import '../models/financial_obligation_candidate.dart';

class FinancialExtractionService {
  /// 极简安全降级版：不执行任何复杂提取，直接返回一个安全默认值
  Future<List<FinancialObligationCandidate>> extractFinancialObligations(String rawText) async {
    // 如果扫描没扫到字，返回空
    if (rawText.trim().isEmpty) return [];

    // 直接构造一个保底的占位结果返回，确保 UI 不崩溃
    return [
      FinancialObligationCandidate(
        sourceText: rawText,
        providerName: "Unknown Scanned Document",
        category: "Uncategorized",
        amount: 0.0,
        currency: "\$",
        dueDate: DateTime.now().add(const Duration(days: 30)), // 默认 30 天后
        recurring: false,
        recurrenceType: 'none',
        confidence: 0.1,
        matchedSignals: ["System running in Safe Mode (Extraction Disabled)"],
      ),
    ];
  }
}