import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';

class ArabicTextBlock extends StatelessWidget {
  final String text;
  final bool isQuran;

  const ArabicTextBlock({
    super.key,
    required this.text,
    this.isQuran = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.arabicTextBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Text(
          text,
          style: isQuran
              ? AppTextStyles.arabicQuran
              : AppTextStyles.arabicGeneral,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
