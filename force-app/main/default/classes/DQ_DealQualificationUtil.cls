public with sharing class DQ_DealQualificationUtil {
    private static final String DQ_ORIGINAL_TYPE = 'Original';
    public static DQ_Deal_Qualification__c getDealQualification(String OppId) {
        List<DQ_Deal_Qualification__c> dealQualificationList =
         [SELECT Id, Free_Shipping_Terms_Options__c,Overall_Discount_Contact_Center__c,Overall_Discount_One_Time__c,Overall_Discount_Recurring__c,IsDQCreatedFromCPQOpp__c,Cost_of_One_Time_items__c, New_Annual_Recurring_Charges__c, Is_ELA__c,True_Up_Terms__c,Start_Date__c,Brand__c,Deal_Type__c,
          ELA_Initial_Terms__c, Roll_Out_Plan__c, Maximum_Potential__c, Minimum_Baseline__c, Additional_Info__c, Sub_Region__c,
          Global_Office_Location__c, Region__c,Segment__c,Name,Minimum_Package_s__c,opportunity__r.Name, Type__c, Special_Terms__c,CC_Initial_Term__c,CC_Special_Terms__c,
         Charge_Term__c,Initial_Term__c,Opportunity__c,Renewal_Term__c,Status__c, Deal_Size__c, Overall_Discount__c,
          Opportunity_Owner_s_Email__c, Justification_Description__c, Quote__r.Payment_Plan__c,Quote__r.Initial_Term_months__c,Quote__r.Approved_Status__c
         FROM DQ_Deal_Qualification__c
         WHERE Opportunity__c = :OppId AND Type__c =:DQ_ORIGINAL_TYPE ];
        if(!dealQualificationList.isEmpty()) {
            return dealQualificationList[0];
        }

        return null;
    }

    public static List<DQ_Deal_Qualification_Discounts__c> getDealQualificationDiscount(String DQId) {
        List<DQ_Deal_Qualification_Discounts__c> DQDiscountList =
            [SELECT Id, Product_Package__c, Product_Package__r.Id,Product_Package__r.Name, Promo_Code__c, Product__c, Quantity__c, Product_Category__c,
             Product_Sub_Categories__c, Discount_Type__c,Discount__c, Product_Family__c ,Deal_Qualification__r.IsDQCreatedFromCPQOpp__c,CPQ_Configured_Product__c
             FROM DQ_Deal_Qualification_Discounts__c
             WHERE Deal_Qualification__c = :DQId];
        if(!DQDiscountList.isEmpty()) {
            return DQDiscountList;
        }

        return null;
    }

    public static List<DQ_Deal_Qualification_Discounts__c> getDealQualificationDiscount(String DQId, String recordTypeName) {
        List<DQ_Deal_Qualification_Discounts__c> DQDiscountList =
            [SELECT Id, Product__r.Name, Product_Package__c, Product_Package__r.Id,Product_Package__r.Name, Promo_Code__c, Product__c,Quantity__c,Product_Category__c,Product_Sub_Categories__c,
             Discount_Type__c,Discount__c, Product_Family__c,Deal_Qualification__r.IsDQCreatedFromCPQOpp__c,CPQ_Configured_Product__c
             FROM DQ_Deal_Qualification_Discounts__c
             WHERE Deal_Qualification__c = :DQId and RecordType.Name = :recordTypeName];
        if(!DQDiscountList.isEmpty()) {
            return DQDiscountList;
        }

        return null;
    }

    public static  Map<Id, Opportunity> getOppurtunityById(Set<Id> setOfOpportunityId) {
        return new Map<Id, Opportunity>([SELECT Id, Brand_Name__c,EES_CC_Removal_Approval__c,EES_Removal_Approval__c, RecordType.Name, CurrencyIsoCode, Segment_Name__c, Owner.Region__c, Owner.Sub_Region__c
         FROM Opportunity WHERE Id IN :setOfOpportunityId]);
    }

    public static  Opportunity getOppurtunityById(String OpportunityId) {
        return [SELECT Id, Brand_Name__c, RecordType.Name, EES_CC_Removal_Approval__c,EES_Removal_Approval__c,CurrencyIsoCode, Segment_Name__c
         FROM Opportunity WHERE Id = :OpportunityId];
    }

    public static List<Partner_Quote__c> getQuotes(Id opportunityId){
        return [SELECT Id, Name,Opportunity__c,CreatedDate,RecordTypeId, RecordType.Name, Name__c, Product_Edition__c, Status__c, Primary__c,
                Product_Edition__r.Name, Product_Edition__r.Product_Categories__c, Number_of_Licenses__c,
                Payment_Term__c FROM Partner_Quote__c WHERE Opportunity__c =: opportunityId and (RecordType.DeveloperName = 'Quote' OR RecordType.DeveloperName = 'Change_Order_Request') ORDER BY CreatedDate DESC];
    }

    public static List<DQ_Deal_Qualification_Approver__c> getDQApproverList(Id dqId){
        return [SELECT Id, createdBy.Name,Comments__c,Owner.Name,Approval_Step_Approver__r.Approval_Type__c,Submitted_Date__c,Submitted_Order__c,Approved_By__r.Name, Approval_Step_Approver__r.Owner.Name, Approval_Reason__c, Name, Approval_Step__r.Owner.Name, Approval_Step_Approver__c,
                Approve_Reject_Date__c, CreatedDate, Approved_By__c, Status__c, Step_Order__c, Approval_Step__r.Name
                FROM DQ_Deal_Qualification_Approver__c
                WHERE Deal_Qualification__c =: dqId ORDER BY Submitted_Order__c DESC,Step_Order__c DESC];
    }
    public static Map<String,String> getPickListValue(String objectName, String fieldName) {
        Map<String,String> pickListValuesMap= new Map<String,String>();
        Schema.SObjectType s = ((SObject)Type.forName(objectName).newInstance()).getSObjectType() ;
        Schema.DescribeSObjectResult r = s.getDescribe() ;
        Map<String,Schema.SObjectField> fields = r.fields.getMap() ;
        Schema.DescribeFieldResult fieldResult = fields.get(fieldName).getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for( Schema.PicklistEntry pickListVal : ple){
            pickListValuesMap.put(pickListVal.getLabel(),pickListVal.getValue());
            //System.debug( +' '+);
        }

        return pickListValuesMap;
    }

    public static DQ_Deal_Qualification_Approver__c getDQApproverById(Id dqApproverId){
        return [SELECT Id, Comments__c,Approval_Step_Approver__r.Approval_Type__c,Submitted_Date__c,Submitted_Order__c,Approved_By__r.Name, Approval_Step_Approver__r.Owner.Name, Approval_Reason__c, Name, Approval_Step__r.Owner.Name, Approval_Step_Approver__c,
                Approve_Reject_Date__c, CreatedDate, Approved_By__c, Status__c, Step_Order__c FROM DQ_Deal_Qualification_Approver__c
                WHERE Id =: dqApproverId];
    }

    public static Map<String,String> getPickListValuesBasedOnRecordType(String objectType, String recordTypeId, String fieldName) {
        //List<cfloptionClass> options = new List<cfloptionClass>();
        Map<String,String> mapOfPicklist = new Map<String,String>();
        //Endpoint
        String endpoint = URL.getOrgDomainUrl().toExternalForm();
        endpoint += '/services/data/v41.0';
        endpoint += '/ui-api/object-info/{0}/picklist-values/{1}/{2}';
        endpoint = String.format(endpoint, new String[]{ objectType, recordTypeId, fieldName });
        EncodingUtil.urlEncode(endpoint,'UTF-8');

        //HTTP Request send
        HttpRequest req = new HttpRequest();
        req.setHeader('Authorization', 'OAuth ' + getSessionIdFromVFPage());
        req.setEndpoint(endpoint);
        req.setMethod('GET');
        Http http = new Http();
        HTTPResponse res = http.send(req);
        Map<String,Object> root = (Map<String,Object>) JSON.deserializeUntyped(res.getBody());
        /*if(!root.containsKey('values')){
            return options;
        }*/

        List<Object> pValues = (List<Object>)root.get('values');
        for(Object pValue : pValues){
            Map<String,Object> pValueMap = (Map<String,Object>)pValue;
            //options.add(new cfloptionClass(,));
            mapOfPicklist.put((String)pValueMap.get('label'),(String)pValueMap.get('value'));
        }

        return mapOfPicklist;
    }

    public static String getSessionIdFromVFPage() {
        if(!Test.isRunningTest()){
            String SESSION_ID_START = 'SESSION_ID_START'; String SESSION_ID_END = 'SESSION_ID_END'; String pageContent = Page.GetSessionIdPage.getContent().toString(); Integer startIndex = pageContent.indexOf(SESSION_ID_START) + SESSION_ID_START.length(); Integer endIndex = pageContent.indexOf(SESSION_ID_END); return pageContent.substring(startIndex, endIndex); }
        else{
            return UserInfo.getSessionId();
        }
    }

}