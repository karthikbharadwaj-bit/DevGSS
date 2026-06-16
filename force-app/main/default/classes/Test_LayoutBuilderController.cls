@isTest
private class Test_LayoutBuilderController {

    @isTest
    static void test_getLayout() {
        CaseLayoutAssignment__c cs = new CaseLayoutAssignment__c (
            Name = 'System Administrator',
            Profile_Name__c = 'System Administrator',
            Layout_Name__c = 'Support T1 Layout (Standard)'
        );
        insert cs;

        String layoutName = LayoutBuilderController.getLayout().substringBetween('Case-', '"');
        System.assertEquals('Support T1 Layout (Standard)',layoutName);
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void test_getField() {
        LayoutBuilderController.getField('Case', 'CaseNumber');
    }

    @isTest
    static void test_getNameField() {
        String caseNameFieldJSON = LayoutBuilderController.getNameField('Case');
        String accountNameFieldJSON = LayoutBuilderController.getNameField('Account');

        System.assert(caseNameFieldJSON.containsIgnoreCase('CaseNumber'));
        System.assert(accountNameFieldJSON.containsIgnoreCase('Name'));
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void test_saveRecord() {
        Account newSObject = new Account(
            Name='test SObject'
        );

        LayoutBuilderController.saveRecord(newSObject);
    }

    @isTest
    static void test_getPickListField() {

        // set mock for PageReference.getContent() method(in this case - it is select for Case_Severity__c picklist field)
        LayoutBuilderController.mockHtmlContent = '<html>'+
                    '<head>'+
                    '</head>'+
                    '<body>'+
                        '<select id="j_id0:j_id1:Type__c" data-id="case_severity__c" name="j_id0:j_id1:Type__c">'+
                            '<option value="">--None--</option>'+
                            '<option value="Level 1 - Critical">Level 1 - Critical</option>'+
                            '<option value="Level 2 - Urgent">Level 2 - Urgent</option>'+
                            '<option value="Level 3 - High">Level 3 - High</option>'+
                            '<option value="Level 4 - Medium">Level 4 - Medium</option>'+
                        '</select>'+
                    '</body>'+
                '</html>';

        System.assertNotEquals(null, LayoutBuilderController.getField('Case', 'Case_Severity__c'));
    }

    @isTest
    static void test_getCaseStatusField() {

        // set mock for PageReference.getContent() method
        LayoutBuilderController.mockHtmlContent = '<html>'+
                    '<head>'+
                    '</head>'+
                    '<body>'+
                        '<select data-id="status" id="j_id0:j_id1:j_id2:0:j_id3" name="j_id0:j_id1:j_id2:0:j_id3">'+
                            '<option value="">--None--</option>' +
                            '<option value="New" selected="selected">New</option>' +
                            '<option value="Work in Progress">Work in Progress</option>' +
                            '<option value="PKI Hold">PKI Hold</option>' +
                            '<option value="Waiting on Customer">Waiting on Customer</option>' +
                            '<option value="Updated by Customer">Updated by Customer</option>' +
                            '<option value="Resolved">Resolved</option>' +
                            '<option value="Duplicate">Duplicate</option>' +
                            '<option value="Cancelled">Cancelled</option>' +
                            '<option value="Closed">Closed</option>' +
                            '<option value="Closed - No Response">Closed - No Response</option>' +
                            '<option value="WIP by Partner">WIP by Partner</option>' +
                        '</select>'+
                    '</body>'+
                '</html>';

        System.assertNotEquals(null, LayoutBuilderController.getField('Case', 'Status'));
    }

    @isTest
    static void test_createInnerClassInstances() {

        System.assertNotEquals(null, new LayoutBuilderController.CustomOption(null, null));
        System.assertNotEquals(null, new LayoutBuilderController.CustomOption('some value', 'label'));

        System.assertNotEquals(null, new LayoutBuilderController.CustomDescribeFieldResult(null, null, null, null, null, null, null));
    }

    @isTest
    static void test_getUserProfile() {
        String currentProfileName = LayoutBuilderController.getUserProfile();
        System.assertNotEquals(null, currentProfileName);
    }
}