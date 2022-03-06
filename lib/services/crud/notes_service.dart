import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:mynotes/services/crud/crud_exceptions.dart';
import 'package:path/path.dart' show join;
import 'package:path_provider/path_provider.dart'
    show getApplicationDocumentsDirectory, MissingPlatformDirectoryException;
import 'package:sqflite/sqflite.dart';

class NotesService {
  Database? _db; // from sqflite package

  Database _getDatabaseOrThrow() {
    // a private convenient function for getting current db
    final db = _db;
    if (db == null) {
      throw DBIsNotOpen();
    } else {
      return db;
    }
  }

  // make NotesService a singleton
  static final NotesService _shared = NotesService._sharedInstance();
  NotesService._sharedInstance() {
    _notesStreamController = StreamController<List<DBNote>>.broadcast(
      onListen: () {
        _notesStreamController.sink.add(_notes);
      },
    );
  }

  factory NotesService() => _shared;

  // create note stream for caching
  List<DBNote> _notes = [];
  late final StreamController<List<DBNote>> _notesStreamController;

  Future<void> _cacheNotes() async {
    final allNotes = await getAllNotes();
    // getAllNotes() returns an Iterable<DBNote> while _notes is declared as List
    // we can either convert Iterable to List with .toList() or we can declare
    // _notes as Iterable to match with allNotes and drop .toList()
    _notes = allNotes.toList();
    _notesStreamController.add(_notes);
  }

  Stream<List<DBNote>> get allNotes => _notesStreamController.stream;
  Future<DBUser> getOrCreateUser({required String email}) async {
    try {
      final user = await getUser(email: email);
      return user;
    } on CouldNotFindUser {
      final createdUser = await createUser(email: email);
      return createdUser;
    } catch (err) {
      rethrow;
    }
  }

  Future<DBNote> getNote({required int id}) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();

    final notes = await db.query(
      noteTable,
      limit: 1,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (notes.isEmpty) {
      throw CouldNotFindNote();
    } else {
      final note = DBNote.fromRow(notes.first);
      _notes.removeWhere((note) => note.id == id);
      _notes.add(note);
      _notesStreamController.add(_notes);
      return note;
    }
  }

  Future<Iterable<DBNote>> getAllNotes() async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final allNotes = await db.query(noteTable);

