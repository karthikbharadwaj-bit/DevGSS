public without sharing class Queueable_DG_DFR_Class {
    
    public static boolean isQueueuableLimitsReached() {
        return Limits.getQueueableJobs() == Limits.getLimitQueueableJobs();
    }

    public class DFR_Contacts implements Queueable {
        List<Contact> listNewContacts;
        Map<Id, Contact> mapOldContacts;
        public DFR_Contacts(list<Contact> listNewContacts, map<Id, Contact> mapOldContacts) {
            this.listNewContacts = listNewContacts;
            this.mapOldContacts = mapOldContacts;
        }
        public void execute(QueueableContext context) {
            if (mapOldContacts != null) {
                if (listNewContacts.size() > 50) {
                    List<Contact> contactsToProcess = new List<Contact>();
                    List<Contact> contactsForNextProcess = new List<Contact>();
                    Map<Id, Contact> mapToProcess = new Map<Id, Contact>();
                    Map<Id, Contact> mapForNextProcess = new Map<Id, Contact>();
                    for (Integer i = 0; i < listNewContacts.size(); i++) {
                        if (i < 50) {
                            contactsToProcess.add(listNewContacts[i]);
                            mapToProcess.put(listNewContacts[i].Id, mapOldContacts.get(listNewContacts[i].Id));
                        } else {
                            contactsForNextProcess.add(listNewContacts[i]);
                            mapForNextProcess.put(listNewContacts[i].Id, mapOldContacts.get(listNewContacts[i].Id));
                        }
                    }
                    if (!Test.isRunningTest()) {
                        if (!contactsToProcess.isEmpty()) {
                            DG_DFR_Class.dfrContacts(contactsToProcess, mapToProcess);
                            DG_DFR_Class.DFR_ChangeContactOwner(contactsToProcess, mapToProcess);
                        }
                        if (!contactsForNextProcess.isEmpty()) {
                            System.enqueueJob(
                            new Queueable_DG_DFR_Class.DFR_Contacts(contactsForNextProcess, mapForNextProcess)
                            );
                        }
                    } else {
                        DG_DFR_Class.dfrContacts(listNewContacts, mapOldContacts);
                        DG_DFR_Class.DFR_ChangeContactOwner(listNewContacts, mapOldContacts);
                    }
                } else {
                    DG_DFR_Class.dfrContacts(listNewContacts, mapOldContacts);
                    DG_DFR_Class.DFR_ChangeContactOwner(listNewContacts, mapOldContacts);
                }
            } else {
                if (listNewContacts.size() > 50) {
                    List<Contact> contactsToProcess = new List<Contact>();
                    List<Contact> contactsForNextProcess = new List<Contact>();
                    for (Integer i = 0; i < listNewContacts.size(); i++) {
                        if (i < 50) {
                            contactsToProcess.add(listNewContacts[i]);
                        } else {
                            contactsForNextProcess.add(listNewContacts[i]);
                        }
                    }
                    if (!Test.isRunningTest()) {
                        if (!contactsToProcess.isEmpty()) {
                            DG_DFR_Class.dfrContactCreation(contactsToProcess);
                        }
                        if (!contactsForNextProcess.isEmpty()) {
                            System.enqueueJob(
                            new Queueable_DG_DFR_Class.DFR_Contacts(contactsForNextProcess, null)
                            );
                        }
                    } else {
                        DG_DFR_Class.dfrContactCreation(listNewContacts);
                    }
                } else {
                    DG_DFR_Class.dfrContactCreation(listNewContacts);
                }
            }
        }
    }

    public class DFR_AddOpportunity implements Queueable {
        List<Opportunity> opps;
        Boolean isLeadConvertExecution = false;
        public DFR_AddOpportunity(List<Opportunity> opps, Boolean isLeadConvertExecution) {
            this.opps = opps;
            this.isLeadConvertExecution = isLeadConvertExecution;
        }
        public void execute(QueueableContext context) {
            if (isLeadConvertExecution) {
                Set<Id> contactIds = new Set<Id>();
                List<Demand_Funnel__c> dfrs = new List<Demand_Funnel__c>();
                List<Demand_Funnel__c> dfrsToUpsert = new List<Demand_Funnel__c>();

                for (Opportunity opp : opps) {
                    if (
                        opp.Primary_Opportunity_Contact__c != null &&
                        !contactIds.contains(opp.Primary_Opportunity_Contact__c)
                    ) {
                        contactIds.add(opp.Primary_Opportunity_Contact__c);
                    }
                }

                dfrs = (List<Demand_Funnel__c>) new DemandFunnelSelector()
                    .selectDFRsForAddOpportunity(contactIds)
                    .executeQuery();
                    
                dfrsToUpsert = DG_DFR_Class_Helper.DFRPipelineRecalculation(dfrs, opps);
                upsert dfrsToUpsert;
            } else {
                DG_DFR_Class.DFR_AddOpportunity(opps);
            }
        }
    } 

    public class DFR_OpportunityClosed implements Queueable {
        List<Opportunity> newOpps;
        Map<Id, Opportunity> oldOppsMap;
        public DFR_OpportunityClosed(List<Opportunity> newOpps, Map<Id, Opportunity> oldOppsMap) {
            this.newOpps = newOpps;
            this.oldOppsMap = oldOppsMap;
        }
        public void execute(QueueableContext context) {
            if (newOpps.size() > 50 || (Test.isRunningTest() && newOpps.size() > 10)) {
                List<Opportunity> oppsToProcess = new List<Opportunity>();
                List<Opportunity> oppsForNextProcess = new List<Opportunity>();
                Map<Id, Opportunity> oldOppsToProcessMap = new Map<Id, Opportunity>();
                Map<Id, Opportunity> oldOppsForNextProcessMap = new Map<Id, Opportunity>();
                for (Integer i = 0; i < newOpps.size(); i++) {
                    Opportunity oldOpportunity = oldOppsMap.get(newOpps[i].Id);
                    if (i < 50) {
                        oppsToProcess.add(newOpps[i]);
                        oldOppsToProcessMap.put(oldOpportunity.Id, oldOpportunity);
                    } else {
                        oppsForNextProcess.add(newOpps[i]);
                        oldOppsForNextProcessMap.put(oldOpportunity.Id, oldOpportunity);
                    }
                }
                if (!Test.isRunningTest()) {
                    DG_DFR_Class.DFR_OpportunityClosed(oppsToProcess, oldOppsToProcessMap);
                    DG_DFR_Class.DFR_OpportunityOwnerChange(oppsToProcess, oldOppsToProcessMap);
                    System.enqueueJob(
                        new Queueable_DG_DFR_Class.DFR_OpportunityClosed(oppsForNextProcess, oldOppsForNextProcessMap)
                    );
                } else {
                    DG_DFR_Class.DFR_OpportunityClosed(newOpps, oldOppsMap);
                    DG_DFR_Class.DFR_OpportunityOwnerChange(newOpps, oldOppsMap);
                }
            } else {
                DG_DFR_Class.DFR_OpportunityClosed(newOpps, oldOppsMap);
                DG_DFR_Class.DFR_OpportunityOwnerChange(newOpps, oldOppsMap);
            }
        }
    } 
}