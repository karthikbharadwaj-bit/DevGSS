public without sharing class Partner_Customer_ContactController {
    public static Map<String, String> createContactRecord(Contact newContact)
    {
        String selectedRole = 'Signatory';
        Map<String,String> resultMap = new Map<String,String>();
        // Adding try catch for exception handling
        try {
            
            List <RecordType> rtList = [select id, Name from RecordType where SobjectType='Contact' And Name = 'VAR Visible'];
            
            if(null!=rtList && rtList.size()>0){
                newContact.RecordTypeId = rtList.get(0).id;
            }
            if(null!=newContact.RC_Customer_Role__c && newContact.RC_Customer_Role__c!='') {
                selectedRole = newContact.RC_Customer_Role__c;
            }
            newContact.RC_Customer_Role__c = null;
            newContact.Marketo_Sync_Disabled__c = true;
                CommunityInfo comm = new CommunityInfo();
                Community_Details__mdt comDetail=CommunityInfo.getCommunityDetails();
            newContact.Avaya_Partnership_Contact__c = true;
            newContact.OwnerId = comDetail.Portal_Deal_Desk_User__c;
            // Inserting the Contact
            insert newContact;
            
            AccountContactRole acctContactRole = new AccountContactRole();
            
            acctContactRole.AccountId = newContact.AccountId;
            acctContactRole.ContactId = newContact.Id;
            acctContactRole.Role = selectedRole;
            acctContactRole.IsPrimary = newContact.Target_Account_Primary_Member__c;
            insert acctContactRole;                                    
            
            // Setting the success status and message in resultMap
            resultMap.put('status', 'success');
            resultMap.put('message', 'Contact created successfully!');        
        }
        catch(Exception e) {
            // Setting the error status and message in resultMap
            system.debug('Line number--> '+e.getLineNumber());
            resultMap.put('status', 'error');
            resultMap.put('message',e.getMessage());
        }
        return resultMap;      
    }
    
    public static List<Attachment> getAttachmentOppo(string recordId){
        //get list of attachments to be displayed in record detail page for selected deal support
        Set<Id> recordIds=new Set<Id>{recordId};
            List<Attachment> attachmentList =[Select Id,Name,ContentType FROM Attachment WHERE ParentId IN:recordIds];  
        if(!attachmentList.isEmpty()&&attachmentList!=null){  
            return attachmentList;  
        } else {
            return null; 
        }
    }
    
    public static String updateAccountContactRole(String accountId,String FirstName,String LastName,
                                                  String Email,String Phone,String CustomerRole,Boolean Target_Account_Primary_Member,
                                                  String accContactRoleId,String contactId){
                                                      List<AccountContactRole> accountRolePrimary = new List<AccountContactRole>();
                                                      String roleId = '\''+accContactRoleId+'\'';
                                                      try{
                                                          System.debug('Target_Account_Primary_Member--'+Target_Account_Primary_Member);
                                                          if(Target_Account_Primary_Member != null && Target_Account_Primary_Member){
                                                              accountRolePrimary = [SELECT Id FROM AccountContactRole WHERE AccountId=:accountId  and isPrimary =: true and Id != : accContactRoleId];
                                                          }
                                                          
                                                          if(accountRolePrimary.size() >0 && Target_Account_Primary_Member == true){
                                                              return ' You cannot create more than one Primary contact.';
                                                          }else{
                                                              AccountContactRole acctContactRole = new AccountContactRole();
                                                              acctContactRole.id = accContactRoleId;
                                                              acctContactRole.role  = CustomerRole;
                                                              acctContactRole.isPrimary = Target_Account_Primary_Member;
                                                              update acctContactRole;
                                                              
                                                              
                                                              Contact contactObj = new Contact();
                                                              contactObj.id = contactId;
                                                              contactObj.FirstName = FirstName;                                      
                                                              contactObj.LastName = LastName;
                                                              contactObj.Email = Email;
                                                              contactObj.Phone = Phone;
                                                              update contactObj; 
                                                              
                                                              return 'Updated Successfully';
                                                          } 
                                                      }catch(Exception e){
                                                          System.debug('Error '+e.getLineNumber()+e.getMessage());
                                                          if(e.getMessage().indexOf('FIELD_CUSTOM_VALIDATION_EXCEPTION') != -1){
                                                              String errMsg = e.getMessage().substring(
                                                                  (e.getMessage().indexOf('FIELD_CUSTOM_VALIDATION_EXCEPTION')+'FIELD_CUSTOM_VALIDATION_EXCEPTION'.length()+1)
                                                                  ,e.getMessage().length()-4);
                                                              return errMsg;
                                                          }else{
                                                              return e.getMessage(); 
                                                          }
                                                      }
                                                      
                                                      
                                                  }
    public static User createUserFromContact(User userObj){
        insert userObj;
        return userObj;
    }
}