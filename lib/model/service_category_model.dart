class ServiceCategoryData {
  int? id;
  String? libelle;
  String? image;
  bool hasChildren;
  List<String> breadcrumb;
  int? parentId;

  ServiceCategoryData({
    this.id,
    this.libelle,
    this.image,
    this.hasChildren = false,
    this.breadcrumb = const [],
    this.parentId,
  });

  ServiceCategoryData.fromJson(Map<String, dynamic> json)
      : id = json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()),
        libelle = json['libelle']?.toString(),
        image = json['image']?.toString(),
        hasChildren = json['has_children'] == true,
        breadcrumb = json['breadcrumb'] is List
            ? (json['breadcrumb'] as List).map((e) => e.toString()).toList()
            : const [],
        parentId = json['parent_id'] is int
            ? json['parent_id']
            : int.tryParse(json['parent_id']?.toString() ?? '');
}
