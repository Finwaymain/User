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

  List<ServiceCategoryData> fallbackHomeCategories() {
    return List.generate(homeServiceCatalog.length, (i) {
      final name = homeServiceCatalog[i];
      final isLeaf = const {
        'Doctor Home Visit',
        'Physiotherapy',
        'Lab Sample Collection',
        'Nursing Care',
        'Ambulance Booking',
      }.contains(name);
      return ServiceCategoryData(
        id: -(i + 1),
        libelle: name,
        image: 'icon:${name}',
        hasChildren: !isLeaf,
      );
    });
  }

  Future<List<ServiceCategoryData>> fetchCategories({int? parentId}) async {
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
        return list;
      }
      return parentId == null ? fallbackHomeCategories() : [];
    } catch (e) {
      return parentId == null ? fallbackHomeCategories() : [];
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
