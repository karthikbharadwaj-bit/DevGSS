public class EmailHelper {
    public static final Pattern PATTERN_EMAIL = Pattern.compile('^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$');

    public static final String ERROR_EMAIL_UNSUPPORTED_TEMPLATE_TYPE = 'Email template {0} has unsupported type: {1}';
    public static final String ERROR_EMAIL_INACTIVE_TEMPLATE = 'Email template {0} is inactive';
    public static final String ERROR_EMAIL_NULL_TEMPLATE = 'Email template is not provided';
    public static final String ERROR_EMAIL_NULL_FROM_ADDRESS = 'From address is not provided';
    public static final String ERROR_EMAIL_NO_RECIPIENTS = 'No recipients specified';

    public static final String ERROR_ARG_EMAIL_INVALID = 'Error in argument #{0}, argument value is not a valid email: {1}';
    public static final String ERROR_ARG_VALUE_BLANK = 'Error in argument #{0}, argument value cannot be blank';
    public static final String ERROR_ARG_BODY_VAR_UNDEFINED = 'Error in argument #{0}, body variable {1} is not defined';

    public static final String EMAIL_TEMPLATE_NAME_INITIATE_PROSERV_IGNITE = 'Initiate_Proserv_Ignite';
    public static final String EMAIL_TEMPLATE_NAME_CANCEL_PROSERV_IGNITE = 'Cancel_Proserv_Ignite';
    public static final String EMAIL_ADDRESS_NO_REPLY = 'noreply@ringcentral.com';
    
    public static final String ORG_WIDE_EMAIL_ADDRESS_NAME_RC_PROSERV = 'RC ProServ';

    public virtual class EmailBuilderException extends Exception {}
    public class ArgumentException extends EmailBuilderException {
        public Integer argumentIndex {get;set;}
        public Object argumentValue {get;set;}

        public Integer getArgumentIndex() {
            return this.argumentIndex;
        }

        public Object getArgumentValue() {
            return this.argumentValue;
        }

        public ArgumentException(String message, Integer argumentIndex, Object argumentValue) {
            super(message);
            this.argumentIndex = argumentIndex;
            this.argumentValue = argumentValue;
        }
    }
    public virtual class EmailBuilderTemplateException extends EmailBuilderException {
        protected EmailTemplate template {get;set;}

        public EmailTemplate getTemplate() {
            return this.template;
        }

        public EmailBuilderTemplateException(String message, EmailTemplate template) {
            super(message);
            this.template = template;
        }
    }

    public static String Error_EmptyRecipients() {
        return ERROR_EMAIL_NO_RECIPIENTS;
    }

    public static String Error_TemplateNotProvided() {
        return ERROR_EMAIL_NULL_TEMPLATE;
    }

    public static String Error_FromAddressNotProvided() {
        return ERROR_EMAIL_NULL_FROM_ADDRESS;
    }

    public static String Error_TemplateUnsupportedType(EmailTemplate emailTemplate) {
        return String.format(ERROR_EMAIL_UNSUPPORTED_TEMPLATE_TYPE, new List<Object>{emailTemplate.DeveloperName, emailTemplate.TemplateType});
    }

    public static String Error_TemplateInactive(EmailTemplate emailTemplate) {
        return String.format(ERROR_EMAIL_INACTIVE_TEMPLATE, new List<Object>{emailTemplate.DeveloperName});
    }

    public static String Error_ArgumentEmailInvalid(Integer argumentIndex, Object paramValue) {
        return String.format(ERROR_ARG_EMAIL_INVALID, new List<Object>{ argumentIndex, String.valueOf(paramValue) });
    }

    public static String Error_ArgumentCannotBeBlank(Integer argumentIndex, Object paramValue) {
        return String.format(ERROR_ARG_VALUE_BLANK, new List<Object>{ argumentIndex, String.valueOf(paramValue) });
    }

    public static String Error_ArgumentBodyVariableUndefined(Integer argumentIndex, Object paramValue) {
        return String.format(ERROR_ARG_BODY_VAR_UNDEFINED, new List<Object>{ argumentIndex, String.valueOf(paramValue) });
    }

    public virtual class EmailBuilder {
        protected EmailTemplate template {get;set;}

        public void setTemplate(EmailTemplate template) {
            this.template = template;

            if (this.template != null) {
                if (!template.IsActive) {
                    throw new EmailBuilderTemplateException(Error_TemplateInactive(template), template);
                }

                if (template.TemplateType != 'custom') {
                    throw new EmailBuilderTemplateException(Error_TemplateUnsupportedType(template), template);
                }
            }
        }

        public EmailTemplate getTemplate() {
            return this.template;
        }

        public String getSubject() {
            if (this.getTemplate() == null) {
                return null;
            }

            return this.getTemplate().Subject;
        }

        public String getTemplateId() {
            if (this.getTemplate() == null) {
                return null;
            }

            return this.getTemplate().Id;
        }

        public String getTemplateDeveloperName() {
            if (this.getTemplate() == null) {
                return null;
            }

            return this.getTemplate().DeveloperName;
        }

        public String getTemplateName() {
            if (this.getTemplate() == null) {
                return null;
            }

            return this.getTemplate().Name;
        }

        public String getTemplateHtml() {
            if (this.getTemplate() == null) {
                return null;
            }

            return this.getTemplate().HtmlValue;
        }

        public String getTemplateText() {
            if (this.getTemplate() == null) {
                return null;
            }

            return this.getTemplate().Body;
        }

        public String getTemplateType() {
            if (this.getTemplate() == null) {
                return null;
            }

            return this.getTemplate().TemplateType;
        }

        protected OrgWideEmailAddress fromAddress {get;set;}

        public virtual void setFromAddress(OrgWideEmailAddress orgWideEmailAddress) {
            this.fromAddress = orgWideEmailAddress;
        }

        public virtual OrgWideEmailAddress getFromAddress() {
            return this.fromAddress;
        }

        protected Map<String, String> bodyVariables {get;set;}

        public virtual void setBodyVariable(String variableName, Object variableValue) {
            if (String.isBlank(variableName)) {
                throw new ArgumentException(Error_ArgumentCannotBeBlank(0, variableName), 0, variableName);
            }

            this.getBodyVariables().put(variableName, variableValue != null ? String.valueOf(variableValue) : '');
            this.setCompiledPattern(variableName);
        }

        public virtual void setBodyVariables(Map<String, Object> variables) {
            for (String key : variables.keySet()) {
                this.setBodyVariable(key, variables.get(key));
            }
        }

        public virtual String getBodyVariable(String variableName) {
            if (String.isBlank(variableName)) {
                throw new ArgumentException(Error_ArgumentCannotBeBlank(0, variableName), 0, variableName);
            }

            if (!this.getBodyVariables().containsKey(variableName)) {
                throw new ArgumentException(Error_ArgumentBodyVariableUndefined(0, variableName), 0, variableName);
            }

            return this.getBodyVariables().get(variableName);
        }

        public virtual Map<String, String> getBodyVariables() {
            return this.bodyVariables;
        }

        protected Map<String, Pattern> compiledPatterns = new Map<String, Pattern>();

        @TestVisible
        protected virtual Pattern getCompiledPattern(String variableName) {
            if (String.isBlank(variableName)) {
                throw new ArgumentException(Error_ArgumentCannotBeBlank(0, variableName), 0, variableName);
            }

            return this.getCompiledPatterns().get(variableName);
        }

        @TestVisible
        protected virtual void setCompiledPattern(String variableName) {
            if (String.isBlank(variableName)) {
                throw new ArgumentException(Error_ArgumentCannotBeBlank(0, variableName), 0, variableName);
            }

            if (this.getCompiledPatterns().containsKey(variableName)) {
                return;
            }

            this.getCompiledPatterns().put(variableName, Pattern.compile('(?i)(\\{!' + variableName + '})'));
        }

        @TestVisible
        protected virtual Map<String, Pattern> getCompiledPatterns() {
            return this.compiledPatterns;
        }

        @TestVisible
        protected virtual void setCompiledPatterns(Map<String, Pattern> compiledPatterns) {
            this.compiledPatterns = compiledPatterns;
        }

        @TestVisible
        protected virtual void setCompiledPatterns(List<String> variableNames) {
            for (String variableName : variableNames) {
                this.setCompiledPattern(variableName);
            }
        }

        protected Set<String> toAddresses {get;set;}

        public virtual Set<String> getRecipients() {
            return this.toAddresses;
        }

        public virtual void setRecipients(Set<String> recipients) {
            this.toAddresses = recipients;
        }

        public virtual void addRecipient(String recipient) {
            if (!this.isEmailStringValid(recipient)) {
                throw new ArgumentException(Error_ArgumentEmailInvalid(0, recipient), 0, recipient);
            }

            this.toAddresses.add(recipient);
        }

        public virtual void addRecipient(User recipient) {
            this.addRecipient(recipient.Email);
        }

        public virtual void addRecipients(Set<String> recipients) {
            for (String recipient : recipients) {
                this.addRecipient(recipient);
            }
        }

        public virtual void addRecipients(List<String> recipients) {
            this.addRecipients(new Set<String>(recipients));
        }

        public virtual void addRecipients(Set<User> recipients) {
            for (User recipient : recipients) {
                this.addRecipient(recipient.Email);
            }
        }

        public virtual void addRecipients(List<User> recipients) {
            this.addRecipients(new Set<User>(recipients));
        }

        protected Set<String> ccAddresses {get;set;}

        public virtual Set<String> getCCRecipients() {
            return this.ccAddresses;
        }

        public virtual void setCCRecipients(Set<String> ccRecipients) {
            this.ccAddresses = ccRecipients;
        }

        public virtual void addCCRecipient(String ccRecipient) {
            if (!this.isEmailStringValid(ccRecipient)) {
                throw new ArgumentException(Error_ArgumentEmailInvalid(0, ccRecipient), 0, ccRecipient);
            }

            this.ccAddresses.add(ccRecipient);
        }

        public virtual void addCCRecipient(User ccRecipient) {
            this.addCCRecipient(ccRecipient.Email);
        }

        public virtual void addCCRecipients(Set<String> ccRecipients) {
            for (String recipient : ccRecipients) {
                this.addCCRecipient(recipient);
            }
        }

        public virtual void addCCRecipients(List<String> ccRecipients) {
            this.addCCRecipients(new Set<String>(ccRecipients));
        }

        public virtual void addCCRecipients(Set<User> ccRecipients) {
            for (User recipient : ccRecipients) {
                this.addCCRecipient(recipient.Email);
            }
        }

        public virtual void addCCRecipients(List<User> ccRecipients) {
            this.addCCRecipients(new Set<User>(ccRecipients));
        }

        protected Set<String> bccAddresses {get;set;}

        public virtual Set<String> getBCCRecipients() {
            return this.bccAddresses;
        }

        public virtual void setBCCRecipients(Set<String> bccRecipients) {
            this.bccAddresses = bccRecipients;
        }

        public virtual void addBCCRecipient(String bccRecipient) {
            if (!this.isEmailStringValid(bccRecipient)) {
                throw new ArgumentException(Error_ArgumentEmailInvalid(0, bccRecipient), 0, bccRecipient);
            }

            this.bccAddresses.add(bccRecipient);
        }

        public virtual void addBCCRecipient(User bccRecipient) {
            this.addBCCRecipient(bccRecipient.Email);
        }

        public virtual void addBCCRecipients(Set<String> recipients) {
            for (String recipient : recipients) {
                this.addBCCRecipient(recipient);
            }
        }

        public virtual void addBCCRecipients(List<String> recipients) {
            this.addBCCRecipients(new Set<String>(recipients));
        }

        public virtual void addBCCRecipients(Set<User> recipients) {
            for (User recipient : recipients) {
                this.addBCCRecipient(recipient.Email);
            }
        }

        public virtual void addBCCRecipients(List<User> recipients) {
            this.addBCCRecipients(new Set<User>(recipients));
        }

        protected Boolean isProcessBody {get;set;}

        public void setIsProcessBody(Boolean isProcessBody) {
            this.isProcessBody = isProcessBody;
        }

        public Boolean isProcessBody() {
            return this.isProcessBody;
        }

        protected Boolean isProcessSubject {get;set;}

        public void setIsProcessSubject(Boolean isProcessSubject) {
            this.isProcessSubject = isProcessSubject;
        }

        public Boolean isProcessSubject() {
            return this.isProcessSubject;
        }

        public EmailBuilder() {
            this.toAddresses = new Set<String>();
            this.ccAddresses = new Set<String>();
            this.bccAddresses = new Set<String>();

            this.isProcessSubject = true;
            this.isProcessBody = true;

            this.bodyVariables = new Map<String, String>();
            this.compiledPatterns = new Map<String, Pattern>();
        }

        protected Boolean isEmailStringValid(String email) {
            return PATTERN_EMAIL.matcher(email).matches();
        }

        protected String replaceBodyVariables(String sourceText) {
            if (String.isBlank(sourceText)) {
                return '';
            }

            String result = sourceText;
            for (String key : this.getBodyVariables().keySet()) {
                Matcher m = this.getCompiledPattern(key).matcher(result);

                result = m.replaceAll(String.valueOf(this.getBodyVariable(key)));
            }

            return result;
        }

        protected String buildBodyHtml() {
            String html = this.getTemplateHtml();

            if (!this.isProcessBody()) {
                return html;
            }

            return this.replaceBodyVariables(html);
        }

        protected String buildBodyText() {
            String text = this.getTemplateText();

            if (!this.isProcessBody()) {
                return text;
            }

            return this.replaceBodyVariables(text);
        }

        protected String buildSubject() {
            String subject = this.getSubject();

            if (!this.isProcessSubject()) {
                return subject;
            }

            return this.replaceBodyVariables(subject);
        }

        public virtual Messaging.SingleEmailMessage buildEmail() {
            if (this.getTemplate() == null) {
                throw new EmailBuilderException(Error_TemplateNotProvided());
            }

            if (this.getFromAddress() == null) {
                throw new EmailBuilderException(Error_FromAddressNotProvided());
            }

            if (this.getRecipients().isEmpty()) {
                throw new EmailBuilderException(Error_EmptyRecipients());
            }

            Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();

            message.setOrgWideEmailAddressId(this.getFromAddress().Id);
            message.setToAddresses(new List<String>(this.getRecipients()));

            if (!this.getCCRecipients().isEmpty()) {
                List<String> ccRecipients = new List<String>(this.getCCRecipients());
                message.setCcAddresses(ccRecipients);
            }

            if (!this.getBCCRecipients().isEmpty()) {
                List<String> bccRecipients = new List<String>(this.getBCCRecipients());
                message.setBccAddresses(bccRecipients);
            }

            message.setUseSignature(false);
            message.setSaveAsActivity(false);
            message.setBccSender(false);
            message.setTemplateId(this.getTemplateId());
            message.setSubject(this.buildSubject());
            message.setPlainTextBody(this.buildBodyText());
            message.setHtmlBody(this.buildBodyHtml());

            return message;
        }
    }

    public virtual class QuoteCreationEmailBuilder extends EmailBuilder {
        protected List<Quote> quotes = new List<Quote>();
        protected Set<String> opportunityStages = new Set<String> {
            '1. Qualify',
            '2. Problem'
        };
        protected List<Opportunity> newBusinessOpportunities = new List<Opportunity>();
        private Map<Id, Opportunity> opportunitiesByAccountIds = new Map<Id, Opportunity>();

        public void setQuotes(List<Quote> quotes) {
            this.quotes = quotes;
        }

        public List<Quote> getQuotes() {
            return this.quotes;
        }

        public void setOpportunityStages(Set<String> opportunityStages) {
            this.opportunityStages = opportunityStages;
        }

        public Set<String> getOpportunityStages() {
            return this.opportunityStages;
        }

        public void setNewBusinessOpportunities(List<Opportunity> newBusinessOpportunities) {
            this.newBusinessOpportunities = newBusinessOpportunities;

            opportunitiesByAccountIds.clear();

            for (Opportunity opp: newBusinessOpportunities) {
                opportunitiesByAccountIds.put(opp.AccountId, opp);
            }
        }

        public List<Messaging.SingleEmailMessage> buildEmails() {
            List<Messaging.SingleEmailMessage> messages = new List<Messaging.SingleEmailMessage>();
            String baseUrl = Url.getOrgDomainUrl().toExternalForm();

            for (Quote qt : this.getQuotes()) {
                Opportunity opp = qt.Opportunity;
                Opportunity newBusinessOpp = opportunitiesByAccountIds.get(opp.AccountId);

                if (newBusinessOpp == null || opp.Type != OpportunityHelper.OPPORTUNITY_TYPE_NEW_BUSINESS && newBusinessOpp.StageName != OpportunityHelper.STAGE_NAME_CLOSED_WON) {
                    continue;
                }

                if (!this.opportunityStages.contains(opp.StageName)) {
                    continue;
                }

                this.addRecipient(qt.Opportunity.Owner.Email);

                if (String.isNotBlank(qt?.Opportunity?.Inside_Sales_Rep__c)) {
                    this.addCCRecipient(qt.Opportunity.Inside_Sales_Rep__r.Email);
                }

                this.setBodyVariables(new Map<String, Object> {
                    'Name' => qt.Opportunity.Owner.Name,
                    'OpportunityName' => qt.Opportunity.Name,
                    'OpportunityLink' => String.format('{0}/{1}', new List<Object>{baseUrl, qt.OpportunityId}),
                    'QuoteNumber' => qt.QuoteNumber,
                    'QuoteLink' => String.format('{0}/{1}', new List<Object>{baseUrl, qt.Id})
                });

                messages.add(this.buildEmail());
            }

            return messages;
        }
    }

    public virtual class QuoteApprovalEmailBuilder extends EmailBuilder {
        protected EmailBuilder emailBuilder = new EmailBuilder();
        {
            this.emailBuilder.setCompiledPatterns(new List<String> {
                'Name',
                'OpportunityId',
                'OpportunityName',
                'AccountId',
                'AccountName',
                'QuoteNumber',
                'JustificationAndDescription'
            });
        }

        public EmailBuilder getEmailBuilder() {
            return this.emailBuilder.clone();
        }

        public override Set<String> getRecipients() {
            return this.emailBuilder.getRecipients();
        }

        public override void setRecipients(Set<String> recipients) {
            this.emailBuilder.setRecipients(recipients);
        }

        public override void addRecipient(String recipient) {
            this.emailBuilder.addRecipient(recipient);
        }

        public override void addRecipient(User recipient) {
            this.emailBuilder.addRecipient(recipient);
        }

        public override void addRecipients(Set<String> recipients) {
            this.emailBuilder.addRecipients(recipients);
        }

        public override void addRecipients(List<String> recipients) {
            this.emailBuilder.addRecipients(recipients);
        }

        public override void addRecipients(Set<User> recipients) {
            this.emailBuilder.addRecipients(recipients);
        }

        public override void addRecipients(List<User> recipients) {
            this.emailBuilder.addRecipients(recipients);
        }

        public override Set<String> getCCRecipients() {
            return this.emailBuilder.getCCRecipients();
        }

        public override void setCCRecipients(Set<String> ccRecipients) {
            this.emailBuilder.setCCRecipients(ccRecipients);
        }

        public override void addCCRecipient(String ccRecipient) {
            this.emailBuilder.addCCRecipient(ccRecipient);
        }

        public override void addCCRecipient(User ccRecipient) {
            this.emailBuilder.addCCRecipient(ccRecipient);
        }

        public override void addCCRecipients(Set<String> ccRecipients) {
            this.emailBuilder.addCCRecipients(ccRecipients);
        }

        public override void addCCRecipients(List<String> ccRecipients) {
            this.emailBuilder.addCCRecipients(ccRecipients);
        }

        public override void addCCRecipients(Set<User> ccRecipients) {
            this.emailBuilder.addCCRecipients(ccRecipients);
        }

        public override void addCCRecipients(List<User> ccRecipients) {
            this.emailBuilder.addCCRecipients(ccRecipients);
        }

        public override Set<String> getBCCRecipients() {
            return this.emailBuilder.getBCCRecipients();
        }

        public override void setBCCRecipients(Set<String> bccRecipients) {
            this.emailBuilder.setBCCRecipients(bccRecipients);
        }

        public override void addBCCRecipient(String bccRecipient) {
            this.emailBuilder.addBCCRecipient(bccRecipient);
        }

        public override void addBCCRecipient(User bccRecipient) {
            this.emailBuilder.addBCCRecipient(bccRecipient);
        }

        public override void addBCCRecipients(Set<String> recipients) {
            this.emailBuilder.addBCCRecipients(recipients);
        }

        public override void addBCCRecipients(List<String> recipients) {
            this.emailBuilder.addBCCRecipients(recipients);
        }

        public override void addBCCRecipients(Set<User> recipients) {
            this.emailBuilder.addBCCRecipients(recipients);
        }

        public override void addBCCRecipients(List<User> recipients) {
            this.emailBuilder.addBCCRecipients(recipients);
        }

        public override void setCompiledPatterns(Map<String, Pattern> compiledPatterns) {
            this.emailBuilder.setCompiledPatterns(compiledPatterns);
        }

        public override void setCompiledPatterns(List<String> variableNames) {
            this.emailBuilder.setCompiledPatterns(variableNames);
        }

        public override void setBodyVariable(String variableName, Object variableValue) {
            this.emailBuilder.setBodyVariable(variableName, variableValue);
        }

        public override void setBodyVariables(Map<String, Object> variables) {
            this.emailBuilder.setBodyVariables(variables);
        }

        public override String getBodyVariable(String variableName) {
            return this.emailBuilder.getBodyVariable(variableName);
        }

        public override Map<String, String> getBodyVariables() {
            return this.emailBuilder.getBodyVariables();
        }

        public override Map<String, Pattern> getCompiledPatterns() {
            return this.emailBuilder.getCompiledPatterns();
        }

        public override Pattern getCompiledPattern(String variableName) {
            return this.emailBuilder.getCompiledPattern(variableName);
        }

        public override void setFromAddress(OrgWideEmailAddress orgWideEmailAddress) {
            this.emailBuilder.setFromAddress(orgWideEmailAddress);
        }

        public override OrgWideEmailAddress getFromAddress() {
            return this.emailBuilder.getFromAddress();
        }

        protected List<Quote> quotes = new List<Quote>();

        public void setQuotes(List<Quote> quotes) {
            this.quotes = quotes;
        }

        public List<Quote> getQuotes() {
            return this.quotes;
        }

        protected Map<String, EmailTemplate> templatesByStatus = new Map<String, EmailTemplate>();

        public void setApprovedTemplate(EmailTemplate approvedTemplate) {
            this.templatesByStatus.put(QuoteHelper.APPROVAL_STATUS_APPROVED, approvedTemplate);
        }

        public EmailTemplate getApprovedTemplate() {
            return this.templatesByStatus.get(QuoteHelper.APPROVAL_STATUS_APPROVED);
        }

        public void setRejectedTemplate(EmailTemplate rejectedTemplate) {
            this.templatesByStatus.put(QuoteHelper.APPROVAL_STATUS_REJECTED, rejectedTemplate);
        }

        public EmailTemplate getRejectedTemplate() {
            return this.templatesByStatus.get(QuoteHelper.APPROVAL_STATUS_REJECTED);
        }

        public EmailTemplate getTemplateByStatus(String status) {
            return this.templatesByStatus.get(status);
        }

        public Boolean hasTemplateForStatus(String status) {
            return this.templatesByStatus.containsKey(status) && this.templatesByStatus.get(status) != null;
        }

        public List<Messaging.SingleEmailMessage> buildEmails() {
            List<Messaging.SingleEmailMessage> messages = new List<Messaging.SingleEmailMessage>();

            for (Quote qt : this.getQuotes()) {
                if (!this.hasTemplateForStatus(qt.Approved_Status__c)) {
                    continue;
                }

                EmailBuilder emailBuilder = this.getEmailBuilder();
                emailBuilder.addRecipient(qt.Opportunity.Owner.Email);
                emailBuilder.setTemplate(this.getTemplateByStatus(qt.Approved_Status__c));

                if (String.isNotBlank(qt?.Opportunity?.Owner?.ManagerId)) {
                    emailBuilder.addCCRecipient(qt.Opportunity.Owner.Manager.Email);
                }

                if (String.isNotBlank(qt?.Opportunity?.Inside_Sales_Rep__c)) {
                    emailBuilder.addCCRecipient(qt.Opportunity.Inside_Sales_Rep__r.Email);
                }

                emailBuilder.setBodyVariables(new Map<String, Object> {
                    'Name' => qt.Opportunity.Owner.Name,
                    'OpportunityId' => qt.OpportunityId,
                    'OpportunityName' => qt.Opportunity.Name,
                    'AccountId' => qt.AccountId,
                    'AccountName' => qt.Account.Name,
                    'QuoteNumber' => qt.QuoteNumber,
                    'JustificationAndDescription' => qt.JustificationandDescription__c
                });

                messages.add(emailBuilder.buildEmail());
            }

            return messages;
        }
    }

    public virtual class ProServIgniteEmailBuilder extends EmailBuilder {
        protected List<Quote> quotes = new List<Quote>();
        protected String caseReasons = '';

        public void setQuotes(List<Quote> quotes) {
            this.quotes = quotes;
        }

        public List<Quote> getQuotes() {
            return this.quotes;
        }

        public void setCaseReasons(String caseReasons) {
            this.caseReasons = caseReasons;
        }

        public String getCaseReasons() {
            return String.isEmpty(this.caseReasons) ? 'A category has not been selected' : this.caseReasons;
        }

        public List<Messaging.SingleEmailMessage> buildEmails() {
            List<Messaging.SingleEmailMessage> messages = new List<Messaging.SingleEmailMessage>();
            String baseUrl = Url.getOrgDomainUrl().toExternalForm();

            for (Quote qt : this.getQuotes()) {
                Opportunity opp = qt.Opportunity;

                this.addRecipient(qt.Opportunity.Owner.Email);

                if (String.isNotBlank(qt?.Opportunity?.Inside_Sales_Rep__c)) {
                    this.addCCRecipient(qt.Opportunity.Inside_Sales_Rep__r.Email);
                }

                this.setBodyVariables(new Map<String, Object> {
                    'Name' => qt.Opportunity.Owner.Name,
                    'OpportunityName' => qt.Opportunity.Name,
                    'OpportunityLink' => String.format('{0}/{1}', new List<Object>{baseUrl, qt.OpportunityId}),
                    'QuoteNumber' => qt.QuoteNumber,
                    'QuoteLink' => String.format('{0}/{1}', new List<Object>{baseUrl, qt.Id}),
                    'AccountName' => qt.Account.Name,
                    'AccountLink' => String.format('{0}/{1}', new List<Object>{baseUrl, qt.AccountId}),
                    'CaseReasons' => this.getCaseReasons(),
                    'PartnerContactName' => qt.Account.Partner_Contact__r.Name,
                    'PartnerContactEmail' => qt.Account.Partner_Contact__r.Email
                });

                messages.add(this.buildEmail());
            }

            return messages;
        }
    }
}