public with sharing class CompanyRelatedListsExt {
    
    private final Account_Hierarchy__c company;
    public Boolean redirect {get;set;}
    public String redirectUrl {get;set;}
    public Boolean delError {get;set;}
    public Boolean showFullTable {get;set;}
    private List<Company_Persons__c> companyPersons;
    private Set<Id> leadsIds;
    private Set<Id> contactsIds;

    public CompanyRelatedListsExt(ApexPages.StandardController stdController) {
        this.company = (Account_Hierarchy__c)stdController.getRecord();
        this.companyPersons = getCompanyPersons();
        this.leadsIds = getLeadsIds(companyPersons);
        this.contactsIds = getContactsIds(companyPersons);
        this.showFullTable = false;
        this.delError = false;
    }

    public List<Task> getActivities(){
        return [SELECT Id, Subject, WhoId, WhatId, ActivityDate, OwnerId, LastModifiedDate
                FROM Task 
                WHERE WhoId IN : contactsIds
                OR WhoId IN : leadsIds
                ORDER BY LastModifiedDate 
                DESC NULLS LAST];
    }

    public List<Opportunity> getOpportunities(){
        List<OpportunityContactRole> contactRoles;
        Set<Id> returnIds = new Set<Id>();
        if (!contactsIds.isEmpty()) {
            contactRoles = [SELECT OpportunityId 
                            FROM OpportunityContactRole 
                            WHERE ContactId IN : contactsIds];
            if (!contactsIds.isEmpty()) {
                for (OpportunityContactRole role : contactRoles) {
                    if (role.OpportunityId != null) {
                        returnIds.add(role.OpportunityId);
                    }
                }
                if (!returnIds.isEmpty()) {
                    return [SELECT Id, Name, Amount, CloseDate, StageName, LastModifiedDate
                            FROM Opportunity 
                            WHERE Id IN : returnIds
                            ORDER BY LastModifiedDate 
                            DESC NULLS LAST];
                }
            }
        }
        return new List<Opportunity>();
    }

    public List<Campaign> getCampaigns(){
        List<CampaignMember> campaignMembers = new List<CampaignMember>();
        List<Id> campaignIds = new List<Id>();
        if (!contactsIds.isEmpty()) {
            campaignMembers = [SELECT CampaignId
                                FROM CampaignMember 
                                WHERE ContactId IN : contactsIds];
        }
        if (!leadsIds.isEmpty()) {
            campaignMembers.addAll([SELECT CampaignId
                                FROM CampaignMember 
                                WHERE LeadId IN : leadsIds]);
        }
        if (!campaignMembers.isEmpty()) {
            for (CampaignMember campaignMember : campaignMembers) {
                if (campaignMember.CampaignId != null) {
                    campaignIds.add(campaignMember.CampaignId);
                }
            }
            if (!campaignIds.isEmpty()) {
                return [SELECT Id, Name, StartDate, Type, Status, LastModifiedDate 
                        FROM Campaign 
                        WHERE Id IN : campaignIds
                        ORDER BY LastModifiedDate 
                        DESC NULLS LAST];
            }
        }
        return new List<Campaign>();
    }

    public List<Company_Persons__c> getCompanyPersons() {
        return [SELECT Contact__c, Lead__c
                FROM Company_Persons__c 
                WHERE Company__c = : company.Id];
    }

    public Set<Id> getLeadsIds(List<Company_Persons__c> companyPersons) {
        Set<Id> leadsIds = new Set<Id>();
        if (!companyPersons.isEmpty()) {
            for (Company_Persons__c person : companyPersons) {
                if (person.Lead__c != null) {
                    leadsIds.add(person.Lead__c);
                }
            }
        }
        return leadsIds;
    }

    public Set<Id> getContactsIds(List<Company_Persons__c> companyPersons) {
        Set<Id> contactsIds = new Set<Id>();
        if (!companyPersons.isEmpty()) {
            for (Company_Persons__c person : companyPersons) {
                if (person.Contact__c != null) {
                    contactsIds.add(person.Contact__c);
                }
            }
        }
        return contactsIds;
    }

    public void editItem() {
        String objectId = ApexPages.currentPage().getParameters().get('cId');
        String returnId = ApexPages.currentPage().getParameters().get('Id');

        String url = '/' + objectId + '/e?retURL=' + '/' + returnId;
        this.redirect = true;
        this.redirectUrl = url;
    }

    public void deleteItem() {
        String objectId = ApexPages.currentPage().getParameters().get('cId');
        String objType = ApexPages.currentPage().getParameters().get('sobj');
        String returnId = ApexPages.currentPage().getParameters().get('Id');

        String query = 'SELECT Id FROM ' + objType + ' WHERE Id = : objectId';
        
        try {
            sObject delObj = Database.query(query);
            if (delObj != null && delObj.Id != null) {
                delete delObj;
            }
        } catch (Exception ex) {
            this.delError = true;
            ApexPages.addMessage(new ApexPages.Message(
                                            ApexPages.Severity.ERROR,
                                            'You have no privileges to modify this record.' +
                                            'Please contact your administrator.'));
            return;
        }

        String url = '/' + returnId;
        this.redirect = true;
        this.redirectUrl = url;
    }

    public void showAllRecords() {
        this.showFullTable = true;
    }
}