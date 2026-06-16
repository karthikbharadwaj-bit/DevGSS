@isTest
public class Test_CostCenterLineItemTriggerHandler {
    @isTest
    static void testCopyLineItemFromMasterToTechnicalQli() {
        Triggers.switchOff();
        TestDataGenerator.MultiproductStructure mpStruct = new TestDataGenerator.MultiproductStructure();

        Product2 product = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                    Product2.Name => 'Test_Product1',
                    Product2.Charge_Term__c => Product2Helper.CHARGE_TERM_ONE_TIME,
                    Product2.IsActive => true,
                    Product2.Feature__c => 17,
                    Product2.Family => Product2Helper.FAMILY_DISCOUNTED_PHONES
            })
            .create()
            .getRecord();

        PricebookEntry standardPricebookEntry = (PricebookEntry) new SObjectBuilder(PricebookEntry.SObjectType)
                .setFields(new Map<SObjectField, Object> {
                        PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                        PricebookEntry.Product2Id => product.Id,
                        PricebookEntry.UnitPrice => 100,
                        PricebookEntry.IsActive => true,
                        PricebookEntry.UseStandardPrice => false
                })
                .create()
                .getRecord();

        QuoteLineItem masterQli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                QuoteLineItem.QuoteId => mpStruct.masterQuote.Id,
                QuoteLineItem.Product2Id => product.Id,
                QuoteLineItem.Deactivated__c => false,
                QuoteLineItem.PricebookEntryId => standardPricebookEntry.Id,
                QuoteLineItem.Quantity => 4,
                QuoteLineItem.NewQuantity__c => 3,
                QuoteLineItem.UnitPrice => 10,
                QuoteLineItem.Discount => 2,
                QuoteLineItem.IsMultiProductTechnicalQLI__c => false
            })
            .create()
            .getRecord();

        Tax_Location__c taxLocation = (Tax_Location__c) new SObjectBuilder(Tax_Location__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Tax_Location__c.Name => 'test tax location',
                Tax_Location__c.Country__c => 'United States',
                Tax_Location__c.State__c => 'New York',
                Tax_Location__c.City__c => 'Islip Terrace',
                Tax_Location__c.BillingId__c => 'test address Id',
                Tax_Location__c.ZipCode__c => '11752'
            })
            .create()
            .getRecord();

        Cost_Center__c costCenter = (Cost_Center__c) new SObjectBuilder(Cost_Center__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Cost_Center__c.Name => 'test cost center',
                Cost_Center__c.Quote__c => mpStruct.masterQuote.Id,
                Cost_Center__c.Tax_Location__c => taxLocation.Id,
                Cost_Center__c.AddressId__c => 'test address Id',
                Cost_Center__c.BillingId__c => 'test billing id'
            })
            .create()
            .getRecord();

        Triggers.switchOn();
        QuoteLineItem techQli = mpStruct.technicalQLIs.values().get(0).get(0);
        techQli.MasterQLI__c = masterQli.Id;
        update techQli;

        Area_Codes__c ac = (Area_Codes__c) new SObjectBuilder(Area_Codes__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Area_Codes__c.Name => 'test area code'
            })
            .create()
            .getRecord();

        Test.startTest();
            Cost_Center_Line_Item__c ccli = (Cost_Center_Line_Item__c) new SObjectBuilder(Cost_Center_Line_Item__c.SObjectType)
                .setFields(new Map<SObjectField, Object> {
                    Cost_Center_Line_Item__c.AreaCode__c => ac.Id,
                    Cost_Center_Line_Item__c.BundleElementId__c => '5',
                    Cost_Center_Line_Item__c.Cost_Center__c => costCenter.Id,
                    Cost_Center_Line_Item__c.ElementId__c => '10',
                    Cost_Center_Line_Item__c.Quantity__c => 1,
                    Cost_Center_Line_Item__c.SortOrder__c => 99,
                    Cost_Center_Line_Item__c.Quote_Line_Item__c => masterQli.Id
                })
                .create()
                .getRecord();

            List<Cost_Center_Line_Item__c> technicalCostCenterItems = (List<Cost_Center_Line_Item__c>) new CostCenterLineItemSelector()
                .selectTechnicalItemsByMasterQliId(new List<Object> {new List<Id> {masterQli.Id}})
                .executeQuery();
        Test.stopTest();

        System.assert(technicalCostCenterItems.size() == 1, 'Only one technical Cost Center Line Item should be created');
        System.assertEquals(techQli.Id, technicalCostCenterItems.get(0).Quote_Line_Item__c, 'Technical Cost Center Line Item is related to the wrong QLI');
    }

    @isTest
    static void testUpdateLineItemFromMasterToTechnicalQli() {
        Triggers.switchOff();
        TestDataGenerator.MultiproductStructure mpStruct = new TestDataGenerator.MultiproductStructure();

        Product2 product = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                    Product2.Name => 'Test_Product1',
                    Product2.Charge_Term__c => Product2Helper.CHARGE_TERM_ONE_TIME,
                    Product2.IsActive => true,
                    Product2.Feature__c => 17,
                    Product2.Family => Product2Helper.FAMILY_DISCOUNTED_PHONES
            })
            .create()
            .getRecord();

        PricebookEntry standardPricebookEntry = (PricebookEntry) new SObjectBuilder(PricebookEntry.SObjectType)
                .setFields(new Map<SObjectField, Object> {
                        PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                        PricebookEntry.Product2Id => product.Id,
                        PricebookEntry.UnitPrice => 100,
                        PricebookEntry.IsActive => true,
                        PricebookEntry.UseStandardPrice => false
                })
                .create()
                .getRecord();

        QuoteLineItem masterQli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                QuoteLineItem.QuoteId => mpStruct.masterQuote.Id,
                QuoteLineItem.Product2Id => product.Id,
                QuoteLineItem.Deactivated__c => false,
                QuoteLineItem.PricebookEntryId => standardPricebookEntry.Id,
                QuoteLineItem.Quantity => 4,
                QuoteLineItem.NewQuantity__c => 3,
                QuoteLineItem.UnitPrice => 10,
                QuoteLineItem.Discount => 2,
                QuoteLineItem.IsMultiProductTechnicalQLI__c => false
            })
            .create()
            .getRecord();

        Tax_Location__c taxLocation = (Tax_Location__c) new SObjectBuilder(Tax_Location__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Tax_Location__c.Name => 'test tax location',
                Tax_Location__c.Country__c => 'United States',
                Tax_Location__c.State__c => 'New York',
                Tax_Location__c.City__c => 'Islip Terrace',
                Tax_Location__c.BillingId__c => 'test address Id',
                Tax_Location__c.ZipCode__c => '11752'
            })
            .create()
            .getRecord();

        Cost_Center__c costCenter = (Cost_Center__c) new SObjectBuilder(Cost_Center__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Cost_Center__c.Name => 'test cost center',
                Cost_Center__c.Quote__c => mpStruct.masterQuote.Id,
                Cost_Center__c.Tax_Location__c => taxLocation.Id,
                Cost_Center__c.AddressId__c => 'test address Id',
                Cost_Center__c.BillingId__c => 'test billing id'
            })
            .create()
            .getRecord();

        Triggers.switchOn();
        QuoteLineItem techQli = mpStruct.technicalQLIs.values().get(0).get(0);
        techQli.MasterQLI__c = masterQli.Id;
        update techQli;

        Area_Codes__c ac = (Area_Codes__c) new SObjectBuilder(Area_Codes__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Area_Codes__c.Name => 'test area code'
            })
            .create()
            .getRecord();

        Test.startTest();
            Cost_Center_Line_Item__c masterCcli = (Cost_Center_Line_Item__c) new SObjectBuilder(Cost_Center_Line_Item__c.SObjectType)
                .setFields(new Map<SObjectField, Object> {
                    Cost_Center_Line_Item__c.AreaCode__c => ac.Id,
                    Cost_Center_Line_Item__c.BundleElementId__c => '5',
                    Cost_Center_Line_Item__c.Cost_Center__c => costCenter.Id,
                    Cost_Center_Line_Item__c.ElementId__c => '10',
                    Cost_Center_Line_Item__c.Quantity__c => 1,
                    Cost_Center_Line_Item__c.SortOrder__c => 99,
                    Cost_Center_Line_Item__c.Quote_Line_Item__c => masterQli.Id
                })
                .create()
                .getRecord();

            masterCcli.Quantity__c = 100;
            update masterCcli;

            List<Cost_Center_Line_Item__c> technicalCostCenterItems = (List<Cost_Center_Line_Item__c>) new CostCenterLineItemSelector()
                .selectTechnicalItemsByMasterQliId(new List<Object> {new List<Id> {masterQli.Id}})
                .executeQuery();
        Test.stopTest();

        System.assert(technicalCostCenterItems.size() == 1, 'Only one technical area code line item should be created');
        System.assertEquals(masterCcli.Quantity__c, technicalCostCenterItems.get(0).Quantity__c,
            'Quantity on technical Area Code Line Item should be the same as on master Area Code Line Item');
        System.assertEquals(techQli.Id, technicalCostCenterItems.get(0).Quote_Line_Item__c, 'Technical Cost Center Line Item is related to the wrong QLI');
    }

    @isTest
    static void testDeleteLineItemsOnTechnicalQlisOnMasterDelete() {
        Triggers.switchOff();
        TestDataGenerator.MultiproductStructure mpStruct = new TestDataGenerator.MultiproductStructure();

        Product2 product = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                    Product2.Name => 'Test_Product1',
                    Product2.Charge_Term__c => Product2Helper.CHARGE_TERM_ONE_TIME,
                    Product2.IsActive => true,
                    Product2.Feature__c => 17,
                    Product2.Family => Product2Helper.FAMILY_DISCOUNTED_PHONES
            })
            .create()
            .getRecord();

        PricebookEntry standardPricebookEntry = (PricebookEntry) new SObjectBuilder(PricebookEntry.SObjectType)
                .setFields(new Map<SObjectField, Object> {
                        PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                        PricebookEntry.Product2Id => product.Id,
                        PricebookEntry.UnitPrice => 100,
                        PricebookEntry.IsActive => true,
                        PricebookEntry.UseStandardPrice => false
                })
                .create()
                .getRecord();

        QuoteLineItem masterQli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                QuoteLineItem.QuoteId => mpStruct.masterQuote.Id,
                QuoteLineItem.Product2Id => product.Id,
                QuoteLineItem.Deactivated__c => false,
                QuoteLineItem.PricebookEntryId => standardPricebookEntry.Id,
                QuoteLineItem.Quantity => 4,
                QuoteLineItem.NewQuantity__c => 3,
                QuoteLineItem.UnitPrice => 10,
                QuoteLineItem.Discount => 2,
                QuoteLineItem.IsMultiProductTechnicalQLI__c => false
            })
            .create()
            .getRecord();

        Tax_Location__c taxLocation = (Tax_Location__c) new SObjectBuilder(Tax_Location__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Tax_Location__c.Name => 'test tax location',
                Tax_Location__c.Country__c => 'United States',
                Tax_Location__c.State__c => 'New York',
                Tax_Location__c.City__c => 'Islip Terrace',
                Tax_Location__c.BillingId__c => 'test address Id',
                Tax_Location__c.ZipCode__c => '11752'
            })
            .create()
            .getRecord();

        Cost_Center__c costCenter = (Cost_Center__c) new SObjectBuilder(Cost_Center__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Cost_Center__c.Name => 'test cost center',
                Cost_Center__c.Quote__c => mpStruct.masterQuote.Id,
                Cost_Center__c.Tax_Location__c => taxLocation.Id,
                Cost_Center__c.AddressId__c => 'test address Id',
                Cost_Center__c.BillingId__c => 'test billing id'
            })
            .create()
            .getRecord();

        Triggers.switchOn();
        QuoteLineItem techQli = mpStruct.technicalQLIs.values().get(0).get(0);
        techQli.MasterQLI__c = masterQli.Id;
        update techQli;

        Area_Codes__c ac = (Area_Codes__c) new SObjectBuilder(Area_Codes__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Area_Codes__c.Name => 'test area code'
            })
            .create()
            .getRecord();

        Test.startTest();
            Cost_Center_Line_Item__c ccli = (Cost_Center_Line_Item__c) new SObjectBuilder(Cost_Center_Line_Item__c.SObjectType)
                .setFields(new Map<SObjectField, Object> {
                    Cost_Center_Line_Item__c.AreaCode__c => ac.Id,
                    Cost_Center_Line_Item__c.BundleElementId__c => '5',
                    Cost_Center_Line_Item__c.Cost_Center__c => costCenter.Id,
                    Cost_Center_Line_Item__c.ElementId__c => '10',
                    Cost_Center_Line_Item__c.Quantity__c => 1,
                    Cost_Center_Line_Item__c.SortOrder__c => 99,
                    Cost_Center_Line_Item__c.Quote_Line_Item__c => masterQli.Id
                })
                .create()
                .getRecord();

            delete ccli;

            List<Cost_Center_Line_Item__c> technicalCostCenterItems = (List<Cost_Center_Line_Item__c>) new CostCenterLineItemSelector()
                .selectTechnicalItemsByMasterQliId(new List<Object> {new List<Id> {masterQli.Id}})
                .executeQuery();
        Test.stopTest();

        System.assert(technicalCostCenterItems.isEmpty(), 'Technical Cost Center Line Item should be deleted');
    }
}