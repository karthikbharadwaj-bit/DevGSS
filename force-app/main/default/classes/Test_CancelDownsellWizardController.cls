@isTest
private class Test_CancelDownsellWizardController {

    @testSetup static void prepareData() {
        Id pricebookId = Test.getStandardPricebookId();

        Pricebook2 pbk = new Pricebook2(
            Id = pricebookId,
            Line_Range_Min__c = -5000,
            Line_Range_Max__c = 5000
        );

        update pbk;

        Account testAccount = new Account(Name='Opty test account',
                Permitted_Brands__c='RingCentral',
                RC_Brand__c = 'RingCentral',
                RC_Tier__c = 'Office',
                CurrencyIsoCode='USD');
        insert testAccount;

        Contact testContact = new Contact();
        testContact.AccountId =  testAccount.id;
        testContact.Email = 'fake@email.com';
        testContact.LastName = 'TestLast';
        testContact.Phone='9910106804';
        insert testContact;

        Pricebook2 testPriceBook = new Pricebook2(
            Name = 'Test Price Book',
            Description ='Test Price Book Products',
            IsActive = true,
            Line_Range_Min__c = 5,
            Line_Range_Max__c = 10,
            CurrencyIsoCode = 'USD'
        );
        insert testPriceBook;

        List<Product2> prodList = new List<Product2>();

        Product2 testProduct = new Product2(
            Name = 'basic tier',
            IsActive = true,
            Sub_Category__c = 'Main',
            Family = 'Service',
            CurrencyIsoCode = 'USD',
            Charge_Term__c = 'Monthly - Contract'
        );
        prodList.add(testProduct);

        testProduct = new Product2(
            Name = 'basic fee',
            IsActive = true,
            Sub_Category__c = 'Main',
            Family = 'Minutes Bundle',
            CurrencyIsoCode = 'USD',
            Charge_Term__c = 'Monthly - Contract',
            Number_of_Minutes__c = 1000
        );
        prodList.add(testProduct);

        testProduct = new Product2(
            Name = 'basic fee',
            IsActive = true,
            Sub_Category__c = 'Main',
            Family = 'Discounted Phones',
            CurrencyIsoCode = 'USD',
            Charge_Term__c = 'One - Time'
        );
        prodList.add(testProduct);

        insert prodList;

        List<PricebookEntry> pbesList = new List<PricebookEntry>();
        PricebookEntry pbe;
        List<Entitlement__c> entls = new List<Entitlement__c>();
        Entitlement__c entl;

        for (Product2 pr : prodList) {
            pbe = new PricebookEntry(
                Pricebook2Id = pricebookId,
                Product2Id = pr.Id,
                UnitPrice = 200,
                IsActive = true,
                UseStandardPrice = false,
                CurrencyIsoCode = 'USD'
            );
            pbesList.add(pbe);

            pbe = new PricebookEntry(
                Pricebook2Id = testPriceBook.Id,
                Product2Id = pr.Id,
                UnitPrice = 200,
                IsActive = true,
                UseStandardPrice = false,
                Per_Line__c = false,
                CurrencyIsoCode = 'USD'
            );
            pbesList.add(pbe);

            entl = new Entitlement__c(
                Product__c = pr.Id,
                Active__c = true,
                Account__c = testAccount.Id,
                Price__c = 200,
                Discount__c = 20,
                Discount_Type__c = QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY,
                Quantity__c = 7
            );
            entls.add(entl);
        }
        insert pbesList;
        insert entls;

    RetentionOptionVisibility__c retentionSetting = new RetentionOptionVisibility__c();
    retentionSetting.RoleName__c = 'Retention - Michael';
    insert retentionSetting;
    }

    @isTest static void testOpportunityCreation() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        CancelDownsellWizardController.AccountDeactivationParams prms = new CancelDownsellWizardController.AccountDeactivationParams();

