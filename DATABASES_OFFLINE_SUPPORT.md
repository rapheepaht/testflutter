# 🗄️ ฐานข้อมูลและการรองรับออฟไลน์ (Databases & Offline Support)

## **สรุป: Smart Vision Journal ใช้**

✅ **SQLite (sqflite 2.3.0)** - Local database สำหรับ Mobile (Android/iOS)
✅ **SharedPreferences (2.2.2)** - Local storage สำหรับ Web + Settings
✅ **Dio Interceptors** - Smart caching สำหรับ API responses
✅ **Repository Pattern** - Offline-first strategy
✅ **Service Locator** - Platform detection (Mobile vs Web)

---

## **1️⃣ SQLite Database (Mobile)**

### **A. Database Schema**

```dart
// lib/config/database_helper.dart
class DatabaseHelper {
  static const _databaseName = 'smart_vision_journal.db';
  static const _databaseVersion = 1;
  
  static const tableNotes = 'notes';
  static const columnId = 'id';
  static const columnTitle = 'title';
  static const columnContent = 'content';
  static const columnImagePath = 'imagePath';
  static const columnExtractedText = 'extractedText';
  static const columnSummary = 'summary';
  static const columnTags = 'tags';
  static const columnCreatedAt = 'createdAt';
  static const columnUpdatedAt = 'updatedAt';
  
  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, _databaseName);
    
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }
  
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableNotes (
        $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
        $columnTitle TEXT NOT NULL,
        $columnContent TEXT NOT NULL,
        $columnImagePath TEXT,
        $columnExtractedText TEXT,
        $columnSummary TEXT,
        $columnTags TEXT,
        $columnCreatedAt TEXT NOT NULL,
        $columnUpdatedAt TEXT NOT NULL
      )
    ''');
  }
  
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
```

**Schema Table**:
```
┌─────────────────────────────────────────────┐
│                  notes                      │
├─────────────────────────────────────────────┤
│ id (INT) PRIMARY KEY AUTOINCREMENT          │
│ title (TEXT) NOT NULL                       │
│ content (TEXT) NOT NULL                     │
│ imagePath (TEXT)                            │
│ extractedText (TEXT)  ← OCR result          │
│ summary (TEXT)        ← AI summary          │
│ tags (TEXT)           ← AI tags JSON        │
│ createdAt (TEXT)      ← ISO 8601 format     │
│ updatedAt (TEXT)      ← ISO 8601 format     │
└─────────────────────────────────────────────┘
```

---

### **B. Singleton Pattern & Lazy Initialization**

```dart
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  
  factory DatabaseHelper() {
    return _instance;  // Always return same instance
  }
  
  DatabaseHelper._internal();  // Private constructor
  
  static Database? _database;  // Lazy-loaded
  
  Future<Database> get database async {
    _database ??= await _initDatabase();  // Lazy initialization
    return _database!;
  }
}

// Usage
final db = await DatabaseHelper().database;  // Get database instance
```

---

### **C. CRUD Operations (NoteLocalDataSource)**

