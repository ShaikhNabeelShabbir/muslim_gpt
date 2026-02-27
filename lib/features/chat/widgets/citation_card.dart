import 'package:flutter/material.dart';
import '../../../models/citation.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import 'arabic_text_block.dart';

class CitationCard extends StatefulWidget {
  final Citation citation;

  const CitationCard({super.key, required this.citation});

  @override
  State<CitationCard> createState() => _CitationCardState();
}

class _CitationCardState extends State<CitationCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: AppColors.citationBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primaryGreenLight.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header — always visible
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Icon(
                    Icons.menu_book_rounded,
                    size: 18,
                    color: AppColors.primaryGreen,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.citation.source,
                      style: AppTextStyles.citationSource,
                    ),
                  ),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Expandable content
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Arabic text
                  ArabicTextBlock(text: widget.citation.arabicText),
                  const SizedBox(height: 10),

                  // Translation
                  Text(
                    widget.citation.translation,
                    style: AppTextStyles.citationTranslation,
                  ),

                  // Explanation
                  if (widget.citation.explanation.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      widget.citation.explanation,
                      style: AppTextStyles.citationExplanation,
                    ),
                  ],

                  // Reference
                  if (widget.citation.reference.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.bookmark_outline,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          widget.citation.reference,
                          style: AppTextStyles.citationReference,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }
}
