"""
Itinerary models for Smart Trip Planner.

Optimized for read-heavy workloads with proper ordering and indexing.
"""
import uuid
from django.db import models
from django.conf import settings
from django.utils.translation import gettext_lazy as _
from django.core.exceptions import ValidationError


class Itinerary(models.Model):
    """
    Itinerary model representing a day-by-day plan within a trip.
    
    Optimizations:
    - Unique constraint on (trip, date) prevents duplicate days
    - Indexed on trip + date for chronological retrieval
    - Indexed on trip + created_at for listing
    """
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    
    # CASCADE: if trip deleted, all itineraries deleted
    trip = models.ForeignKey(
        'trips.Trip',
        on_delete=models.CASCADE,
        related_name='itineraries',
        verbose_name=_('trip'),
        db_index=True
    )
    
    date = models.DateField(_('date'), db_index=True)
    title = models.CharField(_('title'), max_length=200, blank=True)
    notes = models.TextField(_('notes'), blank=True)
    
    # Timestamps
    created_at = models.DateTimeField(_('created at'), auto_now_add=True)
    updated_at = models.DateTimeField(_('updated at'), auto_now=True)
    
    class Meta:
        db_table = 'itineraries'
        verbose_name = _('itinerary')
        verbose_name_plural = _('itineraries')
        ordering = ['date', 'created_at']
        
        # Unique constraint: one itinerary per trip per date
        constraints = [
            models.UniqueConstraint(
                fields=['trip', 'date'],
                name='unique_trip_date_itinerary'
            ),
        ]
        
        # Optimized indexes for read-heavy workloads
        indexes = [
            # Most common: get all itineraries for a trip, ordered by date
            models.Index(fields=['trip', 'date'], name='itinerary_trip_date_idx'),
            
            # Get itineraries for date range
            models.Index(fields=['trip', 'date', '-created_at'], name='itinerary_trip_date_created_idx'),
        ]
    
    def __str__(self):
        return f"{self.trip.title} - {self.date}"


class ItineraryItem(models.Model):
    """
    Individual activity/item within an itinerary.
    
    Orderable items with proper indexing for read-heavy workloads.
    
    Optimizations:
    - Indexed on itinerary + order for efficient ordering
    - Indexed on itinerary + start_time for time-based queries
    - Order field allows manual reordering (drag-and-drop)
    """
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    
    # CASCADE: if itinerary deleted, all items deleted
    itinerary = models.ForeignKey(
        Itinerary,
        on_delete=models.CASCADE,
        related_name='items',
        verbose_name=_('itinerary'),
        db_index=True
    )
    
    title = models.CharField(_('title'), max_length=200)
    description = models.TextField(_('description'), blank=True)
    
    # Time fields for scheduling
    start_time = models.TimeField(_('start time'), null=True, blank=True, db_index=True)
    end_time = models.TimeField(_('end time'), null=True, blank=True)
    
    location = models.CharField(_('location'), max_length=200, blank=True)
    
    # Order field for manual sorting (allows reordering without changing timestamps)
    order = models.IntegerField(_('order'), default=0, db_index=True)
    
    # Timestamps
    created_at = models.DateTimeField(_('created at'), auto_now_add=True)
    updated_at = models.DateTimeField(_('updated at'), auto_now=True)
    
    class Meta:
        db_table = 'itinerary_items'
        verbose_name = _('itinerary item')
        verbose_name_plural = _('itinerary items')
        
        # Default ordering: by order field, then by start_time
        ordering = ['order', 'start_time']
        
        # Optimized indexes for read-heavy workloads
        indexes = [
            # Most common: get all items for itinerary, ordered by order field
            models.Index(fields=['itinerary', 'order'], name='item_itinerary_order_idx'),
            
            # Time-based queries: items ordered by time
            models.Index(fields=['itinerary', 'start_time'], name='item_itinerary_time_idx'),
            
            # Combined: order + time for flexible sorting
            models.Index(fields=['itinerary', 'order', 'start_time'], name='item_itinerary_order_time_idx'),
        ]
        
        # Database-level constraints
        constraints = [
            # Ensure end_time >= start_time if both provided
            models.CheckConstraint(
                check=models.Q(end_time__gte=models.F('start_time')) | 
                      models.Q(start_time__isnull=True) | 
                      models.Q(end_time__isnull=True),
                name='item_valid_time_range'
            ),
            
            # Ensure order >= 0
            models.CheckConstraint(
                check=models.Q(order__gte=0),
                name='item_positive_order'
            ),
        ]
    
    def clean(self):
        """Model-level validation."""
        super().clean()
        if self.start_time and self.end_time:
            if self.end_time < self.start_time:
                raise ValidationError({
                    'end_time': 'End time must be after or equal to start time.'
                })
        if self.order < 0:
            raise ValidationError({
                'order': 'Order must be a non-negative integer.'
            })
    
    def save(self, *args, **kwargs):
        """Override save to run validation and auto-assign order if needed."""
        # Auto-assign order if not provided (for new items)
        if self.order == 0 and not self.pk:
            max_order = ItineraryItem.objects.filter(itinerary=self.itinerary).aggregate(
                max_order=models.Max('order')
            )['max_order'] or 0
            self.order = max_order + 1
        
        self.full_clean()
        super().save(*args, **kwargs)
    
    def __str__(self):
        return f"{self.title} - {self.itinerary.date}"
