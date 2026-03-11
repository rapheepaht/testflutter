import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:testflutter/core/error/exceptions.dart';
import 'package:testflutter/data/models/note_model.dart';

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

  NoteWebDataSourceImpl();

  Future<SharedPreferences> _getPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

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

  @override
  Future<NoteModel?> getNoteById(int id) async {
    try {
      final notes = await getAllNotes();
      try {
        return notes.firstWhere((note) => note.id == id);
      } catch (_) {
        return null;
      }
    } catch (e) {
      throw NoteDataException('Failed to get note by id: $e');
    }
  }

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

  @override
  Future<int> updateNote(NoteModel note) async {
    try {
      final notes = await getAllNotes();
      final prefs = await _getPrefs();
      final index = notes.indexWhere((n) => n.id == note.id);
      if (index == -1) {
        throw NoteDataException('Note not found');
      }
      notes[index] = note.copyWith(
        updatedAt: DateTime.now(),
      );
      await _saveNotes(notes, prefs);
      return 1;
    } catch (e) {
      throw NoteDataException('Failed to update note: $e');
    }
  }

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

  @override
  Future<List<NoteModel>> searchNotes(String query) async {
    try {
      final notes = await getAllNotes();
      final lowerQuery = query.toLowerCase();
      return notes
          .where((note) =>
              note.title.toLowerCase().contains(lowerQuery) ||
              note.content.toLowerCase().contains(lowerQuery) ||
              note.tags.any((tag) => tag.toLowerCase().contains(lowerQuery)))
          .toList();
    } catch (e) {
      throw NoteDataException('Failed to search notes: $e');
    }
  }

  Future<void> _saveNotes(List<NoteModel> notes, SharedPreferences prefs) async {
    try {
      final jsonList = notes.map((note) => note.toJson()).toList();
      final jsonString = jsonEncode(jsonList);
      await prefs.setString(_notesKey, jsonString);
    } catch (e) {
      throw NoteDataException('Failed to save notes: $e');
    }
  }
}
