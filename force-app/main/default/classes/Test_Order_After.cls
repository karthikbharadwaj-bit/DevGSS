@IsTest
private class Test_Order_After {
    private final static String TEST_STRING = 'TestString';

    private static User testUser = createUser('test');

    private static User createUser(String name) {

        User user = new User(
        Username = name + '!user@gmail.com',
        LastName = 'Test' + name,
        Email = name + '_user@gmail.com',
        Alias = 'test' + name,
        TimeZoneSidKey = 'America/Los_Angeles',
        LocaleSidKey = 'en_US',
        EmailEncodingKey = 'UTF-8',
        ProfileId = [SELECT Id, Name FROM Profile WHERE Name = 'System Administrator'].Id,
        LanguageLocaleKey = 'en_US'
    );
    insert user;
    return user;
  }

  @IsTest
  static void test_method_one() {

    System.runAs(testUser) {
      Triggers.switchOff();

      Account testAcc = new Account(
          Name = 'testAcc',
          InContact_Service__c = 'Contact Center Basic',
          No_of_InContact_Seats__c = 3,
          RC_User_ID__c = '23232'
      );
      insert testAcc;

      Contact testContact = new Contact(
          Account = testAcc,
          LastName = 'Test',
          Preferred_Language__c = 'en_US',
          Email = 'test@test.com',
          Phone = '7777777',
          CurrencyIsoCode = 'USD'
      );
      insert testContact;

      Opportunity opp = new Opportunity(
          Name = 'Test Opportunity 2017',
          Type = 'Existing Business',
          Sales_Model__c = 'Direct',
          Brand_Name__c = 'RingCentral',
          Tier_Name__c = 'Professional',
          Primary_Opportunity_Contact__c = testContact.Id,
          StageName = '1. Qualify',
          CloseDate = System.today(),
          CurrencyIsoCode = 'USD'
      );
      insert opp;


      Id proServRecTypeId = Order.SObjectType.getDescribe().getRecordTypeInfosByName().get('Professional Services').getRecordTypeId();

      Product2 testProduct1 = new Product2(
          Name = 'CloudConnect ProServ Setup',
          IsActive = true,
          Sub_Category__c = 'Professional Services',
          Charge_Term__c = 'Monthly - Contract'
      );
      insert testProduct1;

      PricebookEntry testPBE1 = new PricebookEntry(
          Pricebook2Id = Test.getStandardPricebookId(),
          IsActive = true,
          UnitPrice = 1000,
          Product2Id = testProduct1.Id
      );
      insert testPBE1;

      Product2 testProduct2 = new Product2(
          Name = 'CloudConnect - Standard 200 Mbps',
          IsActive = true,
          Sub_Category__c = 'Professional Services',
          Charge_Term__c = 'Monthly - Contract'
      );
      insert testProduct2;

      PricebookEntry testPBE2 = new PricebookEntry(
          Pricebook2Id = Test.getStandardPricebookId(),
          IsActive = true,
          UnitPrice = 2000,
          Product2Id = testProduct2.Id
      );
      insert testPBE2;

      Quote testQuote = new Quote(
          Name = 'testQuote',
          OpportunityId = opp.id,
          Pricebook2Id = Test.getStandardPricebookId()
      );
      insert testQuote;


      List<QuoteLineItem> qliList = new List<QuoteLineItem>();

      QuoteLineItem qli1 = new QuoteLineItem(
          QuoteId = testQuote.Id,
          Product2Id = testProduct1.Id,
          Quantity = 2,
          UnitPrice = testPBE1.UnitPrice,
          PricebookEntryId = testPBE1.Id
      );
      qliList.add(qli1);

      QuoteLineItem qli2 = new QuoteLineItem(
          QuoteId = testQuote.Id,
          Product2Id = testProduct2.Id,
          Quantity = 10,
          UnitPrice = testPBE2.UnitPrice,
          PricebookEntryId = testPBE2.Id
      );
      qliList.add(qli2);

      insert qliList;
      Triggers.switchOn();


      Emails__c email = new Emails__c(
          Name = 'proservsow',
          Email_Address__c = 'test@test.com'
      );
      insert email;

      Order testOrder = new Order(
          AccountId = testAcc.Id,
          Status = 'New',
          EffectiveDate = System.today(),
          inContact_Cluster__c = 'C20',
          inContact_account_ID__c = 'testInContactAccountId',
          Provision_Date__c = System.today(),
          Pricebook2Id = Test.getStandardPricebookId(),
          QuoteId = testQuote.Id,
          OpportunityId = opp.Id,
          TotalBandwidthOnQuote__c = 2,
          RecordTypeId = proServRecTypeId
      );
      insert testOrder;


      List<OrderItem> orderItemList = new List<OrderItem>();

      OrderItem testOrderItem1 = new OrderItem(
          OrderId = testOrder.Id,
          PricebookEntryId = testPBE1.Id,
          Quantity = qli1.Quantity,
          UnitPrice = qli1.UnitPrice
      );
      orderItemList.add(testOrderItem1);

      OrderItem testOrderItem2 = new OrderItem(
          OrderId = testOrder.Id,
          PricebookEntryId = testPBE2.Id,
          Quantity = qli2.Quantity,
          UnitPrice = qli2.UnitPrice
      );
      orderItemList.add(testOrderItem2);

      insert orderItemList;


      Test.startTest();

      List<Site__c> sites = [SELECT id, TypeOfNetwork__c, ConnectionBandwidth__c, DataCenterLocation__c, VerifiedServiceProvider__c FROM Site__c];
      for( Site__c site : sites ) {
        site.TypeOfNetwork__c = 'CloudConnect - Custom';
        site.ConnectionBandwidth__c = 1000;
        site.DataCenterLocation__c = 'Amsterdam, Netherlands (Telecity AMS5)';
        site.VerifiedServiceProvider__c = 'BICS';
      }
      update sites;
      System.debug('sites >>> ' + sites.size());

      testOrder.Status = 'Activated';
      update testOrder;

      Test.stopTest();

      Order ord = [SELECT Id, Status, NumberOfSites__c, TotalBandwidthOnQuote__c, TotalBandwidthOnOrder__c FROM Order LIMIT 1];
      System.debug('ord >>> ' + ord);

      System.assert( ord.NumberOfSites__c == qli1.Quantity, ord.NumberOfSites__c + '!=' + qli1.Quantity);
      System.assert( ord.TotalBandwidthOnQuote__c == qli2.Quantity * 0.2, ord.TotalBandwidthOnQuote__c + '!=' + qli2.Quantity * 0.2);
      System.assert( ord.TotalBandwidthOnOrder__c == qli1.Quantity * sites.get(0).ConnectionBandwidth__c / 1000, ord.TotalBandwidthOnOrder__c + '!=' + qli1.Quantity * sites.get(0).ConnectionBandwidth__c / 1000 );

    }
  }

  @IsTest
  static void test_phase_autocreation() {

    System.runAs(testUser) {

      Account testAcc = new Account(
          Name = 'testAcc',
          InContact_Service__c = 'Contact Center Basic',
          No_of_InContact_Seats__c = 3,
          RC_User_ID__c = '23232'
      );
      insert testAcc;

      Contact testContact = new Contact(
          Account = testAcc,
          LastName = 'Test',
          Preferred_Language__c = 'en_US',
          Email = 'test@test.com',
          Phone = '7777777',
          CurrencyIsoCode = 'USD'
      );
      insert testContact;

      Opportunity opp = new Opportunity(
          Name = 'Test Opportunity 2017',
          Type = 'Existing Business',
          Sales_Model__c = 'Direct',
          Brand_Name__c = 'RingCentral',
          Tier_Name__c = 'Professional',
          Primary_Opportunity_Contact__c = testContact.Id,
          StageName = '1. Qualify',
          CloseDate = System.today(),
          CurrencyIsoCode = 'USD'
      );
      insert opp;


      List<Product2> productList = new List<Product2>();

      Product2 testProduct1 = new Product2(
          Name = 'CloudConnect ProServ Setup',
          IsActive = true,
          Sub_Category__c = 'Professional Services',
          Charge_Term__c = 'Annual'
      );
      productList.add(testProduct1);

      Product2 testProduct2 = new Product2(
          Name = 'CloudConnect - Standard 200 Mbps',
          IsActive = true,
          Sub_Category__c = 'Professional Services',
          Charge_Term__c = 'Annual'
      );
      productList.add(testProduct2);

      insert productList;


      List<PriceBookEntry> pbeList = new List<PriceBookEntry>();

      PriceBookEntry testPBE1 = new PriceBookEntry(
          Pricebook2Id = Test.getStandardPricebookId(),
          IsActive = true,
          UnitPrice = 1000,
          Product2Id = testProduct1.Id
      );
      pbeList.add(testPBE1);

      PriceBookEntry testPBE2 = new PriceBookEntry(
          Pricebook2Id = Test.getStandardPricebookId(),
          IsActive = true,
          UnitPrice = 2000,
          Product2Id = testProduct2.Id
      );
      pbeList.add(testPBE2);

      insert pbeList;


      Quote testQuote = new Quote(
          Name = 'testQuote',
          OpportunityId = opp.id,
          Pricebook2Id = Test.getStandardPricebookId(),
          Products__c = 'Professional Services',
          RecordTypeId = [SELECT Id FROM RecordType WHERE SobjectType = 'Quote' AND Name = 'ProServ Quote'].Id,
          Number_of_ProServ_Phases__c = 3,
          Number_of_Hardware_Shipment_Phases__c = 2
      );
      insert testQuote;


      List<QuoteLineItem> qliList = new List<QuoteLineItem>();

      QuoteLineItem qli1 = new QuoteLineItem(
          QuoteId = testQuote.Id,
          Product2Id = testProduct1.Id,
          Quantity = 2,
          UnitPrice = testPBE1.UnitPrice,
          PricebookEntryId = testPBE1.Id
      );
      qliList.add(qli1);

      QuoteLineItem qli2 = new QuoteLineItem(
          QuoteId = testQuote.Id,
          Product2Id = testProduct2.Id,
          Quantity = 10,
          UnitPrice = testPBE2.UnitPrice,
          PricebookEntryId = testPBE2.Id
      );
      qliList.add(qli2);

      insert qliList;

      Map<String, Schema.RecordTypeInfo> orderRTInfoByNameMap = Order.SObjectType.getDescribe().getRecordTypeInfosByName();

      Id rcRecTypeId = orderRTInfoByNameMap.get('RingCentral').getRecordTypeId();
      Id proServRecTypeId = orderRTInfoByNameMap.get('Professional Services').getRecordTypeId();


      List<Order> orderList = new List<Order>();

      Order proServOrder = new Order(
        AccountId = testAcc.Id,
        EffectiveDate = System.today(),
        Provision_Date__c = System.today(),
        Pricebook2Id = Test.getStandardPricebookId(),
        QuoteId = testQuote.Id,
        OpportunityId = opp.Id,
        RecordTypeId = proServRecTypeId,
        Status = 'New'
      );
      orderList.add(proServOrder);


      Order rcOrder = new Order(
        AccountId = testAcc.Id,
        EffectiveDate = System.today(),
        Provision_Date__c = System.today(),
        Pricebook2Id = Test.getStandardPricebookId(),
        QuoteId = testQuote.Id,
        OpportunityId = opp.Id,
        RecordTypeId = rcRecTypeId,
        Status = 'New'
      );
      orderList.add(rcOrder);


      Test.startTest();

        insert orderList;

        List<Phase__c> phaseList = [SELECT Id, Name, RecordTypeId FROM Phase__c];

        System.debug('phaseList.size() >>> ' + phaseList.size());
        System.debug('phaseList >>> ' + phaseList);

        Map<String, Schema.RecordTypeInfo> phaseRTInfoByNameStaticMap = Phase__c.sObjectType.getDescribe().getRecordTypeInfosByName();

        Id rcHardwarePhaseRTId = phaseRTInfoByNameStaticMap.get('RingCentral Hardware Phase').getRecordTypeId();
        Id proservPhaseRTId = phaseRTInfoByNameStaticMap.get('ProServ Phase').getRecordTypeId();

        System.assert( phaseList.size() == (testQuote.Number_of_ProServ_Phases__c + testQuote.Number_of_Hardware_Shipment_Phases__c) );

        List<Phase__c> rcPhasesList = new List<Phase__c>();
        List<Phase__c> proServPhasesList = new List<Phase__c>();

        for(Phase__c item : phaseList) {

          if(item.RecordTypeId == rcHardwarePhaseRTId) {
            rcPhasesList.add(item);
          }else if(item.RecordTypeId == proservPhaseRTId) {
            proServPhasesList.add(item);
          }
        }

        System.assert( rcPhasesList.size() == testQuote.Number_of_Hardware_Shipment_Phases__c );
        System.assert( proServPhasesList.size() == testQuote.Number_of_ProServ_Phases__c );

      Test.stopTest();
    }
  }

