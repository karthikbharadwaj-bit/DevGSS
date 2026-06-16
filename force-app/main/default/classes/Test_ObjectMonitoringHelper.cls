/**
 * Created by Makhmud.Shafeev on 8/20/2021.
 */

@IsTest
private class Test_ObjectMonitoringHelper {
    private static final String BASE_ENDPOINT = 'http://test.com';
    private static final String MANAGER_PATH = 'http://test.com/test_manager';

    private static String PACKAGE_INFO = '[{"id":"18","version":"1","packageInfo":{"id":116477002,"catalogId":"18","version":"1","name":"Office Standard 1/2/100/1000+ Lines - 5100/5101/5102/5103","displayName":"RingCentral Office Standard","oldPackageName":"RingCentral Office Standard"},"productName":"Office","productId":"2","duration":"Monthly","edition":{"id":1,"name":"Standard"},"contract":null,"offerType":"Regular","poc":null,"globalPackageLimits":[{"value":"50000","code":"MONTHLY_AMOUNT_LIMIT","name":"Monthly money amount limit","type":"Amount","scope":"BillingCycle","transactionType":"Any","target":"Global","exclusions":[{"target":"LicenseCategoryId","targetId":"AP"}],"override":false}],"permissions":null,"packageBusinessIdentities":{"selectedBi":{"name":"RingCentral Inc.","isDefault":true,"id":"4","address":{"zip":"94002","street2":"","street1":"20 Davis Dr","state":"CA","phone":"","lastName":"","label":null,"firstName":"RingCentral, Inc.","county":"","country":"USA","city":"Belmont"}},"defaultBi":{"name":"RingCentral Inc.","isDefault":true,"id":"4","address":{"zip":"94002","street2":"","street1":"20 Davis Dr","state":"CA","phone":"","lastName":"","label":null,"firstName":"RingCentral, Inc.","county":"","country":"USA","city":"Belmont"}},"approvedBi":{"name":"RingCentral Inc.","isDefault":true,"id":"4","address":{"zip":"94002","street2":"","street1":"20 Davis Dr","state":"CA","phone":"","lastName":"","label":null,"firstName":"RingCentral, Inc.","county":"","country":"USA","city":"Belmont"}}},"existingPackageInfo":{"id":"18","version":"1","offerType":"Regular","productName":"Office"}}]';


    @TestSetup
    private static void testSetup() {
        new SObjectBuilder(ObjectMonitoringSettings__c.SObjectType)
                .setFields(
                new Map<SObjectField, Object>{
                        ObjectMonitoringSettings__c.ObjectName__c => 'Account',
                        ObjectMonitoringSettings__c.Name => 'Account',
                        ObjectMonitoringSettings__c.ObjectFields__c => 'EnabledLBO__c'
                }
        )
                .create()
                .getRecord();

        new SObjectBuilder(ObjectMonitoringSettings__c.SObjectType)
                .setFields(
                new Map<SObjectField, Object>{
                        ObjectMonitoringSettings__c.ObjectName__c => 'Quote',
                        ObjectMonitoringSettings__c.Name => 'Quote',
                        ObjectMonitoringSettings__c.ObjectFields__c => 'Enabled_LBO__c'
                }
        )
                .create()
                .getRecord();

        new SObjectBuilder(NGBS_Settings__c.SObjectType)
                .setFields(new Map<SObjectField, Object>{
                NGBS_Settings__c.BaseEndpoint__c => BASE_ENDPOINT,
                NGBS_Settings__c.AccountManagerPath__c => MANAGER_PATH,
                NGBS_Settings__c.Login__c => ValueProviderBuilder.provideUniqueString(),
                NGBS_Settings__c.Password__c => ValueProviderBuilder.provideUniqueString()
        })
                .create()
                .getRecord();

        Account account = (Account) new SObjectBuilder(Account.SObjectType)
                .setFields(new Map<SObjectField, Object>{
                        Account.Name => 'TestAccount',
                        Account.Billing_ID__c => ValueProviderBuilder.provideUniqueString(),
                        Account.RC_User_ID__c => ValueProviderBuilder.provideUniqueString(),
                        Account.BillingStreet => '2078 Adamsville Road',
                        Account.BillingCity => 'Laredo',
                        Account.BillingPostalCode => '78040',
                        Account.BillingState => 'Texas',
                        Account.BillingCountry => 'United States',
                        Account.EnabledLBO__c => true
                })
                .create()
                .getRecord();

        Contact cont = (Contact) new SObjectBuilder(Contact.SObjectType)
                .setFields(new Map<SObjectField, Object>{
                        Contact.FirstName => 'Test2',
                        Contact.LastName => 'Test2',
                        Contact.AccountId => account.Id,
                        Contact.Email => 'test@test.com',
                        Contact.Phone => '1234567890',
                        Contact.Preferred_Language__c => 'en_US'
                })
                .create()
                .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
                .setFields(new Map<SObjectField, Object>{
                        Opportunity.Name => 'Test1',
                        Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL,
                        Opportunity.Type => OpportunityHelper.OPPORTUNITY_TYPE_EX_BUSINESS,
                        Opportunity.RecordTypeId => OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY,
                        Opportunity.AccountId => account.Id,
                        Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                        Opportunity.CloseDate => System.today().addMonths(1),
                        Opportunity.Primary_Opportunity_Contact__c => cont.Id,
                        Opportunity.CurrencyIsoCode => RingCentralHelper.USD
                })
                .create()
                .getRecord();

        new SObjectBuilder(Quote.SObjectType)
                .setFields(new Map<SObjectField, Object>{
                Quote.Name => 'TestOBQuote',
                Quote.OpportunityId => opp.Id,
                Quote.Status => QuoteHelper.QUOTE_STATUS_DRAFT,
                Quote.Approved_Status__c => QuoteHelper.APPROVAL_STATUS_NOT_REQUIRED,
                Quote.Total_Number_of_Digital_Lines__c => 1,
                Quote.Start_Date__c => Date.today(),
                Quote.End_Date__c => Date.today().addDays(2),
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.Pricebook2Id => Test.getStandardPricebookId(),
                Quote.Package_Info__c => PACKAGE_INFO,
                Quote.Enabled_LBO__c => true
        })
                .create()
                .getRecord();
    }

