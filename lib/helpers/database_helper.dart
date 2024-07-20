import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/book.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() {
    return _instance;
  }

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'books.db');

    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE books (
        id TEXT PRIMARY KEY,
        title TEXT,
        author TEXT,
        description TEXT,
        rating REAL,
        isRead INTEGER
      )
    ''');

    await db.execute('CREATE INDEX idx_title ON books (title)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE books ADD COLUMN isRead INTEGER DEFAULT 0');
    }
  }

  Future<void> insertBook(Book book) async {
    try {
      final db = await database;
      await db.insert('books', book.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      print('Error inserting book: $e');
      rethrow;
    }
  }

  Future<void> updateBook(Book book) async {
    try {
      final db = await database;
      await db.update('books', book.toMap(), where: 'id = ?', whereArgs: [book.id]);
    } catch (e) {
      print('Error updating book: $e');
      rethrow;
    }
  }

  Future<void> deleteBook(String id) async {
    try {
      final db = await database;
      await db.delete('books', where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      print('Error deleting book: $e');
      rethrow;
    }
  }

  Future<List<Book>> getBooks() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query('books');
      return List.generate(maps.length, (i) {
        return Book.fromMap(maps[i]);
      });
    } catch (e) {
      print('Error getting books: $e');
      rethrow;
    }
  }

  Future<void> insertBooks(List<Book> books) async {
    try {
      final db = await database;
      final batch = db.batch();
      for (var book in books) {
        batch.insert('books', book.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await batch.commit(noResult: true);
    } catch (e) {
      print('Error inserting books in batch: $e');
      rethrow;
    }
  }

  Future<void> close() async {
    final db = await database;
    db.close();
    _database = null;
  }
}