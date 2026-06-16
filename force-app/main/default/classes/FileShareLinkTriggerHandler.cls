public class FileShareLinkTriggerHandler {
    public static void beforeInsertMethod(List<ContentDocumentLink> newList){        
        Set<Id> dealSupportIds = new Set<Id>();
        Set<Id> oppIds = new Set<Id>();
        Set<Id> caseIds = new Set<Id>();
        Set<Id> contractIds = new Set<Id>();
        List<ContentDocumentLink> contentLinks = new List<ContentDocumentLink>();
        List<ContentDocumentLink> contentLinkInsert = new List<ContentDocumentLink>();
        List<ContentDocumentLink> contentsLinkedToCases = new List<ContentDocumentLink>();
        List<ContentDocumentLink> contentsLinkedToContracts = new List<ContentDocumentLink>();
        system.debug('newList++'+newList);
        for(ContentDocumentLink cl : newList){
           
            if(cl.LinkedEntityId != null){
                system.debug('Link Id +++'+cl.LinkedEntityId);
                if(String.valueOf(cl.LinkedEntityId.getsobjecttype()) == 'Deal_Support__c'){
                    dealSupportIds.add(cl.LinkedEntityId);
                     cl.ShareType = 'I';
                    cl.Visibility = 'AllUsers';
                    contentLinkInsert.add(cl);
                }
                else if(String.valueOf(cl.LinkedEntityId.getsobjecttype()) == 'Opportunity'){
                    oppIds.add(cl.LinkedEntityId);
                    contentLinks.add(cl);
                }
                else if(String.valueOf(cl.LinkedEntityId.getsobjecttype()) == 'Case'){
                    caseIds.add(cl.LinkedEntityId);
                    contentsLinkedToCases.add(cl);
                }
                else if(String.valueOf(cl.LinkedEntityId.getsobjecttype()) == 'Contract'){
                    contractIds.add(cl.LinkedEntityId);
                    contentsLinkedToContracts.add(cl);
                }
            }
        }
        
        system.debug('Deal Ids +++'+dealSupportIds);
        system.debug('Opp Ids +++'+oppIds);
        Map<Id, Opportunity> mapOfOpp = new Map<Id, Opportunity>();
        if(!oppIds.isEmpty()){
            mapOfOpp = new Map<Id, Opportunity>([Select Id, Avaya_Partnership_Opportunity__c from Opportunity where Id In: oppIds]);
        }
                
        system.debug('contentLinks+++'+contentLinks);
        
        Id recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Collections Dispute').getRecordTypeId();  
        Map<Id, Case> casesMap = new Map<Id, Case>();
        if(!caseIds.isEmpty()){
            casesMap = new Map<Id, Case>([select id, Account.type, RecordTypeId, Account.Avaya_Partnership_Account__c, Account.RC_Brand__c from Case where id IN :caseIds]);
        }
        
        Map<Id, Contract> contractsMap = new Map<Id, Contract>();
        if(!contractIds.isEmpty()){
            contractsMap = new Map<Id, Contract>([Select Id,ContractNumber,Status,Source__c,Account.Type,Account.Avaya_Partnership_Account__c from Contract  where id IN :contractIds]);
        }
        
        if(!mapOfOpp.isEmpty()){
            system.debug('+++');
            for(ContentDocumentLink cl1 : contentLinks){
                if(mapOfOpp.get(cl1.LinkedEntityId).Avaya_Partnership_Opportunity__c == true) {
                    cl1.ShareType = 'I';
                    cl1.Visibility = 'AllUsers';
                    contentLinkInsert.add(cl1);
                    system.debug('Linkss +++'+cl1);
                }               
            }
        }
        
        if(!casesMap.isEmpty())     
        {
            for(ContentDocumentLink cdl : contentsLinkedToCases){
                Case caseRec = casesMap.get(cdl.LinkedEntityId);
                if((caseRec.Account!= null) && (caseRec.Account.type == 'Customer') 
                   && (caseRec.Account.Avaya_Partnership_Account__c == true) && (caseRec.RecordTypeId == recordTypeId)) {
                       cdl.ShareType = 'I';
                       cdl.Visibility = 'AllUsers';
                   } 
            }
        }
        
        if(!contractsMap.isEmpty()){
            for(ContentDocumentLink cl1 : contentsLinkedToContracts){
                if(contractsMap.get(cl1.LinkedEntityId).Account.Avaya_Partnership_Account__c == true) {
                    cl1.ShareType = 'I';
                    cl1.Visibility = 'AllUsers';
                }               
            }
        }
        system.debug('Content Ids to insert+++'+contentLinkInsert);   
    }
}