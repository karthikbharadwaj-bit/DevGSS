public without sharing class EmailHelperIgnite {
    public static Response proServIgnite(Id selectedQuoteId, String proServCaseReasons, String action) {
        Response response = new Response();
        Set<String> ccEmailRecipients = new Set<String>();
        Email_Configuration__c emailSetting = Email_Configuration__c.getInstance();
        if (emailSetting != null && emailSetting.CC_Emails_Ignite_Quote_Creation__c != null) {
            ccEmailRecipients.addAll(emailSetting.CC_Emails_Ignite_Quote_Creation__c.split(','));
        }
        String templateName = action == 'engageProServIgnite'
            ? EmailHelper.EMAIL_TEMPLATE_NAME_INITIATE_PROSERV_IGNITE
            : EmailHelper.EMAIL_TEMPLATE_NAME_CANCEL_PROSERV_IGNITE;
        List<EmailTemplate> templates = (List<EmailTemplate>) new EmailTemplateSelector()
            .selectEmailTemplatesByDeveloperNames(
                new List<String>{
                    templateName
                },
                true
            )
            .executeQuery();

        List<Quote> quotesToProcess = (List<Quote>) new QuoteSelector()
            .newQueryFactory()
            .setFactoryName('selectQuotesByIds')
            .selectFields(new List<String> {
                'Id',
                'QuoteNumber',
                'AccountId',
                'Account.Id',
                'Account.Name',
                'Account.Partner_Contact__r.Name',
                'Account.Partner_Contact__r.Email',
                'OpportunityId',
                'Opportunity.Id',
                'Opportunity.AccountId',
                'Opportunity.Name',
                'Opportunity.Inside_Sales_Rep__c.Email',
                'Opportunity.Owner.Name',
                'Opportunity.Owner.Email',
                'Opportunity.Owner.Manager.Name',
                'Opportunity.Owner.Manager.Email',
                'Opportunity.Name',
                'Opportunity.Type',
                'Opportunity.StageName',
                'Opportunity.PartnerProgram__c'
            })
            .withoutSelectorOrderByIncluded()
            .setCondition('Id IN :bind0')
            .setQueryBindings(new List<Object> {new Set<Id>{selectedQuoteId}})
            .executeQuery();

        List<OrgWideEmailAddress> orgWideEmailAdresses = (List<OrgWideEmailAddress>) new QueryFactory(OrgWideEmailAddress.SObjectType)
            .selectFields(new List<String>{'Id'})
            .setCondition('Address = :bind0')
            .setQueryBindings(new List<String>{ EmailHelper.EMAIL_ADDRESS_NO_REPLY })
            .executeQuery();

        EmailHelper.ProServIgniteEmailBuilder emailBuilder = new EmailHelper.ProServIgniteEmailBuilder();
        emailBuilder.setQuotes(quotesToProcess);
        emailBuilder.setTemplate(templates.get(0));
        emailBuilder.setFromAddress(orgWideEmailAdresses.get(0));
        emailBuilder.addCCRecipients(ccEmailRecipients);
        emailBuilder.setCaseReasons(proServCaseReasons);
        List<Messaging.SingleEmailMessage> messages = new List<Messaging.SingleEmailMessage>(emailBuilder.buildEmails());

        if (!messages.isEmpty()) {
            List<Messaging.SendEmailResult> result = Messaging.sendEmail(messages, false);
        }

        return response;
    }
}