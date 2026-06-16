@isTest
public class Test_BatchJob_ATBC {
    @isTest
    static void testCloseAndDowngradeLead() {
        Account acc = (Account) new SObjectBuilder(Account.sObjectType)
            .setFields(new Map<sObjectField, Object>{
                Account.Next_Renewal_Date__c => System.today(),
                Account.RC_User_ID__c => '12345'})
            .create()
            .getRecord();

        Lead lead = (Lead) new SObjectBuilder(Lead.sObjectType)
            .setFields(new Map<sObjectField, Object>{
                Lead.Firstname => 'John',
                Lead.LastName => 'Doe',
                Lead.Company => 'Test Company',
                Lead.Phone => '+1234567890',
                Lead.Email => 'test@test.com',
                Lead.LeadSource => 'About To Be Cancelled UK',
                Lead.ATBC_Stage__c => 'New',
                Lead.Account__c => acc.Id,
                Lead.User_ID__c => '12345'
            })
            .create()
            .getRecord();
        Test.setCreatedDate(lead.Id, Datetime.now().addDays(-60));
        
        Test.startTest();
            BatchJob_ATBCScheduler atbcScheduler = new BatchJob_ATBCScheduler();
            atbcScheduler.execute(null);
        Test.stopTest();

        Lead updatedLead = (Lead) new LeadSelector()
            .selectLeadById(new List<Object>{lead.Id})
            .selectFields(new List<String>{'ATBC_Stage__c', 'Status', 'Downgrade_Reason__c'})
            .executeQuery()
            .get(0);

        System.assertEquals(LeadHelper.ATBC_STAGE_CLOSED, updatedLead.ATBC_Stage__c);
        System.assertEquals(LeadHelper.STATUS_DOWNGRADED, updatedLead.Status);
        System.assertEquals(LeadHelper.DOWNGRADE_RETENTION_LEAD_CLOSED, updatedLead.Downgrade_Reason__c);
    }

    @isTest
    static void testLeadShouldRemainUntouched() {
        Account acc = (Account) new SObjectBuilder(Account.sObjectType)
            .setFields(new Map<sObjectField, Object>{
                Account.Next_Renewal_Date__c => System.today().addDays(-1),
                Account.RC_User_ID__c => '12345'})
            .create()
            .getRecord();

        Lead lead = (Lead) new SObjectBuilder(Lead.sObjectType)
            .setFields(new Map<sObjectField, Object>{
                Lead.Firstname => 'John',
                Lead.LastName => 'Doe',
                Lead.Company => 'Test Company',
                Lead.Phone => '+1234567890',
                Lead.Email => 'test@test.com',
                Lead.LeadSource => 'About To Be Cancelled UK',
                Lead.ATBC_Stage__c => 'New',
                Lead.Account__c => acc.Id,
                Lead.User_ID__c => '12345'
            })
            .create()
            .getRecord();
        
        Test.startTest();
            BatchJob_ATBCScheduler atbcScheduler = new BatchJob_ATBCScheduler();
            atbcScheduler.execute(null);
        Test.stopTest();

        Lead updatedLead = (Lead) new LeadSelector()
            .selectLeadById(new List<Object>{lead.Id})
            .selectFields(new List<String>{'ATBC_Stage__c', 'Status', 'Downgrade_Reason__c'})
            .executeQuery()
            .get(0);

        System.assertEquals(lead.ATBC_Stage__c, updatedLead.ATBC_Stage__c);
        System.assertEquals(LeadHelper.STATUS_NEW, updatedLead.Status);
        System.assertEquals(lead.Downgrade_Reason__c, updatedLead.Downgrade_Reason__c);
    }
}