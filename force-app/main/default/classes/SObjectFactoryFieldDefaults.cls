public with sharing class SObjectFactoryFieldDefaults {
    /**
    * Provides field defaults for the created records. Also create a default empty mappting
    * @param sObjectType a Schema.SObjectType token used for building the records in the {@link SObjectFactory}.
    * @return Map<SObjectType, Map<SObjectField, Object>> with the existing default mapping.
    */
    public static Map<SObjectField, Object> getDefaults(SObjectType sObjectType) {
        return fieldDefaults.containsKey(sObjectType) ?
               fieldDefaults.get(sObjectType) : new Map<SObjectField, Object>();
    }

    /**
    * The Map<SObjectType, Map<SObjectField, Object>> representing field default values.
    * Used in the {@link SObjectFactory} to build the records.
    * PLEASE PROVIDE ONLY REQUIRED FIELDS IN THIS MAPPINGS
    */
    public static Map<SObjectType, Map<SObjectField, Object>> fieldDefaults = new Map<SObjectType, Map<SObjectField, Object>> {
        Account.sObjectType => new Map<SObjectField, Object> {
            Account.Name => 'My Account'
        },
        Contact.sObjectType => new Map<SObjectField, Object> {
            Contact.LastName => 'Doe',
            Contact.Phone => '1234567'
        },
        Opportunity.sObjectType => new Map<SObjectField, Object> {
            Opportunity.Name => ValueProviderBuilder.provideUniqueString(),
            Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY
        },
        Quote.sObjectType => new Map<SObjectField, Object> {
            Quote.Name => ValueProviderBuilder.provideUniqueString()
        },
        Product2.sObjectType => new Map<SObjectField, Object> {
            Product2.Name => ValueProviderBuilder.provideUniqueString()
        },
        Pricebook2.sObjectType => new Map<SObjectField, Object> {
            Pricebook2.Name => ValueProviderBuilder.provideUniqueString()
        },
        PricebookEntry.sObjectType => new Map<SObjectField, Object> {
            PricebookEntry.UnitPrice => ValueProviderBuilder.provideUniqueNumber()
        },
        Lead.sObjectType => new Map<SObjectField, Object> {
            Lead.Email => 'test@fakeemail.com',
            Lead.LastName => ValueProviderBuilder.provideUniqueString(),
            Lead.Company => ValueProviderBuilder.provideUniqueString()
        },
        User.sObjectType => new Map<SObjectField, Object> {
            User.ProfileId => ProfileHelper.PROFILE_ID_SYSADMIN,
            User.isActive => true,
            User.Username => ValueProviderBuilder.provideUniqueEmail(),
            User.Lastname => ValueProviderBuilder.provideUniqueString(),
            User.Email => ValueProviderBuilder.provideUniqueEmail(),
            User.Alias => ValueProviderBuilder.provideUniqueFixedLengthString(5),
            User.CommunityNickname => ValueProviderBuilder.provideUniqueString(),
            User.TimeZoneSidKey => 'America/Los_Angeles',
            User.LocaleSidKey => 'en_US',
            User.EmailEncodingKey => 'UTF-8',
            User.LanguageLocaleKey => 'en_US'
        },
        NGBS_Settings__c.sObjectType => new Map<SObjectField, Object> {
            NGBS_Settings__c.BaseEndpoint__c => 'http://test',
            NGBS_Settings__c.CatalogPath__c => '/catalog',
            NGBS_Settings__c.Login__c => 'salesforce',
            NGBS_Settings__c.Password__c => 'salesforce'
        }
    };
}