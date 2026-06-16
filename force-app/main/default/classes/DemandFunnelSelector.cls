public inherited sharing class DemandFunnelSelector extends SObjectSelector {

    public DemandFunnelSelector() {
        super();
    }

    public DemandFunnelSelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(enforceCRUD, enforceFLS);
    }

    public override Schema.SObjectType getSObjectType()  {
        return Demand_Funnel__c.SObjectType;
    }

    public override List<Schema.SObjectField> getDefaultFieldList() {
        return new List<Schema.SObjectField> {
            Demand_Funnel__c.Id,
            Demand_Funnel__c.Contact__c,
            Demand_Funnel__c.Lead__c,
            Demand_Funnel__c.Opportunity__c,
            Demand_Funnel__c.DFR_Active_Status__c,
            Demand_Funnel__c.DET_DFR_Close_Date__c,
            Demand_Funnel__c.DET_Current_Sub_Status__c,
            Demand_Funnel__c.Pre_Opportunity_Status__c,
            Demand_Funnel__c.MQL_Owner_Team__c,
            Demand_Funnel__c.TAL_Owner_Name__c,
            Demand_Funnel__c.TQL_Owner_Name__c,
            Demand_Funnel__c.DET_Current_Funnel_Status__c
        };
    }

    public List<Schema.SObjectField> getMQLOwnerFieldList() {
        return new List<Schema.SObjectField> {
            Demand_Funnel__c.MQL_Owner_Id__c,
            Demand_Funnel__c.MQL_Owner_Name__c,
            Demand_Funnel__c.MQL_Owner_Team__c,
            Demand_Funnel__c.MQL_Owner_Division__c,
            Demand_Funnel__c.MQL_Owner_Role__c,
            Demand_Funnel__c.MQL_Queue_Name__c,
            Demand_Funnel__c.MQL_DateTime_Entered__c,
            Demand_Funnel__c.TAL_DateTime_Entered__c,
            Demand_Funnel__c.DET_Current_Funnel_Status__c,
            Demand_Funnel__c.Account__c,
            Demand_Funnel__c.SAL_Entered_From__c
        };
    }

    public List<Schema.SObjectField> getSegmentPicklist() {
        return new List<Schema.SObjectField> {
            Demand_Funnel__c.Prospect_Owner_Segment__c,
            Demand_Funnel__c.MQL_Owner_Segment__c,
            Demand_Funnel__c.TAL_Owner_Segment__c,
            Demand_Funnel__c.TQL_Owner_Segment__c,
            Demand_Funnel__c.SAL_Owner_Segment__c,
            Demand_Funnel__c.SQL_Owner_Segment__c,
            Demand_Funnel__c.EOL_Owner_Segment__c,
            Demand_Funnel__c.Opportunity_Owner_Segment__c
        };
    }

    public List<Schema.SObjectField> getTerritoryPicklist() {
        return new List<Schema.SObjectField> {
            Demand_Funnel__c.Prospect_Owner_Territory__c,
            Demand_Funnel__c.MQL_Owner_Territory__c,
            Demand_Funnel__c.TAL_Owner_Territory__c,
            Demand_Funnel__c.TQL_Owner_Territory__c,
            Demand_Funnel__c.SAL_Owner_Territory__c,
            Demand_Funnel__c.SQL_Owner_Territory__c,
            Demand_Funnel__c.EOL_Owner_Territory__c
        };
    }

    public List<Schema.SObjectField> getTALFields() {
            return new List<Schema.SObjectField> {
                Demand_Funnel__c.TAL_DateTime_Entered__c,
                Demand_Funnel__c.TAL_Owner_Name__c,
                Demand_Funnel__c.TAL_Owner_Segment__c,
                Demand_Funnel__c.TAL_Owner_Id__c,
                Demand_Funnel__c.TAL_Owner_Role__c,
                Demand_Funnel__c.TAL_Owner_Division__c,
                Demand_Funnel__c.TAL_Owner_Team__c,
                Demand_Funnel__c.TAL_Lead_Source__c,
                Demand_Funnel__c.TAL_Lead_Entry_Source__c,
                Demand_Funnel__c.TAL_Campaign__c,
                Demand_Funnel__c.TAL_Demographic_Score__c,
                Demand_Funnel__c.TAL_Behavior_Score__c,
                Demand_Funnel__c.TAL_Score__c,
                Demand_Funnel__c.TAL_BMID__c,
                Demand_Funnel__c.TAL_PID__c,
                Demand_Funnel__c.TAL_AID__c,
                Demand_Funnel__c.TAL_Purchase_Timeframe__c,
                Demand_Funnel__c.TAL_Lead_Score_Category__c
            };
    }

    public List<Schema.SObjectField> getMQLFields() {
            return new List<Schema.SObjectField> {
                Demand_Funnel__c.MQL_DateTime_Entered__c,
                Demand_Funnel__c.MQL_Owner_Name__c,
                Demand_Funnel__c.MQL_Owner_Segment__c,
                Demand_Funnel__c.MQL_Owner_Id__c,
                Demand_Funnel__c.MQL_Owner_Role__c,
                Demand_Funnel__c.MQL_Owner_Division__c,
                Demand_Funnel__c.MQL_Owner_Team__c,
                Demand_Funnel__c.MQL_Lead_Source__c,
                Demand_Funnel__c.MQL_Lead_Entry_Source__c,
                Demand_Funnel__c.MQL_Campaign__c,
                Demand_Funnel__c.MQL_Demographic_Score__c,
                Demand_Funnel__c.MQL_Behavior_Score__c,
                Demand_Funnel__c.MQL_Score__c,
                Demand_Funnel__c.MQL_BMID__c,
                Demand_Funnel__c.MQL_PID__c,
                Demand_Funnel__c.MQL_AID__c,
                Demand_Funnel__c.MQL_Purchase_Timeframe__c,
                Demand_Funnel__c.MQL_Lead_Score_Category__c,
                Demand_Funnel__c.MQL_Entered_From__c
            };
    }

    public List<Schema.SObjectField> getContactOwnerChangeFields() {
        return new List<Schema.SObjectField>{
            Demand_Funnel__c.SQL_Owner_Team__c,
            Demand_Funnel__c.SQL_Owner_Role__c,
            Demand_Funnel__c.SQL_Owner_Name__c,
            Demand_Funnel__c.SQL_Owner_Division__c,
            Demand_Funnel__c.SQL_DateTime_Entered__c,
            Demand_Funnel__c.SAL_Owner_Team__c,
            Demand_Funnel__c.SAL_Owner_Role__c,
            Demand_Funnel__c.SAL_Owner_Name__c,
            Demand_Funnel__c.SAL_Owner_Division__c,
            Demand_Funnel__c.SAL_DateTime_Entered__c,
            Demand_Funnel__c.SAL_Entered_From__c,
            Demand_Funnel__c.Prospect_Owner_Team__c,
            Demand_Funnel__c.Prospect_Owner_Role__c,
            Demand_Funnel__c.Prospect_Owner_Name__c,
            Demand_Funnel__c.Prospect_Owner_Division__c,
            Demand_Funnel__c.Prospect_DateTime_Entered__c,
            Demand_Funnel__c.Prospect_Exited_To__c,
            Demand_Funnel__c.MQL_Owner_Team__c,
            Demand_Funnel__c.MQL_Owner_Role__c,
            Demand_Funnel__c.MQL_Owner_Name__c,
            Demand_Funnel__c.MQL_Owner_Division__c,
            Demand_Funnel__c.MQL_DateTime_Entered__c,
            Demand_Funnel__c.MQL_Exited_To__c,
            Demand_Funnel__c.EOL_Owner_Team__c,
            Demand_Funnel__c.EOL_Owner_Role__c,
            Demand_Funnel__c.EOL_Owner_Name__c,
            Demand_Funnel__c.EOL_Owner_Division__c,
            Demand_Funnel__c.EOL_DateTime_Entered__c,
            Demand_Funnel__c.TAL_Entered_From__c,
            Demand_Funnel__c.Opportunity__c
        };
    }

    public List<String> getRelatedListFields() {
        return new List<String>{
            'Name',
            'DET_DFR_Created_Date__c',
            'DFR_Active_Status__c',
            'DET_Current_Funnel_Status__c',
            'DET_Current_Sub_Status__c',
            'Contact__c',
            'Account__c',
            'Opportunity__c'
        };
    }


    public List<String> getFieldsForFixSMEmployeesField() {
        return new List<String>{
            'SM_Employees__c',
            'Opportunity__r.Account.SM_Employees__c',
            'Lead__r.SM_Employees__c',
            'Lead__r.ZI_CDP_Account_Id__r.SM_Employees__c',
            'Account__r.SM_Employees__c',
            'Contact__r.Account.SM_Employees__c'
        };
    }

    public QueryFactory selectDFRForFixSMEmployeeField(List<Object> bindings) {
        return newQueryFactory()
                .setFactoryName('selectDFRForFixSMEmployeeField')
                .selectFields(getFieldsForFixSMEmployeesField())
                .setCondition('CreatedDate > :bind0 AND CreatedDate < :bind1')
                .setQueryBindings(bindings);
    }

    public List<String> getFieldsForUpdatingIntendedBrandField() {
        return new List<String>{
            'Intended_Brand__c',
            'Prospect_Lead_Source__c',
            'SM_Country__c',
            'Prospect_Campaign__c',
            'Prospect_Campaign__r.Intended_Product__c',
            'Prospect_Campaign__r.Intended_Country__c',
            'Lead__c',
            'Lead__r.Lead_Brand_Name__c',
            'Account__c',
            'Account__r.RC_Brand__c',
            'Opportunity__c',
            'Opportunity__r.Account.RC_Brand__c',
            'Opportunity__r.Account.SM_Country__c',
            'Account__r.SM_Country__c',
            'Lead__r.SM_Country__c',
            'Lead__r.Ultimate_SM_Country__c',
            'Lead__r.ZI_CDP_Account_Id__c',
            'Lead__r.ZI_CDP_Account_Id__r.Multinational_Ultimate__c',
            'Lead__r.ZI_CDP_Account_Id__r.ZI_Company_Country__c'
        };
    }


    public List<String> getLeadAccountOpportunityFields() {
        return new List<String>{
            'Lead__c',
            'Account__c',
            'Opportunity__c',
            'Lead__r.SM_Employees__c',
            'Account__r.SM_Employees__c',
            'Opportunity__r.Account.SM_Employees__c'
        };
    }

    public List<String> getLeadConvertFields() {
        return new List<String>{
            'Lead__c',
            'Id',
            'Pre_Opportunity_Status__c',
            'Pre_Opportunity_Close_Reason__c',
            'Opportunity__c',
            'Contact__c',
            'MQL_Exited_To__c',
            'MQL_Owner_Team__c',
            'MQL_Owner_Id__c',
            'MQL_Owner_Name__c',
            'TAL_Owner_Id__c',
            'SAL_Owner_Team__c'
        };
    }

    public List<String> getFieldsForActivity() {
        return new List<String>{
            'MQL_DateTime_Entered__c',
            'SAL_DateTime_Entered__c',
            'EOL_DateTime_Entered__c',
            'Contact__c',
            'Lead__c'
        };
    }

    public List<String> getMarketingAssetFieldList() {
        return new List<String>{
            'Prospect_Marketing_Asset__c',
            'TAL_Marketing_Asset__c',
            'TQL_Marketing_Asset__c',
            'MQL_Marketing_Asset__c',
            'SAL_Marketing_Asset__c',
            'SQL_Marketing_Asset__c',
            'EOL_Marketing_Asset__c',
            'Opportunity__r.OwnerId',
            'Account__c'
        };
    }

    public List<String> getSALHandoffFieldList() {
        return new List<String>{
            'Id',
            'SAL_Handoff_Owner__c',
            'SAL_Handoff_Owner_Role__c',
            'SAL_Handoff_Date__c',
            'SAL_DateTime_Exited__c',
            'SAL_DateTime_Entered__c',
            'Lead__c'
        };
    }

    public List<String> getMQLHandoffFieldList() {
        return new List<String>{
            'Id',
            'MQL_Handoff_Date__c',
            'MQL_DateTime_Exited__c',
            'MQL_DateTime_Entered__c',
            'MQL_Owner_Division__c',
            'MQL_Owner_Name__c',
            'MQL_Owner_Role__c',
            'MQL_Owner_Team__c',
            'Lead__c'
        };
    }

    public List<Schema.SObjectField> getEnteredExitedFieldList() {
        return new List<Schema.SObjectField> {
            Demand_Funnel__c.Prospect_Exited_To__c,
            Demand_Funnel__c.MQL_Exited_To__c,
            Demand_Funnel__c.SAL_Datetime_Entered__c,
            Demand_Funnel__c.TQL_DateTime_Entered__c
        };
    }

    public List<String> getFieldsForAccountUpdate() {
        return new List<String>{
            'Account__c',
            'Opportunity__r.AccountId',
            'Contact__r.AccountId',
            'Lead__r.ZI_CDP_Account_Id__c'
        };
    }

    public QueryFactory selectDFRForTQLUpdate(List<Object> bindings) {
        return newQueryFactory()
                .setFactoryName('selectDFRForTQLUpdate')
                .withSelectorFieldsIncluded()
                .withoutSelectorOrderByIncluded()
                .selectFields(getMQLOwnerFieldList())
                .setCondition('Lead__c IN :bind0 AND DFR_Active_Status__c = \'Active\'')
                .setQueryBindings(bindings);
    }

    public QueryFactory selectDFRByLeadIds(List<Object> bindings) {
        return newQueryFactory()
                .setFactoryName('selectDFRByLeadIds')
                .withSelectorFieldsIncluded()
                .withoutSelectorOrderByIncluded()
                .selectFields(getMQLOwnerFieldList())
                .setCondition('Lead__c IN :bind0')
                .setQueryBindings(bindings);
    }

    public QueryFactory selectDFRByLeadIdsAndPreOpportunityReasonNull(List<Object> bindings) {
        return newQueryFactory()
                .setFactoryName('selectDFRByLeadIdsAndPreOpportunityReasonNull')
                .withSelectorFieldsIncluded()
                .withoutSelectorOrderByIncluded()
                .selectFields(getMQLOwnerFieldList())
                .selectField('Pre_Opportunity_Close_Reason__c')
                .setCondition('Lead__c IN :bind0 AND Pre_Opportunity_Close_Reason__c != null')
                .setQueryBindings(bindings);
    }

    public QueryFactory selectDFRByOpportunittiesIdAndPreOpportunityReasonNull(List<Object> bindings) {
        return newQueryFactory()
                .setFactoryName('selectDFRByOpportunittiesIdAndPreOpportunityReasonNull')
                .withSelectorFieldsIncluded()
                .withoutSelectorOrderByIncluded()
                .selectFields(getMQLOwnerFieldList())
                .selectField('Pre_Opportunity_Close_Reason__c')
                .setCondition('Opportunity__c IN :bind0 AND Pre_Opportunity_Close_Reason__c != null')
                .setQueryBindings(bindings);
    }

    public QueryFactory selectDFRById(List<Object> bindings) {
        return newQueryFactory()
                .setFactoryName('selectDFRById')
                .withSelectorFieldsIncluded()
                .selectFields(getSegmentPicklist())
                .selectFields(getTerritoryPicklist())
                .withoutSelectorOrderByIncluded()
                .setCondition('Id = :bind0')
                .setQueryBindings(bindings);
    }

    public QueryFactory selectDFRByIds(List<Object> bindings) {
        return newQueryFactory()
                .setFactoryName('selectDFRByIds')
                .withSelectorFieldsIncluded()
                .selectFields(getSegmentPicklist())
                .selectFields(getTerritoryPicklist())
                .withoutSelectorOrderByIncluded()
                .setCondition('Id IN :bind0')
                .setQueryBindings(bindings);
    }


    public QueryFactory selectDFRForUpdatingIntendedBrandFieldValue(List<Object> bindings) {
        return newQueryFactory()
                .setFactoryName('selectDFRForUpdatingIntendedBrandFieldValue')
                .withSelectorFieldsIncluded()
                .withoutSelectorOrderByIncluded()
                .selectFields(getFieldsForUpdatingIntendedBrandField())
                .setCondition('Id IN :bind0'+
                    ' OR Prospect_Campaign__c IN :bind0' +
                    ' OR Lead__c IN :bind0' +
                    ' OR Account__c IN :bind0' +
                    ' OR Opportunity__r.AccountId IN :bind0' +
                    ' OR Opportunity__r.Account.Ultimate_Account__c IN :bind0' +
                    ' OR Account__r.Ultimate_Account__c IN :bind0' +
                    ' OR Lead__r.ZI_CDP_Account_Id__c IN :bind0'
                )
                .setQueryBindings(bindings);
    }

    public QueryFactory selectDFRByLeadID(List<Object> bindings) {
        return newQueryFactory()
                .setFactoryName('selectDFRByLeadId')
                .selectFields(getSegmentPicklist())
                .selectFields(getTerritoryPicklist())
                .selectFields(getMQLFields())
                .withSelectorFieldsIncluded()
                .withoutSelectorOrderByIncluded()
                .setCondition('Lead__c = :bind0')
                .setQueryBindings(bindings)
                .addOrdering('CreatedDate', QueryFactory.SortOrder.DESCENDING);
    }

    public QueryFactory selectDFRByOpportunityID(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectDFRByOpportunityId')
            .selectFields(getMQLFields())
            .selectFields(getMarketingAssetFieldList())
            .withSelectorFieldsIncluded()
            .withoutSelectorOrderByIncluded()
            .setCondition('Opportunity__c = :bind0')
            .setQueryBindings(bindings)
            .addOrdering('CreatedDate', QueryFactory.SortOrder.DESCENDING);
    }

    public QueryFactory selectDFRByLeadList(List<Object> bindings) {
        return newQueryFactory()
                .setFactoryName('selectDFRByLeadId')
                .withSelectorFieldsIncluded()
                .selectField(Demand_Funnel__c.Pre_Opportunity_Status__c)
                .withoutSelectorOrderByIncluded()
                .setCondition('Lead__c IN :bind0 AND Pre_Opportunity_Close_Reason__c = NULL AND Opportunity__c = NULL')
                .setQueryBindings(bindings);
    }

    public QueryFactory selectDFRToFixIntendedBrandFieldValue(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectDFRToFixIntendedBrandFieldValue')
            .withSelectorFieldsIncluded()
            .withoutSelectorOrderByIncluded()
            .selectFields(getFieldsForUpdatingIntendedBrandField())
            .setCondition('CreatedDate > :bind0 AND CreatedDate < :bind1')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectMQLOwnersByLeadID(List<Object> bindings) {
        return newQueryFactory()
                .setFactoryName('selectMQLOwnersByLeadID')
                .withSelectorFieldsIncluded()
                .selectFields(getMQLOwnerFieldList())
                .selectFields(getEnteredExitedFieldList())
                .withoutSelectorOrderByIncluded()
                .setCondition('Lead__c IN :bind0')
                .setQueryBindings(bindings)
                .addOrdering('CreatedDate', QueryFactory.SortOrder.DESCENDING);
    }

    public QueryFactory selectDFRForMarketingAssetProcessing(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectDFRForMarketingAssetProcessing')
            .withSelectorFieldsIncluded()
            .selectFields(getMQLOwnerFieldList())
            .selectFields(getMarketingAssetFieldList())
            .withoutSelectorOrderByIncluded()
            .setCondition('(Lead__c IN :bind0 OR Contact__c IN :bind1 OR Opportunity__c IN :bind2 OR Account__c IN :bind3) AND Pre_Opportunity_Close_Reason__c = null')
            .setQueryBindings(bindings)
            .addOrdering('LastModifiedDate', QueryFactory.SortOrder.DESCENDING);
    }

    public QueryFactory selectActiveDFRByContactId(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectActiveDFRByContactId')
            .withSelectorFieldsIncluded()
            .withoutSelectorOrderByIncluded()
            .selectFields(getMQLOwnerFieldList())
            .selectFields(getContactOwnerChangeFields())
            .selectField('EOL_DateTime_Entered__c')
            .selectField('Opportunity__r.StageName')
            .selectField(Demand_Funnel__c.TQL_Exited_To__c)
            .setCondition('Contact__c IN :bind0 AND DFR_Active_Status__c = \'Active\' AND Opportunity__c = NULL')
            .addOrdering('LastModifiedDate', QueryFactory.SortOrder.DESCENDING)
            .setQueryBindings(bindings);
    }

    public QueryFactory selectDFRByContact(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectDFRByContact')
            .withSelectorFieldsIncluded()
            .withoutSelectorOrderByIncluded()
            .setCondition('Contact__c IN :bind0 AND DFR_Active_Status__c = \'Active\'')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectDFRByContactTest(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectDFRByContact')
            .withSelectorFieldsIncluded()
            .withoutSelectorOrderByIncluded()
            .setCondition('Contact__c IN :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectDFRByLeadAccountOrOpportunity(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectDFRByLeadAccountOrOpportunity')
            .withSelectorFieldsIncluded()
            .withoutSelectorOrderByIncluded()
            .selectFields(getLeadAccountOpportunityFields())
            .selectField(Demand_Funnel__c.SM_Employees__c)
            .setCondition('' +
                'Lead__c IN :bind0 ' +
                'OR Lead__r.ZI_CDP_Account_Id__c IN :bind0 ' +
                'OR Account__c IN :bind0 ' +
                'OR Account__r.Ultimate_Account__c IN :bind0 ' +
                'OR Opportunity__c IN :bind0 ' +
                'OR Opportunity__r.AccountId IN :bind0 ' +
                'OR Opportunity__r.Account.Ultimate_Account__c IN :bind0'
            )
            .setQueryBindings(bindings);
    }

    public QueryFactory selectDFRByOpportunitiesId(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectDFRByOpportunitiesId')
            .withSelectorFieldsIncluded()
            .withoutSelectorOrderByIncluded()
            .selectFields(getLeadAccountOpportunityFields())
            .setCondition('Opportunity__c IN :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectActiveDFRForConvertLead(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectActiveDFRForConvertLead')
            .withSelectorFieldsIncluded()
            .withoutSelectorOrderByIncluded()
            .selectFields(getLeadConvertFields())
            .setCondition('Lead__c = :bind0 AND DFR_Active_Status__c = \'Active\' AND Opportunity__c = null')
            .addOrdering('CreatedDate', QueryFactory.SortOrder.DESCENDING)
            .setLimit(1)
            .setQueryBindings(bindings);

    }

    public QueryFactory selectActiveDFRByContactIdForOwnerChange(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectActiveDFRByContactIdForOwnerChange')
            .withSelectorFieldsIncluded()
            .withoutSelectorOrderByIncluded()
            .selectFields(getContactOwnerChangeFields())
            .setCondition('Contact__c IN :bind0 AND DFR_Active_Status__c = \'Active\'')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectDFRForRelatedList(List<Object> bindings) {
        return newQueryFactory()
                .setFactoryName('selectDFRForRelatedList')
                .withSelectorFieldsIncluded()
                .withoutSelectorOrderByIncluded()
                .selectFields(getRelatedListFields())
                .setCondition('Lead__c = :bind0 OR Contact__c = :bind0 OR Opportunity__c = :bind0')
                .addOrdering('CreatedDate', QueryFactory.SortOrder.DESCENDING)
                .setQueryBindings(bindings);
    }

    public QueryFactory selectDFRForFixAccountField(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectDFRForFixAccountField')
            .selectFields(getFieldsForAccountUpdate())
            .setCondition('CreatedDate > :bind0 AND CreatedDate < :bind1')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectDFRForAccountUpdate(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectDFRForAccountUpdate')
            .withSelectorFieldsIncluded()
            .withoutSelectorOrderByIncluded()
            .selectFields(getFieldsForAccountUpdate())
            .setCondition('' +
                'Opportunity__c IN :bind0 ' +
                'OR Contact__c IN :bind0 ' +
                'OR Lead__c IN :bind0 ' +
                'OR Opportunity__r.AccountId IN :bind0 ' +
                'OR Contact__r.AccountId IN :bind0 ' +
                'OR Lead__r.ZI_CDP_Account_Id__c IN :bind0'
            )
            .setQueryBindings(bindings);
    }

    public QueryFactory selectDFRByLeadOrContact(List<Object> bindings) {
        return newQueryFactory()
                .setFactoryName('selectDFRByLeadOrContact')
                .selectFields(getFieldsForActivity())
                .withSelectorFieldsIncluded()
                .withoutSelectorOrderByIncluded()
                .setCondition('(Lead__c IN :bind0 OR Contact__c IN :bind0) AND First_Activity_DateTime_after_MQL__c = NULL')
                .setQueryBindings(bindings)
                .addOrdering('CreatedDate', QueryFactory.SortOrder.DESCENDING);
    }

    public QueryFactory selectActiveDFRByOpportunitiesId(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectDFRByOpportunitiesId')
            .withSelectorFieldsIncluded()
            .withoutSelectorOrderByIncluded()
            .selectFields(getContactOwnerChangeFields())
            .setCondition('Opportunity__c IN :bind0 AND DFR_Active_Status__c = \'Active\'')
            .setQueryBindings(bindings);
    }

	public QueryFactory selectDFRForUpdateFields(Object[] bindings,
                                                Boolean isDFRIncluded,
                                                Boolean isLeadIncluded,
                                                Boolean isContactIncluded,
                                                Boolean isAccountIncluded) {
        String defaultCondition = 'LastModifiedDate >= :bind0';
        String condition = '';
        condition += (isDFRIncluded ? ' LastModifiedDate >= :bind0 OR' : '');
        condition += (isLeadIncluded ? ' Lead__r.LastModifiedDate >= :bind0  OR' : '');
        condition += (isContactIncluded ? ' Contact__r.LastModifiedDate >= :bind0  OR' : '');
        condition += (isAccountIncluded ? ' (Account__r.RC_Account_Status__c=\'PAID\' AND Account__r.LastModifiedDate >= :bind0)  OR' : '');
		condition = condition.removeEnd('OR');
        condition = String.isEmpty(condition) ? defaultCondition : condition;
        return newQueryFactory()
                .setFactoryName('selectDFRForUpdateFields')
                .selectFields(getFieldsForAccountUpdate())
                .selectFields(getFieldsForUpdatingIntendedBrandField())
                .selectFields(getFieldsForFixSMEmployeesField())
                .setCondition(condition)
            	.withoutSelectorOrderByIncluded()
                .setQueryBindings(bindings);
    }

    public QueryFactory selectDFRForUpdateFieldsBetweenDates(Object[] bindings,
                                                Boolean isDFRIncluded,
                                                Boolean isLeadIncluded,
                                                Boolean isContactIncluded,
                                                Boolean isAccountIncluded) {
        String defaultCondition = '(LastModifiedDate >= :bind0 AND ' + 'LastModifiedDate <= :bind1)';
        String condition = '';
        condition += (isDFRIncluded ? ' (LastModifiedDate >= :bind0 AND ' + 'LastModifiedDate <= :bind1) OR' : '');
        condition += (isLeadIncluded ? ' (Lead__r.LastModifiedDate >= :bind0 AND Lead__r.LastModifiedDate <= :bind1)  OR' : '');
        condition += (isContactIncluded ? ' (Contact__r.LastModifiedDate >= :bind0 AND Contact__r.LastModifiedDate <= :bind1)  OR' : '');
        condition += (isAccountIncluded ? ' (Account__r.RC_Account_Status__c=\'PAID\' AND Account__r.LastModifiedDate >= :bind0 AND Account__r.LastModifiedDate <= :bind1)  OR' : '');
        condition = condition.removeEnd('OR');
        condition = String.isEmpty(condition) ? defaultCondition : condition;
        return newQueryFactory()
                .setFactoryName('selectDFRForUpdateFieldsBetweenDates')
                .selectFields(getFieldsForAccountUpdate())
                .selectFields(getFieldsForUpdatingIntendedBrandField())
                .selectFields(getFieldsForFixSMEmployeesField())
                .setCondition(condition)
            	.withoutSelectorOrderByIncluded()
                .setQueryBindings(bindings);
    }

    public QueryFactory selectDFRForAddOpportunity(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectDFRForAddOpportunity')
            .withSelectorFieldsIncluded()
            .withoutSelectorOrderByIncluded()
            .selectField('MQL_Owner_Id__c')
            .selectField('TAL_Owner_Id__c')
            .selectField('SAL_Owner_Team__c')
            .setCondition('Contact__c = :bind0 AND Opportunity__c = null AND Pre_Opportunity_Close_Reason__c = null AND DFR_Active_Status__c = \'Active\'')
            .addOrdering('CreatedDate', QueryFactory.SortOrder.DESCENDING)
            .setQueryBindings(bindings);
    }

    public QueryFactory selectDFRsForAddOpportunity(Set<Id> bindings) {
        return newQueryFactory()
            .setFactoryName('selectDFRsForAddOpportunity')
            .withSelectorFieldsIncluded()
            .withoutSelectorOrderByIncluded()
            .selectField('MQL_Owner_Id__c')
            .selectField('TAL_Owner_Id__c')
            .selectField('SAL_Owner_Team__c')
            .selectField('Contact__r.OwnerId')
            .setCondition('Contact__c IN :bind0 AND Opportunity__c = null AND Pre_Opportunity_Close_Reason__c = null AND DFR_Active_Status__c = \'Active\'')
            .addOrdering('CreatedDate', QueryFactory.SortOrder.DESCENDING)
            .setQueryBindings(bindings);
    }

    public QueryFactory selectDFRsForSALHandOff(Set<Id> bindings) {
        return newQueryFactory()
            .setFactoryName('selectDFRsForSALHandOff')
            .withSelectorFieldsIncluded()
            .selectFields(getSALHandoffFieldList())
            .setCondition('Lead__c IN :bind0 AND SAL_DateTime_Entered__c != NULL AND SAL_DateTime_Exited__c = NULL')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectActiveDFRsForLeadOwnerChange(Set<Id> bindings) {
        return newQueryFactory()
            .setFactoryName('selectActiveDFRsForLeadOwnerChange')
            .withSelectorFieldsIncluded()
            .selectFields(getContactOwnerChangeFields())
            .setCondition('Lead__c IN :bind0 AND DFR_Active_Status__c = \'Active\'')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectDFRsForMQLHandOff(Set<Id> bindings) {
        return newQueryFactory()
            .setFactoryName('selectDFRsForMQLHandOff')
            .withSelectorFieldsIncluded()
            .selectFields(getMQLHandoffFieldList())
            .setCondition('Lead__c IN :bind0 AND MQL_DateTime_Entered__c != NULL AND MQL_DateTime_Exited__c = NULL')
            .setQueryBindings(bindings);
    }   

    public QueryFactory selectDFRsForDowngrade(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectDFRsForMQLHandOff')
            .withSelectorFieldsIncluded()
            .selectField('Opportunity__c')
            .selectField('Lead__c')
            .selectField('DFR_Active_Status__c')
            .selectField('CreatedDate')
            .selectField('Contact__c')
            .setCondition('CreatedDate <= :bind0 AND Lead__c = NULL AND ' + 
            'Opportunity__c = NULL AND Contact__c != NULL AND DFR_Active_Status__c = \'Active\'')
            .setQueryBindings(bindings);
    }
}