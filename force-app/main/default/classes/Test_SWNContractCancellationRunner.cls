@IsTest
private class Test_SWNContractCancellationRunner {
    // using Contract.sObjectType to get longer unique Ids for billing contracts
    private static final IValueProvider CONTRACT_ID_PROVIDER = ValueProviderBuilder.provideDummyId(Contract.sObjectType);
    private static final String DISCOUNT_GROUP_ID = (String) CONTRACT_ID_PROVIDER.getValue();
    private static final Id DUMMY_QUOTE_ID = (Id) ValueProviderBuilder.provideDummyId(Quote.sObjectType).getValue();

    private static final String BILLING_ID = 'billingId';
    private static final String NGBS_PACKAGE_ID = 'NGBS_PACKAGE_ID';
    private static final String DISCOUNT_GROUP_PRIORITY = 'A';
    private static final String INNER_PACKAGE_INFO_ID = '1389379001';
    private static final String PACKAGE_INFO_VERSION = '1';
    private static final String PACKAGE_INFO_CATALOG_ID = '18';
    private static final String CONTRACT_CANCELLATION_ENDPOINT_MPL = NGBSAPI.NGBS_ACCOUNT_MANAGER + '/' + BILLING_ID + '/package/' + INNER_PACKAGE_INFO_ID + '/contract';
    private static final String CONTRACT_CANCELLATION_ENDPOINT_MPUB = NGBSAPI.NGBS_ACCOUNT_MANAGER + '/' + BILLING_ID + '/contract';

    private static final String ASSERT_MSG_CANCEL_CONTRACT_IS_NOT_NULL = 'cancelContract should have a response';
    private static final String ASSERT_MSG_SHOULD_RETURN_SUCCESS = 'should return a successful response, if nothing wrong has happened';
    private static final String ASSERT_MSG_NO_MESSAGES_ON_SUCCESS = 'should not return any messages on a success';

    enum MockedRequest {
        GET_DISCOUNTS,
        DELETE_DISCOUNTS,
        CONTRACT_CANCELLATION_MPL,
        CONTRACT_CANCELLATION_MPUB
    }

    class ContractCancellationRequestsMock implements HttpCalloutMock {
        public Map<MockedRequest, List<String>> passedParametersToRequests = new Map<MockedRequest, List<String>>();

        String body = '';
        Integer statusCode = 200;

        public Boolean wasRequestMade(MockedRequest request) {
            return passedParametersToRequests.containsKey(request);
        }
        public Boolean wasRequestMadeWith(MockedRequest request, String input) {
            return wasRequestMade(request) && passedParametersToRequests.get(request).contains(input);
        }
        public Boolean wasAnyRequestMade() {
            return !passedParametersToRequests.isEmpty();
        }

        public HTTPResponse respond(HTTPRequest req) {
            String endpoint = req.getEndpoint();
            String method = req.getMethod();

            if (method == HttpHelper.METHOD_GET) {
                handleGet(endpoint);
            } else if (method == HttpHelper.METHOD_DELETE) {
                handleDelete(endpoint);
            } else {
                raiseHandlerNotImplementedException(method, endpoint);
            }

            return createResponse();
        }

        private void handleGet(String endpoint) {
            if (endpoint == NGBSAPI.getDiscountTemplateGroupEndpoint(BILLING_ID, NGBS_PACKAGE_ID)) {
                handleGetDiscountsResponse();
            } else {
                raiseHandlerNotImplementedException(HttpHelper.METHOD_GET, endpoint);
            }
        }
        private void handleDelete(String endpoint) {
            if (endpoint.contains(NGBSAPI.getDiscountTemplateGroupEndpoint(BILLING_ID, NGBS_PACKAGE_ID))) {
                handleDeletionRequest(endpoint, MockedRequest.DELETE_DISCOUNTS);
            } else if (endpoint.contains(CONTRACT_CANCELLATION_ENDPOINT_MPL)) {
                handleDeletionRequest(endpoint, MockedRequest.CONTRACT_CANCELLATION_MPL);
            } else if (endpoint.contains(CONTRACT_CANCELLATION_ENDPOINT_MPUB)) {
                handleDeletionRequest(endpoint, MockedRequest.CONTRACT_CANCELLATION_MPUB);
            } else {
                raiseHandlerNotImplementedException(HttpHelper.METHOD_DELETE, endpoint);
            }
        }

