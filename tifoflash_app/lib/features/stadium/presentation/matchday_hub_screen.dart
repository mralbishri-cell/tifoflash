import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/models/stadium_sector.dart';
import '../../../core/services/sync_engine_service.dart';
import '../../../core/theme/tifo_theme.dart';
import 'live_tifo_screen.dart';

class MatchdayHubScreen extends StatefulWidget {
  final Function(int tabIndex)? onNavigateToTab;

  const MatchdayHubScreen({super.key, this.onNavigateToTab});

  @override
  State<MatchdayHubScreen> createState() => _MatchdayHubScreenState();
}

class _MatchdayHubScreenState extends State<MatchdayHubScreen> {
  StadiumProfile _selectedStadium = PresetStadiumData.kingdomArena;
  late StadiumSector _selectedSector;
  final TextEditingController _rowController = TextEditingController(text: '12');
  final TextEditingController _seatController = TextEditingController(text: '45');

  final SyncEngineService _syncEngine = SyncEngineService();
  StreamSubscription<SyncEngineState>? _syncSubscription;
  SyncEngineState _syncState = SyncEngineState.initial();

  @override
  void initState() {
    super.initState();
    _selectedSector = _selectedStadium.sectors.first;
    _syncEngine.initialize();
    _syncState = _syncEngine.state;
    _syncSubscription = _syncEngine.stateStream.listen((state) {
      if (mounted) {
        setState(() {
          _syncState = state;
        });
      }
    });
  }

  @override
  void dispose() {
    _syncSubscription?.cancel();
    _rowController.dispose();
    _seatController.dispose();
    super.dispose();
  }

