@isTest
private class Test_AccountSelector {
    //User fields defined
    private static final String USER_FIRST_NAME = 'First Name';
    private static final String USER_LAST_NAME = 'Last Name';
    private static final String USER_EMAIL = 'usertestemailforselector@email.com';
    private static final String USER_USERNAME = 'userName@forAccountSelector.com';

    //Account fields defined
    private static final String ACCOUNT_NAME = 'Master';
    private static final String ACCOUNT_BILLING_ID = '12345';
    private static final String ACCOUNT_PARTNER_ID = '12345';

    //Child accounts fields
    private static final String CHILD_ACCOUNT_NAME = 'Child';
    private static final String CHILD_ACCOUNT_WITH_ULTIMATE = 'Child ultimate';

    //Partner account fields
    private static final String PARTNER_ACCOUNT_NAME = 'Partner';

    //Contact fields defined
    private static final String CONTACT_FIRST_NAME = 'Test1';
    private static final String CONTACT_LAST_NAME = 'Test1';
    private static final String CONTACT_EMAIL = 'test@test.com';
    private static final String CONTACT_PHONE = '1234567890';
    private static final String CONTACT_PREFERRED_LANGUAGE = 'en_US';

    //Child contact fields defined
    private static final String CHILD_CONTACT_FIRST_NAME = 'Test1';
    private static final String CHILD_CONTACT_LAST_NAME = 'Test1';
    private static final String CHILD_CONTACT_EMAIL = 'test@test.com';
    private static final String CHILD_CONTACT_PHONE = '1234567891';
    private static final String CHILD_CONTACT_PREFERRED_LANGUAGE = 'en_US';

    //Opportunity fields defined
    private static final String OPPORTUNITY_NAME = 'Test Opportunity';
    private static final String SALES_OPPORTUNITY_NAME = 'Test Sales Opportunity';
    private static final String OPPORTUNITY_BRAND_NAME = 'RingCentral';
    private static final String OPPORTUNITY_TIER_NAME = 'Office';
    private static final String OPPORTUNITY_CURRENCY_ISO_CODE = 'USD';

    //Quote fields defined
    private static final String MASTER_QUOTE_NAME = 'Master Quote';
    private static final String CHILD_QUOTE_NAME = 'Child Quote';
    private static final String QUOTE_FOR_APPROVAL_NAME = 'Test Quote';

    //Approval fields defined
    private static final String APPROVAL_NAME = 'approvedTaxApproval';

    //Assert messages
    private static final String ASSERT_MESSAGE = 'Accounts should be selected';
    private static final String ASSERT_EQUALS_MESSAGE = 'Wrong accounts selected';
    private static final String QUOTE_ASSERT_EQUALS_MESSAGE = 'Quotes should be selected';
    private static final String FIELDS_ASSERT_MESSAGE = 'Fields should be selected';

    private static void assertAccountSelector(QueryFactory factory, String selectorName, String expectedWhereClause, Integer bindingSize) {
        String query = factory.getQuery();

        Assert.areNotEqual(null, factory, getAssertMessageForSelector(selectorName, 'must return Account QueryFactory'));
        Assert.areNotEqual(true, String.isBlank(query), getAssertMessageForSelector(selectorName, 'must compose a string query'));
        Assert.areEqual(true, query.contains(expectedWhereClause), getAssertMessageForSelector(selectorName, 'must have the right WHERE clause'));
        Assert.areEqual(bindingSize, factory.bindings.size(), getAssertMessageForSelector(selectorName, 'must have ' + String.valueOf(bindingSize) + ' input binding variable'));
    }

    private static void assertBindings(QueryFactory factory, String selectorName, List<Object> expectedBindings) {
        Assert.areEqual(expectedBindings, factory.bindings, getAssertMessageForSelector(selectorName, 'must have the right bindings'));
    }

    private static String getAssertMessageForSelector(String selectorName, String assertMessage) {
        return selectorName + ' ' + assertMessage;
    }

    @testSetup
    private static void testData() {

        User testUser = (User) new SObjectBuilder(User.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    User.FirstName => USER_FIRST_NAME,
                    User.LastName => USER_LAST_NAME,
                    User.ProfileId => System.UserInfo.getProfileId(),
                    User.Email => USER_EMAIL,
                    User.isActive => TRUE,
                    User.Username => USER_USERNAME
                }
            )
            .create()
            .getRecord();

