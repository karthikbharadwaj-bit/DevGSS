trigger Entitlement on Entitlement__c (
	before insert,
	before update,
	before delete,
	after insert,
	after update,
	after delete) {
		 ByPassTrigger__c bypassTrigger = ByPassTrigger__c.getInstance();
     	if (bypassTrigger != null && bypassTrigger.Bypass_Entitlement_Trigger__c == true) {
        System.debug('$$$ ByPassTrigger__c Active For Entitlement $$$');
        return;
     	}

		new Triggers()
            .bind(Triggers.Evt.beforeinsert, new EntitlementTriggerHelper.GetData())
            .bind(Triggers.Evt.beforeinsert, new EntitlementTriggerHelper.PrepopulateFields())

            .bind(Triggers.Evt.afterinsert, new EntitlementTriggerHelper.GetData())
            .bind(Triggers.Evt.afterinsert, new EntitlementTriggerHelper.OnAfterInsert())

            .bind(Triggers.Evt.afterupdate, new EntitlementTriggerHelper.GetData())
            .bind(Triggers.Evt.afterupdate, new EntitlementTriggerHelper.OnAfterUpdate())

            .bind(Triggers.Evt.beforeinsert, new EntitlementTriggerHelper.SetIsHiddenLicense())

	        .manage();
}