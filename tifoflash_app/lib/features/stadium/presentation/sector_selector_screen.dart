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
  StadiumSector _selectedSector = PresetStadiumData.sectors.first;
  bool _isSeatMode = false;

  final TextEditingController _rowController = TextEditingController(text: '12');
  final TextEditingController _seatController = TextEditingController(text: '45');

  @override
  void dispose() {
    _rowController.dispose();
    _seatController.dispose();
    super.dispose();
  }

  void _confirmSelectionAndEnterMatch() {
    SyncEngineService().updateFanPlacement(
      sector: _selectedSector,
      seatRow: _isSeatMode ? _rowController.text.trim() : '',
      seatNumber: _isSeatMode ? _seatController.text.trim() : '',
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LiveTifoScreen(
          sector: _selectedSector,
          seatRow: _isSeatMode ? _rowController.text.trim() : '',
          seatNumber: _isSeatMode ? _seatController.text.trim() : '',
        ),
      ),
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
              // Header description
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      TifoTheme.stadiumGreen.withValues(alpha: 0.15),
                      TifoTheme.stadiumCyan.withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: TifoTheme.stadiumGreen.withValues(alpha: 0.3)),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'حدد موقعك في الملعب 🏟️',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'اختر المدرج الذي تجلس فيه للمشاركة في العروض الضوئية التزامنية المباشرة.',
                      style: TextStyle(fontSize: 13, color: Colors.white70),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Placement Mode Toggle (Sector Mode vs Seat Mode)
              Container(
                decoration: BoxDecoration(
                  color: TifoTheme.cardSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: TifoTheme.cardBorder),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isSeatMode = false),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: !_isSeatMode ? TifoTheme.stadiumGreen : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              'المدرج / القطاع (سريع)',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: !_isSeatMode ? Colors.black : Colors.white70,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isSeatMode = true),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _isSeatMode ? TifoTheme.stadiumCyan : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              'الصف والمقعد (دقيق)',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: _isSeatMode ? Colors.black : Colors.white70,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Interactive Sector Selector Grid
              const Text(
                'اختر القطاع / Sector:',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
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
                  itemCount: PresetStadiumData.sectors.length,
                  itemBuilder: (context, index) {
                    final sector = PresetStadiumData.sectors[index];
                    final isSelected = sector.id == _selectedSector.id;

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
                                Text(
                                  sector.nameAr,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: isSelected ? TifoTheme.stadiumGreen : Colors.white,
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
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Optional Seat / Row Inputs if Seat Mode is enabled
              if (_isSeatMode) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: TifoTheme.cardSurface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: TifoTheme.cardBorder),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _rowController,
                          keyboardType: TextInputType.text,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: 'الصف / Row',
                            labelStyle: TextStyle(color: Colors.white70),
                            prefixIcon: Icon(Icons.table_rows, color: TifoTheme.stadiumCyan),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: TifoTheme.stadiumCyan),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: _seatController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: 'المقعد / Seat',
                            labelStyle: TextStyle(color: Colors.white70),
                            prefixIcon: Icon(Icons.event_seat, color: TifoTheme.stadiumCyan),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: TifoTheme.stadiumCyan),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

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
          ),
        ),
      ),
    );
  }
}