  @IsTest
  static void test_TotalBandwithPopulation() {

    System.runAs(testUser) {
      Triggers.switchOff();

      Account testAcc = new Account(
          Name = 'testAcc',
          InContact_Service__c = 'Contact Center Basic',
          No_of_InContact_Seats__c = 3,
          RC_User_ID__c = '23232'
      );
      insert testAcc;

      Contact testContact = new Contact(
          Account = testAcc,
          LastName = 'Test',
          Preferred_Language__c = 'en_US',
          Email = 'test@test.com',
          Phone = '7777777',
          CurrencyIsoCode = 'USD'
      );
      insert testContact;

      Opportunity opp = new Opportunity(
          Name = 'Test Opportunity 2017',
          Type = 'Existing Business',
          Sales_Model__c = 'Direct',
          Brand_Name__c = 'RingCentral',
          Tier_Name__c = 'Professional',
          Primary_Opportunity_Contact__c = testContact.Id,
          StageName = '1. Qualify',
          CloseDate = System.today(),
          CurrencyIsoCode = 'USD'
      );
      insert opp;


      Id proServRecTypeId = Order.SObjectType.getDescribe().getRecordTypeInfosByName().get('Professional Services').getRecordTypeId();

      Product2 testProduct1 = new Product2(
          Name = 'testProduct1',
          IsActive = true,
          Sub_Category__c = 'Professional Services',
          Charge_Term__c = 'Monthly - Contract'
      );
      insert testProduct1;

      PricebookEntry testPBE1 = new PricebookEntry(
          Pricebook2Id = Test.getStandardPricebookId(),
          IsActive = true,
          UnitPrice = 1000,
          Product2Id = testProduct1.Id
      );
      insert testPBE1;

      Product2 testProduct2 = new Product2(
          Name = 'testProduct2',
          IsActive = true,
          Sub_Category__c = 'Professional Services',
          Charge_Term__c = 'Monthly - Contract'
      );
      insert testProduct2;

      PricebookEntry testPBE2 = new PricebookEntry(
          Pricebook2Id = Test.getStandardPricebookId(),
          IsActive = true,
          UnitPrice = 2000,
          Product2Id = testProduct2.Id
      );
      insert testPBE2;

      Quote testQuote = new Quote(
          Name = 'testQuote',
          OpportunityId = opp.id,
          Pricebook2Id = Test.getStandardPricebookId()
      );
      insert testQuote;


      List<QuoteLineItem> qliList = new List<QuoteLineItem>();

      QuoteLineItem qli1 = new QuoteLineItem(
          QuoteId = testQuote.Id,
          Product2Id = testProduct1.Id,
          Quantity = 2,
          UnitPrice = testPBE1.UnitPrice,
          PricebookEntryId = testPBE1.Id
      );
      qliList.add(qli1);

      QuoteLineItem qli2 = new QuoteLineItem(
          QuoteId = testQuote.Id,
          Product2Id = testProduct2.Id,
          Quantity = 10,
          UnitPrice = testPBE2.UnitPrice,
          PricebookEntryId = testPBE2.Id
      );
      qliList.add(qli2);

      insert qliList;
      Triggers.switchOn();


      Emails__c email = new Emails__c(
          Name = 'proservsow',
          Email_Address__c = 'test@test.com'
      );
      insert email;

      Order testOrder = new Order(
          AccountId = testAcc.Id,
          Status = 'New',
          EffectiveDate = System.today(),
          inContact_Cluster__c = 'C20',
          inContact_account_ID__c = 'testInContactAccountId',
          Provision_Date__c = System.today(),
          Pricebook2Id = Test.getStandardPricebookId(),
          QuoteId = testQuote.Id,
          OpportunityId = opp.Id,
          RecordTypeId = proServRecTypeId
      );
      insert testOrder;


      List<OrderItem> orderItemList = new List<OrderItem>();

      OrderItem testOrderItem1 = new OrderItem(
          OrderId = testOrder.Id,
          PricebookEntryId = testPBE1.Id,
          Quantity = qli1.Quantity,
          UnitPrice = qli1.UnitPrice
      );
      orderItemList.add(testOrderItem1);

      OrderItem testOrderItem2 = new OrderItem(
          OrderId = testOrder.Id,
          PricebookEntryId = testPBE2.Id,
          Quantity = qli2.Quantity,
          UnitPrice = qli2.UnitPrice
      );
      orderItemList.add(testOrderItem2);

      insert orderItemList;


      Test.startTest();

        Order reseletedOrder = [SELECT Id, Status, NumberOfSites__c, TotalBandwidthOnQuote__c, TotalBandwidthOnOrder__c FROM Order WHERE Id = :testOrder.Id];

        System.assertEquals(reseletedOrder.Status, 'Submitted');
        System.assertEquals(reseletedOrder.TotalBandwidthOnQuote__c, reseletedOrder.TotalBandwidthOnOrder__c);
        System.assertEquals(reseletedOrder.NumberOfSites__c, 0.0);


        testOrder.Status = 'Activated';
        update testOrder;

      Test.stopTest();

      Order ord = [SELECT Id, Status, NumberOfSites__c, TotalBandwidthOnQuote__c, TotalBandwidthOnOrder__c FROM Order WHERE Id = :testOrder.Id];

      System.assertEquals(ord.Status, 'Project Completed');
      System.assertEquals(ord.TotalBandwidthOnQuote__c, ord.TotalBandwidthOnOrder__c);
      System.assertEquals(ord.NumberOfSites__c, 0.0);

    }
  }

