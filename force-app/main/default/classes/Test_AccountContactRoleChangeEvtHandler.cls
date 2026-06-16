@IsTest
private class Test_AccountContactRoleChangeEvtHandler {
    @IsTest
    static void testSyncWithTechnicalAccounts_create() {
        Triggers.switchOff();
        Triggers.except('AccountContactRoleChangeEventHandler.SyncWithTechnicalAccounts');

        Test.enableChangeDataCapture();

        Account masterAccount = TestDataGenerator.createAccount('Master Account');
        Map<String, Account> techAccounts = AccountHelper.createTechnicalAccounts(
            masterAccount.Id,
            new List<String>{ QuoteHelper.NGBS_RCCC_PRODUCT }
        );
        Contact masterAccountContact1 = TestDataGenerator.createContact('John', 'Doe', masterAccount);

        Test.startTest();
        AccountContactRole acr = TestDataGenerator.createAccountContactRole(
            masterAccount,
            masterAccountContact1,
            'Signatory',
            true
        );
        Test.stopTest();
        Triggers.switchOn();

        List<AccountContactRole> acrs = new AccountContactRoleSelector()
            .selectAccountContactRolesByAccountIds(new List<Id>{ techAccounts.get(QuoteHelper.NGBS_RCCC_PRODUCT).Id })
            .selectFields(new List<String>{ 'Account.Service_Type__c' })
            .executeQuery();
        Map<String, List<AccountContactRole>> acrMap = (Map<String, List<AccountContactRole>>) AquivaHelper.groupByStringField(
            List<AccountContactRole>.class,
            acrs,
            'Account.Service_Type__c'
        );

        System.assert(
            acrMap.get(QuoteHelper.NGBS_RCCC_PRODUCT) != null,
            'Account Contact Role for CC account should exist'
        );
        System.assert(
            acrMap.get(QuoteHelper.NGBS_RCCC_PRODUCT).get(0).ContactId == acr.ContactId,
            'Account Contact Role for CC account has the same contact as master Account Contact Role'
        );
        System.assert(
            acrMap.get(QuoteHelper.NGBS_RCCC_PRODUCT).get(0).Role == acr.Role,
            'Account Contact Role for CC account has the same role as master Account Contact Role'
        );
        System.assert(
            acrMap.get(QuoteHelper.NGBS_RCCC_PRODUCT).get(0).IsPrimary == acr.IsPrimary,
            'Account Contact Role for CC account has the same IsPrimary flag value as master Account Contact Role'
        );
    }

    @IsTest
    static void testSyncWithTechnicalAccounts_delete() {
        Triggers.switchOff();
        Triggers.except('AccountContactRoleChangeEventHandler.SyncWithTechnicalAccounts');

        Test.enableChangeDataCapture();

        List<String> services = new List<String>{
            QuoteHelper.NGBS_RCCC_PRODUCT,
            QuoteHelper.NGBS_ENGAGE_DIGITAL_PRODUCT
        };
        Account masterAccount = TestDataGenerator.createAccount('Master Account');
        Map<String, Account> techAccounts = AccountHelper.createTechnicalAccounts(masterAccount.Id, services);
        Contact masterAccountContact1 = TestDataGenerator.createContact('John', 'Doe', masterAccount);
        Contact masterAccountContact2 = TestDataGenerator.createContact('Jane', 'Doe', masterAccount);
        AccountContactRole acr1 = TestDataGenerator.createAccountContactRole(
            masterAccount,
            masterAccountContact1,
            'Signatory',
            true
        );
        AccountContactRole acr2 = TestDataGenerator.createAccountContactRole(
            masterAccount,
            masterAccountContact2,
            'Evaluator',
            false
        );

        Test.getEventBus().deliver();

        Test.startTest();
        delete new AccountContactRole(Id = acr1.Id);
        Test.stopTest();
        Triggers.switchOn();

        List<AccountContactRole> acrs = new AccountContactRoleSelector()
            .selectAccountContactRolesByAccountIds(
                new List<Id>{
                    techAccounts.get(QuoteHelper.NGBS_RCCC_PRODUCT).Id,
                    techAccounts.get(QuoteHelper.NGBS_ENGAGE_DIGITAL_PRODUCT).Id
                }
            )
            .selectFields(new List<String>{ 'Account.Service_Type__c' })
            .executeQuery();
        Map<String, List<AccountContactRole>> acrMap = (Map<String, List<AccountContactRole>>) AquivaHelper.groupByStringField(
            List<AccountContactRole>.class,
            acrs,
            'Account.Service_Type__c'
        );

        System.assert(
            acrMap.get(QuoteHelper.NGBS_RCCC_PRODUCT).size() == 1,
            'Account Contact Role for CC technical account must contain single entry: ' +
            acrMap.get(QuoteHelper.NGBS_RCCC_PRODUCT).size()
        );
        System.assert(
            acrMap.get(QuoteHelper.NGBS_RCCC_PRODUCT).get(0).ContactId == acr2.ContactId,
            'Remaining Account Contact Role for CC technical account must match with master: ' +
            acrMap.get(QuoteHelper.NGBS_RCCC_PRODUCT).get(0).ContactId +
            ' == ' +
            acr2.ContactId
        );
        System.assert(
            acrMap.get(QuoteHelper.NGBS_ENGAGE_DIGITAL_PRODUCT).size() == 1,
            'Account Contact Role for ED technical account must contain single entry: ' +
            acrMap.get(QuoteHelper.NGBS_ENGAGE_DIGITAL_PRODUCT).size()
        );
        System.assert(
            acrMap.get(QuoteHelper.NGBS_ENGAGE_DIGITAL_PRODUCT).get(0).ContactId == acr2.ContactId,
            'Remaining Account Contact Role for ED technical account must match with master: ' +
            acrMap.get(QuoteHelper.NGBS_ENGAGE_DIGITAL_PRODUCT).get(0).ContactId +
            ' == ' +
            acr2.ContactId
        );
    }

