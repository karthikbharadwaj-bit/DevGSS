public with sharing class LocalSubscribedAddressTriggerHandler {
	public class ValidateRegisteredAddress extends Triggers.TriggerHandlerBase {

        public ValidateRegisteredAddress() {
            super();
        }

        public ValidateRegisteredAddress(TriggerOperation operationType, List<LocalSubscribedAddress__c> newList) {
            super(true, operationType, newList);
        }

        override public void handle() {
            Set<Id> approvalsId = new Set<Id>();
            for (LocalSubscribedAddress__c lsa : (List<LocalSubscribedAddress__c>) triggerRecords) {
                if (lsa.RecordTypeId == LocalSubscribedAddressHelper.RT_ID_REGISTERED_ADDRESS_OF_COMPANY) {
                    approvalsId.Add(lsa.Approval__c);
                }
			}
            if (approvalsId.isEmpty()) {
				return;
			}
            Map<Id, LocalSubscribedAddress__c> approvalIdToLocalSubscribedAddressesMap = LocalSubscribedAddressHelper.getApprovalLocalSubscribedAddressesMap(LocalSubscribedAddressHelper.RT_ID_REGISTERED_ADDRESS_OF_COMPANY, approvalsId);
            for (LocalSubscribedAddress__c lsa : (List<LocalSubscribedAddress__c>) triggerRecords) {
                if (approvalIdToLocalSubscribedAddressesMap.containsKey(lsa.Approval__c)) {
                    lsa.addError(Label.OnlyOneRegisteredAddress);
					break;
                }
			}
        }
    }

    static final List<String> FILEDS_ALLOWED_FOR_CHANGING = new List<String> {
        'latitudelongitudeevery6months__c',
        'revisiondate__c'
    };

    public class ValidateChangedFieldsAfterApprove extends Triggers.TriggerHandlerBase {

        public ValidateChangedFieldsAfterApprove() {
            super();
        }

        public ValidateChangedFieldsAfterApprove(TriggerOperation operationType, List<LocalSubscribedAddress__c> newList, List<LocalSubscribedAddress__c> oldList) {
            super(true, operationType, newList, oldList, new Map<Id, LocalSubscribedAddress__c>(newList), new Map<Id, LocalSubscribedAddress__c>(oldList));
        }

        override public void handle() {
            if (KycDetailsHelper.isUserProfileHasPermissionToEditKYCRequestAfterFinalAction()) {
                return;
            }
            List<LocalSubscribedAddress__c> addresses = (List<LocalSubscribedAddress__c>) triggerRecords;
            List<Id> approvalsIds = new List<Id>();
            for (LocalSubscribedAddress__c addr : addresses) {
                approvalsIds.add(addr.Approval__c);
            }

            Map<Id, Approval__c> approvals = new Map<Id, Approval__c>(
                (List<Approval__c>) new ApprovalSelector()
                    .selectKYCRequestApprovalById(new List<Object> {approvalsIds})
                    .executeQuery()
            );

            for (LocalSubscribedAddress__c address : addresses) {
                String approvalStatus = approvals.get(address.Approval__c)?.Status__c;
                if (approvalStatus != ApprovalHelper.STATUS_APPROVED 
                    && approvalStatus != ApprovalHelper.STATUS_REJECTED) {
                    continue;
                }
                Map<String, Schema.SObjectField> fields = LocalSubscribedAddressHelper.FIELDS_MAP;
                for (String fieldName : fields.keySet()) {
                    if (LocalSubscribedAddressHelper.PRESERVE_TIMESTAMPS.contains(fieldName)) {
                        continue;
                    }
                    Boolean isFieldChanged = isChangedField(address, fields.get(fieldName));
                    if (approvalStatus == ApprovalHelper.STATUS_REJECTED && isFieldChanged) {
                        address.addError(Label.LocalSubscribedAddressCannotBeChangedAfterReject);
                        break;
                    }
                    if (approvalStatus == ApprovalHelper.STATUS_APPROVED && isFieldChanged && !FILEDS_ALLOWED_FOR_CHANGING.contains(fieldName)) {
                        address.addError(Label.LocalSubscribedAddressCannotBeChangedAfterApprove);
                        break;
                    }
                }
            }
        }
    }

    public class RestrictAddressCreationAfterApproveReject extends Triggers.TriggerHandlerBase {

        public RestrictAddressCreationAfterApproveReject() {
            super();
        }

        public RestrictAddressCreationAfterApproveReject(TriggerOperation operationType, List<LocalSubscribedAddress__c> newList) {
            super(true, operationType, newList);
        }
                
        override public void handle() {
            validateAddresses((List<LocalSubscribedAddress__c>) triggerRecords);
        }
    }

    public class RestrictAddressDeletionAfterApproveReject extends Triggers.TriggerHandlerBase {

        public RestrictAddressDeletionAfterApproveReject() {
            super();
        }

        public RestrictAddressDeletionAfterApproveReject(TriggerOperation operationType, List<LocalSubscribedAddress__c> newList) {
            super(true, operationType, newList);
        }

        override public void handle() {
            validateAddresses((List<LocalSubscribedAddress__c>) triggerRecords);
        }
    }

    private static void validateAddresses (List<LocalSubscribedAddress__c> addresses) {
        if (KycDetailsHelper.isUserProfileHasPermissionToEditKYCRequestAfterFinalAction()) {
            return;
        }
        List<Id> approvalsIds = new List<Id>();
        for (LocalSubscribedAddress__c addr: addresses) {
            approvalsIds.add(addr.Approval__c);
        }
        Map<Id, Approval__c> approvals = new Map<Id, Approval__c>(
            (List<Approval__c>) new ApprovalSelector()
                .selectKYCRequestApprovalById(new List<Object>{approvalsIds})
                .executeQuery()
        );
        for (LocalSubscribedAddress__c address: addresses) {
            String approvalStatus = approvals.get(address.Approval__c)?.Status__c;
            if (approvalStatus == ApprovalHelper.STATUS_APPROVED
                || approvalStatus == ApprovalHelper.STATUS_REJECTED) {
                address.addError(Label.SiteDeletionCreationIsRestrictedAfterApproveReject);
            }
        }
    }

    public class RestrictToDeleteLsaWithBillingAddressRecordType extends Triggers.TriggerHandlerBase {
        override public void handle() {
            if (KycDetailsHelper.isUserProfileHasPermissionToEditKYCRequestAfterFinalAction()) {
                return;
            }
            for (LocalSubscribedAddress__c lsa: (List<LocalSubscribedAddress__c>) Trigger.old) {
                if (lsa.RecordTypeId == LocalSubscribedAddressHelper.RT_ID_BILLING_ADDRESS) {
                    lsa.addError(Label.LsaWithBillingAddressRtCantBeDeleted);
                }
            }
        }
    }

    public class RestrictToCreateMoreThanOneLsaWithBillingAddressRt extends Triggers.TriggerHandlerBase {
        override public void handle() {
            Map<Id, List<LocalSubscribedAddress__c>> approvalToLsaMap = new Map<Id, List<LocalSubscribedAddress__c>>();
            for (LocalSubscribedAddress__c lsa: (List<LocalSubscribedAddress__c>) Trigger.new) {
                if (lsa.RecordTypeId == LocalSubscribedAddressHelper.RT_ID_BILLING_ADDRESS) {
                    if (!approvalToLsaMap.containsKey(lsa.Approval__c)) {
                        approvalToLsaMap.put(lsa.Approval__c, new List<LocalSubscribedAddress__c>());
                    }
                    approvalToLsaMap.get(lsa.Approval__c).add(lsa);
                }
            }
            if (approvalToLsaMap.isEmpty()) {
                return;
            }
            List<LocalSubscribedAddress__c> existingBillingAddressLsa = (List<LocalSubscribedAddress__c>)
                new LocalSubscribedAddressSelector()
                    .selectLocalSubscribedAddressesByApprovals(
                        LocalSubscribedAddressHelper.RT_ID_BILLING_ADDRESS,
                        new List<Object>{approvalToLsaMap.keySet()}
                    )
                    .executeQuery();
            for (LocalSubscribedAddress__c lsa: existingBillingAddressLsa) {
                if (approvalToLsaMap.containsKey(lsa.Approval__c)) {
                    for (LocalSubscribedAddress__c newLsa: approvalToLsaMap.get(lsa.Approval__c)) {
                        newLsa.addError(Label.OnlyOneLsaWithBillingAddressRt);
                    }
                }
            }
        }
    }
}