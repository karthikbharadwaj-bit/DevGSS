@IsTest
private class Test_BatchCheckCompanyAndTerritoryOwners {

    @TestSetup static void setup() {
        User owner = new User(
                ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id,
                LastName = 'owner',
                Email = 'puser000@amamama.com',
                Username = 'puser000@amamama.com' + System.currentTimeMillis(),
                CompanyName = 'TEST',
                Title = 'title',
                Alias = 'alias',
                TimeZoneSidKey = 'America/Los_Angeles',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US'
        );

        User alternateOwner = new User(
                ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id,
                LastName = 'alternateOwner',
                Email = 'puser000@amamama.com',
                Username = 'puser000@amamama.com' + System.currentTimeMillis(),
                CompanyName = 'TEST',
                Title = 'title',
                Alias = 'alias',
                TimeZoneSidKey = 'America/Los_Angeles',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US'
        );

        insert owner;
        insert alternateOwner;

        Territory_Data__c territoryData = new Territory_Data__c(
                Name = 'testTerritory',
                Territory_Owner__c = owner.Id,
                Alternate_Owner__c = alternateOwner.Id);

        insert territoryData;

        Account_Hierarchy__c company = new Account_Hierarchy__c(Name = 'finalTestCompany', Territory__c = territoryData.Id);
        insert company;
    }

    @isTest static void testExecution() {
        Test.startTest();
        BatchJob_CheckCompanyAndTerritoryOwners batch = new BatchJob_CheckCompanyAndTerritoryOwners(1);
        Database.executeBatch(batch);
        Test.stopTest();

        Account_Hierarchy__c company = [SELECT AH_Owner__c,AH_Owner__r.LastName,AH_Territory_Name__c,AH_Alternate_Owner__c,Territory__c FROM Account_Hierarchy__c];
        Territory_Data__c territory = [SELECT Territory_Owner__c,Alternate_Owner__c,Name FROM Territory_Data__c];
        System.assertEquals(company.AH_Owner__c, territory.Territory_Owner__c);
        System.assertEquals(company.AH_Territory_Name__c, territory.Name);
        System.assertEquals(company.AH_Alternate_Owner__c, territory.Alternate_Owner__c);
    }
}