@isTest
public class Test_RCQuoteTemplateSelector {
    @TestSetup
    static void prepareData(){
        RC_Quote_Template__c temp1 = (RC_Quote_Template__c) new SObjectBuilder(RC_Quote_Template__c.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                RC_Quote_Template__c.Name => 'NDA',
                RC_Quote_Template__c.Sorting_Order__c => 1,
                RC_Quote_Template__c.Description__c => 'NDA',
                RC_Quote_Template__c.Brand__c => RingCentralHelper.BRAND_RINGCENTRAL,
                RC_Quote_Template__c.Active__c => true,
                RC_Quote_Template__c.ObjectName__c => 'Account',
                RC_Quote_Template__c.Available_For_Billing_Countries__c => 'France'
            })
            .build()
            .getRecord();

        RC_Quote_Template__c temp2 = (RC_Quote_Template__c) new SObjectBuilder(RC_Quote_Template__c.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                RC_Quote_Template__c.Name => 'Other',
                RC_Quote_Template__c.Sorting_Order__c => 1,
                RC_Quote_Template__c.Description__c => 'Other',
                RC_Quote_Template__c.Brand__c => RingCentralHelper.BRAND_RINGCENTRAL_AU,
                RC_Quote_Template__c.Active__c => true,
                RC_Quote_Template__c.ObjectName__c => 'Quote',
                RC_Quote_Template__c.Available_For_Billing_Countries__c => 'Australia'
            })
            .build()
            .getRecord();

        insert new List<RC_Quote_Template__c> {temp1, temp2};
    }

    @isTest
    static void testSelectRCQuoteTemplates() {
        List<RC_Quote_Template__c> templates = (List<RC_Quote_Template__c>) new RCQuoteTemplateSelector()
            .selectRCQuoteTemplates()
            .executeQuery();

        System.assertEquals(2, templates.size(), 'Two templates should be selected');
    }

    @isTest
    static void testSelectNdaTemplatesByBillingCountry() {
        String billingCountry = 'France';
        List<RC_Quote_Template__c> templates = (List<RC_Quote_Template__c>) new RCQuoteTemplateSelector()
            .selectNdaTemplatesByBillingCountry(new List<Object>{billingCountry})
            .executeQuery();

        System.assertEquals(1, templates.size(), 'One template should be selected');
    }

    @isTest
    static void testSelectNdaTemplatesById() {
        List<RC_Quote_Template__c> templates = (List<RC_Quote_Template__c>) new RCQuoteTemplateSelector()
            .selectRCQuoteTemplates()
            .executeQuery();

        RC_Quote_Template__c ndaTemplate;
        for (RC_Quote_Template__c t : templates) {
            if (t.Name == 'NDA') {
                ndaTemplate = t;
            }
        }

        List<RC_Quote_Template__c> ndaTemplates = (List<RC_Quote_Template__c>) new RCQuoteTemplateSelector()
            .selectNdaTemplatesById(new List<Object>{ndaTemplate.Id})
            .executeQuery();

        System.assertEquals(1, ndaTemplates.size(), 'One template should be selected');
        System.assertEquals(ndaTemplate.Id, ndaTemplates.get(0).Id, 'French template should be selected');
    }

    @isTest
    static void testSelectNdaTemplatesByBrand() {
        List<RC_Quote_Template__c> templates = (List<RC_Quote_Template__c>) new RCQuoteTemplateSelector()
            .selectNdaTemplatesByBrand(new List<Object> {RingCentralHelper.BRAND_RINGCENTRAL})
            .executeQuery();

        System.assertEquals(1, templates.size(), 'One template should be selected');
        System.assertEquals(RingCentralHelper.BRAND_RINGCENTRAL, templates.get(0).Brand__c, 'French template should be selected');
    }

    @isTest
    static void testSelectNdaTemplatesByBillingCountryAndBrand() {
        List<RC_Quote_Template__c> templates = (List<RC_Quote_Template__c>) new RCQuoteTemplateSelector()
            .selectNdaTemplatesByBillingCountryAndBrand(new List<Object> {'France', RingCentralHelper.BRAND_RINGCENTRAL})
            .executeQuery();

        System.assertEquals(1, templates.size(), 'One template should be selected');
        System.assertEquals(RingCentralHelper.BRAND_RINGCENTRAL, templates.get(0).Brand__c, 'French template should be selected');
    }
}