import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import 'package:finway/constant/show_toast_dialog.dart';
import 'package:finway/model/service_category_model.dart';
import 'package:finway/page/features/AllServices/service_style.dart';
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
    'Doctor Home Visit',
    'Physiotherapy',
    'Lab Sample Collection',
    'Nursing Care',
    'Ambulance Booking',
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
    'Home Tutor Services': [
      'School Tuition (Class 1-12)',
      'Mathematics & Science Tutor',
      'Physics & Chemistry Tutor',
      'CBSE / ICSE Board Tutor',
      'JEE / NEET Competitive Exam Tutor',
      'English & Foreign Language Tutor',
      'Computer & Coding Tutor',
      'Music & Dance Tutor',
      'Yoga & Fitness Trainer',
    ],
    'Education Services': [
      'Home Tutor Services',
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
        image: 'icon:${name}',
        hasChildren: !isLeaf,
      );
    });
  }

  List<ServiceCategoryData> fallbackSubCategories(String categoryName) {
    final cleanName = cleanServiceName(categoryName);
    final list = subCategoryCatalog[cleanName] ?? [];
    if (list.isEmpty) {
      // Find matching key
      for (final key in subCategoryCatalog.keys) {
        if (key.toLowerCase().contains(cleanName.toLowerCase()) || cleanName.toLowerCase().contains(key.toLowerCase())) {
          return List.generate(subCategoryCatalog[key]!.length, (i) {
            final name = subCategoryCatalog[key]![i];
            return ServiceCategoryData(
              id: -(i + 100),
              libelle: name,
              image: 'icon:${name}',
              hasChildren: false,
            );
          });
        }
      }
      return [];
    }
    return List.generate(list.length, (i) {
      final name = list[i];
      final subHasChildren = subCategoryCatalog.containsKey(name);
      return ServiceCategoryData(
        id: -(i + 100),
        libelle: name,
        image: 'icon:${name}',
        hasChildren: subHasChildren,
      );
    });
  }

  Future<List<ServiceCategoryData>> fetchCategories({int? parentId, String? categoryName}) async {
    try {
      final uri = parentId != null
          ? Uri.parse(API.getServiceCategories).replace(queryParameters: {'parent_id': parentId.toString()})
          : Uri.parse(API.getServiceCategories);
      final response = await http.get(uri, headers: API.header);
      final body = json.decode(response.body);
      if (response.statusCode == 200 && body['success'] == 'success') {
        final list = (body['data'] as List).map((e) => ServiceCategoryData.fromJson(e)).toList();
        if (parentId == null) {
          if (list.isEmpty) return fallbackHomeCategories();
          return _onlyHomeCatalog(list);
        }
        if (list.isEmpty && categoryName != null) {
          return fallbackSubCategories(categoryName);
        }
        return list;
      }
      if (parentId == null) return fallbackHomeCategories();
      return categoryName != null ? fallbackSubCategories(categoryName) : [];
    } catch (e) {
      if (parentId == null) return fallbackHomeCategories();
      return categoryName != null ? fallbackSubCategories(categoryName) : [];
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
      ShowToastDialog.showLoader("Submitting request...".tr);
      final response = await http.post(
        Uri.parse(API.bookService),
        headers: API.header,
        body: json.encode(bodyParams),
      );
      ShowToastDialog.closeLoader();
      final body = json.decode(response.body);
      if (response.statusCode == 200 && body['success'] == 'success') {
        ShowToastDialog.showToast("Service request submitted successfully".tr);
        return true;
      }
      ShowToastDialog.showToast(body['message']?.toString() ?? "Failed to submit request".tr);
      return false;
    } catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast("An error occurred: $e");
      return false;
    }
  }

  int? get currentUserId => Preferences.getInt(Preferences.userId);
}
