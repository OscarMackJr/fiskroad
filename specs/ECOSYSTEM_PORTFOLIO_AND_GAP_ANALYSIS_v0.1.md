# TWG AI Ecosystem: Portfolio, Gap Analysis, And POC Recommendations

Version: 0.1
Status: Draft for CTO strategy discussion
Audience: CTO, enterprise architects, project owners (hometown, popeye, nono, zt-infra), sister-organization liaisons
Primary post-read action: confirm the gap priorities in section 4, select which of POCs A–E to charter after Popeye Stage 1, and decide the sharing posture in section 6.

## 1. Purpose

Phases 1 and 2 of Popeye are committing to Azure. The CTO intends to share TWG's POCs with sister organizations, and the portfolio will be evaluated against Palantir Foundry/AIP — a high bar, proprietary, and expensive. This document maps the existing ecosystem against that bar, names the functional gaps honestly, recommends the next POCs in priority order, and defines what "shareable" has to mean before anything leaves the building.

## 2. The Ecosystem, In The Evaluator's Vocabulary

An evaluator fluent in Palantir will translate TWG's stack roughly as follows:

- **hometown** (Enterprise Knowledge Graph): the ontology and semantic layer — governed business models over source systems, contract-validated context for AI, GraphRAG feed. Read side.
- **popeye** (AI usage governance control plane): resource governance — budgets, keys, attribution, cost as a queryable domain, reliability posture, break-glass. The FinOps and enforcement layer Palantir mostly handles implicitly inside its platform.
- **nono**: endpoint enforcement — the desktop agent boundary Palantir does not really address, because Palantir assumes work happens inside Palantir.
- **zt-infra / ZERO_TRUST_V2**: secure agent-to-agent transport — peer-to-peer, zero-trust communication between agents. No Palantir equivalent exists as an open primitive; Palantir's answer to inter-party workflows is shared tenancy of Palantir.
- **SIT-CIP** (adjacent): the context-intelligence pattern and the Context Answer Envelope thinking — the in-house precedent for provenance-carrying AI answers.

The composition argument writes itself: divisions keep their systems (hometown's founding principle), spend is governed without touching application code (popeye's founding decision), and the endpoints and transport are secured by dedicated open components. What does not yet write itself is Palantir's strongest property: the closed loop where every answer is traceable, every action is gated, and every access is purpose-scoped.

## 3. What Palantir Actually Sells, Decomposed

Strip the branding and Foundry/AIP is roughly seven capabilities. Status against each:

1. **Semantic ontology over federated data** — COVERED (hometown), with a maturity gap in model tooling and breadth of source connectors.
2. **Granular, purpose-based access control on that ontology** — GAP. hometown's own STATE lists the production authorization model as undecided. This is Palantir's deepest enterprise moat.
3. **Decision provenance: every AI output traceable to governed inputs** — GAP, but unusually cheap to close (section 4, POC A). hometown validates context before prompts; popeye stamps every request; the join is missing.
4. **Governed actions: agents and users acting on systems through approved, audited action types** — GAP. Everything in the current stack is read-side. SIT-CIP's "Tines for action hand-off only" decision is the right skeleton.
5. **AI quality evaluation as a platform feature** — GAP. Popeye measures cost and reliability; nothing measures correctness or groundedness.
6. **Operational polish: integrated UX, pipeline tooling, lineage visualization, support organization** — CONCEDED. Do not compete here in POC form; see section 5.
7. **Multi-organization collaboration** — Palantir's model is shared platform tenancy. TWG's model can be federation over zt-infra, which is not a gap to close but an advantage to build (POC E).

## 4. Recommended POCs, In Priority Order

### POC A: Decision Provenance — "Show Your Work" (charter first)

Every AI answer produced through the stack carries a durable trace: the semantic records used (hometown, already validated), the policy path and identity (popeye virtual key and attribution), the model/tokens/cost (popeye ledger, joined on request_id), and the final prompt envelope shape (without sensitive content, per standing guardrails). One trace store, one Cube model over it, one demo: click an answer, see its evidence, its policy, and its price.

- Why first: highest Palantir-differentiating value per unit of effort; both halves already exist; it resolves hometown's open "GraphRAG trace storage" decision; and it generalizes the SIT-CIP Context Answer Envelope into an ecosystem primitive rather than a single-app feature.
- Skeleton: trace record schema (a semantic record about an answer), written by the GraphRAG path at prompt-construction time, keyed by the popeye request_id; `ai_answer_traces` Cube model; retention policy decision.
- Exit demo: for one CRM-style question, the full chain from answer back to tenant-scoped source rows, with cost, in under a minute of clicking.

### POC B: Governed Semantic Access — "Who May Ask What" (charter second)

Entra-group-driven authorization on hometown queries: tenant/row-level security enforced in the semantic layer (Cube security context), purpose tags on queries, denials audited. Closes the stated open decision in hometown's STATE and answers the first question any Palantir-fluent evaluator will ask.

- Skeleton: map Entra groups to Cube security contexts; enforce tenant filters as non-removable policy (hometown guardrail made structural); audit allowed/denied context requests into the same trace store as POC A.
- Honest scope: POC proves the pattern on Intrepid's tenant dimension and one CRM visibility rule; production-grade ABAC across all divisions is MVP work, and the doc should say so.

### POC C: AI Evaluation Harness — "Governed AND Right" (after A)

A golden-question set per onboarded domain, run through the same gateway path, scored for groundedness against the semantic records in the POC A trace (did the answer use the evidence; did it contradict it), with cost-per-correct-answer as a popeye-native metric. Depends on POC A's traces, hence the ordering.

