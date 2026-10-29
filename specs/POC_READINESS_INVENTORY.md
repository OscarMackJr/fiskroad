# POC Readiness Inventory

Status: living checklist — update values and evidence as provisioning completes.

> **Lead:** Fiskroad must be published and clonable before day 1. This is gate G0,
> not a day-1 discovery.

## Values

| Name | Value | Notes |
|---|---|---|
| `GATEWAY_FQDN` | **Unresolved** | Terraform has an internal Container App FQDN, but its value is not checked into the repo. Stable `gateway-azure.ai.twg.internal` is not yet decided. |
| `GATEWAY_MODEL_A` | `twg-foundry` | Documented Azure gateway public model name. |
| `GATEWAY_MODEL_B` | Blank | No second cloud/provider is configured for the current POC. |
| Your virtual key | **Lead-issued** | Set only in the session: `$env:POC_KEY`. Never commit or place in `.env`. |
| Low-budget test key | **Lead-issued** | Budget amount is not recorded; lead must set it for P1.7. |
| `LEDGER_HOST` / `LEDGER_DB` | **Unresolved** | PostgreSQL FQDN is a Terraform output, not a checked-in value. |
| `LEDGER_READ_USER` | `ekg_cube_reader` | The intended read-only pattern/role. A deployment-specific login binding is still required. |
| Local Postgres connection | **Unresolved** | Must come from the local non-production secret/configuration path. |
| Cube URL | `http://localhost:4000` | Local default only; confirm after starting the local Cube profile. |
| Measurement host | **Unresolved** | Must be an in-VNet host; current workstation cannot resolve the internal gateway FQDN. |
| VPN / network path | **Unresolved** | Lead/network owner must provide the route to the private Container App endpoint. |
| Azure subscription | `TWG Architecture POCs` | Subscription name is documented; subscription ID and read-only access must be issued. |
| Workspace path | `C:\Users\OMack\fiskroad\workspace` | Current local workspace; interns may use another path. |
| `fiskroad` clone URL | **Blocked — G0** | Manifest marks Fiskroad as pending publication. Do not begin day 1 until the repo is published and clonable. |
| POC tenant UUIDs | See below | Fixed program values; do not mint replacements. |
| Your lead | **Unresolved** | Lead must provide name and preferred contact channel. |

## POC Tenant UUIDs

| Display name | Canonical `tenant_id` |
|---|---|
| `TENANT_ALPHA` | `2a46fb0c-21d0-4fd7-9ab8-4102ecb682fa` |
| `TENANT_BETA` | `30c224ad-eec5-432d-aeb0-7f104a0b55b8` |
| `TENANT_GAMMA` | `419304ea-36f3-4c27-b773-42248399f247` |

Use each UUID unchanged in seed records, headers, events, traces, and metadata.
The display names are labels only.

## Resolution Cookbook

| Gap | Owner/action | Completion evidence |
|---|---|---|
| G0: Fiskroad clone URL | Program lead publishes Fiskroad and updates the manifest's pending marker. | Fresh `git clone <fiskroad-url>` succeeds. |
| Gateway and ledger values | Popeye infrastructure owner runs Terraform outputs from the applied Azure environment and shares non-secret FQDN/database names through the approved channel. | Intern can resolve the gateway from the approved network path; read-only ledger connection succeeds. |
| Keys and budget | Popeye owner creates a personal virtual key and a separate low-budget test key. | Keys work only from environment variables; budget-test amount is documented. |
| Network and measurement host | Network owner provides VPN/private-DNS instructions and an in-VNet measurement machine. | Gateway hostname resolves and a smoke request returns from that host. |
| Azure access | Subscription owner assigns read-only access to the POC subscription. | Intern can list the scoped resources without write permissions. |
| Hometown database and Cube | Hometown owner supplies a non-production connection string via secret manager/local configuration and confirms the Cube profile. | Local Cube is reachable at the confirmed URL and uses the intended read role. |
| Lead contact | Program lead names the day-1 escalation contact and channel. | Included in the intern handoff. |
