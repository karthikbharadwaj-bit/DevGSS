public with sharing class AccountContactRoleCreationController {
    public Id accId { get; set; }
    public AccountContactRole contactRole { get; set; }

    private transient List<AccountContactRole> crExistingList_p;
    public transient List<AccountContactRole> crExistingList {
        get {
            if (crExistingList_p == null) {
                Map<String, String> pageParameters = ApexPages.currentPage().getParameters();
                Id accId = pageParameters.get('accId');

                AccountContactRoleSelector accountContactRoleSelector = new AccountContactRoleSelector();

                crExistingList_p = accountContactRoleSelector
                    .selectAccountContactRolesByAccountIds(new List<Id> { accId })
                    .selectField('Account.descartesdps__HasBeenFlaggedByDPS__c')
                    .selectField('Contact.AccountId')
                    .selectField('Contact.Account.descartesdps__HasBeenFlaggedByDPS__c')
                    .executeQuery();
            }
            return crExistingList_p;
        }
    }

    public Map<String, String> pageParameters;
    public final String SIGNATORY_ROLE_LIMIT = 'No more than 2 signatory contact roles are allowed';
    public final String DUPLICATE_ROLE = 'Contact has already been added in that Contact Role';
    public final String SINGLE_PRIMARY_ALLOWED = 'Only one primary contact role is allowed';
    public final String CONTACT_ROLE_EDIT_NOT_ALLOWED = 'You are not allowed to edit Primary and Signatory contact roles';
    public final String CONTACT_ROLE_EDIT_HAS_APPROVERS = 'You cannot edit this Contact Role because it is used on the Approval';
    public final String INVALID_ACCOUNT_PAYBLE_CONTACT_ROLE = 'Please assign Accounts Payable Role to the Contact from this Account';
    public final String FLAGGED_ROLE_NOT_MODIFIED = 'Account Contact Role cannot be modified. Please contact Deal Desk for any questions.';
    public final String PERMESSIONSET_NAME = 'EditAccountContactRole';
    public final String FLAGGED_BY_DESCARTES_ACCOUNT = Label.DPS_Validation_Message;
    public static String UITheme = UserInfo.getUIThemeDisplayed();

    public AccountContactRoleCreationController(ApexPages.StandardController stdController) {
        pageParameters = ApexPages.currentPage().getParameters();
        accId = pageParameters.get('accId');

        contactRole = new AccountContactRole();
        contactRole = new AccountContactRole();
        if (pageParameters.get('crId') != null) {
            contactRole.ContactId = pageParameters.get('contactId');
            contactRole.Role = pageParameters.get('role');
            contactRole.IsPrimary = Boolean.valueOf(pageParameters.get('isPrimary'));
            contactRole.Id = pageParameters.get('crId');
        }
    }

    public PageReference save() {
        if (pageParameters.get('crId') == null) {
            contactRole.AccountId = accId;
        }

        validateContactRole();
        if (ApexPages.hasMessages()) {
            return null;
        }

        upsert contactRole;

        if (UITheme == 'Theme4d') {
            PageReference recdet = new PageReference('/lightning/r/Account/' + accId + '/view');

            recdet.setRedirect(true);
            return recdet;
        }

        PageReference pageReference = new PageReference('/' + accId);
        return pageReference;

    }

    public PageReference saveAndNew() {
        if (pageParameters.get('crId') == null) {
            contactRole.AccountId = accId;
        }

        validateContactRole();
        if (ApexPages.hasMessages()) {
            return null;
        }

        upsert contactRole;

        PageReference pageReference = new PageReference('/apex/AccountContactRoleCreation?accId=' + accId);
        pageReference.setRedirect(true);
        return pageReference;
    }

    public PageReference cancel() {
        if (UITheme == 'Theme4d') {
            PageReference recdet = new PageReference('/lightning/r/Account/' + accId + '/view');

            recdet.setRedirect(true);
            return recdet;
        }

        PageReference pageReference = new PageReference('/' + accId);
        return pageReference;

    }

    public Boolean isAllowedNewSignatory() {
        Integer signatoryQuantity = 0;
        for (AccountContactRole cr : crExistingList) {
            if (cr.Role == 'Signatory' && cr.Id != contactRole.Id) {
                signatoryQuantity++;
            }
        }

        return contactRole.Role != 'Signatory' || contactRole.Role == 'Signatory' && signatoryQuantity < 2;
    }

    private Boolean isDuplicate() {
        Boolean isDuplicate = false;
        for (AccountContactRole cr : crExistingList) {
            if (cr.Role == contactRole.Role && cr.ContactId == contactRole.ContactId && cr.Id != contactRole.Id) {
                isDuplicate = true;
            }
        }

        return isDuplicate;
    }

    private Boolean isPrimaryExist() {
        Boolean isPrimaryExist = false;
        for (AccountContactRole cr : crExistingList) {
            if (cr.IsPrimary && cr.Id != contactRole.Id) {
                isPrimaryExist = true;
            }
        }
        return isPrimaryExist;
    }

    public Boolean isFlaggedAccount() {
        Boolean isFlagged = false;
        Set<Id> roleIds = new Set<Id>();

        if(crExistingList.size() > 0 && crExistingList != null){
            for(AccountContactRole cr : crExistingList){
                if ((cr.AccountId != null && cr.Account.descartesdps__HasBeenFlaggedByDPS__c == true)
                    || (cr.ContactId != null && cr.Contact.AccountId != null && cr.Contact.Account.descartesdps__HasBeenFlaggedByDPS__c == true)) {
                    isFlagged = true;
                }
            }
        }
        return isFlagged;
    }

    private Boolean isHasApprovals() {
        if (contactRole.Role != AccountContactRoleHelper.CONTACT_ROLE_ACCOUNT_PAYABLE
            && pageParameters.get('role') != AccountContactRoleHelper.CONTACT_ROLE_ACCOUNT_PAYABLE) {
            return false;
        }
        if (pageParameters.get('role') != contactRole.Role || pageParameters.get('contactId') != contactRole.ContactId) {
            return ApprovalHelper.validateChangingAccountContactRoles(
                pageParameters.get('accId'),
                contactRole.ContactId
            );
        }
        return false;
    }

    private Boolean isInvalidAccountsPayble() {
        if (contactRole.Role != AccountContactRoleHelper.CONTACT_ROLE_ACCOUNT_PAYABLE) {
            return false;
        }
        if ((pageParameters.get('role') != contactRole.Role || pageParameters.get('contactId') != contactRole.ContactId)) {
            List<Contact> relatedContacts = (List<Contact>) new ContactSelector()
                .selectContactsForAccPayble(new List<Object>{
                    new Set<Id>{
                        contactRole.ContactId
                    },
                    new Set<Id>{
                        accId
                    }
                })
                .executeQuery();

            if (relatedContacts == null || relatedContacts.isEmpty()) {
                return true;
            }
        }
        return false;
    }
    public Boolean isRoleNotModified(Boolean hasCustomPermission) {
        Account accountRecord = [SELECT Id, Active_Sales_Agreement__c, RC_Account_Status__c FROM Account WHERE Id = :accId];

        Boolean isCustomerConfirmed = false;
        if (accountRecord.RC_Account_Status__c != null && accountRecord.RC_Account_Status__c == 'Paid' && !hasCustomPermission) {
            return true;
        } else {
            for (Opportunity opp : [SELECT Id, CustomerConfirmation__c FROM Opportunity WHERE AccountId = :accountRecord.Id]) {
                if (!isCustomerConfirmed && opp.CustomerConfirmation__c == 'Confirmed') {
                    isCustomerConfirmed = true;
                }
            }

            if ((isCustomerConfirmed || accountRecord.Active_Sales_Agreement__c != null) && !hasCustomPermission) {
                return true;
            }
        }

        return false;
    }

    private void validateContactRole() {
        if (ConvertLead.IS_LEAD_CONVERT_PROCESSING) {
            return;
        }

        Boolean hasCustomPermission = FeatureManagement.checkPermission(PERMESSIONSET_NAME);
		Boolean isPrimaryOrSignatoryCrEdited = false;
		Boolean isNewContactRole = pageParameters.get('crId') == null;
        Boolean isRoleNotModified = isRoleNotModified(hasCustomPermission);

        if (!isNewContactRole && !isRoleNotModified && !hasCustomPermission ) {
            isPrimaryOrSignatoryCrEdited = isPrimaryOrSignatoryContactRoleEdited(contactRole.Id);
        }

        /*Boolean isUserCanNotEditContactRole = isPrimaryOrSignatoryCrEdited && !isAllowedContRoleEdit();

        if(isUserCanNotEditContactRole) {
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,CONTACT_ROLE_EDIT_NOT_ALLOWED));
            return;
        }*/

        if (!isAllowedNewSignatory()) {
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, SIGNATORY_ROLE_LIMIT));
        }

        if (isDuplicate()) {
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, DUPLICATE_ROLE));
        }

        if (isPrimaryExist() && contactRole.IsPrimary == true) {
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, SINGLE_PRIMARY_ALLOWED));
        }

        if (isHasApprovals()) {
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, CONTACT_ROLE_EDIT_HAS_APPROVERS));
        }

        if (isInvalidAccountsPayble()) {
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, INVALID_ACCOUNT_PAYBLE_CONTACT_ROLE));
        }
        if (isFlaggedAccount()) {
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, FLAGGED_BY_DESCARTES_ACCOUNT));
        }
        if (isRoleNotModified) {
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, FLAGGED_ROLE_NOT_MODIFIED));
        }
        if (!isContactPhoneInRange()) {
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, ContactHelper.CONTACT_PHONE_NOT_IN_RANGE));
        }

    }

    public Boolean isContactPhoneInRange() {
        Boolean isInRange = true;

        if (contactRole.Role == AccountContactRoleHelper.CONTACT_ROLE_ACCOUNT_PAYABLE) {
            Contact contact = (Contact) new ContactSelector()
                .selectContactById(new List<Object>{
                    contactRole.ContactId
                })
                .executeQuery()
                .get(0);

            isInRange = ContactTriggerHelper.isPhoneInRange(contact.Phone);
        }

        return isInRange;
    }

    private Boolean isPrimaryOrSignatoryContactRoleEdited(Id contactRoleId) {
        Boolean res = false;

        AccountContactRole cr = [SELECT Id, IsPrimary, Role FROM AccountContactRole WHERE Id = :contactRoleId];

        if (cr.IsPrimary || 'Signatory'.equalsIgnoreCase(cr.Role)) {
            res = true;
        }

        return res;
    }
}