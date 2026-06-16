@isTest
private class DG_DFR_Class_TEST{

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void CreateLeadDFR_Test() { 
        TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT();
        TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE();
        TriggerHandler.BY_PASS_CONTACT_ON_INSERT();
        TriggerHandler.BY_PASS_CONTACT_ON_UPDATE();
        TriggerHandler.BY_PASS_OPPORTUNITY_ON_INSERT();
        TriggerHandler.BY_PASS_OPPORTUNITY_ON_UPDATE();
        
        Test.startTest();
        List<Lead> listLead = new List<Lead>();     
        
        //Created as MQL
        Lead l1 = new Lead(
            Status = '1. New',
            LeadSource = 'Inbound Call',  
            State ='CA', 
            Phone = '+1.213.111.1111', 
            LastName = 'TEST', 
            FirstName = 'TEST', 
            Company = 'xxAugusto Bisdaxx',
            Email = 'aaabisda@aaabisda.net', 
            Country = 'USA',
            Number_of_Users__c = 20,
          Forecasted_Contact_Center_Users__c = 20,
          Industry = 'Education',
          Employees_Override__c = 'Just Me',
          Lead_Tier_Name__c = 'Office',
          RC_Edition__c = 'Standard',
          RC_Term__c = 'Monthly');
            
        listLead.add(l1);
        
        //Created as Prospect   
        Lead l2 = new Lead(
            Status = 'X. Open',
            LeadSource = 'Inbound Call', 
            State ='CA', 
            Phone = '+1.213.111.1111', 
            LastName = 'TEST', 
            FirstName = 'TEST', 
            Company = 'xxAugusto Bisdaxx',
            Email = 'aaabisda@aaabisda.net', 
            Country = 'USA',
            Number_of_Users__c = 20,
          Forecasted_Contact_Center_Users__c = 20,
          Industry = 'Education',
          Employees_Override__c = 'Just Me',
          Lead_Tier_Name__c = 'Office',
          RC_Edition__c = 'Standard',
          RC_Term__c = 'Monthly');
        
        listLead.add(l2);
        
        //Created as MQL
        Lead l3 = new Lead(
            Status = '1. New',
            LeadSource = 'Inbound Call', 
            State ='CA', 
            Phone = '+1.213.111.1111', 
            LastName = 'TEST', 
            FirstName = 'TEST', 
            Company = 'xxAugusto Bisdaxx',
            Email = 'aaabisda@aaabisda.net', 
            Country = 'USA',
            Number_of_Users__c = 20,
          Forecasted_Contact_Center_Users__c = 20,
          Industry = 'Education',
          Employees_Override__c = 'Just Me',
          Lead_Tier_Name__c = 'Office',
          RC_Edition__c = 'Standard',
          RC_Term__c = 'Monthly');
        
        listLead.add(l3);
        
        //Created as Re-New
        Lead l4 = new Lead(
            Status = '.5 Re-New',
            LeadSource = 'Inbound Call', 
            State ='CA', 
            Phone = '+1.213.111.1111', 
            LastName = 'TEST',  
            FirstName = 'TEST', 
            Company = 'xxAugusto Bisdaxx',
            Email = 'aaabisda@aaabisda.net', 
            Country = 'USA',
            Number_of_Users__c = 20,
          Forecasted_Contact_Center_Users__c = 20,
          Industry = 'Education',
          Employees_Override__c = 'Just Me',
          Lead_Tier_Name__c = 'Office',
          RC_Edition__c = 'Standard',
          RC_Term__c = 'Monthly');
        
        listLead.add(l4);
        
        //Created as SAL
        Lead l5 = new Lead(
            Status = '1.5 Call Out',
            LeadSource = 'Inbound Call', 
            State ='CA', 
            Phone = '+1.213.111.1111', 
            LastName = 'TEST',  
            FirstName = 'TEST', 
            Company = 'xxAugusto Bisdaxx',
            Email = 'aaabisda@aaabisda.net', 
            Country = 'USA',
            Number_of_Users__c = 20,
          Forecasted_Contact_Center_Users__c = 20,
          Industry = 'Education',
          Employees_Override__c = 'Just Me',
          Lead_Tier_Name__c = 'Office',
          RC_Edition__c = 'Standard',
          RC_Term__c = 'Monthly');
        
        listLead.add(l5);
        
        Lead l6 = new Lead(
            Status = 'X. Suspect',
            LeadSource = 'Inbound Call', 
            State ='CA', 
            Phone = '+1.213.111.1111', 
            LastName = 'TEST',  
            FirstName = 'TEST', 
            Company = 'xxAugusto Bisdaxx',
            Email = 'aaabisda@aaabisda.net', 
            Country = 'USA',
            Number_of_Users__c = 20,
          Forecasted_Contact_Center_Users__c = 20,
          Industry = 'Education',
          Employees_Override__c = 'Just Me',
          Lead_Tier_Name__c = 'Office',
          RC_Edition__c = 'Standard',
          RC_Term__c = 'Monthly');
        
        listLead.add(l6);
        
        Lead l7 = new Lead(
            Status = 'X. Suspect',
            LeadSource = 'Inbound Call', 
            State ='CA', 
            Phone = '+1.213.111.1111', 
            LastName = 'TEST',  
            FirstName = 'TEST', 
            Company = 'xxAugusto Bisdaxx',
            Email = 'aaabisda@aaabisda.net', 
            Country = 'USA',
            Number_of_Users__c = 20,
          Forecasted_Contact_Center_Users__c = 20,
          Industry = 'Education',
          Employees_Override__c = 'Just Me',
          Lead_Tier_Name__c = 'Office',
          RC_Edition__c = 'Standard',
          RC_Term__c = 'Monthly');
        
        listLead.add(l7);
        
        try{
            insert listLead;
        }catch(Exception e) {}
       
        //MQL to Downgraded
        l1.Status = '0. Downgraded';        
        l1.Downgrade_Reason__c = 'No Show';  
        
        //Prospect to MQL
        l2.Status = '1. New';
        
        //MQL to SAL
        l3.Status = '1.5 Call Out';
        
        //Re-New to Downgraded;
        l4.status = '0. Downgraded';
        l4.Downgrade_Reason__c = 'No Show'; 
        
       //SAL to Downgraded;
        l5.status = '0. Downgraded';
        l5.Downgrade_Reason__c = 'No Show'; 

        try{       
            update listLead;
        }catch(Exception e) {}
        
        Test.stopTest();
        
        //Convert Lead from Suspect         
        Database.LeadConvert lc = new database.LeadConvert();
        lc.setLeadId(l7.Id);        
        lc.setConvertedStatus('2. Contacted');  
        Database.LeadConvertResult result;
        try {   
            result = Database.convertLead(lc);
        }catch(Exception e) {} 
        
    }    
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
   @isTest
    static void CreateLeadDFR_Test2() {
        TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT();
        TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE();
        TriggerHandler.BY_PASS_CONTACT_ON_INSERT();
        TriggerHandler.BY_PASS_CONTACT_ON_UPDATE();
        TriggerHandler.BY_PASS_OPPORTUNITY_ON_INSERT();
        TriggerHandler.BY_PASS_OPPORTUNITY_ON_UPDATE();
        Test.startTest();
        
        List<Lead> listLead = new List<Lead>();
        
        Lead l7 = new Lead(
            Status = 'X. Suspect',
            LeadSource = 'Inbound Call', 
            State ='CA', 
            Phone = '+1.213.111.1111', 
            LastName = 'TEST',  
            FirstName = 'TEST', 
            Company = 'xxAugusto Bisdaxx',
            Email = 'aaabisda@aaabisda.net', 
            Country = 'USA',
            Number_of_Users__c = 20,
          Forecasted_Contact_Center_Users__c = 20,
          Industry = 'Education',
          Employees_Override__c = 'Just Me',
          Lead_Tier_Name__c = 'Office',
          RC_Edition__c = 'Standard',
          RC_Term__c = 'Monthly');
            
        listLead.add(l7);
            
        Lead l8 = new Lead(
            Status = 'X. Suspect',
            LeadSource = 'Inbound Call', 
            State ='CA', 
            Phone = '+1.213.111.1111', 
            LastName = 'TEST',  
            FirstName = 'TEST', 
            Company = 'xxAugusto Bisdaxx',
            Email = 'aaabisda@aaabisda.net', 
            Country = 'USA',
            Number_of_Users__c = 20,
          Forecasted_Contact_Center_Users__c = 20,
          Industry = 'Education',
          Employees_Override__c = 'Just Me',
          Lead_Tier_Name__c = 'Office',
          RC_Edition__c = 'Standard',
          RC_Term__c = 'Monthly');
        
        listLead.add(l8);
        
        Lead l9 = new Lead(
            Status = 'X. Suspect',
            LeadSource = 'Inbound Call', 
            State ='CA', 
            Phone = '+1.213.111.1111', 
            LastName = 'TEST',  
            FirstName = 'TEST', 
            Company = 'xxAugusto Bisdaxx',
            Email = 'aaabisda@aaabisda.net', 
            Country = 'USA',
            Number_of_Users__c = 20,
          Forecasted_Contact_Center_Users__c = 20,
          Industry = 'Education',
          Employees_Override__c = 'Just Me',
          Lead_Tier_Name__c = 'Office',
          RC_Edition__c = 'Standard',
          RC_Term__c = 'Monthly');
        
        listLead.add(l9);
            
        Lead l10 = new Lead(
            Status = '1.5 Call Out',
            LeadSource = 'Inbound Call', 
            State ='CA', 
            Phone = '+1.213.111.1111', 
            LastName = 'TEST',  
            FirstName = 'TEST', 
            Company = 'xxAugusto Bisdaxx',
            Email = 'aaabisda@aaabisda.net', 
            Country = 'USA',
            Number_of_Users__c = 20,
          Forecasted_Contact_Center_Users__c = 20,
          Industry = 'Education',
          Employees_Override__c = 'Just Me',
          Lead_Tier_Name__c = 'Office',
          RC_Edition__c = 'Standard',
          RC_Term__c = 'Monthly');
        
        listLead.add(l10);
        
        //Created as Prospect   
        Lead l11 = new Lead(
            Status = 'X. Open',
            LeadSource = 'Inbound Call', 
            State ='CA', 
            Phone = '+1.213.111.1111', 
            LastName = 'TEST', 
            FirstName = 'TEST', 
            Company = 'xxAugusto Bisdaxx',
            Email = 'aaabisda@aaabisda.net', 
            Country = 'USA',
            Number_of_Users__c = 20,
          Forecasted_Contact_Center_Users__c = 20,
          Industry = 'Education',
          Employees_Override__c = 'Just Me',
          Lead_Tier_Name__c = 'Office',
          RC_Edition__c = 'Standard',
          RC_Term__c = 'Monthly');
        
        listLead.add(l11);
        
        //Created as Prospect   
        Lead l12 = new Lead(
            Status = 'X. Open',
            LeadSource = 'Inbound Call', 
            State ='CA', 
            Phone = '+1.213.111.1111', 
            LastName = 'TEST', 
            FirstName = 'TEST', 
            Company = 'xxAugusto Bisdaxx',
            Email = 'aaabisda@aaabisda.net', 
            Country = 'USA',
            Number_of_Users__c = 20,
          Forecasted_Contact_Center_Users__c = 20,
          Industry = 'Education',
          Employees_Override__c = 'Just Me',
          Lead_Tier_Name__c = 'Office',
          RC_Edition__c = 'Standard',
          RC_Term__c = 'Monthly');
        
        listLead.add(l12);
        
        //Created as Prospect   
        Lead l13 = new Lead(
            Status = 'X. Open',
            LeadSource = 'Inbound Call', 
            State ='CA', 
            Phone = '+1.213.111.1111', 
            LastName = 'TEST', 
            FirstName = 'TEST', 
            Company = 'xxAugusto Bisdaxx',
            Email = 'aaabisda@aaabisda.net', 
            Country = 'USA',
            Number_of_Users__c = 20,
          Forecasted_Contact_Center_Users__c = 20,
          Industry = 'Education',
          Employees_Override__c = 'Just Me',
          Lead_Tier_Name__c = 'Office',
          RC_Edition__c = 'Standard',
          RC_Term__c = 'Monthly');
        
        listLead.add(l13);
        
        Lead l14 = new Lead(
            Status = 'X. Open',
            LeadSource = 'Inbound Call', 
            State ='CA', 
            Phone = '+1.213.111.1111', 
            LastName = 'TEST', 
            FirstName = 'TEST', 
            Company = 'xxAugusto Bisdaxx',
            Email = 'aaabisda@aaabisda.net', 
            Country = 'USA',
            Number_of_Users__c = 20,
          Forecasted_Contact_Center_Users__c = 20,
          Industry = 'Education',
          Employees_Override__c = 'Just Me',
          Lead_Tier_Name__c = 'Office',
          RC_Edition__c = 'Standard',
          RC_Term__c = 'Monthly');
        
        listLead.add(l14);
        
        Lead l15 = new Lead(
            Status = 'X. Open',
            LeadSource = 'Inbound Call', 
            State ='CA', 
            Phone = '+1.213.111.1111', 
            LastName = 'TEST', 
            FirstName = 'TEST', 
            Company = 'xxAugusto Bisdaxx',
            Email = 'aaabisda@aaabisda.net', 
            Country = 'USA',
            Number_of_Users__c = 20,
          Forecasted_Contact_Center_Users__c = 20,
          Industry = 'Education',
          Employees_Override__c = 'Just Me',
          Lead_Tier_Name__c = 'Office',
          RC_Edition__c = 'Standard',
          RC_Term__c = 'Monthly');
        
        listLead.add(l15);
        
        try{
            insert listLead;
        }catch(Exception e) {}
       
        //Suspect to MQL
        l7.Status = '1. New';
        
        //Suspect to Re-New
        l8.Status = '.5 Re-New';
        
        //Suspect to SAL
        l9.Status = '1.5 Call Out';
        
        //Prospect to Re-New
        l11.Status = '.5 Re-New';
        
        //Prospect to SAL
        l12.Status = '1.5 Call Out';
        
        //Prospect to Downgraded
        l13.Status = '0. Downgraded';
        l13.Downgrade_Reason__c = 'No Show'; 
        
        try{       
            update listLead;
        }catch(Exception e) {}        
        
        //Convert Lead from Prospect            
        Database.LeadConvert lc = new database.LeadConvert();
        lc.setLeadId(l15.Id);       
        lc.setConvertedStatus('2. Contacted');  
        try {   
            Database.LeadConvertResult result = Database.convertLead(lc);
        }catch(Exception e) {}
        
        Test.stopTest();
        
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')    
    @isTest
    static void DFRConvertLeadFromSuspect() {
        
        TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT();
        TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE();
        TriggerHandler.BY_PASS_CONTACT_ON_INSERT();
        TriggerHandler.BY_PASS_CONTACT_ON_UPDATE();
        TriggerHandler.BY_PASS_OPPORTUNITY_ON_INSERT();
        TriggerHandler.BY_PASS_OPPORTUNITY_ON_UPDATE();
        
        Test.startTest();
                
        Lead l1 = new Lead(
        Status = 'X. Suspect',
        LeadSource = 'Inbound Call', 
        State ='CA', 
        Phone = '+1.213.111.1111', 
        LastName = 'TEST', 
        FirstName = 'TEST', 
        Company = 'xxAugusto Bisdaxx',
        Email = 'aaabisda@aaabisda.net', 
        Country = 'USA',
        Number_of_Users__c = 20,
        Forecasted_Contact_Center_Users__c = 20,
        Industry = 'Education',
        Employees_Override__c = 'Just Me',
        Lead_Tier_Name__c = 'Office',
        RC_Edition__c = 'Standard',
        RC_Term__c = 'Monthly');
        
        try{
            insert l1;
        }catch(exception e) {}
        
        Test.stopTest();
        
        //Convert Lead from Suspect
        Database.LeadConvert lc = new database.LeadConvert();
        lc.setLeadId(l1.Id);        
        lc.setConvertedStatus('2. Contacted');      
        try{
            Database.LeadConvertResult result = Database.convertLead(lc);
        }catch(Exception e) {}
        TriggerHandler.RESET_VARIABLES();
    }
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void Opportunity_EOL_Test() {
        TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT();
        TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE();
        TriggerHandler.BY_PASS_CONTACT_ON_INSERT();
        TriggerHandler.BY_PASS_CONTACT_ON_UPDATE();
        TriggerHandler.BY_PASS_OPPORTUNITY_ON_INSERT();
        TriggerHandler.BY_PASS_OPPORTUNITY_ON_UPDATE();
        Test.startTest();
                
        //Created as MQL
        Lead l1 = new Lead(
            Status = '1. New',
            LeadSource = 'Inbound Call', 
            State ='CA', 
            Phone = '+1.213.111.1111', 
            LastName = 'TEST', 
            FirstName = 'TEST', 
            Company = 'xxAugusto Bisdaxx',
            Email = 'aaabisda@aaabisda.net', 
            Country = 'USA',
          Number_of_Users__c = 20,
          Forecasted_Contact_Center_Users__c = 20,
          Industry = 'Education',
          Employees_Override__c = 'Just Me',
          Lead_Tier_Name__c = 'Office',
          RC_Edition__c = 'Standard',
          RC_Term__c = 'Monthly');
        
            
        try{       
            insert l1;
        }catch(Exception e) {}
        
        
        //Convert Lead from SAL         
        Database.LeadConvert lc = new database.LeadConvert();
        lc.setLeadId(l1.Id);        
        lc.setConvertedStatus('2. Contacted');  
        Database.LeadConvertResult result;
        
        Test.stopTest();
        try{   
            result = Database.convertLead(lc);
        }catch(Exception e) {
            System.debug('e =>> ' + e);
        }     
        
        
        map<Id, Opportunity> mapOppUpdate = new map<Id, Opportunity>();
        mapOppUpdate.put(result.getOpportunityId(), new Opportunity(Id=result.getOpportunityId(),StageName=OpportunityHelper.STAGE_NAME_CLOSED_WON));

        try{
            update mapOppUpdate.values();
        }catch(Exception e) {}
        TriggerHandler.RESET_VARIABLES();
        
    }
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void DFRAddRemovePrimaryOpportunityContact_Test() {
        TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT();
        TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE();
        TriggerHandler.BY_PASS_CONTACT_ON_INSERT();
        TriggerHandler.BY_PASS_CONTACT_ON_UPDATE();
        TriggerHandler.BY_PASS_OPPORTUNITY_ON_INSERT();
        TriggerHandler.BY_PASS_OPPORTUNITY_ON_UPDATE();
        
        Lead l1 = new Lead(
        Status = 'X. Open',
        LeadSource = 'Inbound Call', 
        State ='CA', 
        Phone = '+1.213.111.1111', 
        LastName = 'TEST', 
        FirstName = 'TEST', 
        Company = 'xxAugusto Bisdaxx',
        Email = 'aaabisda@aaabisda.net', 
        Country = 'USA',
        Number_of_Users__c = 20,
        Forecasted_Contact_Center_Users__c = 20,
        Industry = 'Education',
        Employees_Override__c = 'Just Me',
        Lead_Tier_Name__c = 'Office',
        RC_Edition__c = 'Standard',
        RC_Term__c = 'Monthly');
        
        insert l1;
        
        //Convert lead from Prospect
        Database.LeadConvert lc = new database.LeadConvert();
        lc.setLeadId(l1.Id);        
        lc.setConvertedStatus('2. Contacted');      
        
        Database.LeadConvertResult result;
        
        try{
            result = Database.convertLead(lc);
        }catch(Exception e) {}
        
        
        ID OppId = result.getOpportunityId();
        ID ConId = result.getContactId();
        
        Test.startTest();        
        map<ID,Opportunity> mapOpp = new map<ID,Opportunity>(); 
        
        //Remove Primary Opportunity Contact
        mapOpp.put(OppId, new Opportunity(Id=OppId, Primary_Opportunity_Contact__c=Null));  
        
        try{
            update  mapOpp.values();
        }catch(Exception e) {}
        
        
        
        Demand_Funnel__c d = [Select d.id From Demand_Funnel__c d 
        where d.Contact__c = :ConId limit 1];
        
        try{
            delete d;
        }catch(Exception e) {}
        
        //Add Primary Opportunity Contact
        mapOpp.put(OppId, new Opportunity(Id=OppId, Primary_Opportunity_Contact__c=ConId)); 
        
        try{
            update  mapOpp.values();
        }catch(Exception e) {}
        
        Test.stopTest();
        
        TriggerHandler.RESET_VARIABLES();
    }
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void DFR_ChangeLeadOwner_Test() {
        TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT();
        TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE();
        TriggerHandler.BY_PASS_CONTACT_ON_INSERT();
        TriggerHandler.BY_PASS_CONTACT_ON_UPDATE();
        TriggerHandler.BY_PASS_OPPORTUNITY_ON_INSERT();
        TriggerHandler.BY_PASS_OPPORTUNITY_ON_UPDATE();
        
        Test.startTest();       
        
        map<String,String> mapDFRSystemUsers = DG_DFR_Class_Helper.getDFRSystemUsers();
        
        String vUID;
        for (String UID : mapDFRSystemUsers.keySet()){
            vUID = UID;
        }
        
        List<Lead> listLead = new List<Lead>();     
        
        //Created lead created by system users
        Lead l1 = new Lead(
            Status = 'X. Open',
            LeadSource = 'Inbound Call', 
            State ='CA', 
            Phone = '+1.213.111.1111', 
            LastName = 'TEST', 
            FirstName = 'TEST', 
            Company = 'xxAugusto Bisdaxx',
            Email = 'aaabisda@aaabisda.net', 
            Country = 'USA',
            OwnerId = vUID,
          Number_of_Users__c = 20,
          Forecasted_Contact_Center_Users__c = 20,
          Industry = 'Education',
          Employees_Override__c = 'Just Me',
          Lead_Tier_Name__c = 'Office',
          RC_Edition__c = 'Standard',
          RC_Term__c = 'Monthly');
            
        listLead.add(l1);
        
        Lead l2 = new Lead(
            Status = '1.5 Call Out',
            LeadSource = 'Inbound Call', 
            State ='CA', 
            Phone = '+1.213.111.1111', 
            LastName = 'TEST', 
            FirstName = 'TEST', 
            Company = 'xxAugusto Bisdaxx',
            Email = 'aaabisda@aaabisda.net', 
            Country = 'USA',
            OwnerId = vUID,
          Number_of_Users__c = 20,
          Forecasted_Contact_Center_Users__c = 20,
          Industry = 'Education',
          Employees_Override__c = 'Just Me',
          Lead_Tier_Name__c = 'Office',
          RC_Edition__c = 'Standard',
          RC_Term__c = 'Monthly');
        
        listLead.add(l2);
                
        try{
            insert listLead;
        }catch(Exception e) {}
        
        Test.stopTest();
        
        //Change Lead Owner from a System User
        l1.OwnerId = Userinfo.getUserId();  
        l2.OwnerId = Userinfo.getUserId();          

        try{   
            update listLead;
        }catch(Exception e) {} 
        
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void populateCohortData_TEST() {
        TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT();
        TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE();
        TriggerHandler.BY_PASS_CONTACT_ON_INSERT();
        TriggerHandler.BY_PASS_CONTACT_ON_UPDATE();
        TriggerHandler.BY_PASS_OPPORTUNITY_ON_INSERT();
        TriggerHandler.BY_PASS_OPPORTUNITY_ON_UPDATE();
        
        Test.startTest();       
                
        List<Lead> listLead = new List<Lead>();     
        
        //Created lead created by system users
        Lead l1 = new Lead(
            Status = 'X. Open',
            LeadSource = 'Inbound Call', 
            State ='CA', 
            Phone = '+1.213.111.1111', 
            LastName = 'TEST', 
            FirstName = 'TEST', 
            Company = 'xxAugusto Bisdaxx',
            Email = 'aaabisda@aaabisda.net', 
            Country = 'USA',
          Number_of_Users__c = 20,
          Forecasted_Contact_Center_Users__c = 20,
          Industry = 'Education',
          Employees_Override__c = 'Just Me',
          Lead_Tier_Name__c = 'Office',
          RC_Edition__c = 'Standard',
          RC_Term__c = 'Monthly');
            
        listLead.add(l1);
        
        Lead l2 = new Lead(
            Status = 'X. Suspect',
            LeadSource = 'Inbound Call', 
            State ='CA', 
            Phone = '+1.213.111.1111', 
            LastName = 'TEST', 
            FirstName = 'TEST', 
            Company = 'xxAugusto Bisdaxx',
            Email = 'aaabisda@aaabisda.net', 
            Country = 'USA',
          Number_of_Users__c = 20,
          Forecasted_Contact_Center_Users__c = 20,
          Industry = 'Education',
          Employees_Override__c = 'Just Me',
          Lead_Tier_Name__c = 'Office',
          RC_Edition__c = 'Standard',
          RC_Term__c = 'Monthly');
        
        listLead.add(l2);
                
        try{
            insert listLead;
        }catch(Exception e) {}
        
        Test.stopTest();

        try{
            l2.Status = 'X. Open';  
            update listLead;
        }catch(Exception e) {} 
        
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')    
    @isTest
    static void DFR_ContactStatusChange1_TEST(){
      TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT();
        TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE();
        TriggerHandler.BY_PASS_CONTACT_ON_INSERT();
        TriggerHandler.BY_PASS_CONTACT_ON_UPDATE();
        TriggerHandler.BY_PASS_OPPORTUNITY_ON_INSERT();
        TriggerHandler.BY_PASS_OPPORTUNITY_ON_UPDATE();
        
        ///test.startTest();
        
        Account testAcc = new Account();        
        testAcc.Name = 'my test account';
        
        insert testAcc;
        
        Contact testContact = new Contact();        
        testContact.FirstName = 'firstname';
        testContact.LastName = 'lastname';
        testContact.Email = 'ab1@ab1.com';      
        testContact.AccountId = testAcc.Id;
        testContact.Contact_Funnel_Type__c = 'Prospect';
        
        try{
            insert testContact;   
        }catch(Exception e) {}     
        
        //TriggerHandler.BY_PASS_CONTACT_ON_INSERT = false;
        //TriggerHandler.BY_PASS_CONTACT_ON_UPDATE = false;
        //TriggerHandler.BY_PASS_CONTACT_ON_AFTER = false;
        
        testContact.Contact_Status__c = '1. New';        
        
        try{
            update testContact;
        }catch(Exception e) {}
        
        ///test.stopTest();
        
        //TriggerHandler.BY_PASS_CONTACT_ON_INSERT = false;
        //TriggerHandler.BY_PASS_CONTACT_ON_UPDATE = false;
        //TriggerHandler.BY_PASS_CONTACT_ON_AFTER = false;      
        
        testContact.Contact_Status__c = '0. Downgraded';
        
        try{
            update testContact;
        }catch(Exception e) {}
    
    TriggerHandler.RESET_VARIABLES();
    
    }
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void DFR_ContactStatusChange2_TEST() {
      TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT();
        TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE();
        TriggerHandler.BY_PASS_CONTACT_ON_INSERT();
        TriggerHandler.BY_PASS_CONTACT_ON_UPDATE();
        TriggerHandler.BY_PASS_OPPORTUNITY_ON_INSERT();
        TriggerHandler.BY_PASS_OPPORTUNITY_ON_UPDATE();
        
        Test.startTest(); 
        
        //Create as Prospect
        Lead l4 = new Lead(
            Status = 'X. Open',
            LeadSource = 'Inbound Call', 
            State ='CA', 
            Phone = '+1.213.111.1111', 
            LastName = 'TEST', 
            FirstName = 'TEST', 
            Company = 'xxAugusto Bisdaxx',
            Email = 'aaabisda@aaabisda.net', 
            Country = 'USA',
          Number_of_Users__c = 20,
          Forecasted_Contact_Center_Users__c = 20,
          Industry = 'Education',
          Employees_Override__c = 'Just Me',
          Lead_Tier_Name__c = 'Office',
          RC_Edition__c = 'Standard',
          RC_Term__c = 'Monthly');
        
        try{
            insert l4;
        }catch(Exception e) {}                 
                    
        Test.stopTest();        
        
        //Convert Lead from MQL         
        Database.LeadConvert lc = new database.LeadConvert();
        lc.setLeadId(l4.Id);
        lc.setDoNotCreateOpportunity(true);        
        lc.setConvertedStatus('2. Contacted'); 
        
        Database.LeadConvertResult lcr = Database.convertLead(lc); 
        
        TriggerHandler.BY_PASS_CONTACT_ON_INSERT = false;
        TriggerHandler.BY_PASS_CONTACT_ON_UPDATE = false;
        TriggerHandler.BY_PASS_CONTACT_ON_AFTER = false;  
        
        map<Id, Contact> mapContact = new map<Id, Contact>();
        
        mapContact.put(lcr.getContactId(), new Contact(Id=lcr.getContactId(),Contact_Status__c='1. New'));
        
        try{
            update mapContact.values();
        }catch(Exception e) {}
        
        TriggerHandler.RESET_VARIABLES();
    }
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void DFR_OpportunityClosed_TEST(){
        test.startTest();
        
        Account testAcc = new Account();        
        testAcc.Name = 'my test account';
        
        try{
            insert testAcc;
        }catch(Exception e) {}
        
        Opportunity testOpp = new Opportunity();        
        testOpp.Name = 'my test opportunity';
        testOpp.StageName = '3. Qualified';
        testOpp.CloseDate = System.today();     
        testOpp.AccountId = testAcc.Id;
        
        try{
            insert testOpp;
        }catch(Exception e) {}
        
        Contact testContact = new Contact();        
        testContact.FirstName = 'firstname';
        testContact.LastName = 'lastname';
        testContact.Email = 'ab1@ab1.com';      
        testContact.AccountId = testAcc.Id;
        testContact.Contact_Funnel_Type__c = 'Prospect';
        
        try{
            insert testContact;
        }catch(Exception e) {}
        
        TriggerHandler.BY_PASS_CONTACT_ON_INSERT = false;
        TriggerHandler.BY_PASS_CONTACT_ON_UPDATE = false;
        TriggerHandler.BY_PASS_CONTACT_ON_AFTER = false;   
        
        testContact.Contact_Status__c = '1. New';
        
        try{
            update testContact;
        }catch(Exception e) {}
        
        test.stopTest();
        
        testOpp.StageName = '0. Downgraded';
        testOpp.Downgrade_Reason_Opp__c = 'Unable to Contact';
        testOpp.Sub_Downgrade_Reason__c = 'No Response';
        
        try{
            update testOpp;
        }catch(Exception e) {}
    }
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void DFR_AddOpportunityToExistingDFR_TEST(){
        test.startTest();
        
        Account testAcc = new Account();        
        testAcc.Name = 'my test account';
        
        try{
            insert testAcc;
        }catch(Exception e) {}
                
        Contact testContact = new Contact();        
        testContact.FirstName = 'firstname';
        testContact.LastName = 'lastname';
        testContact.Email = 'ab1@ab1.com';      
        testContact.AccountId = testAcc.Id;
        testContact.Contact_Funnel_Type__c = 'Prospect';
        
        try{
            insert testContact;
        }catch(Exception e) {}
        
        TriggerHandler.BY_PASS_CONTACT_ON_INSERT = false;
        TriggerHandler.BY_PASS_CONTACT_ON_UPDATE = false;
        TriggerHandler.BY_PASS_CONTACT_ON_AFTER = false;   
        
        testContact.Contact_Status__c = '1. New';
        
        try{
            update testContact;
        }catch(Exception e) {}
        
        test.stopTest();
        
        Opportunity testOpp = new Opportunity();        
        testOpp.Name = 'my test opportunity';
        testOpp.StageName = '3. Qualified';
        testOpp.CloseDate = System.today();     
        testOpp.AccountId = testAcc.Id;
        
        try{
            insert testOpp;
        }catch(Exception e) {}
    }
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
   @isTest
    static void DFR_AddOpportunityWithoutDFR_TEST(){
        test.startTest();
        
        Account testAcc = new Account();        
        testAcc.Name = 'my test account';
        
        try{
            insert testAcc;
        }catch(Exception e) {}
                
        Contact testContact = new Contact();        
        testContact.FirstName = 'firstname';
        testContact.LastName = 'lastname';
        testContact.Email = 'ab1@ab1.com';      
        testContact.AccountId = testAcc.Id;
        testContact.Contact_Funnel_Type__c = 'Prospect';
        
        try{
            insert testContact;
        }catch(Exception e) {}
        
        TriggerHandler.BY_PASS_CONTACT_ON_INSERT = false;
        TriggerHandler.BY_PASS_CONTACT_ON_UPDATE = false;
        TriggerHandler.BY_PASS_CONTACT_ON_AFTER = false;   
        
        testContact.Contact_Status__c = '1. New';
        
        try{
            update testContact;   
        }catch(Exception e) {}
        
        test.stopTest();     
        
        Opportunity testOpp = new Opportunity();        
        testOpp.Name = 'my test opportunity';
        testOpp.StageName = '3. Qualified';
        testOpp.CloseDate = System.today();     
        testOpp.AccountId = testAcc.Id;
        testOpp.Primary_Opportunity_Contact__c = testContact.Id;
        
        try{
            insert testOpp;
        }catch(Exception e) {}
    }
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void DFR_AddOpportunityWithDFR_TEST(){
        TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT();
        TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE();
        TriggerHandler.BY_PASS_CONTACT_ON_INSERT();
        TriggerHandler.BY_PASS_CONTACT_ON_UPDATE();
        TriggerHandler.BY_PASS_OPPORTUNITY_ON_INSERT();
        TriggerHandler.BY_PASS_OPPORTUNITY_ON_UPDATE();
        
        Test.startTest(); 
        
        //Create as Prospect
        Lead l4 = new Lead(
            Status = 'X. Open',
            LeadSource = 'Inbound Call', 
            State ='CA', 
            Phone = '+1.213.111.1111', 
            LastName = 'TEST', 
            FirstName = 'TEST', 
            Company = 'xxAugusto Bisdaxx',
            Email = 'aaabisda@aaabisda.net', 
            Country = 'USA',
          Number_of_Users__c = 20,
          Forecasted_Contact_Center_Users__c = 20,
          Industry = 'Education',
          Employees_Override__c = 'Just Me',
          Lead_Tier_Name__c = 'Office',
          RC_Edition__c = 'Standard',
          RC_Term__c = 'Monthly');
        
        try{
            insert l4;
        }catch(Exception e) {}                 
                    
        Test.stopTest();        
        
        //Convert Lead from MQL         
        Database.LeadConvert lc = new database.LeadConvert();
        lc.setLeadId(l4.Id);
        lc.setDoNotCreateOpportunity(true);        
        lc.setConvertedStatus('2. Contacted'); 
        
        Database.LeadConvertResult lcr = Database.convertLead(lc);      
        
        Opportunity testOpp = new Opportunity();        
        testOpp.Name = 'my test opportunity';
        testOpp.StageName = '3. Qualified';
        testOpp.CloseDate = System.today();     
        testOpp.AccountId = lcr.getAccountId();
        testOpp.Primary_Opportunity_Contact__c = lcr.getContactId();
        
        try{
            insert testOpp;
        }catch(Exception e) {}
        
        TriggerHandler.RESET_VARIABLES();
    }   

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void SALHandOff_OnUpdate_TEST() {
        TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT();
        TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE();
        TriggerHandler.BY_PASS_CONTACT_ON_INSERT();
        TriggerHandler.BY_PASS_CONTACT_ON_UPDATE();
        TriggerHandler.BY_PASS_OPPORTUNITY_ON_INSERT();
        TriggerHandler.BY_PASS_OPPORTUNITY_ON_UPDATE();
        
        Test.startTest();
        
        User SDRUser;
        
        try{
            SDRUser = [Select u.id, u.name, u.UserRole.Name, u.UserRoleId, u.Profile.Name, u.ProfileId
                From User u where u.Profile.Name like '%SDR%' and IsActive = True LIMIT 1]; 
        }catch(exception e){}
        
        system.debug('### SDR Profile: ' + SDRUser.Profile.Name);
        
        //Created as SAL
        Lead l1 = new Lead(
            Status = '1.5 Call Out',
            LeadSource = 'Inbound Call', 
            State ='CA', 
            Phone = '+1.213.111.1111', 
            LastName = 'TEST', 
            FirstName = 'TEST', 
            Company = 'xxAugusto Bisdaxx',
            Email = 'aaabisda@aaabisda.net', 
            Country = 'USA',
          Number_of_Users__c = 20,
          Forecasted_Contact_Center_Users__c = 20,
          Industry = 'Education',
          Employees_Override__c = 'Just Me',
          Lead_Tier_Name__c = 'Office',
          RC_Edition__c = 'Standard',
          RC_Term__c = 'Monthly');
            
        try{
            insert l1;
        }catch(Exception e) {}
        
        try{
            l1.OwnerId = SDRUser.Id;
            update l1;
        }catch(Exception e) {}
        
        try{
            system.debug('### Current Profile: ' + UserInfo.getProfileId());
            l1.OwnerId = UserInfo.getUserId();
            update l1;
        }catch(Exception e) {}
         
        Test.stopTest();
    }
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void CreateAsTALTQLLeads() {
        TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT();
        TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE();
        TriggerHandler.BY_PASS_CONTACT_ON_INSERT();
        TriggerHandler.BY_PASS_CONTACT_ON_UPDATE();
        TriggerHandler.BY_PASS_OPPORTUNITY_ON_INSERT();
        TriggerHandler.BY_PASS_OPPORTUNITY_ON_UPDATE();
        Test.startTest();
        List<Lead> listLead = new List<Lead>();    
        
        list<Id> listQueueId = new list<Id>();
        for(QueueSobject q : [Select q.Queue.Name, q.QueueId From QueueSobject q where q.SobjectType = 'Lead']){
            listQueueId.add(q.QueueId);
        } 
        
        if(!listQueueId.isEmpty()){
            //Created as TAL
            Lead l1 = new Lead(
                Status = '1.5 Call Out',
                LeadSource = 'Inbound Call', 
                State ='CA', 
                Phone = '+1.213.111.1111', 
                LastName = 'TEST', 
                FirstName = 'TEST', 
                Company = 'xxAugusto Bisdaxx',
                Email = 'aaabisda@aaabisda.net', 
                Country = 'USA',
                OwnerId = listQueueId[0],
            Number_of_Users__c = 20,
            Forecasted_Contact_Center_Users__c = 20,
            Industry = 'Education',
            Employees_Override__c = 'Just Me',
            Lead_Tier_Name__c = 'Office',
            RC_Edition__c = 'Standard',
            RC_Term__c = 'Monthly');
                
            listLead.add(l1);
            
            //Created as TAL
            Lead l2 = new Lead(
                Status = '2. Contacted',
                LeadSource = 'Inbound Call', 
                State ='CA', 
                Phone = '+1.213.111.1111', 
                LastName = 'TEST', 
                FirstName = 'TEST', 
                Company = 'xxAugusto Bisdaxx',
                Email = 'aaabisda@aaabisda.net', 
                Country = 'USA',
                OwnerId = listQueueId[0],
            Number_of_Users__c = 20,
            Forecasted_Contact_Center_Users__c = 20,
            Industry = 'Education',
            Employees_Override__c = 'Just Me',
            Lead_Tier_Name__c = 'Office',
            RC_Edition__c = 'Standard',
            RC_Term__c = 'Monthly');
                
            listLead.add(l2);
            
            //Created as Suspect
            Lead l3 = new Lead(
                Status = 'X. Open',
                LeadSource = 'Inbound Call', 
                State ='CA', 
                Phone = '+1.213.111.1111', 
                LastName = 'TEST', 
                FirstName = 'TEST', 
                Company = 'xxAugusto Bisdaxx',
                Email = 'aaabisda@aaabisda.net', 
                Country = 'USA',
                OwnerId = listQueueId[0],
            Number_of_Users__c = 20,
            Forecasted_Contact_Center_Users__c = 20,
            Industry = 'Education',
            Employees_Override__c = 'Just Me',
            Lead_Tier_Name__c = 'Office',
            RC_Edition__c = 'Standard',
            RC_Term__c = 'Monthly');
                
            listLead.add(l3);
            
            try{
                insert listLead;
            }catch(Exception e) {}
                        
            Test.stopTest();
            
            //Move leads to TQL
            
            list<Task> listTask = new list<Task>();
            
            Task e1 = new Task(
                WhoId = l1.Id,
                Subject = 'Lead Task',
                ActivityDate = date.today(),
                SDR_Meeting_Status__c = 'Scheduled'
            );
            
            listTask.add(e1);
            
            //Move to SAL            
            Task e2 = new Task(
                WhoId = l2.Id,
                Subject = 'Lead Task',
                ActivityDate = date.today(),
                SDR_Meeting_Status__c = 'Accepted'
            );
            
            listTask.add(e2);
            
            Task e3 = new Task(
                WhoId = l3.Id,
                Subject = 'Lead Task',
                ActivityDate = date.today(),
                SDR_Meeting_Status__c = 'Accepted'
            );
            
            try{
                insert listTask;
            }catch(Exception e) {}   
            
            //Move to SAL
            e1.SDR_Meeting_Status__c = 'Accepted';
            e2.SDR_Meeting_Status__c = 'Accepted';
            
            try{
                update listTask;
            }catch(Exception e) {}  
             List<String> bindings = new List<String>();
            bindings.add(String.valueOf(l2.id));
             List<Demand_Funnel__c> dfrList =  new DemandFunnelSelector()
                                          .selectDFRByLeadID(bindings)
                                          .selectFields(new List<String>{'SAL_DateTime_Entered__c', 
                                                                         'SAL_DateTime_Exited__c','SAL_Lead_Source__c','SAL_Lead_Entry_Source__c',
                                          								 'SAL_Campaign__c','SAL_Demographic_Score__c','SAL_Behavior_Score__c',
                                              							 'SAL_Score__c','SAL_BMID__c','SAL_PID__c','SAL_AID__c','SAL_Purchase_Timeframe__c',
                                              							 'SAL_Lead_Score_Category__c','SAL_Employee_Size__c','SAL_Owner_Role__c','SAL_Owner_Name__c',
                                              'SAL_Owner_Id__c','SAL_Owner_Division__c','SAL_Owner_Segment__c','SAL_Owner_Territory__c','SAL_Owner_Team__c','SAL_Entered_From__c','SAL_Exited_To__c',
                                              'SAL_Handoff_Date__c','SAL_Handoff_Owner__c','SAL_Handoff_Owner_Role__c',
                                              'TAL_DateTime_Entered__c','TAL_Demographic_Score__c','TAL_Behavior_Score__c','TAL_Score__c',
											  'TAL_DateTime_Exited__c','TAL_Lead_Source__c','TAL_Lead_Entry_Source__c','TAL_Campaign__c' ,
											  'TAL_BMID__c','TAL_PID__c','TAL_AID__c','TAL_Purchase_Timeframe__c','TAL_Lead_Score_Category__c',
                                              'TAL_Employee_Size__c', 'TAL_Owner_Role__c' ,'TAL_Owner_Name__c','TAL_Entered_From__c','TAL_Owner_Team__c' ,
											  'TAL_Owner_Id__c','TAL_Owner_Division__c','TAL_Owner_Segment__c','TAL_Owner_Territory__c','TAL_Owner_Team__c','TAL_Owner_Role__c', 
											  'TAL_Owner_Name__c' ,'TAL_Owner_Id__c','TAL_Owner_Division__c' ,'TAL_Owner_Segment__c' ,'TAL_Exited_To__c'
                                              })
                                          .executeQuery();
            DG_DFR_Class_Helper.setSALStampingToNull(dfrList[0]);
            DG_DFR_Class_Helper.setTALStampingToNull(dfrList[0]);
        }
    }
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void UpdateToTALTQLLeads() {
        TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT();
        TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE();
        TriggerHandler.BY_PASS_CONTACT_ON_INSERT();
        TriggerHandler.BY_PASS_CONTACT_ON_UPDATE();
        TriggerHandler.BY_PASS_OPPORTUNITY_ON_INSERT();
        TriggerHandler.BY_PASS_OPPORTUNITY_ON_UPDATE();
        Test.startTest();
        List<Lead> listLead = new List<Lead>();    
        
        list<Id> listQueueId = new list<Id>();
        for(QueueSobject q : [Select q.Queue.Name, q.QueueId From QueueSobject q where q.SobjectType = 'Lead']){
            listQueueId.add(q.QueueId);
        } 
        
        if(!listQueueId.isEmpty()){
            
            //Create as Suspect
            Lead l1 = new Lead(
                Status = 'X. Suspect',
                LeadSource = 'Inbound Call', 
                State ='CA', 
                Phone = '+1.213.111.1111', 
                LastName = 'TEST', 
                FirstName = 'TEST', 
                Company = 'xxAugusto Bisdaxx',
                Email = 'aaabisda@aaabisda.net', 
                Country = 'USA',
                OwnerId = listQueueId[0],
            Number_of_Users__c = 20,
            Forecasted_Contact_Center_Users__c = 20,
            Industry = 'Education',
            Employees_Override__c = 'Just Me',
            Lead_Tier_Name__c = 'Office',
            RC_Edition__c = 'Standard',
            RC_Term__c = 'Monthly');
                
            listLead.add(l1);
            
            //Create as Prospect
            Lead l2 = new Lead(
                Status = 'X. Open',
                LeadSource = 'Inbound Call', 
                State ='CA', 
                Phone = '+1.213.111.1111', 
                LastName = 'TEST', 
                FirstName = 'TEST', 
                Company = 'xxAugusto Bisdaxx',
                Email = 'aaabisda@aaabisda.net', 
                Country = 'USA',
                OwnerId = listQueueId[0],
            Number_of_Users__c = 20,
            Forecasted_Contact_Center_Users__c = 20,
            Industry = 'Education',
            Employees_Override__c = 'Just Me',
            Lead_Tier_Name__c = 'Office',
            RC_Edition__c = 'Standard',
            RC_Term__c = 'Monthly');
                
            listLead.add(l2);
            
            //Create as MQL
            Lead l3 = new Lead(
                Status = '1. New',
                LeadSource = 'Inbound Call', 
                State ='CA', 
                Phone = '+1.213.111.1111', 
                LastName = 'TEST', 
                FirstName = 'TEST', 
                Company = 'xxAugusto Bisdaxx',
                Email = 'aaabisda@aaabisda.net', 
                Country = 'USA',
                OwnerId = listQueueId[0],
            Number_of_Users__c = 20,
            Forecasted_Contact_Center_Users__c = 20,
            Industry = 'Education',
            Employees_Override__c = 'Just Me',
            Lead_Tier_Name__c = 'Office',
            RC_Edition__c = 'Standard',
            RC_Term__c = 'Monthly');
                
            listLead.add(l3);            
            
             //Create as Suspect
            Lead l4 = new Lead(
                Status = 'X. Suspect',
                LeadSource = 'Inbound Call', 
                State ='CA', 
                Phone = '+1.213.111.1111', 
                LastName = 'TEST', 
                FirstName = 'TEST', 
                Company = 'xxAugusto Bisdaxx',
                Email = 'aaabisda@aaabisda.net', 
                Country = 'USA',
                OwnerId = listQueueId[0],
            Number_of_Users__c = 20,
            Forecasted_Contact_Center_Users__c = 20,
            Industry = 'Education',
            Employees_Override__c = 'Just Me',
            Lead_Tier_Name__c = 'Office',
            RC_Edition__c = 'Standard',
            RC_Term__c = 'Monthly');
                
            listLead.add(l4);
            
            //Create as Prospect
            Lead l5 = new Lead(
                Status = 'X. Open',
                LeadSource = 'Inbound Call', 
                State ='CA', 
                Phone = '+1.213.111.1111', 
                LastName = 'TEST', 
                FirstName = 'TEST', 
                Company = 'xxAugusto Bisdaxx',
                Email = 'aaabisda@aaabisda.net', 
                Country = 'USA',
                OwnerId = listQueueId[0],
            Number_of_Users__c = 20,
            Forecasted_Contact_Center_Users__c = 20,
            Industry = 'Education',
            Employees_Override__c = 'Just Me',
            Lead_Tier_Name__c = 'Office',
            RC_Edition__c = 'Standard',
            RC_Term__c = 'Monthly');
                
            listLead.add(l5);
            
            //Create as MQL
            Lead l6 = new Lead(
                Status = '1. New', 
                LeadSource = 'Inbound Call', 
                State ='CA', 
                Phone = '+1.213.111.1111', 
                LastName = 'TEST', 
                FirstName = 'TEST', 
                Company = 'xxAugusto Bisdaxx',
                Email = 'aaabisda@aaabisda.net', 
                Country = 'USA',
                OwnerId = listQueueId[0],
            Number_of_Users__c = 20,
            Forecasted_Contact_Center_Users__c = 20,
            Industry = 'Education',
            Employees_Override__c = 'Just Me',
            Lead_Tier_Name__c = 'Office',
            RC_Edition__c = 'Standard',
            RC_Term__c = 'Monthly');
                
            listLead.add(l6);
            
            try{
                insert listLead;
            }catch(Exception e) {}
            
            Test.stopTest();
            
            //Move leads to TAL         
            l1.status = '1.5 Call Out';
            l2.status = '1.5 Call Out';
            l3.status = '1.5 Call Out';
            
            try{
                update listLead;
            }catch(Exception e) {}          
  
            
            //Move leads to TQL
            list<Task> listTask = new list<Task>();
                        
            Task e4 = new Task(
                WhoId = l4.Id,
                Subject = 'Lead Task',
                ActivityDate = date.today(),
                SDR_Meeting_Status__c = 'Scheduled'
            );
            
            listTask.add(e4);
            
            Task e5 = new Task(
                WhoId = l5.Id,
                Subject = 'Lead Task',
                ActivityDate = date.today(),
                SDR_Meeting_Status__c = 'Scheduled'
            );
            
            listTask.add(e5);
            
            Task e6 = new Task(
                WhoId = l6.Id,
                Subject = 'Lead Task',
                ActivityDate = date.today(),
                SDR_Meeting_Status__c = 'Scheduled'
            );
            
            listTask.add(e6);
            
            try{
                insert listTask;
            }catch(Exception e) {}              
        }
    }
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void MQLHandoff() {
        TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT();
        TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE();
        TriggerHandler.BY_PASS_CONTACT_ON_INSERT();
        TriggerHandler.BY_PASS_CONTACT_ON_UPDATE();
        TriggerHandler.BY_PASS_OPPORTUNITY_ON_INSERT();
        TriggerHandler.BY_PASS_OPPORTUNITY_ON_UPDATE();
        Test.startTest();
        List<Lead> listLead = new List<Lead>();    
        
        list<Id> listQueueId = new list<Id>();
        for(QueueSobject q : [Select q.Queue.Name, q.QueueId From QueueSobject q where q.SobjectType = 'Lead']){
            listQueueId.add(q.QueueId);
        } 
        
        if(!listQueueId.isEmpty()){
            //Created as MQL
            Lead l1 = new Lead(
                Status = 'X. Open',
                LeadSource = 'Inbound Call', 
                State ='CA', 
                Phone = '+1.213.111.1111', 
                LastName = 'TEST', 
                FirstName = 'TEST', 
                Company = 'xxAugusto Bisdaxx',
                Email = 'aaabisda@aaabisda.net', 
                Country = 'USA',
                OwnerId = listQueueId[0],
            Number_of_Users__c = 20,
            Forecasted_Contact_Center_Users__c = 20,
            Industry = 'Education',
            Employees_Override__c = 'Just Me',
            Lead_Tier_Name__c = 'Office',
            RC_Edition__c = 'Standard',
            RC_Term__c = 'Monthly');
                
            listLead.add(l1);
            
            //Created as MQL
            Lead l2 = new Lead(
                Status = 'X. Open',
                LeadSource = 'Inbound Call', 
                State ='CA', 
                Phone = '+1.213.111.1111', 
                LastName = 'TEST', 
                FirstName = 'TEST', 
                Company = 'xxAugusto Bisdaxx',
                Email = 'aaabisda@aaabisda.net', 
                Country = 'USA',
                OwnerId = listQueueId[0],
            Number_of_Users__c = 20,
            Forecasted_Contact_Center_Users__c = 20,
            Industry = 'Education',
            Employees_Override__c = 'Just Me',
            Lead_Tier_Name__c = 'Office',
            RC_Edition__c = 'Standard',
            RC_Term__c = 'Monthly');
                
            listLead.add(l2);
            
            try{
                insert listLead;
            }catch(Exception e) {}
            
            Test.stopTest();
            
            //Change owner from Queue to User
            Profile p = [SELECT Id FROM Profile WHERE Name='Standard User']; 
            User u = new User(Alias = 'standt', Email='standarduser@dfr.com', 
                EmailEncodingKey='UTF-8', LastName='DFRTesting', LanguageLocaleKey='en_US', 
                LocaleSidKey='en_US', ProfileId = p.Id, 
                TimeZoneSidKey='America/Los_Angeles', UserName='standarduser@dfr.com');
            
            l1.OwnerId = u.Id;
            l2.OwnerId = u.Id;
            
            try{
                update listLead;
            }catch(Exception e) {}          
            
        }
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')    
    @isTest
    static void DFR_ConvertTALLead_Test() {
        TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT();
        TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE();
        TriggerHandler.BY_PASS_CONTACT_ON_INSERT();
        TriggerHandler.BY_PASS_CONTACT_ON_UPDATE();
        TriggerHandler.BY_PASS_OPPORTUNITY_ON_INSERT();
        TriggerHandler.BY_PASS_OPPORTUNITY_ON_UPDATE();
        Test.startTest();  
        
        User SDRUser;
        
        try{
            SDRUser = [Select u.id, u.name, u.UserRole.Name, u.UserRoleId, u.Profile.Name, u.ProfileId
                From User u where u.Profile.Name like '%SDR%' and IsActive = True LIMIT 1]; 
        }catch(exception e){}                    

        //Create as TAL
        Lead l4 = new Lead(
            Status = '1.5 Call Out',
            LeadSource = 'Inbound Call', 
            State ='CA', 
            Phone = '+1.213.111.1111', 
            LastName = 'TEST', 
            FirstName = 'TEST', 
            Company = 'xxAugusto Bisdaxx',
            Email = 'aaabisda@aaabisda.net', 
            Country = 'USA',
            OwnerId = SDRUser.Id,
          Number_of_Users__c = 20,
          Forecasted_Contact_Center_Users__c = 20,
          Industry = 'Education',
          Employees_Override__c = 'Just Me',
          Lead_Tier_Name__c = 'Office',
          RC_Edition__c = 'Standard',
          RC_Term__c = 'Monthly');
        
        try{
            insert l4;
        }catch(Exception e) {}                 
                    
        Test.stopTest();        
        
        //Convert Lead from TAL         
        Database.LeadConvert lc = new database.LeadConvert();
        lc.setLeadId(l4.Id);        
        lc.setConvertedStatus('2. Contacted');  

        try {   
            Database.convertLead(lc);
        }catch(Exception e) {} 
    }
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void DFR_ConvertTQLLead_Test() {
        TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT();
        TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE();
        TriggerHandler.BY_PASS_CONTACT_ON_INSERT();
        TriggerHandler.BY_PASS_CONTACT_ON_UPDATE();
        TriggerHandler.BY_PASS_OPPORTUNITY_ON_INSERT();
        TriggerHandler.BY_PASS_OPPORTUNITY_ON_UPDATE();
        Test.startTest();  
        
        User SDRUser;
        
        try{
            SDRUser = [Select u.id, u.name, u.UserRole.Name, u.UserRoleId, u.Profile.Name, u.ProfileId
                From User u where u.Profile.Name like '%SDR%' and IsActive = True LIMIT 1]; 
        }catch(exception e){}                    

        //Create as TAL
        Lead l4 = new Lead(
            Status = '1.5 Call Out',
            LeadSource = 'Inbound Call', 
            State ='CA', 
            Phone = '+1.213.111.1111', 
            LastName = 'TEST', 
            FirstName = 'TEST', 
            Company = 'xxAugusto Bisdaxx',
            Email = 'aaabisda@aaabisda.net', 
            Country = 'USA',
            OwnerId = SDRUser.Id,
          Number_of_Users__c = 20,
          Forecasted_Contact_Center_Users__c = 20,
          Industry = 'Education',
          Employees_Override__c = 'Just Me',
          Lead_Tier_Name__c = 'Office',
          RC_Edition__c = 'Standard',
          RC_Term__c = 'Monthly');
        
        try{
            insert l4;
        }catch(Exception e) {}       
        
        Task e4 = new Task(
            WhoId = l4.Id,
            Subject = 'Lead Event',
            ActivityDate = date.today(),
            SDR_Meeting_Status__c = 'Scheduled'
        );

        try{
            insert e4;
        }catch(Exception e) {}    
                    
        Test.stopTest();        
        
        //Convert Lead from TAL         
        Database.LeadConvert lc = new database.LeadConvert();
        lc.setLeadId(l4.Id);        
        lc.setConvertedStatus('2. Contacted');  

        try {   
            Database.convertLead(lc);
        }catch(Exception e) {} 
    }
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void DFR_ConvertSALLead_Test() {
        TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT();
        TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE();
        TriggerHandler.BY_PASS_CONTACT_ON_INSERT();
        TriggerHandler.BY_PASS_CONTACT_ON_UPDATE();
        TriggerHandler.BY_PASS_OPPORTUNITY_ON_INSERT();
        TriggerHandler.BY_PASS_OPPORTUNITY_ON_UPDATE();
        Test.startTest();  
        
        User SDRUser;
        
        //Create as SAL
        Lead l4 = new Lead(
            Status = '1.5 Call Out',
            LeadSource = 'Inbound Call', 
            State ='CA', 
            Phone = '+1.213.111.1111', 
            LastName = 'TEST', 
            FirstName = 'TEST', 
            Company = 'xxAugusto Bisdaxx',
            Email = 'aaabisda@aaabisda.net', 
            Country = 'USA',
          Number_of_Users__c = 20,
          Forecasted_Contact_Center_Users__c = 20,
          Industry = 'Education',
          Employees_Override__c = 'Just Me',
          Lead_Tier_Name__c = 'Office',
          RC_Edition__c = 'Standard',
          RC_Term__c = 'Monthly');
        
        try{
            insert l4;
        }catch(Exception e) {}                 
                    
        Test.stopTest();        
        
        //Convert Lead from TAL         
        Database.LeadConvert lc = new database.LeadConvert();
        lc.setLeadId(l4.Id);        
        lc.setConvertedStatus('2. Contacted');  

        try {   
            Database.convertLead(lc);
        }catch(Exception e) {} 
    }

    @isTest
    static void DFR_BulkConvert_Test() {
        TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT();
        TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE();
        TriggerHandler.BY_PASS_CONTACT_ON_INSERT();
        TriggerHandler.BY_PASS_CONTACT_ON_UPDATE();
        TriggerHandler.BY_PASS_OPPORTUNITY_ON_INSERT();
        TriggerHandler.BY_PASS_OPPORTUNITY_ON_UPDATE();

        User SDRUser;

        //Create as SAL
        Lead l4 = new Lead(
            Status = '2. Contacted',
            LeadSource = 'Inbound Call',
            State ='CA',
            Phone = '+1.213.111.1111',
            LastName = 'TEST',
            FirstName = 'TEST',
            Company = 'xxAugusto Bisdaxx',
            Email = 'aaabisda@aaabisda.net',
            Country = 'USA',
          Number_of_Users__c = 20,
          Forecasted_Contact_Center_Users__c = 20,
          Industry = 'Education',
          Employees_Override__c = 'Just Me',
          Lead_Tier_Name__c = 'Office',
          RC_Edition__c = 'Standard',
          RC_Term__c = 'Monthly');

          Lead l5 = new Lead(
              Status = '2. Contacted',
              LeadSource = 'Inbound Call',
              State ='CA',
              Phone = '+1.213.111.1111',
              LastName = 'TEST',
              FirstName = 'TEST',
              Company = 'xxAugusto Bisdaxx',
              Email = 'aaabisda@aaabisda.net',
              Country = 'USA',
            Number_of_Users__c = 20,
            Forecasted_Contact_Center_Users__c = 20,
            Industry = 'Education',
            Employees_Override__c = 'Just Me',
            Lead_Tier_Name__c = 'Office',
            RC_Edition__c = 'Standard',
            RC_Term__c = 'Monthly');

        List<Lead> testLeads = new List<Lead>{l4, l5};

        insert testLeads;

        List<Database.LeadConvert> leadConverts = new List<Database.LeadConvert>();
        Database.LeadConvert lc4 = new database.LeadConvert();
        lc4.setLeadId(l4.Id);
        leadConverts.add(lc4);
        lc4.setConvertedStatus('2. Contacted');

        Database.LeadConvert lc5 = new database.LeadConvert();
        lc5.setLeadId(l5.Id);
        leadConverts.add(lc5);
        lc5.setConvertedStatus('2. Contacted');

        Database.LeadConvertResult[] lcrList;

        Test.startTest();
            lcrList = Database.convertLead(leadConverts, false);
        Test.stopTest();

        for (Database.LeadConvertResult dlcr : lcrList){
            System.debug('### '+dlcr);
        }

        System.assertEquals(true, lcrList[0].isSuccess(), 'should be converted');
        System.assertEquals(true, lcrList[0].isSuccess(), 'should be converted');
    }

    @isTest
    static void testOnCreationFieldsNotNullIfLeadCreatedOnTAL() {
        Emails__c email1 = (Emails__c) new SObjectBuilder(Emails__c.SObjectType)
                                        .setField(Emails__c.Name, 'rcsfsyncuser')
                                        .setField(Emails__c.Email_Address__c, 'test@test.com')
                                        .build()
                                        .getRecord();
        
        Emails__c email2 = (Emails__c) new SObjectBuilder(Emails__c.SObjectType)
                                        .setField(Emails__c.Name, 'suniluser')
                                        .setField(Emails__c.Email_Address__c, 'test@test.com')
                                        .build()
                                        .getRecord();

        List<Emails__c> emails = new List<Emails__c>();
        emails.add(email1);
        emails.add(email2);
        insert emails;

        Lead lead = (Lead) new SObjectBuilder(Lead.SObjectType)
                                        .setField(Lead.LastName, 'someLead')
                                        .setField(Lead.Email, 'somelead@fortest.com')
                                        .setField(Lead.Industry, 'Other')
                                        .setField(Lead.Phone, '123456890')
                                        .setField(Lead.LeadSource, 'Inbound Call')
                                        .setField(Lead.Status, '.5 Re-New')
                                        .create()
                                        .getRecord();
        
        User aeUser = (User) new SObjectBuilder (User.SObjectType)
                                        .setFields(SObjectFactoryFieldDefaults.getDefaults(User.SObjectType))
                                        .setField(User.LastName, 'AltOwnerLastName')
                                        .setField(User.FirstName, 'AltOwnerFirstName')
                                        .setField(User.Team__c, 'DEFAULT')
                                        .create()
                                        .getRecord();

        lead.OwnerId = aeUser.Id;
        update lead;

        Test.startTest();
        lead.Status = '1.5 Call Out';
        update lead;
        Test.stopTest();

        List<Object> bindings = new List<Object>();
        bindings.add(lead.Id);
        List<Demand_Funnel__c> dfrList =  new DemandFunnelSelector()
                                          .selectDFRByLeadID(bindings)
                                          .selectFields(new List<String>{'Lead_Name_on_Creation__c', 
                                                                         'Lead_Email_on_Creation__c'})
                                          .executeQuery();

        System.assert(dfrList[0] != null, 'A Demand funnel record should have been created');
        System.assertEquals('someLead', dfrList[0].Lead_Name_on_Creation__c, 
                            'The Demand funnel record should have lead name on creation field populated with the leads name');
        System.assertEquals('somelead@fortest.com', dfrList[0].Lead_Email_on_Creation__c, 
                            'The Demand funnel record should have lead email on creation field populated with the leads email');

    }
}