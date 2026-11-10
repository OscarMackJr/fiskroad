# Decision Record: Task Binding on the popeye Agent Key (D-3)

| Field | Value |
|---|---|
| Status | **Ratified 2026-11-10** |
| Date | 2026-11-10 |
| Owner | popeye |
| Components affected | popeye (minting, registry, introspection, ledger); nono (session launch); sit-cip, Nexus, olive (consume the binding) |
| Related | `FISKROAD_ACCESS_CONTROL_RBAC_TBAC_v0.1.md` §4.2, §9 D-3; `POPEYE_v0.4.1.md` §2.2, §5 O3; `DECISION_agent-key-service-scope.md`; `DECISION_task-vocabulary.md` |
| Supersedes | — |

---

## 1. Context

Task-based access needs a carrier for "this request belongs to task X of type Y". nono already mints a short-lived agent key per session through popeye. The key has a TTL, a `purpose` and `on_behalf_of`, and it is revoked at session end. `POPEYE_v0.4.1` §5 O3 left open where the agent-ID registry lives.

## 2. Decision

**popeye adds `task_id`, `task_type` and `task_expires_at` to the agent key at mint. `task_type` must come from popeye's agent registry, which is seeded from `contracts/authz/task_types.yaml`.**

- `task_expires_at` ≤ key expiry ≤ 8 h. popeye "may shorten, never lengthen."
- Closing the task is a revocation event at popeye. Services see it within the 60-second introspection cache.
- The binding carries identity only. What a task type permits lives in Cedar policy (`DECISION_policy-engine-cedar.md`).
- **This closes `POPEYE_v0.4.1` §5 O3:** the agent registry lives in popeye. It holds each agent's grants, permitted task types, tenants and purposes, matching the unratified roadmap proposal R2.

## 3. Alternatives Considered

- **A separate task token.**
  - For: tasks are decoupled from sessions.
  - Against: a second mint and revocation path, the drift risk that `DECISION_agent-key-service-scope` §3.2 rejected, and two credentials to reconcile.
  - Rejected.
- **Per-system grants with no shared binding.**
  - For: no popeye change.
  - Against: no cross-system task identity, and revocation would have to be repeated in each system.
  - Rejected.

## 4. Consequences

- **Follow-up:** a popeye amendment (POPEYE v0.4.4 or later) specifying the task claims, registry schema, revocation on task close and ledger fields. It is owned by popeye and not written in this record.
- nono passes `task_id` and `task_type` at session launch: one task per coding session.
- **Residual:** a task that genuinely runs longer than 8 hours needs a fresh key, and with it a new or renewed binding. That is accepted, because it keeps the key-lifetime bound intact.

## 5. Revisit Triggers

- Long-running tasks become common enough that key renewal is a burden: consider a renewal flow, never a longer lifetime.
- Transaction Tokens (draft-ietf-oauth-transaction-tokens) becomes an RFC: evaluate it as the carrier between hops.

---

## Ratification Record

| Field | Value |
|---|---|
| Decision | **Ratified**: task claims on the popeye agent key; registry in popeye (§2) |
| Date | 2026-11-10 |
| Ratified by | Oscar Mack, program lead (architecture and risk decisions) |
| Session | Access-control decisions session, 2026-11-10. Recommendation accepted as written. |
| Closes | `POPEYE_v0.4.1` §5 O3 (registry location) |
| Follow-up ratified | `POPEYE_v0.4.4.md` (the §4 popeye amendment), with `NONO_v0.4.4.md`, via `DECISION_agent-key-service-scope` Revision 2, 2026-11-10 |
| Change control | Moving the binding off the agent key, or adding capabilities to it, requires a new decision record |
