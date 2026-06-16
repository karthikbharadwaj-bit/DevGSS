public without sharing class Quote_OrderChangeRequestController {
  @AuraEnabled
  public static CategoryWrapper getProductCategories(String packageName,Boolean ExistingChangeOrder, String changeOrderId, Boolean isPackageChange) {
     List<parentCategoryWrapper> categoryWrapperList = new List<parentCategoryWrapper>();
     Set<string> existingProductKeyMap = new Set<string>();
     map<String,List<subCategoryWrapper>> mapOfCategoryToSubCategoryWrap = new map<String,List<subCategoryWrapper>>();
     map<String,List<String>> mapOfCategoryToSubCategoryName = new map<String,List<String>>(); 
     map<String,List<productWrapper>> mapOfSubCategoryNameToProductList = new map<String,List<productWrapper>>();
     Map<String,partner_Quote_line__c> mapOfExistingProductIdToLineItem = new Map<String,partner_Quote_line__c>();
      CategoryWrapper objMainWrap = new CategoryWrapper();
      objMainWrap.currentChargeTerm  = false;
      objMainWrap.objPartnerQuoteRec = new Partner_Quote__c();
      String brandName = 'Avaya Cloud Office';
      String oppCurrencyIsoCode = 'USD';//ACO 4.0
      String accountBillingCountry;
      String accountId = '';
      String partnerAccountId = '';//added for wholesale
      String partnerAccountType = '';//added for wholesale
      if(changeOrderId != null && changeOrderId.startsWith('006')) {
          //Added CurrencyIsoCode for ACO 4.0
          //Added Account.Number_of_DL_s__c  for Go pricing BZS-7323
          //Added Account.Licenses_Purchased__c for BZS-7926, Added Account.Sector__c for PBC-9537 EDU
          Opportunity objOpp = [SELECT Id,accountId, Account.BillingCountry, Brand_Name__c, CurrencyIsoCode, 
                                Account.Active_Sales_Agreement__c, Account.Package_Status__c, Account.Package_Name__c, 
                                Account.Licenses_Purchased__c, Account.Number_of_DL_s__c, Partner_Account__r.Partner_Type__c, Partner_Account__c,Account.Sector__c FROM Opportunity WHERE Id = :changeOrderId];
          brandName = objOpp.Brand_Name__c;  
          oppCurrencyIsoCode = objOpp.CurrencyIsoCode;//ACO 4.0
          accountBillingCountry = objOpp.Account.BillingCountry;
          accountId = objOpp.accountId;
          objMainWrap.brandName = brandName;
          objMainWrap.sector = objOpp.Account.Sector__c;//added for edu
          partnerAccountId = objOpp.Partner_Account__c;//added for wholesale
          partnerAccountType = objOpp.Partner_Account__r.Partner_Type__c;//added for wholesale
          if(objOpp.Account.Active_Sales_Agreement__c != null){
              objMainWrap.objPartnerQuoteRec.Contract_Status__c = 'Active';
          }

          if(objOpp.Account.Package_Status__c == 'Active' && objOpp.Account.Package_Name__c != null){
              objMainWrap.currentPackage = objOpp.Account.Package_Name__c;
          }
          //Added for Go pricing BZS-7323 - start
          List<Deal_Support__c> dealSupportLst = [select id, Type__c,Customer_Account__c,opportunity__c, partner_quote__c, partner_quote__r.product_edition__r.name 
                                                  from deal_support__c where Type__c = 'Initial Order' and Customer_Account__c = :objOpp.AccountId 
                                                  and opportunity__r.type = 'New Business'];
          if (dealSupportLst != NULL && !dealSupportLst.isEmpty()){
              objMainWrap.initialOrderPkgEdition = dealSupportLst.get(0).partner_quote__r.product_edition__r.name;
          }else{
              objMainWrap.initialOrderPkgEdition = '';
          }
          //Removed Account.Number_of_DL_s__c and added Account.Licenses_Purchased__c for BZS-7926
          if(objOpp.Account.Licenses_Purchased__c != NULL && objOpp.Account.Licenses_Purchased__c > 0){
              objMainWrap.No_Of_DL_Acct = objOpp.Account.Licenses_Purchased__c;
          }
          else{
              objMainWrap.No_Of_DL_Acct = 0;
          }
      }
      if(ExistingChangeOrder) {
          //Added CurrencyIsoCode for ACO 4.0
          Partner_Quote__c existingPartnerQuote = [SELECT Tax_Exemption__c,VAT_Number__c,Contract_Status__c,Opportunity__r.Account.BillingCountry,Main_Area_Code__c,Opportunity__r.Brand_Name__c,Comments__c,Fax_Area_Code__c,Move_to_Contract__c,Discount_Changes__c,Product_Detail__c,Contract_term__c,Change_Edition__c,Payment_Method__c,
                                                   Name,Product_Edition__r.Monthly_Packgage_Info__c,Subscription__c,Name__c,Opportunity__r.PriceBook2Id ,Opportunity__r.AccountId,Justification_Description__c,Auto_Renewal__c,Quote_Type__c,Discount_Approval_Status__c,
                                                  Agreement_Status__c,Quote_Approval_Id__c,Stage__c,Status__c ,(Select Id,actionType__c,Product__c, 
                                                  Product__r.Name, List_Price__c, Product_Catalogue__c, Partner_Quote__c,Discount__c, Quantity__c, 
                                                  Effective_Price__c, Total_Price__c, Discount_Number__c, Discount_Type__c FROM Partner_Quote_Products__r), 
                                                  Start_Date__c,End_Date__c,Shipping_Address__c,Special_Terms__c,Expiration_Date__c, 
                                                  Initial_Term__c, Renewal_Term__c, Product_Edition__c, Product_Edition__r.Name, Number_of_Licenses__c, 
                                                  Payment_Term__c, Highest_Discount__c, Opportunity__r.CurrencyIsoCode,Opportunity__r.Partner_Account__r.Partner_Type__c, Opportunity__r.Partner_Account__c,Sub_Package__c,
                                                  Opportunity__r.Account.Active_Sales_Agreement__c, Opportunity__r.Account.Package_Status__c,
                                                  Opportunity__r.Account.Sector__c,Opportunity__r.Account.Package_Name__c FROM Partner_Quote__c WHERE id =: changeOrderId];
          partnerAccountId = existingPartnerQuote.Opportunity__r.Partner_Account__c;//added for wholesale
          partnerAccountType = existingPartnerQuote.Opportunity__r.Partner_Account__r.Partner_Type__c; //added for wholesale
          if(existingPartnerQuote.Opportunity__r.AccountId != null) {
              accountId = existingPartnerQuote.Opportunity__r.AccountId;
              if(existingPartnerQuote.Opportunity__r.Account.Package_Status__c == 'Active'
                 && existingPartnerQuote.Opportunity__r.Account.Package_Name__c != null){
                  objMainWrap.currentPackage = existingPartnerQuote.Opportunity__r.Account.Package_Name__c;
              }
          }
          if(existingPartnerQuote.Opportunity__r.Account.Active_Sales_Agreement__c != null){
              existingPartnerQuote.Contract_Status__c = 'Active';
          }
          //ACO 4.0 - If condition
          if(existingPartnerQuote.Opportunity__r.Brand_Name__c != null) {
              brandName = existingPartnerQuote.Opportunity__r.Brand_Name__c;
          }
          objMainWrap.brandName = brandName;
          objMainWrap.sector = existingPartnerQuote.Opportunity__r.Account.Sector__c;//added for edu
          oppCurrencyIsoCode = existingPartnerQuote.Opportunity__r.CurrencyIsoCode;//ACO 4.0
          if(!isPackageChange) {
              packageName = existingPartnerQuote.Product_Edition__c;
          }
          objMainWrap.objPartnerQuoteRec = existingPartnerQuote;
          accountBillingCountry = existingPartnerQuote.Opportunity__r.Account.BillingCountry;
          if(!existingPartnerQuote.Partner_Quote_Products__r.isEmpty()) {
              for(Partner_Quote_Line__c eachLine : existingPartnerQuote.Partner_Quote_Products__r) {
                  mapOfExistingProductIdToLineItem.put(eachLine.Product_Catalogue__c,eachLine);
              }
          }
      }
      
      List<String> listOfAvailableCategories = new List<String>();
      
      if(packageName != null) {
          Product_Package__c objPackage = [SELECT Id, Name, Product_Categories__c FROM Product_Package__c WHERE Id = :packageName];
          objMainWrap.changedPackage = objPackage.Name;//Added for GO Pricing
          if(objPackage.Product_Categories__c != null) {
            listOfAvailableCategories = objPackage.Product_Categories__c.split(';');
          }
      }
      //('Add-Ons', 'International', 'Phones', 'Conferencing', 'Service', 'Bundles')
      for(Product_Catalogue__c eachProduct : [SELECT Category_Name__c,Product_Package__c, Sub_Category_Name__c FROM Product_Catalogue__c 
                                              WHERE Product_Package__c =: packageName AND Category_Name__c != null AND Sub_Category_Name__c != null AND Active__c = true
                                              AND Category_Name__c IN :listOfAvailableCategories
                                              AND Hide_a_product__c EXCLUDES(:accountBillingCountry)]){
        System.debug('eachProduct>>>>'+eachProduct);                                         
        if(mapOfCategoryToSubCategoryName.containsKey(eachProduct.Category_Name__c)) {
            if(!mapOfCategoryToSubCategoryName.get(eachProduct.Category_Name__c).contains(eachProduct.Sub_Category_Name__c)) {
              mapOfCategoryToSubCategoryName.get(eachProduct.Category_Name__c).add(eachProduct.Sub_Category_Name__c);
            }                                          
        }
        else {
             mapOfCategoryToSubCategoryName.put(eachProduct.Category_Name__c,new List<String>{eachProduct.Sub_Category_Name__c});                                         
        }
         
     }
      
     for(Product_Catalogue__c eachCatalogue : [SELECT id, Product__c,Parent__c, Parent__r.Product__c, 
                                               Parent__r.Parent__c, Parent__r.Parent__r.Product__c, 
                                               Color__c, Category_Name__c, Sub_Category_Name__c, 
                                               LBOX_Rule_Lookup__c,LBOX_Rule_Lookup__r.Min_Range__c,LBOX_Rule_Lookup__r.Max_Range__c,//Added for GO Pricing
                                               Product_Catalogue_Rule__c, Product_Catalogue_Rule__r.Count_Dependent_On__c, Display_Name__c, Package_Product_Type__c,
                                               (SELECT Id,CurrencyIsoCode FROM Product_Tier_Prices__r)
                                               FROM Product_Catalogue__c WHERE Active__c = true AND  Product_Package__c =: packageName
                                               AND Sub_Category_Name__c != null AND 
                                               (Package_Product_Type__c EXCLUDES ('Hide From Change Request'))
                                               AND Hide_a_product__c EXCLUDES(:accountBillingCountry)
                                                ORDER BY Row_Order__c ASC]) {
          System.debug('eacheachCatalogue>>'+eachCatalogue);
          if( mapOfSubCategoryNameToProductList.containskey(eachCatalogue.Category_Name__c+'-'+eachCatalogue.Sub_Category_Name__c)) {
                 productWrapper obj = new productWrapper();
                 obj.productName = eachCatalogue.Display_Name__c;
                  
                  if(mapOfExistingProductIdToLineItem.containsKey(eachCatalogue.Id)) {
                     obj.buttonLabel = 'Remove';
                     obj.actionType = mapOfExistingProductIdToLineItem.get(eachCatalogue.Id).actionType__c;
                     obj.isSelected = true;
                      if(mapOfExistingProductIdToLineItem.get(eachCatalogue.Id).Quantity__c > 0) {
                          obj.quantity = Integer.valueof(mapOfExistingProductIdToLineItem.get(eachCatalogue.Id).Quantity__c);
                      } else {
                          obj.quantity = null;
                      }
                  } else {
                     obj.buttonLabel = 'Add';
                     obj.isSelected = false;
                     obj.quantity = null;
                     obj.actionType = 'Add';
                 }
                 //Added for GO Pricing - start
                  if(eachCatalogue.LBOX_Rule_Lookup__c != NULL && eachCatalogue.LBOX_Rule_Lookup__r.Max_Range__c > 0 && eachCatalogue.LBOX_Rule_Lookup__r.Min_Range__c > 0){
                      obj.MinValue = Integer.valueof(eachCatalogue.LBOX_Rule_Lookup__r.Min_Range__c);
                      obj.MaxValue = Integer.valueof(eachCatalogue.LBOX_Rule_Lookup__r.Max_Range__c);
                  }
                  //Added for GO Pricing - end
                  
                 obj.catalogueId = eachCatalogue.id;
                 obj.ProductId = eachCatalogue.Product__c;
                 
                mapOfSubCategoryNameToProductList.get(eachCatalogue.Category_Name__c+'-'+eachCatalogue.Sub_Category_Name__c).add(obj); 
              existingProductKeyMap.add(eachCatalogue.Category_Name__c+'-'+eachCatalogue.Sub_Category_Name__c+eachCatalogue.Display_Name__c);
             }
             else {
                 productWrapper obj = new productWrapper();
                 obj.productName = eachCatalogue.Display_Name__c;
                  
                 if(mapOfExistingProductIdToLineItem.containsKey(eachCatalogue.Id)) {
                     obj.buttonLabel = 'Remove';
                     obj.actionType = mapOfExistingProductIdToLineItem.get(eachCatalogue.Id).actionType__c;
                     obj.isSelected = true;
                     if(mapOfExistingProductIdToLineItem.get(eachCatalogue.Id).Quantity__c > 0) {
                          obj.quantity = Integer.valueof(mapOfExistingProductIdToLineItem.get(eachCatalogue.Id).Quantity__c);
                     } else { 
                         obj.quantity = null;
                     }
                 } else {
                     obj.actionType = 'Add';
                     obj.buttonLabel = 'Add';
                     obj.isSelected = false;
                     obj.quantity = null;
                 }
                  //Added for GO Pricing - start
                  if(eachCatalogue.LBOX_Rule_Lookup__c != NULL && eachCatalogue.LBOX_Rule_Lookup__r.Max_Range__c > 0 && eachCatalogue.LBOX_Rule_Lookup__r.Min_Range__c > 0){
                      obj.MinValue = Integer.valueof(eachCatalogue.LBOX_Rule_Lookup__r.Min_Range__c);
                      obj.MaxValue = Integer.valueof(eachCatalogue.LBOX_Rule_Lookup__r.Max_Range__c);
                  }
                  //Added for GO Pricing - end
                 obj.catalogueId = eachCatalogue.id;
                 obj.ProductId = eachCatalogue.Product__c;
                 mapOfSubCategoryNameToProductList.put(eachCatalogue.Category_Name__c+'-'+eachCatalogue.Sub_Category_Name__c,new list<productWrapper>{obj});
                 existingProductKeyMap.add(eachCatalogue.Category_Name__c+'-'+eachCatalogue.Sub_Category_Name__c+eachCatalogue.Display_Name__c);
             }
     }
      
      for(String categoryName : mapOfCategoryToSubCategoryName.keySet()) {
          List<subCategoryWrapper> subCategoryList = new List<subCategoryWrapper>();
          parentCategoryWrapper objParentWrap = new parentCategoryWrapper();
          objParentWrap.CategoryName = categoryName;
          System.debug('mapOfCategoryToSubCategoryName>>'+ categoryName);
          System.debug('mapOfCategoryToSubCategoryName>>'+ mapOfCategoryToSubCategoryName.get(categoryName));
          for(String subCategoryName : mapOfCategoryToSubCategoryName.get(categoryName)) {
              subCategoryWrapper objSubWrap = new subCategoryWrapper();
              objSubWrap.subCategoryName = subCategoryName;
              if(mapOfSubCategoryNameToProductList.containsKey(categoryName+'-'+subCategoryName)) {
                  objSubWrap.productList = mapOfSubCategoryNameToProductList.get(categoryName+'-'+subCategoryName);
              }
              subCategoryList.add(objSubWrap);
          }
          objParentWrap.subCategoryList = subCategoryList;
          categoryWrapperList.add(objParentWrap);
      }
      
      objMainWrap.parentCategoryWrapperList =categoryWrapperList; 
      
      // Adding Dynamic Package on the basis of Brand
      
      List<EditionWrapper> listOfEditionWrappList = new List<EditionWrapper>();
      //Added if else and CurrencyIsoCode filter for ACO 4.0 - starts
      if(brandName != null && brandName.equalsIgnoreCase('Avaya Cloud Office')){
          //added for wholesale starts
          if(partnerAccountType!= null && partnerAccountType.contains('Wholesale-Reseller')){
                objMainWrap.isWholesale = true;
                for(Wholesale_Partner_Package__c wholesalePackage : [SELECT id,End_Date__c,Parent_Product_Package__c,Parent_Product_Package__r.Name, Product_Package__c,Product_Package__r.Name, Start_Date__c,Wholesale_Partner_Account__c
                                                                    FROM Wholesale_Partner_Package__c WHERE Wholesale_Partner_Account__c = :partnerAccountId]){
                    Boolean packageStart = false;
                    Boolean packageEnd = false;
                    if((Date.today() >= wholesalePackage.Start_Date__c) || wholesalePackage.Start_Date__c == null){
                        packageStart = true;
                    }
                    if((Date.today() <= wholesalePackage.End_Date__c) || wholesalePackage.End_Date__c == null){
                        packageEnd = true;
                    } 
                    if(packageStart && packageEnd){
                EditionWrapper objWrapperEdition = new EditionWrapper();
                objWrapperEdition.pickVal =  wholesalePackage.Parent_Product_Package__r.Name;    
                objWrapperEdition.pickKey =  wholesalePackage.Parent_Product_Package__c;                                       
                listOfEditionWrappList.add(objWrapperEdition); 
                    }                                                   
                }

            }else{
                //added for wholesale ends
          For(Product_Package__c objPackage : [SELECT Id,name,(SELECT Id,Description__c,Contract_Discount__c, Monthly_Price__c, Yearly_Price__c, No_of_Licenses__c 
                                             FROM Product_Tier_Prices__r WHERE CurrencyIsoCode = :oppCurrencyIsoCode) FROM Product_Package__c 
                                              WHERE Brand_Name__c = :brandName 
                                              AND Active__c = true]) {
              if(objPackage.Product_Tier_Prices__r.isEmpty()){
                  continue;
              }                                 
              EditionWrapper objWrapperEdition = new EditionWrapper();
              objWrapperEdition.pickVal =  objPackage.name;    
              objWrapperEdition.pickKey =  objPackage.Id;                                       
              listOfEditionWrappList.add(objWrapperEdition);
          }
            }
      }else{
          //added for wholesale starts
          if(partnerAccountType!= null && partnerAccountType.contains('Wholesale-Reseller')){
                objMainWrap.isWholesale = true;
                for(Wholesale_Partner_Package__c wholesalePackage : [SELECT id,End_Date__c,Parent_Product_Package__c,Parent_Product_Package__r.Name, Product_Package__c,Product_Package__r.Name, Start_Date__c,Wholesale_Partner_Account__c
                                                                    FROM Wholesale_Partner_Package__c WHERE Wholesale_Partner_Account__c = :partnerAccountId]){
                    Boolean packageStart = false;
                    Boolean packageEnd = false;
                    if((Date.today() >= wholesalePackage.Start_Date__c) || wholesalePackage.Start_Date__c == null){
                        packageStart = true;
                    }
                    if((Date.today() <= wholesalePackage.End_Date__c) || wholesalePackage.End_Date__c == null){
                        packageEnd = true;
                    }
                    if(packageStart && packageEnd){ 
                EditionWrapper objWrapperEdition = new EditionWrapper();
                objWrapperEdition.pickVal =  wholesalePackage.Parent_Product_Package__r.Name;    
                objWrapperEdition.pickKey =  wholesalePackage.Parent_Product_Package__c;                                       
                listOfEditionWrappList.add(objWrapperEdition);                                                    
                    }

                }

            }else{
                //added for wholesale ends
          For(Product_Package__c objPackage : [SELECT Id,name,(SELECT Id,Description__c,Contract_Discount__c, Monthly_Price__c, Yearly_Price__c, No_of_Licenses__c 
                                             FROM Product_Tier_Prices__r) FROM Product_Package__c 
                                              WHERE Brand_Name__c = :brandName 
                                              AND Active__c = true]) {
              if(objPackage.Product_Tier_Prices__r.isEmpty()){
                  continue;
              }                                 
              EditionWrapper objWrapperEdition = new EditionWrapper();
              objWrapperEdition.pickVal =  objPackage.name;    
              objWrapperEdition.pickKey =  objPackage.Id;                                       
              listOfEditionWrappList.add(objWrapperEdition);
          }   
      }
      }
      //ACO 4.0 -ends
      System.debug('categoryWrapperList>>'+categoryWrapperList);
      objMainWrap.listofEditionWrapper = listOfEditionWrappList;
      objMainWrap.currencyCode = oppCurrencyIsoCode;//Added for GO Pricing
      return objMainWrap;
  }
  
  @AuraEnabled
  public static void createOrderRequest(String categoryWrapperStr,Partner_Quote__c objPartnerQuoteRec,Boolean ExistingChangeOrder, String changeOrderId,String accountId) {
      System.debug('accountId>>'+accountId);
      Id quoteRecordTypeId = Schema.SObjectType.Partner_Quote__C.getRecordTypeInfosByName().get('Change Order Request').getRecordTypeId();
      List<parentCategoryWrapper> categoryList = (List<parentCategoryWrapper>)System.JSON.deserialize(categoryWrapperStr, List<parentCategoryWrapper>.class);
      String packageId = objPartnerQuoteRec.Product_Edition__c;

      if(packageId != null) {
          objPartnerQuoteRec.Product_Edition__c = packageId;
      }
      if(ExistingChangeOrder) {
          List<Partner_Quote_line__c> existingPartnerQuoteLineList = [Select Id FROM Partner_Quote_line__c WHERE Partner_Quote__c = :changeOrderId]; 
          
          if(!existingPartnerQuoteLineList.isEmpty()) {
              delete existingPartnerQuoteLineList;
          }
          
          update objPartnerQuoteRec;
      } else {
          objPartnerQuoteRec.RecordtypeId = quoteRecordTypeId;
          objPartnerQuoteRec.Number_of_Licenses__c = null;
          insert objPartnerQuoteRec;
          Quote_SharingHandler.handlePartnerQuoteSharingFuture(objPartnerQuoteRec.Id);
      }
      
      if(objPartnerQuoteRec.Status__c != 'Draft') {
          Partner_Quote__c objQuote = Quote_PartnerQuoteUtil.getQuote(objPartnerQuoteRec.Id);
          Deal_Support__c objDealRec = Quote_PartnerQuoteUtil.createDealSupport();
          if(objPartnerQuoteRec.Opportunity__c != null) {
              String oppName = Quote_PartnerQuoteUtil.getOpportunity(objPartnerQuoteRec.Opportunity__c);
              objDealRec.Name = 'Change Order - '+oppName;
          }
          objDealRec.Partner_Quote__c = objPartnerQuoteRec.Id;
          objDealRec.Type__c = 'Change Order';
          objDealRec.Opportunity__c = objPartnerQuoteRec.Opportunity__c;
          String BrandName = 'Avaya Cloud Office';
          if(objQuote.Opportunity__r.Brand_Name__c != null) {
              BrandName = objQuote.Opportunity__r.Brand_Name__c;
          }
          String queueName = Quote_PartnerQuoteUtil.getQueueBasedOnCommunity(BrandName,false);
          String queueId = Quote_PartnerQuoteUtil.getQueueId(queueName);
          objDealRec.Brand_Name__c = BrandName;
          if(queueId != null) {
              if(BrandName != 'RingCentral' && BrandName != 'RingCentral Canada' 
                 && BrandName != 'RingCentral UK' && BrandName != 'RingCentral EU' && BrandName != 'RingCentral AU') {
                     objDealRec.OwnerId = queueId;
                 }
              else {
                  objDealRec.OwnerId = objQuote.Opportunity__r.ownerId;
              }
          }
          
          if(accountId != null) {
              objDealRec.Customer_Account__c = accountId;
              //Changed By Ankit Sharma For Partner Account
              objDealRec.Partner_Account__c = objQuote.Opportunity__r.Partner_Account__c;

          }
         
          insert objDealRec;
      }
              
      List<Partner_Quote_line__c> listOfPartQuoteLineToInsert = new List<Partner_Quote_line__c>();
      For(parentCategoryWrapper objParent : categoryList) {
          for(subCategoryWrapper objchild : objParent.subCategoryList) {
              if(objchild.productList!=null){
                  for(productWrapper objProd : objchild.productList) {
                      if(objProd.isSelected) {
                          Partner_Quote_Line__c objPartQuoteLine = new Partner_Quote_Line__c();
                          objPartQuoteLine.Partner_Quote__c = objPartnerQuoteRec.Id ;
                          objPartQuoteLine.Quantity__c = objProd.quantity;
                          objPartQuoteLine.actionType__c = objProd.actionType;
                          objPartQuoteLine.Product__c = objProd.ProductId;
                          objPartQuoteLine.Product_Catalogue__c = objProd.catalogueId;
                          listOfPartQuoteLineToInsert.add(objPartQuoteLine);
                      }
                  }
              }
          }
      }
      
      if(!listOfPartQuoteLineToInsert.isEmpty()) {
          insert listOfPartQuoteLineToInsert;
      }
  }
  
  public class CategoryWrapper {
      @AuraEnabled
      public Partner_Quote__c objPartnerQuoteRec;
      @AuraEnabled
      public String brandName;
      @AuraEnabled
      public boolean currentChargeTerm;
      @AuraEnabled
      public String currencyCode;//Added for GO Pricing
      @AuraEnabled
      public String changedPackage;//Added for GO Pricing
      @AuraEnabled
      public String currentPackage;
      @AuraEnabled
      public List<EditionWrapper> listofEditionWrapper;
      @AuraEnabled
      public List<parentCategoryWrapper> parentCategoryWrapperList;
      @AuraEnabled
      public Double No_Of_DL_Acct;//Added for GO pricing
      @AuraEnabled
      public String initialOrderPkgEdition;//Added for GO pricing
      @AuraEnabled
      public boolean isWholesale;//Added for wholesale
        @AuraEnabled
        public String sector;//added for edu
   }

  
  public class EditionWrapper {
      @AuraEnabled public string pickVal;
      @AuraEnabled public string pickKey;
  }
  
  public class parentCategoryWrapper {
      @AuraEnabled
      public string CategoryName;
      @AuraEnabled
      public List<subCategoryWrapper> subCategoryList;
  }

  
  public class subCategoryWrapper {
      @AuraEnabled
      public string subCategoryName;
      @AuraEnabled
      public List<productWrapper> productList;
      
  }
  
  public class productWrapper {
      @AuraEnabled
      public String ProductId;
      @AuraEnabled
      public String catalogueId;
      @AuraEnabled
      public Boolean isSelected;
      @AuraEnabled
      public String productName;
      @AuraEnabled
      public integer quantity;
      @AuraEnabled
      public String actionType;
      @AuraEnabled
      public String buttonLabel;
      //Added for GO Pricing
      @AuraEnabled
      public integer MinValue;
      @AuraEnabled
      public integer MaxValue;
  }
    //added for wholesale upsell quote
    @AuraEnabled
    public static List<EditionWrapper> loadSubPackages(String parentPackageId, String oppId){
        List<EditionWrapper> listOfEditionWrappList= new List<EditionWrapper>();
        String accountId = '';
        if(oppId != null && oppId.startsWith('006')){
            Opportunity opp=[SELECT id,Partner_Account__c FROM opportunity WHERE id =:oppId];
            accountId=opp.Partner_Account__c;
        }else{
            Partner_Quote__C quoteObj =[SELECT id,Opportunity__r.Partner_Account__c from Partner_Quote__c where id=:oppId];
            accountId=quoteObj.Opportunity__r.Partner_Account__c;
        }
        for(Wholesale_Partner_Package__c wholesalePackage : [SELECT id,End_Date__c,Product_Package__c,Product_Package__r.Name,Start_Date__c
                                                              FROM Wholesale_Partner_Package__c WHERE Parent_Product_Package__c =:parentPackageId AND Wholesale_Partner_Account__c=:AccountId]){
            
            Boolean packageStart = false;
            Boolean packageEnd = false;
            if((Date.today() >= wholesalePackage.Start_Date__c) || wholesalePackage.Start_Date__c == null){
                packageStart = true;
            }
            if((Date.today() <= wholesalePackage.End_Date__c) || wholesalePackage.End_Date__c == null){
                packageEnd = true;
            }
            if(packageStart && packageEnd){
                EditionWrapper objWrapperEdition = new EditionWrapper();
                objWrapperEdition.pickVal =  wholesalePackage.Product_Package__r.Name;    
                objWrapperEdition.pickKey =  wholesalePackage.Product_Package__c;                                       
                listOfEditionWrappList.add(objWrapperEdition);
            }                                                  
        }
        return listOfEditionWrappList;
    }
}