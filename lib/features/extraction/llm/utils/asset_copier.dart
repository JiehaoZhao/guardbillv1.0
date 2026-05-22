import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

class AssetCopier {
  // 🚨 已更新为你的专属云端直连地址
  static const String _modelCloudUrl = "https://pub-0ac71eb1d3c54212a9eacd9984157066.r2.dev/Qwen3.5-0.8B-Q3_K_M.gguf";

  // 🚨 关键校准：模型体积约 400MB，拦截线定为 350MB 杜绝破损入库
  static const int _minValidSizeBytes = 350 * 1024 * 1024;

  static Future<String> getModelPath({Function(double)? onProgress}) async {
    final Directory docDir = await getApplicationDocumentsDirectory();
    final String localModelPath = "${docDir.path}/qwen_q4_core.gguf"; 
    final File file = File(localModelPath);

    if (await file.exists()) {
      final int fileSize = await file.length();
      if (fileSize >= _minValidSizeBytes) {
        print("====== [GuardBill AI] 检测到本地模型，大小: ${(fileSize / 1024 / 1024).toStringAsFixed(1)}MB ======");
        return localModelPath;
      }
      print("====== [GuardBill AI] 模型残缺 (仅 ${(fileSize / 1024 / 1024).toStringAsFixed(1)}MB)，正在物理重灌... ======");
      await file.delete();
    }

    print("====== [GuardBill AI] 正在从云端高性能灌注模型... ======");
    try {
      final Dio dio = Dio();
      await dio.download(
        _modelCloudUrl,
        localModelPath,
        onReceiveProgress: (received, total) {
          if (total != -1 && onProgress != null) {
            onProgress(received / total);
          }
        },
      );

      final int downloadedSize = await file.length();
      if (downloadedSize < _minValidSizeBytes) {
        await file.delete();
        throw Exception("模型灌注失败: 下载体积不足 (${(downloadedSize / 1024 / 1024).toStringAsFixed(1)}MB < 350MB).");
      }

      print("====== [GuardBill AI] 模型灌注完成，最终大小: ${(downloadedSize / 1024 / 1024).toStringAsFixed(1)}MB ======");
      return localModelPath;
    } catch (e) {
      if (await file.exists()) {
        await file.delete();
      }
      print("❌ [GuardBill AI] 下载异常: $e");
      throw Exception("Financial engine init failed.");
    }
  }
}