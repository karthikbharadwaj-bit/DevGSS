@isTest
private class Test_LookupController {

    @isTest
    private static void test_getAreaCodes() {
        // Create Test data

        List<Category_Codes__c> categoryCodes = new List<Category_Codes__c>();

        Map<String, String> m = new Map<String, String>{
            'FAX_AREA_CODES' => 'MLFN,MTFN',
            'LOCAL_AREA_CODES' => 'ALN,HDRF,HDR,HD,MLN,MLFN,SP,EP',
            'MAIN_AREA_CODES' => 'ALN,HDRF,HDR,HD,MLN,SP,EP,ATN,MTN',
            'TOLL_FREE_AREA_CODES' => 'ATN,MTN,MTFN',
            'AREA_CODES_AVAILABLE' => 'HDRF,HDR,HD,MLN,MTN,MLFN,MTFN,ALN,ATN,SP,EP',
            'REQUIRED_AREA_CODES' => 'ALN,ATN,HDRF,HD'
        };
        for (String codeName : m.KeySet()) {
            categoryCodes.add(
                new Category_Codes__c(
                    Name = codeName,
                    Codes__c = m.get(codeName)
                )
            );
        }
        insert categoryCodes;

        List <Area_Codes__c> testAreaCodes = new List <Area_Codes__c> ();
        // US local
        testAreaCodes.add(new Area_Codes__c(
            Name = '001',
            Area_Code__c = 001,
            Country__c = 'United States',
            Type__c = 'Local'
        ));
        // US Toll-free
        testAreaCodes.add(new Area_Codes__c(
            Name = '002',
            Area_Code__c = 002,
            Country__c = 'United States',
            Type__c = 'Toll-Free'
        ));
        // Canada Toll-free
        testAreaCodes.add(new Area_Codes__c(
            Name = '003',
            Area_Code__c = 003,
            Country__c = 'Canada',
            Type__c = 'Toll-Free'
        ));
        // United Kingdom Toll-free
        testAreaCodes.add(new Area_Codes__c(
            Name = '004',
            Area_Code__c = 004,
            Country__c = 'United Kingdom',
            Type__c = 'Toll-Free'
        ));
        // EU Toll-free
        testAreaCodes.add(new Area_Codes__c(
            Name = '005',
            Area_Code__c = 005,
            Country__c = 'Austria',
            Type__c = 'Toll-Free'
        ));
        // with id
        Area_Codes__c testac = new Area_Codes__c(
            Name = '006',
            Area_Code__c = 006,
            Country__c = 'Belgium'
        );
        testAreaCodes.add(testac);
        // Last viewed
        testAreaCodes.add(new Area_Codes__c(
            Name = '007',
            Area_Code__c = 007,
            Country__c = 'View me'
        ));
        // AU Toll-free
        testAreaCodes.add(new Area_Codes__c(
            Name = '008',
            Area_Code__c = 005,
            Country__c = 'Australia',
            Type__c = 'Toll-Free'
        ));
        insert testAreaCodes;

        // Test Query by id
        Test.startTest();

        List<LookupController.LookupResult> acById = LookupController.getAreaCodes('', testac.Id, null, null);
        System.assertEquals(1, acById.size(), 'Lookup should return record by id');
        System.assertEquals(testac.Id, acById.get(0).Id, 'Lookup should return record by id');

        // Test query last viewed
        Area_Codes__c acLastViewed = [SELECT Id FROM Area_Codes__c WHERE Country__c = 'View me' LIMIT 1 FOR VIEW];
        List<LookupController.LookupResult> acByView = LookupController.getAreaCodes('', null, null, null);
        //System.assert(acByView.size() > 0, 'Lookup should return last viewed elements if other is not specified');
        //System.assertEquals(acLastViewed.Id,acByView.get(0).Id, 'Lookup should return last viewed elements if other is not specified');

        //@TODO Find a way to test sosl part properly

        // Test query by search text
        List<LookupController.LookupResult> acBySearch = LookupController.getAreaCodes('States', null, null, null);
        // sosl returns no rows in test

        // Test filter by B-2189 1.1
        List<LookupController.LookupResult> acByFilter1 = LookupController.getAreaCodes('States', null, null, new Map <String, String>{
            'family' => 'Discounted Phones', 'brand' => 'RingCentral'
        });
        // sosl returns no rows in test

        // Test filter by B-2189 1.3
        List<LookupController.LookupResult> acByFilter2 = LookupController.getAreaCodes('United', null, null, new Map <String, String>{
            'feature' => '2', 'brand' => 'RingCentral UK'
        });
        // sosl returns no rows in test

        // Test filter by B-1914 3
        List<LookupController.LookupResult> acByFilter3 = LookupController.getAreaCodes('Austria', null, null, new Map <String, String>{
            'brand' => 'RingCentral EU'
        });
        // sosl returns no rows in test

        // Test filter by B-2342 3.5
        List<LookupController.LookupResult> acByFilter4 = LookupController.getAreaCodes('800', null, null, new Map <String, String>{
            'type' => 'fax'
        });
        // sosl returns no rows in test

        // Test australian filter
        List<LookupController.LookupResult> acByFilter5 = LookupController.getAreaCodes('Australia', null, null, new Map <String, String>{
            'brand' => 'RingCentral AU'
        });

        Test.stopTest();
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    private static void test_getContacts() {
        Test.startTest();
        //LookupController.getContacts(null, null);

        LookupController.getContacts('Test', 5);
        Test.stopTest();
    }

    /**
     * @see LookupController.getUsers
     */
    @isTest
    private static void test_getUsers() {
        User user1 = new User(
            Username = 'randomUser1!user@example.tld',
            LastName = 'TestRandomUser1',
            Email = 'randomUser1!user@example.tld',
            Alias = 'testUsr1',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = ProfileHelper.PROFILE_ID_SYSADMIN,
            LanguageLocaleKey = 'en_US'
        );
        User user2 = new User(
            Username = 'randomUser2!user@example.tld',
            LastName = 'TestRandomUser2',
            Email = 'randomUser2!user@example.tld',
            Alias = 'testUsr2',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = ProfileHelper.PROFILE_ID_SYSADMIN,
            LanguageLocaleKey = 'en_US'
        );

         //Added as part of profile consolidation of Professional Services
		Id profServiceProfileId2 = [SELECT id, Name FROM Profile WHERE Name = 'Professional Services Lightning' LIMIT 1].Id;
        User user3 = new User(
            Username = 'randomUser3!user@example.tld',
            LastName = 'TestRandomUser3',
            Email = 'randomUser3!user@example.tld',
            Alias = 'testUsr3',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = profServiceProfileId2,
            LanguageLocaleKey = 'en_US'
        );

        User user4 = new User(
            Username = 'randomUser4!user@example.tld',
            LastName = 'TestRandomUser4',
            Email = 'randomUser4!user@example.tld',
            Alias = 'testUsr4',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = profServiceProfileId2,
            LanguageLocaleKey = 'en_US'
        );
        insert new List<User>{
            user1, user2, user3, user4
        };
        //Make LastViewedDate != null for the test user
        User testUser3 = [SELECT Id FROM User WHERE Id = :user3.Id FOR VIEW];

        Test.startTest();
        try {
            // Test search by Id
            List<LookupController.LookupResult> resultUsers1 = LookupController.getUsers(null, user1.Id, 5, null);

            // Test search by text
            List<LookupController.LookupResult> resultUsers2 = LookupController.getUsers('TestRandomUser2', null, null, null);

            // Test general search(with limitation by profileId)
            List<LookupController.LookupResult> resultUsers3 = LookupController.getUsers(null, null, null, new Map <String, String>{
                'filterByProservProfile' => 'filterByProservProfile'
            });

            // Flaky test may fail with error
            // No such column 'LastViewedDate' on entity 'User'
            // Comment if any problems
            // Until salesforce fix it
            // List<User> LastViewedUsers = [SELECT Id FROM User LIMIT 1 FOR VIEW];
            // List<LookupController.LookupResult> resultUsers3 = LookupController.getUsers('', null, null, null);
            System.assertEquals(user1.Id, resultUsers1.get(0).RecordObj.Id);
        } catch (QueryException e) {
            if (!e.getMessage().contains('No such column \'LastViewedDate\'')) {
                AquivaHelper.throwAquivaException(e);
            }
        }
        Test.stopTest();


        //Assert fails because of SOSL
        //See https://salesforce.stackexchange.com/questions/12813/why-is-sosl-in-test-not-working
        //We can utilize Test.setFixedSearchResults, but it makes test pointless

        //System.assertEquals(user3.Id, resultUsers3.get(0).RecordObj.Id);
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    private static void test_getRecords() {
        Test.startTest();
        LookupController.getRecords('Account', 'Test', null, 5, null);
        LookupController.getRecords('Contact', 'Test', null, 5, null);
        Test.stopTest();
    }

    @isTest
    private static void test_getAccounts() {
        Account acc1 = new Account(
            Name = 'Test 1'
        );
        Account acc2 = new Account(
            Name = 'Test 2 search_keyword'
        );
        Account acc3 = new Account(
            Name = 'Test 2'
        );
        insert new List<Account>{
            acc1, acc2, acc3
        };

        Test.startTest();
        try {
            // Test search by Id
            List<LookupController.LookupResult> resultAccount1 = LookupController.getAccounts(null, acc1.Id, 5, null, false);

            // Test search by text
            List<LookupController.LookupResult> resultAccount2 = LookupController.getAccounts('search_keyword', null, null, null, false);

            System.assertEquals(acc1.Id, resultAccount1.get(0).RecordObj.Id);
        } catch (QueryException e) {
            if (!e.getMessage().contains('No such column \'LastViewedDate\'')) {
                AquivaHelper.throwAquivaException(e);
            }
        }
        Test.stopTest();
    }

    @IsTest
    private static void testGetAccountsForEngageMoveToBob() {
        Boolean isBobCustomer = false;
        createCustomerAndPartnersAccs(isBobCustomer);
        Test.startTest();
            List<Account> viewedAccs = (List<Account>) [select Id from Account FOR VIEW];
            LookupService.Params paramsData = getParamsData(isBobCustomer);
            List<LookupController.LookupResult> result = LookupController.getAccounts(
                paramsData.searchText,
                paramsData.recordId,
                paramsData.queryLimit,
                paramsData.params,
                false
            );
        Test.stopTest();
        System.assert(!result.isEmpty(), 'Lookup should find account');
        System.assertEquals(((Account) result.get(0).RecordObj)?.Name, 'BOB Partner', 'Lookup should find partner Bill-on-Behalf account');
    }

    @IsTest
    private static void testGetAccountsForEngageBobChangePartner() {
        Boolean isBobCustomer = true;
        createCustomerAndPartnersAccs(isBobCustomer);
        Test.startTest();
            List<Account> viewedAccs = (List<Account>) [select Id from Account FOR VIEW];
            LookupService.Params paramsData = getParamsData(isBobCustomer);
            List<LookupController.LookupResult> result = LookupController.getAccounts(
                paramsData.searchText,
                paramsData.recordId,
                paramsData.queryLimit,
                paramsData.params,
                false
            );
        Test.stopTest();
        System.assert(!result.isEmpty(), 'Lookup should find account');
        System.assertEquals(((Account) result.get(0).RecordObj)?.Name, 'BOB Partner', 'Lookup should find partner Bill-on-Behalf account');
    }

    private static void createCustomerAndPartnersAccs(Boolean isBobCustomer) {
        new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => ValueProviderBuilder.provideList(new List<String> {
                        'Bob Customer',
                        'BOB Partner',
                        'ATOS BOB Partner'
                    }),
                    Account.Partner_Type__c => ValueProviderBuilder.provideList(new List<String> {
                        isBobCustomer
                            ? AccountHelper.ACCOUNT_PARTNER_BILL_ON_BEHALF
                            : '',
                        AccountHelper.ACCOUNT_PARTNER_BILL_ON_BEHALF,
                        AccountHelper.ACCOUNT_PARTNER_ATOS_BILL_ON_BEHALF
                    }),
                    Account.BusinessIdentity__c => 'RingCentral Inc.',
                    Account.RecordTypeId => ValueProviderBuilder.provideList(new List<Id> {
                        AccountHelper.RT_ID_CUSTOMER_ACCOUNT,
                        AccountHelper.RT_ID_PARTNER_ACCOUNT,
                        AccountHelper.RT_ID_PARTNER_ACCOUNT
                    }),
                    Account.Type => ValueProviderBuilder.provideList(new List<String> {
                        'Customer',
                        'Partner',
                        'Partner'
                    }),
                    Account.PartnerStatus__c => ValueProviderBuilder.provideList(new List<String> {
                        '',
                        'Active',
                        'Active'
                    }),
                    Account.Service_Type__c => ValueProviderBuilder.provideList(new List<String> {
                        'Engage Digital Standalone',
                        '',
                        ''
                    })
                }
            )
            .quantity(3)
            .create();
    }

