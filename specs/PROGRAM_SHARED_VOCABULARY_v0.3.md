# Program Shared Vocabulary v0.3

Version: 0.3 (first issue at this number — versioned with the cross-repo correction set)
Status: Draft — closes cross-repo findings X1 (owning half) and X2
Repository: fiskroad. Audience: all project leads; popeye and hometown implement against this.
Primary post-read action: ratify the two definitions below, then land the conformance checks named in section 4 before the POC generates data.

## 1. Why This Document Exists

The cross-repository review found that each project is internally consistent while the program's shared vocabulary is not: the data-class taxonomy forked between the policy document and the enforcement registry, and `tenant_id` differs in type and format across the stores that must join on it. Both are vocabulary defects, so the fix is a vocabulary document — one page, program-owned, that the repositories conform to and CI compares against.

This document is authoritative for the two definitions it contains. Where any repository disagrees with it, the repository is wrong.

## 2. Canonical Tenant Identifier (closes X2)

**Definition.** `tenant_id` is a UUID, rendered in lowercase canonical form (8-4-4-4-12), identical in every store, header, event, trace, and seed record in the program.

Consequences by surface:

- **Gateway attribution** — the `tenant_id` key inside `spend_logs_metadata` carries the UUID string. Human-readable tenant names are display labels and never travel as identifiers.
- **hometown** — Intrepid RLS predicates already cast `::uuid`; unchanged. The `answer_trace.tenant_id` column and ATE `principal.tenantId` carry the same UUID string.
- **Bluto** — `tenant_id uuid` columns; unchanged. Bluto is the reference implementation of this rule.
- **Seed data (POC)** — the intern guide's `TENANT_ALPHA` / `TENANT_BETA` / `TENANT_GAMMA` become display names for three fixed, program-recorded UUIDs minted once and written into the seed script. The friendly names may appear in display columns only.
- **Where the real tenant registry lives** — Entra tenant/group object IDs are the natural long-term source; that mapping decision is recorded as open, but the *format* is settled now regardless of eventual source.

| REQ | Requirement | TC | Test criteria | Method |
|---|---|---|---|---|
| REQ-VOC-01 | Every stored `tenant_id` parses as a lowercase canonical UUID | TC-VOC-01 | hometown's live attribution verifier asserts ledger `tenant_id` values parse as UUIDs; Bluto and Intrepid enforce by column type | CI (live mode) |
| REQ-VOC-02 | Seed data uses the three recorded POC tenant UUIDs | TC-VOC-02 | Seed script review; ledger rows join to Intrepid rows on tenant | DEMO |

## 3. Canonical Data-Class Taxonomy (closes X1, program half)

**Definition.** Five classes, exactly these names, ordered from least to most restricted:

`public` < `internal` < `confidential-personal` < `regulated-financial` < `regulated-identifier`

Rules that travel with the taxonomy:

1. Class names are exact strings. There is no `confidential`, no `regulated`, no abbreviation. A class name not on this list is a validation error, not a synonym.
2. **`regulated-identifier` is structurally unapprovable.** No model, on any cloud, under any contract, may declare it as an approved maximum. Data of this class never enters a prompt; the correct pattern is a tokenized reference (Bluto). Enforcement of this rule is a registry-schema constraint in popeye, not a review convention.
3. An undeclared feature tag defaults to `internal` (deny-by-default, as already specified).
4. Additions or renames to this list are a program-level contract change: recorded here first, then propagated, never the reverse.

| REQ | Requirement | TC | Test criteria | Method |
|---|---|---|---|---|
| REQ-VOC-03 | popeye's model-approval registry uses only these class names | TC-VOC-03 | Cross-repo CI check compares the registry's `data_classes` block to this document's list; any divergence fails | CI |
| REQ-VOC-04 | No registry entry approves `regulated-identifier` | TC-VOC-04 | Registry schema validation rejects it; a deliberate bad entry fails CI | CI |

## 4. Conformance Checks (the mechanism that keeps this true)

The prior reviews moved each repository from text-versus-text checks to artifact-versus-reality checks. This document adds the third layer: repository-versus-repository.

- **fiskroad carries the machine-readable form** of both definitions: `contracts/vocabulary.yaml` containing the class list (ordered) and the three POC tenant UUIDs. This file is the comparison target.
- **popeye CI** fetches or vendors `vocabulary.yaml` and asserts registry class names ⊆ program class list and the `regulated-identifier` unapprovability rule (TC-VOC-03/04).
- **hometown CI (live mode)** asserts stored `tenant_id` values parse as UUIDs (TC-VOC-01).
- Until fiskroad is published on GitHub (finding X7), each consuming repo vendors a copy of `vocabulary.yaml` with a checked-in hash of the source; publication replaces vendoring with a fetch.

## 5. Out Of Scope Here

Feature-tag naming conventions, the approved-model list contents, and per-class handling rules stay in `REGULATED_DATA_CONTROLS` — this document defines only the vocabulary they share. The Entra mapping for tenant identity is an open decision recorded in the glossary.
