@isTest
private class Test_ValidateLeadDuplicacy {
    static Schema.DescribeSObjectResult leadDescribe = Lead.SObjectType.getDescribe();
    static Map<string,Schema.RecordTypeInfo> mapRtByName = leadDescribe.getRecordTypeInfosByName();
    
    @IsTest
    static void testValidatePerToday_noDuplicate() {
        List<Lead> upcomingLeads = new List<Lead>();
        Lead lead1 = (Lead) new SObjectBuilder(Lead.sObjectType)
            .setField(Lead.Email, 'test1@test.com')
            .build()
            .getRecord();
        upcomingLeads.add(lead1);
        Lead lead2 = (Lead) new SObjectBuilder(Lead.sObjectType)
            .setField(Lead.Email, 'test2@test.com')
            .build()
            .getRecord();
        upcomingLeads.add(lead2);
        
        Test.startTest();
        List<Lead> newLeadObjs = ValidateLeadDuplicacy.validatePerToday(upcomingLeads);
        Test.stopTest();

        System.assertEquals(2, newLeadObjs.size(), 'at least one lead was marked as duplicate');
        System.assertEquals('false', lead1.isDuplicate__c, 'lead1 is was not marked as duplicate');
        System.assertEquals(false, lead1.Duplicate_Lead__c, 'lead1 is was not marked as duplicate');
        System.assertEquals('false', lead2.isDuplicate__c, 'lead2 is was not marked as duplicate');
        System.assertEquals(false, lead2.Duplicate_Lead__c, 'lead2 is was not marked as duplicate');
    }
    
    @IsTest
    static void testValidatePerToday_duplicateLead() {
        List<Lead> upcomingLeads = new List<Lead>();
        Lead lead1 = (Lead) new SObjectBuilder(Lead.sObjectType)
            .setField(Lead.Email, 'test1@test.com')
            .build()
            .getRecord();
        upcomingLeads.add(lead1);
        Lead lead2 = (Lead) new SObjectBuilder(Lead.sObjectType)
            .setField(Lead.Email, 'test1@test.com')
            .setField(Lead.Status, 'X. Open')
            .build()
            .getRecord();
        insert lead2;
        
        Test.startTest();
        List<Lead> newLeadObjs = ValidateLeadDuplicacy.validatePerToday(upcomingLeads);
        Test.stopTest();
        
        System.assertEquals(0, newLeadObjs.size(), 'the lead should be marked as duplicated');
        System.assertEquals('true', upcomingLeads[0].isDuplicate__c, 'lead 1 should be marked as duplicate');
        System.assertEquals(true, upcomingLeads[0].Duplicate_Lead__c, 'lead 1 should be marked as duplicate');
        System.assertEquals(lead2.Id, upcomingLeads[0].existingLeadId__c, 'lead 1 should be marked as duplicate of lead 2');
    }

    @isTest
    static void testValidatePerStatusWithNoDuplicateLeads() {
        List<Lead> leadList = new List<Lead>();
        Lead lead1 = (Lead) new SObjectBuilder(Lead.sObjectType)
            .setField(Lead.Email, 'john.doe@example.com')
            .setField(Lead.Status, '1.5 Call Out')
            .create()
            .getRecord();
        Lead lead2 = (Lead) new SObjectBuilder(Lead.sObjectType)
            .setField(Lead.Email, 'jane.doe@example.com')
            .setField(Lead.Status, '2. Contacted')
            .build()
            .getRecord();
        leadList.add(lead2);
        
        List<Lead> validatedLeads = ValidateLeadDuplicacy.validatePerStatus(leadList);
        
        System.assertEquals(leadList.size(), validatedLeads.size(), 'both list should have one lead');
        System.assert(!leadList[0].Duplicate_Lead__c && leadList[0].isDuplicate__c == null, 'lead should not have been marked as duplicate');
    }
    
