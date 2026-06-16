@isTest
private class Test_ConvertLeadOptimize {

    private static User testUser = createUser('test');

    private static User createUser(String name) {
        User user = new User(
            Username = name+'!user@gmail.com',
            LastName = 'Test'+name,
            Email = name+'_user@gmail.com',
            Alias = 'test'+name,
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = [SELECT Id, Name FROM Profile WHERE Name = 'System Administrator'].Id,
            LanguageLocaleKey = 'en_US'
        );
        insert user;
        return user;
    }


    public static Set<Id> diffBetweenIdSets(Set<Id> setA, Set<Id> setB) {

        setA = setA.clone();
        setB = setB.clone();

        Set<Id> result = setA.clone();
        result.removeAll(setB);
        setB.removeAll(setA);
        result.addAll(setB);

        return result;
    }

    @isTest 
    public static void testConvert_SalesLead_withCreateNewAccount() {

        LeadRoutingSettings__c lrs = LeadRoutingSettings__c.getOrgDefaults();
        lrs.LeanDataUserId__c = HardcodedIdsMapper.getMatchedObjectId('0053400000C176u');
        lrs.RoutingSystemUserId__c = HardcodedIdsMapper.getMatchedObjectId('00580000005USPT');
        lrs.RoutingSystemReason__c = 'PR PER LAR SYSTEM USER';
        lrs.IsBypassProtectionRouting__c = false;
        upsert lrs LeadRoutingSettings__c.Id;

        System.runAs(testUser) {
            Id larUserId = [SELECT Id FROM User where Name = 'LAR System User' limit 1].Id;
            Id currentUserId = UserInfo.getUserId();

            Account testAcc = new Account(Name = 'testAcc');
            insert testAcc;
			
            String testEmailValue = 'test@test.test';
            String testPhoneValue = '111222333';

            Contact testContact = new Contact(
                LastName = 'testLastName',
                email = testEmailValue,
                phone = testPhoneValue,
                AccountId = testAcc.Id
            );
            insert testContact;

            Opportunity testOpp = new Opportunity(
                Name = 'testOpp',
                StageName = '3. ActivePipe',
                AccountId = testAcc.Id,
                RecordTypeId = OpportunityHelper.RT_ID_SALES_OPPORTUNITY
            );
            insert testOpp;

            String testLeadSource = 'Inbound Call';
            String testCurrency = 'USD';
            String testRCEdition = 'Standard';
            String testRCTerm = 'Monthly';
            String testTierName = 'Office';

            Lead testLead = new Lead(
                Email = testEmailValue,
                LastName = 'testLead',
                Company = 'testCompany',
                phone = testPhoneValue,
                RecordTypeId = LeadHelper.RT_ID_SALES_LEADS,
                Status = 'X. Suspect',
                OwnerId = currentUserId,
                Website = 'www.testWebsite.com',
                NumberOfEmployees = 10,
                CurrencyIsoCode = testCurrency,
                Industry = 'Computer, Technology, Internet',
                Employees_Override__c = 'Just me',
                LS_Company_Size__c = 11,
                LS_Company_Size_Range__c = '10-49',
                Number_of_Locations__c = '1',
                Forecasted_Contact_Center_Users__c = 11,
                Referrer_FName__c = 'test referrer FName',
                Referrer_LName__c = 'test referrer LName',
                Referrer_Email__c = 'test@referrer.email',
			//CMR - 272783 - commented for deletion
                //AH_Link_Source__c = 'Vendor',
                FirstName = 'TestLeadFName',
                First_Lead_Source__c = 'Inbound Call',
                LeadSource = testLeadSource,
                Lead_Brand_Name__c = 'RingCentral',
                LS_Company_City__c = 'Ha Noi',
                LS_Company_Country__c = 'Netherlands',
                LS_Company_Industry__c = 'Computer, Technology, Internet',
                LS_Company_Score__c = '0.0',
                LS_Company_Website__c = 'http://www.google.nl',
                LS_Company__c = 'testCompany',
                LS_Original_Email_Verification__c = 'INVALID',
                LS_Site_Website__c = 'http://www.google.nl',
                LS_Site__c = 'testCompany',
                LS_Status__c = 'Company Enriched',
                LS_Total_Score__c = '0',
                LS_Verified__c = 'Not Verified',
                Number_of_Users__c = 1,
                Original_Lead_Owner_Name__c = 'Alexander Moskvin',
                Owner_Manager_Email__c = 'nsergienko=aquivalabs.com@example.com',
                Owner_Manager_Name__c = 'Nikita Sergienko',
                RC_Edition__c = testRCEdition,
                RC_Term__c = testRCTerm,
                Lead_Tier_Name__c = testTierName,
                Bt_Cug_number__c='Test',
                Partner_Contact__c=testContact.id
                
            );
            insert testLead;
            
            Lead_Qualification__c leadQualif = new Lead_Qualification__c(
                Lead__c = testLead.Id
            );
            insert leadQualif;

            Demand_Funnel__c testDemandFunnel = new Demand_Funnel__c(
                Account__c = testAcc.Id,
                Contact__c = testContact.Id,
                Lead__c = testLead.Id
            );
            insert testDemandFunnel;

            Document testDoc = new Document(
                Body = Blob.valueOf('testBodyContent'),
                Name = 'Product_Forecast_Amounts',
                FolderId = UserInfo.getUserId()
            );
            insert testDoc;

            List<Document> docList = [SELECT body,
                    bodyLength, ContentType, Url
                FROM Document
                WHERE Name = 'Product_Forecast_Amounts'];


            PageReference pageRef = Page.convertLeadVFPage;
            Test.setCurrentPage(pageRef);

            ApexPages.currentPage().getParameters().put('id', testLead.Id);

            Map<Id, Account> accListBeforeConvert = new Map<Id, Account>([SELECT Id FROM Account]);
            Set<Id> allAccIdBeforeConvert = accListBeforeConvert.keySet();

            Map<Id, Opportunity> allOppListBeforeConvert = new Map<Id, Opportunity>([SELECT Id FROM Opportunity]);
            Set<Id> allOppIdBeforeConvert = allOppListBeforeConvert.keySet();

            Test.startTest();

                Emails__c email = new Emails__c(
                    Name = 'fake',
                    Email_Address__c = 'fake@email.com');
                insert email;

                ConvertLeadOptimize cntrlr = new ConvertLeadOptimize();

                // turn checkbox "Create a new Account" to true
                cntrlr.createNew = true;

                // start LeadConversion
                PageReference pr = cntrlr.convertAndMerge();

                String resultUrl = pr.getUrl();
                Id newOppId = (Id) resultUrl.substring(1, resultUrl.length());

                Map<Id, Account> accListAfterConvert = new Map<Id, Account>([SELECT Id FROM Account]);
                Set<Id> allAccIdAfterConvert = accListAfterConvert.keySet();

                System.assert(
                    allAccIdBeforeConvert.size() < allAccIdAfterConvert.size(),
                    'it is looks like a new account is not created'
                );

                // find created account Id
                Set<Id> newAccIdSet = diffBetweenIdSets(allAccIdBeforeConvert, allAccIdAfterConvert);

                // check new Account is created(his id does not contains in account id set created before conversion)
                System.assert(!allAccIdBeforeConvert.containsAll(newAccIdSet));


                Map<Id, Opportunity> allOppListAfterConvert = new Map<Id, Opportunity>([SELECT Id FROM Opportunity]);
                Set<Id> allOppIdAfterConvert = allOppListAfterConvert.keySet();

                System.assert(
                    allOppIdBeforeConvert.size() < allOppIdAfterConvert.size(),
                    'it is looks like a new opportunity is not created'
                );

                // check oppId returned after convert is new(it does not contains in oppId set created before lead conversion)
                System.assert(!allOppIdBeforeConvert.contains(newOppId));

            Test.stopTest();


            Opportunity convertedOpp = [SELECT Id, closedate, Type, Partner_ID__c,
                    Description, StageName, Timezone__c,
                    Agent_Email_Address__c, AccountId,
                    Primary_Opportunity_Contact__c, OwnerId, Owner.Name, RecordType.DeveloperName
                FROM Opportunity WHERE Id = :newOppId];

            System.assert(
                convertedOpp.RecordType.DeveloperName == 'New_Sales_Opportunity',
                'after converting Lead with "Sales Leads" recordType Opportunity must have "New_Sales_Opportunity" recordType'
            );

            // check reselected Lead
            Lead reselectedLead = [SELECT Id, CurrencyIsoCode, Lead_Owner_Phone_Number__c, indexedPhone__c, Email,
                    Lead_Active_Date__c, LeadSource, Description, Status, Most_Recent_Campaign__c,
                    Original_Phone_Number__c, Phone, Demographic_Score__c, Behavior_Score__c,
                    BMID__c, PID__c, AID__c, Time_Frame__c, indexedEmail__c, Lead_Score__c,
                    Effective_No_of_Employees_Range__c, OwnerId, LAR_Source__c, Lead_Submitter_Id__c,
                    Assignment_Source_hidden__c, ConvertedOpportunityId, ConvertedContactId, ConvertedAccountId
                FROM Lead WHERE Id = :testLead.Id];

            System.assert(
                reselectedLead.ConvertedOpportunityId == newOppId,
                'reselectedLead.ConvertedOpportunityId does not equal to Id returned after cntrlr.convertAndMerge()'
            );
            System.assert(reselectedLead.ConvertedOpportunityId == convertedOpp.Id);
            System.assert(
                newAccIdSet.contains(reselectedLead.ConvertedAccountId),
                'reselectedLead.ConvertedAccountId does not equal to createdAccount Id'
            );

            Contact convertedContact = [SELECT Id,
                DFR_Status__c, indexedPhone__c, indexedEmail__c
            FROM Contact
            WHERE Id = :reselectedLead.ConvertedContactId];

            System.assert(reselectedLead.Original_Phone_Number__c == reselectedLead.Phone);
            System.assert(convertedContact.indexedPhone__c == reselectedLead.Phone);
            System.assert(convertedContact.indexedEmail__c == reselectedLead.Email);


            // reselectedLead.OwnerId must be equal to "LAR System User"
            Boolean sysIntegUser = [SELECT Id, Systems_Integration_Users__c FROM User WHERE Id = :UserInfo.getUserId()].Systems_Integration_Users__c;
            if(!sysIntegUser) {

                System.assert(reselectedLead.OwnerId == larUserId);

                System.assert(reselectedLead.Assignment_Source_hidden__c == 'PR PER LAR SYSTEM USER');

                System.assert(reselectedLead.Lead_Submitter_Id__c == currentUserId);

                System.assert(
                    convertedContact.DFR_Status__c == DG_DFR_Class.STATUS_CONTACTED,
                    'convertedContact.DFR_Status__c not equal to convertedLead.Status'
                );


                Demand_Funnel__c reselectedDF = [SELECT Id, Opportunity__c, Contact__c, Account__c, SQL_Lead_Source__c,
                        SQL_Campaign__c, SQL_Demographic_Score__c, SQL_Behavior_Score__c, SQL_Score__c, SQL_BMID__c,
                        SQL_PID__c, SQL_Lead_Score_Category__c, SQL_AID__c, SQL_Employee_Size__c,
                        SQL_Purchase_Timeframe__c, SQL_Entered_From__c, SAL_Exited_To__c, Pre_Opportunity_Status__c,
                        DFR_Primary_Role__c
                    FROM Demand_Funnel__c
                    WHERE Id = :testDemandFunnel.Id];

                System.assert(
                    reselectedDF.Account__c == reselectedLead.ConvertedAccountId,
                    'Demand_Funnel__c.Account__c must be equal to convertedAccountId'
                );
                System.assert(
                    reselectedDF.DFR_Primary_Role__c == true,
                    'DFR_Primary_Role__c must be true'
                );

                // check that field values are copied FROM Lead To Demand_Funnel__c object
                System.assert(
                    reselectedDF.Opportunity__c == newOppId,
                    'Demand_Funnel__c.Opportunity__c must be equal to ConvertedOpportunityId'
                );
                System.assert(
                    reselectedDF.SQL_Lead_Source__c == reselectedLead.LeadSource,
                    'Demand_Funnel__c.SQL_Lead_Source__c must be equal to ConvertedLead.LeadSource'
                );
                System.assert(
                    reselectedDF.SQL_Campaign__c == reselectedLead.Most_Recent_Campaign__c,
                    'Demand_Funnel__c.SQL_Campaign__c must be equal to ConvertedLead.Most_Recent_Campaign__c'
                );
                System.assert(
                    reselectedDF.SQL_Demographic_Score__c == reselectedLead.Demographic_Score__c,
                    'Demand_Funnel__c.SQL_Demographic_Score__c must be equal to ConvertedLead.Demographic_Score__c'
                );
                System.assert(
                    reselectedDF.SQL_Behavior_Score__c == reselectedLead.Behavior_Score__c,
                    'Demand_Funnel__c.SQL_Behavior_Score__c must be equal to ConvertedLead.Behavior_Score__c'
                );
                System.assert(
                    reselectedDF.SQL_BMID__c == reselectedLead.BMID__c,
                    'Demand_Funnel__c.SQL_BMID__c must be equal to ConvertedLead.BMID__c'
                );
                System.assert(
                    reselectedDF.SQL_PID__c == reselectedLead.PID__c,
                    'Demand_Funnel__c.SQL_PID__c must be equal to ConvertedLead.PID__c'
                );
                System.assert(
                    reselectedDF.SQL_AID__c == reselectedLead.AID__c,
                    'Demand_Funnel__c.SQL_AID__c must be equal to ConvertedLead.AID__c'
                );
                System.assert(
                    reselectedDF.SQL_Purchase_Timeframe__c == reselectedLead.Time_Frame__c,
                    'Demand_Funnel__c.SQL_Purchase_Timeframe__c must be equal to ConvertedLead.Time_Frame__c'
                );
                System.assert(
                    reselectedDF.SQL_Lead_Score_Category__c == reselectedLead.Lead_Score__c,
                    'Demand_Funnel__c.SQL_Lead_Score_Category__c must be equal to ConvertedLead.Lead_Score__c'
                );
            }

            System.assert(reselectedLead.CurrencyIsoCode == 'USD', 'currencyIsoCode for converted Lead is not USD');

            // check OpportunityContactRole is created
            List<OpportunityContactRole> ocrList = [SELECT Id, IsPrimary, OpportunityId, ContactId FROM OpportunityContactRole];

            System.assert(ocrList.size() > 0, 'OpportunityContactRole not created');
            System.assert(ocrList[0].OpportunityId == newOppId);
            System.assert(ocrList[0].isPrimary == true, 'created OpportunityContactRole is not primary');
        }
    }

