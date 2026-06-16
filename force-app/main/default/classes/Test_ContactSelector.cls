@isTest
private class Test_ContactSelector {
	//Account fields defined
    private static final String ACCOUNT_NAME = 'TestForSelector';
    private static final String ACCOUNT_RC_ACCOUNT_STATUS = 'Other';

    //Campaign fields defined
    private static final String CAMPAIGN_NAME = 'Test';
    private static final String CAMPAIGN_CATEGORY = 'TestCategory';

   	//Contact fields defined
   	private static final String CONTACT_FIRST_NAME = 'Test';
    private static final String CONTACT_LAST_NAME = 'Test';
    private static final String CONTACT_EMAIL = 'test@test.com';
    private static final String CONTACT_PHONE = '1234567890';
    private static final String CONTACT_PREFFERED_LANGUAGE = 'en_US';
    private static final String CONTACT_SAASQ_CODE = 'SAASQ-CODE';

   	//Opportunity fields defined
   	private static final String OPPORTUNITY_NAME = 'TestOpportunity';
    private static final String OPPORTUNITY_BRAND_NAME = 'RingCentral';
    private static final String OPPORTUNITY_TIER_NAME = 'Office';
    private static final String OPPORTUNITY_CURRENCY_ISO_CODE = 'USD';

    //Assert messages defined
    private static final String ASSERT_MESSAGE = 'Contacts should be selected';
    private static final String ASSERT_EQUALS_MESSAGE = 'Wrong contact selected';

    //Saasquatch Referral Program Mapping fields defined
    private static final String SAASQ_DEVELOPER_NAME = 'MapForUKReferralProgram';
    private static final String SAASQ_MASTER_LEVEL = 'MapForUKReferralProgram';
    private static final String SAASQ_QUALIFIED_API_NAME = 'MapForUKReferralProgram';
    private static final String SAASQ_MESSAGE = 'Contacts should be selected';
    private static final boolean SAASQ_IS_MAP_TO_CONTACT = true;
    private static final String SAASQ_FIELD_API_NAME = 'UK_Saasquatch_Referral_Code__c';
    private static final String SAASQ_PICKLIST_VALUE_TO_MAP = 'UK Referral Programme (external)';

