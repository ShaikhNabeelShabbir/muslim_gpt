import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppSettings {
  final String language;
  final bool modelDownloaded;
  final bool useOfflineMode;

  const AppSettings({
    this.language = 'en',
    this.modelDownloaded = false,
    this.useOfflineMode = false,
  });

  AppSettings copyWith({
    String? language,
    bool? modelDownloaded,
    bool? useOfflineMode,
  }) {
    return AppSettings(
      language: language ?? this.language,
      modelDownloaded: modelDownloaded ?? this.modelDownloaded,
      useOfflineMode: useOfflineMode ?? this.useOfflineMode,
    );
  }
}

final settingsProvider =
    NotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);

class SettingsNotifier extends Notifier<AppSettings> {
  @override
  AppSettings build() => const AppSettings();

  void setLanguage(String language) {
    state = state.copyWith(language: language);
  }

  void setModelDownloaded(bool downloaded) {
    state = state.copyWith(modelDownloaded: downloaded);
  }

  void setUseOfflineMode(bool offline) {
    state = state.copyWith(useOfflineMode: offline);
  }
}
