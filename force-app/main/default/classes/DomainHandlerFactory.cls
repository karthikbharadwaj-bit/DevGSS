/**
 * Factory for creating domain handlers
 * Maps domain names to their handler implementations
 * Implements singleton pattern with thread safety
 */
public class DomainHandlerFactory {

    // Map domain names to their handler implementations
    // Example: 'domain-name' => DomainNameHandler.class
    private Map<String, Type> handlerMap = new Map<String, Type>{
        'quote-manager' => QuoteManagerDomainHandler.class,
        'qli-manager' => QuoteLineItemManagerDomainHandler.class,
        'settings' => SettingsDomainHandler.class
    };

    // For testing purposes - allow injection of a mock handler
    @TestVisible
    private static Map<String, IDomainHandler> mockHandlers = new Map<String, IDomainHandler>();

    public static IDomainHandler getHandler(String domainName) {
        if (String.isBlank(domainName)) {
            throw new IllegalArgumentException('Domain name cannot be null or empty');
        }

        // Check if a mock handler has been registered for this domain
        if (Test.isRunningTest() && mockHandlers.containsKey(domainName)) {
            return mockHandlers.get(domainName);
        }

        Type handlerType = new DomainHandlerFactory().handlerMap.get(domainName);
        if (handlerType == null) {
            throw new ApiGateway.ApiDomainNotFoundException('No handler registered for domain: ' + domainName);
        }

        return (IDomainHandler)handlerType.newInstance();
    }

    // For testing - allows registering a mock handler
    @TestVisible
    public static void registerMockHandler(String domainName, IDomainHandler mockHandler) {
        mockHandlers.put(domainName, mockHandler);
    }

    // For testing - clears all mock handlers
    @TestVisible
    public static void clearMockHandlers() {
        mockHandlers.clear();
    }
}