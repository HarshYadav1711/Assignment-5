"""
Trip models for Smart Trip Planner.
"""
import uuid
from django.db import models
from django.conf import settings
from django.utils.translation import gettext_lazy as _


class Trip(models.Model):
    """
    Trip model representing a travel plan.
    
    A trip can have multiple destinations and be shared with multiple users.
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
    title = models.CharField(_('title'), max_length=200)
    description = models.TextField(_('description'), blank=True)
    creator = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='created_trips',
        verbose_name=_('creator')
    )
    start_date = models.DateField(_('start date'), null=True, blank=True)
    end_date = models.DateField(_('end date'), null=True, blank=True)
    status = models.CharField(_('status'), max_length=20, choices=TRIP_STATUS_CHOICES, default='draft')
    visibility = models.CharField(_('visibility'), max_length=20, choices=VISIBILITY_CHOICES, default='private')
    
    # Timestamps
    created_at = models.DateTimeField(_('created at'), auto_now_add=True)
    updated_at = models.DateTimeField(_('updated at'), auto_now=True)
    
    class Meta:
        db_table = 'trips'
        verbose_name = _('trip')
        verbose_name_plural = _('trips')
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['creator', 'created_at']),
            models.Index(fields=['status', 'start_date']),
        ]
    
    def __str__(self):
        return self.title


class TripMember(models.Model):
    """
    Trip membership model for multi-user collaboration.
    
    Links users to trips with role-based access control.
    """
    ROLE_CHOICES = [
        ('owner', _('Owner')),
        ('editor', _('Editor')),
        ('viewer', _('Viewer')),
    ]
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    trip = models.ForeignKey(
        Trip,
        on_delete=models.CASCADE,
        related_name='members',
        verbose_name=_('trip')
    )
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='trip_memberships',
        verbose_name=_('user')
    )
    role = models.CharField(_('role'), max_length=20, choices=ROLE_CHOICES, default='viewer')
    joined_at = models.DateTimeField(_('joined at'), auto_now_add=True)
    invited_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='invited_members',
        verbose_name=_('invited by')
    )
    
    class Meta:
        db_table = 'trip_members'
        verbose_name = _('trip member')
        verbose_name_plural = _('trip members')
        unique_together = [['trip', 'user']]
        indexes = [
            models.Index(fields=['trip', 'user']),
            models.Index(fields=['user', 'joined_at']),
        ]
    
    def __str__(self):
        return f"{self.user.email} - {self.trip.title} ({self.role})"

