# 🎯 State Management & Navigation Documentation

## **สรุป: Smart Vision Journal ใช้**

✅ **State Management**: BLoC 8.1.3 + Equatable
✅ **Navigation**: auto_route 7.8.4 with Typed Routes
✅ **ไม่มี setState** ในลอจิกหลัก - ทุกอย่างผ่าน BLoC

---

## **1️⃣ State Management: BLoC Pattern**

### **A. Event Definition (Input)**

```dart
// lib/presentation/bloc/note_bloc/note_event.dart
abstract class NoteEvent extends Equatable {
  const NoteEvent();
}

// CRUD Events
class GetAllNotesEvent extends NoteEvent {
  const GetAllNotesEvent();
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

// AI/ML Events
class ExtractTextFromImageEvent extends NoteEvent {
  final String imagePath;
  const ExtractTextFromImageEvent(this.imagePath);
  
  @override
  List<Object> get props => [imagePath];
}

class ExtractTextFromImageBytesEvent extends NoteEvent {
  final Uint8List imageBytes;
  final String mimeType;
  const ExtractTextFromImageBytesEvent(this.imageBytes, this.mimeType);
  
  @override
  List<Object> get props => [imageBytes, mimeType];
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
```

### **B. State Definition (Output)**

```dart
// lib/presentation/bloc/note_bloc/note_state.dart
abstract class NoteState extends Equatable {
  const NoteState();
}

// Loading State
class NoteLoading extends NoteState {
  const NoteLoading();
  
  @override
  List<Object> get props => [];
}

// Success States
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
  
  @override
  List<Object> get props => [];
}

class NoteDeleted extends NoteState {
  const NoteDeleted();
  
  @override
  List<Object> get props => [];
}

class NotesSearched extends NoteState {
  final List<NoteEntity> searchResults;
  const NotesSearched(this.searchResults);
  
  @override
  List<Object> get props => [searchResults];
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

// Error State
class NoteError extends NoteState {
  final String message;
  const NoteError(this.message);
  
  @override
  List<Object> get props => [message];
}
```

### **C. BLoC Implementation**

```dart
// lib/presentation/bloc/note_bloc.dart
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
  }) : super(const NoteLoading()) {
    // Register event handlers
    on<GetAllNotesEvent>(_onGetAllNotes);
    on<GetNoteByIdEvent>(_onGetNoteById);
    on<CreateNoteEvent>(_onCreateNote);
    on<UpdateNoteEvent>(_onUpdateNote);
    on<DeleteNoteEvent>(_onDeleteNote);
    on<SearchNotesEvent>(_onSearchNotes);
    on<ExtractTextFromImageEvent>(_onExtractTextFromImage);
    on<ExtractTextFromImageBytesEvent>(_onExtractTextFromImageBytes);
    on<SummarizeTextEvent>(_onSummarizeText);
    on<GenerateTagsEvent>(_onGenerateTags);
  }

  // Event Handler with Either Pattern (Dartz)
  Future<void> _onGetAllNotes(GetAllNotesEvent event, Emitter<NoteState> emit) async {
    emit(const NoteLoading());
    
    final result = await getAllNotesUseCase(NoParams());
    
    // fold = Pattern matching on Either<Failure, Success>
    result.fold(
      (failure) => emit(NoteError(_mapFailureToMessage(failure))),
      (notes) => emit(NotesLoaded(notes)),
    );
  }

  Future<void> _onCreateNote(CreateNoteEvent event, Emitter<NoteState> emit) async {
    emit(const NoteLoading());
    
    final result = await createNoteUseCase(CreateNoteParams(event.note));
    
    result.fold(
      (failure) => emit(NoteError(_mapFailureToMessage(failure))),
      (noteId) => emit(NoteCreated(noteId)),
    );
  }

  // Error mapping with type-safe pattern matching
  String _mapFailureToMessage(Failure failure) {
    if (failure is DatabaseFailure) {
      return 'ฐานข้อมูลผิดพลาด: ${failure.message}';
    } else if (failure is MLKitFailure) {
      return 'ML Kit ผิดพลาด: ${failure.message}';
    } else if (failure is GeminiAPIFailure) {
      return 'API ผิดพลาด: ${failure.message}';
    } else {
      return 'ข้อผิดพลาดที่ไม่ทราบ: ${failure.message}';
    }
  }
}
```

### **D. Using BLoC in UI**

```dart
// lib/presentation/pages/home_page.dart
class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('โน้ต')),
      body: BlocBuilder<NoteBloc, NoteState>(
        builder: (context, state) {
          // Render based on state
          if (state is NoteLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is NotesLoaded) {
            return ListView.builder(
              itemCount: state.notes.length,
              itemBuilder: (context, index) {
                final note = state.notes[index];
                return ListTile(
                  title: Text(note.title),
                  subtitle: Text(note.content),
                  onTap: () {
                    // Navigate ด้วย auto_route
                    context.router.push(
                      NoteDetailRoute(noteId: note.id ?? 0),
                    );
                  },
                );
              },
            );
          } else if (state is NoteError) {
            return Center(child: Text('ข้อผิดพลาด: ${state.message}'));
          }
          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Trigger BLoC event
          context.read<NoteBloc>().add(const GetAllNotesEvent());
        },
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
```

