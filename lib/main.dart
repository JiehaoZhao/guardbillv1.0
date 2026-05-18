import 'dart:io';
import 'package:flutter/material.dart';
import 'bill_scan_service.dart';
import 'features/extraction/models/financial_obligation_candidate.dart';
import 'features/extraction/services/financial_extraction_service.dart';
import 'features/extraction/llm/utils/asset_copier.dart';
import 'models/bill_data.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
final FlutterLocalNotificationsPlugin
    flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化本地通知
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings =
      InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  // 这里测试创建一条账单
  final bill = BillData(
    billType: 'Credit Card',
    issuer: 'American Express',
    amountDue: 1200,
    minimumDue: 50,
    currency: 'USD',
    dueDate: '2026-05-20',
    riskLevel: 'HIGH',
    isRecurring: true,
    createdAt: DateTime.now().toIso8601String(),
  );
  

  print(bill.toJson());
  
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
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00695C),
          brightness: Brightness.light,
        ),
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
  final FinancialExtractionService _extractionService = FinancialExtractionService();

  final List<FinancialObligationCandidate> _protectedObligations = [];
  bool _isEngineProcessing = false;
  double _modelDownloadProgress = -1;
  String _modelStatus = '';

  @override
  void initState() {
    super.initState();
    _ensureModelReady();
  }

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
        _modelStatus = 'AI Core Ready';
      });
    } catch (e) {
      setState(() {
        _modelDownloadProgress = -2;
        _modelStatus = 'AI Core download pending. Retry on next scan.';
      });
    }
  }

  /// 🚀 扫描触发后直接以文本形式输出结果，跳过任何文本预览界面
  Future<void> _activateFinancialProtection() async {
    setState(() {
      _isEngineProcessing = true;
    });

    final List<BillOcrResult> ocrResults = await _scanService.convertImageToOcrText();

    if (ocrResults.isEmpty) {
      setState(() {
        _isEngineProcessing = false;
      });
      return;
    }

    for (var ocrItem in ocrResults) {
      await Future.delayed(const Duration(milliseconds: 200));
      
      // 执行混合提取流水线(Regex -> Context Slicer -> Qwen)
      final List<FinancialObligationCandidate> candidates =
          await _extractionService.extractFinancialObligations(ocrItem.rawText);

      if (candidates.isNotEmpty) {
        final candidate = candidates.first;
        
        // 直接转换为审计文本并输出，不再弹出任何 BottomSheet 预览界面
        final String formattedPlainText = _convertToAuditablePlainText(candidate);
        
        print("==================================================================");
        print("✅ [GuardBill 审计文本输出成功]");
        print(formattedPlainText);
        print("==================================================================");

        setState(() {
          _protectedObligations.insert(0, candidate);
        });
      }
    }

    setState(() {
      _isEngineProcessing = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚡ Extraction complete. Text results appended to local pipeline.'),
          backgroundColor: Color(0xFF004D40),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// 📝 专为离线系统定制的「可审计结构化纯文本」格式生成器
  String _convertToAuditablePlainText(FinancialObligationCandidate candidate) {
    final StringBuffer buffer = StringBuffer();
    
    buffer.writeln("[OBLIGATION LOCKED]");
    buffer.writeln("-> Provider Name : ${candidate.providerName}");
    buffer.writeln("-> Category      : ${candidate.category}");
    buffer.writeln("-> Amount Locked : ${candidate.formattedAmount}");
    buffer.writeln("-> Due Date      : ${candidate.formattedDueDate}");
    buffer.writeln("-> Recurring Type: ${candidate.recurring ? candidate.recurrenceType : 'None (One-time Bill)'}");
    buffer.writeln("-> Confidence    : ${candidate.confidencePercent}");
    buffer.writeln("\n[EXPLAINABILITY AUDIT TRAIL]");
    
    for (String signal in candidate.matchedSignals) {
      buffer.writeln(" • $signal");
    }
    
    return buffer.toString();
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
        title: const Text(
          '🛡️ GuardBill',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.0),
        ),
        backgroundColor: const Color(0xFF004D40),
        centerTitle: true,
        elevation: 2,
      ),
      body: _isEngineProcessing
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF004D40)),
                  SizedBox(height: 16),
                  Text(
                    'Parsing local obligation matrix...',
                    style: TextStyle(color: Color(0xFF004D40), fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                  SizedBox(height: 4),
                  Text('Local AI core is executing pipeline', style: TextStyle(color: Colors.grey, fontSize: 13)),
                ],
              ),
            )
          : _modelDownloadProgress >= 0 && _modelDownloadProgress < 1.0
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Preparing AI Core', style: TextStyle(color: Color(0xFF004D40), fontWeight: FontWeight.w700, fontSize: 15)),
                      const SizedBox(height: 16),
                      Text(_modelStatus, style: const TextStyle(color: Color(0xFF004D40), fontWeight: FontWeight.w600, fontSize: 14)),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 48),
                        child: LinearProgressIndicator(
                          value: _modelDownloadProgress,
                          backgroundColor: Colors.grey[200],
                          color: const Color(0xFF00695C),
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                )
              : _protectedObligations.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.gpp_maybe_rounded, size: 80, color: Colors.teal[100]),
                          const SizedBox(height: 16),
                          const Text('No financial obligations detected yet.', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black54)),
                          const SizedBox(height: 4),
                          const Text('Scan a document to begin monitoring.', style: TextStyle(color: Colors.grey, fontSize: 13)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _protectedObligations.length,
                      itemBuilder: (context, index) {
                        final item = _protectedObligations[index];
                        return Card(
                          color: Colors.white,
                          elevation: 2,
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: CircleAvatar(
                              backgroundColor: item.recurring ? Colors.orange[50] : Colors.teal[50],
                              child: Icon(
                                item.recurring ? Icons.autorenew_rounded : Icons.description_rounded,
                                color: item.recurring ? Colors.orange[800] : Colors.teal[800],
                              ),
                            ),
                            title: Text(item.providerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            subtitle: Text('Due: ${item.formattedDueDate}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            trailing: Text(
                              item.formattedAmount,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFD32F2F)),
                            ),
                          ),
                        );
                      },
                    ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _activateFinancialProtection,
        icon: const Icon(Icons.document_scanner_rounded),
        label: const Text('Scan Document', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        backgroundColor: const Color(0xFF004D40),
        foregroundColor: Colors.white,
        elevation: 4,
      ),
    );
  }
}