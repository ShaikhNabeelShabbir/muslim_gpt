# Muslim GPT Offline RAG + On-Device Answer Quality Plan

## Objective
Deliver a fully offline Islamic Q&A app that:
1. Uses bundled Quran and Hadith sources as the only knowledge base.
2. Retrieves relevant local evidence reliably.
3. Produces faithful, citation-grounded answers from that evidence.
4. Minimizes hallucination, paraphrase drift, and malformed model output.

## Scope Guardrails
1. Retrieval must remain grounded in local corpus records only.
2. Citations must come from retrieved chunks, never be invented by the model.
3. Factual canonical questions should prefer faithfulness over fluency.
4. Quality work should be measurable with repeatable evaluation prompts.

---

## Status Summary

### Done (Verified in Repo)
1. **Quran corpus** — `assets/corpus/quran.json`
   - Bundled locally with Arabic text, English translation, and transliteration.
2. **Hadith corpus** — `assets/corpus/hadith.json`
   - 33,738 hadiths across 6 canonical collections.
3. **Normalized chunk pipeline** — `tools/corpus/normalize_corpus.dart`
   - Produces unified records in `assets/corpus/chunks.json`.
4. **Embedding pipeline** — `tools/corpus/build_embeddings.dart`
   - Produces TF-IDF weighted hash embeddings in `assets/corpus/embeddings.bin`.
5. **Runtime corpus loading** — `lib/services/corpus_loader_service.dart`
   - Loads bundled chunks at runtime.
6. **Runtime retrieval** — `lib/services/embedding_service.dart`
   - Loads embeddings, embeds queries, computes similarity, and ranks candidates.
7. **On-device model runtime** — `lib/services/local_llm_service.dart`
   - Uses bundled GGUF model through `fllama`.
8. **Model extraction on startup** — `lib/services/model_extractor_service.dart`
   - Copies the GGUF model from assets to app storage.
9. **Chat orchestration** — `lib/features/chat/providers/chat_provider.dart`
   - Retrieves local evidence, tries local generation, and falls back to citation-first response.
10. **Initial quality hardening**
   - Added query source-intent handling for `hadith` vs `quran`.
   - Expanded keyword ranking text beyond translation/reference only.
   - Reduced local model randomness.
   - Sanitized malformed model output and fall back when output is unusable.

### Current Quality Issues
1. Canonical factual questions can still be paraphrased incorrectly by the local model.
2. TF-IDF hash retrieval is workable but weaker than true embedding retrieval.
3. No formal evaluation set exists for measuring Islamic answer faithfulness.
4. No deterministic answer mode exists for high-confidence, structured questions.
5. The current bundled model (`Qwen2.5-1.5B-Instruct q2_k`) is compact but weak for faithful summarization.

---

## Implementation Phases

### Phase 1: Corpus and Offline Retrieval Foundation ✅ COMPLETE
- Quran and Hadith corpora bundled locally.
- Unified chunk schema created.
- TF-IDF hash embedding index created.
- Runtime loading and retrieval path integrated into chat flow.

### Phase 2: On-Device Generation Integration ✅ COMPLETE
- GGUF model bundled in `assets/models/`.
- Model extracted locally on startup.
- `fllama` wired for on-device completion.
- Chat pipeline uses local retrieval plus local generation.
- Citation-grounded fallback response exists when generation fails.

### Phase 3: Retrieval Reliability Hardening 🔄 IN PROGRESS
**Goal:** Make the retrieved evidence reliably match the user’s intent before generation.

#### Exact Changes
1. Strengthen explicit source-intent routing in `lib/services/embedding_service.dart`.
   - Keep `hadith` vs `quran` preference detection.
   - Expand to detect `verse`, `surah`, `ayah`, `sunnah`, `dua`, `zakat`, `hajj`, `wudu` style intent hints where appropriate.
2. Improve searchable text used for keyword ranking.
   - Keep translation, reference, source name, source type.
   - Add more metadata fields such as collection, chapter title, surah name, transliteration, and topic aliases.
3. Introduce a canonical topic alias map.
   - Example: `five pillars` → `islam is built on five`, `arkan al-islam`.
   - Example: `wudu` ↔ `ablution`.
   - Example: `charity` ↔ `zakat`.
4. Add source-quality priors for ranking.
   - Prefer stronger canonical records for foundational questions where appropriate.
   - Avoid over-weighting loosely related matches when exact canonical hits exist.
5. Add retrieval debugging output for development.
   - Log query tokens, source preference, top scores, and chosen chunk IDs in debug mode.
6. Build a retrieval evaluation script.
   - Input: fixed set of queries.
   - Output: top-k chunk IDs and scores.
   - Use it to tune ranking before changing generation.

#### Exit Criteria
1. Queries like `Hadith on patience` consistently return hadith-first results.
2. Canonical queries like `Five Pillars of Islam` retrieve direct foundational records in top-k.
3. Top-k retrieval behavior is inspectable and repeatable.

### Phase 4: Answer Faithfulness Layer 🚧 NEXT PRIORITY
**Goal:** Reduce model paraphrase errors by preferring extraction and structure over free-form generation.

