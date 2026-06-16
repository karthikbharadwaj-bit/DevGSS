@isTest
public class TestDataFactory {

  public static final sObjectType APPROVAL_TYPE = ((SObject)Type.forName('Approval__c').newInstance()).getSObjectType();
  public static final sObjectType OPPORTUNITY_TYPE = ((SObject)Type.forName('Opportunity').newInstance()).getSObjectType();
  public static final sObjectType ACCOUNT_TYPE = ((SObject)Type.forName('Account').newInstance()).getSObjectType();
  public static final sObjectType CONTACT_TYPE = ((SObject)Type.forName('Contact').newInstance()).getSObjectType();
  public static final sObjectType QUOTE_TYPE = ((SObject)Type.forName('Quote').newInstance()).getSObjectType();
  public static final sObjectType PRODUCT2_TYPE = ((SObject)Type.forName('Product2').newInstance()).getSObjectType();
  public static final sObjectType QUOTELINEITEM_TYPE = ((SObject)Type.forName('QuoteLineItem').newInstance()).getSObjectType();
  public static final Id RYAN_AZUS_ID_FOR_TESTS = HardcodedIdsMapper.getMatchedObjectId('0058000000371o2');

  public static final Map<String, Schema.RecordTypeInfo> CASE_RECORD_TYPE_MAP = Schema.SObjectType.Case.getRecordTypeInfosByName();
  public static final Map<String, Schema.RecordTypeInfo> PHASE_RECORD_TYPE_MAP = Schema.SObjectType.Phase__c.getRecordTypeInfosByName();

  private static final String DEFAULT_OPPTY_RT_NAME = 'New_Sales_Opportunity';
  private static final String DEFAULT_ACCOUNT_RT_NAME = 'Customer_Account';
  private static final String DEFAULT_CONTACT_RT_NAME = 'Internal';

  public enum TestObject {
    Account,
    Contact,
    Opportunity,
    Product2,
    Quote,
    QuoteLineItem,
    Approval
  }

  public enum DocusignStatus {
    Sent,
    Completed
  }

  public enum QuoteType {
    Quote,
    Agreement
  }

  private static final Map<TestObject, sObjectType> TEST_OBJECTS_TYPE_MAP = new Map<TestObject, sObjectType>{
      TestObject.Account => ACCOUNT_TYPE,
      TestObject.Contact => CONTACT_TYPE,
      TestObject.Opportunity => OPPORTUNITY_TYPE,
      TestObject.Product2 => PRODUCT2_TYPE,
      TestObject.Quote => QUOTE_TYPE,
      TestObject.QuoteLineItem => QUOTELINEITEM_TYPE,
      TestObject.Approval => APPROVAL_TYPE
  };

  /** factory methods description
  *  Map<TestObject, sObject> createTestData() - creates test data with methods below. Stores it by TestObject enum in provate map
  *  sObject getTestObject(TestObject objectName) - returns test object from stored map. Init map with createTestData() if it's null
  *  sObject selectTestObject(TestObject objectName) - calls getTestObject(objectName) to get object id. Selects it from Db.
  *  Account createAccount() - calls createAccount(true)
  *  Account createAccount(Boolean save) - creates new test account. Inserts it to db depending on save param
  *  Contact createContact(Account acc) - calls createContact(acc, true)
  *  Contact createContact(Account acc, Boolean save) - creates new test contact. Inserts it to db depending on save param
  *  PriceBook2 getTestPriceBook() - calls getTestPriceBook(true)
  *  PriceBook2 getTestPriceBook(Boolean save) - creates new test PriceBook2 and stores it. Inserts it to db depending on save param. Inserts stored pricebook if there is one
  *  PriceBookEntry getTestPrice(Product2 prod) - calls getTestPrice(prod, true)
  *  PriceBookEntry getTestPrice(Product2 prod, Boolean save) - creates new test pricebook entry and stores it by product. Inserts it to db depending on save param. Inserts stored pricebook entry if there is one for specified product
  *  Opportunity createOppty(Account acc, Contact cont) - calls createOppty(acc, cont, true)
  *  Opportunity createOppty(Account acc, Contact cont, Boolean save) - creates new test oppty. Inserts it to db depending on save param
  *  Quote createQuote(Opportunity oppty) - calls createQuote(oppty, true)
  *  Quote createQuote(Opportunity oppty, Boolean save) - creates new test quote. Inserts it to db depending on save param
  *  Product2 createProduct() - calls createProduct(true)
  *  Product2 createProduct(Boolean save) -  creates new test Product2. Inserts it to db depending on save param
  *  Employee__c createEmployee() - calls createEmployee(true)
  *  Employee__c createEmployee(Boolean save) - creates a new Employee__c with all necessary info
  *  Case createCase() - calls createCase(true)
  *  Case createCase(Boolean save) - creates a new Case with all minimum necessary info
  **/

  private static Map<sObjectType, sObject> testData;


  private static Pricebook2 pb;
  private static Map<Id, PriceBookEntry> prices {
    get{
      if(null == prices){
        prices = new Map<Id, PriceBookEntry>();
      }
      return prices;
    }
    set;
  }
  private static Map<Id, PriceBookEntry> standardPrices {
    get{
      if(null == standardPrices){
        standardPrices = new Map<Id, PriceBookEntry>();
      }
      return standardPrices;
    }
    set;
  }

  //private static Map<String, Id> recordTypes;

  //public static Id getRecordTypeId(String rtName, String objectType){
  //  if(null == recordTypes){
  //    recordTypes = new Map<String, Id>();
  //  }
  //  if(recordTypes.containsKey(rtName)){
  //    List<RecordType> rt = [SELECT Id FROM RecordType WHERE DeveloperName =: rtName AND sObjectType =: objectType LIMIT 1];
  //    if(!rt.isEmpty()){
  //      recordTypes.put(rtName, rt[0].Id);
  //    }
  //  }
  //  return recordTypes.get(rtName);
  //}

