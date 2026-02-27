import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  // Arabic - Quranic text
  static const TextStyle arabicQuran = TextStyle(
    fontFamily: 'AmiriQuran',
    fontSize: 22,
    height: 2.0,
    color: AppColors.textPrimary,
  );

  // Arabic - General (Hadith, etc.)
  static const TextStyle arabicGeneral = TextStyle(
    fontFamily: 'NotoNaskhArabic',
    fontSize: 18,
    height: 1.8,
    color: AppColors.textPrimary,
  );

  // Chat
  static const TextStyle userMessage = TextStyle(
    fontSize: 15,
    height: 1.5,
    color: AppColors.textOnPrimary,
  );

  static const TextStyle assistantMessage = TextStyle(
    fontSize: 15,
    height: 1.5,
    color: AppColors.textPrimary,
  );

  // Citations
  static const TextStyle citationSource = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.primaryGreen,
  );

  static const TextStyle citationTranslation = TextStyle(
    fontSize: 14,
    height: 1.6,
    fontStyle: FontStyle.italic,
    color: AppColors.textPrimary,
  );

  static const TextStyle citationExplanation = TextStyle(
    fontSize: 13,
    height: 1.5,
    color: AppColors.textSecondary,
  );

  static const TextStyle citationReference = TextStyle(
    fontSize: 11,
    color: AppColors.textSecondary,
  );
}
