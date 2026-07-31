# Fiskroad Program Roadmap: Requirements, Objectives, And Test Criteria

Version: 0.1
Status: Draft for CTO review and team execution
Audience: CTO, project leads, engineers, summer interns, sister-organization reviewers
Primary post-read action: use this as the traceability surface — every requirement has an owner, a stage, and a way to prove it is met. Project roadmaps say *how*; this says *what must be true and how we will know*.

Companion documents: hometown ROADMAP (Stages 0–5), popeye ROADMAP (Stages 1–4), Popeye Stage 1 Kickoff (execution mechanics), AI Usage Governance Roadmap v0.2 (architecture and SLOs), Ecosystem Portfolio and Gap Analysis (POC charters).

## 1. How To Read This Document

Three ID families, cross-referenced throughout:

- **OBJ-n** — program objectives. Why the work exists. Stable.
- **REQ-<area>-nn** — requirements. What must be true. Each maps to one or more objectives and has an owning project and a target stage.
- **TC-<area>-nn** — test criteria. How we prove it. Each maps to one requirement and names a verification method.

Verification methods:

| Method | Meaning |
|---|---|
| DEMO | Observed live or captured in a recorded demo run |
| MEAS | A measured number recorded in a baseline or SLO report |
| CI | Automated check in a repository validation gate |
| RUNBOOK | Rehearsed operational procedure with a written outcome |
| AUDIT | Inspection of configuration, grants, or history |

Status values: `not started`, `in progress`, `met`, `deferred`. Rows default to `not started`; see the stage view in section 4 for what has actually moved. As of 2026-07-28 the popeye Azure region is applied, so several P-S2 infrastructure preconditions are met while every measurement-based criterion remains open.

**Intern-executable** rows are marked `[I]`. These are real deliverables with real consumers, not exercises.

## 2. Program Objectives

| ID | Objective | Success looks like |
|---|---|---|
| OBJ-1 | **Visibility** — know what AI costs, by whom, on what | Any division's AI spend by app, user, model, and cloud is a governed query, not a spreadsheet exercise |
| OBJ-2 | **Control** — budgets that actually stop things | A runaway agent or misconfigured app is capped by the platform, not discovered on an invoice |
| OBJ-3 | **Coverage** — no ungoverned path | Server-side and desktop AI both flow through the governed path, and departures from it are detected |
| OBJ-4 | **Reliability** — governance does not become the outage | AI capability survives provider failures and component failures with measured, bounded degradation |
| OBJ-5 | **Trust** — answers traceable to governed evidence | Any AI answer can be shown with the evidence, policy, and cost behind it |
| OBJ-6 | **Portability** — open and composable, no lock-in | The stack runs from clean clones on open components; a sister organization can adopt it without licensing anything |

## 3. Requirements And Test Criteria

### 3.1 Cost Attribution And Reporting (OBJ-1)

| REQ | Requirement | Owner | Stage | TC | Test criteria | Method |
|---|---|---|---|---|---|---|
| REQ-COST-01 | Every AI request is attributed to an application and an identity | popeye | P-S1 | TC-COST-01 | Ledger rows carry `app_id` and `user_id` for 99%+ of requests in the POC window; misses trace to a key-issuance defect, not a code path | MEAS |
| REQ-COST-02 | Attribution supports tenant and feature granularity | popeye + apps | P-S1 | TC-COST-02 | A query filters spend by `tenant_id` and by `feature_tag` and returns non-empty, correct results | DEMO |
| REQ-COST-03 | Spend is queryable through the governed semantic layer, not a bespoke dashboard | hometown | H-S1 | TC-COST-03 | `ai_token_usage` passes the Cube model validation gate and answers spend by app, user, model, and cloud in one query `[I]` | CI + DEMO |
| REQ-COST-04 | Cloud attribution distinguishes AWS from Azure spend | popeye + hometown | P-S1 | TC-COST-04 | The `cloud` dimension returns correct splits across both pilot backends | DEMO |
| REQ-COST-05 | Reported spend is reconcilable against provider billing | popeye | P-S2 | TC-COST-05 | Monthly ledger total vs. cloud cost-allocation-tag total agree within an agreed tolerance; divergence raises a notify alert | MEAS |
| REQ-COST-06 | Ledger completeness is verified, not assumed | popeye | P-S1 | TC-COST-06 | Hourly gateway request count vs. ledger row count reconciliation runs and reports zero unexplained divergence `[I]` | CI + MEAS |

### 3.2 Enforcement And Governance (OBJ-2)

