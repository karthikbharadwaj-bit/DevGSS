@isTest
public with sharing class Test_SWNDataCollector {
    private static final String ACC_NAME = 'Test Acc';
    private static final String OPP_NAME = 'Test Opp';
    private static final String QUOTE_NAME = 'Test Quote';
    private static final String PROSERV_QUOTE_NAME = 'Test ProservQuote';
    private static final String QUOTELINEITEM_NAME = 'Test QuoteLineItem';
    private static final String PACKAGE_INFO = '[{"id":"18","version":"1","packageInfo":{"id":9710001}}]';

    @IsTest
    static void testCollectingWithSOQL() {
        Triggers.switchOff();
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, ACC_NAME)
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.Name => OPP_NAME,
                Opportunity.AccountId => acc.Id,
                Opportunity.CloseDate => System.today()
            })
            .create()
            .getRecord();

        Quote testQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.Name => QUOTE_NAME,
                Quote.OpportunityId => opp.Id
            })
            .build()
            .getRecord();

        Quote proservQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.Name => PROSERV_QUOTE_NAME,
                Quote.OpportunityId => opp.Id,
                Quote.ProServ_Status__c => QuoteHelper.PROSERVSTATUS_SYNCED,
                Quote.RecordTypeId => QuoteHelper.RT_ID_PROSERV
            })
            .build()
            .getRecord();

        insert new List<Quote> {testQuote, proservQuote};

        Cost_Center__c costCenter = (Cost_Center__c) new SObjectBuilder(Cost_Center__c.SObjectType)
            .setField(Cost_Center__c.Quote__c, testQuote.Id)
            .create()
            .getRecord();
        Triggers.switchOn();
        SWNDataCollector sdc = new SWNDataCollector(testQuote.Id);
        Assert.areEqual(testQuote.Id, sdc.qt.Id, 'Wrong quote was selected');
        Assert.areEqual(PROSERV_QUOTE_NAME, sdc.proservQuotes[0].Name, 'Wrong prosserv quote was selected');
        Assert.areEqual(costCenter.Id, sdc.costCenters[0].Id, 'Wrong cost center was selected');
    }

    @IsTest
    static void testCollectingDataWithoutSOQL() {
        Triggers.switchOff();
        upsert new NGBS_Settings__c(
            BaseEndpoint__c = 'https://testapi',
            AccountManagerPath__c = '/restapi/account-manager/v1.0',
            Login__c = '123',
            Password__c = '456'
        );
        Triggers.switchOn();
        BillingHttpRequestMock tstMock = new BillingHttpRequestMock();
        Test.setMock(HttpCalloutMock.class, tstMock);


        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => ValueProviderBuilder.provideUniqueString(),
                Account.Billing_ID__c => '123'
            })
            .build()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setField(Opportunity.Name, OPP_NAME)
            .build()
            .getRecord();

        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.Id => ValueProviderBuilder.provideDummyId(Quote.SObjectType),
                Quote.Package_Info__c => PACKAGE_INFO
            })
            .build()
            .getRecord();

        QuoteLineItem qli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setField(QuoteLineItem.Display_Name__c, QUOTELINEITEM_NAME)
            .build()
            .getRecord();

        ServiceInfo__c serviceInfo = (ServiceInfo__c) new SObjectBuilder(ServiceInfo__c.SObjectType)
            .setField(ServiceInfo__c.Id, ValueProviderBuilder.provideDummyId(ServiceInfo__c.SObjectType))
            .build()
            .getRecord();

        qt = (Quote) Test_Utils.putIntoUnwritableFields(
            qt,
            Quote.class,
            new Map<String, Object> {
                'Account' => acc,
                'Opportunity' => opp
            }
        );

        qt = (Quote) Test_Utils.putIntoUnwritableField(
            qt,
            Quote.class,
            'QuoteLineItems',
            new List<QuoteLineItem> { qli }
        );

        qt = (Quote) Test_Utils.putIntoUnwritableField(
            qt,
            Quote.class,
            'ServiceInfo__r',
            new List<ServiceInfo__c> { serviceInfo }
        );

        SWNDataCollector sdc = new SWNDataCollector();
        sdc.qt = qt;
        Assert.areEqual(qt.Id, sdc.qt.Id, 'Wrong Quote was returned');
        Assert.areEqual(opp.Name, sdc.opp.Name, 'Wrong Opportunity was returned');
        Assert.areEqual(acc.Name, sdc.acc.Name, 'Wrong Account was returned');
        Assert.areEqual(qli.Display_Name__c, sdc.qlis[0].Display_Name__c, 'Wrong Qli was returned');
        Assert.isTrue(sdc.isMPUB, 'Wrong isMPUB value was returned');
        Assert.areEqual(acc.Billing_ID__c, sdc.billingId, 'Wrong BillingId value was returned');
        Test.startTest();
            Assert.areEqual('9710001', sdc.ngbsPackage.id, 'Wrong packageId was returned');
            Assert.areEqual('42775001', sdc.billingContracts[0].id, 'Contract must be returned');
        Test.stopTest();
    }
}