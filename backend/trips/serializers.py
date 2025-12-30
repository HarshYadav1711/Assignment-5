"""
Serializers for Trip models.
"""
from rest_framework import serializers
from .models import Trip, TripMember
from users.serializers import UserSerializer


class TripMemberSerializer(serializers.ModelSerializer):
    """Serializer for TripMember model."""
    user = UserSerializer(read_only=True)
    
    class Meta:
        model = TripMember
        fields = ['id', 'user', 'role', 'joined_at', 'invited_by']
        read_only_fields = ['id', 'joined_at']


class TripSerializer(serializers.ModelSerializer):
    """Serializer for Trip model."""
    creator = UserSerializer(read_only=True)
    members = TripMemberSerializer(many=True, read_only=True)
    member_count = serializers.SerializerMethodField()
    
    class Meta:
        model = Trip
        fields = [
            'id', 'title', 'description', 'creator', 'start_date', 'end_date',
            'status', 'visibility', 'members', 'member_count',
            'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'creator', 'created_at', 'updated_at']
    
    def get_member_count(self, obj):
        """Return number of members."""
        return obj.members.count()


class TripCreateSerializer(serializers.ModelSerializer):
    """Serializer for creating a trip."""
    
    class Meta:
        model = Trip
        fields = ['title', 'description', 'start_date', 'end_date', 'status', 'visibility']
    
    def create(self, validated_data):
        """Create trip and add creator as owner."""
        trip = Trip.objects.create(
            creator=self.context['request'].user,
            **validated_data
        )
        # Add creator as owner
        TripMember.objects.create(
            trip=trip,
            user=trip.creator,
            role='owner'
        )
        return trip

