# Fiskroad Glossary

The program uses codenames, stage numbers, and POC letters at the same
time. This is the decoder; keep it current.

## Projects

- **Fiskroad** — the umbrella program covering all four projects.
- **hometown** — Enterprise Knowledge Graph: the semantic layer over
  divisional source systems; owns governed Cube models, GraphRAG
  context, and answer provenance.
- **popeye** — the AI usage governance control plane: gateway, virtual
  keys, budgets, spend ledger, provider failover.
- **nono** — Windows-native endpoint agent sandboxing; in this program,
  the detector for AI traffic that bypasses the gateway.
- **zt-infra / ZERO_TRUST_V2** — zero-trust agent identity and secure
  agent-to-agent transport.
- **bluto** — the enterprise identity spine: maps source-system keys to
  stable party identifiers via versioned, auditable match rules.
  Chartered in response to architecture-evaluation gap C1. Holds
  identity mapping only, never business attributes.
- **sit-cip** — adjacent security/IT context intelligence platform; the
  origin of the Context Answer Envelope pattern and an onboarding
  application for popeye.

## Program Concepts

- **ATE (Answer Trace Envelope)** — the provenance record for an AI
  answer: evidence used, prompt shape, model calls, answer hash. Owned
  by hometown; joins popeye's ledger on `primary_request_id`.
- **CAE (Context Answer Envelope)** — the sit-cip precedent the ATE
  generalizes.
- **Attribution vocabulary** — `app_id`, `user_id`, `tenant_id`,
  `feature_tag`, carried on every gateway request as
  `spend_logs_metadata`. Shared verbatim between popeye and hometown.
- **Virtual key** — a gateway-issued credential scoped to an app, team,
  or user, carrying budgets and model allowlists. Replaces raw provider
  API keys everywhere.
- **Break-glass** — the dual-approved, time-boxed procedure for direct
  provider access when the gateway cannot serve.
- **Party / party_id** — a resolved enterprise entity and its stable
  identifier, owned by Bluto. Never reused, including after merge.
- **Data class** — the sensitivity classification carried by a feature
  tag and by an approved model; popeye enforces the intersection.
- **Degradation mode** — per-feature declaration of behaviour when
  governed context is unavailable: `fail_closed` or
  `degrade_with_disclosure`.
- **Retrieval tier** — L (live), P (pre-aggregated, bounded staleness),
  or M (materialized) per entity type, with a declared freshness bound.
- **Bounded overspend** — the accepted consistency trade: budget
  counters are eventually consistent, so overspend is bounded and
  measured rather than zero.

## POCs (program-level charters)

- **POC A** — answer provenance (the ATE). Lands as hometown Stage 4.
- **POC B** — governed semantic access (who may ask what). hometown
  Stage 5.
- **POC C** — evaluation harness (groundedness joined to cost).
- **POC D** — governed actions (the write path; action broker).
- **POC E** — cross-organization federation over zt-infra.

## File And Repository Naming

- Repositories are named by codename alone: `hometown`, `popeye`,
  `nono`, `zt-infra-full`. There is no `-infra` suffix; earlier drafts
  used `popeye-infra` and `ai-gateway-infra`, both retired.
- Every project's team roadmap is `specs/ROADMAP.md` and its state file
  is `specs/STATE.md` (popeye's state file sits at the repo root). The
  `ROADMAP_integration_*` filenames were merge-process artifacts and are
  retired; both roadmaps are consolidated single files as of
  2026-07-28.

## Stage Numbers Are Per-Project

"Stage 2" means different things in different repositories: popeye
Stage 2 is the first managed Azure region; hometown Stage 2 is the
Intrepid non-production slice. Always say which project.
