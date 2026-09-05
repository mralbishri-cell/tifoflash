import 'dart:async';
import 'dart:convert';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:vibration/vibration.dart';
import '../../../core/models/stadium_sector.dart';
import '../../../core/theme/tifo_theme.dart';
import 'fan_profile_screen.dart';
import 'light_studio_screen.dart';
import 'live_tifo_screen.dart';
import 'matchday_hub_screen.dart';
import 'stadium_guide_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  StreamSubscription<DatabaseEvent>? _alertSubscription;
  Timer? _httpAlertTimer;
  String? _lastHandledAlertId;

  @override
  void initState() {
    super.initState();
    _listenForLiveStadiumAlerts();
  }

  @override
  void dispose() {
    _alertSubscription?.cancel();
    _httpAlertTimer?.cancel();
    super.dispose();
  }

  void _listenForLiveStadiumAlerts() {
    // 1. HTTP Immediate Fetch & Periodic Polling
    _pollLiveAlertHttp();
    _httpAlertTimer?.cancel();
    _httpAlertTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted) _pollLiveAlertHttp();
    });

    // 2. WebSocket Realtime Listener
    try {
      final alertRef = FirebaseDatabase.instance.ref('/matches/match_2026_final/live_alert');
      _alertSubscription = alertRef.onValue.listen((event) {
        if (event.snapshot.value == null || event.snapshot.value is! Map) return;
        try {
          final map = Map<String, dynamic>.from(event.snapshot.value as Map);
          _handleAlertMap(map);
        } catch (e) {
          debugPrint('[LiveAlert] Parse error: $e');
        }
      });
    } catch (e) {
      debugPrint('[LiveAlert] Init error: $e');
    }
  }

  void _pollLiveAlertHttp() async {
    try {
      final url = Uri.parse('https://tifoflash-default-rtdb.europe-west1.firebasedatabase.app/matches/match_2026_final/live_alert.json');
      final res = await http.get(url).timeout(const Duration(seconds: 2));
      if (res.statusCode == 200 && res.body.isNotEmpty && res.body != 'null') {
        final decoded = json.decode(res.body);
        if (decoded is Map) {
          final map = Map<String, dynamic>.from(decoded);
          _handleAlertMap(map);
        }
      }
    } catch (_) {}
  }

  void _handleAlertMap(Map<String, dynamic> map) {
    final alertId = map['id']?.toString() ?? '';
    final title = map['title']?.toString() ?? 'إشعار من إدارة المباراة 📣';
    final body = map['body']?.toString() ?? 'شارك الآن في العرض الضوئي والتيفو ⚡';
    final timestamp = (map['timestamp'] as num?)?.toInt() ?? 0;

    final now = DateTime.now().millisecondsSinceEpoch;
    // Only show if fresh (within last 90 seconds) and not handled yet
    if (alertId.isNotEmpty && alertId != _lastHandledAlertId && (now - timestamp).abs() < 90000) {
      _lastHandledAlertId = alertId;
      _triggerInAppNotification(title, body);
    }
  }

  void _triggerInAppNotification(String title, String body) {
    // Vibrate device
    try {
      Vibration.hasVibrator().then((hasVib) {
        if (hasVib == true) {
          Vibration.vibrate(pattern: [0, 200, 100, 300]);
        }
      });
    } catch (_) {}

    if (!mounted) return;

    // Show floating alert dialog / banner
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        alignment: Alignment.topCenter,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0F172A), Color(0xFF1E1B4B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: TifoTheme.stadiumGreen, width: 2),
            boxShadow: [
              BoxShadow(
                color: TifoTheme.stadiumGreen.withValues(alpha: 0.4),
                blurRadius: 25,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.redAccent),
                    ),
                    child: const Icon(Icons.notifications_active, color: Colors.redAccent, size: 22),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54, size: 20),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                body,
                style: const TextStyle(
                  color: Color(0xFFE2E8F0),
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  // Navigate directly to Live Tifo Show
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => LiveTifoScreen(
                        sector: PresetStadiumData.sectors.first,
                        seatRow: '1',
                        seatNumber: '1',
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.flash_on, color: Colors.black, size: 18),
                label: const Text(
                  'دخول العرض المباشر الآن 🚀',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: TifoTheme.stadiumGreen,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      MatchdayHubScreen(onNavigateToTab: _onTabTapped),
      const LightStudioScreen(),
      const StadiumGuideScreen(),
      const FanProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: TifoTheme.darkBackground,
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0B1120),
          border: Border(
            top: BorderSide(
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
          backgroundColor: Colors.transparent,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: TifoTheme.stadiumGreen,
          unselectedItemColor: const Color(0xFF9CA3AF),
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
          unselectedLabelStyle: const TextStyle(fontSize: 10),
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.stadium_outlined),
              activeIcon: Icon(Icons.stadium),
              label: 'المباريات',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.tune_outlined),
              activeIcon: Icon(Icons.tune),
              label: 'الإضاءة',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.map_outlined),
              activeIcon: Icon(Icons.map),
              label: 'الدليل',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.badge_outlined),
              activeIcon: Icon(Icons.badge),
              label: 'بروفايل',
            ),
          ],
        ),
      ),
    );
  }
}
