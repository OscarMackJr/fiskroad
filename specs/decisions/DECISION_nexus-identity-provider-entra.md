# Decision Record: Entra ID as Nexus's Identity Provider (D-5)

| Field | Value |
|---|---|
| Status | **Ratified 2026-11-10** |
| Date | 2026-11-10 |
| Owner | Nexus |
| Components affected | Nexus (authentication, role source); Entra tenant (app registration, groups, PIM) |
| Related | `FISKROAD_ACCESS_CONTROL_RBAC_TBAC_v0.1.md` §4.1, §5 Phase 1, §9 D-5; `contracts/authz/roles.yaml`; `DECISION_entra-group-naming.md` |
| Supersedes | — |

---

## 1. Context

Nexus authenticates with local passwords and HS256 JWTs, with its role stored as one string on the user row. It runs on AWS. The other program systems, and the people who use them, are in the organization's Entra ID tenant. RBAC across nono, sit-cip and Nexus needs one source of roles, groups and just-in-time elevation.

## 2. Decision

**Nexus uses Entra ID (OIDC) as its identity provider, although it runs on AWS.**

- Roles come from the token's `roles` claim, using the app roles in `contracts/authz/roles.yaml`: `nexus_admin`, `nexus_supervisor`, `nexus_principal` and `nexus_user`.
- `nexus_admin` is activated just in time through PIM.
- Local passwords remain only as break-glass access, behind a feature flag, and are disabled by default.

## 3. Alternatives Considered

- **AWS Cognito.**
  - For: native to Nexus's hosting.
  - Against: a second directory, with roles and groups that diverge from the other two systems, and no PIM.
  - Rejected.
- **Keep local passwords.**
  - For: no change.
  - Against: no single sign-on, no PIM, no access reviews, and role assignment in the application database.
  - Rejected.

## 4. Consequences

- **Phase 1 work in Nexus-CRM:**
  - An Entra app registration and the four app roles.
  - OIDC login in the frontend and JWT validation (issuer, audience, signature) in the backend.
  - `User.role` populated from the claim.
  - The existing `POST /api/v1/users` admin flow replaced by group assignment.
- The Nexus org-to-program-tenant mapping (`tenant_id`, vocabulary §1.1) must be set alongside. The tenant-to-Entra mapping is still an open program item.
- **Residual:** Nexus depends on Entra availability for login. Break-glass access covers outages.

## 5. Revisit Triggers

- Nexus moves to serving external parties (customers or sister organizations): evaluate Entra External ID or federation.

---

## Ratification Record

| Field | Value |
|---|---|
| Decision | **Ratified**: Entra ID for Nexus; local passwords as break-glass access only (§2) |
| Date | 2026-11-10 |
| Ratified by | Oscar Mack, program lead (architecture and risk decisions) |
| Session | Access-control decisions session, 2026-11-10. Recommendation accepted as written. |
| Not ratified here | The tenant-to-Entra mapping (still open) |
