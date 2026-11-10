// nono. Evaluated by the Cedar-backed ApprovalBackend
// (crates/nono/src/supervisor/mod.rs). A Deny here is not final for a
// capability request: it escalates to the interactive approval path, as
// today. A Deny for fleet administration is final.

// ---- Humans (RBAC) ----------------------------------------------------

@id("nono.policy_admin_author")
permit (
  principal is Fiskroad::User in Fiskroad::Role::"nono_policy_admin",
  action == Fiskroad::Action::"nono.profile.author",
  resource is Fiskroad::NonoProfile
);

@id("nono.override_approver")
permit (
  principal is Fiskroad::User in Fiskroad::Role::"nono_override_approver",
  action == Fiskroad::Action::"nono.override.approve",
  resource is Fiskroad::NonoCapability
);

// ---- Agents (TBAC) ----------------------------------------------------
// Inside a coding session, filesystem capabilities are granted without a
// prompt; network egress always escalates to a human.

@id("nono.agent_coding_fs")
permit (
  principal is Fiskroad::Agent in Fiskroad::Role::"agent_nono_coder",
  action == Fiskroad::Action::"nono.capability.request",
  resource is Fiskroad::NonoCapability
)
when {
  principal.on_behalf_of in Fiskroad::Role::"nono_operator" &&
  context has task &&
  context.task.task_type == "nono.coding_session" &&
  (resource.kind == "fs_read" || resource.kind == "fs_write")
};
