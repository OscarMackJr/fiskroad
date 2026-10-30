# Fiskroad POC Operations Runbook

Version: 0.4.2
Status: Draft. Validate every command against the current repositories on first run and correct this document in place.
Audience: POC lead, intern, olive and Liam implementers, anyone restarting the environment
Primary post-read action: complete the prerequisites in §2, then run the startup sequence in §3 in order.

**This document is expected to be wrong in places on first use.** Command names, script paths and connection details drift. When something here does not match reality, fix this file in the same session, on a branch in `fiskroad`. A runbook nobody corrects becomes a runbook nobody trusts.

**Companion documents.** The [Field Guide](FISKROAD_FIELD_GUIDE_v0.4.md) teaches the skills these commands assume. The [Intern Guide](POC_INTERN_GUIDE_v0.3.md) says what to do once the environment is up. `DECISION_olive-poc2-phase1_v0.5.md` (v0.5.2, §1–§17 ratified) is the authority for anything about olive. `HOMETOWN_v0.4.md` §2.5–§2.6 is the authority for hometown's trace-resolution and agent answer endpoints. All of them assume Windows and PowerShell, and all of them live in the `fiskroad` repository: clone it first (§2.1).

**What changed in 0.4.2.** hometown has added the missing ledger Cube profile, `cube/docker-compose.gateway-poc.yml`, pinned to `cubejs/cube:v1.6.64`, as a reviewed change: hometown PR #18, branch `cube/gateway-ledger-profile`, **not yet merged**. §3.3 now covers its `GATEWAY_POSTGRES_*` settings, §5 and §8 are updated, and §10 item 1 is fixed pending merge.

**What changed in 0.4.1.** Brought in line with the olive decision record v0.5.2 and hometown v0.4 §2.5–§2.6 (all agreed 2026-10-20): olive's trace check runs on fixtures and a popeye stub (§3.7); hometown's endpoint server refuses to start without Postgres and forced row-level security on `answer_trace`, which the current trace DDL does not have (§3.2); olive's agent session key goes only to popeye (rule 9); two new known gaps (§10, items 7–8).

**What changed in 0.4.** Three things v0.3 got wrong, and two components it didn't cover:
- **The shared Postgres is not hometown's.** It is the container `deploy-postgres-1`, started by **Nexus CRM's `deploy/` Compose project**, on the Docker network `deploy_default`. Its admin role is `nexus`, not `postgres`. v0.3 told you to run `docker compose up -d` in hometown, which has no root Compose file. Source: hometown `specs/STATE.md` ("Local Shared Postgres Notes") and `cube/README.md`, confirmed by the POC lead on 2026-10-20.
- **The npm script names use colons** (`verify:gateway:access`), not hyphens. Taken from hometown's `package.json`.
- **The ledger grants script lives in popeye** (`popeye/sql/ai_usage_grants.sql`), not hometown. hometown's `sql/` holds only `answer_trace_ddl.sql`.
- **New:** olive's Phase 1 local database (§3.7) and Liam's stub-mode runs (§3.8).
- **Flagged, not fixed (fixed in 0.4.2):** the Cube profile v0.3 used for the ledger, `cube/docker-compose.gateway-poc.yml`, is not in the hometown copy this runbook was checked against. See §3.3 and §10.

---

## 1. What Runs Where

The POC spans four places. Knowing which is which prevents most confusion.

| Component | Location | State | Who starts it |
|---|---|---|---|
| popeye gateway | Azure Container Apps, `eastus2` | **Already running**: applied infrastructure | Nobody. It stays up |
| Gateway ledger (Postgres) | Azure Database for PostgreSQL Flexible Server | Already running | Nobody |
| Gateway counters (Redis) | Azure Managed Redis | Already running | Nobody |
| **fiskroad** (docs and contracts) | Local clone | Nothing to start | **You, first** |
| **Shared local Postgres** | Docker container `deploy-postgres-1`, network `deploy_default`, port 5432 published to the host | Started per session | You, **from Nexus CRM's `deploy/`** |
| hometown Cube | Local Docker, joins `deploy_default` | Started per session | You |
| olive (Phase 1, simulation only) | Local process or container; its own database `olive` on the shared Postgres | Started when olive work is in scope | olive implementer |
| Liam (stub mode only) | Windows workstation | Per test run; real-nono runs are blocked (§3.8) | Liam implementer |
| Local gateway profile | Local Docker | Only for the interruption test (Intern Guide P1.9) | You, with the lead |
| Measurement host | In-VNet VM or job (§6) | Per measurement run | You |
| Desktop AI tool + nono | Windows workstation | Configured once, used per endpoint test | You |
| bluto v1 | Local Docker (when built) | Optional for the POC | You |

