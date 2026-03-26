import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class ModelExtractorService {
  static const String _assetPath =
      'assets/models/qwen2.5-1.5b-instruct-q4_k_m-00001-of-00001.gguf';
  static const String _modelFileName =
      'qwen2.5-1.5b-instruct-q4_k_m-00001-of-00001.gguf';
  static const String _modelsDir = 'models';

  static Future<String> get _modelDirPath async {
    final appDir = await getApplicationDocumentsDirectory();
    return '${appDir.path}/$_modelsDir';
  }

  static Future<String> get modelPath async {
    return '${await _modelDirPath}/$_modelFileName';
  }

  /// Returns true if the model has already been extracted to the filesystem.
  static Future<bool> isModelReady() async {
    final path = await modelPath;
    return File(path).existsSync();
  }

  /// Extracts the bundled model asset to the filesystem.
  /// Calls [onProgress] with 0.0-1.0 progress.
  /// No-ops if model already exists on disk.
  static Future<void> extractIfNeeded({
    void Function(double progress)? onProgress,
  }) async {
    if (await isModelReady()) {
      onProgress?.call(1.0);
      return;
    }

    final dirPath = await _modelDirPath;
    final dir = Directory(dirPath);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }

    final filePath = await modelPath;
    final tempPath = '$filePath.tmp';

    onProgress?.call(0.0);

    // Load asset into memory (one-time spike, ~600MB)
    final data = await rootBundle.load(_assetPath);
    onProgress?.call(0.3);

    // Write to temp file
    final bytes = data.buffer.asUint8List(
      data.offsetInBytes,
      data.lengthInBytes,
    );
    final tempFile = File(tempPath);
    await tempFile.writeAsBytes(bytes, flush: true);
    onProgress?.call(0.9);

    // Atomic rename
    await tempFile.rename(filePath);
    onProgress?.call(1.0);
  }
}
