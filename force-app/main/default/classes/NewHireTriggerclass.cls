/**********************************************************************************************************
UPDATE

by:            eugenebasianomutya
date:          May 5, 2015
details:       Case 03574324 - Headset Procurement for New Hire   
               Copy the Parents' New_Hire_Desk_Phone__c to child when IT Helpdesk ticket is created.                 
***********************************************************************************************************/


public class NewHireTriggerclass { 
    static User supportAgentUser = null;
    static { 
        supportAgentUser = [SELECT Id, Name FROM User WHERE Name = 'RC Support Agent' LIMIT 1];
    } 
    public static Case getAssignedChildCases(case objCaseChild, case objCaseTrigger, string strRecordType){
        system.debug('objCaseTrigger'+objCaseTrigger);
        objCaseChild.ParentId = objCaseTrigger.id;
        objCaseChild.Origin = objCaseTrigger.Origin;
        objCaseChild.Hire_Name__c = objCaseTrigger.Hire_Name__c;
        if(supportAgentUser != null ) {
            objCaseChild.ownerId = supportAgentUser.Id;
        }
        objCaseChild.RecordTypeId =OpportunityHelper.getOppRecordTypeMap(strRecordType);
        objCaseChild.status = 'New';
        objCaseChild.Priority ='Medium';
        objCaseChild.contactId = objCaseTrigger.contactId;
        if(objCaseChild.contactId == null) {   
            try {
                getContact(objCaseChild, objCaseTrigger);
        
            } catch(exception e){}
        }
        objCaseChild.SuppliedEmail = objCaseTrigger.SuppliedEmail;
        objCaseChild.FormSubmitterEmail__c = objCaseTrigger.FormSubmitterEmail__c;
        objCaseChild.Location__c = objCaseTrigger.Location__c;
        objCaseChild.Job_title__c = objCaseTrigger.Job_title__c;
        return objCaseChild;            
    } 
    private static void getContact(Case objCaseChild, Case parentCase) {
        Account accObj = [SELECT id, (SELECT Id, Phone, Name, Email FROM Contacts
                                         WHERE Email =:parentCase.FormSubmitterEmail__c ORDER BY LastModifiedDate DESC LIMIT 1) FROM Account WHERE Name =:'RC Internal' LIMIT 1];
        if(accObj != null) {
            List<Contact> contactList = accObj.Contacts;
            if(contactList != null && contactList.size() != 0) {
                objCaseChild.ContactId = contactList.get(0).Id;
            } else {
                if(!String.isBlank(parentCase.FormSubmitterEmail__c)) {
                    Contact conObj = new Contact();
                    conObj.AccountId = accObj.Id;
                    conObj.LastName = parentCase.SuppliedName;
                    conObj.Email = parentCase.FormSubmitterEmail__c;
                    conObj.Phone = parentCase.SuppliedPhone;
                    if(!String.isBlank(conObj.LastName)&&conObj.LastName!=null){
                        insert conObj;
                        objCaseChild.ContactId = conObj.id;
                    }
                }
            }
        }           
    }        
    public static void createNewHireCases(Map<Id, Case> caseNewMap) {
        List<Case> caseList = caseNewMap.values();
        system.debug('@@@caseList@@@'+caseList);
        Schema.DescribeSObjectResult caseObjDetails = Case.SObjectType.getDescribe();
        Map<ID,Schema.RecordTypeInfo> rtMapByName = caseObjDetails.getRecordTypeInfosById(); 
        List<Case> lstCase = new List<Case>();
        List<string> stringList = new List<string>();
        for(Case cs : caseList) {
            if(rtMapByName.get(cs.RecordTypeId).getName()== 'IT New Hire Request') {
                Set<String> setString = new Set<String>(); 
                Set<string> setStrDP = new Set<String>();  
                if(setString.contains('SalesForce') || setString.contains('inContact') || cs.Requires_BizServ__c == true) {//if salesforce or incontains selected or both are selected
                       Case objCase =new Case();
                       objCase.Subject ='Biz Serv Account Request for Business Services '+cs.Hire_Name__c;
                       objCase.Description='Parent Case :' +cs.CaseNumber+'\nName:'+cs.Hire_Name__c+'\n'+
                                            'Add User to SFDC Call Center by default for Sales and Support Users.\n'+
                                            'Add User to DocuSign for Sales Users.\n'+
                                            'Account Creation Request:\n'+stringList ;
                       lstCase.add(getAssignedChildCases(objCase, cs, 'Internal Business Services'));
               }
               if(cs.ParentId == null) {
                   try{
                       Case objCase1 =new Case(Request_Type__c ='Helpdesk', Request_Subtype_1__c = 'Application', Request_Subtype_2__c='Account Creation');
                       objCase1.Subject ='IT Account Request for New Hire '+cs.Hire_Name__c;
                       objCase1.Description='Parent Case :' +cs.casenumber+ '\nName:'+cs.Hire_Name__c+'\nAccount Creation Request w/ Justification:\n'+stringList+' \nCreate Exchange/Rackspace email account'+'\nCreate Active Directory account'+'\nAdd Email to the correct Office Email Distribution List: '+cs.Location__c+'.' ;
                       system.debug('---------->'+stringList );                                                                     
                       lstCase.add(getAssignedChildCases(objCase1, cs,'IT Helpdesk'));
                       
                       Case objCase3 =new Case();                                                   
                       objCase3.Subject ='Employee and Contact Creation in SFDC for New Hire '+cs.Hire_Name__c;
                       objCase3.Description='Parent Case :' +cs.casenumber+'\nName:' +cs.Hire_Name__c+'\nAdd this employee as a Contact on RC Internal, and to the Employee object in SFDC.';
                       lstCase.add(getAssignedChildCases(objCase3, cs, 'IT Helpdesk'));
                   }catch(exception e){cs.addError(e.getMessage());}
               }
            }                
        }
        if(lstCase.size()>0){
            try{
                insert lstCase;
            }catch(Exception ex){
                caseList[0].addError('Problem in creating child Case.'+ex.getMessage());    
            }
        }                           
    } 

    public static void newHireupdate(Map<Id, Case> caseNewMap,Map<id,Case> caseOldMap ) {
        List<Case> caseList = caseNewMap.values();
        Schema.DescribeSObjectResult result = Case.SObjectType.getDescribe();
        Map<ID,Schema.RecordTypeInfo> rtMapByName = result.getRecordTypeInfosById(); 
        Map<Id,Case> caseMap = new Map<Id,Case>([Select Id, (Select Id, Status From Cases where status = 'New' limit 1) From 
                                                    Case where Id IN :caseNewMap.keySet()]);
        for(Case caseobj:caseList) {
            if(rtMapByName.get(caseObj.RecordTypeId).getName()== 'IT New Hire Request') {
                Case caseoldObj = caseOldMap.get(caseobj.id); 
                if(caseoldObj.Status != 'Closed' && caseobj.Status == 'Closed') {
                    if(caseMap != null && caseMap.get(caseobj.id).Cases != null && caseMap.get(caseobj.id).Cases.size()>0) {
                        caseobj.addError('Please close all the child cases before closing the parent.');
                    }
                }  
            }
        }
    }
}