| REQ | Requirement | Owner | Stage | TC | Test criteria | Method |
|---|---|---|---|---|---|---|
| REQ-GOV-01 | Budgets are enforced by the platform, not by application code | popeye | P-S1 | TC-GOV-01 | A key at its cap receives a 429 and the request does not reach the provider | DEMO |
| REQ-GOV-02 | Budget rejection is distinguishable from provider throttling | popeye | P-S1 | TC-GOV-02 | Captured response bodies for both cases show distinct error classes; which budget and its reset time are present in the budget case | DEMO |
| REQ-GOV-03 | Overspend is bounded and measured, not assumed zero | popeye | P-S1 | TC-GOV-03 | Under 20 concurrent requests against a near-exhausted budget, over-cap successes are counted and the bound recorded; MVP target under 5% of budget or a fixed floor `[I]` | MEAS |
| REQ-GOV-04 | Applications hold no raw provider credentials | all apps | P-S2 | TC-GOV-04 | Inspection of every onboarded app's config, secret store, and CI variables finds no provider keys; removal is each app's onboarding exit criterion | AUDIT |
| REQ-GOV-05 | Model access is allowlisted per application | popeye | P-S2 | TC-GOV-05 | A key requesting a non-allowlisted model receives a policy rejection with a distinct error class | DEMO |
| REQ-GOV-06 | Key revocation takes effect promptly across all replicas | popeye | P-S2 | TC-GOV-06 | Revoked key fails on all replicas within 60 seconds of the admin action | MEAS |
| REQ-GOV-07 | Administrative actions are audited | popeye | P-S2 | TC-GOV-07 | Key issuance, budget changes, and config changes appear in a retained audit log with actor and timestamp | AUDIT |

### 3.3 Endpoint And Path Coverage (OBJ-3)

| REQ | Requirement | Owner | Stage | TC | Test criteria | Method |
|---|---|---|---|---|---|---|
| REQ-EP-01 | Desktop agents route through the governed gateway | popeye + nono | P-S1 | TC-EP-01 | A workstation agent configured by base-URL produces attributed ledger rows under a per-user key | DEMO |
| REQ-EP-02 | Traffic bypassing the gateway is detected | nono | P-S1 | TC-EP-02 | One direct-to-provider connection from an agent process is detected and reported (stand-in detection acceptable per descope rules) | DEMO |
| REQ-EP-03 | Desktop identity maps to enterprise identity | popeye | P-S3 | TC-EP-03 | Per-user keys resolve to Entra identities; a leaver's key is revoked by automation | DEMO |
| REQ-EP-04 | Bypass detection reaches the alerting fabric promptly | nono + popeye | P-S3 | TC-EP-04 | Detection-to-alert latency under 5 minutes; coverage percentage of managed endpoints reported | MEAS |
| REQ-EP-05 | Server-side egress cannot silently bypass the gateway | popeye | P-S3 | TC-EP-05 | After egress hardening, a direct provider call from an application subnet fails; break-glass path remains available | DEMO |

### 3.4 Reliability And Operations (OBJ-4)

| REQ | Requirement | Owner | Stage | TC | Test criteria | Method |
|---|---|---|---|---|---|---|
| REQ-REL-01 | The gateway adds acceptable latency | popeye | P-S1 | TC-REL-01 | Paired-run difference distribution reported at p50/p95/p99, plus streaming time-to-first-token delta; provisional target p95 under 150 ms `[I]` | MEAS |
| REQ-REL-02 | Provider failure is absorbed, not passed through | popeye | P-S1 | TC-REL-02 | With the primary backend made unreachable, requests succeed via fallback; recovery is automatic on restoration | DEMO |
| REQ-REL-03 | Reporting and provenance never block a request | popeye + hometown | P-S1 | TC-REL-03 | With the ledger store stopped for 60 seconds under load, requests continue; loss is quantified by reconciliation after recovery | DEMO + MEAS |
| REQ-REL-04 | Ledger freshness supports reporting use | popeye | P-S1 | TC-REL-04 | Request-completion to Cube-queryable measured at p95; MVP target under 15 minutes across consolidation `[I]` | MEAS |
| REQ-REL-05 | The gateway runs as stateless replicas with no per-request local state | popeye | P-S2 | TC-REL-05 | Replica count changes and rolling upgrades occur without request loss; validation forbids fewer than 2 replicas | CI + DEMO |
| REQ-REL-06 | Availability is committed and alarmed | popeye | P-S2 | TC-REL-06 | SLOs committed from Stage 1 baselines; burn-rate alerts fire in a controlled test | MEAS + RUNBOOK |
| REQ-REL-07 | A gateway outage has a rehearsed response | popeye | P-S2 | TC-REL-07 | Break-glass game day completed: dual approval exercised, time-box enforced, credentials destroyed, post-review filed | RUNBOOK |
| REQ-REL-08 | Incident procedures exist for the six named failure classes | popeye | P-S2 | TC-REL-08 | Six runbooks written and each rehearsed at least once | RUNBOOK |

