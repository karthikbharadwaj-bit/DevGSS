/****************************************************************************************************/
/* Class Name  : AgentcreditsplitHandler
/* Date        : 04-Feb-2021
/* Author      : Ranjani.N
/* Description : Class to Calcuate Booking amount and create Agent credit records
/****************************************************************************************************/
public class AgentcreditsplitHandler {
    public static string SOPS_Adjustment_One_time = 'SOPS Adjustment - One-time';
    public static string SOPS_Adjustment = 'SOPS Adjustment';
    public static List < Agent_Credit__c > lACNew = new List < Agent_Credit__c > ();
    public static List < Agent_Credit__c > lACUpdate = new List < Agent_Credit__c > ();
    public class AgentsplitAfter extends Triggers.TriggerHandlerBase {

    /****************************************************************************************************/
    /* Method Name  : handle
    /* Description  : Queries the accountsplit data and commission to create Agent credit records
    /****************************************************************************************************/
        override public void handle() {

            if (Trigger.isInsert || Trigger.isUpdate) {
                List < Date > Startdate = new List < Date > ();
                List < Date > Enddate = new List < Date > ();
                Set < id > Accountids = new Set < id > ();
               
                List < Id > UserIds = new List < Id > ();
                List < String > Commision = new List < String > ();
                List < id > Agentsplitid = new List < id > ();
                List < Agent_Credit__c > Agentcreditonetime = new List < Agent_Credit__c > ();
                List < Agent_Credit__c > AgentcreditARR = new List < Agent_Credit__c > ();
                Boolean isUpdated;
                Account_Split__c accspOldObj;
                for (Account_Split__c AC: (List < Account_Split__c > )Trigger.New) {

                    
                    if (AC.Commission__c != null) {
                        Startdate.add(AC.Begin_Date__c);
                        Enddate.add(AC.End_Date__c);
                        Accountids.add(AC.Account__c);
                        UserIds.add(AC.Sales_Agent__c);
                        UserIds.add(AC.Sales_AE_2__c);
                        Agentsplitid.add(AC.id);
                        Commision.add(String.valueOf(AC.Booking_for_Sales_AE_2__c));
                    }
                }
                system.debug('Uids'+UserIds);
                List < Agent_Credit__c > Agentcredit = [SELECT Id, Order__c, Name__c, Account__c, Partner__c, Compensation_Date__c, Agent_Credit_Type__c, Agent_First_Name__c, Agent_Role__c,
                    Agent_Credit_Sub_Type__c, ARR_Booking_Amount__c, One_Time_Booking_Amount__c, ARR_Booking_Amount_Override__c, One_Time_Booking_Amount_Override__c, OwnerId, X12M_Commission_Booking_Amount__c, X12M_Sales_Booking_Amount__c, Agent_Email__c, Agent_Last_Name__c, Agent_Team__c, Agent_Division__c, Agent_SPID__c
                    FROM Agent_Credit__c
                    WHERE Account__c IN: Accountids and Compensation_Date__c >= : Startdate and Compensation_Date__c <= : Enddate and Splitted_automatically__c = false Order by CreatedDate asc];
                  User  mUser1 = new User();
                  User  mUser2 = new User();
               /* if (UserIds.size() > 0) {
                    mUser1 = [
                        SELECT Id, Email, FirstName, LastName, Team__c, Division,ManagerId,Manager.FirstName, Manager.LastName, Manager.Email, UserRole.Name, PID__c
                        FROM User
                        WHERE Id =: UserIds[0]
                    ];
                    mUser2 = [
                        SELECT Id, Email, FirstName, LastName, Team__c, Division,ManagerId,Manager.FirstName, Manager.LastName, Manager.Email, UserRole.Name, PID__c
                        FROM User
                        WHERE Id =: UserIds[1]
                    ];
                }*/
               List<user> Userlst = [
                        SELECT Id, Email, FirstName, LastName, Team__c, Division,ManagerId,Manager.FirstName, Manager.LastName, Manager.Email, UserRole.Name, PID__c
                        FROM User
                        WHERE Id IN : UserIds
                    ];
              
                
                system.debug('UserIds'+UserIds);
                
                 for (Agent_Credit__c agcredit: Agentcredit) {
                     
                       if(UserIds[0] != null && UserIds[1] != null)
                       {
                             mUser1 = Userlst[0];//AE1
               				 mUser2 = Userlst[1];//AE2
                            createAgentcredit(agcredit,mUser1,mUser2,Agentsplitid,Commision);
                       }
					 
                    }
            
               

            }
        }
        
