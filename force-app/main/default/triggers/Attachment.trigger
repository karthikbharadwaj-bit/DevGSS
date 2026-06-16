/*************************************************
Trigger on Attachment object
After Insert & Update: Set Responded and Last Touched fields as needed.
                       Send email to case owner of new attachment if parentId is a case.

UPDATE:

Updated By:			eugenebasianomutya
Date:					03042016
Case: 					04362176 - Remove distribution list from notification
Description: 			Do not send email to Support Tier 3 and US Support Tier 3

Updated By:			alexander savickiy
Date:					23.01.2017
Description: 			Copy attachments from dsfs__DocuSign_Status__c to Contract

/************************************************/

trigger Attachment on Attachment (before insert,before update,after insert, after update) {
    new Triggers()
        .bind(Triggers.Evt.beforeinsert, new AttachmentTriggerHelper.TellusProcessing())
        .bind(Triggers.Evt.afterinsert, new AttachmentTriggerHelper.TellusProcessing())
        .bind(Triggers.Evt.afterinsert, new AttachmentTriggerHelper.LegacyProcessing())
        .bind(Triggers.Evt.beforeupdate, new AttachmentTriggerHelper.TellusProcessing())
        .bind(Triggers.Evt.afterupdate, new AttachmentTriggerHelper.TellusProcessing())
        .bind(Triggers.Evt.afterupdate, new AttachmentTriggerHelper.LegacyProcessing())
        .bind(Triggers.Evt.afterupdate, new AttachmentTriggerHelper.DocuSignAttachmentProcessing())
        .bind(Triggers.Evt.afterinsert, new AttachmentTriggerHelper.PopulateNdaStatusOnAccount())
        .bind(Triggers.Evt.afterinsert, new AttachmentTriggerHelper.CopySignedNdaAttachmentToAccount())
        .bind(Triggers.Evt.afterinsert, new AttachmentTriggerHelper.ExecSupportProcessing())
        .bind(Triggers.Evt.afterinsert, new AttachmentTriggerHelper.BillOnBehalfProcessing())
        .manage();
}