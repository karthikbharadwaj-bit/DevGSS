@isTest
private class Test_MaintenanceCasesCreate {
    private static final String ACCOUNT_NAME = 'AccountName';
    private static final String CONTACT_LAST_NAME = 'Test contact';

    private static final Id CASE_OWNER_ID = MaintenanceCasesCreate.MAINTENANCE_OWNER_ID;
    private static final Id CASE_RECORD_TYPE_ID = MaintenanceCasesCreate.MAINTENANCE_RECORD_TYPE_ID;
    private static final String CASE_UID = '123123';
    private static final String CASE_STATUS = 'New';
    private static final String CASE_SUBJECT = 'Subject';
    private static final String CASE_DESCRIPTION = 'Description';

    private static final Integer INVALID_DATA = 0;
    private static final Date DATE_TODAY = System.today();
    private static final String CASE_OBJECT_NAME = 'Case';

    @testSetup
    private static void setup() {
        Account testAccount = (Account) new SObjectBuilder(Account.sObjectType)
            .setFields(new Map<SObjectField, Object>{Account.Name => ACCOUNT_NAME, Account.RC_User_Id__c => CASE_UID})
            .create()
            .getRecord();
        Id accId = testAccount.Id;

        Contact testContact = (Contact) new SObjectBuilder(Contact.sObjectType)
            .setFields(new Map<SObjectField, Object>{Contact.LastName => CONTACT_LAST_NAME, Contact.AccountId => accId})
            .create()
            .getRecord();
        Id contactId = testContact.Id;

        Case c = (Case) new SObjectBuilder(Case.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Case.RecordTypeId => CASE_RECORD_TYPE_ID,
                    Case.OwnerId => CASE_OWNER_ID,
                    Case.Status => CASE_STATUS,
                    Case.Subject => CASE_SUBJECT,
                    Case.Description => CASE_DESCRIPTION,
                    Case.Date_Assigned__c => DATE_TODAY,
                    Case.AccountId => accId,
                    Case.ContactId => contactId
                }
            )
            .create()
            .getRecord();
    }

    @isTest
    private static void testGetMapExistAndNotExistUIDAndAccountId() {
        String existUID = CASE_UID;
        String notExistUID = CASE_UID + '1';
        List<String> uidList = new List<String>{existUID, notExistUID};

        String request = JSON.serialize(uidList);
        Response res = MaintenanceCasesCreate.getMapUIDAndAccountId(request);
        System.assertEquals('success', res.status, 'Status should be successful');

        Map<String, Id> mapUIDAndAccountId = (Map<String, Id>) res.data.get(
            MaintenanceCasesCreate.LABEL_MAP_UID_AND_ACCOUNTID
        );
        System.assertNotEquals(null, mapUIDAndAccountId.get(existUID), 'UID should be defined for this account');
        System.assertEquals(null, mapUIDAndAccountId.get(notExistUID), 'UID should not be defined for this account');
    }

    @isTest
    private static void testGetMapUIDAndAccountIdWithBlankUIDs() {
        List<String> blankUIDList = new List<String>{' ', '', null};
        String request = JSON.serialize(blankUIDList);
        Response res = MaintenanceCasesCreate.getMapUIDAndAccountId(request);
        System.assertEquals('success', res.status, 'Status should be successful');

        Map<String, Id> mapUIDAndAccountId = (Map<String, Id>) res.data.get(
            MaintenanceCasesCreate.LABEL_MAP_UID_AND_ACCOUNTID
        );
        System.assertEquals(0, mapUIDAndAccountId.size(), 'No accounts for blank UIDs');
    }

    @isTest
    private static void testGetErrorResponceMapUIDAndAccountIdForInvalidData() {
        String request = JSON.serialize(INVALID_DATA);
        Response res = MaintenanceCasesCreate.getMapUIDAndAccountId(request);
        System.assertEquals('error', res.status, 'Status should be error');
    }

    @isTest
    private static void testGetPiclkistValuesForFields() {
        String caseFieldName = 'Status';
        MaintenanceCasesCreate.fieldAPINameToObject = new Map<String, String>{caseFieldName => CASE_OBJECT_NAME};
        Response res = MaintenanceCasesCreate.getPicklistValuesForFields();
        System.assertEquals('success', res.status, 'Status should be successful');

        Map<String, List<String>> mapFieldNameAndPicklistValues = (Map<String, List<String>>) res.data.get(
            MaintenanceCasesCreate.LABEL_MAP_FIELD_AND_PICKLIST_VALUES
        );
        System.assertEquals(
            1,
            mapFieldNameAndPicklistValues.keySet().size(),
            'Should be defined picklist for only one field'
        );
        System.assertNotEquals(
            null,
            mapFieldNameAndPicklistValues.get(caseFieldName),
            'Should be defined picklist for field ' + caseFieldName
        );
    }

    @isTest
    private static void testGetErrorResponceGetPiclkistValuesForFieldsForInvalidData() {
        MaintenanceCasesCreate.fieldAPINameToObject = new Map<String, String>{JSON.serialize(INVALID_DATA) => CASE_OBJECT_NAME};
        Response res = MaintenanceCasesCreate.getPicklistValuesForFields();
        System.assertEquals('error', res.status, 'Status should be error');
    }

    @isTest
    private static void testInsertDifferentMaintenances() {
        Account acc = (Account) new AccountSelector()
            .newQueryFactory()
            .selectFields(new List<Schema.SObjectField>{Account.Id})
            .setCondition('Name = :bind0')
            .setQueryBindings(new List<Object>{ACCOUNT_NAME})
            .executeQuery()
            .get(0);
        Id accId = acc.Id;

        Contact testContact = (Contact) new ContactSelector()
            .newQueryFactory()
            .selectFields(new List<Schema.SObjectField>{Contact.Id})
            .setCondition('LastName = :bind0')
            .setQueryBindings(new List<Object>{CONTACT_LAST_NAME})
            .executeQuery()
            .get(0);
        Id contactId = testContact.Id;

        List<Case> listCasesToInsert = new SObjectBuilder(Case.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Case.RecordTypeId => CASE_RECORD_TYPE_ID,
                    Case.OwnerId => CASE_OWNER_ID,
                    Case.Status => CASE_STATUS,
                    Case.Subject => CASE_SUBJECT,
                    Case.Description => new ValueProvider.UniqueStringProvider(CASE_DESCRIPTION),
                    Case.Date_Assigned__c => DATE_TODAY,
                    Case.AccountId => ValueProviderBuilder.provideList(new List<Object>{accId, accId, ''}),
                    Case.ContactId => ValueProviderBuilder.provideList(new List<Object>{contactId, contactId, ''})
                }
            )
            .quantity(3)
            .build()
            .getRecords();
        /* insert 1 dublicate, 1 dublicate with org, 1 normal maintenance*/
        String request = JSON.serialize(listCasesToInsert);
        Response res = MaintenanceCasesCreate.insertMaintenance(request);
        System.assertEquals('success', res.status, 'Status should be successful');
        Map<String, Object> mapIndexAndErrorMessage = (Map<String, Object>) res.data;

        System.assertEquals('success', res.status, 'Status should be successful');

        String error0 = String.valueOf(mapIndexAndErrorMessage.get('0'));
        System.assert(
            error0.contains(MaintenanceCasesCreate.LABEL_DUBLICATE_MAINTENANCE),
            'Error should contain ' + MaintenanceCasesCreate.LABEL_DUBLICATE_MAINTENANCE
        );

        String error1 = String.valueOf(mapIndexAndErrorMessage.get('1'));
        System.assert(
            error1.contains(MaintenanceCasesCreate.LABEL_DUBLICATE_INSERT_MAINTENANCE),
            'Error should contain ' + MaintenanceCasesCreate.LABEL_DUBLICATE_INSERT_MAINTENANCE
        );
    }

    @isTest
    private static void testGetErrorResponceForInsertInvalidData() {
        String request = JSON.serialize(INVALID_DATA);
        Response res = MaintenanceCasesCreate.insertMaintenance(request);
        System.assertEquals('error', res.status, 'Status should be error');
    }
}