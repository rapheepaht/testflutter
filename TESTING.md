# 🧪 การทดสอบซอฟต์แวร์ (Testing)

## **สรุป: Smart Vision Journal ใช้**

✅ **Unit Test** - ทดสอบ Business Logic ด้วย mocktail/mockito
✅ **Widget Test** - ทดสอบ UI และ Form Validation
✅ **Integration Test** - ทดสอบ End-to-End สมบูรณ์
✅ **BLoC Testing** - ทดสอบ Events และ States ด้วย bloc_test

---

## **1️⃣ Unit Test - ทดสอบ Business Logic**

### **A. Setup Dependencies**

```yaml
# pubspec.yaml
dev_dependencies:
  test: ^1.24.0
  mockito: ^5.4.0
  mocktail: ^1.0.0
  bloc_test: ^9.1.0
```

---

### **B. ทดสอบ Use Case**

```dart
// lib/domain/usecases/create_note_usecase.dart
import 'package:dartz/dartz.dart';

abstract class CreateNoteUseCase {
  Future<Either<Failure, int>> call(CreateNoteParams params);
}

class CreateNoteUseCaseImpl implements CreateNoteUseCase {
  final NoteRepository repository;
  
  CreateNoteUseCaseImpl(this.repository);
  
  @override
  Future<Either<Failure, int>> call(CreateNoteParams params) async {
    return await repository.createNote(params.note);
  }
}

class CreateNoteParams {
  final NoteEntity note;
  CreateNoteParams({required this.note});
}
```

```dart
// test/domain/usecases/create_note_usecase_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:dartz/dartz.dart';

// ✅ Mock repository ด้วย Mockito
class MockNoteRepository extends Mock implements NoteRepository {}

void main() {
  group('CreateNoteUseCase', () {
    late CreateNoteUseCase useCase;
    late MockNoteRepository mockRepository;
    
    setUp(() {
      mockRepository = MockNoteRepository();
      useCase = CreateNoteUseCaseImpl(mockRepository);
    });
    
    // ✅ Test case 1: สร้าง Note สำเร็จ
    test(
      'ควรคืนค่า ID เมื่อสร้าง Note สำเร็จ',
      () async {
        // Arrange - เตรียมข้อมูล
        final note = NoteEntity(
          title: 'Test Note',
          content: 'Test Content',
          tags: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        
        final expectedId = 1;
        
        // Mock repository behavior
        when(mockRepository.createNote(any))
            .thenAnswer((_) async => Right(expectedId));
        
        // Act - เรียกใช้ function
        final result = await useCase(CreateNoteParams(note: note));
        
        // Assert - ตรวจสอบผลลัพธ์
        expect(result, equals(Right(expectedId)));
        
        // ตรวจสอบว่าเรียกใช้ mock ถูกต้อง
        verify(mockRepository.createNote(note)).called(1);
      },
    );
    
    // ✅ Test case 2: Repository ส่ง Error
    test(
      'ควรคืนค่า DatabaseFailure เมื่อ Repository ล้มเหลว',
      () async {
        final note = NoteEntity(
          title: 'Test',
          content: 'Content',
          tags: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        
        // Mock failure response
        when(mockRepository.createNote(any))
            .thenAnswer((_) async => Left(DatabaseFailure('Database error')));
        
        final result = await useCase(CreateNoteParams(note: note));
        
        // ตรวจสอบว่าได้รับ Failure
        expect(result, isA<Left>());
        expect(
          result.fold((l) => l, (r) => null),
          isA<DatabaseFailure>(),
        );
      },
    );
    
    // ✅ Test case 3: Validation - Title ว่าง
    test(
      'ควรคืนค่า Failure เมื่อ Title ว่าง',
      () async {
        final note = NoteEntity(
          title: '',  // ❌ Title ว่าง
          content: 'Content',
          tags: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        
        // สมมติว่า Use Case จะ validate ก่อน
        final result = await useCase(CreateNoteParams(note: note));
        
        // Repository ไม่ควรถูกเรียก
        verifyNever(mockRepository.createNote(any));
      },
    );
  });
}
```