    @isTest 
    public static void testConvert_PartnerLead_withCreateNewAccount() {
        Triggers.switchOff();
        User testLarUser = createUser('lar');

        LeadRoutingSettings__c lrs = LeadRoutingSettings__c.getOrgDefaults();
        lrs.LeanDataUserId__c = HardcodedIdsMapper.getMatchedObjectId('0053400000C176u');
        lrs.RoutingSystemUserId__c = testLarUser.Id;
        lrs.RoutingSystemReason__c = 'PR PER LAR SYSTEM USER';
        lrs.IsBypassProtectionRouting__c = false;
        upsert lrs LeadRoutingSettings__c.Id;

        System.runAs(testUser) {

            Id currentUserId = UserInfo.getUserId();
            Emails__c email = new Emails__c(
                Name = 'fake',
                Email_Address__c = 'fake@email.com');
            insert email;

            // test data
            Account testAcc = new Account(Name = 'testAcc');
            insert testAcc;

            String testEmailValue = 'test@test.test';
            String testPhoneValue = '111222333';

            Contact testContact = new Contact(
                LastName = 'testLastName',
                email = testEmailValue,
                phone = testPhoneValue,
                AccountId = testAcc.Id
            );
            insert testContact;

            Opportunity testOpp = new Opportunity(
                Name = 'testOpp',
                StageName = '3. ActivePipe',
                AccountId = testAcc.Id,
                RecordTypeId = OpportunityHelper.RT_ID_SALES_OPPORTUNITY,
                CloseDate = Date.today().addDays(30)
            );
            insert testOpp;


            String testLeadSource = 'Inbound Call';

            Lead testLead = new Lead(
                Email = testEmailValue,
                LastName = 'testLead',
                Company = 'testCompany',
                phone = testPhoneValue,
                RecordTypeId = LeadHelper.RT_ID_PARTNER_LEADS,
                Status = 'X. Suspect',
                OwnerId = currentUserId,
                Agent_Email_Address__c = 'testAgent@email.com',
                Website = 'www.testWebsite.com',
                NumberOfEmployees = 10,
                Industry = 'Computer, Technology, Internet',
                Employees_Override__c = 'Just me',
                LS_Company_Size__c = 11,
                LS_Company_Size_Range__c = '10-49',
                Number_of_Locations__c = '1',
                Forecasted_Contact_Center_Users__c = 11,
                Referrer_FName__c = 'test referrer FName',
                Referrer_LName__c = 'test referrer LName',
                Referrer_Email__c = 'test@referrer.email',
                //CMR - 272783 - commented for deletion
			//AH_Link_Source__c = 'Vendor',
                FirstName = 'TestLeadFName',
                First_Lead_Source__c = 'Inbound Call',
                LeadSource = testLeadSource,
                Lead_Brand_Name__c = 'RingCentral',
                LS_Company_City__c = 'Ha Noi',
                LS_Company_Country__c = 'Netherlands',
                LS_Company_Industry__c = 'Computer, Technology, Internet',
                LS_Company_Score__c = '0.0',
                LS_Company_Website__c = 'http://www.google.nl',
                LS_Company__c = 'testCompany',
                LS_Original_Email_Verification__c = 'INVALID',
                LS_Site_Website__c = 'http://www.google.nl',
                LS_Site__c = 'testCompany',
                LS_Status__c = 'Company Enriched',
                LS_Total_Score__c = '0',
                LS_Verified__c = 'Not Verified',
                Estimated_Close_Date__c = Date.today(),
                Number_of_Users__c = 1,
                Original_Lead_Owner_Name__c = 'Alexander Moskvin',
                Owner_Manager_Email__c = 'nsergienko=aquivalabs.com@example.com',
                Owner_Manager_Name__c = 'Nikita Sergienko',
                RC_Edition__c = 'Standard',
                RC_Term__c = 'Monthly',
                Bt_Cug_number__c='Test',
                Partner_Contact__c=testContact.id
            );
            insert testLead;
			
            Lead_Qualification__c leadQualif = new Lead_Qualification__c(
                Lead__c = testLead.Id,
                Decision_Maker_Partner__c = 'Details Below',
                Decision_Maker_Last_Name__c = 'test_DecisionMaker_LastName',
                Decision_Maker_First_Name__c = 'test_DecisionMaker_FirstName',
                Decision_Maker_Email__c = 'test@email.com',
                Decision_Maker_Phone__c = '555666777',
                Decision_Maker_Business_Title__c = 'some_title'
            );
            insert leadQualif;
         
            Demand_Funnel__c testDemandFunnel = new Demand_Funnel__c(
                Account__c = testAcc.Id,
                Contact__c = testContact.Id,
                Lead__c = testLead.Id
            );
            insert testDemandFunnel;

            Document testDoc = new Document(
                Body = Blob.valueOf('testBodyContent'),
                Name = 'Product_Forecast_Amounts',
                FolderId = UserInfo.getUserId()
            );
            insert testDoc;

            List<Document> docList = [SELECT body,
                    bodyLength, ContentType, Url
                FROM Document
                WHERE Name = 'Product_Forecast_Amounts'];

            PageReference pageRef = Page.convertLeadVFPage;
            Test.setCurrentPage(pageRef);

            ApexPages.currentPage().getParameters().put('id', testLead.Id);


            Map<Id, Account> accListBeforeConvert = new Map<Id, Account>([SELECT Id FROM Account]);
            Set<Id> allAccIdBeforeConvert = accListBeforeConvert.keySet();

            Map<Id, Contact> contListBeforeConvert = new Map<Id, Contact>([SELECT Id FROM Contact]);
            Set<Id> allContIdBeforeConvert = contListBeforeConvert.keySet();

            Map<Id, Opportunity> allOppListBeforeConvert = new Map<Id, Opportunity>([SELECT Id FROM Opportunity]);
            Set<Id> allOppIdBeforeConvert = allOppListBeforeConvert.keySet();

            
            Test.startTest();
                ConvertLeadOptimize cntrlr = new ConvertLeadOptimize();

                // turn checkbox "Create a new Account" to true
                cntrlr.createNew = true;

                // start LeadConversion
                PageReference pr = cntrlr.convertAndMerge();
                String resultUrl='';
                if(pr!=null){
                resultUrl = pr.getUrl();
                Id newOppId= (Id) resultUrl.substring(1, resultUrl.length());

                Test.stopTest();
            Triggers.switchOn();
                Map<Id, Account> accListAfterConvert = new Map<Id, Account>([SELECT Id FROM Account]);
                Set<Id> allAccIdAfterConvert = accListAfterConvert.keySet();

                System.assert(
                    allAccIdBeforeConvert.size() < allAccIdAfterConvert.size(),
                    'it is looks like a new account is not created'
                );

                // find created account Id
                Set<Id> newAccIdSet = diffBetweenIdSets(allAccIdBeforeConvert, allAccIdAfterConvert);

                // check new Account is created(his id does not contains in account id set created before conversion)
                System.assert(!allAccIdBeforeConvert.containsAll(newAccIdSet));
  
                Map<Id, Contact> contListAfterConvert = new Map<Id, Contact>([SELECT Id FROM Contact]);
                Set<Id> allContIdAfterConvert = contListAfterConvert.keySet();

                System.assert(
                    allContIdBeforeConvert.size() < allContIdAfterConvert.size(),
                    'it is looks like a new contact is not created'
                );

                // find created contact Id
                Set<Id> newContIdSet = diffBetweenIdSets(allContIdBeforeConvert, allContIdAfterConvert);

                // check new Contact is created(his id does not contains in contact id set created before conversion)
                System.assert(!allContIdBeforeConvert.containsAll(newContIdSet));


                Map<Id, Opportunity> allOppListAfterConvert = new Map<Id, Opportunity>([SELECT Id FROM Opportunity]);
                Set<Id> allOppIdAfterConvert = allOppListAfterConvert.keySet();

                System.assert(
                    allOppIdBeforeConvert.size() < allOppIdAfterConvert.size(),
                    'it is looks like a new opportunity is not created'
                );

                // check oppId returned after convert is new(it does not contains in oppId set created before lead conversion)
                System.assert(!allOppIdBeforeConvert.contains(newOppId));

            Opportunity convertedOpp = [SELECT Id, closedate, Type, Partner_ID__c, Website__c,
                    Description, StageName, Timezone__c,
                    Agent_Email_Address__c, AccountId,
                    Primary_Opportunity_Contact__c, OwnerId, Owner.Name, RecordType.DeveloperName
                FROM Opportunity WHERE Id = :newOppId];

            System.assert(
                convertedOpp.RecordType.DeveloperName == 'VAR_Opportunity',
                'after converting Lead with "Partner Leads" recordType Opportunity must have "VAR_Opportunity" recordType'
            );


            Lead reselectedLead = [SELECT Id, CurrencyIsoCode, Lead_Owner_Phone_Number__c, indexedPhone__c, Email,
                    Industry, Lead_Active_Date__c, LeadSource, Description, Status,
                    Most_Recent_Campaign__c, Original_Phone_Number__c, Phone, Demographic_Score__c, Behavior_Score__c,
                    BMID__c, PID__c, AID__c, Time_Frame__c, indexedEmail__c, Lead_Score__c,
                    Effective_No_of_Employees_Range__c, OwnerId, LAR_Source__c, Website, Timezone__c,
                    Lead_Submitter_Id__c, Assignment_Source_hidden__c, Account_Number__c, LeadPartnerID__c,
                    Agent_Email_Address__c, City, Country, Street_2__c, PostalCode, State, Street,
                    Phone_Ext__c, Title, FirstName, LastName, ConvertedOpportunityId, ConvertedContactId,
                    ConvertedAccountId
                FROM Lead
                WHERE Id = :testLead.Id];

            System.assert(newAccIdSet.contains(reselectedLead.ConvertedAccountId));
			
            Account convertedAccount = [SELECT Id, Phone, Industry, Description, BillingStreet, BillingCity,
                    BillingCountry, BillingPostalCode, BillingState, ShippingCity, ShippingCountry, ShippingPostalCode,
                    ShippingState, ShippingStreet, Website, NumberOfEmployees, Inside_Sales_Rep__c, Signup_Link__c,
                    RC_Sync_Status__c, Name
                FROM Account
                WHERE Id = :reselectedLead.ConvertedAccountId];
            
            System.assert(newContIdSet.contains(reselectedLead.ConvertedContactId));
			
            Contact convertedContact = [SELECT Id, FirstName, LastName, OwnerId, Description, Email, Contact_Status__c,
                    Contact_Funnel_Type__c, DFR_Status__c, Street_2__c, Phone, Phone_Ext__c,
                    MailingCity, MailingCountry, MailingPostalCode, MailingState, MailingStreet, Title,
                    indexedPhone__c, indexedEmail__c, LeadSource
                FROM Contact where Id = :reselectedLead.ConvertedContactId];

            System.assert(
                convertedContact.Email == reselectedLead.Email,
                convertedContact.Email + ' != ' + reselectedLead.Email
            );
            System.assert(
                convertedContact.FirstName == reselectedLead.FirstName,
                convertedContact.FirstName + ' != ' + reselectedLead.FirstName
            );
            System.assert(
                convertedContact.LastName == reselectedLead.LastName,
                convertedContact.LastName + ' != ' + reselectedLead.LastName
            );
            System.assert(
                convertedContact.LeadSource == reselectedLead.LeadSource,
                convertedContact.LeadSource + ' != ' + reselectedLead.LeadSource
            );
            System.assert(
                convertedContact.MailingCity == reselectedLead.City,
                convertedContact.MailingCity + ' != ' + reselectedLead.City
            );
            System.assert(
                convertedContact.MailingCountry == reselectedLead.Country,
                convertedContact.MailingCountry + ' != ' + reselectedLead.Country
            );
            System.assert(
                convertedContact.MailingPostalCode == reselectedLead.PostalCode,
                convertedContact.MailingPostalCode + ' != ' + reselectedLead.PostalCode
            );
            System.assert(
                convertedContact.MailingState == reselectedLead.State,
                convertedContact.MailingState + ' != ' + reselectedLead.State
            );
            System.assert(
                convertedContact.MailingStreet == reselectedLead.Street,
                convertedContact.MailingStreet + ' != ' + reselectedLead.Street
            );
            System.assert(
                convertedContact.Street_2__c == reselectedLead.Street_2__c,
                convertedContact.Street_2__c + ' != ' + reselectedLead.Street_2__c
            );
            System.assert(
                convertedContact.Phone == reselectedLead.Phone,
                convertedContact.Phone + ' != ' + reselectedLead.Phone
            );
            System.assert(
                convertedContact.Phone_Ext__c == reselectedLead.Phone_Ext__c,
                convertedContact.Phone_Ext__c + ' != ' + reselectedLead.Phone_Ext__c
            );
            System.assert(
                convertedContact.Title == reselectedLead.Title,
                convertedContact.Title + ' != ' + reselectedLead.Title
            );
            System.assert(
                convertedContact.indexedPhone__c == reselectedLead.Phone,
                convertedContact.indexedPhone__c + ' != ' + reselectedLead.Phone
            );
            System.assert(
                convertedContact.indexedEmail__c == reselectedLead.Email,
                convertedContact.indexedEmail__c + ' != ' + reselectedLead.Email
            );

            System.assert(
                convertedContact.DFR_Status__c == DG_DFR_Class.STATUS_CONTACTED,
                convertedContact.DFR_Status__c + ' != ' + ' convertedLead.Status'
            );

            System.assert(
                reselectedLead.ConvertedOpportunityId == newOppId,
                'reselectedLead.ConvertedOpportunityId does not equal to Id returned after cntrlr.convertAndMerge()'
            );
            System.assert(reselectedLead.ConvertedOpportunityId == convertedOpp.Id);
            System.assert(
                newAccIdSet.contains(reselectedLead.ConvertedAccountId),
                'reselectedLead.ConvertedAccountId does not equal to createdAccount Id'
            );


            System.assert(reselectedLead.Original_Phone_Number__c == reselectedLead.Phone);

            System.assert(convertedContact.indexedPhone__c == reselectedLead.Phone);
            System.assert(convertedContact.indexedEmail__c == reselectedLead.Email);


            System.assert(
                reselectedLead.OwnerId == testLarUser.Id,
                'reselectedLead OwnerId is not equal to user specified in ' +
                'custom setting LeadRoutingSettings__c.RoutingSystemUserId__c(LAR User)'
            );
            System.assert(
                convertedOpp.OwnerId == testLarUser.Id,
                'convertedOpp OwnerId is not equal to specified in custom ' +
                'setting LeadRoutingSettings__c.RoutingSystemUserId__c(LAR User)'
            );
            System.assert(
                convertedOpp.Type == 'New Business',
                convertedOpp.Type + ' != "New Business"'
            );
            System.assert(
                convertedOpp.Partner_ID__c == reselectedLead.LeadPartnerID__c,
                convertedOpp.Partner_ID__c + ' != ' + reselectedLead.LeadPartnerID__c
            );
            System.assert(
                convertedOpp.StageName == OpportunityHelper.defaultOpportunityStage,
                convertedOpp.StageName + ' != ' + OpportunityHelper.defaultOpportunityStage
            );
            System.assert(
                convertedOpp.Timezone__c == reselectedLead.Timezone__c,
                convertedOpp.Timezone__c + ' != ' + reselectedLead.Timezone__c
            );
            System.assert(
                convertedOpp.Agent_Email_Address__c == reselectedLead.Agent_Email_Address__c,
                convertedOpp.Agent_Email_Address__c + ' != ' + reselectedLead.Agent_Email_Address__c
            );

            System.assert(reselectedLead.CurrencyIsoCode == 'USD', 'currencyIsoCode for converted Lead is not USD');

            // check OpportunityContactRole is created
            List<OpportunityContactRole> ocrList = [SELECT Id, IsPrimary, OpportunityId, ContactId FROM OpportunityContactRole];

            System.assert(ocrList.size() > 0, 'OpportunityContactRole not created');
            System.assert(ocrList[0].OpportunityId == newOppId);


            Demand_Funnel__c reselectedDF = [SELECT Id, Opportunity__c, Contact__c, Account__c, SQL_Lead_Source__c,
                    SQL_Campaign__c, SQL_Demographic_Score__c, SQL_Behavior_Score__c, SQL_Score__c, SQL_BMID__c,
                    SQL_PID__c, SQL_Lead_Score_Category__c, SQL_AID__c, SQL_Employee_Size__c,
                    SQL_Purchase_Timeframe__c, SQL_Entered_From__c, SAL_Exited_To__c,
                    Pre_Opportunity_Status__c, DFR_Primary_Role__c
                FROM Demand_Funnel__c
                WHERE Id = :testDemandFunnel.Id];

            System.assert(
                reselectedDF.Account__c == reselectedLead.ConvertedAccountId,
                'Demand_Funnel__c.Account__c must be equal to convertedAccountId'
            );
            System.assert(
                reselectedDF.DFR_Primary_Role__c == true,
                'DFR_Primary_Role__c must be true'
            );

            // check that field values are copied FROM Lead To Demand_Funnel__c object
            System.assert(
                reselectedDF.Opportunity__c == newOppId,
                'Demand_Funnel__c.Opportunity__c must be equal to ConvertedOpportunityId'
            );
            System.assert(
                reselectedDF.SQL_Lead_Source__c == reselectedLead.LeadSource,
                'Demand_Funnel__c.SQL_Lead_Source__c must be equal to ConvertedLead.LeadSource'
            );
            System.assert(
                reselectedDF.SQL_Campaign__c == reselectedLead.Most_Recent_Campaign__c,
                'Demand_Funnel__c.SQL_Campaign__c must be equal to ConvertedLead.Most_Recent_Campaign__c'
            );
            System.assert(
                reselectedDF.SQL_Demographic_Score__c == reselectedLead.Demographic_Score__c,
                'Demand_Funnel__c.SQL_Demographic_Score__c must be equal to ConvertedLead.Demographic_Score__c'
            );
            System.assert(
                reselectedDF.SQL_Behavior_Score__c == reselectedLead.Behavior_Score__c,
                'Demand_Funnel__c.SQL_Behavior_Score__c must be equal to ConvertedLead.Behavior_Score__c'
            );
            System.assert(
                reselectedDF.SQL_BMID__c == reselectedLead.BMID__c,
                'Demand_Funnel__c.SQL_BMID__c must be equal to ConvertedLead.BMID__c'
            );
            System.assert(
                reselectedDF.SQL_PID__c == reselectedLead.PID__c,
                'Demand_Funnel__c.SQL_PID__c must be equal to ConvertedLead.PID__c'
            );
            System.assert(
                reselectedDF.SQL_AID__c == reselectedLead.AID__c,
                'Demand_Funnel__c.SQL_AID__c must be equal to ConvertedLead.AID__c'
            );
            System.assert(
                reselectedDF.SQL_Purchase_Timeframe__c == reselectedLead.Time_Frame__c,
                'Demand_Funnel__c.SQL_Purchase_Timeframe__c must be equal to ConvertedLead.Time_Frame__c'
            );
            System.assert(
                reselectedDF.SQL_Lead_Score_Category__c == reselectedLead.Lead_Score__c,
                'Demand_Funnel__c.SQL_Lead_Score_Category__c must be equal to ConvertedLead.Lead_Score__c'
            );
        }
        }
    }