### 3.5 Provenance And Semantic Trust (OBJ-5)

| REQ | Requirement | Owner | Stage | TC | Test criteria | Method |
|---|---|---|---|---|---|---|
| REQ-PROV-01 | Business context is validated before reaching a prompt | hometown | H-S0 | TC-PROV-01 | Contract validation gate rejects malformed semantic records in CI | CI |
| REQ-PROV-02 | Every AI answer records the evidence used | hometown | H-S4 | TC-PROV-02 | A GraphRAG answer produces a validated trace with at least one evidence record and a resolvable ledger join | DEMO + CI |
| REQ-PROV-03 | Traces carry no prompt or completion content | hometown | H-S4 | TC-PROV-03 | Inspection of trace rows shows references and hashes only; policy-gated fields absent where not permitted | AUDIT |
| REQ-PROV-04 | Ungrounded answers are visible | hometown | H-S4 | TC-PROV-04 | The `ungrounded_answers` measure returns correct counts against seeded traces including one zero-evidence case `[I]` | CI |
| REQ-PROV-05 | Traces are immutable | hometown | H-S4 | TC-PROV-05 | Writer role holds INSERT only; an UPDATE attempt is refused by the database | AUDIT |
| REQ-PROV-06 | Provenance is forward-compatible with access control and federation | hometown | H-S4 | TC-PROV-06 | Empty `policy` and `signature` blocks round-trip through validation | CI |
| REQ-PROV-07 | Semantic access is authorized per identity | hometown | H-S5 | TC-PROV-07 | The same question from two differently-entitled identities returns correctly different evidence sets, both visible in traces | DEMO |
| REQ-PROV-08 | Denials are audited, not silent | hometown | H-S5 | TC-PROV-08 | A denied context request produces an audited denial record, not an empty result | DEMO + AUDIT |
| REQ-PROV-09 | Answer quality is measurable, and measurable against cost | hometown | POC C | TC-PROV-09 | Golden-question runs produce groundedness scores joined to per-answer cost | MEAS |

### 3.6 Openness And Portability (OBJ-6)

| REQ | Requirement | Owner | Stage | TC | Test criteria | Method |
|---|---|---|---|---|---|---|
| REQ-OPEN-01 | All governed models and contracts are source-controlled artifacts | hometown | H-S1 | TC-OPEN-01 | Semantic models, trace schema, and gateway config are files in git, validated in CI | CI |
| REQ-OPEN-02 | Infrastructure is reproducible from source | popeye | P-S2 | TC-OPEN-02 | `terraform plan` from a clean clone produces the reviewed expected plan; image versions pinned, `latest` rejected by validation — *provider lock committed and region applied 2026-07-28; clean-clone replay not yet re-verified* | CI + AUDIT |
| REQ-OPEN-03 | Every commercial component has a documented open fallback | program | P-S2 | TC-OPEN-03 | Each purchase ADR names its OSS alternative; a reference deployment runs with no paid subscription | AUDIT |
| REQ-OPEN-04 | A sister organization can stand up the stack from a clean clone | program | POC E prep | TC-OPEN-04 | Clean-clone-to-running in under one day with synthetic seed data on the receiving org's own subscription `[I]` | DEMO |
| REQ-OPEN-05 | No credentials or real data in shared history | program | POC E prep | TC-OPEN-05 | History scan finds no credentials, tenant identifiers, or production data in any shareable repository | AUDIT |
| REQ-OPEN-06 | Context can be exchanged across organizations without a shared platform | zt-infra + hometown | POC E | TC-OPEN-06 | A signed semantic record produced by one org is validated and used by another, with cross-org origin recorded in provenance | DEMO |

## 4. Stage Execution View

Stage prefixes: **P-Sn** = popeye stage n; **H-Sn** = hometown stage n.

### P-S1 — Control-Plane POC (two weeks; CTO demo day 10)

Objectives served: OBJ-1, OBJ-2, OBJ-3, OBJ-4.

Requirements in scope: REQ-COST-01/02/03/04/06, REQ-GOV-01/02/03, REQ-EP-01/02, REQ-REL-01/02/03/04.

Must-hold exit criteria (the demo is these four):

