@isTest
private class TestCampaignToCalculateMRR {

    @isTest static void testValuesAreUpdated() {
         User marketingUser = (User) new SObjectBuilder(User.SObjectType)
                                 .setFields(SObjectFactoryFieldDefaults.getDefaults(User.SObjectType))
                                 .setField(User.UserPermissionsMarketingUser, true)
                                 .create()
                                 .getRecord();
        Campaign camp = new Campaign();
        System.runAs(marketingUser) {
          camp = (Campaign) new SObjectBuilder(Campaign.SObjectType)
                                           .setField(Campaign.Name, 'someCampaign')
                                           .setField(Campaign.Intended_Product__c, 'someProduct')
                                           .create()
                                           .getRecord();
        }
        Date closeDate  = Date.today().addDays(5);
        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
                                .setField(Opportunity.CampaignId, camp.Id)
                                .setField(Opportunity.Name, 'someOpp')
                                .setField(Opportunity.X12_Month_Booking__c, 150)
                                .setField(Opportunity.CloseDate, closeDate)
                                .create()
                                .getRecord();
        Opportunity otherOpp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
                                .setField(Opportunity.CampaignId, camp.Id)
                                .setField(Opportunity.Name, 'someOtherOpp')
                                .setField(Opportunity.X12_Month_Booking__c, 150)
                                .setField(Opportunity.CloseDate, closeDate)
                                .create()
                                .getRecord();
        
        Test.startTest();
        CampaignBatchToCalculateMRR batchy = new CampaignBatchToCalculateMRR();
        Database.executeBatch(batchy);
        Test.stopTest();
        CampaignSelector campSelector = new CampaignSelector();
        camp = (Campaign) campSelector.selectCampaignsByName(new List<Object>{camp.Name})
                            .selectField(Campaign.Total_Actual_12_Month_Booking_hidden__c)
                            .selectField(Campaign.Total_Estimated_12_Month_Booking_hidden__c)
                            .executeQuery()[0];
        System.assertEquals(camp.Total_Actual_12_Month_Booking_hidden__c, 0,
                            'Actual 12-Month Booking field should have been correctly assigned');
        System.assertEquals(camp.Total_Estimated_12_Month_Booking_hidden__c, 300,
                            'Estimated 12-Month Booking field should have been correctly assigned');
    }
    
    @isTest static void testValuesAreNotUpdated() {
        User marketingUser = (User) new SObjectBuilder(User.SObjectType)
                                 .setFields(SObjectFactoryFieldDefaults.getDefaults(User.SObjectType))
                                 .setField(User.UserPermissionsMarketingUser, true)
                                 .create()
                                 .getRecord();
        Campaign camp = new Campaign();
        System.runAs(marketingUser) {
          camp = (Campaign) new SObjectBuilder(Campaign.SObjectType)
                                        .setField(Campaign.Name, 'someCampaign')
                                        .setField(Campaign.Intended_Product__c, 'someProduct')
                                        .setField(Campaign.Total_Actual_12_Month_Booking_hidden__c, 300)
                                        .setField(Campaign.Total_Estimated_12_Month_Booking_hidden__c, 300)
                                        .create()
                                        .getRecord();
        }
        
        Test.startTest();
        CampaignBatchToCalculateMRR batchy = new CampaignBatchToCalculateMRR();
        Database.executeBatch(batchy);
        Test.stopTest();
        CampaignSelector campSelector = new CampaignSelector();
        camp = (Campaign) campSelector.selectCampaignsByName(new List<Object>{camp.Name})
                            .selectField(Campaign.Total_Actual_12_Month_Booking_hidden__c)
                            .selectField(Campaign.Total_Estimated_12_Month_Booking_hidden__c)
                            .executeQuery()[0];
        System.assertEquals(camp.Total_Actual_12_Month_Booking_hidden__c, 300,
                            'Actual 12-Month Booking field should not have changed');
        System.assertEquals(camp.Total_Estimated_12_Month_Booking_hidden__c, 300,
                            'Estimated 12-Month Booking field should not have changed');
    }
    
}