"""
Poll models for Smart Trip Planner.

Optimized for read-heavy workloads with proper indexing and vote counting.
"""
import uuid
from django.db import models
from django.conf import settings
from django.utils.translation import gettext_lazy as _
from django.core.exceptions import ValidationError
from django.db.models import Count, Q


class Poll(models.Model):
    """
    Poll model for trip-related decisions.
    
    Optimizations:
    - Indexed on trip + created_at for listing
    - Indexed on is_active for filtering active polls
    - Indexed on closes_at for scheduled closure queries
    """
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    
    # CASCADE: if trip deleted, all polls deleted
    trip = models.ForeignKey(
        'trips.Trip',
        on_delete=models.CASCADE,
        related_name='polls',
        verbose_name=_('trip'),
        db_index=True
    )
    
    # CASCADE: if creator deleted, poll deleted (data integrity)
    created_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='created_polls',
        verbose_name=_('created by'),
        db_index=True
    )
    
    question = models.CharField(_('question'), max_length=500, db_index=True)
    description = models.TextField(_('description'), blank=True)
    
    is_active = models.BooleanField(_('is active'), default=True, db_index=True)
    closes_at = models.DateTimeField(_('closes at'), null=True, blank=True, db_index=True)
    
    # Timestamps
    created_at = models.DateTimeField(_('created at'), auto_now_add=True, db_index=True)
    updated_at = models.DateTimeField(_('updated at'), auto_now=True)
    
    class Meta:
        db_table = 'polls'
        verbose_name = _('poll')
        verbose_name_plural = _('polls')
        ordering = ['-created_at']
        
        # Optimized indexes for read-heavy workloads
        indexes = [
            # Most common: get all polls for a trip, ordered by creation
            models.Index(fields=['trip', '-created_at'], name='poll_trip_created_idx'),
            
            # Active polls for a trip
            models.Index(
                fields=['trip', 'is_active', '-created_at'],
                name='poll_trip_active_idx',
                condition=models.Q(is_active=True)
            ),
            
            # Polls closing soon (for notifications)
            models.Index(
                fields=['closes_at'],
                name='poll_closes_at_idx',
                condition=models.Q(closes_at__isnull=False, is_active=True)
            ),
        ]
    
    def clean(self):
        """Model-level validation."""
        super().clean()
        if self.closes_at and self.closes_at < self.created_at:
            raise ValidationError({
                'closes_at': 'Close date must be after creation date.'
            })
    
    def save(self, *args, **kwargs):
        """Override save to run validation."""
        self.full_clean()
        super().save(*args, **kwargs)
    
    @property
    def total_votes(self):
        """Get total vote count (cached via annotation in queries)."""
        return self.votes.count()
    
    @property
    def option_count(self):
        """Get number of options."""
        return self.options.count()
    
    def __str__(self):
        return self.question


class PollOption(models.Model):
    """
    Option within a poll.
    
    Optimizations:
    - Indexed on poll + order for ordered listing
    - Vote count calculated via annotation for performance
    """
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    
    # CASCADE: if poll deleted, all options deleted
    poll = models.ForeignKey(
        Poll,
        on_delete=models.CASCADE,
        related_name='options',
        verbose_name=_('poll'),
        db_index=True
    )
    
    text = models.CharField(_('text'), max_length=200)
    order = models.IntegerField(_('order'), default=0, db_index=True)
    
    # Timestamps
    created_at = models.DateTimeField(_('created at'), auto_now_add=True)
    
    class Meta:
        db_table = 'poll_options'
        verbose_name = _('poll option')
        verbose_name_plural = _('poll options')
        ordering = ['order', 'created_at']
        
        # Optimized indexes for read-heavy workloads
        indexes = [
            # Most common: get all options for poll, ordered by order field
            models.Index(fields=['poll', 'order'], name='option_poll_order_idx'),
        ]
        
        # Database-level constraints
        constraints = [
            # Ensure order >= 0
            models.CheckConstraint(
                check=models.Q(order__gte=0),
                name='option_positive_order'
            ),
        ]
    
    def clean(self):
        """Model-level validation."""
        super().clean()
        if self.order < 0:
            raise ValidationError({
                'order': 'Order must be a non-negative integer.'
            })
    
    def save(self, *args, **kwargs):
        """Override save to run validation and auto-assign order if needed."""
        # Auto-assign order if not provided (for new options)
        if self.order == 0 and not self.pk:
            max_order = PollOption.objects.filter(poll=self.poll).aggregate(
                max_order=models.Max('order')
            )['max_order'] or 0
            self.order = max_order + 1
        
        self.full_clean()
        super().save(*args, **kwargs)
    
    @property
    def vote_count(self):
        """Return number of votes for this option (use annotation in queries for performance)."""
        return self.votes.count()
    
    def __str__(self):
        return f"{self.poll.question} - {self.text}"


class Vote(models.Model):
    """
    Vote cast by a user for a poll option.
    
    Optimizations:
    - Unique constraint on (poll, option, user) prevents duplicate votes
    - Indexed on poll + user for "has user voted" checks
    - Indexed on option for vote counting
    - Indexed on user for user's voting history
    """
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    
    # CASCADE: if poll deleted, all votes deleted
    poll = models.ForeignKey(
        Poll,
        on_delete=models.CASCADE,
        related_name='votes',
        verbose_name=_('poll'),
        db_index=True
    )
    
    # CASCADE: if option deleted, all votes for that option deleted
    option = models.ForeignKey(
        PollOption,
        on_delete=models.CASCADE,
        related_name='votes',
        verbose_name=_('option'),
        db_index=True
    )
    
    # CASCADE: if user deleted, all votes deleted
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='poll_votes',
        verbose_name=_('user'),
        db_index=True
    )
    
    # Timestamps
    created_at = models.DateTimeField(_('created at'), auto_now_add=True, db_index=True)
    
    class Meta:
        db_table = 'votes'  # Changed from 'poll_votes' for clarity
        verbose_name = _('vote')
        verbose_name_plural = _('votes')
        
        # Unique constraint: one vote per user per option (data integrity)
        constraints = [
            models.UniqueConstraint(
                fields=['poll', 'option', 'user'],
                name='unique_poll_option_user_vote'
            ),
        ]
        
        # Optimized indexes for read-heavy workloads
        indexes = [
            # Most common: check if user has voted in poll
            models.Index(fields=['poll', 'user'], name='vote_poll_user_idx'),
            
            # Count votes per option (for results)
            models.Index(fields=['option'], name='vote_option_idx'),
            
            # User's voting history
            models.Index(fields=['user', '-created_at'], name='vote_user_created_idx'),
            
            # Get all votes for a poll (for results)
            models.Index(fields=['poll', 'option'], name='vote_poll_option_idx'),
        ]
    
    def clean(self):
        """Model-level validation."""
        super().clean()
        # Ensure option belongs to poll
        if self.option.poll != self.poll:
            raise ValidationError({
                'option': 'Option must belong to the specified poll.'
            })
        
        # Ensure poll is active
        if not self.poll.is_active:
            raise ValidationError({
                'poll': 'Cannot vote on an inactive poll.'
            })
        
        # Check if poll has closed
        if self.poll.closes_at and self.poll.closes_at < timezone.now():
            raise ValidationError({
                'poll': 'This poll has closed.'
            })
    
    def save(self, *args, **kwargs):
        """Override save to run validation."""
        self.full_clean()
        super().save(*args, **kwargs)
    
    def __str__(self):
        return f"{self.user.email} voted for {self.option.text}"
