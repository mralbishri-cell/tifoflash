import 'package:flutter/material.dart';
import '../../../core/models/stadium_sector.dart';
import '../../../core/theme/tifo_theme.dart';
import 'widgets/chant_lyrics_widget.dart';

class StadiumGuideScreen extends StatefulWidget {
  const StadiumGuideScreen({super.key});

  @override
  State<StadiumGuideScreen> createState() => _StadiumGuideScreenState();
}

class _StadiumGuideScreenState extends State<StadiumGuideScreen> {
  StadiumProfile _selectedStadium = PresetStadiumData.kingdomArena;
  int _activeTab = 0; // 0 = Gates & Map, 1 = Chants Library, 2 = Safety Info

  final List<Map<String, String>> _chants = [
    {
      'title': 'أهازيج الموج الأزرق 🌊',
      'team': 'الهلال',
      'lines': 'أووووه أووووه يا هلالي 💙\nفي كل ملعب رايتك عالية ⭐\nباسمك نغني في كل المدرجات 🔥',
    },
    {
      'title': 'أهازيج العميد والجمهور 🟡',
      'team': 'الاتحاد',
      'lines': 'يا اتي يا عميد ناديك في القلب 💛\nجمهورك معاك في الشدة والرخاء 🐯\nوالتيفو يضيء بكامل المدرج ✨',
    },
    {
      'title': 'أهازيج العالمي والذهب 🟡',
      'team': 'النصر',
      'lines': 'يا عالمي رايتك شموخ وفخر 🏆\nصوتنا يدوي في كل الملاعب ⭐\nوالفلاش يتلألأ في سماء الرياض 🔥',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TifoTheme.darkBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.map_outlined, color: Color(0xFFF59E0B), size: 22),
            SizedBox(width: 8),
            Text(
              'دليل الملعب والأهازيج (Stadium Guide)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Header Segmented Tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              decoration: BoxDecoration(
                color: TifoTheme.cardSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: TifoTheme.cardBorder),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildSegmentButton(0, 'خريطة البوابات 🗺️'),
                  ),
                  Expanded(
                    child: _buildSegmentButton(1, 'أهازيج المدرج 🎵'),
                  ),
                  Expanded(
                    child: _buildSegmentButton(2, 'إرشادات السلامة ⚠️'),
                  ),
                ],
              ),
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: _activeTab == 0
                  ? _buildGatesAndMapSection()
                  : _activeTab == 1
                      ? _buildChantsSection()
                      : _buildSafetySection(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentButton(int index, String label) {
    final bool isSelected = _activeTab == index;
    return GestureDetector(
      onTap: () => setState(() => _activeTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? TifoTheme.stadiumCyan : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white70,
            fontWeight: FontWeight.bold,
            fontSize: 11.5,
          ),
        ),
      ),
    );
  }

  Widget _buildGatesAndMapSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Stadium Picker
        DropdownButtonFormField<StadiumProfile>(
          initialValue: _selectedStadium,
          dropdownColor: TifoTheme.cardSurface,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
          decoration: InputDecoration(
            filled: true,
            fillColor: TifoTheme.cardSurface,
            labelText: 'اختر الملعب للاستعراض 🏟️',
            labelStyle: const TextStyle(color: TifoTheme.stadiumCyan),
            prefixIcon: const Icon(Icons.stadium, color: TifoTheme.stadiumCyan),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
          items: PresetStadiumData.allStadiums.map((stadium) {
            return DropdownMenuItem<StadiumProfile>(
              value: stadium,
              child: Text('${stadium.nameAr} (${stadium.cityAr})'),
            );
          }).toList(),
          onChanged: (s) => setState(() => _selectedStadium = s!),
        ),

        const SizedBox(height: 16),

        // Interactive Stadium Map Card
        Container(
          width: double.infinity,
          height: 220,
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: TifoTheme.stadiumGreen.withValues(alpha: 0.5)),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Pitch Outline Graphic
              Container(
                width: 140,
                height: 90,
                decoration: BoxDecoration(
                  color: const Color(0xFF064E3B),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white30, width: 2),
                ),
                child: const Center(
                  child: Text(
                    '⚽ أرض الملعب',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ),

              // North Stand Pin
              Positioned(
                top: 16,
                child: _buildSectorPin('المدرج الشمالي (N)', Colors.cyan),
              ),

              // South Stand Pin
              Positioned(
                bottom: 16,
                child: _buildSectorPin('المدرج الجنوبي (S)', Colors.amber),
              ),

              // East Stand Pin
              Positioned(
                right: 12,
                child: _buildSectorPin('الواجهة الشرقية (E)', TifoTheme.stadiumGreen),
              ),

              // West Stand Pin
              Positioned(
                left: 12,
                child: _buildSectorPin('المنصة الغربية (W)', Colors.purpleAccent),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Gates & Amenities Cards
        const Text('خدمات وبوابات الملعب 🚪', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 8),

        _buildServiceTile(Icons.door_sliding_outlined, 'بوابات الدخول الرئيسية', 'بوابة 1-4 للعائلات • بوابة 5-8 للأفراد'),
        _buildServiceTile(Icons.local_parking_rounded, 'مواقف السيارات', 'مواقف A و B متاحة لحاملي التذاكر الرقمية'),
        _buildServiceTile(Icons.fastfood_rounded, 'منطقة المأكولات والمشروبات', 'متوفرة خلف القطاعات 102، 106، 204'),
        _buildServiceTile(Icons.medical_services_outlined, 'العيادة والإسعافات الأولية', 'بجوار البوابة الرقمية 3'),
      ],
    );
  }

  Widget _buildSectorPin(String label, Color col) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: col.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: col),
      ),
      child: Text(
        label,
        style: TextStyle(color: col, fontWeight: FontWeight.bold, fontSize: 9.5),
      ),
    );
  }

  Widget _buildServiceTile(IconData icon, String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: TifoTheme.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: TifoTheme.cardBorder),
      ),
      child: Row(
        children: [
          Icon(icon, color: TifoTheme.stadiumCyan, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.5)),
                Text(subtitle, style: const TextStyle(color: Colors.white60, fontSize: 10.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChantsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _chants.map((chant) {
        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          child: ChantLyricsWidget(
            title: chant['title']!,
            lines: chant['lines']!.split('\n'),
            primaryColor: TifoTheme.stadiumCyan,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSafetySection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TifoTheme.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 24),
              SizedBox(width: 8),
              Text(
                'إرشادات السلامة الضوئية (Photosensitivity Advisory) ⚠️',
                style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            '1. يحتوي التطبيق على ومضات ضوئية متكررة واستوروب فلاش مخصص للعروض الجماعية.\n'
            '2. يُنصح الأشخاص الذين يعانون من حساسيات ضوئية أو صرع ضوئي بتقليل سطوع الشاشة.\n'
            '3. لا تقم بتوجيه الفلاش مباشرة إلى أعين المشجعين الآخرين من مسافة قريبة جداً.\n'
            '4. حافظ على ثبات الهاتف بزاوية مائلة نحو الملعب لتحقيق التزامن الأمثل.',
            style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.6),
          ),
        ],
      ),
    );
  }
}
