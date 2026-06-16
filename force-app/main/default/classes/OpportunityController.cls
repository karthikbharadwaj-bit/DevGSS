public class OpportunityController{
	public Opportunity oppObj{get;set;}
	public String BrandName{get;set;}
	public OpportunityContactRole oppContactRole{get;set;}
	public String proposalDate{get;set;}
	public List<ProductsWrapper> ProductServiceList{get;set;}
	public List<ProductsWrapper> ProductHardwareList{get;set;}

	public List<Boolean> isBlankServiceList{get;set;}
	public List<Boolean> isBlankHardwareList{get;set;}

	public Decimal serviceTotalPrice{get;set;}
	public Decimal hardwareTotalPrice{get;set;}

	public static final String BRAND_RING_CENTRAL = 'RingCentral';
	public static final String BRAND_RING_CENTRAL_CANADA = 'RingCentral Canada';

	public OpportunityController(ApexPages.StandardController controller) {
		ProductServiceList = new List<ProductsWrapper>();
		ProductHardwareList = new List<ProductsWrapper>();
		
		isBlankServiceList = new List<Boolean>();
		isBlankHardwareList = new List<Boolean>();
		
		serviceTotalPrice = Decimal.valueOf(0);
		hardwareTotalPrice = Decimal.valueOf(0);
		
		proposalDate = formatDate(Datetime.now());
		BrandName = 'RingCentral'; 
		this.oppObj = (Opportunity)controller.getRecord();
		oppObj = [SELECT Id, Name, OwnerId, Brand_Name__c,CurrencyISOCode, Owner.Name, Term__c, Owner.Email, Proposal_Expiration_Date__c, Owner.Phone, owner.Title, 
					(SELECT Id, ContactId, Contact.Name, Contact.Email, Contact.Phone From OpportunityContactRoles WHERE IsPrimary=true LIMIT 1),
					(SELECT PricebookEntryId,UnitPrice, CurrencyISOCode, TotalPrice, Quantity, ListPrice FROM OpportunityLineItems) FROM Opportunity WHERE Id=: oppObj.Id];
		Map<Id, List<OpportunityLineItem>> priceBookLineItem = new Map<Id, List<OpportunityLineItem>>(); 
		if(oppObj.OpportunityLineItems != null) {
			List<OpportunityLineItem> oppLineItems = oppObj.OpportunityLineItems;
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'items='+oppLineItems.size()));
			Set<Id> priceBookIds = new Set<Id>();
			for(OpportunityLineItem oppLineItemObj : oppLineItems) {
				if(oppLineItemObj.PricebookEntryId != null) {
					priceBookIds.add(oppLineItemObj.PricebookEntryId);
				}
			}
			if(oppLineItems != null && oppLineItems.size() != 0) {
				getLineItems(priceBookIds, oppLineItems);
			}
		}
		if(oppObj.Proposal_Expiration_Date__c != null) {
			Datetime foundDate = Datetime.newInstance(oppObj.Proposal_Expiration_Date__c, Time.newInstance(0, 0, 0, 0));
			proposalDate =  formatDate(foundDate);
		}    		
	      if(!String.isBlank(oppObj.Brand_Name__c) && oppObj.Brand_Name__c.containsIgnoreCase('Canada')) {
	      		BrandName = 'RingCentral Canada';
	      } else if(!String.isBlank(oppObj.Brand_Name__c) && oppObj.Brand_Name__c.containsIgnoreCase('UK')) {
	      		BrandName = 'RingCentral UK';
	      } else if(!String.isBlank(oppObj.Brand_Name__c) && oppObj.Brand_Name__c.containsIgnoreCase('EU')) {
	      		BrandName = 'RingCentral EU';
	      } else {
				BrandName = 'RingCentral';      	
	      }
		try {
			if(oppObj.OpportunityContactRoles != null) {
				oppContactRole = oppObj.OpportunityContactRoles;
  			}
		} catch(Exception e) {}
	}

	@TestVisible
	private String superScript(String day) {
		Integer lastIndex = day.length()-1;
		if(day.lastIndexOf('0') == lastIndex) {
			return 'th';
		}
		if(day.lastIndexOf('1') == lastIndex) {
			return 'st';
		}
		if(day.lastIndexOf('2') == lastIndex) {
			return 'nd';
		}
		if(day.lastIndexOf('3') == lastIndex) {
			return 'rd';
		}
		return 'th';
	}

	@TestVisible
	private String getMonthName(Datetime d){
       return d.format('MMMMM');
    }

	private void getLineItems(Set<Id> priceBookIds, List<OpportunityLineItem> oppLineItems) {
		Map<Id, PricebookEntry> priceBookMap = new Map<Id, PricebookEntry>([SELECT id, name, Product2.productcode, Product2.Name, 
		productcode, Product2.Tier_Family__c, Product2.description, UnitPrice FROM PricebookEntry WHERE Id IN:priceBookIds AND isActive=true]);
		ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'pricebook='+priceBookMap.size()));
		for(OpportunityLineItem oppLineItem : oppLineItems) {
			Decimal unitP = oppLineItem.UnitPrice;
			Decimal totalP = oppLineItem.TotalPrice;
			Double quantityP = oppLineItem.quantity;
			String tierFamily = 'SERVICE';
			PricebookEntry priceBookObj = priceBookMap.get(oppLineItem.PricebookEntryId);
			if(priceBookObj != null) {
				if(!String.isBlank(priceBookObj.Product2.Tier_Family__c) && priceBookObj.Product2.Tier_Family__c.contains('Device') ) {
					tierFamily = 'DEVICE';
				}
				ProductsWrapper productObj = new ProductsWrapper(priceBookObj.Product2.Name, priceBookObj.Product2.description, 
				unitP, totalP, quantityP, tierFamily, oppLineItem.CurrencyISOCode);
				if(tierFamily == 'DEVICE') {
					ProductHardwareList.add(productObj);
					hardwareTotalPrice += totalP;
				} else {
					serviceTotalPrice += totalP;
					ProductServiceList.add(productObj);
				}
			}
		}
		if(ProductHardwareList.size() == 0) {
			isBlankHardwareList.add(true);
		}
		if(ProductServiceList.size() == 0) {
			isBlankServiceList.add(true);
		}
	}

	@TestVisible
	private String formatDate(Datetime foundDate) {
		return getMonthName(foundDate) + ' ' + String.valueOf(foundDate.day()) + '<sup>'+ superScript(String.valueOf(foundDate.day())) +'</sup>'+', '+ String.valueOf(foundDate.year());
	}
	
	public class ProductsWrapper {
		public Decimal unitPrice{get;set;}
		public Decimal extendedPrice{get;set;}
		public String productName{get;set;}
		public String description{get;set;}
		public Double quantity{get;set;}
		public String tierFamily{get;set;}
		public String CurrencyISOCode{get;set;}
		public ProductsWrapper(String productName, String description,Decimal unitPrice, Decimal extendedPrice, 
		Double quantity, String tierFamily, String CurrencyISOCode) {
			this.productName = productName;
			this.description = description;
			this.unitPrice = unitPrice;
			this.extendedPrice= extendedPrice;
			this.quantity = quantity;
			this.tierFamily = tierFamily;
			this.CurrencyISOCode = CurrencyISOCode;
		}
	}
}