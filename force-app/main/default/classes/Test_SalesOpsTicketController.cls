@isTest
public class Test_SalesOpsTicketController {

    @isTest
    static void testCreateNewCase2() {
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
        SalesOpsTicketController controller = new SalesOpsTicketController();
        PageReference pageRef = controller.createNewCase2();
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
        SalesOpsTicketController controller = new SalesOpsTicketController();
        PageReference pageRef = controller.close();
        List<SelectOption> categoryOptions = controller.getCategoryOptions();
        List<SelectOption> typeOptions = controller.getTypeOptions();
        List<SelectOption> applicationOptions = controller.getApplicationOptions();

        System.assertEquals(true, pageRef.getRedirect());
    }
}