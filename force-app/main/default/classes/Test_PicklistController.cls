@isTest
private class Test_PicklistController {
    
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
                    '</body>'+
                '</html>';
    }
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest static void test_parse() {
        String html = getTestHtml();
        String parentTag = '<select ';
        String childTag = '<option ';

        List<PicklistController.Picklist> result = PicklistController.parse(html, parentTag, childTag);


        System.equals(result.size(), 1);

        PicklistController.Picklist pl = result.get(0);

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

    }

    @isTest static void test_constructor_default() {

        Test.startTest();
            PicklistController instance = new PicklistController();

            Sobject targetSobj = instance.targetSobject;
            System.assert(targetSobj != null);

            // by default targetSobject has Approval__c type
            Approval__c targetSobjectApproval = (Approval__c) targetSobj;
            System.assert(targetSobjectApproval != null);
        Test.stopTest();
    }

    @isTest static void test_constructor_withParams() {

        Test.startTest();
            ApexPages.currentPage().getParameters().put('SObjectType', 'Phase__c');
            ApexPages.currentPage().getParameters().put('RecordTypeName', 'ProServ Phase');
            ApexPages.currentPage().getParameters().put('fields', 'billingstatus__c');

            PicklistController instance = new PicklistController();

            Sobject targetSobj = instance.targetSobject;
            System.assert(targetSobj != null);

            // if SObjectType and RecordTypeName params is presented targetSobject will have type specified in SObjectType param
            Phase__c targetSobjectPhase = (Phase__c) targetSobj;
            System.assert(targetSobjectPhase != null);
        Test.stopTest();
    }

}