import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:testflutter/domain/entities/note_entity.dart';
import 'package:testflutter/presentation/bloc/note_bloc.dart';
import 'package:testflutter/presentation/pages/home_page.dart';

class MockNoteBloc extends Mock implements NoteBloc {
  @override
  Stream<NoteState> get stream => Stream.value(const NoteInitial());

  @override
  NoteState get state => const NoteInitial();
}

void main() {
  group('HomePage Widget Tests', () {
    late MockNoteBloc mockNoteBloc;

    setUp(() {
      mockNoteBloc = MockNoteBloc();
    });

    testWidgets('should display empty state when no notes', (WidgetTester tester) async {
      // Arrange
      when(() => mockNoteBloc.state).thenReturn(const NotesLoaded([]));
      when(() => mockNoteBloc.stream).thenAnswer((_) => Stream.value(const NotesLoaded([])));

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<NoteBloc>.value(
            value: mockNoteBloc,
            child: const HomePage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('No notes yet'), findsOneWidget);
      expect(find.byIcon(Icons.note_outlined), findsOneWidget);
    });

    testWidgets('should display loading state', (WidgetTester tester) async {
      // Arrange
      when(() => mockNoteBloc.state).thenReturn(const NoteLoading());
      when(() => mockNoteBloc.stream).thenAnswer((_) => Stream.value(const NoteLoading()));

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<NoteBloc>.value(
            value: mockNoteBloc,
            child: const HomePage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should display notes list when loaded', (WidgetTester tester) async {
      // Arrange
      final notes = [
        NoteEntity(
          id: 1,
          title: 'Test Note 1',
          content: 'Content 1',
          tags: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        NoteEntity(
          id: 2,
          title: 'Test Note 2',
          content: 'Content 2',
          tags: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      when(() => mockNoteBloc.state).thenReturn(NotesLoaded(notes));
      when(() => mockNoteBloc.stream).thenAnswer((_) => Stream.value(NotesLoaded(notes)));

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<NoteBloc>.value(
            value: mockNoteBloc,
            child: const HomePage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Test Note 1'), findsOneWidget);
      expect(find.text('Test Note 2'), findsOneWidget);
      expect(find.byType(ListTile), findsWidgets);
    });

    testWidgets('should display error message on failure', (WidgetTester tester) async {
      // Arrange
      const errorMessage = 'Failed to load notes';
      when(() => mockNoteBloc.state).thenReturn(const NoteError(errorMessage));
      when(() => mockNoteBloc.stream).thenAnswer((_) => Stream.value(const NoteError(errorMessage)));

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<NoteBloc>.value(
            value: mockNoteBloc,
            child: const HomePage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Error: $errorMessage'), findsOneWidget);
    });

    testWidgets('should have FAB to create note', (WidgetTester tester) async {
      // Arrange
      when(() => mockNoteBloc.state).thenReturn(const NotesLoaded([]));
      when(() => mockNoteBloc.stream).thenAnswer((_) => Stream.value(const NotesLoaded([])));

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<NoteBloc>.value(
            value: mockNoteBloc,
            child: const HomePage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });
  });
}