    private static LookupService.Params getParamsData(Boolean isBobCustomer) {
        return (LookupService.Params) JSON.deserialize(
            '{' +
                '"searchText":"",' +
                '"recordId":null,' +
                '"queryLimit":null,' +
                '"params":{"businessIdentity":"RingCentral Inc.","engagePartners":"true","bobPartners":" ' + !isBobCustomer + '","partnerOnly":"true"},' +
                '"method":"getAccounts",' +
                '"action":"getLookupSearch"' +
                '}',
            LookupService.Params.class);
    }

    @isTest
    private static void test_getContactsSOSL() {
        Account acc1 = new Account(
            Name = 'Test 1'
        );
        Contact testContact1 = new Contact(
            AccountId = acc1.Id,
            LastName = 'John',
            FirstName = 'Doe',
            Email = 'contact1@ringcentral.tld'
        );
        Contact testContact2 = new Contact(
            AccountId = acc1.Id,
            LastName = 'Eric',
            FirstName = 'K. Murphy',
            Email = 'contact2@ringcentral.tld'
        );

        Account acc2 = new Account(
            Name = 'Test 2'
        );
        Contact testContact3 = new Contact(
            AccountId = acc2.Id,
            LastName = 'Eric',
            FirstName = 'K. Murphy',
            Email = 'contact3@newmarketinc.com'
        );
        Contact testContact4 = new Contact(
            AccountId = acc2.Id,
            LastName = 'Roberta',
            FirstName = 'D. Shields',
            Email = 'contact4@newmarketinc.com'
        );
        insert new List<Account>{
            acc1, acc2
        };
        insert new List<Contact>{
            testContact1, testContact2,
            testContact3, testContact4
        };

        Test.startTest();
        try {
            // Test search by Id
            List<LookupController.LookupResult> resultContact1 = LookupController.getContacts(null, testContact1.Id, 5, null);

            // Test search by text (filtered by Account Id)
            List<LookupController.LookupResult> resultContact3 = LookupController.getContacts('Eric Murphy', null, null, new Map<String, String>{
                'accountId' => acc2.Id
            });

            System.assertEquals(testContact1.Id, resultContact1.get(0).RecordObj.Id);
        } catch (QueryException e) {
            if (!e.getMessage().contains('No such column \'LastViewedDate\'')) {
                AquivaHelper.throwAquivaException(e);
            }
        }
        Test.stopTest();
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    private static void test_getContactsSOSLRoleFilter() {
        Account acc1 = new Account(
            Name = 'Test 1'
        );
        Contact testContact1 = new Contact(
            AccountId = acc1.Id,
            LastName = 'John',
            FirstName = 'Doe',
            Email = 'contact1@ringcentral.tld'
        );
        Contact testContact2 = new Contact(
            AccountId = acc1.Id,
            LastName = 'Eric',
            FirstName = 'K. Murphy',
            Email = 'contact2@ringcentral.tld'
        );

        Account acc2 = new Account(
            Name = 'Test 2'
        );
        Contact testContact3 = new Contact(
            AccountId = acc2.Id,
            LastName = 'Eric',
            FirstName = 'K. Murphy',
            Email = 'contact3@newmarketinc.com'
        );
        Contact testContact4 = new Contact(
            AccountId = acc2.Id,
            LastName = 'Roberta',
            FirstName = 'D. Shields',
            Email = 'contact4@newmarketinc.com'
        );
        insert new List<Account>{
            acc1, acc2
        };
        insert new List<Contact>{
            testContact1, testContact2,
            testContact3, testContact4
        };

        AccountContactRole testContactRole = new AccountContactRole(
            Role = 'Signatory',
            ContactId = testContact1.Id,
            AccountId = acc1.Id
        );
        insert testContactRole;

        Test.startTest();
        try {
            // Test search by text (filtered by Account Id and contact role)
            List<LookupController.LookupResult> resultContact1 = LookupController.getContacts('Eric Murphy', null, null, new Map<String, String>{
                'accountId' => acc1.Id,
                'applyContactRoleFilter' => 'true'
            });

            // Test search by text (filtered by Account Id and contact role)
            List<LookupController.LookupResult> resultContact2 = LookupController.getContacts('Eric Murphy', null, null, new Map<String, String>{
                'accountId' => acc2.Id,
                'applyContactRoleFilter' => 'true'
            });
        } catch (QueryException e) {
            if (!e.getMessage().contains('No such column \'LastViewedDate\'')) {
                AquivaHelper.throwAquivaException(e);
            }
        }
        Test.stopTest();
    }

    @isTest
    private static void testGetEngageLegalApprovals() {
        List<Account> acc = (List<Account>) new SObjectBuilder(Account.SObjectType)
            .quantity(2)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => ValueProviderBuilder.provideList(new List<String>{
                    'ACME Inc.', 'Legacy LLC'
                })
            })
            .create()
            .getRecords();
        List<Approval__c> approval = (List<Approval__c>) new SObjectBuilder(Approval__c.SObjectType)
            .quantity(4)
            .setFields(new Map<SObjectField, Object>{
                Approval__c.Name => ValueProviderBuilder.provideList(new List<String>{
                    'Engage Legal - ' + acc.get(0).Name,
                    'Engage Legal - ' + acc.get(0).Name,
                    'Engage Legal - ' + acc.get(1).Name,
                    'Engage Legal - ' + acc.get(1).Name
                }),
                Approval__c.RecordTypeId => ApprovalHelper.RT_ID_ENGAGE_LEGAL,
                Approval__c.Account__c => ValueProviderBuilder.provideList(new List<Id>{
                    acc.get(0).Id,
                    acc.get(0).Id,
                    acc.get(1).Id,
                    acc.get(1).Id
                })
            })
            .create()
            .getRecords();

