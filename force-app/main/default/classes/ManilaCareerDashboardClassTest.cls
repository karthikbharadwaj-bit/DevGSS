@isTest
private class ManilaCareerDashboardClassTest 
{
 /**
  * Created By	:	Jerslin Mary
  * Created Date:	March 23 2023
  * Purpose		: 	The test class for Apex class - ManilaCareerDashboardClass was missing. Identified 
  * 				during EU Privacy Phase 3 - Sprint 3 when Sales profiles were added in the apex class
  * 				as part of this project
  * */
    
    //Scenario - 1 - Mgr and subordinate with Sys Admin Profile and Sales Dept with Level 1 Agent
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testManilaCareerDashboardClass1() 
    {
        Profile adminProf = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        UserRole testRole = new UserRole(Name = 'TestRole');
        insert testRole;
        User usr = new User(Alias = 'standt', Email='standarduser@testorg.com', 
                          EmailEncodingKey='UTF-8', LastName='Mgr', LanguageLocaleKey='en_US', 
                          LocaleSidKey='en_US', 
                          ProfileId = adminProf.Id,
                          UserRoleId = testRole.Id,
                          division = 'Manager',
                          Department = 'Sales', 
                          TimeZoneSidKey='America/Los_Angeles', UserName='mgruser@testorg.com',Employee_Location__c='Manila, Philippines',IsActive = true);
        insert usr;
        User subordinate = new User(Alias = 'standtop', Email='standarduser2@testorg.com', 
                            EmailEncodingKey='UTF-8', LastName='SubUsr', LanguageLocaleKey='en_US', 
                            LocaleSidKey='en_US', 
                            ProfileId = adminProf.Id,
                            UserRoleId = testRole.Id, 
                            Department='Sales',
                            ManagerID = usr.Id, 
                            TimeZoneSidKey='America/Los_Angeles', UserName='subuser@testorg.com',Employee_Location__c='Manila, Philippines',IsActive = true);
        insert subordinate;
        System.RunAs(usr)
        {
            Test.startTest();         
            testScenario1(usr.Id,subordinate.Id);
            Test.stopTest(); 
        } 
    }
    
    //Scenario - 2 - User with Sales Mgr Profile and Coaching Dept with Level 0 Agent
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testManilaCareerDashboardClass2() 
    {
        Profile salesProf = [SELECT Id FROM Profile WHERE id = '00e80000001ONutAAG'];
        UserRole testRole = new UserRole(Name = 'TestRole');
        insert testRole;
        User salesUsr = new User(Alias = 'standt', Email='standarduser@testorg.com', 
                           EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                           LocaleSidKey='en_US', 
                           ProfileId = salesProf.Id,
                           UserRoleId = testRole.Id,
                           division = 'Coaching',
                           Department='Sales',
                           TimeZoneSidKey='America/Los_Angeles', UserName='standarduser@testorg1.com',Employee_Location__c='Manila, Philippines',IsActive = true);
        insert salesUsr;
        System.RunAs(salesUsr)
        {
            Test.startTest();         
            testScenario2(salesUsr.Id);
            Test.stopTest(); 
        } 
    } 
    
    @future
    private static void testScenario1(ID uid, ID subID)
    {
		
        Employee__c e = new Employee__c(User__c=uid,  Agent_Level__c='Level 1', 
                                        Industry_Certified_Legal__c=true, Industry_Certified_Healthcare__c=false, 
                                        Industry_Certified_High_Technology__c=true, Industry_Certified_Government__c=false, 
                                        Industry_Certified_Real_Estate__c=false, Industry_Certified_Construction__c=true);
        insert e;
        // Create quality_monitoring_form__c records for the user
        quality_monitoring_form__c qmf = new quality_monitoring_form__c(Agent_Name__c=uid, Overall_ACE_Score__c=90, 
                                                                        QMF_Info__c='Completed', Monitored_Date__c=Date.today().addDays(-5));
        insert qmf;       
        ApexPages.StandardController sc = new ApexPages.standardController(e); 
        ManilaCareerDashboardClass signupObj = new ManilaCareerDashboardClass(sc);
        List<SelectOption> v1 = signupObj.UserList;
        signupObj.selectedVal = subID;
        signupObj.checkops();
    }
    
    @future
    private static void testScenario2(ID uid)
    {
        //Delete prev employee records
        List<Employee__c> empList = [select Id from Employee__c limit 5];
        if(empList != null) {
            delete empList;
        }
        // Create an Employee record for the user
        Employee__c e = new Employee__c(User__c=uid,  Agent_Level__c='Level 0', 
                                        Industry_Certified_Legal__c=true, Industry_Certified_Healthcare__c=false, 
                                        Industry_Certified_High_Technology__c=true, Industry_Certified_Government__c=false, 
                                        Industry_Certified_Real_Estate__c=false, Industry_Certified_Construction__c=true);
        insert e;
        // Create quality_monitoring_form__c records for the user
        quality_monitoring_form__c qmf = new quality_monitoring_form__c(Agent_Name__c=uid, Overall_ACE_Score__c=90, 
                                                                        QMF_Info__c='Completed', Monitored_Date__c=Date.today().addDays(-5));
        insert qmf;
        ApexPages.StandardController sc = new ApexPages.standardController(e); 
        ManilaCareerDashboardClass signupObj = new ManilaCareerDashboardClass(sc);
        List<SelectOption> v1 = signupObj.UserList;
        signupObj.selectedVal = uid;
        signupObj.checkops();
    }
    
    @future
    private static void testScenario3(ID uid)
    {
		//Delete prev employee records
        List<Employee__c> empList = [select Id from Employee__c limit 5];
        if(empList != null) {
            delete empList;
        }
        // Create an Employee record for the user
        Employee__c e = new Employee__c(User__c=uid,  Agent_Level__c='Level 2', 
                                        Industry_Certified_Legal__c=true, Industry_Certified_Healthcare__c=false, 
                                        Industry_Certified_High_Technology__c=true, Industry_Certified_Government__c=false, 
                                        Industry_Certified_Real_Estate__c=false, Industry_Certified_Construction__c=true);
        insert e;
        // Create quality_monitoring_form__c records for the user
        quality_monitoring_form__c qmf = new quality_monitoring_form__c(Agent_Name__c=uid, Overall_ACE_Score__c=90, 
                                                                        QMF_Info__c='Completed', Monitored_Date__c=Date.today().addDays(-5));
        insert qmf;
        ApexPages.StandardController sc = new ApexPages.standardController(e); 
        ManilaCareerDashboardClass signupObj = new ManilaCareerDashboardClass(sc);
        List<SelectOption> v1 = signupObj.UserList;
        signupObj.selectedVal = uid;
        signupObj.checkops();
    }
}