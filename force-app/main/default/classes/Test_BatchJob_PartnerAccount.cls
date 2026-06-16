@IsTest
private class Test_BatchJob_PartnerAccount {   

    @TestSetup static void createData() {
        Account partnerAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => 'partnerAcc',
                    Account.Type => 'Partner',
                    Account.Partner_ID__c => '123456',
                    Account.Master_Agent_Channel_Manager__c => 'Test Value'
                }
            )
            .build()
            .getRecord();

        Account emptyPartnerAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => 'emptyPartnerAcc',
                    Account.Type => 'Partner',
                    Account.Partner_ID__c => '567890'
                }
            )
            .build()
            .getRecord();

        insert new List<Account> {partnerAcc, emptyPartnerAcc};

        Account duplicate = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => 'duplicate',
                    Account.Type => 'Partner',
                    Account.Partner_ID__c => '654321',
                    Account.Master_Agent_Channel_Manager__c => 'Test Value'
                }
            )
            .create()
            .getRecord();

        duplicate.FoundDuplicateAccountIds__c = duplicate.Id + ',' + partnerAcc.Id;
        partnerAcc.FoundDuplicateAccountIds__c = partnerAcc.Id + ',' + duplicate.Id;

        update new List<Account> {partnerAcc, duplicate};

        Lead testLead = (Lead) new SObjectBuilder(Lead.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Lead.email => 'fake@email.com',
                    Lead.LastName => 'fakeLastName',
                    Lead.Company => 'fakeCompany',
                    Lead.RecordTypeId => LeadHelper.RT_ID_PARTNER_LEADS,
                    Lead.Status => '1. New',
                    Lead.Partner_Account__c => partnerAcc.Id,
                    Lead.LeadPartnerID__c => '123456'
                }
            )
            .create()
            .getRecord();

        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.FirstName => 'Test1',
                    Contact.LastName => 'Test1',
                    Contact.AccountId => partnerAcc.Id,
                    Contact.Email => 'test@test.com',
                    Contact.Phone => '1234567890',
                    Contact.Preferred_Language__c => 'en_US'
                }
            )
            .create()
            .getRecord();

        Account serviceAcc1 = new Account();
        Account serviceAcc2 = new Account();
        Account serviceAccWithNullValues = new Account();

        serviceAcc1.Name = 'customerAcc';
        serviceAcc1.No_of_InContact_Seats__c = 5;
        serviceAcc1.RC_Account_Status__c = 'Paid';
        serviceAcc1.MRR__c = 100;
        serviceAcc1.Partner_ID__c = '123456';

        serviceAcc2.Name = 'testAcc';
        serviceAcc2.No_of_InContact_Seats__c = 15;
        serviceAcc2.RC_Account_Status__c = 'Paid';
        serviceAcc2.MRR__c = 300;
        serviceAcc2.Partner_ID__c = '123456';

        serviceAccWithNullValues.Name = 'testAcc';
        serviceAccWithNullValues.RC_Account_Status__c = 'Paid';
        serviceAccWithNullValues.Partner_ID__c = '123456';

        insert new List<Account>{serviceAcc1, serviceAcc2, serviceAccWithNullValues};

        Triggers.switchOff();

        List<Package__c> billingAccountPackages = (List<Package__c>) new SObjectBuilder(Package__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Package__c.Account__c => ValueProviderBuilder.provideList(new List<String>{serviceAcc1.Id, serviceAcc2.Id}),
                Package__c.Account_Package_Id__c => ValueProviderBuilder.provideList(new List<String>{'18','19'}),
                Package__c.Service_Type__c => QuoteHelper.NGBS_OFFICE_PRODUCT,
                Package__c.Total_DLs__c => ValueProviderBuilder.provideList(new List<Integer>{10, 15})
            })
            .quantity(2)
            .create()
            .getRecords();
        Triggers.switchOn();

        Opportunity openOpp1 = new Opportunity();
        Opportunity openOpp2 = new Opportunity();
        Opportunity openOppWithNullValues = new Opportunity();
        Opportunity closeOpp = new Opportunity();
        Opportunity downGradedOpp = new Opportunity();
            
        openOpp1.Name = 'Test Opportunity 2016';
        openOpp1.Type = 'Syndicated - New';
        openOpp1.StageName = 'Planning';
        openOpp1.CloseDate = system.today().addMonths(1);
        openOpp1.AccountId = serviceAcc1.Id;
        openOpp1.Primary_Opportunity_Contact__c = con.Id;
        openOpp1.Amount = 10000;
        openOpp1.Forecasted_Users__c = 25;
        openOpp1.Partner_ID__c = '123456';
        openOpp1.Forecast_Contact_Center_Users__c = 30;

        openOpp2.Name = 'Test Opportunity 2016';
        openOpp2.Type = 'Syndicated - New';
        openOpp2.StageName = 'Planning';
        openOpp2.CloseDate = system.today().addMonths(1);
        openOpp2.AccountId = serviceAcc2.Id;
        openOpp2.Primary_Opportunity_Contact__c = con.Id;
        openOpp2.Amount = 20000;
        openOpp2.Forecasted_Users__c = 50;
        openOpp2.Partner_ID__c = '123456';

        openOppWithNullValues.Name = 'Test Opportunity 2016';
        openOppWithNullValues.Type = 'Syndicated - New';
        openOppWithNullValues.StageName = 'Planning';
        openOppWithNullValues.CloseDate = system.today().addMonths(1);
        openOppWithNullValues.AccountId = serviceAccWithNullValues.Id;
        openOppWithNullValues.Primary_Opportunity_Contact__c = con.Id;

        closeOpp.Name = 'Test Opportunity 2016';
        closeOpp.Type = 'Syndicated - New';
        closeOpp.CloseDate = system.today().addMonths(1);
        closeOpp.AccountId = serviceAcc2.Id;
        closeOpp.Primary_Opportunity_Contact__c = con.Id;
        closeOpp.Amount = 90000;
        closeOpp.Forecasted_Users__c = 24;
        closeOpp.StageName = OpportunityHelper.closedStage;
        closeOpp.Partner_ID__c = '123456';

        downGradedOpp.Name = 'Test Opportunity 2016';
        downGradedOpp.Type = 'Syndicated - New';
        downGradedOpp.CloseDate = system.today().addMonths(1);
        downGradedOpp.AccountId = serviceAcc1.Id;
        downGradedOpp.Primary_Opportunity_Contact__c = con.Id;
        downGradedOpp.Amount = 90000;
        downGradedOpp.Forecasted_Users__c = 24;
        downGradedOpp.StageName = OpportunityHelper.STAGE_NAME_DOWNGRADED;
        downGradedOpp.Partner_ID__c = '123456';
        downGradedOpp.Downgrade_Reason_Opp__c = 'Downgrade reason test';

        insert new List<Opportunity>{openOpp1, openOpp2, openOppWithNullValues, closeOpp, downGradedOpp};
    }

    @IsTest static void testPartnerAccountWithRelatedData() {

        Test.startTest();
        Database.executeBatch(new BatchJob_PartnerAccount());
        Test.stopTest();

        Account accWithData;
        Account accWithoutData;
        Account customer;
        Account duplicate;
        Opportunity relatedOpp;
        Lead partnerLead;

        List<Account> accs = [SELECT Id, Name, Open_partner_leads__c, Open_partner_opps__c, Closed_Won_opps__c, 
                                Amount_of_open_opps__c, Forecasted_Users_of_open_opps__c, MRR_of_current_customers__c, 
                                DLs_of_current_customers__c, InContact_Seats_of_current_customers__c,
                                Master_Agent_Channel_Manager__c, Forecast_Contact_Center_Users__c, 
                                (SELECT Id, Name, Service_Type__c, Account__c, Total_DLs__c FROM Service_Accounts__r)
                                FROM Account 
                                WHERE Name = 'partnerAcc' 
                                    OR Name = 'emptyPartnerAcc'
                                    OR Name = 'customerAcc'
                                    OR Name = 'duplicate'];

        relatedOpp = [SELECT Id, Master_Agent_Channel_Manager__c 
                        FROM Opportunity
                        WHERE Partner_ID__c = '123456'
                        LIMIT 1];

        partnerLead = [SELECT Id,Master_Agent_Channel_Manager__c 
                        FROM Lead
                        WHERE LeadPartnerID__c = '123456'
                        LIMIT 1];

        

        for(Account acc : accs) {
            if(acc.Name == 'partnerAcc') {
                accWithData = acc;
            }
            if(acc.Name == 'emptyPartnerAcc') {
                accWithoutData = acc;
            }
            if(acc.Name == 'customerAcc') {
                customer = acc;
            }
            if(acc.Name == 'duplicate') {
                duplicate = acc;
            }
        }

        System.assertEquals(1, accWithData.Open_partner_leads__c, 'Account should have 1 open partner Lead');
        System.assertEquals(1, accWithData.Closed_Won_opps__c, 'Account should have 1 closed/won Opportunity');
        System.assertEquals(3, accWithData.Open_partner_opps__c, 'Account should have 3 open Opportunities');
        System.assertEquals(30000, accWithData.Amount_of_open_opps__c, 
            'Total Amount on all open Opportunities should be equal to 30000');
        System.assertEquals(75, accWithData.Forecasted_Users_of_open_opps__c, 
            'Total number of Forecasted Users on open Opportunities should be equal to 75');
        System.assertEquals(400, accWithData.MRR_of_current_customers__c, 
            'Total MRR of all customer Accounts should be equal to 400');
        System.assertEquals(25, accWithData.DLs_of_current_customers__c, 
            'Total number of Digital Lines on all customer Accounts should be equal to 25');
        System.assertEquals(20, accWithData.InContact_Seats_of_current_customers__c, 
            'Total number of InContact Seats on all customer Accounts should be equal to 20');
        System.assertEquals(30, accWithData.Forecast_Contact_Center_Users__c, 
            'Total number of Forecasted CC Users on open Opportunities should be equal to 30');
        

        System.assertEquals(accWithData.Open_partner_leads__c, duplicate.Open_partner_leads__c, 
            'Account should have 1 open partner Lead');
        System.assertEquals(accWithData.Closed_Won_opps__c, duplicate.Closed_Won_opps__c, 
            'Account should have 1 closed/won Opportunity');
        System.assertEquals(accWithData.Open_partner_opps__c, duplicate.Open_partner_opps__c, 
            'Account should have 3 open Opportunities');
        System.assertEquals(accWithData.Amount_of_open_opps__c, duplicate.Amount_of_open_opps__c, 
            'Total Amount on all open Opportunities should be equal to 30000');
        System.assertEquals(accWithData.Forecasted_Users_of_open_opps__c, duplicate.Forecasted_Users_of_open_opps__c, 
            'Total number of Forecasted Users on open Opportunities should be equal to 75');
        System.assertEquals(accWithData.MRR_of_current_customers__c, duplicate.MRR_of_current_customers__c, 
            'Total MRR of all customer Accounts should be equal to 400');
        System.assertEquals(accWithData.DLs_of_current_customers__c, duplicate.DLs_of_current_customers__c, 
            'Total number of Digital Lines on all customer Accounts should be equal to 25');
        System.assertEquals(accWithData.InContact_Seats_of_current_customers__c, 
            duplicate.InContact_Seats_of_current_customers__c, 
            'Total number of InContact Seats on all customer Accounts should be equal to 20');
        System.assertEquals(accWithData.Forecast_Contact_Center_Users__c, 
            duplicate.Forecast_Contact_Center_Users__c, 
            'Total number of Forecasted CC Users on all customer Accounts should be equal to 20');

        System.assertEquals(accWithData.Master_Agent_Channel_Manager__c, customer.Master_Agent_Channel_Manager__c, 
            'Master Agent Channel Manager field should be equal for Partner Account and related Customer Account');
        System.assertEquals(accWithData.Master_Agent_Channel_Manager__c, relatedOpp.Master_Agent_Channel_Manager__c, 
            'Master Agent Channel Manager field should be equal for Partner Account and related Opportunity');
        System.assertEquals(accWithData.Master_Agent_Channel_Manager__c, partnerLead.Master_Agent_Channel_Manager__c, 
            'Master Agent Channel Manager field should be equal for Partner Account and related Partner Lead');

        System.assertEquals(0, accWithoutData.Open_partner_leads__c, 'Account should have 0 open partner Leads');
        System.assertEquals(0, accWithoutData.Closed_Won_opps__c, 'Account should have 0 closed/won Opportunities');
        System.assertEquals(0, accWithoutData.Open_partner_opps__c, 'Account should have 0 open Opportunities');
        System.assertEquals(0, accWithoutData.Amount_of_open_opps__c, 
            'Account does not have related Opportunities, so total Amount should be 0');
        System.assertEquals(0, accWithoutData.Forecasted_Users_of_open_opps__c, 
            'Account does not have related Opportunities, so total number of Forecasted Users should be 0');
        System.assertEquals(0, accWithoutData.MRR_of_current_customers__c, 
            'Account does not have related Accounts, so total MRR should be 0');
        System.assertEquals(0, accWithoutData.DLs_of_current_customers__c, 
            'Account does not have related Accounts, so total number of Digital Lines should be 0');
        System.assertEquals(0, accWithoutData.InContact_Seats_of_current_customers__c, 
            'Account does not have related Accounts, so total number of InContact Seats should be 0');
        System.assertEquals(0, accWithoutData.Forecast_Contact_Center_Users__c, 
            'Account does not have related Accounts, so total number of Forecasted CC Users should be 0');
        
    }
}