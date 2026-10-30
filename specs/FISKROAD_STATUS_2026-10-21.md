# Fisk Road: Where Everything Stands

Date: 2026-10-21 (updated 10:25; roadmap proposals added 2026-10-26)
Audience: Oscar (program lead)
Basis: the decision records, specifications and runbook produced or ratified up to this morning, plus the bluto owner's status report and the olive and bluto reviews and ratification of IR-1 (2026-10-21). Where implementation status was never reported to me, this note says **unconfirmed** rather than guessing.

---

## The short version

- **olive and Liam aren't waiting on any decision.** Every spec decision needed to start building them has been ratified. **bluto is the exception:** it's architecture-ready but needs internal decisions (merge/split semantics, database placement, referential keys) and a certified work package before its v1 build starts.
- What remains is three kinds of blocker: **external** (the network team, a divisional write agreement), **implementation** (nono, popeye and hometown work not yet built) and **two meetings, in order**:
  1. **the ATE v0.3 joint session** (hometown and bluto, about an hour). It approves the identity fields and names the HMAC key owner, and it's hometown v0.4's prerequisite;
  2. **the ATE v0.4 joint review**.
- **Liam is not on hold.** It can be built and tested now against stand-in services. Only *real-session* runs are blocked, waiting on nono.
- **The two sessions are the highest-leverage next steps.** v0.3 unblocks hometown's v0.4 work and moves POC-2 entry criterion 1 forward. v0.4 settles hometown's endpoints, the popeye token dependency and the olive–Liam contract review.
- **bluto's review queue is olive's, and it's now contracted.** IR-1 and bluto spine v0.1.1 were **ratified 2026-10-21**, with both owners' approval. This fixes the v1.1 integration shape only; live traffic waits on popeye, a named steward group and two open questions.

---

## Component by component

### popeye (AI gateway)

| | |
|---|---|
| **State** | Azure infrastructure applied in `eastus2` and running |
| **Blocked on** | The network team: VNet and subnet addresses, how internal callers reach the internal load balancer, outbound access to the model providers, and a stable internal DNS name. Until the path exists, nobody can reach the gateway, so POC-1 measurement can't start |
| **Specified, implementation unconfirmed** | v0.4.1–v0.4.3: the agent key exchange, introspection, hometown relaying model calls on an agent's key, `direct_gateway`, `key_id` as a UUID. Liam's spec lists these as assumption A3, "ratified, implementation unconfirmed" |
| **New dependency, not yet specified** | A service registry plus short-lived olive tokens bound to a tenant and a delegated agent, with introspection for hometown (olive record §17.1). popeye **acknowledged** it on 2026-10-20 as proposed. It needs a popeye spec and ratification before anyone builds it. **Now also needed for bluto:** a registry entry with tenant-scoped tokens and no delegated agent, so bluto can call olive's queue (IR-1 §4). **Not yet raised with popeye**; stub-only until then |
| **Drafts** | Model-selection policy v0.1 (draft) |

### nono (Windows endpoint sandbox)

| | |
|---|---|
| **State** | Under development (your Windows fork) |
| **Specified, implementation unconfirmed** | v0.4.1–v0.4.3: issuing and injecting the agent session key, the `AgentKeyInjection` census row, `AgentSessionRecord`, `SessionEndRecord`, and `endpoint-detection/0.1` events. Liam's spec lists these as assumption A4 |
| **Open items owned by the nono owner** | **O7**: the `token_arm` value for an AppContainer launch, plus review of Liam's expectancy table. **This is what blocks Liam's real runs.** **A5**: confirm nono puts `http://127.0.0.1:<port>` (not `localhost`) in the child's proxy variables. Also open: O2 (whether DSSE signing becomes required) and O3 (receipt directory and ACL) |

### hometown (semantic layer and answer provenance)

