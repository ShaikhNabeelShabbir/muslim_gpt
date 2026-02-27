class Citation {
  final String source;
  final String arabicText;
  final String translation;
  final String explanation;
  final String reference;

  const Citation({
    required this.source,
    required this.arabicText,
    required this.translation,
    this.explanation = '',
    this.reference = '',
  });
}
