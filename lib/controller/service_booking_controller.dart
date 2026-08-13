import 'dart:async';
import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import 'package:finway/constant/show_toast_dialog.dart';
import 'package:finway/model/service_price_estimate_model.dart';
import 'package:finway/model/service_request_model.dart';
import 'package:finway/controller/service_history_controller.dart';
import 'package:finway/service/api.dart';
import 'package:finway/utils/Preferences.dart';

class ServiceBookingController extends GetxController {
  final Rx<ServiceRequestData?> booking = Rx<ServiceRequestData?>(null);
  final Rx<ServicePriceEstimate?> estimate = Rx<ServicePriceEstimate?>(null);
  final RxBool isLoading = false.obs;
  final RxString statusMessage = 'Searching nearby experts...'.obs;

  Timer? _pollTimer;

  @override
  void onClose() {
    _pollTimer?.cancel();
    super.onClose();
  }

  Future<ServicePriceEstimate?> fetchPriceEstimate({
    required String serviceName,
    List<String> serviceNames = const [],
    String? lat,
    String? lng,
  }) async {
    try {
      isLoading.value = true;
      final params = <String, String>{
        'service_name': serviceName,
        'service_names': serviceNames.join('|'),
      };
      if (lat != null && lat.isNotEmpty) params['lat'] = lat;
      if (lng != null && lng.isNotEmpty) params['lng'] = lng;

      final uri = Uri.parse(API.servicePriceEstimate).replace(queryParameters: params);
      final response = await http.get(uri, headers: API.header).timeout(const Duration(seconds: 20));
      final body = json.decode(response.body);
      if (response.statusCode == 200 && body['success'] == 'success') {
        final data = ServicePriceEstimate.fromJson(Map<String, dynamic>.from(body['data'] as Map));
        estimate.value = data;
        return data;
      }
      return null;
    } catch (_) {
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  Future<int?> bookService(Map<String, dynamic> bodyParams) async {
    try {
      final userId = ServiceHistoryController.resolveUserId();
      if (userId == 0) {
        ShowToastDialog.showToast("Please login to book a service".tr);
        return null;
      }

      bodyParams['user_id'] = userId.toString();
      final headers = Map<String, String>.from(API.header);
      headers['id_user'] = userId.toString();

      ShowToastDialog.showLoader("Booking service...".tr);
      final response = await http
          .post(Uri.parse(API.bookService), headers: headers, body: json.encode(bodyParams))
          .timeout(const Duration(seconds: 30));
      ShowToastDialog.closeLoader();

      final raw = response.body.trim();
      if (raw.isEmpty || raw.startsWith('<!DOCTYPE') || raw.startsWith('<html')) {
        ShowToastDialog.showToast('Server error while booking service'.tr);
        return null;
      }

      final body = json.decode(raw);
      if (response.statusCode == 200 && _isSuccess(body['success'])) {
        final data = body['data'];
        final id = data is Map ? int.tryParse(data['id']?.toString() ?? '') : null;
        if (id != null) {
          await refreshBooking(id);
        }
        return id;
      }

      ShowToastDialog.showToast(body['message']?.toString() ?? "Failed to submit request".tr);
      return null;
    } catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast("An error occurred: $e");
      return null;
    }
  }

  bool _isSuccess(dynamic value) {
    if (value == true) return true;
    final normalized = value?.toString().toLowerCase() ?? '';
    return normalized == 'success' || normalized == 'true';
  }

  ServiceRequestData? _parseBooking(dynamic raw) => ServiceRequestData.tryParse(raw);

  ServiceRequestData? _parseBookingLoose(Map<String, dynamic> json) {
    final item = ServiceRequestData.tryParse(json);
    if (item != null) return item;
    final id = int.tryParse(json['id']?.toString() ?? '');
    if (id == null || id <= 0) return null;
    return ServiceRequestData(
      id: id,
      serviceName: json['service_name']?.toString(),
      status: json['status']?.toString() ?? 'Pending',
      driverId: int.tryParse(json['driver_id']?.toString() ?? ''),
      amount: double.tryParse(json['amount']?.toString() ?? ''),
      paymentStatus: json['payment_status']?.toString(),
      otp: json['otp']?.toString(),
      priceBreakdown: ServicePriceEstimate.tryParse(json['price_breakdown']),
    );
  }

  Future<ServiceRequestData?> _fetchBookingFromHistory(int bookingId, int userId) async {
    try {
      final uri = Uri.parse(API.serviceHistory).replace(queryParameters: {'user_id': userId.toString()});
      final headers = Map<String, String>.from(API.header);
      headers['id_user'] = userId.toString();

      final response = await http.get(uri, headers: headers).timeout(const Duration(seconds: 15));
      final raw = response.body.trim();
      if (raw.isEmpty || raw.startsWith('<!DOCTYPE') || raw.startsWith('<html')) return null;

      final body = json.decode(raw);
      if (response.statusCode != 200 || !_isSuccess(body['success']) || body['data'] is! List) return null;

      for (final entry in body['data'] as List) {
        final item = _parseBooking(entry);
        if (item?.id != null && item!.id == bookingId) return item;
        if (entry is Map) {
          final loose = _parseBookingLoose(Map<String, dynamic>.from(entry));
          if (loose?.id != null && loose!.id == bookingId) return loose;
        }
      }
    } catch (_) {}
    return null;
  }

  Future<ServiceRequestData?> refreshBooking(int bookingId) async {
    final userId = ServiceHistoryController.resolveUserId();

    try {
      final headers = Map<String, String>.from(API.header);
      if (userId > 0) headers['id_user'] = userId.toString();

      final queryParams = userId > 0 ? {'user_id': userId.toString()} : <String, String>{};
      final uri = Uri.parse('${API.serviceBookingDetail}$bookingId').replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: headers).timeout(const Duration(seconds: 15));
      final raw = response.body.trim();
      if (raw.isEmpty || raw.startsWith('<!DOCTYPE') || raw.startsWith('<html')) {
        return _fetchBookingFromHistory(bookingId, userId);
      }

      final body = json.decode(raw);
      if (response.statusCode == 200 && _isSuccess(body['success']) && body['data'] is Map) {
        final data = Map<String, dynamic>.from(body['data'] as Map);
        final item = _parseBooking(data) ?? _parseBookingLoose(data);
        if (item != null) {
          booking.value = item;
          return item;
        }
      }
    } catch (_) {}

    return _fetchBookingFromHistory(bookingId, userId);
  }

