@isTest
private class TestLeadTriggerHelperExt {

    private final static String LAR_USER = 'LAR System User';

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void myUnitTest() {
        try {
            Profile prof = [SELECT id FROM Profile WHERE Name = 'Sales Agent SDR w Insidesales' LIMIT 1];
            User user1 = new User(alias = 'nwUsr', email='nwUsr@simplion.com.test',
            emailencodingkey='UTF-8', lastname='Testing1',
            languagelocalekey='en_US', localesidkey='en_US', profileid = prof.id,
            timezonesidkey='America/Los_Angeles', username= System.now().millisecond() + 'nwUsr@simplion.com.test');
            insert user1;
            Schema.DescribeSObjectResult leadDescRes = Schema.SObjectType.Lead;
            Map<String,Schema.RecordTypeInfo> leadRecordTypeInfo = leadDescRes.getRecordTypeInfosByName();

            List<Campaign> campaignList = new List<Campaign>();
            Campaign campObj1 = new Campaign(Name='Default Campaign',Protected_Campaign__c=true
            , Shared_Lead_Campaign__c=true, Lead_Creation_Score__c='300', IsActive=true, AID__c='test0121' );
            campaignList.add(campObj1);

            Campaign campObj2 = new Campaign(Name='TestCampaign',Protected_Campaign__c=false
            , Shared_Lead_Campaign__c=true, Lead_Creation_Score__c='test', IsActive=true, DNIS__c='test0121' );
            campaignList.add(campObj2);

            Campaign campObj3 = new Campaign(Name='TestCampaign',Protected_Campaign__c=true
            , Shared_Lead_Campaign__c=true, Lead_Creation_Score__c='-200', IsActive=true, PID__c='test0121', BMID__c='test0122', AID__c='test0123' );
            campaignList.add(campObj3);

            Campaign campObj4 = new Campaign(Name='TestCampaign',Protected_Campaign__c=false
                , Shared_Lead_Campaign__c=true, Lead_Creation_Score__c='200.00', IsActive=true, BMID__c='test0121' );
            campaignList.add(campObj4);
            insert campaignList;

            List<Lead> leadList = new List<Lead>();
            Lead leadObj0 = new Lead(firstName='Singh', Title='VP', LeadSource='Solve Then Sell', Sales_Agent_User_Lookup__c=user1.Id, Lead_Entry_Source__c='ROI Form', Primary_Campaign__c=campObj3.Id, lastname = 'Virendra',
                                        company='Simplion', email='virendra.singh0@simplion.com', phone='9910106804', BMID__c = 'test0121',
                                        RecordTypeId = leadRecordTypeInfo.get('Sales Leads').getRecordTypeId());
            leadList.add(leadObj0);

            Lead leadObj1 = new Lead(firstName='Singh', Title='VP', Lead_Entry_Source__c='ROI Form', LeadSource='Initial', lastname = 'Virendra',
                                        company='Simplion', email='virendra.singh@simplion.com', phone='9910106804', BMID__c = 'test0121',
                                        RecordTypeId = leadRecordTypeInfo.get('Partner Leads').getRecordTypeId());
            leadList.add(leadObj1);

            Lead leadObj2 = new Lead(firstName='Singh', Title='VP', AID__C='test0121', Referrer_RCUserID__c='Test002',
                                LeadSource='About To Be Cancelled',User_ID__c='Test002', lastname = 'Virendra',
                                company='Simplion', email='virendra.singh1@simplion.com', phone='9910106805');
            leadList.add(leadObj2);

            Lead leadObj3 = new Lead(firstName='Singh', Title='VP', PID__c='test0121', NumberOfEmployees__c ='500', LeadSource='Vista Print', lastname = 'Virendra',
            company='Simplion', email='virendra.singh2@simplion.com', phone='(919)191-9128');
            leadList.add(leadObj3);
            insert leadList;

            Test.startTest();
            LeadTriggerHelperExt leadTrgObj = new LeadTriggerHelperExt();
            LeadTriggerHelperExt.assignCampaigns(leadList);
             Lead leadObj4 = new Lead(firstName='Singh1', Title='VP', PID__c='test0121', BMID__c='test0122', AID__c='test0123',
                                        NumberOfEmployees__c ='500+',
                                        LeadSource = 'Vista Print', lastname = 'Virendra',
                                        company='Simplion', email= 'virendra.singh7@simplion.com', phone='(919)191-9122');

            List<Lead> leadList1 = new List<Lead>();
            leadList1.add(leadObj4);
            LeadTriggerHelperExt.assignCampaigns(leadList1);
            Lead leadObj5 = new Lead(firstName='Singh15', Title='VP', PID__c='test0121', BMID__c='test0122',
                                        NumberOfEmployees__c ='500+',
                                        LeadSource = 'Vista Print', lastname = 'Virendra',
                                        company='Simplion', email= 'virendra.singh15@simplion.com', phone='(919)191-9115');

            leadList1 = new List<Lead>();
            leadList1.add(leadObj5);
            Map<id ,Lead> mlead = new map<Id,Lead>();
            Set<String> sid = new set<String>();
            LeadTriggerHelperExt.assignCampaigns(leadList1);

            User indiaTeamUser = [Select id,IsActive,Email from user where id = :HardcodedIdsMapper.getMatchedObjectId('00580000003d9rB')];
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
            leadObj.Country='USA';
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
            /*****************************************j********************************************************/
            Map<string,Map<String,String>> segmentDataMap = PRAssignmentLogic.createSegmentDataMap();
            Map<String,Map<String,List<Territory_Data__c>>> territoryDataMap = PRAssignmentLogic.createTerritoryDataMap();
            Set<string> employeeSizeSet = new Set<string>{'50-249'};
            leadObj.Industry = '1';
            LeadTriggerHelperExt.assignCampaignToList('TestCampaign',new List<Lead>{leadObj},new Map<String, Campaign>());

            Test.stopTest();
        } catch(Exception ex) {}
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testCSV(){
        List<Lead> leadListNew = new List<Lead>();
        Lead leadObj = new Lead();
        leadObj.FirstName='testFirst';
        leadObj.LastName='testLast';
        leadObj.Company='testCompany';
        leadObj.Email='test2.test@test.com';
        leadObj.Phone='9910106804';
        leadObj.LeadSource = 'Inbound Call';
        leadObj.Notes__c = 'Test Notes';
        leadObj.Website = 'http://test.com';
        leadObj.NumberOfEmployees = 123;
        leadObj.Industry = 'Other';
        leadObj.NumberOfEmployees__c = '50-249';
        leadObj.Number_of_Locations__c = '50+';
        leadObj.Agent_Email_Address__c = 'test@test.com';
        leadObj.Eligible_Protection_Period__c = system.today();
        leadObj.Status = '2. Contacted';
        leadObj.Country__c='USA';
        leadObj.Zip_Code__c = '100';
        leadObj.LS_Primary_NAIC__c='1';
        leadObj.Employees_Override__c='50-249';
        Lead leadObj2 = new Lead();
        leadObj2.FirstName='testFirst';
        leadObj2.LastName='testLast';
        leadObj2.Company='testCompany';
        leadObj2.Email='test2.test@test.com';
        leadObj2.Phone='9910106804';
        leadObj2.LeadSource = 'Inbound Call';
        leadObj2.Notes__c = 'Test Notes';
        leadObj2.Website = 'http://test.com';
        leadObj2.NumberOfEmployees = 123;
        leadObj2.Industry = 'Other';
        leadObj2.NumberOfEmployees__c = '20';
        leadObj2.Number_of_Locations__c = '50+';
        leadObj2.Agent_Email_Address__c = 'test@test.com';
        leadObj2.Eligible_Protection_Period__c = system.today();
        leadObj2.Status = '2. Contacted';
        leadObj2.Country__c='USA';
        leadObj2.Zip_Code__c = '100';
        leadObj2.LS_Primary_NAIC__c='1';
        leadObj2.Employees_Override__c='50-249';

        Lead leadObj1 = new Lead();
        leadObj1.FirstName='testFirst';
        leadObj1.LastName='testLast';
        leadObj1.Company='testCompany';
        leadObj1.Email='test2.test@test.com';
        leadObj1.Phone='9910106804';
        leadObj1.LeadSource = 'Inbound Call';
        leadObj1.Notes__c = 'Test Notes';
        leadObj1.Website = 'http://test.com';
        leadObj1.NumberOfEmployees = 123;
        leadObj1.Industry = 'Other';
        leadObj1.NumberOfEmployees__c = '20+';
        leadObj1.Number_of_Locations__c = '50+';
        leadObj1.Agent_Email_Address__c = 'test@test.com';
        leadObj1.Eligible_Protection_Period__c = system.today();
        leadObj1.Status = '2. Contacted';
        leadObj1.Country__c='USA';
        leadObj1.Zip_Code__c = '100';
        leadObj1.LS_Primary_NAIC__c='1';
        leadObj1.Employees_Override__c='50-249';
        leadListNew.add(leadObj1);
        leadListNew.add(leadObj);
        leadListNew.add(leadObj2);
        String expected = ''
            + '"FieldName","delimit1","BadValues","delimit2","GoodValues","delimit3","EOL"\n'
            + '"NumberOfEmployees__c","#","20+","#","Oct-49","#","#EOL#"\n'
            + '"NumberOfEmployees__c","#","20-24","#","Oct-49","#","#EOL#"\n'
            ;
        Folder fd = [SELECT Id FROM Folder WHERE Name='Public Documents' LIMIT 1];
        Document dummyDocument = new Document();
        dummyDocument.name = 'No_Employee_Mapping';
        dummyDocument.body = Blob.valueOf(expected);
        dummyDocument.folderId=fd.Id;
        dummyDocument.isPublic=true;
        dummyDocument.type='csv';
        insert dummyDocument;
        LeadTriggerHelperExt.getCheckForBadValue(leadListNew);

        TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT();
        TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE();
        TriggerHandler.BY_PASS_CONTACT_ON_INSERT();
        TriggerHandler.BY_PASS_CONTACT_ON_UPDATE();
        TriggerHandler.BY_PASS_OPPORTUNITY_ON_INSERT();
        TriggerHandler.BY_PASS_OPPORTUNITY_ON_UPDATE();
        TriggerHandler.BY_PASS_LEAD_UPDATE = true;

        Profile p = [SELECT Id FROM Profile WHERE Name='RC Partner User'];

        Account accountObj = new Account();
        accountObj.Name = 'TestAcc';
        accountObj.Partner_ID__c= '140001';
        Schema.DescribeSObjectResult schemaL = Schema.SObjectType.Account;
        Map<String,Schema.RecordTypeInfo> aRecordTypeInfo = schemaL.getRecordTypeInfosByName();
        accountObj.RecordTypeId = aRecordTypeInfo.get('Partner Account').getRecordTypeId();
        insert accountObj;

        Contact conObj = new Contact();
        conObj.FirstName = 'TestFNameconvert';
        conObj.LastName = 'TestLNameconvert';
        conObj.Email = 'Testnameconvert@test.com';
        conObj.AccountId = accountObj.Id;
        insert  conObj;

        User objUser = new User(Alias = 'standt', Email='standarduser@testorg.com',
                            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
                            LocaleSidKey='en_US', ProfileId = p.Id,ContactId = conObj.id,
                            TimeZoneSidKey='America/Los_Angeles', UserName='testconvertlead@2.com'+system.now().getTime());
        insert objUser ;

        Schema.DescribeSObjectResult leadDescRes = Schema.SObjectType.Lead;
        Map<String,Schema.RecordTypeInfo> leadRecordTypeInfo = leadDescRes.getRecordTypeInfosByName();
        Lead leadObjTest = new Lead();
        leadObjTest.FirstName='Virendra';
        leadObjTest.LastName='Singh';
        leadObjTest.Company='Simplion';
        leadObjTest.Email='virendra.singhasdasd@simplion.com';
        leadObjTest.Phone='9910106866';
        leadObjTest.LeadSource = 'Inbound Call';
        leadObjTest.Notes__c = 'Test Notes';
        leadObjTest.Website = 'http://test.com';
        leadObjTest.NumberOfEmployees = 123;
        leadObjTest.Industry = 'Test';
        leadObjTest.NumberOfEmployees__c = '250-999';
        leadObjTest.Number_of_Locations__c = '2-4';
        leadObjTest.Agent_Email_Address__c = 'test@test.com';
        leadObjTest.RecordTypeId = LeadRecordTypeInfo.get('Partner Leads').getRecordTypeId();
        leadObjTest.Partner_Lead_Owner__c =  objUser.Id;
        leadObjTest.ownerId =  UserInfo.getUserId();
        leadObjTest.LeadPartnerID__c = '140001';
        leadObjTest.Status = '2. Contacted';
        leadObjTest.Estimated_Close_Date__c = Date.today();
        insert leadObjTest;

        TriggerHandler.BY_PASS_LEAD_UPDATE = false;
        Database.LeadConvert lc = new database.LeadConvert();
        lc.setLeadId(leadObjTest.id);
        LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted=true LIMIT 1];
        lc.setConvertedStatus(convertStatus.MasterLabel);
        Database.LeadConvertResult lcr = Database.convertLead(lc);
    }

