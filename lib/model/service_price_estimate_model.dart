import 'dart:convert';
import 'package:finway/constant/constant.dart';

class ServicePriceLineItem {
  final String name;
  final double price;
  final double minPrice;
  final double maxPrice;
  final bool priceAvailable;
  final String priceLabel;

  ServicePriceLineItem({
    required this.name,
    required this.price,
    required this.minPrice,
    required this.maxPrice,
    required this.priceAvailable,
    this.priceLabel = '',
  });

  factory ServicePriceLineItem.fromJson(Map<String, dynamic> json) {
    final min = double.tryParse(json['min_price']?.toString() ?? json['price']?.toString() ?? '') ?? 0;
    final max = double.tryParse(json['max_price']?.toString() ?? json['price']?.toString() ?? '') ?? min;
    final available = json['price_available'] == true || min > 0 || max > 0;
    return ServicePriceLineItem(
      name: json['name']?.toString() ?? '',
      price: min,
      minPrice: min,
      maxPrice: max > 0 ? max : min,
      priceAvailable: available,
      priceLabel: json['price_label']?.toString() ?? '',
    );
  }

  static ServicePriceLineItem? tryParse(dynamic raw) {
    try {
      if (raw is! Map) return null;
      return ServicePriceLineItem.fromJson(Map<String, dynamic>.from(raw));
    } catch (_) {
      return null;
    }
  }

  String get displayPrice {
    if (priceLabel.isNotEmpty) return priceLabel;
    if (!priceAvailable) return 'Rate on visit';
    if (maxPrice > minPrice && (maxPrice - minPrice).abs() >= 1) {
      return '${Constant.currency ?? ''}${minPrice.toStringAsFixed(0)}-${Constant.currency ?? ''}${maxPrice.toStringAsFixed(0)}';
    }
    if (minPrice > 0) return '${Constant.currency ?? ''}${minPrice.toStringAsFixed(0)}';
    return 'Rate on visit';
  }

  static ServicePriceLineItem? matchForSelection(String name, List<ServicePriceLineItem> items) {
    final needle = name.toLowerCase().trim();
    if (needle.isEmpty) return null;

    for (final item in items) {
      final label = item.name.toLowerCase().trim();
      if (label == needle) return item;
    }

    for (final item in items) {
      final label = item.name.toLowerCase().trim();
      if (label.contains(needle)) return item;
    }

    return null;
  }
}

class ServicePriceEstimate {
  final List<ServicePriceLineItem> serviceItems;
  final double visitingCharge;
  final double visitingChargeMin;
  final double visitingChargeMax;
  final String visitingChargeLabel;
  final double platformFee;
  final double materialCost;
  final double servicesSubtotal;
  final double servicesSubtotalMin;
  final double servicesSubtotalMax;
  final double total;
  final double totalMin;
  final double totalMax;
  final String totalLabel;
  final int providersNearby;
  final String currencySymbol;

  ServicePriceEstimate({
    required this.serviceItems,
    required this.visitingCharge,
    required this.visitingChargeMin,
    required this.visitingChargeMax,
    required this.visitingChargeLabel,
    required this.platformFee,
    this.materialCost = 0,
    required this.servicesSubtotal,
    required this.servicesSubtotalMin,
    required this.servicesSubtotalMax,
    required this.total,
    required this.totalMin,
    required this.totalMax,
    required this.totalLabel,
    required this.providersNearby,
    this.currencySymbol = '',
  });

  factory ServicePriceEstimate.fromJson(Map<String, dynamic> json) {
    final items = <ServicePriceLineItem>[];
    for (final entry in (json['service_items'] as List? ?? [])) {
      final item = ServicePriceLineItem.tryParse(entry);
      if (item != null) items.add(item);
    }

    final totalMin = double.tryParse(json['total_min']?.toString() ?? json['total']?.toString() ?? '') ?? 0;
    final totalMax = double.tryParse(json['total_max']?.toString() ?? json['total']?.toString() ?? '') ?? totalMin;
    final visitMin = double.tryParse(json['visiting_charge_min']?.toString() ?? json['visiting_charge']?.toString() ?? '') ?? 0;
    final visitMax = double.tryParse(json['visiting_charge_max']?.toString() ?? json['visiting_charge']?.toString() ?? '') ?? visitMin;

    return ServicePriceEstimate(
      serviceItems: items,
      visitingCharge: visitMin,
      visitingChargeMin: visitMin,
      visitingChargeMax: visitMax,
      visitingChargeLabel: json['visiting_charge_label']?.toString() ?? '',
      platformFee: double.tryParse(json['platform_fee']?.toString() ?? '') ?? 0,
      materialCost: double.tryParse(json['material_cost']?.toString() ?? '') ?? 0,
      servicesSubtotal: double.tryParse(json['services_subtotal']?.toString() ?? '') ?? 0,
      servicesSubtotalMin: double.tryParse(json['services_subtotal_min']?.toString() ?? json['services_subtotal']?.toString() ?? '') ?? 0,
      servicesSubtotalMax: double.tryParse(json['services_subtotal_max']?.toString() ?? json['services_subtotal']?.toString() ?? '') ?? 0,
      total: totalMin,
      totalMin: totalMin,
      totalMax: totalMax,
      totalLabel: json['total_label']?.toString() ?? '',
      providersNearby: int.tryParse(json['providers_nearby']?.toString() ?? '') ?? 0,
      currencySymbol: json['currency_symbol']?.toString() ?? Constant.currency ?? '',
    );
  }

