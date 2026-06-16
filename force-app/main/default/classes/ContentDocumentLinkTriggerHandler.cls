//Developer: ratul.saha@ringcentral.com,
//JIRA: PRM-58
//Test class: Test_ContentDocumentLinkTrigger
//Modified By: Jerslin Alexander (to include RISE changes)
public with sharing class ContentDocumentLinkTriggerHandler {

    private static final String riseBrand = 'Rise';
    private static final String shippingRTName = 'Support_T1_Shipping';
    private static final String riseGenericRTName = 'RISE_Partner_Support';
    private static final String customerEBondingRTName = 'Support_Customer_ebonding';
    private static final String testingSubBrand = '2000.Optus';
    private static final String bodyContent = System.Label.CaseComments_For_Adding_Attachments;
    private static Set<String> getCaseCommentRecordTypes() {
        return JiraAccessPermissionService.getConfiguredRecordTypeKeys();
    }

    public static void handleCaseContentDocumentLinks(List<ContentDocumentLink> contentDocumentLinks) {
        Set<Id> caseIds = new Set<Id>();
        for (ContentDocumentLink contentDocLink: contentDocumentLinks) {
            Schema.sObjectType sObjectType = contentDocLink.LinkedEntityId.getSObjectType();
            if (sObjectType == Case.sObjectType) {
                caseIds.add(contentDocLink.LinkedEntityId);
            }
        }
        if (caseIds.size() == 0) {
            return;
        }

        List<Case> casesLst = [
                    SELECT ID, Brand_Account__c, RecordTypeName__c, Original_RecordType__c, Account.Sub_Brand__c, Jira__c
                    FROM Case
                    WHERE Id IN :caseIds AND Brand_Account__c != NULL
                ];

        Map<String, Case_RecordTypes__c> caseRecordTypeMap = Case_RecordTypes__c.getAll();
        Set<String> caseRecordTypeAPINames= new Set<String>();
        Set<String> brandNames = new Set<String>();

        Map<String, Rise_Partner_Case_Comments_Configuration__c> riseRTSettings = Rise_Partner_Case_Comments_Configuration__c.getAll();
        Map<String, Rise_Shipping_Case_Comment_Configuration__c> riseShippingSettings = Rise_Shipping_Case_Comment_Configuration__c.getAll();

        for (String caseRecordTypeName: caseRecordTypeMap.keySet()) {
            Case_RecordTypes__c caseRecordType = caseRecordTypeMap.get(caseRecordTypeName);
            caseRecordTypeAPINames.add(caseRecordType.RecordType_APIName__c);
            brandNames.add(caseRecordType.Brand__c);
        }
        caseRecordTypeAPINames.remove(null);
        brandNames.remove(null);
        
        // Get configured record types from Custom Metadata
        Set<String> caseCommentRecordTypes = getCaseCommentRecordTypes();

        List<CaseComment> caseComments = new List<CaseComment>();
        for (Case caseRec : casesLst) {
            String caseRecordTypeKey = String.isBlank(caseRec.RecordTypeName__c)
                ? ''
                : caseRec.RecordTypeName__c.trim().toLowerCase();

            if (caseCommentRecordTypes.contains(caseRecordTypeKey) && caseRec.Brand_Account__c != null && String.isNotBlank(caseRec.Jira__c)) {
                caseComments.add(new CaseComment(CommentBody = bodyContent, ParentId = caseRec.Id, IsPublished = false));
            } 
            
            else if (caseRec.Brand_Account__c.startsWith(riseBrand)) {
                CaseComment caseComment = createCaseCommentsforRiseBrands(riseRTSettings, riseShippingSettings, caseRec);
                if (caseComment != null) {
                    caseComments.add(caseComment);
                }
            } 
            
            else if (caseRec.Original_RecordType__c.equals(customerEBondingRTName)) {
                List<String> escalationRTs = System.Label.Escalation_Record_Types_for_Customer_EBonded_Cases.split(',');
                if (caseRec.RecordTypeName__c.equals(customerEBondingRTName) || escalationRTs.contains(caseRec.RecordTypeName__c)) {
                    caseComments.add(new CaseComment(CommentBody = bodyContent, ParentId = caseRec.Id, IsPUblished = true ));
                }
            } 
            
            else {
                if (caseRecordTypeAPINames.contains(caseRec.RecordTypeName__c) && brandNames.contains(caseRec.Brand_Account__c)) {
                    caseComments.add(new CaseComment(CommentBody = bodyContent, ParentId = caseRec.Id ));
                }
            }
        }
        if (caseComments.size() > 0) {
            insert caseComments;
        }
    }

    private static CaseComment createCaseCommentsforRiseBrands(Map<String, Rise_Partner_Case_Comments_Configuration__c> riseRTSetting,
                                                               Map<String, Rise_Shipping_Case_Comment_Configuration__c> shippingSetting,
                                                               Case caseRec) {
        CaseComment riseCaseComment;
        String subBrand = caseRec.Account.Sub_Brand__c;
        if(Test.isRunningTest()) {
            subBrand = testingSubBrand;
        }
        if (caseRec.Original_RecordType__c.equals(shippingRTName) && caseRec.RecordTypeName__c.equals(shippingRTName)) {
            Boolean isShippingRTSettingAvailable = shippingSetting.containsKey(subBrand);
            if (isShippingRTSettingAvailable) {
                riseCaseComment = new CaseComment(CommentBody = bodyContent,
                                               ParentId = caseRec.Id,
                                               IsPublished = shippingSetting.get(subBrand).File_Attachment__c );
            }
        } else if (caseRec.Original_RecordType__c.equals(riseGenericRTName)) {
            Boolean isRiseRTSettingAvailable = riseRTSetting.containsKey(subBrand);
            if (isRiseRTSettingAvailable) {
                Rise_Partner_Case_Comments_Configuration__c riseSubBrandSetting = riseRTSetting.get(subBrand);
                List<String> escalationRecordTypes = riseSubBrandSetting.Escalation_Record_Types__c.split(',');
                if (escalationRecordTypes.contains(caseRec.RecordTypeName__c) || 
                     caseRec.RecordTypeName__c.equals(riseGenericRTName)) {
                    riseCaseComment = new CaseComment(CommentBody = bodyContent,
                                                    ParentId = caseRec.Id,
                                                    IsPublished = riseSubBrandSetting.File_Attachment__c );
                }
            }
        }
        return riseCaseComment;
    }
}