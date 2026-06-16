@isTest
public class CAPReqTrigger_Test {

    private static final String RINGCENTRAL_BRAND = 'RingCentral';
    
    @isTest
    public static void testCapReqToCaseCreation() {

        TriggerHandler.BY_PASS_CONTACT_ON_INSERT = true;
        TriggerHandler.BY_PASS_LEAD_UPDATE_ON_INSERT = true;
        TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT();
        TriggerHandler.BY_PASS_OPPORTUNITY_ON_INSERT();

        Triggers.switchOff();
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => 'testAcc',
                    Account.RC_Brand__c => RINGCENTRAL_BRAND,
                    Account.RC_User_ID__c => '43243423'
                }
            )
            .create()
            .getRecord();

        Contact cont = (Contact) new SObjectBuilder(Contact.SObjectType)
                .setFields(new Map<SObjectField, Object>{
                        Contact.FirstName => 'Test2',
                        Contact.LastName => 'Test2',
                        Contact.AccountId => acc.Id,
                        Contact.Email => 'test@test.com',
                        Contact.Phone => '1234567890',
                        Contact.Preferred_Language__c => 'en_US'
                })
                .create()
                .getRecord();   

        Triggers.switchOn();

        List<Cap_Request__c> capReqs;
        Test.startTest();
            capReqs = (List<Cap_Request__c>) new SObjectBuilder(Cap_Request__c.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Cap_Request__c.Account_MRR__c  => '34234',
                        Cap_Request__c.Additional_Context__c  => 'test context',
                        Cap_Request__c.Assigned_PM__c  => 'test user',
                        Cap_Request__c.CAP_Escalation_Reason__c  => 'test reason',
                        Cap_Request__c.UID__c => '43243423'
                    }
                )
                .quantity(1)
                .create()
                .getRecords();
        Test.stopTest();
        System.assertEquals(1, capReqs.size(), 'There should be 1 capReq created.');
    }
}