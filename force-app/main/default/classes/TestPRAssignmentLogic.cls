@isTest
private class TestPRAssignmentLogic {

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void myUnitTest() {
        
        User indiaTeamUser = [SELECT id,Email,IsActive,Username,Contact.Account.Partner_ID__c,Contact.Account.Current_Owner__c,Contact.Account.Current_Owner__r.isActive,
                                Contact.Account.Name,Contact.Account.Ultimate_Partner_ID__c,Contact.Account.Ultimate_Parent_Partner_ID__c,Contact.Account.Ultimate_Partner_Name__c,Contact.Account.VAR_Territory__c,
                                Contact.Account.Ultimate_Parent_Account_Name__c,Profile.Name, Contact.Account.Current_Owner__r.Name,Contact.Account.Inside_Sales_Rep__c, ContactId,
                                Contact.MailingStreet,Contact.MailingState,Contact.MailingCity,Contact.MailingCountry,Contact.MailingPostalCode 
                                FROM User where Name = 'x-India Team'];
        boolean userFound = true;
        
        Account acctest = new Account();
        acctest.Name='TestAccount';
        acctest.RC_Attribution_Channel__c = 'Sales Agents & Resellers';
        acctest.Partner_ID__c ='123';
        acctest.RecordTypeId  = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer Account').getRecordTypeId();
        acctest.Current_Owner__c = indiaTeamUser.id;
        insert acctest;
                
        Contact contactObj = new Contact();
        contactObj.AccountId =  acctest.id;
        contactObj.Email = 'test.test@test.com';
        contactObj.Phone = '9910106804';
        contactObj.LastName = 'TestLast';
        
        insert contactObj;
        
        Campaign campObj1 = new Campaign(Name='TestCampaign',Protected_Campaign__c=true
        , Shared_Lead_Campaign__c=true, Lead_Creation_Score__c='300', IsActive=true, AID__c='test0121' );
        insert campObj1;

        /********************Segement Object Data Created**************************************************/
        List<Segment_Data__c> segmentDataList = new List<Segment_Data__c>();
        Segment_Data__c segData = new Segment_Data__c(Type__c='Industry',Attribute_1__c='1',Attribute_2__c='Transportation',Postal_Code__c='');
        Segment_Data__c segData1 = new Segment_Data__c(Type__c='Country',Attribute_1__c='USA',Attribute_2__c='United States',Postal_Code__c='');
        Segment_Data__c segData2 = new Segment_Data__c(Type__c='Area Code',Attribute_1__c='991',Attribute_2__c='United States',Postal_Code__c='100');
        
        Segment_Data__c segData3 = new Segment_Data__c(Type__c='Industry',Attribute_1__c='2',Attribute_2__c='Transportation',Postal_Code__c='');
        Segment_Data__c segData4 = new Segment_Data__c(Type__c='Country',Attribute_1__c='CN',Attribute_2__c='Canada',Postal_Code__c='');
        Segment_Data__c segData5 = new Segment_Data__c(Type__c='Area Code',Attribute_1__c='999',Attribute_2__c='Canada',Postal_Code__c='100');
        
        segmentDataList.add(segData);
        segmentDataList.add(segData1);
        segmentDataList.add(segData2);
        segmentDataList.add(segData3);
        segmentDataList.add(segData4);
        segmentDataList.add(segData5);
        insert segmentDataList;
        /*************************************************************************************************/

        /********************Territory Object Data Created**************************************************/
        List<Territory_Data__c> territoryDataList = new List<Territory_Data__c>();
        Territory_Data__c terrData = new Territory_Data__c(Type__c='Industry-Geo',Name='Data1',Country__c='United States',Industry__c='Transportation',
                                                            Postal_Begin__c='100',Postal_End__c='200',Segment__c='50-249',Alternate_Owner__c=indiaTeamUser.Id);
        Territory_Data__c terrData1 = new Territory_Data__c(Type__c='Geo',Name='Data2',Country__c='United States',Industry__c='',
                                                            Postal_Begin__c='100',Postal_End__c='200',Segment__c='50-249',Territory_Owner__c=indiaTeamUser.Id);         
        
        Territory_Data__c terrData2 = new Territory_Data__c(Type__c='Industry-Geo',Name='Data3',Country__c='Canada',Industry__c='Transportation',
                                                            Postal_Begin__c='100',Postal_End__c='200',Segment__c='50-249',Alternate_Owner__c=indiaTeamUser.Id);
        Territory_Data__c terrData3 = new Territory_Data__c(Type__c='Geo',Name='Data4',Country__c='Canada',Industry__c='',
                                                            Postal_Begin__c='100',Postal_End__c='200',Segment__c='50-249',Territory_Owner__c=indiaTeamUser.Id);
        
        territoryDataList.add(terrData);
        territoryDataList.add(terrData1);
        territoryDataList.add(terrData2);
        territoryDataList.add(terrData3);           
        insert territoryDataList;
        /*************************************************************************************************/ 
        
        /*************************Custom Setting and Custom Label data Created*******************************************/
        Campaign_Subtype_Mapping__c mappingCS = new Campaign_Subtype_Mapping__c(Name='CPL_Shared',Queue_Id__c=indiaTeamUser.Id);
        insert mappingCS;
        
        system.debug('Label=='+Label.Territory_Employee_Size);
        //System.Label.Territory_Employee_Size = '50-249';
        //System.Label.Territory_By_Pass = 'true';
        /***********************************************************************************************/
       
        Lead leadObj = new Lead();
        leadObj.FirstName='testFirst';
        leadObj.LastName='testLast';
        leadObj.Company='testCompany';
        leadObj.Email='test.test@test.com';
        leadObj.Phone='9910106804';
        leadObj.LeadSource = 'Inbound Call';
        leadObj.Notes__c = 'Test Notes'; 
        leadObj.Website = 'http://test.com';
        leadObj.NumberOfEmployees = 123;
        leadObj.Industry = 'Test';
        leadObj.NumberOfEmployees__c = '2-9';      
        leadObj.Number_of_Locations__c = '2-4';
        leadObj.LAR_Source__c ='';
        leadObj.Assignment_Source_hidden__c ='PR PER MARKETO';
        leadObj.Agent_Email_Address__c = 'test@test.com';  
        leadObj.Lead_Owner_Email_Address__c = indiaTeamUser.Email;  
        leadObj.Eligible_Protection_Period__c = system.today();
        leadObj.Status = '2. Contacted';
        leadObj.Most_Recent_Campaign__c = campObj1.Id;
        leadObj.Geo_Country__c='United States';
        leadObj.LS_Company_Country__c = 'United States';
        leadObj.postalcode = '100';
        leadObj.LS_Company_Size_Range__c ='5-9';
        leadObj.OwnerId = UserInfo.getUserId()  ; 
        leadObj.Sales_Agent_Email__c= userinfo.getuserId() ;
        leadObj.LS_Primary_NAIC__c='1';
        leadObj.Employees_Override__c='50-249';
        leadObj.Partner_Lead_Source__c = 'RingCentral';
        leadObj.Partner_Account_Name__c ='testrecord';
        leadObj.Ultimate_Parent_Account_Partner_ID__c ='test123';
        leadObj.Ultimate_Parent_Account_Name__c ='test1233';
        leadObj.VAR_Territory__c ='House';
        leadObj.Assignment_Source_hidden__c='PR PER MARKETO VAR';
       
        Lead leadObj1 = new Lead();
        leadObj1.FirstName='testFirst1';
        leadObj1.LastName='testLast1';
        leadObj1.Company='testCompany1';
        leadObj1.Email='test1.test@test.com';
        leadObj1.Phone='9990106801';
        leadObj1.LeadSource = 'Inbound Call';
        leadObj1.Notes__c = 'Test Notes'; 
        leadObj1.Website = 'http://test.com';
        leadObj1.NumberOfEmployees = 123;
        leadObj.LAR_Source__c ='';
        leadObj.Assignment_Source_hidden__c ='PR PER MARKETO';

        leadObj1.Industry = 'Test';
        leadObj1.NumberOfEmployees__c = '2-9';
        leadObj1.Number_of_Locations__c = '2-4';
        leadObj1.Agent_Email_Address__c = 'test@test.com';  
        leadObj1.Lead_Owner_Email_Address__c = indiaTeamUser.Email;  
        leadObj1.Eligible_Protection_Period__c = system.today();
        leadObj1.Status = '2. Contacted';
        leadObj1.Most_Recent_Campaign__c = campObj1.Id;
        leadObj1.LS_Company_Size_Range__c ='5-9';
        leadObj1.OwnerId = UserInfo.getUserId()   ; 
        leadObj1.Sales_Agent_Email__c='lokesh@gmail.com' ;     
        leadObj1.Employees_Override__c='50-249';
        leadObj1.Partner_Lead_Source__c = 'RingCentral';
        leadObj1.Partner_Account_Name__c ='testrecord';
        leadObj1.Ultimate_Parent_Account_Partner_ID__c ='test123';
        leadObj1.Ultimate_Parent_Account_Name__c ='test1233';
        leadObj1.VAR_Territory__c ='House';
        leadObj1.Assignment_Source_hidden__c='PR PER MARKETO VAR';
        
         Lead leadObj12 = new Lead();
        leadObj12.FirstName='testFirst1';
        leadObj12.LastName='testLast1';
        leadObj12.Company='testCompany1';
        leadObj12.Email='test1.test@test.com';
        leadObj12.Phone='9990106801';
        leadObj.LAR_Source__c ='';
        leadObj.Assignment_Source_hidden__c ='PR PER MARKETO';
      
        Opportunity oppObj = new Opportunity(Name='TestOpp',StageName='1. Qualify',AccountId=acctest.Id,Type='New Business',Sales_Model__c='Online',
                                             Brand_Name__c='RingCentral',Tier_Name__c='Office',CloseDate=system.today());
        insert oppObj;
           
        OpportunityContactRole oppContRole = new OpportunityContactRole(opportunityId=oppObj.Id,ContactId=contactObj.Id,IsPrimary=true);
        insert oppContRole;        
        
        Campaign campObj2 = new Campaign(Name='TestCampaign',Protected_Campaign__c=false
        , Shared_Lead_Campaign__c=true, Lead_Creation_Score__c='test', IsActive=true, DNIS__c='test0121' );
        insert campObj2;
        Campaign campObj3 = new Campaign(Name='TestCampaign',Protected_Campaign__c=true
        , Shared_Lead_Campaign__c=true, Lead_Creation_Score__c='-200', IsActive=true, PID__c='test0121' );
        insert campObj3;
        Campaign campObj4 = new Campaign(Name='TestCampaign',Protected_Campaign__c=false
        , Shared_Lead_Campaign__c=true, Lead_Creation_Score__c='200.00', IsActive=true, BMID__c='test0121' );
        insert campObj4;
        Campaign campObj5 = new Campaign(Name='TestCampaign',Protected_Campaign__c=true
        , Shared_Lead_Campaign__c=true, IsActive=true, Lead_Entry_Source__c='ROI Form' );
        insert campObj5;

        RcDealHealper.searchResultClass searchObj = new RcDealHealper.searchResultClass();
        searchObj.contactResultList = new List<Contact>{contactObj};
        searchObj.leadResultList = new List<Lead>{leadObj};

       	PRAssignmentLogic.prRuleWrapper prWrapper = new PRAssignmentLogic.prRuleWrapper(leadObj.Id,leadObj1.Id,indiaTeamUser.Id,leadObj1.OwnerId,
                                                                                        contactObj.Id,leadObj1.LeadSource,leadObj.RecordTypeId,leadObj.Partner_Account__r.Name,leadObj.Ultimate_Parent_Account_ID__c,
                                                                                        leadObj.Ultimate_Parent_Account_Name__c,leadObj.Owner.Name,'Sample',leadObj.OwnerId,
                                                                                        true,false,'',
                                                                                        '','','','50210',leadObj.Account__c);
        map<String,RcDealHealper.searchResultClass> searchResultMap = new map<String,RcDealHealper.searchResultClass>{leadObj.Email+leadObj.Phone=>searchObj};
        map<String,PRAssignmentLogic.prRuleWrapper> prOwnerDetailMap = new map<String,PRAssignmentLogic.prRuleWrapper> ();        
        system.debug('searchResultMap='+searchResultMap);
        
        map<String,String> prOwnerMap = new map<String,String>();
        PRAssignmentLogic.checkAccountCurrentOwner(searchResultMap,prOwnerMap,prOwnerDetailMap, new Set<string>());    
        
        searchResultMap = new map<String,RcDealHealper.searchResultClass>{leadObj.Email+leadObj.Phone=>searchObj}; 
        prOwnerDetailMap = new map<String,PRAssignmentLogic.prRuleWrapper>();//){leadObj.Email+leadObj.Phone=>searchObj};
        PRAssignmentLogic.checkActivePipeOrProtected(searchResultMap, prOwnerMap,prOwnerDetailMap);
        searchObj.contactResultList = new List<Contact>();
        searchResultMap = new map<String,RcDealHealper.searchResultClass>{leadObj.Email+leadObj.Phone=>searchObj};
        PRAssignmentLogic.checkActivePipeOrProtected(searchResultMap, prOwnerMap,prOwnerDetailMap);
        
        map<String,RcDealHealper.searchResultClass> activePipeOrProtectedMap = new map<String,RcDealHealper.searchResultClass>();        
        List<Lead> newLeadList = new List<Lead>();
        boolean assignUser = true;
        
        Profile p = [SELECT Id FROM Profile WHERE Name='RC Partner Modify']; 
        User VarContactUser = new User();
        VarContactUser.Email='donotcontactvrar@ringcentral.com.mkto';
        VarContactUser.Alias= 'test'; 
        VarContactUser.TimeZoneSidKey='America/Los_Angeles';
        VarContactUser.EmailEncodingKey='UTF-8';
        VarContactUser.LastName='Testing';
        VarContactUser.LocaleSidKey='en_US';
        VarContactUser.LanguageLocaleKey='en_US'; 
        VarContactUser.ProfileId = p.Id;
        VarContactUser.ContactId = contactObj.Id;
        VarContactUser.Username ='donotcontactvasdsdr@ringcentral.com.mkto';
        map<string,boolean> systemUserMap = new map<string,boolean>();
        map<string,boolean> invalidStatusMap= new map<string,boolean>();
        String finalPostalCode = '';
        String postalCode = (leadObj.PostalCode!=null ? leadObj.PostalCode : leadObj.LS_Company_Zipcode__c);    
        finalPostalCode =postalCode;        
        String uniqueKey = ( !string.isBlank(leadObj.Email) ? leadObj.Email : '') + ( !string.isBlank(leadObj.Phone) ? leadObj.Phone : '');
        PRAssignmentLogic.createEmailOwnerMap(new List<Lead>{leadObj});
        //PRAssignmentLogic.findSystemAdminUser(); 
        String uniqueString = leadObj.Email+leadObj.Phone;
        prOwnerDetailMap.put(uniqueString,prWrapper);
        PRAssignmentLogic.runPRLogic(leadObj, leadObj.Email+leadObj.Phone, prOwnerMap, prOwnerDetailMap,new map<String,User>(),new map<String,Contact>(),new User(),VarContactUser,true);
        PRAssignmentLogic.checkVARReferalLead(leadObj,uniqueKey,prOwnerMap, new User(),new Contact(),VarContactUser);
        PRAssignmentLogic.calculateProtectionPeriod(leadObj,leadObj,systemUserMap,invalidStatusMap,new Set<String>());  
        Map<string,Map<String,String>> segmentDataMap = PRAssignmentLogic.createSegmentDataMap();
        PRAssignmentLogic.validatePostalCode(postalCode,leadObj.Phone,leadObj.Geo_Country__c,segmentDataMap);        
        Map<String,Map<String,List<Territory_Data__c>>> territoryDataMap = PRAssignmentLogic.createTerritoryDataMap();
        Set<string> employeeSizeSet = new Set<string>{'50-249'};
        Set<string> leadSourceSet = new Set<string>{'Inbound Call'};
        PRAssignmentLogic.runGeoTerritoryRouting(leadObj,segmentDataMap,territoryDataMap,employeeSizeSet,leadSourceSet);
        PRAssignmentLogic.calculateLimits();
        PRAssignmentLogic.runGeoTerritoryRouting(leadObj1,segmentDataMap,territoryDataMap,employeeSizeSet,leadSourceSet);
        PRAssignmentLogic.runGeoTerritoryRouting(leadObj12,segmentDataMap,territoryDataMap,employeeSizeSet,leadSourceSet);
        List<Lead> newLeadList1 = new List<Lead>{new Lead(Lead_Owner_Email_Address__c='test.test@test.com',Sales_Agent_Email__c='test.test@test.com')};
        PRAssignmentLogic.createEmailContactMap(newLeadList1);
        PRAssignmentLogic.findSystemAdminUser();
        PRAssignmentLogic.checkVARReferalLead(leadObj,uniqueKey,prOwnerMap, new User(),contactObj,VarContactUser);
        Profile portalProfile = [SELECT Id,Name FROM Profile WHERE Name = 'RC Partner Modify' Limit 1];
        User user1;     
        user1 = new User(
            Username = UserHelper.getUniqueUserName(),
            ContactId = contactObj.Id,
            ProfileId = portalProfile.Id,
            //userroleid  = r.Id, 
            Alias = 'test123',
            Email = 'test12345@test.com', 
            EmailEncodingKey = 'UTF-8',
            LastName = 'McTesty',
            CommunityNickname = 'test12345',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            LanguageLocaleKey = 'en_US');           
        Database.insert(user1);
        User userObj = [SELECT id,Email,IsActive,Username,Contact.Account.Partner_ID__c,Contact.Account.Current_Owner__c,Contact.Account.Current_Owner__r.isActive,
                                Contact.Account.Name,Contact.Account.Ultimate_Partner_ID__c,Contact.Account.Ultimate_Parent_Partner_ID__c,Contact.Account.Ultimate_Partner_Name__c,Contact.Account.VAR_Territory__c,
                                Contact.Account.Ultimate_Parent_Account_Name__c,Profile.Name, Contact.Account.Current_Owner__r.Name,Contact.Account.Inside_Sales_Rep__c, ContactId,
                                Contact.MailingStreet,Contact.MailingState,Contact.MailingCity,Contact.MailingCountry,Contact.MailingPostalCode 
                                FROM User WHERE id =: user1.id]; 
        PRAssignmentLogic.checkVARReferalLead(leadObj,uniqueKey,prOwnerMap, indiaTeamUser,new Contact(),VarContactUser);
        PRAssignmentLogic.checkVARReferalLead(leadObj,uniqueKey,prOwnerMap, userObj,new Contact(),VarContactUser);
        
    }
}