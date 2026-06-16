public with sharing class CaseTaggingToolInlinePageController {
    
    public static final String MODE_HIDE      = 'HIDE';
    public static final String MODE_EDIT      = 'EDIT';
    public static final String MODE_READONLY  = 'READONLY';
    private static final Set<String> VALID_FINAL_FIX_MODES = new Set<String>{ MODE_HIDE, MODE_EDIT, MODE_READONLY };
        
    private static Map<String, String> finalFixModeByProfileNameCache = new Map<String, String>();

    public String caseObjJson { get; set; }
    public static final List<Schema.SObjectField> availableFields = new List<Schema.SObjectField>{
            Case.CSAT_Prediction__c,
            Case.CSAT_Prediction_after_Manager_Callback__c,
            Case.OpenCustomerSupportLevel1__c,
            Case.OpenCustomerSupportLevel2__c,
            Case.OpenCustomerSupportLevel3__c,
            Case.ProductType__c,
            Case.ProductType_CS__c,
            Case.ProductVersionModelPlatform__c,
            Case.CloseCustomerSupportLevel1__c,
            Case.CloseCustomerSupportLevel2__c,
            Case.CloseCustomerSupportLevel3__c,
            Case.Final_Fix__c,
            Case.OpenInternalWorkflowLevel1__c,
            Case.OpenInternalWorkflowLevel2__c,
            Case.OpenInternalWorkflowLevel3__c,
            Case.CloseInternalWorkflowLevel1__c,
            Case.CloseInternalWorkflowLevel2__c,
            Case.CloseInternalWorkflowLevel3__c
    };

    /*
     *  Controller for CaseTaggingToolInlinePage
     */
    public CaseTaggingToolInlinePageController(ApexPages.StandardController stdController) {
        Case currentCase = (Case) stdController.getRecord();
        Id caseId = currentCase.Id;

        // get case obj
        Case caseObj = getCase(caseId);
        caseObjJson = JSON.serialize(caseObj);
    }

    @AuraEnabled
    public static String getPicklistValues(){

        // get picklist values for CSAT_Prediction__c
        String cp = JSON.serialize(SFDescribeHelper.getOptions('Case', 'CSAT_Prediction__c'));

        // get picklist values for CSAT_Prediction_after_Manager_Callback__c
        String cpamc = JSON.serialize(SFDescribeHelper.getOptions('Case', 'CSAT_Prediction_after_Manager_Callback__c'));

        // Open Customer Support Level 1, 2, 3
        String ocsl12 = JSON.serialize(SFDescribeHelper.getDependentOptions('Case', 'OpenCustomerSupportLevel1__c', 'OpenCustomerSupportLevel2__c'));
        String ocsl23 = JSON.serialize(SFDescribeHelper.getDependentOptions('Case', 'OpenCustomerSupportLevel2__c', 'OpenCustomerSupportLevel3__c'));
        
        // NEW: Product Type -> Open CS L1
        String pt_to_openL1 = JSON.serialize(
            SFDescribeHelper.getDependentOptions('Case', 'ProductType_CS__c', 'OpenCustomerSupportLevel1__c')
        );
        
        // NEW: Open CS L3 -> Close CS L3
        String openL3_to_closeL3 = JSON.serialize(
            SFDescribeHelper.getDependentOptions('Case', 'OpenCustomerSupportLevel3__c', 'CloseCustomerSupportLevel3__c')
        );

        // Close Customer Support Level 1, 2, 3
        String ccsl3 = JSON.serialize(SFDescribeHelper.getOptions('Case', 'CloseCustomerSupportLevel3__c'));

        // Product Type / Product Version Model Platform
        String pt = JSON.serialize(SFDescribeHelper.getDependentOptions('Case', 'ProductType__c', 'ProductVersionModelPlatform__c'));
                
        // CS product options (standalone) for the CS dropdown
        String pt_cs = JSON.serialize(SFDescribeHelper.getOptions('Case','ProductType_CS__c'));

        // Open Internal Workflow Level 1, 2, 3
        String oiwl12 = JSON.serialize(SFDescribeHelper.getDependentOptions('Case', 'OpenInternalWorkflowLevel1__c', 'OpenInternalWorkflowLevel2__c'));
        String oiwl23 = JSON.serialize(SFDescribeHelper.getDependentOptions('Case', 'OpenInternalWorkflowLevel2__c', 'OpenInternalWorkflowLevel3__c'));

        // Close Internal Workflow Level 1, 2, 3
        String ciwl12 = JSON.serialize(SFDescribeHelper.getDependentOptions('Case', 'CloseInternalWorkflowLevel1__c', 'CloseInternalWorkflowLevel2__c'));
        String ciwl23 = JSON.serialize(SFDescribeHelper.getDependentOptions('Case', 'CloseInternalWorkflowLevel2__c', 'CloseInternalWorkflowLevel3__c'));

        return JSON.serialize(new Map<String, String>{
                'CSAT_Prediction__c' => cp,
                'CSAT_Prediction_after_Manager_Callback__c' => cpamc,

                'OpenCustomerSupportLevel1__c' => ocsl12,
                'OpenCustomerSupportLevel2__c' => ocsl23,

                'CloseCustomerSupportLevel3__c' => ccsl3,

                'ProductType__c' => pt,
                'ProductType_CS__c' => pt_cs,                    
             
                'PT_to_OpenCSL1__c' => pt_to_openL1,
                'OpenCSL3_to_CloseCSL3__c' => openL3_to_closeL3,

                'OpenInternalWorkflowLevel1__c' => oiwl12,
                'OpenInternalWorkflowLevel2__c' => oiwl23,

                'CloseInternalWorkflowLevel1__c' => ciwl12,
                'CloseInternalWorkflowLevel2__c' => ciwl23
        });
    }

    /*
     *  Get Case object with fields required for app
     */
    @AuraEnabled
    public static Case getCase(Id caseId) {
        Case caseObj = null;
        if (caseId != null) {
            try {
                caseObj = [
                        SELECT Id, Status, CSAT_Prediction__c, CSAT_Prediction_after_Manager_Callback__c,
                                OpenCustomerSupportLevel1__c, OpenCustomerSupportLevel2__c, OpenCustomerSupportLevel3__c,
                                ProductType__c, ProductVersionModelPlatform__c, ProductType_CS__c,
                                CloseCustomerSupportLevel1__c, CloseCustomerSupportLevel2__c, CloseCustomerSupportLevel3__c, Final_Fix__c,
                                OpenInternalWorkflowLevel1__c, OpenInternalWorkflowLevel2__c, OpenInternalWorkflowLevel3__c,
                                CloseInternalWorkflowLevel1__c, CloseInternalWorkflowLevel2__c, CloseInternalWorkflowLevel3__c
                        FROM Case
                        WHERE Id = :caseId
                        LIMIT 1
                ];
            } catch (DMLException e) {
                AquivaHelper.throwAuraException(e);
            }
        }
        return caseObj;
    }

    /*
     *  Save Case
     */
    @AuraEnabled
    public static Case saveCaseAction(Map < String, String > params) {

        System.debug('params=' + params);

        Id caseId = Id.valueOf(params.get('Id'));

        Case caseObj;

        // find existing case object with Id
        if (caseId == null) {
            AquivaHelper.throwAuraException('Case id is required');
        }
        caseObj = new Case(Id = caseId);

        // assign fields
        
        if(params.containsKey('CSAT_Prediction__c')){
            String csatPrediction = params.get('CSAT_Prediction__c');
            caseObj.CSAT_Prediction__c = csatPrediction;

        }
        if(params.containsKey('CSAT_Prediction_after_Manager_Callback__c')){
            String csatPredictionAMC = params.get('CSAT_Prediction_after_Manager_Callback__c');
            caseObj.CSAT_Prediction_after_Manager_Callback__c = csatPredictionAMC;

        }
        if(params.containsKey('OpenCustomerSupportLevel1__c')){
            String openCustomerSupportLevel1 = params.get('OpenCustomerSupportLevel1__c');
            caseObj.OpenCustomerSupportLevel1__c = openCustomerSupportLevel1;

            String openCustomerSupportLevel2 = params.get('OpenCustomerSupportLevel2__c');
            caseObj.OpenCustomerSupportLevel2__c = openCustomerSupportLevel2;

            String openCustomerSupportLevel3 = params.get('OpenCustomerSupportLevel3__c');
            caseObj.OpenCustomerSupportLevel3__c = openCustomerSupportLevel3;
        }
        
        // ProductType is standalone for Customer Support, ProductVersionModelPlatform still used in Internal Workflow
        if(params.containsKey('ProductType__c')){
            String productType = params.get('ProductType__c');
            caseObj.ProductType__c = productType;
        }
        
        // ProductType_CS__c is CS-only (standalone)
        if (params.containsKey('ProductType_CS__c')) {
            caseObj.ProductType_CS__c = params.get('ProductType_CS__c');
        }

        // ProductVersionModelPlatform still needed (conditionally set at Aura component for Internal Workflow only)
        if(params.containsKey('ProductVersionModelPlatform__c')){
            caseObj.ProductVersionModelPlatform__c = params.get('ProductVersionModelPlatform__c');
        }
        
        if (params.containsKey('CloseCustomerSupportLevel1__c')) {
            caseObj.CloseCustomerSupportLevel1__c = params.get('CloseCustomerSupportLevel1__c');
        }
        if (params.containsKey('CloseCustomerSupportLevel2__c')) {
            caseObj.CloseCustomerSupportLevel2__c = params.get('CloseCustomerSupportLevel2__c');
        }
        
        if(params.containsKey('CloseCustomerSupportLevel3__c')){
            caseObj.CloseCustomerSupportLevel3__c = params.get('CloseCustomerSupportLevel3__c');
        }
        
        
        // Set the new Final Fix field explicitly        
        if (params.containsKey('Final_Fix__c') &&
            resolveFinalFixModeForProfile(UserInfo.getProfileId()) == MODE_EDIT) {
                caseObj.Final_Fix__c = params.get('Final_Fix__c');
            }

        if(params.containsKey('OpenInternalWorkflowLevel1__c')){
            String openInternalWorkflowLevel1 = params.get('OpenInternalWorkflowLevel1__c');
            caseObj.OpenInternalWorkflowLevel1__c = openInternalWorkflowLevel1;

            String openInternalWorkflowLevel2 = params.get('OpenInternalWorkflowLevel2__c');
            caseObj.OpenInternalWorkflowLevel2__c = openInternalWorkflowLevel2;

            String openInternalWorkflowLevel3 = params.get('OpenInternalWorkflowLevel3__c');
            caseObj.OpenInternalWorkflowLevel3__c = openInternalWorkflowLevel3;
        }
        if(params.containsKey('CloseInternalWorkflowLevel1__c')){
            String closeInternalWorkflowLevel1 = params.get('CloseInternalWorkflowLevel1__c');
            caseObj.CloseInternalWorkflowLevel1__c = closeInternalWorkflowLevel1;

            String closeInternalWorkflowLevel2 = params.get('CloseInternalWorkflowLevel2__c');
            caseObj.CloseInternalWorkflowLevel2__c = closeInternalWorkflowLevel2;

            String closeInternalWorkflowLevel3 = params.get('CloseInternalWorkflowLevel3__c');
            caseObj.CloseInternalWorkflowLevel3__c = closeInternalWorkflowLevel3;
        }


        // upsert case
        try{
            update caseObj;
        } catch (DMLException e){
            Integer numErrors = e.getNumDml();
            for(Integer i=0;i<numErrors;i++) {
                System.debug('getDmlFieldNames=' + e.getDmlFieldNames(i));
                String errMessage = e.getDmlMessage(i);
                List<String> errFieldName = e.getDmlFieldNames(i);
                if(errFieldName != null) {
                    errMessage = errMessage + ' Field Name: '+ errFieldName;
                }
                System.debug('getDmlMessage=' + errMessage);
                AquivaHelper.throwAuraException(errMessage);
            }
        }
        
        caseObj = getCase(caseObj.Id);

        return caseObj;

    }
    
    @AuraEnabled
    public static String getFinalFixMode() {
        return resolveFinalFixModeForProfile(UserInfo.getProfileId());
    }
    
    private static String resolveFinalFixModeForProfile(Id profileId) {
        // Profile name
        Profile profile = (Profile) new ProfileSelector()
            .selectProfileById(new List<Object>{profileId})
            .executeQuery()
            .get(0);
        String profileName = profile.Name;
        
        if (finalFixModeByProfileNameCache.containsKey(profileName)) {
            return finalFixModeByProfileNameCache.get(profileName);
        }

        String resolvedMode;
        Map<String, CaseFinalFixModes__c> finalFixAccess = CaseFinalFixModes__c.getAll(); 
        
        if (finalFixAccess != null && !finalFixAccess.isEmpty()) {
            CaseFinalFixModes__c defaultRec = null;
            
            for (CaseFinalFixModes__c profileLevelAccess : finalFixAccess.values()) {
                if (profileLevelAccess.ProfileName__c == profileName) {
                    resolvedMode = profileLevelAccess.Mode__c;
                    break;
                }
                if (defaultRec == null && profileLevelAccess.IsDefault__c) {
                    defaultRec = profileLevelAccess; 
                }
            }
            
            if (resolvedMode == null && defaultRec != null) {
                resolvedMode = defaultRec.Mode__c; // fallback to default
            }
        }
        
        if (!VALID_FINAL_FIX_MODES.contains(resolvedMode)) {
            resolvedMode = MODE_READONLY;
        }
        
        finalFixModeByProfileNameCache.put(profileName, resolvedMode);
        return resolvedMode;
    }

}