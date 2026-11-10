# Access Control Across nono, sit-cip and Nexus: RBAC + TBAC — Recommendation v0.1

Version: 0.1
Status: **Decisions ratified 2026-11-10.** All six §9 recommendations were accepted, and each is recorded in `specs/decisions/`. The prerequisite fixes (§5 Phase 0) are merged apart from denial logging. `contracts/authz/` and vocabulary v0.5 implement D-1 and D-2.
Date: 2026-11-10
Audience: program lead; nono, sit-cip, Nexus and popeye maintainers; olive charter owner
Relationship: triggers the deferred policy-engine decision in `COMPONENT_GAP_ASSESSMENT_v0.1` §3C; builds on `POPEYE_v0.4.1` §2.2 (agent keys), `PROGRAM_SHARED_VOCABULARY_v0.4` §2–§4, `OLIVE_CHARTER_v0.4` §2–§5, `DECISION_agent-key-service-scope`, and `FISKROAD_MCP_GOVERNANCE_CONVERGENCE_v0.1`.
Primary post-read action: start Phase 1 (§5). The follow-ups named in the D-3 and D-4 decision records are the popeye amendment for task claims and the nono and popeye amendments for the wider injection scope.

---

## 1. Recommendation in One Paragraph

Use **Entra ID app roles for RBAC**: a small, fixed role catalogue per system, assigned through Entra groups, with privileged roles activated just in time through PIM. Implement **TBAC as a task binding on the identity the program already mints**. The popeye agent key gains a `task_id` and `task_type`. Each system then authorizes a request against three things together: the user's roles, the agent's grants, and what the task type allows. The task binding dies when the task closes. Evaluate that combined rule with **Cedar, embedded in each system** (Rust crate in nono, Python bindings in sit-cip and Nexus). The policies and schema live in one shared, CI-tested policy repository. There is no central policy service in v1. All writes that change another system's state, such as sit-cip → Tines and agent → Nexus, go through **olive action types**, which already carry the approval rules. This review found three access-control defects, which are now fixed (§5 Phase 0).

## 2. Definitions Used Here

- **RBAC.** A principal's standing permissions come from roles. Roles are coarse, change rarely, and are assigned to people and groups, never to individual requests.
- **TBAC (task-based access control).** Permissions are switched on for the duration and scope of one task and switched off when it ends. This follows Thomas & Sandhu (1997). The present-day agent form is the same idea: a just-in-time, short-lived grant bound to the user being acted for, the agent, and one declared task.
- **Task.** This spec proposes it as a new vocabulary term (open decision D-2). A task is a bounded unit of work with an owner, a type, a lifecycle (opened → closed) and a `task_id`. It is a lowercase canonical UUID, like every other program ID. The concrete task anchors already exist:

| System | Task anchor (existing) |
|---|---|
| nono | the agent session/run (`session_id`, `run_id`) |
| sit-cip | `InvestigationThread`, `ValidationTicket` (`src/python_engine/models.py`) |
| Nexus | `Task` (has `assignee_id`, `deal_id`), `Deal` + `DealTeamMember` |
| olive | `proposal_id` (an approved proposal is a single-use task) |

- **Effective permission** for an agent request. This restates vocabulary §3 ("delegation narrows"), with the task as a third factor:

```
effective = roles(on_behalf_of) ∩ grants(agent principal) ∩ allowed(task_type) ∩ scope(task instance)
```

Each factor can only narrow the result. None of them widens another.

## 3. What Exists Today

All findings come from the code at the time of this review.

