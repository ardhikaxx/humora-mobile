import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/subscription_plan_model.dart';
import '../../data/models/transaction_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../widgets/custom_pill_app_bar.dart';
import '../main_navigation_shell.dart';

class PaymentStatusScreen extends StatefulWidget {
  final TransactionModel transaction;
  final SubscriptionPlanModel? plan;

  const PaymentStatusScreen({
    super.key,
    required this.transaction,
    this.plan,
  });

  @override
  State<PaymentStatusScreen> createState() => _PaymentStatusScreenState();
}

class _PaymentStatusScreenState extends State<PaymentStatusScreen> {
  late TransactionModel _currentTrx;
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    _currentTrx = widget.transaction;
    _checkStatusSilently();
  }

  Future<void> _checkStatusSilently() async {
    final updated = await context.read<TransactionProvider>().checkTransactionStatus(_currentTrx.id);
    if (updated != null && mounted) {
      setState(() {
        _currentTrx = updated;
      });
      if (updated.isSuccess) {
        context.read<AuthProvider>().refreshUser();
      }
    }
  }

  Future<void> _handleManualCheck() async {
    setState(() => _isChecking = true);
    final updated = await context.read<TransactionProvider>().checkTransactionStatus(_currentTrx.id);
    setState(() => _isChecking = false);

    if (!mounted) return;

    if (updated != null) {
      setState(() {
        _currentTrx = updated;
      });

      if (updated.isSuccess) {
        context.read<AuthProvider>().refreshUser();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Selamat! Pembayaran Anda telah disetujui admin dan VIP sudah aktif!'),
            backgroundColor: AppColors.green,
          ),
        );
      } else if (updated.isRejected) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Pembayaran ditolak: ${updated.rejectReason ?? "Bukti tidak valid"}'),
            backgroundColor: AppColors.red,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Status masih menunggu verifikasi admin keuangan.'),
            backgroundColor: Color(0xFFD97706),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            CustomPillAppBar(
              title: 'Status Pembayaran',
              showBackButton: true,
              onBackTap: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const MainNavigationShell()),
                  (route) => false,
                );
              },
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  children: [
                    const SizedBox(height: 10),

                    // Icon Status Header
                    _buildStatusIcon(),

                    const SizedBox(height: 18),

                    // Status Badge
                    _buildStatusBadge(),

                    const SizedBox(height: 12),

                    // Title and subtitle
                    Text(
                      _getTitleText(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _getSubtitleText(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Transaction Details Card
                    _buildDetailsCard(),

                    const SizedBox(height: 20),

                    // Verification timeline
                    _buildTimelineCard(),

                    const SizedBox(height: 24),

                    // Action Button
                    _buildActionButton(),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIcon() {
    if (_currentTrx.isSuccess) {
      return Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: const Color(0xFFE2F7ED),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.green.withValues(alpha: 0.2),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Center(
          child: Icon(LucideIcons.checkCheck, color: AppColors.green, size: 40),
        ),
      );
    } else if (_currentTrx.isRejected) {
      return Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: const Color(0xFFFEE2E2),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.red.withValues(alpha: 0.2),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Center(
          child: Icon(LucideIcons.x, color: AppColors.red, size: 40),
        ),
      );
    } else {
      return Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: const Color(0xFFFEF3C7),
          shape: BoxShape.circle,
          boxShadow: const [
            BoxShadow(
              color: Color(0x20D97706),
              blurRadius: 16,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: const Center(
          child: Icon(LucideIcons.clock, color: Color(0xFFD97706), size: 40),
        ),
      );
    }
  }

  Widget _buildStatusBadge() {
    Color bg;
    Color text;
    String label;

    if (_currentTrx.isSuccess) {
      bg = const Color(0xFFE2F7ED);
      text = AppColors.green;
      label = 'PEMBAYARAN TERVERIFIKASI';
    } else if (_currentTrx.isRejected) {
      bg = const Color(0xFFFEE2E2);
      text = AppColors.red;
      label = 'PEMBAYARAN DITOLAK';
    } else {
      bg = const Color(0xFFFEF3C7);
      text = const Color(0xFFB45309);
      label = 'MENUNGGU VERIFIKASI ADMIN';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: text,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  String _getTitleText() {
    if (_currentTrx.isSuccess) {
      return 'Akses VIP Berhasil Diaktifkan!';
    } else if (_currentTrx.isRejected) {
      return 'Bukti Pembayaran Ditolak';
    }
    return 'Bukti Pembayaran Telah Diterima';
  }

  String _getSubtitleText() {
    if (_currentTrx.isSuccess) {
      return 'Selamat! Anda sekarang dapat menonton seluruh episode VIP Humora tanpa batas.';
    } else if (_currentTrx.isRejected) {
      return _currentTrx.rejectReason ??
          'Bukti transfer tidak dapat diverifikasi oleh admin. Silakan periksa kembali nominal dan bukti yang diunggah.';
    }
    return 'Tim verifikasi kami sedang memeriksa bukti pembayaran Anda. VIP akan aktif otomatis segera setelah diverifikasi.';
  }

  Widget _buildDetailsCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 1.2),
      ),
      child: Column(
        children: [
          _buildRow('Kode Transaksi', _currentTrx.trxCode, isCopyable: true),
          const Divider(height: 20, color: AppColors.border),
          _buildRow('Paket VIP', _currentTrx.planName),
          const Divider(height: 20, color: AppColors.border),
          _buildRow('Metode Pembayaran', _currentTrx.paymentMethodLabel),
          const Divider(height: 20, color: AppColors.border),
          _buildRow('Total Transfer', _currentTrx.formattedAmount, isBold: true),
          if (_currentTrx.rejectReason != null && _currentTrx.rejectReason!.isNotEmpty) ...[
            const Divider(height: 20, color: AppColors.border),
            _buildRow('Alasan Penolakan', _currentTrx.rejectReason!, textColor: AppColors.red),
          ],
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value, {bool isBold = false, bool isCopyable = false, Color? textColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        Row(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: isBold ? FontWeight.w800 : FontWeight.w700,
                color: textColor ?? AppColors.textPrimary,
              ),
            ),
            if (isCopyable) ...[
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: value));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Kode transaksi disalin ke papan klip.'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                child: const Icon(LucideIcons.copy, size: 14, color: AppColors.accentPurple),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildTimelineCard() {
    final isDone = _currentTrx.isSuccess;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TAHAPAN TRANSAKSI',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppColors.textMuted,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          _buildTimelineStep(
            title: '1. Pemesanan Paket',
            subtitle: 'Paket langganan dipilih',
            isComplete: true,
          ),
          _buildTimelineStep(
            title: '2. Unggah Bukti Transfer',
            subtitle: _currentTrx.proofUploaded ? 'Bukti foto berhasil dikirim' : 'Menunggu upload bukti',
            isComplete: _currentTrx.proofUploaded,
          ),
          _buildTimelineStep(
            title: '3. Verifikasi oleh Admin',
            subtitle: isDone
                ? 'Selesai diverifikasi'
                : (_currentTrx.isRejected ? 'Ditolak admin' : 'Sedang diproses admin portal'),
            isComplete: isDone,
            isCurrent: !_currentTrx.isSuccess && !_currentTrx.isRejected,
            isError: _currentTrx.isRejected,
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineStep({
    required String title,
    required String subtitle,
    required bool isComplete,
    bool isCurrent = false,
    bool isError = false,
  }) {
    Color iconColor;
    IconData icon;

    if (isError) {
      iconColor = AppColors.red;
      icon = LucideIcons.x;
    } else if (isComplete) {
      iconColor = AppColors.green;
      icon = LucideIcons.check;
    } else if (isCurrent) {
      iconColor = const Color(0xFFD97706);
      icon = LucideIcons.loader;
    } else {
      iconColor = AppColors.textMuted;
      icon = LucideIcons.circle;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: isError ? AppColors.red : AppColors.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    if (_currentTrx.isSuccess) {
      return SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: () {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const MainNavigationShell()),
              (route) => false,
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryDark,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: const Text(
            'Mulai Nonton Video VIP',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _isChecking ? null : _handleManualCheck,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryYellow,
              foregroundColor: AppColors.primaryDark,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: _isChecking
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.primaryDark),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.refreshCw, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Cek Status Verifikasi',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton(
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const MainNavigationShell()),
                (route) => false,
              );
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.border, width: 1.2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text(
              'Kembali ke Beranda',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
          ),
        ),
      ],
    );
  }
}
