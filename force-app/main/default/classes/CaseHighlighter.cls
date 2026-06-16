public class CaseHighlighter {
    final public Set<String> CLOUD_CONNECT_RT = new Set<String>{'Support_T1', 'Support_T1_Shipping','Support_T1_VAR_Partners','Support_T2','Support_T3','Support_VIPFR','Support_Case','Developer_Platform','Support_Chat','Support_Glip','Support_Mobile','Support_FeedBack','Support_Red_Account','Support_Executive_Response_Team','Support_QoS','Feedback'}; //only for those RTs we should check isCloudConnectCustomer
    public Boolean bRedAccount {get;set;}
    public Boolean bContactCenter {get;set;}
    public Boolean isCloudConnectCustomer {get;set;}
    public String strRedAccountId{get;set;}
    public String highlighterMsg {get;set;}
    private static final String BT_BUSINESS;

    static{
        if(!Test.isRunningTest()){
            BT_BUSINESS = RcDealHealper.getBTBrand();
        }else{
            BT_BUSINESS = 'BT Business';
        }
    }

    public CaseHighlighter(ApexPages.StandardController controller) {
        Set<Id> cloudConnectRTIds = new Map<Id, RecordType>([SELECT Id FROM RecordType WHERE DeveloperName IN: CLOUD_CONNECT_RT]).keySet();
        isCloudConnectCustomer = false;
        Case objCase= (Case)controller.getRecord();
        Case objCaseDetail=[SELECT id,AccountId,Account.RC_Brand__c, RecordTypeId FROM Case WHERE id=:objCase.id];
        String brand = objCaseDetail.Account.RC_Brand__c;

        highlighterMsg = (!String.isBlank(brand) ? (brand.containsIgnoreCase('TELUS') ? 'TELUS' : (brand.containsIgnoreCase('BT') ? BT_BUSINESS : (brand.containsIgnoreCase('AT&T') ? 'AT&T' : null)) ) : null );
        for(Account acc: [
                        SELECT
                            (SELECT id,Status__c FROM Escalations__r
                            WHERE Status__c != 'Resolved - Saved' AND Status__c != 'Resolved - Lost' AND Status__c != 'Resolved – Downgraded' ORDER BY LastModifiedDate DESC LIMIT 1)
                        FROM Account WHERE Id =:objCaseDetail.AccountId LIMIT 1] ){
            try {
                if(acc.Escalations__r.size()>0){
                    bRedAccount=true;
                    strRedAccountId=acc.Escalations__r.get(0).id;
                }
            } catch(Exception e){}
        }
        for(Account acc: [SELECT InContact_Service__c FROM Account WHERE Id =:objCaseDetail.AccountId LIMIT 1] ){
            try {
                if(!String.IsBlank(acc.InContact_Service__c)) {
                    bContactCenter = true ;
                }
            } catch(Exception e){}
        }
    }
}