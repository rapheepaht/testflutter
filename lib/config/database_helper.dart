import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

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

  static final DatabaseHelper _instance = DatabaseHelper._internal();

  factory DatabaseHelper() {
    return _instance;
  }

  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

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
