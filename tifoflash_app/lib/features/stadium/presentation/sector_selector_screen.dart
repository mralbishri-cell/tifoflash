import 'package:flutter/material.dart';
import '../../../core/models/stadium_sector.dart';
import '../../../core/services/sync_engine_service.dart';
import '../../../core/theme/tifo_theme.dart';
import 'live_tifo_screen.dart';

class SectorSelectorScreen extends StatefulWidget {
  const SectorSelectorScreen({super.key});

  @override
  State<SectorSelectorScreen> createState() => _SectorSelectorScreenState();
}

class _SectorSelectorScreenState extends State<SectorSelectorScreen> {
  StadiumProfile? _selectedStadium;
  StadiumSector? _selectedSector;
  final TextEditingController _rowController = TextEditingController(text: '12');
  final TextEditingController _seatController = TextEditingController(text: '45');

  // Placement Modes: 0 = Auto Smart Sync, 1 = Sector Fast Mode, 2 = Manual Seat Mode
  final int _placementMode = 2;

  @override
  void initState() {
    super.initState();
  }

  void _autoAssignSector() {
    if (_selectedStadium == null) return;
    final hashIndex = DateTime.now().microsecondsSinceEpoch % _selectedStadium!.sectors.length;
    _selectedSector = _selectedStadium!.sectors[hashIndex];
  }

  @override
  void dispose() {
    _rowController.dispose();
    _seatController.dispose();
    super.dispose();
  }

