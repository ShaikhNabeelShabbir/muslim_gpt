import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppSettings {
  final String apiKey;
  final String language;

  const AppSettings({
    this.apiKey = '',
    this.language = 'en',
  });

  AppSettings copyWith({String? apiKey, String? language}) {
    return AppSettings(
      apiKey: apiKey ?? this.apiKey,
      language: language ?? this.language,
    );
  }
}

final settingsProvider =
    NotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);

class SettingsNotifier extends Notifier<AppSettings> {
  @override
  AppSettings build() => const AppSettings();

  void setApiKey(String key) {
    state = state.copyWith(apiKey: key);
  }

  void setLanguage(String language) {
    state = state.copyWith(language: language);
  }
}
