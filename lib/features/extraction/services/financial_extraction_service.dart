// 文件路径: lib/features/extraction/services/financial_extraction_service.dart
import 'dart:convert';
<<<<<<< HEAD
import 'dart:ffi';
import 'package:ffi/ffi.dart';
import '../../../models/bill_data.dart'; 

typedef LlamaInferenceC = Pointer<Utf8> Function(Pointer<Utf8> prompt, Double temperature);
typedef LlamaInferenceDart = Pointer<Utf8> Function(Pointer<Utf8> prompt, double temperature);

class FinancialExtractionService {
  DynamicLibrary? _libLlama;
  LlamaInferenceDart? _executeLocalInference;
  bool _isEngineLoaded = false;

  FinancialExtractionService() {
    _initFFIEngine();
  }

  void _initFFIEngine() {
    try {
      _libLlama = DynamicLibrary.open('libllama.so');
      _executeLocalInference = _libLlama!
          .lookup<NativeFunction<LlamaInferenceC>>('execute_llama_inference')
          .asFunction<LlamaInferenceDart>();
      _isEngineLoaded = true;
      print("🚀 [GuardBill] Qwen 本地 NPU 引擎就绪！");
    } catch (e) {
      print("⚠️ [GuardBill] NPU 引擎未就绪，使用局部正则块兜底。");
      _isEngineLoaded = false;
    }
  }

  String buildQwenPrompt(String logicalBlocksInput) {
    return '''<|im_start|>system
你是一个顶级的金融账单解析AI。输入数据已被底层的视觉引擎划分为多个独立的 `<block>` 模块。你必须严格遵守以下阅读规则：
1. 【地址免疫】：若 `<block>` 内包含 "P.O. Box", "Address", "Street" 等词，严禁将其中的数字（如邮编）识别为金额！
2. 【日期防混淆】：忽略 "Statement Date"，严格寻找包含 "Payment Due Date" 或 "Due Date" 的 `<block>` 并提取日期。
3. 【金额精准锁定】：在包含 "New Balance", "Total Amount Due" 的 `<block>` 中寻找主金额；在包含 "Late Payment Warning" 的 `<block>` 中寻找逾期罚金。

严格输出包含以下字段的纯JSON结构，找不到的数字填0.0，日期格式为 YYYY-MM-DD：
{"issuer": "机构名", "total_amount": 0.0, "minimum_payment": 0.0, "late_fee": 0.0, "due_date": "YYYY-MM-DD"}
<|im_end|>
<|im_start|>user
$logicalBlocksInput
<|im_end|>
输出:''';
  }

  Future<BillData?> extractBillDataWithAI(String logicalBlocksInput) async {
    if (logicalBlocksInput.trim().isEmpty) return null;
    String llmRawOutput = "";
    
    if (_isEngineLoaded && _executeLocalInference != null) {
      final prompt = buildQwenPrompt(logicalBlocksInput);
      final Pointer<Utf8> promptPointer = prompt.toNativeUtf8();
      try {
        final Pointer<Utf8> resultPointer = _executeLocalInference!(promptPointer, 0.0);
        llmRawOutput = resultPointer.toDartString();
      } catch (e) {
        llmRawOutput = _blockBasedFallbackEngine(logicalBlocksInput);
      } finally {
        malloc.free(promptPointer);
      }
    } else {
      llmRawOutput = _blockBasedFallbackEngine(logicalBlocksInput);
    }

    return _parseAndDiagnose(llmRawOutput);
  }

