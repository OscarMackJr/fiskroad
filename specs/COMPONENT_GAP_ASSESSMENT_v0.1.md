# Component Gap Assessment: What The Roadmaps Require Beyond Existing Projects

Version: 0.1
Status: Draft decision record
Audience: CTO, hometown team, popeye team, nono and zt-infra maintainers
Primary post-read action: confirm the "no new components for the current push" finding, and register the four future components and two watch items so they arrive by decision rather than by surprise.
Companion documents: hometown ROADMAP (Stages 0-5), popeye ROADMAP (Stages 1-4), ecosystem portfolio and gap analysis (POCs A-E).

## 1. Finding

The aggressive near-term push — hometown Stages 1-5 and popeye Stages 1-4, covering provenance (POC A), authorization (POC B), and evaluation (POC C) — requires **no new components**. Every task on that path is an extension of the four existing projects (hometown, popeye, nono, zt-infra) plus already-committed off-the-shelf pieces (LiteLLM, Cube, Postgres, Redis, Tines, Entra/Intune, Teams).

New components appear only at POC D (governed actions) and POC E (federation), plus two conditional items. Each is listed below with its trigger, so the ecosystem grows by decision.

## 2. Gap-By-Gap Component Analysis

- **Provenance (POC A / hometown Stage 4)**: Postgres table, Cube model, writer inside the existing engine. Extension only.
- **Authorization (POC B / hometown Stage 5)**: Cube security contexts driven by Entra JWT claims; denials audited into the trace store. Extension only, with one conditional component (section 3, item C).
- **Evaluation (POC C)**: harness scripts, golden-question datasets, and an eval-results table beside the traces — all hometown artifacts riding the existing verify/CI conventions. If LLM-as-judge scoring is used, judge calls route through the popeye gateway, so evaluation cost is itself metered and attributed. No new service.
- **Governed actions (POC D)**: the first genuinely new component — see section 3, item A.

## 3. Future Components, With Triggers

**A. Action broker (POC D).** Holds pending actions, runs the approval state machine, hands execution to Tines (standing decision: Tines for action hand-off only), receives results, writes provenance via the ATE link. Starts as a hometown extension: an `action_record` contract beside the ATE, an action table, and Teams Adaptive Cards for human approvals (O365-native; no UI build). Trigger to become its own deployable/repo: when it needs independent scaling, its own on-call, or exposure to callers outside hometown's engine — the standing rule that repositories map to deployables, applied forward.

**B. Federation exchange service (POC E).** The signed-envelope exchange endpoint over zt-infra between organizations. Already designated as the first thing in the program that earns a new repository, because it is a genuinely independent deployable with its own trust boundary. Trigger: zt-infra/ZERO_TRUST_V2 demo maturity plus POCs A and B landed, plus a confirmed sister-org pilot.

**C. Policy engine (conditional; OPA or Cedar class).** NOT adopted now. POC B's scope is policies-as-code in the semantic layer (Cube security contexts), which is versionable, testable, and sufficient for tenant and group rules. Trigger for adoption: policies that must be evaluated at runtime by components other than the semantic layer (the action broker's approval rules are the likely first pressure), or a policy count/complexity that makes code review the bottleneck. Deferring this is a decision, recorded here, not an omission.

**D. Shared contracts package.** A small versioned package (npm) exporting SemanticRecordSchema, AnswerTraceSchema, and the future action record, consumable without the hometown engine. Trigger: the earlier of (a) sister-organization sharing beginning (external consumers must not vendor hometown's engine to validate an envelope) or (b) POC E development starting. Includes the canonicalization implementation (JCS / RFC 8785) so hashing and signing are identical everywhere — a correctness requirement, not a convenience.

## 4. nono And zt-infra: Extensions Required, Nothing Replaced

**nono** (three named extensions, all within its existing WFP architecture):

1. Bypass-detection policy profile, flag mode — popeye Stage 1 (already planned; stand-in allowed per kickoff descope rules).
2. Block mode with an exception process — popeye Stage 3, gated on the legal/HR review already listed as an open decision.
3. Detection-event export into the common alerting fabric (sit-cip as the natural consumer) — integration work, not a component.

**zt-infra / ZERO_TRUST_V2** (the POC E gating dependency):

1. Agent identity and mutual authentication at demo maturity.
2. Signed-payload transport suitable for carrying the ATE envelope.
3. Key management for organization signing keys (interacts with the canonicalization decision in item D).

These are charter-consistent extensions; neither project changes shape.

## 5. Watch Items (Align Early, Build Later)

- **Agent identity seam.** Popeye's virtual keys identify agents economically (budgets, attribution); zt-infra identifies them cryptographically (mutual auth, signatures). POC D's action records will want both identities on the same record. No component to build today; the alignment task is agreeing that the popeye `user_id`/key identity and the zt-infra agent identity are mappable, before POC D hardens either vocabulary. Cheap now, expensive to reconcile later.
- **Eval harness placement.** Runs in hometown for POC C; if evaluation becomes a continuous gate on model/prompt changes (likely at MVP), it may want scheduled infrastructure in popeye's deployment estate. Placement decision deferred to POC C exit.

## 6. Summary Table (Prose Form)

Build now: nothing new — extensions only, per the two team roadmaps. Build at POC D: action broker, as a hometown extension first. Build at POC E: federation exchange service (new repo) and the shared contracts package (possibly earlier, on sister-org sharing). Build only on trigger: policy engine. Extend on schedule: nono (three items), zt-infra (three items). Watch: agent identity seam, eval placement.

The ecosystem's discipline to date — contracts before components, triggers before adoption — is the reason this assessment is short. Keep it that way.
