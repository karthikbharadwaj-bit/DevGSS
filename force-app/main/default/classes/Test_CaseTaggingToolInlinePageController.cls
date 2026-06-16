@isTest
private class Test_CaseTaggingToolInlinePageController {
    
    private static Case testCase;

    private static void CreateTestData(){

        // create test case
        testCase = new Case ();
        insert testCase;
    }
    
    private static Case makeCase() {
        Case c = new Case(Subject = 'UT', Final_Fix__c = 'Fixed by unit test');
        insert c;
        return c;
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest static void testSelections() {
        CreateTestData();

        Test.startTest();
        
        ApexPages.StandardController sc = new ApexPages.StandardController(testCase);
        CaseTaggingToolInlinePageController ctr = new CaseTaggingToolInlinePageController(sc);

        PageReference pageRef = Page.CaseTaggingToolInlinePage;
        pageRef.getParameters().put('id', String.valueOf(testCase.Id));
        Test.setCurrentPage(pageRef);

        Test.stopTest();
    }

    @isTest static void testCreations() {
        Map <String, String> saveParams = new Map <String, String>();

        CreateTestData();

        Test.startTest();

        // test case update
        saveParams.put('Id', testCase.Id);
        saveParams.put('CSAT_Prediction__c', '1');
        saveParams.put('CSAT_Prediction_after_Manager_Callback__c', '1');

        saveParams.put('OpenCustomerSupportLevel1__c', 'I have a question or need help with Call Forwarding');
        saveParams.put('OpenCustomerSupportLevel2__c', 'My calls are Not Forwarding');
        saveParams.put('OpenCustomerSupportLevel3__c', 'To RingCentral number');

        saveParams.put('CloseCustomerSupportLevel3__c', 'Timing before sending to VM');

        saveParams.put('OpenInternalWorkflowLevel1__c', 'Transfer');
        saveParams.put('OpenInternalWorkflowLevel2__c', 'Transferred to BT Partner');
        saveParams.put('OpenInternalWorkflowLevel3__c', 'Contract - Cancellations');

        saveParams.put('CloseInternalWorkflowLevel1__c', 'Transfer');
        saveParams.put('CloseInternalWorkflowLevel2__c', 'Transferred to BT Partner');
        saveParams.put('CloseInternalWorkflowLevel3__c', 'Contract - Cancellations');

        saveParams.put('ProductType__c', 'Polycom Deskphone');
        saveParams.put('ProductVersionModelPlatform__c', 'Polycom 5000 Conference Phone');

        Case testCaseResult = CaseTaggingToolInlinePageController.saveCaseAction(saveParams);

        System.assertEquals(testCaseResult.CSAT_Prediction__c, saveParams.get('CSAT_Prediction__c'));
        System.assertEquals(testCaseResult.CSAT_Prediction_after_Manager_Callback__c, saveParams.get('CSAT_Prediction_after_Manager_Callback__c'));

        System.assertEquals(testCaseResult.OpenCustomerSupportLevel1__c, saveParams.get('OpenCustomerSupportLevel1__c'));
        System.assertEquals(testCaseResult.OpenCustomerSupportLevel2__c, saveParams.get('OpenCustomerSupportLevel2__c'));
        System.assertEquals(testCaseResult.OpenCustomerSupportLevel3__c, saveParams.get('OpenCustomerSupportLevel3__c'));

        System.assertEquals(testCaseResult.CloseCustomerSupportLevel3__c, saveParams.get('CloseCustomerSupportLevel3__c'));

        System.assertEquals(testCaseResult.OpenInternalWorkflowLevel1__c, saveParams.get('OpenInternalWorkflowLevel1__c'));
        System.assertEquals(testCaseResult.OpenInternalWorkflowLevel2__c, saveParams.get('OpenInternalWorkflowLevel2__c'));
        System.assertEquals(testCaseResult.OpenInternalWorkflowLevel3__c, saveParams.get('OpenInternalWorkflowLevel3__c'));

        System.assertEquals(testCaseResult.CloseInternalWorkflowLevel1__c, saveParams.get('CloseInternalWorkflowLevel1__c'));
        System.assertEquals(testCaseResult.CloseInternalWorkflowLevel2__c, saveParams.get('CloseInternalWorkflowLevel2__c'));
        System.assertEquals(testCaseResult.CloseInternalWorkflowLevel3__c, saveParams.get('CloseInternalWorkflowLevel3__c'));

        System.assertEquals(testCaseResult.ProductType__c, saveParams.get('ProductType__c'));
        System.assertEquals(testCaseResult.ProductVersionModelPlatform__c, saveParams.get('ProductVersionModelPlatform__c')); 

        Test.stopTest();
    }
    
    @IsTest static void getFinalFixMode_default_and_readonly() {
        String mode = CaseTaggingToolInlinePageController.getFinalFixMode();
        System.assert(mode == 'HIDE' || mode == 'EDIT' || mode == 'READONLY');
        
        Id userId = UserInfo.getUserId();
        User u = [Select Id, Name from User where Id =:userId];
        System.runAs(u) {
            String m2 = CaseTaggingToolInlinePageController.getFinalFixMode();
            System.assert(m2 == 'HIDE' || m2 == 'READONLY' || m2 == 'EDIT');
        }
    }
    
    @IsTest static void verifyNewPicklistValues() {
        Case c = makeCase();
        
        ApexPages.StandardController sc =
            new ApexPages.StandardController(c);
        CaseTaggingToolInlinePageController ctrl =
            new CaseTaggingToolInlinePageController(sc);
        
        System.assertNotEquals(null, ctrl.caseObjJson,'Constructor should serialize the queried Case.');
        
        System.assertNotEquals(null, CaseTaggingToolInlinePageController.getCase(c.Id));
        
        System.assertEquals(null, CaseTaggingToolInlinePageController.getCase(null));
        
        String json = CaseTaggingToolInlinePageController.getPicklistValues();
        System.assert(String.isNotBlank(json));
        Map<String, Object> m =
            (Map<String, Object>) System.JSON.deserializeUntyped(json);
        System.assert(m.containsKey('OpenCustomerSupportLevel1__c'));
        System.assert(m.containsKey('OpenInternalWorkflowLevel1__c'));
        System.assert(m.containsKey('ProductType_CS__c'));
    }
    
    @IsTest static void saveCase_success_minimal() {
        Case c = makeCase();
        
        
        Id profileId = UserInfo.getProfileId();

        
        Profile profile = (Profile) new ProfileSelector()
            .selectProfileById(new List<Object>{profileId})
            .executeQuery()
            .get(0);
        String profileName = profile.Name;
        
        Map<String, String> p = new Map<String, String>{
            'Id' => c.Id,
                'Final_Fix__c' => 'Fixed by unit test'
                };
                    Case saved = CaseTaggingToolInlinePageController.saveCaseAction(p);
        
        System.assertEquals('Fixed by unit test', saved.Final_Fix__c);
    }
    
    @IsTest static void saveCase_dmlException_path() {
        Case c = makeCase();
        delete c; 
        
        Boolean thrown = false;
        try {
            Map<String, String> p = new Map<String, String>{
                'Id' => c.Id,
                    'CSAT_Prediction__c' => 'X',
                    'CSAT_Prediction_after_Manager_Callback__c' => 'Y',
                    'OpenCustomerSupportLevel1__c' => 'L1',
                    'OpenCustomerSupportLevel2__c'  => 'L2',
                    'OpenCustomerSupportLevel3__c'  => 'L3',
                    'ProductType__c'                 => 'Anything',
                    'ProductType_CS__c'              => 'Anything',
                    'ProductVersionModelPlatform__c' => 'Anything',
                    'CloseCustomerSupportLevel3__c'  => 'cL3',
                    'OpenInternalWorkflowLevel1__c'  => 'iL1',
                    'OpenInternalWorkflowLevel2__c'  => 'iL2',
                    'OpenInternalWorkflowLevel3__c'  => 'iL3',
                    'CloseInternalWorkflowLevel1__c' => 'ciL1',
                    'CloseInternalWorkflowLevel2__c' => 'ciL2',
                    'CloseInternalWorkflowLevel3__c' => 'ciL3',
                    'Final_Fix__c' => 'Some notes'
                    };
                        CaseTaggingToolInlinePageController.saveCaseAction(p);
        } catch (Exception e) {
            thrown = true;
        }
        System.assertEquals(true, thrown, 'Expect an exception so the catch block (and loop) are covered.');
    }
    
    
}