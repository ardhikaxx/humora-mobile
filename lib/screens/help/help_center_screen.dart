import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../data/dummy_data.dart';
import '../../widgets/custom_pill_app_bar.dart';

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  int _selectedCategoryIndex = 0;
  final Set<int> _expandedFaqIndices = {0}; // First FAQ expanded as in reference
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> _categories = [
    {'title': 'Semua Topik', 'icon': LucideIcons.helpCircle},
    {'title': 'Langganan & VIP', 'icon': LucideIcons.creditCard},
    {'title': 'Streaming Video', 'icon': LucideIcons.playCircle},
    {'title': 'Akun & Profil', 'icon': LucideIcons.user},
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            CustomPillAppBar(
              title: 'Pusat Bantuan',
              onBackTap: () => Navigator.of(context).pop(),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),

                    // Purple Hero Card with Search
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.primaryPurple,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x18000000),
                            blurRadius: 14,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(LucideIcons.sparkles, size: 13, color: AppColors.primaryYellow),
                              SizedBox(width: 6),
                              Text(
                                'LAYANAN BANTUAN 24/7',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primaryYellow,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Ada yang bisa kami bantu?',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Temukan jawaban cepat seputar langganan, streaming, dan akun HUMORA.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.85),
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Search input inside Hero
                          Container(
                            height: 46,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.25),
                                width: 1,
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: Row(
                              children: [
                                const Icon(
                                  LucideIcons.search,
                                  color: Colors.white70,
                                  size: 18,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextField(
                                    controller: _searchController,
                                    style: const TextStyle(color: Colors.white, fontSize: 12.5),
                                    decoration: InputDecoration(
                                      border: InputBorder.none,
                                      hintText: 'Cari kendala (contoh: langganan, video)...',
                                      hintStyle: TextStyle(
                                        fontSize: 12,
                                        color: Colors.white.withValues(alpha: 0.65),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Kategori Kendala
                    const Text(
                      'KATEGORI KENDALA',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // 2x2 Grid Chips
                    GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 3.2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: _categories.length,
                      itemBuilder: (context, index) {
                        final cat = _categories[index];
                        final isSelected = _selectedCategoryIndex == index;

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedCategoryIndex = index;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primaryPurple : AppColors.surface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected ? AppColors.primaryPurple : AppColors.border,
                                width: 1.2,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  cat['icon'] as IconData,
                                  size: 16,
                                  color: isSelected ? AppColors.primaryYellow : AppColors.accentPurple,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    cat['title'] as String,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                      color: isSelected ? Colors.white : AppColors.textPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),

                    // Pertanyaan Sering Diajukan (FAQ)
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.border, width: 1.2),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Pertanyaan Sering Diajukan (FAQ)',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 14),

                          ...List.generate(DummyData.faqs.length, (idx) {
                            final faq = DummyData.faqs[idx];
                            final isExpanded = _expandedFaqIndices.contains(idx);

                            return Column(
                              children: [
                                if (idx > 0)
                                  const Divider(color: AppColors.border, height: 20),
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      if (isExpanded) {
                                        _expandedFaqIndices.remove(idx);
                                      } else {
                                        _expandedFaqIndices.add(idx);
                                      }
                                    });
                                  },
                                  behavior: HitTestBehavior.opaque,
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          faq['question']!,
                                          style: const TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textPrimary,
                                            height: 1.35,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Icon(
                                        isExpanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                                        size: 16,
                                        color: AppColors.accentPurple,
                                      ),
                                    ],
                                  ),
                                ),
                                if (isExpanded) ...[
                                  const SizedBox(height: 10),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF9F6FC),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      faq['answer']!,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                        height: 1.45,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            );
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Masih Butuh Bantuan Card
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.border, width: 1.2),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Masih butuh bantuan?',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Tim layanan pelanggan HUMORA siap mendampingimu setiap hari (08.00 - 22.00 WIB).',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 14),

                          // WhatsApp Card
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFA7F3D0), width: 1),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    LucideIcons.messageCircle,
                                    color: Color(0xFF059669),
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'WhatsApp Support',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF065F46),
                                        ),
                                      ),
                                      SizedBox(height: 1),
                                      Text(
                                        '+62 812-9988-7766',
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          color: Color(0xFF047857),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  LucideIcons.externalLink,
                                  size: 16,
                                  color: Color(0xFF059669),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Email Card
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.accentPurpleSoft.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.accentPurpleBorder, width: 1),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    LucideIcons.mail,
                                    color: AppColors.accentPurple,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Email Resmi',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primaryPurple,
                                        ),
                                      ),
                                      SizedBox(height: 1),
                                      Text(
                                        'support@humora.id',
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  LucideIcons.externalLink,
                                  size: 16,
                                  color: AppColors.accentPurple,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
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
}
