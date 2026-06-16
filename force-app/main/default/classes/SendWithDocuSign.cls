/*
* Name         : SendWithDocuSign
* Created By   : Alexander savickiy
* Created Date : 15/June/2018
* Description  : B-5292 (Sprint 62 Moscow).
* Dependencies : QuoteHelper.cls
*/
global class SendWithDocuSign {

	webservice static String processData(Id opportunityId, Id selectedQuoteId) {
		List <Opportunity> optyList = [
			SELECT Id,
				(SELECT Id, Status, IsPrimary__c, QuoteType__c, Approved_Status__c,
					RecordTypeId, Special_Terms__c, Billing_Zip_Postal_Code__c, Billing_City__c, Billing_Country__c,
					Billing_State_Province__c, Billing_Street__c, Account.BillingPostalCode, Account.BillingCity,
					Account.BillingCountry, Account.BillingState, Account.BillingStreet,
					Opportunity.Is_Billing_Opportunity__c, LastModifiedDate
				FROM Quotes ORDER BY LastModifiedDate DESC)
			FROM Opportunity WHERE Id =:opportunityId
		];
		Opportunity opty = optyList[0];
        String result = null;
        List<ErrorWrapper> errors = getErrors(opty, selectedQuoteId);
        if (errors != null) {
            result = JSON.serialize(errors);
        }
        return result;
	}

    public static List<ErrorWrapper> getErrors(Opportunity opty, Id selectedQuoteId) {
        //List of possible errors
        List <ErrorWrapper> errorMessagesList = new List <ErrorWrapper>();
        if(opty.Quotes.isEmpty()) {
            ErrorWrapper error = new ErrorWrapper('Send with DocuSign Error',
                'To send with DocuSign you must have at least one Quote on the Opportunity');
            return new List<ErrorWrapper> {error};
        }

        if(hasActiveQuote(opty.Quotes)) {
            ErrorWrapper error = new ErrorWrapper('Send with DocuSign Error',
                'Active Agreement already exists under this Opportunity');
            return new List<ErrorWrapper> {error};
        }

        if(!hasRecordType(opty.Quotes)) {
            ErrorWrapper error = new ErrorWrapper('Send with DocuSign Error',
                'One of quotes under Opportunity has no record type. Please create a case using bizserv.case@ringcentral.com');
            return new List<ErrorWrapper> {error};
        }

        Quote primaryQuote = getSelectedPrimaryQuote(opty.Quotes, selectedQuoteId);
        if(primaryQuote == null) {
            ErrorWrapper error = new ErrorWrapper('Send with DocuSign Error',
                'There is no appropriate primary Quote under this Opportunity');
            return new List<ErrorWrapper> {error};
        }

        if(!isQuoteReadyForDocusign(primaryQuote)) {
            ErrorWrapper error = new ErrorWrapper('Send with DocuSign Error',
                'Primary Quote should be in \'Agreement\' stage and has \'Approved\' or \'Not Required\' approved status in order to be sent with DocuSign');
            return new List<ErrorWrapper> {error};
        }

        if(primaryQuote.Special_Terms__c != null && !QuoteHelper.isCorrectBillingAddress(primaryQuote)) {
            ErrorWrapper error = new ErrorWrapper('Send with DocuSign Error',
                'Taxes were requested for the Address that doesn\'t match Billing Address on the Account. Please change Quote Stage to Quote, remove and add Taxes for new Account Billing Address');
            return new List<ErrorWrapper> {error};
        }

        return null;
    }

	public static Boolean hasActiveQuote(List<Quote> quoteList) {
		for(Quote qt : quoteList) {
			if(qt.Status == QuoteHelper.QUOTE_STATUS_ACTIVE) {
                return true;
            }
		}
		return false;
	}

	public static Boolean hasRecordType(List<Quote> quoteList) {
		for(Quote qt : quoteList) {
			if(qt.RecordTypeId == null) {
                return false;
            }
		}
		return true;
	}

    public static Quote getSelectedPrimaryQuote(List<Quote> quoteList, Id selectedQuoteId) {
        if (String.isBlank(selectedQuoteId)) {
            return QuoteHelper.getPrimaryQuote(quoteList);
        }

        Quote primaryQuote = new Map<Id, Quote>(quoteList).get(selectedQuoteId);
        Boolean isBillingQuote = primaryQuote != null && primaryQuote.Opportunity.Is_Billing_Opportunity__c;
        Boolean isPrimaryQuote = primaryQuote != null && primaryQuote.isPrimary__c;
        Boolean isNGBSPrimaryQuote =
            isPrimaryQuote
            && isBillingQuote
            && QuoteHelper.PRIMARY_QUOTES_RT_IDS.contains(primaryQuote.RecordTypeId);
        Boolean isSalesPrimaryQuote =
            isPrimaryQuote
            && !isBillingQuote
            && QuoteHelper.RT_ID_SALES == primaryQuote.RecordTypeId;

        return (isNGBSPrimaryQuote || isSalesPrimaryQuote) ? primaryQuote : null;
    }

    public static Boolean isQuoteReadyForDocusign(Quote primaryQuote) {
        return QuoteHelper.isPOCQuote(primaryQuote)
                || primaryQuote.QuoteType__c == QuoteHelper.QUOTE_TYPE_AGREEMENT
                && QuoteHelper.APPROVAL_STATUSES_NOT_REQUIRED.contains(primaryQuote.Approved_Status__c);
    }

	public class ErrorWrapper {
		public String header;
		public string message;

		public ErrorWrapper (String header, String message) {
			this.header = header;
			this.message = message;
		}
	}
}