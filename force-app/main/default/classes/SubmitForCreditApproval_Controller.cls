public class SubmitForCreditApproval_Controller {
    
    public static responsewrapper reswrap = new responsewrapper();
    
    @AuraEnabled
    public static responsewrapper validatesubmitforcreditcheck(String recordId){
        
        List<String> errorlist = new List<String>();
        List<D_B_Credit_Check__c> dnbrecord = new List<D_B_Credit_Check__c>();
        errorlist = ApexWebServices.dnbiValidationForQueueAndCompanyName(recordId);
        reswrap.errormessageList = errorList;
        
        if(errorlist.size() == 0 || Test.isRunningTest()){
            try{
                dnbrecord = [SELECT Id,Business_Name__c FROM D_B_Credit_Check__c WHERE Approval__c = : recordId];
                if(dnbrecord.size() >0) {
                    reswrap.dnbrecordid = dnbrecord[0].id;
                }
            }catch(Exception e){
                reswrap.dnbrecordid = 'ERROR';
            }
            
        }
        
        return reswrap;
        
    }
    
        
        public class responsewrapper{
            
            @AuraEnabled
            public List<String> errormessageList {get;set;}
            @AuraEnabled
            public String dnbrecordid {get;set;}
        }
    
}