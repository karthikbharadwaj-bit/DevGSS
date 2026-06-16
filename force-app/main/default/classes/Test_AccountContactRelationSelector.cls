@isTest
private class Test_AccountContactRelationSelector {
	//Account fields defined
	private static final String ACCOUNT_NAME = 'Test';
    private static final String ACCOUNT_NAME_FOR_MULTIPLE_CONTACT_RELATION = 'Account for multiple contact relation';
    
    //Contact fields defined
    private static final String CONTACT_EMAIL = 'test@test.com';
    private static final String CONTACT_FIRST_NAME = 'Test';
    private static final String CONTACT_LAST_NAME = 'Test';

    //Assert message
    private static final String ASSERT_MESSAGE = 'Account contact relations should be selected';

    @testSetup
    private static void testData(){
    	Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => ACCOUNT_NAME
                }
            )
            .create()
            .getRecord();
		
        Account accForMultipleContactRelation = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => ACCOUNT_NAME_FOR_MULTIPLE_CONTACT_RELATION
                }
            )
            .create()
            .getRecord();

        Contact contact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Contact.SObjectType))
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.AccountId => acc.Id,
                    Contact.Email => CONTACT_EMAIL,
                    Contact.FirstName => CONTACT_FIRST_NAME,
                    Contact.LastName => CONTACT_LAST_NAME
                }
            )
            .create()
            .getRecord();
        
        AccountContactRelation acr = (AccountContactRelation) new SObjectBuilder(AccountContactRelation.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    AccountContactRelation.AccountId => accForMultipleContactRelation.Id,
                    AccountContactRelation.ContactId => contact.Id
                }
            )
            .create()
            .getRecord();
    }
    
	@isTest
    private static void testSelectAccountContactRelationsForAccountLink(){
        List<AccountContactRelation> accountContactRelationsForAccountLink = (List<AccountContactRelation>) new AccountContactRelationSelector()
            .selectAccountContactRelationsForAccountLink()
            .executeQuery();
        
        List<AccountContactRelation> accountContactRelationsForAccountLinkWithConstructorParams = (List<AccountContactRelation>) new AccountContactRelationSelector(true, true)
            .selectAccountContactRelationsForAccountLink()
            .executeQuery();
        
        System.assert(accountContactRelationsForAccountLink.size() > 0, ASSERT_MESSAGE);
        System.assert(accountContactRelationsForAccountLinkWithConstructorParams.size() > 0, ASSERT_MESSAGE);
    }
}