# Fiskroad

Fiskroad is the umbrella program for TWG's open, composable AI platform.
It is a coordination repository, not a monorepo: the member projects keep
their own repositories, release cycles, reviewers, and licenses, and
Fiskroad holds what belongs to none of them individually.

## The Five Projects

| Project | Repository | What it owns |
|---|---|---|
| hometown | `hometown` | Enterprise Knowledge Graph: semantic layer, GraphRAG context, governed Cube models, the Answer Trace Envelope |
| popeye | `popeye` | AI usage governance control plane: gateway, virtual keys, budgets, spend ledger, gateway infrastructure |
| bluto | `bluto` | Enterprise identity spine: resolves entity identity across divisional systems so cross-domain context has an auditable join |
| nono | `OscarMackJr/nono` (public) | Windows-native endpoint agent sandboxing and bypass detection |
| zt-infra | `oscarmackjr-twg/zt-infra-full` (public) | Zero-trust agent identity and secure agent-to-agent transport |

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
  the portfolio and gap analysis, the component gap assessment, the
  commercial components and timing record, and the glossary.
- `specs/adr/` — cross-project decision records only. Decisions internal
  to one project live in that project's repository.
- `contracts/` — reserved for the shared contracts package. Not populated
  yet; see `contracts/README.md` for the trigger and current authority.
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
session — can see all four projects at once without any of them becoming
a submodule of the others.

## Orientation Path For New People

1. `docs/ORIENTATION.md` — what the program is, in one page.
2. `specs/GLOSSARY.md` — the codenames, stages, and POC letters.
3. `specs/PROGRAM_ROADMAP_REQUIREMENTS_v0.1.md` — requirements, objectives, and test criteria: what must be true and how we prove it.
4. `specs/ECOSYSTEM_PORTFOLIO_AND_GAP_ANALYSIS_v0.1.md` — the strategy.
5. The `STATE.md` and `specs/ROADMAP.md` of whichever project you join.
