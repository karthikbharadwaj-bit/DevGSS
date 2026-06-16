public without Sharing class Quote_PartnerDetailController {
    public static Integer sizeOfMap {get;  set;}
    public List<QuoteLineWrapper> listOfQuoteLines {get; private set;}     
    public static Map<Id,List<Partner_Contract_Detail__c>> mapPartnerContractIdNLstPartnerContractDetails {get;set;}
    public static Map<Id,List<Partner_Contract_Service__c>> mapPartnerContractDetailIdNLstPartnerContractServices {get;set;}
    public List<Partner_Contract__c> lstPartnerContract {get;set;}
    public static final string DEFAULT_COUNTRY_VALUE = 'United States';
    
	public Quote_PartnerDetailController(){
        String quoteId = ApexPages.currentPage().getParameters().get('Id');
        sizeOfMap = 0;
       	mapPartnerContractIdNLstPartnerContractDetails  = new Map<Id,List<Partner_Contract_Detail__c>>();
        mapPartnerContractDetailIdNLstPartnerContractServices = new Map<Id,List<Partner_Contract_Service__c>>();
        mapPartnerContractIdNLstPartnerContractDetails  = getContracts(quoteId);
        mapPartnerContractDetailIdNLstPartnerContractServices = getContractService(quoteId); 
        lstPartnerContract = Quote_PartnerQuoteUtil.getContracts(quoteId);             
    }
    
    @AuraEnabled
    public static Partner_Quote__c getQuote(Id quoteId){
        return Quote_PartnerQuoteUtil.getQuote(quoteId);
    }
    
    @AuraEnabled
    public static List<Partner_Quote__c> getQuotes(Id opportunityId){
        return Quote_PartnerQuoteUtil.getQuotes(opportunityId);
    }
        
    @AuraEnabled
    public static List<Partner_Quote_Line__c> getQuoteLines(Id quoteId){
        return Quote_PartnerQuoteUtil.getQuoteLinesForOutput(quoteId);
    }
	
	 //Translation Start

     @AuraEnabled
     public static CommunityInfo.Translationswrap getTranslations(String objNames)
     {    
         
         return CommunityInfo.getTranslations(objNames);
     }
     //Translation End
    
    //<T1>***********
    public static Map<Id,List<Partner_Contract_Detail__c>> getContracts(Id quoteId){        
        for(Partner_Contract__c pc : Quote_PartnerQuoteUtil.getContracts(quoteId))
        {
            if(pc.Partner_Contract_Details__r != null && pc.Partner_Contract_Details__r.size() > 0)
            {
                mapPartnerContractIdNLstPartnerContractDetails.put(pc.Id,pc.Partner_Contract_Details__r);
            }
           sizeOfMap = mapPartnerContractIdNLstPartnerContractDetails.size();
        }
        return mapPartnerContractIdNLstPartnerContractDetails;
    }
    //</T1>***********
     //<T1>***********
    public static Map<Id,List<Partner_Contract_Service__c>> getContractService(Id quoteId){
        for(Partner_Contract_Service__c pcs : Quote_PartnerQuoteUtil.getContractService(quoteId))
        {
            if(mapPartnerContractDetailIdNLstPartnerContractServices.containskey(pcs.Partner_Contract_Detail__c))
            {
                mapPartnerContractDetailIdNLstPartnerContractServices.get(pcs.Partner_Contract_Detail__c).add(pcs);
            }
            else
            {
                mapPartnerContractDetailIdNLstPartnerContractServices.put(pcs.Partner_Contract_Detail__c, new List<Partner_Contract_Service__c>{pcs});
            } 
        }
        return mapPartnerContractDetailIdNLstPartnerContractServices;
    }
    //</T1>***********
    @AuraEnabled
    public static void deleteQuote(Id quoteId){
        Quote_PartnerQuoteUtil.deleteQuote(quoteId);
    }
    
    @AuraEnabled
    public static List<Partner_Quote__c> updateQuotes(Id opportunityId, List<Partner_Quote__c> listOfQuotes){
        update listOfQuotes;
        return Quote_PartnerQuoteUtil.getQuotes(opportunityId);
    }
    
    @AuraEnabled public static List<Partner_Quote_Line__c> deleteQuoteLine(Id quoteId, Id quoteLineId){
        Partner_Quote_Line__c objQLToDelete = new Partner_Quote_Line__c(id = quoteLineId);
        delete objQLToDelete;
        return Quote_PartnerQuoteUtil.getQuoteLines(quoteId);
    }
    
    @AuraEnabled
    public static void updateQuoteLines(String quoteLines){
        List<Partner_Quote_Line__c> listOfQuoteLines = (List<Partner_Quote_Line__c>)JSON.deserialize(quoteLines, List<Partner_Quote_Line__c>.class);
        if(!listOfQuoteLines.isEmpty()){
            upsert listOfQuoteLines;
            Partner_Quote__c objQuote = new Partner_Quote__c(id = listOfQuoteLines[0].Partner_Quote__c);
            update objQuote;
        }
    }
    
    @AuraEnabled
    public static String updateQuote(Partner_Quote__c objQuote, Boolean doSubmit, Decimal discount, 
                                     String discountDetails, Boolean promotion, Boolean campaign, String promoCode, String discountType){
        try{
            //Added by Ankit Sharma for dynamic queue name based on community..
            String BrandName = 'Avaya Cloud Office';
            if(objQuote.Opportunity__r.Brand_Name__c != null) {
                BrandName = objQuote.Opportunity__r.Brand_Name__c;
            }
            List<Deal_Support__c> objDealSupportList = [Select Id,Promo_Code__c,Campaign__c,Discount__c,Approved_Discount__c,Discount_Details__c,Promotion__c, Discount_Amount__c, Approved_Discount_Amount__c FROM Deal_Support__c WHERE Partner_Quote__c = :objQuote.id AND Type__c='Discount Request' limit 1];
            Boolean isSuperUser = Quote_PartnerQuoteUtil.checkSuperUser();
            if(objDealSupportList != null && !objDealSupportList.isEmpty() && isSuperUser && doSubmit) {
          		String queueName = Quote_PartnerQuoteUtil.getQueueBasedOnCommunity(BrandName,true);
            	String queueId = Quote_PartnerQuoteUtil.getQueueId(queueName);
                Deal_Support__c objDS = objDealSupportList[0];
                objDS.Brand_Name__c = BrandName;
                if(queueId != null) {
                    if(BrandName != 'RingCentral' && BrandName != 'RingCentral Canada' 
                       && BrandName != 'RingCentral UK' && BrandName != 'RingCentral EU' && BrandName != 'RingCentral AU') {
                           objDS.ownerId = queueId;
                       }
                    else {
                        objDS.ownerId = objQuote.Opportunity__r.ownerId;
                    }
                }
                	objDS.Customer_Account__c = objQuote.Opportunity__r.AccountId;
                	//Changed By Ankit Sharma For Partner Account
            		objDS.Partner_Account__c = objQuote.Opportunity__r.Partner_Account__c;
            			
                    objDS.Approval_Status__c = Quote_PartnerQuoteUtil.QUOTE_STATUS_PENDING;
                    objDS.Opportunity__c = objQuote.Opportunity__c;
                    if(discountType == '%'){
                        objDS.Discount__c = discount;
                        objDS.Approved_Discount__c = discount;
                        objDS.Discount_Amount__c = 0;
                        objDS.Approved_Discount_Amount__c = 0;
                    }else if(discountType == 'Amt'){
                        objDS.Discount_Amount__c = discount;
                        objDS.Approved_Discount_Amount__c = discount;
                        objDS.Discount__c = 0;
                        objDS.Approved_Discount__c = 0;
                    }                    
                    objDS.Discount_Details__c = discountDetails;
                    objDS.Promotion__c = promotion;
                    objDS.Campaign__c = campaign;
                    objDS.Promo_Code__c = promoCode;
                    update objDS;
            } 
            else if(doSubmit){
                Deal_Support__c objNewDS = Quote_PartnerQuoteUtil.createDealSupport();
                objNewDS.Discount_Details__c = discountDetails;
                String oppName = Quote_PartnerQuoteUtil.getOpportunity(objQuote.Opportunity__c);
                objNewDS.Name = 'Discount Request - '+oppName;
            	String queueName = Quote_PartnerQuoteUtil.getQueueBasedOnCommunity(BrandName,true);
            	String queueId = Quote_PartnerQuoteUtil.getQueueId(queueName);
                objNewDS.Brand_Name__c = BrandName;
                if(queueId != null) {
                    if(BrandName != 'RingCentral' && BrandName != 'RingCentral Canada' 
                       && BrandName != 'RingCentral UK' && BrandName != 'RingCentral EU' && BrandName != 'RingCentral AU') {
                           objNewDS.ownerId = queueId;
                       }
                    else {
                        objNewDS.ownerId = objQuote.Opportunity__r.ownerId;
                    } 
                }
                objNewDS.Type__c = 'Discount Request';
                objNewDS.Status__c = 'New';
                objNewDS.Sub_Status__c = 'Pending Avaya Approval';
                objNewDS.Partner_Quote__c = objQuote.Id;
                objNewDS.Requested_By__c = UserInfo.getUserId();
                objNewDS.Customer_Account__c = objQuote.Opportunity__r.AccountId;
                //Changed By Ankit Sharma For Partner Account
            	objNewDS.Partner_Account__c = objQuote.Opportunity__r.Partner_Account__c;
            	objNewDS.Approval_Status__c = Quote_PartnerQuoteUtil.QUOTE_STATUS_PENDING;
                objNewDS.Opportunity__c = objQuote.Opportunity__c;
                if(discountType == '%'){
                    objNewDS.Discount__c = discount;
                    objNewDS.Approved_Discount__c = discount;
                    objNewDS.Discount_Amount__c = 0;
                    objNewDS.Approved_Discount_Amount__c = 0;
                }else if(discountType == 'Amt'){
                    objNewDS.Discount_Amount__c = discount;
                    objNewDS.Approved_Discount_Amount__c = discount;
                    objNewDS.Discount__c = 0;
                    objNewDS.Approved_Discount__c = 0;
                }
                objNewDS.Promotion__c = promotion;
                objNewDS.Campaign__c = campaign;
                objNewDS.Promo_Code__c = promoCode;
                
                insert objNewDS;
            
                objQuote.Expiration_Date__c = System.today().addDays(30);
                objQuote.Status__c = 'Pending Approval';
            }
            
            if(objQuote.Start_Date__c != null) {
                objQuote.End_Date__c = Quote_PartnerQuoteUtil.calculateEndDate(objQuote);
            }
            
            update objQuote;
        }
        catch(Exception ex){
            return ex.getMessage();
        }
        return 'Success';
    }
    
    @AuraEnabled
     public static Id addQuoteASFav(Id quoteId, string quoteName){
        Id templateRecordTypeId = Schema.SObjectType.Partner_Quote__c.getRecordTypeInfosByName().get('Quote Template').getRecordTypeId(); 
        Partner_Quote__c objQuote = getQuote(quoteId);
        Partner_Quote__c objClonedQuote = objQuote.clone(false, true, false, false);
        objClonedQuote.Name__c =  quoteName;
        objClonedQuote.User__c = UserInfo.getUserId(); 
        objClonedQuote.RecordTypeId =  templateRecordTypeId;
        objClonedQuote.Primary__c = false;
        insert objClonedQuote;
        
        List<Partner_Quote_Line__c> listOfClonedQuoteLines = new List<Partner_Quote_Line__c>();
        for(Partner_Quote_Line__c eachLine : getQuoteLines(quoteId)){
            Partner_Quote_Line__c objClonedLine = eachLine.clone(false, true, false, false);
            objClonedLine.Partner_Quote__c = objClonedQuote.id;
            listOfClonedQuoteLines.add(objClonedLine);
        }
            
        if(!listOfClonedQuoteLines.isEmpty()) {
            insert listOfClonedQuoteLines;
        }
        return objClonedQuote.id;
    }
    
    @AuraEnabled
    public static AccountCheckListWrapper CheckAccountListExist(String accountId) {
        AccountCheckListWrapper obj = new AccountCheckListWrapper();
     	List<AccountCheckListAddressWrapp> listACAWrapp = new List<AccountCheckListAddressWrapp>();
        Map<String,List<String>> dependentPicklistValuesMap = ControlAndDependentPicklstMap.getDependentPicklistValues(Deal_Registration__c.State__c);
        //Added VAT_Number__c for ACO 3.0
        List<Account_Checklist__c> objAccCheckList =  [SELECT Id,Cost_Center__c,FSC_Comment__c,Legal_Country__c,Legal_City__c,Legal_Company_Name__c, Legal_Physical_Address__c,
                                                       Legal_State__c,Legal_Zip_Code__c,Accounts_Payable_email_address__c,
                                                       (Select Id,Carrier__c,Type__c,Selected_Quantity__c, City__c, Country__c, Shipping_Address__c, State__c,Quantity__c,Product_Catalogue__c, Zip_Code__c,Shipping_Method__c,Shipping_Contact__c,Shipping_Contact_Phone_Number__c FROM Account_Checklist_Addresss__r),taxExemptionCostCenter__c,based__c,State__c,Zip_Code__c, Invoice_Credit_Card__c,Tax_Exemptions__c,POC_Requested__c,Type__c,
                                                    Main_Number_Area_Code__c,MainFaxAreaCode__c,Shipping_Details__c,Area_Code__c,Tax_Exemption_Text__c,VAT_Number__c,Is_Area_Code_Declaration_Checked__c,Main_Area_Code_Country__c,Quantity_Requested__c,Other_Country__c,Payment_Method__c	
                                                    FROM Account_Checklist__c WHERE Account__c = :accountId LIMIT 1];
        system.debug('objAccCheckList--'+objAccCheckList);
        if(objAccCheckList != null && !objAccCheckList.isEmpty()) {
            obj.objACR = objAccCheckList[0];
            List<Account_Checklist_Address__c> listOfACA = objAccCheckList[0].Account_Checklist_Addresss__r;
            if(listOfACA.isEmpty()){
            	listOfACA = new List<Account_Checklist_Address__c>();
                Account_Checklist_Address__c objNew = new Account_Checklist_Address__c();
                listOfACA.add(objNew);
                AccountCheckListAddressWrapp objWrapp = new AccountCheckListAddressWrapp();
                objWrapp.acrRec = new Account_Checklist_Address__c(Country__c = DEFAULT_COUNTRY_VALUE);
                if(dependentPicklistValuesMap.containsKey(DEFAULT_COUNTRY_VALUE)) {
                    objWrapp.shippingStateList = dependentPicklistValuesMap.get(DEFAULT_COUNTRY_VALUE);
                }
                listACAWrapp.add(objWrapp);
            }
            obj.listOfACR = listOfACA;
            for(Account_Checklist_Address__c objAccountAddress : objAccCheckList[0].Account_Checklist_Addresss__r) {
                AccountCheckListAddressWrapp objWrapp = new AccountCheckListAddressWrapp();
                objWrapp.acrRec = objAccountAddress;
                if(dependentPicklistValuesMap.containsKey(objAccountAddress.country__c)) {
                    objWrapp.shippingStateList = dependentPicklistValuesMap.get(objAccountAddress.country__c);
                }
                
                listACAWrapp.add(objWrapp);
            }
            
            obj.listOfACRWrapp = listACAWrapp;
            return obj;
        }
        else {
            Account_Checklist__c objAccountCheckRec = new Account_Checklist__c(Legal_Country__c = DEFAULT_COUNTRY_VALUE);
            List<Account_Checklist_Address__c> listOfACA = new List<Account_Checklist_Address__c>();
            if(listOfACA.isEmpty()){
            	listOfACA = new List<Account_Checklist_Address__c>();
                Account_Checklist_Address__c objNew = new Account_Checklist_Address__c(Selected_Quantity__c = '0');  
                listOfACA.add(objNew);
           	}
            AccountCheckListAddressWrapp objWrapp = new AccountCheckListAddressWrapp();
            objWrapp.acrRec = new Account_Checklist_Address__c(Country__c = DEFAULT_COUNTRY_VALUE,Selected_Quantity__c = '0');
            if(dependentPicklistValuesMap.containsKey(DEFAULT_COUNTRY_VALUE)) {
                objWrapp.shippingStateList = dependentPicklistValuesMap.get(DEFAULT_COUNTRY_VALUE);
            }
            
            listACAWrapp.add(objWrapp);
            obj.objACR = objAccountCheckRec;
            obj.listOfACR = listOfACA;
            obj.listOfACRWrapp = listACAWrapp;
        }
        return obj;
    }
    
    @AuraEnabled
    public static QuoteLineWithPriceWrapper getQuoteLinesWithCalculation(Id quoteId){
        List<QuoteLineWrapper> listOfQuoteLineWrappList = new List<QuoteLineWrapper>();
        Decimal totalPriceTotal = 0;
        Decimal effectivePrice = 0;
        Decimal oldTotalPriceTotal = 0;
        Decimal oldEffectivePrice = 0;
        Decimal oneTimeTotal = 0;
        Decimal reccuringTotal = 0;
        Boolean isFromSubscription = false;
        for(Partner_Quote_Line__c eachQuoteLine : Quote_PartnerQuoteUtil.getQuoteLinesForOutput(quoteId)){
            decimal listPrice = eachQuoteLine.List_Price__c;
            decimal discount = eachQuoteLine.Discount_Number__c;
            string discountType = eachQuoteLine.Discount_Type__c;
            QuoteLineWrapper obj = new QuoteLineWrapper();
            String packageProductType = eachQuoteLine.Product_Catalogue__r.Package_Product_Type__c;
            obj.isHeaderProduct = false;
            if(packageProductType != null && packageProductType.contains('Header')){
                obj.isHeaderProduct = true;
            }
            obj.productName = eachQuoteLine.Product_Catalogue__r.Display_Name__c;
            if(discount > 0 && discountType == '%'){
                effectivePrice = listPrice - ((listPrice * discount) / 100);
            }else if(discount > 0 && discountType == 'Amt'){
                effectivePrice = listPrice - discount;
            }
            else{
                effectivePrice = listPrice;
            }
            
            if(eachQuoteLine.Product_Catalogue__r.plan__c == 'One - Time') {
                oneTimeTotal += eachQuoteLine.Total_Price__c == null ? 0 : eachQuoteLine.Total_Price__c;
            }
            else {
                reccuringTotal += eachQuoteLine.Total_Price__c == null ? 0 : eachQuoteLine.Total_Price__c;
            }
            
			eachQuoteLine.Effective_Price__c = effectivePrice;
            Decimal totalPrice = 0;
            if(eachQuoteLine != null && eachQuoteLine.Quantity__c != null && effectivePrice != null) {
            	totalPrice = effectivePrice * eachQuoteLine.Quantity__c;
            }
            obj.quoteLine = eachQuoteLine; 
            obj.priceChange = 0;
               obj.quantityStatus = 'Error'; 
            listOfQuoteLineWrappList.add(obj);
            totalPriceTotal += totalPrice;
        }
        
        QuoteLineWithPriceWrapper obj = new QuoteLineWithPriceWrapper();
        obj.objQuoteWrap = listOfQuoteLineWrappList;
        obj.totalPrice = totalPriceTotal;
        obj.isFromSubscription = isFromSubscription;
        obj.changedTotalPrice = oldTotalPriceTotal;
        if(oneTimeTotal > 0) {
        	obj.oneTimeTotal =  oneTimeTotal;
        } else {
            obj.oneTimeTotal = 0;
        }
        if(reccuringTotal > 0) {
        	obj.reccuringTotal = reccuringTotal;
        } else {
           obj.reccuringTotal = 0;
        } 
        return obj;
    }
    
    @AuraEnabled
    public static UserDetailWrapper checkSuperUser(String quoteId) {
        UserDetailWrapper obj = new UserDetailWrapper();
        obj.isSuperUser = Quote_PartnerQuoteUtil.checkSuperUser();
        obj.objDealSupport = null;
        obj.isOpenContractRequest = false;
        List<Deal_Support__c> objDealSupportList = [Select Id,Type__c,Status__c,Discount_Details__c,Discount__c,Approved_Discount__c,Promotion__c,Campaign__c,Promo_Code__c, Discount_Amount__c, Approved_Discount_Amount__c 
                                                    FROM Deal_Support__c WHERE Partner_Quote__c = :quoteId and (Type__c = 'Discount Request' or Type__c = 'New Contract Request' 
                                                                                                                or Type__c = 'POC Request') ORDER BY CreatedDate DESC];
        if(objDealSupportList != null && !objDealSupportList.isEmpty()) {
            for(Deal_Support__c objDealSupport : objDealSupportList) {
                if(objDealSupport.Type__c == 'Discount Request'){  
                    obj.objDealSupport = objDealSupportList[0];
                }
                if(objDealSupport.Type__c == 'New Contract Request' && objDealSupport.Status__c != 'Closed-Approved'){  
                    obj.isOpenContractRequest = true;
                }
                if(objDealSupport.Type__c == 'POC Request' && objDealSupport.Status__c != 'Closed-Approved'){  
                    obj.isPOCRequestExists = true;
                }
                if(objDealSupport.Type__c == 'Discount Request' && objDealSupport.Status__c != 'Closed-Approved') {
                    obj.isDiscountRequestExists = true;
                }
            }
        }
        
        List<Partner_Contract__c> objPartnerContractList = [Select Id FROM Partner_Contract__c WHERE Partner_Quote__c = :quoteId limit 1];
        if(objPartnerContractList != null && !objPartnerContractList.isEmpty()) {
            obj.isPartnerContractExist = true;
        } else {
            obj.isPartnerContractExist = false;
        }
        
        
        return obj;
    }
    
    @AuraEnabled
    public static boolean isCommunity(){
        Id siteId = Site.getSiteId(); // take a look at the apex class Site, you may find more useful method concerning site/community
        if (siteId != null) {
            return true;
        }
        return false;
    }
    
    @AuraEnabled
    public static void createPOCRequest(Partner_Quote__c partnerQuoteRecord) {
        update partnerQuoteRecord;
        String BrandName = 'Avaya Cloud Office';
        List<Deal_Support__c> objDealSupportList = [Select Id FROM Deal_Support__c WHERE Partner_Quote__c = :partnerQuoteRecord.Id 
                                                    and Type__c = 'POC Request'];
        
        if(objDealSupportList.isEmpty()) {
            Deal_Support__c objDealSupport= Quote_PartnerQuoteUtil.createDealSupport();
            if(partnerQuoteRecord != null) {
                if(partnerQuoteRecord.Opportunity__r.Brand_Name__c != null) {
           			BrandName = partnerQuoteRecord.Opportunity__r.Brand_Name__c;
                }
        		objDealSupport.Partner_Quote__c = partnerQuoteRecord.Id;
            }
            objDealSupport.Opportunity__c = partnerQuoteRecord.Opportunity__c;
            objDealSupport.Customer_Account__c = partnerQuoteRecord.Opportunity__r.AccountId;
            //Changed By Ankit Sharma For Partner Account
            objDealSupport.Partner_Account__c = partnerQuoteRecord.Opportunity__r.Partner_Account__c;
            objDealSupport.Status__c = 'New';
            objDealSupport.Type__c = 'POC Request';
            String oppName = ''; 
            if(partnerQuoteRecord.Opportunity__c != null) {
            	oppName = Quote_PartnerQuoteUtil.getOpportunity(partnerQuoteRecord.Opportunity__c);
            }
            objDealSupport.Name = 'POC Request - ' + oppName;
          	String queueName = Quote_PartnerQuoteUtil.getQueueBasedOnCommunity(BrandName,true);
            System.debug('queueName>>>'+queueName);
            String queueId = Quote_PartnerQuoteUtil.getQueueId(queueName);
            objDealSupport.Brand_Name__c = BrandName;
            if(queueId != null) {
                if(BrandName != 'RingCentral' && BrandName != 'RingCentral Canada' 
                   && BrandName != 'RingCentral UK' && BrandName != 'RingCentral EU' && BrandName != 'RingCentral AU') {
                       objDealSupport.ownerId = queueId;
                   }
                else {
                    objDealSupport.ownerId = partnerQuoteRecord.Opportunity__r.ownerId;
                } 
            }
            insert objDealSupport;
        }
    }
    
    @auraEnabled
    public static Boolean isValidServiceLineOnQuote(Id quoteId) {
		Boolean isValidQuote = true;
        AggregateResult[] phoneCountResult = [SELECT Sum(Quantity__c)phoneCount FROM Partner_Quote_Line__c WHERE 
                                              Product_Catalogue__r.Category_Name__c = 'Phones' 
                                              AND Partner_Quote__c = :quoteId];
    	Decimal serviceCount = Quote_PartnerQuoteUtil.getServiceCountFromQuote(quoteId);
        
        if ((Decimal)phoneCountResult[0].get('phoneCount') > serviceCount) {
            isValidQuote = false;
        }
        return isValidQuote;
    }
    
    @AuraEnabled
    public static String createDealSprtForEngageProServ(String quoteId,Boolean availProServ,String proServNotes){
        try{
            String brandName = '';
            String idDeal = '';
            Partner_Quote__c partnerQuoteRecord = [select id,name,Opportunity__r.Brand_Name__c,Opportunity__r.AccountId,Opportunity__r.Strategic_Partner_RC_Owner__c,
                                                   Opportunity__r.Partner_Account__c,Opportunity__r.ownerId,Avail_ProServ__c from Partner_Quote__c where id =: quoteId];
            List<Deal_Support__c> objDealSupportList = [Select Id FROM Deal_Support__c WHERE Partner_Quote__c = :partnerQuoteRecord.Id 
                                                        and Type__c = 'Engage ProServ'];
            
            if(objDealSupportList.isEmpty()) {
                Deal_Support__c objDealSupport= Quote_PartnerQuoteUtil.createDealSupport();
                if(partnerQuoteRecord != null) {
                    if(partnerQuoteRecord.Opportunity__r.Brand_Name__c != null) {
                        brandName = partnerQuoteRecord.Opportunity__r.Brand_Name__c;
                    }
                    objDealSupport.Partner_Quote__c = partnerQuoteRecord.Id;
                }
                objDealSupport.Opportunity__c = partnerQuoteRecord.Opportunity__c;
                objDealSupport.Customer_Account__c = partnerQuoteRecord.Opportunity__r.AccountId;
                
                objDealSupport.Partner_Account__c = partnerQuoteRecord.Opportunity__r.Partner_Account__c;
                objDealSupport.Status__c = 'New';
                objDealSupport.Type__c = 'Engage ProServ';
                String oppName = ''; 
                if(partnerQuoteRecord.Opportunity__c != null) {
                    oppName = Quote_PartnerQuoteUtil.getOpportunity(partnerQuoteRecord.Opportunity__c);
                }
                objDealSupport.Name = 'Engage ProServ - ' + oppName;
                objDealSupport.Partner_ProServ_Notes__c = proServNotes;
                String queueName = Quote_PartnerQuoteUtil.getQueueBasedOnCommunity(brandName,true);
                System.debug('queueName>>>'+queueName);
                String queueId = Quote_PartnerQuoteUtil.getQueueId(queueName);
                objDealSupport.Brand_Name__c = brandName;
                if(queueId != null) {
                    if(brandName != 'RingCentral' && brandName != 'RingCentral Canada' 
                       && brandName != 'RingCentral UK' && brandName != 'RingCentral EU' && brandName != 'RingCentral AU') {
                           objDealSupport.ownerId = queueId;
                       }
                    else {
                        objDealSupport.ownerId = partnerQuoteRecord.Opportunity__r.ownerId;
                    } 
                    //objDealSupport.OwnerId = queueId;
                }
                insert objDealSupport;
                idDeal = objDealSupport.Id;
            }
            if(partnerQuoteRecord != null && partnerQuoteRecord.Avail_ProServ__c != availProServ){
                partnerQuoteRecord.Avail_ProServ__c = availProServ;
                update partnerQuoteRecord;
                return 'Success'+ 'Tadaa';
            }
            return 'Success'+idDeal;
        }catch(Exception e){
            System.debug('Exception '+e.getMessage()+' at line '+e.getLineNumber());
            return e.getMessage();    
        }
        
    }
    
    public class QuoteLineWrapper{
        @AuraEnabled public Partner_Quote_Line__c quoteLine {get; private set;}
        @AuraEnabled public Decimal quantityChanged;
		@AuraEnabled public Decimal priceChange;
        @AuraEnabled public String quantityStatus;
        @AuraEnabled public String chargeTerm {get; private set;}
        @AuraEnabled public String productName {get; private set;}
        @AuraEnabled public Boolean isHeaderProduct {get; private set;}
    }
    
    public class QuoteLineWithPriceWrapper{
    	@AuraEnabled public List<QuoteLineWrapper> objQuoteWrap;
        @AuraEnabled public Decimal totalPrice;
		@AuraEnabled public Decimal changedTotalPrice;
        @AuraEnabled public Boolean isFromSubscription;
        @AuraEnabled public Decimal oneTimeTotal {get;set;}
        @AuraEnabled public Decimal reccuringTotal {get;set;}
    }
    
    public class AccountCheckListWrapper{
    	@AuraEnabled public Account_Checklist__c objACR;
        @AuraEnabled public List<Account_Checklist_Address__c> listOfACR;
        @AuraEnabled public List<AccountCheckListAddressWrapp> listOfACRWrapp;
    }
    
    public class AccountCheckListAddressWrapp{
    	@AuraEnabled public Account_Checklist_Address__c acrRec;
        @AuraEnabled public List<String> shippingStateList;
    }
    
    public class UserDetailWrapper{
    	@AuraEnabled public Boolean isSuperUser;
        @AuraEnabled public Deal_Support__c objDealSupport;
        @AuraEnabled public Boolean isPartnerContractExist;
        @AuraEnabled public Boolean isOpenContractRequest;
        @AuraEnabled public Boolean isPOCRequestExists;
        @AuraEnabled public Boolean isDiscountRequestExists;
    }
}