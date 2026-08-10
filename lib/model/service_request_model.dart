import 'dart:convert';

import 'service_price_estimate_model.dart';

class ServiceRequestData {
  final int? id;
  final String? serviceName;
  final String? addressType;
  final String? serviceAddress;
  final String? lat;
  final String? lng;
  final String? preferredDate;
  final String? preferredTime;
  final String? description;
  final String? status;
  final String? createdAt;
  final int? driverId;
  final double? amount;
  final String? paymentStatus;
  final String? otp;
  final ServiceDriverInfo? driver;
  final ServicePriceEstimate? priceBreakdown;

  ServiceRequestData({
    this.id,
    this.serviceName,
    this.addressType,
    this.serviceAddress,
    this.lat,
    this.lng,
    this.preferredDate,
    this.preferredTime,
    this.description,
    this.status,
    this.createdAt,
    this.driverId,
    this.amount,
    this.paymentStatus,
    this.otp,
    this.driver,
    this.priceBreakdown,
  });

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  static String normalizeServiceOtp(String? raw) {
    return (raw ?? '').replaceAll(RegExp(r'\D'), '');
  }

  static String displayServiceOtp(String? raw) {
    final digits = normalizeServiceOtp(raw);
    if (digits.isEmpty) return '';
    return digits.padLeft(4, '0');
  }

  static String? _parseString(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    if (value is Map && value['date'] != null) return value['date'].toString();
    return value.toString();
  }

  factory ServiceRequestData.fromJson(Map<String, dynamic> json) {
    final breakdown = ServicePriceEstimate.tryParse(json['price_breakdown']);
    final driver = ServiceDriverInfo.fromJson(json['driver'] is Map ? Map<String, dynamic>.from(json['driver'] as Map) : null);
    final parsedDriverId = _parseInt(json['driver_id']) ?? driver.id;

    return ServiceRequestData(
      id: _parseInt(json['id']),
      serviceName: _parseString(json['service_name']),
      addressType: _parseString(json['address_type']),
      serviceAddress: _parseString(json['service_address']),
      lat: _parseString(json['lat']),
      lng: _parseString(json['lng']),
      preferredDate: _parseString(json['preferred_date']),
      preferredTime: _parseString(json['preferred_time']),
      description: _parseString(json['description']),
      status: _parseString(json['status']),
      createdAt: _parseString(json['created_at']),
      driverId: parsedDriverId,
      amount: double.tryParse(json['amount']?.toString() ?? ''),
      paymentStatus: _parseString(json['payment_status']),
      otp: _parseString(json['otp']),
      driver: driver,
      priceBreakdown: breakdown,
    );
  }

  static ServiceRequestData? tryParse(dynamic raw) {
    try {
      if (raw is! Map) return null;
      return ServiceRequestData.fromJson(Map<String, dynamic>.from(raw));
    } catch (_) {
      return null;
    }
  }

  String get _normalizedStatus => (status ?? 'Pending').toLowerCase().trim();

  String get statusLabel {
    final s = _normalizedStatus;
    if (s == 'accepted') return 'Accepted';
    if (s == 'awaiting payment' || s == 'awaiting_payment') return 'Awaiting Payment';
    if (s == 'in progress' || s == 'in_progress') return 'In Progress';
    if (s == 'completed') return 'Completed';
    if (s == 'rejected') return 'Rejected';
    if (s == 'cancelled' || s == 'canceled') return 'Cancelled';
    return 'Pending';
  }

  bool get isCancelled => _normalizedStatus == 'cancelled' || _normalizedStatus == 'canceled';

  bool get isPending {
    if (isHistory || isOngoing) return false;
    final s = _normalizedStatus;
    return s.isEmpty || s == 'pending';
  }

  bool get isAwaitingPayment =>
      _normalizedStatus == 'awaiting payment' || _normalizedStatus == 'awaiting_payment';

  bool get needsPayment => isAwaitingPayment && !isPaid;

  bool get isOngoing {
    final s = _normalizedStatus;
    if (hasAssignedDriver && (s == 'pending' || s.isEmpty)) return true;
    return s == 'accepted' ||
        s == 'confirmed' ||
        s == 'in progress' ||
        s == 'in_progress' ||
        s == 'awaiting payment' ||
        s == 'awaiting_payment' ||
        s == 'started' ||
        s == 'on ride' ||
        s == 'onride' ||
        s == 'on_ride';
  }