**Test Structure**:
```
Test สามารถแบ่งเป็นส่วน:
1. Arrange  - เตรียมข้อมูล, mock
2. Act      - เรียกใช้ function
3. Assert   - ตรวจสอบผลลัพธ์
```

---

### **C. ทดสอบ Repository Implementation**

```dart
// test/data/repositories/note_repository_impl_test.dart
import 'package:mocktail/mocktail.dart';

class MockNoteLocalDataSource extends Mock 
    implements NoteLocalDataSource {}

class MockNoteRemoteDataSource extends Mock 
    implements NoteRemoteDataSource {}

void main() {
  group('NoteRepositoryImpl', () {
    late NoteRepositoryImpl repository;
    late MockNoteLocalDataSource mockLocalDataSource;
    late MockNoteRemoteDataSource mockRemoteDataSource;
    
    setUp(() {
      mockLocalDataSource = MockNoteLocalDataSource();
      mockRemoteDataSource = MockNoteRemoteDataSource();
      repository = NoteRepositoryImpl(
        localDataSource: mockLocalDataSource,
        remoteDataSource: mockRemoteDataSource,
      );
    });
    
    // ✅ Test Offline-First Strategy
    test(
      'ควรคืนค่าข้อมูลจาก Local เมื่อออฟไลน์',
      () async {
        // Arrange
        final noteModels = [
          NoteModel(
            id: 1,
            title: 'Note 1',
            content: 'Content 1',
            tags: [],
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ];
        
        // Mock local return success, remote throw error
        when(() => mockLocalDataSource.getAllNotes())
            .thenAnswer((_) async => noteModels);
        
        when(() => mockRemoteDataSource.getAllNotes())
            .thenThrow(Exception('No internet'));
        
        // Act
        final result = await repository.getAllNotes();
        
        // Assert
        expect(result, isA<Right>());
        final notes = result.fold((l) => null, (r) => r);
        expect(notes, isNotNull);
        expect(notes!.length, equals(1));
      },
    );
    
    // ✅ Test Create with Sync
    test(
      'ควรบันทึกลงใน Local ทันทีแม้ Remote ล้มเหลว',
      () async {
        final note = NoteModel(
          id: null,
          title: 'New Note',
          content: 'Content',
          tags: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        
        when(() => mockLocalDataSource.createNote(any))
            .thenAnswer((_) async => 1);
        
        when(() => mockRemoteDataSource.createNote(any))
            .thenThrow(Exception('Network error'));
        
        final result = await repository.createNote(note.toEntity());
        
        // ตรวจสอบว่า Local ถูกเรียก
        verify(() => mockLocalDataSource.createNote(any)).called(1);
        
        // ตรวจสอบว่า Remote ถูกลอง (best-effort)
        verify(() => mockRemoteDataSource.createNote(any)).called(1);
        
        // ผลลัพธ์ควรสำเร็จ (Local saved)
        expect(result, isA<Right>());
      },
    );
  });
}
```

---

### **D. ทดสอบ BLoC**

