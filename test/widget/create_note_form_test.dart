import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:testflutter/presentation/bloc/note_bloc.dart';
import 'package:testflutter/presentation/pages/create_note_page.dart';

class MockNoteBloc implements NoteBloc {
  @override
  Stream<NoteState> get stream => Stream.value(const NoteInitial());

  @override
  NoteState get state => const NoteInitial();

  @override
  dynamic noSuchMethod(Invocation invocation) {}
}

void main() {
  testWidgets('form validation requires title and content', (tester) async {
    final mockBloc = MockNoteBloc();

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<NoteBloc>.value(
          value: mockBloc,
          child: const CreateNotePage(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Create Note').last);
    await tester.pumpAndSettle();

    expect(find.text('Title is required'), findsOneWidget);
    expect(find.text('Content is required'), findsOneWidget);
  });
}
