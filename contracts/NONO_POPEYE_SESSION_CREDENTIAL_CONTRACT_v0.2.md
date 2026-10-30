# Nono ↔ Popeye Session Credential Contract v0.2

Version: 0.2
Status: **Draft cross-repo contract, aligned to the ratified v0.4.1–v0.4.3 package.** Needs confirmation by the nono and popeye maintainers and the program lead. Where this contract and a ratified spec disagree, the ratified spec wins and this contract is corrected.
Canonical home: `fiskroad/contracts/NONO_POPEYE_SESSION_CREDENTIAL_CONTRACT_v0.2.md`. Both repos reference it and never copy it.
Implementers: popeye (issuer side), nono (consumer side).
Sources (ratified 2026-10-19): `POPEYE_v0.4.1` §2 (agent key exchange), `POPEYE_v0.4.2` §2.6 (`direct_gateway`), `POPEYE_v0.4.3` (key identifier format), `NONO_v0.4.1` §4 (session key lifecycle), `NONO_v0.4.2` §2–3 (injection scope, agent profile), `NONO_v0.4.3` (agent session record). Also depends on `PROGRAM_SHARED_VOCABULARY_v0.4` §3 (principal types, delegation rules).
Supersedes: v0.1. See §9 for what changed.
Primary post-read action: confirm that §2–§5 restate the ratified specs without drift. §7 lists what is still open.

---

## 1. Purpose And The One Sentence

When nono launches a governed agent session, it must put a credential in the agent's path to program services without the agent ever holding it. This contract defines that credential's **issuance, shape, injection, lifetime, session records and join semantics**: the seam between the endpoint runtime and the gateway.

> **One sentence:** before the agent starts, nono-proxy exchanges the user's own virtual key for a short-lived agent key from popeye, holds it in memory and injects it only toward the profile's declared services, and the key's `key_id` is what joins nono's session records to popeye's ledger rows.

## 2. Issuance (`POPEYE_v0.4.1` §2.1–2.2, `POPEYE_v0.4.2` §2.6)

### 2.1 Request (nono-proxy → popeye)

```
POST <exchange path on the gateway FQDN>     # path and implementation are popeye's choice
Authorization: <the user's own virtual key>  # principal_type = user
{
  "agent_id":       "<registered agent id, e.g. liam>",
  "purpose":        "<one of the 7 vocabulary purposes>",
  "ttl_seconds":    <int, requested>,
  "direct_gateway": <bool>                    # true only when the profile's inject_on contains "gateway"
}
```

The request carries **no** `on_behalf_of`, `tenant_id`, `principal_type`, session identifier or device reference. popeye derives `on_behalf_of` from the authenticating user key and ignores any value in the body. Tenant, data-class ceiling and budget are inherited from that key.

### 2.2 Validation (popeye MUST enforce)

| Rule | Source |
|---|---|
| Caller is a `user` key. An `application` or `agent` key is refused, so an agent key can never mint another | `POPEYE_v0.4.1` §2.2; REQ-VOC-10 |
| `on_behalf_of` is the caller's own principal, set server-side | `POPEYE_v0.4.1` §2.2 |
| `agent_id` is in the agent-ID registry | `POPEYE_v0.4.1` §2.2 |
| `purpose` is in the vendored vocabulary and permitted to the caller (intersection, never union) | `POPEYE_v0.4.1` §2.2; REQ-PUR-06 |
| `expires_at` = min(requested, program cap). POC-2 cap: **8 hours**. popeye may shorten, never lengthen | `POPEYE_v0.4.1` §2.2 |
| Data-class ceiling, tenant and budget are inherited and can never be exceeded | `POPEYE_v0.4.1` §2.2 |
| `direct_gateway` is bound to the key. With `false`, any gateway call not arriving through a registered relay (POC-2: hometown) is refused | `POPEYE_v0.4.2` §2.6 |

### 2.3 Response (popeye → nono-proxy)

```
{
  "key":            "<agent key secret; nono-proxy memory only>",
  "key_id":         "<lowercase canonical UUID, v4 or v7>",
  "expires_at":     "<granted expiry>",
  "agent_id":       "<echoed>",
  "purpose":        "<echoed>",
  "on_behalf_of":   "<derived by popeye from the user key>",
  "principal_type": "agent"
}
```