    /****************************************************************************************************/
    /* Method Name  : CreateAgentcredit
    /* Parameters   : List of Agentcredit,user and commision%
    /* Return Type  : void
    /* Description  : Create Agent credit record for Agent 2 and update Agent 1 record
    /****************************************************************************************************/
        Public void createAgentcredit( Agent_Credit__c Agentcredit,User  mUser1,User  mUser2 ,List < id > Agentsplitid, List < String > Commision  )
        {
              List < String > Agent2 = new list < String > ();
             system.debug('mUser1'+mUser1);
             system.debug('mUser2'+mUser2);
              List < Agent_Credit__c > lACNew = new List < Agent_Credit__c > ();
              List < Agent_Credit__c > lACUpdate = new List < Agent_Credit__c > ();
                
             if (Agentcredit != null) {
                   

                  if(Agentcredit.ARR_Booking_Amount__c > 0 && (Agentcredit.One_Time_Booking_Amount__c == null || Agentcredit.One_Time_Booking_Amount__c == 0 ))
                        {
                           AgentcreditsplitHandler.onlyARR(Agentcredit,mUser1,mUser2,Agentsplitid,Commision);
                        }
                 if(Agentcredit.One_Time_Booking_Amount__c > 0 && (Agentcredit.ARR_Booking_Amount__c == null || Agentcredit.ARR_Booking_Amount__c == 0 ))
                        {
                           AgentcreditsplitHandler.onlyonetime(Agentcredit,mUser1,mUser2,Agentsplitid,Commision);
                        }
                        if (Agentcredit.ARR_Booking_Amount__c > 0 && Agentcredit.One_Time_Booking_Amount__c > 0) {
                            createArronetimerecords(Agentcredit,mUser1,mUser2,Agentsplitid,Commision);
                        }
                         if (Agentcredit.ARR_Booking_Amount__c > 0 && Agentcredit.One_Time_Booking_Amount__c < 0) {
                             
                             AgentcreditsplitHandler.Positive_ARR(Agentcredit,mUser1,mUser2,Agentsplitid,Commision);
                         }
                 	if (Agentcredit.ARR_Booking_Amount__c < 0 && Agentcredit.One_Time_Booking_Amount__c > 0) {
                             
                              AgentcreditsplitHandler.Positive_onetime(Agentcredit,mUser1,mUser2,Agentsplitid,Commision);
                         }

                  
                   
             }
            
        }
    /****************************************************************************************************/
    /* Method Name  : CreateArronetimerecords
    /* Parameters   : List of Agentcredit,user and Decimals values of commision and sales booking amount of Agent1 and Agent2
    /* Return Type  : void
    /* Description  : Create Agent credit record for Agent 2 and update Agent 1 record
    /****************************************************************************************************/
        @Testvisible
        Private  List<Agent_Credit__c> createArronetimerecords(Agent_Credit__c Agentcredit,User mUser1,User mUser2,List <id>Agentsplitid,List < String > Commision)
        {
            					Decimal Agent1bookingpercent = 0;
					Decimal myNewAmountUpdate = 0;
					Decimal myNewAmountSalesUpdate = 0;
                    Decimal myNewAmountAdd = 0;
                    Decimal myNewAmountSalesAdd = 0;
                    Agent1bookingpercent = 100 - Decimal.valueOf(Commision[0]);
                        
                    if (Agentcredit.ARR_Booking_Amount_Override__c != null) {
                        myNewAmountAdd = Agentcredit.ARR_Booking_Amount_Override__c * (Decimal.valueOf(Commision[0]) / 100);
                        myNewAmountUpdate = Agentcredit.ARR_Booking_Amount_Override__c * (Agent1bookingpercent / 100);
                    }
                 else if (Agentcredit.ARR_Booking_Amount__c != null)
                 {

                        myNewAmountAdd = Agentcredit.ARR_Booking_Amount__c * (Decimal.valueOf(Commision[0]) / 100);
                        myNewAmountUpdate = Agentcredit.ARR_Booking_Amount__c * (Agent1bookingpercent / 100);
                     
                 }
                    if (Agentcredit.One_Time_Booking_Amount_Override__c != null) {
                        myNewAmountSalesAdd = Agentcredit.One_Time_Booking_Amount_Override__c * (Decimal.valueOf(Commision[0]) / 100);
                        myNewAmountSalesUpdate = Agentcredit.One_Time_Booking_Amount_Override__c * (Agent1bookingpercent / 100);
                    }
                    else if(Agentcredit.One_Time_Booking_Amount__c != null)
                      {
                        myNewAmountSalesAdd = Agentcredit.One_Time_Booking_Amount__c * (Decimal.valueOf(Commision[0]) / 100);
                        myNewAmountSalesUpdate = Agentcredit.One_Time_Booking_Amount__c * (Agent1bookingpercent / 100);
                    }
                   
            List < Agent_Credit__c >  agcredit = new List < Agent_Credit__c > ();
            List < Agent_Credit__c > lACUpdate = new List < Agent_Credit__c > ();
            
            Agent_Credit__c aNew = new Agent_Credit__c(
                              	Account__c = Agentcredit.Account__c,
                                X12M_Commission_Booking_Amount__c = Agentcredit.X12M_Commission_Booking_Amount__c,
                                X12M_Sales_Booking_Amount__c = Agentcredit.X12M_Sales_Booking_Amount__c,
                                Agent_Credit_Type__c = Agentcredit.Agent_Credit_Type__c,

                                Compensation_Date__c = Agentcredit.Compensation_Date__c,
                                Order__c = Agentcredit.Order__c,
                                Partner__c = Agentcredit.Partner__c,
                                Agent_Credit_Sub_Type__c = SOPS_Adjustment_One_time,
                                Agent_Credit_Split__c = Agentsplitid[0],
                                Agent_Email__c = mUser2.Email,
                                Agent_First_Name__c = mUser2.FirstName,
                                Agent_Last_Name__c = mUser2.LastName,
                                Agent_Team__c = mUser2.Team__c,
                                Agent_Division__c = mUser2.Division,
                                Agent_Role__c = mUser2.UserRole.Name,
                                Agent_SPID__c = mUser2.PID__c,
                				Agent_Manager_First_Name__c =  mUser2.Manager.FirstName,
                                Agent_Manager_Last_Name__c = mUser2.Manager.LastName,
                				Agent_Manager_Email__c = mUser2.Manager.Email,
                                One_Time_Booking_Amount_Override__c = myNewAmountSalesAdd,
                				OwnerId = mUser2.id,
                				Splitted_automatically__c = true,
                				ARR_Booking_Amount_Override__c = 0
                            	
                               );
              agcredit.add(aNew);
            //ARR  AE2
                            Agent_Credit__c aNewonetime = new Agent_Credit__c(
                                    Account__c = Agentcredit.Account__c,
                                    X12M_Commission_Booking_Amount__c = Agentcredit.X12M_Commission_Booking_Amount__c,
                                    X12M_Sales_Booking_Amount__c = Agentcredit.X12M_Sales_Booking_Amount__c,
                                    Agent_Credit_Type__c = Agentcredit.Agent_Credit_Type__c,

                                    Compensation_Date__c = Agentcredit.Compensation_Date__c,
                                    Order__c = Agentcredit.Order__c,
                                    Partner__c = Agentcredit.Partner__c,
                                    Agent_Credit_Sub_Type__c = SOPS_Adjustment,
                                    Agent_Credit_Split__c = Agentsplitid[0],
                                    Agent_Email__c = mUser2.Email,
                                    Agent_First_Name__c = mUser2.FirstName,
                                    Agent_Last_Name__c = mUser2.LastName,
                                    Agent_Team__c = mUser2.Team__c,
                                    Agent_Division__c = mUser2.Division,
                                    Agent_Role__c = mUser2.UserRole.Name,
                                    Agent_SPID__c = mUser2.PID__c,
                                    ARR_Booking_Amount_Override__c =myNewAmountAdd,
                                	Agent_Manager_First_Name__c =  mUser2.Manager.FirstName,
                                	Agent_Manager_Last_Name__c = mUser2.Manager.LastName,
                					Agent_Manager_Email__c = mUser2.Manager.Email,
                                	OwnerId = mUser2.id,
                                	Splitted_automatically__c = true,
                                    One_Time_Booking_Amount_Override__c = 0);
                            agcredit.add(aNewonetime);
                                system.debug('Email- AE2'+mUser1.Email);
                                system.debug('Email- AE1'+mUser2.Email);
            
                            //aNewonetime  AE1
                            Agent_Credit__c aeoldonetime = new Agent_Credit__c(
                                    Account__c = Agentcredit.Account__c,
                                    X12M_Commission_Booking_Amount__c =  Agentcredit.X12M_Commission_Booking_Amount__c,
                                    X12M_Sales_Booking_Amount__c =  Agentcredit.X12M_Sales_Booking_Amount__c,
                                    Agent_Credit_Type__c = Agentcredit.Agent_Credit_Type__c,

                                    Compensation_Date__c = Agentcredit.Compensation_Date__c,
                                    Order__c = Agentcredit.Order__c,
                                    Partner__c = Agentcredit.Partner__c,
                                    Agent_Credit_Sub_Type__c = SOPS_Adjustment_One_time,
                                    Agent_Credit_Split__c = Agentsplitid[0],
                                    Agent_Email__c = mUser1.Email,
                                    Agent_First_Name__c = mUser1.FirstName,
                                    Agent_Last_Name__c = mUser1.LastName,
                                    Agent_Team__c =mUser1.Team__c,
                                    Agent_Division__c = mUser1.Division,
                                    Agent_Role__c = mUser1.UserRole.Name,
                                    Agent_SPID__c = mUser1.PID__c,
                                    ARR_Booking_Amount_Override__c = 0,
                                	OwnerId = mUser1.id,
                                	Agent_Manager_First_Name__c =  mUser1.Manager.FirstName,
                                	Agent_Manager_Last_Name__c = mUser1.Manager.LastName,
                					Agent_Manager_Email__c = mUser1.Manager.Email,
                                	Splitted_automatically__c = true,
                                    One_Time_Booking_Amount_Override__c = myNewAmountSalesUpdate);
                            agcredit.add(aeoldonetime);
              if (agcredit.size() > 0) {
                  try
                  {
                      insert agcredit;
                        System.debug('Agent Credit onetime-ARR >>>>> ' + agcredit);
                    }
                    catch(dmlexception e)
                        {
                           // If DML failed, ends up here
                          system.debug('Error inserting Agentcredit: ' + e);
                        }
                        
                    }
             Agent_Credit__c aUpdate = new Agent_Credit__c();
                    aUpdate.Id = Agentcredit.id;
                    aUpdate.Agent_Credit_Split__c = Agentsplitid[0];
                    aUpdate.Agent_Credit_Sub_Type__c = SOPS_Adjustment;
                   aUpdate.ARR_Booking_Amount_Override__c = myNewAmountUpdate;
                    aUpdate.OwnerId =mUser1.Id;
            		aUpdate.Agent_Email__c = mUser1.Email;
                    aUpdate.Agent_First_Name__c = mUser1.FirstName;
                    aUpdate.Agent_Last_Name__c = mUser1.LastName;
                    aUpdate.Agent_Team__c =mUser1.Team__c;
                    aUpdate.Agent_Division__c = mUser1.Division;
                    aUpdate.Agent_Role__c = mUser1.UserRole.Name;
                    aUpdate.Agent_SPID__c = mUser1.PID__c;
                    aUpdate.Agent_Manager_First_Name__c =  mUser1.Manager.FirstName;
                    aUpdate.Agent_Manager_Last_Name__c = mUser1.Manager.LastName;
                	aUpdate.Agent_Manager_Email__c = mUser1.Manager.Email;
                    //aUpdate.X12M_Commission_Booking_Amount__c = myNewAmountUpdate;
                    //aUpdate.X12M_Sales_Booking_Amount__c = myNewAmountSalesUpdate;
                    aUpdate.One_Time_Booking_Amount_Override__c = 0;
                    lACUpdate.add(aUpdate);

                    if (lACUpdate.size() > 0) {
                        try{

                        update lACUpdate;
                        System.debug('Agent Credit for Update >>>>> ' + lACUpdate);
                        }
                        catch(dmlexception e)
                        {
                           // If DML failed, ends up here
                          system.debug('Error Updating Agentcredit: ' + e);
                        }
                    }

        return agcredit;
                        }
        
         }
     public static void onlyARR(Agent_Credit__c Agentcredit,User mUser1,User mUser2,List <id>Agentsplitid,List < String > Commision)
		{
            Decimal Agent1bookingpercent = 0;
					Decimal myNewAmountUpdate = 0;
					Decimal myNewAmountSalesUpdate = 0;
                    Decimal myNewAmountAdd = 0;
                    Decimal myNewAmountSalesAdd = 0;
                    Agent1bookingpercent = 100 - Decimal.valueOf(Commision[0]);
                        
                    if (Agentcredit.ARR_Booking_Amount_Override__c != null) {
                        myNewAmountAdd = Agentcredit.ARR_Booking_Amount_Override__c * (Decimal.valueOf(Commision[0]) / 100);
                        myNewAmountUpdate = Agentcredit.ARR_Booking_Amount_Override__c * (Agent1bookingpercent / 100);
                    }
                 else if (Agentcredit.ARR_Booking_Amount__c != null)
                 {

                        myNewAmountAdd = Agentcredit.ARR_Booking_Amount__c * (Decimal.valueOf(Commision[0]) / 100);
                        myNewAmountUpdate = Agentcredit.ARR_Booking_Amount__c * (Agent1bookingpercent / 100);
                     
                 }
                    if (Agentcredit.One_Time_Booking_Amount_Override__c != null) {
                        myNewAmountSalesAdd = Agentcredit.One_Time_Booking_Amount_Override__c * (Decimal.valueOf(Commision[0]) / 100);
                        myNewAmountSalesUpdate = Agentcredit.One_Time_Booking_Amount_Override__c * (Agent1bookingpercent / 100);
                    }
                    else if(Agentcredit.One_Time_Booking_Amount__c != null)
                      {
                        myNewAmountSalesAdd = Agentcredit.One_Time_Booking_Amount__c * (Decimal.valueOf(Commision[0]) / 100);
                        myNewAmountSalesUpdate = Agentcredit.One_Time_Booking_Amount__c * (Agent1bookingpercent / 100);
                    }
                   
		Agent_Credit__c aUpdate1 = new Agent_Credit__c();
                                aUpdate1.Id = Agentcredit.id;
                                aUpdate1.Agent_Credit_Split__c = Agentsplitid[0];
                                aUpdate1.Agent_Credit_Sub_Type__c = SOPS_Adjustment;
                                aUpdate1.ARR_Booking_Amount_Override__c = myNewAmountUpdate;
                              	aUpdate1.OwnerId =mUser1.Id;
            					
                                aUpdate1.Agent_Email__c = mUser1.Email;
                                aUpdate1.Agent_First_Name__c = mUser1.FirstName;
                                aUpdate1.Agent_Last_Name__c = mUser1.LastName;
                                aUpdate1.Agent_Team__c =mUser1.Team__c;
                                aUpdate1.Agent_Division__c = mUser1.Division;
                                aUpdate1.Agent_Role__c = mUser1.UserRole.Name;
                                aUpdate1.Agent_SPID__c = mUser1.PID__c;
                                aUpdate1.Agent_Manager_First_Name__c =  mUser1.Manager.FirstName;
                                aUpdate1.Agent_Manager_Last_Name__c = mUser1.Manager.LastName;
                                aUpdate1.Agent_Manager_Email__c = mUser1.Manager.Email;
                                 Agent_Credit__c aNewAe2 = new Agent_Credit__c(
                                OwnerId = mUser2.id,
                                Account__c = Agentcredit.Account__c,
                                X12M_Commission_Booking_Amount__c = Agentcredit.X12M_Commission_Booking_Amount__c,
                                X12M_Sales_Booking_Amount__c = Agentcredit.X12M_Sales_Booking_Amount__c,
                                Agent_Credit_Type__c = Agentcredit.Agent_Credit_Type__c,

                                Compensation_Date__c = Agentcredit.Compensation_Date__c,
                                Order__c = Agentcredit.Order__c,
                                Partner__c = Agentcredit.Partner__c,
                                Agent_Credit_Sub_Type__c = SOPS_Adjustment_One_time,
                                Agent_Credit_Split__c = Agentsplitid[0],
                                Agent_Email__c = mUser2.Email,
                                Agent_First_Name__c = mUser2.FirstName,
                                Agent_Last_Name__c = mUser2.LastName,
                                Agent_Team__c = mUser2.Team__c,
                                Agent_Division__c = mUser2.Division,
                                Agent_Role__c = mUser2.UserRole.Name,
                                Agent_SPID__c = mUser2.PID__c,
                                Agent_Manager_First_Name__c =  mUser1.Manager.FirstName,
                    			Agent_Manager_Last_Name__c = mUser1.Manager.LastName,
                				Agent_Manager_Email__c = mUser1.Manager.Email,
                                One_Time_Booking_Amount_Override__c = 0,
                                Splitted_automatically__c = true,
                                ARR_Booking_Amount_Override__c = myNewAmountAdd                        	
                               );
            lACNew.add(aNewAe2);
            lACUpdate.add(aUpdate1);
            AgentcreditsplitHandler.AgentcreditDML(lACNew,lACUpdate);
			
		}
     
