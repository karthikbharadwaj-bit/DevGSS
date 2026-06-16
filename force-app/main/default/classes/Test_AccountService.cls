@isTest
public class Test_AccountService {
    @TestSetup
    static void prepareData() {
        new SObjectBuilder(Account.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Account.SObjectType))
            .create();

        new SObjectBuilder(RC_Quote_Template__c.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                RC_Quote_Template__c.Name => 'Second Template',
                RC_Quote_Template__c.ObjectName__c => 'Account',
                RC_Quote_Template__c.Available_For_Billing_Countries__c => 'France',
                RC_Quote_Template__c.Sorting_Order__c => 2,
                RC_Quote_Template__c.Brand__c => RingCentralHelper.BRAND_RINGCENTRAL_EU
            })
            .create();

        new SObjectBuilder(RC_Quote_Template__c.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                RC_Quote_Template__c.Name => 'First Template',
                RC_Quote_Template__c.ObjectName__c => 'Account',
                RC_Quote_Template__c.Available_For_Billing_Countries__c => 'France',
                RC_Quote_Template__c.Sorting_Order__c => 1,
                RC_Quote_Template__c.Brand__c => RingCentralHelper.BRAND_RINGCENTRAL
            })
            .create();
    }

    @isTest
    static void testGetTemplatesForEuAccount() {
        BillingWrappers.Params params = new BillingWrappers.Params();
        params.action = 'templatesForAccount';
        params.data = new Map<String, String> {
            'billingCountry' => 'France',
            'brand' => RingCentralHelper.BRAND_RINGCENTRAL_EU
        };

        RestRequest request = new RestRequest();
        request.requestBody = Blob.valueOf(JSON.serialize(params));
        RestContext.request = request;

        AccountService.handleRequest();

        String body = RestContext.response.responseBody.toString();

        List<RC_Quote_Template__c> templatesForAcc = new RCQuoteTemplateSelector()
            .selectNdaTemplatesByBillingCountry(new List<Object> {'France'})
            .executeQuery();

        Response resp = new Response();
        resp.setData('templates', templatesForAcc);

        System.assertEquals(JSON.serialize(resp), body, 'Wrong templates retrieved');
    }

    @isTest
    static void testGetTemplatesForNonEuAccount() {
        BillingWrappers.Params params = new BillingWrappers.Params();
        params.action = 'templatesForAccount';
        params.data = new Map<String, String> {
            'billingCountry' => 'France',
            'brand' => RingCentralHelper.BRAND_RINGCENTRAL
        };

        RestRequest request = new RestRequest();
        request.requestBody = Blob.valueOf(JSON.serialize(params));
        RestContext.request = request;

        AccountService.handleRequest();

        String body = RestContext.response.responseBody.toString();

        List<RC_Quote_Template__c> templatesForAcc = new RCQuoteTemplateSelector()
            .selectNdaTemplatesByBrand(new List<Object> {RingCentralHelper.BRAND_RINGCENTRAL})
            .executeQuery();

        Response resp = new Response();
        resp.setData('templates', templatesForAcc);

        System.assertEquals(JSON.serialize(resp), body, 'Wrong templates retrieved');
    }

    @isTest
    static void testAttachPdfForAccount() {
        RC_Quote_Template__c template = (RC_Quote_Template__c) new RCQuoteTemplateSelector()
            .selectRCQuoteTemplates()
            .executeQuery()
            .get(0);

        Account acc = (Account) new AccountSelector()
            .selectAccounts()
            .executeQuery()
            .get(0);

        BillingWrappers.Params params = new BillingWrappers.Params();
        params.action = 'attachPdf';
        params.data = new Map<String, String>{'accountId' => acc.Id, 'templateId' => template.Id};

        RestRequest request = new RestRequest();
        request.requestBody = Blob.valueOf(JSON.serialize(params));
        RestContext.request = request;

        AccountService.handleRequest();

        String body = RestContext.response.responseBody.toString();

        List<Attachment> attachment = (List<Attachment>) new AttachmentSelector()
            .selectAttachmentsByParentId(new List<Object>{acc.Id})
            .executeQuery();

        System.assertEquals(attachment.size(), 1, 'One attachment should be attached to Account');
    }

     @isTest
    static void testGetAccountsOnAccountViewer() {
       Account testChildAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .create()
            .getRecord();

        AccountService.RequestParams params = new AccountService.RequestParams();
        params.action = 'getAccountsOnAccountViewer';
        params.accountIds = new List<Id>{testChildAccount.Id};

        RestRequest request = new RestRequest();
        request.requestBody = Blob.valueOf(JSON.serialize(params));
        RestContext.request = request;

        Test.startTest();
            AccountService.handleRequest();
        Test.stopTest();

        String body = RestContext.response.responseBody.toString();
        Map<String, Object> parsedBody = (Map<String, Object>) JSON.deserializeUntyped(body);

        Map<String, Object> data = (Map<String, Object>) parsedBody.get('data');
        List<Object> accountList = (List<Object>) data.get('salesforceAccounts');

        System.assertEquals(1, accountList.size(), 'Account should be queried and returned');
    }

    @isTest
    static void testGetAccountNature() {
        Account testChildAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .create()
            .getRecord();

        AccountService.RequestParams params = new AccountService.RequestParams();
            params.action = 'getAccountNature';
            params.accountIdSet = new Set<Id>{testChildAccount.Id};

        RestRequest request = new RestRequest();
            request.requestBody = Blob.valueOf(JSON.serialize(params));
        RestContext.request = request;

        Test.startTest();
            AccountService.handleRequest();
        Test.stopTest();
        String body = RestContext.response.responseBody.toString();
        Map<String, Object> parsedBody = (Map<String, Object>) JSON.deserializeUntyped(body);
        System.assert(parsedBody.containsKey('data'), 'data parameter is expected');

        Map<String, Object> data = (Map<String, Object>) parsedBody.get('data');
        System.assert(data.containsKey('isChildAccount'), 'isChildAccount parameter is expected');
        System.assertEquals(true, data.get('isChildAccount'), 'Account should be treated as child');
    }

    @isTest
    static void testGetChildById() {
        Account testChildAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .create()
            .getRecord();

        List<Contact> contactList = (List<Contact>) new SObjectBuilder(Contact.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Contact.SObjectType))
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.AccountId => ValueProviderBuilder.provideList(new List<Id>{
                        testChildAccount.Id, testChildAccount.Id
                    })
                }
            )
            .quantity(2)
            .create()
            .getRecords();

        List<AccountContactRole> contactRoles = (List<AccountContactRole>) new SObjectBuilder(AccountContactRole.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    AccountContactRole.AccountId => testChildAccount.Id,
                    AccountContactRole.ContactId => ValueProviderBuilder.provideList(new List<Id>{
                        contactList[0].Id, contactList[1].Id
                    }),
                    AccountContactRole.Role => AccountContactRoleHelper.CONTACT_ROLE_SIGNATORY,
                    AccountContactRole.IsPrimary => ValueProviderBuilder.provideList(new List<Boolean>{
                        true, false
                    })
                }
            )
            .quantity(2)
            .create()
            .getRecords();

        AccountService.ContactParams roleContact = new AccountService.ContactParams();
        roleContact.contactId = contactList[0].Id;

        AccountService.SoqlParams soqlParams = new AccountService.SoqlParams();
        soqlParams.queryMethod = 'childById';
        soqlParams.roleContact = roleContact;

        AccountService.RequestParams params = new AccountService.RequestParams();
        params.action = 'getAccountData';
        params.accountIdSet = new Set<Id>{testChildAccount.Id};
        params.soqlParams = soqlParams;

        RestRequest request = new RestRequest();
        request.requestBody = Blob.valueOf(JSON.serialize(params));
        RestContext.request = request;

        Test.startTest();
            AccountService.handleRequest();
        Test.stopTest();
        String body = RestContext.response.responseBody.toString();
        Map<String, Object> parsedBody = (Map<String, Object>) JSON.deserializeUntyped(body);
        System.assert(parsedBody.containsKey('data'), 'data parameter is expected');

        Map<String, Object> data = (Map<String, Object>) parsedBody.get('data');
        System.assert(data.containsKey('accData'), 'accData parameter is expected');

        List<Object> accountList = (List<Object>) data.get('accData');
        System.assertEquals(1, accountList.size(), 'Child account should be queried and returned');
    }

    @isTest
    static void testGetChildByMasterId() {
        Account testMasterAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .create()
            .getRecord();
        /* As child account has no contact roles yet - account trigger validation will always fail insert dml */
        Triggers.switchOff();
        Account testChildAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Master_Account__c, testMasterAccount.Id)
            .create()
            .getRecord();
        Triggers.switchOn();

        List<Contact> contactList = (List<Contact>) new SObjectBuilder(Contact.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Contact.SObjectType))
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.AccountId => ValueProviderBuilder.provideList(new List<Id>{
                        testChildAccount.Id, testChildAccount.Id
                    })
                }
            )
            .quantity(2)
            .create()
            .getRecords();

        List<AccountContactRole> contactRoles = (List<AccountContactRole>) new SObjectBuilder(AccountContactRole.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    AccountContactRole.AccountId => testChildAccount.Id,
                    AccountContactRole.ContactId => ValueProviderBuilder.provideList(new List<Id>{
                        contactList[0].Id, contactList[1].Id
                    }),
                    AccountContactRole.Role => AccountContactRoleHelper.CONTACT_ROLE_SIGNATORY,
                    AccountContactRole.IsPrimary => ValueProviderBuilder.provideList(new List<Boolean>{
                        true, false
                    })
                }
            )
            .quantity(2)
            .create()
            .getRecords();

        AccountService.SoqlParams soqlParams = new AccountService.SoqlParams();
        soqlParams.queryMethod = 'childByMasterId';

        AccountService.RequestParams params = new AccountService.RequestParams();
        params.action = 'getAccountData';
        params.accountIdSet = new Set<Id>{testMasterAccount.Id};
        params.soqlParams = soqlParams;

        RestRequest request = new RestRequest();
        request.requestBody = Blob.valueOf(JSON.serialize(params));
        RestContext.request = request;

        Test.startTest();
            AccountService.handleRequest();
        Test.stopTest();

        String body = RestContext.response.responseBody.toString();
        Map<String, Object> parsedBody = (Map<String, Object>) JSON.deserializeUntyped(body);
        System.assert(parsedBody.containsKey('data'), 'data parameter is expected');

        Map<String, Object> data = (Map<String, Object>) parsedBody.get('data');
        System.assert(data.containsKey('accData'), 'accData parameter is expected');

        List<Object> accountList = (List<Object>) data.get('accData');
        System.assertEquals(1, accountList.size(), 'Child account should be queried and returned');
    }

    @isTest
    static void testGetMasterByIdWOPermission() {
        Account testMasterAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .create()
            .getRecord();

        List<Contact> contactList = (List<Contact>) new SObjectBuilder(Contact.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Contact.SObjectType))
            .setField(Contact.AccountId, testMasterAccount.Id)
            .quantity(2)
            .create()
            .getRecords();

        List<AccountContactRole> contactRoles = (List<AccountContactRole>) new SObjectBuilder(AccountContactRole.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    AccountContactRole.AccountId => testMasterAccount.Id,
                    AccountContactRole.ContactId => ValueProviderBuilder.provideList(new List<Id>{
                        contactList[0].Id, contactList[1].Id
                    }),
                    AccountContactRole.Role => AccountContactRoleHelper.CONTACT_ROLE_SIGNATORY,
                    AccountContactRole.IsPrimary => ValueProviderBuilder.provideList(new List<Boolean>{
                        true, false
                    })
                }
            )
            .quantity(2)
            .create()
            .getRecords();

        AccountService.ContactParams relationContact = new AccountService.ContactParams();
        AccountService.ContactParams roleContact = new AccountService.ContactParams();
        roleContact.contactId = contactList[0].Id;

        AccountService.SoqlParams soqlParams = new AccountService.SoqlParams();
        soqlParams.queryMethod = 'masterById';
        soqlParams.roleContact = roleContact;
        soqlParams.relationContact = relationContact;

        AccountService.RequestParams params = new AccountService.RequestParams();
        params.action = 'getAccountData';
        params.accountIdSet = new Set<Id>{testMasterAccount.Id};
        params.soqlParams = soqlParams;

        RestRequest request = new RestRequest();
        request.requestBody = Blob.valueOf(JSON.serialize(params));
        RestContext.request = request;

        Test.startTest();
            AccountService.handleRequest();
        Test.stopTest();

        String body = RestContext.response.responseBody.toString();
        Map<String, Object> parsedBody = (Map<String, Object>) JSON.deserializeUntyped(body);
        System.assert(parsedBody.containsKey('data'), 'data parameter is expected');

        Map<String, Object> data = (Map<String, Object>) parsedBody.get('data');
        System.assert(data.containsKey('accData'), 'accData parameter is expected');

        List<Object> accountList = (List<Object>) data.get('accData');
        System.assertEquals(1, accountList.size(), 'Master account should be queried and returned');
    }

    @isTest
    static void testGetMasterByIdWPermission() {
        User testUser = (User) new SObjectBuilder(User.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    User.FirstName => new ValueProvider.UniqueStringProvider('firstName'),
                    User.Email => new ValueProvider.UniqueStringProvider('test@gmail.ru'),
                    User.Username => new ValueProvider.UniqueStringProvider('test@gmail.ru'),
                    User.CommunityNickname => new ValueProvider.UniqueStringProvider('test@gmail.ru'),
                    User.LanguageLocaleKey => 'en_US',
                    User.ProfileId => ProfileHelper.PROFILE_ID_SYSADMIN
                }
            )
            .create()
            .getRecord();

        PermissionSet ps = (PermissionSet) new SObjectBuilder(PermissionSet.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    PermissionSet.Name => 'CustomPermissionEnabled',
                    PermissionSet.Label => 'Custom Permisison Enabled'
                }
            )
            .create()
            .getRecord();

        CustomPermission cp = (CustomPermission) new CustomPermissionSelector()
            .selectCustomPermissionsByDeveloperName(new List<Object> {CustomPermissionHelper.PERMISSION_EXPANDED_ENGAGE_BINDING})
            .executeQuery()
            .get(0);

        new SObjectBuilder(SetupEntityAccess.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    SetupEntityAccess.ParentId => ps.Id,
                    SetupEntityAccess.SetupEntityId => cp.Id
                }
            )
            .create();

        new SObjectBuilder(PermissionSetAssignment.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    PermissionSetAssignment.AssigneeId => testUser.Id,
                    PermissionSetAssignment.PermissionSetId => ps.Id
                }
            )
            .create();

        Test.startTest();
            System.runAs(testUser) {
                Account testMasterAccount = (Account) new SObjectBuilder(Account.SObjectType)
                    .create()
                    .getRecord();

                List<Contact> contactList = (List<Contact>) new SObjectBuilder(Contact.SObjectType)
                    .setFields(SObjectFactoryFieldDefaults.getDefaults(Contact.SObjectType))
                    .setField(Contact.AccountId, testMasterAccount.Id)
                    .quantity(2)
                    .create()
                    .getRecords();

                List<AccountContactRole> contactRoles = (List<AccountContactRole>) new SObjectBuilder(AccountContactRole.SObjectType)
                    .setFields(
                        new Map<SObjectField, Object>{
                            AccountContactRole.AccountId => testMasterAccount.Id,
                            AccountContactRole.ContactId => ValueProviderBuilder.provideList(new List<Id>{
                                contactList[0].Id, contactList[1].Id
                            }),
                            AccountContactRole.Role => AccountContactRoleHelper.CONTACT_ROLE_SIGNATORY,
                            AccountContactRole.IsPrimary => ValueProviderBuilder.provideList(new List<Boolean>{
                                true, false
                            })
                        }
                    )
                    .quantity(2)
                    .create()
                    .getRecords();

                AccountService.ContactParams relationContact = new AccountService.ContactParams();
                AccountService.ContactParams roleContact = new AccountService.ContactParams();
                roleContact.contactId = contactList[0].Id;

                AccountService.SoqlParams soqlParams = new AccountService.SoqlParams();
                soqlParams.queryMethod = 'masterById';
                soqlParams.roleContact = roleContact;
                soqlParams.relationContact = relationContact;

                AccountService.RequestParams params = new AccountService.RequestParams();
                params.action = 'getAccountData';
                params.accountIdSet = new Set<Id>{testMasterAccount.Id};
                params.soqlParams = soqlParams;

                RestRequest request = new RestRequest();
                request.requestBody = Blob.valueOf(JSON.serialize(params));
                RestContext.request = request;

                AccountService.handleRequest();
            }
        Test.stopTest();

        String body = RestContext.response.responseBody.toString();
        Map<String, Object> parsedBody = (Map<String, Object>) JSON.deserializeUntyped(body);
        System.assert(parsedBody.containsKey('data'), 'data parameter is expected');

        Map<String, Object> data = (Map<String, Object>) parsedBody.get('data');
        System.assert(data.containsKey('accData'), 'accData parameter is expected');

        List<Object> accountList = (List<Object>) data.get('accData');
        System.assertEquals(1, accountList.size(), 'Master account should be queried and returned');
    }

    @isTest
    static void testLinkData() {
        Triggers.switchOff();
        List<Account> testAccounts = (List<Account>) new SObjectBuilder(Account.SObjectType)
            .quantity(2)
            .create()
            .getRecords();

        Contact testContact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Contact.SObjectType))
            .setField(Contact.AccountId, testAccounts[0].Id)
            .quantity(1)
            .create()
            .getRecord();

        List<AccountContactRole> contactRoles = (List<AccountContactRole>) new SObjectBuilder(AccountContactRole.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    AccountContactRole.AccountId => ValueProviderBuilder.provideList(new List<Id>{
                        testAccounts[0].Id, testAccounts[1].Id
                    }),
                    AccountContactRole.ContactId => testContact.Id,
                    AccountContactRole.Role => AccountContactRoleHelper.CONTACT_ROLE_SIGNATORY,
                    AccountContactRole.IsPrimary => true
                }
            )
            .quantity(2)
            .create()
            .getRecords();

        List<Opportunity> testOptys = (List<Opportunity>) new SOBjectBuilder(Opportunity.sObjectType)
            .quantity(2)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.AccountId => testAccounts[0].Id,
                Opportunity.Name => 'New Business Oppty',
                Opportunity.Type => 'New Business',
                Opportunity.Is_Billing_Opportunity__c => true,
                Opportunity.CloseDate => ValueProviderBuilder.provideUniqueDate(),
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY
            })
            .create()
            .getRecords();

        List<Quote> testQuotes = (List<Quote>) new SObjectBuilder(Quote.sObjectType)
            .quantity(2)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.Name => new ValueProvider.UniqueStringProvider('quoteName'),
                    Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                    Quote.Upsell_Status__c => QuoteHelper.STATUS_NEW_CUSTOMER,
                    Quote.PriceBook2Id => Test.getStandardPricebookId(),
                    Quote.OpportunityId => ValueProviderBuilder.provideList(new List<Id>{
                        testOptys[0].Id, testOptys[1].Id
                    })
                }
            )
            .create()
            .getRecords();
        Triggers.switchOn();

        BillingWrappers.QuoteWrapper qWrapper = new BillingWrappers.QuoteWrapper();
            qWrapper.id = testQuotes[0].Id;
            qWrapper.parentQuoteId = testQuotes[1].Id;
            qWrapper.initialTerm = '12';
            qWrapper.renewalTerm = '12';
            qWrapper.autoRenewal = true;
            qWrapper.startDate = '2000-11-11';
            qWrapper.endDate = '2020-11-11';

        AccountService.RequestParams params = new AccountService.RequestParams();
            params.action = 'linkData';
            params.accountAssignments = new Map<String,String>{testAccounts[0].Id => testAccounts[1].Id};
            params.quoteWrapperList = new List<BillingWrappers.QuoteWrapper>{qWrapper};
            params.opportunityId = testOptys[0].Id;


        RestRequest request = new RestRequest();
        request.requestBody = Blob.valueOf(JSON.serialize(params));
        RestContext.request = request;

        Test.startTest();
            AccountService.handleRequest();
            String body = RestContext.response.responseBody.toString();
        Test.stopTest();

        Map<String, Object> parsedBody = (Map<String, Object>) JSON.deserializeUntyped(body);
        System.assert(parsedBody.containsKey('data'), 'data parameter is expected');

        Map<String, Object> data = (Map<String, Object>) parsedBody.get('data');
        System.assert(data.containsKey('reselectedQuotes'), 'reselectedQuotes parameter is expected');

        List<Object> reselectedQuotes = (List<Object>) data.get('reselectedQuotes');
        System.assertEquals(1, reselectedQuotes.size(), 'quote should reselected');

        Quote updatedQuote = (Quote) new QuoteSelector()
            .selectQuoteById(new List<Id>{ testQuotes[0].Id })
            .selectFields( new List<String>{
                'Id',
                'ParentQuote__c',
                'Initial_Term_months__c',
                'Term_months__c',
                'Auto_Renewal__c',
                'End_Date__c',
                'Start_Date__c'
            })
            .executeQuery()
            .get(0);

        System.assertEquals(testQuotes[1].Id, updatedQuote.ParentQuote__c, 'Wrong parentQuote is provided');
        System.assertEquals('12', updatedQuote.Initial_Term_months__c, 'Wrong initial term is provided');
        System.assertEquals('12', updatedQuote.Term_months__c, 'Wrong renewal term is provided');
        System.assertEquals(true, updatedQuote.Auto_Renewal__c, 'Wrong autorenewal term is provided');
        System.assertEquals(Date.valueOf('2020-11-11'), updatedQuote.End_Date__c, 'Wrong end date term is provided');
        System.assertEquals(Date.valueOf('2000-11-11'), updatedQuote.Start_Date__c, 'Wrong start date is provided');

        Account reselectedAcc = (Account) new AccountSelector()
            .selectAccountById(testAccounts[0].Id)
            .selectFields(new List<String>{'Master_Account__c'})
            .executeQuery()
            .get(0);
        System.assertEquals(testAccounts[1].Id, reselectedAcc.Master_Account__c, 'Wrong master account is provided');
    }

    @IsTest
    public static void testConvertToEla() {
        Test.startTest();
        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .create()
            .getRecord();

        Contact testContact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Contact.SObjectType))
            .setField(Contact.AccountId, testAccount.Id)
            .create()
            .getRecord();

        AccountService.RequestParams params = new AccountService.RequestParams();
        params.action = AccountService.CONVERT_ACCOUNT_TO_ELA;
        params.accountIds = new List<Id>{testAccount.Id};
        params.numberOfAccounts = 1;
        params.accountName = 'Test Ela Service';
        params.contactId = testContact.Id;

        RestRequest request = new RestRequest();
        request.requestBody = Blob.valueOf(JSON.serialize(params));
        RestContext.request = request;

        AccountService.handleRequest();

        System.assertEquals(
            1, [SELECT Id FROM Account WHERE ELA_Account_Type__c =: AccountHelper.ACCOUNT_TYPE_ELA_BILLING].size(),
            'Account was not converted to billing'
        );

        System.assertEquals(
            1, [SELECT Id FROM Account WHERE ELA_Account_Type__c =: AccountHelper.ACCOUNT_TYPE_ELA_SERVICE].size(),
            'Service account was not created'
        );
        Test.stopTest();
    }

    @IsTest
    public static void testBuildAttParentsMap() {
        Triggers.switchOff();
        List<Account> accountList = (List<Account>) new SObjectBuilder(Account.sObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Account.SObjectType))
            .quantity(4)
            .create()
            .getRecords();

        Account childIndiaAccountOne = accountList[0];
        Account childIndiaAccountTwo = accountList[1];
        Account parentAccountOne = accountList[2];
        Account parentAccountTwo = accountList[3];

        new SObjectBuilder(Approval__c.SObjectType)
            .quantity(2)
            .setFields(
                new Map<SObjectField, Object>{
                    Approval__c.Name => ValueProviderBuilder.provideUniqueString(),
                    Approval__c.Account__c => ValueProviderBuilder.provideList(new List<Id>{
                        childIndiaAccountOne.Id,
                        childIndiaAccountTwo.Id
                    }),
                    Approval__c.RecordTypeId => ApprovalHelper.RT_ID_KYC_APPROVAL_REQUEST
                }
            )
            .create();

        List<Contract> contractList = (List<Contract>) new SObjectBuilder(Contract.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contract.Name => ValueProviderBuilder.provideUniqueString(),
                    Contract.AccountId => ValueProviderBuilder.provideList(new List<Id>{
                        parentAccountOne.Id,
                        parentAccountOne.Id,
                        parentAccountTwo.Id,
                        parentAccountTwo.Id
                    }),
                    Contract.Original_Signed_Date__c => ValueProviderBuilder.provideList(new List<Datetime>{
                        null,
                        System.now(),
                        null,
                        System.now()
                    })
                }
            )
            .quantity(4)
            .create()
            .getRecords();
        /* Contracts can't be inserted in Active status */
        for (Contract c : contractList) {
            c.Status = DocuSignHelper.CONTRACT_STATUS_ACTIVE;
        }
        update contractList;
        Triggers.switchOn();

        Test.startTest();
            Map<Id, Contract> parentMap = AccountService.buildAttParentsMap(new Map<String, String>{
                childIndiaAccountOne.Id => parentAccountOne.Id,
                childIndiaAccountTwo.Id => parentAccountTwo.Id
            });
        Test.stopTest();
        System.assert(!parentMap.isEmpty(), 'Active Contracts with original signed Of date should be found');
        System.assert(parentMap.get(contractList[1].Id) != null, 'Contract with Original signed date should be found');
        System.assert(parentMap.get(contractList[3].Id) != null, 'Contract with Original signed date should be found');
    }

    @IsTest
    public static void testGetAtts() {
        List<Account> accountList = (List<Account>) new SObjectBuilder(Account.sObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Account.SObjectType))
            .quantity(4)
            .create()
            .getRecords();

        Account childIndiaAccountOne = accountList[0];
        Account childIndiaAccountTwo = accountList[1];
        Account parentAccountOne = accountList[2];
        Account parentAccountTwo = accountList[3];

        List<Contract> contractList = (List<Contract>) new SObjectBuilder(Contract.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contract.Name => ValueProviderBuilder.provideUniqueString(),
                    Contract.AccountId => ValueProviderBuilder.provideList(new List<Id>{
                        parentAccountOne.Id,
                        parentAccountTwo.Id
                    })
                }
            )
            .quantity(2)
            .create()
            .getRecords();

        List<Attachment> attachmentList = (List<Attachment>) new SObjectBuilder(Attachment.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Attachment.Name => ValueProviderBuilder.provideList(new List<String>{
                        'testMSAtest',
                        'wrong attachment name 1',
                        'testMaster Service Agreementtest',
                        'wrong attachment name 2',
                        'MSAchildIndiaAccountOne Attachment',
                        'childIndiaAccountOne Attachment Master Service Agreement'
                    }),
                    Attachment.ParentId => ValueProviderBuilder.provideList(new List<Id>{
                        contractList[0].Id,
                        contractList[0].Id,
                        contractList[1].Id,
                        contractList[1].Id,
                        childIndiaAccountOne.Id,
                        childIndiaAccountTwo.Id
                    }),
                    Attachment.Body => Blob.valueOf('test body')
                }
            )
            .quantity(6)
            .create()
            .getRecords();

        Set<String> childAccStringIdSet = new Set<String>((List<String>)new List<Id>{childIndiaAccountOne.Id, childIndiaAccountTwo.Id});

        Test.startTest();
            Map<String, List<Attachment>> attMap = AccountService.getAtts(
                new Map<Id, Contract>{
                    contractList[0].Id => contractList[0],
                    contractList[1].Id => contractList[1]
                },
                childAccStringIdSet
            );
        Test.stopTest();
        System.assert(!attMap.get('parentMsa').isEmpty(), 'Parent msa attachments should be found');
        System.assert(
            attMap.get('parentMsa').size() == 2,
            'both "MSA" like and "Master Service Agreement" like attachments should be found'
        );
        System.assert(!attMap.get('childMsa').isEmpty(), 'Attachments from child accounts should be found');
        System.assert(attMap.get('childMsa').size() == 2, 'All attachments from child accounts should be found');
    }

    @IsTest
    public static void testBuildParentAccIdToAttMap() {
        List<Account> accountList = (List<Account>) new SObjectBuilder(Account.sObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Account.SObjectType))
            .quantity(2)
            .create()
            .getRecords();

        List<Contract> contractList = (List<Contract>) new SObjectBuilder(Contract.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contract.Name => ValueProviderBuilder.provideUniqueString(),
                    Contract.AccountId => ValueProviderBuilder.provideList(new List<Id>{
                        accountList[0].Id,
                        accountList[1].Id
                    })
                }
            )
            .quantity(2)
            .create()
            .getRecords();

        List<Attachment> attachmentList = (List<Attachment>) new SObjectBuilder(Attachment.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Attachment.Name => ValueProviderBuilder.provideList(new List<String>{
                        'attachOne',
                        'attachTwo'
                    }),
                    Attachment.ParentId => ValueProviderBuilder.provideList(new List<Id>{
                        contractList[0].Id,
                        contractList[1].Id
                    }),
                    Attachment.Body => Blob.valueOf('test body')
                }
            )
            .quantity(2)
            .create()
            .getRecords();

        Test.startTest();
            Map<Id, Attachment> parentAccIdToAttMap = AccountService.buildParentAccIdToAttMap(
                attachmentList,
                new Map<Id, Contract>{
                    contractList[0].Id => contractList[0],
                    contractList[1].Id => contractList[1]
                });
        Test.stopTest();
        System.assert(parentAccIdToAttMap.get(accountList[0].Id) != null, 'Account misses attachment');
        System.assert(parentAccIdToAttMap.get(accountList[0].Id).Name == 'attachOne', 'Wrong');
        System.assert(parentAccIdToAttMap.get(accountList[1].Id) != null, 'Account misses attachment');
        System.assert(parentAccIdToAttMap.get(accountList[1].Id).Name == 'attachTwo', 'Account misses attachment');
    }

    @IsTest
    public static void testBuildAttachmentsToInsert() {
        List<Attachment> attachmentList = (List<Attachment>) new SObjectBuilder(Attachment.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Attachment.Name => ValueProviderBuilder.provideList(new List<String>{
                        'attachOne',
                        'attachTwo'
                    }),
                    Attachment.Body => Blob.valueOf('test body')
                }
            )
            .quantity(2)
            .build()
            .getRecords();

        String childAccIdOne = 'a0e7d000003altTAAC';
        String childAccIdTwo = 'a0e7d000003altTAAD';
        String parentAccIdOne = 'a0e7d000003altTAAA';
        String parentAccIdTwo = 'a0e7d000003altTAAB';

        Map<String, String> assignmentMap = new Map<String, String>{childAccIdOne => parentAccIdOne, parentAccIdOne => parentAccIdTwo};
        Map<Id, Attachment> parentAccIdToAttMap = new Map<Id, Attachment>{parentAccIdOne => attachmentList[0], parentAccIdTwo => attachmentList[1] };

        Test.startTest();
            List<Attachment> attList = AccountService.buildAttachmentsToInsert(assignmentMap, parentAccIdToAttMap);
        Test.stopTest();
        System.assert(attList.size() == 2, 'Both attachments should be copied');
    }

    @IsTest
    public static void testCopyParentMsaAttachment() {
        Triggers.switchOff();
        List<Account> accountList = (List<Account>) new SObjectBuilder(Account.sObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Account.SObjectType))
            .quantity(4)
            .create()
            .getRecords();

        Account childIndiaAccountOne = accountList[0];
        Account childIndiaAccountTwo = accountList[1];
        Account parentAccountOne = accountList[2];
        Account parentAccountTwo = accountList[3];

        new SObjectBuilder(Approval__c.SObjectType)
            .quantity(2)
            .setFields(
                new Map<SObjectField, Object>{
                    Approval__c.Name => ValueProviderBuilder.provideUniqueString(),
                    Approval__c.Account__c => ValueProviderBuilder.provideList(new List<Id>{
                        childIndiaAccountOne.Id,
                        childIndiaAccountTwo.Id
                    }),
                    Approval__c.RecordTypeId => ApprovalHelper.RT_ID_KYC_APPROVAL_REQUEST
                }
            )
            .create();

        List<Contract> contractList = (List<Contract>) new SObjectBuilder(Contract.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contract.Name => ValueProviderBuilder.provideUniqueString(),
                    Contract.AccountId => ValueProviderBuilder.provideList(new List<Id>{
                        parentAccountOne.Id,
                        parentAccountTwo.Id
                    }),
                    Contract.Original_Signed_Date__c => ValueProviderBuilder.provideList(new List<Datetime>{
                        System.now(),
                        System.now()
                    })
                }
            )
            .quantity(2)
            .create()
            .getRecords();

        /* Contracts can't be inserted in Active status */
        for (Contract c : contractList) {
            c.Status = DocuSignHelper.CONTRACT_STATUS_ACTIVE;
        }
        update contractList;

        List<Attachment> attachmentList = (List<Attachment>) new SObjectBuilder(Attachment.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Attachment.Name => ValueProviderBuilder.provideList(new List<String>{
                        'testMSAtest',
                        'wrong attachment name 1',
                        'testMaster Service Agreementtest',
                        'wrong attachment name 2',
                        'MSAchildIndiaAccountOne Attachment',
                        'childIndiaAccountOne Attachment Master Service Agreement'
                    }),
                    Attachment.ParentId => ValueProviderBuilder.provideList(new List<Id>{
                        contractList[0].Id,
                        contractList[0].Id,
                        contractList[1].Id,
                        contractList[1].Id,
                        childIndiaAccountOne.Id,
                        childIndiaAccountTwo.Id
                    }),
                    Attachment.Body => Blob.valueOf('test body')
                }
            )
            .quantity(6)
            .create()
            .getRecords();
        Triggers.switchOn();
        Test.startTest();
            AccountService.copyParentMsaAttachment(new Map<String, String>{
                childIndiaAccountOne.Id => parentAccountOne.Id,
                childIndiaAccountTwo.Id => parentAccountTwo.Id
            });
        Test.stopTest();
        List<Attachment> copiedAttachments = (List<Attachment>) new AttachmentSelector()
            .selectAttachmentsByParentIds(new List<Object>{new List<Id>{childIndiaAccountOne.Id, childIndiaAccountTwo.Id}})
            .executeQuery();

        System.assert(copiedAttachments.size() == 2, 'Old attachments should be removed, new attachments  should be created');
        for (Attachment at : copiedAttachments) {
            if (at.ParentId == childIndiaAccountOne.Id) {
               System.assert(at.Name == 'testMSAtest', 'Wrong attachment was copied');
            }
            if (at.ParentId == childIndiaAccountTwo.Id) {
                System.assert(at.Name == 'testMaster Service Agreementtest', 'Wrong attachment was copied');
            }
        }
    }

    @isTest
    public static void testGetSubBrandAndDefaultBI() {
        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .create()
            .getRecord();

        AccountService.RequestParams params = new AccountService.RequestParams();
        params.action = 'getSubBrandAndDefaultBI';
        params.accountId = testAccount.Id;

        RestRequest request = new RestRequest();
        request.requestBody = Blob.valueOf(JSON.serialize(params));
        RestContext.request = request;

        Test.startTest();
            AccountService.handleRequest();
        Test.stopTest();

        String body = RestContext.response.responseBody.toString();

        Response resp = new Response();
        resp.setData('defaultBI', '');
        resp.setData('subBrand', '');
        resp.setData('availableBIs', '[]');

        System.assertEquals(JSON.serialize(resp), body, 'Wrong subBrand, defaultBI or availableBIs');
    }
}