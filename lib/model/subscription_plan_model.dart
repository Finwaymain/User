import 'dart:convert';

class SubscriptionPlanModel {
  String? success;
  String? error;
  String? message;
  List<SubscriptionPlanData>? data;

  SubscriptionPlanModel({this.success, this.error, this.message, this.data});

  SubscriptionPlanModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    error = json['error'];
    message = json['message'];
    if (json['data'] != null) {
      data = <SubscriptionPlanData>[];
      json['data'].forEach((v) {
        data!.add(SubscriptionPlanData.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['success'] = success;
    data['error'] = error;
    data['message'] = message;
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class SubscriptionPlanData {
  String? id;
  String? bookingLimit;
  String? description;
  String? expiryDay;
  String? image;
  String? isEnable;
  String? name;
  String? place;
  List<String>? planPoints;
  String? price;
  String? type;
  String? createdAt;
  String? updatedAt;
  String? cashbackOnPurchase;
  int? tierLevel;
  String? badge;
  List<String>? benefitsList;
  List<String>? chargeableItems;

  SubscriptionPlanData(
      {this.id,
        this.bookingLimit,
        this.description,
        this.expiryDay,
        this.image,
        this.isEnable,
        this.name,
        this.place,
        this.planPoints,
        this.price,
        this.type,
        this.createdAt,
        this.updatedAt,
        this.cashbackOnPurchase,
        this.tierLevel,
        this.badge,
        this.benefitsList,
        this.chargeableItems});

  SubscriptionPlanData.fromJson(Map<String, dynamic> json) {
    id = json['id']?.toString();
    // Handle both driver plan (bookingLimit) and consumer plan (validity_days) fields
    bookingLimit = json['bookingLimit']?.toString() ?? json['validity_days']?.toString();
    description = json['description']?.toString();
    // Handle both driver plan (expiryDay) and consumer plan (validity_days/expiryDay) fields
    expiryDay = json['expiryDay']?.toString() ?? json['validity_days']?.toString();
    image = json['image']?.toString();
    // Handle both driver plan (isEnable) and consumer plan (status) fields
    isEnable = json['isEnable']?.toString() ?? json['status']?.toString();
    name = json['name']?.toString();
    // Handle both driver plan (place) and consumer plan (display_order) fields
    place = json['place']?.toString() ?? json['display_order']?.toString();
    if (json['plan_points'] != null) {
      var points = json['plan_points'];
      if (points is String) {
        try {
          var decoded = jsonDecode(points);
          if (decoded is List) {
            planPoints = List<String>.from(decoded.map((e) => e.toString()));
          } else {
            planPoints = [decoded.toString()];
          }
        } catch (e) {
          planPoints = [points.toString()];
        }
      } else if (points is List) {
        planPoints = List<String>.from(points.map((e) => e.toString()));
      } else {
        planPoints = [points.toString()];
      }
    } else {
      planPoints = [];
    }
    price = json['price']?.toString();
    type = json['type']?.toString() ?? json['status']?.toString();
    cashbackOnPurchase = json['cashback_on_purchase']?.toString();
    tierLevel = json['tier_level'] != null ? int.tryParse(json['tier_level'].toString()) : null;
    badge = json['badge']?.toString();
    if (json['benefits_list'] != null) {
      var benefits = json['benefits_list'];
      if (benefits is String) {
        try {
          var decoded = jsonDecode(benefits);
          if (decoded is List) {
            benefitsList = List<String>.from(decoded.map((e) => e.toString()));
          } else {
            benefitsList = [decoded.toString()];
          }
        } catch (_) {
          benefitsList = [benefits.toString()];
        }
      } else if (benefits is List) {
        benefitsList = List<String>.from(benefits.map((e) => e.toString()));
      }
    }
    if (json['chargeable_items'] != null) {
      var items = json['chargeable_items'];
      if (items is String) {
        try {
          var decoded = jsonDecode(items);
          if (decoded is List) {
            chargeableItems = List<String>.from(decoded.map((e) => e.toString()));
          } else {
            chargeableItems = [decoded.toString()];
          }
        } catch (_) {
          chargeableItems = [items.toString()];
        }
      } else if (items is List) {
        chargeableItems = List<String>.from(items.map((e) => e.toString()));
      }
    }
    createdAt = json['created_at']?.toString();
    updatedAt = json['updated_at']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['bookingLimit'] = bookingLimit;
    data['description'] = description;
    data['expiryDay'] = expiryDay;
    data['image'] = image;
    data['isEnable'] = isEnable;
    data['name'] = name;
    data['place'] = place;
    data['plan_points'] = planPoints;
    data['price'] = price;
    data['type'] = type;
    data['cashback_on_purchase'] = cashbackOnPurchase;
    data['tier_level'] = tierLevel;
    data['badge'] = badge;
    data['benefits_list'] = benefitsList;
    data['chargeable_items'] = chargeableItems;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    return data;
  }
}
