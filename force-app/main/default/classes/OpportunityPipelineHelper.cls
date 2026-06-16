public with sharing class OpportunityPipelineHelper {

    public static final String LATE_STAGE_ESTIMATE_CHANGE_ERROR = '{0} value cannot be changed when the opportunity stage is Order/Closed';
    public static final String INAPPLICABLE_BRAND_ESTIMATE_CHANGE_ERROR = '{0} field cannot be changed when the opportunity brand is {1}';
    public static final Integer FORECASTED_USERS_MAX_VALUE = 9999999;
    public static final Set<String> EARLY_APPLICABLE_STAGES = new Set<String> {
        '1. Qualify',
        '2. Problem'
    };
    public static final Set<String> LATE_APPLICABLE_STAGES = new Set<String> {
        '6. Order',
        '7. Closed Won'
    };
    public static final Set<String> FINAL_LOCKED_STAGES = new Set<String> {
        '0. Downgraded',
        '7. Closed Won'
    };

    public static final String GLOBAL_OFFICE = 'Global Office';

    public static final String SOURCE_USERS = 'Forecasted Users';
    public static final String SOURCE_QUOTE = 'Quote Amounts';
    public static final String SOURCE_OVERRIDDEN = 'Overridden';
    public static final String SOURCE_WEAK_OVERRIDDEN = 'Weak Overridden';

    public class OpportunityPipeline {
        Schema.SObjectField field;
        String fieldLabel;
        String service;
        Schema.SObjectField usersField;
        Schema.SObjectField sourceField;
        public OpportunityPipeline(Schema.SObjectField field,
                String fieldLabel,
                String service,
                Schema.SObjectField usersField,
                Schema.SObjectField sourceField) {
            this.field = field;
            this.fieldLabel = fieldLabel;
            this.service = service;
            this.usersField = usersField;
            this.sourceField = sourceField;
        }
    }

     public static OpportunityPipeline AMOUNT {
        get {
            if (AMOUNT != null) {
                return AMOUNT;
            }
            AMOUNT = new OpportunityPipeline(
                Opportunity.Amount,
                Opportunity.Amount.getDescribe().getLabel(),
                null,
                null,
                null
            );
            return AMOUNT;
        }
        private set;
    }
    public static OpportunityPipeline OFFICE_PIPELINE {
        get {
            if (OFFICE_PIPELINE != null) {
                return OFFICE_PIPELINE;
            }
            OFFICE_PIPELINE = new OpportunityPipeline(
                Opportunity.Estimated_12M_Office_Pipeline__c,
                Opportunity.Estimated_12M_Office_Pipeline__c.getDescribe().getLabel(),
                'Office',
                Opportunity.Forecasted_Users__c,
                Opportunity.Source_For_Office_Pipeline__c
            );
            return OFFICE_PIPELINE;
        }
        private set;
    }
    public static OpportunityPipeline CC_PIPELINE {
        get {
            if (CC_PIPELINE != null) {
                return CC_PIPELINE;
            }
            CC_PIPELINE = new OpportunityPipeline(
                Opportunity.Estimated_12M_Contact_Center_Pipeline__c,
                Opportunity.Estimated_12M_Contact_Center_Pipeline__c.getDescribe().getLabel(),
                'Contact Center',
                Opportunity.Forecast_Contact_Center_Users__c,
                Opportunity.Source_For_Contact_Center_Pipeline__c
            );
            return CC_PIPELINE;
        }
        private set;
    }
    public static OpportunityPipeline ED_PIPELINE {
        get {
            if (ED_PIPELINE != null) {
                return ED_PIPELINE;
            }
            ED_PIPELINE = new OpportunityPipeline(
                Opportunity.Estimated_12M_Engage_Digital_Pipeline__c,
                Opportunity.Estimated_12M_Engage_Digital_Pipeline__c.getDescribe().getLabel(),
                'Engage Digital Standalone',
                Opportunity.ForcastedDimeloUsers__c,
                Opportunity.Source_For_Engage_Digital_Pipeline__c
            );
            return ED_PIPELINE;
        }
        private set;
    }
    public static OpportunityPipeline EVENT_PIPELINE {
        get {
            if (EVENT_PIPELINE != null) {
                return EVENT_PIPELINE;
            }
            EVENT_PIPELINE = new OpportunityPipeline(
                Opportunity.Estimated_12M_RC_Events_Pipeline__c,
                Opportunity.Estimated_12M_RC_Events_Pipeline__c.getDescribe().getLabel(),
                'Events',
                Opportunity.Forecasted_Events_Users__c,
                Opportunity.Source_for_RC_Event_Pipeline__c
            );
            return EVENT_PIPELINE;
        }
        private set;
    }
    public static OpportunityPipeline EV_PIPELINE {
        get {
            if (EV_PIPELINE != null) {
                return EV_PIPELINE;
            }
            EV_PIPELINE = new OpportunityPipeline(
                Opportunity.Estimated_12M_Engage_Voice_Pipeline__c,
                Opportunity.Estimated_12M_Engage_Voice_Pipeline__c.getDescribe().getLabel(),
                'Engage Voice Standalone',
                Opportunity.Forecast_Connect_First_Users__c,
                Opportunity.Source_For_Engage_Voice_Pipeline__c
            );
            return EV_PIPELINE;
        }
        private set;
    }
    public static OpportunityPipeline GO_PIPELINE {
        get {
            if (GO_PIPELINE != null) {
                return GO_PIPELINE;
            }
            GO_PIPELINE = new OpportunityPipeline(
                Opportunity.Estimated_12M_Global_Office_Pipeline__c,
                Opportunity.Estimated_12M_Global_Office_Pipeline__c.getDescribe().getLabel(),
                'Global Office',
                Opportunity.Forecasted_Global_Office_Users__c,
                Opportunity.Source_For_Global_Office_Pipeline__c
            );
            return GO_PIPELINE;
        }
        private set;
    }
    public static OpportunityPipeline VIDEO_PIPELINE {
        get {
            if (VIDEO_PIPELINE != null) {
                return VIDEO_PIPELINE;
            }
            VIDEO_PIPELINE = new OpportunityPipeline(
                Opportunity.Estimated_12M_RingCentral_Video_Pipeline__c,
                Opportunity.Estimated_12M_RingCentral_Video_Pipeline__c.getDescribe().getLabel(),
                'RC Meetings',
                Opportunity.Forecasted_RingCentral_Video_Users__c,
                Opportunity.Source_For_RingCentral_Video_Pipeline__c
            );
            return VIDEO_PIPELINE;
        }
        private set;
    }
    public static OpportunityPipeline HARDWARE_PIPELINE {
        get {
            if (HARDWARE_PIPELINE != null) {
                return HARDWARE_PIPELINE;
            }
            HARDWARE_PIPELINE = new OpportunityPipeline(
                Opportunity.Estimated_Hardware__c,
                Opportunity.Estimated_Hardware__c.getDescribe().getLabel(),
                'Hardware',
                null,
                Opportunity.Source_For_Hardware_Pipeline__c
            );
            return HARDWARE_PIPELINE;
        }
        private set;
    }
    public static OpportunityPipeline PROSERV_PIPELINE {
        get {
            if (PROSERV_PIPELINE != null) {
                return PROSERV_PIPELINE;
            }
            PROSERV_PIPELINE = new OpportunityPipeline(
                Opportunity.EstimatedProfessionalServices12Month__c,
                Opportunity.EstimatedProfessionalServices12Month__c.getDescribe().getLabel(),
                'ProServ',
                null,
                Opportunity.Source_For_ProServ_Pipeline__c
            );
            return PROSERV_PIPELINE;
        }
        private set;
    }
    public static OpportunityPipeline ONE_TIME_PIPELINE {
        get {
            if (ONE_TIME_PIPELINE != null) {
                return ONE_TIME_PIPELINE;
            }
            ONE_TIME_PIPELINE = new OpportunityPipeline(
                Opportunity.Estimated_One_Time_Pipeline__c,
                Opportunity.Estimated_One_Time_Pipeline__c.getDescribe().getLabel(),
                'One-Time',
                null,
                Opportunity.Source_For_One_Time_Pipeline__c
            );
            return ONE_TIME_PIPELINE;
        }
        private set;
    }
    public static OpportunityPipeline ENGAGE_PIPELINE {
        get {
            if (ENGAGE_PIPELINE != null) {
                return ENGAGE_PIPELINE;
            }
            ENGAGE_PIPELINE = new OpportunityPipeline(
                Opportunity.Estimated_12M_Engagement_Pipeline__c,
                Opportunity.Estimated_12M_Engagement_Pipeline__c.getDescribe().getLabel(),
                null,
                null,
                null
            );
            return ENGAGE_PIPELINE;
        }
        private set;
    }
    public static OpportunityPipeline CX_MRR_PIPELINE {
        get {
            if (CX_MRR_PIPELINE != null) {
                return CX_MRR_PIPELINE;
            }
            CX_MRR_PIPELINE = new OpportunityPipeline(
                Opportunity.Estimated_CX_MRR__c,
                Opportunity.Estimated_CX_MRR__c.getDescribe().getLabel(),
                null,
                null,
                null
            );
            return CX_MRR_PIPELINE;
        }
        private set;
    }
    public static OpportunityPipeline CALCULATED_TOTAL_PIPELINE {
        get {
            if (CALCULATED_TOTAL_PIPELINE != null) {
                return CALCULATED_TOTAL_PIPELINE;
            }
            CALCULATED_TOTAL_PIPELINE = new OpportunityPipeline(
                Opportunity.Calculated_12M_Total_Pipeline__c,
                Opportunity.Calculated_12M_Total_Pipeline__c.getDescribe().getLabel(),
                null,
                null,
                null
            );
            return CALCULATED_TOTAL_PIPELINE;
        }
        private set;
    }
    public static OpportunityPipeline CALCULATED_TOTAL_MRR_PIPELINE {
        get {
            if (CALCULATED_TOTAL_MRR_PIPELINE != null) {
                return CALCULATED_TOTAL_MRR_PIPELINE;
            }
            CALCULATED_TOTAL_MRR_PIPELINE = new OpportunityPipeline(
                Opportunity.Calculated_Total_MRR__c,
                Opportunity.Calculated_Total_MRR__c.getDescribe().getLabel(),
                null,
                null,
                null
            );
            return CALCULATED_TOTAL_MRR_PIPELINE;
        }
        private set;
    }
    public static OpportunityPipeline ESTIMATED_TOTAL_PIPELINE {
        get {
            if (ESTIMATED_TOTAL_PIPELINE != null) {
                return ESTIMATED_TOTAL_PIPELINE;
            }
            ESTIMATED_TOTAL_PIPELINE = new OpportunityPipeline(
                Opportunity.Estimated_12M_Total_Pipeline__c,
                Opportunity.Estimated_12M_Total_Pipeline__c.getDescribe().getLabel(),
                null,
                null,
                Opportunity.Source_For_Total_Pipeline__c
            );
            return ESTIMATED_TOTAL_PIPELINE;
        }
        private set;
    }
    public static OpportunityPipeline ESTIMATED_TOTAL_MRR_PIPELINE {
        get {
            if (ESTIMATED_TOTAL_MRR_PIPELINE != null) {
                return ESTIMATED_TOTAL_MRR_PIPELINE;
            }
            ESTIMATED_TOTAL_MRR_PIPELINE = new OpportunityPipeline(
                Opportunity.Estimated_Total_MRR__c,
                Opportunity.Estimated_Total_MRR__c.getDescribe().getLabel(),
                null,
                null,
                Opportunity.Source_For_Total_Pipeline__c
            );
            return ESTIMATED_TOTAL_MRR_PIPELINE;
        }
        private set;
    }
    public static List<OpportunityPipeline> ALL_PIPELINES = new List<OpportunityPipeline> {
        OFFICE_PIPELINE,
        CC_PIPELINE,
        ED_PIPELINE,
        EV_PIPELINE,
        GO_PIPELINE,
        VIDEO_PIPELINE,
        EVENT_PIPELINE,
        HARDWARE_PIPELINE,
        PROSERV_PIPELINE,
        ONE_TIME_PIPELINE,
        ESTIMATED_TOTAL_PIPELINE,
        ESTIMATED_TOTAL_MRR_PIPELINE
    };
    public static List<OpportunityPipeline> RECURRING_NONTOTAL_PIPELINES = new List<OpportunityPipeline> {
        OFFICE_PIPELINE,
        CC_PIPELINE,
        ED_PIPELINE,
        EV_PIPELINE,
        GO_PIPELINE,
        VIDEO_PIPELINE,
        EVENT_PIPELINE
    };
    public static List<OpportunityPipeline> NON_RECURRING_PIPELINES = new List<OpportunityPipeline> {
        HARDWARE_PIPELINE,
        PROSERV_PIPELINE,
        ONE_TIME_PIPELINE
    };
    public static List<OpportunityPipeline> OVERRIDABLE_PIPELINES = new List<OpportunityPipeline> {
        HARDWARE_PIPELINE,
        PROSERV_PIPELINE,
        ONE_TIME_PIPELINE,
        ESTIMATED_TOTAL_PIPELINE,
        ESTIMATED_TOTAL_MRR_PIPELINE
    };

    public static void populateSourcesForNewOppty(Opportunity opp) {
        enforceUserBasedSources(opp);
        final Decimal totalValue = (Decimal) opp.get(ESTIMATED_TOTAL_PIPELINE.field);
        final Decimal totalMRRValue = (Decimal) opp.get(ESTIMATED_TOTAL_MRR_PIPELINE.field);
        opp.put(
            ESTIMATED_TOTAL_PIPELINE.sourceField,
            totalValue == null || totalValue == 0 ? SOURCE_USERS : SOURCE_OVERRIDDEN
        );
        opp.put(
            ESTIMATED_TOTAL_MRR_PIPELINE.sourceField,
            totalMRRValue == null || totalMRRValue == 0 ? SOURCE_USERS : SOURCE_OVERRIDDEN
        );
        for (OpportunityPipeline pipeline : NON_RECURRING_PIPELINES) {
            final Decimal value = (Decimal) opp.get(pipeline.field);
            opp.put(pipeline.sourceField, value == null || value == 0 ? SOURCE_QUOTE : SOURCE_OVERRIDDEN);
        }
    }

    public static void enforceUserBasedSources(Opportunity opp) {
        for (OpportunityPipeline pipeline : RECURRING_NONTOTAL_PIPELINES) {
            opp.put(pipeline.sourceField, SOURCE_USERS);
        }
    }

    public static void detectOverridesAndPopulateSources(Opportunity opp, Opportunity oldOpp) {
        for (OpportunityPipeline pipeline : OVERRIDABLE_PIPELINES) {
            if (opp.get(pipeline.field) != oldOpp.get(pipeline.field) && oldOpp.get(pipeline.field) != null) {
                if ((pipeline.field == ESTIMATED_TOTAL_PIPELINE.field || pipeline.field == ESTIMATED_TOTAL_MRR_PIPELINE.field) && EARLY_APPLICABLE_STAGES.contains(opp.StageName)) {
                    opp.put(pipeline.sourceField, SOURCE_WEAK_OVERRIDDEN);
                } else {
                    opp.put(pipeline.sourceField, SOURCE_OVERRIDDEN);
                }
            }
        }
        // Temporary recalculate Total Estimated Pipeline (while exists ARR and MRR)
        if (opp.get(ESTIMATED_TOTAL_PIPELINE.field) != oldOpp.get(ESTIMATED_TOTAL_PIPELINE.field) && oldOpp.get(ESTIMATED_TOTAL_PIPELINE.field) != null) {
            if (opp.get(ESTIMATED_TOTAL_PIPELINE.field) != (Decimal)opp.get(ESTIMATED_TOTAL_MRR_PIPELINE.field) * 12) {
                opp.put(ESTIMATED_TOTAL_MRR_PIPELINE.field, ((Decimal)opp.get(ESTIMATED_TOTAL_PIPELINE.field) / 12).setscale(2));
            }
        } else if (opp.get(ESTIMATED_TOTAL_MRR_PIPELINE.field) != oldOpp.get(ESTIMATED_TOTAL_MRR_PIPELINE.field) && oldOpp.get(ESTIMATED_TOTAL_MRR_PIPELINE.field) != null) {
            if ((Decimal)opp.get(ESTIMATED_TOTAL_MRR_PIPELINE.field) * 12 != opp.get(ESTIMATED_TOTAL_PIPELINE.field)) {
                opp.put(ESTIMATED_TOTAL_PIPELINE.field, ((Decimal)opp.get(ESTIMATED_TOTAL_MRR_PIPELINE.field) * 12).setscale(2));
            }
        }
    }

    public static void enforceQuoteAmountsSources(Opportunity opp, Boolean isDiscardOverriden) {
        List<Opportunity> result = new List<Opportunity>();
        for (OpportunityPipeline pipeline : ALL_PIPELINES) {
            if (isDiscardOverriden || opp.get(pipeline.sourceField) != SOURCE_OVERRIDDEN) {
                opp.put(pipeline.sourceField, SOURCE_QUOTE);
            }
        }
    }

    public static void validateMaxUsersNotExceeded(Opportunity opp, Opportunity oldOpp) {
        for (OpportunityPipeline pipeline : RECURRING_NONTOTAL_PIPELINES) {
            if (opp.get(pipeline.usersField) == null) {
                continue;
            }
            final Decimal usersValue = (Decimal) opp.get(pipeline.usersField);
            if (usersValue > FORECASTED_USERS_MAX_VALUE) {
                opp.addError(
                    'Invalid value for forecasted field (Max: ' + String.valueOf(FORECASTED_USERS_MAX_VALUE) + ')'
                );
            }
        }
    }

    public static void validateQuoteBasedEstimatesWereNotChangedManually(Opportunity opp, Opportunity oldOpp) {
        String errorFields = '';
        for (OpportunityPipeline p : OVERRIDABLE_PIPELINES) {
            // neglect 0.01 difference (lightning <-> classic layout switch bug)
            if (NumberHelper.roundCurrency((Decimal) oldOpp.get(p.field), 1)
                    != NumberHelper.roundCurrency((Decimal) opp.get(p.field), 1)) {
                errorFields += p.fieldLabel;
            }
        }
        if(!String.isEmpty(errorFields)) {
            opp.addError(String.format(LATE_STAGE_ESTIMATE_CHANGE_ERROR, new List<String>{errorFields}));
        } else {
            // preserve old values to avoid updating fields with 0.01 difference
            for (OpportunityPipeline p : OVERRIDABLE_PIPELINES) {
                opp.put(p.field, oldOpp.get(p.field));
            }
        }
    }

    public static void validateUsersUnchangedAfterOppClosed(Opportunity opp, Opportunity oldOpp) {
        if (!FINAL_LOCKED_STAGES.contains(opp.StageName)) {
            return;
        }
        for (OpportunityPipeline pipeline : RECURRING_NONTOTAL_PIPELINES) {
            if (opp.get(pipeline.usersField) != oldOpp.get(pipeline.usersField)) {
                opp.addError('Closed type of stages does not allow change on forecasted fields');
                break;
            }
        }
    }

    public static void validateAdminAndSalesProfilesCannotChangeForecastedUsers(Opportunity opp, Opportunity oldOpp) {
        if (ProfileHelper.ADMIN_OR_SALES_PROFILE_ID_TO_NAME.get(UserInfo.getProfileId()) == null) {
            return;
        }
        //EU Privacy Phase 3 Sales Profiles Changes - START
        List<String> salesEngrProfiles = new List<String>();//-----created to store sales engineer lightning and its EU restricted profiles
        List<EU_Component_reference__mdt> profileList = [Select DeveloperName,Values__c from EU_Component_reference__mdt where Apex_Classes__c like '%OpportunityPipelineHelper%' and DeveloperName='validateAdminAndSalesProfiles'];
        for(EU_Component_reference__mdt profRec:profileList){
            if(String.isNotBlank(profRec.Values__c)) {
                salesEngrProfiles.addall(profRec.Values__c.split(','));
            }
        }

        for (OpportunityPipeline pipeline : RECURRING_NONTOTAL_PIPELINES) {
            if (opp.get(pipeline.usersField) != oldOpp.get(pipeline.usersField)) {
                if (pipeline.service == VIDEO_PIPELINE.service
                  && salesEngrProfiles.contains(ProfileHelper.ADMIN_OR_SALES_PROFILE_ID_TO_NAME.get(UserInfo.getProfileId())) //EU Privacy Phase 3 Sales Profiles Changes - END
                ) {
                    continue;
                }
                opp.addError('Profile does not have permission to edit Forecast fields');
                break;
            }
        }
    }

    public static void enforceNonNullValues(Opportunity opp) {
        for (OpportunityPipeline pipeline : ALL_PIPELINES) {
            if (pipeline.usersField != null && opp.get(pipeline.usersField) == null) {
                opp.put(pipeline.usersField, 0);
            }
            if (opp.get(pipeline.field) == null) {
                opp.put(pipeline.field, 0);
            }
        }
    }

    public static void performBrandSpecificValidationsAndDefaults(Opportunity opp, Opportunity oldOpp) {
        if (opp.Tier_Name__c == null || FINAL_LOCKED_STAGES.contains(opp.StageName)) {
            return;
        }
        if (oldOpp != null && opp.Tier_Name__c != oldOpp.Tier_Name__c) {
            // Reset all users on tier change
            for (OpportunityPipeline pipeline : RECURRING_NONTOTAL_PIPELINES) {
                opp.put(pipeline.usersField, 0);
            }
            opp.put(HARDWARE_PIPELINE.field, 0);
            return;
        }
        for (String tierName : new List<String>{'engage digital', 'engage voice', 'rc meetings'} ) {
            if (opp.Tier_Name__c.containsIgnoreCase(tierName)) {
                for (OpportunityPipeline pipeline : RECURRING_NONTOTAL_PIPELINES) {
                     // preserve value only in one of the forecasted users fields - the one specific to the opp brand
                    if (!pipeline.service.containsIgnoreCase(tierName)) {
                        if (oldOpp != null
                                && opp.get(pipeline.usersField) != oldOpp.get(pipeline.usersField)
                                && oldOpp.get(pipeline.usersField) != null) {
                            opp.addError(String.format(
                                INAPPLICABLE_BRAND_ESTIMATE_CHANGE_ERROR,
                                new List<String>{pipeline.fieldLabel, opp.Tier_Name__c}
                            ));
                            opp.put(pipeline.usersField, 0);
                        }
                    }
                }
                if (oldOpp != null && opp.get(HARDWARE_PIPELINE.field) != oldOpp.get(HARDWARE_PIPELINE.field)) {
                    opp.addError(String.format(
                        INAPPLICABLE_BRAND_ESTIMATE_CHANGE_ERROR,
                        new List<String>{HARDWARE_PIPELINE.fieldLabel, opp.Tier_Name__c}
                    ));
                }
                opp.put(HARDWARE_PIPELINE.field, 0);
            }
        }
    }

    public static void performCalculations(List<Opportunity> opps, Map<Id, List<Quote>> quotesByOppId) {
        Map<Id, Opportunity> oppsIdsToOpps = new Map<Id, Opportunity>();
        for (Opportunity opp : opps) {
            if (opp?.Id != null) {
                oppsIdsToOpps.put(opp.Id, opp);
                }
            }
        Map<Id, Boolean> oppIdToIsMaster = OpportunityHelper.getIsMasterMultiproductOpportunities(oppsIdsToOpps.keySet());
        Map<Id, OpportunityMethods.OpportunityEstimates> quoteAmountsByOppId =
            OpportunityMethods.calculateQuoteByOpportunity(quotesByOppId, oppsIdsToOpps, oppIdToIsMaster);
        Map<Id, OpportunityMethods.OpportunityQuoteUsers> quoteUsersByOppId =
            OpportunityMethods.getQuoteUsers(quotesByOppId, oppsIdsToOpps.keySet());
        for (Opportunity opp : opps) {
            if (opp == null) {
                continue;
            }
            final OpportunityMethods.OpportunityEstimates opportunityAmounts = quoteAmountsByOppId.get(opp.Id);
            final OpportunityMethods.OpportunityQuoteUsers quoteUsers = quoteUsersByOppId.get(opp.Id);
            quoteUsers?.populateNumberOfSeatsOnOppty(opp);

            // Opportunities with empty quotes should fall back to users-based values
            for (OpportunityPipeline pipeline : RECURRING_NONTOTAL_PIPELINES) {

                Boolean isOpptyToProcess = (opp.Tier_Name__c == pipeline.service)
                        && !LATE_APPLICABLE_STAGES.contains(opp.StageName)
                    && opportunityAmounts?.get(pipeline.service) == 0;
                Boolean isOpptyHasNoQuotes = quotesByOppId.get(opp.Id) == null || quotesByOppId.get(opp.Id).size() == 0;

                if (isOpptyToProcess && (Decimal) opp.get(pipeline.usersField) > 0) {
                    opp.put(pipeline.sourceField, SOURCE_USERS);
                }
                if (isOpptyToProcess) {
                    if (isOpptyHasNoQuotes || !opp.IsMultiProductTechnicalOpportunity__c) {
                        if (pipeline.service == VIDEO_PIPELINE.service
                        || (pipeline.service == GO_PIPELINE.service && quoteUsers.get(OFFICE_PIPELINE.service) != null)) {
                            continue;
                        }
                            opp.put(pipeline.sourceField, SOURCE_USERS);
                        } else if (QuoteHelper.getCCQuote(quotesByOppId.get(opp.Id)) == null
                                && pipeline.service == CC_PIPELINE.service
                                && !opp.IsMultiProductTechnicalOpportunity__c) {
                            opp.put(pipeline.sourceField, SOURCE_USERS);
                        }
                }
            }
            for (OpportunityPipeline pipeline : RECURRING_NONTOTAL_PIPELINES) {
                if (opp.get(pipeline.sourceField) == SOURCE_QUOTE) {
                    opp.put(
                        pipeline.field,
                        EARLY_APPLICABLE_STAGES.contains(opp.StageName) || opportunityAmounts == null
                            ? 0
                            : opportunityAmounts.get(pipeline.service)
                    );
                } else if (opp.get(pipeline.sourceField) == SOURCE_USERS) {
                    opp.put(
                        pipeline.field,
                        DocumentHelper.getEstimatedPriceByOpportunity(
                            opp, (Decimal) opp.get(pipeline.usersField), pipeline.service
                        )
                    );
                } 
                if (!EARLY_APPLICABLE_STAGES.contains(opp.StageName)
                    && opp.StageName != OpportunityHelper.STAGE_NAME_DOWNGRADED
                    && quoteUsers?.get(pipeline.service)>0 && quoteUsers?.get(pipeline.service) != null) {
                    opp.put(pipeline.usersField, quoteUsers.get(pipeline.service));
                }
            }
            for (OpportunityPipeline pipeline : NON_RECURRING_PIPELINES) {
                if (opp.get(pipeline.sourceField) != SOURCE_OVERRIDDEN) {
                    opp.put(
                        pipeline.field,
                        opportunityAmounts == null
                            ? 0
                            : opportunityAmounts.get(pipeline.service)
                    );
                }
            }
            final Decimal engageTotal = (Decimal) opp.get(CC_PIPELINE.field)
                + (Decimal) opp.get(ED_PIPELINE.field) + (Decimal) opp.get(EV_PIPELINE.field);
            final Decimal total = engageTotal + (Decimal) opp.get(OFFICE_PIPELINE.field)
                + (Decimal) opp.get(GO_PIPELINE.field) + (Decimal) opp.get(VIDEO_PIPELINE.field)+ (Decimal) opp.get(EVENT_PIPELINE.field);
         
            opp.put(ENGAGE_PIPELINE.field, engageTotal);
            opp.put(CX_MRR_PIPELINE.field, (engageTotal / 12).setscale(2));
            opp.put(CALCULATED_TOTAL_PIPELINE.field, total);
            opp.put(CALCULATED_TOTAL_MRR_PIPELINE.field, (total / 12).setscale(2));
            if (opp.get(ESTIMATED_TOTAL_PIPELINE.sourceField) != SOURCE_OVERRIDDEN
                && opp.get(ESTIMATED_TOTAL_PIPELINE.sourceField) != SOURCE_WEAK_OVERRIDDEN) {
                opp.put(ESTIMATED_TOTAL_PIPELINE.field, total);
                opp.put(AMOUNT.field, total);
                opp.put(ESTIMATED_TOTAL_MRR_PIPELINE.field, (total / 12).setscale(2));
            }
        }
    }
}