  void _confirmSelectionAndEnterMatch() {
    if (_selectedStadium == null || _selectedSector == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ يرجى اختيار الملعب أولاً لتحديد موقعك بدون أخطاء'),
          backgroundColor: Colors.amber,
        ),
      );
      return;
    }

    final row = _placementMode == 2 ? _rowController.text.trim() : '';
    final seat = _placementMode == 2 ? _seatController.text.trim() : '';

    SyncEngineService().updateFanPlacement(
      sector: _selectedSector!,
      seatRow: row,
      seatNumber: seat,
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LiveTifoScreen(
          sector: _selectedSector!,
          seatRow: row,
          seatNumber: seat,
        ),
      ),
    );
  }

  void _instantAutoJoin() {
    if (_selectedStadium == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ يرجى اختيار الملعب من القائمة أولاً لتأكيد حضورك'),
          backgroundColor: Colors.amber,
        ),
      );
      return;
    }
    _autoAssignSector();
    _confirmSelectionAndEnterMatch();
  }

  void _showQRScannerModal() {
    if (_selectedStadium == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ يرجى اختيار الملعب من القائمة المنسدلة أولاً قبل مسح التذكرة'),
          backgroundColor: Colors.amber,
        ),
      );
      return;
    }

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
                        'كاميرا مسح التذكرة والـ QR Code 🎟️',
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

                  // Camera Viewfinder Box
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: TifoTheme.stadiumCyan.withValues(alpha: 0.8), width: 2),
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
                                ? const Center(
                                    child: CircularProgressIndicator(color: TifoTheme.stadiumCyan),
                                  )
                                : const Icon(Icons.check_circle_rounded, color: TifoTheme.stadiumGreen, size: 60),
                          ),
                          Positioned(
                            bottom: 16,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.black87,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'جاري فك تشفير التذكرة وتأكيد الكود...',
                                style: TextStyle(color: TifoTheme.stadiumCyan, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Simulate Camera Scan Confirmation Button
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
                            _selectedSector = _selectedStadium!.sectors.first;
                            _rowController.text = '14';
                            _seatController.text = '28';
                          });
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text('تم مسح التذكرة بنجاح: ${_selectedSector!.nameAr} • صف 14 • مقعد 28 🎟️'),
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
    return Scaffold(
      backgroundColor: TifoTheme.darkBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  colors: [
                    Color(0xFF10B981),
                    Color(0xFF06B6D4),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10B981).withValues(alpha: 0.6),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: const Icon(
                Icons.bolt,
                color: Colors.black,
                size: 20,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'TIFO FLASH',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dropdown Stadium Selection
              const Text(
                'اختر ملعب المباراة الحالية 🏟️:',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
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
                  hintText: '-- اختر الملعب أولاً لتحديد موقعك --',
                  hintStyle: const TextStyle(color: Colors.white54, fontSize: 12.5),
                  prefixIcon: const Icon(Icons.stadium, color: TifoTheme.stadiumCyan),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: TifoTheme.cardBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: _selectedStadium != null ? TifoTheme.stadiumCyan : TifoTheme.cardBorder,
                      width: _selectedStadium != null ? 2 : 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: TifoTheme.stadiumCyan, width: 2),
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
                  setState(() {
                    _selectedStadium = newStadium;
                    if (newStadium != null) {
                      _selectedSector = newStadium.sectors.first;
                    } else {
                      _selectedSector = null;
                    }
                  });
                },
              ),
              const SizedBox(height: 14),

              // Locked state until stadium is selected
              if (_selectedStadium == null) ...[
                Expanded(
                  child: Center(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: TifoTheme.cardSurface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.lock_outline_rounded, color: Colors.amber, size: 44),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'تحديد الموقع مقفل 🔒',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'الرجاء اختيار الملعب أولاً من القائمة المنسدلة أعلاه، لتجنب اختيار موقع أو مدرج في ملعب آخر عن طريق الخطأ.',
                            style: TextStyle(color: Colors.white70, fontSize: 12.5, height: 1.4),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 14),
                          OutlinedButton.icon(
                            onPressed: () {
                              setState(() {
                                _selectedStadium = PresetStadiumData.kingdomArena;
                                _selectedSector = PresetStadiumData.kingdomArena.sectors.first;
                              });
                              _confirmSelectionAndEnterMatch();
                            },
                            icon: const Icon(Icons.science, color: TifoTheme.stadiumCyan, size: 18),
                            label: const Text(
                              '🧪 وضع المعاينة والتجربة لمراجعي أبل (Apple Reviewer Demo Mode)',
                              style: TextStyle(color: TifoTheme.stadiumCyan, fontWeight: FontWeight.bold, fontSize: 11),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: TifoTheme.stadiumCyan),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ] else ...[
                // Dropdown Sector Selection
                const Text(
                  'اختر القطاع / Sector 🎟️:',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
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
                    hintText: '-- اختر القطاع من القائمة المنسدلة --',
                    hintStyle: const TextStyle(color: Colors.white54, fontSize: 12.5),
                    prefixIcon: const Icon(Icons.stadium_outlined, color: TifoTheme.stadiumGreen),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: TifoTheme.cardBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: TifoTheme.stadiumGreen, width: 1.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: TifoTheme.stadiumGreen, width: 2),
                    ),
                  ),
                  items: _selectedStadium!.sectors.map((sector) {
                    return DropdownMenuItem<StadiumSector>(
                      value: sector,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '${sector.nameAr} (${sector.standGroup})',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: TifoTheme.stadiumGreen.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              sector.id,
                              style: const TextStyle(color: TifoTheme.stadiumGreen, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (newSector) {
                    setState(() {
                      _selectedSector = newSector;
                    });
                  },
                ),
                const SizedBox(height: 14),

                // Manual Seat & Row Input Card
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: TifoTheme.cardSurface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: TifoTheme.stadiumCyan.withValues(alpha: 0.5)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.event_seat, color: TifoTheme.stadiumCyan, size: 18),
                          SizedBox(width: 6),
                          Text(
                            'رقم المقعد والصف (اختياري):',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
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
                                hintText: 'مثال: 14',
                                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                                prefixIcon: const Icon(Icons.table_rows, color: TifoTheme.stadiumCyan),
                                filled: true,
                                fillColor: Colors.black26,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: Colors.white24),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: TifoTheme.stadiumCyan),
                                ),
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
                                hintText: 'مثال: 28',
                                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                                prefixIcon: const Icon(Icons.event_seat, color: TifoTheme.stadiumCyan),
                                filled: true,
                                fillColor: Colors.black26,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: Colors.white24),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: TifoTheme.stadiumCyan),
                                ),
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
                            '📷 مسح التذكرة تلقائياً بواسطة الكاميرا (QR Scan)',
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
                const Spacer(),

                // 1-Click Instant Auto-Join Banner
                GestureDetector(
                  onTap: _instantAutoJoin,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF10B981), Color(0xFF06B6D4)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF10B981).withValues(alpha: 0.35),
                          blurRadius: 15,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: const Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.black,
                          radius: 18,
                          child: Icon(Icons.bolt, color: Color(0xFF10B981), size: 22),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '⚡ الدخول الفوري بالتوزيع التلقائي الذكي',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                'توزيع تلقائي متوازن بنقرة واحدة بدون تحديد يدوي',
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios, color: Colors.black, size: 16),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Confirm and Launch Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _confirmSelectionAndEnterMatch,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TifoTheme.stadiumGreen,
                      foregroundColor: Colors.black,
                      elevation: 6,
                      shadowColor: TifoTheme.stadiumGreen.withValues(alpha: 0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.bolt, color: Colors.black, size: 22),
                        SizedBox(width: 8),
                        Text(
                          'دخول وضع العرض المباشر (LIVE MODE)',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
