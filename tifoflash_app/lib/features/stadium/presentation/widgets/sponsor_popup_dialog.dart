import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/models/tifo_action_payload.dart';
import '../../../../core/theme/tifo_theme.dart';

class SponsorPopupDialog extends StatefulWidget {
  final List<SponsorInfo> sponsors;
  final VoidCallback onClose;

  const SponsorPopupDialog({
    super.key,
    required this.sponsors,
    required this.onClose,
  });

  @override
  State<SponsorPopupDialog> createState() => _SponsorPopupDialogState();
}

class _SponsorPopupDialogState extends State<SponsorPopupDialog> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sponsorList = widget.sponsors.isNotEmpty
        ? widget.sponsors
        : [
            const SponsorInfo(
              title: 'عرض خاص من الراعي الرسمي',
              imageUrl: '',
              couponCode: 'MATCH2026',
              linkUrl: '',
            )
          ];
    final bool isMulti = sponsorList.length > 1;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: TifoTheme.cardSurface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: TifoTheme.stadiumGold, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: TifoTheme.stadiumGold.withValues(alpha: 0.3),
              blurRadius: 30,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Header: Badge + Multi-indicator + Close
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: TifoTheme.stadiumGold.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.stars, color: TifoTheme.stadiumGold, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        isMulti ? 'عروض الرعاة الرسميين (${_currentPage + 1}/${sponsorList.length})' : 'هدية الراعي الرسمي',
                        style: const TextStyle(
                          color: TifoTheme.stadiumGold,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70),
                  onPressed: widget.onClose,
                ),
              ],
            ),

            const SizedBox(height: 12),

            // PageView for Multi-Sponsors
            SizedBox(
              height: 310,
              child: PageView.builder(
                controller: _pageController,
                itemCount: sponsorList.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  final sponsor = sponsorList[index];
                  return _buildSponsorCard(sponsor);
                },
              ),
            ),

            // Dots Indicator & Next/Prev Controls if Multi-Sponsor
            if (isMulti) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white70, size: 16),
                    onPressed: _currentPage > 0
                        ? () => _pageController.previousPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            )
                        : null,
                  ),
                  Row(
                    children: List.generate(sponsorList.length, (i) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == i ? 18 : 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: _currentPage == i ? TifoTheme.stadiumGold : Colors.white24,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 16),
                    onPressed: _currentPage < sponsorList.length - 1
                        ? () => _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            )
                        : null,
                  ),
                ],
              ),
            ],

            const SizedBox(height: 12),

            // Close / Return Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: widget.onClose,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'إغلاق والعودة للتيفو',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSponsorCard(SponsorInfo sponsor) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Sponsor Banner Image
          if (sponsor.imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                sponsor.imageUrl,
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 100,
                  color: const Color(0xFF1E293B),
                  child: const Icon(Icons.card_giftcard, size: 48, color: TifoTheme.stadiumGold),
                ),
              ),
            )
          else
            Container(
              height: 100,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF334155), Color(0xFF0F172A)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.local_activity, size: 54, color: TifoTheme.stadiumGold),
            ),

          const SizedBox(height: 14),

          // Offer Title
          Text(
            sponsor.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 14),

          // Coupon Code Box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white24, width: 1),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  sponsor.couponCode.isNotEmpty ? sponsor.couponCode : 'TIFO2026',
                  style: const TextStyle(
                    color: TifoTheme.stadiumCyan,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    letterSpacing: 2,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: sponsor.couponCode));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('تم نسخ كود: ${sponsor.couponCode} 📋'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TifoTheme.stadiumGreen,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.copy, size: 14),
                  label: const Text('نسخ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
