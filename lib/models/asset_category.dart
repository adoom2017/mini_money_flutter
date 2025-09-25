class AssetCategory {
  final String id;
  final String name;
  final String icon;
  final String type; // 'asset' or 'liability'

  AssetCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.type,
  });

  factory AssetCategory.fromJson(Map<String, dynamic> json) {
    return AssetCategory(
      id: json['id'].toString(),
      name: json['name'],
      icon: json['icon'],
      type: json['type'],
    );
  }
}
