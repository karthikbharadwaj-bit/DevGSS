@isTest
public with sharing class Test_OpportunityMethods {
    @isTest
    static void testGettingDocumentProcessRunOnlyOneQuery() {
        Document doc = (Document) new SObjectBuilder(Document.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Document.Name => 'Product_Forecast_Amounts',
                Document.Body => Blob.valueOf('Test body for document'),
                Document.ContentType => 'application/pdf',
                Document.IsPublic => true,
                Document.FolderId => UserInfo.getUserId()})
            .create()
            .getRecord();
        Integer queryLimitBeforeRun;
        Integer queryLimitAfterRun;

        Test.startTest();
            queryLimitBeforeRun = Limits.getQueries();
            OpportunityMethods.getAmountByBrandAndTier();

            queryLimitAfterRun = Limits.getQueries();
        Test.stopTest();

        Assert.areEqual(1, queryLimitAfterRun - queryLimitBeforeRun, 'Query for Documents should be executed only 1 time');
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testAmountBasedOnForecastCSV() {
        User userNotEnterprise = (User) new SObjectBuilder (User.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    User.LastName => 'TestSysAdm',
                    User.Username => 'SysAdm!user@gmail.com',
                    User.Email => 'SysAdm_user@gmail.com',
                    User.Alias => 'Test',
                    User.TimeZoneSidKey => 'America/Los_Angeles',
                    User.ManagerId => UserInfo.getUserId(),
                    User.LocaleSidKey => 'en_US',
                    User.EmailEncodingKey => 'UTF-8',
                    User.ProfileId => [SELECT Id, Name FROM Profile WHERE Name = 'System Administrator'].Id,
                    User.LanguageLocaleKey => 'en_US',
                    User.Hierarchy_Role__c => 'Sales Rep'
                }
            )
            .create()
            .getRecord();
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => 'testAcc'
                }
            )
            .create()
            .getRecord();
        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.FirstName => 'Test1',
                    Contact.LastName => 'Test1',
                    Contact.AccountId => acc.Id,
                    Contact.Email => 'something@mostcommon.fake',
                    Contact.Phone => '1234567890',
                    Contact.Preferred_Language__c => 'en_US'
                }
            )
            .create()
            .getRecord();

        Document doc = (Document) new SObjectBuilder(Document.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Document.Name => 'Product_Forecast_Amounts',
                Document.Body => Blob.valueOf('Brand,Service,Price,Forecasted User Range\nRingCentral,Office,100,1\nRingCentral,Office,10,2-99'),
                Document.ContentType => 'text/csv',
                Document.IsPublic => true,
                Document.FolderId => userNotEnterprise.Id
            })
            .create()
            .getRecord();

        Test.startTest();
        System.runAs(userNotEnterprise) {
            Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Opportunity.Name => 'Test Opportunity 2016',
                        Opportunity.Type => 'Syndicated - New',
                        Opportunity.StageName => 'Planning',
                        Opportunity.CloseDate => system.today().addMonths(1),
                        Opportunity.AccountId => acc.Id,
                        Opportunity.Primary_Opportunity_Contact__c => con.Id,
                        Opportunity.Brand_Name__c => 'RingCentral',
                        Opportunity.Tier_Name__c => 'Office',
                        Opportunity.Forecasted_Users__c => 15
                    }
                )
                .create()
                .getRecord();

            Quote quote = (Quote) new SObjectBuilder(Quote.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                            Quote.Name => 'quotetest',
                            Quote.OpportunityId => opp.Id,
                            Quote.Total_Number_of_Digital_Lines__c => 10,
                            Quote.Account__c => opp.AccountId,
                            Quote.ProServ_Sold_Date__c => System.now(),
                            Quote.Pricebook2Id => Test.getStandardPricebookId(),
                            Quote.RecordTypeId => QuoteHelper.RT_ID_PROSERV,
                            Quote.Upsell_Status__c => 'New',
                            Quote.isPrimary__c => true
                        }
                )
                .create()
                .getRecord();
        }

        Test.stopTest();
    }

    @isTest
    static void testPipelineSourceQuoteAmounts() {
        Triggers.switchOff();
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => 'testAcc'
                }
            )
            .create()
            .getRecord();

        Triggers.switchOn();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.Name => 'Test Opportunity',
                    Opportunity.Type => OpportunityHelper.OPPORTUNITY_TYPE_EX_BUSINESS,
                    Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                    Opportunity.CloseDate => system.today().addMonths(1),
                    Opportunity.AccountId => acc.Id,
                    Opportunity.Brand_Name__c => 'RingCentral',
                    Opportunity.Tier_Name__c => 'Office',
                    Opportunity.CurrencyIsoCode => 'USD',
                    Opportunity.Forecasted_Users__c => 15,
                    Opportunity.Forecast_Contact_Center_Users__c => 10
                }
            )
            .create()
            .getRecord();

        Quote testSalesQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                        Quote.Name => 'testSalesQuote',
                        Quote.Auto_Renewal__c => true,
                        Quote.isPrimary__c => true,
                        Quote.Account__c => opp.AccountId,
                        Quote.OpportunityId => opp.Id,
                        Quote.Pricebook2Id => Test.getStandardPricebookId(),
                        Quote.RecordTypeId => QuoteHelper.RT_ID_SALES,
                        Quote.CurrencyIsoCode => 'USD'
                    }
            )
            .create()
            .getRecord();

        Product2 officeDLProduct = (Product2) new SObjectBuilder(Product2.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Product2.Name => 'DigitalLine',
                Product2.ExtID__c => Product2Helper.DL_UNL_ELEMENT_ID,
                Product2.IsActive => true
            })
            .create()
            .getRecord();

        PricebookEntry officeDLProductStdPBE = (PricebookEntry) new SObjectBuilder(PricebookEntry.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                PricebookEntry.UnitPrice => 100,
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false,
                PricebookEntry.CurrencyIsoCode => 'USD',
                PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                PricebookEntry.Product2Id => officeDLProduct.Id
            })
            .create()
            .getRecord();

        QuoteLineItem officeQli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                QuoteLineItem.QuoteId => testSalesQuote.Id,
                QuoteLineItem.Quantity => 12,
                QuoteLineItem.UnitPrice => officeDLProductStdPBE.UnitPrice,
                QuoteLineItem.PricebookEntryId => officeDLProductStdPBE.Id,
                QuoteLineItem.Product2Id => officeDLProduct.Id,
                QuoteLineItem.Delta_ARR__c => 10
            })
            .create()
            .getRecord();

        Test.startTest();
        opp.StageName = OpportunityHelper.STAGE_NAME_SOLUTION;
        update opp;
        Test.stopTest();

        opp = (Opportunity) new OpportunitySelector()
            .selectOpportunities()
            .selectFields(new List<String>{
                'Source_For_Contact_Center_Pipeline__c',
                'Source_For_Office_Pipeline__c',
                'Estimated_12M_Office_Pipeline__c',
                'Estimated_12M_Contact_Center_Pipeline__c'
                }
            )
            .executeQuery()
            .get(0);

        Assert.areEqual(
            OpportunityPipelineHelper.SOURCE_USERS,
            opp.Source_For_Contact_Center_Pipeline__c,
            'Source should be in forecasted users when Stage 3-5 and oppty doesnt contain cc quote'
        );
        Assert.areNotEqual(
            OpportunityPipelineHelper.SOURCE_QUOTE,
            opp.Source_For_Office_Pipeline__c,
            'Source should be in quote amounts when Stage 3+ and oppty contain quote'
        );
        Assert.areNotEqual(
            14400,
            opp.Estimated_12M_Office_Pipeline__c,
            'Estimated should be 0 when Stage 3+ and oppty contain quote with qlis'
        );
    }

    @isTest
    static void testPipelineSourceForecastedUsers() {
        Triggers.switchOff();
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => 'testAcc'
                }
            )
            .create()
            .getRecord();

        String csvBody = ''
            + 'Brand,Currency,Service,Price,MinimumUserRange,MaximumUserRange\n'
            + 'RingCentral,USD,Office,14.99,1,1\n'
            + 'RingCentral,USD,Office,10,2,99\n'
            + 'RingCentral,USD,Contact Center,199.99,1,1\n'
            + 'RingCentral,USD,Contact Center,100,2,99\n';

        Folder fd = [SELECT Id FROM Folder WHERE Name='Public Documents' LIMIT 1];
        Document doc = new Document();
        doc.name = 'Pipeline_Forecast_Amounts';
        doc.body = Blob.valueOf(csvBody);
        doc.folderId=fd.Id;
        doc.isPublic=true;
        doc.type='csv';
        insert doc;

        Triggers.switchOn();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.Name => 'Test Opportunity',
                    Opportunity.Type => OpportunityHelper.OPPORTUNITY_TYPE_EX_BUSINESS,
                    Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                    Opportunity.CloseDate => system.today().addMonths(1),
                    Opportunity.AccountId => acc.Id,
                    Opportunity.Brand_Name__c => 'RingCentral',
                    Opportunity.Tier_Name__c => 'Office',
                    Opportunity.CurrencyIsoCode => 'USD',
                    Opportunity.Forecasted_Users__c => 15,
                    Opportunity.Forecast_Contact_Center_Users__c => 10
                }
            )
            .create()
            .getRecord();

        Test.startTest();
        opp.StageName = OpportunityHelper.STAGE_NAME_SOLUTION;
        update opp;
        Test.stopTest();

        opp = [SELECT Source_For_Contact_Center_Pipeline__c, Source_For_Office_Pipeline__c,
                        Estimated_12M_Office_Pipeline__c, Estimated_12M_Contact_Center_Pipeline__c
                FROM Opportunity
                WHERE Id =: opp.Id];

        Assert.areEqual(opp.Source_For_Contact_Center_Pipeline__c, OpportunityPipelineHelper.SOURCE_USERS, 'Source should be in forecasted users when Stage 3+ and office oppty without quotes');
        Assert.areEqual(opp.Source_For_Office_Pipeline__c, OpportunityPipelineHelper.SOURCE_USERS, 'Source should be in forecasted users when Stage 3-5 and office oppty without quotes');
        Assert.areEqual(opp.Estimated_12M_Office_Pipeline__c, 1800, 'Estimated should be calculated by csv when Stage 3-5 and office oppty without quotes');
        Assert.areEqual(opp.Estimated_12M_Contact_Center_Pipeline__c, 12000, 'Estimated should be calculated by csv when Stage 3-5 and office oppty without quotes');
    }

    private static decimal getX12MonthBookingValue(Id oppId) {

        List<Opportunity> oppsList = new OpportunitySelector()
            .selectOpportunities()
            .selectFields(
                new Set<SObjectField>{
                    Opportunity.X12_Month_Booking__c
                }
            )
            .setCondition('Id = :bind0')
            .setQueryBindings(new List<Object>{ oppId })
            .executeQuery();

        Opportunity selectedOpp = oppsList.get(0);


        return selectedOpp.X12_Month_Booking__c;
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testupdateAccountMostRecentOppTouched() {
        User userNotEnterprise = (User) new SObjectBuilder (User.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    User.LastName => 'TestSysAdm',
                    User.Username => 'SysAdm!user@gmail.com',
                    User.Email => 'SysAdm_user@gmail.com',
                    User.Alias => 'Test',
                    User.TimeZoneSidKey => 'America/Los_Angeles',
                    User.ManagerId => UserInfo.getUserId(),
                    User.LocaleSidKey => 'en_US',
                    User.EmailEncodingKey => 'UTF-8',
                    User.ProfileId => [SELECT Id, Name FROM Profile WHERE Name = 'System Administrator'].Id,
                    User.LanguageLocaleKey => 'en_US',
                    User.Hierarchy_Role__c => 'Sales Rep'
                }
            )
            .create()
            .getRecord();

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => 'testAcc'
                }
            )
            .create()
            .getRecord();

        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.FirstName => 'Test1',
                    Contact.LastName => 'Test1',
                    Contact.AccountId => acc.Id,
                    Contact.Email => 'something@mostcommon.fake',
                    Contact.Phone => '1234567890',
                    Contact.Preferred_Language__c => 'en_US'
                }
            )
            .create()
            .getRecord();

        Document doc = (Document) new SObjectBuilder(Document.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Document.Name => 'Product_Forecast_Amounts',
                Document.Body => Blob.valueOf('Brand,Service,Price,Forecasted User Range\nRingCentral,Office,1000,1\nRingCentral,Office,10,2-99'),
                Document.ContentType => 'text/csv',
                Document.IsPublic => true,
                Document.FolderId => userNotEnterprise.Id
            })
            .create()
            .getRecord();

        System.runAs(userNotEnterprise) {
            Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Opportunity.Name => 'Test Opportunity 1234567',
                        Opportunity.Type => OpportunityHelper.OPPORTUNITY_TYPE_EX_BUSINESS,
                        Opportunity.StageName => 'Qualify',
                        Opportunity.CloseDate => system.today().addMonths(1),
                        Opportunity.AccountId => acc.Id,
                        Opportunity.Primary_Opportunity_Contact__c => con.Id,
                        Opportunity.Brand_Name__c => 'RingCentral',
                        Opportunity.Tier_Name__c => 'Office',
                        Opportunity.Forecasted_Users__c => 15,
                        Opportunity.Is_Billing_Opportunity__c => true,
                        Opportunity.Total_MRR__c => 600.00
                    }
                )
                .create()
                .getRecord();

           List<Quote> quotesList = new List<Quote>();

            Quote testPrimarySalesQuote = new Quote(
                isPrimary__c = true,
                Name = 'test primary Sales quote',
                RecordTypeId = QuoteHelper.RT_ID_SALES,
                OpportunityId = Opp.Id,
                Total_MRR_New__c = 42
            );
            quotesList.add(testPrimarySalesQuote);

            Quote testSalesQuote = new Quote(
                isPrimary__c = false,
                Name = 'test second Sales quote',
                RecordTypeId = QuoteHelper.RT_ID_SALES,
                OpportunityId = Opp.Id,
                Total_MRR_New__c = 36
            );
            quotesList.add(testSalesQuote);

            Test.startTest();
            opp.stageName = '7. Closed Won';
            update opp;
            Test.stopTest();
        }
    }

    @isTest
    static void testCalculateQuoteByOpportunityMultiproductFlow() {

        Account testAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, 'Test Account')
            .create()
            .getRecord();

        Opportunity testOpp = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.Name => 'Test Master Opportunity',
                Opportunity.AccountId => testAcc.Id,
                Opportunity.Type => OpportunityHelper.OPPORTUNITY_TYPE_EX_BUSINESS,
                Opportunity.Brand_Name__c => 'RingCentral',
                Opportunity.Tier_Name__c => OpportunityHelper.TIER_OFFICE,
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_SOLUTION,
                Opportunity.CloseDate => System.today(),
                Opportunity.CurrencyIsoCode => 'USD'
            })
            .create()
            .getRecord();

        List<Product2> testProducts = (List<Product2>) new SObjectBuilder(Product2.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Product2.ExtID__c => ValueProviderBuilder.provideUniqueString(),
                    Product2.Charge_Term__c => Product2Helper.CHARGE_TERM_MONTHLY,
                    Product2.Family => ValueProviderBuilder.provideList(
                        new List<String>{
                            null,
                            null,
                            null,
                            null,
                            null,
                            'Test PHONES hardware',
                            null,
                            Product2Helper.FAMILY_TAXES,
                            null,
                            null
                        }
                    ),
                    Product2.Billing_Type__c => ValueProviderBuilder.provideList(
                        new List<String>{
                            null,
                            null,
                            null,
                            null,
                            null,
                            null,
                            null,
                            null,
                            Product2Helper.BILLING_TYPE_USAGE,
                            null
                        }
                    ),
                    Product2.GOA_Group_V2__c => ValueProviderBuilder.provideList(
                        new List<String>{
                            null,
                            null,
                            null,
                            null,
                            null,
                            null,
                            'GOA_Global_Office',
                            null,
                            null,
                            null
                        }
                    )
                }
            )
            .quantity(10)
            .create()
            .getRecords();


        List<PricebookEntry> standardPricebookEntryRecords = (List<PricebookEntry>) new SObjectBuilder(PricebookEntry.sObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                    PricebookEntry.Product2Id => ValueProviderBuilder.provideParents(testProducts),
                    PricebookEntry.UnitPrice => 10,
                    PricebookEntry.IsActive => true,
                    PricebookEntry.UseStandardPrice => false,
                    PricebookEntry.CurrencyIsoCode => 'USD'
                }
            )
            .quantity(10)
            .create()
            .getRecords();

        List<Quote> testQuotes = (List<Quote>) new SObjectBuilder(Quote.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.Name => ValueProviderBuilder.provideList(
                        new List<String>{
                            'Multiproduct Billing Quote',
                            'Singleproduct ProServ Quote'
                        }
                    ),
                    Quote.Account__c => testOpp.AccountId,
                    Quote.OpportunityId => testOpp.Id,
                    Quote.Total_Number_of_Digital_Lines__c => 10,
                    Quote.Pricebook2Id => Test.getStandardPricebookId(),
                    Quote.isPrimary__c => true,
                   	Quote.RecordTypeId => ValueProviderBuilder.provideList(
                        new List<String>{
                            QuoteHelper.RT_ID_BILLING,
                            QuoteHelper.RT_ID_PROSERV
                        }
                    ),
                   	Quote.Total_First_Year_Cost__c => ValueProviderBuilder.provideList(
                        new List<Integer>{
                            0,
                            200
                        }
                    ),
                    Quote.Package_Info__c => ValueProviderBuilder.provideList(
                        new List<String>{
                            NGBSTestDataGenerator.generateMultiProductQuotePackageInfo(),
                            null
                        }
                    )
                }
            )
            .quantity(2)
            .create()
            .getRecords();

        List<QuoteLineItem> testQlis = new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    QuoteLineItem.Display_Name__c => ValueProviderBuilder.provideList(
                        new List<String>{
                            'Office QLI',
                            'CC QLI',
                            'Engage Voice QLI',
                            'Engage Digital QLI',
                            'One-Time QLI',
                            'Hardware QLI',
                            'Global Office QLI',
                            'Tax QLI to skip',
                            'Usage QLI to skip',
                            'ProServ in NGBS QLI'
                        }
                    ),
                    QuoteLineItem.QuoteId => testQuotes[0].Id,
                    QuoteLineItem.Quantity => 10,
                    QuoteLineItem.UnitPrice => 10,
                    QuoteLineItem.Product2Id => ValueProviderBuilder.provideParents(testProducts),
                    QuoteLineItem.PricebookEntryId => ValueProviderBuilder.provideParents(standardPricebookEntryRecords),
                    QuoteLineItem.ChargeTerm__c => ValueProviderBuilder.provideList(
                        new List<String>{
                            Product2Helper.CHARGE_TERM_MONTHLY,
                            Product2Helper.CHARGE_TERM_MONTHLY,
                            Product2Helper.CHARGE_TERM_MONTHLY,
                            Product2Helper.CHARGE_TERM_MONTHLY,
                            Product2Helper.CHARGE_TERM_ONE_TIME,
                            Product2Helper.CHARGE_TERM_MONTHLY,
                            Product2Helper.CHARGE_TERM_MONTHLY,
                            Product2Helper.CHARGE_TERM_MONTHLY,
                            Product2Helper.CHARGE_TERM_MONTHLY,
                            Product2Helper.CHARGE_TERM_ONE_TIME
                        }
                    ),
                    QuoteLineItem.ServiceName__c => ValueProviderBuilder.provideList(
                        new List<String>{
                            'Office',
                            'RingCentral Contact Center',
                            'Engage Voice Standalone',
                            'Engage Digital Standalone',
                            'Office',
                            'Office',
                            'Office',
                            'Office',
                            'Office',
                            'Professional Services'
                        }
                    ),
                    QuoteLineItem.Delta_ARR__c => ValueProviderBuilder.provideList(
                        new List<Decimal>{
                            1200.00,
                            1200.00,
                            1200.00,
                            1200.00,
                            0.00,
                            0.00,
                            1200.00,
                            5.00,
                            5.00,
                            0.00
                        }
                    )
                }
            )
            .quantity(10)
            .create()
            .getRecords();

        Map<Id, List<Quote>> quotesByOppId = OpportunityMethods.fetchOpportunityQuotes(new Set<Id> { testOpp.Id });
        Map<Id, Opportunity> oppsIdsToOpps = new Map<Id, Opportunity> { testOpp.Id => testOpp };
        Map<Id, Boolean> oppIdToIsMaster = new Map<Id, Boolean> { testOpp.Id => true };

        Test.startTest();

        Map<Id, OpportunityMethods.OpportunityEstimates> quoteAmmountsByOppId = OpportunityMethods.calculateQuoteByOpportunity(
            quotesByOppId,
            oppsIdsToOpps,
            oppIdToIsMaster
        );

        Test.stopTest();

        OpportunityMethods.OpportunityEstimates estimates = quoteAmmountsByOppId.get(testOpp.Id);

        Assert.areEqual(
            testQlis[0].Delta_ARR__c,
            estimates.officePipeline,
            'officePipeline value should be equal to sum of Delta_ARR__c of QLIs with ServiceName__c "Office"'
        );
        Assert.areEqual(
            testQlis[1].Delta_ARR__c,
            estimates.contactCenterPipeline,
            'contactCenterPipeline value should be equal to sum of Delta_ARR__c of QLIs with ServiceName__c "RingCentral Contact Center"'
        );
        Assert.areEqual(
            testQlis[2].Delta_ARR__c,
            estimates.engageVoicePipeline,
            'engageVoicePipeline value should be equal to sum of Delta_ARR__c of QLIs with ServiceName__c "Engage Voice Standalone"'
        );
        Assert.areEqual(
            testQlis[3].Delta_ARR__c,
            estimates.engageDigitalPipeline,
            'engageDigitalPipeline value should be equal to of Delta_ARR__c of QLIs with ServiceName__c "Engage Digital Standalone"'
        );
        Assert.areEqual(
            testQlis[6].Delta_ARR__c,
            estimates.globalOfficePipeline,
            'globalOfficePipeline value should be equal to sum of Delta_ARR__c of QLIs with Product2.GOA_Group_V2__c "GOA_Global_Office"'
        );
        Assert.areEqual(
            estimates.contactCenterPipeline + estimates.engageDigitalPipeline + estimates.engageVoicePipeline,
            estimates.customerEngagementPipeline,
            'customerEngagementPipeline value should be a sum of contactCenterPipeline, engageDigitalPipeline and engageVoicePipeline'
        );
        Assert.areEqual(
            testQuotes[1].Total_First_Year_Cost__c + testQlis[9].UnitPrice * testQlis[9].Quantity,
            estimates.proServPipeline,
            'proServPipeline value should be equal to ProServ Quotes Total_First_Year_Cost__c value for legacy ProServ Quotes + sum of TotalPrice values (TotalPrice = UnitPrice * Quantity) for ProServ in NGBS'
        );
        Assert.areEqual(
            100,
            estimates.hardwarePipeline,
            'hardwarePipeline value should be 100 (TotalPrice value, UnitPrice * Quantity)'
        );
        Assert.areEqual(
            100,
            estimates.oneTimePipeline,
            'oneTimePipeline value should be 100 (TotalPrice value, UnitPrice * Quantity)'
        );
    }

    @isTest
    static void testCalculateQuoteByOpportunitySingleproductFlow() {
        Account testAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, 'Test Account')
            .create()
            .getRecord();

        List<Opportunity> testOpps = (List<Opportunity>) new SObjectBuilder(Opportunity.sObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.Name => 'Test Technical Opportunity',
                    Opportunity.AccountId => testAcc.Id,
                    Opportunity.Type => OpportunityHelper.OPPORTUNITY_TYPE_EX_BUSINESS,
                    Opportunity.Brand_Name__c => 'RingCentral',
                    Opportunity.Tier_Name__c => OpportunityHelper.TIER_OFFICE,
                    Opportunity.StageName => OpportunityHelper.STAGE_NAME_SOLUTION,
                    Opportunity.CloseDate => System.today(),
                    Opportunity.CurrencyIsoCode => 'USD',
                    Opportunity.IsMultiProductTechnicalOpportunity__c => ValueProviderBuilder.provideList(
                        new List<Boolean>{
                            false,
                            true
                        }
                    )
                }
            )
            .quantity(2)
            .create()
            .getRecords();

        String packageInfoEngageDigital = NGBSTestDataGenerator.generateQuotePackageInfo(new Map<String, Object>{
            'productId' =>  Product2Helper.PRODUCT_ID_ENGAGE_DIGITAL_STANDALONE
        });
        String packageInfoEngageVoice = NGBSTestDataGenerator.generateQuotePackageInfo(new Map<String, Object>{
            'productId' =>  Product2Helper.PRODUCT_ID_ENGAGE_VOICE_STANDALONE
        });

        List<Quote> testQuotes = (List<Quote>) new SObjectBuilder(Quote.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.Name => ValueProviderBuilder.provideList(
                        new List<String>{
                            'Engage Digital Quote',
                            'Engage Voice Quote',
                            'Contact Center Quote',
                            'Engage Voice Techncial Quote'
                        }
                    ),
                    Quote.Account__c => testOpps[0].AccountId,
                    Quote.OpportunityId => ValueProviderBuilder.provideList(
                        new List<Id>{
                            testOpps[0].Id,
                            testOpps[0].Id,
                            testOpps[0].Id,
                            testOpps[1].Id
                        }
                    ),
                    Quote.Total_Number_of_Digital_Lines__c => 10,
                    Quote.Pricebook2Id => Test.getStandardPricebookId(),
                    Quote.isPrimary__c => true,
                    Quote.RecordTypeId => ValueProviderBuilder.provideList(
                        new List<String>{
                            QuoteHelper.RT_ID_BILLING,
                            QuoteHelper.RT_ID_BILLING,
                            QuoteHelper.RT_ID_CC,
                            QuoteHelper.RT_ID_BILLING
                        }
                    ),
                    Quote.Delta_ARR__c => ValueProviderBuilder.provideList(
                        new List<Decimal>{
                            10.00,
                            15.00,
                            0.00,
                            0.00
                        }
                    ),
                    Quote.Delta_CC_ARR__c => ValueProviderBuilder.provideList(
                        new List<Decimal>{
                            0.00,
                            0.00,
                            20.00,
                            0.00
                        }
                    ),
                    Quote.Package_Info__c => ValueProviderBuilder.provideList(
                        new List<String>{
                            packageInfoEngageDigital,
                            packageInfoEngageVoice,
                            null,
                            packageInfoEngageVoice
                        }
                    ),
                    Quote.Total_One_Time__c => ValueProviderBuilder.provideList(
                        new List<Decimal>{
                            0.00,
                            0.00,
                            0.00,
                            25.00
                        }
                    )
                }
            )
            .quantity(4)
            .create()
            .getRecords();

        Set<Id> oppsIds = new Set<Id>(new Map<Id, Opportunity>(testOpps).keySet());

        Map<Id, List<Quote>> quotesByOppId = OpportunityMethods.fetchOpportunityQuotes(oppsIds);
        Map<Id, Opportunity> oppsIdsToOpps = new Map<Id, Opportunity>(testOpps);
        Map<Id, Boolean> oppIdToIsMaster = new Map<Id, Boolean> { testOpps[0].Id => false, testOpps[0].Id => false };

        Test.startTest();

        Map<Id, OpportunityMethods.OpportunityEstimates> quoteAmmountsByOppId = OpportunityMethods.calculateQuoteByOpportunity(
            quotesByOppId,
            oppsIdsToOpps,
            oppIdToIsMaster
        );

        OpportunityMethods.OpportunityEstimates estimatesNotTechnicalOpp = quoteAmmountsByOppId.get(testOpps[0].Id);
        OpportunityMethods.OpportunityEstimates estimatesTechnicalOpp = quoteAmmountsByOppId.get(testOpps[1].Id);

        quotesByOppId = new Map<Id, List<Quote>>();

        Map<Id, OpportunityMethods.OpportunityEstimates> quoteAmmountsByOppIdNoQuotes = OpportunityMethods.calculateQuoteByOpportunity(
            quotesByOppId,
            oppsIdsToOpps,
            oppIdToIsMaster
        );

        OpportunityMethods.OpportunityEstimates estimatesQuoteWithoutQuotes = quoteAmmountsByOppIdNoQuotes.get(testOpps[1].Id);

        Test.stopTest();

        // Non-Technical Opportunity estimates asserts
        Assert.areEqual(
            testQuotes[0].Delta_ARR__c,
            estimatesNotTechnicalOpp.engageDigitalPipeline,
            'engageDigitalPipeline value should be equal to Delta_ARR__c of Engage Digital Standalone Quote'
        );
        Assert.areEqual(
            testQuotes[1].Delta_ARR__c,
            estimatesNotTechnicalOpp.engageVoicePipeline,
            'engageVoicePipeline value should be equal to Delta_ARR__c of Engage Voice Standalone Quote'
        );
        Assert.areEqual(
            testQuotes[2].Delta_CC_ARR__c,
            estimatesNotTechnicalOpp.contactCenterPipeline,
            'contactCenterPipeline value should be equal to Delta_CC_ARR__c of Contact Center Quote'
        );

        // Technical Opportunity estimates asserts
        Assert.areEqual(
            testQuotes[3].Total_One_Time__c,
            estimatesTechnicalOpp.oneTimePipeline,
            'oneTimePipeline value should be equal to Total_One_Time__c of Quote on Technical Opportunity'
        );
        Assert.areEqual(
            0,
            estimatesTechnicalOpp.officePipeline,
            'officePipeline value should be 0 on Technical Opportunity'
        );
        Assert.areEqual(
            0,
            estimatesTechnicalOpp.customerEngagementPipeline,
            'customerEngagementPipeline value should be 0 on Technical Opportunity'
        );
        Assert.areEqual(
            0,
            estimatesTechnicalOpp.contactCenterPipeline,
            'contactCenterPipeline value should be 0 on Technical Opportunity'
        );
        Assert.areEqual(
            0,
            estimatesTechnicalOpp.engageDigitalPipeline,
            'engageDigitalPipeline value should be 0 on Technical Opportunity'
        );
        Assert.areEqual(
            0,
            estimatesTechnicalOpp.engageVoicePipeline,
            'engageVoicePipeline value should be 0 on Technical Opportunity'
        );
        Assert.areEqual(
            0,
            estimatesTechnicalOpp.globalOfficePipeline,
            'globalOfficePipeline value should be 0 on Technical Opportunity'
        );
        Assert.areEqual(
            0,
            estimatesTechnicalOpp.ringCentralVideoPipeline,
            'ringCentralVideoPipeline value should be 0 on Technical Opportunity'
        );
        Assert.areEqual(
            0,
            estimatesTechnicalOpp.proServPipeline,
            'proServPipeline value should be 0 on Technical Opportunity'
        );
        Assert.areEqual(
            0,
            estimatesTechnicalOpp.hardwarePipeline,
            'hardwarePipeline value should be 0 on Technical Opportunity'
        );

        // Null Quotes estimates asserts
        Assert.areEqual(
            0,
            estimatesQuoteWithoutQuotes.oneTimePipeline,
            'oneTimePipeline value should be 0 if there\' no Quotes for Opportunities'
        );
        Assert.areEqual(
            0,
            estimatesQuoteWithoutQuotes.officePipeline,
            'officePipeline value should be 0 if there\' no Quotes for Opportunities'
        );
        Assert.areEqual(
            0,
            estimatesQuoteWithoutQuotes.customerEngagementPipeline,
            'customerEngagementPipeline value should be 0 if there\' no Quotes for Opportunities'
        );
        Assert.areEqual(
            0,
            estimatesQuoteWithoutQuotes.contactCenterPipeline,
            'contactCenterPipeline value should be 0 if there\' no Quotes for Opportunities'
        );
        Assert.areEqual(
            0,
            estimatesQuoteWithoutQuotes.engageDigitalPipeline,
            'engageDigitalPipeline value should be 0 if there\' no Quotes for Opportunities'
        );
        Assert.areEqual(
            0,
            estimatesQuoteWithoutQuotes.engageVoicePipeline,
            'engageVoicePipeline value should be 0 if there\' no Quotes for Opportunities'
        );
        Assert.areEqual(
            0,
            estimatesQuoteWithoutQuotes.globalOfficePipeline,
            'globalOfficePipeline value should be 0 if there\' no Quotes for Opportunities'
        );
        Assert.areEqual(
            0,
            estimatesQuoteWithoutQuotes.ringCentralVideoPipeline,
            'ringCentralVideoPipeline value should be 0 if there\' no Quotes for Opportunities'
        );
        Assert.areEqual(
            0,
            estimatesQuoteWithoutQuotes.proServPipeline,
            'proServPipeline value should be 0 if there\' no Quotes for Opportunities'
        );
        Assert.areEqual(
            0,
            estimatesQuoteWithoutQuotes.hardwarePipeline,
            'hardwarePipeline value should be 0 if there\' no Quotes for Opportunities'
        );
    }

    @isTest
    static void testPopulateNumberOfSeatsOnOppty() {
        Triggers.switchOff();
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => 'testAcc',
                    Account.Offer_Type__c => 'trial',
                    Account.RC_User_ID__c => '123',
                    Account.Billing_ID__c => '123'
                }
            )
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.Name => 'Test Opportunity',
                    Opportunity.Type => OpportunityHelper.OPPORTUNITY_TYPE_EX_BUSINESS,
                    Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                    Opportunity.CloseDate => system.today().addMonths(1),
                    Opportunity.AccountId => acc.Id,
                    Opportunity.Brand_Name__c => 'RingCentral',
                    Opportunity.Tier_Name__c => 'Office',
                    Opportunity.CurrencyIsoCode => 'USD',
                    Opportunity.Forecasted_Users__c => 15,
                    Opportunity.Forecast_Contact_Center_Users__c => 10
                }
            )
            .create()
            .getRecord();

        Product2 dlUnlimited = (Product2) new SObjectBuilder(Product2.SObjectType)
        .setFields(new Map<SObjectField, Object> {
            Product2.Name => 'DigitalLine Unlimited',
            Product2.ExtID__c => Product2Helper.DL_UNL_ELEMENT_ID,
            Product2.Charge_Term__c => Product2Helper.CHARGE_TERM_MONTHLY,
            Product2.Family => Product2Helper.FAMILY_SERVICE,
            Product2.IsActive => true
        })
        .create()
        .getRecord();

        PricebookEntry pbe = (PricebookEntry) new SObjectBuilder(PricebookEntry.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                PricebookEntry.Product2Id => dlUnlimited.Id,
                PricebookEntry.UnitPrice => 100,
                PricebookEntry.IsActive => true
            })
            .create()
            .getRecord();

        Quote pocQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                        Quote.Name => 'testSalesQuote',
                        Quote.Auto_Renewal__c => true,
                        Quote.isPrimary__c => true,
                        Quote.Account__c => opp.AccountId,
                        Quote.OpportunityId => opp.Id,
                        Quote.Pricebook2Id => Test.getStandardPricebookId(),
                        Quote.RecordTypeId => QuoteHelper.RT_ID_POC,
                        Quote.CurrencyIsoCode => 'USD'
                    }
            )
            .create()
            .getRecord();

        Entitlement__c ent = (Entitlement__c) new SObjectBuilder(Entitlement__c.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Entitlement__c.Account__c => acc.Id,
                Entitlement__c.Quote__c => pocQuote.Id,
                Entitlement__c.Product__c => dlUnlimited.Id,
                Entitlement__c.Quantity__c => 10,
                Entitlement__c.Price__c => 50,
                Entitlement__c.ChargeTerm__c => Product2Helper.CHARGE_TERM_MONTHLY,
                Entitlement__c.Discount__c => 10,
                Entitlement__c.Discount_Type__c => QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY,
                Entitlement__c.PackageCatalogId__c => '7',
                Entitlement__c.PackageVersion__c => '1',
                Entitlement__c.Active__c => true
            })
            .create()
            .getRecord();

        QuoteLineItem pocQli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                QuoteLineItem.QuoteId => pocQuote.Id,
                QuoteLineItem.Product2Id => dlUnlimited.Id,
                QuoteLineItem.Quantity => 5,
                QuoteLineItem.PricebookEntryId => pbe.Id,
                QuoteLineItem.UnitPrice => 10.00,
                QuoteLineItem.Entitlement__c => ent.Id
            })
            .create()
            .getRecord();
        Triggers.switchOn();

        Test.startTest();
        update opp;

        pocQli = (QuoteLineItem) new QuoteLineItemSelector()
            .selectQuoteLineItemsForSyncWithNGBS()
            .executeQuery()
            .get(0);
        opp = (Opportunity) new OpportunitySelector()
            .selectOpportunityForSyncWithNGBSByName('Test Opportunity')
            .executeQuery()
            .get(0);
        Test.stopTest();
        Assert.areNotEqual(pocQli.NewQuantity__c, opp.NumberOfOfficeDLs__c, 'The values are not equal');
    }

    @isTest
    static void testCheckForActiveQuote() {
        // Create test data
        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => 'Test Account',
                Account.RC_User_ID__c => '12345'
            })
            .create()
            .getRecord();
        
        Opportunity testOpportunity = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.Name => 'Test Opportunity',
                Opportunity.AccountId => testAccount.Id,
                Opportunity.StageName => 'Prospecting'
            })
            .create()
            .getRecord();
        
        Quote testQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Quote.Name => 'Test Quote',
                Quote.OpportunityId => testOpportunity.Id,
                Quote.Status => QuoteTriggerHelper.STATUS_ACTIVE,
                Quote.End_Date__c => Date.today().addDays(30),
                Quote.Start_Date__c => Date.today()
            })
            .create()
            .getRecord();
        
        Test.startTest();
            String result = OpportunityMethods.checkForActiveQuote(testOpportunity.Id);
        Test.stopTest();
        
        Assert.areEqual('Active Sales Agreement already exists for the account.', result, 'Should return message about active sales agreement');
    }
    
    @isTest
    static void testOpportunityQuoteUsersClass() {
        // Create an instance of OpportunityQuoteUsers
        OpportunityMethods.OpportunityQuoteUsers quoteUsers = new OpportunityMethods.OpportunityQuoteUsers();
        
        // Test with opportunity
        Opportunity testOpportunity = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.Name => 'Test Opportunity',
                Opportunity.StageName => 'Prospecting',
                Opportunity.CloseDate => System.today()
            })
            .build()
            .getRecord();
        
        Test.startTest();
            // Add values to the quote users
            quoteUsers.add(OpportunityHelper.TIER_OFFICE, 10);
            quoteUsers.add(OpportunityHelper.TIER_CONTACT_CENTER, 5);
            quoteUsers.add(OpportunityHelper.TIER_ENGAGE_DIGITAL_STANDALONE, 3);
            quoteUsers.add(OpportunityHelper.TIER_ENGAGE_VOICE_STANDALONE, 2);
            quoteUsers.add(OpportunityPipelineHelper.GLOBAL_OFFICE, 4);
            quoteUsers.add(OpportunityHelper.TIER_RC_MEETINGS, 1);
            
            // Test get method
            Decimal officeUsers = quoteUsers.get(OpportunityHelper.TIER_OFFICE);
            Decimal contactCenterUsers = quoteUsers.get(OpportunityHelper.TIER_CONTACT_CENTER);
            Decimal engageDigitalUsers = quoteUsers.get(OpportunityHelper.TIER_ENGAGE_DIGITAL_STANDALONE);
            Decimal engageVoiceUsers = quoteUsers.get(OpportunityHelper.TIER_ENGAGE_VOICE_STANDALONE);
            Decimal globalOfficeUsers = quoteUsers.get(OpportunityPipelineHelper.GLOBAL_OFFICE);
            Decimal rcMeetingsUsers = quoteUsers.get(OpportunityHelper.TIER_RC_MEETINGS);
            Decimal unknownServiceUsers = quoteUsers.get('Unknown Service');
            
            // Test populateNumberOfSeatsOnOppty method
            quoteUsers.populateNumberOfSeatsOnOppty(testOpportunity);
        Test.stopTest();
        
        // Verify get method results
        Assert.areEqual(10, officeUsers, 'Office users should be 10');
        Assert.areEqual(5, contactCenterUsers, 'Contact Center users should be 5');
        Assert.areEqual(3, engageDigitalUsers, 'Engage Digital users should be 3');
        Assert.areEqual(2, engageVoiceUsers, 'Engage Voice users should be 2');
        Assert.areEqual(4, globalOfficeUsers, 'Global Office users should be 4');
        Assert.areEqual(1, rcMeetingsUsers, 'RC Meetings users should be 1');
        Assert.areEqual(0, unknownServiceUsers, 'Unknown service users should be 0');
        
        // Verify populateNumberOfSeatsOnOppty results
        Assert.areEqual(15, testOpportunity.NumberOfOfficeDLs__c, 'Office DLs should be 15 (Office + Global Office + RC Meetings)');
        Assert.areEqual(5, testOpportunity.NumberOfCCSeats__c, 'CC Seats should be 5');
        Assert.areEqual(2, testOpportunity.NumberOfEngageVoiceDLs__c, 'Engage Voice DLs should be 2');
        Assert.areEqual(3, testOpportunity.NumberOfEngageDigitalDLs__c, 'Engage Digital DLs should be 3');
    }
    
    @isTest
    static void testUpdateParentAccount() {
        // Create test data
        User testOwner = (User) new SObjectBuilder(User.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                User.LastName => 'TestOwner',
                User.Username => 'testowner@example.com',
                User.Email => 'testowner@example.com',
                User.Alias => 'town',
                User.TimeZoneSidKey => 'America/Los_Angeles',
                User.LocaleSidKey => 'en_US',
                User.EmailEncodingKey => 'UTF-8',
                User.ProfileId => [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id,
                User.LanguageLocaleKey => 'en_US',
                User.Phone => '5555555555',
                User.FirstName => 'Test'
            })
            .create()
            .getRecord();
        
        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => 'Test Account'
            })
            .create()
            .getRecord();
        
        // Test with new opportunity
        Test.startTest();
            Opportunity testOpportunity = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
                .setFields(new Map<SObjectField, Object>{
                    Opportunity.Name => 'Test Opportunity',
                    Opportunity.AccountId => testAccount.Id,
                    Opportunity.StageName => '1. Qualify',
                    Opportunity.CloseDate => System.today(),
                    Opportunity.OwnerId => testOwner.Id,
                    Opportunity.Sales_Segment__c => 'SMB',
                    Opportunity.Forecasted_Users__c => 25,
                    Opportunity.Tier_Name__c => 'Office'
                })
                .create()
                .getRecord();
            
            // Update to Closed Won
            testOpportunity.StageName = '8. Closed Won';
            update testOpportunity;
        Test.stopTest();
        
        // Verify account was updated
        Account updatedAccount = [
            SELECT Most_Recent_Opportunity_Owner__c, Most_Recent_Opportunity_Owner_Email__c,
                   Most_Recent_Opportunity_Owner_FirstName__c, Most_Recent_Opportunity_Owner_LastName__c,
                   Most_Recent_Opportunity_Owner_Phone__c, Sales_Segment__c,
                   Most_Recent_Opportunity_Forecasted_Users__c, Most_Recent_Opportunity_Tier_Name__c,
                   Most_Recent_Opportunity_Stage__c
            FROM Account
            WHERE Id = :testAccount.Id
        ];
        
        Assert.areEqual(testOwner.Id, updatedAccount.Most_Recent_Opportunity_Owner__c, 'Most recent opportunity owner ID should match');
        Assert.areEqual(testOwner.Email, updatedAccount.Most_Recent_Opportunity_Owner_Email__c, 'Most recent opportunity owner email should match');
        Assert.areEqual(testOwner.FirstName, updatedAccount.Most_Recent_Opportunity_Owner_FirstName__c, 'Most recent opportunity owner first name should match');
        Assert.areEqual(testOwner.LastName, updatedAccount.Most_Recent_Opportunity_Owner_LastName__c, 'Most recent opportunity owner last name should match');
        Assert.areEqual(testOwner.Phone, updatedAccount.Most_Recent_Opportunity_Owner_Phone__c, 'Most recent opportunity owner phone should match');
        Assert.areEqual('SMB', updatedAccount.Sales_Segment__c, 'Sales segment should match opportunity');
        Assert.areEqual(25, updatedAccount.Most_Recent_Opportunity_Forecasted_Users__c, 'Forecasted users should match opportunity');
        Assert.areEqual('Office', updatedAccount.Most_Recent_Opportunity_Tier_Name__c, 'Tier name should match opportunity');
    }
    
    @isTest
    static void testUpdateAccountMostRecentContact() {
        // Create test data
        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => 'Test Account'
            })
            .create()
            .getRecord();
        
        Contact testContact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Contact.FirstName => 'Test',
                Contact.LastName => 'Contact',
                Contact.Email => 'test.contact@example.com',
                Contact.AccountId => testAccount.Id
            })
            .create()
            .getRecord();
        
        Opportunity testOpportunity = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.Name => 'Test Opportunity',
                Opportunity.AccountId => testAccount.Id,
                Opportunity.StageName => '1. Qualify',
                Opportunity.CloseDate => System.today()
            })
            .create()
            .getRecord();
        
        // Create contact role
        OpportunityContactRole testRole = new OpportunityContactRole(
            OpportunityId = testOpportunity.Id,
            ContactId = testContact.Id,
            IsPrimary = true
        );
        insert testRole;
        
        Test.startTest();
            // Call the method
            Map<Id, Opportunity> opportunityMap = new Map<Id, Opportunity>{testOpportunity.Id => testOpportunity};
            OpportunityMethods methods = new OpportunityMethods();
            methods.updateAccountMostRecentContact(opportunityMap, null);
        Test.stopTest();
        
        // Verify account was updated
        Account updatedAccount = [
            SELECT Most_Recent_Opportunity_Contact__c
            FROM Account
            WHERE Id = :testAccount.Id
        ];
        
        Assert.areEqual(testContact.Id, updatedAccount.Most_Recent_Opportunity_Contact__c, 'Most recent opportunity contact should match');
    }
}