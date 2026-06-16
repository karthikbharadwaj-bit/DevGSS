public class BatchJob_CheckMarketoFlag implements Database.Batchable<sObject>, Schedulable, Database.Stateful{

    public BatchJob_CheckMarketoFlag() {}

    public List<sObject> start(Database.BatchableContext bc) {
        Database.QueryLocatorIterator leadIterator = Database.getQueryLocator(getQuery('Lead')).iterator();
        Database.QueryLocatorIterator contactIterator = Database.getQueryLocator(getQuery('Contact')).iterator();
        List<sObject> leadsAndContacts = new List<sObject>();
        while (leadIterator.hasNext()) {
            leadsAndContacts.add(leadIterator.next());
        }
        while (contactIterator.hasNext()) {
            leadsAndContacts.add(contactIterator.next());
        }
        return leadsAndContacts;
    }

    public void execute(Database.BatchableContext bc, List<sObject> scope) {
        Map<Id, sObject> recordsByIds = new Map<Id, sObject>();
        for (sObject record : scope) {
            recordsByIds.put(record.Id, record);
        }
        if (!recordsByIds.isEmpty()) {
            List<CampaignMember> members = [
                                            SELECT LeadId, ContactId,
                                                    Asset_Name__c, Asset_Type__c,
                                                    Member_Target_Segment__c,
                                                    Member_Type__c, Member_Detail__c,
                                                    Promo_Code__c, Responded_Date__c
                                            FROM CampaignMember
                                            WHERE LeadId IN : recordsByIds.keySet()
                                            OR ContactId IN : recordsByIds.keySet()
                                            ];
            if (!members.isEmpty()) {
                for (CampaignMember member : members) {
                    if (member.ContactId != null) {
                        member.Asset_Name__c = ((Contact)recordsByIds.get(member.ContactId)).Asset_Name__c;
                        member.Asset_Type__c = ((Contact)recordsByIds.get(member.ContactId)).Asset_Type__c;
                        member.Member_Target_Segment__c =
                                    ((Contact)recordsByIds.get(member.ContactId)).Campaign_Member_Target_Segment__c;
                        member.Member_Type__c = ((Contact)recordsByIds.get(member.ContactId)).Campaign_Member_Type__c;
                        member.Member_Detail__c = ((Contact)recordsByIds.get(member.ContactId)).Member_Detail__c;
                        member.Promo_Code__c = ((Contact)recordsByIds.get(member.ContactId)).Promo_Code__c;
                        member.Responded_Date__c = ((Contact)recordsByIds.get(member.ContactId)).Responded_Date__c;
                        ((Contact)recordsByIds.get(member.ContactId)).MarketoBatchJobFlag__c = false;
                    } else if (member.LeadId != null) {
                        member.Asset_Name__c = ((Lead)recordsByIds.get(member.LeadId)).Asset_Name__c;
                        member.Asset_Type__c = ((Lead)recordsByIds.get(member.LeadId)).Asset_Type__c;
                        member.Member_Target_Segment__c =
                                            ((Lead)recordsByIds.get(member.LeadId)).Campaign_Member_Target_Segment__c;
                        member.Member_Detail__c = ((Lead)recordsByIds.get(member.LeadId)).Member_Detail__c;
                        member.Responded_Date__c = ((Lead)recordsByIds.get(member.LeadId)).Responded_DateMKTO__c;
                        ((Lead)recordsByIds.get(member.LeadId)).MarketoBatchJobFlag__c = false;
                    }
                }
                update recordsByIds.values();
                update members;
            }
        }
    }

    public void finish(Database.BatchableContext bc) {}

    public void execute(SchedulableContext context) {
        BatchJob_CheckMarketoFlag batchJob = new BatchJob_CheckMarketoFlag();
        Database.executeBatch(batchJob);
    }

    private String getQuery(String queryObject) {
        return 'SELECT Asset_Name__c, Asset_Type__c, ' +
                        'Campaign_Member_Target_Segment__c, ' +
                         (queryObject == 'Lead'
                                                ? ''
                                                : 'Campaign_Member_Type__c,') +
                        'Member_Detail__c,' +
                        (queryObject == 'Lead'
                                                ? 'Responded_DateMKTO__c '
                                                : 'Promo_Code__c, Responded_Date__c ') +
                'FROM ' + queryObject + ' ' +
                'WHERE MarketoBatchJobFlag__c = true ' +
                'AND Id IN (SELECT ' + (queryObject == 'Lead'
                                                ? 'LeadId '
                                                : 'ContactId ') +
                'FROM CampaignMember WHERE ' + (queryObject == 'Lead'
                                                    ? 'LeadId '
                                                    : 'ContactId ') + '!= null) ' +
                'ORDER BY LastModifiedDate DESC ' +
                'LIMIT 10000';
    }
}