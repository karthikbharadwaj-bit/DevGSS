//Naresh Kumar  10/30/2019
/*
Change History
********************************************************************************************************************
SCRUM/Jira              ModifiedBy      Date        Description                                          Tag
Partner Quote Pdf       Namitha         11/27/2019  Added logic for quote pdf - Partner Contract details T1 
********************************************************************************************************************
*/
Global without sharing class PartnerQuoteController {
    
    public QuotePDFWrapper objPartnerQuotePDF {get;  set;}
    public Partner_Quote__c objPartnerQuote {get;  set;}
    public static Integer sizeOfMap {get;  set;}
    public List<QuoteLineWrapper> listOfQuoteLines {get; private set;}     
    public static Map<Id,List<Partner_Contract_Detail__c>> mapPartnerContractIdNLstPartnerContractDetails {get;set;}
    public static Map<Id,List<Partner_Contract_Service__c>> mapPartnerContractDetailIdNLstPartnerContractServices {get;set;}
    public List<Partner_Contract__c> lstPartnerContract {get;set;}
     
    public PartnerQuoteController(){
        String quoteId = ApexPages.currentPage().getParameters().get('Id');
        sizeOfMap = 0;
        objPartnerQuote = getQuote(quoteId);
        objPartnerQuotePDF = getPDFData(quoteId);
        listOfQuoteLines = new List<QuoteLineWrapper>();
        for(Partner_Quote_Line__c eachLine : getQuoteLines(quoteId)){
            QuoteLineWrapper objNewRecord = new QuoteLineWrapper();
            objNewRecord.quoteLine = eachLine;
            String chargeTerm = '';
          if(eachLine.Product_Catalogue__r.Plan__c == null && objPartnerQuote.Payment_Term__c != null){
                chargeTerm = objPartnerQuote.Payment_Term__c;
                if(objPartnerQuote.Payment_Term__c == 'Monthly' && objPartnerQuote.Contract__c != null && objPartnerQuote.Contract__c){
                  chargeTerm += ' Contract';    
                }
            }  
            objNewRecord.chargeTerm = chargeTerm;
            objNewRecord.productName = eachLine.Product_Catalogue__r.Display_Name__c;
            listOfQuoteLines.add(objNewRecord);
        }
        mapPartnerContractIdNLstPartnerContractDetails  = new Map<Id,List<Partner_Contract_Detail__c>>();
        mapPartnerContractDetailIdNLstPartnerContractServices = new Map<Id,List<Partner_Contract_Service__c>>();
        mapPartnerContractIdNLstPartnerContractDetails  = getContracts(quoteId);
        mapPartnerContractDetailIdNLstPartnerContractServices = getContractService(quoteId); 
        lstPartnerContract = Quote_PartnerQuoteUtil.getContracts(quoteId);             
        String myGeneratedFileName = objPartnerQuote.name +'.pdf';
        Apexpages.currentPage().getHeaders().put('content-disposition', 'attachment; filename='+myGeneratedFilename);
    }
    
    @AuraEnabled
    public static Partner_Quote__c getQuote(Id quoteId){
        return Quote_PartnerQuoteUtil.getQuote(quoteId);
    }
    
    @AuraEnabled
    public static List<Partner_Quote__c> getQuotes(Id opportunityId){
        return Quote_PartnerQuoteUtil.getQuotes(opportunityId);
    }
    
    //Translation Start
    @AuraEnabled
    public static CommunityInfo.Translationswrap getTranslations(String objNames)
    {        
        return CommunityInfo.getTranslations(objNames);
    }    
    //Translation End
        
    @AuraEnabled
    public static List<Partner_Quote_Line__c> getQuoteLines(Id quoteId){
        return Quote_PartnerQuoteUtil.getQuoteLinesForOutput(quoteId);
    }
    
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
    public static String updateQuote(Partner_Quote__c objQuote, Boolean doSubmit, String discountDetails){
        try{
            String partnerDiscountApproval = [SELECT Partner_Discount_Approval__c FROM User WHERE Id = :UserInfo.getUserId()].Partner_Discount_Approval__c;
            
            Deal_Support__c objNewDS = Quote_PartnerQuoteUtil.createDealSupport();
            objNewDS.Discount_Details__c = discountDetails;
            objNewDS.Partner_Quote__c = objQuote.Id;
            objNewDS.Requested_By__c = UserInfo.getUserId();
            objNewDS.Customer_Account__c = objQuote.Opportunity__r.AccountId;
            objNewDS.Approval_Status__c = Quote_PartnerQuoteUtil.QUOTE_STATUS_PENDING;
            if(doSubmit){
                String dsType;
                List<Group> objQueue;
                if(partnerDiscountApproval == null || partnerDiscountApproval == Quote_PartnerQuoteUtil.NONE_APPROVAL){
                  objQuote.Status__c = Quote_PartnerQuoteUtil.QUOTE_STATUS_PENDING_L1_APPROVAL;
                    objQueue = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName =: Quote_PartnerQuoteUtil.QUOTE_L1_APPROVAL_QUEUE];
                    dsType = Quote_PartnerQuoteUtil.DS_TYPE_L1_APPROVAL;
                }
                else if(partnerDiscountApproval == Quote_PartnerQuoteUtil.L1_APPROVAL){
                  objQuote.Status__c = Quote_PartnerQuoteUtil.QUOTE_STATUS_PENDING_L2_APPROVAL;
                    objQueue = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName =: Quote_PartnerQuoteUtil.QUOTE_L2_APPROVAL_QUEUE];
                    dsType = Quote_PartnerQuoteUtil.DS_TYPE_L2_APPROVAL;
                }
                if(objQueue != null && !objQueue.isEmpty()) {
                  objNewDS.OwnerId = objQueue[0].Id;
                }
                objNewDS.Type__c = dsType;
                insert objNewDS;    
            }
            update objQuote;
        }
        catch(Exception ex){
            return ex.getMessage();
        }
        return 'Success';
    }
    
    @AuraEnabled
    public static Partner_Quote__c createPartnerQuoteForUpsell(String accID) {
        List<Subscription__c> listOfSubscription = new List<Subscription__c>();
        Partner_Quote__c partnerQuoteRec;
        listOfSubscription =  [SELECT Id, Account__c, Active__c FROM Subscription__c WHERE Account__c = :accID and Active__c = true ];
        
       return partnerQuoteRec; 
    }
    
    @AuraEnabled
     public static Id addQuoteASFav(Id quoteId, string quoteName){
        Id templateRecordTypeId = Schema.SObjectType.Partner_Quote__c.getRecordTypeInfosByName().get('Quote Template').getRecordTypeId(); 
        Partner_Quote__c objQuote = getQuote(quoteId);
        Partner_Quote__c objClonedQuote = objQuote.clone(false, true, false, false);
        objClonedQuote.Name__c =  quoteName;
        objClonedQuote.User__c = UserInfo.getUserId(); 
        objClonedQuote.RecordTypeId =  templateRecordTypeId;
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
    public static Account_Checklist__c CheckAccountListExist(String accountId) {
        Account_Checklist__c obj = new Account_Checklist__c();
       List<Account_Checklist__c> objAccCheckList =  [SELECT Id,taxExemptionCostCenter__c,based__c,State__c,Zip_Code__c, Invoice_Credit_Card__c,Tax_Exemptions__c,POC_Requested__c,Type__c,
                                                    Main_Number_Area_Code__c,MainFaxAreaCode__c,Shipping_Details__c,Area_Code__c
                                                    FROM Account_Checklist__c WHERE Account__c = :accountId LIMIT 1];
       if(!objAccCheckList.isEmpty()) {
          return objAccCheckList[0];
       }
        return obj;
    }    
    //Added method for PBC-11030
    @AuraEnabled
    public static Quote_PartnerDetailController.AccountCheckListWrapper checkPartnerQuoteExistFORAccount(String accID) {
        Quote_PartnerDetailController.AccountCheckListWrapper obj = Quote_PartnerDetailController.CheckAccountListExist(accID);
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
            Decimal totalPrice = effectivePrice * eachQuoteLine.Quantity__c;
            eachQuoteLine.Total_Price__c = totalPrice;
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
    
    public static QuotePDFWrapper getPDFData(String quoteId) {
        QuotePDFWrapper objWrapp = new QuotePDFWrapper();
        Partner_Quote__c objPartnerQuote = getQuote(quoteId);
        objWrapp.quoteRec = objPartnerQuote;
        Decimal oneTimeTotal = 0;
        Decimal reccuringTotal = 0;
        For(Partner_Quote_line__c eachLine : objPartnerQuote.Partner_Quote_Products__r) {
            if(eachLine.Product_Catalogue__r.plan__c == 'One - Time') {
                oneTimeTotal += eachLine.Total_Price__c == null ? 0 : eachLine.Total_Price__c;
            }
            else {
                reccuringTotal +=  eachLine.Total_Price__c == null ? 0 : eachLine.Total_Price__c;
            }
        }
        objWrapp.oneTimeTotal = oneTimeTotal;
        objWrapp.reccuringTotal = reccuringTotal ;
        return objWrapp;
    }
    
    @AuraEnabled
    public static POCRequestWrapper checkPOCRequestExist(String oppId) {
        Boolean isSuperUser = Quote_PartnerQuoteUtil.checkSuperUser();
        String BrandName = 'Avaya Cloud Office';
        Opportunity oppRec = [SELECT Id, Name,ownerId,AccountId,Partner_Account__c,Brand_Name__c,Account.Type_of_Customer_or_Prospect__c FROM Opportunity WHERE Id =: oppId ];//added Type_of_Customer_or_Prospect__c for mitel in query.
        if(oppRec.Brand_Name__c != null) {
            BrandName = oppRec.Brand_Name__c;
        }
        List<Deal_Support__c> objDealSupportList = [Select Id,Type__c,Phone_and_Shippment__c,Phone_type__c,Main_Area_Code__c,Edition__c,Number_of_User__c,POC_Term__c,Comment__c,Status__c,Discount_Details__c,Discount__c,Approved_Discount__c,Promotion__c,Campaign__c,Promo_Code__c, Discount_Amount__c, Approved_Discount_Amount__c 
                                                    FROM Deal_Support__c WHERE Opportunity__c = :oppId and (Type__c = 'POC Request')];
        POCRequestWrapper obj = new POCRequestWrapper();
		//added for mitel starts(PBC-10625)
        User currentUser = QuotePlanAndPricingController.getCurrentUserInfo();
        if(currentUser.Contact.Account.Partner_ID__c!=null && currentUser.Contact.Account.Partner_ID__c == '120292' && oppRec.Account.Type_of_Customer_or_Prospect__c !=null && oppRec.Account.Type_of_Customer_or_Prospect__c == 'Existing Cloud Customer'){
            obj.isMitelContact=true;
        }
        if(currentUser.Contact.Account.Partner_Account__r.Partner_ID__c!=null && currentUser.Contact.Account.Partner_Account__r.Partner_ID__c == '120292' && oppRec.Account.Type_of_Customer_or_Prospect__c !=null && oppRec.Account.Type_of_Customer_or_Prospect__c == 'Existing Cloud Customer'){
            obj.isMitelContact=true;
        }
        //added for mitel ends
        obj.isInternalRc = false;
        if(BrandName == 'RingCentral' || BrandName == 'RingCentral Canada' 
           || BrandName == 'RingCentral UK' || BrandName == 'RingCentral EU' || BrandName == 'RingCentral AU') {
               obj.isInternalRc = true;  
           }
        List<GroupMember> gpMemberList = [SELECT Group.Name FROM GroupMember WHERE 
                                                UserOrGroupId = :oppRec.OwnerId 
                                                AND Group.Type = 'Queue'
                                                AND Group.Name = 'Internal RC Create Quote Access'];
        obj.isOppOwnerExistInQueue = false;
        if(gpMemberList != null && gpMemberList.size() > 0) {
            obj.isOppOwnerExistInQueue = true;
        }
        
        obj.isSuperUser = Quote_PartnerQuoteUtil.checkSuperUser();
        if(objDealSupportList != null && !objDealSupportList.isEmpty()) {
            obj.objDealSupport = objDealSupportList[0];
        } else{
            obj.objDealSupport = null;
        }
        return obj;
    }
    
    
    
    @AuraEnabled
    public static void createPOCRequest(Deal_Support__c dealSupportRecord,String opportunityId) {
        String BrandName = 'Avaya Cloud Office';
        if(dealSupportRecord != null && dealSupportRecord.id == null) {
            Deal_Support__c objDealSupport= Quote_PartnerQuoteUtil.createDealSupport();
            objDealSupport.Opportunity__c = opportunityId;
            objDealSupport.Number_of_User__c = dealSupportRecord.Number_of_User__c;
            objDealSupport.Main_Area_Code__c = dealSupportRecord.Main_Area_Code__c;
            objDealSupport.Phone_type__c = dealSupportRecord.Phone_type__c;

            objDealSupport.Edition__c = dealSupportRecord.Edition__c;
            objDealSupport.Phone_and_Shippment__c = dealSupportRecord.Phone_and_Shippment__c;
            objDealSupport.Comment__c = dealSupportRecord.Comment__c;
            objDealSupport.POC_Term__c = dealSupportRecord.POC_Term__c;
            objDealSupport.Status__c = 'New';
            objDealSupport.Type__c = 'POC Request';
            Opportunity oppRec = [SELECT Id, Name,ownerId,AccountId,Partner_Account__c,Brand_Name__c FROM Opportunity WHERE Id =: opportunityId ];
            objDealSupport.Customer_Account__c = oppRec.AccountId;
            objDealSupport.Partner_Account__c = oppRec.Partner_Account__c;
            if(oppRec.Brand_Name__c != null ) {
              BrandName = oppRec.Brand_Name__c;
            }
            Integer oppNameLen = oppRec.Name.length();//BZS-10912, BZS-11093
            if(oppNameLen > 66) {
                objDealSupport.Name = 'POC Request - '+oppRec.Name.substring(0,66);//BZS-10912, BZS-11093
            } else {
                objDealSupport.Name = 'POC Request - '+oppRec.Name;//BZS-10912, BZS-11093
            }
            String queueName = Quote_PartnerQuoteUtil.getQueueBasedOnCommunity(BrandName,false);
            String queueId = Quote_PartnerQuoteUtil.getQueueId(queueName);
            objDealSupport.Brand_Name__c = BrandName;
            if(queueId != null) {
                if(BrandName != 'RingCentral' && BrandName != 'RingCentral Canada' 
                   && BrandName != 'RingCentral UK' && BrandName != 'RingCentral EU' && BrandName != 'RingCentral AU') {
                       objDealSupport.ownerId = queueId;
                   }
                else {
                    objDealSupport.ownerId = oppRec.ownerId;
                }
            }
            insert objDealSupport;
        } else {
            update dealSupportRecord;
        }
    }
    // Added for BZS-9309 - starts wholesale
    @AuraEnabled
    public static List<String> checkAndGetWholesalePartnerPackageEditions(String oppId) {
        Opportunity opp = [Select Partner_Account__c, Partner_Account__r.partner_Type__c from Opportunity where id = :oppId limit 1];
        Id partnerAccountId = opp.Partner_Account__c;
        if(partnerAccountId != null && opp.Partner_Account__r != null && opp.Partner_Account__r.partner_Type__c != null && opp.Partner_Account__r.partner_Type__c.containsIgnoreCase('Wholesale-Reseller')) {
            List<Wholesale_Partner_Package__c> wholesalePartnerPckgList = [SELECT id, Wholesale_Partner_Account__c, Parent_Product_Package__r.Package_Edition__c FROM Wholesale_Partner_Package__c WHERE Wholesale_Partner_Account__c = :partnerAccountId];

            Set<String> partnerPackageEditions = new Set<String>();
            for (Wholesale_Partner_Package__c wPackage : wholesalePartnerPckgList) {
                if (wPackage.Parent_Product_Package__r != null && (wPackage.Parent_Product_Package__r.Package_Edition__c != null || wPackage.Parent_Product_Package__r.Package_Edition__c != '')) {
                    partnerPackageEditions.add(wPackage.Parent_Product_Package__r.Package_Edition__c);
                }
            }
            return new List<String>(partnerPackageEditions);
        }
        return null;
    }
    webservice static Id getProductPackgeId(string BrandName, string PackageName, String currencyIsoCode){
        Id packageId;
        try{
            List<Product_Package__c> allpackagesList=[SELECT id, Name, Description__c,(SELECT Id,Description__c,Contract_Discount__c, Monthly_Price__c, Yearly_Price__c, No_of_Licenses__c 
                                                   FROM Product_Tier_Prices__r WHERE CurrencyIsoCode = :currencyIsoCode ORDER BY No_of_Licenses__c), Price__c, CurrencyISOCode,Monthly_Packgage_Info__c,
                                                   Product_Categories__c
                                                   FROM Product_Package__c WHERE Active__c = true And Brand_Name__c = :BrandName And Name =:PackageName];
            for(Product_Package__c pkg : allpackagesList){
                 if(pkg.Product_Tier_Prices__r.isEmpty()){
                    continue;
                 }
                packageId = pkg.Id;
            }
            return packageId;
        }catch(Exception e){
            return packageId;
        }
    }
    // Added for BZS-9309 - ends -wholesale
    public class QuoteLineWrapper{
        @AuraEnabled public Partner_Quote_Line__c quoteLine {get; private set;}
        @AuraEnabled public Decimal quantityChanged;
    @AuraEnabled public Decimal priceChange;
        @AuraEnabled public String quantityStatus;
        @AuraEnabled public String chargeTerm {get; private set;}
        @AuraEnabled public String productName {get; private set;}
    }
    public class QuoteLineWithPriceWrapper{
      @AuraEnabled public List<QuoteLineWrapper> objQuoteWrap;
        @AuraEnabled public Decimal totalPrice;
    @AuraEnabled public Decimal changedTotalPrice;
        @AuraEnabled public Boolean isFromSubscription;
        @AuraEnabled public Decimal oneTimeTotal {get;set;}
        @AuraEnabled public Decimal reccuringTotal {get;set;}
    }
    
    public class QuotePDFWrapper{
        public Partner_Quote__c quoteRec {get;set;}
        public Decimal oneTimeTotal {get;set;}
        public Decimal reccuringTotal {get;set;}
  }
    
    public class POCRequestWrapper{
      @AuraEnabled public Boolean isSuperUser;
        @AuraEnabled public Deal_Support__c objDealSupport;
        @AuraEnabled public Boolean isInternalRc;
        @AuraEnabled public Boolean isOppOwnerExistInQueue;
		@AuraEnabled public Boolean isMitelContact;//added for mitel pbc-10625
    }
    
}