  void _enterLiveTifoShow() {
    final row = _rowController.text.trim();
    final seat = _seatController.text.trim();

    _syncEngine.updateFanPlacement(
      sector: _selectedSector,
      seatRow: row,
      seatNumber: seat,
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LiveTifoScreen(
          sector: _selectedSector,
          seatRow: row,
          seatNumber: seat,
        ),
      ),
    );
  }


  void _showQRScannerModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: TifoTheme.darkBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (ctx) {
        bool isScanning = true;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(24),
              height: 480,
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Row(
                    children: [
                      Icon(Icons.qr_code_scanner, color: TifoTheme.stadiumCyan, size: 24),
                      SizedBox(width: 8),
                      Text(
                        'كاميرا مسح التذكرة (QR Code Scan) 🎟️',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'وجّه كاميرا الجوال نحو الـ QR Code المطبوع على تذكرتك لتحديد موقعك تلقائياً',
                    style: TextStyle(color: Colors.white60, fontSize: 11.5),
                  ),
                  const SizedBox(height: 20),

                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: TifoTheme.stadiumCyan, width: 2),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          const Icon(Icons.camera_alt_outlined, color: Colors.white12, size: 80),
                          Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              border: Border.all(color: TifoTheme.stadiumCyan, width: 2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: isScanning
                                ? const Center(child: CircularProgressIndicator(color: TifoTheme.stadiumCyan))
                                : const Icon(Icons.check_circle_rounded, color: TifoTheme.stadiumGreen, size: 60),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        setModalState(() => isScanning = false);
                        final nav = Navigator.of(context);
                        final messenger = ScaffoldMessenger.of(context);
                        Future.delayed(const Duration(milliseconds: 600), () {
                          if (!mounted) return;
                          nav.pop();
                          setState(() {
                            _selectedSector = _selectedStadium.sectors.first;
                            _rowController.text = '14';
                            _seatController.text = '28';
                          });
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text('تم مسح التذكرة بنجاح: ${_selectedSector.nameAr} • صف 14 • مقعد 28 🎟️'),
                              backgroundColor: TifoTheme.stadiumGreen,
                            ),
                          );
                        });
                      },
                      icon: const Icon(Icons.qr_code, color: Colors.black),
                      label: const Text(
                        'تأكيد قراءة التذكرة والربط التلقائي',
                        style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: TifoTheme.stadiumCyan,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeMatch = _syncState.activeMatch;

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
                  'التزامن الضوئي المباشر للملاعب',
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
                CircleAvatar(radius: 3, backgroundColor: Color(0xFF10B981)),
                SizedBox(width: 6),
                Text(
                  'سيرفر متصل ⚡',
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
            // Live Admin Match Banner (Synced with Firebase)
            _buildLiveMatchBanner(context, activeMatch),

            const SizedBox(height: 20),

            // STEP 1: Select Stadium
            const Text(
              '1️⃣ اختر ملعب المباراة (Select Stadium):',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<StadiumProfile>(
              initialValue: _selectedStadium,
              dropdownColor: TifoTheme.cardSurface,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              isExpanded: true,
              decoration: InputDecoration(
                filled: true,
                fillColor: TifoTheme.cardSurface,
                prefixIcon: const Icon(Icons.stadium, color: TifoTheme.stadiumCyan),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: TifoTheme.stadiumCyan, width: 1.5),
                ),
              ),
              items: PresetStadiumData.allStadiums.map((stadium) {
                return DropdownMenuItem<StadiumProfile>(
                  value: stadium,
                  child: Text(
                    '${stadium.nameAr} (${stadium.cityAr})',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (newStadium) {
                if (newStadium != null) {
                  setState(() {
                    _selectedStadium = newStadium;
                    _selectedSector = newStadium.sectors.first;
                  });
                }
              },
            ),

            const SizedBox(height: 16),

            // STEP 2: Select Sector / Stand
            const Text(
              '2️⃣ اختر القطاع أو المدرج (Select Sector):',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<StadiumSector>(
              initialValue: _selectedSector,
              dropdownColor: TifoTheme.cardSurface,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              isExpanded: true,
              decoration: InputDecoration(
                filled: true,
                fillColor: TifoTheme.cardSurface,
                prefixIcon: const Icon(Icons.stadium_outlined, color: TifoTheme.stadiumGreen),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: TifoTheme.stadiumGreen, width: 1.5),
                ),
              ),
              items: _selectedStadium.sectors.map((sector) {
                return DropdownMenuItem<StadiumSector>(
                  value: sector,
                  child: Text(
                    '${sector.nameAr} (${sector.standGroup})',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (newSector) {
                if (newSector != null) {
                  setState(() {
                    _selectedSector = newSector;
                  });
                }
              },
            ),

            const SizedBox(height: 16),

            // STEP 3: Seat & Row Input Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: TifoTheme.cardSurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: TifoTheme.cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '3️⃣ رقم الصف والمقعد (اختياري):',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _rowController,
                          keyboardType: TextInputType.text,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          decoration: InputDecoration(
                            labelText: 'رقم الصف / Row',
                            labelStyle: const TextStyle(color: Colors.white70),
                            prefixIcon: const Icon(Icons.table_rows, color: TifoTheme.stadiumCyan),
                            filled: true,
                            fillColor: Colors.black26,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _seatController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          decoration: InputDecoration(
                            labelText: 'رقم المقعد / Seat',
                            labelStyle: const TextStyle(color: Colors.white70),
                            prefixIcon: const Icon(Icons.event_seat, color: TifoTheme.stadiumCyan),
                            filled: true,
                            fillColor: Colors.black26,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _showQRScannerModal,
                      icon: const Icon(Icons.qr_code_scanner, color: TifoTheme.stadiumCyan, size: 18),
                      label: const Text(
                        '📷 مسح التذكرة تلقائياً (Scan QR Code)',
                        style: TextStyle(color: TifoTheme.stadiumCyan, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: TifoTheme.stadiumCyan),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // PRIMARY BIG ACTION BUTTON: Enter Live Tifo Show
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _enterLiveTifoShow,
                icon: const Icon(Icons.bolt, color: Colors.black, size: 24),
                label: const Text(
                  '⚡ دخول العرض الضوئي المباشر الان',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: TifoTheme.stadiumGreen,
                  elevation: 8,
                  shadowColor: TifoTheme.stadiumGreen.withValues(alpha: 0.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveMatchBanner(BuildContext context, ActiveMatchInfo activeMatch) {
    return Container(
      padding: const EdgeInsets.all(16),
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
            blurRadius: 15,
          ),
        ],
      ),
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
                child: Row(
                  children: [
                    const CircleAvatar(radius: 3, backgroundColor: Colors.redAccent),
                    const SizedBox(width: 6),
                    Text(
                      activeMatch.statusText,
                      style: const TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const Row(
                children: [
                  Icon(Icons.wifi_tethering, color: TifoTheme.stadiumCyan, size: 14),
                  SizedBox(width: 4),
                  Text(
                    'بث حي متزامن ⚡',
                    style: TextStyle(color: TifoTheme.stadiumCyan, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(activeMatch.homeLogo, style: const TextStyle(fontSize: 26)),
              const SizedBox(width: 6),
              Text(
                activeMatch.homeTeam,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text('🆚', style: TextStyle(fontSize: 18)),
              ),
              Text(
                activeMatch.awayTeam,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(width: 6),
              Text(activeMatch.awayLogo, style: const TextStyle(fontSize: 26)),
            ],
          ),
          const SizedBox(height: 6),
          Center(
            child: Text(
              '${activeMatch.stadiumName} • بث التيفو نشط الآن 🏟️',
              style: const TextStyle(color: Colors.white60, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}
