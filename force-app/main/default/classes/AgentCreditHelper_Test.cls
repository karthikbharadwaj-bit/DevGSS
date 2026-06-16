@isTest
private class AgentCreditHelper_Test {
    
    @testSetup 
    static void agentCreditSetup() {
        Profile p = [select id from profile where name='System Administrator'];
        
        List<User> userList = new List<User>();
        User testUser = new User(alias = 'u111', email='u111@testorg.com',
                                 emailencodingkey='UTF-8', lastname='Testing11', languagelocalekey='en_US',
                                 localesidkey='en_US', profileid = p.Id, country='United States',
                                 timezonesidkey='America/Los_Angeles', username='u111@testorg.com');
        userList.add(testUser);
        
        User testUser3 = new User(alias = 'u111', email='u112@testorg.com',
                                  emailencodingkey='UTF-8', lastname='Testing12', languagelocalekey='en_US',
                                  localesidkey='en_US', profileid = p.Id, country='United States',
                                  timezonesidkey='America/Los_Angeles', username='u112@testorg.com');
        userList.add(testUser3);

        insert userList;
        
        User testUser2 = [SELECT Id, email FROM User WHERE Name = 'RCSF Sync' LIMIT 1];
        
        RCSF_Sync__c rcsfSetting = new RCSF_Sync__c(
            Name = 'RCSF Sync',
            Active__c = true,
            Email__c = 'rcsfsync@ringcentral.com',
            First_Name__c = 'RCSF',
            Last_Name__c = 'Sync',
            Id__c = (Id) new ValueProvider.DummyIdProvider(User.sObjectType).getValue(),
            Is_Primary__c = true,
            Username__c = 'rcsfsync@ringcentral.com'
        );
        insert rcsfSetting;
        
        Employee__c emp = new Employee__c(User__c = testUser2.id, First_Name__c = 'tuser', Last_Name__c = 'lname', 
                                          Email__c ='rcsfsync@ringcentral.com', Location__c = 'Noida, India', Department__c = 'IT', 
                                          Team__c = 'SE', SPID__c = '12454', Is_Active__c = true);
        insert emp;
        
        List<Account> acctList = new List<Account>();
        Account testAccount = new Account(Name = 'Test account', InContact_Service__c = 'Contact Center Basic',
                                          No_of_InContact_Seats__c = 3, Type = 'Partner', Partner_ID__c = '123456784',
                                          Inside_Sales_Rep__c = testUser.Id, RC_Attribution_Channel__c = 'Sales Agents & Resellers');
        acctList.add(testAccount);
        
        Account testAccount2 = new Account(Name = 'Test account2', InContact_Service__c = 'Contact Center Basic',
                                           No_of_InContact_Seats__c = 3, Type = 'Partner', Partner_ID__c = '123456785',
                                           Inside_Sales_Rep__c = testUser3.Id, RC_Attribution_Channel__c = 'Franchise & Assoc');
        acctList.add(testAccount2);

        Account customerAcct = new Account(Name = 'Test Customer account', InContact_Service__c = 'Contact Center Basic',
                                          No_of_InContact_Seats__c = 3, Type = 'Customer', Partner_ID__c = '987654321',
                                          Inside_Sales_Rep__c = testUser.Id, RC_Attribution_Channel__c = 'Sales Agents & Resellers');
        acctList.add(customerAcct);
        
        Account partnerAcct = new Account(Name = 'Test Partner account', InContact_Service__c = 'Contact Center Basic',
                                           No_of_InContact_Seats__c = 3, Type = 'Partner', Partner_ID__c = '987654321',
                                           Inside_Sales_Rep__c = testUser.Id, RC_Attribution_Channel__c = 'Franchise & Assoc');
        acctList.add(partnerAcct);

        Account customerAcct2 = new Account(Name = 'Test Customer account 2', InContact_Service__c = 'Contact Center Basic',
                                          No_of_InContact_Seats__c = 3, Type = 'Customer', Partner_ID__c = '54321',
                                          Inside_Sales_Rep__c = testUser.Id, RC_Attribution_Channel__c = 'Sales Agents & Resellers');
        acctList.add(customerAcct2);
        
        Account partnerAcct2 = new Account(Name = 'Test Partner account 2', InContact_Service__c = 'Contact Center Basic',
                                           No_of_InContact_Seats__c = 3, Type = 'Partner', Partner_ID__c = '54321', 
                                           RC_Attribution_Channel__c = 'Franchise & Assoc');
        acctList.add(partnerAcct2);

        insert acctList;
        
        List<Order__c> orderList = new List<Order__c>();
        Order__c testOrder = new Order__c(Account__c = testAccount.id, Partner__c = testAccount.id, Order_Date__c = date.today());
        orderList.add(testOrder);
        
        Order__c testOrder2 = new Order__c(Account__c = testAccount2.id, Partner__c = testAccount2.id, Order_Date__c = date.today());
        orderList.add(testOrder2);
        
        Order__c testOrder3 = new Order__c(Account__c = customerAcct.id, Partner__c = partnerAcct.id, Order_Date__c = date.today());
        orderList.add(testOrder3);

        Order__c testOrder4 = new Order__c(Account__c = customerAcct2.id, Partner__c = partnerAcct2.id, Order_Date__c = date.today());
        orderList.add(testOrder4);

        insert orderList;
        
        List<Agent_Credit__c> agcList = new List<Agent_Credit__c>();
        Agent_Credit__c agc = new Agent_Credit__c();
        agc.Name = 'testAgent';
        agc.Account__c = testAccount.Id;
        agc.Order__c = testOrder.Id;
        agc.Compensation_Date__c = date.today();
        agc.Agent_Email__c = UserInfo.getUserEmail();
        agc.OwnerId = UserInfo.getUserId();
        agc.ARR_Booking_Amount_Override__c = 100;
        agc.One_Time_Booking_Amount_Override__c = 100;
        agcList.add(agc);
        
        Agent_Credit__c agc2 = new Agent_Credit__c();
        agc2.Name = 'testAgent2';
        agc2.Account__c = testAccount2.Id;
        agc2.Order__c = testOrder2.Id;
        agc2.Compensation_Date__c = date.today();
        agc2.Agent_Email__c = UserInfo.getUserEmail();
        agc2.OwnerId = UserInfo.getUserId();
        agc2.ARR_Booking_Amount_Override__c = 100;
        agc2.One_Time_Booking_Amount_Override__c = 100;
        agcList.add(agc2);

        Agent_Credit__c agc3 = new Agent_Credit__c();
        agc3.Name = 'testAgent3';
        agc3.Account__c = customerAcct.Id;
        agc3.Order__c = testOrder3.Id;
        agc.Compensation_Date__c = date.today();
        agc3.Agent_Email__c = UserInfo.getUserEmail();
        agc3.OwnerId = UserInfo.getUserId();
        agc3.ARR_Booking_Amount_Override__c = 100;
        agc3.One_Time_Booking_Amount_Override__c = 100;
        agcList.add(agc3);

        Agent_Credit__c agc4 = new Agent_Credit__c();
        agc4.Name = 'testAgent4';
        agc4.Account__c = customerAcct2.Id;
        agc4.Order__c = testOrder4.Id;
        agc4.Compensation_Date__c = date.today();
        agc4.Agent_Email__c = UserInfo.getUserEmail();
        agc4.OwnerId = UserInfo.getUserId();
        agc4.ARR_Booking_Amount_Override__c = 100;
        agc4.One_Time_Booking_Amount_Override__c = 100;
        agcList.add(agc4);        
        insert agcList; 
        
        Account_Split__c asp = new Account_Split__c();
             asp.Account__c = agc.Account__c;
             asp.Role__c = 'VAR Shared Agent';
             asp.Commission__c = 60;
             asp.Booking_for_Sales_AE_2__c = 40;
             asp.Sales_Agent__c = testUser.id;
             asp.Sales_AE_2__c = Userinfo.getUserId();
             asp.Begin_Date__c = Date.today()-2;
             asp.End_Date__c = Date.today() + 2;
            insert asp;
             


    }
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void AgentCreditBeforeInsertTest() {
        
        AgentCreditHelper ach = new AgentCreditHelper();
        
        Agent_Credit__c agc = [SELECT Id, Order__c, Name__c, Account__c, Partner__c, Compensation_Date__c, Agent_Credit_Type__c, Agent_First_Name__c, Agent_Role__c,
                    Agent_Credit_Sub_Type__c,Agent_Credit_Split__c, ARR_Booking_Amount__c,Splitted_automatically__c, One_Time_Booking_Amount__c, ARR_Booking_Amount_Override__c, One_Time_Booking_Amount_Override__c, OwnerId, X12M_Commission_Booking_Amount__c, X12M_Sales_Booking_Amount__c, Agent_Email__c, Agent_Last_Name__c, Agent_Team__c, Agent_Division__c, Agent_SPID__c
                    FROM Agent_Credit__c WHERE Name = 'testAgent'];
        
        List<Agent_Credit__c> newlist = new List<Agent_Credit__c>();
        newlist.add( agc );
        
        Test.startTest();
        AgentCreditHelper.isBeforeInsert(newlist);
      
        
       // AgentCreditHelper.createArronetimerecords(agc, testUser2, testuser3, asplitlist, Commision);
      
       // AgentCreditHelper.Createsplitrecords(newlist);
        
        
        
        
        agc = [
            SELECT Office_Location__c, OwnerId
            FROM Agent_Credit__c
            WHERE Id = :agc.Id
        ];
          Test.stopTest();
       // System.assertEquals(agc.Office_Location__c, null);
        //System.assertEquals(agc.OwnerId, UserInfo.getUserId());
    }
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void AgentCreditBeforeUpdateRCSFTest() {
        AgentCreditHelper ach = new AgentCreditHelper();
        
        Agent_Credit__c agc = [SELECT Id, Name, Account__c, Order__c, Compensation_Date__c, Agent_Email__c, OwnerId FROM Agent_Credit__c WHERE Name = 'testAgent'];
        User agcNewOwner = [SELECT Id, Email FROM User WHERE Name = 'RCSF Sync'];
        
        List<Agent_Credit__c> oldlist = new List<Agent_Credit__c>();
        oldlist.add( agc );
        
        Map<id,Agent_Credit__c> oldMap = new Map<id,Agent_Credit__c>();
        oldMap.put(agc.id , agc);
        
        agc.OwnerId = agcNewOwner.Id;
        
        Test.startTest();
        update agc;
        
        List<Agent_Credit__c> newlist = new List<Agent_Credit__c>();
        newlist.add( agc );
        
        Map<id,Agent_Credit__c> newMap = new Map<id,Agent_Credit__c>();
        newMap.put(agc.id , agc);
        
        AgentCreditHelper.isBeforeUpdate( newList, oldList, newMap, oldMap);
        Test.stopTest();
    }
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void AgentCreditBeforeUpdateRCSFTest2() {
        
        AgentCreditHelper ach = new AgentCreditHelper();
        
        Agent_Credit__c agc = [SELECT Id, Name, Account__c, Order__c, Compensation_Date__c, Agent_Email__c, OwnerId FROM Agent_Credit__c WHERE Name = 'testAgent2'];
        User agcNewOwner = [SELECT Id, Email FROM User WHERE Name = 'RCSF Sync'];
        
        List<Agent_Credit__c> oldlist = new List<Agent_Credit__c>();
        oldlist.add( agc );
        
        Map<id,Agent_Credit__c> oldMap = new Map<id,Agent_Credit__c>();
        oldMap.put(agc.id , agc);
        
        agc.OwnerId = agcNewOwner.Id;
        
        Test.startTest();
        update agc;
        
        List<Agent_Credit__c> newlist = new List<Agent_Credit__c>();
        newlist.add( agc );
        
        Map<id,Agent_Credit__c> newMap = new Map<id,Agent_Credit__c>();
        newMap.put(agc.id , agc);
        
        AgentCreditHelper.isBeforeUpdate( newList, oldList, newMap, oldMap);
        Test.stopTest();
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void TestUpdateParnterChannelManager() {
        AgentCreditHelper ach = new AgentCreditHelper();
                
        User agcNewOwner = [SELECT Id, Email FROM User WHERE LastName = 'Testing12'];
        
        Map<id,Agent_Credit__c> oldMap = new Map<id,Agent_Credit__c>([SELECT Id, Name, Account__c, Order__c, Compensation_Date__c, Agent_Email__c, OwnerId FROM Agent_Credit__c WHERE Name IN ('testAgent3','testAgent4')]);
        List<Agent_Credit__c> oldlist = new List<Agent_Credit__c>(oldMap.values());        
                    
        oldlist[0].OwnerId = agcNewOwner.Id;
        oldlist[1].OwnerId = agcNewOwner.Id;
        
        Test.startTest();
        update oldlist;
        
        List<Agent_Credit__c> newlist = new List<Agent_Credit__c>(oldlist);                
        Map<id,Agent_Credit__c> newMap = new Map<id,Agent_Credit__c>(oldMap);        
        
        AgentCreditHelper.isBeforeUpdate( newList, oldList, newMap, oldMap);
        Test.stopTest();
    }
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void TestInsertParnterChannelManager() {
        
        AgentCreditHelper ach = new AgentCreditHelper();
                        
        List<Agent_Credit__c> newlist = new List<Agent_Credit__c>([SELECT Id, Name, Account__c, Order__c, Compensation_Date__c, Agent_Email__c, OwnerId FROM Agent_Credit__c WHERE Name IN ('testAgent3','testAgent4')]);        
       	Test.startTest();
        AgentCreditHelper.isBeforeInsert(newlist);
        AgentCreditHelper.getCcBccEmailAddresses('Test@ringcentral.com');
      	Test.stopTest();    
          //AgentCreditHelper.Createsplitrecords(newlist);
    }
    
}