public with sharing class OpenIdAuthHandler implements Auth.RegistrationHandler {
    private final String priorityLisence = 'Salesforce';
    private final String defaultUserProfileName = 'RC Guest User';
    private final String defautEncoding = 'UTF-8';
    private final String defaultLocale = 'en_US';
    private final String defaultTimezone = 'GMT';
    private final String defaultRolesDelimiter = ',';
    private final String defaultMatchingDelimiter = ';';
    private final String defaultMatchingKeyValueDelimiter = '#=#';
    private final String defaultProfileMarker = '';

    public User createUser(Id portalId, Auth.UserData data) {
        if (data == null) {
            this.onError('UserData is null', null);
        }

        User u;
        Account contactAcc;
        Map<String, String> authProviderInfo = data.attributeMap;
        Id accId;

        if (authProviderInfo != null && authProviderInfo.get('useAdditionalInfo') == 'true') {
            String externalAccId = authProviderInfo.get('accountId');
            String defaultAccId = authProviderInfo.get('DefaultAccountUserID');
            contactAcc = handleAccount(externalAccId, defaultAccId, null);
            accId = contactAcc.Id;
        } else {
            //Here will be support for ordinary SSO in future
            this.onError('No Additional info found', null);
        }

        try {
            u = matchUserAndContact(contactAcc.Id, data);
        } catch(Exception e) {
            this.onError('We cant log you due to inapropriate information', e);
        }
        return u;
    }

    public void updateUser(Id userId, Id portalId, Auth.UserData data) {
        try {
            User u = [
                SELECT Id, Email, LastName, FirstName, IsActive, Profile.Name, UserName,
                    Profile.UserLicense.Name, ContactId, Contact.AccountId, ProfileId
                FROM User
                WHERE id = :userid
            ];

            u.email = String.isEmpty(data.email)? u.email: data.email;
            u.lastName = String.isEmpty(data.lastName)? u.lastName: data.lastName;
            u.firstName = String.isEmpty(data.firstName)? u.firstName: data.firstName;

            update(u);
            assignPermissionsToExistingUser(u, data);
            try {
                if(!u.isActive) {
                    u.isActive = true;
                    update u;
                }
            } catch (Exception e) {
//                there only a try to respawn unrewoked disabled user - if it cant - no reaction
//                not only all users can be respawned
            }

        } catch(Exception e) {
            this.onError('Your identity provider sent incorrect information', e);
        }
    }

    /*
        General error handler spam in the log with trace and details and throw pretty text error
     */
    private void onError(String message, Exception e) {
        if (e != null){
            PlatformLog.logException(OpenIdAuthHandler.class.getName(), e);
            System.debug('OpenIdHandler ##### ' + e.getMessage() + ' ##### ' + e.getStackTraceString());
        }
        throw new OpenIdAuthHandlerException(message);
    }

    /*
        Function is responsible for matching or creating contact for future user.
        In both cases must return inserted in DB Account with filled RC UID.
    */
    private Account handleAccount(String rcUserId, String defaultAccountRCId, Auth.UserData data) {
        Account resAcc;
        if (String.isEmpty(rcUserId)) {
            rcUserId = defaultAccountRCId;
        }

        if (String.isEmpty(rcUserId)) {
            onError('No informatin about your organization found', null);
        }

        List<Account> accMatches = [
            SELECT Id
            FROM Account
            WHERE RC_User_ID__c = :rcUserId
        ];

        if (accMatches.size() > 0) {
            resAcc = accMatches[0];
        } else {
            //Create Account
            resAcc = new Account (
                Name = 'RC UID ' + rcUserId,
                RC_User_ID__c = rcUserId
            );
            insert resAcc;
        }

        return resAcc;
    }

    /*
        The main function that checks if user or contact is already exists and creates or gives permissions to id
     */
    private User matchUserAndContact(Id accountId, Auth.UserData data) {
        List<User> userMatches;
        User retUser;
        String email = data.Email;

        if (String.isEmpty(email) || accountId == null) {
            this.onError('Few information for matching user', null);
        }

        userMatches = checkExistingUsers(accountId, email);

        if (userMatches.size() > 0) {
            //Here we choose licence with priority license
            for (User u : userMatches) {
                retUser = u;
                if (String.valueOf(Profile.UserLicense.Name) == priorityLisence) {
                    break;
                }
            }

            assignPermissionsToExistingUser(retUser, data);

        } else {
            String firstName = String.isEmpty(data.firstName) ? '' : data.firstName;
            String lastName = String.isEmpty(data.lastName) ? email : data.lastName;

            firstName = getSubstring(firstName, 39);
            lastName = getSubstring(lastName, 39);

            String[] strSplitmail = email.split('@');

            String userName = data.identifier + '.' + email;
            String nickName = data.identifier + '.' + strSplitmail[0];

            Integer maxNickNameLength = 39;
            Integer maxUserNameLength = 79;
            Integer uniqueLength = 5;
            Integer userNameLimit = maxUsernameLength - uniqueLength;
            Integer nickNameLimit = maxNickNameLength - uniqueLength;

            if(userName.length() > userNameLimit) {
                Integer newStartpositionName = userName.length() - userNameLimit;
                userName = username.substring(newStartpositionName, userName.length());
            }

            if(nickName.length() > nickNameLimit) {
                Integer newStartposition = nickName.length() - nickNameLimit;
                nickName = nickName.substring(newStartposition, nickName.length());
            }

            String alias = '';

            if(strSplitmail.size() > 0) {
                alias = getSubstring(strSplitmail[0], 8);
            } else {
                String al = String.valueOf((Math.Random() * 10000).intValue());
                alias = getSubstring(al, 8);
            }

            List<Contact> contacts = checkExistingContacts(accountId, email);

            Contact userContact;
            Boolean isNewContact = false;
            if (contacts.size() > 0) {
                userContact = contacts[0];
            } else {
                isNewContact = true;
                userContact = new Contact(
                    LastName = lastName,
                    FirstName = firstName,
                    AccountId = accountId,
                    Email = email
                );
                insert userContact;
            }

            Profile communityProfile = matchNewUserProfile(userContact, data, isNewContact);

            if (communityProfile == null) {
                onError('No profile found for user', null);
            }

            if (!isUserNameFieldUnique(userName, nickName)) {
                String addtionalUniqueValue = String.valueOf((Math.Random() * 12372).intValue());

                userName += '.' + getSubstring(addtionalUniqueValue, maxUsernameLength - userName.length() - 2);
                nickName += '.' + getSubstring(addtionalUniqueValue, maxNickNameLength - nickName.length() - 2);
            }

            retUser = new User(
                FirstName = firstName,
                LastName = lastName,
                Email = email,
                CommunityNickname = nickName,
                ContactId = userContact.Id,
                EmailEncodingKey = defautEncoding,
                LocaleSidKey  = defaultLocale,
                TimeZoneSidKey = defaultTimezone,
                Alias = alias,
                Username = userName,
                ProfileId = communityProfile.Id,
                LanguageLocaleKey = defaultLocale
            );
        }

        return retUser;
    }

    private String getSubstring(String inbound, Integer length) {
        if(String.isEmpty(inbound) || inbound.length() <= length) {
            return inbound;
        }
        return inbound.substring(0, length);
    }

    private List<User> checkExistingUsers(Id accountId, String email) {
        List<User> userMatches = [
            SELECT Id, Email, Profile.Name, Profile.UserLicense.Name, ContactId, Contact.AccountId, isActive
            FROM User
            WHERE (
                Email = :email
                OR Contact.Email= :email
            )
            AND Contact.AccountId = :accountId
            AND isActive = true
        ];
        return userMatches;
    }
    /*
     User with unique fields can exist, for now there only username and community nick.
     This function is responsible to check all such fields
     */
    private Boolean isUserNameFieldUnique(String userName, String nickName) {
        List<User> concurrentUserNameValue = [
            SELECT Id
            FROM User
            WHERE Username = :userName
            OR CommunityNickname = :nickName
        ];
        return concurrentUserNameValue.size() == 0;
    }
    /*
    Tis function is responsible to check if in SF exists contact with same account and email
    For one account can be only one contact with similar email
    */
    private List<Contact> checkExistingContacts(Id accountId, String email) {
        List<Contact> matchingContacts = [
            SELECT Id, Name, Email, AccountId
            FROM Contact
            WHERE Email = :email
            AND AccountId = :accountId
        ];
        return matchingContacts;
    }

    /*
    This function match profiles to roles based on settings from Auth provider in UserData for NEW users
    */
    @TestVisible
    private Profile matchNewUserProfile(Contact userContact, Auth.UserData data, boolean isNewContact) {
        Profile newUserProfile;
        String userPofileName;
        Boolean useDefaultProfile = true;
        String authProviderMatchingSettings;

        if (data != null && data.attributeMap != null) {
            authProviderMatchingSettings = data.attributeMap.get('UserRolesMatching');
        }

        if (userContact != null && userContact.Id != null && !isNewContact && !String.isEmpty(authProviderMatchingSettings)) {
            Map<String, String> roleProfileMatches =
                getMatchingInfoFromSettingString(data.attributeMap.get('UserRolesMatching'));

            List<AccountContactRole> contactRoles = getAccountRoleForContact(userContact.AccountId, userContact.Id);

            userPofileName = matchRoleWithPermissionName(contactRoles, roleProfileMatches);
            if (!String.isEmpty(userPofileName)) {
                useDefaultProfile = false;
            }
        }

        List<Profile> profiles = getProfilesByName(userPofileName);
        if ( profiles.size() > 0) {
            newUserProfile = profiles[0];
        } else {
            useDefaultProfile = true;
        }

        if (useDefaultProfile) {
            userPofileName = getDefaultProfileName(data);
            profiles = getProfilesByName(userPofileName);

            if ( profiles.size() > 0) {
                newUserProfile = profiles[0];
            } else {
                onError('No correct profile found for user', null);
            }
        }

        return newUserProfile;
    }

    /*
        Function for parsing long text area from CustomMetadata.
        Field value looks like:
        Profile good#=# role1 name, role2 NAME;
        profile2 #=# role3, role4 sd;
        profile4;
        No validation on client side for this field

        Should take the first founded profile for role to make admins move important roles higher in list
        every incorrect line should be ignored
        This function is used both for profiles and permissions cause of their similar names
    */
    @TestVisible
    private Map<String, String> getMatchingInfoFromSettingString(string settingField) {
        Map<String, String> roleProfileMatches = new Map<String, String>();

        if (String.isEmpty(settingField)) {
            return roleProfileMatches;
        }

        List<String> matchingLines = settingField.split(defaultMatchingDelimiter);
        if (matchingLines.size() > 0) {
            for (String matchLine : matchingLines) {
                List<String> valueMatch = matchLine.split(defaultMatchingKeyValueDelimiter);

                if (valueMatch.size() == 2) {
                    string profile = valueMatch[0].trim();
                    string rolesString = valueMatch[1];
                    List<String> roles = rolesString.split(defaultRolesDelimiter);

                    if (roles.size() > 0) {
                        for (string curRole : roles) {
                            string roleName = curRole.trim();

                            if (!String.isEmpty(roleName) && String.isEmpty(roleProfileMatches.get(roleName))) {
                                roleProfileMatches.put(roleName, profile);
                            }
                        }
                    }
                } else {
                    continue;
                }
            }
        }
        return roleProfileMatches;
    }

    /*
        Function similar to matchUserProfile but for existing users and returns permission sets
    */
    @TestVisible
    private List<PermissionSet> getPermissionSetsForAssign(User user, String matchSettings) {
        Map<String, String> matchingRolesSetings = getMatchingInfoFromSettingString(matchSettings);
        Id contactId = user.contactId;
        Id accountId = user.Contact.AccountId;

        List<AccountContactRole> contactRoles = getAccountRoleForContact(accountId, contactId);

        String permissionSetName = matchRoleWithPermissionName(contactRoles, matchingRolesSetings);

        List<PermissionSet> perms = new List<PermissionSet>();

        //To awoid mixed dml we cant both update user and insert permissions
        if (String.isEmpty(permissionSetName)) {
            return perms;
        } else {
            perms = getPermissionSetByName(permissionSetName);
        }
        return perms;
    }

    private String matchRoleWithPermissionName(List<AccountContactRole> contactRoles, Map<String, String> matchingRolesSetings) {
        String result;

        if (contactRoles.size() > 0) {
            for (AccountContactRole role : contactRoles) {
                String roleName = role.Role;
                String permissionName = matchingRolesSetings.get(roleName);

                if (permissionName != null && !String.isEmpty(permissionName)) {
                    result = permissionName;
                    break;
                }
            }
        }

        return result;
    }

    /*
    This function simply returns users permission sets ids to control uniqueness
     */
    private Map<String, Boolean> convertUserPermissionsAsIdMap(List<PermissionSetAssignment> userPsa) {
        Map<String, Boolean> userPerms = new Map<String, Boolean>();
        for (PermissionSetAssignment psa : userPsa) {
            userPerms.put(psa.PermissionSetId, true);
        }
        return userPerms;
    }

    @TestVisible
    private void assignPermissionsToExistingUser(User user, Auth.UserData data) {
        List<PermissionSet> permsForAssignment = getPermissionSetsForAssign(user, data.attributeMap.get('UserRolesMatching'));
        Boolean useDefault = true;

        List<PermissionSetAssignment> userPermissions = getUserPermissionSetAssignments(user.Id);
        Map<String, Boolean> assignedPermissions = convertUserPermissionsAsIdMap(userPermissions);

        if (permsForAssignment.size() > 0) {
            List<PermissionSetAssignment> ass = new List<PermissionSetAssignment>();
            for (PermissionSet per : permsForAssignment) {
                if (assignedPermissions.get(per.id) == null) {
                    PermissionSetAssignment psa = new PermissionSetAssignment
                        (PermissionSetId = per.id, AssigneeId = user.id);
                    ass.add(psa);
                }
            }

            //If smth wrong with permissions and licences for user return to default permission set
            try {
                insert ass;
                useDefault = false;
            } catch (Exception er) {
                useDefault = true;
            }
        }

        if (useDefault){
            String permName = getDefaultProfileName(data);
            List<PermissionSet> defPerm = getPermissionSetByName(permName);

            if (defPerm.size() > 0 && assignedPermissions.get(defPerm[0].Id) == null) {
                PermissionSetAssignment psa = new PermissionSetAssignment
                    (PermissionSetId = defPerm[0].Id, AssigneeId = user.id);
                insert psa;
            }
        }
    }

    private List<Profile> getProfilesByName(String profileName) {
        if (String.isEmpty(profileName)) {
            return  new List<Profile>();
        } else {
            return  (List<Profile>) [
                SELECT Id, Name
                FROM Profile
                WHERE Name = :profileName
            ];
        }
    }

    private List<AccountContactRole> getAccountRoleForContact(Id AccountId, Id contactId) {
        if (String.isEmpty(AccountId) || String.isEmpty(contactId)) {
            return  new List<AccountContactRole>();
        } else {
            return (List<AccountContactRole>) [
                SELECT Id, Role
                FROM AccountContactRole
                WHERE AccountId = :AccountId
                AND ContactId = :contactId
            ];
        }
    }

    private List<PermissionSet> getPermissionSetByName(String permissionSetName) {
        if (String.isEmpty(permissionSetName)) {
            return  new List<PermissionSet>();
        } else {
            return (List<PermissionSet>) [
                SELECT Id, Label
                FROM PermissionSet
                WHERE Label = :permissionSetName
            ];
        }
    }

    private List<PermissionSetAssignment> getUserPermissionSetAssignments(Id userId) {
        if (String.isEmpty(userId)) {
            return  new List<PermissionSetAssignment>();
        } else {
            return (List<PermissionSetAssignment>) [
                SELECT PermissionSetId
                FROM PermissionSetAssignment
                WHERE AssigneeId = :userId
            ];
        }
    }

    @TestVisible
    private String getDefaultProfileName(Auth.UserData data) {
        String userPofileName = data.attributeMap.get('DefaultUserProfileName');
        userPofileName = String.isEmpty(userPofileName) ?  defaultUserProfileName : userPofileName;
        return userPofileName;
    }

    private class OpenIdAuthHandlerException extends Exception {}
}