  bool get isHistory {
    final s = _normalizedStatus;
    return s == 'completed' || s == 'rejected' || s == 'cancelled' || s == 'canceled';
  }

  bool get isCompleted => _normalizedStatus == 'completed';

  bool get isPaid {
    final p = (paymentStatus ?? '').toLowerCase();
    return p == 'paid' || p == 'paid_cash' || p == 'paid_wallet' || p == 'paid_upi' || p == 'yes';
  }

  bool get hasAssignedDriver {
    if (driverId != null && driverId! > 0) return true;
    return driver?.id != null && driver!.id! > 0;
  }

  String get scheduleLabel {
    final date = preferredDate ?? '';
    final time = preferredTime ?? '';
    if (date.isEmpty && time.isEmpty) return 'Schedule not set';
    if (time.isEmpty) return date;
    return '$date · $time';
  }

  bool get canTrackLive =>
      !isCancelled && (isPending || isOngoing || needsPayment || (isCompleted && isPaid));

  String get trackActionLabel {
    if (needsPayment) return 'Pay Now';
    if (isCompleted && isPaid) return 'View Receipt';
    if (isOngoing) return 'View Expert';
    return 'Track Booking';
  }

  bool get shouldShowExpertAssigned {
    if (isCancelled) return false;
    if (isCompleted && isPaid) return false;
    return hasAssignedDriver;
  }

  double get payableAmount {
    final breakdown = priceBreakdown;
    if (breakdown != null) {
      final visit = breakdown.visitingChargeMin > 0 ? breakdown.visitingChargeMin : breakdown.visitingCharge;
      final material = breakdown.materialCost;
      final platform = breakdown.platformFee;
      final services = breakdown.serviceItems.fold<double>(0, (t, e) => t + e.minPrice);
      final calculated = services + visit + material + platform;
      if (calculated > 0) return calculated;
      if (breakdown.totalMin > 0) return breakdown.totalMin;
    }
    if (amount != null && amount! > 0) return amount!;
    if (breakdown != null) {
      final services = breakdown.serviceItems.fold<double>(0, (t, e) => t + e.minPrice);
      final visit = breakdown.visitingChargeMin > 0 ? breakdown.visitingChargeMin : breakdown.visitingCharge;
      final material = breakdown.materialCost;
      final platform = breakdown.platformFee;
      final sum = services + visit + material + platform;
      if (sum > 0) return sum;
    }
    return 0;
  }

  double get materialCostAmount => priceBreakdown?.materialCost ?? 0;

  double get visitingChargeAmount =>
      priceBreakdown?.visitingChargeMin ?? priceBreakdown?.visitingCharge ?? 0;

  String get visitingChargeLabel {
    final label = priceBreakdown?.visitingChargeLabel ?? '';
    if (label.isNotEmpty) return label;
    if (visitingChargeAmount > 0) return '₹${visitingChargeAmount.toStringAsFixed(0)}';
    return '';
  }

  String get displayPayableLabel {
    if (amount != null && amount! > 0) {
      return '₹${amount!.toStringAsFixed(0)}';
    }
    final breakdownLabel = priceBreakdown?.displayTotal ?? '';
    if (breakdownLabel.isNotEmpty && breakdownLabel != 'Rate on visit') {
      return breakdownLabel;
    }
    if (payableAmount > 0) {
      return '₹${payableAmount.toStringAsFixed(0)}';
    }
    return 'Rate on visit';
  }

  bool get hasServiceOtp => ServiceRequestData.normalizeServiceOtp(otp).length >= 4;

  List<ServicePriceLineItem> get bookedServiceItems {
    if (priceBreakdown != null && priceBreakdown!.serviceItems.isNotEmpty) {
      return priceBreakdown!.serviceItems;
    }
    final raw = (serviceName ?? '').split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    if (raw.isEmpty) {
      return [
        ServicePriceLineItem(
          name: serviceName ?? 'Service',
          price: payableAmount,
          minPrice: payableAmount,
          maxPrice: payableAmount,
          priceAvailable: payableAmount > 0,
        ),
      ];
    }
    return raw
        .map(
          (name) => ServicePriceLineItem(
            name: name,
            price: 0,
            minPrice: 0,
            maxPrice: 0,
            priceAvailable: false,
          ),
        )
        .toList();
  }
}
