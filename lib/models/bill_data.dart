class BillData {
  final String billType;
  final String issuer;
  final double amountDue;
  final double minimumDue;
  final String currency;
  final String dueDate;
  final String riskLevel;
  final bool isRecurring;
  final String createdAt;

  BillData({
    required this.billType,
    required this.issuer,
    required this.amountDue,
    required this.minimumDue,
    required this.currency,
    required this.dueDate,
    required this.riskLevel,
    required this.isRecurring,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'billType': billType,
      'issuer': issuer,
      'amountDue': amountDue,
      'minimumDue': minimumDue,
      'currency': currency,
      'dueDate': dueDate,
      'riskLevel': riskLevel,
      'isRecurring': isRecurring,
      'createdAt': createdAt,
    };
  }

  factory BillData.fromJson(Map<String, dynamic> json) {
    return BillData(
      billType: json['billType'] ?? '',
      issuer: json['issuer'] ?? '',
      amountDue: (json['amountDue'] ?? 0).toDouble(),
      minimumDue: (json['minimumDue'] ?? 0).toDouble(),
      currency: json['currency'] ?? '',
      dueDate: json['dueDate'] ?? '',
      riskLevel: json['riskLevel'] ?? 'SAFE',
      isRecurring: json['isRecurring'] ?? false,
      createdAt: json['createdAt'] ?? '',
    );
  }
}