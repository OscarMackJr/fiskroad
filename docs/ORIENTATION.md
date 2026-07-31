# Fiskroad In One Page

**What it is.** An open, composable platform for governed enterprise AI:
four projects that together give the organization a semantic layer for
what AI may know, a control plane for what AI costs and who may call it,
endpoint enforcement on workstations, and secure agent transport.

**Why it exists.** Divisions are deploying AI across two clouds and onto
desktops at once. Without a governed path there is no answer to what AI
costs, who spent it, whether the answers were grounded in governed data,
or when an agent is calling a provider outside any policy. The commercial
answer to this is a single expensive proprietary platform. Fiskroad is
the composable alternative: open components, contracts in git, no lock-in,
and — deliberately — coverage that platform does not attempt.

**The four projects.** hometown governs what AI may know (semantic layer,
provenance). popeye governs what AI may do and what it costs (gateway,
budgets, ledger). nono governs the endpoint (bypass detection).
zt-infra governs agent-to-agent trust (identity, secure transport).

**How they connect.** Applications call popeye's gateway with a virtual
key and attribution headers — that is their entire obligation. popeye
records every request. hometown models that spend as a governed business
domain and, from Stage 4, links each AI answer to the governed evidence
behind it. nono detects traffic that skips the gateway. zt-infra carries
signed context between agents and, eventually, between organizations.

**What we are not building.** A data warehouse, a pipeline platform, a
BI product, or a proprietary ontology. Divisions keep their systems.

**How we work.** Specification-first. Every project has a `specs/`
directory, a roadmap, and a STATE.md that says exactly where things
stand. Contracts are validated in CI. Decisions are recorded before
implementation, with their triggers and their rejected alternatives.
If the specs and the code disagree, that is a bug in one of them — say
so loudly.

**Where to start.** `specs/GLOSSARY.md`, then the portfolio and gap
analysis, then the STATE.md of the project you are joining.
