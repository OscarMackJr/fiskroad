# Nono ↔ Popeye Session Credential Contract v0.1

Version: 0.1
Status: **Draft cross-repo contract — requires joint review (nono + popeye maintainers + program lead) before either side implements.** A contract one team can shape unilaterally is that team's data structure, not a contract.
Canonical home: `fiskroad/contracts/NONO_POPEYE_SESSION_CREDENTIAL_CONTRACT_v0.1.md`. Referenced (never copied) by both repos.
Implementers: popeye (issuer side), nono (consumer side).
Depends on: `PROGRAM_SHARED_VOCABULARY_v0.4` §3 (principal types, delegation rules), `POPEYE_v0.4` §2 (agent principals), `NONO_AGENT_RUNTIME_CHARTER_v0.1` §2–4.
Primary post-read action: the joint review decides **D-1 (issuer identity)** — every other section is reviewable as written. D-1 is a security-posture decision and is deliberately NOT pre-answered here.

---

## 1. Purpose And The One Sentence

When nono performs a governed launch, it must place a credential in the contained agent's egress path. This contract defines that credential's **issuance, shape, injection, lifetime, and join semantics** — the single seam between the endpoint runtime and the gateway.

> **One sentence:** at governed launch, nono requests a short-lived agent-principal key from popeye, injects it at the proxy (never into the agent workspace), and the key's identity fields are what make the session's enforcement receipt reconcile with the gateway's ledger rows.

## 2. Issuance

### 2.1 Request (nono → popeye)

```
POST <issuance endpoint>            # concrete path mapped by popeye per D-2
{
  "principal_type": "agent",                  # constant for this contract
  "agent_id":       "<stable agent identifier>",
  "on_behalf_of":   "<user or application principal id>",
  "purpose":        "<one of the 7 vocabulary purposes>",
  "tenant_id":      "<canonical lowercase uuid>",
  "requested_ttl_seconds": <int>,
  "session_id":     "<uuid, minted by nono at governed launch>",
  "device_ref":     "<opaque managed-device reference — shape decided by D-1>"
}
```

### 2.2 Validation (popeye MUST enforce, all pre-existing rules restated by reference, not re-specified)

- `principal_type` is `agent`; `agent_id` and `on_behalf_of` both present (`POPEYE_v0.4` REQ-AGT-01).
- `on_behalf_of` is not itself an agent — onward delegation refused (REQ-VOC-10 / REQ-AGT-02).
- `purpose` validates against the vendored vocabulary list (REQ-PUR-06).
- `tenant_id` matches the canonical UUID format.
- `requested_ttl_seconds` is clamped to the issuer's maximum (§4.1); never extended.
- The caller is an authorized issuer per **D-1**.

### 2.3 Response

```
{
  "key":            "<bearer credential — opaque to nono>",
  "key_ref":        "<non-secret key identifier for logs/receipts>",
  "expires_at":     "<RFC 3339 UTC>",
  "session_id":     "<echoed>",
  "budget_scope":   "<informational: budget id this key draws on>"
}
```

**Rules:** `key_ref` MUST be derivable/loggable without exposing the bearer secret. nono, the receipt, and the ledger all speak `key_ref`; only the proxy's injection path ever holds `key`.

## 3. Injection And Containment (nono side)

- The bearer key is held by the nono proxy and injected into gateway-bound requests only. It is **never** written to the agent workspace, environment, or any file a contained process can read (`NONO_AGENT_RUNTIME_CHARTER` REQ-RUN-04).
- The contained agent is configured with the gateway endpoint and *no credential*. From the agent's view, auth is ambient; from the program's view, auth is a per-session grant the agent never possessed.
- On issuance failure, governed launch **fails closed** with a distinct error. There is no anonymous or shared-key fallback path.

## 4. Lifetime And Mid-Session Behavior

### 4.1 TTL
- Default TTL: **hours, not days** — issued per session (`POPEYE_v0.4` §2.2). Issuer maximum is configuration, not contract; the contract fixes only that a maximum exists and clamps silently with the clamped value visible in `expires_at`.

### 4.2 Expiry mid-session
- The gateway refuses an expired key with popeye's distinct expired-key error (REQ-AGT-04). The refusal is popeye's; the *experience* is nono's to manage:
- nono MAY re-issue within the same `session_id` (a "renewal": new key, same session, new `key_ref`). Renewal is a fresh §2 issuance — same validation, no shortcut path.
- nono MUST NOT extend a key's life locally, cache keys across sessions, or reuse a key for a second agent process.
- Session end (agent exit or containment teardown) SHOULD trigger best-effort key revocation where the issuer supports it; the receipt records session end regardless.