  //public static Id getOpptyRecordTypeId(){
  //  return getRecordTypeId(DEFAULT_OPPTY_RT_NAME, TestObject.Opportunity.name());
  //}

  //public static Id getAccountRecordTypeId(){
  //  return getRecordTypeId(DEFAULT_ACCOUNT_RT_NAME, TestObject.Account.name());
  //}

  //public static Id getContactRecordTypeId(){
  //  return getRecordTypeId(DEFAULT_CONTACT_RT_NAME, TestObject.Contact.name());
  //}

  public static Account createAccount(){
    return createAccount(true);
  }

  public static Map<sObjectType, sObject> createTestData(){
    return createTestData(true);
  }

  public static Map<sObjectType, sObject> createTestData(Boolean basicDataOnly) {
    Account acc = createAccount();
    Contact contact = createContact(acc);
    Product2 prod = createProduct();
    Opportunity oppty = createOppty(acc, contact);
    Quote q = createQuote(oppty);
    //QuoteLineItem qli = createQuoteLineItem(q, prod);
    Map<sObjectType, SObject> result = new Map<sObjectType, SObject>{
        ACCOUNT_TYPE => acc,
        OPPORTUNITY_TYPE => oppty,
        CONTACT_TYPE => contact,
        PRODUCT2_TYPE => prod,
        QUOTE_TYPE => q
    };
    if(!basicDataOnly){
      Approval__c appr = createApproval((Quote)selectTestObject(TestObject.Quote));
      result.put(APPROVAL_TYPE, appr);
    }
    testData = result;
    return result;
  }

  public static DSFS__DocuSign_Status__c createDocusignStatus(DocusignStatus status){
    return createDocusignStatus(status, true);
  }

  public static DSFS__DocuSign_Status__c createDocusignStatus(DocusignStatus status, Boolean save) {
    String statusName = status.name();
    DSFS__DocuSign_Status__c dsStatus = new DSFS__DocuSign_Status__c(
        DSFS__Company__c = getTestObject(ACCOUNT_TYPE).Id,
        DFSQ__Quote__c = getTestObject(QUOTE_TYPE).Id,
        DSFS__Completed_Date_Time__c = DateTime.newInstance(2000, 10, 11, 8, 6, 16),
        DSFS__Envelope_Status__c = statusName);
    if(save){
      insert dsStatus;
    }
    return dsStatus;
  }

  public static Approval__c createLegalEngagementRequest(){
    return createLegalEngagementRequest((Quote)getTestObject(QUOTE_TYPE));
  }

  public static Approval__c createLegalEngagementRequest(Quote q){
    return createLegalEngagementRequest(q, true);
  }

  public static void setQuoteLegalRequest(Quote q, Approval__c a){
    setQuoteLegalRequest(q, a, true);
  }

    public static Account_Hierarchy__c createAccountHierarchy(String companyStatus, String name, Boolean save){
        Account_Hierarchy__c accHierarchy = new Account_Hierarchy__c(
            Company_Status__c = companyStatus,
            Name = name
        );
        if(save){
            insert accHierarchy;
        }
        return accHierarchy;
    }

  public static void setQuoteLegalRequest(Quote q, Approval__c a, Boolean save) {
    Quote testQ = (Quote)getTestObject(QUOTE_TYPE);
    Approval__c testA = (Approval__c)getTestObject(APPROVAL_TYPE);
    q.Special_TOS_Approval__c = a.Id;
    if(save){
      update q;
      if(testQ.Id == q.Id){
        setTestObject(q);
      }
      if(null == testA || testA.Id == a.Id){
        setTestObject(a);
      }
    }
  }

  public static void setOpportunityLegalRequest(Opportunity oppty, Approval__c a){
    setOpportunityLegalRequest(oppty, a, true);
  }

  public static void setOpportunityLegalRequest(Opportunity o, Approval__c a, Boolean save) {
    Opportunity testO = (Opportunity)getTestObject(OPPORTUNITY_TYPE);
    Approval__c testA = (Approval__c)getTestObject(APPROVAL_TYPE);
    o.Special_TOS_Approval__c = a.Id;
    if(save){
      update o;
      if(testO.Id == o.Id){
        setTestObject(o);
      }
      if(null == testA || testA.Id == a.Id){
        setTestObject(a);
      }
    }
  }

  public static Approval__c createLegalEngagementRequest(Quote q, Boolean save) {
    Approval__c appr = new Approval__c();
    appr.Quote__c = q.Id;
    appr.Opportunity__c = q.OpportunityId;
    appr.Type__c = ApprovalHelperCls.LEGAL_REQUEST_TYPE_AMENDMENT;
    appr.Account__c = q.Account__c;
    appr.RecordTypeId = ApprovalHelperCls.RT_ID_ENGAGE_LEGAL;
    if(save){
      insert appr;
    }
    return appr;
  }

  public static Approval__c createApproval(Quote q){
    return createApproval(q, true);
  }

  public static Approval__c createApproval(Quote q, Boolean save) {
    Approval__c appr = new Approval__c();
    appr.Quote__c = q.Id;
    appr.Opportunity__c = q.OpportunityId;
    appr.Account__c = q.Account__c;
    if(save){
      insert appr;
    }
    return appr;
  }

  public static sObject getTestObject(TestObject objectName) {
    return getTestObject(TEST_OBJECTS_TYPE_MAP.get(objectName));
  }

    public static sObject getTestObject(sObjectType sobjType) {
        if(null == testData){
            if(sobjType == APPROVAL_TYPE) {
                createTestData(false);
            } else {
                createTestData();
            }
        }
        return testData.get(sobjType);
    }

  public static void setTestObject(sObject obj) {
    if(null == testData){
      createTestData();
    }
    testData.put(obj.getSobjectType(), obj);
  }

  public static sObject selectTestObject(TestObject objectName) {
    return selectTestObject(TEST_OBJECTS_TYPE_MAP.get(objectName));
  }

