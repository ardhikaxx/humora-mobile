import 'package:delightful_toast/delight_toast.dart';
import 'package:delightful_toast/toast/components/toast_card.dart';
import 'package:delightful_toast/toast/utils/enums.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../core/theme/app_colors.dart';

/// Service untuk menampilkan notifikasi mengambang halus di sisi atas layar
/// menggunakan [delightful_toast] tanpa menutupi bilah navigasi bawah (bottom bar).
class HumoraToast {
  /// Flag untuk mematikan timer otomatis saat pengujian widget bila diperlukan
  static bool disableAutoDismissInTests = false;

  /// Menampilkan toast sukses dengan ikon centang hijau
  static void showSuccess(
    BuildContext context,
    String message, {
    String title = 'Berhasil',
    Duration duration = const Duration(milliseconds: 2800),
  }) {
    _show(
      context: context,
      title: title,
      subtitle: message,
      icon: LucideIcons.check,
      iconColor: AppColors.green,
      iconBgColor: AppColors.greenLight,
      duration: duration,
    );
  }

  /// Menampilkan toast informasi dengan aksen ungu khas HUMORA
  static void showInfo(
    BuildContext context,
    String message, {
    String title = 'Informasi',
    Duration duration = const Duration(milliseconds: 2800),
  }) {
    _show(
      context: context,
      title: title,
      subtitle: message,
      icon: LucideIcons.info,
      iconColor: AppColors.accentPurple,
      iconBgColor: AppColors.accentPurpleSoft,
      duration: duration,
    );
  }

  /// Menampilkan toast khusus Daftar Tonton (Watchlist)
  static void showWatchlist(
    BuildContext context, {
    required bool isAdded,
    String? seriesTitle,
    Duration duration = const Duration(milliseconds: 2800),
  }) {
    if (isAdded) {
      _show(
        context: context,
        title: 'Daftar Tonton',
        subtitle: seriesTitle != null
            ? '"$seriesTitle" berhasil ditambahkan ke Daftar Tonton.'
            : 'Serial berhasil ditambahkan ke Daftar Tonton.',
        icon: LucideIcons.bookmarkCheck,
        iconColor: AppColors.primaryYellowDark,
        iconBgColor: AppColors.yellowSoft,
        duration: duration,
      );
    } else {
      _show(
        context: context,
        title: 'Daftar Tonton',
        subtitle: seriesTitle != null
            ? '"$seriesTitle" dihapus dari Daftar Tonton.'
            : 'Serial dihapus dari Daftar Tonton.',
        icon: LucideIcons.bookmarkMinus,
        iconColor: AppColors.textSecondary,
        iconBgColor: AppColors.surfaceVariant,
        duration: duration,
      );
    }
  }

  /// Menampilkan toast khusus Suka (Like) pada serial atau episode
  static void showLike(
    BuildContext context, {
    required bool isLiked,
    String? targetTitle,
    bool isSeries = false,
    Duration duration = const Duration(milliseconds: 2800),
  }) {
    final String label = isSeries ? 'Serial' : 'Episode';
    if (isLiked) {
      _show(
        context: context,
        title: '$label Disukai',
        subtitle: targetTitle != null
            ? '"$targetTitle" disukai! Terima kasih apresiasinya.'
            : '$label disukai! Jumlah suka bertambah.',
        icon: LucideIcons.heart,
        iconColor: const Color(0xFFEF4444),
        iconBgColor: const Color(0xFFFEE2E2),
        duration: duration,
      );
    } else {
      _show(
        context: context,
        title: 'Batal Menyukai',
        subtitle: targetTitle != null
            ? 'Batal menyukai "$targetTitle".'
            : 'Batal menyukai $label.',
        icon: LucideIcons.heartCrack,
        iconColor: AppColors.textSecondary,
        iconBgColor: AppColors.surfaceVariant,
        duration: duration,
      );
    }
  }

  /// Menampilkan toast peringatan dengan ikon oranye
  static void showWarning(
    BuildContext context,
    String message, {
    String title = 'Peringatan',
    Duration duration = const Duration(milliseconds: 3200),
  }) {
    _show(
      context: context,
      title: title,
      subtitle: message,
      icon: LucideIcons.triangleAlert,
      iconColor: AppColors.orangeDark,
      iconBgColor: AppColors.orangeLight,
      duration: duration,
    );
  }

  /// Menampilkan toast error dengan ikon merah
  static void showError(
    BuildContext context,
    String message, {
    String title = 'Terjadi Kesalahan',
    Duration duration = const Duration(milliseconds: 3500),
  }) {
    _show(
      context: context,
      title: title,
      subtitle: message,
      icon: LucideIcons.circleAlert,
      iconColor: AppColors.red,
      iconBgColor: AppColors.redLight,
      duration: duration,
    );
  }

  /// Internal renderer menggunakan DelightToastBar di posisi atas
  static void _show({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required Duration duration,
  }) {
    if (!context.mounted) return;

    // Bersihkan toast sebelumnya agar tidak bertumpuk
    DelightToastBar.removeAll();

    DelightToastBar(
      position: DelightSnackbarPosition.top,
      autoDismiss: !disableAutoDismissInTests,
      snackbarDuration: duration,
      animationDuration: const Duration(milliseconds: 300),
      animationCurve: Curves.easeOutCubic,
      builder: (toastContext) => ToastCard(
        color: AppColors.surface,
        shadowColor: AppColors.primaryDark.withValues(alpha: 0.1),
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: iconBgColor,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 19,
            color: iconColor,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
            height: 1.35,
          ),
        ),
      ),
    ).show(context);
  }
}
