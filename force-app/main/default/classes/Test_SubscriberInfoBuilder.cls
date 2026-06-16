@isTest
private class Test_SubscriberInfoBuilder {

    public static QuoteLineItem[] qlis;
    public static Area_Code_Line_Item__c[] aclis;
    public static AssignmentLineItem__c[] alis;
    public static Area_Codes__c[] acList;
    public static Quote primaryQuote;

    public static Map<Id, QuoteLineItem> qliMap;
    public static Map<Id, Area_Codes__c> acMap;

    public static CountryCodes__c countryCodesSetting;

    public static Id SC;
    public static Id MLN;
    public static Id VF;
    public static Id DL;
    public static Id E911;
    public static Id CRF;
    public static Id DL_UNL;
    public static Id HD;

    static void createTestData() {
        List<String> categoryPathList = new List<String>{
            'SC',
            'SC:MLN',
            'SC:VF',
            'DL',
            'DL:E911',
            'DL:CRF',
            'DL:DL-UNL',
            'HD'
        };
        List<String> catalogList = new List<String>{
            'LC_SC_1',
            'LC_MLN_1',
            'LC_VF_1',
            'LC_DL_1',
            'LC_E911_1',
            'LC_CRF_1',
            'LC_DL-UNL_1',
            'LC_HD_1'
        };

        new SObjectBuilder(NGBS_Phoenix_Settings__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
            NGBS_Phoenix_Settings__c.NGBSPhoenixAvailableBrands__c => OpportunityHelper.BRAND_RINGCENTRAL,
            NGBS_Phoenix_Settings__c.NGBSPhoenixAvailablePackageIDs__c => '100;200',
            NGBS_Phoenix_Settings__c.NGBSPhoenixAvailableProducts__c => 'Meetings'
        })
            .create()
            .getRecord();

        List<Decimal> qtyList = new List<Decimal>{1,1,1,11,11,11,11,11};
        List<Decimal> newQtyList = new List<Decimal>{1,1,1,11,11,11,11,11};

        List<String> pInfoList = new List<String>();
        for (String categoryPath : categoryPathList) {
            List<String> catList = categoryPath.split(':');
            String categoryCode = catList.get(catList.size() - 1);

            Map<String, Object> data = new Map<String, Object>{
                'Id' => '1',
                'Duration' => 'Monthly',
                'CategoryCode' => categoryCode,
                'CategoryPath' => categoryPath
            };
            pInfoList.add(
                NGBSTestDataGenerator.generateQLIPackageInfo(data)
            );
        }

        Product2[] prods = new SObjectBuilder(Product2.SObjectType)
            .quantity(categoryPathList.size())
            .setFields(
                new Map<SObjectField, Object>{
                    Product2.Id => ValueProviderBuilder.provideDummyId(Product2.SObjectType),
                    Product2.ExtId__c => ValueProviderBuilder.provideList(catalogList)
                }
            )
            .build()
            .getRecords();

        qlis = new SObjectBuilder(QuoteLineItem.SObjectType)
            .quantity(categoryPathList.size())
            .setFields(
                new Map<SObjectField, Object>{
                    QuoteLineItem.Id => ValueProviderBuilder.provideDummyId(QuoteLineItem.SObjectType),
                    QuoteLineItem.NewQuantity__c => ValueProviderBuilder.provideList(newQtyList),
                    QuoteLineItem.PackageInfo__c => ValueProviderBuilder.provideList(pInfoList),
                    QuoteLineItem.Package_Info_QLI__c => ValueProviderBuilder.provideList(pInfoList),
                    QuoteLineItem.Item_type__c => null
                }
            )
            .build()
            .getRecords();

        for (Integer i = 0; i < qlis.size(); i++) {
            qlis.get(i).Product2 = prods.get(i);
        }

        qliMap = new Map<Id, QuoteLineItem>(qlis);
        List<Id> qliIds = new List<Id>(qliMap.keySet());

        SC = qliIds.get(0);
        MLN = qliIds.get(1);
        VF = qliIds.get(2);
        DL = qliIds.get(3);
        E911 = qliIds.get(4);
        CRF = qliIds.get(5);
        DL_UNL = qliIds.get(6);
        HD = qliIds.get(7);

        acList = new SObjectBuilder(Area_Codes__c.SObjectType)
            .quantity(3)
            .setFields(
                new Map<SObjectField, Object>{
                    Area_Codes__c.Id => ValueProviderBuilder.provideDummyId(Area_Codes__c.SObjectType),
                    Area_Codes__c.Area_Code__c => ValueProviderBuilder.provideList(
                        new List<Decimal>{800, 833, 866}
                    ),
                    Area_Codes__c.City__c => 'New York',
                    Area_Codes__c.Country__c => 'United States'
                }
            )
            .build()
            .getRecords();

        acMap = new Map<Id, Area_Codes__c>(acList);
        List<Id> acIds = new List<Id>(acMap.keySet());

        Id ac800 = acIds.get(0);
        Id ac833 = acIds.get(1);
        Id ac866 = acIds.get(2);

        aclis = new SObjectBuilder(Area_Code_Line_Item__c.SObjectType)
            .quantity(3)
            .setFields(
                new Map<SObjectField, Object>{
                    Area_Code_Line_Item__c.Id => ValueProviderBuilder.provideDummyId(Area_Code_Line_Item__c.SObjectType),
                    Area_Code_Line_Item__c.Quote_Line_Item__c => ValueProviderBuilder.provideList(
                        new List<Id>{MLN,HD,HD}
                    ),
                    Area_Code_Line_Item__c.Area_Code__c => ValueProviderBuilder.provideList(acIds),
                    Area_Code_Line_Item__c.Quantity__c => ValueProviderBuilder.provideList(
                        new List<Decimal>{1,5,6}
                    )
                }
            )
            .build()
            .getRecords();

        alis = new SObjectBuilder(AssignmentLineItem__c.SObjectType)
            .quantity(2)
            .setFields(
                new Map<SObjectField, Object>{
                  AssignmentLineItem__c.Parent__c => DL_UNL,
                  AssignmentLineItem__c.Child__c => HD,
                  AssignmentLineItem__c.AreaCode__c => ValueProviderBuilder.provideList(
                      new List<Id>{ac833,ac866}
                  ),
                  AssignmentLineItem__c.Quantity__c => ValueProviderBuilder.provideList(
                      new List<Decimal>{5,2}
                  )
                }
            )
            .build()
            .getRecords();

        primaryQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.Name => ValueProviderBuilder.provideUniqueString('Test Quote'),
                Quote.Status => QuoteHelper.QUOTE_STATUS_DRAFT,
                Quote.Start_Date__c => Date.today(),
                Quote.End_Date__c => Date.today().addDays(2),
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.Pricebook2Id => Test.getStandardPricebookId(),
                Quote.isPrimary__c => true,
                Quote.Enabled_LBO__c => false,
                Quote.Package_Info__c => '[{"id":"65","version":"1",' +
                    '"packageInfo":{"catalogId":"65","version":"1",' +
                    '"name":"Office Standard 1/2/20/100+ Lines - 2021/2022/2023/2024",' +
                    '"displayName":"RingCentral Office Standard"},' +
                    '"productName":"Office","duration":"Monthly",' +
                    '"edition":{"id":1,"name":"Standard"},"contract":null,' +
                    '"offerType":"Regular","poc":null,"globalPackageLimits":' +
                    '[{"value":"6000","code":"MONTHLY_AMOUNT_LIMIT",' +
                    '"name":"Monthly money amount limit",' +
                    '"type":"Amount","scope":"BillingCycle","transactionType":"Any",' +
                    '"target":"Global","exclusions":[{"target":"LicenseCategoryId","targetId":"AP"}],' +
                    '"override":false}],"permissions":null}]'
            })
            .build()
            .getRecord();
    }

    /* UsedQuantity */
    @isTest
    static void verifyAddAndGetQuantityWorksCorrectForUsedQuantity() {
      SubscriberInfoBuilder.UsedQuantity uq = new SubscriberInfoBuilder.UsedQuantity();

      ValueProvider.DummyIdProvider vp = new ValueProvider.DummyIdProvider(QuoteLineItem.SObjectType);

      Id qliParentId = (Id) vp.getValue();
      Id qliChild1Id = (Id) vp.getValue();
      Id qliChild2Id = (Id) vp.getValue();
      Id ac1Id = (Id) vp.getValue();
      Id ac2Id = (Id) vp.getValue();

      AssignmentLineItem__c[] alis2 = new SObjectBuilder(AssignmentLineItem__c.sObjectType)
          .quantity(2)
          .setFields(new Map<SObjectField, Object>{
              AssignmentLineItem__c.Parent__c => qliParentId,
              AssignmentLineItem__c.Child__c => ValueProviderBuilder.provideList(
                  new List<Id>{qliChild1Id, qliChild2Id}
              ),
              AssignmentLineItem__c.AreaCode__c => ac1Id,
              AssignmentLineItem__c.Quantity__c => ValueProviderBuilder.provideList(
                  new List<Integer>{4, 7}
              )
          })
          .build()
          .getRecords();

      for (AssignmentLineItem__c ali : alis2) {
        uq.add(ali);
      }

      uq.add(null);

      System.assertEquals(11, uq.getQuantity(qliParentId, ac1Id), 'Should return correct qty for QLI involved in Assignment');
      System.assertEquals(4, uq.getQuantity(qliChild1Id, ac1Id), 'Should return correct qty for QLI involved in Assignment');
      System.assertEquals(7, uq.getQuantity(qliChild2Id, ac1Id), 'Should return correct qty for QLI involved in Assignment');

      System.assertEquals(0, uq.getQuantity(null, null), 'Should return 0 if QLI is undefined');
      System.assertEquals(0, uq.getQuantity(qliParentId, null), 'Should return 0 if AreaCode is undefined');
      System.assertEquals(0, uq.getQuantity(qliParentId, ac2Id), 'Should return 0 if QLI is not involved in Assignment');
    }

    /* Assignments */
    @isTest
    static void verifyGetAssignments() {
        createTestData();

        SubscriberInfoBuilder.AssignmentData[] assignmnts = SubscriberInfoBuilder.getAssignments(qlis, aclis, alis, qliMap, acMap, false, Product2Helper.PRODUCT_OFFICE, null, null, false);

        System.assertEquals(9, assignmnts.size(), 'Should be correct splitted');

        List<Map<String, Object>> expextation =  new List<Map<String, Object>>{
            new Map<String, Object>{'quantity' => 5, 'parentId' => DL_UNL, 'childId' => HD, 'areaCode' => '833', 'root' => 'DL', 'path' => 'DL:DL-UNL', 'code' => 'DL-UNL'},
            new Map<String, Object>{'quantity' => 2, 'parentId' => DL_UNL, 'childId' => HD, 'areaCode' => '866', 'root' => 'DL', 'path' => 'DL:DL-UNL', 'code' => 'DL-UNL'},
            new Map<String, Object>{'quantity' => 1, 'parentId' => MLN, 'childId' => null, 'areaCode' => '800', 'root' => 'SC', 'path' => 'SC:MLN', 'code' => 'MLN'},
            new Map<String, Object>{'quantity' => 4, 'parentId' => HD, 'childId' => null, 'areaCode' => '866', 'root' => 'HD', 'path' => 'HD', 'code' => 'HD'},
            new Map<String, Object>{'quantity' => 1, 'parentId' => SC, 'childId' => null, 'areaCode' => null, 'root' => 'SC', 'path' => 'SC', 'code' => 'SC'},
            new Map<String, Object>{'quantity' => 1, 'parentId' => VF, 'childId' => null, 'areaCode' => null, 'root' => 'SC', 'path' => 'SC:VF', 'code' => 'VF'},
            new Map<String, Object>{'quantity' => 11, 'parentId' => DL, 'childId' => null, 'areaCode' => null, 'root' => 'DL', 'path' => 'DL', 'code' => 'DL'},
            new Map<String, Object>{'quantity' => 11, 'parentId' => E911, 'childId' => null, 'areaCode' => null, 'root' => 'DL', 'path' => 'DL:E911', 'code' => 'E911'},
            new Map<String, Object>{'quantity' => 11, 'parentId' => CRF, 'childId' => null, 'areaCode' => null, 'root' => 'DL', 'path' => 'DL:CRF', 'code' => 'CRF'}
        };

        Integer i = 0;
        for (SubscriberInfoBuilder.AssignmentData ad : assignmnts) {
            Id childId = ad.child != null ? ad.child.Id : null;
            String areaCode = ad.areaCode != null ? ad.areaCode.areaCode : null;
            System.assertEquals((Decimal) expextation.get(i).get('quantity'), ad.quantity, 'Should be correct (idx=' + i + ')');
            System.assertEquals((Id) expextation.get(i).get('parentId'), ad.parent.Id, 'Should be correct (idx=' + i + ')');
            System.assertEquals((Id) expextation.get(i).get('childId'), childId, 'Should be correct (idx=' + i + ')');
            System.assertEquals((String) expextation.get(i).get('areaCode'), areaCode, 'Should be correct (idx=' + i + ')');
            System.assertEquals((String) expextation.get(i).get('root'), ad.categoryRoot, 'Should be correct (idx=' + i + ')');
            System.assertEquals((String) expextation.get(i).get('path'), ad.categoryPath, 'Should be correct (idx=' + i + ')');
            System.assertEquals((String) expextation.get(i).get('code'), ad.categoryCode, 'Should be correct (idx=' + i + ')');
            i++;
        }
    }

    @isTest
    static void verifySubscriberInfo() {
        createTestData();

        User user = (User) new SObjectBuilder(User.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                User.FirstName => 'John',
                User.LastName => 'Good'
            })
            .create()
            .getRecord();

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Id => ValueProviderBuilder.provideDummyId(Account.SObjectType),
                Account.Name => 'Test Account',
                Account.BillingCity => 'TestCity',
                Account.BillingStreet => 'TestStreet',
                Account.BillingState => 'NY',
                Account.BillingPostalCode => '123890',
                Account.BillingCountry => 'United States'
            })
            .build()
            .getRecord();

        Contact contact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Contact.Id => ValueProviderBuilder.provideDummyId(Account.SObjectType),
                Contact.FirstName => 'Test first name',
                Contact.LastName => 'Test last name',
                Contact.Email => 'Test email',
                Contact.Phone => 'Test Phone'
            })
            .build()
            .getRecord();

        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Quote.Id => ValueProviderBuilder.provideDummyId(Quote.SObjectType),
                Quote.Package_Info__c => NGBSTestDataGenerator.generateQuotePackageInfo()
            })
            .build()
            .getRecord();

        SubscriberInfoBuilder.AssignmentData[] assignmnts = SubscriberInfoBuilder.getAssignments(qlis, aclis, alis, qliMap, acMap, false, Product2Helper.PRODUCT_OFFICE, null, null, false);

        SubscriberInfoBuilder infoBuilder = new SubscriberInfoBuilder(user, acc, contact, qt, assignmnts, new Map<Id, List<CustomAddressAssignments__c>>(), null, false);
        String sInfoStr = EncodingUtil.base64Decode(
            infoBuilder.getValue()
        ).toString();

        SubscriberInfoBuilder.SubscriberInfo sInfo =
            (SubscriberInfoBuilder.SubscriberInfo)
                JSON.deserialize(sInfoStr, SubscriberInfoBuilder.SubscriberInfo.class);

        /* salesAgentInfo */
        System.assertEquals(user.Id, sInfo.salesAgentInfo.salesAgentId);
        System.assertEquals(user.Name, sInfo.salesAgentInfo.name);

        /* contactInfo */
        System.assertEquals(contact.FirstName, sInfo.contactInfo.firstName);
        System.assertEquals(contact.LastName, sInfo.contactInfo.lastName);
        System.assertEquals(contact.Email, sInfo.contactInfo.email);
        System.assertEquals(contact.Phone, sInfo.contactInfo.contactPhone);
        System.assertEquals(acc.Name, sInfo.contactInfo.companyName);

        List<Map<String, Object>> expectation = new List<Map<String, Object>>{
            new Map<String, Object>{'licenseCategory' => 'SC', 'size' => 3, 'licenses' => new List<Map<String, Object>>{
                new Map<String, Object>{'catalogId' => 'LC_MLN_1', 'qty' => 1, 'areaCode' => '800'},
                new Map<String, Object>{'catalogId' => 'LC_SC_1', 'qty' => 1},
                new Map<String, Object>{'catalogId' => 'LC_VF_1', 'qty' => 1}
            }},
            new Map<String, Object>{'licenseCategory' => 'DL', 'size' => 2, 'licenses' => new List<Map<String, Object>>{
                new Map<String, Object>{'catalogId' => 'LC_DL-UNL_1', 'qty' => 5, 'areaCode' => '833'},
                new Map<String, Object>{'catalogId' => 'LC_DL-UNL_1', 'qty' => 2, 'areaCode' => '866'}
            }},
            new Map<String, Object>{'licenseCategory' => 'HD', 'size' => 1, 'licenses' => new List<Map<String, Object>>{
                new Map<String, Object>{'catalogId' => 'LC_HD_1', 'qty' => 4, 'areaCode' => '866'}
            }}
        };

        /* LicenseCategories */
        System.assertEquals(3, sInfo.LicenseCategories.size());

        for (Integer i = 0; i < sInfo.LicenseCategories.size(); i++) {
            SubscriberInfoBuilder.LicenseCategoryRequest lcr = sInfo.LicenseCategories.get(i);
            System.assertEquals((String) expectation.get(i).get('licenseCategory'), lcr.licenseCategory);
            System.assertEquals((Integer) expectation.get(i).get('size'), lcr.licenses.size());

            List<Map<String, Object>> expectationInner = (List<Map<String, Object>>) expectation.get(i).get('licenses');
            for (Integer k = 0; k < lcr.licenses.size(); k++) {
                SubscriberInfoBuilder.LicenseRequest lc = lcr.licenses.get(k);
                if (expectationInner.size() == 0) {
                    continue;
                }
                Map<String, Object> exInner = expectationInner.get(k);
                System.assertEquals((String) exInner.get('catalogId'), lc.catalogId);
                System.assertEquals((Integer) exInner.get('qty'), lc.qty);

                if (lc.phoneNumberInfo != null) {
                    System.assertEquals((String) exInner.get('areaCode'), lc.phoneNumberInfo.get(0).areaCode);
                }
            }
        }

        /* billingAddress */
        System.assertEquals(contact.FirstName, sInfo.billingAddress.firstName);
        System.assertEquals(contact.LastName, sInfo.billingAddress.lastName);
        System.assertEquals(acc.BillingCity, sInfo.billingAddress.city);
        System.assertEquals(acc.BillingStreet, sInfo.billingAddress.addressLine1);
        System.assertEquals(acc.BillingState, sInfo.billingAddress.state);
        System.assertEquals(acc.BillingPostalCode, sInfo.billingAddress.zipCode);
        System.assert(!String.isBlank(sInfo.billingAddress.country));
    }

    @isTest
    static void verifyAssignmentsFilteredByLimits() {
        createTestData();

        new SObjectBuilder(Funnel_Limits__c.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Funnel_Limits__c.Name => 'DL-UNL',
                Funnel_Limits__c.Categories__c => 'DL-UNL',
                Funnel_Limits__c.Quantity__c => 1,
                Funnel_Limits__c.Manual_Upsell__c => true
            })
            .create();

        Map<String, SubscriberInfoBuilder.AssignmentData[]> result = SubscriberInfoBuilder.getAssignmentsFilterByLimits(qlis, aclis, alis, qliMap, acMap, primaryQuote, null, null, '', false);

        System.assertEquals(0, result.get('manual').size());
        System.assertEquals(9, result.get('auto').size());

        Integer i;
        List<Map<String, Object>> expextation;

        expextation = new List<Map<String, Object>>{
            new Map<String, Object>{'quantity' => 5, 'parentId' => DL_UNL, 'childId' => HD, 'areaCode' => '833', 'root' => 'DL', 'path' => 'DL:DL-UNL', 'code' => 'DL-UNL'},
            new Map<String, Object>{'quantity' => 2, 'parentId' => DL_UNL, 'childId' => HD, 'areaCode' => '866', 'root' => 'DL', 'path' => 'DL:DL-UNL', 'code' => 'DL-UNL'},
            new Map<String, Object>{'quantity' => 1, 'parentId' => MLN, 'childId' => null, 'areaCode' => '800', 'root' => 'SC', 'path' => 'SC:MLN', 'code' => 'MLN'},
            new Map<String, Object>{'quantity' => 4, 'parentId' => HD, 'childId' => null, 'areaCode' => '866', 'root' => 'HD', 'path' => 'HD', 'code' => 'HD'},
            new Map<String, Object>{'quantity' => 1, 'parentId' => SC, 'childId' => null, 'areaCode' => null, 'root' => 'SC', 'path' => 'SC', 'code' => 'SC'},
            new Map<String, Object>{'quantity' => 1, 'parentId' => VF, 'childId' => null, 'areaCode' => null, 'root' => 'SC', 'path' => 'SC:VF', 'code' => 'VF'},
            new Map<String, Object>{'quantity' => 11, 'parentId' => DL, 'childId' => null, 'areaCode' => null, 'root' => 'DL', 'path' => 'DL', 'code' => 'DL'},
            new Map<String, Object>{'quantity' => 11, 'parentId' => E911, 'childId' => null, 'areaCode' => null, 'root' => 'DL', 'path' => 'DL:E911', 'code' => 'E911'},
            new Map<String, Object>{'quantity' => 11, 'parentId' => CRF, 'childId' => null, 'areaCode' => null, 'root' => 'DL', 'path' => 'DL:CRF', 'code' => 'CRF'}
        };

        i = 0;
        for (SubscriberInfoBuilder.AssignmentData ad : result.get('auto')) {
            Id childId = ad.child != null ? ad.child.Id : null;
            String areaCode = ad.areaCode != null ? ad.areaCode.areaCode : null;
            System.assertEquals((Decimal) expextation.get(i).get('quantity'), ad.quantity, 'Should be correct (idx=' + i + ')');
            System.assertEquals((Id) expextation.get(i).get('parentId'), ad.parent.Id, 'Should be correct (idx=' + i + ')');
            System.assertEquals((Id) expextation.get(i).get('childId'), childId, 'Should be correct (idx=' + i + ')');
            System.assertEquals((String) expextation.get(i).get('areaCode'), areaCode, 'Should be correct (idx=' + i + ')');
            System.assertEquals((String) expextation.get(i).get('root'), ad.categoryRoot, 'Should be correct (idx=' + i + ')');
            System.assertEquals((String) expextation.get(i).get('path'), ad.categoryPath, 'Should be correct (idx=' + i + ')');
            System.assertEquals((String) expextation.get(i).get('code'), ad.categoryCode, 'Should be correct (idx=' + i + ')');
            i++;
        }
    }

    @isTest
    static void verifyAssignmentsFilteredByLimitsWithLBO() {
        createTestData();

        new SObjectBuilder(Funnel_Limits__c.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Funnel_Limits__c.Name => 'DL-UNL',
                Funnel_Limits__c.Categories__c => 'DL-UNL',
                Funnel_Limits__c.Quantity__c => 0,
                Funnel_Limits__c.Manual_Upsell__c => true,
                Funnel_Limits__c.Only_LBO__c => true
            })
            .create();

        primaryQuote.Enabled_LBO__c = true;

        Map<String, SubscriberInfoBuilder.AssignmentData[]> result = SubscriberInfoBuilder.getAssignmentsFilterByLimits(qlis, aclis, alis, qliMap, acMap, primaryQuote, null, null, '', false);
        system.debug(result);
        System.assertEquals(0, result.get('manual').size());
        System.assertEquals(9, result.get('auto').size());
    }

    @isTest
    static void verifyBillingAddressLogicForPhoenixWTTaxSettings() {
        createTestData();

        User user = (User) new SObjectBuilder(User.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                User.FirstName => 'John',
                User.LastName => 'Good'
            })
            .create()
            .getRecord();

        new SObjectBuilder(Feature_Toggle__c.sObjectType)
            .setFields(new Map<SObjectField, Object>{
            Feature_Toggle__c.Enable_Account_Based_Tax_Exemption__c => true})
            .create();

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => 'Test Account',
                Account.BillingStreet => '20 Davis Drive',
                Account.BillingCity => 'Belmont',
                Account.BillingState => 'CA',
                Account.BillingPostalCode => '94002',
                Account.BillingCountry => 'USA',
                Account.VATNumber__c => '112312341'
            })
            .create()
            .getRecord();

        Contact contact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Contact.AccountId => acc.Id,
                Contact.FirstName => 'Test first name',
                Contact.LastName => 'Test last name',
                Contact.Email => 'test@example.com',
                Contact.Phone => '1234567'
            })
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.Name => 'Test1',
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL,
                Opportunity.Tier_Name__c => 'Meetings',
                Opportunity.Type => OpportunityHelper.OPPORTUNITY_TYPE_EX_BUSINESS,
                Opportunity.RecordTypeId => OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY,
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                Opportunity.CloseDate => system.today().addMonths(1)
            })
            .create()
            .getRecord();

        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.Name => ValueProviderBuilder.provideUniqueString('Test Billing Quote 1'),
                Quote.OpportunityId => opp.Id,
                Quote.Package_Info__c => '[{"id":"100","version":"1","packageInfo":{"catalogId":"100","version":"1"}}]',
                Quote.Status => QuoteHelper.QUOTE_STATUS_DRAFT,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.QuoteType__c => QuoteHelper.QUOTE_TYPE_AGREEMENT,
                Quote.isPrimary__c => true
            })
            .create()
            .getRecord();

        SubscriberInfoBuilder.AssignmentData[] assignments = SubscriberInfoBuilder.getAssignments(qlis, aclis, alis, qliMap, acMap, true, Product2Helper.PRODUCT_OFFICE, null, null, false);

        SubscriberInfoBuilder infoBuilder = new SubscriberInfoBuilder(user, acc, contact, qt, assignments, new Map<Id, List<CustomAddressAssignments__c>>(), null, false);
        String sInfoStr = EncodingUtil.base64Decode(
            infoBuilder.getValue()
        ).toString();

        SubscriberInfoBuilder.SubscriberInfo sInfo =
            (SubscriberInfoBuilder.SubscriberInfo)
                JSON.deserialize(sInfoStr, SubscriberInfoBuilder.SubscriberInfo.class);

        System.assertNotEquals(null, sInfo.billingAddress, 'Billing address must be not null');
        System.assertEquals(sInfo.billingAddress.country, 'USA', 'Country name must be USA');
        System.assertEquals(sInfo.billingAddress.state, acc.BillingState, 'State must be same as in account');
        System.assertEquals(sInfo.billingAddress.city, acc.BillingCity, 'City must be same as in account');
        System.assertEquals(sInfo.billingAddress.addressLine1, acc.BillingStreet, 'Street must be same as in account');
        System.assertEquals(sInfo.billingAddress.addressLine2, null, 'Second address line must be same null');
        System.assertEquals(sInfo.billingAddress.zipCode, acc.BillingPostalCode, 'ZipCode must be same as in account');
        System.assertNotEquals(sInfo.billingAddress.taxSettings, null, 'Taxes must be not null');
        System.assertEquals(sInfo.billingAddress.taxSettings.VATNumber, acc.VATNumber__c, 'VAT number must be from Account');
        System.assertEquals(sInfo.billingAddress.taxSettings.GSTNumber, null, 'GST number must be null if VAT not null');
        System.assertEquals(sInfo.billingAddress.contactPhone, contact.Phone, 'State must be same as contact phone');
        System.assertEquals(sInfo.billingAddress.lastName, contact.LastName, 'State must be same as contact last name');
        System.assertEquals(sInfo.billingAddress.firstName, contact.FirstName, 'State must be same as contact first name');
    }

    @isTest
    static void verifyBillingAddressLogicForPhoenixWithTaxSettings() {
        createTestData();

        User user = (User) new SObjectBuilder(User.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                User.FirstName => 'John',
                User.LastName => 'Good'
            })
            .create()
            .getRecord();

        new SObjectBuilder(Feature_Toggle__c.sObjectType)
            .setFields(new Map<SObjectField, Object>{
            Feature_Toggle__c.Enable_Account_Based_Tax_Exemption__c => true})
            .create();

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => 'Test Account',
                Account.BillingStreet => '20 Davis Drive',
                Account.BillingCity => 'Belmont',
                Account.BillingState => 'CA',
                Account.BillingPostalCode => '94002',
                Account.BillingCountry => 'USA',
                Account.VATNumber__c => '33333'
            })
            .create()
            .getRecord();

        Contact contact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Contact.AccountId => acc.Id,
                Contact.FirstName => 'Test first name',
                Contact.LastName => 'Test last name',
                Contact.Email => 'test@example.com',
                Contact.Phone => '1234567'
            })
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.Name => 'Test1',
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL,
                Opportunity.Tier_Name__c => 'Meetings',
                Opportunity.Type => OpportunityHelper.OPPORTUNITY_TYPE_EX_BUSINESS,
                Opportunity.RecordTypeId => OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY,
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                Opportunity.CloseDate => system.today().addMonths(1)
            })
            .create()
            .getRecord();

        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.Name => ValueProviderBuilder.provideUniqueString('Test Billing Quote 1'),
                Quote.OpportunityId => opp.Id,
                Quote.Package_Info__c => '[{"id":"100","version":"1","packageInfo":{"catalogId":"100","version":"1"}}]',
                Quote.Status => QuoteHelper.QUOTE_STATUS_DRAFT,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.QuoteType__c => QuoteHelper.QUOTE_TYPE_AGREEMENT,
                Quote.isPrimary__c => true
            })
            .create()
            .getRecord();
        Test.startTest();
        Approval__c app = (Approval__c) new SObjectBuilder(Approval__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Approval__c.Name => ValueProviderBuilder.provideUniqueString('Test Billing Quote 1'),
                Approval__c.Opportunity__c => opp.Id,
                Approval__c.Account__c => acc.Id,
                Approval__c.Contact__c => contact.Id,
                Approval__c.Status__c => ApprovalHelper.STATUS_NEW,
                Approval__c.VATNumber__c => '22222',
                Approval__c.RecordTypeId => ApprovalHelper.RT_ID_TAX_EXEMPT_APPROVAL,
                Approval__c.StateTaxExemption__c => ApprovalHelper.STATUS_APPROVED,
                Approval__c.CountyTaxExemption__c => ApprovalHelper.STATUS_APPROVED,
                Approval__c.LocalTaxExemption__c => ApprovalHelper.STATUS_APPROVED,
                Approval__c.FederalTaxExemption__c => ApprovalHelper.STATUS_APPROVED,
                Approval__c.SalesTaxExemption__c => ApprovalHelper.STATUS_APPROVED
            })
            .create()
            .getRecord();

        app.Status__c = ApprovalHelper.STATUS_APPROVED;
        update app;

        SubscriberInfoBuilder.AssignmentData[] assignments = SubscriberInfoBuilder.getAssignments(qlis, aclis, alis, qliMap, acMap, true, Product2Helper.PRODUCT_OFFICE, null, null, false);

        SubscriberInfoBuilder infoBuilder = new SubscriberInfoBuilder(user, acc, contact, qt, assignments, new Map<Id, List<CustomAddressAssignments__c>>(), null, false);
        String sInfoStr = EncodingUtil.base64Decode(
            infoBuilder.getValue()
        ).toString();

        SubscriberInfoBuilder.SubscriberInfo sInfo =
            (SubscriberInfoBuilder.SubscriberInfo)
                JSON.deserialize(sInfoStr, SubscriberInfoBuilder.SubscriberInfo.class);
        Test.stopTest();
        System.assertNotEquals(null, sInfo.billingAddress, 'Billing address must be not null');
        System.assertEquals(sInfo.billingAddress.country, 'USA', 'Country name must be USA');
        System.assertEquals(sInfo.billingAddress.state, acc.BillingState, 'State must be same as in account');
        System.assertEquals(sInfo.billingAddress.city, acc.BillingCity, 'City must be same as in account');
        System.assertEquals(sInfo.billingAddress.addressLine1, acc.BillingStreet, 'Street must be same as in account');
        System.assertEquals(sInfo.billingAddress.addressLine2, null, 'Second address line must be same null');
        System.assertEquals(sInfo.billingAddress.zipCode, acc.BillingPostalCode, 'ZipCode must be same as in account');
        System.assertEquals(sInfo.billingAddress.contactPhone, contact.Phone, 'State must be same as contact phone');
        System.assertEquals(sInfo.billingAddress.lastName, contact.LastName, 'State must be same as contact last name');
        System.assertEquals(sInfo.billingAddress.firstName, contact.FirstName, 'State must be same as contact first name');
        System.assertNotEquals(sInfo.billingAddress.taxSettings, null, 'Taxes must be not null');
        System.assertEquals(sInfo.billingAddress.taxSettings.stateTaxExemption, true, 'StateTaxExemption must be true');
        System.assertEquals(sInfo.billingAddress.taxSettings.federalTaxExemption, true, 'FederalTaxExemption must be true');
        System.assertEquals(sInfo.billingAddress.taxSettings.countyTaxExemption, true, 'CountyTaxExemption must be true');
        System.assertEquals(sInfo.billingAddress.taxSettings.localTaxExemption, true, 'LocalTaxExemption must be true');
        System.assertEquals(sInfo.billingAddress.taxSettings.VATExemption, false, 'VATExemption must be null');
        System.assertEquals(sInfo.billingAddress.taxSettings.SEZWOPExemption, false, 'SEZWOPExemption must be false');
        System.assertEquals(sInfo.billingAddress.taxSettings.VATNumber, app.VATNumber__c, 'VATNumber must be null');
        System.assertEquals(sInfo.billingAddress.taxSettings.salesTaxExemption, true, 'salesTaxExemption must be true');
    }

    @isTest
    static void testGetPayableContactInfo() {
        Test.startTest();
            Triggers.switchOff();

            new SObjectBuilder(Feature_Toggle__c.SObjectType)
                .setField(Feature_Toggle__c.SelectPackagesByBusinessIdentity__c, true)
                .create();

            createTestData();

            User user = (User) new SObjectBuilder(User.SObjectType)
                .setFields(new Map<SObjectField, Object>{
                    User.FirstName => 'John',
                    User.LastName => 'Good'
                })
                .create()
                .getRecord();

            Account acc = (Account) new SObjectBuilder(Account.SObjectType)
                .setFields(new Map<SObjectField, Object>{
                    Account.Name => 'Test Account',
                    Account.BillingCity => 'TestCity',
                    Account.BillingStreet => 'TestStreet',
                    Account.BillingState => 'NY',
                    Account.BillingPostalCode => '123890',
                    Account.BillingCountry => 'United States'
                })
                .create()
                .getRecord();

            Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
                .setFields(new Map<SObjectField, Object>{
                    Contact.FirstName => 'Test first name',
                    Contact.LastName => 'Test last name',
                    Contact.Email => 'Testemail@email.email',
                    Contact.Phone => 'Test Phone'
                })
                .create()
                .getRecord();

            Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
                .setFields(new Map<SObjectField, Object>{
                    Opportunity.Name => 'Test1',
                    Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL,
                    Opportunity.Tier_Name__c => OpportunityHelper.TIER_OFFICE,
                    Opportunity.Type => OpportunityHelper.OPPORTUNITY_TYPE_NEW_BUSINESS,
                    Opportunity.RecordTypeId => OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY,
                    Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                    Opportunity.CloseDate => system.today().addMonths(1)
                })
                .create()
                .getRecord();

            Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
                .setFields(new Map<SObjectField, Object>{
                    Quote.Package_Info__c => NGBSTestDataGenerator.generateQuotePackageInfo(),
                    Quote.Name => ValueProviderBuilder.provideUniqueString('Test Billing Quote'),
                    Quote.OpportunityId => opp.Id,
                    Quote.Status => QuoteHelper.QUOTE_STATUS_DRAFT,
                    Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                    Quote.QuoteType__c => QuoteHelper.QUOTE_TYPE_AGREEMENT,
                    Quote.isPrimary__c => true,
                    Quote.PaymentMethod__c => QuoteHelper.PAYMENT_METHOD_INVOICE
                })
                .create()
                .getRecord();

            SubscriberInfoBuilder.AssignmentData[] assignments = SubscriberInfoBuilder.getAssignments(qlis, aclis, alis, qliMap, acMap, true, Product2Helper.PRODUCT_OFFICE, null, null, false);
            List<AccountContactRole> accountPayableRoles = (List<AccountContactRole>) new SObjectBuilder(AccountContactRole.SObjectType)
                .setFields(new Map<SObjectField, Object> {
                    AccountContactRole.AccountId => acc.Id,
                    AccountContactRole.ContactId => con.Id,
                    AccountContactRole.Role => AccountContactRoleHelper.CONTACT_ROLE_ACCOUNT_PAYABLE
                })
                .quantity(1)
                .create()
                .getRecords();

            Approval__c app = new Approval__c(
                Name =  'Invoicing Approval',
                RecordTypeId = ApprovalHelper.RT_ID_INVOICING_REQUEST,
                Account__c = acc.Id,
                Opportunity__c = opp.Id,
                AccountPayableContact__c = con.Id,
                Status__c = ApprovalHelper.STATUS_APPROVED,
                Potential_Users__c = 1,
                Reason_Customer_is_Requesting_Invoicing__c = 'test'
                );

                insert app;
                SubscriberInfoBuilder infoBuilder = new SubscriberInfoBuilder(user, acc, con, qt, assignments, new Map<Id, List<CustomAddressAssignments__c>>(), QuoteHelper.PAYMENT_METHOD_INVOICE, false);
                String sInfoStr = EncodingUtil.base64Decode(infoBuilder.getValue()).toString();
                SubscriberInfoBuilder.SubscriberInfo sInfo =
                (SubscriberInfoBuilder.SubscriberInfo)
                    JSON.deserialize(sInfoStr, SubscriberInfoBuilder.SubscriberInfo.class);
            Triggers.switchOn();

            System.assertNotEquals(sInfo.billingAccountContactInfo, null, 'We should have billingAccountContactInfo when it is Invoice, it is Approved and there is an Account Payable Contact Role');
            System.assertEquals(sInfo.billingAccountContactInfo.firstName, con.FirstName, 'First Name should match Account Payable contact record');
            System.assertEquals(sInfo.billingAccountContactInfo.lastName, con.LastName, 'Last Name should match Account Payable contact record');
            System.assertEquals(sInfo.billingAccountContactInfo.email, con.Email.toLowercase(), 'Email should match Account Payable contact record');
            System.assertEquals(sInfo.billingAccountContactInfo.contactPhone, con.Phone, 'Phone number should match Account Payable contact record');
            System.assertEquals(sInfo.billingAccountContactInfo.companyName, acc.Name, 'Company Name should match Account name');
        Test.stopTest();
    }

    @isTest
    static void testBillingContactInfoForNonInvoice() {
        Triggers.switchOff();

        new SObjectBuilder(Feature_Toggle__c.SObjectType)
            .setField(Feature_Toggle__c.SelectPackagesByBusinessIdentity__c, true)
            .create();

        createTestData();

        User user = (User) new SObjectBuilder(User.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                User.FirstName => 'John',
                User.LastName => 'Good'
            })
            .create()
            .getRecord();

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => 'Test Account',
                Account.BillingCity => 'TestCity',
                Account.BillingStreet => 'TestStreet',
                Account.BillingState => 'NY',
                Account.BillingPostalCode => '123890',
                Account.BillingCountry => 'United States'
            })
            .create()
            .getRecord();

        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Contact.FirstName => 'Test first name',
                Contact.LastName => 'Test last name',
                Contact.Email => 'Testemail@email.email',
                Contact.Phone => 'Test Phone'
            })
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.Name => 'Test1',
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL,
                Opportunity.Tier_Name__c => OpportunityHelper.TIER_OFFICE,
                Opportunity.Type => OpportunityHelper.OPPORTUNITY_TYPE_NEW_BUSINESS,
                Opportunity.RecordTypeId => OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY,
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                Opportunity.CloseDate => system.today().addMonths(1)
            })
            .create()
            .getRecord();

        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Quote.Package_Info__c => NGBSTestDataGenerator.generateQuotePackageInfo(),
                Quote.Name => ValueProviderBuilder.provideUniqueString('Test Billing Quote'),
                Quote.OpportunityId => opp.Id,
                Quote.Status => QuoteHelper.QUOTE_STATUS_DRAFT,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.QuoteType__c => QuoteHelper.QUOTE_TYPE_AGREEMENT,
                Quote.isPrimary__c => true,
                Quote.PaymentMethod__c => QuoteHelper.PAYMENT_METHOD_CREDIT_CARD // Credit Card Payment Method
            })
            .create()
            .getRecord();

        SubscriberInfoBuilder.AssignmentData[] assignments = SubscriberInfoBuilder.getAssignments(qlis, aclis, alis, qliMap, acMap, true, Product2Helper.PRODUCT_OFFICE, null, null, false);

        List<AccountContactRole> accountPayableRoles = (List<AccountContactRole>) new SObjectBuilder(AccountContactRole.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                AccountContactRole.AccountId => acc.Id,
                AccountContactRole.ContactId => con.Id,
                AccountContactRole.Role => AccountContactRoleHelper.CONTACT_ROLE_ACCOUNT_PAYABLE
            })
            .quantity(1)
            .create()
            .getRecords();

        Approval__c app = new Approval__c(
            Name =  'Invoicing Approval',
            RecordTypeId = ApprovalHelper.RT_ID_INVOICING_REQUEST,
            Account__c = acc.Id,
            Opportunity__c = opp.Id,
            AccountPayableContact__c = con.Id,
            Status__c = ApprovalHelper.STATUS_APPROVED,
            Potential_Users__c = 1,
            Reason_Customer_is_Requesting_Invoicing__c = 'test'
        );

        Test.startTest();
            insert app;
            SubscriberInfoBuilder infoBuilder = new SubscriberInfoBuilder(user, acc, con, qt, assignments, new Map<Id, List<CustomAddressAssignments__c>>(), QuoteHelper.PAYMENT_METHOD_CREDIT_CARD, false);
            String sInfoStr = EncodingUtil.base64Decode(infoBuilder.getValue()).toString();
            SubscriberInfoBuilder.SubscriberInfo sInfo =
            (SubscriberInfoBuilder.SubscriberInfo)
                JSON.deserialize(sInfoStr, SubscriberInfoBuilder.SubscriberInfo.class);
        Test.stopTest();
        Triggers.switchOn();

        System.assertEquals(sInfo.billingAccountContactInfo, null, 'Should be no billingAccountContactInfo when Quote record has non-Invoice payment type');
    }

    @isTest
    static void testBillingContactInfoWithoutApproval() {
        Triggers.switchOff();

        new SObjectBuilder(Feature_Toggle__c.SObjectType)
            .setField(Feature_Toggle__c.SelectPackagesByBusinessIdentity__c, true)
            .create();

        createTestData();

        User user = (User) new SObjectBuilder(User.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                User.FirstName => 'John',
                User.LastName => 'Good'
            })
            .create()
            .getRecord();

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => 'Test Account',
                Account.BillingCity => 'TestCity',
                Account.BillingStreet => 'TestStreet',
                Account.BillingState => 'NY',
                Account.BillingPostalCode => '123890',
                Account.BillingCountry => 'United States'
            })
            .create()
            .getRecord();

        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Contact.FirstName => 'Test first name',
                Contact.LastName => 'Test last name',
                Contact.Email => 'Testemail@email.email',
                Contact.Phone => 'Test Phone'
            })
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.Name => 'Test1',
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL,
                Opportunity.Tier_Name__c => OpportunityHelper.TIER_OFFICE,
                Opportunity.Type => OpportunityHelper.OPPORTUNITY_TYPE_NEW_BUSINESS,
                Opportunity.RecordTypeId => OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY,
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                Opportunity.CloseDate => system.today().addMonths(1)
            })
            .create()
            .getRecord();

        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Quote.Package_Info__c => NGBSTestDataGenerator.generateQuotePackageInfo(),
                Quote.Name => ValueProviderBuilder.provideUniqueString('Test Billing Quote'),
                Quote.OpportunityId => opp.Id,
                Quote.Status => QuoteHelper.QUOTE_STATUS_DRAFT,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.QuoteType__c => QuoteHelper.QUOTE_TYPE_AGREEMENT,
                Quote.isPrimary__c => true,
                Quote.PaymentMethod__c => QuoteHelper.PAYMENT_METHOD_INVOICE
            })
            .create()
            .getRecord();

        SubscriberInfoBuilder.AssignmentData[] assignments = SubscriberInfoBuilder.getAssignments(qlis, aclis, alis, qliMap, acMap, true, Product2Helper.PRODUCT_OFFICE, null, null, false);

        List<AccountContactRole> accountPayableRoles = (List<AccountContactRole>) new SObjectBuilder(AccountContactRole.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                AccountContactRole.AccountId => acc.Id,
                AccountContactRole.ContactId => con.Id,
                AccountContactRole.Role => AccountContactRoleHelper.CONTACT_ROLE_ACCOUNT_PAYABLE
            })
            .quantity(1)
            .create()
            .getRecords();

        Approval__c app = new Approval__c(
            Name =  'Invoicing Approval',
            RecordTypeId = ApprovalHelper.RT_ID_INVOICING_REQUEST,
            Account__c = acc.Id,
            Opportunity__c = opp.Id,
            AccountPayableContact__c = null, // no payable contact
            Status__c = ApprovalHelper.STATUS_APPROVED,
            Potential_Users__c = 1,
            Reason_Customer_is_Requesting_Invoicing__c = 'test'
        );

        Test.startTest();
            insert app;
            SubscriberInfoBuilder infoBuilder = new SubscriberInfoBuilder(user, acc, con, qt, assignments, new Map<Id, List<CustomAddressAssignments__c>>(),  QuoteHelper.PAYMENT_METHOD_INVOICE, false);
            String sInfoStr = EncodingUtil.base64Decode(infoBuilder.getValue()).toString();
            SubscriberInfoBuilder.SubscriberInfo sInfo =
            (SubscriberInfoBuilder.SubscriberInfo)
                JSON.deserialize(sInfoStr, SubscriberInfoBuilder.SubscriberInfo.class);
        Test.stopTest();
        Triggers.switchOn();

        System.assertEquals(sInfo.billingAccountContactInfo, null, 'Should be no billingAccountContactInfo when it is Invoice payment type and we do not have Account Payable Role');
    }

    @isTest
    static void testBillingContactInfoWithoutPayableContact() {
        Triggers.switchOff();

        new SObjectBuilder(Feature_Toggle__c.SObjectType)
            .setField(Feature_Toggle__c.SelectPackagesByBusinessIdentity__c, true)
            .create();

        createTestData();

        User user = (User) new SObjectBuilder(User.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                User.FirstName => 'John',
                User.LastName => 'Good'
            })
            .create()
            .getRecord();

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => 'Test Account',
                Account.BillingCity => 'TestCity',
                Account.BillingStreet => 'TestStreet',
                Account.BillingState => 'NY',
                Account.BillingPostalCode => '123890',
                Account.BillingCountry => 'United States'
            })
            .create()
            .getRecord();

        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Contact.FirstName => 'Test first name',
                Contact.LastName => 'Test last name',
                Contact.Email => 'Testemail@email.email',
                Contact.Phone => 'Test Phone'
            })
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.Name => 'Test1',
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL,
                Opportunity.Tier_Name__c => OpportunityHelper.TIER_OFFICE,
                Opportunity.Type => OpportunityHelper.OPPORTUNITY_TYPE_NEW_BUSINESS,
                Opportunity.RecordTypeId => OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY,
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                Opportunity.CloseDate => system.today().addMonths(1)
            })
            .create()
            .getRecord();

        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Quote.Package_Info__c => NGBSTestDataGenerator.generateQuotePackageInfo(),
                Quote.Name => ValueProviderBuilder.provideUniqueString('Test Billing Quote'),
                Quote.OpportunityId => opp.Id,
                Quote.Status => QuoteHelper.QUOTE_STATUS_DRAFT,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.QuoteType__c => QuoteHelper.QUOTE_TYPE_AGREEMENT,
                Quote.isPrimary__c => true,
                Quote.PaymentMethod__c => QuoteHelper.PAYMENT_METHOD_INVOICE
            })
            .create()
            .getRecord();

        SubscriberInfoBuilder.AssignmentData[] assignments = SubscriberInfoBuilder.getAssignments(qlis, aclis, alis, qliMap, acMap, true, Product2Helper.PRODUCT_OFFICE, null, null, false);

        List<AccountContactRole> accountPayableRoles = (List<AccountContactRole>) new SObjectBuilder(AccountContactRole.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                AccountContactRole.AccountId => acc.Id,
                AccountContactRole.ContactId => con.Id,
                AccountContactRole.Role => AccountContactRoleHelper.CONTACT_ROLE_ACCOUNT_PAYABLE
            })
            .quantity(1)
            .create()
            .getRecords();

        Approval__c app = new Approval__c(
            Name =  'Invoicing Approval',
            RecordTypeId = ApprovalHelper.RT_ID_INVOICING_REQUEST,
            Account__c = acc.Id,
            Opportunity__c = opp.Id,
            AccountPayableContact__c = con.Id,
            Status__c = ApprovalHelper.STATUS_NEW,
            Potential_Users__c = 1,
            Reason_Customer_is_Requesting_Invoicing__c = 'test'
        ); // not approved

        Test.startTest();
            insert app;
            SubscriberInfoBuilder infoBuilder = new SubscriberInfoBuilder(user, acc, con, qt, assignments, new Map<Id, List<CustomAddressAssignments__c>>(), QuoteHelper.PAYMENT_METHOD_INVOICE, false);
            String sInfoStr = EncodingUtil.base64Decode(infoBuilder.getValue()).toString();
            SubscriberInfoBuilder.SubscriberInfo sInfo =
            (SubscriberInfoBuilder.SubscriberInfo)
                JSON.deserialize(sInfoStr, SubscriberInfoBuilder.SubscriberInfo.class);
        Test.stopTest();
        Triggers.switchOn();

        System.assertEquals(sInfo.billingAccountContactInfo, null, 'Should be no billingAccountContactInfo when it is Invoice payment type and we do not have an Approval');
    }

    @isTest
    static void testPayableContactInfoWholesale() {
        Test.startTest();
            Triggers.switchOff();

            new SObjectBuilder(Feature_Toggle__c.SObjectType)
                .setField(Feature_Toggle__c.SelectPackagesByBusinessIdentity__c, true)
                .create();

            createTestData();

            User user = (User) new SObjectBuilder(User.SObjectType)
                .setFields(new Map<SObjectField, Object>{
                    User.FirstName => 'John',
                    User.LastName => 'Good'
                })
                .create()
                .getRecord();

            Account acc = (Account) new SObjectBuilder(Account.SObjectType)
                .setFields(new Map<SObjectField, Object>{
                    Account.Name => 'Test Account',
                    Account.BillingCity => 'TestCity',
                    Account.BillingStreet => 'TestStreet',
                    Account.BillingState => 'NY',
                    Account.BillingPostalCode => '123890',
                    Account.BillingCountry => 'United States',
                    Account.Partner_ID__c => '543',
                    Account.Partner_Type__c => AccountHelper.ACCOUNT_PARTNER_WHOLESALE
                })
                .create()
                .getRecord();

            Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
                .setFields(new Map<SObjectField, Object>{
                    Contact.FirstName => 'Test first name',
                    Contact.LastName => 'Test last name',
                    Contact.Email => 'Testemail@email.email',
                    Contact.Phone => 'Test Phone'
                })
                .create()
                .getRecord();

            Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
                .setFields(new Map<SObjectField, Object>{
                    Opportunity.Name => 'Test1',
                    Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL,
                    Opportunity.Tier_Name__c => OpportunityHelper.TIER_OFFICE,
                    Opportunity.Type => OpportunityHelper.OPPORTUNITY_TYPE_NEW_BUSINESS,
                    Opportunity.RecordTypeId => OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY,
                    Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                    Opportunity.CloseDate => system.today().addMonths(1)
                })
                .create()
                .getRecord();

            Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
                .setFields(new Map<SObjectField, Object>{
                    Quote.Package_Info__c => NGBSTestDataGenerator.generateQuotePackageInfo(),
                    Quote.Name => ValueProviderBuilder.provideUniqueString('Test Billing Quote'),
                    Quote.OpportunityId => opp.Id,
                    Quote.Status => QuoteHelper.QUOTE_STATUS_DRAFT,
                    Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                    Quote.QuoteType__c => QuoteHelper.QUOTE_TYPE_AGREEMENT,
                    Quote.isPrimary__c => true,
                    Quote.PaymentMethod__c => QuoteHelper.PAYMENT_METHOD_INVOICE
                })
                .create()
                .getRecord();

            SubscriberInfoBuilder.AssignmentData[] assignments = SubscriberInfoBuilder.getAssignments(qlis, aclis, alis, qliMap, acMap, true, Product2Helper.PRODUCT_OFFICE, null, null, false);

            List<AccountContactRole> accountPayableRoles = (List<AccountContactRole>) new SObjectBuilder(AccountContactRole.SObjectType)
                .setFields(new Map<SObjectField, Object> {
                    AccountContactRole.AccountId => acc.Id,
                    AccountContactRole.ContactId => con.Id,
                    AccountContactRole.Role => AccountContactRoleHelper.CONTACT_ROLE_ACCOUNT_PAYABLE
                })
                .quantity(1)
                .create()
                .getRecords();

            Approval__c app = new Approval__c(
                Name =  'Wholesale Approval',
                RecordTypeId = ApprovalHelper.RT_ID_INVOICE_WHOLESALE_REQUEST,
                Account__c = acc.Id,
                Opportunity__c = opp.Id,
                AccountPayableContact__c = con.Id,
                Status__c = ApprovalHelper.STATUS_APPROVED);

                insert app;
                SubscriberInfoBuilder infoBuilder = new SubscriberInfoBuilder(user, acc, con, qt, assignments, new Map<Id, List<CustomAddressAssignments__c>>(), QuoteHelper.PAYMENT_METHOD_WHOLESALE, false);
                String sInfoStr = EncodingUtil.base64Decode(infoBuilder.getValue()).toString();
                SubscriberInfoBuilder.SubscriberInfo sInfo =
                (SubscriberInfoBuilder.SubscriberInfo)
                    JSON.deserialize(sInfoStr, SubscriberInfoBuilder.SubscriberInfo.class);
            Triggers.switchOn();

            System.assertNotEquals(sInfo.billingAccountContactInfo, null, 'We should have billingAccountContactInfo when it is Invoice, it is Approved and there is an Account Payable Contact Role');
            System.assertEquals(sInfo.billingAccountContactInfo.firstName, con.FirstName, 'First Name should match Account Payable contact record');
            System.assertEquals(sInfo.billingAccountContactInfo.lastName, con.LastName, 'Last Name should match Account Payable contact record');
            System.assertEquals(sInfo.billingAccountContactInfo.email, con.Email.toLowercase(), 'Email should match Account Payable contact record');
            System.assertEquals(sInfo.billingAccountContactInfo.contactPhone, con.Phone, 'Phone number should match Account Payable contact record');
            System.assertEquals(sInfo.billingAccountContactInfo.companyName, acc.Name, 'Company Name should match Account name');
        Test.stopTest();
    }

    // @isTest
    // static void verifyBillingAddressLogicForIndianTaxSettings() {
    //     createTestData();

    //     Test.startTest();
    //     User user = (User) new SObjectBuilder(User.SObjectType)
    //         .setFields(new Map<SObjectField, Object>{
    //             User.FirstName => 'John',
    //             User.LastName => 'Good'
    //         })
    //         .create()
    //         .getRecord();

    //     new SObjectBuilder(Feature_Toggle__c.sObjectType)
    //         .setFields(new Map<SObjectField, Object>{
    //         Feature_Toggle__c.Enable_Account_Based_Tax_Exemption__c => true})
    //         .create();

    //     Triggers.switchOff();
    //     Account acc = (Account) new SObjectBuilder(Account.SObjectType)
    //         .setFields(new Map<SObjectField, Object>{
    //             Account.Name => 'Test Account',
    //             Account.BillingStreet => '20 Davis Drive',
    //             Account.BillingCity => 'Belmont',
    //             Account.BillingState => 'CA',
    //             Account.BillingPostalCode => '94002',
    //             Account.BillingCountry => 'India',
    //             Account.VATNumber__c => '33333'
    //         })
    //         .create()
    //         .getRecord();

    //     Contact contact = (Contact) new SObjectBuilder(Contact.SObjectType)
    //         .setFields(new Map<SObjectField, Object>{
    //             Contact.AccountId => acc.Id,
    //             Contact.FirstName => 'Test first name',
    //             Contact.LastName => 'Test last name',
    //             Contact.Email => 'test@example.com',
    //             Contact.Phone => '1234567'
    //         })
    //         .create()
    //         .getRecord();

    //     Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
    //         .setFields(new Map<SObjectField, Object>{
    //             Opportunity.Name => 'Test1',
    //             Opportunity.Tier_Name__c => 'Office',
    //             Opportunity.Type => OpportunityHelper.OPPORTUNITY_TYPE_EX_BUSINESS,
    //             Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
    //             Opportunity.CloseDate => system.today().addMonths(1),
    //             Opportunity.CurrencyIsoCode => 'INR',
    //             Opportunity.RecordTypeId => OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY,
    //             Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL_EU,
    //             Opportunity.AccountId => acc.Id
    //         })
    //         .create()
    //         .getRecord();

    //     Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
    //         .setFields(new Map<SObjectField, Object> {
    //             Quote.Name => ValueProviderBuilder.provideUniqueString('Test Billing Quote 1'),
    //             Quote.OpportunityId => opp.Id,
    //             Quote.Package_Info__c => '[{"id":"100","version":"1","packageInfo":{"catalogId":"100","version":"1"}}]',
    //             Quote.Status => QuoteHelper.QUOTE_STATUS_DRAFT,
    //             Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
    //             Quote.QuoteType__c => QuoteHelper.QUOTE_TYPE_AGREEMENT,
    //             Quote.isPrimary__c => true
    //         })
    //         .create()
    //         .getRecord();

    //     Approval__c kyc = (Approval__c) new SObjectBuilder(Approval__c.sObjectType)
    //         .setFields(new Map<SObjectField, Object>{
    //             Approval__c.Name => 'KYC Approval',
    //             Approval__c.Account__c => acc.Id,
    //             Approval__c.RecordTypeId => ApprovalHelper.RT_ID_KYC_APPROVAL_REQUEST,
    //             //Approval__c.Status__c => ApprovalHelper.STATUS_APPROVED,
    //             Approval__c.StatusLastModifiedDate__c => System.today()
    //         })
    //         .create()
    //         .getRecord();

    //     kyc.GstNo__c = '22222';
    //     kyc.DateOfSignOff__c = System.today();
    //     kyc.Other__c = 'test other';
    //     kyc.NameOfTheAuthorisedSignatory__c = 'test name of Authorised Signatory';
    //     kyc.NameOfFatherOrHusband__c = 'test name of father';
    //     kyc.GenderOfAuthorisedSignatory__c = 'Male';
    //     kyc.NationalityOfAuthorisedSignatory__c = 'India';
    //     kyc.DateOfBirthOfAuthorisedSignatory__c = System.today().addYears(-20);
    //     kyc.KycFiles__c = 'file1;file2;file3;file4;file5;file6;file7;file8;file9';
    //     kyc.Status__c = ApprovalHelper.STATUS_APPROVED;
    //     kyc.PanGirNo__c = '1234567890';
    //     kyc.PinCode__c = '123456';
    //     kyc.HouseNo__c = '1';
    //     kyc.StreetAddress__c = 'Test street';
    //     kyc.Area__c = 'Test area';
    //     kyc.City__c = 'Test city';
    //     kyc.District__c = 'Test district';
    //     kyc.State__c = 'Assam';
    //     kyc.Other__c = 'Test other';
    //     update kyc;

    //     kyc = (Approval__c) new ApprovalSelector()
    //         .selectKYCRequestApprovalsForAccount(new List<Object>{new Set<Id>{acc.Id}})
    //         .executeQuery()
    //         .get(0);

    //     new SObjectBuilder(LocalSubscribedAddress__c.SObjectType)
    //         .setFields(
    //             new Map<SObjectField, Object>{
    //                 LocalSubscribedAddress__c.Approval__c => kyc.Id,
    //                 LocalSubscribedAddress__c.RecordTypeId => LocalSubscribedAddressHelper.RT_ID_REGISTERED_ADDRESS_OF_COMPANY
    //             }
    //         )
    //         .create();

    //     Approval__c app = (Approval__c) new SObjectBuilder(Approval__c.SObjectType)
    //         .setFields(new Map<SObjectField, Object> {
    //             Approval__c.Name => ValueProviderBuilder.provideUniqueString('Test Billing Quote 1'),
    //             Approval__c.Opportunity__c => opp.Id,
    //             Approval__c.Account__c => acc.Id,
    //             Approval__c.Contact__c => contact.Id,
    //             Approval__c.Status__c => ApprovalHelper.STATUS_NEW,
    //             Approval__c.GstNo__c => '22222',
    //             Approval__c.RecordTypeId => ApprovalHelper.RT_ID_TAX_EXEMPT_APPROVAL,
    //             Approval__c.SEZWOPExemption__c => ApprovalHelper.STATUS_APPROVED
    //         })
    //         .create()
    //         .getRecord();

    //     app.Status__c = ApprovalHelper.STATUS_APPROVED;
    //     update app;
    //     Triggers.switchOn();
    //     Test.stopTest();

    //     SubscriberInfoBuilder.AssignmentData[] assignments = SubscriberInfoBuilder.getAssignments(qlis, aclis, alis, qliMap, acMap, true);

    //     SubscriberInfoBuilder infoBuilder = new SubscriberInfoBuilder(user, acc, contact, qt, assignments, new Map<Id, List<CustomAddressAssignments__c>>(), null);
    //     String sInfoStr = EncodingUtil.base64Decode(
    //         infoBuilder.getValue()
    //     ).toString();

    //     SubscriberInfoBuilder.SubscriberInfo sInfo =
    //         (SubscriberInfoBuilder.SubscriberInfo)
    //             JSON.deserialize(sInfoStr, SubscriberInfoBuilder.SubscriberInfo.class);



    //     System.assertNotEquals(null, sInfo.billingAddress, 'Billing address must be not null');
    //     System.assertEquals(sInfo.billingAddress.country, 'India', 'Country name must be USA');
    //     System.assertNotEquals(sInfo.billingAddress.taxSettings, null, 'Taxes must be not null');
    //     System.assertEquals(sInfo.billingAddress.taxSettings.VATExemption, false, 'VATExemption must be false');
    //     System.assertEquals(sInfo.billingAddress.taxSettings.SEZWOPExemption, true, 'SEZWOPExemption must be true');
    //     System.assertEquals(sInfo.billingAddress.taxSettings.VATNumber, null, 'VATNumber must be null');
    //     System.assertEquals(sInfo.billingAddress.taxSettings.GSTNumber, app.GstNo__c, 'GSTNumber must be 2222');
    // }

    private static String PACKAGE_INFO = '[{"id":"18","version":"3","packageInfo":{"catalogId":"18","version":"3","name":"MVP Standard 1/2/100/1000+ Lines - 5100/5101/5102/5103","displayName":"RingCentral MVP Standard"},"productName":"Office","productId":"2","duration":"Monthly","edition":{"id":1,"name":"Standard"},"contract":null,"offerType":"Regular","poc":null,"globalPackageLimits":[{"code":"MONTHLY_AMOUNT_LIMIT","name":"Monthly money amount limit","type":"Amount","scope":"BillingCycle","transactionType":"Any","target":"Global","exclusions":[{"target":"LicenseCategoryId","targetId":"AP"}],"override":false,"value":"50000"}],"permissions":null,"packageBusinessIdentities":{"selectedBi":{"name":"RingCentral Inc.","isDefault":true,"id":"4","address":{"zip":"94002","street2":"","street1":"20 Davis Dr","state":"CA","phone":"","lastName":"","label":null,"firstName":"RingCentral, Inc.","county":"","country":"USA","city":"Belmont"}},"defaultBi":{"name":"RingCentral Inc.","isDefault":true,"id":"4","address":{"zip":"94002","street2":"","street1":"20 Davis Dr","state":"CA","phone":"","lastName":"","label":null,"firstName":"RingCentral, Inc.","county":"","country":"USA","city":"Belmont"}},"approvedBi":{"name":"RingCentral Inc.","isDefault":true,"id":"4","address":{"zip":"94002","street2":"","street1":"20 Davis Dr","state":"CA","phone":"","lastName":"","label":null,"firstName":"RingCentral, Inc.","county":"","country":"USA","city":"Belmont"}}},"existingPackageInfo":{}}]';
    private static final String packageQLIInfoHD = '{"Version":"3","q":null,"Price":null,"parent":null,"originalDiscount":null,"lbox":{"min":0,"max":99999,"elementID":"LB_698"},"isPhoneLeasingEnabled":null,"isCore":null,"Id":"18","duration":"One - Time","Discount":{"Value":0,"Type":"Money"},"categoryPath":"HD","categoryCode":"HD"}';
    private static final String packageQLIInfoDLUNL_50 = '{"categoryCode":"DL-UNL","duration":"Monthly","parent":null,"q":2,"lbox":{"min":1,"max":99999,"elementID":"LB_70"},"categoryPath":"DL:DL-UNL","originalDiscount":null,"isCore":null,"isPhoneLeasingEnabled":null}';
    private static final List<String> catalogIds = new List<String>{ 'LC_HD_202','LC_HD_203', 'LC_DL-UNL_50'};

    @isTest
    private static void verifySubscriberInfoForLBOWithShippingAssignments() {
        Triggers.switchOff();

        new SObjectBuilder(Feature_Toggle__c.sObjectType)
            .setField(Feature_Toggle__c.Shipping_Tab_New_Business__c, true)
            .create();

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => 'Test acc',
                Account.BillingStreet => '2078 Adamsville Road',
                Account.BillingCity => 'Laredo',
                Account.BillingPostalCode => '78040',
                Account.BillingState => 'Texas',
                Account.BillingCountry => 'United States'
            })
            .create()
            .getRecord();

        Contact cont = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Contact.FirstName => 'Test2',
                Contact.LastName => 'Test2',
                Contact.AccountId => acc.Id,
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
                Opportunity.Type => OpportunityHelper.OPPORTUNITY_TYPE_NEW_BUSINESS,
                Opportunity.RecordTypeId => OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY,
                Opportunity.AccountId => acc.Id,
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                Opportunity.CloseDate => system.today().addMonths(1),
                Opportunity.Primary_Opportunity_Contact__c => cont.Id,
                Opportunity.CurrencyIsoCode => RingCentralHelper.USD
            })
            .create()
            .getRecord();

        Area_Codes__c ac = (Area_Codes__c) new SObjectBuilder(Area_Codes__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Area_Codes__c.Name => '205',
                    Area_Codes__c.Area_Code__c => 205,
                    Area_Codes__c.City__c => 'Birmingham',
                    Area_Codes__c.Country__c => 'United States',
                    Area_Codes__c.State__c => 'Alabama'
                }
            )
            .create()
            .getRecord();

        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.Name => ValueProviderBuilder.provideUniqueString('Test Billing Quote'),
                Quote.OpportunityId => opp.Id,
                Quote.Status => QuoteHelper.QUOTE_STATUS_DRAFT,
                Quote.Approved_Status__c => QuoteHelper.APPROVAL_STATUS_NOT_REQUIRED,
                Quote.Total_Number_of_Digital_Lines__c => 1,
                Quote.Start_Date__c => Date.today(),
                Quote.End_Date__c => Date.today().addDays(2),
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.Pricebook2Id => Test.getStandardPricebookId(),
                Quote.Package_Info__c => PACKAGE_INFO,
                Quote.isPrimary__c => true,
                Quote.Enabled_LBO__c => true,
                Quote.AreaCode__c => ac.Id
            })
            .create()
            .getRecord();

        List<Product2> products = (List<Product2>) new SObjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Product2.Name => ValueProviderBuilder.provideList(new List<String> {'Polycom IP 5000 Conference Phone', 'Polycom IP 6000 Conference Phone', 'DigitalLine Unlimited'}),
                Product2.ExtID__c => ValueProviderBuilder.provideList(catalogIds),
                Product2.Charge_Term__c => ValueProviderBuilder.provideList(new List<String> {Product2Helper.CHARGE_TERM_ONE_TIME, Product2Helper.CHARGE_TERM_ONE_TIME, Product2Helper.CHARGE_TERM_MONTHLY}),
                Product2.Family => ValueProviderBuilder.provideList(new List<String>{Product2Helper.FAMILY_DISCOUNTED_PHONES, Product2Helper.FAMILY_DISCOUNTED_PHONES, Product2Helper.FAMILY_SERVICE}),
                Product2.IsActive => true,
                Product2.ShippingType__c => ValueProviderBuilder.provideList(new List<String> {Product2Helper.SHIPPING_TYPE_AUTO, Product2Helper.SHIPPING_TYPE_AUTO, ''})
            })
            .quantity(3)
            .create()
            .getRecords();

        List<PricebookEntry> pbe = (List<PricebookEntry>) new SObjectBuilder(PricebookEntry.SObjectType)
            .quantity(3)
            .setFields(new Map<SObjectField, Object>{
                PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                PricebookEntry.Product2Id => ValueProviderBuilder.provideList(new List<Id>{products[0].Id, products[1].Id, products[2].Id}),
                PricebookEntry.UnitPrice => 100,
                PricebookEntry.IsActive => true
            })
            .create()
            .getRecords();

        List<QuoteLineItem> qlis = (List<QuoteLineItem>) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                QuoteLineItem.QuoteId => qt.Id,
                QuoteLineItem.Product2Id => ValueProviderBuilder.provideList(new List<Id>{products[0].Id, products[1].Id, products[2].Id}),
                QuoteLineItem.Quantity => ValueProviderBuilder.provideList(new List<Integer> {10,10,20}),
                QuoteLineItem.NewQuantity__c => ValueProviderBuilder.provideList(new List<Integer> {10,10,20}),
                QuoteLineItem.PricebookEntryId => ValueProviderBuilder.provideList(new List<Id> {pbe[0].Id, pbe[1].Id, pbe[2].Id}),
                QuoteLineItem.UnitPrice => 10.00,
                QuoteLineItem.PackageInfo__c =>ValueProviderBuilder.provideList(
                    new List<String>{
                        packageQLIInfoHD,
                        packageQLIInfoHD,
                        packageQLIInfoDLUNL_50
                    }
                )
            })
            .quantity(3)
            .create()
            .getRecords();

        CustomAddress__c ca = (CustomAddress__c) new SObjectBuilder(CustomAddress__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                CustomAddress__c.AddressLine__c => '2078 Adamsville Road',
                CustomAddress__c.City__c => 'Laredo',
                CustomAddress__c.PostalCode__c => '78040',
                CustomAddress__c.State__c => 'Texas',
                CustomAddress__c.Country__c => 'United States'
            })
            .create()
            .getRecord();

        List<CustomAddressAssignments__c> addresses = (List<CustomAddressAssignments__c>) new SObjectBuilder(CustomAddressAssignments__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                CustomAddressAssignments__c.CustomAddress__c => ca.Id,
                CustomAddressAssignments__c.AttentionTo__c => 'FirstName LastName',
                CustomAddressAssignments__c.Quantity__c => ValueProviderBuilder.provideList(new List<Integer> {4,7}),
                CustomAddressAssignments__c.QuoteLineItem__c => ValueProviderBuilder.provideList(new List<Id> {qlis[0].Id, qlis[1].Id}),
                CustomAddressAssignments__c.Type__c => ValueProviderBuilder.provideList(new List<String> {'Ground', '2 Day'}),
                CustomAddressAssignments__c.ShippingLicenseTree__c => 'LC_SHP_86:LC_SHIP_82:LC_SHIPT_80'
            })
            .quantity(2)
            .create()
            .getRecords();

        Triggers.switchOn();

        Test.startTest();
        User user = (User) new SObjectBuilder(User.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                User.FirstName => 'John',
                User.LastName => 'Good'
            })
            .create()
            .getRecord();

        List<CustomAddressAssignments__c> reselectAddresses = (List<CustomAddressAssignments__c>) new CustomAddressAssignmentsSelector().selectCustomAddressAssignments().executeQuery();
        Quote reselectQuote = (Quote) new QuoteSelector().selectQuoteForSignUp(qt.Id).executeQuery().get(0);
        Map<Id, List<CustomAddressAssignments__c>> addressAssignmentsMap = new Map<Id, List<CustomAddressAssignments__c>>{ca.Id => reselectAddresses};
        SubscriberInfoBuilder.AssignmentData[] assignments = SubscriberInfoBuilder.getAssignments(
            reselectQuote.QuoteLineItems,
            new List<Area_Code_Line_Item__c>(),
            new List<AssignmentLineItem__c>(),
            new Map<Id, QuoteLineItem>(reselectQuote.QuoteLineItems),
            new Map<Id, Area_Codes__c>(new List<Area_Codes__c> {ac}),
            qt.Enabled_LBO__c,
            Product2Helper.PRODUCT_OFFICE,
            null,
            null,
            false
        );
        SubscriberInfoBuilder infoBuilder = new SubscriberInfoBuilder(user, acc, cont, reselectQuote, assignments, addressAssignmentsMap, null, false);
        Test.stopTest();

        String sInfoStr = EncodingUtil.base64Decode(infoBuilder.getValue()).toString();
        SubscriberInfoBuilder.SubscriberInfo sInfo = (SubscriberInfoBuilder.SubscriberInfo) JSON.deserialize(sInfoStr, SubscriberInfoBuilder.SubscriberInfo.class);
        System.assertEquals(3, sInfo.LicenseCategories.size(), 'LicenseCategories list must have 3 records');

        System.assertEquals('DL', sInfo.LicenseCategories[0].licenseCategory, 'License category list must be "DL"');
        System.assertEquals(1, sInfo.LicenseCategories[0].licenses.size(), 'Licenses list must have 1 record');
        System.assertEquals('LC_DL-UNL_50', sInfo.LicenseCategories[0].licenses[0].catalogId, 'License catalogId must be "LC_DL-UNL_50"');
        System.assertEquals(20, sInfo.LicenseCategories[0].licenses[0].qty, 'License qty must be 20');
        System.assertEquals(null, sInfo.LicenseCategories[0].licenses[0].shippingGroupId, 'ShippingGroupId must be null');
        System.assertEquals(null, sInfo.LicenseCategories[0].licenses[0].shippingAddress, 'ShippingAddress must be null');
        System.assertEquals(null, sInfo.LicenseCategories[0].licenses[0].phoneNumberInfo, 'PhoneNumberInfo must be null');
        System.assertEquals(null, sInfo.LicenseCategories[0].licenses[0].deviceTypeInfo, 'DeviceTypeInfo must be null');

        System.assertEquals('SHP', sInfo.LicenseCategories[1].licenseCategory, 'License category list must be "SHP"');
        System.assertEquals(1, sInfo.LicenseCategories[1].licenses.size(), 'Licenses list must have 1 record');
        System.assertEquals('LC_SHIPT_80', sInfo.LicenseCategories[1].licenses[0].catalogId, 'License catalogId must be "LC_SHIPT_80"');
        System.assertEquals(1, sInfo.LicenseCategories[1].licenses[0].qty, 'License qty must be 1');
        System.assertEquals(null, sInfo.LicenseCategories[1].licenses[0].phoneNumberInfo, 'PhoneNumberInfo must be null');
        System.assertEquals(null, sInfo.LicenseCategories[1].licenses[0].deviceTypeInfo, 'DeviceTypeInfo must be null');
        System.assertEquals(null, sInfo.LicenseCategories[1].licenses[0].shippingGroupId, 'ShippingGroupId must be null');
        System.assertEquals(1, sInfo.LicenseCategories[1].licenses[0].shippingAddress.size(), 'ShippingAddress must have 1 record');
        System.assertEquals(ca.PostalCode__c, sInfo.LicenseCategories[1].licenses[0].shippingAddress[0].zipCode, 'Zip code must the same as in Custom Address object');
        System.assertEquals(ca.State__c, sInfo.LicenseCategories[1].licenses[0].shippingAddress[0].state, 'State must the same as in Custom Address object');
        System.assertEquals(ca.Id, sInfo.LicenseCategories[1].licenses[0].shippingAddress[0].shippingGroupId, 'State must the same as in Custom Address object');
        System.assertEquals(addresses[0].AttentionTo__c.split(' ')[0], sInfo.LicenseCategories[1].licenses[0].shippingAddress[0].firstName, 'FirstName must the same as in Custom Address Assignment object');
        System.assertEquals(addresses[0].AttentionTo__c.split(' ')[1], sInfo.LicenseCategories[1].licenses[0].shippingAddress[0].lastName, 'LastName must the same as in Custom Address Assignment object');
        System.assertEquals(ca.Country__c, sInfo.LicenseCategories[1].licenses[0].shippingAddress[0].country, 'Country must the same as in Custom Address object');
        System.assertEquals(acc.Name, sInfo.LicenseCategories[1].licenses[0].shippingAddress[0].companyName, 'Company Name must the same as in Account object');
        System.assertEquals(ca.City__c, sInfo.LicenseCategories[1].licenses[0].shippingAddress[0].city, 'City must the same as in Custom Address object');
        System.assertEquals(ca.AddressLine__c, sInfo.LicenseCategories[1].licenses[0].shippingAddress[0].addressLine1, 'Address line must the same as in Custom Address object');

        System.assertEquals('HD', sInfo.LicenseCategories[2].licenseCategory, 'License category list must be "HD"');
        System.assertEquals(4, sInfo.LicenseCategories[2].licenses.size(), 'Licenses list must have 4 records');

        System.assertEquals('LC_HD_202', sInfo.LicenseCategories[2].licenses[0].catalogId, 'License catalogId must be "LC_HD_202"');
        System.assertEquals('auto', sInfo.LicenseCategories[2].licenses[0].shippingReq, 'License "shiping label" must be "auto"');
        System.assertEquals(null, sInfo.LicenseCategories[2].licenses[0].phoneNumberInfo, 'PhoneNumberInfo must be null');
        System.assertEquals(null, sInfo.LicenseCategories[2].licenses[0].shippingAddress, 'ShippingAddress must be null');

        // System.assertEquals(ca.Id, sInfo.LicenseCategories[2].licenses[0].shippingGroupId, 'ShippingGroupId must be the same as in Custom Address Assignment object');
        System.assertEquals((Integer) addresses[0].Quantity__c, sInfo.LicenseCategories[2].licenses[0].qty, 'Quantity must be the same as in Custom Address Assignment object');

        System.assertEquals('LC_HD_202', sInfo.LicenseCategories[2].licenses[1].catalogId, 'License catalogId must be "LC_HD_202"');
        System.assertEquals(null, sInfo.LicenseCategories[2].licenses[1].phoneNumberInfo, 'PhoneNumberInfo must be null');
        System.assertEquals(null, sInfo.LicenseCategories[2].licenses[1].deviceTypeInfo, 'DeviceTypeInfo must be null');
        System.assertEquals(null, sInfo.LicenseCategories[2].licenses[1].shippingAddress, 'ShippingAddress must be null');
        System.assertEquals(null, sInfo.LicenseCategories[2].licenses[1].shippingGroupId, 'ShippingGroupId must be null');
        System.assertEquals(6, sInfo.LicenseCategories[2].licenses[1].qty, 'Quantity must be 6');

        System.assertEquals('LC_HD_203', sInfo.LicenseCategories[2].licenses[2].catalogId, 'License catalogId must be "LC_HD_203"');
        System.assertEquals(null, sInfo.LicenseCategories[2].licenses[2].phoneNumberInfo, 'PhoneNumberInfo must be null');
        System.assertEquals(null, sInfo.LicenseCategories[2].licenses[2].shippingAddress, 'ShippingAddress must be null');
        System.assertEquals((Integer) addresses[1].Quantity__c, sInfo.LicenseCategories[2].licenses[2].qty, 'Quantity must be the same as in Custom Address Assignment object');

        System.assertEquals('LC_HD_203', sInfo.LicenseCategories[2].licenses[3].catalogId, 'License catalogId must be "LC_HD_203"');
        System.assertEquals(null, sInfo.LicenseCategories[2].licenses[3].phoneNumberInfo, 'PhoneNumberInfo must be null');
        System.assertEquals(null, sInfo.LicenseCategories[2].licenses[3].deviceTypeInfo, 'DeviceTypeInfo must be null');
        System.assertEquals(null, sInfo.LicenseCategories[2].licenses[3].shippingAddress, 'ShippingAddress must be null');
        System.assertEquals(null, sInfo.LicenseCategories[2].licenses[3].shippingGroupId, 'ShippingGroupId must be null');
        System.assertEquals(3, sInfo.LicenseCategories[2].licenses[3].qty, 'Quantity must be 3');
    }

    @isTest
    private static void verifySubscriberInfoForNonLBOWithShippingAssignments() {
        Triggers.switchOff();

        new SObjectBuilder(Feature_Toggle__c.sObjectType)
            .setField(Feature_Toggle__c.Shipping_Tab_New_Business__c, true)
            .create();

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => 'Test acc',
                Account.BillingStreet => '2078 Adamsville Road',
                Account.BillingCity => 'Laredo',
                Account.BillingPostalCode => '78040',
                Account.BillingState => 'Texas',
                Account.BillingCountry => 'United States'
            })
            .create()
            .getRecord();

        Contact cont = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Contact.FirstName => 'Test2',
                Contact.LastName => 'Test2',
                Contact.AccountId => acc.Id,
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
                Opportunity.Type => OpportunityHelper.OPPORTUNITY_TYPE_NEW_BUSINESS,
                Opportunity.RecordTypeId => OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY,
                Opportunity.AccountId => acc.Id,
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                Opportunity.CloseDate => system.today().addMonths(1),
                Opportunity.Primary_Opportunity_Contact__c => cont.Id,
                Opportunity.CurrencyIsoCode => RingCentralHelper.USD
            })
            .create()
            .getRecord();

        Area_Codes__c ac = (Area_Codes__c) new SObjectBuilder(Area_Codes__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Area_Codes__c.Name => '205',
                    Area_Codes__c.Area_Code__c => 205,
                    Area_Codes__c.City__c => 'Birmingham',
                    Area_Codes__c.Country__c => 'United States',
                    Area_Codes__c.State__c => 'Alabama'
                }
            )
            .create()
            .getRecord();

        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.Name => ValueProviderBuilder.provideUniqueString('Test Billing Quote'),
                Quote.OpportunityId => opp.Id,
                Quote.Status => QuoteHelper.QUOTE_STATUS_DRAFT,
                Quote.Approved_Status__c => QuoteHelper.APPROVAL_STATUS_NOT_REQUIRED,
                Quote.Total_Number_of_Digital_Lines__c => 1,
                Quote.Start_Date__c => Date.today(),
                Quote.End_Date__c => Date.today().addDays(2),
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.Pricebook2Id => Test.getStandardPricebookId(),
                Quote.Package_Info__c => PACKAGE_INFO,
                Quote.isPrimary__c => true,
                Quote.Enabled_LBO__c => false,
                Quote.AreaCode__c => ac.Id
            })
            .create()
            .getRecord();

        List<Product2> products = (List<Product2>) new SObjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Product2.Name => ValueProviderBuilder.provideList(new List<String> {'Polycom IP 5000 Conference Phone', 'Polycom IP 6000 Conference Phone', 'DigitalLine Unlimited'}),
                Product2.ExtID__c => ValueProviderBuilder.provideList(catalogIds),
                Product2.Charge_Term__c => ValueProviderBuilder.provideList(new List<String> {Product2Helper.CHARGE_TERM_ONE_TIME, Product2Helper.CHARGE_TERM_ONE_TIME, Product2Helper.CHARGE_TERM_MONTHLY}),
                Product2.Family => ValueProviderBuilder.provideList(new List<String>{Product2Helper.FAMILY_DISCOUNTED_PHONES, Product2Helper.FAMILY_DISCOUNTED_PHONES, Product2Helper.FAMILY_SERVICE}),
                Product2.IsActive => true,
                Product2.ShippingType__c => ValueProviderBuilder.provideList(new List<String> {Product2Helper.SHIPPING_TYPE_AUTO, Product2Helper.SHIPPING_TYPE_AUTO, ''})
            })
            .quantity(3)
            .create()
            .getRecords();

        List<PricebookEntry> pbe = (List<PricebookEntry>) new SObjectBuilder(PricebookEntry.SObjectType)
            .quantity(3)
            .setFields(new Map<SObjectField, Object>{
                PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                PricebookEntry.Product2Id => ValueProviderBuilder.provideList(new List<Id>{products[0].Id, products[1].Id, products[2].Id}),
                PricebookEntry.UnitPrice => 100,
                PricebookEntry.IsActive => true
            })
            .create()
            .getRecords();

        List<QuoteLineItem> qlis = (List<QuoteLineItem>) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                QuoteLineItem.QuoteId => qt.Id,
                QuoteLineItem.Product2Id => ValueProviderBuilder.provideList(new List<Id>{products[0].Id, products[1].Id, products[2].Id}),
                QuoteLineItem.Quantity => ValueProviderBuilder.provideList(new List<Integer> {10,10,20}),
                QuoteLineItem.NewQuantity__c => ValueProviderBuilder.provideList(new List<Integer> {10,10,20}),
                QuoteLineItem.PricebookEntryId => ValueProviderBuilder.provideList(new List<Id> {pbe[0].Id, pbe[1].Id, pbe[2].Id}),
                QuoteLineItem.UnitPrice => 10.00,
                QuoteLineItem.PackageInfo__c =>ValueProviderBuilder.provideList(new List<String>{packageQLIInfoHD, packageQLIInfoHD, packageQLIInfoDLUNL_50})
            })
            .quantity(3)
            .create()
            .getRecords();

        List<Area_Code_Line_Item__c> areaCodeList = (List<Area_Code_Line_Item__c>) new SObjectBuilder(Area_Code_Line_Item__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Area_Code_Line_Item__c.Id => ValueProviderBuilder.provideDummyId(Area_Code_Line_Item__c.SObjectType),
                    Area_Code_Line_Item__c.Quote_Line_Item__c => ValueProviderBuilder.provideList(new List<Id>{qlis[0].Id, qlis[1].Id}),
                    Area_Code_Line_Item__c.Area_Code__c => ac.Id,
                    Area_Code_Line_Item__c.Quantity__c => 10
                }
            )
            .quantity(2)
            .build()
            .getRecords();

        List<AssignmentLineItem__c> assignmentLinesList = (List<AssignmentLineItem__c>) new SObjectBuilder(AssignmentLineItem__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    AssignmentLineItem__c.Parent__c => qlis[2].Id,
                    AssignmentLineItem__c.Child__c => ValueProviderBuilder.provideList(new List<Id>{qlis[0].Id, qlis[1].Id}),
                    AssignmentLineItem__c.AreaCode__c => ac.Id,
                    AssignmentLineItem__c.Quantity__c => 10
                }
            )
            .quantity(2)
            .create()
            .getRecords();

        CustomAddress__c ca = (CustomAddress__c) new SObjectBuilder(CustomAddress__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                CustomAddress__c.AddressLine__c => '2078 Adamsville Road',
                CustomAddress__c.City__c => 'Laredo',
                CustomAddress__c.PostalCode__c => '78040',
                CustomAddress__c.State__c => 'Texas',
                CustomAddress__c.Country__c => 'United States'
            })
            .create()
            .getRecord();

        List<CustomAddressAssignments__c> addresses = (List<CustomAddressAssignments__c>) new SObjectBuilder(CustomAddressAssignments__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                CustomAddressAssignments__c.CustomAddress__c => ca.Id,
                CustomAddressAssignments__c.AttentionTo__c => 'FirstName LastName',
                CustomAddressAssignments__c.Quantity__c => ValueProviderBuilder.provideList(new List<Integer> {4,7}),
                CustomAddressAssignments__c.QuoteLineItem__c => ValueProviderBuilder.provideList(new List<Id> {qlis[0].Id, qlis[1].Id}),
                CustomAddressAssignments__c.Type__c => ValueProviderBuilder.provideList(new List<String> {'Ground', '2 Day'}),
                CustomAddressAssignments__c.ShippingLicenseTree__c => 'LC_SHP_86:LC_SHIP_82:LC_SHIPT_80',
                CustomAddressAssignments__c.AssignmentLineItem__c => ValueProviderBuilder.provideList(new List<Id>{assignmentLinesList[0].Id, assignmentLinesList[1].Id})
            })
            .quantity(2)
            .create()
            .getRecords();

        Triggers.switchOn();

        Test.startTest();
        User user = (User) new SObjectBuilder(User.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                User.FirstName => 'John',
                User.LastName => 'Good'
            })
            .create()
            .getRecord();

        List<CustomAddressAssignments__c> reselectAddresses = (List<CustomAddressAssignments__c>) new CustomAddressAssignmentsSelector().selectCustomAddressAssignments().executeQuery();
        Quote reselectQuote = (Quote) new QuoteSelector().selectQuoteForSignUp(qt.Id).executeQuery().get(0);
        Map<Id, List<CustomAddressAssignments__c>> addressAssignmentsMap = new Map<Id, List<CustomAddressAssignments__c>>{ca.Id => reselectAddresses};
        SubscriberInfoBuilder.AssignmentData[] assignments = SubscriberInfoBuilder.getAssignments(
            reselectQuote.QuoteLineItems,
            areaCodeList,
            assignmentLinesList,
            new Map<Id, QuoteLineItem>(reselectQuote.QuoteLineItems),
            new Map<Id, Area_Codes__c>(new List<Area_Codes__c> {ac}),
            qt.Enabled_LBO__c,
            Product2Helper.PRODUCT_OFFICE,
            null,
            null,
            false
        );
        SubscriberInfoBuilder infoBuilder = new SubscriberInfoBuilder(user, acc, cont, reselectQuote, assignments, addressAssignmentsMap, null, false);
        Test.stopTest();

        String sInfoStr = EncodingUtil.base64Decode(infoBuilder.getValue()).toString();
        SubscriberInfoBuilder.SubscriberInfo sInfo = (SubscriberInfoBuilder.SubscriberInfo) JSON.deserialize(sInfoStr, SubscriberInfoBuilder.SubscriberInfo.class);

        System.assertEquals(2, sInfo.LicenseCategories.size(), 'LicenseCategories list must have 2 records');

        System.assertEquals('DL', sInfo.LicenseCategories[0].licenseCategory, 'License category list must be "DL"');
        System.assertEquals(4, sInfo.LicenseCategories[0].licenses.size(), 'Licenses list must have 4 records');

        System.assertEquals('LC_DL-UNL_50', sInfo.LicenseCategories[0].licenses[0].catalogId, 'License catalogId must be "LC_DL-UNL_50"');
        System.assertEquals(ac.Country__c, sInfo.LicenseCategories[0].licenses[0].phoneNumberInfo[0].country, 'PhoneNumberInfo Country must be the same as in Area Code object');
        System.assertEquals(ac.City__c, sInfo.LicenseCategories[0].licenses[0].phoneNumberInfo[0].city, 'PhoneNumberInfo City must be the same as in Area Code object');
        System.assertEquals(String.valueOf(ac.Area_Code__c), sInfo.LicenseCategories[0].licenses[0].phoneNumberInfo[0].areaCode, 'PhoneNumberInfo Area Code must be the same as in Area Code object');
        System.assertEquals('LC_HD_202', sInfo.LicenseCategories[0].licenses[0].deviceTypeInfo[0].catalogId, 'DeviceTypeInfo catalogId must be "LC_HD_202"');
        System.assertEquals(ca.Id, sInfo.LicenseCategories[0].licenses[0].deviceTypeInfo[0].shippingGroupId, 'DeviceTypeInfo shippingGroupId must be the same as in Custom Address object');
        System.assertEquals(null, sInfo.LicenseCategories[0].licenses[0].shippingAddress, 'ShippingAddress must be null');
        System.assertEquals(ca.Id, sInfo.LicenseCategories[0].licenses[0].shippingGroupId, 'ShippingGroupId must be the same as in Custom Address Assignment object');
        System.assertEquals((Integer) addresses[0].Quantity__c, sInfo.LicenseCategories[0].licenses[0].qty, 'Quantity must be the same as in Custom Address Assignment object');

        System.assertEquals('LC_DL-UNL_50', sInfo.LicenseCategories[0].licenses[1].catalogId, 'License catalogId must be "LC_DL-UNL_50"');
        System.assertEquals(ac.Country__c, sInfo.LicenseCategories[0].licenses[1].phoneNumberInfo[0].country, 'PhoneNumberInfo Country must be the same as in Area Code object');
        System.assertEquals(ac.City__c, sInfo.LicenseCategories[0].licenses[1].phoneNumberInfo[0].city, 'PhoneNumberInfo City must be the same as in Area Code object');
        System.assertEquals(String.valueOf(ac.Area_Code__c), sInfo.LicenseCategories[0].licenses[1].phoneNumberInfo[0].areaCode, 'PhoneNumberInfo Area Code must be the same as in Area Code object');
        System.assertEquals('LC_HD_202', sInfo.LicenseCategories[0].licenses[1].deviceTypeInfo[0].catalogId, 'DeviceTypeInfo catalogId must be "LC_HD_202"');
        System.assertEquals('auto', sInfo.LicenseCategories[0].licenses[1].deviceTypeInfo[0].shippingReq, 'License "shiping label" must be "auto"');
        System.assertEquals(null, sInfo.LicenseCategories[0].licenses[1].deviceTypeInfo[0].shippingGroupId, 'DeviceTypeInfo shippingGroupId must be null');
        System.assertEquals(null, sInfo.LicenseCategories[0].licenses[1].shippingAddress, 'ShippingAddress must be null');
        System.assertEquals(null, sInfo.LicenseCategories[0].licenses[1].shippingGroupId, 'ShippingGroupId must be the same as in Custom Address Assignment object');
        System.assertEquals(6, sInfo.LicenseCategories[0].licenses[1].qty, 'Quantity must be 6');

        System.assertEquals('LC_DL-UNL_50', sInfo.LicenseCategories[0].licenses[2].catalogId, 'License catalogId must be "LC_DL-UNL_50"');
        System.assertEquals(ac.Country__c, sInfo.LicenseCategories[0].licenses[2].phoneNumberInfo[0].country, 'PhoneNumberInfo Country must be the same as in Area Code object');
        System.assertEquals(ac.City__c, sInfo.LicenseCategories[0].licenses[2].phoneNumberInfo[0].city, 'PhoneNumberInfo City must be the same as in Area Code object');
        System.assertEquals(String.valueOf(ac.Area_Code__c), sInfo.LicenseCategories[0].licenses[2].phoneNumberInfo[0].areaCode, 'PhoneNumberInfo Area Code must be the same as in Area Code object');
        System.assertEquals('LC_HD_203', sInfo.LicenseCategories[0].licenses[2].deviceTypeInfo[0].catalogId, 'DeviceTypeInfo catalogId must be "LC_HD_203"');
        System.assertEquals(ca.Id, sInfo.LicenseCategories[0].licenses[2].deviceTypeInfo[0].shippingGroupId, 'DeviceTypeInfo shippingGroupId must be the same as in Custom Address object');
        System.assertEquals(null, sInfo.LicenseCategories[0].licenses[2].shippingAddress, 'ShippingAddress must be null');
        System.assertEquals(ca.Id, sInfo.LicenseCategories[0].licenses[2].shippingGroupId, 'ShippingGroupId must be the same as in Custom Address Assignment object');
        System.assertEquals((Integer) addresses[1].Quantity__c, sInfo.LicenseCategories[0].licenses[2].qty, 'Quantity must be the same as in Custom Address Assignment object');

        System.assertEquals('LC_DL-UNL_50', sInfo.LicenseCategories[0].licenses[3].catalogId, 'License catalogId must be "LC_DL-UNL_50"');
        System.assertEquals(ac.Country__c, sInfo.LicenseCategories[0].licenses[3].phoneNumberInfo[0].country, 'PhoneNumberInfo Country must be the same as in Area Code object');
        System.assertEquals(ac.City__c, sInfo.LicenseCategories[0].licenses[3].phoneNumberInfo[0].city, 'PhoneNumberInfo City must be the same as in Area Code object');
        System.assertEquals(String.valueOf(ac.Area_Code__c), sInfo.LicenseCategories[0].licenses[3].phoneNumberInfo[0].areaCode, 'PhoneNumberInfo Area Code must be the same as in Area Code object');
        System.assertEquals('LC_HD_203', sInfo.LicenseCategories[0].licenses[3].deviceTypeInfo[0].catalogId, 'DeviceTypeInfo catalogId must be "LC_HD_203"');
        System.assertEquals(null, sInfo.LicenseCategories[0].licenses[3].deviceTypeInfo[0].shippingGroupId, 'DeviceTypeInfo shippingGroupId must be null');
        System.assertEquals(null, sInfo.LicenseCategories[0].licenses[3].shippingAddress, 'ShippingAddress must be null');
        System.assertEquals(null, sInfo.LicenseCategories[0].licenses[3].shippingGroupId, 'ShippingGroupId must be the same as in Custom Address Assignment object');
        System.assertEquals(3, sInfo.LicenseCategories[0].licenses[3].qty, 'Quantity must be 6');

        System.assertEquals('SHP', sInfo.LicenseCategories[1].licenseCategory, 'License category list must be "SHP"');
        System.assertEquals(1, sInfo.LicenseCategories[1].licenses.size(), 'Licenses list must have 1 record');
        System.assertEquals('LC_SHIPT_80', sInfo.LicenseCategories[1].licenses[0].catalogId, 'License catalogId must be "LC_SHIPT_80"');
        System.assertEquals(1, sInfo.LicenseCategories[1].licenses[0].qty, 'License qty must be 1');
        System.assertEquals(null, sInfo.LicenseCategories[1].licenses[0].phoneNumberInfo, 'PhoneNumberInfo must be null');
        System.assertEquals(null, sInfo.LicenseCategories[1].licenses[0].deviceTypeInfo, 'DeviceTypeInfo must be null');
        System.assertEquals(null, sInfo.LicenseCategories[1].licenses[0].shippingGroupId, 'ShippingGroupId must be null');
        System.assertEquals(1, sInfo.LicenseCategories[1].licenses[0].shippingAddress.size(), 'ShippingAddress must have 1 record');
        System.assertEquals(ca.PostalCode__c, sInfo.LicenseCategories[1].licenses[0].shippingAddress[0].zipCode, 'Zip code must the same as in Custom Address object');
        System.assertEquals(ca.State__c, sInfo.LicenseCategories[1].licenses[0].shippingAddress[0].state, 'State must the same as in Custom Address object');
        System.assertEquals(ca.Id, sInfo.LicenseCategories[1].licenses[0].shippingAddress[0].shippingGroupId, 'State must the same as in Custom Address object');
        System.assertEquals(addresses[0].AttentionTo__c.split(' ')[0], sInfo.LicenseCategories[1].licenses[0].shippingAddress[0].firstName, 'FirstName must the same as in Custom Address Assignment object');
        System.assertEquals(addresses[0].AttentionTo__c.split(' ')[1], sInfo.LicenseCategories[1].licenses[0].shippingAddress[0].lastName, 'LastName must the same as in Custom Address Assignment object');
        System.assertEquals(ca.Country__c, sInfo.LicenseCategories[1].licenses[0].shippingAddress[0].country, 'Country must the same as in Custom Address object');
        System.assertEquals(acc.Name, sInfo.LicenseCategories[1].licenses[0].shippingAddress[0].companyName, 'Company Name must the same as in Account object');
        System.assertEquals(ca.City__c, sInfo.LicenseCategories[1].licenses[0].shippingAddress[0].city, 'City must the same as in Custom Address object');
        System.assertEquals(ca.AddressLine__c, sInfo.LicenseCategories[1].licenses[0].shippingAddress[0].addressLine1, 'Address line must the same as in Custom Address object');
    }

    @isTest
    private static void verifyNonAssignableLicensesAddedToLicenseCategoryRequest() {

        SubscriberInfoBuilder.DLBuilder builderDL = new SubscriberInfoBuilder.DLBuilder();
        SubscriberInfoBuilder.DLBuilder builderBYOC = new SubscriberInfoBuilder.DLBuilder();

        CustomAddress__c address = (CustomAddress__c) new SObjectBuilder(CustomAddress__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                CustomAddress__c.Id => ValueProviderBuilder.provideDummyId(CustomAddress__c.SObjectType),
                CustomAddress__c.AddressLine__c => '2078 Adamsville Road',
                CustomAddress__c.City__c => 'Laredo',
                CustomAddress__c.PostalCode__c => '78040',
                CustomAddress__c.State__c => 'Texas',
                CustomAddress__c.Country__c => 'United States'
            })
            .build()
            .getRecord();

        CustomAddressAssignments__c addressAssignment = (CustomAddressAssignments__c) new SObjectBuilder(CustomAddressAssignments__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                CustomAddressAssignments__c.Id => ValueProviderBuilder.provideDummyId(CustomAddressAssignments__c.SObjectType),
                CustomAddressAssignments__c.CustomAddress__c => address.Id,
                CustomAddressAssignments__c.AttentionTo__c => 'FirstName LastName',
                CustomAddressAssignments__c.Quantity__c => 1,
                CustomAddressAssignments__c.Type__c => '2 Day',
                CustomAddressAssignments__c.ShippingLicenseTree__c => 'LC_SHP_86:LC_SHIP_82:LC_SHIPT_80'
            })
            .build()
            .getRecord();

        Map<Id, List<CustomAddressAssignments__c>> addressAssignmentsMap = new Map<Id, List<CustomAddressAssignments__c>>{
            address.Id => new List<CustomAddressAssignments__c>{addressAssignment}
        };


        QuoteLineItem domesticRoomsQli = new QuoteLineItem();
        domesticRoomsQli.Product2 = new Product2(
            ExtID__c = Product2Helper.ELEMENT_ID_DOMESTIC_ROOMS_PHONE_LINE_ADDON
        );
        SubscriberInfoBuilder.AssignmentData domesticRoomsData = new SubscriberInfoBuilder.AssignmentData();
        domesticRoomsData.categoryRoot = 'DL';
        domesticRoomsData.categoryCode = 'DL-ROOMS';
        domesticRoomsData.categoryPath = 'DL:DL-ROOMS';
        domesticRoomsData.parent = domesticRoomsQli;
        domesticRoomsData.child = null;
        domesticRoomsData.areaCode = null;
        domesticRoomsData.quantity = 1;

        builderDL.add(domesticRoomsData, false, addressAssignmentsMap);

        SubscriberInfoBuilder.LicenseCategoryRequest result = builderDL.lcr;

        System.assertEquals(domesticRoomsData.categoryRoot, result.licenseCategory, 'licenseCategory in LicenseRequest should be equal to categoryRoot');

        for (SubscriberInfoBuilder.LicenseRequest license : result.licenses) {
            System.assert(
                Product2Helper.NON_ASSIGNABLE_LICENSES.contains(license.catalogId),
                'licenses listed in NON_ASSIGNABLE_LICENSES set should be added to SignUp LicenseRequest even ' +
                'if they are not assigned in shipping tab'
            );
        }


        QuoteLineItem byocDomesticQli = new QuoteLineItem();
        byocDomesticQli.Product2 = new Product2(
            ExtID__c = Product2Helper.ELEMENT_ID_BYOC_DOMESTIC
        );
        SubscriberInfoBuilder.AssignmentData byocDomesticData = new SubscriberInfoBuilder.AssignmentData();
        byocDomesticData.categoryRoot = 'DL-BYOC';
        byocDomesticData.categoryCode = 'DL-BYOCD';
        byocDomesticData.categoryPath = 'DL-BYOC:DL-BYOCD';
        byocDomesticData.parent = byocDomesticQli;
        byocDomesticData.child = null;
        byocDomesticData.areaCode = null;
        byocDomesticData.quantity = 1;

        builderBYOC.add(byocDomesticData, false, addressAssignmentsMap);

        QuoteLineItem byocInternationalQli = new QuoteLineItem();
        byocInternationalQli.Product2 = new Product2(
            ExtID__c = Product2Helper.ELEMENT_ID_BYOC_INTERNATIONAL
        );
        SubscriberInfoBuilder.AssignmentData byocInternationalData = new SubscriberInfoBuilder.AssignmentData();
        byocInternationalData.categoryRoot = 'DL-BYOC';
        byocInternationalData.categoryCode = 'DL-BYOCI';
        byocInternationalData.categoryPath = 'DL-BYOC:DL-BYOCI';
        byocInternationalData.parent = byocInternationalQli;
        byocInternationalData.child = null;
        byocInternationalData.areaCode = null;
        byocInternationalData.quantity = 1;

        builderBYOC.add(byocInternationalData, false, addressAssignmentsMap);

        result = builderBYOC.lcr;

        System.assertEquals(byocDomesticData.categoryRoot, result.licenseCategory, 'licenseCategory in LicenseRequest should be equal to categoryRoot');

        for (SubscriberInfoBuilder.LicenseRequest license : result.licenses) {
            System.assert(
                Product2Helper.NON_ASSIGNABLE_LICENSES.contains(license.catalogId),
                'licenses listed in NON_ASSIGNABLE_LICENSES set should be added to SignUp LicenseRequest even ' +
                'if they are not assigned in shipping tab'
            );
        }
    }

    @isTest
    static void testShipBuilderWithoutAddressAssignmentsInLicenseCategoryRequest() {
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => 'Test acc',
                Account.BillingStreet => '2078 Adamsville Road',
                Account.BillingCity => 'Laredo',
                Account.BillingPostalCode => '78040',
                Account.BillingState => 'Texas',
                Account.BillingCountry => 'United States'
            })
            .build()
            .getRecord();

        Contact cont = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Contact.FirstName => 'Test2',
                Contact.LastName => 'Test2',
                Contact.Email => 'test@test.com',
                Contact.Phone => '1234567890',
                Contact.Preferred_Language__c => 'en_US'
            })
            .build()
            .getRecord();

        Test.startTest();
            SubscriberInfoBuilder.SHIPBuilder shipBuilder = new SubscriberInfoBuilder.SHIPBuilder();
            shipBuilder.add(acc, cont, new Map<Id, List<CustomAddressAssignments__c>>(), false);
        Test.stopTest();

        Assert.isNull(shipBuilder.lcr, 'License Category Request shoulb be null');
    }

    @IsTest
    static void testBuildAssignmentDataForUILessMVP() {
        createTestData();
        Test.startTest();
            SubscriberInfoBuilder.AssignmentData[] assignments = SubscriberInfoBuilder.getAssignments(qlis, aclis, alis, qliMap, acMap, false, Product2Helper.PRODUCT_OFFICE, null, null, false);
            SubscriberInfoBuilder.AssignmentData[] result;
            for (QuoteLineItem qli: qlis) {
                result = SubscriberInfoBuilder.buildAssignmentDataForUILessMVP(qli, new Map<Id, Decimal>(), assignments);
            }
        Test.stopTest();
        Assert.isNotNull(result, 'Should contains assigment data records');
        Assert.isFalse(result.isEmpty(), 'Array must not be empty');
    }
}