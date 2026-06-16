/*
* Name         : SetApprovalTypeHelper.trigger
* Created By   : Fedor Golovanov (fgolovanov@newmarketinc.com)
* Created Date : 7/June/2016
* Description  : B-58 (Sprint 5 Moscow). As a user I want the approval process to be on Quote so I could see all Quote Line Items in the same place and approve discounts without opening other objeects. The approval process should use the same GOA rules as Approval object is using right now.
* Dependencies : SetApprovalType.trigger, SetQuoteApprovalType.trigger
*/

public class SetApprovalTypeHelper {

    public static Set<String> featureWithSubfeature = new Set<String>{'11', '34', '35', '39', '48'};
    public static Map<Integer, String> approvalTypes = new Map<Integer, String>{0 => '', 1 => 'Sales Rep', 2 => 'Sales Manager', 3 => 'Sales Manager Manager', 4 => 'Sales VP', 5 => 'Finance'};
    public static Map<String, Integer> reverseApprovalTypes = new Map<String, Integer>{'SalesRep' => 1, 'SalesManager' => 2, 'SalesManagerManager' => 3, 'SalesVP' => 4, 'Finance' => 5};
    public static Set<String> approversProfiles = new Set<String>{'Sales Agent','System Administrator', 'Quoting Wizard Beta Tester', 'Sales 10+', 'Sales Agent SDR w Insidesales',
                                                    'Sales Manager - Business Processing', 'Sales Manager w Insidesales'};
    public static Map<String, Integer> specialTermsAprrovers = new Map<String, Integer>{'2-day Shipping for Ground Pricing' => 2, '1 Free Week of Service' => 2, '2 Free Weeks of Service' => 2,
                                                                          'Free shipping' => 3, '3 Free Weeks of Service' => 3, '4 Free Weeks of Service' => 3,
                                                                          '5 Free Weeks of Service' => 4, '6 Free Weeks of Service' => 4, '7 Free Weeks of Service' => 4, '8 Free Weeks of Service' => 4,
                                                                          '10 Free Weeks of Service' => 4, '12 Free Weeks of Service' => 4,
                                                                          '50% off service charge for the first 2 months of the contract' => 4,
                                                                          '50% off service charge for the first 3 months of the contract' => 4};
    public static Set<Id> hasSpecificExecuteId = new Set<Id>();
    public static Map<Id, QuoteLineItem> quoteLineItems = new Map<Id, QuoteLineItem>();
    public static Set<Id> autoApprovedQuotes = new Set<Id>();

    private static final String PROSERV_PRODUCT_SUBCATEGORY = 'Professional Services';

    private static final String CC_PROSERV_PRODUCT_SUBCATEGORY = 'CC Professional Services';

    private static final String PRODUCT_CHARGETERM_ONETIME = 'One - Time';

    public static Map<Id, QuoteTabValues> getTabValues(List<QuoteLineItem> items){
        Map<Id, QuoteTabValues> quoteId_Values = new Map<Id, QuoteTabValues>();
        for(QuoteLineItem qli: items){

            String chargeTerm = QuoteLineItemHelper.getChargeTerm(qli);
            Decimal discount = (Decimal) NumberHelper.getNumberNullSafe(qli.Discount);
            Decimal unitPrice = (Decimal) NumberHelper.getNumberNullSafe(qli.UnitPrice);
            Decimal newQuantity = (Decimal) NumberHelper.getNumberNullSafe(qli.NewQuantity__c);

            Decimal totalPrice = ((1 - discount / 100) * unitPrice).setScale(2) * newQuantity;

            if(!quoteId_Values.containsKey(qli.QuoteId)){
                quoteId_Values.put(qli.QuoteId, new QuoteTabValues(0,0,0,0));
            }

            //B-554 Create new field "First Year Total Cost excluding Taxes" that wouldn't take taxes (products with Product Family == "Taxes") into account but will be calculated in the same way as First_Year_Cost_of_Service__c.
            if (!qli.Zero_Quantity__c){
                if (chargeTerm == 'Monthly - Contract' || chargeTerm == 'Monthly'){
                    quoteId_Values.put(qli.QuoteId, quoteId_Values.get(qli.QuoteId).addValue((qli.TotalPrice) * 12, (qli.Subtotal - qli.TotalPrice) * 12, 0, 0));
                    if (qli.Product2.Family != 'Taxes') {
                        quoteId_Values.put(qli.QuoteId, quoteId_Values.get(qli.QuoteId).addValue(0, 0, 0, (qli.TotalPrice) * 12));
                        quoteId_Values.put(qli.QuoteId, quoteId_Values.get(qli.QuoteId).addValue(0, 0, totalPrice, 0));

                    }
                }else{
                    quoteId_Values.put(qli.QuoteId, quoteId_Values.get(qli.QuoteId).addValue(qli.TotalPrice, (qli.Subtotal - qli.TotalPrice), 0, 0));

                    if (qli.Product2.Family != 'Taxes') {
                        quoteId_Values.put(qli.QuoteId, quoteId_Values.get(qli.QuoteId).addValue(0, 0, 0, qli.TotalPrice));
                        System.debug('Added not a tax' + String.valueOf(qli.TotalPrice));
                    }

                    // Fixing after review of code; (July 4, 2k17);
                    if(chargeTerm == 'Annual' && qli.Product2.Family != 'Taxes') {
                      quoteId_Values.put(qli.QuoteId, quoteId_Values.get(qli.QuoteId).addValue(0, 0, (totalPrice / 12), 0));
                    }

                }
            }
        }

        return quoteId_Values;
    }

