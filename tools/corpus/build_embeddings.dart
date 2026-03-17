import 'dart:convert';
import 'dart:math' as math;
import 'dart:io';
import 'dart:typed_data';

void main() {
  const chunksPath = 'assets/corpus/chunks.json';
  const outputBinPath = 'assets/corpus/embeddings.bin';
  const outputMetaPath = 'assets/corpus/embeddings_meta.json';
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

  final vectors = <List<double>>[];
  final ids = <String>[];
  var maxNorm = 0.0;
  var minNorm = double.infinity;

  for (final dynamicChunk in chunks) {
    final chunk = dynamicChunk as Map<String, dynamic>;
    final id = _normalizeText(chunk['id']);
    final text = _buildSearchText(chunk);
    final vector = _embedText(text, dimensions: dimensions);
    final norm = _vectorNorm(vector);

    if (norm > maxNorm) maxNorm = norm;
    if (norm < minNorm) minNorm = norm;

    ids.add(id);
    vectors.add(vector);
  }

  final bytes = _serializeEmbeddings(vectors, dimensions: dimensions);
  File(outputBinPath).writeAsBytesSync(bytes, flush: true);

  final meta = <String, dynamic>{
    'version': '1.0.0',
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
      'type': 'deterministic-hash-embedding',
      'notes': 'Bootstrapping embeddings for local retrieval; replace with model-based embeddings later.',
    },
    'chunkCount': ids.length,
    'dimensions': dimensions,
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

List<double> _embedText(String text, {required int dimensions}) {
  final vector = List<double>.filled(dimensions, 0);
  if (text.isEmpty) return vector;

  final normalized = text.toLowerCase();
  final tokens = normalized.split(RegExp(r'\s+')).where((t) => t.isNotEmpty);

  for (final token in tokens) {
    final hash = _fnv1a32(token);
    final bucket = hash % dimensions;
    final sign = ((hash >> 31) & 1) == 0 ? 1.0 : -1.0;
    final magnitude = 1.0 + ((hash & 0xFF) / 255.0);
    vector[bucket] += sign * magnitude;
  }

  final norm = _vectorNorm(vector);
  if (norm == 0) return vector;

  for (var i = 0; i < vector.length; i++) {
    vector[i] = vector[i] / norm;
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
  final headerSize = 20; // magic(4) + version(4) + count(4) + dim(4) + dtype(4)
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
