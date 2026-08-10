import 'package:flutter/material.dart';

class ServiceCategoryStyle {
  final IconData icon;
  final Color color;
  final Color bg;
  const ServiceCategoryStyle(this.icon, this.color, this.bg);
}

/// Visual theme (icon + color) for each of the 26 top-level "All Services"
/// categories — mirrors the pastel-tile look of the reference mockup without
/// depending on per-category illustration assets that don't exist in this repo.
const Map<String, ServiceCategoryStyle> kCategoryStyles = {
  'Home Services': ServiceCategoryStyle(Icons.home_rounded, Color(0xFF1E88E5), Color(0xFFE3F2FD)),
  'Repair & Maintenance': ServiceCategoryStyle(Icons.build_rounded, Color(0xFFFB8C00), Color(0xFFFFF3E0)),
  'AC & Appliances': ServiceCategoryStyle(Icons.ac_unit_rounded, Color(0xFF039BE5), Color(0xFFE1F5FE)),
  'Cleaning Services': ServiceCategoryStyle(Icons.cleaning_services_rounded, Color(0xFF43A047), Color(0xFFE8F5E9)),
  'Interior & Renovation': ServiceCategoryStyle(Icons.chair_rounded, Color(0xFFD81B60), Color(0xFFFCE4EC)),
  'Outdoor Services': ServiceCategoryStyle(Icons.grass_rounded, Color(0xFF388E3C), Color(0xFFE8F5E9)),
  'Security & Safety': ServiceCategoryStyle(Icons.security_rounded, Color(0xFF8E24AA), Color(0xFFF3E5F5)),
  'Smart Home Services': ServiceCategoryStyle(Icons.wifi_rounded, Color(0xFF00897B), Color(0xFFE0F2F1)),
  'Water Services': ServiceCategoryStyle(Icons.water_drop_rounded, Color(0xFF1E88E5), Color(0xFFE3F2FD)),
  'Construction Services': ServiceCategoryStyle(Icons.construction_rounded, Color(0xFFE65100), Color(0xFFFFF3E0)),
  'Furniture Services': ServiceCategoryStyle(Icons.chair_alt_rounded, Color(0xFF5E35B1), Color(0xFFEDE7F6)),
  'Pest Control': ServiceCategoryStyle(Icons.pest_control_rounded, Color(0xFFE53935), Color(0xFFFFEBEE)),
  'Shifting Services': ServiceCategoryStyle(Icons.local_shipping_rounded, Color(0xFFFB8C00), Color(0xFFFFF3E0)),
  'Personal Home Assistance': ServiceCategoryStyle(Icons.person_rounded, Color(0xFF7B1FA2), Color(0xFFEDE7F6)),
  'Pet Services': ServiceCategoryStyle(Icons.pets_rounded, Color(0xFF388E3C), Color(0xFFE8F5E9)),
  'Laundry & Textile': ServiceCategoryStyle(Icons.local_laundry_service_rounded, Color(0xFF1976D2), Color(0xFFE3F2FD)),
  'Technology Services': ServiceCategoryStyle(Icons.computer_rounded, Color(0xFF1E88E5), Color(0xFFE3F2FD)),
  'Personal Services': ServiceCategoryStyle(Icons.face_rounded, Color(0xFFC2185B), Color(0xFFFCE4EC)),
  'Education Services': ServiceCategoryStyle(Icons.school_rounded, Color(0xFF2E7D32), Color(0xFFE8F5E9)),
  'Healthcare Services': ServiceCategoryStyle(Icons.favorite_rounded, Color(0xFFE53935), Color(0xFFFFEBEE)),
  'Doctor Home Visit': ServiceCategoryStyle(Icons.medical_services_rounded, Color(0xFF1E88E5), Color(0xFFE3F2FD)),
  'Physiotherapy': ServiceCategoryStyle(Icons.accessibility_new_rounded, Color(0xFF00897B), Color(0xFFE0F2F1)),
  'Lab Sample Collection': ServiceCategoryStyle(Icons.biotech_rounded, Color(0xFF8E24AA), Color(0xFFF3E5F5)),
  'Nursing Care': ServiceCategoryStyle(Icons.local_hospital_rounded, Color(0xFFD81B60), Color(0xFFFCE4EC)),
  'Ambulance Booking': ServiceCategoryStyle(Icons.emergency_rounded, Color(0xFFE53935), Color(0xFFFFEBEE)),
};

const ServiceCategoryStyle kDefaultCategoryStyle =
    ServiceCategoryStyle(Icons.miscellaneous_services_rounded, Color(0xFF5A6178), Color(0xFFECEEF4));

