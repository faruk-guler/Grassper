import 'package:hive/hive.dart';

part 'note_model.g.dart';

@HiveType(typeId: 0)
class Note extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String content;

  @HiveField(3)
  bool isPinned;

  @HiveField(4)
  bool isArchived;

  @HiveField(5)
  int updatedAt;

  @HiveField(6)
  late int createdAt;

  @HiveField(7)
  bool isImportant;

  @HiveField(8)
  int? colorValue;

  @HiveField(9)
  String? imageBase64;

  @HiveField(10)
  String? drawingData;

  Note({
    required this.id,
    this.title = '',
    this.content = '',
    this.isPinned = false,
    this.isArchived = false,
    this.isImportant = false,
    this.colorValue,
    this.imageBase64,
    this.drawingData,
    required this.updatedAt,
    int? createdAt,
  }) : createdAt = createdAt ?? updatedAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'isPinned': isPinned,
      'isArchived': isArchived,
      'isImportant': isImportant,
      'colorValue': colorValue,
      'imageBase64': imageBase64,
      'drawingData': drawingData,
      'updatedAt': updatedAt,
      'createdAt': createdAt,
    };
  }

  factory Note.fromJson(Map<String, dynamic> json) {
    final updatedAt = json['updatedAt'] as int? ?? DateTime.now().millisecondsSinceEpoch;
    return Note(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      isPinned: json['isPinned'] as bool? ?? false,
      isArchived: json['isArchived'] as bool? ?? false,
      isImportant: json['isImportant'] as bool? ?? false,
      colorValue: json['colorValue'] as int?,
      imageBase64: json['imageBase64'] as String?,
      drawingData: json['drawingData'] as String?,
      updatedAt: updatedAt,
      createdAt: json['createdAt'] as int? ?? updatedAt,
    );
  }
}
