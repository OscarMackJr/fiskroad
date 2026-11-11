# Fisk Road: Demo Priorities for the CTO and CSO

Date: 2026-11-11
Audience: Oscar (program lead)
Basis: the planning state in each member repository as of 2026-11-10/11: popeye `.planning/` (phase 01, plan 01-08 held), nono `.planning/` (phase 126.1, plan 99 partial), olive `.planning/` (phase 08 verification), liam `.planning/` (phase 2 blocked), hometown `specs/STATE.md` and its working tree, sit-cip-poc `STATE.md`, and `PROGRAM_ROADMAP_REQUIREMENTS_v0.1.md` §P-S1. No tests were run for this note. Where something wasn't checked, it says so.

Predecessor: `FISKROAD_STATUS_2026-10-21.md` (component-by-component state, proposed items R1–R7).

---

## The short version

- **The CTO demo is the popeye ceremony (plan 01-08), followed by a chargeback query through Cube.** Together they cover the four P-S1 exit criteria the CTO demo was defined around. The ceremony is two small gates away from running.
- **The CSO demo is mostly built already.** olive's beat 2 and beat 4 run today against fixtures. The ceremony's lockdown evidence is the infrastructure half. One olive blocker (CR-01) and one sit-cip security fix need to land first.
- **The endpoint story comes next:** close nono 126.1 with the operator test only you can run, then build a gateway-only bypass profile (REQ-EP-02). That joins nono to popeye without waiting for the agent-key issuer.
- **Keep the agent-key issuer out of these demos** (popeye phases 2–6, the full Liam → hometown → olive chain). It's the right long-term work, but it can't be shown live for months.

---

## 1. CTO demo: the popeye ceremony (plan 01-08)

**What it proves:**

- One synthetic `twg-foundry` completion lands **exactly one attributed ledger row** (MVP-01).
- A user key gets 401/403 on `/key/*`, `/user/*`, `/utils/*`, `/team/*` and `/config/*` (GW-03).
- Budget counters are shared across at least two replicas through Redis (GW-06).
- A revision restart loses no rows (GW-04).

**Gates remaining:**

| Gate | State | Owner |
|---|---|---|
| NET-06: both operators sign in through Bastion | Networking applied the RBAC change on 2026-11-10 and the control-plane check passes; the two sign-ins are pending | Oscar, Oleg |
| Security approval to keep outbound HTTPS open to any destination for the ceremony window | Networking recommended it on 2026-11-04 ("Security to approve"). **No recorded approval found** | Oscar → Security |
| NET-03: env DNS zone not linked to `vnet-popeye-stage1-stage2-eastus2` | Doesn't block the ceremony; not yet sent to networking | Oscar → networking |

Getting Security's approval in writing also brings the CSO's team in before they see the demo.

**Fix before the demo:** plan 01-08 expects an HTTP **422** when a budget runs out (LiteLLM 1.106 behavior). TC-GOV-01, the CTO demo criterion, says "a budget cap produces a clean **429**". Decide which one you'll show and amend the requirement or the evidence, so the CTO doesn't see a mismatch.

Plan 01-09 (final network evidence and evidence index) follows and is paperwork.

## 2. CTO demo: complete the four P-S1 exit criteria

`PROGRAM_ROADMAP_REQUIREMENTS_v0.1.md` §P-S1 defines the CTO demo as four things:

| Criterion | Delivered by | State |
|---|---|---|
| TC-GOV-01: a budget cap produces a clean 429 | Ceremony (01-08) | Ready once the 422/429 question is settled |
| TC-COST-01: attribution end to end, app and user visible | Ceremony (01-08) | Ready |
| TC-COST-03: chargeback query answered through Cube | hometown `ai_token_usage` over the live ledger | **Uncommitted**: see below |
| TC-REL-01: one measured latency baseline | A measurement run from `EUS-VM-POPEYE` | Not started; run it while operator access is open |

**hometown has 24 uncommitted files** on `contract/ate-v0.4` (last commit 2026-10-21), including `cube/model/ai_token_usage.yml`, `scripts/verify-gateway-attribution.mjs` and `scripts/verify-gateway-ledger-model.mjs`. That is the chargeback demo, and it exists only on this machine. Commit it first, then point it at the ceremony's ledger row to answer "spend by app and by user".

That turns "the gateway works" into "we can tell you who spent what, and governance costs X ms".

## 3. CSO demo: mostly built already

