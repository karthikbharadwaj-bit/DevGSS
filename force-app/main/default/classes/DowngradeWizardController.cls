public with sharing class DowngradeWizardController {
    public static final String WIZARD_TYPE_DOWNGRADE = 'Downgrade';
    public static final String WIZARD_TYPE_CLOSE = 'close';
    public static final String WIZARD_TYPE_DOWNSELL = 'downsell';
    public static final String WIZARD_TYPE_DOWNSELLWITHRETENTION = 'downsellwithretention';
    public static final String WIZARD_TYPE_CANCEL = 'cancel';
    public static final String WIZARD_TYPE_SAVE = 'save';
    public static final String WIZARD_TYPE_WINBACK = 'winback';

    public static Boolean IS_IN_DOWNGRADE_PROCESS_FORM = false;

    public DowngradeWizardController() {
    }

    public class PanelConfig {
        @AuraEnabled public string name;
        @AuraEnabled public string display;
        @AuraEnabled public Boolean multiple;
        @AuraEnabled public string options;
        @AuraEnabled public string optionsOrdered;

        @AuraEnabled public Map<string, List<AdditionalConfig>> additionalConfigs;

        public PanelConfig(Source params) {
            System.debug('+++ params ' + params);
            String optionsOrdered = JSON.serialize(SFDescribeHelper.getOptions(params.obj, params.plFieldName));

            String options = optionsOrdered;
            if (params.plFieldNameDependent != null) {
                options = JSON.serialize(SFDescribeHelper.getDependentOptions(params.obj, params.plFieldName, params.plFieldNameDependent));
            }

            this.name = params.name;
            this.display = params.display;
            this.multiple = params.multiple;
            this.options = options;
            this.optionsOrdered = optionsOrdered;
            this.additionalConfigs = getAdditionalConfig(params.additionalOptions);
        }
    }
    public class AdditionalConfig {
        @AuraEnabled public string fieldName;
        @AuraEnabled public string name;
        @AuraEnabled public string label;
        @AuraEnabled public string type;
        @AuraEnabled public boolean required;
        @AuraEnabled public string stringLength;
        @AuraEnabled public string options;

        public AdditionalConfig(AdditionalOptionConfig aOptionConfig) {
            this.fieldName       = aOptionConfig.plFieldName;
            this.name            = aOptionConfig.plFieldName;
            this.label           = AquivaHelper.getFieldLabel(aOptionConfig.obj, aOptionConfig.plFieldName);
            this.type            = aOptionConfig.type;
            this.required        = aOptionConfig.required;
            this.stringLength    = aOptionConfig.stringLength;
            this.type            = aOptionConfig.type;
            this.options         = JSON.serialize(SFDescribeHelper.getOptions(aOptionConfig.obj, aOptionConfig.plFieldName));
        }
    }

    public class AdditionalOption {
        @AuraEnabled public string value;
        @AuraEnabled public AdditionalOptionConfig[] configs;
    }
    public class AdditionalOptionConfig {
        @AuraEnabled public string obj;
        @AuraEnabled public string plFieldName;
        @AuraEnabled public string type;
        @AuraEnabled public boolean required;
        @AuraEnabled public string stringLength;
    }

    public class Source {
        @AuraEnabled public string id;
        @AuraEnabled public string name;
        @AuraEnabled public string obj;
        @AuraEnabled public string plFieldName;
        @AuraEnabled public string plFieldNameDependent;

        @AuraEnabled public string display;
        @AuraEnabled public Boolean multiple;

        @AuraEnabled public AdditionalOption[] additionalOptions;
    }

    public static Map<string, List<AdditionalConfig>> getAdditionalConfig(List<AdditionalOption> additionalOptions) {
        Map<string, List<AdditionalConfig>> result;

        if(additionalOptions != null) {
            result = new Map<string, List<AdditionalConfig>>();

            for(AdditionalOption aOption : additionalOptions) {

                // list additional configs
                List<AdditionalConfig> configList = new List<AdditionalConfig>();
                for(AdditionalOptionConfig aOptionConfig : aOption.configs) {
                    configList.add(new AdditionalConfig(aOptionConfig));
                }

                result.put(aOption.value, configList);
            }
        }

        return result;
    }

    @AuraEnabled
    public static PanelConfig getPanelConfig(String params) {
        Source panelSource = (Source)JSON.deserialize(params, Source.class);
        PanelConfig result;

        try {
            result = new PanelConfig(panelSource);
        } catch(Exception e) {
            AquivaHelper.throwAuraException(e);
        }

        return result;
    }

    @AuraEnabled
    public static List<PanelConfig> getAllPanelConfigs(String params) {
        system.debug(params);
        List<Source> panelSources = (List<Source>)JSON.deserialize(params, List<Source>.class);
        List<PanelConfig> result = new List<PanelConfig>();

        try {
            for(Source src: panelSources) {
                PanelConfig cfg = new PanelConfig(src);
                result.add(cfg);
            }
        } catch (Exception e) {
            AquivaHelper.throwAuraException(e);
        }

        return result;
    }

    @AuraEnabled
    public static Id submitForm(Map<String, String> params) {
        IS_IN_DOWNGRADE_PROCESS_FORM = true;

        String stageName = 'StageName';
        String subStage = 'Sub_Stage__c';
        String wizardType = params.remove('wType');
        String brandName = params.remove('brandName');
        Boolean isInline = BooleanHelper.toBoolean(params.remove('isInline'));
        Opportunity opp = new Opportunity(Id = params.get('Id'));
        try {
            // If necessary, update should be done before the stage is determined, cause EndStage__c depends on confirm and close flag
            // Will do this only in case if wizard type is not equlas to Downgrade
            if (!OpportunityHelper.BRAND_BT_BUSINESS.equalsIgnoreCase(brandName)
                && !RingCentralHelper.BRAND_TELUS_BUSINESS_CONNECT.equalsIgnoreCase(brandName)
                && !RingCentralHelper.BRAND_VODAFONE.equalsIgnoreCase(brandName)
                && !isInline
                && wizardType != WIZARD_TYPE_DOWNGRADE
                && OpportunityHelper.isCustomerConfirmationEmailFlow(opp.Id)
            ) {
                opp.ConfirmAndClose__c = true;
                update opp;
            } else if (RingCentralHelper.BRAND_VODAFONE.equalsIgnoreCase(brandName)) {
                opp.ConfirmAndClose__c = false;
                update opp;
            }

            opp = OpportunityHelper.getOpportunity(params.get('Id'));

            if(!isInline) {
                Switch on wizardType {
                    when 'close', 'downsell', 'downsellwithretention' {
                        if (opp.EndStage__c != null) {
                            params.put(stageName, opp.EndStage__c);
                        } else {
                            params.put(stageName, OpportunityHelper.STAGE_NAME_CLOSED_WON);
                        }
                    }
                    when 'cancel' {
                        params.put(stageName, OpportunityHelper.STAGE_NAME_CLOSED_WON);
                        params.put(subStage, opp.GoldfingerRetention__c);
                        params.put('GoldfingerRetention__c', 'Cancel');
                    }
                    when 'save' {
                        params.put(stageName, OpportunityHelper.STAGE_NAME_CLOSED_WON);
                        params.put(subStage, opp.GoldfingerRetention__c);
                    }
                    when 'winback' {
                        params.put(stageName, OpportunityHelper.STAGE_NAME_CLOSED_WON);
                        params.put(subStage, opp.GoldfingerRetention__c);
                    }
                    when else {
                        params.put(stageName, OpportunityHelper.STAGE_NAME_DOWNGRADED);
                        params.put('Downgrade_Reason_Opp__c', params.get('Why_We_Lost__c'));
                    }
                }
            }

            Map<String, Schema.SObjectField> opportunityFieldMap = OpportunityHelper.DESCRIBE.fields.getMap();
            for (String key : params.keySet()) {
                if (!opportunityFieldMap.containsKey(key)) {
                    continue;
                }

                if (opportunityFieldMap.get(key).getDescribe().getType() == Schema.DisplayType.Date) {
                    opp.put(key, Date.valueOf(params.get(key)));
                } else {
                    opp.put(key, params.get(key));
                }
            }
            update opp;
            if (wizardType != WIZARD_TYPE_DOWNGRADE && !isInline) {
                updateQuotes(opp);
            }
        } catch(Exception e) {
            AquivaHelper.throwAuraException(e);
        }

        IS_IN_DOWNGRADE_PROCESS_FORM = false;
        return opp.Id;
    }

    private static void updateQuotes(Opportunity opty) {

        Map<Id, Quote> updatedQuotesMap = new Map<Id, Quote>();

        Feature_Toggle__c featureToggle = Feature_Toggle__c.getInstance();

        List<Quote> allQuotes = (List<Quote>) new QuoteSelector()
            .selectorQuotesAndQlisForCloseWizardByOpportunityId(opty.Id)
            .executeQuery();

        Boolean isChangeOptyClose = false;
        for (Quote q : allquotes) {
            if (OpportunityHelper.checkIsChangeOrderOrMigrationOpty(q.Opportunity.Name, q.Opportunity.Parent_Order__c) && q.Opportunity.Id == opty.Id) {
                isChangeOptyClose = true;
                break;
            }
        }

        Boolean isRenewalOptyWithoutChanges = OpportunityHelper.isRenewalOptyWithoutChanges(
            opty,
            allquotes
        );

        List<Quote> quoteList = QuoteHelper.filterProservQuotes(allquotes, false);
        for (Quote q : quoteList) {

            Boolean isQuoteChanged = false;

            Boolean isNeedToSetQuoteInvalid = !isRenewalOptyWithoutChanges
                                                && QuoteHelper.isNeedSetQuoteInvalid(q, new List<Opportunity>{opty})
                                                && !q.Quote_is_Invalid__c;

            if(isNeedToSetQuoteInvalid) {
                q.Quote_is_Invalid__c = true;
                isQuoteChanged = true;
            }

            Boolean isNeedToSetPresentedStatus = q.isPrimary__c
                && !(q.Status == QuoteHelper.QUOTE_STATUS_ACTIVE && q.QuoteType__c == QuoteHelper.QUOTE_TYPE_AGREEMENT)
                && q.Opportunity.Type == OpportunityHelper.OPPORTUNITY_TYPE_EX_BUSINESS
                && QuoteHelper.isExistingBusiness(q)
                && (q.RecordTypeId == QuoteHelper.RT_ID_SALES || q.RecordTypeId == QuoteHelper.RT_ID_BILLING);

            if (featureToggle.ModifiedCloseOpportunityFlow__c
                && isNeedToSetPresentedStatus
                && q.OpportunityId == opty.Id
                && q.QuoteType__c == QuoteHelper.QUOTE_TYPE_QUOTE
                && q.Opportunity.ConfirmAndClose__c
            ) {
                q.Status = QuoteHelper.QUOTE_STATUS_PRESENTED;
                isQuoteChanged = true;
            }

            if(isQuoteChanged) {
                updatedQuotesMap.put(q.Id, q);
            }
        }

        if(!updatedQuotesMap.isEmpty()) {
            UpdateSObjectsWithoutSharing updater = new UpdateSObjectsWithoutSharing();
            updater.updateWithoutSharing(updatedQuotesMap.values());
        }
    }

    @AuraEnabled
    public static Opportunity getOpportunityCloseWizardData(Id opportunityId) {
        Opportunity opp;
        try {
            opp = OpportunityHelper.getOpportunityCloseWizardValues(opportunityId);
        } catch(Exception e) {
            AquivaHelper.throwAuraException(e);
        }

        return opp;
    }

    @AuraEnabled
    public static Id uncheckConfirmAndClose(Id opportunityId) {

        if(opportunityId == null) {
            return null;
        }

        Feature_Toggle__c featureToggle = Feature_Toggle__c.getInstance();

        if(featureToggle.ModifiedCloseOpportunityFlow__c) {

            try {
                update new Opportunity(
                    Id = opportunityId,
                    ConfirmAndClose__c = false
                );
            } catch(Exception e) {
                AquivaHelper.throwAuraException(e);
            }
        }

        return opportunityId;
    }

    private without sharing class UpdateSObjectsWithoutSharing {
        public void updateWithoutSharing(List<SObject> records) {
            update records;
        }
    }
}