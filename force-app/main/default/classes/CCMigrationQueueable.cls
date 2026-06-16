public class CCMigrationQueueable implements Queueable, Database.AllowsCallouts {
    private static final String MIGRATION_ERROR_MESSAGE = '[MIGRATION] Error occurred during {0} => \n{1}';
    private static final String NGBS_DID_NOT_RETURN_MONTHLY_LIMIT_MESSAGE = 'NGBS did not return Monthly_Credit_Limit__c';
    private static final String NGBS_DID_NOT_RETURN_SIGNUP_PURCHASE_LIMIT_MESSAGE = 'NGBS did not return Sign_Up_Purchase_Limit__c';
    @TestVisible
    private static final String ACCOUNT_DOES_NOT_HAVE_ACCOUNT_PAYABLE_ROLE = 'MVP Account does not have any Account Payable Contact Role. No Invoice Request was created during migration.';
    private static final String CC_MIGRATION_ERROR_EMAIL_SUBJECT = 'Error happened during CC Migration';

    @TestVisible
    private static final String CC_MIGRATION_CLASS_NAME = 'CCMigrationQueueable';
    @TestVisible
    private static final String CC_MIGRATION_GROUP_DEVELOPER_NAME = 'CC_Migration_Support';
    @TestVisible
    private static final String CC_LEGACY_BASE_LINE_OPPORTUNITY_NAME = '[CC Legacy base-line Opportunity]';
    @TestVisible
    private static final String CC_LEGACY_QUOTE_NAME = '[CC Legacy Quote]';
    @TestVisible
    private static final String CC_LEGACY_BASE_LINE_OPPORTUNITY_NAME_FORMAT = '{0} {1}';
    private static final String NAME_FIELD_API = 'Name';
    private static final String CURRENCY_PROPERTY = 'currency';
    private static final String PACKAGES_PROPERTY = 'packages';
    private Account technicalAccountForMigration;
    private Boolean isAutomatically;
    @TestVisible
    private BillingWrappers.NGBSAccountPackage ngbsAccountPackage;
    @TestVisible
    private BillingWrappers.BillingInfo2 bInfo;
    @TestVisible
    private BillingWrappers.NGBSPackageLimit packageLimit;


    public CCMigrationQueueable(Account technicalAccountForMigration) {
        this(technicalAccountForMigration, false);
    }

    //@Param isAutomatically = false means that Queueable started manually without rollback
    public CCMigrationQueueable(Account technicalAccountForMigration, Boolean isAutomatically) {
        this.technicalAccountForMigration = technicalAccountForMigration;
        this.isAutomatically = isAutomatically;
    }

    public void execute(QueueableContext context) {
        migrateAccount();
    }

    @TestVisible
    private void migrateAccount() {
        Savepoint sp;
        try {
            requestDataFromNGBS();

            sp = isAutomatically ? Database.setSavepoint() : null;
            insertRecordsForCCMigration();
        } catch (Exception e) {
            if (sp != null) {
                Database.rollback(sp);
            }
            handleException(e);
        }
    }

    @TestVisible
    private class BillingData {
        public List<BillingWrappers.CartItem> cartItems;
        public List<BillingWrappers.BillingProduct> products;

        public BillingData(
            List<BillingWrappers.CartItem> cartItems,
            List<BillingWrappers.BillingProduct> products
        ) {
            this.cartItems = cartItems;
            this.products = products;
        }
    }

    @TestVisible
    private void insertRecordsForCCMigration() {
        Opportunity technicalOpp = createTechnicalOpp();
        insertCreatedRecordWithTriggersOff(technicalOpp);

        Quote technicalQuote = createTechnicalQuoteForMigratedOpportunity(technicalOpp.Id);
        Database.insert(technicalQuote);

        // Sync products and create QLIs
        BillingData data = createItemsFromNGBSBillingInfo();
        QuoteLineItemService.syncProducts(technicalQuote.Id, data.products);
        QuoteLineItemService.insertQuoteLineItems(technicalQuote.Id, data.cartItems);

        insertInvoiceApprovalForMigratedAccount(technicalOpp.Id);

        updateLimitsOnTechnicalAccount(technicalQuote.Id);
        insertOrder(technicalQuote.Id);
        updateQlis(technicalQuote.Id);
    }

    private void insertOrder(Id quoteId) {
        Quote techQuote = (Quote) new ListOptional(
            new QuoteSelector()
                .selectQuoteById(new List<Id> { quoteId })
                .executeQuery()
        ).getFirst();

        Database.insert(OrderHelper.createOrder(techQuote));
    }

    @TestVisible
    private Opportunity createTechnicalOpp() {
        return (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.AccountId => this.technicalAccountForMigration.Id,
                Opportunity.Brand_Name__c => this.technicalAccountForMigration.RC_Brand__c,
                Opportunity.CloseDate => System.today(),
                Opportunity.Downgrade_Reason_Opp__c => OpportunityHelper.DOWNGRADE_REASON_CC_MIGRATION,
                Opportunity.Why_We_Lost__c => OpportunityHelper.DOWNGRADE_REASON_CC_MIGRATION,
                Opportunity.Final_Competitor_we_lost_against__c => OpportunityHelper.COMPETITOR_LOST_CC_MIGRATION,
                Opportunity.Additional_details_on_why_we_lost__c =>  OpportunityHelper.ADDITIONAL_DOWNGRADE_REASON_CC_MIGRATION,
                Opportunity.IsMultiProductTechnicalOpportunity__c => true,
                Opportunity.Is_Billing_Opportunity__c => true,
                Opportunity.MasterOpportunity__c => null,
                Opportunity.Name => constructCCMigrationName(CC_LEGACY_BASE_LINE_OPPORTUNITY_NAME, OpportunityHelper.FIELDS_MAP.get(NAME_FIELD_API).getDescribe().getLength()),
                Opportunity.OwnerId => UserHelper.getMultiproductTechnicalUser().Id,
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_DOWNGRADED,
                Opportunity.Tier_Name__c => OpportunityHelper.TIER_RC_CONTACT_CENTER,
                Opportunity.Type => OpportunityHelper.OPPORTUNITY_TYPE_NEW_BUSINESS,
                Opportunity.CurrencyIsoCode => ngbsAccountPackage.currencyCode
            })
            .build()
            .getRecord();
    }

    @TestVisible
    private Quote createTechnicalQuoteForMigratedOpportunity(Id technicalOppId) {
        return (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.OpportunityId => technicalOppId,
                Quote.QuoteType__c => QuoteHelper.QUOTE_TYPE_AGREEMENT,
                Quote.OwnerId => UserHelper.getMultiproductTechnicalUser().Id,
                Quote.IsMultiProductTechnicalQuote__c => true,
                Quote.MasterQuote__c => null,
                Quote.Name => constructCCMigrationName(CC_LEGACY_QUOTE_NAME, QuoteHelper.FIELDS_MAP.get(NAME_FIELD_API).getDescribe().getLength()),
                Quote.Status => QuoteHelper.QUOTE_STATUS_EXECUTED,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.isPrimary__c => true,
                Quote.ServiceName__c => QuoteHelper.NGBS_RCCC_PRODUCT,
                Quote.Pricebook2Id => Pricebook2Helper.getStandardPricebookId(),
                Quote.CurrencyIsoCode => ngbsAccountPackage.currencyCode
            })
            .build()
            .getRecord();
    }

    @TestVisible
    private BillingData createItemsFromNGBSBillingInfo() {
        List<BillingWrappers.CartItem> items = new List<BillingWrappers.CartItem>();
        List<BillingWrappers.BillingProduct> products = new List<BillingWrappers.BillingProduct>();

        try {
            Map<String, List<BillingWrappers.LicenseRequested2>> catalogIdToLicense = new Map<String, List<BillingWrappers.LicenseRequested2>>();
            for (BillingWrappers.LicenseRequested2 license : bInfo.licenses) {
                if (!catalogIdToLicense.containsKey(license.catalogId)) {
                    catalogIdToLicense.put(license.catalogId, new List<BillingWrappers.LicenseRequested2>());
                }
                catalogIdToLicense.get(license.catalogId).add(license);
            }

            for (String catalogId : catalogIdToLicense.keySet()) {
                BillingWrappers.CartItem cartItem = new BillingWrappers.CartItem();
                BillingWrappers.BillingProduct product = new BillingWrappers.BillingProduct();

                cartItem.productName = bInfo.product;
                cartItem.unitPrice = cartItem.discount = 0;
                cartItem.quantity = 0;
                cartItem.discountType = QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY;
                cartItem.billingPackage = new BillingWrappers.PackageInfo();
                cartItem.billingPackage.catalogId = ngbsAccountPackage.catalogId;
                cartItem.billingPackage.version = ngbsAccountPackage.version;
                cartItem.currencyIsoCode = product.currencyIsoCode = ngbsAccountPackage.currencyCode;
                product.itemType = Product2Helper.PRODUCT_TYPE_BILLING_PRODUCT;

                for (BillingWrappers.LicenseRequested2 license : catalogIdToLicense.get(catalogId)) {
                    // BILLING PRODUCT
                    product.catalogId = license.catalogId;
                    product.name = license.description;
                    product.categoryCode = license.categoryId;
                    product.billingType = license.billingType;
                    if (license.labels?.GOA?.size() > 0) {
                        product.goa = license.labels.GOA[0];
                    }

                    if (license.labels?.quotingGroup?.size() > 0) {
                        product.quotingGroup = license.labels.quotingGroup[0];
                    }

                    if (license.labels?.quotingSubGroup?.size() > 0) {
                        product.quotingSubGroup = license.labels.quotingSubGroup[0];
                    }

                    // CART ITEM
                    cartItem.catalogId = license.catalogId;
                    cartItem.name = license.description;
                    cartItem.displayName = license.description;
                    cartItem.billingCycleDuration = license.billingCycleDuration;
                    cartItem.quantity += license.qty;
                    cartItem.unitPrice = license.price;
                    cartItem.packageInfo = '{"duration": "' + license.billingCycleDuration + '"}';
                    cartItem.billingType = license.billingType;

                    Date endDate = Date.valueOf(license.billingEndDate);
                    cartItem.salesEndDate = DateTime.newInstance(endDate.year(), endDate.month(), endDate.day());

                    if (license.discount != null) {
                        cartItem.discountType = NGBS_Discount.BILLING_DISCOUNT_TYPE_CURRENCY.equalsIgnoreCase(license.discount.value.unit)
                            ? QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY
                            : QuoteLineItemHelper.DISCOUNT_TYPE_PERCENTAGE;

                        cartItem.discount = license.discount.value.value;
                    }
                }
                products.add(product);
                items.add(cartItem);
            }
        } catch (Exception e) {
            AquivaHelper.throwAquivaException(
                String.format(
                    '[MIGRATION] Error occurred during cart items creation => {0}\n{1}',
                    new List<String> { e.getMessage(), e.getStackTraceString() }
                ), e);
        }
        return new BillingData(items, products);
    }

    @TestVisible
    private void insertInvoiceApprovalForMigratedAccount(Id technicalOppId) {
        AccountContactRole accountPayableContact = getAccountPayableContactRole();
        if (accountPayableContact == null) {
            notifyInChatter(ACCOUNT_DOES_NOT_HAVE_ACCOUNT_PAYABLE_ROLE);
            notifyInChatter(ACCOUNT_DOES_NOT_HAVE_ACCOUNT_PAYABLE_ROLE, this.technicalAccountForMigration.Master_Account__c);
            return;
        }

        Approval__c invoiceApproval = (Approval__c) new SObjectBuilder(Approval__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Approval__c.RecordTypeId => ApprovalHelper.RT_ID_INVOICING_REQUEST,
                Approval__c.Account__c => this.technicalAccountForMigration.Id,
                Approval__c.AccountPayableContact__c => accountPayableContact.ContactId,
                Approval__c.Opportunity__c => technicalOppId,
                Approval__c.Monthly_Credit_Limit__c => this.packageLimit.value,
                Approval__c.Sign_Up_Purchase_Limit__c => this.packageLimit.limitOverride.value,
                Approval__c.Status__c => ApprovalHelper.STATUS_APPROVED,
                Approval__c.StatusLastModifiedDate__c => System.now(),
                Approval__c.IsMultiProductTechnicalApproval__c => true
            })
            .build()
            .getRecord();

        insertCreatedRecordWithTriggersOff(invoiceApproval);
    }

    private AccountContactRole getAccountPayableContactRole() {
        AccountContactRole accountPayableContact = selectAccountPayableContactRole();
        return accountPayableContact == null
               ? createAccountPayableContact()
               : accountPayableContact;
    }

    private AccountContactRole createAccountPayableContact() {
        List<AccountContactRole> primaryContactRoles = (List<AccountContactRole>) new AccountContactRoleSelector()
            .selectPrimaryAccountContactRolesByAccountIds(new Set<Id> {
                this.technicalAccountForMigration.Master_Account__c,
                this.technicalAccountForMigration.Id
            })
            .executeQuery();
        if (primaryContactRoles.size() != 2) {
            return null;
        }

        List<Id> accIds = new List<Id>();
        List<id> contactIds = new List<Id>();
        for (AccountContactRole acr : primaryContactRoles) {
            accIds.add(acr.AccountId);
            contactIds.add(acr.ContactId);
        }

        return (AccountContactRole) new SObjectBuilder(AccountContactRole.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                AccountContactRole.AccountId => new ValueProvider.ListProvider(accIds),
                AccountContactRole.ContactId => new ValueProvider.ListProvider(contactIds),
                AccountContactRole.Role => AccountContactRoleHelper.CONTACT_ROLE_ACCOUNT_PAYABLE,
                AccountContactRole.IsPrimary => false
            })
            .quantity(2)
            .create()
            // Salesforce doesn't allow more than one primary AccountContactRole per Account.
            // This is why we can be certain that the second record in the list is for the technical Account.
            .getRecord(1);
    }

    private AccountContactRole selectAccountPayableContactRole() {
        return (AccountContactRole) new ListOptional(
                new AccountContactRoleSelector()
                    .selectAccountContactRolesByRoleAndAccountId(
                        this.technicalAccountForMigration.Id,
                        AccountContactRoleHelper.CONTACT_ROLE_ACCOUNT_PAYABLE
                    )
                    .executeQuery()
            )
            .getFirst();
    }

    private void insertCreatedRecordWithTriggersOff(SObject recordToInsert) {
        Triggers.switchOff();
        Database.insert(recordToInsert);
        Triggers.switchOn();
    }

    private void handleException(Exception e) {
        String source = String.format('Error {0}', new List<String> {CC_MIGRATION_CLASS_NAME});
        PlatformLog.logException(source, e);

        String errorMessage = composeErrorMessageForNotification(e);
        notifyInChatter(CC_MIGRATION_ERROR_EMAIL_SUBJECT + '\n\n' + errorMessage);
        notifyCCSupportTeam(errorMessage);
    }

    private void notifyInChatter(String errorMessage) {
        notifyInChatter(errorMessage, this.technicalAccountForMigration.Id);
    }

    private void notifyInChatter(String errorMessage, Id accountId) {
        new ChatterHelper.FeedItemInputBuilder()
            .withMessage(errorMessage)
            .withFeedSObjectId(accountId)
            .build();
    }

    private void notifyCCSupportTeam(String plainTextBody) {
        EmailNotificationHelper.sendEmailNotificationToGroupMembers(
            CC_MIGRATION_GROUP_DEVELOPER_NAME,
            CC_MIGRATION_ERROR_EMAIL_SUBJECT,
            plainTextBody
        );
    }

    private String composeErrorMessageForNotification(Exception e) {
        return String.format(
            'Error message: {0}\n\n{1}\n\n{2}',
            new List<Object> {e.getMessage(), e.getStackTraceString(), getMigratingAccountInfo()}
        );
    }

    private String getMigratingAccountInfo() {
        String accUrl = URL.getOrgDomainUrl().toExternalForm() + '/' + this.technicalAccountForMigration.Id;
        return String.format(
            'Enterprise Account ID: {0}\nAccount link: {1}',
            new List<Object> {this.technicalAccountForMigration.RC_User_ID__c, accUrl}
        );
    }

    @TestVisible
    private String constructCCMigrationName(String recordSystemName, Integer maxLength) {
        String constructedName = String.format(
            CC_LEGACY_BASE_LINE_OPPORTUNITY_NAME_FORMAT,
            new List<String> {recordSystemName, this.technicalAccountForMigration.Name}
        );
        return StringHelper.getSafeLengthString(constructedName, maxLength);
    }

    @TestVisible
    private void requestDataFromNGBS() {
        String billingId = technicalAccountForMigration.Billing_ID__c;
        ngbsAccountPackage = getNGBSAccountPackage(billingId);
        bInfo = NGBSAPI.getBillingInfo(billingId, ngbsAccountPackage.Id);
        packageLimit = requestPackageLimit(billingId, ngbsAccountPackage.Id);
    }

    private BillingWrappers.NGBSPackageLimit requestPackageLimit(String billingId, String packageId) {
        String endpoint = String.format(NGBSAPI.NGBS_PACKAGE_LIMITS_F0RMAT, new List<String> {billingId, packageId});
        HttpResponse response = NGBSAPI.requestNGBS(endpoint, HttpHelper.METHOD_GET);

        BillingWrappers.NGBSPackageLimit packageLimit = getPackageLimit(response.getBody());
        validatePackageLimit(packageLimit);

        return packageLimit;
    }

    @TestVisible
    private static BillingWrappers.NGBSPackageLimit getPackageLimit(String responseBody) {
        return (BillingWrappers.NGBSPackageLimit) new ListOptional(
            (List<BillingWrappers.NGBSPackageLimit>) JSON.deserialize(responseBody, List<BillingWrappers.NGBSPackageLimit>.class)
        ).getFirst();
    }

    private void validatePackageLimit(BillingWrappers.NGBSPackageLimit packageLimit) {
        String errorMessage = '';
        if (packageLimit.value == null) {
            errorMessage += NGBS_DID_NOT_RETURN_MONTHLY_LIMIT_MESSAGE + '\n';
        }

        if (packageLimit.limitOverride?.value == null) {
            errorMessage += NGBS_DID_NOT_RETURN_SIGNUP_PURCHASE_LIMIT_MESSAGE + '\n';
        }

        if (String.isBlank(errorMessage)) {
            return;
        }

        AquivaHelper.throwAquivaException(
            String.format(
                MIGRATION_ERROR_MESSAGE,
                new List<String> {'NGBSPackageLimit request', errorMessage}
            )
        );
    }

    private void updateLimitsOnTechnicalAccount(Id quoteId) {
        this.technicalAccountForMigration.Monthly_Credit_Limit__c = this.packageLimit.value;
        this.technicalAccountForMigration.Sign_Up_Purchase_Limit__c = this.packageLimit.limitOverride.value;
        this.technicalAccountForMigration.Account_Payment_Method__c = AccountHelper.PAYMENT_METHOD_INVOICE;
        this.technicalAccountForMigration.Payment_Method__c = AccountHelper.PAYMENT_METHOD_INVOICE;
        this.technicalAccountForMigration.Active_Sales_Agreement__c = quoteId;

        Database.update(this.technicalAccountForMigration);
    }

    @TestVisible
    private static BillingWrappers.NGBSAccountPackage getNGBSAccountPackage(String accountId) {
        if (accountId == null) {
            return null;
        }
        BillingWrappers.NGBSAccountPackage ngbsPackage;
        try {
            String responseBody = NGBSAPI.getNGBSAccountSummary(accountId);
            BillingWrappers.NGBSAccount acc = (BillingWrappers.NGBSAccount) JSON.deserialize(responseBody, BillingWrappers.NGBSAccount.class);
            ngbsPackage = acc.getPackage();
            if (ngbsPackage != null) {
                Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(responseBody);

                // the word "currency" is reserved by sfdc
                List<Object> packageInfo = (List<Object>) responseMap.get(PACKAGES_PROPERTY);
                Map<String, Object> packageInfoMap = (Map<String, Object>) packageInfo.get(0);
                if (packageInfoMap.get(CURRENCY_PROPERTY) != null) {
                    ngbsPackage.currencyCode = String.valueOf(packageInfoMap.get(CURRENCY_PROPERTY));
                }
            }
        } catch (Exception e) {
            AquivaHelper.throwAquivaException(
                'Unexpected error occurred while retrieving account from NGBS.' +
                ' Please contact administrator', e.getCause());
        }
        return ngbsPackage;
    }

    private void updateQlis(Id quoteId) {
        List<QuoteLineItem> qlis = (List<QuoteLineItem>) new QuoteLineItemSelector()
            .selectQuoteLineItemsByQuoteIds(quoteId)
            .executeQuery();
        for (QuoteLineItem qli : qlis) {
            qli.IsMultiProductTechnicalQLI__c = true;
        }
        Triggers.switchOff();
        DataBase.update(qlis);
        Triggers.switchOn();
    }
}