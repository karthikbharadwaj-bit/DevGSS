public abstract with sharing class STCControllerHelper {
    public List<Lead_Qualification__c> allLeadQualList{get;set;}
    public Lead_Qualification__c lq {get;set;}
    public string viewMode{get;set;}
    public String redirectUrl{get;set;}
    public List<HistoryWrapper> history{get;set;}
    public Double offset{get{
        TimeZone tz = UserInfo.getTimeZone();
        //Milliseconds to Day
        return tz.getOffset(DateTime.now()) / (1000 * 3600 * 24.0);
    }}

    //-------------------methdos to controll read or write mode of page
    public void showEdit(){
        viewMode = 'edit';
    }

    public void hideEdit(){
        viewMode = 'read';
    }

    @TestVisible
    private class HistoryWrapper {
        public String changer {get; set;}
        public String fieldName {get; set;}
        public Datetime modifyDate {get; set;}

        public HistoryWrapper (String changer, String fieldName, Datetime modifyDate) {
            this.changer = changer;
            this.fieldName = fieldName;
            this.modifyDate = modifyDate;
        }
    }

    public void trackHistory(Lead_Qualification__c lq) {
        List<Lead_Qualification__History> lqHistory = new List<Lead_Qualification__History>([
                SELECT ParentId, OldValue, NewValue, Field, CreatedById, CreatedDate
                FROM Lead_Qualification__History
                WHERE ParentId = :lq.Id
                ORDER BY CreatedDate DESC
        ]);

        List<Id> userIds = new List<Id>();
        for (Lead_Qualification__History lqh: lqHistory) {
            if (lqh.CreatedById != null) {
                userIds.add(lqh.CreatedById);
            }
        }
        Map<Id, User> users = new Map<Id, User>([
                SELECT Id, Name
                FROM User
                WHERE Id IN :userIds
        ]);

        Map<String,Schema.SObjectField> lqFields = ((SObject)Type.forName('Lead_Qualification__c').newInstance()).getSObjectType()
            .getDescribe().fields.getMap();

        history = new List<HistoryWrapper>();
        for (Lead_Qualification__History lqh : lqHistory) {
            history.add(new HistoryWrapper(
                users.get(lqh.CreatedById).Name, 
                lqFields.containsKey(lqh.Field) ? lqFields.get(lqh.Field).getDescribe().getLabel() : '–', 
                lqh.CreatedDate
            ));
        }
    }
}