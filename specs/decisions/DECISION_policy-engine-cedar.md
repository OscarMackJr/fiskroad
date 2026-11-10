# Decision Record: Cedar as the Program Policy Engine (D-1)

| Field | Value |
|---|---|
| Status | **Ratified 2026-11-10** |
| Date | 2026-11-10 |
| Owner | Program lead |
| Components affected | nono, sit-cip, Nexus; olive (executor rules); fiskroad `contracts/authz/` |
| Related | `FISKROAD_ACCESS_CONTROL_RBAC_TBAC_v0.1.md` §4.3, §9 D-1; `COMPONENT_GAP_ASSESSMENT_v0.1.md` §3C; `DECISION_task-vocabulary.md`; `DECISION_task-binding-on-agent-key.md` |
| Supersedes | The §3C deferral ("Policy engine … NOT adopted now") |

---

## 1. Context

`COMPONENT_GAP_ASSESSMENT_v0.1` §3C deferred a policy engine until "policies that must be evaluated at runtime by components other than the semantic layer". RBAC plus task-based access across nono, sit-cip and Nexus is that case. Three systems must evaluate one rule: the user's roles, intersected with the agent's grants, intersected with what the task type allows.

Today each system hand-codes its checks: inline route checks in sit-cip, `access.py` in Nexus, and `ApprovalBackend` plus profiles in nono.

## 2. Decision

**Adopt Cedar as the program policy engine, embedded in each system, with one shared schema and policy set in `fiskroad/contracts/authz/`. There is no central policy decision service in v1.**

- **nono** embeds the Rust `cedar-policy` crate behind a Cedar-backed `ApprovalBackend`.
- **sit-cip and Nexus** embed the Python bindings behind one `authorize(action, resource)` entry point.
- Policies are tested in CI by `tools/authz_check.py`: schema validation, catalogue lint, golden fixtures, and a fail-closed check.

## 3. Alternatives Considered

- **OPA / Rego.**
  - For: the most mature general engine, with a large ecosystem.
  - Against: in Rust it needs a sidecar or Wasm, and Rego is harder to review.
  - Rejected for now; revisit with Kubernetes admission control.
- **OpenFGA (Zanzibar-style relationship authorization).**
  - For: strong for record sharing.
  - Against: needs a service and a datastore, and is weak for per-task conditions. Nexus's team, owner and private rules fit in a dozen Cedar policies.
  - Rejected now (revisit trigger R-3 in the spec).
- **Keep hand-coded checks.**
  - For: no new dependency.
  - Against: three implementations of the intersection rule drift apart, and none can be tested against shared fixtures.
  - Rejected.

## 4. Rationale

1. **Native fit.** Cedar is written in Rust, which suits nono, and has Python bindings for the other two systems.
2. **Matches the program's posture.** Policies are schema-validated and analyzable. Cedar denies by default and `forbid` overrides `permit`, which matches "structurally unapprovable" for `regulated-identifier`.
3. **No new runtime service.** Embedded evaluation over one shared policy set gives consistency without adding a component.

## 5. Consequences

- `contracts/authz/` is created with the schema, policies, role catalogue, task types and fixtures. A policy change is a contract change, reviewed in fiskroad and in each affected repository.
- Each system vendors `contracts/authz/` at a pinned commit and records it in `VENDORED.md`.
- **Residual:** policies are only as current as each system's vendored copy. Version drift is caught by vendoring checks, not at runtime.

## 6. Revisit Triggers

- More than about 5 systems evaluate policy, or policies need data no single system holds: consider a central decision service.
- Kubernetes admission control enters scope: re-evaluate OPA.

---

## Ratification Record

| Field | Value |
|---|---|
| Decision | **Ratified**: Cedar, embedded, one shared policy repository, CI-tested (§2) |
| Date | 2026-11-10 |
| Ratified by | Oscar Mack, program lead (architecture and risk decisions) |
| Session | Access-control decisions session, 2026-11-10, with the nono, sit-cip, Nexus and popeye owners. Recommendation accepted as written. |
| Change control | Replacing the engine, or adding a central decision service, requires a new decision record |