| | |
|---|---|
| **Spec** | `HOMETOWN_v0.4.1` (aligned with Liam v0.4.1) is ready to commit on `contract/ate-v0.4`. §2.5 (trace resolution) and §2.6 (agent answer endpoint) are agreed with olive and Liam, but still **proposed** until the joint review |
| **Prerequisite** | **ATE v0.3 identity fields** merged before v0.4 work begins: `HOMETOWN_CORRECTIONS_ATE_v0.3.md` §3 (an optional `identity` object with `partyIds` and `rulesetVersion`, plus a per-evidence `partyId`). It needs **explicit joint hometown–bluto approval**, not yet given. The repository was last seen at `ate/0.2` |
| **To build** | An HTTP server, which hometown doesn't have today; row-level security on `answer_trace`, which doesn't exist; the agent answer and resolution endpoints; purpose masking (§4, the largest slice); definition provenance (§3); source-health monitoring (§5) |
| **Known gap** | No Cube profile for the ledger (`cube/docker-compose.gateway-poc.yml` is missing, confirmed in your clone). It blocks the chargeback step of the POC-1 smoke test |
| **Open for the review** | `ate/0.2` traces; the program-level record of the invariant 4 exception; the feature tag name; where `appId`/`featureTag` come from; whether refused requests produce traces |

### olive (action broker and review queue)

