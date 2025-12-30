"""
Admin configuration for User and Profile models.
"""
from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin
from django.utils.translation import gettext_lazy as _
from .models import User, Profile


@admin.register(User)
class UserAdmin(BaseUserAdmin):
    """Admin interface for User model."""
    list_display = ('email', 'username', 'first_name', 'last_name', 'is_staff', 'is_active', 'date_joined')
    list_filter = ('is_staff', 'is_superuser', 'is_active', 'date_joined')
    search_fields = ('email', 'username', 'profile__first_name', 'profile__last_name')
    ordering = ('-date_joined',)
    
    fieldsets = (
        (None, {'fields': ('email', 'username', 'password')}),
        (_('Permissions'), {'fields': ('is_active', 'is_staff', 'is_superuser', 'groups', 'user_permissions')}),
        (_('Important dates'), {'fields': ('last_login', 'date_joined')}),
    )
    add_fieldsets = (
        (None, {
            'classes': ('wide',),
            'fields': ('email', 'password1', 'password2', 'is_staff', 'is_active'),
        }),
    )
    
    def first_name(self, obj):
        """Display first name from profile."""
        return obj.profile.first_name if hasattr(obj, 'profile') else '-'
    first_name.short_description = 'First Name'
    
    def last_name(self, obj):
        """Display last name from profile."""
        return obj.profile.last_name if hasattr(obj, 'profile') else '-'
    last_name.short_description = 'Last Name'


@admin.register(Profile)
class ProfileAdmin(admin.ModelAdmin):
    """Admin interface for Profile model."""
    list_display = ('user', 'first_name', 'last_name', 'created_at')
    search_fields = ('user__email', 'first_name', 'last_name')
    list_filter = ('created_at',)
    raw_id_fields = ('user',)

