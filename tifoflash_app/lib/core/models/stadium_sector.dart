class StadiumSector {
  final String id;
  final String nameAr;
  final String nameEn;
  final String standGroup; // East, West, North, South, Curve Left, Curve Right
  final int orderIndex; // For wave sequence ordering
  final String assignedChar; // Default tifo letter in banner sequences
  final int totalRows;
  final int seatsPerRow;

  const StadiumSector({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.standGroup,
    required this.orderIndex,
    this.assignedChar = '',
    this.totalRows = 20,
    this.seatsPerRow = 30,
  });
}

class StadiumProfile {
  final String id;
  final String nameAr;
  final String nameEn;
  final String cityAr;
  final String capacity;
  final String homeClub;
  final String primaryColorHex;
  final List<StadiumSector> sectors;

  const StadiumProfile({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.cityAr,
    required this.capacity,
    required this.homeClub,
    required this.primaryColorHex,
    required this.sectors,
  });
}

class PresetStadiumData {
  static const StadiumProfile jawharaStadium = StadiumProfile(
    id: 'stadium_jawhara',
    nameAr: 'مدينة الملك عبد الله الرياضية (الجوهرة)',
    nameEn: 'King Abdullah Sports City Stadium',
    cityAr: 'جدة',
    capacity: '62,241 مقعد بيضاوي 360°',
    homeClub: 'مدرجات المنطقة الغربية (Western Stands)',
    primaryColorHex: '#FFD700',
    sectors: [
      StadiumSector(id: 'JAW_VIP_101', nameAr: 'المنصة الملكية VIP 101', nameEn: 'VIP Royal Box 101', standGroup: 'VIP', orderIndex: 1, assignedChar: '★', totalRows: 15, seatsPerRow: 30),
      StadiumSector(id: 'JAW_VIP_102', nameAr: 'المنصة السفلى 102', nameEn: 'Lower VIP 102', standGroup: 'VIP', orderIndex: 2, assignedChar: 'V', totalRows: 20, seatsPerRow: 35),
      StadiumSector(id: 'JAW_W_104', nameAr: 'المباشر الغربي 104', nameEn: 'West Main 104', standGroup: 'West', orderIndex: 3, assignedChar: 'R', totalRows: 25, seatsPerRow: 40),
      StadiumSector(id: 'JAW_W_105', nameAr: 'الغربي السفلي 105', nameEn: 'West Lower 105', standGroup: 'West', orderIndex: 4, assignedChar: 'O', totalRows: 25, seatsPerRow: 40),
      StadiumSector(id: 'JAW_W_CORNER', nameAr: 'الغربي السفلي 106', nameEn: 'West Corner 106', standGroup: 'West', orderIndex: 5, assignedChar: 'Y', totalRows: 25, seatsPerRow: 40),
      StadiumSector(id: 'JAW_W_107', nameAr: 'الغربي السفلي 107', nameEn: 'West Lower 107', standGroup: 'West', orderIndex: 6, assignedChar: 'A', totalRows: 25, seatsPerRow: 40),
      StadiumSector(id: 'JAW_E_112', nameAr: 'الشرقية السفلى 112', nameEn: 'East Lower 112', standGroup: 'East', orderIndex: 7, assignedChar: 'J', totalRows: 30, seatsPerRow: 50),
      StadiumSector(id: 'JAW_E_114', nameAr: 'الشرقية السفلى 114 ⚽', nameEn: 'East Lower 114', standGroup: 'East', orderIndex: 8, assignedChar: 'A', totalRows: 30, seatsPerRow: 50),
      StadiumSector(id: 'JAW_E_116', nameAr: 'الشرقية السفلى 116', nameEn: 'East Lower 116', standGroup: 'East', orderIndex: 9, assignedChar: 'W', totalRows: 30, seatsPerRow: 50),
      StadiumSector(id: 'JAW_E_312', nameAr: 'الشرقية العليا 312', nameEn: 'East Upper 312', standGroup: 'East', orderIndex: 10, assignedChar: 'H', totalRows: 35, seatsPerRow: 50),
      StadiumSector(id: 'JAW_E_314', nameAr: 'الشرقية العليا 314 ⚽', nameEn: 'East Upper 314', standGroup: 'East', orderIndex: 11, assignedChar: 'A', totalRows: 35, seatsPerRow: 50),
      StadiumSector(id: 'JAW_E_316', nameAr: 'الشرقية العليا 316', nameEn: 'East Upper 316', standGroup: 'East', orderIndex: 12, assignedChar: 'R', totalRows: 35, seatsPerRow: 50),
      StadiumSector(id: 'JAW_N_120', nameAr: 'المدرج الشمالي 120 🔥', nameEn: 'North Stand 120', standGroup: 'North', orderIndex: 13, assignedChar: 'U', totalRows: 30, seatsPerRow: 45),
      StadiumSector(id: 'JAW_N_320', nameAr: 'الشمالي العلوي 320', nameEn: 'North Upper 320', standGroup: 'North', orderIndex: 14, assignedChar: 'N', totalRows: 30, seatsPerRow: 45),
      StadiumSector(id: 'JAW_S_130', nameAr: 'الجنوبي السفلي 130', nameEn: 'South Lower 130', standGroup: 'South', orderIndex: 15, assignedChar: 'S', totalRows: 30, seatsPerRow: 45),
      StadiumSector(id: 'JAW_S_330', nameAr: 'الجنوبي العلوي 330', nameEn: 'South Upper 330', standGroup: 'South', orderIndex: 16, assignedChar: 'G', totalRows: 30, seatsPerRow: 45),
    ],
  );

