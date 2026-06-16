public class AccountMetricExtensionPDF {
    public Account accObj {get;set;}
    public Account_Metric__c accountMetricObj {get;set;}
    Integer perGroupNumber;
    public Quote quoteObj{get;set;}
    AccountScoreCardHelper accountScoreCardHelperObj = new  AccountScoreCardHelper();
    public AccountMetricExtensionPDF(ApexPages.StandardController controller) {
        String accountId = ApexPages.currentPage().getParameters().get('accid'); 	//controller.getId();
        accountMetricObj = new Account_Metric__c();
        if(accountId != null) {
	        try {
        	 	accObj = accountScoreCardHelperObj.getAccountValues(accountId);
        	 	quoteObj = accountScoreCardHelperObj.getSalesAgreement(accObj);
        		accountMetricObj = accountScoreCardHelperObj.getAccountMetricValues(accountId);
        		if(accountMetricObj != null) {
        			perGroupNumber = Integer.valueOf(accountMetricObj.Peer_Group_ID__c);
        		}
           } catch(Exception ex) {} 	
        }
    }
    
    public Set<Integer> getMetricSet() {
    	Set<Integer> rtnSetMetricId = accountScoreCardHelperObj.getMetricSet();
        return rtnSetMetricId;
    }
}