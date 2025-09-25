class AssetRecord {
  final String id;
  final DateTime date;
  final double amount;

  AssetRecord({
    required this.id,
    required this.date,
    required this.amount,
  });

  factory AssetRecord.fromJson(Map<String, dynamic> json) {
    return AssetRecord(
      id: json['id'].toString(),
      date: DateTime.parse(json['date']),
      amount: (json['amount'] as num).toDouble(),
    );
  }
}

class Asset {
  final String id;
  final String name;
  final String category;
  final String categoryId;
  final List<AssetRecord> records;

  Asset({
    required this.id,
    required this.name,
    required this.category,
    required this.categoryId,
    required this.records,
  });

  factory Asset.fromJson(Map<String, dynamic> json) {
    var recordsList = (json['records'] as List? ?? [])
        .map((recordJson) => AssetRecord.fromJson(recordJson))
        .toList();
        
    // Sort records by date descending to easily get the latest
    recordsList.sort((a, b) => b.date.compareTo(a.date));

    return Asset(
      id: json['id'].toString(),
      name: json['name'],
      category: json['category'] ?? '',
      categoryId: json['categoryId'].toString(),
      records: recordsList,
    );
  }

  double get latestAmount => records.isEmpty ? 0.0 : records.first.amount;
}
