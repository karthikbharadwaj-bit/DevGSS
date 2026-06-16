trigger Campaign on Campaign (
    after update
) {

    ByPassTrigger__c bypassTrigger = ByPassTrigger__c.getInstance();
    if (bypassTrigger != null && bypassTrigger.Bypass_Campaign_Trigger__c == true) {
        System.debug('$$$ ByPassTrigger__c Active For Campaign $$$');
        return;
    }

    new Triggers()
        .bind(Triggers.Evt.afterupdate, new CampaignTriggerHandler.DFR_IntendedBrandPopulation())
        .manage();
}