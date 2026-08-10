import 'dart:convert';

import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import 'package:finway/model/service_price_estimate_model.dart';
import 'package:finway/model/service_request_model.dart';
import 'package:finway/model/user_model.dart';
import 'package:finway/service/api.dart';
import 'package:finway/utils/Preferences.dart';

class ServiceHistoryController extends GetxController {
  final RxBool isLoading = true.obs;
  final RxList<ServiceRequestData> items = <ServiceRequestData>[].obs;
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchHistory();
  }

  static Future<void> refreshAll() async {
    for (final tag in ['service_history_false', 'service_history_true']) {
      if (Get.isRegistered<ServiceHistoryController>(tag: tag)) {
        await Get.find<ServiceHistoryController>(tag: tag).fetchHistory();
      }
    }
  }

  static int resolveUserId() {
    final stored = Preferences.getInt(Preferences.userId);
    if (stored > 0) return stored;

    try {
      final userJson = Preferences.getString(Preferences.user);
      if (userJson.isEmpty) return 0;
      final map = jsonDecode(userJson);
      if (map is! Map) return 0;
      final root = Map<String, dynamic>.from(map);
      int? resolved;
      if (root['data'] != null) {
        final userModel = UserModel.fromJson(root);
        resolved = int.tryParse(userModel.data?.id?.toString() ?? '');
      } else {
        resolved = int.tryParse(root['id']?.toString() ?? '');
      }
      if (resolved != null && resolved > 0) {
        Preferences.setInt(Preferences.userId, resolved);
        return resolved;
      }
      return 0;
    } catch (_) {
      return 0;
    }
  }

  bool _isSuccess(dynamic value) {
    if (value == true) return true;
    final normalized = value?.toString().toLowerCase() ?? '';
    return normalized == 'success' || normalized == 'true';
  }

  ServiceRequestData? _parseItemLoose(dynamic raw) {
    if (raw is! Map) return null;
    final json = Map<String, dynamic>.from(raw);
    final parsed = ServiceRequestData.tryParse(json);
    if (parsed != null && parsed.id != null && parsed.id! > 0) return parsed;

    final id = int.tryParse(json['id']?.toString() ?? '');
    if (id == null || id <= 0) return null;

    return ServiceRequestData(
      id: id,
      serviceName: json['service_name']?.toString(),
      addressType: json['address_type']?.toString(),
      serviceAddress: json['service_address']?.toString(),
      lat: json['lat']?.toString(),
      lng: json['lng']?.toString(),
      preferredDate: json['preferred_date']?.toString(),
      preferredTime: json['preferred_time']?.toString(),
      description: json['description']?.toString(),
      status: json['status']?.toString() ?? 'Pending',
      createdAt: json['created_at']?.toString(),
      driverId: int.tryParse(json['driver_id']?.toString() ?? ''),
      amount: double.tryParse(json['amount']?.toString() ?? ''),
      paymentStatus: json['payment_status']?.toString(),
      otp: json['otp']?.toString(),
      priceBreakdown: ServicePriceEstimate.tryParse(json['price_breakdown']),
    );
  }

  Future<void> fetchHistory() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final userId = ServiceHistoryController.resolveUserId();
      if (userId == 0) {
        items.clear();
        errorMessage.value = 'Please login to view service bookings';
        return;
      }

      final uri = Uri.parse(API.serviceHistory).replace(queryParameters: {'user_id': userId.toString()});
      final headers = Map<String, String>.from(API.header);
      headers['id_user'] = userId.toString();

      final response = await http.get(uri, headers: headers).timeout(const Duration(seconds: 20));
      final raw = response.body.trim();
      if (raw.isEmpty || raw.startsWith('<!DOCTYPE') || raw.startsWith('<html')) {
        errorMessage.value = 'Unable to load service bookings (server error)';
        items.clear();
        return;
      }

      final body = json.decode(raw);
      if (!_isSuccess(body['success'])) {
        errorMessage.value = body['message']?.toString() ?? 'Failed to load service bookings';
        items.clear();
        return;
      }

      final data = body['data'];
      late final List<dynamic> entries;
      if (data == null) {
        entries = [];
      } else if (data is List) {
        entries = data;
      } else {
        errorMessage.value = 'Invalid booking data received';
        items.clear();
        return;
      }

      final parsed = <ServiceRequestData>[];
      for (final entry in entries) {
        final item = _parseItemLoose(entry);
        if (item != null) parsed.add(item);
      }

      items.value = parsed;
      errorMessage.value = '';
    } catch (e) {
      errorMessage.value = 'Failed to load service bookings';
      items.clear();
    } finally {
      isLoading.value = false;
    }
  }

  List<ServiceRequestData> get pending => items.where((e) => e.isPending).toList();
  List<ServiceRequestData> get ongoing => items.where((e) => e.isOngoing).toList();
  List<ServiceRequestData> get history => items.where((e) => e.isHistory).toList();
}
