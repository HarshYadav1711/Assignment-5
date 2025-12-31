"""
Admin configuration for Poll models.
"""
from django.contrib import admin
from .models import Poll, PollOption, Vote


@admin.register(Poll)
class PollAdmin(admin.ModelAdmin):
    list_display = ('question', 'trip', 'created_by', 'is_active', 'created_at')
    list_filter = ('is_active', 'created_at')
    search_fields = ('question', 'description', 'trip__title')
    raw_id_fields = ('trip', 'created_by')


@admin.register(PollOption)
class PollOptionAdmin(admin.ModelAdmin):
    list_display = ('text', 'poll', 'order', 'vote_count', 'created_at')
    list_filter = ('created_at',)
    search_fields = ('text',)
    raw_id_fields = ('poll',)


@admin.register(Vote)
class VoteAdmin(admin.ModelAdmin):
    list_display = ('user', 'poll', 'option', 'created_at')
    list_filter = ('created_at',)
    search_fields = ('user__email', 'poll__question', 'option__text')
    raw_id_fields = ('poll', 'option', 'user')

