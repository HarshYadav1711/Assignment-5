"""
Serializers for Itinerary models.
"""
from rest_framework import serializers
from .models import Itinerary, ItineraryItem


class ItineraryItemSerializer(serializers.ModelSerializer):
    """Serializer for ItineraryItem model."""
    
    class Meta:
        model = ItineraryItem
        fields = [
            'id', 'title', 'description', 'start_time', 'end_time',
            'location', 'order', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']


class ItinerarySerializer(serializers.ModelSerializer):
    """Serializer for Itinerary model."""
    items = ItineraryItemSerializer(many=True, read_only=True)
    item_count = serializers.SerializerMethodField()
    
    class Meta:
        model = Itinerary
        fields = [
            'id', 'trip', 'date', 'title', 'notes', 'items',
            'item_count', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']
    
    def get_item_count(self, obj):
        """Return number of items."""
        return obj.items.count()


class ItineraryCreateSerializer(serializers.ModelSerializer):
    """Serializer for creating an itinerary."""
    
    class Meta:
        model = Itinerary
        fields = ['trip', 'date', 'title', 'notes']