    @isTest
    public static void coverageTest() {

        System.runAs(testUser) {

            // it looks like a bug:
            // in this case(accountList[0].selected = true, newModel parameter = 1, Lead.RecordType = 'Sales Leads') both methods are launched: convertAndMerge() and convert()
            // and it will produce error in convert() method becouse lead already converted(this error not throw, becouse converted() method wrapped in try/catch)

            // insert test data
            Emails__c email = new Emails__c(
                Name = 'fake',
                Email_Address__c = 'fake@email.com');
            insert email;

            Account testAcc = new Account(
                Name = 'testAcc'
            );
            insert testAcc;
            String testEmailValue = 'test@test.test';

            Contact testContact = new Contact(
                LastName = 'testLastName',
                email = testEmailValue,
                AccountId = testAcc.Id
            );
            insert testContact;

            Opportunity testOpp = new Opportunity(
                Name = 'testOpp',
                StageName = '3. ActivePipe',
                AccountId = testAcc.Id,
                RecordTypeId = OpportunityHelper.RT_ID_SALES_OPPORTUNITY
            );
            insert testOpp;

            String brandName = 'RingCentral';

            Lead testLead = new Lead(
                Email = testEmailValue,
                LastName = 'testLead',
                Company = 'testCompany',
                RecordTypeId = LeadHelper.RT_ID_SALES_LEADS,
                Lead_Brand_Name__c = brandName,
                Lead_Tier_Name__c = 'Office',
                RC_Term__c = 'Monthly',
                RC_Edition__c = 'Standard',
                Number_of_Users__c = 1,
                Website = 'www.testWebsite.com',
                NumberOfEmployees = 10,
                Industry = 'Computer, Technology, Internet',
                Employees_Override__c = 'Just me',
                LS_Company_Size__c = 11,
                LS_Company_Size_Range__c = '10-49',
                Number_of_Locations__c = '1',
                Referrer_FName__c = 'test referrer FName',
                Referrer_LName__c = 'test referrer LName',
                Referrer_Email__c = 'test@referrer.email',
                Bt_Cug_number__c='Test',
                Partner_Contact__c=testContact.id
            );
            insert testLead;
            
            Lead_Qualification__c leadQualif = new Lead_Qualification__c(
                Lead__c = testLead.Id
            );
            insert leadQualif;


            schedulerConfiguration__c sc = new schedulerConfiguration__c(
                Name = brandName
            );
            insert sc;

            Pricebook2 pb = new PriceBook2(
                Name = 'testPB',
                Service__c = 'Office',
                Edition__c = 'Standard',
                Plan__c = 'Monthly',
                IsActive = true,
                Line_Range_Min__c = 1,
                Line_Range_Max__c = 100,
                Brand__c = sc.Id
            );
            insert pb;

            Product2 testProduct = new Product2(
                Name = 'testProduct',
                Feature__c = 11,
                Sub_Feature__c = -1,
                Family = 'Discounted Phones',
                Description = 'testProduct'
            );
            insert testProduct;

            PriceBookEntry standartPbe = new PriceBookEntry(
                Pricebook2Id = Test.getStandardPricebookId(),
                Product2Id = testProduct.Id,
                CurrencyIsoCode = 'USD',
                UnitPrice = 100,
                UseStandardPrice = false,
                IsActive = true
            );
            insert standartPbe;

            PriceBookEntry pbe = new PriceBookEntry(
                Pricebook2Id = pb.Id,
                Product2Id = testProduct.Id,
                CurrencyIsoCode = 'USD',
                UnitPrice = 100,
                UseStandardPrice = false,
                IsActive = true
            );
            insert pbe;

            PageReference pageRef = Page.convertLeadVFPage;
            Test.setCurrentPage(pageRef);

            ApexPages.currentPage().getParameters().put('id', testLead.Id);
            ApexPages.currentPage().getParameters().put('retURL', 'www.example.com');
            ApexPages.currentPage().getParameters().put('newmodel', '1');

            Test.startTest();

                Map<Id, Account> accListBeforeConvert = new Map<Id, Account>([SELECT Id FROM Account]);
                Set<Id> allAccIdBeforeConvert = accListBeforeConvert.keySet();

                Map<Id, Contact> contListBeforeConvert = new Map<Id, Contact>([SELECT Id FROM Contact]);
                Set<Id> allContIdBeforeConvert = contListBeforeConvert.keySet();

                Map<Id, Opportunity> allOppListBeforeConvert = new Map<Id, Opportunity>([SELECT Id FROM Opportunity]);
                Set<Id> allOppIdBeforeConvert = allOppListBeforeConvert.keySet();

                ConvertLeadOptimize cntrlr = new ConvertLeadOptimize();

                cntrlr.accountList[0].selected = true;

                List<String> initCategoryValues = cntrlr.getListInitialCategoryValues();
                List<SelectOption> initCategoryItems = cntrlr.getListInitialCategoryItems();

                PageReference pr = cntrlr.convertAndMerge();

                Id newOppId = (Id) pr.getParameters().get('Id');

                TriggerHandler.BY_PASS_LEAD_UPDATE = true;
                TriggerHandler.BY_PASS_LEAD_UPDATE_ON_INSERT = true;
                PageReference updateLeadCategory = cntrlr.updateLeadCategory();
                PageReference goBack = cntrlr.GoBack();
                //PageReference createQuote = cntrlr.createQuote();

            Test.stopTest();

            PageReference additionalQLI = cntrlr.createAdditionalQuoteLineItems();
            PageReference leadBeforeConversion = cntrlr.saveLeadBeforeConversion();
            PageReference validateLead = cntrlr.validateLeadBeforeConversion();

            ConvertLeadOptimize.partnerDetailWrapper partnerContact = cntrlr.fetchPartnerContact();
            ConvertLeadOptimize.partnerDetailWrapper partnerOwner = cntrlr.fetchPartnerOwner();

            cntrlr.getl();
            cntrlr.getCreateNew();
            cntrlr.getMultipleSelected();
            cntrlr.getMatchFound();
            cntrlr.getMatchNotFound();
            cntrlr.getnotAnswered();
            cntrlr.getInitial_CategoryFlag();
            cntrlr.getstrDebug();
			cntrlr.loadLeadQualDet();
            cntrlr.getOpportunities();
            cntrlr.getPermanentOptions(initCategoryValues);
            cntrlr.setL(testLead);
            cntrlr.setCreateNew(true);
            cntrlr.setInitialCategory('New');
            
            List<Note> noteList=new List<Note>();
            Note n1=new Note();
            Note n2=new Note();
            noteList.add(n1);
            noteList.add(n2);
            cntrlr.prepareNoteList(noteList,testAcc.id);
            cntrlr.product='Fax';
            List<SelectOption> editionOptions = cntrlr.getEditionNames();
            cntrlr.product='Professional';
            List<SelectOption> editionOptions1 = cntrlr.getEditionNames();
            cntrlr.product='RC Meetings';
            List<SelectOption> editionOptions2 = cntrlr.getEditionNames();
            cntrlr.brand='BT Business';
            List<SelectOption> editionOptions3 = cntrlr.getEditionNames();
            // check new Account is created
            Map<Id, Account> accListAfterConvert = new Map<Id, Account>([SELECT Id FROM Account]);
            Set<Id> allAccIdAfterConvert = accListAfterConvert.keySet();

            System.assert(
                allAccIdBeforeConvert.size() == allAccIdAfterConvert.size(),
                'it is looks like a new(additional) account is created'
            );

            // find created account Id
            Set<Id> newAccIdSet = diffBetweenIdSets(allAccIdBeforeConvert, allAccIdAfterConvert);
            System.assert(newAccIdSet.size() == 0, 'additional account is created');

            Map<Id, Contact> contListAfterConvert = new Map<Id, Contact>([SELECT Id FROM Contact]);
            Set<Id> allContIdAfterConvert = contListAfterConvert.keySet();

            System.assert(
                allContIdBeforeConvert.size() == allContIdAfterConvert.size(),
                'it is looks like a new contact(additional) is created'
            );

            // find created contact Id
            Set<Id> newContIdSet = diffBetweenIdSets(allContIdBeforeConvert, allContIdAfterConvert);

            System.assert(newContIdSet.size() == 0, 'additional contact is created');

            Map<Id, Opportunity> allOppListAfterConvert = new Map<Id, Opportunity>([SELECT Id FROM Opportunity]);
            Set<Id> allOppIdAfterConvert = allOppListAfterConvert.keySet();

            System.assert(
                allOppIdBeforeConvert.size() < allOppIdAfterConvert.size(),
                'it is looks like a new opportunity is not created'
            );

            System.assert(!allOppIdBeforeConvert.contains(newOppId));
            TriggerHandler.RESET_VARIABLES();
        }
    }

