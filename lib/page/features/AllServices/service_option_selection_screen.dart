import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import 'package:finway/themes/button_them.dart';
import 'package:finway/themes/constant_colors.dart';
import 'package:finway/utils/dark_theme_provider.dart';
import 'lab_sample_selection_screen.dart';
import 'service_request_screen.dart';
import 'service_style.dart';

class ServiceOptionItem {
  final String title;
  final String description;
  final String icon;
  final String? badge;

  const ServiceOptionItem({
    required this.title,
    required this.description,
    required this.icon,
    this.badge,
  });
}

class ServiceOptionSelectionScreen extends StatefulWidget {
  final String categoryName;

  const ServiceOptionSelectionScreen({
    super.key,
    required this.categoryName,
  });

  @override
  State<ServiceOptionSelectionScreen> createState() => _ServiceOptionSelectionScreenState();
}

class _ServiceOptionSelectionScreenState extends State<ServiceOptionSelectionScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFrequency = 'Hourly';

  static const Map<String, List<ServiceOptionItem>> catalog = {
    'Doctor Home Visit': [
      ServiceOptionItem(
        title: 'General Physician Visit',
        description: 'Comprehensive general health checkup, diagnosis & prescription at home',
        icon: '👨‍⚕️',
        badge: 'Popular',
      ),
      ServiceOptionItem(
        title: 'Emergency Doctor Visit',
        description: 'Urgent medical doctor consultation for sudden illness & severe discomfort',
        icon: '🚨',
        badge: 'Priority',
      ),
      ServiceOptionItem(
        title: 'Pediatric (Child Doctor) Visit',
        description: 'Specialized infant, toddler & child health checkup by pediatric doctor',
        icon: '👶',
      ),
      ServiceOptionItem(
        title: 'Elderly Care Doctor Visit',
        description: 'Geriatric physician visit for senior citizen chronic conditions & health monitoring',
        icon: '👵',
      ),
      ServiceOptionItem(
        title: 'Heart & BP Care Consultation',
        description: 'Cardiology doctor consultation for hypertension, palpitations & BP management',
        icon: '❤️',
      ),
      ServiceOptionItem(
        title: 'Diabetes & Metabolism Care',
        description: 'Endocrinology & diabetes specialist consultation for glucose management',
        icon: '🩺',
      ),
      ServiceOptionItem(
        title: 'Respiratory & Fever Care',
        description: 'Doctor consultation for cold, flu, asthma, chest congestion & high fevers',
        icon: '🫁',
      ),
      ServiceOptionItem(
        title: 'Women\'s Health & Gynecologist Visit',
        description: 'Female doctor consultation for prenatal care, hormonal & general women\'s health',
        icon: '👩‍⚕️',
      ),
      ServiceOptionItem(
        title: 'Minor Injury & Wound Care',
        description: 'At-home dressing, burn care, minor stitch inspection & infection treatment',
        icon: '🩹',
      ),
      ServiceOptionItem(
        title: 'ECG & Home Diagnostics Consultation',
        description: '12-lead portable ECG at home with instant doctor interpretation',
        icon: '📊',
      ),
    ],
    'Physiotherapy': [
      ServiceOptionItem(
        title: 'Orthopedic Physiotherapy',
        description: 'Therapy for joint pain, arthritis, fractures, spine & neck cervical issues',
        icon: '🦴',
        badge: 'Popular',
      ),
      ServiceOptionItem(
        title: 'Post-Surgery Rehabilitation',
        description: 'Structured recovery program after knee/hip replacement or ligament surgery',
        icon: '🚶',
      ),
      ServiceOptionItem(
        title: 'Neuro Physiotherapy & Stroke Rehab',
        description: 'Specialized motor recovery for stroke, paralysis, Parkinson\'s & nerve trauma',
        icon: '🧠',
      ),
      ServiceOptionItem(
        title: 'Sports Injury Rehabilitation',
        description: 'Muscle tears, sprains, tendonitis & athletic return-to-sport therapy',
        icon: '⚽',
      ),
      ServiceOptionItem(
        title: 'Pain Management & Dry Needling',
        description: 'Electrotherapy, TENS, ultrasonic pain relief & myofascial trigger point release',
        icon: '⚡',
      ),
      ServiceOptionItem(
        title: 'Cardio & Pulmonary Rehab',
        description: 'Breathing exercises, lung capacity expansion & post-cardiac therapy',
        icon: '🫀',
      ),
      ServiceOptionItem(
        title: 'Geriatric / Elderly Mobility Therapy',
        description: 'Balance training, fall prevention & gentle joint flexibility exercises',
        icon: '👴',
      ),
      ServiceOptionItem(
        title: 'Postural & Ergonomic Therapy',
        description: 'Correction of slouching, tech-neck, scoliosis & workplace posture strains',
        icon: '🧘',
      ),
    ],
    'Nursing Care': [
      ServiceOptionItem(
        title: 'General Nurse Visit',
        description: 'Qualified nurse visit for routine nursing, medication administration & vitals',
        icon: '👩‍⚕️',
        badge: 'Popular',
      ),
      ServiceOptionItem(
        title: 'Injection & IV Drip Care',
        description: 'Intravenous cannula insertion, saline, antibiotic drip & intramuscular injections',
        icon: '💉',
      ),
      ServiceOptionItem(
        title: 'Wound & Surgical Dressing Care',
        description: 'Sterile dressing for post-operative incisions, bedsores & diabetic ulcers',
        icon: '🩹',
      ),
      ServiceOptionItem(
        title: 'Catheter & Ryle\'s Tube Care',
        description: 'Foley catheter insertion, urinary bag change & nasogastric tube maintenance',
        icon: '🧪',
      ),
      ServiceOptionItem(
        title: 'Bedridden Patient Attendant',
        description: 'Full-shift compassionate assistance with bathing, hygiene & mobility support',
        icon: '🛏️',
      ),
      ServiceOptionItem(
        title: 'Vital Signs & ICU at Home Monitoring',
        description: 'Continuous BP, SpO2, pulse, blood sugar & oxygen flow management',
        icon: '📈',
      ),
      ServiceOptionItem(
        title: 'Elderly Care Nursing',
        description: 'Dedicated senior nurse for daily medication schedules & geriatric companion care',
        icon: '👵',
      ),
      ServiceOptionItem(
        title: 'Post-Surgery Day / Night Nursing',
        description: 'Specialized 12-hr or 24-hr post-operative recovery monitoring by certified nurse',
        icon: '🌙',
      ),
    ],
    'Home Tutor Services': [
      ServiceOptionItem(
        title: 'School Tuition (Class 1-10 All Subjects)',
        description: 'Comprehensive daily tutoring in Maths, Science, Social Studies, English & Hindi',
        icon: '📚',
        badge: 'Popular',
      ),
      ServiceOptionItem(
        title: 'Mathematics & Science Specialist (Class 9-12)',
        description: 'In-depth conceptual coaching for higher secondary Board preparation',
        icon: '📐',
      ),
      ServiceOptionItem(
        title: 'Physics & Chemistry Tutor (Class 11-12)',
        description: 'Expert board exam preparation with numericals & conceptual clarity',
        icon: '🔬',
      ),
      ServiceOptionItem(
        title: 'JEE / NEET Competitive Exam Coach',
        description: 'Intensive problem solving, mock series & shortcuts for engineering/medical exams',
        icon: '🎯',
      ),
      ServiceOptionItem(
        title: 'English & Foreign Language Tutor',
        description: 'Spoken English, grammar, French, German, Spanish & IELTS coaching',
        icon: '🗣️',
      ),
      ServiceOptionItem(
        title: 'Computer Science & Coding Tutor',
        description: 'Python, C++, Java, web development & school CS curriculum',
        icon: '💻',
      ),
      ServiceOptionItem(
        title: 'Music & Instrument Teacher',
        description: 'Home guitar, piano, keyboard, vocal singing & classical music lessons',
        icon: '🎸',
      ),
      ServiceOptionItem(
        title: 'Yoga & Fitness Home Trainer',
        description: 'Personal yoga instructor for flexibility, weight management & mindfulness',
        icon: '🧘',
      ),
      ServiceOptionItem(
        title: 'Dance & Creative Arts Teacher',
        description: 'Western, Classical, Bollywood dance, drawing & fine arts home classes',
        icon: '🎨',
      ),
    ],
    'Education Services': [
      ServiceOptionItem(
        title: 'Home Tutor Services',
        description: 'Private home tutoring for school, board & competitive examinations',
        icon: '📚',
        badge: 'Top Service',
      ),
      ServiceOptionItem(
        title: 'Music Teacher',
        description: 'Personal home tutor for guitar, piano, singing & musical instruments',
        icon: '🎵',
      ),
      ServiceOptionItem(
        title: 'Dance Teacher',
        description: 'Choreographer & dance instructor for classical, western & contemporary dance',
        icon: '💃',
      ),
      ServiceOptionItem(
        title: 'Yoga Trainer',
        description: 'Certified yoga instructor for daily home meditation & wellness sessions',
        icon: '🧘',
      ),
      ServiceOptionItem(
        title: 'Gym & Fitness Trainer',
        description: 'Personal fitness trainer for home workouts, strength & weight loss programs',
        icon: '🏋️',
      ),
      ServiceOptionItem(
        title: 'Language Tutor',
        description: 'Language teacher for English, French, Spanish, German & regional languages',
        icon: '🗣️',
      ),
    ],
    'Healthcare Services': [
      ServiceOptionItem(
        title: 'Doctor Home Visit',
        description: 'Qualified doctor visit at your home for diagnosis, checkup & prescription',
        icon: '👨‍⚕️',
        badge: 'Recommended',
      ),
      ServiceOptionItem(
        title: 'Physiotherapy',
        description: 'Certified physiotherapist for rehabilitation, joint pain & injury therapy',
        icon: '🤸',
      ),
      ServiceOptionItem(
        title: 'Lab Sample Collection',
        description: 'Certified phlebotomist for home blood & diagnostic sample collection',
        icon: '🧪',
        badge: 'Multi-select',
      ),
      ServiceOptionItem(
        title: 'Nursing Care',
        description: 'Trained male & female nurses for injections, dressing, drip & elderly care',
        icon: '🩺',
      ),
      ServiceOptionItem(
        title: 'Ambulance Booking',
        description: 'Emergency & non-emergency patient transfer ambulance with oxygen support',
        icon: '🚑',
        badge: '24/7',
      ),
    ],
    'Repair & Maintenance': [
      ServiceOptionItem(
        title: 'Electrician',
        description: 'Wiring, switchboard, fuse, short-circuit, lighting & appliance connections',
        icon: '⚡',
        badge: 'Popular',
      ),
      ServiceOptionItem(
        title: 'Plumber',
        description: 'Pipe leaks, tap fixing, bathroom fittings, flush repair & drainage blockage',
        icon: '🔧',
      ),
      ServiceOptionItem(
        title: 'Carpenter',
        description: 'Furniture assembly, door lock fixing, wardrobe repair & wooden custom work',
        icon: '🪚',
      ),
      ServiceOptionItem(
        title: 'Painter',
        description: 'Wall painting, waterproofing, putty, exterior & interior home painting',
        icon: '🎨',
      ),
      ServiceOptionItem(
        title: 'Mason (Raj Mistri)',
        description: 'Tile fixing, brickwork, plastering, floor repair & cement masonry work',
        icon: '🧱',
      ),
      ServiceOptionItem(
        title: 'Welder',
        description: 'Metal gate, grill, railing, window frame welding & iron fabrication repair',
        icon: '🔥',
      ),
      ServiceOptionItem(
        title: 'Handyman General Repair',
        description: 'Curtain rod fixing, wall drillings, mirror hanging & minor home fixes',
        icon: '🛠️',
      ),
      ServiceOptionItem(
        title: 'Door & Window Repair',
        description: 'Sliding track repair, mosquito mesh installation & hinge alignment',
        icon: '🚪',
      ),
      ServiceOptionItem(
        title: 'Furniture Polishing & Repair',
        description: 'Sofa cushioning, wooden polishing, varnish & chair castor repair',
        icon: '🪑',
      ),
    ],
    'AC & Appliances': [
      ServiceOptionItem(
        title: 'AC Installation & Repair',
        description: 'Split & window AC installation, cooling fix, PCB check & servicing',
        icon: '❄️',
        badge: 'Popular',
      ),
      ServiceOptionItem(
        title: 'AC Gas Filling & Jet Cleaning',
        description: 'Refrigerant gas top-up & high-pressure jet pump deep foam wash',
        icon: '💨',
      ),
      ServiceOptionItem(
        title: 'Refrigerator Repair',
        description: 'Single/double door & side-by-side fridge cooling, compressor & defrost fix',
        icon: '🧊',
      ),
      ServiceOptionItem(
        title: 'Washing Machine Repair',
        description: 'Front load, top load & semi-automatic washing machine drum & motor fix',
        icon: '🫧',
      ),
      ServiceOptionItem(
        title: 'Water Purifier (RO) Service',
        description: 'Filter replacement, membrane change, TDS calibration & leakage repair',
        icon: '💧',
      ),
      ServiceOptionItem(
        title: 'Geyser & Water Heater Repair',
        description: 'Instant & storage geyser heating element replacement, thermostat & wiring',
        icon: '🔥',
      ),
      ServiceOptionItem(
        title: 'Microwave & Oven Repair',
        description: 'Magnetron repair, touch panel fixing & heating element replacement',
        icon: '🍲',
      ),
      ServiceOptionItem(
        title: 'TV Installation & Repair',
        description: 'LED/OLED TV wall mounting, motherboard repair, display & speaker fix',
        icon: '📺',
      ),
      ServiceOptionItem(
        title: 'Kitchen Chimney & Hob Service',
        description: 'Deep motor degreasing, filter mesh cleaning & suction repair',
        icon: '🍳',
      ),
    ],
    'Cleaning Services': [
      ServiceOptionItem(
        title: 'Full Home Deep Cleaning',
        description: 'Complete scrubbing, dusting, floor mechanised buffing & sanitization',
        icon: '✨',
        badge: 'Popular',
      ),
      ServiceOptionItem(
        title: 'Bathroom Deep Cleaning',
        description: 'Tile scale removal, tap polishing, mirror cleaning & germ disinfection',
        icon: '🚿',
      ),
      ServiceOptionItem(
        title: 'Kitchen Deep Cleaning',
        description: 'Oil grease degreasing, chimney exterior, cabinet interiors & slab cleaning',
        icon: '🍽️',
      ),
      ServiceOptionItem(
        title: 'Sofa & Carpet Shampooing',
        description: 'Fabric & leather sofa vacuuming, stain removal & wet shampoo extraction',
        icon: '🛋️',
      ),
      ServiceOptionItem(
        title: 'Mattress Sanitization',
        description: 'UV sanitization, deep dust mite extraction & allergen removal',
        icon: '🛏️',
      ),
      ServiceOptionItem(
        title: 'Water Tank Cleaning',
        description: 'Overhead & underground water tank sludge removal & UV treatment',
        icon: '🚰',
      ),
      ServiceOptionItem(
        title: 'Complete Car Foam Cleaning',
        description: 'Exterior high-pressure foam wash, interior vacuuming & dashboard polish',
        icon: '🚗',
      ),
    ],
    'Personal Home Assistance': [
      ServiceOptionItem(
        title: 'Maid Service',
        description: 'Trained domestic helper for sweeping, mopping, utensil cleaning & dusting',
        icon: '🧹',
        badge: 'Popular',
      ),
      ServiceOptionItem(
        title: 'Cook & Chef',
        description: 'Experienced home cook for hygienic breakfast, lunch & dinner preparation',
        icon: '👨‍🍳',
      ),
      ServiceOptionItem(
        title: 'Babysitter & Nanny',
        description: 'Caring, verified child care assistant for playtime, feeding & supervision',
        icon: '👶',
      ),
      ServiceOptionItem(
        title: 'Elder Care Companion',
        description: 'Dedicated caregiver for senior citizens assisting with daily routines & walking',
        icon: '👵',
      ),
      ServiceOptionItem(
        title: 'Patient Care Attendant',
        description: 'Home attendant for post-surgery & bedridden patient mobility and hygiene',
        icon: '🛏️',
      ),
      ServiceOptionItem(
        title: 'Driver on Demand',
        description: 'Professional verified chauffeur for local city trips & outstation driving',
        icon: '🚗',
      ),
    ],
    'Personal Services': [
      ServiceOptionItem(
        title: 'Men\'s Grooming & Haircut',
        description: 'At-home haircut, beard styling, head massage & facial cleanup for men',
        icon: '✂️',
        badge: 'Popular',
      ),
      ServiceOptionItem(
        title: 'Women\'s Salon & Spa',
        description: 'Waxing, facial, cleanup, hair spa, threading & manicure/pedicure at home',
        icon: '💅',
      ),
      ServiceOptionItem(
        title: 'Massage & Relaxation Therapy',
        description: 'Therapeutic full body massage, deep tissue & stress relief therapy at home',
        icon: '💆',
      ),
    ],
    'Shifting Services': [
      ServiceOptionItem(
        title: 'House Shifting',
        description: 'End-to-end packing, loading, transportation & unpacking for apartments & villas',
        icon: '📦',
        badge: 'Popular',
      ),
      ServiceOptionItem(
        title: 'Office & Commercial Moving',
        description: 'Workstation, IT equipment, server rack & office furniture relocation',
        icon: '🏢',
      ),
      ServiceOptionItem(
        title: 'Packers & Movers',
        description: 'Multi-layer bubble wrap, carton packing & safe fragile item handling',
        icon: '🚚',
      ),
      ServiceOptionItem(
        title: 'Local & Interstate Mini-Truck Booking',
        description: 'Tempo, mini-truck & freight transport for household cargo moves',
        icon: '🚛',
      ),
    ],
  };

  bool get _supportsFrequency {
    final clean = cleanServiceName(widget.categoryName).toLowerCase();
    return clean.contains('tutor') ||
        clean.contains('nurse') ||
        clean.contains('nursing') ||
        clean.contains('physio') ||
        clean.contains('maid') ||
        clean.contains('cook') ||
        clean.contains('assistance') ||
        clean.contains('personal home');
  }

  List<ServiceOptionItem> get _items {
    final clean = cleanServiceName(widget.categoryName);
    var list = catalog[clean] ?? [];

    if (list.isEmpty) {
      for (final key in catalog.keys) {
        if (key.toLowerCase().contains(clean.toLowerCase()) || clean.toLowerCase().contains(key.toLowerCase())) {
          list = catalog[key]!;
          break;
        }
      }
    }

    if (list.isEmpty) {
      final subNames = AllServicesController.subCategoryCatalog[clean] ?? [];
      list = subNames.map((name) => ServiceOptionItem(
        title: name,
        description: 'Professional ${clean.toLowerCase()} service at your home',
        icon: '🔹',
      )).toList();
    }

    if (_searchQuery.trim().isEmpty) return list;
    final q = _searchQuery.trim().toLowerCase();
    return list.where((item) => item.title.toLowerCase().contains(q) || item.description.toLowerCase().contains(q)).toList();
  }

  void _onSelectOption(ServiceOptionItem option) {
    final name = option.title.toLowerCase();
    if (name.contains('lab sample') || name.contains('lab collection')) {
      Get.to(() => LabSampleSelectionScreen(categoryName: cleanServiceName(widget.categoryName)));
      return;
    }

    if (name.contains('doctor home visit') ||
        name.contains('home tutor') ||
        name.contains('nursing care') ||
        name.contains('physiotherapy')) {
      Get.to(() => ServiceOptionSelectionScreen(categoryName: option.title));
      return;
    }

    Get.to(() => ServiceRequestScreen(
          serviceName: option.title,
          categoryName: cleanServiceName(widget.categoryName),
          initialFrequency: _supportsFrequency ? _selectedFrequency : null,
        ));
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<DarkThemeProvider>(context).getThem();
    final cleanName = cleanServiceName(widget.categoryName);
    final style = categoryStyleFor(cleanName);
    final items = _items;

    return Scaffold(
      backgroundColor: isDarkMode ? AppThemeData.surface50Dark : const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: isDarkMode ? AppThemeData.surface50Dark : Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: isDarkMode ? AppThemeData.grey900Dark : Colors.black),
        title: Text(
          cleanName.tr,
          style: TextStyle(
            fontFamily: AppThemeData.bold,
            fontSize: 17,
            color: isDarkMode ? AppThemeData.grey900Dark : Colors.black,
          ),
        ),
      ),
      body: Column(
        children: [
          // Category Banner
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(14, 8, 14, 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDarkMode ? AppThemeData.surface100Dark : style.bg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cleanName.tr,
                        style: TextStyle(
                          fontFamily: 'Switzer-Bold',
                          fontSize: 18,
                          color: style.color,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Select the exact service or specialist for your needs'.tr,
                        style: TextStyle(
                          fontFamily: AppThemeData.regular,
                          fontSize: 12,
                          color: isDarkMode ? AppThemeData.grey500Dark : AppThemeData.grey500,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  style.icon == Icons.medical_services_rounded ? '🩺' : (style.icon == Icons.school_rounded ? '📚' : '✨'),
                  style: const TextStyle(fontSize: 36),
                ),
              ],
            ),
          ),

          // Duration / Frequency Chips (for Tutor, Nursing, Maid, Physio, Cook)
          if (_supportsFrequency)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              child: Row(
                children: [
                  Text(
                    'Booking Type: '.tr,
                    style: TextStyle(
                      fontFamily: AppThemeData.semiBold,
                      fontSize: 12,
                      color: isDarkMode ? AppThemeData.grey500Dark : AppThemeData.grey500,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: ['Hourly', 'Daily', 'Monthly', 'Yearly / Course'].map((freq) {
                          final isSelected = _selectedFrequency == freq;
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ChoiceChip(
                              label: Text(
                                freq.tr,
                                style: TextStyle(
                                  fontFamily: isSelected ? AppThemeData.bold : AppThemeData.medium,
                                  fontSize: 11,
                                  color: isSelected ? Colors.white : (isDarkMode ? Colors.white70 : Colors.black87),
                                ),
                              ),
                              selected: isSelected,
                              selectedColor: style.color,
                              backgroundColor: isDarkMode ? AppThemeData.surface100Dark : Colors.white,
                              onSelected: (_) => setState(() => _selectedFrequency = freq),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 10),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Search $cleanName options...'.tr,
                hintStyle: TextStyle(
                  fontFamily: AppThemeData.regular,
                  fontSize: 13,
                  color: AppThemeData.grey500,
                ),
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: isDarkMode ? AppThemeData.surface100Dark : Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDarkMode ? Colors.white12 : Colors.black.withOpacity(0.08),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDarkMode ? Colors.white12 : Colors.black.withOpacity(0.08),
                  ),
                ),
              ),
            ),
          ),

          // Options List
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        'No matching services found'.tr,
                        style: TextStyle(color: AppThemeData.grey500),
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(14, 4, 14, 24),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final option = items[index];
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () => _onSelectOption(option),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isDarkMode ? AppThemeData.surface100Dark : Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isDarkMode ? Colors.white10 : Colors.black.withOpacity(0.06),
                              ),
                              boxShadow: isDarkMode
                                  ? null
                                  : [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.03),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Icon Circle
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: style.bg,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    option.icon,
                                    style: const TextStyle(fontSize: 24),
                                  ),
                                ),
                                const SizedBox(width: 14),

                                // Title & Description
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              option.title.tr,
                                              style: TextStyle(
                                                fontFamily: AppThemeData.bold,
                                                fontSize: 14,
                                                color: isDarkMode ? AppThemeData.grey900Dark : Colors.black,
                                              ),
                                            ),
                                          ),
                                          if (option.badge != null)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: style.color.withOpacity(0.12),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                option.badge!.tr,
                                                style: TextStyle(
                                                  fontFamily: AppThemeData.bold,
                                                  fontSize: 10,
                                                  color: style.color,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        option.description.tr,
                                        style: TextStyle(
                                          fontFamily: AppThemeData.regular,
                                          fontSize: 11.5,
                                          height: 1.25,
                                          color: isDarkMode ? AppThemeData.grey500Dark : AppThemeData.grey500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),

                                // Action Arrow
                                Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 14,
                                  color: isDarkMode ? Colors.white38 : Colors.black26,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