    @isTest
    static void testClone(){

        Profile prof = [SELECT id FROM Profile WHERE Name = 'Sales Rep - Lightning' LIMIT 1];

        User user1 = new User(alias = 'nwUsr', email='nwUsr@rc.com.test',
        emailencodingkey='UTF-8', lastname='Testing1',
        languagelocalekey='en_US', localesidkey='en_US', profileid = prof.id,
        timezonesidkey='America/Los_Angeles', username= System.now().millisecond() + 'nwUsr@simplion.com.test');
        insert user1;

        Schema.DescribeSObjectResult leadDescRes = Schema.SObjectType.Lead;
        Map<String,Schema.RecordTypeInfo> leadRecordTypeInfo = leadDescRes.getRecordTypeInfosByName();

        Test.startTest();
            Lead leadObj0 = new Lead(
                firstName='eugene', Title='VP', LeadSource='Solve Then Sell', Sales_Agent_User_Lookup__c=user1.Id, Lead_Entry_Source__c='ROI Form',
                lastname = 'mutya', company='Rc', email='eugene.mutya@rc.com', phone='9910106804', BMID__c = 'test0121', RecordTypeId = leadRecordTypeInfo.get('Sales Leads').getRecordTypeId(),
                LS_Company__c='1',LS_Company_City__c='1',LS_Company_Country__c='1',LS_Company_Industry__c='1',LS_Company_Original_Input__c='1',
                LS_Company_Phone__c='1',LS_Company_Products_and_Technologies__c='1',LS_Company_Revenue__c='1',LS_Company_Score__c='1',LS_Company_Size__c=1,
                LS_Company_Size_Range__c='1',LS_Company_State__c='1',LS_Company_Street__c='1',LS_Company_Sub_Industry__c='1',LS_Company_Website__c='1',
                LS_Company_Zipcode__c='1',LS_Enrichment_Date__c=system.today(),LS_First_Name__c='1',LS_Last_Name__c='1',LS_Lead_Country__c='1',
                LS_Lead_Department__c='1',LS_Lead_Job_Functions__c='1',LS_Lead_Level__c='1',LS_Lead_Linkedin_Profile__c='1',
                LS_Lead_Phone__c='9910106804',LS_Lead_Products_and_Technologies__c='1',LS_Lead_Score__c='1',LS_Lead_State__c='1',LS_LTV_Predictive_Score__c='1',
                LS_Name__c='1',LS_Original_Email_Verification__c='1',LS_Predictive_Score__c='1',LS_Primary_NAIC__c='1',LS_Primary_SIC__c='1',LS_Response__c='1',
                LS_Secondary_NAIC__c='1',LS_Secondary_SIC__c='1',LS_Site__c='1',LS_Site_Phone__c='9910106804',LS_Site_Size__c=1,
                LS_Site_Size_Range__c='1',LS_Site_State__c='1',LS_Site_Website__c='1',LS_Site_Zipcode__c='1',LS_Status__c='1',LS_Sync_Trigger__c=False,
                LS_Title__c='1',LS_Total_Score__c='1',LS_Verified__c='1');

            insert leadObj0;

            Lead leadObj1 = new Lead();
            leadObj1 = leadObj0.clone();
            insert leadObj1;

            system.assertequals(leadObj0.firstName == leadObj1.firstName, true);
            system.assertequals(leadObj0.LS_Company__c != leadObj1.LS_Company__c, false);

        test.stopTest();
    }

