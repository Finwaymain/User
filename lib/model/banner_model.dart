class BannerModel {
  String? success;
  String? error;
  String? message;
  List<BannerModelData>? data;

  BannerModel({this.success, this.error, this.message, this.data});

  BannerModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    error = json['error'];
    message = json['message'];
    if (json['data'] != null) {
      data = <BannerModelData>[];
      json['data'].forEach((v) {
        data!.add(BannerModelData.fromJson(v));
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

class BannerModelData {
  String? id;
  String? title;
  String? alt;
  String? link;
  String? targetApp;
  String? description;
  String? image;
  String? status;
  DateTime? createdAt;
  DateTime? updatedAt;

  BannerModelData({
    this.id,
    this.title,
    this.alt,
    this.link,
    this.targetApp,
    this.description,
    this.image,
    this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory BannerModelData.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic date) {
      if (date == null) return null;
      try {
        return DateTime.parse(date.toString());
      } catch (_) {
        return null;
      }
    }

    return BannerModelData(
      id: json['id']?.toString(),
      title: json['title']?.toString(),
      alt: json['alt']?.toString(),
      link: json['link']?.toString(),
      targetApp: json['target_app']?.toString(),
      description: json['description']?.toString(),
      image: json['image']?.toString(),
      status: json['status']?.toString(),
      createdAt: parseDate(json['created_at']),
      updatedAt: parseDate(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'alt': alt,
      'link': link,
      'target_app': targetApp,
      'description': description,
      'image': image,
      'status': status,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
