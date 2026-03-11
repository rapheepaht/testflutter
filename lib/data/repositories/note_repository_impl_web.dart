import 'package:dartz/dartz.dart';
import 'dart:typed_data';
import 'package:testflutter/core/error/failures.dart';
import 'package:testflutter/data/datasources/local/note_web_data_source.dart';
import 'package:testflutter/data/datasources/remote/note_remote_data_source.dart';
import 'package:testflutter/data/models/note_model.dart';
import 'package:testflutter/domain/entities/note_entity.dart';
import 'package:testflutter/domain/repositories/note_repository.dart';
import 'package:testflutter/core/error/exceptions.dart' as custom_exceptions;

class NoteRepositoryImplWeb implements NoteRepository {
  final NoteWebDataSource webDataSource;
  final NoteRemoteDataSource remoteDataSource;

  NoteRepositoryImplWeb({
    required this.webDataSource,
    required this.remoteDataSource,
  });

  @override
  Future<Either<Failure, List<NoteEntity>>> getAllNotes() async {
    try {
      final notes = await webDataSource.getAllNotes();
      return Right(notes);
    } on custom_exceptions.NoteDataException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unknown error occurred'));
    }
  }

  @override
  Future<Either<Failure, NoteEntity>> getNoteById(int id) async {
    try {
      final note = await webDataSource.getNoteById(id);
      if (note == null) {
        return Left(DatabaseFailure('Note not found'));
      }
      return Right(note);
    } on custom_exceptions.NoteDataException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unknown error occurred'));
    }
  }

  @override
  Future<Either<Failure, int>> createNote(NoteEntity note) async {
    try {
      final noteModel = NoteModel(
        title: note.title,
        content: note.content,
        imagePath: note.imagePath,
        extractedText: note.extractedText,
        summary: note.summary,
        tags: note.tags,
        createdAt: note.createdAt,
        updatedAt: note.updatedAt,
      );
      final noteId = await webDataSource.createNote(noteModel);
      return Right(noteId);
    } on custom_exceptions.NoteDataException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unknown error occurred'));
    }
  }

  @override
  Future<Either<Failure, int>> updateNote(NoteEntity note) async {
    try {
      final noteModel = NoteModel(
        id: note.id,
        title: note.title,
        content: note.content,
        imagePath: note.imagePath,
        extractedText: note.extractedText,
        summary: note.summary,
        tags: note.tags,
        createdAt: note.createdAt,
        updatedAt: DateTime.now(),
      );
      final result = await webDataSource.updateNote(noteModel);
      return Right(result);
    } on custom_exceptions.NoteDataException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unknown error occurred'));
    }
  }

  @override
  Future<Either<Failure, int>> deleteNote(int id) async {
    try {
      final result = await webDataSource.deleteNote(id);
      return Right(result);
    } on custom_exceptions.NoteDataException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unknown error occurred'));
    }
  }

  @override
  Future<Either<Failure, List<NoteEntity>>> searchNotes(String query) async {
    try {
      final notes = await webDataSource.searchNotes(query);
      return Right(notes);
    } on custom_exceptions.NoteDataException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unknown error occurred'));
    }
  }

  @override
  Future<Either<Failure, String>> extractTextFromImage(String imagePath) async {
    try {
      final extractedText = await remoteDataSource.extractTextFromImage(imagePath);
      return Right(extractedText);
    } on custom_exceptions.MLKitException catch (e) {
      return Left(MLKitFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unknown error occurred'));
    }
  }

  @override
  Future<Either<Failure, String>> extractTextFromImageBytes(
    Uint8List imageBytes,
    String mimeType,
  ) async {
    try {
      final extractedText = await remoteDataSource.extractTextFromImageBytes(imageBytes, mimeType);
      return Right(extractedText);
    } on custom_exceptions.GeminiAPIException catch (e) {
      return Left(GeminiAPIFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unknown error occurred'));
    }
  }

  @override
  Future<Either<Failure, String>> summarizeText(String text) async {
    try {
      final summary = await remoteDataSource.summarizeText(text);
      return Right(summary);
    } on custom_exceptions.GeminiAPIException catch (e) {
      return Left(GeminiAPIFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unknown error occurred'));
    }
  }

  @override
  Future<Either<Failure, List<String>>> generateTags(String text) async {
    try {
      final tags = await remoteDataSource.generateTags(text);
      return Right(tags);
    } on custom_exceptions.GeminiAPIException catch (e) {
      return Left(GeminiAPIFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unknown error occurred'));
    }
  }
}