  static const StadiumProfile kingdomArena = StadiumProfile(
    id: 'stadium_kingdom_arena',
    nameAr: 'أرينا العاصمة المغطاة (Capital Indoor Arena)',
    nameEn: 'Capital Indoor Arena (Riyadh)',
    cityAr: 'الرياض',
    capacity: '30,000 مقعد مغلق بكامل الزوايا 360°',
    homeClub: 'المدرج الأزرق (Blue Stand)',
    primaryColorHex: '#00E5FF',
    sectors: [
      StadiumSector(id: 'KA_BLUE_WALL', nameAr: '🔥 المدرج الشرقي الرئيسي (East Stand S50-S70)', nameEn: 'East Stand S50-S70', standGroup: 'East', orderIndex: 1, assignedChar: 'H', totalRows: 35, seatsPerRow: 70),
      StadiumSector(id: 'KA_VIP_SUITES', nameAr: 'كبائن VVIP & Skyboxes', nameEn: 'VVIP Royal Skyboxes', standGroup: 'VIP', orderIndex: 2, assignedChar: 'I', totalRows: 12, seatsPerRow: 25),
      StadiumSector(id: 'KA_CLUB_VIEW', nameAr: 'مدرج Club View المميز', nameEn: 'Club View Stand', standGroup: 'West', orderIndex: 3, assignedChar: 'C', totalRows: 20, seatsPerRow: 35),
      StadiumSector(id: 'KA_NORTH_STAND', nameAr: 'المدرج الشمالي المغلق (S28–S39)', nameEn: 'North Indoor Stand', standGroup: 'North', orderIndex: 4, assignedChar: 'L', totalRows: 25, seatsPerRow: 40),
      StadiumSector(id: 'KA_SOUTH_STAND', nameAr: 'المدرج الجنوبي (S01–S06)', nameEn: 'South Indoor Stand', standGroup: 'South', orderIndex: 5, assignedChar: 'A', totalRows: 25, seatsPerRow: 40),
      StadiumSector(id: 'KA_CORNER_NW', nameAr: 'الزاوية الشمالية الغربية N-W', nameEn: 'North-West Corner', standGroup: 'North', orderIndex: 6, assignedChar: 'N', totalRows: 20, seatsPerRow: 30),
      StadiumSector(id: 'KA_CORNER_SW', nameAr: 'الزاوية الجنوبية الغربية S-W', nameEn: 'South-West Corner', standGroup: 'South', orderIndex: 7, assignedChar: 'S', totalRows: 20, seatsPerRow: 30),
    ],
  );

