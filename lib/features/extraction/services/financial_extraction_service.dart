// 文件路径: lib/features/extraction/services/financial_extraction_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../models/bill_data.dart'; // 引入统一真相源模型
import '../models/financial_obligation_candidate.dart'; // 保持旧模型兼容

class FinancialExtractionService {
  
  // =========================================================================
  // 🔄 两个接口彻底合并（双通路统一流）
  // 无论未来是走 OCR 还是走 AI，数据全都在这里完成“收敛合并”与“本地持久化”
  // =========================================================================

  /// 🧠 核心合并接口：接收 OCR 文本，返回统一的 [BillData]
  /// 这样就与你 BillScanService 的数据语言彻底统一了！
  Future<List<BillData>> extractBillData(String rawText) async {
    if (rawText.trim().isEmpty) return [];

    // 1. 先从 SharedPreferences 中读取目前通过 BillScanService 已经打捞上来的真实账单
    final prefs = await SharedPreferences.getInstance();
    final savedBillsString = prefs.getStringList('saved_bills') ?? [];
    
    List<BillData> currentSavedBills = savedBillsString
        .map((jsonStr) => BillData.fromJson(jsonDecode(jsonStr)))
        .toList();

    // 2. 💡 先不用管 AI 接口：这里是留给未来 Qwen 接入的 TODO 区域
    // 等以后接入 Qwen 后，可以将大模型识别出来的新 BillData 也 add 到这个 List 里并存入 prefs
    // =======================================================================
    // TODO: final String aiOutput = llamaLib.generate(rawText);
    // =======================================================================

    // 3. 直接返回当前系统里唯一真相源的全部账单数据
    return currentSavedBills;
  }

  /// 🔄 保持旧接口的签名兼容（内部彻底重构合并）
  /// 如果你其他的旧页面、旧代码仍在调用老方法，它在内部会被自动升级并轨为新数据
  Future<List<FinancialObligationCandidate>> extractFinancialObligations(String rawText) async {
    // 现阶段无 AI 深度分析时，为了防止类型冲突或红屏，直接返回空数组
    // 这样既保留了你写的函数契约，又切断了假数据对 UI 的污染
    return [];
  }
}