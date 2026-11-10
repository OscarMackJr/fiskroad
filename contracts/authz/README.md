# contracts/authz/

The program's shared authorization contract: one Cedar schema and policy
set that nono, sit-cip and Nexus each evaluate in-process.

- Spec: `specs/FISKROAD_ACCESS_CONTROL_RBAC_TBAC_v0.1.md` (§4.3, §6)
- Ratified by: `specs/decisions/DECISION_policy-engine-cedar.md` (D-1) and the
  related decisions D-2 to D-6 in `specs/decisions/`

| Path | What it holds |
|---|---|
| `schema.cedarschema` | Entity types (User, Agent, Application, Role and each system's resources), the task binding, and every action |
| `policies/common/` | Program-wide guards: agents need a task binding, never read `regulated-identifier`, never write Nexus directly, never administer nono |
| `policies/<system>/` | Each system's RBAC rules and its agent (TBAC) rules |
| `roles.yaml` | The role catalogue: human roles per system (Entra app roles), agent grants, application roles |
| `task_types.yaml` | Registered task types, seeding popeye's agent registry |
| `fixtures/*.json` | Golden allow/deny cases per system |

## How a decision is made

Effective permission for an agent request is the intersection of:

1. the delegating user's roles (`on_behalf_of`),
2. the agent's own grants,
3. what the task type allows, and
4. the task instance's scope (tenant, team, owner).

Each factor can only narrow the result. Cedar denies by default, and a
`forbid` overrides any `permit`. Task expiry and revocation are enforced by
popeye introspection before a request reaches policy.

## Checking changes

```
pip install cedarpy==4.12.2 pyyaml
python tools/authz_check.py
```

The check validates every policy against the schema, confirms that every
role and task type a policy names is in the catalogue (at most 6 human roles
per system), runs every fixture case, and confirms an empty policy set
denies them all. CI runs it on every pull request that touches this
directory (`.github/workflows/authz.yml`).

## Consuming repositories

Vendor this directory unchanged at a pinned commit and record the commit in
`VENDORED.md`, as with `contracts/vocabulary.yaml`. A policy change is a
contract change: it is reviewed here and in each affected system's
repository.