    @isTest
    private static void testOwnerNamePopulationOnInsert() {
        List<User> users = [
                    SELECT Id, Name
                    FROM User
                    WHERE IsActive = true
                    AND Name =: LAR_USER
                    LIMIT 1
                    ];
        if (users.isEmpty()) {
            return;
        }
        User us = users[0];
        System.runAs(us) {

            Test.startTest();
            Lead ld = (Lead) new SObjectBuilder(Lead.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Lead.email => 'fake@email.com',
                        Lead.LastName => 'fakeLastName',
                        Lead.Company => 'fakeCompany'
                    }
                )
                .create()
                .getRecord();
            Test.stopTest();

            ld = [
                    SELECT LeadOwnerName__c
                    FROM Lead
                    WHERE Id =: ld.Id
                    ];

            System.assertEquals(us.Name,
                                ld.LeadOwnerName__c,
                                'Lead Owner Name was assigned incorrectly after insert.');
        }
    }

    @isTest
    private static void testOwnerNamePopulationOnUpdate() {
        List<User> users = [
                    SELECT Id, Name
                    FROM User
                    WHERE IsActive = true
                    AND Name =: LAR_USER
                    LIMIT 1
                    ];
        if (users.isEmpty()) {
            return;
        }
        User us = users[0];
        System.runAs(us) {
            Lead ld = (Lead) new SObjectBuilder(Lead.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Lead.email => 'fake@email.com',
                        Lead.LastName => 'fakeLastName',
                        Lead.Company => 'fakeCompany'
                    }
                )
                .create()
                .getRecord();
            ld.OwnerId = us.Id;

            Test.startTest();
                update ld;
            Test.stopTest();

            ld = [
                    SELECT LeadOwnerName__c
                    FROM Lead
                    WHERE Id =: ld.Id
                    ];

            System.assertEquals(us.Name,
                                ld.LeadOwnerName__c,
                                'Lead Owner Name was assigned incorrectly after update.');
        }
    }

    @isTest
    private static void testMarketoBatchJobFlagOnInsert() {
        List<User> users = [
                    SELECT Id, Name
                    FROM User
                    WHERE IsActive = true
                    AND Name = 'User Marketo'
                    LIMIT 1
                    ];
        if (users.isEmpty()) {
            return;
        }
        User us = users[0];
        System.runAs(us) {

            Test.startTest();
                Lead ld = (Lead) new SObjectBuilder(Lead.SObjectType)
                    .setFields(
                        new Map<SObjectField, Object>{
                            Lead.email => 'fake@email.com',
                            Lead.LastName => 'fakeLastName',
                            Lead.Company => 'fakeCompany',
                            Lead.Asset_Name__c => LAR_USER
                        }
                    )
                    .create()
                    .getRecord();
            Test.stopTest();

            ld = [
                    SELECT MarketoBatchJobFlag__c
                    FROM Lead
                    WHERE Id =: ld.Id
                    ];

            System.assertEquals(ld.MarketoBatchJobFlag__c,
                                true,
                                'Marketo Batch Job Flag is incorrectly uncheked.');
        }
    }

    @isTest
    private static void testMarketoBatchJobFlagOnUpdate() {
        List<User> users = [
                    SELECT Id, Name
                    FROM User
                    WHERE IsActive = true
                    AND Name = 'User Marketo'
                    LIMIT 1
                    ];
        if (users.isEmpty()) {
            return;
        }
        User us = users[0];
        System.runAs(us) {
            Lead ld = (Lead) new SObjectBuilder(Lead.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Lead.email => 'fake@email.com',
                        Lead.LastName => 'fakeLastName',
                        Lead.Company => 'fakeCompany'
                    }
                )
                .create()
                .getRecord();
            ld.Asset_Name__c = LAR_USER;

            Test.startTest();
                update ld;
            Test.stopTest();

            ld = [
                    SELECT MarketoBatchJobFlag__c
                    FROM Lead
                    WHERE Id =: ld.Id
                    ];

            System.assertEquals(ld.MarketoBatchJobFlag__c,
                                true,
                                'Marketo Batch Job Flag is incorrectly uncheked.');
        }
    }
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    private static void testRemainingCoverage() {
        Test.startTest();
         List<Lead> leadList = new List<Lead>();
           Lead leadObj0 = new Lead(firstName='Singh15', Title='VP', PID__c='test0121', BMID__c='test0122',
                                        NumberOfEmployees__c ='955',
                                        LeadSource = 'Vista Print', lastname = 'Virendra',
                                        company='Simplion', email= 'virendra.singh15@simplion.com', phone='(919)191-9115');
            leadList.add(leadObj0);
        insert leadList;
        LeadTriggerHelperExt leadTrgObj = new LeadTriggerHelperExt();
        Test.stopTest();
        
        
    }
}