- The differentiating twist available to TWG and not to most: evaluation *joined to cost*. "Model X is 4 points more grounded at 3x the cost per correct answer" is a decision-grade sentence Palantir's pricing makes uncomfortable.

### POC D: Governed Action Layer — The Write Path (after B)

One action type, end to end: an AI-proposed action (e.g., flag a loan exception for review) expressed as a validated action record, gated by an approval rule (auto-approve low-risk, human-approve otherwise), handed off to Tines for execution, resulted back into the trace store. Read-context-decide-act, every step audited.

- Deliberately one action type. Palantir's action framework is years of work; the POC proves the contract shape (action record schema, approval gate, execution hand-off, result provenance), not a workflow engine.
- Ordering rationale: actions without authorization (POC B) is a demo nobody should approve.

### POC E: Cross-Organization Federation Over zt-infra — The Sister-Org Play

Two organizations, two independent stacks, no shared platform: org A's agent requests context from org B; the request travels over zt-infra's zero-trust channel; org B's hometown applies its own POC B authorization and returns a signed semantic record; org A validates the contract and uses it, with provenance (POC A) recording the cross-org origin.

- This is the one capability in the portfolio Palantir structurally cannot match, because its multi-org answer is "both parties license Palantir." Federation over an open transport with contract-validated payloads and local authorization is the offensive story for the sister-organization conversation — the POCs are not just shareable, the architecture is *designed for sharing*.
- Dependency-honest: needs zt-infra/ZERO_TRUST_V2 at demo maturity and POCs A+B landed. Charter the design spec now; build when the dependencies clear.

### Explicitly Not Chartered (and why)

- **Content guardrails / DLP at the gateway** (prompt-injection screening, PII masking): real, but it is a configuration-and-evaluation exercise on popeye's existing hook surface, not a POC-shaped unknown. Fold into Popeye Stage 2 as a work item.
- **A unified UI over the stack**: premature. Cube, the gateway admin UI, and the demo scripts carry Phases 1–2; building a portal now competes with Palantir where Palantir is strongest and TWG is weakest.
- **Pipeline/lineage tooling parity**: hometown's virtualization-first principle deliberately avoids owning pipelines; do not drift into building a Foundry.

## 5. The Palantir Comparison, Played Honestly

Where Palantir wins, and the pitch should concede without flinching: integrated polish, breadth of connectors, mature ontology tooling, embedded forward-deployed support, and a decade of operational hardening. Pretending parity on these forfeits credibility for everything else.

Where TWG wins:

- **Openness and exit cost**: every component is open source or open-standard; the ontology is YAML in git, not a proprietary object store. Leaving Palantir is a migration project; leaving any single TWG component is a module swap (hometown's "replaceable infrastructure" principle, already written).
- **Cost shape**: order-of-magnitude cheaper at POC and pilot scale, and — via popeye — the only stack in the comparison that *shows its own AI cost per answer* as a governed query. Turn cost transparency itself into a feature Palantir's pricing model cannot comfortably demo.
- **Coverage Palantir does not attempt**: desktop agent enforcement (nono) and open zero-trust agent transport (zt-infra). Palantir governs what happens inside Palantir; TWG governs the estate.
- **Federation without platform capture** (POC E): the sister-org model is "run your own, exchange verified context," not "join our tenant."

Framing sentence for the CTO deck: *a composable, open control plane delivering the governance loop enterprises actually buy Palantir for — provenance, authorization, evaluation, governed action — at commodity cost, plus federation and endpoint coverage Palantir does not offer; conceding polish and breadth, and pricing that concession honestly.*

## 6. Shareability: What "Give The POC To A Sister Org" Requires

Sharing is a deliverable class, not a gesture. Before anything ships:

- **Licensing and provenance hygiene**: every repo carries an explicit license (nono and zt-infra already public; hometown and popeye need a decision — recommend permissive for the frameworks, with TWG-specific config excluded); dependency license scan; git history scrubbed of anything that predates the guardrails.
- **Reference deployment**: each shared POC runs from a clean clone with synthetic seed data in under a day, on the receiving org's own Azure subscription. Popeye's scaffold is already close; hometown needs a synthetic-data seed profile (the Intrepid smoke-test pattern, promoted).
- **Secrets posture audit**: one pass confirming the standing guardrails held — no credentials, tenant identifiers, or real data anywhere in history.
- **Support boundary stated in the README**: shared as-is, spec-first, with the specs directory as the contract — not a support obligation. The STATE.md convention travels with each repo; it is genuinely the best onboarding artifact the ecosystem has.
- **Umbrella identity**: the suite needs a name for external conversation (the way "Popeye" named the control plane). One decision, CTO-level, before the first external demo.

## 7. Sequencing Against Current Commitments

- Now: Popeye Stage 1 POC (unchanged; it is the substrate everything above joins to).
- Popeye Stage 2 (Azure, scaffolded): unchanged, plus the guardrails/DLP work item from section 4.
- Charter POC A immediately after Stage 1's demo — it reuses the demo's momentum and the same request_id spine.
- POC B alongside Popeye Stage 2 (both are Azure identity work; same skills, same sprint rhythm).
- POC C after A; POC D after B; POC E design spec now, build on dependency maturity.
- Shareability workstream (section 6) starts when the CTO confirms the sharing intent — licensing decisions have lead time.

## 8. Open Decisions

- Which of POCs A–E to charter, and in what order (recommendation above: A, B, C, D, E-spec).
- License posture for hometown and popeye when shared externally.
- Umbrella name for the suite in external conversations.
- Whether sister-organization sharing is code-only, or includes a federated pilot (which pulls POC E forward).
- Trace-store retention and residency policy (POC A dependency; interacts with the no-prompt-content guardrail).
