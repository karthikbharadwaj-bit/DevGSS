public class SEClosedDowngradedEmailAlerts {
    static final String OPP_CLOSEDWON_SUBJECT = 'SE Closed Won Opp Notification';
    static final String OPP_DOWNGRADED_SUBJECT = 'SE Downgraded Opp Notification';
    static final String SENDER_ADDRESS = 'noreply@ringcentral.com';
    //static final String CLOSED_WON = '7. Closed Won';
    //static final String DOWNGRADED = '0. Downgraded';

    @InvocableMethod(label='Send Email-SE Users' description='Send email to related Opportunity Team Members and their respective Managers whenver Opportunity Status is Closed/Won or Downgraded' category='Opportunity')
    public static void sendEmailBasedOnOppTeamRoles(List<String> oppIds) {
        if (oppIds.isEmpty()) { return; }

        List<String> teamRolesList = new List<String>();
        Messaging.SingleEmailMessage[] emailMessageList;
        Messaging.SendEmailResult[] emailResults;
        Map<String, OppTeamRoles__c> roleMap = OppTeamRoles__c.getAll();
        for (OppTeamRoles__c role : roleMap.values()) {
            teamRolesList.addAll(StringHelper.safeSplit(role.RoleName__c, ';'));
        }

	    List<Opportunity> oppList = (List<Opportunity>) new OpportunitySelector()
            .getOpptyFieldsForEmailNotification(new List<Object> {oppIds})
            .executeQuery();
        Map<Id, Opportunity> opportunityMap = new Map<Id, Opportunity>(oppList);

        List<OpportunityTeamMember> oppTeamMembersList = (List<OpportunityTeamMember>) new OpportunityTeamMemberSelector()
            .selectByOpportunityIdsAndRoles(new List<Object> {oppIds,teamRolesList})
            .executeQuery();
        if (!oppTeamMembersList.isEmpty()) {
            emailMessageList = getEmailMessage(oppTeamMembersList, opportunityMap);
            emailResults = Messaging.sendEmail(emailMessageList, false);
        }
    }

    public static Messaging.SingleEmailMessage[] getEmailMessage (List<OpportunityTeamMember> oppTeamMembersList,
                                                                  Map<Id, Opportunity> opportunityMap) {
       	Messaging.SingleEmailMessage[] emailMessageList = new List<Messaging.SingleEmailMessage>();
	    OrgWideEmailAddress[] emailSender = [SELECT Id FROM OrgWideEmailAddress WHERE address =: SENDER_ADDRESS LIMIT 1];
            
        for (OpportunityTeamMember oppTeamMemberRecord : oppTeamMembersList) {
            String emailHtmlBody;
            Messaging.SingleEmailMessage emailMessage = new Messaging.SingleEmailMessage();
            if (oppTeamMemberRecord.UserId != null && oppTeamMemberRecord.User.IsActive) {
                emailMessage.setTargetObjectId(oppTeamMemberRecord.UserId);
                emailMessage.setSaveAsActivity(false);
                if (oppTeamMemberRecord.User.Manager != null && oppTeamMemberRecord.User.Manager.IsActive) {
                    emailMessage.setccAddresses(new List<Id> {oppTeamMemberRecord.User.Manager.Id});
                }
            }

            Opportunity oppRecord = opportunityMap.get(oppTeamMemberRecord.opportunityId);
            String oppName = StringHelper.safeString(oppRecord.Name);
		    String todayDate = String.valueof(Date.today());
            String ownerFullName = StringHelper.safeString(oppRecord.Owner.Full_Name__c);
            String forecastCategoryName = StringHelper.safeString(oppRecord.ForecastCategoryName);
            String createdDate = StringHelper.safeString(oppRecord.CreatedDate);
            String estimatedTotalPipeline = StringHelper.safeString(oppRecord.Estimated_12M_Total_Pipeline__c);
            String oppOwnerSegment = StringHelper.safeString(oppRecord.Opportunity_Owner_s_Segment__c);
            String forecastedUsers = StringHelper.safeString(oppRecord.Forecasted_Users__c);
            String forecastedRingcentralVideoUsers = StringHelper.safeString(oppRecord.Forecasted_RingCentral_Video_Users__c);
            String forecastedContactCenterUsers = StringHelper.safeString(oppRecord.Forecast_Contact_Center_Users__c);

            if (oppRecord.stageName == OpportunityHelper.STAGE_NAME_CLOSED_WON) {
		        String tierName = StringHelper.safeString(oppRecord.Tier_Name__c);
                String totalContractValue = StringHelper.safeString(oppRecord.Total_Contract_Value__c);
                emailHtmlBody = 'Hello,' + '<br/>' + '<br/>' + 'Good News! ' + oppName + ' has finally been closed by ' + ownerFullName
                    + ' today. This ' + forecastCategoryName + ' Opportunity was created on ' + createdDate
                    + ', with an estimated annual recurring revenue of ' + estimatedTotalPipeline + ' under ' + oppOwnerSegment + ' Segment .'
                    + '<br/>' + '<br/>' + 'Additional Metrics that this closed opportunity gives us include:'
                    + '<br/>' + 'Tier Name: ' + tierName + '<br/>'
                    + 'Total Contract Value: ' + totalContractValue + '<br/>'
                    + 'Forecasted Office Users: ' + forecastedUsers + '<br/>'
                    + 'Forecasted Video Users: ' + forecastedRingcentralVideoUsers + '<br/>'
                    + 'Forecasted Contact Center Users: ' + forecastedContactCenterUsers + '<br/>'
                    + '<br/>' + 'Awesome job helping to close this deal and keep up the good work!';
                emailMessage.setSubject(OPP_CLOSEDWON_SUBJECT);
            } else if (oppRecord.stageName == OpportunityHelper.STAGE_NAME_DOWNGRADED) {
                emailHtmlBody = 'Hello,' + '<br/>'+'<br/>' + 'Unfortunately, ' + oppName
                    + ' has been downgraded as of today ' + todayDate + ' by ' + ownerFullName
                    + ', This ' + forecastCategoryName + ' Opportunity was created on ' + createdDate
                    + ' , with an estimated annual recurring pipeline of  ' + estimatedTotalPipeline + ' under ' 
                    + oppOwnerSegment + '<br/>' + '<br/>'
                    + 'Even though ' + oppName + ' wasn\'t able to be closed by ' + ownerFullName
                    + ', these are the potential Metrics this opportunity could still provide for RingCentral:' + '<br/>' + '<br/>'
                    + 'Forecasted Office Users: ' + forecastedUsers + '<br/>'
                    + 'Forecasted Video Users: ' + forecastedRingcentralVideoUsers + '<br/>'
                    + 'Forecasted Contact Center Users:' + forecastedContactCenterUsers + '<br/>'
                    + 'Don\'t give up on this opportunity just yet. We still would love to close this opportunity in the near future.';
                emailMessage.setSubject(OPP_DOWNGRADED_SUBJECT);
            }
            emailMessage.setOrgWideEmailAddressId(emailSender[0].Id);
            emailMessage.setHTMLBody(emailHtmlBody);
            emailMessageList.add(emailMessage);
        }
      return emailMessageList;
    }
}