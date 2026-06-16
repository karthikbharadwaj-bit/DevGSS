/*******************************************************************
Handler class of trigger on CAP Request object
Auther: Diganta Sarkar (diganta.sarkar@ringcentral.com) 24-Jan-2022
********************************************************************/
public class CAPReq_TriggerHandler {
    
    public class CreateCapCase extends Triggers.TriggerHandlerBase {
        override public void handle() {
            List<Case> capCasesToCreate = new List<Case>();
            Map<String,Id> caseEmailVsCapIdMap = new Map<String,Id>();
            Map<Id,Id> capIdVsCaseIdMap = new Map<Id,Id>();
            Map<String,Cap_Request__c> uIdsVsCRMap = new Map<String,Cap_Request__c>();
            Map<String,Id> uIdsVsAccId = new Map<String,Id>();
            Map<String,Id> uIdsVsConId = new Map<String,Id>();

            for(Cap_Request__c capR : (List<Cap_Request__c>) Trigger.new){
                uIdsVsCRMap.put(capR.UID__c, capR);
            }

            List<Account> accs = [Select id,RC_User_ID__c from Account where RC_User_ID__c in : uIdsVsCRMap.keyset()];
            if(accs.size() > 0){
                for(Account a : accs){
                    uIdsVsAccId.put(a.RC_User_ID__c, a.Id);
                }
            }
            List<Contact> cons = [Select Id,User_Id__c from contact where User_Id__c in : uIdsVsCRMap.keyset() order by createdDate desc];
            if(cons.size() > 0){
                for(Contact c : cons){
                    uIdsVsConId.put(c.User_Id__c, c.Id);
                }
            }

            Group capQueue = [SELECT Id,Email FROM Group where Type = 'queue' and DeveloperName='CAP_Request' limit 1][0];

            for (CAP_Request__c cap : (List<Cap_Request__c>) Trigger.new) {
                Case c = new Case();
                c.OwnerId = capQueue.Id;
                c.AccountId = uIdsVsAccId.get(cap.UID__c);
                c.ContactId = uIdsVsConId.get(cap.UID__c);
                c.Subject = cap.Success_Criteria__c;
                c.recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('CAP Request').getRecordTypeId();
                c.Case_Contact_Email__c = cap.Requestor_Email__c;
                c.Details_of_the_Concern__c =   'Requestor Name: '+cap.Requestor_Name__c+';\n\n'+
                                                'CAP Escalation Reason: '+cap.CAP_Escalation_Reason__c+';\n\n'+
                                                'Problem Statement: '+cap.Problem_Statement__c+';\n\n'+
                                                'Success Criteria: '+cap.Success_Criteria__c+';\n\n'+
                                                'Product Family: '+cap.Product_Family__c+';\n\n'+
                                                'RingCentral CSM: '+cap.RingCentral_CSM__c+';\n\n'+
                                                'RingCentral TAM: '+cap.RingCentral_TAM__c+';\n\n'+
                                                'Account MRR: '+cap.Account_MRR__c+';\n\n'+
                                                'Contact Center MRR: '+cap.Contact_Center_MRR__c+';\n\n'+
                                                'Contract End Date: '+cap.Contract_End_Date__c+';\n\n'+
                                                'Additional Context: '+cap.Additional_Context__c;
                c.Description = cap.Problem_Statement__c;
                capCasesToCreate.add(c);
                caseEmailVsCapIdMap.put(c.Case_Contact_Email__c,cap.Id);
            }
            if(capCasesToCreate.size() > 0){
                Insert capCasesToCreate;
                for(Case c : capCasesToCreate){
                    capIdVsCaseIdmap.put(caseEmailVsCapIdMap.get(c.Case_Contact_Email__c), c.Id);
                }
                system.debug('nemesis capIdVsCaseIdmap---->'+capIdVsCaseIdmap);
                connectCase(capIdVsCaseIdmap);
            }
        }
    }
    
    @future
    public static void connectCase(Map<Id, Id> capRIdVsCaseIdmap){
        system.debug('nemesis inside connectCase() capRIdVsCaseIdmap---->'+capRIdVsCaseIdmap);
        List<Cap_Request__c> capRecs = [Select id, UID__c, Case__c from Cap_Request__c where id in : capRIdVsCaseIdmap.keyset()];
        if(capRecs.size() > 0){
            for(Cap_Request__c cap : capRecs){
                cap.Case__c = capRIdVsCaseIdmap.get(cap.id);
            }
            system.debug('nemesis inside connectCase() before update capRecs---->'+capRecs);
            Update capRecs;
            system.debug('nemesis inside connectCase() after update capRecs---->'+capRecs);
        }
    }
}