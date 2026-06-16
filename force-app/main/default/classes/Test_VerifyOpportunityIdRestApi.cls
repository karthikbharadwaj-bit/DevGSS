@IsTest
public class Test_VerifyOpportunityIdRestApi {
	@IsTest
	private static void test_verifyOpportunityIdService() {
		Account testAccount = new Account(Name='TestAcc', RC_User_ID__c = '55555');
        insert testAccount;

        Opportunity opp = new Opportunity(
                Name = 'Test Opportunity',
                Type = 'Syndicated - New',
                StageName = OpportunityHelper.closedStage,
                CloseDate = System.today(),
                Brand_Name__c = 'RingCentral',
                AccountId = testAccount.Id
        );
        insert opp;

        Quote testQuote = new Quote (
                Name = 'Test Quote',
                OpportunityId = opp.id,
                Status = 'Draft',
                Pricebook2Id = Test.getStandardPricebookId(),
                Total_Number_of_Digital_Lines__c = 5
        );
        insert testQuote;

    	RestRequest req = new RestRequest(); 
        req.requestURI = URL.getOrgDomainUrl().toExternalForm() + '/services/apexrest/VerifyOpportunityIdRestApi';
    	req.httpMethod = 'POST';
    	// Prepare request body for successful scenario
    	VerifyOpportunityIdRestApi.OpportunityValidationRequest requestBody = new VerifyOpportunityIdRestApi.OpportunityValidationRequest();
    	requestBody.oppId = opp.Id;
    	requestBody.accUserId = testAccount.RC_User_ID__c;
    	req.requestBody = Blob.valueOf(JSON.serialize(requestBody));
    	// Set request
        RestContext.request = req;
        // Set response
        RestResponse res = new RestResponse();
    	RestContext.response = res;

    	Test.startTest();
    		// Call rest service
    		VerifyOpportunityIdRestApi.verifyOpportunityId();
    		RestResponse serviceResponse = RestContext.response;

			VerifyOpportunityIdRestApi.OpportunityValidationResponse validationSuccess = (VerifyOpportunityIdRestApi.OpportunityValidationResponse)JSON.deserialize(serviceResponse.responseBody.toString(), VerifyOpportunityIdRestApi.OpportunityValidationResponse.class);

			// Check response
			System.assertEquals('application/json', res.headers.get('Content-Type'));
			System.assertEquals(opp.Id, validationSuccess.oppId);
			System.assertEquals(testAccount.RC_User_ID__c, validationSuccess.accUserId);
			System.assertEquals(true, validationSuccess.isValidId);
			System.assertEquals('', validationSuccess.errorMessage);

			// Prepare request body for failing scenario(opty is incorrect)
			VerifyOpportunityIdRestApi.OpportunityValidationRequest requestBodyEmptyOpty = new VerifyOpportunityIdRestApi.OpportunityValidationRequest();
	    	requestBodyEmptyOpty.oppId = '';
	    	requestBodyEmptyOpty.accUserId = testAccount.RC_User_ID__c;
	    	req.requestBody = Blob.valueOf(JSON.serialize(requestBodyEmptyOpty));
	    	RestContext.request = req;

	    	// Call rest service
	    	VerifyOpportunityIdRestApi.verifyOpportunityId();
    		RestResponse serviceResponseFail1 = RestContext.response;

			VerifyOpportunityIdRestApi.OpportunityValidationResponse validationOptyFail = (VerifyOpportunityIdRestApi.OpportunityValidationResponse)JSON.deserialize(serviceResponseFail1.responseBody.toString(), VerifyOpportunityIdRestApi.OpportunityValidationResponse.class);
			// Check response
			System.assertEquals('', validationOptyFail.oppId);
			System.assertEquals(testAccount.RC_User_ID__c, validationOptyFail.accUserId);
			System.assertEquals(false, validationOptyFail.isValidId);
			System.assertEquals('Opportunity Id is empty or doesn\'t exist in salesforce', validationOptyFail.errorMessage);

			// Prepare request body for failing scenario(rc user id is incorrect)
			VerifyOpportunityIdRestApi.OpportunityValidationRequest requestBodyEmptyRcUserId = new VerifyOpportunityIdRestApi.OpportunityValidationRequest();
	    	requestBodyEmptyRcUserId.oppId = opp.Id;
	    	requestBodyEmptyRcUserId.accUserId = '';
	    	req.requestBody = Blob.valueOf(JSON.serialize(requestBodyEmptyRcUserId));
	    	RestContext.request = req;

	    	// Call rest service
	    	VerifyOpportunityIdRestApi.verifyOpportunityId();
    		RestResponse serviceResponseFail2 = RestContext.response;

			VerifyOpportunityIdRestApi.OpportunityValidationResponse validationRcUserIdFail = (VerifyOpportunityIdRestApi.OpportunityValidationResponse)JSON.deserialize(serviceResponseFail2.responseBody.toString(), VerifyOpportunityIdRestApi.OpportunityValidationResponse.class);
			// Check response
			System.assertEquals(opp.Id, validationRcUserIdFail.oppId);
			System.assertEquals('', validationRcUserIdFail.accUserId);
			System.assertEquals(false, validationRcUserIdFail.isValidId);
			System.assertEquals('You must specify not blank account Enterprise Account id', validationRcUserIdFail.errorMessage);
    	Test.stopTest();
	}
}