ServiceCategoryStyle categoryStyleFor(String? name) => resolveServiceStyle(name);

String cleanServiceName(String? name) {
  if (name == null) return '';
  return name.replaceAll(RegExp(r'[\u{1F300}-\u{1F9FF}]|[\u{2600}-\u{26FF}]|[\u{2700}-\u{27BF}]', unicode: true), '').trim();
}

/// Parses multi-select lab / service summaries into individual service names.
List<String> parseSelectedServiceNames(String? raw) {
  if (raw == null || raw.trim().isEmpty) return [];

  final names = <String>[];
  final seen = <String>{};

  void addName(String value) {
    final clean = cleanServiceName(value).trim();
    if (clean.isEmpty) return;
    final key = clean.toLowerCase();
    if (seen.add(key)) names.add(clean);
  }

  for (final line in raw.split(RegExp(r'\r?\n'))) {
    var text = line.trim();
    if (text.isEmpty) continue;
    text = text.replaceFirst(RegExp(r'^[-•*]\s*'), '');
    text = text.replaceFirst(RegExp(r'^Selected\s+.+?\(\d+\):\s*', caseSensitive: false), '');
    text = text.trim();
    if (text.isEmpty) continue;
    if (RegExp(r'^Selected\s+.+?\(\d+\):\s*$', caseSensitive: false).hasMatch(text)) continue;
    addName(text);
  }

  if (names.isEmpty) {
    addName(raw.replaceFirst(RegExp(r'^Selected\s+.+?\(\d+\):\s*', caseSensitive: false), ''));
  }

  return names;
}

bool isParentServiceCategory(String? rawName) {
  if (rawName == null) return false;
  final clean = cleanServiceName(rawName).trim().toLowerCase();
  if (clean.isEmpty) return false;

  const parentSet = {
    'home services',
    'repair & maintenance',
    'ac & appliances',
    'cleaning services',
    'interior & renovation',
    'outdoor services',
    'security & safety',
    'smart home services',
    'water services',
    'construction services',
    'furniture services',
    'pest control',
    'shifting services',
    'personal home assistance',
    'pet services',
    'laundry & textile',
    'technology services',
    'personal services',
    'education services',
    'healthcare services',
    'doctor home visit',
    'physiotherapy',
    'nursing care',
    'home tutor',
    'home tutor services',
  };

  return parentSet.contains(clean);
}

String _cleanNameForLookup(String? name) => cleanServiceName(name);

const List<Color> _stylePalette = [
  Color(0xFF1E88E5), Color(0xFFFB8C00), Color(0xFF43A047), Color(0xFF8E24AA),
  Color(0xFFE53935), Color(0xFF00897B), Color(0xFF5E35B1), Color(0xFFD81B60),
  Color(0xFF039BE5), Color(0xFF455A64),
];

Color _accentFromName(String name) => _stylePalette[name.hashCode.abs() % _stylePalette.length];