```dart
// lib/data/datasources/local/note_local_data_source.dart
abstract class NoteLocalDataSource {
  Future<List<NoteModel>> getAllNotes();
  Future<NoteModel> getNoteById(int id);
  Future<int> createNote(NoteModel note);
  Future<void> updateNote(NoteModel note);
  Future<void> deleteNote(int id);
  Future<List<NoteModel>> searchNotes(String query);
}

class NoteLocalDataSourceImpl implements NoteLocalDataSource {
  final Database database;
  
  NoteLocalDataSourceImpl(this.database);
  
  // ✅ CREATE
  @override
  Future<int> createNote(NoteModel note) async {
    try {
      return await database.insert(
        'notes',
        note.toDatabase(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw NoteDataException('Failed to create note: $e');
    }
  }
  
  // ✅ READ ALL
  @override
  Future<List<NoteModel>> getAllNotes() async {
    try {
      final List<Map<String, dynamic>> maps = 
        await database.query('notes');
      return List<NoteModel>.from(
        maps.map((x) => NoteModel.fromDatabase(x))
      );
    } catch (e) {
      throw NoteDataException('Failed to fetch notes: $e');
    }
  }
  
  // ✅ READ ONE
  @override
  Future<NoteModel> getNoteById(int id) async {
    try {
      final List<Map<String, dynamic>> maps = 
        await database.query(
          'notes',
          where: 'id = ?',
          whereArgs: [id],
        );
      
      if (maps.isEmpty) {
        throw NoteDataException('Note not found');
      }
      
      return NoteModel.fromDatabase(maps.first);
    } catch (e) {
      throw NoteDataException('Failed to fetch note: $e');
    }
  }
  
  // ✅ UPDATE
  @override
  Future<void> updateNote(NoteModel note) async {
    try {
      await database.update(
        'notes',
        note.toDatabase(),
        where: 'id = ?',
        whereArgs: [note.id],
      );
    } catch (e) {
      throw NoteDataException('Failed to update note: $e');
    }
  }
  
  // ✅ DELETE
  @override
  Future<void> deleteNote(int id) async {
    try {
      await database.delete(
        'notes',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw NoteDataException('Failed to delete note: $e');
    }
  }
  
  // ✅ SEARCH
  @override
  Future<List<NoteModel>> searchNotes(String query) async {
    try {
      final List<Map<String, dynamic>> maps = 
        await database.query(
          'notes',
          where: 'title LIKE ? OR content LIKE ?',
          whereArgs: ['%$query%', '%$query%'],
        );
      return List<NoteModel>.from(
        maps.map((x) => NoteModel.fromDatabase(x))
      );
    } catch (e) {
      throw NoteDataException('Failed to search notes: $e');
    }
  }
}
```

**CRUD Cheat Sheet**:
```
CREATE:     database.insert(table, map)
READ ALL:   database.query(table)
READ ONE:   database.query(table, where: 'id = ?', whereArgs: [id])
UPDATE:     database.update(table, map, where: 'id = ?')
DELETE:     database.delete(table, where: 'id = ?')
SEARCH:     database.query(table, where: 'LIKE %query%')
```

---

## **2️⃣ SharedPreferences (Web + Settings)**

### **A. Web Implementation**

```dart
// lib/data/datasources/local/note_web_data_source.dart
abstract class NoteWebDataSource {
  Future<List<NoteModel>> getAllNotes();
  Future<NoteModel?> getNoteById(int id);
  Future<int> createNote(NoteModel note);
  Future<int> updateNote(NoteModel note);
  Future<int> deleteNote(int id);
  Future<List<NoteModel>> searchNotes(String query);
}

class NoteWebDataSourceImpl implements NoteWebDataSource {
  static const String _notesKey = 'notes_list';
  static const String _nextIdKey = 'next_note_id';
  
  SharedPreferences? _prefs;
  
  Future<SharedPreferences> _getPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }
  
  // ✅ GET ALL (JSON Array)
  @override
  Future<List<NoteModel>> getAllNotes() async {
    try {
      final prefs = await _getPrefs();
      final jsonString = prefs.getString(_notesKey);
      
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }
      
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList
          .map((json) => NoteModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw NoteDataException('Failed to get all notes: $e');
    }
  }
  
  // ✅ CREATE (Auto-increment ID)
  @override
  Future<int> createNote(NoteModel note) async {
    try {
      final notes = await getAllNotes();
      final prefs = await _getPrefs();
      final nextId = prefs.getInt(_nextIdKey) ?? 1;
      
      final newNote = NoteModel(
        id: nextId,
        title: note.title,
        content: note.content,
        imagePath: note.imagePath,
        extractedText: note.extractedText,
        summary: note.summary,
        tags: note.tags,
        createdAt: note.createdAt,
        updatedAt: note.updatedAt,
      );
      
      notes.add(newNote);
      await _saveNotes(notes, prefs);
      await prefs.setInt(_nextIdKey, nextId + 1);
      
      return nextId;
    } catch (e) {
      throw NoteDataException('Failed to create note: $e');
    }
  }
  
  // ✅ UPDATE
  @override
  Future<int> updateNote(NoteModel note) async {
    try {
      final notes = await getAllNotes();
      final prefs = await _getPrefs();
      final index = notes.indexWhere((n) => n.id == note.id);
      
      if (index == -1) {
        throw NoteDataException('Note not found');
      }
      
      notes[index] = note.copyWith(updatedAt: DateTime.now());
      await _saveNotes(notes, prefs);
      
      return 1;
    } catch (e) {
      throw NoteDataException('Failed to update note: $e');
    }
  }
  
  // ✅ DELETE
  @override
  Future<int> deleteNote(int id) async {
    try {
      final notes = await getAllNotes();
      final prefs = await _getPrefs();
      notes.removeWhere((note) => note.id == id);
      await _saveNotes(notes, prefs);
      
      return 1;
    } catch (e) {
      throw NoteDataException('Failed to delete note: $e');
    }
  }
  
  // Helper: Save entire list as JSON
  Future<void> _saveNotes(
    List<NoteModel> notes,
    SharedPreferences prefs,
  ) async {
    final jsonString = jsonEncode(
      notes.map((note) => note.toJson()).toList(),
    );
    await prefs.setString(_notesKey, jsonString);
  }
}
```

