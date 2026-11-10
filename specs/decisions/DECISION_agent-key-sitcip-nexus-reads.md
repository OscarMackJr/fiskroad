# Decision Record: Agent Key on sit-cip and Nexus, Reads Only (D-4)

| Field | Value |
|---|---|
| Status | **Ratified 2026-11-10** |
| Date | 2026-11-10 |
| Owner | Program lead |
| Components affected | nono (injection scope), popeye (introspection callers), sit-cip, Nexus, olive (executor) |
| Related | `FISKROAD_ACCESS_CONTROL_RBAC_TBAC_v0.1.md` §4.4, §9 D-4; `DECISION_agent-key-service-scope.md` §7 and its change-control clause; `OLIVE_CHARTER_v0.4.md` §2–§3 |
| Supersedes | — |

---

## 1. Context

`DECISION_agent-key-service-scope` limits the session agent key to the gateway, hometown and olive. Its §7 says: "a fourth service needing agent identity → extend `inject_on` by program decision, not configuration". sit-cip and Nexus now need agent identity for task-scoped reads. Agent writes to either system would bypass olive's approval rules.

## 2. Decision

**Extend agent-key injection to the sit-cip and Nexus FQDNs declared in an agent profile, for reads only. Every agent-initiated write to Nexus, and every sit-cip hand-off to Tines, goes through an olive action type.**

- sit-cip and Nexus validate the key through popeye introspection, exactly as hometown and olive do.
- Agents never log in to Nexus as users. The olive executor writes under its own workload identity with `acting_for` set to the approving user, and Nexus records both.
- The shared policy `common.agent_no_direct_nexus_write` (`contracts/authz/policies/common/guards.cedar`) denies any agent write to Nexus, whatever else permits it.

## 3. Alternatives Considered

- **Reads and writes on the agent key.**
  - For: simpler for agents.
  - Against: bypasses olive's per-proposal approval and its `refused_policy` / `rejected` distinction.
  - Rejected.
- **Not yet.**
  - For: no change to the ratified injection scope.
  - Against: leaves sit-cip and Nexus with no agent identity, so agents keep borrowing human logins.
  - Rejected.

## 4. Consequences

- **Change control applies.** `DECISION_agent-key-service-scope` requires that "any change to injection scope … requires matching changes to both amendments and re-ratification of this decision". This record is the program decision its §7 calls for. Implementing it still needs:
  - a nono amendment adding sit-cip and Nexus to the injectable FQDNs, and
  - a popeye amendment adding them as registered introspection callers,

  followed by re-ratification of `DECISION_agent-key-service-scope`. None of these are written yet.
- sit-cip's `TinesHandoffEvent` becomes an olive proposal with `target_system: "tines"`, carrying `on_behalf_of` and `task_id`.
- **Residual:** the key reaches two more services. That is mitigated by short TTL, reads-only policy, and introspection conferring no capability, the same mitigations as the original scope decision.

## 5. Revisit Triggers

- A read-only path proves insufficient for a specific agent workflow. Add it as an olive action type, never as direct write access.
- Replay from a program service becomes a realistic threat. Reconsider per-service tokens (`DECISION_agent-key-service-scope` §3.2).

---

## Ratification Record

| Field | Value |
|---|---|
| Decision | **Ratified**: inject on sit-cip and Nexus for reads; writes via olive (§2) |
| Date | 2026-11-10 |
| Ratified by | Oscar Mack, program lead (architecture and risk decisions) |
| Session | Access-control decisions session, 2026-11-10. Recommendation accepted as written. |
| Not ratified here | The nono and popeye amendments, and re-ratification of `DECISION_agent-key-service-scope` (§4) |
| Residual risk accepted | Wider key exposure, limited to reads (§4) |
