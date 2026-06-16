public class OpportunitySurveyClass {
    
    Set<Id> oppIds;
    Set<id> accIds;
    Map<id, String> SurveyOppMap;
    Map<id, Opportunity> newOppMap;
    Map<id, List<AccountContactRole>> newAccContRMap; //In the case when we have to fetch ContactRole form Account
    Map<id, List<Contact>> newAccContMap; //
    List<Survey__c> surveyList ;
    String surveyType;
    String event;
        
    public OpportunitySurveyClass(Set<id> oppSet, String sType, String onInsert) {
            
            event = onInsert;
            newAccContRMap = new Map<id, List<AccountContactRole>>();
            newAccContMap = new Map<id, List<Contact>>();
            surveyType = sType;
        
                /*Collect all Required data for creating survey*/
                surveyList = new List<Survey__c>();
                newOppMap = new Map<id, Opportunity>([Select (Select SurveyType__c From Surveys__r),AccountID, 
                                                 Owner.Team__c, Owner.ManagerId, Owner.Manager.Name, Owner.Manager.Email , Owner.UserRoleId,Account.Is_Demo_Account__c, 
                                                 Owner.Email, Owner.Name, OwnerId From Opportunity WHERE id IN : OppSet AND AccountID != NULL]);    
                
                if(newOppMap.size() > 0) {
                    accIds = new Set<id>();
                    for(Opportunity opp : newOppMap.values()){
                        accIds.add(opp.Accountid);
                    }
                    
                }
                if(accIds.size() > 0){  
                    String queryStr = 'SELECT id,(SELECT Id, AccountId, ContactId, IsPrimary, Contact.Email,CreatedDate' 
                                             +' From AccountContactRoles ORDER BY IsPrimary DESC LIMIT 1 ),'
                                             +' (Select Id, Email, HasOptedOutOfEmail, CreatedDate From Contacts' 
                                             +' WHERE HasOptedOutOfEmail = false ORDER BY CreatedDate DESC LIMIT 1)'
                                             +' From Account  WHERE id IN: accIds';
                    //Case 05223375 : Remove the marketingSuspend__c from code - END

                    System.debug(queryStr);
                    List<sObject> sobjList = Database.query(queryStr);
                    if(sobjList != null && sobjList.size() != 0) {
                        for(SObject obj : sobjList) {
                            Account acc = (Account) obj;
                            newAccContRMap.put(acc.id , acc.AccountContactRoles);
                            newAccContMap.put(acc.id , acc.Contacts );
                        }
                    }
                }
                    
                makeSurvey(newOppMap.values());
              
    }
        
    public OpportunitySurveyClass(Set<id> OppSet, String sType ) {
        
                surveyType = sType;
                newAccContMap = new Map<id, List<Contact>>();
                /*Collect all Required data for creating survey*/
                surveyList = new List<Survey__c>();
                newOppMap = new Map<id, Opportunity>([Select (Select SurveyType__c From Surveys__r), 
                                                 (Select ContactId, Contact.Email, IsPrimary From OpportunityContactRoles WHERE Contact.Email !=null), 
                                                 Owner.Team__c, Owner.ManagerId, Owner.Manager.Name, Owner.Manager.Email , Owner.UserRoleId, Account.Is_Demo_Account__c, 
                                                 Owner.Email, Owner.Name, AccountID,OwnerId From Opportunity WHERE id IN : OppSet]);    

                if(newOppMap.size() > 0) {
                    accIds = new Set<id>();
                    for(Opportunity opp : newOppMap.values()){
                        accIds.add(opp.Accountid);
                    }
                }
                System.debug('##########'+accIds);
                if(accIds.size() > 0) {
                    for(Account acc: [Select id,(Select Id, Email, HasOptedOutOfEmail, CreatedDate From Contacts 
                                                 WHERE HasOptedOutOfEmail = false  ORDER BY CreatedDate DESC LIMIT 1)
                                                 From Account  WHERE id IN: accIds]) {
                            newAccContMap.put(acc.id , acc.Contacts );
                    }
                }
                
                makeSurvey(newOppMap.values());
                
    }
    
    public void makeSurvey(List<Opportunity> oppList) {
         for(Opportunity opp:oppList) {
                if(!isSurveyExist( surveyType , opp.id)) {
                    surveyList.add(createSurvey(opp));
                }
            }
            if(surveyList != null && surveyList.size() > 0) { 
                try {
                    insert surveyList;
                } catch(Exception ex) {}
            }
    }
    
    public Boolean isSurveyExist(String surveyType, ID oppid) {
      boolean flag = false; 
      for(Survey__c surveyObj: newOppMap.get(oppid).Surveys__r ) {
            if(surveyObj.SurveyType__c == surveyType ) {
                 flag = true;
                 return flag;
            }
      }
      return false;
    }
    
          
    public Survey__c createSurvey(Opportunity opp) { 
        Survey__c surveyObj = new Survey__c();
        if(event == null) {
            System.debug('### Preparing Contact info');
            if(newOppMap.get(opp.id).OpportunityContactRoles != NULL &&  newOppMap.get(opp.id).OpportunityContactRoles.size() != 0) {
                System.debug('### Contact Role'+'='+newOppMap.get(opp.id).OpportunityContactRoles );
                for(OpportunityContactRole Ocr : newOppMap.get(opp.id).OpportunityContactRoles ){
                /* Fetch primary contact if avialable*/ 
                    if(Ocr.IsPrimary) {
                        surveyObj.Contact__c = Ocr.ContactId;
                        surveyObj.Contact_Email__c = Ocr.Contact.Email;
                        break;
                    } else {
                        surveyObj.Contact__c = Ocr.ContactId;
                        surveyObj.Contact_Email__c = Ocr.Contact.Email;
                    }
                }
            } else if(newAccContMap.get(opp.AccountID) != NULL && newAccContMap.get(opp.AccountID).size() !=0) {
                System.debug('### IN Contact Itself');
                for(Contact cont  :(List<Contact>) newAccContMap.get(opp.AccountID)) {
                    surveyObj.Contact__c = cont.Id;
                    surveyObj.Contact_Email__c = cont.Email;
                }   
            }
         }
         
        if(event != null && event=='ON_INSERT') {
            if(newAccContRMap.get(opp.AccountID) != NULL && newAccContRMap.get(opp.AccountID).size() !=0 ) {
                for(AccountContactRole acr :(List<AccountContactRole>) newAccContRMap.get(opp.AccountID)){
                            /* Fetch primary contact if avialable*/ 
                            if(acr.IsPrimary) {
                                surveyObj.Contact__c = acr.ContactId;
                                surveyObj.Contact_Email__c = acr.Contact.Email;
                                break;
                            } else {
                                surveyObj.Contact__c = acr.ContactId;
                                surveyObj.Contact_Email__c = acr.Contact.Email;
                            }
                     }
            } else if(newAccContMap.get(opp.AccountID) != NULL && newAccContMap.get(opp.AccountID).size() !=0) {
                for(Contact cont  :(List<Contact>) newAccContMap.get(opp.AccountID)) {
                                surveyObj.Contact__c = cont.Id;
                                surveyObj.Contact_Email__c = cont.Email;
                }   
            }
        }
        surveyObj.Account__c = opp.AccountId;
        surveyObj.Opportunity__c = opp.Id;
        surveyObj.Agent__c = opp.OwnerId;
        surveyObj.Agent_Email__c = opp.Owner.Email;
        surveyObj.Agent_Name__c = opp.Owner.Name;
        surveyObj.Agent_Team__c = opp.Owner.Team__c;
        surveyObj.Agent_Manager_Name__c = opp.Owner.Manager.Name;
        surveyObj.Agent_Manager_Email__c = opp.Owner.Manager.Email;
        surveyObj.Name = surveyType +' - ' + Datetime.now().format();
        surveyObj.SurveyType__c = surveyType;
        return surveyObj;   
    }
 }