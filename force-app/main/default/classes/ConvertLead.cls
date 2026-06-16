public without sharing class ConvertLead {

    public static boolean byPassStrategicPartner = false;

    public class ConvertLeadDTOValidationException extends Exception {}

    public class ConvertLeadDTO {

        @AuraEnabled public Id leadId;
        @AuraEnabled public Id ownerId;
        @AuraEnabled public Boolean isBilling;
        @AuraEnabled public Boolean isCreateOpportunity;
        @AuraEnabled public Boolean isCreateQuote;
        @AuraEnabled public Boolean doNotCreateOpportunity;
        @AuraEnabled public String opportunityCreationOption;

        @AuraEnabled public Boolean createAccContactRole;

        @AuraEnabled public Id accountId;
        @AuraEnabled public String rcUserId;
        @AuraEnabled public Boolean isCreateAccount;
        @AuraEnabled public Boolean isElaAccount;
        @AuraEnabled public Boolean isElaLastChunk;
        @AuraEnabled public Integer numberOfELAServiceAccounts;
        @AuraEnabled public List<Id> elaServiceOpportunityIds;
        @AuraEnabled public Integer elaChunkSize;
        @AuraEnabled public Id contactId;
        @AuraEnabled public Boolean isCreateContact;
        @AuraEnabled public Id opportunityId;
        @AuraEnabled public Id leadQualificationId;
        @AuraEnabled public String contactRole;
        @AuraEnabled public Boolean isPrimaryContactRole;

        @AuraEnabled public String currencyCode;
        @AuraEnabled public String opportunityName;
        @AuraEnabled public Integer existingUsers;
        @AuraEnabled public Integer forecastedUsers;
        @AuraEnabled public Integer ccForecastedUsers;
        @AuraEnabled public Integer forecastedDigitalUsers;
        @AuraEnabled public Integer forecastedVoiceUsers;
        @AuraEnabled public Integer forecastedGlobalUsers;
        @AuraEnabled public Integer forecastedRCVideoUsers;
        @AuraEnabled public Integer forecastedEventUsers;
        @AuraEnabled public String upsellStatus;
        @AuraEnabled public Boolean isFedRampFlow;

        @AuraEnabled public Id pricebook2Id;

        @AuraEnabled public String brand;
        @AuraEnabled public String subBrand;
        @AuraEnabled public String country;
        @AuraEnabled public String edition;
        @AuraEnabled public String product;
        @AuraEnabled public String term;
        @AuraEnabled public Boolean applyError;
        @AuraEnabled public Boolean accountHasApplied;
        @AuraEnabled public Boolean contactHasApplied;
        @AuraEnabled public Boolean opportunityHasApplied;
        @AuraEnabled public Boolean opportunityContactRoleHasApplied;

        @AuraEnabled public Integer businessIdentityId;
        @AuraEnabled public String businessIdentityCurrency;
        @AuraEnabled public String closeDate;

        public ConvertLeadDTO() {}

        public ConvertLeadDTO(ConvertLeadDTO data) {
            if (data == null) {
                return;
            }
            this.leadId = data.leadId;
            this.isBilling = BooleanHelper.toBoolean(data.isBilling);
            this.isCreateOpportunity = BooleanHelper.toBoolean(data.isCreateOpportunity);
            this.isCreateAccount = BooleanHelper.toBoolean(data.isCreateAccount);
            this.isElaAccount = BooleanHelper.toBoolean(data.isElaAccount);
            this.isElaLastChunk = BooleanHelper.toBoolean(data.isElaLastChunk);
            this.numberOfELAServiceAccounts = data.numberOfELAServiceAccounts;
            this.isCreateContact = BooleanHelper.toBoolean(data.isCreateContact);
            this.doNotCreateOpportunity = BooleanHelper.toBoolean(data.doNotCreateOpportunity);
            this.opportunityCreationOption = data.opportunityCreationOption;
            this.isPrimaryContactRole = BooleanHelper.toBoolean(data.isPrimaryContactRole);
            this.createAccContactRole = BooleanHelper.toBoolean(data.createAccContactRole);
            this.rcUserId = data.rcUserId;
            this.accountId = data.accountId;
            this.contactId = data.contactId;
            this.contactRole = data.contactRole;
            this.opportunityId = data.opportunityId;
            this.leadQualificationId = data.leadQualificationId;
            this.currencyCode = data.currencyCode;
            this.opportunityName = data.opportunityName;
            this.existingUsers = data.existingUsers;
            this.forecastedUsers = data.forecastedUsers;
            this.ccForecastedUsers = data.ccForecastedUsers;
            this.forecastedDigitalUsers = data.forecastedDigitalUsers;
            this.forecastedVoiceUsers = data.forecastedVoiceUsers;
            this.forecastedGlobalUsers = data.forecastedGlobalUsers;
            this.forecastedRCVideoUsers = data.forecastedRCVideoUsers;
            this.forecastedEventUsers = data.forecastedEventUsers;
            this.upsellStatus = data.upsellStatus;
            this.pricebook2Id = data.pricebook2Id;
            this.brand = data.brand;
            this.subBrand = data.subBrand;
            this.country = data.country;
            this.edition = data.edition;
            this.product = data.product;
            this.term = data.term;
            this.isCreateQuote = BooleanHelper.toBoolean(data.isCreateQuote);
            this.applyError = BooleanHelper.toBoolean(data.applyError);
            this.opportunityHasApplied = BooleanHelper.toBoolean(data.opportunityHasApplied);
            this.accountHasApplied = BooleanHelper.toBoolean(data.accountHasApplied);
            this.contactHasApplied = BooleanHelper.toBoolean(data.contactHasApplied);
            this.opportunityContactRoleHasApplied = BooleanHelper.toBoolean(data.opportunityContactRoleHasApplied);
            this.isFedRampFlow = BooleanHelper.toBoolean(data.isFedRampFlow);
            this.businessIdentityId = data.businessIdentityId;
            this.businessIdentityCurrency = data.businessIdentityCurrency;
            this.elaServiceOpportunityIds = data.elaServiceOpportunityIds;
            this.elaChunkSize = data.elaChunkSize;
            this.closeDate = data.closeDate;
        }

        public Boolean validate() {

            if (this.leadId == null) {
                throw new ConvertLeadDTOValidationException('leadId:Id is required parameter and cannot be null');
            }

            if (this.applyError != null && this.applyError) {

                String exceptionApplyErrorMessage = 'Please press \'Apply\' button in the following sections:';

                if (!this.accountHasApplied) {
                    exceptionApplyErrorMessage = exceptionApplyErrorMessage + '\n' + 'Account,';
                } else {
                if (!this.opportunityHasApplied) {
                    exceptionApplyErrorMessage = exceptionApplyErrorMessage + '\n Opportunity,';
                }
                if (!this.contactHasApplied) {
                    exceptionApplyErrorMessage = exceptionApplyErrorMessage + '\n Contact,';
                }
                if (!this.opportunityContactRoleHasApplied) {
                    exceptionApplyErrorMessage = exceptionApplyErrorMessage + '\n Opportunity Role,';
                }
            }
                exceptionApplyErrorMessage = exceptionApplyErrorMessage.removeEnd(',');
                throw new ConvertLeadDTOValidationException(exceptionApplyErrorMessage);
            }

            if (this.doNotCreateOpportunity != null && !this.doNotCreateOpportunity
                && (this.opportunityId == null && !this.isCreateOpportunity)) {
                throw new ConvertLeadDTOValidationException('Opportunity is Required');
            }

            if (this.isCreateOpportunity || (!this.doNotCreateOpportunity && this.opportunityId == null)) {

                if (String.isBlank(this.opportunityName) || this.forecastedUsers == null) {
                    final String exceptionMessage = 'required parameters(opportunityName:String, forecastedUsers:Integer) are null or empty';
                    throw new ConvertLeadDTOValidationException(exceptionMessage);
                }

                if (this.isBilling != null && this.isBilling && this.brand == null) {
                    throw new ConvertLeadDTOValidationException('brand:String is required parameter and cannot be null');
                }

                if (this.isCreateQuote != null && this.isCreateQuote) {
                    Boolean isErrorsInRequiredParamsData = String.isBlank(this.upsellStatus)
                        || this.ccForecastedUsers == null;

                    if (isErrorsInRequiredParamsData) {
                        final String exceptionMessage = 'required parameters(upsellStatus:String, ccForecastedUsers: Integer) are null or empty';
                        throw new ConvertLeadDTOValidationException(exceptionMessage);
                    }

                    if (this.isBilling != null && !this.isBilling && this.pricebook2Id == null) {
                        throw new ConvertLeadDTOValidationException('pricebook2Id:Id is required parameter and cannot be null');
                    }
                }

            }

            return true;
        }
    }

    public class ConvertLeadOwnerData {
        @AuraEnabled public Id ownerId;
        @AuraEnabled public String email;
        @AuraEnabled public String firstName;
        @AuraEnabled public String lastName;
        @AuraEnabled public String phone;

        public ConvertLeadOwnerData() {}

        public ConvertLeadOwnerData(Lead lead) {
            if (String.isBlank(lead.Id) || String.isBlank(lead.OwnerId)) {
                return;
            }

            this.ownerId = lead.OwnerId;
            this.email = lead.Owner.Email;

            if (lead.Owner instanceOf User) {
                this.firstName = lead.Owner.FirstName;
                this.lastName = lead.Owner.LastName;
                this.phone = lead.Owner.Phone;
            }
        }
    }

    public static final String ACCOUNTID_RESPONSE_IDENTIFIER = 'AccountId';
    public static final String CONTACTID_RESPONSE_IDENTIFIER = 'ContactId';
    public static final String OPPORTUNITYID_RESPONSE_IDENTIFIER = 'OpportunityId';
    public static final String QUOTEID_RESPONSE_IDENTIFIER = 'QuoteId';
    public static final String CONVERTDATA_RESPONSE_IDENTIFIER = 'ConvertData';
    public static Boolean IS_LEAD_CONVERT_PROCESSING = false;

    public static String convertPartNode;
    public static Id accountPrimaryContactId;
    public static Boolean isLeadBeingConverted = false;

    public static Response prepareLeadRecord(ConvertLeadDTO convertLeadData) {

        if(convertLeadData == null || convertLeadData.leadId == null) {
            return null;
        }

        List<Lead> leadList = (List<Lead>) new LeadSelector()
            .selectLeadForConvert(new List<Object>{ convertLeadData.leadId })
            .executeQuery();

        Lead leadToConvert = leadList.get(0);

        leadToConvert = populateFieldsRequiredForConvert(leadToConvert, convertLeadData);

        if (convertLeadData.accountId == null && leadToConvert.Account__c != null) {
            convertLeadData.accountId = leadToConvert.Account__c;
        }

        Response result = fillNextPartResponse(
            convertLeadData.accountId,
            null,
            null,
            convertLeadData
        );
                
        if(IS_LEAD_CONVERT_PROCESSING && SettingsHelper.FEATURE_TOGGLE.EnableLeadConversionUsingCache__c){
            storeProfileRecordInPlatformCache(UserInfo.getProfileId());
            storeUserRecordInPlatformCache(UserInfo.getUserId());
            if(convertLeadData.ownerId != null && convertLeadData.ownerId != UserInfo.getUserId()){
                storeUserRecordInPlatformCache(convertLeadData.ownerId);
            }
        }

        System.debug('prepareLeadRecord; Limits.getQueries() >>> ' + Limits.getQueries());
        return result;
    }

    public static Response convertPart1(ConvertLeadDTO convertLeadData) {

        isLeadBeingConverted = true;
        if(convertLeadData == null || convertLeadData.leadId == null) {
            return null;
        }

        System.SavePoint sp = Database.setSavepoint();

        Response result = new Response();

        try {

            convertLeadData.validate();

            fillUsersCacheWithCurrentUser();

            IS_LEAD_CONVERT_PROCESSING = true;
            LeadSelector leadSelector = new LeadSelector();
            List<Object> bindings = new List<Object>();
            bindings.add(convertLeadData.leadId);

            List<Lead> leadList = (List<Lead>) leadSelector.selectLeadForConvert(bindings).executeQuery();
            Lead leadToConvert = leadList.get(0);

            LeadStatusSelector leadStatusSelector = new LeadStatusSelector();
            List<LeadStatus> leadStatusList = leadStatusSelector.selectLeadStatusForConvert().executeQuery();
            LeadStatus convertStatus = leadStatusList.get(0);
            String opportunityId;

            Database.LeadConvertResult convertResult = null;

            if (leadToConvert.RecordTypeId == LeadHelper.RT_ID_SALES_LEADS) {
                ConvertSalesLead salesLeadConverter = new ConvertSalesLead();
                convertResult = salesLeadConverter.convert(convertLeadData, convertStatus, leadToConvert);

            } else if (leadToConvert.RecordTypeId == LeadHelper.RT_ID_PARTNER_LEADS) {

                ConvertPartnerLead partnerLeadConverter = new ConvertPartnerLead();

                convertResult = partnerLeadConverter.convert(convertLeadData, convertStatus, leadToConvert);
            }


            if (convertResult != null) {
                opportunityId = convertResult.getOpportunityId();
                result = fillNextPartResponse(
                    convertResult.getAccountId(),
                    convertResult.getContactId(),
                    convertResult.getOpportunityId(),
                    convertLeadData
                );
            } else {
                Lead lead = (Lead) ConvertLeadController.getLead(convertLeadData.leadId).data.get('lead');
                if (lead.IsConverted) {
                    opportunityId = lead.ConvertedOpportunityId;
                    result = fillNextPartResponse(
                        lead.ConvertedAccountId,
                        lead.ConvertedContactId,
                        lead.ConvertedOpportunityId,
                        convertLeadData
                    );
                }
                result.error();
            }
            if (String.isNotBlank(opportunityId)) {
                if (convertLeadData.businessIdentityId != null && convertLeadData.businessIdentityCurrency != null) {
                    Opportunity oppRecord = new Opportunity();
                    oppRecord.Id = opportunityId;
                    oppRecord.BusinessIdentity__c = OpportunityHelper.businessIdentitySerialize(convertLeadData.businessIdentityId, convertLeadData.businessIdentityCurrency);
                    Triggers.switchOff();
                    update oppRecord;
                    Triggers.switchOn();
                }
            }

        } catch(Exception ex) {
            Database.rollback(sp);

            result.error(ex);
        }

        return result;
    }

    public static Response convertPart2(ConvertLeadDTO convertLeadData) {

        if(convertLeadData == null || convertLeadData.leadId == null) {
            return null;
        }
        isLeadBeingConverted = true;

        fillUsersCacheWithCurrentUser();

        Lead convertedLead = selectConvertedLead(convertLeadData.leadId);

        if (convertLeadData.currencyCode != null) {
            convertedLead.CurrencyIsoCode = convertLeadData.currencyCode;
        }

        // Used old select style until it's possible to use TYPEOF WHEN THEN construction in selector classes
        ConvertLeadOwnerData owner = new ConvertLeadOwnerData([
            SELECT
                OwnerId,
                TYPEOF Owner
                    WHEN User
                    THEN Email, Phone, FirstName, LastName
                    WHEN Group
                    THEN Email
                END
            FROM Lead
            WHERE Id =:convertLeadData.leadId
        ]);

        if (convertedLead.RecordTypeId == LeadHelper.RT_ID_SALES_LEADS) {

            Id convertedOppId = convertLeadData.opportunityId != null ? convertLeadData.opportunityId : null;
            OpportunityContactRole oppHasPrimaryContactRole;
            if (convertLeadData.opportunityId != null) {
                oppHasPrimaryContactRole = oppHasValidPrimaryContactRole(convertLeadData.opportunityId);
            }
            convertPartNode = 'Account';
            if (!convertLeadData.isCreateAccount){
                manageContactRoleCreation(convertLeadData.opportunityCreationOption, convertLeadData.contactRole,
                                      convertLeadData.accountId, convertedOppId, convertLeadData.contactId,

                                      oppHasPrimaryContactRole,convertLeadData.isCreateOpportunity);
            } else {
                updateOpportunityContactRoleForSalesLeads(convertedOppId, convertLeadData.contactId, convertLeadData.contactRole, true);
                updateAccountContactRole(convertLeadData.accountId, convertLeadData.contactId, convertLeadData.contactRole, true);
            }
            Account accnt = new Account(
                Id = convertLeadData.accountId,
                RunContactMostFrequentEmail__c = true
            );
            AccountTriggerHandler.isSalesLeadConversion = true;
            Opportunity opp = new Opportunity(Id = convertedOppId);
            Contact con = new Contact(Id = convertLeadData.contactId);
            accnt = copyLeadToAccountFields(accnt, convertedLead, owner, ConvertLeadData.forecastedUsers);
            accnt = mapSalesLeadsFieldsToRelatedAccount(convertedLead, accnt, con);
            con = mapSalesLeadsFieldsToRelatedContact(convertedLead, con, convertedOppId);

            if(convertedLead.Most_Recent_MQL_Date__c != null && (convertLeadData.isCreateAccount || (!convertLeadData.isCreateAccount && con.Most_Recent_MQL_Date__c != null && convertedLead.Most_Recent_MQL_Date__c > con.Most_Recent_MQL_Date__c)) ){
                con.Most_Recent_MQL_Date__c = convertedLead.Most_Recent_MQL_Date__c;
            }

            if(convertLeadData.opportunityId != null || convertLeadData.opportunityId != null) {
                convertPartNode = 'Opportunity';
                opp = mapSalesLeadsFieldsToRelatedOpportunity(convertedLead, opp, con);

                if (convertLeadData.businessIdentityId != null && convertLeadData.businessIdentityCurrency != null) {
                    // Store business identity
                    opp.BusinessIdentity__c = OpportunityHelper.businessIdentitySerialize(convertLeadData.businessIdentityId, convertLeadData.businessIdentityCurrency);
                }

                update opp;
            }
            system.debug('##### convert lead con ' + con);
            convertPartNode = 'Account';
            update accnt;
            update con;

            if (convertLeadData.doNotCreateOpportunity) {
                Response result = fillNextPartResponse(
                    convertLeadData.accountId,
                    convertLeadData.contactId,
                    null,
                    convertLeadData
                );
                return result;
            } else {
                convertPartNode = 'Opportunity';
                Opportunity createdOpp = prepareOpportunityRecord(convertedOppId, convertLeadData, convertedLead.Lead_Tier_Name__c,accountPrimaryContactId);

                createdOpp.RecordTypeId = OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY;
                createdOpp.CampaignId = convertedLead.Most_Recent_Campaign__c;

                List<AccountTeamMember> atmList = accountTeamMemberAssignment(convertedOppId);
                if(!atmList.isEmpty()){
                    insert atmList;
                    byPassStrategicPartner = true;
                    createdOpp.Strategic_Partner_RC_Owner__c = createdOpp.OwnerId;
                }
                update createdOpp;
                List<Note> noteList = processNotes(convertedOppId, convertLeadData, convertedLead);
                if (!noteList.isEmpty()) {
                    insert noteList;
                }

                Boolean isIndiaOffice = OpportunityHelper.isIndia(createdOpp);

                if (isIndiaOffice && convertLeadData.isCreateAccount) {
                    Approval__c newKYCApproval = new Approval__c(
                        RecordTypeId = ApprovalHelper.RT_ID_KYC_APPROVAL_REQUEST,
                        Account__c = opp.AccountId,
                        Status__c = ApprovalHelper.STATUS_REQUIRED,
                        NationalityOfAuthorisedSignatory__c = ApprovalHelper.NATIONALITY_OF_AUTHORISED_SIGNATORY_INDIA
                    );
                    insert newKYCApproval;
                } else if (isIndiaOffice && !convertLeadData.isCreateAccount) {
                    OpportunityHelper.createKYCApprovalsForIndiaOffice(new List<Opportunity> {createdOpp});
                }
            }

        } else if (convertedLead.RecordTypeId == LeadHelper.RT_ID_PARTNER_LEADS) {

            ConvertPartnerLead partnerLeadConverter = new ConvertPartnerLead();

            convertPartNode = 'Account';
            Account accnt = partnerLeadConverter.populateAccountFieldsFromPartnerLead(
                convertLeadData.accountId,
                convertedLead,
                convertLeadData.currencyCode
            );
            accnt = copyLeadToAccountFields(accnt, convertedLead, owner, convertLeadData.forecastedUsers);
            accnt.RunContactMostFrequentEmail__c = true;
            update accnt;

            System.debug('convertPart2(1); Limits.getQueries() >>> ' + Limits.getQueries());

            if (convertedLead.Partner_Lead_Owner__c != null) {
                partnerLeadConverter.shareAccountToPartner(convertedLead.Partner_Lead_Owner__c, accnt.Id);
            }

            System.debug('convertPart2(2); Limits.getQueries() >>> ' + Limits.getQueries());

            Contact contactFromLead = partnerLeadConverter.populateContactFieldsFromPartnerLead(
                convertLeadData.contactId,
                convertedLead,
                convertLeadData.currencyCode
            );

            if(convertedLead.Most_Recent_MQL_Date__c != null && (convertLeadData.isCreateAccount || (!convertLeadData.isCreateAccount && contactFromLead.Most_Recent_MQL_Date__c != null && convertedLead.Most_Recent_MQL_Date__c > contactFromLead.Most_Recent_MQL_Date__c)) ){
                contactFromLead.Most_Recent_MQL_Date__c = convertedLead.Most_Recent_MQL_Date__c;
            }
            update contactFromLead;

            if (convertLeadData.isCreateOpportunity) {
                convertPartNode = 'Opportunity';

                updateOpportunityContactRole(convertLeadData.opportunityId, contactFromLead.Id);

                if (convertLeadData.leadQualificationId != null) {

                    List<Lead_Qualification__c> leadQualificationList = (List<Lead_Qualification__c>) new LeadQualificationSelector()
                        .selectLeadQualificationsForBackendConvert(new List<Object>{convertLeadData.leadQualificationId})
                        .executeQuery();

                    if (!leadQualificationList.isEmpty()) {
                        Lead_Qualification__c leadQualificationObj = leadQualificationList.get(0);

                        partnerLeadConverter.mapOpportunityContactRole(
                            convertLeadData.accountId,
                            convertLeadData.contactId,
                            convertLeadData.opportunityId,
                            leadQualificationObj
                        );
                    }
                }

                AccountContactRole primaryAcr = accountHasPrimaryContactRole(convertLeadData.accountId);
                accountPrimaryContactId = primaryAcr?.ContactId;

                Opportunity createdOpp = prepareOpportunityRecord(
                    convertLeadData.opportunityId,
                    convertLeadData,
                    convertedLead.Lead_Tier_Name__c,
                    accountPrimaryContactId
                );

                createdOpp = partnerLeadConverter.populateOpportunityFieldsFromPartnerLead(
                        createdOpp,
                        convertedLead,
                        QuoteHelper.isExistingBusiness(convertLeadData.upsellStatus)
                                ? OpportunityHelper.OPPORTUNITY_TYPE_EX_BUSINESS
                                : OpportunityHelper.OPPORTUNITY_TYPE_NEW_BUSINESS
                        );

                createdOpp.CampaignId = convertedLead.Most_Recent_Campaign__c;

                List<AccountTeamMember> atmList = accountTeamMemberAssignment(convertLeadData.opportunityId);
                if(!atmList.isEmpty()){
                    insert atmList;
                    byPassStrategicPartner = true;
                    createdOpp.Strategic_Partner_RC_Owner__c = createdOpp.OwnerId;
                }
                update createdOpp;

                Boolean isAmazon = OpportunityHelper.isAmazon(createdOpp);

                if (isAmazon && OpportunityHelper.isNewBusiness(createdOpp)) {
                    Approval__c newSalesTaxExemptionApproval = new Approval__c();
                    TaxExemptionHelper.populateFieldsForSalesTaxExemptionApprovals(newSalesTaxExemptionApproval, createdOpp, null);
                    TaxExemptionHelper.isAutomaticApprovalMap.put(createdOpp.Id, true);
                    insert newSalesTaxExemptionApproval;
                }

                List<Note> noteList = processNotes(convertLeadData.opportunityId, convertLeadData, convertedLead);
                if (!noteList.isEmpty()) {
                    insert noteList;
                }
            }
        }

        Response result = fillNextPartResponse(
            convertLeadData.accountId,
            convertLeadData.contactId,
            convertLeadData.opportunityId,
            convertLeadData
        );

        System.debug('convertPart2(3); Limits.getQueries() >>> ' + Limits.getQueries());
        return result;
    }

    public static Response convertPart3(ConvertLeadDTO convertLeadData) {

        Response result = new Response();

        if (convertLeadData == null) {
            return result;
        }

        convertLeadData.validate();

        result = fillNextPartResponse(
            convertLeadData.accountId,
            convertLeadData.contactId,
            convertLeadData.opportunityId,
            convertLeadData
        );

        if (!convertLeadData.isCreateOpportunity || !convertLeadData.isCreateQuote) {
            PlatformCacheUtility.removeKeys(PlatformCacheUtility.SESSION_CACHE,PlatformCacheUtility.CURRENT_USER_SESSION_DATA);
            return result;
        }

        if (!convertLeadData.isBilling) {

            if (convertLeadData.opportunityId == null) {
                throw new ConvertLeadDTOValidationException('opportunityId:Id is required parameter for Quote creation and cannot be null');
            }

            Boolean isNeedToInsert = true;

            Map<String, String> paramsForQuoteCreation = new Map<String, String>{
                'pricebook2Id' => convertLeadData.pricebook2Id,
                'quoteId' => null,
                'lines' => String.valueOf(convertLeadData.forecastedUsers),
                'opportunityId' => convertLeadData.opportunityId,
                'upsellStatus' => convertLeadData.upsellStatus,
                'recordTypeId' => null,
                'proServDetails' => null,
                'isCC' => null
            };

            Quote createdQuote = QuotingToolQuoteApexController.saveQuote(paramsForQuoteCreation, isNeedToInsert);

            result.setData(QUOTEID_RESPONSE_IDENTIFIER, createdQuote.Id);

            Decimal existingUsers = 0;
            if (QuoteHelper.isExistingBusiness(convertLeadData.upsellStatus)) {
                Entitlement__c serviceEnt = EntitlementHelper.getServiceEntitlement(
                    QuoteHelper.RT_ID_SALES,
                    QuotingToolQuoteApexController.getEntitlementsSync(convertLeadData.accountId)
                );
                existingUsers = serviceEnt == null ? 0 : serviceEnt.Quantity__c;
                Map<String, String> paramsForEntQLICreation = new Map<String, String>{
                    'pricebook2Id' => convertLeadData.pricebook2Id,
                    'quoteId' => createdQuote.Id,
                    'additionalForecastedUsers' => String.valueOf(convertLeadData.forecastedUsers - existingUsers),
                    'type' => convertLeadData.upsellStatus
                };
                OpportunityCreationFormController.addEntitlementsAsLineItems(paramsForEntQLICreation);
                QuotingToolQuoteApexController.handleExtendedEnterpriseSupport(createdQuote.Id);
            }

            Map<String, String> paramsForQLICreation = new Map<String, String>{
                'pricebook2Id' => convertLeadData.pricebook2Id,
                'quoteId' => createdQuote.Id,
                'quantity' => String.valueOf(convertLeadData.forecastedUsers - existingUsers)
            };
            OpportunityCreationFormController.createAdditionalSoftphoneQLIs(paramsForQLICreation);
        }
        PlatformCacheUtility.removeKeys(PlatformCacheUtility.SESSION_CACHE,PlatformCacheUtility.CURRENT_USER_SESSION_DATA);

        return result;
    }

    public static Response convertPart4(ConvertLeadDTO convertLeadData) {

        Response result = new Response();

        try {

            if (convertLeadData == null || !convertLeadData.isElaAccount || !convertLeadData.isCreateAccount) {
                PlatformCacheUtility.removeKeys(PlatformCacheUtility.SESSION_CACHE,PlatformCacheUtility.CURRENT_USER_SESSION_DATA);
                return result;
            }

            convertLeadData.validate();

            if (convertLeadData.elaServiceOpportunityIds == null) {
                convertLeadData.elaServiceOpportunityIds = new List<Id>();
            }

            Lead convertedLead = selectConvertedLead(convertLeadData.leadId);
            Account elaBillingAccount = AccountSelector.getAccountWithLeadConvertFields(convertLeadData.accountId);
            Opportunity elaBillingOpportunity = selectOpportunityWithLeadConvertFields(convertLeadData.opportunityId);
            List<Account> elaServiceAccountList = AccountHelper.generateElaServiceAccounts(
                elaBillingAccount,
                convertLeadData.elaChunkSize,
                elaBillingAccount.Name);

            List<Account> allElaAccountList = new List<Account>(elaServiceAccountList);

            if(convertLeadData.elaServiceOpportunityIds.isEmpty() && !convertLeadData.isElaLastChunk) {
                elaBillingAccount.ELA_Account_Type__c = AccountHelper.ACCOUNT_TYPE_ELA_BILLING;
                allElaAccountList.add(elaBillingAccount);
            }

            if(convertLeadData.isElaLastChunk) {
                AccountHelper.convertAccountToElaBilling(elaBillingAccount);
                allElaAccountList.add(elaBillingAccount);
            }

            upsert allElaAccountList;

            List<AccountContactRole> acRoleList = new List<AccountContactRole>();
            List<AccountRelation__c> accountRelationList = new List<AccountRelation__c>();
            List<Opportunity> oppList = new List<Opportunity>();
            Opportunity elaServiceOpportunity;
            for(Account elaServiceAcc : elaServiceAccountList) {
                acRoleList.add(
                    AccountHelper.createAccountContactRole(elaServiceAcc.Id, convertLeadData.contactId)
                );
                accountRelationList.add(
                    AccountHelper.createAccountRelationEla(elaBillingAccount.Id, elaServiceAcc.Id)
                );

                if (!convertLeadData.doNotCreateOpportunity && elaBillingOpportunity != null) {
                    elaServiceOpportunity = elaBillingOpportunity.clone(false, false, false, false);
                    elaServiceOpportunity.AccountId = elaServiceAcc.Id;
                    elaServiceOpportunity.ContactId = convertLeadData.contactId;
                    oppList.add(elaServiceOpportunity);
                }
            }

            if (!convertLeadData.doNotCreateOpportunity && elaBillingOpportunity != null && convertLeadData.isElaLastChunk) {
                elaBillingOpportunity.Name = StringHelper.safeSubstring(elaBillingOpportunity.Name,
                    Opportunity.Name.getDescribe().length - AccountHelper.ACCOUNT_BILLABLE_POSTFIX.length()) +
                    AccountHelper.ACCOUNT_BILLABLE_POSTFIX;
            }
            if (convertedLead.RecordTypeId == LeadHelper.RT_ID_PARTNER_LEADS && convertedLead.Partner_Lead_Owner__c != null) {
                new ConvertPartnerLead().shareAccountToPartner(convertedLead.Partner_Lead_Owner__c, new Map<String, Account>(elaServiceAccountList).keySet());
            }

            List<Opportunity> allElaOpportunityList = new List<Opportunity>(oppList);
            if(convertLeadData.isElaLastChunk) {
                allElaOpportunityList.add(elaBillingOpportunity);
            }

            upsert allElaOpportunityList;

            convertLeadData.elaServiceOpportunityIds.addAll(new Map<Id, Opportunity>(oppList).keySet());

            insert acRoleList;
            insert accountRelationList;
        } catch (Exception e) {
            result.error(e);
        }

        result = fillNextPartResponse(
            convertLeadData.accountId,
            convertLeadData.contactId,
            convertLeadData.opportunityId,
            convertLeadData
        );

        return result;
    }

    private static Lead selectConvertedLead(Id convertedLeadId){
        return (Lead) new LeadSelector()
            .selectLeadForConvert(new List<Object>{convertedLeadId})
            .executeQuery()[0];
    }

    private static Opportunity selectOpportunityWithLeadConvertFields(Id oppId){
        return (Opportunity) new OpportunitySelector()
            .selectOpportunityWithLeadConvertFields(oppId)
            .executeQuery()[0];
    }

    private static Response fillNextPartResponse(Id accId, Id contactId, Id oppId, ConvertLeadDTO convertLeadData) {
        Response result = new Response();

        result.setData(ACCOUNTID_RESPONSE_IDENTIFIER, accId);

        result.setData(CONTACTID_RESPONSE_IDENTIFIER, contactId);

        result.setData(OPPORTUNITYID_RESPONSE_IDENTIFIER, oppId);

        // prepare data for next part
        ConvertLeadDTO convertLeadDataForNextPart = new ConvertLeadDTO(convertLeadData);
        convertLeadDataForNextPart.opportunityId = oppId;

        result.setData(CONVERTDATA_RESPONSE_IDENTIFIER, convertLeadDataForNextPart);

        return result;
    }

    private static void fillUsersCacheWithCurrentUser() {
        Id currentUserId = UserInfo.getUserId();
        if (OpportunityTriggerHelperRefactored.UsersCacheInstance.Users.containsKey(currentUserId) == false) {
            OpportunityTriggerHelperRefactored.UsersCacheInstance.ValidateAndFill(new Set<Id>{ currentUserId });
        }
    }

    private static Lead populateFieldsRequiredForConvert(Lead leadRecord, ConvertLeadDTO convertLeadData) {
        if (leadRecord == null || convertLeadData == null) {
            return leadRecord;
        }

        String brand = convertLeadData.brand;
        String country = convertLeadData.country;
        String edition = convertLeadData.edition;
        String product = convertLeadData.product;
        String term = convertLeadData.term;
        Integer forecastedUsers = convertLeadData.forecastedUsers;
        Integer forecasteEDUsers = convertLeadData.forecastedDigitalUsers;
        Integer forecasteEVUsers = convertLeadData.forecastedVoiceUsers;
        Integer forecastedCCUsers = convertLeadData.ccForecastedUsers;
        Integer forecastedGlobalUsers = convertLeadData.forecastedGlobalUsers;
        Integer forecastedEventUser = convertLeadData.forecastedEventUsers;
        
        if (String.isNotBlank(convertLeadData.pricebook2Id)) {
            Pricebook2 pb = (Pricebook2) new Pricebook2Selector()
                .getPricebookForLeadConvert(new List<Object>{ convertLeadData.pricebook2Id })
                .executeQuery().get(0);

            brand = pb.Brand__r.Name;
            edition = pb.Edition__c;
            product = pb.Service__c;
            term = pb.Plan__c;
        }

        leadRecord.Is_Billing__c = convertLeadData.isBilling;
        if(leadRecord.Lead_Brand_Name__c==null || (leadRecord.Lead_Brand_Name__c!=null && System.Label.BizMerge_Brand_Exclusion_List!=null
                       && !System.Label.BizMerge_Brand_Exclusion_List.contains(leadRecord.Lead_Brand_Name__c)) ){//BizMerge-Added Brand Name check to exclude DFR logic for ATT Leads
           leadRecord.Lead_Brand_Name__c = brand;
           }
        leadRecord.RC_Edition__c = edition;
        leadRecord.Lead_Tier_Name__c = product;
        leadRecord.RC_Term__c = term;
        leadRecord.Country__c = String.isNotBlank(country) ? country : leadRecord.Country__c;
        //filling out forecasted fields from the Lead Convert page for correct pipeline calculations ISUS-169
        leadRecord.Number_of_Users__c = forecastedUsers != null ? forecastedUsers : leadRecord.Number_of_Users__c;
        leadRecord.Forecasted_Engage_Digital_Users__c = forecasteEDUsers != null ? forecasteEDUsers : leadRecord.Forecasted_Engage_Digital_Users__c;
        leadRecord.Forecasted_Engage_Voice_Users__c = forecasteEVUsers != null ? forecasteEVUsers : leadRecord.Forecasted_Engage_Voice_Users__c;
        leadRecord.Forecasted_Contact_Center_Users__c = forecastedCCUsers != null ? forecastedCCUsers : leadRecord.Forecasted_Contact_Center_Users__c;
        leadRecord.Forecasted_Global_Office_Users__c = forecastedGlobalUsers != null ? forecastedGlobalUsers : leadRecord.Forecasted_Global_Office_Users__c;
        leadRecord.Forecasted_Events_Users__c = forecastedEventUser != null ? forecastedEventUser : leadRecord.Forecasted_Events_Users__c;
       
        update leadRecord;

        return leadRecord;
    }

    private static void updateOpportunityContactRole(Id oppId, Id contactId) {

        if (oppId == null && contactId == null) {
            return;
        }

        OpportunityContactRoleSelector selector = new OpportunityContactRoleSelector();

        List<Object> bindings = new List<Object>();
        bindings.add(oppId);
        bindings.add(contactId);

        List<OpportunityContactRole> oppContactRoleList = selector
            .selectOCRForLeadConvert(bindings)
            .executeQuery();

        OpportunityContactRole oppContactRoleObj = oppContactRoleList.isEmpty() ? null : oppContactRoleList.get(0);

        if (oppContactRoleObj != null) {
            if (!oppContactRoleObj.IsPrimary) {
                oppContactRoleObj.IsPrimary = true;
            }
            oppContactRoleObj.Role = OpportunityHelper.CONTACT_ROLE_SIGNATORY;
            update oppContactRoleObj;
        } else {
            insert new OpportunityContactRole(
                OpportunityId = oppId,
                ContactId = contactId,
                Role = OpportunityHelper.CONTACT_ROLE_SIGNATORY,
                isPrimary = true
            );
        }
    }

    public static void manageContactRoleCreation(String oppSectionOptionSelected,
                                                 String roleSelected,
                                                 Id accId,
                                                 Id oppId,
                                                 Id conId,

                                                 OpportunityContactRole oppHasPrimaryContactRole,
                                                 Boolean isCreateOpportunity) {
        if (isCreateOpportunity) {
            accountValidContactRoleLogic(roleSelected, accId, oppId, conId, oppSectionOptionSelected);
        } else if (oppSectionOptionSelected == 'selectExistingOpp') {
            if (oppHasPrimaryContactRole != null) {
                //create Acc contact role on opportunity using selected contact non primary
                Boolean isPrimary  = oppHasPrimaryContactRole.ContactId == conId? true : false;
                updateOpportunityContactRoleForSalesLeads(oppId, conId, roleSelected, isPrimary);
            } else {
                accountValidContactRoleLogic(roleSelected, accId, oppId, conId, oppSectionOptionSelected);
            }
        }
    }

    private static void accountValidContactRoleLogic(String roleSelected, Id accId, Id oppId, Id conId, String optionSelected) {
        AccountContactRole primaryAcr;
        if (accId != null) {
            primaryAcr = accountHasPrimaryContactRole(accId);
        }
        if (primaryAcr != null) {
            if (accountContactRoleIsValid(primaryAcr)) {

                accountPrimaryContactId = primaryAcr.ContactId;
                //mirror Acc's contact role from account on opportunity
                if (optionSelected == 'createNewOpp' && (conId != null && conId == primaryAcr.ContactId)) {
                  updateOpportunityContactRoleForSalesLeads(oppId, conId, roleSelected, true);
                } else {
                    updateOpportunityContactRoleForSalesLeads(oppId, primaryAcr.ContactId, null, true);
                    if (conId != null) {
                        updateOpportunityContactRoleForSalesLeads(oppId, conId, roleSelected, false);
                    } else {
                        Contact newContact = (Contact) new SObjectBuilder (Contact.SObjectType)
                                          .setFields(SObjectFactoryFieldDefaults.getDefaults(Contact.SObjectType))
                                          .setField(Contact.AccountId, accId)
                                          .create()
                                          .getRecord();
                        updateOpportunityContactRoleForSalesLeads(oppId, newContact.Id, roleSelected, false);
                    }
                }
            } else {
                updateAccountContactRole(accId, conId, roleSelected, false);
                updateOpportunityContactRoleForSalesLeads(oppId, conId, roleSelected, true);
            }
        } else {
            //create contact role on opportunity using selected contact primary
            updateOpportunityContactRoleForSalesLeads(oppId, conId, roleSelected, true);
            //create Acc contact primary
            updateAccountContactRole(accId, conId, null, true);
        }
    }

    private static AccountContactRole accountHasPrimaryContactRole(Id accId) {
        AccountContactRole acrToReturn;
        List<Object> bindings = new List<Object>();
        bindings.add(accId);
        List<AccountContactRole> primaryAcrList = (List<AccountContactRole>) new AccountContactRoleSelector()
                                 .selectPrimaryAccountContactRolesByAccountIds(bindings).executeQuery();

        if (!primaryAcrList.isEmpty()) {
            return primaryAcrList[0];
        } else {
            return null;
        }
    }

    private static Boolean accountContactRoleIsValid(AccountContactRole acr) {
        List<Object> bindings = new List<Object>();
        bindings.add(acr.ContactId);
        bindings.add(acr.AccountId);
        List<Contact> con = (List<Contact>) new ContactSelector()
                      .selectContactsByAccountId(bindings)
                      .setCondition('Id =:bind0 AND AccountId = :bind1')
                      .executeQuery();
        if (!con.isEmpty()) {
            return true;
        } else {
            return false;
        }
    }

    @TestVisible
    private static OpportunityContactRole oppHasValidPrimaryContactRole(Id oppId) {
        OpportunityContactRole result;
        List<Object> bindings = new List<Object>();
        bindings.add(oppId);
        List<OpportunityContactRole> primaryOcrList = (List<OpportunityContactRole>) new OpportunityContactRoleSelector()
                                 .selectPrimaryOpportunityContactRolesByOppIds(bindings).executeQuery();
        result = primaryOcrList.isEmpty()? null : primaryOcrList[0];
        return result;
    }

    @TestVisible
    private static void updateAccountContactRole(Id accId, Id contactId, String roleSelected, Boolean primary) {
        List<Object> bindings = new List<Object>();
        bindings.add(accId);
        bindings.add(contactId);
        if (primary) {
            roleSelected = OpportunityHelper.CONTACT_ROLE_SIGNATORY;
        }
        List<AccountContactRole> acrList = (List<AccountContactRole>) new AccountContactRoleSelector()
                                 .selectAccountContactRolesByAccountAndContactIds(bindings).executeQuery();
        if (acrList.isEmpty()) {
            insert new AccountContactRole(AccountId = accId,
                                      ContactId = contactId,
                                      Role = roleSelected,
                                      isPrimary = primary
            );
        } else {
            AccountContactRole acr = acrList[0];
            acr.Role = roleSelected;
            update acr;
        }
    }

    private static void updateOpportunityContactRoleForSalesLeads(Id oppId,
                                                                  Id contactId,
                                                                  String roleSelected,
                                                                  Boolean primary) {

        if (oppId == null && contactId == null) {
            return;
        }

        if (primary) {
            roleSelected = OpportunityHelper.CONTACT_ROLE_SIGNATORY;
        }

        OpportunityContactRoleSelector selector = new OpportunityContactRoleSelector();

        List<Object> bindings = new List<Object>();
        bindings.add(oppId);
        bindings.add(contactId);

        List<OpportunityContactRole> oppContactRoleList = selector
            .selectOCRForLeadConvert(bindings)
            .executeQuery();

        OpportunityContactRole oppContactRoleObj = oppContactRoleList.isEmpty() ? null : oppContactRoleList.get(0);

        if (oppContactRoleObj != null) {
            oppContactRoleObj.isPrimary = primary;
            if (roleSelected != null) {
                oppContactRoleObj.Role = roleSelected;
            }
            update oppContactRoleObj;
        } else {
            insert new OpportunityContactRole(
                OpportunityId = oppId,
                ContactId = contactId,
                Role = roleSelected,
                isPrimary = primary
            );
        }
    }


    public static Account mapSalesLeadsFieldsToRelatedAccount(Lead leadObj, Account acc,Contact con) {
        List<String> fieldList = new List<String> {
            'NumberOfEmployees',
            'Rating',
            'Website',
            'LS_Enrichment_Date__c',
            'Company_DUNS__c',
            'AnnualRevenue',
            'LID__LinkedIn_Company_Id__c',
            'VATNumber__c',
            'ParentId',
            'BillingCountry'
        };
        Account accObj = (Account) new AccountSelector().selectAccountById(acc.Id)
                                                        .selectFields(fieldList)
                                                        .executeQuery()[0];
        fieldList = new List<String> {
            'LID__LinkedIn_Company_Id__c'
        };
        Contact conObj = (Contact) new ContactSelector().selectContactsByIds(new List<Object>{new List<Id>{ con.Id } })
                                                        .selectFields(fieldList)
                                                        .executeQuery()[0];
        //new field mapping for account
        if (leadObj.CurrencyIsoCode != null) {
            accObj.CurrencyIsoCode = leadObj.CurrencyIsoCode;
        }
        if (accObj.NumberOfEmployees == null) {
            accObj.NumberOfEmployees = leadObj.NumberOfEmployees;
        }
        if (accObj.Rating == null) {
            accObj.Rating = leadObj.Rating;
        }
        if (accObj.Website == null) {
            accObj.Website = leadObj.Website;
        }
        if (accObj.Company_DUNS__c == null) {
            accObj.Company_DUNS__c = leadObj.Company_DUNS__c;
        }
        if (accObj.AnnualRevenue == null) {
            accObj.AnnualRevenue = leadObj.AnnualRevenue;
        }

        if (accObj.BillingCountry == null) {
            accObj.BillingCountry = leadObj.Country__c;
        }

        if (accObj.VATNumber__c == null) {
            accObj.VATNumber__c = leadObj.VATNumber__c;
        }
        if(leadObj.ZI_CDP_Account_Id__c != null){
            accObj.ParentId = leadObj.ZI_CDP_Account_Id__c;
        }

        //Field mapping for both Account and Contact
        if (accObj.LID__LinkedIn_Company_Id__c == null && conObj.LID__LinkedIn_Company_Id__c == null) {
            accObj.LID__LinkedIn_Company_Id__c = leadObj.LID__LinkedIn_Company_Id__c;
            conObj.LID__LinkedIn_Company_Id__c = leadObj.LID__LinkedIn_Company_Id__c;
        }
        return accObj;
    }

    public static Opportunity mapSalesLeadsFieldsToRelatedOpportunity(Lead leadObj, Opportunity opp, Contact con) {
        List<String> fieldList = new List<String> {
            'Lead_Entry_Source__c',
            'CreatedDate'
        };
        Opportunity oppObj = (Opportunity) new OpportunitySelector()
                                          .selectOpportunitiesByIds(new Set<Id>{ opp.Id })
                                          .selectFields(fieldList)
                                          .executeQuery()[0];
        fieldList = new List<String> {
          'Lead_Entry_Source__c',
          'CreatedDate'
        };
        Contact conObj = (Contact) new ContactSelector().selectContactsByIds(new List<Object>{new List<Id>{ con.Id } })
                                                                                        .selectFields(fieldList)
                                                                                        .executeQuery()[0];
        //Field mapping for both Opportunity and Contact
        if (oppObj.Lead_Entry_Source__c == null && conObj.Lead_Entry_Source__c == null) {
            oppObj.Lead_Entry_Source__c = leadObj.Lead_Entry_Source__c;
            conObj.Lead_Entry_Source__c = leadObj.Lead_Entry_Source__c;
        }

        //Field mapping for Opportunity
        if (leadObj.LeadSource != null) {
            oppObj.LeadSource = leadObj.LeadSource;
        }
        if (leadObj.AID__c != null) {
            oppObj.AID__c = leadObj.AID__c;
        }
        if (leadObj.BMID__c != null) {
            oppObj.BMID__c = leadObj.BMID__c;
        }
        if (leadObj.ConversionPage__c != null) {
            oppObj.ConversionPage__c = leadObj.ConversionPage__c;
        }
        if (leadObj.GCLID__c != null) {
            oppObj.GCLID__c = leadObj.GCLID__c;
        }
        if (leadObj.KCID__c != null) {
            oppObj.MKWID__c = leadObj.KCID__c;
        }
        if (leadObj.PID__c != null) {
            oppObj.PID__c = leadObj.PID__c;
        }
        if (leadObj.RCKW__c != null) {
            oppObj.RCKW__c = leadObj.RCKW__c;
        }
        if (leadObj.RCMT__c != null) {
            oppObj.RCMT__c = leadObj.RCMT__c;
        }
        if (leadObj.SID__c != null) {
            oppObj.SID__c = leadObj.SID__c;
        }
        return oppObj;
    }

    public static Contact mapSalesLeadsFieldsToRelatedContact(Lead leadObj, Contact con, Id convertedOppId) {
        List<String> fieldList = new List<String> {
            'LID__LinkedIn_Company_Id__c',
            'LS_Enrichment_Date__c',
            'Description',
            'DoNotCall',
            'HasOptedOutOfEmail',
            'HasOptedOutOfFax',
            'Actively_Being_Sequenced__c',
            'Do_Not_Call__c',
            'Do_Not_Direct_Mail__c',
            'Do_Not_SMS__c',
            'Events_Opt_In__c',
            'LID__LinkedIn_Member_Token__c',
            'Meeting_Type_CP__c',
            'Ok_to_Email__c',
            'Webinars_Opt_In__c',
            'Company_DUNS__c',
            'Lead_Entry_Source__c',
            'SIA_Information__c',
            'CreatedDate',
            'Most_Recent_MQL_Date__c',
            'Forecasted_Contact_Center_Users__c',
            'Forecasted_Engage_Digital_Users__c',
            'Forecasted_Engage_Voice_Users__c',
            'Forecasted_Global_Office_Users__c',
            'Forecasted_Office_Users__c',
            'Forecasted_RingCentral_Video_Users__c',
            'saasquatch_program_selector__c'
        };
        Contact conObj = (Contact) new ContactSelector().selectContactsByIds(new List<Object>{new List<Id>{ con.Id } })
                                                        .selectFields(fieldList)
                                                        .executeQuery()[0];

        //new field mapping for contact
        if (conObj.LS_Enrichment_Date__c == null) {
            conObj.LS_Enrichment_Date__c = leadObj.LS_Enrichment_Date__c;
        }
        if (leadObj.LS_Enrichment_Status__c != null) {
            conObj.LS_Enrichment_Status__c = leadObj.LS_Enrichment_Status__c;
        }
        if (leadObj.Street != null) {
            conObj.MailingStreet = leadObj.Street;
        }
        if (leadObj.State != null) {
            conObj.MailingState = leadObj.State;
        }
        if (leadObj.PostalCode != null) {
            conObj.MailingPostalCode = leadObj.PostalCode;
        }
        if (leadObj.Longitude != null) {
            conObj.MailingLongitude = leadObj.Longitude;
        }
        if (leadObj.Latitude != null) {
            conObj.MailingLatitude = leadObj.Latitude;
        }
        if (leadObj.Country != null) {
            conObj.MailingCountry = leadObj.Country;
        }
        if (leadObj.City != null) {
            conObj.MailingCity = leadObj.City;
        }
        if (leadObj.CurrencyIsoCode != null) {
            conObj.CurrencyIsoCode = leadObj.CurrencyIsoCode;
        }
        if (String.isNotBlank(leadObj.Description)) {
            conObj.Description += leadObj.Description;
        }
        if (conObj.DoNotCall == null) {
            conObj.DoNotCall = leadObj.DoNotCall;
        }
        if (leadObj.Email != null) {
            conObj.Email = leadObj.Email;
        }
        if (leadObj.Fax != null) {
            conObj.Fax = leadObj.Fax;
        }
        if (leadObj.FirstName != null) {
            conObj.FirstName = leadObj.FirstName;
        }
        if (leadObj.LastName != null) {
            conObj.LastName = leadObj.LastName;
        }
        if (conObj.HasOptedOutOfEmail == null) {
            conObj.HasOptedOutOfEmail = leadObj.HasOptedOutOfEmail;
        }
        if (conObj.HasOptedOutOfFax == null) {
            conObj.HasOptedOutOfFax = leadObj.HasOptedOutOfFax;
        }
        if (leadObj.MobilePhone != null) {
            conObj.MobilePhone = leadObj.MobilePhone;
        }
        if (leadObj.Phone != null) {
            conObj.Phone = leadObj.Phone;
        }
        if (leadObj.Salutation != null) {
            conObj.Salutation = leadObj.Salutation;
        }
        if (leadObj.Status != null && convertedOppId == null) {
            conObj.Contact_Status__c = leadObj.Status;
        }
        if (leadObj.Title != null) {
            conObj.Title = leadObj.Title;
        }
        if (conObj.Actively_Being_Sequenced__c == null) {
            conObj.Actively_Being_Sequenced__c = leadObj.Actively_Being_Sequenced__c;
        }
        if (leadObj.Adobe_Target_Id__c != null) {
            conObj.Adobe_Target_Id__c = leadObj.Adobe_Target_Id__c;
        }
        if (leadObj.Adobe_Target_Id_History__c != null) {
            conObj.Adobe_Target_Id_History__c = leadObj.Adobe_Target_Id_History__c;
        }
        if (leadObj.BMID_Old__c != null) {
            conObj.BMID_Old__c = leadObj.BMID_Old__c;
        }
        if (leadObj.CASS_Address_Line_1__c != null) {
            conObj.CASS_Address_Line_1__c = leadObj.CASS_Address_Line_1__c;
        }
        if (leadObj.CASS_Address_Line_2__c != null) {
            conObj.CASS_Address_Line_2__c = leadObj.CASS_Address_Line_2__c;
        }
        if (leadObj.Current_Sequence_ID__c != null) {
            conObj.Current_Sequence_ID__c = leadObj.Current_Sequence_ID__c;
        }
        if (leadObj.Current_Sequence_Name__c != null) {
            conObj.Current_Sequence_Name__c = leadObj.Current_Sequence_Name__c;
        }
        if (leadObj.Current_Sequence_Status__c != null) {
            conObj.Current_Sequence_Status__c = leadObj.Current_Sequence_Status__c;
        }
        if (leadObj.Current_Sequence_Step_Number__c != null) {
            conObj.Current_Sequence_Step_Number__c = leadObj.Current_Sequence_Step_Number__c;
        }
        if (leadObj.Current_Sequence_Step_Type__c != null) {
            conObj.Current_Sequence_Step_Type__c = leadObj.Current_Sequence_Step_Type__c;
        }
        if (leadObj.Current_Sequence_Task_Due_Date__c != null) {
            conObj.Current_Sequence_Task_Due_Date__c = leadObj.Current_Sequence_Task_Due_Date__c;
        }
        if (leadObj.Current_Sequence_User_SFDC_ID__c != null) {
            conObj.Current_Sequence_User_SFDC_ID__c = leadObj.Current_Sequence_User_SFDC_ID__c;
        }
        if (conObj.Do_Not_Call__c == null) {
            conObj.Do_Not_Call__c = leadObj.Do_Not_Call__c;
        }
        if (conObj.Do_Not_Direct_Mail__c == null) {
            conObj.Do_Not_Direct_Mail__c = leadObj.Do_Not_Direct_Mail__c;
        }
        if (conObj.Do_Not_SMS__c == null) {
            conObj.Do_Not_SMS__c = leadObj.Do_Not_SMS__c;
        }
        if (leadObj.Email_Invalid__c != null) {
            conObj.Email_Invalid__c = leadObj.Email_Invalid__c;
        }
        if (leadObj.Entry_URL__c != null) {
            conObj.Entry_URL__c = leadObj.Entry_URL__c;
        }
        if (leadObj.Integration_Apps__c != null) {
            conObj.Integration_Apps__c = leadObj.Integration_Apps__c;
        }
        if (conObj.LID__LinkedIn_Member_Token__c == null) {
            conObj.LID__LinkedIn_Member_Token__c = leadObj.LID__LinkedIn_Member_Token__c;
        }
        if (leadObj.LS_Best_Fit_Persona__c != null) {
            conObj.LS_Best_Fit_Persona__c = leadObj.LS_Best_Fit_Persona__c;
        }
        if (leadObj.LS_Predictive_Score__c != null) {
            conObj.LS_Predictive_Score__c = leadObj.LS_Predictive_Score__c;
        }
        if (leadObj.Marketability__c != null) {
            conObj.Marketability__c = leadObj.Marketability__c;
        }
        if (conObj.Meeting_Type_CP__c == null) {
            conObj.Meeting_Type_CP__c = leadObj.Meeting_Type_CP__c;
        }
        if (leadObj.Most_Recent_Campaign__c != null) {
            conObj.Most_Recent_Campaign__c = leadObj.Most_Recent_Campaign__c;
        }
        if (leadObj.Number_of_Active_Sequences__c != null) {
            conObj.Number_of_Active_Sequences__c = leadObj.Number_of_Active_Sequences__c;
        }
        if (conObj.Ok_to_Email__c == null) {
            conObj.Ok_to_Email__c = leadObj.Ok_to_Email__c;
        }
        if (leadObj.Outreach_Stages__c != null) {
            conObj.Outreach_Stages__c = leadObj.Outreach_Stages__c;
        }
        if (String.isNotBlank(leadObj.SIA_Information__c)) {
            conObj.SIA_Information__c += leadObj.SIA_Information__c;
        }
        if (leadObj.SmartSearchURL__c != null) {
            conObj.SmartSearchURL__c = leadObj.SmartSearchURL__c;
        }
        if (leadObj.The_Set__c != null) {
            conObj.The_Set__c = leadObj.The_Set__c;
        }
        if (leadObj.Transaction_Id__c != null) {
            conObj.Transaction_Id__c = leadObj.Transaction_Id__c;
        }
        if (leadObj.LeadSource != null) {
            conObj.LeadSource = leadObj.LeadSource;
        }
        if (leadObj.AID__c != null) {
            conObj.AID__c = leadObj.AID__c;
        }
        if (leadObj.BMID__c != null) {
            conObj.BMID__c = leadObj.BMID__c;
        }
        if (leadObj.ConversionPage__c != null) {
            conObj.ConversionPage__c = leadObj.ConversionPage__c;
        }
        if (leadObj.GCLID__c != null) {
            conObj.GCLID__c = leadObj.GCLID__c;
        }
        if (leadObj.KCID__c != null) {
            conObj.MKWID__c = leadObj.KCID__c;
        }
        if (leadObj.PID__c != null) {
            conObj.PID__c = leadObj.PID__c;
        }
        if (leadObj.RCKW__c != null) {
            conObj.RCKW__c = leadObj.RCKW__c;
        }
        if (leadObj.RCMT__c != null) {
            conObj.RCMT__c = leadObj.RCMT__c;
        }
        if (leadObj.SID__c != null) {
            conObj.SID__c = leadObj.SID__c;
        }
        if (conObj.Company_DUNS__c == null) {
            conObj.Company_DUNS__c = leadObj.Company_DUNS__c;
        }
        if(leadObj.Forecasted_Contact_Center_Users__c != null){
            conObj.Forecasted_Contact_Center_Users__c = leadObj.Forecasted_Contact_Center_Users__c;
        }
        if(leadObj.Forecasted_Engage_Digital_Users__c != null){
            conObj.Forecasted_Engage_Digital_Users__c = leadObj.Forecasted_Engage_Digital_Users__c;
        }
        if(leadObj.Forecasted_Engage_Voice_Users__c != null){
            conObj.Forecasted_Engage_Voice_Users__c = leadObj.Forecasted_Engage_Voice_Users__c;
        }
        if(leadObj.Forecasted_Global_Office_Users__c != null){
            conObj.Forecasted_Global_Office_Users__c = leadObj.Forecasted_Global_Office_Users__c;
        }
        if(leadObj.Number_of_Users__c != null){
            conObj.Forecasted_Office_Users__c = leadObj.Number_of_Users__c;
        }
        if(leadObj.Forecasted_RingCentral_Video_Users__c != null){
            conObj.Forecasted_RingCentral_Video_Users__c = leadObj.Forecasted_RingCentral_Video_Users__c;
        }
        if(leadObj.saasquatch_program_selector__c != null) {
            conObj.saasquatch_program_selector__c = leadObj.saasquatch_program_selector__c;
        }
        return conObj;
    }

    private static Account copyLeadToAccountFields(Account accObj, Lead leadObj, ConvertLeadOwnerData owner, Integer forecastedUsers) {

        if (String.isNotBlank(leadObj.Website)) {
            accObj.Website = leadObj.Website;
        }
        if (leadObj.NumberOfEmployees != null) {
            accObj.NumberOfEmployees = leadObj.NumberOfEmployees;
        }
        if (String.isNotBlank(leadObj.Industry)) {
            accObj.Industry = leadObj.Industry;
        }
        if (String.isNotBlank(leadObj.Effective_No_of_Employees_Range__c)) {
            accObj.No_of_Employees__c = leadObj.Effective_No_of_Employees_Range__c;
        }
        if (String.isNotBlank(leadObj.Number_of_Locations__c)) {
            accObj.Number_Of_Locations__c = leadObj.Number_of_Locations__c;
        }
        if (String.isNotBlank(leadObj.Lead_Brand_Name__c)) {
            accObj.RC_Brand__c = leadObj.Lead_Brand_Name__c;
        }
        //Added for Mitel
        if (String.isNotBlank(leadObj.Type_of_Customer_or_Prospect__c)) {
            accObj.Type_of_Customer_or_Prospect__c = leadObj.Type_of_Customer_or_Prospect__c;
        }
        if (String.isNotBlank(leadObj.Mitel_Data_Sharing__c)) {
            accObj.Mitel_Data_Sharing__c = leadObj.Mitel_Data_Sharing__c;
        }
        //Added for Mitel ends
        if (String.isNotBlank(leadObj.Lead_Tier_Name__c)) {
            accObj.Most_Recent_Opportunity_Tier_Name__c = leadObj.Lead_Tier_Name__c;
        }
        if (String.isNotBlank(owner.ownerId)) {
            accObj.Most_Recent_Opportunity_Owner__c = owner.ownerId;
        }
        if (String.isNotBlank(owner.email)) {
            accObj.Most_Recent_Opportunity_Owner_Email__c = owner.email;
        }
        if (String.isNotBlank(owner.firstName)) {
            accObj.Most_Recent_Opportunity_Owner_FirstName__c = owner.firstName;
        }
        if (String.isNotBlank(owner.lastName)) {
            accObj.Most_Recent_Opportunity_Owner_LastName__c = owner.lastName;
        }
        if (String.isNotBlank(owner.phone)) {
            accObj.Most_Recent_Opportunity_Owner_Phone__c = owner.phone;
        }

        if (forecastedUsers != null) {
            accObj.Most_Recent_Opportunity_Forecasted_Users__c = forecastedUsers;
        }

        if (leadObj.VATNumber__c != null) {
            accObj.VATNumber__c = leadObj.VATNumber__c;
        }

        accObj.Most_Recent_Opportunity_Stage__c = OpportunityHelper.defaultOpportunityStage;

        return accObj;
    }


    private static Opportunity prepareOpportunityRecord(Id oppId, ConvertLeadDTO convertLeadData, String tierName, Id accPrimaryContactId) {
        Opportunity oppRecord = new Opportunity(
            Id = oppId
        );

        if (convertLeadData.opportunityName != null) {
            oppRecord.Name = StringHelper.safeSubstring(convertLeadData.opportunityName, Opportunity.Name.getDescribe().length);
        }
        populateForecastedUserFields(oppRecord, tierName, convertLeadData);

        oppRecord.Forecast_Contact_Center_Users__c = NumberHelper.toNumber(convertLeadData.ccForecastedUsers);
        oppRecord.ForcastedDimeloUsers__c = NumberHelper.toNumber(convertLeadData.forecastedDigitalUsers);
        oppRecord.Forecast_Connect_First_Users__c = NumberHelper.toNumber(convertLeadData.forecastedVoiceUsers);
        oppRecord.Forecasted_Global_Office_Users__c = NumberHelper.toNumber(convertLeadData.forecastedGlobalUsers);
        oppRecord.Forecasted_RingCentral_Video_Users__c = NumberHelper.toNumber(convertLeadData.forecastedRCVideoUsers);    
        oppRecord.Forecasted_Events_Users__c = NumberHelper.toNumber(convertLeadData.forecastedEventUsers);

        if (convertLeadData.isBilling) {
            oppRecord.Is_Billing_Opportunity__c = true;
        }

        if (String.isNotBlank(convertLeadData.currencyCode)) {
            oppRecord.CurrencyIsoCode = convertLeadData.currencyCode;
        }

        if (String.isNotBlank(convertLeadData.upsellStatus)) {
            oppRecord.Type = QuoteHelper.isExistingBusiness(convertLeadData.upsellStatus)
                ? OpportunityHelper.OPPORTUNITY_TYPE_EX_BUSINESS
                : OpportunityHelper.OPPORTUNITY_TYPE_NEW_BUSINESS;
        }

        if (convertLeadData.isCreateOpportunity) {
            if (accPrimaryContactId != null) {
                oppRecord.Primary_Opportunity_Contact__c = accPrimaryContactId;
            } else if(convertLeadData.contactId != null) {
                oppRecord.Primary_Opportunity_Contact__c = convertLeadData.contactId;
            }
        }

        if (convertLeadData.isFedRampFlow !=null && convertLeadData.isFedRampFlow) {
            oppRecord.isFedRamp__c = true;
        }

        if (convertLeadData.businessIdentityId != null && convertLeadData.businessIdentityCurrency != null) {
            oppRecord.BusinessIdentity__c = OpportunityHelper.businessIdentitySerialize(convertLeadData.businessIdentityId, convertLeadData.businessIdentityCurrency);
        }

        if (String.isNotBlank(convertLeadData.brand)) {
            oppRecord.Brand_Name__c = convertLeadData.brand;
        }

        if (String.isNotBlank(convertLeadData.subBrand)) {
            oppRecord.Sub_Brand__c = convertLeadData.subBrand;
        }

        if (String.isNotBlank(convertLeadData.accountId)) {
            oppRecord.AccountId = convertLeadData.accountId;
        }

        if (String.isNotBlank(convertLeadData.closeDate)) {
            oppRecord.CloseDate = Date.valueOf(convertLeadData.closeDate);
        }

        oppRecord.Tier_Name__c = tierName;

        return oppRecord;
    }

    private static List<Note> processNotes(Id oppId, ConvertLeadDTO convertLeadData, Lead leadObj) {

        List<Note> resultList = new List<Note>();

        if (oppId == null && convertLeadData == null && leadObj == null) {
            return resultList;
        }

        NoteSelector noteSelector = new NoteSelector();
        List<Object> bindings = new List<Object>();
        bindings.add(convertLeadData.leadId);

        List<Note> leadNotes = (List<Note>) noteSelector
            .selectNotesForLeadConvert(bindings)
            .executeQuery();

        if (!leadNotes.isEmpty()) {

            for(Note noteToInsert : leadNotes) {
                resultList.add(
                    new Note(
                        ParentId = oppId,
                        Title = noteToInsert.Title,
                        Body = noteToInsert.Body,
                        IsPrivate = noteToInsert.IsPrivate
                    )
                );
            }
        }

        if (!String.isBlank(leadObj.Notes__c)) {

            resultList.add(
                new Note(
                    ParentId = oppId,
                    Body = leadObj.Notes__c,
                    Title = 'Original note from lead'
                )
            );
        }

        return resultList;
    }

    @TestVisible
    private static void populateForecastedUserFields(Opportunity opp, String tier, ConvertLeadDTO convertLeadData) {
        opp.ForcastedDimeloUsers__c = NumberHelper.toNumber(OpportunityHelper.getForecastedDigitalUsers(tier, convertLeadData.forecastedUsers));
        opp.Forecast_Connect_First_Users__c = NumberHelper.toNumber(OpportunityHelper.getForecastedVoiceUsers(tier, convertLeadData.forecastedUsers));
        if (String.isNotBlank(convertLeadData.rcUserId)) {
            opp.Forecasted_Users__c = NumberHelper.toNumber(OpportunityHelper.getForecastedOfficeUsers(tier, convertLeadData.forecastedUsers - convertLeadData.existingUsers));
        } else {
            opp.Forecasted_Users__c = convertLeadData.product == Product2Helper.PRODUCT_OFFICE && convertLeadData.forecastedUsers <= 0 ? 1 : convertLeadData.forecastedUsers;
        }
    }


    private class ConvertSalesLead {

        public Database.LeadConvertResult convert(ConvertLeadDTO convertLeadData, LeadStatus convertStatus, Lead leadToConvert) {

            if(convertLeadData == null || convertLeadData.leadId == null || leadToConvert.IsConverted) {
                return null;
            }
            DG_DFR_Class.isContactCreatedByConversion = convertLeadData.isCreateContact;
            DG_DFR_Class.isOpportunityCreatedByConversion = convertLeadData.isCreateOpportunity;
            Database.LeadConvert leadConvert = new Database.LeadConvert();
            leadConvert.setLeadId(convertLeadData.leadId);
            leadConvert.setConvertedStatus(convertStatus.MasterLabel);

            if (convertLeadData.accountId != null) {
                leadConvert.setAccountId(convertLeadData.accountId);
            }
            if (convertLeadData.contactId != null) {
                leadConvert.setContactId(convertLeadData.contactId);
            }

            leadConvert.setDoNotCreateOpportunity(convertLeadData.doNotCreateOpportunity);

            if (!convertLeadData.doNotCreateOpportunity && convertLeadData.opportunityId != null) {
                leadConvert.setOpportunityId(convertLeadData.opportunityId);
            }

            Database.LeadConvertResult convertResult = Database.convertLead(leadConvert);
            System.assert(convertResult.isSuccess());

            return convertResult;
        }

    }

    private class ConvertPartnerLead {

        private Database.LeadConvertResult convert(ConvertLeadDTO convertLeadData, LeadStatus convertStatus, Lead leadToConvert) {

            if(convertLeadData == null || convertLeadData.leadId == null || leadToConvert.IsConverted) {
                return null;
            }

            Id ownerId = String.isNotBlank(convertLeadData.ownerId) ? convertLeadData.ownerId : leadToConvert.OwnerId;
            Database.LeadConvert leadConvert = new Database.LeadConvert();
            leadConvert.setLeadId(convertLeadData.leadId);
            leadConvert.setOwnerId(ownerId);
            leadConvert.setConvertedStatus(convertStatus.MasterLabel);

            if (convertLeadData.accountId != null) {
                leadConvert.setAccountId(convertLeadData.accountId);
            }
            if (convertLeadData.contactId != null) {
                leadConvert.setContactId(convertLeadData.contactId);
            }

            leadConvert.setDoNotCreateOpportunity(convertLeadData.doNotCreateOpportunity);
            AccountTriggerHandler.isPartnerLeadConversion = true;
            Database.LeadConvertResult convertResult = Database.convertLead(leadConvert);
            System.assert(convertResult.isSuccess());
            OpportunityTriggerHelperRefactored.isSkipSecondRunWorkflowActions = false;

            ConvertLeadOwnerData owner = new ConvertLeadOwnerData([
                    SELECT
                        OwnerId,
                        TYPEOF Owner
                            WHEN User
                            THEN Email, Phone, FirstName, LastName
                            WHEN Group
                            THEN Email
                        END
                    FROM Lead
                    WHERE Id =:convertLeadData.leadId
            ]);

            Account accnt = this.populateAccountFieldsFromPartnerLead(convertResult.getAccountId(), leadToConvert, convertLeadData.currencyCode);
            accnt = copyLeadToAccountFields(accnt, leadToConvert, owner, convertLeadData.forecastedUsers);
            update accnt;

            if (leadToConvert.Partner_Lead_Owner__c != null) {
                this.shareAccountToPartner(leadToConvert.Partner_Lead_Owner__c, accnt.Id);
            }

            Contact contactFromLead = this.populateContactFieldsFromPartnerLead(convertResult.getContactId(), leadToConvert, convertLeadData.currencyCode);
            update contactFromLead;

            if (convertLeadData.doNotCreateOpportunity) {
                return convertResult;
            }

            Id convertedOppId = convertResult.getOpportunityId();

            updateOpportunityContactRole(convertedOppId, convertResult.getContactId());

            if (convertLeadData.leadQualificationId != null) {

                LeadQualificationSelector leadQualificationSelector = new LeadQualificationSelector();
                List<Object> bindings = new List<Object>();
                bindings.add(convertLeadData.leadQualificationId);

                List<Lead_Qualification__c> leadQualificationList = (List<Lead_Qualification__c>) leadQualificationSelector
                    .selectLeadQualificationsForBackendConvert(bindings)
                    .executeQuery();
                if (!leadQualificationList.isEmpty()) {
                    Lead_Qualification__c leadQualificationObj = leadQualificationList.get(0);

                    this.mapOpportunityContactRole(convertLeadData.accountId,
                            convertLeadData.contactId,
                            convertLeadData.opportunityId,
                            leadQualificationObj);
                }
            }

            Opportunity createdOpp = prepareOpportunityRecord(convertedOppId, convertLeadData, leadToConvert.Lead_Tier_Name__c,accountPrimaryContactId);

            createdOpp = this.populateOpportunityFieldsFromPartnerLead(createdOpp, leadToConvert);

            createdOpp.CampaignId = leadToConvert.Most_Recent_Campaign__c;

            update createdOpp;


            List<Note> noteList = processNotes(convertedOppId, convertLeadData, leadToConvert);
            if (!noteList.isEmpty()) {
                insert noteList;
            }

            return convertResult;
        }

        private Account populateAccountFieldsFromPartnerLead(Id accId, Lead leadToConvert, string currencyCode) {

            Account accnt = new Account(
                Id = accId,
                OwnerId = leadToConvert.OwnerId,
                RecordTypeId = AccountHelper.RT_ID_CUSTOMER_ACCOUNT,
                BillingStreet = leadToConvert.Street,
                Partner_Contact__c = leadToConvert.Partner_Contact__c,
                Partner_ID__c = leadToConvert.LeadPartnerID__c,
                Partner_Account__c = leadToConvert.Partner_Account__c,
                CurrencyIsoCode = currencyCode
            );

            accnt.BillingStreet = (leadToConvert.Street != null ? leadToConvert.Street : leadToConvert.Street_2__c);
            accnt.BillingCountry = (leadToConvert.Country != null ? leadToConvert.Country : leadToConvert.Country__c);
            accnt.BillingState = (leadToConvert.State != null ? leadToConvert.State : leadToConvert.State__c);
            accnt.BillingCity = (leadToConvert.City != null ? leadToConvert.City : leadToConvert.City__c);
            accnt.BillingPostalCode = (leadToConvert.PostalCode != null ? leadToConvert.PostalCode : leadToConvert.Zip_Code__c);

            if (leadToConvert.VATNumber__c != null) {
                accnt.VATNumber__c = leadToConvert.VATNumber__c;
            }

            if (!String.isBlank(leadToConvert.Lead_Brand_Name__c)) {
                accnt.RC_Brand__c = leadToConvert.Lead_Brand_Name__c;
            }

            if(leadToConvert.Inside_Sales_Rep__c != null) {
                accnt.Inside_Sales_Rep__c = leadToConvert.Inside_Sales_Rep__c;
            }

            Boolean isPopulateProfileLastModifiedDate = leadToConvert.Website != null ||
                leadToConvert.NumberOfEmployees != null || leadToConvert.Industry != null ||
                leadToConvert.Effective_No_of_Employees_Range__c != null ||
                leadToConvert.Number_of_Locations__c != null;

            if (isPopulateProfileLastModifiedDate) {
                accnt.Customer_Profile_Last_modified_Date__c = System.now();
            }

            return accnt;
        }

        private Contact populateContactFieldsFromPartnerLead(Id contactId, Lead leadToConvert, string currencyCode) {

            Contact contactFromLead = new Contact(
                Id = contactId,
                RecordTypeId = ContactHelper.RT_ID_VAR_VISIBLE,
                Description = leadToConvert.Description,
                CurrencyIsoCode = currencyCode,
                Email = leadToConvert.Email,
                FirstName = leadToConvert.FirstName,
                LastName = leadToConvert.LastName,
                LeadSource = leadToConvert.LeadSource,
                MailingCity = leadToConvert.City,
                MailingCountry = leadToConvert.Country,
                MailingPostalCode = leadToConvert.PostalCode,
                MailingState = leadToConvert.State,
                MailingStreet = leadToConvert.Street,
                Street_2__c = leadToConvert.Street_2__c,
                Phone = leadToConvert.Phone,
                Phone_Ext__c = leadToConvert.Phone_Ext__c,
                Title = leadToConvert.Title,
                indexedPhone__c = leadToConvert.Phone,
                indexedEmail__c = leadToConvert.Email
                //Contact_Funnel_Type__c = ContactHelper.FUNNEL_TYPE_ACQUISITION
            );

            return contactFromLead;
        }

        public Opportunity populateOpportunityFieldsFromPartnerLead(Opportunity opp, Lead leadToConvert) {
            return populateOpportunityFieldsFromPartnerLead(opp, leadToConvert, null);
        }

        public Opportunity populateOpportunityFieldsFromPartnerLead(Opportunity opp, Lead leadToConvert, String opportunityType) {

                opp.RecordTypeId = OpportunityHelper.RT_ID_VAR_OPPORTUNITY;
                opp.Website__c = leadToConvert.Website;
                opp.Type = opportunityType == null ? OpportunityHelper.OPPORTUNITY_TYPE_NEW_BUSINESS : opportunityType;
                opp.Partner_ID__c = leadToConvert.LeadPartnerID__c;
                opp.StageName = OpportunityHelper.defaultOpportunityStage;
                opp.Timezone__c = leadToConvert.Timezone__c;
                opp.Agent_Email_Address__c = leadToConvert.Agent_Email_Address__c;
                opp.Lead_Entry_Source__c = leadToConvert.Lead_Entry_Source__c;
                opp.Partner_Owner__c = leadToConvert.Partner_Lead_Owner__c;
                opp.Partner_Account__c = leadToConvert.Partner_Account__c;
                opp.Partner_Contact__c = leadToConvert.Partner_Contact__c;
                opp.PartnerProgram__c = leadToConvert.Partner_Program__c;
                opp.Installation_Service_Provider__c = leadToConvert.Installation_Service_Provider__c; //Added for LTR-673 PS Deal Reg

            if (leadToConvert.Referrer_FName__c != null || leadToConvert.Referrer_LName__c != null ||
                leadToConvert.Referrer_Email__c != null) {

                opp.Description = ' Referrer FName: ' + (leadToConvert.Referrer_FName__c == null ? '' : leadToConvert.Referrer_FName__c)
                    + '\n Referrer LName: ' + (leadToConvert.Referrer_LName__c == null ? '' : leadToConvert.Referrer_LName__c)
                    + '\n Referrer Email: ' + (leadToConvert.Referrer_Email__c == null ? '' : leadToConvert.Referrer_Email__c)
                    + '\n\n' + (leadToConvert.Description == null ? '' : leadToConvert.Description);
            } else {
                opp.Description = leadToConvert.Description;
            }
            if (leadToConvert.Lead_Brand_Name__c == OpportunityHelper.BRAND_BT_BUSINESS) {
                opp.CurrencyIsoCode = 'GBP';
            }
            opp.Mitel_Data_Sharing__c=leadToConvert.Mitel_Data_Sharing__c;
            return opp;
        }

        public void mapOpportunityContactRole(Id accId, Id contactId, Id oppId, Lead_Qualification__c leadQualObj) {

            if (leadQualObj == null) {
                return;
            }

            if (leadQualObj.Decision_Maker_Partner__c == 'Details Below') {
                Contact contactObj = new Contact(
                    AccountId = accId,
                    FirstName = leadQualObj.Decision_Maker_First_Name__c,
                    LastName = leadQualObj.Decision_Maker_Last_Name__c,
                    Email = leadQualObj.Decision_Maker_Email__c,
                    Phone = leadQualObj.Decision_Maker_Phone__c,
                    Title = leadQualObj.Decision_Maker_Business_Title__c,
                    RecordTypeId = ContactHelper.RT_ID_VAR_VISIBLE
                );
                insert contactObj;

                if (contactObj != null) {
                    OpportunityContactRole oppContactRoleObj = new OpportunityContactRole(
                        OpportunityId = oppId,
                        ContactId = contactObj.Id,
                        Role = 'Decision Maker'
                    );
                    insert oppContactRoleObj;
                }
            } else if(leadQualObj.Decision_Maker_Partner__c == 'Same as Contact') {

                OpportunityContactRoleSelector selector = new OpportunityContactRoleSelector();

                List<Object> bindings = new List<Object>();
                bindings.add(oppId);
                bindings.add(contactId);

                List<OpportunityContactRole> oppContactRoleList = selector
                    .selectOCRForLeadConvert(bindings)
                    .executeQuery();

                OpportunityContactRole oppContactRoleObj = oppContactRoleList.isEmpty() ? null : oppContactRoleList.get(0);

                if (oppContactRoleObj != null) {
                    oppContactRoleObj.Role = 'Decision Maker';
                    oppContactRoleObj.isPrimary = true;
                    update oppContactRoleObj;
                }
            }
        }

        public void shareAccountToPartner(Id leadPartnerOwnerId, Id accountId) {
            shareAccountToPartner(leadPartnerOwnerId, new Set<String>{accountId});
        }

        public void shareAccountToPartner(Id leadPartnerOwnerId, Set<String> accountIdSet) {

            if (leadPartnerOwnerId == null && accountIdSet == null && !accountIdSet.isEmpty()) {
                return;
            }

            UserSelector usrSelector = new UserSelector();
            List<Object> bindings = new List<Object>();
            bindings.add(leadPartnerOwnerId);

            List<User> usrsList = (List<User>) usrSelector
                .selectUserByIdForLeadConvert(bindings)
                .executeQuery();

            User leadPartnerOwner = !usrsList.isEmpty() ? usrsList.get(0) : null;

            if (leadPartnerOwner == null) {
                return;
            }

            if (leadPartnerOwner.Contact.AccountId != null) {
                ShareUtil.shareAccountToPartner(leadPartnerOwnerId, accountIdSet);
            }
        }
    }

    public static List<AccountTeamMemberAssignment__c> filterAtmByState(String state, List<AccountTeamMemberAssignment__c> atmAssignList) {
        Map<String, List<AccountTeamMemberAssignment__c>> atmByState = new Map<String, List<AccountTeamMemberAssignment__c>>();

        for (AccountTeamMemberAssignment__c atmAssign : atmAssignList) {
            if (!atmByState.containsKey(atmAssign.State__c)) {
                atmByState.put(atmAssign.State__c, new List<AccountTeamMemberAssignment__c>());
            }
            atmByState.get(atmAssign.State__c).add(atmAssign);
        }

        return atmByState.get(atmByState.containsKey(state) ? state : null);
    }

    public static List<AccountTeamMember> accountTeamMemberAssignment(Id oppId) {

        List<Opportunity> oppList = (List<Opportunity>) new OpportunitySelector()
        .selectBillingOpportunity('Id = \'' + oppId + '\'')
        .executeQuery();

        List<AccountTeamMemberAssignment__c> atmAssignList = new List<AccountTeamMemberAssignment__c>();

        for(AccountTeamMemberAssignment__c atmAssign : AccountTeamMemberAssignment__c.getall().values()){
            List<String> acctBrandList = atmAssign.Brand__c.split(';');
            List<String> acctSegmentList = atmAssign.Segment__c.split(';');
            String oppCountry = String.isBlank(oppList[0].Account.ZI_Company_Country__c) ? oppList[0].Account.BillingCountry :  oppList[0].Account.ZI_Company_Country__c;
            if(atmAssign.Country__c == oppCountry && acctBrandList.contains(oppList[0].Brand_Name__c) && acctSegmentList.contains(oppList[0].Segment_Name__c)){
                atmAssignList.add(atmAssign);
            }
        }

        String oppState = String.isBlank(oppList[0].Account.ZI_Company_State__c) ? oppList[0].Account.BillingState :  oppList[0].Account.ZI_Company_State__c;
        atmAssignList = filterAtmByState(oppState, atmAssignList);

        if (atmAssignList == null || atmAssignList.isEmpty()) {
            return new List<AccountTeamMember>();
        }

        List<AccountTeamMember> atmInsList = new List<AccountTeamMember>();
        for(AccountTeamMemberAssignment__c atmAssign : atmAssignList){
            AccountTeamMember atm = new AccountTeamMember(
                AccountId = oppList[0].AccountId,
                TeamMemberRole =  atmAssign.Team_Role__c,
                UserId = atmAssign.UserId__c,
                AccountAccessLevel = atmAssign.AccountAccessLevel__c,
                CaseAccessLevel = atmAssign.CaseAccessLevel__c,
                ContactAccessLevel = atmAssign.ContactAccessLevel__c,
                OpportunityAccessLevel = atmAssign.OpportunityAccessLevel__c
            );
            atmInsList.add(atm);
        }
        return atmInsList;
    }
    
    @TestVisible
    private static void storeProfileRecordInPlatformCache(Id profileId){
        if(profileId == null){
            return;
        }
        Profile currentUserProfileRecord = (Profile) new ProfileSelector()
            .selectProfileById(new List<String>{ profileId })
            .executeQuery()
            .get(0);
        if(!PlatformCacheUtility.contains(PlatformCacheUtility.SESSION_CACHE,profileId,PlatformCacheUtility.CURRENT_USER_SESSION_DATA)){
            PlatformCacheUtility.put(PlatformCacheUtility.SESSION_CACHE,profileId,currentUserProfileRecord,PlatformCacheUtility.CURRENT_USER_SESSION_DATA);
        }
    }
    
    @TestVisible
    private static void storeUserRecordInPlatformCache(Id userId){
        if(userId == null){
            return;
        }
        User currentUserRecord = UserHelper.queryUsersWithSelectorForPlatformCache(new Set<Id>{userId})[0];
        if(!PlatformCacheUtility.contains(PlatformCacheUtility.SESSION_CACHE,userId,PlatformCacheUtility.CURRENT_USER_SESSION_DATA)){
            PlatformCacheUtility.put(PlatformCacheUtility.SESSION_CACHE,userId,currentUserRecord,PlatformCacheUtility.CURRENT_USER_SESSION_DATA);
        }
    }
}