## 5. The Join (why every field above exists)

The reconciliation that makes endpoint governance *provable* rather than asserted:

```
receipt.session_id + receipt.key_refs[]  ↔  ledger rows where key identifier ∈ key_refs
receipt.agent_id / on_behalf_of          ≡  ledger principal fields (must match exactly)
receipt.session window [start, end]      ⊇  ledger row timestamps for those keys
```

- One governed session reconciles to **all and only** its ledger rows. Rows outside the window or under other keys are a finding, not noise.
- `on_behalf_of` roll-up (cost to the human/app, activity to the agent) comes free from `POPEYE_v0.4` §2.3 once these fields match — this contract adds no new attribution logic, only the discipline that both sides carry identical values.

## 6. Requirements

| REQ | Requirement | TC | Test criteria | Side | Method |
|---|---|---|---|---|---|
| REQ-CRED-01 | Issuance validates all §2.2 rules; each failure returns a distinct error | TC-CRED-01 | Negative test per rule | popeye | CI |
| REQ-CRED-02 | Issued keys carry principal metadata such that ledger rows populate `principal_type`, `agent_id`, `on_behalf_of` | TC-CRED-02 | Live verifier on agent-key traffic: no nulls | popeye | CI (live) |
| REQ-CRED-03 | `key_ref` is present, non-secret, and stable for the key's life | TC-CRED-03 | Log/receipt fixture contains `key_ref`, never `key` | both | CI |
| REQ-CRED-04 | The bearer key is unreadable from the contained workspace for the whole session | TC-CRED-04 | Post-session workspace scan; in-session read attempt from contained process fails | nono | CI + DEMO |
| REQ-CRED-05 | Issuance failure ⇒ governed launch fails closed, distinct error, no fallback credential | TC-CRED-05 | Issuer unreachable in fixture; launch refuses | nono | CI |
| REQ-CRED-06 | Expired key ⇒ gateway refusal surfaces to the session; renewal (if used) creates a new `key_ref` under the same `session_id` | TC-CRED-06 | Short-TTL fixture; observe refusal then renewal chain in receipt | both | DEMO |
| REQ-CRED-07 | Receipt ↔ ledger reconciliation holds: one session, all and only its rows | TC-CRED-07 | End-to-end governed session; reconciliation script passes; injected out-of-window row fails it | both | DEMO + CI |
| REQ-CRED-08 | No shared, static, or cross-session agent credential exists on any endpoint | TC-CRED-08 | Endpoint config audit; grep for provisioned model-path secrets | nono | AUDIT |

## 7. Decisions For The Joint Review

**D-1 · Issuer identity — THE decision.** What credential does *nono itself* present when calling the issuance endpoint? A long-lived issuer secret on every laptop recreates the shadow-credential problem one level up. Candidates, deliberately not ranked:
- *(a)* **Managed-device identity** — Entra device attestation / conditional access on the issuance endpoint. Strongest story, couples issuance to the device-management plane; portability cost on any future non-Entra estate.
- *(b)* **Per-device provisioned token** — issued at enrollment, rotated on schedule, revocable per device. Simpler plumbing; is itself a credential to govern, with its own rotation owner (a name, per B1's lesson).
The review picks one and names the owner of its lifecycle. **This document does not.**

**D-2 · Endpoint mapping.** How §2 maps onto the gateway's actual key-issuance surface (LiteLLM key generation + metadata) vs a thin issuance wrapper in front of it. popeye's proposal, reviewed jointly — the wrapper question decides where §2.2 validation lives.

**D-3 · Revocation.** Best-effort on session end (§4.2): supported now, or recorded as accepted gap until the gateway's key-management path supports it cleanly.

**D-4 · Renewal policy.** Allow in-session renewal (§4.2) or force session end at expiry. Tradeoff: long agent tasks vs simpler audit story (one session = one key).

**D-5 · Receipt schema residency.** The receipt fields this contract requires (`session_id`, `key_refs`, window) live in the endpoint-detection schema family — same file as `endpoint-detection/0.1` or a sibling `endpoint-receipt/0.1`. nono's proposal, reviewed jointly.

## 8. Change Control

This contract versions like the vocabulary: changes by PR against the canonical fiskroad copy, two-team review mandatory, consuming repos update their reference (not a vendored copy — this is an interface spec, not a validation artifact). The joint review that ratifies v0.1 should also fold in the still-unextracted `ENDPOINT_DETECTION_CONTRACT` (v0.3 item) — same seam, one meeting.