  static const StadiumProfile alawwalPark = StadiumProfile(
    id: 'stadium_alawwal_park',
    nameAr: 'استاد العاصمة الدولي (Capital Stadium)',
    nameEn: 'Capital Stadium (Riyadh)',
    cityAr: 'الرياض',
    capacity: '25,000 مقعد مكشوف بكامل الزوايا 360°',
    homeClub: 'المدرج الأصفر (Yellow Stand)',
    primaryColorHex: '#FFD700',
    sectors: [
      StadiumSector(id: 'AP_YELLOW_WALL', nameAr: '🔥 المدرج الشمالي الرئيسي (North Stand CAT 4)', nameEn: 'The North Stand CAT 4', standGroup: 'North', orderIndex: 1, assignedChar: 'N', totalRows: 30, seatsPerRow: 60),
      StadiumSector(id: 'AP_EAST_STAND', nameAr: 'المواجهة الشرقية (CAT 1 Midfield)', nameEn: 'East Stand CAT 1', standGroup: 'East', orderIndex: 2, assignedChar: 'A', totalRows: 25, seatsPerRow: 40),
      StadiumSector(id: 'AP_VIP_CABINS', nameAr: 'كبائن VVIP Platinum Lounge', nameEn: 'VIP Platinum Lounge', standGroup: 'VIP', orderIndex: 3, assignedChar: 'S', totalRows: 12, seatsPerRow: 25),
      StadiumSector(id: 'AP_SOUTH_STAND', nameAr: 'المدرج الجنوبي (CAT 5)', nameEn: 'South Goal Stand CAT 5', standGroup: 'South', orderIndex: 4, assignedChar: 'S', totalRows: 25, seatsPerRow: 40),
      StadiumSector(id: 'AP_WEST_STAND', nameAr: 'المدرج الغربي للعائلات (CAT 2)', nameEn: 'West Family Stand CAT 2', standGroup: 'West', orderIndex: 5, assignedChar: 'R', totalRows: 22, seatsPerRow: 35),
      StadiumSector(id: 'AP_CORNER_NE', nameAr: 'الزاوية الشمالية الشرقية N-E', nameEn: 'North-East Corner', standGroup: 'North', orderIndex: 6, assignedChar: 'E', totalRows: 20, seatsPerRow: 30),
      StadiumSector(id: 'AP_CORNER_SE', nameAr: 'الزاوية الجنوبية الشرقية S-E', nameEn: 'South-East Corner', standGroup: 'South', orderIndex: 7, assignedChar: 'E', totalRows: 20, seatsPerRow: 30),
      StadiumSector(id: 'AP_CORNER_NW', nameAr: 'الزاوية الشمالية الغربية N-W', nameEn: 'North-West Corner', standGroup: 'North', orderIndex: 8, assignedChar: 'W', totalRows: 20, seatsPerRow: 30),
      StadiumSector(id: 'AP_CORNER_SW', nameAr: 'الزاوية الجنوبية الغربية S-W', nameEn: 'South-West Corner', standGroup: 'South', orderIndex: 9, assignedChar: 'W', totalRows: 20, seatsPerRow: 30),
    ],
  );