**The shared Postgres is shared.** Nexus CRM, Intrepid loan_engine, sit-cip, hometown and now olive all use the same instance. Stopping it stops all of them, and its data is everyone's seed data.

**The Azure environment is live infrastructure.** Never run `terraform destroy`, never run `terraform apply` without the POC lead, and never edit resources in the Azure portal. Local components are disposable; Azure components are not.

---

## 2. Prerequisites

Confirm all of these before the first startup. Missing access is the most common cause of a lost day.

**Tools** (Intern Guide P0.1 step 1 records the versions):

```powershell
docker --version          # Docker Desktop must be running, not just installed
node --version            # match hometown's package.json
git --version
az version --output table
curl.exe --version        # curl.exe specifically: see Field Guide §2.3
psql --version            # optional; every psql step below also has a docker exec form
```

Liam work also needs the Rust toolchain (`rustc --version`, `cargo --version`). Use the version pinned in the liam repository.

**Access:**

- Azure CLI authenticated (`az login`) with read access to the POC subscription.
- **Network path to the gateway.** The Container App has internal ingress only, so you need VPN or a jump path into the VNet. Confirm this on day one: it blocks everything and is not obvious until you try.
- A gateway virtual key issued for your work, plus ledger read credentials for the `ekg_cube_reader` role. Request both from the POC lead. **Never use the gateway master key** for ordinary requests.
- The local password for the `nexus` admin role on the shared Postgres, from whoever owns Nexus CRM's `deploy/` project. It is local-only and synthetic, but it still doesn't get committed.

**Configuration:**

- `hometown/cube/.env` populated from `cube/.env.example`. The hometown verifier scripts read their `GATEWAY_POSTGRES_*` and `CUBE_*` variables from this file (§4.2).
- `olive/.env` populated from olive's `.env.example`, if olive is in scope (§3.7).
- Git line endings configured once: `git config --global core.autocrlf true` (Field Guide §2.2 explains why).
- Session variables in a file **outside any repository**, dot-sourced each session (Intern Guide P0.1 step 2).

**Never commit or paste any credential.** They are gitignored for a reason.

### 2.1 Workspace Layout And Clone Order

Everything lives in one workspace, so cross-repository work has the trees side by side: vendoring the shared vocabulary, checking vendored hashes agree, comparing popeye's registry against the program list.

```
C:\dev\
  poc-env.ps1                    <- your credentials. OUTSIDE every repo. Never committed.
  fiskroad-workspace\
    fiskroad\                    <- clone FIRST
    nexus-crm\                   <- needed for deploy\, which starts the shared Postgres
    hometown\
    popeye\
    olive\                       <- if olive work is in scope
    liam\                        <- if Liam work is in scope
    nono\                        <- if endpoint or Liam real-nono work is in scope
    bluto\                       <- if identity work is in scope
```

`nexus-crm` is a placeholder folder name. Use whatever `fiskroad\.repos.yml` calls the Nexus CRM repository, and correct the paths in this runbook to match.

**Clone fiskroad first.** It is not a component and there is nothing to run in it, but it holds the manifest, the shared vocabulary, the glossary, the decision records and these POC documents. Every other instruction here depends on it:

```powershell
New-Item -ItemType Directory -Force -Path C:\dev\fiskroad-workspace
Set-Location C:\dev\fiskroad-workspace
git clone <fiskroad-url>          # from Section 0 of the Intern Guide
Get-Content fiskroad\.repos.yml   # this tells you what to clone next
git clone <nexus-crm-url>         # required: owns the shared Postgres
git clone <hometown-url>
git clone <popeye-url>
```

**Why you need fiskroad locally, not just as a link:**

- `.repos.yml` is the list of what to clone. Reading it is step one, not step two.
- `contracts/vocabulary.yaml` holds the three POC tenant UUIDs you will seed with.
- `specs/GLOSSARY.md` decodes the codenames, stage numbers and ID prefixes.
- `specs/` holds the component specifications and decision records the olive and Liam work depends on.
- **These POC documents live there.** This runbook and the Intern Guide both tell you to fix them in place when they are wrong. That needs a writable clone and a branch, not a browser tab.

**These are fresh clones from GitHub.** If you already have clones of these repositories elsewhere on the machine, the workspace copies are a *second* set against the same remotes. Work only in the workspace, and never push from a tree that contains your `terraform.tfvars` or any `.env`.

