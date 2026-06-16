@isTest
private class Test_AccountRelationTriggerHandler {

	@isTest
	private static void testAccountRelationBefore() {

		Account billingAccount1 = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => 'billingAccount1',
                Account.ELA_Account_Type__c => AccountHelper.ACCOUNT_TYPE_ELA_BILLING
            })
            .create()
            .getRecord();
                
        Account serviceAccount1 = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => 'serviceAccount1',
                Account.ELA_Account_Type__c => AccountHelper.ACCOUNT_TYPE_ELA_SERVICE
            })
            .create()
            .getRecord();
                
        Account billingAccount2 = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => 'billingAccount2',
                Account.ELA_Account_Type__c => AccountHelper.ACCOUNT_TYPE_ELA_BILLING
            })
            .create()
            .getRecord();

        Account serviceAccount2 = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => 'serviceAccount3',
                Account.ELA_Account_Type__c => AccountHelper.ACCOUNT_TYPE_ELA_SERVICE
            })
            .create()
            .getRecord();

		Contact contact1 = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Contact.FirstName => 'Test1',
                Contact.LastName => 'Test1',
                Contact.AccountId => billingAccount1.Id,
                Contact.Email => 'test1@test.com',
                Contact.Phone => '1234567890',
                Contact.Preferred_Language__c => 'en_US'
            })
            .create()
            .getRecord();
        
        Contact contact2 = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Contact.FirstName => 'Test2',
                Contact.LastName => 'Test2',
                Contact.AccountId => billingAccount2.Id,
                Contact.Email => 'test2@test.com',
                Contact.Phone => '1234567890',
                Contact.Preferred_Language__c => 'en_US'
            })
            .create()
            .getRecord();
                
        AccountContactRole accountContactRole1 = (AccountContactRole) new SObjectBuilder(AccountContactRole.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                AccountContactRole.AccountId => billingAccount1.Id,
                AccountContactRole.ContactId => contact1.Id
            })
            .create()
            .getRecord();

        AccountContactRole accountContactRole2 = (AccountContactRole) new SObjectBuilder(AccountContactRole.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                AccountContactRole.AccountId => serviceAccount1.Id,
                AccountContactRole.ContactId => contact1.Id
            })
            .create()
            .getRecord();
        
        AccountContactRole accountContactRole3 = (AccountContactRole) new SObjectBuilder(AccountContactRole.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                AccountContactRole.AccountId => billingAccount2.Id,
                AccountContactRole.ContactId => contact2.Id
            })
            .create()
            .getRecord();

            AccountContactRole accountContactRole4 = (AccountContactRole) new SObjectBuilder(AccountContactRole.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                AccountContactRole.AccountId => serviceAccount2.Id,
                AccountContactRole.ContactId => contact2.Id
            })
            .create()
            .getRecord();

        AccountRelation__c accountRelation1 = new AccountRelation__c(
            Parent_Account__c = billingAccount1.Id, 
            Child_Account__c = billingAccount2.Id, 
            Relation_Type__c = AccountHelper.RELATION_TYPE_ELA
            );
        Database.SaveResult result1 = Database.insert(accountRelation1, false);
        System.assertEquals('Child account must be \'ELA Service\'', 
            result1.getErrors()[0].getMessage(), 
            'AccountRelation object with Accounts which have the same ELA type cannot be inserted or updated'
            );

        AccountRelation__c accountRelation2 = new AccountRelation__c(
            Parent_Account__c = billingAccount1.Id, 
            Child_Account__c = billingAccount1.Id, 
            Relation_Type__c = AccountHelper.RELATION_TYPE_ELA
            );
        Database.SaveResult result2 = Database.insert(accountRelation2, false);
        System.assertEquals('Parent and Child accounts cannot be the same', result2.getErrors()[0].getMessage());

        AccountRelation__c accountRelation3 = new AccountRelation__c(
            Parent_Account__c = billingAccount1.Id, 
            Child_Account__c = serviceAccount2.Id, 
            Relation_Type__c = AccountHelper.RELATION_TYPE_ELA
            );
        Database.SaveResult result3 = Database.insert(accountRelation3, false);
        System.assertEquals('Accounts don\'t have a common contact', result3.getErrors()[0].getMessage());

        AccountRelation__c accountRelation4 = new AccountRelation__c(
            Parent_Account__c = serviceAccount1.Id, 
            Child_Account__c = billingAccount1.Id, 
            Relation_Type__c = AccountHelper.RELATION_TYPE_ELA
            );
        Database.SaveResult result4 = Database.insert(accountRelation4, false);
        System.assertEquals('Parent account must be \'ELA Billing\'', result4.getErrors()[0].getMessage());

        AccountRelation__c accountRelation5 = new AccountRelation__c(
            Parent_Account__c = billingAccount1.Id, 
            Child_Account__c = serviceAccount1.Id, 
            Relation_Type__c = AccountHelper.RELATION_TYPE_ELA
            );
        Database.SaveResult result5 = Database.insert(accountRelation5, false);
        System.assertEquals(true, result5.isSuccess(), 'AccountRelation object should be inserted or updated');
	}
}