    @isTest
    static void testValidatePerStatusWithDuplicateLeads() {
        List<Lead> leadList = new List<Lead>();
        Lead lead1 = (Lead) new SObjectBuilder(Lead.sObjectType)
            .setField(Lead.Email, 'john.doe@example.com')
            .setField(Lead.Status, '1.5 Call Out')
            .create()
            .getRecord();
        Lead lead2 = (Lead) new SObjectBuilder(Lead.sObjectType)
            .setField(Lead.Email, 'john.doe@example.com')
            .setField(Lead.Status, '2. Contacted')
            .build()
            .getRecord();
        leadList.add(lead2);

        List<Lead> validatedLeads = ValidateLeadDuplicacy.validatePerStatus(leadList);
        
        Lead duplicatedLead = leadList[0];
        System.assertEquals(0, validatedLeads.size(), 'no leads should be returned since the lead used is duplicated');
        System.assert(duplicatedLead.Duplicate_Lead__c && duplicatedLead.isDuplicate__c == 'true' && duplicatedLead.LeadExistingSource__c == 'Lead',
        'lead was not marked as duplicated of another lead');
        System.assertEquals(lead1.Id, duplicatedLead.existingLeadId__c, 'lead 2 was not marked as duplicate of lead 1');
    }

    @IsTest
    static void testValidatePerStages() {
        String salesRCType = mapRtByName.get('Sales Leads').getRecordTypeId();

        List<Lead> leadObjList = new List<Lead>();
        for (Integer i = 0; i < 5; i++) {
            Lead leadObj = (Lead) new SObjectBuilder(Lead.sObjectType)
                .setField(Lead.RecordTypeId, salesRCType)
                .setField(Lead.LeadSource, 'Online Chat')
                .setField(Lead.FirstName, 'Test')
                .setField(Lead.LastName, 'Lead' + i)
                .setField(Lead.Email, 'test'+ i + '@test.com')
                .build()
                .getRecord();
            leadObjList.add(leadObj);
        }
        Account paidAcc = (Account) new SObjectBuilder(Account.sObjectType)
            .setField(Account.RC_Account_Status__c, 'Paid')
            .build()
            .getRecord();
        Account notPaidAcc = (Account) new SObjectBuilder(Account.sObjectType)
            .setField(Account.RC_Account_Status__c, 'Free')
            .build()
            .getRecord();
        insert new List<Account> {paidAcc, notPaidAcc};

        Contact ct1 = (Contact) new SObjectBuilder(Contact.sObjectType)
            .setField(Contact.FirstName, 'Test')
            .setField(Contact.Email, 'test1@test.com')
            .setField(Contact.AccountId, paidAcc.Id)
            .build()
            .getRecord();
        Contact ct2 = (Contact) new SObjectBuilder(Contact.sObjectType)
            .setField(Contact.FirstName, 'Test2')
            .setField(Contact.Email, 'test2@test.com')
            .setField(Contact.AccountId, notPaidAcc.Id)
            .build()
            .getRecord();
        Contact ct3 = (Contact) new SObjectBuilder(Contact.sObjectType)
            .setField(Contact.FirstName, 'Test3')
            .setField(Contact.Email, 'test3@test.com')
            .setField(Contact.AccountId, notPaidAcc.Id)
            .build()
            .getRecord();
        insert new List<Contact> {ct1, ct2, ct3};

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
            .setField(Opportunity.AccountId, notPaidAcc.Id)
            .setField(Opportunity.StageName, '1. Qualify')
            .create()
            .getRecord();

        Test.startTest();
        List<Lead> newLeadObjs = ValidateLeadDuplicacy.validatePerStages(leadObjList);
        Test.stopTest();

        System.assertEquals(2, newLeadObjs.size(), 'only two leads should be returned as the other 3 were duplicates');
        System.assertEquals(ct1.Id, leadObjList[1].existingLeadId__c, 
        'lead was not marked as duplicate of the expected contact record');
        System.assertEquals(ct2.Id, leadObjList[2].existingLeadId__c,
        'lead was not marked as duplicate of the expected contact record');
        System.assertEquals(ct3.Id, leadObjList[3].existingLeadId__c,
        'lead was not marked as duplicate of the expected contact record');
    }

    @isTest
    static void testCompareInDifferentScenarios() {
        // Test when both strings are null
        Boolean result = ValidateLeadDuplicacy.compare(null, null);
        System.assertEquals(false, result, 'compare method didn not work as expected');

        // Test when one string is null and the other is not
        result = ValidateLeadDuplicacy.compare(null, 'value');
        System.assertEquals(false, result, 'compare method didn not work as expected');

        // Test when the two strings are equal
        result = ValidateLeadDuplicacy.compare('value', 'value');
        System.assertEquals(true, result, 'compare method didn not work as expected');

        // Test when the two strings are different
        result = ValidateLeadDuplicacy.compare('value1', 'value2');
        System.assertEquals(false, result, 'compare method didn not work as expected');

        // Test when one string is empty and the other is not
        result = ValidateLeadDuplicacy.compare('', 'value');
        System.assertEquals(false, result, 'compare method didn not work as expected');
    }

