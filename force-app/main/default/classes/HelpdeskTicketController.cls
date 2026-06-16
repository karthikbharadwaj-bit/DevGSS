public class HelpdeskTicketController{

    public String newCaseSubject {get; set;}
    public String newCaseDescription {get; set;}
    
    public String selectedCategory{get;set;} 
    public String selectedType{get;set;}    
    public String selectedSeverity{get;set;} 

    public static Schema.DescribeSObjectResult result = Case.SObjectType.getDescribe();
    public static Map<ID,Schema.RecordTypeInfo> rtMapByName = result.getRecordTypeInfosById();
    public static Map<String,Schema.RecordTypeInfo> rtMapByRecName = result.getRecordTypeInfosByName();
    
    public PageReference close(){
        PageReference tempPage = ApexPages.currentPage();            
            tempPage.setRedirect(true);
        return tempPage ;    
    }
    
    public PageReference createNewCase(){
        System.debug('New case creation');
        
            try{
                TriggerHandler.BY_PASS_CASE_ON_INSERT = true;
                TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE = true;
    
                String loggedInUserId = UserInfo.getUserId();
                Case caseObj = new Case();
                List<User> userObj = [SELECT ContactId, Contact.AccountId FROM User WHERE Id = :loggedInUserId];
    
                caseObj.RecordTypeId  = rtMapByRecName.get('IT Helpdesk').getRecordTypeId();
                caseObj.ContactId = userObj[0].ContactId;
                caseObj.AccountId = userObj[0].Contact.AccountId;
                caseObj.Status = 'New';
                caseObj.Subject = newCaseSubject;
                caseObj.Description = newCaseDescription;
                caseObj.Case_Category__c = selectedCategory;
                caseObj.Type1__c = selectedType;
                caseObj.Case_Severity__c = selectedSeverity;
                caseObj.OwnerId = [select id from User where Name = 'RC Support Agent' and Profile.Name = 'System Administrator' limit 1].id;
                caseObj.origin = 'Web';
                insert caseObj;
                PageReference returnPage = new PageReference('/helpdesk/' + caseObj.Id); 
                returnPage.setRedirect(true);
                return returnPage;
            }catch(Exception e){
                System.debug(e + '(' + e.getLineNumber() + ')');
            }     
            return null;
    }
    
    public List<SelectOption> getCategoryOptions() {
        List<SelectOption> CategoryOptions = new List<SelectOption>();
        CategoryOptions.add(new SelectOption('','--None--'));
        CategoryOptions.add(new SelectOption('Email','Email'));
        CategoryOptions.add(new SelectOption('Laptop/Desktop','Laptop/Desktop'));
        CategoryOptions.add(new SelectOption('Network Access','Network Access'));
        CategoryOptions.add(new SelectOption('End User Application','End User Application'));
        CategoryOptions.add(new SelectOption('Other','Other'));
 
        return CategoryOptions;
        }
    
        public List<SelectOption> getTypeOptions() {
        List<SelectOption> TypeOptions = new List<SelectOption>();
        TypeOptions.add(new SelectOption('','--None--'));
        TypeOptions.add(new SelectOption('New Service Request','New Service Request'));
        TypeOptions.add(new SelectOption('Break/Fix','Break/Fix'));
 
        return TypeOptions;
        }
        
        public List<SelectOption> getSeverityOptions() {
        List<SelectOption> SeverityOptions = new List<SelectOption>();
        SeverityOptions.add(new SelectOption('','--None--'));
        SeverityOptions.add(new SelectOption('Critical','I know many people can’t work'));
        SeverityOptions.add(new SelectOption('Urgent','I can’t do anything'));
        SeverityOptions.add(new SelectOption('High','It’s an inconvenience'));
        SeverityOptions.add(new SelectOption('Medium','I  can wait a few days'));
        return SeverityOptions;
        }
}