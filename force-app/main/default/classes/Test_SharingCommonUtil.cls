@isTest
public class Test_SharingCommonUtil {
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    public static void testSharingCommonUtil(){

        Account partnerAccount = new Account(Name = 'Test Partner Account', Avaya_Partnership_Account__c = true, Type = 'Partner');
        insert partnerAccount;
        
        Account customerAccount = new Account(Name = 'Test Customer Account', Avaya_Partnership_Account__c = true, Type = 'Customer', Partner_Account__c = partnerAccount.Id);
        insert customerAccount;
        
        Contact testContact = new Contact(LastName = 'Test Contact', Avaya_Partnership_Contact__c = true, AccountId = partnerAccount.Id);
        insert testContact;
        
        Profile testProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        
        User testUser = new User(
            LastName = 'Test User',
            Alias = 'tuser',
            Email = 'testuser7543@example.com',
            Username = 'testuser7543@example.com',
            TimeZoneSidKey = 'GMT',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            IsActive = true,
            ProfileId = testProfile.Id
        );
        insert testUser;
        
        User_Account_Mapping__c testUAM = new User_Account_Mapping__c(
            Partner_Account__c = partnerAccount.Id,
            Partner_User__c = testUser.Id,
            Partner_Contact__c = testContact.Id
        );
        insert testUAM;
        
        Map<Id, Id> mapOfUAMToUser = new Map<Id, Id>();
        mapOfUAMToUser.put(testUAM.Id, testUser.Id);
        
        SharingCommonUtil.sharingRecalculateContact(new List<Id>{testContact.Id});
        SharingCommonUtil.getSharingForUAM(mapOfUAMToUser);
        SharingCommonUtil.getAccountPartnerShareFuture(new Set<Id>{partnerAccount.Id});
        SharingCommonUtil.getAccountCustomerShareFuture(new Set<Id>{customerAccount.Id});
        SharingCommonUtil.getAccountDealRegShareFuture(new Set<Id>{partnerAccount.Id}, new List<Id>{testContact.Id});
        SharingCommonUtil.getAccountLeadShareFuture(new Set<Id>{partnerAccount.Id}, new List<Id>{testContact.Id});
        SharingCommonUtil.getAccountDealSupportShareFuture(new Set<Id>{partnerAccount.Id}, new List<Id>{testContact.Id});
    }
}