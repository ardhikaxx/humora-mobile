import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../core/services/local_notification_service.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/custom_pill_app_bar.dart';
import '../../widgets/humora_empty_state.dart';
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
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () => _showNotificationTestSheet(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3E8FF),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.primaryPurple, width: 1),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(LucideIcons.bellRing, size: 13, color: AppColors.primaryDark),
                          SizedBox(width: 4),
                          Text(
                            'Tes Push',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
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
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.checkCheck, size: 14, color: AppColors.accentPurple),
                        SizedBox(width: 3),
                        Text(
                          'Dibaca',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.accentPurple,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
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
                  ? HumoraEmptyState(
                      icon: _filterIndex == 1 ? LucideIcons.bellRing : LucideIcons.bellOff,
                      title: _filterIndex == 1
                          ? 'Tidak Ada Notifikasi Baru'
                          : 'Kotak Notifikasi Bersih',
                      subtitle: _filterIndex == 1
                          ? 'Seluruh pesan dan pemberitahuan penting telah kamu baca.'
                          : 'Belum ada pemberitahuan atau informasi baru untuk akunmu saat ini.',
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

  void _showNotificationTestSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryPurple.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(LucideIcons.bellRing, color: AppColors.primaryDark, size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Simulasi Push Notifikasi',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'flutter_local_notifications ^22.3.2',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.accentPurple,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    icon: const Icon(LucideIcons.x, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(LucideIcons.info, size: 16, color: Color(0xFF3B82F6)),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Pilih jenis notifikasi di bawah. Notifikasi akan langsung muncul di heads-up banner atas layar dan tersimpan di tray perangkat (berjalan di foreground & background/sleep).',
                        style: TextStyle(fontSize: 11.5, color: Color(0xFF475569), height: 1.35),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 1. VIP Disetujui
              _buildTestItem(
                ctx: ctx,
                title: 'Verifikasi Premium Disetujui Admin',
                subtitle: 'Pop-up & nada notifikasi saat pembayaran VIP disetujui.',
                icon: LucideIcons.badgeCheck,
                color: const Color(0xFF7C3AED),
                onTap: () async {
                  await LocalNotificationService.showVipApprovedNotification(
                    trxCode: 'TRX-HUMORA-VIP99',
                    planName: 'VIP 3 Bulan',
                  );
                  _showTriggerSuccess('Notifikasi VIP Disetujui berhasil dikirim!');
                },
              ),
              const SizedBox(height: 10),

              // 2. Video Baru
              _buildTestItem(
                ctx: ctx,
                title: 'Video / Episode Baru Dirilis',
                subtitle: 'Notifikasi rilis episode terbaru serial komedi.',
                icon: LucideIcons.clapperboard,
                color: const Color(0xFF2563EB),
                onTap: () async {
                  await LocalNotificationService.showNewVideoNotification(
                    title: 'Kost 99',
                    episodeName: 'Episode 4 - Tetangga Baru',
                  );
                  _showTriggerSuccess('Notifikasi Video Baru berhasil dikirim!');
                },
              ),
              const SizedBox(height: 10),

              // 3. Video Populer
              _buildTestItem(
                ctx: ctx,
                title: 'Video Populer / Trending',
                subtitle: 'Notifikasi tayangan terpopuler minggu ini.',
                icon: LucideIcons.flame,
                color: const Color(0xFFEA580C),
                onTap: () async {
                  await LocalNotificationService.showPopularVideoNotification(
                    title: 'Warkop Milenial',
                    totalLikes: '12.4K',
                  );
                  _showTriggerSuccess('Notifikasi Video Populer berhasil dikirim!');
                },
              ),
              const SizedBox(height: 10),

              // 4. Ajakan Berlangganan
              _buildTestItem(
                ctx: ctx,
                title: 'Ajakan Berlangganan (Upgrade VIP)',
                subtitle: 'Promo langganan hemat untuk buka semua episode tanpa jeda.',
                icon: LucideIcons.sparkles,
                color: const Color(0xFFCA8A04),
                onTap: () async {
                  await LocalNotificationService.showSubscriptionInviteNotification();
                  _showTriggerSuccess('Notifikasi Ajakan Berlangganan berhasil dikirim!');
                },
              ),
              const SizedBox(height: 10),

              // 5. Langganan Mau Habis
              _buildTestItem(
                ctx: ctx,
                title: 'Masa Langganan Segera Habis',
                subtitle: 'Peringatan sisa masa aktif VIP tersisa 3 hari lagi.',
                icon: LucideIcons.clockAlert,
                color: const Color(0xFFDC2626),
                onTap: () async {
                  await LocalNotificationService.showExpiringSubscriptionNotification(
                    remainingDays: 3,
                  );
                  _showTriggerSuccess('Notifikasi Masa VIP Berakhir berhasil dikirim!');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTriggerSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(LucideIcons.checkCircle2, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.primaryDark,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Widget _buildTestItem({
    required BuildContext ctx,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Future<void> Function() onTap,
  }) {
    return InkWell(
      onTap: () async {
        Navigator.of(ctx).pop();
        await onTap();
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border, width: 1.1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            const Icon(LucideIcons.send, size: 16, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