---

## **2️⃣ Navigation: auto_route**

### **A. Route Definition**

```dart
// lib/presentation/routes/app_router.dart
import 'package:auto_route/auto_route.dart';
import 'package:testflutter/domain/entities/note_entity.dart';
import 'package:testflutter/presentation/pages/home_page.dart';
import 'package:testflutter/presentation/pages/create_note_page.dart';
import 'package:testflutter/presentation/pages/note_detail_page.dart';

part 'app_router.gr.dart';

@AutoRouterConfig(replaceInRouteName: 'Page,Route')
class AppRouter extends _$AppRouter {
  @override
  List<AutoRoute> get routes => [
    // Initial route
    AutoRoute(page: HomeRoute.page, initial: true),
    
    // CRUD routes
    AutoRoute(page: CreateNoteRoute.page),
    AutoRoute(page: NoteDetailRoute.page),
  ];
}
```

### **B. Page Decoration (Auto-generated)**

```dart
// lib/presentation/pages/home_page.dart
@RoutePage()
class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('หน้าแรก')),
      // ...
    );
  }
}

// lib/presentation/pages/create_note_page.dart
@RoutePage()
class CreateNotePage extends StatefulWidget {
  const CreateNotePage({Key? key}) : super(key: key);

  @override
  State<CreateNotePage> createState() => _CreateNotePageState();
}

// lib/presentation/pages/note_detail_page.dart
@RoutePage()
class NoteDetailPage extends StatelessWidget {
  final int noteId;  // ← Parameter passed from route
  
  const NoteDetailPage({
    Key? key,
    required this.noteId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('รายละเอียดโน้ต')),
      body: BlocBuilder<NoteBloc, NoteState>(
        builder: (context, state) {
          // Get note by ID
          if (state is NoteLoaded) {
            return Text(state.note.title);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
```

### **C. Typed Navigation (Type-Safe)**

```dart
// Navigation with auto_route
class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () {
        // Type-safe navigation with parameter
        context.router.push(
          NoteDetailRoute(noteId: note.id ?? 0),
        );
      },
      title: Text(note.title),
    );
  }
}

// Go back
context.router.pop();

// Replace current route
context.router.replace(HomeRoute());

// Clear stack and go to home
context.router.replaceAll([HomeRoute()]);
```

---

## **3️⃣ BLoC Lifecycle & State Flow**

### **Event Flow Diagram**

```
User Action (Tap Button)
         ↓
context.read<NoteBloc>().add(CreateNoteEvent(note))
         ↓
NoteBloc._onCreateNote() handler
         ↓
emit(NoteLoading())  // ← UI rebuilds: show spinner
         ↓
await createNoteUseCase(params)
         ↓
result.fold(
  (failure) → emit(NoteError(message))  // ← UI shows error
  (noteId) → emit(NoteCreated(noteId))  // ← UI shows success
)
         ↓
BlocBuilder rebuilds UI based on new state
```

---

## **4️⃣ ไม่มี setState ❌**

### **ผิด (Avoid)**

```dart
// ❌ DO NOT USE setState
class BadPage extends StatefulWidget {
  @override
  State<BadPage> createState() => _BadPageState();
}

class _BadPageState extends State<BadPage> {
  List<Note> notes = [];

  void fetchNotes() async {
    final result = await repository.getAllNotes();
    setState(() {  // ❌ BAD: Business logic in UI layer
      notes = result;
    });
  }
}
```

### **ถูก (Correct)**

```dart
// ✅ USE BLoC
class GoodPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NoteBloc, NoteState>(
      builder: (context, state) {
        if (state is NotesLoaded) {
          return ListView(
            children: state.notes.map((note) => Text(note.title)).toList(),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}
```

---

## **5️⃣ ผลประโยชน์ของ BLoC + auto_route**

| ลักษณะ | ประโยชน์ |
|--------|----------|
| **Separation of Concerns** | UI ไม่รู้เรื่อง business logic |
| **Testability** | ทดสอบ BLoC โดยไม่มี UI |
| **Reusability** | BLoC ใช้ได้หลาย page |
| **Type-Safe Navigation** | Compiler ตรวจสอบ route parameters |
| **State Persistence** | State ไม่หายเมื่อ rotate screen |
| **Easy Debugging** | ใจเย็นกับ state history |

---

## **📋 Command ที่ต้องใช้**

```bash
# Generate routes (auto_route)
flutter pub run build_runner build

# Generate code (json_serializable, freezed)
flutter pub run build_runner build --delete-conflicting-outputs

# Watch mode for development
flutter pub run build_runner watch
```

---

## **✅ summary**

`Smart Vision Journal` ใช้:
- ✅ **BLoC** แบบ professional สำหรับทั้ง CRUD + AI/ML operations
- ✅ **Either<Failure, Success>** pattern สำหรับ error handling
- ✅ **auto_route** สำหรับ typed navigation with parameters
- ✅ **ไม่มี setState** - ลอจิกทั้งหมดผ่าน BLoC
- ✅ **Equatable** สำหรับ immutable events/states

การออกแบบนี้แบบ **enterprise-grade** ครับ! 🚀
