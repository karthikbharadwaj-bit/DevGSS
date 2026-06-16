@isTest
public with sharing class Test_AccountViewerController {

    @isTest
    static void verifyControllerIsInitialized() {
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
        .setFields(new Map<SObjectField, Object>{
            Account.Name => 'test Account'
        })
        .create()
        .getRecord();

    ApexPages.StandardController sc = new ApexPages.standardController(acc);

    AccountViewerController controller = new AccountViewerController(sc);

    System.assertEquals(
        JSON.serialize(AccountHelper.ACCOUNT_BILL_ON_BEHALF_PARTNERS),
        controller.billOnBehalfPartnerTypes,
        'BOB partner types should be a copy of AccountHelper List'
    );
    }

    // commented until required profile is created, probably in QTC-285
    /*@isTest
    static void testIsPartnerOperationsAvailable() {

        Boolean partnerOperationsAvailable;

        System.runAs(createTestUser(ProfileHelper.PROFILE_NAME_CHANNEL_OPERATIONS_LIGHTNING)) {
            partnerOperationsAvailable = AccountViewerController.isPartnerOperationsAvailable();
        }

        System.assertEquals(true, partnerOperationsAvailable, 'Partner Operations wasn\'t shown for Channel Sales Manager - Lightning Profile');

        System.runAs(createTestUser(ProfileHelper.PROFILE_NAME_PROFESSIONAL_SERVICES)) {
            partnerOperationsAvailable = AccountViewerController.isPartnerOperationsAvailable();
        }

        System.assertEquals(false, partnerOperationsAvailable, 'Partner Operations was shown for wrong Profile');
    }

    private static User createTestUser(String profileName) {
        String uniqueUserName = 'standarduser' + Datetime.now().getTime() + '@testorg.com';
        Profile p = [SELECT Id FROM Profile WHERE Name =: profileName];
        User u = new User(Alias = 'standt', Email = 'standarduser@testorg.com',
            EmailEncodingKey = 'UTF-8', LastName = 'Testing', LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US', ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            Username = uniqueUserName);
        return u;
    }*/
}