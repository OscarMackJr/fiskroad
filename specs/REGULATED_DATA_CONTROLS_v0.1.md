# Regulated Data Controls For AI Processing

Version: 0.1
Status: Draft — requires compliance and legal sign-off before it is authoritative
Audience: CTO, compliance and legal, popeye team, hometown team, application owners
Primary post-read action: assign a compliance owner, complete the three tables in sections 3–5, and obtain written sign-off before any regulated context flows to a model provider.
Program: Fiskroad. Enforcement: popeye. Classification: hometown and application owners.

**Scope note.** This document specifies the *control framework* — the classifications, decisions, and enforcement points that must exist. It does not interpret law. Every determination below requires review by TWG's compliance and legal functions, and their determinations override anything written here.

## 1. Why This Exists

Intrepid is a loan engine. Nexus holds customer relationships. AI features assemble context from both and send it to third-party model providers on two clouds. Today no artifact states which categories of data may be sent to which providers under what terms.

Fiskroad's existing guardrail — no prompt or completion content in the spend ledger or trace store — is strong and should be highlighted. But it governs *our* stores. It says nothing about what leaves the building inside a prompt. That is the gap.

For a financial institution this is the one architectural gap that can stop a program rather than merely embarrass it in review.

## 2. Control Model In One Paragraph

Every AI feature declares the highest data classification it may handle. Every model deployment is approved for a maximum classification based on the provider's contractual terms. Popeye enforces the intersection: a virtual key scoped to a feature may only reach models approved for that feature's classification. Classification is a design-time decision recorded in configuration, not a runtime content inspection.

## 3. Data Classification (complete with compliance)

| Class | Definition | Examples in the TWG estate |
|---|---|---|
| `public` | Freely disclosable | Published rate sheets, marketing content |
| `internal` | Business-confidential, non-personal | Aggregate portfolio metrics, internal process docs |
| `confidential-personal` | Personal data, not financial-account | Contact names, business email, role |
| `regulated-financial` | Nonpublic personal financial information | Borrower identity with loan terms, balances, payment history, application data |
| `regulated-identifier` | Strong government identifiers | Tax IDs, government ID numbers |

Working assumptions to confirm with compliance: `regulated-financial` and `regulated-identifier` are subject to the strictest controls; `regulated-identifier` should be treated as **never permitted in a prompt** — if a feature appears to need it, the feature design is wrong, and tokenized references (as Bluto uses) are the correct pattern.

## 4. Provider And Model Approval (complete with legal)

For each model deployment, record and verify before approval:

| Attribute | Why it matters | Status |
|---|---|---|
| Contractual no-training commitment | Inputs must not train provider models | To verify per provider |
| Retention period for inputs and outputs | Including abuse-monitoring retention, which is often the overlooked term | To verify |
| Data residency and processing region | Where inference physically occurs | To verify |
| Subprocessor list and change notification | Who else can touch the data | To verify |
| Human review provisions | Whether provider staff may access content, and under what conditions | To verify |
| Contract vehicle | Enterprise agreement, DPA, or BAA as applicable | To confirm |

Both Bedrock and Azure AI Foundry offer enterprise terms addressing most of these. **Cite the specific contractual terms in the completed table, not the marketing pages.** The reviewers in the partner design review will know the difference immediately, and the difference is the whole point.

Output of this section: an **approved-model list**, keyed by model deployment, stating the maximum data class each is approved for. Bedrock and Foundry deployments are assessed independently; approval does not transfer between clouds.

## 5. Feature Classification

Every AI feature carries a `feature_tag` already — the attribution vocabulary popeye and hometown share. Extend it with a declared maximum data class:

| Feature tag | Max class | Rationale | Owner |
|---|---|---|---|
| `ekg.graphrag_context` | to complete | | hometown |
| `crm.deal_summary` | to complete | | Nexus owner |
| `intrepid.*` | to complete | | Intrepid owner |
| `sitcip.*` | to complete | | sit-cip owner |

The declaration is the application owner's responsibility and is reviewed by compliance. An undeclared feature tag defaults to `internal` and therefore cannot reach models approved only for higher classes — deny by default.

## 6. Enforcement Points

1. **Popeye (primary, technical).** Virtual keys carry the feature's data class; model allowlists are derived from the approved-model list. A request for a model not approved for the key's class is rejected with a distinct policy error class. This reuses the allowlist mechanism already built — see the popeye enforcement specification.
2. **hometown (design-time).** Context assembled for a feature must not exceed the feature's declared class. The minimum-necessary principle applies: a summarization feature does not need account numbers. Where a strong identifier would otherwise be needed, use Bluto's tokenized reference.
3. **nono (coverage).** Desktop agents bypassing the gateway are outside all of the above, which is precisely why bypass detection is a control and not merely a cost measure. State this connection explicitly in the review — it converts nono from a nice-to-have into part of the compliance story.
4. **Audit.** Popeye's ledger records model, feature tag, and identity per request without content, so "which features reached which models" is answerable from governed data. This is genuinely strong and should be demonstrated.

## 7. Prompt Content Policy

- Minimum necessary: include only the fields the feature requires.
- Never include `regulated-identifier` class data in a prompt.
- Prefer tokenized or resolved references (Bluto `party_id`) to raw identifiers.
- No content in Fiskroad's own governed stores — existing guardrail, unchanged.
- Where a provider offers a zero-retention or no-abuse-logging option for enterprise agreements, evaluate and record whether it is enabled.

## 8. Incident Handling

Add to popeye's runbook set: **suspected regulated data sent to an unapproved model.** Steps: identify affected requests from the ledger by feature tag, model, and time window (content is not stored, so scope is bounded by attribution, not by inspection); revoke or re-scope the offending key; notify compliance within the agreed window; assess provider-side retention and pursue deletion where contractually available; record in the incident log. Severity: treat as SEV-2 minimum, SEV-1 if `regulated-financial` reached a model with no contractual no-training commitment.

## 9. Requirements And Test Criteria

| REQ | Requirement | TC | Test criteria | Method |
|---|---|---|---|---|
| REQ-REG-01 | Every approved model has recorded contractual terms and a maximum data class | TC-REG-01 | The approved-model list is complete for every model configured in popeye; no model is reachable that is absent from it | AUDIT |
| REQ-REG-02 | Every feature tag declares a maximum data class | TC-REG-02 | Every feature tag in use appears in the classification table; unknown tags default to `internal` | AUDIT + CI |
| REQ-REG-03 | Class mismatches are technically prevented, not merely documented | TC-REG-03 | A key scoped to a regulated feature is refused a non-approved model with a distinct policy error class | DEMO |
| REQ-REG-04 | Strong identifiers never enter prompts | TC-REG-04 | Prompt construction paths are reviewed and a test asserts tokenized references are used | CI + AUDIT |
| REQ-REG-05 | Feature-to-model history is auditable without storing content | TC-REG-05 | A query answers which features reached which models over a period, from the ledger alone | DEMO |
| REQ-REG-06 | An incident has a rehearsed response | TC-REG-06 | The unapproved-model runbook is written and rehearsed once | RUNBOOK |

## 10. Open Decisions

- Compliance owner for this document (blocking — assign before the review).
- Whether any feature genuinely requires `regulated-financial` context in v1, or whether MVP features can be designed to operate on derived and aggregated context instead. Answering "no regulated context in the POC" is a legitimate and very strong review position if it is true.
- Whether provider zero-retention options are contracted and enabled on both clouds.
- Retention period for the popeye ledger and ATE traces themselves, given they carry attribution about regulated processing even without content.
