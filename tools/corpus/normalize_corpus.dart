import 'dart:convert';
import 'dart:io';

void main() {
  final quranPath = 'assets/corpus/quran.json';
  final hadithPath = 'assets/corpus/hadith.json';
  final outputPath = 'assets/corpus/chunks.json';

  final quranFile = File(quranPath);
  final hadithFile = File(hadithPath);

  if (!quranFile.existsSync()) {
    stderr.writeln('Missing input file: $quranPath');
    exitCode = 1;
    return;
  }
  if (!hadithFile.existsSync()) {
    stderr.writeln('Missing input file: $hadithPath');
    exitCode = 1;
    return;
  }

  final quranJson = jsonDecode(quranFile.readAsStringSync()) as Map<String, dynamic>;
  final hadithJson = jsonDecode(hadithFile.readAsStringSync()) as Map<String, dynamic>;

  final chunks = <Map<String, dynamic>>[];
  final chunkIds = <String>{};
  var quranCount = 0;
  var hadithCount = 0;

  final quranItems = (quranJson['items'] as List<dynamic>? ?? const []);
  for (final surahDynamic in quranItems) {
    final surah = surahDynamic as Map<String, dynamic>;
    final surahId = surah['id'];
    final surahNameArabic = _normalizeText(surah['nameArabic']);
    final surahNameEnglish = _normalizeText(surah['englishName']);
    final surahTransliteration = _normalizeText(surah['transliteration']);
    final revelationType = _normalizeText(surah['revelationType']);
    final verses = (surah['verses'] as List<dynamic>? ?? const []);

    for (final verseDynamic in verses) {
      final verse = verseDynamic as Map<String, dynamic>;
      final ayahId = verse['ayahId'];
      final chunkId = 'quran:$surahId:$ayahId';

      _requireUniqueChunkId(chunkIds, chunkId);

      final arabicText = _normalizeText(verse['arabicText']);
      final translation = _normalizeText(verse['englishText']);
      final transliteration = _normalizeText(verse['transliteration']);

      if (arabicText.isEmpty && translation.isEmpty) {
        throw StateError('Empty Quran chunk text: $chunkId');
      }

      chunks.add({
        'id': chunkId,
        'sourceType': 'quran',
        'sourceName': surahTransliteration.isNotEmpty
            ? 'Quran - $surahTransliteration'
            : (surahNameEnglish.isNotEmpty ? 'Quran - $surahNameEnglish' : 'Quran'),
        'reference': 'Quran $surahId:$ayahId',
        'arabicText': arabicText,
        'translation': translation,
        'explanation': '',
        'metadata': {
          'surahId': surahId,
          'ayahId': ayahId,
          'surahNameArabic': surahNameArabic,
          'surahNameEnglish': surahNameEnglish,
          'surahTransliteration': surahTransliteration,
          'revelationType': revelationType,
          'transliteration': transliteration,
        },
      });
      quranCount++;
    }
  }

  final hadithItems = (hadithJson['items'] as List<dynamic>? ?? const []);
  for (final hadithDynamic in hadithItems) {
    final hadith = hadithDynamic as Map<String, dynamic>;
    final hadithId = _normalizeText(hadith['id']);
    final collectionId = _normalizeText(hadith['collectionId']);
    final collection = _normalizeText(hadith['collection']);
    final referenceKey = _normalizeText(hadith['referenceKey']);
    final reference = _normalizeText(hadith['reference']);
    final inBookReference = _normalizeText(hadith['inBookReference']);
    final hadithKey = hadithId.startsWith('$collectionId:')
        ? hadithId.substring(collectionId.length + 1)
        : hadithId;
    final chunkId = 'hadith:$collectionId:$hadithKey';

    _requireUniqueChunkId(chunkIds, chunkId);

    final arabicText = _normalizeText(hadith['arabicText']);
    final translation = _normalizeText(hadith['englishText']);

    if (arabicText.isEmpty && translation.isEmpty) {
      throw StateError('Empty Hadith chunk text: $chunkId');
    }

    final canonicalReference = referenceKey.isNotEmpty
        ? referenceKey
        : (inBookReference.isNotEmpty ? inBookReference : hadithId);

    chunks.add({
      'id': chunkId,
      'sourceType': 'hadith',
      'sourceName': collection.isNotEmpty ? collection : collectionId,
      'reference': canonicalReference,
      'arabicText': arabicText,
      'translation': translation,
      'explanation': '',
      'metadata': {
        'hadithId': hadithId,
        'hadithKey': hadithKey,
        'collectionId': collectionId,
        'collection': collection,
        'bookNumber': hadith['bookNumber'],
        'hadithNumber': _normalizeText(hadith['hadithNumber']),
        'chapterNumber': hadith['chapterNumber'],
        'chapterTitleArabic': _normalizeText(hadith['chapterTitleArabic']),
        'chapterTitleEnglish': _normalizeText(hadith['chapterTitleEnglish']),
        'grade': _normalizeText(hadith['grade']),
        'referenceUrl': reference,
        'inBookReference': inBookReference,
        'sourceFile': _normalizeText(hadith['sourceFile']),
      },
    });
    hadithCount++;
  }

  final output = {
    'version': '1.0.0',
    'source': {
      'generatedAt': DateTime.now().toIso8601String(),
      'inputs': [quranPath, hadithPath],
    },
    'totalChunks': chunks.length,
    'sourceBreakdown': {
      'quran': quranCount,
      'hadith': hadithCount,
    },
    'chunks': chunks,
  };

  final outputFile = File(outputPath);
  outputFile.writeAsStringSync('${jsonEncode(output)}\n');

  stdout.writeln(
    'Generated $outputPath with ${chunks.length} chunks (quran: $quranCount, hadith: $hadithCount).',
  );
}

String _normalizeText(Object? value) {
  final text = (value ?? '').toString();
  return text.replaceAll(RegExp(r'\s+'), ' ').trim();
}

void _requireUniqueChunkId(Set<String> seen, String chunkId) {
  if (seen.contains(chunkId)) {
    throw StateError('Duplicate chunk ID detected: $chunkId');
  }
  seen.add(chunkId);
}
