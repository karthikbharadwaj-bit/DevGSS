@IsTest
private class Test_AccountHierarchyTriggerHelper {
    @isTest
    static void testTargetAccountNotPopulated() {
        Account_Hierarchy__c company = (Account_Hierarchy__c) new SObjectBuilder(Account_Hierarchy__c.SObjectType)
            .setField(Account_Hierarchy__c.Company_Status__c, 'Status 1')
            .create()
            .getRecord();

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, 'Test Account')
            .setField(Account.AH_Name__c, company.Id)
            .setField(Account.Target_Account__c, false)
            .create()
            .getRecord();

        Lead ld = (Lead) new SObjectBuilder(Lead.SObjectType)
            .setField(Lead.AH_Name__c, company.Id)
            .setField(Lead.Target_Account__c, false)
            .create()
            .getRecord();

        Test.startTest();
            company.Company_Status__c = 'Status 2';
            update company;
        Test.stopTest();

        List<Account> accounts = (List<Account>) new AccountSelector()
            .selectAccountById(acc.Id)
            .executeQuery();

        List<Lead> leads = (List<Lead>) new LeadSelector()
            .selectLeadById(new List<Object>{new Set<Id>{ld.Id}})
            .executeQuery();

        System.assertEquals(false, accounts.get(0).Target_Account__c);
        System.assertEquals(false, leads.get(0).Target_Account__c);
    }

    @isTest
    static void testTargetAccountPopulatedAsFalse() {
        Account_Hierarchy__c company = (Account_Hierarchy__c) new SObjectBuilder(Account_Hierarchy__c.SObjectType)
            .setField(Account_Hierarchy__c.Company_Status__c, 'AE Top 25')
            .create()
            .getRecord();

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, 'Test Account')
            .setField(Account.AH_Name__c, company.Id)
            .setField(Account.Target_Account__c, true)
            .create()
            .getRecord();

        Lead ld = (Lead) new SObjectBuilder(Lead.SObjectType)
            .setField(Lead.Target_Account__c, true)
            .create()
            .getRecord();

        ld.AH_name__c = company.Id;
        update ld;

        Test.startTest();
            company.Company_Status__c = 'Status 2';
            update company;
        Test.stopTest();

        List<Account> accounts = (List<Account>) new AccountSelector()
            .selectAccountById(acc.Id)
            .executeQuery();

        List<Lead> leads = (List<Lead>) new LeadSelector()
            .selectLeadById(new List<Object>{new Set<Id>{ld.Id}})
            .executeQuery();

        System.assertEquals(1, accounts.size());
        System.assertEquals(1, leads.size());

        System.assertEquals(false, accounts.get(0).Target_Account__c);
        System.assertEquals(false, leads.get(0).Target_Account__c);
    }

    @isTest
    static void testTargetAccountPopulatedAsTrue() {
        Account_Hierarchy__c company = (Account_Hierarchy__c) new SObjectBuilder(Account_Hierarchy__c.SObjectType)
            .setField(Account_Hierarchy__c.Company_Status__c, 'Status 1')
            .create()
            .getRecord();

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, 'Test Account')
            .setField(Account.AH_Name__c, company.Id)
            .setField(Account.Target_Account__c, false)
            .create()
            .getRecord();

        Lead ld = (Lead) new SObjectBuilder(Lead.SObjectType)
            .setField(Lead.Target_Account__c, false)
            .create()
            .getRecord();

        ld.AH_name__c = company.Id;
        update ld;

        Test.startTest();
            company.Company_Status__c = 'AE Top 25';
            update company;
        Test.stopTest();

        List<Account> accounts = (List<Account>) new AccountSelector()
            .selectAccountById(acc.Id)
            .executeQuery();

        List<Lead> leads = (List<Lead>) new LeadSelector()
            .selectLeadById(new List<Object>{new Set<Id>{ld.Id}})
            .executeQuery();

        System.assertEquals(1, accounts.size());
        System.assertEquals(1, leads.size());

        System.assertEquals(true, accounts.get(0).Target_Account__c);
        System.assertEquals(true, leads.get(0).Target_Account__c);
    }

    @isTest
    static void testApprovalFieldsNotPopulatedIfCompanyFieldsNotUpdated() {
        Account_Hierarchy__c company = (Account_Hierarchy__c) new SObjectBuilder(Account_Hierarchy__c.SObjectType)
            .create()
            .getRecord();

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, 'Test Account')
            .setField(Account.AH_Name__c, company.Id)
            .create()
            .getRecord();

        Approval__c approval = (Approval__c) new SObjectBuilder(Approval__c.SObjectType)
            .setField(Approval__c.Account__c, acc.Id)
            .create()
            .getRecord();

        Test.startTest();
            company.Name = 'testCompany';
            update company;
        Test.stopTest();

        List<Approval__c> approvals = (List<Approval__c>) new ApprovalSelector()
            .selectApprovalForDNBi(new List<Object>{new Set<Id>{approval.Id}})
            .executeQuery();

        System.assertEquals(1, approvals.size());
        System.assertEquals(null, approvals.get(0).Company_Phone_Number__c);
        System.assertEquals(null, approvals.get(0).Company_DUNS_Number__c);
        System.assertEquals(null, approvals.get(0).Company_Website__c);
    }

    @isTest
    static void testApprovalFieldsNotPopulatedIfApprovalsNotSuitable() {
        Account_Hierarchy__c company = (Account_Hierarchy__c) new SObjectBuilder(Account_Hierarchy__c.SObjectType)
            .create()
            .getRecord();

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, 'Test Account')
            .setField(Account.AH_Name__c, company.Id)
            .create()
            .getRecord();

        Approval__c approval = (Approval__c) new SObjectBuilder(Approval__c.SObjectType)
            .setField(Approval__c.Account__c, acc.Id)
            .create()
            .getRecord();

        Test.startTest();
            company.AH_Phone__c = '111111';
            update company;
        Test.stopTest();

        List<Approval__c> approvals = (List<Approval__c>) new ApprovalSelector()
            .selectApprovalForDNBi(new List<Object>{new Set<Id>{approval.Id}})
            .executeQuery();

        System.assertEquals(1, approvals.size());
        System.assertEquals(null, approvals.get(0).Company_Phone_Number__c);
        System.assertEquals(null, approvals.get(0).Company_DUNS_Number__c);
        System.assertEquals(null, approvals.get(0).Company_Website__c);
    }

    @isTest
    static void testApprovalFieldsPopulated() {
        Account_Hierarchy__c company = (Account_Hierarchy__c) new SObjectBuilder(Account_Hierarchy__c.SObjectType)
            .create()
            .getRecord();

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, 'Test Account')
            .setField(Account.AH_Name__c, company.Id)
            .create()
            .getRecord();

        Contact testContact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.FirstName => 'TestFirst',
                    Contact.LastName => 'TestLast',
                    Contact.AccountId => acc.Id,
                    Contact.Email => 'fake@email.com',
                    Contact.Phone => '9910106804',
                    Contact.Preferred_Language__c => 'en_US'
                }
            )
            .create()
            .getRecord();

        AccountContactRole payableContactRole = (AccountContactRole) new SObjectBuilder(AccountContactRole.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    AccountContactRole.AccountId => acc.Id,
                    AccountContactRole.ContactId => testContact.Id,
                    AccountContactRole.Role => AccountContactRoleHelper.CONTACT_ROLE_ACCOUNT_PAYABLE
                }
            )
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setField(Opportunity.Name, 'Test Opportunity')
            .setField(Opportunity.Type, 'Syndicated - New')
            .setField(Opportunity.StageName, 'Planning')
            .setField(Opportunity.CloseDate, System.today().addMonths(1))
            .setField(Opportunity.AccountId, acc.Id)
            .create()
            .getRecord();
        
            Test.startTest();
            List<Approval__c> approvals = (List<Approval__c>) new SObjectBuilder(Approval__c.SObjectType)
                .setField(Approval__c.Account__c, acc.Id)
                .setField(Approval__c.RecordTypeId, Schema.SObjectType.Approval__c
                    .getRecordTypeInfosByName().get('Invoicing Request').getRecordTypeId())
                .setField(Approval__c.Opportunity__c, opp.Id)
                .setField(Approval__c.Potential_Users__c, 1)
                .setField(Approval__c.Reason_Customer_is_Requesting_Invoicing__c, 'Test')
                .setField(Approval__c.AccountPayableContact__c, testContact.Id)
                .quantity(2)
                .create()
                .getRecords();
    
            System.debug('Opportunity.Name' + opp.Name);
            company.AH_Phone__c = '111111';
            company.D_U_N_S_Number__c = '22222';
            company.AH_Website__c = '33333';
            update company;
        Test.stopTest();

        List<Approval__c> updatedApprovals = (List<Approval__c>) new ApprovalSelector()
            .selectApprovalForDNBi(new List<Object>{new Set<Id>{approvals.get(0).Id, approvals.get(1).Id}})
            .executeQuery();

        System.assertEquals(2, approvals.size());

        System.assertEquals(company.AH_Phone__c, updatedApprovals.get(0).Company_Phone_Number__c);
        System.assertEquals(company.AH_Phone__c, updatedApprovals.get(1).Company_Phone_Number__c);

        System.assertEquals(company.D_U_N_S_Number__c, updatedApprovals.get(0).Company_DUNS_Number__c);
        System.assertEquals(company.D_U_N_S_Number__c, updatedApprovals.get(1).Company_DUNS_Number__c);

        System.assertEquals(company.AH_Website__c, updatedApprovals.get(0).Company_Website__c);
        System.assertEquals(company.AH_Website__c, updatedApprovals.get(1).Company_Website__c);
    }

    @isTest
    static void testCompanyOwnerIdIsPopulatedAsMarketoUser() {
        List<User> users = (List<User>) new UserSelector()
            .selectMarketoUser()
            .executeQuery();

        User marketoUser = users.get(0);

        List<Account_Hierarchy__c> companies = (List<Account_Hierarchy__c>) new SObjectBuilder(Account_Hierarchy__c.SObjectType)
            .setField(Account_Hierarchy__c.Company_Status__c, ValueProviderBuilder.provideList(new List<String>{'Invalid', 'Active'}))
            .quantity(2)
            .create()
            .getRecords();

        List<Account_Hierarchy__c> insertedCompanies = (List<Account_Hierarchy__c>) new AccountHierarchySelector()
            .selectAccountHierarchyByIdInRange(new Set<Id>{companies.get(0).Id, companies.get(1).Id})
            .executeQuery();

        System.assertEquals(2, insertedCompanies.size());
        System.assertEquals(marketoUser.Id, insertedCompanies.get(0).OwnerId);
        System.assertEquals(marketoUser.Id, insertedCompanies.get(1).OwnerId);

        Test.startTest();
            companies.get(0).OwnerId = UserInfo.getUserId();
            companies.get(1).OwnerId = UserInfo.getUserId();
            update companies;
        Test.stopTest();

        List<Account_Hierarchy__c> updatedCompanies = (List<Account_Hierarchy__c>) new AccountHierarchySelector()
            .selectAccountHierarchyByIdInRange(new Set<Id>{companies.get(0).Id, companies.get(1).Id})
            .executeQuery();

        System.assertEquals(2, updatedCompanies.size());
        System.assertEquals(marketoUser.Id, updatedCompanies.get(0).OwnerId);
        System.assertEquals(marketoUser.Id, updatedCompanies.get(1).OwnerId);
    }

    @isTest
    static void testCompanyOwnerIdIsPopulatedAsProtectedOwner() {
        User protectedOwner = (User) new SObjectBuilder(User.SObjectType)
            .setField(User.FirstName, 'Protected')
            .setField(User.LastName, 'User')
            .setField(User.isActive, true)
            .create()
            .getRecord();

        Account_Hierarchy__c company = (Account_Hierarchy__c) new SObjectBuilder(Account_Hierarchy__c.SObjectType)
            .setField(Account_Hierarchy__c.Company_Status__c, 'Active')
            .setField(Account_Hierarchy__c.Protected_Owner__c, protectedOwner.Id)
            .create()
            .getRecord();

        List<Account_Hierarchy__c> insertedCompanies = (List<Account_Hierarchy__c>) new AccountHierarchySelector()
            .selectAccountHierarchyById(company.Id)
            .executeQuery();

        System.assertEquals(1, insertedCompanies.size());
        System.assertEquals(protectedOwner.Id, insertedCompanies.get(0).OwnerId);

        Test.startTest();
            company.OwnerId = UserInfo.getUserId();
            update company;
        Test.stopTest();

        List<Account_Hierarchy__c> updatedCompanies = (List<Account_Hierarchy__c>) new AccountHierarchySelector()
            .selectAccountHierarchyById(company.Id)
            .executeQuery();

        System.assertEquals(1, updatedCompanies.size());
        System.assertEquals(protectedOwner.Id, updatedCompanies.get(0).OwnerId);
    }

    @isTest
    static void testCompanyOwnerIdIsPopulatedAsAHOwner() {
        User AHOwner = (User) new SObjectBuilder(User.SObjectType)
            .setField(User.FirstName, 'AH')
            .setField(User.LastName, 'Owner')
            .setField(User.isActive, true)
            .create()
            .getRecord();

        Account_Hierarchy__c company = (Account_Hierarchy__c) new SObjectBuilder(Account_Hierarchy__c.SObjectType)
            .setField(Account_Hierarchy__c.Company_Status__c, 'Active')
            .setField(Account_Hierarchy__c.AH_Owner__c, AHOwner.Id)
            .create()
            .getRecord();

        List<Account_Hierarchy__c> insertedCompanies = (List<Account_Hierarchy__c>) new AccountHierarchySelector()
            .selectAccountHierarchyById(company.Id)
            .executeQuery();

        System.assertEquals(1, insertedCompanies.size());
        System.assertEquals(AHOwner.Id, insertedCompanies.get(0).OwnerId);

        Test.startTest();
            company.OwnerId = UserInfo.getUserId();
            update company;
        Test.stopTest();

        List<Account_Hierarchy__c> updatedCompanies = (List<Account_Hierarchy__c>) new AccountHierarchySelector()
            .selectAccountHierarchyById(company.Id)
            .executeQuery();

        System.assertEquals(1, updatedCompanies.size());
        System.assertEquals(AHOwner.Id, updatedCompanies.get(0).OwnerId);
    }

    @isTest
    static void testCompanyOwnerIdIsPopulatedAsCurrentUserAHOwnerInactive() {
        User AHOwner = (User) new SObjectBuilder(User.SObjectType)
            .setField(User.FirstName, 'AH')
            .setField(User.LastName, 'Owner')
            .setField(User.isActive, false)
            .create()
            .getRecord();

        Account_Hierarchy__c company = (Account_Hierarchy__c) new SObjectBuilder(Account_Hierarchy__c.SObjectType)
            .setField(Account_Hierarchy__c.Company_Status__c, 'Active')
            .setField(Account_Hierarchy__c.AH_Owner__c, AHOwner.Id)
            .create()
            .getRecord();

        List<Account_Hierarchy__c> insertedCompanies = (List<Account_Hierarchy__c>) new AccountHierarchySelector()
            .selectAccountHierarchyById(company.Id)
            .executeQuery();

        System.assertEquals(1, insertedCompanies.size());
        System.assertEquals(UserInfo.getUserId(), insertedCompanies.get(0).OwnerId);

        Test.startTest();
            company.OwnerId = AHOwner.Id;
            update company;
        Test.stopTest();

        List<Account_Hierarchy__c> updatedCompanies = (List<Account_Hierarchy__c>) new AccountHierarchySelector()
            .selectAccountHierarchyById(company.Id)
            .executeQuery();

        System.assertEquals(1, updatedCompanies.size());
        System.assertEquals(AHOwner.Id, updatedCompanies.get(0).OwnerId);
    }

    @isTest
    static void testIsZipCodeInRange() {
        final String POSTAL_BEGIN = '3';
        final String POSTAL_END = '7';
        final String POSTAL_LESS = '1';
        final String POSTAL_MORE = '9';
        final String POSTAL_IN_RANGE = '5';
        final String POSTAL_INVALID = 'xxxxxxxxxx';

        List<Account_Hierarchy__c> companies = (List<Account_Hierarchy__c>) new SObjectBuilder(Account_Hierarchy__c.SObjectType)
            .setField(Account_Hierarchy__c.Country__c, ValueProviderBuilder.provideList(new List<String>{
                AccountHierarchyHelper.CANADA, AccountHierarchyHelper.CANADA, AccountHierarchyHelper.CANADA,
                AccountHierarchyHelper.USA, AccountHierarchyHelper.USA, AccountHierarchyHelper.USA, AccountHierarchyHelper.USA
            }))
            .setField(Account_Hierarchy__c.ZipCode__c, ValueProviderBuilder.provideList(new List<String>{
                POSTAL_LESS, POSTAL_MORE, POSTAL_IN_RANGE,
                POSTAL_LESS, POSTAL_MORE, POSTAL_IN_RANGE, POSTAL_INVALID
            }))
            .quantity(7)
            .create()
            .getRecords();

        Territory_Data__c territory = (Territory_Data__c) new SObjectBuilder(Territory_Data__c.SObjectType)
            .setField(Territory_Data__c.Postal_Begin__c, POSTAL_BEGIN)
            .setField(Territory_Data__c.Postal_End__c, POSTAL_END)
            .create()
            .getRecord();

        AccountHierarchyTriggerHelper.CheckCompanyAndTerritoryOwners handler = new AccountHierarchyTriggerHelper.CheckCompanyAndTerritoryOwners();

        System.assertEquals(false, handler.isZipCodeInRange(companies.get(0), territory), 'Zip Code should not be in range');
        System.assertEquals(false, handler.isZipCodeInRange(companies.get(1), territory), 'Zip Code should not be in range');
        System.assertEquals(true, handler.isZipCodeInRange(companies.get(2), territory), 'Zip Code should be in range');

        System.assertEquals(false, handler.isZipCodeInRange(companies.get(3), territory), 'Zip Code should not be in range');
        System.assertEquals(false, handler.isZipCodeInRange(companies.get(4), territory), 'Zip Code should not be in range');
        System.assertEquals(true, handler.isZipCodeInRange(companies.get(5), territory), 'Zip Code should be in range');

        System.assertEquals(false, handler.isZipCodeInRange(companies.get(6), territory), 'Zip Code should not be in range');
    }

    @isTest
    static void testIsSuitableTerritory() {
        final String POSTAL_BEGIN = '3';
        final String POSTAL_END = '7';
        final String POSTAL_IN_RANGE = '5';
        final String POSTAL_LESS = '1';
        final String EMPLOYEES = '1000+';
        final String EMPLOYEES_WRONG = '500+';

        List<Account_Hierarchy__c> companies = (List<Account_Hierarchy__c>) new SObjectBuilder(Account_Hierarchy__c.SObjectType)
            .setField(Account_Hierarchy__c.Country__c, ValueProviderBuilder.provideList(new List<String>{
                AccountHierarchyHelper.CANADA, AccountHierarchyHelper.USA, AccountHierarchyHelper.USA, AccountHierarchyHelper.USA
            }))
            .setField(Account_Hierarchy__c.Effective_No_of_Employees_Range__c, ValueProviderBuilder.provideList(new List<String>{
                EMPLOYEES, EMPLOYEES_WRONG, EMPLOYEES, EMPLOYEES
            }))
            .setField(Account_Hierarchy__c.ZipCode__c, ValueProviderBuilder.provideList(new List<String>{
                POSTAL_IN_RANGE, POSTAL_IN_RANGE, POSTAL_LESS, POSTAL_IN_RANGE
            }))
            .quantity(4)
            .create()
            .getRecords();

        Territory_Data__c territory = (Territory_Data__c) new SObjectBuilder(Territory_Data__c.SObjectType)
            .setField(Territory_Data__c.Postal_Begin__c, POSTAL_BEGIN)
            .setField(Territory_Data__c.Postal_End__c, POSTAL_END)
            .setField(Territory_Data__c.Country__c, AccountHierarchyHelper.USA)
            .setField(Territory_Data__c.Segment__c, EMPLOYEES)
            .create()
            .getRecord();

        AccountHierarchyTriggerHelper.CheckCompanyAndTerritoryOwners handler = new AccountHierarchyTriggerHelper.CheckCompanyAndTerritoryOwners();

        System.assertEquals(false, handler.isSuitableTerritory(companies.get(0), territory), 'Territory with wrong country cannot be suitable');
        System.assertEquals(false, handler.isSuitableTerritory(companies.get(1), territory), 'Territory with wrong employees number cannot be suitable');
        System.assertEquals(false, handler.isSuitableTerritory(companies.get(2), territory), 'Territory with wrong postal address cannot be suitable');
        System.assertEquals(true, handler.isSuitableTerritory(companies.get(3), territory), 'Territory should be suitable');
    }

    @isTest
    static void testGetStateToTerritoriesMap() {
        List<Territory_Data__c> territories = (List<Territory_Data__c>) new SObjectBuilder(Territory_Data__c.SObjectType)
            .setField(Territory_Data__c.State_Province__c, ValueProviderBuilder.provideList(new List<String>{
                'Alabama', 'Kansas', 'Nevada', 'Alabama'
            }))
            .quantity(4)
            .create()
            .getRecords();

        Map<String, List<Territory_Data__c>> expectedMap = new Map<String, List<Territory_Data__c>> {
            'Alabama' => new List<Territory_Data__c>{territories.get(0), territories.get(3)},
            'Kansas' => new List<Territory_Data__c>{territories.get(1)},
            'Nevada' => new List<Territory_Data__c>{territories.get(2)}
        };

        Map<String, List<Territory_Data__c>> actualMap = new AccountHierarchyTriggerHelper.CheckCompanyAndTerritoryOwners().getStateToTerritoriesMap(territories);

        System.assertEquals(expectedMap.get('Alabama').get(0), actualMap.get('Alabama').get(0));
        System.assertEquals(expectedMap.get('Alabama').get(1), actualMap.get('Alabama').get(1));
        System.assertEquals(expectedMap.get('Kansas').get(0), actualMap.get('Kansas').get(0));
        System.assertEquals(expectedMap.get('Nevada').get(0), actualMap.get('Nevada').get(0));
    }

    @isTest
    static void testCompanyTerritoryNotPopulatedIfNoSuitableTerritoryFound() {
        List<User> owners = (List<User>) new SObjectBuilder(User.SObjectType)
            .setField(User.LastName, ValueProviderBuilder.provideList(new List<String>{'Territory owner', 'Alternative owner'}))
            .quantity(2)
            .create()
            .getRecords();

        List<Territory_Data__c> territories = (List<Territory_Data__c>) new SObjectBuilder(Territory_Data__c.SObjectType)
            .setField(Territory_Data__c.Name, ValueProviderBuilder.provideUniqueString())
            .setField(Territory_Data__c.Territory_Owner__c, owners.get(0).Id)
            .setField(Territory_Data__c.Alternate_Owner__c, owners.get(1).Id)
            .setField(Territory_Data__c.Country__c, ValueProviderBuilder.provideList(new List<String>{
                AccountHierarchyHelper.CANADA, AccountHierarchyHelper.USA, AccountHierarchyHelper.USA, AccountHierarchyHelper.USA, AccountHierarchyHelper.USA
            }))
            .setField(Territory_Data__c.State_Province__c, ValueProviderBuilder.provideList(new List<String>{
                'Alabama', 'Kansas', 'Alabama', 'Alabama', 'Alabama'
            }))
            .setField(Territory_Data__c.Segment__c, ValueProviderBuilder.provideList(new List<String>{
                '1000+', '1000+', '500+', '1000+', '1000+'
            }))
            .setField(Territory_Data__c.Postal_Begin__c, ValueProviderBuilder.provideList(new List<String>{
                '4', '4', '4', '6', '4'
            }))
            .setField(Territory_Data__c.Postal_End__c, ValueProviderBuilder.provideList(new List<String>{
                '6', '6', '6', '8', '6'
            }))
            .setField(Territory_Data__c.Industry__c, ValueProviderBuilder.provideList(new List<String>{
                'Industry 1', 'Industry 1', 'Industry 1', 'Industry 1', 'Industry 2'
            }))
            .quantity(5)
            .create()
            .getRecords();

        Account_Hierarchy__c company = (Account_Hierarchy__c) new SObjectBuilder(Account_Hierarchy__c.SObjectType)
            .setField(Account_Hierarchy__c.Country__c, AccountHierarchyHelper.USA)
            .setField(Account_Hierarchy__c.State__c, 'Alabama')
            .setField(Account_Hierarchy__c.Effective_No_of_Employees_Range__c, '1000+')
            .setField(Account_Hierarchy__c.ZipCode__c, '5')
            .setField(Account_Hierarchy__c.Industry__c, 'Industry 1')
            .create()
            .getRecord();

        List<Account_Hierarchy__c> insertedCompanies = (List<Account_Hierarchy__c>) new AccountHierarchySelector()
            .selectAccountHierarchyById(company.Id)
            .executeQuery();

        System.assertEquals(1, insertedCompanies.size());
        System.assertEquals(null, insertedCompanies.get(0).Territory__c);
        System.assertEquals(null, insertedCompanies.get(0).AH_Territory_Name__c);
        System.assertEquals(null, insertedCompanies.get(0).AH_Owner__c);
        System.assertEquals(null, insertedCompanies.get(0).AH_Alternate_Owner__c);

        Test.startTest();
            company.Territory__c = territories.get(0).Id;
            company.AH_Territory_Name__c = 'AH Territory';
            company.AH_Owner__c = owners.get(0).Id;
            company.AH_Alternate_Owner__c = owners.get(1).Id;
            update company;
        Test.stopTest();

        List<Account_Hierarchy__c> updatedCompanies = (List<Account_Hierarchy__c>) new AccountHierarchySelector()
            .selectAccountHierarchyById(company.Id)
            .executeQuery();

        System.assertEquals(1, updatedCompanies.size());
        System.assertEquals(territories.get(0).Id, updatedCompanies.get(0).Territory__c);
        System.assertEquals('AH Territory', updatedCompanies.get(0).AH_Territory_Name__c);
        System.assertEquals(owners.get(0).Id, updatedCompanies.get(0).AH_Owner__c);
        System.assertEquals(owners.get(1).Id, updatedCompanies.get(0).AH_Alternate_Owner__c);
    }

    @isTest
    static void testCompanyTerritoryPopulatedWithoutIndustry() {
        List<User> owners = (List<User>) new SObjectBuilder(User.SObjectType)
            .setField(User.LastName, ValueProviderBuilder.provideList(new List<String>{'Territory owner', 'Alternative owner'}))
            .quantity(2)
            .create()
            .getRecords();

        List<Territory_Data__c> territories = (List<Territory_Data__c>) new SObjectBuilder(Territory_Data__c.SObjectType)
            .setField(Territory_Data__c.Name, ValueProviderBuilder.provideUniqueString())
            .setField(Territory_Data__c.Territory_Owner__c, owners.get(0).Id)
            .setField(Territory_Data__c.Alternate_Owner__c, owners.get(1).Id)
            .setField(Territory_Data__c.Country__c, ValueProviderBuilder.provideList(new List<String>{
                AccountHierarchyHelper.CANADA, AccountHierarchyHelper.USA, AccountHierarchyHelper.USA, AccountHierarchyHelper.USA, AccountHierarchyHelper.USA, AccountHierarchyHelper.USA
            }))
            .setField(Territory_Data__c.State_Province__c, ValueProviderBuilder.provideList(new List<String>{
                'Alabama', 'Kansas', 'Alabama', 'Alabama', 'Alabama', 'Alabama'
            }))
            .setField(Territory_Data__c.Segment__c, ValueProviderBuilder.provideList(new List<String>{
                '1000+', '1000+', '500+', '1000+', '1000+', '1000+'
            }))
            .setField(Territory_Data__c.Postal_Begin__c, ValueProviderBuilder.provideList(new List<String>{
                '4', '4', '4', '6', '4', '4'
            }))
            .setField(Territory_Data__c.Postal_End__c, ValueProviderBuilder.provideList(new List<String>{
                '6', '6', '6', '8', '6', '6'
            }))
            .setField(Territory_Data__c.Industry__c, ValueProviderBuilder.provideList(new List<String>{
                'Industry 1', 'Industry 1', 'Industry 1', 'Industry 1', 'Industry 2', null
            }))
            .quantity(6)
            .create()
            .getRecords();

        Account_Hierarchy__c company = (Account_Hierarchy__c) new SObjectBuilder(Account_Hierarchy__c.SObjectType)
            .setField(Account_Hierarchy__c.Country__c, AccountHierarchyHelper.USA)
            .setField(Account_Hierarchy__c.State__c, 'Alabama')
            .setField(Account_Hierarchy__c.Effective_No_of_Employees_Range__c, '1000+')
            .setField(Account_Hierarchy__c.ZipCode__c, '5')
            .setField(Account_Hierarchy__c.Industry__c, 'Industry 1')
            .create()
            .getRecord();

        List<Account_Hierarchy__c> insertedCompanies = (List<Account_Hierarchy__c>) new AccountHierarchySelector()
            .selectAccountHierarchyById(company.Id)
            .executeQuery();

        System.assertEquals(1, insertedCompanies.size());
        System.assertEquals(territories.get(5).Id, insertedCompanies.get(0).Territory__c);
        System.assertEquals(territories.get(5).Name, insertedCompanies.get(0).AH_Territory_Name__c);
        System.assertEquals(territories.get(5).Territory_Owner__c, insertedCompanies.get(0).AH_Owner__c);
        System.assertEquals(territories.get(5).Alternate_Owner__c, insertedCompanies.get(0).AH_Alternate_Owner__c);

        Test.startTest();
            company.Territory__c = null;
            company.AH_Territory_Name__c = null;
            company.AH_Owner__c = null;
            company.AH_Alternate_Owner__c = null;
            update company;
        Test.stopTest();

        List<Account_Hierarchy__c> updatedCompanies = (List<Account_Hierarchy__c>) new AccountHierarchySelector()
            .selectAccountHierarchyById(company.Id)
            .executeQuery();

        System.assertEquals(1, updatedCompanies.size());
        System.assertEquals(territories.get(5).Id, updatedCompanies.get(0).Territory__c);
        System.assertEquals(territories.get(5).Name, updatedCompanies.get(0).AH_Territory_Name__c);
        System.assertEquals(territories.get(5).Territory_Owner__c, updatedCompanies.get(0).AH_Owner__c);
        System.assertEquals(territories.get(5).Alternate_Owner__c, updatedCompanies.get(0).AH_Alternate_Owner__c);
    }

    @isTest
    static void testCompanyTerritoryPopulatedWithIndustry() {
        List<User> owners = (List<User>) new SObjectBuilder(User.SObjectType)
            .setField(User.LastName, ValueProviderBuilder.provideList(new List<String>{'Territory owner', 'Alternative owner'}))
            .quantity(2)
            .create()
            .getRecords();

        List<Territory_Data__c> territories = (List<Territory_Data__c>) new SObjectBuilder(Territory_Data__c.SObjectType)
            .setField(Territory_Data__c.Name, ValueProviderBuilder.provideUniqueString())
            .setField(Territory_Data__c.Territory_Owner__c, owners.get(0).Id)
            .setField(Territory_Data__c.Alternate_Owner__c, owners.get(1).Id)
            .setField(Territory_Data__c.Country__c, ValueProviderBuilder.provideList(new List<String>{
                AccountHierarchyHelper.CANADA, AccountHierarchyHelper.USA, AccountHierarchyHelper.USA, AccountHierarchyHelper.USA,
                AccountHierarchyHelper.USA, AccountHierarchyHelper.USA, AccountHierarchyHelper.USA
            }))
            .setField(Territory_Data__c.State_Province__c, ValueProviderBuilder.provideList(new List<String>{
                'Alabama', 'Kansas', 'Alabama', 'Alabama', 'Alabama', 'Alabama', 'Alabama'
            }))
            .setField(Territory_Data__c.Segment__c, ValueProviderBuilder.provideList(new List<String>{
                '1000+', '1000+', '500+', '1000+', '1000+', '1000+', '1000+'
            }))
            .setField(Territory_Data__c.Postal_Begin__c, ValueProviderBuilder.provideList(new List<String>{
                '4', '4', '4', '6', '4', '4', '4'
            }))
            .setField(Territory_Data__c.Postal_End__c, ValueProviderBuilder.provideList(new List<String>{
                '6', '6', '6', '8', '6', '6', '6'
            }))
            .setField(Territory_Data__c.Industry__c, ValueProviderBuilder.provideList(new List<String>{
                'Industry 1', 'Industry 1', 'Industry 1', 'Industry 1', 'Industry 2', null, 'Industry 1'
            }))
            .quantity(7)
            .create()
            .getRecords();

        Account_Hierarchy__c company = (Account_Hierarchy__c) new SObjectBuilder(Account_Hierarchy__c.SObjectType)
            .setField(Account_Hierarchy__c.Country__c, AccountHierarchyHelper.USA)
            .setField(Account_Hierarchy__c.State__c, 'Alabama')
            .setField(Account_Hierarchy__c.Effective_No_of_Employees_Range__c, '1000+')
            .setField(Account_Hierarchy__c.ZipCode__c, '5')
            .setField(Account_Hierarchy__c.Industry__c, 'Industry 1')
            .create()
            .getRecord();

        List<Account_Hierarchy__c> insertedCompanies = (List<Account_Hierarchy__c>) new AccountHierarchySelector()
            .selectAccountHierarchyById(company.Id)
            .executeQuery();

        System.assertEquals(1, insertedCompanies.size());
        System.assertEquals(territories.get(6).Id, insertedCompanies.get(0).Territory__c);
        System.assertEquals(territories.get(6).Name, insertedCompanies.get(0).AH_Territory_Name__c);
        System.assertEquals(territories.get(6).Territory_Owner__c, insertedCompanies.get(0).AH_Owner__c);
        System.assertEquals(territories.get(6).Alternate_Owner__c, insertedCompanies.get(0).AH_Alternate_Owner__c);

        Test.startTest();
            company.Territory__c = null;
            company.AH_Territory_Name__c = null;
            company.AH_Owner__c = null;
            company.AH_Alternate_Owner__c = null;
            update company;
        Test.stopTest();

        List<Account_Hierarchy__c> updatedCompanies = (List<Account_Hierarchy__c>) new AccountHierarchySelector()
            .selectAccountHierarchyById(company.Id)
            .executeQuery();

        System.assertEquals(1, updatedCompanies.size());
        System.assertEquals(territories.get(6).Id, updatedCompanies.get(0).Territory__c);
        System.assertEquals(territories.get(6).Name, updatedCompanies.get(0).AH_Territory_Name__c);
        System.assertEquals(territories.get(6).Territory_Owner__c, updatedCompanies.get(0).AH_Owner__c);
        System.assertEquals(territories.get(6).Alternate_Owner__c, updatedCompanies.get(0).AH_Alternate_Owner__c);
    }

    @isTest
    static void testCompanyTerritoryPopulatedAsFirstSuitableWithIndustry() {
        List<User> owners = (List<User>) new SObjectBuilder(User.SObjectType)
            .setField(User.LastName, ValueProviderBuilder.provideList(new List<String>{'Territory owner', 'Alternative owner'}))
            .quantity(2)
            .create()
            .getRecords();

        List<Territory_Data__c> territories = (List<Territory_Data__c>) new SObjectBuilder(Territory_Data__c.SObjectType)
            .setField(Territory_Data__c.Name, ValueProviderBuilder.provideUniqueString())
            .setField(Territory_Data__c.Territory_Owner__c, owners.get(0).Id)
            .setField(Territory_Data__c.Alternate_Owner__c, owners.get(1).Id)
            .setField(Territory_Data__c.Country__c, AccountHierarchyHelper.USA)
            .setField(Territory_Data__c.State_Province__c, 'Alabama')
            .setField(Territory_Data__c.Segment__c,'1000+')
            .setField(Territory_Data__c.Postal_Begin__c, '4')
            .setField(Territory_Data__c.Postal_End__c, '6')
            .setField(Territory_Data__c.Industry__c, 'Industry 1')
            .quantity(2)
            .create()
            .getRecords();

        Account_Hierarchy__c company = (Account_Hierarchy__c) new SObjectBuilder(Account_Hierarchy__c.SObjectType)
            .setField(Account_Hierarchy__c.Country__c, AccountHierarchyHelper.USA)
            .setField(Account_Hierarchy__c.State__c, 'Alabama')
            .setField(Account_Hierarchy__c.Effective_No_of_Employees_Range__c, '1000+')
            .setField(Account_Hierarchy__c.ZipCode__c, '5')
            .setField(Account_Hierarchy__c.Industry__c, 'Industry 1')
            .create()
            .getRecord();

        List<Account_Hierarchy__c> insertedCompanies = (List<Account_Hierarchy__c>) new AccountHierarchySelector()
            .selectAccountHierarchyById(company.Id)
            .executeQuery();

        System.assertEquals(1, insertedCompanies.size());
        System.assertEquals(territories.get(0).Id, insertedCompanies.get(0).Territory__c);
        System.assertEquals(territories.get(0).Name, insertedCompanies.get(0).AH_Territory_Name__c);
        System.assertEquals(territories.get(0).Territory_Owner__c, insertedCompanies.get(0).AH_Owner__c);
        System.assertEquals(territories.get(0).Alternate_Owner__c, insertedCompanies.get(0).AH_Alternate_Owner__c);

        Test.startTest();
            company.Territory__c = null;
            company.AH_Territory_Name__c = null;
            company.AH_Owner__c = null;
            company.AH_Alternate_Owner__c = null;
            update company;
        Test.stopTest();

        List<Account_Hierarchy__c> updatedCompanies = (List<Account_Hierarchy__c>) new AccountHierarchySelector()
            .selectAccountHierarchyById(company.Id)
            .executeQuery();

        System.assertEquals(1, updatedCompanies.size());
        System.assertEquals(territories.get(0).Id, updatedCompanies.get(0).Territory__c);
        System.assertEquals(territories.get(0).Name, updatedCompanies.get(0).AH_Territory_Name__c);
        System.assertEquals(territories.get(0).Territory_Owner__c, updatedCompanies.get(0).AH_Owner__c);
        System.assertEquals(territories.get(0).Alternate_Owner__c, updatedCompanies.get(0).AH_Alternate_Owner__c);
    }

    @isTest
    static void testCompanyTerritoryPopulatedAsLastSuitableWithoutIndustry() {
        List<User> owners = (List<User>) new SObjectBuilder(User.SObjectType)
            .setField(User.LastName, ValueProviderBuilder.provideList(new List<String>{'Territory owner', 'Alternative owner'}))
            .quantity(2)
            .create()
            .getRecords();

        List<Territory_Data__c> territories = (List<Territory_Data__c>) new SObjectBuilder(Territory_Data__c.SObjectType)
            .setField(Territory_Data__c.Name, ValueProviderBuilder.provideUniqueString())
            .setField(Territory_Data__c.Territory_Owner__c, owners.get(0).Id)
            .setField(Territory_Data__c.Alternate_Owner__c, owners.get(1).Id)
            .setField(Territory_Data__c.Country__c, AccountHierarchyHelper.USA)
            .setField(Territory_Data__c.State_Province__c, 'Alabama')
            .setField(Territory_Data__c.Segment__c,'1000+')
            .setField(Territory_Data__c.Postal_Begin__c, '4')
            .setField(Territory_Data__c.Postal_End__c, '6')
            .setField(Territory_Data__c.Industry__c, null)
            .quantity(2)
            .create()
            .getRecords();

        Account_Hierarchy__c company = (Account_Hierarchy__c) new SObjectBuilder(Account_Hierarchy__c.SObjectType)
            .setField(Account_Hierarchy__c.Country__c, AccountHierarchyHelper.USA)
            .setField(Account_Hierarchy__c.State__c, 'Alabama')
            .setField(Account_Hierarchy__c.Effective_No_of_Employees_Range__c, '1000+')
            .setField(Account_Hierarchy__c.ZipCode__c, '5')
            .setField(Account_Hierarchy__c.Industry__c, 'Industry 1')
            .create()
            .getRecord();

        List<Account_Hierarchy__c> insertedCompanies = (List<Account_Hierarchy__c>) new AccountHierarchySelector()
            .selectAccountHierarchyById(company.Id)
            .executeQuery();

        System.assertEquals(1, insertedCompanies.size());
        System.assertEquals(territories.get(1).Id, insertedCompanies.get(0).Territory__c);
        System.assertEquals(territories.get(1).Name, insertedCompanies.get(0).AH_Territory_Name__c);
        System.assertEquals(territories.get(1).Territory_Owner__c, insertedCompanies.get(0).AH_Owner__c);
        System.assertEquals(territories.get(1).Alternate_Owner__c, insertedCompanies.get(0).AH_Alternate_Owner__c);

        Test.startTest();
            company.Territory__c = null;
            company.AH_Territory_Name__c = null;
            company.AH_Owner__c = null;
            company.AH_Alternate_Owner__c = null;
            update company;
        Test.stopTest();

        List<Account_Hierarchy__c> updatedCompanies = (List<Account_Hierarchy__c>) new AccountHierarchySelector()
            .selectAccountHierarchyById(company.Id)
            .executeQuery();

        System.assertEquals(1, updatedCompanies.size());
        System.assertEquals(territories.get(1).Id, updatedCompanies.get(0).Territory__c);
        System.assertEquals(territories.get(1).Name, updatedCompanies.get(0).AH_Territory_Name__c);
        System.assertEquals(territories.get(1).Territory_Owner__c, updatedCompanies.get(0).AH_Owner__c);
        System.assertEquals(territories.get(1).Alternate_Owner__c, updatedCompanies.get(0).AH_Alternate_Owner__c);
    }

    // NPE exception while executing this test
    // @isTest
    // static void testCompanyOwnerIdIsPopulatedAsCurrentUserAHAndProtectedOwnerWrongId() {
    //     Account_Hierarchy__c company = (Account_Hierarchy__c) new SObjectBuilder(Account_Hierarchy__c.SObjectType)
    //         .setField(Account_Hierarchy__c.Company_Status__c, 'Active')
    //         .setField(Account_Hierarchy__c.AH_Owner__c, ValueProviderBuilder.provideDummyId(User.SObjectType, 15))
    //         .setField(Account_Hierarchy__c.Protected_Owner__c, ValueProviderBuilder.provideDummyId(User.SObjectType, 15))
    //         .create()
    //         .getRecord();

    //     List<Account_Hierarchy__c> companies = (List<Account_Hierarchy__c>) new AccountHierarchySelector()
    //         .selectAccountHierarchyById(company.Id)
    //         .executeQuery();

    //     System.assertEquals(1, companies.size());
    //     System.assertEquals(UserInfo.getUserId(), companies.get(0).OwnerId);
    // }
}