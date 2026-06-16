public with sharing class UpdateSeatOveragesPriceHelper {
	public List<PricebookEntry> seats;

	public UpdateSeatOveragesPriceHelper() {
		 seats = [SELECT Id, Name, Pricebook2Id, UnitPrice, Pricebook2.Plan__c, Product2.Family, Product2.Parent__c, Product2Id
					FROM PriceBookEntry 
					WHERE Product2.Product_Type__c = 'Seat' AND Product2.Family != 'Overage'];
	}
}