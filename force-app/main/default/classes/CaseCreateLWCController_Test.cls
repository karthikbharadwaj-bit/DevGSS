@isTest
public class CaseCreateLWCController_Test {
    
    @isTest
    public static void testFormVisibilityBasedOnCaseOrigin(){
        Map<String, List<CaseCreateLWCController.FieldWrapper>> fieldWrapperMap = CaseCreateLWCController.getFormVisibility('Case');
        Assert.isNotNull(fieldWrapperMap);
    }
    
    @isTest
    public static void testFormVisibilityBasedOnProfile(){
        Id profileId = UserInfo.getProfileId();
        String profileName = [Select Id, Name from Profile where Id =: profileId].Name;
        
        Case_Routing_SFDC__c routingConfig = new Case_Routing_SFDC__c();
        routingConfig.Name = profileName;
        routingConfig.Profile_Name__c = profileName;
        insert routingConfig;
        
        Map<String, List<CaseCreateLWCController.FieldWrapper>> fieldWrapperMap = CaseCreateLWCController.getFormVisibility('');
        Assert.isNotNull(fieldWrapperMap);
    }
    
    @isTest
    public static void testFormUnaccessibility(){
        Map<String, List<CaseCreateLWCController.FieldWrapper>> fieldWrapperMap = CaseCreateLWCController.getFormVisibility('');
        Assert.isNull(fieldWrapperMap);
    }
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    public static void testCaseAndFileInsertion(){
        SObjectFactory factory = new SObjectFactory();

        Lead ld = (Lead) factory
            .create(
                Lead.SObjectType
            );
        String recTypeId = CaseHelper.RT_ID_DEAL_AND_ORDER_SUPPORT;
        String caseJson = '{"AccountId":null,"Opportunity_Reference__c":null,"CSM__c":null,"OpportunityMRR__c":null,"AccountOwner__c":null,"Lead__c":"'+ld.Id+'","ParentPartnerAccount__c":null,"ParentId":null,"OwnerId":"005Hr00000HYWcXIAX","Priority":null,"Status":"New","CaseDependencies__c":null,"Case_Category__c":"Ignite Partner","Origin":"Lead","Case_Subcategory__c":"ELA terms","RecordTypeId":"'+recTypeId+'","PreviousCaseCategory__c":null,"PreviousCaseSubCategory__c":null,"Subject":"Test","Description":null,"ContactId":null,"Target_Closure_Date__c":null}';
        String fileJson = '[{"fileName":"Test","fileContent":"VGVzdA=="}]';
        CaseCreateLWCController.insertCaseAndFile(true, caseJson, fileJson);
        Test.startTest();
        List<Case> caseList = [Select Id From Case LIMIT 1];
        Test.stopTest();
    }
    
    @isTest
    public static void testDeserialization(){
        String encodedStr = 'Case_Category__c=Provisioning Assistance,Origin=Process Order,AccountId=001di000006YNefAAG,Opportunity_Reference__c=006di000003RjXBAA0,AccountOwner__c=005Hr00000Ga06ZIAR';
        Map<String, String> desrializedMap = CaseCreateLWCController.deserializeToMap(encodedStr);
        Assert.isNotNull(desrializedMap);
    }

}