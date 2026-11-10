// Program-wide guards. Cedar denies by default and forbid overrides
// permit, so these hold whatever any system policy permits.

// TBAC: an agent acts only inside a task. No task binding, no access.
// (An expired or revoked binding is stopped earlier, by popeye
// introspection; this catches a request that arrives without one.)
@id("common.agent_requires_task")
forbid (principal is Fiskroad::Agent, action, resource)
unless { context has task };

// Agents never receive regulated-identifier records (vocabulary §1.2:
// structurally unapprovable).
@id("common.agent_no_regulated_identifier")
forbid (principal is Fiskroad::Agent, action, resource)
when { resource has data_class && resource.data_class == "regulated-identifier" };

// D-4: agents read Nexus directly but never write it; writes go through
// olive action types (principal Application, role olive_executor).
@id("common.agent_no_direct_nexus_write")
forbid (
  principal is Fiskroad::Agent,
  action in [Fiskroad::Action::"nexus.deal.update", Fiskroad::Action::"nexus.deal.delete"],
  resource
);

// Agents never author fleet policy or approve their own overrides.
@id("common.agent_no_nono_admin")
forbid (
  principal is Fiskroad::Agent,
  action in [Fiskroad::Action::"nono.profile.author", Fiskroad::Action::"nono.override.approve"],
  resource
);
