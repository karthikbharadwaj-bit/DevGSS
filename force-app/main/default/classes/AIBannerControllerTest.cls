@IsTest
private class AIBannerControllerTest {
    
    @TestSetup
    static void setupTestData() {
        AI_Banner__c bannerSetting = new AI_Banner__c(
            SetupOwnerId = UserInfo.getOrganizationId(),
            Switch__c = true,
            Heading__c = 'AI Features Update',
            Content__c = '<p>Check out our new AI-powered features that will help you work more efficiently!</p>',
            Gif__c = 'ai_image', 
            Background_Color__c = 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
            From_Date__c = DateTime.now().addDays(-1),
            To_Date__c = DateTime.now().addDays(1)
        );
        insert bannerSetting;
    }
    
    @IsTest
    static void testGetBannerSettings_Success() {
        Test.startTest();
        AIBannerController.AIBannerWrapper result = AIBannerController.getBannerSettings();
        Test.stopTest();
        
        Assert.areEqual(true, result.isVisible, 'Banner should be visible when enabled and within date range');
        Assert.areEqual('AI Features Update', result.heading, 'Heading should match custom setting');
        Assert.areEqual('<p>Check out our new AI-powered features that will help you work more efficiently!</p>', 
                          result.content, 'Content should match custom setting');
        Assert.areEqual('ai_image', result.gifResource, 'Gif resource should match custom setting');
        Assert.areEqual('linear-gradient(135deg, #667eea 0%, #764ba2 100%)', result.backgroundColor, 'Background color should match custom setting');
    }
    
    @IsTest
    static void testGetBannerSettings_SwitchDisabled() {
        AI_Banner__c bannerSetting = AI_Banner__c.getOrgDefaults();
        bannerSetting.Switch__c = false;
        update bannerSetting;
        
        Test.startTest();
        AIBannerController.AIBannerWrapper result = AIBannerController.getBannerSettings();
        Test.stopTest();
        
        Assert.areEqual(false, result.isVisible, 'Banner should not be visible when switch is disabled');
        Assert.areEqual('AI Features Update', result.heading, 'Heading should still be populated');
        Assert.areEqual('<p>Check out our new AI-powered features that will help you work more efficiently!</p>', 
                          result.content, 'Content should still be populated');
    }
    
    @IsTest
    static void testGetBannerSettings_OutsideDateRange_Before() {
        AI_Banner__c bannerSetting = AI_Banner__c.getOrgDefaults();
        bannerSetting.From_Date__c = DateTime.now().addDays(1);
        bannerSetting.To_Date__c = DateTime.now().addDays(2);
        update bannerSetting;
        
        Test.startTest();
        AIBannerController.AIBannerWrapper result = AIBannerController.getBannerSettings();
        Test.stopTest();
        
        Assert.areEqual(false, result.isVisible, 'Banner should not be visible when current date is before range');
    }
    
    @IsTest
    static void testGetBannerSettings_OutsideDateRange_After() {
        AI_Banner__c bannerSetting = AI_Banner__c.getOrgDefaults();
        bannerSetting.From_Date__c = DateTime.now().addDays(-2);
        bannerSetting.To_Date__c = DateTime.now().addDays(-1);
        update bannerSetting;
        
        Test.startTest();
        AIBannerController.AIBannerWrapper result = AIBannerController.getBannerSettings();
        Test.stopTest();
        
        Assert.areEqual(false, result.isVisible, 'Banner should not be visible when current date is after range');
    }
    
    @IsTest
    static void testGetBannerSettings_NullDates() {
        AI_Banner__c bannerSetting = AI_Banner__c.getOrgDefaults();
        bannerSetting.From_Date__c = null;
        bannerSetting.To_Date__c = null;
        update bannerSetting;
        
        Test.startTest();
        AIBannerController.AIBannerWrapper result = AIBannerController.getBannerSettings();
        Test.stopTest();
        
        Assert.areEqual(true, result.isVisible, 'Banner should be visible when both dates are null');
    }

    
    @IsTest
    static void testGetBannerSettings_NoCustomSetting() {
        delete [SELECT Id FROM AI_Banner__c];
        
        Test.startTest();
        AIBannerController.AIBannerWrapper result = AIBannerController.getBannerSettings();
        Test.stopTest();
        
        Assert.areEqual(false, result.isVisible, 'Banner should not be visible without custom setting');
        Assert.areEqual(null, result.heading, 'Heading should be null without custom setting');
        Assert.areEqual(null, result.content, 'Content should be null without custom setting');
        Assert.areEqual(null, result.gifResource, 'Gif resource should be null without custom setting');
        Assert.areEqual(null, result.backgroundColor, 'Background color should be null without custom setting');
    }

}