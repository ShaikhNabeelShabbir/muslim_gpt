# Muslim GPT Offline RAG + On-Device SLM Plan

## Objective
Build a fully offline Islamic Q&A app by replacing network inference with:
1. Local Quran + Hadith corpus
2. Local retrieval (RAG)
3. On-device SLM inference
4. Grounded citation rendering from local sources

## Scope Guardrails
1. Keep current app functional while building offline stack in parallel.
2. Make all new components additive until explicit cutover.
3. Enforce citation grounding from retrieved records only.
4. Preserve traceability (source, reference, provenance, license notes).

## Status Summary
### Done
1. Added corpus scaffolding and tooling placeholders:
   - `tools/corpus/fetch_quran.dart`
   - `tools/corpus/fetch_hadith.dart`
   - `tools/corpus/normalize_corpus.dart`
   - `tools/corpus/build_embeddings.dart`
2. Added corpus/runtime models and services (not wired into chat flow):
   - `lib/models/corpus_chunk.dart`
   - `lib/models/retrieval_result.dart`
   - `lib/services/corpus_loader_service.dart`
   - `lib/services/embedding_service.dart`
   - `lib/services/retriever_service.dart`
   - `lib/services/rag_answer_service.dart`
3. Added corpus asset placeholders:
   - `assets/corpus/sources_manifest.json`
   - `assets/corpus/hadith.json`
   - `assets/corpus/chunks.json`
   - `assets/corpus/embeddings.bin`
4. Built real Quran corpus file:
   - `assets/corpus/quran.json`
   - Contains 114 surahs and 6236 ayahs with Arabic text + English translation + transliteration.

### In Progress
1. Finalizing canonical Hadith schema for `assets/corpus/hadith.json`.
2. Defining ingestion and normalization rules for `hadithapi.com` datasets.
3. Preparing corpus provenance/licensing entries in `sources_manifest.json`.

### Will Be Done
1. Complete Hadith ingestion and normalization pipeline.
2. Build chunking + embeddings for Quran and Hadith.
3. Integrate retrieval layer into chat flow (initially no SLM).
4. Add on-device SLM runtime and generation flow.
5. Cut over from remote API to fully local mode.

## Implementation Phases

## Phase 1: Corpus Contract and Data Ingestion
### Goals
1. Lock schema for Quran and Hadith records.
2. Populate `hadith.json` with normalized, canonical records.
3. Capture provenance and licensing metadata.

### Tasks
1. Define canonical Hadith JSON schema:
   - `id`, `collection`, `bookNumber`, `bookName`
   - `chapterNumber`, `chapterTitle`
   - `hadithNumber`, `arabicText`, `englishText`
   - `grade`, `reference`, `sourceUrl`, `sourceLicense`
2. Implement `tools/corpus/fetch_hadith.dart` with:
   - API key auth
   - pagination
   - retries/backoff
   - resumable checkpoints
3. Save raw snapshots in a deterministic local structure.
4. Normalize into `assets/corpus/hadith.json`.
5. Update `assets/corpus/sources_manifest.json`.

### Exit Criteria
1. `hadith.json` generated end-to-end from source APIs.
2. Stable IDs and required fields present.
3. No duplicate canonical IDs.

## Phase 2: Retrieval-Ready Corpus
### Goals
1. Produce retrieval chunks and embeddings.
2. Ensure chunk-to-source traceability for citations.

### Tasks
1. Implement chunk generation in `tools/corpus/normalize_corpus.dart`.
2. Populate `assets/corpus/chunks.json` from Quran + Hadith.
3. Implement embedding generation in `tools/corpus/build_embeddings.dart`.
4. Populate `assets/corpus/embeddings.bin` and index metadata.
5. Run quality checks for retrieval relevance on known Islamic queries.

### Exit Criteria
1. `chunks.json` and `embeddings.bin` generated and loadable.
2. Retriever returns relevant top-k passages for smoke-test queries.
3. Every retrieval result maps to a valid source citation.

## Phase 3: Local RAG in App (No SLM Yet)
### Goals
1. Add local grounded answers without breaking existing app behavior.
2. Keep remote API path as fallback during transition.

### Tasks
1. Wire `corpus_loader_service`, `retriever_service`, `rag_answer_service` behind a feature flag.
2. Add local answer mode in chat provider:
   - question -> retrieve -> compose grounded response -> render citations
3. Persist local RAG responses via existing DB flow.
4. Add settings toggle for `Remote API` vs `Local RAG`.

### Exit Criteria
1. App can answer using local corpus offline.
2. Citation cards render from retrieved records.
3. Existing remote path still functional when toggle is off.

## Phase 4: On-Device SLM Integration
### Goals
1. Replace template-style local answers with natural generation.
2. Keep citation grounding anchored to retrieval sources.

### Tasks
1. Integrate on-device inference runtime (target: `llama.cpp` + GGUF).
2. Add model asset/download management and versioning.
3. Build prompt assembly:
   - system rules
   - retrieved context
   - user question
4. Stream token output to chat UI.
5. Enforce citation mapping from retrieval IDs, not free-form model references.

### Exit Criteria
1. Fully offline generation works without network.
2. Output latency acceptable on target devices.
3. Citations remain grounded and verifiable.

## Phase 5: Cutover to Fully Offline Default
### Goals
1. Make local stack the default production path.
2. Remove hard dependency on remote API.

### Tasks
1. Switch default chat provider mode to local.
2. Keep remote path optional or remove it after validation.
3. Finalize migration docs and data update process.
4. Run full QA: analyzer, tests, device checks, performance checks.

### Exit Criteria
1. App fully functional offline by default.
2. No mandatory external API dependency.
3. Release checklist completed.

## Technical Risks and Mitigations
1. Large corpus/model size:
   - Use staged downloads and compression.
2. Low-end device latency:
   - Start with smaller quantized models and strict token limits.
3. Citation hallucination:
   - Resolve citations from retrieval metadata only.
4. Data licensing ambiguity:
   - Track source/license per dataset in manifest.
5. Data drift during updates:
   - Version all corpus builds with reproducible scripts.

## Immediate Next Actions
1. Finalize and approve Hadith schema.
2. Implement `fetch_hadith.dart` with auth + pagination + checkpointing.
3. Generate first real `assets/corpus/hadith.json`.
4. Update manifest with sources and fetch metadata.