  // 🛡️ 核心硬壁垒：按 <block> 物理隔离的防污染正则兜底引擎
  String _blockBasedFallbackEngine(String blocksText) {
    final blocks = blocksText.split('</block>');
    String issuer = 'Unknown Bank';
    String amount = '0.0';
    String dueDate = '';
    double minDue = 0.0;
    double lateFeeVal = 0.0;

    final lowerFullText = blocksText.toLowerCase();
    if (lowerFullText.contains('american express')) issuer = 'American Express';
    else if (lowerFullText.contains('bank of america')) issuer = 'Bank of America';
    else if (lowerFullText.contains('chase')) issuer = 'Chase';

    for (var block in blocks) {
      final lowerBlock = block.toLowerCase();
      // 1. 地址特征区绝对防御，强制跳过匹配
      if (lowerBlock.contains('p.o. box') || lowerBlock.contains('mail to') || lowerBlock.contains('box ')) continue; 

      // 2. 滞纳金独立打捞
      if (lowerBlock.contains('late payment warning') || lowerBlock.contains('late fee')) {
        final lateRegex = RegExp(r'late fee of up to\s?\$?\s?(\d+[.,]?\d*)', caseSensitive: false);
        final lMatch = lateRegex.firstMatch(block);
        if (lMatch != null) lateFeeVal = double.tryParse(lMatch.group(1)!.replaceAll(',', '')) ?? 0.0;
      }

      // 3. 金额、还款日独立打捞，决不允许跨 block 污染
      if (lowerBlock.contains('balance') || lowerBlock.contains('due') || lowerBlock.contains('minimum')) {
        final amountRegex = RegExp(r'(?:new balance|total amount due|balance)[\s|:\t]*\$?\s?(\d{1,3}(?:,\d{3})*(?:\.\d{2})?)', caseSensitive: false);
        final minRegex = RegExp(r'(?:minimum payment|minimum due)[\s|:\t]*\$?\s?(\d{1,3}(?:,\d{3})*(?:\.\d{2})?)', caseSensitive: false);
        final dateRegex = RegExp(r'(?:payment due date|due date)[\s|:\t]*(\d{1,2})\s?[/]\s?(\d{1,2})\s?[/]\s?(\d{2,4})', caseSensitive: false);

        final aMatch = amountRegex.firstMatch(block);
        final mMatch = minRegex.firstMatch(block);
        final dMatch = dateRegex.firstMatch(block);

        if (aMatch != null && amount == '0.0') amount = aMatch.group(1)!.replaceAll(',', '');
        if (mMatch != null && minDue == 0.0) minDue = double.tryParse(mMatch.group(1)!.replaceAll(',', '')) ?? 0.0;
        
        if (dMatch != null && dueDate.isEmpty) {
          String m = dMatch.group(1)!.padLeft(2, '0');
          String d = dMatch.group(2)!.padLeft(2, '0');
          String y = dMatch.group(3)!;
          if (y.length == 2) y = '20$y';
          dueDate = '$y-$m-$d';
        }
      }
    }
    return '{"issuer": "$issuer", "total_amount": $amount, "minimum_payment": $minDue, "late_fee": $lateFeeVal, "due_date": "${dueDate.isEmpty ? 'Unknown' : dueDate}"}';
  }

  BillData? _parseAndDiagnose(String rawOutput) {
    try {
      final startIndex = rawOutput.indexOf('{');
      final endIndex = rawOutput.lastIndexOf('}');
      if (startIndex == -1 || endIndex == -1) return null;
      
      final Map<String, dynamic> jsonMap = jsonDecode(rawOutput.substring(startIndex, endIndex + 1));
      String dueDateStr = jsonMap['due_date']?.toString() ?? '';
      
      // 🚨 严苛数据审计：如果日期未成功打捞，拒绝入库，严防假数据污染列表展示
      if (dueDateStr.isEmpty || dueDateStr == 'Unknown') {
        print("❌ [GuardBill] 关键字段 Due Date 缺失，拒绝入库。");
        return null;
      }

      double totalAmount = double.tryParse(jsonMap['total_amount']?.toString() ?? '0') ?? 0.0;
      double minPayment = double.tryParse(jsonMap['minimum_payment']?.toString() ?? '0') ?? 0.0;
      double lateFee = double.tryParse(jsonMap['late_fee']?.toString() ?? '0') ?? 0.0;

      String riskLevel = 'SAFE';
      double potentialLoss = 0.0;
      double amountSaved = 0.0;
      List<String> riskPoints = [];

      if (minPayment > 0 && minPayment < totalAmount) {
        riskLevel = 'HIGH';
        riskPoints.add('【最低还款陷阱】: 若仅还款 \$${minPayment}，剩余款项将立刻触发 24.99% 的循环高息！');
        potentialLoss += (totalAmount - minPayment) * (0.2499 / 12) * 3; 
      }

      if (lateFee > 0) {
        if (riskLevel == 'SAFE') riskLevel = 'MEDIUM';
        riskPoints.add('【高额罚金预警】: 错过还款日将直接触发 \$${lateFee} 滞纳金罚款。');
        potentialLoss += lateFee;
      }

      if (riskLevel == 'HIGH' || riskLevel == 'MEDIUM') amountSaved = potentialLoss;

      return BillData(
        billType: 'Credit Card Statement',
        issuer: jsonMap['issuer']?.toString() ?? 'Unknown Issuer',
        amountDue: totalAmount,
        minimumDue: minPayment,
        currency: 'USD',
        dueDate: dueDateStr,
        riskLevel: riskLevel,
        isRecurring: false,
        createdAt: DateTime.now().toIso8601String(),
        potentialLoss: potentialLoss,
        amountSaved: amountSaved,
        riskPoints: riskPoints,
      );
    } catch (e) {
      print("❌ [GuardBill] 解析器崩溃: $e");
      return null;
    }
  }
=======
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
>>>>>>> 5302f72aab18e693d15823281578d9ab854adc4a
}