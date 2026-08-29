class StadiumSector {
  final String id;
  final String nameAr;
  final String nameEn;
  final String standGroup; // East, West, North, South, Curve Left, Curve Right
  final int orderIndex; // For wave sequence ordering
  final String assignedChar; // Default tifo letter in banner sequences

  const StadiumSector({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.standGroup,
    required this.orderIndex,
    this.assignedChar = '',
  });
}

class PresetStadiumData {
  static const List<StadiumSector> sectors = [
    StadiumSector(id: 'SEC_EAST_101', nameAr: 'المدرج الشرقي 101', nameEn: 'East Stand 101', standGroup: 'East', orderIndex: 1, assignedChar: 'A'),
    StadiumSector(id: 'SEC_EAST_102', nameAr: 'المدرج الشرقي 102', nameEn: 'East Stand 102', standGroup: 'East', orderIndex: 2, assignedChar: 'L'),
    StadiumSector(id: 'SEC_EAST_103', nameAr: 'المدرج الشرقي 103', nameEn: 'East Stand 103', standGroup: 'East', orderIndex: 3, assignedChar: ' '),
    StadiumSector(id: 'SEC_EAST_104', nameAr: 'المدرج الشرقي 104', nameEn: 'East Stand 104', standGroup: 'East', orderIndex: 4, assignedChar: 'H'),
    StadiumSector(id: 'SEC_WEST_201', nameAr: 'المدرج الغربي 201', nameEn: 'West Stand 201', standGroup: 'West', orderIndex: 5, assignedChar: 'I'),
    StadiumSector(id: 'SEC_WEST_202', nameAr: 'المدرج الغربي 202', nameEn: 'West Stand 202', standGroup: 'West', orderIndex: 6, assignedChar: 'L'),
    StadiumSector(id: 'SEC_CURVE_L1', nameAr: 'المنحنى الأيسر L1', nameEn: 'Curve Left L1', standGroup: 'Curve Left', orderIndex: 7, assignedChar: 'A'),
    StadiumSector(id: 'SEC_CURVE_R1', nameAr: 'المنحنى الأيمن R1', nameEn: 'Curve Right R1', standGroup: 'Curve Right', orderIndex: 8, assignedChar: 'L'),
    StadiumSector(id: 'SEC_NORTH_301', nameAr: 'المدرج الشمالي 301', nameEn: 'North Stand 301', standGroup: 'North', orderIndex: 9, assignedChar: '★'),
    StadiumSector(id: 'SEC_SOUTH_401', nameAr: 'المدرج الجنوبي 401', nameEn: 'South Stand 401', standGroup: 'South', orderIndex: 10, assignedChar: '★'),
  ];
}
