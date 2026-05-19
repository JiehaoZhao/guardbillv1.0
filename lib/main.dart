import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'bill_scan_service.dart';
import 'models/bill_data.dart'; // 唯一真相源
import 'features/extraction/services/financial_extraction_service.dart';
import 'features/extraction/llm/utils/asset_copier.dart'; // 保留 Qwen 下载器

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const GuardBillApp());
}

class GuardBillApp extends StatelessWidget {
  const GuardBillApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GuardBill',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF00695C)),
        useMaterial3: true,
      ),
      home: const GuardBillDashboardPage(),
    );
  }
}

class GuardBillDashboardPage extends StatefulWidget {
  const GuardBillDashboardPage({super.key});

  @override
  State<GuardBillDashboardPage> createState() => _GuardBillDashboardPageState();
}

class _GuardBillDashboardPageState extends State<GuardBillDashboardPage> {
  final BillScanService _scanService = BillScanService();
  final FinancialExtractionService _extractionService = FinancialExtractionService(); // 留作 Qwen 备用

  // 核心！完全依赖你的 BillData
  List<BillData> _savedBills = [];
  
  bool _isScanning = false;
  double _modelDownloadProgress = -1;
  String _modelStatus = '';

  @override
  void initState() {
    super.initState();
    _loadSavedBills(); // 启动时读取本地账单
    _ensureModelReady(); // 启动时准备 Qwen 模型
  }

  // 📥 从 SharedPreferences 加载你的真实数据
  Future<void> _loadSavedBills() async {
    final prefs = await SharedPreferences.getInstance();
    final savedBillsString = prefs.getStringList('saved_bills') ?? [];
    
    setState(() {
      _savedBills = savedBillsString
          .map((jsonStr) => BillData.fromJson(jsonDecode(jsonStr)))
          .toList();
    });
  }

  // 🤖 Qwen 模型下载逻辑 (完美保留)
  Future<void> _ensureModelReady() async {
    try {
      await AssetCopier.getModelPath(onProgress: (progress) {
        setState(() {
          _modelDownloadProgress = progress;
          _modelStatus = 'Downloading AI Core: ${(progress * 100).toStringAsFixed(0)}%';
        });
      });
      setState(() {
        _modelDownloadProgress = 1.0;
        _modelStatus = 'Qwen AI Core Ready';
      });
    } catch (e) {
      setState(() {
        _modelDownloadProgress = -2;
        _modelStatus = 'AI Core download failed.';
      });
    }
  }

  /// 📸 扫描流转核心流程 (不再打印假数据)
  Future<void> _scanAndExtract() async {
    setState(() => _isScanning = true);

    // 1. 调用你写好的 OCR 和正则提取，数据会在服务内保存进 SharedPreferences
    await _scanService.convertImageToOcrText();

    // 2. 重新从本地存储加载最新数据刷新 UI
    await _loadSavedBills();

    setState(() => _isScanning = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚡ 账单扫描与保存成功！'), backgroundColor: Color(0xFF004D40)),
      );
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
        title: const Text('🛡️ GuardBill', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF004D40),
        centerTitle: true,
      ),
      body: _isScanning
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF004D40)),
                  SizedBox(height: 16),
                  Text('正在扫描并提取账单...', style: TextStyle(color: Color(0xFF004D40), fontWeight: FontWeight.w600)),
                ],
              ),
            )
          : _modelDownloadProgress >= 0 && _modelDownloadProgress < 1.0
              ? Center(
                  // Qwen 下载进度条 UI 完美保留
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Preparing AI Core', style: TextStyle(color: Color(0xFF004D40), fontWeight: FontWeight.w700, fontSize: 15)),
                      const SizedBox(height: 16),
                      Text(_modelStatus, style: const TextStyle(color: Color(0xFF004D40), fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 48),
                        child: LinearProgressIndicator(value: _modelDownloadProgress, color: const Color(0xFF00695C)),
                      ),
                    ],
                  ),
                )
              : _savedBills.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.receipt_long, size: 80, color: Colors.teal[100]),
                          const SizedBox(height: 16),
                          const Text('暂无账单数据', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black54)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _savedBills.length,
                      // 倒序展示：最新的账单在最上面
                      itemBuilder: (context, index) {
                        final bill = _savedBills[_savedBills.length - 1 - index];
                        return Card(
                          elevation: 2,
                          color: Colors.white,
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.teal[50],
                              child: Icon(Icons.description, color: Colors.teal[800]),
                            ),
                            title: Text(bill.issuer, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('Due: ${bill.dueDate} | Risk: ${bill.riskLevel}'),
                            trailing: Text(
                              '\$${bill.amountDue}',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
                            ),
                          ),
                        );
                      },
                    ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _scanAndExtract,
        icon: const Icon(Icons.document_scanner),
        label: const Text('扫描纸质账单', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF004D40),
        foregroundColor: Colors.white,
      ),
    );
  }
}