import 'package:dartz/dartz.dart';
import 'dart:typed_data';
import 'package:equatable/equatable.dart';
import 'package:testflutter/core/error/failures.dart';
import 'package:testflutter/core/usecases/usecase.dart';
import 'package:testflutter/domain/entities/note_entity.dart';
import 'package:testflutter/domain/repositories/note_repository.dart';

class GetAllNotesUseCase implements UseCase<List<NoteEntity>, NoParams> {
  final NoteRepository repository;

  GetAllNotesUseCase(this.repository);

  @override
  Future<Either<Failure, List<NoteEntity>>> call(NoParams params) async {
    return await repository.getAllNotes();
  }
}

class GetNoteByIdUseCase implements UseCase<NoteEntity, GetNoteByIdParams> {
  final NoteRepository repository;

  GetNoteByIdUseCase(this.repository);

  @override
  Future<Either<Failure, NoteEntity>> call(GetNoteByIdParams params) async {
    return await repository.getNoteById(params.id);
  }
}

class CreateNoteUseCase implements UseCase<int, CreateNoteParams> {
  final NoteRepository repository;

  CreateNoteUseCase(this.repository);

  @override
  Future<Either<Failure, int>> call(CreateNoteParams params) async {
    return await repository.createNote(params.note);
  }
}

class UpdateNoteUseCase implements UseCase<void, UpdateNoteParams> {
  final NoteRepository repository;

  UpdateNoteUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(UpdateNoteParams params) async {
    return await repository.updateNote(params.note);
  }
}

class DeleteNoteUseCase implements UseCase<void, DeleteNoteParams> {
  final NoteRepository repository;

  DeleteNoteUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(DeleteNoteParams params) async {
    return await repository.deleteNote(params.id);
  }
}

class SearchNotesUseCase implements UseCase<List<NoteEntity>, SearchNotesParams> {
  final NoteRepository repository;

  SearchNotesUseCase(this.repository);

  @override
  Future<Either<Failure, List<NoteEntity>>> call(SearchNotesParams params) async {
    return await repository.searchNotes(params.query);
  }
}

class ExtractTextFromImageUseCase implements UseCase<String, ExtractTextParams> {
  final NoteRepository repository;

  ExtractTextFromImageUseCase(this.repository);

  @override
  Future<Either<Failure, String>> call(ExtractTextParams params) async {
    return await repository.extractTextFromImage(params.imagePath);
  }
}

class ExtractTextFromImageBytesUseCase
    implements UseCase<String, ExtractTextBytesParams> {
  final NoteRepository repository;

  ExtractTextFromImageBytesUseCase(this.repository);

  @override
  Future<Either<Failure, String>> call(ExtractTextBytesParams params) async {
    return await repository.extractTextFromImageBytes(
      params.imageBytes,
      params.mimeType,
    );
  }
}

class SummarizeTextUseCase implements UseCase<String, SummarizeTextParams> {
  final NoteRepository repository;

  SummarizeTextUseCase(this.repository);

  @override
  Future<Either<Failure, String>> call(SummarizeTextParams params) async {
    return await repository.summarizeText(params.text);
  }
}

class GenerateTagsUseCase implements UseCase<List<String>, GenerateTagsParams> {
  final NoteRepository repository;

  GenerateTagsUseCase(this.repository);

  @override
  Future<Either<Failure, List<String>>> call(GenerateTagsParams params) async {
    return await repository.generateTags(params.text);
  }
}

// Params classes
class GetNoteByIdParams extends Equatable {
  final int id;

  const GetNoteByIdParams(this.id);

  @override
  List<Object> get props => [id];
}

class CreateNoteParams extends Equatable {
  final NoteEntity note;

  const CreateNoteParams(this.note);

  @override
  List<Object> get props => [note];
}

class UpdateNoteParams extends Equatable {
  final NoteEntity note;

  const UpdateNoteParams(this.note);

  @override
  List<Object> get props => [note];
}

class DeleteNoteParams extends Equatable {
  final int id;

  const DeleteNoteParams(this.id);

  @override
  List<Object> get props => [id];
}

class SearchNotesParams extends Equatable {
  final String query;

  const SearchNotesParams(this.query);

  @override
  List<Object> get props => [query];
}

class ExtractTextParams extends Equatable {
  final String imagePath;

  const ExtractTextParams(this.imagePath);

  @override
  List<Object> get props => [imagePath];
}

class ExtractTextBytesParams extends Equatable {
  final Uint8List imageBytes;
  final String mimeType;

  const ExtractTextBytesParams(this.imageBytes, this.mimeType);

  @override
  List<Object> get props => [imageBytes.length, mimeType];
}

class SummarizeTextParams extends Equatable {
  final String text;

  const SummarizeTextParams(this.text);

  @override
  List<Object> get props => [text];
}

class GenerateTagsParams extends Equatable {
  final String text;

  const GenerateTagsParams(this.text);

  @override
  List<Object> get props => [text];
}