  static const StadiumProfile aramcoStadium = StadiumProfile(
    id: 'stadium_aramco',
    nameAr: 'استاد المنطقة الشرقية الجديد (Eastern Province Arena)',
    nameEn: 'Eastern Province Arena (Khobar)',
    cityAr: 'الخبر / المنطقة الشرقية',
    capacity: '47,000 مقعد تحفة معمارية 360°',
    homeClub: 'المنطقة الشرقية (Eastern Province)',
    primaryColorHex: '#00F5D4',
    sectors: [
      StadiumSector(id: 'ARM_VIP_SKYBOX', nameAr: 'كبائن المقصورة VVIP Skyboxes', nameEn: 'VVIP Skyboxes', standGroup: 'VIP', orderIndex: 1, assignedChar: 'A', totalRows: 15, seatsPerRow: 30),
      StadiumSector(id: 'ARM_EAST_PITCH', nameAr: 'المواجهة الشرقية البانورامية (CAT 1)', nameEn: 'East Panoramic Stand CAT 1', standGroup: 'East', orderIndex: 2, assignedChar: 'R', totalRows: 30, seatsPerRow: 55),
      StadiumSector(id: 'ARM_NORTH_WAVE', nameAr: 'مدرج الدوامة الشمالي (CAT 2 Wave)', nameEn: 'North Spiral Wave Stand CAT 2', standGroup: 'North', orderIndex: 3, assignedChar: 'A', totalRows: 28, seatsPerRow: 50),
      StadiumSector(id: 'ARM_SOUTH_ULTRAS', nameAr: '🔥 مدرج الشرقية الجنوبي (CAT 3)', nameEn: 'South Stand CAT 3', standGroup: 'South', orderIndex: 4, assignedChar: 'M', totalRows: 30, seatsPerRow: 55),
      StadiumSector(id: 'ARM_WEST_STAND', nameAr: 'المدرج الغربي الرئيسي (CAT 1)', nameEn: 'West Main Stand CAT 1', standGroup: 'West', orderIndex: 5, assignedChar: 'C', totalRows: 28, seatsPerRow: 50),
      StadiumSector(id: 'ARM_CORNER_NE', nameAr: 'زاوية دوامة الخليج N-E', nameEn: 'Gulf Spiral Corner N-E', standGroup: 'North', orderIndex: 6, assignedChar: 'O', totalRows: 20, seatsPerRow: 35),
      StadiumSector(id: 'ARM_CORNER_SE', nameAr: 'زاوية دوامة الخليج S-E', nameEn: 'Gulf Spiral Corner S-E', standGroup: 'South', orderIndex: 7, assignedChar: 'S', totalRows: 20, seatsPerRow: 35),
      StadiumSector(id: 'ARM_CORNER_NW', nameAr: 'زاوية دوامة الخليج N-W', nameEn: 'Gulf Spiral Corner N-W', standGroup: 'North', orderIndex: 8, assignedChar: 'T', totalRows: 20, seatsPerRow: 35),
      StadiumSector(id: 'ARM_CORNER_SW', nameAr: 'زاوية دوامة الخليج S-W', nameEn: 'Gulf Spiral Corner S-W', standGroup: 'South', orderIndex: 9, assignedChar: 'A', totalRows: 20, seatsPerRow: 35),
    ],
  );

  static const StadiumProfile openEventHall = StadiumProfile(
    id: 'stadium_open_hall',
    nameAr: '🎪 صالة الفعاليات والمسارح المفتوحة (Open Arena & Hall)',
    nameEn: 'Open Event Arena & Hall (Free Roam)',
    cityAr: 'فعاليات حرة / صالات مغلقة / مسارح',
    capacity: 'سعة مفتوحة حرة (بدون مقاعد)',
    homeClub: 'الفعاليات والمهرجانات والمعارض',
    primaryColorHex: '#EC4899',
    sectors: [
      StadiumSector(id: 'HALL_STAGE', nameAr: '🎤 منصة المسرح والعرض (Main Stage)', nameEn: 'Main Stage & Screen', standGroup: 'North', orderIndex: 1, assignedChar: '★', totalRows: 1, seatsPerRow: 1),
      StadiumSector(id: 'HALL_ZONE_LEFT', nameAr: '👈 يسار الصالة (Zone A - Left Area)', nameEn: 'Left Wing Area', standGroup: 'West', orderIndex: 2, assignedChar: 'L', totalRows: 1, seatsPerRow: 1),
      StadiumSector(id: 'HALL_ZONE_CENTER', nameAr: '⭐ قلب الصالة والساحة الحرة (Central Floor)', nameEn: 'Central Floor Arena', standGroup: 'East', orderIndex: 3, assignedChar: 'C', totalRows: 1, seatsPerRow: 1),
      StadiumSector(id: 'HALL_ZONE_RIGHT', nameAr: '👉 يمين الصالة (Zone C - Right Area)', nameEn: 'Right Wing Area', standGroup: 'East', orderIndex: 4, assignedChar: 'R', totalRows: 1, seatsPerRow: 1),
      StadiumSector(id: 'HALL_VIP_LOUNGE', nameAr: '👑 كبار الشخصيات والضيوف (VIP Lounge)', nameEn: 'VIP & Guests Lounge', standGroup: 'VIP', orderIndex: 5, assignedChar: 'V', totalRows: 1, seatsPerRow: 1),
      StadiumSector(id: 'HALL_BACK_STAND', nameAr: '🚪 المنطقة الخلفية والمداخل (Rear Entry)', nameEn: 'Rear & Gate Area', standGroup: 'South', orderIndex: 6, assignedChar: 'B', totalRows: 1, seatsPerRow: 1),
    ],
  );

