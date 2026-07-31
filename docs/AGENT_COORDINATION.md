# Coordinating Multi-Project Changes With Claude Code

How to use agent assistance across Fiskroad's four repositories without
undermining the boundaries that make the program reviewable.

## The Short Answer

Yes. Point Claude Code at `workspace/` after running
`tools/bootstrap.sh` and one session can read and edit across all four
projects — they are ordinary sibling directories, not submodules.
Multiple sessions can run in parallel, isolated by git worktrees.

The constraint is not tooling, it is governance: **the cross-repository
changes an agent is most useful for are exactly the ones our own rules
say need human review.** The patterns below are designed so speed lands
on the safe changes and friction stays on the contract changes.

## Three Patterns, In Order Of Preference

### 1. Single session, coordinated read — the default

Open one Claude Code session at `workspace/`. It can read every
project's STATE.md, roadmaps, and code at once, which is exactly what
cross-project questions need ("does hometown's trace writer match
popeye's ledger schema?", "which repos mention the attribution
vocabulary?").

Best for: analysis, consistency audits, spec alignment, and any change
where understanding both sides is the hard part.

### 2. Single session, coordinated edit — for mechanical fan-out

One session edits several repositories in sequence, then commits each on
its own branch. Correct for mechanical changes with one intent: renaming
a feature tag, updating a shared vocabulary term, propagating a spec
version bump.

Rule regardless of how the edits were made: **one pull request per
repository.** The repos have different reviewers and different CI gates;
a single agent session producing four branches is fine, four repos
sharing one review is not. Link the PRs to each other in their
descriptions.

### 3. Parallel sessions in worktrees — for independent work

Claude Code has first-class git worktree support: each session (or
subagent) gets its own working directory and branch, so parallel edits
cannot collide on the filesystem. Use this when two genuinely
independent tasks are in flight in the same repository — for example,
hometown's Intrepid slice and its `ai_token_usage` model.

Do not use parallel agents to work both sides of a contract at once.
Two agents independently "aligning" popeye's ledger and hometown's trace
schema will each produce something coherent and mutually incompatible.
Contract changes are sequential by design: change the contract, review
it, then adapt consumers.

## The Rules That Do Not Bend

1. **Cross-boundary changes need a human in the middle.** The five
   invariants in `STATE.md` — the join key, attribution vocabulary,
   semantics-out-of-gateway, observation-never-blocks, no-content — are
   reviewed by both affected teams, whoever or whatever drafted them.
2. **One PR per repository, always.**
3. **Agents propose; CI decides.** Every project has a validation gate
   (contract validation, `verify:*` scripts, `terraform plan`). Nothing
   merges because an agent was confident.
4. **Never point an agent session at a repository holding live
   credentials or state.** Terraform state contains generated secrets;
   review plans, do not delegate applies. This is no longer
   hypothetical: popeye's azure-eastus2 region is applied, its remote
   state holds generated gateway and database secrets, and a local
   `terraform.tfvars` sits untracked in the working tree. Agents may
   read `.tf` files and propose changes; `apply` stays human.
5. **Public repositories are public.** nono and zt-infra have external
   contributors and their own conventions. Program-driven changes there
   are proposals to those maintainers, not internal edits.

## Good First Uses

- Consistency audit: "read every STATE.md and roadmap in workspace/ and
  list places the attribution vocabulary is described inconsistently."
- Onboarding: "summarize what hometown owns versus popeye, citing the
  boundary sections."
- Mechanical propagation: a spec version bump referenced across repos.
- Verifier authoring: writing the `verify:*` scripts, which are small,
  well-specified, and CI-checked — the ideal agent task shape.

## Where Human Judgment Stays

Architecture decisions, ADRs, anything touching the five invariants,
security posture changes, and anything that would relax a guardrail.
The specs exist so these decisions are recorded by people and executed
with help — not the other way around.
