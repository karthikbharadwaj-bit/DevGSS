/**
 * This is helper class for OpportunityTeam standard object
 * Keep all static variables and helper methods related to it here
 *
 * It's might be better to keep here helper methods that do not do any SOQL
 * so they could be reused in triggers or controllers
 */
public inherited sharing class OpportunityTeamHelper {

    // Opportunity Team Roles
    public static final String ROLE_ASSOCIATE_SALES_ENGINEER = 'Associate SE';
    public static final String ROLE_SALES_ENGINEER_PRIMARY = 'Solutions Engineer (Primary)';
    public static final String ROLE_SALES_ENGINEER_SECONDARY = 'Solutions Engineer (Secondary)';
    public static final String ROLE_SALES_ENGINEER_SPECIALIST = 'Sales Engineer Specialist';

    public static final Set<String> ENGINEER_ROLES = new Set<String>{
        ROLE_ASSOCIATE_SALES_ENGINEER,
        ROLE_SALES_ENGINEER_PRIMARY,
        ROLE_SALES_ENGINEER_SECONDARY,
        ROLE_SALES_ENGINEER_SPECIALIST
    };

    // for Opportunity Team Members notification
    private static final String NOTIFICATION_SUBJECT = 'Opportunity Team Autotag from Parent Account';

    public class NotificationParam {
        @InvocableVariable(
            label = 'Opportunity Team Members'
            description = 'Opportunity Team Members to notify'
            required = true
        )
        public List<OpportunityTeamMember> oppTeamMembers;
    }

    @InvocableMethod(
        label = 'Notify Opportunity Team Members about a new Opportunity'
        description = 'Notifies Opportunity Team Members about a newly created Opportunity. If no OpportunityTeamMember is provided, no email will be send. Notice that this action uses one SOQL query in order to compose a message.'
        category = 'Email'
    )
    public static void notifyOppTeamMembersAboutNewOpportunities(List<NotificationParam> params) {
        new OpportunityTeamMemberNotifier(params).notify();
    }

    @TestVisible
    private class OpportunityTeamMemberNotifier {
        @TestVisible
        private final String MAIN_NOTIFICATION_TEMPLATE_FOR_OPP_TEAM_MEMBER = '{0}, which you are a part of the account team, '
            + 'has had a new opportunity created by {1}: {2}. '
            + 'Please start engaging in conversations with the other team members along with the AE, BDR, Company, etc. to ensure a smooth and impactful sales process for {3}. '
            + 'Here are some notable metrics to be aware of when engaging with the customer:<br/><br/>';

        private Map<Id, OpportunityTeamMember> opportunityTeamMembersMap;
        private List<NotificationParam> params;

        public OpportunityTeamMemberNotifier(List<NotificationParam> notificationParams) {
            this.params = notificationParams;
            this.setOpportunityTeamMembersMap();
        }

        public void notify() {
            if (this.opportunityTeamMembersMap.isEmpty()) {
                return;
            }

            List<Messaging.SingleEmailMessage> emailsToSend = new List<Messaging.SingleEmailMessage>();
            for (NotificationParam param : this.params) {
                if (param.oppTeamMembers.isEmpty()) {
                    continue;
                }
                emailsToSend.addAll(createNotificationsForOpportunity(param));
            }

            EmailNotificationHelper.sendSingleEmailMessages(emailsToSend);
        }

        private List<Messaging.SingleEmailMessage> createNotificationsForOpportunity(NotificationParam param) {
            Opportunity opp = this.opportunityTeamMembersMap.get(param.oppTeamMembers[0].Id).Opportunity;
            List<OpportunityTeamMember> oppTeamMembers = param.oppTeamMembers;

            List<Messaging.SingleEmailMessage> createdEmailsForOpportunity = new List<Messaging.SingleEmailMessage>();
            for (OpportunityTeamMember oppTeamMember : oppTeamMembers) {
                OpportunityTeamMember oppTeamMemberWithUser = this.opportunityTeamMembersMap.get(oppTeamMember.Id);
                String greetings = 'Dear ' + oppTeamMemberWithUser.User.Name + ',<br/><br/>';
                createdEmailsForOpportunity.add(
                    EmailNotificationHelper.createEmailMessage(
                        oppTeamMemberWithUser.UserId,
                        NOTIFICATION_SUBJECT,
                        greetings + this.constructMainBody(opp),
                        true
                    )
                );
            }

            return createdEmailsForOpportunity;
        }

        private void setOpportunityTeamMembersMap() {
            List<OpportunityTeamMember> oppTeamMembers = new List<OpportunityTeamMember>();
            for (NotificationParam param : this.params) {
                oppTeamMembers.addAll(param.oppTeamMembers);
            }

            this.opportunityTeamMembersMap = this.getAccTeamMembersWithUserAndOpportunity(oppTeamMembers);
        }

        private Map<Id, OpportunityTeamMember> getAccTeamMembersWithUserAndOpportunity(List<OpportunityTeamMember> oppTeamMembers) {
            return new Map<Id, OpportunityTeamMember>((List<OpportunityTeamMember>) new OpportunityTeamMemberSelector()
                .newQueryFactory()
                .setFactoryName('getByIds')
                .withoutSelectorFieldsIncluded()
                .selectFields(new Set<String> {
                    'Id',
                    'UserId',
                    'User.Name',
                    'OpportunityId',
                    'Opportunity.Name',
                    'Opportunity.Owner.Name',
                    'Opportunity.Account.Name',
                    'Opportunity.Tier_Name__c',
                    'Opportunity.Total_Contract_Value__c',
                    'Opportunity.Forecasted_Users__c',
                    'Opportunity.Forecasted_RingCentral_Video_Users__c',
                    'Opportunity.Forecast_Contact_Center_Users__c'
                })
                .setCondition('Id IN :bind0')
                .setQueryBindings(new List<Object> {oppTeamMembers})
                .executeQuery()
            );
        }

        @TestVisible
        private String constructMainBody(Opportunity opp) {
            String accLink = this.constructLink(opp.AccountId, opp.Account.Name);
            return String.format(
                this.MAIN_NOTIFICATION_TEMPLATE_FOR_OPP_TEAM_MEMBER + this.constructOppDetails(opp),
                new List<Object> {
                    accLink,
                    this.constructLink(opp.OwnerId, opp.Owner.Name),
                    this.constructLink(opp.Id, opp.Name),
                    accLink,
                    opp.Tier_Name__c,
                    opp.Total_Contract_Value__c,
                    opp.Forecasted_Users__c,
                    opp.Forecasted_RingCentral_Video_Users__c,
                    opp.Forecast_Contact_Center_Users__c
                }
            );
        }

        private String constructOppDetails(Opportunity opp) {
            String oppDetails = '';

            if (String.isNotBlank(opp.Tier_Name__c)) {
                oppDetails += 'Tier Name: {4}<br/><br/>';
            }
            if (opp.Total_Contract_Value__c != null) {
                oppDetails += 'Total Contract Value: ${5}<br/><br/>';
            }
            if (opp.Forecasted_Users__c != null) {
                oppDetails += 'Forecasted Office Users: {6}<br/><br/>';
            }
            if (opp.Forecasted_RingCentral_Video_Users__c != null) {
                oppDetails += 'Forecasted Video Users: {7}<br/><br/>';
            }
            if (opp.Forecast_Contact_Center_Users__c != null) {
                oppDetails += 'Forecasted Contact Center Users: {8}';
            }

            return oppDetails;
        }

        private String constructLink(Id recordId, String displayText) {
            return String.format(
                '<a href="{0}">{1}</a>',
                new List<String> {
                    StringHelper.createObjectLink(recordId),
                    displayText
                }
            );
        }
    }
}