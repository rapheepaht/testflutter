import 'package:equatable/equatable.dart';

class NoteEntity extends Equatable {
  final int? id;
  final String title;
  final String content;
  final String? imagePath;
  final String? extractedText;
  final String? summary;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;

  const NoteEntity({
    this.id,
    required this.title,
    required this.content,
    this.imagePath,
    this.extractedText,
    this.summary,
    required this.tags,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        title,
        content,
        imagePath,
        extractedText,
        summary,
        tags,
        createdAt,
        updatedAt,
      ];
}