  public static Quote changeQuoteType(QuoteType qType){
    return changeQuoteType((Quote) getTestObject(QUOTE_TYPE), qType);
  }

  public static Quote changeQuoteType(Quote q, QuoteType qType){
    return changeQuoteType(q, qType, true);
  }

  public static Quote changeQuoteType(QuoteType qType, Boolean save){
    return changeQuoteType((Quote) getTestObject(QUOTE_TYPE), qType, save);
  }

  public static Quote changeQuoteType(Quote q, QuoteType qType, Boolean save) {
    String typeStr = qType.name();
    q.QuoteType__c = typeStr;
    if(QuoteType.Agreement == qType) {
      q.Start_Date__c = Date.today();
      q.End_Date__c = Date.today();
      q.Initial_Term__c = '24';
    }
    if(save){
      update q;
      Quote testQ = (Quote)getTestObject(QUOTE_TYPE);
      if(testQ.Id == q.Id){
        setTestObject(q);
      }
    }
    return q;
  }

  public static sObject selectTestObject(sObjectType sobjType) {
    sObject obj = getTestObject(sobjType);
    String query = 'SELECT ';
    for(String fieldName : sobjType.getDescribe().fields.getMap().keySet()) {
      query += fieldName + ', ';
    }
    query = query.left(query.lastIndexOf(','));
    query += ' FROM ' + sobjType.getDescribe().getName() + ' WHERE Id = \'' + obj.Id + '\'';
    List<sObject> resultList = Database.query(query);
    return resultList.isEmpty() ? null : resultList[0];
  }

  public static Account createAccount(Boolean save) {
    Account testAcc = new Account(
        Name = 'testAcc'
    );
    if(save){
      insert testAcc;
    }
    return testAcc;
  }

  public static Contact createContact(Account acc){
    return createContact(acc, true);
  }

  public static Contact createContact(Account acc, Boolean save) {
    Contact testContact = new Contact(
        FirstName = 'Test1',
        LastName = 'Test1',
        AccountId = acc.Id,
        Email = 'test@test.com',
        Phone = '1234567890',
        Preferred_Language__c = 'en_US'
    );
    if(save){
      insert testContact;
    }
    return testContact;
  }

  public static PriceBook2 getTestPriceBook(){
    return getTestPriceBook(true);
  }

  public static PriceBook2 getTestPriceBook(Boolean save){
    if(null == pb){
      Id standardPriceBookId = Test.getStandardPricebookId();
      PriceBook2 testPriceBook = new Pricebook2(Name = 'Test Price Book', Description ='Test Price Book Products', IsActive = true, Line_Range_Min__c = 5, Service__c='Office');
      pb = testPriceBook;
    }
    if(null != pb && null == pb.Id && save){
      insert pb;
    }
    return pb;
  }

    public static PriceBook2 getAnnualPriceBook(){
    return getAnnualPriceBook(true);
  }

    public static PriceBook2 getAnnualPriceBook(Boolean save){
        Id standardPriceBookId = Test.getStandardPricebookId();
        PriceBook2 testPriceBook = new Pricebook2(Name = 'Test Price Book', Description ='Test Price Book Products', IsActive = true, Line_Range_Min__c = 5, Service__c='Office', Plan__c = 'Annual');
        pb = testPriceBook;
        insert pb;
    return pb;
  }

    public static PriceBook2 getMonthlyPriceBook(){
    return getMonthlyPriceBook(true);
  }

    public static PriceBook2 getMonthlyPriceBook(Boolean save){
        Id standardPriceBookId = Test.getStandardPricebookId();
        PriceBook2 testPriceBook = new Pricebook2(Name = 'Test Price Book', Description ='Test Price Book Products', IsActive = true, Line_Range_Min__c = 5, Service__c='Office', Plan__c = 'Monthly');
        pb = testPriceBook;

        insert pb;

    return pb;
  }

  public static PriceBookEntry getTestStandardPrice(Product2 prod){
    return getTestStandardPrice(prod, true);
  }

  public static PriceBookEntry getTestStandardPrice(Product2 prod, Boolean save) {
    PricebookEntry price = standardPrices.get(prod.Id);
    if(null == price){
      price = new PricebookEntry(
          Pricebook2Id = Test.getStandardPricebookId(),
          Product2Id = prod.Id,
          UnitPrice = 10000,
          IsActive = true,
          UseStandardPrice = false);
      standardPrices.put(prod.Id, price);
    }
    if(null != price && null == price.Id && save){
      insert price;
    }
    return price;
  }

  public static PriceBookEntry getTestPrice(Product2 prod){
    return getTestPrice(prod, true);
  }

  public static PriceBookEntry getTestPrice(Product2 prod, Boolean save) {
    PriceBookEntry standardPrice = getTestStandardPrice(prod);
    PricebookEntry price = prices.get(prod.Id);
    if(null == price){
      PricebookEntry testPrice = new PricebookEntry(
          Pricebook2Id = getTestPriceBook().Id,
          Product2Id = prod.Id,
          UnitPrice = 10000,
          IsActive = true,
          UseStandardPrice = false,
          Per_Line__c = false,
          Min_Quantity__c = 1,
          Max_Quantity__c = 100);
      price = testPrice;
      prices.put(prod.Id, price);
    }
    if(null != price && null == price.Id && save){
      insert price;
    }
    return price;
  }

  public static Opportunity createOppty(Account acc, Contact cont){
    return createOppty(acc, cont, true);
  }

  public static Opportunity createOppty(Account acc, Contact cont, Boolean save) {
    Opportunity testOpportunity = new Opportunity(
        Name = 'Test Opportunity 2016',
        Type = 'Syndicated - New',
        StageName = 'Planning',
        CloseDate = system.today().addMonths(1),
        AccountId = acc.Id,
        Primary_Opportunity_Contact__c = cont.Id);
    if(save){
      insert testOpportunity;
    }
    return testOpportunity;
  }

