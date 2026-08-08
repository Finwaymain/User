import 'subscription_plan_model.dart';

class UserModel {
  UserModel({
    this.success,
    this.error,
    this.message,
    this.data,
  });

  String? success;
  dynamic error;
  String? message;
  User? data;

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    success: json["success"],
    error: json["error"],
    message: json["message"],
    data: json["data"] != null ? User.fromJson(json["data"]) : null,
  );

  Map<String, dynamic> toJson() => {
    "success": success,
    "error": error,
    "message": message,
    "data": data?.toJson(),
  };
}

class User {
  User({
    this.id,
    this.mPin,
    this.acNo,
    this.startDate,
    this.endDate,
    this.startDate2,
    this.endDate2,
    this.startDate3,
    this.endDate3,
    this.startDate4,
    this.endDate4,
    this.perSender,
    this.perReceiver,
    this.percentage,
    this.senderDesc,
    this.receiverDesc,
    this.description2nd,
    this.description3rd,
    this.per3rd,
    this.amount3rd,
    this.amount4th,
    this.description4th,
    this.kycStatus,
    this.nom,
    this.prenom,
    this.email,
    this.phone,
    this.loginType,
    this.photo,
    this.photoPath,
    this.photoNic,
    this.photoNicPath,
    this.statut,
    this.statutNic,
    this.tonotify,
    this.deviceId,
    this.fcmId,
    this.creer,
    this.updatedAt,
    this.modifier,
    this.amount,
    this.earnAmount,
    this.resetPasswordOtp,
    this.resetPasswordOtpModifier,
    this.age,
    this.gender,
    this.otp,
    this.otpCreated,
    this.deletedAt,
    this.createdAt,
    this.userCat,
    this.accesstoken,
    this.currency,
    this.decimalDigit,
    this.country,
    this.adminCommission,
    this.referralCode,
    this.referralBy,
    this.online,
    this.alternatePhone,
    this.marketplaceEnabled,
    this.consumerPlanId,
    this.consumerPlanExpiryDate,
    this.consumerPlan,
  });

  String? id;
  String? mPin;
  String? acNo;
  String? startDate;
  String? endDate;
  String? startDate2;
  String? endDate2;
  String? startDate3;
  String? endDate3;
  String? startDate4;
  String? endDate4;
  String? perSender;
  String? perReceiver;
  String? percentage;
  String? senderDesc;
  String? receiverDesc;
  String? description2nd;
  String? description3rd;
  String? per3rd;
  String? amount3rd;
  String? amount4th;
  String? description4th;
  String? kycStatus;
  String? nom;
  String? prenom;
  String? email;
  String? phone;
  String? loginType;
  String? photo;
  String? photoPath;
  String? photoNic;
  String? photoNicPath;
  String? statut;
  String? statutNic;
  String? tonotify;
  String? deviceId;
  String? fcmId;

