import 'dart:io';
import 'package:flutter/material.dart';
import 'bill_scan_service.dart';
import 'features/extraction/models/financial_obligation_candidate.dart';
import 'features/extraction/services/financial_extraction_service.dart';
import 'features/extraction/llm/utils/asset_copier.dart';

void main() {
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
  final FinancialExtractionService _extractionService =
      FinancialExtractionService();

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
          _modelStatus =
              'Downloading AI Core: ${(progress * 100).toStringAsFixed(0)}%';
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

  Future<void> _activateFinancialProtection() async {
    setState(() {
      _isEngineProcessing = true;
    });

    final List<BillOcrResult> ocrResults =
        await _scanService.convertImageToOcrText();

    if (ocrResults.isEmpty) {
      setState(() {
        _isEngineProcessing = false;
      });
      return;
    }

    for (var ocrItem in ocrResults) {
      await Future.delayed(const Duration(milliseconds: 200));
      final List<FinancialObligationCandidate> candidates =
          await _extractionService.extractFinancialObligations(ocrItem.rawText);

      if (candidates.isNotEmpty) {
        _presentReviewBottomSheet(candidates.first, ocrItem.localImagePath);
      }
    }

    setState(() {
      _isEngineProcessing = false;
    });
  }

  void _presentReviewBottomSheet(
      FinancialObligationCandidate candidate, String imagePath) {
    final TextEditingController providerController =
        TextEditingController(text: candidate.providerName);
    final TextEditingController amountController = TextEditingController(
      text:
          candidate.amount != null ? candidate.amount!.toStringAsFixed(2) : '',
    );
    final TextEditingController dateController = TextEditingController(
      text: candidate.dueDate != null
          ? candidate.dueDate!.toIso8601String().substring(0, 10)
          : '2026-05-17',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            top: 24,
            left: 24,
            right: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '🛡️ GuardBill Review',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF004D40),
                        ),
                      ),
                      Text(
                        'Possible financial obligation detected',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.teal[50],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'AI Confidence: ${(candidate.confidence * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        color: Colors.teal[800],
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 100,
                  width: double.infinity,
                  color: Colors.grey[100],
                  child: Image.file(File(imagePath), fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: providerController,
                decoration: InputDecoration(
                  labelText: 'Detected Provider',
                  prefixIcon: const Icon(Icons.business, color: Colors.teal),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  labelText: '',
                  prefixIcon:
                      const Icon(Icons.monetization_on, color: Colors.amber),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: dateController,
                decoration: InputDecoration(
                  labelText: 'Detected Due Date',
                  prefixIcon:
                      const Icon(Icons.calendar_today, color: Colors.blue),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'EXPLAINABILITY AUDIT TRAIL',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: candidate.matchedSignals.map((signal) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '• $signal',
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                          color: Colors.blueGrey,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _protectedObligations.insert(
                        0,
                        FinancialObligationCandidate(
                          sourceText: candidate.sourceText,
                          providerName: providerController.text,
                          category: candidate.category,
                          amount: double.tryParse(amountController.text),
                          currency: candidate.currency,
                          dueDate: DateTime.tryParse(dateController.text),
                          recurring: candidate.recurring,
                          recurrenceType: candidate.recurrenceType,
                          confidence: candidate.confidence,
                          matchedSignals: candidate.matchedSignals,
                        ),
                      );
                    });
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          '⚡ Financial protection activated. Monitoring running locally.',
                        ),
                        backgroundColor: Color(0xFF004D40),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  icon: const Icon(Icons.shield, color: Colors.white),
                  label: const Text(
                    'Activate Financial Protection',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00695C),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
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
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1.0,
          ),
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
                  Text(
                    'Parsing local obligation matrix...',
                    style: TextStyle(
                      color: Color(0xFF004D40),
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Local AI core is preparing',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            )
          : _modelDownloadProgress >= 0 && _modelDownloadProgress < 1.0
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Preparing AI Core',
                        style: TextStyle(
                          color: Color(0xFF004D40),
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _modelStatus,
                        style: const TextStyle(
                          color: Color(0xFF004D40),
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 48),
                        child: LinearProgressIndicator(
                          value: _modelDownloadProgress,
                          backgroundColor: Colors.grey[200],
                          color: const Color(0xFF00695C),
                          borderRadius: BorderRadius.circular(4),
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
                          Icon(Icons.gpp_maybe_rounded,
                              size: 80, color: Colors.teal[100]),
                          const SizedBox(height: 16),
                          const Text(
                            'No financial obligations detected yet.',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Scan a document to begin monitoring.',
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          ),
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
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: CircleAvatar(
                              backgroundColor: item.recurring
                                  ? Colors.orange[50]
                                  : Colors.teal[50],
                              child: Icon(
                                item.recurring
                                    ? Icons.autorenew_rounded
                                    : Icons.description_rounded,
                                color: item.recurring
                                    ? Colors.orange[800]
                                    : Colors.teal[800],
                              ),
                            ),
                            title: Text(
                              item.providerName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                'Due: ${item.dueDate != null ? item.dueDate!.toIso8601String().substring(0, 10) : "N/A"}',
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey),
                              ),
                            ),
                            trailing: Text(
                              '${item.currency ?? '\$'}${item.amount?.toStringAsFixed(2) ?? '0.00'}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFD32F2F),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _activateFinancialProtection,
        icon: const Icon(Icons.document_scanner_rounded),
        label: const Text(
          'Scan Document',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
        backgroundColor: const Color(0xFF004D40),
        foregroundColor: Colors.white,
        elevation: 4,
      ),
    );
  }
}
