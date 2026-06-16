@isTest
private class Test_MarketoControllerNew {

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void myUnitTest() {
    	Lead leadObj = new Lead();
       	leadObj.LeadSource = 'About To be Cancelled'; 
        leadObj.ATBC_Stage__c = 'WIP';
        leadObj.IsConverted = false;
        leadObj.User_ID__c = UserInfo.getUserId();
        leadObj.FirstName='Virendra';
        leadObj.LastName='Singh';
        leadObj.Company='Simplion';
        leadObj.Email='vps@sss.ss221.com';
        leadObj.Phone='9910106804';
        insert leadObj;
        
        Account accObj = new Account(Name='Simplion', Partner_ID__c='Test12322');
        insert accObj;
        
        Contact contactObj = new Contact(firstName='Virendra', lastname='Singh', marketingSuspend__c=false, accountid=accObj.id, email='virendra.singh@simplion.com', phone='9910106804');
        insert contactObj;
        
        apexpages.currentPage().getParameters().put('sfdcId',leadobj.id);
        apexpages.currentPage().getParameters().put('email','vps@sss.ss221.com');              
        
        MarketoControllerNew objMarketo=new MarketoControllerNew();
       	MarketoLeadActivityTypeFilter objMlatf =new MarketoLeadActivityTypeFilter();
       	MarketoLeadActivityTypeFilter.getAllAvailableActivityFilter();
       	MarketoLeadActivityTypeFilter.getDefaultActivityFilter();
       	MarketoLeadActivityTypeFilter.getDefaultSelectedActivityFilter();       	
        objMarketo.objMultiRows.add(objMlatf);
         apexpages.currentPage().getParameters().put('contactId',contactObj.id);
         
    }
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void myUnitTest1() {
    	Lead leadObj = new Lead();
       	leadObj.LeadSource = 'About To be Cancelled'; 
        leadObj.ATBC_Stage__c = 'WIP';
        leadObj.IsConverted = false;
        leadObj.User_ID__c = UserInfo.getUserId();
        leadObj.FirstName='Virendra';
        leadObj.LastName='Singh';
        leadObj.Company='Simplion';
        leadObj.Email='vps@sss.ss221.com';
        leadObj.Phone='9910106804';
        insert leadObj;
        
        Account accObj = new Account(Name='Simplion', Partner_ID__c='Test12322');
        insert accObj;
        
        Contact contactObj = new Contact(firstName='Virendra', lastname='Singh', marketingSuspend__c=false, accountid=accObj.id, email='virendra.singh@simplion.com', phone='9910106804');
        insert contactObj;
       
        apexpages.currentPage().getParameters().put('contactId',contactObj.id);
        apexpages.currentPage().getParameters().put('email','vps@sss.ss221.com');              
        
        MarketoControllerNew objMarketo=new MarketoControllerNew();
       	MarketoLeadActivityTypeFilter objMlatf =new MarketoLeadActivityTypeFilter();
       	MarketoLeadActivityTypeFilter.getAllAvailableActivityFilter();
       	MarketoLeadActivityTypeFilter.getDefaultActivityFilter();
       	MarketoLeadActivityTypeFilter.getDefaultSelectedActivityFilter();       	
        objMarketo.objMultiRows.add(objMlatf);
         
    }
    
    @isTest
    static void testMoveRight() {
        MarketoControllerNew controller = new MarketoControllerNew();
        
        MarketoLeadActivityTypeFilter filter = new MarketoLeadActivityTypeFilter();
        filter.listLeftFilter = new List<SelectOption>();
        filter.listRightFilter = new List<SelectOption>();
        filter.SelectedOptionsLeft = new List<String>{'1'};
        filter.SelectedOptionsRight = new List<String>();
        filter.listLeftFilter.add(new SelectOption('1', 'Option 1'));
        filter.listLeftFilter.add(new SelectOption('2', 'Option 2'));
        
        controller.objMultiRows = new List<MarketoLeadActivityTypeFilter>{filter};
        controller.MoveRight();
        
        System.assertEquals(1, filter.listLeftFilter.size());
        System.assertEquals('2', filter.listLeftFilter[0].getValue());
        System.assertEquals(1, filter.listRightFilter.size());
        System.assertEquals('1', filter.listRightFilter[0].getValue());
    }
    
    @isTest
    static void testMoveLeft() {
        MarketoControllerNew controller = new MarketoControllerNew();
        
        MarketoLeadActivityTypeFilter filter = new MarketoLeadActivityTypeFilter();
        filter.listLeftFilter = new List<SelectOption>();
        filter.listRightFilter = new List<SelectOption>();
        filter.SelectedOptionsLeft = new List<String>();
        filter.SelectedOptionsRight = new List<String>{'1'};
        filter.listRightFilter.add(new SelectOption('1', 'Option 1'));
        filter.listRightFilter.add(new SelectOption('2', 'Option 2'));

        controller.objMultiRows = new List<MarketoLeadActivityTypeFilter>{filter};
        controller.MoveLeft();
        
        System.assertEquals(1, filter.listRightFilter.size());
        System.assertEquals('2', filter.listRightFilter[0].getValue());
        System.assertEquals(1, filter.listLeftFilter.size());
        System.assertEquals('1', filter.listLeftFilter[0].getValue());
    }
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testShowLeadActivityWithFilter() {
        ApexPages.currentPage().getParameters().put('sfdcId', 'someLeadId');
        ApexPages.currentPage().getParameters().put('email', 'test@example.com');
        
        MarketoControllerNew controller = new MarketoControllerNew();
        
        MarketoLeadActivityTypeFilter filter = new MarketoLeadActivityTypeFilter();
        filter.listLeftFilter = new List<SelectOption>();
        filter.listRightFilter = new List<SelectOption>();
        filter.SelectedOptionsLeft = new List<String>();
        filter.SelectedOptionsRight = new List<String>();
        filter.listRightFilter.add(new SelectOption('1', 'Option 1'));
        controller.objMultiRows = new List<MarketoLeadActivityTypeFilter>{filter};
        
        Test.startTest();
        controller.showLeadActivityWithFilter();
        Test.stopTest();
        
    }

    @isTest
    static void testGetMarketoLeadRecord() {
        Mktows.ActivityRecord testItem = new Mktows.ActivityRecord();
        testItem.Id = 123;
        testItem.activityDateTime = Datetime.now();
        testItem.activityType = 'TestActivityType';
        
        MarketoControllerNew controller = new MarketoControllerNew();
        MarketoLeadRecord result = controller.getMarketoLeadRecord(testItem);
        
        System.assertEquals('123', result.ActivityID, 'Activity ID should match');
        System.assertEquals('TestActivityType', result.Activity, 'Activity Type should match');
    }

    @isTest
    static void testMarketoControllerProperties() {
        List<Account> testAccounts = new List<Account>();
        for (Integer i = 0; i < 5; i++) {
            testAccounts.add(new Account(Name = 'TestAccount' + i));
        }
        insert testAccounts;
        
        ApexPages.StandardSetController testController = new ApexPages.StandardSetController(testAccounts);

        MarketoControllerNew controller = new MarketoControllerNew();

        controller.con = testController;

        controller.iListSize = 10;
        System.assertEquals(10, controller.iListSize, 'iListSize should be 10');

        controller.recordCount = 5;
        System.assertEquals(5, controller.recordCount, 'recordCount should be 5');

        controller.SelectedRow = 'Row1';
        System.assertEquals('Row1', controller.SelectedRow, 'SelectedRow should be "Row1"');

        System.assertEquals(5, controller.con.getRecords().size(), 'StandardSetController should have 5 records');
    }
}