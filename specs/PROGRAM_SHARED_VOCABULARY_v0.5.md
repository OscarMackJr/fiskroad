# Program Shared Vocabulary v0.5

Version: 0.5
Status: **Ratified 2026-11-10** by `specs/decisions/DECISION_task-vocabulary.md` (D-2).
Repository: fiskroad, `specs/`. Machine-readable form: `contracts/vocabulary.yaml` (v0.5, SHA-256 `db1a9b135248ec7c988722213dc882dfd97bcf269423fe639f81eea04004f855`, LF line endings).
Audience: all project leads. hometown, popeye, olive and bluto implement against this; nono, sit-cip, Nexus and Liam validate against it.
Primary post-read action: re-vendor `vocabulary.yaml` in every consuming repository and update each `VENDORED.md` hash. popeye: add the task fields to agent-key minting (§5.3).

Supersedes v0.4 (SHA-256 `60a44f00db0daafcad3a4e11fe8fcbb2821e1ca7879302bae413b212a0c1e8e7`). Everything in v0.4 is carried forward unchanged (§1–§4); v0.5 adds tasks (§5).

---

## 1–4. Carried Forward From v0.4 (unchanged)

The following sections of `PROGRAM_SHARED_VOCABULARY_v0.4.md` apply as written:

- **§1:** canonical tenant identifier and data-class taxonomy (from v0.3).
- **§2:** purposes, with no default and the purpose/class prohibitions.
- **§3:** principal types `user`, `application` and `agent`. Agent delegation narrows: effective permission is the intersection, never the union. Onward delegation is refused.
- **§4:** action outcomes and action identifiers.

Their requirements REQ-VOC-01 to REQ-VOC-10 are unchanged.

---

## 5. Tasks (new at v0.5; decision D-2)

### 5.1 Definition

A **task** is a bounded unit of work with an owner, a type and a lifecycle. Task-based access control (TBAC) switches an agent's permissions on for one task and off when it closes.

Each system already has a natural task anchor:

| System | Task anchor | `task_type` |
|---|---|---|
| nono | agent session (`session_id`, `run_id`) | `nono.coding_session` |
| sit-cip | `InvestigationThread`, `ValidationTicket` | `sitcip.investigation` |
| Nexus | `Task` (with `assignee_id`, `deal_id`) | `nexus.deal_review` |
| olive | `proposal_id`, single use | `olive.proposal` |

### 5.2 Identifiers and states

- `task_id` is a UUID in lowercase canonical form, the same form as `tenant_id` (§1.1).
- `task_type` has the form `<system>.<kind>`, matching `^[a-z][a-z0-9_]*\.[a-z][a-z0-9_]*$`.
  - Registered values live in `contracts/authz/task_types.yaml`.
  - popeye's agent registry mirrors that list, and an unregistered type is refused at mint.
  - Adding a task type is a change-managed event, not configuration.
- Task states, exact strings: `open`, `closed`, `expired`, `revoked`. Any state other than `open` ends the binding.

### 5.3 The task binding

- A task binding travels on the popeye agent key as `task_id`, `task_type` and `task_expires_at` (decision D-3).
- The binding never outlives its agent key, which is capped at 8 hours. popeye "may shorten, never lengthen."
- **Identity, not capability.** The binding says which task a request belongs to. What a `task_type` permits is defined in policy (`contracts/authz/policies/`), owned per system, never in the key.
- Closing the task revokes the binding at popeye. Services see the revocation within the existing 60-second introspection cache.
- A request without a binding is not an agent request any system will serve. Agents act only inside a task.

### 5.4 Where tasks are enforced

- **popeye:** validates `task_type` against the registry at mint, records `task_id` on the ledger, and revokes on task close.
- **nono, sit-cip, Nexus:** evaluate the shared Cedar policies with the binding in the request context.
- **olive:** an approved proposal is a single-use task; its executor acts under `olive.proposal`.

---

## 6. Conformance

`contracts/vocabulary.yaml` gains `task_id_format`, `task_type_format`, `task_states` and `task_binding`. Consuming repositories re-vendor it with the recorded hash, as at v0.4.

| REQ | Requirement | Verified by | Method |
|---|---|---|---|
| REQ-VOC-11 | Every stored, logged or transmitted `task_id` parses as a lowercase canonical UUID | popeye mint validation; audit-record schema checks in each system | CI |
| REQ-VOC-12 | `task_type` values match `task_type_format` and appear in `contracts/authz/task_types.yaml`; an unregistered type is refused at mint | `tools/authz_check.py`; popeye registry conformance check | CI |
| REQ-VOC-13 | A task binding never outlives its agent key, and a request bound to a non-`open` task is refused | popeye mint and introspection tests; spec REQ-AC-04 | CI, DEMO |
| REQ-VOC-14 | The binding carries no capabilities: no permitted-operation list travels in any token | Token schema review; spec REQ-AC-05 | AUDIT |

**Line endings.** Hashes are computed over LF, as at v0.4.
