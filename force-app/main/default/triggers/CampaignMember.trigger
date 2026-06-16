trigger CampaignMember on CampaignMember (before insert,
    before update,
    before delete,
    after insert,
    after update,
    after delete,
    after undelete
) {
    Feature_Toggle__c featureToogle = Feature_Toggle__c.getInstance();
    ByPassTrigger__c bypassTrigger = ByPassTrigger__c.getInstance();

    if (bypassTrigger != null && bypassTrigger.Bypass_Campaign_Member_Trigger__c == true) {
        System.debug('$$$ ByPassTrigger__c Active For Campaign Member $$$');
        return;
    }
    
    new Triggers()
            .bind(Triggers.Evt.beforeinsert, new CampaignMemberTriggerHandler.FirePlatformEventLog())
            .bind(Triggers.Evt.beforeinsert, new CampaignMemberTriggerHandler.CampaignAttribution())
            .bind(Triggers.Evt.afterinsert, new CampaignMemberTriggerHandler.FirePlatformEventCheck())
            .bind(Triggers.Evt.afterinsert, new CampaignMemberTriggerHandler.UpdateMostRecentCampaignValuesOnLeadAndContact())
            .bind(Triggers.Evt.beforeupdate, new CampaignMemberTriggerHandler.FirePlatformEventLog())
            .bind(Triggers.Evt.afterupdate, new CampaignMemberTriggerHandler.FirePlatformEventCheck())
            .bind(Triggers.Evt.afterupdate, new CampaignMemberTriggerHandler.UpdateMostRecentCampaignValuesOnLeadAndContact())
            .bind(Triggers.Evt.beforedelete, new CampaignMemberTriggerHandler.UpdateMostRecentCampaignValuesOnLeadAndContact())
            .manage();
}