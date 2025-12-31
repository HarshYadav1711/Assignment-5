/// Poll model
class PollModel {
  final String id;
  final String tripId;
  final String question;
  final String? description;
  final String createdById;
  final bool isActive;
  final DateTime? closesAt;
  final DateTime createdAt;
  final List<PollOptionModel> options;
  final String? userVoteId; // ID of option user voted for

  PollModel({
    required this.id,
    required this.tripId,
    required this.question,
    this.description,
    required this.createdById,
    required this.isActive,
    this.closesAt,
    required this.createdAt,
    this.options = const [],
    this.userVoteId,
  });

  factory PollModel.fromJson(Map<String, dynamic> json) {
    return PollModel(
      id: json['id'] as String,
      tripId: json['trip'] is String
          ? json['trip'] as String
          : (json['trip'] as Map)['id'] as String,
      question: json['question'] as String,
      description: json['description'] as String?,
      createdById: json['created_by'] is String
          ? json['created_by'] as String
          : (json['created_by'] as Map)['id'] as String,
      isActive: json['is_active'] as bool? ?? true,
      closesAt: json['closes_at'] != null
          ? DateTime.parse(json['closes_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      options: (json['options'] as List<dynamic>?)
              ?.map((opt) => PollOptionModel.fromJson(opt as Map<String, dynamic>))
              .toList() ??
          [],
      userVoteId: json['user_vote'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'trip': tripId,
      'question': question,
      'description': description,
      'is_active': isActive,
      if (closesAt != null) 'closes_at': closesAt!.toIso8601String(),
    };
  }

  PollModel copyWith({
    String? id,
    String? tripId,
    String? question,
    String? description,
    String? createdById,
    bool? isActive,
    DateTime? closesAt,
    DateTime? createdAt,
    List<PollOptionModel>? options,
    String? userVoteId,
  }) {
    return PollModel(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      question: question ?? this.question,
      description: description ?? this.description,
      createdById: createdById ?? this.createdById,
      isActive: isActive ?? this.isActive,
      closesAt: closesAt ?? this.closesAt,
      createdAt: createdAt ?? this.createdAt,
      options: options ?? this.options,
      userVoteId: userVoteId ?? this.userVoteId,
    );
  }
}

/// Poll option model
class PollOptionModel {
  final String id;
  final String pollId;
  final String text;
  final int order;
  final int voteCount;
  final DateTime createdAt;

  PollOptionModel({
    required this.id,
    required this.pollId,
    required this.text,
    required this.order,
    required this.voteCount,
    required this.createdAt,
  });

  factory PollOptionModel.fromJson(Map<String, dynamic> json) {
    return PollOptionModel(
      id: json['id'] as String,
      pollId: json['poll'] is String
          ? json['poll'] as String
          : (json['poll'] as Map)['id'] as String,
      text: json['text'] as String,
      order: json['order'] as int? ?? 0,
      voteCount: json['vote_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'poll': pollId,
      'text': text,
      'order': order,
    };
  }

  PollOptionModel copyWith({
    String? text,
    int? order,
    int? voteCount,
  }) {
    return PollOptionModel(
      id: id,
      pollId: pollId,
      text: text ?? this.text,
      order: order ?? this.order,
      voteCount: voteCount ?? this.voteCount,
      createdAt: createdAt,
    );
  }
}