**`key_id` rules** (`POPEYE_v0.4.3` §2): a UUID (version 4 or 7) in lowercase canonical `8-4-4-4-12` form, unique, never reused, even after revocation or expiry. The same string appears byte for byte in the exchange response, the revocation request, ledger rows, issuance events and the introspection response. `key_id` is not a secret. Only nono-proxy's injection path ever holds `key`.

### 2.4 Response checks (nono MUST enforce; `NONO_v0.4.1` §4.4)

The session is **refused** and the child never runs if:

- the purpose is missing or not in the vendored vocabulary (checked before the exchange);
- the exchange fails or times out;
- the response's `principal_type` is not `agent`, or its `agent_id` differs from the profile;
- `on_behalf_of` is empty or is itself an agent.

**There is no fallback to the user key**, and no anonymous or shared-key path.

## 3. Injection And Containment (`NONO_v0.4.1` §4.1–4.2, `NONO_v0.4.2` §2–3)

- nono-proxy holds the agent key **in memory only**. It is never written to disk, a receipt or record, a log, the child's environment or its command line.
- The key is injected only on requests to the services in the agent profile's `inject_on` list. POC-2 permits `gateway`, `hometown` and `olive`. Each named service must map, in `[agent.services]`, to an FQDN already on the profile's network allowlist. Matching is on the exact CONNECT host (case-insensitive, no wildcard).
- The session refuses to start if `inject_on` is absent or empty, names a service outside the POC-2 set, names a service with no `[agent.services]` entry, or maps to an FQDN not on the allowlist.
- The user key is used for one thing only: the exchange call (§2.1). It is never injected into child traffic.

## 4. Lifetime, Expiry And Revocation (`NONO_v0.4.1` §4.3, `POPEYE_v0.4.1` §2.4)

- **One key per session.** The TTL comes from the profile (`key_ttl_seconds`) and is capped by popeye (§2.2).
- **No renewal and no silent re-mint.** If the key expires mid-session, the next request fails and the failure is recorded as a session event. A session that needs longer than its TTL is a profile change, not a runtime behaviour.
- nono MUST NOT extend a key's life locally, cache a key across sessions, or reuse a key for another agent process.
- **Revocation at session end** (normal or abnormal): nono-proxy calls popeye's revocation for the session's `key_id`, authenticated with the user key that minted it. Revocation is idempotent: revoking an already expired or revoked key succeeds. Revocation by any other key is refused. If revocation fails, the key still expires at `expires_at`.
- A crashed proxy leaves nothing to sweep, because keys are memory-only. Expiry bounds the exposure.

## 5. Session Records (`NONO_v0.4.3`)

nono records agent-session facts in two supervisor-written records beside the enforcement receipt, so the receipt keeps its startup-only, content-free and policy-free invariants (D-20, D-05/D-14, D-12). All three files live in the receipt's existing directory.

### 5.1 Enforcement receipt: one census row (`<session_id>.receipt.json`)

`EnforcementReceipt.schema_version` becomes **2** and gains the census row `LayerId::AgentKeyInjection`:

| Session | Status |
|---|---|
| Agent profile, exchange returned a conforming key (§2.4 passed) | `Confirmed` |
| Agent profile, exchange failed or the key did not conform | `Unconfirmed`, `outcome = Refused` |
| Non-agent profile | `NotApplicable` |

The receipt carries no other agent field.

### 5.2 `AgentSessionRecord` (`<session_id>.agent.json`, startup-only)

Written at the attestation gate before `ResumeThread`, **only for agent sessions that are resumed** (`outcome = Ran`). Every value comes from the supervisor's own observation or popeye's exchange response, never from the confined process.

| Field | Type | Value |
|---|---|---|
| `schema_version` | `u16` | `1` |
| `session_id` | `String` | equals the receipt's `session_id` (the only `String` allowed) |
| `agent_id` | `AgentId` enum | e.g. `liam` |
| `purpose` | `PurposeId` enum | one of the 7 vocabulary purposes, kebab-case (`compliance-review`, `internal-support`, …) |
| `key_id` | `KeyId` (16 bytes) | from the exchange response; serialized as a lowercase canonical UUID string |
| `key_expires_at_unix` | `u64` | popeye's granted expiry, seconds since epoch (UTC) |
| `injected_on` | `Vec<ServiceId>` | resolved `inject_on` set (`gateway`, `hometown`, `olive`); no FQDNs |
| `direct_gateway` | `bool` | the value sent at mint |
| `profile_version` | `u32` | the agent profile's version |
| `proxy_port` | `u16` | nono-proxy's loopback port for the session |
| `written_at_unix` | `u64` | supervisor clock at write time |

