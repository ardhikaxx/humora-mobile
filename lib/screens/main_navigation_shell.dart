import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../core/services/permission_service.dart';
import '../core/services/vibration_service.dart';
import '../providers/connectivity_provider.dart';
import '../providers/series_provider.dart';
import '../providers/history_provider.dart';
import '../providers/notification_provider.dart';
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

      // Register auto-reload callback when network reconnects
      if (mounted) {
        context.read<ConnectivityProvider>().registerReconnectCallback(_handleNetworkReconnect);
      }
    });
  }

  void _handleNetworkReconnect() {
    if (!mounted) return;
    context.read<SeriesProvider>().fetchSeries();
    context.read<SeriesProvider>().fetchCategories();
    context.read<HistoryProvider>().fetchHistory();
    context.read<NotificationProvider>().fetchNotifications();
  }

  @override
  void dispose() {
    try {
      context.read<ConnectivityProvider>().unregisterReconnectCallback(_handleNetworkReconnect);
    } catch (_) {}
    super.dispose();
  }

  void _onTabSelected(int index) {
    VibrationService.lightImpact();
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final conn = context.watch<ConnectivityProvider>();

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

          // Real-time Network Status Banner (Offline Alert)
          if (conn.isOffline)
            Positioned(
              top: 8,
              left: 16,
              right: 16,
              child: SafeArea(
                bottom: false,
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFFECACA), width: 1.2),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x14000000),
                          blurRadius: 8,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.wifiOff, size: 16, color: Color(0xFFEF4444)),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Koneksi internet terputus. Mode offline aktif.',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF991B1B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => conn.manualRetry(),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Coba Lagi',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Real-time Network Status Banner (Reconnection Toast)
          if (conn.showReconnectedBanner)
            Positioned(
              top: 8,
              left: 16,
              right: 16,
              child: SafeArea(
                bottom: false,
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFA7F3D0), width: 1.2),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x14000000),
                          blurRadius: 8,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Row(
                      children: [
                        Icon(LucideIcons.wifi, size: 16, color: Color(0xFF10B981)),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Koneksi internet terhubung kembali!',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF065F46),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
