trigger DealQualificationTrigger on DQ_Deal_Qualification__c (after insert, before update, after update) {
    new Triggers()
        .bind(Triggers.Evt.beforeupdate, new DealQualificationHandler.SetClosedDateTime())
        .bind(Triggers.Evt.afterinsert, new DealQualificationHandler.DQHistoryHandler())
        .bind(Triggers.Evt.afterupdate, new DealQualificationHandler.DQHistoryHandler())
        .bind(Triggers.Evt.afterupdate, new DealQualificationHandler.QuoteApprovalStatusHandler())
        .bind(Triggers.Evt.afterupdate, new DealQualificationHandler.SendEmailsOnStatusChangeForPRM())
        .manage();
}