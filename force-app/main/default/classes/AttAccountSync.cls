@RestResource(urlMapping='/AttAccountSync/*')
global class AttAccountSync {
    static RestRequest request;

    @HttpPost
    global static void insertAccount() {
        request = RestContext.request;
        List<Account> accountsToInsert = buildAccountsFromRequest();

        insert accountsToInsert;
    }

    @HttpPut
    global static void updateAccount() {
        request = RestContext.request;
        List<Account> accountsToUpdate = buildAccountsFromRequest();

        upsert accountsToUpdate RC_User_ID__c;
    }

    private static List<Account> buildAccountsFromRequest() {
        List<AccountFromATT> accountsFromATT = 
            (List<AccountFromATT>) JSON.deserialize(request.requestBody.toString(), List<AccountFromATT>.class);
        List<Account> createdAccounts = new List<Account>();
        Set<String> userNames = new Set<String>();
        Set<String> userEmails = new Set<String>();
        Set<String> accountHierarchyNames = new Set<String>();

        for (AccountFromATT attAccount : accountsFromATT) {
            if (userExistsOnAtt(attAccount.Current_Owner_Name, attAccount.Current_Owner_Email)) {
                userNames.add(attAccount.Current_Owner_Name);
                userEmails.add(attAccount.Current_Owner_Email);
            }
            if (userExistsOnAtt(attAccount.Inside_Sales_Rep_Name, attAccount.Inside_Sales_Rep_Email)) {
                userNames.add(attAccount.Inside_Sales_Rep_Name);
                userEmails.add(attAccount.Inside_Sales_Rep_Email);
            }
            if (accountHierarchyExistsOnAtt(attAccount.AH_Name_Name)) {
                accountHierarchyNames.add(attAccount.AH_Name_Name);
            }
        }

        if ((!userNames.isEmpty() && !userEmails.isEmpty()) || !accountHierarchyNames.isEmpty()) {
            createdAccounts = createAccountsBasedOnRequest(accountsFromATT, userNames, userEmails, accountHierarchyNames);
        }

        return createdAccounts;
    }

    private static Boolean userExistsOnAtt(String name, String email) {
        return name != null && email != null;
    }

    private static Boolean accountHierarchyExistsOnAtt(String name) {
        return name != null;
    }

    private static List<Account> createAccountsBasedOnRequest(List<AccountFromATT> accountsFromATT, Set<String> userNames, Set<String> userEmails, Set<String> accountHierarchyNames) {
        List<Account> createdAccounts = new List<Account>();

        Map<UserIdentifier, Id> uniqueUserIdentifierToId = prepareUniqueIdentifierMapForUsers(userNames, userEmails);

        Map<String, Id> accountHierarchyNameToId = prepareUniqueIdentifierMapForAccountHierarchies(accountHierarchyNames);
        
        for (AccountFromATT attAccount : accountsFromATT) {
            Account acc = new Account();
            acc.RC_User_ID__c = attAccount.RC_User_ID;
            acc.RC_Account_Status__c = attAccount.RC_Account_Status;
            acc.Website = attAccount.Website;
            acc.MRR__c = attAccount.MRR;
            acc.Partner_ID__c = attAccount.Partner_ID;
            acc.VAR_Territory__c = attAccount.VAR_Territory;
            acc.RC_Brand__c = attAccount.RC_Brand;

            if (request.httpMethod == HttpHelper.METHOD_POST) {
                acc.Name = attAccount.Name;
            }

            acc.Current_Owner__c = matchUser(attAccount.Current_Owner_Name, attAccount.Current_Owner_Email, uniqueUserIdentifierToId);
            acc.Inside_Sales_Rep__c = matchUser(attAccount.Inside_Sales_Rep_Name, attAccount.Inside_Sales_Rep_Email, uniqueUserIdentifierToId);
            acc.AH_Name__c = matchAccountHierarchy(attAccount.AH_Name_Name, accountHierarchyNameToId);

            createdAccounts.add(acc);
        }

        return createdAccounts;
    }

    private static Map<UserIdentifier, Id> prepareUniqueIdentifierMapForUsers(Set<String> userNames, Set<String> userEmails) {
        Map<UserIdentifier, Id> uniqueUserIdentifierToId = new Map<UserIdentifier, Id>();

        if (!userNames.isEmpty() && !userEmails.isEmpty()) {
            List<User> usersOnOrg = new UserSelector()
            .selectUserByNameAndEmail(new List<Object>{userNames, userEmails})
            .executeQuery();

            for (User user : usersOnOrg) {
                uniqueUserIdentifierToId.put(new UserIdentifier(user.Name, user.Email), user.Id);
            }
        }
        
        return uniqueUserIdentifierToId;
    }

    private static Map<String, Id> prepareUniqueIdentifierMapForAccountHierarchies(Set<String> accountHierarchyNames) {
        Map<String, Id> accountHierarchyToName = new Map<String, Id>();

        if (!accountHierarchyNames.isEmpty()) {
            List<Account_Hierarchy__c> accountHierarchiesOnOrg = new AccountHierarchySelector()
                .selectAccountHierarchyByName(new List<Object>{accountHierarchyNames})
                .executeQuery();

            for (Account_Hierarchy__c ah : accountHierarchiesOnOrg) {
                accountHierarchyToName.put(ah.Name, ah.Id);
            }
        }

        return accountHierarchyToName;
    }

    private static Id matchUser(String name, String email, Map<UserIdentifier, Id> uniqueUserIdentifierToId) {
        UserIdentifier attUserIdentifier = new UserIdentifier(name, email);
        return uniqueUserIdentifierToId.get(attUserIdentifier);
    }

    private static Id matchAccountHierarchy(String name, Map<String, Id> accountHierarchyToName) {
        return accountHierarchyToName.get(name);
    }

    public class AccountFromATT {
        String Name;
        String RC_User_ID;
        String Current_Owner_Name;
        String Current_Owner_Email;
        String RC_Account_Status;
        String Website;
        String AH_Name_Name;
        Double MRR;
        String Partner_ID;
        String Inside_Sales_Rep_Name;
        String Inside_Sales_Rep_Email;
        String VAR_Territory;
        String RC_Brand;
    }

    public class UserIdentifier {
        public String name;
        public String email;

        public UserIdentifier(String name, String email) {
            this.name = name;
            this.email = email;
        }

        public Boolean equals(Object obj) {
            if (this === obj) {
                return true;
            }
            if (obj != null && obj instanceof AttAccountSync.UserIdentifier) {
                UserIdentifier ai = (UserIdentifier) obj;
                if ((this.name != null && this.email != null) && (ai.name != null && ai.email != null)) {
                    return ai.name.equalsIgnoreCase(this.name) && ai.email.equalsIgnoreCase(email);
                }
            }
            return false;
        }

        public Integer hashCode() {
            return (name + email).hashcode();
        }
    }
}