    @IsTest
    private static void testGetObjectAPINameById() {
        ObjectMonitoringSettings__c objectMonitoringSettings = [
                SELECT Id, ObjectName__c, Name, ObjectFields__c
                FROM ObjectMonitoringSettings__c
                WHERE Name = 'Quote'
        ];

        String objectApiName = ObjectMonitoringHelper.getObjectAPINameById(objectMonitoringSettings.Id);
        System.assertEquals(objectApiName, ObjectMonitoringSettings__c.class.getName(), 'Object api name must be ObjectMonitoringSettings__c');
    }

    @IsTest
    public static void testCreateAccountObjectMonitoring() {
        Account testAcc = [SELECT Id,Name, EnabledLBO__c FROM Account WHERE Name = 'TestAccount'];

        System.assert(testAcc != null);

        Test.startTest();
        testAcc.EnabledLBO__c = false;
        update testAcc;
        Test.stopTest();

        List<ObjectMonitoring__c> objMonitoring = [SELECT Id FROM ObjectMonitoring__c WHERE ObjectName__c = 'Account'];

        System.assert(!objMonitoring.isEmpty());
    }

    @IsTest
    public static void testCreateQuoteObjectMonitoring() {
        Quote testQuote = [SELECT Id, Name, Enabled_LBO__c FROM Quote WHERE Name = 'TestOBQuote'];

        System.assert(testQuote != null);

        Test.startTest();
        testQuote.Enabled_LBO__c = false;
        update testQuote;
        Test.stopTest();

        List<ObjectMonitoring__c> objMonitoring = [SELECT Id FROM ObjectMonitoring__c WHERE ObjectName__c = 'Quote'];

        System.assert(!objMonitoring.isEmpty());
    }

        @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @IsTest
    private static void testGenerateCSVStructure() {
        Quote testQuote = [SELECT Id, Name, Enabled_LBO__c FROM Quote WHERE Name = 'TestOBQuote'];

        String csvText = ObjectMonitoringHelper.generateCSVStructure(testQuote.Id);

        System.debug(csvText != null);
        System.debug(csvText.contains('CreatedDate,Id,objectId,objectName,fieldName,newValue,oldValue,userId,triggerAction,comments,stackTrace'));
    }

    @IsTest
    private static void testCreateObjectMonitoring() {
        Id idops = (Id) new ValueProvider.DummyIdProvider(OpportunityRenewalSettings__c.sObjectType).getValue();
        Test.startTest();
        ObjectMonitoringHelper.createObjectMonitoring(idops, Quote.class.getName(), 'Enabled_LBO__c', 'true', 'false', String.valueOf(System.UserInfo.getUserId()), 'Add new OM');
        ObjectMonitoringHelper.createObjectMonitoring(idops, Quote.class.getName(), 'Enabled_LBO__c', 'false', 'true', String.valueOf(System.UserInfo.getUserId()), 'Add new OM', new DmlException().getStackTraceString());
        Test.stopTest();

        List<ObjectMonitoring__c> objMonitoring = [SELECT Id FROM ObjectMonitoring__c WHERE ObjectName__c = 'Quote' AND ObjectId__c = :idops];

        System.assert(!objMonitoring.isEmpty());
        System.assertEquals(objMonitoring.size(), 2, 'Size should be 2');
    }

    @IsTest
    private static void testGetTriggerAction() {

        Test.startTest();
        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
                .setFields(new Map<SObjectField, Object>{
                        Account.Name => 'TestAccount2',
                        Account.BillingStreet => '2078 Adamsville Road',
                        Account.BillingCity => 'Laredo',
                        Account.BillingPostalCode => '78040',
                        Account.BillingState => 'Texas',
                        Account.BillingCountry => 'United States',
                        Account.EnabledLBO__c => true
                })
                .create()
                .getRecord();

        testAccount.EnabledLBO__c = false;
        update testAccount;

        Test.stopTest();

        List<ObjectMonitoring__c> objMonitoring = [SELECT Id, TriggerAction__c FROM ObjectMonitoring__c WHERE ObjectName__c = 'Account' AND ObjectId__c = :testAccount.Id];

        System.assert(!objMonitoring.isEmpty());
        System.assertEquals(objMonitoring.size(), 2, 'Size should be 2');
        for (ObjectMonitoring__c objectMonitoring : objMonitoring) {
            System.assert(objectMonitoring.TriggerAction__c != null);
        }
    }
}