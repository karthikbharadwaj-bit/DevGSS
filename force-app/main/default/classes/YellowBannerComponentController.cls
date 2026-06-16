public class YellowBannerComponentController {


    public class YellowBannerDTO {
        @AuraEnabled public String leadSourceDescription;
        @AuraEnabled public String domainType;
        @AuraEnabled public String emailTitle;
        @AuraEnabled public String emailMessage;
        @AuraEnabled public Boolean isBTApproved;
        @AuraEnabled public Boolean isDoNotCall;
        @AuraEnabled public Boolean isHasOptedOutOfEmail;
        @AuraEnabled public Boolean isDoNotDirectMail;
        @AuraEnabled public Boolean isDoNotSMS;
        @AuraEnabled public Boolean isSia;
        @AuraEnabled public Boolean isFreeTrialLead;


        @AuraEnabled public Contact contact;
        @AuraEnabled public String contactParentAccount;

        @AuraEnabled public Lead lead;
    }

    @AuraEnabled(cacheable=true)
    public static YellowBannerDTO getDataForYellowBannerComponent(String recordId, String obj) {
        return obj == 'Lead' ? getDataForYellowBannerComponentForLead(recordId) : getDataForYellowBannerComponentForContact(recordId);
    }
    
    public static YellowBannerDTO getDataForYellowBannerComponentForLead(Id leadId) {
        Lead leadObj = (Lead) new LeadSelector().selectLeadById(new List<Object>{ leadId })
        .selectFields(new List<String>{'LeadSource', 'Lead_Entry_Source__c', 'MostRecentCampaign__c', 'Most_Recent_Campaign__r.Description',
         'Campaign_Product__c', 'Most_Recent_Campaign_Member_Status__c',
        'SIA_Information__c', 'Partner_Account_Name__c', 'Domain_Type__c',
        'PartnerDeal_Status__c', 'Ok_to_Email__c', 'Do_Not_Direct_Mail__c',
        'HasOptedOutOfEmail', 'Do_Not_Call__c', 'Do_Not_SMS__c', 'Country'})
        .executeQuery()[0];
        YellowBannerDTO yellowBannerData = new YellowBannerDTO();
        yellowBannerData.lead = leadObj;
        setLeadSourceDescription(leadObj.LeadSource, yellowBannerData);
        setIsBTApprovedLead(leadObj.PartnerDeal_Status__c, yellowBannerData);
        setIsFreeTrialLead(leadObj.Lead_Entry_Source__c, yellowBannerData);
        setDomainType(leadObj.Domain_Type__c, yellowBannerData);
        setDoNotsLead(leadObj, yellowBannerData);
        isSia(leadObj.LeadSource, yellowBannerData);
        setEmailString(leadObj.Ok_to_Email__c, leadObj.HasOptedOutOfEmail, leadObj.Country, yellowBannerData);
        return yellowBannerData;
    }

    public static YellowBannerDTO getDataForYellowBannerComponentForContact(Id contactId) {
        Contact conObj = (Contact) new ContactSelector().selectContactById(new List<Object>{ contactId })
        .selectFields(new List<String>{'Account.Parent_Partner_Account__c', 'MostRecentCampaign__c',
        'Most_Recent_Campaign__r.Description', 'Campaign_Product__c', 'Most_Recent_Campaign_Member_Status__c',
        'LeadSource', 'Domain_Type__c', 'Account.RC_Brand__c', 'Ok_to_Email__c', 'SIA_Information__c',
        'Do_Not_Direct_Mail__c', 'HasOptedOutOfEmail', 'Do_Not_Call__c', 'Do_Not_SMS__c','Account.BillingCountry'})
        .executeQuery()[0];
        YellowBannerDTO yellowBannerData = new YellowBannerDTO();
        yellowBannerData.contact = conObj;
        setContactParentAccount(conObj.Account.Parent_Partner_Account__c, yellowBannerData);
        setLeadSourceDescription(conObj.LeadSource, yellowBannerData);
        setIsBTApprovedContact(conObj.Account.RC_Brand__c, yellowBannerData);
        setDomainType(conObj.Domain_Type__c, yellowBannerData);
        setDoNotsContact(conObj, yellowBannerData);
        isSia(conObj.LeadSource, yellowBannerData);
        setEmailString(conObj.Ok_to_Email__c, conObj.HasOptedOutOfEmail, conObj.Account.BillingCountry, yellowBannerData);
        return yellowBannerData;
    }
    
    public static void setLeadSourceDescription(String leadSource, YellowBannerDTO YellowBannerDTO) {
        Map<String,String> mapLeadSrcToLeadsrcDescption = LeadHighlighter.getDescriptionByLeadSource();
        YellowBannerDTO.leadSourceDescription = mapLeadSrcToLeadsrcDescption.get(leadSource);
    }

    public static void setDomainType(String domainType, YellowBannerDTO YellowBannerDTO) {
        if (String.isNotBlank(domainType)) {
            DomainTypeLeadContact__C myDomainType
                            = DomainTypeLeadContact__C.getValues(domainType.toLowerCase());
            if (myDomainType != null) {
                YellowBannerDTO.domainType = Label.DomainTypeLeadContact1 + ' <' +  domainType + '>: ' + Label.DomainTypeLeadContact2;
            }
        }
    }

    public static void setEmailString(String okToEmail, Boolean HasOptedOutOfEmail, String Country, YellowBannerDTO YellowBannerDTO) {
        Map<String, String> mapEmailTitleEmailMessage = new Map<String, String>();
        mapEmailTitleEmailMessage = LeadHighlighter.setEmailString(okToEmail, HasOptedOutOfEmail, Country);
        if (mapEmailTitleEmailMessage != null && !mapEmailTitleEmailMessage.isEmpty() && okToEmail != 'No') {
            YellowBannerDTO.emailTitle = mapEmailTitleEmailMessage.get('title');
            YellowBannerDTO.emailMessage = mapEmailTitleEmailMessage.get('message');
        } else if (okToEmail == 'No') {
            YellowBannerDTO.isHasOptedOutOfEmail = true;
        }
    }

    public static void setIsBTApprovedLead(String dealStatus, YellowBannerDTO YellowBannerDTO) {
        if (String.isNotBlank(dealStatus)) {
            YellowBannerDTO.isBTApproved = 'BT Approved'.equalsIgnoreCase(dealStatus);
        }
    }

    public static void setIsFreeTrialLead(String leadEntrySource, YellowBannerDTO YellowBannerDTO) {
        if (String.isNotBlank(leadEntrySource)) {
            YellowBannerDTO.isFreeTrialLead = 'US MVP Try Now Batch'.equalsIgnoreCase(leadEntrySource) || 'CA MVP Try Now Batch'.equalsIgnoreCase(leadEntrySource);
        }
    }


    public static void setIsBTApprovedContact(String accountBrand, YellowBannerDTO YellowBannerDTO) {
        if (String.isNotBlank(accountBrand)) {
            YellowBannerDTO.isBTApproved = accountBrand.containsIgnoreCase('BT');
        }
    }

    public static void setContactParentAccount(String accountParentPartnerId, YellowBannerDTO YellowBannerDTO) {
        if (String.isNotBlank(accountParentPartnerId)) {
            Account acc = (Account) new AccountSelector().selectAccountById( accountParentPartnerId )
                    .selectFields(new List<String>{'Name'})
                    .executeQuery()[0];

            YellowBannerDTO.contactParentAccount = acc.Name;
        }
    }

    public static void setDoNotsLead(Lead leadObj, YellowBannerDTO YellowBannerDTO) {
        YellowBannerDTO.isHasOptedOutOfEmail = leadObj.HasOptedOutOfEmail;
        YellowBannerDTO.isDoNotCall = leadObj.Do_Not_Call__c;
        YellowBannerDTO.isDoNotDirectMail = leadObj.Do_Not_Direct_Mail__c;
        YellowBannerDTO.isDoNotSMS = leadObj.Do_Not_SMS__c;
    }

    public static void setDoNotsContact(Contact conObj, YellowBannerDTO YellowBannerDTO) {
        YellowBannerDTO.isHasOptedOutOfEmail = conObj.HasOptedOutOfEmail;
        YellowBannerDTO.isDoNotCall = conObj.Do_Not_Call__c;
        YellowBannerDTO.isDoNotDirectMail = conObj.Do_Not_Direct_Mail__c;
        YellowBannerDTO.isDoNotSMS = conObj.Do_Not_SMS__c;
    }

    public static void isSia(String leadSource, YellowBannerDTO YellowBannerDTO) {
        if (String.isNotBlank(leadSource) && leadSource.equalsIgnoreCase('SIA')) {
            YellowBannerDTO.isSia = true;
        }
    }

}