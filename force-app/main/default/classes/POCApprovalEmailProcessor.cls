public class POCApprovalEmailProcessor extends PlatformEventProcessor implements PlatformEvents.POCApprovalEmailInterface {
    
    private static final String BASE_URL = URL.getOrgDomainURL().toExternalForm();
    private static final String POC_OPPORTUNITY_CESE_LEADERSHIP_TEAM_EMAIL = 'POC_RingCX_Quote_SSE_Leadership_Team_Email';
    private static final String SSE_DIRECT_LEADERSHIP_EMAIL = 'SSE_Direct_Leadership';
    
    public override void handle(List<SObject> events) {
        List<POCApprovalEmail__e> pocEvents = (List<POCApprovalEmail__e>) events;
        Set<Id> opportunityIds = new Set<Id>();
        
        Map<Id, Id> opportunityToSubmitterMap = new Map<Id, Id>();
        for (POCApprovalEmail__e event : pocEvents) {
            opportunityIds.add(event.OpportunityId__c);
            opportunityToSubmitterMap.put(event.OpportunityId__c, event.SubmitterUserId__c);
        }
        
        if (!opportunityIds.isEmpty()) {
            List<Opportunity> opportunities = (List<Opportunity>) new OpportunitySelector()
                .selectOpportunitiesByIds(opportunityIds)
                .executeQuery();
            
            if (!opportunities.isEmpty()) {
                List<Messaging.SingleEmailMessage> emailList = buildEmailList(opportunities, POC_OPPORTUNITY_CESE_LEADERSHIP_TEAM_EMAIL, opportunityToSubmitterMap);
                sendEmails(emailList);
            }
        }
    }
    
    private List<Messaging.SingleEmailMessage> buildEmailList(List<Opportunity> opportunities, String templateDeveloperName, Map<Id, Id> opportunityToSubmitterMap) {
        List<EmailTemplate> templates = (List<EmailTemplate>) new EmailTemplateSelector()
                .selectEmailTemplatesByDeveloperNames(
                    new List<String>{templateDeveloperName},
                    false
                )
                .executeQuery();
        
        if (templates.isEmpty()) {
            return new List<Messaging.SingleEmailMessage>();
        }
        
        String toEmail = Emails__c.getInstance(SSE_DIRECT_LEADERSHIP_EMAIL).Email_Address__c;
        List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
        
        for (Opportunity opportunity : opportunities) {
            Id submitterUserId = opportunityToSubmitterMap.get(opportunity.Id);
            ApprovalHelperCls.InternalEmail mail = new ApprovalHelperCls.InternalEmail(
                submitterUserId,
                templates[0].Subject, 
                templates[0].HtmlValue
            );
            
            mail.addParameter('Opportunity.Name', opportunity.Name);
            mail.addParameter('Opportunity.Link', BASE_URL + '/' + opportunity.Id);
            
            Messaging.SingleEmailMessage email = mail.getMails()[0];
            email.setToAddresses(new List<String>{toEmail});
            emailList.add(email);
        }
        return emailList;
    }
    
    private void sendEmails(List<Messaging.SingleEmailMessage> emailList) {
        if (emailList.isEmpty()) {
            return;
        }
        
        try {
            Messaging.sendEmail(emailList);
        } catch (EmailException ex) {
            Platformlog.logResult('POCApprovalEmailProcessor', ex.getMessage(), 'ErrorMessage: ' + ex.getMessage() + ' StackTrace: ' + ex.getStackTraceString(), null, null, false);
        }
    }
}