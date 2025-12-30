"""
Admin configuration for Trip models.
"""
from django.contrib import admin
from .models import Trip, TripMember


@admin.register(Trip)
class TripAdmin(admin.ModelAdmin):
    list_display = ('title', 'creator', 'status', 'visibility', 'start_date', 'created_at')
    list_filter = ('status', 'visibility', 'created_at')
    search_fields = ('title', 'description', 'creator__email')
    raw_id_fields = ('creator',)


@admin.register(TripMember)
class TripMemberAdmin(admin.ModelAdmin):
    list_display = ('trip', 'user', 'role', 'joined_at')
    list_filter = ('role', 'joined_at')
    search_fields = ('trip__title', 'user__email')
    raw_id_fields = ('trip', 'user', 'invited_by')

