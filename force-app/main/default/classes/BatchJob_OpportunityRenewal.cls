public with sharing class BatchJob_OpportunityRenewal implements Database.Batchable<SObject>, Database.Stateful, Schedulable {
    List<String> renewalOppAccountStatuses;
    private List<String> brandsForRenewal;
    private List<String> queryList = new List<String>();
    private Date oppCloseDateForRenewal;
    private Decimal minMRR;    

    private static List<OpportunityRenewalSettings__c> renewalOpptySettingsList {
        get {
            if (renewalOpptySettingsList == null) {
                renewalOpptySettingsList = OpportunityRenewalSettings__c.getall().values();
            }            
            return renewalOpptySettingsList;
        }
        set;
    }   

    public void execute(SchedulableContext sc) {
        Database.executeBatch(new BatchJob_OpportunityRenewal());
    }

    public BatchJob_OpportunityRenewal() {        
        for(OpportunityRenewalSettings__c settings : renewalOpptySettingsList){
            if (settings.Days_Till_Opportunity_Close_Date__c == null
                || settings.MRRThreshold__c == null
                || settings.DefaultOwnerId__c == null
                || settings.AccountStatus__c == null) {
                throw new OpportunityRenewalException('Invalid parameters');
            }

            Set<Id> proposalRenewalOpportunityOwnersId;
            Map<Id, User> receivedProposalRenewalOpportunityOwners;
            try {
                proposalRenewalOpportunityOwnersId = new Set<Id> {settings.DefaultOwnerId__c};

                receivedProposalRenewalOpportunityOwners = new Map<Id, User>(
                    (List<User>) new UserSelector()
                        .selectUsersByIdNoFields(new List<Object>{ proposalRenewalOpportunityOwnersId })
                        .withoutSelectorFieldsIncluded()
                        .setCondition('Id IN :bind0 AND IsActive = true')
                        .executeQuery()
                );
            } catch (Exception e) {
                throw new OpportunityRenewalException('Invalid one of renewal opportunity owner id');
            }

            for (Id ownerId : proposalRenewalOpportunityOwnersId) {
                if (!receivedProposalRenewalOpportunityOwners.keySet().contains(ownerId)) {
                    throw new OpportunityRenewalException('No renewal opportunity owner with id ' + ownerId);
                }
            }

            brandsForRenewal = StringHelper.safeSplit(settings.BrandsForRenewal__c, ';');
            String strBrandsForRenewal = '(\'' + String.join(brandsForRenewal, '\',\'') + '\')';
            String strStagesForRenewal = '(\'' + String.join(OpportunityHelper.OPPORTUNITY_STAGES.values(), '\',\'') + '\')';

            renewalOppAccountStatuses = StringHelper.safeSplit(settings.AccountStatus__c, ';');
            String strRenewalOppAccountStatuses = '(\'' + String.join(renewalOppAccountStatuses, '\',\'') + '\')';                      
            
            Integer daysFromToday = Integer.valueOf(settings.Days_Till_Opportunity_Close_Date__c);
            this.oppCloseDateForRenewal = Date.today().addDays(daysFromToday);
            String strOppCloseDateForRenewal = String.valueOf(this.oppCloseDateForRenewal).substring(0,10);
            
            this.minMRR = settings.MRRThreshold__c;
                        
            String query = 'SELECT Id, Name, Owner.IsActive, Owner.SegmentPicklist__c, Billing_ID__c,'
                + ' Active_Sales_Agreement__c, Active_Sales_Agreement__r.End_Date__c, '
                + ' Active_Sales_Agreement__r.Opportunity.Tier_Name__c, Active_Sales_Agreement__r.Opportunity.Brand_Name__c, '
                + ' Active_Sales_Agreement__r.Opportunity.Edition__c, '
                + ' Active_Sales_Agreement__r.Opportunity.Is_Billing_Opportunity__c, '
                + ' Active_Sales_Agreement__r.Opportunity.CW_Categories_Who_did_we_beat__c, '
                + ' Active_Sales_Agreement__r.Opportunity.CW_Categories_Who_did_we_replace__c, '
                + ' Active_Sales_Agreement__r.Opportunity.CW_Primary_Win_Reason__c, '
                + ' Active_Sales_Agreement__r.Opportunity.CW_Secondary_Win_Reason__c, '
                + ' Active_Sales_Agreement__r.Opportunity.CW_Who_did_we_beat__c, '
                + ' Active_Sales_Agreement__r.Opportunity.CW_Who_did_we_replace__c, '
                + ' Active_Sales_Agreement__r.Opportunity.CW_Win_Reason_Awards__c, '
                + ' Active_Sales_Agreement__r.Opportunity.CW_Win_Reason_Features__c, '
                + ' Active_Sales_Agreement__r.Opportunity.CW_Win_Reason_Integrations__c, '
                + ' Active_Sales_Agreement__r.Opportunity.CW_Win_Reason_Savings__c, '
                + ' Active_Sales_Agreement__r.Opportunity.Total_Contract_Value__c,'
                + ' Active_Sales_Agreement__r.Opportunity.Primary_Opportunity_Contact__c'
                + ' FROM Account '
                + ' WHERE RC_Account_Status__c IN  '+ strRenewalOppAccountStatuses
                + ' AND Active_Sales_Agreement__r.Opportunity.closedate = ' + strOppCloseDateForRenewal
                + ' AND RC_Brand__c IN ' + strBrandsForRenewal
                + ' AND MRR__c >= ' + minMRR
                + ' AND Active_Sales_Agreement__r.Opportunity.StageName IN '+strStagesForRenewal;
            this.queryList.add(query);
        }

    }

    public List<sObject> start(Database.BatchableContext bc) {
        List<sObject> scope = new List<sObject>();
        for(String query : queryList){
            scope.addAll(Database.query(query));
        }
        return scope;
        
    }

    public void execute(Database.BatchableContext bc, List<SObject> scope) {             
        List<Opportunity> opptyList = new List<Opportunity>();
        for (Account acc : (List<Account>) scope) {
            opptyList.add(OpportunityHelper.createRenewalOppty(acc, renewalOpptySettingsList[0].DefaultOwnerId__c));
        }

        Database.SaveResult[] saveResults = Database.insert(opptyList, false);
        PlatformLog.logErrors('BatchJob_OpportunityRenewal', saveResults, opptyList);
    }

    public void finish(Database.BatchableContext bc) {
        if (!Test.isRunningTest()) {
            runNextBatch();
        }
    }

    @testVisible
    private static Id runNextBatch() {
        return Database.executeBatch(new BatchJob_CloseRenewalOpportunity());
    }

    public class OpportunityRenewalException extends Exception {}
}