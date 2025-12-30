"""
Trip models for Smart Trip Planner.

Optimized for read-heavy workloads with proper indexing and constraints.
"""
import uuid
from django.db import models
from django.conf import settings
from django.utils.translation import gettext_lazy as _
from django.core.exceptions import ValidationError


class Trip(models.Model):
    """
    Trip model representing a travel plan.
    
    Optimizations:
    - Indexed on creator + created_at for user trip lists
    - Indexed on status + start_date for filtering
    - Indexed on updated_at for sync queries
    - Check constraint ensures end_date >= start_date
    """
    TRIP_STATUS_CHOICES = [
        ('draft', _('Draft')),
        ('planned', _('Planned')),
        ('active', _('Active')),
        ('completed', _('Completed')),
        ('cancelled', _('Cancelled')),
    ]
    
    VISIBILITY_CHOICES = [
        ('private', _('Private')),
        ('shared', _('Shared')),
        ('public', _('Public')),
    ]
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    title = models.CharField(_('title'), max_length=200, db_index=True)  # Single field index for search
    description = models.TextField(_('description'), blank=True)
    
    # Foreign key with CASCADE: if creator deleted, trip deleted (data integrity)
    creator = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,  # Trip ownership: if user deleted, trip deleted
        related_name='created_trips',
        verbose_name=_('creator'),
        db_index=True  # Index FK for join performance
    )
    
    start_date = models.DateField(_('start date'), null=True, blank=True, db_index=True)
    end_date = models.DateField(_('end date'), null=True, blank=True)
    
    status = models.CharField(
        _('status'),
        max_length=20,
        choices=TRIP_STATUS_CHOICES,
        default='draft',
        db_index=True  # Indexed for filtering
    )
    visibility = models.CharField(
        _('visibility'),
        max_length=20,
        choices=VISIBILITY_CHOICES,
        default='private'
    )
    
    # Timestamps
    created_at = models.DateTimeField(_('created at'), auto_now_add=True, db_index=True)
    updated_at = models.DateTimeField(_('updated at'), auto_now=True, db_index=True)
    
    class Meta:
        db_table = 'trips'
        verbose_name = _('trip')
        verbose_name_plural = _('trips')
        ordering = ['-created_at']
        
        # Composite indexes for common query patterns
        indexes = [
            # User's trips ordered by creation (most common read pattern)
            models.Index(fields=['creator', '-created_at'], name='trips_creator_created_idx'),
            
            # Filter by status and date range
            models.Index(fields=['status', 'start_date'], name='trips_status_date_idx'),
            
            # Sync queries: get trips updated since timestamp
            models.Index(fields=['updated_at'], name='trips_updated_idx'),
            
            # Public trips listing
            models.Index(
                fields=['visibility', 'status', '-created_at'],
                name='trips_public_listing_idx',
                condition=models.Q(visibility='public')
            ),
        ]
        
        # Database-level constraints
        constraints = [
            # Ensure end_date >= start_date (data integrity)
            models.CheckConstraint(
                check=models.Q(end_date__gte=models.F('start_date')) | 
                      models.Q(start_date__isnull=True) | 
                      models.Q(end_date__isnull=True),
                name='trips_valid_date_range'
            ),
        ]
    
    def clean(self):
        """Model-level validation."""
        super().clean()
        if self.start_date and self.end_date:
            if self.end_date < self.start_date:
                raise ValidationError({
                    'end_date': 'End date must be after or equal to start date.'
                })
    
    def save(self, *args, **kwargs):
        """Override save to run validation."""
        self.full_clean()
        super().save(*args, **kwargs)
    
    def __str__(self):
        return self.title


class Collaborator(models.Model):
    """
    Trip collaborator model (renamed from TripMember for clarity).
    
    Represents a user's membership in a trip with role-based permissions.
    
    Optimizations:
    - Unique constraint on (trip, user) prevents duplicates
    - Indexed on trip + user for membership checks (most common query)
    - Indexed on user + joined_at for user's memberships
    - Indexed on trip + role for role-based queries
    """
    ROLE_CHOICES = [
        ('owner', _('Owner')),
        ('editor', _('Editor')),
        ('viewer', _('Viewer')),
    ]
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    
    # CASCADE: if trip deleted, all memberships deleted
    trip = models.ForeignKey(
        Trip,
        on_delete=models.CASCADE,
        related_name='collaborators',  # Changed from 'members' for clarity
        verbose_name=_('trip'),
        db_index=True
    )
    
    # CASCADE: if user deleted, all memberships deleted
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='trip_collaborations',  # Changed from 'trip_memberships'
        verbose_name=_('user'),
        db_index=True
    )
    
    role = models.CharField(
        _('role'),
        max_length=20,
        choices=ROLE_CHOICES,
        default='viewer',
        db_index=True
    )
    
    joined_at = models.DateTimeField(_('joined at'), auto_now_add=True, db_index=True)
    
    # SET_NULL: if inviter deleted, keep membership but null the reference
    invited_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='invited_collaborators',
        verbose_name=_('invited by')
    )
    
    class Meta:
        db_table = 'collaborators'  # Changed from 'trip_members'
        verbose_name = _('collaborator')
        verbose_name_plural = _('collaborators')
        
        # Unique constraint: one membership per user per trip (data integrity)
        constraints = [
            models.UniqueConstraint(
                fields=['trip', 'user'],
                name='unique_trip_user_collaboration'
            ),
        ]
        
        # Optimized indexes for read-heavy workloads
        indexes = [
            # Most common: check if user is member of trip
            models.Index(fields=['trip', 'user'], name='collab_trip_user_idx'),
            
            # User's trip memberships ordered by join date
            models.Index(fields=['user', '-joined_at'], name='collab_user_joined_idx'),
            
            # Get all editors/owners of a trip (permission checks)
            models.Index(fields=['trip', 'role'], name='collab_trip_role_idx'),
            
            # Get all trips user collaborates on (with role)
            models.Index(fields=['user', 'role', '-joined_at'], name='collab_user_role_idx'),
        ]
    
    def clean(self):
        """Model-level validation."""
        super().clean()
        # Ensure at least one owner exists (enforced at application level, not DB)
        # This is a business rule that should be checked in views/signals
    
    def __str__(self):
        return f"{self.user.email} - {self.trip.title} ({self.role})"
