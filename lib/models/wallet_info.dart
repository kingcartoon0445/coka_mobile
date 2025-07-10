class WalletInfo {
  int credit;

  WalletInfo({required this.credit});

  factory WalletInfo.fromJson(Map<String, dynamic> json) {
    return WalletInfo(
      credit: json['credit'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'credit': credit,
    };
  }

  // Format số tiền với dấu phẩy
  String get formattedCredit {
    return credit.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), 
      (Match m) => '${m[1]},'
    );
  }
} 