import 'dart:convert';
import 'dart:math' as math;
import 'dart:io';
import 'dart:typed_data';

/// Stop words to filter out before embedding.
/// These add noise without contributing to topic relevance.
const _englishStopWords = <String>{
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
  // Hadith-specific common words that appear in nearly every hadith
  'narrated', 'reported', 'messenger', 'allah', 'prophet', 'book',
  'chapter', 'hadith', 'sahih', 'volume', 'number', 'ibn', 'abu',
};

const _arabicStopWords = <String>{
  'في', 'من', 'على', 'إلى', 'عن', 'مع', 'هذا', 'هذه', 'ذلك', 'تلك',
  'هو', 'هي', 'هم', 'هن', 'أنا', 'نحن', 'أنت', 'أنتم', 'الذي', 'التي',
  'ما', 'لا', 'لم', 'لن', 'قد', 'كان', 'كانت', 'يكون', 'إن', 'أن',
  'ثم', 'أو', 'بل', 'حتى', 'إذا', 'إذ', 'كل', 'بعض', 'غير', 'بين',
  'عند', 'فوق', 'تحت', 'قبل', 'بعد', 'منذ', 'خلال', 'حول',
};

final _allStopWords = <String>{..._englishStopWords, ..._arabicStopWords};

void main() {
  const chunksPath = 'assets/corpus/chunks.json';
  const outputBinPath = 'assets/corpus/embeddings.bin';
  const outputMetaPath = 'assets/corpus/embeddings_meta.json';
  const outputIdfPath = 'assets/corpus/idf_weights.json';
  const dimensions = 384;

  final chunksFile = File(chunksPath);
  if (!chunksFile.existsSync()) {
    stderr.writeln('Missing input file: $chunksPath');
    exitCode = 1;
    return;
  }

  final chunksDoc = jsonDecode(chunksFile.readAsStringSync()) as Map<String, dynamic>;
  final chunks = (chunksDoc['chunks'] as List<dynamic>? ?? const []);
  if (chunks.isEmpty) {
    stderr.writeln('No chunks found in $chunksPath');
    exitCode = 1;
    return;
  }

  final n = chunks.length;
  stdout.writeln('Processing $n chunks...');

  // ── Pass 1: Compute document frequency for each token ──
  stdout.writeln('Pass 1: Computing IDF weights...');
  final documentFrequency = <String, int>{};
  final chunkTokenLists = <List<String>>[];

  for (final dynamicChunk in chunks) {
    final chunk = dynamicChunk as Map<String, dynamic>;
    final text = _buildSearchText(chunk);
    final tokens = _tokenize(text);
    chunkTokenLists.add(tokens);

    // Count unique tokens per document
    final uniqueTokens = tokens.toSet();
    for (final token in uniqueTokens) {
      documentFrequency[token] = (documentFrequency[token] ?? 0) + 1;
    }
  }

  // Compute IDF: log(N / (1 + df))
  final idfWeights = <String, double>{};
  for (final entry in documentFrequency.entries) {
    idfWeights[entry.key] = math.log(n / (1 + entry.value));
  }

  stdout.writeln('  Vocabulary size: ${idfWeights.length} tokens');
  stdout.writeln('  Max IDF: ${idfWeights.values.reduce(math.max).toStringAsFixed(2)}');
  stdout.writeln('  Min IDF: ${idfWeights.values.reduce(math.min).toStringAsFixed(2)}');

  // Save IDF weights for runtime query embedding
  File(outputIdfPath).writeAsStringSync(jsonEncode(idfWeights));
  stdout.writeln('  Saved IDF weights to $outputIdfPath (${(File(outputIdfPath).lengthSync() / 1024 / 1024).toStringAsFixed(1)} MB)');

  // ── Pass 2: Build TF-IDF weighted vectors ──
  stdout.writeln('Pass 2: Building TF-IDF vectors...');
  final vectors = <List<double>>[];
  final ids = <String>[];
  var maxNorm = 0.0;
  var minNorm = double.infinity;

  for (var i = 0; i < chunks.length; i++) {
    final chunk = chunks[i] as Map<String, dynamic>;
    final id = _normalizeText(chunk['id']);
    final tokens = chunkTokenLists[i];
    final vector = _embedTokensTfIdf(tokens, idfWeights, dimensions: dimensions);
    final norm = _vectorNorm(vector);

    if (norm > maxNorm) maxNorm = norm;
    if (norm < minNorm) minNorm = norm;

    ids.add(id);
    vectors.add(vector);
  }

  final bytes = _serializeEmbeddings(vectors, dimensions: dimensions);
  File(outputBinPath).writeAsBytesSync(bytes, flush: true);

  final meta = <String, dynamic>{
    'version': '2.0.0',
    'format': {
      'magic': 'MGBE',
      'endianness': 'little',
      'dtype': 'float32',
      'header': {
        'version': 1,
        'chunkCount': ids.length,
        'dimensions': dimensions,
        'dtypeCode': 1,
      },
    },
    'generator': {
      'type': 'tfidf-hash-embedding',
      'notes': 'TF-IDF weighted hash embeddings with stop word removal.',
    },
    'chunkCount': ids.length,
    'dimensions': dimensions,
    'vocabularySize': idfWeights.length,
    'vectorNormRange': {
      'min': minNorm,
      'max': maxNorm,
    },
    'source': {
      'chunksPath': chunksPath,
      'generatedAt': DateTime.now().toIso8601String(),
    },
    'sampleChunkIds': ids.take(5).toList(growable: false),
  };
  File(outputMetaPath).writeAsStringSync('${jsonEncode(meta)}\n');

  stdout.writeln(
    'Generated $outputBinPath and $outputMetaPath '
    'for ${ids.length} chunks at $dimensions dimensions.',
  );
}

