@isTest
private class Test_LeadQualificationView {

    @isTest
    private static void testSalesProfileUser() {
        Account accObj = new Account();
        accObj.Name = 'Test Account Parent ';
        accObj.Partner_ID__c = '12346';
        insert accObj;
        
        Lead lead = (Lead) new SObjectBuilder(Lead.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Lead.email => 'fake@email.com',
                    Lead.LastName => 'fakeLastName',
                    Lead.Company => 'fakeCompany'
                }
            )
            .create()
            .getRecord();

        Lead_Qualification__c lq = new Lead_Qualification__c();
        lq.Lead__c = lead.Id;
        lq.Reasons__c='Slow to respond';
        lq.Who_is_Decision_Maker__c='Test';
        lq.More_Info_on_Budgeted__c='test';
        lq.Account__c= accObj.id;
        insert lq;

        User us = (User) new SObjectBuilder (User.SObjectType)        
            .setFields(
                new Map<SObjectField, Object>{
                    User.LastName => 'TestAtt',
                    User.Username => 'Test!user@gmail.com',
                    User.Email => 'Att_user@gmail.com',
                    User.Alias => 'Test',
                    User.TimeZoneSidKey => 'America/Los_Angeles',
                    User.ManagerId => UserInfo.getUserId(),
                    User.LocaleSidKey => 'en_US',
                    User.EmailEncodingKey => 'UTF-8',
                    User.ProfileId => [SELECT Id, Name FROM Profile WHERE Name = 'Channel Sales - Lightning'].Id,
                    User.LanguageLocaleKey => 'en_US',
                    User.Hierarchy_Role__c => 'Sales Rep'
                }
            )
            .create()
            .getRecord();

        PageReference pr = new PageReference('/apex/LeadQualificationView');
        pr.getParameters().put('Id',lead.Id);
        pr.setRedirect(true);
        Test.setCurrentPage(pr);

