import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../shared/constants/app_assets.dart';
import '../../../shared/constants/app_strings.dart';
import '../../../theme/app_colors.dart';

class ChatEmptyState extends StatelessWidget {
  final ValueChanged<String> onSuggestionTap;

  const ChatEmptyState({super.key, required this.onSuggestionTap});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          SvgPicture.asset(
            AppAssets.emptyChat,
            width: 100,
            height: 100,
          ),
          const SizedBox(height: 24),
          const Text(
            AppStrings.welcomeTitle,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryGreen,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            AppStrings.welcomeSubtitle,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: AppStrings.suggestedQuestions.map((question) {
              return ActionChip(
                label: Text(
                  question,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.primaryGreen,
                  ),
                ),
                backgroundColor: AppColors.primaryGreen.withValues(alpha: 0.08),
                side: BorderSide(
                  color: AppColors.primaryGreen.withValues(alpha: 0.2),
                ),
                onPressed: () => onSuggestionTap(question),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