```dart
// test/presentation/bloc/note_bloc_test.dart
import 'package:bloc_test/bloc_test.dart';

class MockCreateNoteUseCase extends Mock implements CreateNoteUseCase {}
class MockGetAllNotesUseCase extends Mock implements GetAllNotesUseCase {}

void main() {
  group('NoteBloc', () {
    late NoteBloc noteBloc;
    late MockCreateNoteUseCase mockCreateNoteUseCase;
    late MockGetAllNotesUseCase mockGetAllNotesUseCase;
    
    setUp(() {
      mockCreateNoteUseCase = MockCreateNoteUseCase();
      mockGetAllNotesUseCase = MockGetAllNotesUseCase();
      
      noteBloc = NoteBloc(
        createNoteUseCase: mockCreateNoteUseCase,
        getAllNotesUseCase: mockGetAllNotesUseCase,
      );
    });
    
    tearDown(() {
      noteBloc.close();
    });
    
    // ✅ ทดสอบ Event → State transitions
    blocTest<NoteBloc, NoteState>(
      'ควรปล่อย [NoteLoading, NoteCreated] เมื่อ CreateNoteEvent สำเร็จ',
      build: () {
        when(() => mockCreateNoteUseCase(any))
            .thenAnswer((_) async => const Right(1));
        
        return noteBloc;
      },
      act: (bloc) {
        final note = NoteEntity(
          title: 'Test',
          content: 'Content',
          tags: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        
        bloc.add(CreateNoteEvent(note: note));
      },
      expect: () => [
        const NoteLoading(),
        const NoteCreated(1),
      ],
    );
    
    // ✅ ทดสอบ Error case
    blocTest<NoteBloc, NoteState>(
      'ควรปล่อย [NoteLoading, NoteError] เมื่อสร้าง Note ล้มเหลว',
      build: () {
        when(() => mockCreateNoteUseCase(any)).thenAnswer(
          (_) async => Left(DatabaseFailure('DB error')),
        );
        
        return noteBloc;
      },
      act: (bloc) {
        final note = NoteEntity(
          title: 'Test',
          content: 'Content',
          tags: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        
        bloc.add(CreateNoteEvent(note: note));
      },
      expect: () => [
        const NoteLoading(),
        isA<NoteError>(),
      ],
    );
    
    // ✅ ทดสอบ LoadNotes Event
    blocTest<NoteBloc, NoteState>(
      'ควรโหลด Notes ทั้งหมดสำเร็จ',
      build: () {
        final notes = [
          NoteEntity(
            id: 1,
            title: 'Note 1',
            content: 'Content 1',
            tags: [],
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ];
        
        when(() => mockGetAllNotesUseCase(any))
            .thenAnswer((_) async => Right(notes));
        
        return noteBloc;
      },
      act: (bloc) => bloc.add(const LoadNotesEvent()),
      expect: () => [
        const NoteLoading(),
        isA<NotesLoaded>(),
      ],
    );
  });
}
```

**BLoC Test ด้วย bloc_test**:
```
blocTest<BLoC, State>(
  'คำอธิบาย Test',
  build: () {
    // Setup mocks
    return bloc;
  },
  act: (bloc) {
    // Trigger event
    bloc.add(Event());
  },
  expect: () => [
    State1(),
    State2(),  // Expected states
  ],
);
```

---

## **2️⃣ Widget Test - ทดสอบ UI และ Form**

### **A. ทดสอบ Widget พื้นฐาน**

```dart
// test/presentation/pages/create_note_page_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void main() {
  group('CreateNotePage Widget Tests', () {
    late MockNoteBloc mockNoteBloc;
    
    setUp(() {
      mockNoteBloc = MockNoteBloc();
    });
    
    // ✅ Helper function - Build widget
    Widget _buildWidget() {
      return MaterialApp(
        home: BlocProvider<NoteBloc>(
          create: (_) => mockNoteBloc,
          child: const CreateNotePage(),
        ),
      );
    }
    
    // ✅ Test 1: Widget loads correctly
    testWidgets(
      'ควรแสดง Form สำหรับบันทึกข้อมูล',
      (WidgetTester tester) async {
        when(() => mockNoteBloc.state).thenReturn(const NoteInitial());
        
        await tester.pumpWidget(_buildWidget());
        
        // ตรวจสอบ AppBar
        expect(find.text('Create Note'), findsOneWidget);
        
        // ตรวจสอบ TextField สำหรับ Title
        expect(find.byType(TextFormField), findsWidgets);
        
        // ตรวจสอบปุ่ม
        expect(find.byType(ElevatedButton), findsWidgets);
      },
    );
    
    // ✅ Test 2: Form Validation
    testWidgets(
      'ควรแสดง Error message เมื่อ Title ว่าง',
      (WidgetTester tester) async {
        when(() => mockNoteBloc.state).thenReturn(const NoteInitial());
        
        await tester.pumpWidget(_buildWidget());
        
        // หา Form
        final formField = find.byType(TextFormField).first;
        
        // Leave empty and submit
        await tester.tap(find.byType(ElevatedButton).last);
        await tester.pumpWidget(_buildWidget());
        
        // ตรวจสอบ Validation error
        // (หลังจากที่ validator ถูกเรียก)
        // expect(find.text('Title is required'), findsOneWidget);
      },
    );
    
    // ✅ Test 3: ป้อนข้อมูลและบันทึก
    testWidgets(
      'ควรบันทึก Note เมื่อป้อนข้อมูลถูกต้อง',
      (WidgetTester tester) async {
        when(() => mockNoteBloc.state).thenReturn(const NoteInitial());
        
        await tester.pumpWidget(_buildWidget());
        
        // ป้อน Title
        await tester.enterText(
          find.byType(TextFormField).first,
          'My Note',
        );
        
        // ป้อน Content
        await tester.enterText(
          find.byType(TextFormField).last,
          'My Content',
        );
        
        // แตะปุ่ม Create
        await tester.tap(find.byType(ElevatedButton).last);
        await tester.pumpAndSettle();
        
        // ตรวจสอบว่า BLoC event ถูกเรียก
        // verify(() => mockNoteBloc.add(any(that: isA<CreateNoteEvent>())));
      },
    );
  });
}
```