        private void handleGetDiscountsResponse() {
            this.passedParametersToRequests.put(MockedRequest.GET_DISCOUNTS, null);
            setResponseBody(new List<NGBS_Discount.DiscountTemplateGroup> {buildDiscountGroup()});
            this.statusCode = 200;
        }
        private void handleDeletionRequest(String endpoint, MockedRequest requestType) {
            if (!passedParametersToRequests.containsKey(requestType)) {
                passedParametersToRequests.put(requestType, new List<String>());
            }
            passedParametersToRequests.get(requestType).add(endpoint.substringAfterLast('/'));
            this.statusCode = 200;
        }

        private void raiseHandlerNotImplementedException(String method, String endpoint) {
            String endpointPart = String.isBlank(endpoint) ? '' : ' ' + endpoint + ' endpoint';
            Assert.fail(
                'Not Implemented Error: ' + method + endpointPart + ' is not implemented in the ContractCancellationMock'
            );
        }

        private void setResponseBody(Object responseBody) {
            this.body = JSON.serialize(responseBody);
        }

        private HttpResponse createResponse() {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(this.statusCode);
            res.setBody(this.body);

            return res;
        }
    }

    private static BillingWrappers.BillingContract buildBillingContract(Boolean isActive) {
        BillingWrappers.BillingContract contract = new BillingWrappers.BillingContract();
        contract.startBillingCycleNumber = isActive ? 1 : -1;
        contract.id = (Id) CONTRACT_ID_PROVIDER.getValue();
        return contract;
    }
    private static BillingWrappers.PackageInfo buildPackageInfo() {
        BillingWrappers.PackageInfo innerPackageInfo = new BillingWrappers.PackageInfo();
        innerPackageInfo.id = INNER_PACKAGE_INFO_ID;
        innerPackageInfo.catalogId = PACKAGE_INFO_CATALOG_ID;
        innerPackageInfo.version = PACKAGE_INFO_VERSION;
        return innerPackageInfo;
    }
    private static NGBS_Discount.DiscountTemplateGroup buildDiscountGroup() {
        NGBS_Discount.DiscountTemplateGroup discountGroup = new NGBS_Discount.DiscountTemplateGroup();
        discountGroup.id = DISCOUNT_GROUP_ID;
        discountGroup.priority = DISCOUNT_GROUP_PRIORITY;
        discountGroup.target = buildPackageInfo();
        return discountGroup;
    }
    private static SWNDataCollector buildDataCollector() {
        Quote testQt = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setFields(new Map<SOBjectField, Object> {
                Quote.Id => DUMMY_QUOTE_ID,
                Quote.Package_Info__c => new SWNMockBuilders.PackageInfoBuilder()
                    .withInnerPackageInfo(buildPackageInfo())
                    .buildAsJson()
            })
            .build()
            .getRecord();

        BillingWrappers.NGBSAccountPackage ngbsPackage = new BillingWrappers.NGBSAccountPackage();
        ngbsPackage.id = NGBS_PACKAGE_ID;

        SWNDataCollector sdc = new SWNDataCollector();
        sdc.currentStep = SWNStep.buildContractCancellationStep();
        sdc.ngbsPackage = ngbsPackage;
        sdc.packageId = NGBS_PACKAGE_ID;
        sdc.billingId = BILLING_ID;
        sdc.qt = testQt;
        return sdc;
    }
    private static SWNContractCancellationRunner buildRunner() {
        return new SWNContractCancellationRunner(DUMMY_QUOTE_ID, SWNStep.CONTRACT_CANCELLATION);
    }
    private static SWNContractCancellationRunner buildRunnerForCancellation(Boolean isMPUB) {
        BillingWrappers.BillingContract activeContract = buildBillingContract(true);
        SWNContractCancellationRunner runner = buildRunner();
        runner.sdc = buildDataCollector();
        runner.sdc.billingContracts = new List<BillingWrappers.BillingContract> {activeContract, buildBillingContract(false)};
        runner.sdc.isMPUB = isMPUB;

        return runner;
    }
    private static SWNContractCancellationRunner buildRunnerForSync() {
        Account acc = (Account) new SObjectBuilder(Account.sObjectType)
            .setFields(new Map<SOBjectField, Object> {
                Account.Active_Sales_Agreement__c => DUMMY_QUOTE_ID,
                Account.Id => ValueProviderBuilder.provideDummyId(Account.sObjectType)
            })
            .build()
            .getRecord();
        Opportunity opp = new Opportunity(Account = acc);
        opp.AccountId = acc.Id;

        SWNContractCancellationRunner runner = buildRunnerForCancellation(true);
        runner.sdc.opp = opp;
        return runner;
    }

