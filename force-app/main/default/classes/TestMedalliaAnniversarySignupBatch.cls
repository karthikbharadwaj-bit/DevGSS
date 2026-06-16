@isTest
public class TestMedalliaAnniversarySignupBatch {

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void MedalliaAnniversarySignupBatch(){
        Test_Utils testRecordClass = new Test_Utils();
        
        try{
            // Creating Account Record.
            List<Account> testAccountList = new List<Account>();
            Account accountRecord = new Account();
            accountRecord.type = 'Customer';
            accountRecord.RC_Signup_Date__c = Date.Today().addDays(-365);
            testAccountList.add(accountRecord);
            testAccountList = testRecordClass.createAccountRecord(testAccountList);
            system.debug('#### testAccount - '+testAccountList);
            
            // Creating Contact Record.
            List<Contact> testContactList = new List<Contact>();
            Contact contactRecord = new Contact();
            contactRecord.AccountId = testAccountList[0].Id;
            testContactList.add(contactRecord);
            testContactList = testRecordClass.createContactRecord(testContactList);
            system.debug('#### testContact - '+testContactList);
            
            // Creating Account Contact Role.
            AccountContactRole acrRecord = new AccountContactRole();
            acrRecord.AccountId = testAccountList[0].Id;
            acrRecord.ContactId = testContactList[0].Id;
            acrRecord.IsPrimary =  true;
            acrRecord.Role = 'RC Admin User';            
            insert acrRecord;
            system.debug('#### acrRecord - '+acrRecord);
                  
            List<Medallia_Survey__c> MSurveyList = new List<Medallia_Survey__c>();
            
            // Creating Medallia Survey Record
            Medallia_Survey__c msRecord = new Medallia_Survey__c(
            SurveyType__c = 'Relationship',
            Account_Signup_Date__c = accountRecord.RC_Signup_Date__c,
            Account_Brand__c = 'RingCentral',
            Admin_Role__c = 'RC Admin User',
            Admin_Email__c = 'test1@gmail.com',
            Account_Status__c = 'Paid'                        
            );
            MSurveyList.add(msRecord);           
            insert MSurveyList;
            system.debug('#### MedRecord - '+msRecord);
            
            //Updating Anniversary SignUp Date to Today
            for (Medallia_Survey__c ms: MSurveyList){
                ms.Account_Anniversary_Signup_Date__c = date.today();
            }
            update MSurveyList;
            system.debug('#### UpdMedRecord - '+MSurveyList);
            
            /**Test.StartTest();
            MedalliaAnniversarySignupBatch ms = new MedalliaAnniversarySignupBatch();
            Database.executeBatch(ms);
            Test.stopTest();
            **/
            
            Test.StartTest();
            MedalliaAnniversarySignupBatch_Scheduler testsche = new MedalliaAnniversarySignupBatch_Scheduler();
            String sch = '0 0 23 * * ?';
            system.schedule('Test status Check', sch, testsche );
            Test.stopTest();
            
        }catch(Exception ex){
            system.debug('#### Error on line - '+ex.getLineNumber());
            system.debug('#### Error message - '+ex.getMessage());
        }
    }    
}