**A note on `bootstrap.sh`.** `fiskroad/tools/bootstrap.sh` is a bash script, so on Windows either run it in Git Bash (it ships with Git for Windows), run it under WSL, or use the manual clones above. The script lives inside fiskroad, so fiskroad must be cloned before it can run. Writing a PowerShell equivalent is a genuinely useful small contribution (Field Guide §1.4).

---

## 3. Startup Sequence

Order matters: each step depends on the one before. §3.1–§3.4 are every session. §3.5–§3.8 are only for the work that needs them.

### 3.1 Shared Postgres (from Nexus CRM)

```powershell
Set-Location C:\dev\fiskroad-workspace\nexus-crm\deploy
docker compose up -d
docker ps --filter name=deploy-postgres-1 --format "{{.Names}}  {{.Status}}"
```

Wait until the status shows `healthy` (or `Up`, if the deploy project defines no health check), rather than assuming. Cube failing to connect because Postgres was still initialising is a classic ten-minute detour.

Confirm the network exists. Cube and olive containers join it:

```powershell
docker network ls --filter name=deploy_default
```

**If someone else already has it running, do nothing.** It is shared; `docker compose up -d` on a running project is harmless, but don't restart it to "be sure".

### 3.2 Grants And Schema

Two scripts, from two repositories, for two different databases.

**Ledger read grants: `popeye\sql\ai_usage_grants.sql`.** These create the `ekg_cube_reader` read path on the **gateway ledger**. Where the ledger lives decides who applies them:
- **Azure ledger (the normal case):** the POC lead applies the grants there. You do not, because you have no write path to Azure.
- **Local ledger** (only with the local gateway profile, §3.5): apply them to that local database. Ask the lead which database name the local profile uses.

```powershell
# Local ledger only: through the container, as the nexus admin
Get-Content C:\dev\fiskroad-workspace\popeye\sql\ai_usage_grants.sql |
  docker exec -i deploy-postgres-1 psql -U nexus -d <local-ledger-db>
```

**Answer trace store: `hometown\sql\answer_trace_ddl.sql`.** Only if answer traces are in scope. It creates the append-only `answer_trace` table, an INSERT-only writer role and `SELECT` for `ekg_cube_reader`:

```powershell
Get-Content C:\dev\fiskroad-workspace\hometown\sql\answer_trace_ddl.sql |
  docker exec -i deploy-postgres-1 psql -U nexus -d <hometown-db>
```

Both are idempotent by design, so re-running them is safe.

**The trace DDL is not enough for hometown's endpoints.** `answer_trace_ddl.sql` creates the table and grants, but no row-level security. hometown's HTTP server, which serves the agent answer endpoint (for Liam) and trace resolution (for olive), **refuses to start** unless the trace store is Postgres with `FORCE ROW LEVEL SECURITY` on `answer_trace` (`HOMETOWN_v0.4` §2.5 rule 5, §2.6). That migration is new hometown work and doesn't exist yet (§10, item 7). The file-backed store still works for hometown's CLI and CI runs, which don't use the server.

**Use `-U nexus`.** The `postgres` role does not exist on this instance, and neither does `loan_app`, even though some loan_engine config files mention them (hometown `STATE.md`). **If the gateway ledger is in Azure, your Cube connection points at Azure**, not the shared Postgres. Confirm with the POC lead; it changes your `.env` and materially changes your freshness numbers.

### 3.3 Cube

First, find out which profiles actually exist:

```powershell
Set-Location C:\dev\fiskroad-workspace\hometown
Get-ChildItem cube\docker-compose*.yml | Select-Object Name
```

hometown's `main` has three profiles: `docker-compose.yml` (a CRM scaffold pointing at `AWS_POSTGRES_CRM_URL`), `docker-compose.intrepid-sandbox.yml` and `docker-compose.intrepid-smoke.yml`. The POC lead's clone confirmed this on 2026-10-20. The fourth, **`docker-compose.gateway-poc.yml`, is the ledger profile** the chargeback query (§4.3) needs. Until hometown PR #18 is merged, it exists only on branch `cube/gateway-ledger-profile` (§10, item 1).

**Before starting it**, fill the ledger connection in `hometown\cube\.env`. hometown's `cube/README.md` ("Gateway Ledger Profile") has the full notes.