final List<MapEntry<String, IconData>> _keywordIconRules = [
  MapEntry('electric', Icons.electrical_services_rounded),
  MapEntry('plumb', Icons.plumbing_rounded),
  MapEntry('carpent', Icons.carpenter_rounded),
  MapEntry('paint', Icons.format_paint_rounded),
  MapEntry('clean', Icons.cleaning_services_rounded),
  MapEntry('ac ', Icons.ac_unit_rounded),
  MapEntry('air condition', Icons.ac_unit_rounded),
  MapEntry('fridge', Icons.kitchen_rounded),
  MapEntry('refrigerator', Icons.kitchen_rounded),
  MapEntry('wash', Icons.local_laundry_service_rounded),
  MapEntry('laundry', Icons.local_laundry_service_rounded),
  MapEntry('pet', Icons.pets_rounded),
  MapEntry('doctor', Icons.medical_services_rounded),
  MapEntry('nurse', Icons.local_hospital_rounded),
  MapEntry('ambul', Icons.emergency_rounded),
  MapEntry('physio', Icons.accessibility_new_rounded),
  MapEntry('lab ', Icons.biotech_rounded),
  MapEntry('tutor', Icons.menu_book_rounded),
  MapEntry('yoga', Icons.self_improvement_rounded),
  MapEntry('gym', Icons.fitness_center_rounded),
  MapEntry('music', Icons.music_note_rounded),
  MapEntry('dance', Icons.emoji_people_rounded),
  MapEntry('massage', Icons.spa_rounded),
  MapEntry('salon', Icons.content_cut_rounded),
  MapEntry('barber', Icons.content_cut_rounded),
  MapEntry('garden', Icons.local_florist_rounded),
  MapEntry('lawn', Icons.grass_rounded),
  MapEntry('pest', Icons.pest_control_rounded),
  MapEntry('cctv', Icons.videocam_rounded),
  MapEntry('security', Icons.security_rounded),
  MapEntry('wifi', Icons.wifi_rounded),
  MapEntry('smart', Icons.settings_remote_rounded),
  MapEntry('water', Icons.water_drop_rounded),
  MapEntry('construct', Icons.construction_rounded),
  MapEntry('renovat', Icons.home_repair_service_rounded),
  MapEntry('furniture', Icons.chair_rounded),
  MapEntry('shift', Icons.local_shipping_rounded),
  MapEntry('mov', Icons.local_shipping_rounded),
  MapEntry('pack', Icons.inventory_2_rounded),
  MapEntry('maid', Icons.cleaning_services_rounded),
  MapEntry('cook', Icons.restaurant_rounded),
  MapEntry('baby', Icons.child_care_rounded),
  MapEntry('elder', Icons.elderly_rounded),
  MapEntry('scrap', Icons.recycling_rounded),
  MapEntry('gas', Icons.propane_tank_rounded),
  MapEntry('decor', Icons.celebration_rounded),
  MapEntry('tent', Icons.other_houses_rounded),
  MapEntry('inspect', Icons.search_rounded),
  MapEntry('tv', Icons.tv_rounded),
  MapEntry('laptop', Icons.laptop_rounded),
  MapEntry('computer', Icons.computer_rounded),
  MapEntry('printer', Icons.print_rounded),
  MapEntry('inverter', Icons.battery_charging_full_rounded),
  MapEntry('generator', Icons.electric_bolt_rounded),
  MapEntry('microwave', Icons.microwave_rounded),
  MapEntry('geyser', Icons.hot_tub_rounded),
  MapEntry('chimney', Icons.blur_on_rounded),
  MapEntry('dishwasher', Icons.local_dining_rounded),
  MapEntry('fan', Icons.mode_fan_off_rounded),
  MapEntry('cooler', Icons.ac_unit_rounded),
  MapEntry('roof', Icons.roofing_rounded),
  MapEntry('tile', Icons.grid_view_rounded),
  MapEntry('wallpaper', Icons.wallpaper_rounded),
  MapEntry('floor', Icons.grid_on_rounded),
  MapEntry('curtain', Icons.curtains_rounded),
  MapEntry('modular', Icons.kitchen_rounded),
  MapEntry('ceiling', Icons.dashboard_rounded),
  MapEntry('weld', Icons.whatshot_rounded),
  MapEntry('mason', Icons.foundation_rounded),
  MapEntry('handyman', Icons.handyman_rounded),
  MapEntry('door', Icons.sensor_door_rounded),
  MapEntry('window', Icons.window_rounded),
  MapEntry('vet', Icons.pets_rounded),
  MapEntry('groom', Icons.pets_rounded),
  MapEntry('iron', Icons.iron_rounded),
  MapEntry('driver', Icons.drive_eta_rounded),
  MapEntry('cab', Icons.local_taxi_rounded),
  MapEntry('delivery', Icons.delivery_dining_rounded),
  MapEntry('food', Icons.restaurant_rounded),
  MapEntry('health', Icons.favorite_rounded),
  MapEntry('educat', Icons.school_rounded),
  MapEntry('repair', Icons.build_rounded),
  MapEntry('install', Icons.handyman_rounded),
];

IconData? _keywordIconFor(String lower) {
  for (final rule in _keywordIconRules) {
    if (lower.contains(rule.key)) return rule.value;
  }
  return null;
}

ServiceCategoryStyle resolveServiceStyle(String? name, {ServiceCategoryStyle? parentStyle}) {
  final clean = _cleanNameForLookup(name);
  if (clean.isEmpty) return parentStyle ?? kDefaultCategoryStyle;
  if (kCategoryStyles.containsKey(clean)) return kCategoryStyles[clean]!;
  final lower = clean.toLowerCase();
  for (final entry in kCategoryStyles.entries) {
    final key = entry.key.toLowerCase();
    if (lower.contains(key) || key.contains(lower)) return entry.value;
  }
  final icon = leafIconFor(clean, fallback: kDefaultCategoryStyle.icon);
  if (icon != kDefaultCategoryStyle.icon) {
    final color = _accentFromName(clean);
    return ServiceCategoryStyle(icon, color, color.withValues(alpha: 0.12));
  }
  return parentStyle ?? kDefaultCategoryStyle;
}

