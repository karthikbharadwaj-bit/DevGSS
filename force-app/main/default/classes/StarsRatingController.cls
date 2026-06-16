public with sharing class StarsRatingController {
    private Account acc;
    public Boolean isLightning { get;set; }
    public String modifiedDate { get;set; }
    public String numberFields { get;set; }
    public String recordId { get;set; }

    @testVisible private static UpsellInsightsProductUsageData.IUpsellInsightsProductUsageData 
        upsellInsightsProductUsageDataInstance = new UpsellInsightsProductUsageData();

    public StarsRatingController(ApexPages.StandardController stdController) {
        this.acc = (Account)stdController.getRecord();
        this.isLightning = UserInfo.getUiThemeDisplayed().equalsIgnoreCase('Theme4d');
        this.recordId = acc.Id;
        setFieldsValue(getUpsellModel());
    }

    @TestVisible
    private Upsell_Model__c getUpsellModel() {
        List<Upsell_Model__c> upsells = [
                                        SELECT cc_upsell_score__c, total_upsell_score__c,
                                                tf_upsell_score__c, dl_upsell_score__c, 
                                                LM_Upsell_Score__c, LastModifiedDate
                                        FROM Upsell_Model__c 
                                        WHERE UpsellAccount__c =: acc.Id 
                                        ORDER BY LastModifiedDate DESC
                                        LIMIT 1
                                        ];
        if (!upsells.isEmpty()) {
            return upsells.get(0);
        }
        return null;
    }

    @TestVisible
    private void setFieldsValue(Upsell_Model__c upsell) {
        if (upsell != null) {
            this.modifiedDate = upsell.LastModifiedDate.format();            
            this.numberFields = String.valueOf(upsell.total_upsell_score__c == null 
                                                || upsell.total_upsell_score__c > 5
                                                || upsell.total_upsell_score__c < 0
                                                ? 0 
                                                : upsell.total_upsell_score__c) + ';' +
                                String.valueOf(upsell.cc_upsell_score__c == null 
                                                || upsell.cc_upsell_score__c > 5
                                                || upsell.cc_upsell_score__c < 0
                                                ? 0 
                                                : upsell.cc_upsell_score__c) + ';' +
                                String.valueOf(upsell.tf_upsell_score__c == null 
                                                || upsell.tf_upsell_score__c > 5
                                                || upsell.tf_upsell_score__c < 0
                                                ? 0 
                                                : upsell.tf_upsell_score__c) + ';' +
                                String.valueOf(upsell.dl_upsell_score__c == null 
                                                || upsell.dl_upsell_score__c > 5
                                                || upsell.dl_upsell_score__c < 0
                                                ? 0 
                                                : upsell.dl_upsell_score__c) + ';' +
                                String.valueOf(upsell.LM_Upsell_Score__c == null 
                                                || upsell.LM_Upsell_Score__c > 5
                                                || upsell.LM_Upsell_Score__c < 0
                                                ? 0 
                                                : upsell.LM_Upsell_Score__c);
        } else {
            List<Upsell_Insights_Product_Usage__c> upInsights = [SELECT
                                                           LastModifiedDate
                                                           FROM Upsell_Insights_Product_Usage__c
                                                           WHERE Account__c =: acc.Id
                                                           ORDER BY CreatedDate
                                                           DESC LIMIT 1];
            if(upInsights.size() > 0)
            {
                this.modifiedDate = upInsights[0].LastModifiedDate.format();
            } else {
                this.modifiedDate = '-';
            }
            
            this.numberFields = '0;0;0;0';
        }
    }

    @AuraEnabled(cacheable=true)
    public static Map<String, String> getFieldValues(String upsellId){
        Map<String, String> fieldValues = new Map<String, String>();
        List<String> upsellFields = new List<String>{'cc_current_plan__c', 'cc_current_seats__c', 
                                                    'cc_current_config_seats__c', 'cc_current_price_per_seat__c', 
                                                    'cc_current_seat_mrr__c', 'cc_current_bundle__c',
                                                    'cc_current_bundle_mrs__c', 'cc_current_billed_min_cost__c', 
                                                    'cc_current_bundle_total__c', 'cc_prop_plan__c',
                                                    'cc_prop_seats__c', 'cc_prop_config_seats__c',
                                                    'cc_prop_price_per_seat__c', 'cc_prop_seat_mrr__c',
                                                    'cc_prop_bundle__c', 'cc_prop_bundle_mrs__c',
                                                    'cc_prop_billed_min_cost__c', 'cc_prop_bundle_total__c', 'NULL',
                                                    'cc_delta_incontact_seats__c', 'NULL', 
                                                    'cc_delta_price_per_seat__c',
                                                    'cc_delta_seat_mrr__c', 'cc_delta_bundle_min__c',
                                                    'cc_delta_bundle_mrr__c', 'cc_delta_min_overage_charge__c',
                                                    'cc_delta_bundle_total__c', 'tf_current_bundle__c', 
                                                    'tf_current_cost__c', 'tf_current_overage__c', 
                                                    'tf_current_total__c', 'tf_prop_bundle__c', 
                                                    'tf_prop_cost__c', 'tf_prop_overage__c', 'tf_prop_total__c',
                                                    'tf_delta_bundle__c', 'tf_delta_cost__c',
                                                    'tf_delta_overage__c', 'tf_delta_total__c',
                                                    'LM_Current_Edition__c', 'LM_Current_Plan_MRR__c', 
                                                    'LM_Current_Licenses__c', 'LM_Current_MRR__c',
                                                    'LM_Proposed_Edition__c', 'LM_Proposed_Plan_MRR__c', 
                                                    'LM_Proposed_Licenses__c', 'LM_Proposed_MRR__c', 
                                                    'NULL', 'LM_Delta_Plan_MRR__c', 'LM_Delta_Licenses__c', 
                                                    'LM_Delta_MRR__c', 
                                                    'cc_twelve_month_potential__c', 'tf_twelve_month_potential__c', 
                                                    'LM_Twelve_Month_Potential__c'};
        String tempQuery = 'SELECT ';
        for (String str : upsellFields) {
            if (str != 'NULL') {
                tempQuery += str + ', ';
            }
        }
        String query = tempQuery.left(tempQuery.length() - 2);
        query += ' FROM Upsell_Model__c ' +
                    'WHERE UpsellAccount__c = \'' + String.escapeSingleQuotes(upsellId) + '\'' +
                    'ORDER BY LastModifiedDate DESC ' +
                    'LIMIT 1';
        List<Upsell_Model__c> upsells = (List<Upsell_Model__c>)Database.query(query);
        if (!upsells.isEmpty()) {
            Map<String, Object> fieldsToValue = upsells.get(0).getPopulatedFieldsAsMap();
            for (Integer i = 0; i < upsellFields.size(); i++) {
                if (upsellFields.get(i) == 'NULL') {
                    fieldValues.put(String.valueOf(i), '');
                } else if (fieldsToValue.get(upsellFields.get(i)) != null) {
                        fieldValues.put(String.valueOf(i),
                                        String.valueOf((isCurrency(upsellFields.get(i))? '$' : '') 
                                                        + fieldsToValue.get(upsellFields.get(i))));
                } else {
                    fieldValues.put(String.valueOf(i), '');
                }
            }
            return fieldValues;
        }
        return null;
    }

    @TestVisible
    private static Boolean isCurrency(String fieldName) {
        return String.valueOf(((SObject)Type.forName('Upsell_Model__c').newInstance())
                                .getSObjectType()
                                .getDescribe()
                                .fields
                                .getMap()
                                .get(fieldName)
                                .getDescribe()
                                .getType())
                                .equalsIgnoreCase('CURRENCY');
    }

    @AuraEnabled
    public static List<Upsell_Insights_Product_Usage__c> getUpsellInsightsProductUsages(Id accountId){
        return upsellInsightsProductUsageDataInstance.getUpsellInsightsProductUsages(accountId);
    }
}