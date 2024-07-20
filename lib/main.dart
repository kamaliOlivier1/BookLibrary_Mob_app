import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'helpers/database_helper.dart';
import 'providers/preferences_provider.dart';
import 'screens/book_list_screen.dart' as list_screen;
import 'screens/add_edit_book_screen.dart';
import 'screens/book_detail_screen.dart' as detail_screen;
import 'screens/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final databaseHelper = DatabaseHelper();
  await databaseHelper.database; // Initialize the database
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => PreferencesProvider(),
      child: Consumer<PreferencesProvider>(
        builder: (ctx, prefs, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Book App',
            theme: ThemeData.light().copyWith(
              primaryColor: Colors.teal,
              appBarTheme: AppBarTheme(backgroundColor: Colors.teal),
            ),
            darkTheme: ThemeData.dark().copyWith(
              primaryColor: Colors.tealAccent,
              appBarTheme: AppBarTheme(backgroundColor: Colors.tealAccent),
            ),
            themeMode: prefs.themeMode,
            home: list_screen.BookListScreen(),
            routes: {
              '/book-list': (ctx) => list_screen.BookListScreen(),
              AddEditBookScreen.routeName: (ctx) => AddEditBookScreen(),
              detail_screen.BookDetailScreen.routeName: (ctx) => detail_screen.BookDetailScreen(),
              SettingsScreen.routeName: (ctx) => SettingsScreen(),
            },
          );
        },
      ),
    );
  }
}