    @IsTest
    static void testSyncWithTechnicalAccounts_update() {
        Triggers.switchOff();
        Triggers.except('AccountContactRoleChangeEventHandler.SyncWithTechnicalAccounts');

        Test.enableChangeDataCapture();

        List<String> services = new List<String>{
            QuoteHelper.NGBS_RCCC_PRODUCT,
            QuoteHelper.NGBS_ENGAGE_DIGITAL_PRODUCT
        };
        Account masterAccount = TestDataGenerator.createAccount('Master Account');
        Map<String, Account> techAccounts = AccountHelper.createTechnicalAccounts(masterAccount.Id, services);
        Contact masterAccountContact1 = TestDataGenerator.createContact('John', 'Doe', masterAccount);
        Contact masterAccountContact2 = TestDataGenerator.createContact('Jane', 'Doe', masterAccount);
        Contact masterAccountContact3 = TestDataGenerator.createContact('Bob', 'Doe', masterAccount);
        AccountContactRole acr1 = TestDataGenerator.createAccountContactRole(
            masterAccount,
            masterAccountContact1,
            'Signatory',
            true
        );
        AccountContactRole acr2 = TestDataGenerator.createAccountContactRole(
            masterAccount,
            masterAccountContact2,
            'Evaluator',
            false
        );

        Test.getEventBus().deliver();

        Test.startTest();
        AccountContactRole updatedAcr1 = new AccountContactRole(
            Id = acr1.Id,
            ContactId = masterAccountContact2.Id,
            Role = 'Decision Maker',
            IsPrimary = false
        );
        AccountContactRole updatedAcr2 = new AccountContactRole(
            Id = acr2.Id,
            ContactId = masterAccountContact3.Id,
            Role = 'Signatory',
            IsPrimary = true
        );

        List<AccountContactRole> listToUpdate = new List<AccountContactRole>{ updatedAcr2, updatedAcr1 };
        update listToUpdate;

        Test.stopTest();
        Triggers.switchOn();

        List<AccountContactRole> acrs = new AccountContactRoleSelector()
            .selectAccountContactRolesByAccountIds(
                new List<Id>{
                    techAccounts.get(QuoteHelper.NGBS_RCCC_PRODUCT).Id,
                    techAccounts.get(QuoteHelper.NGBS_ENGAGE_DIGITAL_PRODUCT).Id
                }
            )
            .selectField('Account.Service_Type__c')
            .addOrdering('CreatedDate', QueryFactory.SortOrder.DESCENDING)
            .executeQuery();
        Map<String, List<AccountContactRole>> acrMap = (Map<String, List<AccountContactRole>>) AquivaHelper.groupByStringField(
            List<AccountContactRole>.class,
            acrs,
            'Account.Service_Type__c'
        );
        Map<String, Map<String, AccountContactRole>> acrByServiceNameAndRole = new Map<String, Map<String, AccountContactRole>>();
        for (String serviceName : acrMap.keySet()) {
            Map<String, AccountContactRole> acrByRole = new Map<String, AccountContactRole>();
            for (AccountContactRole acr : acrMap.get(serviceName)) {
                acrByRole.put(acr.Role, acr);
            }
            acrByServiceNameAndRole.put(serviceName, acrByRole);
        }
        Map<String, AccountContactRole[]> updatedACRByRole = (Map<String, AccountContactRole[]>) AquivaHelper.groupByStringField(
            List<AccountContactRole>.class,
            listToUpdate,
            'Role'
        );

        List<AccountContactRole> ccAcrList = acrMap.get(QuoteHelper.NGBS_RCCC_PRODUCT);
        List<AccountContactRole> edAcrList = acrMap.get(QuoteHelper.NGBS_ENGAGE_DIGITAL_PRODUCT);

        System.assert(ccAcrList != null, 'Account Contact Role for CC account should exist');
        System.assert(
            !ccAcrList.isEmpty(),
            'Account Contact Role list for CC account is not empty: ' + ccAcrList.size()
        );
        System.assert(edAcrList != null, 'Account Contact Role for ED account should exist');
        System.assert(
            !edAcrList.isEmpty(),
            'Account Contact Role list for ED account is not empty: ' + edAcrList.size()
        );

        for (String service : services) {
            Map<String, AccountContactRole> acrByRole = acrByServiceNameAndRole.get(service);
            for (String role : acrByRole.keySet()) {
                if (!updatedACRByRole.containsKey(role)) {
                    continue;
                }
                AccountContactRole acr = acrByRole.get(role);
                System.assert(
                    acr.ContactId == updatedACRByRole.get(role).get(0).ContactId,
                    'ContactId for Account Contact Role ' +
                    role +
                    ' for ' +
                    service +
                    ' matches one on master Account Contact Role ' +
                    role +
                    ': ' +
                    acr.ContactId +
                    ' == ' +
                    updatedACRByRole.get(role).get(0).ContactId
                );
                System.assert(
                    acr.Role == updatedACRByRole.get(role).get(0).Role,
                    'Role for Account Contact Role ' +
                    role +
                    ' for ' +
                    service +
                    ' matches one on master Account Contact Role ' +
                    role +
                    ': ' +
                    acr.Role +
                    ' == ' +
                    updatedACRByRole.get(role).get(0).Role
                );
                System.assert(
                    acr.IsPrimary == updatedACRByRole.get(role).get(0).IsPrimary,
                    'IsPrimary for Account Contact Role ' +
                    role +
                    ' for ' +
                    service +
                    ' matches one on master Account Contact Role ' +
                    role +
                    ': ' +
                    acr.IsPrimary +
                    ' == ' +
                    updatedACRByRole.get(role).get(0).IsPrimary
                );
            }
        }
    }

