import 'dart:io';
import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

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