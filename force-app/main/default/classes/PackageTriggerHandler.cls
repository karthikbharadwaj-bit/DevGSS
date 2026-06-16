public with sharing class PackageTriggerHandler {
    static Set<SObjectField> IN_CONTACT_PACKAGE_FIELDS = new Set<SObjectField> {
        Package__c.inContact_account_ID__c,
        Package__c.Provision_Date__c,
        Package__c.Service_Status__c,
        Package__c.inContact_Cluster__c,
        Package__c.InContact_Service__c
    };

    private static Set<Schema.SObjectField> ACCOUNT_FIELDS_SERVICE_INFO = new Set<SObjectField> {
        Account.Account_Payment_Method__c,
        Account.RC_Account_Status__c,
        Account.RC_Service_name__c,
        Account.Service_Version__c,
        Account.Price_per_DL__c,
        Account.Total_Account_DL_s__c,
        Account.Provision_Date__c,
        Account.Bill_As_Of_Date__c
    };

    private static final Map<SObjectField, SObjectField> FIELDS_TO_UPDATE_MAP = new Map<SObjectField, SObjectField> {
        Package__c.Total_DLs__c => Account.Total_DLs__c,
        Package__c.Acquisition_No_of_DL__c => Account.Acquisition_No_of_DL__c,
        Package__c.Additional_Phone_s__c => Account.Additional_Phone_s__c,
        Package__c.Purchased_DL_s__c => Account.Purchased_DL_s__c,
        Package__c.Number_of_DL_s__c => Account.Number_of_DL_s__c,
        Package__c.Number_of_Extensions__c => Account.Number_of_Extensions__c,
        Package__c.Number_of_IP_Devices__c => Account.Number_of_IP_Devices__c,
        Package__c.Licenses_Purchased__c => Account.Licenses_Purchased__c,
        Package__c.Number_of_Leased_Devices__c => Account.Number_of_Leased_Devices__c,
        Package__c.Number_of_Events_Users__c => Account.CombinedNumberofEventsUsers__c
    };

    private static final Map<SObjectField, SObjectField> SLOW_MRR_FIELDS_TO_UPDATE_MAP = new Map<SObjectField, SObjectField> {
        Package__c.EDAcquisitionMRR__c => Account.CombinedEDAcquisitionMRR__c,
        Package__c.EngageDigitalMRR__c => Account.CombinedEngageDigitalMRR__c,
        Package__c.EngageVoiceMRR__c => Account.CombinedEngageVoiceMRR__c,
        Package__c.EVAcquisitionMRR__c => Account.CombinedEVAcquisitionMRR__c,
        Package__c.MVPAcquisitionMRR__c => Account.CombinedMVPAcquisitionMRR__c,
        Package__c.MVPCurrentTotalMRR__c => Account.CombinedMVPCurrentTotalMRR__c,
        Package__c.Total_MRR__c => Account.Total_MRR__c,
        Package__c.CCAcquisitionMRR__c => Account.CombinedCCAcquisitionMRR__c,
        Package__c.Events_Acquisition_MRR__c => Account.CombinedEventsAcquisitionMRR__c,
        Package__c.Events_MRR__c => Account.CombinedEventsMRR__c
    };

    private static final Map<SObjectField, SObjectField> ORDER_MRR_FIELDS_TO_UPDATE_MAP = new Map<SObjectField, SObjectField> {
        Package__c.No_of_InContact_Seats__c => Account.No_of_InContact_Seats__c,
        Package__c.EDAdditionalProductsMRR__c => Account.CombinedEDAdditionalProductsMRR__c,
        Package__c.EngageDigitalUserMRR__c => Account.CombinedEngageDigitalUserMRR__c,
        Package__c.EVAdditionalProductsMRR__c => Account.CombinedEVAdditionalProductsMRR__c,
        Package__c.EngageVoiceUserMRR__c => Account.CombinedEngageVoiceUserMRR__c,
        Package__c.AdditionalProductsMRR__c => Account.Additional_Products_MRR__c,
        Package__c.NumberOfEngageDigitalUsers__c => Account.CombinedNumberOfEngageDigitalUsers__c,
        Package__c.NumberOfEngageVoiceSeats__c => Account.CombinedNumberOfEngageVoiceSeats__c,        
        Package__c.SeatMRR__c => Account.Seat_MRR__c,
        Package__c.Events_Additional_Products_MRR__c => Account.CombinedEventsAdditionalProductsMRR__c,
        Package__c.Events_User_MRR__c => Account.CombinedEventsUserMRR__c
    };

    private static final Set<SObjectField> FIELDS_TO_UPDATE = FIELDS_TO_UPDATE_MAP.keySet();
    private static final Set<SObjectField> SLOW_MRR_FIELDS_TO_UPDATE = SLOW_MRR_FIELDS_TO_UPDATE_MAP.keySet();
    private static final Set<SObjectField> ORDER_MRR_FIELDS_TO_UPDATE = ORDER_MRR_FIELDS_TO_UPDATE_MAP.keySet();


    public enum ServiceType {
        OFFICE,
        RINGCENTRAL_CONTACT_CENTER,
        ENGAGE_DIGITAL,
        ENGAGE_VOICE,
        EVENTS
    }

    private static Map<String, ServiceType> serviceTypeMap = new Map<String, ServiceType>{
        AccountHelper.SERVICE_TYPE_OFFICE => ServiceType.OFFICE,
        AccountHelper.SERVICE_TYPE_RCCC => ServiceType.RINGCENTRAL_CONTACT_CENTER,
        AccountHelper.SERVICE_TYPE_ENGAGE_DIGITAL => ServiceType.ENGAGE_DIGITAL,
        AccountHelper.SERVICE_TYPE_ENGAGE_VOICE => ServiceType.ENGAGE_VOICE,
        AccountHelper.SERVICE_TYPE_ENGAGE_DIGITAL_LEGACY => ServiceType.ENGAGE_DIGITAL,
        AccountHelper.SERVICE_TYPE_ENGAGE_VOICE_LEGACY => ServiceType.ENGAGE_VOICE,
        AccountHelper.SERVICE_TYPE_RC_EVENT => ServiceType.EVENTS
    };

    public class SendElaDataToNGBS extends Triggers.TriggerHandlerBase {
        private ElaNGBSIntegrationService elaNGBSIntegrationService = new ElaNGBSIntegrationService();

        override public void handle() {
            List<Id> accountIds = (List<Id>) AquivaHelper.collectFieldValues(List<Id>.class, Trigger.new, 'Enterprise_Account_ID__c', true);

            if (accountIds.isEmpty()) {
                return;
            }

            List<Account> paidBillingAccountsWithPackage = elaNGBSIntegrationService.getBillingPaidAccountsWithPackages(new Set<Id>(accountIds));

            if (paidBillingAccountsWithPackage.isEmpty()) {
                return;
            }

            elaNGBSIntegrationService.handleBillingAccSignUp(paidBillingAccountsWithPackage);
        }

        override public Boolean bypass() {
            return Test.isRunningTest();
        }
    }

    public class UpdateARPUOnTechnicalPackages extends Triggers.TriggerHandlerBase {
        override public void handle() {
            for(Package__c bap: (List<Package__c>) Trigger.new) {
                if(isChangedField(bap, Package__c.Sales_Order_MRS__c) || isChangedField(bap, Package__c.NumberOfMainLicenses__c)) {
                    bap.ARPU__c = (Decimal) NumberHelper.getNumberNullSafe(bap.NumberOfMainLicenses__c) != 0
                            ? (Decimal) NumberHelper.getNumberNullSafe(bap.Sales_Order_MRS__c) / (Decimal) NumberHelper.getNumberNullSafe(bap.NumberOfMainLicenses__c)
                            : 0;
                }
            }
        }
    }

    public class ConnectServiceAccountToOrder extends Triggers.TriggerHandlerBase {
        override public void handle() {
            List<Id> masterAccountIds = (List<Id>) AquivaHelper.collectFieldValues(List<Id>.class, Trigger.new, 'Account__c', true);

            if (masterAccountIds.isEmpty()) {
                return;
            }

            List<Account> accountsWithOrders = (List<Account>) new AccountSelector()
                .selectAccountsForConnectServiceAccountToOrder(new List<Object>{masterAccountIds})
                .executeQuery();

            Map<String, List<Order>> productNameToOrders = new Map<String, List<Order>>();
            for (Account acc : accountsWithOrders) {
                for (Order order : acc.Orders) {
                    BillingWrappers.QuotePackageInfo pInfo = QuoteHelper.getPackageInfo(order.TechnicalQuoteId__r);

                    String productName = pInfo?.productName;
                    if (!productNameToOrders.containsKey(productName)) {
                        productNameToOrders.put(productName, new List<Order>());
                    }
                    productNameToOrders.get(productName).add(order);
                }
            }

            List<Order> ordersToUpdate = new List<Order>();
            for (Package__c bap : (List<Package__c>) this.TriggerRecords) {
                if (String.isNotBlank(bap.Service_Type__c) && productNameToOrders.containsKey(bap.Service_Type__c)) {
                    for (Order order : productNameToOrders.get(bap.Service_Type__c)) {
                        if (bap.Account__c == order.AccountId && order.PackageId__c == null) {
                            order.PackageId__c = bap.Id;
                            ordersToUpdate.add(order);
                        }
                    }
                }
            }

            if (!ordersToUpdate.isEmpty()) {
                update ordersToUpdate;
            }
        }
    }

    public class UpdateServiceMRRFieldsOnAccount extends Triggers.TriggerHandlerBase {
        private Set<SObjectField> PACKAGE_REVENUE_FIELDS = new Set<SObjectField> {
            Package__c.ARPU__c
        };

        override public void handle() {
            System.debug('UpdateServiceMRRFieldsOnAccount ' + Trigger.new.size());
            List<Package__c> billingAccountPackages = new List<Package__c>();
            for(Package__c bap: (List<Package__c>) Trigger.new) {

                if(!isChangedAnyField(bap, PACKAGE_REVENUE_FIELDS)) {
                    continue;
                }

                billingAccountPackages.add(bap);
            }

            if (billingAccountPackages.isEmpty()) {
                return;
            }

            List<Id> accountIds = (List<Id>) AquivaHelper.collectFieldValues(List<Id>.class, billingAccountPackages, 'Enterprise_Account_ID__c', true);

            if (accountIds.isEmpty()) {
                return;
            }

            billingAccountPackages = new PackageSelector()
                .selectPackagesByEnterpriseAccountIdsWithAccountTotals(accountIds)
                .executeQuery();

            Map<Id, Account> recordsToUpdate = new Map<Id, Account>();

            for (Id accountId : accountIds) {
                Account updatedAccount = new Account(Id = accountId);
                Boolean isUpdated = false;

                for(Package__c bap: billingAccountPackages) {
                    if (String.isBlank(bap.Enterprise_Account_ID__c)) {
                        continue;
                    }

                    Account acc = bap.Enterprise_Account_ID__r;

                    if (acc.Id != accountId) {
                        continue;
                    }

                    Decimal ccARPU = null;
                    Decimal edARPU = null;
                    Decimal evARPU = null;
                    Decimal eventARPU = null;

                    Decimal arpu = (Decimal) NumberHelper.getNumberNullSafe(bap.ARPU__c);

                    if (bap.Service_Type__c == QuoteHelper.NGBS_RCCC_PRODUCT) {
                        ccARPU = (Decimal) NumberHelper.getNumberNullSafe(ccARPU) + arpu;
                    } else if (bap.Service_Type__c == QuoteHelper.NGBS_ENGAGE_DIGITAL_PRODUCT) {
                        edARPU = (Decimal) NumberHelper.getNumberNullSafe(edARPU) + arpu;
                    } else if (bap.Service_Type__c == QuoteHelper.NGBS_ENGAGE_VOICE_PRODUCT) {
                        evARPU = (Decimal) NumberHelper.getNumberNullSafe(evARPU) + arpu;
                    } else if (bap.Service_Type__c == QuoteHelper.NGBS_RCEVENTS_PRODUCT) {
                        eventARPU = (Decimal) NumberHelper.getNumberNullSafe(eventARPU) + arpu;
                    }

                    Decimal currentCcARPU = acc.inContactARPU__c;
                    Decimal currentEdARPU = acc.EngageDigitalARPU__c;
                    Decimal currentEvARPU = acc.EngageVoiceARPU__c;
                    Decimal currentEventARPU = acc.EventsARPU__c;

                    if (ccARPU != null && (ccARPU != currentCcARPU)) {
                        updatedAccount.inContactARPU__c = ccARPU;
                        isUpdated = true;
                    }
                    if (edARPU != null && (edARPU != currentEdARPU)) {
                        updatedAccount.EngageDigitalARPU__c = edARPU;
                        isUpdated = true;
                    }
                    if (evARPU != null && (evARPU != currentEvARPU)) {
                        updatedAccount.EngageVoiceARPU__c = evARPU;
                        isUpdated = true;
                    }
                    if (eventARPU != null && (eventARPU != currentEventARPU)) {
                        updatedAccount.EventsARPU__c = eventARPU;
                        isUpdated = true;
                    }
                }
                if (isUpdated) {
                    recordsToUpdate.put(updatedAccount.Id, updatedAccount);
                }
            }

            if (!recordsToUpdate.isEmpty()) {
                Triggers.switchOff();
                Triggers.except('AccountTriggerHandler.UpdateServiceMRRFieldsOnMasterAccount');
                update recordsToUpdate.values();
                Triggers.switchOn();
            }
        }
    }

    public class UpdateReportedMRSOnTechnicalPackages extends Triggers.TriggerHandlerBase {
        override public void handle() {
            System.debug('UpdateReportedMRSOnTechnicalPackages ' + Trigger.new.size());
            List<Package__c> billingAccountPackages = new List<Package__c>();

            for (Package__c bap: (List<Package__c>) Trigger.new) {
                if(!isChangedField(bap, Package__c.Sales_Order_MRS__c)) {
                    continue;
                }

                billingAccountPackages.add(bap);
            }

            if (billingAccountPackages.isEmpty()) {
                return;
            }

            List<Id> accountIds = (List<Id>) AquivaHelper.collectFieldValues(List<Id>.class, billingAccountPackages, 'Enterprise_Account_ID__c', true);

            if(accountIds.isEmpty()) {
                return;
            }

            billingAccountPackages = new PackageSelector()
                .selectPackagesByEnterpriseAccountIdsWithAccountTotals(accountIds)
                .executeQuery();

            List<Package__c> recordsToUpdate = new List<Package__c>();
            for(Package__c bap: (List<Package__c>) billingAccountPackages) {
                if (bap.Service_Type__c == QuoteHelper.NGBS_OFFICE_PRODUCT) {
                    continue;
                }

                Package__c updatedPackage = new Package__c(Id = bap.Id);
                Decimal reportedMRS = PackageHelper.getReportedMRS(bap, bap.Enterprise_Account_ID__r);

                if (reportedMRS != null) {
                    if (bap.Reported_MRS__c != reportedMRS) {
                        updatedPackage.Reported_MRS__c = reportedMRS;
                        recordsToUpdate.add(updatedPackage);
                    }
                }
            }

            if(!recordsToUpdate.isEmpty()) {
                System.debug(recordsToUpdate.size());
                System.debug(recordsToUpdate);
                update recordsToUpdate;
            }
        }
    }

    public class CopyEngageFieldsFromAccount extends Triggers.TriggerHandlerBase {
        public CopyEngageFieldsFromAccount() {
            super();
        }

        public CopyEngageFieldsFromAccount(TriggerOperation operationType, List<Package__c> newList) {
            super(true, operationType, newList);
        }

        override public void handle() {
            Set<Id> accountIds = new Set<Id>();
            for (Package__c bap : (List<Package__c>) triggerRecords) {
                if (String.isBlank(bap.Account__c)
                    || !isChangedFieldToAnyString(bap, Package__c.Service_Type__c, QuoteHelper.NGBS_ENGAGES_STANDALONE)
                ) {
                    continue;
                }
                accountIds.add(bap.Account__c);
            }

            if (accountIds.isEmpty()) {
                return;
            }

            Map<Id, Account> accountsMap = new Map<Id, Account>((List<Account>) new AccountSelector()
                .selectAccountForEngagePackageByAccIds(new List<Object> {accountIds})
                .executeQuery());

            populateEngagePackageFields((List<Package__c>) triggerRecords, accountsMap);
        }

        private void populateEngagePackageFields(List<Package__c> packages, Map<Id, Account> accountsMap) {
            for (Package__c bap : packages) {
                Account acc = accountsMap.get(bap.Account__c);
                List<Account> techAccs = acc.Master_Accounts__r;
                Boolean isMPLite = !techAccs.isEmpty();

                // RC_Engage_Account_ID__c is the common field for EV/ED service for the MPUB flow
                // because signUp is not allowed for both of them under one Account
                // however for the MPL flow this field is populated only on technical Accounts
                if (String.isBlank(acc.RC_Engage_Account_ID__c) && !isMPLite) {
                    continue;
                }

                if (isMPLite) {
                    acc = getTargetAccountFromTechnicalOnes(techAccs, bap);
                }

                if (acc == null) {
                    continue;
                }

                bap.RC_Engage_Account_ID__c = acc.RC_Engage_Account_ID__c;
                // populate EV fields on Package__c
                if (String.isNotBlank(acc.EV_Account_ID__c)) {
                    bap.EV_Account_ID__c = acc.EV_Account_ID__c;
                    bap.EV_Platform__c = acc.EV_Platform__c;
                    continue;
                }
                // populate ED fields on Package__c
                bap.ED_Account_ID__c = acc.ED_Account_ID__c;
                bap.Engage_Domain__c = acc.Engage_Domain__c;
                bap.ED_Platform__c = acc.ED_Platform__c;
            }
        }

        private Account getTargetAccountFromTechnicalOnes(List<Account> accs, Package__c bap) {
            Account targetAcc;
            for (Account acc : accs) {
                // Package__c Enterprise_Account_ID__c field stores technical Account Id for the MPL data model
                if (acc.Id.equals(bap.Enterprise_Account_ID__c)) {
                    targetAcc = acc;
                    break;
                }
            }
            return targetAcc;
        }
    }

    public class CopyFieldsFromAccount extends Triggers.TriggerHandlerBase {
        override public void handle() {
            System.debug('CopyFieldsFromAccount ' + Trigger.new.size());
            List<Package__c> billingAccountPackages = new List<Package__c>();

            for (Package__c bap : (List<Package__c>) triggerRecords) {
                if (!isChangedField(bap, Package__c.Enterprise_Account_ID__c)) {
                    continue;
                }

                billingAccountPackages.add(bap);
            }

            if (billingAccountPackages.isEmpty()) {
                return;
            }

            List<Id> accountIds = (List<Id>) AquivaHelper.collectFieldValues(List<Id>.class, billingAccountPackages, 'Enterprise_Account_ID__c', true);

            if (accountIds.isEmpty()) {
                return;
            }

            processPackagesForMasterAccounts(accountIds);
        }
    }

    @future
    private static void processPackagesForMasterAccounts(List<Id> accountIds) {
        List<Package__c> billingAccountPackages = new PackageSelector()
            .selectPackagesByEnterpriseAccountIdsWithServiceFields(accountIds)
            .executeQuery();

        List<Package__c> recordsToUpdate = new List<Package__c>();
        for (Package__c bap : (List<Package__c>) billingAccountPackages) {
            Account account = bap.Enterprise_Account_ID__r;

            Package__c updatedRecord = new Package__c(Id = bap.Id);
            Boolean isUpdated = false;

            for (SObjectField field: ACCOUNT_FIELDS_SERVICE_INFO) {
                String fieldName = field.getDescribe().getName();
                Object fieldValue = account.get(fieldName);

                if(field.getDescribe().isUpdateable()) {
                    if(bap.get(fieldName) != fieldValue) {
                        if (fieldName == 'Service_Type__c' && String.isBlank((String) fieldValue)) {
                            updatedRecord.put(fieldName, QuoteHelper.NGBS_OFFICE_PRODUCT);
                            isUpdated = true;
                            continue;
                        }
                        updatedRecord.put(fieldName, fieldValue);
                        isUpdated = true;
                    }
                }
            }

            if (isUpdated) {
                recordsToUpdate.add(updatedRecord);
            }
        }

        if(!recordsToUpdate.isEmpty()) {
            System.debug(recordsToUpdate.size());
            System.debug(recordsToUpdate);
            update recordsToUpdate;
        }
    }

    public class SyncEnabledLBOOnQuote extends Triggers.TriggerHandlerBase {
        override public void handle() {
            List<Id> accIds = new List<Id>();
            List<Quote> quotes = new List<Quote>();
            List<Quote> quotesToUpdate = new List<Quote>();
            List<Package__c> packages = new List<Package__c>();
            Map<String, Boolean> enabledLBOFromPackagesMap = new Map<String, Boolean>();

            for (Package__c pckg : (List<Package__c>) Trigger.new) {
                if (isChangedField(pckg, Package__c.EnabledLBO__c)) {
                    accIds.add(pckg.Account__c);
                }
            }

            if (accIds.isEmpty()) {
                return;
            }

            packages = new PackageSelector()
                    .selectPackagesForAccountUpdateByAccountIds(accIds)
                    .executeQuery();

            quotes = new QuoteSelector()
                    .selectQuotesForPackageTriggerEnabledLBO(accIds)
                    .selectFields(new List<String> {
                        'Account.RC_Account_Status__c',
                        'Account.Offer_Type__c'
                    })
                    .executeQuery();

            for (Package__c pckg : packages) {
                Boolean accountValue = BooleanHelper.toBoolean(enabledLBOFromPackagesMap.get(pckg.Account__c))
                    ? true
                    : pckg.EnabledLBO__c;
                enabledLBOFromPackagesMap.put(pckg.Account__c, accountValue);
            }

            for (Quote qt : quotes) {
                qt.IsShowSmokeModifiedMessage__c = true;
                Boolean enabledLBOFromPackages = BooleanHelper.toBoolean(enabledLBOFromPackagesMap.get(qt.AccountId));
                Boolean isPOCToPaid = AccountHelper.isPOCToPaid(qt.Account);

                // LBO => True
                if (
                    isPOCToPaid ||
                    enabledLBOFromPackages &&
                    !(QuoteHelper.isNew(qt) && AccountHelper.isExistingBusiness(qt?.Account))
                ) {
                    qt.Enabled_LBO__c = true;
                    quotesToUpdate.add(qt);
                }

                // LBO => False
                if (
                    !isPOCToPaid &&
                    !enabledLBOFromPackages &&
                    QuoteHelper.isNewBillingQuote(qt)
                    && !QuoteHelper.isNew(qt)
                ) {
                    qt.Enabled_LBO__c = false;
                    quotesToUpdate.add(qt);
                }
            }

            if (!quotesToUpdate.isEmpty()) {
                QueueableDMLExecuter.enqueueJob(quotesToUpdate, QueueableDMLExecuter.DMLType.DML_UPDATE);
            }
        }
    }

    public class CopyContactCenterServiceFieldsToMasterAccount extends Triggers.TriggerHandlerBase {
        private final Map<SObjectField, SObjectField> fieldCopyMap = new Map<SObjectField, SObjectField> {
            Package__c.MinuteBundle__c => Account.Minute_Bundle__c,
            Package__c.TransportMRR__c => Account.Actual_transport_MRR__c,
            Package__c.Bill_As_Of_Date__c => Account.Bill_As_Of_Date__c
        };
        override public void handle() {
            List<Id> bapIds = new List<Id>();
            List<Package__c> packagesToUpdate = new List<Package__c>();
            for (Package__c bap: (List<Package__c>) Trigger.new) {
                if (bap.Service_Type__c == QuoteHelper.NGBS_RCCC_PRODUCT) {
                    bapIds.add(bap.Id);
                }
            }

            if (bapIds.isEmpty()) {
                return;
            }

            List<Package__c> baps = new PackageSelector()
                .selectPackagesById(bapIds)
                .executeQuery();
            List<Account> accountsToUpdate = new List<Account>();
            for (Package__c bap : baps) {
                Account accToUpdate = new Account(Id = bap.Account__c);
                Boolean isUpdated = false;
                if (bap.get('SeatMRR__c') != null && bap.get('NumberOfMainLicenses__c') != null) {
                    if (bap.NumberOfMainLicenses__c == 0 ) {
                        bap.Price_per_Seat__c = bap.SeatMRR__c;
                    } else {
                        bap.Price_per_Seat__c = bap.SeatMRR__c / bap.NumberOfMainLicenses__c;
                    }
                    packagesToUpdate.add(bap);
                }
                for (SObjectField field: fieldCopyMap.keySet()) {
                    if (bap.get(field) != null) {
                        accToUpdate.put(fieldCopyMap.get(field), bap.get(field));
                        isUpdated = true;
                    }
                }
                if (isUpdated) {
                    accountsToUpdate.add(accToUpdate);
                }
            }

            Triggers.switchOff();
            if (!packagesToUpdate.isEmpty()) {
                update packagesToUpdate;
            }
            Triggers.switchOn();

            if (!accountsToUpdate.isEmpty()) {
                Triggers.switchOff();
                update accountsToUpdate;
                Triggers.switchOn();
            }
        }
    }

    public class UpdateAccountFieldsFromBAP extends Triggers.TriggerHandlerBase {
        override public void handle() {
            List<Id> accIds = new List<Id>();
            Map<Id, Account> accsToUpdate = new Map<Id, Account>();

            for (Package__c bap: (List<Package__c>) this.triggerRecords) {
                if (
                    isUpdate() &&
                    !isChangedAnyField(bap, FIELDS_TO_UPDATE) &&
                    !isChangedAnyField(bap, SLOW_MRR_FIELDS_TO_UPDATE) &&
                    !isChangedAnyField(bap, ORDER_MRR_FIELDS_TO_UPDATE)
                ) {
                    continue;
                }
                accIds.add(bap.Account__c);
            }
            if (accIds.isEmpty()) {
                return;
            }

            List<Package__c> baps = new PackageSelector()
                .selectPackagesForAccountUpdateByAccountIds(accIds)
                .executeQuery();

            Map<Id, List<Package__c>> accIdToBapMap = new Map<Id, List<Package__c>>();
            for (Package__c bap : baps) {
                if (!accIdToBapMap.containsKey(bap.Account__c)) {
                    accIdToBapMap.put(bap.Account__c, new List<Package__c>());
                }
                accIdToBapMap.get(bap.Account__c).add(bap);
            }

            for (Package__c bap : (List<Package__c>) this.triggerRecords) {
                if (!accsToUpdate.containsKey(bap.Account__c)) {
                    accsToUpdate.put(bap.Account__c, new Account(Id = bap.Account__c));
                }
                Account accountToUpdate = accsToUpdate.get(bap.Account__c);
                List<Package__c> bapsForAccount = accIdToBapMap.get(bap.Account__c);

                Map<Set<SObjectField>, Map<SObjectField, SObjectField>> fieldSetsToUpdateMaps = new Map<Set<SObjectField>, Map<SObjectField, SObjectField>>{
                    FIELDS_TO_UPDATE => FIELDS_TO_UPDATE_MAP,
                    SLOW_MRR_FIELDS_TO_UPDATE => SLOW_MRR_FIELDS_TO_UPDATE_MAP,
                    ORDER_MRR_FIELDS_TO_UPDATE => ORDER_MRR_FIELDS_TO_UPDATE_MAP
                };
                for (Set<SObjectField> fieldSet : fieldSetsToUpdateMaps.keySet()) {
                    if ((isInsert() || isUpdate()) && isChangedAnyField(bap, fieldSet)) {
                        for (SObjectField field : fieldSet) {
                            updateAccountFieldFromPackage(field, bapsForAccount, fieldSetsToUpdateMaps.get(fieldSet), accountToUpdate, accsToUpdate);
                        }
                    }
                }

            }

            List<Account> accsToUpdateList = accsToUpdate.values();
            if (!accsToUpdateList.isEmpty()) {
                Triggers.switchOff();
                update accsToUpdateList;
                Triggers.switchOn();
            }
        }

        private void updateAccountFieldFromPackage(
            SObjectField field,
            List<Package__c> baps,
            Map<SObjectField, SObjectField> fieldsMap,
            Account accountToUpdate,
            Map<Id, Account> accsToUpdate
        ) {
            SObjectField accountField = fieldsMap.get(field);
            Decimal totalValue = 0;
            for (Package__c bap : baps) {
                Decimal packageValue = (Decimal) bap.get(field);
                if (packageValue != null) {
                    totalValue += packageValue;
                }
            }

            accountToUpdate.put(accountField, totalValue);
            accsToUpdate.put(accountToUpdate.Id, accountToUpdate);
        }
    }

    public class CreateCaseForManualProvisioningMPUB extends Triggers.TriggerHandlerBase {
        override public void handle() {
            Set<Id> bapIds = new Set<Id>();
            Set<Id> masterAccountIds = new Set<Id>();
            for (Package__c bap: (List<Package__c>) this.TriggerRecords) {
                bapIds.add(bap.Id);
                masterAccountIds.add(bap.Account__c);
            }

            if (bapIds.isEmpty() || masterAccountIds.isEmpty()) {
                return;
            }

            List<Quote> quotesForAccounts = (List<Quote>) new QuoteSelector()
                .selectQuotesForOrderActivationProcess(new List<Object>{masterAccountIds})
                .executeQuery();

            Set<Id> orderIds = new Set<Id>();
            for (Quote quote : quotesForAccounts) {
                if (quote.Orders3__r.isEmpty() || quote.ServiceInfo__r.isEmpty()) {
                    continue;
                }

                for (Order order : quote.Orders3__r) {
                    if (bapIds.contains(order.PackageId__c)) {
                        orderIds.add(order.Id);
                    }
                }
            }
            if (System.isBatch() || System.isFuture()) {
                List<Order> ordersWithItems = (List<Order>) new OrderSelector()
                    .selectOrdersByIdsForManualProvisioningCaseCreationProcessMPUB(orderIds)
                    .executeQuery();

                DealDeskCaseGenerator.createCaseForManualProvisioningMPUB(ordersWithItems);
            } else {
                DealDeskCaseGenerator.createCaseForManualProvisioningMPUBFuture(orderIds);
            }
        }
    }

    public class ActivateNewestOrders extends Triggers.TriggerHandlerBase {
        override public void handle() {
            Set<Id> bapIds = new Set<Id>();
            Set<Id> masterAccountIds = new Set<Id>();

            for (Package__c bap: (List<Package__c>) this.TriggerRecords) {
                if (PackageHelper.PACKAGE_STATUS_ACTIVE.equals(bap.Package_Status__c) && String.isNotBlank(bap.Account__c) && bap.Service_Type__c!= QuoteHelper.NGBS_PROFESSIONAL_SERVICES_PRODUCT ) {
                    bapIds.add(bap.Id);
                    masterAccountIds.add(bap.Account__c);
                }
            }

            if (bapIds.isEmpty() || masterAccountIds.isEmpty()) {
                return;
            }

            List<Quote> quotesForAccounts = (List<Quote>) new QuoteSelector()
                .selectQuotesForOrderActivationProcess(new List<Object>{masterAccountIds})
                .executeQuery();

            List<Order> ordersToUpdate = new List<Order>();
            for (Quote quote : quotesForAccounts) {
                if (quote.Orders3__r.isEmpty() || quote.ServiceInfo__r.isEmpty()) {
                    continue;
                }

                for (Order order : quote.Orders3__r) {
                    if (bapIds.contains(order.PackageId__c)) {
                        ordersToUpdate.add(new Order(
                            Id = order.Id,
                            Status = OrderHelper.STATUS_ACTIVATED
                        ));
                    }
                }
                if (!ordersToUpdate.isEmpty()) {
                    update ordersToUpdate;
                }
            }
        }
    }

    public class PopulateIsRingCxFieldOnMasterAccount extends Triggers.TriggerHandlerBase {
        Set<SObjectField> PACKAGE_FIELDS_TO_CHECK = new Set<SObjectField>{
            Package__c.Package_Name__c,
            Package__c.Package_Status__c
        };

        public PopulateIsRingCxFieldOnMasterAccount() {
            super();
        }

        public PopulateIsRingCxFieldOnMasterAccount(TriggerOperation operationType, List<Package__c> newList) {
            super(true, operationType, newList);
        }

        override public void handle() {
            Map<Id, Account> accsForUpdate = new Map<Id, Account>();

            for (Package__c pkg : (List<Package__c>) triggerRecords) {
                if (String.isBlank(pkg.Package_Name__c) || !isChangedAnyField(pkg, PACKAGE_FIELDS_TO_CHECK)
                    || !pkg.Package_Name__c.containsIgnoreCase(PackageHelper.RINGCX_PACKAGE_NAME)) {
                    continue;
                }
                accsForUpdate.put(pkg.Account__c, new Account(
                    Id = pkg.Account__c,
                    IsRingCx__c = StringHelper.safeString(pkg.Package_Status__c)
                        .containsIgnoreCase(PackageHelper.PACKAGE_STATUS_ACTIVE)
                ));
            }

            List<Account> accsToUpdateList = accsForUpdate.values();
            if (!accsToUpdateList.isEmpty()) {
                Triggers.switchOff();
                update accsToUpdateList;
                Triggers.switchOn();
            }
        }
    }

    public class PopulateInContactFieldsFromParentAccount extends Triggers.TriggerHandlerBase {
        public PopulateInContactFieldsFromParentAccount() {
            super();
        }

        public PopulateInContactFieldsFromParentAccount(TriggerOperation operationType, List<Package__c> newList) {
            super(true, operationType, newList);
        }

        override public void handle() {
            Map<Package__c, Set<Id>> packageToAccountIds = new Map<Package__c, Set<Id>>();

            for (Package__c pkg : (List<Package__c>) triggerRecords) {
                if (isSkip(pkg)) {
                    continue;
                }

                packageToAccountIds.put(pkg, new Set<Id> {pkg.Account__c, pkg.Enterprise_Account_ID__c});
            }

            if (packageToAccountIds.isEmpty()) {
                return;
            }
            Set<Id> targetAccIds = new Set<Id>();
            for (Set<Id> ids : packageToAccountIds.values()) {
                targetAccIds.addAll(ids);
            }
            targetAccIds.remove(null);

            Map<Id, Account> accIdToAccount = selectAccounts(targetAccIds);

            for (Package__c pkg : packageToAccountIds.keySet()) {
                for (SObjectField field : IN_CONTACT_PACKAGE_FIELDS) {
                    if (!isEmptyField(pkg, field)) {
                        continue;
                    }
                    String fieldName = field.toString();
                    Object masterValue = accIdToAccount.get(pkg.Account__c)?.get(fieldName);
                    Object childValue = accIdToAccount.get(pkg.Enterprise_Account_ID__c)?.get(fieldName);
                    pkg.put(fieldName, masterValue ?? childValue);
                }
            }
        }

        private Boolean isSkip(Package__c pkg) {
            return String.isBlank(pkg.Account__c)
                || pkg.Service_Type__c != QuoteHelper.NGBS_RCCC_PRODUCT
                || !hasEmptyFieldValue(pkg);
        }

        private Boolean hasEmptyFieldValue(Package__c pkg) {
            for (SObjectField field : IN_CONTACT_PACKAGE_FIELDS) {
                if (isEmptyField(pkg, field)) {
                    return true;
                }
            }
            return false;
        }

        private Map<Id, Account> selectAccounts(Set<Id> accIds) {
            return new Map<Id, Account>((List<Account>) new AccountSelector()
                .selectAccountsByIdNoFields(new List<Object> {accIds})
                .selectFields(IN_CONTACT_PACKAGE_FIELDS)
                .executeQuery());
        }

        private Boolean isEmptyField(Package__c pkg, SObjectField field) {
            return String.isBlank(StringHelper.safeString(pkg.get(field)));
        }
    }

    public class UpdateMarketingAttributionFields extends Triggers.TriggerHandlerBase {

        public UpdateMarketingAttributionFields() {
            super();
        }

        public UpdateMarketingAttributionFields(TriggerOperation operationType, List<SObject> newRecords) {
            super(true, operationType, newRecords);
        }

        override public void handle() {
            Set<Id> accIds = new Set<Id>();
            List<Package__c> targetPkgs = new List<Package__c>();

            collectData(accIds, targetPkgs);
            if (accIds.isEmpty()) {
                return;
            }

            Map<Id, Account> accountsMap = new Map<Id, Account>((List<Account>) new AccountSelector()
                .selectAccsForMarketingAttributionUpdate(new List<Object> {accIds})
                .executeQuery());

            Map<Id, List<Package__c>> accIdToPackagesMap = PackageHelper.mapAccountIdToPackages(targetPkgs);
            populatedExistingPackages(accountsMap, accIdToPackagesMap);
            Map<Id, Package__c> accIdFieldPackageMap = PackageHelper.collectAccIdToPackageMap(accIdToPackagesMap);

            Map<Id, Account> accountsToUpdate = new Map<Id, Account>();
            Set<Id> packageIdsToUpdate = new Set<Id>();
            for (Id accId : accIdFieldPackageMap.keySet()) {
                Account accountToUpdate = accountsMap.get(accId);
                Package__c targetPackage = accIdFieldPackageMap.get(accId);

                AccountHelper.prepareAccountForUpdating(targetPackage, accountToUpdate, accountsToUpdate);

                if (!targetPackage.IsUsedForAccountAttribution__c && accountsToUpdate.containsKey(accId)) {
                    packageIdsToUpdate.add(targetPackage.Id);
                }
            }

            PackageHelper.markPackagesAsMarketing(packageIdsToUpdate);

            if (!accountsToUpdate.isEmpty()) {
                Triggers.switchOff();
                update accountsToUpdate.values();
                Triggers.switchOn();
            }
        }

        @TestVisible
        private void collectData(Set<Id> accIds, List<Package__c> targetPkgs) {
            for (Package__c bap : (List<Package__c>) triggerRecords) {
                if (String.isBlank(bap.Service_Type__c) || String.isBlank(bap.Account__c)) {
                        continue;
                    }
                if (isUpdate() && !isChangedAnyField(bap, PackageHelper.PACKAGE_FIELDS)) {
                    continue;
                }

                accIds.add(bap.Account__c);
                targetPkgs.add(bap);
            }
        }

        @TestVisible
        private void populatedExistingPackages(
            Map<Id, Account> accountsMap,
            Map<Id, List<Package__c>> accIdToPackagesMap
        ) {
            for (Id accId : accIdToPackagesMap.keySet()) {
                Package__c accPackage = (Package__c) ListHelper.first(accountsMap.get(accId)?.Service_Accounts__r);
                if (accPackage == null) {
                    continue;
                }
                List<Package__c> accPackages = accIdToPackagesMap.get(accId);
                if (!new Map<Id, Package__c>(accPackages).containsKey(accPackage.Id)) {
                    accPackages.add(accPackage);
                }
            }
        }
    }

    public class PopulatePackageMRRFields extends Triggers.TriggerHandlerBase {
        private Set<SObjectField> PACKAGE_MRR_FIELDS = new Set<SObjectField> {
            Package__c.MRR__c,
            Package__c.aMRR__c
        };

        private ServiceType getServiceTypeEnum(String serviceType) {
            return serviceTypeMap.get(serviceType);
        }

        override public void handle() {
            for (Package__c pkg : (List<Package__c>) this.triggerRecords) {
                if (shouldSkipUpdate(pkg)) {
                    continue;
                }

                updateMRRFields(pkg);
            }
        }

        private Boolean shouldSkipUpdate(Package__c pkg) {
            if (Trigger.isUpdate) {
                ServiceType serviceType = getServiceTypeEnum(pkg?.Service_Type__c);
                switch on serviceType {
                    when OFFICE {
                        return pkg.MRR__c == pkg.MVPCurrentTotalMRR__c && pkg.aMRR__c == pkg.MVPAcquisitionMRR__c;
                    }
                    when RINGCENTRAL_CONTACT_CENTER {
                        return pkg.MRR__c == pkg.Total_MRR__c && pkg.aMRR__c == pkg.CCAcquisitionMRR__c;
                    }
                    when ENGAGE_DIGITAL {
                        return pkg.MRR__c == pkg.EngageDigitalMRR__c && pkg.aMRR__c == pkg.EDAcquisitionMRR__c;
                    }
                    when ENGAGE_VOICE {
                        return pkg.MRR__c == pkg.EngageVoiceMRR__c && pkg.aMRR__c == pkg.EVAcquisitionMRR__c;
                    }
                    when EVENTS {
                        return pkg.MRR__c == pkg.Events_MRR__c && pkg.aMRR__c == pkg.Events_Acquisition_MRR__c;
                    }
                }
            }
            return pkg.MRR__c == null && pkg.aMRR__c == null;
        }


        private void updateMRRFields(Package__c pkg) {
            ServiceType serviceType = getServiceTypeEnum(pkg?.Service_Type__c);
            switch on serviceType {
                when OFFICE {
                    pkg.MVPCurrentTotalMRR__c = pkg?.MRR__c;
                    pkg.MVPAcquisitionMRR__c = pkg?.aMRR__c;
                }
                when RINGCENTRAL_CONTACT_CENTER {
                    pkg.Total_MRR__c = pkg?.MRR__c;
                    pkg.CCAcquisitionMRR__c = pkg?.aMRR__c;
                }
                when ENGAGE_DIGITAL {
                    pkg.EngageDigitalMRR__c = pkg?.MRR__c;
                    pkg.EDAcquisitionMRR__c = pkg?.aMRR__c;
                }
                when ENGAGE_VOICE {
                    pkg.EngageVoiceMRR__c = pkg?.MRR__c;
                    pkg.EVAcquisitionMRR__c = pkg?.aMRR__c;
                }
                when EVENTS {
                    pkg.Events_MRR__c = pkg?.MRR__c;
                    pkg.Events_Acquisition_MRR__c = pkg?.aMRR__c;
                }
            }
        }
    }

    public class UpdateAccountDateFields extends Triggers.TriggerHandlerBase {
        Map<SObjectField, SObjectField> MVP_PACKAGE_DATE_FIELDS = new Map<SObjectField, SObjectField> {
            Package__c.RC_Signup_Date__c => Account.RC_Signup_Date__c,
            Package__c.RC_Activation_Date__c => Account.RC_Activation_Date__c,
            Package__c.RC_Upgrade_Date__c => Account.RC_Upgrade_Date__c
        };
        Map<SObjectField, SObjectField> CANCEL_PACKAGE_DATE_FIELDS = new Map<SObjectField, SObjectField> {
            Package__c.RC_Churn_Date__c => Account.RC_Churn_Date__c,
            Package__c.RC_Cancel_Date__c => Account.RC_Cancel_Date__c
        };

        override public void handle() {
            Set<Id> accIds = new Set<Id>();
            Map<Id, Account> accountsToUpdate = new Map<Id, Account>();

            for (Package__c bap: (List<Package__c>) this.triggerRecords) {
                if (Trigger.isUpdate &&
                    !isChangedAnyField(bap, MVP_PACKAGE_DATE_FIELDS.keySet())
                    && !isChangedAnyField(bap, CANCEL_PACKAGE_DATE_FIELDS.keySet())
                ) {
                    continue;
                }
                accIds.add(bap.Account__c);
            }

            if (accIds.isEmpty()) {
                return;
            }

            Map<Id, Account> accountsMap = new Map<Id, Account>((List<Account>) new AccountSelector()
                .selectAccountsDateFieldsUpdateByAccountIds(new List<Object> {accIds})
                .executeQuery());

            List<Package__c> packages = new PackageSelector()
                .selectPackagesForDateFieldsUpdateByAccountIds(new List<Object> {accIds})
                .executeQuery();

                Map<Id, List<Package__c>> accountToPackagesMap = PackageHelper.mapAccountIdToPackages(packages);
            List<Package__c> packagesToProcess = PackageHelper.filterPackagesByCreatedDateAndService(packages);

            for (Package__c packageToProcess : packagesToProcess) {
                for (SObjectField packageField : MVP_PACKAGE_DATE_FIELDS.keySet()) {
                    Account accountToUpdate = accountsMap.get(packageToProcess.Account__c);
                    SObjectField accountField = MVP_PACKAGE_DATE_FIELDS.get(packageField);
                    Object packageFieldValue = packageToProcess.get(packageField);
                    Object accountFieldValue = accountToUpdate.get(accountField);

                    if (packageFieldValue != null && accountFieldValue == null && accountFieldValue != packageFieldValue) {
                        accountToUpdate.put(accountField, packageFieldValue);
                        accountsToUpdate.put(accountToUpdate.Id, accountToUpdate);
                    }
                }
            }

            updateChurnAndCancelDates(accountToPackagesMap, accountsToUpdate, accountsMap);

            if (!accountsToUpdate.values().isEmpty()) {
                Triggers.switchOff();
                update accountsToUpdate.values();
                Triggers.switchOn();
            }
        }

        private void updateChurnAndCancelDates(Map<Id, List<Package__c>> accountToPackagesMap, Map<Id, Account> accountsToUpdate, Map<Id, Account> accountsMap) {
            for (Id accountId : accountToPackagesMap.keySet()) {
                Account acc = accountsMap.get(accountId);
                Account accountToUpdate = accountsToUpdate.get(accountId) ?? new Account(Id = accountId);

                Datetime latestChurnDate = getLatestDate(accountToPackagesMap.get(accountId), Package__c.RC_Churn_Date__c);
                Datetime latestCancelDate = getLatestDate(accountToPackagesMap.get(accountId), Package__c.RC_Cancel_Date__c);

                accountToUpdate.RC_Cancel_Date__c = latestCancelDate;

                if (latestChurnDate != null) {
                    accountToUpdate.RC_Churn_Date__c = latestChurnDate.addDays(90);
                } else {
                    accountToUpdate.RC_Churn_Date__c = null;
                }

                accountsToUpdate.put(accountToUpdate.Id, accountToUpdate);
            }
        }

        private Datetime getLatestDate(List<Package__c> packages, SObjectField fieldName) {
            Datetime latestDate = null;
            Boolean allPackagesHaveDate = true;

            for (Package__c pkg : packages) {
                Datetime dateValue = (Datetime) pkg.get(fieldName);
                if (dateValue != null) {
                    latestDate = (latestDate == null || dateValue > latestDate) ? dateValue : latestDate;
                } else {
                    allPackagesHaveDate = false;
                }
            }

            return allPackagesHaveDate ? latestDate : null;
        }
    }

    public class PopulateServiceRelatedFields extends Triggers.TriggerHandlerBase {
        override public void handle() {
            Set<Id> accIds = new Set<Id>();
            Map<Id, Approval__c> accountToLastApprovedApproval = new Map<Id, Approval__c>();
            Map<Id, Account_Management__c> accManagementsToUpdate = new Map<Id, Account_Management__c>();
            Map<Id, Deal_Support__c> dealSupportsToUpdate = new Map<Id, Deal_Support__c>();
            Map<Id, Implementation__c> implementationsToUpdate = new Map<Id, Implementation__c>();
            Map<Id, Retention_Task__c> retentionTaksToUpdate = new Map<Id, Retention_Task__c>();
            Map<Id, Account> accountsToUpdate = new Map<Id, Account>();
            List<Package__c> packagesToProcess = (List<Package__c>) this.triggerRecords;
            Feature_Toggle__c featureToggle = Feature_Toggle__c.getInstance();
            Set<Id> packageIds = new Set<Id>();

            for (Package__c bap : packagesToProcess) {
                accIds.add(bap.Account__c);
                packageIds.add(bap.Id);
            }

            if (accIds.isEmpty()) {
                return;
            }

            Map<Id, Account> accountsMap = new Map<Id, Account>((List<Account>) new AccountSelector()
                .selectAccountWithServiceRelatedFields(new List<Object> {accIds})
                .executeQuery());

                accountToLastApprovedApproval = ApprovalHelper.fetchLatestPOCApprovalForEachAccount(accIds);
                for (Package__c pkg : packagesToProcess) {
                    if (Trigger.isInsert || Trigger.isUpdate && isChangedFieldFrom(pkg, Package__c.Service_Type__c, null)) {
                        updateNumberOfPOCUsers(pkg, accountsMap, accountToLastApprovedApproval);
                    }
                }

            List<Package__c> filteredPackages = getFilteredPackages(packagesToProcess, accIds, packageIds);

            updateSignupType(packagesToProcess, accountsMap, featureToggle);
            populateAccountManagementFields(packagesToProcess, accountsMap, accManagementsToUpdate);
            populateDealSupportFields(packagesToProcess, accountsMap, dealSupportsToUpdate);
            populateImplementationFields(packagesToProcess, accountsMap, implementationsToUpdate);
            populateRetentionTaskFields(packagesToProcess, accountsMap, retentionTaksToUpdate);
            populateAccountFields(filteredPackages, accountsMap, accountsToUpdate);

            List<Account_Management__c> accMngsToUpdate = new List<Account_Management__c>(accManagementsToUpdate.values());
            List<Deal_Support__c> dsToUpdate = new List<Deal_Support__c>(dealSupportsToUpdate.values());
            List<Implementation__c> implsToUpdate = new List<Implementation__c>(implementationsToUpdate.values());
            List<Retention_Task__c> rtToUpdate = new List<Retention_Task__c>(retentionTaksToUpdate.values());
            List<Account> accToUpdate = new List<Account>(accountsToUpdate.values());

            Triggers.switchOff();
            if (!accMngsToUpdate.isEmpty()) {
                update accMngsToUpdate;
            }
            if (!dsToUpdate.isEmpty()) {
                update dsToUpdate;
            }
            if (!implsToUpdate.isEmpty()) {
                update implsToUpdate;
            }
            if (!rtToUpdate.isEmpty()) {
                update rtToUpdate;
            }
            if (!accToUpdate.isEmpty()) {
                update accToUpdate;
            }
            Triggers.switchOn();
        }

        private List<Package__c> getFilteredPackages(List<Package__c> packagesToProcess, Set<Id> accIds, Set<Id> packageIds) {
            List<Package__c> fetchedPackages = new PackageSelector()
                .selectPackagesForDateFieldsUpdateByAccountIds(new List<Object> {accIds})
                .executeQuery();
            List<Package__c> packages = new List<Package__c>(packagesToProcess);
            for (Package__c pkg : fetchedPackages) {
                if (!packageIds.contains(pkg.Id)) {
                    packages.add(pkg);
                }
            }
            return PackageHelper.filterPackagesByCreatedDateAndService(packages);
        }

        private void updateNumberOfPOCUsers(Package__c pkg, Map<Id, Account> accountsMap, Map<Id, Approval__c> accountToLastApprovedApproval) {
            if (pkg.Service_Type__c != QuoteHelper.NGBS_OFFICE_PRODUCT) {
                return;
            }
            String rcAccountStatus = accountsMap.get(pkg.Account__c).RC_Account_Status__c;
            Approval__c approval = accountToLastApprovedApproval.get(pkg.Account__c);
            pkg.Number_of_POC_Users__c = approval != null && !AccountHelper.FEATURE_ADD_ONS_ACCOUNT_STATUSES.contains(rcAccountStatus?.toLowerCase()) ? approval.Number_of_POC_Users__c : null;
        }

        private void updateSignupType(List<Package__c> packages, Map<Id, Account> accountsMap, Feature_Toggle__c featureToggle) {
            if (!BooleanHelper.toBoolean(featureToggle?.AccountWorkflowRulesAndProcToTrigger__c)) {
                return;
            }
            for (Package__c pkg : packages) {
                Account acc = accountsMap.get(pkg.Account__c);
                if (pkg.Number_of_POC_Users__c > 0 && (pkg.SignupType__c == null || !acc.Office_30_Day_Trial__c)) {
                    pkg.SignupType__c = AccountTriggerHelper.SIGN_UP_TYPE_TRIAL_30NOCC;
                }

                if (String.isNotBlank(acc.Office_Trial__c)) {
                    if (acc.Office_Trial__c == AccountTriggerHelper.OFFICE_TRIAL_30DAYS) {
                        pkg.SignupType__c = AccountTriggerHelper.SIGN_UP_TYPE_TRIAL_30CC;
                    } else if (acc.Office_Trial__c == AccountTriggerHelper.OFFICE_TRIAL_15DAYS) {
                        pkg.SignupType__c = AccountTriggerHelper.SIGN_UP_TYPE_TRIAL_15CC;
                    }
                }
            }
        }

        private void populateDealSupportFields(List<Package__c> packages, Map<Id, Account> accountsMap, Map<Id, Deal_Support__c> dealSupportsToUpdate){
            for (Package__c pkg : packages) {
                Account acc = accountsMap.get(pkg.Account__c);
                if (acc == null
                    || acc.Deal_Supports1__r.isEmpty()
                    || pkg.Service_Type__c != QuoteHelper.NGBS_OFFICE_PRODUCT
                    || !(isChangedFieldTo(pkg, Package__c.Service_Type__c, QuoteHelper.NGBS_OFFICE_PRODUCT)
                        || isChangedField(pkg, Package__c.RC_Tier_ID__c))
                ) {
                    continue;
                }
                for (Deal_Support__c dsToProcess : acc.Deal_Supports1__r) {
                    dsToProcess.User_ID__c = pkg.RC_Tier_ID__c;
                    dealSupportsToUpdate.put(dsToProcess.Id, dsToProcess);
                }
            }
        }

        private void populateRetentionTaskFields(List<Package__c> packages, Map<Id, Account> accountsMap, Map<Id, Retention_Task__c> retentionTasksToUpdate){
            for (Package__c pkg : packages) {
                Account acc = accountsMap.get(pkg.Account__c);
                if (acc == null
                    || acc.Retention_Tasks__r.isEmpty()
                    || pkg.Service_Type__c != QuoteHelper.NGBS_OFFICE_PRODUCT
                    || !isChangedField(pkg, Package__c.Package_Status__c)
                ) {
                    continue;
                }
                for (Retention_Task__c rtToProcess : acc.Retention_Tasks__r) {
                    rtToProcess.Dunning_Status__c = pkg.Package_Status__c;
                    retentionTasksToUpdate.put(rtToProcess.Id, rtToProcess);
                }
            }
        }

        private void populateAccountFields(List<Package__c> packages, Map<Id, Account> accountsMap, Map<Id, Account> accountsToUpdate){
            for (Package__c pkg : packages) {
                Account acc = accountsMap.get(pkg.Account__c);
                String sn = ServiceNameHandler.getServiceName(pkg.Service_Type__c, acc.RC_Brand__c);
                if (acc == null || acc.RC_Service_name__c == sn) {
                    continue;
                }
                acc.RC_Service_name__c = sn;
                accountsToUpdate.put(acc.Id, acc);
            }
        }

        private void populateAccountManagementFields(List<Package__c> packages, Map<Id, Account> accountsMap, Map<Id, Account_Management__c> accManagementsToUpdate) {
            for (Package__c pkg : packages) {
                Account acc = accountsMap.get(pkg.Account__c);
                if (acc == null
                    || acc.Account_Management__r.isEmpty()
                    || pkg.Service_Type__c != QuoteHelper.NGBS_OFFICE_PRODUCT
                    || !isChangedField(pkg, Package__c.Sales_Booking_MRS__c)
                ) {
                    continue;
                }
                for (Account_Management__c accManagement : acc.Account_Management__r) {
                    accManagement.Sales_Booking_MRS_Converted__c = pkg.Sales_Booking_MRS__c;
                    accManagementsToUpdate.put(accManagement.Id, accManagement);
                }
            }
        }

        private void populateImplementationFields(List<Package__c> packages, Map<Id, Account> accountsMap, Map<Id, Implementation__c> implementationsToUpdate) {
            if (packages.isEmpty()) {
                return;
            }
            for (Package__c pkg : (List<Package__c>) this.triggerRecords) {
                Account acc = accountsMap.get(pkg.Account__c);
                if (acc == null
                    || acc.Implementations__r.isEmpty()
                    || !isChangedField(pkg, Package__c.Service_Version_Label__c)
                    || pkg.Service_Type__c != QuoteHelper.NGBS_OFFICE_PRODUCT
                ) {
                    continue;
                }
                for (Implementation__c implToProcess : acc.Implementations__r) {
                    implToProcess.Service_Version_Name__c = pkg.Service_Version_Label__c;
                    implementationsToUpdate.put(implToProcess.Id, implToProcess);
                }
            }
        }
    }

    public class PopulatePackageForRelatedProSerQuotes extends Triggers.TriggerHandlerBase {
        override public void handle() {
            Set<Id> packageIds = new Set<Id>();
            for (Package__c bap : (List<Package__c>) this.triggerRecords) {
                if (bap.Service_Type__c == PackageHelper.PROSERV_SERVICE_TYPE) {
                    packageIds.add(bap.Id);
                }
            }

            if (packageIds.isEmpty()) {
                return;
            }

            List<Order> proservOrders = (List<Order>) new OrderSelector()
                .selectProServOrderByPackageIdsUB(packageIds)
                .executeQuery();

            List<Quote> techQuoteForUpdate = new List<Quote>();
            for (Order order: proservOrders) {
                techQuoteForUpdate.add(new Quote(
                    Id = order.TechnicalQuoteId__c,
                    BillingPackage__c = order.PackageId__c
                ));
            }

            if (!techQuoteForUpdate.isEmpty()) {
                Triggers.switchOff();
                update techQuoteForUpdate;
                Triggers.switchOn();
            }
        }
    }

    public class CreateProservProjectAndPSIntegration extends Triggers.TriggerHandlerBase {
        override public void handle() {
            Set<Id> opptyIdSet = new Set<Id>();
            for (Package__c bap : (List<Package__c>) this.triggerRecords) {
                if (bap.Service_Type__c == PackageHelper.PROSERV_SERVICE_TYPE && bap.Opportunity__c != null) {
                    opptyIdSet.add(bap.Opportunity__c);
                }
            }

            if (opptyIdSet.isEmpty()) {
                return;
            }

            List<Order> proservOrders = (List<Order>) new OrderSelector()
                .selectOrdersByOpportunityIds(new List<Object> {opptyIdSet, new List<String> {OrderHelper.TYPE_INITIAL_ORDER}})
                .subselect(
                    new SuborderSelector()
                        .selectSuborders()
                        .selectFields(new List<Schema.SObjectField> {
                            Suborder__c.Id,
                            Suborder__c.SuborderNumber__c,
                            Suborder__c.Order__c,
                            Suborder__c.Phase__c,
                            Suborder__c.Status__c
                        })
                        .setCondition('Status__c = \'' + SuborderHelper.STATUS_NEW + '\'')
                )
                .executeQuery();

            List<Proserv_Project__c> proservProjectsToInsert = new List<Proserv_Project__c>();
            for (Order order : proservOrders) {
                if (QuoteHelper.isNewBillingQuote(order?.Quote)) {
                    Proserv_Project__c proservProject = ProServProjectObj.createProject(order);
                    proservProjectsToInsert.add(proservProject);
                }
            }

            if (!proservProjectsToInsert.isEmpty()) {
                insert proservProjectsToInsert;
            }

            Map<Id, List<Suborder__c>> orderIdToSuborderListMap = new Map<Id, List<Suborder__c>>();
            for (Order order : proservOrders) {
                if (order.Suborders__r == null || order.Suborders__r.isEmpty()) {
                    continue;
                }

                if (!orderIdToSuborderListMap.containsKey(order.Id)) {
                    orderIdToSuborderListMap.put(order.Id, new List<Suborder__c>());
                }
                orderIdToSuborderListMap.get(order.Id).addAll(order.Suborders__r);
            }

            if (!orderIdToSuborderListMap.isEmpty()) {
                List<PS_Integration__c> psIntegrationsToUpsert = PSIntegrationHelper.buildPSRecords(orderIdToSuborderListMap, false);
                if (!psIntegrationsToUpsert.isEmpty()) {
                    upsert psIntegrationsToUpsert;
                }
            }
        }
    }
}