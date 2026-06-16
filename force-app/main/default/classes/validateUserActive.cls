/**--------------------------------------------------------------------------------------------------
* Class Name   : validateUserActive
* Description  : Class invoked from Lightning component, to check whether user is active or not, if not activate user
* Author       : Siva Nekkalapudi
* CreatedDate  : 5-Jun-2021
------------------------------------------------------------------------------------------------------**/
public without sharing class validateUserActive {
  

/************************************************************
Description : Method to check if the license is active and also to activate user and cutom object field
@Param : None
@Return Type : Boolean 
************************************************************/
    @AuraEnabled
    public static Boolean saveTodoRecord() {
        String userId;
        if (!Test.isRunningTest()) {
           userId = UserInfo.getUserId();
        } else {
            License_Harvesting__c lhcuser =   [SELECT Id,Name , Is_Active__c, User_ID__c FROM License_Harvesting__c LIMIT 1];
            userId = lhcuser.Id;
        } 
        List<License_Harvesting__c> licenses = [SELECT Id,Name , Is_Active__c, User_ID__c FROM License_Harvesting__c WHERE Community_User_ID__c =:userId ];

        
        if(licenses.size()> 0 &&  licenses[0].User_ID__c !=null) {
            
            List<ID> accIds = new List<ID>();
            accIds.add(licenses[0].Id);
            User Usr = getUser(licenses[0].User_ID__c);
            if(!Usr.IsActive) {
                
                activateUser(Usr);
                updateActive(accIds);
            }
            return true;
            
        }
        
        
        return false;
    }

/************************************************************
Description : Furture Method to update the Custom object record
@Param : List of record ids
@Return Type : None 
************************************************************/    
    @future
    public static void updateActive(List<ID> recordIds) { 
        
        // Get those records based on the IDs

        List<License_Harvesting__c> licenses = new  List<License_Harvesting__c> ();
        for(License_Harvesting__c license : [SELECT Name,Is_Active__c FROM License_Harvesting__c WHERE Id IN :recordIds]) {
            license.Is_Active__c = true;
            license.Last_Login_Date__c = System.now(); 
            licenses.add(license);
        }
        update licenses;
        
    }
   
/************************************************************
Description : Method to return the user record for the user id passed as parameter
@Param : String
@Return Type : User 
************************************************************/
    public static User getUser(String usrId) {
        User u = [SELECT Id,IsActive FROM User WHERE Id=:usrId];
        Id userId = u.Id;
        Boolean isActive = u.isActive;
        return u;
        
    }
    
    
/************************************************************
Description : Method to activate user
@Param : User
@Return Type : None 
************************************************************/
    public static void activateUser(User usr) {
        String userId;
        Integer communityLicenseCount=0;
        Boolean isActive;
        
        usr.IsActive = true;
        update usr;
    }
    
}