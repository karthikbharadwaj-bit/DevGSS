trigger OpportunityContactRole on OpportunityContactRole(
    before insert,
    before update,
    before delete,
    after insert,
    after update,
    after delete
) {
    new Triggers()
        .bind(Triggers.Evt.beforeinsert, new OpportunityContactRoleHandler.RestrictUserToCreateContactRole())
        .bind(Triggers.Evt.beforeupdate, new OpportunityContactRoleHandler.RestrictUserToCreateContactRole())
        .bind(Triggers.Evt.afterinsert, new OpportunityContactRoleHandler.UpdateContactLogic())
        .bind(Triggers.Evt.beforeDelete, new OpportunityContactRoleHandler.UpdateContactLogic())
        .bind(Triggers.Evt.beforeDelete, new OpportunityContactRoleHandler.DeletePrimaryOppContactValidation())
  .bind(Triggers.Evt.afterupdate, new OpportunityContactRoleHandler.UpdateOppPrimaryContact())

        .manage();
}