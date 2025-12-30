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
    
    def validate(self, attrs):
        """Validate time range."""
        start_time = attrs.get('start_time') or (self.instance.start_time if self.instance else None)
        end_time = attrs.get('end_time') or (self.instance.end_time if self.instance else None)
        
        if start_time and end_time and end_time < start_time:
            raise serializers.ValidationError({
                'end_time': 'End time must be after or equal to start time.'
            })
        
        return attrs


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
    
    def validate(self, attrs):
        """Validate that date is within trip date range."""
        trip = attrs.get('trip') or self.context.get('trip')
        date = attrs.get('date')
        
        if trip and date:
            if trip.start_date and date < trip.start_date:
                raise serializers.ValidationError({
                    'date': 'Itinerary date cannot be before trip start date.'
                })
            if trip.end_date and date > trip.end_date:
                raise serializers.ValidationError({
                    'date': 'Itinerary date cannot be after trip end date.'
                })
        
        return attrs


class ReorderItemsSerializer(serializers.Serializer):
    """Serializer for reordering itinerary items."""
    item_ids = serializers.ListField(
        child=serializers.UUIDField(),
        min_length=1,
        help_text="List of item IDs in the desired order (first ID = order 0, second = order 1, etc.)"
    )
    
    def validate_item_ids(self, value):
        """Validate that all item IDs belong to the same itinerary."""
        itinerary = self.context.get('itinerary')
        if itinerary:
            item_count = ItineraryItem.objects.filter(
                id__in=value,
                itinerary=itinerary
            ).count()
            if item_count != len(value):
                raise serializers.ValidationError(
                    'All item IDs must belong to the specified itinerary.'
                )
            if len(value) != len(set(value)):
                raise serializers.ValidationError(
                    'Duplicate item IDs are not allowed.'
                )
        return value
