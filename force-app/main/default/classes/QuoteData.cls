public with sharing class QuoteData {
    public Quote retrieveQuoteByQuoteNumber(String quoteNumber){
        Quote retrievedQuote = new Quote();
        if (quoteNumber != null) {
            retrievedQuote = [SELECT Id, Opportunity.Id, Opportunity.Account.Id, QuoteNumber
                              FROM Quote
                              WHERE QuoteNumber = :quoteNumber];
        }
        return retrievedQuote;
    }

}