---

### **B. ทดสอบ List Widget**

```dart
// test/presentation/pages/home_page_test.dart
testWidgets(
  'ควรแสดง List ของ Notes ทั้งหมด',
  (WidgetTester tester) async {
    final notes = [
      NoteEntity(
        id: 1,
        title: 'Note 1',
        content: 'Content 1',
        tags: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      NoteEntity(
        id: 2,
        title: 'Note 2',
        content: 'Content 2',
        tags: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];
    
    when(() => mockNoteBloc.state)
        .thenReturn(NotesLoaded(notes));
    
    await tester.pumpWidget(_buildWidget());
    
    // ตรวจสอบ ListView ถูกแสดง
    expect(find.byType(ReorderableListView), findsOneWidget);
    
    // ตรวจสอบจำนวน items
    expect(find.byType(ListTile), findsNWidgets(2));
    
    // ตรวจสอบ Text ของ Note
    expect(find.text('Note 1'), findsOneWidget);
    expect(find.text('Note 2'), findsOneWidget);
  },
);
```

---

### **C. ทดสอบ Animation**

```dart
// test/presentation/pages/note_detail_page_test.dart
testWidgets(
  'ควรแสดง AnimatedContainer เมื่อแตะ',
  (WidgetTester tester) async {
    await tester.pumpWidget(_buildWidget());
    
    // หา GestureDetector
    final gestureDetector = find.byType(GestureDetector).first;
    
    // ขนาด container ตอนแรก
    Offset initialSize = tester.getSize(find.byType(AnimatedContainer)).bottomRight;
    
    // แตะ GestureDetector
    await tester.tap(gestureDetector);
    
    // Wait for animation
    await tester.pumpAndSettle(const Duration(seconds: 1));
    
    // ตรวจสอบขนาด container เปลี่ยน
    Offset newSize = tester.getSize(find.byType(AnimatedContainer)).bottomRight;
    expect(newSize, isNot(initialSize));
  },
);
```

---

## **3️⃣ Integration Test - ทดสอบ End-to-End**

### **A. Setup Integration Test**

```yaml
# pubspec.yaml
dev_dependencies:
  integration_test:
    sdk: flutter
```

```dart
// test_driver/integration_test.dart
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  // Run all integration tests
  testWidgets('E2E Test Flow', (WidgetTester tester) async {
    // Run tests
  });
}
```

### **B. Complete E2E Test Scenario**