1. TC-GOV-01 — a budget cap produces a clean 429.
2. TC-COST-03 — chargeback query answered through Cube.
3. TC-REL-01 — one measured latency baseline.
4. TC-COST-01 — attribution end to end, app and user visible.

May slip with a stand-in: TC-EP-02. May slip entirely: the second cloud backend (TC-COST-04 degrades to single-provider, stated honestly). Kill criterion: no reachable model endpoint by day 5.

Deliverable of record: `STAGE1_BASELINES.md` — TC-REL-01, TC-REL-04, TC-GOV-03, TC-COST-06 numbers, each with the sentence "therefore the provisional SLO of X is / is not achievable as written."

Intern-executable in this stage: TC-REL-01, TC-REL-04, TC-GOV-03, TC-COST-06 measurement runs and the baseline document; TC-COST-03 Cube queries and first cost dashboard; synthetic seed data for all of it.

### P-S2 — First Managed Region (Azure)

Objectives: OBJ-2, OBJ-4, OBJ-6. Requirements: REQ-GOV-04/05/06/07, REQ-REL-05/06/07/08, REQ-COST-05, REQ-OPEN-02/03.

Gate to start (status as of 2026-07-28): `name_prefix` renamed to `popeye-` — **met**; state backend settled (Azure Storage remote state) — **met**; ADR-002 decided and implemented — **met**; Stage 1 baselines exist — **not met**.

The region was applied ahead of the baselines. The consequence to track: TC-REL-06 cannot be closed, and the observability alert criteria remain placeholders, until the Stage 1 measurements land. Applying early bought a live target to measure against; it did not remove the measurement.

Exit: region live on pinned releases with rollback, SLOs committed and alarmed, two applications onboarded with zero raw provider keys, six runbooks rehearsed including a break-glass game day, operational owner named.

### H-S1 (extension) — Semantic Reporting

Runs alongside P-S1. Requirements: REQ-COST-03, REQ-OPEN-01, plus the two `verify:gateway:*` verifiers supporting TC-COST-06.

### H-S2 / H-S3 — Intrepid And CRM Slices

Existing hometown work, unchanged. H-S2's tenant-isolation work is the on-ramp to REQ-PROV-07; H-S3's GraphRAG path becomes the first writer for REQ-PROV-02.

### H-S4 — Answer Provenance (POC A)

Objectives: OBJ-5. Requirements: REQ-PROV-02/03/04/05/06.

Exit: all five test criteria met, plus the trace-store outage test (TC-REL-03 applied to the trace path).

### H-S5 — Governed Semantic Access (POC B)

Objectives: OBJ-5. Requirements: REQ-PROV-07/08. Runs alongside P-S2 (shared Entra identity work).

### P-S3 — Second Region, Reporting, Fleet

Objectives: OBJ-1, OBJ-3, OBJ-4. Requirements: REQ-EP-03/04/05, REQ-REL-04 across consolidation, REQ-COST-05 on both clouds.

### P-S4 / POC C / POC E

P-S4 operationalizes OBJ-1 (showback, spend-velocity alerts, reconciliation automation). POC C adds REQ-PROV-09. POC E adds REQ-OPEN-04/05/06.

## 5. Coverage Notes And Honest Gaps

- **Provisional targets are provisional.** Every numeric target in section 3 marked "provisional" is a proposal until the Stage 1 baseline document confirms or revises it. Committing SLOs before measuring them is how platform teams lose credibility in month one.
- **REQ-GOV-03 accepts non-zero overspend by design.** Budget counters are eventually consistent; the requirement is a measured bound, not zero. Anyone reading this as a weakness should read the consistency-model section of the governance roadmap first.
- **REQ-EP-05 has a sequencing hazard.** Egress hardening converts a gateway outage from degraded to hard-down for anything not on the break-glass list. TC-REL-07 must be met before TC-EP-05 is attempted.
- **REQ-PROV-09 has no owner yet.** The evaluation harness placement is undecided; the requirement is recorded so it is not lost.
- **Nothing here tests answer correctness before POC C.** Until then the program proves that AI is governed, attributed, and reliable — not that it is right. Say so plainly in any external presentation.
- **No requirement covers user-facing UX.** Deliberate: the program competes on the governance loop, not on polish, and pretending otherwise forfeits credibility.

## 6. Change Control

Requirements and test criteria change by pull request against this file, reviewed by the owning project lead. A requirement touching a cross-project invariant (see program STATE.md) is reviewed in both affected repositories. Test criteria may be tightened from measured baselines at any time; loosening one requires a recorded rationale.