		public static void onlyonetime(Agent_Credit__c Agentcredit,User mUser1,User mUser2,List <id>Agentsplitid,List < String > Commision)
		{
            Decimal Agent1bookingpercent = 0;
					Decimal myNewAmountUpdate = 0;
					Decimal myNewAmountSalesUpdate = 0;
                    Decimal myNewAmountAdd = 0;
                    Decimal myNewAmountSalesAdd = 0;
                    Agent1bookingpercent = 100 - Decimal.valueOf(Commision[0]);
                        
                    if (Agentcredit.ARR_Booking_Amount_Override__c != null) {
                        myNewAmountAdd = Agentcredit.ARR_Booking_Amount_Override__c * (Decimal.valueOf(Commision[0]) / 100);
                        myNewAmountUpdate = Agentcredit.ARR_Booking_Amount_Override__c * (Agent1bookingpercent / 100);
                    }
                 else if (Agentcredit.ARR_Booking_Amount__c != null)
                 {

                        myNewAmountAdd = Agentcredit.ARR_Booking_Amount__c * (Decimal.valueOf(Commision[0]) / 100);
                        myNewAmountUpdate = Agentcredit.ARR_Booking_Amount__c * (Agent1bookingpercent / 100);
                     
                 }
                    if (Agentcredit.One_Time_Booking_Amount_Override__c != null) {
                        myNewAmountSalesAdd = Agentcredit.One_Time_Booking_Amount_Override__c * (Decimal.valueOf(Commision[0]) / 100);
                        myNewAmountSalesUpdate = Agentcredit.One_Time_Booking_Amount_Override__c * (Agent1bookingpercent / 100);
                    }
                    else if(Agentcredit.One_Time_Booking_Amount__c != null)
                      {
                        myNewAmountSalesAdd = Agentcredit.One_Time_Booking_Amount__c * (Decimal.valueOf(Commision[0]) / 100);
                        myNewAmountSalesUpdate = Agentcredit.One_Time_Booking_Amount__c * (Agent1bookingpercent / 100);
                    }
                   
		Agent_Credit__c aUpdate2 = new Agent_Credit__c();
                                aUpdate2.Id = Agentcredit.id;
                                aUpdate2.Agent_Credit_Split__c = Agentsplitid[0];
                                aUpdate2.Agent_Credit_Sub_Type__c = SOPS_Adjustment_One_time;
                                aUpdate2.One_Time_Booking_Amount_Override__c = myNewAmountSalesUpdate;
                            	aUpdate2.OwnerId =mUser1.Id;
            					
                                aUpdate2.Agent_Email__c = mUser1.Email;
                                aUpdate2.Agent_First_Name__c = mUser1.FirstName;
                                aUpdate2.Agent_Last_Name__c = mUser1.LastName;
                                aUpdate2.Agent_Team__c =mUser1.Team__c;
                                aUpdate2.Agent_Division__c = mUser1.Division;
                                aUpdate2.Agent_Role__c = mUser1.UserRole.Name;
                                aUpdate2.Agent_SPID__c = mUser1.PID__c;
                                aUpdate2.Agent_Manager_First_Name__c =  mUser1.Manager.FirstName;
                                aUpdate2.Agent_Manager_Last_Name__c = mUser1.Manager.LastName;
                                aUpdate2.Agent_Manager_Email__c = mUser1.Manager.Email;
                               Agent_Credit__c aNew1AE2 = new Agent_Credit__c(
                                OwnerId = mUser2.Id,
                                Account__c = Agentcredit.Account__c,
                                X12M_Commission_Booking_Amount__c = Agentcredit.X12M_Commission_Booking_Amount__c,
                                X12M_Sales_Booking_Amount__c = Agentcredit.X12M_Sales_Booking_Amount__c,
                                Agent_Credit_Type__c = Agentcredit.Agent_Credit_Type__c,

                                Compensation_Date__c = Agentcredit.Compensation_Date__c,
                                Order__c = Agentcredit.Order__c,
                                Partner__c = Agentcredit.Partner__c,
                                Agent_Credit_Sub_Type__c = SOPS_Adjustment_One_time,
                                Agent_Credit_Split__c = Agentsplitid[0],
                                Agent_Email__c = mUser2.Email,
                                Agent_First_Name__c = mUser2.FirstName,
                                Agent_Last_Name__c = mUser2.LastName,
                                Agent_Team__c = mUser2.Team__c,
                                Agent_Division__c = mUser2.Division,
                                Agent_Role__c = mUser2.UserRole.Name,
                                Agent_SPID__c = mUser2.PID__c,
                                One_Time_Booking_Amount_Override__c = myNewAmountSalesAdd,
                                Splitted_automatically__c = true,
                                Agent_Manager_First_Name__c =  mUser2.Manager.FirstName,
                    			Agent_Manager_Last_Name__c = mUser2.Manager.LastName,
                				Agent_Manager_Email__c = mUser2.Manager.Email,
                                ARR_Booking_Amount_Override__c = 0                        	
                               );
              lACNew.add(aNew1AE2);
            lACUpdate.add(aUpdate2);
             AgentcreditsplitHandler.AgentcreditDML(lACNew,lACUpdate);
		}
    public static void Positive_ARR( Agent_Credit__c  Agentcredit,User mUser1,User mUser2,List <id>Agentsplitid,List < String > Commision)
		{
            					Decimal Agent1bookingpercent = 0;
					Decimal myNewAmountUpdate = 0;
					Decimal myNewAmountSalesUpdate = 0;
                    Decimal myNewAmountAdd = 0;
                    Decimal myNewAmountSalesAdd = 0;
                    Agent1bookingpercent = 100 - Decimal.valueOf(Commision[0]);
                        
                    if (Agentcredit.ARR_Booking_Amount_Override__c != null) {
                        myNewAmountAdd = Agentcredit.ARR_Booking_Amount_Override__c * (Decimal.valueOf(Commision[0]) / 100);
                        myNewAmountUpdate = Agentcredit.ARR_Booking_Amount_Override__c * (Agent1bookingpercent / 100);
                    }
                 else if (Agentcredit.ARR_Booking_Amount__c != null)
                 {

                        myNewAmountAdd = Agentcredit.ARR_Booking_Amount__c * (Decimal.valueOf(Commision[0]) / 100);
                        myNewAmountUpdate = Agentcredit.ARR_Booking_Amount__c * (Agent1bookingpercent / 100);
                     
                 }
                    if (Agentcredit.One_Time_Booking_Amount_Override__c != null) {
                        myNewAmountSalesAdd = Agentcredit.One_Time_Booking_Amount_Override__c * (Decimal.valueOf(Commision[0]) / 100);
                        myNewAmountSalesUpdate = Agentcredit.One_Time_Booking_Amount_Override__c * (Agent1bookingpercent / 100);
                    }
                    else if(Agentcredit.One_Time_Booking_Amount__c != null)
                      {
                        myNewAmountSalesAdd = Agentcredit.One_Time_Booking_Amount__c * (Decimal.valueOf(Commision[0]) / 100);
                        myNewAmountSalesUpdate = Agentcredit.One_Time_Booking_Amount__c * (Agent1bookingpercent / 100);
                    }
                   
		Agent_Credit__c aUpdate = new Agent_Credit__c();
                                aUpdate.Id = Agentcredit.id;
                                aUpdate.Agent_Credit_Split__c = Agentsplitid[0];
                                aUpdate.Agent_Credit_Sub_Type__c = SOPS_Adjustment;
                                aUpdate.ARR_Booking_Amount_Override__c = myNewAmountUpdate;
                                aUpdate.OwnerId =mUser1.Id;
            					aUpdate.Agent_Email__c = mUser1.Email;
                    			aUpdate.Agent_First_Name__c = mUser1.FirstName;
                    			aUpdate.Agent_Last_Name__c = mUser1.LastName;
                    			aUpdate.Agent_Team__c =mUser1.Team__c;
                   				 aUpdate.Agent_Division__c = mUser1.Division;
                   				 aUpdate.Agent_Role__c = mUser1.UserRole.Name;
                   				 aUpdate.Agent_SPID__c = mUser1.PID__c;
                    			 aUpdate.Agent_Manager_First_Name__c =  mUser1.Manager.FirstName;
                    			 aUpdate.Agent_Manager_Last_Name__c = mUser1.Manager.LastName;
                				 aUpdate.Agent_Manager_Email__c = mUser1.Manager.Email;
                                
                                 Agent_Credit__c aNew = new Agent_Credit__c(
                                OwnerId = mUser2.Id,
                                Account__c = Agentcredit.Account__c,
                                X12M_Commission_Booking_Amount__c = Agentcredit.X12M_Commission_Booking_Amount__c,
                                X12M_Sales_Booking_Amount__c = Agentcredit.X12M_Sales_Booking_Amount__c,
                                Agent_Credit_Type__c = Agentcredit.Agent_Credit_Type__c,

                                Compensation_Date__c = Agentcredit.Compensation_Date__c,
                                Order__c = Agentcredit.Order__c,
                                Partner__c = Agentcredit.Partner__c,
                                Agent_Credit_Sub_Type__c = SOPS_Adjustment_One_time,
                                Agent_Credit_Split__c = Agentsplitid[0],
                                Agent_Email__c = mUser2.Email,
                                Agent_First_Name__c = mUser2.FirstName,
                                Agent_Last_Name__c = mUser2.LastName,
                                Agent_Team__c = mUser2.Team__c,
                                Agent_Division__c = mUser2.Division,
                                Agent_Role__c = mUser2.UserRole.Name,
                                Agent_SPID__c = mUser2.PID__c,
                                Agent_Manager_First_Name__c =  mUser2.Manager.FirstName,
                    			Agent_Manager_Last_Name__c = mUser2.Manager.LastName,
                				Agent_Manager_Email__c = mUser2.Manager.Email,
                                One_Time_Booking_Amount_Override__c = 0,
                                Splitted_automatically__c = true,
                                ARR_Booking_Amount_Override__c = myNewAmountAdd                        	
                               );
                 
             lACNew.add(aNew);
            lACUpdate.add(aUpdate);
             AgentcreditsplitHandler.AgentcreditDML(lACNew,lACUpdate);
		}
     public static void Positive_onetime( Agent_Credit__c  Agentcredit,User mUser1,User mUser2,List <id>Agentsplitid,List < String > Commision)
		{
            					Decimal Agent1bookingpercent = 0;
					Decimal myNewAmountUpdate = 0;
					Decimal myNewAmountSalesUpdate = 0;
                    Decimal myNewAmountAdd = 0;
                    Decimal myNewAmountSalesAdd = 0;
                    Agent1bookingpercent = 100 - Decimal.valueOf(Commision[0]);
                        
                    if (Agentcredit.ARR_Booking_Amount_Override__c != null) {
                        myNewAmountAdd = Agentcredit.ARR_Booking_Amount_Override__c * (Decimal.valueOf(Commision[0]) / 100);
                        myNewAmountUpdate = Agentcredit.ARR_Booking_Amount_Override__c * (Agent1bookingpercent / 100);
                    }
                 else if (Agentcredit.ARR_Booking_Amount__c != null)
                 {

                        myNewAmountAdd = Agentcredit.ARR_Booking_Amount__c * (Decimal.valueOf(Commision[0]) / 100);
                        myNewAmountUpdate = Agentcredit.ARR_Booking_Amount__c * (Agent1bookingpercent / 100);
                     
                 }
                    if (Agentcredit.One_Time_Booking_Amount_Override__c != null) {
                        myNewAmountSalesAdd = Agentcredit.One_Time_Booking_Amount_Override__c * (Decimal.valueOf(Commision[0]) / 100);
                        myNewAmountSalesUpdate = Agentcredit.One_Time_Booking_Amount_Override__c * (Agent1bookingpercent / 100);
                    }
                    else if(Agentcredit.One_Time_Booking_Amount__c != null)
                      {
                        myNewAmountSalesAdd = Agentcredit.One_Time_Booking_Amount__c * (Decimal.valueOf(Commision[0]) / 100);
                        myNewAmountSalesUpdate = Agentcredit.One_Time_Booking_Amount__c * (Agent1bookingpercent / 100);
                    }
                   
				 
                             Agent_Credit__c aUpdate = new Agent_Credit__c();
                                aUpdate.Id = Agentcredit.id;
                                aUpdate.Agent_Credit_Split__c = Agentsplitid[0];
                                aUpdate.Agent_Credit_Sub_Type__c = SOPS_Adjustment;
            					aUpdate.OwnerId =mUser1.Id;
            					aUpdate.Agent_Email__c = mUser1.Email;
                                aUpdate.Agent_First_Name__c = mUser1.FirstName;
                                aUpdate.Agent_Last_Name__c = mUser1.LastName;
                                aUpdate.Agent_Team__c =mUser1.Team__c;
                                aUpdate.Agent_Division__c = mUser1.Division;
                                aUpdate.Agent_Role__c = mUser1.UserRole.Name;
                                aUpdate.Agent_SPID__c = mUser1.PID__c;
                                aUpdate.Agent_Manager_First_Name__c =  mUser1.Manager.FirstName;
                                aUpdate.Agent_Manager_Last_Name__c = mUser1.Manager.LastName;
                                aUpdate.Agent_Manager_Email__c = mUser1.Manager.Email;
					
                               
                           
                               
                                aUpdate.One_Time_Booking_Amount_Override__c = myNewAmountSalesUpdate;
                                Agent_Credit__c aNew1 = new Agent_Credit__c(
                                OwnerId =mUser2.Id,
                                Account__c = Agentcredit.Account__c,
                                X12M_Commission_Booking_Amount__c = Agentcredit.X12M_Commission_Booking_Amount__c,
                                X12M_Sales_Booking_Amount__c = Agentcredit.X12M_Sales_Booking_Amount__c,
                                Agent_Credit_Type__c = Agentcredit.Agent_Credit_Type__c,

                                Compensation_Date__c = Agentcredit.Compensation_Date__c,
                                Order__c = Agentcredit.Order__c,
                                Partner__c = Agentcredit.Partner__c,
                                Agent_Credit_Sub_Type__c = SOPS_Adjustment_One_time,
                                Agent_Credit_Split__c = Agentsplitid[0],
                                Agent_Email__c = mUser2.Email,
                                Agent_First_Name__c = mUser2.FirstName,
                                Agent_Last_Name__c = mUser2.LastName,
                                Agent_Team__c = mUser2.Team__c,
                                Agent_Division__c = mUser2.Division,
                                Agent_Role__c = mUser2.UserRole.Name,
                                Agent_SPID__c = mUser2.PID__c,
                                Agent_Manager_First_Name__c =  mUser2.Manager.FirstName,
                    			Agent_Manager_Last_Name__c = mUser2.Manager.LastName,
                				Agent_Manager_Email__c = mUser2.Manager.Email,
                                One_Time_Booking_Amount_Override__c = myNewAmountSalesAdd,
                                Splitted_automatically__c = true,
                                ARR_Booking_Amount_Override__c = 0                        	
                               );
            lACNew.add(aNew1);
            lACUpdate.add(aUpdate);
            
            AgentcreditsplitHandler.AgentcreditDML(lACNew,lACUpdate);
            
		}
     public static void AgentcreditDML(List < Agent_Credit__c > lACNew,List < Agent_Credit__c > lACUpdate)
     {
             if (lACNew.size() > 0) {
                         try{

                        insert lACNew;
                        System.debug('Agent Credit for Creation >>>>> ' + lACNew);
                         }
                         catch(dmlexception e)
                        {
                           // If DML failed, ends up here
                          system.debug('Error inserting Agentcredit: ' + e);
                        }
                    }
          /*if (lACUpdate.size() > 0) {
                         try{

                        //Update lACUpdate;
                        System.debug('Agent Credit for Updation >>>>> ' + lACUpdate);
                         }
                         catch(dmlexception e)
                        {
                           // If DML failed, ends up here
                          system.debug('Error Updating Agentcredit: ' + e);
                        }
                    }*/

                
         
     }

}