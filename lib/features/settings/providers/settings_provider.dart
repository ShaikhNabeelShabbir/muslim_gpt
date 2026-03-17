import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppSettings {
  final String language;

  const AppSettings({this.language = 'en'});

  AppSettings copyWith({String? language}) {
    return AppSettings(language: language ?? this.language);
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
}
