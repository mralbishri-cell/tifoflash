import 'package:flutter_test/flutter_test.dart';
import 'package:tifoflash_app/core/services/sync_engine_service.dart';

void main() {
  group('ActiveMatchInfo Deep Verification Tests', () {
    test('Correctly parses team names and emojis from Firebase Map', () {
      final firebaseData = {
        'home_team': 'الاتحاد',
        'home_logo': '🐅',
        'away_team': 'الأهلي',
        'away_logo': '🟢',
        'stadium_name': 'مدينة الملك عبد الله (الجوهرة المشعة)',
        'status_text': 'مباشر الان 🔥',
        'is_live': true,
      };

      final info = ActiveMatchInfo.fromMap(firebaseData);

      expect(info.homeTeam, equals('الاتحاد'));
      expect(info.homeLogo, equals('🐅'));
      expect(info.awayTeam, equals('الأهلي'));
      expect(info.awayLogo, equals('🟢'));
      expect(info.stadiumName, equals('مدينة الملك عبد الله (الجوهرة المشعة)'));
      expect(info.statusText, equals('مباشر الان 🔥'));
      expect(info.isLive, isTrue);
    });

    test('Correctly supports network image URLs for logos', () {
      final firebaseDataWithUrl = {
        'home_team': 'ريال مدريد',
        'home_logo': 'https://example.com/real_madrid_logo.png',
        'away_team': 'برشلونة',
        'away_logo': 'https://example.com/barcelona_logo.png',
        'stadium_name': 'استاد سانتياغو برنابيو',
        'status_text': 'الشوط الأول',
        'is_live': true,
      };

      final info = ActiveMatchInfo.fromMap(firebaseDataWithUrl);

      expect(info.homeTeam, equals('ريال مدريد'));
      expect(info.homeLogo, equals('https://example.com/real_madrid_logo.png'));
      expect(info.awayTeam, equals('برشلونة'));
      expect(info.awayLogo, equals('https://example.com/barcelona_logo.png'));
    });

    test('Equality operator detects when logos or team names change', () {
      final info1 = ActiveMatchInfo(
        homeTeam: 'الهلال',
        homeLogo: '⚽',
        awayTeam: 'النصر',
        awayLogo: '🏆',
      );

      final info2 = ActiveMatchInfo(
        homeTeam: 'الهلال',
        homeLogo: '🔵', // Only logo changed!
        awayTeam: 'النصر',
        awayLogo: '🏆',
      );

      expect(info1 == info2, isFalse);
    });

    test('Correctly handles Concert / Festival Mode with single event title and empty away team', () {
      final concertData = {
        'home_team': 'حفل موسم الرياض الغنائي 🎵',
        'home_logo': '🎵',
        'away_team': '',
        'away_logo': '',
        'stadium_name': 'مسرح محمد عبده أرينا (بوليفارد سيتي)',
        'status_text': 'العرض الضوئي المباشر نشط الآن ⚡',
        'is_live': true,
      };

      final info = ActiveMatchInfo.fromMap(concertData);

      expect(info.homeTeam, equals('حفل موسم الرياض الغنائي 🎵'));
      expect(info.homeLogo, equals('🎵'));
      expect(info.awayTeam, isEmpty);
      expect(info.awayLogo, isEmpty);
      expect(info.stadiumName, equals('مسرح محمد عبده أرينا (بوليفارد سيتي)'));
    });
  });
}