| Variable | Azure ledger (normal case) | Local ledger (interruption test only, §3.5) |
|---|---|---|
| `GATEWAY_POSTGRES_HOST` | Flexible Server host, from the POC lead | `deploy-postgres-1`, never `localhost` |
| `GATEWAY_POSTGRES_PORT` | `5432` | `5432` |
| `GATEWAY_POSTGRES_DB` | From the POC lead | The local ledger database (§10, item 3) |
| `GATEWAY_POSTGRES_USER` / `_PASSWORD` | An `ekg_cube_reader` login from the POC lead, never an admin role | An `ekg_cube_reader` login on the local database |
| `GATEWAY_POSTGRES_SSL` | `true` (Azure requires TLS) | `false` |

The Azure ledger is behind a private network path, so you need VPN or VNet access from the machine running Docker. The profile joins `deploy_default`, so start the shared Postgres first (§3.1). It uses ports 4000 and 15432, like the other profiles, so **stop any Intrepid profile first**.

```powershell
docker compose -f cube\docker-compose.gateway-poc.yml up -d
docker compose -f cube\docker-compose.gateway-poc.yml logs -f     # Ctrl-C stops following, not the container
```

- **If `docker-compose.gateway-poc.yml` is not in your clone,** you're on a hometown branch without it: `main`, before PR #18 merges. Check out `cube/gateway-ledger-profile`, or ask the POC lead. Don't adapt one of the Intrepid profiles to point at the ledger. That is a design change to hometown with a reviewer, not a runbook step.

Watch the logs until models load without error. **Cube reports syntax errors at load time but bad column references only at query time**, so a clean startup does not mean the models work. §4 covers that.

**Inside a Cube container, the database host is `deploy-postgres-1`, never `localhost`.** In a container, `localhost` is the container itself (hometown `cube/README.md`).

### 3.4 Confirm The Gateway

Don't start it; confirm it. From a host with VNet access:

```powershell
curl.exe -s -o $null -w "%{http_code}`n" "https://$env:GATEWAY_FQDN/health/liveliness"
```

Expected: `200`. If this fails, the problem is almost always your network path, not the gateway. Check VPN before escalating.

**Note the `curl.exe`**, not `curl`. In Windows PowerShell, bare `curl` is an alias for a different command, and these flags produce a wall of confusing errors (Field Guide §2.3).

### 3.5 Local Gateway Profile (interruption test only)

Only needed for Intern Guide P1.9, which requires stopping the ledger. That must never be done to Azure. Ask your lead whether a local gateway profile exists, how to start it, and which database on the shared Postgres it uses.

### 3.6 Desktop AI Tool (endpoint attribution tests only)

This is for POC-1's endpoint tests: a user's desktop AI tool pointed at the gateway under nono. **It is not Liam.** Liam never points at the gateway (§3.8).

On the Windows workstation, set the tool's base URL to the gateway and its key to your per-user virtual key:

```powershell
[Environment]::SetEnvironmentVariable('ANTHROPIC_BASE_URL', "https://$env:GATEWAY_FQDN", 'User')
```

Confirm nono is running with its detection policy profile active. Needed only for endpoint attribution and bypass-detection tests; skip it on measurement days.

### 3.7 olive Phase 1 Database (olive work only)

Authority: `DECISION_olive-poc2-phase1_v0.5.md` §13, §15.4, §16 and §17. If this section and the decision record disagree, **the decision record wins**; fix this section.

**Phase 1 is simulation only.** olive holds no write credential to any system. Its executor writes to a local simulated target.

**One-time setup:** create the database and its roles as `nexus`. The olive repository's migrations own everything inside the database; this step only creates the database and the four roles that own and use it.

```powershell
$sql = @"
CREATE ROLE olive_owner NOLOGIN;
CREATE ROLE olive_migrator LOGIN PASSWORD '<local-only>' IN ROLE olive_owner;
CREATE ROLE olive_app      LOGIN PASSWORD '<local-only>' NOBYPASSRLS;
CREATE ROLE olive_reader   LOGIN PASSWORD '<local-only>' NOBYPASSRLS;
CREATE DATABASE olive OWNER olive_owner;
"@
$sql | docker exec -i deploy-postgres-1 psql -U nexus -d postgres -v ON_ERROR_STOP=1
```

Use real local-only passwords in place of `<local-only>`, and keep them in `olive\.env` and your `poc-env.ps1`, never in this file. If the olive repository ships a bootstrap script that does this, use that instead and delete this block.

**Configure olive:** in `olive\.env`, following hometown's variable convention:

```env
OLIVE_ENVIRONMENT=local
OLIVE_POSTGRES_URL=postgresql://olive_app:<local-only>@localhost:5432/olive
OLIVE_POSTGRES_HOST=localhost
OLIVE_POSTGRES_PORT=5432
OLIVE_POSTGRES_DB=olive
OLIVE_POSTGRES_USER=olive_app
OLIVE_POSTGRES_PASSWORD=<local-only>
OLIVE_MIGRATOR_URL=postgresql://olive_migrator:<local-only>@localhost:5432/olive
```

- The host is `localhost` when olive runs as a process on your workstation, and **`deploy-postgres-1`** when olive runs in a container on `deploy_default`.
- **`OLIVE_ENVIRONMENT` is required and has no default.** olive refuses to start without it, and refuses to start with the fixture trace resolver if it says `production`. On a workstation it is always `local`.

**Run migrations:** with olive's migration runner, as `olive_migrator`. Migrations are forward-only, so a mistake is corrected by a new migration, never by editing an applied one. Use the runner's actual command from the olive repository's README.

**Trace check: fixtures and a popeye stub only.** olive verifies every proposal's `trace_ref` before policy and before queueing (decision record §14, §16, §17). In Phase 1:
- the trace resolver is the **fixture** resolver. Every proposal records `trace_verification = fixture`, and olive refuses to start with it if `OLIVE_ENVIRONMENT=production`;
- the token client for hometown calls runs against a **popeye stub**. popeye's real service registry and tenant-scoped tokens are proposed but not yet specified or approved on popeye's side (§10, item 8);
- the live resolver (`trace_verification = hometown`) needs both hometown's server (§3.2) and popeye's tokens. Don't wire it up early, and don't claim a cross-component join from Phase 1 results.

**Check the isolation actually holds** after the first migration:

```powershell
docker exec -i deploy-postgres-1 psql -U nexus -d olive -c "SELECT relname, relrowsecurity, relforcerowsecurity FROM pg_class WHERE relname IN ('proposal','proposal_event','queue_item','execution_ledger');"
```

Expected: four rows, both columns `t`. Anything else, stop: tenant isolation is not in place, and nothing should be seeded until it is.

### 3.8 Liam (stub mode only)

Authority: `LIAM_DESIGN_SPEC_v0.4.md` §3.2, §10.3 and the test spec. **Liam does not call the gateway or any model.** It talks only to hometown and olive, through nono's proxy, and hometown makes the model call.

**Real-nono runs are blocked.** Liam ships with `nono.expected_token_arm` empty and refuses to start outside stub mode until the nono owner confirms that value (Liam open item O7). Until then, run Liam only in stub mode:

- build with the `stubs` feature, and set `LIAM_STUBS=1`;
- generate a fresh receipt and agent-record pair for each run with `scripts\make-stub-records.ps1`. They are tied to the run's process ID and current time, so yesterday's pair fails the freshness check;
- Liam still refuses to start without proxy variables. In stub mode the test harness supplies its capturing proxy.

Use the exact commands in the liam repository's README; this runbook doesn't restate them, because they change with the test harness. An exit code of `10` with `receipt:token_arm` outside stub mode is **the expected result** until O7 closes, not a fault.

---

## 4. Verification

Run these in order. Stop at the first failure; later checks assume earlier ones passed.

### 4.1 Component Health

| Check | How | Expected |
|---|---|---|
| Shared Postgres up | `docker ps --filter name=deploy-postgres-1` | `healthy` or `Up` |
| Cube up | Open the Cube playground (`http://localhost:4000`) | Loads, models listed |
| Gateway reachable | `curl.exe` the health endpoint (§3.4) | `200` |
| Ledger readable | Connect as the read role, count rows | A number, no permission error |
| olive database (if in scope) | The RLS check in §3.7 | Four rows, all `t` |

