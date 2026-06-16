public class DocumentHelper {
    
    public class EstimatedPriceCSVWrapper {
        public String brand;
        public String currencyType;	
        public String service;
        public Decimal price;	
        public Integer minimumUserRange;	
        public Integer maximumUserRange;

        public EstimatedPriceCSVWrapper(List<String> csvRow) {

            this.brand = csvRow[0]; //Brand table on CSV
            this.currencyType = csvRow[1]; //Currency table on CSV
            this.service = csvRow[2]; //Service table on CSV (Price, minimumUserRange and maximumUserRange are the following tables, order must be respected)
            this.price = String.isNotBlank(csvRow[3].trim()) ?  Decimal.valueOf(csvRow[3].trim()) : null;
            this.minimumUserRange = String.isNotBlank(csvRow[4].trim()) && csvRow[4].trim().isNumeric() ? Integer.valueOf(csvRow[4].trim()) : null;
            this.maximumUserRange = String.isNotBlank(csvRow[5].trim()) && csvRow[5].trim().isNumeric() ? Integer.valueOf(csvRow[5].trim()) : null;
        }
    }
    
    private static List<EstimatedPriceCSVWrapper> pricingCatalog;

    public static Decimal getEstimatedPriceByOpportunity(Opportunity opp, Decimal quantityOfEquipment, String serviceType) {

        if(quantityOfEquipment == null || quantityOfEquipment == 0 || opp == null || opp.Brand_Name__c == null || opp.CurrencyIsoCode == null || opp.tier_name__c == null) {
            return 0;
        }

        try {

            pricingCatalog = loadProductForecastAmounts();
            for(EstimatedPriceCSVWrapper row : pricingCatalog) {
                if(opp.Brand_Name__c.equalsIgnoreCase(row.brand) && 
                    opp.CurrencyIsoCode.equalsIgnoreCase(row.currencyType) && 
                    row.service != null &&
                    row.service.equalsIgnoreCase(serviceType) &&
                    row.minimumUserRange != null &&
                    Math.abs(quantityOfEquipment) >= row.minimumUserRange &&  
                    row.maximumUserRange != null &&
                    Math.abs(quantityOfEquipment) <= row.maximumUserRange) {
                        return row.price != null ? row.price * 12 * quantityOfEquipment : 0;
                } 
            }
        } catch (Exception ex) {
            AquivaHelper.throwAquivaException(ex);
        }
        return 0;
    }

    private static List<EstimatedPriceCSVWrapper> loadProductForecastAmounts() {
                
        if (pricingCatalog != null) {
            return pricingCatalog;
        } else {
            List<EstimatedPriceCSVWrapper> resultsToReturn = new List<EstimatedPriceCSVWrapper>();
            try {
                Document doc = OpportunityMethods.getDocument('Pipeline_Forecast_Amounts');

                if(doc != null && doc.Body != null) {
                    List<List<String>> csvValues =  OpportunityMethods.parseCSV(doc.Body.toString(), true);

                    for(List<String> row : csvValues) {                        
                        resultsToReturn.add(new EstimatedPriceCSVWrapper(row));
                    }
                }

            } catch (Exception ex) {
                AquivaHelper.throwAquivaException(ex);
            }
            return resultsToReturn;
        }
    }
}