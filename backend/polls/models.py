"""
Poll models for Smart Trip Planner.

Allows trip members to vote on decisions (e.g., destination choices, activities).
"""
import uuid
from django.db import models
from django.conf import settings
from django.utils.translation import gettext_lazy as _


class Poll(models.Model):
    """
    Poll model for trip-related decisions.
    
    A poll belongs to a trip and contains multiple options.
    """
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    trip = models.ForeignKey(
        'trips.Trip',
        on_delete=models.CASCADE,
        related_name='polls',
        verbose_name=_('trip')
    )
    created_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='created_polls',
        verbose_name=_('created by')
    )
    question = models.CharField(_('question'), max_length=500)
    description = models.TextField(_('description'), blank=True)
    is_active = models.BooleanField(_('is active'), default=True)
    closes_at = models.DateTimeField(_('closes at'), null=True, blank=True)
    
    # Timestamps
    created_at = models.DateTimeField(_('created at'), auto_now_add=True)
    updated_at = models.DateTimeField(_('updated at'), auto_now=True)
    
    class Meta:
        db_table = 'polls'
        verbose_name = _('poll')
        verbose_name_plural = _('polls')
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['trip', 'created_at']),
            models.Index(fields=['is_active']),
        ]
    
    def __str__(self):
        return self.question


class PollOption(models.Model):
    """
    Option within a poll.
    
    Users vote for one or more options (depending on poll settings).
    """
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    poll = models.ForeignKey(
        Poll,
        on_delete=models.CASCADE,
        related_name='options',
        verbose_name=_('poll')
    )
    text = models.CharField(_('text'), max_length=200)
    order = models.IntegerField(_('order'), default=0)
    
    # Timestamps
    created_at = models.DateTimeField(_('created at'), auto_now_add=True)
    
    class Meta:
        db_table = 'poll_options'
        verbose_name = _('poll option')
        verbose_name_plural = _('poll options')
        ordering = ['order', 'created_at']
        indexes = [
            models.Index(fields=['poll', 'order']),
        ]
    
    def __str__(self):
        return f"{self.poll.question} - {self.text}"
    
    @property
    def vote_count(self):
        """Return number of votes for this option."""
        return self.votes.count()


class PollVote(models.Model):
    """
    Vote cast by a user for a poll option.
    
    One user can vote for multiple options in a poll (if allowed).
    """
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    poll = models.ForeignKey(
        Poll,
        on_delete=models.CASCADE,
        related_name='votes',
        verbose_name=_('poll')
    )
    option = models.ForeignKey(
        PollOption,
        on_delete=models.CASCADE,
        related_name='votes',
        verbose_name=_('option')
    )
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='poll_votes',
        verbose_name=_('user')
    )
    
    # Timestamps
    created_at = models.DateTimeField(_('created at'), auto_now_add=True)
    
    class Meta:
        db_table = 'poll_votes'
        verbose_name = _('poll vote')
        verbose_name_plural = _('poll votes')
        unique_together = [['poll', 'option', 'user']]  # One vote per option per user
        indexes = [
            models.Index(fields=['poll', 'user']),
        ]
    
    def __str__(self):
        return f"{self.user.email} voted for {self.option.text}"