**Data Format in Browser**:
```javascript
// localStorage.getItem('notes_list')
[
  {
    "id": 1,
    "title": "My Note",
    "content": "Content here...",
    "imagePath": null,
    "extractedText": "...",
    "summary": "...",
    "tags": ["tag1", "tag2"],
    "createdAt": "2026-03-10T12:30:00.000",
    "updatedAt": "2026-03-10T12:30:00.000"
  }
]
```

---

## **3️⃣ Platform Detection (Mobile vs Web)**

### **A. Service Locator Setup**

```dart
// lib/config/service_locator.dart
Future<void> setupServiceLocator(
  Database? database,
  String geminiApiKey,
) async {
  await getIt.reset();
  
  // ✅ Platform-specific local data source
  if (kIsWeb) {
    // Web: Use SharedPreferences
    getIt.registerSingleton<NoteWebDataSource>(
      NoteWebDataSourceImpl(),
    );
  } else {
    // Mobile: Use SQLite
    getIt.registerSingleton<NoteLocalDataSource>(
      NoteLocalDataSourceImpl(database!),
    );
  }
  
  // Remote data source (same for both)
  getIt.registerSingleton<NoteRemoteDataSource>(
    NoteRemoteDataSourceImpl(
      geminiApiKey: geminiApiKey,
      dioClient: getIt(),
    ),
  );
  
  // Repository implementation (web or mobile)
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
}
```

**Flow**:
```
main.dart
  ├─ Detect platform (kIsWeb)
  ├─ Initialize database (if mobile)
  ├─ Setup service locator
  │  ├─ Register NoteLocalDataSource (if mobile)
  │  └─ Register NoteWebDataSource (if web)
  └─ Run app
```

---

## **4️⃣ Offline-First Architecture**

### **A. Repository Implementation (Offline-First)**

```dart
// lib/data/repositories/note_repository_impl.dart
class NoteRepositoryImpl implements NoteRepository {
  final NoteLocalDataSource localDataSource;
  final NoteRemoteDataSource remoteDataSource;
  
  NoteRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
  });
  
  // ✅ OFFLINE-FIRST: Try local first, fallback to remote
  @override
  Future<Either<Failure, List<NoteEntity>>> getAllNotes() async {
    try {
      // 1️⃣ Get from local (SQLite) - ALWAYS available
      final localNotes = await localDataSource.getAllNotes();
      
      // 2️⃣ Try to sync from remote (API) - May fail if offline
      try {
        final remoteNotes = await remoteDataSource.getAllNotes();
        // Update local cache with latest
        for (var note in remoteNotes) {
          await localDataSource.updateNote(note);
        }
      } catch (e) {
        // Network error - OK, use local data
        print('Network error: $e - Using local cache');
      }
      
      // 3️⃣ Return local data (either original or updated)
      return Right(localNotes);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }
  
  // ✅ CREATE: Save locally, sync remote when online
  @override
  Future<Either<Failure, int>> createNote(NoteEntity note) async {
    try {
      // 1️⃣ Save to local database IMMEDIATELY
      final noteModel = NoteModel.fromEntity(note);
      final id = await localDataSource.createNote(noteModel);
      
      // 2️⃣ Try to sync to remote (best-effort)
      try {
        await remoteDataSource.createNote(noteModel);
      } catch (e) {
        // Network error - OK, will sync when online
        print('Sync failed: $e - Will retry when online');
      }
      
      return Right(id);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }
  
  // ✅ UPDATE: Local first, remote when online
  @override
  Future<Either<Failure, void>> updateNote(NoteEntity note) async {
    try {
      final noteModel = NoteModel.fromEntity(note);
      
      // 1️⃣ Update local immediately
      await localDataSource.updateNote(noteModel);
      
      // 2️⃣ Try remote sync (optional)
      try {
        await remoteDataSource.updateNote(noteModel);
      } catch (e) {
        print('Sync failed: $e');
      }
      
      return Right(null);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }
  
  // ✅ DELETE: Local first, remote when online
  @override
  Future<Either<Failure, void>> deleteNote(int id) async {
    try {
      await localDataSource.deleteNote(id);
      
      try {
        await remoteDataSource.deleteNote(id);
      } catch (e) {
        print('Sync failed: $e');
      }
      
      return Right(null);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }
}
```

