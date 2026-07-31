# Commercial Components: Leverage And Timing

Version: 0.1
Status: Draft decision record
Audience: CTO, popeye team, hometown team, procurement
Primary post-read action: confirm the buy/build principles, note the two Stage 2 purchase decisions (they gate exit criteria), and register the anti-buy list so well-meaning tool adoption doesn't undercut the program thesis.
Companion documents: popeye ROADMAP (ADR-001, ADR-002), Component Gap Assessment v0.1, Ecosystem Portfolio and Gap Analysis v0.1.

## 1. Principles

1. **Buy undifferentiated operations.** Managed databases, identity, SIEM, content classification, metrics plumbing — engineering hours spent here return nothing the program is judged on.
2. **Never buy the differentiator.** The semantic models, the Answer Trace Envelope, the popeye control-plane logic, and the governance loop are what the CTO demos against Palantir. Purchasing an overlapping SaaS creates a second source of truth for the exact capability being claimed.
3. **Every commercial piece must be swappable.** The sister-organization sharing intent means reference deployments must run on pure OSS; commercial components are accelerators for TWG's own operation, documented with their OSS fallback.
4. **Already-licensed beats newly-purchased.** TWG's O365/Azure estate (Entra, Teams, Intune, likely Sentinel and some Entra premium licensing) is checked before any net-new procurement.

## 2. Already Commercial (No Decision Needed)

The Stage 2 Terraform already commits to commercial managed services: Azure Database for PostgreSQL Flexible Server, Azure Cache for Redis, Container Apps, Key Vault, Log Analytics — and their AWS equivalents at Stage 3. Entra ID, Intune, and Teams carry identity, fleet configuration, and alerting/approvals. These are the correct buys and are already made.

## 3. Purchase Decisions By Stage

### Stage 2 (decide during first managed region)

- **LiteLLM Enterprise** — the likely first net-new purchase. The Prometheus metrics endpoint, SSO for the admin surface, and audit-log retention are enterprise-gated; all three serve Stage 2 exit criteria (committed SLO alerting, admin audit trail). Basic tier was observed around $250/month; verify at procurement. This IS ADR-001, with two alternatives inside the same decision: stay OSS and build OTel-callback metrics plumbing (costs engineering days exceeding the license), or adopt Azure APIM's AI gateway (in-estate commercial, strongest if TWG later consolidates management planes on Azure).
- **Azure AI Content Safety** — the buy option for the Stage 2 guardrails/DLP work item. Consumption-priced, Azure-native, integrates at the gateway hook surface. OSS fallback documented: Presidio for PII masking. Bedrock Guardrails is the AWS-side equivalent at Stage 3.
- **Entra ID P2 / PIM** — break-glass eligible membership assumes PIM-style just-in-time elevation, which requires P2. Action: confirm existing licensing before assuming a purchase; if absent, license the approvers group only.
- **Terraform state backend** — HCP Terraform is the commercial option only if no organizational standard exists; an Azure Storage backend is near-zero cost and likely sufficient. This remains "do not invent alone" — a platform decision, not a popeye purchase.

### Stage 3 (second region and fleet)

- **Microsoft Sentinel** — SIEM home for nono bypass detections, key-usage anomalies, and the admin audit trail. Wiring work if already in the estate; a deliberate procurement if not. Timing follows the fleet rollout, when detection volume becomes real.
- **Bedrock Guardrails** — AWS-side content safety, consumption-priced, configured when gateway-aws goes live.

### Stage 4-5 / MVP (triggered, not scheduled)

- **Cube Cloud** — the largest deferred decision. Trigger: operating self-hosted Cube demonstrably costs more than the consumption bill would, or hometown Stage 5 wants managed access control and SSO. Relevant facts: Azure all-regions support, SAML SSO, RBAC, and monitoring integrations sit at the Enterprise tier (99.99% SLA); pricing is consumption-based (Cube Consumption Units in 5-minute intervals) with tier-determined unit price. The exit story is intact by construction: the models are YAML in git; Cube Cloud hosts the artifacts, it does not own them. Evaluate at production reporting cutover.
- **Evaluation platform (Braintrust / LangSmith / Arize class)** — decide at POC C charter. The legitimate purchase is the harness and results UI; the golden datasets and the groundedness-against-ATE scoring remain in-house because they are the differentiator (principle 2). If purchased, judge/model calls still route through the popeye gateway so evaluation spend is metered.
- **Tines paid tier** — already the standing action hand-off decision; the free tier likely carries POC D, and the paid tier is sized when action volume is known.

## 4. The Anti-Buy List (Deliberate, Not Oversight)

- **LLM observability SaaS** (Langfuse Cloud, Helicone, Datadog LLM Observability, LangSmith-as-observability): duplicates the ATE and the spend ledger, splits the source of truth for the program's headline capability, and typically requires shipping prompt/completion content to a third party — colliding with the standing no-content guardrail.
- **FinOps SaaS** (CloudZero/Vantage class for AI spend): popeye is the FinOps layer; buying one concedes the thesis being demoed.
- **Gateway SaaS** (Portkey, Kong Konnect, and peers): the self-host decision is made and encoded in Terraform; the sanctioned escape hatch is Azure APIM inside ADR-001, not a third vendor.
- **Data catalog/governance platforms** (Collibra/Atlan class): adjacent problem, real product category, not this program. Revisit only if divisional model sprawl outgrows the code-review-and-ownership-metadata conventions already specified.
- **Anything Palantir-shaped**: the program exists because of this comparison; partial adoption forfeits the openness and cost arguments simultaneously.

## 5. Timing Summary

Now through Stage 1: purchase nothing; the POC runs on local infrastructure and existing licenses, and its USD 50 spend cap is the entire budget. Stage 2: decide ADR-001 (LiteLLM Enterprise vs OSS vs APIM), adopt Azure AI Content Safety for the DLP work item, confirm Entra P2 for break-glass, settle the state backend. Stage 3: Sentinel wiring, Bedrock Guardrails. Stage 4-5/MVP: Cube Cloud on trigger, eval platform at POC C charter, Tines tier at POC D sizing. Throughout: every purchase records its OSS fallback in the ADR, preserving the shareable reference deployment.

## 6. Open Items

- Inventory current Entra/Microsoft licensing (P1/P2, Sentinel entitlements) before Stage 2 — likely reduces the purchase list.
- Verify current LiteLLM Enterprise pricing and terms at ADR-001 time; observed figures predate procurement.
- Confirm whether Cube Cloud's BYOC option changes the Stage 5 calculus (managed control plane, TWG-owned compute) — it may split the difference between self-hosted and SaaS.
