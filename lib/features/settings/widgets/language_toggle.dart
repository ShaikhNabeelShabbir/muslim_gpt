import 'package:flutter/material.dart';
import '../../../shared/constants/app_strings.dart';
import '../../../theme/app_colors.dart';

class LanguageToggle extends StatelessWidget {
  final String currentLanguage;
  final ValueChanged<String> onChanged;

  const LanguageToggle({
    super.key,
    required this.currentLanguage,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          AppStrings.language,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(
              value: 'en',
              label: Text(AppStrings.english),
              icon: Icon(Icons.language),
            ),
            ButtonSegment(
              value: 'ar',
              label: Text(AppStrings.arabic),
            ),
          ],
          selected: {currentLanguage},
          onSelectionChanged: (selected) => onChanged(selected.first),
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return AppColors.primaryGreen;
              }
              return null;
            }),
            foregroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return AppColors.textOnPrimary;
              }
              return AppColors.textPrimary;
            }),
          ),
        ),
      ],
    );
  }
}
