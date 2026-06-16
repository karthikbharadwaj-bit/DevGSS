/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 08-25-2021
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public class DealQuoteCalculatorUtil {
    
    public static List<Quote> getQuoteDetailByListOfIds(List<String> listOfQuoteIds) {
        return [SELECT Id, Name, Package_Info__c, Total_Number_of_Digital_Lines__c, Initial_Term_months__c, Special_Terms__c, OpportunityId, Opportunity.Name,
            Payment_Plan__c, (Select Product2Id, Product2.Name, Quantity, ListPrice, Discount, Charge_Term__c, Discount_type__c, UnitPrice
            FROM QuoteLineItems WHERE Product2.Name Like '%DigitalLine%') 
            FROM Quote WHERE Id IN :listOfQuoteIds];
    }

    public static List<Quote> getQuoteDetailByOppId(String oppId) {
        return [SELECT Id, Name, Package_Info__c, Total_Number_of_Digital_Lines__c, Initial_Term_months__c, Special_Terms__c, OpportunityId, Opportunity.Name,
            Payment_Plan__c, (Select Product2Id, Product2.Name, Quantity, ListPrice, Discount, Charge_Term__c, Discount_type__c, UnitPrice
            FROM QuoteLineItems WHERE Product2.Name Like '%DigitalLine%') 
            FROM Quote WHERE OpportunityId = :oppId AND isPrimary__c = true];
    }
    
    public static List<Deal_Quoting_Tool_Base__mdt> getDealQuotingToolBase() {
        return [SELECT DeveloperName, MasterLabel, Rate__c FROM Deal_Quoting_Tool_Base__mdt WHERE Is_CPQ__c = FALSE];
    }

    public static List<Deal_Quoting_Info__c> getDealQuotingInfoByRecordId(String dealQuoteId) {
        return [SELECT Id,Sales_Agreement__c, Sales_Agreement__r.Name, Opportunity__c, Tier__c, Number_of_Unlimited_DLs__c, Number_of_Limited_Exts__c, 
            Undiscounted_Unit_Price_for_Limited_Exts__c, Contract_Length_Years__c, Payment_Plan__c, Monthly_total_for_ProServ_Enterprise__c, 
            Monthly_total_for_Contact_Center__c, Monthly_total_for_phone_rentals__c, Monthly_total_for_all_other_recurring_ch__c, Sector__c, 
            Total_Number_of_Employees__c, Potential_to_sell_contact_center_in_near__c, Features__c, Free_Months_Given__c, Per_Unlimited_DL_advertised__c, 
            Total_for_Unlimited_DLs_advertised__c, Per_Limited_Extension_advertised__c, Total_for_Limited_Extensions_advertised__c, 
            Recommended_price_per_Unlimited_DL_after__c, Recommended_Unlimited_DLs_price_after_di__c, Recommended_price_per_Limited_Extension__c, 
            Recommended_Limited_Extensions_price_aft__c, Recommended_Discount_vs_list__c, Final_quote_price_per_Unlimited_DL__c, 
            Final_quote_price_for_Unlimited_DLs__c, Final_quote_price_per_Limited_Extension__c, Final_quote_price_for_Limited_Extensions__c, 
            Final_discount_vs_list__c, Final_discount_vs_list_percent__c, Deal_discretion_for_Unlimited_DLs__c, Deal_discretion_for_Unlimited_DLs_Per__c, 
            Discretion_vs_target_price__c, Approval_Needed_for_Unlimited_DLs__c, Approval_Different_from_GoA__c, Opportunity__r.Name,Number_of_additional_local_number_incl__c, 
			Undiscounted_Unit_Price_for_additional_l__c
             FROM Deal_Quoting_Info__c WHERE Id =:dealQuoteId];
    }

	public static List<Deal_Quoting_Info__c> getDealQuotingInfoIdByOpportunityId(String oppId) {
        return [SELECT Id,Sales_Agreement__c, Sales_Agreement__r.Name  FROM Deal_Quoting_Info__c WHERE Opportunity__c =:oppId];
    }

	

    public static List<Deal_Quoting_Info__c> getDealQuotingInfoByQuoteId(String quoteId) {
        return [Select Id, Sales_Agreement__c FROM Deal_Quoting_Info__c WHERE Sales_Agreement__c =:quoteId];
    }

    public static List<Opportunity> getOpportunityByOppId(List<String> listOfOpportunityId) {
        return [SELECT Id, Name, Quote_Calculator_Permission__c	 FROM Opportunity WHERE Id IN: listOfOpportunityId];
    }
    public static List<Deal_Quoting_Tool_List_Price__mdt> getDealQuotingToolListPrice() {
        return [SELECT MasterLabel, DeveloperName, Annual__c, Lower_Band__c, Monthly__c, Monthly_With_Contract__c, Upper_Band__c, 
                Base_Price_Deal__r.MasterLabel, Base_Price_Deal__r.DeveloperName, Base_Price_Deal__r.Rate__c
                FROM Deal_Quoting_Tool_List_Price__mdt where Is_Contact_Center__c=FALSE AND Is_CPQ__c = FALSE];
    }


    public static List<Deal_Quoting_Sector__mdt> getDealQuotingSector() {
        return [SELECT MasterLabel, DeveloperName, Coefficient__c FROM Deal_Quoting_Sector__mdt WHERE Is_CPQ__c = FALSE];
    }

    public static List<Deal_Quoting_Feature__mdt> getDealQuotingFeature() {
        return [SELECT MasterLabel, DeveloperName, Coefficient__c FROM Deal_Quoting_Feature__mdt WHERE Is_CPQ__c = FALSE];
    }

    
    public static List<Deal_Quoting_Potential_Seat__mdt> getDealQuotingPotentialSeat() {
        return [SELECT MasterLabel, DeveloperName, Coefficient__c FROM Deal_Quoting_Potential_Seat__mdt WHERE Is_CPQ__c = FALSE];
    }

    public static List<Deal_Quoting_Payment_Plan__mdt> getDealQuotingPaymentPlan() {
        return [SELECT MasterLabel, DeveloperName, Coefficient__c,list_unit_price__c FROM Deal_Quoting_Payment_Plan__mdt WHERE Is_CPQ__c = FALSE];
    }

    public static List<Deal_Quoting_Order_Year__mdt> getDealQuotingOrderYear() {
        return [SELECT MasterLabel, DeveloperName, Coefficient__c FROM Deal_Quoting_Order_Year__mdt WHERE Is_CPQ__c = FALSE];
    }

    public static List<Deal_Quoting_Log_ACV__mdt> getDealQuotingLogAcv() {
        return [SELECT MasterLabel, DeveloperName, Coefficient__c FROM Deal_Quoting_Log_ACV__mdt WHERE Is_CPQ__c = FALSE];
    }

    public static List<Deal_Quoting_Intercept__mdt> getDealQuotingIntercept() {
        return [SELECT MasterLabel, DeveloperName, Coefficient__c FROM Deal_Quoting_Intercept__mdt WHERE Is_CPQ__c = FALSE];
    }

    public static List<Deal_Quoting_Initial_Term__mdt> getDealQuotingInitialTerm() {
        return [SELECT MasterLabel, DeveloperName, Coefficient__c,Is_Contact_Center__c FROM Deal_Quoting_Initial_Term__mdt WHERE Is_CPQ__c = FALSE];
    }

    public static List<Deal_Quoting_Info_Fees_And_E911__mdt> getDealQuotingFeeAndE911() {
        return [SELECT MasterLabel, DeveloperName, E911__c, Max_Users__c, Compliance_and_Administrative_cost__c FROM Deal_Quoting_Info_Fees_And_E911__mdt WHERE Is_CPQ__c = FALSE ORDER BY Max_Users__c ASC ];
    }

    public static List<Deal_Quoting_Free_Month_Discount__mdt> getDealQuotingFreeMonthDiscount() {
        return [SELECT MasterLabel, DeveloperName, Coefficient__c FROM Deal_Quoting_Free_Month_Discount__mdt WHERE Is_CPQ__c = FALSE];
    }

    public static List<Deal_Quoting_Contact_Center_Potential__mdt> getDealQuotingContactCenterPotential() {
        return [SELECT MasterLabel, DeveloperName, Upper_Band__c, Lower_Band__c, Price__c FROM Deal_Quoting_Contact_Center_Potential__mdt WHERE Is_CPQ__c = FALSE];
    }
}