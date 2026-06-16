@isTest
private class Test_BatchJob_CheckMarketoFlag {
    private final static String TEST_DATA = 'Test Data';

    @isTest 
    private static void testUpdateMembersOnLead() {
        User us = [
                    SELECT Id, Name
                    FROM User
                    WHERE IsActive = true
                    AND Name = 'User Marketo'
                    LIMIT 1
                    ];
        System.runAs(us) {
        Lead ld = (Lead) new SObjectBuilder(Lead.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Lead.email => 'fake@email.com',
                    Lead.LastName => 'fakeLastName',
                    Lead.Company => 'fakeCompany',
                    Lead.Asset_Name__c => TEST_DATA,
                    Lead.Asset_Type__c => TEST_DATA
                }
            )
            .create()
            .getRecord();
        Campaign camp = (Campaign) new SObjectBuilder(Campaign.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Campaign.Name => 'fakeCampaign'
                }
            )
            .create()
            .getRecord();
        CampaignMember member = new CampaignMember();
        member.CampaignId = camp.Id;
        member.LeadId = ld.Id;
            insert member;

        Test.startTest();
            BatchJob_CheckMarketoFlag marketoBatch = new BatchJob_CheckMarketoFlag();
            Database.executeBatch(marketoBatch);
        Test.stopTest();

        member = [
                SELECT Asset_Name__c, Promo_Code__c,
                        Asset_Type__c
                FROM CampaignMember
                WHERE Id =: member.Id
                ];

        System.assertEquals(member.Asset_Name__c,
                            TEST_DATA,
                            'Marketo Batch Job Asset Name mapping was failed.');
        System.assertEquals(member.Asset_Type__c,
                            TEST_DATA,
                            'Marketo Batch Job Asset Type mapping was failed.');
        }
    }

    @isTest 
    private static void testUpdateMembersOnContact() {
        User us = [
                    SELECT Id, Name
                    FROM User
                    WHERE IsActive = true
                    AND Name = 'User Marketo'
                    LIMIT 1
                    ];
        System.runAs(us) {
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => 'testAcc'
                }
            )
            .create()
            .getRecord();
        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.FirstName => 'Test1',
                    Contact.LastName => 'Test1',
                    Contact.AccountId => acc.Id,
                    Contact.Email => 'test@test.com',
                    Contact.Phone => '1234567890',
                    Contact.Preferred_Language__c => 'en_US',
                    Contact.Asset_Name__c => TEST_DATA,
                    Contact.Asset_Type__c => TEST_DATA,
                    Contact.Promo_Code__c => TEST_DATA
                }
            )
            .create()
            .getRecord();
        Campaign camp = (Campaign) new SObjectBuilder(Campaign.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Campaign.Name => 'fakeCampaign'
                }
            )
            .create()
            .getRecord();
        CampaignMember member = new CampaignMember();
        member.CampaignId = camp.Id;
        member.ContactId = con.Id;
        insert member;

        Test.startTest();
            BatchJob_CheckMarketoFlag marketoBatch = new BatchJob_CheckMarketoFlag();
            Database.executeBatch(marketoBatch);
        Test.stopTest();

        member = [
                SELECT Asset_Name__c, Promo_Code__c,
                        Asset_Type__c
                FROM CampaignMember
                WHERE Id =: member.Id
                ];

        System.assertEquals(member.Asset_Name__c,
                            TEST_DATA,
                            'Marketo Batch Job Asset Name mapping was failed.');
        System.assertEquals(member.Asset_Type__c,
                            TEST_DATA,
                            'Marketo Batch Job Asset Type mapping was failed.');
        System.assertEquals(member.Promo_Code__c,
                            TEST_DATA,
                            'Marketo Batch Job Promo Code mapping was failed.');
        }
    }
}