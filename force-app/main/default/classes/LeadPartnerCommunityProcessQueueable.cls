public without sharing class LeadPartnerCommunityProcessQueueable implements Queueable {
    private List<Lead> leads = new List<Lead>();
    private Map<Id, Lead> oldLeads = new Map<Id, Lead>();
    private Boolean isNoReplySender;
    private Map<Id, Contact> contacts;
    private List<String> additionalEmail = new List<String>();
    private List<String> avayaAdditionalEmails = new List<String>();
    
    private static final List<String> TEMPLATE_NAMES = new List<String>{'Avaya Portal - Send Email when Opportunity Created',
                                                                        'Avaya Portal - Send Email when Lead Conversion Requested',
                                                                        'Avaya Portal - Send Email when Partner Lead Downgraded', 
                                                                        'Avaya Portal - Send Email when Partner Lead Created'};

    //Instead 'Partner Community Process For Lead' Process flow.

    public LeadPartnerCommunityProcessQueueable(List<Lead> newLeads, Map<Id, Lead> oldLeadsValues) {
        if (!newLeads.isEmpty()) {
            this.leads.addAll(newLeads);
            if (oldLeadsValues != null) {
                this.oldLeads.putAll(oldLeadsValues);
            }
        }
    }

    public void execute(QueueableContext queContext) {
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
        String userProfileName = [SELECT Name FROM Profile WHERE Id = :UserInfo.getProfileId() LIMIT 1].Name;

        Additional_Emails__c additEmails = Additional_Emails__c.getAll().values();
        additionalEmail.add(additEmails.Additional_Email__c);
        for (String avayaEmail : additEmails.AvayaAdditional_Emails__c.split(',')) {
            avayaAdditionalEmails.add(avayaEmail.trim());
        }

        Map<String, Id> emailTemplatesIds = new Map<String, Id>();
        for (EmailTemplate emTemplate : [SELECT Id, Name FROM EmailTemplate WHERE Name IN :TEMPLATE_NAMES]) {
            emailTemplatesIds.put(emTemplate.Name, emTemplate.Id);
        }

        Set<Id> contactIds = new Set<Id>();
        
        for (Lead lead : leads) {
            contactIds.add(lead.Partner_Contact__c);
        }
        contacts = new Map<Id, Contact>([SELECT Id, Email FROM Contact WHERE Id IN :contactIds]);

        for(Lead lead : leads) {
            if (String.isBlank(lead.Lead_Brand_Name__c)) {
                continue;
            }

            // ATOS
            if (lead.Lead_Brand_Name__c == 'Unify Office') {
                isNoReplySender = true;

                if (isLeadConvertRequested(lead) && userProfileName == 'Atos Partner Community - Partner Admin'
                        && emailTemplatesIds.containsKey('Avaya Portal - Send Email when Lead Conversion Requested')) {
                    mails.add(setEmailNotification(lead.Id, emailTemplatesIds.get('Avaya Portal - Send Email when Lead Conversion Requested'), new List<String>{contacts.get(lead.Partner_Contact__c).Email}, additionalEmail));
                    continue;
                }

                if (isOldLead(lead) && isLeadDowngraded(lead) && emailTemplatesIds.containsKey('Avaya Portal - Send Email when Partner Lead Downgraded')) {
                    mails.add(setEmailNotification(lead.Id, emailTemplatesIds.get('Avaya Portal - Send Email when Partner Lead Downgraded'), new List<String>{contacts.get(lead.Partner_Contact__c).Email}, additionalEmail));
                    continue;
                }

                if (isOpportunityCreated(lead) && emailTemplatesIds.containsKey('Avaya Portal - Send Email when Opportunity Created')) {
                    mails.add(setEmailNotification(lead.Id, emailTemplatesIds.get('Avaya Portal - Send Email when Opportunity Created'), new List<String>{contacts.get(lead.Partner_Contact__c).Email}, additionalEmail));
                    continue;
                }

                if (isNewLead(lead) && isLeadCreated(lead) && emailTemplatesIds.containsKey('Avaya Portal - Send Email when Partner Lead Created')) {
                    mails.add(setEmailNotification(lead.Id, emailTemplatesIds.get('Avaya Portal - Send Email when Partner Lead Created'), new List<String>{contacts.get(lead.Partner_Contact__c).Email, lead.CreatedById}, additionalEmail));
                    continue;
                }
            }

            // Internal RC
            if (lead.Lead_Brand_Name__c.contains('RingCentral')) {
                isNoReplySender = false;
                
                if (userProfileName == 'Internal RC Community - Partner Admin' && isLeadConvertRequested(lead)
                        && emailTemplatesIds.containsKey('Avaya Portal - Send Email when Lead Conversion Requested')) {
                    mails.add(setEmailNotification(lead.Id, emailTemplatesIds.get('Avaya Portal - Send Email when Lead Conversion Requested'), new List<String>{contacts.get(lead.Partner_Contact__c).Email}, additionalEmail));
                    continue;
                }

                if (isOldLead(lead) && isLeadDowngraded(lead) && emailTemplatesIds.containsKey('Avaya Portal - Send Email when Partner Lead Downgraded')) {
                    mails.add(setEmailNotification(lead.Id, emailTemplatesIds.get('Avaya Portal - Send Email when Partner Lead Downgraded'), new List<String>{contacts.get(lead.Partner_Contact__c).Email}, additionalEmail));
                    continue;
                }

                if (isOpportunityCreated(lead) && emailTemplatesIds.containsKey('Avaya Portal - Send Email when Opportunity Created')) {
                    mails.add(setEmailNotification(lead.Id, emailTemplatesIds.get('Avaya Portal - Send Email when Opportunity Created'), new List<String>{contacts.get(lead.Partner_Contact__c).Email}, additionalEmail));
                    continue;
                }

                if (isNewLead(lead) && isLeadCreated(lead) && emailTemplatesIds.containsKey('Avaya Portal - Send Email when Partner Lead Created')) {
                    mails.add(setEmailNotification(lead.Id, emailTemplatesIds.get('Avaya Portal - Send Email when Partner Lead Created'), new List<String>{contacts.get(lead.Partner_Contact__c).Email, lead.CreatedById}, additionalEmail));
                    continue;
                }
            }

            // AVAYA
            if (lead.Lead_Brand_Name__c == 'Avaya Cloud Office') {
                isNoReplySender = false;
                
                if (userProfileName == 'Partner Community - Partner Admin' && isLeadConvertRequested(lead)
                        && emailTemplatesIds.containsKey('Avaya Portal - Send Email when Lead Conversion Requested')) {
                    mails.add(setEmailNotification(lead.Id, emailTemplatesIds.get('Avaya Portal - Send Email when Lead Conversion Requested'), new List<String>{contacts.get(lead.Partner_Contact__c).Email}, avayaAdditionalEmails));
                    continue;
                }

                if (isOldLead(lead) && isLeadDowngraded(lead) && emailTemplatesIds.containsKey('Avaya Portal - Send Email when Partner Lead Downgraded')) {
                    mails.add(setEmailNotification(lead.Id, emailTemplatesIds.get('Avaya Portal - Send Email when Partner Lead Downgraded'), new List<String>{contacts.get(lead.Partner_Contact__c).Email}, avayaAdditionalEmails));
                    continue;
                }

                if (isOpportunityCreated(lead) && emailTemplatesIds.containsKey('Avaya Portal - Send Email when Opportunity Created')) {
                    mails.add(setEmailNotification(lead.Id, emailTemplatesIds.get('Avaya Portal - Send Email when Opportunity Created'), new List<String>{contacts.get(lead.Partner_Contact__c).Email}, avayaAdditionalEmails));
                    continue;
                }

                if (isNewLead(lead) && isLeadCreated(lead) && emailTemplatesIds.containsKey('Avaya Portal - Send Email when Partner Lead Created')) {
                    mails.add(setEmailNotification(lead.Id, emailTemplatesIds.get('Avaya Portal - Send Email when Partner Lead Created'), new List<String>{contacts.get(lead.Partner_Contact__c).Email, lead.CreatedById}, avayaAdditionalEmails));
                    continue;
                }
            }
        }

        if(mails.size() > 0) {
            Messaging.sendEmail(mails);
        }
    }

    private Boolean isOldLead(Lead lead) {
        return !oldLeads.isEmpty() 
                && oldLeads.keySet().contains(lead.Id);
    }

    private Boolean isNewLead(Lead lead) {
        return oldLeads.isEmpty() 
                || !oldLeads.keySet().contains(lead.Id);
    }

    private Boolean isLeadConvertRequested(Lead lead) {
        return lead.Avaya_Partnership_Lead__c
                && lead.IsAvayaConverted__c
                && !lead.IsConverted;
    }

    private Boolean isLeadDowngraded(Lead lead) {
        return lead.Avaya_Partnership_Lead__c
                && lead.Status != oldLeads.get(lead.Id).Status
                && lead.Status == '0. Downgraded'
                && !lead.IsConverted;
    }

    private Boolean isOpportunityCreated(Lead lead) {
        return lead.Avaya_Partnership_Lead__c
                && lead.IsConverted;
    }

    private Boolean isLeadCreated(Lead lead) {
        return lead.Avaya_Partnership_Lead__c
                && !lead.IsConverted;
    }

    private Messaging.SingleEmailMessage setEmailNotification(Id leadId, Id templateId, List<String> recipientEmails, List<String> additionalRecepients) {
        Messaging.SingleEmailMessage emailMessage = new Messaging.SingleEmailMessage();
        emailMessage.setSaveAsActivity(false);
        emailMessage.setTreatTargetObjectAsRecipient(false);
        emailMessage.setTemplateId(templateId);
        if (isNoReplySender) {
            emailMessage.setReplyTo('noreply@ringcentral.com');
            emailMessage.setSenderDisplayName('No Reply');
        } else {
            emailMessage.setReplyTo('partners@avayacloudoffice.com');
            emailMessage.setSenderDisplayName('partners@avayacloudoffice.com');
        }
        emailMessage.setTargetObjectId(leadId);
        emailMessage.setToAddresses(recipientEmails);
        emailMessage.setCcAddresses(additionalRecepients);
        
        return emailMessage;
    }
}