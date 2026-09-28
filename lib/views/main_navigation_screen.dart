import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_theme.dart';
import 'home/home_screen.dart';
import 'search/advanced_search_screen.dart';
import 'library/library_screen.dart';
import 'settings/settings_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    HomeScreen(),
    AdvancedSearchScreen(),
    LibraryScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          border: Border(
            top: BorderSide(
              color: Colors.white.withOpacity(0.06),
              width: 1,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          backgroundColor: AppTheme.surfaceColor,
          selectedItemColor: AppTheme.primaryColor,
          unselectedItemColor: AppTheme.textSecondary,
          selectedLabelStyle: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 11,
          ),
          unselectedLabelStyle: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w500,
            fontSize: 11,
          ),
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.explore_outlined),
              activeIcon: Icon(Icons.explore_rounded),
              label: 'Katalog',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.search_outlined),
              activeIcon: Icon(Icons.search_rounded),
              label: 'Cari & Filter',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bookmarks_outlined),
              activeIcon: Icon(Icons.bookmarks_rounded),
              label: 'Koleksi',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings_rounded),
              label: 'Pengaturan',
            ),
          ],
        ),
      ),
    );
  }
}
