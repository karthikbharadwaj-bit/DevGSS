/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 03-11-2021
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
 * Modifications Log 
 * Ver   Date         Author                               Modification
 * 1.0   03-11-2021   ChangeMeIn@UserSettingsUnder.SFDoc   Initial Version
**/
public with sharing class DealQuoteInfoController { 

    private static final String[] specialTermExcludeArr = new String[]{'2-day Shipping for Ground Pricing', 'Free shipping'};

    @AuraEnabled(cacheable=true)
    public static DealQuoteInfoWrappper initDealQuoteInfo(){
        try {
            DealQuoteInfoWrappper dealQuoteInforWrapperInstance = new DealQuoteInfoWrappper();
            dealQuoteInforWrapperInstance.listOfDealQuoteBasePrice = DealQuoteCalculatorUtil.getDealQuotingToolBase();
            dealQuoteInforWrapperInstance.listOfDealQuoteListPrice = DealQuoteCalculatorUtil.getDealQuotingToolListPrice();
            dealQuoteInforWrapperInstance.listOfDealQuoteContactCenterPotential = DealQuoteCalculatorUtil.getDealQuotingContactCenterPotential();
            dealQuoteInforWrapperInstance.listOfDealQuoteFreeMonthDiscount = DealQuoteCalculatorUtil.getDealQuotingFreeMonthDiscount();
            dealQuoteInforWrapperInstance.listOfDealQuoteFeeAndE991 = DealQuoteCalculatorUtil.getDealQuotingFeeAndE911();
            dealQuoteInforWrapperInstance.listOfDealQuoteInitialTerm = DealQuoteCalculatorUtil.getDealQuotingInitialTerm();
            dealQuoteInforWrapperInstance.listOfDealQuoteIntercept = DealQuoteCalculatorUtil.getDealQuotingIntercept();
            dealQuoteInforWrapperInstance.listOfDealQuoteLogAcv = DealQuoteCalculatorUtil.getDealQuotingLogAcv();
            dealQuoteInforWrapperInstance.listOfDealQuoteOrderYear = DealQuoteCalculatorUtil.getDealQuotingOrderYear();
            dealQuoteInforWrapperInstance.listOfDealQuotePaymentPlan = DealQuoteCalculatorUtil.getDealQuotingPaymentPlan();
            dealQuoteInforWrapperInstance.listOfDealQuotePotentialSeat = DealQuoteCalculatorUtil.getDealQuotingPotentialSeat();
            dealQuoteInforWrapperInstance.listOfDealQuoteSector = DealQuoteCalculatorUtil.getDealQuotingSector();
            dealQuoteInforWrapperInstance.listOfDealQuoteFeature = DealQuoteCalculatorUtil.getDealQuotingFeature();

            return dealQuoteInforWrapperInstance;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

	@AuraEnabled
	public static DealQuoteDetailWrapper refreshValueFromQuote(String dealQuoteInfoId, String quoteId){
		try {
			if (String.isNotBlank(quoteId)) {
				return dealQuoteInfoByQuoteId(quoteId, dealQuoteInfoId);
			}  

		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
		return null;
	}
 
    
    @AuraEnabled
    public static Opportunity getOpportunityDetail(String opportunityId) {
        if (String.isNotEmpty(opportunityId)) {
            List<Opportunity> listOfOpportunity = DealQuoteCalculatorUtil.getOpportunityByOppId(new List<String> {opportunityId});
            if (!listOfOpportunity.isEmpty()) {
                return listOfOpportunity.get(0);
            }
        }
        return null;
    }

    @AuraEnabled
    public static Quote getQuoteInfoById(String quoteId){
        try {
            List<Quote> listOfQuote = DealQuoteCalculatorUtil.getQuoteDetailByListOfIds(new List<String> {quoteId});
            if (!listOfQuote.isEmpty()) {
                return listOfQuote.get(0);
            }
            return null;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static DealQuoteDetailWrapper getDealQuotingInfoById(String dealQuoteInfoId){
        //try {
            if (Id.valueOf(dealQuoteInfoId).getSObjectType() == Opportunity.sObjectType) {
				DealQuoteDetailWrapper dealQuotInfoWrapper = dealQuoteInfoByObjectOpportunityInstance(dealQuoteInfoId);
				String recordId = null;
				if (dealQuotInfoWrapper.dealQuoteInfo != null) {
					upsert dealQuotInfoWrapper.dealQuoteInfo;
					recordId = dealQuotInfoWrapper.dealQuoteInfo.Id;
				}

				if (recordId != null) {
					dealQuotInfoWrapper.dealQuoteInfo.Id = recordId;
				}
				System.debug('dealQuotInfoWrapper.dealQuoteInfo>>> ' + dealQuotInfoWrapper.dealQuoteInfo.Id);
                return dealQuotInfoWrapper;
            }
            else {
                List<Deal_Quoting_Info__c> listOfDealQuotingInfo = DealQuoteCalculatorUtil.getDealQuotingInfoByRecordId(dealQuoteInfoId);
                if (!listOfDealQuotingInfo.isEmpty()) {
                    DealQuoteDetailWrapper dealQuoteWrapper = new DealQuoteDetailWrapper();
                    dealQuoteWrapper.dealQuoteInfo = listOfDealQuotingInfo.get(0);
                    return dealQuoteWrapper;
                }
            }
            
        // } catch (Exception e) {
        //  throw new AuraHandledException(e.getMessage());
        // }
         return null;
    }

    private static Deal_Quoting_Info__c  initializeDealQuoteInfo() {
        Deal_Quoting_Info__c dealQuoteInfoObj = new Deal_Quoting_Info__c();
        dealQuoteInfoObj.Sales_Agreement__c = null;
        dealQuoteInfoObj.Opportunity__c = null;
        dealQuoteInfoObj.Tier__c = '';
        dealQuoteInfoObj.Number_of_Unlimited_DLs__c = 0.0;
        dealQuoteInfoObj.Number_of_Limited_Exts__c = 0.0;
        dealQuoteInfoObj.Undiscounted_Unit_Price_for_Limited_Exts__c = 0.0;
        dealQuoteInfoObj.Contract_Length_Years__c = '';
        dealQuoteInfoObj.Payment_Plan__c = '';
        dealQuoteInfoObj.Monthly_total_for_ProServ_Enterprise__c =0.0;
        dealQuoteInfoObj.Monthly_total_for_Contact_Center__c =0.0;
        dealQuoteInfoObj.Monthly_total_for_phone_rentals__c =0.0;
        dealQuoteInfoObj.Monthly_total_for_all_other_recurring_ch__c =0.0;
        dealQuoteInfoObj.Sector__c = '';
        dealQuoteInfoObj.Total_Number_of_Employees__c =0.0;
        dealQuoteInfoObj.Potential_to_sell_contact_center_in_near__c = '';
        dealQuoteInfoObj.Features__c = '';
        dealQuoteInfoObj.Free_Months_Given__c = 0.0;
        dealQuoteInfoObj.Per_Unlimited_DL_advertised__c = 0.0;
        dealQuoteInfoObj.Total_for_Unlimited_DLs_advertised__c =0.0;
        dealQuoteInfoObj.Per_Limited_Extension_advertised__c = 0.0;
        dealQuoteInfoObj.Total_for_Limited_Extensions_advertised__c = 0.0;
        dealQuoteInfoObj.Recommended_price_per_Unlimited_DL_after__c = 0.0;
        dealQuoteInfoObj.Recommended_Unlimited_DLs_price_after_di__c = 0.0;
        dealQuoteInfoObj.Recommended_price_per_Limited_Extension__c =0.0;
        dealQuoteInfoObj.Recommended_Limited_Extensions_price_aft__c = 0.0;
        dealQuoteInfoObj.Recommended_Discount_vs_list__c = 0.0;
        dealQuoteInfoObj.Final_quote_price_per_Unlimited_DL__c = 0.0;
        dealQuoteInfoObj.Final_quote_price_for_Unlimited_DLs__c = 0.0;
        dealQuoteInfoObj.Final_quote_price_per_Limited_Extension__c = 0.0;
        dealQuoteInfoObj.Final_quote_price_for_Limited_Extensions__c = 0.0;
        dealQuoteInfoObj.Final_discount_vs_list__c =0.0;
        dealQuoteInfoObj.Final_discount_vs_list_percent__c = 0.0;
        dealQuoteInfoObj.Deal_discretion_for_Unlimited_DLs__c = 0.0;
        dealQuoteInfoObj.Deal_discretion_for_Unlimited_DLs_Per__c = 0.0;
        dealQuoteInfoObj.Discretion_vs_target_price__c = 0.0;
        dealQuoteInfoObj.Approval_Needed_for_Unlimited_DLs__c = '';
        dealQuoteInfoObj.Approval_Different_from_GoA__c = '';
		dealQuoteInfoObj.Undiscounted_Unit_Price_for_additional_l__c = 0.00;
		dealQuoteInfoObj.Number_of_additional_local_number_incl__c = 0;
        return dealQuoteInfoObj;
    }

	private static DealQuoteDetailWrapper dealQuoteInfoByQuoteId(String quoteId, String dealQuoteInfoId) {
		return intializeDealQuoteInfoByQuoteInfo(DealQuoteCalculatorUtil.getQuoteDetailByListOfIds(new List<String> {quoteId}),dealQuoteInfoId );
	}

	private static DealQuoteDetailWrapper intializeDealQuoteInfoByQuoteInfo(List<Quote> listOfQuotes, String dealQuoteInfoId) {
		DealQuoteDetailWrapper dealQuoteWrapper = new DealQuoteDetailWrapper();
        Deal_Quoting_Info__c dealQuoteInfoObj = initializeDealQuoteInfo();
		if (String.isNotBlank(dealQuoteInfoId)) {
			List<Deal_Quoting_Info__c> listOfDealQuoteInfo =  DealQuoteCalculatorUtil.getDealQuotingInfoByRecordId(dealQuoteInfoId);
			if (!listOfDealQuoteInfo.isEmpty()) {
				dealQuoteInfoObj = listOfDealQuoteInfo.get(0);
			}
		} 
        if (!listOfQuotes.isEmpty()) {
            Quote quoteRecord = listOfQuotes.get(0);
            dealQuoteInfoObj.Opportunity__c = quoteRecord.OpportunityId;
            dealQuoteInfoObj.Sales_Agreement__c = quoteRecord.Id;
            dealQuoteInfoObj.Payment_Plan__c = quoteRecord.Payment_Plan__c;
            if (quoteRecord.Package_Info__c != null) {
                List<Quote_QuoteJSONParent> objWrappList = (List<Quote_QuoteJSONParent>)System.JSON.deserialize(quoteRecord.Package_Info__c , List<Quote_QuoteJSONParent>.class);
                dealQuoteInfoObj.Tier__c = objWrappList[0].edition != null ? objWrappList[0].edition.Name : null;
            } else {
                dealQuoteInfoObj.Tier__c = '';
            }

            if (quoteRecord.Special_Terms__c != null) {
                if (specialTermExcludeArr.indexOf(quoteRecord.Special_Terms__c) == -1) {
                    String specialTerm = quoteRecord.Special_Terms__c.substring(0, 1);
                    dealQuoteInfoObj.Total_Number_of_Employees__c = Integer.valueOf(specialTerm);
                }
            } else {
                dealQuoteInfoObj.Total_Number_of_Employees__c = 0;
            }
            
            if (quoteRecord.Initial_Term_months__c != null) {
                dealQuoteInfoObj.Contract_Length_Years__c = (Integer.valueOf(quoteRecord.Initial_Term_months__c) / 12) + '';
            } else {
                dealQuoteInfoObj.Contract_Length_Years__c = '';
            }
            
            dealQuoteInfoObj.Total_Number_of_Employees__c = quoteRecord.Total_Number_of_Digital_Lines__c;
            
            if (!quoteRecord.quoteLineItems.isEmpty()) {
                for (QuoteLineItem eachQuoteLine : quoteRecord.quoteLineItems) {
                    if (eachQuoteLine.Product2Id != null &&  eachQuoteLine.Product2.Name.indexOf('DigitalLine Unlimited') != -1) {
                        dealQuoteInfoObj.Number_of_Unlimited_DLs__c = eachQuoteLine.Quantity;
						System.debug('eachQuoteLine.UnitPrice>>> ' + eachQuoteLine.UnitPrice);
						if ('Annual'.equalsIgnoreCase(dealQuoteInfoObj.Payment_Plan__c)) {
                            dealQuoteInfoObj.Final_quote_price_per_Unlimited_DL__c = eachQuoteLine.UnitPrice / 12;
                        } else {
                            dealQuoteInfoObj.Final_quote_price_per_Unlimited_DL__c = eachQuoteLine.UnitPrice;
                        }
                    }

                    if (eachQuoteLine.Product2Id != null && eachQuoteLine.Product2.Name.indexOf('DigitalLine Basic') != -1) {
                        dealQuoteInfoObj.Number_of_Limited_Exts__c = eachQuoteLine.Quantity;
                        if ('Annual'.equalsIgnoreCase(dealQuoteInfoObj.Payment_Plan__c)) {
                            dealQuoteInfoObj.Undiscounted_Unit_Price_for_Limited_Exts__c = eachQuoteLine.UnitPrice / 12;
                        } else {
                            dealQuoteInfoObj.Undiscounted_Unit_Price_for_Limited_Exts__c = eachQuoteLine.UnitPrice;
                        }
                    }
                }
            }
            dealQuoteWrapper.salesAgreementInformation = listOfQuotes.get(0);
        }
        dealQuoteWrapper.dealQuoteInfo = dealQuoteInfoObj;
        
        return dealQuoteWrapper;
	}
     
    private static DealQuoteDetailWrapper dealQuoteInfoByObjectOpportunityInstance(String OpportunityId) {
		List<Deal_Quoting_Info__c> listOfDealQuotingInfo = DealQuoteCalculatorUtil.getDealQuotingInfoIdByOpportunityId(OpportunityId);
		String dealQuoteInfoId = null;
		if (!listOfDealQuotingInfo.isEmpty()) {
			dealQuoteInfoId = listOfDealQuotingInfo.get(0).Id;
		}
        return intializeDealQuoteInfoByQuoteInfo(DealQuoteCalculatorUtil.getQuoteDetailByOppId(OpportunityId), dealQuoteInfoId);
    }
 
    @AuraEnabled
    public static string createDealQuoteInfoRecord(String dealQuotingInfo){
        Boolean isSuccess = false;
        Deal_Quoting_Info__c dealQuotingInfoObj = (Deal_Quoting_Info__c) JSON.deserialize(dealQuotingInfo, Deal_Quoting_Info__c.class);
		System.debug('dealQuotingInfoObj<<<<<< ' + dealQuotingInfoObj);
        try {
            List<Deal_Quoting_Info__c> listOfDealQuoteInfos = DealQuoteCalculatorUtil.getDealQuotingInfoByQuoteId(dealQuotingInfoObj.Sales_Agreement__c);
            if (!listOfDealQuoteInfos.isEmpty() && dealQuotingInfoObj.Id == null) {
                dealQuotingInfoObj.Id = listOfDealQuoteInfos.get(0).Id;
            }
            upsert dealQuotingInfoObj;
			System.debug('>>dealQuotingInfoObj.Id>> ' + dealQuotingInfoObj.Id);
            isSuccess = true;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return String.valueOf(isSuccess);
    }

    @AuraEnabled
    public static String acceptRecommendation (String quoteId, String targetPricePercent) {
        String successMsg = 'false';
        List<QuoteLineItem> listOfQuoteLineToUpdate = new List<QuoteLineItem>();

        if (String.isBlank(targetPricePercent)) {
            return 'Recommend percent can not be blank!';
        }

        if (String.isNotBlank(targetPricePercent)) {

            if(Decimal.valueOf(targetPricePercent) < 0) { 
                return 'Recommend discount can not be negative!';
            }

            List<Quote> listOfQuoteInfo = DealQuoteCalculatorUtil.getQuoteDetailByListOfIds(new List<String> {quoteId});

            if (listOfQuoteInfo.isEmpty()) {
                return 'No quote information found!';
            }

            if (!listOfQuoteInfo.isEmpty()) {
                Quote quoteRecord = listOfQuoteInfo.get(0);
                System.debug('quoteRecord.quoteLineItems >>> ' + quoteRecord.quoteLineItems);

                if (quoteRecord.quoteLineItems.isEmpty()) {
                    return 'No quoteline items found in selected quote!';
                }

                for (QuoteLineItem eachQuoteLine : quoteRecord.quoteLineItems) {
                    System.debug('eachQuoteLine.Product2Id>>> ' + eachQuoteLine.Product2.Name);
                    if (eachQuoteLine.Product2Id != null &&  eachQuoteLine.Product2.Name.indexOf('DigitalLine Unlimited') != -1) {
                        listOfQuoteLineToUpdate.add(new QuoteLineItem(Id=eachQuoteLine.Id,
                             discount=Decimal.valueOf(targetPricePercent),
                             Discount_number__c = Decimal.valueOf(targetPricePercent)));
                    }
                }
            }
        }

        System.debug('listOfQuoteLineToUpdate>>> ' + listOfQuoteLineToUpdate);
        if (listOfQuoteLineToUpdate.isEmpty()) {
            return 'No digital unlimited line not founds';
        }
        if (!listOfQuoteLineToUpdate.isEmpty()) {
            update listOfQuoteLineToUpdate;
            successMsg = 'true';
        }
        return successMsg;
    }
    
    

    public class DealQuoteInfoWrappper {
        @AuraEnabled
        public List<Deal_Quoting_Tool_Base__mdt> listOfDealQuoteBasePrice {get;set;}
        @AuraEnabled
        public List<Deal_Quoting_Tool_List_Price__mdt> listOfDealQuoteListPrice {get;set;}
        @AuraEnabled
        public List<Deal_Quoting_Contact_Center_Potential__mdt> listOfDealQuoteContactCenterPotential {get;set;}
        @AuraEnabled
        public List<Deal_Quoting_Free_Month_Discount__mdt> listOfDealQuoteFreeMonthDiscount {get;set;}
        @AuraEnabled
        public List<Deal_Quoting_Info_Fees_And_E911__mdt> listOfDealQuoteFeeAndE991 {get;set;}
        @AuraEnabled
        public List<Deal_Quoting_Initial_Term__mdt> listOfDealQuoteInitialTerm {get;set;}
        @AuraEnabled
        public List<Deal_Quoting_Intercept__mdt> listOfDealQuoteIntercept {get;set;}
        @AuraEnabled
        public List<Deal_Quoting_Log_ACV__mdt> listOfDealQuoteLogAcv {get;set;}
        @AuraEnabled
        public List<Deal_Quoting_Order_Year__mdt> listOfDealQuoteOrderYear {get;set;}
        @AuraEnabled
        public List<Deal_Quoting_Payment_Plan__mdt> listOfDealQuotePaymentPlan {get;set;}
        @AuraEnabled
        public List<Deal_Quoting_Potential_Seat__mdt> listOfDealQuotePotentialSeat {get;set;}
        @AuraEnabled
        public List<Deal_Quoting_Sector__mdt> listOfDealQuoteSector {get;set;}
        @AuraEnabled
        public List<Deal_Quoting_Feature__mdt> listOfDealQuoteFeature {get;set;}
    }

    public class DealQuoteDetailWrapper {
        @AuraEnabled
        public Quote salesAgreementInformation {get; set;}

        @AuraEnabled
        public Deal_Quoting_Info__c dealQuoteInfo {get; set;}

    }
}