public class ProdInputWrapper {

    	public Id ProdId{get;set;}         
        public Boolean isApplied{get;set;}        
        public String ProdName{get;set;}        
        public Decimal DiscAmt{get;set;}        
        public Decimal DiscPer{get;set;}        
        public String DiscType{get;set;}
    
    	public ProdInputWrapper(Id prodid, boolean isapplied, string prodname, decimal discper)
        {
            this.ProdId = prodid;
            this.isApplied = isapplied;
            this.ProdName = prodname;
            this.DiscPer = DiscPer;                     	
        }
    
}