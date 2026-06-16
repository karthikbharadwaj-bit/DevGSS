global with sharing class  Approvaldefaults {

    public Approval__c app = new Approval__c();
    public ApexPages.StandardController controller;
    public Boolean showError = false;
    public String errMsg;
    public Approvaldefaults(ApexPages.StandardController controller) {

        app = (Approval__c) controller.getRecord();
        this.controller = controller;
        checkRecordType();
    }

    //Lightning component parameters
    public String legalApprover;
    public String accountId;
    public String recordType;
    public String caseId;
    public String credTransferAgent;
    public String agentCredit;
    public String name;
    public String typecomp;
    public String potUsers;
    public String signUpPurchaseLimit;
    public String monthlycredLimit;
    public String initialnumOfUsers;
    public string OpporId;
    public String retURLComp;
    public String addressLegal;
    public String refundOwner;
    public String claimingrequestor;
    public String paymentTerms;
    public String invoiceTerms;
    public String accountType;
    public String editionComp;



    public PageReference checkRecordType (){
        String packageId;
        BillingWrappers.QuotePackageInfo packageInfo;
        String address;
        Map<String, String> countryCodes = SettingsService.getCountryCodes();

        if (app.Opportunity__c == null && app.RecordTypeId == ApprovalHelper.RT_ID_TAX_EXEMPT_APPROVAL) {
            showError = true;
            errMsg = 'Tax exemption approval must be created from Opportunity.';
        } else {
            if(app.Opportunity__c != null) {
                Opportunity opp = (Opportunity)  new OpportunitySelector()
                    .selectOpportunitiesForApprovalCheck(new List<Object>{
                        new Set<Id>{app.Opportunity__c}})
                    .executeQuery()[0];
                if (opp != null &&
                    app.RecordTypeId == ApprovalHelper.RT_ID_TAX_EXEMPT_APPROVAL &&
                    TaxExemptionHelper.VATBRANDS.contains(opp.Brand_Name__c) &&
                    TaxExemptionHelper.VATCURRENCIES.contains(opp.CurrencyIsoCode) &&
                    opp.Account.BillingCountry != null) {
                    if (opp.Account.Billing_ID__c != null) {
                        try {
                            address = getAddress(opp.Account.Billing_ID__c);
                        } catch(Exception e) {
                            System.debug('errorOnGetAddress:: ' + e.getMessage());
                        }
                    }
                    if (address != null && address !='') {
                        BillingWrappers.BIAddress billingAddress = (BillingWrappers.BIAddress) JSON.deserialize(address,
                            BillingWrappers.BIAddress.class);
                        if (billingAddress != null) {
                            if (billingAddress.country != countryCodes.get(opp.Account.BillingCountry.toLowerCase())) {
                                errMsg = 'Billing Country on SFDC Account does not match with Billing Country in NGBS. Please, check your Account\'s Billing Address.';
                                showError = true;
                            }
                        }
                    } else {
                        if (!countryCodes.containsKey(opp.Account.BillingCountry.toLowerCase())) {
                            errMsg = 'Billing Country on SFDC Account does not match with Billing Country in NGBS. Please, check your Account\'s Billing Address.';
                            showError = true;
                        }
                    }
                    if (opp.Quotes.size() > 0) {
                        for (Quote q : opp.Quotes) {
                            if (q.Package_Info__c == null) {
                                continue;
                            } else {
                                List<BillingWrappers.QuotePackageInfo> pInfos =
                                    (List<BillingWrappers.QuotePackageInfo>)
                                        JSON.deserialize(q.Package_Info__c,
                                            List<BillingWrappers.QuotePackageInfo>.class
                                        );

                                if (pInfos.size() > 0) {
                                    for (BillingWrappers.QuotePackageInfo pInfo : pInfos) {
                                        if (pInfo.id != null) {
                                            packageId = pInfo.id;
                                            if (q.RecordType.Name == QuoteHelper.RT_NAME_BILLING) {
                                                packageInfo = pInfo;
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    if (packageId != null) {
                        if (packageInfo != null && packageInfo.packageBusinessIdentities != null && packageInfo.packageBusinessIdentities.approvedBi != null &&
                                packageInfo.packageBusinessIdentities.approvedBi.address != null &&
                                packageInfo.packageBusinessIdentities.approvedBi.address.country != null) {
                            String countryBI = countryCodes.get(packageInfo.packageBusinessIdentities.approvedBi.address.country.toLowerCase());
                            String country = countryCodes.get(opp.Account.BillingCountry.toLowerCase());
                            if (country != null && !SettingsService.isSwitzerland(opp.Account.BillingCountry) && !SettingsService.isTaiwan(opp.Account.BillingCountry) && countryBI != null && countryBI == country) {
                                errMsg = 'VAT exemption is not available for this country!';
                                showError = true;
                            }
                        } else {
                            errMsg = 'VAT exemption is not available for this quote due to BI absence (the quote may be too old). Please re-create the quote.';
                            showError = true;
                        }
                    }
                }

                if (opp != null &&
                    app.RecordTypeId == ApprovalHelper.RT_ID_TAX_EXEMPT_APPROVAL &&
                    TaxExemptionHelper.VATBRANDS.contains(opp.Brand_Name__c) &&
                    opp.Account.BillingCountry == null) {
                    showError = true;
                    errMsg = 'Please fill up Billing Country on Account';
                }

                if (opp != null && app.RecordTypeId == ApprovalHelper.RT_ID_TAX_EXEMPT_APPROVAL
                    && TaxExemptionHelper.isIndiaCountry(opp.Account.BillingCountry)) {
                    Map<Id, Approval__c> approvalsByAccount =
                        TaxExemptionHelper.getLastApprovedKYCApprovalByAccounts(new List<Id>{opp.Account.Id});
                    Approval__c kycApproval = approvalsByAccount.get(opp.Account.Id);
                    errMsg = TaxExemptionHelper.getKycErrorForTEACreation(kycApproval);
                    showError = String.isNotBlank(errMsg);
                }
            }
        }


        if(showError){
            return errorPage(errMsg);
        } else {
            return actapprovalObject();
        }
    }



    public PageReference errorPage(String errMsg) {
        ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,errMsg));
        return null;
    }

    public PageReference actapprovalObject() {
        System.debug(ApexPages.currentPage().getHeaders());
        System.debug(ApexPages.currentPage().getUrl());

        User currentUser = [SELECT ManagerId,Manager.Name, Division, Team__c from User WHERE Id=:UserInfo.getUserId()];

        PageReference approvalPage = new PageReference('/a0e/e?');

        if(currentUser != null) {
            approvalPage.getParameters().put('CF00N80000004iCn4',currentUser.Manager.Name);
            approvalPage.getParameters().put('CF00N80000004iCn4_lkid',currentUser.ManagerId);
            legalApprover = currentUser.ManagerId;
        }

		system.debug('CF00N80000004iCmz***' +ApexPages.currentPage().getParameters().get('CF00N80000004iCmz'));
        system.debug('Account Id>>>>>>' +ApexPages.currentPage().getParameters().get('Id'));
        approvalPage.getParameters().put('CF00N80000004iCmz_lkid',ApexPages.currentPage().getParameters().get('CF00N80000004iCmz_lkid'));
        approvalPage.getParameters().put('CF00N80000004iCmz_lkid',ApexPages.currentPage().getParameters().get('CF00N80000004iCmz_lkid'));
        accountId = ApexPages.currentPage().getParameters().get('CF00N80000004iCmz_lkid');

        // using this method to retrive return url :ApexPages.currentPage().getParameters().get('retURL');
        //save_new_url RecordType
        approvalPage.getParameters().put('retURL',ApexPages.currentPage().getParameters().get('retURL'));
        retURLComp = ApexPages.currentPage().getParameters().get('retURL');
        approvalPage.getParameters().put('RecordType',ApexPages.currentPage().getParameters().get('RecordType'));
        recordType = ApexPages.currentPage().getParameters().get('RecordType');

        approvalPage.getParameters().put('CF00N80000004iTTJ',ApexPages.currentPage().getParameters().get('CF00N80000004iTTJ'));
        approvalPage.getParameters().put('CF00N80000004iTTJ_lkid',ApexPages.currentPage().getParameters().get('CF00N80000004iTTJ_lkid'));
		caseId = ApexPages.currentPage().getParameters().get('CF00N80000004iTTJ_lkid');

        approvalPage.getParameters().put('CF00N80000004ieSF',UserInfo.getName());
        approvalPage.getParameters().put('CF00N80000004ieSF_lkid',UserInfo.getUserId());
        credTransferAgent = UserInfo.getUserId();

        approvalPage.getParameters().put('CF00N80000004ieQs',ApexPages.currentPage().getParameters().get('CF00N80000004ieQs'));
        approvalPage.getParameters().put('CF00N80000004ieQs_lkid',ApexPages.currentPage().getParameters().get('CF00N80000004ieQs_lkid'));
		agentCredit = ApexPages.currentPage().getParameters().get('CF00N80000004ieQs_lkid');

        approvalPage.getParameters().put('Name', ApexPages.currentPage().getParameters().get('Name'));
        approvalPage.getParameters().put(HardcodedIdsMapper.getMatchedObjectId('00N80000004iCoM'), ApexPages.currentPage().getParameters().get(HardcodedIdsMapper.getMatchedObjectId('00N80000004iCoM')));
		name = ApexPages.currentPage().getParameters().get('Name');
        typecomp = ApexPages.currentPage().getParameters().get(HardcodedIdsMapper.getMatchedObjectId('00N80000004iCoM'));

        setAccount(approvalPage);
        setOpportunityAndAccount(approvalPage);
        setQuoteFields(approvalPage);

        Map<Id, Account> accMap = new Map<Id, Account>();
        String accId = ApexPages.currentPage().getParameters().get('CF00N80000004iCmz_lkid') != null
                        ? String.escapeSingleQuotes(ApexPages.currentPage().getParameters().get('CF00N80000004iCmz_lkid'))
                        : null;
        if (accId != null) {
            accMap = new Map<Id, Account>([SELECT Id, Number_of_POC_Users__c,
                                                RC_User_ID__c, RC_Tier__c, RC_Account_Status__c,
                                                Payment_Method__c, Monthly_Credit_Limit__c, Sign_up_purchase_limit__c,
                                                Payment_terms__c, Invoice_terms__c
                                            FROM Account
                                            WHERE id = :accId]);
        }

        // Opportunity // Invoice

        if(!string.Isblank(ApexPages.currentPage().getParameters().get('RecordType'))) {
            string recordTypeId = ApexPages.currentPage().getParameters().get('RecordType');
            Schema.DescribeSObjectResult result = Approval__c.SObjectType.getDescribe();
            Map<ID,Schema.RecordTypeInfo> rtMapByName = result.getRecordTypeInfosById();
            if(rtMapByName.get(recordTypeId).getName() == ApprovalHelper.RT_NAME_REFUND_APPROVAL) {
                approvalPage.getParameters().put('CF00N80000005Hece',UserInfo.getName());
                approvalPage.getParameters().put('CF00N80000005Hece_lkid',UserInfo.getUserId());
                refundOwner = UserInfo.getUserId();
            }
            if(rtMapByName.get(recordTypeId).getName() == ApprovalHelper.RT_NAME_FARMING_CLAIM_OWNER) {
                approvalPage.getParameters().put('CF00N80000005HUXw',UserInfo.getName());
                approvalPage.getParameters().put('CF00N80000005HUXw_lkid',UserInfo.getUserId());
                claimingrequestor = UserInfo.getUserId();
            }

            if(rtMapByName.get(recordTypeId).getName() == ApprovalHelper.RT_NAME_ENGAGE_LEGAL) {
                approvalPage.getParameters().put('RecordType', Schema.SObjectType.Approval__c.getRecordTypeInfosByName()
                    .get('Engage Legal').getRecordTypeId());
                recordType = Schema.SObjectType.Approval__c.getRecordTypeInfosByName()
                    .get('Engage Legal').getRecordTypeId();
            }

            if(rtMapByName.get(recordTypeId).getName() == ApprovalHelper.INVOICING_REQUEST_APPROVAL_RT_NAME) {
                if (accId != null && accMap.containsKey(accId)
                &&  accMap.get(accId).Payment_Method__c == AccountHelper.PAYMENT_METHOD_INVOICE) {
                    Account acc = accMap.get(accId);
                    approvalPage.getParameters().put(HardcodedIdsMapper.getMatchedObjectId('00N80000004j6pe'), String.valueOf(acc.Monthly_Credit_Limit__c));
                    monthlycredLimit = String.valueOf(acc.Monthly_Credit_Limit__c);
                    approvalPage.getParameters().put(HardcodedIdsMapper.getMatchedObjectId('00N80000004j6pU'), String.valueOf(acc.Sign_up_purchase_limit__c));
                    signUpPurchaseLimit =  String.valueOf(acc.Sign_up_purchase_limit__c);
                    approvalPage.getParameters().put(HardcodedIdsMapper.getMatchedObjectId('00N80000004jB6A'), acc.Payment_Terms__c);
                    paymentTerms = acc.Payment_Terms__c;
                    approvalPage.getParameters().put(HardcodedIdsMapper.getMatchedObjectId('00N80000005H5ND'), acc.Invoice_Terms__c);
                    invoiceTerms = acc.Invoice_Terms__c;
                }
            }
            if(rtMapByName.get(recordTypeId).getName() == ApprovalHelper.RT_NAME_FEATURE_ADD_ONS_APPROVAL) {

                if ( accId != null && accMap.containsKey(accId) ) {
                    List<Package__c> packages = new PackageSelector()
                        .selectPackagesForNewReferences(new List<Object> {new Set<Id>{accountId}})
                        .executeQuery();

                    Map<Id, Package__c> packageMap = PackageHelper.filterPackagesByService(packages, QuoteHelper.NGBS_OFFICE_PRODUCT);
                    Package__c pkg = packageMap.get(accountId);
                    approvalPage.getParameters().put('CF00N80000004iCn4','');
                    approvalPage.getParameters().put('CF00N80000004iCn4_lkid','');
                    legalApprover = '';

                    String accTypeField;
                    String editionField;

                    try {
                        accTypeField = getCustomFieldId('Approval__c', 'AccountType__c');
                        editionField = getCustomFieldId('Approval__c', 'Edition__c');
                    } catch( Exception ex ) {
                        accTypeField = HardcodedIdsMapper.getMatchedObjectId('00Nn0000000c78N');
                        editionField = HardcodedIdsMapper.getMatchedObjectId('00Nn0000000c78R');
                    }
                    System.debug( 'AccountType__c >>> ' + accTypeField );
                    System.debug( 'Edition__c >>> ' + editionField );

                    Decimal numberOfPOCUsers = pkg != null? pkg.Number_of_POC_Users__c: 0;
                    String rcUserID = accMap.get(accId).RC_User_ID__c;
                    String rcAccountStatus = accMap.get(accId).RC_Account_Status__c;
                    String accType = '';
                    String edition = '';

                    // Fill AccountType__c field according to the logic below
                    if (numberOfPOCUsers > 0 && rcAccountStatus != 'Paid' && rcAccountStatus != 'Disabled' && rcAccountStatus != 'Canceled') {
                        accType = 'POC';
                    } else if (String.isNotBlank(rcUserID)) {
                        accType = 'Existing';
                    } else {
                        accType = 'New';
                    }

                    approvalPage.getParameters().put( accTypeField , accType);
                    accountType = accType;

                    Map<Id, String> accToTierMap = createMapAccToTier(accMap.values());
                    Map<String, String> tierToEditionMap = createMapTierToEdition(accToTierMap.values());

                    edition = tierToEditionMap.get(accToTierMap.get(accId));
                    approvalPage.getParameters().put( editionField, edition);
                    editionComp = edition;

                }
            }

        }
        approvalPage.getParameters().put('nooverride','1');
        approvalPage.setRedirect(true);

        return approvalPage;

    }

    webService static String getUsersInfo (String userId) {
        String resultUrl = '';

        User currentUser = [SELECT Id, Name, ManagerId,Manager.Name from User WHERE id=:userId];

        if (String.isNotBlank(currentUser.Manager.Name)) {
            resultUrl = 'CF00N80000004iCn4=' + EncodingUtil.urlEncode(currentUser.Manager.Name, 'UTF-8');
        }
        resultUrl += '&CF00N80000004iCn4_lkid=' + currentUser.ManagerId
                    + '&CF00N80000004ieSF=' + EncodingUtil.urlEncode(currentUser.Name, 'UTF-8')
                    + '&CF00N80000004ieSF_lkid=' + currentUser.Id;
        return resultUrl;
    }

    public String getCustomFieldId(String sObjectName, String fieldName) {

        System.debug('sObjectName >>> ' + sObjectName);
        System.debug('fieldName >>> ' + fieldName);

        sObjectName = sObjectName.replace('__c', '');
        fieldName = fieldName.replace('__c', '');

        List<EntityDefinition> entityDefinitions = [SELECT Id, DurableId FROM EntityDefinition WHERE DeveloperName =: sObjectName and DurableId !=: sObjectName];

        String entityDurableId = entityDefinitions[0].DurableId;

        List<FieldDefinition> fieldDefList = [SELECT Id, DeveloperName, NamespacePrefix, DurableId FROM FieldDefinition WHERE EntityDefinitionId =: entityDurableId and DeveloperName =: fieldName];

        String customFieldId = fieldDefList[0].DurableId;

        customFieldId = customFieldId.substringAfter('.');

        return customFieldId;
    }


    public Map<Id, String> createMapAccToTier( List<Account> accs) {
        Pattern regexPattern = Pattern.compile('\\[\\d+\\]');
        Map<Id, String> accToTierMap = new Map< Id, String>();

        for( Account acc : accs ) {
            String tier = acc.RC_Tier__c == null ? '' : acc.RC_Tier__c;
            Matcher regexMatcher = regexPattern.matcher( tier );
            if ( regexMatcher.find() ) {
                accToTierMap.put( acc.Id , regexMatcher.group().removeStart('[').removeEnd(']') );
            } else {
                accToTierMap.put( acc.Id , null );
            }
        }

        return accToTierMap;
    }

    public Map<String, String> createMapTierToEdition( List<String> tiers) {
        Map<String, String> tierToEditionMap = new Map<String, String>();
        List<Pricebook2> pb2s = [ SELECT Tier_ID__c, Edition__c FROM Pricebook2 WHERE Tier_ID__c IN :tiers ];

        for( Pricebook2 pb2 : pb2s ) {
            tierToEditionMap.put( pb2.Tier_ID__c, pb2.Edition__c );
        }

        return tierToEditionMap;
    }

    public void setAccount(PageReference approvalPage) {
        String accId = ApexPages.currentPage().getParameters().get('CF00N80000004iCmz_lkid');
        String accName = ApexPages.currentPage().getParameters().get('CF00N80000004iCmz');
        String accBillingAddress = '';
        if (accId == null){
            return;
        }
        Account acc = [
                SELECT Id, BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry
                FROM Account
                WHERE Id = :accId LIMIT 1
        ];

        if (acc.BillingPostalCode != null) {
            accBillingAddress += acc.BillingPostalCode;
        }
        if (acc.BillingCountry != null) {
            if (accBillingAddress != '') {
                accBillingAddress += ', ';
            }
            accBillingAddress += acc.BillingCountry;
        }
        if (acc.BillingState != null) {
            if (accBillingAddress != '') {
                accBillingAddress += ', ';
            }
            accBillingAddress += acc.BillingState;
        }
        if (acc.BillingCity != null) {
            if (accBillingAddress != '') {
                accBillingAddress += ', ';
            }
            accBillingAddress += acc.BillingCity;
        }
        if (acc.BillingStreet != null) {
            if (accBillingAddress != '') {
                accBillingAddress += ', ';
            }
            accBillingAddress += acc.BillingStreet;
        }

        List<Opportunity> opps = new List<Opportunity>([
                SELECT Id, Name, AccountId, Account.Name, Is_Billing_Opportunity__c
                FROM Opportunity
                WHERE AccountId = :ApexPages.currentPage().getParameters().get('CF00N80000004iCmz_lkid')
        ]);
        if (opps.size() == 1) {
            List<Quote> quote = [
                    SELECT Id, TotalPrice, Monthly_Recurring_Revenue__c, Total_Number_of_Digital_Lines__c
                    FROM Quote
                    WHERE OpportunityId = :opps.get(0).Id AND isPrimary__c = TRUE
            ];
            Set<Id> qIds = new Set<Id>();
            for (Quote q: quote) {
                qIds.add(q.Id);
            }
            Decimal potentialUsers = 0;
            if (!quote.isEmpty() && !opps.get(0).Is_Billing_Opportunity__c) {
                List<QuoteLineItem> quoteLineItems = [
                        SELECT Id, NewQuantity__c, Entitlement__r.Quantity__c, Quote.RecordType.Name, Product2.Family, QuoteId
                        FROM QuoteLineItem
                        WHERE QuoteId IN :qIds AND Quote.RecordType.Name = 'Sales Quote' AND Product2.Family = 'Service'
                        LIMIT 1
                ];
                if (!quoteLineItems.isEmpty()) {
                    if (quoteLineItems.get(0).NewQuantity__c == null) {
                        if (quoteLineItems.get(0).Entitlement__r.Quantity__c == null) {
                            potentialUsers = 0;
                        } else {
                            potentialUsers = potentialUsers - quoteLineItems.get(0).Entitlement__r.Quantity__c;
                        }
                    } else if (quoteLineItems.get(0).Entitlement__r.Quantity__c == null) {
                        potentialUsers = quoteLineItems.get(0).NewQuantity__c;
                    } else {
                        potentialUsers = quoteLineItems.get(0).NewQuantity__c - quoteLineItems.get(0).Entitlement__r.Quantity__c;
                    }
                    approvalPage.getParameters().put(getFieldIdByName('Approval', 'Potential_Users__c'), String.valueOf(potentialUsers));
                	potUsers = String.valueOf(potentialUsers);
                }
            }
            if (!quote.isEmpty()) {
                if(quote.get(0).TotalPrice != null){
                    approvalPage.getParameters().put(HardcodedIdsMapper.getMatchedObjectId('00N80000004j6pU'), String.valueOf(quote.get(0).TotalPrice * 1.5));
                    signUpPurchaseLimit = String.valueOf(quote.get(0).TotalPrice * 1.5);
                }
                if(quote.get(0).Monthly_Recurring_Revenue__c != null){
                    approvalPage.getParameters().put(HardcodedIdsMapper.getMatchedObjectId('00N80000004j6pe'), String.valueOf(
                        quote.get(0).Monthly_Recurring_Revenue__c * 1.5));
                    monthlycredLimit = String.valueOf(
                        quote.get(0).Monthly_Recurring_Revenue__c * 1.5);
                }
                if(quote.get(0).Total_Number_of_Digital_Lines__c != null){
                    approvalPage.getParameters().put(HardcodedIdsMapper.getMatchedObjectId('00N80000005HYKX'), String.valueOf(
                        quote.get(0).Total_Number_of_Digital_Lines__c));
                    initialnumOfUsers = String.valueOf(
                        quote.get(0).Total_Number_of_Digital_Lines__c);
                }
            }
            if(approvalPage.getParameters().get('retURL') != null && !approvalPage.getParameters().get('retURL').startsWith('/001')){
                approvalPage.getParameters().put('CF00N80000004j6pF', opps.get(0).Name);
                approvalPage.getParameters().put('CF00N80000004j6pF_lkid', opps.get(0).Id);
                OpporId = opps.get(0).Id;

            }
        }
        approvalPage.getParameters().put('CF00N80000004iCmz', accName);
        approvalPage.getParameters().put('CF00N80000004iCmz_lkid', accId);
        approvalPage.getParameters().put(getFieldIdByName('Approval', 'Legal_Physical_Address_Head_Office__c'), accBillingAddress);
    	accountId = accId;
        addressLegal = accBillingAddress;
    }

    public void setOpportunityAndAccount(PageReference approvalPage) {
        String oppId = ApexPages.currentPage().getParameters().get('CF00N80000004j6pF_lkid');
        String oppName = ApexPages.currentPage().getParameters().get('CF00N80000004j6pF');
        String accId = '';
        String accName = '';
        String accBillingAddress = '';

        if (oppId == null) {
            return;
        }

        try {
            Opportunity opp = [
                    SELECT Id, AccountId, Brand_Name__c, Account.Name, Account.BillingStreet, Account.BillingState, Account.BillingCountry,
                            Account.BillingCity, Account.BillingPostalCode, (Select Id, Package_Info__c FROM Quotes)
                    FROM Opportunity
                    WHERE Id = :ApexPages.currentPage().getParameters().get('CF00N80000004j6pF_lkid') LIMIT 1
            ];
            accId = opp.AccountId;
            accName = opp.Account.Name;
            if (opp.Account.BillingPostalCode != null) {
                accBillingAddress += opp.Account.BillingPostalCode;
            }
            if (opp.Account.BillingCountry != null) {
                if (accBillingAddress != '') {
                    accBillingAddress += ', ';
                }
                accBillingAddress += opp.Account.BillingCountry;
            }
            if (opp.Account.BillingState != null) {
                if (accBillingAddress != '') {
                    accBillingAddress += ', ';
                }
                accBillingAddress += opp.Account.BillingState;
            }
            if (opp.Account.BillingCity != null) {
                if (accBillingAddress != '') {
                    accBillingAddress += ', ';
                }
                accBillingAddress += opp.Account.BillingCity;
            }
            if (opp.Account.BillingStreet != null) {
                if (accBillingAddress != '') {
                    accBillingAddress += ', ';
                }
                accBillingAddress += opp.Account.BillingStreet;
            }

        } catch(Exception ex) {
            System.debug('Not able to find the opportunity.');
        }

        approvalPage.getParameters().put('CF00N80000004iCmz', accName);
        approvalPage.getParameters().put('CF00N80000004iCmz_lkid', accId);
        approvalPage.getParameters().put('CF00N80000004j6pF',oppName);
        approvalPage.getParameters().put('CF00N80000004j6pF_lkid',oppId);
        approvalPage.getParameters().put(getFieldIdByName('Approval', 'Legal_Physical_Address_Head_Office__c'), accBillingAddress);
   		accountId = accId;
        OpporId = oppId;
        addressLegal = accBillingAddress;
    }

    public void setQuoteFields(PageReference approvalPage) {
        String oppId = ApexPages.currentPage().getParameters().get('CF00N80000004j6pF_lkid');
        List<Quote> quote = [
                SELECT Id, TotalPrice, Monthly_Recurring_Revenue__c, Total_Number_of_Digital_Lines__c
                FROM Quote
                WHERE OpportunityId = :oppId AND isPrimary__c = TRUE
        ];
        List<Opportunity> opps = new List<Opportunity>([
                SELECT Id, Is_Billing_Opportunity__c
                FROM Opportunity
                WHERE Id = :oppId LIMIT 1
        ]);
        Set<Id> qIds = new Set<Id>();
        for (Quote q: quote) {
            qIds.add(q.Id);
        }
        Decimal potentialUsers = 0;
        if (!quote.isEmpty()) {
            List<QuoteLineItem> quoteLineItems = [
                    SELECT Id, NewQuantity__c, Entitlement__r.Quantity__c, Quote.RecordType.Name, Product2.Family, QuoteId
                    FROM QuoteLineItem
                    WHERE QuoteId IN :qIds AND Quote.RecordType.Name = 'Sales Quote' AND Product2.Family = 'Service' LIMIT 1
            ];
            if (!quoteLineItems.isEmpty() && !opps.isEmpty() && !opps.get(0).Is_Billing_Opportunity__c) {
                if (quoteLineItems.get(0).NewQuantity__c == null) {
                    if (quoteLineItems.get(0).Entitlement__r.Quantity__c == null) {
                        potentialUsers = 0;
                    } else {
                        potentialUsers = potentialUsers - quoteLineItems.get(0).Entitlement__r.Quantity__c;
                    }
                } else if (quoteLineItems.get(0).Entitlement__r.Quantity__c == null) {
                    potentialUsers = quoteLineItems.get(0).NewQuantity__c;
                } else {
                    potentialUsers = quoteLineItems.get(0).NewQuantity__c - quoteLineItems.get(0).Entitlement__r.Quantity__c;
                }
                approvalPage.getParameters().put(getFieldIdByName('Approval', 'Potential_Users__c'), String.valueOf(potentialUsers));
                potUsers = String.valueOf(potentialUsers);
            }
            if(quote.get(0).TotalPrice != null){
                approvalPage.getParameters().put(HardcodedIdsMapper.getMatchedObjectId('00N80000004j6pU'), String.valueOf(quote.get(0).TotalPrice * 1.5));
            	signUpPurchaseLimit = String.valueOf(quote.get(0).TotalPrice * 1.5);
            }
            if(quote.get(0).Monthly_Recurring_Revenue__c != null){
                approvalPage.getParameters().put(getFieldIdByName('Approval', 'Monthly_Credit_Limit__c'), String.valueOf(quote.get(0).Monthly_Recurring_Revenue__c * 1.5));
            	monthlycredLimit = String.valueOf(quote.get(0).Monthly_Recurring_Revenue__c * 1.5);
            }
            if(quote.get(0).Total_Number_of_Digital_Lines__c != null){
                approvalPage.getParameters().put(HardcodedIdsMapper.getMatchedObjectId('00N80000005HYKX'), String.valueOf(quote.get(0).Total_Number_of_Digital_Lines__c));
            	initialnumOfUsers = String.valueOf(quote.get(0).Total_Number_of_Digital_Lines__c);
            }
        }
    }

    public static String getFieldIdByName(String nameObj, String fieldName) {
        FieldDefinition  fieldDefinitions;
        List<EntityDefinition> entityDefinitions = [
                SELECT Id, DurableId from EntityDefinition WHERE DeveloperName = :nameObj
        ];
        String fieldNamespacePrefix ;

        String fieldNameForQuery = fieldName.replace('__c', '');
        if (fieldNameForQuery.contains('__')) {
            fieldNamespacePrefix = fieldNameForQuery.substringBefore('__');
            fieldNameForQuery = fieldNameForQuery.substringAfter('__');
        }
        if (fieldNamespacePrefix != null && fieldNamespacePrefix != '') {
            fieldDefinitions = [
                    SELECT Id, DeveloperName, NamespacePrefix, DurableId FROM FieldDefinition WHERE EntityDefinitionId = :entityDefinitions[0].DurableId + '__c' AND DeveloperName = :fieldNameForQuery
            ];
        } else if (nameObj == 'Case') {
            fieldDefinitions = [
                    SELECT Id, DeveloperName, NamespacePrefix, DurableId FROM FieldDefinition WHERE EntityDefinitionId = :entityDefinitions[0].DurableId AND DeveloperName = :fieldNameForQuery
            ];
        } else {
            fieldDefinitions = [
                    SELECT Id, DeveloperName, NamespacePrefix, DurableId FROM FieldDefinition WHERE EntityDefinitionId = :entityDefinitions[0].DurableId + '__c' AND DeveloperName = :fieldNameForQuery
            ];
        }

        String result = String.valueOf(fieldDefinitions.DurableId.split('\\.')[1]);

        if (result.length() > 15) {
            result = result.substring(0, 15);
        }

        return result;
    }

    public static String getAddress(String billingId) {
        String responseBody;
        if (billingId != null) {
            String endpoint = NGBSAPI.NGBS_ACCOUNT_MANAGER + '/' + billingId + '/address?type=Billing';
            responseBody = NGBSAPI.requestNGBS(endpoint, HttpHelper.METHOD_GET).getBody();
        }
        return responseBody;
    }
}