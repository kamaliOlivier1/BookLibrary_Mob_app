import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../models/book.dart';
import '../helpers/database_helper.dart';
import 'add_edit_book_screen.dart';

class BookDetailScreen extends StatefulWidget {
  static const routeName = '/book-detail';

  @override
  _BookDetailScreenState createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  late Book _book;
  bool _isLoading = true;
  final DatabaseHelper _dbHelper = DatabaseHelper();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bookId = ModalRoute.of(context)!.settings.arguments as String;
    _loadBook(bookId);
  }

  Future<void> _loadBook(String id) async {
    final books = await _dbHelper.getBooks();
    setState(() {
      _book = books.firstWhere((book) => book.id == id);
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: <Widget>[
                _buildSliverAppBar(),
                SliverToBoxAdapter(
                  child: _buildBookDetails(),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _editBook(context),
        child: Icon(Icons.edit),
        backgroundColor: Theme.of(context).colorScheme.secondary,
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 200.0,
      floating: false,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          _book.title,
          style: GoogleFonts.poppins(
            textStyle: TextStyle(
              color: Colors.white,
              fontSize: 16.0,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        background: Hero(
          tag: 'bookCover${_book.id}',
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Theme.of(context).primaryColor,
                  Theme.of(context).primaryColor.withOpacity(0.8),
                ],
              ),
            ),
            child: Center(
              child: Icon(
                Icons.book,
                size: 80,
                color: Colors.white70,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBookDetails() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildInfoRow(Icons.person, 'Author', _book.author),
          SizedBox(height: 16),
          _buildRatingRow(),
          SizedBox(height: 16),
          _buildReadStatus(),
          SizedBox(height: 24),
          Text(
            'Description',
            style: GoogleFonts.poppins(
              textStyle: Theme.of(context).textTheme.titleLarge,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            _book.description,
            style: GoogleFonts.poppins(
              textStyle: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: <Widget>[
        Icon(icon, color: Theme.of(context).primaryColor),
        SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              label,
              style: GoogleFonts.poppins(
                textStyle: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            Text(
              value,
              style: GoogleFonts.poppins(
                textStyle: Theme.of(context).textTheme.titleMedium,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRatingRow() {
    return Row(
      children: <Widget>[
        Icon(Icons.star, color: Theme.of(context).primaryColor),
        SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Rating',
              style: GoogleFonts.poppins(
                textStyle: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            RatingBar.builder(
              initialRating: _book.rating,
              minRating: 0,
              direction: Axis.horizontal,
              allowHalfRating: true,
              itemCount: 5,
              itemSize: 20,
              itemBuilder: (context, _) => Icon(
                Icons.star,
                color: Colors.amber,
              ),
              onRatingUpdate: (rating) {
                // Update rating logic here
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildReadStatus() {
    return Row(
      children: <Widget>[
        Icon(Icons.book, color: Theme.of(context).primaryColor),
        SizedBox(width: 8),
        Text(
          'Read Status:',
          style: GoogleFonts.poppins(
            textStyle: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        SizedBox(width: 8),
        Chip(
          label: Text(
            _book.isRead ? 'Read' : 'Unread',
            style: GoogleFonts.poppins(
              textStyle: TextStyle(color: Colors.white),
            ),
          ),
          backgroundColor: _book.isRead ? Colors.green : Colors.orange,
        ),
      ],
    );
  }

  void _editBook(BuildContext context) async {
    final result = await Navigator.of(context).pushNamed(
      AddEditBookScreen.routeName,
      arguments: _book.id,
    );
    if (result == true) {
      _loadBook(_book.id);
    }
  }
}