  //Is used to check if phases are properly mapped to orders
  @IsTest
  static void test_MapPhaseToOrder() {
    //Create basic test objects
    Account testAcc = new Account(
        Name = 'testAccount'
    );
    insert testAcc;

    Opportunity testOpp = new Opportunity(
        Name = 'MyTestOpportunity',
        Type = 'Existing Business',
        Brand_Name__c = 'RingCentral',
        Tier_Name__c = 'Professional',
        StageName = '1. Qualify',
        CloseDate = System.today(),
        CurrencyIsoCode = 'USD'
    );
    insert testOpp;

    Quote proservTestQuote = new Quote (Name='proservTestQuote',
        OpportunityId = testOpp.Id,
        Pricebook2Id = Test.getStandardPricebookId(),
        RecordTypeId = QuoteHelper.RT_ID_CC_PROSERV,
        ProServ_Status__c = 'In Progress');
    insert (new List<Quote>{proservTestQuote});
    //Create a couple of products
    Product2 testProservProduct1 = new Product2(
            Name = 'TestProserv1',
            Family = 'Add - Ons',
            Charge_Term__c = 'One - Time',
            IsActive = true,
            Sub_Category__c = 'Professional Services'
    );
    Product2 testProservProduct2 = new Product2(
            Name = 'TestProserv2',
            Family = 'Add - Ons',
            Charge_Term__c = 'One - Time',
            IsActive = true,
            Sub_Category__c = 'Professional Services'
    );
    insert (new List<Product2>{testProservProduct1,testProservProduct2});
    //Create proce book entries for them
    PricebookEntry testPrice1 = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = testProservProduct1.Id,
            UnitPrice = 50,
            IsActive = true,
            UseStandardPrice = false,
            Per_Line__c = false,
            Min_Quantity__c = 1,
            Max_Quantity__c = 100
    );
    PricebookEntry testPrice2 = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = testProservProduct2.Id,
            UnitPrice = 50,
            IsActive = true,
            UseStandardPrice = false,
            Per_Line__c = false,
            Min_Quantity__c = 1,
            Max_Quantity__c = 100
    );
    insert (new List<PricebookEntry>{testPrice1, testPrice2});
    //Create quote line items
    QuoteLineItem qli1 = new QuoteLineItem (
            ServiceDate = Date.today(),
            Description = 'TestLineItem1',
            Quantity = 3,
            QuoteId = proservTestQuote.Id,
            UnitPrice = 50,
            Product2Id = testProservProduct1.Id,
            PricebookEntryId = testPrice1.Id
    );
    QuoteLineItem qli2 = new QuoteLineItem (
            ServiceDate = Date.today(),
            Description = 'TestLineItem2',
            Quantity = 3,
            QuoteId = proservTestQuote.Id,
            UnitPrice = 50,
            Product2Id = testProservProduct2.Id,
            PricebookEntryId = testPrice2.Id
    );

    Test.startTest();
    insert (new List<QuoteLineItem>{qli1, qli2});
    //Create phases
    Phase__c testPhase1 = new Phase__c(
        Name = 'testPhase1',
        RecordTypeId = Schema.SObjectType.Phase__c.getRecordTypeInfosByName().get('ProServ Phase').getRecordTypeId(),
        Quote__c = proservTestQuote.Id
    );
    Phase__c testPhase2 = new Phase__c(
        Name = 'testPhase2',
        RecordTypeId = Schema.SObjectType.Phase__c.getRecordTypeInfosByName().get('ProServ Phase').getRecordTypeId(),
        Quote__c = proservTestQuote.Id
    );
    insert (new List<Phase__c>{testPhase1, testPhase2});

    //Before orders are created lookUp should be empty
    System.assertEquals(testPhase1.Order__c,null);
    System.assertEquals(testPhase2.Order__c,null);

    Order testOrder = new Order(
        AccountId = testAcc.Id,
        QuoteId = proservTestQuote.Id,
        OpportunityId = testOpp.Id,
        Pricebook2Id = Test.getStandardPricebookId(),
        EffectiveDate = System.today(),
        Status = 'Requested',
        RecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByName().get('Professional Services').getRecordTypeId()
    );
    insert (new List<Order>{testOrder});
    //Check if lookUp on order is populated correctly
    Phase__c updatedPhase = [SELECT Id, Order__c FROM Phase__c WHERE Quote__c =: proservTestQuote.Id LIMIT 1];
    System.assertEquals(testOrder.Id, updatedPhase.Order__c);
  }

  //Is used to check if email messages were send
  @IsTest
  static void test_SendMessages() {

    //Create Emails__c custom setting
    Emails__c cs = new Emails__c (Name = 'proservleaders', Email_Address__c = 'test@gmail.com');
    insert cs;
    //Create basic test objects
    Account testAcc = new Account(
        Name = 'testAccount',
        Number_of_DL_s__c = 123
    );
    insert testAcc;

    Contact testCont = new Contact(
        Account = testAcc,
        LastName = 'Test'
    );
    insert testCont;

    Opportunity testOpp = new Opportunity(
        Name = 'MyTestOpportunity',
        Type = 'Existing Business',
        Brand_Name__c = 'RingCentral',
        Tier_Name__c = 'Professional',
        StageName = '1. Qualify',
        CloseDate = System.today(),
        CurrencyIsoCode = 'USD',
        Primary_Opportunity_Contact__c = testCont.Id,
        AccountId = testAcc.Id
    );
    insert testOpp;

    Quote proservTestQuote = new Quote (Name='proservTestQuote',
        OpportunityId = testOpp.Id,
        Pricebook2Id = Test.getStandardPricebookId(),
        RecordTypeId = QuoteHelper.RT_ID_PROSERV,
        Total_Number_of_Digital_Lines__c = 123
    );

    Quote rcTestQuote = new Quote (Name='rcTestQuote',
        OpportunityId = testOpp.Id,
        Pricebook2Id = Test.getStandardPricebookId(),
        RecordTypeId = QuoteHelper.RT_ID_SALES
    );
    insert (new List<Quote>{proservTestQuote, rcTestQuote});
    //Create a couple of products
    Product2 testProservProduct1 = new Product2(
        Name = 'TestProserv1',
        Family = 'Add - Ons',
        Charge_Term__c = 'One - Time',
        IsActive = true,
        Sub_Category__c = 'Professional Services'
    );
    Product2 testProservProduct2 = new Product2(
        Name = 'TestProserv2',
        Family = 'Add - Ons',
        Charge_Term__c = 'One - Time',
        IsActive = true,
        Sub_Category__c = 'Professional Services'
    );
    Product2 testRcProduct = new Product2(
        Name = 'TestRcProduct',
        Family = 'Service',
        IsActive = true,
        Sub_Category__c = 'Main'
    );
    insert (new List<Product2>{testProservProduct1, testProservProduct2, testRcProduct});
    //Create proce book entries for them
    PricebookEntry testPrice1 = new PricebookEntry(
        Pricebook2Id = Test.getStandardPricebookId(),
        Product2Id = testProservProduct1.Id,
        UnitPrice = 50,
        IsActive = true,
        UseStandardPrice = false,
        Per_Line__c = false,
        Min_Quantity__c = 1,
        Max_Quantity__c = 100
    );
    PricebookEntry testPrice2 = new PricebookEntry(
        Pricebook2Id = Test.getStandardPricebookId(),
        Product2Id = testProservProduct2.Id,
        UnitPrice = 50,
        IsActive = true,
        UseStandardPrice = false,
        Per_Line__c = false,
        Min_Quantity__c = 1,
        Max_Quantity__c = 100
    );
    PricebookEntry testPrice3 = new PricebookEntry(
        Pricebook2Id = Test.getStandardPricebookId(),
        Product2Id = testRcProduct.Id,
        UnitPrice = 500,
        IsActive = true,
        UseStandardPrice = false,
        Per_Line__c = false,
        Min_Quantity__c = 1,
        Max_Quantity__c = 100
    );
    insert (new List<PricebookEntry>{testPrice1, testPrice2, testPrice3});
    //Create quote line items
    QuoteLineItem qli1 = new QuoteLineItem (
        ServiceDate = Date.today(),
        Description = 'TestLineItem1',
        Quantity = 3,
        QuoteId = proservTestQuote.Id,
        UnitPrice = testPrice1.UnitPrice,
        Product2Id = testProservProduct1.Id,
        PricebookEntryId = testPrice1.Id
    );
    QuoteLineItem qli2 = new QuoteLineItem (
        ServiceDate = Date.today(),
        Description = 'TestLineItem2',
        Quantity = 3,
        QuoteId = proservTestQuote.Id,
        UnitPrice = testPrice2.UnitPrice,
        Product2Id = testProservProduct2.Id,
        PricebookEntryId = testPrice2.Id
    );
    QuoteLineItem qli3 = new QuoteLineItem (
        ServiceDate = Date.today(),
        Description = 'TestLineItem3',
        Quantity = 3,
        QuoteId = rcTestQuote.Id,
        UnitPrice = testPrice3.UnitPrice,
        Product2Id = testRcProduct.Id,
        PricebookEntryId = testPrice3.Id
    );

    Test.startTest();
    insert (new List<QuoteLineItem>{qli1, qli2, qli3});

    Order testProservOrder = new Order(
        AccountId = testAcc.Id,
        QuoteId = proservTestQuote.Id,
        OpportunityId = testOpp.Id,
        Pricebook2Id = Test.getStandardPricebookId(),
        EffectiveDate = System.today(),
        Status = 'Submitted',
        RecordTypeId = OrderHelper.RT_ID_PROSERV
    );
    Order testRcOrder = new Order(
        AccountId = testAcc.Id,
        QuoteId = rcTestQuote.Id,
        OpportunityId = testOpp.Id,
        Pricebook2Id = Test.getStandardPricebookId(),
        EffectiveDate = System.today(),
        Status = 'Submitted',
        RecordTypeId = OrderHelper.RT_ID_RC
    );

    Integer emailInvocations = null;

    try{
        insert (new List<Order>{testProservOrder, testRcOrder});

        emailInvocations = Limits.getEmailInvocations();

    }catch(Exception ex) {
        ExceptionHelper.checkIsMassEmailException(ex);
        return;
    }

    Test.stopTest();

    System.assertEquals(1, emailInvocations, 'An email has not been sent');
  }

  /*
  *  Verify that orders get 'Completed' Status only if all related Phases has not empty
  *  Completed_Date__c and BillingStatus__c is 'Accepted'
  */
  @IsTest
  static void testCompleteOrder() {

    Product2 testProServProduct = new Product2(
        Name = 'TestProserv1',
        Family = 'Add - Ons',
        Charge_Term__c = 'One - Time',
        IsActive = true,
        Sub_Category__c = 'Professional Services'
    );
    insert testProServProduct;

    PricebookEntry testPBE = new PricebookEntry(
        Pricebook2Id = Test.getStandardPricebookId(),
        Product2Id = testProServProduct.Id,
        UnitPrice = 500,
        IsActive = true,
        UseStandardPrice = false,
        Per_Line__c = false,
        Min_Quantity__c = 1,
        Max_Quantity__c = 100
    );
    insert testPBE;

    Account testAcc = new Account(
        Name = 'testAccount',
        Number_of_DL_s__c = 123
    );
    insert testAcc;

    Opportunity testOpp = new Opportunity(
        Name = 'MyTestOpportunity',
        Type = 'Existing Business',
        Brand_Name__c = 'RingCentral',
        Tier_Name__c = 'Professional',
        StageName = '1. Qualify',
        CloseDate = System.today(),
        CurrencyIsoCode = 'USD',
        AccountId = testAcc.Id
    );
    insert testOpp;

    Test.startTest();

    Quote proservTestQuote = new Quote(
        Name='proservTestQuote',
        OpportunityId = testOpp.Id,
        Pricebook2Id = Test.getStandardPricebookId(),
        RecordTypeId = QuoteHelper.RT_ID_PROSERV
    );
    insert proservTestQuote;

    QuoteLineItem testQLI = new QuoteLineItem (
        ServiceDate = Date.today(),
        Description = 'TestQli',
        Quantity = 1,
        QuoteId = proservTestQuote.Id,
        UnitPrice = testPBE.UnitPrice,
        Product2Id = testProServProduct.Id,
        PricebookEntryId = testPBE.Id
    );
    insert testQLI;

    Order testProServOrder = new Order(
        AccountId = testAcc.Id,
        QuoteId = proservTestQuote.Id,
        OpportunityId = testOpp.Id,
        Pricebook2Id = Test.getStandardPricebookId(),
        EffectiveDate = System.today(),
        Status = 'Submitted',
        RecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByName().get('Professional Services').getRecordTypeId()
    );
    insert testProServOrder;

    OrderItem oi = new OrderItem(
        OrderId = testProServOrder.Id,
        Quantity = 1,
        UnitPrice = testQLI.UnitPrice,
        PricebookEntryId = testPBE.Id,
        QuoteLineItemId = testQLI.Id
    );
    insert oi;

        Phase__c testPhase = new Phase__c(
            Name = 'testPhase',
            Order__c = testProServOrder.Id,
            RecordTypeId = Schema.SObjectType.Phase__c.getRecordTypeInfosByName().get('ProServ Phase').getRecordTypeId(),
            Quote__c = proservTestQuote.Id,
            Completed_Date__c = Datetime.now()
        );
        insert testPhase;

        Order reselectedOrder = [SELECT Id, Status FROM Order WHERE Id = :testProServOrder.Id];
        System.assertEquals(reselectedOrder.Status, 'Submitted');

        testPhase.Initial_Payment__c = 50;
        testPhase.BillingStatus__c = 'Accepted';
        update testPhase;

        // if all related phases has not empty Completed_Date__c and BillingStatus__c is 'Accepted' - order should become 'Completed'
        reselectedOrder = [SELECT Id, Status FROM Order WHERE Id = :testProServOrder.Id];
        System.assertEquals(reselectedOrder.Status, 'Completed');

    Test.stopTest();
  }

    @IsTest
    private static void testUpdateRelatedOrderPhase() {
        Triggers.switchOff();
        User us = (User) new SObjectBuilder (User.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    User.LastName => 'TestTest123',
                    User.Username => 'Test123!user@gmail.com',
                    User.Email => 'Test123_user@gmail.com',
                    User.Alias => 'Test',
                    User.TimeZoneSidKey => 'America/Los_Angeles',
                    User.ManagerId => UserInfo.getUserId(),
                    User.LocaleSidKey => 'en_US',
                    User.EmailEncodingKey => 'UTF-8',
                    User.ProfileId => [SELECT Id, Name FROM Profile WHERE Name = 'System Administrator'].Id,
                    User.LanguageLocaleKey => 'en_US',
                    User.Hierarchy_Role__c => 'Sales Rep',
                    User.Division => OpportunityHelper.USER_DIVISION_SALES_ENTERPRISE
                }
            )
            .create()
            .getRecord();
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Current_Owner__c => us.Id,
                    Account.Name => 'testAcc',
                    Account.Current_Owner_Name__c => TEST_STRING,
                    Account.RC_User_ID__c => us.Id,
                    Account.Sales_Segment__c => TEST_STRING
                }
            )
            .create()
            .getRecord();
        Contact contact = (Contact) new SObjectBuilder(Contact.SObjectType)
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
        DateTime dateNow = System.now();
        Opportunity oppty = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.Name => 'Test Opportunity 2016',
                    Opportunity.Type => 'Syndicated - New',
                    Opportunity.StageName => 'Planning',
                    Opportunity.CloseDate => Date.newinstance(dateNow.year(), dateNow.month(), dateNow.day()),
                    Opportunity.AccountId => acc.Id,
                    Opportunity.Primary_Opportunity_Contact__c => contact.Id,
                    Opportunity.EstimatedProfessionalServices12Month__c => 10
                    }
                )
            .create()
            .getRecord();
        PriceBook2 pB2 = (PriceBook2) new SObjectBuilder(PriceBook2.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    PriceBook2.Name => 'Test Price Book',
                    PriceBook2.Description => 'Test Price Book Products',
                    PriceBook2.IsActive => true,
                    PriceBook2.Line_Range_Min__c => 5,
                    PriceBook2.Service__c => 'Office'
                }
            )
            .create()
            .getRecord();
        Quote q = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.Name => 'quotetest',
                    Quote.OpportunityId => oppty.Id,
                    Quote.Total_Number_of_Digital_Lines__c => 10,
                    Quote.Account__c => oppty.AccountId,
                    Quote.ProServ_Sold_Date__c => System.now(),
                    Quote.ProServSalesRep__c => us.Id,
                    Quote.Pricebook2Id => pB2.Id
                }
            )
            .create()
            .getRecord();
        Order ord = (Order) new SObjectBuilder(Order.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Order.Status => 'New',
                    Order.RecordTypeId => OrderHelper.RT_ID_CC_PROSERV,
                    Order.Signed_SOW__c => TEST_STRING,
                    Order.AccountId => acc.Id,
                    Order.EffectiveDate => Date.newinstance(dateNow.year(), dateNow.month(), dateNow.day())
                }
            )
            .create()
            .getRecord();
        insert new Feature_Toggle__c(Mavenlink_Integration__c = true);
        Phase__c phase = (Phase__c) new SObjectBuilder(Phase__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Phase__c.Status__c => 'New',
                    Phase__c.RecordTypeId => PhaseHelper.RT_INFO_BY_NAME.get('ProServ Phase').getRecordTypeId(),
                    Phase__c.Account__c => acc.Id,
                    Phase__c.Opportunity__c => oppty.Id,
                    Phase__c.Quote__c => q.Id,
                    Phase__c.Order__c => ord.Id,
                    Phase__c.Initial_Payment__c => 10
                }
            )
            .create()
            .getRecord();

        Triggers.switchOn();

        ord.SOW_Type__c = 'Single Phase';

        Test.startTest();
            update ord;
        Test.stopTest();

        phase = [SELECT MavenlinkIntegrationStatus__c
                FROM Phase__c
                WHERE Order__c = :ord.Id
                LIMIT 1];

        acc = [SELECT Professional_Services__c
                FROM Account
                WHERE Id = :acc.Id
                LIMIT 1];

        System.assert(!phase.MavenlinkIntegrationStatus__c.containsIgnoreCase('SOW Type'),
                        'SOW Type field on the Phase was updated incorrectly.');
        System.assertEquals(true, acc.Professional_Services__c);
    }

    @IsTest
    static void testPackageFieldsUpdateForNewBusiness() {
        Triggers.switchOff();
        TestDataGenerator.MultiproductStructure mpStruct = new TestDataGenerator.MultiproductStructure();
        Triggers.switchOn();

        List<QuoteLineItem> qliToUpdate = new List<QuoteLineItem>();
        for(List<QuoteLineItem> qliList : mpStruct.technicalQLIs.values()) {
            for (QuoteLineItem qli : qliList) {
                qli.ChargeTerm__c = QuoteLineItemHelper.CHARGE_TERM_MONTHLY;
                qliToUpdate.add(qli);
            }
        }

        Triggers.switchOff();
        TriggerHandler.BY_PASS_QUOTE_ON_CONVERT = true;
        update qliToUpdate;
        TriggerHandler.BY_PASS_QUOTE_ON_CONVERT = false;
        Triggers.switchOn();

        List<Order> orders = new List<Order>();
        for(Quote quote : mpStruct.serviceQuotes.values()) {
            if (mpStruct.technicalQLIs.get(quote.ServiceName__c).isEmpty()) {
                continue;
            }
            if(OrderHelper.SERVICE_NAME_TO_RT_ID.containsKey(quote.ServiceName__c)) {
                orders.add(OrderHelper.buildOrderForQuote(quote));
            }
        }

        insert orders;
        List<Account> accList = new List<Account> (mpStruct.serviceAccounts.values());
        accList.add(mpStruct.masterAccount);

        Map<Id, Package__c> accountIdToPackage = new Map<Id, Package__c>();

        for(Account acc : accList) {
            accountIdToPackage.put(acc.Id,
                new Package__c(
                    Name = 'Test package',
                    Account_Package_Id__c = '123' + acc.Id,
                    Enterprise_Account_ID__c = acc.Id,
                    Account__c = acc.Id,
                    NumberOfMainLicenses__c = 1
                )
            );
        }
        Triggers.switchOff();
        insert accountIdToPackage.values();
        Triggers.switchOn();

        Set<Id> accountIds = accountIdToPackage.keySet();

        Test.startTest();

        List<Order> ordersToActivate = (List<Order>) new OrderSelector()
            .selectNewOrdersByAccountIds(accountIds)
            .selectFields(
                new List<String>{
                   'Id',
                   'PackageId__c',
                   'Recurring_total__c',
                   'Quote.Opp_Type__c'
                }
            )
            .executeQuery();

        Set<Id> packageIds = new Set<Id>();

        for(Order order : ordersToActivate) {
            order.SeatMRR__c = 100;
            order.TransportMRR__c = 15;
            order.MinuteBundle__c = 13;
            order.NumberOfMainLicenses__c = 1;
            order.Status = OrderHelper.STATUS_ACTIVATED;
            packageIds.add(order.PackageId__c);
        }

        update ordersToActivate;

        Test.stopTest();

        Map<Id, Order> packageIdToOrder = new Map<Id, Order>();

        for(Order order : ordersToActivate) {
            packageIdToOrder.put(order.PackageId__c, order);
        }

        List<Package__c> packageList = (List<Package__c>) new PackageSelector()
            .selectPackagesById(packageIds)
            .selectFields(
                new List<String>{
                   'Id',
                   'AcquisitionMRR__c',
                   'Sales_Order_MRS__c',
                   'SeatMRR__c',
                   'TransportMRR__c',
                   'MinuteBundle__c',
                   'NumberOfMainLicenses__c'
                }
            )
            .executeQuery();

        for(Package__c bp : packageList) {
            Order relatedOrder = packageIdToOrder.get(bp.Id);
            System.assert(relatedOrder.Recurring_total__c == bp.Sales_Order_MRS__c, 'Sales_Order_MRS__c should be populated from order Recurring_total__c');
            System.assert(relatedOrder.SeatMRR__c == bp.SeatMRR__c, 'SeatMRR__c should be populated from order SeatMRR__c');
            System.assert(relatedOrder.TransportMRR__c == bp.TransportMRR__c, 'TransportMRR__c should be populated from order TransportMRR__c');
            System.assert(relatedOrder.MinuteBundle__c == bp.MinuteBundle__c, 'MinuteBundle__c should be populated from order MinuteBundle__c');

            if(relatedOrder.Quote.Opp_Type__c == OpportunityHelper.OPPORTUNITY_TYPE_NEW_BUSINESS) {
                System.assert(relatedOrder.Recurring_total__c == bp.AcquisitionMRR__c, 'AcquisitionMRR__c should be populated from order Recurring_total__c');
            }
        }
    }

    @IsTest
    static void testPopulateNumberOfMainLicensesOnPackage() {
        Triggers.switchOff();
        Account testAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Account.SObjectType))
            .create()
            .getRecord();

        Opportunity testOpp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setField(Opportunity.Name, 'MyTestOpportunity')
            .setField(Opportunity.Type, 'Existing Business')
            .setField(Opportunity.Brand_Name__c, 'RingCentral')
            .setField(Opportunity.Tier_Name__c, 'Professional')
            .setField(Opportunity.StageName, '1. Qualify')
            .setField(Opportunity.CloseDate, System.today())
            .setField(Opportunity.CurrencyIsoCode, 'USD')
            .setField(Opportunity.AccountId, testAcc.Id)
            .create()
            .getRecord();

        Product2 testProduct = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setField(Product2.Name, 'TestProserv1')
            .setField(Product2.Family, Product2Helper.FAMILY_ADDONS)
            .setField(Product2.Charge_Term__c, Product2Helper.CHARGE_TERM_ONE_TIME)
            .setField(Product2.IsActive, true)
            .setField(Product2.Sub_Category__c, Product2Helper.SUBCATEGORY_RINGCENTRAL)
            .create()
            .getRecord();

        PricebookEntry testPBE = (PricebookEntry) new SObjectBuilder(PricebookEntry.SObjectType)
            .setField(PricebookEntry.Pricebook2Id, Test.getStandardPricebookId())
            .setField(PricebookEntry.Product2Id, testProduct.Id)
            .setField(PricebookEntry.UnitPrice, 500)
            .setField(PricebookEntry.IsActive, true)
            .setField(PricebookEntry.UseStandardPrice, false)
            .setField(PricebookEntry.Per_Line__c, false)
            .setField(PricebookEntry.Min_Quantity__c, 1)
            .setField(PricebookEntry.Max_Quantity__c, 10)
            .create()
            .getRecord();

        Test.startTest();

        Quote testQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setField(Quote.Name, 'proservTestQuote')
            .setField(Quote.OpportunityId, testOpp.Id)
            .setField(Quote.Pricebook2Id, Test.getStandardPricebookId())
            .setField(Quote.RecordTypeId, QuoteHelper.RT_ID_PROSERV)
            .create()
            .getRecord();

        Package__c testPackage = (Package__c) new SObjectBuilder(Package__c.SObjectType)
            .setField(Package__c.Account__c, testAcc.Id)
            .setField(Package__c.Enterprise_Account_ID__c, testAcc.Id)
            .setField(Package__c.Account_Package_Id__c, '1')
            .create()
            .getRecord();

        QuoteLineItem testQLI = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setField(QuoteLineItem.ServiceDate, Date.today())
            .setField(QuoteLineItem.Description, 'TestQli')
            .setField(QuoteLineItem.Quantity, 1)
            .setField(QuoteLineItem.QuoteId, testQuote.Id)
            .setField(QuoteLineItem.UnitPrice, testPBE.UnitPrice)
            .setField(QuoteLineItem.Product2Id, testProduct.Id)
            .setField(QuoteLineItem.PricebookEntryId, testPBE.Id)
            .create()
            .getRecord();
            Triggers.switchOn();

        Order testOrder = (Order) new SObjectBuilder(Order.SObjectType)
            .setField(Order.AccountId, testAcc.Id)
            .setField(Order.QuoteId, testQuote.Id)
            .setField(Order.OpportunityId, testOpp.Id)
            .setField(Order.Pricebook2Id, Test.getStandardPricebookId())
            .setField(Order.EffectiveDate, System.today())
            .setField(Order.Status, 'Submitted')
            .setField(Order.NumberOfMainLicenses__c, 25)
            .setField(Order.PackageId__c, testPackage.Id)
            .create()
            .getRecord();

        OrderItem testOrderItem = (OrderItem) new SObjectBuilder(OrderItem.SObjectType)
            .setField(OrderItem.OrderId, testOrder.Id)
            .setField(OrderItem.PricebookEntryId, testPBE.Id)
            .setField(OrderItem.Quantity, testQLI.Quantity)
            .setField(OrderItem.UnitPrice, testQLI.UnitPrice)
            .create()
            .getRecord();

            testOrder.Status = OrderHelper.STATUS_ACTIVATED;
            update testOrder;
        Test.stopTest();

        Package__c updatedPackage = (Package__c) new PackageSelector()
            .selectPackagesById(new Set<Id> {testPackage.Id})
            .selectFields(new List<String> {'NumberOfMainLicenses__c'})
            .executeQuery()
            .get(0);

        System.assertEquals(testOrder.NumberOfMainLicenses__c, updatedPackage.NumberOfMainLicenses__c,
            'NumberOfMainLicenses__c should be equal on activated order and package');
    }

    @IsTest
    private static void testCreateOrderItemsForNewOrders() {
        Triggers.switchOff();
        Triggers.except('OrderAfterTriggerHandler.CreateOrderItemsForNewOrders');
        Account testAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Account.SObjectType))
            .create()
            .getRecord();

        Opportunity testOpp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setField(Opportunity.Name, 'MyTestOpportunity')
            .setField(Opportunity.Type, 'Existing Business')
            .setField(Opportunity.Brand_Name__c, 'RingCentral')
            .setField(Opportunity.Tier_Name__c, 'Office')
            .setField(Opportunity.StageName, '1. Qualify')
            .setField(Opportunity.CloseDate, System.today())
            .setField(Opportunity.CurrencyIsoCode, 'USD')
            .setField(Opportunity.AccountId, testAcc.Id)
            .create()
            .getRecord();

        List<Product2> testProduct = (List<Product2>) new SObjectBuilder(Product2.SObjectType)
            .setField(Product2.Name, ValueProviderBuilder.provideUniqueString('Product'))
            .setField(Product2.Family, Product2Helper.FAMILY_ADDONS)
            .setField(Product2.Charge_Term__c, Product2Helper.CHARGE_TERM_ONE_TIME)
            .setField(Product2.IsActive, true)
            .setField(Product2.Sub_Category__c, Product2Helper.SUBCATEGORY_RINGCENTRAL)
            .quantity(10)
            .create()
            .getRecords();

        List<PricebookEntry> testPBE = (List<PricebookEntry>) new SObjectBuilder(PricebookEntry.SObjectType)
            .setField(PricebookEntry.Pricebook2Id, Test.getStandardPricebookId())
            .setField(PricebookEntry.Product2Id, ValueProviderBuilder.provideParents(testProduct))
            .setField(PricebookEntry.UnitPrice, ValueProviderBuilder.providerRandomDecimal(100, 1000, 2))
            .setField(PricebookEntry.IsActive, true)
            .setField(PricebookEntry.UseStandardPrice, false)
            .setField(PricebookEntry.Per_Line__c, false)
            .setField(PricebookEntry.Min_Quantity__c, 1)
            .setField(PricebookEntry.Max_Quantity__c, ValueProviderBuilder.providerRandomDecimal(10, 100, 0))
            .quantity(10)
            .create()
            .getRecords();

        Quote testQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setField(Quote.Name, 'proservTestQuote')
            .setField(Quote.OpportunityId, testOpp.Id)
            .setField(Quote.Pricebook2Id, Test.getStandardPricebookId())
            .setField(Quote.Status, QuoteHelper.QUOTE_STATUS_ACTIVE)
            .setField(Quote.Start_Date__c, Date.today().addDays(1))
            .setField(Quote.End_Date__c, Date.today().addDays(30))
            .create()
            .getRecord();

        Package__c testPackage = (Package__c) new SObjectBuilder(Package__c.SObjectType)
            .setField(Package__c.Account__c, testAcc.Id)
            .setField(Package__c.Enterprise_Account_ID__c, testAcc.Id)
            .setField(Package__c.Account_Package_Id__c, '1')
            .create()
            .getRecord();

        List<QuoteLineItem> testQLI = (List<QuoteLineItem>) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setField(QuoteLineItem.ServiceDate, Date.today())
            .setField(QuoteLineItem.Description, ValueProviderBuilder.provideUniqueString('Test Quote Line Item'))
            .setField(QuoteLineItem.Quantity, ValueProviderBuilder.providerRandomDecimal(1, 10, 0))
            .setField(QuoteLineItem.QuoteId, testQuote.Id)
            .setField(QuoteLineItem.UnitPrice, ValueProviderBuilder.provideList(
                (List<Decimal>) AquivaHelper.collectFieldValues(
                    List<Decimal>.class,
                    testPBE,
                    'UnitPrice',
                    false
                )
            ))
            .setField(QuoteLineItem.Product2Id, ValueProviderBuilder.provideParents(testProduct))
            .setField(QuoteLineItem.PricebookEntryId, ValueProviderBuilder.provideParents(testPBE))
            .setField(QuoteLineItem.Zero_Quantity__c, ValueProviderBuilder.provideList(new List<Object> {
                false,
                false,
                false,
                false,
                false,
                false,
                false,
                false,
                true,
                true
            }))
            .quantity(10)
            .create()
            .getRecords();

        Triggers.switchOn();
        Test.startTest();
        Order testOrder = (Order) new SObjectBuilder(Order.SObjectType)
            .setField(Order.AccountId, testAcc.Id)
            .setField(Order.QuoteId, testQuote.Id)
            .setField(Order.OpportunityId, testOpp.Id)
            .setField(Order.Pricebook2Id, Test.getStandardPricebookId())
            .setField(Order.EffectiveDate, System.today())
            .setField(Order.Status, OrderHelper.STATUS_NEW)
            .setField(Order.NumberOfMainLicenses__c, 25)
            .setField(Order.PackageId__c, testPackage.Id)
            .setField(Order.TechnicalAccountId__c, testAcc.Id)
            .setField(Order.TechnicalOpportunityId__c, testOpp.Id)
            .setField(Order.TechnicalQuoteId__c, testQuote.Id)
            .create()
            .getRecord();

        List<OrderItem> testOrderItems = (List<OrderItem>) new OrderItemSelector()
            .selectOrderItemsByOrderId(testOrder.Id)
            .executeQuery();
        List<QuoteLineItem> reselectedTestQLI = (List<QuoteLineItem>) new QuoteLineItemSelector()
            .selectQuoteLineItems()
            .selectFields(new List<String>{
                'Quantity',
                'UnitPrice',
                'EffectivePrice__c',
                'Product2Id',
                'PricebookEntryId',
                'QuoteId'
            })
            .setCondition('Id IN :bind0')
            .setQueryBindings(new List<Object> {new Map<Id, QuoteLineItem>(testQLI).keySet()})
            .executeQuery();

        Map<Id, QuoteLineItem> quoteLineItemsByIds = new Map<Id, QuoteLineItem>(reselectedTestQLI);
        Map<Id, OrderItem> orderItemsByQLIIds = new Map<Id, OrderItem>();
        for (OrderItem ordItem : testOrderItems) {
            orderItemsByQLIIds.put(ordItem.QuoteLineItemId, ordItem);
        }

        System.assertEquals(
            testQLI.size(),
            testOrderItems.size(),
            'OrderItems should be created for all QuoteLineItems'
        );
        System.assert(
            orderItemsByQLIIds.keySet().containsAll(quoteLineItemsByIds.keySet()),
            'OrderItems should be created for all QuoteLineItems'
        );
        for (OrderItem ordItem : testOrderItems) {
            QuoteLineItem qli = quoteLineItemsByIds.get(ordItem.QuoteLineItemId);
            System.assertEquals(
                qli.Quantity,
                ordItem.Quantity,
                'OrderItem quantity should be equal to QuoteLineItem quantity'
            );
            System.assertEquals(
                qli.EffectivePrice__c,
                ordItem.UnitPrice,
                'OrderItem unit price should be equal to QuoteLineItem Effective price'
            );
            System.assertEquals(
                qli.UnitPrice,
                ordItem.UnitPriceWithoutDiscount__c,
                'OrderItem UnitPriceWithoutDiscount should be equal to QuoteLineItem unit price'
            );
            System.assertEquals(
                qli.Product2Id,
                ordItem.Product2Id,
                'OrderItem product should be equal to QuoteLineItem product'
            );
            System.assertEquals(
                qli.PricebookEntryId,
                ordItem.PricebookEntryId,
                'OrderItem pricebook entry should be equal to QuoteLineItem pricebook entry'
            );
        }
        Test.stopTest();
        Triggers.switchOn();
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @IsTest
    public static void testCreateOrderItemsForNewOrders_multiProductLite() {
        Triggers.switchOff();
        Triggers.except('OrderAfterTriggerHandler.CreateOrderItemsForNewOrders');
        TestDataGenerator.MultiproductStructure struct = new TestDataGenerator.MultiproductStructure();
        update new List<Quote>{
            new Quote(
                Id = struct.serviceQuotes.get(QuoteHelper.NGBS_OFFICE_PRODUCT).Id,
                QuoteType__c = QuoteHelper.QUOTE_TYPE_AGREEMENT,
                Status = QuoteHelper.QUOTE_STATUS_ACTIVE,
                ServiceName__c = QuoteHelper.NGBS_OFFICE_PRODUCT
            ),
            new Quote(
                Id = struct.serviceQuotes.get(QuoteHelper.NGBS_RCCC_PRODUCT).Id,
                QuoteType__c = QuoteHelper.QUOTE_TYPE_AGREEMENT,
                Status = QuoteHelper.QUOTE_STATUS_ACTIVE,
                ServiceName__c = QuoteHelper.NGBS_RCCC_PRODUCT
            ),
            new Quote(
                Id = struct.serviceQuotes.get(QuoteHelper.NGBS_ENGAGE_DIGITAL_PRODUCT).Id,
                QuoteType__c = QuoteHelper.QUOTE_TYPE_AGREEMENT,
                Status = QuoteHelper.QUOTE_STATUS_ACTIVE,
                ServiceName__c = QuoteHelper.NGBS_ENGAGE_DIGITAL_PRODUCT
            ),
            new Quote(
                Id = struct.serviceQuotes.get(QuoteHelper.NGBS_ENGAGE_VOICE_PRODUCT).Id,
                QuoteType__c = QuoteHelper.QUOTE_TYPE_AGREEMENT,
                Status = QuoteHelper.QUOTE_STATUS_ACTIVE,
                ServiceName__c = QuoteHelper.NGBS_ENGAGE_VOICE_PRODUCT
            )
        };
        IValueProvider billingIdProvider = ValueProviderBuilder.provideUniqueString('BID');
        IValueProvider rcUserIdProvider = ValueProviderBuilder.provideUniqueString('UID');

        update new List<Account> {
            new Account(
                Id = struct.masterAccount.Id,
                Billing_ID__c = (String) billingIdProvider.getValue(),
                RC_User_ID__c = (String) rcUserIdProvider.getValue()
            ),
            new Account(
                Id = struct.serviceAccounts.get(QuoteHelper.NGBS_RCCC_PRODUCT).Id,
                Billing_ID__c = (String) billingIdProvider.getValue(),
                RC_User_ID__c = (String) rcUserIdProvider.getValue()
            ),
            new Account(
                Id = struct.serviceAccounts.get(QuoteHelper.NGBS_ENGAGE_DIGITAL_PRODUCT).Id,
                Billing_ID__c = (String) billingIdProvider.getValue(),
                RC_User_ID__c = (String) rcUserIdProvider.getValue()
            ),
            new Account(
                Id = struct.serviceAccounts.get(QuoteHelper.NGBS_ENGAGE_VOICE_PRODUCT).Id,
                Billing_ID__c = (String) billingIdProvider.getValue(),
                RC_User_ID__c = (String) rcUserIdProvider.getValue()
            )
        };

        Test.startTest();
        List<Order> orders = (List<Order>) new SObjectBuilder(Order.SObjectType)
            .setField(Order.Pricebook2Id, Test.getStandardPricebookId())
            .setField(Order.EffectiveDate, System.today())
            .setField(Order.Status, OrderHelper.STATUS_NEW)
            .setField(Order.NumberOfMainLicenses__c, 25)
            .setField(Order.AccountId, ValueProviderBuilder.provideParents(
                new List<Account>{
                    struct.masterAccount,
                    struct.masterAccount,
                    struct.masterAccount
                }
            ))
            .setField(Order.OpportunityId, ValueProviderBuilder.provideParents(
                new List<Opportunity>{
                    struct.masterOpp,
                    struct.masterOpp,
                    struct.masterOpp
                }
            ))
            .setField(Order.QuoteId, ValueProviderBuilder.provideParents(
                new List<Quote>{
                    struct.masterQuote,
                    struct.masterQuote,
                    struct.masterQuote
                }
            ))
            .setField(Order.TechnicalAccountId__c, ValueProviderBuilder.provideParents(
                new List<Account>{
                    struct.masterAccount,
                    struct.masterAccount,
                    struct.serviceAccounts.get(QuoteHelper.NGBS_RCCC_PRODUCT)
                }
            ))
            .setField(Order.TechnicalOpportunityId__c, ValueProviderBuilder.provideParents(
                new List<Opportunity>{
                    struct.masterOpp,
                    struct.masterOpp,
                    struct.serviceOpportunities.get(QuoteHelper.NGBS_RCCC_PRODUCT)
                }
            ))
            .setField(Order.TechnicalQuoteId__c, ValueProviderBuilder.provideParents(
                new List<Quote>{
                    struct.masterQuote,
                    struct.serviceQuotes.get(QuoteHelper.NGBS_OFFICE_PRODUCT),
                    struct.serviceQuotes.get(QuoteHelper.NGBS_RCCC_PRODUCT)
                }
            ))
            .quantity(3)
            .create()
            .getRecords();
        Test.stopTest();
        Triggers.switchOn();

        List<Order> ordList = (List<Order>) new OrderSelector()
            .newQueryFactory()
            .selectFields(new Set<String> {
                'AccountId',
                'QuoteId',
                'Quote.ServiceName__c',
                'Quote.MasterQuote__c',
                'Quote.IsMultiProductTechnicalQuote__c',
                'OpportunityId',
                'Pricebook2Id',
                'TechnicalAccountId__c',
                'TechnicalOpportunityId__c',
                'TechnicalQuoteId__c'
            })
            .subselect(
                new OrderItemSelector('OrderItems', Order.SObjectType)
                    .selectOrderItems()
            )
            .setCondition('Id IN :bind0')
            .setQueryBindings(new List<Object>{ new Map<Id, Order>(orders).keySet() })
            .executeQuery();

        List<Quote> quotesWithItems = new QuoteSelector()
            .newQueryFactory()
            .selectFields(new List<String> {
                'Id',
                'AccountId',
                'Account.Id',
                'OpportunityId',
                'Opportunity.Id',
                'Pricebook2Id',
                'Pricebook2.Id',
                'MasterQuote__c',
                'IsMultiProductTechnicalQuote__c',
                'Name'
            })
            .subselect(
                new QuoteLineItemSelector('QuoteLineItems', Quote.SObjectType)
                    .selectNonZeroQuoteLineItems()
            )
            .subselect(
                new QuoteSelector('Master_Quotes__r', Quote.SObjectType)
                    .newQueryFactory()
                    .selectFields(new List<String> {
                        'Id',
                        'AccountId',
                        'Account.Id',
                        'OpportunityId',
                        'Opportunity.Id',
                        'Pricebook2Id',
                        'Pricebook2.Id',
                        'MasterQuote__c',
                        'IsMultiProductTechnicalQuote__c',
                        'Name'
                    })
            )
            .setCondition('Id IN :bind0 OR MasterQuote__c IN :bind0')
            .setQueryBindings(new List<Object>{
                new List<Id> {
                    struct.masterQuote.Id,
                    struct.serviceQuotes.get(QuoteHelper.NGBS_OFFICE_PRODUCT).Id,
                    struct.serviceQuotes.get(QuoteHelper.NGBS_RCCC_PRODUCT).Id,
                    struct.serviceQuotes.get(QuoteHelper.NGBS_ENGAGE_DIGITAL_PRODUCT).Id,
                    struct.serviceQuotes.get(QuoteHelper.NGBS_ENGAGE_VOICE_PRODUCT).Id
                }
            })
            .executeQuery();

        Map<Id, Order> ordersByTechQuoteId = new Map<Id, Order>();
        for (Order ord : ordList) {
            ordersByTechQuoteId.put(ord.TechnicalQuoteId__c, ord);
        }
        Map<Id, Quote> quotesByIds = new Map<Id, Quote>(quotesWithItems);

        System.assertEquals(false, quotesByIds.isEmpty(), 'Quotes should not be empty');
        System.assertEquals(false, ordersByTechQuoteId.isEmpty(), 'Orders should not be empty');
         for (Quote qt : quotesByIds.values()) {
             if (!ordersByTechQuoteId.containsKey(qt.Id)) {
                 continue;
             }

             Order ord = ordersByTechQuoteId.get(qt.Id);

             Map<Id, QuoteLineItem> quoteLineItemsByIds = new Map<Id, QuoteLineItem>(qt.QuoteLineItems);
             Map<Id, OrderItem> orderItemsByQliId = new Map<Id, OrderItem>();
             for (OrderItem oi : ord.OrderItems) {
                 orderItemsByQliId.put(oi.QuoteLineItemId, oi);
             }

             for (QuoteLineItem qli : qt.QuoteLineItems) {
                 if (qli.IsMultiProductTechnicalQLI__c) {
                     System.assertEquals(
                         true,
                         orderItemsByQliId.containsKey(qli.MasterQLI__c),
                         'OrderItem should be created for Master QLI'
                     );
                 } else {
                     System.assertEquals(
                         true,
                         orderItemsByQliId.containsKey(qli.Id),
                         'OrderItem should be created for QLI'
                     );
                 }
             }
         }
    }

    @IsTest
    private static void testCreateOrderItemsForNewOrders_singleProduct_withUnifiedBilling() {
        new SObjectBuilder(Feature_Toggle__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Feature_Toggle__c.EnableMultiProductUnifiedBilling__c => true
            })
            .create();

        Triggers.switchOff();
        Triggers.except('OrderAfterTriggerHandler.CreateOrderItemsForNewOrders');

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, 'Test Account')
            .quantity(1)
            .create()
            .getRecord();

        Package__c pkg = (Package__c) new SObjectBuilder(Package__c.SObjectType)
            .setField(Package__c.Account__c, acc.Id)
            .setField(Package__c.Account_Package_Id__c, '1231231231')
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setField(Opportunity.Name, 'Test Opportunity')
            .setField(Opportunity.AccountId, acc.Id)
            .setField(Opportunity.Tier_Name__c, QuoteHelper.NGBS_OFFICE_PRODUCT)
            .setField(Opportunity.Brand_Name__c, OpportunityHelper.BRAND_RINGCENTRAL)
            .setField(Opportunity.Type, OpportunityHelper.OPPORTUNITY_TYPE_EX_BUSINESS)
            .setField(Opportunity.RecordTypeId, OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY)
            .setField(Opportunity.StageName, OpportunityHelper.STAGE_NAME_QUALIFY)
            .setField(Opportunity.CloseDate, System.today())
            .setField(Opportunity.CurrencyIsoCode, RingCentralHelper.USD)
            .quantity(1)
            .create()
            .getRecord();

        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setField(Quote.Name, 'Test Quote')
            .setField(Quote.OpportunityId, opp.Id)
            .setField(Quote.BillingPackage__c, pkg.Id)
            .setField(Quote.CurrencyIsoCode, RingCentralHelper.USD)
            .setField(Quote.Pricebook2Id, Test.getStandardPricebookId())
            .setField(Quote.isPrimary__c, true)
            .setField(Quote.IsMultiProductTechnicalQuote__c, false)
            .setField(Quote.Package_Info__c, NGBSTestDataGenerator.generateQuotePackageInfo())
            .quantity(1)
            .create()
            .getRecord();

        List<Product2> prodList = (List<Product2>) new SObjectBuilder(Product2.sObjectType)
            .setField(Product2.Name, 'Test product')
            .setField(Product2.Sub_Category__c, Product2Helper.SUBCATEGORY_RINGCENTRAL)
            .setField(Product2.IsActive, true)
            .setField(Product2.Charge_Term__c, Product2Helper.CHARGE_TERM_MONTHLY)
            .setField(Product2.UpsellType__c, ValueProviderBuilder.provideList(
                new List<String>{
                    Product2Helper.PRODUCT_PROVISIONING_TYPE_AUTO_WITH_CASE,
                    'manual',
                    'testUpsellType',
                    null
                }
            ))
            .quantity(4)
            .create()
            .getRecords();

        List<PricebookEntry> pbeList = new SObjectBuilder(PricebookEntry.SObjectType)
            .setField(PricebookEntry.Pricebook2Id, Test.getStandardPricebookId())
            .setField(PricebookEntry.Product2Id, ValueProviderBuilder.provideParents(prodList))
            .setField(PricebookEntry.UnitPrice, 10)
            .setField(PricebookEntry.IsActive, true)
            .setField(PricebookEntry.UseStandardPrice, false)
            .setField(PricebookEntry.CurrencyIsoCode, 'USD')
            .quantity(4)
            .create()
            .getRecords();

        List<QuoteLineItem> qliList = (List<QuoteLineItem>) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setField(QuoteLineItem.QuoteId, qt.Id)
            .setField(QuoteLineItem.Product2Id, ValueProviderBuilder.provideParents(prodList))
            .setField(QuoteLineItem.PricebookEntryId, ValueProviderBuilder.provideParents(pbeList))
            .setField(QuoteLineItem.Quantity, 5)
            .setField(QuoteLineItem.UnitPrice, 10)
            .setField(QuoteLineItem.IsMultiProductTechnicalQLI__c, false)
            .quantity(4)
            .create()
            .getRecords();

        Test.startTest();
        List<Order> orderList = (List<Order> ) new SObjectBuilder(Order.SObjectType)
            .setField(Order.AccountId, acc.Id)
            .setField(Order.QuoteId, qt.Id)
            .setField(Order.OpportunityId, opp.Id)
            .setField(Order.Pricebook2Id, Test.getStandardPricebookId())
            .setField(Order.EffectiveDate, System.today())
            .setField(Order.Status, OrderHelper.STATUS_NEW)
            .setField(Order.NumberOfMainLicenses__c, 25)
            .setField(Order.TechnicalAccountId__c, acc.Id)
            .setField(Order.TechnicalOpportunityId__c, opp.Id)
            .setField(Order.TechnicalQuoteId__c, qt.Id)
            .setField(Order.Provisioning__c, ValueProviderBuilder.provideList(
                new List<String>{
                    OrderHelper.PROVISIONING_AUTO,
                    OrderHelper.PROVISIONING_MANUAL
                }
            ))
            .quantity(2)
            .create()
            .getRecords();
        Test.stopTest();

        Triggers.switchOn();

        List<OrderItem> testOrderItems = (List<OrderItem>) new OrderItemSelector()
            .selectOrderItemsByOrderIds(new List<Object>{orderList})
            .executeQuery();

        Map<Id, QuoteLineItem> quoteLineItemsByIds = new Map<Id, QuoteLineItem>(qliList);
        Map<Id, OrderItem> orderItemsByQLIIds = new Map<Id, OrderItem>();
        for (OrderItem ordItem : testOrderItems) {
            orderItemsByQLIIds.put(ordItem.QuoteLineItemId, ordItem);
        }

        System.assertEquals(
            qliList.size(),
            testOrderItems.size(),
            'OrderItems should be created for all QuoteLineItems'
        );
        System.assert(
            orderItemsByQLIIds.keySet().containsAll(quoteLineItemsByIds.keySet()),
            'OrderItems should be created for all QuoteLineItems'
        );

        Map<Id, List<OrderItem>> orderIdToOrderItems = new  Map<Id, List<OrderItem>>();
        for (OrderItem orderItem : testOrderItems) {
            if (!orderIdToOrderItems.containsKey(orderItem.OrderId)) {
                orderIdToOrderItems.put(orderItem.OrderId, new List<OrderItem>());
            }
            orderIdToOrderItems.get(orderItem.OrderId).add(orderItem);
        }

        System.assertEquals(
            2,
            orderIdToOrderItems.get(orderList[0].Id).size(),
            'Should be 2 OrderItem for Order with "auto" provisioning'
        );

        System.assertEquals(
            2,
            orderIdToOrderItems.get(orderList[1].Id).size(),
            'Should be 2 OrderItem for Order with "manual" provisioning'
        );
    }

    @IsTest
    private static void testCreateOrderItemsForNewOrders_multiProduct_withUnifiedBilling() {
        new SObjectBuilder(Feature_Toggle__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Feature_Toggle__c.EnableMultiProductUnifiedBilling__c => true
            })
            .create();

        Triggers.switchOff();
        Triggers.except('OrderAfterTriggerHandler.CreateOrderItemsForNewOrders');

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, 'Test Account')
            .quantity(1)
            .create()
            .getRecord();

        Package__c pkg = (Package__c) new SObjectBuilder(Package__c.SObjectType)
            .setField(Package__c.Account__c, acc.Id)
            .setField(Package__c.Account_Package_Id__c, '1231231231')
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setField(Opportunity.Name, 'Test Opportunity')
            .setField(Opportunity.AccountId, acc.Id)
            .setField(Opportunity.Tier_Name__c, QuoteHelper.NGBS_OFFICE_PRODUCT)
            .setField(Opportunity.Brand_Name__c, OpportunityHelper.BRAND_RINGCENTRAL)
            .setField(Opportunity.Type, OpportunityHelper.OPPORTUNITY_TYPE_EX_BUSINESS)
            .setField(Opportunity.RecordTypeId, OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY)
            .setField(Opportunity.StageName, OpportunityHelper.STAGE_NAME_QUALIFY)
            .setField(Opportunity.CloseDate, System.today())
            .setField(Opportunity.CurrencyIsoCode, RingCentralHelper.USD)
            .quantity(1)
            .create()
            .getRecord();

        Quote masterQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setField(Quote.Name, 'Test Quote')
            .setField(Quote.OpportunityId, opp.Id)
            .setField(Quote.CurrencyIsoCode, RingCentralHelper.USD)
            .setField(Quote.Pricebook2Id, Test.getStandardPricebookId())
            .setField(Quote.isPrimary__c, true)
            .setField(Quote.IsMultiProductTechnicalQuote__c, false)
            .setField(Quote.Package_Info__c, NGBSTestDataGenerator.generateMultiProductQuotePackageInfo())
            .quantity(1)
            .create()
            .getRecord();

        Quote technicalQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setField(Quote.Name, 'Test Quote')
            .setField(Quote.OpportunityId, opp.Id)
            .setField(Quote.CurrencyIsoCode, RingCentralHelper.USD)
            .setField(Quote.ServiceName__c, QuoteHelper.NGBS_OFFICE_PRODUCT)
            .setField(Quote.Start_Date__c, Date.today())
            .setField(Quote.End_Date__c, Date.today().addDays(2))
            .setField(Quote.Pricebook2Id, Test.getStandardPricebookId())
            .setField(Quote.isPrimary__c, true)
            .setField(Quote.Status, QuoteHelper.QUOTE_STATUS_ACTIVE)
            .setField(Quote.IsMultiProductTechnicalQuote__c, true)
            .setField(Quote.MasterQuote__c, masterQuote.Id)
            .setField(Quote.Package_Info__c, NGBSTestDataGenerator.generateQuotePackageInfo())
            .setField(Quote.BillingPackage__c, pkg.Id)
            .quantity(1)
            .create()
            .getRecord();

        List<Product2> prodList = (List<Product2>) new SObjectBuilder(Product2.sObjectType)
            .setField(Product2.Name, 'Test product')
            .setField(Product2.Sub_Category__c, Product2Helper.SUBCATEGORY_RINGCENTRAL)
            .setField(Product2.IsActive, true)
            .setField(Product2.Charge_Term__c, Product2Helper.CHARGE_TERM_MONTHLY)
            .setField(Product2.UpsellType__c, ValueProviderBuilder.provideList(
                new List<String>{
                    Product2Helper.PRODUCT_PROVISIONING_TYPE_AUTO_WITH_CASE,
                    'manual',
                    'testUpsellType',
                    null
                }
            ))
            .quantity(4)
            .create()
            .getRecords();

        List<PricebookEntry> pbeList = new SObjectBuilder(PricebookEntry.SObjectType)
            .setField(PricebookEntry.Pricebook2Id, Test.getStandardPricebookId())
            .setField(PricebookEntry.Product2Id, ValueProviderBuilder.provideParents(prodList))
            .setField(PricebookEntry.UnitPrice, 10)
            .setField(PricebookEntry.IsActive, true)
            .setField(PricebookEntry.UseStandardPrice, false)
            .setField(PricebookEntry.CurrencyIsoCode, 'USD')
            .quantity(4)
            .create()
            .getRecords();

        List<QuoteLineItem> masterQLIList = (List<QuoteLineItem>) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setField(QuoteLineItem.QuoteId, masterQuote.Id)
            .setField(QuoteLineItem.Product2Id, ValueProviderBuilder.provideParents(prodList))
            .setField(QuoteLineItem.PricebookEntryId, ValueProviderBuilder.provideParents(pbeList))
            .setField(QuoteLineItem.Quantity, 5)
            .setField(QuoteLineItem.UnitPrice, 10)
            .setField(QuoteLineItem.IsMultiProductTechnicalQLI__c, false)
            .quantity(4)
            .create()
            .getRecords();

        List<QuoteLineItem> technicalQLIList = (List<QuoteLineItem>) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setField(QuoteLineItem.QuoteId, technicalQuote.Id)
            .setField(QuoteLineItem.Product2Id, ValueProviderBuilder.provideParents(prodList))
            .setField(QuoteLineItem.PricebookEntryId, ValueProviderBuilder.provideParents(pbeList))
            .setField(QuoteLineItem.Quantity, 5)
            .setField(QuoteLineItem.UnitPrice, 10)
            .setField(QuoteLineItem.IsMultiProductTechnicalQLI__c, true)
            .setField(QuoteLineItem.MasterQLI__c, ValueProviderBuilder.provideParents(masterQLIList))
            .quantity(4)
            .create()
            .getRecords();

        Test.startTest();
        List<Order> orderList = (List<Order> ) new SObjectBuilder(Order.SObjectType)
            .setField(Order.AccountId, acc.Id)
            .setField(Order.QuoteId, masterQuote.Id)
            .setField(Order.OpportunityId, opp.Id)
            .setField(Order.Pricebook2Id, Test.getStandardPricebookId())
            .setField(Order.EffectiveDate, System.today())
            .setField(Order.Status, OrderHelper.STATUS_NEW)
            .setField(Order.NumberOfMainLicenses__c, 25)
            .setField(Order.TechnicalAccountId__c, acc.Id)
            .setField(Order.TechnicalOpportunityId__c, opp.Id)
            .setField(Order.TechnicalQuoteId__c, technicalQuote.Id)
            .setField(Order.Provisioning__c, ValueProviderBuilder.provideList(
                new List<String>{
                    OrderHelper.PROVISIONING_AUTO,
                    OrderHelper.PROVISIONING_MANUAL
                }
            ))
            .quantity(2)
            .create()
            .getRecords();
        Test.stopTest();

        Triggers.switchOn();

        List<OrderItem> testOrderItems = (List<OrderItem>) new OrderItemSelector()
            .selectOrderItemsByOrderIds(new List<Object>{orderList})
            .executeQuery();

        System.assertEquals(
            technicalQLIList.size(),
            testOrderItems.size(),
            'OrderItems should be created for all QuoteLineItems'
        );

        Map<Id, List<OrderItem>> orderIdToOrderItems = new  Map<Id, List<OrderItem>>();
        for (OrderItem orderItem : testOrderItems) {
            if (!orderIdToOrderItems.containsKey(orderItem.OrderId)) {
                orderIdToOrderItems.put(orderItem.OrderId, new List<OrderItem>());
            }
            orderIdToOrderItems.get(orderItem.OrderId).add(orderItem);
        }

        System.assertEquals(
            2,
            orderIdToOrderItems.get(orderList[0].Id).size(),
            'Should be 2 OrderItem for Order with "auto" provisioning'
        );

        System.assertEquals(
            2,
            orderIdToOrderItems.get(orderList[1].Id).size(),
            'Should be 2 OrderItem for Order with "manual" provisioning'
        );
    }

    @IsTest
    private static void testCreateOrderItemsForNewOrders_multiProductLite_withUnifiedBilling() {
        new SObjectBuilder(Feature_Toggle__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Feature_Toggle__c.EnableMultiProductUnifiedBilling__c => true
            })
            .create();

        Triggers.switchOff();
        Triggers.except('OrderAfterTriggerHandler.CreateOrderItemsForNewOrders');

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, 'Test Account')
            .quantity(1)
            .create()
            .getRecord();

        Account technicalAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, 'Test Technical Account')
            .setField(Account.Master_Account__c, acc.Id)
            .setField(Account.IsMultiProductTechnicalAccount__c, true)
            .quantity(1)
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setField(Opportunity.Name, 'Test Opportunity')
            .setField(Opportunity.AccountId, acc.Id)
            .setField(Opportunity.Tier_Name__c, QuoteHelper.NGBS_OFFICE_PRODUCT)
            .setField(Opportunity.Brand_Name__c, OpportunityHelper.BRAND_RINGCENTRAL)
            .setField(Opportunity.Type, OpportunityHelper.OPPORTUNITY_TYPE_EX_BUSINESS)
            .setField(Opportunity.RecordTypeId, OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY)
            .setField(Opportunity.StageName, OpportunityHelper.STAGE_NAME_QUALIFY)
            .setField(Opportunity.CloseDate, System.today())
            .setField(Opportunity.CurrencyIsoCode, RingCentralHelper.USD)
            .quantity(1)
            .create()
            .getRecord();

        Opportunity techOpp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setField(Opportunity.Name, 'Test Technical Opportunity')
            .setField(Opportunity.AccountId, technicalAccount.Id)
            .setField(Opportunity.MasterOpportunity__c, opp.Id)
            .setField(Opportunity.Tier_Name__c, QuoteHelper.NGBS_OFFICE_PRODUCT)
            .setField(Opportunity.Brand_Name__c, OpportunityHelper.BRAND_RINGCENTRAL)
            .setField(Opportunity.Type, OpportunityHelper.OPPORTUNITY_TYPE_EX_BUSINESS)
            .setField(Opportunity.RecordTypeId, OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY)
            .setField(Opportunity.StageName, OpportunityHelper.STAGE_NAME_QUALIFY)
            .setField(Opportunity.CloseDate, System.today())
            .setField(Opportunity.CurrencyIsoCode, RingCentralHelper.USD)
            .quantity(1)
            .create()
            .getRecord();

        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setField(Quote.Name, 'Test Quote')
            .setField(Quote.OpportunityId, opp.Id)
            .setField(Quote.CurrencyIsoCode, RingCentralHelper.USD)
            .setField(Quote.Pricebook2Id, Test.getStandardPricebookId())
            .setField(Quote.isPrimary__c, true)
            .setField(Quote.IsMultiProductTechnicalQuote__c, false)
            .setField(Quote.Package_Info__c, NGBSTestDataGenerator.generateQuotePackageInfo())
            .quantity(1)
            .create()
            .getRecord();
        opp.PrimaryQuote__c = qt.Id;
        update opp;

        Quote techQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setField(Quote.Name, 'Test Quote')
            .setField(Quote.MasterQuote__c, qt.Id)
            .setField(Quote.OpportunityId, techOpp.Id)
            .setField(Quote.CurrencyIsoCode, RingCentralHelper.USD)
            .setField(Quote.Pricebook2Id, Test.getStandardPricebookId())
            .setField(Quote.isPrimary__c, true)
            .setField(Quote.IsMultiProductTechnicalQuote__c, true)
            .setField(Quote.Package_Info__c, NGBSTestDataGenerator.generateQuotePackageInfo())
            .quantity(1)
            .create()
            .getRecord();
        List<Product2> prodList = (List<Product2>) new SObjectBuilder(Product2.sObjectType)
            .setField(Product2.Name, 'Test product')
            .setField(Product2.Sub_Category__c, Product2Helper.SUBCATEGORY_RINGCENTRAL)
            .setField(Product2.IsActive, true)
            .setField(Product2.Charge_Term__c, Product2Helper.CHARGE_TERM_MONTHLY)
            .setField(Product2.UpsellType__c, ValueProviderBuilder.provideList(
                new List<String>{
                    Product2Helper.PRODUCT_PROVISIONING_TYPE_AUTO_WITH_CASE,
                    'manual',
                    'testUpsellType',
                    null
                }
            ))
            .quantity(4)
            .create()
            .getRecords();

        List<PricebookEntry> pbeList = new SObjectBuilder(PricebookEntry.SObjectType)
            .setField(PricebookEntry.Pricebook2Id, Test.getStandardPricebookId())
            .setField(PricebookEntry.Product2Id, ValueProviderBuilder.provideParents(prodList))
            .setField(PricebookEntry.UnitPrice, 10)
            .setField(PricebookEntry.IsActive, true)
            .setField(PricebookEntry.UseStandardPrice, false)
            .setField(PricebookEntry.CurrencyIsoCode, 'USD')
            .quantity(4)
            .create()
            .getRecords();

        List<QuoteLineItem> qliList = (List<QuoteLineItem>) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setField(QuoteLineItem.QuoteId, qt.Id)
            .setField(QuoteLineItem.Product2Id, ValueProviderBuilder.provideParents(prodList))
            .setField(QuoteLineItem.PricebookEntryId, ValueProviderBuilder.provideParents(pbeList))
            .setField(QuoteLineItem.Quantity, 5)
            .setField(QuoteLineItem.UnitPrice, 10)
            .setField(QuoteLineItem.IsMultiProductTechnicalQLI__c, false)
            .quantity(4)
            .create()
            .getRecords();

        Test.startTest();
        List<Order> testOrder = (List<Order>) new SObjectBuilder(Order.SObjectType)
            .setField(Order.AccountId, acc.Id)
            .setField(Order.QuoteId, qt.Id)
            .setField(Order.OpportunityId, opp.Id)
            .setField(Order.Pricebook2Id, Test.getStandardPricebookId())
            .setField(Order.EffectiveDate, System.today())
            .setField(Order.Status, OrderHelper.STATUS_NEW)
            .setField(Order.NumberOfMainLicenses__c, 25)
            .setField(Order.TechnicalAccountId__c, acc.Id)
            .setField(Order.TechnicalOpportunityId__c, opp.Id)
            .setField(Order.TechnicalQuoteId__c, qt.Id)
            .setField(Order.Provisioning__c, ValueProviderBuilder.provideList(
                new List<String>{
                    OrderHelper.PROVISIONING_AUTO,
                    OrderHelper.PROVISIONING_MANUAL
                }
            ))
            .quantity(1)
            .create()
            .getRecords();
        Test.stopTest();

        Triggers.switchOn();

        List<OrderItem> testOrderItems = (List<OrderItem>) new OrderItemSelector()
            .selectOrderItemsByOrderIds(new List<Object>{testOrder})
            .executeQuery();

        System.assertEquals(
            4,
            testOrderItems.size(),
            'No order items should be created'
        );
    }
}