# Scope Statement: Unstructured Retrieval

Version: 0.1
Status: Draft — addresses architecture evaluation gap S1
Audience: CTO, hometown team, application owners, partner reviewers
Primary post-read action: adopt the scope limit as a stated program position, and decide whether POC F is chartered or deferred.

## 1. The Position

**Fiskroad governs structured business context. Unstructured retrieval — documents, notes, correspondence, contracts, and policy material — is out of scope for the MVP.**

This is a deliberate boundary, stated in advance. It is not a gap discovered under questioning, and the difference between those two things is most of the credibility at stake in the partner review.

## 2. What Is Excluded

No component of Fiskroad today ingests, chunks, embeds, indexes, or retrieves unstructured content. There is no vector store, no embedding pipeline, and no document ingestion path. An AI feature asking "what did we agree with this borrower in the amendment letter?" cannot be served, and should not be attempted with the current architecture.

## 3. Why The Boundary Is Principled, Not Merely Convenient

Fiskroad's governance model rests on a specific mechanism: context is a **validated semantic record** with a contract, an owner, a schema, and a hash. That mechanism is what makes provenance, tenant isolation, freshness declaration, and groundedness scoring all work. Every guarantee the program makes descends from it.

Unstructured content has no equivalent contract yet. A document chunk has no schema, no validated shape, and no natural owner. Extending the governance model to cover it is genuine design work, not integration work — which is precisely why it must not be quietly added to hometown as "one more integration."

Three specific conflicts would have to be resolved first, and naming them is what turns this from a limitation into a demonstration of rigor:

1. **The no-content guardrail collides with vector storage.** Fiskroad's standing rule is that governed stores hold references and hashes, never bodies. A vector index is, functionally, a searchable copy of content. Either the guardrail acquires a carefully bounded exception with its own controls, or embeddings live somewhere with a different classification and different handling. That is a program-level decision about the program's central privacy claim, not an implementation detail.

2. **Provenance granularity changes.** The Answer Trace Envelope pins evidence as `(entity, recordHash, asOf)`. Chunk-level evidence needs document identity, chunk identity, chunk hash, and the extraction and embedding versions that produced it — because a re-chunked or re-embedded corpus yields different evidence for the same document. That is an ATE revision with real thought behind it.

3. **Tenant isolation becomes harder.** Row-level security on a relational table is a well-understood, testable control. Tenant isolation inside a vector index is a different problem with a different failure mode, and a chunk that leaks does so as readable text rather than as a row. For a multi-tenant lender this is the highest-risk element of the whole idea.

## 4. How To State It In Review

Lead with the boundary rather than defending it after the question:

> Fiskroad governs structured business context. Unstructured retrieval is deliberately out of scope for the MVP, because our governance guarantees derive from validated semantic records and we have not yet designed the equivalent contract for document chunks. We know what it would take: chunk-level provenance in the trace envelope, a reasoned exception to our no-content rule for the vector index, and tenant isolation inside that index. We would rather state the boundary than claim coverage we cannot govern.

That answer is stronger than a partial implementation would be, and it is the correct answer for a regulated institution.

## 5. POC F, If Chartered

Should unstructured retrieval prove genuinely necessary, it is a **new component** and a separate charter — not an extension of hometown. Charter shape:

- Ingestion and extraction with recorded versions.
- Chunking and embedding strategy, both versioned, since both change evidence.
- A vector store with tenant isolation designed and independently tested from the outset.
- ATE extension for chunk-level provenance.
- A resolved position on the no-content guardrail, approved at program level.
- Groundedness scoring extended to chunk evidence (interacts with the evaluation harness).

Sequencing: POC F depends on POC A (provenance) and the tenant isolation work being complete, and should not precede POC B. It is not a candidate for pre-review work under any circumstances.

## 6. Requirements

| REQ | Requirement | TC | Test criteria | Method |
|---|---|---|---|---|
| REQ-SCOPE-01 | The unstructured boundary is stated in program documentation, not discovered | TC-SCOPE-01 | This position appears in the portfolio analysis, the orientation material, and the review deck | AUDIT |
| REQ-SCOPE-02 | No component ingests unstructured content without a chartered POC F | TC-SCOPE-02 | Architecture review finds no vector store, embedding pipeline, or document ingestion path in any Fiskroad repository | AUDIT |

## 7. Open Decision

Whether any MVP feature genuinely requires unstructured context. Ask each application owner directly and record the answers. If all three say no, this scope limit is not a limitation at all and should be presented with confidence. If one says yes, that is a chartering decision for the CTO — made deliberately, with the three conflicts above understood, rather than absorbed into a sprint.
