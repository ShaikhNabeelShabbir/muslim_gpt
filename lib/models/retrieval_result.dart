import 'corpus_chunk.dart';

class RetrievalResult {
  final CorpusChunk chunk;
  final double score;

  const RetrievalResult({
    required this.chunk,
    required this.score,
  });
}
