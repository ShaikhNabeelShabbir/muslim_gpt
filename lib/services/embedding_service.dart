import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/services.dart';

import '../models/corpus_chunk.dart';
import '../models/retrieval_result.dart';
import 'corpus_loader_service.dart';

enum _SourcePreference { quran, hadith }

/// Stop words filtered out before embedding (must match build_embeddings.dart).
const _stopWords = <String>{
  'a', 'an', 'the', 'and', 'or', 'but', 'in', 'on', 'at', 'to', 'for',
  'of', 'with', 'by', 'from', 'is', 'are', 'was', 'were', 'be', 'been',
  'being', 'have', 'has', 'had', 'do', 'does', 'did', 'will', 'would',
  'shall', 'should', 'may', 'might', 'can', 'could', 'not', 'no', 'nor',
  'so', 'if', 'then', 'than', 'that', 'this', 'these', 'those', 'it',
  'its', 'he', 'she', 'his', 'her', 'him', 'we', 'they', 'them', 'their',
  'our', 'you', 'your', 'i', 'me', 'my', 'who', 'whom', 'which', 'what',
  'when', 'where', 'how', 'why', 'as', 'up', 'out', 'about', 'into',
  'through', 'during', 'before', 'after', 'above', 'below', 'between',
  'under', 'over', 'again', 'further', 'once', 'here', 'there', 'all',
  'each', 'every', 'both', 'few', 'more', 'most', 'other', 'some', 'such',
  'only', 'own', 'same', 'too', 'very', 'just', 'also', 'now', 'well',
  'even', 'back', 'still', 'way', 'us', 'let', 'say', 'said', 'like',
  'upon', 'one', 'two', 'first', 'new', 'used', 'use', 'get',
  'go', 'went', 'come', 'came', 'made', 'make', 'take', 'took', 'see',
  'saw', 'know', 'knew', 'think', 'thought', 'tell', 'told', 'find',
  'found', 'give', 'gave', 'put', 'set', 'got', 'while', 'much', 'many',
  'any', 'am', 'off', 'down', 'against', 'because', 'until', 'since',
  'narrated', 'reported', 'messenger', 'allah', 'prophet', 'book',
  'chapter', 'hadith', 'sahih', 'volume', 'number', 'ibn', 'abu',
  // Arabic stop words
  'في', 'من', 'على', 'إلى', 'عن', 'مع', 'هذا', 'هذه', 'ذلك', 'تلك',
  'هو', 'هي', 'هم', 'هن', 'أنا', 'نحن', 'أنت', 'أنتم', 'الذي', 'التي',
  'ما', 'لا', 'لم', 'لن', 'قد', 'كان', 'كانت', 'يكون', 'إن', 'أن',
  'ثم', 'أو', 'بل', 'حتى', 'إذا', 'إذ', 'كل', 'بعض', 'غير', 'بين',
  'عند', 'فوق', 'تحت', 'قبل', 'بعد', 'منذ', 'خلال', 'حول',
};

class EmbeddingService {
  static EmbeddingService? _instance;
  static EmbeddingService get instance => _instance ??= EmbeddingService._();
  EmbeddingService._();

  static const int _dimensions = 384;
  static const int _headerSize = 20;

  Float32List? _vectors;
  int _chunkCount = 0;
  bool get isLoaded => _vectors != null;

  Map<String, double> _idfWeights = const {};
  double _maxIdf = 10.0; // Default for unknown tokens (treat as rare/important)

