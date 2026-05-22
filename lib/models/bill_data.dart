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
<<<<<<< HEAD
  final double potentialLoss;
  final double amountSaved;
  final List<String> riskPoints;
=======
>>>>>>> 5302f72aab18e693d15823281578d9ab854adc4a

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
<<<<<<< HEAD
    required this.potentialLoss,
    required this.amountSaved,
    required this.riskPoints,
  });

  factory BillData.fromJson(Map<String, dynamic> json) {
    return BillData(
      billType: json['billType'] ?? '',
      issuer: json['issuer'] ?? 'Unknown',
      amountDue: (json['amountDue'] ?? 0).toDouble(),
      minimumDue: (json['minimumDue'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'USD',
=======
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
>>>>>>> 5302f72aab18e693d15823281578d9ab854adc4a
      dueDate: json['dueDate'] ?? '',
      riskLevel: json['riskLevel'] ?? 'SAFE',
      isRecurring: json['isRecurring'] ?? false,
      createdAt: json['createdAt'] ?? '',
<<<<<<< HEAD
      potentialLoss: (json['potentialLoss'] ?? 0).toDouble(),
      amountSaved: (json['amountSaved'] ?? 0).toDouble(),
      riskPoints: List<String>.from(json['riskPoints'] ?? []),
    );
  }

  Map<String, dynamic> toJson() => {
    'billType': billType, 'issuer': issuer, 'amountDue': amountDue,
    'minimumDue': minimumDue, 'currency': currency, 'dueDate': dueDate,
    'riskLevel': riskLevel, 'isRecurring': isRecurring, 'createdAt': createdAt,
    'potentialLoss': potentialLoss, 'amountSaved': amountSaved, 'riskPoints': riskPoints,
  };
=======
    );
  }
>>>>>>> 5302f72aab18e693d15823281578d9ab854adc4a
}