    @isTest
    public static void coverageTest2() {

        System.runAs(testUser) {

            // insert test data
            Emails__c email = new Emails__c(
                Name = 'fake',
                Email_Address__c = 'fake@email.com');
            insert email;
            Account testAcc = new Account(
                Name = 'testAcc',
                RC_User_ID__c = '1234',
                Bt_Cug_number__c='Test'
            );
            insert testAcc;

            String testPhoneValue = '111222333';

            Contact testContact = new Contact(
                LastName = 'testLastName',
                phone = testPhoneValue,
                AccountId = testAcc.Id
            );
            insert testContact;

            Opportunity testOpp = new Opportunity(
                Name = 'testOpp',
                StageName = '3. ActivePipe',
                AccountId = testAcc.Id,
                RecordTypeId = OpportunityHelper.RT_ID_SALES_OPPORTUNITY
            );
            insert testOpp;

            String brandName = 'RingCentral';

            Lead testLead = new Lead(
                Email = 'fake@email.com',
                LastName = 'testLead',
                Company = 'testCompany',
                phone = testPhoneValue,
                RecordTypeId = LeadHelper.RT_ID_SALES_LEADS,
                Account__c = testAcc.Id,
                Lead_Brand_Name__c = brandName,
                Lead_Tier_Name__c = 'Office',
                RC_Term__c = 'Monthly',
                RC_Edition__c = 'Standard',
                Number_of_Users__c = 1,
                Website = 'www.testWebsite.com',
                Installation_Service_Provider__c = 'RC ProServices Install',
                NumberOfEmployees = 10,
                Industry = 'Computer, Technology, Internet',
                Employees_Override__c = 'Just me',
                LS_Company_Size__c = 11,
                LS_Company_Size_Range__c = '10-49',
                Number_of_Locations__c = '1',
                Referrer_FName__c = 'test referrer FName',
                Referrer_LName__c = 'test referrer LName',
                Referrer_Email__c = 'test@referrer.email',
                Notes__c = 'test notes',
                Bt_Cug_number__c='Test',
                Partner_Contact__c=testContact.id
            );
            insert testLead;
            
            Lead_Qualification__c leadQualif = new Lead_Qualification__c(
                Lead__c = testLead.Id
            );
            insert leadQualif;


            schedulerConfiguration__c sc = new schedulerConfiguration__c(
                Name = brandName
            );
            insert sc;

            Pricebook2 pb = new PriceBook2(
                Name = 'testPB',
                Service__c = 'Office',
                Edition__c = 'Standard',
                Plan__c = 'Monthly',
                IsActive = true,
                Line_Range_Min__c = 1,
                Line_Range_Max__c = 100,
                Brand__c = sc.Id
            );
            insert pb;

            Product2 testProduct = new Product2(
                Name = 'testProduct',
                Feature__c = 11,
                Sub_Feature__c = -1,
                Description = 'testProduct'
            );
            insert testProduct;

            PriceBookEntry standartPbe = new PriceBookEntry(
                Pricebook2Id = Test.getStandardPricebookId(),
                Product2Id = testProduct.Id,
                CurrencyIsoCode = 'USD',
                UnitPrice = 100,
                UseStandardPrice = false,
                IsActive = true
            );
            insert standartPbe;

            PriceBookEntry pbe = new PriceBookEntry(
                Pricebook2Id = pb.Id,
                Product2Id = testProduct.Id,
                CurrencyIsoCode = 'USD',
                UnitPrice = 100,
                UseStandardPrice = false,
                IsActive = true
            );
            insert pbe;

            PageReference pageRef = Page.convertLeadVFPage;
            Test.setCurrentPage(pageRef);

            ApexPages.currentPage().getParameters().put('id', testLead.Id);
            ApexPages.currentPage().getParameters().put('newmodel', '1');

            // check Acc count
            Map<Id, Account> accListBeforeConvert = new Map<Id, Account>([SELECT Id FROM Account]);
            Set<Id> allAccIdBeforeConvert = accListBeforeConvert.keySet();

            // check Contact count
            Map<Id, Contact> contListBeforeConvert = new Map<Id, Contact>([SELECT Id FROM Contact]);
            Set<Id> allContIdBeforeConvert = contListBeforeConvert.keySet();

            // check Opp count in order to then compare the count after Lead conversion
            Map<Id, Opportunity> allOppListBeforeConvert = new Map<Id, Opportunity>([SELECT Id FROM Opportunity]);
            Set<Id> allOppIdBeforeConvert = allOppListBeforeConvert.keySet();


            Test.startTest();

                ConvertLeadOptimize cntrlr = new ConvertLeadOptimize();


                List<String> initCategoryValues = cntrlr.getListInitialCategoryValues();
                List<SelectOption> initCategoryItems = cntrlr.getListInitialCategoryItems();

                PageReference pr = cntrlr.convertAndMerge();

                Id newOppId = (Id) pr.getParameters().get('Id');

                PageReference updateLeadCategory = cntrlr.updateLeadCategory();

            Test.stopTest();


            // check new Account is created
            Map<Id, Account> accListAfterConvert = new Map<Id, Account>([SELECT Id FROM Account]);
            Set<Id> allAccIdAfterConvert = accListAfterConvert.keySet();

            System.assert(
                allAccIdBeforeConvert.size() == allAccIdAfterConvert.size(),
                'it is looks like a new(additional) account is created'
            );

            // find created account Id
            Set<Id> newAccIdSet = diffBetweenIdSets(allAccIdBeforeConvert, allAccIdAfterConvert);
            System.assert(newAccIdSet.size() == 0, 'additional account is created');


            Map<Id, Contact> contListAfterConvert = new Map<Id, Contact>([SELECT Id FROM Contact]);
            Set<Id> allContIdAfterConvert = contListAfterConvert.keySet();

            System.assert(
                allContIdBeforeConvert.size() == allContIdAfterConvert.size(),
                'it is looks like a new contact(additional) is created'
            );

            // find created contact Id
            Set<Id> newContIdSet = diffBetweenIdSets(allContIdBeforeConvert, allContIdAfterConvert);
            System.assert(newContIdSet.size() == 0, 'additional contact is created');

            Map<Id, Opportunity> allOppListAfterConvert = new Map<Id, Opportunity>([SELECT Id FROM Opportunity]);
            Set<Id> allOppIdAfterConvert = allOppListAfterConvert.keySet();

            System.assert(
                allOppIdBeforeConvert.size() < allOppIdAfterConvert.size(),
                'it is looks like a new opportunity is not created'
            );

            // check oppId returned after convert is new(it does not contains in oppId set created before lead conversion)
            System.assert(!allOppIdBeforeConvert.contains(newOppId));
        }
    }