**Deliberately absent:** `on_behalf_of` (identity-shaped; the ledger carries it, joined by `key_id`), FQDNs (content-shaped), `required` flags and egress mode (policy, not attestation), and `key_revoked` (an end-of-session fact; see §5.3).

### 5.3 `SessionEndRecord` (`<session_id>.end.json`, teardown)

Written when the session ends, after the revocation call.

| Field | Type | Value |
|---|---|---|
| `schema_version` | `u16` | `1` |
| `session_id` | `String` | same as above |
| `key_id` | `KeyId` | the session's key |
| `key_revoked` | `bool` | `false` if revocation failed |
| `ended_at_unix` | `u64` | supervisor clock at session end |

A supervisor crash may leave no end record. That absence is itself the signal, and `key_expires_at_unix` still bounds exposure.

### 5.4 Delivery and protection

- Writable by the supervisor only. The child can read `.receipt.json` and `.agent.json` but not necessarily `.end.json`.
- The child receives `NONO_RECEIPT_PATH` and `NONO_AGENT_RECORD_PATH`. Agent-specific names such as `LIAM_RECEIPT_PATH` are retired.
- POC position: records are protected by ACL only. A supervisor with an audit signing key MAY also write `<session_id>.agent.dsse.json`.

## 6. The Join

This reconciliation is what makes endpoint governance provable rather than asserted:

```
AgentSessionRecord.key_id                     ↔  ledger rows where key_id = record.key_id
AgentSessionRecord.agent_id / purpose         ≡  ledger agent_id / purpose (must match exactly)
ledger on_behalf_of                           =  the exchange response's on_behalf_of (carried by popeye, not by nono)
[written_at_unix, min(ended_at_unix, key_expires_at_unix)]  ⊇  ledger row timestamps for that key_id
```

- One governed session reconciles to **all and only** the ledger rows under its `key_id`. A row outside the window is a finding, not noise.
- Rows from model calls that hometown relays on the session key (`POPEYE_v0.4.2` §2.6) carry `relayed_by=hometown` and belong to the same session.
- With no end record, the window closes at `key_expires_at_unix`.
- The `on_behalf_of` roll-up (cost to the user, activity to the agent) comes from `POPEYE_v0.4` §2.3. This contract adds no attribution logic. It only requires both sides to carry identical `key_id`, `agent_id` and `purpose` values.

## 7. Open Items

These are carried from the ratified specs and are not decided here:

- **O1 · User key on the workstation** (`NONO_v0.4.1` §8 O1). Where the user key used for the exchange lives, and confirmation that it is outside every agent session's filesystem grant.
- **O2 · Replacing the user key** (`NONO_v0.4.1` §8 O2). Whether an Entra-token or machine-identity exchange later removes the long-lived user key from the endpoint. Out of scope for POC-2. This is where v0.1's D-1 (issuer identity) now lives.
- **O3 · Record signing** (`NONO_v0.4.3` §11 O2). Whether DSSE signing of the session records becomes required.
- **O4 · Receipt directory and ACL** (`NONO_v0.4.3` §11 O3). Recorded in the fork's own docs.
- **O5 · Endpoint detection contract.** Fold the still-unextracted `ENDPOINT_DETECTION_CONTRACT` (v0.3 item) into this seam's next review.

## 8. Requirements

The ratified specs own the requirements. This table maps the contract's sections to them.

