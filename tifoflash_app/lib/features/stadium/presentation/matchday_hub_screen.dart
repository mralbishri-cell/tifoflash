import 'package:flutter/material.dart';
import '../../../core/models/stadium_sector.dart';
import '../../../core/theme/tifo_theme.dart';
import 'live_tifo_screen.dart';
import 'sector_selector_screen.dart';

class MatchdayHubScreen extends StatefulWidget {
  final Function(int tabIndex)? onNavigateToTab;

  const MatchdayHubScreen({super.key, this.onNavigateToTab});

  @override
  State<MatchdayHubScreen> createState() => _MatchdayHubScreenState();
}

class _MatchdayHubScreenState extends State<MatchdayHubScreen> {
  final List<Map<String, dynamic>> _upcomingMatches = [
    {
      'homeTeam': 'الهلال',
      'awayTeam': 'النصر',
      'homeLogo': '⚽',
      'awayLogo': '🏆',
      'stadium': PresetStadiumData.kingdomArena,
      'time': 'اليوم • 08:30 م',
      'status': 'LIVE NOW 🔥',
      'isLive': true,
      'syncedFans': '18,450',
    },
    {
      'homeTeam': 'الاتحاد',
      'awayTeam': 'الأهلي',
      'homeLogo': '🟡',
      'awayLogo': '🟢',
      'stadium': PresetStadiumData.jawharaStadium,
      'time': 'غداً • 09:00 م',
      'status': 'قريباً ⏳',
      'isLive': false,
      'syncedFans': '24,100',
    },
    {
      'homeTeam': 'الشباب',
      'awayTeam': 'الاتفاق',
      'homeLogo': '⚪',
      'awayLogo': '🔴',
      'stadium': PresetStadiumData.alawwalPark,
      'time': 'الجمعة • 07:45 م',
      'status': 'قريباً ⏳',
      'isLive': false,
      'syncedFans': '12,300',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TifoTheme.darkBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  colors: [Color(0xFF10B981), Color(0xFF06B6D4)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10B981).withValues(alpha: 0.5),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: const Icon(Icons.bolt, color: Colors.black, size: 20),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TIFO FLASH',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    letterSpacing: 2,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'مركز المباريات والتزامن المباشر',
                  style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(left: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF10B981)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.wifi_tethering, color: Color(0xFF10B981), size: 14),
                SizedBox(width: 4),
                Text(
                  'سيرفر مباشر ⚡',
                  style: TextStyle(color: Color(0xFF10B981), fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Live Featured Match Banner
            _buildLiveFeaturedMatchCard(context),

            const SizedBox(height: 20),

            // Quick Actions Toolbar
            _buildQuickActionsGrid(context),

            const SizedBox(height: 20),

            // Upcoming Matches List
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'جدول المباريات والفعاليات القادمة 🗓️',
                  style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                ),
                Text(
                  'عرض الكل',
                  style: TextStyle(color: TifoTheme.stadiumCyan, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 10),

            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _upcomingMatches.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (ctx, idx) {
                final match = _upcomingMatches[idx];
                return _buildMatchCard(ctx, match);
              },
            ),

            const SizedBox(height: 20),

            // Demo Mode Callout Box
            _buildDemoShowCallout(context),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveFeaturedMatchCard(BuildContext context) {
    final liveMatch = _upcomingMatches.first;
    final StadiumProfile stadium = liveMatch['stadium'];

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF064E3B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: TifoTheme.stadiumGreen, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: TifoTheme.stadiumGreen.withValues(alpha: 0.2),
            blurRadius: 20,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            left: -20,
            top: -20,
            child: Icon(Icons.stadium, size: 140, color: Colors.white.withValues(alpha: 0.04)),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.redAccent),
                      ),
                      child: const Row(
                        children: [
                          CircleAvatar(radius: 3, backgroundColor: Colors.redAccent),
                          SizedBox(width: 6),
                          Text(
                            'مباشر الان • LIVE SHOW',
                            style: TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.people_outline, color: TifoTheme.stadiumCyan, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '${liveMatch['syncedFans']} مشجع متزامن',
                          style: const TextStyle(color: TifoTheme.stadiumCyan, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Teams Scoreboard Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Text(liveMatch['homeLogo'], style: const TextStyle(fontSize: 32)),
                        const SizedBox(height: 4),
                        Text(
                          liveMatch['homeTeam'],
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                    const Column(
                      children: [
                        Text(
                          'VS',
                          style: TextStyle(color: TifoTheme.stadiumGreen, fontWeight: FontWeight.w900, fontSize: 20),
                        ),
                        Text(
                          'الشوط الأول',
                          style: TextStyle(color: Colors.white60, fontSize: 10),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        Text(liveMatch['awayLogo'], style: const TextStyle(fontSize: 32)),
                        const SizedBox(height: 4),
                        Text(
                          liveMatch['awayTeam'],
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.black38,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on, color: TifoTheme.stadiumCyan, size: 16),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${stadium.nameAr} • ${stadium.cityAr}',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => LiveTifoScreen(
                                sector: stadium.sectors.first,
                                seatRow: '12',
                                seatNumber: '45',
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.bolt, color: Colors.black, size: 20),
                        label: const Text(
                          'دخول عرض التيفو المباشر',
                          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 13),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: TifoTheme.stadiumGreen,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const SectorSelectorScreen(),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: TifoTheme.stadiumCyan),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text(
                        'تحديد المقعد',
                        style: TextStyle(color: TifoTheme.stadiumCyan, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsGrid(BuildContext context) {
    final actions = [
      {
        'icon': Icons.tune_rounded,
        'title': 'استوديو الإضاءة',
        'subtitle': 'فلاش وألوان مخصصة',
        'color': TifoTheme.stadiumCyan,
        'tabIndex': 1,
      },
      {
        'icon': Icons.music_note_rounded,
        'title': 'أهازيج المدرج',
        'subtitle': 'إيقاعات وأغاني',
        'color': const Color(0xFFA855F7),
        'tabIndex': 2,
      },
      {
        'icon': Icons.map_outlined,
        'title': 'دليل الملعب',
        'subtitle': 'بوابات وخدمات',
        'color': const Color(0xFFF59E0B),
        'tabIndex': 2,
      },
      {
        'icon': Icons.badge_outlined,
        'title': 'أوسمة المشجع',
        'subtitle': 'إنجازات ونقاط',
        'color': TifoTheme.stadiumGreen,
        'tabIndex': 3,
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 2.3,
      ),
      itemCount: actions.length,
      itemBuilder: (ctx, idx) {
        final item = actions[idx];
        final Color col = item['color'] as Color;
        return InkWell(
          onTap: () {
            if (widget.onNavigateToTab != null) {
              widget.onNavigateToTab!(item['tabIndex'] as int);
            }
          },
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: TifoTheme.cardSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: col.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: col.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(item['icon'] as IconData, color: col, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['title'] as String,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        item['subtitle'] as String,
                        style: const TextStyle(color: Colors.white54, fontSize: 9.5),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMatchCard(BuildContext context, Map<String, dynamic> match) {
    final StadiumProfile stadium = match['stadium'];
    final bool isLive = match['isLive'] as bool;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: TifoTheme.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isLive ? TifoTheme.stadiumGreen : TifoTheme.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${match['homeLogo']} VS ${match['awayLogo']}',
              style: const TextStyle(fontSize: 16),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${match['homeTeam']} 🆚 ${match['awayTeam']}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5),
                ),
                const SizedBox(height: 2),
                Text(
                  '${stadium.nameAr} • ${match['time']}',
                  style: const TextStyle(color: Colors.white60, fontSize: 11),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => LiveTifoScreen(
                    sector: stadium.sectors.first,
                    seatRow: '10',
                    seatNumber: '22',
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isLive ? TifoTheme.stadiumGreen : const Color(0xFF1F2937),
              foregroundColor: isLive ? Colors.black : Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              isLive ? 'دخول العرض' : 'انضمام',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDemoShowCallout(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E1B4B), Color(0xFF0F172A)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF8B5CF6)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.play_circle_fill, color: Color(0xFF8B5CF6), size: 26),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🧪 وضع العرض التجريبي (Demo Mode)',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                SizedBox(height: 2),
                Text(
                  'اختبار فلاش الجوال وألوان الشاشة بدون الحاجة لمباراة جارية',
                  style: TextStyle(color: Colors.white60, fontSize: 10.5),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => LiveTifoScreen(
                    sector: PresetStadiumData.kingdomArena.sectors.first,
                    startInDemo: true,
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B5CF6),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('تشغيل', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
          ),
        ],
      ),
    );
  }
}