    private static void assertCallout(ContractCancellationRequestsMock mock, MockedRequest requestType, String expectedInput) {
        Assert.isTrue(mock.wasRequestMade(requestType), requestType + ' is expected to be made');
        Assert.isTrue(
            mock.wasRequestMadeWith(requestType, expectedInput),
            requestType + ' is expected to be made for "' + expectedInput + '", but was not'
        );
    }
    private static void assertDiscountsDeleteCallouts(ContractCancellationRequestsMock mock) {
        Assert.isTrue(mock.wasRequestMade(MockedRequest.GET_DISCOUNTS), 'deleteCurrentDiscounts should make a request to get discounts');
        Assert.isTrue(mock.wasRequestMade(MockedRequest.DELETE_DISCOUNTS), 'deleteCurrentDiscounts should make a request to delete discounts');
        assertCallout(mock, MockedRequest.DELETE_DISCOUNTS, DISCOUNT_GROUP_ID);
    }
    private static void assertContractCancellationResponse(SWNContractCancellationRunner runner, ContractCancellationRequestsMock mock) {
        Assert.isNotNull(runner.res, ASSERT_MSG_CANCEL_CONTRACT_IS_NOT_NULL);
        Assert.isTrue(runner.res.isSuccess(), 'cancelContract() should return a successful response');
        Assert.areEqual(1, runner.res.messages.size(), 'cancelContract should return a message when successfully canceled');
        Assert.areEqual(
            SWNHelper.SUCCESS_MESSAGES_BUILDER.getSWNMessage(SWNMessageHelper.LabelMessage.CANCEL_CONTRACT_SUCCESS).header,
            runner.res.messages[0].message,
            'Wrong message was returned for a successful cancellation'
        );
        BillingWrappers.BillingContract activeContract = runner.sdc.billingContracts[0];
        assertCallout(
            mock,
            runner.sdc.isMPUB ? MockedRequest.CONTRACT_CANCELLATION_MPUB : MockedRequest.CONTRACT_CANCELLATION_MPL,
            activeContract.id
        );
    }

