"""
Serializers for User and Profile models.
"""
from rest_framework import serializers
from django.contrib.auth.password_validation import validate_password
from .models import User, Profile


class ProfileSerializer(serializers.ModelSerializer):
    """Serializer for Profile model."""
    
    class Meta:
        model = Profile
        fields = ['id', 'first_name', 'last_name', 'bio', 'avatar', 'created_at', 'updated_at']
        read_only_fields = ['id', 'created_at', 'updated_at']


class UserSerializer(serializers.ModelSerializer):
    """Serializer for User model (read-only fields)."""
    profile = ProfileSerializer(read_only=True)
    full_name = serializers.SerializerMethodField()
    
    class Meta:
        model = User
        fields = ['id', 'email', 'username', 'profile', 'full_name', 'date_joined', 'last_login']
        read_only_fields = ['id', 'email', 'date_joined', 'last_login']
    
    def get_full_name(self, obj):
        """Return user's full name."""
        return obj.get_full_name()


class UserRegistrationSerializer(serializers.ModelSerializer):
    """Serializer for user registration."""
    password = serializers.CharField(write_only=True, required=True, validators=[validate_password])
    password_confirm = serializers.CharField(write_only=True, required=True)
    first_name = serializers.CharField(write_only=True, required=False, allow_blank=True)
    last_name = serializers.CharField(write_only=True, required=False, allow_blank=True)
    
    class Meta:
        model = User
        fields = ['email', 'username', 'password', 'password_confirm', 'first_name', 'last_name']
    
    def validate(self, attrs):
        """Validate that passwords match."""
        if attrs['password'] != attrs['password_confirm']:
            raise serializers.ValidationError({"password": "Password fields didn't match."})
        return attrs
    
    def create(self, validated_data):
        """Create user and profile."""
        validated_data.pop('password_confirm')
        first_name = validated_data.pop('first_name', '')
        last_name = validated_data.pop('last_name', '')
        
        user = User.objects.create_user(
            email=validated_data['email'],
            username=validated_data.get('username'),
            password=validated_data['password']
        )
        
        # Create profile if name provided
        if first_name or last_name:
            Profile.objects.create(
                user=user,
                first_name=first_name,
                last_name=last_name
            )
        
        return user


class ProfileUpdateSerializer(serializers.ModelSerializer):
    """Serializer for updating profile."""
    
    class Meta:
        model = Profile
        fields = ['first_name', 'last_name', 'bio', 'avatar']
    
    def update(self, instance, validated_data):
        """Update profile instance."""
        for attr, value in validated_data.items():
            setattr(instance, attr, value)
        instance.save()
        return instance

