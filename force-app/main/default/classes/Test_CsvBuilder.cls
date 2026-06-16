@isTest
private class Test_CsvBuilder {
    private static List<String> ACCOUNT_FIELDS = new List<String> {'Id', 'Name', 'RC_User_ID__c'};
    private static List<String> CONTACT_FIELDS = new List<String> {'Id', 'Name', 'Email'};
    private static List<String> CASE_FIELDS = new List<String> {'Id', 'Subject', 'RecordTypeId'};

    @testSetup
    private static void testSetup() {
        new SObjectBuilder(Account.SObjectType)
            .quantity(2)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => ValueProviderBuilder.provideList(new List<String>{'accWithRCId', 'accWithOutRCId'}),
                Account.RC_User_ID__c => ValueProviderBuilder.provideDummyId(User.SObjectType)
            })
            .create();

        new SObjectBuilder(Contact.SObjectType)
            .quantity(2)
            .setFields(
                new Map<SObjectField, Object> {
                    Contact.LastName => ValueProviderBuilder.provideUniqueString(),
                    Contact.FirstName => ValueProviderBuilder.provideUniqueString(),
                    Contact.Email => ValueProviderBuilder.provideUniqueEmail()
                })
            .create();

        new SObjectBuilder(Case.SObjectType)
            .quantity(2)
            .setField(Case.RecordTypeId, ValueProviderBuilder.provideList(
                new List<String>{CaseHelper.RT_ID_SUPPORT_T1, CaseHelper.RT_ID_IT_HELPDESK}))
            .setField(Case.Subject, ValueProviderBuilder.provideList(new List<String>{'subject', ''}))
            .create();
    }

    @isTest
    private static void testCreateAccountCsv() {
        List<Account> accounts = (List<Account>) new AccountSelector().newQueryFactory()
            .selectFields(ACCOUNT_FIELDS)
            .executeQuery();

        String expectedString = ''
            + 'Id,Name,RC_User_ID__c\n'
            + accounts.get(0).Id + ',' + accounts.get(0).Name + ',' + accounts.get(0).RC_User_ID__c + '\n'
            + accounts.get(1).Id + ',' + accounts.get(1).Name + ',' + accounts.get(1).RC_User_ID__c + '\n';

        System.assertEquals(
            expectedString,
            new CsvBuilder().createCSV(accounts, ACCOUNT_FIELDS),
            'Strings should be equal');
    }

    @isTest
    private static void testCreateContactCsv() {
        List<Contact> contacts = (List<Contact>) new ContactSelector().newQueryFactory()
            .selectFields(CONTACT_FIELDS)
            .executeQuery();

        String expectedString = ''
            + 'Id,Name,Email\n'
            + contacts.get(0).Id + ',' + contacts.get(0).Name + ',' + contacts.get(0).Email + '\n'
            + contacts.get(1).Id + ',' + contacts.get(1).Name + ',' + contacts.get(1).Email + '\n';

        System.assertEquals(
            expectedString,
            new CsvBuilder().createCSV(contacts, CONTACT_FIELDS),
            'Strings should be equal');
    }

    @isTest
    private static void testCreateCaseCsv() {
        List<Case> cases = (List<Case>) new CaseSelector().newQueryFactory().selectFields(CASE_FIELDS).executeQuery();

        String expectedString = ''
            + 'Id,Subject,RecordTypeId\n'
            + cases.get(0).Id + ',' + cases.get(0).Subject + ',' + cases.get(0).RecordTypeId + '\n'
            + cases.get(1).Id + ',,' + cases.get(1).RecordTypeId + '\n';

        System.assertEquals(
            expectedString,
            new CsvBuilder().createCSV(cases, CASE_FIELDS),
            'Strings should be equal');
    }
}