  static const StadiumProfile outdoorPlaza = StadiumProfile(
    id: 'stadium_outdoor_plaza',
    nameAr: '🌲 الساحة الخارجية المفتوحة ومنطقة المشجعين (Outdoor Fan Zone & Plaza)',
    nameEn: 'Outdoor Open Plaza & Fan Zone (Sky Light)',
    cityAr: 'ساحات مفتوحة بالهواء الطلق / بوليفارد / Fan Zones',
    capacity: 'سعة غير محدودة بالهواء الطلق 360°',
    homeClub: 'المناطق المفتوحة والبوليفارد ومهرجانات المشجعين',
    primaryColorHex: '#38BDF8',
    sectors: [
      StadiumSector(id: 'PLAZA_MAIN_SCREEN', nameAr: '📺 منطقة الشاشة العملاقة (Giant Screen Zone)', nameEn: 'Giant LED Screen Zone', standGroup: 'North', orderIndex: 1, assignedChar: '★', totalRows: 1, seatsPerRow: 1),
      StadiumSector(id: 'PLAZA_WEST_WING', nameAr: '🌴 الساحة الغربية وممشى البوليفارد (West Boulevard)', nameEn: 'West Boulevard & Walkway', standGroup: 'West', orderIndex: 2, assignedChar: 'W', totalRows: 1, seatsPerRow: 1),
      StadiumSector(id: 'PLAZA_CENTER_HUB', nameAr: '⛲ قلب الساحة المفتوحة والمجمع الرئيسي (Central Hub)', nameEn: 'Central Plaza & Fountain Hub', standGroup: 'East', orderIndex: 3, assignedChar: 'C', totalRows: 1, seatsPerRow: 1),
      StadiumSector(id: 'PLAZA_EAST_WING', nameAr: '🎡 الساحة الشرقية ومنطقة الفعاليات (East Area)', nameEn: 'East Fan Plaza Zone', standGroup: 'East', orderIndex: 4, assignedChar: 'E', totalRows: 1, seatsPerRow: 1),
      StadiumSector(id: 'PLAZA_FOOD_TRUCKS', nameAr: '🍔 منطقة عربات الطعام والمطاعم (Food Trucks Zone)', nameEn: 'Food Trucks & Lounge', standGroup: 'VIP', orderIndex: 5, assignedChar: 'F', totalRows: 1, seatsPerRow: 1),
      StadiumSector(id: 'PLAZA_SOUTH_GATE', nameAr: '🚪 المداخل والساحة الجنوبية الترحيبية (South Gates)', nameEn: 'South Welcome Gate & Plaza', standGroup: 'South', orderIndex: 6, assignedChar: 'S', totalRows: 1, seatsPerRow: 1),
    ],
  );

  static const List<StadiumProfile> allStadiums = [
    jawharaStadium,
    kingdomArena,
    alawwalPark,
    aramcoStadium,
    openEventHall,
    outdoorPlaza,
  ];

  static List<StadiumSector> get sectors => kingdomArena.sectors;
}


