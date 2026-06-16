global without sharing class LeadHelperCls {

    public static final String ADD_LEAD_QUALIFICATION = 'You should add a Lead Qualification before conversion';
    public static final String POPULATE_REQUIRED_FIELDS =
        'Please go to Lead Qualification Summary section and fill all fields marked as required (*) before conversion';
    public static final Integer QUERY_LIMIT = 1;
    public static final Integer OFFSET = 0;


    @AuraEnabled
    public static List<String> getLeadrecord(String leadId){
        Lead pb;
        String cs = System.Label.Pb_Custom_label;
        String [] returnarray = new List<String>();

        try {
            pb = [Select Id, OwnerId from lead where Id = :LeadId];
            String lid = pb.Id;
            String oid = pb.OwnerId;
            Feature_Toggle__c fc = Feature_Toggle__c.getInstance();
            Boolean b = fc.NewConvertLeadPage__c;
            String s = String.ValueOf(b);
            returnarray.add(lid);
            returnarray.add(oid);
            returnarray.add(s);
            returnarray.add(cs);
        } catch (Exception ex) {
            System.debug('Error:' + ex.getmessage());
        }
        
        
        return returnarray;
    }
    @AuraEnabled
    webService static String convert(String recordId) {
        List<UserRole> roles = (List<UserRole>) new QueryFactory(UserRole.SObjectType)
            .selectFields(new List<SObjectField> {UserRole.Id, UserRole.Name})
            .setCondition('Id =:bind0')
            .setQueryBindings(new List<Object> {UserInfo.getUserRoleId()})
            .executeQuery();

        List<Lead_Qualification__c> allLeadQualList =
            (List<Lead_Qualification__c>) new LeadQualificationSelector().selectQualificationsForLeadConvert(recordId,OFFSET,QUERY_LIMIT)
            .selectFields(new LeadQualificationSelector().getFieldListForLeadConverting())
            .executeQuery();

        Lead leadToConvert = [SELECT Id, Lead_Qualification_Next_Steps__c, Lead_Qualification_Current_SItuation__c,
                                     Lead_Qualification_Problems__c, Decision_Making_Process__c
                              FROM Lead WHERE Id = :recordId];

        if (!roles.isEmpty()) {
            if (roles.get(0).Name.toLowerCase().contains('sdr') || roles.get(0).Name.toLowerCase().contains('bdr')) {
                Lead_Qualification__c lq;
                if (!allLeadQualList.isEmpty()) {
                    lq = allLeadQualList.get(0);
                }
                if (
                    (String.isBlank(leadToConvert.Lead_Qualification_Next_Steps__c)
                        || String.isBlank(leadToConvert.Lead_Qualification_Current_SItuation__c)
                        || String.isBlank(leadToConvert.Lead_Qualification_Problems__c)
                        || String.isBlank(leadToConvert.Decision_Making_Process__c))
                    && (allLeadQualList.isEmpty()
                        || (String.isBlank(lq.Current_Situation__c)
                        || String.isBlank(lq.Problems__c)
                        || String.isBlank(lq.Decision_Making_Process__c)
                        || String.isBlank(lq.NextSteps__c)))
                ) {
                    return POPULATE_REQUIRED_FIELDS;
                }
            }
        }
        return null;
    }
    
}