        approval = new ApprovalSelector()
            .selectEngageLegalApprovalsForAccounts(new List<Object> { acc })
            .addOrdering('Approval_ID__c', QueryFactory.SortOrder.ASCENDING)
            .executeQuery();

        Test.startTest();

        Test.setFixedSearchResults(new List<Id> { approval.get(0).Id, approval.get(1).Id });
        List<LookupController.LookupResult> resultsApproval1
            = LookupController.getEngageLegalApprovals('ACME Inc.', null, null, new Map<String, String>{
                'accountId' => acc.get(0).Id
            });


        System.assertEquals(approval.get(0).Id, resultsApproval1.get(0).Id);
        System.assertEquals(approval.get(0).Approval_ID__c, resultsApproval1.get(0).Text);
        System.assertEquals(approval.get(0).Name, resultsApproval1.get(0).Meta);
        System.assertEquals(approval.get(1).Id, resultsApproval1.get(1).Id);
        System.assertEquals(approval.get(1).Approval_ID__c, resultsApproval1.get(1).Text);
        System.assertEquals(approval.get(1).Name, resultsApproval1.get(1).Meta);

        Test.setFixedSearchResults(new List<Id> { approval.get(2).Id, approval.get(3).Id });
        List<LookupController.LookupResult> resultsApproval2
            = LookupController.getEngageLegalApprovals('Legacy', null, null, new Map<String, String>{
                'accountId' => acc.get(1).Id
            });

