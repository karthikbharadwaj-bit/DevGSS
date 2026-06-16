trigger EmailMessage on EmailMessage
(before insert,
before update,
before delete,
after insert,
after update,
after delete)
	{
        new Triggers()
                .bind(Triggers.Evt.beforeinsert, new EmailMessageTriggerHandler.EmailMessageBefore())
                .bind(Triggers.Evt.beforeupdate, new EmailMessageTriggerHandler.EmailMessageBefore())
                .bind(Triggers.Evt.beforedelete, new EmailMessageTriggerHandler.EmailMessageBefore())
                .bind(Triggers.Evt.afterinsert, new EmailMessageTriggerHandler.EmailMessageAfter())
                .bind(Triggers.Evt.afterupdate, new EmailMessageTriggerHandler.EmailMessageAfter())
                .bind(Triggers.Evt.afterdelete, new EmailMessageTriggerHandler.EmailMessageAfter())
                .bind(Triggers.Evt.afterinsert, new EmailMessageTriggerHandler.EmailMessageAfterCreateCase())
                .bind(Triggers.Evt.afterinsert, new EmailMessageTriggerHandler.PopulateFirstMessageDateOnRelatedCase())
                .bind(Triggers.Evt.afterinsert, new EmailMessageTriggerHandler.CreateCaseCommentsForEmailsFromStandardCNRFlow())
                .bind(Triggers.Evt.afterinsert, new EmailMessageTriggerHandler.CreateCaseCommentsForEmailsFromPartnerCNRFlow())
                .bind(Triggers.Evt.afterinsert, new EmailMessageTriggerHandler.CreateCaseCommentsForEmailsFromTCRCNRFlow())
                .bind(Triggers.Evt.afterinsert, new EmailMessageTriggerHandler.CreateCaseCommentsForBTCaseEmails())
                .bind(Triggers.Evt.afterinsert, new EmailMessageTriggerHandler.CreateCaseCommentsForDevPortalEmails())
                .manage();

}