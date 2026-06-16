@isTest
private class Test_AccountHierarchySelector {
	//Account hierachy fields defined
	private static final String ACCOUNT_HIERARCHY_NAME = 'Test';
    private static final String ACCOUNT_HIERARCHY_STATUS = 'Status 1';
    
    //Assert messages defined
    private static final String ASSERT_MESSAGE = 'Account hierarchy objects should be selected';
    private static final String ASSERT_EQUALS_MESSAGE = 'Account hierarchy object selected';
    
    @testSetup
    private static void testData(){
        Account_Hierarchy__c company = (Account_Hierarchy__c) new SObjectBuilder(Account_Hierarchy__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account_Hierarchy__c.Name => ACCOUNT_HIERARCHY_NAME,
                    Account_Hierarchy__c.Company_Status__c => ACCOUNT_HIERARCHY_STATUS
                	}
            )
            .create()
            .getRecord();

    }
    
   	@isTest
    private static void testSelectAccountHierarchyByName(){       
        List<Account_Hierarchy__c> accountHierarchyByByName = (List<Account_Hierarchy__c>) new AccountHierarchySelector()
            .selectAccountHierarchyByName(new List<Object>{new Set<String>{ACCOUNT_HIERARCHY_NAME}})
			.executeQuery();
        
        System.assert(accountHierarchyByByName.size() > 0, ASSERT_MESSAGE);
        System.assertEquals(ACCOUNT_HIERARCHY_NAME, accountHierarchyByByName[0].Name, ASSERT_EQUALS_MESSAGE);
    }
    
    @isTest
    private static void testSelectAccountHierarchyById(){
		List<Account_Hierarchy__c> accountHierarchyByByName = (List<Account_Hierarchy__c>) new AccountHierarchySelector()
            .selectAccountHierarchyByName(new List<Object>{new Set<String>{ACCOUNT_HIERARCHY_NAME}})
			.executeQuery();
        
        List<Account_Hierarchy__c> accountHierarchyById = (List<Account_Hierarchy__c>) new AccountHierarchySelector()
            .selectAccountHierarchyById(accountHierarchyByByName[0].Id)
			.executeQuery();
        
        System.assert(accountHierarchyById.size() > 0, ASSERT_MESSAGE);
        System.assertEquals(accountHierarchyByByName[0].Id, accountHierarchyById[0].Id, ASSERT_EQUALS_MESSAGE);
    }
    
    @isTest
    private static void testSelectAccountHierarchyByIdInRange(){
		List<Account_Hierarchy__c> accountHierarchyByByName = (List<Account_Hierarchy__c>) new AccountHierarchySelector()
            .selectAccountHierarchyByName(new List<Object>{new Set<String>{ACCOUNT_HIERARCHY_NAME}})
			.executeQuery();
        
        List<Account_Hierarchy__c> accountHierarchyByIdInRange = (List<Account_Hierarchy__c>) new AccountHierarchySelector()
            .selectAccountHierarchyByIdInRange(new Set<Id>{accountHierarchyByByName[0].Id})
			.executeQuery();
        
        System.assert(accountHierarchyByIdInRange.size() > 0, ASSERT_MESSAGE);
        System.assertEquals(accountHierarchyByByName[0].Id, accountHierarchyByIdInRange[0].Id, ASSERT_EQUALS_MESSAGE);
    }
}