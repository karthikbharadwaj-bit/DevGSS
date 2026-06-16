public class CampaignMemberData implements ICampaignMemberData{
    public static Map<Id,Lead> leadMap;
    public static Map<Id,Contact> contactMap;
    public static Map<Id,Campaign> campaignMap;
    public static Set<Id> leadMapIds {get{return (Set<Id>) leadMap.keySet();}}
    public static Set<Id> contactMapIds {get{return (Set<Id>) contactMap.keySet();}}
    public static Set<Id> campaignMapIds {get{return (Set<Id>) campaignMap.keySet();}}

    public CampaignMemberData(){}

    public Interface ICampaignMemberData{
        Map<Id,Lead> getLeadMap(Set<Id> idSet);
        Map<Id,Contact> getContactMap(Set<Id> idSet);
        Map<Id,Campaign> getCampaignMap(Set<Id> idSet);
    }

    public Map<Id,Lead> getLeadMap(Set<Id> idSet){
        if (leadMap == null || leadMap.isEmpty() || !leadMapIds.containsAll(idSet)) {
            List<Object> bindings = new List<Object>();
            bindings.add(idSet);
            leadMap = new Map<Id,Lead>();
            leadMap.putAll((List<Lead>) new LeadSelector().selectLeadsByIds(bindings).executeQuery());
        }
        return leadMap;
    }

    public Map<Id,Contact> getContactMap(Set<Id> idSet){
        if (contactMap == null || contactMap.isEmpty() || !contactMapIds.containsAll(idSet)) {
            List<Object> bindings = new List<Object>();
            bindings.add(idSet);
            contactMap = new Map<Id,Contact>();
            contactMap.putAll((List<Contact>) new ContactSelector().selectContactsByIds(bindings).executeQuery());
        }
        return contactMap;
    }

    public Map<Id,Campaign> getCampaignMap(Set<Id> idSet){
        if (campaignMap == null || campaignMap.isEmpty() || !campaignMapIds.containsAll(idSet)) {
            List<Object> bindings = new List<Object>();
            bindings.add(idSet);
            campaignMap = new Map<Id,Campaign>();
            campaignMap.putAll((List<Campaign>) new CampaignSelector().selectCampaignsByIds(bindings).executeQuery());
        }
        return campaignMap;
    }

}