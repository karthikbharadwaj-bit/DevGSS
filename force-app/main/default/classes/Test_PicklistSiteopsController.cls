@isTest
private class Test_PicklistSiteopsController {
    
    private static String getTestHtml() {
        return '<html>'+
                    '<head>'+
                    '</head>'+
                    '<body>'+
                        '<select id="j_id0:j_id1:Type__c" name="j_id0:j_id1:Type__c">'+
                            '<option value="">--None--</option>'+
                            '<option value="Amendment">Amendment</option>'+
                            '<option value="Enterprise/Majors Agreement">Enterprise/Majors Agreement</option>'+
                            '<option value="Free Services < 3 months">Free Services < 3 months</option>'+
                        '</select>'+
                        'pl.vals_00N80000005HvdP_01280000000UIfJ=[\'Billing information update\',\'ESSSS billing information update\',\'Taxes and fees inquiry\',\'Taxes and fees inquiry\',\'3rd Party\',\'3rd Party\',\'Account Reactivation\',\'Account Reactivation\'];' +
                    '</body>'+
                '</html>';
    }
    

    @isTest static void testConstructor_whenPageParametersAreCorrect_shouldBeOk() {

        PageReference pr = new PageReference('/apex/PicklistSiteops?SObjectType=Case&RecordTypeName=Support-Case');
        Test.setCurrentPage(pr);
        ApexPages.currentPage().getParameters().put('SObjectType', 'Case');
        ApexPages.currentPage().getParameters().put('RecordTypeName', 'Support-Case');
        
        Test.startTest();
            PicklistSiteopsController instance = new PicklistSiteopsController();
        Test.stopTest();

        system.assertEquals('Case', instance.targetSobject.getSObjectType().getDescribe().getName(), 'targetObject should be Case');
    }

    @isTest
    static void testParse_whenDependentPicklistParameterIsTrue_shouldRetrieveDependentPicklistValues() {

        String html = getTestHtml();
        String parentTag = '<select ';
        String childTag = '<option ';

        List<PicklistSiteopsController.Picklist> result = PicklistSiteopsController.parse(html, parentTag, childTag, true);

        System.equals(result.size(), 2);

        PicklistSiteopsController.Picklist pl = result.get(0);

        System.equals(pl.Name, 'Type__c');
        System.equals(pl.Options.size(), 4);

        System.equals(pl.Options[0].Value, '');
        System.equals(pl.Options[0].Label, '--None--');

        System.equals(pl.Options[1].Value, 'Amendment');
        System.equals(pl.Options[1].Label, 'Amendment');

        System.equals(pl.Options[0].Value, 'Enterprise/Majors Agreement');
        System.equals(pl.Options[0].Label, 'Enterprise/Majors Agreement');

        System.equals(pl.Options[0].Value, 'Free Services < 3 months');
        System.equals(pl.Options[0].Label, 'Free Services < 3 months');

        PicklistSiteopsController.Picklist pl2 = result.get(1);

        System.assertEquals(pl.Options.size(), 4, 'bad picklist size');
    }
}