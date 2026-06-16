public with sharing class OpportunityWarningMessageController {
   public class ResponseWrapper {
        public String message;
       	public String nextStage;

        public ResponseWrapper(String message, String nextStage) {
            this.message = message;
            this.nextStage = nextStage;
        }
    }

    @AuraEnabled
    public static String getData(Id oppId) {
        try {
            Opportunity opp = (Opportunity) new OpportunitySelector()
                .selectOpportunitiesForAuraComponentByIds(new Set<Id> {oppId})
                .executeQuery()
                .get(0);

            String message = getMessage(opp);

            return JSON.serialize(new ResponseWrapper(message, ''));
        } catch (Exception e) {
            PlatformLog.logException('OpportunityWarningMessageController', e);
            return null;
        }
    }

    private static String getMessage(Opportunity opp) {
        Boolean isOpportunityNotForForecasting = !QuoteHelper.isQuotingAvailableForBrand(opp.Brand_Name__c, opp.Type == OpportunityHelper.OPPORTUNITY_TYPE_NEW_BUSINESS)
                && OpportunityHelper.STAGE_NAMES_NO_FORECASTING_REPORTS.contains(opp.StageName);
        Boolean isVerizon = OpportunityHelper.isVerizon(opp);
        Boolean isRiseBrand = OpportunityHelper.isRiseBrand(opp);

        SettingsService.GSPPartnerSetup gspPartner = new SettingsService.GSPPartnerSetup(opp);

        if (isOpportunityNotForForecasting) {
            return String.format(Label.OpportunityNotCountedInForecasting, new List<Object> {opp.StageName, opp.Brand_Name__c});
        }

        if (isVerizon) {
            return Label.VerizonOnlyForProServ + '<br/>' + Label.VerizonPipelineNotAutoPopulated;
        }

        if (isRiseBrand) {
            return Label.RiseOnlyForProServ;
        }

        if (gspPartner.isQuotingNotSupported() || gspPartner.isDisableCommercialQuoting && gspPartner.isDisableProServ) {
            return Label.QuotingNotSupported;
        }

        if (gspPartner.isDisableProServ) {
            return Label.GSPPartnerOnlyForCommercialQuoting;
        }

        if (gspPartner.isDisableCommercialQuoting) {
            return Label.GSPPartnerOnlyForProServ;
        }

        return '';
    }

    @AuraEnabled
    public static String getStageValidationMessage(Id oppId) {
        String message = '';
        Integer nextStageNumber = 0;
        Opportunity oppty;
        if(OpportunityHelper.doesUserProfileHaveValidationRules()) {
            List<Opportunity> opptyList = new OpportunitySelector()
                .selectOpptyMandatoryFieldsByOpptyID(new List<Object> {oppId, OpportunityHelper.STAGE_NAMES_FOR_SHOWING_MANDATORY_FIELDS} )
                .executeQuery();
            if (opptyList != null && !opptyList.isEmpty()) {
                oppty = opptyList.get(0);
            }
            if(oppty != null) {
                if(!oppty.StageName.equalsIgnoreCase(OpportunityHelper.STAGE_NAMES_FOR_SHOWING_MANDATORY_FIELDS.get(OpportunityHelper.STAGE_NAMES_FOR_SHOWING_MANDATORY_FIELDS.size()-1))) {
                    oppty.StageName = OpportunityHelper.STAGE_NAMES_FOR_SHOWING_MANDATORY_FIELDS.get(OpportunityHelper.STAGE_NAMES_FOR_SHOWING_MANDATORY_FIELDS.indexOf(oppty.StageName)+1);
                }
                Map<Id, OpportunityHelper.ValidationCategory> opptyValidationCategoryMap = OpportunityHelper.getOpportunityValidationCategory(new List<Opportunity> { oppty });
                OpportunityHelper.ValidationCategory valCategory = opptyValidationCategoryMap.get(oppty.Id); 
                List<String> missingFields = new List<String>();
                if(valCategory != OpportunityHelper.ValidationCategory.GSP_VALIDATION) {
                    missingFields = OpportunityStageValidator.getMissingFieldLabelsForGivenStage(oppty, 
                                        OpportunityHelper.getARRConvertedToCorporateCCY(oppty.ID),
                                        valCategory);
                }
                if(!missingFields.isEmpty()) {
                    message = string.join(missingFields, ', ');
                    nextStageNumber = OpportunityHelper.STAGE_NAMES_FOR_SHOWING_MANDATORY_FIELDS.indexOf(oppty.StageName) + 1;
                }
            }
        }
        
        return JSON.serialize(new ResponseWrapper(message, 'Stage ' + nextStageNumber));
    }
}