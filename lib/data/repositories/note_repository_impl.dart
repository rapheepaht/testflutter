import 'package:dartz/dartz.dart';
import 'dart:typed_data';
import 'package:testflutter/core/error/exceptions.dart' as custom_exceptions;
import 'package:testflutter/core/error/failures.dart';
import 'package:testflutter/data/datasources/local/note_local_data_source.dart';
import 'package:testflutter/data/datasources/remote/note_remote_data_source.dart';
import 'package:testflutter/data/models/note_model.dart';
import 'package:testflutter/domain/entities/note_entity.dart';
import 'package:testflutter/domain/repositories/note_repository.dart';

class NoteRepositoryImpl implements NoteRepository {
  final NoteLocalDataSource localDataSource;
  final NoteRemoteDataSource remoteDataSource;

  NoteRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
  });

  @override
  Future<Either<Failure, List<NoteEntity>>> getAllNotes() async {
    try {
      final notes = await localDataSource.getAllNotes();
      return Right(notes);
    } on custom_exceptions.NoteDataException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, NoteEntity>> getNoteById(int id) async {
    try {
      final note = await localDataSource.getNoteById(id);
      return Right(note);
    } on custom_exceptions.NoteDataException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
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
      final id = await localDataSource.createNote(noteModel);
      return Right(id);
    } on custom_exceptions.NoteDataException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateNote(NoteEntity note) async {
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
        updatedAt: note.updatedAt,
      );
      await localDataSource.updateNote(noteModel);
      return const Right(null);
    } on custom_exceptions.NoteDataException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteNote(int id) async {
    try {
      await localDataSource.deleteNote(id);
      return const Right(null);
    } on custom_exceptions.NoteDataException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<NoteEntity>>> searchNotes(String query) async {
    try {
      final notes = await localDataSource.searchNotes(query);
      return Right(notes);
    } on custom_exceptions.NoteDataException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
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
      return Left(UnknownFailure(e.toString()));
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
      return Left(UnknownFailure(e.toString()));
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
      return Left(UnknownFailure(e.toString()));
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
      return Left(UnknownFailure(e.toString()));
    }
  }
}