    public static Opportunity createEngOppty(Account acc, Contact cont, Boolean save) {
    Opportunity testOpportunity = new Opportunity(
        Name = 'Test Opportunity 2016',
        Type = 'Syndicated - New',
        StageName = 'Planning',
        CloseDate = system.today().addMonths(1),
        AccountId = acc.Id,
                Tier_Name__c = 'Engage Voice Standalone',
        Primary_Opportunity_Contact__c = cont.Id);
    if(save){
      insert testOpportunity;
    }
    return testOpportunity;
  }

  public static Quote createQuote(Opportunity oppty){
    return createQuote(oppty, true);
  }

  public static Quote createQuote(Opportunity oppty, Boolean save) {
    Quote testQuote = new Quote(
        Name = 'quotetest',
        OpportunityId = oppty.id,
        Pricebook2Id = getTestPriceBook().Id,
        Total_Number_of_Digital_Lines__c = 10, Account__c = oppty.AccountId);

    if(save){
      insert testQuote;
    }
    return testQuote;
  }

  public static Product2 createProduct(){
    return createProduct(true);
  }

  public static Product2 createProduct(Boolean save) {
        List<Product_Category__c> listOfProductCategory = createProductCategory(1, true);
    Product2 testProduct = new Product2(
        Name = 'Connect Pro - Annual Fee',
        IsActive = true,
        GOA_Group__c = 'DEVICES_B_STOCK',
                Product_Category__c = listOfProductCategory.get(0).Id,
        Family = 'RingCentral');
    if(save){
      insert testProduct;
    }
    return testProduct;
  }

  public static Product2 createServiceProduct(Boolean save) {
    Product2 testProduct = new Product2(
        Name = 'Connect Pro - Annual Fee',
        IsActive = true,
        GOA_Group__c = 'DEVICES_B_STOCK',
        Charge_Term__c = 'Monthly',
        Family = 'Service');
    if(save){
      insert testProduct;
    }
    return testProduct;
  }

    public static Product2 createCcProduct(){
    return createCcProduct(true);
  }

    public static Product2 createCcProduct(Boolean save) {
    Product2 testProduct = new Product2(
        Name = 'Connect Pro - Annual Fee',
        IsActive = true,
        GOA_Group__c = 'DEVICES_B_STOCK',
        Charge_Term__c = 'Monthly',
        Family = 'CC Service',
                Sub_Category__c = 'Contact Center',
                Cart_Tab_Availability__c = 'Sales Quote;Contact Center Quote');
    if(save){
      insert testProduct;
    }
    return testProduct;
  }

  public static QuoteLineItem createQuoteLineItem(Quote q, Product2 prod){
    return createQuoteLineItem(q, prod, true);
  }

  public static QuoteLineItem createQuoteLineItem(Quote q, Product2 prod, Boolean save) {
    QuoteLineItem testQuoteLineItem = new QuoteLineItem (
        ServiceDate = date.today(),
        Description = 'TestLineItem',
        UnitPrice = getTestPrice(prod).UnitPrice,
        Quantity = 5,
        QuoteId = q.Id,
        PriceBookEntryId = getTestPrice(prod).Id,
        Product2Id = prod.Id,
        Discount_type__c = QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY,
        Discount_number__c = 0,
            NewQuantity__c = 5);
    if(save){
      insert testQuoteLineItem;
    }
    return testQuoteLineItem;
  }

  public static User createUser(){
    return createUser('Test', true);
  }

  public static User createUser(String name){
    return createUser(name, true);
  }

  public static User createUser(Boolean insertUser){
    return createUser('Test', insertUser);
  }

  public static User createUser(String name, Boolean insertUser){
    //alias should be less than 8 characters
    String alias = name;
    if (name.length() > 8 ) {
      alias = name.left(8);
    }

    User user = new User(
        Username = name+'!user@gmail.com',
        LastName = 'Test'+name,
        Email = name+'_user@gmail.com',
        Alias = alias,
        TimeZoneSidKey = 'America/Los_Angeles',
        ManagerId = UserInfo.getUserId(),
        LocaleSidKey = 'en_US',
        EmailEncodingKey = 'UTF-8',
        ProfileId = [SELECT Id, Name FROM Profile WHERE Name = 'System Administrator'].Id,
        LanguageLocaleKey = 'en_US',
        Hierarchy_Role__c = 'Sales Rep'
    );
    if(insertUser) {
      insert user;
    }
    return user;
  }
  
  public static Group createGroup(String name, Boolean insertGroup){
    Group g = new Group(
            Name = name
        );
        if(insertGroup){
          insert g;
        }
        return g;
  }

  public static void addUserToGroup(Id groupId){
    addUserToGroup(UserInfo.getUserId(), groupId);
  }

  public static void addUserToGroup(Id userId, Id groupId) {
    GroupMember gm = new GroupMember(
        UserOrGroupId = userId,
        GroupId = groupId
    );
    insert gm;
  }

  public static Employee__c createEmployee() {
    return createEmployee(true);
  }

  public static Employee__c createEmployee(Boolean isInsertEmployee) {
    Employee__c employee = new Employee__c(
        First_Name__c = 'FirstName',
        Last_Name__c = 'LastName',
        Email__c = 'veryRandomSuch@Email123.com',
        Location__c = 'San Mateo, US',
        Department__c = 'Business Development',
        Division__c = 'Sales - Development Bay',
        Team__c = 'Sales - AT&T Initials'
    );
    if(isInsertEmployee){
      insert employee;
    }
    return employee;
  }

    public static IT_Purchase_Order__c createITPurchaseOrder(Id contactId, Boolean save){
      IT_Purchase_Order__c itpo = new IT_Purchase_Order__c(
        End_User_Contact__c = contactId,
        Status__c = '1. New Request',
        Category__c = 'New Hire',
        Recurring__c = 'No'
      );
      if(save){
            insert itpo;
        }
        return itpo;
    }

