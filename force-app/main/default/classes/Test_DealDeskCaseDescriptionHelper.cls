@isTest
private class Test_DealDeskCaseDescriptionHelper {

    @testSetup
    private static void prepareTestData() {
        Triggers.switchOff();
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SobjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.Name => 'Test Opportunity',
                Opportunity.AccountId => acc.Id,
                Opportunity.CloseDate => System.today()
            })
            .create()
            .getRecord();

        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Quote.Account__c => acc.id,
                Quote.OpportunityId => opp.Id,
                Quote.Pricebook2Id => Test.getStandardPricebookId(),
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.isPrimary__c => true
            })
            .create()
            .getRecord();

        Product2 testProduct = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Product2.Name => 'DigitalLine Unlimited',
                Product2.ExtID__c => 'L1',
                Product2.ShippingType__c => Product2Helper.SHIPPING_TYPE_MANUAL
            })
            .create()
            .getRecord();

        PricebookEntry pbe = (PricebookEntry) new SObjectBuilder(PricebookEntry.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                PricebookEntry.Product2Id => testProduct.Id,
                PricebookEntry.UnitPrice => 10,
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false
            })
            .create()
            .getRecord();

        QuoteLineItem qli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                QuoteLineItem.QuoteId => qt.Id,
                QuoteLineItem.Product2Id => testProduct.Id,
                QuoteLineItem.Quantity => 1,
                QuoteLineItem.PricebookEntryId => pbe.Id,
                QuoteLineItem.UnitPrice => pbe.UnitPrice,
                QuoteLineItem.EffectivePriceNew__c => pbe.UnitPrice
            })
            .create()
            .getRecord();

        CustomAddress__c address = (CustomAddress__c) new SObjectBuilder(CustomAddress__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                CustomAddress__c.AddressLine__c => 'Test address line',
                CustomAddress__c.Street__c => 'Test street',
                CustomAddress__c.City__c => 'Test city',
                CustomAddress__c.PostalCode__c => 'Test postal code',
                CustomAddress__c.State__c => 'Test state',
                CustomAddress__c.Country__c => 'Test country'
            })
            .create()
            .getRecord();

        CustomAddressAssignments__c addressAssignment = (CustomAddressAssignments__c) new SObjectBuilder(CustomAddressAssignments__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                CustomAddressAssignments__c.CustomAddress__c => address.Id,
                CustomAddressAssignments__c.AttentionTo__c => 'test',
                CustomAddressAssignments__c.Quantity__c => 1,
                CustomAddressAssignments__c.QuoteLineItem__c => qli.Id,
                CustomAddressAssignments__c.Type__c => QuoteHelper.SHIPPING_OPTION_GROUND
            })
            .create()
            .getRecord();
        Triggers.switchOn();
    }

    @isTest
    private static void testgetQuoteLineItemsByLabels() {
        Opportunity opp = (Opportunity) new OpportunitySelector()
            .selectOpportunities()
            .executeQuery()
            .get(0);

        Quote qt = (Quote) new QuoteSelector()
            .selectQuotes()
            .executeQuery()
            .get(0);

        Product2 testProduct = (Product2) new Product2Selector()
            .selectProducts()
            .executeQuery()
            .get(0);

        List<Product2> testProducts = (List<Product2>) new SObjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Product2.Name => ValueProviderBuilder.provideUniqueString('DigitalLine Unlimited'),
                Product2.ExtID__c => ValueProviderBuilder.provideUniqueString('L1'),
                Product2.ShippingType__c => ValueProviderBuilder.provideList(new List<String>{
                    null,
                    null,
                    null,
                    null,
                    null
                }),
                Product2.InitialOrderType__c => ValueProviderBuilder.provideList(new List<String>{
                    null,
                    Product2Helper.ORDER_TYPE_AUTO,
                    Product2Helper.ORDER_TYPE_MANUAL,
                    null,
                    null
                }),
                Product2.UpsellType__c => ValueProviderBuilder.provideList(new List<String>{
                    null,
                    null,
                    null,
                    Product2Helper.ORDER_TYPE_AUTO,
                    Product2Helper.ORDER_TYPE_MANUAL
                })
            })
            .quantity(5)
            .create()
            .getRecords();

        PricebookEntry pbe = (PricebookEntry) new PricebookEntrySelector()
            .getAllPBEs()
            .executeQuery()
            .get(0);

        new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                QuoteLineItem.QuoteId => qt.Id,
                QuoteLineItem.Product2Id => ValueProviderBuilder.provideParents(testProducts),
                QuoteLineItem.Quantity => 1,
                QuoteLineItem.PricebookEntryId => pbe.Id,
                QuoteLineItem.UnitPrice => pbe.UnitPrice,
                QuoteLineItem.PackageInfo__c => ValueProviderBuilder.provideList(new List<String>{
                    '{}',
                    '{}',
                    '{}',
                    '{}',
                    '{}'
                })
            })
            .quantity(5)
            .create();

        qt = (Quote) new QuoteSelector()
            .selectQuoteForSignUp(opp.Id)
            .executeQuery()
            .get(0);

        Test.startTest();
        DealDeskCaseDescriptionHelper.QLIsByLabelsData qlisByLabels = DealDeskCaseDescriptionHelper.getQuoteLineItemsByLabels(qt.BusinessIdentity__c, qt.QuoteLineItems);
        Test.stopTest();

        System.assert(
            qlisByLabels != null,
            'DealDeskCaseDescriptionHelper.getQuoteLineItemsByLabels should return object containing quotelineitems with different labels'
        );
        System.assertEquals(1, qlisByLabels.qlisWithShippingLabel.size(),
            'qlisWithShippingLabel should contain quotelineitems with "manual" shipping label');
        System.assertEquals(2, qlisByLabels.qlisWithUpsellTypeLabel.size(),
            'qlisWithUpsellTypeLabel should contain quotelineitems with "manual"/"autoWithCase" shipping label');
        System.assertEquals(2, qlisByLabels.qlisWithInitialOrderTypeLabel.size(),
            'qlisWithInitialOrderTypeLabel should contain quotelineitems with "manual"/"autoWithCase" shipping label');
    }

    @isTest
    private static void testGetLicenseIdOrCategoryCodeToTemplate() {
        DealDeskCaseDescriptionHelper.templatesMetadata = new SObjectBuilder(NGBSProcessOrderCaseTemplate__mdt.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                NGBSProcessOrderCaseTemplate__mdt.Id => ValueProviderBuilder.provideDummyId(NGBSProcessOrderCaseTemplate__mdt.SObjectType),
                NGBSProcessOrderCaseTemplate__mdt.IsActive__c => ValueProviderBuilder.provideList(
                    new List<Boolean>{
                        true, true, true, true, true
                    }
                ),
                NGBSProcessOrderCaseTemplate__mdt.Type__c => DealDeskCaseDescriptionHelper.SHIPPING_CASE_TEMPLATE_TYPE,
                NGBSProcessOrderCaseTemplate__mdt.ShippingReq__c => Product2Helper.SHIPPING_TYPE_MANUAL,
                NGBSProcessOrderCaseTemplate__mdt.LicenceIdOrCategoryCode__c => ValueProviderBuilder.provideList(
                    new List<String>{
                        'L1', 'L2', 'L3;L4;L5', 'L2; L6', null
                    }
                ),
                NGBSProcessOrderCaseTemplate__mdt.Description__c => ValueProviderBuilder.provideUniqueString('Test template')
            })
            .quantity(5)
            .build()
            .getRecords();
        DealDeskCaseDescriptionHelper.initializeTemplatesMap();

        Test.startTest();
        Map<String, DealDeskCaseDescriptionHelper.CaseDescriptionMapping> mappingsForCaseTypes = DealDeskCaseDescriptionHelper.getLicenseIdOrCategoryCodeToTemplate();
        Test.stopTest();

        DealDeskCaseDescriptionHelper.CaseDescriptionMapping shippingMapping = mappingsForCaseTypes.get(
            DealDeskCaseDescriptionHelper.SHIPPING_CASE_TEMPLATE_TYPE
        );

        System.assertEquals(shippingMapping.defaultTemplates.get(0).description, 'Test template4',
            'If LicenceIdOrCategoryCode__c are null and any label value specified, then it is default template');
        String descriptionForL1;
        for (DealDeskCaseDescriptionHelper.Template template : shippingMapping.licenseIdOrCategoryCodeTemplates) {
            if (template.licenseIdOrCategoryCode == 'L1') {
                descriptionForL1 = template.description;
            }
        }
        System.assertEquals('Test template0', descriptionForL1,
            'if licenseId or category code specified in licenseCatalogIdToTemplate field then it is a custom template');
    }

    @isTest
    private static void testGetTemplateIdToQLIMap() {
        DealDeskCaseDescriptionHelper.templatesMetadata = new SObjectBuilder(NGBSProcessOrderCaseTemplate__mdt.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                NGBSProcessOrderCaseTemplate__mdt.Id => ValueProviderBuilder.provideDummyId(NGBSProcessOrderCaseTemplate__mdt.SObjectType),
                NGBSProcessOrderCaseTemplate__mdt.IsActive__c => true,
                NGBSProcessOrderCaseTemplate__mdt.Type__c => DealDeskCaseDescriptionHelper.SHIPPING_CASE_TEMPLATE_TYPE,
                NGBSProcessOrderCaseTemplate__mdt.ShippingReq__c => Product2Helper.SHIPPING_TYPE_MANUAL,
                NGBSProcessOrderCaseTemplate__mdt.LicenceIdOrCategoryCode__c => ValueProviderBuilder.provideList(
                    new List<String>{
                        'L01;C1', 'L2;C2', 'L3;L4;L5', /*null*/'C3;C4;C5', 'L6;L8;C6;C8', 'L6;C6', null
                    }
                ),
                NGBSProcessOrderCaseTemplate__mdt.Description__c => ValueProviderBuilder.provideList(
                    new List<String>{
                        'Template for L01', 'Template for C2', 'Template for L3,L4,L5', 'Template for C3,C4,C5',
                        'Template for L2,L6', 'Template with error', 'Default template'
                    }
                )
            })
            .quantity(7)
            .build()
            .getRecords();
        DealDeskCaseDescriptionHelper.initializeTemplatesMap();

        Map<String, NGBSProcessOrderCaseTemplate__mdt> templateToSettingMap = new Map<String, NGBSProcessOrderCaseTemplate__mdt>();
        for (NGBSProcessOrderCaseTemplate__mdt mdt : DealDeskCaseDescriptionHelper.templatesMetadata) {
            templateToSettingMap.put(mdt.Description__c, mdt);
        }

        Triggers.switchOff();

        Opportunity opp = (Opportunity) new SobjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.CloseDate => System.today()
            })
            .create()
            .getRecord();

        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Quote.OpportunityId => opp.Id,
                Quote.Pricebook2Id => Test.getStandardPricebookId(),
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING
            })
            .create()
            .getRecord();

        List<Product2> testProducts = (List<Product2>) new SObjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Product2.Name => ValueProviderBuilder.provideUniqueString('Product Name'),
                Product2.ExtID__c => ValueProviderBuilder.provideList(
                    new List<String>{
                        'L01', 'L15', 'L3', 'L4', 'L5', 'L7','L9','L10','L11', 'L6', 'L12'
                    }
                ),
                Product2.ShippingType__c => Product2Helper.SHIPPING_TYPE_MANUAL
            })
            .quantity(11)
            .create()
            .getRecords();

        List<PricebookEntry> pbes = (List<PricebookEntry>) new SObjectBuilder(PricebookEntry.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                PricebookEntry.Product2Id => ValueProviderBuilder.provideList(
                    new List<Id>{
                        testProducts[0].Id, testProducts[1].Id, testProducts[2].Id,
                        testProducts[3].Id, testProducts[4].Id, testProducts[5].Id,
                        testProducts[6].Id, testProducts[7].Id, testProducts[8].Id,
                        testProducts[9].Id, testProducts[10].Id
                    }
                ),
                PricebookEntry.UnitPrice => 10,
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false
            })
            .quantity(11)
            .create()
            .getRecords();

        List<QuoteLineItem> qlis = (List<QuoteLineItem>) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                QuoteLineItem.QuoteId => qt.Id,
                QuoteLineItem.Product2Id => ValueProviderBuilder.provideList(
                    new List<Id>{
                        testProducts[0].Id, testProducts[1].Id, testProducts[2].Id,
                        testProducts[3].Id, testProducts[4].Id, testProducts[5].Id,
                        testProducts[6].Id, testProducts[7].Id, testProducts[8].Id
                    }
                ),
                QuoteLineItem.Quantity => 1,
                QuoteLineItem.PricebookEntryId => ValueProviderBuilder.provideList(
                    new List<Id>{
                        pbes[0].Id, pbes[1].Id, pbes[2].Id, pbes[3].Id, pbes[4].Id, pbes[5].Id, pbes[6].Id, pbes[7].Id, pbes[8].Id
                    }
                ),
                QuoteLineItem.UnitPrice => pbes[0].UnitPrice,
                QuoteLineItem.PackageInfo__c => ValueProviderBuilder.provideList(
                    new List<String>{
                        '{"categoryCode": "C1"}',
                        '{"categoryCode": "C2"}',
                        '{"categoryCode": "C15"}',
                        '{"categoryCode": "C16"}',
                        '{"categoryCode": "C17"}',
                        '{"categoryCode": "C18"}',
                        '{"categoryCode": "C3"}',
                        '{"categoryCode": "C4"}',
                        '{"categoryCode": "C5"}'
                    }
                )
            })
            .quantity(9)
            .create()
            .getRecords();

        qlis = (List<QuoteLineItem>) new QuoteLineItemSelector()
            .selectQuoteLineItemsByQuoteIds(qt.Id)
            .selectFields(new List<String>{
                'Product_Lic_Id__c',
                'Product2.InitialOrderType__c',
                'Product2.UpsellType__c',
                'Product2.ShippingType__c'
            })
            .executeQuery();

        Map<String, DealDeskCaseDescriptionHelper.CaseDescriptionMapping> mappingsForCaseTypes = DealDeskCaseDescriptionHelper.getLicenseIdOrCategoryCodeToTemplate();
        DealDeskCaseDescriptionHelper.CaseDescriptionMapping shippingMapping = mappingsForCaseTypes.get(
            DealDeskCaseDescriptionHelper.SHIPPING_CASE_TEMPLATE_TYPE
        );

        Map<Id, List<QuoteLineItem>> templateIdToQLIsMap = DealDeskCaseDescriptionHelper.getTemplateIdToQLIsMap(shippingMapping, qlis);
        System.assertEquals(templateIdToQLIsMap.get(templateToSettingMap.get('Template for L01').Id)[0], qlis[0],
            'getTemplateToQLIsMap should map template and qli by licenseId');
        System.assertEquals(templateIdToQLIsMap.get(templateToSettingMap.get('Template for C2').Id)[0], qlis[1],
            'getTemplateToQLIsMap should map template and qli by categoryCode if there is no setting with corresponding licenseId');
        System.assert((templateIdToQLIsMap.get(templateToSettingMap.get('Template for L3,L4,L5').Id)[0] == qlis[2] &&
            templateIdToQLIsMap.get(templateToSettingMap.get('Template for L3,L4,L5').Id)[1] == qlis[3] &&
            templateIdToQLIsMap.get(templateToSettingMap.get('Template for L3,L4,L5').Id)[2] == qlis[4]),
            'getTemplateToQLIsMap should map template and qlis by licenseId for setting with enumerated license ids');
        System.assert((templateIdToQLIsMap.get(templateToSettingMap.get('Template for C3,C4,C5').Id)[0] == qlis[6] &&
            templateIdToQLIsMap.get(templateToSettingMap.get('Template for C3,C4,C5').Id)[1] == qlis[7] &&
            templateIdToQLIsMap.get(templateToSettingMap.get('Template for C3,C4,C5').Id)[2] == qlis[8]),
            'getTemplateToQLIsMap should map template and qlis by categoryCode for setting with enumerated license ids');
        System.assertEquals(templateIdToQLIsMap.get(templateToSettingMap.get('Default template').Id)[0], qlis[5],
            'getTemplateToQLIsMap should map deafault template and qli because there is no setting for such licenseId or categoryCode');

        Triggers.switchOn();
    }

    @isTest
    private static void testGetAddressToCaasMap() {
        Quote qt = (Quote) new QuoteSelector()
            .selectQuotes()
            .executeQuery()
            .get(0);

        Product2 testProduct = (Product2) new Product2Selector()
            .selectProducts()
            .executeQuery()
            .get(0);

        PricebookEntry pbe = (PricebookEntry) new PricebookEntrySelector()
            .getAllPBEs()
            .executeQuery()
            .get(0);

        List<QuoteLineItem> qlis = (List<QuoteLineItem>) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                QuoteLineItem.QuoteId => qt.Id,
                QuoteLineItem.Product2Id => testProduct.Id,
                QuoteLineItem.Quantity => 1,
                QuoteLineItem.PricebookEntryId => pbe.Id,
                QuoteLineItem.UnitPrice => pbe.UnitPrice
            })
            .quantity(5)
            .create()
            .getRecords();

        Map<Id, QuoteLineItem> qlisMap = new Map<Id, QuoteLineItem>(qlis);

        List<CustomAddress__c> addresses = (List<CustomAddress__c>) new SObjectBuilder(CustomAddress__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                CustomAddress__c.AddressLine__c => ValueProviderBuilder.provideUniqueString('address line '),
                CustomAddress__c.City__c => ValueProviderBuilder.provideUniqueString('city '),
                CustomAddress__c.PostalCode__c => ValueProviderBuilder.provideUniqueString('postal code '),
                CustomAddress__c.State__c => ValueProviderBuilder.provideUniqueString('state '),
                CustomAddress__c.Country__c => ValueProviderBuilder.provideUniqueString('country ')
            })
            .quantity(5)
            .create()
            .getRecords();

        List<CustomAddressAssignments__c> assignments = (List<CustomAddressAssignments__c>) new SObjectBuilder(CustomAddressAssignments__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                CustomAddressAssignments__c.CustomAddress__c => ValueProviderBuilder.provideList(new List<String>{
                    addresses[0].Id, addresses[0].Id, addresses[1].Id, addresses[2].Id, addresses[3].Id
                }),
                CustomAddressAssignments__c.AttentionTo__c => 'test',
                CustomAddressAssignments__c.Quantity__c => 1,
                CustomAddressAssignments__c.QuoteLineItem__c => ValueProviderBuilder.provideList(new List<String>{
                    qlis[0].Id, qlis[1].Id, qlis[2].Id, qlis[3].Id, qlis[4].Id
                }),
                CustomAddressAssignments__c.Type__c => QuoteHelper.SHIPPING_OPTION_GROUND
            })
            .quantity(5)
            .create()
            .getRecords();

        Test.startTest();
        DealDeskCaseDescriptionHelper.ShippingCaseDescriptionBuilder builder = new DealDeskCaseDescriptionHelper.ShippingCaseDescriptionBuilder(
            qt, null, assignments, addresses
        );
        Map<Id, List<CustomAddressAssignments__c>> addressToCaasMap = builder.getAddressToCaasMap(assignments, qlisMap);
        Test.stopTest();

        System.assert(addressToCaasMap.get(addresses[0].Id).contains(assignments[0]) && addressToCaasMap.get(addresses[0].Id).contains(assignments[1]),
            'getAddressToCaasMap should map various qlis to corresponding address');

        qlisMap.remove(qlis[0].Id);
        qlisMap.remove(qlis[1].Id);
        addressToCaasMap = builder.getAddressToCaasMap(assignments, qlisMap);
        System.assert(!addressToCaasMap.containsKey(addresses[0].Id) && addressToCaasMap.containsKey(addresses[1].Id)
            && addressToCaasMap.containsKey(addresses[2].Id) && addressToCaasMap.containsKey(addresses[3].Id),
            'getAddressToCaasMap should map only qlis which are contained in params');
    }

    @isTest
    private static void testComposeDescriptionForShippingCaseNewBusiness() {
        DealDeskCaseDescriptionHelper.templatesMetadata = new SObjectBuilder(NGBSProcessOrderCaseTemplate__mdt.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                NGBSProcessOrderCaseTemplate__mdt.Id => ValueProviderBuilder.provideDummyId(NGBSProcessOrderCaseTemplate__mdt.SObjectType),
                NGBSProcessOrderCaseTemplate__mdt.IsActive__c => true,
                NGBSProcessOrderCaseTemplate__mdt.Type__c => DealDeskCaseDescriptionHelper.SHIPPING_CASE_TEMPLATE_TYPE,
                NGBSProcessOrderCaseTemplate__mdt.ShippingReq__c => Product2Helper.SHIPPING_TYPE_MANUAL,
                NGBSProcessOrderCaseTemplate__mdt.LicenceIdOrCategoryCode__c => 'L1',
                NGBSProcessOrderCaseTemplate__mdt.Subject__c => 'Test Subject',
                NGBSProcessOrderCaseTemplate__mdt.Description__c => 'Test Template',
                NGBSProcessOrderCaseTemplate__mdt.Instruction__c => 'Test Instruction'
            })
            .quantity(1)
            .build()
            .getRecords();
        DealDeskCaseDescriptionHelper.initializeTemplatesMap();

        Quote qt = (Quote) new QuoteSelector()
            .selectQuotes()
            .executeQuery()
            .get(0);

        QuoteLineItem qli = (QuoteLineItem) new QuoteLineItemSelector()
            .selectQuoteLineItems()
            .selectFields(new List<String>{
                'Product_Lic_Id__c',
                'Display_Name__c',
                'Discount_Value__c',
                'Product2.InitialOrderType__c',
                'Product2.UpsellType__c',
                'Product2.ShippingType__c'
            })
            .executeQuery()
            .get(0);

        CustomAddress__c address = (CustomAddress__c) new CustomAddressSelector()
            .selectCustomAddress()
            .selectFields(new CustomAddressSelector().getDefaultFieldList())
            .executeQuery()
            .get(0);

        CustomAddressAssignments__c addressAssignment = (CustomAddressAssignments__c) new CustomAddressAssignmentsSelector()
            .selectCustomAddressAssignments()
            .executeQuery()
            .get(0);

        String accountUrl =  URL.getOrgDomainUrl().toExternalForm() + '/' + qt.Account__c;
        String expectedDescription = 'Account: ' + accountUrl + '\n\n';
        String opportunityUrl =  URL.getOrgDomainUrl().toExternalForm() + '/' + qt.OpportunityId;
        expectedDescription += 'Opportunity: ' + opportunityUrl + '\n\n';
        expectedDescription += DealDeskCaseDescriptionHelper.templatesMetadata.get(0).Description__c;
        expectedDescription += '\n\n1. Product Name: ' + qli.Display_Name__c + '; Quantity: ' + String.valueOf(qli.Quantity) + ';';

        expectedDescription += '\n\n' + DealDeskCaseDescriptionHelper.templatesMetadata.get(0).Instruction__c;

        Map<String, DealDeskCaseDescriptionHelper.CaseDescriptionMapping> mappingsForCaseTypes = DealDeskCaseDescriptionHelper.getLicenseIdOrCategoryCodeToTemplate();
        DealDeskCaseDescriptionHelper.CaseDescriptionMapping shippingMapping = mappingsForCaseTypes.get(
            DealDeskCaseDescriptionHelper.SHIPPING_CASE_TEMPLATE_TYPE
        );

        Map<Id, List<QuoteLineItem>> templateIdToQLIsMap = DealDeskCaseDescriptionHelper.getTemplateIdToQLIsMap(
            shippingMapping,
            new List<QuoteLineItem>{qli}
        );

        DealDeskCaseDescriptionHelper.ShippingCaseDescriptionBuilder builder = new DealDeskCaseDescriptionHelper.ShippingCaseDescriptionBuilder(
            qt,
            templateIdToQLIsMap,
            new List<CustomAddressAssignments__c>{addressAssignment},
            new List<CustomAddress__c>{address}
        );

        Test.startTest();
        List<DealDeskCaseDescription__c> caseDescriptions = builder.buildDealDeskCaseDescriptions();
        System.assertEquals(1, caseDescriptions.size(), 'builder should create 1 DealDeskCaseDescription__c record');
        DealDeskCaseDescription__c createdDescriptionRecord = caseDescriptions.get(0);
        String actualDescription = createdDescriptionRecord.CaseDescription__c;
        Test.stopTest();

        System.assertEquals(expectedDescription, actualDescription, 'composeDescription should properly create a description');
        System.assertEquals(
            DealDeskCaseDescriptionHelper.generateCaseSubject(DealDeskCaseDescriptionHelper.templatesMetadata.get(0).Subject__c, qt.Opportunity.Name),
            createdDescriptionRecord.Subject__c,
            'Subject__c should have the same value as specified in configuration'
        );
    }

    @isTest
    private static void testComposeDescriptionForShippingCaseNewBusinessWithoutFT() {
        new SObjectBuilder(Feature_Toggle__c.SObjectType)
            .setField(Feature_Toggle__c.Shipping_Tab_New_Business__c, false)
            .create();

        DealDeskCaseDescriptionHelper.templatesMetadata = new SObjectBuilder(NGBSProcessOrderCaseTemplate__mdt.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                NGBSProcessOrderCaseTemplate__mdt.IsActive__c => true,
                NGBSProcessOrderCaseTemplate__mdt.Type__c => DealDeskCaseDescriptionHelper.SHIPPING_CASE_TEMPLATE_TYPE,
                NGBSProcessOrderCaseTemplate__mdt.ShippingReq__c => Product2Helper.SHIPPING_TYPE_MANUAL,
                NGBSProcessOrderCaseTemplate__mdt.LicenceIdOrCategoryCode__c => 'L1',
                NGBSProcessOrderCaseTemplate__mdt.Subject__c => 'Test Subject',
                NGBSProcessOrderCaseTemplate__mdt.Description__c => 'Test Template',
                NGBSProcessOrderCaseTemplate__mdt.Instruction__c => 'Test Instruction'
            })
            .quantity(1)
            .build()
            .getRecords();
        DealDeskCaseDescriptionHelper.initializeTemplatesMap();

        Quote qt = (Quote) new QuoteSelector()
            .selectQuotes()
            .executeQuery()
            .get(0);

        QuoteLineItem qli = (QuoteLineItem) new QuoteLineItemSelector()
            .selectQuoteLineItems()
            .selectFields(new List<String>{
                'Product_Lic_Id__c',
                'Display_Name__c',
                'Discount_Value__c',
                'Product2.InitialOrderType__c',
                'Product2.UpsellType__c',
                'Product2.ShippingType__c'
            })
            .executeQuery()
            .get(0);

        String accountUrl =  URL.getOrgDomainUrl().toExternalForm() + '/' + qt.Account__c;
        String expectedDescription = 'Account: ' + accountUrl + '\n\n';
        String opportunityUrl =  URL.getOrgDomainUrl().toExternalForm() + '/' + qt.OpportunityId;
        expectedDescription += 'Opportunity: ' + opportunityUrl + '\n\n';
        expectedDescription += DealDeskCaseDescriptionHelper.templatesMetadata.get(0).Description__c;
        expectedDescription += '\n\n1. Product Name: ' + qli.Display_Name__c + '; Quantity: ' + String.valueOf(qli.Quantity) + ';';

        expectedDescription += '\n\n' + DealDeskCaseDescriptionHelper.templatesMetadata.get(0).Instruction__c;


        Map<String, DealDeskCaseDescriptionHelper.CaseDescriptionMapping> mappingsForCaseTypes = DealDeskCaseDescriptionHelper.getLicenseIdOrCategoryCodeToTemplate();
        DealDeskCaseDescriptionHelper.CaseDescriptionMapping shippingMapping = mappingsForCaseTypes.get(
            DealDeskCaseDescriptionHelper.SHIPPING_CASE_TEMPLATE_TYPE
        );

        Map<Id, List<QuoteLineItem>> templateIdToQLIsMap = DealDeskCaseDescriptionHelper.getTemplateIdToQLIsMap(
            shippingMapping,
            new List<QuoteLineItem>{qli}
        );

        DealDeskCaseDescriptionHelper.ShippingCaseDescriptionBuilder builder = new DealDeskCaseDescriptionHelper.ShippingCaseDescriptionBuilder(
            qt,
            templateIdToQLIsMap,
            new List<CustomAddressAssignments__c>(),
            new List<CustomAddress__c>()
        );

        Test.startTest();
        List<DealDeskCaseDescription__c> caseDescriptions = builder.buildDealDeskCaseDescriptions();
        System.assertEquals(1, caseDescriptions.size(), 'builder should create 1 DealDeskCaseDescription__c record');
        DealDeskCaseDescription__c createdDescriptionRecord = caseDescriptions.get(0);
        String actualDescription = createdDescriptionRecord.CaseDescription__c;
        Test.stopTest();

        System.assertEquals(expectedDescription, actualDescription, 'composeDescription should properly create a description');
        System.assertEquals(
            DealDeskCaseDescriptionHelper.generateCaseSubject(DealDeskCaseDescriptionHelper.templatesMetadata.get(0).Subject__c, qt.Opportunity.Name),
            createdDescriptionRecord.Subject__c,
            'Subject__c should have the same value as specified in configuration'
        );
    }

    @isTest
    private static void testGetDealDeskCaseDescriptions() {

        DealDeskCaseDescriptionHelper.templatesMetadata = new SObjectBuilder(NGBSProcessOrderCaseTemplate__mdt.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                NGBSProcessOrderCaseTemplate__mdt.Id => ValueProviderBuilder.provideDummyId(NGBSProcessOrderCaseTemplate__mdt.SObjectType),
                NGBSProcessOrderCaseTemplate__mdt.IsActive__c => true,
                NGBSProcessOrderCaseTemplate__mdt.Type__c => ValueProviderBuilder.provideList(new List<String>{
                    DealDeskCaseDescriptionHelper.SHIPPING_CASE_TEMPLATE_TYPE,
                    DealDeskCaseDescriptionHelper.CHANGE_ORDER_CASE_TEMPLATE_TYPE
                }),
                NGBSProcessOrderCaseTemplate__mdt.ShippingReq__c => Product2Helper.SHIPPING_TYPE_MANUAL,
                NGBSProcessOrderCaseTemplate__mdt.UpsellType__c => Product2Helper.ORDER_TYPE_MANUAL,
                NGBSProcessOrderCaseTemplate__mdt.LicenceIdOrCategoryCode__c => 'L1',
                NGBSProcessOrderCaseTemplate__mdt.Subject__c => 'Test Subject',
                NGBSProcessOrderCaseTemplate__mdt.Description__c => 'Test Template',
                NGBSProcessOrderCaseTemplate__mdt.Instruction__c => 'Test Instruction'
            })
            .quantity(2)
            .build()
            .getRecords();
        DealDeskCaseDescriptionHelper.initializeTemplatesMap();

        Quote qt = (Quote) new QuoteSelector()
            .selectQuotes()
            .executeQuery()
            .get(0);

        Product2 testProduct = (Product2) new Product2Selector()
            .selectProducts()
            .executeQuery()
            .get(0);

        testProduct.UpsellType__c = Product2Helper.ORDER_TYPE_MANUAL;
        testProduct.ShippingType__c = Product2Helper.SHIPPING_TYPE_MANUAL;
        update testProduct;

        PricebookEntry pbe = (PricebookEntry) new PricebookEntrySelector()
            .getAllPBEs()
            .executeQuery()
            .get(0);

        new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                QuoteLineItem.QuoteId => qt.Id,
                QuoteLineItem.Product2Id => testProduct.Id,
                QuoteLineItem.Quantity => 1,
                QuoteLineItem.Zero_Quantity__c => false,
                QuoteLineItem.PricebookEntryId => pbe.Id,
                QuoteLineItem.UnitPrice => pbe.UnitPrice,
                QuoteLineItem.PackageInfo__c => '{}'
            })
            .create();

        List<QuoteLineItem> qliList = (List<QuoteLineItem>) new QuoteLineItemSelector()
            .selectQuoteLineItems()
            .selectFields(new List<String>{
                'Quantity',
                'UnitPrice',
                'Zero_Quantity__c',
                'PackageInfo__c',
                'CurrencyIsoCode',
                'Product_Lic_Id__c',
                'Display_Name__c',
                'Discount_Value__c',
                'Charge_Term__c',
                'EffectivePriceNew__c',
                'Product2.InitialOrderType__c',
                'Product2.UpsellType__c',
                'Product2.ShippingType__c'
            })
            .executeQuery();

        CustomAddress__c address = (CustomAddress__c) new CustomAddressSelector()
            .selectCustomAddress()
            .selectFields(new CustomAddressSelector().getDefaultFieldList())
            .executeQuery()
            .get(0);

        CustomAddressAssignments__c addressAssignment = (CustomAddressAssignments__c) new CustomAddressAssignmentsSelector()
            .selectCustomAddressAssignments()
            .executeQuery()
            .get(0);

        DealDeskCaseDescriptionHelper.QLIsByLabelsData qliData = DealDeskCaseDescriptionHelper.getQuoteLineItemsByLabels(qt.BusinessIdentity__c, qliList);

        Map<String, DealDeskCaseDescriptionHelper.TemplateData> templateDataMap = DealDeskCaseDescriptionHelper.getTemplateDataMap(qliData);

        Test.startTest();
        Boolean isSignUp = false;
        List<DealDeskCaseDescription__c> dealDeskCaseDescriptions = DealDeskCaseDescriptionHelper.getDealDeskCaseDescriptions(
            qt,
            templateDataMap,
            new List<CustomAddressAssignments__c>{addressAssignment},
            new List<CustomAddress__c>{address},
            new List<AssignmentLineItem__c>(),
            new List<Area_Code_Line_Item__c>(),
            isSignUp
        );
        Test.stopTest();

        System.assertEquals(dealDeskCaseDescriptions.size(), 2,
            'getDealDeskCaseDescriptions should return a list of DealDeskCaseDescription__c with two element');

        for (DealDeskCaseDescription__c caseDescription : dealDeskCaseDescriptions) {
            System.assertNotEquals(caseDescription.CaseDescription__c, null,
                'getDealDeskCaseDescriptions should return a list of DealDeskCaseDescription__c with not empty CaseDescription__c');
            System.assertNotEquals(caseDescription.Account__c, null,
                'getDealDeskCaseDescriptions should return a list of DealDeskCaseDescription__c with not empty Account__c');
        }
    }

    @isTest
    private static void testHandleDealDeskCaseDescriptions() {
        new SObjectBuilder(Feature_Toggle__c.SObjectType)
            .setField(Feature_Toggle__c.Shipping_Tab_New_Business__c, true)
            .create();

        DealDeskCaseDescriptionHelper.templatesMetadata = new SObjectBuilder(NGBSProcessOrderCaseTemplate__mdt.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                NGBSProcessOrderCaseTemplate__mdt.Id => ValueProviderBuilder.provideDummyId(NGBSProcessOrderCaseTemplate__mdt.SObjectType),
                NGBSProcessOrderCaseTemplate__mdt.IsActive__c => true,
                NGBSProcessOrderCaseTemplate__mdt.Type__c => ValueProviderBuilder.provideList(new List<String>{
                    DealDeskCaseDescriptionHelper.SHIPPING_CASE_TEMPLATE_TYPE,
                    DealDeskCaseDescriptionHelper.INITIAL_ORDER_CASE_TEMPLATE_TYPE
                }),
                NGBSProcessOrderCaseTemplate__mdt.ShippingReq__c => Product2Helper.SHIPPING_TYPE_MANUAL,
                NGBSProcessOrderCaseTemplate__mdt.InitialOrderType__c => Product2Helper.ORDER_TYPE_MANUAL,
                NGBSProcessOrderCaseTemplate__mdt.LicenceIdOrCategoryCode__c => 'L1',
                NGBSProcessOrderCaseTemplate__mdt.Subject__c => ValueProviderBuilder.provideList(new List<String>{
                    DealDeskCaseDescriptionHelper.SHIPPING_CASE_TEMPLATE_TYPE,
                    DealDeskCaseDescriptionHelper.INITIAL_ORDER_CASE_TEMPLATE_TYPE
                }),
                NGBSProcessOrderCaseTemplate__mdt.Owner__c => ValueProviderBuilder.provideList(new List<String>{
                    UserInfo.getUserId(),
                    '005_who_pretends_to_be_a_user_id'
                }),
                NGBSProcessOrderCaseTemplate__mdt.Description__c => ValueProviderBuilder.provideUniqueString('Test Template')
            })
            .quantity(2)
            .build()
            .getRecords();

        Opportunity opp = (Opportunity) new OpportunitySelector()
            .selectOpportunities()
            .executeQuery()
            .get(0);

        Quote qt = (Quote) new QuoteSelector()
            .selectQuotes()
            .executeQuery()
            .get(0);

        Product2 testProduct = (Product2) new Product2Selector()
            .selectProducts()
            .executeQuery()
            .get(0);

        testProduct.ShippingType__c = Product2Helper.SHIPPING_TYPE_MANUAL;
        testProduct.InitialOrderType__c = Product2Helper.ORDER_TYPE_MANUAL;
        update testProduct;

        PricebookEntry pbe = (PricebookEntry) new PricebookEntrySelector()
            .getAllPBEs()
            .executeQuery()
            .get(0);

        new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                QuoteLineItem.QuoteId => qt.Id,
                QuoteLineItem.Product2Id => testProduct.Id,
                QuoteLineItem.Quantity => 1,
                QuoteLineItem.PricebookEntryId => pbe.Id,
                QuoteLineItem.UnitPrice => pbe.UnitPrice,
                QuoteLineItem.PackageInfo__c => '{}'
            })
            .create();

        qt = (Quote) new QuoteSelector()
            .selectQuoteForSyncWithNGBSByQuoteId(qt.Id)
            .selectFields(new List<String>{'Opportunity.Name'})
            .executeQuery()
            .get(0);

        Test.startTest();
        List<DealDeskCaseDescription__c> existingDescsForAccount = DealDeskCaseDescriptionHelper.handleDealDeskCaseDescriptionsForSignUp(qt);
        Test.stopTest();

        System.assertEquals(2, existingDescsForAccount.size(),
            'DealDeskCaseDescriptionHelper.handleDealDeskCaseDescriptionsForSignUp should properly create DealDeskCaseDescription__c records');
        for (DealDeskCaseDescription__c caseDescription : existingDescsForAccount) {
                if (caseDescription.Subject__c == DealDeskCaseDescriptionHelper.generateCaseSubject(DealDeskCaseDescriptionHelper.INITIAL_ORDER_CASE_TEMPLATE_TYPE, qt.Opportunity.Name)) {
                System.assertEquals(DealDeskCaseGenerator.DEAL_DESK_QUEUE.QueueId, caseDescription.CaseOwner__c,
                    'DealDeskCaseDescriptionHelper.handleDealDeskCaseDescriptionsForSignUp should set default CaseOwner__c if NGBSProcessOrderCaseTemplate__mdt doesn\'t contain valid Owner__c');
            } else {
                System.assertEquals(UserInfo.getUserId(), caseDescription.CaseOwner__c,
                    'DealDeskCaseDescriptionHelper.handleDealDeskCaseDescriptionsForSignUp should set CaseOwner__c from NGBSProcessOrderCaseTemplate__mdt');
            }
        }
    }

    @isTest
    private static void testHandleDealDeskCaseDescriptionsWithoutQlisWithManualShipping() {
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.RC_User_ID__c => '1',
                Account.Billing_ID__c => '1'
            })
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SobjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.AccountId => acc.Id,
                Opportunity.CloseDate => System.today()
            })
            .create()
            .getRecord();

        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Quote.Account__c => acc.Id,
                Quote.OpportunityId => opp.Id,
                Quote.Pricebook2Id => Test.getStandardPricebookId(),
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.isPrimary__c => true
            })
            .create()
            .getRecord();

        qt = (Quote) new QuoteSelector()
            .selectQuoteById(new List<Object>{qt.Id})
            .executeQuery()
            .get(0);

        Response resp = new Response();

        Test.startTest();
        List<DealDeskCaseDescription__c> existingDescsForAccount = DealDeskCaseDescriptionHelper.handleDealDeskCaseDescriptionsForSyncWithNGBS(qt);
        Test.stopTest();

        System.assertEquals(existingDescsForAccount.size(), 0,
            'handleDealDeskCaseDescriptionsForSyncWithNGBS shouldn\'t create DealDeskCaseDescription__c records if there are no qlis with manual label');
    }

    @isTest
    private static void testComposeDescriptionForInitialOrderCase() {
        DealDeskCaseDescriptionHelper.templatesMetadata = new SObjectBuilder(NGBSProcessOrderCaseTemplate__mdt.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                NGBSProcessOrderCaseTemplate__mdt.IsActive__c => true,
                NGBSProcessOrderCaseTemplate__mdt.Type__c => DealDeskCaseDescriptionHelper.INITIAL_ORDER_CASE_TEMPLATE_TYPE,
                NGBSProcessOrderCaseTemplate__mdt.InitialOrderType__c => Product2Helper.ORDER_TYPE_MANUAL,
                NGBSProcessOrderCaseTemplate__mdt.LicenceIdOrCategoryCode__c => 'L1',
                NGBSProcessOrderCaseTemplate__mdt.Subject__c => 'Test Subject',
                NGBSProcessOrderCaseTemplate__mdt.Description__c => 'Test Template',
                NGBSProcessOrderCaseTemplate__mdt.Instruction__c => 'Test Instruction'
            })
            .quantity(1)
            .build()
            .getRecords();
        DealDeskCaseDescriptionHelper.initializeTemplatesMap();

        Quote qt = (Quote) new QuoteSelector()
            .selectQuotes()
            .executeQuery()
            .get(0);

        Product2 testProduct = (Product2) new Product2Selector()
            .selectProducts()
            .executeQuery()
            .get(0);

        testProduct.InitialOrderType__c = Product2Helper.ORDER_TYPE_MANUAL;
        update testProduct;

        QuoteLineItem qli = (QuoteLineItem) new QuoteLineItemSelector()
            .selectQuoteLineItems()
            .selectFields(new List<String>{
                'Quantity',
                'UnitPrice',
                'Zero_Quantity__c',
                'PackageInfo__c',
                'CurrencyIsoCode',
                'Product_Lic_Id__c',
                'Display_Name__c',
                'Discount_Value__c',
                'Discount_Type__c',
                'Charge_Term__c',
                'EffectivePriceNew__c',
                'Product2.InitialOrderType__c',
                'Product2.UpsellType__c',
                'Product2.ShippingType__c'
            })
            .executeQuery()
            .get(0);

        String accountUrl =  URL.getOrgDomainUrl().toExternalForm() + '/' + qt.Account__c;
        String expectedDescription = 'Account: ' + accountUrl + '\n\n';
        String opportunityUrl =  URL.getOrgDomainUrl().toExternalForm() + '/' + qt.OpportunityId;
        expectedDescription += 'Opportunity: ' + opportunityUrl + '\n\n';
        expectedDescription += DealDeskCaseDescriptionHelper.templatesMetadata.get(0).Description__c;
        expectedDescription += '\n\n1. Product Name: ' + qli.Display_Name__c + '; Charge Term: ' + qli.Charge_Term__c
            + '; Price: ' + DealDeskCaseDescriptionHelper.calculatePrice(qli) + '; Quantity: ' + String.valueOf(Math.round(qli.Quantity)) + '; Discount: ' + DealDeskCaseDescriptionHelper.calculateDiscount(qli) + ';';
        expectedDescription += '\n\n' + DealDeskCaseDescriptionHelper.templatesMetadata.get(0).Instruction__c;


        Map<String, DealDeskCaseDescriptionHelper.CaseDescriptionMapping> mappingsForCaseTypes = DealDeskCaseDescriptionHelper.getLicenseIdOrCategoryCodeToTemplate();
        DealDeskCaseDescriptionHelper.CaseDescriptionMapping initialOrderMapping = mappingsForCaseTypes.get(
            DealDeskCaseDescriptionHelper.INITIAL_ORDER_CASE_TEMPLATE_TYPE
        );

        Map<Id, List<QuoteLineItem>> templateIdToQLIsMap = DealDeskCaseDescriptionHelper.getTemplateIdToQLIsMap(
            initialOrderMapping,
            new List<QuoteLineItem>{qli}
        );

        DealDeskCaseDescriptionHelper.InitialOrderCaseDescriptionBuilder builder = new DealDeskCaseDescriptionHelper.InitialOrderCaseDescriptionBuilder(
            qt,
            templateIdToQLIsMap,
            new List<AssignmentLineItem__c>(),
            new List<Area_Code_Line_Item__c>()
        );

        Test.startTest();
        List<DealDeskCaseDescription__c> caseDescriptions = builder.buildDealDeskCaseDescriptions();
        System.assertEquals(1, caseDescriptions.size(), 'builder should create 1 DealDeskCaseDescription__c record');
        DealDeskCaseDescription__c createdDescriptionRecord = caseDescriptions.get(0);
        String actualDescription = createdDescriptionRecord.CaseDescription__c;
        Test.stopTest();

        System.assertEquals(expectedDescription, actualDescription, 'composeDescription should properly create a description');
        System.assertEquals(
            DealDeskCaseDescriptionHelper.generateCaseSubject(DealDeskCaseDescriptionHelper.templatesMetadata.get(0).Subject__c, qt.Opportunity.Name),
            createdDescriptionRecord.Subject__c,
            'Subject__c should have the same value as specified in configuration'
        );
    }

    @isTest
    private static void testComposeDescriptionForChangeOrderCase() {
        DealDeskCaseDescriptionHelper.templatesMetadata = new SObjectBuilder(NGBSProcessOrderCaseTemplate__mdt.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                NGBSProcessOrderCaseTemplate__mdt.Id => ValueProviderBuilder.provideDummyId(NGBSProcessOrderCaseTemplate__mdt.SObjectType),
                NGBSProcessOrderCaseTemplate__mdt.IsActive__c => true,
                NGBSProcessOrderCaseTemplate__mdt.Type__c => DealDeskCaseDescriptionHelper.CHANGE_ORDER_CASE_TEMPLATE_TYPE,
                NGBSProcessOrderCaseTemplate__mdt.UpsellType__c => Product2Helper.ORDER_TYPE_MANUAL,
                NGBSProcessOrderCaseTemplate__mdt.LicenceIdOrCategoryCode__c => 'L1',
                NGBSProcessOrderCaseTemplate__mdt.Subject__c => 'Test Subject',
                NGBSProcessOrderCaseTemplate__mdt.Description__c => 'Test Template',
                NGBSProcessOrderCaseTemplate__mdt.Instruction__c => 'Test Instruction'
            })
            .quantity(1)
            .build()
            .getRecords();
        DealDeskCaseDescriptionHelper.initializeTemplatesMap();

        Quote qt = (Quote) new QuoteSelector()
            .selectQuotes()
            .executeQuery()
            .get(0);

        Product2 testProduct = (Product2) new Product2Selector()
            .selectProducts()
            .executeQuery()
            .get(0);

        testProduct.UpsellType__c = Product2Helper.ORDER_TYPE_MANUAL;
        update testProduct;

        QuoteLineItem qli = (QuoteLineItem) new QuoteLineItemSelector()
            .selectQuoteLineItems()
            .selectFields(new List<String>{
                'Quantity',
                'UnitPrice',
                'Zero_Quantity__c',
                'PackageInfo__c',
                'CurrencyIsoCode',
                'Product_Lic_Id__c',
                'Display_Name__c',
                'Discount_Value__c',
                'Discount_Type__c',
                'Charge_Term__c',
                'EffectivePriceNew__c',
                'Product2.InitialOrderType__c',
                'Product2.UpsellType__c',
                'Product2.ShippingType__c'
            })
            .executeQuery()
            .get(0);

        String accountUrl =  URL.getOrgDomainUrl().toExternalForm() + '/' + qt.Account__c;
        String expectedDescription = 'Account: ' + accountUrl + '\n\n';
        String opportunityUrl =  URL.getOrgDomainUrl().toExternalForm() + '/' + qt.OpportunityId;
        expectedDescription += 'Opportunity: ' + opportunityUrl + '\n\n';
        expectedDescription += DealDeskCaseDescriptionHelper.templatesMetadata.get(0).Description__c;
        expectedDescription += '\n\n1. Product Name: ' + qli.Display_Name__c + '; Charge Term: ' + qli.Charge_Term__c
            + '; Price: ' + DealDeskCaseDescriptionHelper.calculatePrice(qli) + '; Quantity: ' + String.valueOf(Math.round(qli.Quantity)) + '; Discount: ' + DealDeskCaseDescriptionHelper.calculateDiscount(qli) + ';';
        expectedDescription += '\n\n' + DealDeskCaseDescriptionHelper.templatesMetadata.get(0).Instruction__c;


        Map<String, DealDeskCaseDescriptionHelper.CaseDescriptionMapping> mappingsForCaseTypes = DealDeskCaseDescriptionHelper.getLicenseIdOrCategoryCodeToTemplate();
        DealDeskCaseDescriptionHelper.CaseDescriptionMapping changeOrderMapping = mappingsForCaseTypes.get(
            DealDeskCaseDescriptionHelper.CHANGE_ORDER_CASE_TEMPLATE_TYPE
        );

        Map<Id, List<QuoteLineItem>> templateIdToQLIsMap = DealDeskCaseDescriptionHelper.getTemplateIdToQLIsMap(
            changeOrderMapping,
            new List<QuoteLineItem>{qli}
        );

        DealDeskCaseDescriptionHelper.ChangeOrderCaseDescriptionBuilder builder = new DealDeskCaseDescriptionHelper.ChangeOrderCaseDescriptionBuilder(
            qt,
            templateIdToQLIsMap,
            new List<AssignmentLineItem__c>(),
            new List<Area_Code_Line_Item__c>()
        );

        Test.startTest();
        List<DealDeskCaseDescription__c> caseDescriptions = builder.buildDealDeskCaseDescriptions();
        System.assertEquals(1, caseDescriptions.size(), 'builder should create 1 DealDeskCaseDescription__c record');
        DealDeskCaseDescription__c createdDescriptionRecord = caseDescriptions.get(0);
        String actualDescription = createdDescriptionRecord.CaseDescription__c;
        Test.stopTest();

        System.assertEquals(expectedDescription, actualDescription, 'composeDescription should properly create a description');
        System.assertEquals(
            DealDeskCaseDescriptionHelper.generateCaseSubject(DealDeskCaseDescriptionHelper.templatesMetadata.get(0).Subject__c, qt.Opportunity.Name),
            createdDescriptionRecord.Subject__c,
            'Subject__c should have the same value as specified in configuration'
        );
    }

    @isTest
    private static void testComposeDescriptionForProductWithAssignment() {
        DealDeskCaseDescriptionHelper.templatesMetadata = new SObjectBuilder(NGBSProcessOrderCaseTemplate__mdt.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                NGBSProcessOrderCaseTemplate__mdt.IsActive__c => true,
                NGBSProcessOrderCaseTemplate__mdt.Type__c => DealDeskCaseDescriptionHelper.INITIAL_ORDER_CASE_TEMPLATE_TYPE,
                NGBSProcessOrderCaseTemplate__mdt.InitialOrderType__c => Product2Helper.ORDER_TYPE_MANUAL,
                NGBSProcessOrderCaseTemplate__mdt.LicenceIdOrCategoryCode__c => 'L1',
                NGBSProcessOrderCaseTemplate__mdt.Subject__c => 'Test Subject',
                NGBSProcessOrderCaseTemplate__mdt.Description__c => 'Test Template',
                NGBSProcessOrderCaseTemplate__mdt.Instruction__c => 'Test Instruction'
            })
            .quantity(1)
            .build()
            .getRecords();
        DealDeskCaseDescriptionHelper.initializeTemplatesMap();

        Quote qt = (Quote) new QuoteSelector()
            .selectQuotes()
            .executeQuery()
            .get(0);

        Product2 parentProduct = (Product2) new Product2Selector()
            .selectProducts()
            .executeQuery()
            .get(0);

        parentProduct.InitialOrderType__c = Product2Helper.ORDER_TYPE_MANUAL;
        update parentProduct;

        Product2 childProduct = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Product2.Name => 'test child product',
                Product2.ExtID__c => 'L2',
                Product2.InitialOrderType__c => Product2Helper.ORDER_TYPE_MANUAL
            })
            .create()
            .getRecord();

        PricebookEntry childPbe = (PricebookEntry) new SObjectBuilder(PricebookEntry.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                PricebookEntry.Product2Id => childProduct.Id,
                PricebookEntry.UnitPrice => 10,
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false
            })
            .create()
            .getRecord();

        QuoteLineItem parentQli = (QuoteLineItem) new QuoteLineItemSelector()
            .selectQuoteLineItems()
            .selectFields(new List<String>{
                'Quantity',
                'UnitPrice',
                'Zero_Quantity__c',
                'PackageInfo__c',
                'CurrencyIsoCode',
                'Product_Lic_Id__c',
                'Display_Name__c',
                'Discount_Value__c',
                'Discount_Type__c',
                'Charge_Term__c',
                'EffectivePriceNew__c',
                'Product2.InitialOrderType__c',
                'Product2.UpsellType__c',
                'Product2.ShippingType__c'
            })
            .executeQuery()
            .get(0);

        QuoteLineItem childQli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                QuoteLineItem.QuoteId => parentQli.Quote.Id,
                QuoteLineItem.Deactivated__c => false,
                QuoteLineItem.PricebookEntryId => childPbe.Id,
                QuoteLineItem.Quantity => 1,
                QuoteLineItem.NewQuantity__c => 1,
                QuoteLineItem.UnitPrice => 10,
                QuoteLineItem.Discount => 2,
                QuoteLineItem.Product2Id => childProduct.Id,
                QuoteLineItem.IsMultiProductTechnicalQLI__c => false,
                QuoteLineItem.EffectivePriceNew__c => 9.80
            })
            .create()
            .getRecord();

        Area_Codes__c ac = (Area_Codes__c) new SObjectBuilder(Area_Codes__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Area_Codes__c.Name => 'test area code',
                Area_Codes__c.Area_Code__c => 4,
                Area_Codes__c.City__c => 'test city',
                Area_Codes__c.Country__c => 'test country'
            })
            .create()
            .getRecord();

        AssignmentLineItem__c ali = (AssignmentLineItem__c) new SObjectBuilder(AssignmentLineItem__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                AssignmentLineItem__c.Parent__c   => parentQli.Id,
                AssignmentLineItem__c.Child__c    => childQli.Id,
                AssignmentLineItem__c.AreaCode__c => ac.Id,
                AssignmentLineItem__c.Quantity__c => 1
            })
            .create()
            .getRecord();

        List<AssignmentLineItem__c> assignmentLineItems = (List<AssignmentLineItem__c>) new AssignmentLineItemSelector()
            .selectALIForDealDeskCaseDescription(new List<Object>{new Set<Id>{parentQli.Id}})
            .executeQuery();

        ali = assignmentLineItems.get(0);

        String accountUrl =  URL.getOrgDomainUrl().toExternalForm() + '/' + qt.Account__c;
        String expectedDescription = 'Account: ' + accountUrl + '\n\n';
        String opportunityUrl =  URL.getOrgDomainUrl().toExternalForm() + '/' + qt.OpportunityId;
        expectedDescription += 'Opportunity: ' + opportunityUrl + '\n\n';
        expectedDescription += DealDeskCaseDescriptionHelper.templatesMetadata.get(0).Description__c;
        expectedDescription += '\n\n1. Product Name: ' + parentQli.Display_Name__c + '; Charge Term: ' + parentQli.Charge_Term__c
            + '; Price: ' + DealDeskCaseDescriptionHelper.calculatePrice(parentQli) + '; Quantity: ' + String.valueOf(Math.round(ali.Quantity__c)) + '; Discount: ' + DealDeskCaseDescriptionHelper.calculateDiscount(parentQli) + ';';
        expectedDescription += '\nProduct Name: ' + ali.Child__r.Display_Name__c + '; Charge Term: ' + ali.Child__r.Charge_Term__c
            + '; Price: ' + DealDeskCaseDescriptionHelper.calculatePrice(ali.Child__r) + '; Quantity: ' + String.valueOf(Math.round(ali.Quantity__c)) + '; Discount: ' + DealDeskCaseDescriptionHelper.calculateDiscount(ali.Child__r) + ';';
        expectedDescription += '\nArea Code: ' + ac.Area_Code__c + ' ' + ac.City__c + ' ' + ac.Country__c + ';';
        expectedDescription += '\n\n' + DealDeskCaseDescriptionHelper.templatesMetadata.get(0).Instruction__c;


        Map<String, DealDeskCaseDescriptionHelper.CaseDescriptionMapping> mappingsForCaseTypes = DealDeskCaseDescriptionHelper.getLicenseIdOrCategoryCodeToTemplate();
        DealDeskCaseDescriptionHelper.CaseDescriptionMapping initialOrderMapping = mappingsForCaseTypes.get(
            DealDeskCaseDescriptionHelper.INITIAL_ORDER_CASE_TEMPLATE_TYPE
        );

        Map<Id, List<QuoteLineItem>> templateIdToQLIsMap = DealDeskCaseDescriptionHelper.getTemplateIdToQLIsMap(
            initialOrderMapping,
            new List<QuoteLineItem>{parentQli}
        );

        DealDeskCaseDescriptionHelper.InitialOrderCaseDescriptionBuilder builder = new DealDeskCaseDescriptionHelper.InitialOrderCaseDescriptionBuilder(
            qt,
            templateIdToQLIsMap,
            assignmentLineItems,
            new List<Area_Code_Line_Item__c>()
        );

        Test.startTest();
        List<DealDeskCaseDescription__c> caseDescriptions = builder.buildDealDeskCaseDescriptions();
        String actualDescription = caseDescriptions.get(0).CaseDescription__c;
        Test.stopTest();

        System.assertEquals(expectedDescription, actualDescription, 'composeDescription should properly create a description');
    }

    @isTest
    private static void testComposeDescriptionForProductWithAreaCode() {
        DealDeskCaseDescriptionHelper.templatesMetadata = new SObjectBuilder(NGBSProcessOrderCaseTemplate__mdt.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                NGBSProcessOrderCaseTemplate__mdt.IsActive__c => true,
                NGBSProcessOrderCaseTemplate__mdt.Type__c => DealDeskCaseDescriptionHelper.INITIAL_ORDER_CASE_TEMPLATE_TYPE,
                NGBSProcessOrderCaseTemplate__mdt.InitialOrderType__c => Product2Helper.ORDER_TYPE_MANUAL,
                NGBSProcessOrderCaseTemplate__mdt.LicenceIdOrCategoryCode__c => 'L1',
                NGBSProcessOrderCaseTemplate__mdt.Subject__c => 'Test Subject',
                NGBSProcessOrderCaseTemplate__mdt.Description__c => 'Test Template',
                NGBSProcessOrderCaseTemplate__mdt.Instruction__c => 'Test Instruction'
            })
            .quantity(1)
            .build()
            .getRecords();
        DealDeskCaseDescriptionHelper.initializeTemplatesMap();

        Quote qt = (Quote) new QuoteSelector()
            .selectQuotes()
            .executeQuery()
            .get(0);

        Product2 product = (Product2) new Product2Selector()
            .selectProducts()
            .executeQuery()
            .get(0);

        product.InitialOrderType__c = Product2Helper.ORDER_TYPE_MANUAL;
        update product;

        QuoteLineItem qli = (QuoteLineItem) new QuoteLineItemSelector()
            .selectQuoteLineItems()
            .selectFields(new List<String>{
                'Quantity',
                'UnitPrice',
                'Zero_Quantity__c',
                'PackageInfo__c',
                'CurrencyIsoCode',
                'Product_Lic_Id__c',
                'Display_Name__c',
                'Discount_Value__c',
                'Discount_Type__c',
                'Charge_Term__c',
                'EffectivePriceNew__c',
                'Product2.InitialOrderType__c',
                'Product2.UpsellType__c',
                'Product2.ShippingType__c'
            })
            .executeQuery()
            .get(0);

        Area_Codes__c ac = (Area_Codes__c) new SObjectBuilder(Area_Codes__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Area_Codes__c.Name => 'test area code',
                Area_Codes__c.Area_Code__c => 4,
                Area_Codes__c.City__c => 'test city',
                Area_Codes__c.Country__c => 'test country'
            })
            .create()
            .getRecord();

        Area_Code_Line_Item__c ali = (Area_Code_Line_Item__c) new SObjectBuilder(Area_Code_Line_Item__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Area_Code_Line_Item__c.Area_Code__c => ac.Id,
                Area_Code_Line_Item__c.Quantity__c => 1,
                Area_Code_Line_Item__c.Quote_Line_Item__c => qli.Id
            })
            .create()
            .getRecord();

        List<Area_Code_Line_Item__c> areaCodeLineItems = (List<Area_Code_Line_Item__c>) new AreaCodeLineItemSelector()
            .selectACLIForDealDeskCaseDescription(new List<Object>{new Set<Id>{qli.Id}})
            .executeQuery();

        String accountUrl =  URL.getOrgDomainUrl().toExternalForm() + '/' + qt.Account__c;
        String expectedDescription = 'Account: ' + accountUrl + '\n\n';
        String opportunityUrl =  URL.getOrgDomainUrl().toExternalForm() + '/' + qt.OpportunityId;
        expectedDescription += 'Opportunity: ' + opportunityUrl + '\n\n';
        expectedDescription += DealDeskCaseDescriptionHelper.templatesMetadata.get(0).Description__c;
        expectedDescription += '\n\n1. Product Name: ' + qli.Display_Name__c + '; Charge Term: ' + qli.Charge_Term__c
            + '; Price: ' + DealDeskCaseDescriptionHelper.calculatePrice(qli) + '; Quantity: ' + String.valueOf(Math.round(qli.Quantity)) + '; Discount: ' + DealDeskCaseDescriptionHelper.calculateDiscount(qli) + ';';
        expectedDescription += '\nArea Code: ' + ac.Area_Code__c + ' ' + ac.City__c + ' ' + ac.Country__c + ';';
        expectedDescription += '\n\n' + DealDeskCaseDescriptionHelper.templatesMetadata.get(0).Instruction__c;


        Map<String, DealDeskCaseDescriptionHelper.CaseDescriptionMapping> mappingsForCaseTypes = DealDeskCaseDescriptionHelper.getLicenseIdOrCategoryCodeToTemplate();
        DealDeskCaseDescriptionHelper.CaseDescriptionMapping initialOrderMapping = mappingsForCaseTypes.get(
            DealDeskCaseDescriptionHelper.INITIAL_ORDER_CASE_TEMPLATE_TYPE
        );

        Map<Id, List<QuoteLineItem>> templateIdToQLIsMap = DealDeskCaseDescriptionHelper.getTemplateIdToQLIsMap(
            initialOrderMapping,
            new List<QuoteLineItem>{qli}
        );

        DealDeskCaseDescriptionHelper.InitialOrderCaseDescriptionBuilder builder = new DealDeskCaseDescriptionHelper.InitialOrderCaseDescriptionBuilder(
            qt,
            templateIdToQLIsMap,
            new List<AssignmentLineItem__c>(),
            areaCodeLineItems
        );

        Test.startTest();
        List<DealDeskCaseDescription__c> caseDescriptions = builder.buildDealDeskCaseDescriptions();
        String actualDescription = caseDescriptions.get(0).CaseDescription__c;
        Test.stopTest();

        System.assertEquals(expectedDescription, actualDescription, 'composeDescription should properly create a description');
    }

    @isTest
    private static void testSplitToSetMethod() {
        System.assertEquals(
            new Set<String>(),
            DealDeskCaseDescriptionHelper.splitToSet(null),
            'method should return empty set if passed parameter is null'
        );
        System.assertEquals(
            new Set<String>(),
            DealDeskCaseDescriptionHelper.splitToSet(''),
            'method should return empty set if passed parameter is empty string'
        );
        System.assertEquals(
            new Set<String>{'test_value'},
            DealDeskCaseDescriptionHelper.splitToSet('test_value'),
            'method should return set with 1 element if passed string does not contain delimeter ";"'
        );
        System.assertEquals(
            new Set<String>{'test_value_1', 'test_value_2', 'test_value_3'},
            DealDeskCaseDescriptionHelper.splitToSet('test_value_1;test_value_2;test_value_3;test_value_1;test_value_1;test_value_1'),
            'method should spilt passed string using delimeter ";" and return it as a set'
        );
    }
}