    //Return Map, which contains Id of Quote and sum of (QLI.Subtotal - QLI.TotalPrice)
    //of all QLI where QLI.Product2. Sub_Category__c == "Main" or "Contact Center".
    public static Map<Id, Decimal> getInitialDiscountWithoutProServ(List<QuoteLineItem> quotes) {

        Map<Id, Decimal> discountsWithoutProserv = new Map<Id, Decimal>();

        for(QuoteLineItem qli : quotes) {

            if((qli.Product2.Sub_Category__c == 'Main' || qli.Product2.Sub_Category__c == 'Contact Center')
                && qli.Subtotal != null && qli.TotalPrice != null) {
                if(discountsWithoutProserv.containsKey(qli.QuoteId)) {
                    Decimal newValue = discountsWithoutProserv.get(qli.QuoteId) + qli.Subtotal - qli.TotalPrice;
                    discountsWithoutProserv.put(qli.QuoteId, newValue);
                } else {
                    discountsWithoutProserv.put(qli.QuoteId, (qli.Subtotal - qli.TotalPrice));
                }
            }
        }
        return discountsWithoutProserv;
    }

    public static Boolean isValueNotEmpty(String val){
        return (val != null && val.trim() != '' && val != 'null');
    }

    public static Boolean isValueNotEmpty(Decimal val){
        return (val != null);
    }

    public static Map<Id, String> getProductsMap(Map<Id, QuoteLineItem> qlis){
        Map<Id, String> productsMap = new Map<Id, String>();

        for (QuoteLineItem qli : qlis.values()){
            String subcategory = (qli.Product2.Sub_Category__c == 'Main') ? 'RingCentral' : qli.Product2.Sub_Category__c;
            if(String.isBlank(subcategory)) {
                continue;
            }
            if (productsMap.containsKey(qli.QuoteId)) {
                if (!productsMap.get(qli.QuoteId).containsIgnoreCase(subcategory)){
                    String productsList = productsMap.get(qli.QuoteId) + ';' + subcategory;
                    productsMap.put(qli.QuoteId, productsList);
                }
            } else {
                productsMap.put(qli.QuoteId, subcategory);
            }
        }
        return productsMap;
    }

    public class QuoteTabValues{
        public Decimal FYCS;
        public Decimal FYD;
        public Decimal MRV;
        //First Year Total Cost excluding Taxes
        public Decimal FYTCET;

        public QuoteTabValues(Decimal cs, Decimal f, Decimal m, Decimal cset){
            this.FYCS = cs;
            this.FYD = f;
            this.MRV = m;
            this.FYTCET = cset;
        }

        public QuoteTabValues addValue(Decimal acs, Decimal af, Decimal am, Decimal cset){
            this.FYCS += (acs != null ? acs : 0);
            this.FYD += (af != null ? af : 0);
            this.MRV += (am != null ? am : 0);
            this.FYTCET += (cset != null ? cset : 0);
            return this;
        }
    }

    public static Map<Id, Decimal> getMapProServOneTime( List<QuoteLineItem> qlis ){
        Map<Id, Decimal> quoteSumProServOneTime = new Map<Id, Decimal>();
        Decimal sumProServOneTime;

        for( QuoteLineItem qli : qlis ) {
            if ( !quoteSumProServOneTime.containsKey( qli.QuoteId ) ) {
                quoteSumProServOneTime.put( qli.QuoteId, 0 );
            }
            if ( (qli.Product2.Sub_Category__c == PROSERV_PRODUCT_SUBCATEGORY
                    || qli.Product2.Sub_Category__c == CC_PROSERV_PRODUCT_SUBCATEGORY)
                    && qli.Product2.Charge_Term__c == PRODUCT_CHARGETERM_ONETIME) {
                sumProServOneTime = quoteSumProServOneTime.get( qli.QuoteId ) + qli.TotalInitialPrice__c;
                quoteSumProServOneTime.put( qli.QuoteId, sumProServOneTime );
            }
        }

        return quoteSumProServOneTime;
    }
}