  public static Case createCase() {
    return createCase(true);
  }

  public static Case createCase(Boolean isInsertCase) {
    Case c = new Case(
        Status = 'New',
        RecordTypeId = CASE_RECORD_TYPE_MAP.get('IT Helpdesk').getRecordTypeId()
    );
    return c;
  }

    public static Lead createLead(Boolean save) {
        Lead testLead = new Lead();
        testLead.email = 'fake@email.com';
        testLead.LastName = 'fakeLastName';
        testLead.Company = 'fakeCompany';
        if(save){
            insert testLead;
        }
        return testLead;
    }

    public static Lead createLead(Map<String, String> fieldValueMap){
        Lead testSetupLead = new Lead(
            LastName = 'fakeLastName',
            Company = 'fakeCompany',
            Email = 'fake@email.com'
        );

        for (String fieldName : fieldValueMap.keySet() ){
            testSetupLead.put(fieldName, fieldValueMap.get(fieldName) );
        }
        return testSetupLead;
    }

    public static Campaign createCampaign(Boolean save) {
        Campaign testCampaign = new Campaign();
        testCampaign.Name = 'fakeCampaign';
        if(save){
            insert testCampaign;
        }
        return testCampaign;
    }

    public Static Emails__c createEmails(String name, String emailAddress, Boolean save){
        Emails__c email = new Emails__c(
            Name = name,
            Email_Address__c = emailAddress
        );
        if(save){
            insert email;
        }
        return email;
    }

    public static String getLeadSpaceEnrichmentSuccessJson(){
        String successJson = '{ ' +
                '"status": "success",' +
                '"data": { ' +
                    '"person": {' +
                    ' "first_name": "testPersonFirstName",' +
                        '"address": {' +
                            '"country": "testPersonAddressCountry"' +
                        '},' +
                        '"analytics": {' +
                            '"job_functions": [' +
                                '"testJobFunction"' +
                            '],' +
                            '"scores": [' +
                                '{' +
                                    '"score": {' +
                                        '"value": 0' +
                                    '},' +
                                    '"profile_name": "testPersonAnalyticsScoreProfileName"' +
                                '}' +
                            ']' +
                        '}' +
                    '},' +
                    '"company": {' +
                        '"client_id":"DunsTest",' +
                        '"industry": "testIndustry",' +
                        '"website": "www.testwebsite.com",' +
                        '"address": {' +
                            '"country": "testCompanyCountry"' +
                        '},' +
                        '"size": {' +
                            '"range": "testCompanySizeRange",' +
                            '"exact": 1' +
                        '},' +
                        '"revenue": {' +
                            '"range": "testCompanyRevenueRange"' +
                        '},' +
                        '"analytics": {' +
                            '"installed_base_technologies":["testCompanyAnalyticsInstalledBaseTechnologies"]' +
                        '},' +
                        '"family_tree": {' +
                            '"companies": [' +
                                '{' +
                                    '"type": "DU",' +
                                    '"address": {' +
                                        '"country": "testCompanyFamilyTreeCompaniesAddressCountry"' +
                                    '},' +
                                    '"duns": "testCompanyFamilyTreeCompaniesDuns"' +
                                '}' +
                            ']' +
                        '}' +
                    '},' +
                    '"total_scores": [' +
                        '{' +
                            '"score": {' +
                                '"value": "10"' +
                            '},' +
                            '"profile_name": "testTotalScoresProfileName"' +
                        '}' +
                    '],' +
                    '"max_positive_total_score_profiles":["testMaxPositiveTotalScoreProfiles"],' +
                    '"enrichment_status": "testEnrichmentStatus"' +
                '}' +
            '}';
        return successJson;
    }

    public static String getUserNamePrefix(){
        String orgId = UserInfo.getOrganizationId();
        String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');
        Integer randomInt = Integer.valueOf(math.rint(math.random()*1000000));

        return orgId + dateString + '_' + randomInt;
    }

    public static String getUniqueUserName(){
        return getUserNamePrefix() + '@RingCentralTest.tld';
    }

