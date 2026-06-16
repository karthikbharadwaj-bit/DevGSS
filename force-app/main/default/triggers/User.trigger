/*
* Trigger on User object
* Before Insert: Create Okta User
* Before Update: Reaasign cases from inactive user to his manager
*/
trigger User on User (before insert, before update, before delete, after insert, after update) {
    new Triggers()

        .bind(Triggers.Evt.beforeinsert, new UserTriggerHelper.SetPortalRole())
        .bind(Triggers.Evt.beforeupdate, new UserTriggerHelper.SetDeactivationDate())
        .bind(Triggers.Evt.afterupdate, new UserTriggerHelper.AutomatedCaseAssignment())
        .bind(Triggers.Evt.afterinsert, new UserTriggerHelper.DefineKCSGroupMembers())
        .bind(Triggers.Evt.afterupdate, new UserTriggerHelper.DefineKCSGroupMembers())
        .bind(Triggers.Evt.afterinsert, new UserTriggerHelper.AssignCLMPermissionForPartnerUsers())// Added for PRM-82
        .bind(Triggers.Evt.beforeupdate, new UserTriggerHelper.EURestricted_Validation())
        .bind(Triggers.Evt.afterupdate, new UserTriggerHelper.trackUserNameChangesForCSM()) // PBC-20541
        .bind(Triggers.Evt.afterupdate, new UserTriggerHelper.TrackManagerChangesForCSM())  // Added for PBC-26526 

        .manage();
}