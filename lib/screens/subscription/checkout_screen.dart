import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../core/network/api_config.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/payment_info_model.dart';
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
                MaterialPageRoute(
                  builder: (_) => LoginScreen(
                    redirectToCheckoutPlan: widget.plan,
                  ),
                ),
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

                    _buildMethodSelector(paymentInfo),

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

  Widget _buildMethodSelector(dynamic paymentInfo) {
    final List<Widget> buttons = [];
    final banks = paymentInfo?.bankAccounts ?? <BankAccountModel>[];

    // If no method selected yet, or current method not in banks and not qris, select first
    if (_selectedMethod != 'qris' && !banks.any((b) => b.code == _selectedMethod)) {
      if (banks.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _selectedMethod != banks.first.code) {
            setState(() => _selectedMethod = banks.first.code);
          }
        });
      }
    }

    if (banks.isNotEmpty) {
      for (final bank in banks) {
        buttons.add(
          _buildMethodButton(
            code: bank.code,
            label: _formatBankLabel(bank.bankName),
            logoUrl: bank.bankLogoUrl,
          ),
        );
      }
    } else {
      final baseHost = ApiConfig.baseUrl.replaceFirst('/api/v1', '');
      buttons.add(
        _buildMethodButton(
          code: 'bca',
          label: 'BCA Transfer',
          logoUrl: '$baseHost/images/banks/bca.png',
        ),
      );
      buttons.add(
        _buildMethodButton(
          code: 'mandiri',
          label: 'Mandiri Transfer',
          logoUrl: '$baseHost/images/banks/mandiri.png',
        ),
      );
    }

    // QRIS is always available ("untuk qris tetap")
    buttons.add(
      _buildMethodButton(
        code: 'qris',
        label: 'QRIS Resmi',
      ),
    );

    if (buttons.length <= 3) {
      return Row(
        children: buttons.asMap().entries.map((entry) {
          final isLast = entry.key == buttons.length - 1;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: isLast ? 0 : 8),
              child: entry.value,
            ),
          );
        }).toList(),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: buttons.asMap().entries.map((entry) {
          final isLast = entry.key == buttons.length - 1;
          return Padding(
            padding: EdgeInsets.only(right: isLast ? 0 : 8),
            child: SizedBox(
              width: 114,
              child: entry.value,
            ),
          );
        }).toList(),
      ),
    );
  }

  String _formatBankLabel(String rawName) {
    final match = RegExp(r'\(([^)]+)\)').firstMatch(rawName);
    if (match != null) {
      return '${match.group(1)} Transfer';
    }
    if (rawName.toLowerCase().startsWith('bank ')) {
      return '${rawName.substring(5).trim()} Transfer';
    }
    return '$rawName Transfer';
  }

  Widget _buildBankLogoWidget({
    String? logoUrl,
    String? bankCode,
    double height = 20,
    double? width,
  }) {
    String resolvedUrl = (logoUrl ?? '').trim();

    // If logoUrl is not provided or empty, but bankCode is given, construct from backend API
    if (resolvedUrl.isEmpty && bankCode != null && bankCode.isNotEmpty && bankCode != 'qris') {
      final baseHost = ApiConfig.baseUrl.replaceFirst('/api/v1', '');
      resolvedUrl = '$baseHost/images/banks/${bankCode.toLowerCase()}.png';
    }

    if (resolvedUrl.isNotEmpty) {
      // Handle relative paths
      if (resolvedUrl.startsWith('/')) {
        final uri = Uri.tryParse(ApiConfig.baseUrl);
        if (uri != null) {
          resolvedUrl = '${uri.scheme}://${uri.authority}$resolvedUrl';
        }
      } else {
        // Adapt host and port to active ApiConfig.baseUrl so localhost/LAN/emulator always resolve
        final baseUri = Uri.tryParse(ApiConfig.baseUrl);
        final imgUri = Uri.tryParse(resolvedUrl);
        if (baseUri != null && imgUri != null && imgUri.hasScheme && imgUri.hasAuthority) {
          if (imgUri.authority != baseUri.authority) {
            resolvedUrl = imgUri.replace(
              scheme: baseUri.scheme,
              host: baseUri.host,
              port: baseUri.hasPort ? baseUri.port : null,
            ).toString();
          }
        }
      }

      return CachedNetworkImage(
        imageUrl: resolvedUrl,
        height: height,
        width: width,
        fit: BoxFit.contain,
        placeholder: (context, url) => SizedBox(
          height: height,
          width: width ?? (height * 1.8),
          child: Center(
            child: Text(
              (bankCode ?? 'BANK').toUpperCase(),
              style: TextStyle(
                fontSize: height * 0.45,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryPurple.withValues(alpha: 0.6),
              ),
            ),
          ),
        ),
        errorWidget: (context, url, error) => Center(
          child: Text(
            (bankCode ?? 'BANK').toUpperCase(),
            style: TextStyle(
              fontSize: height * 0.45,
              fontWeight: FontWeight.w800,
              color: AppColors.primaryPurple,
            ),
          ),
        ),
      );
    }

    return Center(
      child: Text(
        (bankCode ?? 'BANK').toUpperCase(),
        style: TextStyle(
          fontSize: height * 0.45,
          fontWeight: FontWeight.w800,
          color: AppColors.primaryPurple,
        ),
      ),
    );
  }

  Widget _buildMethodButton({
    required String code,
    required String label,
    String? logoUrl,
  }) {
    final isSelected = _selectedMethod == code;
    final isQris = code == 'qris';

    return GestureDetector(
      onTap: () => setState(() => _selectedMethod = code),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryPurple : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primaryPurple : AppColors.border,
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primaryPurple.withValues(alpha: 0.22),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 28,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(7),
                border: Border.all(
                  color: isSelected ? Colors.white.withValues(alpha: 0.8) : AppColors.border,
                  width: 0.8,
                ),
              ),
              child: Center(
                child: isQris
                    ? const Icon(
                        LucideIcons.qrCode,
                        size: 18,
                        color: AppColors.primaryPurple,
                      )
                    : _buildBankLogoWidget(
                        logoUrl: logoUrl,
                        bankCode: code,
                        height: 20,
                      ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ],
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
            Text(
              'a.n. ${paymentInfo?.qris?.accountName ?? "PT HUMORA MEDIA KREATIF"}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              paymentInfo?.qris?.instructions ?? 'Dapat dipindai dari m-BCA, Livin by Mandiri, GoPay, OVO, ShopeePay, DANA.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    // Dynamic Bank Account details
    final banks = paymentInfo?.bankAccounts ?? <BankAccountModel>[];
    BankAccountModel? selectedBank;
    if (banks.isNotEmpty) {
      for (final b in banks) {
        if (b.code == _selectedMethod) {
          selectedBank = b;
          break;
        }
      }
      selectedBank ??= banks.first;
    }

    final String bankName = selectedBank?.bankName ?? (_selectedMethod == 'mandiri' ? 'Bank Mandiri' : 'Bank Central Asia (BCA)');
    final String accNumber = selectedBank?.accountNumber ?? (_selectedMethod == 'mandiri' ? '137-00-998822-1' : '8830-192-888');
    final String accName = selectedBank?.accountName ?? 'PT HUMORA MEDIA KREATIF';
    final String instructions = selectedBank?.instructions ?? 'Transfer manual ke rekening di atas sesuai nominal paket.';

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
          Row(
            children: [
              Container(
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: _buildBankLogoWidget(
                  logoUrl: selectedBank?.bankLogoUrl,
                  bankCode: selectedBank?.code ?? _selectedMethod,
                  height: 22,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bankName.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 1),
                    const Text(
                      'Transfer Bank Manual Resmi',
                      style: TextStyle(fontSize: 10, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  accNumber,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryPurple,
                    letterSpacing: 1.0,
                  ),
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
          if (instructions.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              instructions,
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
          ],
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
