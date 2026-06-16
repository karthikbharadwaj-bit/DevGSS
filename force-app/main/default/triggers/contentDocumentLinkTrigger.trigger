trigger contentDocumentLinkTrigger on ContentDocumentLink (before insert, after insert) {

    if(Trigger.isInsert && Trigger.isBefore) {
        /*Schema.DescribeSObjectResult caseObj = Case.sObjectType.getDescribe();
        String caseKeyPrefix = caseObj.getKeyPrefix();
        
        Set<Id> caseIds = new Set<Id> ();
        for(ContentDocumentLink cdl : trigger.new) {
            caseIds.add(cdl.LinkedEntityId);
        }
        Id recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Collections Dispute').getRecordTypeId();
        Map<Id, Case> casesMap = new Map<Id, Case> ([select id, Account.type, RecordTypeId, Account.Avaya_Partnership_Account__c, Account.RC_Brand__c from Case where id IN :caseIds]);
        
        for(ContentDocumentLink cdl:trigger.new){
            Case caseRec = casesMap.get(cdl.LinkedEntityId);
            if((String.valueOf(cdl.LinkedEntityId)).startsWith(caseKeyPrefix) && (caseRec.Account.type == 'Customer') 
               && (caseRec.Account.Avaya_Partnership_Account__c == true) && (caseRec.RecordTypeId == recordTypeId)) {
                   cdl.ShareType = 'I';
                   cdl.Visibility = 'AllUsers';
               } 
        }*/
        
        FileShareLinkTriggerHandler.beforeInsertMethod(Trigger.new);
    }

    new Triggers()
        .bind(Triggers.Evt.afterinsert, new AttachmentTriggerHelper.BillOnBehalfProcessing_Aura())
        .bind(Triggers.Evt.afterinsert, new AttachmentTriggerHelper.KnowledgeContentSharing())
        .manage();

}