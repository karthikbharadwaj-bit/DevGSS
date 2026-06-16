/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 */
@isTest
private class Test_Employee {

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
	@isTest
    static void Test_employeedetails2012new() {
	     Employee__c objEmp=new Employee__c();   
         employeedetails2012new  obj2=new employeedetails2012new ();
         ApexPages.StandardController controller=new ApexPages.StandardController(objEmp);
         employeedetails2012new obj=new employeedetails2012new (controller);
         System.currentPagereference().getParameters().put('id','123345');
         Test.startTest();
         obj.getEmpDetails();
         obj.getPeers();
         obj.getMgdTeams();
         Test.stopTest();
    }
 	
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void Test_employeesearchdrill2012New() {
         ApexPages.currentPage().getHeaders().put('True-Client-IP','119.93.30.162');
         Employee__c objEmp=new Employee__c();
         ApexPages.StandardController controller=new ApexPages.StandardController(objEmp);
         employeesearchdrill2012New obj=new employeesearchdrill2012New ();
         Test.startTest();
         obj.showEmployeeByText();
         obj.gettrueIP();
         obj.getShowDirectory();
         obj.isIPExist('107.0.179.57');
         obj.getTeam();
         String[] str=new List<String>();
         obj.setTeam(str);
         obj.setDivision(str);
         obj.getDivisionValues();
        obj.getCountries();
        obj.getManagerAll1();
        obj.getTotalTeamValues();
        obj.getTeamValues1();
        obj.getTotalDepartmentValues();
        obj.getDepartment1();
        obj.strEmployee='test test';
        obj.strEmployee='test test';
        obj.seletedManager='test test';
        obj.seletedTeam='test test';
        obj.seletedDepartment='test test';
        obj.getIntCount();
        obj.setCountries(str);
        obj.getManager();
        obj.setManager(str);
        obj.doSearch1();
        
        ApexPages.currentPage().getHeaders().put('True-Client-IP','119.93.302.163');
		Employee__c objEmp1=new Employee__c();
		ApexPages.StandardController controller1=new ApexPages.StandardController(objEmp1);
		employeesearchdrill2012New obj1=new employeesearchdrill2012New ();
		obj1.getShowDirectory();
		Test.stopTest();
    }
}