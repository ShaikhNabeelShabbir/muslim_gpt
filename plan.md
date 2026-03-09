# Muslim GPT Offline RAG + On-Device SLM Plan

## Objective
Eliminate all API costs and network dependency by building a fully offline Islamic Q&A app with:
1. Local Quran + Hadith corpus (bundled with app)
2. Local retrieval via embedding similarity (RAG)
3. On-device SLM inference (no cloud API calls)
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
7. **Working cloud-based app** — Full chat UI, SQLite persistence, Railway backend with OpenRouter (Kimi K2.5).

### Not Yet Built
1. Runtime Dart models: `corpus_chunk.dart`, `retrieval_result.dart`.
2. Runtime Dart services: `corpus_loader_service.dart`, `embedding_service.dart`, `retriever_service.dart`, `rag_answer_service.dart`.
3. Corpus provenance manifest: `sources_manifest.json`.
4. On-device SLM runtime integration.
5. Settings toggle for offline vs. remote mode.

---

## Implementation Phases

### Phase 1: Corpus ✅ COMPLETE
**What was done:**
- Quran corpus built (114 surahs, 6,236 ayahs).
- Hadith corpus built (33,738 hadiths, 6 collections).
- Chunking pipeline built and run (39,974 chunks).
- Embedding pipeline built and run (384-dim vectors, ~61 MB binary).

---

### Phase 2: Runtime RAG Layer (Next Up)
**Goal:** Load corpus + embeddings in-app and retrieve relevant passages for any user question.

#### Tasks
1. Create `lib/models/corpus_chunk.dart` — chunk data model matching chunks.json schema.
2. Create `lib/models/retrieval_result.dart` — ranked result with chunk + similarity score.
3. Create `lib/services/corpus_loader_service.dart`:
   - Load `chunks.json` from bundled assets.
   - Parse into in-memory chunk list.
   - Index by chunk ID for fast lookup.
4. Create `lib/services/embedding_service.dart`:
   - Load `embeddings.bin` from bundled assets (read binary, parse float32 vectors).
   - Embed user query using same FNV-1a hash function (must match `build_embeddings.dart` logic).
   - Compute cosine similarity between query vector and all corpus vectors.
5. Create `lib/services/retriever_service.dart`:
   - Accept a query string.
   - Embed it → rank all chunks by cosine similarity → return top-k results.
   - Map each result back to its source chunk for citation data.
6. Smoke-test retrieval with known queries:
   - "What is Ayat al-Kursi?" → should return Quran 2:255.
   - "Hadith on patience" → should return relevant Bukhari/Muslim hadiths.
   - "Five pillars of Islam" → should return relevant ayahs and hadiths.

#### Exit Criteria
1. Retriever returns relevant top-k passages for test queries.
2. Every result maps to a valid source citation (surah/ayah or collection/hadith number).
3. No network calls involved.

---

### Phase 3: Local RAG Answer Flow (No SLM)
**Goal:** Wire retrieval into the chat UI so users get offline answers with citations, using template-based response composition (no language model yet).

#### Tasks
1. Create `lib/services/rag_answer_service.dart`:
   - Take user question → call retriever → compose a grounded response from top-k chunks.
   - Template format: intro text + retrieved passages with citations.
   - Convert retrieved chunks into `Citation` objects matching existing model.
2. Add Riverpod provider for RAG service (lazy initialization, load corpus on first use).
3. Update `chat_provider.dart`:
   - Add local answer mode alongside existing remote API mode.
   - Route based on settings toggle.
4. Add settings toggle in `settings_screen.dart`: "Remote API" vs. "Offline (Local)".
5. Persist local RAG responses via existing SQLite flow.

#### Exit Criteria
1. App answers questions offline using local corpus.
2. Citation cards render correctly from retrieved chunks.
3. Remote API path still works when selected.

---

### Phase 4: On-Device SLM Integration
**Goal:** Replace template-based answers with natural language generation using a small language model running on-device. Zero API costs.

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

### Phase 5: Cutover to Fully Offline Default
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
| Large app bundle (~61 MB embeddings + corpus + model) | Compress assets; consider on-demand download for SLM model |
| Low-end device latency for SLM | Start with smallest quantized model; set strict token limits; show streaming output |
| Citation hallucination by SLM | Resolve citations from retrieval metadata only, never from model output |
| Hash-based embeddings have low retrieval quality | Current FNV-1a embeddings are bootstrapping only; replace with model-based embeddings (e.g., MiniLM) once SLM runtime is available |
| Memory pressure loading 40k vectors | Lazy load; consider memory-mapped file access for embeddings |
| Data licensing ambiguity | Track source/license per dataset in manifest |

---

## Immediate Next Actions
1. Build `corpus_chunk.dart` and `retrieval_result.dart` models.
2. Build `corpus_loader_service.dart` to load chunks from bundled assets.
3. Build `embedding_service.dart` to load embeddings and compute similarity.
4. Build `retriever_service.dart` to return top-k results for a query.
5. Smoke-test retrieval accuracy with known Islamic queries.
