@isTest
private class Test_DomainHandlerFactory {
    @isTest
    static void testGetHandler_NullDomain() {
        try {
            Test.startTest();
            DomainHandlerFactory.getHandler(null);
            Test.stopTest();
            System.assert(false, 'Expected IllegalArgumentException for null domain');
        } catch (IllegalArgumentException e) {
            System.assertEquals('Domain name cannot be null or empty', e.getMessage(), 'Error message should match');
        }
    }

    @isTest
    static void testGetHandler_EmptyDomain() {
        try {
            Test.startTest();
            DomainHandlerFactory.getHandler('');
            Test.stopTest();
            System.assert(false, 'Expected IllegalArgumentException for empty domain');
        } catch (IllegalArgumentException e) {
            System.assertEquals('Domain name cannot be null or empty', e.getMessage(), 'Error message should match');
        }
    }

    @isTest
    static void testGetHandler_BlankDomain() {
        try {
            Test.startTest();
            DomainHandlerFactory.getHandler('   ');
            Test.stopTest();
            System.assert(false, 'Expected IllegalArgumentException for blank domain');
        } catch (IllegalArgumentException e) {
            System.assertEquals('Domain name cannot be null or empty', e.getMessage(), 'Error message should match');
        }
    }

    @isTest
    static void testGetHandler_InvalidDomain() {
        try {
            Test.startTest();
            DomainHandlerFactory.getHandler('invalid-domain');
            Test.stopTest();
            System.assert(false, 'Expected ApiDomainNotFoundException for invalid domain');
        } catch (ApiGateway.ApiDomainNotFoundException e) {
            System.assertEquals('No handler registered for domain: invalid-domain', e.getMessage(), 'Error message should match');
        }
    }
}