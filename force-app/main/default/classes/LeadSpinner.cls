public class LeadSpinner {
    
    public Lead leadObj{get;set;}
    public Campaign campaignObj{get;set;}
    public Integer currentUserIndex{get;set;}    
    public Boolean isErrorOccured{get;set;}
    public Boolean isEmptyFolder{get;set;}
    
    public void getLeadObj(Id recordId) {
        try {
            leadObj = [SELECT Id, Name, Company, Email, Phone, SDR_Agents__c, SDR_Agents__r.Name, Owner.Name, Status, OwnerId, LeadSource, 
                       Lead_Folder__c, Primary_Campaign__c, NumberOfEmployees__c, Effective_No_of_Employees_Range__c FROM Lead WHERE Id=: recordId];
        } catch(Exception ex) {
            setException('Lead does not exist.');
        }
    }
    public Set<Id> getSDRProfiles() {
        Set<Id> sdrIds = new Set<Id>();
        for(Profile prof : [SELECT Id, Name FROM Profile WHERE Name LIKE '%SDR%'  ]) {
            sdrIds.add(prof.Id);
        }
        return sdrIds;
    }
    public LeadSpinner(ApexPages.StandardController controller) {
        isEmptyFolder = false;
        isErrorOccured = false;
        currentUserIndex = 0;
        try {
            Id recordId = controller.getId();
            getLeadObj(recordId);
            if(leadObj != null) {
                Set<String> skillIds = new Set<String>();
                Map<Id, Campaign> campaignMap = new Map<Id, Campaign>([SELECT Id, Lead_Creation_Score__c, Lead_Entry_Source__c, AID__c, 
                PID__c, BMID__c, DNIS__c, /*Team__c,*/ NumberOfLeads, Lead_Score__c, Name FROM Campaign WHERE IsActive=true AND Id=:leadObj.Primary_Campaign__c]); 
                campaignObj = campaignMap.get((String) leadObj.Primary_Campaign__c);
                setDefaultFolder();
                Map<String, String> empToCustomerSizeMap =  LeadTriggerHelper.getCustomerSize(new List<Lead>{leadObj});
                //String customerSize = empToCustomerSizeMap.get(String.isBlank(leadObj.NumberOfEmployees__c) ? 'DEFAULT' : leadObj.NumberOfEmployees__c);
                String customerSize = empToCustomerSizeMap.get(String.isBlank(leadObj.Effective_No_of_Employees_Range__c) ? 'DEFAULT' : leadObj.Effective_No_of_Employees_Range__c);
                if(String.isBlank(customerSize)) { 
                    customerSize = empToCustomerSizeMap.get('DEFAULT');
                }
            } else {
                setException('Lead does not exist.'); 
            }
        } catch(Exception e) {
            setException(e.getMessage()); 
        }
    }
    private void setException(String exceptionStr) {
        isErrorOccured = true;
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, exceptionStr)); 
    }
    private void setDefaultFolder() {
        if(String.isBlank(leadObj.Lead_Folder__c)) {
            leadObj.Lead_Folder__c ='B';
            isEmptyFolder = true;
        } 
    }
    public void resetFolder() {
        if(isEmptyFolder) {
            leadObj.Lead_Folder__c = null;
            isEmptyFolder = false;
        }
    }
    public PageReference goToLead() {
        return new PageReference('/'+ leadObj.Id);
    }
    
    public void refreshList() {
        try {
            getLeadObj(leadObj.Id);
            setDefaultFolder();
        } catch(Exception e){
            setException('Error occured while changing owner.');
        }
    }
}