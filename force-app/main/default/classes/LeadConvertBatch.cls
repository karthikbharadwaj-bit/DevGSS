public class LeadConvertBatch implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.stateful {
    public final String Query;
    public final String gatingQuery;
    public List<String> lstAccountIds = new List<String>();
    public List<String> brandNames = new List<String>();

    public LeadConvertBatch() {
        String LeanDataUserId = System.Label.LeanDataUserId;
        String nonAvayaUsers = System.Label.Non_Avaya_Users;
        String leanDataUsers = System.Label.Pb_Custom_label;// 0-Events User,1-Routing Review User,2-LeanData Queue, 3- Do Not Contact VAR
        String [] listUsersLean = leanDataUsers.split(',');
        //CMR-306098
        Gating_Process_Stage__c processStage = Gating_Process_Stage__c.getInstance();
        if (processStage != null && processStage.Bypass_Gating_Process_Stage__c == false && processStage.Bypass_Convert_Batch__c == false) {
            gatingQuery = 'AND (Systems_Process_Stage__c=\'Route complete\' OR SystemsProcessBypass__c=\'Bypass Routing\') AND OwnerId!=\'' + listUsersLean[3] + '\' ';
        } else {
            gatingQuery = ' ';
        }
        //CMR-272228
        List<Community_Details__mdt> lstComm = [SELECT Id, Brand_Name__c, IsStrategicAllowedforBrand__c FROM Community_Details__mdt where IsStrategicAllowedforBrand__c = true];
        for (Community_Details__mdt com : lstComm) {
            if (com.Brand_Name__c != null) {
                List<String> temp = new List<String>();
                for (String names : com.Brand_Name__c.split(';')) {
                    temp.add(names);
                }
                if (temp.size() > 0) {
                    brandNames.addAll(temp);
                } else {
                    brandNames.add(com.Brand_Name__c);
                }
            }
        }

        //Added Is_RFP_Needed__c and Brand Filter - Rainbow Office for ALE
        //Removed Is_RFP_Needed__c for ALE BZS-4808
        Query = 'Select Id, Partner_Type__c,BusinessIdentity__c, Settlement_type__c, Status, Name, FirstName, LastName, Title, Company, Email, Phone, Street, City,City__c, State__c, PostalCode, Country__c, Number_of_Users__c, '
            + 'Lead_Brand_Name__c, Lead_Tier_Name__c, Partner_Lead_Source__c, NumberOfEmployees__c, Number_of_Locations__c, Industry, Estimated_Close_Date__c, '
            + 'How_did_you_acquire_this_Lead__c, Description, website, Existing_Solution_Provider__c, Prompting_Change__c, Partner_Lead_Owner__r.Name, '
            + 'Deal_Registration__r.Name, Partner_Account__r.Name, Partner_Account__r.Partner_ID__c, Partner_Contact__r.Name, Competitors__c, '
            + 'Decision_Maker__c, Currently_in_a_contract__c, Project_budget__c, Partner_Lead_Owner__c, Deal_Registration__c, Partner_Account__c, '
            + 'Partner_Contact__c, Inside_Sales_Rep__c, Inside_Sales_Rep__r.Name, Sales_Notes__c, IsAvayaConverted__c, Avaya_Cloud_Specialist__c, '
            + 'RC_Overlay__c, Partner_Account__r.Partner_Country__c, Owner.Name, OwnerId, Portal_Cloud_Specialist__c, Portal_Cloud_Specialist__r.Name, '
            + 'Timezone__c, LeadSource, Country, State, Street_2__c, Phone_Ext__c, Account_Number__c, Sector__c, Preferred_Language__c, '
            + 'Zip_Code__c, NumberOfEmployees, Effective_No_of_Employees_Range__c, LeadPartnerID__c, CurrencyIsoCode, Installation_Service_Provider__c '
            + 'FROM Lead '
            + 'WHERE ('
            + '((Lead_Brand_Name__c = \'Rainbow Office\' OR (Lead_Brand_Name__c = \'Unify Office\' AND Country IN (\'United States\',\'Australia\',\'Canada\'))) AND SM_Employees__c <= 100) '
            + 'OR (Lead_Brand_Name__c = \'Unify Office\' AND Country NOT IN (\'United States\',\'Australia\',\'Canada\')) '
            + 'OR (Lead_Brand_Name__c = \'Vodafone Business with RingCentral\') '
            + 'OR (Lead_Brand_Name__c = \'Avaya Cloud Office\' AND SM_Employees__c <= 100) '
            + ') '
            + 'AND OwnerId != \'' + LeanDataUserId + '\' '
            + 'AND Avaya_Partnership_Lead__c = true '
            + 'AND isConverted = false '
            + 'AND Status IN (\'1.5 Call Out\',\'1. New\',\'2. Contacted\') '
            + gatingQuery //CMR-306098
            + 'AND CreatedById != \'' + nonAvayaUsers + '\' '
            + 'AND ((Lead_Brand_Name__c in :brandNames AND Strategic_Partner_RC_Owner__c!=null) OR Strategic_Partner_RC_Owner__c=null) ';//CMR-272228

        System.debug('LeadConvertBatch query --> ' + Query);
    }
    public Database.QueryLocator start(Database.BatchableContext BC) {
        System.debug('LeadConvertBatch query from start --> ' + Query);
        return Database.getQueryLocator(Query);
    }
    public void execute(Database.BatchableContext BC, List<sObject> objLst) {
        List<Lead> leadList = new List<Lead>();
        List<String> countriesForUOCondition = new List<String>{'United States', 'Australia', 'Canada'};

        for (Lead ld : (List<Lead>) objLst) {
            if (ld.NumberOfEmployees__c != null 
                && ld.Lead_Brand_Name__c == OpportunityHelper.BRAND_ATOS 
                && !countriesForUOCondition.contains(ld.Country)
            ) {
                String numEmployees = ld.NumberOfEmployees__c;
                List<String> parts = numEmployees.split('-');
                if (parts.size() == 2 && parts[1].isNumeric()) {
                    Integer upperLimit = Integer.valueOf(parts[1]);
                    if (upperLimit <= 100) {
                        leadList.add(ld);
                    }
                }
            } else {
                leadList.add(ld);
            }
        }
        
        Map<Id, Lead> mapAccIdsToLeads = new Map<Id, Lead>();
        for (Lead eachLead : leadList) {
            PartnerDealRegistrationUtil.PartnerLeadConvertResult result = PartnerDealRegistrationUtil.convertPartnerLead(eachLead, true);
        }
        //Skip screening
        List<String> skipScreeningNames = new List<String>();
        if (system.label.DPS_Skip_Account != null && system.label.DPS_Skip_Account != '') {
            skipScreeningNames = system.label.DPS_Skip_Account.split(';');
        }
        for (Lead l : [Select ConvertedAccountId, ConvertedAccount.Name, ConvertedAccount.CreatedById from Lead where Id in :leadList]) {
            if (l.ConvertedAccountId != null) {
                mapAccIdsToLeads.put(l.ConvertedAccountId, l);
            }
        }
        if (mapAccIdsToLeads != null && mapAccIdsToLeads.size() > 0) {
            for (Id accId : mapAccIdsToLeads.keySet()) {
                if (!(system.label.DPS_Skip_User != '' && mapAccIdsToLeads.get(accId).ConvertedAccount.CreatedById == system.label.DPS_Skip_User
                    && skipScreeningNames != null && skipScreeningNames.contains(mapAccIdsToLeads.get(accId).ConvertedAccount.Name))) {
                    lstAccountIds.add(accId);
                }
            }
        }
    }

    public void finish(Database.BatchableContext BC) {
        if (lstAccountIds.size() > 0) {
            system.enqueueJob(new DPSQueueableJob(lstAccountIds, null, null, true));
        }
    }
}