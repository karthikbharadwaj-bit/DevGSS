public with sharing class AccountPlanTriggerHelper {

    public class EnrichWithEmployeeDetails extends Triggers.TriggerHandlerBase {
        override public void handle() {
            if (Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {
                List<Account_Plan__c> accountPlans = (List<Account_Plan__c>) triggerRecords;
                enrichAccountPlanWithEmployeeDetails(accountPlans);
            }
        }

        public void enrichAccountPlanWithEmployeeDetails(List<Account_Plan__c> accountPlans) {
            Set<Id> accountPlanOwners = getAccountPlanOwners(accountPlans);
            Map<String, Employee__c> mapEmployeesByUserId = getEmployeeDetailsByUserId(accountPlanOwners);
            Map<String, Employee__c> mapManagersByEmployeeId = getManagerDetailsByEmployeeId(mapEmployeesByUserId.values());

            for (Account_Plan__c accountPlan : accountPlans) {
                Employee__c employee = mapEmployeesByUserId.get(accountPlan.OwnerId);

                if (employee != null) {
                    accountPlan.Owner_Team__c = employee.Team__c;
                    accountPlan.Owner_Division__c = employee.Division__c;
                    accountPlan.Owner_Email__c = employee.Email__c;

                    Employee__c manager = mapManagersByEmployeeId.get(employee.Id);

                    if (manager != null) {
                        accountPlan.Owner_Manager_Email__c = manager.Email__c;

                        if (manager.First_Name__c == null) {
                            manager.First_Name__c = '';
                        }

                        if (manager.Last_Name__c == null) {
                            manager.Last_Name__c = '';
                        }

                        accountPlan.Owner_Manager_Name__c = String.join(new List<String>{
                            manager.First_Name__c,
                            manager.Last_Name__c
                        }, ' ');
                    }
                }
            }
        }

        public Set<Id> getAccountPlanOwners(List<Account_Plan__c> accountPlans) {
            Set<Id> setUsers = new Set<Id>();

            for (Account_Plan__c accountPlan : accountPlans) {
                setUsers.add(accountPlan.OwnerId);
            }

            return setUsers;
        }

        public Map<String, Employee__c> getEmployeeDetailsByUserId(Set<Id> userIds) {
            Map<String, Employee__c> mapEmployeesByUserId = new Map<String, Employee__c>();

            for (Employee__c employee : [
                SELECT Team__c, Email__c, Division__c, Manager_Employee_Number__c, User__c
                FROM Employee__c
                WHERE User__c IN :userIds
            ]) {
                mapEmployeesByUserId.put(employee.User__c, employee);
            }

            return mapEmployeesByUserId;
        }

        public Map<String, Employee__c> getManagerDetailsByEmployeeId(List<Employee__c> setEmployees) {
            Map<String, Employee__c> mapManagerDetailsByEmployeeId = new Map<String, Employee__c>();
            Set<String> setManagerEmployeeNumbers = new Set<String>();

            for (Employee__c employee : setEmployees) {
                setManagerEmployeeNumbers.add(employee.Manager_Employee_Number__c);
            }

            Map<Id, Employee__c> managers = new Map<Id, Employee__c>([
                SELECT Id, First_Name__c, Last_Name__c, Email__c
                FROM Employee__c
                WHERE Id IN :setManagerEmployeeNumbers
            ]);

            for (Employee__c employee : setEmployees) {
                Employee__c manager = managers.get(employee.Manager_Employee_Number__c);
                if (manager != null) {
                    mapManagerDetailsByEmployeeId.put(employee.Id, manager);
                }
            }

            return mapManagerDetailsByEmployeeId;
        }
    }
}