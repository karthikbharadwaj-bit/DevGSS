public with sharing class PostCopyEmployeesInsert extends PostCopyWorker {

    public override String getClassName(){
        return PostCopyEmployeesInsert.class.getName();

    }

    public override void run() {
        Set<String> profiles = profilesForNewRecords();
        List<User> insertedUsers = [SELECT Id, FirstName, LastName, Profile.Name, Email, PID__c FROM User WHERE Profile.Name IN :profiles];
        List<Employee__c> employees = new List<Employee__c>();
        for (User user : insertedUsers) {
            employees.add(new Employee__c(
                Is_Active__c = true,
                First_Name__c = user.FirstName,
                Last_Name__c = user.LastName,
                Email__c = user.Email,
                SPID__c = user.PID__c,
                User__c = user.Id,
                Location__c = 'Remote',
                Department__c = '550 - Business Services',
                Division__c = 'Business Development',
                Team__c = 'Developer'
            ));
        }
        insert employees;

    }

    public static Set<String> profilesForNewRecords () {
        Set<String> profiles = new Set<String>();
        List<PostCopyEmployeesManagement__c> settings = PostCopyEmployeesManagement__c.getAll().values();
        for(PostCopyEmployeesManagement__c record : settings) {
            profiles.add(record.Profile_Name__c);
        }
        return profiles;
    }

}