  static ServicePriceEstimate? tryParse(dynamic raw) {
    try {
      if (raw is String && raw.trim().isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          return ServicePriceEstimate.fromJson(Map<String, dynamic>.from(decoded));
        }
        return null;
      }
      if (raw is Map) {
        return ServicePriceEstimate.fromJson(Map<String, dynamic>.from(raw));
      }
    } catch (_) {}
    return null;
  }

  String get displayTotal {
    if (totalLabel.isNotEmpty) return totalLabel;
    if (totalMax > totalMin && (totalMax - totalMin).abs() >= 1 && totalMin > 0) {
      return '${Constant.currency ?? ''}${totalMin.toStringAsFixed(0)}-${Constant.currency ?? ''}${totalMax.toStringAsFixed(0)}';
    }
    if (totalMin > 0) return '${Constant.currency ?? ''}${totalMin.toStringAsFixed(0)}';
    return 'Rate on visit';
  }

  String get displayVisitingCharge {
    if (visitingChargeLabel.isNotEmpty) return visitingChargeLabel;
    if (visitingChargeMax > visitingChargeMin && (visitingChargeMax - visitingChargeMin).abs() >= 1 && visitingChargeMin > 0) {
      return '${Constant.currency ?? ''}${visitingChargeMin.toStringAsFixed(0)}-${Constant.currency ?? ''}${visitingChargeMax.toStringAsFixed(0)}';
    }
    if (visitingChargeMin > 0) return '${Constant.currency ?? ''}${visitingChargeMin.toStringAsFixed(0)}';
    return '';
  }

  bool get hasPricedServiceItems => serviceItems.any((item) => item.priceAvailable);

  String displayTotalFor({required bool includeServicePrices}) {
    if (!includeServicePrices) {
      return displayVisitingCharge.isNotEmpty ? displayVisitingCharge : 'Rate on visit';
    }
    return displayTotal;
  }

  double payableAmountFor({required bool includeServicePrices}) {
    if (!includeServicePrices) {
      return visitingChargeMin > 0 ? visitingChargeMin : totalMin;
    }
    return totalMin;
  }

  List<ServicePriceLineItem> lineItemsForSelection(List<String> selectedServices) {
    if (selectedServices.isEmpty) return const [];

    final rows = <ServicePriceLineItem>[];
    for (final name in selectedServices) {
      rows.add(
        ServicePriceLineItem.matchForSelection(name, serviceItems) ??
            ServicePriceLineItem(
              name: name,
              price: 0,
              minPrice: 0,
              maxPrice: 0,
              priceAvailable: false,
            ),
      );
    }
    return rows;
  }

  Map<String, dynamic> toBreakdownJson() => {
        'service_items': serviceItems
            .map((e) => {
                  'name': e.name,
                  'price': e.minPrice,
                  'min_price': e.minPrice,
                  'max_price': e.maxPrice,
                  'price_available': e.priceAvailable,
                  'price_label': e.displayPrice,
                })
            .toList(),
        'visiting_charge': visitingChargeMin,
        'visiting_charge_min': visitingChargeMin,
        'visiting_charge_max': visitingChargeMax,
        'visiting_charge_label': displayVisitingCharge,
        'platform_fee': platformFee,
        'services_subtotal': servicesSubtotalMin,
        'services_subtotal_min': servicesSubtotalMin,
        'services_subtotal_max': servicesSubtotalMax,
        'total': totalMin,
        'total_min': totalMin,
        'total_max': totalMax,
        'total_label': displayTotal,
        'providers_nearby': providersNearby,
      };
}

class ServiceDriverInfo {
  final int? id;
  final String? name;
  final String? phone;
  final String? photo;
  final String? rating;
  final String? profession;
  final int? reviewCount;
  final String? experience;
  final String? vehicleNumber;
  final String? etaLabel;

  ServiceDriverInfo({
    this.id,
    this.name,
    this.phone,
    this.photo,
    this.rating,
    this.profession,
    this.reviewCount,
    this.experience,
    this.vehicleNumber,
    this.etaLabel,
  });

  factory ServiceDriverInfo.fromJson(Map<String, dynamic>? json) {
    if (json == null) return ServiceDriverInfo();
    return ServiceDriverInfo(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? ''),
      name: json['name']?.toString(),
      phone: json['phone']?.toString(),
      photo: json['photo']?.toString(),
      rating: json['rating']?.toString(),
      profession: json['profession']?.toString(),
      reviewCount: int.tryParse(json['review_count']?.toString() ?? ''),
      experience: json['experience']?.toString(),
      vehicleNumber: json['vehicle_number']?.toString(),
      etaLabel: json['eta_label']?.toString(),
    );
  }

  String get ratingLabel {
    final r = rating ?? '4.8';
    final count = reviewCount ?? 0;
    if (count > 0) return '$r ($count Reviews)';
    return r;
  }
}
