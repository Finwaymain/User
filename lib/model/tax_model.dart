class TaxModel {
  String? id;
  String? libelle;
  String? value;
  String? type;
  String? country;
  String? statut;
  String? applicableOn;

  TaxModel({this.country, this.statut, this.value, this.id, this.type, this.libelle, this.applicableOn});

  TaxModel.fromJson(Map<String, dynamic> json) {
    country = json['country']?.toString();
    statut = json['statut']?.toString();
    value = json['value']?.toString();
    id = json['id']?.toString();
    type = json['type']?.toString();
    libelle = json['libelle']?.toString();
    applicableOn = json['applicable_on']?.toString();
  }

  bool isApplicableFor(String method) {
    if (statut != null && statut != 'yes') return false;
    if (applicableOn == null || applicableOn!.trim().isEmpty) return true;
    final list = applicableOn!.toLowerCase().split(',').map((e) => e.trim()).toList();
    final m = method.toLowerCase().trim();
    return list.contains(m) || (m == 'upi' && list.contains('online')) || (m == 'online' && list.contains('upi'));
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['country'] = country;
    data['statut'] = statut;
    data['value'] = value;
    data['id'] = id;
    data['type'] = type;
    data['libelle'] = libelle;
    data['applicable_on'] = applicableOn;
    return data;
  }
}
