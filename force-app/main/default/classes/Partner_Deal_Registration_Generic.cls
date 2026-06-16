//Description - Generic Class for Creating PRM Deal Reg, Lead, Account, Opportunity, Contact
//JIRA(s) covered - PRM-67, PRM-79, PRM-193
//Developer - ratul.saha@ringcentral.com
//Related Classes/Triggers - PartnerDealRegistrationUtil.cls, Quote_SharingHandler.cls, Sharing_AccountLeadHandler.cls, DealRegistrationMain.trigger
//Test Class - Test_Partner_Deal_Registration_Generic

global with sharing class Partner_Deal_Registration_Generic {
  webservice static String createDealRegistration(Deal_Registration__c dealReg) {
    try {
        checkMandatoryFields(dealReg);
        fillOtherFields(dealReg);
        
        //Upsert Deal Reg
        if(!String.isBlank(dealReg.Deal_Reg_RC_UID__c)) {
          upsert dealReg Deal_Reg_RC_UID__c;
        } else {
          insert dealReg;
        }

        //Fix Deal Reg Sharing
        Set<Id> dealRegIdSet = new Set<Id>();
        dealRegIdSet.add(dealReg.Id);
        Quote_SharingHandler.handleDealRegistrationShare(dealRegIdSet);

        //For Avaya Perform Duplicate check
        if(dealReg.Brand_Name__c == 'Avaya Cloud Office') {
          List<Deal_Registration__c> dealRegs = PartnerDealRegistrationUtil.performDuplicateCheckMain(dealRegIdSet);
          if(dealRegs[0].Duplicate__c == true) {//It returns single Id as we are passing single Id to it.
            return JSON.serializePretty(new ResponseWrapper(
              dealRegs[0], null, true, 'Warning', 'Duplicate Deal Registration record detected, stopped Deal Registration conversion to Lead.'
            ), true);
          }
        }

        //Create Lead from Deal Reg
        List<Deal_Registration__c> dealToCreateAsLeads = new List<Deal_Registration__c>();
        dealToCreateAsLeads.add(dealReg);
        List<Lead> leadsCreated = PartnerDealRegistrationUtil.AddDealAsLead(dealToCreateAsLeads);

        //Fix Lead Sharing
        Set<Id> setOfLeadIds = new Set<id>();
        setOfLeadIds.add(leadsCreated[0].Id);
        Sharing_AccountLeadHandler.handleLeadShareFuture(setOfLeadIds);

         //For Avaya and ALE Perform below checks
        if (dealReg.Brand_Name__c == 'Avaya Cloud Office' || dealReg.Brand_Name__c == 'Rainbow Office'){
          Lead ld = [SELECT SM_Employees__c FROM Lead where Id = :leadsCreated[0].Id LIMIT 1];
          if (dealReg.Portal_Deal__c){
            return JSON.serializePretty(new ResponseWrapper(dealReg, leadsCreated[0], true, 'Success', 'No Errors. Skipped Auto-Conversion.'), true);
          }
          if(dealReg.Brand_Name__c == 'Rainbow Office' && ld.SM_Employees__c > 100){
            return JSON.serializePretty(new ResponseWrapper(
              dealReg, leadsCreated[0], true, 'Warning', 'Lead has SM_Employees__c > 100, stopped Lead Auto conversion'
            ), true);
          } 
        }
        return JSON.serializePretty(new ResponseWrapper(dealReg, leadsCreated[0]), true);
    } catch (Exception excp) {
      //Catch error and return
      return JSON.serializePretty(new ResponseWrapper('Failure', excp.getMessage() + '\n' + excp.getStackTraceString()), true);
    }
  }

  webservice static String convertLead(Id leadToBeConvertedId) {
    try {
      Lead leadToBeConverted = [Select Id, Status, Name, FirstName, LastName, Title, Company, Email, Phone, Street, City__c, City, State__c, PostalCode, Country__c, Number_of_Users__c,
        Lead_Brand_Name__c, Deal_Reg_RC_UID__c, Settlement_type__c, Lead_Tier_Name__c, BusinessIdentity__c, Partner_Type__c, Partner_Lead_Source__c, NumberOfEmployees__c, Number_of_Locations__c, Industry, Estimated_Close_Date__c,
        How_did_you_acquire_this_Lead__c, Description, website, Existing_Solution_Provider__c, Prompting_Change__c, Partner_Lead_Owner__r.Name,
        Deal_Registration__r.Id, Deal_Registration__r.Name, Partner_Account__r.Name, Partner_Account__r.Partner_ID__c, Partner_Contact__r.Name, Competitors__c,
        Decision_Maker__c, Currently_in_a_contract__c, Project_budget__c, Partner_Lead_Owner__c, Deal_Registration__c, Partner_Account__c,
        Partner_Contact__c, Inside_Sales_Rep__c, Inside_Sales_Rep__r.Name, Sales_Notes__c, IsAvayaConverted__c, Avaya_Cloud_Specialist__c,
        RC_Overlay__c, Partner_Account__r.Partner_Country__c, Owner.Name, OwnerId, Portal_Cloud_Specialist__c, Portal_Cloud_Specialist__r.Name,
        Deal_Registration__r.Ignite_Deal__c, Timezone__c, LeadSource, Country, State, Street_2__c, Phone_Ext__c, Account_Number__c,
        Zip_Code__c, NumberOfEmployees, Effective_No_of_Employees_Range__c, Preferred_Language__c, LeadPartnerID__c, CurrencyIsoCode, Type_of_Customer_or_Prospect__c from Lead where Id =: leadToBeConvertedId FOR UPDATE
      ];

      PartnerDealRegistrationUtil.PartnerLeadConvertResult result = PartnerDealRegistrationUtil.convertPartnerLead(leadToBeConverted, true);

      return JSON.serializePretty(new ResponseWrapper(leadToBeConverted.Deal_Registration__r.Id, leadToBeConverted.Id, result.accountId, result.contactId, result.opportunityId), true);
    } catch (Exception excp) {
      return JSON.serializePretty(new ResponseWrapper('Failure', excp.getMessage() + '\n' + excp.getStackTraceString()), true);
    }
  }

  private static void checkMandatoryFields(Deal_Registration__c dealReg) {
    Set<String> missingFields = new Set<String>();

    //String Fields
    missingFields.add(String.isBlank(dealReg.First_Name__c) ? 'First_Name__c' : null);
    missingFields.add(String.isBlank(dealReg.Last_Name__c) ? 'Last_Name__c' : null);
    missingFields.add(String.isBlank(dealReg.Business_Title__c) ? 'Business_Title__c' : null);
    missingFields.add(String.isBlank(dealReg.Company_Name__c) ? 'Company_Name__c' : null);
    missingFields.add(String.isBlank(dealReg.Email_Address__c) ? 'Email_Address__c' : null);
    missingFields.add(String.isBlank(dealReg.Phone_Number__c) ? 'Phone_Number__c' : null);
    missingFields.add(String.isBlank(dealReg.Address__c) ? 'Address__c' : null);
    missingFields.add(String.isBlank(dealReg.City__c) ? 'City__c' : null);
    missingFields.add(String.isBlank(dealReg.State__c) ? 'State__c' : null);
    missingFields.add(String.isBlank(dealReg.Country__c) ? 'Country__c' : null);
    missingFields.add(String.isBlank(dealReg.Tier_Name__c) ? 'Tier_Name__c' : null);
    missingFields.add(String.isBlank(dealReg.Brand_Name__c) ? 'Brand_Name__c' : null);
    missingFields.add(String.isBlank(dealReg.Edition__c) ? 'Edition__c' : null);
    missingFields.add(String.isBlank(dealReg.Term__c) ? 'Term__c' : null);
    missingFields.add(String.isBlank(dealReg.Number_of_Employees__c) ? 'Number_of_Employees__c' : null);
    missingFields.add(String.isBlank(dealReg.Number_of_Locations__c) ? 'Number_of_Locations__c' : null);
    missingFields.add(String.isBlank(dealReg.Website__c) ? 'Website__c' : null);
    missingFields.add(String.isBlank(dealReg.How_did_you_acquire_this_Lead__c) ? 'How_did_you_acquire_this_Lead__c' : null);
    missingFields.add(String.isBlank(dealReg.Description__c) ? 'Description__c' : null);
    missingFields.add(String.isBlank(dealReg.Budget_available_for_project__c) ? 'Budget_available_for_project__c' : null);
    missingFields.add(String.isBlank(dealReg.Existing_Solution_Provider__c) ? 'Existing_Solution_Provider__c' : null);
    missingFields.add(String.isBlank(dealReg.Competitor_s__c) ? 'Competitor_s__c' : null);
    missingFields.add(String.isBlank(dealReg.Whats_prompting_change__c) ? 'Whats_prompting_change__c' : null);
    missingFields.add(String.isBlank(dealReg.Decision_Maker__c) ? 'Decision_Maker__c' : null);
    missingFields.add(String.isBlank(dealReg.Currently_in_a_contract__c) ? 'Currently_in_a_contract__c' : null);
    //Non String Fields
    missingFields.add(dealReg.Forecasted_Users__c == null ? 'Forecasted_Users__c' : null);
    missingFields.add(dealReg.Estimated_Close_Date__c == null ? 'Estimated_Close_Date__c' : null);
    //Conditional fields validation
    if(!String.isBlank(dealReg.Decision_Maker__c) && dealReg.Decision_Maker__c.equals('Other')) {
      missingFields.add(String.isBlank(dealReg.Decision_Maker_Other__c) ? 'Decision_Maker_Other__c' : null);
    }
    if(!String.isBlank(dealReg.Existing_Solution_Provider__c) && dealReg.Existing_Solution_Provider__c.equals('Other')) {
      missingFields.add(String.isBlank(dealReg.Existing_Solution_Provider_Others__c) ? 'Existing_Solution_Provider_Others__c' : null);
    }
    if(!String.isBlank(dealReg.Competitor_s__c) && dealReg.Competitor_s__c.equals('Other')) {
      missingFields.add(String.isBlank(dealReg.Competitors_Other__c) ? 'Competitors_Other__c' : null);
    }
    if(!String.isBlank(dealReg.Whats_prompting_change__c) && dealReg.Whats_prompting_change__c.equals('Other')) {
      missingFields.add(String.isBlank(dealReg.What_s_prompting_change_Other__c) ? 'What_s_prompting_change_Other__c' : null);
    }
    //Avaya Specific fields
    if(!String.isBlank(dealReg.Brand_Name__c) && dealReg.Brand_Name__c.equals('Avaya Cloud Office')) {
      missingFields.add(String.isBlank(dealReg.Partner_System_ID__c) ? 'Partner_System_ID__c' : null);
    }

    missingFields.remove(null);
    if(missingFields.size() > 0) {
      String exceptionMessage = 'Below mandatory field(s) are missing from payload.\n';
      for(String field: missingFields) {
        exceptionMessage += field + '\n';
      }

      throw new Deal_Registration_Exception(exceptionMessage);
    }

    validateNumberofEmployeesPicklist(dealReg.Number_of_Employees__c);
  }

  private static void validateNumberofEmployeesPicklist(String value) {
    Set<String> pickListValuesSet= new Set<String>();
		Schema.DescribeFieldResult fieldResult = Deal_Registration__c.Number_of_Employees__c.getDescribe();
		List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
		for( Schema.PicklistEntry pickListVal : ple){
			pickListValuesSet.add(pickListVal.getLabel());
		}
    if(!pickListValuesSet.contains(value)) {
      throw new Deal_Registration_Exception('Invalid value provided on Number_of_Employees__c field. Please provide correct value');
    }
  }

  private static void fillOtherFields(Deal_Registration__c dealReg) {
    dealReg.Avaya_Partnership_Deal__c = true;
    dealReg.Portal_Deal__c = true;
    dealReg.Street__c = dealReg.Address__c;
    dealReg.Status__c = 'Approved';
    dealReg.RC_Overlay__c = 'API';
    if(dealReg.Partner_Contact__c != null) {
      Contact con = [Select AccountId, Account.Permitted_Brands__c, Account.Partner_Id__c from Contact where Id =: dealReg.Partner_Contact__c limit 1];
      //Validate whether this Partner is permitted to sell for the current dealReg brand
      if(String.isBlank(con.Account.Permitted_Brands__c) || !con.Account.Permitted_Brands__c.contains(dealReg.Brand_Name__c)) {
        throw new Deal_Registration_Exception('This Partner is not permitted to create Deal Registrations with Brand = ' + dealReg.Brand_Name__c);
      }
      dealReg.Partner_Account__c = con.AccountId;
      dealReg.Partner_ID__c = con.Account.Partner_Id__c;
    }
  }

  global class ResponseWrapper {
    webservice String apiStatus {
      get;
      set;
    }
    webservice String apiMessage {
      get;
      set;
    }
    webservice Boolean skipConversion {
      get;
      set;
    }
    webservice Deal_Registration__c dealReg {
      get;
      set;
    }
    webservice Lead partnerLead {
      get;
      set;
    }
    webservice APIResponse apiResponse {
      get;
      set;
    }
    webservice DuplicateMatchedAgainst duplicateMatchedAgainst { get; set; }

    //Stage 1 Success constructor
    global ResponseWrapper(Deal_Registration__c dealReg, Lead partnerLead) {
      this.apiStatus = 'Success';
      this.apiMessage = 'No Errors';
      this.skipConversion = false;
      this.dealReg = dealReg;
      this.partnerLead = partnerLead;
      this.apiResponse = new APIResponse((dealReg != null ? dealReg.Id : null), (partnerLead != null ? partnerLead.id : null), null, null, null);
    }

    //Stage 1 Success with Skip messages
    global ResponseWrapper(Deal_Registration__c dealReg, Lead partnerLead, boolean skip, String apiStatus, String apiMessage) {
      this.apiStatus = apiStatus;
      this.apiMessage = apiMessage;
      this.skipConversion = skip;
      //this.dealReg = dealReg;
      //this.partnerLead = partnerLead;
      this.apiResponse = new APIResponse((dealReg != null ? dealReg.Id : null), (partnerLead != null ? partnerLead.id : null), null, null, null);
      if(dealReg.Duplicate__c){
      		this.duplicateMatchedAgainst = new DuplicateMatchedAgainst(dealReg.Duplicate_Match_Account__c, dealReg.Duplicate_Match_Contact__c, dealReg.Duplicate_Match_Opportunity__c, dealReg.Duplicate_Deal_Registration__c, dealReg.Duplicate_Match_Lead__c);
     	}
    }

    //Stage 2 Success constructor
    global ResponseWrapper(Id partnerDealRegistrationId, Id partnerLeadId, Id partnerAccountId, Id partnerContactId, Id partnerOpportunityId) {
      this.apiStatus = 'Success';
      this.apiMessage = 'No Errors';
      this.apiResponse = new APIResponse(partnerDealRegistrationId, partnerLeadId, partnerAccountId, partnerContactId, partnerOpportunityId);
    }

    //Error constructor
    global ResponseWrapper(String apiStatus, String apiMessage) {
      this.apiStatus = apiStatus;
      this.apiMessage = apiMessage;
    }
  }

  global class APIResponse {
    webservice Id partnerDealRegistrationId {
      get;
      set;
    }
    webservice Id partnerLeadId {
      get;
      set;
    }
    webservice Id partnerAccountId {
      get;
      set;
    }
    webservice Id partnerContactId {
      get;
      set;
    }
    webservice Id partnerOpportunityId {
      get;
      set;
    }

    global APIResponse(Id partnerDealRegistrationId, Id partnerLeadId, Id partnerAccountId, Id partnerContactId, Id partnerOpportunityId) {
      this.partnerDealRegistrationId = partnerDealRegistrationId;
      this.partnerLeadId = partnerLeadId;
      this.partnerAccountId = partnerAccountId;
      this.partnerContactId = partnerContactId;
      this.partnerOpportunityId = partnerOpportunityId;
    }
  }
  global class DuplicateMatchedAgainst{
     webservice Id Account;
     webservice Id Contact;
     webservice Id Opportunity;
     webservice Id Deal;
     webservice Id Lead;
    global DuplicateMatchedAgainst(Id accountId, Id contactId, Id opportunityId, Id dealId, Id leadId){
         this.Account = AccountId;
         this.Contact = contactId;
         this.Opportunity = opportunityId;
         this.Deal = dealId;
         this.Lead = leadId;
    }
  }
  global class Deal_Registration_Exception extends Exception {}
}