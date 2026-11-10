// sit-cip. Mirrors today's role table (src/python_engine/auth.py,
// api/routes.py) so the move to Cedar changes where rules live, not
// what they say.

// ---- Tenant guards ----------------------------------------------------

@id("sitcip.user_tenant_guard")
forbid (principal is Fiskroad::User, action, resource is Fiskroad::SitcipRecord)
unless { principal.tenants.contains(resource.tenant_id) || principal.tenants.contains("*") };

// Agents get no wildcard: the delegating user's explicit tenants only.
@id("sitcip.agent_tenant_guard")
forbid (principal is Fiskroad::Agent, action, resource is Fiskroad::SitcipRecord)
unless { principal.on_behalf_of.tenants.contains(resource.tenant_id) };

// ---- Humans (RBAC) ----------------------------------------------------

@id("sitcip.operator")
permit (
  principal is Fiskroad::User in Fiskroad::Role::"sitcip_operator",
  action in [
    Fiskroad::Action::"sitcip.search",
    Fiskroad::Action::"sitcip.read",
    Fiskroad::Action::"sitcip.ingest",
    Fiskroad::Action::"sitcip.ai_assist",
    Fiskroad::Action::"sitcip.export_thread"
  ],
  resource is Fiskroad::SitcipRecord
);

@id("sitcip.owner")
permit (
  principal is Fiskroad::User in Fiskroad::Role::"sitcip_owner",
  action in [
    Fiskroad::Action::"sitcip.search",
    Fiskroad::Action::"sitcip.read",
    Fiskroad::Action::"sitcip.map_reference"
  ],
  resource is Fiskroad::SitcipRecord
);

@id("sitcip.auditor")
permit (
  principal is Fiskroad::User in Fiskroad::Role::"sitcip_auditor",
  action in [
    Fiskroad::Action::"sitcip.search",
    Fiskroad::Action::"sitcip.read",
    Fiskroad::Action::"sitcip.export_thread"
  ],
  resource is Fiskroad::SitcipRecord
);

@id("sitcip.admin")
permit (
  principal is Fiskroad::User in Fiskroad::Role::"sitcip_admin",
  action,
  resource is Fiskroad::SitcipRecord
);

// ---- Agents (TBAC) ----------------------------------------------------
// Grant AND delegating user's role AND task type: delegation narrows.

@id("sitcip.agent_investigation")
permit (
  principal is Fiskroad::Agent in Fiskroad::Role::"agent_sitcip_analyst",
  action in [
    Fiskroad::Action::"sitcip.search",
    Fiskroad::Action::"sitcip.read",
    Fiskroad::Action::"sitcip.ai_assist"
  ],
  resource is Fiskroad::SitcipRecord
)
when {
  principal.on_behalf_of in Fiskroad::Role::"sitcip_operator" &&
  context has task &&
  context.task.task_type == "sitcip.investigation"
};
