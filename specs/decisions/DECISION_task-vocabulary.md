# Decision Record: Task Terms in the Shared Vocabulary (D-2)

| Field | Value |
|---|---|
| Status | **Ratified 2026-11-10** — ratifies `PROGRAM_SHARED_VOCABULARY_v0.5.md` and `contracts/vocabulary.yaml` v0.5 |
| Date | 2026-11-10 |
| Owner | Program lead with popeye |
| Components affected | every repository that vendors `contracts/vocabulary.yaml`; popeye (minting) |
| Related | `FISKROAD_ACCESS_CONTROL_RBAC_TBAC_v0.1.md` §2, §9 D-2; `DECISION_task-binding-on-agent-key.md`; `contracts/authz/task_types.yaml` |
| Supersedes | `PROGRAM_SHARED_VOCABULARY_v0.4.md` |

---

## 1. Context

Task-based access control needs one identifier for a task that every system understands. Without it, an audit cannot follow a task from a nono session through a sit-cip investigation and an olive proposal to a Nexus write. Vocabulary v0.4 had no task concept. Its scoping units were the session agent key, `run_id`, `proposal_id` and the declared purpose.

## 2. Decision

**Add tasks to the shared vocabulary as v0.5:**

- `task_id`, a lowercase canonical UUID.
- `task_type`, of the form `<system>.<kind>`, from a registered list.
- Task states `open`, `closed`, `expired` and `revoked`.
- Binding rules: the binding never outlives the agent key, and it carries no capabilities.

The registered task types are seeded in `contracts/authz/task_types.yaml`: `nono.coding_session`, `sitcip.investigation`, `nexus.deal_review` and `olive.proposal`.

## 3. Alternatives Considered

- **Per-system task terms.**
  - For: no contract change.
  - Against: four incompatible notions of "task", and no join key across systems for audit (spec §4.5).
  - Rejected.
- **Reuse `run_id` as the task identifier.**
  - For: it already exists.
  - Against: a run is one agent session, while a task can span sessions (a multi-day investigation) or have no agent at all (an olive proposal).
  - Rejected.

## 4. Consequences

- `contracts/vocabulary.yaml` moves to v0.5 (SHA-256 `db1a9b135248ec7c988722213dc882dfd97bcf269423fe639f81eea04004f855`, LF). Every consuming repository re-vendors it and updates `VENDORED.md`.
- **This is a two-team contract change** (STATE.md, Invariant 2). popeye and every consumer review the re-vendor.
- New requirements REQ-VOC-11 to REQ-VOC-14 (vocabulary v0.5 §6).

## 5. Revisit Triggers

- A task type that needs more than one system's anchor, such as a cross-system workflow: consider a parent-task field.
- Onward agent-to-agent delegation is reconsidered (vocabulary §3.2): tasks will need a delegation chain.

---

## Ratification Record

| Field | Value |
|---|---|
| Decision | **Ratified**: task terms added as vocabulary v0.5 (§2) |
| Date | 2026-11-10 |
| Ratified by | Oscar Mack, program lead (architecture and risk decisions) |
| Session | Access-control decisions session, 2026-11-10. Recommendation accepted as written. |
| Ratifies | `PROGRAM_SHARED_VOCABULARY_v0.5.md`; `contracts/vocabulary.yaml` v0.5 |
| Change control | Any change to task fields or states is a vocabulary revision, ratified by a new decision record |