| | |
|---|---|
| **Decisions** | `DECISION_olive-poc2-phase1` v0.5.2: §1–§17 **ratified**. The component, its boundary and Phase 1 are approved |
| **Can build now** | All of Phase 1, simulation only: the proposal API, policy checks before queueing, the queue and web UI, Postgres with row-level security, the trace check (against fixtures), the proposal-hash check, and the popeye token client (against a stub) |
| **Blocked for the live trace check** | hometown's server (§2.5–§2.6) and popeye's service tokens |
| **Blocked for Phase 2 (real writes)** | A signed divisional write agreement, a named credential owner, and CTO and CSO sign-off |
| **Open** | The Entra group for `role:case_supervisor`; publishing the v1 contract and the S-OL-1 → v1 compatibility review (with the Liam owner and James O'Meara) |
| **Queue item contract for bluto** | **IR-1** (`QUEUE_ITEM_CONTRACT_identity-review_v0.1.md`), olive-owned, **ratified 2026-10-21** (olive and bluto approved). SHA-256 `c993c35e…bff5cf`. olive commits the authoritative copy, with `.gitattributes` `-text`. The queue is built generically in Phase 1; IR-1 registers `kind = identity_review` |

### Liam (Windows desktop agent)

| | |
|---|---|
| **Spec** | Design and test specs v0.4.1, **ratified** (proxy transport 2026-10-20; contract alignment 2026-10-21, Liam's side) |
| **Can build now** | Everything in stub mode, and every `ci-elevated` test: startup self-check, proxy transport, error handling, forwarding the proposal unchanged, evidence records |
| **Blocked for real-session runs** | nono O7 and A5, and nono's implementation of v0.4.1–v0.4.3 |
| **Blocked for end-to-end** | hometown §2.6 ratified and built; olive's v1 contract published and reviewed; popeye v0.4.2 implemented |

### bluto (identity spine)

| | |
|---|---|
| **What it is** | Stable `party_id` mappings across source systems. hometown consumes them read-only for cross-domain joins. Deliberately **not** a golden-record store |
| **Spec** | `BLUTO_IDENTITY_SPINE_v0.1.1`, **ratified 2026-10-21** together with IR-1. It corrects the certified v0.1: no bluto review queue (cases go to olive under IR-1); the baselined queue APIs superseded (§9.1), leaving only a read-only evidence endpoint; a local `review_candidate` record with a deterministic identity and canonical pair order; v1 records candidates without submitting them; a tenant check before every olive call; one link per `review_item_id`; new-ruleset candidates submitted normally, with earlier decisions shown as references; ATE fields cited as v0.3; `tenant_id` as a vocabulary UUID; REQ-ID-12..20 |
| **State** | Architecture and governance ready: the repository baseline, architecture, contracts, security, testing, DevOps and AI-factory controls are certified (Stream 9). **No implementation yet**: no application source, service, schema migration, deployment configuration or test suite. Implementation needs a certified work package; Stream 10 hasn't begun |
| **Blocked on (internal decisions, not other components)** | Approve the identity-resolution model, especially merge/split semantics, before v1 is authorized. Choose dedicated Postgres or a shared schema. Confirm usable CRM and ledger referential keys. Name the data steward, who becomes `role:identity_steward` (needed for v1.1). **Jointly with hometown:** approve ATE v0.3's identity fields and name the HMAC tokenization key owner |
| **Dependencies** | **v1: none.** It records unresolved candidates locally and calls no one. **v1.1:** olive's shared queue (Phase 1) under IR-1; popeye tenant tokens with a bluto registry entry (stub until popeye ships it); a named steward group. **Live value:** hometown, through ATE v0.3 and a working hometown. **nono and Liam:** none |
| **Can build now** | Write the Stream 10 work package against v0.1.1, then a bounded v1 against stand-ins, much like Liam. v1.1's review integration can be built against IR-1 and stubs for olive and popeye |
| **Still to do** | Re-vendor the ratified IR-1 once (new SHA-256 `c993c35e…bff5cf` in `VENDORED.md`). Land the contract-change PR removing the superseded queue APIs from `COMMAND-QUERY-CONTRACTS.md` and `bluto-v1.openapi.yaml`. Confirm REQ-ID-12..20 are free in the baseline. Certify the work package |

**Resolved since the last update:**
- **The review queue is olive's, and contracted.** IR-1 is ratified, with both owners' approval. bluto builds no queue; the item is defined once, in IR-1, which olive owns and bluto vendors with a pinned hash.
- **The ATE version question is settled.** It's **ATE v0.3**, as specified in `HOMETOWN_CORRECTIONS_ATE_v0.3.md` §3, with bluto's review obligations in `BLUTO_ATE_AND_KEY_OWNERSHIP_v0.3.md` §1. bluto v0.1's "ATE v0.2" was stale: v0.2 shipped without the identity half. One change, one version. What remains is the **joint approval**. It's the hometown v0.4 prerequisite and POC-2 entry criterion 1, and it doesn't block IR-1.

**On the Postgres choice:** olive took its own database on the shared POC instance (`deploy-postgres-1`) with row-level security from day one, and a later move to a dedicated server is a connection-string change (olive record §13). bluto could follow the same pattern for v1 and decide on dedicated hosting when it leaves the POC.

### zt-infra

Future work, with no part in this build.

---

## Program-level loose ends

- **POC-1 baselines are not yet measured.** They need popeye's network path, the hometown Cube ledger profile and an in-VNet measurement host.
- **The program charter for POC-2 is still a draft.** olive's Phase 1 runs under a documented exception to its entry criteria (olive record §1).
- **`fiskroad/STATE.md`** needs a line next to invariant 4 pointing to the agent-answer exception.
- **Intern Guide v0.3, task P0.1 step 5,** still has the old Postgres commands. Runbook v0.4.1 is correct.
- **Open questions from IR-1** (no owner action yet):
  - whether untenanted sources (possibly the CRM and the ledger) get an enterprise tenant UUID in the vocabulary;
  - which purpose governs a reviewer's evidence reads through hometown;
  - the reserved `link_challenge` (splits), which waits on bluto's merge/split decision.
- **Divisional write agreement:** not started. The program charter calls it "the long pole" and says to start it during any infrastructure wait.

---

## Proposed roadmap items (2026-10-26)

**Status: proposed, not chartered or ratified.** Each needs a spec and your ratification before anyone builds it. R1–R3 came from reviewing Capgemini's *Rise of agentic AI* report (July 2025, an executive survey). R4–R7 came from Datadog's *State of AI Engineering 2026* (measured customer telemetry, mostly March 2026; reviewed from the web version, because the PDF couldn't be fetched). Each was checked against Fisk Road's current design: they're the places where a report named something Fisk Road doesn't yet have.

| # | Item | The gap today | Proposed shape | Touches | Suggested owner | When |
|---|---|---|---|---|---|---|
| R1 | **Agent kill switch** | Fisk Road can end a *session* (nono revokes the key when a run ends), but nothing stops an *agent* everywhere at once. 48% of organisations in the survey plan one, and the CSO will ask | One recorded command, for example "disable `agent_id = liam`", honoured by every enforcement point: **popeye** refuses the agent's keys and stops issuing new ones; **olive** refuses its proposals and pauses its queued items; **nono** refuses new sessions for it; **hometown** refuses its answer requests. Invoking it, and lifting it, are audited, named-person actions. It must work when one component is down, so each point checks the single registry (R2) and fails closed for that agent | popeye, olive, nono, hometown | popeye (enforcement hub), with a program-level spec in `fiskroad` | Specify alongside R2. Needed before any agent leaves stub mode for real sessions |
| R2 | **Single agent registry** | An agent is registered in **three** places: hometown's agent registration (§2.6: `appId`, `featureTag`, degradation mode), popeye's planned service registry, and olive's agent allowlist. That's the same drift risk as hometown's open "where do `appId`/`featureTag` come from?" question | One registry, owned by popeye, since popeye already issues and checks every agent key and is building a service registry for olive and bluto. Per agent: identity, owner, permitted services and tenants, permitted purposes, maximum autonomy level, attribution (`appId`/`featureTag`), status (`active`, `disabled`, `retired`), and its lifecycle: onboarding, review and retirement as reviewed changes. hometown and olive read it rather than keep their own copies | popeye (owner); hometown §2.6 and olive's allowlist become readers | popeye | **Fold into the service-registry spec popeye is already being asked to write** (olive record §17.1; IR-1 §8), so it's one spec, not two. Resolves hometown §2.6's open item at the same time |
| R3 | **Agent incident response** | The runbook covers infrastructure failures, but has no procedure for an agent behaving badly: wrong proposals, unexpected traffic, a suspected compromised endpoint | A runbook section and a short playbook covering: who may trigger the kill switch (R1), and on what signals (nono detections, `trace_proposal_mismatch` from olive, spend spikes in the ledger, steward rejections); what evidence to preserve (nono receipts and session records, traces, ledger rows, olive proposals and decisions, Liam run records), and the join keys that tie them together; how a run is reconstructed from the records alone; who is told (the CSO; the CTO for anything customer-facing); and how the agent is re-enabled. A tabletop exercise against a stub run before the first real session | Runbook; every component's evidence | You, with the CSO's team | Draft once R1 is specified; rehearse before real-session runs |
| R4 | **Model retirement in the approved-model list** | popeye's registry and the model-selection policy (v0.1, draft) say how a model gets **approved**, not how it's **retired**. Datadog finds teams add models fast and retire them slowly, so lists only grow | Each registry entry gains a lifecycle: `approved_from`, `sunset_on`, and a `successor` within the same routing group. After `sunset_on`, explicit requests for the model are refused with a distinct error naming the successor, and routing stops selecting it. Retirement is a reviewed registry change, like approval. Ledger reporting shows each model's traffic in its last 30 days, so retirement isn't a surprise | popeye (registry, selection policy) | popeye | Add to the model-selection policy before it's ratified; it's a few fields and one rule |
| R5 | **Request-rate and token-rate caps per agent** | popeye's budgets limit **spend**, not **rate**. Datadog finds rate limits are the main cause of LLM failures (60% of errors in February 2026), and that retries and bursts in agent loops turn throttling into sustained outages | Each agent's registry entry (R2) carries requests-per-minute and tokens-per-minute caps, enforced by popeye on the agent's session keys. A capped request gets a 429 that is distinguishable from both provider throttling and budget refusal. The kill switch (R1) gains a softer setting, **throttle**, which lowers an agent's caps rather than disabling it | popeye; the registry (R2) | popeye | Specify with R2. LiteLLM supports per-key rate limits; the spec decides values and the error shape |
| R6 | **Two more POC-1 baseline numbers** | The baseline document measures latency, freshness, counter lag and reconciliation, but not **why requests fail** or **how much prompt caching saves**. Datadog finds system prompts are 69% of input tokens, yet only 28% of calls benefit from caching | Add two measurements to `STAGE1_BASELINES.md`: (a) **errors by cause**: provider throttling versus budget refusal versus other, as a share of requests; (b) **cached share of input tokens**, from the ledger. Each with the usual achievable-or-not sentence. For hometown, a design note: put the fixed part of each prompt template first, so provider caching can work | Intern Guide and the measurement protocol; hometown's prompt templates | POC lead (measurements); hometown owner (template note) | Now: these are measurement tasks, with no new code. Confirm first which cache fields the ledger records |
| R7 | **Guardrail: no content-carrying logging integrations** | The no-content rule is enforced in the **ledger** (prompt storage off), but LiteLLM can also send logs to outside observability tools, Datadog among them. Turning one on would ship prompt and response text out of the program, with nothing in the ledger showing it | popeye's config validation, in CI and at startup, refuses any configured logging callback or integration that can carry request or response content, unless it's on a reviewed allowlist configured to send metadata only. A test proves a config containing such a callback fails validation. Check the exact integration names against the LiteLLM version popeye pins | popeye (config validation, CI) | popeye | Now; it's small and closes a quiet leak path before anyone enables observability |

**How they fit together:**
- **Agents:** R2 is the record, R1 is the switch on it (with R5's throttle as its softer setting), and R3 is the procedure for using the switch. Specify R2, R1 and R5 together inside popeye's planned registry spec; R3 follows.
- **Models:** R4 belongs in the model-selection policy.
- **Now:** R6 and R7 are small and can start immediately.

**Ideas from the same review, not yet proposed:**
- an autonomy level on each olive action type, alongside `reversible`;
- reporting proposal approval rates as a trust measure;
- a mapping of Fisk Road's evidence to ISO/IEC 42001's controls, for the CSO.

---

## What can happen now, in parallel

None of these waits on another.

| # | Work | Who | Unblocks |
|---|---|---|---|
| 1 | **Schedule the ATE v0.3 joint session first** (hometown and bluto, about an hour): approve the identity fields and name the HMAC key owner | You | hometown's v0.4 prerequisite; POC-2 entry criterion 1; bluto's live value |
| 1b | **Then the ATE v0.4 joint review** (bluto, olive, Liam owner, popeye; James O'Meara independent) | You | hometown §2.5–§2.6 ratified, closing Liam A1; the popeye token dependency agreed; olive's compatibility review |
| 2 | **Build olive Phase 1**, simulation only | olive implementer | The beat 2 and beat 4 demos, against fixtures |
| 3 | **Build Liam v0.4.1** in stub mode; get the `ci-elevated` suite green | Liam implementer | Liam is ready the day nono delivers |
| 4 | **Commit `HOMETOWN_v0.4.1`**; merge ATE v0.3 once the joint session approves it | hometown owner | hometown's v0.4 work can begin |
| 5 | **hometown work that doesn't depend on the review**: row-level security on `answer_trace`, and the Cube ledger profile | hometown owner | The server's start condition; the POC-1 chargeback step |
| 6 | **popeye: write the service-registry and token spec**, covering olive (delegated-agent tokens) **and bluto** (tenant tokens, no delegated agent). Spec work doesn't need the network. Also confirm how much of v0.4.1–v0.4.3 is implemented | popeye owner (**raise the bluto entry with them**: it's now a ratified dependency of IR-1) | olive's live trace check; any live bluto–olive traffic |
| 7 | **nono: close O7 and A5**; continue the v0.4.1–v0.4.3 implementation | nono owner | Liam's real-session runs |
| 8 | **Chase the network team** on the popeye path and the stable DNS name | You | POC-1 measurement |
| 9 | **Start the divisional write agreement** | You | olive Phase 2 |
| 10 | **bluto: certify the v1 work package.** Decide merge/split semantics, Postgres placement and the CRM/ledger keys; then a bounded v1 build with stand-ins | You and the bluto owner | bluto Stream 10; a real identity spine for hometown's cross-domain joins |
| 11 | **Finish IR-1 housekeeping**: bluto re-vendors the ratified file and lands the PR removing the superseded queue APIs; olive commits the authoritative copy. *(Contract ratified 2026-10-21.)* | bluto and olive owners | bluto's Stream 10 work package; olive's queue gains its second consumer |
| 12 | **Small items**: name the Entra groups for `role:case_supervisor` (olive approvals) and `role:identity_steward` (bluto identity review); add the invariant 4 line to `fiskroad/STATE.md`; fix Intern Guide P0.1 step 5; send the CTO and CSO note and the popeye note, if they haven't gone | You | Removes small blockers before they become big ones |
| 13 | **Fold R1 (kill switch), R2 (single agent registry) and R5 (rate caps) into popeye's registry spec request; R4 (model retirement) into the model-selection policy; start R7 (logging guardrail) now.** Add R6's two metrics to the POC-1 baseline plan. Ask the CSO's team to co-own R3 (incident response). *(Proposed items: see above)* | You, then the popeye owner and the POC lead | One spec instead of three registries; a kill switch and rate caps before real sessions; a closed content-leak path |

## Critical paths

- **POC-1** (observation): the network team → popeye reachable → Cube ledger profile → measurements → baseline document.
- **hometown v0.4 and bluto live value** (now shared): ATE v0.3 joint session → ATE v0.3 merged → hometown v0.4 work, and bluto's party IDs in traces → the cross-domain demo. bluto v1 itself runs in parallel (work package → build). v1.1's review rides on olive's queue and popeye's tokens.
- **POC-2 end to end** (Liam → hometown → olive): the ATE v0.3 session → the ATE v0.4 review → hometown server and row-level security → popeye tokens → nono O7 and its implementation. These run in parallel; the slowest of the last three sets the date.
- **olive real writes**: the divisional write agreement, which is calendar-bound, not engineering-bound.
