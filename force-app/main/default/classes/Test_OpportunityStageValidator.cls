@isTest
private class Test_OpportunityStageValidator {
	@testSetup
    static void createTestData() {
        List<Segment_Master__c> segmentList = (List<Segment_Master__c>) new SObjectBuilder(Segment_Master__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Segment_Master__c.Name => ValueProviderBuilder.provideList(new List<String>{UserHelper.SEGMENT_MID_MARKET,UserHelper.SEGMENT_SMALL_BUSINESS}),
                Segment_Master__c.Max__c => ValueProviderBuilder.provideList(new List<Integer> {399,99}),
                Segment_Master__c.Min__c => ValueProviderBuilder.provideList(new List<Integer> {100,20}),
                Segment_Master__c.Country__c => ValueProviderBuilder.provideList(new List<String> {'United States','United States'}),
                Segment_Master__c.Start_Date__c => ValueProviderBuilder.provideList(new List<Date> {Date.today(), Date.today()})
            })
            .quantity(2)
            .create()
            .getRecords();
        
        List<Account> acctList = (List<Account>) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name =>ValueProviderBuilder.provideList(new List<String> {'Test Acc 1','Test Acc 2'}),
                Account.Segment_Name__c =>ValueProviderBuilder.provideList(new List<Id> {segmentList[0].Id,segmentList[1].Id})
            })
            .quantity(2)
            .create()
            .getRecords();
        	
        List<Opportunity> opptyList = (List<Opportunity>) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.Name => ValueProviderBuilder.provideList(new List<String> {'Test Oppty 1','Test Oppty 2'}),
                Opportunity.AccountId => ValueProviderBuilder.provideList(new List<Id> {acctList[0].Id, acctList[1].Id}),
                Opportunity.StageName => ValueProviderBuilder.provideList(new List<String> {OpportunityHelper.STAGE_NAME_QUALIFY,OpportunityHelper.STAGE_NAME_QUALIFY}),
                Opportunity.Estimated_12M_Total_Pipeline__c => ValueProviderBuilder.provideList(new List<Decimal> {10600,0}),
                Opportunity.Type => ValueProviderBuilder.provideList(new List<String> {OpportunityHelper.OPPORTUNITY_TYPE_NEW_BUSINESS,OpportunityHelper.OPPORTUNITY_TYPE_NEW_BUSINESS})
            })
            .quantity(2)
            .create()
            .getRecords();
    }
        
    @isTest
    static void testSMBValidation() {
        Opportunity opp2 = (Opportunity) new OpportunitySelector()
        	.selectOpptyMandatoryFieldsByOpptyName('Test Oppty 2')
            .executeQuery()
            .get(0);
        
        opp2.Estimated_12M_Total_Pipeline__c = 26000;
        update opp2;
        OpportunityHelper.ValidationCategory valCategory = OpportunityHelper.ValidationCategory.FULL_VALIDATION;
        
        opp2.StageName = OpportunityHelper.STAGE_NAME_CLOSED_WON;
        Decimal convertedARR = OpportunityHelper.getARRConvertedToCorporateCCY(opp2.Id);
        List<String> missingfieldLabels1 = OpportunityStageValidator.getMissingFieldLabelsForGivenStage(opp2, convertedARR, valCategory);
        Assert.areEqual(22,missingfieldLabels1.size(),'Missing Fields count for Stage Closed won - SMB is incorrect' );
        
        opp2.StageName = OpportunityHelper.STAGE_NAME_ORDER;
        List<String> missingfieldLabels2 = OpportunityStageValidator.getMissingFieldLabelsForGivenStage(opp2, convertedARR, valCategory);
        Assert.areEqual(19,missingfieldLabels2.size(),'Missing Fields count for Stage order - SMB is incorrect' );
        
        OpportunityHelper.ValidationCategory valCategory1 = OpportunityHelper.ValidationCategory.PARTNER_VALIDATION;
        opp2.StageName = OpportunityHelper.STAGE_NAME_PROOF;
        List<String> missingfieldLabels4 = OpportunityStageValidator.getMissingFieldLabelsForGivenStage(opp2, convertedARR, valCategory1);
        Assert.areEqual(0,missingfieldLabels4.size(),'Missing Fields count for Stage Proof - SMB is incorrect' );
        
        OpportunityHelper.ValidationCategory valCategory12 = OpportunityHelper.ValidationCategory.CHANNEL_HARMONY_VALIDATION;
        opp2.StageName = OpportunityHelper.STAGE_NAME_PROOF;
        List<String> missingfieldLabels5 = OpportunityStageValidator.getMissingFieldLabelsForGivenStage(opp2, convertedARR, valCategory12);
        Assert.areEqual(12,missingfieldLabels5.size(),'Missing Fields count for Stage Proof - SMB is incorrect' );
    }
    
    @isTest
    static void testMidMarketValidation() {
        Opportunity opp1 = (Opportunity) new OpportunitySelector()
        	.selectOpptyMandatoryFieldsByOpptyName('Test Oppty 1')
            .executeQuery()
            .get(0);
        Decimal convertedARR = OpportunityHelper.getARRConvertedToCorporateCCY(opp1.Id);
        opp1.StageName = OpportunityHelper.STAGE_NAME_CLOSED_WON;
        OpportunityHelper.ValidationCategory valCategory = OpportunityHelper.ValidationCategory.GSP_VALIDATION;
        List<String> missingfields1 = OpportunityStageValidator.getMissingFieldsforGivenStage(opp1, convertedARR, valCategory);
        Assert.areEqual(3,missingfields1.size(),'Missing Fields count for Stage Closed Won - MidMarket is incorrect' );
        
        opp1.StageName = OpportunityHelper.STAGE_NAME_DOWNGRADED;
        List<String> missingfields3 = OpportunityStageValidator.getMissingFieldsforGivenStage(opp1, convertedARR, valCategory);
        Assert.areEqual(3,missingfields3.size(),'Missing Fields count for Stage Downgrade - MidMarket is incorrect' );

        OpportunityHelper.ValidationCategory valCategory2 = OpportunityHelper.ValidationCategory.FULL_VALIDATION;
        opp1.StageName = OpportunityHelper.STAGE_NAME_SOLUTION;
        List<String> missingfields4 = OpportunityStageValidator.getMissingFieldsforGivenStage(opp1, convertedARR, valCategory2);
        Assert.areEqual(16,missingfields4.size(),'Missing Fields count for Stage Solution - MidMarket is incorrect' );
        
        opp1.StageName = OpportunityHelper.STAGE_NAME_PROOF;
        List<String> missingfields5 = OpportunityStageValidator.getMissingFieldsforGivenStage(opp1, convertedARR, valCategory2);
        Assert.areEqual(20,missingfields5.size(),'Missing Fields count for Stage Proof - MidMarket is incorrect' );
        
        OpportunityHelper.ValidationCategory valCategory1 = OpportunityHelper.ValidationCategory.PARTNER_VALIDATION;
        opp1.ProServ_Comments_Notes__c = 'test comment';
        opp1.Implementation_Comments_Notes__c = 'test comment';
        opp1.StageName = OpportunityHelper.STAGE_NAME_AGREEMENT;
        List<String> missingfields2 = OpportunityStageValidator.getMissingFieldsforGivenStage(opp1, convertedARR, valCategory1);
        Assert.areEqual(0,missingfields2.size(),'Missing Fields count for Stage Agreement - MidMarket is incorrect' );
    }
}