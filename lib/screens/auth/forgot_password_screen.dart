import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_assets.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_pill_app_bar.dart';
import 'reset_password_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  final String? initialEmail;
  final String? initialPhone;
  final String? initialIdentifier;
  final int initialTabIndex;

  const ForgotPasswordScreen({
    super.key,
    this.initialEmail,
    this.initialPhone,
    this.initialIdentifier,
    this.initialTabIndex = 0,
  });

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  int _selectedTabIndex = 0; // 0 for Email, 1 for Nomor HP
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _selectedTabIndex = widget.initialTabIndex;

    final initialId = widget.initialIdentifier ?? '';
    final isPhone = (widget.initialPhone != null && widget.initialPhone!.isNotEmpty) ||
        (initialId.isNotEmpty && !initialId.contains('@'));

    final emailText = widget.initialEmail ?? (!isPhone ? initialId : '');
    final phoneText = widget.initialPhone ?? (isPhone ? initialId : '');

    _emailController = TextEditingController(text: emailText);
    _phoneController = TextEditingController(text: phoneText);

    if (isPhone && phoneText.isNotEmpty) {
      _selectedTabIndex = 1;
    } else if (emailText.isNotEmpty) {
      _selectedTabIndex = 0;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleVerifyIdentifier() async {
    final isEmail = _selectedTabIndex == 0;
    final identifier = isEmail ? _emailController.text.trim() : _phoneController.text.trim();

    if (identifier.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEmail
                ? 'Mohon masukkan alamat email Anda.'
                : 'Mohon masukkan nomor handphone Anda.',
          ),
          backgroundColor: const Color(0xFFD97706),
        ),
      );
      return;
    }

    if (isEmail) {
      if (!identifier.contains('@') || !identifier.contains('.')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Format alamat email tidak valid.'),
            backgroundColor: AppColors.red,
          ),
        );
        return;
      }
    } else {
      final clean = identifier.replaceAll(RegExp(r'[^0-9]'), '');
      if (clean.length < 8) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nomor handphone minimal terdiri dari 8 digit.'),
            backgroundColor: AppColors.red,
          ),
        );
        return;
      }
    }

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.verifyForgotPasswordIdentifier(identifier);

    if (!mounted) return;

    if (success) {
      final label = isEmail ? 'Email' : 'Nomor handphone';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$label berhasil diverifikasi! Silakan ubah kata sandi baru Anda.'),
          backgroundColor: AppColors.primaryDark,
          duration: const Duration(seconds: 2),
        ),
      );

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ResetPasswordScreen(
            identifier: identifier,
            isPhone: !isEmail,
          ),
        ),
      );
    } else {
      final typeLabel = isEmail ? 'Alamat email' : 'Nomor handphone';
      final err = authProvider.errorMessage ?? '$typeLabel belum terdaftar di akun HUMORA.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err),
          backgroundColor: AppColors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Widget _buildTabButton({
    required int index,
    required String label,
    required IconData icon,
  }) {
    final isSelected = _selectedTabIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTabIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? const [
                  BoxShadow(
                    color: Color(0x0C000000),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? AppColors.accentPurple : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.primaryDark : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isEmail = _selectedTabIndex == 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Fixed Top Pill App Bar
            CustomPillAppBar(
              title: 'Lupa Kata Sandi',
              onBackTap: () => Navigator.of(context).pop(),
            ),
            const SizedBox(height: 12),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    // Logo Center
                    ClipOval(
                      child: Image.asset(
                        AppAssets.logoHumora,
                        width: 88,
                        height: 88,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const Icon(
                          LucideIcons.smile,
                          size: 48,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Brand Tagline
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.accentPurpleSoft,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.accentPurple.withValues(alpha: 0.25),
                          width: 1,
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            LucideIcons.sparkles,
                            size: 13,
                            color: AppColors.accentPurple,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'scroll, laugh, repeat',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.accentPurple,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Title & Subtitle
                    const Text(
                      'Lupa Kata Sandi?',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 36),
                      child: Text(
                        'Masukkan alamat email atau nomor handphone yang terdaftar untuk mengatur ulang kata sandi akun Anda.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Form Container Card
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.border, width: 1.2),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x0A000000),
                            blurRadius: 14,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Tab Selection: Email vs Nomor HP
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3EFF8),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: _buildTabButton(
                                    index: 0,
                                    label: 'Email',
                                    icon: LucideIcons.mail,
                                  ),
                                ),
                                Expanded(
                                  child: _buildTabButton(
                                    index: 1,
                                    label: 'Nomor HP',
                                    icon: LucideIcons.phone,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),

                          // Dynamic Label
                          Text(
                            isEmail ? 'Alamat Email Terdaftar' : 'Nomor Handphone Terdaftar',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Dynamic Input Field
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFFAF8FC),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.border, width: 1.2),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: Row(
                              children: [
                                Icon(
                                  isEmail ? LucideIcons.mail : LucideIcons.phone,
                                  size: 18,
                                  color: AppColors.textSecondary,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextField(
                                    key: ValueKey('forgot_input_$_selectedTabIndex'),
                                    controller: isEmail ? _emailController : _phoneController,
                                    keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.phone,
                                    autofocus: true,
                                    decoration: InputDecoration(
                                      border: InputBorder.none,
                                      hintText: isEmail
                                          ? 'Masukkan alamat email'
                                          : 'Masukkan nomor handphone',
                                      hintStyle: const TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                    onSubmitted: (_) => _handleVerifyIdentifier(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Info Note
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3E8FF),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  LucideIcons.info,
                                  size: 16,
                                  color: AppColors.primaryDark,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    isEmail
                                        ? 'Email Anda akan dicocokkan secara otomatis dengan akun HUMORA yang sudah terdaftar.'
                                        : 'Nomor handphone Anda akan dicocokkan secara otomatis dengan akun HUMORA yang sudah terdaftar.',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.primaryDark,
                                      height: 1.3,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 22),

                          // Submit Button
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: auth.isLoading ? null : _handleVerifyIdentifier,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryDark,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 0,
                              ),
                              child: auth.isLoading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          isEmail ? 'Verifikasi Email' : 'Verifikasi Nomor HP',
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        const Icon(LucideIcons.arrowRight, size: 18),
                                      ],
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Back to Login Link
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const Text(
                          'Sudah ingat kata sandi Anda? ',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: const Text(
                            'Masuk',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.accentPurple,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