  DateTime? creer;
  DateTime? updatedAt;
  DateTime? modifier;
  String? amount;
  String? earnAmount;
  String? resetPasswordOtp;
  String? resetPasswordOtpModifier;
  String? age;
  String? gender;
  String? otp;
  String? otpCreated;
  String? deletedAt;
  String? createdAt;
  String? userCat;
  String? accesstoken;
  String? currency;
  String? decimalDigit;
  String? country;
  String? adminCommission;
  String? referralCode;
  String? referralBy;
  String? consumerPlanId;
  String? consumerPlanExpiryDate;
  SubscriptionPlanData? consumerPlan;
  String? online;
  String? alternatePhone;
  String? marketplaceEnabled;

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json["id"]?.toString(),
    mPin: json["m_pin"]?.toString(),
    acNo: json["ac_no"]?.toString(),
    startDate: json["start_date"]?.toString(),
    endDate: json["end_date"]?.toString(),
    startDate2: json["start_date2"]?.toString(),
    endDate2: json["end_date2"]?.toString(),
    startDate3: json["start_date3"]?.toString(),
    endDate3: json["end_date3"]?.toString(),
    startDate4: json["start_date4"]?.toString(),
    endDate4: json["end_date4"]?.toString(),
    perSender: json["per_sender"]?.toString(),
    perReceiver: json["per_receiver"]?.toString(),
    percentage: json["percentage"]?.toString(),
    senderDesc: json["sender_desc"]?.toString(),
    receiverDesc: json["receiver_desc"]?.toString(),
    description2nd: json["description_2nd"]?.toString(),
    description3rd: json["description_3rd"]?.toString(),
    per3rd: json["per_3rd"]?.toString(),
    amount3rd: json["amount_3rd"]?.toString(),
    amount4th: json["amount_4th"]?.toString(),
    description4th: json["description_4th"]?.toString(),
    kycStatus: json["kyc_status"]?.toString(),
    nom: json["nom"]?.toString(),
    prenom: json["prenom"]?.toString(),
    email: json["email"]?.toString(),
    phone: json["phone"]?.toString(),
    loginType: json["login_type"]?.toString(),
    photo: json["photo"]?.toString(),
    photoPath: json["photo_path"]?.toString(),
    photoNic: json["photo_nic"]?.toString(),
    photoNicPath: json["photo_nic_path"]?.toString(),
    statut: json["statut"]?.toString(),
    statutNic: json["statut_nic"]?.toString(),
    tonotify: json["tonotify"]?.toString(),
    deviceId: json["device_id"]?.toString(),
    fcmId: json["fcm_id"]?.toString(),
    creer: json["creer"] != null ? DateTime.tryParse(json["creer"].toString()) : null,
    updatedAt: json["updated_at"] != null ? DateTime.tryParse(json["updated_at"].toString()) : null,
    modifier: json["modifier"] != null ? DateTime.tryParse(json["modifier"].toString()) : null,
    amount: json["amount"]?.toString(),
    earnAmount: json["earn_amount"]?.toString(),
    resetPasswordOtp: json["reset_password_otp"]?.toString(),
    resetPasswordOtpModifier: json["reset_password_otp_modifier"]?.toString(),
    age: json["age"]?.toString(),
    gender: json["gender"]?.toString(),
    otp: json["otp"]?.toString(),
    otpCreated: json["otp_created"]?.toString(),
    deletedAt: json["deleted_at"]?.toString(),
    createdAt: json["created_at"]?.toString(),
    userCat: json["user_cat"]?.toString(),
    accesstoken: json["accesstoken"]?.toString(),
    currency: json["currency"]?.toString(),
    decimalDigit: json["decimal_digit"]?.toString(),
    country: json["country"]?.toString(),
    adminCommission: json["admin_commission"]?.toString(),
    referralCode: json["referral_code"]?.toString(),
    referralBy: json["referral_by"]?.toString(),
    online: json["online"]?.toString(),
    alternatePhone: json["alternate_phone"]?.toString(),
    marketplaceEnabled: json["marketplace_enabled"]?.toString(),
    consumerPlanId: json["consumer_plan_id"]?.toString(),
    consumerPlanExpiryDate: json["consumer_plan_expiry_date"]?.toString(),
    consumerPlan: json["consumer_plan"] != null ? SubscriptionPlanData.fromJson(json["consumer_plan"]) : null,
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "m_pin": mPin,
    "ac_no": acNo,
    "start_date": startDate,
    "end_date": endDate,
    "start_date2": startDate2,
    "end_date2": endDate2,
    "start_date3": startDate3,
    "end_date3": endDate3,
    "start_date4": startDate4,
    "end_date4": endDate4,
    "per_sender": perSender,
    "per_receiver": perReceiver,
    "percentage": percentage,
    "sender_desc": senderDesc,
    "receiver_desc": receiverDesc,
    "description_2nd": description2nd,
    "description_3rd": description3rd,
    "per_3rd": per3rd,
    "amount_3rd": amount3rd,
    "amount_4th": amount4th,
    "description_4th": description4th,
    "kyc_status": kycStatus,
    "nom": nom,
    "prenom": prenom,
    "email": email,
    "phone": phone,
    "login_type": loginType,
    "photo": photo,
    "photo_path": photoPath,
    "photo_nic": photoNic,
    "photo_nic_path": photoNicPath,
    "statut": statut,
    "statut_nic": statutNic,
    "tonotify": tonotify,
    "device_id": deviceId,
    "fcm_id": fcmId,
    "creer": creer?.toIso8601String(),
    "updated_at": updatedAt?.toIso8601String(),
    "modifier": modifier?.toIso8601String(),
    "amount": amount,
    "earn_amount": earnAmount,
    "reset_password_otp": resetPasswordOtp,
    "reset_password_otp_modifier": resetPasswordOtpModifier,
    "age": age,
    "gender": gender,
    "otp": otp,
    "otp_created": otpCreated,
    "deleted_at": deletedAt,
    "created_at": createdAt,
    "user_cat": userCat,
    "accesstoken": accesstoken,
    "currency": currency,
    "decimal_digit": decimalDigit,
    "country": country,
    "admin_commission": adminCommission,
    "referral_code": referralCode,
    "referral_by": referralBy,
    "online": online,
    "alternate_phone": alternatePhone,
    "marketplace_enabled": marketplaceEnabled,
    "consumer_plan_id": consumerPlanId,
    "consumer_plan_expiry_date": consumerPlanExpiryDate,
    "consumer_plan": consumerPlan?.toJson(),
  };
}


