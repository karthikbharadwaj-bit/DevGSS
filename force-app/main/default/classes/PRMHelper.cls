public class PRMHelper {
    private static final String SEMICOLON_SEPARATOR = ';';
    private static final String COMMA_SEPARATOR = ',';

    public static final String RESELLER_TYPE_REGULAR_PARTNER = 'Regular Partner';
    public static final String RESELLER_TYPE_ISV_PARTNER = 'ISV Partner';

    public static final String PARTNER_TYPE_MASTER_AGENT = 'Master Agent';
    public static final String PARTNER_TYPE_ISV_PARTNER = 'ISV Partner';

    public static final String FRANCHISOR_LITERAL = 'Franchisor';
    public static final String NATIONAL_ACCOUNTS_LITERAL = 'National Accounts';

    public static final String PARTNER_STATUS_NEW = 'New';
    public static final String PARTNER_STATUS_DECLINED = 'Declined';
    public static final String PARTNER_SOURCE_DIRECT_SALES_REFERRAL = 'Direct Sales Referral';

    //added for JIRA - 6286 Bill On Behalf PRM/CRM start
    public static final String PARTNER_TYPE_AVAYA_BILL_ON_BHEALF = 'Avaya - Bill-on-Behalf';
    public static final String PARTNER_TYPE_ATOS_BILL_ON_BHEALF = 'Atos - Bill-on-Behalf';
    public static final String PARTNER_TYPE_ALE_BILL_ON_BHEALF = 'Alcatel-Lucent - Bill-on-Behalf';
    public static final String PARTNER_TYPE_BILL_ON_BHEALF = 'Bill-on-Behalf';
    //added for JIRA - 6286 Bill On Behalf PRM/CRM end
    //added for PRM - 55 Wholesale Reseller PRM/CRM start
    public static final String PARTNER_TYPE_AVAYA_WOLESALE_RESELLER = 'Avaya - Wholesale-Reseller';
    public static final String PARTNER_TYPE_ATOS_WOLESALE_RESELLER = 'Atos - Wholesale-Reseller';
    public static final String PARTNER_TYPE_ALE_WOLESALE_RESELLER = 'Alcatel-Lucent - Wholesale-Reseller';
    public static final String PARTNER_TYPE_WOLESALE_RESELLER = 'Wholesale-Reseller';
    //added for PRM - 55 Wholesale Reseller PRM/CRM end

    public static final Id RCPARTNER_USER_ID = HardcodedIdsMapper.getMatchedObjectId('005800000038AHjAAM');

    public static final String ACCOUNT_TYPE_PARTNER = 'Partner';

    public Account[] processFranchisorRequests(Partner_Request__c[] requests) {
        List<Partner_Request__c> franchisorRequests = new List<Partner_Request__c>();

        for(Partner_Request__c request : requests){
            if(request.Partner_Type__c == FRANCHISOR_LITERAL
                && request.Partner_Request_Source__c == NATIONAL_ACCOUNTS_LITERAL)
            {
                franchisorRequests.add(request);
            }
        }

        List<Account> accountByFranchiseRequest = new List<Account>();
        for(Partner_Request__c request : franchisorRequests) {
            Account a = createAccount(request, null);
            a.Partner_Source__c = NATIONAL_ACCOUNTS_LITERAL;
            a.Partner_Type__c = FRANCHISOR_LITERAL;
            accountByFranchiseRequest.add(a);
        }
        try {
            if(accountByFranchiseRequest.size() > 0) {
                insert accountByFranchiseRequest;
            }
        } catch (DMLException dmlex) {
            System.debug('PRMHelper.processFranchisorRequests got an DML exception ' + dmlex.getMessage() +
                '\n' + dmlex.getStackTraceString());
            return null;
        }

        List<Contact> conactsToAssignToAccounts = new List<Contact>();
        for(Partner_Request__c request : franchisorRequests) {
            Id accountId = accountByFranchiseRequest.size() > 0 ? accountByFranchiseRequest[0].Id : null;
            conactsToAssignToAccounts.add(createContact(accountId, request));
        }
        try {
            if(conactsToAssignToAccounts.size() > 0) {
                insert conactsToAssignToAccounts;
            }
        } catch (DMLException dmlex) {
            System.debug('PRMHelper.processFranchisorRequests got an DML exception ' + dmlex.getMessage() +
                '\n' + dmlex.getStackTraceString());
        }

        return accountByFranchiseRequest;
    }

    public Map<Id, Account> onInsertPRM(List<Partner_Request__c> triggerNewList) {
        Set<String> partnerCompanyName = new Set<String>();
        for(Partner_Request__c request: triggerNewList) {
            if (String.IsNotBlank(request.Partner_Company_Name__c)) {
                partnerCompanyName.add(request.Partner_Company_Name__c);
            }
        }

        Map<String, Account> existingPartnerAccount = new Map<String, Account>();
        for(Account acc : [
            SELECT  Id, Name, PartnerStatus__c, Partner_Type__c, Partner_Source__c,
                Referring_DSR__c, Partner_Sign_Up_Date__c, Other_TextField__c,
                OwnerId, BillingStreet, BillingCity, BillingState, BillingPostalCode,
                BillingCountry, Partner_ID__c,Parent_partner_account__c
            FROM Account
            WHERE (Account.Name IN :partnerCompanyName) AND Type = :ACCOUNT_TYPE_PARTNER])
        {
            existingPartnerAccount.put(acc.Name, acc);
        }

        /***************************************/
        /***************************************/
        Map<Id, Account> accountsToCreate = new Map<Id, Account>();
        List<Account> accountsToUpsert = new List<Account>();
         //PRM 249
        Map<Id, Account> accountsToUpsertMap = new Map<Id, Account>();
        Integer intAccExist = 0;
        for(Partner_Request__c request: triggerNewList) {
            try {
                if(!existingPartnerAccount.containsKey(request.Partner_Company_Name__c)) {
                    Account a = createAccount(request, null);
                    a.Referring_DSR__c = request.DSR_USER__c;
                    a.Partner_Classification__c = request.Partner_Classification__c; // Added for Mitel for PRM-145

                    if (String.isNotBlank(request.DSR_USER__c)) {
                        a.Partner_Source__c = PARTNER_SOURCE_DIRECT_SALES_REFERRAL;
                    }
                    else {
                        a.Partner_Source__c = request.Partner_Request_Source__c;
                    }
                    if(request.Brand_Name__c == 'RingCentral') {
                        //pbc-10146
                        if(request.Direct_Partner__c == true) {
                            a.Partner_Source__c = 'General Partner';
                        } else {
                            a.Partner_Source__c = 'Distributor';
                        }
                    }
                    if(request.Partner_Type__c!=null && request.Partner_Type__c!=PARTNER_TYPE_BILL_ON_BHEALF && request.Partner_Type__c != PARTNER_TYPE_WOLESALE_RESELLER && request.Partner_Type__c != PARTNER_TYPE_AVAYA_WOLESALE_RESELLER && request.Partner_Type__c != PARTNER_TYPE_ATOS_WOLESALE_RESELLER &&  request.Partner_Type__c != PARTNER_TYPE_ALE_WOLESALE_RESELLER){
                        if (request.Reseller_Partner_Type__c == RESELLER_TYPE_REGULAR_PARTNER
                            || request.Partner_Type__c == PARTNER_TYPE_MASTER_AGENT)
                        {
                            a.Partner_Type__c = PARTNER_TYPE_MASTER_AGENT;
                        }
                        else if (request.Reseller_Partner_Type__c == RESELLER_TYPE_ISV_PARTNER
                            || request.Partner_Type__c == RESELLER_TYPE_ISV_PARTNER) {
                            a.Partner_Type__c = RESELLER_TYPE_ISV_PARTNER;
                        }
                        else {
                            a.Partner_Type__c = request.Partner_Type__c;
                        }
         			}
                    else{
                    	a.Partner_Type__c = request.Partner_Type__c;
                  	}
                    accountsToCreate.put(request.Id, a);
                }
                else {
                    intAccExist = 1;
                    //TO-DO Its looks like an error, because we will update ALL found
                    //accounts, not only with matching names
                    for(Account existingAccount : existingPartnerAccount.values()) {
                        if (existingAccount.PartnerStatus__c == PARTNER_STATUS_DECLINED) {
                            Account newAccount = createAccount(request, existingAccount.Id);
                            newAccount.Partner_Source__c = request.Partner_Request_Source__c;
                            if(request.Brand_Name__c == 'RingCentral') {
                                //pbc-10146
                                if(request.Direct_Partner__c == true) {
                                    newAccount.Partner_Source__c = 'General Partner';
                                } else {
                                    newAccount.Partner_Source__c = 'Distributor';
                                }
                            }
                            if (existingAccount.Partner_ID__c != null) {
                                newAccount.Partner_ID__c = existingAccount.Partner_ID__c;
                            }
                            newAccount.Other_TextField__c = existingAccount.Other_TextField__c;
                            newAccount.OwnerId = existingAccount.OwnerId;
                            newAccount.BillingStreet = existingAccount.BillingStreet;
                            newAccount.BillingCity = existingAccount.BillingCity;
                            newAccount.BillingState = existingAccount.BillingState;
                            newAccount.BillingPostalCode =  existingAccount.BillingPostalCode;
                            newAccount.BillingCountry = existingAccount.BillingCountry;
                            if (existingAccount.Partner_Sign_Up_Date__c != null) {
                                newAccount.Partner_Sign_Up_Date__c = existingAccount.Partner_Sign_Up_Date__c;
                            }
                            accountsToUpsert.add(newAccount);
                        }
                    }
                }
            }
            catch(Exception ex) {
                System.debug('EXCEPTION WAS THROWN: ' + ex);
                sendEmailAboutFailure(request, ex);
            }
        }

        accountsToUpsert.addAll(accountsToCreate.values());

        //PRM 249

        if (accountsToUpsert.size() > 0){
            upsert accountsToUpsert;
        }

        //TO-DO Another erroneous cycle:
        //1. For each partner request we will create a contact bounded to FIRST added to list Account.
        //2. intAccExist variable in cycle has ambigious meaning
        List<Contact> contactsToCreate = new List<Contact>();

        //Added for JIRA - 6286 Bill On Behalf PRM/CRM start
        List<Contact> BOBContactList = new List<Contact>();
        List<AccountContactRole> objAcctContactRolesList = new List<AccountContactRole>();
        //Added for JIRA - 6286 Bill On Behalf PRM/CRM end

        for(Partner_Request__c request : triggerNewList){
            if (intAccExist == 0) {
                Id accountId = accountsToCreate.size() > 0 ? accountsToCreate.values()[0].Id : null;
                Contact c = createContact(accountId, request);

                //Added for JIRA - 6286 Bill On Behalf PRM/CRM start
                if(request.Partner_First_Name_Accounts_Payable__c != null && request.Partner_Last_Name_Accounts_Payable__c !=null && request.Partner_Phone_Accounts_Payable__c !=null && request.Partner_Email_Address_Accounts_Payable__c!=null){
                    BOBContactList = createContact2(accountId, request);

                    if(!BOBContactList.isEmpty() && BOBContactList.size() <= 2){

                        for(integer i = 1;i<=BOBContactList.size();i++){
                            AccountContactRole objAcctContactRoleAP = new AccountContactRole();
                            objAcctContactRoleAP.AccountId = accountId;
                            if(i==1){
                                objAcctContactRoleAP.Role = 'Accounts Payable';
                            }
                            else{
                                objAcctContactRoleAP.Role = 'Billing Support';
                            }

                            objAcctContactRolesList.add(objAcctContactRoleAP);
                        }

                    }
                }
                //Added for JIRA - 6286 Bill On Behalf PRM/CRM end
                contactsToCreate.add(c);
            }
        }
        if (contactsToCreate.size() > 0) {
            insert contactsToCreate;
        }

        //Added for JIRA - 6286 Bill On Behalf PRM/CRM start
        if(BOBContactList.size() > 0){
            insert BOBContactList;
            system.debug('Inserted contactsToCreateAccountsPayable >>>>>.: '+BOBContactList);
            if(objAcctContactRolesList.size()>0){
                for(integer i=0;i<BOBContactList.size();i++){
                    objAcctContactRolesList[i].ContactId = BOBContactList[i].Id;
                }
                insert objAcctContactRolesList;
            }
        }
        //Added for JIRA - 6286 Bill On Behalf PRM/CRM end

        //Naresh Kumar  03/03/2020  Sharing accounts
    Sharing_AccountLeadHandler.handleAccountShare(accountsToUpsert);
        return accountsToCreate;
    }

    public PartnerRequestDuplicateAccountSearcher.SearchResult findDuplicateAccounts(
        Partner_Request__c[] triggerNewList)
    {
        return PartnerRequestDuplicateAccountSearcher.findDuplicates(triggerNewList);
    }

    public void  onUpdatePRM (List<Partner_Request__c> triggerNewList){
        //Case 07991705 Urgent: System user changing Partner Status on accounts
        //https://rc.my.salesforce.com/50034000017MkTc
        if (UserInfo.getUserId() == RCPARTNER_USER_ID) {
            return;
        }

        Set<String> partnerId = new Set<String>();
        Set<String> partnerComapanyNameUpdate = new Set<String>();
        for(Partner_Request__c request : triggerNewList) {
            partnerId.add(request.Partner_ID__c );
            partnerComapanyNameUpdate.add(request.Partner_Company_Name__c);
        }

        List<Account> foundByNamePartnerAccounts = [
            SELECT  Id, Name, PartnerStatus__c, Partner_Type__c, Partner_Source__c, Partner_ID__c, Partner_Sign_Up_Date__c,
                Other_TextField__c, OwnerId, BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry
            FROM Account
            WHERE (Account.Partner_ID__c IN :partnerId OR Account.Name IN :partnerComapanyNameUpdate)
                AND Type = :ACCOUNT_TYPE_PARTNER
        ];
        Boolean hasFoundAccountByNameOnUpdate = foundByNamePartnerAccounts.size() > 0;

        List<Account> accountsToUpsert = new List<Account>();
        //PRM 249
         Map<Id, Account> accountsToUpsertMap1 = new Map<Id, Account>();
        Integer intAccExist = 0;
        for(Partner_Request__c request: triggerNewList) {
            for(Account existingAccount : foundByNamePartnerAccounts) {
                Account newAccount = createAccount(request, existingAccount.Id);

                if (existingAccount.Partner_Source__c != NATIONAL_ACCOUNTS_LITERAL) {
                    newAccount.Partner_Source__c = request.Partner_Request_Source__c;
                }
                if (String.isNotBlank(request.DSR_USER__c)) {
                    newAccount.Partner_Source__c = PARTNER_SOURCE_DIRECT_SALES_REFERRAL;
                } else {
                    newAccount.Partner_Source__c = request.Partner_Request_Source__c;
                }
                if(request.Brand_Name__c == 'RingCentral') {
                    //pbc-10146
                    if(request.Direct_Partner__c == true) {
                        newAccount.Partner_Source__c = 'General Partner';
                    } else {
                        newAccount.Partner_Source__c = 'Distributor';
                    }
                }
                if (existingAccount.Partner_Type__c != FRANCHISOR_LITERAL) {
                    newAccount.Partner_Type__c = request.Partner_Type__c;
                }

                if (existingAccount.Partner_ID__c != null) {
                    newAccount.Partner_ID__c = existingAccount.Partner_ID__c;
                }

                if (existingAccount.Partner_Sign_Up_Date__c != null) {
                    newAccount.Partner_Sign_Up_Date__c = existingAccount.Partner_Sign_Up_Date__c;
                }
                newAccount.Other_TextField__c = existingAccount.Other_TextField__c;
                newAccount.OwnerId = existingAccount.OwnerId;

                newAccount.BillingStreet = existingAccount.BillingStreet;
                newAccount.BillingCity = existingAccount.BillingCity;
                newAccount.BillingState = existingAccount.BillingState;
                newAccount.BillingPostalCode =  existingAccount.BillingPostalCode;
                newAccount.BillingCountry = existingAccount.BillingCountry;

                accountsToUpsert.add(newAccount);
            }
            if (foundByNamePartnerAccounts.size() == 0) {
                intAccExist = 1;
                Account a = createAccount(request, null);

                if (String.isNotBlank(request.DSR_USER__c)) {
                    a.Partner_Source__c = PARTNER_SOURCE_DIRECT_SALES_REFERRAL;
                } else {
                    a.Partner_Source__c = request.Partner_Request_Source__c;
                }
                if(request.Brand_Name__c == 'RingCentral') {
                    //pbc-10146
                    if(request.Direct_Partner__c == true) {
                        a.Partner_Source__c = 'General Partner';
                    } else {
                        a.Partner_Source__c = 'Distributor';
                    }
                }
                a.Referring_DSR__c = request.DSR_USER__c;
                a.Partner_Type__c = request.Partner_Type__c;

                accountsToUpsert.add(a);
            }
        }

         //PRM 249
                for (Account acc:accountsToUpsert){
                     accountsToUpsertMap1.put(acc.id,acc);
                }

            if (accountsToUpsertMap1.size() > 0){
                     upsert accountsToUpsertMap1.Values();
            }
        //PRM 249

        List<Contact> contactsToInsert = new List<Contact>();
        for(Partner_Request__c request : triggerNewList) {
            if(intAccExist == 1) {
                Id accountId = accountsToUpsert.size() > 0 ? accountsToUpsert[0].Id : null;
                contactsToInsert.add(createContact(accountId, request));
            }
        }
        if (contactsToInsert.size() > 0) {
            insert contactsToInsert;
        }
    }

    public void sendEmailNotificationAboutDuplicates(Partner_Request__c[] newRequests,
        Map<Id, Account> foundAccountsByName)
    {
        if (foundAccountsByName == null || foundAccountsByName.size() == 0) {
            System.debug('PRMHelper.sendEmailNotificationAboutDuplicates no duplicated accounts found');
            return;
        }

        String[] emailCcAddresses;
        String[] emailBccAddresses;
        String emailAddresses = PartnerRequestEmailSettings__c.getInstance().CC_Addresses__c;
        if (String.IsNotBlank(emailAddresses)) {
            emailCcAddresses = PRMHelper.parseStringWithSeparator(emailAddresses, SEMICOLON_SEPARATOR);
        }
        emailAddresses = PartnerRequestEmailSettings__c.getInstance().Bcc_Addresses__c;
        if (String.IsNotBlank(emailAddresses)) {
            emailBccAddresses = PRMHelper.parseStringWithSeparator(emailAddresses, SEMICOLON_SEPARATOR);
        }

        List<Messaging.SingleEmailMessage> emailsToSent = new List<Messaging.SingleEmailMessage>();
        for (Partner_Request__c request : newRequests) {
            if (String.IsNotBlank(request.FoundDuplicateAccountIds__c) == false) {
                continue;
            }

            Account[] cachedAccounts = getAccountsByIdsFromCache(foundAccountsByName,
                request.FoundDuplicateAccountIds__c);

            for (Account acc : cachedAccounts) {
                emailsToSent.add(createEmailMessageAboutDuplicateAccount(request, acc,
                    emailCcAddresses, emailBccAddresses));
            }
        }

        try {
            Messaging.sendEmail(emailsToSent);
        }
        catch(Exception ex) {
            ExceptionHelper.checkIsMassEmailException(ex);
        }
    }

     private Contact createContact(Id accId, Partner_Request__c request) {
        CommunityInfo comm = new CommunityInfo();
        Map<String,Community_Details__mdt> comDetailMap = new Map<String,Community_Details__mdt>();
        Community_Details__mdt comDetail = CommunityInfo.getCommunityDetails();
        //If network is null - While Data load
        if(null == comDetail){
            comDetailMap = CommunityInfo.getAllCommunityDetails();
            comDetail = comDetailMap.get(request.Brand_Name__c);
        }

        Contact cont = new Contact();
        cont.Firstname = request.Partner_First_Name__c;
        cont.Lastname = request.Partner_Last_Name__c;
        if (accId != null) {
            cont.AccountId = accId;
        }
        if(request.Avaya_Partnership_Reg__c){
            //Added for Avaya partner registrations - Girish
            cont.OwnerId = comDetail.Portal_Deal_Desk_User__c;
            cont.Avaya_Partnership_Contact__c = true;
            cont.Marketo_Sync_Disabled__c = true;
            cont.Partner_Portal_View__c = request.Partner_Portal_View__c;
        }

        cont.Phone = request.Partner_Phone__c;
        cont.MobilePhone = request.Partner_Mobile__c;
        cont.Email = request.Partner_Email_Address__c;
        cont.MailingpostalCode = request.Partner_Zip__c;
        cont.MailingCity = request.Partner_City__c;
        cont.MailingState = request.Partner_State__c;
        cont.MailingCountry = request.Partner_Country__c;
        cont.MailingStreet = request.Partner_Address1__c;
        cont.Title = request.Partner_Title__c;
        cont.Company__c = request.Partner_Company_Name__c;
        return cont;
    }

    //Added for JIRA - 6286 Bill On Behalf PRM/CRM start
    @TestVisible
  private List<Contact> createContact2(Id accId, Partner_Request__c request) {
        CommunityInfo comm = new CommunityInfo();
        Map<String,Community_Details__mdt> comDetailMap = new Map<String,Community_Details__mdt>();
        Community_Details__mdt comDetail = CommunityInfo.getCommunityDetails();
        //If network is null - While Data load
        if(null == comDetail){
            comDetailMap = CommunityInfo.getAllCommunityDetails();
            comDetail = comDetailMap.get(request.Brand_Name__c);
        }

        List<Contact> bobContList = new List<Contact>();
        Contact cont2 = new Contact();
        cont2.Firstname = request.Partner_First_Name_Accounts_Payable__c;
        cont2.Lastname = request.Partner_Last_Name_Accounts_Payable__c;
        cont2.Phone = request.Partner_Phone_Accounts_Payable__c;
        cont2.Email = request.Partner_Email_Address_Accounts_Payable__c;
        cont2.Business_Role__c = 'Accounts Payable';
        if (accId != null) {
            cont2.AccountId = accId;
        }
        if(request.Avaya_Partnership_Reg__c){
            cont2.OwnerId = comDetail.Portal_Deal_Desk_User__c;
            cont2.Avaya_Partnership_Contact__c = true;
            cont2.Marketo_Sync_Disabled__c = true;
            cont2.Partner_Portal_View__c = request.Partner_Portal_View__c;
        }
        cont2.MailingpostalCode = request.Partner_Zip__c;
        cont2.MailingCity = request.Partner_City__c;
        cont2.MailingState = request.Partner_State__c;
        cont2.MailingCountry = request.Partner_Country__c;
        cont2.MailingStreet = request.Partner_Address1__c;
        cont2.Title = request.Partner_Title__c;
        cont2.Company__c = request.Partner_Company_Name__c;
        bobContList.add(cont2);

        if(request.Partner_First_Name_Billing_Support__c!=null && request.Partner_Last_Name_Billing_Support__c!=null && request.Partner_Phone_Billing_Support__c!=null && request.Partner_Email_Address_Billing_Support__c !=null){
            Contact cont3 = new Contact();
            cont3.Firstname =  request.Partner_First_Name_Billing_Support__c;
            cont3.Lastname = request.Partner_Last_Name_Billing_Support__c;
            cont3.Phone = request.Partner_Phone_Billing_Support__c;
            cont3.Email = request.Partner_Email_Address_Billing_Support__c;
            cont3.Business_Role__c = 'Billing Support';
            if (accId != null) {
                cont3.AccountId = accId;
            }
            if(request.Avaya_Partnership_Reg__c){
                cont3.OwnerId = comDetail.Portal_Deal_Desk_User__c;
                cont3.Avaya_Partnership_Contact__c = true;
                cont3.Marketo_Sync_Disabled__c = true;
                cont3.Partner_Portal_View__c = request.Partner_Portal_View__c;
            }
            cont3.MailingpostalCode = request.Partner_Zip__c;
            cont3.MailingCity = request.Partner_City__c;
            cont3.MailingState = request.Partner_State__c;
            cont3.MailingCountry = request.Partner_Country__c;
            cont3.MailingStreet = request.Partner_Address1__c;
            cont3.Title = request.Partner_Title__c;
            cont3.Company__c = request.Partner_Company_Name__c;
            bobContList.add(cont3);
        }

        system.debug('Newly Populated cont2 for Accounts Payable>>>>>>>>>>>>>  '+cont2);
        return bobContList;

    }
    //Added for JIRA - 6286 Bill On Behalf PRM/CRM end

    private Account createAccount(Partner_Request__c request, Id baseAccountId) {

        Account acct = baseAccountId == null ? new Account() : new Account(Id = baseAccountId);
        acct.Partner_Currently_resell__c = request.Partner_Currently_resell__c;
        acct.Partner_Cisco_Reseller__c = request.Partner_Cisco_Reseller__c;
        acct.How_did_you_hear_about_the_RC_Part_Prog__c = request.How_did_you_hear_about_the_RC_Part_Prog__c;
        acct.Partner_Average_Customer_Size__c = request.Partner_Average_Customer_Size__c;
        acct.Partner_Additional_Information__c = request.Partner_Additional_Information__c;
        acct.PartnerStatus__c = PARTNER_STATUS_NEW;

        if (String.IsNotBlank(request.Partner_Company_Name__c)) {
            acct.Name = request.Partner_Company_Name__c;
        } else {
            acct.Name = 'No name from PRM';
        }

        acct.Notes__c = request.Notes__c;
        acct.Partner_Country__c = request.Partner_Country__c;
        acct.Partner_State__c = request.Partner_State__c;
        acct.Partner_Address1__c = request.Partner_Address1__c;
        acct.Partner_Address2__c = request.Partner_Address2__c;
        acct.Partner_City__c = request.Partner_City__c;
        acct.Partner_Zip__c = request.Partner_Zip__c;
        acct.Partner_Company_Name__c = request.Partner_Company_Name__c;
        acct.Partner_ID__c = request.Partner_ID__c;
        acct.Phone = request.Partner_Phone__c;
        acct.Other_TextField__c = request.Partner_Email_Address__c;
        acct.Partner_Description_of_Your_Business__c = request.Partner_Description_of_Your_Business__c;
          //For PRM 80 Start
        acct.Reseller_Requests__c = request.id;
        //For PBC 10653
            if(!request.Avaya_Partnership_Reg__c){
                acct.OwnerID = RCPARTNER_USER_ID;
            }else{
                CommunityInfo comm = new CommunityInfo();
                Map<String,Community_Details__mdt> comDetailMap = new Map<String,Community_Details__mdt>();
                Community_Details__mdt comDetail = CommunityInfo.getCommunityDetails();
                //If network is null - While Data load
                if(null == comDetail){
                    comDetailMap = CommunityInfo.getAllCommunityDetails();
                    comDetail = comDetailMap.get(request.Brand_Name__c);
                }

                acct.OwnerID =  comDetail.Portal_Deal_Desk_User__c;

                Contact MasterAgent;
                if(request.Master_Partner_Contact__c != null) {
                    MasterAgent = Sharing_AccountLeadHandler.getContactAccount(request.Master_Partner_Contact__c);
                }

                if(request.AD__c == 'Yes' && request.Partner_Role__c == 'General Partner' && MasterAgent != null){
                    acct.Partner_Account__c = MasterAgent.AccountId;
                    if(MasterAgent.Account != null) {
                    acct.Parent_Partner_Account__c = MasterAgent.Account.Partner_Account__c;
                    }
                    else {
                        acct.Parent_Partner_Account__c = isRunningTestForAvayaPartner(comDetail) ? PartnerRecordsUtil.avayaMasterAccount.Id : comDetail.Portal_Top_Master_Account_Id__c;
                    }
                }else{
                    if (isRunningTestForAvayaPartner(comDetail)) {
                        acct.Partner_Account__c = PartnerRecordsUtil.avayaMasterAccount.Id;
                        acct.Parent_Partner_Account__c = PartnerRecordsUtil.avayaMasterAccount.Id;
                    } else {
                        acct.Partner_Account__c = comDetail.Portal_Top_Master_Account_Id__c;
                        acct.Parent_Partner_Account__c = comDetail.Portal_Top_Master_Account_Id__c;
                    }
                }

                acct.Avaya_Partnership_Account__c = true;
                if(comDetail.Brand_Name__c.contains('RingCentral')&&(comDetail.MasterLabel=='ignite')){
                     acct.RC_Brand__c = 'RingCentral';
                }
                else{
                    acct.VAR_Territory__c = comDetail.VAR_Territory__c;
                    acct.RC_Brand__c = comDetail.Brand_Name__c;
                }
                acct.Partner_Hierarchy_Level__c = comDetail.Portal_Partner_Hierarchy__c;
                acct.Partner_Source__c=comDetail.Portal_Partner_Source__c;
                acct.Permitted_Brands__c = comDetail.Brands_Permitted_To_Sell__c;
                acct.Partner_Role__c = request.Partner_Role__c;
                //Added condition for PBC-10852
                if(request.Brand_Name__c != 'RingCentral'){
                    acct.Website = request.Partner_Website__c;
                }
                if(request.Brand_Name__c == 'RingCentral') {
                    //pbc-10146

                    acct.Partner_Role__c = 'General Partner';
                    acct.Direct_Partner__c = request.Direct_Partner__c;

                    switch on request.Partner_Country__c {
                        when 'United States','Canada','Puerto Rico' {
                            acct.Permitted_Brands__c = 'RingCentral;RingCentral Canada';
                        }
                        when 'United Kingdom' {
                            acct.Permitted_Brands__c = 'RingCentral UK';
                        }
                        when 'Australia' {
                            acct.Permitted_Brands__c = 'RingCentral AU';
                        }
                        when 'Austria','Belgium','Bulgaria','Croatia','Czech Republic','Denmark','Estonia',
                        'Finland','France','Germany','Greece','Hungary','Ireland','Italy','Latvia','Lithuania',
                        'Luxembourg','Malta','Netherlands','Norway','Poland','Republic of Cyprus','Romania',
                        'Singapore','Slovakia','Slovenia','Spain','Switzerland' {
                            acct.Permitted_Brands__c = 'RingCentral EU';
                        }
                    }

                    String partnerEmail = request.Partner_Email_Address__c;
                    if(partnerEmail != null) {
                        acct.Website = partnerEmail.substringAfterLast('@');
                    }
                }
                acct.Master_Agent_Channel_Manager__c = request.Master_Agent_Channel_Manager__c;
            }
        // added for JIRA - 6286 Bill On Behalf PRM/CRM start
            acct.Partner_Type__c = request.Partner_Type__c;

            if(request.Partner_Type__c !=null){
                Boolean isPartnerTypeBOB = request.Partner_Type__c == PARTNER_TYPE_AVAYA_BILL_ON_BHEALF || request.Partner_Type__c == PARTNER_TYPE_ATOS_BILL_ON_BHEALF || request.Partner_Type__c == PARTNER_TYPE_ALE_BILL_ON_BHEALF || request.Partner_Type__c == PARTNER_TYPE_BILL_ON_BHEALF;
                Boolean isPartnerTypeWholesaleReseller = request.Partner_Type__c == PARTNER_TYPE_AVAYA_WOLESALE_RESELLER || request.Partner_Type__c == PARTNER_TYPE_ATOS_WOLESALE_RESELLER || request.Partner_Type__c == PARTNER_TYPE_ALE_WOLESALE_RESELLER || request.Partner_Type__c == PARTNER_TYPE_WOLESALE_RESELLER;
                if(request.Partner_Type__c == PARTNER_TYPE_AVAYA_BILL_ON_BHEALF || request.Partner_Type__c == PARTNER_TYPE_ATOS_BILL_ON_BHEALF || request.Partner_Type__c == PARTNER_TYPE_ALE_BILL_ON_BHEALF || request.Partner_Type__c == PARTNER_TYPE_BILL_ON_BHEALF || isPartnerTypeWholesaleReseller){
                    System.debug(':::::inside partner type::::');
                    if(!request.Avaya_Partnership_Reg__c){
                        acct.Partner_Hierarchy_Level__c = 'Reseller';
                    }
                    if (String.IsNotBlank(request.BusinessIdentity__c)) {
                        acct.BusinessIdentity__c = request.BusinessIdentity__c;
                    }
                    if (String.IsNotBlank(request.Invoice_Copy_Partner_ID__c)) {
                        acct.Invoice_Copy_Partner_ID__c = request.Invoice_Copy_Partner_ID__c;
                    }
                    if(String.IsNotBlank(request.Partner_ID__c)){
                        acct.Invoicing_Partner_ID__c = request.Partner_ID__c;
                    }
                    //acct.Settlement_type__c='Commission'; // commenting temporarily to change the data type of Settlement_type__c
                    if (isPartnerTypeBOB) {
                        acct.Settlement_type__c='Commission';
                        //PBC-9615 START
                        acct.Partner_Requires_Billing_feed__c = request.Partner_Requires_Billing_feed__c;
                        //PBC-9615 END
                    }
                     // Added for PRM - 55 Wholesale Reseller PRM/CRM start
                     else if (isPartnerTypeWholesaleReseller){
                        acct.Settlement_Type__c = request.Settlement_Type__c;
                        acct.Partner_Requires_Billing_feed__c = request.Partner_Requires_Billing_feed__c;
                        acct.Settlement_Rate_Partner_ID__c = request.Settlement_Rate_Partner_ID__c;
                        acct.Partner_Tax_Exemptions__c = request.Partner_Tax_Exemptions__c;
                        if (request.Partner_Requires_Billing_feed__c == 'Yes') {
                            acct.Billing_Feed_Type__c = request.Billing_Feed_Type__c;
                        }
                    }
                    // Added for PRM - 55 Wholesale Reseller PRM/CRM end
                } else {
                    String defaultBI = '';
                    for (CountryBusinessIdentityMapping__c countryBI : CountryBusinessIdentityMapping__c.getAll().values()) {
                        System.debug('country BI Mapping ' +countryBI);
                        if (countryBI.Brand_Name__c.equalsIgnoreCase(request.Brand_Name__c)) {
                            if(countryBI.Country__c.equalsIgnoreCase(request.Partner_Country__c)) {
                                acct.BusinessIdentity__c = countryBI.Business_Identity__c;
                                break;
                            }
                            if (countryBI.Country__c.equalsIgnoreCase('United States')) {
                                defaultBI = countryBI.Business_Identity__c;
                            }
                        }
                    }
                    if (acct.BusinessIdentity__c == null || acct.BusinessIdentity__c == '') {
                        acct.BusinessIdentity__c = defaultBI;
                    }
                }
            }
            // added for JIRA - 6286 Bill On Behalf PRM/CRM end


        acct.Type = ACCOUNT_TYPE_PARTNER;
        acct.Partner_Sign_Up_Date__c = Date.today();

        acct.Signup_Link__c = 'http://www.ringcentral.com/partner_signup.html?cid=reseller&partnerid=' +
            request.Partner_ID__c;
        acct.Co_Branded_Funnel_Link__c = 'https://secure.ringcentral.com/partners/signup?partnerid=' +
            request.Partner_ID__c;

        acct.BillingStreet = request.Partner_Address1__c;
        acct.BillingCity = request.Partner_City__c;
        acct.BillingState = request.Partner_State__c;
        acct.BillingPostalCode =  request.Partner_Zip__c;
        acct.BillingCountry = request.Partner_Country__c;

        acct.Sales_Model__c = request.Sales_Model__c ;
        acct.External_SID__c = request.External_SID__c;
        acct.Which_verticals_do_you_sell_to_most__c = request.Which_verticals_do_you_sell_to_most__c;
        acct.Partner_Currently_Resell_Other__c = request.Partner_Currently_Resell_Other__c;
        acct.Customer_ready_to_place_an_order_now__c = request.Customer_ready_to_place_an_order_now__c;
        acct.How_d_you_like_us_to_follow_up_with_you__c = request.How_d_you_like_us_to_follow_up_with_you__c;
        acct.Partner_Best_Contact_Time__c = request.Partner_Best_Contact_Time__c;
        acct.Closest_Metro_Area__c = request.Closest_Metro_Area__c;
        acct.Certifications__c = request.Certifications__c;
        acct.Certifications_Other__c = request.Certifications_Other__c;
        acct.Contact_FName__c = request.Partner_First_Name__c;
        acct.Contact_LName__c = request.Partner_Last_Name__c;
        acct.Contact_Email__c = request.Partner_Email_Address__c;
        acct.Contact_Phone__c = request.Partner_Phone__c;
        acct.No_of_Employees__c = request.No_of_Employees__c;
        acct.Dist_Dealer__c = request.AFN__c;
        acct.Master_Distributor_Agent__c = 'Yes'.equalsIgnoreCase(request.AD__c);
        acct.Company_size_typically_sell_to__c = request.Company_size_typically_sell_to__c;
        acct.Annual_Gross_Revenue__c = request.Annual_Gross_Revenue__c;
        return acct;
    }

    public void storeInfoAboutDuplicatesInRequests(Partner_Request__c[] triggerObjs,
        Map<Partner_Request__c, Set<Id>> foundDuplicatesByRequest)
    {
        if (foundDuplicatesByRequest == null || foundDuplicatesByRequest.size() == 0) {
            return;
        }

        for (Partner_Request__c entry : triggerObjs) {
            if (foundDuplicatesByRequest.containsKey(entry)) {
                entry.FoundDuplicateAccountIds__c = String.join(new List<Id>(foundDuplicatesByRequest.get(entry)),
                    COMMA_SEPARATOR);
            }
        }
    }

    public void storeInfoAboutDuplicatesInAccounts(Map<Partner_Request__c, Set<Id>> duplicatesByRequest) {
        for (Partner_Request__c entry : duplicatesByRequest.keyset()) {
            // Condition added inside for-loop to avoid 'Null Pointer Exception' -
            if(duplicatesByRequest.containsKey(entry)) {
                storeInfoAboutDuplicatesInAccounts(duplicatesByRequest.get(entry));
            }
        }
    }

    private void storeInfoAboutDuplicatesInAccounts(Set<Id> foundDuplicatedAccounts) {
        if (foundDuplicatedAccounts.size() < 2)  {
            return;
        }

        Id[] accountIdsArray = new List<Id>(foundDuplicatedAccounts);
        List<Id[]> idsToStore = new List<Id[]>();
        idsToStore.add(accountIdsArray);

        //Imagine, that we found 3 duplicates in Accounts with folloiwng Ids: #1, #2, #3
        //We need to update Account's #1 field FoundDuplicateAccountIds__c with the value #2;#3
        //And Account's #2 field FoundDuplicateAccountIds__c with the value #1;#3 and so on.
        //To achive this, I will use circle array shift algorithm to get N arrays,
        //where N - is count of found Accounts.
        //In this arrays, first element will contains Id of an Account to update and
        //all following elements will be stored in the FoundDuplicateAccountIds__c field.
        //So result will look like this: [[#1,#2,#3], [#2,#3,#1],[#3,#1,#2]]
        Integer arrayLength = accountIdsArray.size();
        Integer arrayFirstElementIdx = 1;

        for(Integer step = 1; step < arrayLength; step++) {
            Id[] ids = new Id[arrayLength];
            Integer elementIdx = arrayFirstElementIdx;
            for (Integer virtualIdx = 0; virtualIdx < arrayLength; virtualIdx++) {
                ids[virtualIdx] = accountIdsArray[elementIdx];
                elementIdx++;
                if (elementIdx >= arrayLength) {
                    elementIdx = 0;
                }
            }
            idsToStore.add(ids);
            arrayFirstElementIdx++;
        }

        //TO-DO simplify this cycle and just write data to storage, yopta
        List<Account> accToUpdate = new List<Account>();
        for (Integer i = 0; i < idsToStore.size(); i++) {
            Account a = new Account(Id = idsToStore[i][0]);
            a.FoundDuplicateAccountIds__c = String.join(idsToStore[i], COMMA_SEPARATOR);
            accToUpdate.add(a);
        }

        TriggerHandler.BY_PASS_ACCOUNT_ON_BEFORE = true;
        TriggerHandler.BY_PASS_ACCOUNT_ON_AFTER = true;
        update accToUpdate;
    }

    private Account[] getAccountsByIdsFromCache(Map<Id, Account> accStore, String ids) {
        String[] accountIds = PRMHelper.parseStringWithSeparator(ids, PRMHelper.COMMA_SEPARATOR);
        List<Account> result = new List<Account>();
        for (String idAsString : accountIds) {
            Id accountId = null;
            try {
                accountId = Id.valueOf(idAsString);
            } catch (Exception e) {
                System.debug('PRMHelper.getAccountsByIds Could not cast String to Id: ' + e.getMessage() + '\n' +
                    e.getStackTraceString());
                continue;
            }
            if (accStore.containsKey(accountId)) {
                result.add(accStore.get(accountId));
            }
        }
        return result;
    }

    private Messaging.SingleEmailMessage createEmailMessageAboutDuplicateAccount(Partner_Request__c request, Account dupAccount,
        String[] ccAddresses, String[] bccAddresses) {
        String bodyTemplate = 'Account with following company name is already with us<br/><br/>' +
            'Account with Company Name: <a href="{0}" target="_blank">{1}</a><br/><br/>' +
            'Duplicate Reseller Request Name: <a href="{2}" target="_blank">{3} {4}</a>';

        Messaging.SingleEmailMessage result = new Messaging.SingleEmailMessage();
        result.setToAddresses(new String[] { UserRC.rcsfSyncUserObj.Email__c } );
        if (ccAddresses != null && ccAddresses.size() > 0) {
            result.setCcAddresses(ccAddresses);
        }
        if (bccAddresses != null && bccAddresses.size() > 0) {
            result.setBccAddresses(bccAddresses);
        }

        result.setSenderDisplayName('Partner Request Form');
        result.setSubject('Partner Request - Duplicate Record');

        String[] templateParameters = new String[]
        {
            URL.getOrgDomainUrl().toExternalForm() + '/' + dupAccount.Id,
            dupAccount.Name.escapeHtml4(),
            URL.getOrgDomainUrl().toExternalForm() + '/' + request.Id,
            request.Partner_First_Name__c.escapeHtml4(),
            request.Partner_Last_Name__c.escapeHtml4()
        };

        result.setHtmlBody(String.format(bodyTemplate, templateParameters));

        return result;
    }

    @TestVisible
    private void sendEmailAboutFailure(Partner_Request__c request, Exception ex) {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        String[] toAddresses = new String[] { UserRC.rcsfSyncUserObj.Email__c };
        mail.setToAddresses(toAddresses);
        mail.setSenderDisplayName('Partner Request Form');
        mail.setSubject('Partner Request - Account was not created');

        mail.setPlainTextBody('Account for following Partner Request has been not created due to some invalid ' +
            'data provided by user.\n\n' +
            'Partner Company Name: ' + request.Partner_Company_Name__c + '  ' + '\n\n' +
            'To view the details of this Partner Request in SFDC click on the following link: ' +
            'https://' + System.Url.getOrgDomainUrl().getHost() + '/'+ request.Id + '\n\n' +
            'Technical information about failure: ' + ex.getMessage() + '\n' + ex.getStackTraceString());

        try {
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        }
        catch(Exception mailException) {
            ExceptionHelper.checkIsMassEmailException(mailException);
        }
    }

    private static String[] parseStringWithSeparator(String value, String separator) {
        return (value.contains(separator) ? value.split(separator) : new String[] { value });
    }

    private static Boolean isRunningTestForAvayaPartner(Community_Details__mdt comDetail) {
        return Test.isRunningTest() && comDetail.MasterLabel == 'partner' && comDetail.Brand_Name__c == 'Avaya Cloud Office';
    }
}