"""
Serializers for Poll models.
"""
from rest_framework import serializers
from .models import Poll, PollOption, Vote
from users.serializers import UserSerializer


class PollOptionSerializer(serializers.ModelSerializer):
    """Serializer for PollOption model."""
    vote_count = serializers.IntegerField(read_only=True)
    user_voted = serializers.SerializerMethodField()
    
    class Meta:
        model = PollOption
        fields = ['id', 'text', 'order', 'vote_count', 'user_voted', 'created_at']
        read_only_fields = ['id', 'vote_count', 'created_at']
    
    def get_user_voted(self, obj):
        """Check if current user voted for this option."""
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            return Vote.objects.filter(option=obj, user=request.user).exists()
        return False


class PollSerializer(serializers.ModelSerializer):
    """Serializer for Poll model."""
    created_by = UserSerializer(read_only=True)
    options = PollOptionSerializer(many=True, read_only=True, context={'request': None})
    total_votes = serializers.SerializerMethodField()
    user_has_voted = serializers.SerializerMethodField()
    
    class Meta:
        model = Poll
        fields = [
            'id', 'trip', 'created_by', 'question', 'description',
            'is_active', 'closes_at', 'options', 'total_votes',
            'user_has_voted', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_by', 'created_at', 'updated_at']
    
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        # Pass request context to nested serializers
        request = self.context.get('request')
        if request:
            self.fields['options'].context['request'] = request
    
    def get_total_votes(self, obj):
        """Return total number of votes across all options."""
        return Vote.objects.filter(poll=obj).count()
    
    def get_user_has_voted(self, obj):
        """Check if current user has voted."""
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            return Vote.objects.filter(poll=obj, user=request.user).exists()
        return False


class PollCreateSerializer(serializers.ModelSerializer):
    """Serializer for creating a poll."""
    options = serializers.ListField(
        child=serializers.CharField(max_length=200),
        write_only=True,
        min_length=2,
        help_text="List of poll option texts (minimum 2 options required)"
    )
    
    class Meta:
        model = Poll
        fields = ['trip', 'question', 'description', 'is_active', 'closes_at', 'options']
    
    def validate_options(self, value):
        """Validate that options are unique."""
        if len(value) != len(set(value)):
            raise serializers.ValidationError('Poll options must be unique.')
        return value
    
    def validate(self, attrs):
        """Validate poll data."""
        closes_at = attrs.get('closes_at')
        if closes_at:
            from django.utils import timezone
            if closes_at < timezone.now():
                raise serializers.ValidationError({
                    'closes_at': 'Close date cannot be in the past.'
                })
        return attrs
    
    def create(self, validated_data):
        """Create poll and options."""
        options_data = validated_data.pop('options')
        poll = Poll.objects.create(
            created_by=self.context['request'].user,
            **validated_data
        )
        
        for index, option_text in enumerate(options_data):
            PollOption.objects.create(
                poll=poll,
                text=option_text,
                order=index
            )
        
        return poll


class VoteSerializer(serializers.ModelSerializer):
    """Serializer for Vote model."""
    
    class Meta:
        model = Vote
        fields = ['id', 'poll', 'option', 'created_at']
        read_only_fields = ['id', 'created_at']
    
    def validate(self, attrs):
        """Validate vote data."""
        poll = attrs.get('poll')
        option = attrs.get('option')
        
        # Ensure option belongs to poll
        if option.poll != poll:
            raise serializers.ValidationError({
                'option': 'Option must belong to the specified poll.'
            })
        
        # Ensure poll is active
        if not poll.is_active:
            raise serializers.ValidationError({
                'poll': 'Cannot vote on an inactive poll.'
            })
        
        # Check if poll has closed
        if poll.closes_at:
            from django.utils import timezone
            if poll.closes_at < timezone.now():
                raise serializers.ValidationError({
                    'poll': 'This poll has closed.'
                })
        
        return attrs
    
    def create(self, validated_data):
        """Create vote."""
        return Vote.objects.create(
            user=self.context['request'].user,
            **validated_data
        )


class VoteRequestSerializer(serializers.Serializer):
    """Serializer for vote request (option_id only)."""
    option_id = serializers.UUIDField(required=True, help_text="UUID of the poll option to vote for")