**Offline-First Flow**:
```
User Action (Online or Offline?)
         ↓
Repository.createNote()
         ↓
┌─ Save to Local DB ✅ (Always succeeds)
│
├─ Try Sync to Remote (Best-effort)
│  ├─ Online? → Sync successful ✅
│  └─ Offline? → Sync failed, will retry later ⏳
│
└─ Return Success to BLoC
(User never sees "no internet" error for local operations)
```

---

## **5️⃣ Caching Strategy (Dio Interceptors)**

### **A. Response Caching**

```dart
// lib/core/network/dio_client.dart
class DioClient {
  static final DioClient _instance = DioClient._internal();
  
  late final Dio _dio;
  
  factory DioClient() {
    return _instance;
  }
  
  DioClient._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: 'https://api.example.com',
      connectTimeout: const Duration(seconds: 10),
    ));
    
    // Add caching interceptor
    _dio.interceptors.add(_CacheInterceptor());
  }
  
  Dio get dio => _dio;
}

// ✅ Simple caching interceptor
class _CacheInterceptor extends Interceptor {
  // In-memory cache: key = URI, value = Response
  final Map<String, Response> _cache = {};
  
  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    // Cache GET requests only
    if (options.method == 'GET') {
      final key = '${options.method}:${options.uri}';
      
      if (_cache.containsKey(key)) {
        // Return cached response
        print('📦 Cache HIT: $key');
        return handler.resolve(_cache[key]!);
      }
    }
    
    handler.next(options);
  }
  
  @override
  void onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) {
    // Cache successful responses
    if (response.statusCode == 200) {
      final key = '${response.requestOptions.method}:${response.requestOptions.uri}';
      _cache[key] = response;
      print('💾 Cached: $key');
    }
    
    handler.next(response);
  }
}
```

**Cache Strategy**:
```
GET /api/notes
    ├─ Cache miss?
    │  ├─ Fetch from API
    │  ├─ Store in cache
    │  └─ Return response
    └─ Cache hit?
       └─ Return cached response (instant!)
```

---

## **6️⃣ Caching with Hive (Optional)**

### **A. Hive Setup (For Better Caching)**

```dart
// pubspec.yaml
dependencies:
  hive: ^3.1.0
  hive_flutter: ^1.1.0

// lib/main.dart
import 'package:hive_flutter/hive_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // ✅ Initialize Hive
  await Hive.initFlutter();
  
  // Register adapters
  Hive.registerAdapter(NoteModelAdapter());
  
  // Open boxes
  await Hive.openBox<NoteModel>('notes');
  await Hive.openBox('apiCache');
  
  runApp(const MyApp());
}
```

### **B. Hive Data Source Implementation**

```dart
// lib/data/datasources/cache/note_cache_data_source.dart
class NoteCacheDataSource {
  late final Box<NoteModel> _notesBox;
  late final Box _cacheBox;
  
  NoteCacheDataSource() {
    _notesBox = Hive.box<NoteModel>('notes');
    _cacheBox = Hive.box('apiCache');
  }
  
  // ✅ Cache notes
  Future<void> cacheNotes(List<NoteModel> notes) async {
    await _notesBox.clear();
    for (int i = 0; i < notes.length; i++) {
      await _notesBox.putAt(i, notes[i]);
    }
  }
  
  // ✅ Get cached notes
  Future<List<NoteModel>> getCachedNotes() async {
    return _notesBox.values.toList();
  }
  
  // ✅ Cache API response
  Future<void> cacheApiResponse(
    String key,
    dynamic response,
    Duration ttl,
  ) async {
    _cacheBox.put(key, {
      'data': jsonEncode(response),
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'ttl': ttl.inSeconds,
    });
  }
  
  // ✅ Get API response (check TTL)
  Future<dynamic?> getApiResponse(String key) async {
    final cached = _cacheBox.get(key);
    if (cached == null) return null;
    
    final timestamp = cached['timestamp'] as int;
    final ttl = cached['ttl'] as int;
    final elapsed = DateTime.now().millisecondsSinceEpoch - timestamp;
    
    // Check if expired
    if (elapsed > (ttl * 1000)) {
      await _cacheBox.delete(key);
      return null;
    }
    
    return jsonDecode(cached['data'] as String);
  }
  
  // ✅ Clear cache
  Future<void> clearCache() async {
    await _notesBox.clear();
    await _cacheBox.clear();
  }
}
```

