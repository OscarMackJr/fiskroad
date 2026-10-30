# Fiskroad

Fiskroad is the umbrella program for TWG's open, composable AI platform.
It is a coordination repository, not a monorepo: the member projects keep
their own repositories, release cycles, reviewers, and licenses, and
Fiskroad holds what belongs to none of them individually.

## The Projects

Five projects have repositories today. A sixth, olive, is chartered and
waiting for its repository.

| Project | Repository | What it owns |
|---|---|---|
| hometown | `hometown` | Enterprise Knowledge Graph: semantic layer, GraphRAG context, governed Cube models, the Answer Trace Envelope |
| popeye | `popeye` | AI usage governance control plane: gateway, virtual keys, budgets, spend ledger, gateway infrastructure |
| bluto | `bluto` | Enterprise identity spine: resolves entity identity across divisional systems so cross-domain context has an auditable join |
| nono | `OscarMackJr/nono` (public) | Windows-native endpoint agent sandboxing and bypass detection |
| zt-infra | `oscarmackjr-twg/zt-infra-full` (public) | Zero-trust agent identity and secure agent-to-agent transport |
| olive | not yet created (codename is a placeholder) | Action broker and review queue: holds the program's one write credential. See `specs/OLIVE_CHARTER_v0.4.md` |

## Why Not A Monorepo

Deliberate, and worth restating whenever someone proposes consolidating:

- nono and zt-infra are public open-source projects with independent
  lifecycles and external contributors. Absorbing them into a private
  monorepo breaks their public identity.
- Sister-organization sharing requires clean, per-project clones. A
  monorepo makes "share popeye without our CRM specifics" hard.
- hometown and popeye have a deliberately stated boundary (one join key,
  one shared vocabulary). A monorepo makes cross-boundary edits
  frictionless, which is exactly what the boundary exists to prevent.
- The repositories have different security postures: popeye holds
  infrastructure with secret references; nono is public.

Repositories map to deployables and ownership boundaries. Fiskroad maps
to the program.

## What Lives Here

- `specs/` — program-level design artifacts that span projects:
  - strategy and requirements: the portfolio and gap analysis, the
    component gap assessment, the roadmap requirements, the architecture
    evaluation, and the commercial components and timing record;
  - the shared vocabulary (v0.3, v0.4) and the glossary;
  - cross-component specs: the NONO and POPEYE v0.4 series (v0.4.1–v0.4.3
    are ratified; v0.4 is the base draft), the OLIVE charter, and the
    cross-component execution spec, which turns the ratified package
    into per-component work orders;
  - alignment notes: MCP governance convergence, regulated data controls,
    unstructured retrieval scope, and the v0.3 corrections;
  - POC operations: the POC readiness inventory and dated status reports
    (`FISKROAD_STATUS_<date>.md`).
- `specs/decisions/` — cross-project decision records only. Decisions
  internal to one project live in that project's repository.
- `contracts/` — shared machine-readable contracts, starting with
  `vocabulary.yaml`. The shared schemas aren't here yet; see
  `contracts/README.md` for the extraction trigger and current authority.
- `docs/` — onboarding material, the team orientation note, diagrams.
- `tools/` — workspace bootstrap and cross-repo helper scripts.
- `.repos.yml` — the manifest of member repositories.
- `STATE.md` — program-level state. Each project keeps its own.

## What Does Not Live Here

Project roadmaps, project STATE files, application code, Terraform, and
project-internal ADRs. If a document is about one project, it belongs in
that project's repository. Fiskroad holds the seams, not the parts.

## Getting A Workspace

```bash
./tools/bootstrap.sh          # clones every repo in .repos.yml into workspace/
```

`workspace/` is gitignored. It exists so a developer — or an agent
session — can see every project at once without any of them becoming
a submodule of the others.

## Orientation Path For New People

1. `docs/ORIENTATION.md` — what the program is, in one page.
2. `specs/GLOSSARY.md` — the codenames, stages, and POC letters.
3. `specs/PROGRAM_ROADMAP_REQUIREMENTS_v0.1.md` — requirements, objectives, and test criteria: what must be true and how we prove it.
4. `specs/ECOSYSTEM_PORTFOLIO_AND_GAP_ANALYSIS_v0.1.md` — the strategy.
5. The latest `specs/FISKROAD_STATUS_<date>.md` — what's ratified, what's blocked, and the next steps.
6. `specs/CROSS_COMPONENT_EXECUTION_SPEC.md` — if you're implementing, your component's work order.
7. The `STATE.md` and roadmap of whichever project you join. `.repos.yml` lists where each project keeps them.
