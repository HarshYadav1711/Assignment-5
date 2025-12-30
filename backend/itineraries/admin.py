"""
Admin configuration for Itinerary models.
"""
from django.contrib import admin
from .models import Itinerary, ItineraryItem


@admin.register(Itinerary)
class ItineraryAdmin(admin.ModelAdmin):
    list_display = ('trip', 'date', 'title', 'created_at')
    list_filter = ('date', 'created_at')
    search_fields = ('trip__title', 'title', 'notes')
    raw_id_fields = ('trip',)


@admin.register(ItineraryItem)
class ItineraryItemAdmin(admin.ModelAdmin):
    list_display = ('title', 'itinerary', 'start_time', 'location', 'order')
    list_filter = ('created_at',)
    search_fields = ('title', 'description', 'location')
    raw_id_fields = ('itinerary',)

