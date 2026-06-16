public with sharing class BatchJob_LastKeyFieldsUpdateCampaigns implements Database.Batchable<sObject>, Database.Stateful {
    public String objectToRun;
    public Boolean isPopulate;
    public DateTime startDate;
    public DateTime endDate;
    private Map<Id, String> failedRecords = new Map<Id, String>();
    public static final List<String> countryAlias = new List<String>{'Canada', 'Ca', 'Caca', 'Can', 'CanadaTgsCom', 'Canda', 'Candaa', 'Dominion du Canada', 
                                        'Dominion of Canada', 'Alabama', 'Alaska', 'America', 'Arizona', 'Arkansas', 'California', 'Colorado', 'Connecticut', 'Country United States', 'Delaware', 
                                        'Florida', 'Georgia', 'Hawaii', 'Idaho', 'Illinois', 'Indiana', 'Iowa', 'Kansas', 'Kentucky', 'Louisiana', 'Maine', 'Maryland', 'Massachusetts', 'Michigan', 
                                        'Minnesota', 'Mississippi', 'Missouri', 'Montana', 'Nebraska', 'Nevada', 'New Hampshire', 'New Jersey', 'New Mexico', 'New York', 'North Carolina', 
                                        'North Dakota', 'Ohio', 'Oklahoma', 'Oregon', 'Pennsylvania', 'Rhode Island', 'South Carolina', 'South Dakota', 'Tennessee', 'Texas', 'the States', 
                                        'U.S.', 'U.S.A', 'U.S.A.', 'Unied States', 'Uniited States', 'Unite States', 'United', 'United Sates', 'United Shtates', 'United Staes', 'United Stataes', 
                                        'United State', 'United Stated', 'United States', 'United States ?', 'United States Minor Outlying Islands', 'United States of America', 'United StatesEoneCom', 
                                        'United StatesRoyalcaribbeanCom', 'United Stats', 'United Stattes', 'Uniteed States', 'Unites States', 'Unitws States', 'Untied States', 'Untited States', 'US', 
                                        'Us Territory', 'US Virgin Islands', 'USA', 'Usaaaaa', 'Ususaa', 'Utah', 'Vermont', 'Virginia', 'Washington', 'West Virginia', 'Wisconsin', 'Wyoming'};
    

    public BatchJob_LastKeyFieldsUpdateCampaigns(String objectToRun, Boolean isPopulate, DateTime startDate, DateTime endDate) {
        this.objectToRun = objectToRun;
        this.isPopulate = isPopulate;
        this.startDate = startDate;
        this.endDate = endDate;
    }

    public Iterable<SObject> start(Database.BatchableContext bc) {
        String query;
        if (objectToRun == 'CampaignMember') {
            if (isPopulate) {
                query = 'SELECT Id, Last_Key_Fields_Update__c FROM CampaignMember ' +
                        'WHERE ((LeadId != null AND Lead.SM_Country__c IN :countryAlias) OR (ContactId != null AND Contact.Account.SM_Country__c IN :countryAlias)) ' +
                        'AND Last_Key_Fields_Update__c = null AND CreatedDate >= :startDate AND CreatedDate <= :endDate';
            } else {
                query = 'SELECT Id, Last_Key_Fields_Update__c FROM CampaignMember ' + 
                        'WHERE (LeadId = null OR Lead.SM_Country__c NOT IN :countryAlias) AND (ContactId = null OR Contact.Account.SM_Country__c NOT IN :countryAlias) ' + 
                        'AND Last_Key_Fields_Update__c != null AND CreatedDate >= :startDate AND CreatedDate <= :endDate';
            }
        } else if (objectToRun == 'CampaignInfluence') {
            if (isPopulate) {
                query = 'SELECT Id, Last_Key_Fields_Update__c FROM CampaignInfluence ' + 
                        'WHERE Contact.Account.SM_Country__c IN :countryAlias ' + 
                        'AND Last_Key_Fields_Update__c = null AND CreatedDate >= :startDate AND CreatedDate <= :endDate';
            } else {
                query = 'SELECT Id, Last_Key_Fields_Update__c FROM CampaignInfluence ' + 
                        'WHERE Contact.Account.SM_Country__c NOT IN :countryAlias ' + 
                        'AND Last_Key_Fields_Update__c != null AND CreatedDate >= :startDate AND CreatedDate <= :endDate';
            }
        } else if (objectToRun == 'Opportunity') {
            if (isPopulate) {
                query = 'SELECT Id, Last_Key_Fields_Update__c FROM Opportunity ' + 
                    'WHERE Account.SM_Country__c IN :countryAlias ' + 
                    'AND Last_Key_Fields_Update__c = null AND CreatedDate >= :startDate AND CreatedDate <= :endDate';
            } else {
                query = 'SELECT Id, Last_Key_Fields_Update__c FROM Opportunity ' + 
                    'WHERE Account.SM_Country__c NOT IN :countryAlias ' + 
                    'AND Last_Key_Fields_Update__c != null AND CreatedDate >= :startDate AND CreatedDate <= :endDate';
            }
        } else if (objectToRun == 'OpportunityContactRole') {
            if (isPopulate) {
                query = 'SELECT Id, Last_Key_Fields_Update__c FROM OpportunityContactRole ' + 
                    'WHERE Contact.Account.SM_Country__c IN :countryAlias ' + 
                    'AND Last_Key_Fields_Update__c = null AND CreatedDate >= :startDate AND CreatedDate <= :endDate';
            } else {
                query = 'SELECT Id, Last_Key_Fields_Update__c FROM OpportunityContactRole ' + 
                    'WHERE Contact.Account.SM_Country__c NOT IN :countryAlias ' + 
                    'AND Last_Key_Fields_Update__c != null AND CreatedDate >= :startDate AND CreatedDate <= :endDate';
            }
        } else if (objectToRun == 'Task' || objectToRun == 'Event') {
            if (objectToRun == 'Task') {
                if (isPopulate) {
                    query = 'SELECT Id, Last_Key_Fields_Update__c, Account.SM_Country__c, AccountId, Who.Type, What.Type FROM Task ' + 
                        'WHERE Last_Key_Fields_Update__c = null AND CreatedDate >= :startDate AND CreatedDate <= :endDate';
                } else {
                    query = 'SELECT Id, Last_Key_Fields_Update__c, Account.SM_Country__c, AccountId, Who.Type, What.Type FROM Task ' + 
                        'WHERE Last_Key_Fields_Update__c != null AND CreatedDate >= :startDate AND CreatedDate <= :endDate';
                }
            } else {
                if (isPopulate) {
                    query = 'SELECT Id, Last_Key_Fields_Update__c, Account.SM_Country__c, AccountId, Who.Type, What.Type FROM Event ' + 
                        'WHERE Last_Key_Fields_Update__c = null AND CreatedDate >= :startDate AND CreatedDate <= :endDate';
                } else {
                    query = 'SELECT Id, Last_Key_Fields_Update__c, Account.SM_Country__c, AccountId, Who.Type, What.Type FROM Event ' + 
                        'WHERE Last_Key_Fields_Update__c != null AND CreatedDate >= :startDate AND CreatedDate <= :endDate';
                }
            }
        } else if (objectToRun == 'RedAccount') {
            if (isPopulate) {
                query = 'SELECT Id,Last_Key_Fields_Update__c ' + 
                        'FROM Red_Account__c WHERE EscalatedAccount__r.SM_Country__c IN :countryAlias ' + 
                        'AND Last_Key_Fields_Update__c = null AND CreatedDate >= :startDate AND CreatedDate <= :endDate';
            } else {
                query = 'SELECT Id,Last_Key_Fields_Update__c ' + 
                        'FROM Red_Account__c WHERE EscalatedAccount__r.SM_Country__c NOT IN :countryAlias ' + 
                        'AND Last_Key_Fields_Update__c != null AND CreatedDate >= :startDate AND CreatedDate <= :endDate';
            }
       } else if (objectToRun == 'Case') {
            if (isPopulate) {
                query = 'SELECT Id,Last_Key_Fields_Update__c ' + 
                        'FROM Case WHERE Account.SM_Country__c IN :countryAlias ' + 
                        'AND Last_Key_Fields_Update__c = null AND CreatedDate >= :startDate AND CreatedDate <= :endDate';
            } else {
                query = 'SELECT Id,Last_Key_Fields_Update__c ' + 
                        'FROM Case WHERE Account.SM_Country__c NOT IN :countryAlias ' + 
                        'AND Last_Key_Fields_Update__c != null AND CreatedDate >= :startDate AND CreatedDate <= :endDate';
            }
       }
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext bc, List<SObject> scope) {
        Database.SaveResult[] saveResults;
        Triggers.switchOff();
        if (objectToRun == 'CampaignMember') {
            List<CampaignMember> campMembersUpdate = new List<CampaignMember>();
            for (SObject obj : scope) {
                CampaignMember cm = (CampaignMember) obj;
                cm.Last_Key_Fields_Update__c = isPopulate ? Datetime.now() : null;
                campMembersUpdate.add(cm);
            }
            saveResults = Database.update(campMembersUpdate, false);
        } else if (objectToRun == 'CampaignInfluence') {
            List<CampaignInfluence> campInfluenceUpdate = new List<CampaignInfluence>();
            for (SObject obj : scope) {
                CampaignInfluence ci = (CampaignInfluence) obj;
                ci.Last_Key_Fields_Update__c = isPopulate ? Datetime.now() : null;
                campInfluenceUpdate.add(ci);
            }
            saveResults = Database.update(campInfluenceUpdate, false);
        } else if (objectToRun == 'Opportunity') {
            List<Opportunity> oppsUpdate = new List<Opportunity>();
            for (SObject obj : scope) {
                Opportunity opp = (Opportunity) obj;
                opp.Last_Key_Fields_Update__c = isPopulate ? Datetime.now() : null;
                oppsUpdate.add(opp);
            }
            saveResults = Database.update(oppsUpdate, false);
        } else if (objectToRun == 'OpportunityContactRole') {
            List<OpportunityContactRole> oppsConUpdate = new List<OpportunityContactRole>();
            for (SObject obj : scope) {
                OpportunityContactRole oppCon = (OpportunityContactRole) obj;
                oppCon.Last_Key_Fields_Update__c = isPopulate ? Datetime.now() : null;
                oppsConUpdate.add(oppCon);
            }
            saveResults = Database.update(oppsConUpdate, false);
        } else if (objectToRun == 'Task') {
            Set<Id> contactIds = new Set<Id>();
            Set<Id> leadIds = new Set<Id>();
            Set<Id> relatedAccountsId = new Set<Id>();
            for (Task t : (List<Task>) scope) {
                if ((isPopulate && countryAlias.contains(t.Account.SM_Country__c)) || (!isPopulate && !countryAlias.contains(t.Account.SM_Country__c))){
                    relatedAccountsId.add(t.AccountId);
                } 
                if (t.WhoId != null && t.WhoId.getSObjectType().getDescribe().getName() == 'Contact') {
                    contactIds.add(t.WhoId);
                } else if (t.WhoId != null && t.WhoId.getSObjectType().getDescribe().getName() == 'Lead') {
                    leadIds.add(t.WhoId);
                }
            }
            saveResults = Database.update((List<Task>) filterRecordsForTaskAndEventsUpdate(relatedAccountsId, contactIds, leadIds, scope), false);
        } else if (objectToRun == 'Event') {
            Set<Id> contactIds = new Set<Id>();
            Set<Id> leadIds = new Set<Id>();
            Set<Id> relatedAccountsId = new Set<Id>();
            for (Event evt : (List<Event>) scope) {
                if ((isPopulate && countryAlias.contains(evt.Account.SM_Country__c)) || (!isPopulate && !countryAlias.contains(evt.Account.SM_Country__c))){
                    relatedAccountsId.add(evt.AccountId);
                }
                if (evt.WhoId != null && evt.WhoId.getSObjectType().getDescribe().getName() == 'Contact') {
                    contactIds.add(evt.WhoId);
                } else if (evt.WhoId != null && evt.WhoId.getSObjectType().getDescribe().getName() == 'Lead') {
                    leadIds.add(evt.WhoId);
                }
            }
            saveResults = Database.update((List<Event>) filterRecordsForTaskAndEventsUpdate(relatedAccountsId, contactIds, leadIds, scope), false);
         } else if (objectToRun == 'RedAccount') {
            List<Red_Account__c> redAccountsToUpdate = new List<Red_Account__c>();
            for (SObject obj : scope) {
                Red_Account__c rAccount = (Red_Account__c) obj;
                rAccount.Last_Key_Fields_Update__c = isPopulate ? Datetime.now() : null;
                redAccountsToUpdate.add(rAccount);
            }
            saveResults = Database.update(redAccountsToUpdate, false);
        } else if (objectToRun == 'Case') {
            List<Case> casesToUpdate = new List<Case>();
            for (SObject obj : scope) {
                Case c = (Case) obj;
                c.Last_Key_Fields_Update__c = isPopulate ? Datetime.now() : null;
                casesToUpdate.add(c);
            }
            saveResults = Database.update(casesToUpdate, false);
        } 
        Triggers.switchOn();
        for (Database.SaveResult sr : saveResults) {
            if (!sr.isSuccess()) {
                failedRecords.put(sr.getId(), sr.getErrors()[0].getMessage());
            }
        }
    }

    public void finish(Database.BatchableContext bc) {
        AsyncApexJob a = [SELECT Id, Status, TotalJobItems, CreatedById FROM AsyncApexJob WHERE Id = :BC.getJobId()];
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.saveAsActivity = false;
        mail.setTargetObjectId(a.CreatedById);
        mail.setSubject('The Last Key Fields Update batch finished execution with Status: ' + a.Status);
        String body = '<h3>The batch Apex job processed ' + a.TotalJobItems + ' batches with '+ failedRecords.keySet().size() + ' failures.</h3><br/>';
        for (Id recordId : failedRecords.keySet()) {
            body += 'The update of ' + objectToRun + ' record with id: <b>' + recordId + '</b> failed with the following error: <b>' +  failedRecords.get(recordId) + '</b><br/>';
        }
        mail.setHtmlBody(body);
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }

    List<SObject> filterRecordsForTaskAndEventsUpdate(Set<Id> relatedAccountsId, Set<Id> contactIds, Set<Id> leadIds, List<SObject> scope) {
        List<SObject> recordsToUpdate = new List<SObject>();
        Set<Id> relatedContactsId = new Set<Id>();
        Set<Id> relatedLeadsId = new Set<Id>();

        if (isPopulate) {
            relatedContactsId = new Set<Id>(new Map<Id, Contact>([SELECT Id FROM Contact WHERE Id IN :contactIds AND Account.SM_Country__c IN :countryAlias]).keySet());
            relatedLeadsId = new Set<Id>(new Map<Id, Lead>([SELECT Id FROM Lead WHERE Id IN :leadIds AND SM_Country__c IN :countryAlias]).keySet());

            if (objectToRun == 'Task') {
                for(Task t : [SELECT Id,Last_Key_Fields_Update__c FROM Task WHERE Id IN :scope AND (AccountId IN :relatedAccountsId OR WhoId IN :relatedContactsId OR WhoId IN :relatedLeadsId)]) {
                    t.Last_Key_Fields_Update__c = isPopulate ? Datetime.now() : null;
                    recordsToUpdate.add(t);
                }
            } else if (objectToRun == 'Event') {
                for(Event evt : [SELECT Id,Last_Key_Fields_Update__c FROM Event WHERE Id IN :scope AND (AccountId IN :relatedAccountsId OR WhoId IN :relatedContactsId OR WhoId IN :relatedLeadsId)]) {
                    evt.Last_Key_Fields_Update__c = isPopulate ? Datetime.now() : null;
                    recordsToUpdate.add(evt);
                }
            }
        } else if (!isPopulate) {
            relatedContactsId = new Set<Id>(new Map<Id, Contact>([SELECT Id FROM Contact WHERE Id IN :contactIds AND Account.SM_Country__c NOT IN :countryAlias]).keySet());
            relatedLeadsId = new Set<Id>(new Map<Id, Lead>([SELECT Id FROM Lead WHERE Id IN :leadIds AND SM_Country__c NOT IN :countryAlias]).keySet());

            if (objectToRun == 'Task') {
                for(Task t : [SELECT Id,Last_Key_Fields_Update__c FROM Task WHERE Id IN :scope AND (AccountId IN :relatedAccountsId) AND (WhoId = NULL OR WhoId IN :relatedContactsId OR WhoId IN :relatedLeadsId)]) {
                    t.Last_Key_Fields_Update__c = isPopulate ? Datetime.now() : null;
                    recordsToUpdate.add(t);
                }
            } else if (objectToRun == 'Event') {
                for(Event evt : [SELECT Id,Last_Key_Fields_Update__c FROM Event WHERE Id IN :scope AND (AccountId IN :relatedAccountsId) AND (WhoId = NULL OR WhoId IN :relatedContactsId OR WhoId IN :relatedLeadsId)]) {
                    evt.Last_Key_Fields_Update__c = isPopulate ? Datetime.now() : null;
                    recordsToUpdate.add(evt);
                }
            }
        }
        return recordsToUpdate;
    }

}