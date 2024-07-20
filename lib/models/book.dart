class Book {
  final String id;
  final String title;
  final String author;
  final String description;
  final double rating;
  final bool isRead;

  Book({
    required this.id,
    required this.title,
    required this.author,
    required this.description,
    required this.rating,
    required this.isRead,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'description': description,
      'rating': rating,
      'isRead': isRead ? 1 : 0,
    };
  }

  factory Book.fromMap(Map<String, dynamic> map) {
    return Book(
      id: map['id'] as String,
      title: map['title'] as String,
      author: map['author'] as String,
      description: map['description'] as String,
      rating: map['rating'] as double,
      isRead: map['isRead'] == 1,
    );
  }
}