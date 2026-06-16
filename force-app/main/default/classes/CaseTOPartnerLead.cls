public with sharing class CaseTOPartnerLead {
    
    public String caseId{get;set;}
    public Boolean isErrorOccured{get;set;}
    public Boolean isShowMessage{get;set;}
    string userLouisMastrangelo;
    
    public CaseTOPartnerLead(ApexPages.standardController objCont){
        caseId=ApexPages.currentPage().getParameters().get('id');
         if(caseId==null || caseId==''){
            isErrorOccured=true;
        }else{
          isErrorOccured=false;
        }
        isShowMessage=false;
        Default_Partner_Owner__c dfltPartOwner = Default_Partner_Owner__c.getOrgDefaults();
        if(dfltPartOwner != null ) {
            userLouisMastrangelo = dfltPartOwner.UserId__c;
        }
        System.Debug('>>>userLouisMastrangelo>>'+ userLouisMastrangelo);        
    }
    
    public String strMessage{get;set;}
    
    public pagereference createPartnerLead(){
        strMessage='';      
        try{
            isShowMessage=true;    
            RecordType objRecordType=[SELECT id,Name FROM RecordType where SobjectType='Lead' and Name='Partner Leads' limit 1];
            Case objCase=[Select id ,Partner_Contact__c,Partner_Contact__r.Account.Current_Owner__c,Partner_Contact__r.Account.Inside_Sales_Rep__c,
                                Lead_Partner_ID__c,Partner_Lead_Owner__c,NumberOfEmployees__c,Number_of_Locations__c,Partner_Lead_Description__c,
                                Number_of_Users__c,Zip__c,(Select Id From Lead_Qualifications__r), Address_Street_Name__c,
                                Partner_How_did_you_acquire_this_Lead__c, Partner_Lead_Fields__c, Partner_Lead_FirstName__c, Partner_Lead_LastName__c,
                                Partner_Lead_Title__c, Partner_Lead_Company__c, Partner_Lead_Email__c, Partner_Lead_Phone__c,
                                Partner_Lead_Phone_Alternate__c, Resolution__c
                                FROM Case where id=:caseId];
        
            if(objCase.Partner_Lead_Owner__c !=null || objCase.Partner_Contact__c != NULL){
                
                User objUserDetail;
                if(objCase.Partner_Lead_Owner__c !=null){
                    objUserDetail = [Select id,Contact.Account.Current_Owner__c ,Contact.Account.Inside_Sales_Rep__c from User 
                                              where id=:objCase.Partner_Lead_Owner__c];
                }
              
                Lead objLead = new Lead();                
                objLead.leadSource = 'Partner';
                objLead.RecordTypeId = objRecordType.id;
                objLead.LeadPartnerID__c = objCase.Lead_Partner_ID__c;
                objLead.Partner_Lead_Owner__c = objCase.Partner_Lead_Owner__c;
                objLead.Partner_Contact__c  =  objCase.Partner_Contact__c;        
                objLead.NumberOfEmployees__c = objCase.NumberOfEmployees__c;
                objLead.Number_of_Locations__c = objCase.Number_of_Locations__c;
                objLead.Description = objCase.Partner_Lead_Description__c;
                objLead.Number_of_Users__c = objCase.Number_of_Users__c;
                objLead.Zip_Code__c = objCase.Zip__c;
                objLead.Partner_Zip__c = objCase.Zip__c;
                objLead.PostalCode = objCase.Zip__c;
                objLead.Partner_Address1__c = objCase.Address_Street_Name__c;
                objLead.Street = objCase.Address_Street_Name__c;
                //waiting for edition and term.

                objLead.How_did_you_acquire_this_Lead__c = objCase.Partner_How_did_you_acquire_this_Lead__c ;

                //Case 07140743 (QW) Duplicate lead case updates
                objLead.Duplicate_Lead_Case__c = objCase.Id;

                //B3028 Rework of lead to case logic
                objLead.FirstName = objCase.Partner_Lead_FirstName__c;
                objLead.LastName = objCase.Partner_Lead_LastName__c;
                objLead.Title = objCase.Partner_Lead_Title__c;
                objLead.Company = objCase.Partner_Lead_Company__c;
                objLead.Email = objCase.Partner_Lead_Email__c;
                objLead.Phone = objCase.Partner_Lead_Phone__c;
                objLead.Phone_Alternate__c = objCase.Partner_Lead_Phone_Alternate__c;

                DuplicateLeadHelper.fillLeadFromJson(objLead, objCase.Partner_Lead_Fields__c);

                if(objCase.Partner_Contact__c != NULL && objCase.Partner_Contact__r.Account.Current_Owner__c != NULL){
                    objLead.OwnerId = objCase.Partner_Contact__r.Account.Current_Owner__c;
                } else if(objUserDetail != NULL && !String.isBlank(objUserDetail.Contact.Account.Current_Owner__c)) {
                    objLead.OwnerId = objUserDetail.Contact.Account.Current_Owner__c;
                } else {
                    objLead.OwnerId = userLouisMastrangelo;
                }
                
                if(objCase.Partner_Contact__c != NULL && objCase.Partner_Contact__r.Account.Inside_Sales_Rep__c != NULL){
                    objLead.Inside_Sales_Rep__c = objCase.Partner_Contact__r.Account.Inside_Sales_Rep__c;
                } else if(objUserDetail != NULL && objUserDetail.Contact.Account.Inside_Sales_Rep__c != null) {
                    objLead.Inside_Sales_Rep__c = objUserDetail.Contact.Account.Inside_Sales_Rep__c;
                }               
                
                if(Test.isRunningTest()){
                    objLead.Partner_Lead_Owner__c = NULL;
                }
                objLead.Lead_Created_via_Smart_Search__c=true;//CMR-309341 Checking the flag true to identify smart search partner leads for gating
                insert objLead; 
                
                if(objUserDetail != NULL){
                    ShareUtil.shareLeadToPartner(objLead.id,objUserDetail.id);
                }
                
                if(objCase.Lead_Qualifications__r != null && objCase.Lead_Qualifications__r.size() == 1) {
                    string leadQualId = objCase.Lead_Qualifications__r[0].id;
                    Lead_Qualification__c leadQualObj = new Lead_Qualification__c(id = leadQualId);
                    leadQualObj.lead__c = objLead.id;
                    leadQualObj.Case__c = null;
                    update leadQualObj;
                    if(objUserDetail  != NULL){
                        ShareUtil.shareLeadQualificationToPartner(leadQualObj.id, objUserDetail.id); 
                    }
                }
                strMessage=strMessage+'Lead successfully created.Please click <a href=/'+objLead.id+' >here</a> to see the lead details';
                objCase.status='Closed';
                TriggerHandler.BY_PASS_CASE_ON_INSERT = true;
                TriggerHandler.BY_PASS_CASE_ON_UPDATE = true;
                upsert objCase;
                TriggerHandler.BY_PASS_CASE_ON_INSERT = false;
                TriggerHandler.BY_PASS_CASE_ON_UPDATE = false;              
            }else{
                strMessage='Partner Detail is not found.';
            } 
        }catch(DMLException em){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, em.getDmlMessage(0)));
            return null;
        }catch(Exception e){
            strMessage=e.getMessage()+' Line Number:'+e.getLineNumber();
        }
        return null;
    }
    
    public Group getPartnerQueue() {
        return [SELECT id,Name FROM Group WHERE Type='Queue' AND Name='Partner Lead Reviewer' LIMIT 1];
    }
}