| | nono | sit-cip | Nexus |
|---|---|---|---|
| **AuthN** | OS identity. The control pipe is SDDL-restricted to SYSTEM, Admins and the owner. The agent is identified by its AppContainer SID. A per-session secret authenticates the child to the supervisor. | Static API keys in the `X-SITCIP-API-Key` header, loaded from Key Vault into an env var. No Entra or OIDC. | Local passwords and HS256 JWTs signed with one shared `SECRET_KEY`. No SSO. |
| **Roles** | Implicit admin vs user, from Windows ACLs | `operator`, `owner`, `auditor`, `admin`, checked inline in each route | `admin`, `supervisor`, `principal`, `regular_user`, as one string per user |
| **Record or tenant scope** | Capability sets: paths, network, profiles | Tenant set per key | `org_id` filters written into each query; team and private-deal rules in `backend/auth/access.py`; no row-level security |
| **Task or session scope** | **Yes.** A per-session popeye agent key (TTL, `purpose`, revoked at session end). `ApprovalBackend` grants at runtime. Signed, expiring `OverrideGrant`. | None | None |
| **Agent identity** | popeye agent key, injected by nono-proxy | The app's own managed identity, used for model calls | None. An agent would have to log in as a human. |
| **Audit** | Hash-chained NDJSON, DSSE attestations, ETW events, `.agent.json` / `.end.json` | JSON log lines for writes and AI calls. Denials are not logged as events. | A stub middleware that `print`s. No audit table. |

The conclusion is that nono already implements TBAC for its own sessions. sit-cip and Nexus have RBAC only, and neither has a usable identity for agents. So the program-level work is to extend nono's per-session pattern to the other two systems, not to invent a new one.

## 4. Recommended Architecture

### 4.1 RBAC: Entra app roles, one catalogue per system

- Each system is an Entra app registration whose app roles become the token's `roles` claim. Assign roles to **groups**, not to users. Prefer app roles over raw group claims, because a user in too many groups gets a token with the group list omitted.
- Map the existing role names one-to-one, so the code changes stay small:

| System | Roles (`role:<name>`) | Privileged, so PIM-activated |
|---|---|---|
| nono | `nono_policy_admin`, `nono_override_approver`, `nono_operator` | admin, approver |
| sit-cip | `sitcip_operator`, `sitcip_owner`, `sitcip_auditor`, `sitcip_admin` | admin |
| Nexus | `nexus_admin`, `nexus_supervisor`, `nexus_principal`, `nexus_user` | admin |
| olive (existing) | `case_supervisor`, plus others as chartered | per action type |

- Keep 4–6 roles per system. Record-, team-, tenant- and task-level conditions are **attributes in policy, never new roles**. That rule is what prevents an explosion of roles.
- nono keeps the OS as the enforcement point for its local operator plane. The Entra roles apply to who may *author* fleet policy (HKLM/Intune profiles) and who may *sign* override grants. A nono roles claim inside the endpoint waits on credential-contract option D-1(a).
- Nexus runs on AWS. That doesn't stop Entra from being its identity provider, which is a standard OIDC integration. Keep local passwords only as break-glass access, behind a feature flag.

### 4.2 TBAC: a task binding on the agent key, not a new credential

- **Mint.** popeye mints the agent key as it does today, and adds three claims: `task_id`, `task_type` and `task_expires_at` (open decision D-3). The task can never outlive the key: `task_expires_at ≤ key expiry ≤ 8 h`, and popeye "may shorten, never lengthen."
- **Identity, not capability.** The key carries *who, for whom, for which task*, not a list of permitted operations. That keeps it consistent with the ratified rule that "introspection is identity, not capability." It also keeps meaning out of the gateway (program invariant). The operations a `task_type` permits live in policy (§4.3), owned by each system.
- **Lifecycle.** Closing the task is the revocation event:
  - nono revokes at session end, which it already does.
  - sit-cip revokes when the thread is closed or reviewed, or the ticket is resolved.
  - Nexus revokes when the `Task` is completed.
  - olive revokes when the proposal executes, is rejected or expires.

  Revocation goes to popeye. The receiving systems see it within the existing 60 s introspection cache.
- **Humans get TBAC too.** A human's task-scoped elevation is **PIM for Groups**: time-boxed activation with a justification, which produces an app role. Do not build a custom human task-grant flow.
- **Standards posture.**
  - Express task scope in the shape of an RFC 9396 `authorization_details` entry (type, actions, locations), so a later move to standard OAuth is a format change rather than a redesign.
  - Use Entra on-behalf-of or RFC 8693 token exchange between hops. **Never pass a received token through to the next hop.**
  - Watch OAuth Transaction Tokens (still a draft, planned for IESG submission in December 2026) as the eventual cross-hop carrier, but do not depend on it.
  - Treat Entra Agent ID, Okta Cross App Access and the agent-OBO drafts as pre-standard. Keep them behind popeye's issuer abstraction.

