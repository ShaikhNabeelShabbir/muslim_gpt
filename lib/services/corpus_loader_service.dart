import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/corpus_chunk.dart';

class CorpusLoaderService {
  static CorpusLoaderService? _instance;
  static CorpusLoaderService get instance => _instance ??= CorpusLoaderService._();
  CorpusLoaderService._();

  List<CorpusChunk>? _chunks;
  Map<String, CorpusChunk>? _chunkById;

  bool get isLoaded => _chunks != null;

  List<CorpusChunk> get chunks => _chunks ?? const [];

  CorpusChunk? getById(String id) => _chunkById?[id];

  Future<void> load() async {
    if (_chunks != null) return;

    final raw = await rootBundle.loadString('assets/corpus/chunks.json');
    final doc = jsonDecode(raw) as Map<String, dynamic>;
    final list = doc['chunks'] as List<dynamic>? ?? const [];

    _chunks = list
        .map((e) => CorpusChunk.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);

    _chunkById = {for (final c in _chunks!) c.id: c};
  }
}
