import 'dart:io';
import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
<<<<<<< HEAD

=======
import 'models/bill_data.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
/// 🛡️ GuardBill 纯净版离线文本打捞结果实体
>>>>>>> 5302f72aab18e693d15823281578d9ab854adc4a
class BillOcrResult {
  final String rawText;        
  final String localImagePath; 

  BillOcrResult({
    required this.rawText,
    required this.localImagePath,
  });
}

class BillScanService {
  final TextRecognizer _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  Future<List<BillOcrResult>> convertImageToOcrText() async {
    List<BillOcrResult> ocrResults = [];
    try {
      final List<String>? imagePaths = await CunningDocumentScanner.getPictures();
      if (imagePaths == null || imagePaths.isEmpty) return [];

      print("====== [GuardBill] 成功捕获 ${imagePaths.length} 张单据，启动【文字框模块化解析】算法 ======");

      for (String path in imagePaths) {
        final File imageFile = File(path);
        if (!await imageFile.exists()) continue;

        final InputImage inputImage = InputImage.fromFile(imageFile);
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
        
<<<<<<< HEAD
        List<TextBlock> blocks = List<TextBlock>.from(recognizedText.blocks);

        // 🚨 安全非空防线：如果拍到空白纸张则直接跳过
        if (blocks.isEmpty) continue;

        // 📍 空间拓扑核心算法 1：宏观排版排序（判断高度差邻近阈值是否小于 40 像素）
        blocks.sort((TextBlock a, TextBlock b) {
          double topA = a.boundingBox.top;
          double topB = b.boundingBox.top;
          double topDiff = topA - topB;

          if (topDiff.abs() < 40.0) {
            return a.boundingBox.left.compareTo(b.boundingBox.left); 
          }
          return topA.compareTo(topB);
        });

        StringBuffer semanticLayoutBuffer = StringBuffer();
        
        for (TextBlock block in blocks) {
          List<TextLine> linesInBlock = List<TextLine>.from(block.lines);
          if (linesInBlock.isEmpty) continue;

          // 📍 空间拓扑核心算法 2：微观行距对齐（判断微观行高差是否小于 10 像素）
          linesInBlock.sort((TextLine a, TextLine b) {
            double topA = a.boundingBox.top;
            double topB = b.boundingBox.top;
            double yDiff = topA - topB;

            if (yDiff.abs() < 10.0) { 
              return a.boundingBox.left.compareTo(b.boundingBox.left);
            }
            return topA.compareTo(topB);
          });

          String blockContent = linesInBlock
              .map((l) => l.text.trim())
              .where((t) => t.isNotEmpty)
              .join(" ");

          if (blockContent.isNotEmpty) {
            // 用自定义标签包裹空间临近块，注入空间语义
            semanticLayoutBuffer.writeln("<logical_block>");
            semanticLayoutBuffer.writeln(blockContent);
            semanticLayoutBuffer.writeln("</logical_block>\n");
          }
        }

        print("====== [GuardBill 模块化分块阅读完毕] ======");
        ocrResults.add(BillOcrResult(
          rawText: semanticLayoutBuffer.toString(),
          localImagePath: path,
        ));
=======
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
>>>>>>> 5302f72aab18e693d15823281578d9ab854adc4a
      }
    } catch (e) {
      print("❌ [GuardBill] 模块分块算法发生不可逆崩溃: $e");
    }
    return ocrResults;
  }

  void dispose() {
    _textRecognizer.close();
  }
}