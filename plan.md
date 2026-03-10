# Muslim GPT Offline RAG + On-Device SLM Plan

## Objective
Eliminate all API costs and network dependency by building a fully offline Islamic Q&A app with:
1. Local Quran + Hadith corpus (bundled with app)
2. Local retrieval via embedding similarity (RAG)
3. Free HuggingFace API for generation (interim) → On-device SLM (future)
4. Grounded citation rendering from local sources only

## Scope Guardrails
1. Keep current app functional while building offline stack in parallel.
2. Make all new components additive until explicit cutover.
3. Enforce citation grounding from retrieved records only.
4. Preserve traceability (source, reference, provenance, license notes).

---

## Status Summary

### Done (Verified)
1. **Quran corpus** — `assets/corpus/quran.json`
   - 114 surahs, 6,236 ayahs with Arabic text + English translation + transliteration.
2. **Hadith corpus** — `assets/corpus/hadith.json`
   - 33,738 hadiths from 6 canonical collections (Bukhari, Muslim, Tirmidhi, Abu Dawud, Nasa'i, Ibn Majah).
3. **Chunking tool** — `tools/corpus/normalize_corpus.dart`
   - Merges Quran + Hadith into unified chunks with stable IDs (`quran:surahId:ayahId`, `hadith:collectionId:key`).
4. **Chunks output** — `assets/corpus/chunks.json`
   - 39,974 chunks (6,236 Quran + 33,738 Hadith), generated and loadable.
5. **Embedding tool** — `tools/corpus/build_embeddings.dart`
   - Generates 384-dimensional vectors using deterministic FNV-1a hash-based embedding.
6. **Embeddings output** — `assets/corpus/embeddings.bin` (~61 MB) + `assets/corpus/embeddings_meta.json`
   - 39,974 vectors, normalized, binary format with MGBE magic header.
7. **Working cloud-based app** — Full chat UI, SQLite persistence, Railway backend.
8. **Runtime RAG models** — `lib/models/corpus_chunk.dart`, `lib/models/retrieval_result.dart`.
9. **Corpus loader** — `lib/services/corpus_loader_service.dart` — loads chunks.json from bundled assets, indexes by ID.
10. **Embedding + retriever service** — `lib/services/embedding_service.dart` — loads embeddings.bin, embeds queries using identical FNV-1a algorithm, computes cosine similarity, returns top-k results.
11. **RAG wired into chat flow** — `chat_provider.dart` retrieves top-5 chunks before each API call, `openrouter_service.dart` sends context array to backend.
12. **Android internet permission** — Added to `AndroidManifest.xml` for release builds.
13. **Corpus assets registered** — `chunks.json` and `embeddings.bin` added to `pubspec.yaml`.

### Not Yet Done
1. On-device SLM runtime integration (future — Phase 4).
2. Settings toggle for offline vs. remote mode (future — Phase 5).

---

## Implementation Phases

### Phase 1: Corpus ✅ COMPLETE
- Quran corpus built (114 surahs, 6,236 ayahs).
- Hadith corpus built (33,738 hadiths, 6 collections).
- Chunking pipeline built and run (39,974 chunks).
- Embedding pipeline built and run (384-dim vectors, ~61 MB binary).

---

### Phase 2: Runtime RAG Layer ✅ COMPLETE
- `lib/models/corpus_chunk.dart` — chunk data model with `fromJson()`.
- `lib/models/retrieval_result.dart` — chunk + similarity score wrapper.
- `lib/services/corpus_loader_service.dart` — singleton, loads chunks.json via rootBundle, indexes by ID.
- `lib/services/embedding_service.dart` — singleton, loads embeddings.bin, ports exact FNV-1a hash embedding, cosine similarity search, returns top-k `RetrievalResult`.
- `lib/services/openrouter_service.dart` — updated to accept and send `context` (retrieved chunks) to backend.
- `lib/features/chat/providers/chat_provider.dart` — updated to load corpus + embeddings on first use, retrieve top-5 chunks before each API call.
- `pubspec.yaml` — registered `chunks.json` and `embeddings.bin` as bundled assets.

---

### Phase 3: Backend Migration to Free HuggingFace API ✅ COMPLETE
- Deployed updated `index.tsx` to Railway with HuggingFace Router API (`Qwen/Qwen2.5-72B-Instruct`).
- Backend accepts `context` array and injects retrieved sources into system prompt.
- `HF_TOKEN` set in Railway environment variables.
- Smoke-tested end-to-end successfully — grounded citations working.

---

### Phase 4: On-Device SLM Integration (Future)
**Goal:** Replace HuggingFace API with on-device SLM for fully offline operation.

#### Tasks
1. Evaluate Flutter-compatible on-device inference options:
   - `flutter_llm` / `fllama` (llama.cpp bindings for Flutter).
   - ONNX Runtime via FFI.
   - TensorFlow Lite via `tflite_flutter`.
2. Select and integrate a small GGUF model (target: 1-3B parameters, Q4 quantized).
   - Candidates: Phi-3-mini, TinyLlama, Qwen2-1.5B, SmolLM2.
3. Add model management:
   - Bundle small model with app OR download on first launch.
   - Show download progress UI if needed.
   - Version tracking for model updates.
4. Build prompt assembly pipeline:
   - System prompt: Islamic Q&A rules + citation format.
   - Retrieved context: top-k chunks from retriever.
   - User question.
5. Stream token output to chat UI (token-by-token rendering).
6. Enforce citation mapping from retrieval chunk IDs only — model cannot invent references.

#### Exit Criteria
1. Fully offline natural language answers with no network dependency.
2. Response latency under 10 seconds on mid-range devices.
3. Citations remain grounded and verifiable against corpus.
4. Zero API costs per query.

---

### Phase 5: Cutover to Fully Offline Default (Future)
**Goal:** Make offline mode the default. Remove Railway backend dependency.

#### Tasks
1. Switch default mode to offline/local in chat provider.
2. Remove or make remote API path opt-in only.
3. Remove Railway backend deployment (eliminate hosting costs).
4. Optimize app bundle size:
   - Compress corpus assets.
   - Evaluate splitting embeddings into downloadable packs.
5. Run full QA: Dart analyzer, widget tests, device testing (low-end Android, iOS).
6. Performance benchmarks: startup time, first-query latency, memory usage.

#### Exit Criteria
1. App fully functional offline by default.
2. No mandatory external API dependency.
3. Zero recurring API/hosting costs.
4. Acceptable performance on target devices.

---

## Technical Risks and Mitigations

| Risk | Mitigation |
|---|---|
| Large app bundle (~61 MB embeddings + corpus) | Compress assets; consider on-demand download for SLM model |
| Low-end device latency for SLM | Start with smallest quantized model; set strict token limits; show streaming output |
| Citation hallucination by SLM | Resolve citations from retrieval metadata only, never from model output |
| Hash-based embeddings have low retrieval quality | Current FNV-1a embeddings are bootstrapping only; replace with model-based embeddings (e.g., MiniLM) once SLM runtime is available |
| Memory pressure loading 40k vectors | Lazy load; consider memory-mapped file access for embeddings |
| HuggingFace free tier rate limits | Monitor usage; queue requests if needed; fallback to alternate free model |

---

## Immediate Next Actions
1. Evaluate retrieval quality — tune top-k or improve embedding approach if results are weak.
2. Consider replacing FNV-1a hash embeddings with model-based embeddings (e.g., MiniLM) for better retrieval accuracy.
3. When ready for fully offline: evaluate on-device SLM options (Phase 4).