  Future<void> load() async {
    if (_vectors != null) return;

    // Load embeddings
    final data = await rootBundle.load('assets/corpus/embeddings.bin');
    final bytes = data.buffer.asByteData();

    final chunkCount = bytes.getUint32(8, Endian.little);
    final dimensions = bytes.getUint32(12, Endian.little);
    if (dimensions != _dimensions) {
      throw StateError('Expected $_dimensions dimensions, got $dimensions');
    }

    _chunkCount = chunkCount;

    final bodyOffset = _headerSize;
    final bodyBytes = data.buffer.asUint8List(bodyOffset);
    _vectors = Float32List.view(bodyBytes.buffer, bodyBytes.offsetInBytes, chunkCount * _dimensions);

    // Load IDF weights
    final idfJson = await rootBundle.loadString('assets/corpus/idf_weights.json');
    final idfMap = jsonDecode(idfJson) as Map<String, dynamic>;
    _idfWeights = idfMap.map((k, v) => MapEntry(k, (v as num).toDouble()));
    if (_idfWeights.isNotEmpty) {
      _maxIdf = _idfWeights.values.reduce(math.max);
    }
  }

  /// Retrieve top-k most similar chunks for the given query.
  /// Uses hybrid approach: keyword matching + vector similarity.
  List<RetrievalResult> retrieve(String query, {int topK = 5}) {
    if (_vectors == null) throw StateError('EmbeddingService not loaded. Call load() first.');

    final corpus = CorpusLoaderService.instance;
    if (!corpus.isLoaded) throw StateError('CorpusLoaderService not loaded. Call load() first.');

    final queryTokens = _tokenize(query);
    final sourcePreference = _detectSourcePreference(query);
    final chunks = corpus.chunks;

    // Stage 1: Find chunks that contain query keywords (exact match)
    final keywordMatches = <int, int>{}; // index → number of matching keywords
    if (queryTokens.isNotEmpty) {
      for (var i = 0; i < chunks.length; i++) {
        final chunkText = _buildSearchText(chunks[i]);
        var matchCount = 0;
        for (final token in queryTokens) {
          if (chunkText.contains(token)) matchCount++;
        }
        if (matchCount > 0) keywordMatches[i] = matchCount;
      }
    }

    // Stage 2: Compute vector similarity scores
    final queryVector = _embedText(query);
    final scores = Float32List(_chunkCount);
    for (var i = 0; i < _chunkCount; i++) {
      var dot = 0.0;
      final base = i * _dimensions;
      for (var d = 0; d < _dimensions; d++) {
        dot += queryVector[d] * _vectors![base + d];
      }
      scores[i] = dot;
    }

    final hasPreferredKeywordMatches = sourcePreference != null &&
        keywordMatches.keys.any(
          (index) => chunks[index].sourceType == sourcePreference.name,
        );

    // Stage 3: Combine — keyword matches dominate ranking, and explicit
    // source intent like "hadith" or "quran" strongly biases the result set.
    final ranked = <_RankedChunk>[];
    for (var i = 0; i < _chunkCount; i++) {
      final keywordCount = keywordMatches[i] ?? 0;
      final chunk = chunks[i];
      final isPreferredSource =
          sourcePreference == null || chunk.sourceType == sourcePreference.name;

      final sourceBoost = sourcePreference == null
          ? 0.0
          : (isPreferredSource ? 1.25 : -0.75);
      final keywordBoost = keywordCount * 2.5;

      ranked.add(
        _RankedChunk(
          index: i,
          combinedScore: scores[i] + keywordBoost + sourceBoost,
          keywordMatches: keywordCount,
          isPreferredSource: isPreferredSource,
        ),
      );
    }

    ranked.sort((a, b) {
      if (hasPreferredKeywordMatches) {
        final sourceCompare =
            _boolRank(b.isPreferredSource) - _boolRank(a.isPreferredSource);
        if (sourceCompare != 0) return sourceCompare;
      }

      final keywordPresenceCompare =
          _boolRank(b.keywordMatches > 0) - _boolRank(a.keywordMatches > 0);
      if (keywordPresenceCompare != 0) return keywordPresenceCompare;

      final keywordCountCompare =
          b.keywordMatches.compareTo(a.keywordMatches);
      if (keywordCountCompare != 0) return keywordCountCompare;

      if (sourcePreference != null) {
        final sourceCompare =
            _boolRank(b.isPreferredSource) - _boolRank(a.isPreferredSource);
        if (sourceCompare != 0) return sourceCompare;
      }

      return b.combinedScore.compareTo(a.combinedScore);
    });

    final results = <RetrievalResult>[];
    for (var i = 0; i < topK && i < _chunkCount; i++) {
      final idx = ranked[i].index;
      if (idx < chunks.length) {
        results.add(RetrievalResult(
          chunk: chunks[idx],
          score: ranked[i].combinedScore,
        ));
      }
    }
    return results;
  }

