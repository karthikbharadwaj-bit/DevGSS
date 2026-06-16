public with sharing class CampaignMemberTriggerHandler { 
    public static Boolean dmlFromExceptionAndNotificationReprocessingBatch = false;
    public static Boolean dmlFromPlatformEvents = false;

    public class CampaignAttribution extends Triggers.TriggerHandlerBase {

        public CampaignMemberData data = new CampaignMemberData();

        override public void handle() {
            
            if (TriggerHandler.BY_PASS_CAMPAIGNMEMBER_TRIGGER_CAMPAIGNATTRIBUTION) {
                return;
            }

            Set<Id> campaignIdSet = new Set<Id>();
            Set<Id> leadIdSet = new Set<Id>();
            Set<Id> contactIdSet = new Set<Id>();

            for (CampaignMember cm : (List<CampaignMember>) trigger.new) {
                campaignIdSet.add(cm.CampaignId);
                if (cm.LeadId != null) {
                    leadIdSet.add(cm.LeadId);
                }
                if (cm.ContactId != null) {
                    contactIdSet.add(cm.ContactId);
                }
            }

            Map<Id, Lead> idToLeadMap = data.getLeadMap(leadIdSet);
            Map<Id, Contact> idToContactMap = data.getContactMap(contactIdSet);
            Map<Id, Campaign> idToCampaignMap = data.getCampaignMap(campaignIdSet);

            Map<id,Lead> leadsToUpdate = new Map<id,Lead>();
            Map<Id,Contact> contactsToUpdate = new Map<Id,Contact>();
            
            for (CampaignMember cm : (List<CampaignMember>) trigger.new) {
                Lead lead = idToLeadMap.get(cm.LeadId);
                Campaign campaign = idToCampaignMap.get(cm.CampaignId);
                Contact contact = idToContactMap.get(cm.ContactId);
                if (lead != null) {
                    CampaignMemberTriggerHelper.updateCampaignOnLead(lead, campaign);
                    if (campaign.Shared_Lead_Campaign__c) {
                        CampaignMemberTriggerHelper.updateSharedLeadCampaignCounter(lead);
                    }
                    leadsToUpdate.put(lead.id,lead);
                }
                if (contact != null) {
                    CampaignMemberTriggerHelper.updateCampaignOnContact(contact, campaign);
                    contactsToUpdate.put(contact.Id, contact);
                }
            }

            if(leadsToUpdate!=null && leadsToUpdate.values().size() > 0){
                try {
                    TriggerHandler.BY_PASS_LEAD_UPDATE = true;
                    update leadsToUpdate.values();
                    TriggerHandler.BY_PASS_LEAD_UPDATE = false;
                } catch(Exception e) {
                    AquivaHelper.throwAquivaException('Exception Occured on Campaign attribution on Lead: ' + e.getMessage() + ' \r\n');
                }
            }
            if(contactsToUpdate!=null && contactsToUpdate.values().size() > 0){
                TriggerHandler.BY_PASS_CONTACT_ON_UPDATE = true;
                Database.update(contactsToUpdate.values(), false);
                TriggerHandler.BY_PASS_CONTACT_ON_UPDATE = false;
            }
        }
    }

    public class FirePlatformEventLog extends Triggers.TriggerHandlerBase {

        override public void handle() {

            if (TriggerHandler.BY_PASS_CAMPAIGNMEMBER_TRIGGER_FIREPLATFORMEVENTLOG) {
                return;
            }

            Feature_Toggle__c featureToogle = Feature_Toggle__c.getInstance();
            Decimal CampMemberAsyncRecordQantity = featureToogle.CampMemberAsyncRecordQantity__c != null ? featureToogle.CampMemberAsyncRecordQantity__c : 25; 
            if (!dmlFromExceptionAndNotificationReprocessingBatch && !dmlFromPlatformEvents &&
                Trigger.new.size() > CampMemberAsyncRecordQantity) {
                    CampaignMemberTriggerHelper.FirePlatformEventLog((List<CampaignMember>) Trigger.new);
                }                
        }
    }

    public class FirePlatformEventCheck extends Triggers.TriggerHandlerBase {

        override public void handle() {
            
            if (TriggerHandler.BY_PASS_CAMPAIGNMEMBER_TRIGGER_FIREPLATFORMEVENTCHECK) {
                return;
            }

            Feature_Toggle__c featureToogle = Feature_Toggle__c.getInstance();
            Decimal CampMemberAsyncRecordQantity = featureToogle.CampMemberAsyncRecordQantity__c != null ? featureToogle.CampMemberAsyncRecordQantity__c : 25;
            if (!dmlFromExceptionAndNotificationReprocessingBatch && !dmlFromPlatformEvents &&
                Trigger.new.size() > CampMemberAsyncRecordQantity) {
                    CampaignMemberTriggerHelper.FirePlatformEventCheck((List<CampaignMember>) Trigger.new); 
                }                
        }
    }   
    
    public class UpdateMostRecentCampaignValuesOnLeadAndContact extends Triggers.TriggerHandlerBase {

        override public void handle() {

            if(Trigger.isInsert || Trigger.isUpdate) {
                List<CampaignMember> campaignMemberWithStatusChanged = new List<CampaignMember>();
    
                for (CampaignMember cm : (List<CampaignMember>) Trigger.new) {
                    Boolean statusHasChanged = Trigger.isInsert || (cm.Status != ((CampaignMember) Trigger.oldMap.get(cm.Id)).Status);
                    if (statusHasChanged) {
                        campaignMemberWithStatusChanged.add(cm);
                    }
                }
    
                if (!campaignMemberWithStatusChanged.isEmpty()) {
                    if ( Trigger.isInsert 
                        && !(Limits.getQueueableJobs() == Limits.getLimitQueueableJobs()) 
                        && !System.isBatch()
                    ) {
                        System.enqueueJob(new UpdateMostRecentCampaignValuesOnLeadAndContactAsync(campaignMemberWithStatusChanged));
                    } else {
                        CampaignMemberTriggerHelper.updateMostRecentCampaignMemberStatusOnContactAndLead(campaignMemberWithStatusChanged);
                    }
                }
            } else if (Trigger.isDelete) {
                CampaignMemberTriggerHelper.deleteMostRecentCampaignMemberStatusOnContactAndLead((List<CampaignMember>) trigger.old);
            }
        }
    }

    public class UpdateMostRecentCampaignValuesOnLeadAndContactAsync implements Queueable {
        List<CampaignMember> campaignMembers;

        public UpdateMostRecentCampaignValuesOnLeadAndContactAsync(List<CampaignMember> campaignMembers) {
            this.campaignMembers = campaignMembers;
        }

        public void execute(QueueableContext context) {
            CampaignMemberTriggerHelper.updateMostRecentCampaignMemberStatusOnContactAndLead(campaignMembers);
        }
    }
}