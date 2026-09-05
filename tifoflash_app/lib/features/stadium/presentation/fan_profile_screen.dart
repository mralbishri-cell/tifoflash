import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/tifo_theme.dart';

class FanProfileScreen extends StatelessWidget {
  const FanProfileScreen({super.key});

  Future<void> _launchUrlString(String urlStr) async {
    try {
      final Uri uri = Uri.parse(urlStr);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final badges = [
      {
        'title': 'قائد الفلاش الذهبي ⚡',
        'desc': 'المشاركة في 5 عروض تيفو مباشرة',
        'icon': Icons.bolt,
        'color': TifoTheme.stadiumGreen,
        'unlocked': true,
      },
      {
        'title': 'فارس الموجة الضوئية 🌊',
        'desc': 'تزامن مثالي مع الموجة بنسبة 99%',
        'icon': Icons.waves,
        'color': TifoTheme.stadiumCyan,
        'unlocked': true,
      },
      {
        'title': 'حاضر الديربي 🏆',
        'desc': 'حضور مباراة الكلاسيكو بالملعب',
        'icon': Icons.emoji_events,
        'color': const Color(0xFFF59E0B),
        'unlocked': true,
      },
      {
        'title': 'مايسترو العروض 🎵',
        'desc': 'التفاعل مع عروض الفريق بالكامل',
        'icon': Icons.music_note,
        'color': const Color(0xFFA855F7),
        'unlocked': true,
      },
    ];

    return Scaffold(
      backgroundColor: TifoTheme.darkBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.badge_outlined, color: TifoTheme.stadiumGreen, size: 22),
            SizedBox(width: 8),
            Text(
              'بروفايل المشجع والإعدادات (Fan Profile)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fan Digital Card Header
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: TifoTheme.stadiumCyan.withValues(alpha: 0.5)),
                boxShadow: [
                  BoxShadow(
                    color: TifoTheme.stadiumCyan.withValues(alpha: 0.15),
                    blurRadius: 15,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const RadialGradient(
                        colors: [Color(0xFF10B981), Color(0xFF06B6D4)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF10B981).withValues(alpha: 0.4),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.person, color: Colors.black, size: 36),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'مشجع التيفو الذهبي 👑',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'عضوية المدرج الذهبي • بطاقة رقمية',
                          style: TextStyle(color: TifoTheme.stadiumCyan, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.bolt, color: Colors.amber, size: 14),
                            SizedBox(width: 4),
                            Text(
                              '8 مباريات • 1,450 نقطة تيفو',
                              style: TextStyle(color: Colors.white70, fontSize: 11),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Badges & Achievements Section
            const Text(
              'أوسمة وإنجازات التيفو 🎖️',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 10),

            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.5,
              ),
              itemCount: badges.length,
              itemBuilder: (ctx, idx) {
                final badge = badges[idx];
                final bool unlocked = badge['unlocked'] as bool;
                final Color col = badge['color'] as Color;

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: TifoTheme.cardSurface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: unlocked ? col : TifoTheme.cardBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Icon(badge['icon'] as IconData, color: unlocked ? col : Colors.grey, size: 20),
                          const Spacer(),
                          Text(
                            unlocked ? 'مكتمل ✅' : 'مغلق 🔒',
                            style: TextStyle(
                              color: unlocked ? col : Colors.grey,
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        badge['title'] as String,
                        style: TextStyle(
                          color: unlocked ? Colors.white : Colors.grey,
                          fontWeight: FontWeight.bold,
                          fontSize: 11.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        badge['desc'] as String,
                        style: const TextStyle(color: Colors.white54, fontSize: 9.5),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            // Help, Support & Privacy Center Card (Interactive Tappable Links)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: TifoTheme.cardSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: TifoTheme.cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'مركز الدعم والمعلومات 🎧',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5),
                  ),
                  const SizedBox(height: 12),
                  _buildInteractiveTile(
                    icon: Icons.headset_mic_outlined,
                    title: 'الدعم الفني المباشر (Contact Support Center)',
                    subtitle: 'shelny.exp@gmail.com (انقر للمراسلة/فتح صفحة الدعم)',
                    onTap: () => _launchUrlString('https://mralbishri-cell.github.io/tifoflash/support.html'),
                  ),
                  _buildInteractiveTile(
                    icon: Icons.shield_outlined,
                    title: 'سياسة الخصوصية والأمان (Privacy Policy)',
                    subtitle: 'لا يتم جمع أو تتبع أي بيانات شخصية (انقر لفتح الصفحة)',
                    onTap: () => _launchUrlString('https://mralbishri-cell.github.io/tifoflash/privacy.html'),
                  ),
                  _buildInteractiveTile(
                    icon: Icons.info_outline,
                    title: 'إصدار التطبيق (App Version)',
                    subtitle: 'TifoFlash v1.0.0+6 (Build 2026)',
                    onTap: null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInteractiveTile({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          children: [
            Icon(icon, color: TifoTheme.stadiumCyan, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(color: TifoTheme.stadiumCyan, fontSize: 10.5)),
                ],
              ),
            ),
            if (onTap != null) const Icon(Icons.open_in_new, color: TifoTheme.stadiumCyan, size: 16),
          ],
        ),
      ),
    );
  }
}
