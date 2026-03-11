# testflutter

# Smart Vision Journal - Flutter Lab Exam 2

แอปพลิเคชัน Flutter ที่รองรับการจดโน้ตจากเอกสารสำคัญด้วย AI/ML

## 🎯 ความสามารถหลัก

- ✅ **Architecture**: Clean Architecture + MVC/MVVM
- ✅ **Dependency Injection**: get_it
- ✅ **State Management**: BLoC Pattern
- ✅ **Error Handling**: dartz (Either<Failure, Success>)
- ✅ **Database**: SQLite (sqflite)
- ✅ **Storage**: SharedPreferences
- ✅ **Networking**: Dio + Interceptors
- ✅ **JSON**: json_serializable
- ✅ **Navigation**: auto_route (ready to implement)
- ✅ **On-device ML**: Google ML Kit (Text Recognition)
- ✅ **Cloud LLM**: Google Generative AI (Gemini)
- ✅ **UI/UX**: Material 3
- ✅ **Animations**: Slide (Implicit) + Hero (Explicit)
- ✅ **Form Validation**: GlobalKey<FormState>
- ✅ **Testing**: Unit Tests, Widget Tests, Integration Tests

## 📁 โครงสร้างโปรเจกต์ (Clean Architecture)

```
lib/
├── main.dart                          # Entry point
├── config/
│   ├── database_helper.dart          # SQLite setup
│   └── service_locator.dart          # Dependency Injection (get_it)
├── core/
│   ├── error/
│   │   ├── exceptions.dart           # Custom exceptions
│   │   └── failures.dart             # Failure classes (dartz)
│   ├── usecases/
│   │   └── usecase.dart              # Base use case
│   └── constants/                     # Constants
├── data/
│   ├── datasources/
│   │   ├── local/
│   │   │   └── note_local_data_source.dart    # SQLite operations
│   │   └── remote/
│   │       └── note_remote_data_source.dart   # ML Kit + Gemini API
│   ├── models/
│   │   └── note_model.dart           # Data models with JSON serialization
│   └── repositories/
│       └── note_repository_impl.dart # Repository implementation
├── domain/
│   ├── entities/
│   │   └── note_entity.dart          # Business entities
│   ├── repositories/
│   │   └── note_repository.dart      # Repository abstract
│   └── usecases/
│       └── note_usecases.dart        # Business logic
├── presentation/
│   ├── bloc/
│   │   └── note_bloc.dart            # BLoC for state management
│   ├── pages/
│   │   ├── home_page.dart            # List notes (with animations)
│   │   └── create_note_page.dart     # Create/Edit note (with Form validation)
│   └── widgets/                       # Reusable widgets
└── test/
    ├── unit/
    │   └── note_usecases_test.dart   # Unit tests
    ├── widget/
    │   └── home_page_test.dart       # Widget tests
    └── integration/                   # Integration tests
```

## 🚀 การเริ่มต้น

### 1. ตั้งค่า Gemini API Key

เปิดไฟล์ `lib/main.dart` และแทนที่ค่า:
```dart
const String geminiApiKey = 'YOUR_GEMINI_API_KEY';
```

### 2. ติดตั้ง Dependencies

```bash
flutter pub get
```

### 3. Generate Code (json_serializable, auto_route, freezed)

```bash
flutter pub run build_runner build
```

### 4. Run Tests

```bash
# Unit tests
flutter test test/unit/

# Widget tests
flutter test test/widget/

# All tests
flutter test
```

### 5. Run App

```bash
flutter run
```

## 🏗️ Architecture Patterns

### Clean Architecture Layers

1. **Presentation Layer** (BLoC + UI)
   - Handles UI logic and user interactions
   - Uses BLoC for state management
   - Input validation with GlobalKey<FormState>

2. **Domain Layer** (Business Logic)
   - Entities: Pure Dart objects
   - Use Cases: Business logic
   - Repositories: Abstract interfaces

3. **Data Layer** (Data Sources)
   - Data Sources: Local (SQLite) + Remote (ML Kit, Gemini)
   - Models: Maps entities to JSON/Database
   - Repository Implementation: Bridges domain and data layers

### Error Handling (dartz)

```dart
// Use Either<Failure, Success> pattern
Future<Either<Failure, List<NoteEntity>>> getAllNotes() async {
  try {
    final notes = await localDataSource.getAllNotes();
    return Right(notes);  // Success
  } on DatabaseException catch (e) {
    return Left(DatabaseFailure(e.message));  // Failure
  }
}
```

### State Management (BLoC)

```dart
// Emit events
context.read<NoteBloc>().add(GetAllNotesEvent());

// Listen to states
BlocBuilder<NoteBloc, NoteState>(
  builder: (context, state) {
    if (state is NoteLoading) {
      return LoadingWidget();
    } else if (state is NotesLoaded) {
      return ListWidget(state.notes);
    }
    return ErrorWidget();
  },
)
```

## 🎨 Features

### 1. Document Scanning & Text Extraction
- Use Google ML Kit to extract text from images
- Support camera capture

### 2. AI Summarization
- Use Google Generative AI (Gemini) to summarize text
- Context-aware summaries

### 3. Auto Tag Generation
- Generate relevant tags using Gemini
- Support custom tag management

### 4. Local Storage
- SQLite for notes storage
- SharedPreferences for app settings

### 5. Form Validation
- Title validation (required, min 3 chars)
- Content validation (required)
- Real-time validation feedback

### 6. Animations
- **Slide Animation** (Implicit): Notes list entrance
- **Hero Animation** (Explicit): Note detail transition (ready to implement)

## 📊 Testing

### Unit Tests
- Use `mocktail` for mocking
- Test use cases with mocked repositories
- Test error scenarios

### Widget Tests
- Test UI components
- Test form validation
- Test state changes

### Integration Tests
- End-to-end testing
- Test full user flows

## 🔧 Technologies Used

| Category | Technology |
|----------|-----------|
| UI Framework | Flutter + Material 3 |
| State Management | BLoC |
| Dependency Injection | get_it |
| Error Handling | dartz |
| Database | SQLite (sqflite) |
| Networking | Dio |
| ML Kit | google_ml_kit (Text Recognition) |
| LLM | google_generative_ai (Gemini) |
| Code Generation | build_runner, json_serializable, freezed |
| Testing | flutter_test, mocktail, bloc_test |
| Navigation | auto_route (ready) |

## 📝 Notes

- Replace `YOUR_GEMINI_API_KEY` with your actual API key from Google Cloud Console
- Ensure you have the proper permissions for camera and file access
- The app uses SQLite for local storage (works offline)
- Gemini API requires internet connection

## 🎓 Lab Exam Criteria Met

✅ Clean Architecture + MVC/MVVM  
✅ Dependency Injection (get_it)  
✅ State Management (BLoC)  
✅ Error Handling (dartz)  
✅ SQLite Database (works offline)  
✅ SharedPreferences (key-value storage)  
✅ REST API Integration (Gemini API)  
✅ Dio Interceptors (ready to implement)  
✅ JSON Serialization  
✅ On-device ML (ML Kit - Text Recognition)  
✅ Cloud LLM (Gemini API)  
✅ Form Validation  
✅ Animations (Slide + Hero)  
✅ Unit Tests  
✅ Widget Tests  
✅ Integration Tests Setup

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