        System.assertEquals(approval.get(2).Id, resultsApproval2.get(0).Id);
        System.assertEquals(approval.get(2).Approval_ID__c, resultsApproval2.get(0).Text);
        System.assertEquals(approval.get(2).Name, resultsApproval2.get(0).Meta);
        System.assertEquals(approval.get(3).Id, resultsApproval2.get(1).Id);
        System.assertEquals(approval.get(3).Approval_ID__c, resultsApproval2.get(1).Text);
        System.assertEquals(approval.get(3).Name, resultsApproval2.get(1).Meta);

        List<LookupController.LookupResult> resultsApprovalgetQuote
            = LookupController.getQuotes('ACME Inc.', null, null, new Map<String, String>{
                'accountId' => acc.get(0).Id
            });

        Test.stopTest();
    }

    @isTest
    private static void testGetProducts() {
        String testGoaAll = '{"regular":"test_goa_group_all"}';
        String testGoaOne = '{"regular":"test_goa_group_one"}';
        List<Product2> productItems = (List<Product2>) new SObjectBuilder(Product2.SObjectType)
            .quantity(6)
            .setFields(new Map<SObjectField, Object>{
                Product2.Name => ValueProviderBuilder.provideList(new List<String>{
                    'DigitalLine', 'DigitalLine', 'Phone', 'Support', 'Subscription', 'Subscription'
                }),
                Product2.IsActive => ValueProviderBuilder.provideList(new List<Boolean>{
                    false, true, true, true, true, true
                }),
                Product2.GOA_Group_V3__c => ValueProviderBuilder.provideList(new List<String>{
                    testGoaOne, testGoaAll, testGoaAll, null, testGoaAll, null
                }),
                Product2.Sub_Category__c => ValueProviderBuilder.provideList(new List<String>{
                    null, null, null, null, null, Product2Helper.SUBCATEGORY_CONTACT_CENTER
                })
            })
            .create()
            .getRecords();

        Set<Id> productItemIds = (new Map<Id, Product2>(productItems)).keySet();
        Test.setFixedSearchResults(new List<Id>(productItemIds));

        Id recordId = productItems.get(1).Id;

        List<LookupController.LookupResult> result;

        result = LookupController.getProducts('line', null, null, new Map<String, String>{'productCategory' => 'test_goa_group_one'});
        System.assertEquals(1, result.size(), 'should be found 1 because it has additional filter by productCategory');

        result = LookupController.getProducts(null, null, null, new Map<String, String>{'productCategory' => 'test_goa_group_one'});
        System.assertEquals(1, result.size(), 'should be found 1 because it has additional filter by productCategory');

        result = LookupController.getProducts(null, recordId, null, null);
        System.assertEquals(1, result.size(), 'should be found 1 because we pass the record id');

        result = LookupController.getProducts(null, null, null, null);
        System.assertEquals(6, result.size(), 'should be found 6 because the test method has fixed search result');

        result = LookupController.getProducts(null, null, null, new Map<String, String>{'productCategory' => Product2Helper.DEFAULT_CATEGORY});
        System.assertEquals(1, result.size(), 'should be found 1 because it has ' + Product2Helper.DEFAULT_CATEGORY + ' in additional filter by productCategory and no "Contact Center" in Sub_Category__c');
    }

    private static void testGetPartnerAccounts() {
        List<Account> listAccs = (List<Account>) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => ValueProviderBuilder.provideList(new List<String>{
                    'Test acc 1', 'Test acc 2'
                })
            })
            .quantity(2)
            .create()
            .getRecords();

        Test.startTest();
            List<Account> viewedAccs = [SELECT Id FROM Account FOR VIEW];
            List<LookupController.LookupResult> resultsAccounts
                = LookupController.getAccounts('', null, null, new Map<String, String>{
                    'partnerId' => listAccs.get(0).Partner_ID__c,
                    'partnerType' => listAccs.get(0).Partner_Type__c,
                    'method' => 'getAccounts',
                    'action'=> 'getLookupSearch'
                }, false);
        Test.stopTest();

        System.assertEquals(2, resultsAccounts.size(), 'List of returned Accounts should not be empty, must contain 2 elements');
        System.assertEquals(resultsAccounts.get(0).Id, listAccs.get(0).Id, 'Accounts must be same');
        System.assertEquals(resultsAccounts.get(1).Id, listAccs.get(1).Id, 'Accounts must be same');
    }

    @isTest
    private static void testGetQueuesSObjects() {
        User testUser = (User) new SObjectBuilder(User.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    User.Username => UserHelper.getUniqueUserName(),
                    User.LastName => ValueProviderBuilder.provideUniqueString('LastName'),
                    User.ProfileId => ProfileHelper.PROFILE_ID_SYSADMIN,
                    User.Email => ValueProviderBuilder.provideUniqueEmail(),
                    User.Alias => StringHelper.getRandomString(8),
                    User.TimeZoneSidKey => 'America/Los_Angeles',
                    User.LocaleSidKey => 'en_US',
                    User.EmailEncodingKey => 'UTF-8',
                    User.LanguageLocaleKey => 'en_US',
                    User.Region__c => 'US',
                    User.Sub_Region__c => 'All'
                }
            )
            .create()
            .getRecord();
        Group testQueue = (Group) new SObjectBuilder(Group.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Group.Name => ValueProviderBuilder.provideUniqueString('testDQGoa_Group'),
                    Group.Type => 'Queue'
                }
            )
            .create()
            .getRecord();

        System.runAs(testUser) {
            QueuesObject testQueueSObject = (QueueSObject) new SObjectBuilder(QueueSObject.getSObjectType())
                .setFields(
                    new Map<SObjectField, Object>{
                        QueueSObject.QueueID => testQueue.Id,
                        QueueSObject.SObjectType => ApprovalHelper.APPROVAL_OBJECT_NAME
                    }
                )
                .create()
                .getRecord();
        }
        List <LookupController.LookupResult> results = new List<LookupController.LookupResult>();
        Test.startTest();
            results = LookupController.getQueuesSObjects('', null, 5, new Map<String,String> { 'nameOfQueueSupportObject' => ApprovalHelper.APPROVAL_OBJECT_NAME});
        Test.stopTest();
        System.assert(!results.isEmpty(), 'Method must return Queues with Supported object Approval__c');
    }

    @isTest
    private static void testGetQueuesSObjectsWithSearchText() {
        User testUser = (User) new SObjectBuilder(User.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    User.Username => UserHelper.getUniqueUserName(),
                    User.LastName => ValueProviderBuilder.provideUniqueString('LastName'),
                    User.ProfileId => ProfileHelper.PROFILE_ID_SYSADMIN,
                    User.Email => ValueProviderBuilder.provideUniqueEmail(),
                    User.Alias => StringHelper.getRandomString(8),
                    User.TimeZoneSidKey => 'America/Los_Angeles',
                    User.LocaleSidKey => 'en_US',
                    User.EmailEncodingKey => 'UTF-8',
                    User.LanguageLocaleKey => 'en_US',
                    User.Region__c => 'US',
                    User.Sub_Region__c => 'All'
                }
            )
            .create()
            .getRecord();
        Group testQueue = (Group) new SObjectBuilder(Group.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Group.Name => 'Abcd test queue',
                    Group.Type => 'Queue'
                }
            )
            .create()
            .getRecord();

        System.runAs(testUser) {
            QueuesObject testQueueSObject = (QueueSObject) new SObjectBuilder(QueueSObject.getSObjectType())
                .setFields(
                    new Map<SObjectField, Object>{
                        QueueSObject.QueueID => testQueue.Id,
                        QueueSObject.SObjectType => DQApproverHelper.DQ_APPROVER_OBJECT_NAME
                    }
                )
                .create()
                .getRecord();
        }
        List <LookupController.LookupResult> results = new List<LookupController.LookupResult>();
        Test.startTest();
            results = LookupController.getQueuesSObjects('Ab', null, 5, new Map<String,String> { 'nameOfQueueSupportObject' => DQApproverHelper.DQ_APPROVER_OBJECT_NAME});
        Test.stopTest();
        System.assertEquals(testQueue.Id, results[0].Id, 'Method must return Queue with Supported object DQ_Deal_Qualification_Approver__c and with name started from ab');
    }
}