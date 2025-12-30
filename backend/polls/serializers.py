"""
Serializers for Poll models.
"""
from rest_framework import serializers
from .models import Poll, PollOption, PollVote
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
            return PollVote.objects.filter(option=obj, user=request.user).exists()
        return False


class PollSerializer(serializers.ModelSerializer):
    """Serializer for Poll model."""
    created_by = UserSerializer(read_only=True)
    options = PollOptionSerializer(many=True, read_only=True)
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
    
    def get_total_votes(self, obj):
        """Return total number of votes across all options."""
        return PollVote.objects.filter(poll=obj).count()
    
    def get_user_has_voted(self, obj):
        """Check if current user has voted."""
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            return PollVote.objects.filter(poll=obj, user=request.user).exists()
        return False


class PollCreateSerializer(serializers.ModelSerializer):
    """Serializer for creating a poll."""
    options = serializers.ListField(
        child=serializers.CharField(max_length=200),
        write_only=True,
        min_length=2
    )
    
    class Meta:
        model = Poll
        fields = ['trip', 'question', 'description', 'is_active', 'closes_at', 'options']
    
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


class PollVoteSerializer(serializers.ModelSerializer):
    """Serializer for PollVote model."""
    
    class Meta:
        model = PollVote
        fields = ['id', 'poll', 'option', 'created_at']
        read_only_fields = ['id', 'created_at']
    
    def create(self, validated_data):
        """Create vote."""
        return PollVote.objects.create(
            user=self.context['request'].user,
            **validated_data
        )

