import 'package:testflutter/domain/entities/note_entity.dart';

class NoteModel extends NoteEntity {
  const NoteModel({
    int? id,
    required String title,
    required String content,
    String? imagePath,
    String? extractedText,
    String? summary,
    required List<String> tags,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super(
    id: id,
    title: title,
    content: content,
    imagePath: imagePath,
    extractedText: extractedText,
    summary: summary,
    tags: tags,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );

  /// Create from JSON
  factory NoteModel.fromJson(Map<String, dynamic> json) {
    return NoteModel(
      id: json['id'] as int?,
      title: json['title'] as String,
      content: json['content'] as String,
      imagePath: json['imagePath'] as String?,
      extractedText: json['extractedText'] as String?,
      summary: json['summary'] as String?,
      tags: List<String>.from(json['tags'] as List? ?? []),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'imagePath': imagePath,
      'extractedText': extractedText,
      'summary': summary,
      'tags': tags,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Create from Database (SQLite)
  factory NoteModel.fromDatabase(Map<String, dynamic> map) {
    return NoteModel(
      id: map['id'] as int,
      title: map['title'] as String,
      content: map['content'] as String,
      imagePath: map['imagePath'] as String?,
      extractedText: map['extractedText'] as String?,
      summary: map['summary'] as String?,
      tags: (map['tags'] as String? ?? '').split('|').where((e) => e.isNotEmpty).toList(),
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  /// Convert to Database (SQLite)
  Map<String, dynamic> toDatabase() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'imagePath': imagePath,
      'extractedText': extractedText,
      'summary': summary,
      'tags': tags.join('|'),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Create a copy of this note with some fields replaced
  NoteModel copyWith({
    int? id,
    String? title,
    String? content,
    String? imagePath,
    String? extractedText,
    String? summary,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NoteModel(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      imagePath: imagePath ?? this.imagePath,
      extractedText: extractedText ?? this.extractedText,
      summary: summary ?? this.summary,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
