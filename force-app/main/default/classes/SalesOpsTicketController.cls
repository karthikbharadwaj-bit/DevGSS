public class SalesOpsTicketController{

    public String newCaseSubject {get; set;}
    public String newCaseDescription {get; set;}
    
    public String selectedCategory{get;set;} 
    public String selectedType{get;set;}    
    public String selectedSeverity{get;set;} 
    
    public List<SelectOption> optionsType {get;set;}

    public void HelpdeskTicketController(){}

    //to be checked
    public static Schema.DescribeSObjectResult result = Case.SObjectType.getDescribe();
    public static Map<ID,Schema.RecordTypeInfo> rtMapByName = result.getRecordTypeInfosById();
    public static Map<String,Schema.RecordTypeInfo> rtMapByRecName = result.getRecordTypeInfosByName();
    
    public PageReference close(){
        PageReference tempPage = ApexPages.currentPage();            
            tempPage.setRedirect(true);
        return tempPage ;    
    
        //return null;
    }
    
    //New case creation via Helpdesk Case button
    public PageReference createNewCase2(){
        System.debug('New case creation');
        
            try{
                TriggerHandler.BY_PASS_CASE_ON_INSERT = true;
                TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE = true;
    
                String loggedInUserId = UserInfo.getUserId();
                Case caseObj = new Case();
                List<User> userObj = [SELECT ContactId, Contact.AccountId FROM User WHERE Id = :loggedInUserId];
    
                caseObj.ContactId = userObj[0].ContactId;
                caseObj.AccountId = userObj[0].Contact.AccountId;
                caseObj.Status = 'New';
                caseObj.Subject = newCaseSubject;
                caseObj.Description = newCaseDescription;
                caseObj.Case_Category__c = selectedCategory;
                caseObj.Type1__c = selectedType;
                caseObj.Application__c = selectedSeverity;
                caseObj.OwnerId = [select id from Group where Type='Queue' and Name = 'Sales Ops Team'].id;
                caseObj.origin = 'Web';
                insert caseObj;
                PageReference returnPage = new PageReference('/helpdesk/' + caseObj.Id); 
                returnPage.setRedirect(true);
                return returnPage;
            }catch(Exception e){
                System.debug(e + '(' + e.getLineNumber() + ')');
                ApexPages.addMessages(e);
            }     
            return null;
 
    }

    
        public List<SelectOption> getCategoryOptions() {
            
            List<Case_Field_Dependency__mdt> casecategory;
            String prev;
           
            casecategory = [select case_category__c from Case_Field_Dependency__mdt order by case_category__c] ;
           
            List<SelectOption> options= new List<SelectOption>();
            options.add(new SelectOption('','---Select---'));
            for(Case_Field_Dependency__mdt u : casecategory)
            {      
               if(u.Case_Category__c!=prev){
                   options.add(new SelectOption(u.Case_Category__c, u.Case_Category__c));
                   prev=u.Case_Category__c;
               }
            }
            return options;
       
           

        }
        
        
        public void updateDropdownType() {
            List<Case_Field_Dependency__mdt> casecategory;
            casecategory = [select type__c from Case_Field_Dependency__mdt where case_category__c=:selectedCategory order by type__c] ;
                
            optionsType = new List<SelectOption>();
            optionsType.add(new SelectOption('','---Select---'));
            for(Case_Field_Dependency__mdt u : casecategory)
            {
                   optionsType.add(new SelectOption(u.type__c , u.type__c));
            }
        
        }
    
    
        public List<SelectOption> getTypeOptions() {
            return optionsType;
        }
        
        public List<SelectOption> getApplicationOptions() {
        List<SelectOption> options = new List<SelectOption>();
    
        Schema.DescribeFieldResult fieldResult = Case.Application__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        options.add(new SelectOption( '' ,'---Select---'));
        for( Schema.PicklistEntry f : ple)
        {
           options.add(new SelectOption(f.getLabel(), f.getValue()));
        }
        return options;
        }        
}