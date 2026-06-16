public inherited sharing class OrderCustomSelector extends SObjectSelector {
    public OrderCustomSelector() {
        super();
    }
    public OrderCustomSelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(enforceCRUD, enforceFLS);
    }
    public override Schema.SObjectType getSObjectType()  {
        return Order__c.SObjectType;
    }

    public override List<Schema.SObjectField> getDefaultFieldList() {
        return new List<Schema.SObjectField> {
            Order__c.Id,
            Order__c.Account_ID__c,
            Order__c.Account__c,
            Order__c.Order_Type__c,
            Order__c.Brand__c,
            Order__c.Service_Name__c,
            Order__c.Tier__c
        };
    }

    private List<Schema.SObjectField> getOrderFieldList() {
        return new List<Schema.SObjectField> {
            Order__c.Id,
            Order__c.MRS_Delta__c,
            Order__c.Account__c
        };
    }

    public List<String> getSFtoSFSyncFields() {
        return new List<String>{
            'Id',
            'Account_ID__c',
            'Account__c',
            'Order_Type__c',
            'Brand__c',
            'Service_Name__c',
            'Tier__c',
            'Name',
            'CreatedBy.Name',
            'Attribution_Channel__c',
            'Attribution_L2__c',
            'Attribution_L3__c',
            'Attribution_Campaign__c',
            'BMID__c',
            'PID__c',
            'AID__c',
            'Billing_Ccity__c',
            'Billing_State__c',
            'Billing_Zip__c',
            'Billing_Country__c',
            'Number_of_DL_s__c',
            'X12M_Company_Booking_Amount__c',
            'Service_Plan_Change_Amount__c',
            'Serivce_Plan_Discount_Change_Amount__c',
            'Digital_Line_Change_Amount__c',
            'Digital_Line_Discount_Change_Amount__c',
            'Additional_Minutes_Purchase_Amount__c',
            'Devices_Purchase_Amount__c',
            'Other_One_Time_Purchases_Amount__c',
            'Other_Recurring_Change_Amount__c',
            'Other_Recurring_Discounts_Change_Amount__c',
            'Currency_Conversion_Rate__c',
            'Original_Booking_Currency__c',
            'Next_Account_Renewal_Date__c',
            'Paid_Service_Start_Date__c',
            'Account_Status__c',
            'Renewal_Term__c',
            'Shipping_Charges__c',
            'Partner__c',
            'Cost_Recovery_MRR__c',
            'Device_Leasing_Change_Amount__c',
            'Device_Leasing_Discount_Change_Amount__c',
            'Promotion_code_OID__c',
            'Service_Plan_Change_Amount_Uplifted__c',
            'Digital_Line_Change_Amount_Uplifted__c',
            'Other_Recurring_Change_Amount_Uplifted__c',
            'Device_Leasing_Change_Amount_Uplifted__c',
            'Cost_Recovery_Change_Amount_Uplifted__c',
            'Digital_Lines_included_in_service_plan__c',
            'Digital_Lines_added_to_service_plan__c',
            'Uplift_applied_to_included_Digital_Lines__c',
            'Uplift_applied_to_addl_Digital_Lines__c',
            'Total_uplift_applied_to_DLs__c',
            'Contact_Center_Change_Amount__c',
            'IBO_Change_Amount__c',
            'Contact_Center_Discount_Change_Amount__c',
            'IBO_Discount_Change_Amount__c',
            'Change_Type__c',
            'RC_Change_in_DL__c',
            'X12M_Commission_Booking_Amount__c',
            'Order_Date__c',
            'Account_Name__c',
            'Number_of_Employees__c',
            //'Campaign_ID__c',
            'Industry__c',
            'Lead_Score__c',
            'Lead_Source__c',
            'Sales_Model__c',
            'Account__r.Billing_ID__c',
            'Account__r.RC_User_ID__c'
        };
    }

    public QueryFactory selectOrders() {
        return newQueryFactory()
            .setFactoryName('selectOrders')
            .selectFields(getSFtoSFSyncFields())
            .subselect(new AgentCreditSelector().selectAgentCredits())
            .withoutSelectorOrderByIncluded();
    }

    public QueryFactory selectOrdersForSFToSFSync(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectOrdersForSFToSFSync')
            .selectFields(getSFtoSFSyncFields())
                .subselect(new AgentCreditSelector().selectAgentCredits())
            .withoutSelectorOrderByIncluded()
            .setCondition('Id IN :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectOrdersWithinMonthByAccountIds(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectOrdersWithinMonthByAccountIds')
            .selectFields(getOrderFieldList())
            .withoutSelectorOrderByIncluded()
            .setCondition('Account__c IN :bind0 AND CreatedDate = LAST_N_DAYS:30')
            .setQueryBindings(bindings);
    }
}