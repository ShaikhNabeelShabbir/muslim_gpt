import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

class MuslimGptTheme extends ThemeExtension<MuslimGptTheme> {
  final TextStyle arabicQuranStyle;
  final TextStyle arabicGeneralStyle;
  final Color citationCardColor;
  final Color arabicTextBgColor;
  final Color userBubbleColor;
  final Color assistantBubbleColor;
  final Color goldAccent;

  const MuslimGptTheme({
    required this.arabicQuranStyle,
    required this.arabicGeneralStyle,
    required this.citationCardColor,
    required this.arabicTextBgColor,
    required this.userBubbleColor,
    required this.assistantBubbleColor,
    required this.goldAccent,
  });

  static const MuslimGptTheme light = MuslimGptTheme(
    arabicQuranStyle: AppTextStyles.arabicQuran,
    arabicGeneralStyle: AppTextStyles.arabicGeneral,
    citationCardColor: AppColors.citationBg,
    arabicTextBgColor: AppColors.arabicTextBg,
    userBubbleColor: AppColors.userBubble,
    assistantBubbleColor: AppColors.assistantBubble,
    goldAccent: AppColors.gold,
  );

  @override
  MuslimGptTheme copyWith({
    TextStyle? arabicQuranStyle,
    TextStyle? arabicGeneralStyle,
    Color? citationCardColor,
    Color? arabicTextBgColor,
    Color? userBubbleColor,
    Color? assistantBubbleColor,
    Color? goldAccent,
  }) {
    return MuslimGptTheme(
      arabicQuranStyle: arabicQuranStyle ?? this.arabicQuranStyle,
      arabicGeneralStyle: arabicGeneralStyle ?? this.arabicGeneralStyle,
      citationCardColor: citationCardColor ?? this.citationCardColor,
      arabicTextBgColor: arabicTextBgColor ?? this.arabicTextBgColor,
      userBubbleColor: userBubbleColor ?? this.userBubbleColor,
      assistantBubbleColor: assistantBubbleColor ?? this.assistantBubbleColor,
      goldAccent: goldAccent ?? this.goldAccent,
    );
  }

  @override
  MuslimGptTheme lerp(covariant ThemeExtension<MuslimGptTheme>? other, double t) {
    if (other is! MuslimGptTheme) return this;
    return MuslimGptTheme(
      arabicQuranStyle: TextStyle.lerp(arabicQuranStyle, other.arabicQuranStyle, t)!,
      arabicGeneralStyle: TextStyle.lerp(arabicGeneralStyle, other.arabicGeneralStyle, t)!,
      citationCardColor: Color.lerp(citationCardColor, other.citationCardColor, t)!,
      arabicTextBgColor: Color.lerp(arabicTextBgColor, other.arabicTextBgColor, t)!,
      userBubbleColor: Color.lerp(userBubbleColor, other.userBubbleColor, t)!,
      assistantBubbleColor: Color.lerp(assistantBubbleColor, other.assistantBubbleColor, t)!,
      goldAccent: Color.lerp(goldAccent, other.goldAccent, t)!,
    );
  }
}