    @isTest
    public static void coverageTest3() {

        System.runAs(testUser) {

            // insert test data
            Emails__c email = new Emails__c(
                Name = 'fake',
                Email_Address__c = 'fake@email.com');
            insert email;
            Account testAcc = new Account(
                Name = 'testAcc',
                RC_User_ID__c = '1234',
                Bt_Cug_number__c='Test'
            );
            insert testAcc;

            String testPhoneValue = '111222333';

            Contact testContact = new Contact(
                LastName = 'testLastName',
                phone = testPhoneValue,
                AccountId = testAcc.Id
            );
            insert testContact;

            Opportunity testOpp = new Opportunity(
                Name = 'testOpp',
                StageName = '3. ActivePipe',
                AccountId = testAcc.Id,
                RecordTypeId = OpportunityHelper.RT_ID_SALES_OPPORTUNITY
            );
            insert testOpp;

            String brandName = 'RingCentral';

            Lead testLead = new Lead(
                Email = 'fake@email.com',
                LastName = 'testLead',
                Company = 'testCompany',
                phone = testPhoneValue,
                RecordTypeId = LeadHelper.RT_ID_SALES_LEADS,
                Account__c = testAcc.Id,
                Lead_Brand_Name__c = brandName,
                Lead_Tier_Name__c = 'Office',
                RC_Term__c = 'Monthly',
                RC_Edition__c = 'Standard',
                Number_of_Users__c = 1,
                Website = 'www.testWebsite.com',
                NumberOfEmployees = 10,
                Industry = 'Computer, Technology, Internet',
                Employees_Override__c = 'Just me',
                LS_Company_Size__c = 11,
                LS_Company_Size_Range__c = '10-49',
                Number_of_Locations__c = '1',
                Referrer_FName__c = 'test referrer FName',
                Referrer_LName__c = 'test referrer LName',
                Referrer_Email__c = 'test@referrer.email',
                Notes__c = 'test notes',
                Bt_Cug_number__c='Test',
                Partner_Contact__c=testContact.id
            );
            insert testLead;
			
            Lead_Qualification__c leadQualif = new Lead_Qualification__c(
                Lead__c = testLead.Id
            );
            insert leadQualif;


            schedulerConfiguration__c sc = new schedulerConfiguration__c(
                Name = brandName
            );
            insert sc;

            Pricebook2 pb = new PriceBook2(
                Name = 'testPB',
                Service__c = 'Office',
                Edition__c = 'Standard',
                Plan__c = 'Monthly',
                IsActive = true,
                Line_Range_Min__c = 1,
                Line_Range_Max__c = 100,
                Brand__c = sc.Id
            );
            insert pb;

            Product2 testProduct = new Product2(
                Name = 'testProduct',
                Feature__c = 11,
                Sub_Feature__c = -1,
                Description = 'testProduct'
            );
            insert testProduct;

            PriceBookEntry standartPbe = new PriceBookEntry(
                Pricebook2Id = Test.getStandardPricebookId(),
                Product2Id = testProduct.Id,
                CurrencyIsoCode = 'USD',
                UnitPrice = 100,
                UseStandardPrice = false,
                IsActive = true
            );
            insert standartPbe;

            PriceBookEntry pbe = new PriceBookEntry(
                Pricebook2Id = pb.Id,
                Product2Id = testProduct.Id,
                CurrencyIsoCode = 'USD',
                UnitPrice = 100,
                UseStandardPrice = false,
                IsActive = true
            );
            insert pbe;
            
            PageReference pageRef = Page.convertLeadVFPage;
            Test.setCurrentPage(pageRef);

            ApexPages.currentPage().getParameters().put('id', testLead.Id);
            ApexPages.currentPage().getParameters().put('newmodel', '1');

            // check Acc count
            Map<Id, Account> accListBeforeConvert = new Map<Id, Account>([SELECT Id FROM Account]);
            Set<Id> allAccIdBeforeConvert = accListBeforeConvert.keySet();

            // check Contact count
            Map<Id, Contact> contListBeforeConvert = new Map<Id, Contact>([SELECT Id FROM Contact]);
            Set<Id> allContIdBeforeConvert = contListBeforeConvert.keySet();

            // check Opp count in order to then compare the count after Lead conversion
            Map<Id, Opportunity> allOppListBeforeConvert = new Map<Id, Opportunity>([SELECT Id FROM Opportunity]);
            Set<Id> allOppIdBeforeConvert = allOppListBeforeConvert.keySet();


            Test.startTest();

                ConvertLeadOptimize cntrlr = new ConvertLeadOptimize();

                PageReference pr = cntrlr.convertAndMerge();

                Id newOppId = (Id) pr.getParameters().get('Id');
            	
                PageReference createQuote = cntrlr.createQuote();
                PageReference additionalQLI = cntrlr.createAdditionalQuoteLineItems();
                PageReference leadBeforeConversion = cntrlr.saveLeadBeforeConversion();
                PageReference validateLead = cntrlr.validateLeadBeforeConversion();
                ConvertLeadOptimize.partnerDetailWrapper partnerContact = cntrlr.fetchPartnerContact();
                ConvertLeadOptimize.partnerDetailWrapper partnerOwner = cntrlr.fetchPartnerOwner();

            Test.stopTest();


            // check new Account is created
            Map<Id, Account> accListAfterConvert = new Map<Id, Account>([SELECT Id FROM Account]);
            Set<Id> allAccIdAfterConvert = accListAfterConvert.keySet();

            System.assert(
                allAccIdBeforeConvert.size() == allAccIdAfterConvert.size(),
                'it is looks like a new(additional) account is created'
            );

            // find created account Id
            Set<Id> newAccIdSet = diffBetweenIdSets(allAccIdBeforeConvert, allAccIdAfterConvert);
            System.assert(newAccIdSet.size() == 0, 'additional account is created');


            Map<Id, Contact> contListAfterConvert = new Map<Id, Contact>([SELECT Id FROM Contact]);
            Set<Id> allContIdAfterConvert = contListAfterConvert.keySet();

            System.assert(
                allContIdBeforeConvert.size() == allContIdAfterConvert.size(),
                'it is looks like a new contact(additional) is created'
            );

            // find created contact Id
            Set<Id> newContIdSet = diffBetweenIdSets(allContIdBeforeConvert, allContIdAfterConvert);
            System.assert(newContIdSet.size() == 0, 'additional contact is created');

            Map<Id, Opportunity> allOppListAfterConvert = new Map<Id, Opportunity>([SELECT Id FROM Opportunity]);
            Set<Id> allOppIdAfterConvert = allOppListAfterConvert.keySet();

            System.assert(
                allOppIdBeforeConvert.size() < allOppIdAfterConvert.size(),
                'it is looks like a new opportunity is not created'
            );

            // check oppId returned after convert is new(it does not contains in oppId set created before lead conversion)
            System.assert(!allOppIdBeforeConvert.contains(newOppId));
        }
    }