// class UserModel {
//   UserModel({
//     this.success,
//     this.error,
//     this.message,
//     this.data,
//   });
//
//   String? success;
//   dynamic error;
//   String? message;
//   User? data;
//
//   factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
//         success: json["success"],
//         error: json["error"],
//         message: json["message"],
//         data: User.fromJson(json["data"]),
//       );
//
//   Map<String, dynamic> toJson() => {
//         "success": success,
//         "error": error,
//         "message": message,
//         "data": data!.toJson(),
//       };
// }
//
// class User {
//   User({
//     this.id,
//     this.nom,
//     this.prenom,
//     this.email,
//     this.phone,
//     this.loginType,
//     this.photo,
//     this.photoPath,
//     this.photoNic,
//     this.photoNicPath,
//     this.statut,
//     this.statutNic,
//     this.tonotify,
//     this.deviceId,
//     this.fcmId,
//     this.creer,
//     this.updatedAt,
//     this.modifier,
//     this.amount,
//     this.resetPasswordOtp,
//     this.resetPasswordOtpModifier,
//     this.age,
//     this.gender,
//     this.deletedAt,
//     this.createdAt,
//     this.userCat,
//     this.online,
//     this.country,
//     this.accesstoken,
//     this.adminCommission,
//   });
//
//   String? id;
//   String? nom;
//   String? prenom;
//   String? email;
//   String? phone;
//   String? loginType;
//   dynamic photo;
//   String? photoPath;
//   dynamic photoNic;
//   dynamic photoNicPath;
//   String? statut;
//   dynamic statutNic;
//   String? tonotify;
//   dynamic deviceId;
//   dynamic fcmId;
//
//   DateTime? creer;
//   DateTime? updatedAt;
//   DateTime? modifier;
//   dynamic amount;
//   dynamic resetPasswordOtp;
//   dynamic resetPasswordOtpModifier;
//   String? age;
//   String? gender;
//   dynamic deletedAt;
//   dynamic createdAt;
//   String? userCat;
//   String? online;
//   String? country;
//   String? accesstoken;
//   String? adminCommission;
//
//   factory User.fromJson(Map<String, dynamic> json) => User(
//         id: json["id"].toString(),
//         nom: json["nom"].toString(),
//         prenom: json["prenom"].toString(),
//         email: json["email"].toString(),
//         phone: json["phone"].toString(),
//         loginType: json["login_type"].toString(),
//         photo: json["photo"].toString(),
//         photoPath: json["photo_path"].toString(),
//         photoNic: json["photo_nic"].toString(),
//         photoNicPath: json["photo_nic_path"].toString(),
//         statut: json["statut"].toString(),
//         statutNic: json["statut_nic"].toString(),
//         tonotify: json["tonotify"].toString(),
//         deviceId: json["device_id"].toString(),
//         fcmId: json["fcm_id"].toString(),
//         creer: json["creer"] != null ? DateTime.parse(json["creer"].toString()) : null,
//         updatedAt: json["updated_at"] != null ? DateTime.parse(json["updated_at"].toString()) : null,
//         modifier: json["modifier"] != null ? DateTime.parse(json["modifier"].toString()) : null,
//         amount: json["amount"].toString(),
//         resetPasswordOtp: json["reset_password_otp"].toString(),
//         resetPasswordOtpModifier: json["reset_password_otp_modifier"].toString(),
//         age: json["age"].toString(),
//         gender: json["gender"].toString(),
//         deletedAt: json["deleted_at"].toString(),
//         createdAt: json["created_at"].toString(),
//         userCat: json["user_cat"].toString(),
//         online: json["online"].toString(),
//         country: json["country"].toString(),
//         accesstoken: json["accesstoken"].toString(),
//         adminCommission: json["admin_commission"].toString(),
//       );
//
//   Map<String, dynamic> toJson() => {
//         "id": id,
//         "nom": nom,
//         "prenom": prenom,
//         "email": email,
//         "phone": phone,
//         "login_type": loginType,
//         "photo": photo,
//         "photo_path": photoPath,
//         "photo_nic": photoNic,
//         "photo_nic_path": photoNicPath,
//         "statut": statut,
//         "statut_nic": statutNic,
//         "tonotify": tonotify,
//         "device_id": deviceId,
//         "fcm_id": fcmId,
//         "creer": creer!.toIso8601String(),
//         "updated_at": updatedAt!.toIso8601String(),
//         "modifier": modifier!.toIso8601String(),
//         "amount": amount,
//         "reset_password_otp": resetPasswordOtp,
//         "reset_password_otp_modifier": resetPasswordOtpModifier,
//         "age": age,
//         "gender": gender,
//         "deleted_at": deletedAt,
//         "created_at": createdAt,
//         "user_cat": userCat,
//         "online": online,
//         "country": country,
//         "accesstoken": accesstoken,
//         "admin_commission": adminCommission,
//       };
// }
