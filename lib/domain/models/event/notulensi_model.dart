import 'package:hive/hive.dart';

part 'notulensi_model.g.dart';

@HiveType(typeId: 8)
class NotulensiModel extends HiveObject {
  @HiveField(0)
  final String eventId;

  @HiveField(1)
  String content;

  @HiveField(2)
  final DateTime updatedAt;

  @HiveField(3)
  final String updatedBy;

  @HiveField(4)
  bool isSynced;

  NotulensiModel({
    required this.eventId,
    required this.content,
    required this.updatedAt,
    required this.updatedBy,
    this.isSynced = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'eventId': eventId,
      'content': content,
      'updatedAt': updatedAt.toIso8601String(),
      'updatedBy': updatedBy,
      'isSynced': isSynced,
    };
  }

  factory NotulensiModel.fromMap(Map<String, dynamic> map) {
    return NotulensiModel(
      eventId: map['eventId'],
      content: map['content'],
      updatedAt: DateTime.tryParse(map['updatedAt'] ?? '') ?? DateTime.now(),
      updatedBy: map['updatedBy'] ?? 'system',
      isSynced: map['isSynced'] ?? false,
    );
  }

  NotulensiModel copyWith({
    String? eventId,
    String? content,
    DateTime? updatedAt,
    String? updatedBy,
    bool? isSynced,
  }) {
    return NotulensiModel(
      eventId: eventId ?? this.eventId,
      content: content ?? this.content,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}