    @isTest
    static void testHasExceptionRulesInDifferentScenarios() {
        // Test when leadObj has fake email
        Lead leadObj = (Lead) new SObjectBuilder(Lead.sObjectType)
            .setField(Lead.Email, 'fake@email.com')
            .setField(Lead.Status, '2. Contacted')
            .build()
            .getRecord(); 
        Boolean result = ValidateLeadDuplicacy.hasExceptionRules(leadObj);
        System.assertEquals(true, result, 'lead should have exception rule');

        // Test when leadObj has first name as "Something" and last name as "New"
        leadObj = (Lead) new SObjectBuilder(Lead.sObjectType)
            .setField(Lead.Email, 'something@email.com')
            .setField(Lead.FirstName, 'Something')
            .setField(Lead.LastName, 'New')
            .build()
            .getRecord();
        result = ValidateLeadDuplicacy.hasExceptionRules(leadObj);
        System.assertEquals(true, result, 'lead should have exception rule');

        // Test when leadObj has first name as "rctu" and last name as "2calls4me"
        leadObj = (Lead) new SObjectBuilder(Lead.sObjectType)
            .setField(Lead.Email, 'something@email.com')
            .setField(Lead.FirstName, 'rctu')
            .setField(Lead.LastName, '2calls4me')
            .build()
            .getRecord(); 
        result = ValidateLeadDuplicacy.hasExceptionRules(leadObj);
        System.assertEquals(true, result, 'lead should have exception rule');

        // Test when leadObj has LeadSource as "About To Be Cancelled"
        leadObj = (Lead) new SObjectBuilder(Lead.sObjectType)
            .setField(Lead.Email, 'something@email.com')
            .setField(Lead.FirstName, 'first')
            .setField(Lead.LastName, 'test')
            .setField(Lead.LeadSource, 'About To Be Cancelled')
            .build()
            .getRecord();  
        result = ValidateLeadDuplicacy.hasExceptionRules(leadObj);
        System.assertEquals(true, result, 'lead should have exception rule');

        // Test when leadObj has LeadSource as "About To Be Cancelled UK"
        leadObj = (Lead) new SObjectBuilder(Lead.sObjectType)
            .setField(Lead.Email, 'something@email.com')
            .setField(Lead.LeadSource, 'About To Be Cancelled UK')
            .setField(Lead.FirstName, 'first')
            .setField(Lead.LastName, 'test')
            .build()
            .getRecord();
        result = ValidateLeadDuplicacy.hasExceptionRules(leadObj);
        System.assertEquals(true, result, 'lead should have exception rule');

        // Test when leadObj has RecordTypeId matching partnerRCTypeId
        String partnerRCTypeId = mapRtByName.get('Partner Leads').getRecordTypeId();
        leadObj = (Lead) new SObjectBuilder(Lead.sObjectType)
            .setField(Lead.RecordTypeId, partnerRCTypeId)
            .setField(Lead.Email, 'something@email.com')
            .setField(Lead.FirstName, 'first')
            .setField(Lead.LastName, 'test')
            .setField(Lead.LeadSource, 'Online Chat')
            .build()
            .getRecord();
        result = ValidateLeadDuplicacy.hasExceptionRules(leadObj);
        System.assertEquals(true, result,'lead should have exception rule');

        // Test when none of the conditions are met
        String salesRCType = mapRtByName.get('Sales Leads').getRecordTypeId();
        leadObj = (Lead) new SObjectBuilder(Lead.sObjectType)
            .setField(Lead.RecordTypeId, salesRCType)
            .setField(Lead.LeadSource, 'Online Chat')
            .setField(Lead.FirstName, 'Test')
            .setField(Lead.LastName, 'Last')
            .setField(Lead.Email, 'test@test.com')
            .build()
            .getRecord();
        result = ValidateLeadDuplicacy.hasExceptionRules(leadObj);
        System.assertEquals(false, result, 'lead should not have exception rule');
    }
    
}