    @isTest 
    static void testPicklistOptions() {

        schedulerConfiguration__c sc = new schedulerConfiguration__c(
            Name = 'RingCentral'
        );
        insert sc;

        PriceBook2 testPriceBook = new Pricebook2(
            Name = 'Test Price Book',
            Brand__c = sc.Id,
            IsActive = true,
            Service__c = 'Office',
            Edition__c = 'Standard'
        );
        insert testPriceBook;

        Lead testLead = new Lead(
            Email = 'fake@email.com',
            LastName = 'testLead',
            Company = 'testCompany',
            RecordTypeId =
                Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Sales Leads').getRecordTypeId(),
            Industry = 'Computer, Technology, Internet',
            Employees_Override__c = 'Just me',
            LS_Company_Size__c = 11,
            LS_Company_Size_Range__c = '10-49',
            Number_of_Locations__c = '1',
            Bt_Cug_number__c='Test'
        );
        insert testLead;

        PageReference pageRef = Page.convertLeadVFPage;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('id', testLead.Id);

        ConvertLeadOptimize controller = new ConvertLeadOptimize();
        //Set available picklist values
        controller.brandValues = '[{"label":"RingCentral","value":"RingCentral"}]';
        //Choose picklist value
        controller.brand = 'RingCentral';

        controller.productValues = '[{"label":"Office","value":"Office"}]';
        controller.product = 'Office';

        controller.editionValues = '[{"label":"Standard","value":"Standard"}]';
        controller.termValues = '[{"label":"Monthly","value":"Monthly"}]';
        controller.setParams();

        Test.startTest();
            //Get options for every picklist
            List<SelectOption> brandOptions = controller.getBrandNames();
            List<SelectOption> productOptions = controller.getProductNames();
            List<SelectOption> editionOptions = controller.getEditionNames();
            List<SelectOption> termOptions = controller.getTermNames();

        Test.stopTest();
        System.assertEquals(new SelectOption('RingCentral','RingCentral'), brandOptions.get(0));
        // ...get(0) is always "--None--"" option. That is why we check  ...get(1) option
        System.assertEquals(new SelectOption('Office','Office'), productOptions.get(1));
        System.assertEquals(new SelectOption('Standard','Standard'), editionOptions.get(1));
        System.assertEquals(new SelectOption('Monthly','Monthly'), termOptions.get(1));
    }

