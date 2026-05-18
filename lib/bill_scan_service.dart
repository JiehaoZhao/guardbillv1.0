import 'dart:io';
import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'models/bill_data.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
/// 🛡️ GuardBill 纯净版离线文本打捞结果实体
class BillOcrResult {
  final String rawText;        // 离线 OCR 提取出来的全量原始文本
  final String localImagePath; // 账单图片的本地物理缓存路径

  BillOcrResult({
    required this.rawText,
    required this.localImagePath,
  });
}

class BillScanService {
  // 初始化谷歌本地离线文本识别器（指定识别拉丁/英文语系）
  final TextRecognizer _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  /// 📸 仅唤起系统相机认字并抓取物理 RawText，不执行任何旧世界正则猜测
  Future<List<BillOcrResult>> convertImageToOcrText() async {
    List<BillOcrResult> ocrResults = [];

    try {
      // 1. 调用系统级边缘检测相机
      final List<String>? imagePaths = await CunningDocumentScanner.getPictures();
      
      if (imagePaths == null || imagePaths.isEmpty) {
        print("====== [GuardBill] 用户取消了本次拍照扫描 ======");
        return [];
      }

      print("====== [GuardBill] 成功捕获到 ${imagePaths.length} 张账单，启动离线 NPU 文本打捞... ======");

      // 2. 遍历物理路径，单据流式执行高精度认字
      for (String path in imagePaths) {
        final File imageFile = File(path);
        if (!await imageFile.exists()) continue;

        final InputImage inputImage = InputImage.fromFile(imageFile);
        
        // 3. 触发本地算力硬件加速识别
        final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
        final rawText = recognizedText.text;

        final dueDateRegex = RegExp(
          r'(\d{4}-\d{2}-\d{2})|(\d{2}/\d{2}/\d{4})',
        );

        final amountRegex = RegExp(
          r'(\$|USD)?\s?(\d+[.,]?\d*)',
        );

        final dueDateMatch = dueDateRegex.firstMatch(rawText);
        final amountMatch = amountRegex.firstMatch(rawText);

        final extractedDueDate =
            dueDateMatch?.group(0) ?? 'UNKNOWN';

        final extractedAmount =
            amountMatch?.group(0) ?? '0';
        
        String riskLevel = 'SAFE';
        final amountValue = double.tryParse(
              extractedAmount.replaceAll(RegExp(r'[^0-9.]'), ''),
            ) ??
            0;
        final issuerKeywords = {
          'american express': 'American Express',
          'amex': 'American Express',
          'chase': 'Chase',
          'citi': 'Citi',
          'citibank': 'Citi',
          'bank of america': 'Bank of America',
          'capital one': 'Capital One',
          'wells fargo': 'Wells Fargo',
          'discover': 'Discover',
          'verizon': 'Verizon',
          'at&t': 'AT&T',
          't-mobile': 'T-Mobile',
          'comcast': 'Comcast',
          'xfinity': 'Xfinity',
        };

        String issuer = 'Unknown';

        final lowerText = rawText.toLowerCase();

        for (final entry in issuerKeywords.entries) {
          if (lowerText.contains(entry.key)) {
            issuer = entry.value;
            break;
          }
        }
        if (amountValue > 1000) {
          riskLevel = 'HIGH';
        }

        if (extractedDueDate != 'UNKNOWN') {
          final dueDate = DateTime.tryParse(extractedDueDate);

          if (dueDate != null) {
            final difference = dueDate.difference(DateTime.now()).inDays;

            if (difference <= 3) {
              riskLevel = 'HIGH';
            }
          }
        }
        
        print('Due Date: $extractedDueDate');
        print('Amount: $extractedAmount');
        
        final billData = BillData(
          billType: 'Credit Card',
          issuer: issuer,
          amountDue: double.tryParse(
                extractedAmount.replaceAll(RegExp(r'[^0-9.]'), ''),
              ) ??
              0,
            minimumDue: 0,
            currency: 'USD',
            dueDate: extractedDueDate,
            riskLevel: riskLevel,
            isRecurring: false,
            createdAt: DateTime.now().toIso8601String(),
          );

          print('BillData Created:');
          print(billData.toJson());

          final prefs = await SharedPreferences.getInstance();

          final savedBills = prefs.getStringList('saved_bills') ?? [];

          savedBills.add(
            jsonEncode(billData.toJson()),
          );

          await prefs.setStringList(
            'saved_bills',
            savedBills,
          );

          print('Bill saved successfully');

        ocrResults.add(
          BillOcrResult(
            rawText: recognizedText.text,
            localImagePath: path,
          ),
        );
      }

    } catch (e) {
      print("❌ [GuardBill 离线文本打捞严重崩溃]: $e");
    }

    return ocrResults;
  }

  /// ♻️ 释放句柄，死守离线内存红线
  void dispose() {
    _textRecognizer.close();
  }
}