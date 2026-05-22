class FinancialObligationCandidate {
  final String sourceText;
  final String providerName;
  final String category;
  final double amount;
  final String currency;
  final DateTime dueDate;
  final bool recurring;
  final String recurrenceType;
  final double confidence;
  final List<String> matchedSignals;

  FinancialObligationCandidate({
    required this.sourceText,
    required this.providerName,
    required this.category,
    required this.amount,
    required this.currency,
    required this.dueDate,
    required this.recurring,
    required this.recurrenceType,
    required this.confidence,
    required this.matchedSignals,
  });

  String get formattedAmount => '$currency ${amount.toStringAsFixed(2)}';

  String get formattedDueDate =>
      '${dueDate.year}-${dueDate.month.toString().padLeft(2, '0')}-${dueDate.day.toString().padLeft(2, '0')}';

  String get riskLabel {
    final daysUntilDue = dueDate.difference(DateTime.now()).inDays;
    if (daysUntilDue < 0) return 'OVERDUE';
    if (daysUntilDue <= 3) return 'HIGH';
    if (daysUntilDue <= 7) return 'MEDIUM';
    return 'LOW';
  }

  @override
  String toString() {
    return 'FinancialObligationCandidate(provider: $providerName, amount: $formattedAmount, due: $formattedDueDate)';
  }
}