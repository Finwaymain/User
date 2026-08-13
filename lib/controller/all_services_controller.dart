import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import 'package:finway/constant/show_toast_dialog.dart';
import 'package:finway/model/service_category_model.dart';
import 'package:finway/page/features/AllServices/service_style.dart';
import 'package:finway/model/service_option_item_model.dart';
import 'package:finway/service/api.dart';
import 'package:finway/utils/Preferences.dart';

class AllServicesController extends GetxController {
  /// Exact Home Services grid shown on "More" (matches product mockup).
  static const List<String> homeServiceCatalog = [
    'Home Services',
    'Repair & Maintenance',
    'AC & Appliances',
    'Cleaning Services',
    'Interior & Renovation',
    'Outdoor Services',
    'Security & Safety',
    'Smart Home Services',
    'Water Services',
    'Construction Services',
    'Furniture Services',
    'Pest Control',
    'Shifting Services',
    'Personal Home Assistance',
    'Pet Services',
    'Laundry & Textile',
    'Technology Services',
    'Personal Services',
    'Education Services',
    'Healthcare Services',
  ];

  static const Map<String, List<String>> subCategoryCatalog = {
    'Doctor Home Visit': [
      'General Physician Visit',
      'Emergency Doctor Visit',
      'Respiratory & Fever Care',
      'Heart & BP Care',
      'Diabetes Care',
      'Pediatric (Child Doctor) Visit',
      'Elderly Care Visit',
      'Women\'s Health Visit',
      'Minor Injury & Wound Care',
      'ECG & Home Diagnostics',
    ],
    'Physiotherapy': [
      'Orthopedic Physiotherapy',
      'Post-Surgery Rehabilitation',
      'Neuro Physiotherapy',
      'Cardio & Pulmonary Rehab',
      'Pediatric & Geriatric Physiotherapy',
      'Sports Injury Rehabilitation',
      'Pain Management Therapy',
      'Mobility & Exercise Therapy',
    ],
    'Nursing Care': [
      'General Nurse Visit',
      'Injection & IV Drip Care',
      'Wound & Surgical Dressing',
      'Vital Monitoring',
      'Bedridden Patient Care',
      'Catheter & Tube Care',
      'Elderly Care Nursing',
      'Post-Surgery Nursing Care',
    ],
    'Lab Sample Collection': [
      'Complete Blood Count (CBC)',
      'Blood Sugar & HbA1c',
      'Thyroid Profile (T3, T4, TSH)',
      'Lipid Profile (Heart Risk)',
      'Liver Function Test (LFT)',
      'Kidney Function Test (KFT)',
      'Vitamin D & Vitamin B12 Test',
      'Iron Profile & Ferritin',
      'Routine Urine & Stool Examination',
      'Fever Panel (COVID, Dengue, Malaria, Typhoid)',
      'Cardiac Risk Markers & ECG at Home',
      'Hormone Panel (Testosterone, Estrogen, Cortisol)',
      'Pregnancy & Women\'s Health Tests (Beta hCG, PCOS)',
      'Full Body Health Checkup Package',
      'Senior Citizen Health Package',
      'Diabetes Care Health Suite',
      'Home Blood Sample Collection (Standard)',
      'Express Home Blood Sample Collection (1 Hr)',
    ],
    'Lab Technician': [
      'Complete Blood Count (CBC)',
      'Blood Sugar & HbA1c',
      'Thyroid Profile (T3, T4, TSH)',
      'Lipid Profile (Heart Risk)',
      'Liver Function Test (LFT)',
      'Kidney Function Test (KFT)',
      'Vitamin D & Vitamin B12 Test',
      'Iron Profile & Ferritin',
      'Routine Urine & Stool Examination',
      'Fever Panel (COVID, Dengue, Malaria, Typhoid)',
      'Cardiac Risk Markers & ECG at Home',
      'Hormone Panel (Testosterone, Estrogen, Cortisol)',
      'Pregnancy & Women\'s Health Tests (Beta hCG, PCOS)',
      'Full Body Health Checkup Package',
      'Senior Citizen Health Package',
      'Diabetes Care Health Suite',
      'Home Blood Sample Collection (Standard)',
      'Express Home Blood Sample Collection (1 Hr)',
    ],
    'Diagnostic Lab': [
      'Complete Blood Count (CBC)',
      'Blood Sugar & HbA1c',
      'Thyroid Profile (T3, T4, TSH)',
      'Lipid Profile (Heart Risk)',
      'Liver Function Test (LFT)',
      'Kidney Function Test (KFT)',
      'Vitamin D & Vitamin B12 Test',
      'Iron Profile & Ferritin',
      'Routine Urine & Stool Examination',
      'Fever Panel (COVID, Dengue, Malaria, Typhoid)',
      'Cardiac Risk Markers & ECG at Home',
      'Hormone Panel (Testosterone, Estrogen, Cortisol)',
      'Pregnancy & Women\'s Health Tests (Beta hCG, PCOS)',
      'Full Body Health Checkup Package',
      'Senior Citizen Health Package',
      'Diabetes Care Health Suite',
      'Home Blood Sample Collection (Standard)',
      'Express Home Blood Sample Collection (1 Hr)',
    ],
    'Home Tutor': [
      'School Tuition (Class 1-12)',
      'Mathematics & Science Tutor',
      'Physics & Chemistry Tutor',
      'CBSE / ICSE Board Tutor',
      'JEE / NEET Competitive Exam Tutor',
      'English & Foreign Language Tutor',
      'Computer & Coding Tutor',
    ],
    'Education Services': [
      'Home Tutor',
      'Music Teacher',
      'Dance Teacher',
      'Yoga Trainer',
      'Gym Trainer',
      'Language Tutor',
    ],
    'Healthcare Services': [
      'Doctor Home Visit',
      'Physiotherapy',
      'Lab Sample Collection',
      'Lab Technician',
      'Nursing Care',
      'Ambulance Booking',
    ],
    'Repair & Maintenance': [
      'Electrician',
      'Plumber',
      'Carpenter',
      'Painter',
      'Mason (Raj Mistri)',
      'Welder',
      'Handyman',
      'Door & Window Repair',
      'Furniture Repair',
    ],
    'AC & Appliances': [
      'AC Installation & Repair',
      'AC Gas Filling',
      'Refrigerator Repair',
      'Washing Machine Repair',
      'Microwave Repair',
      'Water Purifier (RO) Service',
      'Geyser Repair',
      'Chimney & Dishwasher Service',
      'TV Repair',
    ],
    'Cleaning Services': [
      'Home Deep Cleaning',
      'Bathroom Cleaning',
      'Kitchen Cleaning',
      'Sofa & Carpet Cleaning',
      'Mattress & Water Tank Cleaning',
      'Car Cleaning',
    ],
    'Personal Services': [
      'Barber & Men\'s Salon',
      'Women\'s Salon & Spa',
      'Massage Therapist',
    ],
    'Shifting Services': [
      'House Shifting',
      'Office Shifting',
      'Packers & Movers',
      'Local & Interstate Moving',
    ],
    'Personal Home Assistance': [
      'Maid Service',
      'Cook',
      'Babysitter',
      'Elder Care',
      'Patient Care',
      'Driver on Demand',
    ],
  };

