# Fiskroad Program State

Status: Active
Last updated: 2026-08-02
Audience: program maintainers, project leads, future implementation agents
Primary post-read action: know the program's current position and which project repository holds the next engineering task.

Fiskroad tracks the program. Engineering state lives in each project's
own STATE.md; this file never duplicates it.

## Current Position

The program has running infrastructure and owes measurement. Popeye's
first managed Azure region is applied and live; the Stage 1 baselines
that convert provisional SLOs into committed numbers are still
outstanding, and remain the gate for committing SLOs, replacing
placeholder alert thresholds, and chartering POC A.

Project positions in one line each:

- **popeye**: Stage 2 (azure-eastus2) APPLIED and live — remote state in
  Azure Storage, Container App healthy on two replicas, Foundry backend
  configured via ADR-002, gateway identity holding Foundry RBAC. Stage 1
  measurement work and the smoke-completion/ledger-row proof are the
  open items.
- **hometown**: Stage 2 (Intrepid non-production slice) is the active
  engineering slice; the Stage 1 extension (`ai_token_usage` model and
  the two gateway verifiers) is now unblocked by a live ledger and is
  the near-term dependency for the chargeback demo.
- **bluto**: chartered 2026-07-30 in response to architecture-evaluation
  gap C1; specification drafted, no code. v1 deterministic slice is
  pre-review work.
- **nono**: no Fiskroad-driven work in flight; the bypass-detection
  policy profile is requested for Popeye Stage 1 (flag mode).
- **zt-infra**: no Fiskroad-driven work in flight; three extensions
  (agent identity, signed-payload transport, org key management) are the
  gating dependency for POC E.

## Program Decisions Made

- Umbrella program identity: Fiskroad. Member repositories are named by
  codename alone: `hometown`, `popeye`, `nono`, `zt-infra-full`.
- Coordination repository, not a monorepo (rationale in README).
- Control plane over per-application metering (popeye's founding
  decision).
- Regional gateway per cloud; Azure leads Phases 1 and 2.
- POC ordering: A (provenance), B (governed access), C (evaluation),
  D (governed actions), E (federation, design spec now).
- No new components required for the current push; four future
  components registered with triggers.
- Commercial posture: buy undifferentiated operations, never buy the
  differentiator, keep every commercial piece swappable.
- Fifth member project chartered: bluto (identity spine), in response to
  the pre-review architecture evaluation. Identity is resolved ahead of
  time and recorded, never inferred at query time.
- Unstructured retrieval is explicitly out of scope for the MVP; if
  required it is a new component (POC F), not an extension of hometown.
- Document conventions: chartered projects use `specs/ROADMAP.md` and
  `specs/STATE.md`; pre-existing members retain their native layouts,
  and `.repos.yml` records each project's roadmap and state paths.
- v0.3 correction set: shared vocabulary ratified; `tenant_id` is a
  lowercase canonical UUID; the five-class taxonomy is unified; and
  `regulated-identifier` is structurally unapprovable.
- Cross-repository findings X1 and X2 are closed at the program level;
  downstream conformance remains pending in popeye and hometown.
- ADR-002 (popeye): gateway config is Terraform-rendered non-secret YAML
  delivered as a Container Apps secret and written to disk at startup —
  chosen over a config-baked image to get auditable revision rollback
  without an image pipeline. Consequence recorded: the rendered YAML
  lands in Terraform state, acceptable only because it carries routing
  metadata and no credentials.

## Program Decisions Open

- Charter order confirmation for POCs A–E (recommendation: A, B, C, D,
  E-spec).
- License posture for hometown and popeye when shared externally.
- Whether sister-organization sharing is code-only or includes a
  federated pilot (pulls POC E forward).
- Operational ownership and on-call for the control plane — needed
  before Popeye Stage 2 exit.
- Break-glass approver names.

## Cross-Project Invariants

These hold across every repository and are the reason Fiskroad exists:

1. **One join key.** popeye's `request_id` links the spend ledger to
   hometown's Answer Trace Envelope. Ledger facts are joined, never
   copied.
2. **One attribution vocabulary.** `app_id`, `user_id`, `tenant_id`,
   `feature_tag` mean the same thing in every project. Changing them is
   a two-team contract change, never a quiet edit.
3. **Semantics stay out of the gateway.** popeye knows what requests
   cost, never what evidence means.
4. **Observation never blocks.** Reporting, provenance, and monitoring
   components must not be able to fail a request.
5. **No content in governed stores.** No prompt or completion bodies in
   the ledger or the trace store; references and hashes only.

Any change touching more than one of these needs review in both affected
repositories before it lands in either.

## Invariant Exceptions On Record

**Invariant 4, agent answers only** — ratified 2026-10-20 by Oscar Mack
(architecture and risk decisions). Recorded in full in hometown
`specs/HOMETOWN_v0.4.md` §2.5 (hometown PR #17).

For an answer whose `policy.principalType` is `agent`, hometown saves
the trace before the answer or its trace ID is returned. If the save
fails, the answer is withheld. The reason: an agent must never hold a
`trace_ref` that does not resolve. Otherwise olive cannot verify agent
proposals against hometown's trace resolution endpoint.

The exception covers nothing else. User and application answers keep
non-blocking trace writes, and the ledger, monitoring and every other
observation component remain bound by invariant 4 (hometown
REQ/TC-PROV-26 guards the boundary). Widening the scope needs a new
ratification recorded here.

## Sequence Deviation On Record

The plan of record gated Popeye Stage 2's apply on the Stage 1 baseline
document. In practice the Azure region was applied first. This is
recorded rather than smoothed over, because two consequences are still
live: the committed SLOs and the observability alert thresholds remain
placeholders until baselines exist, and the measurement protocol now has
to run against (or alongside) live infrastructure rather than the
isolated local profile it was written for. Neither is a defect; both are
work that is still owed.

## Next Program Milestone

Smoke completion through the live gateway producing one attributed
ledger row, then the Stage 1 measurement runs and
`specs/STAGE1_BASELINES.md`. That document remains the gate for
committing SLOs, replacing placeholder alert criteria, and chartering
POC A.
