@isTest private class Test_QuoteData
{
    @isTest static void testRetrieveQuotesByQuoteNumber() {
        Account testAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => 'testAcc'
                }
            )
            .create()
            .getRecord();
        Contact testCont = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.FirstName => 'Test1',
                    Contact.LastName => 'Opty test contact',
                    Contact.AccountId => testAcc.Id,
                    Contact.Email => 'test@test.com',
                    Contact.Phone => '+18885550505',
                    Contact.Preferred_Language__c => 'en_US',
                    Contact.CurrencyIsoCode => 'USD'
                }
            )
            .create()
            .getRecord();
        DateTime dateNow = System.now();    
		Opportunity testOpp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
			.setFields(
				new Map<SObjectField, Object>{
					Opportunity.Name => 'Test Opportunity 2016',
					Opportunity.Type => 'Syndicated - New',
					Opportunity.StageName => 'Planning',
					Opportunity.CloseDate => Date.newinstance(dateNow.year(), dateNow.month(), dateNow.day()),
					Opportunity.AccountId => testAcc.Id,
					Opportunity.Primary_Opportunity_Contact__c => testCont.Id,
				    Opportunity.EstimatedProfessionalServices12Month__c => 10
				}
			)
			.create()
			.getRecord();
        Quote quote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(
                    new Map<SObjectField, Object>{
                            Quote.Name => 'quotetest',
                            Quote.OpportunityId => testOpp.Id,
                            Quote.Total_Number_of_Digital_Lines__c => 10,
                            Quote.Account__c => testOpp.AccountId,                             
                            Quote.RecordTypeId => QuoteHelper.RT_ID_SALES,
                            Quote.Upsell_Status__c => 'New',
                            Quote.Pricebook2Id => Test.getStandardPricebookId()
                    }
            )
            .create()
            .getRecord();
        String quoteNumber = [SELECT QuoteNumber FROM Quote LIMIT 1].QuoteNumber;
        Test.startTest();
        QuoteData quoteData = new QuoteData();
        Quote comparedQuote = quoteData.retrieveQuoteByQuoteNumber(quoteNUmber);
        Test.stopTest();
        System.assert(comparedQuote != null, 'At least one Quote object should have been retrieved');
    }
}