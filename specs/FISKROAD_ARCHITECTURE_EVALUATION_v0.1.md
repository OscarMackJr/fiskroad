# Fiskroad Architecture Evaluation: Pre-Review Assessment

Version: 0.1
Status: Draft for internal review before the partner design review
Audience: CTO, project leads, enterprise architects
Primary post-read action: decide which of the five critical items to fix, which to explicitly scope out, and which to concede — before the review, not during it.

This document is deliberately adversarial. It assumes the reviewing engineers are fluent in Foundry/AIP and will probe where the architecture is thinnest. Strengths are covered last and briefly, because they are not what needs work.

## 1. How This Review Will Actually Go

Palantir-fluent reviewers rarely attack the gateway or the cost layer — those are the parts of Foundry customers ignore. They will probe three things:

1. **The ontology.** "Show me a customer, joined across CRM, the ledger, and Intrepid." This is Foundry's core and the question is asked within the first twenty minutes.
2. **Access control.** "Who can see what, and what enforces it?" Purpose-based access is their deepest moat.
3. **Where the data actually is.** Foundry materializes; Fiskroad federates. They will want to know what that costs at query time and what it does to source systems.

Fiskroad has excellent answers on cost governance, endpoint coverage, and provenance — capabilities Foundry treats as implicit. It has weak or missing answers on all three questions above. That asymmetry is the whole risk of this review.

## 2. Critical Gaps

### C1. There is no entity resolution, and therefore no cross-domain ontology

**The problem.** hometown is presented as the semantic/ontology layer, but Cube provides governed dimensions and measures *per data source*. It does not resolve identity across sources. The roadmap's own open decision — "canonical enterprise customer identity across CRM, ledger, and Intrepid" — is a single bullet that in fact gates Stage 6 entirely. Without an identity spine, "cross-domain GraphRAG" has no defined join.

A related naming exposure: the project is the Enterprise Knowledge Graph and the retrieval pattern is called GraphRAG, but there is no graph. `SemanticRecordSchema` carries a `relationships` array, and nothing traverses it. There is no link store, no traversal engine, no multi-hop query. A reviewer will notice within minutes, and the credibility cost of an unearned name is larger than the gap itself.

**Recommendation — pick one and write it down:**

- **Option A (recommended): charter an identity spine as a first-class component.** A `party_identity` mapping — source system, source key, resolved entity id, match method, confidence, effective dates — maintained as governed data with explicit, auditable match rules. Start deterministic (tax ID, normalized name plus address, existing CRM-to-loan foreign keys). Probabilistic matching can come later; what matters at review is that identity is *modelled and auditable*, not inferred at query time.
- **Option B: scope explicitly to single-domain retrieval for the MVP** and state that cross-domain joins are deferred pending an identity decision. This is a perfectly respectable answer *if stated first*. It becomes a weakness only when discovered by the reviewer.

Either way, rename the retrieval pattern honestly. If relationships are single-hop lookups over governed relational context, call it governed context retrieval. Reserve "graph" for when there is traversal — and if traversal is genuinely wanted, evaluate Apache AGE or recursive CTEs on the existing Postgres before adopting a graph database.

### C2. The regulated-data posture is undocumented — and this is a lender

**The problem.** Intrepid is a loan engine. Customer financial context is being assembled into prompts and sent to third-party model providers. Nowhere in the specification set is there a statement of: which models are approved for regulated context, what the providers' data-handling and no-training commitments are, how consumer financial data in prompts is treated under GLBA and applicable state lending law, or what the retention posture is on the provider side.

The no-content guardrail on the ledger and trace store is excellent and will be praised — but it governs *our* stores, not what leaves the building in a prompt. A partner CTO at a financial institution will find this gap immediately, and it is the one gap that can stop a program rather than merely embarrass it.

**Recommendation.** Before the review, produce a short data-handling control document covering: an approved-model list for regulated context (both Bedrock and Foundry offer enterprise no-training and residency commitments — cite the specific contractual terms, not the marketing page); a prompt-content classification policy per feature tag, enforced at the gateway; the DPA/contractual position with each provider; and the retention position. Popeye is the natural enforcement point — model allowlists per key already exist, so "regulated feature tags may only use approved-for-regulated models" is a configuration of a control you have already built. That is a strong answer. Having no answer is not.

### C3. Tenant isolation rests on a single layer

**The problem.** Tenant filtering is enforced in Cube security contexts. That is standard and correct, but it is one layer: a misconfigured security context, a model added without the tenant filter, or a developer testing with an over-broad JWT produces cross-tenant disclosure with nothing behind it. For a multi-tenant loan platform this is the highest-severity failure mode in the system, and Foundry's answer — mandatory, object-level access control independent of the query layer — is materially stronger.

**Recommendation.** Add defense in depth *before* POC B rather than after: enforce tenant isolation at the database layer as well, using Postgres row-level security with a session variable set from the connection context, so the semantic layer and the database independently enforce the same rule. Then add a CI verifier that runs the same query under two tenants and asserts disjoint results — you already have `verify:intrepid:tenant-safety`, so extend that pattern to assert failure, not just success. Two independent enforcement layers and a test that proves it is a defensible answer to the strongest question they will ask.

### C4. The reliability model covers the gateway path but not the semantic path

**The problem.** The governance roadmap's reliability design is genuinely strong — failure domains, bounded overspend, fallbacks, break-glass, observation-never-blocks. All of it describes the *gateway*. But GraphRAG's context retrieval runs through Cube and the divisional source systems, and those are in the synchronous request path too. There is no stated behaviour for: Cube unavailable, a divisional source system unavailable or slow, or partial context (two of three sources answered).

