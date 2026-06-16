public inherited sharing class ProServProjectSelector extends SObjectSelector {

    public ProServProjectSelector() {
        super();
    }

    public ProServProjectSelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(enforceCRUD, enforceFLS);
    }

    public override SObjectType getSObjectType() {
        return ProServ_Project__c.SObjectType;
    }

    public override List<SObjectField> getDefaultFieldList() {
        return new List<Schema.SObjectField> {
            ProServ_Project__c.Id, ProServ_Project__c.PS_Health_Status_Color_Message__c,
            ProServ_Project__c.PS_Health_Status_Project_Color__c, ProServ_Project__c.Overall_Project_Status_Note__c,
            ProServ_Project__c.PS_Quote_Number__c, ProServ_Project__c.ProServProjectManager__c
        };
    }

    public QueryFactory selectProServProjects() {
        return newQueryFactory()
            .setFactoryName('selectProServProjects')
            .withSelectorFieldsIncluded();
    }

    public List<Schema.SObjectField> getProServProjectUserFieldList() {
        return new List<Schema.SObjectField> {
            ProServ_Project__c.ProServProjectManager__c,
            ProServ_Project__c.Delivery_engineer__c,
            ProServ_Project__c.ProServ_IM__c
        };
    }

    public QueryFactory selectProServProjectsUserFields() {
        return newQueryFactory()
            .setFactoryName('selectProServProjectsUserFields')
            .withSelectorFieldsIncluded()
            .selectFields(getProServProjectUserFieldList());
    }
    
    public List<Schema.SObjectField> getProServProjectAllFieldList() {
        return new List<Schema.SObjectField> {
            ProServ_Project__c.Id,
            ProServ_Project__c.PS_Health_Status_Color_Message__c,
            ProServ_Project__c.PS_Health_Status_Project_Color__c,
            ProServ_Project__c.Overall_Project_Status_Note__c,
            ProServ_Project__c.PS_Quote_Number__c,
            ProServ_Project__c.ProServProjectManager__c,
            ProServ_Project__c.ProjectCloseDate__c,
            ProServ_Project__c.Total_Actual_Hours__c,
            ProServ_Project__c.ProjectStatusSummary__c,
            ProServ_Project__c.PSA__c,
            ProServ_Project__c.Acceptance_Closure_Date__c,
            ProServ_Project__c.Build_Date__c,
            ProServ_Project__c.Control_Monitor_Date__c,
            ProServ_Project__c.Current_Estimated_Date_of_Completion__c,
            ProServ_Project__c.Executed_Signoff__c,
            ProServ_Project__c.Finance_Approved_Date__c,
            ProServ_Project__c.Handoff_to_Support_Date__c,
            ProServ_Project__c.Initiation_Completion_Date__c,
            ProServ_Project__c.Invoiced_Date__c,
            ProServ_Project__c.Kickoff_Call_Date__c,
            ProServ_Project__c.P_D_Completion_Date__c,
            ProServ_Project__c.Port_Date__c,
            ProServ_Project__c.Delivery_engineer__c,
            ProServ_Project__c.ProServ_IM__c,
            ProServ_Project__c.Project_Percent_Complete__c,
            ProServ_Project__c.Submitted_to_Finance_Date__c,
            ProServ_Project__c.Training_Date__c,
            ProServ_Project__c.Date_PM_Assigned__c,
            ProServ_Project__c.Project_Initial_EDC__c,
            ProServ_Project__c.HasFinanceApproval__c,
            ProServ_Project__c.ProjectRevenueRecognitionDate__c,
            ProServ_Project__c.ProjectBillingStatus__c,
            ProServ_Project__c.Deploy_Date__c,
            ProServ_Project__c.Order__c
        };
    }

    public QueryFactory selectProServProjectsAllFields() {
        return newQueryFactory()
            .setFactoryName('selectProServProjectsAllFields')
            .withSelectorFieldsIncluded()
            .selectFields(getProServProjectAllFieldList());
    }

    public QueryFactory selectProServProjectsByOrderIds(Set<Id> orderIds) {
        return newQueryFactory()
            .setFactoryName('selectProServProjectsByOrderIds')
            .withSelectorFieldsIncluded()
            .selectFields(new List<Schema.SObjectField>{ProServ_Project__c.Id})
            .setCondition('Order__c IN :bind0')
            .setQueryBindings(new List<Object> {orderIds});
    }
}