class PackageData {
  String id;
  String description;
  int value;
  double pricePerUnit;
  String packageType; // "DATA_ENRICHMENT"

  PackageData({
    required this.id,
    required this.description,
    required this.value,
    required this.pricePerUnit,
    required this.packageType,
  });

  factory PackageData.fromJson(Map<String, dynamic> json) {
    return PackageData(
      id: json['id'] ?? '',
      description: json['description'] ?? '',
      value: json['value'] ?? 0,
      pricePerUnit: (json['pricePerUnit'] ?? 0).toDouble(),
      packageType: json['packageType'] ?? 'DATA_ENRICHMENT',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
      'value': value,
      'pricePerUnit': pricePerUnit,
      'packageType': packageType,
    };
  }

  // Tính tổng chi phí
  int get totalCost => (value * pricePerUnit).round();
  
  // Format giá tiền với dấu phẩy
  String get formattedPrice {
    return totalCost.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), 
      (Match m) => '${m[1]},'
    );
  }
} 