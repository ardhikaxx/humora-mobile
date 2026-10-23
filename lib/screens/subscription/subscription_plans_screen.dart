import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../core/services/vibration_service.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/subscription_plan_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../widgets/custom_pill_app_bar.dart';
import '../../widgets/humora_empty_state.dart';
import '../auth/login_screen.dart';
import 'checkout_screen.dart';

class SubscriptionPlansScreen extends StatefulWidget {
  const SubscriptionPlansScreen({super.key});

  @override
  State<SubscriptionPlansScreen> createState() => _SubscriptionPlansScreenState();
}

class _SubscriptionPlansScreenState extends State<SubscriptionPlansScreen> {
  SubscriptionPlanModel? _selectedPlan;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SubscriptionProvider>().fetchPlans();
      context.read<SubscriptionProvider>().fetchPaymentInfo();
    });
  }

  @override
  Widget build(BuildContext context) {
    final subProv = context.watch<SubscriptionProvider>();
    final availablePlans = subProv.plans;

    if (subProv.isLoading && availablePlans.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: const SafeArea(
          child: Center(
            child: CircularProgressIndicator(color: AppColors.primaryYellow),
          ),
        ),
      );
    }

    if (availablePlans.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              CustomPillAppBar(
                title: 'Paket Premium',
                onBackTap: () => Navigator.of(context).pop(),
              ),
              Expanded(
                child: HumoraEmptyState(
                  icon: LucideIcons.crown,
                  title: 'Paket Belum Tersedia',
                  subtitle: 'Saat ini belum ada pilihan paket VIP yang aktif. Silakan hubungi pusat bantuan atau muat ulang halaman.',
                  buttonText: 'Muat Ulang Paket',
                  buttonIcon: LucideIcons.rotateCcw,
                  onButtonPressed: () => context.read<SubscriptionProvider>().fetchPlans(),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final currentSelected = (_selectedPlan != null && availablePlans.any((p) => p.id == _selectedPlan!.id))
        ? _selectedPlan!
        : availablePlans.first;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            CustomPillAppBar(
              title: 'Paket Premium',
              onBackTap: () => Navigator.of(context).pop(),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    const SizedBox(height: 12),

                    // Badge top
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.yellowSoft,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.primaryYellow, width: 1.2),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(LucideIcons.crown, size: 14, color: Color(0xFFD97706)),
                          SizedBox(width: 6),
                          Text(
                            'HUMORA PREMIUM ACCESS',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryPurple,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Title & Subtitle
                    const Text(
                      'Pilih Paket Premium',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        'Nikmati setiap episode tanpa jeda cerita. Tawa segar menghibur sepuasnya.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Plan Cards List
                    ...availablePlans.map((plan) {
                      final isSelected = currentSelected.id == plan.id;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _buildPlanCard(plan, isSelected),
                      );
                    }),
                    const SizedBox(height: 10),

                    // Benefits Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.border, width: 1.2),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'KEUNTUNGAN ${currentSelected.name.toUpperCase()}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...currentSelected.benefits.map((benefit) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    LucideIcons.checkCircle2,
                                    size: 16,
                                    color: AppColors.green,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      benefit,
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Payment Instruction Note
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3E8FF).withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.accentPurpleBorder, width: 1),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(LucideIcons.info, size: 16, color: AppColors.accentPurple),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Pembayaran diproses melalui transfer bank atau QRIS resmi. Setelah mengunggah bukti transfer, tim verifikasi HUMORA akan mengaktifkan paket VIP Anda.',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),

            // Bottom Sticky Checkout Bar
            _buildBottomBar(context, currentSelected),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard(SubscriptionPlanModel plan, bool isSelected) {
    return GestureDetector(
      onTap: () {
        VibrationService.lightImpact();
        setState(() {
          _selectedPlan = plan;
        });
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isSelected ? AppColors.accentPurple : AppColors.border,
                width: isSelected ? 2.0 : 1.2,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.accentPurple.withValues(alpha: 0.12),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Radio Checkbox
                Container(
                  width: 22,
                  height: 22,
                  margin: const EdgeInsets.only(top: 2),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primaryDark : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? AppColors.primaryDark : const Color(0xFFD4D4D8),
                      width: isSelected ? 1.5 : 2.0,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(LucideIcons.check, size: 14, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 12),

                // Name & details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AutoSizeText(
                        plan.name,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        minFontSize: 11,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        plan.durationText,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (plan.formattedQuota.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.accentPurpleSoft : const Color(0xFFF4F4F5),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Kuota: ${plan.formattedQuota}',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: isSelected ? AppColors.accentPurple : AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                      if (plan.isAddon && !context.read<AuthProvider>().canPurchaseAddon) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: const Color(0xFFFECACA)),
                          ),
                          child: const Text(
                            'Khusus Paket Mingguan Aktif',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFDC2626),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        plan.description,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),

                // Prices right
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Rp ${plan.originalPrice.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                    const SizedBox(height: 2),
                    AutoSizeText(
                      'Rp ${plan.price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryPurple,
                      ),
                      maxLines: 1,
                      minFontSize: 13,
                    ),
                    if (plan.monthlyPriceText != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        plan.monthlyPriceText!,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.accentPurple,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Badge on top right
          if (plan.badgeText != null)
            Positioned(
              top: -10,
              right: 18,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primaryYellow,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  plan.badgeText!,
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryDark,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, SubscriptionPlanModel selectedPlan) {
    final auth = context.watch<AuthProvider>();
    final isAddonBlocked = selectedPlan.isAddon && !auth.canPurchaseAddon;
    final formattedPrice = 'Rp ${selectedPlan.price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isAddonBlocked) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: const Row(
                children: [
                  Icon(LucideIcons.alertCircle, size: 16, color: Color(0xFFDC2626)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Paket Add-on hanya dapat dibeli jika Anda memiliki Paket Akses Mingguan aktif.',
                      style: TextStyle(fontSize: 11, color: Color(0xFF991B1B), fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Pembayaran',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                formattedPrice,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryPurple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Lanjutkan Pembayaran Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: isAddonBlocked
                  ? null
                  : () {
                      VibrationService.mediumImpact();
                      final auth = context.read<AuthProvider>();
                      if (auth.isGuest) {
                        ScaffoldMessenger.of(context).clearSnackBars();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Silakan masuk atau daftar akun terlebih dahulu untuk melanjutkan pembayaran paket ${selectedPlan.name}.',
                            ),
                            backgroundColor: AppColors.primaryDark,
                            duration: const Duration(seconds: 3),
                          ),
                        );
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => LoginScreen(
                              redirectToCheckoutPlan: selectedPlan,
                            ),
                          ),
                        );
                        return;
                      }

                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => CheckoutScreen(plan: selectedPlan),
                        ),
                      );
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryDark,
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFFE4E4E7),
                disabledForegroundColor: const Color(0xFFA1A1AA),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Lanjutkan Pembayaran',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(LucideIcons.arrowRight, size: 18),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),

          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(LucideIcons.shieldCheck, size: 14, color: AppColors.green),
              SizedBox(width: 6),
              Text(
                'Verifikasi resmi HUMORA aman dan terpercaya',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
