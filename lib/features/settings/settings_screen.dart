import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/constants/app_strings.dart';
import 'providers/settings_provider.dart';
import 'widgets/api_key_input.dart';
import 'widgets/language_toggle.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.settings),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ApiKeyInput(
            apiKey: settings.apiKey,
            onChanged: (key) =>
                ref.read(settingsProvider.notifier).setApiKey(key),
          ),
          const SizedBox(height: 24),
          LanguageToggle(
            currentLanguage: settings.language,
            onChanged: (lang) =>
                ref.read(settingsProvider.notifier).setLanguage(lang),
          ),
          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 16),
          Center(
            child: Text(
              '${AppStrings.appName} v1.0.0',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
