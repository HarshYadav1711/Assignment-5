/// Itinerary model
class ItineraryModel {
  final String id;
  final String tripId;
  final DateTime date;
  final String? title;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ItineraryItemModel> items;

  ItineraryModel({
    required this.id,
    required this.tripId,
    required this.date,
    this.title,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.items = const [],
  });

  factory ItineraryModel.fromJson(Map<String, dynamic> json) {
    return ItineraryModel(
      id: json['id'] as String,
      tripId: json['trip'] is String
          ? json['trip'] as String
          : (json['trip'] as Map)['id'] as String,
      date: DateTime.parse(json['date'] as String),
      title: json['title'] as String?,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      items: (json['items'] as List<dynamic>?)
              ?.map((item) => ItineraryItemModel.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'trip': tripId,
      'date': date.toIso8601String().split('T')[0],
      'title': title,
      'notes': notes,
    };
  }
}

/// Itinerary item model
class ItineraryItemModel {
  final String id;
  final String itineraryId;
  final String title;
  final String? description;
  final DateTime? startTime;
  final DateTime? endTime;
  final String? location;
  final int order;
  final DateTime createdAt;
  final DateTime updatedAt;

  ItineraryItemModel({
    required this.id,
    required this.itineraryId,
    required this.title,
    this.description,
    this.startTime,
    this.endTime,
    this.location,
    required this.order,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ItineraryItemModel.fromJson(Map<String, dynamic> json) {
    return ItineraryItemModel(
      id: json['id'] as String,
      itineraryId: json['itinerary'] is String
          ? json['itinerary'] as String
          : (json['itinerary'] as Map)['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      startTime: json['start_time'] != null
          ? DateTime.parse('2000-01-01 ${json['start_time']}')
          : null,
      endTime: json['end_time'] != null
          ? DateTime.parse('2000-01-01 ${json['end_time']}')
          : null,
      location: json['location'] as String?,
      order: json['order'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'itinerary': itineraryId,
      'title': title,
      'description': description,
      'start_time': startTime?.toTimeString(),
      'end_time': endTime?.toTimeString(),
      'location': location,
      'order': order,
    };
  }

  ItineraryItemModel copyWith({
    String? title,
    String? description,
    DateTime? startTime,
    DateTime? endTime,
    String? location,
    int? order,
  }) {
    return ItineraryItemModel(
      id: id,
      itineraryId: itineraryId,
      title: title ?? this.title,
      description: description ?? this.description,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      location: location ?? this.location,
      order: order ?? this.order,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

