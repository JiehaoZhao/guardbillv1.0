import 'dart:io';

import 'package:dio/dio.dart';

import 'package:path_provider/path_provider.dart';

class AssetCopier {

  static const String _modelCloudUrl = "https://pub-e47d59e8bf0c49d28b4b74736ed21ab6.r2.dev/qwen2.5-0.5b-instruct-q4_0.gguf";

  static const int _minValidSizeBytes = 250 * 1024 * 1024;

  static Future<String> getModelPath({Function(double)? onProgress}) async {
    final Directory docDir = await getApplicationDocumentsDirectory();
    final String localModelPath = "${docDir.path}/qwen_q4_core.gguf";
    final File file = File(localModelPath);

    if (await file.exists()) {
      final int fileSize = await file.length();
      if (fileSize >= _minValidSizeBytes) {
        print("====== [GuardBill AI] 本地模型完整，大小: ${(fileSize / 1024 / 1024).toStringAsFixed(1)}MB，秒级返回 ======");
        return localModelPath;
      }
      print("====== [GuardBill AI] 检测到残渣文件，大小仅 ${(fileSize / 1024 / 1024).toStringAsFixed(1)}MB < 250MB，物理删除并重新下载 ======");
      await file.delete();
    }

    print("====== [GuardBill AI] 触发动态机制：正在从云端灌注 Q4 模型... ======");
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
        throw Exception("Downloaded model file is incomplete (${(downloadedSize / 1024 / 1024).toStringAsFixed(1)}MB < 250MB).");
      }

      print("====== [GuardBill AI] 模型灌注完成，最终大小: ${(downloadedSize / 1024 / 1024).toStringAsFixed(1)}MB ======");
      return localModelPath;
    } catch (e) {
      if (await file.exists()) {
        await file.delete();
      }
      print("❌ [GuardBill AI] 模型下载失败: $e");
      throw Exception("Advanced financial protection modules pending download.");
    }
  }
}