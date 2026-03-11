import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:typed_data';
import 'package:equatable/equatable.dart';
import 'package:testflutter/core/error/failures.dart';
import 'package:testflutter/core/usecases/usecase.dart';
import 'package:testflutter/domain/entities/note_entity.dart';
import 'package:testflutter/domain/usecases/note_usecases.dart';

// ============ EVENTS ============
abstract class NoteEvent extends Equatable {
  const NoteEvent();

  @override
  List<Object?> get props => [];
}

class GetAllNotesEvent extends NoteEvent {
  const GetAllNotesEvent();
}

class GetNoteByIdEvent extends NoteEvent {
  final int id;

  const GetNoteByIdEvent(this.id);

  @override
  List<Object> get props => [id];
}

class CreateNoteEvent extends NoteEvent {
  final NoteEntity note;

  const CreateNoteEvent(this.note);

  @override
  List<Object> get props => [note];
}

class UpdateNoteEvent extends NoteEvent {
  final NoteEntity note;

  const UpdateNoteEvent(this.note);

  @override
  List<Object> get props => [note];
}

class DeleteNoteEvent extends NoteEvent {
  final int id;

  const DeleteNoteEvent(this.id);

  @override
  List<Object> get props => [id];
}

class SearchNotesEvent extends NoteEvent {
  final String query;

  const SearchNotesEvent(this.query);

  @override
  List<Object> get props => [query];
}

class ExtractTextEvent extends NoteEvent {
  final String imagePath;

  const ExtractTextEvent(this.imagePath);

  @override
  List<Object> get props => [imagePath];
}

class ExtractTextBytesEvent extends NoteEvent {
  final Uint8List imageBytes;
  final String mimeType;

  const ExtractTextBytesEvent(this.imageBytes, this.mimeType);

  @override
  List<Object> get props => [imageBytes.length, mimeType];
}

class SummarizeTextEvent extends NoteEvent {
  final String text;

  const SummarizeTextEvent(this.text);

  @override
  List<Object> get props => [text];
}

class GenerateTagsEvent extends NoteEvent {
  final String text;

  const GenerateTagsEvent(this.text);

  @override
  List<Object> get props => [text];
}

// ============ STATES ============
abstract class NoteState extends Equatable {
  const NoteState();

  @override
  List<Object?> get props => [];
}

class NoteInitial extends NoteState {
  const NoteInitial();
}

class NoteLoading extends NoteState {
  const NoteLoading();
}

class NotesLoaded extends NoteState {
  final List<NoteEntity> notes;

  const NotesLoaded(this.notes);

  @override
  List<Object> get props => [notes];
}

class NoteLoaded extends NoteState {
  final NoteEntity note;

  const NoteLoaded(this.note);

  @override
  List<Object> get props => [note];
}

class NoteCreated extends NoteState {
  final int noteId;

  const NoteCreated(this.noteId);

  @override
  List<Object> get props => [noteId];
}

class NoteUpdated extends NoteState {
  const NoteUpdated();
}

class NoteDeleted extends NoteState {
  const NoteDeleted();
}

class NotesSearched extends NoteState {
  final List<NoteEntity> notes;

  const NotesSearched(this.notes);

  @override
  List<Object> get props => [notes];
}

class TextExtracted extends NoteState {
  final String extractedText;

  const TextExtracted(this.extractedText);

  @override
  List<Object> get props => [extractedText];
}

class TextSummarized extends NoteState {
  final String summary;

  const TextSummarized(this.summary);

  @override
  List<Object> get props => [summary];
}

class TagsGenerated extends NoteState {
  final List<String> tags;

  const TagsGenerated(this.tags);

  @override
  List<Object> get props => [tags];
}

class NoteError extends NoteState {
  final String message;

  const NoteError(this.message);

  @override
  List<Object> get props => [message];
}

// ============ BLoC ============
class NoteBloc extends Bloc<NoteEvent, NoteState> {
  final GetAllNotesUseCase getAllNotesUseCase;
  final GetNoteByIdUseCase getNoteByIdUseCase;
  final CreateNoteUseCase createNoteUseCase;
  final UpdateNoteUseCase updateNoteUseCase;
  final DeleteNoteUseCase deleteNoteUseCase;
  final SearchNotesUseCase searchNotesUseCase;
  final ExtractTextFromImageUseCase extractTextFromImageUseCase;
  final ExtractTextFromImageBytesUseCase extractTextFromImageBytesUseCase;
  final SummarizeTextUseCase summarizeTextUseCase;
  final GenerateTagsUseCase generateTagsUseCase;

  NoteBloc({
    required this.getAllNotesUseCase,
    required this.getNoteByIdUseCase,
    required this.createNoteUseCase,
    required this.updateNoteUseCase,
    required this.deleteNoteUseCase,
    required this.searchNotesUseCase,
    required this.extractTextFromImageUseCase,
    required this.extractTextFromImageBytesUseCase,
    required this.summarizeTextUseCase,
    required this.generateTagsUseCase,
  }) : super(const NoteInitial()) {
    on<GetAllNotesEvent>(_onGetAllNotes);
    on<GetNoteByIdEvent>(_onGetNoteById);
    on<CreateNoteEvent>(_onCreateNote);
    on<UpdateNoteEvent>(_onUpdateNote);
    on<DeleteNoteEvent>(_onDeleteNote);
    on<SearchNotesEvent>(_onSearchNotes);
    on<ExtractTextEvent>(_onExtractText);
    on<ExtractTextBytesEvent>(_onExtractTextBytes);
    on<SummarizeTextEvent>(_onSummarizeText);
    on<GenerateTagsEvent>(_onGenerateTags);
  }

