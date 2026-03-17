import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/model_extractor_service.dart';

/// Tracks extraction progress (0.0 to 1.0). -1.0 means not started.
final extractionProgressProvider =
    NotifierProvider<ExtractionProgressNotifier, double>(
        ExtractionProgressNotifier.new);

class ExtractionProgressNotifier extends Notifier<double> {
  @override
  double build() => -1.0;

  void update(double value) {
    state = value;
  }
}

/// Resolves to the model file path once extraction is complete.
final modelReadyProvider =
    AsyncNotifierProvider<ModelReadyNotifier, String>(ModelReadyNotifier.new);

class ModelReadyNotifier extends AsyncNotifier<String> {
  @override
  Future<String> build() async {
    final progress = ref.read(extractionProgressProvider.notifier);

    await ModelExtractorService.extractIfNeeded(
      onProgress: (p) => progress.update(p),
    );

    return ModelExtractorService.modelPath;
  }
}
