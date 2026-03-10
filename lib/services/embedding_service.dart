import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/services.dart';

import '../models/retrieval_result.dart';
import 'corpus_loader_service.dart';

class EmbeddingService {
  static EmbeddingService? _instance;
  static EmbeddingService get instance => _instance ??= EmbeddingService._();
  EmbeddingService._();

  static const int _dimensions = 384;
  static const int _headerSize = 20; // magic(4) + version(4) + count(4) + dim(4) + dtype(4)

  Float32List? _vectors; // flat array: chunkCount * 384
  int _chunkCount = 0;
  bool get isLoaded => _vectors != null;

  Future<void> load() async {
    if (_vectors != null) return;

    final data = await rootBundle.load('assets/corpus/embeddings.bin');
    final bytes = data.buffer.asByteData();

    // Parse header
    final chunkCount = bytes.getUint32(8, Endian.little);
    final dimensions = bytes.getUint32(12, Endian.little);
    if (dimensions != _dimensions) {
      throw StateError('Expected $_dimensions dimensions, got $dimensions');
    }

    _chunkCount = chunkCount;

    // Read vectors as flat Float32List
    final bodyOffset = _headerSize;
    final bodyBytes = data.buffer.asUint8List(bodyOffset);
    _vectors = Float32List.view(bodyBytes.buffer, bodyBytes.offsetInBytes, chunkCount * _dimensions);
  }

  /// Retrieve top-k most similar chunks for the given query.
  List<RetrievalResult> retrieve(String query, {int topK = 5}) {
    if (_vectors == null) throw StateError('EmbeddingService not loaded. Call load() first.');

    final corpus = CorpusLoaderService.instance;
    if (!corpus.isLoaded) throw StateError('CorpusLoaderService not loaded. Call load() first.');

    final queryVector = _embedText(query);

    // Compute cosine similarity with all corpus vectors.
    // Since both query and corpus vectors are L2-normalized, dot product = cosine similarity.
    final scores = Float32List(_chunkCount);
    for (var i = 0; i < _chunkCount; i++) {
      var dot = 0.0;
      final base = i * _dimensions;
      for (var d = 0; d < _dimensions; d++) {
        dot += queryVector[d] * _vectors![base + d];
      }
      scores[i] = dot;
    }

    // Find top-k indices
    final indices = List<int>.generate(_chunkCount, (i) => i);
    indices.sort((a, b) => scores[b].compareTo(scores[a]));

    final chunks = corpus.chunks;
    final results = <RetrievalResult>[];
    for (var i = 0; i < topK && i < _chunkCount; i++) {
      final idx = indices[i];
      if (idx < chunks.length) {
        results.add(RetrievalResult(
          chunk: chunks[idx],
          score: scores[idx],
        ));
      }
    }
    return results;
  }

  // ──────────────────────────────────────────────
  // Exact port of tools/corpus/build_embeddings.dart
  // ──────────────────────────────────────────────

  Float32List _embedText(String text) {
    final vector = Float32List(_dimensions);
    if (text.isEmpty) return vector;

    final normalized = text.toLowerCase();
    final tokens = normalized.split(RegExp(r'\s+')).where((t) => t.isNotEmpty);

    for (final token in tokens) {
      final hash = _fnv1a32(token);
      final bucket = hash % _dimensions;
      final sign = ((hash >> 31) & 1) == 0 ? 1.0 : -1.0;
      final magnitude = 1.0 + ((hash & 0xFF) / 255.0);
      vector[bucket] += sign * magnitude;
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
}
