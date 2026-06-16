public without sharing class DQ_AddMultipleDQDiscountController {
    @AuraEnabled
    public static CategoryWrapper getProductCategories(String packageName,String dqId, String changeOrderId, Boolean isPackageChange, String recordtypeName) {
       List<parentCategoryWrapper> categoryWrapperList = new List<parentCategoryWrapper>();
       map<String,parentCategoryWrapper> mapOfCategoryNameToParentCatWrap = new map<String,parentCategoryWrapper>();
       map<String,List<subCategoryWrapper>> mapOfCategoryToSubCategoryWrap = new map<String,List<subCategoryWrapper>>();
       map<String,List<String>> mapOfCategoryToSubCategoryName = new map<String,List<String>>(); 
       map<String,List<productWrapper>> mapOfSubCategoryNameToProductList = new map<String,List<productWrapper>>();
       Map<String,DQ_Deal_Qualification_Discounts__c> mapOfExistingProductIdToLineItem = new Map<String,DQ_Deal_Qualification_Discounts__c>();
        CategoryWrapper objMainWrap = new CategoryWrapper();
        objMainWrap.objPartnerQuoteRec = new Partner_Quote__c();
        String brandName = 'Avaya Cloud Office';
        if(dqId != null) {
           DQ_Deal_Qualification__c objOpp = [SELECT Id,Opportunity__r.Brand_Name__c FROM DQ_Deal_Qualification__c WHERE Id = :dqId];
		   brandName = objOpp.Opportunity__r.Brand_Name__c;            
        }
        if(dqId != null) {
                for(DQ_Deal_Qualification_Discounts__c eachLine :[SELECT Id, Product__c,Quantity__c,Discount__c FROM DQ_Deal_Qualification_Discounts__c 
                                                                  WHERE Deal_Qualification__c = :dqId and RecordType.Name = :recordtypeName]) {
                    mapOfExistingProductIdToLineItem.put(eachLine.Product__c,eachLine);
                }
        } 
		
        List<String> listOfAvailableCategories = new List<String>();
        List<String> listOfOrderCategories = new List<String>();
        
        if(packageName != null) {
        	Product_Package__c objPackage = [SELECT Id, Approval_Categories_Order__c,Product_Categories__c FROM Product_Package__c WHERE Id = :packageName];
            if(objPackage.Approval_Categories_Order__c != null) {
                listOfOrderCategories = objPackage.Approval_Categories_Order__c.split(';');
            }
            if(objPackage.Product_Categories__c != null) {
            	listOfAvailableCategories = objPackage.Product_Categories__c.split(';');
            }
        }
        for(Product_Catalogue__c eachProduct : [SELECT Product__r.GOA_Group_V3__c,Product__r.GOA_Group__c,Approval__c,Category_Name__c,Product_Package__c, Sub_Category_Name__c FROM Product_Catalogue__c 
                                                WHERE Product_Package__c =: packageName AND Category_Name__c != null AND Approval__c = true
                                    			AND Category_Name__c IN :listOfAvailableCategories]){
          if(mapOfCategoryToSubCategoryName.containsKey(eachProduct.Category_Name__c)) {
              if(!mapOfCategoryToSubCategoryName.get(eachProduct.Category_Name__c).contains(eachProduct.Sub_Category_Name__c)) {
              	mapOfCategoryToSubCategoryName.get(eachProduct.Category_Name__c).add(eachProduct.Sub_Category_Name__c);     
              }                                     
          }
          else {
               mapOfCategoryToSubCategoryName.put(eachProduct.Category_Name__c,new List<String>{eachProduct.Sub_Category_Name__c});                                         
          }
           
       }
        
       for(Product_Catalogue__c eachCatalogue : [SELECT id,Product__r.GOA_Group_V3__c ,Product__r.GOA_Group__c,Approval__c, Product__c,Parent__c, Parent__r.Product__c, 
                                                 Parent__r.Parent__c, Parent__r.Parent__r.Product__c, 
                                                 Color__c, Category_Name__c,Product_Package__c, Sub_Category_Name__c, 
                                                 Product_Catalogue_Rule__c, Product_Catalogue_Rule__r.Count_Dependent_On__c, Display_Name__c, Package_Product_Type__c
                                                 FROM Product_Catalogue__c WHERE Approval__c = true AND  Product_Package__c =: packageName AND 
                                                 (Package_Product_Type__c EXCLUDES ('Hide From Change Request')) 
                                                  ORDER BY Row_Order__c ASC]) {
         String productCategoryName;
         if(eachCatalogue.Product__r.GOA_Group_V3__c != null && eachCatalogue.Product__r.GOA_Group_V3__c.contains('regular')) {
                productCategoryName =  eachCatalogue.Product__r.GOA_Group_V3__c.substringBetween('{"regular":"','"');                                         
         }
         if(mapOfSubCategoryNameToProductList.containskey(eachCatalogue.Sub_Category_Name__c)) {
                   productWrapper obj = new productWrapper();
                   obj.productName = eachCatalogue.Display_Name__c;
                    
                  	if(mapOfExistingProductIdToLineItem.containsKey(eachCatalogue.Product__c)) {
                       obj.buttonLabel = 'Remove';
                        obj.isExisting = true;
                        obj.objDQDiscount = mapOfExistingProductIdToLineItem.get(eachCatalogue.Product__c).Id;
                       obj.actionType = 'Add';
                       obj.isSelected = true;
                        if(mapOfExistingProductIdToLineItem.get(eachCatalogue.Product__c).Discount__c > 0) {
                            obj.discount = Integer.valueof(mapOfExistingProductIdToLineItem.get(eachCatalogue.Product__c).Discount__c);
                        } else {
                            obj.discount = null;
                        }
                        if(mapOfExistingProductIdToLineItem.get(eachCatalogue.Product__c).Quantity__c > 0) {
                       		obj.quantity = Integer.valueof(mapOfExistingProductIdToLineItem.get(eachCatalogue.Product__c).Quantity__c);
                        } else {
                            obj.quantity = null;
                        }
                    } else {
                       obj.buttonLabel = 'Add';
                       obj.isSelected = false;
                       obj.quantity = null;
                       obj.actionType = 'Add';
                        obj.isExisting = false;
                   }
                   
                   obj.catalogueId = eachCatalogue.id;
                   obj.ProductId = eachCatalogue.Product__c;
             	   obj.packageId = eachCatalogue.Product_Package__c;
                   obj.productCategory = productCategoryName;
                  mapOfSubCategoryNameToProductList.get(eachCatalogue.Sub_Category_Name__c).add(obj);                                       
               }
               else {
                   productWrapper obj = new productWrapper();
                   obj.productName = eachCatalogue.Display_Name__c;
                    
                   if(mapOfExistingProductIdToLineItem.containsKey(eachCatalogue.Product__c)) {
                       obj.buttonLabel = 'Remove';
                       obj.isExisting = true;
                       obj.objDQDiscount = mapOfExistingProductIdToLineItem.get(eachCatalogue.Product__c).Id;
                       obj.actionType = 'Add';
                       obj.isSelected = true;
                       if(mapOfExistingProductIdToLineItem.get(eachCatalogue.Product__c).Discount__c > 0) {
                            obj.discount = Integer.valueof(mapOfExistingProductIdToLineItem.get(eachCatalogue.Product__c).Discount__c);
                       } else {
                            obj.discount = null;
                       }
                        
                       if(mapOfExistingProductIdToLineItem.get(eachCatalogue.Product__c).Quantity__c > 0) {
                       		obj.quantity = Integer.valueof(mapOfExistingProductIdToLineItem.get(eachCatalogue.Product__c).Quantity__c);
                       } else { 
                           obj.quantity = null;
                       }
                   } else {
                       obj.actionType = 'Add';
                       obj.buttonLabel = 'Add';
                       obj.isSelected = false;
                       obj.quantity = null;
                       obj.isExisting = false;
                   }
                    
                   obj.catalogueId = eachCatalogue.id;
                   obj.ProductId = eachCatalogue.Product__c;
                   obj.packageId = eachCatalogue.Product_Package__c;
                   obj.productCategory = productCategoryName;
                   mapOfSubCategoryNameToProductList.put(eachCatalogue.Sub_Category_Name__c,new list<productWrapper>{obj});
               }
       }
        
        for(String categoryName : mapOfCategoryToSubCategoryName.keySet()) {
            List<subCategoryWrapper> subCategoryList = new List<subCategoryWrapper>();
            parentCategoryWrapper objParentWrap = new parentCategoryWrapper();
            objParentWrap.CategoryName = categoryName;
            for(String subCategoryName : mapOfCategoryToSubCategoryName.get(categoryName)) {
                subCategoryWrapper objSubWrap = new subCategoryWrapper();
                objSubWrap.subCategoryName = subCategoryName;
                if(mapOfSubCategoryNameToProductList.containsKey(subCategoryName)) {
                    objSubWrap.productList = mapOfSubCategoryNameToProductList.get(subCategoryName);
                }
                subCategoryList.add(objSubWrap);
            }
            objParentWrap.subCategoryList = subCategoryList;
            mapOfCategoryNameToParentCatWrap.put(categoryName,objParentWrap);
            categoryWrapperList.add(objParentWrap);
        }
        
        if(listOfOrderCategories != null && listOfOrderCategories.size() > 0) {
            categoryWrapperList = new List<parentCategoryWrapper>();
            for(String categoryName : listOfOrderCategories) {
                if(mapOfCategoryNameToParentCatWrap.containsKey(categoryName.trim())) {
                    categoryWrapperList.add(mapOfCategoryNameToParentCatWrap.get(categoryName.trim()));
                }
            }
            objMainWrap.parentCategoryWrapperList =categoryWrapperList;
        } else {
        	objMainWrap.parentCategoryWrapperList =categoryWrapperList;
        }
        
        // Adding Dynamic Package on the basis of Brand
        
        List<EditionWrapper> listOfEditionWrappList = new List<EditionWrapper>();
        For(Product_Package__c objPackage : [SELECT Id,name,(SELECT Id,Description__c,Contract_Discount__c, Monthly_Price__c, Yearly_Price__c, No_of_Licenses__c 
                                               FROM Product_Tier_Prices__r) FROM Product_Package__c 
                                             	WHERE Brand_Name__c = :brandName 
                                             	AND Show_On_DQ__c = true]) {
            if(objPackage.Product_Tier_Prices__r.isEmpty()){
                continue;
             }                                 
       		EditionWrapper objWrapperEdition = new EditionWrapper();
            objWrapperEdition.pickVal =  objPackage.name;    
            objWrapperEdition.pickKey =  objPackage.Id;                                       
            listOfEditionWrappList.add(objWrapperEdition);
        }
        System.debug('categoryWrapperList>>'+categoryWrapperList);
        objMainWrap.listofEditionWrapper = listOfEditionWrappList;
        return objMainWrap;
    }
    
    
    
    @AuraEnabled
    public static void createDQDiscount(String categoryWrapperStr,String dqId,String recordtypeName) {
        System.debug('categoryWrapperStr>>'+categoryWrapperStr);
        Id dqDiscountRecordTypeId = Schema.SObjectType.DQ_Deal_Qualification_Discounts__c.getRecordTypeInfosByName().get(recordtypeName).getRecordTypeId();
		List<parentCategoryWrapper> categoryList = (List<parentCategoryWrapper>)System.JSON.deserialize(categoryWrapperStr, List<parentCategoryWrapper>.class);
        List<DQ_Deal_Qualification_Discounts__c> DQDiscountList = new List<DQ_Deal_Qualification_Discounts__c>();
        List<DQ_Deal_Qualification_Discounts__c> DQDiscountListToUpdate = new List<DQ_Deal_Qualification_Discounts__c>();
        List<DQ_Deal_Qualification_Discounts__c> DQDiscountListToDelete = new List<DQ_Deal_Qualification_Discounts__c>();
        Map<String,DQ_Deal_Qualification_Discounts__c> mapOfExistingProductIdToLineItem = new Map<String,DQ_Deal_Qualification_Discounts__c>();
        for(DQ_Deal_Qualification_Discounts__c eachLine :[SELECT Id, Product__c,Quantity__c,Discount__c FROM DQ_Deal_Qualification_Discounts__c 
                                                          WHERE Deal_Qualification__c = :dqId and RecordType.Name = :recordtypeName]) {
                    mapOfExistingProductIdToLineItem.put(eachLine.Id,eachLine);
        }
        For(parentCategoryWrapper objParent : categoryList) {
            for(subCategoryWrapper objchild : objParent.subCategoryList) {
                for(productWrapper objProd : objchild.productList) {
                    if(objProd.isSelected && !objProd.isExisting) {
                        DQ_Deal_Qualification_Discounts__c objDQLine = new DQ_Deal_Qualification_Discounts__c();
                        objDQLine.Deal_Qualification__c = dqId;
                        objDQLine.RecordTypeId = dqDiscountRecordTypeId;
                        objDQLine.Quantity__c = objProd.quantity;
                        objDQLine.Discount__c = objProd.discount;
                        objDQLine.Product__c = objProd.ProductId;
                        objDQLine.Product_package__c =  objProd.packageId;
                        objDQLine.Product_Category__c = objProd.productCategory;
                        DQDiscountList.add(objDQLine);
                    } else if(objProd.isSelected && objProd.isExisting) {
                        // Add Dq Discount For Update..
                        if(mapOfExistingProductIdToLineItem.containsKey(objProd.objDQDiscount)) {
                            DQ_Deal_Qualification_Discounts__c objDQLine = mapOfExistingProductIdToLineItem.get(objProd.objDQDiscount);
                            objDQLine.Quantity__c = objProd.quantity;
                            objDQLine.RecordTypeId = dqDiscountRecordTypeId;
                            objDQLine.Discount__c = objProd.discount;
                            objDQLine.Product__c = objProd.ProductId;
                            objDQLine.Product_Category__c = objProd.productCategory; 
                            DQDiscountListToUpdate.add(objDQLine);
                        }
                    } else if(!objProd.isSelected && objProd.isExisting) {
                        // Remove Dq Discount..
                        if(mapOfExistingProductIdToLineItem.containsKey(objProd.objDQDiscount)) {
                        	DQDiscountListToDelete.add(mapOfExistingProductIdToLineItem.get(objProd.objDQDiscount));
                        }
                    }
                }
            }
        }
        
        if(!DQDiscountList.isEmpty()) {
            insert DQDiscountList;
        }
        if(!DQDiscountListToUpdate.isEmpty()) {
            update DQDiscountListToUpdate;
        }
        if(!DQDiscountListToDelete.isEmpty()) {
            delete DQDiscountListToDelete;
        }
    }
    
    public class CategoryWrapper {
        @AuraEnabled
        public Partner_Quote__c objPartnerQuoteRec;
        @AuraEnabled
        public List<EditionWrapper> listofEditionWrapper;
        @AuraEnabled
        public List<parentCategoryWrapper> parentCategoryWrapperList;
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
        public integer discount;
        @AuraEnabled
        public String actionType;
        @AuraEnabled
        public Boolean isExisting;
        @AuraEnabled
        public String objDQDiscount;
        @AuraEnabled
        public String buttonLabel;
        @AuraEnabled
        public String packageId;
        @AuraEnabled
        public String productCategory;
    }

}