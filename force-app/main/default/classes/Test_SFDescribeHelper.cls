@isTest
private class Test_SFDescribeHelper
{
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
	@isTest
	static void itShould()
	{
		Test.startTest();
		SFDescribeHelper.getOptions('Case', 'CSAT_Prediction__c');
		SFDescribeHelper.getDependentOptions('Case', 'OpenCustomerSupportLevel1__c', 'OpenCustomerSupportLevel2__c');
		Test.stopTest();
	}

    @isTest
	static void testGetOptionsMap() {

        Test.startTest();
        Map<String, Schema.PicklistEntry> options = SFDescribeHelper.getOptionsMap('Case', 'Product_Assistance__c');
        Test.stopTest();

        List<Schema.PicklistEntry> pes = Case.Product_Assistance__c.getDescribe().getPicklistValues();
        System.assert(options != null, 'Received null');
        System.assertEquals(
            pes.size(),
            options.size(),
            'Picklist size does not match'
        );
        System.assert(
            options.containsKey(pes[0].getLabel()),
            'Option not found'
        );
        System.assertEquals(
            pes[0].getValue(),
            options.get(pes[0].getLabel()).getValue(),
            'Value does not match'
        );
    }

    @isTest
	static void testGetDependentOptions() {

        Test.startTest();
        Map<String,List<String>> options = SFDescribeHelper.getDependentOptions(
            'Case', 'Product_Assistance__c', 'Product_Assistance_Lvl2__c');
        Test.stopTest();

        List<Schema.PicklistEntry> pesControlling = Case.Product_Assistance__c.getDescribe().getPicklistValues();
        System.assert(options != null, 'Received null');
        System.assertEquals(
            pesControlling.size(),
            options.size(),
            'Picklist size does not match'
        );
        System.assert(
            options.containsKey('Call Quality'),
            '"Call Quality" option not found'
        );
        System.assert(
            options.get('Call Quality').contains('Echo'),
            '"Call Quality" -> "Echo" dependency not found'
        );
    }

    @isTest
    static void testCnvBits_whenParameterIsValid_shouldBeOk(){
        Boolean hasThrownException = false;
        String errorMessage = '';

        Test.startTest();
        Integer[] bits = SFDescribeHelper.cnvBits('as');
        Test.stopTest();

        Assert.AreEqual(2, bits[0], 'Wrong number');
        Assert.AreEqual(3, bits[1], 'Wrong number');
        Assert.AreEqual(5, bits[2], 'Wrong number');
        Assert.AreEqual(7, bits[3], 'Wrong number');
    }
    
    @isTest
    static void testGetOptionsWithNoneValue_whenParameterAreValid_shouldBeOk(){
        Test.startTest();
        List<Schema.PicklistEntry> picklistEntries = SFDescribeHelper.getOptions('Case', 'Status', true);
        Test.stopTest();

        Assert.IsTrue(picklistEntries.size() > 1, 'There should be at least 1 status picklist value.');
        Assert.AreEqual('', picklistEntries[0].value, 'The first value should be an empty value.');
    }
    
    @isTest
    static void testGetSObjectField_whenParameterAreValid_shouldBeOk(){
        Test.startTest();
        String accountName = StringHelper.safeString(SFDescribeHelper.getSObjectField(new Account(Name='test'), 'Name'));
        Test.stopTest();
        
        Assert.AreEqual('test', accountName, 'Invalid value');
    }
    
    @isTest
    static void testGetNameField_whenParameterAreValid_shouldBeOk(){
        Test.startTest();
        String nameFieldName = SFDescribeHelper.getNameField('Case').getName();
        Test.stopTest();

        Assert.IsNotNull(nameFieldName, 'Invalid value');
    }
    
    @isTest
    static void testIsValidSalesforceId_whenParameterAreValid_shouldBeOk(){
        Assert.AreEqual(true, SFDescribeHelper.isValidSalesforceId((Id) new ValueProvider.DummyIdProvider(Case.sObjectType).getValue(), Schema.Case.sObjectType), 'It is a valid case id.');
    }

    @isTest
    static void testGetPicklistOptionsWithTranslation_whenParameterAreValid_shouldBeOk(){
        Test.startTest();
        List<PicklistSiteopsController.Picklist> picklistList = SFDescribeHelper.getPicklistOptions(
            'Case', 
            'Support-Case',
            'Status',
            'en_US',
            true
        );
        Test.stopTest();

        Assert.IsTrue(picklistList.size() == 0, 'Test method does not support getContent call.');
    }
    
    @isTest
    static void testGetFilteredPicklist_whenParameterAreValid_shouldBeOk(){
        List<Schema.PicklistEntry> picklistEntries = SFDescribeHelper.getFilteredPicklist(
            new String[]{'Closed'},
            SFDescribeHelper.getOptions('Case','Status')
        );
        Assert.IsTrue(picklistEntries.size() > 0, 'There should be at least 1 status picklist value.');
    }
    
    @isTest
    static void testGetObjectNameById() {
    	Account acc = new Account(Name = 'Test Account');
    	insert acc;

    	Contact con = new Contact(FirstName = 'Test', LastName = 'Contact', AccountId = acc.Id);
    	insert con;

    	Opportunity opp = new Opportunity(Name = 'Test Opportunity', CloseDate = Date.today(), StageName = 'Prospecting', AccountId = acc.Id);
    	insert opp;

    	System.assertEquals('Account', SFDescribeHelper.getObjectNameById(acc.Id));
    	System.assertEquals('Contact', SFDescribeHelper.getObjectNameById(con.Id));
    	System.assertEquals('Opportunity', SFDescribeHelper.getObjectNameById(opp.Id));
    }
    
    @isTest
    static void testConvertToTPicklistEntry() {
        // Get picklist values for a standard field
        List<Schema.PicklistEntry> picklistEntries = Case.Status.getDescribe().getPicklistValues();
        
        Test.startTest();
            List<SFDescribeHelper.TPicklistEntry> convertedEntries = SFDescribeHelper.convertToTPicklistEntry(picklistEntries);
        Test.stopTest();
        
        System.assertNotEquals(null, convertedEntries, 'Converted entries should not be null');
        System.assertEquals(
            picklistEntries.size(), 
            convertedEntries.size(), 
            'Size of converted entries should match the original picklist size'
        );
        
        // Verify the conversion maintained the values correctly
        for (Integer i = 0; i < picklistEntries.size(); i++) {
            System.assertEquals(
                picklistEntries[i].getValue(), 
                convertedEntries[i].value, 
                'The value property should match after conversion'
            );
            System.assertEquals(
                picklistEntries[i].getLabel(), 
                convertedEntries[i].label, 
                'The label property should match after conversion'
            );
        }
    }
    
    @isTest
    static void testGetChildRelationship() {
        // Test getting a child relationship from Account (Contacts)
        Schema.DescribeSObjectResult accountDescribe = Account.SObjectType.getDescribe();
        String relationshipName = 'Contacts'; // Standard Account to Contacts relationship
        
        Test.startTest();
            Schema.ChildRelationship relationship = SFDescribeHelper.getChildRelationship(
                accountDescribe, 
                relationshipName
            );
        Test.stopTest();
        
        System.assertNotEquals(null, relationship, 'The child relationship should not be null');
        System.assertEquals(
            relationshipName, 
            relationship.getRelationshipName(), 
            'The relationship name should match the requested name'
        );
        System.assertEquals(
            Contact.SObjectType, 
            relationship.getChildSObject(), 
            'The child SObject type should be Contact'
        );
    }
}