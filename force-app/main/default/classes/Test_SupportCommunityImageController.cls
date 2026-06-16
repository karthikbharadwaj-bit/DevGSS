@isTest
private class Test_SupportCommunityImageController {
    @testSetup
    private static void setupData() {
        SupportCommunityImagelnk__c lnk = new SupportCommunityImagelnk__c(
            Name = 'Test',
            Image__c = 'OPOY',
            Link__c = 'google.it.comrade',
            Place__c = 'carousel',
            Active__c = true,
            OrderId__c = 7,
            Country__c = 'en_US;en_GB'
        );
        insert lnk;
        SupportCommunityImagelnk__c lnk2 = new SupportCommunityImagelnk__c(
            Name = 'Test2',
            Image__c = 'OPOY',
            Link__c = 'google.it.comrade',
            Place__c = 'carousel',
            Active__c = true,
            OrderId__c = 3
        );
        insert lnk2;
    }
    @isTest
    private static void getCorrectImageByOrder(){
        System.assertEquals(1, SupportCommunityImageController.getPictures('carousel', 7, null).size());
        System.assertEquals(0, SupportCommunityImageController.getPictures('carousel', 5, null).size());
    }
    @isTest
    private static void getCorrectImageWithoutOrder(){
        System.assertEquals(2, SupportCommunityImageController.getPictures('carousel', null,  null).size());
    }
    @isTest
    private static void getCorrectImageWithCountry(){
        System.assertEquals(2, SupportCommunityImageController.getPictures('carousel', null,  'en_US').size());
        System.assertEquals(2, SupportCommunityImageController.getPictures('carousel', null,  'en_GB').size());
        System.assertEquals(2, SupportCommunityImageController.getPictures('carousel', null,  null).size());
        System.assertEquals(1, SupportCommunityImageController.getPictures('carousel', null,  'en_CA').size());
    }
    @isTest
    private static void getZeroImagesToCountry(){
        delete [SELECT Id FROM SupportCommunityImagelnk__c];
        System.assertEquals(0, SupportCommunityImageController.getPictures('carousel', null,  'en_US').size());
        setupData();
    }
}