| Contract § | Requirement | Side | Source REQ |
|---|---|---|---|
| §2.2 | Exchange enforces every issuance rule; each failure is distinct | popeye | `POPEYE_v0.4.1` §2.2 |
| §2.2 | `direct_gateway=false` keys are refused on unrelayed gateway calls | popeye | `POPEYE_v0.4.2` §2.6 |
| §2.3 | Every `key_id` is a lowercase canonical UUID, never reused | popeye | REQ-AGT-20 |
| §2.3 | The same `key_id` string appears on all five popeye surfaces | popeye | REQ-AGT-21 |
| §3 | Agent sessions inject the agent key, never the user key | nono | REQ-END-08 |
| §2.4 | A failed exchange or a non-conforming key means the child never starts | nono | REQ-END-09 |
| §3 | No agent key reaches disk, logs, records, the child's environment or its command line | nono | REQ-END-10 |
| §4 | Key revoked at session end; failure recorded (now in `SessionEndRecord`, REQ-END-21) | nono | REQ-END-12 |
| §4 | No silent re-mint on expiry | nono | REQ-END-13 |
| §5.1 | `AgentKeyInjection` census row; receipt `schema_version = 2` | nono | REQ-END-18 |
| §5.2 | `AgentSessionRecord` written for every resumed agent session, none for refused ones | nono | REQ-END-19, REQ-END-20 |
| §5.3 | `SessionEndRecord` written at teardown with the revocation result | nono | REQ-END-21 |
| §5 | All three records pass the content-free scan with only the `session_id` exception | nono | REQ-END-22 |
| §5.2 | `KeyId` serializes only as a lowercase canonical UUID | nono | REQ-END-23 |
| §5.2 | `PurposeId` matches the vendored vocabulary | nono | REQ-END-24 |
| §5.4 | Child receives both record paths and cannot write either file | nono | REQ-END-25 |
| §6 | One session reconciles to all and only its ledger rows; an injected out-of-window row fails reconciliation | both | **None yet.** No ratified REQ covers reconciliation; v0.1's REQ-CRED-07 is carried as a proposal for the next ratification |

## 9. Changes From v0.1

| v0.1 | v0.2 | Why |
|---|---|---|
| Request carried `principal_type`, `on_behalf_of`, `tenant_id`, `session_id`, `device_ref`, `requested_ttl_seconds` | Request is `agent_id`, `purpose`, `ttl_seconds`, `direct_gateway`, authenticated with the user's virtual key | `POPEYE_v0.4.1` §2.1, `POPEYE_v0.4.2` §2.6 |
| Response `key_ref` (format unspecified), `session_id`, `budget_scope` | Response `key_id` (lowercase UUID), `agent_id`, `purpose`, `on_behalf_of`, `principal_type` | `POPEYE_v0.4.1` §2.1, `POPEYE_v0.4.3` |
| D-1 issuer identity open; candidates were device attestation or a per-device token | Resolved for POC-2: nono authenticates with the user's own virtual key. Machine identity is a later stage (O2) | `NONO_v0.4.1` §4.1 |
| D-2 endpoint mapping | popeye's choice; the contract fixes only the fields | `POPEYE_v0.4.1` §2.1 |
| D-3 revocation best-effort or deferred | Required at session end, idempotent, minting user key only | `NONO_v0.4.1` §4.3, `POPEYE_v0.4.1` §2.4 |
| D-4 in-session renewal allowed with a new `key_ref` | No renewal and no silent re-mint; one key per session | `NONO_v0.4.1` §4.3 |
| D-5 receipt schema residency | `AgentSessionRecord` and `SessionEndRecord` beside the receipt; the receipt gains one census row | `NONO_v0.4.3` |
| Receipt carried `session_id`, `key_refs[]`, `agent_id`, `on_behalf_of` | Session facts live in the two records. `on_behalf_of` is ledger-only | `NONO_v0.4.3` §1, §5 |
| Injection toward the gateway only | Injection toward the profile's `inject_on` services | `NONO_v0.4.2` §2 |
| TTL "hours, not days" | POC-2 cap: 8 hours | `POPEYE_v0.4.1` §2.2 |
| REQ-CRED-01 to -08 | Mapped to the ratified REQs (§8); REQ-CRED-07 (reconciliation) has no ratified equivalent yet | The ratified specs own the requirements |

## 10. Change Control

This contract versions like the vocabulary: changes go by PR against the canonical fiskroad copy, with mandatory review by both teams. Consuming repos update their reference; they don't vendor a copy, because this is an interface spec, not a validation artifact. A change to a ratified source spec that affects §2–§6 requires a matching revision here. A change here that is not in a ratified spec requires re-ratification of the affected package first.
