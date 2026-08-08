class TransactionModel {
  String? success;
  String? error;
  String? message;
  List<TransactionData>? data;

  TransactionModel({this.success, this.error, this.message, this.data});

  TransactionModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    error = json['error'];
    message = json['message'];
    if (json['data'] != null) {
      data = <TransactionData>[];
      json['data'].forEach((v) {
        data!.add(TransactionData.fromJson(v));
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

class TransactionData {
  String? id;
  String? amount;
  String? idUserApp;
  String? deductionType;
  String? rideId;
  String? paymentMethod;
  String? paymentStatus;
  String? creer;
  String? modifier;
  String? description;
  String? txnId;
  String? type;
  String? date;
  String? categoryTitle;
  String? counterpartyName;
  String? formattedDate;
  String? statusLabel;
  String? iconType;

  TransactionData({
    this.id,
    this.amount,
    this.idUserApp,
    this.deductionType,
    this.rideId,
    this.paymentMethod,
    this.paymentStatus,
    this.creer,
    this.modifier,
    this.description,
    this.txnId,
    this.type,
    this.date,
    this.categoryTitle,
    this.counterpartyName,
    this.formattedDate,
    this.statusLabel,
    this.iconType,
  });

  TransactionData.fromJson(Map<String, dynamic> json) {
    id = json['id']?.toString();
    amount = json['amount']?.toString();
    idUserApp = json['id_user_app']?.toString();
    deductionType = json['deduction_type']?.toString();
    rideId = json['ride_id']?.toString();
    paymentMethod = json['payment_method']?.toString();
    paymentStatus = json['payment_status']?.toString();
    creer = json['creer']?.toString();
    modifier = json['modifier']?.toString();
    description = json['description']?.toString();
    txnId = json['txn_id']?.toString();
    type = json['type']?.toString();
    date = json['date']?.toString();
    categoryTitle = json['category_title']?.toString();
    counterpartyName = json['counterparty_name']?.toString();
    formattedDate = json['formatted_date']?.toString();
    statusLabel = json['status_label']?.toString();
    iconType = json['icon_type']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['amount'] = amount;
    data['id_user_app'] = idUserApp;
    data['deduction_type'] = deductionType;
    data['ride_id'] = rideId;
    data['payment_method'] = paymentMethod;
    data['payment_status'] = paymentStatus;
    data['creer'] = creer;
    data['modifier'] = modifier;
    data['description'] = description;
    data['txn_id'] = txnId;
    data['type'] = type;
    data['date'] = date;
    data['category_title'] = categoryTitle;
    data['counterparty_name'] = counterpartyName;
    data['formatted_date'] = formattedDate;
    data['status_label'] = statusLabel;
    data['icon_type'] = iconType;
    return data;
  }
}
