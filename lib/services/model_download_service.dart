import 'dart:io';

import 'package:path_provider/path_provider.dart';

class ModelDownloadService {
  static const String _modelUrl =
      'https://huggingface.co/Qwen/Qwen2.5-1.5B-Instruct-GGUF/resolve/main/qwen2.5-1.5b-instruct-q2_k.gguf';
  static const String _modelFileName = 'qwen2.5-1.5b-instruct-q2_k.gguf';
  static const String _modelsDir = 'models';

  static Future<String> get _modelDirPath async {
    final appDir = await getApplicationDocumentsDirectory();
    return '${appDir.path}/$_modelsDir';
  }

  static Future<String> get modelPath async {
    return '${await _modelDirPath}/$_modelFileName';
  }

  static Future<bool> isModelDownloaded() async {
    final path = await modelPath;
    return File(path).existsSync();
  }

  /// Downloads the GGUF model file. Calls [onProgress] with 0.0-1.0 progress.
  static Future<void> download({
    required void Function(double progress) onProgress,
  }) async {
    final dirPath = await _modelDirPath;
    final dir = Directory(dirPath);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }

    final filePath = await modelPath;
    final tempPath = '$filePath.tmp';

    final client = HttpClient();
    try {
      final request = await client.getUrl(Uri.parse(_modelUrl));
      final response = await request.close();

      if (response.statusCode != 200) {
        throw Exception('Download failed: HTTP ${response.statusCode}');
      }

      final totalBytes = response.contentLength;
      var receivedBytes = 0;

      final file = File(tempPath);
      final sink = file.openWrite();

      await for (final chunk in response) {
        sink.add(chunk);
        receivedBytes += chunk.length;
        if (totalBytes > 0) {
          onProgress(receivedBytes / totalBytes);
        }
      }

      await sink.flush();
      await sink.close();

      // Rename temp to final path (atomic-ish)
      await File(tempPath).rename(filePath);
      onProgress(1.0);
    } finally {
      client.close();
      // Clean up temp file if it exists
      final temp = File(tempPath);
      if (temp.existsSync()) {
        temp.deleteSync();
      }
    }
  }

  static Future<void> deleteModel() async {
    final path = await modelPath;
    final file = File(path);
    if (file.existsSync()) {
      await file.delete();
    }
  }
}
