import 'package:flutter/foundation.dart';
import '../models/book.dart';
import 'preferences_provider.dart';
import '../helpers/database_helper.dart';

class BookProvider with ChangeNotifier {
  PreferencesProvider _preferencesProvider;
  final DatabaseHelper _dbHelper = DatabaseHelper();

  List<Book> _books = [];

  BookProvider(this._preferencesProvider) {
    _initializeBooks();
  }

  List<Book> get books {
    _sortBooks();
    return List.unmodifiable(_books);
  }

  Future<void> _initializeBooks() async {
    await loadBooks();
  }

  Future<void> loadBooks() async {
    try {
      _books = await _dbHelper.getBooks();
      _sortBooks();
      notifyListeners();
    } catch (error) {
      debugPrint('Error loading books: $error');
      _books = [];
      notifyListeners();
    }
  }

  void _sortBooks() {
    final sortOrder = _preferencesProvider.sortOrder;
    _books.sort((a, b) {
      switch (sortOrder) {
        case 'title':
          return a.title.compareTo(b.title);
        case 'author':
          return a.author.compareTo(b.author);
        case 'rating':
          return b.rating.compareTo(a.rating);
        default:
          return 0;
      }
    });
  }

  Book? findById(String id) {
    try {
      return _books.firstWhere((book) => book.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<void> addBook(Book book) async {
    final newBook = Book(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: book.title,
      author: book.author,
      description: book.description,
      rating: book.rating,
      isRead: book.isRead,
    );

    try {
      await _dbHelper.insertBook(newBook);
      _books.add(newBook);
      _sortBooks();
      notifyListeners();
    } catch (error) {
      debugPrint('Error adding book: $error');
    }
  }

  Future<void> updateBook(String id, Book newBook) async {
    final bookIndex = _books.indexWhere((book) => book.id == id);
    if (bookIndex >= 0) {
      try {
        final updatedBook = Book(
          id: id,
          title: newBook.title,
          author: newBook.author,
          description: newBook.description,
          rating: newBook.rating,
          isRead: newBook.isRead,
        );
        await _dbHelper.updateBook(updatedBook);
        _books[bookIndex] = updatedBook;
        _sortBooks();
        notifyListeners();
      } catch (error) {
        debugPrint('Error updating book: $error');
      }
    }
  }

  Future<void> deleteBook(String id) async {
    try {
      await _dbHelper.deleteBook(id);
      _books.removeWhere((book) => book.id == id);
      notifyListeners();
    } catch (error) {
      debugPrint('Error deleting book: $error');
    }
  }

  Future<void> refreshBooks() async {
    await loadBooks();
  }

  void updatePreferences(PreferencesProvider newPrefs) {
    _preferencesProvider = newPrefs;
    _sortBooks();
    notifyListeners();
  }

  // New method to update book rating
  Future<void> updateBookRating(String id, double newRating) async {
    final book = findById(id);
    if (book != null) {
      final updatedBook = Book(
        id: book.id,
        title: book.title,
        author: book.author,
        description: book.description,
        rating: newRating,
        isRead: book.isRead,
      );
      await updateBook(id, updatedBook);
    }
  }

  // New method to toggle read/unread status
  Future<void> toggleReadStatus(String id) async {
    final book = findById(id);
    if (book != null) {
      final updatedBook = Book(
        id: book.id,
        title: book.title,
        author: book.author,
        description: book.description,
        rating: book.rating,
        isRead: !book.isRead,
      );
      await updateBook(id, updatedBook);
    }
  }
}