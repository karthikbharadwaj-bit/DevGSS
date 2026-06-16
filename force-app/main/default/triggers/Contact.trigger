/**
 * Created by capitan on 9/4/17.
 */

trigger Contact on Contact (
        before insert,
        before update,
        before delete,
        after insert,
        after update,
        after delete,
        after undelete
) {

    ByPassTrigger__c bypassTrigger = ByPassTrigger__c.getInstance();
    if ((bypassTrigger != null && bypassTrigger.Bypass_Contact_Trigger__c == true) || ContactTriggerHandler.bypassTrigger) {
        System.debug('$$$ ByPassTrigger__c Active For Contact $$$');
        return;
    }
    new Triggers()
            .bind(Triggers.Evt.beforeinsert, new ContactTriggerHandler.OldContactTriggerLogicBefore())
            .bind(Triggers.Evt.beforeupdate, new ContactTriggerHandler.OldContactTriggerLogicBefore())
 //.bind(Triggers.Evt.beforeupdate, new ContactTriggerHandler.ValidateEmailContactUpdateForPrimaryOrSignatoryContact())
        	.bind(Triggers.Evt.afterupdate, new ContactTriggerHandler.ValidateContactedit())

            .bind(Triggers.Evt.afterinsert, new ContactTriggerHandler.ProcessDUNSLogic())
            .bind(Triggers.Evt.afterupdate, new ContactTriggerHandler.ProcessDUNSLogic())
            .bind(Triggers.Evt.afterupdate, new ContactTriggerHandler.UpdateRelatedDFR())
            .bind(Triggers.Evt.afterinsert, new ContactTriggerHandler.OldContactTriggerLogicAfter())
            .bind(Triggers.Evt.afterupdate, new ContactTriggerHandler.OldContactTriggerLogicAfter())
            .bind(Triggers.Evt.beforeupdate, new ContactTriggerHandler.CampaingAttributionAndCampaignMemberCreation())
            .bind(Triggers.Evt.beforeupdate, new ContactTriggerHandler.ValidateContactStatusChange())
            .bind(Triggers.Evt.beforeupdate, new ContactTriggerHandler.PopulateSaasquatchFields())
            .bind(Triggers.Evt.afterupdate, new ContactTriggerHandler.PopulateSaasquatchReferralEmailOnAccount())
            .bind(Triggers.Evt.afterupdate, new ContactTriggerHandler.upsertSaasquatchReferralUser()) //CMR-323448
            .bind(Triggers.Evt.beforeinsert, new ContactTriggerHandler.WorkflowActions())
            .bind(Triggers.Evt.beforeupdate, new ContactTriggerHandler.WorkflowActions())
            .bind(Triggers.Evt.beforedelete, new ContactTriggerHandler.RemoveUnnecessaryCompanyPersons())
            .bind(Triggers.Evt.beforedelete, new ContactTriggerHandler.ValidateContactDeletion())
            .bind(Triggers.Evt.beforeinsert, new ContactTriggerHandler.ContactStatusValidations())
            .bind(Triggers.Evt.beforeupdate, new ContactTriggerHandler.ContactStatusValidations())
            .bind(Triggers.Evt.afterinsert, new ContactTriggerHandler.ContactPhoneNumberValidations())
            .bind(Triggers.Evt.afterupdate, new ContactTriggerHandler.ContactPhoneNumberValidations())
            .bind(Triggers.Evt.beforeinsert, new ContactTriggerHandler.PopulateContactZIShellAccount())
            .bind(Triggers.Evt.beforeupdate, new ContactTriggerHandler.PopulateContactZIShellAccount())
            .bind(Triggers.Evt.beforeinsert, new ContactTriggerHandler.PopulateCustomAccountId())
            .bind(Triggers.Evt.beforeupdate, new ContactTriggerHandler.PopulateCustomAccountId())
        	//.bind(Triggers.Evt.afterinsert, new ContactTriggerHandler.CreateContactExtensions()) //Create Contact Extensions //Commenting as Contact_Ext__c is no longer Used
            .bind(Triggers.Evt.afterupdate, new ContactTriggerHandler.disableCustomerCommunityUser())
            /* CRM-5077 - Added as Part of EU Data Privacy Project to restrict changing the Account Owner when the Record is of EU*/
            //.bind(Triggers.Evt.beforeupdate, new ContactTriggerHandler.CheckEUDataPrivacy()) Commented as a part of ITPMO-3741
            .bind(Triggers.Evt.beforeinsert, new ContactTriggerHandler.PopulateDateStatusChanged())
            .bind(Triggers.Evt.beforeupdate, new ContactTriggerHandler.PopulateDateStatusChanged())
            .bind(Triggers.Evt.beforedelete, new ContactTriggerHandler.RecalculateCDPDeliverStatusAccountField())
            .bind(Triggers.Evt.afterupdate, new ContactTriggerHandler.RecalculateCDPDeliverStatusAccountField())
            .manage();
}