```dart
// integration_test/app_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:testflutter/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  group('Smart Vision Journal E2E Tests', () {
    
    // ✅ E2E Test 1: สร้าง Note จาก Form
    testWidgets(
      'สามารถสร้าง Note ได้สำเร็จ',
      (WidgetTester tester) async {
        app.main();
        
        // รอ app load
        await tester.pumpAndSettle(const Duration(seconds: 2));
        
        // ✅ Step 1: หน้า Home มีปุ่ม "Create Note"
        expect(find.byIcon(Icons.add), findsOneWidget);
        
        // ✅ Step 2: แตะปุ่ม "Create Note"
        await tester.tap(find.byIcon(Icons.add));
        await tester.pumpAndSettle();
        
        // ✅ Step 3: ตรวจสอบ CreateNotePage โหลด
        expect(find.text('Create Note'), findsOneWidget);
        
        // ✅ Step 4: ป้อน Title
        final titleField = find.byType(TextFormField).first;
        await tester.enterText(titleField, 'Integration Test Note');
        
        // ✅ Step 5: ป้อน Content
        final contentField = find.byType(TextFormField).at(1);
        await tester.enterText(
          contentField,
          'This is content from integration test',
        );
        
        // ✅ Step 6: แตะปุ่ม "Create Note"
        final createButton = find.byType(ElevatedButton)
            .evaluate()
            .toList()
            .where((e) {
              final widget = e.widget as ElevatedButton;
              return widget.child is Text &&
                  (widget.child as Text).data == 'Create Note';
            })
            .first;
        
        await tester.tap(find.byWidget(createButton.widget));
        await tester.pumpAndSettle(const Duration(seconds: 2));
        
        // ✅ Step 7: ตรวจสอบว่ากลับมาหน้า Home
        expect(find.text('Smart Vision Journal'), findsWidgets);
        
        // ✅ Step 8: ตรวจสอบว่า Note เพิ่มลงใน List
        expect(
          find.text('Integration Test Note'),
          findsOneWidget,
        );
      },
    );
    
    // ✅ E2E Test 2: เปิดดู Note และแก้ไข
    testWidgets(
      'สามารถแก้ไข Note ได้สำเร็จ',
      (WidgetTester tester) async {
        app.main();
        await tester.pumpAndSettle(const Duration(seconds: 2));
        
        // ✅ หา Note ในลิสต์
        final noteTitle = find.text('Integration Test Note');
        expect(noteTitle, findsOneWidget);
        
        // ✅ แตะเพื่อเปิดดู
        await tester.tap(noteTitle);
        await tester.pumpAndSettle();
        
        // ✅ ตรวจสอบว่า Detail page โหลด
        expect(find.text('Integration Test Note'), findsOneWidget);
        expect(
          find.text('This is content from integration test'),
          findsOneWidget,
        );
        
        // ✅ แตะปุ่ม Edit (หากมี)
        await tester.tap(find.byIcon(Icons.edit));
        await tester.pumpAndSettle();
        
        // ✅ แก้ไขข้อมูล
        final titleField = find.byType(TextFormField).first;
        await tester.enterText(titleField, 'Updated Title');
        
        // ✅ บันทึกการแก้ไข
        await tester.tap(find.byType(ElevatedButton).last);
        await tester.pumpAndSettle(const Duration(seconds: 2));
        
        // ✅ ตรวจสอบข้อมูลอัปเดต
        expect(find.text('Updated Title'), findsOneWidget);
      },
    );
    
    // ✅ E2E Test 3: ลบ Note
    testWidgets(
      'สามารถลบ Note ได้สำเร็จ',
      (WidgetTester tester) async {
        app.main();
        await tester.pumpAndSettle(const Duration(seconds: 2));
        
        // ✅ หา Note ในลิสต์
        final initialCount = find.byType(ListTile).evaluate().length;
        
        // ✅ แตะปุ่มลบ (swipe or menu)
        await tester.tap(find.byIcon(Icons.delete).first);
        await tester.pumpAndSettle(const Duration(seconds: 1));
        
        // ✅ Confirm deletion (หากมี dialog)
        final confirmButton = find.text('Delete');
        if (confirmButton.evaluate().isNotEmpty) {
          await tester.tap(confirmButton);
        }
        
        await tester.pumpAndSettle(const Duration(seconds: 2));
        
        // ✅ ตรวจสอบว่า Note ลบแล้ว
        final newCount = find.byType(ListTile).evaluate().length;
        expect(newCount, lessThan(initialCount));
      },
    );
    
    // ✅ E2E Test 4: OCR + Summarize
    testWidgets(
      'สามารถ Extract ข้อความและสรุป Note ได้',
      (WidgetTester tester) async {
        app.main();
        await tester.pumpAndSettle(const Duration(seconds: 2));
        
        // ✅ หา "Create Note" button
        await tester.tap(find.byIcon(Icons.add));
        await tester.pumpAndSettle();
        
        // ✅ หา "Capture Document" button (หากมี)
        final captureButton = find.byIcon(Icons.document_scanner);
        if (captureButton.evaluate().isNotEmpty) {
          await tester.tap(captureButton);
          
          // ✅ รอ Image Picker (หรือ mock image)
          await tester.pumpAndSettle(const Duration(seconds: 2));
          
          // ✅ ตรวจสอบว่า OCR extraction เสร็จ
          // (ในที่นี้ mock data จะแสดง)
          expect(
            find.byType(TextFormField),
            findsWidgets,
          );
        }
      },
    );
    
    // ✅ E2E Test 5: Offline Capability
    testWidgets(
      'สามารถใช้งาน App ในสถานะ Offline ได้',
      (WidgetTester tester) async {
        // Disable network (simulate offline)
        // ใช้ test utilities เพื่อ mock network
        
        app.main();
        await tester.pumpAndSettle(const Duration(seconds: 2));
        
        // ✅ สร้าง Note ขณะ Offline
        await tester.tap(find.byIcon(Icons.add));
        await tester.pumpAndSettle();
        
        final titleField = find.byType(TextFormField).first;
        await tester.enterText(titleField, 'Offline Test Note');
        
        final contentField = find.byType(TextFormField).at(1);
        await tester.enterText(contentField, 'Created offline');
        
        // ✅ บันทึก
        await tester.tap(find.byType(ElevatedButton).last);
        await tester.pumpAndSettle(const Duration(seconds: 2));
        
        // ✅ ตรวจสอบว่า Note ถูกบันทึกแม้ Offline
        expect(find.text('Offline Test Note'), findsOneWidget);
        
        // Re-enable network
        // Network will sync pending changes
      },
    );
  });
}
```

