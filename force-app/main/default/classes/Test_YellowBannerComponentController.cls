@isTest
private class Test_YellowBannerComponentController {

    @isTest
    static void testGetDataForYellowBannerComponentForLead() {
        Campaign camp = (Campaign) new SObjectBuilder(Campaign.SObjectType)
                .setField(Campaign.Name, 'YellowBanner')
                .setField(Campaign.BMID__c, 'YellowBanner 1')
                .setField(Campaign.Intended_Product__c, 'UK General')
                .setField(Campaign.Description, 'YellowBanner description')
                .create()
                .getRecord();

        Lead leadObj = (Lead) new SObjectBuilder(Lead.SObjectType)
                .setField(Lead.LastName, 'YellowBanner')
                .setField(Lead.LeadSource, 'SIA')
                .setField(Lead.PartnerDeal_Status__c, 'BT Approved')
                .setField(Lead.Most_Recent_Campaign__c, camp.Id)
                .setField(Lead.SIA_Information__c, 'test SIA Information Text')
                .setField(Lead.Partner_Account_Name__c, 'Test YellowBanner Name')
                .setField(Lead.Domain_Type__c, 'att checked')
                .setField(Lead.Ok_to_Email__c, 'Yes-Single')
                .setField(Lead.Do_Not_Direct_Mail__c, true)
                .setField(Lead.HasOptedOutOfEmail, true)
                .setField(Lead.Do_Not_Call__c, true)
                .setField(Lead.Do_Not_SMS__c, true)
                .create()
                .getRecord();

        YellowBannerComponentController.YellowBannerDTO data = new YellowBannerComponentController.YellowBannerDTO();
        data = YellowBannerComponentController.getDataForYellowBannerComponent(leadObj.Id, 'Lead');

        System.assertEquals(data.isBTApproved, true, 'isBTApproved should be true');
        System.assertEquals(data.isDoNotCall, true, 'isDoNotCall should be true');
        System.assertEquals(data.isHasOptedOutOfEmail, true, 'isHasOptedOutOfEmail should be true');
        System.assertEquals(data.isDoNotDirectMail, true, 'isDoNotDirectMail should be true');
        System.assertEquals(data.isDoNotSMS, true, 'isDoNotSMS should be true');
        System.assertEquals(data.isSia, true, 'isSia should be true');
        System.assertEquals(data.Lead.LastName, 'YellowBanner', 'Wrong Lead assignation');
    }

    @isTest
    static void testGetDataForYellowBannerComponentForContact() {
        Campaign camp = (Campaign) new SObjectBuilder(Campaign.SObjectType)
                .setField(Campaign.Name, 'YellowBanner')
                .setField(Campaign.BMID__c, 'YellowBanner 1')
                .setField(Campaign.Intended_Product__c, 'UK General')
                .setField(Campaign.Description, 'YellowBanner description')
                .create()
                .getRecord();
        
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
                .setField(Account.Name, 'Test Account')
                .setField(Account.RC_Brand__c, 'BT Approved')
                .create()
                .getRecord();

        Contact contactObj = (Contact) new SObjectBuilder(Contact.SObjectType)
                .setField(Contact.LastName, 'YellowBanner')
                .setField(Contact.LeadSource, 'SIA')
                .setField(Contact.Most_Recent_Campaign__c, camp.Id)
                .setField(Contact.SIA_Information__c, 'test SIA Information Text')
                .setField(Contact.Domain_Type__c, 'att checked')
                .setField(Contact.AccountId, acc.Id)
                .setField(Contact.PartnerDeal_Status__c, 'BT Approved')
                .setField(Contact.Ok_to_Email__c, 'Yes-Single')
                .setField(Contact.Do_Not_Direct_Mail__c, true)
                .setField(Contact.HasOptedOutOfEmail, true)
                .setField(Contact.Do_Not_Call__c, true)
                .setField(Contact.Do_Not_SMS__c, true)
                .create()
                .getRecord();

        YellowBannerComponentController.YellowBannerDTO data = new YellowBannerComponentController.YellowBannerDTO();
        data = YellowBannerComponentController.getDataForYellowBannerComponent(contactObj.Id, 'Contact');

        System.assertEquals(data.isDoNotCall, true, 'isDoNotCall should be true');
        System.assertEquals(data.isHasOptedOutOfEmail, true, 'isHasOptedOutOfEmail should be true');
        System.assertEquals(data.isDoNotDirectMail, true, 'isDoNotDirectMail should be true');
        System.assertEquals(data.isDoNotSMS, true, 'isDoNotSMS should be true');
        System.assertEquals(data.isSia, true, 'isSia should be true');
        System.assertEquals(data.Contact.LastName, 'YellowBanner', 'Wrong Lead assignation');
    }
}