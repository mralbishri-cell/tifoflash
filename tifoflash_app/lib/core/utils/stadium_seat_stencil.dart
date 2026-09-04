/// Stadium Seat Stencil Engine
/// Converts Arabic and Latin characters into a 6-Row x 10-Seat geometric matrix
/// so that thousands of fan seats collectively spell out the word across stadium stands.
class StadiumSeatStencil {
  /// Checks if a seat at (row: 1..6, seat: 1..10) is part of the character stroke
  /// Row 1 = Front/Bottom row, Row 6 = Top row
  /// Seat 1 = Left side, Seat 10 = Right side
  static bool isSeatOnStroke(String character, int row, int seat) {
    if (character.isEmpty) return false;
    final r = row.clamp(1, 6);
    final s = seat.clamp(1, 10);
    final ch = character.trim();

    // ── Arabic Letter Stencils ──
    // 1. أ / ا / إ / آ (Alif)
    if (ch == 'ا' || ch == 'أ' || ch == 'إ' || ch == 'آ') {
      return (s == 5 || s == 6) && (r >= 1 && r <= 6);
    }

    // 2. ل (Lam)
    if (ch == 'ل') {
      final isVerticalStem = (s == 7 || s == 8) && (r >= 1 && r <= 6);
      final isHorizontalBase = (r == 1 || r == 2) && (s >= 3 && s <= 8);
      final isLeftCurl = (s == 3) && (r == 2 || r == 3);
      return isVerticalStem || isHorizontalBase || isLeftCurl;
    }

    // 3. س / ش (Seen / Sheen)
    if (ch == 'س' || ch == 'ش') {
      final isBase = (r == 2) && (s >= 2 && s <= 9);
      final isRightTooth = (s == 8 || s == 9) && (r >= 2 && r <= 4);
      final isMidTooth = (s == 5 || s == 6) && (r >= 2 && r <= 4);
      final isLeftTooth = (s == 2 || s == 3) && (r >= 2 && r <= 4);
      final isSheenDots = ch == 'ش' && (r == 6) && (s >= 4 && s <= 7);
      return isBase || isRightTooth || isMidTooth || isLeftTooth || isSheenDots;
    }

    // 4. ع / غ (Ain / Ghain)
    if (ch == 'ع' || ch == 'غ') {
      final isTopArch = (r == 5) && (s >= 5 && s <= 8);
      final isTopRight = (s == 8) && (r == 4);
      final isMidDivider = (r == 3) && (s >= 4 && s <= 7);
      final isBottomBelly = (r == 1) && (s >= 2 && s <= 8);
      final isBottomLeft = (s == 2) && (r == 2);
      final isGhainDot = ch == 'غ' && (r == 6) && (s == 6 || s == 7);
      return isTopArch || isTopRight || isMidDivider || isBottomBelly || isBottomLeft || isGhainDot;
    }

    // 5. و / ؤ (Waw)
    if (ch == 'و' || ch == 'ؤ') {
      final isHeadLoop = (r >= 4 && r <= 5) && (s >= 5 && s <= 8);
      final isNeck = (r == 3) && (s == 6 || s == 7);
      final isTail = (r == 2 && (s == 4 || s == 5)) || (r == 1 && (s == 2 || s == 3));
      return isHeadLoop || isNeck || isTail;
    }

    // 6. د / ذ (Dal / Dhal)
    if (ch == 'د' || ch == 'ذ') {
      final isSlantBack = (s == 7 || s == 8) && (r >= 2 && r <= 5);
      final isTopTip = (r == 5) && (s >= 6 && s <= 8);
      final isBottomLine = (r == 1 || r == 2) && (s >= 3 && s <= 8);
      final isDhalDot = ch == 'ذ' && (r == 6) && (s == 7);
      return isSlantBack || isTopTip || isBottomLine || isDhalDot;
    }

    // 7. ي / ى / ئ (Yaa)
    if (ch == 'ي' || ch == 'ى' || ch == 'ئ') {
      final isTopWave = (r == 5) && (s >= 5 && s <= 8);
      final isSpine = (s == 5) && (r == 4);
      final isBottomBowl = (r == 2) && (s >= 3 && s <= 8);
      final isLeftUp = (s == 3) && (r == 3);
      final isDots = ch == 'ي' && (r == 1) && (s == 4 || s == 7);
      return isTopWave || isSpine || isBottomBowl || isLeftUp || isDots;
    }

    // 8. ة / ه (Taa Marbuta / Haa)
    if (ch == 'ة' || ch == 'ه') {
      final isOuterBox = ((r == 2 || r == 5) && (s >= 4 && s <= 8)) ||
                         ((s == 4 || s == 8) && (r >= 2 && r <= 5));
      final isTaaDots = ch == 'ة' && (r == 6) && (s == 5 || s == 7);
      return isOuterBox || isTaaDots;
    }

    // 9. ن (Noon)
    if (ch == 'ن') {
      final isBowl = ((r == 1) && (s >= 3 && s <= 8)) ||
                     ((s == 3 || s == 8) && (r >= 2 && r <= 4));
      final isCenterDot = (r == 4 || r == 5) && (s == 5 || s == 6);
      return isBowl || isCenterDot;
    }

    // 10. م (Meem)
    if (ch == 'م') {
      final isHead = (r >= 4 && r <= 5) && (s >= 5 && s <= 8);
      final isDescender = (s == 3 || s == 4) && (r >= 1 && r <= 4);
      return isHead || isDescender;
    }

    // 11. ر / ز (Raa / Zay)
    if (ch == 'ر' || ch == 'ز') {
      final isArc = (r == 4 && (s == 7 || s == 8)) ||
                    (r == 3 && (s == 6 || s == 7)) ||
                    (r == 2 && (s == 4 || s == 5)) ||
                    (r == 1 && (s == 2 || s == 3));
      final isZayDot = ch == 'ز' && (r == 5) && (s == 7);
      return isArc || isZayDot;
    }

    // 12. ب / ت / ث (Baa / Taa / Thaa)
    if (ch == 'ب' || ch == 'ت' || ch == 'ث') {
      final isPlate = (r == 2) && (s >= 2 && s <= 9);
      final isRightEnd = (s == 9) && (r >= 2 && r <= 3);
      final isLeftEnd = (s == 2) && (r >= 2 && r <= 3);
      final isBaaDot = ch == 'ب' && (r == 1) && (s == 5 || s == 6);
      final isTaaDots = ch == 'ت' && (r == 4) && (s == 4 || s == 7);
      final isThaaDots = ch == 'ث' && (r >= 4 && r <= 5) && (s >= 4 && s <= 7);
      return isPlate || isRightEnd || isLeftEnd || isBaaDot || isTaaDots || isThaaDots;
    }

    // 13. ف / ق (Faa / Qaaf)
    if (ch == 'ف' || ch == 'ق') {
      final isHead = (r >= 4 && r <= 5) && (s >= 6 && s <= 9);
      final isPlate = (r == 2) && (s >= 2 && s <= 7);
      final isDots = (r == 6) && (s == 7 || s == 8);
      return isHead || isPlate || isDots;
    }

    // 14. ك (Kaaf)
    if (ch == 'ك') {
      final isStem = (s == 8 || s == 9) && (r >= 2 && r <= 6);
      final isBase = (r == 2) && (s >= 2 && s <= 8);
      final isInnerHamza = (r == 4) && (s == 5 || s == 6);
      return isStem || isBase || isInnerHamza;
    }

    // 15. ح / ج / خ (Haa / Jeem / Khaa)
    if (ch == 'ح' || ch == 'ج' || ch == 'خ') {
      final isBrow = (r == 5) && (s >= 3 && s <= 8);
      final isNose = (s == 8) && (r == 4);
      final isBelly = (r == 1 || r == 2) && (s >= 2 && s <= 8);
      final isJeemDot = ch == 'ج' && (r == 2) && (s == 5);
      final isKhaaDot = ch == 'خ' && (r == 6) && (s == 6);
      return isBrow || isNose || isBelly || isJeemDot || isKhaaDot;
    }

    // 16. ص / ض (Saad / Dhad)
    if (ch == 'ص' || ch == 'ض') {
      final isLoop = (r >= 3 && r <= 4) && (s >= 4 && s <= 9);
      final isTooth = (s == 3) && (r >= 2 && r <= 4);
      final isBase = (r == 2) && (s >= 2 && s <= 9);
      final isDhadDot = ch == 'ض' && (r == 5) && (s == 6 || s == 7);
      return isLoop || isTooth || isBase || isDhadDot;
    }

    // 17. ط / ظ (Taa / Zhaa)
    if (ch == 'ط' || ch == 'ظ') {
      final isStaff = (s == 5) && (r >= 2 && r <= 6);
      final isLoop = (r >= 2 && r <= 3) && (s >= 4 && s <= 9);
      final isZhaaDot = ch == 'ظ' && (r == 6) && (s == 6);
      return isStaff || isLoop || isZhaaDot;
    }

    // ── Latin Letter Stencils (A-Z) ──
    final upper = ch.toUpperCase();
    if (upper == 'T') {
      return (r == 6 && s >= 2 && s <= 9) || (s == 5 || s == 6);
    }
    if (upper == 'I') {
      return (r == 6 && s >= 3 && s <= 8) || (r == 1 && s >= 3 && s <= 8) || (s == 5 || s == 6);
    }
    if (upper == 'F') {
      return (s == 3 || s == 4) || (r == 6 && s >= 3 && s <= 8) || (r == 4 && s >= 3 && s <= 7);
    }
    if (upper == 'O' || upper == '0') {
      return ((r == 1 || r == 6) && s >= 4 && s <= 7) || ((s == 3 || s == 8) && r >= 2 && r <= 5);
    }
    if (upper == 'S') {
      return (r == 6 && s >= 3 && s <= 8) ||
             (r == 5 && (s == 3 || s == 4)) ||
             (r == 4 && s >= 3 && s <= 8) ||
             (r == 2 && (s == 7 || s == 8)) ||
             (r == 1 && s >= 3 && s <= 8);
    }
    if (upper == 'A') {
      return (r == 6 && s >= 4 && s <= 7) ||
             ((s == 3 || s == 8) && r >= 1 && r <= 5) ||
             (r == 3 && s >= 3 && s <= 8);
    }
    if (upper == 'U') {
      return ((s == 3 || s == 8) && r >= 2 && r <= 6) || (r == 1 && s >= 4 && s <= 7);
    }
    if (upper == 'D') {
      return (s == 3 || s == 4) ||
             ((r == 1 || r == 6) && s >= 4 && s <= 7) ||
             ((s == 8) && r >= 2 && r <= 5);
    }

    // Generic fallback: alternating diagonal mosaic pattern for any unspecified symbol
    return (r + s) % 2 == 0;
  }
}