        System.runAs(us) {
            Test.startTest();
                LeadQualificationView controller = new LeadQualificationView();
            Test.stopTest();

            System.assertEquals(controller.isSalesProfile,
                                true,
                                'Sales profile was not assigned correctly to user.');
            System.assertEquals(controller.isInsideSalesProfile,
                                false,
                                'Inside Sales profile was not assigned correctly to user.');
        }
    }

    @isTest
    private static void testSalesInsideProfileUser() {
        Lead lead = (Lead) new SObjectBuilder(Lead.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Lead.email => 'fake@email.com',
                    Lead.LastName => 'fakeLastName',
                    Lead.Company => 'fakeCompany'
                }
            )
            .create()
            .getRecord();
        Lead_Qualification__c lq = new Lead_Qualification__c();
        lq.Lead__c = lead.Id;
        lq.Reasons__c='Slow to respond';
        insert lq;

        User us = (User) new SObjectBuilder (User.SObjectType)        
            .setFields(
                new Map<SObjectField, Object>{
                    User.LastName => 'TestAtt',
                    User.Username => 'Test!user@gmail.com',
                    User.Email => 'Att_user@gmail.com',
                    User.Alias => 'Test',
                    User.TimeZoneSidKey => 'America/Los_Angeles',
                    User.ManagerId => UserInfo.getUserId(),
                    User.LocaleSidKey => 'en_US',
                    User.EmailEncodingKey => 'UTF-8',
                    User.ProfileId => [SELECT Id, Name FROM Profile WHERE Name = :ProfileHelper.PROFILE_NAME_SALES_MANAGER_WITH_INSIDESALES].Id,
                    User.LanguageLocaleKey => 'en_US',
                    User.Hierarchy_Role__c => 'Sales Rep'
                }
            )
            .create()
            .getRecord();

        PageReference pr = new PageReference('/apex/LeadQualificationView');
        pr.getParameters().put('Id',lead.Id);
        pr.setRedirect(true);
        Test.setCurrentPage(pr);

        System.runAs(us) {
            Test.startTest();
                LeadQualificationView controller = new LeadQualificationView();
            Test.stopTest();

            System.assertEquals(controller.isSalesProfile,
                                false,
                                'Sales profile was not assigned correctly to user.');
            System.assertEquals(controller.isInsideSalesProfile,
                                true,
                                'Inside Sales profile was not assigned correctly to user.');
        }
    }
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
@isTest
    private static void testSelectclick()
    {
     LeadQualificationView lv = new LeadQualificationView();
        Lead lead = (Lead) new SObjectBuilder(Lead.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Lead.email => 'fake@email.com',
                    Lead.LastName => 'fakeLastName',
                    Lead.Company => 'fakeCompany'
                }
            )
            .create()
            .getRecord();
        Lead_Qualification__c lq = new Lead_Qualification__c();
        lq.Lead__c = lead.Id;
        lq.Reasons__c='Slow to respond';
        lq.Who_is_Decision_Maker__c = 'testing string';
         //StringBuilder sb = new  StringBuilder('WelcomeGeeks');
        //sb.setLength(35000);
        String lenstr = 'test';
       // lenstr.length() = 35000;
        lq.CompanyInfo__c =lenstr;
        lq.Pain__c=lenstr;
        lq.Pain_Impact__c = lenstr;
        lq.Gain__c = lenstr;
        lq.Gain_Impact__c=lenstr;
        lq.Ideal_Solution__c=lenstr;
        lq.Benefits__c=lenstr;
        lq.Next_Steps_questions__c =lenstr;
        lq.Other_Explanation__c = lenstr;
        lq.Need__c = lenstr;
        lq.Prospect_Need__c = lenstr;
        lq.of_employees_in_org__c=lenstr;
        lq.How_many_phones_to_start__c = lenstr;
        lq.Other_Notes__c = lenstr;
        lq.Decision_on_Large_Projects__c=lenstr;
        lq.More_Info_on_Budgeted__c=lenstr;
        lq.ContractAdditionalInfo__c=lenstr;
        lq.CurrentSystemAdditionalInfo__c=lenstr;
        lq.TimeframeAdditionalInfo__c=lenstr;
        lq.Decision_makers_Additional_Information__c=lenstr;
        insert lq;
        lv.leadQualificationObj = lq;
        User us = (User) new SObjectBuilder (User.SObjectType)        
            .setFields(
                new Map<SObjectField, Object>{
                    User.LastName => 'TestAtt',
                    User.Username => 'Test!user@gmail.com',
                    User.Email => 'Att_user@gmail.com',
                    User.Alias => 'Test',
                    User.TimeZoneSidKey => 'America/Los_Angeles',
                    User.ManagerId => UserInfo.getUserId(),
                    User.LocaleSidKey => 'en_US',
                    User.EmailEncodingKey => 'UTF-8',
                    User.ProfileId => [SELECT Id, Name FROM Profile WHERE Name = :ProfileHelper.PROFILE_NAME_SALES_MANAGER_WITH_INSIDESALES].Id,
                    User.LanguageLocaleKey => 'en_US',
                    User.Hierarchy_Role__c => 'Sales Rep'
                }
            )
            .create()
            .getRecord();

        PageReference pr = new PageReference('/apex/LeadQualificationView');
        pr.getParameters().put('Id',lead.Id);
        pr.setRedirect(true);
        Test.setCurrentPage(pr);
        //System.runAs(us) {
            Test.startTest();
                LeadQualificationView controller = new LeadQualificationView();
             PageReference p = controller.selectclick();
             PageReference p2 = controller.unselectclick();
             PageReference p3 = controller.dependentReasons();
                            controller.loadLeadQualBasicDet();
            
                            controller.loadupdatedLeadQual();
                            controller.getContactInfo();
            PageReference p4 = controller.cancel();
            PageReference p5 = controller.editLeadQualDet();
                               controller.loadLeadQualDet();
                               controller.getDecisionMaker();
                               controller.showMoreInfoBudget();
            //String l =         controller.checkInputFieldLength();
         PageReference p6 = controller.updateLeadQual();
                               controller.initialiseTriggerBypass();
                               controller.setManagerAndNextStepValue();
         PageReference p7 =    controller.backToDetail();
          PageReference p8 =   controller.dependentReasons();
            Lead_Qualification__c lc2 = controller.SaveDriverResons(lq);
           Lead_Qualification__c lc3 =  controller.saveFeaturesRequestdByCustomerValues(lq);
           Lead_Qualification__c lc4 =  controller.saveUsagesLevelvalues(lq);
           Lead_Qualification__c lc5 =  controller.saveCurrentSystemInfovalues(lq);
           Lead_Qualification__c lc6 =  controller.saveCallFlowModelValues(lq);
           Lead_Qualification__c lc7 =  controller.saveFeaturesRequestdByCustomerValues(lq);
           Lead_Qualification__c lc8 =  controller.saveUsagesLevelvalues(lq);
            controller.setManagerAndNextStepValue();
           
            List<sObject> outlist = new List<sObject>();
            List<Schema.PicklistEntry> pickList = new List<Schema.PicklistEntry>();
            List<SelectOption> optionList = new List<SelectOption>();
            List<String> out = new List<String>();
             out = controller.getSelectedValueOfPickList(lq,'Business_Change_Reasons__c');
          Map<Integer,String> optionMap = new Map<Integer,String>();
          String selectFlowModel = controller.getSelectedFlowModelValues;
          optionList = controller.getBusinessAgilityResons;
          optionList = controller.getBusinessresponsivenessResons;
          optionList = controller.getBusinessVendorResons;
           optionList = controller.getAllCurrentSystemInfoValues;
            optionList = controller.getFeaturesRequestdByCustomerValues;
             optionList = controller.getUsagesLevelValues;    
            optionMap = controller.getCallFlowModelValues2;
            List<String> pickLstString = new List<String>();
            pickLstString.add('Features_Requested_by_Customer__c');
            pickLstString.add('CurrentSystemInfo__c');
            pickLstString.add('Business_Change_Reasons__c');
            pickLstString.add('Customer_Responsiveness_Reasons__c');
            pickLstString.add('Dissatisfaction_with_Current__c');
       String pickLstString1 = LeadQualificationView.getMultipickListString(pickLstString);
          
            
            Test.stopTest();
        //}    
    } 
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')   
  @isTest
    private static void testGetunSelectedValues()
    {
        List<SelectOption> out = new List<SelectOption>();
         LeadQualificationView lv = new LeadQualificationView();
         out = lv.getunSelectedValues();
    }   
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')  
    @isTest
    private static void testGetSelectedValues()
    {
                List<SelectOption> out = new List<SelectOption>();
             LeadQualificationView lv = new LeadQualificationView();
             out = lv.getSelectedValues();
    } 
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')  
    @isTest
    private static void testGetbusinessDriverList()
    {
        List<SelectOption> out = new List<SelectOption>();
             LeadQualificationView lv = new LeadQualificationView();
             out = lv.getbusinessDriverList();
    }   
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
     @isTest
    private static void testFetchPickList()
    {
        List<SelectOption> out = new List<SelectOption>();
         Lead_Qualification__c lc = new Lead_Qualification__c();
             LeadQualificationView lv = new LeadQualificationView();
              lv.setModelUsageFeatureDependencyClass();
             out = lv.fetchPickList(lc,'Usage_Levels__c');
    }  
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts') 
@isTest
    private static void testRedirectLeadQualificUser()
    {
             LeadQualificationView lv = new LeadQualificationView();
             lv.loadLeadQualBasicDet();
             PageReference p = lv.redirectLeadQualificUser();
    }   
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
@isTest
    private static void testGetLeadQual()
    {
         Account accObj = new Account();
            accObj.Name = 'Test Account Parent ';
            accObj.Partner_ID__c = '12346';
            insert accObj;
        Contact conObj = new Contact();
        conObj.FirstName='test contact';
        conObj.LastName = 'test last';
        conObj.AccountId = accObj.Id;
        insert conObj;
         PageReference pr2 = Page.LeadQualificationView;
            Test.setCurrentPage(pr2);
        pr2.getParameters().put('Id',accObj.Id);
        pr2.setRedirect(true);
        LeadQualificationView lv = new LeadQualificationView();
        List<Lead> leadInsertList = (List<Lead>) new SObjectBuilder(Lead.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                Lead.LastName => 'fakeLastName',
                Lead.Company => 'fakeCompany',
                Lead.Email => 'test@email.com'
            })
            .quantity(2)
            .create()
            .getRecords();
        Lead lead = leadInsertList[0];
        Lead_Qualification__c lq = new Lead_Qualification__c();
        lq.Lead__c = lead.Id;
        lq.Reasons__c='Slow to respond';
        lq.Who_is_Decision_Maker__c = 'testing string';
        lq.Contact__c = conObj.id;
        insert lq;
        lv.leadQualificationObj = lq;            
            //controller.setManagerAndNextStepValue();
                       List<Lead_Qualification__c> leadList = new List<Lead_Qualification__c>();
                                   lv.getContactInfo();
                                 lv.loadupdatedLeadQual();
                                  lv.updateLeadQual();
                       leadList =  lv.getLeadQualList();
        
         Opportunity testSetupOpportunity = new Opportunity(
            AccountId = accObj.Id,
            CurrencyIsoCode = 'USD',
            Name =   'Change Order',
            StageName = '1. Qualify',
            RecordTypeId = OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY,
            Type = OpportunityHelper.OPPORTUNITY_TYPE_EX_BUSINESS,
            closeDate = System.today()
        );
        insert testSetupOpportunity;
         PageReference pr3 = Page.LeadQualificationView;
            Test.setCurrentPage(pr3);
        pr3.getParameters().put('Id',testSetupOpportunity.Id);
        pr3.setRedirect(true);
        LeadQualificationView lv2 = new LeadQualificationView();
        Lead lead2 = leadInsertList[1];
        Lead_Qualification__c lq2 = new Lead_Qualification__c();
        lq2.Lead__c = lead2.Id;
        lq2.Reasons__c='Slow to respond';
        lq2.Who_is_Decision_Maker__c = 'testing string';
        lq2.Contact__c = conObj.id;
        insert lq2;
        lv2.leadQualificationObj = lq;
        List<Lead_Qualification__c> leadList2 = new List<Lead_Qualification__c>();
            lv2.getContactInfo();
            //lv2.loadupdatedLeadQual();
            lv2.updateLeadQual();
            leadList2 =  lv2.getLeadQualList();
       
    }  
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')  
    @isTest
    private static void testGetLeadQual2() {
        Account accObj = new Account();
        accObj.Name = 'Test Account Parent ';
        accObj.Partner_ID__c = '12346';
        insert accObj;
        Contact conObj = new Contact();
        conObj.FirstName='test contact';
        conObj.LastName = 'test last';
        conObj.AccountId = accObj.Id;
        insert conObj;
         PageReference pr2 = Page.LeadQualificationView;
            Test.setCurrentPage(pr2);
        pr2.getParameters().put('Id',conObj.Id);
        pr2.setRedirect(true);
        LeadQualificationView lv = new LeadQualificationView();
        Lead lead = (Lead) new SObjectBuilder(Lead.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Lead.email => 'fake@email.com',
                    Lead.LastName => 'fakeLastName',
                    Lead.Company => 'fakeCompany'
                }
            )
            .create()
            .getRecord();
        Lead_Qualification__c lq = new Lead_Qualification__c();
        lq.Lead__c = lead.Id;
        lq.Reasons__c='Slow to respond';
        lq.Who_is_Decision_Maker__c = 'testing string';
        lq.Contact__c = conObj.id;
        insert lq;
      lv.leadQualificationObj = lq;        
        List<Lead_Qualification__c> leadList2 = new List<Lead_Qualification__c>();
                                   lv.getContactInfo();
                                 lv.loadupdatedLeadQual();
                                 lv.updateLeadQual();
                       leadList2 =  lv.getLeadQualList();
        Implementation__c impObj = new Implementation__c();
        impObj.Name = 'testImplementationObj';
        impObj.Lead_Qualification__c = lq.id;
        insert impObj;
        PageReference pr3 = Page.LeadQualificationView;
            Test.setCurrentPage(pr3);
        pr3.getParameters().put('Id',impObj.Id);
        pr3.setRedirect(true);        
         lv.getContactInfo();
                                 lv.loadupdatedLeadQual();
                                 lv.updateLeadQual();
                       leadList2 =  lv.getLeadQualList();
        
    }
       
 @isTest static void testCheckInputFieldsLength() {
      LeadQualificationView lv = new LeadQualificationView();
        Lead lead = (Lead) new SObjectBuilder(Lead.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Lead.email => 'fake@email.com',
                    Lead.LastName => 'fakeLastName',
                    Lead.Company => 'fakeCompany'
                }
            )
            .create()
            .getRecord();
        Lead_Qualification__c lq = new Lead_Qualification__c();
        lq.Lead__c = lead.Id;
        lq.Reasons__c='Slow to respond';
        lq.Who_is_Decision_Maker__c = 'testing string';
        String lenstr = 'test';
        lq.CompanyInfo__c =lenstr;
        lq.Pain__c=lenstr;
        lq.Pain_Impact__c = lenstr;
        lq.Gain__c = lenstr;
        lq.Gain_Impact__c=lenstr;
        lq.Ideal_Solution__c=lenstr;
        lq.Benefits__c=lenstr;
        lq.Next_Steps_questions__c =lenstr;
        lq.Other_Explanation__c = lenstr;
        lq.Need__c = lenstr;
        lq.Prospect_Need__c = lenstr;
        lq.of_employees_in_org__c=lenstr;
        lq.How_many_phones_to_start__c = lenstr;
        lq.Other_Notes__c = lenstr;
        lq.Decision_on_Large_Projects__c=lenstr;
        lq.More_Info_on_Budgeted__c=lenstr;
        lq.ContractAdditionalInfo__c=lenstr;
        lq.CurrentSystemAdditionalInfo__c=lenstr;
        lq.TimeframeAdditionalInfo__c=lenstr;
        lq.Decision_makers_Additional_Information__c=lenstr;
        insert lq;
          lv.leadQualificationObj = lq;
      String res;
        String resCompanyInfo;
        String resPain;
        String resPainImpact;
        String resGain;
        String resGainImpact;
        String resIdeal;
        String resBenefits;
        String resNextQues;
        String resOtherExp;
        String resNeed;
        String resNoOFEMP;
        String resPhoneStart;
        String resOtherNotes;
        String resDecision;
        String resMoreInfoBudget;
        String resContactAddInfo;
        String resCurrSystemInfo;
        String resTimeFrameInfo;
        String resDecisionMakersInfo;
        String resProspectNeed;
     Test.startTest();
     String resi ;
             System.debug('from input feild value is'+lv.leadQualificationObj.CompanyInfo__c);
   resCompanyInfo = lv.checkInputFieldLength();
     lv.leadQualificationObj.CompanyInfo__c = '';
      resPain = lv.checkInputFieldLength();
     System.debug('resCompanyInfo===='+resCompanyInfo);
 lv.leadQualificationObj.Pain__c = '';
          resPainImpact = lv.checkInputFieldLength();
     System.debug('resCompanyInfo===='+resPain);
     lv.leadQualificationObj.Pain_Impact__c = '';
               resGain = lv.checkInputFieldLength();
     System.debug('resCompanyInfo===='+resPainImpact);
     lv.leadQualificationObj.Gain__c = '';
               resGainImpact = lv.checkInputFieldLength();
     System.debug('resCompanyInfo===='+resGain);
     lv.leadQualificationObj.Gain_Impact__c = '';
               resIdeal = lv.checkInputFieldLength();
     System.debug('resCompanyInfo===='+resGainImpact);
     lv.leadQualificationObj.Ideal_Solution__c = '';
               resBenefits = lv.checkInputFieldLength();
     System.debug('resCompanyInfo===='+resIdeal);
     lv.leadQualificationObj.Benefits__c = '';
               resNextQues = lv.checkInputFieldLength();
     lv.leadQualificationObj.Next_Steps_questions__c = '';
               resOtherExp = lv.checkInputFieldLength();
     lv.leadQualificationObj.Other_Explanation__c = '';
               resNeed = lv.checkInputFieldLength();
     lv.leadQualificationObj.Need__c = '';
               resProspectNeed = lv.checkInputFieldLength();
     lv.leadQualificationObj.Prospect_Need__c = '';
               resNoOFEMP = lv.checkInputFieldLength();
     lv.leadQualificationObj.of_employees_in_org__c = '';
               resPhoneStart = lv.checkInputFieldLength();
     lv.leadQualificationObj.How_many_phones_to_start__c = '';
               resOtherNotes = lv.checkInputFieldLength();
     lv.leadQualificationObj.Other_Notes__c = '';
               resDecision = lv.checkInputFieldLength();
     lv.leadQualificationObj.Decision_on_Large_Projects__c = '';
               resContactAddInfo = lv.checkInputFieldLength();
     lv.leadQualificationObj.ContractAdditionalInfo__c = '';
               resMoreInfoBudget = lv.checkInputFieldLength();
     lv.leadQualificationObj.More_Info_on_Budgeted__c = '';
               resCurrSystemInfo = lv.checkInputFieldLength();
     lv.leadQualificationObj.CurrentSystemAdditionalInfo__c = '';
               resTimeFrameInfo = lv.checkInputFieldLength();
     lv.leadQualificationObj.TimeframeAdditionalInfo__c = '';
               resDecisionMakersInfo = lv.checkInputFieldLength();
      lv.leadQualificationObj.Decision_makers_Additional_Information__c = '';
               resDecisionMakersInfo = lv.checkInputFieldLength();

        Test.stopTest();

        System.assertEquals('CompanyInfo', resCompanyInfo, 'Error occured while checking CompanyInfo__c field');
        System.assertEquals('PAIN', resPain, 'Error occured while checking Pain__c field');
        System.assertEquals('PAINImpact', resPainImpact, 'Error occured while checking Pain_Impact__c field');
        System.assertEquals('GAIN', resGain, 'Error occured while checking Gain__c field');
        System.assertEquals('GAINImpact', resGainImpact, 'Error occured while checking Gain_Impact__c field');
        System.assertEquals('IDEASol', resIdeal, 'Error occured while checking Ideal_Solution__c field');
        System.assertEquals('Benefits', resBenefits, 'Error occured while checking Benefits__c field');
        System.assertEquals('NextQues', resNextQues, 'Error occured while checking Next_Steps_questions__c field');
        System.assertEquals('OtherExplain', resOtherExp, 'Error occured while checking Other_Explanation__c field');
        System.assertEquals('Need', resNeed, 'Error occured while checking Need__c field');
        System.assertEquals('NoOFEMP', resNoOFEMP, 'Error occured while checking of_employees_in_org__c field');
        System.assertEquals('PhoneStart', resPhoneStart,
            'Error occured while checking How_many_phones_to_start__c field');
        System.assertEquals('OtherNotes', resOtherNotes, 'Error occured while checking Other_Notes__c field');
        System.assertEquals('DecisionLargerProject', resDecision,
            'Error occured while checking Decision_on_Large_Projects__c field');
        System.assertEquals('MoreInfoBugdet', resMoreInfoBudget,
            'Error occured while checking More_Info_on_Budgeted__c field');
    }
 
    
}