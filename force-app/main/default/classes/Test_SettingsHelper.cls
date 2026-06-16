@isTest
public with sharing class Test_SettingsHelper {
    @isTest static void testGetEndpointsSettings() {
        new SObjectBuilder(EndpointsSettings__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                EndpointsSettings__c.DocusignCLMAccountId__c => 'testid',
                EndpointsSettings__c.DocuSign_CLM_Endpoint__c => 'http://testlink1.com',
                EndpointsSettings__c.Fax_CA_SignUp_Endpoint__c => 'http://testlink2.com',
                EndpointsSettings__c.Fax_US_SignUp_Endpoint__c => 'http://testlink3.com'
            })
            .create();

        EndpointsSettings__c settings = SettingsHelper.getEndpointsSettings();

        System.assertEquals('testid', settings.DocusignCLMAccountId__c);
        System.assertEquals('http://testlink1.com', settings.DocuSign_CLM_Endpoint__c);
        System.assertEquals('http://testlink2.com', settings.Fax_CA_SignUp_Endpoint__c);
        System.assertEquals('http://testlink3.com', settings.Fax_US_SignUp_Endpoint__c);
    }

    @isTest static void testGetBrandToAllowedCountryMapping() {
        System.assert(String.isNotBlank(SettingsHelper.getBrandToAllowedCountryMapping()));
    }
}