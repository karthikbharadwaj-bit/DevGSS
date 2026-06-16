public inherited sharing class MavenlinkIntegratorSelector extends SObjectSelector {
    public MavenlinkIntegratorSelector() {
        super();
    }

    public MavenlinkIntegratorSelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(enforceCRUD, enforceFLS);
    }
    
    public override SObjectType getSObjectType() {
        return Mavenlink_Integrator__c.SObjectType;
    }

    public override List<SObjectField> getDefaultFieldList() {
        return new List<Schema.SObjectField> {
            Mavenlink_Integrator__c.Id,
            Mavenlink_Integrator__c.Name,
            Mavenlink_Integrator__c.PhaseStatus__c,
            Mavenlink_Integrator__c.PhaseId__c,
            Mavenlink_Integrator__c.Account__c,
            Mavenlink_Integrator__c.AccountId__c,
            Mavenlink_Integrator__c.Initial_Payment__c,
            Mavenlink_Integrator__c.EstimatedProfessionalServices12Month__c,
            Mavenlink_Integrator__c.Estimated_Completion_Date__c,
            Mavenlink_Integrator__c.Current_Owner_Name__c,
            Mavenlink_Integrator__c.Current_Owner_Manager_Name__c
        };
    }

    public QueryFactory selectMavenlinkIntegrator() {
        return newQueryFactory()
            .setFactoryName('selectMavenlinkIntegrator')
            .withSelectorFieldsIncluded();
    }
}