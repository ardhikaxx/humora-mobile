import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/subscription_plan_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../widgets/custom_pill_app_bar.dart';
import '../../widgets/humora_image.dart';
import '../auth/login_screen.dart';
import 'payment_status_screen.dart';

class CheckoutScreen extends StatefulWidget {
  final SubscriptionPlanModel plan;

  const CheckoutScreen({super.key, required this.plan});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String _selectedMethod = 'bca'; // 'bca', 'mandiri', 'qris'
  File? _pickedProofFile;
  final ImagePicker _picker = ImagePicker();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SubscriptionProvider>().fetchPaymentInfo();
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1600,
      );

      if (picked != null) {
        setState(() {
          _pickedProofFile = File(picked.path);
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengambil gambar: $e'),
          backgroundColor: AppColors.red,
        ),
      );
    }
  }

  void _showImageSourcePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Pilih Sumber Foto Bukti Pembayaran',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(LucideIcons.image, color: AppColors.primaryPurple),
                title: const Text('Galeri Foto', style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(LucideIcons.camera, color: AppColors.primaryPurple),
                title: const Text('Kamera Langsung', style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handlePaymentSubmission() async {
    final auth = context.read<AuthProvider>();

    // Guard: Must be authenticated
    if (auth.isGuest) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Silakan masuk atau daftar akun terlebih dahulu untuk berlangganan.'),
          backgroundColor: AppColors.primaryDark,
          action: SnackBarAction(
            label: 'Masuk',
            textColor: AppColors.primaryYellow,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
          ),
        ),
      );
      return;
    }

    if (_pickedProofFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Wajib memilih dan melampirkan foto bukti pembayaran sebelum mengirim.'),
          backgroundColor: Color(0xFFD97706),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final planId = int.tryParse(widget.plan.id) ?? 1;

      final trx = await context.read<TransactionProvider>().uploadPaymentProof(
        planId: planId,
        paymentMethod: _selectedMethod,
        proofFile: _pickedProofFile!,
      );

      if (!mounted) return;

      if (trx != null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => PaymentStatusScreen(
              transaction: trx,
              plan: widget.plan,
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pengiriman bukti gagal: ${e.toString()}'),
          backgroundColor: AppColors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final subProv = context.watch<SubscriptionProvider>();
    final paymentInfo = subProv.paymentInfo;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            CustomPillAppBar(
              title: 'Checkout Pembayaran',
              onBackTap: () => Navigator.of(context).pop(),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),

                    // User Account Card
                    _buildAccountCard(auth),
                    const SizedBox(height: 14),

                    // Selected Plan Summary
                    _buildPlanSummaryCard(),
                    const SizedBox(height: 20),

                    // Payment Method Selector
                    const Text(
                      'Pilih Rekening Transfer Tujuan',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),

                    _buildMethodSelector(),

                    const SizedBox(height: 16),

                    // Bank Account / QRIS Details Card
                    _buildPaymentDetailsCard(paymentInfo),

                    const SizedBox(height: 20),

                    // Upload Proof of Payment Box
                    _buildProofUploadSection(),

                    const SizedBox(height: 20),

                    // Summary Card
                    _buildSummaryCard(),

                    const SizedBox(height: 24),

                    // Submit Button
                    _buildSubmitButton(),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountCard(AuthProvider auth) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'AKUN PEMESAN',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              color: AppColors.textMuted,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            auth.user.name,
            style: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            auth.user.email.isNotEmpty ? auth.user.email : (auth.user.phone.isNotEmpty ? auth.user.phone : 'Belum masuk akun'),
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanSummaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.accentPurpleSoft.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.accentPurpleBorder, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Paket Langganan',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accentPurple,
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: const Text(
                  'Ubah Paket',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.accentPurple,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            widget.plan.name,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Durasi ${widget.plan.durationText} • Bebas nonton seluruh video VIP',
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildMethodSelector() {
    return Row(
      children: [
        _buildMethodButton(
          code: 'bca',
          label: 'BCA Transfer',
          icon: LucideIcons.building,
        ),
        const SizedBox(width: 8),
        _buildMethodButton(
          code: 'mandiri',
          label: 'Mandiri Transfer',
          icon: LucideIcons.building2,
        ),
        const SizedBox(width: 8),
        _buildMethodButton(
          code: 'qris',
          label: 'QRIS Resmi',
          icon: LucideIcons.qrCode,
        ),
      ],
    );
  }

  Widget _buildMethodButton({
    required String code,
    required String label,
    required IconData icon,
  }) {
    final isSelected = _selectedMethod == code;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedMethod = code),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryPurple : AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? AppColors.primaryPurple : AppColors.border,
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? AppColors.primaryYellow : AppColors.textSecondary,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentDetailsCard(dynamic paymentInfo) {
    if (_selectedMethod == 'qris') {
      final qrisUrl = paymentInfo?.qris?.qrisImageUrl;

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border, width: 1.2),
        ),
        child: Column(
          children: [
            const Text(
              'SCAN QRIS HUMORA RESMI',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.textMuted,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: qrisUrl != null
                  ? HumoraImage(
                      imagePathOrUrl: qrisUrl,
                      fit: BoxFit.contain,
                    )
                  : const Center(
                      child: Icon(
                        LucideIcons.qrCode,
                        size: 90,
                        color: AppColors.primaryPurple,
                      ),
                    ),
            ),
            const SizedBox(height: 10),
            const Text(
              'a.n. PT HUMORA MEDIA KREATIF',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Dapat dipindai dari m-BCA, Livin by Mandiri, GoPay, OVO, ShopeePay, DANA.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    // Bank Account details
    String bankName = _selectedMethod == 'bca' ? 'Bank Central Asia (BCA)' : 'Bank Mandiri';
    String accNumber = _selectedMethod == 'bca' ? '8830-192-888' : '137-00-998822-1';
    String accName = _selectedMethod == 'bca' ? 'PT HUMORA MEDIA KREATIF' : 'HUMORA';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            bankName.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppColors.textMuted,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                accNumber,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryPurple,
                  letterSpacing: 1.0,
                ),
              ),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: accNumber.replaceAll('-', '')));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Nomor rekening disalin ke papan klip!'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.accentPurpleSoft,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.copy, size: 14, color: AppColors.accentPurple),
                      SizedBox(width: 4),
                      Text(
                        'Salin',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.accentPurple,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Atas Nama: $accName',
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildProofUploadSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _pickedProofFile != null ? AppColors.green : AppColors.border,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'BUKTI PEMBAYARAN',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textMuted,
                  letterSpacing: 0.5,
                ),
              ),
              if (_pickedProofFile != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2F7ED),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Siap Diunggah',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppColors.green,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          if (_pickedProofFile != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: double.infinity,
                height: 180,
                child: Image.file(
                  _pickedProofFile!,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _pickedProofFile!.path.split(Platform.pathSeparator).last,
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton(
                  onPressed: _showImageSourcePicker,
                  child: const Text('Ganti Foto', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ] else ...[
            GestureDetector(
              onTap: _showImageSourcePicker,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.border,
                    style: BorderStyle.solid,
                  ),
                ),
                child: const Column(
                  children: [
                    Icon(
                      LucideIcons.uploadCloud,
                      size: 36,
                      color: AppColors.accentPurple,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Ketuk untuk Mengunggah Bukti Transfer',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Format JPG, JPEG, atau PNG (Maks. 5 MB)',
                      style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border, width: 1.2),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Harga Paket', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              Text(
                widget.plan.formattedPrice.isNotEmpty ? widget.plan.formattedPrice : 'Rp ${widget.plan.price}',
                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Biaya Admin & Pajak', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              Text(
                'Rp0 (Gratis)',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.green),
              ),
            ],
          ),
          const Divider(height: 20, color: AppColors.border),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Pembayaran', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
              Text(
                widget.plan.formattedPrice.isNotEmpty ? widget.plan.formattedPrice : 'Rp ${widget.plan.price}',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primaryPurple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _handlePaymentSubmission,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryDark,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: _isSubmitting
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.send, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Kirim Bukti Pembayaran',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
      ),
    );
  }
}
