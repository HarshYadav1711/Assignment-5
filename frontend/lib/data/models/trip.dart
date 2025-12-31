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
    return TripModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      creatorId: json['creator'] is String
          ? json['creator'] as String
          : (json['creator'] as Map)['id'] as String,
      startDate: json['start_date'] != null
          ? DateTime.parse(json['start_date'] as String)
          : null,
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'] as String)
          : null,
      status: json['status'] as String? ?? 'draft',
      visibility: json['visibility'] as String? ?? 'private',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
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

