import 'package:dartz/dartz.dart';
import 'dart:typed_data';
import 'package:testflutter/core/error/failures.dart';
import 'package:testflutter/domain/entities/note_entity.dart';

abstract class NoteRepository {
  // Local operations
  Future<Either<Failure, List<NoteEntity>>> getAllNotes();
  Future<Either<Failure, NoteEntity>> getNoteById(int id);
  Future<Either<Failure, int>> createNote(NoteEntity note);
  Future<Either<Failure, void>> updateNote(NoteEntity note);
  Future<Either<Failure, void>> deleteNote(int id);
  Future<Either<Failure, List<NoteEntity>>> searchNotes(String query);

  // ML Kit operations
  Future<Either<Failure, String>> extractTextFromImage(String imagePath);
  Future<Either<Failure, String>> extractTextFromImageBytes(Uint8List imageBytes, String mimeType);

  // Gemini API operations
  Future<Either<Failure, String>> summarizeText(String text);
  Future<Either<Failure, List<String>>> generateTags(String text);
}
