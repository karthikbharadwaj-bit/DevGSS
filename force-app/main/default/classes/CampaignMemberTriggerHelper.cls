public class CampaignMemberTriggerHelper {
    private static final String SOLVE_THEN_SELL_BMID = 'SOLVETHENSELL';
    static final String DMLINSERT = 'INSERT';
    static final String DMLUPDATE = 'UPDATE';
    public static Lead updateCampaignOnLead(Lead leadToUpdate, Campaign campaign) {
        if (leadToUpdate == null || campaign == null) {
            return null;
        }
        if (leadToUpdate.Most_Recent_Campaign__r == null || leadToUpdate.Most_Recent_Campaign__r.Non_Attributable__c 
            || !campaign.Non_Attributable__c) {
            leadToUpdate.Most_Recent_Campaign__c = campaign.Id;
            leadToUpdate.Primary_Campaign__c = campaign.Id;
            if (String.isNotBlank(campaign.BMID__c)) {
                leadToUpdate.BMID__c = campaign.BMID__c;
            }
        }
        return leadToUpdate;
    }

    public static Lead updateSharedLeadCampaignCounter(Lead leadToUpdate) {
        Integer counter = Integer.valueOf(leadToUpdate.Shared_Lead_Counter__c == null ? 0 : leadToUpdate.Shared_Lead_Counter__c);
        leadToUpdate.Shared_Lead_Counter__c = counter + 1;
        return leadToUpdate;
    }

    public static Contact updateCampaignOnContact(Contact contactToUpdate, Campaign campaign) {
        if (contactToUpdate == null || campaign == null) {
            return null;
        }
        if (contactToUpdate.Most_Recent_Campaign__r == null || contactToUpdate.Most_Recent_Campaign__r.Non_Attributable__c 
            || !campaign.Non_Attributable__c) {
            contactToUpdate.Most_Recent_Campaign__c = campaign.Id;
            contactToUpdate.Primary_Campaign__c = campaign.Id;
            if (String.isNotBlank(campaign.BMID__c)) {
                contactToUpdate.BMID__c = campaign.BMID__c;
            }
        }
        if (TriggerHandler.UPDATE_CONTACT_BMID) {
            contactToUpdate.BMID__c = SOLVE_THEN_SELL_BMID;
            contactToUpdate.AID__c = '';
            contactToUpdate.PID__c = '';
        }
        return contactToUpdate;
    }

    public static void FirePlatformEventLog(List<CampaignMember> CampaignMembers) {
        List<Campaign_Member_Log__e> campMembEvents = new List<Campaign_Member_Log__e>();
        for( CampaignMember campMemb : CampaignMembers) {
            String recordId = Trigger.isUpdate == true ? 
                (String) campMemb.id : 
                (String) campMemb.CampaignId + '-' + (String) campMemb.ContactId + '-' + (String) campMemb.LeadId;
            campMembEvents.add(
                new Campaign_Member_Log__e(
                    Data__c = JSON.serialize(campMemb),
                    RecordId__c = recordId )
            );
        }
        PlatformEvents.publishPlatformEvent(campMembEvents, 'FirePlatformEventLog');
    }
    public static void FirePlatformEventCheck(List<CampaignMember> CampaignMembers) {
        List<Campaign_Member_Check__e> campMembEvents = new List<Campaign_Member_Check__e>();
        for( CampaignMember campMemb : CampaignMembers) {
            String recordId = Trigger.isUpdate == true ? 
                (String) campMemb.id : 
                (String) campMemb.CampaignId + '-' + (String) campMemb.ContactId + '-' + (String) campMemb.LeadId;
            campMembEvents.add(
                new Campaign_Member_Check__e(
                    RecordId__c = recordId)
            );
        }
        PlatformEvents.publishPlatformEvent(campMembEvents, 'FirePlatformEventCheck');
    }
    
    public static void updateMostRecentCampaignMemberStatusOnContactAndLead(List<CampaignMember> campaignMembers) {
        updateMostRecentCampaignMemberStatus(campaignMembers, false);
    }

    public static void deleteMostRecentCampaignMemberStatusOnContactAndLead(List<CampaignMember> campaignMembers) {
        updateMostRecentCampaignMemberStatus(campaignMembers, true);
    }

    private static void updateMostRecentCampaignMemberStatus(List<CampaignMember> campaignMembers, Boolean isDelete) {
        Map<String, CampaignMember> campaignMemberByUniqueKey = new Map<String, CampaignMember>();

        Set<Id> idCampaigns = new Set<Id>();
        Set<Id> idContacts = new Set<Id>();
        Set<Id> idLeads = new Set<Id>();

        List<Lead> leadsToUpdate = new List<Lead>();
        List<Contact> contactsToUpdate = new List<Contact>();

        for (CampaignMember cm : campaignMembers) {
            idCampaigns.add(cm.CampaignId);
            
            campaignMemberByUniqueKey.put(cm.CampaignId + '-' + cm.ContactId + '-' + cm.LeadId, cm);

            if (String.isNotBlank(cm.ContactId)) {
                idContacts.add(cm.ContactId);
            }

            if (String.isNotBlank(cm.LeadId)) {
                idLeads.add(cm.LeadId);
            }
        }
        
        for (Lead l : (List<Lead>) new LeadSelector()
             .selectLeadByIdAndMostRecentCampaign(new Object[]{idLeads, idCampaigns})
             .executeQuery()
            ) {
                String key = l.Most_Recent_Campaign__c + '-null-' + l.Id;
                if(campaignMemberByUniqueKey.containsKey(key)){
                    if (isDelete) {
                        l.Most_Recent_Campaign_Member_Status__c = null;
                    } else {
                        l.Most_Recent_Campaign_Member_Status__c = campaignMemberByUniqueKey.get(key).Status;
                    }
                    leadsToUpdate.add(l);
                }
            }
        
        for (Contact cont : (List<Contact>) new ContactSelector()
             .selectContactByIdAndMostRecentCampaign(new Object[]{idContacts, idCampaigns})
             .executeQuery()
            ) {
                String key = cont.Most_Recent_Campaign__c + '-' + cont.Id + '-null';
                if(campaignMemberByUniqueKey.containsKey(key)){
                    if (isDelete) {
                        cont.Most_Recent_Campaign_Member_Status__c = null;
                    } else {
                        cont.Most_Recent_Campaign_Member_Status__c = campaignMemberByUniqueKey.get(key).Status;
                    }
                    contactsToUpdate.add(cont);
                }
            }

        TriggerHandler.BY_PASS_LEAD_UPDATE = true;
        update leadsToUpdate;
        TriggerHandler.BY_PASS_LEAD_UPDATE = false;
        TriggerHandler.BY_PASS_CONTACT_ON_UPDATE = true;
        update contactsToUpdate;
        TriggerHandler.BY_PASS_CONTACT_ON_UPDATE = false;
    }

}