  List<ServiceCategoryData> fallbackHomeCategories() {
    return List.generate(homeServiceCatalog.length, (i) {
      final name = homeServiceCatalog[i];
      final isLeaf = name == 'Ambulance Booking';
      return ServiceCategoryData(
        id: -(i + 1),
        libelle: name,
        image: 'icon:$name',
        hasChildren: !isLeaf,
      );
    });
  }

  static const Map<String, String> _catalogAliases = {
    'home tutor services': 'Home Tutor',
    'physiotherapist': 'Physiotherapy',
    'lab technician': 'Lab Sample Collection',
    'diagnostic lab': 'Lab Sample Collection',
    'blood test': 'Lab Sample Collection',
    'blood tests': 'Lab Sample Collection',
  };

  String _catalogKeyFor(String categoryName) {
    final clean = cleanServiceName(categoryName);
    if (subCategoryCatalog.containsKey(clean)) return clean;
    final alias = _catalogAliases[clean.toLowerCase()];
    if (alias != null) return alias;
    for (final key in subCategoryCatalog.keys) {
      final keyLower = key.toLowerCase();
      final cleanLower = clean.toLowerCase();
      if (keyLower.contains(cleanLower) || cleanLower.contains(keyLower)) {
        return key;
      }
    }
    return clean;
  }

  List<ServiceCategoryData> fallbackSubCategories(String categoryName) {
    final catalogKey = _catalogKeyFor(categoryName);
    final list = subCategoryCatalog[catalogKey] ?? [];
    if (list.isEmpty) return [];
    return List.generate(list.length, (i) {
      final name = list[i];
      return ServiceCategoryData(
        id: -(i + 100),
        libelle: name,
        image: 'icon:$name',
        hasChildren: isParentServiceCategory(name),
      );
    });
  }

