@isTest
public class Oppestimates12monthbookingTest {
    private static final String TEST_OPPORTUNITY_NAME = 'Test Opportunity';
    private static final String TEST_QUOTE_NAME = 'Test Quote';

    @testSetup
    static void setup() {
        new SObjectBuilder(Feature_Toggle__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {Feature_Toggle__c.ModifiedCloseOpportunityFlow__c => true})
            .create();

        Triggers.switchOff();
        Account testAccount = (Account) new SobjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => 'Test Account',
                Account.Type => AccountHelper.TYPE_CUSTOMER,
                Account.RecordTypeId => AccountHelper.RT_ID_CUSTOMER_ACCOUNT,
                Account.RC_Signup_Date__c => Date.Today().addDays(-365),
                Account.RC_Brand__c => OpportunityHelper.BRAND_RINGCENTRAL
            })
            .create()
            .getRecord();

        Contact testContact = (Contact) new SobjectBuilder(Contact.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Contact.LastName => 'TestContact',
                Contact.AccountId => testAccount.Id,
                Contact.RecordTypeId => ContactHelper.RT_ID_INTERNAL,
                Contact.Preferred_Language__c => ContactHelper.PREFERRED_LANGUAGE_EN_US,
                Contact.Lastname => 'Test Last Name',
                Contact.Email => 'test@ringcentral.com.test',
                Contact.Phone => '1234567890'
        })
            .create()
            .getRecord();

        new SobjectBuilder(AccountContactRole.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                AccountContactRole.AccountId => testAccount.Id,
                AccountContactRole.ContactId => testContact.Id,
                AccountContactRole.IsPrimary => true,
                AccountContactRole.Role => AccountContactRoleHelper.CONTACT_ROLE_RC_ADMIN_USER
            })
            .create();

        List<Opportunity> testOpportunities = (List<Opportunity>) new SobjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.Name => TEST_OPPORTUNITY_NAME,
                Opportunity.AccountId => testAccount.Id,
                Opportunity.RecordTypeId => OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY,
                Opportunity.Type => OpportunityHelper.OPPORTUNITY_TYPE_RENEWAL,
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                Opportunity.CloseDate => Date.Today() + 10,
                Opportunity.CurrencyIsoCode => OpportunityHelper.CURRENCY_ISO_CODE_USD,
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL,
                Opportunity.Sales_Model__c => OpportunityHelper.SALES_MODEL_DIRECT
            })
            .quantity(2)
            .build()
            .getRecords();
        testOpportunities[1].Name = TEST_OPPORTUNITY_NAME + 'NOT CHECKING THIS OPPORTUNITY';
        insert testOpportunities;

        List<Quote> testQuotes = (List<Quote>) new SobjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.Name => TEST_QUOTE_NAME,
                Quote.RecordTypeId => QuoteHelper.RT_ID_SALES,
                Quote.OpportunityId => testOpportunities[0].Id,
                Quote.Pricebook2Id => Test.getStandardPricebookId(),
                Quote.Upsell_Status__c => QuoteHelper.STATUS_UPSELL,
                Quote.Total_Number_of_Digital_Lines__c => 0,
                Quote.Initial_Term_months__c => '12',
                Quote.Account__c => testAccount.Id
            })
            .quantity(2)
            .build()
            .getRecords();
        testQuotes[0].Name = TEST_QUOTE_NAME + 'NOT CHECKING THIS QUOTE';
        testQuotes[1].OpportunityId = testOpportunities[1].Id;
        insert testQuotes;

        Product2 testProduct = (Product2) new SobjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Product2.Name => 'Test Product2',
                Product2.Family => 'Office',
                Product2.IsActive => true,
                Product2.Sub_Category__c => Product2Helper.SUBCATEGORY_RINGCENTRAL
            })
            .create()
            .getRecord();

        PricebookEntry testPbe = (PricebookEntry) new SObjectBuilder(PricebookEntry.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                PricebookEntry.Product2Id => testProduct.Id,
                PricebookEntry.UnitPrice => 100,
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false,
                PricebookEntry.Per_Line__c => false,
                PricebookEntry.Min_Quantity__c => 1,
                PricebookEntry.Max_Quantity__c => 100
            })
            .create()
            .getRecord();

        new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                QuoteLineItem.QuoteId => testQuotes[0].Id,
                QuoteLineItem.Product2Id => testProduct.Id,
                QuoteLineItem.PricebookEntryId => testPbe.Id,
                QuoteLineItem.Quantity => 5,
                QuoteLineItem.UnitPrice => testPbe.UnitPrice
            })
            .create();
        Triggers.switchOn();
    }

    @isTest
    static void testCustomCancel() {
        Opportunity testOpportunity = (Opportunity) new ListOptional(
            new OpportunitySelector()
                .selectOpportunityByName(TEST_OPPORTUNITY_NAME)
                .executeQuery()
        )
            .getFirst();

        Test.startTest();
            ApexPages.currentPage().getParameters().put('id',String.valueOf(testOpportunity.Id));
            ApexPages.StandardController standardController = new ApexPages.StandardController(testOpportunity);
            Oppestimates12monthbooking OppController = new Oppestimates12monthbooking(standardController);
            PageReference returnedReference = OppController.Customcancel();
        Test.stopTest();

        System.assertEquals('/' + testOpportunity.Id, returnedReference.getUrl(), 'Cancel operation should redirect to the original opportunity');

        Opportunity checkOpportunity = (Opportunity) new ListOptional(
            new OpportunitySelector()
                .newQueryFactory()
                .setFactoryName('selectOpportunityById')
                .selectField('StageName')
                .setCondition('Id = :bind0')
                .setQueryBindings(new List<Object> {testOpportunity.Id})
                .executeQuery()
        )
            .getFirst();
        System.assertEquals(testOpportunity.StageName, checkOpportunity.StageName, 'After cancel opportunity shouldn\'t change');

        Quote checkTestQuote = (Quote) new ListOptional(
            new QuoteSelector()
                .selectQuoteByName(TEST_QUOTE_NAME)
                .selectField('Quote_is_Invalid__c')
                .executeQuery()
        )
            .getFirst();
        System.assertEquals(false, checkTestQuote.Quote_is_Invalid__c, 'After cancel quote should not be invalid');
    }

    @isTest
    static void testCustomSave() {
        Opportunity testOpportunity = (Opportunity) new ListOptional(
                new OpportunitySelector()
                    .selectOpportunityByName(TEST_OPPORTUNITY_NAME)
                    .executeQuery()
            )
            .getFirst();
        testOpportunity.Downsell_Churn_Reason__c = 'Price Concession';
        testOpportunity.Downsell_Churn_Sub_Reason__c = 'Promotion';
        testOpportunity.Downgrade_Reason_Other__c = null;

        Test.startTest();
            ApexPages.currentPage().getParameters().put('id',String.valueOf(testOpportunity.Id));
            ApexPages.StandardController standardController = new ApexPages.StandardController(testOpportunity);
            Oppestimates12monthbooking OppController = new Oppestimates12monthbooking(standardController);
            PageReference returnedReference = OppController.Customsave();
        Test.stopTest();

        System.assertEquals('/' + testOpportunity.Id, returnedReference.getUrl(), 'Successful save operation should redirect to the original opportunity');

        Opportunity checkOpportunity = (Opportunity) new ListOptional(
                new OpportunitySelector()
                    .newQueryFactory()
                    .setFactoryName('selectOpportunityById')
                    .selectField('StageName')
                    .setCondition('Id = :bind0')
                    .setQueryBindings(new List<Object> {testOpportunity.Id})
                    .executeQuery()
            )
            .getFirst();
        System.assertEquals(OpportunityHelper.STAGE_NAME_CLOSED_WON, checkOpportunity.StageName, 'After successful save opportunity should have closed won stage');

        Quote checkTestQuote = (Quote) new ListOptional(
            new QuoteSelector()
                .selectQuoteByName(TEST_QUOTE_NAME)
                .selectField('Quote_is_Invalid__c')
                .executeQuery()
            )
            .getFirst();
        System.assertEquals(true, checkTestQuote.Quote_is_Invalid__c, 'After successful save quote should be invalid');
    }
}