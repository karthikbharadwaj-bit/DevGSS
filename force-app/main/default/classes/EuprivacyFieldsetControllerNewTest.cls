@isTest
private class EuprivacyFieldsetControllerNewTest {

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testInvokeController() {
        Test.StartTest();
        Account ultimateAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, 'Test Account')
            .setField(Account.Emp_Range_Sales_Override__c, 50)
            .create()
            .getRecord();
        
        Account acctObjj = EUPrivacyTest.getAccount();
        acctObjj.Ultimate_Account__c = ultimateAcc.Id;
        acctObjj.BillingCountry = 'Germany';
        insert acctObjj;
        
        Contact contactObj = EUPrivacyTest.getContact();
        contactObj.AccountId =  acctObjj.id;
        insert contactObj;

        Case caseObj = EUPrivacyTest.getCase();
        caseObj.AccountId = acctObjj.id;
        caseObj.contactId = contactObj.Id;       
        insert caseObj;
    
        //Opportunity oppObj = EUPrivacyTest.getOpportunity();
        //oppObj.AccountId = acctObjj.Id;

        //insert oppObj;
        
        String inputString = '[{"value":"test@tests.test2","key":"Billing_Email__c"},{"value":"","key":"AH_Name__c"},{"value":"","key":"AH_Name__r.Name"},{"value":"12345","key":"Phone"}]';
        
        String inputCaseString = '[{"value":"test@tests.test2","key":"SuppliedEmail"},{"value":"Test","key":"SuppliedName"},{"value":"RC-Test","key":"SuppliedCompany"},{"value":'+acctObjj.Id+',"key":"AccountId"}]';
        
        EuprivacyFieldsetControllerNew.MetadataResponse metResAccount = EuprivacyFieldsetControllerNew.getFieldSetMetadata(acctObjj.Id,'');
        EuprivacyFieldsetControllerNew.savePIIUpdates(acctObjj.Id, inputString);
        EuprivacyFieldsetControllerNew.MetadataResponse metResCase = EuprivacyFieldsetControllerNew.getFieldSetMetadata(caseObj.Id,'');
        EuprivacyFieldsetControllerNew.MetadataResponse metResContact = EuprivacyFieldsetControllerNew.getFieldSetMetadata(contactObj.Id,'');        
        //EuprivacyFieldsetControllerNew.MetadataResponse metResOpportunity = EuprivacyFieldsetControllerNew.getFieldSetMetadata(oppObj.Id,'');        
        
        Test.StopTest();
    }
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testInvokeController2() {
        Test.StartTest();
        
        Account acctObjj2 = EUPrivacyTest.getAccount();
        insert acctObjj2;

        Contact contactObj2 = EUPrivacyTest.getContact();
        contactObj2.AccountId =  acctObjj2.id;
        insert contactObj2;

        Case caseObj2 = EUPrivacyTest.getCase();
        caseObj2.AccountId = acctObjj2.id;
        caseObj2.contactId = contactObj2.Id;       
        insert caseObj2;
    
        //Opportunity oppObj2 = EUPrivacyTest.getOpportunity();
        //oppObj2.AccountId = acctObjj2.Id;

       // insert oppObj2;

        String inputString = '[{"value":"test@tests.test2","key":"Billing_Email__c"},{"value":"","key":"AH_Name__c"},{"value":"","key":"AH_Name__r.Name"},{"value":"12345","key":"Phone"}]';
        
        
        EuprivacyFieldsetControllerNew.MetadataResponse metResAccount2 = EuprivacyFieldsetControllerNew.getFieldSetMetadata(acctObjj2.Id,'');
        EuprivacyFieldsetControllerNew.savePIIUpdates(acctObjj2.Id, inputString);
        EuprivacyFieldsetControllerNew.MetadataResponse metResCase2 = EuprivacyFieldsetControllerNew.getFieldSetMetadata(caseObj2.Id,'');
        EuprivacyFieldsetControllerNew.MetadataResponse metResContact2 = EuprivacyFieldsetControllerNew.getFieldSetMetadata(contactObj2.Id,'');        
        
        Test.StopTest();
    }
    
    @isTest
    static void testInvokeController3() {
                
        Account acctObjj2 = EUPrivacyTest.getAccount();
        insert acctObjj2;

        /*Contact contactObj2 = EUPrivacyTest.getContact();
        contactObj2.AccountId =  acctObjj2.id;
        insert contactObj2;

        Case caseObj2 = EUPrivacyTest.getCase();
        caseObj2.AccountId = acctObjj2.id;
        caseObj2.contactId = contactObj2.Id;       
        insert caseObj2;
    
        Opportunity oppObj2 = EUPrivacyTest.getOpportunity();
        oppObj2.AccountId = acctObjj2.Id;

        insert oppObj2;*/
        
        boolean euRestrictedAccount = EURestrictedNotificationController.validateEURestrictedData(acctObjj2.Id);
        String bannerMsg = EURestrictedNotificationController.getEUBannerMsg();
        System.assertEquals(true, bannerMsg.length()>0?true:false, 'Able to get banner msg from Custom metadata successfully');
        //boolean euRestrictedCase = EURestrictedNotificationController.validateEURestrictedData(caseObj2.Id);
        Test.StartTest();
        /*boolean euRestrictedContact = EURestrictedNotificationController.validateEURestrictedData(contactObj2.Id);
        boolean euRestrictedOpportunity = EURestrictedNotificationController.validateEURestrictedData(oppObj2.Id);*/
        
        boolean euRestrictedAccount1 = EURestrictedNotificationController.hideNotes(acctObjj2.Id);
        Test.StopTest();
    }
}