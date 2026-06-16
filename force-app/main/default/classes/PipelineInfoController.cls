public with sharing class PipelineInfoController {

    public static final Set<String> OPP_SOURCE_FIELDS = new Set<String> {
        'Source_For_Contact_Center_Pipeline__c',
        'Source_For_Engage_Digital_Pipeline__c',
        'Source_For_Engage_Voice_Pipeline__c',
        'Source_For_Global_Office_Pipeline__c',
        'Source_For_Hardware_Pipeline__c',
        'Source_For_Office_Pipeline__c',
        'Source_For_One_Time_Pipeline__c',
        'Source_For_ProServ_Pipeline__c',
        'Source_For_RingCentral_Video_Pipeline__c',
        'Source_For_Total_Pipeline__c',
        'Source_for_RC_Event_Pipeline__c'
    };

    public static final Set<String> OPP_PIPELINE_FIELDS = new Set<String> {
        'Estimated_12M_Total_Pipeline__c',
        'Estimated_Hardware__c',
        'Estimated_One_Time_Pipeline__c',
        'EstimatedProfessionalServices12Month__c',
        'Estimated_12M_Office_Pipeline__c',
        'Estimated_12M_Contact_Center_Pipeline__c',
        'Estimated_12M_Global_Office_Pipeline__c',
        'Estimated_12M_Engage_Digital_Pipeline__c',
        'Estimated_12M_Engage_Voice_Pipeline__c',
        'Estimated_12M_RingCentral_Video_Pipeline__c',
        'Estimated_12M_Engagement_Pipeline__c',
        'Calculated_12M_Total_Pipeline__c',
        'Forecasted_Users__c',
        'Forecast_Contact_Center_Users__c',
        'Forecasted_Global_Office_Users__c',
        'ForcastedDimeloUsers__c',
        'Forecast_Connect_First_Users__c',
        'Forecasted_Events_Users__c',
        'Forecasted_RingCentral_Video_Users__c',
        'Calculated_Total_MRR__c',
        'Estimated_CX_MRR__c',
        'Estimated_Total_MRR__c',
        'Seller_Forecast_Value__c',
        'Estimated_12M_RC_Events_Pipeline__c'
    };

    public static final Map<String, String> OPP_CONVERTED_PIPELINE_FIELDS = new Map<String, String> {
        'Converted_Estimated_12M_Total_Pipeline__c'=> 'FORMAT(Estimated_12M_Total_Pipeline__c) Converted_Estimated_12M_Total_Pipeline__c',
        'Converted_Estimated_Hardware__c' => 'FORMAT(Estimated_Hardware__c) Converted_Estimated_Hardware__c',
        'Converted_Estimated_One_Time_Pipeline__c' => 'FORMAT(Estimated_One_Time_Pipeline__c) Converted_Estimated_One_Time_Pipeline__c',
        'Converted_EstimatedProfessionalServices12Month__c' => 'FORMAT(EstimatedProfessionalServices12Month__c) Converted_EstimatedProfessionalServices12Month__c',
        'Converted_Estimated_12M_Office_Pipeline__c' => 'FORMAT(Estimated_12M_Office_Pipeline__c) Converted_Estimated_12M_Office_Pipeline__c',
        'Converted_Estimated_12M_Contact_Center_Pipeline__c' => 'FORMAT(Estimated_12M_Contact_Center_Pipeline__c) Converted_Estimated_12M_Contact_Center_Pipeline__c',
        'Converted_Estimated_12M_Global_Office_Pipeline__c' => 'FORMAT(Estimated_12M_Global_Office_Pipeline__c) Converted_Estimated_12M_Global_Office_Pipeline__c',
        'Converted_Estimated_12M_Engage_Digital_Pipeline__c' => 'FORMAT(Estimated_12M_Engage_Digital_Pipeline__c) Converted_Estimated_12M_Engage_Digital_Pipeline__c',
        'Converted_Estimated_12M_Engage_Voice_Pipeline__c' => 'FORMAT(Estimated_12M_Engage_Voice_Pipeline__c) Converted_Estimated_12M_Engage_Voice_Pipeline__c',
        'Converted_Estimated_12M_RingCentral_Video_Pipeline__c' => 'FORMAT(Estimated_12M_RingCentral_Video_Pipeline__c) Converted_Estimated_12M_RingCentral_Video_Pipeline__c',
        'Converted_Estimated_12M_Engagement_Pipeline__c' => 'FORMAT(Estimated_12M_Engagement_Pipeline__c) Converted_Estimated_12M_Engagement_Pipeline__c',
        'Converted_Estimated_12M_RC_Events_Pipeline__c' => 'FORMAT(Estimated_12M_RC_Events_Pipeline__c) Converted_Estimated_12M_RC_Events_Pipeline__c',
        'Converted_Calculated_12M_Total_Pipeline__c' => 'FORMAT(Calculated_12M_Total_Pipeline__c) Converted_Calculated_12M_Total_Pipeline__c',
        'Converted_Calculated_Total_MRR__c' => 'FORMAT(Calculated_Total_MRR__c) Converted_Calculated_Total_MRR__c',
        'Converted_Estimated_CX_MRR__c'=> 'FORMAT(Estimated_CX_MRR__c) Converted_Estimated_CX_MRR__c',
        'Converted_Estimated_Total_MRR__c' => 'FORMAT(Estimated_Total_MRR__c) Converted_Estimated_Total_MRR__c',
        'Converted_Seller_Forecast_Value__c' => 'FORMAT(Seller_Forecast_Value__c) Converted_Seller_Forecast_Value__c'
    };

    public static final Set<String> OPP_FIELDS = new Set<String> {
        'CurrencyIsoCode',
        'StageName',
        'Tier_Name__c'
    };

    public class PipelineInfoWrapper {
        @AuraEnabled public Map<String, String> sourceFields;
        @AuraEnabled public Map<String, Decimal> recordFields;
        @AuraEnabled public Map<String, String> convertedEstimatedFields;
        @AuraEnabled public String currencyIsoCode;
        @AuraEnabled public String stageName;
        @AuraEnabled public OpportunityMethods.OpportunityQuoteUsers quoteUsers;
    }

    @AuraEnabled(cacheable=true)
    public static PipelineInfoWrapper getPipelineInfo(String oppId) {
        PipelineInfoWrapper pipelineWrapper = new PipelineInfoWrapper();

        List<String> oppRecordFields = new List<String>();
        oppRecordFields.addAll(OPP_FIELDS);
        oppRecordFields.addAll(OPP_SOURCE_FIELDS);
        oppRecordFields.addAll(OPP_PIPELINE_FIELDS);
        oppRecordFields.addAll(OPP_CONVERTED_PIPELINE_FIELDS.values());

        Opportunity opp = Database.query('SELECT ' + String.join(oppRecordFields, ',') + ' FROM Opportunity WHERE Id =: oppId LIMIT 1');

        pipelineWrapper.quoteUsers = getQuoteUsersInfo(opp);
        pipelineWrapper.sourceFields = getSourceInfo(opp);
        pipelineWrapper.recordFields = getPipelineInfo(opp);
        pipelineWrapper.convertedEstimatedFields = getConvertedPipelineValues(opp);
        pipelineWrapper.currencyIsoCode = opp.CurrencyIsoCode;
        pipelineWrapper.stageName = opp.StageName;

        return pipelineWrapper;
    }

    public static Map<String, String> getSourceInfo(Opportunity opp) {
        Map<String, String> sourceApiToValue = new Map<String, String>();
        for (String sourceField : OPP_SOURCE_FIELDS) {
            sourceApiToValue.put(sourceField, (String)opp.get(sourceField));
        }
        return sourceApiToValue;
    }

    public static Map<String, Decimal> getPipelineInfo(Opportunity opp) {
        Map<String, Decimal> pipelineApiToValue = new Map<String, Decimal>();
        for (String pipelineField : OPP_PIPELINE_FIELDS) {
            pipelineApiToValue.put(pipelineField, (Decimal)opp.get(pipelineField));
        }
        return pipelineApiToValue;
    }

    public static Map<String, String> getConvertedPipelineValues(Opportunity opp) {
        Map<String, String> convertedApiToValue = new Map<String, String>();
        for (String convertedPipelineField : OPP_CONVERTED_PIPELINE_FIELDS.keySet()) {
            convertedApiToValue.put(convertedPipelineField, (String)opp.get(convertedPipelineField));
        }
        return convertedApiToValue;
    }

    public static OpportunityMethods.OpportunityQuoteUsers getQuoteUsersInfo(Opportunity opp) {
        OpportunityMethods.OpportunityQuoteUsers quoteUsers = new OpportunityMethods.OpportunityQuoteUsers();

        if (OpportunityPipelineHelper.EARLY_APPLICABLE_STAGES.contains(opp.StageName)
            || opp.StageName == OpportunityHelper.STAGE_NAME_DOWNGRADED) {
            return quoteUsers;
        }

        Map<Id, List<Quote>> quotesByOppId = OpportunityMethods.fetchOpportunityQuotes(new Set<Id>{opp.Id});
        return OpportunityMethods.getQuoteUsers(quotesByOppId, new Set<Id>{opp.Id}).get(opp.Id);
    }
}