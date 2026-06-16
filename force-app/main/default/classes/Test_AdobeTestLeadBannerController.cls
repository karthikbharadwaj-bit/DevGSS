@isTest
class Test_AdobeTestLeadBannerController {
    @testSetup
    static void setupData() {
        new SObjectBuilder(Marketing_Testing__c.SObjectType)
            .setField(Marketing_Testing__c.Name, 'Test')
            .setField(Marketing_Testing__c.Adobe_Target_Id__c, '123')
            .setField(Marketing_Testing__c.Test_Date_From__c, System.today())
            .setField(Marketing_Testing__c.Description__c, 'Test Description')
            .create();
    }

    @isTest
    static void testLeadBannerPositive() {
        test.startTest();
        Lead ld = (Lead) new SObjectBuilder(Lead.SObjectType)
            .setField(Lead.LastName, Test_DemandFunnelHelper.LEADLASTNAME)
            .setField(Lead.Status, LeadTriggerHelper.LEADSTATUSCONTACTED)
            .setField(Lead.Email, Test_DemandFunnelHelper.LEADEMAIL)
            .setField(Lead.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Lead.LeadSource, Test_DemandFunnelHelper.LEADSOURCE)
            .setField(Lead.Adobe_Target_Id__c, '123')
            .create()
            .getRecord();
        Marketing_Testing__c mktObj = AdobeTestLeadBannerController.isAdobeTest(ld.Id, 'Lead');
        test.stopTest();
        System.assertNotEquals(null, mktObj, 'Marketing Testing was not found');
    }

    @isTest
    static void testLeadBannerNegative() {
        test.startTest();
        Lead ld = (Lead) new SObjectBuilder(Lead.SObjectType)
            .setField(Lead.LastName, Test_DemandFunnelHelper.LEADLASTNAME)
            .setField(Lead.Status, LeadTriggerHelper.LEADSTATUSCONTACTED)
            .setField(Lead.Email, Test_DemandFunnelHelper.LEADEMAIL)
            .setField(Lead.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Lead.LeadSource, Test_DemandFunnelHelper.LEADSOURCE)
            .setField(Lead.Adobe_Target_Id__c, '12345')
            .create()
            .getRecord();
        Marketing_Testing__c mktObj = AdobeTestLeadBannerController.isAdobeTest(ld.Id, 'Lead');
        test.stopTest();
        System.assertEquals(null, mktObj, 'Marketing Testing was found');
    }

    @isTest
    static void testContactBannerPositive() {
        test.startTest();
        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setField(Contact.FirstName, 'Test')
            .setField(Contact.LastName, 'Record1')
            .setField(Contact.Email, 'test@test.com')
            .setField(Contact.Phone, '1234567890')
            .setField(Contact.Preferred_Language__c, 'en_US')
            .setField(Contact.Contact_Status__c, '2. Contacted')
            .setField(Contact.Adobe_Target_Id__c, '123')
            .create()
            .getRecord();
        Marketing_Testing__c mktObj = AdobeTestLeadBannerController.isAdobeTest(con.Id, 'Contact');
        test.stopTest();
        System.assertNotEquals(null, mktObj, 'Marketing Testing was not found');
    }

    @isTest
    static void testContactBannerNegative() {
        test.startTest();
        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setField(Contact.FirstName, 'Test')
            .setField(Contact.LastName, 'Record1')
            .setField(Contact.Email, 'test@test.com')
            .setField(Contact.Phone, '1234567890')
            .setField(Contact.Preferred_Language__c, 'en_US')
            .setField(Contact.Contact_Status__c, '2. Contacted')
            .setField(Contact.Adobe_Target_Id__c, '12345')
            .create()
            .getRecord();
        Marketing_Testing__c mktObj = AdobeTestLeadBannerController.isAdobeTest(con.Id, 'Contact');
        test.stopTest();
        System.assertEquals(null, mktObj, 'Marketing Testing was found');
    }

}