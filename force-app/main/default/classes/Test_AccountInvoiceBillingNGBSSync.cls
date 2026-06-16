@isTest
private class Test_AccountInvoiceBillingNGBSSync
{
    private static final String PaymentMethod_Empty_Resp = '[]';
    private static final String PaymentMethod_Invoice_Resp = '[{"id":778453001,"accountId":866255001,"addedAt":"2018-11-12T13:55:13.600Z[UTC]","invoiceInfo":{"terms":0,"address":{"label":null,"firstName":"New NGBS test","lastName":"New NGBS test","phone":null,"street1":"street","street2":null,"city":"city","county":null,"state":"NY","zip":"123456","country":"USA"}},"default":true}]';
    private static final String PaymentMethod_Invoice_Resp2 = '[{"id":778453002,"accountId":866255002,"addedAt":"2018-11-12T13:55:13.600Z[UTC]","invoiceInfo":{"terms":0,"address":{"label":null,"firstName":"New NGBS test","lastName":"New NGBS test","phone":null,"street1":"street","street2":null,"city":"city","county":null,"state":"NY","zip":"123456","country":"USA"}},"default":true}]';
    private static final String PackageConsolidation_Post_Resp = '{"billingAlignmentEnabled":true,"invoiceConsolidationEnabled":true}';
    private static final String PackageConsolidation_Get_Resp = '{"billingAlignmentEnabled":false,"invoiceConsolidationEnabled":false}';

    private static final String accountIdWithEmptyPaymentResponse = '11111111';
    private static final String accountIdWithExistingPaymentResponse = '778453001';
    private static final String accountIdWithExistingPaymentResponse2 = '778453002';
    private static final String accountIdWithBadResponse = '00000000000';

    @testSetup
    static void generateData() {
        upsert new NGBS_Settings__c(
            BaseEndpoint__c = 'https://testapi/',
            AccountManagerPath__c = '/restapi/account-manager/v1.0',
            Login__c = '123',
            Password__c = '456'
        );
        Feature_Toggle__c toggle = Feature_Toggle__c.getOrgDefaults();
        toggle.AccountInvoiceBillingNGBSSync__c = true;
        insert toggle;
        Account acc1 = new Account(Name='Test account');
        Account acc2 = new Account(
            Name = 'Test account2',
            Billing_ID__c = accountIdWithExistingPaymentResponse,
            BillingStreet = 'street',
            BillingState = 'state',
            BillingPostalCode = '123',
            BillingCountry = 'USA',
            BillingCity = 'City',
            Phone = '123467445'
        );
        Account acc4 = new Account(Name='Test account4', Billing_ID__c=accountIdWithBadResponse);
        insert new List<Account>{acc1,acc2,acc4};
    }

    public class Mock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            res.setStatus('OK');
            res.setStatusCode(200);

            String endpoint = req.getEndpoint();
            if (endpoint.endsWith(accountIdWithEmptyPaymentResponse + '/paymentMethod')) {
                res.setBody(PaymentMethod_Empty_Resp);
            } else if (endpoint.endsWith('/paymentMethod')) {  // for accountId = 778453001
                res.setBody(PaymentMethod_Invoice_Resp);
            } else if (endpoint.endsWith('/packageConsolidationSettings') && req.getMethod() == HttpHelper.METHOD_GET) {
                res.setBody(PackageConsolidation_Get_Resp);
            } else if (endpoint.endsWith('/packageConsolidationSettings') && req.getMethod() == HttpHelper.METHOD_POST) {
                res.setBody(PackageConsolidation_Post_Resp);
            }

            if (endpoint.endsWith(accountIdWithBadResponse + '/paymentMethod')) {
                res.setStatusCode(400);
                res.setStatus('BadRequest');
            }