"Observation never blocks" covers traces. Nothing covers retrieval. A reviewer who has read the reliability section will ask what happens when the CRM is down, and "the AI answers with no context" versus "the AI refuses" versus "the AI answers with partial context and says so" are three very different products.

**Recommendation.** Extend the reliability model to the semantic path with an explicit degradation policy per feature tag: fail closed (refuse to answer without governed context — correct for regulated advice), or degrade with disclosure (answer with partial context, record the gap in the trace). The ATE already has the right shape to record this — an evidence array that is empty or partial is a queryable fact, and you already surface `ungrounded_answers`. Make partial-context a first-class recorded state rather than an accident.

### C5. Virtualization-first has an unpriced cost: production source-system load

**The problem.** The founding principle — no warehouse, query sources live — is a real differentiator and I would not abandon it. But it means AI context retrieval issues queries against production operational systems, at whatever volume AI usage reaches. The latency target for CRM context lookup is still an open decision. Pre-aggregations are mentioned and deferred. There is no stated source-system load budget and no agreement with the divisional owners who operate those databases.

Two risks: the review exposes it as unanalyzed, and — more seriously — divisional DBAs discover AI traffic on their OLTP systems and revoke access. That kills the program faster than any architecture criticism.

**Recommendation.** Before the review, define a three-tier retrieval policy per entity type: live query (low-volume, high-freshness lookups), Cube pre-aggregation with a stated freshness bound (the common case), and cached/materialized context for hot paths. Then state a source-system load budget and get divisional sign-off. This converts your weakest operational assumption into a designed control, and it is a stronger position than Foundry's — because you can state, per entity, exactly how fresh the context is, where Foundry's answer is "whenever the pipeline last ran."

## 3. Significant Gaps — Address Or Explicitly Concede

**S1. No unstructured retrieval.** There is no vector search, no document or note ingestion, no chunking or embedding strategy anywhere in the design. Real enterprise AI questions frequently concern notes, contracts, correspondence, and policy documents. Foundry handles both structured and unstructured. Recommendation: state the scope limit explicitly ("Fiskroad governs structured business context; unstructured retrieval is out of scope for the MVP") rather than being discovered without one. If unstructured is genuinely needed, it is a new component and should be chartered as POC F, not smuggled into hometown.

**S2. Evaluation arrives too late.** POC C is third in the ordering, meaning provenance and authorization land before any correctness signal exists. Meanwhile the gateway makes model swapping easy, and swapping models without evals is how quality silently degrades. Recommendation: pull a minimal harness forward — twenty golden questions per domain and a groundedness check against ATE evidence is a week of work and converts "we govern AI" into "we govern AI and can prove it stayed correct." Full harness stays at POC C.

**S3. There is no surface for the provenance demo.** The single most differentiating demo — click an answer, see its evidence, its policy, and its price — currently has no place to happen. Cube's playground is not a demo surface. Recommendation: a small read-only trace viewer, perhaps a day of work, with far more review value than its cost. This is the one place I would break the deliberate no-UI stance.

**S4. hometown's secret management lags popeye's.** Popeye uses Key Vault with managed identity and no long-lived credentials. hometown holds divisional source credentials in `cube/.env`, with production secret management deferred to Stage 6. The pattern is already solved next door; adopt it now rather than at MVP.

**S5. Computed cost will drift from billed cost.** Gateway-computed spend uses provider price maps, which lag price changes, and it does not model committed-throughput, batch, or caching discounts. The monthly bill-versus-ledger reconciliation catches this, which is the right control — just state the caveat before someone finds a variance and assumes the whole ledger is unreliable.

**S6. No prompt registry.** The ATE requires `templateId` and `templateVersion`, which is a good forcing function, but nothing yet stores or governs those templates. Name it as a deferred component rather than leaving it implied.

## 4. Recommended Additions, Ranked

1. **Identity spine** (C1) — the only genuinely new architectural component recommended here. Charter it or scope it out; do not leave it as a bullet.
2. **Regulated-data control document** (C2) — no new component, but the highest-stakes missing artifact.
3. **Database-layer tenant isolation** (C3) — small change, defense in depth on the highest-severity failure mode.
4. **Semantic-path degradation policy** (C4) — specification work, no new component.
5. **Retrieval tiering and source-load budget** (C5) — design decision plus divisional sign-off.
6. **Trace viewer** (S3) and **minimal eval harness** (S2) — small builds, disproportionate review value.

## 5. What To Concede Confidently

Do not attempt parity on: integrated tooling and UX, breadth of connectors, pipeline lineage, mature ontology tooling, or forward-deployed support. Say so first and price the concession honestly. Reviewers respect a team that knows its own boundaries and distrusts one that claims parity everywhere.

Equally, do not undersell what is genuinely strong and unusual: the cost-governance and attribution layer is more explicit than Foundry's; endpoint coverage via nono addresses a problem Foundry does not attempt; the Answer Trace Envelope with cost joined per answer enables statements Foundry's pricing model makes awkward; the boundary discipline between components is unusually rigorous for a program this young; and federation over zt-infra is a genuinely different answer to multi-organization collaboration than shared platform tenancy.

## 6. Rehearsal Questions

Have an answer ready, in one paragraph each, for:

1. Show me a customer joined across all three systems.
2. What stops tenant A seeing tenant B's loan data, and what proves it?
3. Which model sees consumer financial data, and under what contractual terms?
4. What happens to an AI answer when the CRM is down?
5. What load does AI context retrieval put on the production loan engine?
6. How do you know an answer was correct, not merely governed?
7. Where does this stack lock us in?

Questions 1 through 5 are the critical gaps above. Question 6 is S2. Question 7 is the one you win outright — make sure someone gets to answer it.