    public static String getFullLeadSpaceResponse(String clientId){
        String leadSpaceResponseJson = '{' +
                '"status": "success",' +
                '"data": {' +
                    '"person": {' +
                        '"title": "Co-founder",' +
                        '"department": "Management",' +
                        '"level": "C Level",' +
                        '"email": "",' +
                        '"phone": "",' +
                        '"analytics": {' +
                            '"technologies": [],' +
                            '"scores": [' +
                                '{' +
                                    '"score": {' +
                                        '"value": 0' +
                                    '},' +
                                    '"profile_name": "Decision Maker"' +
                                '},' +
                                '{' +
                                    '"score": {' +
                                        '"value": 0' +
                                    '},' +
                                    '"profile_name": "Finance and Ops"' +
                                '},' +
                                '{' +
                                    '"score": {' +
                                        '"value": 0' +
                                    '},' +
                                    '"profile_name": "Contact Center"' +
                                '},' +
                                '{' +
                                    '"score": {' +
                                        '"value": 0' +
                                    '},' +
                                    '"profile_name": "Influencer"' +
                                '},' +
                                '{' +
                                    '"score": {' +
                                        '"value": 0' +
                                    '},' +
                                    '"profile_name": "IT"' +
                                '},' +
                                '{' +
                                    '"score": {' +
                                        '"value": 50' +
                                    '},' +
                                    '"profile_name": "CXO"' +
                                '}' +
                            '],' +
                            '"job_functions": [' +
                                '"Founder",' +
                                '"This is a job function that does intentionally go over 255 characters 1",' +
                                '"This is a job function that does intentionally go over 255 characters 2",' +
                                '"This is a job function that does intentionally go over 255 characters 3",' +
                                '"This is a job function that does intentionally go over 255 characters 4"' +
                            '],' +
                            '"max_positive_score_profiles": [' +
                                '"CXO",' +
                                '"This is a positive score profile that does intantionally go over 255 characters 1",' +
                                '"This is a positive score profile that does intantionally go over 255 characters 2",' +
                                '"This is a positive score profile that does intantionally go over 255 characters 3",' +
                                '"This is a positive score profile that does intantionally go over 255 characters 4"' +
                            ']' +
                        '},' +
                        '"address": {' +
                            '"country": "United States",' +
                            '"state": "WA",' +
                            '"city": "Seattle"' +
                        '},' +
                        '"verification_status": "Not Verified",' +
                        '"verification_source": "None",' +
                        '"original_email_verification_status": "Valid",' +
                        '"original_email": "bill.gates@microsoft.com",' +
                        '"first_name": "Bill",' +
                        '"last_name": "Gates",' +
                        '"linkedin_profile": "https://www.linkedin.com/in/williamhgates"' +
                    '},' +
                    '"company": {' +
                        '"name": "Microsoft",' +
                        '"description": "At Microsoft, our mission is to empower every person and every...",' +
                        '"address": {' +
                            '"country": "United States",' +
                            '"state": "WA",' +
                            '"city": "Redmond",' +
                            '"street": "1 Microsoft Way",' +
                            '"zipcode": "98052",' +
                            '"region": "North America"' +
                        '},' +
                        '"phone": "4258828080",' +
                        '"industry": "High Tech",' +
                        '"website": "www.microsoft.com",' +
                        '"sic": "7372",' +
                        '"naics": "334611",' +
                        '"size": {' +
                            '"range": "1000+",' +
                            '"exact": 114120' +
                        '},' +
                        '"revenue": {' +
                            '"range": "> $1 Billion",' +
                            '"exact": 85320000000' +
                        '},' +
                        '"analytics": {' +
                            '"installed_base_technologies": [' +
                                '"QuickBooks Online",' +
                                '"Zoho",' +
                                '"Salesforce.com Desk.com"' +
                            '],' +
                            '"web_site_technologies": [' +
                                '"Adobe Dynamic Tag Management",' +
                                '"Adobe Visitor API",' +
                                '"AggregateRating Schema Entity",' +
                                '"Asp .Net"' +
                            ']' +
                        '},' +
                        '"ls_id": "daDMX+XwVwWmVDY19qcJuMLBpl+OR13P",' +
                        '"sub_industry": "Software",' +
                        '"linkedin_profile": "www.linkedin.com/company/microsoft",' +
                        '"family_tree": {' +
                            '"companies": [' +
                                '{' +
                                    '"type": "DU",' +
                                    '"name": "Microsoft Corporation",' +
                                    '"address": {' +
                                        '"country": "United States",' +
                                        '"state": "WA",' +
                                        '"city": "Redmond",' +
                                        '"street": "1 Microsoft Way",' +
                                        '"zipcode": "98052",' +
                                        '"region": "North America"' +
                                    '},' +
                                    '"phone": "4258828080",' +
                                    '"website": "www.microsoft.com",' +
                                    '"sic": "7372",' +
                                    '"naics": "334611",' +
                                    '"size": {' +
                                        '"range": "1000+",' +
                                        '"exact": 114120' +
                                    '},' +
                                    '"revenue": {' +
                                        '"range": "> $1 Billion",' +
                                        '"exact": 85320000000' +
                                    '},' +
                                    '"ls_id": "daDMX+XwVwWmVDY19qcJuMLBpl+OR13P",' +
                                    '"client_id": "' + clientId + '"' +
                                '},' +
                                '{' +
                                    '"type": "GU",' +
                                    '"name": "Microsoft Corporation",' +
                                    '"address": {' +
                                        '"country": "United States",' +
                                        '"state": "WA",' +
                                        '"city": "Redmond",' +
                                        '"street": "1 Microsoft Way",' +
                                        '"zipcode": "98052",' +
                                        '"region": "North America"' +
                                    '},' +
                                    '"phone": "4258828080",' +
                                    '"website": "www.microsoft.com",' +
                                    '"sic": "7372",' +
                                    '"naics": "334611",' +
                                    '"size": {' +
                                        '"range": "1000+",' +
                                        '"exact": 114120' +
                                    '},' +
                                    '"revenue": {' +
                                        '"range": "> $1 Billion",' +
                                        '"exact": 85320000000' +
                                    '},' +
                                    '"ls_id": "daDMX+XwVwWmVDY19qcJuMLBpl+OR13P",' +
                                    '"client_id": "' + clientId + '"' +
                                '},' +
                                '{' +
                                    '"type": "SITE",' +
                                    '"name": "Microsoft Corporation",' +
                                    '"address": {' +
                                        '"country": "United States",' +
                                        '"state": "WA",' +
                                        '"city": "Redmond",' +
                                        '"street": "1 Microsoft Way",' +
                                        '"zipcode": "98052",' +
                                        '"region": "North America"' +
                                    '},' +
                                    '"phone": "4258828080",' +
                                    '"website": "www.microsoft.com",' +
                                    '"sic": "7372",' +
                                    '"naics": "334611",' +
                                    '"size": {' +
                                        '"range": "> 100K",' +
                                        '"exact": 114120' +
                                    '},' +
                                    '"revenue": {' +
                                        '"range": "> $1 Billion",' +
                                        '"exact": 85320000000' +
                                    '},' +
                                    '"ls_id": "daDMX+XwVwWmVDY19qcJuMLBpl+OR13P",' +
                                    '"client_id": "' + clientId + '"' +
                                '}' +
                            '],' +
                            '"site_is_subsidiary": false' +
                        '},' +
                        '"client_id": "' + clientId + '",' +
                        '"ownership": "Public Company",' +
                        '"original_name": "Microsoft"' +
                    '},' +
                    '"enrichment_status": "Person & Company Enriched",' +
                    '"max_positive_total_score_profiles": [],' +
                    '"total_scores": [' +
                        '{' +
                            '"score": {' +
                                '"value": 0' +
                            '},' +
                            '"profile_name": "RingCentral Predictive"' +
                        '}' +
                    ']' +
                '}' +
            '}';
        return leadSpaceResponseJson;
    }

