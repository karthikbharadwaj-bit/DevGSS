trigger LocalSubscribedAddress on LocalSubscribedAddress__c (
    before insert,
    before update,
    before delete,
    after insert,
    after update,
    after delete) {
    new Triggers()
        .bind(Triggers.Evt.beforeinsert, new LocalSubscribedAddressTriggerHandler.ValidateRegisteredAddress())
        .bind(Triggers.Evt.beforeinsert, new LocalSubscribedAddressTriggerHandler.RestrictAddressCreationAfterApproveReject())
        .bind(Triggers.Evt.beforeinsert, new LocalSubscribedAddressTriggerHandler.RestrictToCreateMoreThanOneLsaWithBillingAddressRt())
        .bind(Triggers.Evt.beforeupdate, new LocalSubscribedAddressTriggerHandler.ValidateChangedFieldsAfterApprove())
        .bind(Triggers.Evt.beforeDelete, new LocalSubscribedAddressTriggerHandler.RestrictAddressDeletionAfterApproveReject())
        .bind(Triggers.Evt.beforedelete, new LocalSubscribedAddressTriggerHandler.RestrictToDeleteLsaWithBillingAddressRecordType())
        .manage();
}