  /// Embed query text using TF-IDF weighted hashing (matches build_embeddings.dart).
  Float32List _embedText(String text) {
    final vector = Float32List(_dimensions);
    if (text.isEmpty) return vector;

    final tokens = _tokenize(text);
    if (tokens.isEmpty) return vector;

    // Count term frequency
    final tf = <String, int>{};
    for (final token in tokens) {
      tf[token] = (tf[token] ?? 0) + 1;
    }
    final totalTokens = tokens.length.toDouble();

    // Accumulate TF-IDF weighted hash contributions
    for (final entry in tf.entries) {
      final token = entry.key;
      final count = entry.value;
      final termFreq = count / totalTokens;
      // Unknown tokens get max IDF (treat as rare = important for queries)
      final idf = _idfWeights[token] ?? _maxIdf;
      final tfidf = termFreq * idf;

      final hash = _fnv1a32(token);
      final bucket = hash % _dimensions;
      final sign = ((hash >> 31) & 1) == 0 ? 1.0 : -1.0;
      vector[bucket] += sign * tfidf;
    }

    // L2 normalize
    var sumSquares = 0.0;
    for (final v in vector) {
      sumSquares += v * v;
    }
    if (sumSquares > 0) {
      final norm = math.sqrt(sumSquares);
      for (var i = 0; i < vector.length; i++) {
        vector[i] = vector[i] / norm;
      }
    }

    return vector;
  }

  /// Tokenize: lowercase, split on non-alphanumeric, remove stop words and single chars.
  List<String> _tokenize(String text) {
    final normalized = text.toLowerCase();
    return normalized
        .split(RegExp(r'[\s\p{P}\p{S}]+', unicode: true))
        .where((t) => t.isNotEmpty && t.length > 1 && !_stopWords.contains(t))
        .toList();
  }

  String _buildSearchText(CorpusChunk chunk) {
    final metadata = chunk.metadata;
    return [
      chunk.sourceType,
      chunk.sourceName,
      chunk.reference,
      chunk.translation,
      chunk.explanation,
      chunk.arabicText,
      metadata['surahNameEnglish'],
      metadata['surahTransliteration'],
      metadata['collection'],
      metadata['chapterTitleEnglish'],
      metadata['grade'],
      metadata['inBookReference'],
    ].whereType<String>().join(' ').toLowerCase();
  }

  _SourcePreference? _detectSourcePreference(String query) {
    final normalized = query.toLowerCase();

    if (RegExp(r"\b(quran|qur'?an|ayah|verse|surah)\b").hasMatch(normalized)) {
      return _SourcePreference.quran;
    }

    if (RegExp(r'\b(hadith|hadeeth|sunnah)\b').hasMatch(normalized)) {
      return _SourcePreference.hadith;
    }

    return null;
  }

  int _fnv1a32(String input) {
    const fnvOffset = 0x811C9DC5;
    const fnvPrime = 0x01000193;
    var hash = fnvOffset;

    for (final rune in input.runes) {
      hash ^= rune & 0xFF;
      hash = (hash * fnvPrime) & 0xFFFFFFFF;
    }
    return hash;
  }

  int _boolRank(bool value) => value ? 1 : 0;
}

class _RankedChunk {
  final int index;
  final double combinedScore;
  final int keywordMatches;
  final bool isPreferredSource;

  const _RankedChunk({
    required this.index,
    required this.combinedScore,
    required this.keywordMatches,
    required this.isPreferredSource,
  });
}