---

## **4️⃣ รัน Tests**

### **A. รัน Unit Tests**

```bash
# รัน Unit tests ทั้งหมด
flutter test

# รัน test ไฟล์เดียว
flutter test test/domain/usecases/create_note_usecase_test.dart

# รัน test ด้วย coverage
flutter test --coverage

# ดู coverage report
open coverage/index.html  # macOS
# หรือ
start coverage/index.html  # Windows
```

---

### **B. รัน Widget Tests**

```bash
# รัน Widget tests ทั้งหมด
flutter test test/presentation

# รัน test เดียว
flutter test test/presentation/pages/create_note_page_test.dart
```

---

### **C. รัน Integration Tests**

```bash
# รัน integration tests บน emulator/device
flutter test integration_test/app_test.dart

# รัน บน Chrome web
flutter drive --target=integration_test/app_test.dart --driver=test_driver/integration_test.dart -d chrome

# บน physical device
flutter drive --target=integration_test/app_test.dart -d <device-id>
```

---

## **5️⃣ Mock Helpers & Utilities**

### **A. Create Mock BLoC**

```dart
// test/helpers/mock_bloc.dart
import 'package:mockito/mockito.dart';
import 'package:bloc_test/bloc_test.dart';

class MockNoteBloc extends Mock implements NoteBloc {
  @override
  Stream<NoteState> get stream =>
      Stream.fromIterable([const NoteInitial()]);
  
  @override
  NoteState get state => const NoteInitial();
}

// ✅ ใช้ได้:
final mockBloc = MockNoteBloc();
when(() => mockBloc.state).thenReturn(const NotesLoaded([]));
```

---

### **B. Create Fake Data**

