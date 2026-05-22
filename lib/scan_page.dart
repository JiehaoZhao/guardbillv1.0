import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'bill_scan_service.dart';
import 'features/extraction/services/financial_extraction_service.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  final BillScanService _scanService = BillScanService();
  final FinancialExtractionService _aiService = FinancialExtractionService();
  
  bool _isProcessing = false;
  String _statusMessage = '正在准备边缘相机...';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startCaptureFlow();
    });
  }

  Future<void> _startCaptureFlow() async {
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
    }
  }

  @override
  void dispose() {
    _scanService.dispose();
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Color(0xFF004D40)),
            const SizedBox(height: 16),
            Text(_statusMessage, style: const TextStyle(color: Color(0xFF004D40), fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}