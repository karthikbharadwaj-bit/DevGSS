public class OpportunityHelper {

    class CustomException extends Exception {}

    // Static maps
    public static Map<Id, List<Quote>> opptyToQuotesMapStatic = new Map<Id, List<Quote>>();

    public enum ValidationCategory {GSP_VALIDATION, PARTNER_VALIDATION, FULL_VALIDATION, CHANNEL_HARMONY_VALIDATION}

    // SObjectDescribes
    public static Schema.DescribeSObjectResult DESCRIBE {
        get {
            if(DESCRIBE == null) {
                DESCRIBE = Opportunity.SObjectType.getDescribe();
            }
            return DESCRIBE;
        }
        set;
    }

    public static final Map<String, SObjectField> FIELDS_MAP = DESCRIBE?.fields.getMap();

    // Record Types
    public static final String RT_NAME_NEW_SALES_OPPORTUNITY = 'New Sales Opportunity';
    public static final String RT_NAME_SALES_OPPORTUNITY = 'Sales Opportunity';
    public static final String RT_NAME_CANCEL_OPPORTUNITY = 'Cancel Opportunity';
    public static final String RT_NAME_SAVES_OPPORTUNITY = 'Saves Opportunity';
    public static final String RT_NAME_SAVES_DOWN_SELL_OPPORTUNITY = 'Saves Downsell';
    public static final String RT_NAME_VAR_OPPORTUNITY = 'VAR Opportunity';
    public static final String RT_NAME_NEW_VAR_OPPORTUNITY = 'New VAR Opportunity';
    public static final String RT_NAME_SALES_OPPORTUNITY_Z_QUOTE = 'Sales Opportunity zQuote';

    public static Map<String, Schema.RecordTypeInfo> RT_INFO_BY_NAME {
        get {
            if(RT_INFO_BY_NAME == null) {
                RT_INFO_BY_NAME = DESCRIBE.getRecordTypeInfosByName();
            }
            return RT_INFO_BY_NAME;
        }
        set;
    }

    public static Map<Id, Schema.RecordTypeInfo> RT_INFO_BY_ID {
        get {
            if(RT_INFO_BY_ID == null) {
                RT_INFO_BY_ID = DESCRIBE.getRecordTypeInfosById();
            }
            return RT_INFO_BY_ID;
        }
        set;
    }

    public static final Id RT_ID_NEW_SALES_OPPORTUNITY = RT_INFO_BY_NAME.get(RT_NAME_NEW_SALES_OPPORTUNITY).getRecordTypeId();
    public static final Id RT_ID_SALES_OPPORTUNITY = RT_INFO_BY_NAME.get(RT_NAME_SALES_OPPORTUNITY).getRecordTypeId();
    public static final Id RT_ID_CANCEL_OPPORTUNITY = RT_INFO_BY_NAME.get(RT_NAME_CANCEL_OPPORTUNITY).getRecordTypeId();
    public static final Id RT_ID_SAVES_OPPORTUNITY = RT_INFO_BY_NAME.get(RT_NAME_SAVES_OPPORTUNITY).getRecordTypeId();
    public static final Id RT_ID_SAVES_DOWN_SELL_OPPORTUNITY = RT_INFO_BY_NAME.get(RT_NAME_SAVES_DOWN_SELL_OPPORTUNITY).getRecordTypeId();
    public static final Id RT_ID_VAR_OPPORTUNITY = RT_INFO_BY_NAME.get(RT_NAME_VAR_OPPORTUNITY).getRecordTypeId();

    // Brand_Name__c
    public static final String BRAND_BT_BUSINESS = 'BT Business';
    public static final String BRAND_BT = 'BT';
    public static final String BRAND_TELUS = 'TELUS';
    public static final String BRAND_TELUS_BUSINESS_CONNECT = 'TELUS Business Connect';
    public static final String BRAND_ATTOFFICE = 'AT&T Office@Hand';
    public static final String BRAND_RINGCENTRAL_OFFICE_HAND_ATT = 'RingCentral Office@Hand from AT&T';
    public static final String BRAND_CLEARWIRE = 'Clearwire';

    public static final String BRAND_RCVERIZON = 'RingCentral with Verizon';
    public static final String BRAND_ATT = 'AT&T';
    public static final String BRAND_RINGCENTRAL = 'RingCentral';
    public static final String BRAND_RINGCENTRAL_EU = 'RingCentral EU';
    public static final String BRAND_RINGCENTRAL_UK = 'RingCentral UK';
    public static final String BRAND_RINGCENTRAL_AU = 'RingCentral AU';
    public static final String BRAND_RINGCENTRAL_CA = 'RingCentral Canada';
    public static final String BRAND_AVAYA = 'Avaya Cloud Office';
    public static final String BRAND_ATOS = 'Unify Office';
    public static final String BRAND_RAINBOW = 'Rainbow Office';
    public static final String BRAND_RC_FEDRAMP= 'RC FedRAMP';
    public static final String BRAND_RISE_AMERICA = 'Rise America';
    public static final String BRAND_RISE_INTERNATIONAL = 'Rise International';

    public static final String BI_ID_AMAZON = '62005';

    public static final String OPPORTUNITY_TYPE_EX_BUSINESS = 'Existing Business';
    public static final String OPPORTUNITY_TYPE_NEW_BUSINESS = 'New Business';
    public static final String OPPORTUNITY_TYPE_RENEWAL = 'Renewal';
    public static final String OPPORTUNITY_TYPE_SYNDICATED_NEW = 'Syndicated - New';

    public static final String USER_DIVISION_SALES_ENTERPRISE = 'Sales - Enterprise';

    public static final String CONTACT_ROLE_RC_PRIMARY = 'RC Primary Role';
    public static final String CONTACT_ROLE_SIGNATORY = 'Signatory';
    public static final String CONTACT_ROLE_ADMINISTRATOR = 'Administrator';

    public static final String CURRENCY_NAME_INR = 'INR';
    public static final String CURRENCY_NAME_TWN = 'TWD';

    // Tier_Name__c
    public static final String TIER_FAX ='Fax';
    public static final String TIER_OFFICE = Constants.CONST_OFFICE;
    public static final String TIER_EVENT = Constants.CONST_RC_EVENT;
    public static final String TIER_MEETINGS = 'Meetings';
    public static final String TIER_RC_MEETINGS = 'RC Meetings';
    public static final String TIER_BT_OFFICE = 'BT Office';
    public static final String TIER_TELUS_OFFICE = 'TELUS Office';
    public static final String TIER_CONTACT_CENTER = 'Contact Center';
    public static final String TIER_ENGAGE_DIGITAL_LEGACY = 'Engage Digital Legacy';
    public static final String TIER_ENGAGE_VOICE_LEGACY = 'Engage Voice Legacy';
    public static final String TIER_ENGAGE_DIGITAL_STANDALONE = 'Engage Digital Standalone';
    public static final String TIER_ENGAGE_VOICE_STANDALONE = 'Engage Voice Standalone';
    public static final String TIER_ENGAGE_UNIFIED = 'Engage Unified';
    public static final String TIER_ENGAGE_OMNICHANNEL = 'Engage';
    public static final String TIER_RC_CONTACT_CENTER = 'RingCentral Contact Center';
    public static final String TIER_RC_CONTACT_CENTER_LEGACY = 'RingCentral Contact Center Legacy';
    public static final String TIER_ENGAGE_SHORT = 'Engage';
    public static final String TIER_RC_CONTACT_SHORT = 'Contact Center';
    public static final String TIER_PROFESSIONAL_SERVICES = 'Professional Services';
    public static final Map<String, String> OPPORTUNITY_STAGES = new Map<String, String>{'7' =>'7. Closed Won'};

    // Tier Name for multiproduct UI
    public static final String TIER_MVP = 'MVP';
    public static final String TIER_ENGAGE_DIGITAL = 'Engage Digital';
    public static final String TIER_ENGAGE_VOICE = 'Engage Voice';
    public static final Map<String, String> shortTierNamesMap = new Map<String, String> {
        TIER_OFFICE => TIER_MVP,
        TIER_ENGAGE_DIGITAL_STANDALONE => TIER_ENGAGE_DIGITAL,
        TIER_ENGAGE_VOICE_STANDALONE => TIER_ENGAGE_VOICE,
        TIER_RC_CONTACT_CENTER => TIER_CONTACT_CENTER,
        TIER_MEETINGS => TIER_MEETINGS,
        TIER_FAX => TIER_FAX,
        TIER_PROFESSIONAL_SERVICES => TIER_PROFESSIONAL_SERVICES,
        TIER_EVENT => TIER_EVENT
    };

    public static final Set<String> ENGAGE_TIERS = new Set<String> {
        TIER_ENGAGE_DIGITAL_LEGACY,
        TIER_ENGAGE_VOICE_LEGACY,
        TIER_ENGAGE_DIGITAL_STANDALONE,
        TIER_ENGAGE_VOICE_STANDALONE,
        TIER_ENGAGE_UNIFIED,
        TIER_ENGAGE_OMNICHANNEL
    };

    public static final Set<String> ENGAGE_STANDALONE_TIERS = new Set<String> {
        TIER_ENGAGE_DIGITAL_STANDALONE,
        TIER_ENGAGE_VOICE_STANDALONE
    };

    //Store here some basic values
    public static final Integer NUMBER_OF_WEEKS_IN_THE_MONTH = 4;
    //Customer has approved opportunity close
    public static final String CONFIRMED = 'Confirmed';
    //Customer has rejected opportunity close
    public static final String REJECTED = 'Rejected';
    //Customer has not processed opportunity close
    public static final String PENDING = 'Pending';
    //Confirm and close flow will not be used
    public static final String OVERRIDE_STATUS = 'Override';
    // StageName
    public static final String STAGE_NAME_DOWNGRADED         = '0. Downgraded';
    public static final String STAGE_NAME_QUALIFY            = '1. Qualify';
    public static final String STAGE_NAME_PROBLEM            = '2. Problem';
    public static final String STAGE_NAME_SOLUTION           = '3. Solution';
    public static final String STAGE_NAME_PROOF              = '4. Proof';
    public static final String STAGE_NAME_AGREEMENT          = '5. Agreement';
    public static final String STAGE_NAME_ORDER              = '6. Order';
    public static final String STAGE_NAME_CLOSED_WON         = '7. Closed Won';
    public static final String STAGE_NAME_CLOSED_WON_PROSERV = '7.1. Closed Won for ProServ';
    public static final String STAGE_NAME_CLOSED_CHURNED     = '8. Closed Churned';
    public static final String STAGE_NAME_CLOSED_SAVED       = '9. Closed Saved';
    public static final String STAGE_NAME_CLOSED_WINBACK     = '10. Closed Winback';
    public static final String STAGE_NAME_PLANNING           = 'Planning';
    public static final String STAGE_NAME_RENEW              = '.5 Re-New';

    // Provision_By__c
    public static final String PROVISION_BY_RPA = 'RPA';
    public static final String PROVISION_BY_PROVISIONING_TEAM = 'Provisioning Team';
    public static final String PROVISION_BY_MANUAL = 'Manual';
    public static final String PROVISION_BY_SELF = 'Self-Provisioned';
    public static final String PROVISION_BY_RETENTION_TEAM = 'Retention Team';

    // Sub_Stage__c
    public static final String SUB_STAGE_CLOSED = 'Closed';
    public static final String SUB_STAGE_PENDING_PROVISIONING = 'Pending Provisioning';
    public static final String SUB_STAGE_AUTO_RENEWED = 'Auto-Renewed';

    //Deals_Desk_Stage__c
    public static final String DEALS_DESK_STAGE_PROVISIONING_ORDER_COMPLETE = 'Provisioning/Order Complete';

    //CurrencyIsoCode
    public static final String CURRENCY_ISO_CODE_USD = 'USD';

    //Sales_Model__c
    public static final String SALES_MODEL_DIRECT = 'Direct';

    //Downgrade_Reason_Opp__c
    public static final String DOWNGRADE_REASON_CC_MIGRATION = 'Sales Process / Relationship';
    public static final String COMPETITOR_LOST_CC_MIGRATION = 'No Competition';
    public static final String ADDITIONAL_DOWNGRADE_REASON_CC_MIGRATION = 'CC Migration';
    public static final String DOWNGRADE_REASON_MIGRATING_THIS_ACCOUNT_FROM_LEGACY_CC = 'Migrating this account from Legacy CC to CC in NGBS. You will need to create a new opportunity';

    public static final String STATUS_PAID = 'Paid';
    public static final String SUCCESS_MSG = 'SUCCESS';

    //PartnerProgram__c
    public static final String PARTNER_PROGRAM_CHANNEL_HARMONY = 'Channel Harmony';

    //Opportunity Creation Flow
    public static final String OPPORTUNITY_CREATION_FLOW_SOLVE_THEN_SELL = 'Solve Then Sell';

    public static final String VERIZON_CLOSE_ERROR = 'Verizon opportunity can be closed only with \''
        + STAGE_NAME_CLOSED_WON_PROSERV + '\' stage';

    public static final Set<String> RC_BRANDS = new Set<String>{
            BRAND_RINGCENTRAL,
            BRAND_RINGCENTRAL_EU,
            BRAND_RINGCENTRAL_UK,
            BRAND_RINGCENTRAL_AU,
            BRAND_RINGCENTRAL_CA
    };

    public static final Set<String> STAGE_NAMES_NO_FORECASTING_REPORTS = new Set<String>{
        STAGE_NAME_SOLUTION,
        STAGE_NAME_PROOF,
        STAGE_NAME_AGREEMENT,
        STAGE_NAME_ORDER,
        STAGE_NAME_CLOSED_WON
    };

    public static final Set<String> STAGE_NAMES_CLOSED = new Set<String>{
        STAGE_NAME_CLOSED_WON,
        STAGE_NAME_CLOSED_CHURNED,
        STAGE_NAME_CLOSED_SAVED,
        STAGE_NAME_CLOSED_WINBACK,
        STAGE_NAME_CLOSED_WON_PROSERV
    };

    public static final Set<String> STAGE_NAMES_OPEN = new Set<String> {
        STAGE_NAME_QUALIFY,
        STAGE_NAME_PROBLEM,
        STAGE_NAME_SOLUTION,
        STAGE_NAME_PROOF,
        STAGE_NAME_AGREEMENT,
        STAGE_NAME_ORDER,
        STAGE_NAME_RENEW
    };

    public static final Set<String> SKIP_PIPELINE_TOTALS_CALCULATION_FOR_BRANDS = new Set<String> {
        RingCentralHelper.BRAND_VERIZON
    };

    public static final Set<String> STAGE_NAMES_RECALCULATE_DISCRETION = new Set<String>{
        STAGE_NAME_CLOSED_WON,
        STAGE_NAME_ORDER,
        STAGE_NAME_AGREEMENT
    };

    public static final Set<String> RT_NAMES_FOR_CALCULATE_AMOUNTS_BASED_ON_CSV = new Set<String>{
        RT_NAME_SALES_OPPORTUNITY,
        RT_NAME_VAR_OPPORTUNITY,
        RT_NAME_SALES_OPPORTUNITY_Z_QUOTE,
        RT_NAME_NEW_SALES_OPPORTUNITY,
        RT_NAME_NEW_VAR_OPPORTUNITY
    };

    public static final Set<String> RISE_BRANDS = new Set<String> {
        BRAND_RISE_AMERICA,
        BRAND_RISE_INTERNATIONAL
    };

    public static final List<String> STAGE_NAMES_FOR_SHOWING_MANDATORY_FIELDS = new List<String> {
        STAGE_NAME_QUALIFY,
        STAGE_NAME_PROBLEM,
        STAGE_NAME_SOLUTION,
        STAGE_NAME_PROOF,
        STAGE_NAME_AGREEMENT,
        STAGE_NAME_ORDER
    };

    public static final Set<String> quoteFields = new Set<String> {
        'Id', 'AccountId', 'OpportunityId', 'Opportunity.Brand_Name__c', 'Opportunity.Name',
        'Opportunity.StageName', 'Opportunity.Parent_Order__c', 'Approved_Status__c',
        'TotalPrice', 'Monthly_Recurring_Revenue__c', 'ProServ_Status__c',
        'First_Year_Cost_of_Service__c', 'First_Year_Total_Cost_excluding_Taxes__c', 'Status',
        'Initial_Payment__c', 'sumProServOneTime__c', 'isPrimary__c', 'RecordTypeId',
        'RecordType.DeveloperName',
        'Upsell_Status__c', 'LastModifiedDate', 'RecordType.Name', 'MultipleShippingLocations__c',
        'Pricebook2.AllowedRecordType__c', 'Pricebook2.Service__c', 'Pricebook2.Plan__c', 'CurrentService__c',
        'CurrentService__r.ChargeTerm__c', 'CurrentService__r.EffectivePrice__c',
        'CurrentService__r.Price__c', 'Opportunity.Account.RC_Account_Status__c', 'PaymentMethod__c',
        'Brand__c', 'CurrencyIsoCode', 'Total_MRR_with_Taxes__c', 'Total_One_Time_with_Taxes__c'
    };

    public static final Set<String> qliFields = new Set<String> {
        'Product2.Feature__c', 'Product2.Charge_Term__c',
        'Product2.Dependent_on_Feature__c', 'Product2.Name',
        'Product2.Sub_Category__c', 'Product2.Family', 'TotalPrice', 'Quantity',
        'NewQuantity__c', 'TotalInitialPrice__c', 'Deactivated__c', 'Entitlement__c',
        'Entitlement__r.Active__c', 'Entitlement__r.Quantity__c',
        'Entitlement__r.Discount_Type__c', 'Entitlement__r.Discount__c',
        'Entitlement__r.EffectivePrice__c', 'Entitlement__r.ChargeTerm__c',
        'Entitlement__r.Product__r.Feature__c', 'Entitlement__r.Price__c',
        'Entitlement__r.Product__r.Charge_Term__c', 'Entitlement__r.DisplayQuantity__c',
        'Entitlement__r.Product__r.Family', 'Quote.Account.Id',
        'Quote.Account.Number_of_DL_s__c', 'Zero_Quantity__c', 'Package_Info_QLI__c',
        'Discount_number__c', 'Discount_type__c', 'EffectivePriceNew__c', 'UnitPrice',
        'PackageInfo__c', 'DiscountValueNew__c', 'Charge_Term__c', 'QuoteRecordType__c'
    };

    public static Set<String> alteredStages = new Set<String>();
    public static Set<String> closedStagesSet = new Set<String>();
    public static Map<String, Id> oppRecordTypeMap {
        get {
            if(oppRecordTypeMap == null) {
                oppRecordTypeMap = new Map<String, Id>();
                for(RecordType recordObj : [SELECT Id, Name FROM RecordType]) {
                    oppRecordTypeMap.put(recordObj.name, recordObj.Id);
                }
            }
            return oppRecordTypeMap;
        }
        set;
    }

    static {
        if(alteredStages.size() == 0) {
            // New Stages
            alteredStages.add('3. ActivePipe');
            alteredStages.add('1. Qualify');
            alteredStages.add('2. Problem');
            alteredStages.add('5. Proposal');
            alteredStages.add('3. Solution');
            alteredStages.add('4. Proof');   // add new stage.
            alteredStages.add('5. Agreement');
            alteredStages.add('6. Order');

            // Old Stages
            alteredStages.add('3. Qualified');
            alteredStages.add('4. Discovery');
            alteredStages.add('5. Proposal');
            alteredStages.add('6. Agreement');
            alteredStages.add('7. Order');
        }
        if(closedStagesSet.size() == 0) {
            // Old Stages
            closedStagesSet.add('4. Closed');
            closedStagesSet.add('8. Closed Won');
            //New Stages
            closedStagesSet.add(OpportunityHelper.STAGE_NAME_CLOSED_WON);
        }
    }

    public static String defaultOpportunityStage {
        get {
            if(String.isBlank(defaultOpportunityStage)) {
                Schema.DescribeFieldResult fieldDesc = Opportunity.StageName.getDescribe();
                List<Schema.PicklistEntry> stagepickValueList = fieldDesc.getPicklistValues();
                for(Schema.PicklistEntry stagepickValue : stagepickValueList) {
                    if(stagepickValue.isActive() && stagepickValue.isDefaultValue()) {
                        defaultOpportunityStage = stagepickValue.getLabel();
                        break;
                    } else if(stagepickValue.isActive() && stagepickValue.getLabel() == '3. ActivePipe') {
                        defaultOpportunityStage = stagepickValue.getLabel();
                        break;
                    } else if(stagepickValue.isActive() && (stagepickValue.getLabel() == '1. Qualify'
                                                            || stagepickValue.getLabel() == '3. Qualified')) {
                        defaultOpportunityStage = stagepickValue.getLabel();
                        break;
                    }
                }
                System.debug('### defaultOpportunityStage ###'+defaultOpportunityStage);
            }
            return defaultOpportunityStage;
        }
        set;
    }

    public static String closedStage {
        get {
            if(String.isBlank(closedStage)) {
                Schema.DescribeFieldResult fieldDesc = Opportunity.StageName.getDescribe();
                List<Schema.PicklistEntry> stagepickValueList = fieldDesc.getPicklistValues();
                for(Schema.PicklistEntry stagepickValue : stagepickValueList) {
                    if(stagepickValue.isActive() && stagepickValue.getLabel().containsIgnoreCase('Closed')) {
                        closedStage = stagepickValue.getLabel();
                        break;
                    }
                }
                System.debug('### closedStage ###'+ closedStage);
            }
            return closedStage;
        }
        set;
    }

    public static Id getOppRecordTypeMap (String recordType) {
        if(oppRecordTypeMap == null || oppRecordTypeMap.size() == 0) {
            oppRecordTypeMap = new Map<String, Id>();
            System.debug('### INSIDE MAP METHOD ###');
            for(RecordType recordObj : [SELECT Id, Name FROM RecordType]) {
                oppRecordTypeMap.put(recordObj.name, recordObj.Id);
            }
        } else {
            System.debug('### INSIDE MAP METHOD INITILIZED ###');
        }
        return oppRecordTypeMap.get(recordType);
    }

    public static Boolean isActiveOpp(String oppStage) {
        if(String.isBlank(oppStage)) {
            return false;
        }
        return OpportunityHelper.alteredStages.contains(oppStage);
    }

    public static Boolean isClosedOpp(String oppStage) {
        if(String.isBlank(oppStage)) {
            return false;
        }
        return OpportunityHelper.closedStagesSet.contains(oppStage);
    }

    public static Boolean isBTBusinessOpportunity(Opportunity opp) {
        return BRAND_BT_BUSINESS.equalsIgnoreCase(opp.Brand_Name__c);
    }

    public static Boolean isBTContactCenterOpportunity(Opportunity opp) {
        return isBTBusinessOpportunity(opp) && TIER_CONTACT_CENTER.equalsIgnoreCase(opp.Tier_Name__c);
    }

    public static Boolean isTelusOpportunity(Opportunity opp) {
        return opp != null && BRAND_TELUS_BUSINESS_CONNECT.equalsIgnoreCase(opp.Brand_Name__c);
    }

    public static List<String> getGSPBrands() {
        List<Brand_List__c> brandList = Brand_List__c.getall().values();
        List<String> GSPBranList = new List<String>();
        for (Brand_List__c GSPBrand : brandList) {
            if(GSPBrand.GSP_Brand__c == true) {
                GSPBranList.add(GSPBrand.Brand_Name__c);
            }
        }
        return GSPBranList;
    }

    public static Boolean isGSPBrand(Opportunity opp) {
        List<String> GSPBrandList = getGSPBrands();
        return GSPBrandList.contains(opp.Brand_Name__c);
    }

    public static map<string,List<string>> getApprovedBrandList(List<Opportunity> newOpportunityList) {
        map<string,List<string>> approvedBrandListMap = new map<string,List<string>>();
        try {
            if(UserInfo.getUserType() == 'PowerPartner') {
                User userObjDetails = [select Contact.Account.Permitted_Brands__c,Contact.Account.Partner_ID__c
                                            from User where id = :UserInfo.getUserId()];
                if(userObjDetails != null && userObjDetails.Contact.Account.Permitted_Brands__c != null &&
                    userObjDetails.Contact.Account.Partner_ID__c != null) {
                    approvedBrandListMap.put(userObjDetails.Contact.Account.Partner_ID__c,
                                                userObjDetails.Contact.Account.Permitted_Brands__c.split(';'));
                }
            } else {
                set<string> partnerIdSet = new set<string>();
                for(Opportunity oppObj: newOpportunityList) {
                    if(!string.isBlank(oppObj.Partner_ID__c)) {
                        partnerIdSet.add(oppObj.Partner_ID__c);
                    }
                }
                for(Account accObj : [select Permitted_Brands__c,Partner_ID__c from Account where RecordType.Name = 'Partner Account'
                                        and Partner_ID__c IN :partnerIdSet]) {
                    if(accObj.Permitted_Brands__c != null) {
                        approvedBrandListMap.put(accObj.Partner_ID__c,accObj.Permitted_Brands__c.split(';'));
                    }
                }
            }
        } catch(Exception ex) {}
        return approvedBrandListMap;
    }

    public static void checkPartnerOpportunityPermittedByBrand(List<Opportunity> newoppList, map<Id,Opportunity> oppoldMap,
                                        map<string,List<string>> approvedBrandListMap) {
        boolean isBrandPermitted = false;
        try {
            Schema.DescribeSObjectResult result = Opportunity.SObjectType.getDescribe();
            Map<ID,Schema.RecordTypeInfo> rtMapByName = result.getRecordTypeInfosById();
            if(newoppList != null ) { //&& newLeadList.size() == 1
                for(Opportunity newOppObj : newoppList) {
                    isBrandPermitted = false;
                    if(newOppObj.RecordTypeId != null && rtMapByName != null && rtMapByName.get(newOppObj.RecordTypeId).getName() == 'VAR Opportunity' &&
                        approvedBrandListMap != null && newOppObj.Partner_ID__c != null &&
                        approvedBrandListMap.get(newOppObj.Partner_ID__c) != null && newOppObj.Partner_ID__c != null &&
                        (oppoldMap == null || oppoldMap.get(newOppObj.id).Brand_Name__c != newOppObj.Brand_Name__c)) {
                        for(string strBrand : approvedBrandListMap.get(newOppObj.Partner_ID__c)) {
                            if(strBrand.trim() == newOppObj.Brand_Name__c) {
                                isBrandPermitted = true;
                                break;
                            }
                        }
                        if(isBrandPermitted == false) {
                            String address = Emails__c.getall().get('resellers') != null ? Emails__c.getall().get('resellers').Email_Address__c : 'your manager';
                            newOppObj.AddError('You are not permitted to sell this Brand. '+
                                                'Please contact <a style="font-size:12px;" '+
                                                'href=mailto:' + address + '>' + address + '</a> to gain access to this Brand.');
                        }
                    }
                }
            }
        } catch(Exception ex) {}
    }

    /**
    * Attach PDF to Opportunity when user clicks corresponding button
    * Adapted for Quoting wizard from ViewTemplateHelper.class
    */
    @AuraEnabled
    public static String attachPdfToOpportunity(Id opportunityId, Id quoteId, Id templateId) {
        return attachPdfToOpportunity(opportunityId, quoteId, templateId, null);
    }

    @AuraEnabled
    public static String attachPdfToOpportunity(Id opportunityId, Id quoteId, Id templateId, Map<String, String> templateParameters) {
        String attachmentId = '';

        try {
            RC_Quote_Template__c templateObj = [
                    SELECT Id, Name, LastModifiedDate, Sorting_Order__c, Description__c, Brand__c, Attachment_Name__c,
                            Opportunity_Record_Type__c, Type__c, Active__c, Version__c, Template_Engine__c
                    FROM RC_Quote_Template__c
                    WHERE Id = :templateId
            ];
            if (templateObj == null) {
                throw new CustomException('Template not found');
            }
            List<Quote> selectedQuotes = new QuoteSelector()
                .selectQuoteById(new List<Object>{quoteId})
                .executeQuery();

            if (selectedQuotes.isEmpty()) {
                throw new CustomException(QuoteHelper.QUOTE_NOT_FOUND);
            }
            Quote quoteObj = selectedQuotes[0];

            /* generate the pdf blob */
            Blob pdfBlob;
            PageReference pdfPage;

            if (templateObj.Template_Engine__c == TemplateEngine.PDF_ENGINE_2_0) {
                if (templateParameters != null && !templateParameters.isEmpty()) {
                    // generate template 2.0 with parameters
                     pdfBlob = PreviewPDFController.getPageContentViaPost(String.valueOf(quoteId), String.valueOf(templateId), templateParameters,templateObj.Name);
                } else {
                    // generate template 2.0 without parameters
                    pdfPage = Page.PreviewPDF;
                    pdfPage.getParameters().put('templateId', templateId);
                    pdfPage.getParameters().put('objectId', quoteId);
                    pdfPage.getParameters().put('templateName',templateObj.Name);
                }
            }

            if (pdfPage != null) {
                if(Test.isRunningTest()) {
                    pdfBlob = Blob.valueOf('Test_' + pdfPage.getUrl());
                } else {
                    pdfBlob = pdfPage.getContent();
                }
            }

            // Update Opportunity PDF Template version
            Opportunity oppObj = new Opportunity( Id = quoteObj.OpportunityId );
            if (!String.isBlank(templateObj.Version__c)) {
                oppObj.PDF_Template_Version__c = templateObj.Version__c;
            }
            update oppObj;

            String attachmentName = '';
            System.debug(templateObj.Attachment_Name__c);
            if (QuoteHelper.isProservQuote(quoteObj) || QuoteHelper.isCCProservQuote(quoteObj)) {
                Integer version = getLatestProServDocumentVersion(quoteObj);
                attachmentName = String.format(
                    Label.QW_ProServ_Pdf_Name,
                    new List<Object>{
                        QuoteHelper.isCCProservQuote(quoteObj) ? 'CC' : 'UC',
                        quoteObj.QuoteNumber,
                        quoteObj.Opportunity.Account.Name,
                        System.today().format(),
                        String.valueOf(++version)
                    }
                );
            } else if (String.isNotBlank(templateObj.Attachment_Name__c)){
                attachmentName = TemplateEngine.createFromString(quoteId,templateObj.Attachment_Name__c) + '.pdf';
            } else {
                String qType = String.isNotBlank(quoteObj.QuoteType__c) ? quoteObj.QuoteType__c : 'Quote';
                attachmentName = qType + ' For ' + quoteObj.Opportunity.Name + ' - ' + System.Today().format() + ' File.pdf';
            }

            System.debug(attachmentName);
            /* create the attachment against the quote */
            Attachment a = new Attachment(
                    parentId = oppObj.Id,
                    Name = attachmentName,
                    body = pdfBlob);

            /* insert the attachment */
            insert a;
            attachmentId = a.Id;

        } catch (DMLException e) {
            throw new CustomException(e.getDmlMessage(0));
        }
        return attachmentId;
    }

    @TestVisible
    private static Integer getLatestProServDocumentVersion(Quote quote) {

        Pattern pattern = Pattern.compile(
            'ProServ '
            + (QuoteHelper.isCCProservQuote(quote) ? 'CC' : 'UC')
            + ' Quote ' + quote.QuoteNumber
            + ' for ' + quote.Opportunity.Account.Name + ' [0-9{\\/.}]* - Version [0-9]*( \\{[\\s\\S]*\\})?.pdf'
        );

        Integer latestVersion = 0;
        for (Attachment attachment : [SELECT Id, Name FROM Attachment WHERE ParentId = :quote.OpportunityId AND Name LIKE '% - Version %' ]) {
            Integer lastAttachmentVersion;
            try{
                lastAttachmentVersion = Integer.valueOf(attachment.Name.substringBetween(' - Version ', ' {'));
            } catch(Exception ex) {
                lastAttachmentVersion = Integer.valueOf(attachment.Name.substringBetween(' - Version ', '.pdf'));
            }

            if (pattern.matcher(attachment.Name).matches()) {
                latestVersion = Math.max(
                    latestVersion,
                    Integer.valueOf(attachment.Name.substringBetween(' - Version ', '.pdf'))
                );
            }
        }
        return latestVersion;
    }

    //Calculates EstimatedProfessionalServices12Month__c from proserv quotes items revenues.
    //Cancelled proserv quotes are not taken into account.
    public static Map<Id, Decimal> calculateEstimatedProservServices(List<Quote> quotes, Schema.sObjectField field) {

        Map<Id, Decimal> oppIdValue = new Map<Id, Decimal>();

        if(!quotes.isEmpty()) {

            for(Quote q : quotes){
                oppIdValue.put(q.OpportunityId, 0);
            }

            for(Quote q : quotes){
                if(q.ProServ_Status__c != QuoteHelper.PROSERVSTATUS_CANCELLED){
                    for (QuoteLineItem qli : q.QuoteLineItems){
                        if (qli.Product2.Charge_Term__c == OpportunityTriggerHelperRefactored.PRODUCT_CHARGETERM_ONETIME){
                            Decimal value = (qli.get(field) != null ? (Decimal)qli.get(field) : 0);
                            oppIdValue.put(q.OpportunityId, oppIdValue.get(q.OpportunityId) + value);
                        }
                    }
                }
            }
        }
        return oppIdValue;
    }

    public class QuotesWrapper {
        public List<Quote> allOpptyQuotes;
        public List<Quote> quotes;
        public Quote salesPrimaryQuote;
        public Quote proServQuote;
        public Quote ccProServQuote;
        public Quote ccQuote;
        public Quote pocQuote;
        public Quote primaryQuote;
        public QuotesWrapper(List<Quote> allOpptyQuotes, Opportunity opp) {
            this.allOpptyQuotes = allOpptyQuotes;

            quotes = QuoteHelper.filterBillingQuotes(allOpptyQuotes, opp);
            salesPrimaryQuote = QuoteHelper.getPrimaryQuote(quotes, opp.Is_Billing_Opportunity__c);
            proServQuote = QuoteHelper.getProServQuote(allOpptyQuotes);
            ccProServQuote = QuoteHelper.getCCProServQuote(allOpptyQuotes);
            ccQuote = QuoteHelper.getCCQuote(quotes);
            pocQuote = QuoteHelper.getPOCQuote(quotes, opp.Is_Billing_Opportunity__c);

            if (salesPrimaryQuote != null) {
                primaryQuote = salesPrimaryQuote;
            } else if (pocQuote != null) {
                primaryQuote = pocQuote;
            }
        }
    }

    /**
     * Documentation:
     * https://aquiva.atlassian.net/wiki/spaces/RC/pages/164593680/Close
     *
     * [validateOpportunityOnClose description]
     * @param  opportunity       [Opportunity to validate]
     * @param  qtsWrapper        [Quotes related to Opportunity]
     * @param  phases            [Phases related to Quotes]
     * @param  areaCodeLineItems [List of primary quote area code line items]
     * @param  userProfileName   [User name who closes the opportunity]
     * @param  tierTypeSetting   [TierTypeSetting__c custom setting]
     * @param  optyQuantity      [Amount of not closed and downgraded opportunities under account]
     * @return                   [Validation messages. Empty if no errors]
     */
    public static Response validateOpportunityOnClose(
            Opportunity opportunity,
            QuotesWrapper qtsWrapper,
            List<Phase__c> phases,
            List<Area_Code_Line_Item__c> areaCodeLineItems,
            String userProfileName,
            List<TierTypeSetting__c> tierTypeSetting,
            Integer optyQuantity,
            Map<Id, Cost_Center_Line_Item__c> costCenterLineItems,
            AccountContactRole accRole,
            Account masterAccount,
            Map<String, List<Approval__c>> approvals,
            List<Promotion__c> promoList,
            String paymentMethod,
            List<PartnerOperationsLog__c> partnerOperationsLogs,
            BillingWrappers.NGBSAccount accountInfo
    ){
        String PROFESSIONAL_SERVICE = 'Professional Services';
        Response resp = new Response();
        Boolean isMPUB = AccountHelper.isMPUBAccount(opportunity.Account);
        Package__c billingPackage;

        if (doesUserProfileHaveGPAValidation()
         && (opportunity.AccountId != null && opportunity.Account.GPA_Account__c)
         && opportunity.Type == OPPORTUNITY_TYPE_NEW_BUSINESS) {
            String result = GPOContractValidation(opportunity);
            if (!result.equalsIgnorecase(SUCCESS_MSG)) {
                resp.addMessage(
                    Label.Opportunity_Error_OnClose_Unable_to_close_record_text,
                    result,
                    Response.SEVERITY_ERROR
                );
                return resp;
            }
        }

        if (isTelusOfficePlaceholderOppty(opportunity)) {
            resp.setData(
                'closeWizardURL',
                selectCloseWizard(opportunity, null, false, 1, false)
            );
            return resp;
        }

        if (BizMergeBrandExclusion(opportunity)) {
            resp.setData(
                'closeWizardURL',
                selectCloseWizard(opportunity, null, false, 1, false)
            );
            return resp;
        }

        if (BooleanHelper.toBoolean(engageOppIdToTerminationStatus(new List<Opportunity>{opportunity})?.get(opportunity.Id))) {
            return resp;
        }

        List<Quote> allOpptyQuotes = qtsWrapper.allOpptyQuotes;
        List<Quote> quotes = qtsWrapper.quotes;
        Quote salesPrimaryQuote = qtsWrapper.salesPrimaryQuote;
        Quote proServQuote = qtsWrapper.proServQuote;
        Quote ccProServQuote = qtsWrapper.ccProServQuote;
        Quote ccQuote = qtsWrapper.ccQuote;
        Quote primaryQuote = qtsWrapper.primaryQuote;
        List<QuoteHelper.PackageInfo> pInfos = QuoteHelper.getPackageInfo(primaryQuote?.Package_Info__c);
        List<String> servicesOnPrimaryQuote = new List<String>();
        for (QuoteHelper.PackageInfo pi : pInfos) {
            servicesOnPrimaryQuote.add(pi.ProductName);
        }

        Boolean hasNGBSProServ = servicesOnPrimaryQuote.contains(QuoteHelper.NGBS_PROFESSIONAL_SERVICES_PRODUCT);
        // getLastApprovedInvoiceApproval in ApprovedInvoiceValidator retrieves last approved approval where all service fields are < 0
        // on MPUB it may have some service fields > 0
        // this boolean should cover both cases
        Boolean isSingleQuote = servicesOnPrimaryQuote?.size() == 1 && String.isBlank(primaryQuote.MasterQuote__c);

        Boolean isBillingOpp = opportunity.Is_Billing_Opportunity__c;

        Boolean isProServQuotesNotCancelled = QuoteHelper.hasNonCancelledProServ(new List<Quote>{primaryQuote, proServQuote, ccProServQuote});
        // TODO refactor after GSP Partner Setup CS is complemented with CC availability info
        Boolean isGSPWithCC = isBTBusinessOpportunity(opportunity) || isTelusOpportunity(opportunity);
        Boolean isGSPWithoutCC = !isGSPWithCC && SettingsService.onlyProServQuotesAvailable(opportunity);
        Boolean isGSP = isGSPWithCC || isGSPWithoutCC;
        Boolean isGSPBrandOpp = OpportunityHelper.isGSPBrand(opportunity);
        Boolean isInvoice = QuoteHelper.isInvoice(paymentMethod);

        if (QuoteHelper.isQuoteDeselected(primaryQuote)) {
            return resp;
        }

        if (primaryQuote != null && !isBillingOpp) {
            List<Package__c> packages = new PackageSelector()
                .selectPackagesForNewReferences(new List<Object> {new Set<Id>{primaryQuote.AccountId}})
                .executeQuery();
            Map <Id, Package__c> packageToProcessMap = PackageHelper.filterPackagesByService(packages, QuoteHelper.NGBS_OFFICE_PRODUCT);
            billingPackage = packageToProcessMap.get(primaryQuote.AccountId);
        }

        Approval__c ddApproval = ApprovalHelper.getLastApprovedApproval(opportunity.AccountId, ApprovalHelper.RT_ID_DIRECT_DEBIT_REQUEST);

        Feature_Toggle__c featureToggle = Feature_Toggle__c.getInstance();
        /* Common validations for all opportunities and quote types starts here */
        Validator noQuotesValidator = new OpportunityValidator.NoQuotesValidator('CRITICAL', quotes, opportunity);
        Validator primQtNotApprovedValidator =
            new QuoteValidator.PrimaryQuoteNotApprovedValidator(primaryQuote, opportunity);
        Validator ccQuoteNotApprovedValidator = new QuoteValidator.CCQuoteNotApprovedValidator(ccQuote, opportunity);
        Validator noQuoteLineItemsValidator = new QuoteValidator.NoQuoteLineItemsValidator(primaryQuote, opportunity);
        Validator shippingTabPermissionValidator = new QuoteValidator.QuantityShippingTabPermissionValidator(primaryQuote, new List<QuoteLineItem>());
        Validator shippingQuantityValidator = new QuoteValidator.QuantityShippingValidator(primaryQuote, new List<QuoteLineItem>(), false, isProServQuotesNotCancelled);
        Validator deviceAvailabilityBackorderedValidator = new QuoteValidator.DeviceAvailabilityBackorderValidator(primaryQuote);
        Validator deviceAvailabilityOutOfStockValidator = new QuoteValidator.DeviceAvailabilityOutOfStockValidator(primaryQuote);
        Validator deviceAvailabilityHiddenDiscontinuedValidator = new QuoteValidator.DeviceAvailabilityHiddenDiscontinuedValidator(primaryQuote);
        Validator costCenterShippingQuantityValidator = new QuoteValidator.ShippingCostCenterValidator(primaryQuote, new List<QuoteLineItem>(), new List<Cost_Center__c>(), isProServQuotesNotCancelled);
        Validator quoteIsInvalidValidator = new QuoteValidator.QuoteIsInvalidValidator('CRITICAL', primaryQuote);
        Validator billingAddresValidator = new OpportunityValidator.BillingAddressValidator(opportunity);
        Validator psFieldsValidation = new QuoteValidator.PSFieldsValidation(primaryQuote, opportunity, hasNGBSProServ);

        /* Validations for non billing opportunitites/quotes starts here */
        Validator areaCodeLineItemValidator =
            new QuoteValidator.AreaCodeLineItemValidator(primaryQuote, areaCodeLineItems);
        Validator changeOrderEmptyPhasesValidator =
            new QuoteValidator.ChangeOrderEmptyPhasesValidator(allOpptyQuotes, opportunity, phases);
        Validator changeOrderQliAssignementValidator = new QuoteValidator.ChangeOrderQliAssignementValidator(
            allOpptyQuotes, opportunity, phases, proServQuote, ccProServQuote
        );
        Validator extendedEnterpriseSupportProductValidator =
            new QuoteValidator.ExtendedEnterpriseSupportProductValidator(primaryQuote);
        Validator emptyProvisionNotesValidator =
            new QuoteValidator.EmptyProvisionNotesValidator(primaryQuote, opportunity);
        Validator activeAgreementValidator = new QuoteValidator.ActiveAgreementValidator(primaryQuote, opportunity);
        Validator proservSyncRequiredValidator =
            new QuoteValidator.ProservSyncRequiredValidator (primaryQuote, proservQuote);
        Validator proservSoldRequiredValidator =
            new QuoteValidator.ProservSoldRequiredValidator(primaryQuote, proservQuote);
        Validator activeServicePlanValidator =
            new QuoteValidator.ActiveServicePlanValidator(primaryQuote, tierTypeSetting, userProfileName, billingPackage);
        Validator activeAgreementForContactCenterValidator =
            new QuoteValidator.ActiveAgreementForContactCenterValidator(primaryQuote, opportunity, allOpptyQuotes);
        Validator ccProservEngagementValidator =
            new QuoteValidator.CCProservEngagementValidator(primaryQuote, ccProservQuote);
        Validator ccProservSyncRequiredValidator =
            new QuoteValidator.CCProservSyncRequiredValidator(primaryQuote, ccProservQuote);
        Validator ccProservSoldRequiredValidator =
            new QuoteValidator.CCProservSoldRequiredValidator(primaryQuote, ccProservQuote);
        Validator rentalPhoneValidator = new QuoteValidator.RentalPhoneValidator(primaryQuote);
        Validator phonesAndDlsValidator = new QuoteValidator.PhonesAndDlsValidator(primaryQuote, opportunity);
        /* Validations for billing opportunitites/quotes starts here */
        Validator costCenterAssignementValidator =
            new QuoteValidator.CostCenterAssignementValidator(primaryQuote, costCenterLineItems);
        Validator quoteErrorsValidator = new QuoteValidator.QuoteErrorsValidator(primaryQuote);
        Validator billingPackageExpirationValidator =
            new QuoteValidator.BillingPackageExpirationValidator('CRITICAL', primaryQuote, QuoteValidator.BillingProcessType.CLOSE_ON_OPPORTUNITY);
        Validator areaCodesAssignementValidator =
            new QuoteValidator.AreaCodesAssignementValidator(primaryQuote, opportunity, areaCodeLineItems);
        Validator proservSyncAndSoldValidator = new QuoteValidator.ProservSyncAndSoldValidator(proServQuote);
        Validator ccProservSyncAndSoldValidator = new QuoteValidator.ProservSyncAndSoldValidator(ccProServQuote);
        Validator productReachedSalesEndDateValidator =
            new QuoteValidator.ProductReachedSalesEndDateValidator(primaryQuote);
        Validator billingActiveAgreementValidator =
            new OpportunityValidator.BillingActiveAgreementValidator(primaryQuote, opportunity);
        Validator swissVatIdValidator =
            new OpportunityValidator.SwissVatIdValidator(opportunity, approvals.get('vatIdExempt'));
        Validator ccQuoteRequiresCCProservValidator =
            new QuoteValidator.CCQuoteRequiresCCProservValidator(ccQuote, ccProServQuote);
        Validator ccProservQuoteValidator = new QuoteValidator.CCProservQuoteValidator(ccProServQuote);
        Validator rentalNGBSInCartValidator = new QuoteValidator.RentalNGBSInCartValidator(primaryQuote);
        Validator masterAccountValidator =
            new AccountValidator.MasterAccountValidator(opportunity, accRole, masterAccount, accountInfo);
        Validator expiredPromotionValidator = new QuoteValidator.ExpiredPromoValidator(promoList);
        Set<String> extServices = new Set<String>(); 
        
        if (isMPUB && accountInfo != null && accountInfo.packages != null) { 
            for (BillingWrappers.NGBSAccountPackage accPackage : accountInfo.packages){
                if (accPackage.product != null) {
                    extServices.add(accPackage.product);
                }
            }
        }
        Validator approvedInvoiceValidator =
            new AccountValidator.ApprovedInvoiceValidator(
                new AccountValidator.ApprovedInvoiceValidatorParams(
                    opportunity,
                    approvals.get('invoice'),
                    paymentMethod,
                    true,
                    partnerOperationsLogs,
                    isMPUB,
                    servicesOnPrimaryQuote,
                    isSingleQuote && servicesOnPrimaryQuote[0] != PROFESSIONAL_SERVICE,
                    extServices
                )
            ).enable(isInvoice);
        Validator directDebitLimitValidation =
            new ApprovalValidator.DirectDebitLimitValidation(primaryQuote, paymentMethod, ApprovalValidator.CLOSE, ddApproval);
        Validator directDebitThresholdValidator =
            new ApprovalValidator.DirectDebitThresholdValidator(primaryQuote, ddApproval != null, paymentMethod, ApprovalValidator.CLOSE);
        Validator kycApproveValidator = new AccountValidator.KYCApprovalValidatorOnOpportunityClose(approvals.get('KYC'));
        Validator taiwanVatIdValidator =
            new OpportunityValidator.TaiwanVatIdValidator(
                new OpportunityValidator.TaiwanVatandTaxValidatorParams(
                    opportunity,
                    approvals.get('taxexempt'),
                    true
                )
            );
        Validator approvedInvoiceOnBehalfValidator =
            new AccountValidator.ApprovedInvoiceOnBehalfValidator(opportunity, true, partnerOperationsLogs);
        Validator approvedInvoiceWholesaleValidator =
            new AccountValidator.ApprovedInvoiceWholesaleValidator(opportunity, true, partnerOperationsLogs);
        Validator masterAccountActiveAgreementValidator =
            new AccountValidator.MasterAccountActiveAgreementValidator(masterAccount, true);
        Validator officeMasterAccountValidator =
            new AccountValidator.OfficeMasterAccountValidator(opportunity, masterAccount, accountInfo, true);
        Validator masterAccountContractValidator =
            new AccountValidator.MasterAccountContractValidator(opportunity, masterAccount);
        Validator noProservQuote = new QuoteValidator.NoProservQuote(proservQuote);
        Validator noProservOrCCProservQuote = new QuoteValidator.NoProservQuote(
            ccProServQuote != null ? ccProServQuote : proservQuote
        );
        Validator noProservOrCCProServQuoteLineItems = new QuoteValidator.NoProservOrCCProServQuoteLineItems(proServQuote, ccProServQuote, opportunity);
        Validator proServOrCCProServNotSoldOrCancelled = new QuoteValidator.ProServOrCCProServNotSoldOrCancelled(
            proservQuote, ccProServQuote
        );
        Validator proServQliToPhaseValidator = new QuoteValidator.ProServQliToPhaseValidator(servicesOnPrimaryQuote, primaryQuote, isSingleQuote);
        Validator rcEventsAdminRoleValidator = new OpportunityValidator.RCEventsAdminRoleValidator(Validator.SEVERITY_CRITICAL, opportunity, primaryQuote);

        /* Common */
        List<Validator> common = new List<Validator> {
            noQuotesValidator,
            approvedInvoiceOnBehalfValidator,
            approvedInvoiceWholesaleValidator,
            directDebitLimitValidation,
            primQtNotApprovedValidator,
            noQuoteLineItemsValidator,
            shippingTabPermissionValidator,
            shippingQuantityValidator,
            costCenterShippingQuantityValidator,
            billingAddresValidator,
            masterAccountActiveAgreementValidator,
            proServQliToPhaseValidator
        };

        /* Non billing specific chain */
        List<Validator> nonBilling = new List<Validator> {
            quoteIsInvalidValidator,
            ccQuoteNotApprovedValidator,
            areaCodeLineItemValidator,
            changeOrderEmptyPhasesValidator,
            changeOrderQliAssignementValidator,
            extendedEnterpriseSupportProductValidator,
            emptyProvisionNotesValidator,
            activeAgreementValidator,
            proservSyncRequiredValidator,
            proservSoldRequiredValidator,
            activeServicePlanValidator,
            activeAgreementForContactCenterValidator,
            ccProservEngagementValidator,
            ccProservSyncRequiredValidator,
            ccProservSoldRequiredValidator,
            rentalPhoneValidator,
            phonesAndDlsValidator,
            ccQuoteRequiresCCProservValidator
        };

        List<Validator> directDebit = new List<Validator> {
            directDebitThresholdValidator,
            directDebitLimitValidation
        };

        /* Engage and CC service specific chain */
        List<Validator> engage = new List<Validator>();

        /* POC specific chain */
        List<Validator> poc = new List<Validator> {
            quoteErrorsValidator,
            areaCodesAssignementValidator,
            billingPackageExpirationValidator
        };

        /* Billing specific chain */
        List<Validator> billing = new List<Validator> {
            quoteIsInvalidValidator,
            approvedInvoiceValidator,
            shippingTabPermissionValidator,
            shippingQuantityValidator,
            costCenterShippingQuantityValidator,
            quoteErrorsValidator,
            expiredPromotionValidator,
            costCenterAssignementValidator,
            billingPackageExpirationValidator,
            ccProservSyncAndSoldValidator,
            ccProservQuoteValidator,
            productReachedSalesEndDateValidator,
            billingActiveAgreementValidator,
            swissVatIdValidator,
            rentalNGBSInCartValidator,
            deviceAvailabilityHiddenDiscontinuedValidator,
            deviceAvailabilityBackorderedValidator,
            deviceAvailabilityOutOfStockValidator,
            rcEventsAdminRoleValidator
        };

        /* Office service specific chain */
        List<Validator> office = new List<Validator> {
            areaCodesAssignementValidator,
            proservSyncAndSoldValidator,
            ccQuoteRequiresCCProservValidator
        };

        /* India Office chain */
        List<Validator> indiaOffice = new List<Validator> {
            kycApproveValidator
        };

        /* Taiwan Vat and Tax Exempt Section */
        List<Validator> taiwanVAT = new List<Validator> {
            taiwanVatIdValidator
        };

        List<Validator> gspWithoutCC = new List<Validator> {
            noProservQuote.enable(!isGSPBrandOpp),
            noProservOrCCProServQuoteLineItems, // proservSyncAndSoldValidator inapplicable because GSPs don't sync
            proServOrCCProServNotSoldOrCancelled,
            ccQuoteRequiresCCProservValidator
        };

        List<Validator> gspWithCC = new List<Validator> {
            noProservOrCCProservQuote.enable(!isGSPBrandOpp),
            noProservOrCCProServQuoteLineItems,
            proServOrCCProServNotSoldOrCancelled,
            ccQuoteRequiresCCProservValidator
        };

        if (QuoteHelper.isProServService(primaryQuote)) {
            common.add(psFieldsValidation);
        }

        HelperUtils.BaseValidator validator = new HelperUtils.BaseValidator();

        if (isGSPWithoutCC) {
            validator.setValidators(gspWithoutCC);
        } else if (isGSPWithCC) {
            validator.setValidators(gspWithCC);
        } else {
            validator.setValidators(common);
        }
        Boolean isMultiproductOpp = opportunity.isMultiproductTechnicalOpportunity__c;
        Boolean isNewBilling = QuoteHelper.isNewBillingQuote(primaryQuote);
        Boolean isEngage = QuoteHelper.isEngageService(primaryQuote);
        Boolean isPOC = QuoteHelper.isPOCQuote(primaryQuote);
        Boolean isSingapore = QuoteHelper.isSingapore(primaryQuote);
        Boolean isDirectDebit = QuoteHelper.isDirectDebit(primaryQuote) || QuoteHelper.isDirectDebit(paymentMethod);
        Boolean isIndiaOffice = isIndia(opportunity);
        Boolean isTaiwanVat = isTaiwan(opportunity);
        Boolean isContactCenter = QuoteHelper.isCCService(primaryQuote);
        Boolean isVerizon = isVerizon(opportunity);
        Boolean isbizmergebrandexclusion = BizMergeBrandExclusion(opportunity);
        Boolean isRise = isRiseBrand(opportunity);
        Boolean isOfficeMPUB = isMPUB ? QuoteHelper.isMultiProductQuoteHasServicePackage(primaryQuote, TIER_OFFICE) : false;
        Boolean isContactCenterMPUB = isMPUB ? QuoteHelper.isMultiProductQuoteHasServicePackage(primaryQuote, TIER_RC_CONTACT_CENTER) : false;
        Boolean isEngageMPUB = isMPUB ? QuoteHelper.isMultiProductQuoteHasServicePackage(primaryQuote, new List<String>(ENGAGE_TIERS)) : false;

        if (!isMultiproductOpp) {
            engage.add(masterAccountContractValidator);
            engage.add(officeMasterAccountValidator);
            billing.add(masterAccountValidator);
        }

        if (!isBillingOpp && !isGSP) {
            /* Non billing specific chain */
            validator.setValidators(nonBilling);
        }

        if (isBillingOpp && isNewBilling && !isVerizon && !isRise && !isSingapore) {
            /* Billing specific chain */
            validator.setValidators(billing);

            if (isTaiwanVat) {
                /* Taiwan Vat and Tax Exempt Validation */
                validator.setValidators(taiwanVAT);
            } else if (isEngage || isContactCenter || isContactCenterMPUB || isEngageMPUB) {
                /* Engage and CC service specific chain */
                if (!engage.isEmpty()) {
                    validator.setValidators(engage);
                }
                if (isOfficeMPUB) {
                    validator.setValidators(office);
                }
            } else {
                /* Office service specific chain */
                validator.setValidators(office);
                if (isIndiaOffice) {
                    /* Office india service specific chain */
                    validator.setValidators(indiaOffice);
                }
            }

            if (isDirectDebit) {
                validator.setValidators(directDebit);
            }
        }

        if (isBillingOpp && isPOC && !isVerizon) {
            /* POC specific chain */
            validator.setValidators(poc);
        }

        resp = validator.validate(resp);

        /* GenerateOrdersPrompt validation */
        if (primaryQuote != null && !QuoteHelper.isPOCQuote(primaryQuote) &&
            resp.messages.isEmpty() && featureToggle.AutogenerateOrders__c
            && !isVerizon && !isRise
        ) {
            if (isCCPhoneNumbersRequired(opportunity, quotes, new List<Entitlement__c>()) && resp.messages.isEmpty()) {
                resp.setData('isCCPhoneNumbersRequired', true);
                resp.setData('RCAccountNumber', opportunity.Account.RC_Account_Number__c);
            }
        }

        /* Engage Legal Prompt validation */
        Response elValidationResponse = ApexWebServices.validateELOpportunity(opportunity.Id, 'Close');
        if (!elValidationResponse.messages.isEmpty()) {
            resp.addMessage(
                Label.Opportunity_Error_OnClose_Unable_to_close_record_text,
                elValidationResponse.messages[0].message,
                elValidationResponse.messages[0].severity
            );
        } else if (elValidationResponse.messages.isEmpty()
                && resp.messages.isEmpty()
                && !elValidationResponse.data.isEmpty()) {
            Map<String, Object> data = elValidationResponse.data;
            resp.setData('isShowRecallELPrompt', true);
            resp.setData('approvalId', data.get('approvalId'));
        }

        /* Redirect to close wizard */
        if (resp.messages.isEmpty() && !isShowPrompt(resp.data)) {
            if (isVerizon || isbizmergebrandexclusion) {
                OpportunityHelper.closeOpportunity(opportunity);
                return resp;
            }


            if (
                featureToggle.ModifiedCloseOpportunityFlow__c
                && primaryQuote != null
                && (
                    BRAND_BT_BUSINESS.equalsIgnoreCase(opportunity.Brand_Name__c)
                    || RingCentralHelper.BRAND_TELUS_BUSINESS_CONNECT.equalsIgnoreCase(opportunity.Brand_Name__c)
                    || RingCentralHelper.BRAND_VODAFONE.equalsIgnoreCase(opportunity.Brand_Name__c)
                )
            ) {
                resetConfirmAndCloseFlag(opportunity, primaryQuote);
            }

            if (featureToggle.EnableWizardFreeOppClose__c != true) {
                Boolean isRenewalWithoutChanges = OpportunityHelper.isRenewalOptyWithoutChanges(opportunity, allOpptyQuotes);
                resp.setData('closeWizardURL',
                    selectCloseWizard(opportunity, primaryQuote, isRenewalWithoutChanges, optyQuantity, isMPUB && !isSingleQuote));
            } else {
                String brand = primaryQuote.Pricebook2.Brand__c != null
                    ? primaryQuote.Pricebook2.Brand__r.Name.toLowerCase()
                    : '';
                String closeValidationMessage = validateAndCloseOppWithoutWizard(opportunity, brand, ccQuote, salesPrimaryQuote);
                if (!String.isEmpty(closeValidationMessage)) {
                    resp.addMessage(closeValidationMessage,
                    closeValidationMessage,
                    'Please Complete Necessary Fields');
                }
                resp.setData('closeValidationMessage', closeValidationMessage);
                resp.setData('closeValidationMessage', closeValidationMessage);
            }
        }
        return resp;
    }

    public static String validateAndCloseOppWithoutWizard(Opportunity opp, String brand, Quote ccQuote, Quote ucaasQuote) {
        String validationMessage = validateCloseWithoutWizard(opp, ccQuote, ucaasQuote);
        if (!String.isEmpty(validationMessage)) {
            return validationMessage;
        }
        //Still leveraging the form submission method used in old close wizard
        Map<String,String> submissionParams = new Map<String,String>{
            'isInline' => 'false',
            'wType' => 'close',
            'Id' => opp.Id,
            'brandName' => brand
        };
        DowngradeWizardController.submitForm(submissionParams);
        return '';
    }

    public static String validateCloseWithoutWizard(Opportunity opp, Quote ccQuote, Quote ucaasQuote) {
        List<String> requiredFields = new List<String>();

        if (opp.CW_Primary_Win_Reason__c == null) {
            requiredFields.add('Primary Win Reason');
        } else if (opp.CW_Primary_Win_Reason__c == 'Awards/Good Reviews' &&  opp.CW_Win_Reason_Awards__c == null) {
            requiredFields.add('Win Reason Awards');
        } else if (opp.CW_Primary_Win_Reason__c == 'Annualized Savings' && opp.CW_Win_Reason_Savings__c == null) {
            requiredFields.add('Annualized Savings');
        } else if (opp.CW_Primary_Win_Reason__c == 'Features' && opp.CW_Win_Reason_Features__c == null) {
            requiredFields.add('Required Features');
        } else if (opp.CW_Primary_Win_Reason__c == 'Features' && opp.CW_Win_Reason_Features__c == 'Integrations' && opp.CW_Win_Reason_Integrations__c == null) {
            requiredFields.add('Integrations');
        }

        if (opp.UCaaS_Competitor_s__c == null && opp.UCaaS_Incumbent_s__c == null && opp.CC_Competitor_s__c == null && opp.CC_Incumbent_s__c == null){
            requiredFields.add('UCaaS/CC Competitive Fields');
        }

        return String.join(requiredFields,', ');
    }

    public static Boolean isNotSuitableMasterAcc(AccountContactRole childAccountRole, Account masterAccount) {
        Boolean result = false;
        /* Master account is not specified */
        if (masterAccount == null) {
            return result;
        }

        return isContactsMisMatch(childAccountRole, masterAccount);
    }

    private static Boolean isContactsMisMatch(AccountContactRole engageAccountRole, Account masterAccount) {
        Boolean missSameOfficeContact = true;

        if (engageAccountRole == null) {
            return missSameOfficeContact;
        }

        Boolean isSearchAmongContacts =
            (FeatureManagement.checkPermission(CustomPermissionHelper.PERMISSION_EXPANDED_ENGAGE_BINDING));

        if (isSearchAmongContacts) {
            for (AccountContactRole acr : masterAccount.AccountContactRoles) {
                if (engageAccountRole.Contact.LastName == acr.Contact.LastName &&
                    engageAccountRole.Contact.Phone == acr.Contact.Phone) {

                    missSameOfficeContact = false;
                    break;
                }
            }
        } else {
            for (AccountContactRole accRole : masterAccount.AccountContactRoles) {
                if (engageAccountRole.Contact.Id == accRole.Contact.Id) {
                    missSameOfficeContact = false;
                    break;
                }
            }
        }

        return missSameOfficeContact;
    }
    /**
     * [isShowPrompt - common check for all possible prompts]
     * @param  responseOnClose [Data that contains info if prompt should be shown]
     * @return                 [At least if one prompt should be shown returns true]
     */
    private static Boolean isShowPrompt(Map<String, Object> responseOnClose) {
        Boolean isShowPrompt = false;
        // 1. If generate orders prompt should be shown
        // 2. If Recall engage legal prompt should be shown
        if (responseOnClose.get('isCCPhoneNumbersRequired') != null ||
            responseOnClose.get('isShowRecallELPrompt') != null ||
            responseOnClose.get('isShowEngagePrompt') != null) {
            isShowPrompt = true;
        }
        return isShowPrompt;
    }
    /**
     * [getTierIdSet  - Gets available tier ids]
     * @param  tierTypeSetting [TierTypeSetting__c cutom setting]
     * @return                 [List of available tier ids]
     */
    public static Set<String> getTierIdSet(List<TierTypeSetting__c> tierTypeSetting) {
        Set<String> tierIdSet = new Set<String>();
        if (tierTypeSetting != null) {
            for (TierTypeSetting__c tts : tierTypeSetting) {
                if (tts.TierId__c != null && tts.IsDeleted == false) {
                    tierIdSet.add(tts.TierId__c);
                }
            }
        }
        return tierIdSet;
    }

    public class OpportunityInfo {
        public Id opportunityId {get;set;}
        public String optyName {get;set;}
        public String parentOrder {get;set;}
        public Boolean isSingleOne {get;set;}
        public Boolean isRenewalWithoutChanges {get;set;}

        public OpportunityInfo() {}

        public OpportunityInfo(Id opId, String name, String parentOrder, Boolean isSingleOne) {
            this.opportunityId = opId;
            this.optyName = name;
            this.parentOrder = parentOrder;
            this.isSingleOne = isSingleOne;
        }
    }

    @TestVisible
    private static String selectCloseWizard(
        Opportunity opty,
        Quote primaryQuote,
        Boolean isRenewalWithoutChanges,
        Integer optyQuantity,
        Boolean isMultipleUBOppty) {

        OpportunityInfo info = new OpportunityInfo();
        info.opportunityId = opty.Id;
        info.optyName = opty.Name;
        info.parentOrder = opty.Parent_Order__c;
        info.isSingleOne = optyQuantity <= 1;
        info.isRenewalWithoutChanges = isRenewalWithoutChanges;

        String encodedOppInfo = EncodingUtil.urlEncode(JSON.serialize(info),'UTF-8');
        String wizardType = opty.GoldfingerRetention__c != null ? opty.GoldfingerRetention__c : 'Close';

        // Choose wizard type for upsell/upgrade scenario
        if (primaryQuote != null && primaryQuote.Upsell_Status__c != QuoteHelper.STATUS_NEW_CUSTOMER) {
            if (primaryQuote.Delta_MRR__c != null && primaryQuote.Delta_MRR__c < 0) {
                if(CancelDownsellWizardController.isAllowToShowOptions(UserInfo.getUserRoleId()) ) {
                    wizardType = 'downsellwithretention';
                } else {
                    wizardType = 'downsell';
                }

                return  '/apex/DowngradeWizard?wizardType=' + wizardType + '&opportunityInfo=' + encodedOppInfo;
            }
        }

        List<String> missedFields = new List<String>();
        opty.StageName = OpportunityHelper.STAGE_NAME_CLOSED_WON;
        Map<Id, ValidationCategory> opptyValidationCategoryMap = getOpportunityValidationCategory(new List<Opportunity> { opty });
        ValidationCategory valCategory = opptyValidationCategoryMap.get(opty.Id);
        if(valCategory == ValidationCategory.GSP_VALIDATION || doesUserProfileHaveValidationRules()) {
            missedFields = OpportunityStageValidator.getMissingFieldsforGivenStage(opty, getARRConvertedToCorporateCCY(opty.Id), valCategory);
        }
        String requiredFields = missedFields.isEmpty() ? 'null' : JSON.serialize(missedFields);
        Boolean isShowQuoteLockWarning = !opty.Name.toLowerCase().contains('change order')
            && !opty.Name.toLowerCase().contains('migration')
            && String.isBlank(info.parentOrder)
            && !info.isRenewalWithoutChanges
            && !info.isSingleOne;

        if(missedFields.isEmpty() && !isShowQuoteLockWarning && !isMultipleUBOppty) {
            Map<String, String> params = new Map<String, String>();
            params.put('wType', wizardType.toLowerCase());
            params.put('brandName', opty.Brand_Name__c);
            params.put('isInline', 'false');
            params.put('Id', info.opportunityId);
            DowngradeWizardController.submitForm(params);
            wizardType = '';
        }

        return String.isNotBlank(wizardType)
            ? '/apex/DowngradeWizardV2?wizardType=' + wizardType + '&opportunityInfo=' + encodedOppInfo + '&validationType=' + valCategory.name() + '&requiredFields=' + requiredFields
            : '' ;
    }

    public static Boolean doesUserProfileHaveValidationRules() {
        List<String> profileIDsList = new List<String>();
        for (Opportunity_Close_Setup__mdt listOfProfileIds : [SELECT ProfileIDValues__c FROM Opportunity_Close_Setup__mdt]) {
            profileIDsList.addAll(listOfProfileIds.ProfileIDValues__c.split(','));
        }
        return profileIDsList.contains(UserInfo.getProfileId());
    }

    public static Decimal getARRConvertedToCorporateCCY(ID opptyID) {
        AggregateResult objAggregateResult = [SELECT SUM(Estimated_12M_Total_Pipeline__c) ConvertedARR FROM opportunity WHERE id = :opptyID];
        return (Decimal)objAggregateResult.get('ConvertedARR');
    }

    public static ValidationCategory identifyValidationCategory(String brandNm, String partnerID, String PartnerProgram, List<Non_GSP_Brand__mdt> customMetadataNonGSPBrands) {
        ValidationCategory result;
        Boolean availableInCustomMetadata = false;

        if(String.isNotBlank(brandNm)) {
            for (Non_GSP_Brand__mdt nonGSPBrand : customMetadataNonGSPBrands) {
                if (brandNm.equalsIgnoreCase(nonGSPBrand.Value__c)) {
                    availableInCustomMetadata = true;
                    break;
                }
            }
        }

        if(String.isNotBlank(brandNm) && !availableInCustomMetadata) {
            result = ValidationCategory.GSP_VALIDATION;
        } else if(String.isNotBlank(partnerID)) {
            if(String.isNotBlank(PartnerProgram) && PartnerProgram.equals(PARTNER_PROGRAM_CHANNEL_HARMONY)){
                result = ValidationCategory.CHANNEL_HARMONY_VALIDATION;
            } else {
                result = ValidationCategory.PARTNER_VALIDATION;
            }
        } else {
            result = ValidationCategory.FULL_VALIDATION;
        }
        return result;
    }

    public static Map<Id, ValidationCategory> getOpportunityValidationCategory(List<Opportunity> opptyList) {
        Map<Id, ValidationCategory> opptyValidationCategoryMap = new Map<Id, ValidationCategory>();
        List<Non_GSP_Brand__mdt> customMetadataNonGSPBrands = [Select Id, Label, Value__c FROM Non_GSP_Brand__mdt];
        for (Opportunity oppty : opptyList) {
            ValidationCategory result = identifyValidationCategory(oppty.Brand_Name__c, oppty.Partner_ID__c, oppty.PartnerProgram__c, customMetadataNonGSPBrands);
            opptyValidationCategoryMap.put(oppty.Id, result);
        }
        return opptyValidationCategoryMap;
    }

    @TestVisible
    private static void resetConfirmAndCloseFlag(Opportunity op, Quote qt) {
        Boolean isNeededToResetConfirmAndCloseFlag = !(qt.Status == QuoteHelper.QUOTE_STATUS_ACTIVE &&
            qt.QuoteType__c == QuoteHelper.QUOTE_TYPE_AGREEMENT) &&
            op.Type == OpportunityHelper.OPPORTUNITY_TYPE_EX_BUSINESS &&
            (qt.Upsell_Status__c == QuoteHelper.STATUS_UPSELL || qt.Upsell_Status__c == QuoteHelper.STATUS_UPGRADE)
            && (QuoteHelper.isSalesQuote(qt) || QuoteHelper.isNewBillingQuote(qt)) &&
            op.ConfirmAndClose__c == true;

        if (isNeededToResetConfirmAndCloseFlag && qt.QuoteType__c == QuoteHelper.QUOTE_TYPE_QUOTE) {
            update new Opportunity(
                Id = op.Id,
                ConfirmAndClose__c = false
            );
        }
    }
    /**
     * Check if Opportunity is created under Change Order Flow
     *
     * @param opportunity
     * @param allOpptyQuotes
     *
     * @return
     */
    public static Boolean isChangeOrderOpportunity(Opportunity opportunity, List<Quote> allOpptyQuotes){
        List<Quote> quotes = QuoteHelper.filterBillingQuotes(allOpptyQuotes, opportunity);
        Quote primaryQuote = QuoteHelper.getPrimaryQuote(quotes);
        Quote proServQuote = QuoteHelper.getProServQuote(quotes);
        Quote ccProServQuote = QuoteHelper.getCCProServQuote(quotes);

        Quote ccOrProServQuote = proServQuote != null ?
            proServQuote : ccProServQuote;
        return ccOrProServQuote != null && primaryQuote != null
                && ccOrProServQuote.Upsell_Status__c == QuoteHelper.STATUS_UPSELL
                && quotes.size() == 1;
    }
    //Used to get features for not discountable products
    public static List<Decimal> getRestrictedFeatureList() {

        List<Decimal> featureList = new List<Decimal>();
        if (Features__c.getall().get('restrictedFeature') != null
                    && String.isNotBlank(Features__c.getall().get('restrictedFeature').FeatureSet__c)) {
            String features = Features__c.getall().get('restrictedFeature').FeatureSet__c;
            List<String> str =  features.split(',');
            for(String s : str) {
                featureList.add(Decimal.valueOf(s));
            }
        }
        return featureList;
    }

    public static Boolean isRenewalOpp(Opportunity o) {
        return OPPORTUNITY_TYPE_RENEWAL.equalsIgnoreCase(o.Type);
    }

    public static Boolean isRenewalOptyWithoutChanges(Opportunity o, List<Quote> allOpptyQuotes) {
        Map<Id, List<QuoteLineItem>> quoteIdToQliListMap = new Map<Id, List<QuoteLineItem>>();
        for (Quote qt : allOpptyQuotes) {
            if (!quoteIdToQliListMap.containsKey(qt.Id)) {
                quoteIdToQliListMap.put(qt.Id, new List<QuoteLineItem>());
            }
            quoteIdToQliListMap.get(qt.Id).addAll(qt.QuoteLineItems);
        }
        return isRenewalOptyWithoutChanges(o, allOpptyQuotes, quoteIdToQliListMap);
    }

    public static Boolean isRenewalOptyWithoutChanges(
        Opportunity o,
        List<Quote> allOpptyQuotes,
        Map<Id, List<QuoteLineItem>> quoteIdToQliListMap
    ) {
        if (!isRenewalOpp(o)) {
            return false;
        }

        if (allOpptyQuotes == null || allOpptyQuotes.isEmpty()) {
            return true;
        }

        Quote primaryQuote = QuoteHelper.getPrimaryQuote(allOpptyQuotes, o.Is_Billing_Opportunity__c);

        Boolean isPrimaryQuoteUnchanged = primaryQuote == null ? true
                    : (QuoteHelper.isUpsell(primaryQuote)
                && !QuoteHelper.isQuoteHasChangesOnUpsell(quoteIdToQliListMap.get(primaryQuote.Id))
                && QuoteHelper.QUOTE_STATUS_DRAFT.equals(primaryQuote.Status)
                && QuoteHelper.QUOTE_TYPE_QUOTE.equals(primaryQuote.QuoteType__c));

        Boolean isCcQuoteUnchanged = true;
        if (o.Is_Billing_Opportunity__c) {
            Quote ccQuote = QuoteHelper.getCCQuote(allOpptyQuotes);
            isCcQuoteUnchanged = ccQuote == null ? true
                        : QuoteHelper.isUpsell(ccQuote)
                        && !QuoteHelper.isQuoteHasChangesOnUpsell(quoteIdToQliListMap.get(ccQuote.Id));
        }

        Boolean isNoProservQuote =
            allOpptyQuotes == null
            || (QuoteHelper.getCCProServQuote(allOpptyQuotes, o.Is_Billing_Opportunity__c) == null
                && QuoteHelper.getProServQuote(allOpptyQuotes, o.Is_Billing_Opportunity__c) == null);

        return isPrimaryQuoteUnchanged
                && isCcQuoteUnchanged
                && isNoProservQuote;
    }

    public static List<Quote> filterQuotesByOppId(Id oppId, List<Quote> quotes) {
        List<Quote> res = new List<Quote>();

        if (String.isBlank(oppId) || quotes == null || quotes.isEmpty()) {
            return res;
        }

        for (Quote q : quotes) {
            if (q.OpportunityId == oppId) {
                res.add(q);
            }
        }

        return res;
    }

    public static Map<Id, List<Quote>> filterQuotesByOppIds(Set<Id> oppIds, List<Quote> quotes) {
        Map<Id, List<Quote>> res = new Map<Id, List<Quote>>();

        if (oppIds == null || oppIds.isEmpty() || quotes == null || quotes.isEmpty()) {
            return res;
        }

        for (Id oppId : oppIds) {
            res.put(oppId, new List<Quote>());
            for (Quote q : quotes) {
                if (q.OpportunityId == oppId) {
                    res.get(oppId).add(q);
                }
            }
        }

        return res;
    }

    /**
     * Check are CC Phone Numbers required for order generation
     */
    public static Boolean isCCPhoneNumbersRequired(Opportunity opportunity, List<Quote> quotes, List<Entitlement__c> entitlements){
        Boolean result = false;

        Map<Id, QuoteLineItem> qliIdMap = new Map<Id, QuoteLineItem>();
        Map<String, GenerateOrders.ItemsWrapper> subCategoryItems = new Map<String, GenerateOrders.ItemsWrapper>();

        GenerateOrders.populateMaps(quotes, new List<Entitlement__c>(), qliIdMap, subCategoryItems, opportunity);

        List<Entitlement__c> ccEnts = new List<Entitlement__c>();
        for (Entitlement__c ent : entitlements){
            if (Product2Helper.CONTACT_CENTER_SUBCATEGORIES.contains(ent.Product__r.Sub_Category__c)) {
                ccEnts.add(ent);
            }
        }

        for(String subcategory : subCategoryItems.keySet()) {
            if (Product2Helper.CONTACT_CENTER_SUBCATEGORIES.contains(subcategory)) {
                if (String.isEmpty(opportunity.NumberToBeRCMainNumber__c)
                    && String.isEmpty(opportunity.NumberToBeCCNumber__c)
                    && ccEnts.size() == 0) {
                    result = true;
                    break;
                }
            }
        }

        return result;
    }

    public static Boolean isClosed(String stageName) {
        return STAGE_NAMES_CLOSED.contains(stageName);
    }

    public static Boolean isClosedWonProServ(String stageName) {
        return STAGE_NAME_CLOSED_WON_PROSERV.contains(stageName);
    }

    public static Boolean isProServEngaged(Opportunity opp){
        return opp != null && opp.EstimatedProfessionalServices12Month__c > 0;
    }

    public static Boolean isCustomerConfirmationEmailFlow(Id opportunityId) {
        if (String.isBlank(opportunityId)) {
            return false;
        }

        Opportunity opty = getOpportunity(opportunityId);
        populateOppRelatedStaticCollections(new Map<Id, Opportunity>{opty.Id => opty});
        Boolean isSendEmail = false;

        // Case11923613 : added to bypass issue 'No QuoteLineItems passed for upsell primary quote' when closing from 'Downgrade_X12_Month_Booking.page'
        List<Quote> quotesWithAllQLIs = retrieveAllQuotesWithAllQLIs(opty.Id);

        Feature_Toggle__c featureToggle = Feature_Toggle__c.getInstance();
        if (
            !featureToggle.ModifiedCloseOpportunityFlow__c
            || opty == null
            || opty.Quotes.isEmpty()
            || isRenewalOptyWithoutChanges(opty, quotesWithAllQLIs)
        ) {
            return isSendEmail;
        }

        Quote primaryQuote = opty.Quotes[0];

        RingCentralVariousSettings__c rcVariousSettings = RingCentralVariousSettings__c.getInstance();
        Decimal mrrCustomSettingThreshold = (rcVariousSettings.Customer_Confirmation_MRR_Threshold__c != null && rcVariousSettings.Customer_Confirmation_MRR_Threshold__c != 0)
                ? rcVariousSettings.Customer_Confirmation_MRR_Threshold__c
                : 0;

        Boolean isMrrMoreThanThreshold = rcVariousSettings.Customer_Confirmation_MRR_Threshold__c == null
            || rcVariousSettings.Customer_Confirmation_MRR_Threshold__c == 0
            || Math.abs(opty.Total_MRR__c).setScale(2, RoundingMode.HALF_UP) >= mrrCustomSettingThreshold;

        Boolean isAllowedToSetConfirmAndCloseFlag = !(primaryQuote.Status == QuoteHelper.QUOTE_STATUS_ACTIVE &&
                primaryQuote.QuoteType__c == QuoteHelper.QUOTE_TYPE_AGREEMENT)
                && primaryQuote.QuoteType__c == QuoteHelper.QUOTE_TYPE_QUOTE
                && opty.Type == OpportunityHelper.OPPORTUNITY_TYPE_EX_BUSINESS
                && opty.Parent_Order__c == null
                && (primaryQuote.Upsell_Status__c == QuoteHelper.STATUS_UPSELL
                    || primaryQuote.Upsell_Status__c == QuoteHelper.STATUS_UPGRADE)
                && (QuoteHelper.isSalesQuote(primaryQuote) || QuoteHelper.isNewBillingQuote(primaryQuote))
                && opty.ConfirmAndClose__c == false
                && opty.CustomerConfirmation__c != OVERRIDE_STATUS
                && AccountHelper.isTrial(opty.Account) == false;

        Boolean isValidSettingsPermissions = !featureToggle.Restrict_Customer_Confirmation__c
            || featureToggle.Restrict_Customer_Confirmation__c && isMrrMoreThanThreshold;

        if (isAllowedToSetConfirmAndCloseFlag && isValidSettingsPermissions) {
                isSendEmail = true;
        }

        return isSendEmail;
    }

    public static List<Quote> retrieveAllQuotesWithAllQLIs(Id opportunityId) {
        if (opportunityId == null) {
            return null;
        }

        return (List<Quote>) new QuoteSelector()
            .selectQuotes()
            .withoutSelectorFieldsIncluded()
            .selectFields(quoteFields)
            .subselect(
                new QuoteLineItemSelector()
                .selectQuoteLineItems()
                .withoutSelectorFieldsIncluded()
                .selectFields(qliFields)
            )
            .setCondition('OpportunityId = :bind0')
            .setQueryBindings(new List<Object>{ OpportunityId })
            .executeQuery();
    }

    public static Boolean isExistingBusinessBilling(Quote quote){
        return quote != null && quote.Account != null && quote.Account.Billing_ID__c != null ? String.isNotBlank(quote.Account.Billing_ID__c) : false;
    }

    /**
     * [getOpportunity descripiton]
     * @param  optyId [Opportunity Id]
     * @return        [Opportunity]
     */
    public static Opportunity getOpportunity(String optyId) {
        Opportunity opp;
        try{
            opp = [
                SELECT AccountId, StageName, EndStage__c, Name, Parent_Order__c, Type, ConfirmAndClose__c, Amount, Total_MRR__c,
                    CustomerConfirmation__c, GoldfingerRetention__c, Brand_Name__c, Is_Billing_Opportunity__c, Account.RC_Account_Status__c,
                    (
                        SELECT Upsell_Status__c, Monthly_Recurring_Revenue__c, Account__c,
                            isPrimary__c, Status, QuoteType__c, RecordTypeId, Opportunity.Account.RC_Account_Status__c
                        FROM Quotes
                        WHERE IsPrimary__c = true
                        AND (
                            (Opportunity.Is_Billing_Opportunity__c = true AND RecordTypeId = :QuoteHelper.RT_ID_BILLING)
                            OR (Opportunity.Is_Billing_Opportunity__c = false AND RecordTypeId = :QuoteHelper.RT_ID_SALES)
                            OR RecordTypeId = :QuoteHelper.RT_ID_PROSERV
                            OR RecordTypeId = :QuoteHelper.RT_ID_CC_PROSERV
                        )
                    )
                FROM Opportunity
                WHERE Id = :optyId
            ];
        } catch(QueryException e) {
            System.debug('Invalid opportunity Id, exception is thrown: ' + e.getMessage());
        }
        return opp;
    }

    public static Opportunity getOpportunityCloseWizardValues(String optyId) {
        List<Opportunity> oppList = [
            SELECT Id, AccountId, Name, Type, Brand_Name__c,
                CW_Categories_Who_did_we_beat__c,
                CW_Categories_Who_did_we_beat_other__c,
                CW_Who_did_we_beat__c,
                CW_Categories_Who_did_we_replace__c,
                CW_Categories_Who_did_we_replace_other__c,
                CW_Who_did_we_replace__c,
                CW_Primary_Win_Reason__c,
                CW_Secondary_Win_Reason__c,
                CW_Win_Reason_Awards__c,
                CW_Win_Reason_Awards_other__c,
                CW_Win_Reason_Features__c,
                CW_Win_Reason_Features_enterprise__c,
                CW_Win_Reason_Integrations__c,
                CW_Win_Reason_Integrations_other__c,
                CW_Win_Reason_Savings__c,
                Why_We_Won__c,
                Final_Competitor_we_won_against__c,
                Additional_details_on_why_we_won__c
            FROM Opportunity
            WHERE Id = :optyId
            LIMIT 1
        ];

        return oppList.size() > 0 ? oppList[0] : null;
    }

    public static void populateOppRelatedStaticCollections(Map<Id, Opportunity> oppsMap) {
        Boolean doSOQL = false;
        for (Opportunity oppty : oppsMap.values()) {
            if (opptyToQuotesMapStatic.get(oppty.Id) == null) {
                doSOQL = true;
            }
        }
        if (doSOQL) {
            Set<Id> accountIdSet = new Set<Id>();
            Set<Id> oppIdSet = new Set<Id>();

            for (Opportunity o : oppsMap.values()) {
                accountIdSet.add(o.AccountId);
                oppIdSet.add(o.Id);
            }

            if (accountIdSet.contains(null)) {
                accountIdSet.remove(null);
            }

            if (oppIdSet.contains(null)) {
                oppIdSet.remove(null);
            }

            QueryFactory factory = new QuoteSelector()
                .selectQuotesByAccountAndOpportunity(accountIdSet, oppIdSet)
                .withoutSelectorFieldsIncluded()
                .selectFields(quoteFields);

            Database.QueryLocator locator = factory.executeQueryLocator();
            Database.QueryLocatorIterator iterator = locator.iterator();
            Map<Id, Quote> quotesMap = new Map<Id, Quote>();
            Quote q;
            while (iterator.hasNext()) {
                q = (Quote)iterator.next();
                quotesMap.put(q.Id, q);
            }

            populateOpptyToQuotesMapStatic(quotesMap.values(), oppsMap.keySet());
            populateQuotesPendingApprovalMap(quotesMap.values());
        }
    }

    private static void populateQuotesPendingApprovalMap(List<Quote> quotesList) {
        for (Quote q : quotesList) {
            if (QuoteHelper.isQuotePendingApproval(q)) {
                if (!OpportunityTriggerHelperRefactored.accIdToQuotesOnAccountPendingApproval.containsKey(q.AccountId)) {
                    OpportunityTriggerHelperRefactored.accIdToQuotesOnAccountPendingApproval.put(q.AccountId, new List<Quote>());
                }
                OpportunityTriggerHelperRefactored.accIdToQuotesOnAccountPendingApproval.get(q.AccountId).add(q);
            }
        }
    }

    public static void populateOpptyToQuotesMapStatic(List<Quote> quotesList, Set<Id> oppIds) {
        for (Quote q : quotesList) {
            if (!oppIds.contains(q.OpportunityId)) {
                continue;
            }

            if (!opptyToQuotesMapStatic.containsKey(q.OpportunityId)) {
                opptyToQuotesMapStatic.put(q.OpportunityId, new List<Quote> {q});
                continue;
            }

            List<Quote> quotes = opptyToQuotesMapStatic.get(q.OpportunityId);
            if (!HelperUtils.isSObjectInList(q, quotes)) {
                quotes.add(q);
            }
        }
    }

    public static Boolean isNewBusiness(Opportunity opp) {
        return opp != null && OPPORTUNITY_TYPE_NEW_BUSINESS.equalsIgnoreCase(opp.Type);
    }

    public static Boolean isAvaya(Opportunity opty) {
        return opty != null && opty.Brand_Name__c == RingCentralHelper.BRAND_AVAYA;
    }

    // This method is deprecated. Use QuoteHelper.isEngage(Quote qt) instead.
    public static Boolean isEngage(Opportunity opp) {
        return opp != null && ENGAGE_TIERS.contains(opp.Tier_Name__c);
    }

    // This method is deprecated. Use QuoteHelper.isEngageUnified(Quote qt) instead.
    public static Boolean isEngageUnified(Opportunity opp) {
        return opp != null && (TIER_ENGAGE_UNIFIED.equalsIgnoreCase(opp.Tier_Name__c));
    }

    // This method is deprecated. Use QuoteHelper.isEngageVoice(Quote qt) instead.
    public static Boolean isEngageVoice(Opportunity opp) {
        return opp != null &&
            (TIER_ENGAGE_VOICE_LEGACY.equalsIgnoreCase(opp.Tier_Name__c) ||
            TIER_ENGAGE_VOICE_STANDALONE.equalsIgnoreCase(opp.Tier_Name__c));
    }

    // This method is deprecated. Use QuoteHelper.isEngageVoiceStandalone(Quote qt) instead.
    public static Boolean isEngageVoiceStandalone(Opportunity opp) {
        return opp != null && TIER_ENGAGE_VOICE_STANDALONE.equalsIgnoreCase(opp.Tier_Name__c);
    }

    // This method is deprecated. Use QuoteHelper.isEngageDigital(Quote qt) instead.
    public static Boolean isEngageDigital(Opportunity opp) {
        return opp != null &&
            (TIER_ENGAGE_DIGITAL_LEGACY.equalsIgnoreCase(opp.Tier_Name__c) ||
            TIER_ENGAGE_DIGITAL_STANDALONE.equalsIgnoreCase(opp.Tier_Name__c));
    }

    // This method is deprecated. Use QuoteHelper.isEngageLegacy(Quote qt) instead.
    public static Boolean isEngageLegacy(Opportunity opp) {
        return opp != null &&
           (TIER_ENGAGE_DIGITAL_LEGACY.equalsIgnoreCase(opp.Tier_Name__c) ||
           TIER_ENGAGE_VOICE_LEGACY.equalsIgnoreCase(opp.Tier_Name__c));
    }

    // This method is deprecated. Use QuoteHelper.isEngageOmnichannel(Quote qt) instead.
    public static Boolean isEngageOmnichannel(Opportunity opp) {
        return opp != null && TIER_ENGAGE_OMNICHANNEL.equalsIgnoreCase(opp.Tier_Name__c);
    }

    public static Boolean isRcEuropeBrand(Opportunity opp) {
        return opp != null &&
           (BRAND_RINGCENTRAL_EU.equalsIgnoreCase(opp.Brand_Name__c) ||
           BRAND_RINGCENTRAL_UK.equalsIgnoreCase(opp.Brand_Name__c));
    }

    public static Boolean isRcBrand(Opportunity opp) {
        return opp != null && RC_BRANDS.contains(opp.Brand_Name__c);
    }

    public static Boolean isSingapore(Opportunity opp) {
        return opp != null &&
            BRAND_RINGCENTRAL_EU.equalsIgnoreCase(opp.Brand_Name__c) &&
            opp.CurrencyIsoCode == 'SGD';
    }

    public static Boolean isAustralia(Opportunity opp) {
        return opp != null &&
            BRAND_RINGCENTRAL_AU.equalsIgnoreCase(opp.Brand_Name__c) &&
            opp.CurrencyIsoCode == 'AUD';
    }

    // This method is deprecated. Use QuoteHelper.isRCCC(Quote qt) instead.
    public static Boolean isInContact(Opportunity opp) {
        return opp != null && (TIER_RC_CONTACT_CENTER.equalsIgnoreCase(opp.Tier_Name__c));
    }

    public static Boolean isOffice(Opportunity opp) {
        return TIER_OFFICE.equalsIgnoreCase(opp?.Tier_Name__c);
    }
    public static Boolean isEvent(Opportunity opp) {
        return TIER_EVENT.equalsIgnoreCase(opp?.Tier_Name__c);
    }

    @future
    public static void generateAssistanceCases(Set<Id> opptyIds) {
        List<Case> assistCases = new List<Case>();
        List<Opportunity> opptysForAssyst = (List<Opportunity>) new OpportunitySelector()
            .selectOpportunitiesByIds(opptyIds)
            .executeQuery();

        Map<String, Group> groupMap = new Map<String, Group>();
        for (Group g : (List<Group>) new GroupSelector()
            .selectGroupBasedOnDeveloperNames(
                new List<Object>{
                    new Set<String>{
                        QueueHelper.DEAL_DESK_ENGAGE_QUEUE
                    }
                }
            )
            .executeQuery()) {
            groupMap.put(g.DeveloperName, g);
        }

        for (Opportunity opp : opptysForAssyst) {
            assistCases.add(CaseHelper.buildAssistCase(opp, groupMap));
        }

        insert assistCases;
    }

    public static List<SFDescribeHelper.TPicklistEntry> getTierNameOptions() {
        List<SFDescribeHelper.TPicklistEntry> result = SFDescribeHelper.convertToTPicklistEntry(
            SFDescribeHelper.getOptions('Opportunity', 'Tier_Name__c')
        );

        if (!Feature_Toggle__c.getInstance().Enable_Engage__c) {
            List<SFDescribeHelper.TPicklistEntry> filteredResult = new List<SFDescribeHelper.TPicklistEntry>();
            for (SFDescribeHelper.TPicklistEntry entry: result) {
                if (!ENGAGE_TIERS.contains(entry.value)) {
                    filteredResult.add(entry);
                }
            }
            result = filteredResult;
        }

        if (FeatureManagement.checkPermission(CustomPermissionHelper.PERMISSION_PROCESS_ENGAGE_LEGACY) &&
            Feature_Toggle__c.getInstance().Enable_Engage__c) {
            result.add(new SFDescribeHelper.TPicklistEntry(TIER_ENGAGE_VOICE_LEGACY));
            result.add(new SFDescribeHelper.TPicklistEntry(TIER_ENGAGE_DIGITAL_LEGACY));
        }

        if (Feature_Toggle__c.getInstance().Enable_Engage_Omni__c) {
            result.add(new SFDescribeHelper.TPicklistEntry(TIER_ENGAGE_OMNICHANNEL));
        }

        return result;
    }

    public static Map<String, List<String>> getServiceDependency() {
        Map<String, List<String>> result = SFDescribeHelper.getDependentOptions('Opportunity', 'Brand_Name__c', 'Tier_Name__c');
        if (!Feature_Toggle__c.getInstance().Enable_Engage__c) {
            result = filterOutEngageServices(result, ENGAGE_TIERS);
        }

        if (Feature_Toggle__c.getInstance().Disable_Engage_Standalone__c) {
            result = filterOutEngageServices(result, ENGAGE_STANDALONE_TIERS);
        }

        if (FeatureManagement.checkPermission(CustomPermissionHelper.PERMISSION_PROCESS_ENGAGE_LEGACY) &&
            Feature_Toggle__c.getInstance().Enable_Engage__c) {
            result.get(RingCentralHelper.BRAND_RINGCENTRAL).addAll(new List<String>{
                TIER_ENGAGE_VOICE_LEGACY,
                TIER_ENGAGE_DIGITAL_LEGACY
            });
            result.get(RingCentralHelper.BRAND_RINGCENTRAL_EU).add(TIER_ENGAGE_DIGITAL_LEGACY);
            result.get(RingCentralHelper.BRAND_RINGCENTRAL_CANADA).addAll(new List<String>{
                TIER_ENGAGE_VOICE_LEGACY,
                TIER_ENGAGE_DIGITAL_LEGACY
            });
        }

        if (FeatureManagement.checkPermission(CustomPermissionHelper.PERMISSION_PROCESS_ENGAGE_DIGITAL_STANDALONE)) {
            result.get(RingCentralHelper.BRAND_RINGCENTRAL).add(TIER_ENGAGE_DIGITAL_STANDALONE);
            result.get(RingCentralHelper.BRAND_RINGCENTRAL_CANADA).add(TIER_ENGAGE_DIGITAL_STANDALONE);
        }

        if (Feature_Toggle__c.getInstance().Enable_Engage_Omni__c) {
            result.get(RingCentralHelper.BRAND_RINGCENTRAL).add(TIER_ENGAGE_OMNICHANNEL);
            result.get(RingCentralHelper.BRAND_RINGCENTRAL_CANADA).add(TIER_ENGAGE_OMNICHANNEL);
            result.get(RingCentralHelper.BRAND_RINGCENTRAL_UK).add(TIER_ENGAGE_OMNICHANNEL);
        }

        return result;
    }

    public static Integer getForecastedDigitalUsers(String tier, Integer newUsers) {
        return isEngageDigital(new Opportunity( Tier_Name__c = tier )) ? newUsers : null;
    }

    public static Integer getForecastedVoiceUsers(String tier, Integer newUsers) {
        return isEngageVoice(new Opportunity( Tier_Name__c = tier )) ? newUsers : null;
    }

    public static Integer getForecastedOfficeUsers(String tier, Integer newUsers) {
        return isOffice(new Opportunity( Tier_Name__c = tier )) ? newUsers : null;
    }

    public static Integer getForecastedRCCCUsers(String tier, Integer newUsers) {
        return isInContact(new Opportunity( Tier_Name__c = tier )) ? newUsers : null;
    }
    public static Integer getForecastedRCEventUsers(String tier, Integer newUsers) {
        return isEvent(new Opportunity( Tier_Name__c = tier )) ? newUsers : null;
    }

    @future
    public static void unParentChildQuotes(Set<Id> quoteIdSet) {
        List<Quote> unparentedQuotes = new List<Quote>();
        for (Id qtId : quoteIdSet) {
            Quote qt = new Quote(Id = qtId, ParentQuote__c = null);
            unparentedQuotes.add(qt);
        }

        update unparentedQuotes;
    }

    public static Boolean isAtos (Opportunity opty) {
        return opty != null && opty.Brand_Name__c == RingCentralHelper.BRAND_ATOS;
    }

    public static Boolean isRainbow (Opportunity opty) {
        return opty != null && opty.Brand_Name__c == RingCentralHelper.BRAND_RAINBOW;
    }

    public static Boolean isRcEuBrand(Opportunity opty) {
        return opty?.Brand_Name__c == RingCentralHelper.BRAND_RINGCENTRAL_EU;
    }

    public static Boolean isSkipPipelineTotalsCalculationForBrand(String brand) {
        return SKIP_PIPELINE_TOTALS_CALCULATION_FOR_BRANDS.contains(brand)
                && CustomPermissionHelper.currentUserHasPermissionSet(CustomPermissionHelper.PERMISSION_ESTIMATED_PIPELINE_REPORTING);
    }

    public static Map<Id, Opportunity> filterOpportunitiesToCalculatePipelineTotals(List<Opportunity> oppList) {
        Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>();
        for (Opportunity opp: oppList) {
            if(!OpportunityHelper.isSkipPipelineTotalsCalculationForBrand(OpportunityHelper.getBrand(opp))) {
                oppMap.put(opp.Id, opp);
            }
        }
        return oppMap;
    }

    public static Boolean isVerizon(Opportunity opty) {
        return getBrand(opty) == RingCentralHelper.BRAND_VERIZON;
    }

    public static String getBrand(Opportunity opty) {
        List<PackageBusinessIdentityMapping__c> pbimList;
        BillingWrappers.QuoteBusinessIdentity bi;
        String biBrand;

        if (opty != null && opty.BusinessIdentity__c != null) {
            pbimList = PackageBusinessIdentityMapping__c.getAll().values();
            bi = (BillingWrappers.QuoteBusinessIdentity) JSON.deserialize(
                    opty.BusinessIdentity__c.replace('currency', 'biCurrency'),
                    BillingWrappers.QuoteBusinessIdentity.class
            );
            if (bi == null) {
                return opty?.Brand_Name__c;
            }
            for (PackageBusinessIdentityMapping__c pbim: pbimList) {
                if (pbim.BiId__c != null && pbim.BiId__c.equals(bi.biId)) {
                    biBrand = pbim.DefaultBrand__c;
                    break;
                }
            }
        }

        return biBrand != null ? biBrand : opty?.Brand_Name__c;
    }

    public static Map<String, List<String>> filterOutEngageServices(Map<String, List<String>> result, Set<String> tiers) {
        Map<String, List<String>> filteredResult = new Map<String, List<String>>();

        for (String brand : result.keySet()) {
            List<String> filteredServices = new List<String>();
            for (String tier : result.get(brand)) {
                if (!tiers.contains(tier)) {
                    filteredServices.add(tier);
                }
            }
            filteredResult.put(brand, filteredServices);
        }

        return filteredResult;
    }

    public static Boolean isTelusOfficePlaceholderOppty(Opportunity opty) {
        return opty != null && opty.Brand_Name__c == BRAND_TELUS_BUSINESS_CONNECT && opty.Tier_Name__c == TIER_TELUS_OFFICE;
    }

    public static Boolean BizMergeBrandExclusion(Opportunity opp) {
        return opp != null
            && opp.Brand_Name__c != null
            && System.Label.BizMerge_Brand_Exclusion_List.contains(opp.Brand_Name__c);
    }

    public static Boolean hasInvoiceApproval(Id opportunityId) {
        List<Approval__c> approvals = (List<Approval__c>) new ApprovalSelector()
            .selectInvoiceApprovalsForNGBS(new List<Object> {opportunityId})
            .withoutSelectorFieldsIncluded()
            .executeQuery();
        return !approvals.isEmpty();
    }

    public static Boolean isAllForecastedUsersZero(Opportunity opty) {
        return opty != null
            && (opty.Forecasted_Users__c == null || opty.Forecasted_Users__c == 0)
            && (opty.Forecast_Contact_Center_Users__c == null || opty.Forecast_Contact_Center_Users__c == 0)
            && (opty.Forecasted_Global_Office_Users__c == null || opty.Forecasted_Global_Office_Users__c == 0)
            && (opty.ForcastedDimeloUsers__c == null || opty.ForcastedDimeloUsers__c == 0)
            && (opty.Forecast_Connect_First_Users__c == null || opty.Forecast_Connect_First_Users__c == 0)
            && (opty.Forecasted_RingCentral_Video_Users__c == null || opty.Forecasted_RingCentral_Video_Users__c == 0);
    }

    // this method handles both oppty and service info states
    public static Map<Id, Boolean> engageOppIdToTerminationStatus(List<Opportunity> opportunities) {
        Map<Id, Boolean> result = new Map<Id, Boolean>();
        // handling old single product and MPL tech oppties
        for (Opportunity opp : opportunities) {
            if (String.isNotBlank(opp?.Id) && isEngage(opp) && opp.IsTermination__c) {
                result.put(opp.Id, opp.IsTermination__c);
            }
        }

        // handling new UB single product oppties
        Set<Id> oppIds = new Set<Id>();
        for (Opportunity opp : opportunities) {
            if (String.isNotBlank(opp?.Id) && isEngage(opp) && !BooleanHelper.toBoolean(result.get(opp.Id))) {
                oppIds.add(opp.Id);
            }
        }

        if (oppIds.isEmpty()) {
            return result;
        }

        List<ServiceInfo__c> serviceInfos = (List<ServiceInfo__c>) new ServiceInfoSelector()
            .selectServiceInfoForTerminationCheck(new List<Object> { oppIds })
            .executeQuery();


        for (Id oppId : oppIds) {
            for (ServiceInfo__c sInfo : serviceInfos) {
                if (sInfo.Quote__r.OpportunityId == oppId && !BooleanHelper.toBoolean(result.get(oppId))) {
                    result.put(oppId, sInfo.IsTermination__c);
                    break;
                }
            }
        }

        return result;
    }

    public static Boolean isEngageTerminationOpportunity(Opportunity opp) {
        return String.isNotBlank(opp?.Id) && isEngage(opp) && opp.IsTermination__c;
    }

    public static Boolean isSavesDownSellOpportunity (Opportunity opty) {
        return opty != null && opty.RecordTypeId == RT_ID_SAVES_DOWN_SELL_OPPORTUNITY;
    }

    public static void closeOpportunity(Opportunity opportunity) {
        if (opportunity?.Brand_Name__c == RingCentralHelper.BRAND_VERIZON) {
            opportunity.StageName = OpportunityHelper.STAGE_NAME_CLOSED_WON_PROSERV;
            opportunity.Probability = 100;
        } else if (System.Label.BizMerge_Brand_Exclusion_List.contains(opportunity?.Brand_Name__c)){
            opportunity.StageName = OpportunityHelper.STAGE_NAME_CLOSED_WON;
            opportunity.Probability = 100;
        } else if (opportunity != null) {
            opportunity.StageName = OpportunityHelper.STAGE_NAME_CLOSED_WON;
            opportunity.Probability = 100;
        }
    }

    public static String businessIdentitySerialize(Integer businessIdentityId, String businessIdentityCurrency) {
        String serialize = null;

        if (businessIdentityId != null && businessIdentityCurrency != null) {
            Map<String, String> businessIdentityMap = new Map<String, String>();

            businessIdentityMap.put('biId', String.valueOf(businessIdentityId));
            businessIdentityMap.put('currency', businessIdentityCurrency);

            serialize = JSON.serialize(businessIdentityMap);
        }

        return serialize;
    }

    public static Boolean isAmazon(Opportunity opp) {
        if (String.isBlank(opp?.BusinessIdentity__c)) {
            return false;
        }
        BillingWrappers.QuoteBusinessIdentity bi = (BillingWrappers.QuoteBusinessIdentity) JSON.deserialize(opp.BusinessIdentity__c, BillingWrappers.QuoteBusinessIdentity.class);
        return bi?.biId == BI_ID_AMAZON;
    }

    public static Boolean isIndia(Opportunity opp) {
        return opp != null
            && opp.CurrencyIsoCode != null
            && opp.Brand_Name__c != null
            && opp.CurrencyIsoCode == CURRENCY_NAME_INR
            && opp.Brand_Name__c == BRAND_RINGCENTRAL_EU;
    }

    public static Boolean isTaiwan(Opportunity opp) {
        return opp != null
            && opp.CurrencyIsoCode != null
            && opp.Brand_Name__c != null
            && opp.CurrencyIsoCode == CURRENCY_NAME_TWN
            && opp.Brand_Name__c == BRAND_RINGCENTRAL_EU;
    }


    public static List<Schema.PicklistEntry> getBrandOptions() {
        List<Schema.PicklistEntry> pickListOptions = SFDescribeHelper.getOptions('Opportunity', 'Brand_Name__c');
        List<Schema.PicklistEntry> result = new List<Schema.PicklistEntry>();

        Boolean isSkipFedRampBrand = !FeatureManagement.checkPermission(CustomPermissionHelper.PERMISSION_PROCESS_FEDRAMP_ACCOUNTS);
        for (Schema.PicklistEntry entry: pickListOptions) {
            /* Filter out FedRamp brand*/
            if (isSkipFedRampBrand && entry.getValue().toLowerCase() == BRAND_RC_FEDRAMP.toLowerCase()) {
                continue;
            }
            result.add(entry);
        }
        return result;
    }

    public static Boolean isSalesOpportunity(String opptyRecordTypeId) {
        return opptyRecordTypeId == RT_ID_NEW_SALES_OPPORTUNITY || opptyRecordTypeId == RT_ID_SALES_OPPORTUNITY;
    }

    public static Boolean isPartnerOpportunity(String opptyRecordTypeId) {
        return opptyRecordTypeId == RT_ID_VAR_OPPORTUNITY;
    }

    public static void createKYCApprovalsForIndiaOffice(List<Opportunity> listOpportunities) {
        List<Approval__c> newApprovalListToInsert = new List<Approval__c>();
        Set<Id> accIdSet = new Set<Id>();

        for (Opportunity opp : listOpportunities) {
            accIdSet.add(opp.AccountId);
        }

        Map<Id, Account> accountKYCApprovalsList = new Map<Id, Account>((List<Account>)
            new AccountSelector()
                .selectAccountWithKYCApprovals(new List<Object>{accIdSet})
                .executeQuery()
        );

        for (Opportunity opp : listOpportunities) {
            Boolean hasKYCApprovals = !accountKYCApprovalsList.get(opp.AccountId).Approvals__r?.isEmpty();

            Approval__c lastUpdatedApproval = hasKYCApprovals
                ? accountKYCApprovalsList.get(opp.AccountId).Approvals__r[0]
                : null;

            if (!hasKYCApprovals || lastUpdatedApproval?.Status__c == ApprovalHelper.STATUS_REJECTED) {
                newApprovalListToInsert.add(new Approval__c(
                    RecordTypeId = ApprovalHelper.RT_ID_KYC_APPROVAL_REQUEST,
                    Opportunity__c = opp.Id,
                    Account__c = opp.AccountId,
                    Status__c = ApprovalHelper.STATUS_REQUIRED,
                    NationalityOfAuthorisedSignatory__c = ApprovalHelper.NATIONALITY_OF_AUTHORISED_SIGNATORY_INDIA
                ));
            }
        }

        if (!newApprovalListToInsert.isEmpty()) {
            try {
                insert newApprovalListToInsert;
            } catch (Exception e) {
                PlatformLog.logException('errorKYCApproval', e);
            }
        }
    }

    public static void setOpptyCLMEnable(List<Opportunity> opportunityList) {
        for (Opportunity opp : opportunityList) {
            opp.IsDocusignCLMEnabled__c = false;
        }

        List<Opportunity> filteredOppty = filterOpptyForEnableCLM(opportunityList);

        for (Opportunity opp : filteredOppty) {
            opp.IsDocusignCLMEnabled__c = true;
        }
    }

    public static List<Opportunity> filterOpptyForEnableCLM(List<Opportunity> opportunityList) {
        List<Opportunity> result = new List<Opportunity>();

        if (opportunityList == null || opportunityList.isEmpty()) {
            return result;
        }
        Map<Id, Account> accountMap = OpportunityTriggerHelperRefactored.getAccountMap(opportunityList);
        Set<String> activeBrands = getActiveBrands();

        for (Opportunity opp : opportunityList) {
            Boolean isActiveBrand = activeBrands.contains(opp.Brand_Name__c);
            Account acc = accountMap.get(opp.AccountId);

            if (!AccountHelper.isWholesaleAccount(acc) &&
                !AccountHelper.isInvoiceOnBehalfAccount(acc) &&
                isActiveBrand &&
                (opp.Tier_Name__c == TIER_OFFICE || opp.Tier_Name__c == Constants.CONST_RC_EVENT || opp.Tier_Name__c == TIER_ENGAGE_VOICE_STANDALONE)
                ) {
                result.add(opp);
            }
        }

        return result;
    }

    public static Set<String> getActiveBrands() {
        Set<String> activeBrands = new Set<String>();

        for (Docusign_CLM_Brands__c cmlBrand : Docusign_CLM_Brands__c.getAll().values()) {
            if (cmlBrand.Enable_DocuSign_CLM_Access__c) {
                activeBrands.add(cmlBrand.Brand__c);
            }
        }
        return activeBrands;
    }

    public static Boolean isSearchPackagesEnabledWithValidOppBI(Opportunity opp) {
        return Feature_Toggle__c.getInstance().SelectPackagesByBusinessIdentity__c && isBusinessIdentityValid(opp?.BusinessIdentity__c);
    }

    public static Boolean isBusinessIdentityValid(String biFieldValue) {
        Boolean result = false;
        if (String.isNotBlank(biFieldValue)) {
            Map<String, String> businessIdentityMap = (Map<String, String>) JSON.deserialize(biFieldValue, Map<String, String>.class);
            result = String.isNotBlank(businessIdentityMap.get('biId'));
            // there is a currency key in map but we do not use it in logic and therefore skip it for validation
        }
        return result;
    }

    public static DQ_Deal_Qualification__c getDealQualification(Id oppOrDqId) {
        if (oppOrDqId == null) {
            return null;
        }

        List<DQ_Deal_Qualification__c> dqList = new DealQualificationSelector()
            .selectDQForSync(oppOrDqId)
            .executeQuery();

        if (!dqList.isEmpty()) {
            return dqList.get(0);
        }

        return null;
    }

    public static Map<String, Opportunity> getTechnicalOpportunitiesByMasterId(
        Opportunity masterOpportunity
    ) {
        Map<String, Account> technicalAccountsMap = AccountHelper.getTechnicalAccountsByMasterId(masterOpportunity.AccountId);

        return getTechnicalOpportunitiesByMasterId(masterOpportunity, technicalAccountsMap);
    }

    public static Map<String, Opportunity> getTechnicalOpportunitiesByMasterId(
        Id masterOpportunityId
    ) {
        Opportunity masterOpportunity = (Opportunity) new OpportunitySelector()
            .selectOpportunitiesByIds(new Set<Id> {
                masterOpportunityId
            })
            .selectFields(AquivaHelper.getAllFieldsForObject('Opportunity'))
            .executeQuery()
            .get(0);
        Map<String, Account> technicalAccountsMap = AccountHelper.getTechnicalAccountsByMasterId(masterOpportunity.AccountId);

        return getTechnicalOpportunitiesByMasterId(masterOpportunity, technicalAccountsMap);
    }

    public static Map<String, Opportunity> getTechnicalOpportunitiesByMasterId(
        Id masterOpportunityId,
        Map<String, Account> technicalAccountsMap
    ) {
        Opportunity masterOpportunity = (Opportunity) new OpportunitySelector()
            .selectOpportunitiesByIds(new Set<Id> {
                masterOpportunityId
            })
            .selectFields(AquivaHelper.getAllFieldsForObject('Opportunity'))
            .executeQuery()
            .get(0);
        return getTechnicalOpportunitiesByMasterId(masterOpportunity, technicalAccountsMap);
    }

    public static Map<String, Opportunity> getTechnicalOpportunitiesByMasterId(
        Opportunity masterOpportunity,
        Map<String, Account> technicalAccountsMap
    ) {
        List<Opportunity> technicalOpportunities = new OpportunitySelector()
            .selectServiceOpportunitiesByMasterId(masterOpportunity.Id)
            .executeQuery();
        Map<String, Opportunity> technicalOpportunitiesMap = new Map<String, Opportunity>();

        for (String service: technicalAccountsMap.keySet()) {
            Account acc = technicalAccountsMap.get(service);
            for (Opportunity opp: technicalOpportunities) {
                if (opp.AccountId == acc.Id && opp.MasterOpportunity__c == masterOpportunity.Id) {
                    technicalOpportunitiesMap.put(service, opp);
                }
            }
        }

        return technicalOpportunitiesMap;
    }
    public static Map<String, Opportunity> createTechnicalOpportunities(
        Id masterOpportunityId,
        List<String> services
    ) {
        Opportunity masterOpportunity = (Opportunity) new OpportunitySelector()
            .selectOpportunitiesByIdsWithAllFields(masterOpportunityId)
            .executeQuery()
            .get(0);
        Map<String, Account> technicalAccountsMap = AccountHelper.getTechnicalAccountsByMasterId(masterOpportunity.AccountId);

        return createTechnicalOpportunities(masterOpportunity, technicalAccountsMap, services);
    }

    public static Map<String, Opportunity> createTechnicalOpportunities(
        Opportunity masterOpportunity,
        List<String> services
    ) {
        Map<String, Account> technicalAccountsMap = AccountHelper.getTechnicalAccountsByMasterId(masterOpportunity.AccountId);

        return createTechnicalOpportunities(masterOpportunity, technicalAccountsMap, services);
    }

    public static Map<String, Opportunity> createTechnicalOpportunities(
        Id masterOpportunityId,
        Map<String, Account> technicalAccountsMap,
        List<String> services
    ) {
        Opportunity masterOpp = (Opportunity) new OpportunitySelector()
            .selectOpportunitiesByIdsWithAllFields(masterOpportunityId)
            .executeQuery()
            .get(0);

        return createTechnicalOpportunities(masterOpp, technicalAccountsMap, services);
    }

    private static Set<String> OPPORTUNITY_UNIQUE_FIELDS = SObjectDescribeHelper.getDescribe(Opportunity.getSObjectType()).getUniqueFieldNames();
    public static Map<String, Opportunity> createTechnicalOpportunities(
        Opportunity masterOpportunity,
        Map<String, Account> technicalAccountsMap,
        List<String> services
    ) {
        Map<String, Opportunity> technicalOpportunities = getTechnicalOpportunitiesByMasterId(masterOpportunity, technicalAccountsMap);
        User technicalUser = UserHelper.getMultiproductTechnicalUser();

        List<Opportunity> opportunitiesToCreate = new List<Opportunity>();
        for (String service: services) {
            if (!QuoteHelper.CREATE_TECHNICAL_ACCOUNT_FOR_SERVICES.contains(service)) {
                continue;
            }

            Account acc = technicalAccountsMap.get(service);

            if (!technicalOpportunities.containsKey(service)) {
                Account techAccount = technicalAccountsMap.get(service);
                Opportunity clonedOpp = masterOpportunity.clone(false, true, false, false);

                for (String field: OPPORTUNITY_UNIQUE_FIELDS) {
                    clonedOpp.put(field, null);
                }

                clonedOpp.MasterOpportunity__c = masterOpportunity.Id;
                clonedOpp.IsMultiProductTechnicalOpportunity__c = true;
                clonedOpp.AccountId = acc.Id;
                clonedOpp.Tier_Name__c = service;
                clonedOpp.Type = AccountHelper.isExistingBusiness(techAccount) ? OPPORTUNITY_TYPE_EX_BUSINESS : OPPORTUNITY_TYPE_NEW_BUSINESS;
                clonedOpp.RC_Account_Status__c = null;
                clonedOpp.Existing_Solution_Provider__c = 'No Existing Provider';
                clonedOpp.Total_Contract_Value_Override__c = null;
                clonedOpp.Name = OpportunityHelper.trimOpportunityNameIfTooLong(masterOpportunity.Name, service);

                if (technicalUser != null) {
                    clonedOpp.OwnerId = technicalUser.Id;
                }

                opportunitiesToCreate.add(clonedOpp);
            }
        }

        Map<String, Opportunity> result = new Map<String, Opportunity>();
        if(!opportunitiesToCreate.isEmpty()) {
            TriggerHandler.BY_PASS_OPPORTUNITY_ON_INSERT = true;
            insert opportunitiesToCreate;
            TriggerHandler.BY_PASS_OPPORTUNITY_ON_INSERT = false;

            for (Opportunity opp : opportunitiesToCreate) {
                result.put(opp.Tier_Name__c, opp);
            }
        }

        // part of incremental save.
        for (Opportunity opp : technicalOpportunities.values()) {
            if (!result.containsKey(opp.Tier_Name__c)) {
                result.put(opp.Tier_Name__c, opp);
            }
        }

        return result;
    }

    public static String trimOpportunityNameIfTooLong(String oppName, String service) {
        return String.format('{0} [system: {1}]', new List<Object> { oppName.abbreviate(83), service});
    }

    public static Boolean isMasterMultiProductOpportunity(String oppId) {
        return BooleanHelper.toBoolean(getIsMasterMultiproductOpportunities(new Set<Id>{oppId}).get(oppId));
    }

    public static Map<Id, Boolean> getIsMasterMultiproductOpportunities(Set<Id> oppIds) {
        // we need to check not only that Opportunity has technical opportunities
        // but also that primary quote has multiple products
        Map<Id, Boolean> oppIdToIsMaster = new Map<Id, Boolean>();
        Map<Id, Quote> oppIdtoPrimaryQuote = new Map<Id, Quote>();

        for (Opportunity opp : (List<Opportunity>) new OpportunitySelector()
                .newQueryFactory()
                .selectField(Opportunity.Id)
                .subselect(
                    new OpportunitySelector('Master_Opportunities__r', Opportunity.SObjectType)
                        .newQueryFactory()
                        .selectField(Opportunity.Id)
                )
                .setCondition('Id IN :bind0')
                .setQueryBindings(new List<Object> {
                    oppIds
                })
                .executeQuery()) {
            Boolean doesMasterOppExist = !opp.Master_Opportunities__r.isEmpty();
            oppIdToIsMaster.put(opp.Id, doesMasterOppExist);

            if (doesMasterOppExist) {
                oppIdtoPrimaryQuote.put(opp.Id, null);
            }
        }

        if (!oppIdtoPrimaryQuote.isEmpty()) {
            for (Quote q : (List<Quote>) new QuoteSelector()
                .selectPrimaryQuotes(new List<Id>(oppIdtoPrimaryQuote.keySet()))
                .executeQuery()
            ) {
                oppIdtoPrimaryQuote.put(q.OpportunityId, q);
            }
        }

        for (Id oppId : oppIdToIsMaster.keySet()) {
            Quote primaryQuote = oppIdtoPrimaryQuote.get(oppId);
            Boolean hasMultipleProducts = primaryQuote != null && QuoteHelper.isQuotePackageInfoHasMultipleProducts(primaryQuote);
            oppIdToIsMaster.put(oppId, oppIdToIsMaster.get(oppId) && hasMultipleProducts);
        }

        return oppIdToIsMaster;
    }

    public static String getTierName(Opportunity opp, Quote qt) {
        return shortTierNamesMap.get(opp?.Tier_Name__c) != null
            ? shortTierNamesMap.get(opp.Tier_Name__c)
            : shortTierNamesMap.get(
                new BillingWrappers.QuotePackageInfoWrapper(qt.Package_Info__c)
                    .getPackageInfo()
                    .productName
            );
    }

    public static String getShortTierNameByQuote(Quote qt) {
        if (String.isNotBlank(qt.ServiceName__c)) {
            return shortTierNamesMap.get(qt.ServiceName__c);
        }
        String productName = new BillingWrappers.QuotePackageInfoWrapper(qt.Package_Info__c).getPackageInfo().productName;
        return shortTierNamesMap.get(productName);
    }

    public static Response.ResponseMessage[] addTierNameToMessages(String tierName, Response.ResponseMessage[] messages) {
        for (Response.ResponseMessage message : messages) {
            message.message = tierName + ': ' + message.message;
        }
        return messages;
    }

    public static Boolean checkIsChangeOrderOrMigrationOpty(String oppName, Id parentOrderId) {
        return (oppName.toLowerCase().contains('change order')
            || oppName.toLowerCase().contains('migration')
            || parentOrderId != null);
    }

    public static void updateTechnicalOpportunities(Id masterOpportunityId, Map<String, BillingWrappers.QuoteWrapper> quotesByService) {
        List<Opportunity> opportunitiesToUpdate = getTechnicalQuotesForUpdate(masterOpportunityId, quotesByService);

        if(!opportunitiesToUpdate.isEmpty()) {
            TriggerHandler.BY_PASS_OPPORTUNITY_ON_UPDATE = true;
            update opportunitiesToUpdate;
            TriggerHandler.BY_PASS_OPPORTUNITY_ON_UPDATE = false;
        }
    }

    public static List<Opportunity> getTechnicalQuotesForUpdate(Id masterOpportunityId, Map<String, BillingWrappers.QuoteWrapper> quotesByService) {
        Opportunity masterOpportunity = (Opportunity) new ListOptional(new OpportunitySelector()
            .selectOpportunitiesByIdsWithAllFields(masterOpportunityId)
            .executeQuery()
        ).getFirst();

        Map<String, Account> technicalAccountsMap = AccountHelper.getTechnicalAccountsByMasterId(masterOpportunity?.AccountId);
        Map<String, Opportunity> technicalOpportunities = getTechnicalOpportunitiesByMasterId(masterOpportunity, technicalAccountsMap);

        List<Opportunity> opportunitiesToUpdate = new List<Opportunity>();
        for (String service: quotesByService.keySet()) {
            Opportunity opp = technicalOpportunities.get(service);
            if (opp != null) {
                opp.isTermination__c = quotesByService.get(service).isTermination;
                opportunitiesToUpdate.add(opp);
            }
        }
        return opportunitiesToUpdate;
    }

    public static void updatePartnerFieldsOnOppty(Id opportunityId, String partnerInfo) {
        PartnerOperationsHelper.PartnerInfo pInfo = (PartnerOperationsHelper.PartnerInfo) JSON.deserialize(partnerInfo, PartnerOperationsHelper.PartnerInfo.class);
        Account partnerAccount = AccountHelper.getPartnerAccountById(pInfo.id);
        if (partnerAccount == null) {
            throw new AquivaHelper.AquivaException('Partner Account is required');
        }

        if (partnerAccount.AccountContactRoles.isEmpty()) {
            throw new AquivaHelper.AquivaException('Partner Account Payable Contact Role is required');
        }

        Opportunity opp = new Opportunity(Id = opportunityId);
        opp.Partner_Account__c = partnerAccount.Id;
        opp.Partner_Contact__c = partnerAccount.AccountContactRoles.size() > 0 ? partnerAccount.AccountContactRoles[0].ContactId : partnerAccount.Partner_Contact__c;
        opp.Partner_ID__c = partnerAccount.Partner_ID__c;

        Triggers.switchOff();
        update opp;
        Triggers.switchOn();
    }

    public static Opportunity createRenewalOppty(Account acc, Id ownerId) {
        return (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.AccountId => acc.Id,
                Opportunity.Name => acc.Name + ' - ' + OPPORTUNITY_TYPE_RENEWAL,
                Opportunity.Type => OPPORTUNITY_TYPE_RENEWAL,
                Opportunity.Is_Billing_Opportunity__c => String.isNotBlank(acc.Billing_ID__c),
                Opportunity.ActiveAgreementOnRenewal__c => acc.Active_Sales_Agreement__c,
                Opportunity.CloseDate => acc.Active_Sales_Agreement__r.End_Date__c,
                Opportunity.Tier_Name__c => acc.Active_Sales_Agreement__r.Opportunity.Tier_Name__c,
                Opportunity.Brand_Name__c => acc.Active_Sales_Agreement__r.Opportunity.Brand_Name__c,
                Opportunity.Edition__c => acc.Active_Sales_Agreement__r.Opportunity.Edition__c,
                Opportunity.OwnerId => ownerId,
                Opportunity.StageName => STAGE_NAME_QUALIFY,
                Opportunity.ConfirmAndClose__c => false,
                Opportunity.CW_Categories_Who_did_we_beat__c => acc.Active_Sales_Agreement__r.Opportunity.CW_Categories_Who_did_we_beat__c,
                Opportunity.CW_Categories_Who_did_we_replace__c => acc.Active_Sales_Agreement__r.Opportunity.CW_Categories_Who_did_we_replace__c,
                Opportunity.CW_Primary_Win_Reason__c => acc.Active_Sales_Agreement__r.Opportunity.CW_Primary_Win_Reason__c,
                Opportunity.CW_Secondary_Win_Reason__c => acc.Active_Sales_Agreement__r.Opportunity.CW_Secondary_Win_Reason__c,
                Opportunity.CW_Who_did_we_beat__c => acc.Active_Sales_Agreement__r.Opportunity.CW_Who_did_we_beat__c,
                Opportunity.CW_Who_did_we_replace__c => acc.Active_Sales_Agreement__r.Opportunity.CW_Who_did_we_replace__c,
                Opportunity.CW_Win_Reason_Awards__c => acc.Active_Sales_Agreement__r.Opportunity.CW_Win_Reason_Awards__c,
                Opportunity.CW_Win_Reason_Features__c => acc.Active_Sales_Agreement__r.Opportunity.CW_Win_Reason_Features__c,
                Opportunity.CW_Win_Reason_Integrations__c => acc.Active_Sales_Agreement__r.Opportunity.CW_Win_Reason_Integrations__c,
                Opportunity.CW_Win_Reason_Savings__c => acc.Active_Sales_Agreement__r.Opportunity.CW_Win_Reason_Savings__c,
                Opportunity.Primary_Opportunity_Contact__c => acc.Active_Sales_Agreement__r.Opportunity.Primary_Opportunity_Contact__c,
                Opportunity.Avaya_Partnership_Opportunity__c => true
            })
            .build()
            .getRecord();
    }

    public static Opportunity getMasterOpportunity(Opportunity opp) {
        return opp.isMultiproductTechnicalOpportunity__c ? opp.MasterOpportunity__r : opp;
    }

    public static Boolean isOpportunityInvalid(Opportunity opp) {
        Boolean isInvalid = false;

        Feature_Toggle__c featureToggle = Feature_Toggle__c.getInstance();
        if (!featureToggle.DisableUQTLandingPage__c) {
            return isInvalid;
        }

        if (!String.isBlank(opp.Brand_Name__c)) {
            LeadConversionConfiguration__c config = LeadConversionConfiguration__c.getAll().get(opp.Brand_Name__c);
            Boolean isNGBS = (config != null) ? config.isNGBS__c : false;
            isInvalid = String.isBlank(opp.BusinessIdentity__c) && isNGBS;
        }

        return isInvalid;
    }

    public static String getOpportunityBIName(Opportunity opp) {
        String oppBIName = '';
        if (String.isBlank(opp?.BusinessIdentity__c)) {
            return oppBIName;
        }
        BillingWrappers.QuoteBusinessIdentity bi = (BillingWrappers.QuoteBusinessIdentity) JSON.deserialize(opp.BusinessIdentity__c, BillingWrappers.QuoteBusinessIdentity.class);
        List<PackageBusinessIdentityMapping__c> pbiMap = PackageBusinessIdentityMapping__c.getAll().values();
        for (PackageBusinessIdentityMapping__c item : pbiMap) {
            if (item.Active__c && item.BiId__c == bi.biId) {
                oppBIName = item.BiName__c;
                break;
            }
        }
        return oppBIName;
    }

    public static String getOpportunityBi(String biValue) {
        Map<String, String> businessIdentityMap = (Map<String, String>) JSON.deserialize(biValue, Map<String, String>.class);
        return businessIdentityMap.get('biId');
    }

    public static Boolean isRiseBrand(Opportunity opp) {
        return opp != null
            && opp.Brand_Name__c != null
            && RISE_BRANDS.contains(opp.Brand_Name__c);
    }

    public static Opportunity getPSChangeOrderOpportunityRecord(Id orderId) {
        return (Opportunity) new ListOptional(new OpportunitySelector()
            .selectChangeOrderOpportunityByOrderId(orderId)
            .executeQuery()
            ).getFirst();
    }

    public static void processDeliveredProserv(List<Id> quoteIds) {
        List<Quote> quotesToProcess = getQuotesForDeliveredProserv(quoteIds);

        Triggers.switchOff();
        processDeliveredSuborders(quotesToProcess);
        processDeliveredOrders(quotesToProcess);
        Triggers.switchOn();
        processDeliveredPackages(quoteIds);
    }

    private static void processDeliveredSuborders(List<Quote> quotesToProcess) {
        Set<Id> orderIds = new Set<Id>();
        for (Quote quote : quotesToProcess) {
            orderIds.add(quote.Opportunity.Parent_Order__c);
        }

        List<Suborder__c> subordersToUpdate = new List<Suborder__c>();
        List<Suborder__c> suborders = (List<Suborder__c>) new SuborderSelector()
            .selectSubordersByOrdersIds(orderIds)
            .executeQuery();

        if (suborders.isEmpty()) {
            return;
        }

        for (Suborder__c suborder : suborders) {
            if (suborder.Status__c != SuborderHelper.STATUS_BILLED) {
                suborder.Status__c = SuborderHelper.STATUS_CANCELED;
                subordersToUpdate.add(suborder);
            }
        }
        update subordersToUpdate;
    }

    private static void processDeliveredOrders(List<Quote> quotesToProcess) {
        List<Order> orders = new List<Order>();

        for (Quote quote : quotesToProcess) {
            Order order = (Order) new SObjectBuilder(Order.sObjectType)
                .setFields(new Map<SObjectField, Object> {
                    Order.Id => quote.Opportunity.Parent_Order__c,
                    Order.Status => OrderHelper.STATUS_COMPLETED
                })
                .build()
                .getRecord();
            orders.add(order);
        }

        update orders;
    }

    @future(callout=true)
    private static void processDeliveredPackages(List<Id> quoteIds) {
        List<Quote> quotesToProcess = getQuotesForDeliveredProserv(quoteIds);
        List<Package__c> packagesToUpdate = new List<Package__c>();

        for (Quote quote : quotesToProcess) {
            if (String.isBlank(quote.Package_Info__c)) {
                continue;
            }

            BillingWrappers.QuotePackageInfo pInfo = (BillingWrappers.QuotePackageInfo)
                JSON.deserialize(
                    quote.Package_Info__c.substring(1, quote.Package_Info__c.length() - 1),
                    BillingWrappers.QuotePackageInfo.class
                );

            if (String.isBlank(pInfo?.packageInfo?.id)) {
                continue;
            }

            HttpResponse response;
            String accountBillingId = quote.Account.Billing_ID__c;
            String billingPackageId = pInfo.packageInfo.id;
            try {
                response = NGBSAPI.updatePackageStatus(accountBillingId, billingPackageId, PackageHelper.PACKAGE_STATUS_DELETED);
            } catch (Exception e) {
                PlatformLog.logException('Package Status Update', e);
            }

            if (response?.getStatusCode() == 200) {
                Package__c pkg = (Package__c) new SObjectBuilder(Package__c.sObjectType)
                    .setFields(new Map<SObjectField, Object> {
                        Package__c.Id => quote.BillingPackage__c,
                        Package__c.Package_Status__c => PackageHelper.PACKAGE_STATUS_DELETED
                    })
                    .build()
                    .getRecord();
                packagesToUpdate.add(pkg);
            }
        }
        if (!packagesToUpdate.isEmpty()) {
            update packagesToUpdate;
        }
    }

    private static List<Quote> getQuotesForDeliveredProserv(List<Id> quoteIds) {
        return (List<Quote>) new QuoteSelector()
            .selectQuotesForDeliveredProducts(new List<Object>{ quoteIds, TIER_PROFESSIONAL_SERVICES })
            .executeQuery();
    }

    public static String CheckIfOpportunityGPAAdherent(String siaContractInfo, List<CampaignInfluence> oppCampaignInfluences) {
        String message = '';
        Boolean isSIAInfoPresent = String.IsNotBlank(siaContractInfo);
        Boolean isSalesPurchasingCampaignPresent = false;

        for (CampaignInfluence ci : oppCampaignInfluences) {
            if (ci.Campaign.Name.startsWith('Sales_Purchasing')) {
                isSalesPurchasingCampaignPresent = true;
                break;
            }
        }
        if (isSIAInfoPresent && isSalesPurchasingCampaignPresent) {
            message =  SUCCESS_MSG;
        } else if (!isSIAInfoPresent && !isSalesPurchasingCampaignPresent) {
            message =  System.Label.GPA_Contract_Tagging_SIA_Info_and_Campaign_Missing_ErrorMsg;
        } else if (isSIAInfoPresent && !isSalesPurchasingCampaignPresent) {
            message =  System.Label.GPA_Contract_Tagging_Campaign_Missing_Error_Msg;
        } else if (!isSIAInfoPresent && isSalesPurchasingCampaignPresent) {
            message =  System.Label.GPA_Contract_Tagging_SIA_Information_Missing_Error_Msg;
        }
        return message;
    }

    public static Boolean doesUserProfileHaveGPAValidation() {
        List<String> profileIDsList = new List<String>();
        for (GPA_Validation_Profiles__mdt listOfProfileIds : [SELECT Profile_ID__c FROM GPA_Validation_Profiles__mdt]) {
            profileIDsList.addAll(listOfProfileIds.Profile_ID__c.split(','));
        }
        return profileIDsList.contains(UserInfo.getProfileId());
    }

    @TestVisible
    public static String GPOContractValidation(Opportunity Opp) {
        Integer prevClosedOpptyCount = 0;
        String result = '';
        prevClosedOpptyCount = [ SELECT COUNT()
                                 FROM Opportunity
                                 WHERE AccountId = :Opp.AccountId AND
                                       StageName IN :STAGE_NAMES_CLOSED
        ];
        if (prevClosedOpptyCount == 0) {
            Opportunity oppRecord = [ SELECT Id, Type, Account.SIA_Information__c,
                                        (SELECT Id, OpportunityId, Campaign.Id, Campaign.Name
                                         FROM CampaignInfluences)
                                      FROM Opportunity
                                      WHERE Id = :Opp.Id
            ];
            result = CheckIfOpportunityGPAAdherent(oppRecord.Account.SIA_Information__c, oppRecord.CampaignInfluences);
        } else {
            result = SUCCESS_MSG;
        }
        return result;
    }

    public static Boolean isProServChangeOrderOpportunity(Opportunity opp) {
        return isProServChangeOrderOpportunity(opp.Parent_Order__c, opp.Tier_Name__c);
    }

    public static Boolean isProServChangeOrderOpportunity(Id parentOrderId, String tierName) {
        return parentOrderId != null && tierName == QuoteHelper.NGBS_PROFESSIONAL_SERVICES_PRODUCT;
    }

    public static List<String> getPartnersBrandList() {
        List<String> partnersBrandList = new List<String>();
        for (Brand_List__c GSPBrand : Brand_List__c.getall().values()) {
            partnersBrandList.add(GSPBrand.Brand_Name__c);
        }
        return partnersBrandList;
    }
}