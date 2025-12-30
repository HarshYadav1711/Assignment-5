"""
Itinerary models for Smart Trip Planner.
"""
import uuid
from django.db import models
from django.conf import settings
from django.utils.translation import gettext_lazy as _


class Itinerary(models.Model):
    """
    Itinerary model representing a day-by-day plan within a trip.
    
    An itinerary belongs to a trip and contains activities for a specific date.
    """
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    trip = models.ForeignKey(
        'trips.Trip',
        on_delete=models.CASCADE,
        related_name='itineraries',
        verbose_name=_('trip')
    )
    date = models.DateField(_('date'))
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
        unique_together = [['trip', 'date']]
        indexes = [
            models.Index(fields=['trip', 'date']),
        ]
    
    def __str__(self):
        return f"{self.trip.title} - {self.date}"


class ItineraryItem(models.Model):
    """
    Individual activity/item within an itinerary.
    
    Represents a specific activity, location, or event for a given time.
    """
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    itinerary = models.ForeignKey(
        Itinerary,
        on_delete=models.CASCADE,
        related_name='items',
        verbose_name=_('itinerary')
    )
    title = models.CharField(_('title'), max_length=200)
    description = models.TextField(_('description'), blank=True)
    start_time = models.TimeField(_('start time'), null=True, blank=True)
    end_time = models.TimeField(_('end time'), null=True, blank=True)
    location = models.CharField(_('location'), max_length=200, blank=True)
    order = models.IntegerField(_('order'), default=0)
    
    # Timestamps
    created_at = models.DateTimeField(_('created at'), auto_now_add=True)
    updated_at = models.DateTimeField(_('updated at'), auto_now=True)
    
    class Meta:
        db_table = 'itinerary_items'
        verbose_name = _('itinerary item')
        verbose_name_plural = _('itinerary items')
        ordering = ['order', 'start_time']
        indexes = [
            models.Index(fields=['itinerary', 'order']),
        ]
    
    def __str__(self):
        return f"{self.title} - {self.itinerary.date}"