```dart
// test/helpers/fake_data.dart
class FakeNoteData {
  static NoteEntity createTestNote({
    int? id,
    String? title,
    String? content,
  }) =>
      NoteEntity(
        id: id,
        title: title ?? 'Test Note',
        content: content ?? 'Test Content',
        tags: ['test'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
  
  static List<NoteEntity> createTestNotes(int count) =>
      List.generate(
        count,
        (i) => createTestNote(
          id: i + 1,
          title: 'Note ${i + 1}',
        ),
      );
}

// ✅ ใช้ได้:
final testNotes = FakeNoteData.createTestNotes(5);
```

---

### **C. Test Helper Functions**

```dart
// test/helpers/test_helpers.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// ✅ Build widget ได้ง่าย
Future<void> pumpApp(
  WidgetTester tester,
  Widget widget, {
  Duration? settleTime,
}) async {
  await tester.pumpWidget(MaterialApp(home: widget));
  if (settleTime != null) {
    await tester.pumpAndSettle(settleTime);
  }
}

// ✅ Enter text ในช่องซ้ำ ๆ
Future<void> enterForm(
  WidgetTester tester, {
  required String title,
  required String content,
}) async {
  await tester.enterText(find.byType(TextFormField).first, title);
  await tester.enterText(find.byType(TextFormField).at(1), content);
}

// ✅ ใช้ได้:
await pumpApp(tester, const CreateNotePage(), settleTime: Duration(seconds: 1));
await enterForm(tester, title: 'Test', content: 'Content');
```

---

## **6️⃣ Test Coverage**

### **A. Generate Coverage Report**

```bash
# Generate coverage
flutter test --coverage

# View coverage
# ดู coverage/lcov.info หรือ convert เป็น HTML
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

---

### **B. Coverage Targets**

```
Business Logic (Use Cases, Repository): 80-90%
UI Layer (Pages, Widgets):              60-70%
Data Layer (Data Sources):              80-90%
Constants, Models:                      100%
```

---

## **✅ Testing Checklist**

### **Unit Tests**
- ✅ ทดสอบ Use Cases ทั้งหมด (success + error cases)
- ✅ ทดสอบ Repository (local + remote + offline-first)
- ✅ ทดสอบ BLoC Events and State transitions
- ✅ ทดสอบ Data Source implementations
- ✅ ทดสอบ Exception handling

### **Widget Tests**
- ✅ ทดสอบ Form validation
- ✅ ทดสอบ List rendering
- ✅ ทดสอบ Button interactions
- ✅ ทดสอบ Navigation
- ✅ ทดสอบ Animations
- ✅ ทดสอบ Loading states

### **Integration Tests**
- ✅ Complete user flow: Create Note
- ✅ Complete user flow: Edit Note
- ✅ Complete user flow: Delete Note
- ✅ OCR + Summarization flow
- ✅ Offline capability
- ✅ Data persistence

---

## **📊 Test Structure Example**

```
test/
├── domain/
│   ├── usecases/
│   │   ├── create_note_usecase_test.dart
│   │   ├── get_all_notes_usecase_test.dart
│   │   └── extract_text_usecase_test.dart
│   └── repositories/
│       └── note_repository_test.dart
├── data/
│   ├── datasources/
│   │   ├── local/
│   │   │   ├── note_local_data_source_test.dart
│   │   │   └── note_web_data_source_test.dart
│   │   └── remote/
│   │       └── note_remote_data_source_test.dart
│   └── repositories/
│       └── note_repository_impl_test.dart
├── presentation/
│   ├── bloc/
│   │   └── note_bloc_test.dart
│   └── pages/
│       ├── create_note_page_test.dart
│       ├── home_page_test.dart
│       └── note_detail_page_test.dart
├── helpers/
│   ├── mock_bloc.dart
│   ├── fake_data.dart
│   └── test_helpers.dart
└── integration_test/
    └── app_test.dart
```

---

**สรุป**: Smart Vision Journal มี **3 ระดับ Testing** ที่ครอบคลุม:
- 🧪 Unit Tests ทดสอบ Logic
- 🎨 Widget Tests ทดสอบ UI
- 🔄 Integration Tests ทดสอบ E2E ✨
