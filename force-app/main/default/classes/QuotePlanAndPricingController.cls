//Naresh Kumar  10/23/2019
public without sharing class QuotePlanAndPricingController {
    public Static final String DISCOUNT_REQUEST_TYPE = 'Discount Request';
    public Static final String CLOSED_APPROVED_STATUS = 'Closed-Approved';
    public QuotePlanAndPricingController() {

    }
      @AuraEnabled
  public static Wrapper getInfo(String OpporQuoteId){
    //EDU Packages
    Wrapper wrapper = new Wrapper();
    if (OpporQuoteId.startsWith('006')){
      Opportunity opp = [select Account.Sector__c, CurrencyIsoCode from Opportunity where Id = :OpporQuoteId];
      if (opp != null) {
        wrapper.currencyISOCode = opp.CurrencyIsoCode;
      }
      if (opp != null && opp.Account != null) {
        wrapper.accountSector = opp.Account.Sector__c;
      }
    } else{
      Partner_Quote__c quote = [select Opportunity__c, Opportunity__r.Account.Sector__c, Opportunity__r.CurrencyIsoCode from Partner_Quote__c where Id = :OpporQuoteId];
      if (quote != null && quote.Opportunity__c != null) {
        wrapper.currencyISOCode = quote.Opportunity__r.CurrencyIsoCode;
      }
      if (quote != null && quote.Opportunity__c != null && quote.Opportunity__r.Account != null) {
        wrapper.accountSector = quote.Opportunity__r.Account.Sector__c;
      }
    }
    return wrapper;
  }
  public class Wrapper{
    //EDU Packages
    @AuraEnabled
    public String accountSector{ get; set; }
    @AuraEnabled
    public String currencyISOCode{ get; set; }
  }

    @AuraEnabled
    public static User getCurrentUser(){
        return [SELECT Partner_Discount_Approval__c, UserType FROM User WHERE ID =: UserInfo.getUserId()];
    }

    @AuraEnabled
    public static Boolean checkSuperUser(){
        return Quote_PartnerQuoteUtil.checkSuperUser();
    }
	 //Translation Start
  @AuraEnabled
  public static CommunityInfo.Translationswrap getTranslations(String objNames){
    System.debug('Inside translation method of QuotePlanAndPricingCotroller');
    return CommunityInfo.getTranslations(objNames);
  }
  //Translation End

    @AuraEnabled
    public static List<productEditionWrapper> getProductEditions(String oppId,String parentPackageId){
        //String siteName = Site.getName();
        String oppCurrencyIsoCode;
        String BrandName = 'Avaya Cloud Office';
        String accountType;
        String partnerAcctId;
        Boolean isRingCentralVideo = false;
        Map<String,List<picklistWrapper>> mapOfEditionIdTOPickValue = new Map<String,List<picklistWrapper>>();
        if(oppId.startsWith('006')){
            Opportunity objOpp = [SELECT Id,Tier_Name__c,Brand_Name__c,CurrencyIsoCode, Name,Partner_Account__r.Partner_Type__c,Partner_Account__c FROM Opportunity WHERE Id =: oppId ][0];
            oppCurrencyIsoCode = objOpp.CurrencyIsoCode;
            accountType=objOpp.Partner_Account__r.Partner_Type__c;
            partnerAcctId=objOpp.Partner_Account__c;
            if(objOpp.Brand_Name__c != null) {
                BrandName = objOpp.Brand_Name__c;
            }
            if(objOpp.Tier_Name__c == 'RC Meetings') {
                isRingCentralVideo = true;
            }
        }
        else {
            Partner_Quote__c objQuoteRec = Quote_PartnerQuoteUtil.getQuote(oppId);
            oppCurrencyIsoCode = objQuoteRec.CurrencyIsoCode;
            accountType=objQuoteRec.Opportunity__r.Partner_Account__r.Partner_Type__c;
            partnerAcctId=objQuoteRec.Opportunity__r.Partner_Account__c;
            //if(objQuoteRec.Brand_Name__c != null)
            if(objQuoteRec.Opportunity__r.Brand_Name__c != null) {
                BrandName = objQuoteRec.Opportunity__r.Brand_Name__c;
            }
            if(objQuoteRec.Opportunity__r.Tier_Name__c == 'RC Meetings') {
                isRingCentralVideo = true;
            }
        }
        List<productEditionWrapper> listOfProductEditionWrap = new List<productEditionWrapper>();
        for(Partner_Quote__c objQuote : [SELECT Id, Name__c,Product_Edition__c FROM Partner_Quote__c WHERE RecordType.Name = 'Quote Template'
                                         and Product_Edition__c != null and User__c = : UserInfo.getUserId() and CurrencyIsoCode = :oppCurrencyIsoCode]) {
              picklistWrapper obj = new picklistWrapper();
              obj.label = objQuote.Name__c;
              obj.templateId = objQuote.Id;
              obj.isSelected = false;
             if(mapOfEditionIdTOPickValue.containsKey(objQuote.Product_Edition__c)) {
                 mapOfEditionIdTOPickValue.get(objQuote.Product_Edition__c).add(obj);
             }
             else {
                 mapOfEditionIdTOPickValue.put(objQuote.Product_Edition__c,new List<picklistWrapper>{obj});
             }
        }
        //Added for wholesale starts
        List<Product_Package__c> packagesList = new List<Product_Package__c>();
        if(accountType!= null && accountType.contains('Wholesale-Reseller')){

            if(String.isNotEmpty(parentPackageId)){
                Set<ID> subPackagesID = new Set<ID>();
                List<Wholesale_Partner_Package__c> wholesalePackages= [SELECT id,Product_Package__c,Parent_Product_Package__c,Start_Date__c,End_Date__c from Wholesale_Partner_Package__c where Parent_Product_Package__c =:parentPackageId];
                for(Wholesale_Partner_Package__c eachPackage : wholesalePackages){
                    Boolean packageStart = false;
                    Boolean packageEnd = false;
                    if((Date.today() >= eachPackage.Start_Date__c) || eachPackage.Start_Date__c == null){
                        packageStart = true;
                    }
                    if((Date.today() <= eachPackage.End_Date__c) || eachPackage.End_Date__c == null){
                        packageEnd = true;
                    }
                    if(packageStart && packageEnd){
                        subPackagesID.add(eachPackage.Product_Package__c);
                    }
                }
                packagesList=[SELECT id,Contract_Discount__c, Name, Description__c,(SELECT Id,Description__c,Contract_Discount__c, Monthly_Price__c, Yearly_Price__c, No_of_Licenses__c
                                               FROM Product_Tier_Prices__r WHERE CurrencyIsoCode = :oppCurrencyIsoCode ORDER BY No_of_Licenses__c), Price__c, CurrencyISOCode,
                                               Product_Categories__c
                                               FROM Product_Package__c WHERE Active__c = true and ID in:subPackagesID ORDER BY Display_Order__c ASC];
            }else{
                List<Wholesale_Partner_Package__c> wsppList=[select id,Parent_Product_Package__c,Product_Package__c,End_Date__c,Start_Date__c from Wholesale_Partner_Package__c where Wholesale_Partner_Account__c =:partnerAcctId];
                Set<ID> parentProductPackageIDs = new Set<ID>();
                for(Wholesale_Partner_Package__c parentPackage: wsppList){
                    Boolean packageStart = false;
                    Boolean packageEnd = false;
                    if((Date.today() >= parentPackage.Start_Date__c) || parentPackage.Start_Date__c == null){
                        packageStart = true;
                    }
                    if((Date.today() <= parentPackage.End_Date__c) || parentPackage.End_Date__c == null){
                        packageEnd = true;
                    }
                    if(packageStart && packageEnd){
                        parentProductPackageIDs.add(parentPackage.Parent_Product_Package__c);
                    }
                }
                packagesList=[SELECT id,Contract_Discount__c, Name, Description__c,(SELECT Id,Description__c,Contract_Discount__c, Monthly_Price__c, Yearly_Price__c, No_of_Licenses__c
                                                                                    FROM Product_Tier_Prices__r WHERE CurrencyIsoCode = :oppCurrencyIsoCode ORDER BY No_of_Licenses__c), Price__c, CurrencyISOCode,
                              Product_Categories__c
                              FROM Product_Package__c WHERE Active__c = true and ID in:parentProductPackageIDs ORDER BY Display_Order__c ASC];
            }
        }else{
            List<Product_Package__c> allpackagesList=[SELECT id,Contract_Discount__c, Name, Description__c,(SELECT Id,Description__c,Contract_Discount__c, Monthly_Price__c, Yearly_Price__c, No_of_Licenses__c
                                               FROM Product_Tier_Prices__r WHERE CurrencyIsoCode = :oppCurrencyIsoCode ORDER BY No_of_Licenses__c), Price__c, CurrencyISOCode,Monthly_Packgage_Info__c,
                                               Product_Categories__c
                                               FROM Product_Package__c WHERE Active__c = true and Skip_Pick_Your_Number__c = :isRingCentralVideo and Brand_Name__c = :BrandName ORDER BY Display_Order__c ASC];
            for(Product_Package__c eachPackage : allpackagesList){
                if(eachPackage.Monthly_Packgage_Info__c == null || eachPackage.Monthly_Packgage_Info__c.containsNone('Wholesale')) {
                    packagesList.add(eachPackage);
                }
            }
        }
        //Added for wholesale ends
        for(Product_Package__c eachEdition :  packagesList) {
            //System.assert(false,oppCurrencyIsoCode);
             if(eachEdition.Product_Tier_Prices__r.isEmpty()){
                continue;
             }

            productEditionWrapper obj = new productEditionWrapper();
            obj.editionDescription = eachEdition.Description__c;
            for(Product_Tier_Price__c objProductTier : eachEdition.Product_Tier_Prices__r) {
                 if(objProductTier.Description__c != null) {
                    obj.editionDescription = objProductTier.Description__c;
                 }
            }
            obj.editionRec = eachEdition;
            if(mapOfEditionIdTOPickValue.containsKey(eachEdition.Id)) {
                obj.listOfPickValue = mapOfEditionIdTOPickValue.get(eachEdition.Id);
            }
            obj.currencyIsoCode  =   oppCurrencyIsoCode;
            if(eachEdition.Name.contains('Unlimited')){
                obj.isGlobal = true;
            } else{
                obj.isGlobal = false;
            }
            if(String.isNotEmpty(parentPackageId)){
                obj.ParentOrSubPackage = 'Sub Package';
            }
            else if(accountType !=null && accountType.contains('Wholesale-Reseller')){
                obj.ParentOrSubPackage = 'Parent Package';
            }
            listOfProductEditionWrap.add(obj);
        }


        return listOfProductEditionWrap;
    }

    @AuraEnabled
    public static Product_Package__c getProductEdition(Id editionId){
        return [SELECT id, Name, Description__c, Price__c, CurrencyISOCode
                FROM Product_Package__c WHERE id =: editionId];
    }

    @AuraEnabled
    public static Partner_Quote__c getQuote(Id quoteId){
        return Quote_PartnerQuoteUtil.getQuote(quoteId);
    }

    @AuraEnabled
    public static List<Quote> getQuoteMain(Id opportunityId){
        return Quote_PartnerQuoteUtil.getQuoteMain(opportunityId);
    }

    @AuraEnabled
    public static Id cloneQuote(Id quoteId){
        return Quote_PartnerQuoteUtil.cloneQuote(quoteId);
    }

    @AuraEnabled
    public static User getCurrentUserInfo(){
        return [SELECT UserType, ProfileId, Partner_Discount_Approval__c,Contact.Account.Partner_Type__c,Contact.Account.Partner_ID__c,Contact.Account.Partner_Account__r.Partner_ID__c FROM User WHERE Id =: UserInfo.getUserId()];
		//added partner_type__c and partner_ID__C for mitel
    }

    @AuraEnabled public static List<QuotePlanAndPricingController.ProductWrapper> deleteQuoteLine(Id quoteId, Id quoteLineId){
        Partner_Quote_Line__c objQLToDelete = new Partner_Quote_Line__c(id = quoteLineId);
        delete objQLToDelete;
        return Quote_PartnerQuoteUtil.getProductsFromQuote(quoteId);
    }

    @AuraEnabled public static void deleteQuoteLineFromProductId(Id quoteId, Id productId){

        List<Partner_Quote_Line__c> objQLToDelete = [SELECT id FROM Partner_Quote_Line__c
                                 WHERE Partner_Quote__c =: quoteId AND Product__c =: productId];
        if(!objQLToDelete.isEmpty()) {
            delete objQLToDelete;
        }
    }

    @AuraEnabled
    public static List<ProductWrapper> getProductsFromQuote(Id quoteId){
        return Quote_PartnerQuoteUtil.getProductsFromQuote(quoteId);
    }

    @AuraEnabled
    //loadHideDiscountFlag
    public static Boolean loadHideDiscountFlag(Id quoteId) {
        Boolean isSuperUser = Quote_PartnerQuoteUtil.checkSuperUser();
        if(test.isRunningTest()) {
            isSuperUser = true;
        }
        Partner_Quote__c objQuote = getQuote(quoteId);
        User currentUser = getCurrentUserInfo();
        if(currentUser.UserType == 'Standard') {
            return true;
        } else if(currentUser.UserType != 'Standard' && isSuperUser) {
            return true;
        } else if(objQuote.Discount_Line_Count__c > 0 && !isSuperUser) {
            return true;
        }
        return false;
    }

    @AuraEnabled
    public static List<QuotePlanAndPricingController.ProductWrapper> getProductsForEdition(Id quoteId, String packageProductType,
                                                                                           String categoryName, Boolean showQuoteLinesOnly, List<String> selectedSubCategory){
        return Quote_PartnerQuoteUtil.getProductsForEdition(quoteId, packageProductType, categoryName, showQuoteLinesOnly, selectedSubCategory);
    }

    @AuraEnabled
    public static List<QuotePlanAndPricingController.ProductWrapper> validateRules(Id quoteId, String productList){
        List<ProductWrapper> listOfProducts = new List<ProductWrapper>();
        if(!String.isBlank(productList)) {
            listOfProducts = (List<ProductWrapper>)JSON.deserialize(productList, List<ProductWrapper>.class);
        }
        return Quote_PartnerQuoteUtil.validateRules(quoteId, listOfProducts);
    }


    @AuraEnabled public static Partner_Quote__c createUpdatePartnerQuote(Id opportunityId, Partner_Quote__c objPartnerQuote,
                                                                   String quoteLines, Boolean doUpdateLines,
                                                                   Boolean isPackageChanged){
        if(doUpdateLines == null) {
            doUpdateLines = false;
        }
        List<ProductWrapper> listOfQuoteLines = new List<ProductWrapper>();
        if(!String.isBlank(quoteLines)) {
            listOfQuoteLines = (List<ProductWrapper>)JSON.deserialize(quoteLines, List<ProductWrapper>.class);
        }
        return Quote_PartnerQuoteUtil.createUpdatePartnerQuote(opportunityId, objPartnerQuote, listOfQuoteLines,
                                                         doUpdateLines, isPackageChanged);
    }

     @AuraEnabled public static List<AdditionalProductWrapper> getProductCategories(String editionId,Partner_Quote__c objQuoteRec){
        return Quote_PartnerQuoteUtil.getProductCategories(editionId,objQuoteRec);
    }

    @AuraEnabled
    public static UserInformationWrapper getOtherDetails(String quoteId) {
        Map<String,Partner_Quote_Promo_Detail__c> mapOfPackageIdToPromoDetail = new Map<String,Partner_Quote_Promo_Detail__c>();
        Map<String,List<Partner_Quote_Promo_Detail__c>> mapOfPromoToListAssociatedDetail = new Map<String,List<Partner_Quote_Promo_Detail__c>>();
        Boolean isSuperUser = Quote_PartnerQuoteUtil.checkSuperUser();
        List<Deal_Support__c> dealSupportList;
        if(test.isRunningTest()) {
            isSuperUser = true;
        }
        Partner_Quote__c objQuote = getQuote(quoteId);
        List<Quote> objQuoteMain = getQuoteMain(objQuote.Opportunity__c);
        String businessIdentity;
        if(!objQuoteMain.isEmpty() && objQuoteMain!=null &&  objQuoteMain.size()>0){
            businessIdentity = Quote_PartnerQuoteUtil.getApprovedBIFromQuote(objQuoteMain[0]);
        }
        User currentUser = getCurrentUserInfo();
        Boolean isReadOnlyUser = Quote_PartnerQuoteUtil.getReadOnlyFlagForUser();
        Boolean currentUserdiscountAccess = false;
        Boolean isPromoCodeAppliedApproved = false;
        Boolean isSpecialPermissionPromoAvail = FeatureManagement.checkPermission('Special_Permission_Promo');
        if(currentUser.UserType == 'Standard') {
            currentUserdiscountAccess =  true;
        } else if(currentUser.UserType != 'Standard' && isSuperUser) {
            currentUserdiscountAccess = true;
            dealSupportList = [SELECT Id,Promo_Code__c FROM Deal_Support__c WHERE Type__c = :DISCOUNT_REQUEST_TYPE
                                                     AND Status__c = :CLOSED_APPROVED_STATUS AND Promo_Code__c != null
                                                     AND Partner_Quote__c = :quoteId];
            if(dealSupportList != null && dealSupportList.size() > 0) {
                isPromoCodeAppliedApproved = true;
            }
        } else if(objQuote.Discount_Line_Count__c > 0 && !isSuperUser) {
            currentUserdiscountAccess = true;
        }

        String promoQuery = 'SELECT ID,Specail_Permission__c,isRequired__c,Name,Product_Catalogue__r.Product__c,Term__c,Discount__c,Quantity__c,Product_Catalogue__c, Discount_Amount__c FROM Partner_Quote_Promo_Detail__c';
        promoQuery += ' where Product_Catalogue__r.Product_Package__c = \'' + objQuote.Product_Edition__c + '\'';
        promoQuery += ' and Brand_Name__c = \'' + objQuote.Opportunity__r.Brand_Name__c + '\'';
        promoQuery += ' and Payment_Plan__c includes (\'' + objQuote.Payment_Term__c + '\')';
        promoQuery += ' and Segment__c includes (\'' + objQuote.Opportunity__r.Segment_Name__c + '\')';

        if(businessIdentity != null && businessIdentity != '') {
            promoQuery += ' and Business_Identity__c includes (\'' + businessIdentity + '\')';
        }else{
            if(objQuote.CurrencyIsoCode != null){
               List<Business_Identity_Mapping__c> biMap = Business_Identity_Mapping__c.getall().values();
               Set<String> selectedBI = new Set<String>();
               if(biMap != null && !biMap.isEmpty()){
                   for(Business_Identity_Mapping__c bi: biMap){
                       List<String> currencyIsoCode = bi.CurrencyIsoCode__c.split(';');
                       if(bi.Brand_Name__c == objQuote.Opportunity__r.Brand_Name__c && currencyIsoCode.contains(objQuote.CurrencyIsoCode)){
                           selectedBI.add(bi.name);
                       }
                   }
               }
               if(!selectedBI.isEmpty()){
                   String joinedBI = String.join(new List<String>(selectedBI), '\',\'' );
                   promoQuery += ' and Business_Identity__c includes (\'' + joinedBI + '\')';
               }
            }
        }
        system.debug('promoQuery>>> ' + promoQuery);
        List<Partner_Quote_Promo_Detail__c> promoDetailList = Database.query(promoQuery);
        for(Partner_Quote_Promo_Detail__c objPromoDetail : promoDetailList){
            if(dealSupportList != null && dealSupportList.size() > 0 && dealSupportList[0].Promo_Code__c == objPromoDetail.Name) {
                mapOfPackageIdToPromoDetail.put(objPromoDetail.Product_Catalogue__c,objPromoDetail);
            }
            if(mapOfPromoToListAssociatedDetail.containsKey(objPromoDetail.Name)) {
                mapOfPromoToListAssociatedDetail.get(objPromoDetail.Name).add(objPromoDetail);
            } else{
                mapOfPromoToListAssociatedDetail.put(objPromoDetail.Name,new List<Partner_Quote_Promo_Detail__c>{objPromoDetail});
            }
        }

        UserInformationWrapper obj = new UserInformationWrapper();
        obj.discountAccess = currentUserdiscountAccess;
        obj.isPromoCodeAppliedApproved = isPromoCodeAppliedApproved;
        obj.isSpecialPermissionPromoAvail = isSpecialPermissionPromoAvail;
        obj.isSuperUser = isSuperUser;
        obj.currentUserDetails = currentUser;
        obj.isCustomPermissionAvailable = isReadOnlyUser;
        obj.mapOfPackageToPromoRec = mapOfPackageIdToPromoDetail;
        obj.mapOfPromoToListAssociatedDetail = mapOfPromoToListAssociatedDetail;
        obj.skipPYN = objQuote.Product_Edition__r.Skip_Pick_Your_Number__c;
        return obj;
    }
    //Added for GO Pricing - start
    @AuraEnabled
    public static string getOpportunityCurrency(string OppIdOrQuoteId){
        string currencycode;
        if(OppIdOrQuoteId.startsWith('006')) {
            List<opportunity> oppList = [SELECT Id,CurrencyISOCode FROM Opportunity WHERE Id = :OppIdOrQuoteId];
            if(oppList != null && oppList.size() > 0) {
                currencycode = oppList[0].CurrencyISOCode;
            }
        }
        else {
            currencycode = Quote_partnerQuoteUtil.getQuote(OppIdOrQuoteId).Opportunity__r.CurrencyIsoCode;
        }
        return currencycode;
    }
    //Added for GO Pricing - end
    @AuraEnabled
    public static string getBrandNameFromOppOrQuote(String OppIdOrQuoteId) {
        String BrandName;
        if(OppIdOrQuoteId.startsWith('006')) {
            List<opportunity> oppList = [SELECT Id,Brand_Name__c FROM Opportunity WHERE Id = :OppIdOrQuoteId];
            if(oppList != null && oppList.size() > 0) {
                BrandName = oppList[0].Brand_Name__c;
            }
        }
        else {
            BrandName = Quote_partnerQuoteUtil.getQuote(OppIdOrQuoteId).Opportunity__r.Brand_Name__c;
        }

        return BrandName;
    }

    public class UserInformationWrapper{
        @AuraEnabled public Boolean discountAccess;
        @AuraEnabled public Boolean isSuperUser;
        @AuraEnabled public User currentUserDetails;
        @AuraEnabled public Boolean isCustomPermissionAvailable;
        @AuraEnabled public Boolean isPromoCodeAppliedApproved;
        @AuraEnabled public Boolean isSpecialPermissionPromoAvail;
        @AuraEnabled public Map<String,Partner_Quote_Promo_Detail__c> mapOfPackageToPromoRec;
        @AuraEnabled public Map<String,List<Partner_Quote_Promo_Detail__c>> mapOfPromoToListAssociatedDetail;
        @AuraEnabled public Boolean skipPYN;
    }

    public class AdditionalProductWrapper{
        @AuraEnabled public String categoryName;
        @AuraEnabled public String iconName;
        @AuraEnabled public List<String> subCategories;
        @AuraEnabled public List<optionWrapper> optionWrapperList;
        @AuraEnabled public Boolean isInitialOrder; //ProServ

        public AdditionalProductWrapper(String categoryName, String iconName, List<String> subCategories, List<optionWrapper> optionWrapperList, Boolean isInitialOrder){
            this.categoryName = categoryName;
            this.iconName = iconName;
            this.subCategories = subCategories;
            this.optionWrapperList = optionWrapperList;
            this.isInitialOrder = isInitialOrder; //ProServ
        }

        public AdditionalProductWrapper(){

        }
    }

    public class optionWrapper {
       @AuraEnabled public String value;
       @AuraEnabled public Boolean selected;
        @AuraEnabled public String label;
    }

    public class productEditionWrapper {
       @AuraEnabled public Product_Package__c editionRec;
       @AuraEnabled public List<picklistWrapper> listOfPickValue;
       @AuraEnabled public Boolean isGlobal;//Added for GO Pricing
       @AuraEnabled public String currencyIsoCode;
       @AuraEnabled public String editionDescription;
       @AuraEnabled public String ParentOrSubPackage; //Added for wholesale
    }

    public class picklistWrapper {
       @AuraEnabled public String label;
       @AuraEnabled public String templateId;
       @AuraEnabled public Boolean isSelected;
    }

    public class ProductWrapper{
        @AuraEnabled public Boolean isSelected;
        @AuraEnabled public String productCategory;
        @AuraEnabled public Product2 objProduct;
        @AuraEnabled public Decimal quantity;
        @AuraEnabled public Decimal subscriptionQuantity;
        @AuraEnabled public Decimal listPrice;
        @AuraEnabled public Decimal partnerDiscount;
        @AuraEnabled public String discountType;
        @AuraEnabled public Double netPrice;
        @AuraEnabled public String rowType;
        @AuraEnabled public List<ProductWrapper> childProducts;
        @AuraEnabled public String rowColor;
        @AuraEnabled public String leftSpace;
        @AuraEnabled public Product_Catalogue__c objCatalogue;
        @AuraEnabled public Partner_Quote_Line__c objQuoteLine;
        @AuraEnabled public List<Product_Tier_Price__c> listOfTiers;
        @AuraEnabled public Product_Catalogue_Rule__c objRule;
        @AuraEnabled public Product_Catalogue_Rule__c lboxRule;
        @AuraEnabled public Id parentId;
        @AuraEnabled public String errorMsg;
        @AuraEnabled public Decimal hierarchyLevel;
        @AuraEnabled public Boolean isAutoSelect;
        @AuraEnabled public Boolean isDisabled;
        @AuraEnabled public Boolean isParent;
        @AuraEnabled public Boolean isChild;
        @AuraEnabled public String buttonText;
        @AuraEnabled public String buttonTip;
        @AuraEnabled public Boolean isQuantityDisabled;
        @AuraEnabled public Boolean isDiscountDisabled;
        @AuraEnabled public Boolean showAddButton;
        @AuraEnabled public String rowIcon;
        @AuraEnabled public String rowIconVariant;
        @AuraEnabled public Boolean isProductHidden;
        @AuraEnabled public Boolean doUpdate;
        @AuraEnabled public Boolean showImplementationNumberFields;
        public ProductWrapper(String productCategory, Product2 objProduct, String rowType,
                              List<ProductWrapper> childProducts, List<Product_Tier_Price__c> listOfTiers,
                              Product_Catalogue_Rule__c objRule, Product_Catalogue_Rule__c lboxRule, Product_Catalogue__c objCatalogue,
                              Partner_Quote_Line__c objQuoteLine, Boolean isSelected, Integer hierarchyLevel,
                              String rowColor, String leftSpace, Id parentId, String rowIcon, String rowIconVariant){
            this.isSelected = isSelected;
            this.productCategory = productCategory;
            this.objProduct = objProduct;
            this.objCatalogue = objCatalogue;
            this.objQuoteLine = objQuoteLine;
            this.rowType = rowType;
            this.listPrice = 0;
            this.netPrice = 0;
            this.discountType = '%';
            this.childProducts = childProducts;
            this.listOfTiers = listOfTiers;
            this.hierarchyLevel = Decimal.valueOf(hierarchyLevel);
            this.rowColor = rowColor;
            this.leftSpace = leftSpace;
            this.objRule = objRule;
            this.lboxRule = lboxRule;
            this.isAutoSelect = false;
            //this.isDisabled = isSelected;
            this.isParent = false;
            this.isChild = false;
            if(isSelected) {
                this.buttonText = 'Update';
            } else {
                this.buttonText = 'Add';
            }
            this.parentId = parentId;
            this.isQuantityDisabled = false;
            this.showAddButton = true;
            this.rowIcon = rowIcon;
            this.rowIconVariant = rowIconVariant;
            this.isProductHidden = false;
            this.doUpdate = false;
            this.showImplementationNumberFields = false;
            if(objCatalogue != null && objCatalogue.Package_Product_Type__c != null){
                if(objCatalogue.Package_Product_Type__c.contains('Quantity same as parent')){
                    this.isQuantityDisabled = true;
                    this.isDiscountDisabled = true;
                    this.showAddButton = false;
                }

                if(objCatalogue.Package_Product_Type__c.contains('Hide Button')){
                    this.isQuantityDisabled = true;
                    this.isDiscountDisabled = true;
                    this.showAddButton = false;
                }

                if(objCatalogue.Package_Product_Type__c.contains('Lock Discount')){
                    this.isDiscountDisabled = true;
                }

                if(objCatalogue.Package_Product_Type__c.contains('Hidden')){
                    this.isProductHidden = true;
                }

                if(objCatalogue.Package_Product_Type__c.contains('Fixed Quantity')){
                    this.quantity = objCatalogue.Default_Quantity__c;
                    this.isQuantityDisabled = true;
                }

                if(objCatalogue.Package_Product_Type__c.contains('Lock Discount') && objCatalogue.Package_Product_Type__c.contains('Fixed Quantity')){
                    this.showAddButton = false;
                }
                if(objCatalogue.Package_Product_Type__c.contains('Implementation - Show Number Fields')){
                    this.showImplementationNumberFields = true;
                }

            }
        }

        public ProductWrapper(){
            this.isSelected = false;
        }
    }
    @AuraEnabled
    public static String createDealSprtForEngageProServ(String quoteId,Boolean availProServ,String proServNotes){
        return Quote_PartnerDetailController.createDealSprtForEngageProServ(quoteId,availProServ,proServNotes);
    }
    public class topMasterWrapper{
        @AuraEnabled
        public Boolean isAvaya;
        @AuraEnabled
        public Boolean isContractTeam;
        @AuraEnabled
        public List<String> partnerCommunityName{get;set;}
    }
    @AuraEnabled
    public static topMasterWrapper checkIsTopMaster(String quoteBrandName){
        String portalTopMasters;
        String portalQuoteContractTeam;
        Boolean isAvaya = false;

        topMasterWrapper topMasterDetail = new topMasterWrapper();
        CommunityInfo comm = new CommunityInfo();
        Community_Details__mdt comDetail = CommunityInfo.getCommunityDetails();
        List<String> brandNamesList = comDetail?.Brand_Name__c.split(';');
        Map<String,Community_Details__mdt> comDetailMap = new Map<String,Community_Details__mdt>();

        if(brandNamesList != NULL){
            topMasterDetail.partnerCommunityName = brandNamesList;
            topMasterDetail.isAvaya = false;
        }
        if(comDetail == null){
            comDetailMap = CommunityInfo.getAllCommunityDetails();
            if(QuoteBrandName != null){
                comDetail = comDetailMap.get(quoteBrandName);
            }
        }
        if(comDetail != null) {
            portalQuoteContractTeam = comDetail.Portal_Quote_Contract_Team__c;
            portalTopMasters = comDetail.Portal_Top_Master_Account_Id__c;
        }
        if(PartnerDealRegistrationUtil.getSelectedPartnerId() == portalTopMasters){
            topMasterDetail.isAvaya = true;
            isAvaya = true;
        }

        if(UserInfo.getUserType() == 'Standard') {
            topMasterDetail.isContractTeam = true;
        }
        if(isAvaya){
            Set<Id> userIds=new Set<Id>();
                if(portalQuoteContractTeam !=null){
                    for(GroupMember m : [Select Id, UserOrGroupId,GroupId,Group.type,Group.Name From GroupMember WHERE Group.Name=:portalQuoteContractTeam]) {
                        if(m.UserOrGroupId!=null){
                            userIds.add(m.UserOrGroupId);
                        }
                    }
                }
            if(!userIds.IsEmpty() && userIds!=null && userIds.size()>0){
                if(userIds.contains(UserInfo.getUserId())){
                    topMasterDetail.isContractTeam = true;
                }
            }
        }

        return topMasterDetail;
    }
}