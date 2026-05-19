// 文件路径: lib/scan_page.dart
import 'package:flutter/material.dart';
import 'bill_scan_service.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  final BillScanService _scanService = BillScanService();
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    // 界面渲染完成后，立即自动唤起边缘相机，保障极简畅快的产品体验
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startCaptureFlow();
    });
  }

  Future<void> _startCaptureFlow() async {
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
    }
  }

  @override
  void dispose() {
    _scanService.dispose(); // 安全关闭 MLKit 句柄，死守内存红线
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
      ),
    );
  }
}