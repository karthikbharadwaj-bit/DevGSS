@isTest
public class Test_AssignmentLineItemTriggerHandler {

    @isTest
    static void testCopyLineItemFromMasterToTechnicalQli() {
        Triggers.switchOff();
        TestDataGenerator.MultiproductStructure mpStruct = new TestDataGenerator.MultiproductStructure();
        Triggers.switchOn();

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

        QuoteLineItem masterQliParent = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                QuoteLineItem.QuoteId => mpStruct.masterQuote.Id,
                QuoteLineItem.Deactivated__c => false,
                QuoteLineItem.PricebookEntryId => standardPricebookEntry.Id,
                QuoteLineItem.Quantity => 4,
                QuoteLineItem.NewQuantity__c => 3,
                QuoteLineItem.UnitPrice => 10,
                QuoteLineItem.Discount => 2,
                QuoteLineItem.Product2Id => product.Id,
                QuoteLineItem.IsMultiProductTechnicalQLI__c => false
            })
            .create()
            .getRecord();

        QuoteLineItem masterQliChild = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                QuoteLineItem.QuoteId => mpStruct.masterQuote.Id,
                QuoteLineItem.Deactivated__c => false,
                QuoteLineItem.PricebookEntryId => standardPricebookEntry.Id,
                QuoteLineItem.Quantity => 4,
                QuoteLineItem.NewQuantity__c => 3,
                QuoteLineItem.UnitPrice => 10,
                QuoteLineItem.Discount => 2,
                QuoteLineItem.Product2Id => product.Id,
                QuoteLineItem.IsMultiProductTechnicalQLI__c => false
            })
            .create()
            .getRecord();

        Test.startTest();
            QuoteLineItem techQliParent = mpStruct.technicalQLIs.values().get(0).get(0);
            QuoteLineItem techQliChild = mpStruct.technicalQLIs.values().get(1).get(0);
            techQliParent.MasterQLI__c = masterQliParent.Id;
            techQliChild.MasterQLI__c = masterQliChild.Id;
            update new List<QuoteLineItem> {techQliParent, techQliChild};

            Area_Codes__c ac = (Area_Codes__c) new SObjectBuilder(Area_Codes__c.SObjectType)
                .setFields(new Map<SObjectField, Object> {
                    Area_Codes__c.Name => 'test area code'
                })
                .create()
                .getRecord();

            AssignmentLineItem__c acli = (AssignmentLineItem__c) new SObjectBuilder(AssignmentLineItem__c.SObjectType)
                    .setFields(new Map<SObjectField, Object> {
                        AssignmentLineItem__c.AreaCode__c => ac.Id,
                        AssignmentLineItem__c.Quantity__c => 1,
                        AssignmentLineItem__c.Parent__c => masterQliParent.Id,
                        AssignmentLineItem__c.Child__c => masterQliChild.Id
                    })
                    .create()
                    .getRecord();

            List<AssignmentLineItem__c> technicalAssignmentItems = (List<AssignmentLineItem__c>) new AssignmentLineItemSelector()
                .selectTechnicalItemsByMasterQliId(new List<Object> {new List<Id> {masterQliParent.Id}})
                .executeQuery();
        Test.stopTest();

        System.assert(technicalAssignmentItems.size() == 1, 'Only one technical Assignment Line Item should be created');
        System.assertEquals(techQliParent.Id, technicalAssignmentItems.get(0).Parent__c, 'Parent Id on technical Assignment Line Item is wrong');
        System.assertEquals(techQliChild.Id, technicalAssignmentItems.get(0).Child__c, 'Child Id on technical Assignment Line Item is wrong');
    }

    @isTest
    static void testUpdateLineItemFromMasterToTechnicalQli() {
        Triggers.switchOff();
        TestDataGenerator.MultiproductStructure mpStruct = new TestDataGenerator.MultiproductStructure();
        Triggers.switchOn();

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

        QuoteLineItem masterQliParent = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                QuoteLineItem.QuoteId => mpStruct.masterQuote.Id,
                QuoteLineItem.Deactivated__c => false,
                QuoteLineItem.PricebookEntryId => standardPricebookEntry.Id,
                QuoteLineItem.Quantity => 4,
                QuoteLineItem.NewQuantity__c => 3,
                QuoteLineItem.UnitPrice => 10,
                QuoteLineItem.Discount => 2,
                QuoteLineItem.Product2Id => product.Id,
                QuoteLineItem.IsMultiProductTechnicalQLI__c => false
            })
            .create()
            .getRecord();

        QuoteLineItem masterQliChild = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                QuoteLineItem.QuoteId => mpStruct.masterQuote.Id,
                QuoteLineItem.Deactivated__c => false,
                QuoteLineItem.PricebookEntryId => standardPricebookEntry.Id,
                QuoteLineItem.Quantity => 4,
                QuoteLineItem.NewQuantity__c => 3,
                QuoteLineItem.UnitPrice => 10,
                QuoteLineItem.Discount => 2,
                QuoteLineItem.Product2Id => product.Id,
                QuoteLineItem.IsMultiProductTechnicalQLI__c => false
            })
            .create()
            .getRecord();

        Test.startTest();
            QuoteLineItem techQliParent = mpStruct.technicalQLIs.values().get(0).get(0);
            QuoteLineItem techQliChild = mpStruct.technicalQLIs.values().get(1).get(0);
            techQliParent.MasterQLI__c = masterQliParent.Id;
            techQliChild.MasterQLI__c = masterQliChild.Id;
            update new List<QuoteLineItem> {techQliParent, techQliChild};

            Area_Codes__c ac = (Area_Codes__c) new SObjectBuilder(Area_Codes__c.SObjectType)
                .setFields(new Map<SObjectField, Object> {
                    Area_Codes__c.Name => 'test area code'
                })
                .create()
                .getRecord();

            AssignmentLineItem__c masterAli = (AssignmentLineItem__c) new SObjectBuilder(AssignmentLineItem__c.SObjectType)
                    .setFields(new Map<SObjectField, Object> {
                        AssignmentLineItem__c.AreaCode__c => ac.Id,
                        AssignmentLineItem__c.Quantity__c => 1,
                        AssignmentLineItem__c.Parent__c => masterQliParent.Id,
                        AssignmentLineItem__c.Child__c => masterQliChild.Id
                    })
                    .create()
                    .getRecord();

            masterAli.Quantity__c = 100;
            update masterAli;

            List<AssignmentLineItem__c> technicalAssignmentItems = (List<AssignmentLineItem__c>) new AssignmentLineItemSelector()
                .selectTechnicalItemsByMasterQliId(new List<Object> {new List<Id> {masterQliParent.Id}})
                .executeQuery();
        Test.stopTest();

        System.assert(technicalAssignmentItems.size() == 1, 'Only one technical Assignment Line Item should be created');
        System.assertEquals(techQliParent.Id, technicalAssignmentItems.get(0).Parent__c, 'Parent Id on technical Assignment Line Item is wrong');
        System.assertEquals(techQliChild.Id, technicalAssignmentItems.get(0).Child__c, 'Child Id on technical Assignment Line Item is wrong');
        System.assertEquals(masterAli.Quantity__c, technicalAssignmentItems.get(0).Quantity__c, 'Quantity on technical Assignment Line Item is not synced with master Assignment Line Item');
    }

    @isTest
    static void testDeleteLineItemsOnTechnicalQlisOnMasterDelete() {
        Triggers.switchOff();
        TestDataGenerator.MultiproductStructure mpStruct = new TestDataGenerator.MultiproductStructure();
        Triggers.switchOn();

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

        QuoteLineItem masterQliParent = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                QuoteLineItem.QuoteId => mpStruct.masterQuote.Id,
                QuoteLineItem.Deactivated__c => false,
                QuoteLineItem.PricebookEntryId => standardPricebookEntry.Id,
                QuoteLineItem.Quantity => 4,
                QuoteLineItem.NewQuantity__c => 3,
                QuoteLineItem.UnitPrice => 10,
                QuoteLineItem.Discount => 2,
                QuoteLineItem.Product2Id => product.Id,
                QuoteLineItem.IsMultiProductTechnicalQLI__c => false
            })
            .create()
            .getRecord();

        QuoteLineItem masterQliChild = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                QuoteLineItem.QuoteId => mpStruct.masterQuote.Id,
                QuoteLineItem.Deactivated__c => false,
                QuoteLineItem.PricebookEntryId => standardPricebookEntry.Id,
                QuoteLineItem.Quantity => 4,
                QuoteLineItem.NewQuantity__c => 3,
                QuoteLineItem.UnitPrice => 10,
                QuoteLineItem.Discount => 2,
                QuoteLineItem.Product2Id => product.Id,
                QuoteLineItem.IsMultiProductTechnicalQLI__c => false
            })
            .create()
            .getRecord();

        Test.startTest();
            QuoteLineItem techQliParent = mpStruct.technicalQLIs.values().get(0).get(0);
            QuoteLineItem techQliChild = mpStruct.technicalQLIs.values().get(1).get(0);
            techQliParent.MasterQLI__c = masterQliParent.Id;
            techQliChild.MasterQLI__c = masterQliChild.Id;
            update new List<QuoteLineItem> {techQliParent, techQliChild};

            Area_Codes__c ac = (Area_Codes__c) new SObjectBuilder(Area_Codes__c.SObjectType)
                .setFields(new Map<SObjectField, Object> {
                    Area_Codes__c.Name => 'test area code'
                })
                .create()
                .getRecord();

            AssignmentLineItem__c acli = (AssignmentLineItem__c) new SObjectBuilder(AssignmentLineItem__c.SObjectType)
                    .setFields(new Map<SObjectField, Object> {
                        AssignmentLineItem__c.AreaCode__c => ac.Id,
                        AssignmentLineItem__c.Quantity__c => 1,
                        AssignmentLineItem__c.Parent__c => masterQliParent.Id,
                        AssignmentLineItem__c.Child__c => masterQliChild.Id
                    })
                    .create()
                    .getRecord();

            delete acli;

            List<AssignmentLineItem__c> technicalAssignmentItems = (List<AssignmentLineItem__c>) new AssignmentLineItemSelector()
                .selectTechnicalItemsByMasterQliId(new List<Object> {new List<Id> {masterQliParent.Id}})
                .executeQuery();
        Test.stopTest();

        System.assert(technicalAssignmentItems.isEmpty(), 'Technical Assignment Line Item should be deleted');
    }
}