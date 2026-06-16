/*
* Name         : SignUpCustomers
* Created By   : Fedor Golovanov (fgolovanov@newmarketinc.com)
* Created Date : 06/March/2016
* Description  : B-53 (Sprint 5 Moscow). Refactor SingUp process to use new data model. B-111 (Sprint 7 Moscow) Use old functionality for Pro and Fax Service Plans and Redirect to Old Page.
* Dependencies : No
*/
global class SignUpCustomers {
    public static String creditCard;
    public static String invoice;
    public static Opportunity opp;

    public static String AID;
    public static String BMID;
    public static String PID;
    public static String SPID;
    public static String tabName;
    public static String errorMsg;
    public static String billtype;

    public static String partnerID;
    public static String productName;
    public static String contactName;
    public static String currencySign;
    public static String salesAgentId;
    public static String salesAgentName;
    public static String salesAgentProfileName;

    public static Boolean isError;
    public static Boolean lineItemExists;
    public static Boolean contactIdCodesNotSetUp;

    public static OpportunityContactRole oppContactRole;

    public static GWFunnelWrapper.paramWrapper paramObj;

    public static QuoteLineItem item;
    public static List<QuoteLineItem> lineItems;

    public static Case relatedCase;

    public static List<Account> accsToUpdateFunnelNotSupported;
    public static Package__c packageToProcess;

    // PriceBook
    private static final String GOOGLE_APPS_EDITION = 'Google Apps';
    private static final String RINGCENTRAL_BRAND_NAME = 'RingCentral';
    private static final String RINGCENTRAL_CANADA_BRAND_NAME = 'RingCentral Canada';

    private static Opportunity getOpptyRecord(Id oppId) {
        Id qtId = null;

        List<Quote> optyQuotes = [
            SELECT Id, IsPrimary__c, LastModifiedDate, RecordTypeId,
                Opportunity.Is_Billing_Opportunity__c
            FROM Quote
            WHERE OpportunityId = :oppId
        ];

        if (optyQuotes.size() > 0)  {
            Quote primary = QuoteHelper.getPrimaryQuote(optyQuotes, optyQuotes[0].Opportunity.Is_Billing_Opportunity__c);
            if (primary != null) {
                qtId = primary.Id;
            }
        }

        Opportunity oppty = [
                SELECT Id, Primary_Opportunity_Contact__c, Account_DLS__c, Tier_Name__c, CurrencyIsoCode, Name,
                        Brand_Name__c, PriceBook2.Name, StageName, PID__c, AD__c, Adgrpid__c, AFN__c, AID__c, BMID__c,
                        KID__c, OID__c, PRODUCT__c, RCKW__c, RCMT__c, SID__c, CampaignId, Partner_ID__c, AccountId,
                        Account.Name, Account.BillingPostalCode, Account.BillingCountry, Account.BillingState,
                        Account.BillingCity, PaymentType__c, Account.BillingStreet,
                        Account.Payment_Method__c, Account.SignupType__c, Account.Number_of_POC_Users__c,
                        Account.Tax_Exempt__c, Enable_Cost_Center_Management__c, PriceBook2.Service__c, RecordTypeId,
                (
                        SELECT Id, Name, QuoteNumber, Discount, Status, Approved_Status__c, Account_Number_of_Lines__c,
                                Upsell_Status__c, PriceBook2.Name, PriceBook2.Service__c, PriceBook2.Tier_ID__c,
                                PriceBook2.Plan__c, Pricebook2.Brand__r.Name, Pricebook2.Edition__c,
                                Total_Number_of_Digital_Lines__c, Products__c, Main_Vanity_Number__c, AreaCode__c,
                                AreaCode__r.Name, AreaCode__r.Type__c, AreaCode__r.City__c, AreaCode__r.Country__c,
                                Fax_Vanity_Number__c, FaxAreaCode__c, FaxAreaCode__r.Name, FaxAreaCode__r.Type__c,
                                FaxAreaCode__r.City__c, FaxAreaCode__r.Country__c, Credit_Amount__c, Free_Service_Taxes__c
                        FROM Quotes
                        WHERE id = :qtId
                        LIMIT 1
                ), (
                        SELECT Id, ContactId, Role, IsPrimary
                        FROM OpportunityContactRoles
                        WHERE (IsPrimary = true OR Role = 'Administrator')
                        ORDER BY LastModifiedDate DESC
                )
                FROM Opportunity
                WHERE id = :oppId
        ];
        return oppty;
    }

    public static Profile getSalesAgentProfile(Id userProfileId){
        return [SELECT Id, Name FROM Profile WHERE Id =: userProfileId];
    }

    public static Package__c getPackageToProcess(Id accId){
        List<Package__c> packages = new PackageSelector()
            .selectPackagesForNewReferences(new List<Object> {new Set<Id> {accId}})
            .executeQuery();
        List<Package__c> packagesToProcess = PackageHelper.filterPackagesByCreatedDateAndService(packages);
        if (packagesToProcess.isEmpty()){
            return null;
        }
        return packagesToProcess[0];
    }

    webservice static String proccessData(Id oppId){
        //initialize defaults
        creditCard = 'CC';
        invoice = 'INV';
        contactIdCodesNotSetUp = false;
        lineItemExists = false;
        relatedCase = new Case();
        contactName= '';
        lineItems = new List<QuoteLineItem>();

        opp = new Opportunity();

        opp = getOpptyRecord(oppId);

        packageToProcess = getPackageToProcess(opp.AccountId);

        Schema.DescribeSObjectResult result = Opportunity.SObjectType.getDescribe();
        Map<ID,Schema.RecordTypeInfo> rtMapById = result.getRecordTypeInfosById();
        //Use old functionality for Pro and Fax Service Plans and Redirect to Old Page #B-111
        //#B-366 Don't show a VisualForce Page with list of available Service Plans when Service Plan with Brand == "RingCentral Canada" and Service == "Office" is being Signed up.
        //#B-479 Don't show a VisualForce Page with list of available Service Plans when Service Plan with Brand == "RingCentral UK" and Service == "Office" is being Signed up.
        if (rtMapById.get(opp.RecordTypeId).getName().containsIgnoreCase('var') &&
            !(opp.Brand_Name__c.containsIgnoreCase('ringcentral') && opp.Quotes[0].PriceBook2.Service__c == 'Office')){
            return redirectSignUpVARFaxOrEnterprise(opp.Id);
        }

        if ((opp.Quotes != null && opp.Quotes.size() > 0 &&
            (opp.Quotes[0].PriceBook2.Service__c != 'Office' ||
                (opp.Quotes[0].PriceBook2.Service__c == 'Office' &&
                    (opp.Brand_Name__c != 'RingCentral' && opp.Brand_Name__c !='RingCentral Canada' && opp.Brand_Name__c != 'RingCentral UK' && opp.Brand_Name__c != 'RingCentral EU' && opp.Brand_Name__c != 'RingCentral AU'))))){
            return redirectSignUpFaxOrEnterprise(opp.Id);
        }

        salesAgentId = userInfo.getUserId();
        salesAgentName = userInfo.getName();
        salesAgentProfileName = getSalesAgentProfile(userInfo.getProfileId()).Name;

        SPID = [SELECT PID__c FROM User WHERE Id =: UserInfo.getUserId()].PID__c;

        if(opp != null) {
            String brandName = String.isNotBlank(opp.Brand_Name__c) ? opp.Brand_Name__c : 'RingCentral US';
            tabName = brandName.containsIgnoreCase('CAN') ? 'CAN' : (brandName.containsIgnoreCase('UK') ? 'UK' : 'US');
        }

        setSignUpParams();
        setSignUpProducts();
        return sendToSalesFunnel();
    }

    /**
     * Set Marketing params BMID, AID etc...
     */
    @TestVisible
    private static void setSignUpParams() {
        if(String.isNotBlank(opp.Partner_ID__c)) {
            PartnerID = opp.Partner_ID__c;
        }
        // Check Opportunity fields to see if we can use for attribution
        if(String.isNotBlank(opp.BMID__c) && String.isNotBlank(opp.PID__c)) {
            // all attribution fields are filled in
            BMID = opp.BMID__c;
            PID = opp.PID__c;
            AID = opp.AID__c;
        } else if(String.isNotBlank(opp.BMID__c) && String.isBlank(opp.PID__c)) {
            // only BMID field is filled in
            BMID = opp.BMID__c;
            PID = opp.PID__c;
            AID = opp.AID__c;
        } else if(String.isBlank(opp.BMID__c) && String.isNotBlank(opp.PID__c)) {
            // only PID field is filled in
            BMID = opp.PID__c;
            PID = '';
            AID = opp.AID__c;
        } else if(opp.CampaignId != null) {
            // even if AID has a value RC will not use it for attribution so skip to checking for campaign attribution
            // use campaign from primary campaign source field
            try {
                Campaign c = [SELECT Name,DNIS__c,AID__c,PID__c,BMID__c FROM Campaign WHERE id=:opp.CampaignId];
                system.debug('this is campaign name: ' + c.name + '. This is BMID/PID/AID: ' + c.BMID__c + '/' + c.PID__c + '/' + c.AID__c);

                if(String.isBlank(c.BMID__c)){
                    if(String.isBlank(c.PID__c)){
                        BMID = '';
                        PID = '';
                    } else {
                        BMID = c.PID__c;
                        PID = c.PID__c;
                    }
                } else {
                    BMID = c.BMID__c;
                    if(String.isBlank(c.PID__c)){
                        PID = '';
                    } else{
                        PID = c.PID__c;
                    }
                }
                AID = c.AID__C;
            } catch(System.Exception e){ }
        }
        if(AID == null){
            AID = '';
        }
    }

    @TestVisible
    private static String populateStype(String sType) {

        String r = '';

        if(sType != null) {

            if(sType.containsIgnoreCase('30')) {

                r = (sType.containsIgnoreCase('trial') && sType.containsIgnoreCase('nocc') ?
                    'trial_30nocc':
                    (sType.containsIgnoreCase('trial') && sType.containsIgnoreCase('cc') ?
                        'trial30' : 'buy'
                    )
                );

            }else if(sType.containsIgnoreCase('15')) {

                r = (sType.containsIgnoreCase('trial') && sType.containsIgnoreCase('nocc') ?
                    'trial15':
                    (sType.containsIgnoreCase('trial') && sType.containsIgnoreCase('cc') ?
                        'trial15' : 'buy'
                    )
                );

            }else{

                r = (sType.containsIgnoreCase('trial') && sType.containsIgnoreCase('nocc') ?
                    'trial_30nocc':
                    (sType.containsIgnoreCase('trial') && sType.containsIgnoreCase('cc') ?
                        'trial30' : 'buy'
                    )
                );

            }

        }else{
            r = 'buy';
        }

        return r;
    }

    private static void setSignUpProducts() {
        Quote relatedQuote = new Quote();
        item = new QuoteLineItem();

        if((opp.CurrencyIsoCode=='USD') || (opp.CurrencyIsoCode=='CAD') || (opp.CurrencyIsoCode=='AUD')){
            currencySign = '$';
        } else if(opp.CurrencyIsoCode=='GBP'){
            currencySign = '&pound;';
        } else if(opp.CurrencyIsoCode=='EUR'){
            currencySign = '&euro;';
        } else {
            currencySign = '$';
        }

        paramObj = new GWFunnelWrapper.paramWrapper();

        if(opp.Quotes!=null && opp.Quotes.size()>0) {
            relatedQuote = opp.Quotes[0];
            paramObj.setTaxExempt = relatedQuote.Pricebook2.Service__c == 'Office' ? true : false;
            paramObj.products = relatedQuote.Products__c;
            boolean lineItemFound = false;
            for(QuoteLineItem qli : [SELECT Id,
                QuoteId,
                Quote.AccountId,
                Quote.Account.Funnel_not_supported__c,
                UnitPrice,
                Quantity,
                TotalPrice,
                CurrencyIsoCode,
                Discount,
                Discount_number__c,
                Discount_Type__c,
                Product2Id,
                Product2.Name,
                Product2.Family,
                Product2.GOA_Group__c,
                Product2.ProductCode,
                Product2.Feature__c,
                Product2.Sub_Feature__c,
                Product2.Charge_Term__c,
                Product2.Sub_Category__c,
                Quote.OpportunityId,
                Quote.ActiveAgreementYears__c,
                Quote.AreaCode__c,
                Quote.AreaCode__r.Name,
                Quote.AreaCode__r.Type__c,
                Quote.AreaCode__r.City__c,
                Quote.AreaCode__r.Country__c,
                Quote.Total_Number_of_Digital_Lines__c,
                Quote.isPrimary__c,
                PriceBookEntry.PriceBook2.Tier_ID__c,
                    (SELECT Id,
                            Quantity__c,
                            Area_Code__c,
                            Area_Code__r.Name,
                            Area_Code__r.Type__c,
                            Area_Code__r.City__c,
                            Area_Code__r.Country__c
                    FROM Area_Code_Line_Items__r)
                    //WHERE (Quote_Line_Item__r.Product2.Feature__c = 2 OR Quote_Line_Item__r.Product2.Feature__c = 3))
            FROM QuoteLineItem
            WHERE QuoteId=:relatedQuote.Id]) {
                paramObj.lineItemsList.add(qli);
                if(qli.Product2.Family == 'Tier' || qli.Product2.Family == 'Service'){
                    productname = qli.Product2.Name;
                    lineItemFound = true;
                }
            }
        }

        String contactId='';
        if(opp.opportunityContactRoles!=null && opp.opportunityContactRoles.size() > 0){
            for(OpportunityContactRole roleObj : opp.opportunityContactRoles){
                contactId=roleObj.ContactId;
                if(roleObj.role=='Administrator'){
                    break;
                }
            }
        }

        if(string.isBlank(contactId) || relatedQuote.FaxAreaCode__c == NULL ||  relatedQuote.AreaCode__c == NULL ){
            contactIdCodesNotSetUp = true;
        }

        if(string.isNotBlank(contactId)){
            Contact conObj = [SELECT id,FirstName,LastName,Phone,Email,Name FROM Contact WHERE ID=:contactId];
            paramObj.firstName = conObj.FirstName;
            paramObj.lastName = conObj.LastName;
            paramObj.email = conObj.Email;
            paramObj.phone = conObj.Phone;
            //#B-479  Only for "RingCentral UK" brand we should send location field in the contactInfo.
            // B-1411  For "RingCentral EU" brand we should send location field in the contactInfo too.
            if (opp.Brand_Name__c == 'RingCentral UK' || opp.Brand_Name__c == 'RingCentral EU') {
                paramObj.location = relatedQuote.AreaCode__r.City__c;
            }
            relatedCase.ContactId = conObj.id;
            contactName = conObj.Name;
        }

        paramObj.approvalId = (relatedQuote.Approved_Status__c == 'Approved' && (relatedQuote.Discount > 0 || (relatedQuote.PriceBook2.Plan__c != null ? relatedQuote.PriceBook2.Plan__c.deleteWhitespace() : '') == 'Monthly-Contract')) ? relatedQuote.QuoteNumber : '';
        paramObj.companyName = opp.Account.Name;
        paramObj.PARTNERID = opp.Partner_ID__c;
        paramObj.tierId = string.valueOf(relatedQuote.PriceBook2.Tier_ID__c);
        paramObj.SPID = SPID;
        paramObj.OPPID = opp.id;
        paramObj.PID = PID;
        paramObj.BMID = BMID;
        paramObj.brandName = opp.Brand_Name__c;

        // Getting existing Lock Funnel For Non Admins Org Settings
        Boolean lockFunnelForNonAdmin = false;
        Lock_Sales_Funnel_Settings__c settings = Lock_Sales_Funnel_Settings__c.getOrgDefaults();
        if(settings != null && settings.Lock_Funnel_for_non_Admins__c != null){
            lockFunnelForNonAdmin = settings.Lock_Funnel_for_non_Admins__c;
        }
		//EU phase 3 Changes - START
        List<String> allProfValues=new List<String>();//--------- created for storing Admin, Deal desk, sales and their EU restricted profiles
        List<EU_Component_Reference__mdt> euComp = [Select Values__c from EU_Component_Reference__mdt where Apex_Classes__c like '%SignUpCustomers%' and DeveloperName = 'SignUpCustomers'];
        for(EU_Component_Reference__mdt e:euComp){
            if(String.isNotBlank(e.Values__c)){
                allProfValues.addAll(e.Values__c.split(','));
                    }
            }
        //paramObj.isAdmin = (lockFunnelForNonAdmin ? ((salesAgentProfileName == 'System Administrator' ||  salesAgentProfileName == 'Sales Manager - Business Processing' || salesAgentProfileName == 'Sales Operations Lightning'|| salesAgentProfileName=='Deal Desk Lightning') ? true : false) : true);
		 paramObj.isAdmin = (lockFunnelForNonAdmin ? (allProfValues.contains(salesAgentProfileName) ? true : false) : true);
         //EU Phase 3 Changes - END
        Map <String, String> mapWithTierTypeAndSafid = getTierTypeAndSAFIDByTierId(relatedQuote.Pricebook2.Tier_ID__c);
        paramObj.TIERTYPE = mapWithTierTypeAndSafid.get('TierType');
        if (String.isNotBlank(mapWithTierTypeAndSafid.get('SAFID'))) {
            paramObj.SAFID = mapWithTierTypeAndSafid.get('SAFID');
        }

        //Populate accountNumbers array
        paramObj.mainAreaCode = (relatedQuote.AreaCode__r.Type__c == 'Local' ? Integer.ValueOf(relatedQuote.AreaCode__r.Name) : null);
        paramObj.mainAreaCity = relatedQuote.AreaCode__r.City__c;
        paramObj.mainAreaCountry = relatedQuote.AreaCode__r.Country__c;
        paramObj.mainAreaFreePrefix = (relatedQuote.AreaCode__r.Type__c == 'Toll-Free' ? relatedQuote.AreaCode__r.Name : null);
        paramObj.mainAreaCodePaymentType = getPaymentType(relatedQuote.AreaCode__r.Type__c, relatedQuote.Main_Vanity_Number__c);

        // B-3278 Fax Area code is not available in Google Service Plans
        Boolean shouldIncludeFaxAreaCode = !(GOOGLE_APPS_EDITION.equalsIgnoreCase(relatedQuote.PriceBook2.Edition__c)
                && new Set <String> {
                        RINGCENTRAL_BRAND_NAME,
                        RINGCENTRAL_CANADA_BRAND_NAME
                   }.contains(relatedQuote.PriceBook2.Brand__r.Name) );

        paramObj.shouldIncludeFaxAreaCode = shouldIncludeFaxAreaCode;
        if (shouldIncludeFaxAreaCode) {
            paramObj.faxAreaCode = (relatedQuote.FaxAreaCode__r.Type__c == 'Local' ? Integer.ValueOf(relatedQuote.FaxAreaCode__r.Name) : null);
            paramObj.faxAreaCity = relatedQuote.FaxAreaCode__r.City__c;
            paramObj.faxAreaCountry = relatedQuote.FaxAreaCode__r.Country__c;
            paramObj.faxAreaFreePrefix = (relatedQuote.FaxAreaCode__r.Type__c == 'Toll-Free' ? relatedQuote.FaxAreaCode__r.Name : null);
            paramObj.faxAreaCodePaymentType = getPaymentType(relatedQuote.FaxAreaCode__r.Type__c, relatedQuote.Fax_Vanity_Number__c);
        }

        Integer feature17Limit = GWFunnelWrapper.getFunnelLimitForFeature17();

        if(string.isNotBlank(paramObj.PARTNERID)){
            paramObj.Qty_lines = (relatedQuote.Total_Number_of_Digital_Lines__c != null ? Integer.valueOf(relatedQuote.Total_Number_of_Digital_Lines__c) : 0);

            // if funnel limit == -1 - it is mean there is no limit
            if(feature17Limit == -1) {
                paramObj.Qty_lines = paramObj.Qty_lines;
            }else{
                paramObj.Qty_lines = (paramObj.Qty_lines > feature17Limit ? feature17Limit : paramObj.Qty_lines );
            }
            paramObj.numberOfLines = String.valueOf(paramObj.Qty_lines);
        } else {
            paramObj.Sa_lines = (relatedQuote.Total_Number_of_Digital_Lines__c != null ? Integer.valueOf(relatedQuote.Total_Number_of_Digital_Lines__c) : 0);

            // if funnel limit == -1 - it is mean there is no limit
            if(feature17Limit == -1) {
                paramObj.Sa_lines = paramObj.Sa_lines;
            }else{
                paramObj.Sa_lines = (paramObj.Sa_lines > feature17Limit ? feature17Limit : paramObj.Sa_lines );
            }
            paramObj.numberOfLines = String.valueOf(paramObj.Sa_lines);
        }

        if(!string.isBlank(opp.Account.Payment_Method__c) && opp.Account.Payment_Method__c == 'Invoice') {
            billtype = invoice;
        } else {
            billtype = creditCard;
        }

        paramObj.billtype = billType;
        paramObj.contract = (String.isNotBlank(relatedQuote.PriceBook2.Plan__c) && (relatedQuote.PriceBook2.Plan__c.containsIgnoreCase('contract') || relatedQuote.PriceBook2.Plan__c.containsIgnoreCase('annual')) ? true : false);
        String sType = packageToProcess != null ? packageToProcess?.SignupType__c : null;
        //paramObj.action = (sType != null && sType.containsIgnoreCase('trial') && sType.containsIgnoreCase('nocc') ? 'trial_30nocc': (sType != null && sType.containsIgnoreCase('trial') && sType.containsIgnoreCase('cc') ? 'trial30' : 'buy'));
        paramObj.action = populateStype(sType);
        paramObj.annual = (relatedQuote.PriceBook2.Plan__c!=null && relatedQuote.PriceBook2.Plan__c=='Annual' ? true : false);
        paramObj.OID = opp.OID__c;
        paramObj.bc = (opp.Enable_Cost_Center_Management__c ? '1' : '0');
        paramObj.salesAgentId = salesAgentId;
        paramObj.salesAgentName = salesAgentName;
        paramObj.shippingAddressLine1 = opp.Account.BillingStreet;
        paramObj.shippingCountry = opp.Account.BillingCountry;
        paramObj.shippingState = opp.Account.BillingState;
        paramObj.shippingCity = opp.Account.BillingCity;
        paramObj.shippingZipCode = opp.Account.BillingPostalCode;
        paramObj.accountName = opp.Account.Name;
        paramObj.taxExempt = opp.Account.Tax_Exempt__c ? 'true' : 'false';
        if(string.isNotBlank(paramObj.PARTNERID)){
            paramObj.qty =  paramObj.Qty_lines;
        }else{
            paramObj.qty = paramObj.Sa_lines;
        }
        //Calculate freeServiceCredit
        Double creditAmount = relatedQuote.Credit_Amount__c != null ? relatedQuote.Credit_Amount__c : 0;
        Double freeServiceTaxes = relatedQuote.Free_Service_Taxes__c != null ? relatedQuote.Free_Service_Taxes__c : 0;
        paramObj.freeServiceCredit = creditAmount + freeServiceTaxes;
    }

    public static Map<String, String> getTierTypeAndSAFIDByTierId(String tierId) {
        //returning tierType as String and setting up paramObj.SAFID
        Map <String, String> resultMap = new Map<String, String>();
        resultMap.put('TierType', '');
        resultMap.put('SAFID', '');
        List<TierTypeSetting__c> tierTypeSettingsList = TierTypeSetting__c.getAll().values();
        if (tierTypeSettingsList.size() > 0) {
            for (TierTypeSetting__c tts : tierTypeSettingsList) {
                if (tts.TierId__c == tierId) {
                    String returnedTierType = String.valueOf(Integer.valueOf(tts.TierType__c));
                    resultMap.put('TierType', returnedTierType);
                    String safidToPut = String.valueOf(Integer.valueOf(tts.Safid__c));
                    resultMap.put('SAFID', safidToPut);
                }
            }
        }
        return resultMap;
    }

    @TestVisible
    private static String getPaymentType(String areaCodeType, Boolean isVanity){
        if(isVanity){
            areaCodeType = 'Vanity';
        }

        if(!String.isBlank(areaCodeType)){
           areaCodeType = areaCodeType.remove('-');
        }

        return areaCodeType;
    }

    private static void updateAccFunnelNotSupported() {

        if(accsToUpdateFunnelNotSupported != null && accsToUpdateFunnelNotSupported.size() > 0) {
            update accsToUpdateFunnelNotSupported;
        }
    }

    /**
     * Sends Sign Up Request to General Web Sales Funnel
     */
    public static string sendToSalesFunnel() {
        // Getting existing Sign Up Org Settings
        Sign_Up_Settings__c settings = Sign_Up_Settings__c.getOrgDefaults();
        // Getting feature toggle custom setting
        Feature_Toggle__c featureToggle = Feature_Toggle__c.getInstance();
        // Checking if Sign Up Link is set, setting it to test environment otherwise
        if(settings.Sign_Up_Link__c == null){
            settings.Sign_Up_Link__c = 'http://devorigin101.secure.ringcentral.com/api/projects/ws/index.php';
        }
        GWFunnelWrapper gwFunnelWrapperObject = new GWFunnelWrapper();
        String JSONResponse = gwFunnelWrapperObject.createJSONRequest(paramObj);
        HttpRequest request = new HttpRequest();
        request.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        request.setEndpoint(settings.Sign_Up_Link__c);
        request.setMethod('POST');
        request.setBody(
            'SPID=' + paramObj.SPID +
                '&OPPID=' + opp.Id +
                '&BMID=' +paramObj.BMID +
                '&approvalID=' + paramObj.approvalId +
                '&TierType=' + paramObj.TIERTYPE +
                '&OID=' + paramObj.OID +
                '&PARTNERID='+paramObj.PARTNERID+
                '&Qty_lines='+paramObj.qty+
                '&billType='+paramObj.billType+
                '&annual='+paramObj.annual+
                '&isAdmin='+paramObj.isAdmin+
                '&action='+paramObj.action+
                '&bc='+paramObj.bc+
                '&abt='+paramObj.abt+
                '&SAFID=' +paramObj.SAFID+
                '&AGENTID=' + paramObj.salesAgentId +
                '&contract=' +paramObj.contract +
                (paramObj.setTaxExempt
                    ? ('&exemptFromStateAndLocalTaxes=' + paramObj.taxExempt)
                    : '') +
                (featureToggle.Refund_Process__c
                    ? (paramObj.freeServiceCredit > 0
                        ? ('&freeServiceCredit=' + paramObj.freeServiceCredit)
                        : '')
                    : '') +
                '&freeServiceCreditPhase=2' +
                '&subscriptionInfo=' + JSONResponse
        );
        System.debug('request body is '+request.getBody());

        String jsonBody='';
        if(Test.isRunningTest()) {
            jsonBody = '{"URL":"https://devorigin101.secure.ringcentral.com/api/projects/ws/salesagent_v3.php","OPPID":"' + HardcodedIdsMapper.getMatchedObjectId('0068A000002Efb9QAC') + '","SALESAGENTID":"' + HardcodedIdsMapper.getMatchedObjectId('00580000004wj70AAA') + '","GWAPISID":"0c04915fe914d5d325a33576c05ddcaf_rcprod0"}';
        } else {
            HttpResponse response = new Http().send(request);
            jsonBody = response.getBody();
        }

        PresignUpActions.upsertFunnelStatus(opp.Id);

        updateAccFunnelNotSupported();

        GWFunnelWrapper.ResponseWrapper responseWrapperObject = (GWFunnelWrapper.ResponseWrapper)JSON.deserialize(jsonBody, GWFunnelWrapper.ResponseWrapper.class);
        system.debug(responseWrapperObject);
        String RedirectionURL = responseWrapperObject.URL;
        return String.valueOf(new PageReference(RedirectionURL + '?SALESAGENTID=' + responseWrapperObject.SALESAGENTID + '&OPPID=' + responseWrapperObject.OPPID +
            + '&GWAPISID='+responseWrapperObject.GWAPISID).getUrl());
    }

    public static string redirectSignUpFaxOrEnterprise(Id oppId){
        return String.ValueOf(new PageReference('/apex/SignUpLinksDemo?scontrolCaching=1&id=' + oppId + '&newModel=true').getUrl());
    }

    public static string redirectSignUpVARFaxOrEnterprise(Id oppId){
        return String.ValueOf(new PageReference('/apex/SignUpCustomer?scontrolCaching=1&id=' + oppId).getUrl());
    }
}