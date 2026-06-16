public with sharing class DemandFunnelTriggerHelper {
    public static final String MDT_MAPING_FIELD_BRAND_OPPORTUNITY_ACCOUNT = 'Opportunity Account';
    public static final String MDT_MAPING_FIELD_BRAND_ACCOUNT = 'Account Brand';
    public static final String MDT_MAPING_FIELD_BRAND_LEAD = 'Lead Brand';
    public static final String MDT_MAPING_FIELD_BRAND_PROSPECT_LEAD_SOURCE = 'Prospect - Lead Source';
    public static final String MDT_MAPING_FIELD_BRAND_PROSPECT_CAMPAIGN_INTENDED_COUNTRY = 'Campaign Intended Country';
    public static final String MDT_MAPING_FIELD_BRAND_SM_COUNTRY = 'SM Country';
    public static Map<Id, Opportunity> opportunityById = new Map<Id, Opportunity>();
    public static Map<Id, Lead> leadById = new Map<Id, Lead>();
    public static Map<Id, Account> accountById = new Map<Id, Account>();

    private static Map<Id, Opportunity> getOpportunityMap(Set<Id> oppIds) {
        
        if (!oppIds.isEmpty() && opportunityById.isEmpty()) {
            opportunityById.putAll((List<Opportunity>) new OpportunitySelector()
                .selectOpportunitiesForDFR(oppIds)
                .selectField(Opportunity.AccountId)
                .selectField('Account.SM_Employees__c')
                .selectField('Account.RC_Brand__c')
                .executeQuery()
            );   
        }

        return opportunityById;
    }

    private static Map<Id, Account> getAccountMap(Set<Id> accIds) {

        if (!accIds.isEmpty() && accountById.isEmpty()) {
            accountById.putAll((List<Account>) new AccountSelector()
                    .selectAccountsForDFR(new Object[]{ accIds })
                    .selectField('SM_Employees__c')
                    .selectField(Account.RC_Brand__c)
                    .executeQuery()
            );
        }

        return accountById;
    }

    private static Map<Id, Contact> getContactMap(Set<Id> contIds) {
        Map<Id, Contact> contactById = new Map<Id, Contact>();

        if (!contIds.isEmpty()) {
            contactById.putAll((List<Contact>) new ContactSelector()
                .selectContactsByIds(new Object[]{contIds})
                .selectField(Contact.AccountId)
                .executeQuery()
            );
        }

        return contactById;
    }

    private static Map<Id, Lead> getLeadMap(Set<Id> leadIds) {
        
        if (!leadIds.isEmpty() && leadById.isEmpty()) {
            leadById.putAll((List<Lead>) new LeadSelector()
                .selectLeadsForDFR(new Object[]{ leadIds })
                .selectField('SM_Employees__c')
                .selectField(Lead.ZI_CDP_Account_Id__c)
                .selectField(Lead.Lead_Brand_Name__c)
                .executeQuery()
            );
        }

        return leadById;
    }

    private static Map<Id, Campaign> getCampaignMap(Set<Id> campaignIds) {
        Map<Id, Campaign> campaignById = new Map<Id, Campaign>();

        if (!campaignIds.isEmpty()) {
            campaignById.putAll((List<Campaign>) new CampaignSelector()
                .selectCampaignsByIds(new Object[]{ campaignIds })
                .selectField(Campaign.Intended_Country__c)
                .selectField(Campaign.Intended_Product__c)
                .executeQuery()
            );
        }

        return campaignById;
    }

    public static void populateSMEmployeeField(List<Demand_Funnel__c> dfrs) {
        Set<Id> accountIdSet = new Set<Id>();
        Set<Id> opptyIdSet = new Set<Id>();
        Set<Id> leadIdSet = new Set<Id>();

        for (Demand_Funnel__c dfr : dfrs) {
            if (dfr.Account__c != null) {
                accountIdSet.add(dfr.Account__c);
            }
            if (dfr.Opportunity__c != null) {
                opptyIdSet.add(dfr.Opportunity__c);
            }
            if (dfr.Lead__c != null) {
                leadIdSet.add(dfr.Lead__c);
            }
        }

        Map<Id, Account> acctMap = getAccountMap(accountIdSet);
        Map<Id, Opportunity> oppMap = getOpportunityMap(opptyIdSet);
        Map<Id, Lead> leadMap = getLeadMap(leadIdSet);

        for (Demand_Funnel__c dfr : dfrs) {
            
            Account acc = acctMap.get(dfr.Account__c);
            Opportunity oppty = oppMap.get(dfr.Opportunity__c);
            Lead aLead = leadMap.get(dfr.Lead__c);

            if (oppty?.Account?.SM_Employees__c != null) {
                dfr.SM_Employees__c = oppty.Account.SM_Employees__c;
            } else if (acc?.SM_Employees__c != null) {
                dfr.SM_Employees__c = acc.SM_Employees__c;
            } else {
                dfr.SM_Employees__c = aLead?.SM_Employees__c;
            }
        }
    }

    private static Map<String, Map<String, String>> mappingIntededBrandMapSingleton = null;
    public static Map<String, Map<String, String>> mappingIntededBrandMap {
        get {
            if (mappingIntededBrandMapSingleton != null) {
                return mappingIntededBrandMapSingleton;
            }   

            mappingIntededBrandMapSingleton = new Map<String, Map<String, String>>{
                MDT_MAPING_FIELD_BRAND_OPPORTUNITY_ACCOUNT => new Map<String, String>(),
                MDT_MAPING_FIELD_BRAND_ACCOUNT => new Map<String, String>(),
                MDT_MAPING_FIELD_BRAND_LEAD => new Map<String, String>(),
                MDT_MAPING_FIELD_BRAND_PROSPECT_CAMPAIGN_INTENDED_COUNTRY => new Map<String, String>(),
                MDT_MAPING_FIELD_BRAND_PROSPECT_LEAD_SOURCE => new Map<String, String>(),
                MDT_MAPING_FIELD_BRAND_SM_COUNTRY => new Map<String, String>()
            };

            for (Mapping_Intended_Brand_Field__mdt mdt : Mapping_Intended_Brand_Field__mdt.getAll().values()) {
                mappingIntededBrandMapSingleton.get(mdt.masterLabel).put(mdt.Given__c, mdt.Then__c);
            }

            return mappingIntededBrandMapSingleton;
        }
    }

    public static void populateIntendedBrandField(List<Demand_Funnel__c> demandFunnelList) {
        Set<Id> opportunitiesId = new Set<Id>();
        Set<Id> accountsId = new Set<Id>();
        Set<Id> leadsId = new Set<Id>();
        Set<Id> campaignsId = new Set<Id>();

        for (Demand_Funnel__c dfr : demandFunnelList) {
            if (dfr.Opportunity__c != null) {
                opportunitiesId.add(dfr.Opportunity__c);
            }
            if (dfr.Account__c != null) {
                accountsId.add(dfr.Account__c);
            }
            if (dfr.Lead__c != null) {
                leadsId.add(dfr.Lead__c);
            }
            if (dfr.Prospect_Campaign__c != null) {
                campaignsId.add(dfr.Prospect_Campaign__c);
            }
        }

        Map<Id, Opportunity> opportunittyById = getOpportunityMap(opportunitiesId);
        Map<Id, Lead> leadById = getLeadMap(leadsId);
        Map<Id, Account> accountById = getAccountMap(accountsId);
        Map<Id, Campaign> campaignById = getCampaignMap(campaignsId);

        fillIntendedBrandField(
            demandFunnelList,
            opportunittyById,
            accountById,
            leadById,
            campaignById
        );
    }
    
    public static List<Demand_Funnel__c> getDFRsWithUpdatedIntendedBrandField(List<Demand_Funnel__c> dfrs) {
        return fillIntendedBrandField(dfrs);
    }

    public static List<Demand_Funnel__c> getDFRsWithUpdatedIntendedBrandField(Set<Id> ids) {
        return fillIntendedBrandField(getDFRListToUpdateIntendedBrand(ids));
    }

    private static List<Demand_Funnel__c> getDFRListToUpdateIntendedBrand(Set<Id> ids){
        return (List<Demand_Funnel__c>) new DemandFunnelSelector()
        .selectDFRForUpdatingIntendedBrandFieldValue(new Object[]{ids})
        .executeQuery();
    }

    private static void fillIntendedBrandField (
        List<Demand_Funnel__c> demandFunnelById,
        Map<Id, Opportunity> opportunityById,
        Map<Id, Account> accountById,
        Map<Id, Lead> leadById,
        Map<Id, Campaign> campaignById
    ) {
        for (Demand_Funnel__c dfr : demandFunnelById) {
            dfr.Intended_Brand__c = getIntendedBrandFieldValue(
                dfr,
                opportunityById.get(dfr.Opportunity__c),
                accountById.get(dfr.Account__c),
                leadById.get(dfr.Lead__c),
                campaignById.get(dfr.Prospect_Campaign__c)
            );
        }
    }

    /**
     * dfrs : The Demand Funnel records to update Intended Brand Field.
     * Return: The updated Demand Funnel records.
     */
    private static List<Demand_Funnel__c> fillIntendedBrandField (
        List<Demand_Funnel__c> dfrs
    ) {
        List<Demand_Funnel__c> dfrsToUpdate = new List<Demand_Funnel__c>();
        for (Demand_Funnel__c dfr : dfrs) {
            String oldIntendedBrandValue = dfr.Intended_Brand__C;
            dfr.Intended_Brand__c = getIntendedBrandFieldValue(dfr);
            if (oldIntendedBrandValue != dfr.Intended_Brand__c) {
                dfrsToUpdate.add(dfr);
            }
        }
        return dfrsToUpdate;
    }

    private static String getIntendedBrandFieldValue(
        Demand_Funnel__c dfr,
        Opportunity opp,
        Account acc,
        Lead l,
        Campaign cmp
    ) {
        return getIntendedBrandValue(
            opp?.Account?.RC_Brand__c,
            acc?.RC_Brand__c,
            l?.Lead_Brand_Name__c,
            dfr?.Prospect_Lead_Source__c,
            cmp?.Intended_Country__c,
            dfr.SM_Country__c
        );
    }

    private static String getIntendedBrandFieldValue(
        Demand_Funnel__c dfr
    ) {
        return getIntendedBrandValue(
            dfr.Opportunity__r?.Account?.RC_Brand__c,
            dfr.account__r?.RC_Brand__c,
            dfr.Lead__r?.Lead_Brand_Name__c,
            dfr.Prospect_Lead_Source__c,
            dfr.Prospect_Campaign__r?.Intended_Country__c,
            dfr.SM_Country__c
        );
    }

    private static String getIntendedBrandValue(
        String opportunityAccountRCBrandFieldValue,
        String accountRCBrandFieldValue,
        String leadBrandFieldValue,
        String prospectLeadSourceFieldValue,
        String prospectCampaignIntendedCountryFieldValue,
        String smCountryFieldValue
    ){
        String intendedBrandValue = 'RingCentral';

        if (opportunityAccountRCBrandFieldValue != null 
            && mappingIntededBrandMap.get(MDT_MAPING_FIELD_BRAND_OPPORTUNITY_ACCOUNT).containsKey(opportunityAccountRCBrandFieldValue)
        ) {
            intendedBrandValue = mappingIntededBrandMap.get(MDT_MAPING_FIELD_BRAND_OPPORTUNITY_ACCOUNT).get(opportunityAccountRCBrandFieldValue);
        } else if (accountRCBrandFieldValue != null 
            && mappingIntededBrandMap.get(MDT_MAPING_FIELD_BRAND_ACCOUNT).containsKey(accountRCBrandFieldValue)
        ) {
            intendedBrandValue = mappingIntededBrandMap.get(MDT_MAPING_FIELD_BRAND_ACCOUNT).get(accountRCBrandFieldValue);
        } else if (leadBrandFieldValue != null 
            && mappingIntededBrandMap.get(MDT_MAPING_FIELD_BRAND_LEAD).containsKey(leadBrandFieldValue)
        ) {
            intendedBrandValue = mappingIntededBrandMap.get(MDT_MAPING_FIELD_BRAND_LEAD).get(leadBrandFieldValue);
        } else {
            Boolean useSMCountryForSearching = true;
            Boolean useIntendedCountryForSearching = true;

            if (String.IsNotBlank(prospectLeadSourceFieldValue)) {
                Map<String, String> mapContainsIt = mappingIntededBrandMap.get(MDT_MAPING_FIELD_BRAND_PROSPECT_LEAD_SOURCE);
                for (String containsIt : mapContainsIt.keySet()) {
                    if (prospectLeadSourceFieldValue.contains(containsIt)) {
                        intendedBrandValue = mapContainsIt.get(containsIt);
                        useSMCountryForSearching = false;
                        useIntendedCountryForSearching = false;
                        break;
                    }
                }
            }

            if (useIntendedCountryForSearching && prospectCampaignIntendedCountryFieldValue != null) {
                Map<String, String> mapStartsWith = mappingIntededBrandMap.get(MDT_MAPING_FIELD_BRAND_PROSPECT_CAMPAIGN_INTENDED_COUNTRY);
                for (String startsWith : mapStartsWith.keySet()) {
                    if (prospectCampaignIntendedCountryFieldValue.startsWith(startsWith)) {
                        intendedBrandValue = mapStartsWith.get(startsWith);
                        useSMCountryForSearching = false;
                        break;
                    }
                }
            } 

            if(useSMCountryForSearching && mappingIntededBrandMap.get(MDT_MAPING_FIELD_BRAND_SM_COUNTRY).containsKey(smCountryFieldValue)) { 
                intendedBrandValue = mappingIntededBrandMap.get(MDT_MAPING_FIELD_BRAND_SM_COUNTRY).get(smCountryFieldValue);
            }
        }

        return intendedBrandValue;
    }

    public static void populateAccountField(List<Demand_Funnel__c> dfrs) {
        Set<Id> opptyIdSet = new Set<Id>();
        Set<Id> contactIdSet = new Set<Id>();
        Set<Id> leadIdSet = new Set<Id>();

        for (Demand_Funnel__c dfr : dfrs) {
            if (dfr.Opportunity__c != null) {
                opptyIdSet.add(dfr.Opportunity__c);
            }
            if (dfr.Contact__c != null) {
                contactIdSet.add(dfr.Contact__c);
            }
            if (dfr.Lead__c != null) {
                leadIdSet.add(dfr.Lead__c);
            }
        }

        Map<Id, Opportunity> opptyMap = getOpportunityMap(opptyIdSet);
        Map<Id, Contact> contactMap = getContactMap(contactIdSet);
        Map<Id, Lead> leadMap = getLeadMap(leadIdSet);

        for (Demand_Funnel__c dfr : dfrs) {

            Opportunity opp = opptyMap.get(dfr.Opportunity__c);
            Contact cont = contactMap.get(dfr.Contact__c);
            Lead ld = leadMap.get(dfr.Lead__c);
            
            if (opp?.AccountId != null) {
                dfr.Account__c = opp.AccountId;
            } else if (cont?.AccountId != null) {
                dfr.Account__c = cont.AccountId;
            } else {
                dfr.Account__c = ld?.ZI_CDP_Account_Id__c;
            }
        }
    }

}