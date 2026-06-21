class CardData {
  final int id;
  final String name;
  final String type;
  final double limit;
  final double price;
  final String limitText;
  final List<String> gradientColors;
  final List<String> features;
  final CardDesign cardDesign;

  CardData({
    required this.id,
    required this.name,
    required this.type,
    required this.limit,
    required this.price,
    required this.limitText,
    required this.gradientColors,
    required this.features,
    required this.cardDesign,
  });

  factory CardData.fromJson(Map<String, dynamic> json) {
    return CardData(
      id: json['id'],
      name: json['name'],
      type: json['type'],
      limit: json['limit'].toDouble(),
      price: json['price'].toDouble(),
      limitText: json['limitText'],
      gradientColors: List<String>.from(json['gradientColors']),
      features: List<String>.from(json['features']),
      cardDesign: CardDesign.fromJson(json['cardDesign']),
    );
  }
}

class CardDesign {
  final String backgroundColor;
  final bool hasPattern;
  final String cardNumber;
  final bool showIcons;

  CardDesign({
    required this.backgroundColor,
    required this.hasPattern,
    required this.cardNumber,
    required this.showIcons,
  });

  factory CardDesign.fromJson(Map<String, dynamic> json) {
    return CardDesign(
      backgroundColor: json['backgroundColor'],
      hasPattern: json['hasPattern'],
      cardNumber: json['cardNumber'],
      showIcons: json['showIcons'],
    );
  }
}

class PurchasedCard {
  final String id;
  final CardData cardData;
  final String cardNumber;
  double balance;
  final DateTime purchaseDate;
  final List<ClaimRecord> claims;



  PurchasedCard({
    required this.id,
    required this.cardData,
    required this.cardNumber,
    required this.balance,
    required this.purchaseDate,
    List<ClaimRecord>? claims,
  }) : claims = claims ?? [];

  void addClaim(ClaimRecord claim) {
    claims.add(claim);
    balance += claim.approvedAmount;
  }
}

class ClaimRecord {
  final String id;
  final String prescriptionPath;
  final String menuPath;
  final String dischargeDocPath;
  final double claimAmount;
  final double approvedAmount;
  final DateTime fromDate;
  final DateTime toDate;
  final DateTime submittedDate;
  final ClaimStatus status;

  ClaimRecord({
    required this.id,
    required this.prescriptionPath,
    required this.menuPath,
    required this.dischargeDocPath,
    required this.claimAmount,
    required this.approvedAmount,
    required this.fromDate,
    required this.toDate,
    required this.submittedDate,
    required this.status,
  });
}

enum ClaimStatus {
  pending,
  approved,
  rejected
}