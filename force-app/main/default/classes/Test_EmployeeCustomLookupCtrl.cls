@isTest
public class Test_EmployeeCustomLookupCtrl {
    @isTest
    public static void  EmployeeCustomLookupCtrl(){
        final String FRM = 'frm_test';
        final String TXT = 'txt_test';
        Employee__c emp = new Employee__c();
        emp.First_Name__c = 'tuser';
        emp.Last_Name__c = 'lname';
        emp.Email__c ='clc@clc.com';
        emp.Location__c = 'Noida, India';
        emp.Department__c = 'IT';
        emp.Team__c = 'SE';
        emp.SPID__c = '12454';
        insert emp;

        PageReference pageRef = Page.CustomEmployeeLookup;
        Test.setCurrentPageReference(pageRef);
        Apexpages.currentPage().getParameters().put('lksrch', 'tuser');
        Apexpages.currentPage().getParameters().put('frm', FRM);
        Apexpages.currentPage().getParameters().put('txt', TXT);

        EmployeeCustomLookupCtrl eclc = new EmployeeCustomLookupCtrl();
        PageReference searchPage = eclc.search();
        String formTag = eclc.getFormTag();
        String textBox = eclc.getTextBox();

        System.assertEquals(searchPage, null);
        System.assertEquals(formTag, FRM);
        System.assertEquals(textBox, TXT);
    }
}