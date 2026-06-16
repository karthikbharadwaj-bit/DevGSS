/****************************************************************************************************/
/* Class Name  : Test_AgentcreditsplitHandler
/* Date        : 04-Feb-2021
/* Author      : Ranjani.N
/* Description :Testclass for AgentcreditsplitHandler class
/****************************************************************************************************/
@ istest
public class Test_AgentcreditsplitHandler {

      @testSetup 
    static void agentCreditSetup() {
        Profile p = [select id from profile where name='System Administrator'];
        
        List<User> userList = new List<User>();
        User testUser = new User(alias = 'u111', email='u111@testorg.com',
                                 emailencodingkey='UTF-8', lastname='Testing11', languagelocalekey='en_US',
                                 localesidkey='en_US', profileid = p.Id, country='United States',
                                 timezonesidkey='America/Los_Angeles', username='u111@testorg.com');
        userList.add(testUser);
        
        User testUser3 = new User(alias = 'u111', email='rcsfsync@ringcentral.com',
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
            Id__c = ((String) ValueProviderBuilder.provideDummyId(User.SObjectType, 15).getValue()),
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
                                          No_of_InContact_Seats__c = 3, Type = 'Partner', Inside_Sales_Rep__c = testUser.Id, RC_Attribution_Channel__c = 'Sales Agents & Resellers');
        acctList.add(testAccount);
        
        Account testAccount2 = new Account(Name = 'Test account2', InContact_Service__c = 'Contact Center Basic',
                                           No_of_InContact_Seats__c = 3, Type = 'Partner',
                                           Inside_Sales_Rep__c = testUser3.Id, RC_Attribution_Channel__c = 'Franchise & Assoc');
        acctList.add(testAccount2);

        Account customerAcct = new Account(Name = 'Test Customer account', InContact_Service__c = 'Contact Center Basic',
                                          No_of_InContact_Seats__c = 3, Type = 'Customer', 
                                          Inside_Sales_Rep__c = testUser.Id, RC_Attribution_Channel__c = 'Sales Agents & Resellers');
        acctList.add(customerAcct);
        
        Account partnerAcct = new Account(Name = 'Test Partner account', InContact_Service__c = 'Contact Center Basic',
                                           No_of_InContact_Seats__c = 3, Type = 'Partner', 
                                           Inside_Sales_Rep__c = testUser.Id, RC_Attribution_Channel__c = 'Franchise & Assoc');
        acctList.add(partnerAcct);

        Account customerAcct2 = new Account(Name = 'Test Customer account 2', InContact_Service__c = 'Contact Center Basic',
                                          No_of_InContact_Seats__c = 3, Type = 'Customer', 
                                          Inside_Sales_Rep__c = testUser.Id, RC_Attribution_Channel__c = 'Sales Agents & Resellers');
        acctList.add(customerAcct2);
        
        Account partnerAcct2 = new Account(Name = 'Test Partner account 2', InContact_Service__c = 'Contact Center Basic',
                                           No_of_InContact_Seats__c = 3, Type = 'Partner', 
                                           RC_Attribution_Channel__c = 'Franchise & Assoc');
        acctList.add(partnerAcct2);

        insert acctList;
        
        List<Order__c> orderList = new List<Order__c>();
        Order__c testOrder = new Order__c(Account__c = testAccount.id, Partner__c = testAccount.id, Order_Date__c = date.today(),Commission_ARR_Amount__c = 1000,Commission_One_Time_Amount__c = 2000);
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
        
        //Both > 0
        agc.Name = 'testAgent';
        agc.Account__c = testAccount.Id;
        agc.Order__c = testOrder.Id;
        agc.Compensation_Date__c = date.today();
        agc.Agent_Email__c = UserInfo.getUserEmail();
        agc.OwnerId = UserInfo.getUserId();
        agc.ARR_Booking_Amount_Override__c = 100;
        agc.One_Time_Booking_Amount_Override__c = 100;
        agcList.add(agc);
        
         //ARR > 0,Onetime <0
        /*Agent_Credit__c agc2 = new Agent_Credit__c();
        agc2.Name = 'testAgent2';
        agc2.Account__c = testAccount2.Id;
        agc2.Order__c = testOrder2.Id;
        agc2.Compensation_Date__c = date.today();
        agc2.Agent_Email__c = UserInfo.getUserEmail();
        agc2.OwnerId = UserInfo.getUserId();
        agc2.ARR_Booking_Amount_Override__c = 100;
        agc2.One_Time_Booking_Amount_Override__c = - 100;
        agcList.add(agc2);
		 //ARR > 0,Onetime = 0
        Agent_Credit__c agc3 = new Agent_Credit__c();
        agc3.Name = 'testAgent3';
        agc3.Account__c = customerAcct.Id;
        agc3.Order__c = testOrder3.Id;
        agc.Compensation_Date__c = date.today();
        agc3.Agent_Email__c = UserInfo.getUserEmail();
        agc3.OwnerId = UserInfo.getUserId();
        agc3.ARR_Booking_Amount_Override__c = 100;
        agc3.One_Time_Booking_Amount_Override__c = 0;
        agcList.add(agc3);

        Agent_Credit__c agc4 = new Agent_Credit__c();
        agc4.Name = 'testAgent4';
        agc4.Account__c = customerAcct2.Id;
        agc4.Order__c = testOrder4.Id;
        agc4.Compensation_Date__c = date.today();
        agc4.Agent_Email__c = UserInfo.getUserEmail();
        agc4.OwnerId = UserInfo.getUserId();
        agc4.ARR_Booking_Amount_Override__c = 0;
        agc4.One_Time_Booking_Amount_Override__c = 100;
        agcList.add(agc4);   */     
        insert agcList; 


    }
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
     @isTest
    static void AgentCreditBeforeInsertTest() {
        
        AgentCreditHelper ach = new AgentCreditHelper();
         List <Account_Split__c>asplitlist = new List <Account_Split__c>();
         List < String > Commision = new List < String >();
         List <id>aspid = new List <id>();
         List<Agent_Credit__c> agc = [SELECT Id, Order__c, Name__c, Account__c, Partner__c, Compensation_Date__c, Agent_Credit_Type__c, Agent_First_Name__c, Agent_Role__c,
                    Agent_Credit_Sub_Type__c, ARR_Booking_Amount__c, One_Time_Booking_Amount__c, ARR_Booking_Amount_Override__c, One_Time_Booking_Amount_Override__c, OwnerId, X12M_Commission_Booking_Amount__c, X12M_Sales_Booking_Amount__c, Agent_Email__c, Agent_Last_Name__c, Agent_Team__c, Agent_Division__c, Agent_SPID__c
                    FROM Agent_Credit__c WHERE Name Like '%testAgent%' Order by id Asc];
         User usr =  [SELECT Id, Email, FirstName, LastName, Team__c, Division,ManagerId,Manager.FirstName, Manager.LastName, Manager.Email, UserRole.Name, PID__c FROM User WHERE LastName = 'Testing12' LIMIT 1];
          User usr1 =  [SELECT Id, Email, FirstName, LastName, Team__c, Division,ManagerId,Manager.FirstName, Manager.LastName, Manager.Email, UserRole.Name, PID__c FROM User WHERE  Email = 'rcsfsync@ringcentral.com'LIMIT 1];
        for(Agent_Credit__c ag:agc)
         {
             Account_Split__c asp = new Account_Split__c();
             asp.Account__c = ag.Account__c;
             asp.Role__c = 'VAR Shared Agent';
             asp.Commission__c = 60;
             asp.Booking_for_Sales_AE_2__c = 40;
             asp.Sales_Agent__c = usr.id;
             asp.Sales_AE_2__c = Userinfo.getUserId();
             asp.Begin_Date__c = Date.today();
             asp.End_Date__c = Date.today() + 2;
             aspid.add(asp.id);
             asplitlist.add(asp);
             Commision.add(String.valueOf(asp.Commission__c));
         }
        insert asplitlist;
        
         //AgentcreditsplitHandler ac = new AgentcreditsplitHandler();
         Test.startTest();
        AgentcreditsplitHandler.onlyARR(agc[0],usr,usr1,aspid,Commision);
        AgentcreditsplitHandler.onlyonetime(agc[0],usr,usr1,aspid,Commision);
        AgentcreditsplitHandler.Positive_ARR(agc[0],usr,usr1,aspid,Commision);
        AgentcreditsplitHandler.Positive_onetime(agc[0],usr,usr1,aspid,Commision);
        AgentCreditHelper.createArronetimerecords(agc[0],usr,usr1,aspid,Commision);
        AgentCreditHelper.createAgentcredit(agc[0],usr,usr1,aspid,Commision);
         Test.stopTest();
       
       
        
         }

}