    public static String getEmptyLeadSpaceResponse() {
        return '{"status":"success","external_id":"null","data":{"total_scores":[{"score":{"value":0.0},' +
            '"profile_name":"RingCentral Predictive"}],"person":{"verification_status":"Moved",' +
            '"verification_source":"None","title":null,"phone":null,"original_email_verification_status":"",' +
            '"original_email":"user@aol.com","linkedin_profile":"https://www.linkedin.com/in/ron-roma",' +
            '"level":null,"last_name":"Roma","first_name":"Ronald","email":null,"department":null,' +
            '"analytics":{"technologies":[],"scores":[{"score":{"value":0.0},"profile_name":"Decision Maker"},' +
            '{"score":{"value":0.0},"profile_name":"Finance and Ops"},{"score":{"value":0.0},' +
            '"profile_name":"Contact Center"},{"score":{"value":0.0},"profile_name":"Influencer"},' +
            '{"score":{"value":0.0},"profile_name":"IT"},{"score":{"value":0.0},"profile_name":"CXO"}],' +
            '"max_positive_score_profiles":[],"job_functions":[]},"address":{"state":null,"country":"United States",' +
            '"city":null}},"max_positive_total_score_profiles":[],"enrichment_status":"Person Enriched",' +
            '"company":{"website":null,"sub_industry":null,"size":null,"sic":null,"revenue":null,"phone":null,' +
            '"ownership":null,"original_name":"Artificial Landscape Decisions Inc","name":"","naics":null,' +
            '"ls_id":null,"linkedin_profile":null,"industry":null,"family_tree":null,"description":null,' +
            '"client_id":null,"analytics":null,"address":null}}}';
    }

    public static Account_Hierarchy__c createAccountHierarchy(Boolean isInsert){
        Account_Hierarchy__c accountHierarchy = new Account_Hierarchy__c();
        if (isInsert){
            insert accountHierarchy;
        }
        return accountHierarchy;
    }

    public static RingCentralVariousSettings__c createRingCentralVariousSettings(Boolean isInsert){
        RingCentralVariousSettings__c ringCentralVariousSettings = new RingCentralVariousSettings__c();
        ringCentralVariousSettings.LeadspaceAPIKey__c = 'AnyFakeKey';
        ringCentralVariousSettings.LSBatchRequestMaxNumberRecords__c = 10;
        if (isInsert){
            insert ringCentralVariousSettings;
        }
        return ringCentralVariousSettings;
    }

    public static Company_Persons__c createCompanyPersons(Boolean isInsert){
        Company_Persons__c companyPerson = new Company_Persons__c();
        if(isInsert){
            insert companyPerson;
        }
        return companyPerson;
    }

    public static AccountContactRole createAccountContactRole(Account account, Contact contact, Boolean isInsert){
        AccountContactRole accountContactRole = new AccountContactRole();
        accountContactRole.AccountId = account.Id;
        accountContactRole.ContactId = contact.Id;
        if(isInsert){
            insert accountContactRole;
        }
        return accountContactRole;
    }

    public static AccountContactRole createAccountContactRole(Id accountId, Contact contact, Boolean isInsert){
        AccountContactRole accountContactRole = new AccountContactRole();
        accountContactRole.AccountId = accountId;
        accountContactRole.ContactId = contact.Id;
        if(isInsert){
            insert accountContactRole;
        }
        return accountContactRole;
    }

    public static AccountContactRole createPrimarySignatoryAccountContactRole(
        Account account, 
        Contact contact, 
        Boolean isInsert
    ){
        AccountContactRole accountContactRole = new AccountContactRole(
            AccountId = account.Id,
      ContactId = contact.Id,
        IsPrimary = true,
      Role = 'Signatory'
        );
        if(isInsert){
            insert accountContactRole;
        }
        return accountContactRole;
    }

    public static CompanyMatchingCountryMapping__c createCompanyMatchingCountryMapping(Boolean isInsert){
        CompanyMatchingCountryMapping__c companyMatchingCountryMapping = new CompanyMatchingCountryMapping__c();
        companyMatchingCountryMapping.Name = 'USA';
        companyMatchingCountryMapping.ToCountry__c = 'United States';
        if (isInsert){
            insert companyMatchingCountryMapping;
        }
        return companyMatchingCountryMapping;
    }

    public static CompanyMatchingIgnoredDomains__c createCompanyMatchingIgnoredDomain(Boolean isInsert){
        CompanyMatchingIgnoredDomains__c companyMatchingIgnoredDomain = new CompanyMatchingIgnoredDomains__c();
        companyMatchingIgnoredDomain.Name = 'yahoo.com';
        if (isInsert){
            insert companyMatchingIgnoredDomain;
        }
        return companyMatchingIgnoredDomain;
    }

    public static Jeopardy_History__c createJeopardyHistory(Boolean isInsert){
        Jeopardy_History__c testJeopardyHistory = new Jeopardy_History__c(Name = 'testJH');

        if (isInsert){
            insert testJeopardyHistory;
        }

        return testJeopardyHistory;
    }

    public static String getLeadSpaceResponseBatchPollingJson(){
        String successJson = '{' +
                                '"id": "/v3/enrichment/results/6382c184-529d-4b61-9dd8-08fc9299ce21"' +
                            '}';
        return successJson;
    }

