import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/book.dart';
import '../helpers/database_helper.dart';
import '../providers/preferences_provider.dart';
import 'add_edit_book_screen.dart';
import 'book_detail_screen.dart';
import 'settings_screen.dart';

class BookListScreen extends StatefulWidget {
  @override
  _BookListScreenState createState() => _BookListScreenState();
}

class _BookListScreenState extends State<BookListScreen> with SingleTickerProviderStateMixin {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Book> _books = [];
  List<Book> _filteredBooks = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  RefreshController _refreshController = RefreshController(initialRefresh: false);
  late AnimationController _animationController;
  bool _isGridView = false;

  @override
  void initState() {
    super.initState();
    _loadBooks();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    _refreshController.dispose();
    super.dispose();
  }

  Future<void> _loadBooks() async {
    setState(() {
      _isLoading = true;
    });
    final books = await _dbHelper.getBooks();
    setState(() {
      _books = books;
      _filteredBooks = books;
      _isLoading = false;
    });
    _animationController.forward(from: 0);
  }

  void _filterBooks() {
    setState(() {
      if (_searchQuery.isEmpty) {
        _filteredBooks = _books;
      } else {
        _filteredBooks = _books
            .where((book) =>
                book.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                book.author.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();
      }
    });
  }

  void _onRefresh() async {
    await _loadBooks();
    _refreshController.refreshCompleted();
  }

  @override
  Widget build(BuildContext context) {
    final prefs = Provider.of<PreferencesProvider>(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: _buildAppBar(context, isDarkMode),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _filteredBooks.isEmpty
                ? _buildEmptyState()
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      _buildSearchBar(),
                      _buildBookCount(),
                      Expanded(
                        child: SmartRefresher(
                          controller: _refreshController,
                          onRefresh: _onRefresh,
                          child: _isGridView
                              ? _buildBookGrid(prefs, isDarkMode)
                              : _buildBookList(prefs, isDarkMode),
                        ),
                      ),
                    ],
                  ),
      ),
      floatingActionButton: _buildFloatingActionButton(context),
    );
  }

  AppBar _buildAppBar(BuildContext context, bool isDarkMode) {
    return AppBar(
      backgroundColor: Theme.of(context).primaryColor,
      systemOverlayStyle: isDarkMode ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      elevation: 0,
      title: Text(
        'Your Library',
        style: GoogleFonts.poppins(
          textStyle: TextStyle(color: Theme.of(context).appBarTheme.titleTextStyle?.color),
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(_isGridView ? Icons.list : Icons.grid_view, color: Theme.of(context).iconTheme.color),
          onPressed: () {
            setState(() {
              _isGridView = !_isGridView;
            });
          },
        ),
        IconButton(
          icon: Icon(Icons.settings, color: Theme.of(context).iconTheme.color),
          onPressed: () async {
            await Navigator.of(context).pushNamed(SettingsScreen.routeName);
            setState(() {});
          },
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          color: Theme.of(context).cardColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search books',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                        _filterBooks();
                      });
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          ),
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
              _filterBooks();
            });
          },
        ),
      ),
    );
  }

  Widget _buildBookCount() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Text(
        '${_filteredBooks.length} ${_filteredBooks.length == 1 ? 'Book' : 'Books'}',
        style: GoogleFonts.poppins(
          textStyle: Theme.of(context).textTheme.titleLarge,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildBookList(PreferencesProvider prefs, bool isDarkMode) {
    List<Book> sortedBooks = _getSortedBooks(prefs);

    return AnimationLimiter(
      child: ListView.builder(
        itemCount: sortedBooks.length,
        itemBuilder: (ctx, index) {
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 375),
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: _buildBookItem(sortedBooks[index], isDarkMode),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBookGrid(PreferencesProvider prefs, bool isDarkMode) {
    List<Book> sortedBooks = _getSortedBooks(prefs);

    return AnimationLimiter(
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: sortedBooks.length,
        itemBuilder: (ctx, index) {
          return AnimationConfiguration.staggeredGrid(
            position: index,
            duration: const Duration(milliseconds: 375),
            columnCount: 2,
            child: ScaleAnimation(
              child: FadeInAnimation(
                child: _buildBookGridItem(sortedBooks[index], isDarkMode),
              ),
            ),
          );
        },
      ),
    );
  }

  List<Book> _getSortedBooks(PreferencesProvider prefs) {
    List<Book> sortedBooks = List.from(_filteredBooks);
    switch (prefs.sortOrder) {
      case 'title':
        sortedBooks.sort((a, b) => a.title.compareTo(b.title));
        break;
      case 'author':
        sortedBooks.sort((a, b) => a.author.compareTo(b.author));
        break;
      case 'rating':
        sortedBooks.sort((a, b) => b.rating.compareTo(a.rating));
        break;
    }
    return sortedBooks;
  }

  Widget _buildBookItem(Book book, bool isDarkMode) {
    return Slidable(
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.25,
        children: [
          SlidableAction(
            label: 'Delete',
            backgroundColor: Colors.red,
            icon: Icons.delete,
            onPressed: (context) => _deleteBook(book),
          ),
        ],
      ),
      child: Card(
        elevation: 4,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: () => _viewBookDetails(book.id),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        book.title,
                        style: GoogleFonts.poppins(
                          textStyle: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Theme.of(context).textTheme.titleLarge?.color,
                          ),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.edit, color: Theme.of(context).iconTheme.color),
                      onPressed: () => _editBook(book.id),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  book.author,
                  style: GoogleFonts.poppins(
                    textStyle: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _buildRatingStars(book)),
                    _buildReadToggle(book),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBookGridItem(Book book, bool isDarkMode) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _viewBookDetails(book.id),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Center(
                  child: Icon(Icons.book, size: 64, color: Theme.of(context).primaryColor),
                ),
              ),
              Text(
                book.title,
                style: GoogleFonts.poppins(
                  textStyle: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Theme.of(context).textTheme.titleLarge?.color,
                  ),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                book.author,
                style: GoogleFonts.poppins(
                  textStyle: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: _buildRatingStars(book)),
                  _buildReadToggle(book),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRatingStars(Book book) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return GestureDetector(
          onTap: () => _updateBookRating(book, index + 1),
          child: Icon(
            index < book.rating ? Icons.star : Icons.star_border,
            color: Colors.amber,
            size: 20,
          ),
        );
      }),
    );
  }

  Widget _buildReadToggle(Book book) {
    return Switch(
      value: book.isRead,
      onChanged: (value) => _updateBookReadStatus(book, value),
      activeColor: Theme.of(context).colorScheme.secondary,
    );
  }

  Future<void> _updateBookRating(Book book, int rating) async {
    final updatedBook = Book(
      id: book.id,
      title: book.title,
      author: book.author,
      description: book.description,
      rating: rating.toDouble(),
      isRead: book.isRead,
    );
    await _dbHelper.updateBook(updatedBook);
    await _loadBooks();
    _showSnackBar('Rating updated');
  }

  Future<void> _updateBookReadStatus(Book book, bool isRead) async {
    final updatedBook = Book(
      id: book.id,
      title: book.title,
      author: book.author,
      description: book.description,
      rating: book.rating,
      isRead: isRead,
    );
    await _dbHelper.updateBook(updatedBook);
    _loadBooks();
    _showSnackBar(isRead ? 'Marked as read' : 'Marked as unread');
  }

  Widget _buildFloatingActionButton(BuildContext context) {
    return FloatingActionButton(
      child: const Icon(Icons.add),
      onPressed: () => _addNewBook(),
      backgroundColor: Theme.of(context).colorScheme.secondary,
      foregroundColor: Theme.of(context).colorScheme.onSecondary,
    );
  }

  Future<void> _addNewBook() async {
    final result = await Navigator.of(context).pushNamed(AddEditBookScreen.routeName);
    if (result == true) {
      await _loadBooks();
      _showSnackBar('Book added successfully');
    }
  }

  Future<void> _editBook(String bookId) async {
    final result = await Navigator.of(context).pushNamed(
      AddEditBookScreen.routeName,
      arguments: bookId,
    );
    if (result == true) {
      await _loadBooks();
      _showSnackBar('Book updated successfully');
    }
  }

  Future<void> _viewBookDetails(String bookId) async {
    await Navigator.of(context).pushNamed(
      BookDetailScreen.routeName,
      arguments: bookId,
    );
    await _loadBooks();
  }

  Future<void> _deleteBook(Book book) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Confirm Deletion'),
        content: Text('Are you sure you want to delete "${book.title}"?'),
        actions: [
          TextButton(
            child: Text('Cancel'),
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
          TextButton(
            child: Text('Delete'),
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _dbHelper.deleteBook(book.id);
      await _loadBooks();
      _showSnackBar('Book deleted');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        action: SnackBarAction(
          label: 'Dismiss',
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.library_books,
            size: 80,
            color: Theme.of(context).disabledColor,
          ),
          SizedBox(height: 16),
          Text(
            'Your library is empty',
            style: GoogleFonts.poppins(
              textStyle: Theme.of(context).textTheme.headlineSmall,
              color: Theme.of(context).disabledColor,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Add some books to get started!',
            style: GoogleFonts.poppins(
              textStyle: Theme.of(context).textTheme.bodyMedium,
              color: Theme.of(context).disabledColor,
            ),
          ),
        ],
      ),
    );
  }
}