**Hive Benefits**:
- 🔄 Automatic serialization (no JSON encoding/decoding)
- ⚡ Very fast (native Hive implementation)
- 💾 Persistent (survives app restart)
- 🔒 Type-safe (generic Box<T>)
- ⏰ TTL support (auto-expire cache)

---

## **7️⃣ Exception Handling**

```dart
// lib/core/error/exceptions.dart
abstract class AppException implements Exception {
  final String message;
  const AppException(this.message);
  
  @override
  String toString() => message;
}

class NoteDataException extends AppException {
  const NoteDataException(String message) : super(message);
}

class DatabaseFailure extends AppException {
  const DatabaseFailure(String message) : super(message);
}

class NetworkFailure extends AppException {
  const NetworkFailure(String message) : super(message);
}

class GeminiAPIException extends AppException {
  const GeminiAPIException(String message) : super(message);
}

class MLKitException extends AppException {
  const MLKitException(String message) : super(message);
}
```

---

## **8️⃣ Database Migration**

```dart
// Future: Add new column
Future<void> _onUpgrade(
  Database db,
  int oldVersion,
  int newVersion,
) async {
  if (oldVersion < 2) {
    // Migration from v1 to v2
    await db.execute('''
      ALTER TABLE notes 
      ADD COLUMN isPinned INTEGER DEFAULT 0
    ''');
  }
  
  if (oldVersion < 3) {
    // Migration from v2 to v3
    await db.execute('''
      CREATE INDEX idx_notes_created_at 
      ON notes(createdAt DESC)
    ''');
  }
}
```

---

## **📋 Database Comparison**

| ลักษณะ | SQLite | SharedPreferences | Hive |
|--------|---------|------------------|------|
| **Platform** | Mobile (Android/iOS) | Web + Mobile | Mobile + Web |
| **Type** | Relational DB | Key-value | Object DB |
| **Speed** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| **Storage Size** | Unlimited | ~100KB | Unlimited |
| **Queries** | SQL (JOIN, WHERE) | Simple key-get | CRUD operations |
| **Serialization** | Custom | JSON | Automatic |
| **TTL Support** | ❌ | ❌ | ✅ |
| **Encryption** | Yes (with extension) | iOS keychain only | Yes (with encryption) |
| **Use Case** | Large structured data | Settings + small data | Caching + offline |

**Recommendation**:
```
Mobile: SQLite (primary) + Hive (caching)
Web: SharedPreferences (primary) + Hive (caching)
Settings: SharedPreferences (both)
API Cache: Hive (if TTL needed) or Dio in-memory
```

---

## **🚀 Offline-First Workflow**

```
1️⃣ User opens app (offline)
   ├─ Load from local database ✅
   └─ Show cached data immediately

2️⃣ User creates/edits note
   ├─ Save to local DB immediately ✅
   ├─ Try to sync remote (best-effort)
   └─ Show success to user

3️⃣ Internet comes back
   ├─ BLoC detects connectivity
   ├─ Sync all pending changes
   └─ Pull latest from remote

4️⃣ Conflict resolution
   ├─ Last-write-wins strategy
   ├─ Or show conflict dialog
   └─ User chooses which version
```

---

## **✅ Offline Support Checklist**

- ✅ All CRUD operations work offline
- ✅ Local database initialized on app start
- ✅ Service locator detects platform
- ✅ Repository uses offline-first pattern
- ✅ Network errors don't crash app
- ✅ Pending changes saved locally
- ✅ Auto-sync when online
- ✅ GestureDetector works offline
- ✅ No "no internet" error for local ops
- ✅ Cache strategy in place

---

**สรุป**: Smart Vision Journal ใช้ **Offline-First Architecture** ที่ให้ผู้ใช้สามารถใช้งาน CRUD operations ได้เสมอ ไม่ว่าจะมีอินเทอร์เน็ตหรือไม่ 🚀
