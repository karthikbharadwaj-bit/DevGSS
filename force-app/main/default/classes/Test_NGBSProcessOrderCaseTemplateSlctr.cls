@isTest
private class Test_NGBSProcessOrderCaseTemplateSlctr {

    @isTest
    private static void testSelectActiveNGBSProcessOrderCaseTemplates(){
        Test.startTest();
        List<NGBSProcessOrderCaseTemplate__mdt> medatada =
            new NGBSProcessOrderCaseTemplateSelector()
                .selectActiveNGBSProcessOrderCaseTemplates()
                .executeQuery();
        Test.stopTest();
        Integer expectedSize = [SELECT COUNT() FROM NGBSProcessOrderCaseTemplate__mdt WHERE IsActive__c = true];
        System.assertEquals(expectedSize, medatada.size(), 'Should select all active NGBSProcessOrderCaseTemplate__mdt');
    }
}