        prms.accountId = acc.Id;
        prms.churn = new CancelDownsellWizardController.CancelSurvey();
        prms.churn.option = 'Customer changed mind';
        prms.churn.suboption = 'Contract concerns';
        prms.churn.details = 'test details';
        prms.replacement = new CancelDownsellWizardController.CancelSurvey();
        prms.replacement.option = 'Hosted PBX';
        prms.replacement.suboption = 'Avaya Live';
        prms.replacement.details = 'test details';

        String oppParams = JSON.serialize(prms);
        Opportunity opty;

        Test.startTest();
        opty = CancelDownsellWizardController.createCancelOpportunity(oppParams);
        Test.stopTest();

        Schema.DescribeSObjectResult objectDesc = Opportunity.SObjectType.getDescribe();
        Map<String, Schema.RecordTypeInfo> rtMapByName = objectDesc.getRecordTypeInfosByName();

        System.assertEquals(opty.RecordTypeID, rtMapByName.get('Cancel Opportunity').getRecordTypeId());
        System.assertEquals(opty.Churn_reason__c, prms.churn.option);
        System.assertEquals(opty.Sub_Churn_reason__c, prms.churn.suboption);
        System.assertEquals(opty.Sub_Churn_reason_detail_text__c, prms.churn.details);
    }

    @isTest static void testQuoteCreationAndDownsellCheck() {

        Feature_Toggle__c featureToggle = new Feature_Toggle__c(
            ModifiedCloseOpportunityFlow__c = true
        );
        insert featureToggle;

        Account acc = [SELECT Id, CurrencyIsoCode FROM Account LIMIT 1];
        Contact cont = [SELECT Id FROM Contact WHERE AccountId = :acc.Id LIMIT 1];

        CancelDownsellWizardController.AccountDeactivationParams prms = new CancelDownsellWizardController.AccountDeactivationParams();
        prms.accountId = acc.Id;
        prms.churn = new CancelDownsellWizardController.CancelSurvey();
        prms.churn.option = 'Customer changed mind';
        prms.churn.suboption = 'Contract concerns';
        prms.churn.details = 'test details';
        prms.replacement = new CancelDownsellWizardController.CancelSurvey();
        prms.replacement.option = 'Hosted PBX';
        prms.replacement.suboption = 'Avaya Live';
        prms.replacement.details = 'test details';

        String oppParams = JSON.serialize(prms);
        Opportunity opty = CancelDownsellWizardController.createCancelOpportunity(oppParams);

        Quote qt;
        Map<String, String> params = new Map<String, String>();
        params.put('accountId', acc.Id);
        params.put('opportunityId', opty.Id);
        params.put('contactId', cont.Id);
        params.put('Name', 'test Name');
        params.put('currency', acc.CurrencyIsoCode);

        List<Entitlement__c> entls = [SELECT Id FROM Entitlement__c WHERE Account__c = :acc.Id];

        Test.startTest();

        qt = CancelDownsellWizardController.createCancelQuote(params);

        Test.stopTest();

        String downsellWizardType =
            (CancelDownsellWizardController.isAllowToShowOptions(UserInfo.getUserId()))
                ? 'downsellwithretention' : 'downsell';
        String expectedRedirectLink = '/apex/DowngradeWizard?wizardType=' + downsellWizardType + '&opportunityInfo=';

        List<QuoteLineItem> qlis = [SELECT Id FROM QuoteLineItem WHERE QuoteId = :qt.Id];
        Boolean isSingle = [
                            SELECT count()
                            FROM Opportunity
                            WHERE AccountId = :qt.Account__c
                            AND RecordTypeId IN :new Set<Id>{QuoteHelper.RT_ID_SALES, QuoteHelper.RT_ID_BILLING}
                            ] <= 1;

        System.assertEquals(entls.size(), qlis.size());
        System.assertEquals(qt.Name, 'Cancel Quote');
        System.assertEquals(qt.Pricebook2Id, Test.getStandardPricebookId());

        Opportunity reselectedOpp = [SELECT Id, ConfirmAndClose__c FROM Opportunity WHERE Id = :opty.Id];
        System.assertEquals(reselectedOpp.ConfirmAndClose__c, false);
    }

    @isTest static void testOrderGeneration() {
        Account acc = [SELECT Id, CurrencyIsoCode FROM Account LIMIT 1];
        Contact cont = [SELECT Id FROM Contact WHERE AccountId = :acc.Id LIMIT 1];

        CancelDownsellWizardController.AccountDeactivationParams prms = new CancelDownsellWizardController.AccountDeactivationParams();
        prms.accountId = acc.Id;
        prms.churn = new CancelDownsellWizardController.CancelSurvey();
        prms.churn.option = 'Customer changed mind';
        prms.churn.suboption = 'Contract concerns';
        prms.churn.details = 'test details';
        prms.replacement = new CancelDownsellWizardController.CancelSurvey();
        prms.replacement.option = 'Hosted PBX';
        prms.replacement.suboption = 'Avaya Live';
        prms.replacement.details = 'test details';

        String oppParams = JSON.serialize(prms);
        Opportunity opty = CancelDownsellWizardController.createCancelOpportunity(oppParams);

        Quote qt;
        Map<String, String> params = new Map<String, String>();
        params.put('accountId', acc.Id);
        params.put('opportunityId', opty.Id);
        params.put('contactId', cont.Id);
        params.put('Name', 'test Name');
        params.put('currency', acc.CurrencyIsoCode);

        List<Entitlement__c> entls = [SELECT Id FROM Entitlement__c WHERE Account__c = :acc.Id];

        String checkDownsellResult;

        Test.startTest();
        qt = CancelDownsellWizardController.createCancelQuote(params);

        CancelDownsellWizardController.GenerateOrdersResult result1;
        CancelDownsellWizardController.GenerateOrdersResult result2;
        Test.stopTest();

        result1 = CancelDownsellWizardController.createCancelOrder(opty.Id);
        //result2 = CancelDownsellWizardController.createCancelOrder(opty.Id);

        Order ord = [SELECT Id, (SELECT Id FROM OrderItems) FROM Order LIMIT 1];

        System.assertEquals(3, ord.OrderItems.size());
        //System.assertEquals('No orders created because Quote has no items', result2.message);
    }

    @isTest static void testCancelAccount() {
        Account acc = [SELECT Id, CurrencyIsoCode FROM Account LIMIT 1];

        Test.startTest();
        CancelDownsellWizardController.cancelAccount(acc.Id);
        Test.stopTest();

        Account resultAcc = [SELECT Id, RC_Account_Status__c FROM Account WHERE Id = :acc.Id];

        System.assertEquals('Disabled', resultAcc.RC_Account_Status__c);
    }

    @isTest static void testUpdateDownsellOpportunity() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        CancelDownsellWizardController.AccountDeactivationParams prms = new CancelDownsellWizardController.AccountDeactivationParams();

        prms.accountId = acc.Id;
        prms.churn = new CancelDownsellWizardController.CancelSurvey();
        prms.churn.option = 'Customer changed mind';
        prms.churn.suboption = 'Contract concerns';
        prms.churn.details = 'test details';
        prms.replacement = new CancelDownsellWizardController.CancelSurvey();
        prms.replacement.option = 'Hosted PBX';
        prms.replacement.suboption = 'Avaya Live';
        prms.replacement.details = 'test details';

        String oppParams = JSON.serialize(prms);
        Opportunity opty = CancelDownsellWizardController.createCancelOpportunity(oppParams);

        CancelDownsellWizardController.DownsellOpportunityParams dprms = new CancelDownsellWizardController.DownsellOpportunityParams();
        dprms.opportunityId = opty.Id;
        // dprms.change = 'Premium Support;Service Change;';
        dprms.change = dprms.churn = new CancelDownsellWizardController.CancelSurvey();
        dprms.change.option = 'Premium Support;Service Change;';
        dprms.churn = new CancelDownsellWizardController.CancelSurvey();
        dprms.churn.option = 'Business Mortality';
        dprms.churn.suboption = 'Closing location';
        dprms.churn.details = 'no details';
        dprms.replacement = new CancelDownsellWizardController.CancelSurvey();
        dprms.replacement.option = 'On-Premise PBX';
        dprms.replacement.suboption = 'Microsoft Lync';
        dprms.replacement.details = 'Microsoft Lync';

        Test.startTest();
            CancelDownsellWizardController.updateDownsellOpportunity(JSON.serialize(dprms));
        Test.stopTest();

        Opportunity ropty = [SELECT Id, Churn_reason__c, Sub_Churn_reason__c,
                                    Sub_Churn_reason_detail_text__c, Replacement_option__c,
                                    Replacement_suboption__c, Replacement_suboption_detail_text__c,
                                    Service_change_options__c
                                FROM Opportunity
                                WHERE Id = :opty.Id];

        System.assertEquals('Premium Support;Service Change', ropty.Service_change_options__c);
        System.assertEquals('Business Mortality', ropty.Churn_reason__c);
        System.assertEquals('Closing location', ropty.Sub_Churn_reason__c);
        System.assertEquals('no details', ropty.Sub_Churn_reason_detail_text__c);
        System.assertEquals('On-Premise PBX', ropty.Replacement_option__c);
        System.assertEquals('Microsoft Lync', ropty.Replacement_suboption__c);
        System.assertEquals('Microsoft Lync', ropty.Replacement_suboption_detail_text__c);
    }

    @isTest static void testControllerConstructor() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        ApexPages.currentPage().getParameters().put('accId', acc.Id);
        ApexPages.currentPage().getParameters().put('oppId', acc.Id);
        ApexPages.currentPage().getParameters().put('type', 'downsell');

        CancelDownsellWizardController cdw;

        Test.startTest();
        cdw = new CancelDownsellWizardController();
        Test.stopTest();

        System.assertEquals(acc.Id, cdw.accId);
        System.assertEquals(acc.Id, cdw.oppId);
        System.assertEquals('downsell', cdw.type);
    }

  @isTest static void testIsAllowToShowOptions() {
    id currentUserRoleId = UserInfo.getUserRoleId();

    Test.startTest();
    Boolean result = CancelDownsellWizardController.isAllowToShowOptions(currentUserRoleId);
    Test.stopTest();

    System.assertEquals(result, false);
  }

  @isTest static void testUpdateCloseOpportunity() {
    Account acc = [SELECT Id, Name FROM Account LIMIT 1];

    Opportunity opp = new Opportunity(
      Name = acc.Name,
      AccountId = acc.Id,
      Description = acc.Name,
      StageName = '1. Qualify',
      Type = 'Existing Business',
      CloseDate = System.today()
        );

    insert opp;

    CancelDownsellWizardController.CloseOpportunityParams prms = new CancelDownsellWizardController.CloseOpportunityParams();

    date testDate = date.newInstance(2000, 01, 01);

    prms.opportunityId = opp.Id;
    prms.opp = opp;

    prms.who_did_we_beat = new CancelDownsellWizardController.CancelSurvey();
    prms.who_did_we_beat.option = 'test option';
    prms.who_did_we_beat.suboption = 'test suboption';
    prms.who_did_we_beat.details = 'test details';
    prms.who_did_we_beat.detailsDate = testDate;

    prms.what_are_we_replacing = new CancelDownsellWizardController.CancelSurvey();
    prms.what_are_we_replacing.option = 'test option';
    prms.what_are_we_replacing.suboption = 'test suboption';
    prms.what_are_we_replacing.details = 'test details';
    prms.what_are_we_replacing.detailsDate = testDate;

    prms.why_did_we_win = new CancelDownsellWizardController.CancelSurvey();
    prms.why_did_we_win.option = 'test option';
    prms.why_did_we_win.suboption = 'test suboption';
    prms.why_did_we_win.details = 'test details';
    prms.why_did_we_win.detailsDate = testDate;

    prms.retention = new CancelDownsellWizardController.CancelSurvey();
    prms.retention.option = 'Saved';
    prms.retention.suboption = null;
    prms.retention.details = null;
    prms.retention.detailsDate = null;

    String oppParams = JSON.serialize(prms);


    Test.startTest();
    CancelDownsellWizardController.updateCloseOpportunity(JSON.serialize(prms));
    Test.stopTest();

    Opportunity updatedOpp = [SELECT Id, StageName, Retention__c,
                    Why_did_we_win_option__c,
                    Who_did_we_beat_option__c, Who_did_we_beat_suboptions__c,
                    What_are_we_replacing_option__c, What_are_we_replacing_suboption__c
                FROM Opportunity WHERE Id = :opp.Id];

    System.assertEquals('0. Downgraded', updatedOpp.StageName);
    System.assertEquals('Saved', updatedOpp.Retention__c);

    System.assertEquals('test option', updatedOpp.Why_did_we_win_option__c);
    
    System.assertEquals('test option', updatedOpp.Who_did_we_beat_option__c);
    System.assertEquals('test suboption', updatedOpp.Who_did_we_beat_suboptions__c);

    System.assertEquals('test option', updatedOpp.What_are_we_replacing_option__c);
    System.assertEquals('test suboption', updatedOpp.What_are_we_replacing_suboption__c);
    }

    @isTest static void testMakeQuotesInvalid() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        // Opportunity which is going to be closed
        Opportunity opty = new Opportunity(
            Name = 'change order',
            AccountId = acc.id,
            CloseDate = System.today(),
            StageName = OpportunityHelper.STAGE_NAME_QUALIFY,
            Type = 'Existing Business',
            Brand_Name__c = 'RingCentral',
            Tier_Name__c = 'Office',
            CurrencyIsoCode = 'USD',
            Forecasted_Users__c = 0,
            Forecast_Contact_Center_Users__c = 0,
            ForcastedDimeloUsers__c = 0,
            Forecast_Connect_First_Users__c = 0,
            Forecasted_Global_Office_Users__c = 0,
            Forecasted_RingCentral_Video_Users__c = 0,
            Forecasted_Events_Users__c = 0,
            Estimated_12M_Office_Pipeline__c = 0,
            Estimated_12M_Contact_Center_Pipeline__c = 0,
            Estimated_12M_Engage_Digital_Pipeline__c = 0,
            Estimated_12M_Engage_Voice_Pipeline__c = 0,
            Estimated_12M_Global_Office_Pipeline__c = 0,
            Estimated_12M_RingCentral_Video_Pipeline__c = 0,
            Estimated_12M_RC_Events_Pipeline__c = 0);

        // Prepare test opportunities
        Opportunity testOpty1 = new Opportunity(Name = 'opty1', AccountId = acc.Id, StageName = OpportunityHelper.STAGE_NAME_QUALIFY, CloseDate = System.today(), Type = 'Existing Business', Brand_Name__c = 'RingCentral', Tier_Name__c = 'Office', CurrencyIsoCode = 'USD', Forecasted_Users__c = 10, Forecasted_Events_Users__c = 0, Estimated_12M_Office_Pipeline__c = 0, Estimated_12M_Contact_Center_Pipeline__c = 0, Estimated_12M_Engage_Digital_Pipeline__c = 0, Estimated_12M_Engage_Voice_Pipeline__c = 0, Estimated_12M_Global_Office_Pipeline__c = 0, Estimated_12M_RingCentral_Video_Pipeline__c = 0, Estimated_12M_RC_Events_Pipeline__c = 0);
        Opportunity testOpty2 = new Opportunity(Name = 'opty2', AccountId = acc.Id, StageName = OpportunityHelper.closedStage, CloseDate = System.today(), Type = 'Existing Business', Brand_Name__c = 'RingCentral', Tier_Name__c = 'Office', CurrencyIsoCode = 'USD', Forecasted_Users__c = 10, Forecasted_Events_Users__c = 0, Estimated_12M_Office_Pipeline__c = 0, Estimated_12M_Contact_Center_Pipeline__c = 0, Estimated_12M_Engage_Digital_Pipeline__c = 0, Estimated_12M_Engage_Voice_Pipeline__c = 0, Estimated_12M_Global_Office_Pipeline__c = 0, Estimated_12M_RingCentral_Video_Pipeline__c = 0, Estimated_12M_RC_Events_Pipeline__c = 0);
        Opportunity testOpty3 = new Opportunity(Name = 'opty3', AccountId = acc.Id, StageName = OpportunityHelper.STAGE_NAME_DOWNGRADED, Downgrade_Reason_Opp__c = 'Lost', Primary_Competitor__c = '8x8', CloseDate = System.today(), Type = 'Existing Business', Brand_Name__c = 'RingCentral', Tier_Name__c = 'Office', CurrencyIsoCode = 'USD', Forecasted_Users__c = 10, Forecasted_Events_Users__c = 0, Estimated_12M_Office_Pipeline__c = 0, Estimated_12M_Contact_Center_Pipeline__c = 0, Estimated_12M_Engage_Digital_Pipeline__c = 0, Estimated_12M_Engage_Voice_Pipeline__c = 0, Estimated_12M_Global_Office_Pipeline__c = 0, Estimated_12M_RingCentral_Video_Pipeline__c = 0, Estimated_12M_RC_Events_Pipeline__c = 0);
        Opportunity testOpty4 = new Opportunity(Name = 'change order', AccountId = acc.Id, StageName = OpportunityHelper.STAGE_NAME_QUALIFY, CloseDate = System.today(), Type = 'Existing Business', Brand_Name__c = 'RingCentral', Tier_Name__c = 'Office', CurrencyIsoCode = 'USD', Forecasted_Users__c = 10, Forecasted_Events_Users__c = 0, Estimated_12M_Office_Pipeline__c = 0, Estimated_12M_Contact_Center_Pipeline__c = 0, Estimated_12M_Engage_Digital_Pipeline__c = 0, Estimated_12M_Engage_Voice_Pipeline__c = 0, Estimated_12M_Global_Office_Pipeline__c = 0, Estimated_12M_RingCentral_Video_Pipeline__c = 0, Estimated_12M_RC_Events_Pipeline__c = 0);
        
        insert (new List<Opportunity>{opty, testOpty1, testOpty2, testOpty3, testOpty4});

        Quote testQuote = new Quote(
            Name = 'testQuote',
            OpportunityId = opty.id,
            RecordTypeId = QuoteHelper.RT_ID_SALES,
            Pricebook2Id = Test.getStandardPricebookId(),
            Account__c = acc.Id
        );
        // Opty is not closed => should be invalidated
        Quote testQuote1 = new Quote(
            Name = 'testQuote1',
            OpportunityId = testOpty1.id,
            RecordTypeId = QuoteHelper.RT_ID_SALES,
            Pricebook2Id = Test.getStandardPricebookId(),
            Account__c = acc.Id
        );
        // Opty is not closed but quote record type == proserv => should not be invalidated
        Quote testQuote2 = new Quote(
            Name = 'testQuote2',
            OpportunityId = testOpty1.id,
            RecordTypeId = QuoteHelper.RT_ID_PROSERV,
            Pricebook2Id = Test.getStandardPricebookId(),
            Account__c = acc.Id
        );
        // Opty is closed => should not be invalidated
        Quote testQuote3 = new Quote(
            Name = 'testQuote3',
            OpportunityId = testOpty2.id,
            RecordTypeId = QuoteHelper.RT_ID_SALES,
            Pricebook2Id = Test.getStandardPricebookId(),
            Account__c = acc.Id
        );
        // Opty is downgraded => should not be invalidated
        Quote testQuote4 = new Quote(
            Name = 'testQuote4',
            OpportunityId = testOpty3.id,
            RecordTypeId = QuoteHelper.RT_ID_SALES,
            Pricebook2Id = Test.getStandardPricebookId(),
            Account__c = acc.Id
        );
        // Opty is change order => should not be invalidated
        Quote testQuote5 = new Quote(
            Name = 'testQuote5',
            OpportunityId = testOpty4.id,
            RecordTypeId = QuoteHelper.RT_ID_SALES,
            Pricebook2Id = Test.getStandardPricebookId(),
            Account__c = acc.Id
        );
        insert (new List<Quote>{testQuote, testQuote1, testQuote2, testQuote3, testQuote4, testQuote5});

        // Prepare params to pass
        CancelDownsellWizardController.DownsellOpportunityParams dprms = new CancelDownsellWizardController.DownsellOpportunityParams();
        dprms.opportunityId = opty.Id;
        dprms.change = dprms.churn = new CancelDownsellWizardController.CancelSurvey();
        dprms.change.option = 'Premium Support;Service Change;';
        dprms.churn = new CancelDownsellWizardController.CancelSurvey();
        dprms.churn.option = 'Business Mortality';
        dprms.churn.suboption = 'Closing location';
        dprms.churn.details = 'no details';
        dprms.replacement = new CancelDownsellWizardController.CancelSurvey();
        dprms.replacement.option = 'On-Premise PBX';
        dprms.replacement.suboption = 'Microsoft Lync';
        dprms.replacement.details = 'Microsoft Lync';

        Test.startTest();
            CancelDownsellWizardController.updateDownsellOpportunity(JSON.serialize(dprms));
            // Only the first quote fits the criteria to be invalidated
            for (Quote qt : [SELECT Id, Quote_is_Invalid__c, Name FROM Quote]) {
                if (qt.Name == 'testQuote1')  {
                    System.assertEquals(false, qt.Quote_is_Invalid__c);
                }
                if (qt.Name == 'testQuote2')  {
                    System.assertEquals(false, qt.Quote_is_Invalid__c);
                }
                if (qt.Name == 'testQuote3')  {
                    System.assertEquals(false, qt.Quote_is_Invalid__c);
                }
                if (qt.Name == 'testQuote4')  {
                    System.assertEquals(false, qt.Quote_is_Invalid__c);
                }
                if (qt.Name == 'testQuote5')  {
                    System.assertEquals(false, qt.Quote_is_Invalid__c);
                }
            }

            // Rerun test flow when not change order is going ro be closed
            opty.Name = 'test';
            update opty;
            CancelDownsellWizardController.updateDownsellOpportunity(JSON.serialize(dprms));
            for (Quote qt : [SELECT Id, Quote_is_Invalid__c, Name FROM Quote]) {
                if (qt.Name == 'testQuote1')  {
                    System.assertEquals(true, qt.Quote_is_Invalid__c);
                }
                if (qt.Name == 'testQuote2')  {
                    System.assertEquals(false, qt.Quote_is_Invalid__c);
                }
                if (qt.Name == 'testQuote3')  {
                    System.assertEquals(false, qt.Quote_is_Invalid__c);
                }
                if (qt.Name == 'testQuote4')  {
                    System.assertEquals(false, qt.Quote_is_Invalid__c);
                }
                if (qt.Name == 'testQuote5')  {
                    System.assertEquals(false, qt.Quote_is_Invalid__c);
                }
            }
        Test.stopTest();
    }
}