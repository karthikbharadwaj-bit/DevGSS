@isTest
public class TestBatchJobSubBrands {

    @TestSetup
    static void setup() {
        Triggers.switchOff();
        new SObjectBuilder(SubBrandsMapping__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                SubBrandsMapping__c.Name => 'Test Name',
                SubBrandsMapping__c.Sub_Brand__c => '1234.AWS_RCUS',
                SubBrandsMapping__c.Brand__c => 'RingCentral Inc.',
                SubBrandsMapping__c.Country__c => 'United States',
                SubBrandsMapping__c.PartnerID__c => '111'
            })
            .create();

        new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => 'Test Partner Account',
                Account.BillingCountry => 'United States',
                Account.CurrencyIsoCode => 'USD',
                Account.ParentId => null,
                Account.Ultimate_Account__c => null,
                Account.Type => 'Partner',
                Account.Partner_ID__c => '111',
                Account.RC_Brand__c => 'RingCentral Inc.'
            })
            .create();

        Triggers.switchOn();
    }

    @isTest
    static void testSubBrands() {
        Account acc = [SELECT Sub_Brands_Permitted_To_Sell__c FROM Account][0];
        System.assertEquals(null, acc.Sub_Brands_Permitted_To_Sell__c, 'Sub_Brands_Permitted_To_Sell__c should be null');

        Test.startTest();
        BatchJobSubBrands job = new BatchJobSubBrands();
        job.execute(null);
        Test.stopTest();

        acc = [SELECT Sub_Brands_Permitted_To_Sell__c FROM Account][0];
        System.assertEquals('1234.AWS_RCUS', acc.Sub_Brands_Permitted_To_Sell__c, 'Sub_Brands_Permitted_To_Sell__c should be populated');
    }
}