### 4.3 Policy decision: Cedar, embedded, one policy repository

- **Why now.** §3C deferred a policy engine until "policies that must be evaluated at runtime by components other than the semantic layer". Three systems evaluating role × agent × task is that case.
- **Why Cedar:**
  - It is written in Rust, so it embeds natively in nono.
  - It has Python bindings for sit-cip and Nexus.
  - Policies are checked against a schema and can be formally analyzed.
  - It denies by default, and `forbid` overrides `permit`. That matches the program's posture that `regulated-identifier` is structurally unapprovable.
  - It is a CNCF Sandbox project.
- **Why not OPA.** OPA is the more mature general engine. But it is a weak fit for embedding in Rust (it needs a sidecar or Wasm), and Rego is harder to review. Revisit if the program adopts Kubernetes admission control.
- **Why not OpenFGA (Zanzibar-style relationship authorization) now.** Nexus's record rules (team, owner, private, oversight) fit in roughly a dozen Cedar policies over entity attributes. Adopt OpenFGA only if Nexus gains real many-to-many sharing (revisit trigger R-3).
- **Where policies live.** The shared schema and policies are in `fiskroad/contracts/authz/`: `schema.cedarschema`, `policies/<system>/*.cedar`, `fixtures/*.json`, `roles.yaml` and `task_types.yaml`. They are checked by `tools/authz_check.py`.
  - Each system pins a version, the same pattern as `contracts/vocabulary.yaml`.
  - CI runs `cedar validate`, plus golden allow/deny fixtures for every role × task_type × data class.
  - Changing a policy is a contract change, reviewed in the policy repository and the affected system's repository.
- **Where policies are enforced.** In-process, at each system's existing check point:
  - **nono:** a Cedar-backed `ApprovalBackend`, at `crates/nono/src/supervisor/mod.rs`, decides runtime capability requests against the session's task binding. The terminal prompt stays as the escalation path. Move override-grant signature verification from nono-py into Rust next to it.
  - **sit-cip:** replace inline `require_role()` / `require_tenant()` with one FastAPI dependency, `authorize(action, resource)`, that calls Cedar.
  - **Nexus:** `backend/auth/access.py` becomes the place Cedar is called from. Its existing functions become policies with the same names, so the service layer doesn't change.
- **No central decision service in v1.** It would be a new runtime component, which the program has declined to add for this push. Embedded evaluation over one shared policy set gives the same consistency.

### 4.4 Actions across systems go through olive

- **sit-cip → Tines.** The `TinesHandoffEvent` becomes an olive proposal with `target_system: "tines"`. The recommendation records the analyst (`on_behalf_of`) and the `task_id` of the thread. This answers the open question in sit-cip's v0.4 spec (FR-70, step-up authorization).
- **Agent → Nexus.** Agents never log in to Nexus as users. Agent writes are olive action types with `target_system: "nexus_crm"`. olive's executor calls Nexus with its own workload identity *and* the `on_behalf_of` user, and Nexus records both. Agent reads use the popeye agent key, validated through introspection. That extends `inject_on`, which `DECISION_agent-key-service-scope` §7 says needs a **program decision** (D-4).
- **Approvals stay as chartered.** Approval is per proposal, never per action type, and there are no standing approvals.

### 4.5 Audit: one decision record shape

- Every policy decision, allow **and deny**, emits one record in a common shape: `decision_id`, `timestamp`, `system`, `principal_type`, `principal_id`, `on_behalf_of`, `agent_id`, `task_id`, `task_type`, `action`, `resource_type`, `resource_id`, `tenant_id`, `data_class`, `decision`, `policy_ids[]`, `request_id`.
- The record **never includes arguments or content**, per the program invariant that governed stores hold no content.
- Each system keeps its own sink: nono's hash chain, Log Analytics for sit-cip, and a new append-only `audit_event` table in Nexus.
- Records correlate on `task_id` and `request_id` across systems.

