public inherited sharing class ContactSelector extends SObjectSelector {

    public ContactSelector() {
        super();
    }

    public ContactSelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(enforceCRUD, enforceFLS);
    }

    public override List<Schema.SObjectField> getDefaultFieldList() {
        return new List<Schema.SObjectField>{
            Contact.Id,
            Contact.Name,
            Contact.FirstName,
            Contact.LastName,
            Contact.Phone,
            Contact.Email,
            Contact.Title,
            Contact.AccountId,
            Contact.LastModifiedDate,
            Contact.CreatedDate,
            Contact.Customer_Record__c,
            Contact.Contact_Status__c,
            Contact.NumberOfEmployees__c,
            Contact.isCustomer__c,
            Contact.People_Segment__c,
            Contact.RCService_ContactStatus__c
        };
    }

    public List<String> getAPIFieldList() {
        return new List<String>{
            'Id',
            'Name',
            'FirstName',
            'LastName',
            'Phone',
            'Email',
            'AccountId',
            'User_Id__c',
            'Title',
            'Phone_Ext__c', 'Job_Role__c', 'Account_Tier__c',
            'Account_Brand__c', 'Package_Name__c', 'Implementation_Status__c',
            'Account_Number_of_DLs__c', 'Owner.Name', 'Account.BillingAddress', 'Account.Name',
            'Account.CSM_Name__c', 'Account.CSM_Email__c', 'Account.CSM__r.SmallPhotoUrl',
            'Account.CSM__r.FullPhotoUrl', 'Account.CSM__r.Phone', 'Account.Account_POD__c', 'Account.RC_User_ID__c',
            'Account.Invoice_Terms__c', 'Account.Next_Renewal_Date__c', 'Account.Payment_Plan__c',
            'Account.Segment_Name__r.Name', 'Account.RC_Account_Status__c', 'Account.RC_Tier__c',
            'Account.Total_Account_DL_s__c', 'Account.RC_Brand__c', 'Account.VIP_Account_Indicator__c',
            'Account.Number_of_DL_s__c', 'Account.Service_Status__c',
            'Account.Extended_Enterprise_Support_Customer__c', 'Account.Package_Status__c',
            'Account.Sales_Agreement_End_Date__c', 'Account.VideoProvider__c', 'Account.CreatedDate',
            'Account.Total_Account_DL_s__c', 'Account.Current_Owner__r.Name', 'Account.Current_Owner__r.Email',
            'Account.Current_Owner__r.Phone',
            'Account.inContact_Cluster__c',
            'Account.Account_POD__c',
            'Account.RC_Brand__c',
            'Account.Enterprise_Support_Start_Date__c',
            'Account.Enterprise_Support_End_Date__c',
            'Account.Technical_Account_Manager__c',
            'Account.UC_ES_Service_Level__c',
            'ES_Designated_Contact__c',
            'RecordType.Name',
            'Account.Recordtype.Name'
        };
    }

    public List<String> getContactFieldsForOpportunityDFR() {
        return new List<String>{
            'Id',
            'PID__c',
            'Most_Recent_Campaign__c',
            'Most_Recent_Asset__c',
            'Name',
            'Email',
            'LeadSource',
            'Demographic_Score__c',
            'Behavior_Score__c',
            'BMID__c',
            'AID__c',
            'NumberOfEmployees__c',
            'Time_Frame__c',
            'Contact_Funnel_Type__c',
            'Lead_Entry_Source__c',
            'Downgrade_Reason__c',
            'Owner',
            'Owner.Name',
            'OwnerId'
        };
    }

    public List<String> getAttributionFieldList() {
        return new List<String>{
            'Most_Recent_Campaign__r',
            'Most_Recent_Campaign__r.Non_Attributable__c',
            'Primary_Campaign__c',
            'BMID__c',
            'AID__c',
            'PID__c'
        };
    }

    public List<String> getContactMailFieldList() {
        return new List<String> {
            'Name',
            'Email',
            'Phone',
            'AccountId'
        };
    }

    public List<String> getFieldsForEmail() {
        return new List<String>{
            'Id',
            'FirstName',
            'LastName',
            'Email'
        };
    }

    public List<String> getFieldsForSyncWS() {
         return new List<String>{
            'Id',
            'Name',
            'Email',
            'Phone',
            'AccountId'
        };
    }

    public List<String> getRelatedAccountFields() {
        return new List<String>{
            'Account.RecordTypeId',
            'Account.Billing_ID__c'
        };
    }

    public List<String> getContactStatusFieldList() {
        return new List<String>{
            'Account_Status__c',
            'Account.Owner.Email',
            'Account.Account_Owner_Manager_Email__c',
            'Account.Name',
            'Account.RC_Churn_Date__c',
            'Account.RC_Upgrade_Date__c',
            'Contact_Status__c',
            'Customer_Record__c',
            'Quoted_Products__c',
            'LastModifiedById',
            'CreatedById',
            'RCService_ContactStatus__c'
        };
    }

    public List<String> getFieldListForDFRUpdate() {
        return new List<String>{
            'Downgrade_Reason__c',
            'Sub_Downgrade_Reason__c',
            'Contact_Funnel_Type__c'
        };
    }

    public List<String> getFieldListForSaasquatchReferralCodes() {
        List<String> fieldsList = new List<String>();
        List<ReferralProgramFieldMapping__mdt> programs = ReferralProgramFieldMapping__mdt.getAll().values();
        for (ReferralProgramFieldMapping__mdt program: programs) {
            if(program.isMapedToContact__c){
                fieldsList.add(program.FieldAPIName__c);
            }
        }
        return fieldsList;
    }

    public Set<String> getDFRFields() {
        return new Set<String>{
            'BMID__c',
            'Behavior_Score__c',
            'AID__c',
            'Demographic_Score__c',
            'Time_Frame__c',
            'Department',
            'LeadSource',
            'Title',
            'Most_Recent_Campaign__c',
            'Most_Recent_Asset__c',
            'PID__c',
            'Lead_Entry_Source__c',
            'Form_URL__c',
            'Owner',
            'Name',
            'AssistantPhone',
            'Account_Brand__c'
        };
    }

    public List<String> getConversionContactFields() {
        return new List<String>{
            'Id',
            'Name',
            'Email',
            'Phone',
            'AccountId',
            'Account.Name'
        };
    }
    

    public override Schema.SObjectType getSObjectType() {
        return Contact.SObjectType;
    }

    public QueryFactory selectContacts() {
        return newQueryFactory()
            .setFactoryName('SelectContactsLimit10')
            .withSelectorFieldsIncluded()
            .setLimit(10);
    }

    public QueryFactory selectContactsByAccountId(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectContactsByAccountId')
            .selectFields(getDefaultFieldList())
            .setCondition('AccountId = :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectContactsForDFRById(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectContactsForDFRById')
            .selectFields(getDFRFields())
            .selectFields(getContactFieldsForOpportunityDFR())
            .selectField(Contact.Contact_Status__c)
            .setCondition('Id IN :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectContactById(List<Object> bindings) {
        List<String> fieldList = new List<String>{
            'Name',
            'FirstName',
            'LastName',
            'Phone',
            'Email',
            'Account.RC_Brand__c',
            'HasOptedOutOfEmail',
            'Do_Not_Call__c',
            'Domain_Type__c',
            'Ok_to_Email__c'
        };
        return newQueryFactory()
            .setFactoryName('selectContactById')
            .withSelectorFieldsIncluded()
            .selectFields(fieldList)
            .withoutSelectorOrderByIncluded()
            .setCondition('Id = :bind0')
            .setLimit(1)
            .setQueryBindings(bindings);
    }
    public QueryFactory selectContactsForApproval(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectAgentCreditsForApproval')
            .withSelectorFieldsIncluded()
            .setCondition('Id IN :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectContactWithAccountsPayableACR(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectContactWithAccountsPayableACR')
            .withSelectorFieldsIncluded()
            .subselect(
                new QueryFactory(new AccountContactRoleSelector(), AccountHelper.ACCOUNT_CONTACT_ROLES_RELATIONSHIP)
                    .setFactoryName('selectAccountPayableContactRolesForContact')
                    .selectFields(new List<String>{'Id', 'AccountId', 'ContactId', 'Role', 'IsPrimary' })
                    .withoutSelectorOrderByIncluded()
                    .setCondition('Role = \''
                        + AccountContactRoleHelper.CONTACT_ROLE_ACCOUNT_PAYABLE + '\''))
            .setCondition('Id IN :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectContactsByIds(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectContactsByIds')
            .withSelectorFieldsIncluded()
            .selectFields(getAttributionFieldList())
            .setCondition('Id IN :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectContactsForClose() {
        return newQueryFactory()
            .setFactoryName('selectContactsForClose')
            .withSelectorFieldsIncluded()
            .withoutSelectorOrderByIncluded()
            .selectFields(getDefaultFieldList());
    }

    public QueryFactory selectContactsWithAssetTouches(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectContactsWithAssetTouches')
            .withSelectorFieldsIncluded()
            .selectField('Most_Recent_Asset__c')
            .subselect(new AssetTouchSelector().selectAssetsForSubquery())
            .setCondition('Id IN :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectContactsForLeadConversion(List<Object> bindings, Integer queryLimit, Integer offset, String queryCondition) {
        return newQueryFactory()
            .setFactoryName('selectContactsByEmail')
            .selectFields(getDefaultFieldList())
            .selectFields(getAttributionFieldList())
            .selectField(Contact.Company__c)
            .selectField(Contact.Account_Status__c)
            .withSelectorFieldsIncluded()
            .withoutSelectorOrderByIncluded()
            .setCondition(queryCondition)
            .addOrdering('LevelOfRecordCompletion__c', QueryFactory.SortOrder.DESCENDING)
            .setLimit(queryLimit)
            .setOffset(offset)
            .setQueryBindings(bindings);
    }

    public QueryFactory selectContactsForSignUp(Set<Id> contactIdSet) {
        List<Object> bindings = new List<Object>();
        bindings.add(contactIdSet);
        return newQueryFactory()
            .setFactoryName('selectContactsForSignUp')
            .withSelectorFieldsIncluded()
            .setCondition('Id IN :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectContactsByEmail(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectContactsByEmail')
            .withSelectorFieldsIncluded()
            .selectFields(getFieldsForEmail())
            .setCondition('FirstName IN :bind0 AND LastName IN :bind1 AND Email IN :bind2')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectContactForSignUpSync(String email) {
        return newQueryFactory()
            .setFactoryName('selectContactForSignUpSync')
            .withSelectorFieldsIncluded()
            .selectFields(getRelatedAccountFields())
            .setCondition('Email = :bind0 AND Account.Billing_ID__c = null')
            .withoutSelectorOrderByIncluded()
            .addOrdering('CreatedDate', QueryFactory.SortOrder.DESCENDING)
            .setQueryBindings(new List<Object>{
                email
            });
    }

    public QueryFactory selectContactForAPI(List<Object> bindings, List<String> fields) {
        return newQueryFactory()
            .setFactoryName('selectContactForAPI')
            .withoutSelectorFieldsIncluded()
            .selectFields(fields)
            .setCondition('User_Id__c = :bind0 AND Email = :bind1')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectContactForAPI(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectContactForAPI')
            .withSelectorFieldsIncluded()
            .selectFields(getAPIFieldList())
            .setCondition('User_Id__c = :bind0 AND Email = :bind1')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectContactsForAccPayble(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectContactsForAccPayble')
            .selectFields(getDefaultFieldList())
            .setCondition('Id = :bind0 AND AccountId = :bind1')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectContactsByIdsForStatusUpdate(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectContactsByIdsForStatusUpdate')
            .withSelectorFieldsIncluded()
            .selectFields(getContactStatusFieldList())
            .selectFields(getDFRFields())
            .selectFields(getDefaultFieldList())
            .selectFields(getFieldListForDFRUpdate())
            .selectFields(getContactFieldsForOpportunityDFR())
            .setCondition('Id IN :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectContactByIdAndMostRecentCampaign(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectContactByIdAndMostRecentCampaign')
            .selectFields(new List<String>{
                'Id',
                'Most_Recent_Campaign__c',
                'Most_Recent_Campaign_Member_Status__c'
            })
            .setCondition('Id IN :bind0 AND Most_Recent_Campaign__c IN :bind1')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectAccountByContactId(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectAccountByContactId')
            .selectFields(new List<String>{
                'Id',
                'Contact_Status__c',
                'AccountId',
                'Account.OwnerId',
                'Account.Current_Owner__c',
                'BDR_Agent2__c',
                'SDR_Agents__c',
                'Forecasted_Contact_Center_Users__c',
                'Forecasted_Engage_Digital_Users__c',
                'Forecasted_Engage_Voice_Users__c',
                'Forecasted_Global_Office_Users__c',
                'Forecasted_Office_Users__c',
                'Forecasted_RingCentral_Video_Users__c'
            })
            .setCondition('Id = :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectContactsByAccountAndClosedWonStatus(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectContactsByAccountAndClosedWonStatus')
            .withSelectorFieldsIncluded()
            .selectFields(getContactStatusFieldList())
            .setCondition('AccountId = :bind0 AND Contact_Status__c = \'' + ContactTriggerHandler.CONTACT_STATUS_CLOSED_WON_OPP + '\'')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectContactByMail(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectContactByMail')
            .selectFields(getContactMailFieldList())
            .withSelectorOrderByIncluded()
            .setCondition('Email = :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectContactsByAccountIdAndEmailOrPhone(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectContactsByAccountIdAndEmailOrPhone')
            .selectFields(getDefaultFieldList())
            .setCondition('AccountId = :bind0 AND (Email = :bind1 OR Phone = :bind2)')
            .addOrdering(Contact.LastModifiedDate, QueryFactory.SortOrder.DESCENDING)
            .setQueryBindings(bindings);
    }

    public QueryFactory selectContactByIdForMergeToContactInLeadSearchExtension(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectContactById')
            .withSelectorFieldsIncluded()
            .withoutSelectorOrderByIncluded()
            .selectField(Contact.Contact_Status__c)
            .selectFields(new List<String> {
                'FirstName', 'LastName', 'Email',
                'Phone','NumberOfEmployees__c','BMID__c',
                'LeadSource', 'Lead_Entry_Source__c', 'RC_Visitor_ID__c',
                'Adobe_Target_Id__c','Adobe_Target_Id_History__c','AID__c',
                'PID__c', 'GCLID__c','ECID__c'
            })
            .setCondition('Id = :bind0')
            .setLimit(1)
            .setQueryBindings(bindings);
    }

    public QueryFactory selectContactsByAccountAndNotWorkingOppOrDowngradeStatus(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectContactsByAccountAndNotWorkingOppOrDowngradeStatus')
            .withSelectorFieldsIncluded()
            .selectFields(getContactStatusFieldList())
            .selectFields(getDFRFields())
            .selectFields(getFieldListForDFRUpdate())
            .setCondition('AccountId IN :bind0 AND Contact_Status__c NOT IN :bind1')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectContactsByAccountIds(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectContactsByAccountIds')
            .selectFields(getDFRFields())
            .selectFields(getContactFieldsForOpportunityDFR())
            .selectFields(getDefaultFieldList())
            .selectFields(new List<String> { 'Account.Name', 'Account.No_of_Employees__c' })
            .setCondition('AccountId IN :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectContactsMatchedBySearch(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectContactsMatchedBySearch')
            .withSelectorFieldsIncluded()
            .selectFields(new List<String> {
                'Name', 'Contact_Status__c', 'Email',
                'Phone','CreatedDate','LastModifiedDate',
                'AccountId', 'Account.Name', 'Account.RecordType.Name'
            })
            .setCondition('Email in :bind0 OR Phone in :bind1 OR MobilePhone in :bind1 OR Phone_Alternate__c in :bind1')
            .setLimit(50)
            .setQueryBindings(bindings);
    }

    public QueryFactory selectContactsWithAccountByEmail(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectContactsByEmailWithAccount')
            .withSelectorFieldsIncluded()
            .selectFields(new List<String> {
                'Name','AccountId', 'Account.RC_Account_Status__c'
            })
            .withoutSelectorOrderByIncluded()
            .addOrdering('CreatedDate', QueryFactory.SortOrder.DESCENDING)
            .setCondition('Email in :bind0 AND (Account.RC_Account_Status__c = \''
            + 'Paid' + '\' OR Account.RC_Account_Status__c = null'
            + ' OR Account.RC_Account_Status__c Like \''+ '%Trial%' + '\''
            + ' OR Account.RC_Account_Status__c = \'' + 'Free' + '\') AND AccountId != null')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectContactsByIdsForSaasquatchReferralCode(List<Object> bindings) {
    return newQueryFactory()
        .setFactoryName('selectContactsByIdsForSaasquatchReferralCode')
        .withSelectorFieldsIncluded()
        .selectFields(getFieldListForSaasquatchReferralCodes())
        .setCondition('Id IN :bind0')
        .setQueryBindings(bindings);
    }

    public QueryFactory selectContactForDFRConvertedLead(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectContactForDFRConvertedLead')
            .selectFields(new List<String>{
                'Id',
                'AccountId',
                'DFR_Status__c',
                'Contact_Funnel_Type__c',
                'OwnerId',
                'Customer_Record__c',
                'CreatedDate',
                'Form_URL__c'
            })
            .setCondition('Id = :bind0')
            .setLimit(1)
            .setQueryBindings(bindings);
    }

    public QueryFactory selectContactsForSyncWS(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectContactsForSyncWS')
            .selectFields(getFieldsForSyncWS())
            .setCondition(
                'Email = :bind0 ' +
                'AND Account.RC_User_ID__c = NULL ' +
                'AND Account.RecordTypeId = :bind1 ' +
                'AND Account.RC_Brand__c = :bind2'
            )
            .withoutSelectorOrderByIncluded()
            .addOrdering('CreatedDate', QueryFactory.SortOrder.DESCENDING)
            .setQueryBindings(bindings);
    }

    public QueryFactory selectContactsForSlapFiveAdvocate(Set<Id> contactIdSet) {
        List<Object> bindings = new List<Object>();
        bindings.add(contactIdSet);
        return newQueryFactory()
            .setFactoryName('selectContactsForSlapFiveAdvocate')
            .withSelectorFieldsIncluded()
            .selectFields(new List<String>{'SlapFive_Advocate_Member_Id__c'})
            .setCondition('Id IN :bind0 AND Date_Referral_Started__c = LAST_N_DAYS:90')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectConversionContactsByAccount(Id accountId, Id primaryContactId) {
        return newQueryFactory()
            .setFactoryName('selectConversionContactsByAccount')
            .selectFields(getConversionContactFields())
            .setCondition('AccountId = :bind0 AND Id != :bind1')
            .setQueryBindings(new List<Object>{ accountId, primaryContactId });
    }
}