            return res;
        }
    }

    @isTest
    static void test_AccountInvoiceBillingNGBSSync_Job_neg_MissedBillingId()
    {
        Triggers.switchOff();
        Account masterAcc = (Account) new AccountSelector()
            .selectAccountByName(new List<Object>{
                'Test account'
            })
            .executeQuery()
            .get(0);

        Account techAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Master_Account__c => masterAcc.Id,
                    Account.isMultiproductTechnicalAccount__c => true,
                    Account.Billing_ID__c => accountIdWithEmptyPaymentResponse,
                    Account.BillingStreet => 'street',
                    Account.BillingState => 'state',
                    Account.BillingPostalCode => '123',
                    Account.BillingCountry => 'USA',
                    Account.BillingCity => 'City',
                    Account.Phone => '123467445'
                }
            )
            .create()
            .getRecord();

        Opportunity masterOpp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.Name => 'Test opptyMPL',
                    Opportunity.AccountId => masterAcc.Id,
                    Opportunity.isMultiproductTechnicalOpportunity__c => false,
                    Opportunity.CloseDate => Date.today()
                }
            )
            .create()
            .getRecord();

        Opportunity techOpp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.MasterOpportunity__c => masterOpp.Id,
                    Opportunity.isMultiproductTechnicalOpportunity__c => true,
                    Opportunity.CloseDate => Date.today(),
                    Opportunity.AccountId => techAcc.Id
                }
            )
            .create()
            .getRecord();

        Quote masterQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.OpportunityId => masterOpp.Id,
                    Quote.IsMultiProductTechnicalQuote__c => false,
                    Quote.MasterQuote__c => null
                }
            )
            .create()
            .getRecord();
        
        Contact testContact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.FirstName => 'Test1',
                    Contact.LastName => 'Test1',
                    Contact.AccountId => masterAcc.Id,
                    Contact.Email => 'test@test.com',
                    Contact.Phone => '1234567890',
                    Contact.Preferred_Language__c => 'en_US'
                }
            )
            .create()
            .getRecord();

        List<AccountContactRole> testAccountContactRole = (List<AccountContactRole>) new SObjectBuilder(AccountContactRole.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    AccountContactRole.AccountId => ValueProviderBuilder.provideList(new List<String>{masterAcc.Id, techAcc.Id}),
                    AccountContactRole.ContactId => testContact.Id,
                    AccountContactRole.IsPrimary => true,
                    AccountContactRole.Role => AccountContactRoleHelper.CONTACT_ROLE_SIGNATORY
                }
            )
            .quantity(2)
            .create()
            .getRecords();

        List<Quote> techQuotes = (List<Quote>) new SObjectBuilder(Quote.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.OpportunityId => ValueProviderBuilder.provideList(new List<String>{masterOpp.Id, techOpp.Id}),
                    Quote.IsMultiProductTechnicalQuote__c => true,
                    Quote.MasterQuote__c => masterQuote.Id,
                    Quote.ServiceName__c => ValueProviderBuilder.provideList(new List<String>{'Office', 'RingCentral Contact Center'})
                }
            )
            .quantity(2)
            .create()
            .getRecords();

        Approval__c masterApproval = (Approval__c) new SObjectBuilder(Approval__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Approval__c.Account__c => masterAcc.Id,
                    Approval__c.IsMultiProductTechnicalApproval__c => false,
                    Approval__c.Opportunity__c => masterOpp.Id
                    }
            )
            .create()
            .getRecord();

        List<Approval__c> techApprovals = (List<Approval__c>) new SObjectBuilder(Approval__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Approval__c.Account__c => ValueProviderBuilder.provideList(new List<String>{masterAcc.Id, techAcc.Id}),
                    Approval__c.IsMultiProductTechnicalApproval__c => false,
                    Approval__c.Opportunity__c => ValueProviderBuilder.provideList(new List<String>{masterOpp.Id, techOpp.Id})
                }
            )
            .quantity(2)
            .create()
            .getRecords();

        List<Package__c> packagesList = (List<Package__c>) new SObjectBuilder(Package__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Package__c.Account_Package_Id__c => ValueProviderBuilder.provideList(new List<String>{accountIdWithExistingPaymentResponse, accountIdWithExistingPaymentResponse2}),
                    Package__c.Account__c => ValueProviderBuilder.provideList(new List<String>{masterAcc.Id, techAcc.Id}),
                    Package__c.Enterprise_Account_ID__c => ValueProviderBuilder.provideList(new List<String>{masterAcc.Id, techAcc.Id})
                }
            )
            .quantity(2)
            .create()
            .getRecords();

        Triggers.switchOn();

        List<Approval__c> allApprovals = new List<Approval__c>();
        allApprovals.add(masterApproval);
        allApprovals.addAll(techApprovals);

        Map<String, List<Object>> agrumentsMap = new Map<String, List<Object>>{
            'accounts' => new List<Account>{masterAcc, techAcc},
            'approvals' => allApprovals
        };
        List<Object> agrumentsList = new List<Object>{agrumentsMap};
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new Mock());
            QueueableBase.enqueJob('AccountInvoiceBillingNGBSSync', agrumentsList);
        Test.stopTest();
        System.assertEquals(1, ([SELECT Id FROM PlatformLog__c WHERE Source__c = 'AccountInvoiceBillingNGBSSync']).size(), 'should create log record as no billing id on account');

    }

    @isTest
    static void test_AccountInvoiceBillingNGBSSync_Job_neg_MissedBillingAddress()
    {
        Triggers.switchOff();
        Account masterAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => 'Test account5',
                    Account.Billing_ID__c => accountIdWithEmptyPaymentResponse
                }
            )
            .create()
            .getRecord();

        Account techAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Master_Account__c => masterAcc.Id,
                    Account.isMultiproductTechnicalAccount__c => true,
                    Account.Billing_ID__c => accountIdWithEmptyPaymentResponse
                }
            )
            .create()
            .getRecord();

        Opportunity masterOpp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.Name => 'Test opptyMPL',
                    Opportunity.AccountId => masterAcc.Id,
                    Opportunity.isMultiproductTechnicalOpportunity__c => false,
                    Opportunity.CloseDate => Date.today()
                }
            )
            .create()
            .getRecord();

        Opportunity techOpp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.MasterOpportunity__c => masterOpp.Id,
                    Opportunity.isMultiproductTechnicalOpportunity__c => true,
                    Opportunity.CloseDate => Date.today(),
                    Opportunity.AccountId => techAcc.Id
                }
            )
            .create()
            .getRecord();

        Quote masterQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.OpportunityId => masterOpp.Id,
                    Quote.IsMultiProductTechnicalQuote__c => false,
                    Quote.MasterQuote__c => null
                }
            )
            .create()
            .getRecord();

        List<Quote> techQuotes = (List<Quote>) new SObjectBuilder(Quote.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.OpportunityId => ValueProviderBuilder.provideList(new List<String>{masterOpp.Id, techOpp.Id}),
                    Quote.IsMultiProductTechnicalQuote__c => true,
                    Quote.MasterQuote__c => masterQuote.Id,
                    Quote.ServiceName__c => ValueProviderBuilder.provideList(new List<String>{'Office', 'RingCentral Contact Center'})
                }
            )
            .quantity(2)
            .create()
            .getRecords();

        Approval__c masterApproval = (Approval__c) new SObjectBuilder(Approval__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Approval__c.Account__c => masterAcc.Id,
                    Approval__c.IsMultiProductTechnicalApproval__c => false,
                    Approval__c.Opportunity__c => masterOpp.Id
                }
            )
            .create()
            .getRecord();

        List<Approval__c> techApprovals = (List<Approval__c>) new SObjectBuilder(Approval__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Approval__c.Account__c => ValueProviderBuilder.provideList(new List<String>{masterAcc.Id, techAcc.Id}),
                    Approval__c.IsMultiProductTechnicalApproval__c => false,
                    Approval__c.Opportunity__c => ValueProviderBuilder.provideList(new List<String>{masterOpp.Id, techOpp.Id})
                }
            )
            .quantity(2)
            .create()
            .getRecords();

        Contact testContact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.FirstName => 'Test1',
                    Contact.LastName => 'Test1',
                    Contact.AccountId => masterAcc.Id,
                    Contact.Email => 'test@test.com',
                    Contact.Phone => '1234567890',
                    Contact.Preferred_Language__c => 'en_US'
                }
            )
            .create()
            .getRecord();

        List<AccountContactRole> testAccountContactRole = (List<AccountContactRole>) new SObjectBuilder(AccountContactRole.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    AccountContactRole.AccountId => ValueProviderBuilder.provideList(new List<String>{masterAcc.Id, techAcc.Id}),
                    AccountContactRole.ContactId => testContact.Id,
                    AccountContactRole.IsPrimary => true,
                    AccountContactRole.Role => AccountContactRoleHelper.CONTACT_ROLE_SIGNATORY
                }
            )
            .quantity(2)
            .create()
            .getRecords();

        List<Package__c> packagesList = (List<Package__c>) new SObjectBuilder(Package__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Package__c.Account_Package_Id__c => ValueProviderBuilder.provideList(new List<String>{accountIdWithExistingPaymentResponse, accountIdWithExistingPaymentResponse2}),
                    Package__c.Account__c => ValueProviderBuilder.provideList(new List<String>{masterAcc.Id, techAcc.Id}),
                    Package__c.Enterprise_Account_ID__c => ValueProviderBuilder.provideList(new List<String>{masterAcc.Id, techAcc.Id})
                }
            )
            .quantity(2)
            .create()
            .getRecords();

        Triggers.switchOn();

        List<Approval__c> allApprovals = new List<Approval__c>();
        allApprovals.add(masterApproval);
        allApprovals.addAll(techApprovals);

        Map<String, List<Object>> agrumentsMap = new Map<String, List<Object>>{
            'accounts' => new List<Account>{masterAcc, techAcc},
            'approvals' => allApprovals
        };
        List<Object> agrumentsList = new List<Object>{agrumentsMap};
        Test.setMock(HttpCalloutMock.class, new Mock());

        Test.startTest();
            QueueableBase.enqueJob('AccountInvoiceBillingNGBSSync', agrumentsList);
        Test.stopTest();
        List<PlatformLog__c> logs = [SELECT Id, StackTrace__c FROM PlatformLog__c WHERE Source__c = 'AccountInvoiceBillingNGBSSync'];
        System.assertEquals(2, logs.size(), 'should create log record as no billing address on account');
        System.assert(logs[0].StackTrace__c.contains('Address information not valid for the Invoice Payment Update'), 'unexpected exception message');

    }

    @isTest
    static void test_AccountInvoiceBillingNGBSSync_Job_pos_MissedAccountPackage()
    {
        Triggers.switchOff();
        Account masterAcc = (Account) new AccountSelector()
            .selectAccountByName(new List<Object>{
                'Test account2'
            })
            .executeQuery()
            .get(0);

        Account techAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Master_Account__c => masterAcc.Id,
                    Account.isMultiproductTechnicalAccount__c => true,
                    Account.Billing_ID__c => accountIdWithExistingPaymentResponse,
                    Account.BillingStreet => 'street',
                    Account.BillingState => 'state',
                    Account.BillingPostalCode => '123',
                    Account.BillingCountry => 'USA',
                    Account.BillingCity => 'City',
                    Account.Phone => '123467445'
                }
            )
            .create()
            .getRecord();

        Opportunity masterOpp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.Name => 'Test opptyMPL',
                    Opportunity.AccountId => masterAcc.Id,
                    Opportunity.isMultiproductTechnicalOpportunity__c => false,
                    Opportunity.CloseDate => Date.today()
                }
            )
            .create()
            .getRecord();

        Opportunity techOpp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.MasterOpportunity__c => masterOpp.Id,
                    Opportunity.isMultiproductTechnicalOpportunity__c => true,
                    Opportunity.CloseDate => Date.today(),
                    Opportunity.AccountId => techAcc.Id
                }
            )
            .create()
            .getRecord();

        Quote masterQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.OpportunityId => masterOpp.Id,
                    Quote.IsMultiProductTechnicalQuote__c => false,
                    Quote.MasterQuote__c => null
                }
            )
            .create()
            .getRecord();

        List<Quote> techQuotes = (List<Quote>) new SObjectBuilder(Quote.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.OpportunityId => ValueProviderBuilder.provideList(new List<String>{masterOpp.Id, techOpp.Id}),
                    Quote.IsMultiProductTechnicalQuote__c => true,
                    Quote.MasterQuote__c => masterQuote.Id,
                    Quote.ServiceName__c => ValueProviderBuilder.provideList(new List<String>{'Office', 'RingCentral Contact Center'})
                }
            )
            .quantity(2)
            .create()
            .getRecords();

        Approval__c masterApproval = (Approval__c) new SObjectBuilder(Approval__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Approval__c.Account__c => masterAcc.Id,
                    Approval__c.IsMultiProductTechnicalApproval__c => false,
                    Approval__c.Opportunity__c => masterOpp.Id
                }
            )
            .create()
            .getRecord();

        List<Approval__c> techApprovals = (List<Approval__c>) new SObjectBuilder(Approval__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Approval__c.Account__c => ValueProviderBuilder.provideList(new List<String>{masterAcc.Id, techAcc.Id}),
                    Approval__c.IsMultiProductTechnicalApproval__c => false,
                    Approval__c.Opportunity__c => ValueProviderBuilder.provideList(new List<String>{masterOpp.Id, techOpp.Id})
                }
            )
            .quantity(2)
            .create()
            .getRecords();

        Contact testContact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.FirstName => 'Test1',
                    Contact.LastName => 'Test1',
                    Contact.AccountId => masterAcc.Id,
                    Contact.Email => 'test@test.com',
                    Contact.Phone => '1234567890',
                    Contact.Preferred_Language__c => 'en_US'
                }
            )
            .create()
            .getRecord();

        List<AccountContactRole> testAccountContactRole = (List<AccountContactRole>) new SObjectBuilder(AccountContactRole.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    AccountContactRole.AccountId => ValueProviderBuilder.provideList(new List<String>{masterAcc.Id, techAcc.Id}),
                    AccountContactRole.ContactId => testContact.Id,
                    AccountContactRole.IsPrimary => true,
                    AccountContactRole.Role => AccountContactRoleHelper.CONTACT_ROLE_SIGNATORY
                }
            )
            .quantity(2)
            .create()
            .getRecords();

        List<Package__c> packagesList = (List<Package__c>) new SObjectBuilder(Package__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Package__c.Account_Package_Id__c => ValueProviderBuilder.provideList(new List<String>{accountIdWithExistingPaymentResponse, accountIdWithExistingPaymentResponse2}),
                    Package__c.Account__c => ValueProviderBuilder.provideList(new List<String>{masterAcc.Id, techAcc.Id}),
                    Package__c.Enterprise_Account_ID__c => ValueProviderBuilder.provideList(new List<String>{masterAcc.Id, techAcc.Id})
                }
            )
            .quantity(2)
            .create()
            .getRecords();

        Triggers.switchOn();

        List<Approval__c> allApprovals = new List<Approval__c>();
        allApprovals.add(masterApproval);
        allApprovals.addAll(techApprovals);

        Map<String, List<Object>> agrumentsMap = new Map<String, List<Object>>{
            'accounts' => new List<Account>{masterAcc, techAcc},
            'approvals' => allApprovals
        };
        List<Object> agrumentsList = new List<Object>{agrumentsMap};
        Test.setMock(HttpCalloutMock.class, new Mock());

        Test.startTest();
            QueueableBase.enqueJob('AccountInvoiceBillingNGBSSync', agrumentsList);
        Test.stopTest();
        List<PlatformLog__c> logs = [SELECT Id, StackTrace__c FROM PlatformLog__c WHERE Source__c = 'AccountInvoiceBillingNGBSSync'];
        System.assertEquals(0, logs.size(), 'should not create any logs');

        Account reselectedAccount = (Account) new AccountSelector()
            .selectAccountByName(new List<Object>{
                'Test account2'
            })
            .selectField(Account.Account_Payment_Method__c)
            .executeQuery()
            .get(0);

        System.assertEquals(
            AccountHelper.PAYMENT_METHOD_INVOICE,
            reselectedAccount.Account_Payment_Method__c,
            'Account_Payment_Method__c field should have value "Invoice"'
        );
    }

    @isTest
    static void test_AccountInvoiceBillingNGBSSync_Job_pos()
    {
        Triggers.switchOff();

        Account masterAcc = (Account) new AccountSelector()
                .selectAccountByName(new List<Object>{'Test account2'})
                .executeQuery()
                .get(0);

        Account techAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Master_Account__c => masterAcc.Id,
                    Account.isMultiproductTechnicalAccount__c => true,
                    Account.Billing_ID__c => accountIdWithExistingPaymentResponse,
                    Account.BillingStreet => 'street',
                    Account.BillingState => 'state',
                    Account.BillingPostalCode => '123',
                    Account.BillingCountry => 'USA',
                    Account.BillingCity => 'City',
                    Account.Phone => '123467445'
                }
            )
            .create()
            .getRecord();

        Opportunity masterOpp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.Name => 'Test opptyMPL',
                    Opportunity.AccountId => masterAcc.Id,
                    Opportunity.isMultiproductTechnicalOpportunity__c => false,
                    Opportunity.CloseDate => Date.today()
                }
            )
            .create()
            .getRecord();

        Opportunity techOpp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.MasterOpportunity__c => masterOpp.Id,
                    Opportunity.isMultiproductTechnicalOpportunity__c => true,
                    Opportunity.CloseDate => Date.today(),
                    Opportunity.AccountId => techAcc.Id
                }
            )
            .create()
            .getRecord();

        Quote masterQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.OpportunityId => masterOpp.Id,
                    Quote.IsMultiProductTechnicalQuote__c => false,
                    Quote.MasterQuote__c => null
                }
            )
            .create()
            .getRecord();

        List<Quote> techQuotes = (List<Quote>) new SObjectBuilder(Quote.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.OpportunityId => ValueProviderBuilder.provideList(new List<String>{masterOpp.Id, techOpp.Id}),
                    Quote.IsMultiProductTechnicalQuote__c => true,
                    Quote.MasterQuote__c => masterQuote.Id,
                    Quote.ServiceName__c => ValueProviderBuilder.provideList(new List<String>{'Office', 'RingCentral Contact Center'})
                }
            )
            .quantity(2)
            .create()
            .getRecords();

        Approval__c masterApproval = (Approval__c) new SObjectBuilder(Approval__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Approval__c.Account__c => masterAcc.Id,
                    Approval__c.IsMultiProductTechnicalApproval__c => false,
                    Approval__c.Opportunity__c => masterOpp.Id
                }
            )
            .create()
            .getRecord();

        List<Approval__c> techApprovals = (List<Approval__c>) new SObjectBuilder(Approval__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Approval__c.Account__c => ValueProviderBuilder.provideList(new List<String>{masterAcc.Id, techAcc.Id}),
                    Approval__c.IsMultiProductTechnicalApproval__c => false,
                    Approval__c.Opportunity__c => ValueProviderBuilder.provideList(new List<String>{masterOpp.Id, techOpp.Id})
                }
            )
            .quantity(2)
            .create()
            .getRecords();

        Contact testContact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.FirstName => 'Test1',
                    Contact.LastName => 'Test1',
                    Contact.AccountId => masterAcc.Id,
                    Contact.Email => 'test@test.com',
                    Contact.Phone => '1234567890',
                    Contact.Preferred_Language__c => 'en_US'
                }
            )
            .create()
            .getRecord();

        List<AccountContactRole> testAccountContactRole = (List<AccountContactRole>) new SObjectBuilder(AccountContactRole.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    AccountContactRole.AccountId => ValueProviderBuilder.provideList(new List<String>{masterAcc.Id, techAcc.Id}),
                    AccountContactRole.ContactId => testContact.Id,
                    AccountContactRole.IsPrimary => true,
                    AccountContactRole.Role => AccountContactRoleHelper.CONTACT_ROLE_SIGNATORY
                }
            )
            .quantity(2)
            .create()
            .getRecords();

        List<Package__c> packagesList = (List<Package__c>) new SObjectBuilder(Package__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Package__c.Account_Package_Id__c => ValueProviderBuilder.provideList(new List<String>{accountIdWithExistingPaymentResponse, accountIdWithExistingPaymentResponse2}),
                    Package__c.Account__c => ValueProviderBuilder.provideList(new List<String>{masterAcc.Id, techAcc.Id}),
                    Package__c.Enterprise_Account_ID__c => ValueProviderBuilder.provideList(new List<String>{masterAcc.Id, techAcc.Id})
                }
            )
            .quantity(2)
            .create()
            .getRecords();

        Triggers.switchOn();

        List<Approval__c> allApprovals = new List<Approval__c>();
        allApprovals.add(masterApproval);
        allApprovals.addAll(techApprovals);

        Map<String, List<Object>> agrumentsMap = new Map<String, List<Object>>{
            'accounts' => new List<Account>{masterAcc, techAcc},
            'approvals' => allApprovals
        };
        List<Object> agrumentsList = new List<Object>{agrumentsMap};

        Test.setMock(HttpCalloutMock.class, new Mock());

        Test.startTest();
            QueueableBase.enqueJob('AccountInvoiceBillingNGBSSync', agrumentsList);
        Test.stopTest();
        List<PlatformLog__c> logs = [SELECT Id, StackTrace__c FROM PlatformLog__c WHERE Source__c = 'AccountInvoiceBillingNGBSSync'];
        System.assertEquals(0, logs.size(), 'should not create any logs');

        Account reselectedAccount = (Account) new AccountSelector()
            .selectAccountByName(new List<Object>{
                'Test account2'
            })
            .selectField(Account.Account_Payment_Method__c)
            .executeQuery()
            .get(0);

        System.assertEquals(
            AccountHelper.PAYMENT_METHOD_INVOICE,
            reselectedAccount.Account_Payment_Method__c,
            'Account_Payment_Method__c field should have value "Invoice"'
        );
    }

    @isTest
    static void test_AccountInvoiceBillingNGBSSync_Job_neg_CalloutFailed()
    {
        Triggers.switchOff();
        Account masterAcc = (Account) new AccountSelector()
                .selectAccountByName(new List<Object>{
                    'Test account4'
                })
                .executeQuery()
                .get(0);

        Account techAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Master_Account__c => masterAcc.Id,
                    Account.isMultiproductTechnicalAccount__c => true,
                    Account.Billing_ID__c => accountIdWithBadResponse
                }
            )
            .create()
            .getRecord();

        Opportunity masterOpp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.Name => 'Test opptyMPL',
                    Opportunity.AccountId => masterAcc.Id,
                    Opportunity.isMultiproductTechnicalOpportunity__c => false,
                    Opportunity.CloseDate => Date.today()
                }
            )
            .create()
            .getRecord();

        Opportunity techOpp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.MasterOpportunity__c => masterOpp.Id,
                    Opportunity.isMultiproductTechnicalOpportunity__c => true,
                    Opportunity.CloseDate => Date.today(),
                    Opportunity.AccountId => techAcc.Id
                }
            )
            .create()
            .getRecord();

        Quote masterQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.OpportunityId => masterOpp.Id,
                    Quote.IsMultiProductTechnicalQuote__c => false,
                    Quote.MasterQuote__c => null
                }
            )
            .create()
            .getRecord();

        List<Quote> techQuotes = (List<Quote>) new SObjectBuilder(Quote.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.OpportunityId => ValueProviderBuilder.provideList(new List<String>{masterOpp.Id, techOpp.Id}),
                    Quote.IsMultiProductTechnicalQuote__c => true,
                    Quote.MasterQuote__c => masterQuote.Id,
                    Quote.ServiceName__c => ValueProviderBuilder.provideList(new List<String>{'Office', 'RingCentral Contact Center'})
                }
            )
            .quantity(2)
            .create()
            .getRecords();

        Approval__c masterApproval = (Approval__c) new SObjectBuilder(Approval__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Approval__c.Account__c => masterAcc.Id,
                    Approval__c.IsMultiProductTechnicalApproval__c => false,
                    Approval__c.Opportunity__c => masterOpp.Id
                }
            )
            .create()
            .getRecord();

        List<Approval__c> techApprovals = (List<Approval__c>) new SObjectBuilder(Approval__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Approval__c.Account__c => ValueProviderBuilder.provideList(new List<String>{masterAcc.Id, techAcc.Id}),
                    Approval__c.IsMultiProductTechnicalApproval__c => false,
                    Approval__c.Opportunity__c => ValueProviderBuilder.provideList(new List<String>{masterOpp.Id, techOpp.Id})
                }
            )
            .quantity(2)
            .create()
            .getRecords();

        Contact testContact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.FirstName => 'Test1',
                    Contact.LastName => 'Test1',
                    Contact.AccountId => masterAcc.Id,
                    Contact.Email => 'test@test.com',
                    Contact.Phone => '1234567890',
                    Contact.Preferred_Language__c => 'en_US'
                }
            )
            .create()
            .getRecord();

        List<AccountContactRole> testAccountContactRole = (List<AccountContactRole>) new SObjectBuilder(AccountContactRole.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    AccountContactRole.AccountId => ValueProviderBuilder.provideList(new List<String>{masterAcc.Id, techAcc.Id}),
                    AccountContactRole.ContactId => testContact.Id,
                    AccountContactRole.IsPrimary => true,
                    AccountContactRole.Role => AccountContactRoleHelper.CONTACT_ROLE_SIGNATORY
                }
            )
            .quantity(2)
            .create()
            .getRecords();

        List<Package__c> packagesList = (List<Package__c>) new SObjectBuilder(Package__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Package__c.Account_Package_Id__c => ValueProviderBuilder.provideList(new List<String>{accountIdWithExistingPaymentResponse, accountIdWithExistingPaymentResponse2}),
                    Package__c.Account__c => ValueProviderBuilder.provideList(new List<String>{masterAcc.Id, techAcc.Id}),
                    Package__c.Enterprise_Account_ID__c => ValueProviderBuilder.provideList(new List<String>{masterAcc.Id, techAcc.Id})
                }
            )
            .quantity(2)
            .create()
            .getRecords();

        Triggers.switchOn();

        List<Approval__c> allApprovals = new List<Approval__c>();
        allApprovals.add(masterApproval);
        allApprovals.addAll(techApprovals);

        Map<String, List<Object>> agrumentsMap = new Map<String, List<Object>>{
            'accounts' => new List<Account>{masterAcc, techAcc},
            'approvals' => allApprovals
        };
        List<Object> agrumentsList = new List<Object>{agrumentsMap};
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new Mock());
            QueueableBase.enqueJob('AccountInvoiceBillingNGBSSync', agrumentsList);
        Test.stopTest();
        List<PlatformLog__c> logs = [SELECT Id, StackTrace__c FROM PlatformLog__c WHERE Source__c = 'AccountInvoiceBillingNGBSSync'];
        System.assertEquals(2, logs.size(), 'should create log for unexpected response from ngbs');
    }

    @isTest
    static void test_AccountInvoiceBillingNGBSSync_Job_MPUB()
    {
        Feature_Toggle__c toggle = Feature_Toggle__c.getOrgDefaults();
        toggle.EnableMultiProductUnifiedBilling__c = true;
        update toggle;

        Triggers.switchOff();

        Account acc = (Account) new AccountSelector()
            .selectAccountByName(new List<Object>{
                'Test account2'
            })
            .executeQuery()
            .get(0);

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.Name => 'Test opptyMPL',
                    Opportunity.AccountId => acc.Id,
                    Opportunity.isMultiproductTechnicalOpportunity__c => false,
                    Opportunity.CloseDate => Date.today()
                }
            )
            .create()
            .getRecord();

        Quote masterQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.OpportunityId => opp.Id,
                    Quote.IsMultiProductTechnicalQuote__c => false,
                    Quote.MasterQuote__c => null
                }
            )
            .create()
            .getRecord();

        List<Quote> techQuotes = (List<Quote>) new SObjectBuilder(Quote.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.OpportunityId => opp.Id,
                    Quote.IsMultiProductTechnicalQuote__c => true,
                    Quote.MasterQuote__c => masterQuote.Id,
                    Quote.ServiceName__c => ValueProviderBuilder.provideList(new List<String>{'Office', 'RingCentral Contact Center'})
                }
            )
            .quantity(2)
            .create()
            .getRecords();

        Package__c pckg = (Package__c) new SObjectBuilder(Package__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Package__c.Account__c => acc.Id,
                    Package__c.Account_Package_Id__c => '1231231231',
                    Package__c.Opportunity__c => opp.Id
                }
            )
            .create()
            .getRecord();

        List<ServiceInfo__c> serviceInfos = (List<ServiceInfo__c>) new SObjectBuilder(ServiceInfo__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    ServiceInfo__c.Quote__c => ValueProviderBuilder.provideList(new List<String>{techQuotes[0].Id, techQuotes[1].Id}),
                    ServiceInfo__c.BillingPackage__c => pckg.Id
                }
            )
            .quantity(2)
            .create()
            .getRecords();

        Approval__c approval = (Approval__c) new SObjectBuilder(Approval__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Approval__c.Account__c => acc.Id,
                    Approval__c.IsMultiProductTechnicalApproval__c => false,
                    Approval__c.Opportunity__c => opp.Id
                }
            )
            .create()
            .getRecord();

        Contact testContact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.FirstName => 'Test1',
                    Contact.LastName => 'Test1',
                    Contact.AccountId => acc.Id,
                    Contact.Email => 'test@test.com',
                    Contact.Phone => '1234567890',
                    Contact.Preferred_Language__c => 'en_US'
                }
            )
            .create()
            .getRecord();

        AccountContactRole testAccountContactRole = (AccountContactRole) new SObjectBuilder(AccountContactRole.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    AccountContactRole.AccountId => acc.Id,
                    AccountContactRole.ContactId => testContact.Id,
                    AccountContactRole.IsPrimary => true,
                    AccountContactRole.Role => AccountContactRoleHelper.CONTACT_ROLE_SIGNATORY
                }
            )
            .create()
            .getRecord();

        Triggers.switchOn();

        Map<String, List<Object>> agrumentsMap = new Map<String, List<Object>>{
            'accounts' => new List<Account>{acc},
            'approvals' => new List<Approval__c>{approval}
        };
        List<Object> agrumentsList = new List<Object>{agrumentsMap};

        Test.setMock(HttpCalloutMock.class, new Mock());

        Test.startTest();
            QueueableBase.enqueJob('AccountInvoiceBillingNGBSSync', agrumentsList);
        Test.stopTest();
        List<PlatformLog__c> logs = [SELECT Id, StackTrace__c FROM PlatformLog__c WHERE Source__c = 'AccountInvoiceBillingNGBSSync'];
        System.assertEquals(0, logs.size(), 'should not create any logs');
    }

    @isTest
    static void testIsQuotePackageInfoHasMultipleProducts() {
        List<Quote> quotes = (List<Quote>) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.IsPrimary__c => ValueProviderBuilder.provideList(new List<Boolean> { true, false }),
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.Package_Info__c => NGBSTestDataGenerator.generateQuotePackageInfo()
            })
            .quantity(2)
            .build()
            .getRecords();

        AccountInvoiceBillingNGBSSync aib = new AccountInvoiceBillingNGBSSync();

        Test.startTest();
            Assert.isFalse(aib.isQuotePackageInfoHasMultipleProducts(new List<Quote>()), 'Should return false if primary quote not found');
            Assert.isFalse(aib.isQuotePackageInfoHasMultipleProducts(quotes), 'Should return false for single product');

            quotes[0].Package_Info__c = NGBSTestDataGenerator.generateMultiProductQuotePackageInfo();
            Assert.isTrue(aib.isQuotePackageInfoHasMultipleProducts(quotes), 'Should return true for multi product');
        Test.stopTest();
    }
}