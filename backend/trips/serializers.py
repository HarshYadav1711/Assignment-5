"""
Serializers for Trip models.

Includes proper validation, error handling, and nested serialization.
"""
from rest_framework import serializers
from .models import Trip, Collaborator
from users.serializers import UserSerializer


class CollaboratorSerializer(serializers.ModelSerializer):
    """Serializer for Collaborator model."""
    user = UserSerializer(read_only=True)
    invited_by_user = UserSerializer(source='invited_by', read_only=True)
    
    class Meta:
        model = Collaborator
        fields = ['id', 'user', 'role', 'joined_at', 'invited_by', 'invited_by_user']
        read_only_fields = ['id', 'joined_at', 'invited_by_user']


class TripSerializer(serializers.ModelSerializer):
    """Serializer for Trip model with nested collaborators."""
    creator = UserSerializer(read_only=True)
    collaborators = CollaboratorSerializer(many=True, read_only=True)
    collaborator_count = serializers.SerializerMethodField()
    user_role = serializers.SerializerMethodField()
    
    class Meta:
        model = Trip
        fields = [
            'id', 'title', 'description', 'creator', 'start_date', 'end_date',
            'status', 'visibility', 'collaborators', 'collaborator_count',
            'user_role', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'creator', 'created_at', 'updated_at']
    
    def get_collaborator_count(self, obj):
        """Return number of collaborators."""
        return obj.collaborators.count()
    
    def get_user_role(self, obj):
        """Return current user's role in this trip."""
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            collaboration = obj.collaborators.filter(user=request.user).first()
            return collaboration.role if collaboration else None
        return None


class TripCreateSerializer(serializers.ModelSerializer):
    """Serializer for creating a trip."""
    
    class Meta:
        model = Trip
        fields = ['title', 'description', 'start_date', 'end_date', 'status', 'visibility']
    
    def validate(self, attrs):
        """Validate trip data."""
        start_date = attrs.get('start_date')
        end_date = attrs.get('end_date')
        
        if start_date and end_date and end_date < start_date:
            raise serializers.ValidationError({
                'end_date': 'End date must be after or equal to start date.'
            })
        
        return attrs
    
    def create(self, validated_data):
        """Create trip and add creator as owner."""
        trip = Trip.objects.create(
            creator=self.context['request'].user,
            **validated_data
        )
        # Add creator as owner
        Collaborator.objects.create(
            trip=trip,
            user=trip.creator,
            role='owner',
            invited_by=trip.creator
        )
        return trip


class TripUpdateSerializer(serializers.ModelSerializer):
    """Serializer for updating a trip."""
    
    class Meta:
        model = Trip
        fields = ['title', 'description', 'start_date', 'end_date', 'status', 'visibility']
    
    def validate(self, attrs):
        """Validate trip data."""
        start_date = attrs.get('start_date') or self.instance.start_date
        end_date = attrs.get('end_date') or self.instance.end_date
        
        if start_date and end_date and end_date < start_date:
            raise serializers.ValidationError({
                'end_date': 'End date must be after or equal to start date.'
            })
        
        return attrs


class InviteCollaboratorSerializer(serializers.Serializer):
    """Serializer for inviting a collaborator via email."""
    email = serializers.EmailField(required=True)
    role = serializers.ChoiceField(
        choices=Collaborator.ROLE_CHOICES,
        default='viewer',
        required=False
    )
    message = serializers.CharField(
        max_length=500,
        required=False,
        allow_blank=True,
        help_text="Optional personal message to include in invitation email"
    )
    
    def validate_email(self, value):
        """Validate that email is not already a collaborator."""
        trip = self.context.get('trip')
        if trip:
            from django.contrib.auth import get_user_model
            User = get_user_model()
            try:
                user = User.objects.get(email=value)
                if Collaborator.objects.filter(trip=trip, user=user).exists():
                    raise serializers.ValidationError(
                        'User with this email is already a collaborator on this trip.'
                    )
            except User.DoesNotExist:
                # User doesn't exist yet - that's okay, we'll invite them
                pass
        return value


class ReorderItineraryItemsSerializer(serializers.Serializer):
    """Serializer for reordering itinerary items."""
    item_ids = serializers.ListField(
        child=serializers.UUIDField(),
        min_length=1,
        help_text="List of item IDs in the desired order"
    )
    
    def validate_item_ids(self, value):
        """Validate that all item IDs belong to the same itinerary."""
        itinerary = self.context.get('itinerary')
        if itinerary:
            from itineraries.models import ItineraryItem
            item_count = ItineraryItem.objects.filter(
                id__in=value,
                itinerary=itinerary
            ).count()
            if item_count != len(value):
                raise serializers.ValidationError(
                    'All item IDs must belong to the specified itinerary.'
                )
        return value
