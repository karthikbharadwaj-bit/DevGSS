public inherited sharing class AgentCreditSelector extends SObjectSelector {

    public AgentCreditSelector() {
        super();
    }

    public AgentCreditSelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(enforceCRUD, enforceFLS);
    }

    public override Schema.SObjectType getSObjectType()  {
        return Agent_Credit__c.SObjectType;
    }

    public override List<Schema.SObjectField> getDefaultFieldList() {
        return new List<Schema.SObjectField> {
            Agent_Credit__c.Id,
            Agent_Credit__c.Name,
            Agent_Credit__c.Account__c,
            Agent_Credit__c.OwnerId
        };
    }

    public List<String> getSFToSFSyncFields() {
        return new List<String>{
            'Id',
            'X12M_Commission_Booking_Amount__c',
            'X12M_Sales_Booking_Amount__c',
            'X12M_Sales_Booking_Amount_Debooked__c',
            'Account__c',
            'Agent_Commission_claw_back_window__c',
            'Agent_Credit_Has_Overlay__c',
            'Name',
            'Agent_Credit_Main_Credit_ID__c',
            'Agent_Credit_Sub_Type__c',
            'Agent_Credit_Type__c',
            'Agent_Division__c',
            'Agent_Email__c',
            'Agent_First_Name__c',
            'Agent_Last_Name__c',
            'Agent_Manager_Email__c',
            'Agent_Manager_First_Name__c',
            'Agent_Manager_Last_Name__c',
            'Agent_Role__c',
            'Agent_SPID__c',
            'Agent_Team__c',
            'AgentCreditID18Digit__c',
            'Agreement_Lag__c',
            'Approval_ID__c',
            'ARR_Booking_Amount__c',
            'ARR_Booking_Amount_Override__c',
            'ARR_TCV__c',
            'Brand_Partner__c',
            'Comp_Bookings_for_Runrate__c',
            'Comp_Date_Month_End__c',
            'Comp_Date_Month_Start__c',
            'Comp_Month_Business_Days__c',
            'Comp_Month_Elapse_Days__c',
            'Compensation_Date__c',
            'Contact_Center_Agent_Name__c',
            'Contact_Center_Amount__c',
            'Contact_Center_Change_Type__c',
            'Contact_Center_Date__c',
            'Contact_Center_Owner_Email__c',
            'CreatedById',
            'CurrencyIsoCode',
            'Farming_Control_Group__c',
            'Manual_Update_Timestamp__c',
            'Name__c',
            'Office_Location__c',
            'One_Time_Booking_Amount__c',
            'One_Time_Booking_Amount_Override__c',
            'One_time_TCV__c',
            'Order__c',
            'OwnerId',
            'Owner_IsActive__c',
            'Past_Due_Date__c',
            'Annual_Payment_Plan__c',
            'Remaining_of_years__c',
            'Runrate_Multiplicand__c',
            'SFDC_Currency_Conversion_Rate__c',
            'Total_Holidays_for_the_Month__c',
            'Total_TCV__c',
            'Transfer_Disable_Date__c',
            'Type__c'
        };
    }

    public QueryFactory selectAgentCredits() {
        return newQueryFactory()
            .setFactoryName('selectAgentCredits')
            .selectFields(getSFToSFSyncFields());
    }

    public QueryFactory selectAgentCreditsForApproval(List<Object> bindings) {
        return newQueryFactory()
                .setFactoryName('selectAgentCreditsForApproval')
                .withSelectorFieldsIncluded()
                .withoutSelectorOrderByIncluded()
                .setCondition('Id IN :bind0')
                .setQueryBindings(bindings);
    }
}