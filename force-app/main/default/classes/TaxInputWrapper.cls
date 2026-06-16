public class TaxInputWrapper {
    
    	public String quoteId  {get;set;}
        public String ChargeType {get;set;}
        public String productName  {get;set;}
        public String avalaraTaxTypeId  {get;set;}
        public Decimal amount  {get;set;} 
        public Decimal billingCycleDuration {get;set;}
        public string recurring  {get;set;}
        public String categoryId  {get;set;}
            
        public TaxInputWrapper(String quoteID, String chargetype ,String productname, String avalaraTaxtypeId, Decimal Amount, Decimal billingCD, String Recurring, String CategoryId)
        {
        	this.quoteId = quoteID;
            this.ChargeType = chargetype;
            this.productName = productname;
            this.avalaraTaxTypeId = avalaraTaxtypeId;     
            this.amount= Amount;
            this.billingCycleDuration = billingCD;
            this.recurring = Recurring;
            this.categoryId = CategoryId;
        }
        
}