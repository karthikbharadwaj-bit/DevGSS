/*
        Use this class for any update on Agent Credit object
        *Running on Trigger Context only
        -:Updating the Agent Credit trigger with Office Location field for monitoring current owner change.
    */
    /*
        *isBeforeupdate exceut event on trigger.isUpdate on before
        *isBeforeInsert exceut event on trigger.isinsert on before
        *@param newList list of Agent credit in context of trigger e.g. Trigger.new
        *@param oldList list of Agent credit in context of trigger e.g. Trigger.old
        *@param newMap Map of Agent Credit in context of trigger e.g. Trigger.newMap
        *@param oldMap Map of Agent Credit in context of trigger e.g. Trigger.oldMap
    */
    public class AgentCreditHelper {
                
                public static String ccAddresses = 'ccAddresses';
                public static String bccAddresses = 'bccAddresses';
                public static String toAddresses = 'toAddresses';
                public static String CurrentOwnerSalesResellers = 'Current Owner Sales & Resellers';
                public static String SalesResellers = 'RCSF Owner Sales & Resellers';
                public static String CurrentOwnerFranchiseAssoc = 'Current Owner Franchise & Assoc';
                public static String FranchiseAssoc = 'RCSF Owner Franchise & Assoc';
                public static string SOPS_Adjustment_One_time = 'SOPS Adjustment - One-time';
                public static string SOPS_Adjustment = 'SOPS Adjustment';
        
                public static void isBeforeInsert(List<Agent_Credit__c> newList){
                    //Owner id change
                     Set<Id> userIds = new Set<Id>();
                     List<String> Agentdet = new List <string>();
                     Map<Id, User> usersMap = new Map<Id, User>();
                     Map<String, User> usersEmailMap = new Map<String, User>();
                     string Agemail;
                     user Agent = new  user ();
                       for(Agent_Credit__c agentCreditObj :newList){
                           if(agentCreditObj.ownerId != null)
                           {
                             userIds.add(agentCreditObj.ownerId);   
                           }
                             
                           if(agentCreditObj.Agent_Email__c != null && agentCreditObj.Agent_Email__c !='')
                           {
                              Agemail = agentCreditObj.Agent_Email__c;
                           }
                             
                       }
                    if(userids.size() > 0 || Agemail != null)
                    {
                        for(User usr : [SELECT Id, Email, FirstName, LastName, Team__c, Division,ManagerId,Manager.FirstName, Manager.LastName, Manager.Email, UserRole.Name, PID__c
                            FROM User WHERE Id IN:userIds or Email =:Agemail])
                    {
                        usersMap.put(usr.id,usr);
                        usersEmailMap.put(usr.Email,usr);
                    }
                        
                    }
                    
                   
             
             
                    checkownerinfo(newList,usersMap,usersEmailMap,Agemail);
                    updateLocation( newList, null );// passing null here because we not need old map here
                }	
                public static void checkownerinfo(List<Agent_Credit__c> newList,Map<Id, User> usersMap,Map<String, User>usersEmailMap,String Agemail ) {
                     List<User> agent = new List<User>();
                           
                     for(Agent_Credit__c agentCreditObj :newList){
                        if(usersMap.containskey(agentCreditObj.OwnerId)) 
                        {
                            if(usersMap.get(agentCreditObj.OwnerId) != null && usersMap.get(agentCreditObj.OwnerId).Email != agentCreditObj.Agent_Email__c )
                         {
                              agentCreditObj.Agent_Email__c = usersMap.get(agentCreditObj.OwnerId).Email;
                              agentCreditObj.Agent_First_Name__c = usersMap.get(agentCreditObj.OwnerId).FirstName;
                              agentCreditObj.Agent_Last_Name__c = usersMap.get(agentCreditObj.OwnerId).LastName;
                              agentCreditObj.Agent_Team__c = usersMap.get(agentCreditObj.OwnerId).Team__c;
                              agentCreditObj.Agent_Division__c = usersMap.get(agentCreditObj.OwnerId).Division;
                              agentCreditObj.Agent_Role__c = usersMap.get(agentCreditObj.OwnerId).UserRole.Name;
                              agentCreditObj.Agent_SPID__c = usersMap.get(agentCreditObj.OwnerId).PID__c;
                              agentCreditObj.Agent_Manager_First_Name__c = usersMap.get(agentCreditObj.OwnerId).Manager.FirstName;
                              agentCreditObj.Agent_Manager_Last_Name__c = usersMap.get(agentCreditObj.OwnerId).Manager.LastName;
                              agentCreditObj.Agent_Manager_Email__c =  usersMap.get(agentCreditObj.OwnerId).Manager.Email;
                                
                         }
                         
                            
                        }
                         
                       
                     }
                }
                    
                
                public static void isBeforeUpdate(List<Agent_Credit__c> newList, List<Agent_Credit__c> oldList, Map<id,Agent_Credit__c> newMap, Map<id,Agent_Credit__c> oldMap ){
                    //Owner id change
                     Set<Id> userIds = new Set<Id>();
                     List<String> Agentdet = new List <string>();
                     string Agemail;
                      Map<Id, User> usersMap = new Map<Id, User>();
                     Map<String, User> usersEmailMap = new Map<String, User>();
                     user Agent = new  user ();
                       for(Agent_Credit__c agentCreditObj :newList){
                           if((oldMap.get(agentCreditObj.Id).ownerId != newMap.get(agentCreditObj.Id).ownerId) || (oldMap.get(agentCreditObj.Id).Agent_Email__c != newMap.get(agentCreditObj.Id).Agent_Email__c))
                           {
                                userIds.add(agentCreditObj.ownerId);
                           if(agentCreditObj.Agent_Email__c != null && agentCreditObj.Agent_Email__c !='')
                           {
                              Agemail = agentCreditObj.Agent_Email__c;
                           }
                               
                           }
                        }
                    if(userIds.size()>0)
                    {
                     for(User usr : [SELECT Id, Email, FirstName, LastName, Team__c, Division,ManagerId,Manager.FirstName, Manager.LastName, Manager.Email, UserRole.Name, PID__c
                            FROM User WHERE Id IN:userIds or Email =:Agemail])
                    {
                        usersMap.put(usr.id,usr);
                        usersEmailMap.put(usr.Email,usr);
                    }
                        
                    }
               
                   checkownerinfo(newList,usersMap,usersEmailMap,Agemail);
                   updateLocation( newList, oldMap);
                   sendNotificationEmail( newList, oldMap); //Send Email notif on update when changing owner
                    
                }
            
                 private static void updateLocation(List<Agent_Credit__c> newList, Map<id,Agent_Credit__c> oldMap ) {
                    Map< String, String > employeeLocationMap = getEmployeeLocation( newList );
                        if( oldMap != null ){
                            for(Agent_Credit__c agentCreditObjectNew : newList){
                            Agent_Credit__c agentCreditObjectold = oldMap.get( agentCreditObjectNew.id );
                                if( agentCreditObjectNew.OwnerId != agentCreditObjectold.OwnerId  ) {
                                    agentCreditObjectNew.Office_Location__c = employeeLocationMap.get( agentCreditObjectNew.OwnerId );
                                }
                            }	
                        } else if( oldMap == null ) {
                            for(Agent_Credit__c agentCreditObjectNew : newList){
                                agentCreditObjectNew.Office_Location__c = employeeLocationMap.get( agentCreditObjectNew.OwnerId );
                            }
                       }
                }
    
        public static void sendNotificationEmail(List<Agent_Credit__c> newList, Map<id,Agent_Credit__c> oldMap ){
            
          
            Set<Id> userIds = new Set<Id>();
            Set<Id> orderIds = new Set<Id>();
            Set<Id> accountIds = new Set<Id>();
            if( oldMap != null ){
                for(Agent_Credit__c agentCreditObj : newList){
                    userIds.add(agentCreditObj.ownerId);
                    if(agentCreditObj.Order__c != null){
                        orderIds.add(agentCreditObj.Order__c);
                    }
                    if(agentCreditObj.Account__c  != null){
                        accountIds.add(agentCreditObj.Account__c);
                    }
                }
                
                Map<Id, Agent_Credit__c> agentCreditMap = new Map<Id, Agent_Credit__c>([SELECT Id, Owner.Name, X12M_Sales_Booking_Amount__c,AU_MRR__c,ARR_Booking_Amount__c,One_Time_Booking_Amount__c, Account__c, Order__c, Agent_Email__c, Compensation_Date__c,
                                                                                        X12M_Commission_Booking_Amount__c,Agent_Credit_Sub_Type__c FROM Agent_Credit__c WHERE Id IN :newList ]);
                
                Map<Id, Order__c> orderMap = new Map<Id, Order__c>([SELECT Sales_Model__c,Account__c,Account_ID__c, Account__r.Partner_ID__c, Account__r.Inside_Sales_Rep__c,Account__r.RC_Attribution_Channel__c, Order__c.Account__r.RC_Account_Number__c,
                                                                    Order__c.Account__r.name, Order_Type__c,Lead_Source__c FROM ORDER__c WHERE Id IN :orderIds ]);
                
                /********************** Partner Accounts ***********************/
                Set<String> partnerIds = new Set<String>();
                for(Id orderId : orderMap.keySet()) {
                    Order__c orderObj = orderMap.get(orderId);
                    if(!String.isBlank(orderObj.Account__r.Partner_ID__c )) {
                        partnerIds.add(orderObj.Account__r.Partner_ID__c);
                    }
                }
                Map<String,Account> partnerAccountMap = new Map<String, Account>();
                for(Account partnerAccount : [SELECT Id, Partner_ID__c, OwnerId, Inside_Sales_Rep__c FROM Account WHERE Partner_ID__c IN:partnerIds AND Type='Partner']) {
                    partnerAccountMap.put(partnerAccount.Partner_ID__c, partnerAccount);
                }
                /****************************************************************/
                
                for(Id orderId: orderMap.keySet()) {
                    Order__c orderObj = orderMap.get(orderId);
                    Account partnerAccount = partnerAccountMap.get(orderObj.Account__r.Partner_ID__c );
                    if(partnerAccount != null) {
                        if(partnerAccount.Inside_Sales_Rep__c != null) {
                            userIds.add(partnerAccount.Inside_Sales_Rep__c);
                        }else if(orderObj.Account__r.Inside_Sales_Rep__c != null){
                            userIds.add(orderObj.Account__r.Inside_Sales_Rep__c);
                        }
                        userIds.add(partnerAccount.ownerId);
                    }
                }
                
                Map<Id, Account> accountMap = new Map<Id, Account>([
                    SELECT Id, Partner_ID__c, RC_Attribution_Channel__c, type, Inside_Sales_Rep__c, Inside_Sales_Rep__r.Email,
                    (SELECT Id, Tier_Name__c FROM Opportunities)
                    FROM Account
                    WHERE Current_Owner__c = null AND Id IN: accountIds
                ]);
                
                Map<Id, User> usersMap = new Map<Id, User>([SELECT Id, Email, Division, Manager.Email  FROM User WHERE Id IN:userIds]);
                
                List <Messaging.SingleEmailMessage> singleEmailMessageList = new List <Messaging.SingleEmailMessage> ();
                for(Agent_Credit__c agentCreditObj : agentCreditMap.values()){
                    Agent_Credit__c agentCreditObjectold = oldMap.get( agentCreditObj.id );
                    if( agentCreditObj.OwnerId != agentCreditObjectold.OwnerId  ) {
                         /***************************** MAIL NOTIFICATION INITIALIZATION *********************************/
                        Boolean isExceptionOccured = false;
                        Boolean isNotificationSent = false;
                        Boolean activity = false;
                        
                        String body = '';
                        String targetObjectId = '';
                        String replyTo = '';
                        String displayName = '';
                        String subject = '';
                        String compensationDate = '';
                        Decimal arrBookingAmount = agentCreditObj.ARR_Booking_Amount__c != null ? agentCreditObj.ARR_Booking_Amount__c : 0.00;
                        Decimal oneTimeBookingAmount = agentCreditObj.One_Time_Booking_Amount__c != null ? agentCreditObj.One_Time_Booking_Amount__c : 0.00;
                        Decimal AUMRR =  agentCreditObj.AU_MRR__c != null ? agentCreditObj.AU_MRR__c : 0.00;
                        String Agentcredtsubtype = agentCreditObj.Agent_Credit_Sub_Type__c;
                        List<String> bccAddress = new List<String>();
                        List<String> ccAddress = new List<String>();
                        List<String> toAddress = new List<String>();
                        
                        MailHelper helper = new MailHelper();
                        
                        Account accountObj = accountMap.get(agentCreditObj.Account__c);
                        Order__c orderObj = orderMap.get(agentCreditObj.Order__c);
                        
                        Boolean isEngage = false;
                        if (accountObj != null) {
                            for (Opportunity opty : accountObj.Opportunities) {
                                if (OpportunityHelper.isEngage(opty)) {
                                    isEngage = true;
                                    break;
                                }
                            }
                        }
                        String rcAccountNumber = '';
                        if (orderObj != null && orderObj.Account__r != null) {
                            rcAccountNumber = isEngage
                                ? 'Not applicable for Engage account'
                                : orderObj.Account__r.RC_Account_Number__c;
                        }
                        if(agentCreditObj.ARR_Booking_Amount__c != null || agentCreditObj.One_Time_Booking_Amount__c != null){
                            if(agentCreditObj.Agent_Email__c != 'rcsfsync@ringcentral.com' && AgentCreditHelper.isUserPresentInExclusionUsersList(agentCreditObj.Agent_Email__c)) {
                                try {
                                    /************************* ORDER MAY BE EMPTY SO PUT TRY CATCH {} ***************************************/
                                    
                                    User agentUser = usersMap.get(agentCreditObj.OwnerId);
                                    compensationDate = agentCreditObj.Compensation_Date__c.format();
                                    targetObjectId = (String)agentUser.Id;
                                    replyTo = (String)(agentCreditObj.Agent_Email__c);
                                    activity = false;
                                    displayName = 'RingCentral Sales Agent Credit';
                                    subject = 'Agent Credit Notification: ARR: '
                                        + arrBookingAmount+ ', One-Time: '
                                        + oneTimeBookingAmount;
                                    body = 'Hi ' + agentCreditObj.Owner.Name
                                        + ',<BR><BR>  Following <B>Agent Credit</B> has been assigned to you by the system.<BR> '
                                        + '<BR><BR>Enterprise Account ID: '
                                        + orderObj.Account_ID__c + '<BR><BR>Account Name: '
                                        + orderObj.Account__r.name +'<BR><BR>ARR Booking Amount: '
                                        + arrBookingAmount
                                        +'<BR><BR>One-Time Booking Amount: '
                                        + oneTimeBookingAmount
                                        + '<BR><BR>Agent Credit Date: '
                                        + compensationDate
                                        + '<BR><BR>Agent Credit Subtype: '
                                        + Agentcredtsubtype
                                        + '<BR><BR>Order ID: ' + orderObj.id 
                                        + '<BR><BR>Order Type: ' + orderObj.Order_Type__c + '<BR><BR>Sales Model: '
                                        
                                        + orderObj.Sales_Model__c + '<BR><BR> <a href=https://'+System.URL.getOrgDomainUrl().getHost()+'/'
                                        + orderObj.Account__c;
                                     if(orderObj.Account__r.Partner_ID__c != null) {
                                        Account partnerAccount = partnerAccountMap.get(orderObj.Account__r.Partner_ID__c);
                                        if( partnerAccount != null && partnerAccount.Inside_Sales_Rep__c != null) {
                                            String userEmail = usersMap.get(partnerAccount.Inside_Sales_Rep__c).Email;
                                            if(AgentCreditHelper.isUserPresentInExclusionUsersList(userEmail)) {
                                            	ccAddress.add(userEmail);        
                                            }
                                        }else if(partnerAccount != null && orderObj.Account__r.Inside_Sales_Rep__c != null){
                                            String userEmail = usersMap.get(orderObj.Account__r.Inside_Sales_Rep__c).Email;
                                            if(AgentCreditHelper.isUserPresentInExclusionUsersList(userEmail)) {
                                            	ccAddress.add(userEmail);        
                                            }
                                        }
                                    }
                                    String managerEmail = usersMap.get(agentCreditObj.OwnerId).Manager.Email;
                                    if(AgentCreditHelper.isUserPresentInExclusionUsersList(managerEmail)) {
                                        ccAddress.add(managerEmail);        
                                    }
                                } catch(Exception ex) {
                                    isExceptionOccured = true;
                                    if(agentCreditObj.Order__c == null) {
                                        body = '<b>Order not selected</b>';
                                    } else {
                                        body = 'An agent credit for order with ID: ' + agentCreditObj.Order__c + ' could not be updated. The agents email entered on AC is: ' + agentCreditObj.Agent_Email__c;
                                    }
                                    targetObjectId = UserRC.getRCSFSyncPrimaryOwnerId;
                                    activity = false;
                                    displayName = 'RingCentral Sales Agent Credit';
                                    subject = 'Agent Credit Notification Could Not Be Updated: ';
                                }
                            }
                            if(isExceptionOccured == false && AgentCreditHelper.isUserPresentInExclusionUsersList(agentCreditObj.Agent_Email__c)) {
                                if(agentCreditObj.ownerId == UserRC.getRCSFSyncPrimaryOwnerId) {
                                    ccAddress = new List<String>();
                                    toAddress = new List<String>();
                                    Boolean isToBeNotifying = false;
                                    if(orderObj != null && orderObj.Account__r.Partner_ID__c != null) {
                                        targetObjectId = null;
                                        isToBeNotifying = true;
                                        Account partnerAccount = partnerAccountMap.get(orderObj.Account__r.Partner_ID__c);
                                        if( partnerAccount != null && partnerAccount.Inside_Sales_Rep__c != null) {
                                            String userEmail = usersMap.get(partnerAccount.Inside_Sales_Rep__c).Email;
                                            if(AgentCreditHelper.isUserPresentInExclusionUsersList(userEmail)) {
                                            	ccAddress.add(userEmail);        
                                            }                                        
                                        } else if(partnerAccount != null && orderObj.Account__r.Inside_Sales_Rep__c != null){
                                            String userEmail = usersMap.get(orderObj.Account__r.Inside_Sales_Rep__c).Email;
                                            if(AgentCreditHelper.isUserPresentInExclusionUsersList(userEmail)) {
                                            	ccAddress.add(userEmail);        
                                            }                                        
                                        }
                                        if(isToBeNotifying) {
                                            replyTo = (String)(agentCreditObj.Agent_Email__c);
                                            activity = false;
                                            displayName = 'RingCentral Sales Agent Credit';
                                            subject = 'Agent Credit Notification: ARR: '
                                                + arrBookingAmount+ ', One-Time: '
                                                + oneTimeBookingAmount;
                                            body = 'Hi ' + agentCreditObj.Owner.Name
                                                + ',<BR><BR>  Following <B>Agent Credit</B> has been assigned to you by the system.<BR><BR>RC Primary Number: '
                                                + rcAccountNumber + '<BR><BR>Enterprise Account ID: '
                                                + orderObj.Account_ID__c + '<BR><BR>Account Name: '
                                                + orderObj.Account__r.name +'<BR><BR>ARR Booking Amount: '
                                                + arrBookingAmount
                                                +'<BR><BR>One-Time Booking Amount: '
                                                + oneTimeBookingAmount
                                                + '<BR><BR>Agent Credit Date: '
                                                + compensationDate
                                                + '<BR><BR>Order Type: ' + orderObj.Order_Type__c + '<BR><BR>Sales Model: '
                                                + orderObj.Sales_Model__c + '<BR><BR> <a href=https://'+System.URL.getOrgDomainUrl().getHost()+'/'
                                                + orderObj.Account__c
                                                + '>View Account in salesforce</a><BR><BR><B>Order Type Definitions:</B><BR>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;New - Customer Account went to "Paid" status for the first time (+ Agent Credit) <BR>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Change - Customer Account was in ‘Paid’ status already and have a service change (+ or – Agent Credit) <BR>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Churn - Account went form ‘Paid’ status to ‘Suspended’ or ‘Disabled’  (- Agent Credit) <BR>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Return - Account went from ‘Suspended’ or ‘Disabled’ to ‘Paid’ (+ Agent Credit) <BR><BR><B>Sales Model Definitions:</B><BR>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Direct - Agent used Signup Link in salesforce for New Acquisition<BR>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Assisted - Agent used Signup Link outside salesforce and have an  Opportunity in salesforce (Email, Phone)<BR>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Assisted - Agent upgraded customer using Admin and have an active Opportunity in salesforce (Email, Phone)';
                                        }
                                    }
                                }
                            }
                            if(!String.isBlank(targetObjectId)
                               || (toAddress != null && toAddress.size() != 0 )
                               || (ccAddress != null && ccAddress.size() != 0)
                               || (bccAddress != null && bccAddress.size() != 0)) {
                                   singleEmailMessageList.add(helper.createAgentCreditMail(null, body, targetObjectId, replyTo, activity, displayName, subject, toAddress, ccAddress, bccAddress));
                               }
                        }
                    }
                    
                }
                
                try {
                    
                    if (singleEmailMessageList != null && singleEmailMessageList.size() != null) {
                        Messaging.sendEmail(SingleEmailMessageList);
                    }
                } catch (EmailException e) {
                   }
            }
        }
    
            /*
                *getEmployeeLocation returns Map<UserID, Location>
                *@param agentList is Agent Credit List
            */
                private static Map<String,String> getEmployeeLocation(List<Agent_Credit__c> agentList) {
                    Map<String , String> employeeLocationMap = new Map<String , String>(); 
                    Set<Id> OwnerIDs = new Set<Id>();
                    for( Agent_Credit__c agentCredit : agentList ){
                        OwnerIDs.add( agentCredit.OwnerId );
                    }
                    for( Employee__c emp : [SELECT 	
                                                  User__c , 
                                                  Location__c, 
                                                  Email__c 
                                            FROM 
                                                  Employee__c 
                                            WHERE 
                                                  User__c IN : OwnerIDs 
                                                AND 
                                                  Is_Active__c = true ]){
                        employeeLocationMap.put( emp.User__c , emp.Location__c );
                    }
                    return 	employeeLocationMap;
                }
                
                /**
                 * This methods return list of email addresses based on User Id and Attribute Channel.
                */
                public static Map<String, List<String>> getCcBccEmailAddresses(String AgentCredit){
                    
                    Map<String, List<String>> toCcAndBccAddresses = new Map<String, List<String>>();
                    Agent_Credit_Notification_Email_Address__c agentCreditEmails = Agent_Credit_Notification_Email_Address__c.getValues(AgentCredit);
                    if(agentCreditEmails != null){
                            if(String.isNotBlank(agentCreditEmails.bccAddresses__c)){
                                    toCcAndBccAddresses.put(bccAddresses, agentCreditEmails.bccAddresses__c.split(';'));
                                }
                            if(String.isNotBlank(agentCreditEmails.ccAddresses__c)){
                                    toCcAndBccAddresses.put(ccAddresses, agentCreditEmails.ccAddresses__c.split(';'));
                                }
                            if(String.isNotBlank(agentCreditEmails.toAddresses__c)){
                                    toCcAndBccAddresses.put(toAddresses, agentCreditEmails.toAddresses__c.split(';'));
                                }
                        }
                     return toCcAndBccAddresses;
                }
        public static void SendnotificationAgentcredit(Agent_Credit__c agentCreditObj,Order__c orderObj, Decimal arrBookingAmount,Decimal oneTimeBookingAmount, String compensationDate,String Agentcredtsubtype,Decimal AUMRR ) {
            if(!AgentCreditHelper.isUserPresentInExclusionUsersList(agentCreditObj.Agent_Email__c)){
                return;
            } else {
                Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage>();
           if((agentCreditObj.AU_MRR__c != null || agentCreditObj.AU_MRR__c != 0)&& (agentCreditObj.ARR_Booking_Amount__c != null || agentCreditObj.One_Time_Booking_Amount__c != null)){
                    if(agentCreditObj.Agent_Credit_Sub_Type__c!= null && (agentCreditObj.AU_MRR__c > 0 ||(agentCreditObj.AU_MRR__c<0 && agentCreditObj.Agent_First_Name__c != 'rcsf')))
                    {
                   String[] toAddresses = new String[]{
                             
                };
           String subject = ' Automated - Agent Credit Notification: ARR:'+ arrBookingAmount+ ', One-Time: '+oneTimeBookingAmount;
                        toAddresses.add(agentCreditObj.Agent_Email__c);
          
                         String htmlBody = 'Hi ' + agentCreditObj.Agent_First_Name__c
                                        + ' ' + agentCreditObj.Agent_Last_Name__c
                                        + ',<BR><BR>  Following <B>Agent Credit</B> has been assigned to you by the system. '
                                        + '<BR><BR>Enterprise Account ID: '
                                        + orderObj.Account_ID__c + '<BR><BR>Account Name: '
                                        + orderObj.Account__r.name +'<BR><BR>ARR Booking Amount: '
                                        + arrBookingAmount
                                        +'<BR><BR>One-Time Booking Amount: '
                                        + oneTimeBookingAmount
                                        + '<BR><BR>Agent Credit Date: '
                                        + compensationDate
                                        + '<BR><BR>Agent Credit Subtype: '
                                        + Agentcredtsubtype
                                        + '<BR><BR>Order ID: ' + orderObj.id 
                                        + '<BR><BR>Order Type: ' + orderObj.Order_Type__c ;
                         Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
                         message.setUseSignature(false);
                         message.setBccSender(false);       
                         message.setWhatId(orderObj.Account__c); 
                         message.setSubject(subject);
                         message.setHTMLBody(htmlBody);
                         message.setSaveAsActivity(false);   					
                         message.setTargetObjectId(agentCreditObj.ownerid);
                         messages.add(message);	
                      }
                     }
                 if(messages.size() > 0){
                         Messaging.SendEmailResult[] results =  Messaging.sendEmail(messages);
                    
             }
        }
    }
      
         public static void Createsplitrecords(List<Agent_Credit__c> newList)
         {
              Set < id > Accountids = new Set < id > ();
              List < String > Commision = new List < String > ();
              List < id > Agentsplitid = new List < id > ();
             List < Date > Compensationdate = new List < Date > ();
              List < Id > UserIds = new List < Id > ();
          
             if(newList[0].Splitted_automatically__c == false && ((newList[0].Agent_Credit_Split__c == null)||(newList[0].Agent_Credit_Split__c == '')))
                 {
             id acid = newList[0].Account__c;
             Date Compensationdte =  newList[0].Compensation_Date__c;
             if(acid != null && Compensationdte != null )
             {
                List<Account_Split__c> asp = [Select id,Begin_Date__c,End_Date__c,Account__c,Sales_Agent__c,Sales_AE_2__c,Commission__c,Booking_for_Sales_AE_2__c from Account_Split__c where Account__c =: acid and Begin_Date__c <=:Compensationdte and End_Date__c >=:Compensationdte];
             if(asp.size() >0)
             {
                 Agentsplitid.add(asp[0].id);
                 Commision.add(String.valueOf(asp[0].Booking_for_Sales_AE_2__c));
                 UserIds.add(asp[0].Sales_Agent__c);
                 UserIds.add(asp[0].Sales_AE_2__c);
                 User  mUser1 = new User();
                 User  mUser2 = new User();
                  List<user> Userlst = [
                        SELECT Id, Email, FirstName, LastName, Team__c, Division,ManagerId,Manager.FirstName, Manager.LastName, Manager.Email, UserRole.Name, PID__c
                        FROM User
                        WHERE Id IN : UserIds
                    ];
               For(Agent_Credit__c agc:newList)
             {
                if(UserIds[0] != null && UserIds[1] != null)
                       {
                             mUser1 = Userlst[0];//AE1
               				 mUser2 = Userlst[1];//AE2
                            createAgentcredit(agc,mUser1,mUser2,Agentsplitid,Commision);
                       }
					 
             }
             }
                 
             }
             
                 }
         }
        Public static void createAgentcredit( Agent_Credit__c Agentcredit,User  mUser1,User  mUser2 ,List < id > Agentsplitid, List < String > Commision  )
            {
                  List < String > Agent2 = new list < String > ();
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

        public static Boolean isUserPresentInExclusionUsersList(string AgentEmail) {
            for (AgentCreditExlusionUsers__c AgentEmails: AgentCreditExlusionUsers__c.getAll().values()) {                   	List<String> userEmails = StringHelper.safeSplit(AgentEmails.Email__c, ',');
            	for(string userEmail: userEmails) {
                	if(AgentEmail.Contains(userEmail)) {
                    	return false;
                    }
            	}
            }
    		return true;
		}
         @Testvisible
            Private static  List<Agent_Credit__c> createArronetimerecords(Agent_Credit__c Agentcredit,User mUser1,User mUser2,List <id>Agentsplitid,List < String > Commision)
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
                                        Agent_Manager_First_Name__c =  mUser2.Manager.FirstName,
                                        Agent_Manager_Last_Name__c = mUser2.Manager.LastName,
                                        Agent_Manager_Email__c = mUser2.Manager.Email,
                                        ARR_Booking_Amount_Override__c =myNewAmountAdd,
                                        OwnerId = mUser2.id,
                                        Splitted_automatically__c = true,
                                        One_Time_Booking_Amount_Override__c = 0);
                                agcredit.add(aNewonetime);
                                    
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
                                        Agent_Manager_First_Name__c =  mUser1.Manager.FirstName,
                                        Agent_Manager_Last_Name__c = mUser1.Manager.LastName,
                                        Agent_Manager_Email__c = mUser1.Manager.Email,
                                        ARR_Booking_Amount_Override__c = 0,
                                        OwnerId = mUser1.id,
                                        Splitted_automatically__c = true,
                                        One_Time_Booking_Amount_Override__c = myNewAmountSalesUpdate);
                                agcredit.add(aeoldonetime);
                  if (agcredit.size() > 0) {
                      try
                      {
                          insert agcredit;
                         }
                        catch(dmlexception e)
                            {
                               // If DML failed, ends up here
                            }
                            
                        }
                		Agentcredit.Agent_Credit_Split__c = Agentsplitid[0];
                        Agentcredit.Agent_Credit_Sub_Type__c = SOPS_Adjustment;
                        Agentcredit.ARR_Booking_Amount_Override__c = myNewAmountUpdate;
                        Agentcredit.OwnerId =mUser1.Id;
                        
                        Agentcredit.Agent_Email__c = mUser1.Email;
                        Agentcredit.Agent_First_Name__c = mUser1.FirstName;
                        Agentcredit.Agent_Last_Name__c = mUser1.LastName;
                        Agentcredit.Agent_Team__c =mUser1.Team__c;
                        Agentcredit.Agent_Division__c = mUser1.Division;
                        Agentcredit.Agent_Role__c = mUser1.UserRole.Name;
                        Agentcredit.Agent_SPID__c = mUser1.PID__c;
                        Agentcredit.Agent_Manager_First_Name__c =  mUser1.Manager.FirstName;
                        Agentcredit.Agent_Manager_Last_Name__c = mUser1.Manager.LastName;
                        Agentcredit.Agent_Manager_Email__c = mUser1.Manager.Email;
                       
                        Agentcredit.One_Time_Booking_Amount_Override__c = 0;
                        lACUpdate.add(Agentcredit);
    		 return agcredit;
    }
}