/// Tokenize text: lowercase, split on non-alphanumeric, remove stop words.
List<String> _tokenize(String text) {
  if (text.isEmpty) return const [];
  final normalized = text.toLowerCase();
  return normalized
      .split(RegExp(r'[\s\p{P}\p{S}]+', unicode: true))
      .where((t) => t.isNotEmpty && t.length > 1 && !_allStopWords.contains(t))
      .toList();
}

String _buildSearchText(Map<String, dynamic> chunk) {
  final metadata = (chunk['metadata'] as Map<String, dynamic>? ?? const {});
  final fields = <String>[
    _normalizeText(chunk['sourceName']),
    _normalizeText(chunk['reference']),
    _normalizeText(chunk['arabicText']),
    _normalizeText(chunk['translation']),
    _normalizeText(chunk['explanation']),
    _normalizeText(metadata['surahNameArabic']),
    _normalizeText(metadata['surahNameEnglish']),
    _normalizeText(metadata['surahTransliteration']),
    _normalizeText(metadata['transliteration']),
    _normalizeText(metadata['collection']),
    _normalizeText(metadata['chapterTitleArabic']),
    _normalizeText(metadata['chapterTitleEnglish']),
    _normalizeText(metadata['grade']),
    _normalizeText(metadata['inBookReference']),
  ];
  return fields.where((f) => f.isNotEmpty).join(' ');
}

/// Build a TF-IDF weighted vector using the hashing trick.
List<double> _embedTokensTfIdf(
  List<String> tokens,
  Map<String, double> idfWeights, {
  required int dimensions,
}) {
  final vector = List<double>.filled(dimensions, 0);
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
    final idf = idfWeights[token] ?? 0.0;
    final tfidf = termFreq * idf;

    final hash = _fnv1a32(token);
    final bucket = hash % dimensions;
    final sign = ((hash >> 31) & 1) == 0 ? 1.0 : -1.0;
    vector[bucket] += sign * tfidf;
  }

  // L2 normalize
  final norm = _vectorNorm(vector);
  if (norm > 0) {
    for (var i = 0; i < vector.length; i++) {
      vector[i] = vector[i] / norm;
    }
  }
  return vector;
}

double _vectorNorm(List<double> vector) {
  var sumSquares = 0.0;
  for (final value in vector) {
    sumSquares += value * value;
  }
  if (sumSquares <= 0) return 0;
  return math.sqrt(sumSquares);
}

Uint8List _serializeEmbeddings(List<List<double>> vectors, {required int dimensions}) {
  final chunkCount = vectors.length;
  const headerSize = 20; // magic(4) + version(4) + count(4) + dim(4) + dtype(4)
  final bodySize = chunkCount * dimensions * 4;
  final totalSize = headerSize + bodySize;

  final bytes = BytesBuilder(copy: false);

  // Magic: MGBE
  bytes.add([0x4D, 0x47, 0x42, 0x45]);

  final header = ByteData(16);
  header.setUint32(0, 1, Endian.little); // format version
  header.setUint32(4, chunkCount, Endian.little);
  header.setUint32(8, dimensions, Endian.little);
  header.setUint32(12, 1, Endian.little); // dtype code 1=float32
  bytes.add(header.buffer.asUint8List());

  final buffer = ByteData(bodySize);
  var offset = 0;
  for (final vector in vectors) {
    if (vector.length != dimensions) {
      throw StateError('Embedding dimension mismatch. Expected $dimensions, got ${vector.length}.');
    }
    for (final value in vector) {
      buffer.setFloat32(offset, value, Endian.little);
      offset += 4;
    }
  }
  bytes.add(buffer.buffer.asUint8List());

  final built = bytes.toBytes();
  if (built.lengthInBytes != totalSize) {
    throw StateError(
      'Binary size mismatch. Expected $totalSize bytes, got ${built.lengthInBytes} bytes.',
    );
  }
  return built;
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

String _normalizeText(Object? value) {
  final text = (value ?? '').toString();
  return text.replaceAll(RegExp(r'\s+'), ' ').trim();
}
