class CorpusChunk {
  final String id;
  final String sourceType;
  final String sourceName;
  final String reference;
  final String arabicText;
  final String translation;
  final String explanation;
  final Map<String, dynamic> metadata;

  const CorpusChunk({
    required this.id,
    required this.sourceType,
    required this.sourceName,
    required this.reference,
    required this.arabicText,
    required this.translation,
    this.explanation = '',
    this.metadata = const {},
  });

  factory CorpusChunk.fromJson(Map<String, dynamic> json) {
    return CorpusChunk(
      id: json['id'] as String? ?? '',
      sourceType: json['sourceType'] as String? ?? '',
      sourceName: json['sourceName'] as String? ?? '',
      reference: json['reference'] as String? ?? '',
      arabicText: json['arabicText'] as String? ?? '',
      translation: json['translation'] as String? ?? '',
      explanation: json['explanation'] as String? ?? '',
      metadata: json['metadata'] as Map<String, dynamic>? ?? const {},
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'sourceType': sourceType,
        'sourceName': sourceName,
        'reference': reference,
        'arabicText': arabicText,
        'translation': translation,
        'explanation': explanation,
      };
}