    final results = allNotes.map((noteRow) => DBNote.fromRow(noteRow));
    return results;
  }

  Future<DBNote> createNote({required DBUser owner}) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();

    final dbUser = await getUser(email: owner.email);

    // make sure that the owner user exists in db with correct id
    if (dbUser != owner) return throw CouldNotFindUser();

    final noteId = await db.insert(noteTable, {
      userIdColumn: owner.id,
      textColumn: '',
    });

    final note = DBNote(
      id: noteId,
      userId: owner.id,
      text: '',
    );

    // add the newly created note into note cache
    _notes.add(note);
    _notesStreamController.add(_notes);
    return note;
  }

  Future<DBNote> updateNote({
    required DBNote note,
    required String text,
  }) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    await getNote(id: note.id); // checking if the note exists in db

    final updatedCount = await db.update(noteTable, {
      textColumn: text,
    });

    if (updatedCount == 0) {
      throw CouldNotUpdateNote();
    } else {
      final updatedNote = await getNote(id: note.id);
      _notes.removeWhere((note) => note.id == updatedNote.id);
      _notes.add(updatedNote);
      _notesStreamController.add(_notes);
      return updatedNote;
    }
  }

  Future<void> deleteNote({required int noteId}) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final deletedCount = await db.delete(
      noteTable,
      where: 'id = ?',
      whereArgs: [noteId],
    );

    if (deletedCount == 0) {
      throw CouldNotDeleteNote();
      // remove the deleted note from cache
    } else {
      _notes.removeWhere((note) => note.id == noteId);
      _notesStreamController.add(_notes);
    }
  }

  Future<int> deleteAllNotes() async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final deletedCount = await db.delete(noteTable);
    // update notes cache with empty
    _notes = [];
    _notesStreamController.add(_notes);
    return deletedCount;
  }

  Future<DBUser> getUser({required String email}) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();

    final results = await db.query(
      userTable,
      limit: 1,
      where: 'email = ?',
      whereArgs: [email.toLowerCase()],
    );

    if (results.isEmpty) return throw CouldNotFindUser();
    return DBUser.fromRow(results.first);
  }

  Future<DBUser> createUser({required String email}) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final results = await db.query(
      userTable,
      limit: 1,
      where: 'email = ?',
      whereArgs: [email.toLowerCase()],
    );

    if (results.isNotEmpty) return throw UserAlreadyExists();

    final userId = await db.insert(userTable, {
      emailColumn: email.toLowerCase(),
    });
    return DBUser(
      id: userId,
      email: email,
    );
  }

  Future<void> deleteUser({required String email}) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final deletedCount = await db.delete(
      userTable,
      where: 'email = ?',
      whereArgs: [email.toLowerCase()],
    );

    if (deletedCount != 1) throw CouldNotDeleteUser();
  }

  Future<void> close() async {
    final db = _db;

    if (db == null) {
      throw DBIsNotOpen();
    } else {
      await db.close();
      _db = null;
    }
  }

  Future<void> _ensureDbIsOpen() async {
    try {
      await open();
    } on DBAlreadyOpenException {
      // empty
    }
  }

  Future<void> open() async {
    if (_db != null) {
      throw DBAlreadyOpenException();
    }

    try {
      // get the path to the application
      final docsPath = await getApplicationDocumentsDirectory();
      // join it with our dbName
      final dbPath = join(docsPath.path, dbName);
      // open db connection
      final db = await openDatabase(dbPath);
      _db = db; // assign it to our local database variable

      // excute sql queries to create user and note tables
      await db.execute(createUserTable);
      await db.execute(createNoteTable);

      await _cacheNotes(); // get all notes existing in db and cache it
    } on MissingPlatformDirectoryException {
      throw UnableToGetDocumentsDirectory();
    }
  }
}

@immutable
class DBUser {
  final int id;
  final String email;

  const DBUser({
    required this.id,
    required this.email,
  });

  DBUser.fromRow(Map<String, Object?> map)
      : id = map[idColumn] as int,
        email = map[emailColumn] as String;

  @override
  String toString() => 'Person, ID = $id, email = $email';

  @override
  // override equality to tell flutter that if 2 objects have the same id, they are equal
  bool operator ==(covariant DBUser other) => id == other.id;

  @override
  int get hashCode => id.hashCode;
}

@immutable
class DBNote {
  final int id;
  final int userId;
  final String? text;

  const DBNote({
    required this.id,
    required this.userId,
    this.text,
  });

  DBNote.fromRow(Map<String, Object?> map)
      : id = map[idColumn] as int,
        userId = map[userIdColumn] as int,
        text = map[textColumn] as String;

  @override
  String toString() => 'Note, ID = $id, userId = $userId, text = $text';

  @override
  bool operator ==(covariant DBNote other) => id == other.id;

  @override
  int get hashCode => id.hashCode;
}

const dbName = 'notes.db';
const noteTable = 'note';
const userTable = 'user';
const idColumn = 'id';
const emailColumn = 'email';
const userIdColumn = 'user_id';
const textColumn = 'text';

const createUserTable = '''CREATE TABLE IF NOT EXISTS "user" (
                          "id"	INTEGER NOT NULL,
                          "email"	TEXT NOT NULL UNIQUE,
                          PRIMARY KEY("id" AUTOINCREMENT)
                        );''';
const createNoteTable = '''CREATE TABLE IF NOT EXISTS "note" (
                          "id"	INTEGER NOT NULL,
                          "user_id"	INTEGER NOT NULL,
                          "text"	TEXT,
                          FOREIGN KEY("user_id") REFERENCES "user"("id"),
                          PRIMARY KEY("id" AUTOINCREMENT)
                        );''';
