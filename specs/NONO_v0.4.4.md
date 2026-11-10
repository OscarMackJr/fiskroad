# Nono v0.4.4 — Task Binding at Launch, and sit-cip / Nexus Injection

Version: 0.4.4
Status: **Proposed 2026-11-10. Not ratified.** It ratifies jointly with `POPEYE_v0.4.4.md` (one seam) through the re-ratification of `DECISION_agent-key-service-scope.md` (proposed Revision 2). It implements decisions D-3 (`DECISION_task-binding-on-agent-key.md`) and D-4 (`DECISION_agent-key-sitcip-nexus-reads.md`), both ratified 2026-11-10.
Repository: nono (fork `OscarMackJr/nono`; place beside `NONO_v0.4.3.md`)
Amends:
- `NONO_v0.4.1.md` §4.1 (exchange request);
- `NONO_v0.4.2.md` §2 (permitted services) and §3 (agent profile);
- `NONO_v0.4.3.md` §5 (`AgentSessionRecord`).

Adds REQ-END-26 to -31. All other parts of v0.4.1 to v0.4.3 stand.
Audience: nono maintainer; popeye, sit-cip and Nexus owners.
Primary post-read action: review with the popeye owner alongside `POPEYE_v0.4.4.md`, then take both to re-ratification.

---

## 1. Why

- **D-3:** every agent key carries a task binding, and popeye refuses an exchange without one (`POPEYE_v0.4.4` §2). nono is the component that mints the key at launch, so it must supply the task.
- **D-4:** sit-cip and Nexus become services an agent profile may name in `inject_on`, for reads.

nono stays semantics-blind. It passes a task binding through to popeye and injects the key on named hosts; it does not know what a task type permits.

---

## 2. Task Binding at Launch (amends `NONO_v0.4.1` §4.1)

The `[agent]` profile block gains `task_source`:

```toml
[agent]
agent_id = "liam"
purpose_source = "launch_arg"
task_source = "session"          # or "launch_arg"
key_ttl_seconds = 3600
inject_on = ["hometown", "olive", "sitcip"]
```

- **`task_source = "session"`:** nono generates a fresh `task_id` (UUID v4, lowercase canonical) and binds `task_type = "nono.coding_session"`. This is the default for coding agents: one task per session, closed by the existing session-end revocation.
- **`task_source = "launch_arg"`:** the launcher supplies `--task-id <uuid>` and `--task-type <type>`, for example when an agent session works an existing sit-cip investigation (`sitcip.investigation`). nono validates the format only. popeye validates registration and refuses an unregistered type.

The exchange request gains `task_id` and `task_type`. The response's `task_expires_at` is recorded (§4).

**Fail secure.** The session refuses to start if:

- `task_source` is absent or unknown;
- `launch_arg` is selected and either argument is missing or malformed;
- popeye refuses the binding.

There is no fallback to an unbound key and no silent re-mint, as in `NONO_v0.4.1`.

---

## 3. Permitted Services (amends `NONO_v0.4.2` §2, §3)

Permitted services become `gateway`, `hometown`, `olive`, `sitcip` and `nexus`. The fail-secure profile checks of `NONO_v0.4.2` §3 apply unchanged:

- a named service must have an `[agent.services]` entry;
- its FQDN must be on the network allowlist;
- matching is on the exact CONNECT host.

```toml
[agent.services]
hometown = "<hometown-api-fqdn>"
olive    = "<olive-api-fqdn>"
sitcip   = "<sitcip-api-fqdn>"
nexus    = "<nexus-api-fqdn>"
```

nono does not enforce reads-only; sit-cip and Nexus do, in shared policy (`common.agent_no_direct_nexus_write`) and through olive for writes. nono's job is unchanged: inject only on declared services.

---

## 4. `AgentSessionRecord` (amends `NONO_v0.4.3` §5)

Schema version 2 adds:

```rust
pub task_id: TaskId,                 // lowercase canonical UUID; same type rules as KeyId
pub task_type: TaskTypeId,           // enum of registered task types
pub task_expires_at_unix: u64,       // popeye's granted task expiry
```

and extends `ServiceId`:

```rust
pub enum TaskTypeId { NonoCodingSession, SitcipInvestigation, NexusDealReview, OliveProposal }
pub enum ServiceId { Gateway, Hometown, Olive, Sitcip, Nexus }
```

- **Serialization:** `TaskTypeId` serializes as its registered string (`nono.coding_session` and so on); `ServiceId` as lowercase.
- **Content-free:** both new fields are content-free by construction, a UUID and an enum. No new `String` exception is needed (`NONO_v0.4.3` §7).
- **Enum drift guard:** a test asserts `TaskTypeId` matches the vendored `contracts/authz/task_types.yaml`, in the same way `PurposeId` is checked against `vocabulary.yaml`.
- **`SessionEndRecord` is unchanged.** Session-end revocation also ends a `nono.coding_session` task.

---

## 5. Exposure Statement

Shared with `POPEYE_v0.4.4` §6. The key may now reach up to five services, each declared in the profile and behind the allowlist and WFP fence. The task binding means a key works only for the task it was minted for, and only while that task is open.

---

## 6. Requirements

| REQ | Requirement | TC | Test criteria | Method |
|---|---|---|---|---|
| REQ-END-26 | Every agent session's exchange request carries a task binding; `session` mode generates a fresh UUID with `nono.coding_session` | TC-END-26 | Stub exchange capture shows `task_id` (lowercase UUID) and `task_type`; two sessions get different `task_id`s | CI (stub) |
| REQ-END-27 | A profile with a missing or unknown `task_source`, or `launch_arg` mode with missing or malformed arguments, does not start | TC-END-27 | Each misconfiguration refuses the session; the child never starts | CI |
| REQ-END-28 | A popeye refusal of the task binding stops the session with no fallback | TC-END-28 | Stub refuses `task_type`; session does not start; no user key reaches the child | CI (stub) |
| REQ-END-29 | `sitcip` and `nexus` are accepted in `inject_on` under the existing fail-secure checks | TC-END-29 | Profiles naming each start when allowlisted, and refuse when their FQDN is not allowlisted | CI |
| REQ-END-30 | `AgentSessionRecord` v2 records `task_id`, `task_type` and `task_expires_at_unix` | TC-END-30 | Record schema validation for an agent session; content-free scan passes | CI |
| REQ-END-31 | `TaskTypeId` matches the vendored `task_types.yaml` | TC-END-31 | Drift test | CI |

---

## Ratification Record

| Field | Value |
|---|---|
| Decision | **Pending.** Proposed for joint ratification with `POPEYE_v0.4.4.md` |
| Date | — |
| Ratified by | — (program lead, via re-ratification of `DECISION_agent-key-service-scope.md`) |
| Implements | `DECISION_task-binding-on-agent-key.md` (D-3) and `DECISION_agent-key-sitcip-nexus-reads.md` (D-4), ratified 2026-11-10 |
| Change control | On ratification, any change requires a matching change to `POPEYE_v0.4.4.md` and re-ratification of `DECISION_agent-key-service-scope.md` |
