import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:sqflite/sqflite.dart';
import 'package:testflutter/core/network/dio_client.dart';
import 'package:testflutter/data/datasources/local/note_local_data_source.dart';
import 'package:testflutter/data/datasources/local/note_web_data_source.dart';
import 'package:testflutter/data/datasources/remote/ping_remote_data_source.dart';
import 'package:testflutter/data/datasources/remote/note_remote_data_source.dart';
import 'package:testflutter/data/repositories/note_repository_impl.dart';
import 'package:testflutter/data/repositories/note_repository_impl_web.dart';
import 'package:testflutter/domain/repositories/note_repository.dart';
import 'package:testflutter/domain/usecases/note_usecases.dart';
import 'package:testflutter/presentation/bloc/note_bloc.dart';

final getIt = GetIt.instance;

Future<void> setupServiceLocator(Database? database, String geminiApiKey) async {
  await getIt.reset();

  getIt.registerSingleton(DioClient.instance);

  getIt.registerSingleton<PingRemoteDataSource>(
    PingRemoteDataSourceImpl(dio: getIt()),
  );

  // ============ Data Sources ============
  if (kIsWeb) {
    // Use web-compatible data source
    getIt.registerSingleton<NoteWebDataSource>(
      NoteWebDataSourceImpl(),
    );
  } else {
    // Use SQLite data source for mobile
    getIt.registerSingleton<NoteLocalDataSource>(
      NoteLocalDataSourceImpl(database!),
    );
  }

  getIt.registerSingleton<NoteRemoteDataSource>(
    NoteRemoteDataSourceImpl(
      geminiApiKey: geminiApiKey,
    ),
  );

  // ============ Repositories ============
  if (kIsWeb) {
    getIt.registerSingleton<NoteRepository>(
      NoteRepositoryImplWeb(
        webDataSource: getIt<NoteWebDataSource>(),
        remoteDataSource: getIt<NoteRemoteDataSource>(),
      ),
    );
  } else {
    getIt.registerSingleton<NoteRepository>(
      NoteRepositoryImpl(
        localDataSource: getIt<NoteLocalDataSource>(),
        remoteDataSource: getIt<NoteRemoteDataSource>(),
      ),
    );
  }

  // ============ Use Cases ============
  getIt.registerSingleton<GetAllNotesUseCase>(
    GetAllNotesUseCase(getIt<NoteRepository>()),
  );

  getIt.registerSingleton<GetNoteByIdUseCase>(
    GetNoteByIdUseCase(getIt<NoteRepository>()),
  );

  getIt.registerSingleton<CreateNoteUseCase>(
    CreateNoteUseCase(getIt<NoteRepository>()),
  );

  getIt.registerSingleton<UpdateNoteUseCase>(
    UpdateNoteUseCase(getIt<NoteRepository>()),
  );

  getIt.registerSingleton<DeleteNoteUseCase>(
    DeleteNoteUseCase(getIt<NoteRepository>()),
  );

  getIt.registerSingleton<SearchNotesUseCase>(
    SearchNotesUseCase(getIt<NoteRepository>()),
  );

  getIt.registerSingleton<ExtractTextFromImageUseCase>(
    ExtractTextFromImageUseCase(getIt<NoteRepository>()),
  );

  getIt.registerSingleton<ExtractTextFromImageBytesUseCase>(
    ExtractTextFromImageBytesUseCase(getIt<NoteRepository>()),
  );

  getIt.registerSingleton<SummarizeTextUseCase>(
    SummarizeTextUseCase(getIt<NoteRepository>()),
  );

  getIt.registerSingleton<GenerateTagsUseCase>(
    GenerateTagsUseCase(getIt<NoteRepository>()),
  );

  // ============ BLoCs ============
  getIt.registerSingleton<NoteBloc>(
    NoteBloc(
      getAllNotesUseCase: getIt<GetAllNotesUseCase>(),
      getNoteByIdUseCase: getIt<GetNoteByIdUseCase>(),
      createNoteUseCase: getIt<CreateNoteUseCase>(),
      updateNoteUseCase: getIt<UpdateNoteUseCase>(),
      deleteNoteUseCase: getIt<DeleteNoteUseCase>(),
      searchNotesUseCase: getIt<SearchNotesUseCase>(),
      extractTextFromImageUseCase: getIt<ExtractTextFromImageUseCase>(),
      extractTextFromImageBytesUseCase: getIt<ExtractTextFromImageBytesUseCase>(),
      summarizeTextUseCase: getIt<SummarizeTextUseCase>(),
      generateTagsUseCase: getIt<GenerateTagsUseCase>(),
    ),
  );
}
