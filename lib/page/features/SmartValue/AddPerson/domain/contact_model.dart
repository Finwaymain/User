class ContactModel {
  final String? id;
  final String? userId;
  final String name;
  final String? status;
  final String? createdAt;
  final String? updatedAt;
  final String number;

  ContactModel({
    this.id,
     this.userId,
    required this.name,
     this.status,
     this.createdAt,
     this.updatedAt,
    required this.number,
  });

  factory ContactModel.fromJson(Map<String, dynamic> json) {
    return ContactModel(
      id: json['id'].toString(),
      userId: json['user_id'].toString(),
      name: json['name'] ?? '',
      status: json['status'] ?? '',
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      number: json['mobile_no'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "user_id": userId,
      "name": name,
      "status": status,
      "created_at": createdAt,
      "updated_at": updatedAt,
      "mobile_no": number,
    };
  }
}