```powershell
# Ledger readable (Azure or local ledger, whichever the lead confirmed)
psql "host=$env:GATEWAY_POSTGRES_HOST port=$env:GATEWAY_POSTGRES_PORT dbname=$env:GATEWAY_POSTGRES_DB user=$env:GATEWAY_POSTGRES_USER" -c "SELECT count(*) FROM public.`"LiteLLM_SpendLogs`";"
```

Backticks escape the double quotes for PowerShell. The quotes themselves are required by Postgres because the table name is mixed-case (Field Guide §1.1).

### 4.2 Contract Verification

hometown carries verifier scripts under `scripts\`. Confirm the exact npm script names rather than guessing:

```powershell
Set-Location C:\dev\fiskroad-workspace\hometown
(Get-Content package.json | ConvertFrom-Json).scripts
```

As of this revision they use **colons**. Run them in this order, contract mode first:

```powershell
npm run verify:gateway:access                 # boundary text: hometown reads the ledger, never writes it
npm run verify:gateway:ledger-model           # does the Cube model match the real ledger schema
npm run verify:gateway:attribution            # do rows carry app_id and user_id
npm run verify:gateway:ledger-reconciliation  # do request counts match row counts
```

Then live mode, for the scripts that support it, with the `GATEWAY_POSTGRES_*` variables set in `cube\.env`:

```powershell
npm run verify:gateway:ledger-reconciliation -- --live
```

Run contract mode first. If the contract check fails, the live check fails too, for a reason you will misdiagnose. The live reconciliation check calls `psql`, so it needs `psql` on your PATH.

**The ledger-model check is the one that matters most.** The ledger model has failed before because column references were written from memory rather than against the real schema. If it fails, don't work around it: fix the model. Intern Guide P0.3 is that work.

### 4.3 End-To-End Smoke

The single check that proves the whole chain. Full commands are in Intern Guide P0.1 step 11; the shape is:

1. Send one completion request through the gateway with attribution metadata attached.
2. Confirm a row appears in the ledger for that request id.
3. Run the chargeback query through Cube and confirm the request appears with the correct application and user:

   ```powershell
   npm run query:gateway:chargeback     # reads CUBE_URL and CUBEJS_API_SECRET
   ```

If all three pass, the environment works. **If step 3 fails but 1 and 2 pass, the problem is in the Cube model or profile, not the gateway.**

---

## 5. Daily Operating Loop

**Beginning of session:**

```powershell
. C:\dev\poc-env.ps1                                              # session variables
git -C C:\dev\fiskroad-workspace\fiskroad pull --ff-only          # specs, decisions and vocabulary may have moved

Set-Location C:\dev\fiskroad-workspace\nexus-crm\deploy
docker compose up -d                                              # shared Postgres; harmless if already up
docker ps --filter name=deploy-postgres-1 --format "{{.Names}}  {{.Status}}"

Set-Location C:\dev\fiskroad-workspace\hometown
docker compose -f cube\docker-compose.gateway-poc.yml up -d       # ledger profile; cube\.env filled per §3.3

curl.exe -s -o $null -w "%{http_code}`n" "https://$env:GATEWAY_FQDN/health/liveliness"
```

Then run the end-to-end smoke (§4.3) and note anything that differs from yesterday in your working log.

**End of session:**

1. Record what you ran and what you observed, including failures. Unrecorded observations are lost.
2. Commit script and model changes on a branch. Never commit `.env`, `terraform.tfvars`, or anything under `.terraform\`.
3. If you corrected this runbook or the Intern Guide today, commit that too, on a branch in `fiskroad`, where these documents live.
4. Shut down local components (§7).

---

## 6. Measurement Runs

Measurement is the POC's deliverable, and **where it runs changes the numbers**.

- **Develop and debug the scripts on your workstation.** Fast, free, no risk to live infrastructure.
- **Record the numbers of record from a host inside the VNet.** Those are the numbers the SLOs get committed against.

**Critical detail:** the measurement protocol says to run from the same host as the gateway, to exclude network noise. With Container Apps that is impossible, so measurements must run from a host **inside the VNet**: a small VM, or a job in the same Container Apps environment. **Measuring across a VPN measures your VPN**, and it produces numbers that are wrong by an order of magnitude and look entirely plausible.

**Arrange the measurement host on day 1** (Intern Guide P0.4). Provisioning takes time you will not have on day 5.

Record for every run: date and time, gateway image tag, model used, where the measurement host sat, pair count, warm-up pairs discarded, and the timing method. A number without its conditions is not reproducible.

---

## 7. Shutdown

### 7.1 Local (end of each session)

Stop what **you** started, in reverse order:

```powershell
# olive, if you started it: stop its process or container (see the olive README)

Set-Location C:\dev\fiskroad-workspace\hometown
docker compose -f cube\docker-compose.gateway-poc.yml down       # Cube

