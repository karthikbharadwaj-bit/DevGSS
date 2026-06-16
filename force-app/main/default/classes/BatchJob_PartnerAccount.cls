global class BatchJob_PartnerAccount extends BatchJobSvc {

    global override String getBatchJobClassName(){
        return 'BatchJob_PartnerAccount'; 
    }

    global override void bypassTriggers(Boolean bypass){
        TriggerHandler.BY_PASS_ACCOUNT_ON_AFTER = bypass;
        TriggerHandler.BY_PASS_ACCOUNT_ON_BEFORE = bypass;
        TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE = bypass;  
        TriggerHandler.BY_PASS_PARTNER_ACCOUNT_ON_AFTER = bypass;
        TriggerHandler.BY_PASS_PARTNER_ACCOUNT_ON_BEFORE = bypass;
        TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT = bypass;
        TriggerHandler.BY_PASS_LEAD_UPDATE = bypass;
        TriggerHandler.BY_PASS_LEAD_UPDATE_ON_INSERT = bypass;
        TriggerHandler.BY_PASS_OPPORTUNITY_ON_UPDATE = bypass;
        if(bypass){
            Triggers.switchOff();
        } else {
            Triggers.switchOn();
        }
    }

    global Database.QueryLocator start(Database.BatchableContext BC) {
        String query = 'SELECT Id, Partner_ID__c, Master_Agent_Channel_Manager__c, FoundDuplicateAccountIds__c, Type ' +
            'FROM Account ' +
            'WHERE Type = \'Partner\' AND Partner_ID__c != null' + getLimitToApply();
        return Database.getQueryLocator(query);
    }

    global override void performChunkExecution(List<sObject> scope){
        List<Account> accsToUpdate = new List<Account>();
        List<Opportunity> oppsToUpdate = new List<Opportunity>();
        List<Lead> leadsToUpdate = new List<Lead>();

        Set<Id> duplicateIds = new Set<Id>();
        Set<String> accPartnerId = new Set<String>();

        Map<Id, Account> idToPartnerAcc = new Map<Id, Account>();
        Map<Id, Account> uniqueAccs = new Map<Id, Account>((List<Account>) scope);

        for(Account acc : (List<Account>) scope) {
            if(acc.FoundDuplicateAccountIds__c != null) {
                duplicateIds.addAll(new Set<Id>((List<Id>) acc.FoundDuplicateAccountIds__c.split(',')));
            }
        }
        

        uniqueAccs.putAll([
                    SELECT Id, Partner_ID__c, Master_Agent_Channel_Manager__c, FoundDuplicateAccountIds__c, Type 
                    FROM Account
                    WHERE Type = 'Partner'
                        AND Id IN :duplicateIds AND Partner_ID__c != null
                    ]);
        
        for(Account acc : uniqueAccs.values()) {
            accPartnerId.add(acc.Partner_ID__c);
        }
        

        String previousPartnerId = '';

        //<partnerId, List of accounts for that partnerId>
        Map<String, List<Account>> partnerCustomerAccountMap = new Map<String, List<Account>>();
        previousPartnerId = '';
        for(Account custAccount : [
            SELECT Id, MRR__c, Total_DLs__c, No_of_InContact_Seats__c, RC_Account_Status__c, 
                Partner_ID__c, Master_Agent_Channel_Manager__c,
                (SELECT Id, Name, Service_Type__c, Account__c, Total_DLs__c FROM Service_Accounts__r)
            FROM Account
            WHERE Type = 'Customer' AND Partner_ID__c IN :accPartnerId
            ORDER BY Partner_Id__c]){
            if(previousPartnerId != custAccount.Partner_Id__c){
                previousPartnerId = custAccount.Partner_Id__c;
                List<Account> newListForPartner = new List<Account>(); 
                newListForPartner.add(custAccount);
                partnerCustomerAccountMap.put(custAccount.Partner_Id__c, newListForPartner);
            } else {
                partnerCustomerAccountMap.get(custAccount.Partner_Id__c).add(custAccount); 
            }
        }

        //<partnerId, List of Opportunities for that partnerId>
        Map<String, List<Opportunity>> partnerOpportunityMap = new Map<String, List<Opportunity>>();
        previousPartnerId = '';
        for(Opportunity partnerOppty : [
            SELECT Id, StageName, Amount, Forecasted_Users__c, Partner_ID__c, Master_Agent_Channel_Manager__c, 
                Forecast_Contact_Center_Users__c 
            FROM Opportunity
            WHERE Partner_ID__c IN :accPartnerId
            ORDER BY Partner_Id__c]){
            if(previousPartnerId != partnerOppty.Partner_Id__c){
                previousPartnerId = partnerOppty.Partner_Id__c;
                List<Opportunity> newListForPartner = new List<Opportunity>(); 
                newListForPartner.add(partnerOppty);
                partnerOpportunityMap.put(partnerOppty.Partner_Id__c, newListForPartner);
            } else {
                partnerOpportunityMap.get(partnerOppty.Partner_Id__c).add(partnerOppty); 
            }
        }

        //<partnerId, List of Leads for that partnerId>
        Map<String, List<Lead>> partnerLeadMap = new Map<String, List<Lead>>();
        previousPartnerId = '';
        for(Lead partnerLead : [
            SELECT Id, LeadPartnerID__c, Master_Agent_Channel_Manager__c 
            FROM Lead
            WHERE Status IN ('1. New', '1. New D', '1. New B', '1.5 Call Out', '2. Contacted')
                AND LeadPartnerID__c IN :accPartnerId
                AND IsConverted = false
            ORDER BY LeadPartnerID__c]){

            if(previousPartnerId != partnerLead.LeadPartnerID__c){
                previousPartnerId = partnerLead.LeadPartnerID__c;
                List<Lead> newListForPartner = new List<Lead>(); 
                newListForPartner.add(partnerLead);
                partnerLeadMap.put(partnerLead.LeadPartnerID__c, newListForPartner);
            } else {
                partnerLeadMap.get(partnerLead.LeadPartnerID__c).add(partnerLead); 
            }
        }

        for(Account partnerAccount : uniqueAccs.values()) {
            Account accToUpdate = new Account(
                Id = partnerAccount.Id,
                Open_partner_leads__c = 0,
                Open_partner_opps__c = 0,
                Closed_Won_opps__c = 0,
                Amount_of_open_opps__c = 0,
                Forecasted_Users_of_open_opps__c = 0,
                MRR_of_current_customers__c = 0,
                DLs_of_current_customers__c = 0,
                InContact_Seats_of_current_customers__c = 0,
                FoundDuplicateAccountIds__c = partnerAccount.FoundDuplicateAccountIds__c,
                Forecast_Contact_Center_Users__c = 0,
                Type = partnerAccount.Type
            );

            List<Account> customerAccounts = partnerCustomerAccountMap.get(partnerAccount.Partner_ID__c);
            if(customerAccounts != null) {
                for(Account customerAccount : customerAccounts){
                    List<Package__c> packages = customerAccount.Service_Accounts__r;
                    Map<Id, Package__c> packageToProcessMap = PackageHelper.filterPackagesByService(packages);
                    Package__c packageToProcess = packageToProcessMap.get(customerAccount.Id);
                    if(customerAccount.RC_Account_Status__c == 'Paid') {
                        accToUpdate.MRR_of_current_customers__c += customerAccount.MRR__c == null 
                            ? 0 
                            : customerAccount.MRR__c;
                        if (packageToProcess?.Service_Type__c == AccountHelper.SERVICE_TYPE_OFFICE) {
                            accToUpdate.DLs_of_current_customers__c += NumberHelper.toNumber(packageToProcess?.Total_DLs__c);
                        }
                        accToUpdate.InContact_Seats_of_current_customers__c += customerAccount.No_of_InContact_Seats__c == null
                            ? 0
                            : customerAccount.No_of_InContact_Seats__c;
                    }

                    if(customerAccount.Master_Agent_Channel_Manager__c != partnerAccount.Master_Agent_Channel_Manager__c) {
                        customerAccount.Master_Agent_Channel_Manager__c = partnerAccount.Master_Agent_Channel_Manager__c;
                        accsToUpdate.add(customerAccount);
                    }
                }
            }

            List<Opportunity> partnerOpportunities = partnerOpportunityMap.get(partnerAccount.Partner_ID__c);
            if(partnerOpportunities != null) {
                for(Opportunity partnerOpportunity : partnerOpportunities){
                    if(OpportunityHelper.isCLosed(partnerOpportunity.StageName)) { 
                        accToUpdate.Closed_Won_opps__c++;
                    } else {
                        if (partnerOpportunity.StageName != OpportunityHelper.STAGE_NAME_DOWNGRADED) {
                            accToUpdate.Open_partner_opps__c++;
                            
                            accToUpdate.Forecast_Contact_Center_Users__c += partnerOpportunity.Forecast_Contact_Center_Users__c == null
                            ? 0
                            : partnerOpportunity.Forecast_Contact_Center_Users__c;
                            
                            accToUpdate.Amount_of_open_opps__c += partnerOpportunity.Amount == null 
                            ? 0 
                            : partnerOpportunity.Amount;
                            
                            accToUpdate.Forecasted_Users_of_open_opps__c += partnerOpportunity.Forecasted_Users__c == null 
                            ? 0 
                            : partnerOpportunity.Forecasted_Users__c;
                        }
                    }

                    if(partnerOpportunity.Master_Agent_Channel_Manager__c != partnerAccount.Master_Agent_Channel_Manager__c) {
                        partnerOpportunity.Master_Agent_Channel_Manager__c = partnerAccount.Master_Agent_Channel_Manager__c;
                        oppsToUpdate.add(partnerOpportunity);
                    }
                }
            }

            List<Lead> partnerLeads = partnerLeadMap.get(partnerAccount.Partner_ID__c);
            if(partnerLeads != null) {
                for(Lead partnerLead : partnerLeads){
                    accToUpdate.Open_partner_leads__c++;

                    if(partnerLead.Master_Agent_Channel_Manager__c != partnerAccount.Master_Agent_Channel_Manager__c) {
                        partnerLead.Master_Agent_Channel_Manager__c = partnerAccount.Master_Agent_Channel_Manager__c;
                        leadsToUpdate.add(partnerLead);
                    }
                }
            }

            idToPartnerAcc.put(accToUpdate.Id, accToUpdate);
        }

        for(Id accId : idToPartnerAcc.keySet()) {
            Account acc = idToPartnerAcc.get(accId);

            if(acc.FoundDuplicateAccountIds__c != null && acc.Type == 'Partner') {
                Decimal aggregatedLeads = acc.Open_partner_leads__c == null
                    ? 0 
                    : acc.Open_partner_leads__c;
                Decimal aggregatedOpenOpps = acc.Open_partner_opps__c == null
                    ? 0 
                    : acc.Open_partner_opps__c;
                Decimal aggregatedCloseOpps = acc.Closed_Won_opps__c == null
                    ? 0 
                    : acc.Closed_Won_opps__c;
                Decimal aggregatedAmount = acc.Amount_of_open_opps__c == null
                    ? 0 
                    : acc.Amount_of_open_opps__c;
                Decimal aggregatedUsers = acc.Forecasted_Users_of_open_opps__c == null
                    ? 0 
                    : acc.Forecasted_Users_of_open_opps__c;
                Decimal aggregatedMRR = acc.MRR_of_current_customers__c == null
                    ? 0 
                    : acc.MRR_of_current_customers__c;
                Decimal aggregatedDL = acc.DLs_of_current_customers__c == null
                    ? 0 
                    : acc.DLs_of_current_customers__c;
                Decimal aggregatedSeats = acc.InContact_Seats_of_current_customers__c == null
                    ? 0 
                    : acc.InContact_Seats_of_current_customers__c;
                Decimal aggregatedForecastedCCUsers = acc.Forecast_Contact_Center_Users__c == null
                    ? 0 
                    : acc.Forecast_Contact_Center_Users__c;

                for(Id dupId : (List<Id>) acc.FoundDuplicateAccountIds__c.split(',')) {
                    if(dupId != acc.Id && idToPartnerAcc.get(dupId) != null) {
                        Account dup = idToPartnerAcc.get(dupId);

                        aggregatedLeads += dup.Open_partner_leads__c == null
                            ? 0 
                            : dup.Open_partner_leads__c;
                        aggregatedOpenOpps += dup.Open_partner_opps__c == null
                            ? 0 
                            : dup.Open_partner_opps__c;
                        aggregatedCloseOpps += dup.Closed_Won_opps__c == null
                            ? 0 
                            : dup.Closed_Won_opps__c;
                        aggregatedAmount += dup.Amount_of_open_opps__c == null
                            ? 0 
                            : dup.Amount_of_open_opps__c;
                        aggregatedUsers += dup.Forecasted_Users_of_open_opps__c == null
                            ? 0 
                            : dup.Forecasted_Users_of_open_opps__c;
                        aggregatedMRR += dup.MRR_of_current_customers__c == null
                            ? 0 
                            : dup.MRR_of_current_customers__c;
                        aggregatedDL += dup.DLs_of_current_customers__c == null
                            ? 0 
                            : dup.DLs_of_current_customers__c;
                        aggregatedSeats += dup.InContact_Seats_of_current_customers__c == null
                            ? 0 
                            : dup.InContact_Seats_of_current_customers__c;
                        aggregatedForecastedCCUsers += dup.Forecast_Contact_Center_Users__c == null
                            ? 0 
                            : dup.Forecast_Contact_Center_Users__c;
                    }
                }

                Account aggregatedAccToUpdate = new Account(
                    Id = acc.Id,
                    Open_partner_leads__c = aggregatedLeads,
                    Open_partner_opps__c = aggregatedOpenOpps,
                    Closed_Won_opps__c = aggregatedCloseOpps,
                    Amount_of_open_opps__c = aggregatedAmount,
                    Forecasted_Users_of_open_opps__c = aggregatedUsers,
                    MRR_of_current_customers__c = aggregatedMRR,
                    DLs_of_current_customers__c = aggregatedDL,
                    InContact_Seats_of_current_customers__c = aggregatedSeats,
                    Forecast_Contact_Center_Users__c = aggregatedForecastedCCUsers
                );
                
                accsToUpdate.add(aggregatedAccToUpdate);
            } else {
                accsToUpdate.add(acc);
            }
        }

        databaseResults.addAll(Database.update(accsToUpdate, false));
        databaseResults.addAll(Database.update(oppsToUpdate, false));
        databaseResults.addAll(Database.update(leadsToUpdate, false));

    }

    public void execute(SchedulableContext context) {
        bypassTriggers(true);
        BatchJob_PartnerAccount batchToSchedule = new BatchJob_PartnerAccount();
        Database.executeBatch(batchToSchedule, chunkSizeLimit);
    }
}