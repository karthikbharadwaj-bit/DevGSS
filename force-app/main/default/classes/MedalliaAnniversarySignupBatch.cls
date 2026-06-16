global class MedalliaAnniversarySignupBatch implements Database.Batchable<SObject>, Database.Stateful {
    
    //Declaring Constant Variables
    public List<Medallia_Survey__c> AnnSigupAccountsList = new List<Medallia_Survey__c>();
    public Date CurrentDate = Date.today();
    public String ATT = 'AT&T';
    public String ACO = 'ACO';
    public String BT = 'BT';
    
    global Database.QueryLocator start(Database.BatchableContext BC){       
        system.debug('#### today date - '+CurrentDate);
        
        //Query to retrieve Medallia records with anniversary signup day
        try{
       //String Query = 'SELECT id, Account_Anniversary_Signup_Date__c, Account_Signup_Date__c FROM Medallia_Survey__c WHERE Account_Anniversary_Signup_Date__c =:CurrentDate';
            String Query = 'SELECT id, Account_Anniversary_Signup_Date__c, Account_Signup_Date__c FROM Medallia_Survey__c WHERE Admin_Role__c  = \'RC Admin User\' AND (NOT Admin_Email__c LIKE \'%ringcentral.com%\') AND (NOT Account_Brand__c LIKE :BT) AND (NOT Account_Brand__c LIKE :ATT) AND (NOT Account_Brand__c LIKE :ACO) AND Account_Brand__c != \'ATOS\' AND Account_Brand__c != \'Avaya Cloud Office\' AND Account_Brand__c != \'Telus\'AND Account_Status__c != \'Canceled\' AND Account_Status__c != \'Suspended\'AND Account_Status__c != \'Disabled\' AND SurveyType__c = \'Relationship\' AND Account_Anniversary_Signup_Date__c =:CurrentDate';
            return Database.getQueryLocator(query);
        }catch(Exception ex){
            system.debug('#### Error on line - '+ex.getLineNumber());
            system.debug('#### Error message - '+ex.getMessage());
            return null;
        }
    }
    
    global void execute(Database.BatchableContext BC, List<Medallia_Survey__c> scope){
        
        try{          
            for(Medallia_Survey__c survey : scope){
                if(survey.Account_Anniversary_Signup_Date__c == CurrentDate){
                    survey.Send_Anniversary_Signup_Survey__c = true;
                }
                AnnSigupAccountsList.add(survey);
            }
            update AnnSigupAccountsList;
        }catch(Exception ex){
            system.debug('#### Error on line - '+ex.getLineNumber());
            system.debug('#### Error message - '+ex.getMessage());
        }
    }
    
    global void finish(Database.BatchableContext BC){
        
    }
}