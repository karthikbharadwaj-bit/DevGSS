/* 
*Class Name         : Batch_updateContactRoleinContact
*Business Purpose   : Update Customer Contact Role in Contact
*Developer Name     : Elakkiya Natarajan
Modification History:
*--------------------------------------------------------------------------------------------------------------------
Date              User Story#                   Developer Name                    Changes done
*-------------------------------------------------------------------------------------------------------------------
07/06/2022                                      Elakkiya                          New Batch Class
*/
global class Batch_updateContactRoleinContact implements Database.Batchable<sObject>, Database.Stateful{
    String query = '';

    global Batch_updateContactRoleinContact() {
       query = 'select id,contactId,AccountId,Role from AccountContactRole where Contact.Customer_Contact_Role__c = null and contact.Email != null  and Role != null and Role != \'[none]\' and Role != \'\'';
           }
    global Batch_updateContactRoleinContact(String condition) {
       query = 'select id,contactId,AccountId,Role from AccountContactRole where Contact.Customer_Contact_Role__c = null and contact.Email != null and Role != \'[none]\' and Role != \'\' and Role != null ' + condition;       
    }
    
global Database.QueryLocator start(Database.BatchableContext BC) { 
       return Database.getQueryLocator(query);
    }
    global void execute(Database.BatchableContext BC, List<AccountContactRole> acrList){
		Map<Id, Contact> contactupdMap = new Map<Id,Contact>();
		for(AccountContactRole acr: acrList)
        {
		    if(contactupdMap.containskey(acr.contactId))
		    {			 
				String Role = contactupdMap.get(acr.contactId).Customer_Contact_Role__c + ','+acr.Role;
				contactupdMap.put(acr.contactId, new contact(Id=acr.ContactId,Customer_Contact_Role__c=role));
			}
			  else
			{
				contactupdMap.put(acr.contactId,new contact(Id=acr.ContactId,Customer_Contact_Role__c=acr.Role));
			}
		}
		if(contactupdMap.size() >  0)
        {
            Triggers.switchOff();
            update contactupdMap.values();
            Triggers.switchOn();
        }       
    }
    global void finish(Database.BatchableContext BC) {       
        
    } 	
}