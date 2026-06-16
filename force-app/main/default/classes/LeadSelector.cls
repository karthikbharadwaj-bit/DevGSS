public inherited sharing class LeadSelector extends SObjectSelector {

    public LeadSelector() {
        super();
    }

    public LeadSelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(enforceCRUD, enforceFLS);
    }

    public override Schema.SObjectType getSObjectType()  {
        return Lead.SObjectType;
    }

    public override List<Schema.SObjectField> getDefaultFieldList() {
        return new List<Schema.SObjectField> {
            Lead.Id,
            Lead.RecordTypeId,
            Lead.RecordType.Name,
            Lead.IsConverted,
            Lead.OwnerId,
            Lead.Description
        };
    }

    public List<Schema.SObjectField> getOtherFieldList() {
        return new List<Schema.SObjectField> {
            Lead.Account__c,
            Lead.Agent_Email_Address__c,
            Lead.Email,
            Lead.Notes__c,
            Lead.Lead_Entry_Source__c,
            Lead.Lead_Brand_Name__c,
            Lead.FirstName,
            Lead.LastName,
            Lead.State__c,
            Lead.LeadSource,
            Lead.City,
            Lead.Country,
            Lead.PostalCode,
            Lead.State,
            Lead.Street,
            Lead.City__c,
            Lead.Street_2__c,
            Lead.Phone,
            Lead.Phone_Ext__c,
            Lead.Title,
            Lead.Website,
            Lead.Country__c,
            Lead.Account_Number__c,
            Lead.Estimated_Close_Date__c,
            Lead.LeadPartnerID__c,
            Lead.Timezone__c,
            Lead.Referrer_FName__c,
            Lead.Referrer_LName__c,
            Lead.Zip_Code__c,
            Lead.Referrer_Email__c,
            Lead.Inside_Sales_Rep__c,
            Lead.NumberOfEmployees,
            Lead.Industry,
            Lead.Effective_No_of_Employees_Range__c,
            Lead.Number_of_Locations__c,
            Lead.Partner_Lead_Owner__c,
            Lead.Partner_Account__c,
            Lead.Partner_Contact__c,
            Lead.Partner_Program__c,
            Lead.Routing_Reason__c,
            Lead.RC_Edition__c,
            Lead.Lead_Tier_Name__c,
            Lead.RC_Term__c,
            Lead.Is_Billing__c,
            Lead.Target_Account__c,
            Lead.Description,
            Lead.Most_Recent_Campaign__c,
            Lead.Employees_Override__c,
            Lead.AH_Name__r.Effective_No_of_Employees_Range__c,
            Lead.LS_Company_Size_Range__c,
            Lead.NumberOfEmployees__c,
            Lead.Ultimate_Parent_Account_ID__c,
            Lead.Ultimate_Parent_Account_Name__c,
            Lead.Partner_Lead_Source__c,
            Lead.Partner_Account_Name__c,
            Lead.VAR_Territory__c,
            Lead.Status,
            Lead.Downgrade_Reason__c,
            Lead.Sub_Downgrade_Reason__c,
            Lead.Downgrade_Reason_Other__c,
            Lead.Sub_Downgrade_Reason_Other__c,
            Lead.Downgrade_Notes__c,
            Lead.VATNumber__c,
            Lead.Type_of_Customer_or_Prospect__c,
            Lead.Mitel_Data_Sharing__c,
            Lead.ZI_CDP_Account_Id__c,
            Lead.Installation_Service_Provider__c  //Added for LTR-673 PS Deal Reg
        };
    }

    public List<Schema.SObjectField> getFieldsForLeadConversionMapping() {
        return new List<Schema.SObjectField> {
            Lead.Rating,
            Lead.AnnualRevenue,
            Lead.CurrencyIsoCode,
            Lead.DoNotCall,
            Lead.Fax,
            Lead.HasOptedOutOfEmail,
            Lead.HasOptedOutOfFax,
            Lead.MobilePhone,
            lead.Salutation,
            Lead.Actively_Being_Sequenced__c,
            Lead.Adobe_Target_Id__c,
            Lead.Adobe_Target_Id_History__c,
            Lead.AID__c,
            Lead.BMID__c,
            Lead.BMID_Old__c,
            Lead.CASS_Address_Line_1__c,
            Lead.CASS_Address_Line_2__c,
            Lead.Company_DUNS__c,
            Lead.ConversionPage__c,
            Lead.Current_Sequence_ID__c,
            Lead.Current_Sequence_Name__c,
            Lead.Current_Sequence_Status__c,
            Lead.Current_Sequence_Step_Number__c,
            Lead.Current_Sequence_Step_Type__c,
            Lead.Current_Sequence_Task_Due_Date__c,
            Lead.Current_Sequence_User_SFDC_ID__c,
            Lead.Do_Not_Call__c,
            Lead.Do_Not_Direct_Mail__c,
            Lead.Do_Not_SMS__c,
            Lead.Email_Invalid__c,
            Lead.Entry_URL__c,
            Lead.GCLID__c,
            Lead.Integration_Apps__c,
            Lead.LID__LinkedIn_Company_Id__c,
            Lead.LID__LinkedIn_Member_Token__c,
            Lead.LS_Best_Fit_Persona__c,
            Lead.LS_Enrichment_Date__c,
            Lead.LS_Enrichment_Status__c,
            Lead.LS_Predictive_Score__c,
            Lead.LS_Sync_Trigger__c,
            Lead.Marketability__c,
            Lead.Meeting_Type_CP__c,
            Lead.Number_of_Active_Sequences__c,
            Lead.Outreach_Stages__c,
            Lead.PID__c,
            Lead.RCKW__c,
            Lead.RCMT__c,
            Lead.KCID__c,
            Lead.SIA_Information__c,
            Lead.SID__c,
            Lead.SmartSearchURL__c,
            Lead.The_Set__c,
            Lead.Transaction_Id__c,
            Lead.Longitude,
            Lead.Latitude,
            Lead.Ok_to_Email__c,
            Lead.Most_Recent_MQL_Date__c,
            Lead.Forecasted_Contact_Center_Users__c,
            Lead.Forecasted_Engage_Digital_Users__c,
            Lead.Forecasted_Engage_Voice_Users__c,
            Lead.Forecasted_Global_Office_Users__c,
            Lead.Number_of_Users__c,
            Lead.Forecasted_RingCentral_Video_Users__c,
            Lead.Forecasted_Events_Users__c,
            Lead.ZI_CDP_Account_Id__c,
            Lead.saasquatch_program_selector__c,
            Lead.Installation_Service_Provider__c //Added for LTR-673 PS Deal Reg
        };
    }

    public List<String> getAttributionFieldList() {
        return new List<String> {
            'Most_Recent_Campaign__r',
            'Most_Recent_Campaign__r.Non_Attributable__c',
            'Most_Recent_Campaign__r.Type',
            'Most_Recent_Campaign__r.Sub_Channel__c',
            'Shared_Lead_Counter__c',
            'Primary_Campaign__c',
            'BMID__c',
            'AH_Name__r',
            'AH_Name__r.Effective_No_of_Employees_Range__c'
        };
    }

    public List<String> getCampaignFields() {
        return new List<String> {
            'BMID__c',
            'Five9_DNIS__c',
            'Adobe_Target_Id__c',
            'Adobe_Target_Id_History__c',
            'BMID_Old__c',
            'Transaction_Id__c',
            'RCKW__c',
            'RCMT__c'
        };
    }

    public List<Schema.SObjectField> getSortDataLeadFields() {
        return new List<Schema.SObjectField> {
            Lead.Id,
            Lead.OwnerId,
            Lead.Name,
            Lead.Lead_Brand_Name__c
        };
    }

    public List<String> getSaasquatchEmailingFields() {
        return new List<String> {
            'FirstName',
            'LastName',
            'Saasquatch_Advocate_Name__r.saasquatch__First_Name__c',
            'Saasquatch_Advocate_Name__r.saasquatch__Last_Name__c',
            'Saasquatch_Advocate_Email__c',
            'saasquatch_program_selector__c',
            'saasquatch__Referral_Code__c',
            'Saasquatch_Advocate_ID__c'
        };
    }

    public QueryFactory selectLeadForConvert(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('SelectLeadForConvert')
            .withSelectorFieldsIncluded()
            .withoutSelectorOrderByIncluded()
            .withSelectFieldsSorted()
            .selectFields(getOtherFieldList())
            .selectFields(getFieldsForLeadConversionMapping())
            .setCondition('Id = :bind0')
            .setLimit(1)
            .setQueryBindings(bindings);
    }

    public QueryFactory selectLeadById(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectLeadById')
            .withSelectorFieldsIncluded()
            .selectFields(getOtherFieldList())
            .selectFields(getAttributionFieldList())
            .setCondition('Id = :bind0')
            .setLimit(1)
            .setQueryBindings(bindings);
    }

    /*public QueryFactory selectLastCreatedLeadforLeadSearchExtensionTests() {
        return newQueryFactory()
            .setFactoryName('selectLastCreatedLeadforTests')
            .withSelectorFieldsIncluded()
            .selectField(Lead.Phone)
            .withSelectFieldsSorted()
            .setCondition('Phone != null')
            .setLimit(1);
    }*/

    public QueryFactory selectLeads() {
        return newQueryFactory()
            .setFactoryName('SelectLeads')
            .withSelectorFieldsIncluded()
            .withSelectFieldsSorted();
    }

    public QueryFactory selectLeadsByIds(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectLeadsByIds')
            .withSelectorFieldsIncluded()
            .selectFields(getDefaultFieldList())
            .selectFields(getOtherFieldList())
            .selectFields(getAttributionFieldList())
            .setCondition('Id IN :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectLeadsForDFR(List<Object> bindings){
        return newQueryFactory()
            .setFactoryName('selectLeadsForDFR')
            .setCondition('Id = :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectLeadByLastName(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectLeadByLastName')
            .selectFields(getDefaultFieldList())
            .withoutSelectorOrderByIncluded()
            .setCondition('LastName = :bind0')
            .setLimit(1)
            .setQueryBindings(bindings);
    }

	public QueryFactory selectLeadsWithAssetTouches(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectLeadsWithAssetTouches')
            .withSelectorFieldsIncluded()
            .selectField('Most_Recent_Asset__c')
            .subselect(new AssetTouchSelector().selectAssetsForSubquery())
            .setCondition('Id IN :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectLeadWithCampaignFields(List<Object> bindings) {
        return newQueryFactory()
        .setFactoryName('selectLeadWithCampaignFields')
        .withSelectorFieldsIncluded()
        .selectFields(getCampaignFields())
        .selectField('ZI_CDP_Account_Id__c')
        .selectFields(new List<String> {
            'FirstName', 'LastName', 'Email',
            'Phone','Employees_Override__c','BMID__c',
            'LeadSource', 'Lead_Entry_Source__c', 'RC_Visitor_ID__c',
            'Adobe_Target_Id__c','Adobe_Target_Id_History__c','AID__c',
            'PID__c','KCID__c','GCLID__c','ECID__c','Primary_Campaign__c'
        })
        .setCondition('Id = :bind0')
        .setQueryBindings(bindings);
    }

    public QueryFactory selectLeadByIdAndMostRecentCampaign(List<Object> bindings) {
        return newQueryFactory()
        .setFactoryName('selectLeadByIdAndMostRecentCampaign')
        .selectFields(new List<String> {
            'Id',
            'Most_Recent_Campaign__c',
            'Most_Recent_Campaign_Member_Status__c'
        })
        .setCondition('Id IN :bind0 AND Most_Recent_Campaign__c IN :bind1')
        .setQueryBindings(bindings);
    }

    public QueryFactory selectShortDataLead(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectShortInfoLead')
            .selectFields(getSortDataLeadFields())
            .setCondition('Id = :bind0')
            .setLimit(1)
            .setQueryBindings(bindings);
    }

    public QueryFactory selectLeadsByIdsForSaasquatchEmailing(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectLeadsByIdsForSaasquatchEmailing')
            .withSelectorFieldsIncluded()
            .selectFields(getDefaultFieldList())
            .selectFields(getSaasquatchEmailingFields())
            .setCondition('Id IN :bind0')
            .setQueryBindings(bindings);
    }
}