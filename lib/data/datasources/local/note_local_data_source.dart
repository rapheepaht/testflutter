import 'package:sqflite/sqflite.dart';
import 'package:testflutter/core/error/exceptions.dart' as custom_exceptions;
import 'package:testflutter/data/models/note_model.dart';

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

  static const String tableNotes = 'notes';

  @override
  Future<List<NoteModel>> getAllNotes() async {
    try {
      final List<Map<String, dynamic>> maps = await database.query(tableNotes);
      return List<NoteModel>.from(maps.map((x) => NoteModel.fromDatabase(x)));
    } catch (e) {
      throw custom_exceptions.NoteDataException('Failed to fetch notes: $e');
    }
  }

  @override
  Future<NoteModel> getNoteById(int id) async {
    try {
      final List<Map<String, dynamic>> maps = await database.query(
        tableNotes,
        where: 'id = ?',
        whereArgs: [id],
      );

      if (maps.isEmpty) {
        throw custom_exceptions.NoteDataException('Note not found');
      }

      return NoteModel.fromDatabase(maps.first);
    } catch (e) {
      throw custom_exceptions.NoteDataException('Failed to fetch note: $e');
    }
  }

  @override
  Future<int> createNote(NoteModel note) async {
    try {
      return await database.insert(
        tableNotes,
        note.toDatabase(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw custom_exceptions.NoteDataException('Failed to create note: $e');
    }
  }

  @override
  Future<void> updateNote(NoteModel note) async {
    try {
      await database.update(
        tableNotes,
        note.toDatabase(),
        where: 'id = ?',
        whereArgs: [note.id],
      );
    } catch (e) {
      throw custom_exceptions.NoteDataException('Failed to update note: $e');
    }
  }

  @override
  Future<void> deleteNote(int id) async {
    try {
      await database.delete(
        tableNotes,
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw custom_exceptions.NoteDataException('Failed to delete note: $e');
    }
  }

  @override
  Future<List<NoteModel>> searchNotes(String query) async {
    try {
      final List<Map<String, dynamic>> maps = await database.query(
        tableNotes,
        where: 'title LIKE ? OR content LIKE ?',
        whereArgs: ['%$query%', '%$query%'],
      );
      return List<NoteModel>.from(maps.map((x) => NoteModel.fromDatabase(x)));
    } catch (e) {
      throw custom_exceptions.NoteDataException('Failed to search notes: $e');
    }
  }
}
