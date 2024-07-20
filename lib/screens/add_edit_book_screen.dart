import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../models/book.dart';
import '../helpers/database_helper.dart';

class AddEditBookScreen extends StatefulWidget {
  static const routeName = '/add-edit-book';

  @override
  _AddEditBookScreenState createState() => _AddEditBookScreenState();
}

class _AddEditBookScreenState extends State<AddEditBookScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  var _editedBook = Book(id: '', title: '', author: '', description: '', rating: 0.0, isRead: false);
  var _isInit = true;
  var _initValues = {
    'title': '',
    'author': '',
    'description': '',
    'rating': '0.0',
    'isRead': false,
  };

  final DatabaseHelper _dbHelper = DatabaseHelper();
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    if (_isInit) {
      final bookId = ModalRoute.of(context)?.settings.arguments as String?;
      if (bookId != null) {
        _loadBook(bookId);
      }
    }
    _isInit = false;
    super.didChangeDependencies();
  }

  Future<void> _loadBook(String id) async {
    final books = await _dbHelper.getBooks();
    final book = books.firstWhere((book) => book.id == id);
    setState(() {
      _editedBook = book;
      _initValues = {
        'title': book.title,
        'author': book.author,
        'description': book.description,
        'rating': book.rating.toString(),
        'isRead': book.isRead,
      };
    });
  }

  Future<void> _saveForm() async {
    final isValid = _formKey.currentState?.validate();
    if (!isValid!) {
      return;
    }
    _formKey.currentState?.save();
    
    try {
      if (_editedBook.id.isEmpty) {
        _editedBook = Book(
          id: DateTime.now().toString(),
          title: _editedBook.title,
          author: _editedBook.author,
          description: _editedBook.description,
          rating: _editedBook.rating,
          isRead: _editedBook.isRead,
        );
        await _dbHelper.insertBook(_editedBook);
      } else {
        await _dbHelper.updateBook(_editedBook);
      }
      Navigator.of(context).pop(true);
    } catch (error) {
      await _showErrorDialog('An error occurred!', 'Something went wrong.');
    }
  }

  Future<void> _deleteBook() async {
    if (_editedBook.id.isNotEmpty) {
      try {
        await _dbHelper.deleteBook(_editedBook.id);
        Navigator.of(context).pop(true);
      } catch (error) {
        await _showErrorDialog('An error occurred!', 'Could not delete the book.');
      }
    }
  }

  Future<void> _showErrorDialog(String title, String message) async {
    await showDialog<Null>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            child: Text('Okay'),
            onPressed: () {
              Navigator.of(ctx).pop();
            },
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        systemOverlayStyle: isDarkMode ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        elevation: 0,
        title: Text(
          _editedBook.id.isEmpty ? 'Add Book' : 'Edit Book',
          style: GoogleFonts.poppins(
            textStyle: TextStyle(color: Theme.of(context).appBarTheme.titleTextStyle?.color),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.save, color: Theme.of(context).iconTheme.color),
            onPressed: _saveForm,
          ),
          if (_editedBook.id.isNotEmpty)
            IconButton(
              icon: Icon(Icons.delete, color: Theme.of(context).iconTheme.color),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text('Are you sure?'),
                    content: Text('Do you want to delete this book?'),
                    actions: <Widget>[
                      TextButton(
                        child: Text('No'),
                        onPressed: () {
                          Navigator.of(ctx).pop();
                        },
                      ),
                      TextButton(
                        child: Text('Yes'),
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          _deleteBook();
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _animation,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Book Details',
                      style: GoogleFonts.poppins(
                        textStyle: Theme.of(context).textTheme.headlineMedium,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 20),
                    _buildTextField(
                      initialValue: _initValues['title'] as String,
                      labelText: 'Title',
                      validator: (value) {
                        if (value!.isEmpty) {
                          return 'Please provide a title.';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        _editedBook = Book(
                          id: _editedBook.id,
                          title: value!,
                          author: _editedBook.author,
                          description: _editedBook.description,
                          rating: _editedBook.rating,
                          isRead: _editedBook.isRead,
                        );
                      },
                    ),
                    SizedBox(height: 16),
                    _buildTextField(
                      initialValue: _initValues['author'] as String,
                      labelText: 'Author',
                      validator: (value) {
                        if (value!.isEmpty) {
                          return 'Please provide an author.';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        _editedBook = Book(
                          id: _editedBook.id,
                          title: _editedBook.title,
                          author: value!,
                          description: _editedBook.description,
                          rating: _editedBook.rating,
                          isRead: _editedBook.isRead,
                        );
                      },
                    ),
                    SizedBox(height: 16),
                    _buildTextField(
                      initialValue: _initValues['description'] as String,
                      labelText: 'Description',
                      maxLines: 3,
                      validator: (value) {
                        if (value!.isEmpty) {
                          return 'Please provide a description.';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        _editedBook = Book(
                          id: _editedBook.id,
                          title: _editedBook.title,
                          author: _editedBook.author,
                          description: value!,
                          rating: _editedBook.rating,
                          isRead: _editedBook.isRead,
                        );
                      },
                    ),
                    SizedBox(height: 24),
                    Text(
                      'Rating',
                      style: GoogleFonts.poppins(
                        textStyle: Theme.of(context).textTheme.titleMedium,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    RatingBar.builder(
                      initialRating: double.parse(_initValues['rating'] as String),
                      minRating: 0,
                      direction: Axis.horizontal,
                      allowHalfRating: true,
                      itemCount: 5,
                      itemPadding: EdgeInsets.symmetric(horizontal: 4.0),
                      itemBuilder: (context, _) => Icon(
                        Icons.star,
                        color: Colors.amber,
                      ),
                      onRatingUpdate: (rating) {
                        _editedBook = Book(
                          id: _editedBook.id,
                          title: _editedBook.title,
                          author: _editedBook.author,
                          description: _editedBook.description,
                          rating: rating,
                          isRead: _editedBook.isRead,
                        );
                      },
                    ),
                    SizedBox(height: 24),
                    SwitchListTile(
                      title: Text(
                        'Mark as Read',
                        style: GoogleFonts.poppins(
                          textStyle: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                        ),
                      ),
                      value: _editedBook.isRead,
                      onChanged: (bool value) {
                        setState(() {
                          _editedBook = Book(
                            id: _editedBook.id,
                            title: _editedBook.title,
                            author: _editedBook.author,
                            description: _editedBook.description,
                            rating: _editedBook.rating,
                            isRead: value,
                          );
                        });
                      },
                      activeColor: Theme.of(context).colorScheme.secondary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String initialValue,
    required String labelText,
    int maxLines = 1,
    required String? Function(String?) validator,
    required void Function(String?) onSaved,
  }) {
    return TextFormField(
      initialValue: initialValue,
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: GoogleFonts.poppins(
          textStyle: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.secondary, width: 2),
        ),
      ),
      style: GoogleFonts.poppins(
        textStyle: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
      ),
      maxLines: maxLines,
      textInputAction: maxLines > 1 ? TextInputAction.newline : TextInputAction.next,
      validator: validator,
      onSaved: onSaved,
    );
  }
}