    @TestSetup
    static void setup() {
        new SObjectBuilder(NGBS_Settings__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                NGBS_Settings__c.BaseEndpoint__c => 'https://testapi',
                NGBS_Settings__c.AccountManagerPath__c => '/restapi/account-manager/v1.0',
                NGBS_Settings__c.Login__c => '123',
                NGBS_Settings__c.Password__c => '456'
            })
            .create();
    }

    // TODO: cover negative test scenario, e.g. an exception occurred during a callout
    @isTest
    static void testRun() {
        SWNContractCancellationRunner runner = buildRunnerForSync();

        ContractCancellationRequestsMock mock = new ContractCancellationRequestsMock();
        Test.setMock(HttpCalloutMock.class, mock);
        Test.startTest();
            runner.run();
        Test.stopTest();

        Assert.isTrue(runner.sdc.currentStep.isStepCompletedSuccessfully, 'The Contract cancellation step should be completed successfully');
        assertContractCancellationResponse(runner, mock);
        assertDiscountsDeleteCallouts(mock);

        Map<String, Object> quoteFieldsToUpdate = runner.sdc.currentStep.quoteFieldsToUpdate;
        Assert.isTrue(
            quoteFieldsToUpdate.containsKey(Quote.Id.toString()),
            'A given Account\'s Active Sales Agreement should be updated'
        );
        Assert.areEqual(
            quoteFieldsToUpdate.get(Quote.Status.toString()),
            QuoteHelper.QUOTE_STATUS_TERMINATED,
            'The Active Sales Agreement should be terminated'
        );

        Map<String, Object> accountFieldsToUpdate = runner.sdc.currentStep.accountFieldsToUpdate;
        Assert.isTrue(
            accountFieldsToUpdate.containsKey(Account.Id.toString()),
            'A given Account should be updated'
        );
        Assert.isNull(
            accountFieldsToUpdate.get(Account.Active_Sales_Agreement__c.toString()),
            'The Active Sales Agreement should be removed from the Account'
        );
    }

    @isTest
    static void testCancelContractWhenNoPackageInfo() {
        SWNContractCancellationRunner runner = buildRunner();
        runner.sdc.qt = new Quote();

        ContractCancellationRequestsMock mock = new ContractCancellationRequestsMock();
        Test.setMock(HttpCalloutMock.class, mock);
        Test.startTest();
            runner.cancelContract();
        Test.stopTest();

        Assert.isNotNull(runner.res, ASSERT_MSG_CANCEL_CONTRACT_IS_NOT_NULL);
        Assert.isTrue(runner.res.isSuccess(), 'Even though cancelContract() has not canceled anything, it should return a successful response');
        Assert.areEqual(1, runner.res.messages.size(), 'cancelContract should return a message when there is no package info');
        Assert.areEqual(
            SWNHelper.ERROR_MESSAGES_BUILDER.getSWNMessage(SWNMessageHelper.LabelMessage.CANCEL_CONTRACT_IF_NO_PKG_INFO_ON_QUOTE).header,
            runner.res.messages[0].message,
            'The message should be about missing package info'
        );
        Assert.isFalse(mock.wasAnyRequestMade(), 'When there is no package info, no requests should be made');
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testCancelContractWhenMPL() {
        SWNContractCancellationRunner runner = buildRunnerForCancellation(false);

        ContractCancellationRequestsMock mock = new ContractCancellationRequestsMock();
        Test.setMock(HttpCalloutMock.class, mock);
        Test.startTest();
            runner.cancelContract();
        Test.stopTest();

        assertContractCancellationResponse(runner, mock);
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testCancelContractWhenMPUB() {
        SWNContractCancellationRunner runner = buildRunnerForCancellation(true);

        ContractCancellationRequestsMock mock = new ContractCancellationRequestsMock();
        Test.setMock(HttpCalloutMock.class, mock);
        Test.startTest();
            runner.cancelContract();
        Test.stopTest();

        assertContractCancellationResponse(runner, mock);
    }

    @isTest
    static void testGetActiveContractId() {
        BillingWrappers.BillingContract activeContract = buildBillingContract(true);
        BillingWrappers.BillingContract deactivatedContract = buildBillingContract(false);
        List<BillingWrappers.BillingContract> billingContracts = new List<BillingWrappers.BillingContract> {
            activeContract,
            deactivatedContract
        };
        List<BillingWrappers.BillingContract> nonActiveBillingContracts = new List<BillingWrappers.BillingContract> {
            deactivatedContract
        };

        SWNContractCancellationRunner runner = buildRunner();
        Test.startTest();
            String resultWhenNoActiveContract = runner.getActiveContractId(nonActiveBillingContracts);
            String resultWhenActiveContract = runner.getActiveContractId(billingContracts);
        Test.stopTest();

        Assert.isTrue(String.isBlank(resultWhenNoActiveContract), 'When there are no active contracts, the method should return null');
        Assert.isFalse(String.isBlank(resultWhenActiveContract), 'When there is an active contract, the method should return the contract ID');
        Assert.areEqual(activeContract.id, resultWhenActiveContract, 'The method should return the ID of the active contract');
    }

    @isTest
    static void testDeleteCurrentDiscounts() {
        SWNContractCancellationRunner runner = buildRunner();
        runner.sdc = buildDataCollector();

        ContractCancellationRequestsMock mock = new ContractCancellationRequestsMock();
        Test.setMock(HttpCalloutMock.class, mock);
        Test.startTest();
            Response result = runner.deleteCurrentDiscounts();
        Test.stopTest();

        Assert.isNotNull(result, 'deleteCurrentDiscounts should return a response');
        Assert.isTrue(result.isSuccess(), 'deleteCurrentDiscounts ' + ASSERT_MSG_SHOULD_RETURN_SUCCESS);
        Assert.isTrue(result.messages.isEmpty(), 'deleteCurrentDiscounts ' + ASSERT_MSG_NO_MESSAGES_ON_SUCCESS);
        assertDiscountsDeleteCallouts(mock);
    }
}