    @IsTest
    static void testUpdateContactRole() {
        Triggers.switchOff();
        List<Segment_Master__c> segmentMasters = new SObjectBuilder(Segment_Master__c.getSObjectType())
            .setFields(
                new Map<SObjectField, Object>{
                    Segment_Master__c.Name => 'Small Business',
                    Segment_Master__c.Min__c => 20,
                    Segment_Master__c.Max__c => 100,
                    Segment_Master__c.Country__c => 'United States',
                    Segment_Master__c.Start_Date__c => Date.today(),
                    Segment_Master__c.End_Date__c => Date.today().addYears(1)
                }
            )
            .quantity(25)
            .create()
            .getRecords();
        List<Account> accounts = new SObjectBuilder(Account.getSObjectType())
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => ValueProviderBuilder.provideUniqueString('TestAccount'),
                    Account.RC_Account_Status__c => 'Paid',
                    Account.SignupPlatform__c => 'WEB',
                    Account.Service_Type__c => 'office123',
                    Account.Segment_Name__c => ValueProviderBuilder.provideParents(segmentMasters),
                    Account.RC_Activation_Date__c => null,
                    Account.RC_Upgrade_Date__c => Date.today().addMonths(-10),
                    Account.Partner_ID__c => '9852',
                    Account.Wave__c => 'Wave 1'
                }
            )
            .quantity(50)
            .create()
            .getRecords();
        List<Contact> contacts = new SObjectBuilder(Contact.getSObjectType())
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.AccountId => ValueProviderBuilder.provideParents(accounts),
                    Contact.Email => ValueProviderBuilder.provideUniqueEmail('test', '@example.tld'),
                    Contact.FirstName => ValueProviderBuilder.provideUniqueString('TestFirst'),
                    Contact.LastName => ValueProviderBuilder.provideUniqueString('TestLast')
               })
            .quantity(25)
            .create()
            .getRecords();
        Triggers.switchOn();

        Test.enableChangeDataCapture();

        List<AccountContactRole> acrs = new SObjectBuilder(AccountContactRole.getSObjectType())
            .setFields(
                new Map<SObjectField, Object>{
                    AccountContactRole.AccountId => ValueProviderBuilder.provideParents(accounts),
                    AccountContactRole.ContactId => ValueProviderBuilder.provideParents(contacts),
                    AccountContactRole.Role => ValueProviderBuilder.provideList(
                        new List<String>{'Signatory', 'Business User', 'Decision Maker', 'Evaluator', 'Influencer', 'Accounts Payable'}
                    ),
                    AccountContactRole.IsPrimary => true
                }
            )
            .quantity(50)
            .create()
            .getRecords();

        Test.getEventBus().deliver();
        List<AccountContactRole> resultACRs = new AccountContactRoleSelector()
            .selectAccountContactRolesById(new Map<Id, AccountContactRole>(acrs).keySet())
            .selectFields(new List<String> {
                'Contact.Id',
                'Contact.Name',
                'Contact.Customer_Contact_Role__c'
            })
            .executeQuery();
        System.assertEquals(50, resultACRs.size());

        Map<Id, List<AccountContactRole>> acrsByContactId = AquivaHelper.groupByIdField(List<AccountContactRole>.class, resultACRs, 'ContactId');
        List<AccountContactRole> acrsToUpdate = new List<AccountContactRole>();
        for (Id contactId : acrsByContactId.keySet()) {
            List<AccountContactRole> acrsForContact = acrsByContactId.get(contactId);
            List<String> contactRolesForContact = (List<String>) AquivaHelper.collectFieldValues(List<String>.class, acrsForContact, 'Role', true);
            Set<String> contactRolesForContactSet = new Set<String>(contactRolesForContact);

            for (AccountContactRole acr : acrsForContact) {
                if (contactRolesForContact.size() > 1) {
                    System.assertEquals(String.join(contactRolesForContact, ','), acr.Contact.Customer_Contact_Role__c);
                } else if (contactRolesForContact.size() == 1) {
                    System.assertEquals(acr.Role, acr.Contact.Customer_Contact_Role__c);
                } else {
                    System.assertEquals(null, acr.Contact.Customer_Contact_Role__c);
                }

                if (!contactRolesForContactSet.contains('Influencer')) {
                    acrsToUpdate.add(new AccountContactRole(Id = acr.Id, Role = 'Influencer'));
                }
            }
        }

        update acrsToUpdate;
        Test.getEventBus().deliver();

        List<AccountContactRole> resultACRsAfterUpdate = new AccountContactRoleSelector()
            .selectAccountContactRolesById(new Map<Id, AccountContactRole>(acrs).keySet())
            .selectFields(new List<String> {
                'Contact.Id',
                'Contact.Name',
                'Contact.Customer_Contact_Role__c'
            })
            .executeQuery();

        acrsByContactId = AquivaHelper.groupByIdField(List<AccountContactRole>.class, resultACRsAfterUpdate, 'ContactId');
        for (Id contactId : acrsByContactId.keySet()) {
            List<AccountContactRole> acrsForContact = acrsByContactId.get(contactId);

            for (AccountContactRole acr : acrsForContact) {
                if (acr.Role.contains('Influencer')) {
                    System.assertEquals(true, acr.Contact.Customer_Contact_Role__c.contains('Influencer'));
                }
            }
        }

        delete acrsToUpdate;
        List<AccountContactRole> resultACRsAfterDelete = new AccountContactRoleSelector()
            .selectAccountContactRolesById(new Map<Id, AccountContactRole>(acrs).keySet())
            .selectFields(new List<String> {
                'Contact.Id',
                'Contact.Name',
                'Contact.Customer_Contact_Role__c'
            })
            .executeQuery();

        acrsByContactId = AquivaHelper.groupByIdField(List<AccountContactRole>.class, resultACRsAfterDelete, 'ContactId');
        for (Id contactId : acrsByContactId.keySet()) {
            List<AccountContactRole> acrsForContact = acrsByContactId.get(contactId);

            for (AccountContactRole acr : acrsForContact) {
                System.debug(acr);
                if (new Map<Id, AccountContactRole>(acrsToUpdate).containsKey(acr.Id)) {
                    System.assertEquals(false, acr.Contact.Customer_Contact_Role__c.contains('Influencer'));
                }
            }
        }
    }
}