  bool _isValidSelectionList(List<ServiceCategoryData> items, String categoryName) {
    if (items.isEmpty) return false;
    final clean = cleanServiceName(categoryName).toLowerCase();
    if (items.length == 1) {
      final only = cleanServiceName(items.first.libelle).toLowerCase();
      if (only == clean || only.contains(clean) || clean.contains(only)) return false;
    }
    return true;
  }

  /// Loads selectable options (tutor types, doctor types, lab tests, etc.).
  Future<List<ServiceCategoryData>> fetchSelectionOptions({
    int? categoryId,
    required String categoryName,
  }) async {
    final fallback = fallbackSubCategories(categoryName);
    try {
      if (categoryId != null && categoryId > 0) {
        final byParent = await fetchCategories(parentId: categoryId, categoryName: categoryName);
        if (_isValidSelectionList(byParent, categoryName)) return byParent;
      }
      return fallback;
    } catch (_) {
      return fallback;
    }
  }

  Future<List<ServiceCategoryData>> fetchCategories({int? parentId, String? categoryName}) async {
    final fallback = categoryName != null ? fallbackSubCategories(categoryName) : fallbackHomeCategories();

    try {
      final uri = parentId != null && parentId > 0
          ? Uri.parse(API.getServiceCategories).replace(queryParameters: {'parent_id': parentId.toString()})
          : (categoryName != null
              ? Uri.parse(API.getServiceCategories).replace(queryParameters: {'search': cleanServiceName(categoryName)})
              : Uri.parse(API.getServiceCategories));

      final response = await http.get(uri, headers: API.header).timeout(const Duration(seconds: 4));
      final body = json.decode(response.body);
      if (response.statusCode == 200 && body['success'] == 'success') {
        final list = (body['data'] as List).map((e) => ServiceCategoryData.fromJson(e)).toList();
        if (list.isNotEmpty) {
          if (parentId == null && categoryName == null) {
            return _onlyHomeCatalog(list);
          }
          if (categoryName != null && parentId == null && !_isValidSelectionList(list, categoryName)) {
            return fallback;
          }
          return list;
        }
      }
      return fallback;
    } catch (e) {
      return fallback;
    }
  }

  List<ServiceCategoryData> _onlyHomeCatalog(List<ServiceCategoryData> list) {
    final byName = <String, ServiceCategoryData>{};
    for (final item in list) {
      final name = cleanServiceName(item.libelle);
      if (homeServiceCatalog.contains(name)) {
        byName[name] = item;
      }
    }
    final ordered = <ServiceCategoryData>[];
    for (final name in homeServiceCatalog) {
      if (byName.containsKey(name)) {
        ordered.add(byName[name]!);
      }
    }
    return ordered.isNotEmpty ? ordered : fallbackHomeCategories();
  }

  Future<List<ServiceCategoryData>> searchCategories(String query) async {
    if (query.trim().isEmpty) return [];
    try {
      final uri = Uri.parse(API.getServiceCategories).replace(queryParameters: {'search': query.trim()});
      final response = await http.get(uri, headers: API.header);
      final body = json.decode(response.body);
      if (response.statusCode == 200 && body['success'] == 'success') {
        return (body['data'] as List).map((e) => ServiceCategoryData.fromJson(e)).toList();
      }
      final q = query.trim().toLowerCase();
      return fallbackHomeCategories().where((e) => (e.libelle ?? '').toLowerCase().contains(q)).toList();
    } catch (e) {
      final q = query.trim().toLowerCase();
      return fallbackHomeCategories().where((e) => (e.libelle ?? '').toLowerCase().contains(q)).toList();
    }
  }