#### Exact Changes
1. Add answer modes in `lib/features/chat/providers/chat_provider.dart`.
   - `deterministic_rag`: citation-first extraction without free-form model generation.
   - `local_llm_summary`: model-generated summary from retrieved chunks.
   - Route canonical factual questions to deterministic mode first.
2. Add canonical question detectors.
   - Examples: Five Pillars, Six Articles of Faith, Wudu steps, fasting basics, Ayat al-Kursi, Shahada.
   - Use simple pattern matching before general generation.
3. Add structured response builders in `lib/services/rag_answer_service.dart`.
   - Render list-style answers for enumerations.
   - Render verse/hadith summaries from citations directly.
   - Avoid model-written enumerations when the source already contains the list.
4. Tighten generation prompts in `lib/services/local_llm_service.dart`.
   - Instruct the model to restate only what is explicitly present.
   - Forbid adding unstated items or alternate wording that changes meaning.
   - Ask it to say `sources are insufficient` when evidence is weak.
5. Add stronger output validation.
   - Reject answers that mention entities or list items not supported by citations.
   - Reject malformed prompt leakage.
   - Reject overly long or off-topic answers for short factual queries.
6. Add quote-assisted rendering for sensitive canonical answers.
   - Show a short faithful paraphrase plus direct citation cards.
   - Prefer source-backed wording over model creativity.

#### Exit Criteria
1. `What are the Five Pillars of Islam?` returns the correct five items consistently.
2. Canonical list questions are answered from retrieved sources, not model improvisation.
3. When the model is uncertain or malformed, the app falls back cleanly to grounded output.

### Phase 5: Better Local Model Strategy
**Goal:** Improve local generation quality when free-form summarization is still needed.

#### Exact Changes
1. Replace or supplement the current GGUF model.
   - Evaluate stronger quantizations first: `q4_k_m` or similar before changing architecture.
   - Compare Qwen 1.5B/3B, Phi, SmolLM, TinyLlama class models for instruction-following and factual grounding.
2. Add model benchmark prompts.
   - Use fixed Islamic QA examples with expected grounded behavior.
   - Score for faithfulness, formatting, latency, and memory usage.
3. Make model selection configurable.
   - Keep current model as baseline.
   - Allow swapping to a stronger local model without rewriting app logic.
4. Tune inference parameters.
   - Evaluate lower temperature, lower token budget, repeat penalty, and prompt shape.
   - Prefer consistency for factual questions over conversational style.

#### Exit Criteria
1. The chosen local model materially improves fidelity on the evaluation set.
2. Response quality improves without unacceptable latency on target devices.

### Phase 6: Retrieval Upgrade Beyond TF-IDF Hashing
**Goal:** Improve semantic recall for paraphrased or indirect questions.

#### Exact Changes
1. Evaluate true embedding generation offline.
   - Candidate families: MiniLM, BGE-small, E5-small, multilingual alternatives.
2. Generate a new embedding index and compare against current TF-IDF hash retrieval.
3. Keep keyword and source-intent ranking even after adopting better embeddings.
4. If needed, use hybrid retrieval:
   - semantic embedding score
   - exact keyword score
   - source-intent score
   - source-quality prior

#### Exit Criteria
1. Paraphrased questions perform better than with hash-only retrieval.
2. Exact canonical questions remain at least as good as current behavior.

### Phase 7: Evaluation, QA, and Cutover
**Goal:** Make answer quality measurable and stable before wider rollout.

#### Exact Changes
1. Create a local evaluation set of representative queries.
   - Canonical facts
   - practice/how-to questions
   - verse/hadith lookup
   - topic questions like patience, tawakkul, zakat, hajj
2. For each query, record:
   - expected source type
   - acceptable top-k references
   - expected answer shape
   - forbidden errors
3. Add regression testing workflow.
   - Run retrieval evaluation after changes to corpus, embeddings, prompts, or model.
4. Update README and internal docs to reflect offline architecture and known tradeoffs.
5. Decide final default mode.
   - If deterministic mode proves stronger for core factual questions, make it default there.
   - Keep local LLM summarization for broader explanatory questions.

#### Exit Criteria
1. Quality improvements are measured, not anecdotal.
2. Core Islamic factual questions are consistently grounded and correct.
3. The app has a stable default answer strategy.

---

## Technical Risks and Mitigations

| Risk | Mitigation |
|---|---|
| Small local model rewrites correct sources incorrectly | Route canonical questions to deterministic extraction mode first |
| Hash-based retrieval misses paraphrases | Upgrade to true embeddings while retaining keyword/source reranking |
| Wrong citation type selected for user intent | Keep source-intent routing and evaluate with explicit query sets |
| Large bundle size from model and corpus assets | Evaluate stronger but efficient quantization and optional download strategy |
| Quality work becomes subjective | Maintain a fixed evaluation set with expected references and answer shapes |

---

## Immediate Next Actions
1. Add deterministic answer mode for canonical factual questions.
2. Create a first evaluation set with at least 25 representative Islamic queries.
3. Add canonical topic alias mapping for high-frequency questions.
4. Benchmark the current `q2_k` model against a stronger local quantization.
5. Decide whether Phase 4 or Phase 5 gives the best quality-per-effort next.
