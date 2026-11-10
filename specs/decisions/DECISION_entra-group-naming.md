# Decision Record: Naming the Entra Groups for Every Role (D-6)

| Field | Value |
|---|---|
| Status | **Ratified 2026-11-10** |
| Date | 2026-11-10 |
| Owner | Program lead |
| Components affected | Entra tenant; `contracts/authz/roles.yaml` (`entra_group` fields); olive and bluto (open role names) |
| Related | `FISKROAD_ACCESS_CONTROL_RBAC_TBAC_v0.1.md` §4.1, §9 D-6; `FISKROAD_STATUS_2026-10-21.md` item 12; `DECISION_nexus-identity-provider-entra.md` |
| Supersedes | — |

---

## 1. Context

Every role in the catalogue (`contracts/authz/roles.yaml`) is assigned through an Entra group, never to individual users. No groups are named yet. Two older role names are also still waiting on Entra groups: `role:case_supervisor` (olive) and `role:identity_steward` (bluto).

## 2. Decision

**Name the Entra groups for every role in Phase 1, including `role:case_supervisor` and `role:identity_steward`, and record each name in the `entra_group` field of `contracts/authz/roles.yaml`.**

- Privileged roles (`privileged: true`) use PIM for Groups: eligible assignments only, with no permanent members (REQ-AC-08).
- The naming convention is chosen in Phase 1 together with the tenant's directory administrators, so it matches existing group conventions.

## 3. Alternatives Considered

- **Name them now.**
  - For: removes an open item immediately.
  - Against: names would be chosen before the app registrations exist and without the directory administrators.
  - Rejected in favour of doing it in Phase 1 alongside the registrations.

## 4. Consequences

- `roles.yaml` keeps `entra_group: null` until Phase 1. CI does not require the field until then.
- `role:case_supervisor` and `role:identity_steward` should be added to `roles.yaml` when olive and bluto adopt the catalogue.

---

## Ratification Record

| Field | Value |
|---|---|
| Decision | **Ratified**: groups named in Phase 1, recorded in `roles.yaml` (§2) |
| Date | 2026-11-10 |
| Ratified by | Oscar Mack, program lead (architecture and risk decisions) |
| Session | Access-control decisions session, 2026-11-10. Recommendation accepted as written. |