    @IsTest 
    static void setCampaignInflunceShouldntNullOutOppBMID() {
        User marketingUser = (User) new SObjectBuilder(User.SObjectType)
                                 .setFields(SObjectFactoryFieldDefaults.getDefaults(User.SObjectType))
                                 .setField(User.UserPermissionsMarketingUser, true)
                                 .create()
                                 .getRecord();

        Campaign campaignWithNoBmid = new Campaign();
        System.runAs(marketingUser) {
            campaignWithNoBmid = (Campaign) new SObjectBuilder(Campaign.getSObjectType(), true)
                                            .setfield(Campaign.Name, 'NoBMIDCampaign')
                                            .setField(Campaign.Intended_Product__c, 'AU Contact Center')
                                            .setField(Campaign.Non_Attributable__c, false)
                                            .create()
                                            .getRecord();
        }
        Account acc = (Account) new SObjectBuilder(Account.getSObjectType(), true)
                                       .setFields(SObjectFactoryFieldDefaults.getDefaults(Account.SObjectType))
                                       .create()
                                       .getRecord();

        Lead convertedLead = (Lead) new SObjectBuilder(Lead.getSObjectType(), true)
                                 .setField(Lead.FirstName, 'John')
                                 .setField(Lead.LastName, 'Smith')
                                 .setField(Lead.Industry, 'Healthcare')
                                 .setField(Lead.Email, 'conver@tedlead.com')
                                 .setField(Lead.Company, 'convertz')
                                 .setField(Lead.Phone, '1234567890')
                                 .setField(Lead.Most_Recent_Campaign__c, campaignWithNoBmid.Id)
                                 .setField(Lead.BMID__c, 'ExistingBMID')
                                 .create()
                                 .getRecord();

        CampaignMember cmpMember = (CampaignMember) new SObjectBuilder(CampaignMember.getSObjectType(), true)
                                       .setField(CampaignMember.CampaignId, campaignWithNoBmid.Id)
                                       .setField(CampaignMember.LeadId, convertedLead.Id)
                                       .create()
                                       .getRecord();
        OpportunitySelector oppSelect = new OpportunitySelector();

        Test.startTest();
        Database.LeadConvert lc = new database.LeadConvert();
        LeadStatusSelector leadStatusSelector = new LeadStatusSelector();
        LeadStatus convertStatus = (LeadStatus) leadStatusSelector.selectLeadStatusForConvert()
                                                                  .executeQuery()[0];
        lc.setConvertedStatus(convertStatus.MasterLabel);
        lc.setLeadId(convertedLead.Id);
        lc.setAccountId(acc.Id);
        Database.LeadConvertResult lcr = Database.convertLead(lc);
        ConvertLeadOptimize conLeadOpt = new ConvertLeadOptimize();
        Opportunity oppConverted = (Opportunity) oppSelect.selectOpportunities()
                                           .selectField('BMID__c')
                                           .selectField('CampaignId')
                                           .executeQuery()[0];
        conLeadOpt.setCampaignInfluence(convertedLead, oppConverted);
        Test.stopTest();

        System.assert(oppConverted.CampaignId == campaignWithNoBmid.Id
                      && campaignWithNoBmid.BMID__C == null,
                      'The Campaign should be correctly assigned, and the campaigns BMID should be null');
        System.assertEquals('ExistingBMID', oppConverted.BMID__c, 'Opportunity should have BMID');

    }

}