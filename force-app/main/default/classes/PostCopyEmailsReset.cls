/*
* Name         : PostCopyEmailsReset.cls
* Created By   : Fedor Golovanov (fgolovanov@aquivalabs.com)
* Created Date : 20/April/2017
* Description  : Resets emails and profiles after sandbox refresh. Part of the Sandbox Post Copy framework.
* Dependencies : PostCopyWorker.cls
*/

public with sharing class PostCopyEmailsReset extends PostCopyWorker {

    private static final String EMAIL_EXAMPLE_POSTFIX = '@example.com';
    private static final String EMAIL_INVALID_POSTFIX = '.invalid';

    private static final List<String> USER_PROFILE_NAMES_TO_DEACTIVATE = new List<String>{'Support T1'};

    public override String getClassName(){
        return PostCopyEmailsReset.class.getName();
    }

    private static String getClassNameStatic() {
        return PostCopyEmailsReset.class.getName();
    }

    public override void run() {
        /* Run resetting emails for existing users and creating new in async context to avoid mixed DML operations errors */
        System.enqueueJob(new AsyncResetEmails(context.sandboxName()));
    }

    public class AsyncResetEmails implements Queueable {
        private String sandboxName;

        public AsyncResetEmails(String sandboxName){
            this.sandboxName = sandboxName;
        }

        public void execute(QueueableContext context) {
            List<PlatformLog__c> logs = new List<PlatformLog__c>();

            Map<String, String> usersInfoMap = getUsersToResetEmailsInfo(sandboxName);
            logs.add(PlatformLog.buildLog(
                PostCopyEmailsReset.getClassNameStatic(),
                'Selected users to reset email',
                null,
                null,
                'Users: ' + usersInfoMap
            ));

            List<User> usersToDeactivate = getUsersToDeactivate(usersInfoMap.size());
            deactivateUsers(usersToDeactivate, logs);

            List<User> existingUsers = (List<User>) new UserSelector()
                .selectUserByUsername(new List<Object>{usersInfoMap.keySet()})
                .executeQuery();

            List<User> usersToUpdate = getUsersToUpdate(usersInfoMap, existingUsers);
            logs.add(PlatformLog.buildLog(
                PostCopyEmailsReset.getClassNameStatic(),
                'Users to update',
                null,
                null,
                'Users: ' + usersToUpdate
            ));
            updateUsers(usersToUpdate, logs);

            List<User> usersToCreate = getNewUsersToCreate(getOnlyNewUsersInfo(usersInfoMap, existingUsers));
            logs.add(PlatformLog.buildLog(
                PostCopyEmailsReset.getClassNameStatic(),
                'Users to create',
                null,
                null,
                'Users: ' + usersToCreate
            ));
            createUsers(usersToCreate, logs);


            List<User> usersWithoutEmployee = getUsersWithoutEmployee(usersToUpdate, usersToCreate);
            if(!Test.isRunningTest()) {
                System.enqueueJob(new AsyncEmployeeCreator(usersWithoutEmployee, PostCopyEmailsReset.getClassNameStatic()));
            }

            if (!logs.isEmpty() && !Test.isRunningTest()) {
                PlatformLog.logExceptionsAsync(JSON.serialize(logs));
            }
        }

        /* Returns the user data in the reuqired format. Username as key, compared to the new profile. */
        private Map<String, String> getUsersToResetEmailsInfo(String sandboxName) {
            Map<String, String> userData = new Map<String, String>();
            for (PostCopyEmailManagement__c username : [SELECT Id, Username__c, Sandboxes__c, Profile__c
                                                        FROM PostCopyEmailManagement__c]) {
                if (username.Sandboxes__c != null) {
                    for (String sbName : username.Sandboxes__c.split(',')) {
                        if (sbName.toLowerCase() == sandboxName.toLowerCase()) {
                            userData.put(
                                (username.Username__c + '.' + sandboxName).toLowerCase(),
                                username.Profile__c
                            );
                            break;
                        }
                    }
                }
            }

            for (Profile prof : [SELECT Id, Name
                                 FROM Profile
                                 WHERE Name IN :userData.values()]
            ) {
                for (String username : userData.keySet()) {
                    if (userData.get(username) != null && userData.get(username).toLowerCase() == prof.Name.toLowerCase()) {
                        userData.put(username, prof.Id);
                        continue;
                    }
                }
            }

            return userData;
        }

        private List<User> getUsersToDeactivate(Integer limitSize) {
            List<User> usersToDeactivate = [SELECT Id, isActive
                                            FROM User
                                            WHERE Profile.Name IN :USER_PROFILE_NAMES_TO_DEACTIVATE
                                            AND isActive = true
                                            AND Email LIKE '%.invalid'
                                            LIMIT :limitSize];

            for (User deactUser : usersToDeactivate) {
                deactUser.isActive = false;
            }

            return usersToDeactivate;
        }

        private void deactivateUsers(List<User> users, List<PlatformLog__c> logs) {
            if (!users.isEmpty()) {
                Database.SaveResult[] saveResultsDeactivate = Database.update(users, false);
                logs.addAll(PostCopyUtil.buildDatabaseOperationErrorsLogs(saveResultsDeactivate));
            }
        }

        private List<User> getUsersToUpdate(Map<String, String> usernameToProfileIdMap, List<User> existingUsers) {
            List<User> usersToUpdate = new List<User>();

            for (User u : existingUsers) {
                u.Email = convertEmail(u.Email);
                u.isActive = true;

                Id acceptableProfileId = usernameToProfileIdMap.get(u.Username);
                if (acceptableProfileId != null && u.ProfileId != acceptableProfileId) {
                    u.ProfileId = acceptableProfileId;
                }

                usersToUpdate.add(u);
            }

            return usersToUpdate;
        }

        private void updateUsers(List<User> users, List<PlatformLog__c> logs) {
            if (!users.isEmpty()) {
                Database.SaveResult[] saveResultsUpdate = Database.update(users, false);
                logs.addAll(PostCopyUtil.buildDatabaseOperationErrorsLogs(saveResultsUpdate));
            }
        }

        private List<User> getNewUsersToCreate(Map<String, String> usernameToProfileIdMap) {
            List<User> usersToCreate = new List<User>();

            for (String newUserName : usernameToProfileIdMap.keySet()) {

                String email = newUserName.substringBeforeLast('.');

                String firstName = email.substringBefore('@').contains('.')
                    ? email.substringBefore('.').trim().capitalize()
                    : email.substring(0,1).trim().capitalize();

                String lastName = email.substringBefore('@').contains('.')
                    ? email.substringBetween('.', '@').trim().capitalize()
                    : email.substringBefore('@').trim().capitalize();

                String alias = (firstName.left(1) + lastName.left(4)).toLowerCase();

                String cn = (firstName + lastName).toLowerCase() + String.valueOf(Datetime.now().getTime());

                usersToCreate.add(new User(
                    FirstName = firstName,
                    LastName = lastName,
                    Alias = alias,
                    ProfileId = usernameToProfileIdMap.get(newUserName),
                    Username = newUserName,
                    Email = email,
                    isActive = true,
                    CommunityNickname = cn,
                    PID__c = alias.capitalize(),
                    maxClaimLimit__c = 0,
                    EmailEncodingKey = 'UTF-8',
                    LocaleSidKey = 'en_US',
                    TimeZoneSidKey = 'America/Los_Angeles',
                    LanguageLocaleKey = 'en_US'
                ));
            }

            return usersToCreate;
        }

        private void createUsers(List<User> users, List<PlatformLog__c> logs) {
            Database.SaveResult[] saveResultsCreate = Database.insert(users, false);
            logs.addAll(PostCopyUtil.buildDatabaseOperationErrorsLogs(saveResultsCreate));
            try {
                resetUsersPassword(users);
            } catch (Exception e) {
                logs.add(PostCopyUtil.buildLogObj(PostCopyEmailsReset.getClassNameStatic() + '.createUsers', e));
            }
        }

        private Map<String, String> getOnlyNewUsersInfo(Map<String, String> usersInfo, List<User> existingUsers) {
            Map<String, String> newUsersInfo = new Map<String, String>(usersInfo);
            for (User u : existingUsers) {
                newUsersInfo.remove(u.Username);
            }
            return newUsersInfo;
        }

        /* Unconverts an email address to the normal format from
        *  https://releasenotes.docs.salesforce.com/en-us/spring14/release-notes/rn_forcecom_sandbox_email_modified.htm
        *  and
        *  https://help.salesforce.com/articleView?id=000193090&type=1
        */
        private String convertEmail(String emailAddress) {
            String converted = emailAddress;
            if (!String.isBlank(emailAddress)) {
                if (emailAddress.endsWith(EMAIL_EXAMPLE_POSTFIX)) {
                    converted = emailAddress.replace(EMAIL_EXAMPLE_POSTFIX, '').replace('=', '@');
                } else if (emailAddress.endsWith(EMAIL_INVALID_POSTFIX)) {
                    converted = emailAddress.replace(EMAIL_INVALID_POSTFIX, '');
                }
            }
            return converted;
        }

        private void resetUsersPassword(List<User> createdUsers) {
            Set<Id> usersId = new Set<Id>();
            for (User u : createdUsers) {
                if (u.Id != null) {
                    usersId.add(u.Id);
                }
            }

            for (User user : [SELECT Id, Profile.IsSsoEnabled, IsActive FROM User WHERE Id IN :usersId]) {
                if (user.Profile.IsSsoEnabled
                    || user.Id == null
                    || !user.IsActive
                    ) {
                    continue;
                }
                System.resetPassword(user.Id, true);
            }
        }

        private List<User> getUsersWithoutEmployee(List<User> updatedUsers, List<User> createdUsers) {
            List<User> users = new List<User>(createdUsers);

            Map<Id, User> updatedUsersMap = new Map<Id, User>(updatedUsers);
            for (Employee__c employee : [SELECT User__c FROM Employee__c WHERE User__c IN :updatedUsersMap.keySet()]) {
                updatedUsersMap.remove(employee.User__c);
            }
            users.addAll(updatedUsersMap.values());

            return users;
        }
    }

    public class AsyncEmployeeCreator implements Queueable {
        private List<Employee__c> employeeToCreate;
        private List<User> usersWithoutEmployee;
        private String className;

        public AsyncEmployeeCreator(List<User> usersWithoutEmployee, String className){
            this.usersWithoutEmployee = usersWithoutEmployee;
            this.className = className;
        }

        public void execute(QueueableContext context) {
            try {
                employeeToCreate = getEmployeeUsers(usersWithoutEmployee);
                Database.SaveResult[] srListEmployee = Database.insert(employeeToCreate, false);
                PostCopyUtil.handleSaveResults(srListEmployee);
            } catch(Exception e) {
                PostCopyUtil.createLogObj(className, e);
            }
        }

        private List<Employee__c> getEmployeeUsers(List<User> usersWithoutEmployee) {
            Employee__c[] employeesToCreate = new List<Employee__c>();

            for (User user : usersWithoutEmployee) {
                if (user.Id == null) {
                    continue;
                }
                String pid = user.PID__c == null
                    ? ((user.FirstName == null ? user.LastName.left(1) : user.FirstName.left(1)) + user.LastName.left(4)).capitalize()
                    : user.PID__c;

                employeesToCreate.add(new Employee__c(
                    Is_Active__c = true,
                    First_Name__c = user.FirstName,
                    Last_Name__c = user.LastName,
                    Email__c = user.Email,
                    SPID__c = pid,
                    User__c = user.Id,
                    Location__c = 'Remote',
                    Department__c = '550 - Business Services',
                    Division__c = 'Business Development',
                    Team__c = 'Developer'
                ));
            }

            return employeesToCreate;
        }
    }
}