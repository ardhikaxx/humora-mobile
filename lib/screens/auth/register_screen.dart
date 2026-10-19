import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../data/dummy_data.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_pill_app_bar.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _identifierController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreedToTerms = true;

  @override
  void dispose() {
    _nameController.dispose();
    _identifierController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleRegister() {
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap setujui Ketentuan Penggunaan dan Kebijakan Privasi.'),
          backgroundColor: AppColors.red,
        ),
      );
      return;
    }

    final name = _nameController.text.trim();
    final identifier = _identifierController.text.trim();
    final password = _passwordController.text.trim();

    context.read<AuthProvider>().register(
      fullName: name.isNotEmpty ? name : 'Ardhika Pradana',
      identifier: identifier.isNotEmpty ? identifier : 'ardhika@humora.id',
      password: password,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Akun berhasil dibuat! Selamat datang di HUMORA.'),
        backgroundColor: AppColors.primaryDark,
        duration: Duration(seconds: 2),
      ),
    );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              CustomPillAppBar(
                title: 'Daftar Akun',
                onBackTap: () => Navigator.of(context).pop(),
              ),
              const SizedBox(height: 12),

              // Logo Center
              Container(
                width: 84,
                height: 84,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryYellow,
                ),
                padding: const EdgeInsets.all(12),
                child: Image.asset(
                  DummyData.logoHumora,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const Icon(
                    LucideIcons.smile,
                    size: 46,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Title & Subtitle
              const Text(
                'Mulai Cerita Barumu',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 6),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  'Daftar dalam 1 menit dan nikmati ratusan episode seru tanpa batas.',
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
                    // Nama Lengkap
                    const Text(
                      'Nama Lengkap',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _buildInputField(
                      controller: _nameController,
                      hint: 'cth. Ardhika Pradana',
                      keyboardType: TextInputType.name,
                    ),
                    const SizedBox(height: 14),

                    // Email atau No HP
                    const Text(
                      'Email atau No. Handphone',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _buildInputField(
                      controller: _identifierController,
                      hint: 'nama@email.com atau 0812xxxx',
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 14),

                    // Kata Sandi
                    const Text(
                      'Kata Sandi',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _buildInputField(
                      controller: _passwordController,
                      hint: 'Minimal 6 karakter',
                      obscureText: _obscurePassword,
                      trailing: GestureDetector(
                        onTap: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                        child: Icon(
                          _obscurePassword ? LucideIcons.eye : LucideIcons.eyeOff,
                          size: 18,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Ulangi Kata Sandi
                    const Text(
                      'Ulangi Kata Sandi',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _buildInputField(
                      controller: _confirmPasswordController,
                      hint: 'Ketik ulang kata sandi...',
                      obscureText: _obscureConfirmPassword,
                      trailing: GestureDetector(
                        onTap: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                        child: Icon(
                          _obscureConfirmPassword ? LucideIcons.eye : LucideIcons.eyeOff,
                          size: 18,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Terms Checkbox
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _agreedToTerms = !_agreedToTerms;
                            });
                          },
                          child: Container(
                            width: 20,
                            height: 20,
                            margin: const EdgeInsets.only(top: 2),
                            decoration: BoxDecoration(
                              color: _agreedToTerms ? AppColors.primaryDark : Colors.transparent,
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(
                                color: _agreedToTerms ? AppColors.primaryDark : AppColors.textMuted,
                                width: 1.5,
                              ),
                            ),
                            child: _agreedToTerms
                                ? const Icon(
                                    LucideIcons.check,
                                    size: 14,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: RichText(
                            text: const TextSpan(
                              text: 'Saya menyetujui ',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                                height: 1.35,
                              ),
                              children: [
                                TextSpan(
                                  text: 'Ketentuan Penggunaan',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                TextSpan(text: ' dan '),
                                TextSpan(
                                  text: 'Kebijakan Privasi',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                TextSpan(text: ' HUMORA.'),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _handleRegister,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryDark,
                          foregroundColor: AppColors.primaryYellow,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Buat Akun HUMORA',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryYellow,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(
                              LucideIcons.arrowRight,
                              size: 18,
                              color: AppColors.primaryYellow,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Bottom Link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Sudah memiliki akun HUMORA? ',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => const LoginScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      'Masuk di sini',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        decoration: TextDecoration.underline,
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
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? trailing,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFAF8FC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 1.2),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              obscureText: obscureText,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: hint,
                hintStyle: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textMuted,
                ),
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
