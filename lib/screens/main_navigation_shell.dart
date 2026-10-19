import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../data/models/user_model.dart';
import '../providers/auth_provider.dart';
import '../widgets/custom_bottom_nav_bar.dart';
import '../widgets/user_mode_switcher_sheet.dart';
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
  }

  void _onTabSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

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

          // Floating User Mode Quick Switcher Chip (Top-Right or Floating)
          Positioned(
            top: MediaQuery.of(context).padding.top + 60,
            right: 16,
            child: GestureDetector(
              onTap: () => UserModeSwitcherSheet.show(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.primaryDark.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x22000000),
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      auth.isGuest
                          ? LucideIcons.userX
                          : (auth.isFree
                              ? LucideIcons.userCheck
                              : (auth.isPremium ? LucideIcons.crown : LucideIcons.alertTriangle)),
                      size: 13,
                      color: auth.isPremium
                          ? AppColors.primaryYellow
                          : (auth.isExpired ? AppColors.orange : Colors.white),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _getTierBadgeText(auth.currentTier),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: auth.isPremium
                            ? AppColors.primaryYellow
                            : (auth.isExpired ? AppColors.orange : Colors.white),
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(LucideIcons.sliders, size: 10, color: Colors.white70),
                  ],
                ),
              ),
            ),
          ),

          // Floating Pill Bottom Navigation Bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: CustomBottomNavBar(
              currentIndex: _currentIndex,
              onTap: _onTabSelected,
            ),
          ),
        ],
      ),
    );
  }

  String _getTierBadgeText(UserTier tier) {
    switch (tier) {
      case UserTier.guest:
        return 'TAMU';
      case UserTier.free:
        return 'GRATIS';
      case UserTier.premium:
        return 'PREMIUM';
      case UserTier.expired:
        return 'EXPIRED';
    }
  }
}