## 5. Delivery Plan

| Phase | Scope | Exit criterion |
|---|---|---|
| **0 — Prerequisite fixes** (independent of this design) | **Done, 2026-11-10:**<br>• **Nexus self-registration:** public registration no longer accepts `org_id`, so it can't join an existing org with a self-chosen role. Adding users to an existing org stays an admin action. Fixed in Nexus-CRM PR #1 (`a9319ac`), together with the schema change that made the defect reachable.<br>• **sit-cip:** with no keys configured, the API now fails closed. Local development opts in explicitly, and the opt-in is refused on Azure Container Apps.<br>• **sit-cip:** list endpoints called without a `tenant_id` return only the caller's own tenants.<br>Both sit-cip fixes are in sit-cip-poc PR #5 (`0646e17`).<br>**Open:** log 401/403 decisions as audit events, in both sit-cip and Nexus. | Regression tests merged for every fixed defect. The denial-logging item is still open. |
| **1 — RBAC on Entra** | App registrations and roles (§4.1). sit-cip: MSAL in the Workbench and JWT validation in the API. Keep API keys only for machine ingest, moving them to managed identity. Nexus: OIDC login, with roles from the claim. PIM for the admin roles. | Golden RBAC fixtures pass. No static human API keys remain in sit-cip. |
| **2 — Cedar + task binding** | `contracts/authz` schema, policies and fixtures. popeye adds the task claims. Enforcement points as in §4.3. The common audit shape (§4.5). | DEMO: one agent task in nono → sit-cip thread → olive proposal → Nexus write. Every hop is authorized and audited against the same `task_id`. Closing the task causes a denial within 60 s. |
| **3 — Hardening** | Entra access reviews (quarterly) for the privileged groups. Conditional Access on agent identities. Evaluate Entra Agent ID and Transaction Tokens against popeye's issuer. Nexus Postgres row-level security on `org_id`, as defense in depth. | AUDIT: an access review is completed and Conditional Access policies are in place. |

## 6. Requirements

| REQ | Requirement | TC | Test criteria | Method |
|---|---|---|---|---|
| REQ-AC-01 | Every system denies by default when policy cannot be evaluated | TC-AC-01 | A missing or corrupt policy bundle → every request is denied, and the denial is audited | CI |
| REQ-AC-02 | Role names come only from the §4.1 catalogue; each system has ≤ 6 roles | TC-AC-02 | A lint over the app-registration manifests and Cedar schema | CI |
| REQ-AC-03 | Agent effective permission ⊆ the `on_behalf_of` user's permission | TC-AC-03 | Fixtures: an agent request exceeding the user's role is denied for every role × task_type | CI |
| REQ-AC-04 | A task binding cannot outlive its agent key, and closing the task revokes it | TC-AC-04 | Close the task → the next request is denied within 60 s | DEMO |
| REQ-AC-05 | No system passes a received token through to another hop | TC-AC-05 | Inspect outbound calls: the audience changes on every hop | AUDIT |
| REQ-AC-06 | Every allow and deny emits a §4.5 record with no arguments or content | TC-AC-06 | Sample 100 records per system: all fields present, no payloads | AUDIT |
| REQ-AC-07 | Writes from one system to another go only through olive action types | TC-AC-07 | No direct agent-credential write path to Nexus or Tines exists | AUDIT |
| REQ-AC-08 | Privileged roles are activated just in time (PIM) and never assigned permanently | TC-AC-08 | Entra report: zero permanent assignments to the privileged groups | AUDIT |
| REQ-AC-09 | Phase 0 defects are closed | TC-AC-09 | The regression tests from Phase 0 pass in CI | CI |

## 7. Refuses to Own

- **Party identity and record matching.** That belongs to bluto. This spec is about principals, not parties.
- **What an action does.** That belongs to olive action types.
- **Meaning-based decisions in the gateway.** popeye mints identity and task binding only. It never evaluates policy.
- **Purpose vocabulary.** It is reused from vocabulary §2, never extended here.