| Piece | What it shows | State |
|---|---|---|
| olive beat 2 (`build/demo-beat2.sh`) | Every action traces to a proposal, a policy decision and a named approver (REQ-ACT-01) | Runs against fixtures |
| olive beat 4 (`build/demo-beat4.sh`) | A proposal outside its purpose is refused before any human sees it, and the refusal is traced (REQ-ACT-02) | Runs against fixtures |
| olive identity review (`build/demo-identity-review.sh`) | The bluto identity-review queue, with a value-free transcript | **Hold until CR-01 is fixed** |
| Ceremony security evidence (01-08) | Admin routes locked down; no public IP on the caller VM; RDP only from the Bastion subnet; time-boxed, secret-scoped Key Vault grant; no keys, DSNs or prompts in evidence | Produced by the ceremony |
| Agent kill switch (R1) | The answer to "how do I stop an agent everywhere at once?" | Proposed, not specified. A written design is enough for now; `FISKROAD_STATUS_2026-10-21` R1 notes "the CSO will ask" |

**Fix before the CSO sees it:**

- **olive CR-01** (phase 08 verification, `gaps_found`): the producer poll cursor can skip a reviewer's decision when results are read back. That is silent data loss, and the window widens with several instances. Close it with one gap-closure plan plus a concurrency test, and fold in WR-03. WR-01 is a recorded deviation from D-05/D-07; fix it or ratify it.
- **sit-cip `fix/auth-fail-closed-tenant-scope`** (commit `4a65e86`, 2026-11-10, unmerged): makes the service fail closed without API keys and scopes tenant-less list endpoints. Merge and redeploy before sit-cip appears in front of a CSO.

## 4. Endpoint story: close nono 126.1, then build the bypass demo

**nono 126.1** (agent-key session contract) is on its eighth review round. Plan 126.1-99 is partial: the gate, DCO check and 21-ID audit are done. Task 3, the seventh operator test (`uat-126.1-req-end-25.ps1`, elevated), is a blocking human checkpoint that only Oscar can run. Closing it:

- unblocks Liam phase 2 (real nono sessions; Liam has been stopped at gate 1 since 2026-10-22);
- lets nono 126.2 (v0.4.4 task binding) start executing.

More review rounds now give little return. Run the operator test and close the phase.

**Then a bypass-detection demo (REQ-EP-02, popeye phase 7 success criterion 4):**

- An agent connecting straight to a model provider is blocked and reported as a content-free detection.
- The same call through the gateway is allowed and attributed.

This joins nono to popeye without waiting for the issuer, and it's the most intuitive endpoint demo for a CSO. **Unconfirmed:** no `twg-gateway-only` profile exists in nono yet (`crates/nono-cli/data/` was checked). nono's proxy already enforces host allowlists, so this may be mostly profile work plus the detection event, but check that before committing to a date.

## 5. Not for these demos

| Work | Why it waits |
|---|---|
| popeye phases 2–6 (contracts, gateway hook, fleet keys, agent-key issuer, introspection) | The nono integration gate TC-AGT-21 sits at the end of phase 6; the path is months long |
| Full Liam → hometown → olive end to end (POC-2) | Needs the issuer, nono 126.1 closed, nono O7 resolved, and hometown §2.6 |
| nono 126.2 | Starts only after 126.1 closes, by its own roadmap rule |
| bluto | Specification only; `~/bluto` isn't a git repository |
| zt-infra / POC E | No Fiskroad-driven work in flight |

## 6. Order of work

**This week**

1. Bastion sign-ins by Oscar and Oleg; tick NET-06.
2. Security's written approval for the ceremony's outbound window.
3. Decide 422 versus 429 for TC-GOV-01.
4. Run plan 01-08.
5. Commit hometown's chargeback work.
6. Merge the sit-cip fail-closed fix.

**Next**

7. Cube chargeback query over the live ledger row, plus one latency baseline from the VM. **The CTO demo is complete here.**
8. Fix olive CR-01.
9. Run the nono 126.1-99 operator test and close 126.1.
10. Write the R1 kill-switch design note.

**Then**

11. nono gateway-only bypass profile and detection. **The CSO demo gains the endpoint story here.**
12. Plan 01-09 evidence index; raise NET-03's missing VNet link with networking.

## 7. Working-tree hygiene seen during this review

- **hometown:** 24 uncommitted files on `contract/ate-v0.4` (see §2).
- **nono:** uncommitted changes on `milestone/v2.13-carryforward-closeout`, including `bindings/c/build.rs`, `agent_daemon/mod.rs`, `cli_bootstrap.rs` and the diagnostic formatter files.
- **popeye:** untracked `scripts/Test-PopeyeAzureVerificationVm.zip` on `gsd/phase-02-contracts-decisions-registries`.
- **liam:** uncommitted `profiles/liam.nono.json`.
- **zt-infra-full:** uncommitted changes and an untracked `terraform/backend.hcl`; check it holds no secrets before any commit (the repository is public).
- **fiskroad:** untracked `specs/NONO_POPEYE_SESSION_CREDENTIAL_CONTRACT_v0.1.md` (the canonical contract is v0.2 in `contracts/`).
