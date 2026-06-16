trigger DealSupportTrigger on Deal_Support__c (before insert, before update, after insert, after update) {
    
    new Triggers()
        .bind(Triggers.Evt.beforeinsert, new DealSupportTriggerHandler.PopulateDealSupportCountry())
        .bind(Triggers.Evt.beforeinsert, new DealSupportTriggerHandler.PopulateApprovedDiscountField())
        .bind(Triggers.Evt.beforeinsert, new DealSupportTriggerHandler.PopulateDealSupportFieldsWithPackageFields())
        .bind(Triggers.Evt.beforeupdate, new DealSupportTriggerHandler.PopulateDealSupportFieldsWithPackageFields())
        .bind(Triggers.Evt.afterinsert, new DealSupportTriggerHandler.HandleDealSupportShare())
        .bind(Triggers.Evt.afterupdate, new DealSupportTriggerHandler.InsertAttachmentsOnContracts())
        .bind(Triggers.Evt.afterupdate, new DealSupportTriggerHandler.UpdateApprovedQuantityOnQuoteLines())
        .bind(Triggers.Evt.afterupdate, new DealSupportTriggerHandler.HandleDealSupportShare())
        .manage();   
}