/*************************************************
Trigger on AgentCredit object
Before Insert: Send email notification of new Agent Credit to sales agent.
Before update: When the owner is updated on the agent credit, field 'Office Location' 
with the employee location that matches the owner of the agent credit. 
/************************************************/

trigger AgentCredit on Agent_Credit__c (before insert , before update) {

    ByPassTrigger__c bypassTrigger = ByPassTrigger__c.getInstance();
        if (bypassTrigger != null && bypassTrigger.Bypass_AgentCredit_Trigger__c == true) {
             System.debug('$$$ ByPassTrigger__c Active For Agent Credit $$$');
            return;
        }

    new Triggers()
        .bind(Triggers.Evt.beforeinsert, new AgentCreditTriggerHandler.BrandPartnerPopulationHandler())
        .bind(Triggers.Evt.beforeupdate, new AgentCreditTriggerHandler.BrandPartnerPopulationHandler())
        .manage();

	/*******************************/
	/* Global Variable Declaration */
	/*******************************/
    final String CONST_OVERLAY = 'Overlay';
    if(Trigger.isInsert){
       
        AgentCreditHelper.isBeforeInsert( trigger.new );
        Set<Id> userIds = new Set<Id>();
        Set<Id> orderIds = new Set<Id>();
        Set<Id> accountIds = new Set<Id>();
        for(Agent_Credit__c agentCreditObj : trigger.new){
            userIds.add(agentCreditObj.ownerId);
            if(agentCreditObj.Order__c != null) {
                orderIds.add(agentCreditObj.Order__c);
            }
            if(agentCreditObj.Account__c  != null) {
                accountIds.add(agentCreditObj.Account__c);
            }
        }
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
            /*if(orderObj.Account__r.Inside_Sales_Rep__c != null) {
                userIds.add(orderObj.Account__r.Inside_Sales_Rep__c);
            }*/
        }
        Map<Id, Account> accountMap = new Map<Id, Account>([
            SELECT Id, Partner_ID__c, RC_Attribution_Channel__c, type, Inside_Sales_Rep__c, Inside_Sales_Rep__r.Email,
                (SELECT Id, Tier_Name__c FROM Opportunities)
            FROM Account
            WHERE Current_Owner__c = null AND Id IN: accountIds
        ]);
        Map<Id, User> usersMap = new Map<Id, User>([SELECT Id, Email, Division  FROM User WHERE Id IN:userIds]);
        List <Messaging.SingleEmailMessage> singleEmailMessageList = new List <Messaging.SingleEmailMessage> ();
        for(Agent_Credit__c agentCreditObj : trigger.new){

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
			// New devlopement for Agentcredit notification - Salesdevteam
			
         		AgentCreditHelper.SendnotificationAgentcredit(agentCreditObj,orderObj,arrBookingAmount,oneTimeBookingAmount,compensationDate,Agentcredtsubtype,AUMRR);
    		 
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
                /*************** UPDATE AGENT CREDIT'S ACCOUNT ****************/
            if(agentCreditObj.ARR_Booking_Amount__c != null && agentCreditObj.One_Time_Booking_Amount__c != null){
               
                    try {
                        try {
                            if(orderObj != null && orderObj.Lead_Source__c!=null && orderObj.Lead_Source__c.trim().equalsIgnoreCase('Referral Program') ) { // A= Fetch Order’s Lead Source
                                if(usersMap.get(agentCreditObj.OwnerId) != null && usersMap.get(agentCreditObj.OwnerId).Division.containsIgnoreCase('Signature Accounts')) {
                                    //  if(usersMap.get(agentCreditObj.OwnerId) != null && usersMap.get(agentCreditObj.OwnerId).Division.containsIgnoreCase('Farming')) { // B= Fetch Agent Credit Owners’s Division
                                    if(accountMap.get(agentCreditObj.Account__c) != null) {  // C=Fetch Account’s Current Owner
                                        accountMap.get(agentCreditObj.Account__c).Current_Owner__c = agentCreditObj.OwnerId;  // D=Fetch Agent Credit’s Owner
                                    }
                                }
                            }
                        } catch(Exception e) {}
                            
                            /************************* ORDER MAY BE EMPTY SO PUT TRY CATCH {} ***************************************/
                        User agentUser = usersMap.get(agentCreditObj.OwnerId);
                            /*******************************COMPENSATION DATE IS VALIDATE*******************************/
                        try {
                            compensationDate = agentCreditObj.Compensation_Date__c.format();
                        } catch(System.Exception ex){
                            isExceptionOccured = true;
                            body = '<b>Wrong compensation date on agent credit</b>';
                            //targetObjectId = '00580000003d9rB';// [india team id, for development]
                            targetObjectId = UserRC.getRCSFSyncPrimaryOwnerId;
                            activity = false;
                            displayName = 'RingCentral Sales Agent Credit';
                            subject = 'Agent Credit Notification Could Not Be Produced: ';

                        }
                            /******************************* CURRENT OWNER GETS NOTIFICATION *******************************/
                         if(isExceptionOccured == false && AgentCreditHelper.isUserPresentInExclusionUsersList(agentCreditObj.Agent_Email__c)) {
                            targetObjectId = (String)agentUser.Id;
                            replyTo = (String)(agentCreditObj.Agent_Email__c);
                            activity = false;
                            displayName = 'RingCentral Sales Agent Credit';
                            subject = 'Agent Credit Notification: ARR:'
                                    // + orderObj.Order_Type__c + ', '
                                    // + orderObj.Sales_Model__c + ', '
                                    + arrBookingAmount+ ', One-Time: '
                                    + oneTimeBookingAmount;
                            body = 'Hi ' + agentCreditObj.Agent_First_Name__c
                                    + ' ' + agentCreditObj.Agent_Last_Name__c
                                    + ',<BR><BR>  Following <B>Agent Credit</B> has been assigned to you by the system. '
                                    + '<BR><BR>Enterprise Account ID: '
                                    + orderObj.Account_ID__c + '<BR><BR>Account Name: '
                                    + orderObj.Account__r.name /*+'<BR><BR>AU MRR:'
                                    + AUMRR*/+'<BR><BR>ARR Booking Amount: '
                                    + arrBookingAmount
                                    +'<BR><BR>One-Time Booking Amount: '
                                    + oneTimeBookingAmount
                                    + '<BR><BR>Agent Credit Date: '
                                    + compensationDate
                                    + '<BR><BR>Agent Credit Subtype: '
                                    + Agentcredtsubtype
                                    + '<BR><BR>Order ID: ' + orderObj.id 
                                    + '<BR><BR>Order Type: '                                     + orderObj.Order_Type__c + '<BR><BR>Sales Model: '
                                    + orderObj.Sales_Model__c + '<BR><BR> <a href=https://'+URL.getOrgDomainUrl().getHost()+'/'
                                    + orderObj.Account__c;
                                   // + '>View Account in salesforce</a><BR><BR><B>Order Type Definitions:</B><BR>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;New - Customer Account went to "Paid" status for the first time (+ Agent Credit) <BR>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Change - Customer Account was in ‘Paid’ status already and have a service change (+ or – Agent Credit) <BR>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Churn - Account went form ‘Paid’ status to ‘Suspended’ or ‘Disabled’  (- Agent Credit) <BR>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Return - Account went from ‘Suspended’ or ‘Disabled’ to ‘Paid’ (+ Agent Credit) <BR><BR><B>Sales Model Definitions:</B><BR>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Direct - Agent used Signup Link in salesforce for New Acquisition<BR>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Assisted - Agent used Signup Link outside salesforce and have an  Opportunity in salesforce (Email, Phone)<BR>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Assisted - Agent upgraded customer using Admin and have an active Opportunity in salesforce (Email, Phone)';
                            if(orderObj.Account__r.Partner_ID__c != null) {
                                if(String.isNotBlank(agentCreditObj.Agent_Credit_Type__c)
                                        && agentCreditObj.Agent_Credit_Type__c.equalsIgnoreCase(CONST_OVERLAY)
                                        && String.isNotBlank(agentCreditObj.Agent_Email__c) 
                                        && AgentCreditHelper.isUserPresentInExclusionUsersList(agentCreditObj.Agent_Email__c)) {
                                    toAddress.add(agentCreditObj.Agent_Email__c);
                                }
                                  
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
                        }
                    } catch(Exception ex) {
                        isExceptionOccured = true;
                        if(agentCreditObj.Order__c == null) {
                            body = '<b>Order not selected</b>';
                        } else {
                            body = 'An agent credit for order with ID: ' + agentCreditObj.Order__c + ' could not be created. The agents email entered on AC is: ' + agentCreditObj.Agent_Email__c;
                        }
                         targetObjectId = UserRC.getRCSFSyncPrimaryOwnerId;
                        activity = false;
                        displayName = 'RingCentral Sales Agent Credit';
                        subject = 'Agent Credit Notification Could Not Be Produced: ';
                    }
                //}
                if(isExceptionOccured == false && AgentCreditHelper.isUserPresentInExclusionUsersList(agentCreditObj.Agent_Email__c)) {
                    if(agentCreditObj.ownerId == UserRC.getRCSFSyncPrimaryOwnerId || Test.isRunningTest()) {
                        ccAddress = new List<String>();
                        toAddress = new List<String>();
                        Boolean isToBeNotifying = false;
                        if(orderObj != null && orderObj.Account__r.Partner_ID__c != null) {
                            targetObjectId = null;
                            isToBeNotifying = true;
                           
                            if(String.isNotBlank(agentCreditObj.Agent_Credit_Type__c)
                                    && agentCreditObj.Agent_Credit_Type__c.equalsIgnoreCase(CONST_OVERLAY)
                                    && String.isNotBlank(agentCreditObj.Agent_Email__c)){
                                toAddress.add(agentCreditObj.Agent_Email__c);
                            }
                              
                            Account partnerAccount = partnerAccountMap.get(orderObj.Account__r.Partner_ID__c);
                            if( partnerAccount != null && partnerAccount.Inside_Sales_Rep__c != null) {
                                String userEmail = usersMap.get(partnerAccount.Inside_Sales_Rep__c).Email;
                                if(AgentCreditHelper.isUserPresentInExclusionUsersList(userEmail)) {
                                    ccAddress.add(userEmail);        
                                }               
                            } else if(partnerAccount != null && orderObj.Account__r.Inside_Sales_Rep__c != null) {
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
                                    // + orderObj.Order_Type__c + ', '
                                    // + orderObj.Sales_Model__c + ', '
                                    + arrBookingAmount+ ', One-Time: '
                                    + oneTimeBookingAmount;
                                body = 'Hi ' + agentCreditObj.Agent_First_Name__c
                                        + ' ' + agentCreditObj.Agent_Last_Name__c
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
                                        + orderObj.Sales_Model__c + '<BR><BR> <a href=https://'+URL.getOrgDomainUrl().getHost()+'/'
                                        + orderObj.Account__c
                                            + '>View Account in salesforce</a><BR><BR><B>Order Type Definitions:</B><BR>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;New - Customer Account went to "Paid" status for the first time (+ Agent Credit) <BR>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Change - Customer Account was in ‘Paid’ status already and have a service change (+ or – Agent Credit) <BR>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Churn - Account went form ‘Paid’ status to ‘Suspended’ or ‘Disabled’  (- Agent Credit) <BR>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Return - Account went from ‘Suspended’ or ‘Disabled’ to ‘Paid’ (+ Agent Credit) <BR><BR><B>Sales Model Definitions:</B><BR>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Direct - Agent used Signup Link in salesforce for New Acquisition<BR>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Assisted - Agent used Signup Link outside salesforce and have an  Opportunity in salesforce (Email, Phone)<BR>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Assisted - Agent upgraded customer using Admin and have an active Opportunity in salesforce (Email, Phone)';
                            }
                        }
                    }
                }
                if(!(agentCreditObj.ownerId == UserRC.getRCSFSyncPrimaryOwnerId && (orderObj == null || String.isBlank(usersMap.get(orderObj.Account__r.Inside_Sales_Rep__c).Email)))
                        && (!String.isBlank(targetObjectId)
                        || (toAddress != null && toAddress.size() != 0 )
                        || (ccAddress != null && ccAddress.size() != 0)
                        || (bccAddress != null && bccAddress.size() != 0))) {
                     singleEmailMessageList.add(helper.createAgentCreditMail(null, body, targetObjectId, replyTo, activity, displayName, subject, toAddress, ccAddress, bccAddress));
                }
            }
        }
        try {
            if (singleEmailMessageList != null && singleEmailMessageList.size() != null) {
                Messaging.sendEmail(SingleEmailMessageList);
            }
        } catch (EmailException e) {

            //if (!Test.isRunningTest()) throw e;
            System.debug('Exception occured while sending an e-mail. Exception: ' + e.getMessage());
        }
        if(accountMap.values() != null && accountMap.values().size() != 0) {
            update accountMap.values();
        }
    }
  /*On Trigger UPDATE*/
    if(Trigger.isUpdate){
        AgentCreditHelper.isBeforeUpdate( trigger.New , trigger.old, trigger.newMap,  trigger.oldMap);
    }
    if(Trigger.isInsert)
    {
        AgentCreditHelper.Createsplitrecords( trigger.New);
    }
}