    public static String getLeadSpaceEnrichmentSuccessBatchJson(String externalId1, String externalId2){
        String successJson = 
            '{"results": [' +
                '{ ' +
                    '"status": "success",' +
                    '"external_id": "' + externalId1 + '",' +
                    '"data": { ' +
                        '"person": {' +
                        ' "first_name": "testPersonFirstName",' +
                            '"address": {' +
                                '"country": "testPersonAddressCountry"' +
                            '}' +
                        '},' +
                        '"company": {' +
                            '"client_id":"DunsTest",' +
                            '"website": "www.testwebsite.com",' +
                            '"family_tree": {' +
                                '"companies": [' +
                                    '{' +
                                        '"type": "DU",' +
                                        '"address": {' +
                                            '"country": "testCompanyFamilyTreeCompaniesAddressCountry"' +
                                        '},' +
                                        '"duns": "testCompanyFamilyTreeCompaniesDuns"' +
                                    '}' +
                                ']' +
                            '}' +
                        '},' +
                        '"max_positive_total_score_profiles":["testMaxPositiveTotalScoreProfiles"],' +
                        '"enrichment_status": "testEnrichmentStatus"' +
                    '}' +
                '},' +
                '{ ' +
                    '"status": "success",' +
                    '"external_id": "' + externalId2 + '",' +
                    '"data": { ' +
                        '"person": {' +
                        ' "first_name": "testPersonFirstName",' +
                            '"address": {' +
                                '"country": "testPersonAddressCountry"' +
                            '}' +
                        '},' +
                        '"company": {' +
                            '"client_id":"DunsTest",' +
                            '"website": "www.testwebsite.com",' +
                            '"family_tree": {' +
                                '"companies": [' +
                                    '{' +
                                        '"type": "DU",' +
                                        '"address": {' +
                                            '"country": "testCompanyFamilyTreeCompaniesAddressCountry"' +
                                        '},' +
                                        '"duns": "testCompanyFamilyTreeCompaniesDuns"' +
                                    '}' +
                                ']' +
                            '}' +
                        '},' +
                        '"max_positive_total_score_profiles":["testMaxPositiveTotalScoreProfiles"],' +
                        '"enrichment_status": "testEnrichmentStatus"' +
                    '}' +
                '}' +
            ']}';
        return successJson;
    }

    public static BatchJobsConfiguration__c createBatchJobsConfiguration(Boolean isInsert, String className) {
        BatchJobsConfiguration__c batchJobsConfiguration = new BatchJobsConfiguration__c();
        batchJobsConfiguration.Name = className;
        batchJobsConfiguration.ErrorEmailDistributionList__c = 'test@test.com';

        if (isInsert) {
            insert batchJobsConfiguration;
        }

        return batchJobsConfiguration;
    }

    public static Upsell_Insights_Product_Usage__c createUpsellInsightsProductUsages(Id accountId, Boolean isInsert){
        Upsell_Insights_Product_Usage__c upsell = new Upsell_Insights_Product_Usage__c();
        upsell.account__c = accountId;
        if (isInsert){
            insert upsell;
        }
        return upsell;
    }

    public static Phase__c createPhase(Boolean isInsert) {
        Phase__c phase = new Phase__c(
            Status__c = 'New',
            RecordTypeId = PHASE_RECORD_TYPE_MAP.get('ProServ Phase').getRecordTypeId()
        );
        if (isInsert) {
            insert phase;
        }
        return phase;
    }

    public static Order createOrder(Boolean isInsert) {
        Order order = new Order(
            Status = 'New'
        );
        if (isInsert) {
            insert order;
        }
        return order;
    }
    
    public static CampaignMember createCampaignMember(Campaign campaign, Lead lead, Boolean isInsert){
        CampaignMember campaignMember = new CampaignMember();
        CampaignMember.CampaignId = campaign.Id;
        CampaignMember.LeadId = lead.Id;
        if(isInsert){
            insert campaignMember;
        }
        return campaignMember;
    }

    public static ProServ_Project__c createProServProject(boolean isInsert) {
        ProServ_Project__c proServ = new ProServ_Project__c();
        if (isInsert) {
            insert proServ;
        }
        return proServ;
    }

    public static List<Product_Category__c> createProductCategory (Integer numOfRecords, Boolean isInsert) {
        List<Product_Category__c> listOfProductCategory = new List<Product_Category__c>();
        for (Integer i = 0; i < numOfRecords; i++) {
            Product_Category__c productCategory = new Product_Category__c();
            productCategory.Name = 'Office ' + i;
            listOfProductCategory.add(productCategory);
        }

        if (!listOfProductCategory.isEmpty() && isInsert) {
            insert listOfProductCategory;
        }
        return listOfProductCategory;
    }

    // Map to store mock record type mappings
    private static Map<String, Map<String, Boolean>> mockRecordTypeMappings = new Map<String, Map<String, Boolean>>();
    
    // Map to store mock queue mappings
    private static Map<String, String> mockQueueMappings = new Map<String, String>();
    
    // Mock Jira RecordType Mapping
    public static void createJiraRecordTypeMapping(String recordTypeName, String operationType, Boolean isAllowed) {
        if(!mockRecordTypeMappings.containsKey(recordTypeName)) {
            mockRecordTypeMappings.put(recordTypeName, new Map<String, Boolean>());
        }
        mockRecordTypeMappings.get(recordTypeName).put(operationType, isAllowed);
    }
    
    // Mock Jira Queue Mapping
    public static void createJiraQueueMapping(String queueName, String projectKey) {
        mockQueueMappings.put(queueName, projectKey);
    }
    
    // Clear all mocks
    public static void clearMocks() {
        mockRecordTypeMappings.clear();
        mockQueueMappings.clear();
    }
    
    // Method to check if a record type is allowed (to be called from your test methods)
    public static Boolean isRecordTypeAllowed(String recordTypeName, String operationType) {
        return mockRecordTypeMappings.containsKey(recordTypeName) && 
            mockRecordTypeMappings.get(recordTypeName).containsKey(operationType) &&
            mockRecordTypeMappings.get(recordTypeName).get(operationType);
    }
    
    // Method to get project key for queue (to be called from your test methods)
    public static String getProjectKeyForQueue(String queueName) {
        return mockQueueMappings.get(queueName);
    }

}