  Future<bool> bookService(Map<String, dynamic> bodyParams) async {
    try {
      final userId = Preferences.getInt(Preferences.userId);
      if (userId == 0) {
        ShowToastDialog.showToast("Please login to book a service".tr);
        return false;
      }

      bodyParams['user_id'] = userId.toString();
      final headers = Map<String, String>.from(API.header);
      headers['id_user'] = userId.toString();

      ShowToastDialog.showLoader("Submitting request...".tr);
      final response = await http
          .post(
            Uri.parse(API.bookService),
            headers: headers,
            body: json.encode(bodyParams),
          )
          .timeout(const Duration(seconds: 30));
      ShowToastDialog.closeLoader();

      final raw = response.body.trim();
      if (raw.isEmpty || raw.startsWith('<!DOCTYPE') || raw.startsWith('<html')) {
        ShowToastDialog.showToast('Server error while booking service'.tr);
        return false;
      }

      final body = json.decode(raw);
      if (response.statusCode == 200 && body['success'] == 'success') {
        ShowToastDialog.showToast(body['message']?.toString() ?? "Service request submitted successfully".tr);
        return true;
      }
      ShowToastDialog.showToast(body['message']?.toString() ?? body['error']?.toString() ?? "Failed to submit request".tr);
      return false;
    } catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast("An error occurred: $e");
      return false;
    }
  }

  int? get currentUserId => Preferences.getInt(Preferences.userId);

  List<ServiceOptionItem> labTestOptions() {
    return const [
      ServiceOptionItem(
        id: 'cbc',
        title: 'Complete Blood Count (CBC)',
        description: 'Checks overall health, infection & anemia indicators',
        icon: '🩸',
      ),
      ServiceOptionItem(
        id: 'sugar_fasting_pp',
        title: 'Blood Sugar (Fasting & PP)',
        description: 'Fasting and post-meal blood glucose monitoring',
        icon: '🍬',
      ),
      ServiceOptionItem(
        id: 'hba1c',
        title: 'HbA1c (3-Month Glycated Hemoglobin)',
        description: 'Gold standard 3-month average blood sugar control',
        icon: '🍬',
      ),
      ServiceOptionItem(
        id: 'thyroid',
        title: 'Thyroid Profile (T3, T4, TSH)',
        description: 'Evaluates thyroid hormone levels and metabolism',
        icon: '🦋',
      ),
      ServiceOptionItem(
        id: 'lipid',
        title: 'Lipid Profile (Heart Risk & Cholesterol)',
        description: 'Cholesterol, HDL, LDL, and Triglycerides check',
        icon: '❤️',
      ),
      ServiceOptionItem(
        id: 'lft',
        title: 'Liver Function Test (LFT)',
        description: 'Bilirubin, SGPT, SGOT, Alk Phos & Liver enzymes',
        icon: '🏥',
      ),
      ServiceOptionItem(
        id: 'kft',
        title: 'Kidney Function Test (KFT / RFT)',
        description: 'Creatinine, Blood Urea Nitrogen, Uric Acid & Electrolytes',
        icon: '🏥',
      ),
      ServiceOptionItem(
        id: 'vit_d_b12',
        title: 'Vitamin D & Vitamin B12 Suite',
        description: 'Essential bone density, energy & nerve vitamin levels',
        icon: '☀️',
      ),
      ServiceOptionItem(
        id: 'iron_profile',
        title: 'Iron Profile & Ferritin Test',
        description: 'Serum iron, TIBC & Ferritin anemia evaluation',
        icon: '🩸',
      ),
      ServiceOptionItem(
        id: 'urine_routine',
        title: 'Routine Urine Examination & Culture',
        description: 'Screening for UTI, protein, pus cells & kidney indicators',
        icon: '🧪',
      ),
      ServiceOptionItem(
        id: 'fever_panel',
        title: 'Fever Panel (COVID, Dengue, Malaria, Typhoid)',
        description: 'Rapid diagnostic screening for viral & bacterial fevers',
        icon: '🤒',
      ),
      ServiceOptionItem(
        id: 'ecg_home',
        title: 'Home ECG & Cardiac Risk Markers',
        description: 'Portable digital 12-lead ECG recording at home',
        icon: '💓',
      ),
      ServiceOptionItem(
        id: 'hormone_panel',
        title: 'Hormone Profile (Testosterone, Estrogen, Cortisol)',
        description: 'Endocrine hormonal balance screening',
        icon: '🧬',
      ),
      ServiceOptionItem(
        id: 'full_body_package',
        title: 'Full Body Health Checkup Package',
        description: 'Comprehensive 60+ parameters essential health suite',
        icon: '🔬',
      ),
      ServiceOptionItem(
        id: 'senior_package',
        title: 'Senior Citizen Comprehensive Package',
        description: 'Heart, kidney, bone, vitamins & diabetes for seniors',
        icon: '🧓',
      ),
      ServiceOptionItem(
        id: 'express_blood_draw',
        title: 'Express Home Blood Sample Collection (1 Hr)',
        description: 'Urgent technician arrival for instant blood draw at home',
        icon: '⚡',
      ),
    ];
  }
}
