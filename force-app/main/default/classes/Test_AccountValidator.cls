@isTest
public class Test_AccountValidator {
    @isTest
    static void testSignUp_AlreadySignedUpValidator() {
        Account testAccount = (Account) new SObjectBuilder(Account.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => 'Test account',
                Account.RC_User_ID__c => '130001990',
                Account.Billing_ID__c => '123456789'
            })
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.CloseDate => System.today(),
                Opportunity.AccountId => testAccount.Id,
                Opportunity.Is_Billing_Opportunity__c => true,
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL
            })
            .create()
            .getRecord();

        PriceBook2 pb = (PriceBook2) new SObjectBuilder(PriceBook2.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                PriceBook2.Name => ValueProviderBuilder.provideUniqueString('test pricebook'),
                PriceBook2.IsActive => true,
                PriceBook2.Line_Range_Min__c => 2,
                PriceBook2.Service__c => Pricebook2Helper.SERVICE_OFFICE,
                PriceBook2.Plan__c => Pricebook2Helper.PLAN_ANNUAL
            })
            .create()
            .getRecord();

        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.OpportunityId => opp.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.Pricebook2Id => pb.Id,
                Quote.Status => QuoteHelper.QUOTE_STATUS_DRAFT,
                Quote.isPrimary__c => true
            })
            .create()
            .getRecord();

        List<Quote> reselectedQuotes = new QuoteSelector()
            .selectQuoteForSignUp(opp.Id)
            .executeQuery();
        Quote primaryQuote = reselectedQuotes[0];

        Test.startTest();
            Validator alreadySignedUpValidator =
                new AccountValidator.SignUp_AlreadySignedUpValidator(
                    Validator.SEVERITY_CRITICAL,
                    primaryQuote,
                    opp
                    );
            Response resp = alreadySignedUpValidator.validate(new Response());
        Test.stopTest();

        System.assertNotEquals(0, resp.messages.size());
        System.assert(resp.messages[0].messageDetails.contains(
            Label.QW_Notification_Related_Account_is_already_signed_up_help_text),
            'Existing customers aren\'t allowed to sign up'
        );
    }

    @isTest
    static void testMasterAccountValidatorRolesMismatch() {

        List<Account> accounts = (List<Account>) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => ValueProviderBuilder.provideList(new List<String>{
                        'Master Account', 'Child Account'
                    })
                }
            )
            .quantity(2)
            .create()
            .getRecords();

        Account masterAccount = accounts[0];
        Account childAccount = accounts[1];

        /* Opportunity need to be determined if account is Engage */
        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setField(Opportunity.RecordTypeId, OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY)
            .setField(Opportunity.Brand_Name__c, OpportunityHelper.BRAND_RINGCENTRAL_EU)
            .setField(Opportunity.AccountId, childAccount.Id)
            .setField(Opportunity.Tier_Name__c, OpportunityHelper.TIER_ENGAGE_VOICE_STANDALONE)
            .create()
            .getRecord();

        List<Contact> contacts = (List<Contact>) new SObjectBuilder(Contact.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Contact.SObjectType))
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.AccountId => ValueProviderBuilder.provideList(new List<Id>{
                        masterAccount.Id, childAccount.Id
                    })
                }
            )
            .quantity(2)
            .create()
            .getRecords();

        Contact masterContact = contacts[0];
        Contact childContact = contacts[1];

        /* Master and child Contact Roles point to the different contacts */
        List<AccountContactRole> contactRoles = (List<AccountContactRole>) new SObjectBuilder(AccountContactRole.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    AccountContactRole.AccountId => ValueProviderBuilder.provideList(new List<Id>{
                        childAccount.Id, masterAccount.Id
                    }),
                    AccountContactRole.ContactId => ValueProviderBuilder.provideList(new List<Id>{
                        childContact.Id, masterContact.Id
                    }),
                    AccountContactRole.Role => OpportunityHelper.CONTACT_ROLE_SIGNATORY,
                    AccountContactRole.IsPrimary => ValueProviderBuilder.provideList(new List<Boolean>{
                        true, false
                    })
                }
            )
            .quantity(2)
            .create()
            .getRecords();

        Test.startTest();
            AccountContactRole childAccountContactRole = (AccountContactRole) new AccountContactRoleSelector()
                .selectAccountContactRoles()
                .selectFields(new List<String>{
                    'AccountId', 'Contact.FirstName', 'Contact.LastName', 'Contact.Email', 'Contact.Phone'
                })
                .setCondition('AccountId = \'' + childAccount.Id + '\'' +  ' AND IsPrimary = true AND Role = \'' +
                    AccountContactRoleHelper.CONTACT_ROLE_SIGNATORY + '\'')
                .executeQuery()
                .get(0);

            Account masterAccountWithContactRoles = (Account) new AccountSelector()
                .selectAccountForOpportunityClose(new List<Object>{new Set<Id> {masterAccount.Id}})
                .executeQuery()
                .get(0);

            Validator masterAccountValidator =
                new AccountValidator.MasterAccountValidator(
                    opp,
                    childAccountContactRole,
                    masterAccountWithContactRoles,
                    null
                );
            Response resp = masterAccountValidator.validate(new Response());
        Test.stopTest();

        System.assertNotEquals(0, resp.messages.size());
        System.assert(resp.messages[0].messageDetails.contains(
            Label.Opportunity_Error_OnClose_Contact_Roles_Mismatch),
            'Child And Master Account Contact Roles should point to different Contacts - this should lead to validaton failure'
        );
    }

    @isTest
    static void testMasterAccountValidatorMasterNotSpecifiedForVoice() {

        Account childAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => ValueProviderBuilder.provideList(new List<String>{
                        'Child Account'
                    })
                }
            )
            .create()
            .getRecord();

        /* Opportunity need to be determined if account is Engage */
        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setField(Opportunity.RecordTypeId, OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY)
            .setField(Opportunity.Brand_Name__c, OpportunityHelper.BRAND_RINGCENTRAL_EU)
            .setField(Opportunity.AccountId, childAccount.Id)
            .setField(Opportunity.Tier_Name__c, OpportunityHelper.TIER_ENGAGE_VOICE_STANDALONE)
            .create()
            .getRecord();

        Contact childContact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Contact.SObjectType))
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.AccountId => ValueProviderBuilder.provideList(new List<Id>{
                        childAccount.Id
                    })
                }
            )
            .create()
            .getRecord();

        AccountContactRole childAccContactRole = (AccountContactRole) new SObjectBuilder(AccountContactRole.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    AccountContactRole.AccountId => ValueProviderBuilder.provideList(new List<Id>{
                        childAccount.Id
                    }),
                    AccountContactRole.ContactId => ValueProviderBuilder.provideList(new List<Id>{
                        childContact.Id
                    }),
                    AccountContactRole.Role => OpportunityHelper.CONTACT_ROLE_SIGNATORY,
                    AccountContactRole.IsPrimary => ValueProviderBuilder.provideList(new List<Boolean>{
                        true
                    })
                }
            )
            .create()
            .getRecord();

        Test.startTest();
            AccountContactRole childAccountContactRole = (AccountContactRole) new AccountContactRoleSelector()
                .selectAccountContactRoles()
                .selectFields(new List<String>{
                    'AccountId', 'Contact.FirstName', 'Contact.LastName', 'Contact.Email', 'Contact.Phone'
                })
                .setCondition('AccountId = \'' + childAccount.Id + '\'' +  ' AND IsPrimary = true AND Role = \'' +
                    AccountContactRoleHelper.CONTACT_ROLE_SIGNATORY + '\'')
                .executeQuery()
                .get(0);

            Validator masterAccountValidator =
                new AccountValidator.MasterAccountValidator(
                    opp,
                    childAccountContactRole,
                    null,
                    null
                );
            Response resp = masterAccountValidator.validate(new Response());
        Test.stopTest();

        System.assertNotEquals(0, resp.messages.size());
        System.assert(resp.messages[0].messageDetails.contains(
            Label.Opportunity_Error_OnClose_Contact_Roles_Mismatch),
            'Master account is required for Engage Voice/Video Accounts'
        );
    }

    @isTest
    static void testMasterAccountValidatorMasterNotSpecifiedForDigital() {

        Account childAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => ValueProviderBuilder.provideList(new List<String>{
                        'Child Account'
                    })
                }
            )
            .create()
            .getRecord();

        /* Opportunity need to be determined if account is Engage */
        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setField(Opportunity.RecordTypeId, OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY)
            .setField(Opportunity.Brand_Name__c, OpportunityHelper.BRAND_RINGCENTRAL_EU)
            .setField(Opportunity.AccountId, childAccount.Id)
            .setField(Opportunity.Tier_Name__c, OpportunityHelper.TIER_ENGAGE_DIGITAL_LEGACY)
            .create()
            .getRecord();

        Contact childContact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Contact.SObjectType))
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.AccountId => ValueProviderBuilder.provideList(new List<Id>{
                        childAccount.Id
                    })
                }
            )
            .create()
            .getRecord();

        AccountContactRole childAccContactRole = (AccountContactRole) new SObjectBuilder(AccountContactRole.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    AccountContactRole.AccountId => ValueProviderBuilder.provideList(new List<Id>{
                        childAccount.Id
                    }),
                    AccountContactRole.ContactId => ValueProviderBuilder.provideList(new List<Id>{
                        childContact.Id
                    }),
                    AccountContactRole.Role => OpportunityHelper.CONTACT_ROLE_SIGNATORY,
                    AccountContactRole.IsPrimary => ValueProviderBuilder.provideList(new List<Boolean>{
                        true
                    })
                }
            )
            .create()
            .getRecord();

        Test.startTest();
            AccountContactRole childAccountContactRole = (AccountContactRole) new AccountContactRoleSelector()
                .selectAccountContactRoles()
                .selectFields(new List<String>{
                    'AccountId', 'Contact.FirstName', 'Contact.LastName', 'Contact.Email', 'Contact.Phone'
                })
                .setCondition('AccountId = \'' + childAccount.Id + '\'' +  ' AND IsPrimary = true AND Role = \'' +
                    AccountContactRoleHelper.CONTACT_ROLE_SIGNATORY + '\'')
                .executeQuery()
                .get(0);

            Validator masterAccountValidator =
                new AccountValidator.MasterAccountValidator(
                    opp,
                    childAccountContactRole,
                    null,
                    null
                );
            Response resp = masterAccountValidator.validate(new Response());
        Test.stopTest();

        System.assertEquals(0, resp.messages.size(), 'Engage Digital opty can be closed without master account link');
    }

    @isTest
    static void testMasterAccountValidatorMasterLegacyPackage() {

        Account childAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => ValueProviderBuilder.provideList(new List<String>{
                        'Child Account'
                    })
                }
            )
            .create()
            .getRecord();

        /* Opportunity need to be determined if account is Engage */
        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setField(Opportunity.RecordTypeId, OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY)
            .setField(Opportunity.Brand_Name__c, OpportunityHelper.BRAND_RINGCENTRAL_EU)
            .setField(Opportunity.AccountId, childAccount.Id)
            .setField(Opportunity.Tier_Name__c, OpportunityHelper.TIER_ENGAGE_VOICE_LEGACY)
            .create()
            .getRecord();

        Contact childContact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Contact.SObjectType))
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.AccountId => ValueProviderBuilder.provideList(new List<Id>{
                        childAccount.Id
                    })
                }
            )
            .create()
            .getRecord();

        AccountContactRole childAccContactRole = (AccountContactRole) new SObjectBuilder(AccountContactRole.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    AccountContactRole.AccountId => ValueProviderBuilder.provideList(new List<Id>{
                        childAccount.Id
                    }),
                    AccountContactRole.ContactId => ValueProviderBuilder.provideList(new List<Id>{
                        childContact.Id
                    }),
                    AccountContactRole.Role => OpportunityHelper.CONTACT_ROLE_SIGNATORY,
                    AccountContactRole.IsPrimary => ValueProviderBuilder.provideList(new List<Boolean>{
                        true
                    })
                }
            )
            .create()
            .getRecord();

        Test.startTest();
            AccountContactRole childAccountContactRole = (AccountContactRole) new AccountContactRoleSelector()
                .selectAccountContactRoles()
                .selectFields(new List<String>{
                    'AccountId', 'Contact.FirstName', 'Contact.LastName', 'Contact.Email', 'Contact.Phone'
                })
                .setCondition('AccountId = \'' + childAccount.Id + '\'' +  ' AND IsPrimary = true AND Role = \'' +
                    AccountContactRoleHelper.CONTACT_ROLE_SIGNATORY + '\'')
                .executeQuery()
                .get(0);

            Validator masterAccountValidator =
                new AccountValidator.MasterAccountValidator(
                    opp,
                    childAccountContactRole,
                    null,
                    null
                );
            Response resp = masterAccountValidator.validate(new Response());
        Test.stopTest();

        System.assertEquals(
            0,
            resp.messages.size(),
            'Master account validation should not be fired for engage legacy packages'
        );
    }

    @isTest
    static void testELABillingAccountValidator() {
        Account testAccount = (Account) new SobjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => 'Test account',
                Account.ELA_Account_Type__c => 'ELA Billing'
            })
            .create()
            .getRecord();

        Account childAccount = (Account) new SobjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => 'Child account',
                Account.ELA_Account_Type__c => 'ELA Service',
                Account.Billing_ID__c => '323244'
            })
            .create()
            .getRecord();

        Contact testContact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Contact.FirstName => 'Test1',
                Contact.LastName => 'Test1',
                Contact.AccountId => testAccount.Id,
                Contact.Email => 'test1@test.com',
                Contact.Phone => '1234567890',
                Contact.Preferred_Language__c => 'en_US'
            })
            .create()
            .getRecord();

        AccountContactRole accountContactRole1 = (AccountContactRole) new SObjectBuilder(AccountContactRole.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                AccountContactRole.AccountId => testAccount.Id,
                AccountContactRole.ContactId => testContact.Id
            })
            .create()
            .getRecord();

        AccountContactRole accountContactRole2 = (AccountContactRole) new SObjectBuilder(AccountContactRole.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                AccountContactRole.AccountId => childAccount.Id,
                AccountContactRole.ContactId => testContact.Id
            })
            .create()
            .getRecord();

        AccountRelation__c accr = (AccountRelation__c) new SobjectBuilder(AccountRelation__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                AccountRelation__c.Child_Account__c => childAccount.Id,
                AccountRelation__c.Parent_Account__c => testAccount.Id,
                AccountRelation__c.Relation_Type__c => 'ELA'
            })
            .create()
            .getRecord();

        List<AccountRelation__c> accountRelation = (List<AccountRelation__c>) new AccountRelationSelector()
            .selectAccountRelationByParentAndChildId(testAccount.Id)
            .executeQuery();

        Test.startTest();
        Validator elaValidator =
            new AccountValidator.ELABillingAccountValidator(
                testAccount,
                accountRelation
            );
        Response resp = elaValidator.validate(new Response());
        Test.stopTest();

         System.assertEquals(
             0,
             resp.messages.size(),
             'ELABillingAccountValidator should not be fired.'
         );
    }

    @isTest
    static void testELABillingAccountValidatorFails() {
        Account testAccount = (Account) new SobjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => 'Test account',
                Account.ELA_Account_Type__c => 'ELA Billing'
            })
            .create()
            .getRecord();

        Account childAccount = (Account) new SobjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => 'Child account',
                Account.ELA_Account_Type__c => 'ELA Service',
                Account.Billing_ID__c => ''
            })
            .create()
            .getRecord();

        Contact testContact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Contact.FirstName => 'Test1',
                Contact.LastName => 'Test1',
                Contact.AccountId => testAccount.Id,
                Contact.Email => 'test1@test.com',
                Contact.Phone => '1234567890',
                Contact.Preferred_Language__c => 'en_US'
            })
            .create()
            .getRecord();

        AccountContactRole accountContactRole1 = (AccountContactRole) new SObjectBuilder(AccountContactRole.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                AccountContactRole.AccountId => testAccount.Id,
                AccountContactRole.ContactId => testContact.Id
            })
            .create()
            .getRecord();

        AccountContactRole accountContactRole2 = (AccountContactRole) new SObjectBuilder(AccountContactRole.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                AccountContactRole.AccountId => childAccount.Id,
                AccountContactRole.ContactId => testContact.Id
            })
            .create()
            .getRecord();

        AccountRelation__c accr = (AccountRelation__c) new SobjectBuilder(AccountRelation__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                AccountRelation__c.Child_Account__c => childAccount.Id,
                AccountRelation__c.Parent_Account__c => testAccount.Id,
                AccountRelation__c.Relation_Type__c => 'ELA'
            })
            .create()
            .getRecord();

        List<AccountRelation__c> accountRelation = (List<AccountRelation__c>) new AccountRelationSelector()
            .selectAccountRelationByParentAndChildId(testAccount.Id)
            .executeQuery();

        Test.startTest();
        Validator elaValidator =
            new AccountValidator.ELABillingAccountValidator(
                testAccount,
                accountRelation
            );
        Response resp = elaValidator.validate(new Response());
        Test.stopTest();

        System.assertEquals(
            1,
            resp.messages.size(),
            'ELABillingAccountValidator should be fired.'
        );
    }

    @isTest
    static void testSignUp_MasterAccountIsPaidValidator() {
        Account testAccount = (Account) new SObjectBuilder(Account.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => 'Test account',
                Account.RC_User_ID__c => '130001990',
                Account.Billing_ID__c => '123456789',
                Account.Payment_Method__c => AccountHelper.PAYMENT_METHOD_CREDIT_CARD,
                Account.RC_Account_Status__c => AccountHelper.PAID_STATUS
            })
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.CloseDate => System.today(),
                Opportunity.AccountId => testAccount.Id,
                Opportunity.Is_Billing_Opportunity__c => true,
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL,
                Opportunity.Tier_Name__c => OpportunityHelper.TIER_ENGAGE_DIGITAL_STANDALONE
            })
            .create()
            .getRecord();

        Test.startTest();
        Validator paidValidator =
            new AccountValidator.SignUp_MasterAccountIsPaidValidator(
                opp,
                testAccount
            );
        Response resp = paidValidator.validate(new Response());
        Test.stopTest();

        System.assertEquals(
            0,
            resp.messages.size(),
            'SignUp_MasterAccountIsPaidValidator should not be fired.'
        );
    }

    static void testSignUp_MasterAccountIsPaidValidatorFails() {
        Account testAccount = (Account) new SObjectBuilder(Account.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => 'Test account',
                Account.RC_User_ID__c => '130001990',
                Account.Billing_ID__c => '123456789',
                Account.Payment_Method__c => AccountHelper.PAYMENT_METHOD_CREDIT_CARD,
                Account.RC_Account_Status__c => AccountHelper.SUSPENDED_STATUS
            })
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.CloseDate => System.today(),
                Opportunity.AccountId => testAccount.Id,
                Opportunity.Is_Billing_Opportunity__c => true,
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL,
                Opportunity.Tier_Name__c => OpportunityHelper.TIER_ENGAGE_DIGITAL_STANDALONE
            })
            .create()
            .getRecord();

        Test.startTest();
        Validator paidValidator =
            new AccountValidator.SignUp_MasterAccountIsPaidValidator(
                opp,
                testAccount
            );
        Response resp = paidValidator.validate(new Response());
        Test.stopTest();

        System.assertEquals(
            1,
            resp.messages.size(),
            'SignUp_MasterAccountIsPaidValidator should be fired.'
        );
    }

    @isTest
    static void testApprovedInvoiceValidatorForOpportunity() {
        Validator approvedInvoiceValidator;
        Response resp;
        Account accountWithInvoicePaymentMethod = (Account) new SObjectBuilder(Account.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => 'Test account'
            })
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.CloseDate => System.today(),
                Opportunity.AccountId => accountWithInvoicePaymentMethod.Id,
                Opportunity.Is_Billing_Opportunity__c => true,
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL
            })
            .create()
            .getRecord();

        Approval__c approval = (Approval__c) new SObjectBuilder(Approval__c.SObjectType)
            .setField(Approval__c.Account__c, accountWithInvoicePaymentMethod.Id)
            .setField(Approval__c.Opportunity__c, opp.Id)
            .setField(Approval__c.Status__c, 'Pending Approval')
            .create()
            .getRecord();

        List<PartnerOperationsLog__c> partnerLog = (List<PartnerOperationsLog__c>) new SObjectBuilder(PartnerOperationsLog__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                PartnerOperationsLog__c.Opportunity__c => opp.Id,
                PartnerOperationsLog__c.isCompleted__c => false,
                PartnerOperationsLog__c.isRejected__c => false
            })
            .quantity(1)
            .create()
            .getRecords();
            partnerLog.clear();

        Test.startTest();
        approvedInvoiceValidator =
            new AccountValidator.ApprovedInvoiceValidator(
                new AccountValidator.ApprovedInvoiceValidatorParams(
                    opp,
                    new List<Approval__c>{},
                    AccountHelper.PAYMENT_METHOD_INVOICE,
                    true,
                    partnerLog,
                    false,
                    null,
                    false,
                    null
                )
            );
        resp = approvedInvoiceValidator.validate(new Response());
        System.assertEquals(
            1,
            resp.messages.size(),
            'ApprovedInvoiceValidator should throw an error when Payment method is Invoice and there are no created Invoice approvals'
        );

        approvedInvoiceValidator =
            new AccountValidator.ApprovedInvoiceValidator(
                new AccountValidator.ApprovedInvoiceValidatorParams(
                    opp,
                    new List<Approval__c>{approval},
                    AccountHelper.PAYMENT_METHOD_INVOICE,
                    true,
                    partnerLog,
                    false,
                    null,
                    false,
                    null
                )
            );
        resp = approvedInvoiceValidator.validate(new Response());
        System.assertEquals(
            1,
            resp.messages.size(),
            'ApprovedInvoiceValidator should throw an error when Payment method is Invoice and there are pending Invoice approvals'
        );

        // Shouldn't throw an error when Payment method is Invoice and there are approved Invoice approvals
        Approval__c approvalApproved = (Approval__c) new SObjectBuilder(Approval__c.SObjectType)
            .setField(Approval__c.Account__c, accountWithInvoicePaymentMethod.Id)
            .setField(Approval__c.Opportunity__c, opp.Id)
            .setField(Approval__c.Status__c, 'Approved')
            .create()
            .getRecord();

        approvedInvoiceValidator =
            new AccountValidator.ApprovedInvoiceValidator(
                new AccountValidator.ApprovedInvoiceValidatorParams(
                    opp,
                    new List<Approval__c>{approvalApproved},
                    AccountHelper.PAYMENT_METHOD_INVOICE,
                    true,
                    partnerLog,
                    false,
                    null,
                    false,
                    null
                )
            );
        resp = approvedInvoiceValidator.validate(new Response());
        System.assertEquals(
            0,
            resp.messages.size(),
            'ApprovedInvoiceValidator shouldn\'t throw an error when Payment method is Invoice and there are approved Invoice approvals'
        );

        // Shouldn't throw an error when Payment method is not Invoice
        approvedInvoiceValidator =
            new AccountValidator.ApprovedInvoiceValidator(
                new AccountValidator.ApprovedInvoiceValidatorParams(
                    opp,
                    new List<Approval__c>{},
                    AccountHelper.PAYMENT_METHOD_CREDIT_CARD,
                    true,
                    partnerLog,
                    false,
                    null,
                    false,
                    null
                )
            );
        resp = approvedInvoiceValidator.validate(new Response());
        System.assertEquals(
            0,
            resp.messages.size(),
            'ApprovedInvoiceValidator should throw an error when Payment method is Invoice and there are no created Invoice approvals'
        );

        // Should throw a different message for Engage
        approvedInvoiceValidator =
            new AccountValidator.ApprovedInvoiceValidator(
                new AccountValidator.ApprovedInvoiceValidatorParams(
                    new Opportunity(Tier_Name__c = OpportunityHelper.TIER_ENGAGE_DIGITAL_LEGACY),
                    new List<Approval__c>{},
                    AccountHelper.PAYMENT_METHOD_INVOICE,
                    true,
                    partnerLog,
                    false,
                    null,
                    false,
                    null
                )
            );
        resp = approvedInvoiceValidator.validate(new Response());
        System.assertNotEquals(0, resp.messages.size());
        System.assert(resp.messages[0].messageDetails.contains(
            Label.Approved_Invoicing_Request_is_requred_on_oppty_close
        ),
            'Wrong Invoice Approval Validator message for Engage accounts'
        );

        Test.stopTest();
    }

    @isTest
    static void testApprovedInvoiceValidatorMPUB() {
        Validator approvedInvoiceValidator;
        Response resp;
        Triggers.switchOff();
        Account accountWithInvoicePaymentMethod = (Account) new SObjectBuilder(Account.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => 'Test account'
            })
            .create()
            .getRecord();
        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.CloseDate => System.today(),
                Opportunity.AccountId => accountWithInvoicePaymentMethod.Id,
                Opportunity.Is_Billing_Opportunity__c => true,
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL
            })
            .create()
            .getRecord();

        List<PartnerOperationsLog__c> partnerLog = (List<PartnerOperationsLog__c>) new SObjectBuilder(PartnerOperationsLog__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                PartnerOperationsLog__c.Opportunity__c => opp.Id,
                PartnerOperationsLog__c.isCompleted__c => false,
                PartnerOperationsLog__c.isRejected__c => false
            })
            .quantity(1)
            .create()
            .getRecords();
        partnerLog.clear();

        List<String> servicesOnPrimaryQuote = new List<String>{OpportunityHelper.TIER_OFFICE, OpportunityHelper.TIER_RC_CONTACT_CENTER};
        Set<String> extServices = new Set<String>();
        Triggers.switchOn();
        approvedInvoiceValidator =
            new AccountValidator.ApprovedInvoiceValidator(
                new AccountValidator.ApprovedInvoiceValidatorParams(
                    opp,
                    new List<Approval__c>{},
                    AccountHelper.PAYMENT_METHOD_INVOICE,
                    true,
                    partnerLog,
                    true,
                    servicesOnPrimaryQuote,
                    false,
                    extServices
                )
            );
        resp = approvedInvoiceValidator.validate(new Response());
        System.assertEquals(
            1,
            resp.messages.size(),
            'ApprovedInvoiceValidator should throw an error when Payment method is Invoice and there are no created Invoice approvals'
        );
    }

    @IsTest
    static void testApprovedInvoiceValidatorMPUB2() {
        Validator approvedInvoiceValidator;
        Response resp;
        Triggers.switchOff();
        Account accountWithInvoicePaymentMethod = (Account) new SObjectBuilder(Account.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => 'Test account'
            })
            .create()
            .getRecord();
        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.CloseDate => System.today(),
                Opportunity.AccountId => accountWithInvoicePaymentMethod.Id,
                Opportunity.Is_Billing_Opportunity__c => true,
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL
            })
            .create()
            .getRecord();

        List<PartnerOperationsLog__c> partnerLog = (List<PartnerOperationsLog__c>) new SObjectBuilder(PartnerOperationsLog__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                PartnerOperationsLog__c.Opportunity__c => opp.Id,
                PartnerOperationsLog__c.isCompleted__c => false,
                PartnerOperationsLog__c.isRejected__c => false
            })
            .quantity(1)
            .create()
            .getRecords();
        partnerLog.clear();

        List<String> servicesOnPrimaryQuote = new List<String>{OpportunityHelper.TIER_OFFICE, OpportunityHelper.TIER_RC_CONTACT_CENTER};
        Set<String> extServices = new Set<String>();
        Triggers.switchOn();
        // Shouldn't throw an error when Payment method is Invoice and there are approved limits for appropriate services on Invoice approval
        Approval__c approvalApproved = (Approval__c) new SObjectBuilder(Approval__c.SObjectType)
            .setField(Approval__c.Account__c, accountWithInvoicePaymentMethod.Id)
            .setField(Approval__c.Opportunity__c, opp.Id)
            .setField(Approval__c.Status__c, 'Approved')
            .setField(Approval__c.Monthly_Credit_Limit_Office__c, 700)
            .setField(Approval__c.Sign_Up_Purchase_Limit_Office__c, 700)
            .setField(Approval__c.Monthly_Credit_Limit_Contact_Center__c, 700)
            .setField(Approval__c.Sign_Up_Purchase_Limit_Contact_Center__c, 700)
            .create()
            .getRecord();

        approvedInvoiceValidator =
            new AccountValidator.ApprovedInvoiceValidator(
                new AccountValidator.ApprovedInvoiceValidatorParams(
                    opp,
                    new List<Approval__c>{approvalApproved},
                    AccountHelper.PAYMENT_METHOD_INVOICE,
                    true,
                    partnerLog,
                    true,
                    servicesOnPrimaryQuote,
                    false,
                    extServices
                )
            );
        resp = approvedInvoiceValidator.validate(new Response());
        System.assertEquals(
            0,
            resp.messages.size(),
            'ApprovedInvoiceValidator shouldn\'t throw an error when Payment method is Invoice and there are approved Invoice approvals for appropriate services'
        );

        Test.startTest();

        // Should throw an error when Payment method is Invoice and there are no approved limits for appropriate services on Invoice approval
        Approval__c approvalApprovedNoLimits = (Approval__c) new SObjectBuilder(Approval__c.SObjectType)
            .setField(Approval__c.Account__c, accountWithInvoicePaymentMethod.Id)
            .setField(Approval__c.Opportunity__c, opp.Id)
            .setField(Approval__c.Status__c, 'Approved')
            .setField(Approval__c.Monthly_Credit_Limit_Office__c, -1)
            .setField(Approval__c.Sign_Up_Purchase_Limit_Office__c, -1)
            .setField(Approval__c.Monthly_Credit_Limit_Contact_Center__c, -1)
            .setField(Approval__c.Sign_Up_Purchase_Limit_Contact_Center__c, -1)
            .create()
            .getRecord();

        approvedInvoiceValidator =
            new AccountValidator.ApprovedInvoiceValidator(
                new AccountValidator.ApprovedInvoiceValidatorParams(
                    opp,
                    new List<Approval__c>{approvalApprovedNoLimits},
                    AccountHelper.PAYMENT_METHOD_INVOICE,
                    true,
                    partnerLog,
                    true,
                    servicesOnPrimaryQuote,
                    false,
                    extServices
                )
            );
        resp = approvedInvoiceValidator.validate(new Response());
        System.assertEquals(
            1,
            resp.messages.size(),
            'ApprovedInvoiceValidator should throw an error when Payment method is Invoice and there are no approved Invoice approvals for appropriate services'
        );

        Test.stopTest();
    }

    @isTest
    static void testApprovedInvoiceValidatorMPUBSingleProductPass() {
        Validator approvedInvoiceValidator;
        Response resp;
        Account accountWithInvoicePaymentMethod = (Account) new SObjectBuilder(Account.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => 'Test account'
            })
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.CloseDate => System.today(),
                Opportunity.AccountId => accountWithInvoicePaymentMethod.Id,
                Opportunity.Is_Billing_Opportunity__c => true,
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL
            })
            .create()
            .getRecord();

        List<PartnerOperationsLog__c> partnerLog = (List<PartnerOperationsLog__c>) new SObjectBuilder(PartnerOperationsLog__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                PartnerOperationsLog__c.Opportunity__c => opp.Id,
                PartnerOperationsLog__c.isCompleted__c => false,
                PartnerOperationsLog__c.isRejected__c => false
            })
            .quantity(1)
            .create()
            .getRecords();
        partnerLog.clear();

        List<String> servicesOnPrimaryQuoteSingleProduct = new List<String>{OpportunityHelper.TIER_ENGAGE_DIGITAL_STANDALONE};
        Set<String> extServices = new Set<String>();

        Test.startTest();

        // Shouldn't throw an error when Payment method is Invoice and there are approved limits for single product on Invoice approval
        Approval__c approvalApprovedSP = (Approval__c) new SObjectBuilder(Approval__c.SObjectType)
            .setField(Approval__c.Account__c, accountWithInvoicePaymentMethod.Id)
            .setField(Approval__c.Opportunity__c, opp.Id)
            .setField(Approval__c.Status__c, 'Approved')
            .setField(Approval__c.Monthly_Credit_Limit__c, 700)
            .setField(Approval__c.Sign_Up_Purchase_Limit__c, 700)
            .setField(Approval__c.Sign_Up_Purchase_Limit_Office__c, -1)
            .setField(Approval__c.Sign_Up_Purchase_Limit_Contact_Center__c, -1)
            .setField(Approval__c.Sign_Up_Purchase_Limit_Engage_Voice__c, -1)
            .setField(Approval__c.Sign_Up_Purchase_Limit_Engage_Digital__c, -1)
            .setField(Approval__c.Sign_Up_Purchase_Limit_for_RC_Events__c, -1)
            .setField(Approval__c.Monthly_Credit_Limit_Office__c, -1)
            .setField(Approval__c.Monthly_Credit_Limit_Contact_Center__c, -1)
            .setField(Approval__c.Monthly_Credit_Limit_Engage_Voice__c, -1)
            .setField(Approval__c.Monthly_Credit_Limit_Engage_Digital__c, -1)
            .setField(Approval__c.Monthly_Credit_Limit_for_RC_Events__c, -1)
            .create()
            .getRecord();

        approvedInvoiceValidator =
            new AccountValidator.ApprovedInvoiceValidator(
                new AccountValidator.ApprovedInvoiceValidatorParams(
                    opp,
                    new List<Approval__c>{approvalApprovedSP},
                    AccountHelper.PAYMENT_METHOD_INVOICE,
                    true,
                    partnerLog,
                    true,
                    servicesOnPrimaryQuoteSingleProduct,
                    true,
                    extServices
                )
            );
        resp = approvedInvoiceValidator.validate(new Response());
        System.assertEquals(
            0,
            resp.messages.size(),
            'ApprovedInvoiceValidator shouldn\'t throw an error when Payment method is Invoice and there are approved limits for single product on Invoice approval'
        );

        Test.stopTest();
    }

    @isTest
    static void testApprovedInvoiceValidatorMPUBSingleProductFail() {
        Validator approvedInvoiceValidator;
        Response resp;
        Account accountWithInvoicePaymentMethod = (Account) new SObjectBuilder(Account.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => 'Test account'
            })
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.CloseDate => System.today(),
                Opportunity.AccountId => accountWithInvoicePaymentMethod.Id,
                Opportunity.Is_Billing_Opportunity__c => true,
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL
            })
            .create()
            .getRecord();

        List<PartnerOperationsLog__c> partnerLog = (List<PartnerOperationsLog__c>) new SObjectBuilder(PartnerOperationsLog__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                PartnerOperationsLog__c.Opportunity__c => opp.Id,
                PartnerOperationsLog__c.isCompleted__c => false,
                PartnerOperationsLog__c.isRejected__c => false
            })
            .quantity(1)
            .create()
            .getRecords();
        partnerLog.clear();

        List<String> servicesOnPrimaryQuoteSingleProduct = new List<String>{OpportunityHelper.TIER_ENGAGE_DIGITAL_STANDALONE};
        Set<String> extServices = new Set<String>();

        Test.startTest();

        // Should throw an error when Payment method is Invoice and there are no approved limits for single product on Invoice approval
        Approval__c approvalApprovedSPNoLimits = (Approval__c) new SObjectBuilder(Approval__c.SObjectType)
            .setField(Approval__c.Account__c, accountWithInvoicePaymentMethod.Id)
            .setField(Approval__c.Opportunity__c, opp.Id)
            .setField(Approval__c.Status__c, 'Approved')
            .setField(Approval__c.Monthly_Credit_Limit__c, -1)
            .setField(Approval__c.Sign_Up_Purchase_Limit__c, -1)
            .create()
            .getRecord();

        approvedInvoiceValidator =
            new AccountValidator.ApprovedInvoiceValidator(
                new AccountValidator.ApprovedInvoiceValidatorParams(
                    opp,
                    new List<Approval__c>{approvalApprovedSPNoLimits},
                    AccountHelper.PAYMENT_METHOD_INVOICE,
                    true,
                    partnerLog,
                    true,
                    servicesOnPrimaryQuoteSingleProduct,
                    true,
                    extServices
                )
            );
        resp = approvedInvoiceValidator.validate(new Response());
        System.assertEquals(
            1,
            resp.messages.size(),
            'ApprovedInvoiceValidator should throw an error when Payment method is Invoice and there are no approved limits for single product on Invoice approval'
        );

        Test.stopTest();
    }

    @isTest
    static void testTerminatedAccountValidator() {
        Account acc = (Account) new SObjectBuilder(Account.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => 'Test account',
                Account.RC_Account_Status__c => 'terminated'
            })
            .build()
            .getRecord();

        Validator validator = new AccountValidator.SyncWithNGBS_TerminatedAccountValidator(acc);
        Response resp = new Response();

        Test.startTest();

        resp = validator.validate(resp);

        Test.stopTest();

        System.assertNotEquals(0, resp.messages.size(), 'Validation shouldn\'t be passed and errors should be handled');
        System.assertEquals(resp.messages.get(0).messageDetails, Label.TerminatedAccountOnOpportunity,
            'Account should have "terminated" RC Status');
    }

    @isTest
    static void testTerminatedAccountValidatorNotTerminatedAcc() {
        Account acc = (Account) new SObjectBuilder(Account.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => 'Test account'
            })
            .build()
            .getRecord();

        Validator validator = new AccountValidator.SyncWithNGBS_TerminatedAccountValidator(acc);
        Response resp = new Response();

        Test.startTest();

        resp = validator.validate(resp);

        Test.stopTest();

        System.assert(resp.messages.isEmpty(), 'Validation should be passed');
    }

    @isTest
    static void testApprovedInvoiceOnBehalfValidator() {
        Validator approvedInvoiceOnBehalfValidator;
        Response resp;

        BillingHttpRequestMock testMock = new BillingHttpRequestMock();
        testMock.body = '[{"id":20392013,"name":"Monthly money amount limit","code":"MONTHLY_AMOUNT_LIMIT","value":33333,"type":"Amount",' +
        '"scope":"BillingCycle","transactionType":"Any","target":"Global","targetId":null,"exclusions":[{"target":"LicenseCategoryId","targetId":"AP"}],' +
        '"override":true,"paymentType":null,"startDate":null,"limitDuration":null,"overriddenLimitId":null,"limitOverride":{"id":20393013,' +
        '"name":"Monthly money amount limit","code":"MONTHLY_AMOUNT_LIMIT","value":0,"type":"Amount","scope":"BillingCycle","transactionType":"Any",' +
        '"target":"Global","targetId":null,"exclusions":null,"override":true,"paymentType":"InvoiceWholesale","startDate":"2022-04-13T07:49Z[UTC]",' +
        '"limitDuration":{"unit":"Months","value":30},"overriddenLimitId":20392013,"limitOverride":null}}]';
        testMock.code = 200;
        testMock.status = 'Complete';
        Test.setMock(HttpCalloutMock.class, testMock);

        upsert new NGBS_Settings__c(
            BaseEndpoint__c = 'https://testapi/',
            AccountManagerPath__c = '/restapi/account-manager/v1.0',
            Login__c = '123',
            Password__c = '456'
        );

        Account accountInvoiceOnBehalf = (Account) new SObjectBuilder(Account.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => 'Test account',
                Account.Billing_ID__c => '123456789',
                Account.Partner_ID__c => 'anyPartnerId',
                Account.Partner_Type__c => AccountHelper.ACCOUNT_PARTNER_BILL_ON_BEHALF
            })
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.CloseDate => System.today(),
                Opportunity.AccountId => accountInvoiceOnBehalf.Id,
                Opportunity.Is_Billing_Opportunity__c => true,
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL
            })
            .create()
            .getRecord();

        Opportunity opportunityRec = (Opportunity) new OpportunitySelector()
            .selectOpportunities()
            .selectFields(new List<String>{
                'Account.Id',
                'Account.Billing_ID__c',
                'Account.Partner_ID__c',
                'Account.Partner_Type__c'
            })
            .setCondition('Id = :bind0')
            .setLimit(1)
            .setQueryBindings(new List<Object>{
                opp.Id
            })
            .executeQuery()
            .get(0);

        List<PartnerOperationsLog__c> partnerLog = (List<PartnerOperationsLog__c>) new SObjectBuilder(PartnerOperationsLog__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                PartnerOperationsLog__c.Opportunity__c => opp.Id,
                PartnerOperationsLog__c.isCompleted__c => false,
                PartnerOperationsLog__c.isRejected__c => false
            })
            .quantity(1)
            .create()
            .getRecords();
            partnerLog.clear();

        Test.startTest();

        approvedInvoiceOnBehalfValidator =
            new AccountValidator.ApprovedInvoiceOnBehalfValidator(opportunityRec, true, partnerLog);
        resp = approvedInvoiceOnBehalfValidator.validate(new Response());
        if (resp.messages.size() > 1) {
            System.debug('Error messages: ' + resp.messages);
        }
        System.assertEquals(
            1,
            resp.messages.size(),
            'ApprovedInvoiceOnBehalfValidator should throw an error when Payment method is Invoice On Behalf and there are no created Invoice approvals'
        );

        Approval__c approval = (Approval__c) new SObjectBuilder(Approval__c.SObjectType)
            .setField(Approval__c.Account__c, accountInvoiceOnBehalf.Id)
            .setField(Approval__c.Status__c, 'Pending Approval')
            .create()
            .getRecord();

        approvedInvoiceOnBehalfValidator =
            new AccountValidator.ApprovedInvoiceOnBehalfValidator(opportunityRec, true, partnerLog);
        resp = approvedInvoiceOnBehalfValidator.validate(new Response());
        if (resp.messages.size() > 1) {
            System.debug('Error messages: ' + resp.messages);
        }
        System.assertEquals(
            1,
            resp.messages.size(),
            'ApprovedInvoiceOnBehalfValidator should throw an error when Payment method is Invoice On Behalf and there are pending Invoice approvals'
        );
        Test.stopTest();
    }

        @isTest
    static void testApprovedInvoiceOnBehalfValidatorOnChangePartner() {
        Validator approvedInvoiceOnBehalfValidator;
        Response resp;

        BillingHttpRequestMock testMock = new BillingHttpRequestMock();
        testMock.body = '[{"id":20392013,"name":"Monthly money amount limit","code":"MONTHLY_AMOUNT_LIMIT","value":33333,"type":"Amount",' +
        '"scope":"BillingCycle","transactionType":"Any","target":"Global","targetId":null,"exclusions":[{"target":"LicenseCategoryId","targetId":"AP"}],' +
        '"override":true,"paymentType":null,"startDate":null,"limitDuration":null,"overriddenLimitId":null,"limitOverride":{"id":20393013,' +
        '"name":"Monthly money amount limit","code":"MONTHLY_AMOUNT_LIMIT","value":0,"type":"Amount","scope":"BillingCycle","transactionType":"Any",' +
        '"target":"Global","targetId":null,"exclusions":null,"override":true,"paymentType":"InvoiceWholesale","startDate":"2022-04-13T07:49Z[UTC]",' +
        '"limitDuration":{"unit":"Months","value":30},"overriddenLimitId":20392013,"limitOverride":null}}]';
        testMock.code = 200;
        testMock.status = 'Complete';
        Test.setMock(HttpCalloutMock.class, testMock);

        upsert new NGBS_Settings__c(
            BaseEndpoint__c = 'https://testapi/',
            AccountManagerPath__c = '/restapi/account-manager/v1.0',
            Login__c = '123',
            Password__c = '456'
        );
        Triggers.switchOff();

        Account accountInvoiceOnBehalf = (Account) new SObjectBuilder(Account.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => 'Test account',
                Account.Billing_ID__c => '123456789',
                Account.Partner_ID__c => 'anyPartnerId',
                Account.Partner_Type__c => AccountHelper.ACCOUNT_PARTNER_BILL_ON_BEHALF,
                Account.Monthly_Credit_Limit__c => 2000,
                Account.Sign_up_purchase_limit__c => 1500
            })
            .create()
            .getRecord();

        Account partnerAccWholesale = (Account) new SObjectBuilder(Account.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => 'Test partner account',
                Account.Billing_ID__c => '123456789',
                Account.Partner_ID__c => 'anyPartnerId1',
                Account.Partner_Type__c => AccountHelper.ACCOUNT_PARTNER_WHOLESALE
            })
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.CloseDate => System.today(),
                Opportunity.AccountId => accountInvoiceOnBehalf.Id,
                Opportunity.Is_Billing_Opportunity__c => true,
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL,
                Opportunity.Partner_Account__c => partnerAccWholesale.Id
            })
            .create()
            .getRecord();

        Package__c pack = (Package__c) new SObjectBuilder(Package__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Package__c.Account__c => accountInvoiceOnBehalf.Id,
                Package__c.Enterprise_Account_ID__c => accountInvoiceOnBehalf.Id,
                Package__c.Account_Package_Id__c => accountInvoiceOnBehalf.Billing_ID__c
            })
            .create()
            .getRecord();

        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.OpportunityId => opp.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.isPrimary__c => true,
                Quote.PaymentMethod__c => QuoteHelper.PAYMENT_METHOD_WHOLESALE,
                Quote.Entitlement_Total_MRR__c => 1000,
                Quote.Total_MRR_New__c => 500,
                Quote.Total_One_Time__c => 1000
            })
            .create()
            .getRecord();

        List<PartnerOperationsLog__c> partnerLog = (List<PartnerOperationsLog__c>) new SObjectBuilder(PartnerOperationsLog__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                PartnerOperationsLog__c.Opportunity__c => opp.Id,
                PartnerOperationsLog__c.isCompleted__c => false,
                PartnerOperationsLog__c.isRejected__c => false
            })
            .quantity(1)
            .create()
            .getRecords();

        Approval__c approvalApproved = (Approval__c) new SObjectBuilder(Approval__c.SObjectType)
            .setField(Approval__c.Account__c, accountInvoiceOnBehalf.Id)
            .setField(Approval__c.Status__c, ApprovalHelper.STATUS_APPROVED)
            .setField(Approval__c.RecordTypeId, ApprovalHelper.RT_ID_INVOICE_WHOLESALE_REQUEST)
            .setField(Approval__c.Opportunity__c, opp.Id)
            .create()
            .getRecord();

        Triggers.switchOn();

        Opportunity opportunityRec = (Opportunity) new OpportunitySelector()
            .selectOpportunities()
            .selectFields(new List<String>{
                'Account.Id',
                'Account.Billing_ID__c',
                'Account.Partner_ID__c',
                'Account.Partner_Type__c',
                'Account.Monthly_Credit_Limit__c',
                'Account.Sign_up_purchase_limit__c',
                'Partner_Account__r.Partner_Type__c',
                'Partner_Account__r.Partner_ID__c'
            })
            .setCondition('Id = :bind0')
            .setLimit(1)
            .setQueryBindings(new List<Object>{
                opp.Id
            })
            .executeQuery()
            .get(0);

        Test.startTest();

         approvedInvoiceOnBehalfValidator =
            new AccountValidator.ApprovedInvoiceOnBehalfValidator(opportunityRec, true, partnerLog);
        resp = approvedInvoiceOnBehalfValidator.validate(new Response());
        if (resp.messages.size() > 0) {
            System.debug('Error messages: ' + resp.messages);
        }
        System.assertEquals(
            0,
            resp.messages.size(),
            'ApprovedInvoiceOnBehalfValidator should not throw an error when Invoice is Wholesale and Account is Bill on Behalf'
        );
        Test.stopTest();
    }

    @isTest
    static void testApprovedInvoiceOnBehalfValidatorNotInvoice() {
        Validator approvedInvoiceOnBehalfValidator;
        Response resp;

        BillingHttpRequestMock testMock = new BillingHttpRequestMock();
        testMock.body = '[{"id":20392013,"name":"Monthly money amount limit","code":"MONTHLY_AMOUNT_LIMIT","value":33333,"type":"Amount",' +
        '"scope":"BillingCycle","transactionType":"Any","target":"Global","targetId":null,"exclusions":[{"target":"LicenseCategoryId","targetId":"AP"}],' +
        '"override":true,"paymentType":null,"startDate":null,"limitDuration":null,"overriddenLimitId":null,"limitOverride":{"id":20393013,' +
        '"name":"Monthly money amount limit","code":"MONTHLY_AMOUNT_LIMIT","value":0,"type":"Amount","scope":"BillingCycle","transactionType":"Any",' +
        '"target":"Global","targetId":null,"exclusions":null,"override":true,"paymentType":"InvoiceWholesale","startDate":"2022-04-13T07:49Z[UTC]",' +
        '"limitDuration":{"unit":"Months","value":30},"overriddenLimitId":20392013,"limitOverride":null}}]';
        testMock.code = 200;
        testMock.status = 'Complete';
        Test.setMock(HttpCalloutMock.class, testMock);

        upsert new NGBS_Settings__c(
            BaseEndpoint__c = 'https://testapi/',
            AccountManagerPath__c = '/restapi/account-manager/v1.0',
            Login__c = '123',
            Password__c = '456'
        );

        // Account accountInvoiceOnBehalf = (Account) new SObjectBuilder(Account.sObjectType)
        //     .setFields(new Map<SObjectField, Object>{
        //         Account.Name => 'Test account',
        //         Account.Billing_ID__c => '123456789',
        //         Account.Partner_ID__c => 'anyPartnerId',
        //         Account.Partner_Type__c => AccountHelper.ACCOUNT_PARTNER_BILL_ON_BEHALF
        //     })
        //     .create()
        //     .getRecord();
        // // Shouldn't throw an error when Payment method is Invoice On Behalf and there are approved Invoice approvals
        // Opportunity oppApproved = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
        //     .setFields(new Map<SObjectField, Object> {
        //         Opportunity.CloseDate => System.today(),
        //         Opportunity.AccountId => accountInvoiceOnBehalf.Id,
        //         Opportunity.Is_Billing_Opportunity__c => true,
        //         Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL
        //     })
        //     .create()
        //     .getRecord();

        //     Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
        //     .setFields(new Map<SObjectField, Object> {
        //         Quote.OpportunityId => oppApproved.Id,
        //         Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
        //         Quote.isPrimary__c => true,
        //         Quote.PaymentMethod__c => QuoteHelper.PAYMENT_METHOD_INVOICE_ON_BEHALF,
        //         Quote.Entitlement_Total_MRR__c => 1000,
        //         Quote.Total_MRR_New__c => 500,
        //         Quote.Total_One_Time__c => 1000
        //     })
        //     .create()
        //     .getRecord();

        // Package__c pack = (Package__c) new SObjectBuilder(Package__c.SObjectType)
        //     .setFields(new Map<SObjectField, Object> {
        //         Package__c.Account__c => accountInvoiceOnBehalf.Id,
        //         Package__c.Account_Package_Id__c => accountInvoiceOnBehalf.Billing_ID__c
        //     })
        //     .create()
        //     .getRecord();

        //Triggers.switchOff();
        // Approval__c approvalApproved = (Approval__c) new SObjectBuilder(Approval__c.SObjectType)
        //     .setField(Approval__c.Account__c, accountInvoiceOnBehalf.Id)
        //     .setField(Approval__c.Status__c, ApprovalHelper.STATUS_APPROVED)
        //     .setField(Approval__c.RecordTypeId, ApprovalHelper.RT_ID_INVOICE_ON_BEHALF_REQUEST)
        //     .setField(Approval__c.Opportunity__c, oppApproved.Id)
        //     .create()
        //     .getRecord();
        //Triggers.switchOn();

        // Opportunity opportunityApproved = (Opportunity) new OpportunitySelector()
        //     .selectOpportunities()
        //     .selectFields(new List<String>{
        //         'Account.Id',
        //         'Account.Billing_ID__c',
        //         'Account.Partner_ID__c',
        //         'Account.Partner_Type__c'
        //     })
        //     .setCondition('Id = :bind0')
        //     .setLimit(1)
        //     .setQueryBindings(new List<Object>{
        //         oppApproved.Id
        //     })
        //     .executeQuery()
        //     .get(0);

        //     List<PartnerOperationsLog__c> partnerLog = (List<PartnerOperationsLog__c>) new SObjectBuilder(PartnerOperationsLog__c.SObjectType)
        //     .setFields(new Map<SObjectField, Object> {
        //         PartnerOperationsLog__c.Opportunity__c => oppApproved.Id,
        //         PartnerOperationsLog__c.isCompleted__c => false,
        //         PartnerOperationsLog__c.isRejected__c => false
        //     })
        //     .quantity(1)
        //     .create()
        //     .getRecords();
        //     partnerLog.clear();
        //     Test.startTest();
        // approvedInvoiceOnBehalfValidator =
        //     new AccountValidator.ApprovedInvoiceOnBehalfValidator(opportunityApproved, true, partnerLog);
        // resp = approvedInvoiceOnBehalfValidator.validate(new Response());
        // if (resp.messages.size() > 0) {
        //     System.debug('Error messages: ' + resp.messages);
        // }
        // System.assertEquals(
        //     0,
        //     resp.messages.size(),
        //     'ApprovedInvoiceOnBehalfValidator shouldn\'t throw an error when Payment method is Invoice on Behalf and there are approved Invoice-on-Behalf approvals'
        // );
        // Test.stopTest();

        // Shouldn't throw an error when Payment method is not Invoice
        Account nonInvoiceOnBehalfAccount = (Account) new SObjectBuilder(Account.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => 'Test account',
                Account.Billing_ID__c => '123456789',
                Account.Partner_ID__c => '',
                Account.Partner_Type__c => ''
            })
            .create()
            .getRecord();

        Opportunity oppCC = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.CloseDate => System.today(),
                Opportunity.AccountId => nonInvoiceOnBehalfAccount.Id,
                Opportunity.Is_Billing_Opportunity__c => true,
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL
            })
            .create()
            .getRecord();

        Opportunity opportunityCC = (Opportunity) new OpportunitySelector()
            .selectOpportunities()
            .selectFields(new List<String>{
                'Account.Billing_ID__c',
                'Account.Partner_ID__c',
                'Account.Partner_Type__c'
            })
            .setCondition('Id = :bind0')
            .setLimit(1)
            .setQueryBindings(new List<Object>{
                oppCC.Id
            })
            .executeQuery()
            .get(0);

        List<PartnerOperationsLog__c> partnerLog = (List<PartnerOperationsLog__c>) new SObjectBuilder(PartnerOperationsLog__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                PartnerOperationsLog__c.Opportunity__c => oppCC.Id,
                PartnerOperationsLog__c.isCompleted__c => false,
                PartnerOperationsLog__c.isRejected__c => false
            })
            .quantity(1)
            .create()
            .getRecords();
            partnerLog.clear();

        Test.startTest();
        approvedInvoiceOnBehalfValidator =
            new AccountValidator.ApprovedInvoiceOnBehalfValidator(opportunityCC, true, partnerLog);
        resp = approvedInvoiceOnBehalfValidator.validate(new Response());
        if (resp.messages.size() > 0) {
            System.debug('Error messages: ' + resp.messages);
        }
        System.assertEquals(
            0,
            resp.messages.size(),
            'ApprovedInvoiceOnBehalfValidator should not throw an error when Payment method is not Invoice-On-Behalf and there are no created Invoice-On-Behalf approvals'
        );
        Test.stopTest();
    }

    @isTest
    static void testApprovedInvoiceWholesaleValidator() {
        Validator approvedInvoiceWholesaleValidator;
        Response resp;
        Account accountInvoiceWholesale = (Account) new SObjectBuilder(Account.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => 'Test account',
                Account.Partner_ID__c => 'anyPartnerId',
                Account.Partner_Type__c => AccountHelper.ACCOUNT_PARTNER_WHOLESALE
            })
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.CloseDate => System.today(),
                Opportunity.AccountId => accountInvoiceWholesale.Id,
                Opportunity.Is_Billing_Opportunity__c => true,
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL
            })
            .create()
            .getRecord();

        Opportunity opportunityRec = (Opportunity) new OpportunitySelector()
            .selectOpportunities()
            .selectFields(new List<String>{
                'Account.Id',
                'Account.Billing_ID__c',
                'Account.Partner_ID__c',
                'Account.Partner_Type__c',
                'Partner_Account__r.Partner_Type__c',
                'Partner_Account__r.Partner_ID__c'
            })
            .setCondition('Id = :bind0')
            .setLimit(1)
            .setQueryBindings(new List<Object>{
                opp.Id
            })
            .executeQuery()
            .get(0);

        List<PartnerOperationsLog__c> partnerLog = (List<PartnerOperationsLog__c>) new SObjectBuilder(PartnerOperationsLog__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                PartnerOperationsLog__c.Opportunity__c => opportunityRec.Id,
                PartnerOperationsLog__c.isCompleted__c => false,
                PartnerOperationsLog__c.isRejected__c => false
            })
            .quantity(1)
            .create()
            .getRecords();


        Test.startTest();

        approvedInvoiceWholesaleValidator =
            new AccountValidator.approvedInvoiceWholesaleValidator(opportunityRec, true, partnerLog);
        resp = approvedInvoiceWholesaleValidator.validate(new Response());
        if (resp.messages.size() > 1) {
            System.debug('Error messages: ' + resp.messages);
        }
        System.assertEquals(
            1,
            resp.messages.size(),
            'approvedInvoiceWholesaleValidator should throw an error when Payment method is Wholesale and there are no created Invoice approvals'
        );

        Approval__c approval = (Approval__c) new SObjectBuilder(Approval__c.SObjectType)
            .setField(Approval__c.Account__c, accountInvoiceWholesale.Id)
            .setField(Approval__c.Status__c, 'Pending Approval')
            .setField(Approval__c.Opportunity__c, opportunityRec.Id)
            .create()
            .getRecord();

        approvedInvoiceWholesaleValidator =
            new AccountValidator.approvedInvoiceWholesaleValidator(opportunityRec, true, partnerLog);
        resp = approvedInvoiceWholesaleValidator.validate(new Response());
        if (resp.messages.size() > 1) {
            System.debug('Error messages: ' + resp.messages);
        }
        System.assertEquals(
            1,
            resp.messages.size(),
            'approvedInvoiceWholesaleValidator should throw an error when Payment method is Wholesale and there are pending Invoice approvals'
        );
    }

    @isTest
    static void testApprovedInvoiceWholesaleValidatorOnChangePartner() {
        Validator approvedInvoiceWholesaleValidator;
        Response resp;

        BillingHttpRequestMock testMock = new BillingHttpRequestMock();
        testMock.body = '[{"id":20392013,"name":"Monthly money amount limit","code":"MONTHLY_AMOUNT_LIMIT","value":33333,"type":"Amount",' +
        '"scope":"BillingCycle","transactionType":"Any","target":"Global","targetId":null,"exclusions":[{"target":"LicenseCategoryId","targetId":"AP"}],' +
        '"override":true,"paymentType":null,"startDate":null,"limitDuration":null,"overriddenLimitId":null,"limitOverride":{"id":20393013,' +
        '"name":"Monthly money amount limit","code":"MONTHLY_AMOUNT_LIMIT","value":0,"type":"Amount","scope":"BillingCycle","transactionType":"Any",' +
        '"target":"Global","targetId":null,"exclusions":null,"override":true,"paymentType":"InvoiceWholesale","startDate":"2022-04-13T07:49Z[UTC]",' +
        '"limitDuration":{"unit":"Months","value":30},"overriddenLimitId":20392013,"limitOverride":null}}]';
        testMock.code = 200;
        testMock.status = 'Complete';
        Test.setMock(HttpCalloutMock.class, testMock);

        upsert new NGBS_Settings__c(
            BaseEndpoint__c = 'https://testapi/',
            AccountManagerPath__c = '/restapi/account-manager/v1.0',
            Login__c = '123',
            Password__c = '456'
        );
        Triggers.switchOff();

        Account accountInvoiceWholesale = (Account) new SObjectBuilder(Account.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => 'Test account',
                Account.Billing_ID__c => '123456789',
                Account.Partner_ID__c => 'anyPartnerId',
                Account.Partner_Type__c => AccountHelper.ACCOUNT_PARTNER_WHOLESALE,
                Account.Monthly_Credit_Limit__c => 2000,
                Account.Sign_up_purchase_limit__c => 1500
            })
            .create()
            .getRecord();

        Account partnerAccBillOnBehalf = (Account) new SObjectBuilder(Account.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => 'Test partner account',
                Account.Billing_ID__c => '123456789',
                Account.Partner_ID__c => 'anyPartnerId1',
                Account.Partner_Type__c => AccountHelper.ACCOUNT_PARTNER_BILL_ON_BEHALF
            })
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.CloseDate => System.today(),
                Opportunity.AccountId => accountInvoiceWholesale.Id,
                Opportunity.Is_Billing_Opportunity__c => true,
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL,
                Opportunity.Partner_Account__c => partnerAccBillOnBehalf.Id
            })
            .create()
            .getRecord();

        Package__c pack = (Package__c) new SObjectBuilder(Package__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Package__c.Account__c => accountInvoiceWholesale.Id,
                Package__c.Enterprise_Account_ID__c => accountInvoiceWholesale.Id,
                Package__c.Account_Package_Id__c => accountInvoiceWholesale.Billing_ID__c
            })
            .create()
            .getRecord();


        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.OpportunityId => opp.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.isPrimary__c => true,
                Quote.PaymentMethod__c => QuoteHelper.PAYMENT_METHOD_INVOICE_ON_BEHALF,
                Quote.Entitlement_Total_MRR__c => 1000,
                Quote.Total_MRR_New__c => 500,
                Quote.Total_One_Time__c => 1000
            })
            .create()
            .getRecord();

        List<PartnerOperationsLog__c> partnerLog = (List<PartnerOperationsLog__c>) new SObjectBuilder(PartnerOperationsLog__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                PartnerOperationsLog__c.Opportunity__c => opp.Id,
                PartnerOperationsLog__c.isCompleted__c => false,
                PartnerOperationsLog__c.isRejected__c => false
            })
            .quantity(1)
            .create()
            .getRecords();

        Approval__c approvalApproved = (Approval__c) new SObjectBuilder(Approval__c.SObjectType)
            .setField(Approval__c.Account__c, accountInvoiceWholesale.Id)
            .setField(Approval__c.Status__c, ApprovalHelper.STATUS_APPROVED)
            .setField(Approval__c.RecordTypeId, ApprovalHelper.RT_ID_INVOICE_ON_BEHALF_REQUEST)
            .setField(Approval__c.Opportunity__c, opp.Id)
            .create()
            .getRecord();

        Triggers.switchOn();

        Opportunity opportunityRec = (Opportunity) new OpportunitySelector()
            .selectOpportunities()
            .selectFields(new List<String>{
                'Account.Id',
                'Account.Billing_ID__c',
                'Account.Partner_ID__c',
                'Account.Partner_Type__c',
                'Account.Monthly_Credit_Limit__c',
                'Account.Sign_up_purchase_limit__c',
                'Partner_Account__r.Partner_Type__c',
                'Partner_Account__r.Partner_ID__c'
            })
            .setCondition('Id = :bind0')
            .setLimit(1)
            .setQueryBindings(new List<Object>{
                opp.Id
            })
            .executeQuery()
            .get(0);

        Test.startTest();

         approvedInvoiceWholesaleValidator =
            new AccountValidator.approvedInvoiceWholesaleValidator(opportunityRec, true, partnerLog);
        resp = approvedInvoiceWholesaleValidator.validate(new Response());
        if (resp.messages.size() > 0) {
            System.debug('Error messages: ' + resp.messages);
        }
        System.assertEquals(
            0,
            resp.messages.size(),
            'approvedInvoiceWholesaleValidator should not throw an error when Invoice Bill on Behalf is  and Account is Wholesale '
        );
        Test.stopTest();
    }

    @isTest
    static void testApprovedInvoiceWholesaleValidatorAccountLimitsLessPimaryQuoteLimits() {
        Validator approvedInvoiceWholesaleValidator;
        Response resp;

        BillingHttpRequestMock testMock = new BillingHttpRequestMock();
        testMock.body = '[{"id":20392013,"name":"Monthly money amount limit","code":"MONTHLY_AMOUNT_LIMIT","value":0,"type":"Amount",' +
        '"scope":"BillingCycle","transactionType":"Any","target":"Global","targetId":null,"exclusions":[{"target":"LicenseCategoryId","targetId":"AP"}],' +
        '"override":true,"paymentType":null,"startDate":null,"limitDuration":null,"overriddenLimitId":null,"limitOverride":{"id":20393013,' +
        '"name":"Monthly money amount limit","code":"MONTHLY_AMOUNT_LIMIT","value":0,"type":"Amount","scope":"BillingCycle","transactionType":"Any",' +
        '"target":"Global","targetId":null,"exclusions":null,"override":true,"paymentType":"InvoiceWholesale","startDate":"2022-04-13T07:49Z[UTC]",' +
        '"limitDuration":{"unit":"Months","value":30},"overriddenLimitId":20392013,"limitOverride":null}}]';
        testMock.code = 200;
        testMock.status = 'Complete';
        Test.setMock(HttpCalloutMock.class, testMock);

        Triggers.switchOff();

        upsert new NGBS_Settings__c(
            BaseEndpoint__c = 'https://testapi/',
            AccountManagerPath__c = '/restapi/account-manager/v1.0',
            Login__c = '123',
            Password__c = '456'
        );

        Account accountInvoiceWholesaleEB = (Account) new SObjectBuilder(Account.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => 'Test account',
                Account.Partner_ID__c => 'anyPartnerId',
                Account.Billing_ID__c => '123456789',
                Account.Partner_Type__c => AccountHelper.ACCOUNT_PARTNER_WHOLESALE,
                Account.Monthly_Credit_Limit__c => 1200,
                Account.Sign_up_purchase_limit__c => 700
            })
            .create()
            .getRecord();

        Opportunity oppApproved = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.CloseDate => System.today(),
                Opportunity.AccountId => accountInvoiceWholesaleEB.Id,
                Opportunity.Is_Billing_Opportunity__c => true,
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL
            })
            .create()
            .getRecord();

        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.OpportunityId => oppApproved.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.isPrimary__c => true,
                Quote.PaymentMethod__c => QuoteHelper.PAYMENT_METHOD_WHOLESALE,
                Quote.Entitlement_Total_MRR__c => 1000,
                Quote.Total_MRR_New__c => 500,
                Quote.Total_One_Time__c => 1000
            })
            .create()
            .getRecord();

        Package__c pack = (Package__c) new SObjectBuilder(Package__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Package__c.Account__c => accountInvoiceWholesaleEB.Id,
                Package__c.Enterprise_Account_ID__c => accountInvoiceWholesaleEB.Id,
                Package__c.Account_Package_Id__c => accountInvoiceWholesaleEB.Billing_ID__c
            })
            .create()
            .getRecord();

        Approval__c approvalApproved = (Approval__c) new SObjectBuilder(Approval__c.SObjectType)
            .setField(Approval__c.Account__c, accountInvoiceWholesaleEB.Id)
            .setField(Approval__c.Status__c, ApprovalHelper.STATUS_APPROVED)
            .setField(Approval__c.RecordTypeId, ApprovalHelper.RT_ID_INVOICE_WHOLESALE_REQUEST)
            .create()
            .getRecord();
        Triggers.switchOn();

        Opportunity opportunityApproved = (Opportunity) new OpportunitySelector()
            .selectOpportunities()
            .selectFields(new List<String>{
                'Account.Id',
                'Account.Billing_ID__c',
                'Account.Partner_ID__c',
                'Account.Partner_Type__c',
                'Account.Monthly_Credit_Limit__c',
                'Account.Sign_up_purchase_limit__c'
            })
            .setCondition('Id = :bind0')
            .setLimit(1)
            .setQueryBindings(new List<Object>{
                oppApproved.Id
            })
            .executeQuery()
            .get(0);

        List<PartnerOperationsLog__c> partnerLog = (List<PartnerOperationsLog__c>) new SObjectBuilder(PartnerOperationsLog__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                PartnerOperationsLog__c.Opportunity__c => opportunityApproved.Id,
                PartnerOperationsLog__c.isCompleted__c => false,
                PartnerOperationsLog__c.isRejected__c => false
            })
            .quantity(1)
            .create()
            .getRecords();
            partnerLog.clear();

        Test.startTest();
        approvedInvoiceWholesaleValidator =
            new AccountValidator.approvedInvoiceWholesaleValidator(opportunityApproved, true, partnerLog);
        resp = approvedInvoiceWholesaleValidator.validate(new Response());
        if (resp.messages.size() > 1) {
            System.debug('Error messages: ' + resp.messages);
        }
        System.assertEquals(
            1,
            resp.messages.size(),
            'approvedInvoiceWholesaleValidator should throw an error when Payment method is Wholesale and the Account Limits are less than PimaryQuote Limits'
        );
        Test.stopTest();
    }

    @isTest
    static void testApprovedInvoiceWholesaleValidatorAccountLimitsGreaterPimaryQuoteLimits() {
        Validator approvedInvoiceWholesaleValidator;
        Response resp;

        BillingHttpRequestMock testMock = new BillingHttpRequestMock();
        testMock.body = '[{"id":20392013,"name":"Monthly money amount limit","code":"MONTHLY_AMOUNT_LIMIT","value":33333,"type":"Amount",' +
        '"scope":"BillingCycle","transactionType":"Any","target":"Global","targetId":null,"exclusions":[{"target":"LicenseCategoryId","targetId":"AP"}],' +
        '"override":true,"paymentType":null,"startDate":null,"limitDuration":null,"overriddenLimitId":null,"limitOverride":{"id":20393013,' +
        '"name":"Monthly money amount limit","code":"MONTHLY_AMOUNT_LIMIT","value":7370,"type":"Amount","scope":"BillingCycle","transactionType":"Any",' +
        '"target":"Global","targetId":null,"exclusions":null,"override":true,"paymentType":"InvoiceWholesale","startDate":"2022-04-13T07:49Z[UTC]",' +
        '"limitDuration":{"unit":"Months","value":30},"overriddenLimitId":20392013,"limitOverride":null}}]';
        testMock.code = 200;
        testMock.status = 'Complete';
        Test.setMock(HttpCalloutMock.class, testMock);

        Triggers.switchOff();

        upsert new NGBS_Settings__c(
            BaseEndpoint__c = 'https://testapi/',
            AccountManagerPath__c = '/restapi/account-manager/v1.0',
            Login__c = '123',
            Password__c = '456'
        );

        Account accountInvoiceWholesaleEB = (Account) new SObjectBuilder(Account.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => 'Test account',
                Account.Partner_ID__c => 'anyPartnerId',
                Account.Billing_ID__c => '123456789',
                Account.Partner_Type__c => AccountHelper.ACCOUNT_PARTNER_WHOLESALE,
                Account.Monthly_Credit_Limit__c => 2000,
                Account.Sign_up_purchase_limit__c => 1500
            })
            .create()
            .getRecord();

        Opportunity oppApproved = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.CloseDate => System.today(),
                Opportunity.AccountId => accountInvoiceWholesaleEB.Id,
                Opportunity.Is_Billing_Opportunity__c => true,
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL
            })
            .create()
            .getRecord();

        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.OpportunityId => oppApproved.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.isPrimary__c => true,
                Quote.PaymentMethod__c => QuoteHelper.PAYMENT_METHOD_WHOLESALE,
                Quote.Entitlement_Total_MRR__c => 1000,
                Quote.Total_MRR_New__c => 500,
                Quote.Total_One_Time__c => 1000
            })
            .create()
            .getRecord();

        Package__c pack = (Package__c) new SObjectBuilder(Package__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Package__c.Account__c => accountInvoiceWholesaleEB.Id,
                Package__c.Enterprise_Account_ID__c => accountInvoiceWholesaleEB.Id,
                Package__c.Account_Package_Id__c => accountInvoiceWholesaleEB.Billing_ID__c
            })
            .create()
            .getRecord();

        Approval__c approvalApproved = (Approval__c) new SObjectBuilder(Approval__c.SObjectType)
            .setField(Approval__c.Account__c, accountInvoiceWholesaleEB.Id)
            .setField(Approval__c.Status__c, ApprovalHelper.STATUS_APPROVED)
            .setField(Approval__c.RecordTypeId, ApprovalHelper.RT_ID_INVOICE_WHOLESALE_REQUEST)
            .create()
            .getRecord();
        Triggers.switchOn();

        Opportunity opportunityApproved = (Opportunity) new OpportunitySelector()
            .selectOpportunities()
            .selectFields(new List<String>{
                'Account.Id',
                'Account.Billing_ID__c',
                'Account.Partner_ID__c',
                'Account.Partner_Type__c',
                'Account.Monthly_Credit_Limit__c',
                'Account.Sign_up_purchase_limit__c'
            })
            .setCondition('Id = :bind0')
            .setLimit(1)
            .setQueryBindings(new List<Object>{
                oppApproved.Id
            })
            .executeQuery()
            .get(0);

        List<PartnerOperationsLog__c> partnerLog = (List<PartnerOperationsLog__c>) new SObjectBuilder(PartnerOperationsLog__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                PartnerOperationsLog__c.Opportunity__c => opportunityApproved.Id,
                PartnerOperationsLog__c.isCompleted__c => false,
                PartnerOperationsLog__c.isRejected__c => false
            })
            .quantity(1)
            .create()
            .getRecords();
            partnerLog.clear();

        Test.startTest();
        approvedInvoiceWholesaleValidator =
            new AccountValidator.approvedInvoiceWholesaleValidator(opportunityApproved, true, partnerLog);
        resp = approvedInvoiceWholesaleValidator.validate(new Response());
        if (resp.messages.size() > 0) {
            System.debug('Error messages: ' + resp.messages);
        }
        System.assertEquals(
            0,
            resp.messages.size(),
            'approvedInvoiceWholesaleValidator shouldn\'t throw an error when Payment method is Wholesale and the Account Limits are greater than PimaryQuote Limits'
        );
        Test.stopTest();
    }

    @isTest
    static void testApprovedInvoiceValidatorForQuote() {

        Account testAcc = (Account) new SObjectBuilder(Account.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => 'Test account',
                Account.Billing_ID__c => '123456789'
            })
            .create()
            .getRecord();

        Approval__c approval = (Approval__c) new SObjectBuilder(Approval__c.SObjectType)
            .setField(Approval__c.Account__c, testAcc.Id)
            .setField(Approval__c.Status__c, 'Pending Approval')
            .build()
            .getRecord();

        List<PartnerOperationsLog__c> partnerLog = (List<PartnerOperationsLog__c>) new SObjectBuilder(PartnerOperationsLog__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                PartnerOperationsLog__c.Account__c => testAcc.Id,
                PartnerOperationsLog__c.isCompleted__c => false,
                PartnerOperationsLog__c.isRejected__c => false
            })
            .quantity(1)
            .create()
            .getRecords();
            partnerLog.clear();

        Validator approvedInvoiceValidator;
        Response resp;

        Test.startTest();

            approvedInvoiceValidator =
                new AccountValidator.ApprovedInvoiceValidator(
                    new AccountValidator.ApprovedInvoiceValidatorParams(
                        new Opportunity(),
                        new List<Approval__c>{approval},
                        QuoteHelper.PAYMENT_METHOD_INVOICE,
                        true,
                        partnerLog,
                        false,
                        null,
                        false,
                        null
                    )
                );
            resp = approvedInvoiceValidator.validate(new Response());
            System.assertEquals(
                1,
                resp.messages.size(),
                'ApprovedInvoiceValidator should throw an error when Payment method is Invoice and there are pending Invoice approvals'
            );


            approval.Status__c = 'Approved';
            approvedInvoiceValidator =
                new AccountValidator.ApprovedInvoiceValidator(
                    new AccountValidator.ApprovedInvoiceValidatorParams(
                        new Opportunity(),
                        new List<Approval__c>{approval},
                        QuoteHelper.PAYMENT_METHOD_INVOICE,
                        true,
                        partnerLog,
                        false,
                        null,
                        false,
                        null
                    )
                );
            resp = approvedInvoiceValidator.validate(new Response());
            System.assertEquals(
                0,
                resp.messages.size(),
                'ApprovedInvoiceValidator shouldn\'t throw an error when Payment method is Invoice and there are approved Invoice approvals'
            );
        Test.stopTest();
    }

    @IsTest
    private static void testKycProcessInstanceStatusPending() {
        Account testAcc = (Account) new SObjectBuilder(Account.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => 'testAcc'
            })
            .create()
            .getRecord();
        Approval__c testApproval = (Approval__c) new SObjectBuilder(Approval__c.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Approval__c.Name => 'testApproval',
                Approval__c.Account__c => testAcc.Id,
                Approval__c.RecordTypeId => ApprovalHelper.RT_ID_KYC_APPROVAL_REQUEST
            })
            .create()
            .getRecord();
        /* KYC Approval was auto-submited */

        Test.startTest();
            Validator validator = new AccountValidator.KYCApprovalValidatorOnSignUp(new List<Approval__c>{testApproval});
            Response response = new Response();
            response = validator.validate(response);
        Test.stopTest();

        System.assertNotEquals(0, response.messages.size(),
            'Validation should be failed that\'s why error message should be appeared');
        System.assert(response.messages[0].messageDetails.contains(
            Label.KYCRequestIsNotApprovedOnSignUp),
            'To sign up the opportunity, you must remove expired promotion and select an available promo in Quote Wizard'
        );
     }

    @IsTest
    private static void testKycApprovalStatusApproved() {
        Account testAcc = (Account) new SObjectBuilder(Account.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => 'testAcc'
            })
            .create()
            .getRecord();

        List<Approval__c> testApprovals = (List<Approval__c>) new SObjectBuilder(Approval__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Approval__c.Name => 'testApproval',
                Approval__c.Account__c => testAcc.Id,
                Approval__c.RecordTypeId => ApprovalHelper.RT_ID_KYC_APPROVAL_REQUEST,
                Approval__c.Status__c => ValueProviderBuilder.provideList(new List<String>{
                    ApprovalHelper.STATUS_PENDING_APPROVAL, ApprovalHelper.STATUS_APPROVED
                }),
                Approval__c.StatusLastModifiedDate__c => ValueProviderBuilder.provideList(new List<Datetime>{
                    System.now(), System.now().addSeconds(1)
                }),
                Approval__c.DateOfSignOff__c => System.today()
            })
            .quantity(2)
            .build()
            .getRecords();

        Test.startTest();
            Validator validator = new AccountValidator.KYCApprovalValidatorOnOpportunityClose(testApprovals);
            Response response = new Response();
            response = validator.validate(response);
        Test.stopTest();

        System.assertEquals(0, response.messages.size(),
            'Validation should be passed that\'s why error message shouldn\'t be appeared');
    }

    @isTest
    static void testMasterAccountValidatorMasterNotSpecifiedForIndiaOffice() {

        Account childAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => ValueProviderBuilder.provideList(new List<String>{
                        'Child Account'
                    })
                }
            )
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.RecordTypeId => OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY,
                    Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL_EU,
                    Opportunity.AccountId => childAccount.Id,
                    Opportunity.Tier_Name__c => OpportunityHelper.TIER_OFFICE,
                    Opportunity.CurrencyIsoCode => OpportunityHelper.CURRENCY_NAME_INR
                }
            )
            .create()
            .getRecord();

        Test.startTest();

        Validator masterAccountValidator =
            new AccountValidator.MasterAccountValidator(
                opp,
                null,
                null,
                null
            );
        Response resp = masterAccountValidator.validate(new Response());
        Test.stopTest();

        System.assertEquals(1, resp.messages.size(), 'India Office Opportunity must have linked Master Account. Validation should not be passed');
        System.assert(resp.messages[0].messageDetails.contains(
            Label.MasterAccountIsNotBindOnOpportunityClose),
            'Master Account wasn\'t bound. Master Account should be linked'
        );
    }

    @IsTest
    static void testMasterAccountActiveAgreementValidator() {
        Account acc = (Account) new SObjectBuilder(Account.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => 'Test account'
            })
            .build()
            .getRecord();

        Test.startTest();
            Validator masterAccountActiveAgreementValidator =
                new AccountValidator.MasterAccountActiveAgreementValidator(acc, true);
            Response resp = masterAccountActiveAgreementValidator.validate(new Response());
        Test.stopTest();

        System.assertNotEquals(0, resp.messages.size());
        System.assert(resp.messages[0].messageDetails.contains(
            Label.Bound_Account_Active_agreement_status_help_text),
            'Wrong message abount Linked Bound Account should have an Active Agreement should be fired'
        );
    }

    @IsTest
    static void testBoundPartnerAccountsPassedValidation() {
        final String partnerType = AccountHelper.ACCOUNT_ENGAGE_STANDALONE_PARTNER_TYPES.get(0);
        final String partnerId = '12345';
        Account masterAcc = (Account) new SObjectBuilder(Account.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => 'Test Master Account',
                Account.Partner_Type__c => partnerType,
                Account.Partner_ID__c => partnerId
            })
            .build()
            .getRecord();
        Account childAcc = (Account) new SObjectBuilder(Account.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => 'Test Master Account',
                Account.Partner_Type__c => partnerType,
                Account.Partner_ID__c => partnerId,
                Account.Master_Account__c => masterAcc.Id
            })
            .build()
            .getRecord();

        Test.startTest();
            Response resp = new Response();
            resp = new HelperUtils.BaseValidator(new List<Validator>{
                new AccountValidator.BoundPartnerAccountsValidator(new List<Account>{masterAcc, childAcc})
            }).validate(resp);
        Test.stopTest();

        System.assert(resp.messages.isEmpty(), 'Validation should be passed');
    }

    @IsTest
    static void testBoundPartnerAccountsValidation() {
        final String partnerId = '12345';
        Account masterAcc = (Account) new SObjectBuilder(Account.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => 'Test Master Account',
                Account.Partner_Type__c => AccountHelper.ACCOUNT_ENGAGE_STANDALONE_PARTNER_TYPES.get(0),
                Account.Partner_ID__c => partnerId
            })
            .build()
            .getRecord();
        Account childAcc = (Account) new SObjectBuilder(Account.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => 'Test Master Account',
                Account.Partner_Type__c => AccountHelper.ACCOUNT_ENGAGE_STANDALONE_PARTNER_TYPES.get(1),
                Account.Partner_ID__c => partnerId,
                Account.Master_Account__c => masterAcc.Id
            })
            .build()
            .getRecord();

        Test.startTest();
            Response resp = new Response();
            resp = new HelperUtils.BaseValidator(new List<Validator>{
                new AccountValidator.BoundPartnerAccountsValidator(new List<Account>{masterAcc, childAcc})
            }).validate(resp);
        Test.stopTest();

        System.assert(!resp.messages.isEmpty(), 'Validation should be failed and error message appear');
        System.assert(resp.messages[0].messageDetails.contains(Label.SignUp_BoundPartnerAccountsMismatch),
            'Error message should be like \'At least one bound account has a different partner type or id\'');
    }

    @IsTest
    static void testOfficeMasterAccountValidator() {
        List<Account> accounts = (List<Account>) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => ValueProviderBuilder.provideList(new List<String>{
                        'Master Account', 'Child Account'
                    })
                }
            )
            .quantity(2)
            .create()
            .getRecords();

        Account masterAccount = accounts[0];
        Account childAccount = accounts[1];

        /* Opportunity need to be determined if account is InContact */
        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.RecordTypeId => OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY,
                    Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL,
                    Opportunity.AccountId => childAccount.Id,
                    Opportunity.Tier_Name__c => OpportunityHelper.TIER_RC_CONTACT_CENTER
                }
            )
            .create()
            .getRecord();

        BillingWrappers.NGBSAccountPackage ngbsAccountPackage = new BillingWrappers.NGBSAccountPackage();
        ngbsAccountPackage.product = 'Office';
        BillingWrappers.NGBSAccount ngbsAccount = new BillingWrappers.NGBSAccount();
        ngbsAccount.packages = new List<BillingWrappers.NGBSAccountPackage>{ngbsAccountPackage};

        Test.startTest();
            Response respFailedValidation =
                new AccountValidator.OfficeMasterAccountValidator(opp, masterAccount).validate(new Response());
            Response respOfficeInNGBS =
                new AccountValidator.OfficeMasterAccountValidator(opp, masterAccount, ngbsAccount, true)
                    .validate(new Response());
        Test.stopTest();

        System.assertNotEquals(0, respFailedValidation.messages.size());
        System.assert(respFailedValidation.messages[0].messageDetails.contains(
                Label.Opportunity_Error_OnClose_Linked_Bound_Account_Office_help_text),
                'Wrong message about Linked Bound Account should be RingCentral MVP should be fired'
        );

        System.assertEquals(0, respOfficeInNGBS.messages.size(),
            'NGBS accounts with Office product should pass validation');
    }

    @IsTest
    static void testMasterAccountContractValidator() {
        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.RecordTypeId => OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY,
                    Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL,
                    Opportunity.Tier_Name__c => OpportunityHelper.TIER_RC_CONTACT_CENTER
                }
            )
            .create()
            .getRecord();

        Quote testQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.Name => 'Test',
                    Quote.OpportunityId => opp.Id,
                    Quote.Package_Info__c => NGBSTestDataGenerator.generateQuotePackageInfo()
                }
            )
            .create()
            .getRecord();

        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => 'Test',
                Account.Active_Sales_Agreement__c => testQuote.Id
            })
            .create()
            .getRecord();

        Account acc = (Account) new AccountSelector()
            .selectAccountForOpportunityClose(new List<Object>{new Set<Id> {testAccount.Id}})
            .executeQuery()
            .get(0);

        Test.startTest();
            Validator masterAccountContractValidator =
                new AccountValidator.MasterAccountContractValidator(opp, acc);
            Response resp = masterAccountContractValidator.validate(new Response());
        Test.stopTest();

        System.assertNotEquals(0, resp.messages.size());
        System.assert(resp.messages[0].messageDetails.contains(
                Label.Opportunity_Error_OnClose_Linked_Bound_Account_Contract_help_text),
                'Wrong message about Linked Bound Account should be with Contract should be fired'
        );
    }
}