Set-Location C:\dev\fiskroad-workspace\nexus-crm\deploy
docker compose down                                               # shared Postgres: note, no -v
```

**Check before you stop the shared Postgres.** It also serves Nexus CRM, loan_engine, sit-cip, hometown and olive. If anyone else is mid-test, leave it running. Stopping a container you didn't start is rude; stopping one mid-measurement costs someone a day.

**Never pass `-v`** unless you intend to destroy local data. On this instance that is *everyone's* seed data, not just yours.

### 7.2 Azure (do not)

The Azure environment stays running for the duration of the POC. Do not stop, deallocate or destroy it.

**Cost note worth knowing:** the gateway runs a minimum of two replicas by design and cannot scale to zero, so Azure infrastructure costs accrue continuously, independent of AI usage. The POC's USD 50 cap covers **tokens only**, not infrastructure. If the POC pauses for more than a few days, ask the POC lead whether to stop the Postgres server. That is a lead decision, not yours.

---

## 8. Troubleshooting

| Symptom | Most likely cause | First action |
|---|---|---|
| `no configuration file provided: not found` when starting Postgres | You ran `docker compose up -d` in hometown (the v0.3 instruction) | Run it in Nexus CRM's `deploy\` (§3.1) |
| `role "postgres" does not exist` | The admin role on this instance is `nexus` | Use `-U nexus` (§3.2) |
| `network deploy_default ... not found` when starting Cube or olive | The shared Postgres project is not up | Start Nexus CRM's `deploy\` first (§3.1) |
| `npm ERR! Missing script: "verify-gateway-access"` | Hyphenated script names from v0.3 | Use the colon names: `verify:gateway:access` (§4.2) |
| `ai_usage_grants.sql` not found in hometown | It lives in popeye | `popeye\sql\ai_usage_grants.sql` (§3.2) |
| `docker-compose.gateway-poc.yml` not found | Your hometown checkout is on a branch without the ledger profile (`main` before PR #18 merges) | Use `cube/gateway-ledger-profile` or ask the lead (§3.3, §10 item 1). Don't improvise one |
| Chargeback query hits the wrong Cube | `CUBE_SANDBOX_URL` or `CUBE_SMOKE_URL` is still set from Intrepid work; the script reads them before `CUBE_URL` | Clear them, then rerun `npm run query:gateway:chargeback` |
| Gateway profile can't connect to the Azure ledger | No private network path, or `GATEWAY_POSTGRES_SSL` isn't `true` | Check VPN first, then the SSL setting (§3.3) |
| `bootstrap.sh` not found | fiskroad not cloned yet | Clone fiskroad first (§2.1); the script lives inside it |
| Cannot find the tenant UUIDs, glossary, a spec or a decision record | Same cause | Same fix. fiskroad is a required clone, not an optional one |
| `curl` produces bizarre parameter errors | You typed `curl`, not `curl.exe` | Use `curl.exe` (Field Guide §2.3) |
| Cube starts, queries fail on column errors | The model references a column that does not exist | Compare the model SQL against `\d` output; fix the model (Intern Guide P0.3) |
| Container cannot reach the database | `localhost` inside a container is the container | Use `deploy-postgres-1` |
| Gateway unreachable | No VNet path | Check VPN before anything else |
| Ledger query returns a permission error | Wrong role, or grants not applied | Confirm you are the reader role; ask the lead whether the grants are applied where the ledger lives |
| Request succeeds but no ledger row | Attribution or ledger write issue | Check gateway logs; confirm the request id you are searching for |
| Attribution metadata missing from the ledger | `ConvertTo-Json` without `-Depth` | Add `-Depth 10` (Field Guide §1.4) |
| Chargeback query returns empty | No traffic yet, or the wrong time window | Confirm rows exist in the ledger directly before blaming Cube |
| Latency numbers impossibly good or bad | Measuring from the wrong host | Confirm the measurement host is inside the VNet |
| olive refuses to start: environment | `OLIVE_ENVIRONMENT` unset, or `production` with the fixture resolver | Set `OLIVE_ENVIRONMENT=local` on a workstation (§3.7) |
| olive RLS check returns `f`, or fewer than four rows | Migration incomplete, or RLS not forced | Stop; don't seed. Fix the migration (§3.7) |
| olive queries return no rows, or error, for valid data | `olive.tenant_id` not set in the transaction | Expected behaviour of the RLS design: the app must `SET LOCAL` the tenant on every transaction (decision record §13) |
| Liam exits `10` with `receipt:token_arm` | `expected_token_arm` empty, outside stub mode | Expected until Liam O7 closes; use stub mode (§3.8) |
| Liam exits `10` with `agent_record:written_at` | Stale stub records | Regenerate with `make-stub-records.ps1` for every run |
| Liam exits `11` with `env:no_proxy` | No proxy variables set | In stub mode the harness supplies the proxy; run through it |
| Git shows every line changed | CRLF line endings | `git config --global core.autocrlf true` (Field Guide §2.2) |
| Script blocked from running | PowerShell execution policy | `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned` |
| 429 response | Budget exhausted *or* provider throttling | Read the error body: they are deliberately distinguishable |

---

## 9. Rules That Do Not Bend

1. Never run `terraform apply` or `destroy` against Azure. Plans may be reviewed; applies are the POC lead's.
2. Never commit credentials. If one is committed, say so immediately: rotation is easy, silence is not.
3. Never use the gateway master key for ordinary requests. Use your virtual key.
4. **Never INSERT directly into the gateway spend ledger.** It belongs to popeye, and fabricated rows would corrupt the reconciliation check (Intern Guide P0.2).
5. Only synthetic data through the POC. No real customer, loan or tenant data, ever.
6. **olive holds no write credential in Phase 1.** Not a test one, not a temporary one. Any real write needs a new decision record and CTO and CSO sign-off.
7. **Never set `OLIVE_ENVIRONMENT=production` on a workstation**, and never edit olive's startup checks to get past a refusal.
8. **Never point Liam at the gateway.** It is deliberately not on Liam's allowlist. If a test seems to need it, the test is wrong.
9. **olive sends the agent session key only to popeye** (introspection and token issuance). Never to hometown, never to a target system, never into a log. A capture test checks this (decision record §17.1).
10. **Never run `docker compose down -v` on the shared Postgres.** It destroys every project's local data.
11. Record failures as carefully as successes. A failed run nobody wrote down will be run again by someone else.
12. If blocked for more than two hours, escalate. Nobody is impressed by a day spent stuck.

---

## 10. Known Gaps In This Runbook

Open items found while writing v0.4. Close them by fixing the runbook, not by working around them.

| # | Gap | Owner | Effect until closed |
|---|---|---|---|
| 1 | **Fixed pending merge.** Confirmed missing from hometown `main` on 2026-10-20. hometown added `cube/docker-compose.gateway-poc.yml` as a reviewed change: PR #18, branch `cube/gateway-ledger-profile`. The live proof also needs the ledger host, database and an `ekg_cube_reader` login in `cube/.env` | hometown owner (merge) / POC lead (connection values) | The chargeback step of the end-to-end smoke (§4.3 step 3) runs from the branch once §3.3's values are filled. Close this row when PR #18 is merged and `npm run query:gateway:chargeback` returns ledger rows |
| 2 | The Nexus CRM repository's folder name and URL are placeholders (`nexus-crm`) | POC lead | Correct §2.1, §3.1, §5 and §7.1 to the real name |
| 3 | The local gateway profile's database name on the shared Postgres is unknown | POC lead | §3.2 and §3.5 placeholders stay |
| 4 | olive's migration runner and bootstrap script don't exist yet | olive implementer | §3.7 uses the interim `psql` setup block |
| 5 | Liam real-nono runs are blocked on O7 (AppContainer token-arm value and the expectancy review) | nono owner | Stub mode only (§3.8) |
| 6 | The hometown reconciliation check looks for `total_cost_usd`; confirm it matches the current `ai_token_usage` model before trusting a failure | hometown owner | A contract failure may be model drift, not a broken ledger |
| 7 | hometown has no HTTP server yet, and `answer_trace` has no row-level security. Both are needed before the agent answer and trace-resolution endpoints run (`HOMETOWN_v0.4` §2.5–§2.6, agreed, uncommitted on `contract/ate-v0.4`) | hometown owner | Liam runs against stubs only; olive uses the fixture resolver |
| 8 | popeye's service registry, tenant-scoped olive tokens and their introspection are **acknowledged as a proposed dependency** (2026-10-20), not specified, ratified or approved for implementation on popeye's side | popeye owner | olive's token client runs against a popeye stub; no live trace resolution is possible until popeye ships this |

---

## Change Log

| Version | Change |
|---|---|
| 0.4.2 | Ledger Cube profile added by hometown (PR #18, branch `cube/gateway-ledger-profile`, pinned `cubejs/cube:v1.6.64`, not yet merged); §3.3 rewritten with the `GATEWAY_POSTGRES_*` settings; §5 and §8 updated; §10 item 1 fixed pending merge |
| 0.4.1 | Aligned with olive decision record v0.5.2 and `HOMETOWN_v0.4` §2.5–§2.6: olive trace check on fixtures and a popeye stub; hometown server's Postgres-plus-RLS start condition; rule 9 (session key only to popeye); known gaps 7–8 |
| 0.4 | Shared Postgres moved to Nexus CRM `deploy/` (`deploy-postgres-1`, `deploy_default`, admin `nexus`); grants path corrected to popeye; npm script names corrected to colons; Cube ledger profile flagged missing; new §3.7 olive Phase 1 database; new §3.8 Liam stub mode; §3.6 separated from Liam; shared-instance shutdown etiquette; rules 6–9; new §10 known gaps |
| 0.3 | Added the fiskroad coordination clone, which every other instruction quietly assumed |
| 0.2 | — |
| 0.1 | First draft |