  void startPolling(int bookingId, {void Function(ServiceRequestData)? onUpdate}) {
    _pollTimer?.cancel();

    Future<void> pollOnce() async {
      final item = await refreshBooking(bookingId);
      if (item == null) return;

      booking.value = item;
      onUpdate?.call(item);

      final status = (item.status ?? '').toLowerCase();
      if (item.shouldShowExpertAssigned) {
        statusMessage.value = 'Expert assigned successfully!'.tr;
      } else if (item.isAwaitingPayment && !item.isPaid) {
        statusMessage.value = 'Payment requested by expert'.tr;
      } else if (status == 'completed' || status == 'cancelled' || status == 'canceled') {
        _pollTimer?.cancel();
      }
    }

    pollOnce();
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) => pollOnce());
  }

  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<bool> cancelBooking({required int bookingId}) async {
    try {
      final userId = ServiceHistoryController.resolveUserId();
      if (userId == 0) return false;

      final headers = Map<String, String>.from(API.header);
      headers['id_user'] = userId.toString();

      ShowToastDialog.showLoader('Cancelling booking...'.tr);
      final response = await http
          .post(
            Uri.parse(API.cancelServiceBooking),
            headers: headers,
            body: json.encode({
              'user_id': userId.toString(),
              'booking_id': bookingId.toString(),
            }),
          )
          .timeout(const Duration(seconds: 20));
      ShowToastDialog.closeLoader();

      final body = json.decode(response.body);
      if (response.statusCode == 200 && body['success'] == 'success') {
        ShowToastDialog.showToast(body['message']?.toString() ?? 'Booking cancelled'.tr);
        await ServiceHistoryController.refreshAll();
        return true;
      }
      ShowToastDialog.showToast(body['message']?.toString() ?? 'Failed to cancel booking'.tr);
      return false;
    } catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast('Cancel error: $e');
      return false;
    }
  }

  Future<bool> payBooking({required int bookingId, required String paymentMethod}) async {
    try {
      final userId = ServiceHistoryController.resolveUserId();
      if (userId == 0) {
        ShowToastDialog.showToast('Please login to pay'.tr);
        return false;
      }

      final headers = Map<String, String>.from(API.header);
      headers['id_user'] = userId.toString();

      ShowToastDialog.showLoader("Processing payment...".tr);
      final response = await http
          .post(
            Uri.parse(API.payServiceBooking),
            headers: headers,
            body: json.encode({
              'user_id': userId.toString(),
              'booking_id': bookingId.toString(),
              'payment_method': paymentMethod,
            }),
          )
          .timeout(const Duration(seconds: 20));
      ShowToastDialog.closeLoader();

      final body = json.decode(response.body);
      if (response.statusCode == 200 && _isSuccess(body['success'])) {
        await refreshBooking(bookingId);
        await ServiceHistoryController.refreshAll();
        return true;
      }
      ShowToastDialog.showToast(body['message']?.toString() ?? 'Payment failed'.tr);
      return false;
    } catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast('Payment error: $e');
      return false;
    }
  }

  Future<double> fetchWalletBalance() async {
    try {
      final userId = ServiceHistoryController.resolveUserId();
      if (userId == 0) return 0;
      final response = await http.get(
        Uri.parse('${API.wallet}?id_user=$userId&user_cat=user_app'),
        headers: API.header,
      );
      final body = json.decode(response.body);
      if (response.statusCode == 200 && body['data'] != null) {
        return double.tryParse(body['data']['amount']?.toString() ?? '') ?? 0;
      }
    } catch (_) {}
    return 0;
  }
}
