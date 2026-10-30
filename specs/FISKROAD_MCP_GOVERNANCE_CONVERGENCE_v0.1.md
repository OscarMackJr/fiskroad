# MCP Governance: Three Assets, One Chokepoint — Convergence Note v0.1

Version: 0.1
Status: Alignment note — charters no engineering. Its output is §5's decisions, made by humans.
Audience: program lead; olive, nono, and zt-infra maintainers
Relationship: connects `OLIVE_CHARTER_v0.4` §5, `NONO_v0.4` §2 / `NONO_AGENT_RUNTIME_CHARTER_v0.1`, and zt-infra's MCP gateway; presumes `POPEYE_v0.4` agent principals.
Primary post-read action: schedule one three-team session and walk §5 top to bottom. Every question in it is an ownership question, not a design question — which is why a note, not a spec.

---

## 1. The Observation

The program owns three MCP-relevant assets that were built or specified independently and currently do not know about each other:

| Asset | Where | State |
|---|---|---|
| An **MCP zero-trust gateway** | zt-infra | **Built** — sitting in the parallel federation track, unconnected to the program |
| **Tool policy** — which tools an agent may invoke, with what limits | olive charter §5 | **Chartered, deferred** — "the general contract is written now and implemented later"; POC-2 governs only olive's own action tool |
| **Local MCP egress control** — which tool servers a workstation agent may reach | nono v0.4 §2 (+ agent-runtime charter) | **Specified** |

Separately, popeye's v0.4 refusal list already records the placement rule: the gateway will not absorb tool governance — *"Have the gateway decide which tools an agent may call" → olive.*

So the program has, without planning it: an enforcement artifact (zt-infra), a policy owner (olive), an endpoint edge (nono), and a written rule about who must NOT own it (popeye). What it lacks is the sentence connecting them.

## 2. Why Connect Them Now

Three external facts make this the right moment rather than a someday:

1. **MCP won.** It is the de-facto standard for agent-to-tool connectivity — every major vendor adopted it, and enterprise MCP traffic is becoming the substrate of agent work. Governing agents without governing MCP is governing the minority of what agents do.
2. **Its security model is publicly behind its adoption.** National-level guidance (NSA, May 2026) says exactly that, and the early-2026 CVE wave against MCP servers and infrastructure made the risk concrete. "MCP gateway" is now a recognized control-plane category precisely because the protocol needs one.
3. **The program's own POC-2 thesis predicts this.** "From answers to actions" says the frontier is agents acting through tools. Tool traffic is where that action happens; leaving it ungoverned while metering model traffic is governing the receipt and ignoring the transaction.

And one internal fact: **most of the work is assembly, not construction.** The expensive artifact (a working MCP gateway) exists. What's missing is wiring it to the policy owner and the identity model — which is exactly the kind of seam this program is good at, because the seams are contracts.

## 3. The Proposed Shape ("popeye, but for tools")

One sentence: **agent tool traffic passes through an MCP chokepoint that enforces olive's policy under popeye's identity, with nono covering the local edge — and tool calls get the same treatment model calls got in POC-1: identified, allowlisted, metered, recorded, content-free.**

Responsibilities, mapped to the existing invariant style:

- **The MCP gateway (zt-infra's artifact)** is transport enforcement: authenticates the agent principal, resolves its tool grants, allows/refuses/rate-limits tool calls, emits records. It is **semantics-light**: it enforces *which tool, how often, for whom* — never what the call means.
- **olive** owns the policy the gateway enforces: per-agent tool grants, the intersection-with-`on_behalf_of` rule (vocabulary §3.2), rate limits, and the record shape. olive remains the *only* place tool meaning lives.
- **popeye** contributes identity only: the short-lived agent-principal keys are the credential the MCP chokepoint authenticates. popeye's refusal list is unchanged — it never sees tool traffic.
- **nono** enforces the same allowlist at the workstation edge, so a local agent cannot reach tool servers the chokepoint would refuse — closing the bypass that network position alone can't see.
- **Records:** tool-call records carry `run_id`, agent, tool, outcome — never arguments (olive charter §5 rule, now applied at the gateway). They land in **olive's execution/tool ledger, not the spend ledger** — `POPEYE_v0.4` §6 already settled that tool calls are not model calls.

The result completes G2's third leg with mostly-existing parts, and gives the traced-refusal demo (beat 4) a tool-traffic twin: *an agent's out-of-grant tool call, refused at the chokepoint, with the refusal auditable.*

## 4. What This Deliberately Does Not Do

- **Does not move tool semantics into any gateway.** Grants and meaning stay in olive; the chokepoint evaluates grants it is handed. The popeye lesson, applied forward.
- **Does not inspect tool-call payloads.** Same boundary as nono and popeye: identity, destination, rate, outcome — never content.
- **Does not build a tool registry product or third-party MCP marketplace integration.** The olive charter deferred these; the deferral stands.
- **Does not touch federation.** zt-infra's cross-org mission is unchanged; this borrows one artifact, it does not drag the federation timeline forward.

## 5. The Decisions (the actual point of this note)

1. **Ownership of the artifact.** The MCP gateway code lives in zt-infra, a public repo on the federation track. Options: (a) extract into the program (new module or into olive's repo) — clean ownership, real migration cost; (b) zt-infra ships it as a consumable component with olive as its policy source — no move, but the program takes a dependency on the parallel track; (c) treat zt-infra's as reference and reimplement thin inside olive. Recommendation: **decide on inspection** — the artifact's coupling to the rest of zt-infra determines which is cheap, and nobody has inspected it with this question in mind.
2. **Trace linkage.** Tool records carry `run_id` — do they *also* become referenceable from ATE runs (a `toolCalls` count or ref on the run object)? Belongs in the ATE v0.4 joint review agenda, not decided here.
3. **Sequencing.** Options: POC-2 stretch (govern the one olive tool through the real chokepoint instead of in-process) vs POC-3 opener. Recommendation: **spec now, build as the POC-2 stretch only if the core beats are green early** — the entry-criteria discipline outranks the trend.
4. **Public-repo hygiene.** If the artifact stays in zt-infra while serving the program, the standing rule (no internal identifiers in the public repo) needs a checked seam: program config injected, never committed.
5. **Naming.** "MCP chokepoint" here; if it becomes a module it needs a codename, which is the lead's call, as always.

## 6. One Session To Move This

Attendees: program lead + olive, nono, zt-infra maintainers. Agenda: §5 in order; inspect the zt-infra artifact together for decision 1; leave with an owner per decision. Ninety minutes. The note has done its job when that meeting is booked.
