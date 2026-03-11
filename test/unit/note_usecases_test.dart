import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:testflutter/core/error/failures.dart';
import 'package:testflutter/core/usecases/usecase.dart';
import 'package:testflutter/domain/entities/note_entity.dart';
import 'package:testflutter/domain/repositories/note_repository.dart';
import 'package:testflutter/domain/usecases/note_usecases.dart';

class MockNoteRepository extends Mock implements NoteRepository {}

void main() {
  late GetAllNotesUseCase getAllNotesUseCase;
  late MockNoteRepository mockNoteRepository;

  setUp(() {
    mockNoteRepository = MockNoteRepository();
    getAllNotesUseCase = GetAllNotesUseCase(mockNoteRepository);
  });

  group('GetAllNotesUseCase', () {
    final tNotes = [
      NoteEntity(
        id: 1,
        title: 'Test Note 1',
        content: 'Content 1',
        tags: ['tag1'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      NoteEntity(
        id: 2,
        title: 'Test Note 2',
        content: 'Content 2',
        tags: ['tag2'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];

    test('should return list of notes when successful', () async {
      // Arrange
      when(() => mockNoteRepository.getAllNotes())
          .thenAnswer((_) async => Right(tNotes));

      // Act
      final result = await getAllNotesUseCase(NoParams());

      // Assert
      expect(result, Right(tNotes));
      verify(() => mockNoteRepository.getAllNotes()).called(1);
      verifyNoMoreInteractions(mockNoteRepository);
    });

    test('should return failure when repository fails', () async {
      // Arrange
      const failure = DatabaseFailure('Database error');
      when(() => mockNoteRepository.getAllNotes())
          .thenAnswer((_) async => const Left(failure));

      // Act
      final result = await getAllNotesUseCase(NoParams());

      // Assert
      expect(result, const Left(failure));
      verify(() => mockNoteRepository.getAllNotes()).called(1);
      verifyNoMoreInteractions(mockNoteRepository);
    });
  });

  group('CreateNoteUseCase', () {
    late CreateNoteUseCase createNoteUseCase;

    setUp(() {
      createNoteUseCase = CreateNoteUseCase(mockNoteRepository);
    });

    final tNote = NoteEntity(
      title: 'New Note',
      content: 'New Content',
      tags: [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    test('should create a note and return its id', () async {
      // Arrange
      when(() => mockNoteRepository.createNote(any()))
          .thenAnswer((_) async => const Right(1));

      // Act
      final result = await createNoteUseCase(CreateNoteParams(tNote));

      // Assert
      expect(result, const Right(1));
      verify(() => mockNoteRepository.createNote(any())).called(1);
      verifyNoMoreInteractions(mockNoteRepository);
    });

    test('should return failure when creation fails', () async {
      // Arrange
      const failure = DatabaseFailure('Failed to create note');
      when(() => mockNoteRepository.createNote(any()))
          .thenAnswer((_) async => const Left(failure));

      // Act
      final result = await createNoteUseCase(CreateNoteParams(tNote));

      // Assert
      expect(result, const Left(failure));
      verify(() => mockNoteRepository.createNote(any())).called(1);
      verifyNoMoreInteractions(mockNoteRepository);
    });
  });

  group('ExtractTextFromImageUseCase', () {
    late ExtractTextFromImageUseCase extractTextUseCase;

    setUp(() {
      extractTextUseCase = ExtractTextFromImageUseCase(mockNoteRepository);
    });

    const tImagePath = '/path/to/image.jpg';
    const tExtractedText = 'This is extracted text from image';

    test('should extract text from image successfully', () async {
      // Arrange
      when(() => mockNoteRepository.extractTextFromImage(any()))
          .thenAnswer((_) async => const Right(tExtractedText));

      // Act
      final result = await extractTextUseCase(
        const ExtractTextParams(tImagePath),
      );

      // Assert
      expect(result, const Right(tExtractedText));
      verify(() => mockNoteRepository.extractTextFromImage(tImagePath))
          .called(1);
      verifyNoMoreInteractions(mockNoteRepository);
    });

    test('should return failure when text extraction fails', () async {
      // Arrange
      const failure = MLKitFailure('Failed to extract text');
      when(() => mockNoteRepository.extractTextFromImage(any()))
          .thenAnswer((_) async => const Left(failure));

      // Act
      final result = await extractTextUseCase(
        const ExtractTextParams(tImagePath),
      );

      // Assert
      expect(result, const Left(failure));
      verify(() => mockNoteRepository.extractTextFromImage(tImagePath))
          .called(1);
      verifyNoMoreInteractions(mockNoteRepository);
    });
  });
}
