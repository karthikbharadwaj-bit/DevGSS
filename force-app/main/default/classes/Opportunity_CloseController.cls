public class Opportunity_CloseController {
    public class CloseOpportunityParams {
        public Id opportunityId;
        public Id mpUbTechQuoteId;
        public String rcNumber;
        public String ccNumber;
        public String approvalId;
    }
    @AuraEnabled
    public static String closeOppty(String closeOpportunityParams){
        return ApexWebServices.validateOnCloseOpportunity(closeOpportunityParams);
    }
    @AuraEnabled
    public static String opportunityvalidateOpptyBeforeSalesOPsEngagement(string oppStage,string accId)
    {
        return ApexWebServices.validateOpptyBeforeSalesOPsEngagement(accId,oppStage);
    }

    @AuraEnabled
    public static Response closeOpptyMPUB(String closeOpportunityParams){
        Response response = new Response();
        Map<String, String> params = (Map<String, String>) JSON.deserialize(closeOpportunityParams, Map<String, String>.class);
        try {
            DowngradeWizardController.submitForm(params);
            response.addMessage('success', 'Opportunity is closed.');
        } catch (Exception e) {
            response.error(e.getTypeName(), e.getMessage());
        }
        return response;
    }

    @AuraEnabled
    public static List<Opportunity> getOpprecord(String recordId){
        System.debug('inside getOpprecord');
        List<Opportunity> opportunityToProcess = new List<Opportunity>();
        List<Opportunity> opps = new OpportunitySelector()
            .selectOpportunitiesForClose(recordId)
            .executeQuery();

        if (opps.size() == 1) {
            return opps;
        }

        List<BillingWrappers.QuotePackageInfo> masterQuotePackageInfo = QuoteHelper.getPackageInfoList(opps[0]?.PrimaryQuote__r);
        for (BillingWrappers.QuotePackageInfo pInfo : masterQuotePackageInfo) {
           for (Opportunity opportunity: opps){
                if (pInfo?.productName == opportunity.Tier_Name__c) {
                    opportunityToProcess.add(opportunity);
                }
            }
        }
        System.debug('opps'+opps);
        return opportunityToProcess;
    }

    @AuraEnabled
    public static String createCaseFromOpp(String oppId,
                                           String caseCategory,
                                           String caseType,
                                           String caseDescription,
                                           String casePriority,
                                           String caseUrgency,
                                           String caseRecord)
    {
        String s;
        try
        {
            s = ApexWebServices.createCaseFromOpp(oppId,caseCategory,caseType,caseDescription,casePriority,caseUrgency,caseRecord);
            system.debug('??'+s);

        }


        catch(exception e)
        {
            system.debug('message'+e.getMessage());
            system.debug('message-line'+e.getLineNumber());
            s= e.getMessage()+e.getLineNumber();
        }

        return s;
    }

    @AuraEnabled
    public static Boolean getIsMPUB(Id accountId) {
        return AccountHelper.isMPUBAccount(accountId);
    }

    @AuraEnabled
    public static List<Id> getMPUBTechnicalQuotesIds(Id oppId) {
        List<Id> techQuoteIds = new List<Id>();
        List<Quote> quotes = new QuoteSelector()
            .selectTechQuotesForClose(new List<Object>{ oppId })
            .executeQuery();

        for(Quote quote : quotes) {
            if (quote.IsMultiProductTechnicalQuote__c) {
                techQuoteIds.add(quote.Id);
            }
        }

        return techQuoteIds;
    }

    public static List <String> getPicklistValues()
    {
        List<String> plValues = new List<String>();
        Schema.SObjectType objType = ((SObject)Type.forName('Case').newInstance()).getSObjectType();
        Schema.DescribeSObjectResult objDescribe = objType.getDescribe();
        Schema.DescribeFieldResult objFieldInfo = objDescribe.fields.getMap().get('Type1__c').getDescribe();
        List<Schema.PicklistEntry> picklistvalues = objFieldInfo.getPicklistValues();
        //Add the picklist values to list.
        for(Schema.PicklistEntry plv: picklistvalues) {
            plValues.add(plv.getValue());
        }
        plValues.sort();
        return plValues;
    }

    @AuraEnabled
    public static Map<String, List<String>> getDependentMap(sObject objDetail, string contrfieldApiName,string depfieldApiName) {
        String controllingField = contrfieldApiName.toLowerCase();
        String dependentField = depfieldApiName.toLowerCase();

        Map<String,List<String>> objResults = new Map<String,List<String>>();

        Schema.sObjectType objType = objDetail.getSObjectType();
        if (objType==null){
            return objResults;
        }

        Map<String, Schema.SObjectField> objFieldMap = objType.getDescribe().fields.getMap();

        if (!objFieldMap.containsKey(controllingField) || !objFieldMap.containsKey(dependentField)){
            return objResults;
        }

        Schema.SObjectField theField = objFieldMap.get(dependentField);
        Schema.SObjectField ctrlField = objFieldMap.get(controllingField);

        List<Schema.PicklistEntry> contrEntries = ctrlField.getDescribe().getPicklistValues();
        List<PicklistEntryWrapper> depEntries = wrapPicklistEntries(theField.getDescribe().getPicklistValues());
        List<String> controllingValues = new List<String>();

        for (Schema.PicklistEntry ple : contrEntries) {
            String label = ple.getLabel();
            objResults.put(label, new List<String>());
            controllingValues.add(label);
        }

        for (PicklistEntryWrapper plew : depEntries) {
            String label = plew.label;
            String validForBits = base64ToBits(plew.validFor);
            for (Integer i = 0; i < validForBits.length(); i++) {
                String bit = validForBits.mid(i, 1);
                if (bit == '1') {
                    objResults.get(controllingValues.get(i)).add(label);
                }
            }
        }
        return objResults;
    }

    public static String decimalToBinary(Integer val) {
        String bits = '';
        while (val > 0) {
            Integer remainder = Math.mod(val, 2);
            val = Integer.valueOf(Math.floor(val / 2));
            bits = String.valueOf(remainder) + bits;
        }
        return bits;
    }

    public static String base64ToBits(String validFor) {
        if (String.isEmpty(validFor)) {
            return '';
        }
        String validForBits = '';

        for (Integer i = 0; i < validFor.length(); i++) {
            String thisChar = validFor.mid(i, 1);
            Integer val = base64Chars.indexOf(thisChar);
            String bits = decimalToBinary(val).leftPad(6, '0');
            validForBits += bits;
        }

        return validForBits;
    }

    private static final String base64Chars = '' +
        'ABCDEFGHIJKLMNOPQRSTUVWXYZ' +
        'abcdefghijklmnopqrstuvwxyz' +
        '0123456789+/';


    private static List<PicklistEntryWrapper> wrapPicklistEntries(List<Schema.PicklistEntry> PLEs) {
        return (List<PicklistEntryWrapper>)
            JSON.deserialize(JSON.serialize(PLEs), List<PicklistEntryWrapper>.class);
    }

    public class PicklistEntryWrapper{
        public String active {get;set;}
        public String defaultValue {get;set;}
        public String label {get;set;}
        public String value {get;set;}
        public String validFor {get;set;}
        public PicklistEntryWrapper(){
        }
    }
}