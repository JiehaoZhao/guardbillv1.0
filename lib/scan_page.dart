<<<<<<< HEAD
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'bill_scan_service.dart';
import 'features/extraction/services/financial_extraction_service.dart';
=======
// 文件路径: lib/scan_page.dart
import 'package:flutter/material.dart';
import 'bill_scan_service.dart';
>>>>>>> 5302f72aab18e693d15823281578d9ab854adc4a

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  final BillScanService _scanService = BillScanService();
<<<<<<< HEAD
  final FinancialExtractionService _aiService = FinancialExtractionService();
  
  bool _isProcessing = false;
  String _statusMessage = '正在准备边缘相机...';
=======
  bool _isProcessing = false;
>>>>>>> 5302f72aab18e693d15823281578d9ab854adc4a

  @override
  void initState() {
    super.initState();
<<<<<<< HEAD
=======
    // 界面渲染完成后，立即自动唤起边缘相机，保障极简畅快的产品体验
>>>>>>> 5302f72aab18e693d15823281578d9ab854adc4a
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startCaptureFlow();
    });
  }

  Future<void> _startCaptureFlow() async {
<<<<<<< HEAD
    if (!mounted) return;
    setState(() {
      _isProcessing = true;
      _statusMessage = '唤起边缘扫描与物理空间重组...';
    });

    // 1. 触发打捞流 (拿到拓扑排序重组后的纯净文本)
    final ocrResults = await _scanService.convertImageToOcrText();
    if (ocrResults.isEmpty) {
      if (mounted) Navigator.pop(context, false);
      return;
    }

    setState(() {
      _statusMessage = '端侧 Qwen AI 正在高精度读取账单...';
    });

    bool anySuccess = false;

    // 2. 送入 AI / 正则双保险引擎，并【强制安全落盘缓存】
    for (var result in ocrResults) {
      final billData = await _aiService.extractBillDataWithAI(result.rawText);
      if (billData != null) {
        final prefs = await SharedPreferences.getInstance();
        final savedBills = prefs.getStringList('saved_bills') ?? [];
        savedBills.add(jsonEncode(billData.toJson())); // 核心修复：成功后强制写入
        await prefs.setStringList('saved_bills', savedBills);
        anySuccess = true;
      }
    }

    if (mounted) {
      Navigator.pop(context, anySuccess);
=======
    setState(() => _isProcessing = true);

    // 1. 直接触发你在 bill_scan_service.dart 里写好的高精度离线打捞流
    // 它在内部认字成功后，会自己组织成 BillData 并存入 SharedPreferences
    final ocrResults = await _scanService.convertImageToOcrText();

    setState(() => _isProcessing = false);

    // 2. 核心联动回传逻辑
    if (ocrResults.isNotEmpty) {
      if (mounted) {
        // 关键点：扫描并且底层成功数据固化，安全推出并携带成功状态 `true` 告知列表页
        Navigator.pop(context, true); 
      }
    } else {
      if (mounted) {
        // 用户中途取消拍照或者未识别到有效文本，直接返回 `false`，不通知列表刷新
        Navigator.pop(context, false);
      }
>>>>>>> 5302f72aab18e693d15823281578d9ab854adc4a
    }
  }

  @override
  void dispose() {
<<<<<<< HEAD
    _scanService.dispose();
=======
    _scanService.dispose(); // 安全关闭 MLKit 句柄，死守内存红线
>>>>>>> 5302f72aab18e693d15823281578d9ab854adc4a
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F5),
      appBar: AppBar(
        title: const Text('扫描新单据', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF004D40),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context, false),
        ),
      ),
      body: Center(
<<<<<<< HEAD
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Color(0xFF004D40)),
            const SizedBox(height: 16),
            Text(_statusMessage, style: const TextStyle(color: Color(0xFF004D40), fontWeight: FontWeight.w600)),
          ],
        ),
=======
        child: _isProcessing
            ? const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF004D40)),
                  SizedBox(height: 16),
                  Text('离线 NPU 正在高精度检索文本...', style: TextStyle(color: Color(0xFF004D40), fontWeight: FontWeight.w600)),
                ],
              )
            : ElevatedButton.icon(
                onPressed: _startCaptureFlow,
                icon: const Icon(Icons.document_scanner_rounded),
                label: const Text('重新唤起相机'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF004D40),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
>>>>>>> 5302f72aab18e693d15823281578d9ab854adc4a
      ),
    );
  }
}