    private static void assertContactSelector(QueryFactory factory, String selectorName, String expectedWhereClause, Integer bindingSize) {
        String query = factory.getQuery();

        Assert.areNotEqual(null, factory, getAssertMessageForSelector(selectorName, 'must return Contact QueryFactory'));
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
        Account testAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => ACCOUNT_NAME,
                    Account.RC_Account_Status__c => ACCOUNT_RC_ACCOUNT_STATUS
                }
            )
            .create()
            .getRecord();

        Campaign  testCamp = (Campaign ) new SObjectBuilder(Campaign.SobjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Campaign.Name => CAMPAIGN_NAME,
                    Campaign.Category__c   => CAMPAIGN_CATEGORY
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
                    Contact.Preferred_Language__c => CONTACT_PREFFERED_LANGUAGE,
                    Contact.Most_Recent_Campaign__c => testCamp.Id,
                    Contact.UK_Saasquatch_Referral_Code__c => CONTACT_SAASQ_CODE
                }
            )
            .create()
            .getRecord();

        Opportunity testOpp = (Opportunity) new SobjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
            		Opportunity.AccountId => testAcc.Id,
            		Opportunity.Name => OPPORTUNITY_NAME,
            		Opportunity.Brand_Name__c => OPPORTUNITY_BRAND_NAME,
            		Opportunity.Tier_Name__c => OPPORTUNITY_TIER_NAME,
            		Opportunity.StageName => OpportunityHelper.STAGE_NAME_CLOSED_WON,
            		Opportunity.CurrencyIsoCode => OPPORTUNITY_CURRENCY_ISO_CODE,
                    Opportunity.Primary_Opportunity_Contact__c => testContact.Id
					}
            )
            .create()
            .getRecord();
    }

    @isTest
    private static void testSelectContacts(){
        List<Contact> contacts = (List<Contact>) new ContactSelector(true, true)
            .selectContacts()
            .executeQuery();

        System.assert(contacts.size() == 1, ASSERT_MESSAGE);
    }

    @isTest
    private static void testSelectContactsByAccountId(){
        List<Contact> contacts = (List<Contact>) new ContactSelector()
            .selectContacts()
            .executeQuery();

        List<Contact> contactsByAccountId = (List<Contact>) new ContactSelector()
            .selectContactsByAccountId(new List<Object>{new Set<Id>{contacts[0].AccountId}})
            .executeQuery();

        System.assert(contactsByAccountId.size() == 1, ASSERT_MESSAGE);
        System.assertEquals(contacts[0].Id, contactsByAccountId[0].Id, ASSERT_EQUALS_MESSAGE);
    }

    @isTest
    private static void testSelectContactsForDFRById(){
        List<Contact> contacts = (List<Contact>) new ContactSelector()
            .selectContacts()
            .executeQuery();

        List<Contact> contactsForDFRById = (List<Contact>) new ContactSelector()
            .selectContactsForDFRById(new List<Object>{new Set<Id>{contacts[0].Id}})
            .executeQuery();

        System.assert(contactsForDFRById.size() == 1, ASSERT_MESSAGE);
        System.assertEquals(contacts[0].Id, contactsForDFRById[0].Id, ASSERT_EQUALS_MESSAGE);
    }

	@isTest
    private static void testSelectContactById(){
        List<Contact> contacts = (List<Contact>) new ContactSelector()
            .selectContacts()
            .executeQuery();

        List<Contact> contactById = (List<Contact>) new ContactSelector()
            .selectContactById(new List<Object>{new Set<Id>{contacts[0].Id}})
            .executeQuery();

        System.assert(contactById.size() == 1, ASSERT_MESSAGE);
        System.assertEquals(contacts[0].Id, contactById[0].Id, ASSERT_EQUALS_MESSAGE);
    }

    @isTest
    private static void testSelectContactsForApproval(){
        List<Contact> contacts = (List<Contact>) new ContactSelector()
            .selectContacts()
            .executeQuery();

        List<Contact> contactsForApproval = (List<Contact>) new ContactSelector()
            .selectContactsForApproval(new List<Object>{new Set<Id>{contacts[0].Id}})
            .executeQuery();

        System.assert(contactsForApproval.size() == 1, ASSERT_MESSAGE);
        System.assertEquals(contacts[0].Id, contactsForApproval[0].Id, ASSERT_EQUALS_MESSAGE);
    }

    @isTest
    private static void testSelectContactsByIds(){
        List<Contact> contacts = (List<Contact>) new ContactSelector()
            .selectContacts()
            .executeQuery();

        List<Contact> contactsByIds = (List<Contact>) new ContactSelector()
            .selectContactsByIds(new List<Object>{new Set<Id>{contacts[0].Id}})
            .executeQuery();

        System.assert(contactsByIds.size() == 1, ASSERT_MESSAGE);
        System.assertEquals(contacts[0].Id, contactsByIds[0].Id, ASSERT_EQUALS_MESSAGE);
    }

    @isTest
    private static void testSelectContactsForClose(){
        List<Contact> contactsForClose = (List<Contact>) new ContactSelector()
            .selectContactsForClose()
            .executeQuery();

        System.assert(contactsForClose.size() > 0, ASSERT_MESSAGE);
    }

    @isTest
    private static void testSelectContactsWithAssetTouches(){
        List<Contact> contacts = (List<Contact>) new ContactSelector()
            .selectContacts()
            .executeQuery();

        List<Contact> contactsWithAssetTouches = (List<Contact>) new ContactSelector()
            .selectContactsWithAssetTouches(new List<Object>{new Set<Id>{contacts[0].Id}})
            .executeQuery();

        System.assert(contactsWithAssetTouches.size() == 1, ASSERT_MESSAGE);
        System.assertEquals(contacts[0].Id, contactsWithAssetTouches[0].Id, ASSERT_EQUALS_MESSAGE);
    }

    @isTest
    private static void testSelectContactsForSignUp(){
        List<Contact> contacts = (List<Contact>) new ContactSelector()
            .selectContacts()
            .executeQuery();

        List<Contact> contactsForSignUp = (List<Contact>) new ContactSelector()
            .selectContactsForSignUp(new Set<Id>{contacts[0].Id})
            .executeQuery();

        System.assert(contactsForSignUp.size() == 1, ASSERT_MESSAGE);
        System.assertEquals(contacts[0].Id, contactsForSignUp[0].Id, ASSERT_EQUALS_MESSAGE);
    }

    @isTest
    private static void testSelectContactsByEmail(){
        List<Contact> contacts = (List<Contact>) new ContactSelector()
            .selectContacts()
            .executeQuery();

        List<Contact> contactsByEmail = (List<Contact>) new ContactSelector()
            .selectContactsByEmail(new List<Object>{new Set<String>{CONTACT_FIRST_NAME},
                                                      new Set<String>{CONTACT_LAST_NAME},
                                                      new Set<String>{CONTACT_EMAIL}})
            .executeQuery();

        System.assert(contactsByEmail.size() == 1, ASSERT_MESSAGE);
        System.assertEquals(contacts[0].Id, contactsByEmail[0].Id, ASSERT_EQUALS_MESSAGE);
    }

    @isTest
    private static void testSelectContactForSignUpSync(){
        List<Contact> contacts = (List<Contact>) new ContactSelector()
            .selectContacts()
            .executeQuery();

        List<Contact> contactForSignUpSync = (List<Contact>) new ContactSelector()
            .selectContactForSignUpSync(CONTACT_EMAIL)
            .executeQuery();

        System.assert(contactForSignUpSync.size() == 1, ASSERT_MESSAGE);
        System.assertEquals(contacts[0].Id, contactForSignUpSync[0].Id, ASSERT_EQUALS_MESSAGE);
    }

    @isTest
    private static void testSelectContactForAPI(){
        List<Contact> contacts = (List<Contact>) new ContactSelector()
            .selectContacts()
            .executeQuery();

        List<Contact> contactForAPI = (List<Contact>) new ContactSelector()
            .selectContactForAPI(new List<Object>{new Set<Id>{null},
                								  new Set<String>{CONTACT_EMAIL}})
            .executeQuery();

        System.assert(contactForAPI.size() == 1, ASSERT_MESSAGE);
        System.assertEquals(contacts[0].Id, contactForAPI[0].Id, ASSERT_EQUALS_MESSAGE);
    }

    @isTest
    private static void testSelectContactsForAccPayble(){
        List<Contact> contacts = (List<Contact>) new ContactSelector()
            .selectContacts()
            .executeQuery();

        List<Contact> contactsForAccPayble = (List<Contact>) new ContactSelector()
            .selectContactsForAccPayble(new List<Object>{new Set<Id>{contacts[0].Id},
                								  		 new Set<Id>{contacts[0].AccountId}})
            .executeQuery();

        System.assert(contactsForAccPayble.size() == 1, ASSERT_MESSAGE);
        System.assertEquals(contacts[0].Id, contactsForAccPayble[0].Id, ASSERT_EQUALS_MESSAGE);
    }

    @isTest
    private static void testSelectContactsByIdsForStatusUpdate(){
        List<Contact> contacts = (List<Contact>) new ContactSelector()
            .selectContacts()
            .executeQuery();

        List<Contact> contactsByIdsForStatusUpdate = (List<Contact>) new ContactSelector()
            .selectContactsByIdsForStatusUpdate(new List<Object>{new Set<Id>{contacts[0].Id}})
            .executeQuery();

        System.assert(contactsByIdsForStatusUpdate.size() == 1, ASSERT_MESSAGE);
        System.assertEquals(contacts[0].Id, contactsByIdsForStatusUpdate[0].Id, ASSERT_EQUALS_MESSAGE);
    }

    @isTest
    private static void testSelectContactByIdAndMostRecentCampaign(){
        List<Contact> contacts = (List<Contact>) new ContactSelector()
            .selectContacts()
            .executeQuery();

        List<Campaign> campaignsByName = (List<Campaign>) new CampaignSelector()
            .selectCampaignsByName(new List<Object>{new Set<String>{CAMPAIGN_NAME}})
            .executeQuery();

        List<Contact> contactByIdAndMostRecentCampaign = (List<Contact>) new ContactSelector()
            .selectContactByIdAndMostRecentCampaign(new List<Object>{new Set<Id>{contacts[0].Id},
                													 new Set<Id>{campaignsByName[0].Id}})
            .executeQuery();

       	System.assert(contactByIdAndMostRecentCampaign.size() == 1, ASSERT_MESSAGE);
        System.assertEquals(contacts[0].Id, contactByIdAndMostRecentCampaign[0].Id, ASSERT_EQUALS_MESSAGE);
    }

    @isTest
    private static void testSelectAccountByContactId(){
        List<Contact> contacts = (List<Contact>) new ContactSelector()
            .selectContacts()
            .executeQuery();

        List<Contact> accountByContactId = (List<Contact>) new ContactSelector()
            .selectAccountByContactId(new List<Object>{new Set<Id>{contacts[0].Id}})
            .executeQuery();

        System.assert(accountByContactId.size() == 1, ASSERT_MESSAGE);
        System.assertEquals(contacts[0].Id, accountByContactId[0].Id, ASSERT_EQUALS_MESSAGE);
    }

    @isTest
    private static void contactsByAccountAndClosedWonStatus(){
        List<Contact> contacts = (List<Contact>) new ContactSelector()
            .selectContacts()
            .executeQuery();

        List<Contact> contactsForDFRById = (List<Contact>) new ContactSelector()
            .selectContactsForDFRById(new List<Object>{new Set<Id>{contacts[0].Id}})
            .executeQuery();

        Contact testContact = contactsForDFRById[0];
        testContact.Contact_Status__c = ContactTriggerHandler.CONTACT_STATUS_CLOSED_WON_OPP;
        update testContact;

        List<Contact> contactsByAccountAndClosedWonStatus = (List<Contact>) new ContactSelector()
            .selectContactsByAccountAndClosedWonStatus(new List<Object>{new Set<Id>{testContact.AccountId}})
            .executeQuery();

        System.assert(contactsByAccountAndClosedWonStatus.size() == 1, ASSERT_MESSAGE);
        System.assertEquals(testContact.AccountId, contactsByAccountAndClosedWonStatus[0].AccountId, ASSERT_EQUALS_MESSAGE);   }

    @isTest
    private static void testSelectContactsByAccountIdAndEmailOrPhone(){
        List<Contact> contacts = (List<Contact>) new ContactSelector()
            .selectContacts()
            .executeQuery();

        List<Contact> contactsByAccountIdAndEmailOrPhone = (List<Contact>) new ContactSelector()
            .selectContactsByAccountIdAndEmailOrPhone(new List<Object>{new Set<Id>{contacts[0].AccountId},
                                                                       new Set<String>{CONTACT_EMAIL},
                                                                       new Set<String>{CONTACT_PHONE}})
            .executeQuery();

        System.assert(contactsByAccountIdAndEmailOrPhone.size() == 1, ASSERT_MESSAGE);
        System.assertEquals(contacts[0].AccountId, contactsByAccountIdAndEmailOrPhone[0].AccountId, ASSERT_EQUALS_MESSAGE);
    }

    @isTest
    private static void testSelectContactByIdForMergeToContactInLeadSearchExtension(){
        List<Contact> contacts = (List<Contact>) new ContactSelector()
            .selectContacts()
            .executeQuery();

        List<Contact> contactByIdForMergeToContactInLeadSearchExtension = (List<Contact>) new ContactSelector()
            .selectContactByIdForMergeToContactInLeadSearchExtension(new List<Object>{new Set<Id>{contacts[0].Id}})
            .executeQuery();

        System.assert(contactByIdForMergeToContactInLeadSearchExtension.size() == 1, ASSERT_MESSAGE);
        System.assertEquals(contacts[0].Id, contactByIdForMergeToContactInLeadSearchExtension[0].Id, ASSERT_EQUALS_MESSAGE);
    }

    @isTest
    private static void testSelectContactsByAccountAndNotWorkingOppOrDowngradeStatus(){
        List<Contact> contacts = (List<Contact>) new ContactSelector()
            .selectContacts()
            .executeQuery();

        List<Contact> contactsByAccountAndNotWorkingOppOrDowngradeStatus = (List<Contact>) new ContactSelector()
            .selectContactsByAccountAndNotWorkingOppOrDowngradeStatus(new List<Object>{new Set<Id>{contacts[0].AccountId},
                																	   new Set<String>()})
            .executeQuery();

        System.assert(contactsByAccountAndNotWorkingOppOrDowngradeStatus.size() == 1, ASSERT_MESSAGE);
        System.assertEquals(contacts[0].AccountId, contactsByAccountAndNotWorkingOppOrDowngradeStatus[0].AccountId, ASSERT_EQUALS_MESSAGE);
    }

    @isTest
    private static void testSelectContactsByAccountIds(){
        List<Contact> contacts = (List<Contact>) new ContactSelector()
            .selectContacts()
            .executeQuery();

        List<Contact> contactsByAccountIds = (List<Contact>) new ContactSelector()
            .selectContactsByAccountIds(new List<Object>{new Set<Id>{contacts[0].AccountId}})
            .executeQuery();

        System.assert(contactsByAccountIds.size() == 1, ASSERT_MESSAGE);
        System.assertEquals(contacts[0].AccountId, contactsByAccountIds[0].AccountId, ASSERT_EQUALS_MESSAGE);
    }


    @isTest
    private static void testSelectContactsForLeadConversion(){
        List<Contact> contacts = (List<Contact>) new ContactSelector()
            .selectContacts()
            .executeQuery();

        List<Contact> contactsForLeadConversion = (List<Contact>) new ContactSelector()
            .selectContactsForLeadConversion(new List<Object>{new Set<Id>{contacts[0].Id},
                											  new Set<Id>{contacts[0].AccountId}},
                						     5, 0, 'Id = :bind0 AND AccountId = :bind1')
            .executeQuery();

        System.assert(contactsForLeadConversion.size() == 1, ASSERT_MESSAGE);
        System.assertEquals(contacts[0].Id, contactsForLeadConversion[0].Id, ASSERT_EQUALS_MESSAGE);
    }

    @isTest
    private static void testSelectContactsWithAccountByEmail(){
        Account notPaidAcc = (Account) new SObjectBuilder(Account.sObjectType)
            .setField(Account.RC_Account_Status__c, 'Free')
            .create()
            .getRecord();
        Contact contactWithUnpaidAcc = (Contact) new SObjectBuilder(Contact.sObjectType)
            .setField(Contact.FirstName, 'Test')
            .setField(Contact.Email, 'test1@test.com')
            .setField(Contact.AccountId, notPaidAcc.Id)
            .create()
            .getRecord();

        List<Object> bindings = new List<Object>{new List<String> {'test1@test.com'}};
        List<Contact> result = (List<Contact>) new ContactSelector()
            .selectContactsWithAccountByEmail(bindings)
            .executeQuery();

        System.assertEquals(1, result.size(),
        'expected contact was not found');
        System.assertEquals('Test', result[0].FirstName,
        'contact found is not the expected one');
        System.assertEquals(notPaidAcc.Id, result[0].AccountId,
        'contact found is not the expected one');
        System.assertEquals('Free', result[0].Account.RC_Account_Status__c,
        'contact found is not the expected one');

    }

    @isTest
    private static void selectContactsByIdsForSaasquatchReferralCode(){
        List<Contact> contacts = (List<Contact>) new ContactSelector()
            .selectContacts()
            .executeQuery();

        List<String> contactsIds = new List<String>();
        contactsIds.add(contacts[0].Id);

        List<Contact> contactsWithSaasqCode = (List<Contact>) new ContactSelector()
            .selectContactsByIdsForSaasquatchReferralCode(new List<Object> {contactsIds})
            .executeQuery();

        System.assert(contactsWithSaasqCode.size() == 1, ASSERT_MESSAGE);
        System.assertEquals(contactsWithSaasqCode[0].UK_Saasquatch_Referral_Code__c, CONTACT_SAASQ_CODE , ASSERT_EQUALS_MESSAGE);
    }

    @isTest
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    private static void testSelectContactsForSyncWS() {
        List<Object> bindings = new List<Object>{ CONTACT_EMAIL, AccountHelper.RT_ID_CUSTOMER_ACCOUNT, OpportunityHelper.BRAND_RINGCENTRAL };

        Test.startTest();
            QueryFactory factory = new ContactSelector()
                .selectContactsForSyncWS(bindings)
                .setQuery();
        Test.stopTest();

        String selectorName = 'selectContactsForSyncWS';
        String expectedWhereClause = 'WHERE Email = :bind0 ' +
            'AND Account.RC_User_ID__c = NULL ' +
            'AND Account.RecordTypeId = :bind1 ' +
            'AND Account.RC_Brand__c = :bind2';

        assertContactSelector(factory, selectorName, expectedWhereClause, 3);
        assertBindings(factory, selectorName, bindings);
    }

    @isTest
    private static void selectConversionContactsByAccount(){
        List<Contact> contacts = (List<Contact>) new ContactSelector()
            .selectContacts()
            .executeQuery();
    Contact conversionContact = (Contact) new SObjectBuilder(Contact.sObjectType)
            .setField(Contact.FirstName, 'Test')
            .setField(Contact.Email, 'test1@test.com')
            .setField(Contact.AccountId,contacts[0].AccountId)
            .create()
            .getRecord();

	List<Contact> result = (List<Contact>) new ContactSelector()
            .selectConversionContactsByAccount(contacts[0].AccountId, contacts[0].Id)
            .executeQuery();
	    System.assert(result.size() == 1, ASSERT_MESSAGE);
        System.assertEquals(contacts[0].AccountId, result[0].AccountId, ASSERT_EQUALS_MESSAGE);
    }
}