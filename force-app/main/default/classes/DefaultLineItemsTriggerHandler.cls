public class DefaultLineItemsTriggerHandler {

    // Quote Record Types
    private static final String SALES_QUOTE_RT_NAME = 'Sales Quote';
    private static final String PROSERV_QUOTE_RT_NAME = 'ProServ Quote';
    private static final String CC_PROSERV_QUOTE_RT_NAME = 'CC ProServ Quote';

    private static final Map<String, Schema.RecordTypeInfo> QUOTE_RT_INFO_BY_NAME =
            Quote.SObjectType.getDescribe().getRecordTypeInfosByName();

    private static final Id SALES_QUOTE_RT_ID = QUOTE_RT_INFO_BY_NAME.get(SALES_QUOTE_RT_NAME).getRecordTypeId();
    private static final Id PROSERV_QUOTE_RT_ID = QUOTE_RT_INFO_BY_NAME.get(PROSERV_QUOTE_RT_NAME).getRecordTypeId();
    private static final Id CC_PROSERV_QUOTE_RT_ID = QUOTE_RT_INFO_BY_NAME.get(CC_PROSERV_QUOTE_RT_NAME).getRecordTypeId();

    public static final String SERVICE_PRODUCT_FAMILY = 'Service';
    public static final String FEE_PRODUCT_FAMILY = 'Fee';

    public static void setDefaultLineItems(List<Quote> quotes, Set<Id> priceBooksIds){

        List<QuoteLineItem> itemsToInsert = new List<QuoteLineItem>();
        Map<Id,List<PriceBookEntry>> priceBookEntrys = new Map<Id,List<PriceBookEntry>>();
        Map<String, DepandantFee> dependantItemsQuantity = new Map<String, DepandantFee>();

        for (PriceBookEntry pBookEntry:[SELECT Id, 
                                               CurrencyIsoCode, 
                                               Pricebook2Id, 
                                               Product2Id, 
                                               UnitPrice, 
                                               Per_Line__c, 
                                               Min_Quantity__c, 
                                               Product2.Description, 
                                               Pricebook2.Line_Range_Min__c, 
                                               Pricebook2.Service__c, 
                                               Product2.Family,
                                               Product2.Dependent_on_Feature__c,
                                               Product2.Feature__c
            FROM PriceBookEntry
            WHERE (Product2.Family = 'Tier' OR Product2.Family = 'Service' OR Product2.Family = 'Fee')
            AND Pricebook2Id IN: priceBooksIds
            AND Pricebook2.Service__c != 'Glip'
            AND Pricebook2.IsStandard = false]){
            if(!priceBookEntrys.containsKey(pBookEntry.Pricebook2Id)) {
                priceBookEntrys.put(pBookEntry.Pricebook2Id, new PriceBookEntry[0]);
            }
            priceBookEntrys.get(pBookEntry.Pricebook2Id).add(pBookEntry);
        }

        for (Quote qt: quotes) {
            if(qt.Upsell_Status__c != 'Upsell' && priceBooksIds.contains(qt.Pricebook2Id) && priceBookEntrys.get(qt.Pricebook2Id) != null) {
                for(PriceBookEntry pBookEntry: priceBookEntrys.get(qt.Pricebook2Id)) {
                    if(qt.CurrencyIsoCode == pBookEntry.CurrencyIsoCode) {

                        // B-2599 Do not create service products automatically for non sales quotes
                        Boolean createQLI = !((qt.RecordTypeId != null && !qt.RecordTypeId.equals(SALES_QUOTE_RT_ID))
                                || (pBookEntry.Product2.Family == FEE_PRODUCT_FAMILY));

                        if( createQLI ) {

                            QuoteLineItem newQli = new QuoteLineItem(
                                ServiceDate = date.today(),
                                Description = pBookEntry.Product2.Description,
                                UnitPrice = pBookEntry.UnitPrice,
                                Quantity = qt.Total_Number_of_Digital_Lines__c > 0 ?
                                        qt.Total_Number_of_Digital_Lines__c :
                                        (pBookEntry.Pricebook2.Line_Range_Min__c > 0 ?
                                                pBookEntry.Pricebook2.Line_Range_Min__c :
                                                1),
                                QuoteId = qt.Id,
                                PriceBookEntryId = pBookEntry.Id,
                                Product2Id = pBookEntry.Product2Id
                            );
                            
                            itemsToInsert.add(newQli);
                            if(pBookEntry.Product2.Feature__c != null){
                                String key = pBookEntry.Pricebook2Id + String.ValueOf(pBookEntry.Product2.Feature__c);
                                dependantItemsQuantity.put(key, new DepandantFee(key, newQli.Quantity, newQli.QuoteId));
                            }

                        }else{
                            // Do not create QuoteLineItem
                            continue;
                        }
                    }
                }
            }
        }

        if(itemsToInsert.size() > 0){
            itemsToInsert.addAll(QuoteLineItemTriggerHelper.prepareQuoteLineItemsFeesOnInsert(new List<QuoteLineItem>(), priceBookEntrys, dependantItemsQuantity));

            Database.SaveResult[] insertResults = Database.insert(itemsToInsert, true);
            for(Integer i=0; i < insertResults.size(); i++){
                if (!insertResults.get(i).isSuccess()){
                    system.debug('Failed Line Item ID ' + itemsToInsert.get(i).Id + '.With Error: ' + insertResults.get(i).getErrors().get(0).getMessage());
                }
            }
        }
    }

    public class DepandantFee{
        public String key;
        public Decimal quantity;
        public Id quoteId;

        public DepandantFee(String key, Decimal qty, Id qId){
            this.key = key;
            this.quantity = qty;
            this.quoteId = qId; 
        }
    } 

}