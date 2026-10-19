import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/services/permission_service.dart';
import '../widgets/custom_bottom_nav_bar.dart';
import 'home/home_screen.dart';
import 'search/search_screen.dart';
import 'history/history_screen.dart';
import 'profile/profile_screen.dart';

class MainNavigationShell extends StatefulWidget {
  final int initialIndex;

  const MainNavigationShell({super.key, this.initialIndex = 0});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      PermissionService.checkAndRequestInitialPermissions();
    });
  }

  void _onTabSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(onNavigateTab: _onTabSelected),
      const SearchScreen(),
      const HistoryScreen(),
      ProfileScreen(onNavigateTab: _onTabSelected),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Indexed Stack to preserve scroll positions across tabs
          IndexedStack(
            index: _currentIndex,
            children: screens,
          ),

          // Floating Pill Bottom Navigation Bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: CustomBottomNavBar(
                currentIndex: _currentIndex,
                onTap: _onTabSelected,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
