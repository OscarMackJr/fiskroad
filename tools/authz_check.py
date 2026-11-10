#!/usr/bin/env python3
"""Validate and test the shared Cedar policies in contracts/authz/.

Checks (spec FISKROAD_ACCESS_CONTROL_RBAC_TBAC_v0.1 §6):
  1. Every policy validates against schema.cedarschema.
  2. Role names in policies come only from roles.yaml; <= 6 human roles per
     system (REQ-AC-02).
  3. Task types in policies come only from task_types.yaml and match the
     vocabulary's task_type_format (vocabulary v0.5 §5).
  4. Every fixture case returns its expected decision (REQ-AC-03 and others).
  5. Fail closed: with no policies loaded, every fixture case is denied
     (REQ-AC-01).

Usage: python tools/authz_check.py   (requires: pip install cedarpy pyyaml)
Exit status 0 = all checks pass.
"""
from __future__ import annotations

import json
import re
import sys
from pathlib import Path

import cedarpy
import yaml

ROOT = Path(__file__).resolve().parent.parent
AUTHZ = ROOT / "contracts" / "authz"
NS = "Fiskroad"


def load_policies() -> str:
    files = sorted((AUTHZ / "policies").rglob("*.cedar"))
    if not files:
        raise SystemExit("no policies found under contracts/authz/policies")
    return "\n\n".join(f.read_text(encoding="utf-8") for f in files)


def uid(kind: str, ident: str) -> str:
    return f'{NS}::{kind}::"{ident}"'


def to_request(case: dict) -> dict:
    p_kind, p_id = case["principal"]
    r_kind, r_id = case["resource"]
    return {
        "principal": uid(p_kind, p_id),
        "action": uid("Action", case["action"]),
        "resource": uid(r_kind, r_id),
        "context": case.get("context", {}),
    }


def main() -> int:
    errors: list[str] = []
    schema = (AUTHZ / "schema.cedarschema").read_text(encoding="utf-8")
    policies = load_policies()
    roles = yaml.safe_load((AUTHZ / "roles.yaml").read_text(encoding="utf-8"))
    task_types = yaml.safe_load((AUTHZ / "task_types.yaml").read_text(encoding="utf-8"))
    vocab = yaml.safe_load((ROOT / "contracts" / "vocabulary.yaml").read_text(encoding="utf-8"))

    # 1. Schema validation.
    result = cedarpy.validate_policies(policies, schema)
    if not result.validation_passed:
        errors += [f"schema validation: {e}" for e in result.errors]

    # 2. Role catalogue.
    known_roles = {r["name"] for rs in roles["human_roles"].values() for r in rs}
    known_roles |= {r["name"] for r in roles["agent_grants"]}
    known_roles |= {r["name"] for r in roles["application_roles"]}
    used_roles = set(re.findall(r'Role::"([^"]+)"', policies))
    for name in sorted(used_roles - known_roles):
        errors.append(f"role not in roles.yaml: {name}")
    for system, rs in roles["human_roles"].items():
        if len(rs) > 6:
            errors.append(f"{system} has {len(rs)} human roles; the limit is 6 (REQ-AC-02)")

    # 3. Task types.
    fmt = re.compile(vocab["task_type_format"])
    registered = {t["name"] for t in task_types["task_types"]}
    for name in sorted(registered):
        if not fmt.fullmatch(name):
            errors.append(f"task type does not match task_type_format: {name}")
    used_types = set(re.findall(r'task_type\s*==\s*"([^"]+)"', policies))
    for name in sorted(used_types - registered):
        errors.append(f"task type not in task_types.yaml: {name}")

    # 4 and 5. Fixtures, with policies and with none.
    cases_run = 0
    for path in sorted((AUTHZ / "fixtures").glob("*.json")):
        fixture = json.loads(path.read_text(encoding="utf-8"))
        entities = fixture["entities"]
        for case in fixture["cases"]:
            cases_run += 1
            request = to_request(case)
            got = cedarpy.is_authorized(request, policies, entities, schema=schema)
            decision = "Allow" if got.decision == cedarpy.Decision.Allow else "Deny"
            if decision != case["expect"]:
                reasons = ", ".join(got.diagnostics.reasons) or "none"
                errs = "; ".join(str(e) for e in got.diagnostics.errors) or "none"
                errors.append(
                    f"{path.name} :: {case['name']}: expected {case['expect']}, got {decision}"
                    f" (policies: {reasons}; errors: {errs})"
                )
            empty = cedarpy.is_authorized(request, "", entities, schema=schema)
            if empty.decision != cedarpy.Decision.Deny:
                errors.append(f"{path.name} :: {case['name']}: allowed with no policies (REQ-AC-01)")

    if errors:
        print(f"authz check FAILED ({len(errors)} problem(s)):")
        for e in errors:
            print(f"  - {e}")
        return 1
    print(
        f"authz check passed: policies valid against schema; {len(used_roles)} roles and "
        f"{len(used_types)} task types in catalogue; {cases_run} fixture cases match; "
        "empty policy set denies all."
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
