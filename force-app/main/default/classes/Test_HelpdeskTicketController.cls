@isTest
public class Test_HelpdeskTicketController {

    @isTest
    static void testCreateNewCase() {
        Schema.DescribeSObjectResult acccountResult = Account.SObjectType.getDescribe();
        Map<ID,Schema.RecordTypeInfo> acccountrtMapByName = acccountResult.getRecordTypeInfosById();
        Map<string,Schema.RecordTypeInfo> acccountrtMapById = acccountResult.getRecordTypeInfosByName(); 
        Account acctestt = new Account();
        acctestt.Name='TestAccount11';
        acctestt.RC_Attribution_Channel__c = 'Sales Agents & Resellers';
        acctestt.RecordTypeId = acccountrtMapById.get('Customer Account').getRecordTypeId();
        insert acctestt;

        Contact contacObj = new Contact();
        contacObj.AccountId =  acctestt.id;
        contacObj.Email = 'virendra.singh111@simplion.com';
        contacObj.Phone = '9910106804';
        contacObj.LastName = 'TestLast';
        insert contacObj ;

        Case casObj = new Case();
        casObj.Subject = 'Test Case';
        casObj.AccountId = acctestt.Id;
        casObj.Contact_ID__c = contacObj.Id;
        insert casObj;

        Test.startTest();
        HelpdeskTicketController controller = new HelpdeskTicketController();
        PageReference pageRef = controller.createNewCase();
        PageReference testPage = new PageReference('/helpdesk/' + [
            SELECT Id 
            FROM Case 
            WHERE Origin = 'Web'
        ].Id);

        Test.stopTest();
        System.assertEquals(String.valueOf(pageRef), String.valueOf(testPage));
    }

    @isTest
    static void testClose() {
        HelpdeskTicketController controller = new HelpdeskTicketController();
        PageReference pageRef = controller.close();
        List<SelectOption> CategoryOptions = controller.getCategoryOptions();
        List<SelectOption> TypeOptions = controller.getTypeOptions();
        List<SelectOption> SeverityOptions = controller.getSeverityOptions();
        System.assertEquals(true, pageRef.getRedirect());
    }
}