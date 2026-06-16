//Naresh Kumar  10/30/2019

/*
 Change History
 *****************************getReadOnlyFlagForUser***************************************************************************************
 SCRUM/Jira              ModifiedBy      Date        Description                                          Tag
 Partner Quote Pdf       Namitha         11/27/2019  Added logic for quote pdf - Partner Contract details T1
 ********************************************************************************************************************
 */
public without sharing class Quote_PartnerQuoteUtil{
  public static final String EU_PARENT_DEPENDENT_QUANTITY = 'EU - Parent dependent quantity';
  public static final string DEFAULT_COUNTRY_VALUE = 'United States';
  public static final String EU_PARENT_DEPENDENT_QUANTITY_APP = 'EU - Parent dependent quantity - AAP';
  public static final String EU_PARENT_DEPENDENT_QUANTITY_CANNOT_EXCEED_PARENT = 'EU - Parent dependent quantity cannot exceed parent';
  public static final String EU_PARENT_DEPENDENT_QUANTITY_CANNOT_EXCEED_PARENT_SELECT_ONLY_ONE = 'EU - Parent dependent quantity cannot exceed parent, EU - Select only one';
  public static final String LU_PARENT_MANDATORY_CHILDREN_NOT_DEPENDENT = 'LU - Parent mandatory, children not dependent';
  public static final String AA_AUTO_ADD_CHILD = 'AA- Auto Add Child';
  public static final String MU_PICK_NONE_OR_ONE = 'MU - Pick none or one';
  public static final String EU_SELECT_ONLY_ONE = 'EU - Select only one';
  public static final String MU_PICK_NONE_OR_ONE_PARENT_MANDATORY = 'MU - Pick none or one - Parent Mandatory';
  public static final String DEFAULT_ROW_COLOR = '#EDEDED';
  public static final String PACKAGE_PRODUCT_TYPE_PICK_YOUR_NUMBER = 'Pick Your Numbers';
  public static final String L1_APPROVAL = 'L1 Approval';
  public static final String L2_APPROVAL = 'L2 Approval';
  public static final String NONE_APPROVAL = 'None';
  public static final String DS_TYPE_L1_APPROVAL = 'L1 Discount Approval';
  public static final String DS_TYPE_L2_APPROVAL = 'L2 Discount Approval';
  public static final String QUOTE_STATUS_PENDING_L1_APPROVAL = 'Pending L1 Discount Approval';
  public static final String QUOTE_STATUS_PENDING_L2_APPROVAL = 'Pending L2 Discount Approval';
  public static final String QUOTE_STATUS_PENDING = 'Pending';
  public static final String QUOTE_L1_APPROVAL_QUEUE = 'Partner_Quote_L1_Approval_Queue';
  public static final String QUOTE_L2_APPROVAL_QUEUE = 'Partner_Quote_L2_Approval_Queue';
  public static final String QUOTE_STATUS_DRAFT = 'Draft';
  public static final String QUOTE_STATUS_CLOSED_APPROVED = 'Closed-Approved';
  public static final String DEAL_SUPPORT_TYPE_DISCOUNT_REQUEST = 'Discount Request';
  public static Map<String, Integer> mapOfLboxRuleIdToTotalQuantiy = new Map<String, Integer>();
  public Quote_PartnerQuoteUtil(){
  }

  public static Partner_Quote__c getQuote(Id quoteId){
    return [SELECT Opportunity__r.Tier_Name__c, Product_Edition__r.Skip_Pick_Your_Number__c, Name, Opportunity__r.ownerId, Opportunity__r.Partner_Account__c, Opportunity__r.Partner_Account__r.partner_type__c, Opportunity__r.Brand_Name__c, Name__c, POC_Term__c, Comment__c, Discount_Line_Count__c, (SELECT ID, Product__c, Product__r.Name, List_Price__c, Partner_Quote__c, Product_Catalogue__c, Discount__c, Quantity__c, Effective_Price__c, Total_Price__c, Product_Catalogue__r.plan__c, Product_Catalogue__r.Category_Name__c FROM Partner_Quote_Products__r), CurrencyIsoCode, RecordTypeId, Auto_Renewal__c, Quote_Type__c, Discount_Approval_Status__c, Agreement_Status__c, Quote_Approval_Id__c, Stage__c, Status__c, POC__c, Start_Date__c, End_Date__c, Shipping_Address__c, Special_Terms__c, Expiration_Date__c, Opportunity__r.AccountId, Free_Month_Discounts__c, Justification_Description__c, Provisioning_Details__c, Opportunity__r.Account.Name, Opportunity__r.Account.Most_Recent_Implementation_Contact__r.name, Opportunity__c, Opportunity__r.Name, Opportunity__r.Account.Most_Recent_Implementation_Contact__r.Email, Opportunity__r.Account.Customer_city__c, Opportunity__r.Account.Customer_State__c, Opportunity__r.Account.Phone, Opportunity__r.CurrencyIsoCode, Opportunity__r.Account.BillingAddress, Opportunity__r.Account.BillingStreet, Opportunity__r.Account.BillingCity, Opportunity__r.Account.BillingState, Opportunity__r.Account.Preferred_Language__c, Opportunity__r.StageName, Opportunity__r.CloseDate, Primary__c, Initial_Term__c, Renewal_Term__c, Product_Edition__c, Number_of_Licenses__c, Contract__c, Payment_Term__c, Highest_Discount__c, Subscription__c, Product_Edition__r.Name, Grid_View__c, Product_Edition__r.Product_Categories__c, Quote_Locked__c, Licenses_greater_than_100__c, Is_Phone_Product__c, brand_name__c, Opportunity__r.Account.BillingCountry, Opportunity__r.Portal_Cloud_Specialist__r.Name, Opportunity__r.Portal_Cloud_Specialist__r.Email, Opportunity__r.Portal_Cloud_Specialist__r.Phone, Opportunity__r.Account.Partner_Contact__r.Name, Opportunity__r.Account.Partner_Contact__r.Email, Opportunity__r.Account.Partner_Contact__r.Phone, Opportunity__r.Segment_Name__c FROM Partner_Quote__c WHERE id = :quoteId];
  }
    
  public static Quote getSalesQuote(Id quoteId){
     return [SELECT Name, QuoteNumber, CurrencyIsoCode, RecordTypeId, QuoteType__c, Status, Approved_Status__c, isPrimary__c, JustificationandDescription__c, Special_Terms__c, ExpirationDate, Start_Date__c, End_Date__c, Auto_Renewal__c, Term_months__c, Initial_Term_POC__c, 
             Initial_Term__c, Initial_Term_months__c, ShippingAddress, PackageNameNew__c, Brand__c, PaymentMethod__c, Payment_Plan__c, Payment_Period__c, Total_Number_of_Digital_Lines__c, Opportunity.Tier_Name__c, Opportunity.ownerId, Opportunity.AccountId, Opportunity.Brand_Name__c, 
             Opportunity.Partner_Account__r.partner_type__c, Opportunity.Account.Name, Opportunity.Account.Most_Recent_Implementation_Contact__r.name, (SELECT ID,Product2Id,Product2.Name,Product_Family__c,Discount,ChargeTerm__c,TotalPrice,EffectivePriceNew__c,NewQuantity__c from QuoteLineItems),
             Opportunity.Name,Opportunity.Account.Customer_State__c, Opportunity.Account.Phone, Opportunity.CurrencyIsoCode, Opportunity.Account.BillingAddress, Opportunity.Account.BillingStreet, Opportunity.Account.BillingCity, Opportunity.Account.BillingCountry,
             Opportunity.Account.BillingState, Opportunity.Account.Preferred_Language__c, Opportunity.StageName, Opportunity.CloseDate,Opportunity.Portal_Cloud_Specialist__r.Name, Opportunity.Portal_Cloud_Specialist__r.Email,Opportunity.Portal_Cloud_Specialist__r.Phone, 
             Opportunity.Account.Partner_Contact__r.Name, Opportunity.Account.Partner_Contact__r.Email, Opportunity.Account.Partner_Contact__r.Phone, Opportunity.Segment_Name__c from Quote where Id = :quoteId];
  }

  public static List<Partner_Quote__c> getQuotes(Id opportunityId){
    return [SELECT Id, Name, Opportunity__c, CreatedDate, RecordTypeId, RecordType.Name, Name__c, Product_Edition__c, Status__c, Primary__c, Product_Edition__r.Name, Product_Edition__r.Product_Categories__c, Number_of_Licenses__c, Contract__c, Payment_Term__c, Brand_Name__c, CurrencyIsoCode FROM Partner_Quote__c WHERE Opportunity__c = :opportunityId and (RecordType.DeveloperName = 'Quote' OR RecordType.DeveloperName = 'Change_Order_Request') ORDER BY CreatedDate DESC];
  }

  public static List<Quote> getQuoteMain(Id opportunityId){
    return [SELECT Id, Package_Info__c FROM Quote WHERE OpportunityId = :opportunityId and isPrimary__c = true ORDER BY CreatedDate DESC];
  }

  public static String getOpportunity(Id opportunityId){
    return [SELECT Id, Name FROM Opportunity WHERE Id = :opportunityId][0].Name;
  }

  public static Account getAccount(Id AccountId){
    List<Account> accountList = [SELECT Id, Name FROM Account WHERE Id = :AccountId Limit 1];
    if (accountList != null) {
      return accountList[0];
    }
    return null;
  }

  @AuraEnabled
  public static Account_Change_Request__c getAccountChangeRequest(Id AccountChangeRequestId){
    return [SELECT Id, Accounts_Payable_email_address__c, Legal_City__c, Legal_Company_Name__c, Legal_Country__c, Legal_Physical_Address__c, Legal_State__c, Legal_Zip_Code__c, Account__c, Account_Cancellation_Date__c, Account_Cancellation_Reason__c, Company_Details__c, Cost_Center__c, Covert_POC_to_Paid_Account__c, Payment_Method__c, Primary_Contact_Email__c, Primary_Contact_First_Name__c, Primary_Contact_Last_Name__c, Refund_Request_Amount__c, Refund_Request_Reason__c, Tax_Exemption_Location_changes__c, Account__r.RC_Brand__c, Primary_Contact_Phone__c, Contract_Status_Change_To__c, Contract_Status_Request_Reason__c FROM Account_Change_Request__c WHERE Id = :AccountChangeRequestId LIMIT 1];
  }

  //Translation Start
  @AuraEnabled
  public static CommunityInfo.Translationswrap getTranslations(String objNames){
    return CommunityInfo.getTranslations(objNames);
  }

  //Translation End
  public static List<Partner_Quote_Line__c> getQuoteLines(Id quoteId){
    return [SELECT Product__c, CurrencyIsoCode, Approved_Quantity__c, Charge_Term__c, Product_Catalogue__r.LBOX_Rule_Lookup__c, Product_Catalogue__r.LBOX_Rule_Lookup__r.Rule_type__c, Product_Catalogue__r.LBOX_Rule_Lookup__r.Min_Range__c, Product_Catalogue__r.LBOX_Rule_Lookup__r.Max_Range__c, Product_Catalogue__r.Display_Name__c, Product__r.Name, List_Price__c, Partner_Quote__c, Product_Catalogue__c, Discount__c, Quantity__c, Effective_Price__c, Total_Price__c, Number_of_Employees__c, Number_of_Forecasted_ACO_Users__c, Location__c, Partner_Quote__r.Contract__c, Partner_Quote__r.Opportunity__r.Brand_Name__c, Discount_Number__c, Discount_Type__c FROM Partner_Quote_Line__c WHERE Partner_Quote__c = :quoteId ORDER BY Product_Catalogue__r.Output_Sort_Order__c];
  }

  public static List<Partner_Quote_Line__c> getQuoteLinesForSummary(Id quoteId){
    return [SELECT Product__c, CurrencyIsoCode, Approved_Quantity__c, Charge_Term__c, Product_Catalogue__r.LBOX_Rule_Lookup__c, Product_Catalogue__r.LBOX_Rule_Lookup__r.Rule_type__c, Product_Catalogue__r.LBOX_Rule_Lookup__r.Min_Range__c, Product_Catalogue__r.LBOX_Rule_Lookup__r.Max_Range__c, Product_Catalogue__r.Display_Name__c, Product__r.Name, List_Price__c, Partner_Quote__c, Product_Catalogue__c, Discount__c, Quantity__c, Effective_Price__c, Total_Price__c, Number_of_Employees__c, Number_of_Forecasted_ACO_Users__c, Location__c, Partner_Quote__r.Contract__c, Partner_Quote__r.Opportunity__r.Brand_Name__c, Discount_Number__c, Discount_Type__c FROM Partner_Quote_Line__c WHERE Partner_Quote__c = :quoteId ORDER BY Product_Catalogue__r.Sub_Category_Name__c, Product_Catalogue__r.Output_Sort_Order__c];
  }

  public static List<Partner_Quote_Line__c> getQuoteLinesForOutput(Id quoteId){
    return [SELECT Product__c, Product__r.Name, List_Price__c, Product_Catalogue__r.Category_Name__c, Product_Catalogue__r.Output_Display_Name__c, Partner_Quote__c, Product_Catalogue__c, Product_Catalogue__r.Plan__c, Discount__c, Quantity__c, Effective_Price__c, Total_Price__c, Product_Catalogue__r.Display_Name__c, Charge_Term__c, Number_of_Employees__c, Number_of_Forecasted_ACO_Users__c, Location__c, Product_Catalogue__r.Package_Product_Type__c, Partner_Quote__r.Contract__c, Partner_Quote__r.Opportunity__r.Brand_Name__c, Discount_Number__c, Discount_Type__c FROM Partner_Quote_Line__c WHERE Partner_Quote__c = :quoteId AND Product_Catalogue__r.Package_Product_Type__c EXCLUDES('Hide from output') ORDER BY Product_Catalogue__r.Output_Sort_Order__c NULLS LAST];
  }

  //<T1>****************
  public static List<Partner_Contract__c> getContracts(Id quoteId){
    return [SELECT Id, Status__c, Name, Partner_Quote__c, (select Id, Clause__c, Term__c from Partner_Contract_Details__r) FROM Partner_Contract__c WHERE Partner_Quote__c = :quoteId and Status__c = 'Approved'];
  }

  public static List<Partner_Contract_Service__c> getContractService(Id quoteId){
    return [SELECT Id, Minimum_Target__c, Minimum_Target_Effective_Date__c, Partner_Contract_Detail__c FROM Partner_Contract_Service__c WHERE Partner_Contract_Detail__r.Partner_Contract__r.Partner_Quote__c = :quoteId];
  }

  //</T1>****************
  public static void deleteQuote(Id quoteId){
    Partner_Quote__c objQuoteToDelete = new Partner_Quote__c(id = quoteId);
    delete objQuoteToDelete;
  }

  public static Id cloneQuote(Id quoteId){
    Id templateRecordTypeId = Schema.SObjectType.Partner_Quote__c.getRecordTypeInfosByName().get('Quote Template').getRecordTypeId();
    Id QuoteRecordTypeId = Schema.SObjectType.Partner_Quote__c.getRecordTypeInfosByName().get('Quote').getRecordTypeId();
    Partner_Quote__c objQuote = getQuote(quoteId);
    Partner_Quote__c objClonedQuote = objQuote.clone(false, true, false, false);
    if (templateRecordTypeId == objClonedQuote.RecordTypeId){
      objClonedQuote.RecordTypeId = QuoteRecordTypeId;
    }
    objClonedQuote.Status__c = QUOTE_STATUS_DRAFT;
    insert objClonedQuote;

    List<Partner_Quote_Line__c> listOfClonedQuoteLines = new List<Partner_Quote_Line__c>();
    for (Partner_Quote_Line__c eachLine : getQuoteLines(quoteId)){
      Partner_Quote_Line__c objClonedLine = eachLine.clone(false, true, false, false);
      objClonedLine.Partner_Quote__c = objClonedQuote.id;
      listOfClonedQuoteLines.add(objClonedLine);
    }

    if (!listOfClonedQuoteLines.isEmpty()) {
      insert listOfClonedQuoteLines;
    }
    return objClonedQuote.id;
  }

  public static List<QuotePlanAndPricingController.ProductWrapper> getProductsFromQuote(Id quoteId){
    Partner_Quote__c objQuote = getQuote(quoteId);
    List<QuotePlanAndPricingController.ProductWrapper> listOfWrapperRecords = new List<QuotePlanAndPricingController.ProductWrapper>();

    List<Partner_Quote_Line__c> listOfQuoteLines = getQuoteLinesForSummary(quoteId);
    Set<Id> setOfProductIds = new Set<Id>();
    for (Partner_Quote_Line__c eachQuoteLine : listOfQuoteLines){
      setOfProductIds.add(eachQuoteLine.Product_Catalogue__c);
    }
    Map<Id, Product_Catalogue__c> mapOfProductIdVsCatalogue = new Map<Id, Product_Catalogue__c>();
    for (Product_Catalogue__c eachCat : [SELECT id, Parent__c, LBOX_Rule_Lookup__c, Plan__c, Product_Catalogue_Rule__c, Default_Quantity__c, Package_Product_Type__c, Product__c, Display_Name__c, Contract_Discount__c, Category_Name__c, Sub_Category_Name__c, Quantity_Dependent_Product_1__c, Quantity_Dependent_Product_2__c, Product_Package__r.Name, (SELECT No_of_Licenses__c, Contract_Discount__c, Monthly_Price__c, Yearly_Price__c, CurrencyIsoCode FROM Product_Tier_Prices__r WHERE CurrencyIsoCode = :objQuote.CurrencyIsoCode ORDER BY No_of_Licenses__c) FROM Product_Catalogue__c WHERE ID IN:setOfProductIds]){
      mapOfProductIdVsCatalogue.put(eachCat.Product__c, eachCat);
    }
    String productSubCategory;
    Map<Id, Product_Catalogue_Rule__c> mapIdVsRule = getRuleMap();
    for (Partner_Quote_Line__c eachQuoteLine : listOfQuoteLines){
      Product_Catalogue_Rule__c lboxRule;
      Product2 objProduct = new Product2(id = eachQuoteLine.Product__c, Name = eachQuoteLine.Product__r.Name);
      Product_Catalogue__c objCatalogue = mapOfProductIdVsCatalogue.get(objProduct.id);
      Product_Catalogue_Rule__c objRule = mapIdVsRule.get(objCatalogue.Product_Catalogue_Rule__c);

      QuotePlanAndPricingController.ProductWrapper newRecord;
      if (productSubCategory != objCatalogue.Sub_Category_Name__c){
        String headerTitle = objCatalogue.Sub_Category_Name__c;

        newRecord = new QuotePlanAndPricingController.ProductWrapper(headerTitle, null, 'Header', null, null, null, null, null, null, true, null, null, null, null, null, null);
        listOfWrapperRecords.add(newRecord);
      }
      productSubCategory = objCatalogue.Sub_Category_Name__c;
      //System.assert(false,objRule);
      newRecord = new QuotePlanAndPricingController.ProductWrapper(null, objProduct, 'Record', null, null, objRule, null, objCatalogue, null, true, null, null, null, null, null, null);
      newRecord.listPrice = eachQuoteLine.List_Price__c;
      newRecord.partnerDiscount = eachQuoteLine.Discount_Number__c;
      newRecord.discountType = eachQuoteLine.Discount_Type__c;
      newRecord.quantity = Integer.valueOf(eachQuoteLine.Quantity__c);
      newRecord.netPrice = eachQuoteLine.Total_Price__c;
      newRecord.objQuoteLine = eachQuoteLine;
      if (objCatalogue.Package_Product_Type__c != null && objCatalogue.Package_Product_Type__c.contains('Header')){
        newRecord.netPrice = null;
      }
      listOfWrapperRecords.add(newRecord);
    }

    return listOfWrapperRecords;
  }

  public static List<QuotePlanAndPricingController.AdditionalProductWrapper> getProductCategories(Id editionId, Partner_Quote__c objQuote){
    Boolean isInitialOrder = true;
    List<Deal_Support__c> listDS = new List<Deal_Support__c>([Select Id, Name From Deal_Support__c Where Opportunity__c = :objQuote.Opportunity__c And Type__c = 'Engage ProServ']);
    if (listDS != null && listDS.size() > 0){
      isInitialOrder = false;
    }
    Map<string, List<String>> mapOfCategoryVsSubCategory = new Map<string, List<String>>();
    Map<string, List<QuotePlanAndPricingController.optionWrapper>> mapOfCategoryVsoptionWrapper = new Map<String, List<QuotePlanAndPricingController.optionWrapper>>();
    for (Product_Catalogue__c eachProduct : [SELECT Category_Name__c, (SELECT No_of_Licenses__c, Monthly_Price__c, Yearly_Price__c, CurrencyIsoCode FROM Product_Tier_Prices__r ORDER BY No_of_Licenses__c), Sub_Category_Name__c, Product_Package__r.Name FROM Product_Catalogue__c WHERE Product_Package__c = :editionId AND Category_Name__c != null AND Active__c = true AND Category_Name__c IN ('Add-Ons', 'International', 'Phones', 'Conferencing', 'Service', 'Bundles', 'Implementation', 'Others', 'Other Devices')]){
      List<String> subCategories;
      //Start recent changes 8/5
      List<QuotePlanAndPricingController.optionWrapper> optionWrapperList;
      if (eachProduct.Sub_Category_Name__c != null){
        if (!eachProduct.Product_Tier_Prices__r.isEmpty()){
          Boolean hasCurrencyPrice = checkIfTierPriceExist(eachProduct, objQuote.CurrencyIsoCode);
          if (!hasCurrencyPrice){
            continue;
          }
        }
        // END 8-5
        subCategories = new List<String>();
        optionWrapperList = new List<QuotePlanAndPricingController.optionWrapper>();
        string SbCategName = eachProduct.Category_Name__c;
        if (mapOfCategoryVsSubCategory.get(SbCategName) != null){
          subCategories = mapOfCategoryVsSubCategory.get(SbCategName);
          optionWrapperList = mapOfCategoryVsoptionWrapper.get(SbCategName);
        }

        if (!subCategories.contains(eachProduct.Sub_Category_Name__c)){
          QuotePlanAndPricingController.optionWrapper objWrapper = new QuotePlanAndPricingController.optionWrapper();
          objWrapper.value = eachProduct.Sub_Category_Name__c;
          objWrapper.label = eachProduct.Sub_Category_Name__c;

          objWrapper.selected = false;
          optionWrapperList.add(objWrapper);
          subCategories.add(eachProduct.Sub_Category_Name__c);
        }
      
        mapOfCategoryVsSubCategory.put(eachProduct.Category_Name__c, subCategories);
        mapOfCategoryVsoptionWrapper.put(eachProduct.Category_Name__c, optionWrapperList);
      }

    }

    List<QuotePlanAndPricingController.AdditionalProductWrapper> listOfAddProductsWrapper = new List<QuotePlanAndPricingController.AdditionalProductWrapper>();
    for (String eachCategory : mapOfCategoryVsSubCategory.keyset()){
      List<String> subCategories = mapOfCategoryVsSubCategory.get(eachCategory);
      List<QuotePlanAndPricingController.optionWrapper> optionWrapper = mapOfCategoryVsoptionWrapper.get(eachCategory);
      QuotePlanAndPricingController.AdditionalProductWrapper objWrapper = new QuotePlanAndPricingController.AdditionalProductWrapper(eachCategory, null, subCategories, optionWrapper, isInitialOrder);
      listOfAddProductsWrapper.add(objWrapper);
    }
    return listOfAddProductsWrapper;
  }

  public static List<QuotePlanAndPricingController.ProductWrapper> getProductsForEdition(Id quoteId, String packageProductType, String categoryName, Boolean showQuoteLinesOnly, List<String> selectedSubCategory){
    Map<Id, Set<Id>> mapOfParentIdVsChildIds = new Map<Id, Set<Id>>();
    Set<Id> setOfProductIds = new Set<Id>();
    Set<Id> setOfCatalogueIds = new Set<Id>();
    Partner_Quote__c objQuote = getQuote(quoteId);
    List<QuotePlanAndPricingController.ProductWrapper> listOfProductWrapper = new List<QuotePlanAndPricingController.ProductWrapper>();
    Map<Id, Product_Catalogue__c> mapOfProductIdVsCatalogue = new Map<Id, Product_Catalogue__c>();
    String productCategory;
    String productRule;
    List<Product_Catalogue__c> listOfProductCats;
    if (showQuoteLinesOnly == null) {
      showQuoteLinesOnly = false;
    }
    Map<Id, Partner_Quote_Line__c> mapOfIdVsExistingProduct = new Map<Id, Partner_Quote_Line__c>();
    Map<Id, Integer> mapOfProductCatalogueIdVsQuantity = new Map<Id, Integer>();
    Integer domesticAndUnlimitedLicenses = 0;
    for (Partner_Quote_Line__c eachQuoteLine : getQuoteLines(quoteId)){
      mapOfIdVsExistingProduct.put(eachQuoteLine.Product__c, eachQuoteLine);
      if (eachQuoteLine.Quantity__c != null){
        mapOfProductCatalogueIdVsQuantity.put(eachQuoteLine.Product_Catalogue__c, Integer.valueOf(eachQuoteLine.Quantity__c));
        if (eachQuoteLine.Product_Catalogue__r != null){
          if (eachQuoteLine.Product_Catalogue__r.Display_Name__c != null){
            if (eachQuoteLine.Product_Catalogue__r.Display_Name__c.contains('DigitalLine Unlimited') || eachQuoteLine.Product_Catalogue__r.Display_Name__c.contains('MS Teams CloudPBX - Domestic') || eachQuoteLine.Product_Catalogue__r.Display_Name__c.contains('DigitalLine BYOC')){
              domesticAndUnlimitedLicenses = domesticAndUnlimitedLicenses + Integer.valueOf(eachQuoteLine.Quantity__c);
            }
          }
        }
      }
      //AS Start
      if (eachQuoteLine.Product_Catalogue__r.LBOX_Rule_Lookup__c != null && eachQuoteLine.Product_Catalogue__r.LBOX_Rule_Lookup__r.Rule_type__c == 'LB'){
        if (mapOfLboxRuleIdToTotalQuantiy.containsKey(eachQuoteLine.Product_Catalogue__r.LBOX_Rule_Lookup__c)){
          mapOfLboxRuleIdToTotalQuantiy.put(eachQuoteLine.Product_Catalogue__r.LBOX_Rule_Lookup__c, mapOfLboxRuleIdToTotalQuantiy.get(eachQuoteLine.Product_Catalogue__r.LBOX_Rule_Lookup__c) + Integer.valueof(eachQuoteLine.Quantity__c));
        }
        else{
          mapOfLboxRuleIdToTotalQuantiy.put(eachQuoteLine.Product_Catalogue__r.LBOX_Rule_Lookup__c, Integer.valueof(eachQuoteLine.Quantity__c));
        }
      }
      // AS End
    }
    Id editionId = objQuote.Product_Edition__c;
    if (categoryName == null || categoryName == ''){
      if (showQuoteLinesOnly){
        listOfProductCats = [SELECT id, Plan__c, Product__c, LBOX_Rule_Lookup__c, LBOX_Rule_Lookup__r.Rule_type__c, LBOX_Rule_Lookup__r.Min_Range__c, LBOX_Rule_Lookup__r.Max_Range__c, Parent__c, Parent__r.Product__c, Parent__r.Parent__c, Parent__r.Parent__r.Product__c, Parent__r.Parent__r.Parent__c, Color__c, Product_Catalogue_Rule__c, Product_Catalogue_Rule__r.Count_Dependent_On__c, Display_Name__c, Package_Product_Type__c, Category_Name__c, Sub_Category_Name__c, Product_Package__r.Name, (SELECT No_of_Licenses__c, Monthly_Price__c, Yearly_Price__c, CurrencyIsoCode FROM Product_Tier_Prices__r ORDER BY No_of_Licenses__c) FROM Product_Catalogue__c WHERE Active__c = true AND Product_Package__c = :editionId AND Product__c IN:mapOfIdVsExistingProduct.keyset() AND Hide_a_product__c EXCLUDES( :objQuote.Opportunity__r.Account.BillingCountry) ORDER BY Row_Order__c ASC];
      }
      else{
        listOfProductCats = [SELECT id, Plan__c, Product__c, LBOX_Rule_Lookup__c, LBOX_Rule_Lookup__r.Rule_type__c, LBOX_Rule_Lookup__r.Min_Range__c, LBOX_Rule_Lookup__r.Max_Range__c, Parent__c, Parent__r.Product__c, Parent__r.Parent__c, Parent__r.Parent__r.Product__c, Parent__r.Parent__r.Parent__r.Product__c, Parent__r.Parent__r.Parent__c, Color__c, Product_Catalogue_Rule__c, Product_Catalogue_Rule__r.Count_Dependent_On__c, Product_Package__r.Name, Display_Name__c, Package_Product_Type__c, Category_Name__c, Sub_Category_Name__c, (SELECT No_of_Licenses__c, Monthly_Price__c, Yearly_Price__c, CurrencyIsoCode FROM Product_Tier_Prices__r ORDER BY No_of_Licenses__c) FROM Product_Catalogue__c WHERE Active__c = true AND Product_Package__c = :editionId AND (Package_Product_Type__c INCLUDES( :packageProductType)) AND Product_Package__c = :editionId AND Hide_a_product__c EXCLUDES( :objQuote.Opportunity__r.Account.BillingCountry) ORDER BY Row_Order__c ASC];
      }
    }
    else{
      if (showQuoteLinesOnly){
        listOfProductCats = [SELECT id, Product__c, Plan__c, LBOX_Rule_Lookup__c, LBOX_Rule_Lookup__r.Rule_type__c, LBOX_Rule_Lookup__r.Min_Range__c, LBOX_Rule_Lookup__r.Max_Range__c, Parent__c, Parent__r.Product__c, Parent__r.Parent__c, Parent__r.Parent__r.Product__c, Parent__r.Parent__r.Parent__c, Color__c, Product_Catalogue_Rule__c, Product_Catalogue_Rule__r.Count_Dependent_On__c, Display_Name__c, Package_Product_Type__c, Category_Name__c, Sub_Category_Name__c, Product_Package__r.Name, (SELECT No_of_Licenses__c, Monthly_Price__c, Yearly_Price__c, CurrencyIsoCode FROM Product_Tier_Prices__r ORDER BY No_of_Licenses__c) FROM Product_Catalogue__c WHERE Active__c = true AND Product_Package__c = :editionId AND Product__c IN:mapOfIdVsExistingProduct.keyset() AND Hide_a_product__c EXCLUDES( :objQuote.Opportunity__r.Account.BillingCountry) ORDER BY Row_Order__c ASC];
      }
      else if (selectedSubCategory != null && !selectedSubCategory.isEmpty()){
        listOfProductCats = [SELECT id, Product__c, Plan__c, LBOX_Rule_Lookup__c, LBOX_Rule_Lookup__r.Rule_type__c, LBOX_Rule_Lookup__r.Min_Range__c, LBOX_Rule_Lookup__r.Max_Range__c, Parent__c, Parent__r.Product__c, Parent__r.Parent__c, Parent__r.Parent__r.Product__c, Parent__r.Parent__r.Parent__c, Color__c, Category_Name__c, Sub_Category_Name__c, Product_Package__r.Name, Product_Catalogue_Rule__c, Product_Catalogue_Rule__r.Count_Dependent_On__c, Display_Name__c, Package_Product_Type__c, (SELECT No_of_Licenses__c, Monthly_Price__c, Yearly_Price__c, CurrencyIsoCode FROM Product_Tier_Prices__r ORDER BY No_of_Licenses__c) FROM Product_Catalogue__c WHERE Active__c = true AND Product_Package__c = :editionId AND (Package_Product_Type__c INCLUDES( :packageProductType)) AND Category_Name__c = :categoryName AND Sub_Category_Name__c IN:selectedSubCategory AND Product_Package__c = :editionId AND Hide_a_product__c EXCLUDES( :objQuote.Opportunity__r.Account.BillingCountry) ORDER BY Row_Order__c ASC];
      }
      else{
        listOfProductCats = [SELECT id, Product__c, Plan__c, LBOX_Rule_Lookup__c, LBOX_Rule_Lookup__r.Rule_type__c, LBOX_Rule_Lookup__r.Min_Range__c, LBOX_Rule_Lookup__r.Max_Range__c, Parent__c, Parent__r.Product__c, Parent__r.Parent__c, Parent__r.Parent__r.Product__c, Parent__r.Parent__r.Parent__c, Color__c, Category_Name__c, Sub_Category_Name__c, Product_Package__r.Name, Product_Catalogue_Rule__c, Product_Catalogue_Rule__r.Count_Dependent_On__c, Display_Name__c, Package_Product_Type__c, (SELECT No_of_Licenses__c, Monthly_Price__c, Yearly_Price__c, CurrencyIsoCode FROM Product_Tier_Prices__r ORDER BY No_of_Licenses__c) FROM Product_Catalogue__c WHERE Active__c = true AND Product_Package__c = :editionId AND (Package_Product_Type__c INCLUDES( :packageProductType)) AND Category_Name__c = :categoryName AND Product_Package__c = :editionId AND Hide_a_product__c EXCLUDES( :objQuote.Opportunity__r.Account.BillingCountry) ORDER BY Row_Order__c ASC];
      }
    }

    for (Product_Catalogue__c eachCatalogue : listOfProductCats){
      if (!eachCatalogue.Product_Tier_Prices__r.isEmpty()){
        Boolean hasCurrencyPrice = checkIfTierPriceExist(eachCatalogue, objQuote.CurrencyIsoCode);
        if (!hasCurrencyPrice){
          continue;
        }
      }

      if (!objQuote.Contract__c && eachCatalogue.Package_Product_Type__c != null && eachCatalogue.Package_Product_Type__c.contains('Rental Product')){
        continue;
      }
      setOfProductIds.add(eachCatalogue.Product__c);
      setOfCatalogueIds.add(eachCatalogue.id);

      //Level 1
      if (eachCatalogue.Parent__c != null){
        mapOfParentIdVsChildIds = addRelationship(mapOfParentIdVsChildIds, eachCatalogue.Product__c, eachCatalogue.Parent__r.Product__c);
        setOfProductIds.add(eachCatalogue.Parent__r.Product__c);
        setOfCatalogueIds.add(eachCatalogue.Parent__c);
      }
      //Level 2
      if (eachCatalogue.Parent__r.Parent__c != null){
        mapOfParentIdVsChildIds = addRelationship(mapOfParentIdVsChildIds, eachCatalogue.Parent__r.Product__c, eachCatalogue.Parent__r.Parent__r.Product__c);
        setOfProductIds.add(eachCatalogue.Parent__r.Parent__r.Product__c);
        setOfCatalogueIds.add(eachCatalogue.Parent__r.Parent__c);
      }
      //Level 3
      if (eachCatalogue.Parent__r.Parent__r.Parent__c != null){
        mapOfParentIdVsChildIds = addRelationship(mapOfParentIdVsChildIds, eachCatalogue.Parent__r.Parent__r.Product__c, eachCatalogue.Parent__r.Parent__r.Parent__r.Product__c);
        setOfProductIds.add(eachCatalogue.Parent__r.Parent__r.Parent__r.Product__c);
        setOfCatalogueIds.add(eachCatalogue.Parent__r.Parent__r.Parent__c);
      }
    }

    for (Product_Catalogue__c eachCatalogue : [SELECT id, Product__c, LBOX_Rule_Lookup__c, LBOX_Rule_Lookup__r.Rule_type__c, LBOX_Rule_Lookup__r.Min_Range__c, LBOX_Rule_Lookup__r.Max_Range__c, Parent__c, Product_Catalogue_Rule__c, Display_Name__c, Package_Product_Type__c, Color__c, Product_Catalogue_Rule__r.Count_Dependent_On__c, Category_Name__c, Sub_Category_Name__c, Plan__c, Contract_Discount__c, Default_Quantity__c, Row_Order__c, Has_Child__c, Discount_Limit__c, Help_Text__c, Recommended_for_Of_Licneses__c, Quantity_Dependent_Product_1__c, Quantity_Dependent_Product_2__c, Product_Package__r.Name, (SELECT Contract_Discount__c, CurrencyIsoCode, No_of_Licenses__c, Monthly_Price__c, Yearly_Price__c FROM Product_Tier_Prices__r ORDER BY No_of_Licenses__c) FROM Product_Catalogue__c WHERE id IN:setOfCatalogueIds]){
      if (!eachCatalogue.Product_Tier_Prices__r.isEmpty()){
        Boolean hasCurrencyPrice = checkIfTierPriceExist(eachCatalogue, objQuote.CurrencyIsoCode);
        if (!hasCurrencyPrice){
          continue;
        }
      }

      mapOfProductIdVsCatalogue.put(eachCatalogue.Product__c, eachCatalogue);
    }

    String partnerDiscountApproval = [SELECT Partner_Discount_Approval__c FROM User WHERE Id = :UserInfo.getUserId()].Partner_Discount_Approval__c;
    Map<Id, Product_Catalogue_Rule__c> mapOfIdVsRule = getRuleMap();

    Map<Id, Product2> mapOfIdVsProduct = new Map<Id, Product2>([SELECT Name, Description, Product_Category__c, Family, Parent__c, ProductCode FROM Product2 WHERE ID IN:setOfProductIds]);
    for (Product_Catalogue__c objCatalogue : listOfProductCats){
      if (!objCatalogue.Product_Tier_Prices__r.isEmpty()){
        Boolean hasCurrencyPrice = checkIfTierPriceExist(objCatalogue, objQuote.CurrencyIsoCode);
        if (!hasCurrencyPrice){
          continue;
        }
      }
      Product_Catalogue_Rule__c lboxRule;
      Product2 eachProduct = mapOfIdVsProduct.get(objCatalogue.Product__c);
      if (eachProduct == null) {
        continue;
      }
      objCatalogue = mapOfProductIdVsCatalogue.get(eachProduct.id);
      Product_Catalogue_Rule__c objRule = mapOfIdVsRule.get(objCatalogue.Product_Catalogue_Rule__c);
      if (mapOfIdVsRule.containsKey(objCatalogue.LBOX_Rule_Lookup__c)) {
        lboxRule = mapOfIdVsRule.get(objCatalogue.LBOX_Rule_Lookup__c);
      }

      String rowColor = DEFAULT_ROW_COLOR;
      if (objRule != null && objRule.Color__c != null) {
        rowColor = objRule.Color__c;
      }
      String rowIcon = '';
      String rowIconVariant = 'success';
      if (objCatalogue != null && objCatalogue.Parent__c == null){
        List<Product_Tier_Price__c> listOfTiers = objCatalogue.Product_Tier_Prices__r;
        QuotePlanAndPricingController.ProductWrapper newRecord;
        populateWrapper(objQuote, eachProduct, listOfProductWrapper, mapOfIdVsProduct, mapOfParentIdVsChildIds, listOfTiers, mapOfProductIdVsCatalogue, mapOfIdVsRule, objRule, lboxRule, objCatalogue, mapOfIdVsExistingProduct, 0, rowColor, '', null, rowIcon, rowIconVariant, productRule, showQuoteLinesOnly, true, partnerDiscountApproval, mapOfProductCatalogueIdVsQuantity, domesticAndUnlimitedLicenses);
        productCategory = objCatalogue.Category_Name__c;
        productRule = objCatalogue.Product_Catalogue_Rule__c;
      }
    }
    return populateRuleInfo(listOfProductWrapper, showQuoteLinesOnly);
  }

  private static void populateWrapper(Partner_Quote__c objQuote, Product2 objParentProduct, List<QuotePlanAndPricingController.ProductWrapper> listOfProductWrapper, Map<Id, Product2> mapOfIdVsProduct, Map<Id, Set<Id>> mapOfParentIdVsChildIds, List<Product_Tier_Price__c> listOfTiers, Map<Id, Product_Catalogue__c> mapOfProductIdVsCatalogue, Map<Id, Product_Catalogue_Rule__c> mapOfIdVsRule, Product_Catalogue_Rule__c objRule, Product_Catalogue_Rule__c lboxRule, Product_Catalogue__c objCatalogue, Map<Id, Partner_Quote_Line__c> mapOfIdVsExistingProduct, Integer hierarchyLevel, String rowColor, String leftSpace, Id parentId, String rowIcon, String rowIconVariant, String productRule, Boolean showQuoteLinesOnly, Boolean isParent, String partnerDiscountApproval, Map<Id, Integer> mapOfProductCatalogueIdVsQuantity, Integer domesticAndUnlimitedLicenses){

    QuotePlanAndPricingController.ProductWrapper newRecord;
    Set<Id> listOfChildProductIds = mapOfParentIdVsChildIds.get(objParentProduct.id);
    if (listOfChildProductIds != null && listOfChildProductIds.contains(null)){
       //Null removal added as fix for BZS-4308
      listOfChildProductIds.remove(null);
    }
    List<QuotePlanAndPricingController.ProductWrapper> listOfChildProducts;
    Boolean isSelected = false;
    Partner_Quote_Line__c objPartnerQuoteLine = mapOfIdVsExistingProduct.get(objParentProduct.id);
    if (objPartnerQuoteLine != null){
      isSelected = true;
    }

    if (objCatalogue.Package_Product_Type__c != null && objCatalogue.Package_Product_Type__c.contains('Header')){
      newRecord = new QuotePlanAndPricingController.ProductWrapper(objCatalogue.Category_Name__c, objParentProduct, 'Header Product', listOfChildProducts, listOfTiers, objRule, lboxRule, objCatalogue, objPartnerQuoteLine, isSelected, hierarchyLevel, rowColor, leftSpace, parentId, rowIcon, rowIconVariant);
    }
    else{
      //Rule Header
      if (!showQuoteLinesOnly && objRule != null && objRule.Show_Header__c && productRule != objRule.Id && !objCatalogue.Has_child__c){
        newRecord = new QuotePlanAndPricingController.ProductWrapper(objRule.Header_Text__c, objParentProduct, 'Rule Header', null, null, null, lboxRule, null, null, false, hierarchyLevel, objRule.Header_Color__c, null, null, null, null);
        listOfProductWrapper.add(newRecord);
      }

      if (objQuote.Payment_Term__c != null && objCatalogue.Plan__c != 'One - Time'){
        objCatalogue.Plan__c = objQuote.Payment_Term__c;
        if (objQuote.Payment_Term__c == 'Monthly' && objQuote.Contract__c != null && objQuote.Contract__c){
          objCatalogue.Plan__c += ' Contract';
        }
      }
      newRecord = new QuotePlanAndPricingController.ProductWrapper(objCatalogue.Category_Name__c, objParentProduct, 'Record', listOfChildProducts, listOfTiers, objRule, lboxRule, objCatalogue, objPartnerQuoteLine, isSelected, hierarchyLevel, rowColor, leftSpace, parentId, rowIcon, rowIconVariant);
      if (partnerDiscountApproval == null || partnerDiscountApproval == 'None'){
        newRecord.isDiscountDisabled = true;
      }
      //BZS-5115
      if (objQuote != null){
        if (objQuote.Opportunity__c != null && objQuote.Opportunity__r.Brand_Name__c != null){
          If ((objQuote.Contract__c == false) && ((objQuote.Opportunity__r.Brand_Name__c == 'RingCentral') || (objQuote.Opportunity__r.Brand_Name__c == 'RingCentral UK') || (objQuote.Opportunity__r.Brand_Name__c == 'RingCentral Canada') || (objQuote.Opportunity__r.Brand_Name__c == 'RingCentral EU') || (objQuote.Opportunity__r.Brand_Name__c == 'RingCentral AU'))){
            newRecord.isDiscountDisabled = true;
          }
        }
      }
    }
    Integer quantity = 0;
    if (objPartnerQuoteLine != null && objPartnerQuoteLine.Quantity__c != null){
      if (mapOfLboxRuleIdToTotalQuantiy.containsKey(objPartnerQuoteLine.Product_Catalogue__r.LBOX_Rule_Lookup__c)){
        quantity = mapOfLboxRuleIdToTotalQuantiy.get(objPartnerQuoteLine.Product_Catalogue__r.LBOX_Rule_Lookup__c);
      }
      else{
        quantity = Integer.valueOf(objPartnerQuoteLine.Quantity__c);
      }
      newRecord.quantity = Integer.valueOf(objPartnerQuoteLine.Quantity__c);
      newRecord.partnerDiscount = objPartnerQuoteLine.Discount_Number__c;
      newRecord.discountType = objPartnerQuoteLine.Discount_Type__c;

    }
    //BZS-5115
    if (objPartnerQuoteLine != null && newRecord.partnerDiscount > 0){
      If ((objPartnerQuoteLine.Partner_Quote__r.Contract__c == false) && ((objPartnerQuoteLine.Partner_Quote__r.Opportunity__r.Brand_Name__c == 'RingCentral') || (objPartnerQuoteLine.Partner_Quote__r.Opportunity__r.Brand_Name__c == 'RingCentral UK') || (objPartnerQuoteLine.Partner_Quote__r.Opportunity__r.Brand_Name__c == 'RingCentral Canada') || (objPartnerQuoteLine.Partner_Quote__r.Opportunity__r.Brand_Name__c == 'RingCentral EU') || (objPartnerQuoteLine.Partner_Quote__r.Opportunity__r.Brand_Name__c == 'RingCentral AU'))){
        newRecord.isDiscountDisabled = true;
        newRecord.partnerDiscount = 0;
      }
    }

    if (newRecord.objCatalogue != null && newRecord.objCatalogue.Quantity_Dependent_Product_1__c != null){
      quantity = 0;
      Id dependentProductId = newRecord.objCatalogue.Quantity_Dependent_Product_1__c;
      Integer dependentProduct1Quantity = mapOfProductCatalogueIdVsQuantity.get(dependentProductId);
      if (dependentProduct1Quantity != null) {
        quantity = quantity + dependentProduct1Quantity;
      }
    }
    String productPackageType = objCatalogue.Package_Product_Type__c;
    if ((objCatalogue.Category_Name__c == 'Service' || objCatalogue.Category_Name__c == 'International' || objCatalogue.Category_Name__c == 'Conferencing') && (objCatalogue.Sub_Category_Name__c == 'Service' || objCatalogue.Sub_Category_Name__c == 'MS Teams' || objCatalogue.Sub_Category_Name__c == 'Global Office' || objCatalogue.Sub_Category_Name__c == 'Global MVP' || objCatalogue.Sub_Category_Name__c == 'Mobile') && !productPackageType.contains('Header') && !productPackageType.contains('Service Fee')){
      quantity = domesticAndUnlimitedLicenses;
    }

    Decimal listPriceMonthly = -1;
    Decimal listPriceYearly = -1;
    Decimal contractDiscount;
    listOfTiers = objCatalogue.Product_Tier_Prices__r;
    if (listOfTiers != null && !listOfTiers.isEmpty()){
      for (Product_Tier_Price__c eachTier : listOfTiers){
        if (eachTier.CurrencyIsoCode == objQuote.CurrencyIsoCode && quantity <= eachTier.No_of_Licenses__c){
          listPriceMonthly = eachTier.Monthly_Price__c;
          listPriceYearly = eachTier.Yearly_Price__c;
          contractDiscount = eachTier.Contract_Discount__c;
          break;
        }
      }
      if (listPriceMonthly == -1) {
        listPriceMonthly = listOfTiers[listOfTiers.size() - 1].Monthly_Price__c;
      }
      if (listPriceYearly == -1) {
        listPriceYearly = listOfTiers[listOfTiers.size() - 1].Yearly_Price__c;
      }
    }
    if (listPriceMonthly == -1) {
      listPriceMonthly = 0;
    }
    if (listPriceYearly == -1) {
      listPriceYearly = 0;
    }
    if (objQuote.Payment_Term__c == 'Monthly'){
      newRecord.listPrice = listPriceMonthly;
      if (objQuote.Contract__c){
        if (contractDiscount != null){
          newRecord.listPrice -= ContractDiscount;
        }
        else if (newRecord.objCatalogue.Contract_Discount__c != null){
          newRecord.listPrice -= newRecord.objCatalogue.Contract_Discount__c;
        }
      }
    }
    else{
      newRecord.listPrice = listPriceYearly;
    }
    if (newRecord.listPrice != null && newRecord.quantity != null){
      if (newRecord.partnerDiscount == 100) {
        newRecord.listPrice = 0;
      } else if (newRecord.partnerDiscount > 0 && newRecord.discountType == '%'){
        newRecord.listPrice -= ((newRecord.listPrice * newRecord.partnerDiscount) / 100);
      }
      else if (newRecord.partnerDiscount > 0 && newRecord.discountType == 'Amt'){
        newRecord.listPrice -= newRecord.partnerDiscount;
      }
      newRecord.netPrice = newRecord.listPrice.setScale(2, RoundingMode.HALF_UP) * newRecord.quantity;
    }
    listOfProductWrapper.add(newRecord);
    if (listOfChildProductIds != null){
      listOfChildProducts = new List<QuotePlanAndPricingController.ProductWrapper>();

      for (Id eachChildProductId : listOfChildProductIds){
        Product_Catalogue_Rule__c lboxRule1;
        rowIcon = null;
        rowIconVariant = null;
        Product2 objChildProduct = mapOfIdVsProduct.get(eachChildProductId);
        Product_Catalogue__c objCatalogue1 = mapOfProductIdVsCatalogue.get(eachChildProductId);
        Product_Catalogue_Rule__c objRule1 = mapOfIdVsRule.get(objCatalogue1.Product_Catalogue_Rule__c);
        if (mapOfIdVsRule.containsKey(objCatalogue1.LBOX_Rule_Lookup__c)) {
          lboxRule1 = mapOfIdVsRule.get(objCatalogue1.LBOX_Rule_Lookup__c);
        }
        rowColor = DEFAULT_ROW_COLOR;
        if (objRule1 != NULL && objRule1.Color__c != NULL) {
          rowColor = objRule1.Color__c;
        }
        listOfTiers = objCatalogue.Product_Tier_Prices__r;
        populateWrapper(objQuote, objChildProduct, listOfProductWrapper, mapOfIdVsProduct, mapOfParentIdVsChildIds, listOfTiers, mapOfProductIdVsCatalogue, mapOfIdVsRule, objRule1, lboxRule1, objCatalogue1, mapOfIdVsExistingProduct, hierarchyLevel + 1, rowColor, leftSpace + '&nbsp;&nbsp;&nbsp;&nbsp;', objParentProduct.id, rowIcon, rowIconVariant, productRule, showQuoteLinesOnly, false, partnerDiscountApproval, mapOfProductCatalogueIdVsQuantity, domesticAndUnlimitedLicenses);
        if (objRule1 != null) {
          productRule = objRule1.Id;
        }
      }
    }
  }

  //This method can be merged with validateRule method.
  @testvisible
  private static List<QuotePlanAndPricingController.ProductWrapper> populateRuleInfo(List<QuotePlanAndPricingController.ProductWrapper> listOfProducts, Boolean showQuoteLinesOnly){

    Map<Id, List<QuotePlanAndPricingController.ProductWrapper>> mapOfRuleIdVsProducts = new Map<Id, List<QuotePlanAndPricingController.ProductWrapper>>();
    Map<Id, QuotePlanAndPricingController.ProductWrapper> mapOfCatalogueIdVsRecord = new Map<Id, QuotePlanAndPricingController.ProductWrapper>();
    Map<Id, Id> mapOfRuleIdVsParentId = new Map<Id, Id>();
    Map<Id, QuotePlanAndPricingController.ProductWrapper> mapOfProductIdVsProduct = new Map<Id, QuotePlanAndPricingController.ProductWrapper>();

    for (QuotePlanAndPricingController.ProductWrapper eachProduct : listOfProducts){
      if (eachProduct.objCatalogue != null) {
        mapOfCatalogueIdVsRecord.put(eachProduct.objCatalogue.Id, eachProduct);
      }
      if (eachProduct.objRule == null || (eachProduct.rowType != 'Record' && eachProduct.rowType != 'Header Product')) {
        continue;
      }
      List<QuotePlanAndPricingController.ProductWrapper> productList = mapOfRuleIdVsProducts.get(eachProduct.objRule.Id);
      if (productList == null){
        productList = new List<QuotePlanAndPricingController.ProductWrapper>();
      }
      productList.add(eachProduct);
      mapOfRuleIdVsProducts.put(eachProduct.objRule.Id, productList);
      mapOfRuleIdVsParentId.put(eachProduct.objRule.Id, eachProduct.objCatalogue.Parent__c);
      mapOfProductIdVsProduct.put(eachProduct.objProduct.Id, eachProduct);
    }
    if (mapOfRuleIdVsProducts.keyset().isEmpty()) {
      return listOfProducts;
    }
    Map<Id, Product_Catalogue_Rule__c> mapOfIdVsRule = getRuleMap();

    for (Id eachRuleId : mapOfRuleIdVsProducts.keyset()){
      Product_Catalogue_Rule__c objRule = mapOfIdVsRule.get(eachRuleId);
      List<QuotePlanAndPricingController.ProductWrapper> listOfRuleProducts = mapOfRuleIdVsProducts.get(eachRuleId);

      if (objRule.Rule_Type__c == EU_PARENT_DEPENDENT_QUANTITY){
        for (QuotePlanAndPricingController.ProductWrapper eachProduct : listOfRuleProducts){
          if (eachProduct.objRule.Count_Dependent_On__c == eachProduct.objCatalogue.Id){
            eachProduct.isParent = true;
            eachProduct.showAddButton = false;
          }
          else{
            eachProduct.isChild = true;
          }
        }
      }

      else if (objRule.Rule_Type__c == EU_PARENT_DEPENDENT_QUANTITY_CANNOT_EXCEED_PARENT || objRule.Rule_Type__c == EU_PARENT_DEPENDENT_QUANTITY_CANNOT_EXCEED_PARENT_SELECT_ONLY_ONE){
        Id parentId = mapOfRuleIdVsParentId.get(objRule.Id);
        QuotePlanAndPricingController.ProductWrapper parentProduct = mapOfCatalogueIdVsRecord.get(parentId);

        for (QuotePlanAndPricingController.ProductWrapper eachProduct : listOfRuleProducts){
          if (eachProduct.objRule.Count_Dependent_On__c == eachProduct.objCatalogue.Id){
            eachProduct.isParent = true;
          }
          else{
            eachProduct.isChild = true;
            if (!parentProduct.isSelected) {
              eachProduct.isDisabled = true;
            }
          }
        }
      }

      else if (objRule.Rule_Type__c == LU_PARENT_MANDATORY_CHILDREN_NOT_DEPENDENT || objRule.Rule_Type__c == AA_AUTO_ADD_CHILD || objRule.Rule_Type__c == MU_PICK_NONE_OR_ONE_PARENT_MANDATORY){
        Id parentId = mapOfRuleIdVsParentId.get(objRule.Id);
        QuotePlanAndPricingController.ProductWrapper parentProduct = mapOfCatalogueIdVsRecord.get(parentId);
        if (parentProduct != null){
          for (QuotePlanAndPricingController.ProductWrapper eachProduct : listOfRuleProducts){
            eachProduct.isChild = true;
            if (parentProduct.isSelected){
              if (eachProduct.objCatalogue.Package_Product_Type__c == null || !eachProduct.objCatalogue.Package_Product_Type__c.contains(PACKAGE_PRODUCT_TYPE_PICK_YOUR_NUMBER)){
                parentProduct.buttonText = 'Update';
              }
              eachProduct.isDisabled = false;
              if (objRule.Rule_Type__c == AA_AUTO_ADD_CHILD){
                eachProduct.buttonText = 'Added';
              }
            }
            else{
              eachProduct.isDisabled = true;
            }
            if (objRule.Rule_Type__c == AA_AUTO_ADD_CHILD){
              eachProduct.isAutoSelect = true;
              eachProduct.isDisabled = true;
              eachProduct.isQuantityDisabled = true;
            }
          }
        }
      }

      if (objRule.Rule_Type__c == MU_PICK_NONE_OR_ONE || objRule.Rule_Type__c == EU_SELECT_ONLY_ONE || objRule.Rule_Type__c == MU_PICK_NONE_OR_ONE_PARENT_MANDATORY || objRule.Rule_Type__c == EU_PARENT_DEPENDENT_QUANTITY_CANNOT_EXCEED_PARENT_SELECT_ONLY_ONE){
        Boolean isProductSelected = false;
        for (QuotePlanAndPricingController.ProductWrapper eachProduct : listOfRuleProducts){
          if (objRule.Rule_Type__c == EU_PARENT_DEPENDENT_QUANTITY_CANNOT_EXCEED_PARENT_SELECT_ONLY_ONE && eachProduct.objCatalogue.Id == objRule.Count_Dependent_On__c){
            continue;
          }
          if (eachProduct.isSelected){
            isProductSelected = true;
            if (eachProduct.objCatalogue.Package_Product_Type__c != null && eachProduct.objCatalogue.Package_Product_Type__c.contains(PACKAGE_PRODUCT_TYPE_PICK_YOUR_NUMBER) && !showQuoteLinesOnly) {
              eachProduct.buttonText = 'Remove';
            } else {
              eachProduct.buttonText = 'Update';
            }
            eachProduct.isDisabled = false;
          }
        }
        if (isProductSelected){
          for (QuotePlanAndPricingController.ProductWrapper eachProduct : listOfRuleProducts){
            if (objRule.Rule_Type__c == EU_PARENT_DEPENDENT_QUANTITY_CANNOT_EXCEED_PARENT_SELECT_ONLY_ONE && eachProduct.objCatalogue.Id == objRule.Count_Dependent_On__c){
              continue;
            }
            if (!eachProduct.isSelected){
              eachProduct.isDisabled = true;
            }
          }
        }
      }
    }

    for (QuotePlanAndPricingController.ProductWrapper eachProduct : listOfProducts){
      if (eachProduct.parentId == null) {
        continue;
      }
      QuotePlanAndPricingController.ProductWrapper parentProduct = mapOfProductIdVsProduct.get(eachProduct.parentId);
      if (parentProduct != null && parentProduct.isDisabled != null && parentProduct.isDisabled) {
        eachProduct.isDisabled = true;
      }
    }

    return listOfProducts;
  }

  private static Map<Id, Product_Catalogue_Rule__c> getRuleMap(){
    Map<Id, Product_Catalogue_Rule__c> mapOfIdVsRule = new Map<Id, Product_Catalogue_Rule__c>([SELECT Name, Max_Range__c, Min_Range__c, Title__c, Quantity__c, Color__c, Count_Dependent_On__c, Rule_Type__c, Show_Header__c, Header_Text__c, Header_Color__c, Error_Message__c FROM Product_Catalogue_Rule__c]);
    return mapOfIdVsRule;
  }

  public static Map<Id, Set<Id>> addRelationship(Map<Id, Set<Id>> mapOfParentIdVsChildIds, Id productId, Id parentId){
    Set<Id> listOfChildIds;
    if (mapOfParentIdVsChildIds.get(parentId) != null){
      listOfChildIds = mapOfParentIdVsChildIds.get(parentId);
    }
    else{
      listOfChildIds = new Set<Id>();
    }
    listOfChildIds.add(productId);
    mapOfParentIdVsChildIds.put(parentId, listOfChildIds);
    return mapOfParentIdVsChildIds;
  }

  public static List<QuotePlanAndPricingController.ProductWrapper> validateRules(Id quoteId, List<QuotePlanAndPricingController.ProductWrapper> listOfProducts){
    Map<Id, List<QuotePlanAndPricingController.ProductWrapper>> mapOfRuleIdVsProducts = new Map<Id, List<QuotePlanAndPricingController.ProductWrapper>>();
    Map<Id, Id> mapOfRuleIdVsProductCatalogueId = new Map<Id, Id>();
    Map<Id, QuotePlanAndPricingController.ProductWrapper> mapOfCatalogueIdVsRecord = new Map<Id, QuotePlanAndPricingController.ProductWrapper>();

    Map<Id, List<QuotePlanAndPricingController.ProductWrapper>> mapOfParentIdVsChildProducts = new Map<Id, List<QuotePlanAndPricingController.ProductWrapper>>();
    Map<Id, Product_Catalogue__c> mapOfIdVsCatalogue = new Map<Id, Product_Catalogue__c>();

    Map<Id, Decimal> mapOfParentIdDLMSVsQuantity = new Map<Id, Decimal>();

    for (QuotePlanAndPricingController.ProductWrapper eachProduct : listOfProducts){
      if (eachProduct.rowType != 'Record' && eachProduct.rowType != 'Header Product') {
        continue;
      }
      mapOfCatalogueIdVsRecord.put(eachProduct.objCatalogue.Id, eachProduct);
      mapOfIdVsCatalogue.put(eachProduct.objCatalogue.Id, null);
      if (eachProduct.objCatalogue.Parent__c != null){
        List<QuotePlanAndPricingController.ProductWrapper> childList;
        if (mapOfParentIdVsChildProducts.get(eachProduct.parentId) == null){
          childList = new List<QuotePlanAndPricingController.ProductWrapper>();
        }
        else{
          childList = mapOfParentIdVsChildProducts.get(eachProduct.objCatalogue.Parent__c);
        }
        childList.add(eachProduct);
        mapOfParentIdVsChildProducts.put(eachProduct.objCatalogue.Parent__c, childList);
      }

      if (eachProduct.objRule == null) {
        continue; 
      }
      List<QuotePlanAndPricingController.ProductWrapper> productList = mapOfRuleIdVsProducts.get(eachProduct.objRule.Id);
      if (productList == null){
        productList = new List<QuotePlanAndPricingController.ProductWrapper>();
      }
      productList.add(eachProduct);
      mapOfRuleIdVsProducts.put(eachProduct.objRule.Id, productList);
      if (eachProduct.objRule.Count_Dependent_On__c != null){
        mapOfRuleIdVsProductCatalogueId.put(eachProduct.objRule.Id, eachProduct.objRule.Count_Dependent_On__c);
      }

    }
    if (mapOfRuleIdVsProducts.keyset().isEmpty()) {
      return listOfProducts;
    }
    Map<Id, Product_Catalogue_Rule__c> mapOfIdVsRule = getRuleMap();
    Boolean updateProducts = true;
    for (Id eachRuleId : mapOfRuleIdVsProducts.keyset()){
      Product_Catalogue_Rule__c objRule = mapOfIdVsRule.get(eachRuleId);
      if (objRule.Rule_Type__c == EU_PARENT_DEPENDENT_QUANTITY || objRule.Rule_Type__c == EU_PARENT_DEPENDENT_QUANTITY_CANNOT_EXCEED_PARENT || objRule.Rule_Type__c == EU_PARENT_DEPENDENT_QUANTITY_CANNOT_EXCEED_PARENT_SELECT_ONLY_ONE){
        List<QuotePlanAndPricingController.ProductWrapper> listOfRuleProducts = mapOfRuleIdVsProducts.get(eachRuleId);

        Id objParentProductId = mapOfRuleIdVsProductCatalogueId.get(eachRuleId);

        QuotePlanAndPricingController.ProductWrapper objParentProduct = mapOfCatalogueIdVsRecord.get(objParentProductId);

        Decimal quantity = 0;
        for (QuotePlanAndPricingController.ProductWrapper eachProduct : listOfRuleProducts){
          if (objParentProductId == eachProduct.objCatalogue.Id) {
            continue;
          }
          quantity += eachProduct.quantity == null ? 0 : eachProduct.quantity;
        }

        if (objRule.Rule_Type__c == EU_PARENT_DEPENDENT_QUANTITY && objParentProduct.quantity != null && quantity != objParentProduct.quantity){
          objParentProduct.errorMsg = objRule.Error_Message__c;
          updateProducts = false;
        }
        else{
          objParentProduct.errorMsg = null;
        }

        if ((objRule.Rule_Type__c == EU_PARENT_DEPENDENT_QUANTITY_CANNOT_EXCEED_PARENT || objRule.Rule_Type__c == EU_PARENT_DEPENDENT_QUANTITY_CANNOT_EXCEED_PARENT_SELECT_ONLY_ONE) && objParentProduct.quantity != null && quantity > objParentProduct.quantity){
          objParentProduct.errorMsg = objRule.Error_Message__c;
          updateProducts = false;
        }
        else{
          objParentProduct.errorMsg = null;
        }
      }
    }
    if (updateProducts){
      listOfProducts = updateQuoteProduct(quoteId, listOfProducts, mapOfParentIdVsChildProducts, mapOfCatalogueIdVsRecord, mapOfParentIdDLMSVsQuantity);
    }
    return listOfProducts;
  }

  @testVisible
  public static List<QuotePlanAndPricingController.ProductWrapper> updateQuoteProduct(Id quoteId, List<QuotePlanAndPricingController.ProductWrapper> listOfProducts, Map<Id, List<QuotePlanAndPricingController.ProductWrapper>> mapOfParentIdVsChildProducts, Map<Id, QuotePlanAndPricingController.ProductWrapper> mapOfCatalogueIdVsRecord, Map<Id, Decimal> mapOfParentIdDLMSVsQuantity){
    Set<Id> setOfProductIds = new Set<Id>();
    List<QuotePlanAndPricingController.ProductWrapper> listOfProdutsToUpdate = new List<QuotePlanAndPricingController.ProductWrapper>();
    for (Id eachParentId : mapOfParentIdVsChildProducts.keyset()){

      QuotePlanAndPricingController.ProductWrapper objParent = mapOfCatalogueIdVsRecord.get(eachParentId);
      if (objParent != null){
        setOfProductIds.add(objParent.objProduct.Id);
        listOfProdutsToUpdate.add(objParent);
      }
      for (QuotePlanAndPricingController.ProductWrapper eachProduct : listOfProducts){
        if (eachProduct.rowType != 'Record' && eachProduct.rowType != 'Header Product') {
          continue;
        }
        setOfProductIds.add(eachProduct.objProduct.Id);
        if (eachProduct.objCatalogue.Package_Product_Type__c != null && eachProduct.objCatalogue.Package_Product_Type__c.contains('Quantity same as parent')){
          eachProduct.quantity = objParent.quantity;
        }
        listOfProdutsToUpdate.add(eachProduct);
      }
    }
    List<Partner_Quote_Line__c> listOfQuoteLinesToDelete = [SELECT id FROM Partner_Quote_Line__c WHERE Partner_Quote__c = :quoteId AND Product__c IN:setOfProductIds];
    if (!listOfQuoteLinesToDelete.isEmpty()) {
      delete listOfQuoteLinesToDelete;
    }
    List<Partner_Quote_Line__c> listOfQuoteLinesToCreate = new List<Partner_Quote_Line__c>();
    setOfProductIds.clear();
    for (QuotePlanAndPricingController.ProductWrapper eachLine : listOfProdutsToUpdate){

      if (eachLine.quantity != null && eachLine.quantity > 0 && !setOfProductIds.contains(eachLine.objProduct.Id)){
        Partner_Quote_Line__c objPQLine = populateQuoteLine(quoteId, eachLine);
        listOfQuoteLinesToCreate.add(objPQLine);
        setOfProductIds.add(eachLine.objProduct.Id);
      }
    }
    if (!listOfQuoteLinesToCreate.isEmpty()) {
      insert listOfQuoteLinesToCreate;
    }
    return listOfProducts;
  }

  public static Partner_Quote__c createUpdatePartnerQuote(Id opportunityId, Partner_Quote__c objPartnerQuote, List<QuotePlanAndPricingController.ProductWrapper> listOfQuoteLines, Boolean doUpdateLines, Boolean isPackageChanged){
    Boolean isPhoneProduct = false;
    Boolean isContract = objPartnerQuote.Contract__c;
    isPackageChanged = isPackageChanged == null ? false : isPackageChanged;
    if (objPartnerQuote.id != null){
      opportunityId = objPartnerQuote.Opportunity__c;
    }
    String oppCurrencyIsoCode = [SELECT Id, CurrencyIsoCode, Name FROM Opportunity WHERE Id = :opportunityId][0].CurrencyIsoCode;
    Boolean portalOpp = [Select Portal_Opportunity__c from Opportunity where Id = :opportunityId][0].Portal_Opportunity__c;//PRM Quote
    List<Partner_Quote_Line__c> listOfQuoteLinesToCreate = new List<Partner_Quote_Line__c>();
    if (objPartnerQuote.id == null){
      objPartnerQuote.Opportunity__c = opportunityId;
      objPartnerQuote.CurrencyIsoCode = oppCurrencyIsoCode;
      objPartnerQuote.Status__c = 'Draft';
      objPartnerQuote.Initial_Term__c = '24';
      String oppName = Quote_PartnerQuoteUtil.getOpportunity(opportunityId);
      objPartnerQuote.Name__c = oppName;
      objPartnerQuote.Renewal_Term__c = '24';
      objPartnerQuote.Expiration_Date__c = System.today().addMonths(1).addDays(-1);
      objPartnerQuote.Portal_Quote__c = portalOpp;//PRM Quote

      //Make quote primary if none of existing quote is primary.
      List<Partner_Quote__c> listOfExistingPrimaryQuotes = [SELECT id FROM Partner_Quote__c WHERE Opportunity__c = :opportunityId AND Primary__c = true LIMIT 1];
      if (listOfExistingPrimaryQuotes.isEmpty()){
        objPartnerQuote.Primary__c = true;
      }
      insert objPartnerQuote;
      Quote_SharingHandler.handlePartnerQuoteSharingFuture(objPartnerQuote.Id);
      //Adding default package product
      for (Product_Catalogue__c eachCat : [SELECT Product__c, Default_Quantity__c, Product_Package__r.Name, (SELECT No_of_Licenses__c, CurrencyIsoCode, Monthly_Price__c, Yearly_Price__c FROM Product_Tier_Prices__r ORDER BY No_of_Licenses__c) FROM Product_Catalogue__c WHERE Product_Package__c = :objPartnerQuote.Product_Edition__c AND Package_Product_Type__c INCLUDES('Default') AND Active__c = true]){

        if (!eachCat.Product_Tier_Prices__r.isEmpty()){
          Boolean hasCurrencyPrice = checkIfTierPriceExist(eachCat, objPartnerQuote.CurrencyIsoCode);
          if (!hasCurrencyPrice){
            continue;
          }
        }
        Partner_Quote_Line__c objPQLine = new Partner_Quote_Line__c();
        objPQLine.CurrencyISOCode = objPartnerQuote.CurrencyIsoCode;
        objPQLine.Partner_Quote__c = objPartnerQuote.id;
        objPQLine.Product__c = eachCat.Product__c;
        objPQLine.Quantity__c = (eachCat.Default_Quantity__c == 0 || eachCat.Default_Quantity__c == null) ? objPartnerQuote.Number_of_Licenses__c : eachCat.Default_Quantity__c;
        Decimal listPrice = 0;
        for (Product_Tier_Price__c eachTier : eachCat.Product_Tier_Prices__r){
          if (eachTier.CurrencyIsoCode == objPartnerQuote.CurrencyIsoCode && objPQLine.Quantity__c < eachTier.No_of_Licenses__c){
            if (objPartnerQuote.Payment_Term__c == 'Monthly') {
              listPrice = eachTier.Monthly_Price__c;
            } else {
              listPrice = eachTier.Yearly_Price__c;
            }
            break;
          }
        }
        objPQLine.List_Price__c = listPrice.setScale(2, RoundingMode.HALF_UP);
        objPQLine.Discount__c = 0;
        objPQLine.Discount_Type__c = '%';
        objPQLine.Discount_Number__c = 0;
        objPQLine.Total_Price__c = objPQLine.Quantity__c * objPQLine.List_Price__c;
        objPQLine.Product_Catalogue__c = eachCat.Id;
        listOfQuoteLinesToCreate.add(objPQLine);
      }
    }
    else{

      update objPartnerQuote;

      List<Partner_Quote_Line__c> listOfQuoteLinesToDelete = [SELECT id, Product__c, Quantity__c, Product_Catalogue__c, List_Price__c, Discount__c, Total_Price__c, Partner_Quote__r.Contract__c, Partner_Quote__r.Opportunity__r.Brand_Name__c, Discount_Number__c, Discount_Type__c FROM Partner_Quote_Line__c WHERE Partner_Quote__c = :objPartnerQuote.id];
      if (!isPackageChanged && doUpdateLines && !listOfQuoteLines.isEmpty()){
        if (!listOfQuoteLinesToDelete.isEmpty()) {
          delete listOfQuoteLinesToDelete;
        }
      }
      else if (isPackageChanged){

        Map<Id, Partner_Quote_Line__c> mapOfProductIdVsExistingQuoteLine = new Map<Id, Partner_Quote_Line__c>();
        Set<Id> setOfCommonProductIds = new Set<Id>();
        List<Partner_Quote_Line__c> listOfQuoteLinesToDeleteFresh = new List<Partner_Quote_Line__c>();
        for (Partner_Quote_Line__c eachLine : listOfQuoteLinesToDelete){
          mapOfProductIdVsExistingQuoteLine.put(eachLine.Product__c, eachLine);
        }
        for (Product_Catalogue__c eachCat : [SELECT Contract_Discount__c, Product__c, Package_Product_Type__c, Default_Quantity__c, Product_Package__r.Name, (SELECT CurrencyIsoCode, No_of_Licenses__c, Contract_Discount__c, Monthly_Price__c, Yearly_Price__c FROM Product_Tier_Prices__r ORDER BY No_of_Licenses__c) FROM Product_Catalogue__c WHERE Product_Package__c = :objPartnerQuote.Product_Edition__c AND (Package_Product_Type__c INCLUDES('Default') OR Product__c IN:mapOfProductIdVsExistingQuoteLine.keyset()) AND Active__c = true]){
          if (!eachCat.Product_Tier_Prices__r.isEmpty()){
            Boolean hasCurrencyPrice = checkIfTierPriceExist(eachCat, objPartnerQuote.CurrencyIsoCode);
            if (!hasCurrencyPrice){
              continue;
            }
          }
          Partner_Quote_Line__c objPQLine;
          if (mapOfProductIdVsExistingQuoteLine.keyset().contains(eachCat.Product__c)){
            setOfCommonProductIds.add(eachCat.Product__c);
            objPQLine = mapOfProductIdVsExistingQuoteLine.get(eachCat.Product__c);
          }
          else{
            objPQLine = new Partner_Quote_Line__c();
            objPQLine.CurrencyIsoCode = oppCurrencyIsoCode;
            objPQLine.Partner_Quote__c = objPartnerQuote.id;
            objPQLine.Product__c = eachCat.Product__c;
            objPQLine.Quantity__c = (eachCat.Default_Quantity__c == 0 || eachCat.Default_Quantity__c == null) ? objPartnerQuote.Number_of_Licenses__c : eachCat.Default_Quantity__c;
          }
          Decimal listPrice = 0;
          Decimal ContractDiscount;
          for (Product_Tier_Price__c eachTier : eachCat.Product_Tier_Prices__r){
            if (eachTier.CurrencyIsoCode == objPartnerQuote.CurrencyIsoCode && objPQLine.Quantity__c < eachTier.No_of_Licenses__c){
              if (objPartnerQuote.Payment_Term__c == 'Monthly'){
                listPrice = eachTier.Monthly_Price__c;
                contractDiscount = eachTier.Contract_Discount__c;
              }
              else {
                listPrice = eachTier.Yearly_Price__c;
              }
              break;
            }
          }
          objPQLine.List_Price__c = listPrice;
          if (objPartnerQuote.Contract__c && objPartnerQuote.Payment_Term__c == 'Monthly'){
            if (contractDiscount != null){
              objPQLine.List_Price__c = listPrice - ContractDiscount;
            }
            else if (eachCat.Contract_Discount__c != null){
              objPQLine.List_Price__c = listPrice - eachCat.Contract_Discount__c;
            }
          }
          objPQLine.List_Price__c = objPQLine.List_Price__c.setScale(2, RoundingMode.HALF_UP); //Fix rounding issue

          objPQLine.Discount__c = 0;
          objPQLine.Discount_Type__c = '%';
          objPQLine.Discount_Number__c = 0;
          objPQLine.Total_Price__c = objPQLine.Quantity__c * objPQLine.List_Price__c;
          objPQLine.Product_Catalogue__c = eachCat.Id;
          listOfQuoteLinesToCreate.add(objPQLine);
        }
        for (Partner_Quote_Line__c objPartnerQuoteLine : listOfQuoteLinesToDelete){
          if (!setOfCommonProductIds.contains(objPartnerQuoteLine.Product__c)){
            listOfQuoteLinesToDeleteFresh.add(objPartnerQuoteLine);
          }
        }

        if (!listOfQuoteLinesToDeleteFresh.isEmpty()){
          delete listOfQuoteLinesToDeleteFresh;
        }
      }
    }
    if (doUpdateLines){
      Map<Id, QuotePlanAndPricingController.ProductWrapper> mapOfIdVsRecord = new Map<Id, QuotePlanAndPricingController.ProductWrapper>();
      Map<Id, Decimal> mapOfParentIdVsQuantity = new Map<Id, Decimal>();
      Map<Id, Product_Catalogue__c> mapOfIdVsCatalogue = new Map<Id, Product_Catalogue__c>();
      for (QuotePlanAndPricingController.ProductWrapper eachProduct : listOfQuoteLines){
        if (eachProduct.rowType == 'Header') {
          continue;
        }
        mapOfIdVsRecord.put(eachProduct.objCatalogue.Id, eachProduct);
        if (eachProduct.quantity == 0 || eachProduct.quantity == null) {
          continue;
        }
        if (!isPhoneProduct && eachProduct.objCatalogue.Category_Name__c == 'Phones' && 
                                                                      eachProduct.objCatalogue.Package_Product_Type__c.contains('Rental Product')){
          isPhoneProduct = true;
        }
        Id parentId = eachProduct.objCatalogue.Parent__c;
        mapOfIdVsCatalogue.put(eachProduct.objCatalogue.Id, null);
        if (parentId != null && eachProduct.quantity != null && (eachProduct.objRule.Rule_Type__c == EU_PARENT_DEPENDENT_QUANTITY
         || eachProduct.objRule.Rule_Type__c == EU_PARENT_DEPENDENT_QUANTITY_APP)){
          if (mapOfParentIdVsQuantity.get(parentId) == null) {
            mapOfParentIdVsQuantity.put(parentId, eachProduct.quantity);
          } else {
            Decimal quantity = mapOfParentIdVsQuantity.get(parentId);
            quantity += eachProduct.quantity;
            mapOfParentIdVsQuantity.put(parentId, quantity);
          }
          //System.debug('NKC debug mapOfParentIdVsQuantity IN Loop[' + mapOfParentIdVsQuantity + ']');
        }

      }
      //BZS 10018 added Contract_Discount__c
      mapOfIdVsCatalogue = new Map<Id, Product_Catalogue__c>([SELECT id, Product_Package__r.Name, Contract_Discount__c, (SELECT No_of_Licenses__c, CurrencyIsoCode, Monthly_Price__c, Yearly_Price__c, Contract_Discount__c FROM Product_Tier_Prices__r ORDER BY No_of_Licenses__c) FROM Product_Catalogue__c WHERE id IN:mapOfIdVsCatalogue.KEYSET()]);


      QuotePlanAndPricingController.ProductWrapper objParent;
      //BZS-10018
      Decimal digitalLineQuantity = 0;
      Decimal dependentQuantity = 0;
      Decimal ContractDiscount;
      QuotePlanAndPricingController.ProductWrapper digitalLineRecord;
      //BZS-10018

      //BZS-5486
      QuotePlanAndPricingController.ProductWrapper objParentMS;
      Id msTeamDomestic;
      Id digitalLine;
      Id digitalLineBYOC;
      Decimal msQuantity = 0;
      for (QuotePlanAndPricingController.ProductWrapper eachProduct : listOfQuoteLines){
        if (eachProduct.rowType == 'Header') {
          continue;
        }
        Id parentId = eachProduct.objCatalogue.Parent__c;
        if (mapOfParentIdVsQuantity.get(parentId) != null){
          objParent = mapOfIdVsRecord.get(parentId);
          if (objParent != null){
            objParent.quantity = mapOfParentIdVsQuantity.get(parentId);
          }
        }
        if (eachProduct.objCatalogue != null){
          if (eachProduct.objCatalogue.Display_Name__c != null){
            if (eachProduct.objCatalogue.Display_Name__c.contains('MS Teams CloudPBX - Domestic')){
              msTeamDomestic = eachProduct.objCatalogue.id;
              objParentMS = mapOfIdVsRecord.get(msTeamDomestic);
            }
            //BZS-10018
            if (eachProduct.objCatalogue.Display_Name__c.contains('DigitalLine Unlimited')){
              digitalLine = eachProduct.objCatalogue.id;
              digitalLineRecord = mapOfIdVsRecord.get(digitalLine);
              digitalLineQuantity = digitalLineRecord.Quantity;
            }
            //BZS-10018

            //BZS-10662
            if (eachProduct.objCatalogue.Display_Name__c.contains('DigitalLine BYOC')){
              digitalLineBYOC = eachProduct.objCatalogue.id;
              digitalLineRecord = mapOfIdVsRecord.get(digitalLineBYOC);
              digitalLineQuantity = digitalLineQuantity + digitalLineRecord.Quantity;
            }
            //BZS-10662
          }
        }
      }

      for (QuotePlanAndPricingController.ProductWrapper eachProduct : listOfQuoteLines){
        if (eachProduct.rowType == 'Header') {
          continue;
        }
        Id parentId = eachProduct.objCatalogue.Parent__c;
        objParent = mapOfIdVsRecord.get(parentId);
        //BZS-5486
        if (msTeamDomestic != null){
          objParentMS = mapOfIdVsRecord.get(msTeamDomestic);
          msQuantity = objParentMS.Quantity;

        }
        //BZS-10018
        if (msTeamDomestic != null || digitalLine != null){
          dependentQuantity = msQuantity + digitalLineQuantity;
        }
        if (objParent != null && eachProduct.objCatalogue.Package_Product_Type__c != null && eachProduct.objCatalogue.Parent__c == objParent.objCatalogue.Id && eachProduct.objCatalogue.Package_Product_Type__c.contains('Quantity same as parent')){
          Product_Catalogue__c objCatalogue = mapOfIdVsCatalogue.get(eachProduct.objCatalogue.Id);
          Decimal listPriceBeforeUpdate = eachProduct.listPrice;
          if (eachProduct.objCatalogue.Quantity_Dependent_Product_1__c == null && eachProduct.objCatalogue.Quantity_Dependent_Product_2__c == null){
            for (Product_Tier_Price__c eachTier : objCatalogue.Product_Tier_Prices__r){
              if (eachTier.CurrencyIsoCode == objPartnerQuote.CurrencyIsoCode && objParent.quantity <= eachTier.No_of_Licenses__c){
                if (objPartnerQuote.Payment_Term__c == 'Monthly') {
                  eachProduct.listPrice = eachTier.Monthly_Price__c;
                } else {
                  eachProduct.listPrice = eachTier.Yearly_Price__c;
                }
                break;
              }
            }

            eachProduct.quantity = objParent.quantity + msQuantity;
            eachProduct.netPrice = calculateNetPrice(eachProduct.listPrice, eachProduct.quantity, eachProduct.partnerDiscount, eachProduct.discountType);
            eachProduct.partnerDiscount = eachProduct.partnerDiscount == 0 ? null : eachProduct.partnerDiscount;
          }
        }
        else{

          // added for BZS-10018
          Product_Catalogue__c objCatalogue = mapOfIdVsCatalogue.get(eachProduct.objCatalogue.Id);
          if (objCatalogue != null && dependentQuantity != 0){
            for (Product_Tier_Price__c eachTier : objCatalogue.Product_Tier_Prices__r){
              if (eachTier.CurrencyIsoCode == objPartnerQuote.CurrencyIsoCode && dependentQuantity <= eachTier.No_of_Licenses__c){
                if (eachTier.Contract_Discount__c != null){
                  contractDiscount = eachTier.Contract_Discount__c;
                }
                else{
                  contractDiscount = objCatalogue.Contract_Discount__c;
                }
                if (objPartnerQuote.Payment_Term__c == 'Monthly'){
                  if (isContract && ContractDiscount != null){
                    Decimal listPricebefore;
                    listPricebefore = eachTier.Monthly_Price__c - contractDiscount;
                    eachProduct.listPrice = calculateListPrice(listPricebefore, eachProduct.partnerDiscount, eachProduct.discountType);
                  }
                  else{
                    eachProduct.listPrice = calculateListPrice(eachTier.Monthly_Price__c, eachProduct.partnerDiscount, eachProduct.discountType);
                  }

                } else {
                  eachProduct.listPrice = calculateListPrice(eachTier.Yearly_Price__c, eachProduct.partnerDiscount, eachProduct.discountType);
                }
                break;
              }

            }

          }

          if (objCatalogue != null && dependentQuantity == 0){
            for (Product_Tier_Price__c eachTier : objCatalogue.Product_Tier_Prices__r){
              if (eachTier.CurrencyIsoCode == objPartnerQuote.CurrencyIsoCode && eachProduct.quantity < eachTier.No_of_Licenses__c){
                if (eachTier.Contract_Discount__c != null){
                  contractDiscount = eachTier.Contract_Discount__c;
                }
                else{
                  contractDiscount = objCatalogue.Contract_Discount__c;

                }
                if (objPartnerQuote.Payment_Term__c == 'Monthly'){
                  if (isContract && ContractDiscount != null){
                    Decimal listPricebefore;
                    listPricebefore = eachTier.Monthly_Price__c - contractDiscount;

                    eachProduct.listPrice = calculateListPrice(listPricebefore, eachProduct.partnerDiscount, eachProduct.discountType);
                  }
                  else{
                    eachProduct.listPrice = calculateListPrice(eachTier.Monthly_Price__c, eachProduct.partnerDiscount, eachProduct.discountType);
                  }

                } else {
                  eachProduct.listPrice = calculateListPrice(eachTier.Yearly_Price__c, eachProduct.partnerDiscount, eachProduct.discountType);
                }
                break;
              }

            }
          }
        }

        // added for BZS-10018

        if (eachProduct.quantity == 0 || eachProduct.quantity == null){
          continue;
        }
        if (!isContract && eachProduct.objCatalogue != null && eachProduct.objCatalogue.Package_Product_Type__c != null && eachProduct.objCatalogue.Package_Product_Type__c.contains('Rental Product')){
          continue;
        }
        Partner_Quote_Line__c objPQLine = populateQuoteLine(objPartnerQuote.id, eachProduct);
        objPQLine.CurrencyIsoCode = oppCurrencyIsoCode;
        objPQLine.Approved_Quantity__c = eachProduct.objQuoteLine.Approved_Quantity__c;
        listOfQuoteLinesToCreate.add(objPQLine);
      }
    }
    else if (!isContract){
      List<Partner_Quote_Line__c> listOfRentalQuoteLines = [SELECT id FROM Partner_Quote_Line__c WHERE Partner_Quote__c = :objPartnerQuote.id AND Product_Catalogue__r.Package_Product_Type__c INCLUDES('Rental Product')];
      if (!listOfRentalQuoteLines.isEmpty()){
        delete listOfRentalQuoteLines;
      }

    }

    if (!listOfQuoteLinesToCreate.isEmpty()){
      upsert listOfQuoteLinesToCreate;
    }

    objPartnerQuote.is_Phone_Product__c = isPhoneProduct;
    if (isPhoneProduct){
      objPartnerQuote.Renewal_Term__c = '24';
    }
    objPartnerQuote.Number_of_Licenses__c = getServiceCountFromQuote(objPartnerQuote.Id);

    update objPartnerQuote;
    return objPartnerQuote;
  }

  public static Decimal getServiceCountFromQuote(Id quoteId){
    AggregateResult[] serviceCountResult = [SELECT Sum(Quantity__c)serviceCount FROM Partner_Quote_Line__c WHERE (Product_Catalogue__r.Category_Name__c = 'Service' OR Product_Catalogue__r.Sub_Category_Name__c = 'Global Office' OR Product_Catalogue__r.Sub_Category_Name__c = 'Global MVP' OR Product_Catalogue__r.Sub_Category_Name__c = 'MS Teams') AND Product_Catalogue__r.Package_Product_Type__c EXCLUDES('Service Fee', 'Header') AND Partner_Quote__c = :quoteId];
    return (Decimal) serviceCountResult[0].get('serviceCount');
  }

  @testvisible
  private static Decimal calculateNetPrice(Decimal listPrice, Decimal quantity, Decimal discount, String discountType){
    Decimal netPrice = listPrice;
    if (listPrice != null && quantity != null){
      if (discount > 0 && discountType == '%'){
        listPrice -= ((listPrice * discount) / 100);
      }
      else if (discount != null && discountType == 'Amt'){
        listPrice -= discount;
      }
      netPrice = listPrice * quantity;
    }
    return netPrice;
  }

  //BZS=10018
  @testvisible
  private static Decimal calculateListPrice(Decimal listPrice, Decimal discount, String discountType){
    if (listPrice != null){
      if (discount > 0 && discountType == '%'){
        listPrice -= ((listPrice * discount) / 100);
      }
      else if (discount != null && discountType == 'Amt'){
        listPrice -= discount;
      }
    }
    system.debug('***List Price' + listPrice);
    return listPrice;
  }

  private static Partner_Quote_Line__c populateQuoteLine(Id quoteId, QuotePlanAndPricingController.ProductWrapper eachLine){
    Partner_Quote_Line__c objPQLine = new Partner_Quote_Line__c();
    objPQLine.Partner_Quote__c = quoteId;
    objPQLine.Product__c = eachLine.objProduct.id;
    objPQLine.List_Price__c = eachLine.listPrice != null ? eachLine.listPrice.setScale(2, RoundingMode.HALF_UP) : eachLine.listPrice;
    objPQLine.Discount_Number__c = eachLine.partnerDiscount == null ? 0 : eachLine.partnerDiscount;
    objPQLine.Discount_Type__c = eachLine.discountType;
    if (eachLine.discountType == '%' && objPQLine.Discount_Number__c > 0){
      objPQLine.Discount__c = eachLine.partnerDiscount == null ? 0 : eachLine.partnerDiscount;
    }
    objPQLine.Quantity__c = eachLine.quantity;
    objPQLine.Total_Price__c = calculateNetPrice(objPQLine.List_Price__c, objPQLine.Quantity__c, 0, eachLine.discountType);
    objPQLine.Product_Catalogue__c = eachLine.objCatalogue.Id;
    objPQLine.Number_of_Employees__c = eachLine.objQuoteLine.Number_of_Employees__c;
    objPQLine.Location__c = eachLine.objQuoteLine.Location__c;
    objPQLine.Number_of_Forecasted_ACO_Users__c = eachLine.objQuoteLine.Number_of_Forecasted_ACO_Users__c;
    return objPQLine;
  }

  @AuraEnabled
  public static void updateAccountChecklist(Account_Checklist__c objCheckListRec, string accId){
    if (objCheckListRec != null && objCheckListRec.Id != null){
      update objCheckListRec;
    }
    else{
      objCheckListRec.Account__c = accId;
      objCheckListRec.Type__c = 'Credit Check';
      insert objCheckListRec;

      Deal_Support__c objDealSupport = createDealSupport();
      objDealSupport.Account_Checklist__c = objCheckListRec.Id;
      insert objDealSupport;
    }
  }
  @AuraEnabled
    public static void createChangeOrderRequest(Boolean isChangeOrder, Boolean fromProcessOrder, String partnerQuoteId, string accId){
        if(isChangeOrder && fromProcessOrder){
         Quote objQuote = Quote_PartnerQuoteUtil.getSalesQuote(partnerQuoteId);
          Deal_Support__c objDealRec = Quote_PartnerQuoteUtil.createDealSupport();
          if(objQuote.OpportunityId != null) {
              String oppName = Quote_PartnerQuoteUtil.getOpportunity(objQuote.OpportunityId);
              objDealRec.Name = 'Change Order - '+oppName;
          }
          objDealRec.Sales_Agreement__c = partnerQuoteId;
          objDealRec.Type__c = 'Change Order';
          objDealRec.Opportunity__c = objQuote.OpportunityId;
          objDealRec.Brand_Name__c = objQuote.Opportunity.Brand_Name__c;
          objDealRec.OwnerId = objQuote.Opportunity.ownerId;
       	  if(accId != null) {
              objDealRec.Customer_Account__c = accId;
              objDealRec.Partner_Account__c = objQuote.Opportunity.Partner_Account__c;
          }
          insert objDealRec;
    	}
    }
  @AuraEnabled
  public static Account_Checklist__c updateAccountChecklist(Boolean fromProcessOrder, String partnerQuoteId, Account_Checklist__c objCheckListRec, string accId, List<Area_Codes__c> areaCodeList, string isStandardMSA, Boolean isAvaya, Boolean isNoStandardPlayBook, List<Account_Checklist_Address__c> addressList, Boolean isFromCheckOut, Partner_Quote__c Quote){
    List<Area_Codes__c> listOfAreaCodeToInsert = new List<Area_Codes__c>();
    Partner_Quote__c objpartQuote;
    Quote objSalesQuote;
      System.debug('fromProcessOrder-->'+fromProcessOrder);
    String BrandName = 'Avaya Cloud Office';
    List<Account_Checklist_Address__c> listOfAddressListToInsert = new List<Account_Checklist_Address__c>();
    
    if (isFromCheckOut == null) {
      isFromCheckOut = false;
    }
    if(fromProcessOrder){
        objSalesQuote = Quote_PartnerQuoteUtil.getSalesQuote(partnerQuoteId);
        if (objSalesQuote.Opportunity.Brand_Name__c != null) {
        	BrandName = objSalesQuote.Opportunity.Brand_Name__c;
        }
    }
    if (isFromCheckOut && !fromProcessOrder){
      objpartQuote = Quote_PartnerQuoteUtil.getQuote(partnerQuoteId);
      if (objpartQuote.Opportunity__r.Brand_Name__c != null) {
        BrandName = objpartQuote.Opportunity__r.Brand_Name__c;
      }
    }

    if (objCheckListRec != null && objCheckListRec.Id != null){
      update objCheckListRec;
      if (accId != null){
        Account accObj = new Account();
        accObj.Id = accId;
        accObj.VATNumber__c = objCheckListRec.VAT_Number__c;
        update accObj;
        system.debug('VATNumber__c--' + accObj.VATNumber__c);
      }
      if (isFromCheckOut){
          List<Deal_Support__c> objDealSupportList;
          if(fromProcessOrder){
          	objDealSupportList = [Select Id, Sales_Agreement__c, Partner_Quote__c FROM Deal_Support__c where Sales_Agreement__c = :partnerQuoteId and Type__c = 'Initial Order' and Status__c != 'Closed-Approved' limit 1];
          }else{
          	objDealSupportList = [Select Id, Partner_Quote__c FROM Deal_Support__c WHERE Partner_Quote__c = :partnerQuoteId and Type__c = 'Initial Order' and Status__c != 'Closed-Approved' limit 1];
          }
              if (objDealSupportList != null && !objDealSupportList.isEmpty()){
          if (partnerQuoteId != null){
              if(fromProcessOrder){
                 objDealSupportList[0].Sales_Agreement__c = partnerQuoteId; 
              }else{
                  objDealSupportList[0].Partner_Quote__c = partnerQuoteId;
              }    
            objDealSupportList[0].Opportunity__c = fromProcessOrder ? objSalesQuote.OpportunityId : objpartQuote.Opportunity__c;
            objDealSupportList[0].Customer_Account__c = fromProcessOrder ? objSalesQuote.Opportunity.AccountId : objpartQuote.Opportunity__r.AccountId;
            //Changed By Ankit Sharma For Partner Account
            objDealSupportList[0].Partner_Account__c = fromProcessOrder ? objSalesQuote.Opportunity.Partner_Account__c : objpartQuote.Opportunity__r.Partner_Account__c;
          }
          if (isAvaya != null && !isAvaya){
            objDealSupportList[0].Status__c = 'New';
            objDealSupportList[0].Type__c = 'Initial Order';
            objDealSupportList[0].Brand_Name__c = BrandName;
            //Changes By Ankit Sharma queue name Based on community...

            String queueName = Quote_PartnerQuoteUtil.getQueueBasedOnCommunity(BrandName, true);
            // Added for PRM-81 Start
            String queueId = '';
            if (BrandName == 'Avaya Cloud Office'){
              queueId = Quote_PartnerQuoteUtil.getQueueId('Sales Overlay Queue');
            }
            else{
              queueId = Quote_PartnerQuoteUtil.getQueueId(queueName);
            }
            // Added for PRM-81 end

            if (queueId != null){
              if (BrandName != 'RingCentral' && BrandName != 'RingCentral Canada' && 
                    BrandName != 'RingCentral UK' && BrandName != 'RingCentral EU' && BrandName != 'RingCentral AU'){
                objDealSupportList[0].OwnerId = queueId;
              }
              else{
                objDealSupportList[0].OwnerId = fromProcessOrder ? objSalesQuote.Opportunity.ownerId : objpartQuote.Opportunity__r.ownerId;
              }

            }
            if (isStandardMSA != '' && isStandardMSA != 'Yes'){
              objDealSupportList[0].Contract_Type__c = 'Non Standard';
            }
            else{
              objDealSupportList[0].Contract_Type__c = 'Standard';
            }
          }
          else{
            objDealSupportList[0].Status__c = 'New';
            objDealSupportList[0].Type__c = 'Initial Order';
            objDealSupportList[0].Brand_Name__c = BrandName;
            //Changes By Ankit Sharma queue name Based on community...

            String queueName = Quote_PartnerQuoteUtil.getQueueBasedOnCommunity(BrandName, false);
            // Added for PRM-81 Start
            String queueId = '';
            if (BrandName == 'Avaya Cloud Office'){
              queueId = Quote_PartnerQuoteUtil.getQueueId('Sales Overlay Queue');
            }
            else{
              queueId = Quote_PartnerQuoteUtil.getQueueId(queueName);
            }
            // Added for PRM-81 end

            if (queueId != null){
              if (BrandName != 'RingCentral' && BrandName != 'RingCentral Canada' && 
                    BrandName != 'RingCentral UK' && BrandName != 'RingCentral EU' && BrandName != 'RingCentral AU'){
                objDealSupportList[0].OwnerId = queueId;
              }
              else{
                objDealSupportList[0].OwnerId = fromProcessOrder ? objSalesQuote.Opportunity.ownerId : objpartQuote.Opportunity__r.ownerId;
              }
            }
            if (isNoStandardPlayBook) {
              objDealSupportList[0].Contract_Type__c = 'Non Standard Playbook';
            }
          }
          update objDealSupportList;
        }
        else{
          Deal_Support__c objDealSupport = createDealSupport();
            if(fromProcessOrder){
                objDealSupport.Sales_Agreement__c = partnerQuoteId; 
            }else{
                objDealSupport.Partner_Quote__c = partnerQuoteId;
            } 
          objDealSupport.Account_Checklist__c = objCheckListRec.Id;
          objDealSupport.Opportunity__c = fromProcessOrder ? objSalesQuote.OpportunityId : objpartQuote.Opportunity__c;
          objDealSupport.Customer_Account__c = fromProcessOrder ? objSalesQuote.Opportunity.AccountId : objpartQuote.Opportunity__r.AccountId;
          //Changed By Ankit Sharma For Partner Account
          objDealSupport.Partner_Account__c = fromProcessOrder ? objSalesQuote.Opportunity.Partner_Account__c : objpartQuote.Opportunity__r.Partner_Account__c;

          if (isAvaya != null && !isAvaya){
            objDealSupport.Status__c = 'New';
            objDealSupport.Type__c = 'Initial Order';
            if(fromProcessOrder){
                objDealSupport.Sales_Agreement__c = partnerQuoteId; 
            }else{
                objDealSupport.Partner_Quote__c = partnerQuoteId;
            }
            String oppName = fromProcessOrder ? Quote_PartnerQuoteUtil.getOpportunity(objSalesQuote.OpportunityId): Quote_PartnerQuoteUtil.getOpportunity(objpartQuote.Opportunity__c);
            objDealSupport.Name = 'Initial Order - ' + oppName;
            objDealSupport.Brand_Name__c = BrandName;
            //Changes By Ankit Sharma queue name Based on community...

            String queueName = Quote_PartnerQuoteUtil.getQueueBasedOnCommunity(BrandName, true);
            // Added for PRM-81 Start
            String queueId = '';
            if (BrandName == 'Avaya Cloud Office'){
              queueId = Quote_PartnerQuoteUtil.getQueueId('Sales Overlay Queue');
            }
            else{
              queueId = Quote_PartnerQuoteUtil.getQueueId(queueName);
            }
            // Added for PRM-81 end

            if (queueId != null){
              if (BrandName != 'RingCentral' && BrandName != 'RingCentral Canada' && 
                    BrandName != 'RingCentral UK' && BrandName != 'RingCentral EU' && BrandName != 'RingCentral AU'){
                objDealSupport.OwnerId = queueId;
              }
              else{
                objDealSupport.OwnerId = fromProcessOrder ? objSalesQuote.Opportunity.ownerId : objpartQuote.Opportunity__r.ownerId;
              }
            }
            if (isStandardMSA != '' && isStandardMSA != 'Yes'){
              objDealSupport.Contract_Type__c = 'Non Standard';
            }
            else{
              objDealSupport.Contract_Type__c = 'Standard';
            }
          }
          else{
            objDealSupport.Status__c = 'New';
            if(fromProcessOrder){
                objDealSupport.Sales_Agreement__c = partnerQuoteId; 
            }else{
                objDealSupport.Partner_Quote__c = partnerQuoteId;
            }
            objDealSupport.Type__c = 'Initial Order';
            String oppName = fromProcessOrder ? Quote_PartnerQuoteUtil.getOpportunity(objSalesQuote.OpportunityId) : Quote_PartnerQuoteUtil.getOpportunity(objpartQuote.Opportunity__c);
            objDealSupport.Name = 'Initial Order - ' + oppName;
            objDealSupport.Brand_Name__c = BrandName;
            //Changes By Ankit Sharma queue name Based on community...

            String queueName = Quote_PartnerQuoteUtil.getQueueBasedOnCommunity(BrandName, false);
            // Added for PRM-81 Start
            String queueId = '';
            if (BrandName == 'Avaya Cloud Office'){
              queueId = Quote_PartnerQuoteUtil.getQueueId('Sales Overlay Queue');
            }
            else{
              queueId = Quote_PartnerQuoteUtil.getQueueId(queueName);
            }
            // Added for PRM-81 end

            if (queueId != null){
              if (BrandName != 'RingCentral' && BrandName != 'RingCentral Canada' && 
                    BrandName != 'RingCentral UK' && BrandName != 'RingCentral EU' && BrandName != 'RingCentral AU'){
                objDealSupport.OwnerId = queueId;
              }
              else{
                objDealSupport.OwnerId = fromProcessOrder ? objSalesQuote.Opportunity.ownerId : objpartQuote.Opportunity__r.ownerId;
              }

            }
            if (isNoStandardPlayBook) {
              objDealSupport.Contract_Type__c = 'Non Standard Playbook';
            }
          }

          insert objDealSupport;
        }
      }


      list<Area_codes__c> delAreaCodeList = [Select Id FROM Area_Codes__c WHERE Account_Checklist__c = :objCheckListRec.id];
      if (delAreaCodeList != null){
        delete delAreaCodeList;
      }
    }
    else{
      objCheckListRec.Account__c = accId;
      objCheckListRec.Type__c = 'Credit Check';
      insert objCheckListRec;
      if (accId != null){
        Account accObj = new Account();
        accObj.Id = accId;
        accObj.VATNumber__c = objCheckListRec.VAT_Number__c;
        update accObj;
        system.debug('VATNumber__c--' + accObj.VATNumber__c);
      }

      if (isFromCheckOut){
        Deal_Support__c objDealSupport = createDealSupport();
        if (partnerQuoteId != null){
            if(fromProcessOrder){
                objDealSupport.Sales_Agreement__c = partnerQuoteId;
            }else{
                objDealSupport.Partner_Quote__c = partnerQuoteId;
            } 
        }
        objDealSupport.Account_Checklist__c = objCheckListRec.Id;
        objDealSupport.Opportunity__c = fromProcessOrder ? objSalesQuote.OpportunityId : objpartQuote.Opportunity__c;
        objDealSupport.Customer_Account__c = fromProcessOrder ? objSalesQuote.Opportunity.AccountId : objpartQuote.Opportunity__r.AccountId;
        //Changed By Ankit Sharma For Partner Account
        objDealSupport.Partner_Account__c = fromProcessOrder ? objSalesQuote.Opportunity.Partner_Account__c : objpartQuote.Opportunity__r.Partner_Account__c;

        if (isAvaya != null && !isAvaya){
          objDealSupport.Status__c = 'New';
          objDealSupport.Type__c = 'Initial Order';
          if(fromProcessOrder){
                objDealSupport.Sales_Agreement__c = partnerQuoteId; 
            }else{
                objDealSupport.Partner_Quote__c = partnerQuoteId;
            }
          String oppName = fromProcessOrder ? Quote_PartnerQuoteUtil.getOpportunity(objSalesQuote.OpportunityId) : Quote_PartnerQuoteUtil.getOpportunity(objpartQuote.Opportunity__c);
          objDealSupport.Name = 'Initial Order - ' + oppName;
          objDealSupport.Brand_Name__c = BrandName;
          //Changes By Ankit Sharma queue name Based on community...

          String queueName = Quote_PartnerQuoteUtil.getQueueBasedOnCommunity(BrandName, true);
          // Added for PRM -81 Start
          String queueId = '';
          if (BrandName == 'Avaya Cloud Office'){
            queueId = Quote_PartnerQuoteUtil.getQueueId('Sales Overlay Queue');
          }
          else{
            queueId = Quote_PartnerQuoteUtil.getQueueId(queueName);
          }
          // Added for PRM -81 end

          if (queueId != null){
            if (BrandName != 'RingCentral' && BrandName != 'RingCentral Canada' && 
                  BrandName != 'RingCentral UK' && BrandName != 'RingCentral EU' && BrandName != 'RingCentral AU'){
              objDealSupport.OwnerId = queueId;
            }
            else{
              objDealSupport.OwnerId = fromProcessOrder ? objSalesQuote.Opportunity.ownerId : objpartQuote.Opportunity__r.ownerId;
            }
          }

          if (isStandardMSA != '' && isStandardMSA != 'Yes'){
            objDealSupport.Contract_Type__c = 'Non Standard';
          }
          else{
            objDealSupport.Contract_Type__c = 'Standard';
          }
        }
        else{
          objDealSupport.Status__c = 'New';
            if(fromProcessOrder){
                objDealSupport.Sales_Agreement__c = partnerQuoteId; 
            }else{
                objDealSupport.Partner_Quote__c = partnerQuoteId;
            }
          objDealSupport.Type__c = 'Initial Order';
          String oppName = fromProcessOrder ? Quote_PartnerQuoteUtil.getOpportunity(objSalesQuote.OpportunityId) : Quote_PartnerQuoteUtil.getOpportunity(objpartQuote.Opportunity__c);
          objDealSupport.Name = 'Initial Order - ' + oppName;
          objDealSupport.Brand_Name__c = BrandName;
          //Changes By Ankit Sharma queue name Based on community...

          String queueName = Quote_PartnerQuoteUtil.getQueueBasedOnCommunity(BrandName, false);
          // Added for PRM -81 Start
          String queueId = '';
          if (BrandName == 'Avaya Cloud Office'){
            queueId = Quote_PartnerQuoteUtil.getQueueId('Sales Overlay Queue');
          }
          else{
            queueId = Quote_PartnerQuoteUtil.getQueueId(queueName);
          }
          if (queueId != null){
            if (BrandName != 'RingCentral' && BrandName != 'RingCentral Canada' && 
                  BrandName != 'RingCentral UK' && BrandName != 'RingCentral EU' && BrandName != 'RingCentral AU'){
              objDealSupport.OwnerId = queueId;
            }
            else{
              objDealSupport.OwnerId = fromProcessOrder ? objSalesQuote.Opportunity.ownerId : objpartQuote.Opportunity__r.ownerId;
            }

          }
          if (isNoStandardPlayBook) {
            objDealSupport.Contract_Type__c = 'Non Standard Playbook';
          }
        }

        insert objDealSupport;
      }
    }

    if (areaCodeList != null && !areaCodeList.isEmpty()){
      for (Area_Codes__c eachAreaCode : areaCodeList){
        Area_Codes__c obj = eachAreaCode.clone();
        obj.Account_Checklist__c = objCheckListRec.id;
        listOfAreaCodeToInsert.add(obj);
      }
    }
    system.debug('addressList>>>' + addressList);
    if (addressList != null && !addressList.isEmpty()){
      Set<Id> setofACAId = new Set<Id>();
      for (Account_Checklist_Address__c eachAddress : addressList){
        if (eachAddress != null && eachAddress.Id != null){
          setofACAId.add(eachAddress.Id);
        }
        eachAddress.Account_Checklist__c = objCheckListRec.id;
        listOfAddressListToInsert.add(eachAddress);
      }

      if (!setofACAId.isEmpty()){
        List<Account_Checklist_Address__c> listofACAToDelete = [Select Id FROM Account_Checklist_Address__c WHERE Account_Checklist__c = :objCheckListRec.id AND ID NOT IN:setofACAId];
        if (listofACAToDelete != null && listofACAToDelete.size() > 0){
          delete listofACAToDelete;
        }
      }
    }

    if (objpartQuote != null && isFromCheckOut){
      objpartQuote.Status__c = 'Pending Order';
      if (Quote != null && Quote.Start_Date__c != null){
        objpartQuote.Start_Date__c = Quote.Start_Date__c;
        objpartQuote.End_Date__c = Quote_PartnerQuoteUtil.calculateEndDate(Quote);
      }
      update objpartQuote;
    }

    if (!listOfAreaCodeToInsert.isEmpty()){
      upsert listOfAreaCodeToInsert;
    }

    if (!listOfAddressListToInsert.isEmpty()){
      upsert listOfAddressListToInsert;
    }
    return objCheckListRec;
  }

  @AuraEnabled
  public static void createOrderRequest(Partner_Quote__c objPartnerQuoteRec, string oppId){
    Id quoteRecordTypeId = Schema.SObjectType.Partner_Quote__C.getRecordTypeInfosByName().get('Change Order Request').getRecordTypeId();
    if (objPartnerQuoteRec != null && objPartnerQuoteRec.Id != null){
      update objPartnerQuoteRec;
    }
    else{
      objPartnerQuoteRec.Opportunity__c = oppId;
      objPartnerQuoteRec.RecordtypeId = quoteRecordTypeId;
      insert objPartnerQuoteRec;
    }
  }

  public static Deal_Support__c createDealSupport(){
    Deal_Support__c objDealRec = new Deal_Support__c();
    String communityUserId = UserInfo.getUserId();
    List<User> listOfUser = [SELECT ContactId, Contact.AccountId FROM User WHERE Id = :communityUserId];
    if (listOfUser != null && !listOfUser.isEmpty()){
      objDealRec.Partner_Account__c = listOfUser[0].Contact.AccountId;
      objDealRec.Partner_Contact__c = listOfUser[0].ContactId;
    }
    objDealRec.Requested_By__c = UserInfo.getUserId();
    return objDealRec;
  }

  public static String getQueueId(String queueName){
    List<Group> queueList = [select Id from Group where Name = :queueName and Type = 'Queue' Limit 1];
    if (queueList != null && !queueList.isEmpty()){
      return queueList[0].Id;
    }

    return null;
  }

  public static Boolean checkSuperUser(){
    User currentUser = QuotePlanAndPricingController.getCurrentUserInfo();
    Boolean isAvaya = false;
    List<String> BrandName = new List<String>();
    String TopMasterAccountId;
    Community_Details__mdt comDetail = CommunityInfo.getCommunityDetails();
    if (comDetail != null){
      TopMasterAccountId = Test.isRunningTest() ? PartnerRecordsUtil.avayaMasterAccount.Id : comDetail.Portal_Top_Master_Account_Id__c;
      BrandName = comDetail.Brand_Name__c.split(';');
    }

    if (PartnerDealRegistrationUtil.getSelectedPartnerId() == TopMasterAccountId){
      isAvaya = true;
    }
    if (comDetail != null && currentUser != null && currentUser.Partner_Discount_Approval__c != null && currentUser.Partner_Discount_Approval__c == 'L1 Approval'){
      if (BrandName != null && BrandName.size() > 0 && (BrandName.contains('RingCentral') || BrandName.contains('RingCentral Canada') || BrandName.contains('RingCentral UK') || BrandName.contains('RingCentral EU') || BrandName.contains('RingCentral AU'))){

        isAvaya = true;
      }
    }
    return isAvaya;
  }

  @AuraEnabled
  public static void createAccountChangeRequest(Account_Change_Request__c objChangeRequest, string accId){
    String BrandName = 'Avaya Cloud Office';
    Account objAccount = [Select Id, RC_Brand__c, Partner_Account__c FROM Account WHERE Id = :accId];
    if (objAccount.RC_Brand__c != null){
      BrandName = objAccount.RC_Brand__c;
    }

    String queueName = Quote_PartnerQuoteUtil.getQueueBasedOnCommunity(BrandName, true);
    String queueId = getQueueId(queueName);
    objChangeRequest.Account__c = accId;
    objChangeRequest.Status__c = 'New';
    Account objAccRec = getAccount(accId);
    insert objChangeRequest;
    Quote_SharingHandler.handleAccountChangeRequestSharingFuture(objChangeRequest.Id);//Fix for BZS-4704 ALE

    Deal_Support__c objDealRec = createDealSupport();
    objDealRec.Brand_Name__c = BrandName;
    if (objAccRec != null) {
      objDealRec.Name = 'Change Account - ' + objAccRec.Name;
    }
    if (queueId != null) {
      objDealRec.OwnerId = queueId;
    }
    objDealRec.Account_Change_Request__c = objChangeRequest.Id;
    objDealRec.Type__c = 'Change Account';
    if (accId != null){
      objDealRec.Customer_Account__c = accId;
      objDealRec.Partner_Account__c = objAccount.Partner_Account__c;
    }

    insert objDealRec;
  }

  @AuraEnabled
  public static List<Quote_PartnerDetailController.AccountCheckListAddressWrapp> addAddressRow(String addressList){

    Map<String, List<String>> dependentPicklistValuesMap = ControlAndDependentPicklstMap.getDependentPicklistValues(Deal_Registration__c.State__c);
    Quote_PartnerDetailController.AccountCheckListAddressWrapp objNew = new Quote_PartnerDetailController.AccountCheckListAddressWrapp();
    List<Quote_PartnerDetailController.AccountCheckListAddressWrapp> shippingAddressList = (List<Quote_PartnerDetailController.AccountCheckListAddressWrapp>)JSON.deserialize(addressList, List<Quote_PartnerDetailController.AccountCheckListAddressWrapp>.class);
    objNew.acrRec = new Account_Checklist_Address__c(Country__c = DEFAULT_COUNTRY_VALUE, Selected_Quantity__c = '0');
    if (dependentPicklistValuesMap.containsKey(DEFAULT_COUNTRY_VALUE)){
      objNew.shippingStateList = dependentPicklistValuesMap.get(DEFAULT_COUNTRY_VALUE);
    }

    shippingAddressList.add(objNew);

    return shippingAddressList;
  }

  @AuraEnabled
  public static List<ContentDocument> getFiles(string recordId){
    Set<Id> recordIds = new Set<Id>{ recordId };
    Set<Id> documentIds = new Set<Id>();
    List<ContentDocumentLink> cdl = [SELECT id, LinkedEntityId, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId IN:recordIds];
    for (ContentDocumentLink cdLink : cdl){
      documentIds.add(cdLink.ContentDocumentId);
    }
    return [SELECT Id, Title, LatestPublishedVersionId, FileType, CreatedDate FROM ContentDocument WHERE id IN:documentIds];
  }

  public static Date calculateEndDate(partner_Quote__c objQuote){
    Date dt = objQuote.Start_Date__c;
    return dt.addMonths(Integer.valueOf(objQuote.Initial_Term__c));
  }

  @AuraEnabled
  public static PhoneProductWrapper getPhoneProductFROMQuoteLine(String recordId){
    PhoneProductWrapper obj = new PhoneProductWrapper();
    Map<String, String> MapOfProductIdToName = new Map<String, String>();
    Map<String, String> MapOfProductIdToQuantity = new Map<String, String>();
    if (recordId != null){
      for (Partner_Quote_line__c objLine : [Select Id, Product_Catalogue__c, Quantity__c, Product_Catalogue__r.Product_Name__c, Product_Catalogue__r.Display_Name__c, Partner_Quote__r.Contract__c, Partner_Quote__r.Opportunity__r.Brand_Name__c FROM Partner_Quote_line__c WHERE Partner_Quote__c = :recordId and Product_Catalogue__r.Category_Name__c = 'Phones' AND (( NOT Product_Catalogue__r.Display_Name__c LIKE '%for Desktop%') AND Product_Catalogue__r.Display_Name__c != 'Existing Phone')]){
        MapOfProductIdToName.put(objLine.Product_Catalogue__c, objLine.Product_Catalogue__r.Display_Name__c);
        MapOfProductIdToQuantity.put(objLine.Product_Catalogue__c, String.valueof(objLine.Quantity__c));
      }
      obj.mapOfProductIdToProductName = MapOfProductIdToName;
      obj.mapOfProductIdToProductQuantity = MapOfProductIdToQuantity;
      return obj;
    }
    return null;
  }

  public static Boolean getReadOnlyFlagForUser(){
    return FeatureManagement.checkPermission('Quote_ReadOnlyProfile');
  }

  public static Boolean checkIfTierPriceExist(Product_Catalogue__c eachCatalogue, String currencyIsoCode){
    Boolean hasCurrencyPrice = false;
    for (Product_Tier_Price__c eachTier : eachCatalogue.Product_Tier_Prices__r){
      if (eachTier.CurrencyIsoCode == currencyIsoCode){
        hasCurrencyPrice = true;
        break;
      }
    }
    return hasCurrencyPrice;
  }

  @AuraEnabled
  public static PickListWrapperForCountry getCountryStateMap(String communityBrand){
    Map<String, List<String>> dependentPicklistValuesMap = ControlAndDependentPicklstMap.getDependentPicklistValues(Deal_Registration__c.State__c);
    PickListWrapperForCountry picklistWrapperObj = new PickListWrapperForCountry();
    picklistWrapperObj.countryStateMap = dependentPicklistValuesMap;
    picklistWrapperObj.countriesAvailable = Quote_PartnerQuoteUtil.getCountriesAvailableForCommunity(communityBrand);
    return picklistWrapperObj;
  }

  @AuraEnabled
  public static PickListWrapperForCountry getCountryStateMap(String communityBrand, String accountId){
    List<Account> listOfAccount = [SELECT ID, RC_Brand__c, Partner_Type__c, BillingCountry FROM Account WHERE Id = :accountId];
    if (listOfAccount != null && listOfAccount.size() > 0 && listOfAccount[0].RC_Brand__c != null){
      communityBrand = listOfAccount[0].RC_Brand__c;
    }
    Map<String, List<String>> dependentPicklistValuesMap = ControlAndDependentPicklstMap.getDependentPicklistValues(Deal_Registration__c.State__c);
    PickListWrapperForCountry picklistWrapperObj = new PickListWrapperForCountry();
    picklistWrapperObj.countryStateMap = dependentPicklistValuesMap;
    picklistWrapperObj.countriesAvailable = Quote_PartnerQuoteUtil.getCountriesAvailableForCommunity(communityBrand);
    //Adding for JIRA BZS - 7041 PRM BOB  start
    if (listOfAccount != null && !listOfAccount.isEmpty()){
      picklistWrapperObj.custAccount = listOfAccount[0];
    }
    //Adding for JIRA BZS - 7041 PRM BOB  end
    return picklistWrapperObj;
  }

  public static List<String> getCountriesAvailableForCommunity(String communityBrand){
    List<String> countries = new List<String>();
    if (communityBrand == null || communityBrand == ''){
      CommunityInfo comm = new CommunityInfo();
      communityBrand = CommunityInfo.getBrandName();
    }
    String brandName = '%' + communityBrand + '%';
    List<Community_Detail_Child__mdt> countriesForBrand = [select Country_Name__c from Community_Detail_Child__mdt where Community_Details__r.Brand_Name__c like:brandName];
    for (Community_Detail_Child__mdt communityObj : countriesForBrand){
      countries.add(communityObj.Country_Name__c);
    }
    return countries;
  }

  public static String getQueueBasedOnCommunity(String brandName, Boolean isAvayaQueueNeeded){
    String queueName = '';
    for (Community_Details__mdt communityDetailRec : [select id, Portal_Queue__c, Brand_Name__c, Portal_SalesOverlay_Queue__c from Community_Details__mdt]){
      if (communityDetailRec.Brand_Name__c != null){
        List<String> brandNameList = communityDetailRec.Brand_Name__c.split(';');
        if (brandNameList.contains(brandName)){
          if (isAvayaQueueNeeded){

            queueName = communityDetailRec.Portal_Queue__c;

          }
          else{
            queueName = communityDetailRec.Portal_SalesOverlay_Queue__c;
          }

          return queueName;
        }
      }
    }

    return queueName;
  }

  //Added method for ACO 3.0
  @AuraEnabled
  public static CountryAndCommunityWrapper getCountryAndCommunityForCustAcct(String accountId, String opportunityId){
    CountryAndCommunityWrapper ccWrapper = new CountryAndCommunityWrapper();
    List<Partner_Quote__c> objQuoteList = new List<Partner_Quote__c>();
    List<Account> custAcc = [Select id, BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry, BillingAddress, RC_Brand__c, VATNumber__c, Partner_Type__c, Partner_Account__r.Partner_Type__c, (select id, VATExemption__c/*,status__c*/ from Approvals__r), (select id, Tier_Name__c from Opportunities) from Account where id = :accountId];
    if (custAcc != null && !custAcc.isEmpty()){
      ccWrapper.billingCountry = custAcc.get(0).BillingCountry;
      ccWrapper.RCBrand = custAcc.get(0).RC_Brand__c;
      ccWrapper.custAccount = custAcc.get(0);
      if (opportunityId != null){
        objQuoteList = [SELECT Id, Name, Opportunity__c, CreatedDate, RecordTypeId, RecordType.Name, Name__c, Product_Edition__c, Status__c, Primary__c, Product_Edition__r.Name, Product_Edition__r.Product_Categories__c, Number_of_Licenses__c, Payment_Term__c, Contract__c, Brand_Name__c FROM Partner_Quote__c WHERE Opportunity__c = :opportunityId and Primary__c = true];
      }
    }
    CommunityInfo comm = new CommunityInfo();
    Community_Details__mdt comDetail = CommunityInfo.getCommunityDetails();
    ccWrapper.comDetail = comDetail;
    if (objQuoteList != null && !objQuoteList.isEmpty()) {
      ccWrapper.objQuote = objQuoteList[0];
    }
    return ccWrapper;
  }

  @AuraEnabled
  public static List<Area_Codes__c> getAreaCodeListsForAccountChecklists(String accountChecklistId){
    List<Area_Codes__c> listsOfAreaCodeList = new List<Area_Codes__c>();
    if (accountChecklistId != null && accountChecklistId != ''){
      listsOfAreaCodeList = [Select Id, Account_Checklist__c, Area_Code__c, Country__c, State__c, Is_Area_Code_Declaration_Checked__c, Quantity_Requested__c, Other_Country__c FROM Area_Codes__c WHERE Account_Checklist__c = :accountChecklistId];
    }
    return listsOfAreaCodeList;
  }

  //Added method for ACO 3.0
  public class CountryAndCommunityWrapper{
    @AuraEnabled
    public String billingCountry{ get; set; }

    @AuraEnabled
    public String RCBrand{ get; set; }

    @AuraEnabled
    public Community_Details__mdt comDetail{ get; set; }

    @AuraEnabled
    public Account custAccount{ get; set; }

    @AuraEnabled
    public Partner_Quote__c objQuote{ get; set; }

  }

  public class PickListWrapperForCountry{
    @AuraEnabled
    public Map<String, List<String>> countryStateMap{ get; set; }

    @AuraEnabled
    public List<String> countriesAvailable{ get; set; }

    // Added custAccount for JIRA BZS - 7041 PRM BOB
    @AuraEnabled
    public Account custAccount{ get; set; }

  }

  public class PhoneProductWrapper{
    @AuraEnabled
    public Map<String, String> mapOfProductIdToProductName;
    @AuraEnabled
    public Map<String, String> mapOfProductIdToProductQuantity;
  }

  // Business Identity from approved business identity (approvedBi) on Package_Info__c
  public static String getApprovedBIFromQuote(Quote q){
    String res = '';

    if (String.isBlank(q.Package_Info__c)){
      return res;
    }

    List<BillingWrappers.QuotePackageInfo> pInfo = (List<BillingWrappers.QuotePackageInfo>)JSON.deserialize(q.Package_Info__c, List<BillingWrappers.QuotePackageInfo>.class);

    try{
      res = pInfo[0].packageBusinessIdentities.selectedBi.name;
    }
    catch (Exception e){
      System.debug('NO APPROVED BI ON PACKAGE INFO');
    }

    return res;
  }

}