        Account testAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => ACCOUNT_NAME,
                    Account.Billing_ID__c => ACCOUNT_BILLING_ID,
                    Account.RecordTypeId => AccountHelper.RT_ID_CUSTOMER_ACCOUNT,
                    Account.Service_Status__c => AccountHelper.SERVICE_STATUS_CONTRACT_COMPLETE,
                    Account.Partner_ID__c => ACCOUNT_PARTNER_ID
                }
            )
            .create()
            .getRecord();

        Contact testContact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.FirstName => CONTACT_FIRST_NAME,
                    Contact.LastName => CONTACT_LAST_NAME,
                    Contact.AccountId => testAcc.Id,
                    Contact.Email => CONTACT_EMAIL,
                    Contact.Phone => CONTACT_PHONE,
                    Contact.Preferred_Language__c => CONTACT_PREFERRED_LANGUAGE
                }
            )
            .create()
            .getRecord();

        Account testChildAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => CHILD_ACCOUNT_NAME,
                    Account.Master_Account__c => testAcc.Id
                }
            )
            .create()
            .getRecord();

        Account testChildAccountWithUltimate = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => CHILD_ACCOUNT_WITH_ULTIMATE,
                    Account.Account.Ultimate_Account__c => testAcc.Id
                }
            )
            .build()
            .getRecord();

        Account testPartner = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => PARTNER_ACCOUNT_NAME,
                    Account.Partner_Account__c => testAcc.Id,
                    Account.RC_User_ID__c => testUser.Id
                }
            )
            .build()
            .getRecord();

        insert new List<Account> {testChildAccountWithUltimate, testPartner};

        AccountContactRole testAccountContactRole = (AccountContactRole) new SObjectBuilder(AccountContactRole.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    AccountContactRole.AccountId => testAcc.Id,
                    AccountContactRole.ContactId => testContact.Id,
                    AccountContactRole.IsPrimary => true,
                    AccountContactRole.Role => AccountContactRoleHelper.CONTACT_ROLE_SIGNATORY
                }
            )
            .create()
            .getRecord();

        Contact testChildContact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.FirstName => CHILD_CONTACT_FIRST_NAME,
                    Contact.LastName => CHILD_CONTACT_LAST_NAME,
                    Contact.AccountId => testChildAccount.Id,
                    Contact.Email => CHILD_CONTACT_EMAIL,
                    Contact.Phone => CHILD_CONTACT_PHONE,
                    Contact.Preferred_Language__c => CHILD_CONTACT_PREFERRED_LANGUAGE
                }
            )
            .create()
            .getRecord();

        Triggers.switchOff();

        Opportunity testOpportunity = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.Name => OPPORTUNITY_NAME,
                    Opportunity.Type => OpportunityHelper.OPPORTUNITY_TYPE_SYNDICATED_NEW,
                    Opportunity.StageName => OpportunityHelper.STAGE_NAME_PLANNING,
                    Opportunity.CloseDate => system.today().addMonths(1),
                    Opportunity.AccountId => testChildAccount.Id,
                    Opportunity.Primary_Opportunity_Contact__c => testChildContact.Id
                }
            )
            .create()
            .getRecord();

        Quote masterQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    Quote.Name => MASTER_QUOTE_NAME,
                    Quote.OpportunityId => testOpportunity.Id,
                    Quote.Status => QuoteHelper.QUOTE_STATUS_DRAFT,
                    Quote.Approved_Status__c => QuoteHelper.APPROVAL_STATUS_NOT_REQUIRED,
                    Quote.Total_Number_of_Digital_Lines__c => 1,
                    Quote.Start_Date__c => Date.today(),
                    Quote.End_Date__c => Date.today().addDays(2),
                    Quote.isPrimary__c => TRUE,
                   	Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING
                }
            )
            .create()
            .getRecord();
		Triggers.switchOn();

        Quote childQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    Quote.Name => CHILD_QUOTE_NAME,
                    Quote.OpportunityId => testOpportunity.Id,
                    Quote.Status => QuoteHelper.QUOTE_STATUS_DRAFT,
                    Quote.Approved_Status__c => QuoteHelper.APPROVAL_STATUS_NOT_REQUIRED,
                    Quote.Total_Number_of_Digital_Lines__c => 1,
                    Quote.Start_Date__c => Date.today(),
                    Quote.End_Date__c => Date.today().addDays(2),
                    Quote.isPrimary__c => true,
                    Quote.ParentQuote__c => masterQuote.Id,
                    Quote.Account__c => testChildAccount.Id
                }
            )
            .build()
            .getRecord();

        Triggers.switchOff();

        Opportunity opp = (Opportunity) new SobjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.AccountId => testAcc.Id,
                    Opportunity.RecordTypeId => OpportunityHelper.RT_ID_SALES_OPPORTUNITY,
                    Opportunity.Name => SALES_OPPORTUNITY_NAME,
                    Opportunity.Brand_Name__c => OPPORTUNITY_BRAND_NAME,
                    Opportunity.Tier_Name__c => OPPORTUNITY_TIER_NAME,
                    Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                    Opportunity.CloseDate => System.today(),
                    Opportunity.CurrencyIsoCode => OPPORTUNITY_CURRENCY_ISO_CODE
                 })
                .create()
                .getRecord();

        Quote testQuote = (Quote) new SobjectBuilder(Quote.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
            		Quote.Name => QUOTE_FOR_APPROVAL_NAME,
                    Quote.OpportunityId => opp.Id,
                    Quote.Account__c => opp.AccountId,
                    Quote.isPrimary__c => true,
                    Quote.Pricebook2Id => Test.getStandardPricebookId(),
                    Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING
                }
			)
            .build()
            .getRecord();

        insert new List<Quote> {childQuote, testQuote};

        Approval__c testApp = (Approval__c) new SObjectBuilder(Approval__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Approval__c.Name => APPROVAL_NAME,
                    Approval__c.Account__c => testAcc.Id,
                    Approval__c.RecordTypeId => ApprovalHelper.RT_ID_KYC_APPROVAL_REQUEST,
                    Approval__c.Status__c => ApprovalHelper.STATUS_APPROVED,
                	Approval__c.StatusLastModifiedDate__c => System.now(),
                    Approval__c.Opportunity__c => testOpportunity.Id,
                    Approval__c.Quote__c => masterQuote.Id
                }
            )
            .create()
            .getRecord();

        Triggers.switchOn();
    }

    @isTest
    private static void testSelectChildAccById(){
        List<Account> accountByName = (List<Account>) new AccountSelector()
            .selectAccountByName(new List<Object>{new Set<String>{CHILD_ACCOUNT_NAME}})
            .executeQuery();

        List<Account> childAccById = (List<Account>) new AccountSelector()
            .selectChildAccById(new List<Object>{new Set<Id>{accountByName[0].Id}})
            .executeQuery();

        System.assert(childAccById.size() > 0, ASSERT_MESSAGE);
        System.assertEquals(accountByName[0].Id, childAccById[0].id, ASSERT_EQUALS_MESSAGE);
    }

    @isTest
    private static void testSelectChildAccByMasterAccount(){
        List<Account> accountByName = (List<Account>) new AccountSelector()
            .selectAccountByName(new List<Object>{new Set<String>{CHILD_ACCOUNT_NAME}})
            .executeQuery();

        List<Account> childAccByMasterAccount = (List<Account>) new AccountSelector()
            .selectChildAccByMasterAccount(new List<Object>{new Set<Id>{accountByName[0].Master_Account__c}})
            .executeQuery();

        System.assert(childAccByMasterAccount.size() > 0, ASSERT_MESSAGE);
        System.assertEquals(accountByName[0].Id, childAccByMasterAccount[0].id, ASSERT_EQUALS_MESSAGE);
    }

    @isTest
    private static void testSelectAccountsByUltimateAccount(){
        List<Account> accountByName = (List<Account>) new AccountSelector()
            .selectAccountByName(new List<Object>{new Set<String>{ACCOUNT_NAME}})
            .executeQuery();

        List<Account> accountsWithUltimate = (List<Account>) new AccountSelector()
            .selectAccountByName(new List<Object>{new Set<String>{CHILD_ACCOUNT_WITH_ULTIMATE}})
            .executeQuery();

        List<Account> accountsByUltimateAccount = (List<Account>) new AccountSelector()
            .selectAccountsByUltimateAccount(new List<Object>{new Set<Id>{accountByName[0].Id}})
            .executeQuery();

        System.assert(accountsByUltimateAccount.size() > 0, ASSERT_MESSAGE);
        System.assertEquals(accountsWithUltimate[0].Id, accountsByUltimateAccount[0].Id, ASSERT_EQUALS_MESSAGE);
    }

    @isTest
    private static void testSelectBillingAccountsForKYCApproval(){
        List<Account> accountByName = (List<Account>) new AccountSelector()
            .selectAccountByName(new List<Object>{new Set<String>{ACCOUNT_NAME}})
            .executeQuery();

        List<Account> billingAccountsForKYCApproval = (List<Account>) new AccountSelector()
            .selectBillingAccountsForKYCApproval(new List<Object>{new Set<Id>{accountByName[0].Id}})
            .executeQuery();

        System.assert(billingAccountsForKYCApproval.size() > 0, ASSERT_MESSAGE);
        System.assertEquals(accountByName[0].Id, billingAccountsForKYCApproval[0].id, ASSERT_EQUALS_MESSAGE);
    }

    @isTest
    private static void testSelectAccountsForApproval(){
        List<Account> accountByName = (List<Account>) new AccountSelector()
            .selectAccountByName(new List<Object>{new Set<String>{ACCOUNT_NAME}})
            .executeQuery();

        List<Account> accountsForApproval = (List<Account>) new AccountSelector()
            .selectAccountsForApproval(new List<Object>{new Set<Id>{accountByName[0].Id}})
            .executeQuery();

        System.assert(accountsForApproval.size() > 0, ASSERT_MESSAGE);
        System.assertEquals(accountByName[0].Id, accountsForApproval[0].id, ASSERT_EQUALS_MESSAGE);
    }

    @isTest
    private static void testSelectAccountForNewWizard(){
        List<Account> accountByName = (List<Account>) new AccountSelector()
            .selectAccountByName(new List<Object>{new Set<String>{ACCOUNT_NAME}})
            .executeQuery();

        List<Account> accountForNewWizard = (List<Account>) new AccountSelector()
            .selectAccountForNewWizard(accountByName[0].Id)
            .executeQuery();

        System.assert(accountForNewWizard.size() > 0, ASSERT_MESSAGE);
        System.assertEquals(accountByName[0].Id, accountForNewWizard[0].id, ASSERT_EQUALS_MESSAGE);
    }

    @isTest
    private static void testSelectAccountsWithContacts(){
        List<Account> accountByName = (List<Account>) new AccountSelector()
            .selectAccountByName(new List<Object>{new Set<String>{ACCOUNT_NAME}})
            .executeQuery();

        List<Account> accountsWithContacts = (List<Account>) new AccountSelector()
            .selectAccountsWithContacts(new List<Object>{new Set<Id>{accountByName[0].Id}})
            .executeQuery();

        System.assert(accountsWithContacts.size() > 0, ASSERT_MESSAGE);
        System.assertEquals(accountByName[0].Id, accountsWithContacts[0].id, ASSERT_EQUALS_MESSAGE);
    }

    @isTest
    private static void testSelectAccountsForDealDeskCase(){
        List<Account> accountByName = (List<Account>) new AccountSelector()
            .selectAccountByName(new List<Object>{new Set<String>{ACCOUNT_NAME}})
            .executeQuery();

        List<Account> accountsForDealDeskCase = (List<Account>) new AccountSelector()
            .selectAccountsForDealDeskCase(new List<Object>{new Set<Id>{accountByName[0].Id}})
            .executeQuery();

        System.assert(accountsForDealDeskCase.size() > 0, ASSERT_MESSAGE);
        System.assertEquals(accountByName[0].Id, accountsForDealDeskCase[0].id, ASSERT_EQUALS_MESSAGE);
    }

    @isTest
    private static void testSelectAccountByName(){
        List<Account> accountByName = (List<Account>) new AccountSelector()
            .selectAccountByName(new List<Object>{new Set<String>{ACCOUNT_NAME}})
            .executeQuery();

        System.assert(accountByName.size() > 0, ASSERT_MESSAGE);
        System.assertEquals(ACCOUNT_NAME, accountByName[0].Name, ASSERT_EQUALS_MESSAGE);
    }

    @isTest
    private static void testSelectAccountForOpportunityClose(){
        List<Account> accountByName = (List<Account>) new AccountSelector()
            .selectAccountByName(new List<Object>{new Set<String>{ACCOUNT_NAME}})
            .executeQuery();

        List<Account> accountForOpportunityClose = (List<Account>) new AccountSelector()
            .selectAccountForOpportunityClose(new List<Object>{new Set<Id>{accountByName[0].Id}})
            .executeQuery();

        System.assert(accountForOpportunityClose.size() > 0, ASSERT_MESSAGE);
        System.assertEquals(accountByName[0].Id, accountForOpportunityClose[0].id, ASSERT_EQUALS_MESSAGE);
    }

    @isTest
    private static void testSelectChildAccounts(){
        Account testChildAccount = [SELECT Id, Master_Account__c FROM Account WHERE Name =: CHILD_ACCOUNT_NAME LIMIT 1];
        List<Account> childAccounts = (List<Account>) new AccountSelector()
            .selectChildAccounts(new List<Object>{new Set<Id>{testChildAccount.Master_Account__c}})
            .executeQuery();

        System.assert(childAccounts.size() > 0, ASSERT_MESSAGE);
        System.assertEquals(testChildAccount.Id, childAccounts[0].id, ASSERT_EQUALS_MESSAGE);
    }

    @isTest
    private static void testSelectAccountWithLeadConvertFields(){
        List<Account> accountByName = (List<Account>) new AccountSelector()
            .selectAccountByName(new List<Object>{new Set<String>{ACCOUNT_NAME}})
            .executeQuery();

        List<Account> accountWithLeadConvertFields = (List<Account>) new AccountSelector()
            .selectAccountWithLeadConvertFields(accountByName[0].Id)
            .executeQuery();

        System.assert(accountWithLeadConvertFields.size() > 0, ASSERT_MESSAGE);
        System.assertEquals(accountByName[0].Id, accountWithLeadConvertFields[0].id, ASSERT_EQUALS_MESSAGE);
    }

    @isTest
    private static void testSelectPaidAccountWithPackage(){
        List<Account> paidAccountWithPackage = (List<Account>) new AccountSelector()
            .selectPaidAccountWithPackage()
            .executeQuery();

        System.assert(paidAccountWithPackage.size() > 0, ASSERT_MESSAGE);
    }

    @isTest
    private static void testSelectAccounts(){
        List<Account> accounts = (List<Account>) new AccountSelector()
            .selectAccounts()
            .executeQuery();

        System.assert(accounts.size() > 0, ASSERT_MESSAGE);
    }

    @isTest
    private static void testSelectAccountById(){
        List<Account> accountByName = (List<Account>) new AccountSelector()
            .selectAccountByName(new List<Object>{new Set<String>{ACCOUNT_NAME}})
            .executeQuery();

        List<Account> accountById = (List<Account>) new AccountSelector()
            .selectAccountById(accountByName[0].Id)
            .executeQuery();

        System.assert(accountById.size() > 0, ASSERT_MESSAGE);
        System.assertEquals(accountByName[0].Id, accountById[0].id, ASSERT_EQUALS_MESSAGE);
    }

    @isTest
    private static void testSelectAccountsWithActiveSignedContract(){
        List<Account> accountByName = (List<Account>) new AccountSelector()
            .selectAccountByName(new List<Object>{new Set<String>{ACCOUNT_NAME}})
            .executeQuery();

        List<Account> accountsWithActiveSignedContract = (List<Account>) new AccountSelector()
            .selectAccountsWithActiveSignedContract(new List<Object>{new Set<Id>{accountByName[0].Id}})
            .executeQuery();

        System.assert(accountsWithActiveSignedContract.size() > 0, ASSERT_MESSAGE);
        System.assertEquals(accountByName[0].Id, accountsWithActiveSignedContract[0].id, ASSERT_EQUALS_MESSAGE);
    }

    @isTest
    private static void testSelectAccountWithTaxExemptionApprovals(){
        List<Account> accountByName = (List<Account>) new AccountSelector()
            .selectAccountByName(new List<Object>{new Set<String>{ACCOUNT_NAME}})
            .executeQuery();

        List<Account> accountWithTaxExemptionApprovals = (List<Account>) new AccountSelector()
            .selectAccountWithTaxExemptionApprovals(new List<Object>{new Set<Id>{accountByName[0].Id}})
            .executeQuery();

        System.assert(accountWithTaxExemptionApprovals.size() > 0, ASSERT_MESSAGE);
        System.assertEquals(accountByName[0].Id, accountWithTaxExemptionApprovals[0].id, ASSERT_EQUALS_MESSAGE);
    }

    @isTest
    private static void testSelectAccountsWithPackagesById(){
        List<Account> accountByName = (List<Account>) new AccountSelector()
            .selectAccountByName(new List<Object>{new Set<String>{ACCOUNT_NAME}})
            .executeQuery();

        List<Account> accountsWithPackagesById = (List<Account>) new AccountSelector()
            .selectAccountsWithPackagesById(new List<Object>{new Set<Id>{accountByName[0].Id}})
            .executeQuery();

        System.assert(accountsWithPackagesById.size() > 0, ASSERT_MESSAGE);
        System.assertEquals(accountByName[0].Id, accountsWithPackagesById[0].id, ASSERT_EQUALS_MESSAGE);
    }

    @isTest
    private static void testSelectAccountsByUserIds(){
        List<Account> accountByName = (List<Account>) new AccountSelector()
            .selectAccountByName(new List<Object>{new Set<String>{PARTNER_ACCOUNT_NAME}})
            .executeQuery();

        List<Account> accountsByUserIds = (List<Account>) new AccountSelector()
            .selectAccountsByUserIds(new List<Object>{new Set<Id>{accountByName[0].RC_User_ID__c}})
            .executeQuery();

        System.assert(accountsByUserIds.size() > 0, ASSERT_MESSAGE);
        System.assertEquals(accountByName[0].Id, accountsByUserIds[0].id, ASSERT_EQUALS_MESSAGE);
    }

    @isTest
    private static void testSelectAccountWithCaseQueueAssignmentFields(){
        List<Account> accountByName = (List<Account>) new AccountSelector()
            .selectAccountByName(new List<Object>{new Set<String>{ACCOUNT_NAME}})
            .executeQuery();

        List<Account> accountWithCaseQueueAssignmentFields = (List<Account>) new AccountSelector()
            .selectAccountWithCaseQueueAssignmentFields(accountByName[0].Id)
            .executeQuery();

        System.assert(accountWithCaseQueueAssignmentFields.size() > 0, ASSERT_MESSAGE);
        System.assertEquals(accountByName[0].Id, accountWithCaseQueueAssignmentFields[0].Id, ASSERT_EQUALS_MESSAGE);
    }

    @isTest
    private static void testSelectAccountsForParentAccountMap(){
        List<Account> accountByName = (List<Account>) new AccountSelector()
            .selectAccountByName(new List<Object>{new Set<String>{ACCOUNT_NAME}})
            .executeQuery();

        List<Account> accountsForParentAccountMap = (List<Account>) new AccountSelector()
            .selectAccountsForParentAccountMap(new List<Object>{new Set<Id>{accountByName[0].Id}})
            .executeQuery();

        System.assert(accountsForParentAccountMap.size() > 0, ASSERT_MESSAGE);
        System.assertEquals(accountByName[0].Id, accountsForParentAccountMap[0].Id, ASSERT_EQUALS_MESSAGE);
    }

    @isTest
    private static void testSelectAccountWithApprovedKYCApprovals(){
        List<Account> accountByName = (List<Account>) new AccountSelector()
            .selectAccountByName(new List<Object>{new Set<String>{ACCOUNT_NAME}})
            .executeQuery();

        List<Account> accountWithApprovedKYCApprovals = (List<Account>) new AccountSelector()
            .selectAccountWithApprovedKYCApprovals(new List<Object>{new Set<Id>{accountByName[0].Id}})
            .executeQuery();

        System.assert(accountWithApprovedKYCApprovals.size() > 0, ASSERT_MESSAGE);
        System.assertEquals(accountByName[0].Id, accountWithApprovedKYCApprovals[0].Id, ASSERT_EQUALS_MESSAGE);
    }

    @isTest
    private static void testSelectAccountWithKYCApprovals(){
        List<Account> accountByName = (List<Account>) new AccountSelector()
            .selectAccountByName(new List<Object>{new Set<String>{ACCOUNT_NAME}})
            .executeQuery();

        List<Account> accountWithKYCApprovals = (List<Account>) new AccountSelector()
            .selectAccountWithKYCApprovals(new List<Object>{new Set<Id>{accountByName[0].Id}})
            .executeQuery();

        System.assert(accountWithKYCApprovals.size() > 0, ASSERT_MESSAGE);
        System.assertEquals(accountByName[0].Id, accountWithKYCApprovals[0].Id, ASSERT_EQUALS_MESSAGE);
    }

    @isTest
    private static void testSelectAccountsForCaseAPI(){
        List<Account> accountByName = (List<Account>) new AccountSelector()
            .selectAccountByName(new List<Object>{new Set<String>{ACCOUNT_NAME}})
            .executeQuery();

        List<Account> accountsForCaseAPI = (List<Account>) new AccountSelector()
            .selectAccountsForCaseAPI(new Set<Id>{accountByName[0].Id})
            .executeQuery();

        System.assert(accountsForCaseAPI.size() > 0, ASSERT_MESSAGE);
        System.assertEquals(accountByName[0].Id, accountsForCaseAPI[0].Id, ASSERT_EQUALS_MESSAGE);
    }

    @isTest
    private static void testSelectSubBrandId(){
        List<Account> accountByName = (List<Account>) new AccountSelector()
            .selectAccountByName(new List<Object>{new Set<String>{ACCOUNT_NAME}})
            .executeQuery();

        List<Account> subBrandId = (List<Account>) new AccountSelector()
            .selectSubBrandId(new List<Object>{new Set<Id>{accountByName[0].Id}})
            .executeQuery();

        System.assert(subBrandId.size() > 0, ASSERT_MESSAGE);
        System.assertEquals(accountByName[0].Id, subBrandId[0].Id, ASSERT_EQUALS_MESSAGE);
    }

    @isTest
    private static void testSelectAccountForPartnerApproval(){
        List<Account> accountByName = (List<Account>) new AccountSelector()
            .selectAccountByName(new List<Object>{new Set<String>{ACCOUNT_NAME}})
            .executeQuery();

        List<Account> accountForPartnerApproval = (List<Account>) new AccountSelector()
            .selectAccountForPartnerApproval(accountByName[0].Id)
            .executeQuery();

        System.assert(accountForPartnerApproval.size() > 0, ASSERT_MESSAGE);
        System.assertEquals(accountByName[0].Id, accountForPartnerApproval[0].Id, ASSERT_EQUALS_MESSAGE);
    }

    @isTest
    private static void testSelectAccountsWithActiveContract(){
        List<Account> accountByName = (List<Account>) new AccountSelector()
            .selectAccountByName(new List<Object>{new Set<String>{ACCOUNT_NAME}})
            .executeQuery();

        List<Account> accountsWithActiveContract = (List<Account>) new AccountSelector()
            .selectAccountsWithActiveContract(new List<Object>{new Set<Id>{accountByName[0].Id}})
            .executeQuery();

        System.assert(accountsWithActiveContract.size() > 0, ASSERT_MESSAGE);
        System.assertEquals(accountByName[0].Id, accountsWithActiveContract[0].Id, ASSERT_EQUALS_MESSAGE);
    }

    @isTest
    private static void testSelectAccountsByIds(){
        List<Account> accountByName = (List<Account>) new AccountSelector()
            .selectAccountByName(new List<Object>{new Set<String>{ACCOUNT_NAME}})
            .executeQuery();

        List<Account> accountsByIds = (List<Account>) new AccountSelector()
            .selectAccountsByIds(new List<Object>{new Set<Id>{accountByName[0].Id}})
            .executeQuery();

        System.assert(accountsByIds.size() > 0, ASSERT_MESSAGE);
        System.assertEquals(accountByName[0].Id, accountsByIds[0].Id, ASSERT_EQUALS_MESSAGE);
    }

    @isTest
    private static void testSelectChildAccByMasterAccountWithBindedQuotes(){
        List<Account> accountByName = (List<Account>) new AccountSelector()
            .selectAccountByName(new List<Object>{new Set<String>{ACCOUNT_NAME}})
            .executeQuery();

     	List<Account> childAccByMasterAccountWithBindedQuotes = (List<Account>) new AccountSelector()
            .selectChildAccByMasterAccountWithBindedQuotes(new List<Object>{new Set<Id>{accountByName[0].Id}})
            .executeQuery();

        System.assert(childAccByMasterAccountWithBindedQuotes.size() > 0, ASSERT_MESSAGE);
        System.assertEquals(1, childAccByMasterAccountWithBindedQuotes[0].Quotes__r.size(), QUOTE_ASSERT_EQUALS_MESSAGE);
    }

    @isTest
    private static void testSelectAccWithContactByContactId(){
        List<Account> accountByName = (List<Account>) new AccountSelector()
            .selectAccountByName(new List<Object>{new Set<String>{ACCOUNT_NAME}})
            .executeQuery();

        List<Contact> contactsByEmail = (List<Contact>) new ContactSelector()
            .selectContactsByEmail(new List<Object>{new Set<String>{CONTACT_FIRST_NAME},
                                                    new Set<String>{CONTACT_LAST_NAME},
                                                    new Set<String>{CONTACT_EMAIL}})
            .executeQuery();

        Contact testCon = [SELECT Id FROM Contact WHERE Phone =: CONTACT_PHONE LIMIT 1];
        List<Account> accWithContactByContactId = (List<Account>) new AccountSelector()
            .selectAccWithContactByContactId(new List<Object>{new Set<Id>{accountByName[0].Id},
                											  new Set<Id>{contactsByEmail[0].Id},
                                                              new Set<Id>{contactsByEmail[0].Id}})
            .executeQuery();

        System.assert(accWithContactByContactId.size() > 0, ASSERT_MESSAGE);
        System.assertEquals(accountByName[0].Id, accWithContactByContactId[0].Id, ASSERT_EQUALS_MESSAGE);
    }

    @isTest
    private static void testSelectAccountsForOpportunityTrigger(){
        List<Account> accountByName = (List<Account>) new AccountSelector()
            .selectAccountByName(new List<Object>{new Set<String>{ACCOUNT_NAME}})
            .executeQuery();

        List<Account> accountsForOpportunityTrigger = (List<Account>) new AccountSelector()
            .selectAccountsForOpportunityTrigger(new Set<Id>{accountByName[0].Id})
            .executeQuery();

        System.assert(accountsForOpportunityTrigger.size() > 0, ASSERT_MESSAGE);
        System.assertEquals(accountByName[0].Id, accountsForOpportunityTrigger[0].Id, ASSERT_EQUALS_MESSAGE);
    }

    @isTest
    private static void testGetAccountWithLeadConvertFields(){
        List<Account> accountByName = (List<Account>) new AccountSelector()
            .selectAccountByName(new List<Object>{new Set<String>{ACCOUNT_NAME}})
            .executeQuery();

        Account accountWithLeadConvertFields = AccountSelector.getAccountWithLeadConvertFields(accountByName[0].Id);

        System.assertEquals(accountByName[0].Id, accountWithLeadConvertFields.Id, ASSERT_EQUALS_MESSAGE);
    }

    @isTest
    private static void testSelectBoundAccountsByIdOrMasterAccountId(){
        List<Account> accountByName = (List<Account>) new AccountSelector()
            .selectAccountByName(new List<Object>{new Set<String>{ACCOUNT_NAME}})
            .executeQuery();

        List<Account> boundAccountsByIdOrMasterAccountId = (List<Account>) new AccountSelector()
            .selectBoundAccountsByIdOrMasterAccountId(new List<Object>{new Set<Id>{accountByName[0].Id}})
            .executeQuery();

        System.assert(boundAccountsByIdOrMasterAccountId.size() > 0, ASSERT_MESSAGE);

        Boolean isAccountPresentInList = false;
        for (Account currentAcc: boundAccountsByIdOrMasterAccountId) {
            if (currentAcc.Id == accountByName[0].Id) {
                isAccountPresentInList = true;
                break;
            }
        }

        System.assert(isAccountPresentInList, ASSERT_EQUALS_MESSAGE);
    }

    @isTest
    private static void testSelectAccWithContactByContact(){
        List<Account> accountByName = (List<Account>) new AccountSelector()
            .selectAccountByName(new List<Object>{new Set<String>{ACCOUNT_NAME}})
            .executeQuery();

        List<Account> accWithContactByContact = (List<Account>) new AccountSelector()
            .selectAccWithContactByContact(new List<Object>{new Set<Id>{accountByName[0].Id},
                											new Set<String>{CONTACT_LAST_NAME},
                                                            new Set<String>{CONTACT_PHONE},
                                                            new Set<String>{CONTACT_LAST_NAME},
                                                            new Set<String>{CONTACT_PHONE}})
            .executeQuery();

        System.assert(accWithContactByContact.size() > 0, ASSERT_MESSAGE);
        System.assertEquals(accountByName[0].Id, accWithContactByContact[0].Id, ASSERT_EQUALS_MESSAGE);
    }

    @isTest
    private static void testSelectAccountsWithLastModifiedApprovals(){
        List<Account> accountByName = (List<Account>) new AccountSelector()
            .selectAccountByName(new List<Object>{new Set<String>{CHILD_ACCOUNT_NAME}})
            .executeQuery();

        List<Opportunity> opportunityByName = (List<Opportunity>) new OpportunitySelector()
            .selectOpportunityByName(OPPORTUNITY_NAME)
            .executeQuery();

        List<Account> accountsWithLastModifiedApprovals = (List<Account>) new AccountSelector()
            .selectAccountsWithLastModifiedApprovals(new List<Object>{new Set<Id>{accountByName[0].Id},
                													  new Set<Id>{opportunityByName[0].Id}},
                                                     QuoteHelper.RT_ID_BILLING)
            .executeQuery();

        System.assert(accountsWithLastModifiedApprovals.size() > 0, ASSERT_MESSAGE);
        System.assertEquals(accountByName[0].Id, accountsWithLastModifiedApprovals[0].Id, ASSERT_EQUALS_MESSAGE);
    }

    @isTest
    private static void testSelectAccountDefault(){
        List<Account> accountDefault = (List<Account>) new AccountSelector(true, true)
            .selectAccountDefault('Name = \'Master\'')
            .executeQuery();

        System.assert(accountDefault.size() > 0, ASSERT_MESSAGE);
		System.assertEquals(ACCOUNT_NAME, accountDefault[0].Name, ASSERT_EQUALS_MESSAGE);
    }

    @isTest
    private static void testSelectPartnerAccountsByIds(){
        List<Account> accountByName = (List<Account>) new AccountSelector()
            .selectAccountByName(new List<Object>{new Set<String>{PARTNER_ACCOUNT_NAME}})
            .executeQuery();

        List<Account> partnerAccountsByIds = (List<Account>) new AccountSelector()
            .selectPartnerAccountsByIds(new List<Object>{new Set<Id>{accountByName[0].Id}})
            .executeQuery();

        System.assert(partnerAccountsByIds.size() > 0, ASSERT_MESSAGE);
		System.assertEquals(accountByName[0].Id, partnerAccountsByIds[0].Id, ASSERT_EQUALS_MESSAGE);
    }

    @isTest
    private static void testSelectAccountsWithOrderedKYCApprovalsExcludingApprovalRecords(){
        List<Account> accountByName = (List<Account>) new AccountSelector()
            .selectAccountByName(new List<Object>{new Set<String>{ACCOUNT_NAME}})
            .executeQuery();

        List<Approval__c> approvalsForAccount = (List<Approval__c>) new ApprovalSelector()
            .selectApprovalsForAccount(new List<Object>{new Set<Id>{accountByName[0].Id}})
            .executeQuery();

        List<Account> accountsWithOrderedKYCApprovalsExcludingApprovalRecords = (List<Account>) new AccountSelector()
            .selectAccountsWithOrderedKYCApprovalsExcludingApprovalRecords(new Set<Id>{accountByName[0].Id}, new Set<Id>{approvalsForAccount[0].Id})
            .executeQuery();

        System.assert(accountsWithOrderedKYCApprovalsExcludingApprovalRecords.size() > 0, ASSERT_MESSAGE);
        System.assertEquals(accountByName[0].Id, accountsWithOrderedKYCApprovalsExcludingApprovalRecords[0].Id, ASSERT_EQUALS_MESSAGE);
    }

    @isTest
    private static void testGetFieldLists(){
        List<Schema.SObjectField> approvalFieldList = (List<Schema.SObjectField>) new AccountSelector().getApprovalFieldList();
        System.assert(approvalFieldList.size() > 0, 'Fields must be retrieved');

        List<Schema.SObjectField> otherFieldList = (List<Schema.SObjectField>) new AccountSelector().getOtherFieldList();
        System.assert(otherFieldList.size() > 0, 'Fields must be retrieved');
    }

    @isTest
    private static void testSelectTechAccountsWithActiveAgreementsRecords(){
        Account accountByName = (Account) new ListOptional((List<Account>) new AccountSelector()
            .selectAccountByName(new List<Object>{new Set<String>{ACCOUNT_NAME}})
            .executeQuery()).getFirst();
        Triggers.switchOff();
        update new Account(
            Id = accountByName.Id,
            IsMultiProductTechnicalAccount__c = true,
            RC_Account_Status__c = AccountHelper.ACCOUNT_STATUS_TERMINATED
        );
        Triggers.switchOn();
        Test.startTest();
        Account reselectedAccount = (Account) new ListOptional((List<Account>) new AccountSelector()
            .selectTechnicalAccounts(new List<Object>{new List<Id>{ accountByName.Id }})
            .executeQuery()).getFirst();
        Test.stopTest();

        System.assert(reselectedAccount != null, 'Selector returned value');
        System.assertEquals(accountByName.Id, reselectedAccount.Id, 'Selector returned the same account');
        System.assertEquals(reselectedAccount.IsMultiProductTechnicalAccount__c, true, 'Reselected Account must be technical account');
    }

    @isTest
    static void testSelectAccountsByBillingIdOrRCUserId() {
        String billingId = '111111';
        String rcUserId = '222222';

        Test.startTest();
            QueryFactory selectAccountsByBillingIdOrRCUserIdFactory = new AccountSelector()
                .selectAccountsByBillingIdOrRCUserId(billingId, rcUserId)
                .setQuery();
        Test.stopTest();

        String expectedWhereClause = 'FROM Account WHERE Billing_ID__c = :bind0 OR RC_User_ID__c = :bind1';

        System.assertNotEquals(null, selectAccountsByBillingIdOrRCUserIdFactory, 'Selector must return QuoteFactory');
        System.assert(!String.isBlank(selectAccountsByBillingIdOrRCUserIdFactory.getQuery()), 'Selector must compose a string query');
        System.assertEquals(true, selectAccountsByBillingIdOrRCUserIdFactory.getQuery().contains(expectedWhereClause), 'Selector must have the right WHERE clause');
        System.assertEquals(2, selectAccountsByBillingIdOrRCUserIdFactory.bindings.size(), 'Selector must have 2 input binding variables');
        System.assertEquals(billingId, selectAccountsByBillingIdOrRCUserIdFactory.bindings[0], 'Selector must have the same billingId input');
        System.assertEquals(rcUserId, selectAccountsByBillingIdOrRCUserIdFactory.bindings[1], 'Selector must have the same RC_User_Id input');
    }

    @isTest
    static void testSelectMPTechAccountsByMasterIdsWithSetInput() {
        Id dummyMasterAccId = (Id) new ValueProvider.DummyIdProvider(Account.sObjectType).getValue();

        Test.startTest();
            QueryFactory factoryWithSetInput = new AccountSelector()
                .selectMPTechAccountsByMasterIds(new Set<Id> {dummyMasterAccId})
                .setQuery();
        Test.stopTest();

        assertWhereClauseForMPTechAccountsByMasterIds(factoryWithSetInput.getQuery());
        Assert.isTrue(
            ((List<Id>) factoryWithSetInput.bindings[0]).contains(dummyMasterAccId),
            'The input Master Account Id should be preserved'
        );
    }

    @isTest
    static void testSelectMPTechAccountsByMasterIdsWithSingleIdInput() {
        Id dummyMasterAccId = (Id) new ValueProvider.DummyIdProvider(Account.sObjectType).getValue();

        Test.startTest();
            QueryFactory factoryWithSingleIdInput = new AccountSelector()
                .selectMPTechAccountsByMasterIds(dummyMasterAccId)
                .setQuery();
        Test.stopTest();

        assertWhereClauseForMPTechAccountsByMasterIds(factoryWithSingleIdInput.getQuery());
        Assert.isTrue(
            ((List<Id>) factoryWithSingleIdInput.bindings[0]).contains(dummyMasterAccId),
            'The input Master Account Id should be preserved'
        );
    }

    @isTest
    static void testSelectMPTechAccountsByIdsForCopying() {
        Id dummyMasterAccId = (Id) new ValueProvider.DummyIdProvider(Account.sObjectType).getValue();

        Test.startTest();
            QueryFactory factory = new AccountSelector()
                .selectMPTechAccountsByIdsForCopying(new List<Id> {dummyMasterAccId})
                .setQuery();
        Test.stopTest();

        String resultedQuery = factory.getQuery();
        Assert.isTrue(
            ((List<Id>) factory.bindings[0]).contains(dummyMasterAccId),
            'The input Account Id must be preserved'
        );
        Assert.isTrue(
            resultedQuery.contains('Id IN :bind0'),
            'The selector must retrieve results by Ids'
        );
        Assert.isTrue(
            resultedQuery.contains('IsMultiProductTechnicalAccount__c = true'),
            'The selector must return only Technical Accounts'
        );
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testSelectAccountsByIdsWithBillingAccountPackages() {
        Id dummyAccId = (Id) new ValueProvider.DummyIdProvider(Account.sObjectType).getValue();

        Test.startTest();
            QueryFactory factory = new AccountSelector()
                .selectAccountsByIdsWithBillingAccountPackages(new List<Id> {dummyAccId})
                .setQuery();
        Test.stopTest();

        assertFactoryForSelectAccountsByIdsWithBillingAccountPackages(factory, dummyAccId);
    }

    @isTest
    static void testSelectAccountsByIdsWithTechnicalAccounts() {
        Id dummyAccId = (Id) new ValueProvider.DummyIdProvider(Account.sObjectType).getValue();

        Test.startTest();
            QueryFactory factory = new AccountSelector()
                .selectAccountsByIdsWithTechnicalAccounts(new List<Id> {dummyAccId})
                .setQuery();
        Test.stopTest();

        String resultedQuery = factory.getQuery();
        Assert.isTrue(
            ((List<Id>) factory.bindings[0]).contains(dummyAccId),
            'The input Account Id must be preserved'
        );
        Assert.isTrue(
            resultedQuery.contains('Id IN :bind0'),
            'The selector must filter results by input AccountIds'
        );
        Assert.isTrue(
            resultedQuery.contains('IsMultiProductTechnicalAccount__c = false'),
            'The selector must not return any of multiproduct technical accounts'
        );
        Assert.isTrue(
            factory.getSelectedFields().containsAll(AccountSelector.FIELDS_AGGREGATED_TOTALS),
            'The selector must return fields with aggregated totals.'
        );

        QueryFactory technicalAccountSubQueryFactory = (QueryFactory) new ListOptional(factory.getSubselectQueries()).getFirst();
        Assert.isNotNull(technicalAccountSubQueryFactory, 'The selector must have a subquery');
        Assert.areEqual(
            Account.sObjectType,
            technicalAccountSubQueryFactory.sObjType,
            'The selector must select related Accounts as well'
        );
        Assert.isTrue(
            technicalAccountSubQueryFactory.getSelectedFields().containsAll(AccountSelector.FIELDS_AGGREGATED_TOTALS),
            'The returned child technical Accounts must have fields with aggregated totals.'
        );
    }

    @isTest
    static void testSelectAccountsByIdsWithBillingAccountPackagesReportedMRSDependants() {
        Id dummyAccId = (Id) new ValueProvider.DummyIdProvider(Account.sObjectType).getValue();

        Test.startTest();
            QueryFactory factory = new AccountSelector()
                .selectAccountsByIdsWithBillingAccountPackagesReportedMRSDependants(new List<Id> {dummyAccId})
                .setQuery();
        Test.stopTest();

        assertFactoryForSelectAccountsByIdsWithBillingAccountPackages(factory, dummyAccId);
        Assert.isTrue(
            factory.getSelectedFields().containsAll(AccountSelector.FIELDS_REPORTED_MRS_DEPENDANTS),
            'The selector must return fields for reported MRS dependants.'
        );
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testSelectAccountsByIdsWithServiceInfoFields() {
        Id dummyAccId = (Id) new ValueProvider.DummyIdProvider(Account.sObjectType).getValue();

        Test.startTest();
            QueryFactory factory = new AccountSelector()
                .selectAccountsByIdsWithServiceInfoFields(new List<Id> {dummyAccId})
                .setQuery();
        Test.stopTest();

        assertFactoryForSelectAccountsByIdsWithServiceInfoFields(factory, dummyAccId);
    }

    @isTest
    static void testSelectAccountByIdWithAllFields() {
        Id dummyAccId = (Id) new ValueProvider.DummyIdProvider(Account.sObjectType).getValue();

        Test.startTest();
            QueryFactory factory = new AccountSelector()
                .selectAccountByIdWithAllFields(dummyAccId)
                .setQuery();
        Test.stopTest();

        String resultedQuery = factory.getQuery();
        Assert.isTrue(
            factory.getSelectedFields().containsAll(AccountSelector.FIELDS_SERVICE_INFO),
            'The selector must return service info fields.'
        );
        Assert.isTrue(
            resultedQuery.contains('Id = :bind0'),
            'The selector must filter results by a single Account.Id'
        );
        Assert.isTrue(
            ((Set<Id>) factory.bindings[0]).contains(dummyAccId),
            'The input Account Id must be preserved'
        );
    }

    @isTest
    static void testSelectMPAccountsWithTechAccountsAndContactRolesByAcrIds() {
        Id dummyAcrId = (Id) new ValueProvider.DummyIdProvider(AccountContactRole.sObjectType).getValue();

        Test.startTest();
            QueryFactory factory = new AccountSelector()
                .selectMPAccountsWithTechAccountsAndContactRolesByAcrIds(new Set<Id> {dummyAcrId})
                .setQuery();
        Test.stopTest();

        String resultedQuery = factory.getQuery();
        Assert.isTrue(
            resultedQuery.contains('IsMultiProductTechnicalAccount__c = false'),
            'The top selector must not return Technical Accounts'
        );
        Assert.isTrue(
            resultedQuery.contains('Id IN (SELECT AccountId FROM AccountContactRole WHERE Id IN :bind0)'),
            'The selector must return Accounts of the input AccountContactRoles'
        );
        Assert.isTrue(
            ((List<Id>) factory.bindings[0]).contains(dummyAcrId),
            'The input AccountContactRole Id must be preserved'
        );

        Map<Schema.SObjectType, List<QueryFactory>> sObjectTypeToSubQueries = getSObjectTypeToSubQueriesMap(factory);
        Assert.isNotNull(sObjectTypeToSubQueries, 'The selector must have subqueries');
        Assert.isTrue(
            sObjectTypeToSubQueries.containsKey(Account.sObjectType),
            'The selector must return children Accounts'
        );
        Assert.isTrue(
            sObjectTypeToSubQueries.containsKey(AccountContactRole.sObjectType),
            'The selector must return children AccountContactRoles'
        );
        Assert.isTrue(
            sObjectTypeToSubQueries.get(Account.sObjectType)[0].getQuery().contains('IsMultiProductTechnicalAccount__c = true'),
            'The Account subselector must return only Technical Accounts'
        );
    }

    @isTest
    static void testSelectMPTechAccountsWithContactRolesByMasterAccountIds() {
        Id dummyMasterAccId = (Id) new ValueProvider.DummyIdProvider(Account.sObjectType).getValue();

        Test.startTest();
            QueryFactory factory = new AccountSelector()
                .selectMPTechAccountsWithContactRolesByMasterAccountIds(new Set<Id> {dummyMasterAccId})
                .setQuery();
        Test.stopTest();

        String resultedQuery = factory.getQuery();
        Assert.isTrue(
            resultedQuery.contains('Master_Account__c IN :bind0'),
            'The selector must filter results by Master Account Id'
        );
        Assert.isTrue(
            resultedQuery.contains('IsMultiProductTechnicalAccount__c = true'),
            'The selector must return Technical Accounts'
        );
        Assert.isTrue(
            ((List<Id>) factory.bindings[0]).contains(dummyMasterAccId),
            'The input Master Account Id must be preserved'
        );

        QueryFactory accountContactRolesSubFactory = (QueryFactory) new ListOptional(factory.getSubselectQueries()).getFirst();
        Assert.isNotNull(accountContactRolesSubFactory, 'The selector must have a subquery');
        Assert.areEqual(
            AccountContactRole.sObjectType,
            accountContactRolesSubFactory.sObjType,
            'The selector must select related AccountContactRoles as well'
        );
    }

    @isTest
    static void testSelectMPTechAccountsWithContactRolesByAcrIds() {
        Id dummyAcrId = (Id) new ValueProvider.DummyIdProvider(AccountContactRole.sObjectType).getValue();

        Test.startTest();
            QueryFactory factory = new AccountSelector()
                .selectMPTechAccountsWithContactRolesByAcrIds(new Set<Id> {dummyAcrId})
                .setQuery();
        Test.stopTest();

        String resultedQuery = factory.getQuery();
        Assert.isTrue(
            resultedQuery.contains('IsMultiProductTechnicalAccount__c = true'),
            'The selector must return Technical Accounts'
        );
        Assert.isTrue(
            resultedQuery.contains('Master_Account__c IN (SELECT AccountId FROM AccountContactRole WHERE Id IN :bind0)'),
            'The selector must return Accounts based of on the input of AccountContactRole Ids'
        );
        Assert.isTrue(
            ((List<Id>) factory.bindings[0]).contains(dummyAcrId),
            'The input AccountContactRole Id must be preserved'
        );

        QueryFactory accountContactRolesSubFactory = (QueryFactory) new ListOptional(factory.getSubselectQueries()).getFirst();
        Assert.isNotNull(accountContactRolesSubFactory, 'The selector must have a subquery');
        Assert.areEqual(
            AccountContactRole.sObjectType,
            accountContactRolesSubFactory.sObjType,
            'The selector must select related AccountContactRoles as well'
        );
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testSelectCustomerAccountsByPartnerIds() {
        String dummyPartnerId = 'dummyPartnerId';

        Test.startTest();
            QueryFactory factory = new AccountSelector()
                .selectCustomerAccountsByPartnerIds(new Set<String> {dummyPartnerId})
                .setQuery();
        Test.stopTest();

        assertFactoryForSelectAccountsByPartnerIdsAndByRecordTypeName(factory, dummyPartnerId, AccountHelper.RT_NAME_CUSTOMER_ACCOUNT);
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testSelectPartnerAccountsByPartnerIds() {
        String dummyPartnerId = 'dummyPartnerId';

        Test.startTest();
            QueryFactory factory = new AccountSelector()
                .selectPartnerAccountsByPartnerIds(new Set<String> {dummyPartnerId})
                .setQuery();
        Test.stopTest();

        assertFactoryForSelectAccountsByPartnerIdsAndByRecordTypeName(factory, dummyPartnerId, AccountHelper.RT_NAME_PARTNER_ACCOUNT);
    }

    @isTest
    static void testSelectAccountsByTypeAndByPartnerIds() {
        String dummyPartnerId = 'dummyPartnerId';

        Test.startTest();
            QueryFactory factory = new AccountSelector()
                .selectAccountsByTypeAndByPartnerIds(AccountHelper.TYPE_PARTNER, new Set<String> {dummyPartnerId})
                .setQuery();
        Test.stopTest();

        String resultedQuery = factory.getQuery();
        Assert.isTrue(
            resultedQuery.contains('Partner_Id__c IN :bind0'),
            'The selector must filter results by input PartnerIds'
        );
        Assert.isTrue(
            resultedQuery.contains('Type = :bind1'),
            'The selector must filter results by input Record Type'
        );

        Assert.isTrue(
            ((Set<String>) factory.bindings[0]).contains(dummyPartnerId),
            'The input Partner Id must be preserved'
        );
        Assert.areEqual(
            AccountHelper.TYPE_PARTNER,
            factory.bindings[1],
            'The input Type must be preserved'
        );
    }

    @isTest
    static void testSelectMPAccountsWithTaxExemptionApprovals() {
        Id dummyMasterAccId = (Id) new ValueProvider.DummyIdProvider(Account.sObjectType).getValue();

        Test.startTest();
            QueryFactory factory = new AccountSelector()
                .selectMPAccountsWithTaxExemptionApprovals(new List<Object> {new Set<Id> {dummyMasterAccId}})
                .setQuery();
        Test.stopTest();

        Assert.isTrue(
            factory.getQuery().contains('Id IN :bind0 OR Master_Account__c IN :bind0'),
            'The selector must retrieve only Master Accounts and their Technical Accounts'
        );
        Assert.isTrue(
            ((Set<Id>) factory.bindings[0]).contains(dummyMasterAccId),
            'The input Master Account Id must be preserved'
        );

        QueryFactory approvalSubSelector = (QueryFactory) new ListOptional(factory.getSubselectQueries()).getFirst();
        Assert.isNotNull(approvalSubSelector, 'The selector must have a subquery');
        Assert.areEqual(
            Approval__c.sObjectType,
            approvalSubSelector.sObjType,
            'The selector must return related Approvals as well'
        );
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testSelectAccountsByIdNoFields() {
        Id dummyAccId = (Id) new ValueProvider.DummyIdProvider(Account.sObjectType).getValue();

        Test.startTest();
            QueryFactory factory = new AccountSelector()
                .selectAccountsByIdNoFields(new List<Object> {new Set<Id> {dummyAccId}})
                .setQuery();
        Test.stopTest();

        assertFactoryForSelectByAccIds(factory, dummyAccId);
    }

    @isTest
    static void testSelectAccountsByIdForNotification() {
        Id dummyAccId = (Id) new ValueProvider.DummyIdProvider(Account.sObjectType).getValue();

        Test.startTest();
            QueryFactory factory = new AccountSelector()
                .selectAccountsByIdForNotification(new List<Object> {new Set<Id> {dummyAccId}})
                .setQuery();
        Test.stopTest();

        Assert.isTrue(
            ((Set<Id>) factory.bindings[0]).contains(dummyAccId),
            'The input Account Id must be preserved'
        );
        Assert.isTrue(
            factory.getQuery().contains('Id IN: bind0 AND Owner.IsActive = true'),
            'The selector must retrieve results by Ids and active owners'
        );
    }

    @isTest
    static void testSelectAccountsWithContactsAndOpptys() {
        Id dummyAccId = (Id) new ValueProvider.DummyIdProvider(Account.sObjectType).getValue();

        Test.startTest();
            QueryFactory factory = new AccountSelector()
                .selectAccountsWithContactsAndOpptys(new List<Object> {new Set<Id> {dummyAccId}})
                .setQuery();
        Test.stopTest();

        assertFactoryForSelectByAccIds(factory, dummyAccId);

        Map<Schema.SObjectType, List<QueryFactory>> sObjectTypeToSubQueries = getSObjectTypeToSubQueriesMap(factory);
        Assert.isNotNull(sObjectTypeToSubQueries, 'The selector must have subqueries');
        Assert.isTrue(
            sObjectTypeToSubQueries.containsKey(Contact.sObjectType),
            'The selector must also return associated Contacts'
        );
        Assert.isTrue(
            sObjectTypeToSubQueries.containsKey(Opportunity.sObjectType),
            'The selector must also return associated Opportunities'
        );
    }

    @isTest
    static void testSelectPartnerAccountsByIdsAndRT() {
        Id dummyAccId = (Id) new ValueProvider.DummyIdProvider(Account.sObjectType).getValue();

        Test.startTest();
            QueryFactory factory = new AccountSelector()
                .selectPartnerAccountsByIdsAndRT(new List<Object> {new Set<Id> {dummyAccId}})
                .setQuery();
        Test.stopTest();

        Assert.isTrue(
            ((Set<Id>) factory.bindings[0]).contains(dummyAccId),
            'The input Account Id must be preserved'
        );
        Assert.isTrue(
            factory.getQuery().contains('Id IN :bind0 OR Partner_Account__c IN :bind0'),
            'The selector must retrieve Partner Accounts'
        );

        QueryFactory AccountTeamMemberSubSelector = (QueryFactory) new ListOptional(factory.getSubselectQueries()).getFirst();
        Assert.isNotNull(AccountTeamMemberSubSelector, 'The selector must have a subquery');
        Assert.areEqual(
            AccountTeamMember.SObjectType,
            AccountTeamMemberSubSelector.sObjType,
            'The selector must return related AccountTeamMember as well'
        );
    }

    @isTest
    static void testSelectCustomerAccountsByParentSnapshot() {
        Id dummyUltimateParentId = (Id) new ValueProvider.DummyIdProvider(Account.sObjectType).getValue();

        Test.startTest();
            QueryFactory factory = new AccountSelector()
                .selectCustomerAccountsByParentSnapshot(new List<Object> {new Set<Id> {dummyUltimateParentId}})
                .setQuery();
        Test.stopTest();

        Assert.isTrue(
            ((Set<Id>) factory.bindings[0]).contains(dummyUltimateParentId),
            'The input Ultimate Parent Id must be preserved'
        );

        String resultedQuery = factory.getQuery();
        Assert.isTrue(
            resultedQuery.contains('RecordType.Name = \'' + AccountHelper.RT_NAME_CUSTOMER_ACCOUNT + '\''),
            'The selector must retrieve only Customer Accounts'
        );
        Assert.isTrue(
            resultedQuery.contains('Ultimate_Parent_Snapshot__c IN :bind0 OR Id IN :bind0'),
            'The selector must retrieve by Parent Snapshots'
        );
    }

    @isTest
    static void testSelectPartnerAccountsByParentDetail() {
        Id dummyUltimateParentId = (Id) new ValueProvider.DummyIdProvider(Account.sObjectType).getValue();

        Test.startTest();
            QueryFactory factory = new AccountSelector()
                .selectPartnerAccountsByParentDetail(new List<Object> {new Set<Id> {dummyUltimateParentId}})
                .setQuery();
        Test.stopTest();

        Assert.isTrue(
            ((Set<Id>) factory.bindings[0]).contains(dummyUltimateParentId),
            'The input Ultimate Parent Id must be preserved'
        );

        String resultedQuery = factory.getQuery();
        Assert.isTrue(
            resultedQuery.contains('RecordType.Name = \'' + AccountHelper.RT_NAME_PARTNER_ACCOUNT + '\''),
            'The selector must retrieve only Partner Accounts'
        );
        Assert.isTrue(
            resultedQuery.contains('Parent_Detail__c LIKE :bind0'),
            'The selector must retrieve by Parent_Detail__c'
        );
    }

    @isTest
    static void testSelectPartnerAccountsByPartnerId() {
        String dummyPartnerId = 'dummyPartnerId';

        Test.startTest();
            QueryFactory factory = new AccountSelector()
                .selectPartnerAccountsByPartnerId(new List<Object> {new Set<String> {dummyPartnerId}})
                .setQuery();
        Test.stopTest();

        Assert.isTrue(
            ((Set<String>) factory.bindings[0]).contains(dummyPartnerId),
            'The input Ultimate Parent Id must be preserved'
        );

        String resultedQuery = factory.getQuery();
        Assert.isTrue(
            resultedQuery.contains('RecordType.Name = \'' + AccountHelper.RT_NAME_PARTNER_ACCOUNT + '\''),
            'The selector must retrieve only Partner Accounts'
        );
        Assert.isTrue(
            resultedQuery.contains('Partner_ID__c IN :bind0'),
            'The selector must filter results by input PartnerIds'
        );
    }

    @isTest
    static void testSelectCustomerAccountsByParentId() {
        String dummyPartnerId = 'dummyPartnerId';

        Test.startTest();
        QueryFactory factory = new AccountSelector()
            .selectCustomerAccountsByParentId(new List<Object> {new Set<String> {dummyPartnerId}})
            .setQuery();
        Test.stopTest();

        Assert.isTrue(
            ((Set<String>) factory.bindings[0]).contains(dummyPartnerId),
            'The input Ultimate Parent Id must be preserved'
        );

        String resultedQuery = factory.getQuery();
        Assert.isTrue(
            resultedQuery.contains('RecordType.Name = \'' + AccountHelper.RT_NAME_CUSTOMER_ACCOUNT + '\''),
            'The selector must retrieve only Customer Accounts'
        );
        Assert.isTrue(
            resultedQuery.contains('Partner_ID__c IN :bind0'),
            'The selector must filter results by input PartnerIds'
        );
    }

    @isTest
    static void testSelectAccountsForOfficeTrail() {
        Id dummyAccId = (Id) new ValueProvider.DummyIdProvider(Account.sObjectType).getValue();

        Test.startTest();
            QueryFactory factory = new AccountSelector()
                .selectAccountsForOfficeTrail(new List<Object> {new Set<Id> {dummyAccId}})
                .setQuery();
        Test.stopTest();

        assertFactoryForSelectByAccIds(factory, dummyAccId);

        Map<Schema.SObjectType, List<QueryFactory>> sObjectTypeToSubQueries = getSObjectTypeToSubQueriesMap(factory);
        Assert.isNotNull(sObjectTypeToSubQueries, 'The selector must have subqueries');
        Assert.isTrue(
            sObjectTypeToSubQueries.containsKey(Contact.sObjectType),
            'The selector must also return associated Contacts'
        );
        Assert.isTrue(
            sObjectTypeToSubQueries.containsKey(AccountContactRole.sObjectType),
            'The selector must also return associated Account Contact Roles'
        );
        Assert.isTrue(
            sObjectTypeToSubQueries.containsKey(Survey__c.sObjectType),
            'The selector must also return associated Surveys'
        );
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testSelectAccsForTechApprovalValidation() {
        Id dummyAccId = (Id) new ValueProvider.DummyIdProvider(Account.sObjectType).getValue();

        Test.startTest();
            QueryFactory factory = new AccountSelector()
                .selectAccsForTechApprovalValidation(new List<Object> {new Set<Id> {dummyAccId}})
                .setQuery();
        Test.stopTest();

        assertFactoryForSelectByAccIds(factory, dummyAccId);
    }

    @isTest
    static void testSelectAccountsWithFinanceCases() {
        Id dummyAccId = (Id) new ValueProvider.DummyIdProvider(Account.sObjectType).getValue();

        Test.startTest();
            QueryFactory factory = new AccountSelector()
                .selectAccountsWithFinanceCases(new List<Object> {new Set<Id> {dummyAccId}})
                .setQuery();
        Test.stopTest();

        assertFactoryForSelectByAccIds(factory, dummyAccId);

        QueryFactory caseSubSelector = (QueryFactory) new ListOptional(factory.getSubselectQueries()).getFirst();
        Assert.isNotNull(caseSubSelector, 'The selector must have a subquery');
        Assert.areEqual(
            Case.SObjectType,
            caseSubSelector.sObjType,
            'The selector must return related Cases.'
        );
        Assert.isTrue(
            caseSubSelector.getQuery().contains('RecordType.Name = \'' + CaseHelper.RT_NAME_FINANCE + '\''),
            'The Case SubSelector must retrieve only ' + CaseHelper.RT_NAME_FINANCE + ' Cases'
        );
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testSelectAccsForSyncAccountWs() {
        Id dummyAccId = (Id) new ValueProvider.DummyIdProvider(Account.sObjectType).getValue();

        Test.startTest();
            QueryFactory factory = new AccountSelector()
                .selectAccsForSyncAccountWs(new List<Object> {new Set<Id> {dummyAccId}})
                .setQuery();
        Test.stopTest();

        assertFactoryForSelectByAccIds(factory, dummyAccId);
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testSelectAccountsForCase() {
        Id dummyAccId = (Id) new ValueProvider.DummyIdProvider(Account.sObjectType).getValue();

        Test.startTest();
            QueryFactory factory = new AccountSelector()
                .selectAccountsForCase(new List<Object> {new Set<Id> {dummyAccId}})
                .setQuery();
        Test.stopTest();

        assertFactoryForSelectByAccIds(factory, dummyAccId);
    }

    @isTest
    static void testSelectAccountWithAllApprovals() {
        Id dummyAccId = (Id) new ValueProvider.DummyIdProvider(Account.sObjectType).getValue();
        Set<String> approvalTypes = new Set<String> {'ApprovalType1', 'ApprovalType2'};

        Test.startTest();
            QueryFactory factory = new AccountSelector()
                .selectAccountWithAllApprovals(dummyAccId, approvalTypes)
                .setQuery();
        Test.stopTest();

        String resultedQuery = factory.getQuery();
        Assert.isTrue(
            resultedQuery.contains('IsMultiProductTechnicalApproval__c = false'),
            'The selector must not return technical approvals'
        );
        Assert.isTrue(
            resultedQuery.contains('RecordTypeId in :bind1'),
            'The selector must filter results by Record Type'
        );

        Assert.isTrue(
            ((String) factory.bindings[0]).contains(dummyAccId),
            'The input Account Id must be preserved'
        );
    }

    @isTest
    static void testSelectAccountsForConnectServiceAccountToOrder() {
        Id dummyAccId = (Id) new ValueProvider.DummyIdProvider(Account.sObjectType).getValue();

        Test.startTest();
        QueryFactory factory = new AccountSelector()
            .selectAccountsForConnectServiceAccountToOrder(new List<Object> {new Set<Id> {dummyAccId}})
            .setQuery();
        Test.stopTest();

        assertFactoryForSelectByAccIds(factory, dummyAccId);

        Map<Schema.SObjectType, List<QueryFactory>> sObjectTypeToSubQueries = getSObjectTypeToSubQueriesMap(factory);
        Assert.isNotNull(sObjectTypeToSubQueries, 'The selector must have subqueries');
        Assert.isTrue(
            sObjectTypeToSubQueries.containsKey(Order.sObjectType),
            'The selector must also return associated Orders'
        );
    }

    @isTest
    static void testSelectAccountsWithOrdersForOrderActivationMPUB() {
        Id dummyAccId = (Id) new ValueProvider.DummyIdProvider(Account.sObjectType).getValue();
        Id dummyPackageId = (Id) new ValueProvider.DummyIdProvider(Package__c.sObjectType).getValue();

        Test.startTest();
        QueryFactory factory = new AccountSelector()
            .selectAccountsWithOrdersForOrderActivationMPUB(new List<Object> {new Set<Id> {dummyAccId}, new Set<Id> {dummyPackageId}})
            .setQuery();
        Test.stopTest();

        assertFactoryForSelectByAccIds(factory, dummyAccId);

        Map<Schema.SObjectType, List<QueryFactory>> sObjectTypeToSubQueries = getSObjectTypeToSubQueriesMap(factory);
        Assert.isNotNull(sObjectTypeToSubQueries, 'The selector must have subqueries');
        Assert.isTrue(
            sObjectTypeToSubQueries.containsKey(Order.sObjectType),
            'The selector must also return associated Orders'
        );
        Assert.isTrue(
            sObjectTypeToSubQueries.get(Order.sObjectType)[0].getQuery().contains('PackageId__c IN :bind1 ' +
                'AND Status = \'' + OrderHelper.STATUS_NEW + '\' ' +
                'AND Quote.RecordTypeId = \'' + QuoteHelper.RT_ID_BILLING + '\''
            ),
            'The Order subselector must return only New Orders for specific Package'
        );
        Assert.isTrue(
            ((Set<Id>) factory.bindings[1]).contains(dummyPackageId),
            'The input Package Id must be preserved'
        );
        Assert.isTrue(
            sObjectTypeToSubQueries.containsKey(Account.sObjectType),
            'The selector must also return associated tech Accounts'
        );
    }

    @isTest
    static void testSelectAccountForEngagePackageByAccIds() {
        Id dummyAccId = (Id) new ValueProvider.DummyIdProvider(Account.sObjectType).getValue();

        Test.startTest();
            QueryFactory factory = new AccountSelector()
                .selectAccountForEngagePackageByAccIds(new List<Object> {dummyAccId})
                .setQuery();
        Test.stopTest();

        Assert.isTrue(
            factory.bindings.contains(dummyAccId),
            'The input Account Id must be preserved'
        );
        Assert.isTrue(
            factory.getQuery().contains('Id IN :bind0'),
            'The selector must retrieve results by Ids'
        );

        QueryFactory technicalAccountSubQueryFactory = (QueryFactory) new ListOptional(factory.getSubselectQueries()).getFirst();
        Assert.isNotNull(technicalAccountSubQueryFactory, 'The selector must have a subquery');
        Assert.areEqual(
            Account.sObjectType,
            technicalAccountSubQueryFactory.sObjType,
            'The selector must select related Accounts as well'
        );
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testSelectAccsForMarketingAttributionUpdate() {
        Id dummyAccId = (Id) new ValueProvider.DummyIdProvider(Account.sObjectType).getValue();

        Test.startTest();
        QueryFactory factory = new AccountSelector()
            .selectAccsForMarketingAttributionUpdate(new List<Object> {new Set<Id> {dummyAccId}})
            .setQuery();
        Test.stopTest();

        assertFactoryForSelectByAccIds(factory, dummyAccId);
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testSelectAccountsDateFieldsUpdateByAccountIds() {
        Id dummyAccId = (Id) new ValueProvider.DummyIdProvider(Account.sObjectType).getValue();

        Test.startTest();
        QueryFactory factory = new AccountSelector()
            .selectAccountsDateFieldsUpdateByAccountIds(new List<Object> {new Set<Id> {dummyAccId}})
            .setQuery();
        Test.stopTest();

        assertFactoryForSelectByAccIds(factory, dummyAccId);
    }


    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testSelectAccountsWithSinglePackage() {
        Id dummyAccId = (Id) new ValueProvider.DummyIdProvider(Account.sObjectType).getValue();
        String condition;
        Test.startTest();
        QueryFactory factory = new AccountSelector()
            .selectAccountsWithSinglePackage(new List<Id> {dummyAccId}, condition)
            .setQuery();
        Test.stopTest();

        Assert.isTrue(
            ((List<Id>) factory.bindings[0]).contains(dummyAccId),
            'The input Account Id must be preserved'
        );
        Assert.isTrue(
            factory.getQuery().contains('Id IN :bind0'),
            'The selector must retrieve results by Ids'
        );
    }

    private static Map<Schema.SObjectType, List<QueryFactory>> getSObjectTypeToSubQueriesMap(QueryFactory factory) {
        List<QueryFactory> subQueryFactories = factory.getSubselectQueries();
        if (subQueryFactories == null) {
            return null;
        }

        Map<Schema.SObjectType, List<QueryFactory>> resultedMap = new Map<Schema.SObjectType, List<QueryFactory>>();
        for (QueryFactory subFactory : subQueryFactories) {
            if (!resultedMap.containsKey(subFactory.sObjType)) {
                resultedMap.put(subFactory.sObjType, new List<QueryFactory>());
            }

            resultedMap.get(subFactory.sObjType).add(subFactory);
        }

        return resultedMap;
    }

    private static void assertFactoryForSelectByAccIds(QueryFactory factory, Id inputAccId) {
        Assert.isTrue(
            ((Set<Id>) factory.bindings[0]).contains(inputAccId),
            'The input Account Id must be preserved'
        );
        Assert.isTrue(
            factory.getQuery().contains('Id IN :bind0'),
            'The selector must retrieve results by Ids'
        );
    }

    private static void assertWhereClauseForMPTechAccountsByMasterIds(String resultedQuery) {
        Assert.isTrue(
            resultedQuery.contains('Master_Account__c IN :bind0'),
            'The selector must filter results by Master_Account__c'
        );
        Assert.isTrue(
            resultedQuery.contains('IsMultiProductTechnicalAccount__c = true'),
            'The selector must return only Technical Accounts'
        );
    }

    private static void assertFactoryForSelectAccountsByIdsWithServiceInfoFields(QueryFactory factory, Id inputAccId) {
        String resultedQuery = factory.getQuery();
        Assert.isTrue(
            resultedQuery.contains('Id IN :bind0'),
            'The selector must filter results by input AccountIds'
        );
        Assert.isTrue(
            factory.getSelectedFields().containsAll(AccountSelector.FIELDS_SERVICE_INFO),
            'The selector must return service info fields.'
        );
        Assert.isTrue(
            ((List<Id>) factory.bindings[0]).contains(inputAccId),
            'The input Account Id must be preserved'
        );
    }

    private static void assertFactoryForSelectAccountsByIdsWithBillingAccountPackages(QueryFactory factory, Id inputAccId) {
        QueryFactory packageQueryFactory = (QueryFactory) new ListOptional(factory.getSubselectQueries()).getFirst();
        Assert.isNotNull(packageQueryFactory, 'The selector must have a subquery');
        Assert.areEqual(
            Package__c.SObjectType,
            packageQueryFactory.sObjType,
            'The selector must select related Packages as well'
        );
        Assert.isTrue(
            packageQueryFactory.getSelectedFields().containsAll(PackageSelector.FIELDS_STANDARD),
            'Selected packages must have standard fields'
        );
        assertFactoryForSelectAccountsByIdsWithServiceInfoFields(factory, inputAccId);
    }

    private static void assertFactoryForSelectAccountsByPartnerIdsAndByRecordTypeName(QueryFactory factory, String inputPartnerId, String inputRTName) {
        String resultedQuery = factory.getQuery();
        Assert.isTrue(
            resultedQuery.contains('Partner_Id__c IN :bind0'),
            'The selector must filter results by input PartnerIds'
        );
        Assert.isTrue(
            resultedQuery.contains('RecordType.Name = :bind1'),
            'The selector must filter results by input Record Type'
        );

        Assert.isTrue(
            ((Set<String>) factory.bindings[0]).contains(inputPartnerId),
            'The input Partner Id must be preserved'
        );
        Assert.areEqual(
            inputRTName,
            factory.bindings[1],
            'The input RecordType Name must be preserved'
        );
    }

    @isTest
    private static void testselectIncumbentInfoForAccts() {
        List<Account> accountByName = (List<Account>) new AccountSelector()
            .selectAccountByName(new List<Object> {new Set<String> {ACCOUNT_NAME} })
            .executeQuery();

        List<Account> IncumbentInfoForAccts = (List<Account>) new AccountSelector()
            .selectIncumbentInfoForAccts(new List<Object> {new Set<Id> {accountByName[0].Id} })
            .executeQuery();

        Assert.areEqual(true,IncumbentInfoForAccts.size() > 0, ASSERT_MESSAGE);
        Assert.areEqual(accountByName[0].Id, IncumbentInfoForAccts[0].Id, ASSERT_EQUALS_MESSAGE);
    }

    @isTest
    static void testSelectAccountWithServiceRelatedFields() {
        Id dummyAccId = (Id) new ValueProvider.DummyIdProvider(Account.sObjectType).getValue();

        Test.startTest();
        QueryFactory factory = new AccountSelector()
            .selectAccountWithServiceRelatedFields(new List<Object> {new Set<Id> {dummyAccId}})
            .setQuery();
        Test.stopTest();

        assertFactoryForSelectByAccIds(factory, dummyAccId);
        List<QueryFactory> accountManagementSubFactory = (List<QueryFactory>) new List<QueryFactory>(factory.getSubselectQueries());
        Assert.areEqual(5, accountManagementSubFactory.size(), 'The selector must have 5 subqueries');
    }

    @isTest
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    private static void testSelectAccountsForSyncWS() {
        List<Object> bindings = new List<Object>{ '1234' };

        Test.startTest();
            QueryFactory factory = new AccountSelector()
                .selectAccountForSyncWS(bindings)
                .setQuery();
        Test.stopTest();

        String selectorName = 'selectAccountForSyncWS';
        String expectedWhereClause = 'WHERE (RC_User_ID__c != NULL AND RC_User_ID__c = :bind0) ' +
            'OR (Internal_Enterprise_Account_ID__c != NULL AND Internal_Enterprise_Account_ID__c = :bind0)';


        assertAccountSelector(factory, selectorName, expectedWhereClause, 1);
        assertBindings(factory, selectorName, bindings);
    }
}