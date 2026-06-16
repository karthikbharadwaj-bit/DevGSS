@isTest
public with sharing class Test_ApprovalService {

    @isTest
    static void test_getPOCApprovals() {

        POC_GOA__c pocGoaCustomSetting = (POC_GOA__c) new SObjectBuilder(POC_GOA__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                POC_GOA__c.Sales_Rep__c => '0-0',
                POC_GOA__c.Direct_Manager__c => '0-9999',
                POC_GOA__c.Segment_Leader__c => '0-0',
                POC_GOA__c.SVP_WWS_Directs__c => '0-0',
                POC_GOA__c.SVP_WWS__c => '0-0'
            })
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.AccountId => ValueProviderBuilder.provideGenericParent(Account.SObjectType),
                Opportunity.Name => ValueProviderBuilder.provideUniqueString('TestOpportunity'),
                Opportunity.Type => OpportunityHelper.OPPORTUNITY_TYPE_NEW_BUSINESS,
                Opportunity.Brand_Name__c => RingCentralHelper.BRAND_RINGCENTRAL,
                Opportunity.Tier_Name__c => 'Professional',
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                Opportunity.CloseDate => System.today(),
                Opportunity.CurrencyIsoCode => RingCentralHelper.USD
            })
            .create()
            .getRecord();

        List<Quote> quotes = (List<Quote>) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Quote.Name => ValueProviderBuilder.provideUniqueString('Test POC Quote'),
                Quote.OpportunityId => opp.Id,
                Quote.RecordTypeId => ValueProviderBuilder.provideParents(new Set<Id>{
                    QuoteHelper.RT_ID_BILLING,
                    QuoteHelper.RT_ID_POC
                }),
                Quote.Pricebook2Id => Pricebook2Helper.getStandardPricebookId()
            })
            .quantity(2)
            .create()
            .getRecords();

        Test.startTest();

        new SObjectBuilder(Approval__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
            Approval__c.Name => 'Test Approval',
            Approval__c.Opportunity__c => opp.Id,
            Approval__c.Quote__c => ValueProviderBuilder.provideParents(quotes),
            Approval__c.RecordTypeId => ValueProviderBuilder.provideParents(new Set<Id>{
                ApprovalHelper.RT_ID_POC_ACCOUNT,
                ApprovalHelper.RT_ID_ENGAGE_LEGAL
            })
        })
            .quantity(2)
            .create()
            .getRecords();

        Test.stopTest();

        BillingWrappers.Params params = new BillingWrappers.Params();

        params.action = 'getPOCApprovals';
        params.opportunityId = opp.Id;

        RestRequest request = new RestRequest();
        request.requestBody = Blob.valueOf(JSON.serialize(params));
        RestContext.request = request;

        ApprovalService.handle();

        String body = RestContext.response.responseBody.toString();

        List<Approval__c> pocApprovals = (List<Approval__c>) JSON.deserialize(body, List<Approval__c>.class);

        System.assertEquals(
            1,
            pocApprovals.size(),
            'Approvals should be selected'
        );
        System.assertEquals(
            ApprovalHelper.RT_ID_POC_ACCOUNT,
            pocApprovals.get(0).RecordTypeId,
            'only poc approvals should be selected'
        );
    }

    @isTest
    static void test_getPOCApprovals_ThrowException() {

        POC_GOA__c pocGoaCustomSetting = (POC_GOA__c) new SObjectBuilder(POC_GOA__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                POC_GOA__c.Sales_Rep__c => '0-0',
                POC_GOA__c.Direct_Manager__c => '0-9999',
                POC_GOA__c.Segment_Leader__c => '0-0',
                POC_GOA__c.SVP_WWS_Directs__c => '0-0',
                POC_GOA__c.SVP_WWS__c => '0-0'
            })
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.AccountId => ValueProviderBuilder.provideGenericParent(Account.SObjectType),
                Opportunity.Name => ValueProviderBuilder.provideUniqueString('TestOpportunity'),
                Opportunity.Type => OpportunityHelper.OPPORTUNITY_TYPE_NEW_BUSINESS,
                Opportunity.Brand_Name__c => RingCentralHelper.BRAND_RINGCENTRAL,
                Opportunity.Tier_Name__c => 'Professional',
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                Opportunity.CloseDate => System.today(),
                Opportunity.CurrencyIsoCode => RingCentralHelper.USD
            })
            .create()
            .getRecord();

        List<Quote> quotes = (List<Quote>) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Quote.Name => ValueProviderBuilder.provideUniqueString('Test POC Quote'),
                Quote.OpportunityId => opp.Id,
                Quote.RecordTypeId => ValueProviderBuilder.provideParents(new Set<Id>{
                    QuoteHelper.RT_ID_BILLING,
                    QuoteHelper.RT_ID_POC
                }),
                Quote.Pricebook2Id => Pricebook2Helper.getStandardPricebookId()
            })
            .quantity(2)
            .create()
            .getRecords();

        Test.startTest();

        new SObjectBuilder(Approval__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
            Approval__c.Name => 'Test Approval',
            Approval__c.Opportunity__c => opp.Id,
            Approval__c.Quote__c => ValueProviderBuilder.provideParents(quotes),
            Approval__c.RecordTypeId => ValueProviderBuilder.provideParents(new Set<Id>{
                ApprovalHelper.RT_ID_POC_ACCOUNT,
                ApprovalHelper.RT_ID_ENGAGE_LEGAL
            })
        })
            .quantity(2)
            .create()
            .getRecords();

        Test.stopTest();

        BillingWrappers.Params params = new BillingWrappers.Params();

        params.action = 'getPOCApprovals';
        params.opportunityId = 'wrong opportunity Id';

        RestRequest request = new RestRequest();
        request.requestBody = Blob.valueOf(JSON.serialize(params));
        RestContext.request = request;

        ApprovalService.handle();

        String body = RestContext.response.responseBody.toString();

        System.assert(
            body.contains('Invalid id: wrong opportunity Id'),
            'Error should be in response'
        );
    }

    @isTest
    static void test_hasSomeTaxExemptionApprovals() {

        List<Account> accounts = (List<Account>) new SObjectBuilder(Account.SObjectType)
            .quantity(2)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => 'Test Account',
                    Account.RecordTypeId => AccountHelper.RT_ID_CUSTOMER_ACCOUNT,
                    Account.BillingCountry => ValueProviderBuilder.provideList(new List<String>{'AUT', 'USA'}),
                    Account.BillingStreet => 'Lenin',
                    Account.BillingCity => 'Chicago',
                    Account.BillingState => 'Alabama',
                    Account.BillingPostalCode => '12345'})
            .create()
            .getRecords();

        List<Contact> contacts = (List<Contact>) new SObjectBuilder(Contact.SObjectType)
            .quantity(2)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.RecordTypeId => ContactHelper.RT_ID_VAR_VISIBLE,
                    Contact.LastName => 'test',
                    Contact.FirstName => 'test',
                    Contact.Preferred_Language__c => 'en_US',
                    Contact.AccountId => ValueProviderBuilder.provideList(new List<Id>{accounts[0].Id, accounts[1].Id})
                })
            .create()
            .getRecords();

        List<Opportunity> opportunities = (List<Opportunity>) new SObjectBuilder(Opportunity.SObjectType)
            .quantity(2)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.RecordTypeId => OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY,
                    Opportunity.Brand_Name__c => ValueProviderBuilder.provideList(new List<String> {OpportunityHelper.BRAND_RINGCENTRAL_EU, OpportunityHelper.BRAND_RINGCENTRAL}),
                    Opportunity.AccountId => ValueProviderBuilder.provideList(new List<Id>{accounts[0].Id, accounts[1].Id})})
            .create()
            .getRecords();

        List <Approval__c> approvals =  (List <Approval__c>) new SObjectBuilder(Approval__c.SObjectType)
            .quantity(2)
            .setFields(
                new Map<SObjectField, Object>{
                    Approval__c.Name => 'Tax Exempt Approval',
                    Approval__c.RecordTypeId => ApprovalHelper.RT_ID_TAX_EXEMPT_APPROVAL,
                    Approval__c.Account__c => ValueProviderBuilder.provideList(new List<Id>{accounts[0].Id, accounts[1].Id}),
                    Approval__c.Contact__c => ValueProviderBuilder.provideList(new List<Id>{contacts[0].Id, contacts[1].Id}),
                    Approval__c.Status__c => ValueProviderBuilder.provideList(new List<String>{ApprovalHelper.STATUS_APPROVED, ApprovalHelper.STATUS_REJECTED}),
                    Approval__c.VATExemption__c => ValueProviderBuilder.provideList(new List<String>{ApprovalHelper.STATUS_APPROVED, null}),
                    Approval__c.CountyTaxExemption__c => ValueProviderBuilder.provideList(new List<String>{null, ApprovalHelper.STATUS_APPROVED}),
                    Approval__c.FederalTaxExemption__c => ValueProviderBuilder.provideList(new List<String>{null, ApprovalHelper.STATUS_APPROVED}),
                    Approval__c.LocalTaxExemption__c => ValueProviderBuilder.provideList(new List<String>{null, ApprovalHelper.STATUS_APPROVED}),
                    Approval__c.StateTaxExemption__c => ValueProviderBuilder.provideList(new List<String>{null, ApprovalHelper.STATUS_APPROVED}),
                    Approval__c.VATNumber__c => ValueProviderBuilder.provideList(new List<String> {'23423255', ''}),
                    Approval__c.Opportunity__c => ValueProviderBuilder.provideList(new List<Id> {opportunities[0].Id, opportunities[1].Id}),
                    Approval__c.VATCountryForCheck__c => ValueProviderBuilder.provideList(new List<String> {'AT', ''})})
            .create()
            .getRecords();

        Boolean hasApprovals = false;

        Test.startTest();
        hasApprovals = ApprovalService.hasTaxExemptionApprovals(approvals[0].Account__c, OpportunityHelper.BRAND_RINGCENTRAL);
        System.assertEquals(true, hasApprovals);

        hasApprovals = ApprovalService.hasTaxExemptionApprovals(approvals[1].Account__c, OpportunityHelper.BRAND_RINGCENTRAL_EU);
        System.assertEquals(false, hasApprovals);
        Test.stopTest();
    }

    @isTest
    static void test_rejectTaxExemptionApprovals() {
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => 'Test Account',
                    Account.RecordTypeId => AccountHelper.RT_ID_CUSTOMER_ACCOUNT,
                    Account.BillingCountry => 'AUT',
                    Account.BillingStreet => 'Lenin',
                    Account.BillingCity => 'Chicago',
                    Account.BillingState => 'Alabama',
                    Account.BillingPostalCode => '12345'})
            .create()
            .getRecord();

        Contact contact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.RecordTypeId => ContactHelper.RT_ID_VAR_VISIBLE,
                    Contact.LastName => 'test',
                    Contact.FirstName => 'test',
                    Contact.Preferred_Language__c => 'en_US',
                    Contact.AccountId => acc.Id
                })
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.RecordTypeId => OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY,
                    Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL_EU,
                    Opportunity.AccountId => acc.Id})
            .create()
            .getRecord();

        Approval__c app = (Approval__c) new SObjectBuilder(Approval__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Approval__c.Name => 'Tax Exempt Approval',
                    Approval__c.RecordTypeId => ApprovalHelper.RT_ID_TAX_EXEMPT_APPROVAL,
                    Approval__c.Account__c => acc.Id,
                    Approval__c.Contact__c => contact.Id,
                    Approval__c.Status__c => ApprovalHelper.STATUS_APPROVED,
                    Approval__c.VATExemption__c => ApprovalHelper.STATUS_APPROVED,
                    Approval__c.VATNumber__c => '23423255',
                    Approval__c.Opportunity__c => opp.Id,
                    Approval__c.VATCountryForCheck__c =>  'AT'})
            .create()
            .getRecord();

        List<Approval__c> appsReject = new List<Approval__c>();
        Test.startTest();
        appsReject = ApprovalService.rejectTaxExemptionApprovals(acc.Id, OpportunityHelper.BRAND_RINGCENTRAL);
        Test.stopTest();
        System.assertEquals(1, appsReject.size());
    }

    @isTest
    static void testEngageLegalApprovalsRetrieving() {
        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => 'Test Account',
                    Account.RecordTypeId => AccountHelper.RT_ID_CUSTOMER_ACCOUNT,
                    Account.BillingCountry => 'USA',
                    Account.BillingStreet => 'Sesame st.',
                    Account.BillingCity => 'NYC',
                    Account.BillingState => 'NY',
                    Account.BillingPostalCode => '12345'})
            .create()
            .getRecord();

        Contact contact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Contact.SObjectType))
            .setField(Contact.AccountId, testAccount.Id)
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.RecordTypeId => OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY,
                    Opportunity.Brand_Name__c => OpportunityHelper.BRAND_AVAYA,
                    Opportunity.AccountId => testAccount.Id})
            .create()
            .getRecord();

        Test.startTest();

        Approval__c engageLegalApproval = (Approval__c) new SObjectBuilder(Approval__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Approval__c.Name => 'approvalToPopulate',
                    Approval__c.RecordTypeId => ApprovalHelper.RT_ID_ENGAGE_LEGAL,
                    Approval__c.Account__c => testAccount.Id,
                    Approval__c.Opportunity__c => opp.Id
                }
            )
            .create()
            .getRecord();

        Test.stopTest();

        BillingWrappers.Params params = new BillingWrappers.Params();
        params.action = 'getEngageLegalApprovals';
        params.opportunityId = opp.Id;

        RestRequest request = new RestRequest();
        request.requestBody = Blob.valueOf(JSON.serialize(params));
        RestContext.request = request;

        ApprovalService.handle();

        String body = RestContext.response.responseBody.toString();
        List<Approval__c> retrievedApprovals = (List<Approval__c>) JSON.deserializeStrict(body, List<Approval__c>.class);

        System.assertEquals(1, retrievedApprovals.size(), 'One approval should be retrieved');
    }

    @IsTest
    static void testGetApprovalDetails() {
        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => 'Test Account',
                    Account.RecordTypeId => AccountHelper.RT_ID_CUSTOMER_ACCOUNT,
                    Account.BillingCountry => 'USA',
                    Account.BillingStreet => 'Sesame st.',
                    Account.BillingCity => 'NYC',
                    Account.BillingState => 'NY',
                    Account.BillingPostalCode => '12345'})
            .create()
            .getRecord();

        Contact contact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Contact.SObjectType))
            .setField(Contact.AccountId, testAccount.Id)
            .create()
            .getRecord();
        List<AccountContactRole> testACR = (List<AccountContactRole>) new SObjectBuilder(AccountContactRole.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                AccountContactRole.AccountId => testAccount.Id,
                AccountContactRole.ContactId => contact.Id,
                AccountContactRole.Role => AccountContactRoleHelper.CONTACT_ROLE_ACCOUNT_PAYABLE
            })
            .quantity(1)
            .create()
            .getRecords();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.RecordTypeId => OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY,
                    Opportunity.Brand_Name__c => OpportunityHelper.BRAND_AVAYA,
                    Opportunity.AccountId => testAccount.Id})
            .create()
            .getRecord();

        BillingWrappers.ApprovalParams params = new BillingWrappers.ApprovalParams();
        params.recordType = ApprovalHelper.RT_NAME_INVOICE_ON_BEHALF_REQUEST_APPROVAL;
        params.accountId = testAccount.Id;

        List<ApprovalService.ApprovalDetails> result = ApprovalService.getApprovalDetails(params);
        System.assertEquals(
            ApprovalHelper.RT_INFO_BY_NAME.get(ApprovalHelper.RT_NAME_INVOICE_ON_BEHALF_REQUEST_APPROVAL).getRecordTypeId(),
            result[0].recordTypeId, 'Wrong RecordType was set to Approval'
        );
        System.assertEquals(contact.Id, result[0].defaultFieldValues.AccountPayableContact__c, 'Account Payable Contact was set incorrectly');
    }

    @isTest
    static void verifyApprovalDetailsAreReturned() {
        Test.startTest();
        Triggers.switchOff();
        Account firstPartner = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => 'Partner Account'
            })
            .create()
            .getRecord();

        Account secondPartner = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => 'Another Partner Account'
            })
            .create()
            .getRecord();

        Contact firstPartnerContact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.FirstName => 'Test1',
                    Contact.LastName => 'Test1',
                    Contact.AccountId => firstPartner.Id,
                    Contact.Email => 'test@test.com',
                    Contact.Phone => '1234567890',
                    Contact.Preferred_Language__c => 'en_US'
                }
            )
            .create()
            .getRecord();

        Contact secondPartnerContact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.FirstName => 'Test1',
                    Contact.LastName => 'Test1',
                    Contact.AccountId => secondPartner.Id,
                    Contact.Email => 'test@test.com',
                    Contact.Phone => '1234567890',
                    Contact.Preferred_Language__c => 'en_US'
                }
            )
            .create()
            .getRecord();

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => 'test Account'
            })
            .create()
            .getRecord();

        Contact contact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Contact.SObjectType))
            .setField(Contact.AccountId, acc.Id)
            .create()
            .getRecord();
        Triggers.switchOn();
        AccountContactRole payableContactRole = new AccountContactRole();
        payableContactRole.AccountId = acc.Id;
        payableContactRole.ContactId = contact.Id;
        payableContactRole.Role = AccountContactRoleHelper.CONTACT_ROLE_ACCOUNT_PAYABLE;

        AccountContactRole firstPartnerAPC = new AccountContactRole();
        firstPartnerAPC.AccountId = firstPartner.Id;
        firstPartnerAPC.ContactId = firstPartnerContact.Id;
        firstPartnerAPC.Role = AccountContactRoleHelper.CONTACT_ROLE_ACCOUNT_PAYABLE;

        AccountContactRole secondPartnerAPC = new AccountContactRole();
        secondPartnerAPC.AccountId = secondPartner.Id;
        secondPartnerAPC.ContactId = secondPartnerContact.Id;
        secondPartnerAPC.Role = AccountContactRoleHelper.CONTACT_ROLE_ACCOUNT_PAYABLE;
        insert new List<AccountContactRole> { payableContactRole, firstPartnerAPC, secondPartnerAPC };

        Opportunity testOpp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.AccountId => acc.Id,
                Opportunity.Name => 'Test Opportunity',
                Opportunity.Partner_Account__c => null,
                Opportunity.Partner_Contact__c => null
            })
            .create()
            .getRecord();

        Approval__c lastApprovedApproval = (Approval__c) new SObjectBuilder(Approval__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Approval__c.RecordTypeId => ApprovalHelper.RT_ID_INVOICE_ON_BEHALF_REQUEST,
                Approval__c.Account__c => acc.Id,
                Approval__c.Opportunity__c => testOpp.Id,
                Approval__c.AccountPayableContact__c => contact.Id,
                Approval__c.PartnerAccountPayableContact__c => firstPartnerContact.Id,
                Approval__c.SwitchInvoicePartnerAccount__c => firstPartner.Id,
                Approval__c.Status__c => ApprovalHelper.STATUS_REQUIRED
            })
            .create()
            .getRecord();

        lastApprovedApproval.Status__c = ApprovalHelper.STATUS_APPROVED;
        Triggers.switchOff();
        update lastApprovedApproval;
        Triggers.switchOn();

        // remove bill-on-behalf flow
        BillingWrappers.ApprovalParams removeBOBparams = new BillingWrappers.ApprovalParams();
        removeBOBparams.accountId = acc.Id;
        removeBOBparams.action = 'move to invoice';
        removeBOBparams.recordType = ApprovalHelper.INVOICING_REQUEST_APPROVAL_RT_NAME;

        List<ApprovalService.ApprovalDetails> removeBOBDetails = ApprovalService.getApprovalDetails(removeBOBparams);

        System.assertEquals(
            ApprovalHelper.RT_ID_INVOICING_REQUEST,
            removeBOBDetails[0].recordTypeId,
            'New Record Type should be an \'Invoicing Request\''
        );
        System.assertEquals(
            true,
            removeBOBDetails[0].defaultFieldValues.IsChangePaymentMethodRequest__c,
            'New Approval is always with change payment method'
        );
        System.assertEquals(
            contact.Id,
            removeBOBDetails[0].defaultFieldValues.AccountPayableContact__c,
            'Account\'s payable contact is populated with contact from last approval by default'
        );

        // change partner to invoice flow
        BillingWrappers.ApprovalParams changeToInvoicePartnerParams = new BillingWrappers.ApprovalParams();
        changeToInvoicePartnerParams.accountId = acc.Id;
        BillingWrappers.AccountPartner accountPartner = new BillingWrappers.AccountPartner();
        accountPartner.Id = secondPartner.Id;
        changeToInvoicePartnerParams.accountPartner = accountPartner;
        changeToInvoicePartnerParams.action = 'move to invoice';
        changeToInvoicePartnerParams.recordType = ApprovalHelper.INVOICING_REQUEST_APPROVAL_RT_NAME;

        List<ApprovalService.ApprovalDetails> changeInvoiceDetails = ApprovalService.getApprovalDetails(changeToInvoicePartnerParams);

        System.assertEquals(
            ApprovalHelper.RT_ID_INVOICING_REQUEST,
            changeInvoiceDetails[0].recordTypeId,
            'New Record Type should be an \'Invoicing Request\''
        );
        System.assertEquals(
            secondPartner.Id,
            changeInvoiceDetails[0].defaultFieldValues.SwitchInvoicePartnerAccount__c,
            'Switch Invoice Lookup is non-empty on \'Invoicing Request\' if change to non-BOB partner'
        );

        // move to BOB flow
        BillingWrappers.ApprovalParams switchBOBPartnerParams = new BillingWrappers.ApprovalParams();
        switchBOBPartnerParams.accountId = acc.Id;
        switchBOBPartnerParams.accountPartner = accountPartner;
        switchBOBPartnerParams.action = 'move to invoice-on-behalf';
        switchBOBPartnerParams.recordType = ApprovalHelper.RT_NAME_INVOICE_ON_BEHALF_REQUEST_APPROVAL;

        List<ApprovalService.ApprovalDetails> moveToBOBDetails = ApprovalService.getApprovalDetails(switchBOBPartnerParams);

        System.assertEquals(
            ApprovalHelper.RT_ID_INVOICE_ON_BEHALF_REQUEST,
            moveToBOBDetails[0].recordTypeId,
            'New Record Type should be an \'Invoicing Request\''
        );
        System.assertEquals(
            secondPartnerContact.Id,
            moveToBOBDetails[0].defaultFieldValues.PartnerAccountPayableContact__c,
            'Partner Account\'s payable contact is populated with APC from new Partner'
        );
        System.assertEquals(
            secondPartner.Id,
            moveToBOBDetails[0].defaultFieldValues.SwitchInvoicePartnerAccount__c,
            'Switch Invoice Lookup is non-empty on \'Invoicing Request\' if change BOB partner'
        );
        Test.stopTest();
    }

    @isTest
    static void testGetApprovals() {
        Test.startTest();
        Triggers.switchOff();

        Account masterAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => 'test Master Account'
            })
            .create()
            .getRecord();

        Account techAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => 'test Tech Account',
                Account.Master_Account__c => masterAcc.Id,
                Account.IsMultiProductTechnicalAccount__c => true
            })
            .create()
            .getRecord();

        Opportunity masterOpp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.AccountId => masterAcc.Id,
                Opportunity.Name => 'Test Master Opportunity',
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                Opportunity.CloseDate => System.today() + 30
            })
            .create()
            .getRecord();

        Opportunity techOpp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.AccountId => techAcc.Id,
                Opportunity.Name => 'Test Tech Opportunity',
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                Opportunity.CloseDate => System.today() + 30
            })
            .create()
            .getRecord();

        Approval__c masterApproval = (Approval__c) new SObjectBuilder(Approval__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Approval__c.RecordTypeId => ApprovalHelper.RT_ID_INVOICING_REQUEST,
                Approval__c.Account__c => masterAcc.Id,
                Approval__c.Opportunity__c => masterOpp.Id,
                Approval__c.Status__c => ApprovalHelper.STATUS_APPROVED,
                Approval__c.StatusLastModifiedDate__c => System.today(),
                Approval__c.Potential_Users__c => 1,
                Approval__c.Reason_Customer_is_Requesting_Invoicing__c => 'test'
            })
            .create()
            .getRecord();

        Approval__c techApproval = (Approval__c) new SObjectBuilder(Approval__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Approval__c.RecordTypeId => ApprovalHelper.RT_ID_INVOICING_REQUEST,
                Approval__c.Account__c => techAcc.Id,
                Approval__c.Opportunity__c => techOpp.Id,
                Approval__c.Status__c => ApprovalHelper.STATUS_APPROVED,
                Approval__c.StatusLastModifiedDate__c => System.today(),
                Approval__c.Potential_Users__c => 1,
                Approval__c.Reason_Customer_is_Requesting_Invoicing__c => 'test'
            })
            .create()
            .getRecord();

        Triggers.switchOn();

        BillingWrappers.Params params = new BillingWrappers.Params();
        params.accountId = masterAcc.Id;
        params.action = 'getApprovals';

        RestRequest request = new RestRequest();
        request.requestBody = Blob.valueOf(JSON.serialize(params));
        RestContext.request = request;

        ApprovalService.handle();

        String body = RestContext.response.responseBody.toString();
        List<Approval__c> approvals = (List<Approval__c>) JSON.deserializeStrict(body, List<Approval__c>.class);

        Test.stopTest();

        System.assertEquals(
            2,
            approvals.size(),
            'Should return 2 approvals for master and child accounts'
        );
    }
}