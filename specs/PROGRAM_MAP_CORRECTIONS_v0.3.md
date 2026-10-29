# Program Map Corrections v0.3

Version: 0.3
Status: Draft — closes cross-repo finding X7
Repository: fiskroad. Audience: CTO, program coordinator.
Primary post-read action: complete the four items in section 2; total effort is under an hour and all of it is front-door credibility for the partner review.

## 1. The Finding

The program's own map does not match the program. The coordination repository is unpublished, its repository manifest points at the wrong organization for three of five projects, and its glossary asserts a documentation convention that two member projects do not follow and one member never adopted. Reviewers will be handed exactly these URLs; the first thing they will test is whether the map is true.

## 2. Corrections

**M1 — Publish the fiskroad repository.** `github.com/oscarmackjr-twg/fiskroad` (or the org the program settles on), visibility to match the review audience. Until it exists, `bootstrap.sh`, `.repos.yml`, and every cross-reference into `fiskroad/specs/` are instructions pointing at nothing, and the vocabulary conformance checks in `PROGRAM_SHARED_VOCABULARY_v0.3` must vendor rather than fetch.

**M2 — Correct `.repos.yml`.** `hometown`, `popeye`, and `bluto` live under `OscarMackJr`, not `oscarmackjr-twg`. Every private-repo URL in the manifest is currently wrong. Fix the URLs, remove the `# confirm before first use` markers as each is verified by an actual clone, and add `fiskroad` itself as the first entry once M1 is done.

**M3 — Complete popeye's roadmap rename.** `specs/ROADMAP_integration_popeye.md` → `specs/ROADMAP.md`, with `specs/README.md` and `STATE.md` references updated — the same consolidation hometown completed. (Popeye-side task; tracked in popeye's v0.3 spec, listed here because the glossary claim depends on it.)

**M4 — Make the glossary honest about conventions.** Replace the universal claim with the true statement: *projects chartered under Fiskroad keep `specs/ROADMAP.md` and `specs/STATE.md`; member projects that predate the program (nono: `.planning/`; zt-infra-full: `docs/`) keep their native conventions, and the manifest records where each project's roadmap and state live.* Add a `roadmap:` and `state:` path field per entry in `.repos.yml` so tooling reads the manifest instead of assuming the convention.

## 3. Acceptance

| REQ | Requirement | TC | Test criteria | Method |
|---|---|---|---|---|
| REQ-MAP-01 | Every URL in `.repos.yml` clones successfully | TC-MAP-01 | Fresh-machine run of `bootstrap.sh` (or its PowerShell equivalent) clones all listed repos without edits | DEMO |
| REQ-MAP-02 | The glossary's convention claims are true of every listed repo | TC-MAP-02 | For each manifest entry, the declared roadmap and state paths exist | CI or AUDIT |
