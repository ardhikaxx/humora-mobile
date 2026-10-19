import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/custom_pill_app_bar.dart';
import '../subscription/subscription_plans_screen.dart';
import '../video/video_player_screen.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  int _filterIndex = 0; // 0 for Semua, 1 for Belum Dibaca

  @override
  Widget build(BuildContext context) {
    final notifProv = context.watch<NotificationProvider>();
    final allList = notifProv.allNotifications;
    final unreadList = notifProv.unreadNotifications;
    final displayList = _filterIndex == 0 ? allList : unreadList;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            CustomPillAppBar(
              title: 'Notifikasi',
              onBackTap: () => Navigator.of(context).pop(),
              trailing: GestureDetector(
                onTap: () {
                  notifProv.markAllAsRead();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Semua notifikasi telah ditandai dibaca.'),
                      backgroundColor: AppColors.primaryDark,
                    ),
                  );
                },
                child: const Row(
                  children: [
                    Icon(LucideIcons.checkCheck, size: 15, color: AppColors.accentPurple),
                    SizedBox(width: 4),
                    Text(
                      'Tandai dibaca',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accentPurple,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Filter Pills
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _buildFilterChip(
                    index: 0,
                    label: 'Semua (${allList.length})',
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    index: 1,
                    label: 'Belum Dibaca (${unreadList.length})',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Notification Items List
            Expanded(
              child: displayList.isEmpty
                  ? const Center(
                      child: Text(
                        'Tidak ada notifikasi',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 30),
                      itemCount: displayList.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final notif = displayList[index];
                        return _buildNotificationCard(context, notif, notifProv);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({required int index, required String label}) {
    final isSelected = _filterIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _filterIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryDark : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primaryDark : AppColors.border,
            width: 1.2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationCard(
    BuildContext context,
    dynamic notif,
    NotificationProvider notifProv,
  ) {
    final isUnread = !notif.isRead;

    return GestureDetector(
      onTap: () {
        notifProv.markAsRead(notif.id);

        if (notif.iconType == 'tag') {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const SubscriptionPlansScreen()),
          );
        } else if (notif.thumbnailPath != null) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const VideoPlayerScreen(
                seriesId: 'cara-deketin-cewek',
                initialEpisodeNumber: 1,
              ),
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isUnread ? AppColors.accentPurple : AppColors.border,
            width: isUnread ? 1.5 : 1.2,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x06000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Graphic: Thumbnail or Icon
            Stack(
              clipBehavior: Clip.none,
              children: [
                if (notif.thumbnailPath != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: 48,
                      height: 48,
                      child: Image.asset(
                        notif.thumbnailPath!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(color: AppColors.primaryPurple),
                      ),
                    ),
                  )
                else
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3E8FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      notif.iconType == 'tag'
                          ? LucideIcons.tag
                          : (notif.iconType == 'card' ? LucideIcons.creditCard : LucideIcons.bell),
                      color: AppColors.accentPurple,
                      size: 22,
                    ),
                  ),

                // Red dot badge if unread
                if (isUnread)
                  Positioned(
                    top: -3,
                    right: -3,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF4444),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),

            // Text Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          notif.title,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        notif.timeAgo,
                        style: const TextStyle(
                          fontSize: 10.5,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notif.message,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.textSecondary,
                      height: 1.35,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
