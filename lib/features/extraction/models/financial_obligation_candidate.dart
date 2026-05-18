import 'dart:core';
import 'package:intl/intl.dart';

class FinancialObligationCandidate {
  final String sourceText;       // 原始 OCR 全量文本流
  final String providerName;     // 识别出的商户名
  final String category;         // 风险类目分类
  final double? amount;          // 清洗后的最终应付金额
  final String? currency;        // 货币特征符号 (如 $, €, £)
  final DateTime? dueDate;       // 归一化后的标准 ISO 截止日期
  final bool recurring;          // 是否属于循环扣费/连续义务
  final String recurrenceType;   // 循环周期类型 (monthly, annual, unknown)
  final double confidence;       // 100% 可审计的确定性置信度
  final List<String> matchedSignals; // 审计追踪痕迹日志

  FinancialObligationCandidate({
    required this.sourceText,
    required this.providerName,
    required this.category,
    this.amount,
    this.currency,
    this.dueDate,
    required this.recurring,
    required this.recurrenceType,
    required this.confidence,
    required this.matchedSignals,
  });

  String get formattedDueDate {
    if (dueDate == null) return 'N/A';
    return DateFormat('yyyy-MM-dd').format(dueDate!);
  }

  String get formattedAmount {
    if (amount == null) return 'Unidentified';
    return '${currency ?? '\$'}${amount!.toStringAsFixed(2)}';
  }

  String get confidencePercent {
    return '${(confidence * 100).toInt()}%';
  }
}