ServiceCategoryStyle styleForServiceItem(String? name, {ServiceCategoryStyle? parentStyle}) {
  final base = resolveServiceStyle(name, parentStyle: parentStyle);
  final icon = leafIconFor(name, fallback: base.icon);
  return ServiceCategoryStyle(icon, base.color, base.bg);
}

/// Keyword-matched icon for individual leaf sub-services (~150 items).
final Map<String, IconData> _leafIconOverrides = {
  'Cleaner': Icons.cleaning_services_rounded,
  'Electrician': Icons.electrical_services_rounded,
  'Plumber': Icons.plumbing_rounded,
  'Carpenter': Icons.carpenter_rounded,
  'Painter': Icons.format_paint_rounded,
  'Mason (Raj Mistri)': Icons.foundation_rounded,
  'Welder': Icons.whatshot_rounded,
  'Handyman': Icons.handyman_rounded,
  'Door Repair': Icons.sensor_door_rounded,
  'Window Repair': Icons.window_rounded,
  'Furniture Repair': Icons.chair_rounded,
  'AC Installation': Icons.ac_unit_rounded,
  'AC Repair': Icons.ac_unit_rounded,
  'AC Gas Filling': Icons.propane_tank_rounded,
  'Refrigerator Repair': Icons.kitchen_rounded,
  'Washing Machine Repair': Icons.local_laundry_service_rounded,
  'Microwave Repair': Icons.microwave_rounded,
  'Water Purifier (RO) Service': Icons.water_drop_rounded,
  'Geyser Repair': Icons.hot_tub_rounded,
  'Chimney Service': Icons.blur_on_rounded,
  'Dishwasher Repair': Icons.local_dining_rounded,
  'TV Repair': Icons.tv_rounded,
  'Fan Repair': Icons.mode_fan_off_rounded,
  'Cooler Repair': Icons.ac_unit_rounded,
  'Inverter Repair': Icons.battery_charging_full_rounded,
  'Generator Repair': Icons.electric_bolt_rounded,
  'Home Cleaning': Icons.home_rounded,
  'Deep Cleaning': Icons.cleaning_services_rounded,
  'Bathroom Cleaning': Icons.bathtub_rounded,
  'Kitchen Cleaning': Icons.kitchen_rounded,
  'Sofa Cleaning': Icons.weekend_rounded,
  'Carpet Cleaning': Icons.texture_rounded,
  'Mattress Cleaning': Icons.bed_rounded,
  'Water Tank Cleaning': Icons.water_rounded,
  'Floor Cleaning': Icons.cleaning_services_rounded,
  'Glass Cleaning': Icons.window_rounded,
  'Office Cleaning': Icons.business_rounded,
  'Interior Designer': Icons.design_services_rounded,
  'Modular Kitchen': Icons.kitchen_rounded,
  'False Ceiling': Icons.dashboard_rounded,
  'Flooring Work': Icons.grid_on_rounded,
  'Wallpaper Installation': Icons.wallpaper_rounded,
  'Tile Installation': Icons.grid_view_rounded,
  'POP Work': Icons.format_paint_rounded,
  'Curtain Installation': Icons.curtains_rounded,
  'Furniture Installation': Icons.chair_alt_rounded,
  'Gardening': Icons.local_florist_rounded,
  'Lawn Maintenance': Icons.grass_rounded,
  'Tree Cutting': Icons.park_rounded,
  'Plant Care': Icons.eco_rounded,
  'Landscape Design': Icons.landscape_rounded,
  'CCTV Installation': Icons.videocam_rounded,
  'CCTV Repair': Icons.videocam_rounded,
  'Smart Lock Installation': Icons.lock_rounded,
  'Security Guard': Icons.shield_rounded,
  'Fire Safety Equipment': Icons.local_fire_department_rounded,
  'Video Door Phone Installation': Icons.doorbell_rounded,
  'Smart Light Installation': Icons.lightbulb_rounded,
  'Home Automation': Icons.settings_remote_rounded,
  'Wi-Fi Setup': Icons.wifi_rounded,
  'Network Installation': Icons.router_rounded,
  'Smart Door Lock Setup': Icons.lock_rounded,
  'Borewell Service': Icons.water_rounded,
  'Water Tank Repair': Icons.water_damage_rounded,
  'Pipeline Repair': Icons.plumbing_rounded,
  'Motor Pump Repair': Icons.settings_rounded,
  'Water Leakage Detection': Icons.water_drop_rounded,
  'Home Construction': Icons.house_rounded,
  'House Renovation': Icons.home_repair_service_rounded,
  'Civil Contractor': Icons.engineering_rounded,
  'Building Repair': Icons.foundation_rounded,
  'Roof Repair': Icons.roofing_rounded,
  'Waterproofing': Icons.water_drop_rounded,
  'Furniture Assembly': Icons.build_rounded,
  'Furniture Shifting': Icons.local_shipping_rounded,
  'Office Furniture Setup': Icons.chair_alt_rounded,
  'Bed Installation': Icons.bed_rounded,
  'Wardrobe Installation': Icons.checkroom_rounded,
  'Termite Control': Icons.pest_control_rounded,
  'Cockroach Control': Icons.pest_control_rounded,
  'Mosquito Control': Icons.pest_control_rounded,
  'Rodent Control': Icons.pest_control_rounded,
  'General Pest Control': Icons.pest_control_rounded,
  'House Shifting': Icons.house_rounded,
  'Office Shifting': Icons.business_rounded,
  'Packers & Movers': Icons.inventory_2_rounded,
  'Local Moving': Icons.local_shipping_rounded,
  'Interstate Moving': Icons.local_shipping_rounded,
  'Maid Service': Icons.cleaning_services_rounded,
  'Cook': Icons.restaurant_rounded,
  'Babysitter': Icons.child_care_rounded,
  'Elder Care': Icons.elderly_rounded,
  'Patient Care': Icons.personal_injury_rounded,
  'Driver on Demand': Icons.drive_eta_rounded,
  'Pet Grooming': Icons.pets_rounded,
  'Pet Walking': Icons.pets_rounded,
  'Pet Boarding': Icons.house_rounded,
  'Veterinary Visit': Icons.pets_rounded,
  'Laundry Pickup': Icons.local_laundry_service_rounded,
  'Dry Cleaning': Icons.dry_cleaning_rounded,
  'Ironing Service': Icons.iron_rounded,
  'Shoe Cleaning': Icons.icecream_rounded,
  'Curtain Washing': Icons.curtains_rounded,
  'Laptop Repair': Icons.laptop_rounded,
  'Computer Repair': Icons.desktop_windows_rounded,
  'Printer Repair': Icons.print_rounded,
  'Wi-Fi Installation': Icons.wifi_rounded,
  'Smart Home Installation': Icons.home_rounded,
  'TV Wall Mount Installation': Icons.tv_rounded,
  'Barber & Saloon Service': Icons.content_cut_rounded,
  'Salon Spa & Others (Female)': Icons.spa_rounded,
  'Massage Therapist': Icons.spa_rounded,
  'Home Tutor': Icons.menu_book_rounded,
  'Music Teacher': Icons.music_note_rounded,
  'Dance Teacher': Icons.emoji_people_rounded,
  'Yoga Trainer': Icons.self_improvement_rounded,
  'Gym Trainer': Icons.fitness_center_rounded,
  'Language Tutor': Icons.translate_rounded,
  'Doctor Home Visit': Icons.medical_services_rounded,
  'Physiotherapist': Icons.accessibility_new_rounded,
  'Lab Sample Collection': Icons.biotech_rounded,
  'Nursing Care': Icons.local_hospital_rounded,
  'Ambulance Booking': Icons.emergency_rounded,
  'Scrap Collection': Icons.recycling_rounded,
  'Water Can Delivery': Icons.water_drop_rounded,
  'Gas Cylinder Delivery': Icons.propane_tank_rounded,
  'Home Decoration': Icons.chair_rounded,
  'Event Decoration': Icons.celebration_rounded,
  'Festival Decoration': Icons.celebration_rounded,
  'Tent & Furniture Rental': Icons.other_houses_rounded,
  'Home Inspection': Icons.search_rounded,
};

IconData leafIconFor(String? name, {IconData fallback = Icons.build_circle_outlined}) {
  final clean = _cleanNameForLookup(name);
  if (clean.isEmpty) return fallback;
  if (_leafIconOverrides.containsKey(clean)) return _leafIconOverrides[clean]!;
  final lower = clean.toLowerCase();
  for (final entry in _leafIconOverrides.entries) {
    if (lower == entry.key.toLowerCase()) return entry.value;
  }
  for (final entry in _leafIconOverrides.entries) {
    final key = entry.key.toLowerCase();
    if (lower.contains(key) || key.contains(lower)) return entry.value;
  }
  return _keywordIconFor(lower) ?? fallback;
}
