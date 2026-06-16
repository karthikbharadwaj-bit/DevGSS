global class SyncBizAccountWS {

    //Define an object in apex that is exposed in apex web service
    global class syncAcctInputParam {
        /*InPut*/
        webservice String ATT_Opportunity_Id;
        webservice String ATT_Contract_Id;
        webservice String ATT_SubAccount_Id;
        webservice Decimal ATT_Number_Of_Licenses;
        webservice String ATT_Order_Submission_Date;
        webservice String ATT_Address;
        webservice String ATT_Edition;
        webservice String In_OpportunityID;
        webservice String In_RCUserID;
        webservice String In_RCPrimaryNumber;
        webservice String In_Company;
        webservice String In_FirstName;
        webservice String In_LastName;
        webservice String In_ContactEmail;
        webservice String In_Contactphone;
        webservice String In_RCBRAND;
        webservice String In_RCBRANDID;
        webservice String In_Partner_Deal_Registration_Id;
        webservice String In_Bandwidth_Test_Id;
        webservice Decimal In_Bandwidth_MOS_Score;
        webservice Decimal In_Bandwidth_Num_Sim_Calls;
        webservice Boolean In_Porting_Numbers;

        /*New Field added*/
        webservice String In_SignupType ;
        webservice String In_SignupPlatform;

        /*New fields added, 23/06/2011 */
        webservice String In_SERVICENAME;
        webservice String In_TIERNAME;
        /*New fields added, 28/06/2011 */
        webservice String In_Attribute_Key_01;
        webservice String In_Attribute_Value_01;
        webservice String In_Attribute_Key_02;
        webservice String In_Attribute_Value_02;
        webservice String In_Attribute_Key_03;
        webservice String In_Attribute_Value_03;
        webservice String In_Attribute_Key_04;
        webservice String In_Attribute_Value_04;
        webservice String In_Attribute_Key_05;
        webservice String In_Attribute_Value_05;
        /*New field added, 16/05/2018 */
        webservice String In_CugNumber;
        /*New field added, 14/04/2020 */
        webservice String In_Industry;

        /*OutPut*/
        webservice String Out_AccountID;
        webservice String Out_ContactID;
        webservice String Out_UserID;
        webservice String OutErrorMsg = '';

        /*Processing*/
        webservice String proc_AccountId;
        webservice String proc_ContactId;
        webservice String proc_UserId;
        webservice String proc_UserRecCreation;
        webservice String proc_debugmsg;

        public List<Contact> searchContact;
        public List<Lead> searchlead;
    }


    public final static Set<Id> PROFILE_IDS_OF_PORTAL_USERS = getProfilesForPortalUsers();
    public final static Id PROFILE_ID_FOR_NEW_PORTAL_USERS = getProfileForNewUser();
    static Boolean disableCugSync = Feature_Toggle__c.getInstance().Disable_CUG_Account_Sync__c;


    public SyncBizAccountWS() {
    }

    webservice static syncAcctInputParam synAccountNew(syncAcctInputParam vsyncAcctInputParam) {
        if (searchAccountByUID(vsyncAcctInputParam) == true) {
            /*Block*/
            if (disableCugSync) {
                updateCugNumber(vsyncAcctInputParam);
            }
            if (accountMatchingContactEmail(vsyncAcctInputParam) == true) {
                if (contactHavingUserRecord(vsyncAcctInputParam) == true) {
                    handleReturn(vsyncAcctInputParam);
                } else {
                    if (handleCreateUser(vsyncAcctInputParam) == true) {
                        handleReturn(vsyncAcctInputParam);
                    }
                }
            } else {
                if (handleCreateContact(vsyncAcctInputParam) == true) {
                    if (handleCreateUser(vsyncAcctInputParam) == true) {
                        handleReturn(vsyncAcctInputParam);
                    }
                }
            }
            /*Block*/
        } else {
            if (String.isNotBlank(vsyncAcctInputParam.In_Partner_Deal_Registration_Id) &&
                searchContactandLeadByDealId(vsyncAcctInputParam) == true) {
                if (vsyncAcctInputParam.searchContact != null) {
                    System.debug('*** Contact found ***');
                    //Contact is Found
                    vsyncAcctInputParam.proc_AccountId = vsyncAcctInputParam.searchContact.get(0).AccountId;
                    vsyncAcctInputParam.proc_ContactId = vsyncAcctInputParam.searchContact.get(0).Id;
                    handleUpdateAccount(vsyncAcctInputParam);
                    handleReturn(vsyncAcctInputParam);
                } else if (vsyncAcctInputParam.searchlead != null) {
                    System.debug('*** Lead found ***');
                    if (handleConverLead(vsyncAcctInputParam) == true) {
                        handleUpdateAccount(vsyncAcctInputParam);
                        handleReturn(vsyncAcctInputParam);
                    }
                }
            } else {
                if (vsyncAcctInputParam.In_OpportunityID != null && vsyncAcctInputParam.In_OpportunityID != '') {
                    if (searchOppertunityByOID(vsyncAcctInputParam) == true) {
                        if (handleUpdateAccount(vsyncAcctInputParam) == true) {
                            /*Block*/
                            if (accountMatchingContactEmail(vsyncAcctInputParam) == true) {
                                if (contactHavingUserRecord(vsyncAcctInputParam) == true) {
                                    handleReturn(vsyncAcctInputParam);
                                } else {
                                    if (handleCreateUser(vsyncAcctInputParam) == true) {
                                        handleReturn(vsyncAcctInputParam);
                                    }
                                }
                            } else {
                                if (handleCreateContact(vsyncAcctInputParam) == true) {
                                    if (handleCreateUser(vsyncAcctInputParam) == true) {
                                        handleReturn(vsyncAcctInputParam);
                                    }
                                }
                            }
                            /*Block*/
                        } else {
                            handleReturn(vsyncAcctInputParam);
                        }
                    } else {
                        if (searchContactByMailAndBrand(vsyncAcctInputParam) == true) {
                            if (handleUpdateAccount(vsyncAcctInputParam) == true) {
                                /*Block*/
                                if (accountMatchingContactEmail(vsyncAcctInputParam) == true) {
                                    if (contactHavingUserRecord(vsyncAcctInputParam) == true) {
                                        handleReturn(vsyncAcctInputParam);
                                    } else {
                                        if (handleCreateUser(vsyncAcctInputParam) == true) {
                                            handleReturn(vsyncAcctInputParam);
                                        }
                                    }
                                } else {
                                    if (handleCreateContact(vsyncAcctInputParam) == true) {
                                        if (handleCreateUser(vsyncAcctInputParam) == true) {
                                            handleReturn(vsyncAcctInputParam);
                                        }
                                    }
                                }
                                /*Block*/
                            } else {
                                handleReturn(vsyncAcctInputParam);
                            }
                        } else {
                            if (searchLeadByEmail(vsyncAcctInputParam) == true) {
                                if (handleConverLead(vsyncAcctInputParam) == true) {
                                    if (handleUpdateAccount(vsyncAcctInputParam) == true) {
                                        /*Block*/
                                        if (accountMatchingContactEmail(vsyncAcctInputParam) == true) {
                                            if (contactHavingUserRecord(vsyncAcctInputParam) == true) {
                                                handleReturn(vsyncAcctInputParam);
                                            } else {if (handleCreateUser(vsyncAcctInputParam) == true) {
                                                    handleReturn(vsyncAcctInputParam);
                                                }
                                            }
                                        } else {if (handleCreateContact(vsyncAcctInputParam) == true) {
                                                if (handleCreateUser(vsyncAcctInputParam) == true) {
                                                    handleReturn(vsyncAcctInputParam);
                                                }
                                            }
                                        }
                                        /*Block*/
                                    } else {
                                        handleReturn(vsyncAcctInputParam);
                                    }
                                }
                            } else {
                                if (handleCreateAccount(vsyncAcctInputParam) == true) {
                                    if (handleCreateContact(vsyncAcctInputParam) == true) {
                                        if (handleCreateUser(vsyncAcctInputParam) == true) {
                                            handleReturn(vsyncAcctInputParam);
                                        }
                                    }
                                }
                            }
                        }
                    }
                } else {
                    if (searchContactByMailAndBrand(vsyncAcctInputParam) == true) {
                        if (handleUpdateAccount(vsyncAcctInputParam) == true) {
                            /*Block*/
                            if (accountMatchingContactEmail(vsyncAcctInputParam) == true) {
                                if (contactHavingUserRecord(vsyncAcctInputParam) == true) {
                                    handleReturn(vsyncAcctInputParam);
                                } else {
                                    if (handleCreateUser(vsyncAcctInputParam) == true) {
                                        handleReturn(vsyncAcctInputParam);
                                    }
                                }
                            } else {
                                if (handleCreateContact(vsyncAcctInputParam) == true) {
                                    if (handleCreateUser(vsyncAcctInputParam) == true) {
                                        handleReturn(vsyncAcctInputParam);
                                    }
                                }
                            }
                            /*Block*/
                        } else {handleReturn(vsyncAcctInputParam);
                        }
                    } else {
                        if (searchLeadByEmail(vsyncAcctInputParam) == true) {
                            if (handleConverLead(vsyncAcctInputParam) == true) {
                                if (handleUpdateAccount(vsyncAcctInputParam) == true) {
                                    /*Block*/
                                    if (accountMatchingContactEmail(vsyncAcctInputParam) == true) {
                                        if (contactHavingUserRecord(vsyncAcctInputParam) == true) {
                                            handleReturn(vsyncAcctInputParam);
                                        } else {
                                            if (handleCreateUser(vsyncAcctInputParam) == true) {
                                                handleReturn(vsyncAcctInputParam);
                                            }
                                        }
                                    } else {
                                        if (handleCreateContact(vsyncAcctInputParam) == true) {
                                            if (handleCreateUser(vsyncAcctInputParam) == true) {
                                                handleReturn(vsyncAcctInputParam);
                                            }
                                        }
                                    }
                                    /*Block*/
                                } else {
                                    handleReturn(vsyncAcctInputParam);
                                }
                            }
                        } else {
                            if (handleCreateAccount(vsyncAcctInputParam) == true) {
                                if (handleCreateContact(vsyncAcctInputParam) == true) {
                                    if (handleCreateUser(vsyncAcctInputParam) == true) {
                                        handleReturn(vsyncAcctInputParam);
                                    }
                                }
                            }
                        }
                    }
                }

            }
        }
        return vsyncAcctInputParam;
    }

    webservice static syncAcctInputParam synAccountCreateUser(syncAcctInputParam vsyncAcctInputParam) {
        System.debug('vsyncAcctInputParam.In_FirstName: ' + vsyncAcctInputParam.In_FirstName);
        System.debug('vsyncAcctInputParam.In_ContactEmail: ' + vsyncAcctInputParam.In_ContactEmail);
        System.debug('vsyncAcctInputParam.In_RCUserID: ' + vsyncAcctInputParam.In_RCUserID);
        System.debug('vsyncAcctInputParam.In_LastName: ' + vsyncAcctInputParam.In_LastName);
        String strGetIn_FirstName = vsyncAcctInputParam.In_FirstName;
        String strGetIn_ContactEmail = vsyncAcctInputParam.In_ContactEmail;

        /*Logic to get USRID

        Community nick name = email user name + user Id email id is validated per null or @ String, if it is not found,
        returns as input String else, split into Strings per @, provided that it is available in email, else we take an empty '' String.

        */
        String contactEmail = vsyncAcctInputParam.In_ContactEmail;
        String community_Nick_Name = (contactEmail != null && (contactEmail).indexOf('@') != -1 ?
            ((contactEmail.trim()).indexOf('@') == 0 ? '' : (contactEmail).split('@')[0]) : contactEmail)
            + vsyncAcctInputParam.In_RCUserID;


        Integer resultUserNameLen = 0;
        String proc_EmailWORCUSERID = vsyncAcctInputParam.In_ContactEmail;
        String proc_EmailWithRCUSERID = vsyncAcctInputParam.In_RCUserID + vsyncAcctInputParam.In_ContactEmail;

        if (vsyncAcctInputParam.proc_UserRecCreation == '-1') {
            resultUserNameLen = proc_EmailWithRCUSERID.length();
            proc_EmailWithRCUSERID = proc_EmailWithRCUSERID.replace('@', '.');
            if (resultUserNameLen > 70) {
                proc_EmailWithRCUSERID = proc_EmailWithRCUSERID.substring(0, 70);
            }
            proc_EmailWithRCUSERID = proc_EmailWithRCUSERID + '@rc.com';

            /**/

            /*
            If User found then return the userid
            */
            List<User> objUser = new List<User>();
            List<Contact> objContact = [
                SELECT Id
                FROM Contact
                WHERE Account.RC_User_ID__c = :vsyncAcctInputParam.In_RCUserID
                AND Email = :vsyncAcctInputParam.In_ContactEmail
            ];
            if (objContact.size() > 0) {
                objUser = [
                    SELECT Id
                    FROM User
                    WHERE ContactId = :objContact[0].Id
                    AND ProfileId IN :PROFILE_IDS_OF_PORTAL_USERS
                    AND IsActive = TRUE
                    ORDER BY ProfileId ASC
                ];
                if (objUser.size() > 0) {
                    vsyncAcctInputParam.proc_UserId = objUser[0].Id;
                    handleReturn(vsyncAcctInputParam);
                    return vsyncAcctInputParam;
                }
            }

            /* Create New USER*/
            try {
                Integer result = strGetIn_FirstName.length();
                if (result > 8) {
                    strGetIn_FirstName = strGetIn_FirstName.substring(0, 8);
                }
                String strCommunityNickname = community_Nick_Name + System.now().getTime();
                // String strUsername=proc_EmailWithRCUSERID+System.Now().getTime();

                User u = new User(
                    Alias = strGetIn_FirstName,
                    Email = proc_EmailWORCUSERID,
                    EmailEncodingKey = 'UTF-8',
                    LastName = vsyncAcctInputParam.In_LastName,
                    LanguageLocaleKey = 'en_US',
                    LocaleSidKey = 'en_US',
                    ProfileId = getProfileForNewUser(),
                    ContactId = vsyncAcctInputParam.proc_ContactId,
                    TimeZoneSidKey = 'America/Los_Angeles',
                    Username = proc_EmailWithRCUSERID + System.now().getTime(),
                    CommunityNickname = (strCommunityNickname.length() > 40 ? strCommunityNickname.substring(0, 38) : strCommunityNickname)
                );
                System.debug('Before');
                insert u;
                System.debug('After');
                vsyncAcctInputParam.proc_UserId = u.Id;
                handleReturn(vsyncAcctInputParam);
            } catch (Exception ex) {
                vsyncAcctInputParam.OutErrorMsg += ' Error while creating user :: ' + ex.getMessage();
                System.debug(ex.getMessage());
            }
        }

        return vsyncAcctInputParam;
    }

    webservice static syncAcctInputParam[] synAccountCreateUsers (syncAcctInputParam[] vsyncAcctInputParams) {
        try {List<User> users = getUsers(vsyncAcctInputParams);

            List<User> usersToInsert = new List<User>();
            // indexes in syncAcctInputParams list for which user is not found and should be created.
            // i.e. usersToInsert[0] is for inputParamsWithNewUser[0] and so on
            List<Integer> inputParamsWithNewUser = new List<Integer>();
            for (Integer i = 0; i < vsyncAcctInputParams.size(); ++i) {
                for (User u : users) {
                    if (u.ContactId != null && u.Contact.Email == vsyncAcctInputParams[i].In_ContactEmail && u.Contact.AccountId != null && u.Contact.Account.RC_User_ID__c == vsyncAcctInputParams[i].In_RCUserID) {
                        vsyncAcctInputParams[i].proc_UserId = u.Id;
                        break;
                    }
                }
                if (vsyncAcctInputParams[i].proc_UserId == null) {
                    inputParamsWithNewUser.add(i);
                    usersToInsert.add(buildUser(vsyncAcctInputParams[i]));
                }
            }
            // insert users
            Database.SaveResult[] srs = Database.insert(usersToInsert, false);
            for (Integer i = 0; i < srs.size(); ++i) {
                Database.SaveResult sr = srs[i];
                syncAcctInputParam vsyncAcctInputParam = vsyncAcctInputParams[inputParamsWithNewUser[i]];
                if (sr.isSuccess()) {
                    vsyncAcctInputParam.proc_UserId = sr.getId();
                } else {
                    for (Database.Error err: sr.getErrors()) {
                        vsyncAcctInputParam.outErrorMsg += ' Error while creating user :: ' + err.getMessage();
                    }
                }
            }
        } catch (Exception ex) {
            for (syncAcctInputParam vsyncAcctInputParam : vsyncAcctInputParams) {
                vsyncAcctInputParam.outErrorMsg += ' Error while creating user :: ' + ex.getMessage();
            }
        }
        for (syncAcctInputParam vsyncAcctInputParam : vsyncAcctInputParams) {
            handleReturn(vsyncAcctInputParam);
        }
        return vsyncAcctInputParams;
    }

    @TestVisible
    private static List<User> getUsers(syncAcctInputParam[] vsyncAcctInputParams) {
        List<String> inRcUserIds = new List<String>();
        List<String> inContactEmails = new List<String>();
        for (syncAcctInputParam vsyncAcctInputParam : vsyncAcctInputParams) {
            if (vsyncAcctInputParam.proc_UserRecCreation == '-1') {
                if (vsyncAcctInputParam.In_RCUserID != null && vsyncAcctInputParam.In_ContactEmail != null
                ) {
                    inRcUserIds.add(vsyncAcctInputParam.In_RCUserID);
                    inContactEmails.add(vsyncAcctInputParam.In_ContactEmail);
                }
            }
        }
        return [SELECT Id FROM User WHERE Contact.Email IN :inContactEmails AND Contact.Account.RC_User_ID__c IN :inRcUserIds AND ProfileId IN :SyncBizAccountWS.PROFILE_IDS_OF_PORTAL_USERS AND IsActive = true ORDER BY ProfileId ASC];
    }

    @TestVisible
    private static User buildUser(syncAcctInputParam vsyncAcctInputParam) {
        /* Logic to get USRID
            Community nick name = email user name + user Id email id is validated per null or @ string, if it is not found,
            returns as input string else, split into Strings per @, provided that it is available in email, else we take an empty '' string.
        */
        Long now = System.now().getTime();
        return new User(alias = StringHelper.safeString(vsyncAcctInputParam.In_FirstName).left(8),Email = vsyncAcctInputParam.In_ContactEmail,Emailencodingkey = 'UTF-8',Lastname = vsyncAcctInputParam.In_LastName,Languagelocalekey = 'en_US',Localesidkey = 'en_US',Profileid = SyncBizAccountWS.PROFILE_ID_FOR_NEW_PORTAL_USERS,ContactId = vsyncAcctInputParam.proc_ContactId,Timezonesidkey = 'America/Los_Angeles',
            Username = ((StringHelper.safeString(vsyncAcctInputParam.In_RCUserID) + StringHelper.safeString(vsyncAcctInputParam.In_ContactEmail)).replace('@', '.').left(70) + '@rc.com' + now),CommunityNickname = (buildCommunityNickName(vsyncAcctInputParam) + now).left(40));
    }

    @TestVisible
    private static String buildCommunityNickName(syncAcctInputParam vsyncAcctInputParam) {
        return StringHelper.safeString(vsyncAcctInputParam.In_ContactEmail).trim().split('@')[0] + StringHelper.safeString(vsyncAcctInputParam.In_RCUserID);
    }

    //webservice static syncAcctInputParam synAccountCreateUserOLD(syncAcctInputParam vsyncAcctInputParam) {}


    public static Boolean searchAccountByUID(syncAcctInputParam vsyncAcctInputParam) {
        try {
            vsyncAcctInputParam.proc_debugmsg += 'IN searchAccountByUID::';
            System.debug('vsyncAcctInputParam.In_RCUserID: ' + vsyncAcctInputParam.In_RCUserID);
            List<Account> searchAccount = new List<Account>();
            List<Account> userIdsearchAccount = new List<Account>();
            List<Account> BTCUGsearchAccount = new List<Account>();

            if (!disableCugSync) {
                searchAccount = (List<Account>) [
                    SELECT Id, Name, Phone, RC_User_ID__c, Bt_Cug_Number__c
                    FROM Account
                    WHERE
                    (RC_User_ID__c != NULL AND RC_User_ID__c = :vsyncAcctInputParam.In_RCUserID)
                    OR
                    (Bt_Cug_Number__c != NULL AND Bt_Cug_Number__c = :vsyncAcctInputParam.In_CugNumber)
                ];
            } else {
                searchAccount = (List<Account>) [
                    SELECT Id, Name, Phone, RC_User_ID__c, Bt_Cug_Number__c
                    FROM Account
                    WHERE (RC_User_ID__c != NULL
                    AND RC_User_ID__c = :vsyncAcctInputParam.In_RCUserID)
                ];
            }


            for (Account acc : searchAccount) {
                if (acc.RC_User_ID__c != null && acc.RC_User_ID__c == vsyncAcctInputParam.In_RCUserID) {
                    userIdsearchAccount.add(acc);
                }

                if (acc.Bt_Cug_Number__c != null && acc.Bt_Cug_Number__c == vsyncAcctInputParam.In_CugNumber && !disableCugSync) {
                    BTCUGsearchAccount.add(acc);
                }
            }

            if (userIdsearchAccount.size() > 0) {
                vsyncAcctInputParam.proc_AccountId = searchAccount[0].Id;
                return true;
            } else {
                if (BTCUGsearchAccount.size() > 0 && !disableCugSync) {
                    vsyncAcctInputParam.proc_AccountId = searchAccount[0].Id;
                    return true;
                }

                return false;
            }
        } catch (Exception ex) {
            vsyncAcctInputParam.OutErrorMsg = 'searchAccountByUID:: ' + ex.getMessage();
            return false;
        }
        //return true;
    }

    public static Boolean searchContactandLeadByDealId(syncAcctInputParam vsyncAcctInputParam) {
        System.debug('*** Inside searchContactandLeadByDealId ***');
        System.debug('vsyncAcctInputParam.In_Partner_Deal_Registration_Id: ' + vsyncAcctInputParam.In_Partner_Deal_Registration_Id);
        try {
            String PartnerDealId = vsyncAcctInputParam.In_Partner_Deal_Registration_Id;
            Decimal decPartnerDealId = Decimal.valueOf(PartnerDealId);
            List<Contact> lstContact = [
                SELECT Id, AccountId
                FROM Contact
                WHERE PartnerDeal_Registration_ID__c = :decPartnerDealId AND AccountId != NULL
                ORDER BY CreatedDate DESC
                LIMIT 1
            ];
            if (lstContact != null && lstContact.size() > 0) {
                vsyncAcctInputParam.searchContact = lstContact;
                return true;
            } else {
                List<Lead> lstLead = [
                    SELECT Id
                    FROM Lead
                    WHERE PartnerDeal_Registration_ID__c = :decPartnerDealId AND IsConverted = FALSE
                    ORDER BY CreatedDate DESC
                    LIMIT 1
                ];
                if (lstLead != null && lstLead.size() > 0) {
                    vsyncAcctInputParam.searchlead = lstLead;
                    return true;
                }
            }
        } catch (Exception ex) {
            vsyncAcctInputParam.OutErrorMsg = 'searchContactandLeadByDealId:: ' + ex.getMessage();
            return false;
        }
        return false;
    }

    public static Boolean searchOppertunityByOID(syncAcctInputParam vsyncAcctInputParam) {
        try {
            vsyncAcctInputParam.proc_debugmsg += 'IN searchOppertunityByOID::';
            System.debug('vsyncAcctInputParam.In_OpportunityID: ' + vsyncAcctInputParam.In_OpportunityID);
            List<Opportunity> searchopportunity = [
                SELECT Name, AccountId, Id, StageName
                FROM Opportunity
                WHERE Id = :vsyncAcctInputParam.In_OpportunityID
                AND Account.RC_Sync_Status__c != 'In Sync'
                AND Account.RC_User_ID__c = NULL
                ORDER BY CreatedDate DESC
                LIMIT 1
            ];
            if (searchopportunity.size() > 0) {
                vsyncAcctInputParam.proc_AccountId = searchopportunity[0].AccountId;
            } else {
                return false;
            }

            return true;
        } catch (Exception ex) {
            vsyncAcctInputParam.OutErrorMsg = 'searchOppertunityByOID:: ' + ex.getMessage();
            return false;
        }
        //return true;
    }

    public static Boolean searchContactByMailAndBrand(syncAcctInputParam vsyncAcctInputParam) {
        try {
            vsyncAcctInputParam.proc_debugmsg += 'IN searchContactByMailAndBrand::';
            System.debug('vsyncAcctInputParam.In_ContactEmail: ' + vsyncAcctInputParam.In_ContactEmail);
            List<Contact> searchcontact = (List<Contact>) [
                SELECT Id, Name,Email, Phone, AccountId
                FROM Contact
                WHERE Email = :vsyncAcctInputParam.In_ContactEmail
                AND Account.RC_User_ID__c = NULL
                AND Account.RecordTypeId = :AccountHelper.RT_ID_CUSTOMER_ACCOUNT
                AND Account.RC_Brand__c = :vSyncAcctInputParam.In_RCBRAND
                ORDER BY CreatedDate DESC
            ];

            if (searchcontact.size() == 1) {
                vsyncAcctInputParam.proc_AccountId = searchcontact[0].AccountId;
                vsyncAcctInputParam.proc_ContactId = searchcontact[0].Id;
                return true;
            } else if (searchcontact.size() > 1) {
                for (Contact con : searchcontact) {
                    Id rcId = OpportunityHelper.getOppRecordTypeMap('Sales Opportunity');
                    List<Opportunity> opp = [SELECT Id FROM Opportunity WHERE Account.Id = :con.AccountId AND (RecordTypeId = :rcId OR RecordTypeId = NULL) ];
                    // List<Opportunity> opp = [Select Id from Opportunity where Account.id = :con.AccountId];
                    if (opp.size() > 0) {
                        vsyncAcctInputParam.proc_AccountId = con.AccountId;
                        vsyncAcctInputParam.proc_ContactId = con.Id;
                        return true;
                    }
                }
                /*If no account found having oppertunity then return with latest record. Do query and assign*/
                List<Contact> searchcontactLT = (List<Contact>) [SELECT Id, Name, Email, Phone, AccountId FROM Contact WHERE Email = :vsyncAcctInputParam.In_ContactEmail AND Account.RC_User_ID__c = NULL ORDER BY CreatedDate DESC LIMIT 1];
                if (searchcontactLT != null && searchcontactLT.size() != 0) {
                    vsyncAcctInputParam.proc_AccountId = searchcontactLT[0].AccountId;
                    vsyncAcctInputParam.proc_ContactId = searchcontactLT[0].Id;
                } else {
                    return false;
                }
                return true;

            } else {
                return false;
            }
        } catch (Exception ex) {
            vsyncAcctInputParam.OutErrorMsg = 'searchContactByMailAndBrand:: ' + ex.getMessage()+ex.getlinenumber();
            return false;
        }
        //return true;
    }

    public static Boolean searchLeadByEmail(syncAcctInputParam vsyncAcctInputParam) {
        try {
            vsyncAcctInputParam.proc_debugmsg += 'IN searchLeadByEmail::';
            System.debug('vsyncAcctInputParam.In_ContactEmail: ' + vsyncAcctInputParam.In_ContactEmail);
            vsyncAcctInputParam.searchlead =
                (List<Lead>) [
                    SELECT Id, Name, Email, Phone
                    FROM Lead
                    WHERE (LeadSource != 'About To Be Cancelled' AND LeadSource != 'About To Be Cancelled UK')
                    AND ((Phone != ''
                          AND Phone != NULL
                          AND Phone = :vsyncAcctInputParam.In_Contactphone)
                    OR (Email != ''
                        AND Email != NULL
                        AND Email = :vsyncAcctInputParam.In_ContactEmail))
                    AND (Status = '2. Contacted'
                    OR Status = '1.5 Call Out')
                    AND IsConverted = FALSE
                    ORDER BY Name DESC
                    LIMIT 1
                ];
            if (vsyncAcctInputParam.searchlead.size() > 0) {
                return true;
            } else {
                return false;
            }
        } catch (Exception ex) {
            vsyncAcctInputParam.OutErrorMsg = 'searchLeadByEmail:: ' + ex.getMessage();
            return false;
        }
        //turn true;
    }

    public static Boolean handleUpdateAccount(syncAcctInputParam vsyncAcctInputParam) {
        try {
            vsyncAcctInputParam.proc_debugmsg += 'IN handleUpdateAccount::';
            List<Account> AcctUpdate = new Account[] {
            };

            Account acc = new Account(
                Id = vsyncAcctInputParam.proc_AccountId,
                RC_Account_Number__c = vsyncAcctInputParam.In_RCPrimaryNumber,
                RC_User_ID__c = vsyncAcctInputParam.In_RCUserID,
                Name = vsyncAcctInputParam.In_Company,
                Training_Portal_Activation_Code__c= vsyncAcctInputParam.ATT_Opportunity_Id,
                ATT_SubAccount_Id__c = vsyncAcctInputParam.ATT_SubAccount_Id,
                Farming_Control_Group__c = vsyncAcctInputParam.ATT_Contract_Id,
                RC_Edition__c = vsyncAcctInputParam.ATT_Edition,
                Churn_Multiplier__c = vsyncAcctInputParam.ATT_Number_Of_Licenses,
                Employee_Size_History__c = vsyncAcctInputParam.ATT_Order_Submission_Date,
                I_am_a__c = vsyncAcctInputParam.ATT_Address,
                RC_Account_Status__c = '',
                SignupType__c = vsyncAcctInputParam.In_SignupType,
                RC_Brand__c = ((vsyncAcctInputParam.In_RCBRAND == null) ? '' : subStringStr(vsyncAcctInputParam.In_RCBRAND, 127)),
                RC_Brand_ID__c = vsyncAcctInputParam.In_RCBRANDID==null ?'' : vsyncAcctInputParam.In_RCBRANDID,
                SignupPlatform__c = vsyncAcctInputParam.In_SignupPlatform,
                RC_Service_name__c = ((vsyncAcctInputParam.In_SERVICENAME == null) ? '' : subStringStr(vsyncAcctInputParam.In_SERVICENAME, 127)),
                Bandwidth_Test_Id__c = vsyncAcctInputParam.In_Bandwidth_Test_Id,
                Bandwidth_MOS_Score__c = vsyncAcctInputParam.In_Bandwidth_MOS_Score,
                Bandwidth_Num_Sim_Calls__c = vsyncAcctInputParam.In_Bandwidth_Num_Sim_Calls,
                RC_Tier__c = ((vsyncAcctInputParam.In_TIERNAME == null) ? '' : subStringStr(vsyncAcctInputParam.In_TIERNAME, 127)),
                Bt_Cug_Number__c = vsyncAcctInputParam.In_CugNumber == null ? '' : vsyncAcctInputParam.In_CugNumber,
                Industry = vsyncAcctInputParam.In_Industry == null ? '' : subStringStr(vsyncAcctInputParam.In_Industry, 40)
                /*Attribute_Key_01__c = ((vsyncAcctInputParam.In_Attribute_Key_01 == null) ? '' : subStringStr(vsyncAcctInputParam.In_Attribute_Key_01, 240)),
                Attribute_Key_02__c = ((vsyncAcctInputParam.In_Attribute_Key_02 == null) ? '' : subStringStr(vsyncAcctInputParam.In_Attribute_Key_02, 240)),
                Attribute_Key_03__c = ((vsyncAcctInputParam.In_Attribute_Key_03 == null) ? '' : subStringStr(vsyncAcctInputParam.In_Attribute_Key_03, 240)),
                Attribute_Key_04__c = ((vsyncAcctInputParam.In_Attribute_Key_04 == null) ? '' : subStringStr(vsyncAcctInputParam.In_Attribute_Key_04, 240)),
                Attribute_Key_05__c = ((vsyncAcctInputParam.In_Attribute_Key_05 == null) ? '' : subStringStr(vsyncAcctInputParam.In_Attribute_Key_05, 240)),
                Attribute_Value_01__c = ((vsyncAcctInputParam.In_Attribute_Value_01 == null) ? '' : subStringStr(vsyncAcctInputParam.In_Attribute_Value_01, 240)),
                Attribute_Value_02__c = ((vsyncAcctInputParam.In_Attribute_Value_02 == null) ? '' : subStringStr(vsyncAcctInputParam.In_Attribute_Value_02, 240)),
                Attribute_Value_03__c = ((vsyncAcctInputParam.In_Attribute_Value_03 == null) ? '' : subStringStr(vsyncAcctInputParam.In_Attribute_Value_03, 240)),
                Attribute_Value_04__c = ((vsyncAcctInputParam.In_Attribute_Value_04 == null) ? '' : subStringStr(vsyncAcctInputParam.In_Attribute_Value_04, 240)),
                Attribute_Value_05__c = ((vsyncAcctInputParam.In_Attribute_Value_05 == null) ? '' : subStringStr(vsyncAcctInputParam.In_Attribute_Value_05, 240))*/
            );
            AcctUpdate.add(acc);
            upsert AcctUpdate;
            vsyncAcctInputParam.proc_AccountId = acc.Id;
            try {
                LogProcess(vsyncAcctInputParam, 'Upserting');
            } catch (Exception ex) {
                System.debug('Failed to Insert log: ' + ex.getMessage());
            }
            return true;
        } catch (Exception ex) {
            System.debug('Exception === ' + ex.getMessage() + ex.getStackTraceString());
            vsyncAcctInputParam.OutErrorMsg = 'handleUpdateAccount:: ' + ex.getMessage();
            return false;
        }
        //return true;
    }

    public static Boolean handleConverLead(syncAcctInputParam vsyncAcctInputParam) {
        try {
            vsyncAcctInputParam.proc_debugmsg += 'IN handleConverLead::';
            TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT();
            TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE();
            TriggerHandler.BY_PASS_CONTACT_ON_INSERT();
            TriggerHandler.BY_PASS_CONTACT_ON_UPDATE();
            TriggerHandler.BY_PASS_OPPORTUNITY_ON_INSERT();
            TriggerHandler.BY_PASS_OPPORTUNITY_ON_UPDATE();
            LeadStatusSelector leadStatusSelector = new LeadStatusSelector();
            List<LeadStatus> leadStatusList = leadStatusSelector.selectLeadStatusForConvert().executeQuery();
            LeadStatus convertStatus = leadStatusList.get(0);
            for (Lead l : vsyncAcctInputParam.searchlead) {
                vsyncAcctInputParam.proc_debugmsg += 'In handleConverLead::' + l.Id;
                Database.LeadConvert lc = new database.LeadConvert();
                lc.setLeadId(l.Id);
                lc.setConvertedStatus(convertStatus.MasterLabel);
                Database.LeadConvertResult lcr = Database.convertLead(lc);
                vsyncAcctInputParam.proc_AccountId = lcr.getAccountId();
                vsyncAcctInputParam.proc_ContactId = lcr.getContactId();
                TriggerHandler.RESET_VARIABLES();
                vsyncAcctInputParam.proc_debugmsg += 'In handleConverLead:: Account ID' + l.Id + lcr.getAccountId() + 'Conytact ID' + lcr.getContactId();
                return true;
            }
        } catch (Exception ex) {
            vsyncAcctInputParam.OutErrorMsg = 'handleConverLead:: ' + ex.getMessage();
            return false;
        }
        return true;
    }

    public static String subStringStr(String str, Integer len) {
        String result = str;
        if (str.length() > len) {
            result = str.substring(0, len);
        }
        return result;
    }

    public static Boolean handleCreateAccount(syncAcctInputParam vsyncAcctInputParam) {
        try {
            vsyncAcctInputParam.proc_debugmsg += 'IN handleCreateAccount::';
            Account a = new Account();
            a.Name = vsyncAcctInputParam.In_Company;
            a.RC_Account_Number__c = vsyncAcctInputParam.In_RCPrimaryNumber;
            a.RC_User_ID__c = vsyncAcctInputParam.In_RCUserID;
            a.RC_Brand__c = vsyncAcctInputParam.In_RCBRAND;
            a.RC_Brand_ID__c = vsyncAcctInputParam.In_RCBRANDID;
            a.Training_Portal_Activation_Code__c = vsyncAcctInputParam.ATT_Opportunity_Id;
            a.ATT_SubAccount_Id__c = vsyncAcctInputParam.ATT_SubAccount_Id;
            a.Farming_Control_Group__c = vsyncAcctInputParam.ATT_Contract_Id;
            a.RC_Edition__c = vsyncAcctInputParam.ATT_Edition;
            a.Churn_Multiplier__c = vsyncAcctInputParam.ATT_Number_Of_Licenses;
            a.Employee_Size_History__c = vsyncAcctInputParam.ATT_Order_Submission_Date;
            a.I_am_a__c = vsyncAcctInputParam.ATT_Address;
            a.RC_Account_Status__c = '';
            // a.RC_Account_Status__c= 'DWH Sync pending';
            a.OwnerId = HardcodedIdsMapper.getMatchedObjectId('005Hr00000CC1u9');
            a.SignupType__c = vsyncAcctInputParam.In_SignupType;
            a.SignupPlatform__c = vsyncAcctInputParam.In_SignupPlatform;

            /*Added to populate Service name & Tier*/
            a.RC_Service_name__c = ((vsyncAcctInputParam.In_SERVICENAME == null) ? '' : subStringStr(vsyncAcctInputParam.In_SERVICENAME, 127));
            a.RC_Tier__c = ((vsyncAcctInputParam.In_TIERNAME == null) ? '' : subStringStr(vsyncAcctInputParam.In_TIERNAME, 127));

            a.Bt_Cug_Number__c = vsyncAcctInputParam.In_CugNumber == null ? '' : vsyncAcctInputParam.In_CugNumber;
            a.Industry = vsyncAcctInputParam.In_Industry == null ? '' : subStringStr(vsyncAcctInputParam.In_Industry, 40);
            /*a.Attribute_Key_01__c = ((vsyncAcctInputParam.In_Attribute_Key_01 == null) ? '' : subStringStr(vsyncAcctInputParam.In_Attribute_Key_01, 240));
            a.Attribute_Key_02__c = ((vsyncAcctInputParam.In_Attribute_Key_02 == null) ? '' : subStringStr(vsyncAcctInputParam.In_Attribute_Key_02, 240));
            a.Attribute_Key_03__c = ((vsyncAcctInputParam.In_Attribute_Key_03 == null) ? '' : subStringStr(vsyncAcctInputParam.In_Attribute_Key_03, 240));
            a.Attribute_Key_04__c = ((vsyncAcctInputParam.In_Attribute_Key_04 == null) ? '' : subStringStr(vsyncAcctInputParam.In_Attribute_Key_04, 240));
            a.Attribute_Key_05__c = ((vsyncAcctInputParam.In_Attribute_Key_05 == null) ? '' : subStringStr(vsyncAcctInputParam.In_Attribute_Key_05, 240));
            a.Attribute_Value_01__c = ((vsyncAcctInputParam.In_Attribute_Value_01 == null) ? '' : subStringStr(vsyncAcctInputParam.In_Attribute_Value_01, 240));
            a.Attribute_Value_02__c = ((vsyncAcctInputParam.In_Attribute_Value_02 == null) ? '' : subStringStr(vsyncAcctInputParam.In_Attribute_Value_02, 240));
            a.Attribute_Value_03__c = ((vsyncAcctInputParam.In_Attribute_Value_03 == null) ? '' : subStringStr(vsyncAcctInputParam.In_Attribute_Value_03, 240));
            a.Attribute_Value_04__c = ((vsyncAcctInputParam.In_Attribute_Value_04 == null) ? '' : subStringStr(vsyncAcctInputParam.In_Attribute_Value_04, 240));
            a.Attribute_Value_05__c = ((vsyncAcctInputParam.In_Attribute_Value_05 == null) ? '' : subStringStr(vsyncAcctInputParam.In_Attribute_Value_05, 240));*/
            System.debug('@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@' + a.RC_Brand__c);
            insert a;
            vsyncAcctInputParam.proc_AccountId = a.Id;
            try {
                LogProcess(vsyncAcctInputParam, 'Inserting');
            } catch (Exception ex) {
                System.debug('Failed to Insert log: ' + ex.getMessage());
            }
            return true;
        } catch (Exception ex) {
            vsyncAcctInputParam.OutErrorMsg = 'handleCreateAccount:: ' + ex.getMessage();
            return false;
        }
        //return true;
    }

    public static Boolean handleCreateContact(syncAcctInputParam vsyncAcctInputParam) {
        try {
            String strGetIn_FirstName = vsyncAcctInputParam.In_FirstName;
            Integer result = strGetIn_FirstName.length();
            Integer resultUserNameLen = 0;
            if (result > 40) {
                strGetIn_FirstName = strGetIn_FirstName.substring(0, 40);
            }
            vsyncAcctInputParam.proc_debugmsg += 'IN handleCreateContact::';
            Contact c = new Contact();
            c.LastName = vsyncAcctInputParam.In_LastName;
            c.AccountId = vsyncAcctInputParam.proc_AccountId;
            c.FirstName = strGetIn_FirstName;
            c.CurrencyIsoCode = 'USD';
            resultUserNameLen = vsyncAcctInputParam.In_ContactEmail.length();
            if (resultUserNameLen > 80) {
                c.Email = vsyncAcctInputParam.In_ContactEmail.substring(resultUserNameLen - 80, resultUserNameLen);
            } else {
                c.Email = vsyncAcctInputParam.In_ContactEmail;
            }
            c.Company__c = vsyncAcctInputParam.In_Company;
            c.Phone = vsyncAcctInputParam.In_Contactphone;
            insert c;
            vsyncAcctInputParam.proc_ContactId = c.Id;
            return true;
        } catch (Exception ex) {
            vsyncAcctInputParam.OutErrorMsg = 'handleCreateContact:: ' + ex.getMessage();
            return false;
        }
        //return true;
    }

    public static Boolean accountMatchingContactEmail(syncAcctInputParam vsyncAcctInputParam) {
        try {
            vsyncAcctInputParam.proc_debugmsg += 'IN accountMatchingContactEmail::';
            List<Contact> matchacc = [
                SELECT Id
                FROM Contact
                WHERE AccountId = :vsyncAcctInputParam.proc_AccountId
                AND Email = :vsyncAcctInputParam.In_ContactEmail
            ];
            if (matchacc.size() > 0) {
                vsyncAcctInputParam.proc_ContactId = matchacc[0].Id;
                return true;
            } else {
                return false;
            }
        } catch (Exception ex) {
            vsyncAcctInputParam.OutErrorMsg = 'accountMatchingContactEmail:: ' + ex.getMessage();
        }
        return true;
    }

    public static Boolean contactHavingUserRecord(syncAcctInputParam vsyncAcctInputParam) {
        try {
            vsyncAcctInputParam.proc_debugmsg += 'IN contactHavingUserRecord::';

            Integer resultUserNameLen = 0;
            String proc_EmailWORCUSERID = vsyncAcctInputParam.In_ContactEmail;
            String proc_EmailWithRCUSERID = vsyncAcctInputParam.In_RCUserID + vsyncAcctInputParam.In_ContactEmail;

            resultUserNameLen = proc_EmailWithRCUSERID.length();
            proc_EmailWithRCUSERID = proc_EmailWithRCUSERID.replace('@', '.');
            if (resultUserNameLen > 70) {
                proc_EmailWithRCUSERID = proc_EmailWithRCUSERID.substring(0, 70);
            }
            proc_EmailWithRCUSERID = proc_EmailWithRCUSERID + '@rc.com';


            /**/

            /*Logic to get CONTACT ID*/
            List<User> objUser = new List<User>();
            List<Contact> objContact = [
                SELECT Id
                FROM Contact
                WHERE Account.RC_User_ID__c = :vsyncAcctInputParam.In_RCUserID
                AND Email = :vsyncAcctInputParam.In_ContactEmail
            ];
            if (objContact.size() > 0) {
                objUser = [
                    SELECT Id
                    FROM User
                    WHERE ContactId = :objContact[0].Id
                    AND ProfileId IN :PROFILE_IDS_OF_PORTAL_USERS
                    AND IsActive = TRUE
                    ORDER BY ProfileId ASC
                ];
                if (objUser.size() > 0) {
                    vsyncAcctInputParam.proc_UserId = objUser[0].Id;
                    return true;
                } else {
                    return false;
                }
            } else {
                return false;
            }
        } catch (Exception ex) {
            vsyncAcctInputParam.OutErrorMsg = 'contactHavingUserRecord:: ' + ex.getMessage();
        }
        return true;
    }

    public static Boolean handleCreateUser(syncAcctInputParam vsyncAcctInputParam) {
        vsyncAcctInputParam.proc_debugmsg += 'IN handleCreateUser::';
        vsyncAcctInputParam.proc_UserRecCreation = '-1';
        return true;
    }

    public static void handleReturn(syncAcctInputParam vsyncAcctInputParam) {
        vsyncAcctInputParam.proc_debugmsg += 'IN handleReturn::';
        vsyncAcctInputParam.Out_AccountID = vsyncAcctInputParam.proc_AccountId;
        vsyncAcctInputParam.Out_ContactID = vsyncAcctInputParam.proc_ContactId;
        vsyncAcctInputParam.Out_UserID = vsyncAcctInputParam.proc_UserId;
    }

    public static void LogProcess(syncAcctInputParam vsyncAcctInputParam, String action) {
        String accountName = vsyncAcctInputParam.In_Company;
        String accountId = vsyncAcctInputParam.Out_AccountID;
        if (accountId == null) {
            accountId = vsyncAcctInputParam.proc_AccountId;
        }
        String source = 'SyncBizAccountWS: ' + action + ' Account ' + accountId + '/' + accountName;
        String message = JSON.serializePretty(vsyncAcctInputParam);

        PlatformLog__c pl = PlatformLog.buildLog(source, null, null, null, message);

        insert pl;
    }

    public static Set<Id> getProfilesForPortalUsers() {
        RingCentralVariousSettings__c settings = RingCentralVariousSettings__c.getInstance();

        if (settings.Use_Community_Licenses_on_portal__c) {
            Set<Id> res = new Set<Id> {
                ProfileHelper.PROFILE_ID_CUSTOMER_PORTAL_USER,
                ProfileHelper.PROFILE_ID_CUSTOMER_COMMUNITY_LOGIN_USER_CUSTOM
            };
            String configLicences = settings.SitesAcceptedProfiles__c;

            if (String.isBlank(configLicences)) {
                return res;
            }

            for (String licenceId : configLicences.split(';')) {
                try {
                    res.add(licenceId.trim());
                } catch (Exception e) {
                    //ignore bad ids
                    continue;
                }
            }
            return res;

        } else {
            return new Set<Id> {
                ProfileHelper.PROFILE_ID_CUSTOMER_PORTAL_USER
            };
        }
    }

    public static Id getProfileForNewUser() {
        RingCentralVariousSettings__c settings = RingCentralVariousSettings__c.getInstance();

        Id userId;
        try {
            userId = settings.ProfileForNewPortalUser__c;
        } catch (Exception e) {
            userId = ProfileHelper.PROFILE_ID_CUSTOMER_PORTAL_USER;
        }
        return userId;
    }

    public static void updateCugNumber(syncAcctInputParam vsyncAcctInputParam) {
        if (vsyncAcctInputParam.In_CugNumber != null) {
            Account accToUpsert = new Account();
            accToUpsert.RC_User_ID__c = vsyncAcctInputParam.In_RCUserID;
            accToUpsert.Bt_Cug_Number__c = vsyncAcctInputParam.In_CugNumber;

            upsert accToUpsert RC_User_ID__c;
        }
    }
}