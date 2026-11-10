// Nexus CRM. Mirrors backend/auth/access.py (team scoping, private
// deals, owner and supervisor writes) as policies of the same intent.

// ---- Guards -----------------------------------------------------------

@id("nexus.user_tenant_guard")
forbid (principal is Fiskroad::User, action, resource is Fiskroad::NexusDeal)
unless { principal.tenants.contains(resource.tenant_id) };

@id("nexus.agent_tenant_guard")
forbid (principal is Fiskroad::Agent, action, resource is Fiskroad::NexusDeal)
unless { principal.on_behalf_of.tenants.contains(resource.tenant_id) };

// A human needs some Nexus role at all.
@id("nexus.requires_role")
forbid (principal is Fiskroad::User, action, resource is Fiskroad::NexusDeal)
unless {
  principal in Fiskroad::Role::"nexus_admin" ||
  principal in Fiskroad::Role::"nexus_supervisor" ||
  principal in Fiskroad::Role::"nexus_principal" ||
  principal in Fiskroad::Role::"nexus_user"
};

// ---- Reads ------------------------------------------------------------

@id("nexus.admin_all")
permit (
  principal is Fiskroad::User in Fiskroad::Role::"nexus_admin",
  action,
  resource is Fiskroad::NexusDeal
);

// Team deals are visible to the team; private deals only to their owner
// or a supervisor (oversight role).
@id("nexus.team_read")
permit (
  principal is Fiskroad::User,
  action == Fiskroad::Action::"nexus.deal.read",
  resource is Fiskroad::NexusDeal
)
when {
  principal.teams.contains(resource.team_id) &&
  (!resource.is_private || resource.owner == principal ||
   principal in Fiskroad::Role::"nexus_supervisor")
};

// ---- Writes -----------------------------------------------------------

@id("nexus.supervisor_team_update")
permit (
  principal is Fiskroad::User in Fiskroad::Role::"nexus_supervisor",
  action == Fiskroad::Action::"nexus.deal.update",
  resource is Fiskroad::NexusDeal
)
when { principal.teams.contains(resource.team_id) };

@id("nexus.owner_write")
permit (
  principal is Fiskroad::User,
  action in [Fiskroad::Action::"nexus.deal.update", Fiskroad::Action::"nexus.deal.delete"],
  resource is Fiskroad::NexusDeal
)
when { resource.owner == principal };

// ---- Agents (TBAC, reads only — D-4) ---------------------------------

@id("nexus.agent_deal_review")
permit (
  principal is Fiskroad::Agent in Fiskroad::Role::"agent_nexus_reader",
  action == Fiskroad::Action::"nexus.deal.read",
  resource is Fiskroad::NexusDeal
)
when {
  context has task &&
  context.task.task_type == "nexus.deal_review" &&
  principal.on_behalf_of.teams.contains(resource.team_id) &&
  (!resource.is_private || resource.owner == principal.on_behalf_of)
};

// ---- olive executor (cross-system writes — D-4) ----------------------
// Writes only inside an approved proposal, for a user who could make the
// same write themselves, in that user's tenant.

@id("nexus.olive_executor_update")
permit (
  principal is Fiskroad::Application in Fiskroad::Role::"olive_executor",
  action == Fiskroad::Action::"nexus.deal.update",
  resource is Fiskroad::NexusDeal
)
when {
  context has task && context.task.task_type == "olive.proposal" &&
  context has acting_for &&
  context.acting_for.tenants.contains(resource.tenant_id) &&
  (resource.owner == context.acting_for ||
   context.acting_for in Fiskroad::Role::"nexus_admin" ||
   (context.acting_for in Fiskroad::Role::"nexus_supervisor" &&
    context.acting_for.teams.contains(resource.team_id)))
};
