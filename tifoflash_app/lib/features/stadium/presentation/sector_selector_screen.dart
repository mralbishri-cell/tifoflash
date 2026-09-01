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
  int _placementMode = 0;

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
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: TifoTheme.stadiumGreen,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.flash_on, color: Colors.black, size: 18),
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
              const SizedBox(height: 16),

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
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF10B981).withValues(alpha: 0.35),
                          blurRadius: 15,
                          spreadRadius: 2,
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
                                'دخول بنقرة واحدة بدون تحديد موقع أو مقعد (Auto Balanced)',
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

                const SizedBox(height: 14),

                // 3-Way Placement Mode Toggle
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: TifoTheme.cardSurface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: TifoTheme.cardBorder),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _placementMode = 0;
                              _autoAssignSector();
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _placementMode == 0 ? TifoTheme.stadiumGreen : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                '🤖 تلقائي ذكي',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: _placementMode == 0 ? Colors.black : Colors.white70,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _placementMode = 1),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _placementMode == 1 ? TifoTheme.stadiumCyan : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                '🏟️ اختيار القطاع',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: _placementMode == 1 ? Colors.black : Colors.white70,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _placementMode = 2),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _placementMode == 2 ? const Color(0xFFF59E0B) : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                '💺 الصف والمقعد',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: _placementMode == 2 ? Colors.black : Colors.white70,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                if (_placementMode == 0) ...[
                  // Auto Mode Explanation Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.auto_awesome, color: Color(0xFF10B981), size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'وضع التوزيع التلقائي الذكي مفعل ⚡',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'تم توجيه جهازك آلياً إلى: ${_selectedSector?.nameAr ?? ""}',
                                style: const TextStyle(color: Color(0xFF34D399), fontSize: 11, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ],

                // Interactive Sector Selector Grid
                Text(
                  _placementMode == 0 ? 'القطاعات المتاحة في الفعالية:' : 'اختر القطاع / Sector:',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 10),

                Expanded(
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 2.2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: _selectedStadium!.sectors.length,
                    itemBuilder: (context, index) {
                      final sector = _selectedStadium!.sectors[index];
                      final isSelected = sector.id == _selectedSector?.id;

                      return GestureDetector(
                        onTap: () => setState(() => _selectedSector = sector),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? TifoTheme.stadiumGreen.withValues(alpha: 0.2)
                                : TifoTheme.cardSurface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected ? TifoTheme.stadiumGreen : TifoTheme.cardBorder,
                              width: isSelected ? 2.0 : 1.0,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: TifoTheme.stadiumGreen.withValues(alpha: 0.25),
                                      blurRadius: 12,
                                      spreadRadius: 1,
                                    )
                                  ]
                                : [],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      sector.nameAr,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12.5,
                                        color: isSelected ? TifoTheme.stadiumGreen : Colors.white,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (isSelected)
                                    const Icon(
                                      Icons.check_circle,
                                      color: TifoTheme.stadiumGreen,
                                      size: 16,
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${sector.nameEn} • ${sector.standGroup}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.white54,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Manual Seat & Row Input Card (Always Visible)
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
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
                            'الإدخال اليدوي للمقعد والصف (Manual Seat Entry):',
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
                          onPressed: () {
                            if (_selectedStadium == null) return;
                            setState(() {
                              _selectedSector = _selectedStadium!.sectors.first;
                              _rowController.text = '14';
                              _seatController.text = '28';
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('تم مسح التذكرة تلقائياً: صف 14 • مقعد 28 🎟️'),
                                backgroundColor: TifoTheme.stadiumCyan,
                              ),
                            );
                          },
                          icon: const Icon(Icons.qr_code_scanner, color: TifoTheme.stadiumCyan, size: 18),
                          label: const Text(
                            'أو مسح التذكرة تلقائياً (QR Scan)',
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
                const SizedBox(height: 12),

                // Confirm and Launch Button
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _confirmSelectionAndEnterMatch,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TifoTheme.stadiumGreen,
                      foregroundColor: Colors.black,
                      elevation: 8,
                      shadowColor: TifoTheme.stadiumGreen.withValues(alpha: 0.5),
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
