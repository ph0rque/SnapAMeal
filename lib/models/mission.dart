import 'package:cloud_firestore/cloud_firestore.dart';

enum MissionStatus {
  active,
  completed,
  paused,
  expired,
}

enum MissionDifficulty {
  beginner,
  intermediate,
  advanced,
}

class Mission {
  final String id;
  final String userId;
  final String title;
  final String description;
  final List<MissionStep> steps;
  final MissionStatus status;
  final MissionDifficulty difficulty;
  final String goalType; // 'weight_loss', 'muscle_gain', 'health', etc.
  final DateTime createdAt;
  final DateTime? completedAt;
  final DateTime? expiresAt;
  final int durationDays;
  final Map<String, dynamic> metadata;

  Mission({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.steps,
    this.status = MissionStatus.active,
    this.difficulty = MissionDifficulty.beginner,
    required this.goalType,
    required this.createdAt,
    this.completedAt,
    this.expiresAt,
    this.durationDays = 7,
    this.metadata = const {},
  });

  factory Mission.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Mission(
      id: doc.id,
      userId: data['userId'],
      title: data['title'],
      description: data['description'],
      steps: (data['steps'] as List)
          .map((step) => MissionStep.fromMap(step))
          .toList(),
      status: MissionStatus.values.firstWhere(
        (status) => status.name == data['status'],
        orElse: () => MissionStatus.active,
      ),
      difficulty: MissionDifficulty.values.firstWhere(
        (difficulty) => difficulty.name == data['difficulty'],
        orElse: () => MissionDifficulty.beginner,
      ),
      goalType: data['goalType'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      completedAt: data['completedAt'] != null
          ? (data['completedAt'] as Timestamp).toDate()
          : null,
      expiresAt: data['expiresAt'] != null
          ? (data['expiresAt'] as Timestamp).toDate()
          : null,
      durationDays: data['durationDays'] ?? 7,
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'title': title,
      'description': description,
      'steps': steps.map((step) => step.toMap()).toList(),
      'status': status.name,
      'difficulty': difficulty.name,
      'goalType': goalType,
      'createdAt': Timestamp.fromDate(createdAt),
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
      'durationDays': durationDays,
      'metadata': metadata,
    };
  }

  // Utility methods
  double get progressPercentage {
    if (steps.isEmpty) return 0.0;
    final completedSteps = steps.where((step) => step.isCompleted).length;
    return (completedSteps / steps.length) * 100;
  }

  bool get isCompleted => status == MissionStatus.completed;
  bool get isActive => status == MissionStatus.active;
  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);

  int get completedStepsCount => steps.where((step) => step.isCompleted).length;
  int get totalStepsCount => steps.length;

  List<MissionStep> get pendingSteps => steps.where((step) => !step.isCompleted).toList();
  MissionStep? get nextStep => pendingSteps.isNotEmpty ? pendingSteps.first : null;

  Mission copyWith({
    String? title,
    String? description,
    List<MissionStep>? steps,
    MissionStatus? status,
    MissionDifficulty? difficulty,
    DateTime? completedAt,
    DateTime? expiresAt,
    Map<String, dynamic>? metadata,
  }) {
    return Mission(
      id: id,
      userId: userId,
      title: title ?? this.title,
      description: description ?? this.description,
      steps: steps ?? this.steps,
      status: status ?? this.status,
      difficulty: difficulty ?? this.difficulty,
      goalType: goalType,
      createdAt: createdAt,
      completedAt: completedAt ?? this.completedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      durationDays: durationDays,
      metadata: metadata ?? this.metadata,
    );
  }
}

class MissionStep {
  final String id;
  final String title;
  final String description;
  final bool isCompleted;
  final DateTime? completedAt;
  final int order;
  final String? actionType; // 'log_meal', 'start_fast', 'exercise', 'read', etc.
  final Map<String, dynamic> actionData;

  MissionStep({
    required this.id,
    required this.title,
    required this.description,
    this.isCompleted = false,
    this.completedAt,
    required this.order,
    this.actionType,
    this.actionData = const {},
  });

  factory MissionStep.fromMap(Map<String, dynamic> map) {
    return MissionStep(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      isCompleted: map['isCompleted'] ?? false,
      completedAt: map['completedAt'] != null
          ? (map['completedAt'] as Timestamp).toDate()
          : null,
      order: map['order'],
      actionType: map['actionType'],
      actionData: Map<String, dynamic>.from(map['actionData'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'isCompleted': isCompleted,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'order': order,
      'actionType': actionType,
      'actionData': actionData,
    };
  }

  MissionStep copyWith({
    String? title,
    String? description,
    bool? isCompleted,
    DateTime? completedAt,
    int? order,
    String? actionType,
    Map<String, dynamic>? actionData,
  }) {
    return MissionStep(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      order: order ?? this.order,
      actionType: actionType ?? this.actionType,
      actionData: actionData ?? this.actionData,
    );
  }
} 