/// Trip model matching API response
class TripModel {
  final String id;
  final String title;
  final String? description;
  final String creatorId;
  final DateTime? startDate;
  final DateTime? endDate;
  final String status; // draft, planned, active, completed, cancelled
  final String visibility; // private, shared, public
  final DateTime createdAt;
  final DateTime updatedAt;

  TripModel({
    required this.id,
    required this.title,
    this.description,
    required this.creatorId,
    this.startDate,
    this.endDate,
    required this.status,
    required this.visibility,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TripModel.fromJson(Map<String, dynamic> json) {
    try {
      // Handle creator field - can be String ID or nested object
      String creatorId;
      final creator = json['creator'];
      if (creator == null) {
        throw FormatException('Creator field is required but was null. JSON keys: ${json.keys.join(", ")}');
      } else if (creator is String) {
        creatorId = creator;
      } else if (creator is Map) {
        final creatorMap = creator as Map<String, dynamic>;
        final creatorIdValue = creatorMap['id'] as String?;
        if (creatorIdValue == null) {
          throw FormatException('Creator object missing id field. Creator data: $creatorMap');
        }
        creatorId = creatorIdValue;
      } else {
        throw FormatException('Unexpected creator field type: ${creator.runtimeType}. Value: $creator');
      }

      // Handle required fields
      final id = json['id']?.toString();
      if (id == null || id.isEmpty) {
        throw FormatException('Trip id is required. JSON keys: ${json.keys.join(", ")}');
      }

      final title = json['title']?.toString();
      if (title == null || title.isEmpty) {
        throw FormatException('Trip title is required. JSON keys: ${json.keys.join(", ")}');
      }

      // Handle description - can be null or empty string
      final description = json['description'];
      final descriptionStr = (description == null || description == '')
          ? null
          : description.toString();

      // Handle dates - parse safely
      DateTime? parseDate(dynamic dateValue) {
        if (dateValue == null || dateValue == '') return null;
        try {
          return DateTime.parse(dateValue.toString());
        } catch (e) {
          return null;
        }
      }

      // Handle status and visibility with defaults
      final status = json['status']?.toString();
      final visibility = json['visibility']?.toString();

      return TripModel(
        id: id,
        title: title,
        description: descriptionStr,
        creatorId: creatorId,
        startDate: parseDate(json['start_date']),
        endDate: parseDate(json['end_date']),
        status: (status != null && status.isNotEmpty) ? status : 'draft',
        visibility: (visibility != null && visibility.isNotEmpty) ? visibility : 'private',
        createdAt: parseDate(json['created_at']) ?? DateTime.now(),
        updatedAt: parseDate(json['updated_at']) ?? DateTime.now(),
      );
    } catch (e) {
      if (e is FormatException) {
        rethrow;
      }
      throw FormatException('Error parsing TripModel: ${e.toString()}. JSON: $json');
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'creator': creatorId,
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'status': status,
      'visibility': visibility,
    };
  }

  TripModel copyWith({
    String? title,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    String? status,
    String? visibility,
  }) {
    return TripModel(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      creatorId: creatorId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      visibility: visibility ?? this.visibility,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

/// Collaborator model
class CollaboratorModel {
  final String id;
  final String tripId;
  final String userId;
  final String role; // owner, editor, viewer
  final DateTime joinedAt;
  final String? invitedById;

  CollaboratorModel({
    required this.id,
    required this.tripId,
    required this.userId,
    required this.role,
    required this.joinedAt,
    this.invitedById,
  });

  factory CollaboratorModel.fromJson(Map<String, dynamic> json) {
    return CollaboratorModel(
      id: json['id'] as String,
      tripId: json['trip'] is String
          ? json['trip'] as String
          : (json['trip'] as Map)['id'] as String,
      userId: json['user'] is String
          ? json['user'] as String
          : (json['user'] as Map)['id'] as String,
      role: json['role'] as String,
      joinedAt: DateTime.parse(json['joined_at'] as String),
      invitedById: json['invited_by'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'trip': tripId,
      'user': userId,
      'role': role,
      'joined_at': joinedAt.toIso8601String(),
      if (invitedById != null) 'invited_by': invitedById,
    };
  }
}

