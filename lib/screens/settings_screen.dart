import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../providers/preferences_provider.dart';

class SettingsScreen extends StatefulWidget {
  static const routeName = '/settings';

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        systemOverlayStyle: isDarkMode ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        elevation: 0,
        title: Text(
          'Settings',
          style: GoogleFonts.poppins(
            textStyle: TextStyle(color: Theme.of(context).appBarTheme.titleTextStyle?.color),
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).iconTheme.color),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: AnimationLimiter(
          child: Consumer<PreferencesProvider>(
            builder: (ctx, prefs, _) {
              return ListView(
                padding: EdgeInsets.all(16),
                children: AnimationConfiguration.toStaggeredList(
                  duration: const Duration(milliseconds: 375),
                  childAnimationBuilder: (widget) => SlideAnimation(
                    verticalOffset: 50.0,
                    child: FadeInAnimation(
                      child: widget,
                    ),
                  ),
                  children: [
                    _buildSettingsCard(
                      title: 'Display',
                      children: [
                        _buildSettingsTile(
                          title: 'Dark Mode',
                          trailing: _buildCustomSwitch(
                            value: prefs.themeMode == ThemeMode.dark,
                            onChanged: (bool value) {
                              prefs.updateThemeMode(value ? ThemeMode.dark : ThemeMode.light);
                            },
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    _buildSettingsCard(
                      title: 'Sort Order',
                      children: [
                        _buildSortOrderTile('Title', 'title', prefs),
                        _buildSortOrderTile('Author', 'author', prefs),
                        _buildSortOrderTile('Rating', 'rating', prefs),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsCard({required String title, required List<Widget> children}) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.poppins(
                textStyle: Theme.of(context).textTheme.titleLarge,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTile({required String title, required Widget trailing}) {
    return ListTile(
      title: Text(
        title,
        style: GoogleFonts.poppins(
          textStyle: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
        ),
      ),
      trailing: trailing,
    );
  }

  Widget _buildSortOrderTile(String title, String value, PreferencesProvider prefs) {
    return RadioListTile<String>(
      title: Text(
        title,
        style: GoogleFonts.poppins(
          textStyle: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
        ),
      ),
      value: value,
      groupValue: prefs.sortOrder,
      onChanged: (String? newValue) {
        if (newValue != null) {
          prefs.updateSortOrder(newValue);
        }
      },
      activeColor: Theme.of(context).colorScheme.secondary,
    );
  }

  Widget _buildCustomSwitch({required bool value, required ValueChanged<bool> onChanged}) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        height: 30,
        width: 50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: value ? Theme.of(context).colorScheme.secondary : Colors.grey,
        ),
        child: AnimatedAlign(
          duration: Duration(milliseconds: 300),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 2),
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}