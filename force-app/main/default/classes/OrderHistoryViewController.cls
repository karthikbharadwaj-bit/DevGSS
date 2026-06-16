public class OrderHistoryViewController {

	public Account acc {get;set;}

	public OrderHistoryViewController(ApexPages.StandardController stdController) {
		acc = (Account)stdController.getRecord();
	}

	@AuraEnabled
	public static List<Order> getOrders(String accId) {

		// try {
			if(!String.isBlank(accId)) {
				return [SELECT Id, Name, RecordType.Name, CreatedDate, Provisioned_Date__c,
											 Submitted_Date__c, Quote.Id, Quote.Name, Quote.CreatedDate,
											 (SELECT Id, Qty__c, ListPrice, UnitPrice, CurrencyIsoCode, CreatedDate,
											  			 Product2.Id, Product2.Name FROM OrderItems) FROM Order WHERE Quote.Account.Id =: accId];
			}
		// } catch(Exception e) {
		// 	System.debug('Exception============'+e.getMessage());
		// 	System.debug('Exception============'+e.getStackTraceString());
		// }

		return null;
	}


}