  Future<void> _onGetAllNotes(GetAllNotesEvent event, Emitter<NoteState> emit) async {
    emit(const NoteLoading());
    final result = await getAllNotesUseCase(NoParams());
    result.fold(
      (failure) => emit(NoteError(_mapFailureToMessage(failure))),
      (notes) => emit(NotesLoaded(notes)),
    );
  }

  Future<void> _onGetNoteById(GetNoteByIdEvent event, Emitter<NoteState> emit) async {
    emit(const NoteLoading());
    final result = await getNoteByIdUseCase(GetNoteByIdParams(event.id));
    result.fold(
      (failure) => emit(NoteError(_mapFailureToMessage(failure))),
      (note) => emit(NoteLoaded(note)),
    );
  }

  Future<void> _onCreateNote(CreateNoteEvent event, Emitter<NoteState> emit) async {
    emit(const NoteLoading());
    final result = await createNoteUseCase(CreateNoteParams(event.note));
    await result.fold(
      (failure) async => emit(NoteError(_mapFailureToMessage(failure))),
      (noteId) async {
        emit(NoteCreated(noteId));
        await _emitAllNotes(emit);
      },
    );
  }

  Future<void> _onUpdateNote(UpdateNoteEvent event, Emitter<NoteState> emit) async {
    emit(const NoteLoading());
    final result = await updateNoteUseCase(UpdateNoteParams(event.note));
    await result.fold(
      (failure) async => emit(NoteError(_mapFailureToMessage(failure))),
      (_) async {
        emit(const NoteUpdated());
        await _emitAllNotes(emit);
      },
    );
  }

  Future<void> _onDeleteNote(DeleteNoteEvent event, Emitter<NoteState> emit) async {
    emit(const NoteLoading());
    final result = await deleteNoteUseCase(DeleteNoteParams(event.id));
    await result.fold(
      (failure) async => emit(NoteError(_mapFailureToMessage(failure))),
      (_) async {
        emit(const NoteDeleted());
        await _emitAllNotes(emit);
      },
    );
  }

  Future<void> _onSearchNotes(SearchNotesEvent event, Emitter<NoteState> emit) async {
    emit(const NoteLoading());
    final result = await searchNotesUseCase(SearchNotesParams(event.query));
    result.fold(
      (failure) => emit(NoteError(_mapFailureToMessage(failure))),
      (notes) => emit(NotesSearched(notes)),
    );
  }

  Future<void> _onExtractText(ExtractTextEvent event, Emitter<NoteState> emit) async {
    emit(const NoteLoading());
    final result = await extractTextFromImageUseCase(ExtractTextParams(event.imagePath));
    result.fold(
      (failure) => emit(NoteError(_mapFailureToMessage(failure))),
      (text) => emit(TextExtracted(text)),
    );
  }

  Future<void> _onExtractTextBytes(
    ExtractTextBytesEvent event,
    Emitter<NoteState> emit,
  ) async {
    emit(const NoteLoading());
    final result = await extractTextFromImageBytesUseCase(
      ExtractTextBytesParams(event.imageBytes, event.mimeType),
    );
    result.fold(
      (failure) => emit(NoteError(_mapFailureToMessage(failure))),
      (text) => emit(TextExtracted(text)),
    );
  }

  Future<void> _onSummarizeText(SummarizeTextEvent event, Emitter<NoteState> emit) async {
    emit(const NoteLoading());
    final result = await summarizeTextUseCase(SummarizeTextParams(event.text));
    result.fold(
      (failure) => emit(NoteError(_mapFailureToMessage(failure))),
      (summary) => emit(TextSummarized(summary)),
    );
  }

  Future<void> _onGenerateTags(GenerateTagsEvent event, Emitter<NoteState> emit) async {
    emit(const NoteLoading());
    final result = await generateTagsUseCase(GenerateTagsParams(event.text));
    result.fold(
      (failure) => emit(NoteError(_mapFailureToMessage(failure))),
      (tags) => emit(TagsGenerated(tags)),
    );
  }

  Future<void> _emitAllNotes(Emitter<NoteState> emit) async {
    final notesResult = await getAllNotesUseCase(NoParams());
    notesResult.fold(
      (failure) => emit(NoteError(_mapFailureToMessage(failure))),
      (notes) => emit(NotesLoaded(notes)),
    );
  }

  String _mapFailureToMessage(Failure failure) {
    if (failure is DatabaseFailure) {
      return 'Database Error: ${failure.message}';
    } else if (failure is MLKitFailure) {
      return 'ML Kit Error: ${failure.message}';
    } else if (failure is GeminiAPIFailure) {
      return 'API Error: ${failure.message}';
    } else {
      return 'Unknown Error: ${failure.message}';
    }
  }
}