## 8. Deliberately Not Built

- **A central policy decision service** (revisit trigger R-1).
- **A custom just-in-time flow for humans.** PIM covers it.
- **Relationship-based authorization (OpenFGA)** (revisit trigger R-3).
- **Capabilities inside tokens.** Tokens carry identity and task binding, and policy decides.
- **Per-service agent keys.** They stay rejected, per `DECISION_agent-key-service-scope` §3.2.

## 9. Decisions

All six recommendations were accepted at the access-control decisions session on 2026-11-10 with the nono, sit-cip, Nexus and popeye owners, and ratified by the program lead. Each has a decision record in `specs/decisions/`.

| ID | Decision | Outcome | Owner | Record |
|---|---|---|---|---|
| D-1 | Adopt Cedar as the program policy engine (closes the §3C deferral) | **Adopted**: Cedar, embedded, one shared policy repository (`contracts/authz/`) | Program lead | `DECISION_policy-engine-cedar.md` |
| D-2 | Add `task`, `task_id` and `task_type` to the shared vocabulary (a two-team contract change) | **Adopted** as vocabulary v0.5 | Program lead + popeye | `DECISION_task-vocabulary.md` |
| D-3 | popeye adds the task claims to agent keys. This closes POPEYE_v0.4.1 O3 by putting the registry in popeye, per proposal R2. | **Adopted**; `task_type` comes from a registered list (`contracts/authz/task_types.yaml`) | popeye | `DECISION_task-binding-on-agent-key.md` |
| D-4 | Extend `inject_on` to sit-cip and Nexus | **Adopted** for reads only; writes go through olive. The nono and popeye amendments and re-ratification of `DECISION_agent-key-service-scope` follow. | Program lead | `DECISION_agent-key-sitcip-nexus-reads.md` |
| D-5 | Use Entra as Nexus's identity provider, although Nexus runs on AWS | **Adopted** | Nexus | `DECISION_nexus-identity-provider-entra.md` |
| D-6 | Name the Entra groups for every §4.1 role, including the open `role:case_supervisor` and `role:identity_steward` | **Adopted**: named in Phase 1 | Program lead | `DECISION_entra-group-naming.md` |

**Revisit triggers:**
- **R-1:** more than about 5 systems evaluate policy, or policies need data that no single system holds. Then consider a central decision service.
- **R-2:** OAuth Transaction Tokens becomes an RFC. Then evaluate it as the carrier between hops.
- **R-3:** Nexus needs per-record sharing beyond team and owner. Then evaluate OpenFGA.

## 10. Sources

- **Internal:** the code surveys of `Nono`, `sit-cip-poc` and `nexus/Nexus-CRM` at their HEAD on 2026-11-10, and the program specs cited in the header.
- **External:**
  - [RFC 8693](https://www.rfc-editor.org/rfc/rfc8693) (token exchange)
  - [RFC 9396](https://www.rfc-editor.org/rfc/rfc9396) (rich authorization requests)
  - [draft-ietf-oauth-transaction-tokens](https://datatracker.ietf.org/doc/draft-ietf-oauth-transaction-tokens/)
  - [draft-klrc-aiagent-auth](https://datatracker.ietf.org/doc/draft-klrc-aiagent-auth/02/)
  - [MCP authorization specification](https://modelcontextprotocol.io/specification/draft/basic/authorization/index)
  - [Entra Agent ID](https://learn.microsoft.com/entra/agent-id/agent-identities) and [Conditional Access for agents](https://learn.microsoft.com/en-us/entra/identity/conditional-access/agent-id)
  - [Cedar joins CNCF](https://aws.amazon.com/blogs/opensource/cedar-joins-cncf-as-a-sandbox-project)
  - [OpenFGA joins CNCF Incubating](https://www.cncf.io/blog/2025/11/11/openfga-becomes-a-cncf-incubating-project/)
  - Thomas & Sandhu, "Task-based Authorization Controls (TBAC)", IFIP WG11.3, 1997
