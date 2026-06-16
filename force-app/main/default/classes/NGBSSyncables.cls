public with sharing class NGBSSyncables {

    public static ISyncable getSyncable(Id quoteId, Opportunity opp) {
        return getSyncable(AccountHelper.isMPUBAccount(opp.Account), quoteId, opp);
    }

    public static ISyncable getSyncable(Boolean isMPUB, Id quoteId) {
        return getSyncable(isMPUB, quoteId, null);
    }

    public static ISyncable getSyncable(Boolean isMPUB, Id quoteId, Opportunity opp) {
        return BooleanHelper.toBoolean(isMPUB)
            ? createServiceInfoSync(opp, quoteId)
            : createOpportunitySync(opp, quoteId);
    }

    private static ISyncable createServiceInfoSync(Opportunity opp, Id quoteId) {
        ServiceInfo__c serviceInfo = (ServiceInfo__c) new ListOptional(
            new ServiceInfoSelector()
                .selectServiceInfoForNGBSSyncablesByQuoteId(quoteId)
                .executeQuery())
            .getFirst();
        return serviceInfo != null ? new ServiceInfoSync(serviceInfo) : createOpportunitySync(opp, quoteId);
    }

    private static ISyncable createOpportunitySync(Opportunity opp, Id quoteId) {
        if (opp == null) {
            opp = (Opportunity) new ListOptional(
                new OpportunitySelector()
                    .selectOpportunitiesForSyncWithNGBSByQuoteIds(new Set<Id> {quoteId})
                    .executeQuery())
                .getFirst();
        }
        return new OpportunitySync(opp);
    }

    public interface ISyncable {
        String getSyncInfoField();
        SObject getSObjectToUpdate();
        Map<String, SObjectField> getNameToSObjectFieldMap();
        Map<SObjectField, Object> getSObjFieldsToUpdate();
        void setFSCSynced();
        void setIsDownsellCaseCreated();
        void setOrderDate(Date orderDate);
        void setSyncInfo(String updatedSyncInfo);
        void setNGBSSyncExecutorInfo(String updatedExecutorInfo);
        String getNGBSSyncExecutorInfo();
        void setFlagSynced(SObjectField field);
        void updateSObject();

        /* ICB Sync flag methods */
        void setICBSynced();
        void setICBNotSynced();
        void setICBProvisioning();

        /* SyncInfo methods */
        Boolean isDiscountsSynced();
        Boolean isContractsSynced();
        Boolean isResyncContractAllowed();
        Boolean isRepriceSynced();
        Boolean isUpsellStepCompleted();
        Boolean isDownsellStepCompleted();
        Boolean isUpgradeStepCompleted();
        Boolean isLicenseLimitsSynced();
        Boolean isContractCancelled();
        Boolean isOrderStepCompleted();
        Boolean isInvoiceStepCompleted();
        Boolean isSpendingLimitRetrieveStepCompleted();
        Boolean isTerminationStepCompleted();
        Boolean isSyncedToICB();
        Boolean isICBProvisioningComplete();
        Boolean isChargeTermSynced();
        Boolean isFSCSynced();
        Boolean isDownsellCaseCreated();
        Boolean getBooleanFlagByStepName(String stepName);
    }

    public abstract class SyncableBase implements ISyncable {
        protected Map<SObjectField, Object> fieldsToUpdate = new Map<SObjectField, Object>();
        protected final Map<String, SObjectField> stepNameToFieldMap;
        protected SObject sObjectToUpdate;

        public SyncableBase() {
            this.stepNameToFieldMap = new Map<String, SObjectField>();
            setStepNameToFieldMap();
        }

        protected abstract void setStepNameToFieldMap();

        public void updateSObject(Boolean withoutTriggers) {
            if (this.fieldsToUpdate.isEmpty()) {
                return;
            }

            for (SObjectField f : this.fieldsToUpdate.keySet()) {
                this.sObjectToUpdate.put(f, this.fieldsToUpdate.get(f));
            }

            if (withoutTriggers == true) {
                Triggers.switchOff();
                update this.sObjectToUpdate;
                Triggers.switchOn();
            } else {
                update this.sObjectToUpdate;
            }
        }

        public SObject getSObjectToUpdate() {
            return this.sObjectToUpdate;
        }

        public void updateSObject() {
            updateSObject(true);
        }

        public void setFlagSynced(SObjectField field) {
            this.fieldsToUpdate.put(field, true);
        }

        public void setFlagNotSynced(SObjectField field) {
            this.fieldsToUpdate.put(field, false);
        }

        public Map<SObjectField, Object> getSObjFieldsToUpdate() {
            return this.fieldsToUpdate;
        }

        public Map<String, SObjectField> getNameToSObjectFieldMap() {
            return this.stepNameToFieldMap;
        }
    }

    public class OpportunitySync extends SyncableBase {
        private Opportunity opp;

        protected override void setStepNameToFieldMap() {
            this.stepNameToFieldMap.putAll(new Map<String, SObjectField> {
                SWNStep.CONTRACT_CANCELLATION => Opportunity.isContractCancelled__c,
                SWNStep.CONTRACT_SYNC => Opportunity.isContractsSynced__c,
                SWNStep.DISCOUNT_SYNC => Opportunity.isDiscountsSynced__c,
                SWNStep.SYNC_INVOICE => Opportunity.isInvoiceStepCompleted__c,
                SWNStep.UPDATE_LICENSE_LIMITS => Opportunity.isLicenseLimitsSynced__c,
                SWNStep.ORDER => Opportunity.isOrderStepCompleted__c,
                SWNStep.REPRICE_SYNC => Opportunity.isRepriceSynced__c,
                SWNStep.SYNC_TO_NGBS_DOWNSELL => Opportunity.isDownsellStepCompleted__c,
                SWNStep.SYNC_TO_NGBS_UPSELL => Opportunity.isUpsellStepCompleted__c,
                SWNStep.SYNC_TO_NGBS_UPGRADE => Opportunity.isUpgradeStepCompleted__c,
                SWNStep.CHARGE_TERM_SYNC => Opportunity.isChargeTermSynced__c,
                SWNStep.SYNC_SPENDING_LIMIT_RETRIEVE => Opportunity.IsSpendingLimitRetrieveStepCompleted__c,
                SWNStep.SYNC_TO_CCB_DOWNSELL => Opportunity.isDownsellStepCompleted__c,
                SWNStep.SYNC_TO_CCB_UPSELL => Opportunity.isUpsellStepCompleted__c,
                SWNStep.ENGAGE_ACCOUNT_TERMINATION => Opportunity.isTerminationStepCompleted__c,
                SWNStep.SYNC_TO_CCB_UPGRADE => Opportunity.isUpgradeStepCompleted__c,
                SWNStep.DOWN_SELL => Opportunity.isDownsellStepCompleted__c,
                SWNStep.UP_SELL => Opportunity.isUpsellStepCompleted__c,
                SWNStep.UPGRADE => Opportunity.isUpgradeStepCompleted__c
            });
        }

        public OpportunitySync(Opportunity opp) {
            this.opp = opp;
            this.sObjectToUpdate = new Opportunity(Id = this.opp.Id);
        }

        public String getSyncInfoField() {
            return this.opp.SyncInfo__c;
        }

        public Boolean getBooleanFlagByStepName(String stepName) {
            return stepName != null
                && this.stepNameToFieldMap.get(stepName) != null
                && Boolean.valueOf(this.opp.get(this.stepNameToFieldMap.get(stepName)));
        }

        public Boolean isDiscountsSynced() {
            return this.opp.isDiscountsSynced__c;
        }

        public Boolean isContractsSynced() {
            return this.opp.isContractsSynced__c;
        }

        public Boolean isResyncContractAllowed() {
            return this.opp.isResyncContractAllowed__c;
        }

        public Boolean isRepriceSynced() {
            return this.opp.isRepriceSynced__c;
        }

        public Boolean isUpsellStepCompleted() {
            return this.opp.isUpsellStepCompleted__c;
        }

        public Boolean isDownsellStepCompleted() {
            return this.opp.isDownsellStepCompleted__c;
        }

        public Boolean isUpgradeStepCompleted() {
            return this.opp.isUpgradeStepCompleted__c;
        }

        public Boolean isLicenseLimitsSynced() {
            return this.opp.isLicenseLimitsSynced__c;
        }

        public Boolean isContractCancelled() {
            return this.opp.isContractCancelled__c;
        }

        public Boolean isOrderStepCompleted() {
            return this.opp.isOrderStepCompleted__c;
        }

        public Boolean isInvoiceStepCompleted() {
            return this.opp.isInvoiceStepCompleted__c;
        }

        public Boolean isSpendingLimitRetrieveStepCompleted() {
            return this.opp.IsSpendingLimitRetrieveStepCompleted__c;
        }

        public Boolean isTerminationStepCompleted() {
            return this.opp.isTerminationStepCompleted__c;
        }

        public Boolean isSyncedToICB() {
            return this.opp.isSyncedToICB__c;
        }

        public Boolean isICBProvisioningComplete() {
            return this.opp.isICBProvisioningComplete__c;
        }

        public Boolean isChargeTermSynced() {
            return this.opp.isChargeTermSynced__c;
        }

        public Boolean isFSCSynced() {
            return this.opp.isFSCSynced__c;
        }

        public Boolean isDownsellCaseCreated() {
            return this.opp.IsDownsellCaseCreated__c;
        }

        public void setIsDownsellCaseCreated() {
            this.setFlagSynced(Opportunity.IsDownsellCaseCreated__c);
        }

        public void setFSCSynced() {
            this.setFlagSynced(Opportunity.isFSCSynced__c);
        }

        public void setICBSynced() {
            this.setFlagSynced(Opportunity.isSyncedToICB__c);
        }

        public void setICBNotSynced() {
            this.setFlagNotSynced(Opportunity.isSyncedToICB__c);
        }

        public void setICBProvisioning() {
            this.setFlagSynced(Opportunity.isICBProvisioningComplete__c);
        }

        public void setOrderDate(Date orderDate) {
            this.fieldsToUpdate.put(Opportunity.OrderDate__c, orderDate);
        }

        public void setSyncInfo(String updatedSyncInfo) {
            this.fieldsToUpdate.put(Opportunity.SyncInfo__c, updatedSyncInfo);
        }

        public void setNGBSSyncExecutorInfo(String updatedExecutorInfo) {
            this.fieldsToUpdate.put(Opportunity.NGBS_Sync_Executor_Info__c, updatedExecutorInfo);
        }

        public String getNGBSSyncExecutorInfo() {
            return this.opp.NGBS_Sync_Executor_Info__c;
        }
    }

    public class ServiceInfoSync extends SyncableBase {
        private ServiceInfo__c serviceInfo;

        protected override void setStepNameToFieldMap() {
            this.stepNameToFieldMap.putAll(new Map<String, SObjectField>{
                SWNStep.CONTRACT_CANCELLATION => ServiceInfo__c.ContractCancellationStepStatus__c,
                SWNStep.CONTRACT_SYNC => ServiceInfo__c.ContractStepStatus__c,
                SWNStep.DISCOUNT_SYNC => ServiceInfo__c.DiscountStepStatus__c,
                SWNStep.SYNC_INVOICE => ServiceInfo__c.InvoiceStepStatus__c,
                SWNStep.UPDATE_LICENSE_LIMITS => ServiceInfo__c.LicenseLimitsStepStatus__c,
                SWNStep.ORDER => ServiceInfo__c.OrderStepStatus__c,
                SWNStep.REPRICE_SYNC => ServiceInfo__c.RepriceStepStatus__c,
                SWNStep.SYNC_TO_NGBS_DOWNSELL => ServiceInfo__c.DownsellStepStatus__c,
                SWNStep.SYNC_TO_NGBS_UPSELL => ServiceInfo__c.UpsellStepStatus__c,
                SWNStep.SYNC_TO_NGBS_UPGRADE => ServiceInfo__c.UpgradeStepStatus__c,
                SWNStep.CHARGE_TERM_SYNC => ServiceInfo__c.ChargeTermStepStatus__c,
                SWNStep.SYNC_SPENDING_LIMIT_RETRIEVE => ServiceInfo__c.SpendingLimitRetrieveStepStatus__c,
                SWNStep.SYNC_TO_CCB_DOWNSELL => ServiceInfo__c.DownsellStepStatus__c,
                SWNStep.SYNC_TO_CCB_UPSELL => ServiceInfo__c.UpsellStepStatus__c,
                SWNStep.ENGAGE_ACCOUNT_TERMINATION => ServiceInfo__c.TerminationStepStatus__c,
                SWNStep.SYNC_TO_CCB_UPGRADE => ServiceInfo__c.UpgradeStepStatus__c,
                SWNStep.DOWN_SELL => ServiceInfo__c.DownsellStepStatus__c,
                SWNStep.UP_SELL => ServiceInfo__c.UpsellStepStatus__c,
                SWNStep.UPGRADE => ServiceInfo__c.UpgradeStepStatus__c
            });
        }

        public ServiceInfoSync(ServiceInfo__c serviceInfo) {
            this.serviceInfo = serviceInfo;
            this.sObjectToUpdate = new ServiceInfo__c(Id = this.serviceInfo.Id);
        }

        public String getSyncInfoField() {
            return this.serviceInfo.SyncInfo__c;
        }

        public Boolean getBooleanFlagByStepName(String stepName) {
            return stepName != null
                && this.stepNameToFieldMap.get(stepName) != null
                && Boolean.valueOf(this.serviceInfo.get(this.stepNameToFieldMap.get(stepName)));
        }

        public Boolean isDiscountsSynced() {
            return this.serviceInfo.DiscountStepStatus__c;
        }

        public Boolean isContractsSynced() {
            return this.serviceInfo.ContractStepStatus__c;
        }

        public Boolean isResyncContractAllowed() {
            return this.serviceInfo.IsResyncContractAllowed__c;
        }

        public Boolean isRepriceSynced() {
            return this.serviceInfo.RepriceStepStatus__c;
        }

        public Boolean isUpsellStepCompleted() {
            return this.serviceInfo.UpsellStepStatus__c;
        }

        public Boolean isDownsellStepCompleted() {
            return this.serviceInfo.DownsellStepStatus__c;
        }

        public Boolean isUpgradeStepCompleted() {
            return this.serviceInfo.UpgradeStepStatus__c;
        }

        public Boolean isLicenseLimitsSynced() {
            return this.serviceInfo.LicenseLimitsStepStatus__c;
        }

        public Boolean isContractCancelled() {
            return this.serviceInfo.ContractCancellationStepStatus__c;
        }

        public Boolean isOrderStepCompleted() {
            return this.serviceInfo.OrderStepStatus__c;
        }

        public Boolean isInvoiceStepCompleted() {
            return this.serviceInfo.InvoiceStepStatus__c;
        }

        public Boolean isSpendingLimitRetrieveStepCompleted() {
            return this.serviceInfo.SpendingLimitRetrieveStepStatus__c;
        }

        public Boolean isTerminationStepCompleted() {
            return this.serviceInfo.TerminationStepStatus__c;
        }

        public Boolean isSyncedToICB() {
            return this.serviceInfo.ICBSyncStepStatus__c;
        }

        public Boolean isICBProvisioningComplete() {
            return this.serviceInfo.ICBProvisioningStepStatus__c;
        }

        public Boolean isChargeTermSynced() {
            return this.serviceInfo.ChargeTermStepStatus__c;
        }

        public Boolean isFSCSynced() {
            return this.serviceInfo.FSCStepStatus__c;
        }

        public Boolean isDownsellCaseCreated() {
            return this.serviceInfo.IsDownsellCaseCreated__c;
        }

        public void setIsDownsellCaseCreated() {
            this.setFlagSynced(ServiceInfo__c.IsDownsellCaseCreated__c);
        }

        public void setFSCSynced() {
            this.setFlagSynced(ServiceInfo__c.FSCStepStatus__c);
        }

        public void setICBSynced() {
            this.setFlagSynced(ServiceInfo__c.ICBSyncStepStatus__c);
        }

        public void setICBNotSynced() {
            this.fieldsToUpdate.put(ServiceInfo__c.ICBSyncStepStatus__c, false);
        }

        public void setICBProvisioning() {
            this.setFlagSynced(ServiceInfo__c.ICBProvisioningStepStatus__c);
        }

        public void setOrderDate(Date orderDate) {
            this.fieldsToUpdate.put(ServiceInfo__c.OrderDate__c, orderDate);
        }

        public void setSyncInfo(String updatedSyncInfo) {
            this.fieldsToUpdate.put(ServiceInfo__c.SyncInfo__c, updatedSyncInfo);
        }

        public void setNGBSSyncExecutorInfo(String updatedExecutorInfo) {
            this.fieldsToUpdate.put(ServiceInfo__c.NGBSSyncExecutorInfo__c, updatedExecutorInfo);
        }

        public String getNGBSSyncExecutorInfo() {
            return this.serviceInfo.NGBSSyncExecutorInfo__c;
        }
    }
}