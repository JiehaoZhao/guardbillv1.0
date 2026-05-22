import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'bill_scan_service.dart';
import 'models/bill_data.dart';
import 'features/extraction/llm/utils/asset_copier.dart';
import 'scan_page.dart';

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
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF004D40)),
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
  List<BillData> _savedBills = [];
  double _modelDownloadProgress = -1;
  String _modelStatus = '';

  @override
  void initState() {
    super.initState();
    _loadSavedBills();
    _ensureModelReady();
  }

  Future<void> _loadSavedBills() async {
    final prefs = await SharedPreferences.getInstance();
    final savedBillsString = prefs.getStringList('saved_bills') ?? [];
    setState(() {
      _savedBills = savedBillsString
          .map((jsonStr) => BillData.fromJson(jsonDecode(jsonStr)))
          .toList();
    });
  }

  Future<void> _ensureModelReady() async {
    try {
      await AssetCopier.getModelPath(onProgress: (progress) {
        setState(() {
          _modelDownloadProgress = progress;
          _modelStatus = 'Downloading Private AI Core: ${(progress * 100).toStringAsFixed(0)}%';
        });
      });
      setState(() {
        _modelDownloadProgress = 1.0;
        _modelStatus = 'GuardBill AI Core Ready';
      });
    } catch (e) {
      setState(() {
        _modelDownloadProgress = -2;
        _modelStatus = 'AI Core download failed.';
      });
    }
  }

  Future<void> _scanAndExtract() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ScanPage()),
    );

    if (result == true) {
      await _loadSavedBills();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('⚡ 账单解析完成，金融陷阱已拦截！'), backgroundColor: Color(0xFF004D40)),
        );
      }
    }
  }

  Color getRiskColor(String risk) {
    switch (risk) {
      case 'SAFE': return Colors.green;
      case 'HIGH': return Colors.red;
      default: return Colors.orange;
    }
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
      body: _modelDownloadProgress >= 0 && _modelDownloadProgress < 1.0
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Preparing Private AI Engine', style: TextStyle(color: Color(0xFF004D40), fontWeight: FontWeight.w700, fontSize: 15)),
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
                      const Text('暂无安全审计账单', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black54)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _savedBills.length,
                  itemBuilder: (context, index) {
                    final bill = _savedBills[_savedBills.length - 1 - index]; // 倒序展示最新
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      color: Colors.white,
                      child: ListTile(
                        leading: Container(
                          width: 6,
                          height: 45,
                          decoration: BoxDecoration(
                            color: getRiskColor(bill.riskLevel),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        title: Text(bill.issuer, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Due: ${bill.dueDate}', style: const TextStyle(color: Colors.black87)),
                              Text('Amount: ${bill.amountDue} ${bill.currency}', style: const TextStyle(fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(color: getRiskColor(bill.riskLevel), borderRadius: BorderRadius.circular(12)),
                          child: Text(bill.riskLevel, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
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