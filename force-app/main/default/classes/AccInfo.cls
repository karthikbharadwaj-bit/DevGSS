/****************************************************************************************************************
Updated By: eugenebasianomutya and levyudkin
Update details: Case # 03523403 - highlight on the account when a "Customer Success Manager" is flagged on the account
                Case # 03531598 - Account Highlights for First Group Accounts
                Case # 03650782 - Update Account Highlights
                Case # 04387410 - Franchise Accounts Tagging on SalesForce
                Case # 09178146 - Account Highlights for Fujitsu Accounts
*****************************************************************************************************************/

public class AccInfo {

    static final String strBTBrand = 'BT';
    static final String strBTCloudWork = 'Work';
    static final String strBTEnterprise = 'Enterprise';
    static final String strOfficeHand = 'OFFICE@HAND';
    static final String strATT = 'AT&T';
    static final String firstGroupAmerica = 'first group america';

    static final String BRAND_RINGCENTRAL = 'RingCentral';
    static final String strFujitsuBrand = 'Fujitsu - House Account';

    public static String RT_NAME_PARTNER_ACCOUNT = 'Partner Account';

    public String imgPath {get; set;}
    public String msg {get; set;}
    public String salsAgreeDate {get; set;}
    public String salsAgreeId {get; set;}
    public String salsAgreeName {get; set;}
    public List<String> tempList {get; set;}
    public List<StepUpWrapper> stepUps {get; set;}
    public Map<String, AccHighlighterWrapper> mapAccHighlighter;
    public String customerContactName {get; set;}
    public String RcExecutiveName {get; set;}
    public Boolean isBTApproved {get; set;}
    public Boolean isBTCloudWork {get; set;}
    public Boolean isBTEnterprise {get; set;}
    public Boolean isFujitsuBrand {get; set;}
    public Boolean isAccountMessage {get; set;}
    public Boolean isELBannerEmpty {get; set;}
    public Boolean isGPAAccount {get; set;}

    public Boolean warn1 {get; set;}
    public Boolean warnHighlighter {get; set;}
    public Boolean warn2 {get; set;}
    public Boolean warn3 {get; set;}
    public Boolean warn4 {get; set;}
    public Boolean warn5 {get; set;}
    public Boolean warn6 {get; set;}
    public Boolean warn7 {get; set;}
    public Boolean warn8 {get; set;}
    public Boolean warn9 {get; set;}
    public Boolean warn10 {get; set;}

    public Boolean isATT {get; set;}
    public Boolean isFirstGroupAcc {get; set;}
    public Boolean boolTrailAccountMsg {get; set;}
    public String strPaidDate {get; set;}
    public String strTAM {get; set;}
    public String strTAMId {get; set;}

    public String strCSM {get; set;}
    public String strCSMId {get; set;}

    public Boolean refreshBool {get; set;}
    public Boolean bRedAccount {get; set;}
    public String strRedAccountId {get; set;}
    public String strRedAccount {get;set;}
    public String ccdesk {get;set;}

    public boolean IsFlagshipAccount {get; set;}
    public boolean ProfServDevExists {get; set;}
    public boolean ProfServSalesOwnerExists {get; set;}

    public string ProfServDevName {get; set;}
    public string ProfServSalesOwnerName {get; set;}

    public Boolean IsInTransitionToRcDirect {get; set;}
    public Boolean IsInMigrationToAcquistionTier {get; set;}

    public EngageLegalWrapper completedEngageLegal {get; set;}

    public Boolean IsDuplicatedPartnerAccountFound {get; private set;}
    public Account[] DuplicatePartnerAccounts {get; private set;}

    private Account acct;
    private Boolean isNewBusinessAcc;

    public AccInfo(ApexPages.StandardController controller) {
        isBTApproved = false;
        isFujitsuBrand = false;
        isATT = false;
        isAccountMessage = false;
        warnHighlighter = false;
        isFirstGroupAcc = false;
        isGPAAccount = false;
        mapAccHighlighter = new Map<String, AccHighlighterWrapper>();
        acct = (Account) controller.getRecord();

        tempList = new List<String>();
        tempList.add('test');

        getDocument();

        ccdesk = Emails__c.getAll().get('ccdesk') != null ? Emails__c.getAll().get('ccdesk').Email_Address__c
                : 'Contact Center team';

        List<Account> lstAcc = [
            SELECT RC_User_ID__c, RC_Brand__c, Name, RC_Tier__c, Account_Highlights_Message__c,
                RC_Service_name__c, Acquisition_Tier__c, RC_Attribution_L2__c, GPA_Account__c,
                FoundDuplicateAccountIds__c, RecordType.Name, parent.name
            FROM Account
            WHERE Id = :acct.id
            LIMIT 1];

        String accUserId;

        if (lstAcc != null && lstAcc.size() > 0) {

            if (lstAcc.get(0).Account_Highlights_Message__c != null) {
                isAccountMessage = true;
            }

            if (lstAcc.get(0).GPA_Account__c) {
                isGPAAccount = true;
            }

            String rcBrand = lstAcc.get(0).RC_Brand__c;
            if (String.isNotBlank(rcBrand)) {
                isBTApproved = rcBrand.containsIgnoreCase(strBTBrand) ? true : false;
                isATT = rcBrand.containsIgnoreCase(strATT) ? true : false;
            }

            String rcTier = lstAcc.get(0).RC_Tier__c;
                if (String.isNotBlank(rcTier)) {
                    isBTCloudWork = rcTier.containsIgnoreCase(strBTCloudWork) ? true : false;
                    isBTEnterprise = rcTier.containsIgnoreCase(strBTEnterprise) ? true : false;
            }

            // 09178146 - Start
            String rcFujitsu = lstAcc.get(0).parent.name;
            if (String.isNotBlank(rcFujitsu)) {
                isFujitsuBrand = rcFujitsu.equalsIgnoreCase(strFujitsuBrand) ? true : false;
            }
            // 09178146 - End

            // 03650782 - Start
            string sAccName = lstAcc.get(0).Name;
            isFirstGroupAcc = sAccName.containsIgnoreCase(firstGroupAmerica) ? true : false;
            // 03650782 - End

            accUserId = lstAcc.get(0).RC_User_ID__c;
            isNewBusinessAcc = String.isBlank(accUserId);
        }

        isELBannerEmpty = true;
        for (Approval__c approval : [SELECT Id, Elasticity__c, Elasticity_Details__c, SLA__c, SLA_Contact_Center__c,
                                            SLA_Meetings_Only__c, SLA_GSS__c, SLA_Incident_Management__c
                                     FROM Approval__c
                                     WHERE Account__c = :acct.id AND RecordType.Name = 'Engage Legal'
                                     AND (Status__c = 'Completed' OR Status__c = 'Completed Audit')
                                     ORDER BY LastModifiedDate DESC
                                     LIMIT 1]) {
            // It is needed to use wrapper to workaround Object-Level Security
            completedEngageLegal = new EngageLegalWrapper(approval);

            // It is needed to use wrapper to workaround Object-Level Security
            stepUps = new List<StepUpWrapper>();
            for (Step_Up__c stepUp : [SELECT Name, Step_Up_DLs__c, Step_Up_Date__c
                                      FROM Step_Up__c
                                      WHERE Engage_Legal_Record__c = :approval.Id
                                      ORDER BY Step_Up_Date__c ASC]) {
                stepUps.add(new StepUpWrapper(stepUp.Name, stepUp.Step_Up_DLs__c, stepUp.Step_Up_Date__c));
            }

            isELBannerEmpty = String.isEmpty(approval.Elasticity__c) && String.isEmpty(approval.Elasticity_Details__c)
                    && String.isEmpty(approval.SLA__c) && String.isEmpty(approval.SLA_Contact_Center__c)
                    && String.isEmpty(approval.SLA_Meetings_Only__c) && String.isEmpty(approval.SLA_GSS__c)
                    && String.isEmpty(approval.SLA_Incident_Management__c) && stepUps.isEmpty();
        }

        AccHighlighterWrapper currWrap = mapAccHighlighter.get(accUserId);
        if (currWrap != null) {
            customerContactName = currWrap.custContactName;
            RcExecutiveName = currWrap.rcExecContactName;
            warnHighlighter = true;
        }

        boolTrailAccountMsg = false;
        ImgPath = '/resource/warning';

        for (Quote quote_obj: [SELECT id,Name,End_Date__c FROM Quote WHERE AccountId = :acct.id AND Status = 'Active' LIMIT 1]) {
            String dateStr = '';
            try {
                dateStr = '' + (quote_obj.End_Date__c == null ? '' : ('' + quote_obj.End_Date__c));
            } catch (Exception e) {}
            salsAgreeId = quote_obj.id;
            salsAgreeName = quote_obj.Name;
            salsAgreeDate = (dateStr == '' ? '' : dateStr.substring(0, dateStr.length() - 8));
            warn1 = true;
        }

        for (Account acc: [SELECT id, Name, RC_Account_Status__c, RC_Service_name__c FROM Account WHERE Id = :acct.id]) {
            if (!String.isBlank(acc.RC_Account_Status__c) && !String.isBlank(acc.RC_Service_name__c)
                && acc.RC_Account_Status__c.containsIgnoreCase('Trial')
                && acc.RC_Service_name__c.containsIgnoreCase('Office')) {
                warn4 = true;
            }
        }

        // 04079900 - Start
        for (Account acc: [SELECT id, Name, No_of_InContact_Seats__c FROM Account WHERE Id = :acct.id]) {
            warn8 = acc.No_of_InContact_Seats__c > 0 ? true : false;

            // Case # 03650782 - Start
            warn9 = acc.Name == 'Glip User' ? true : false;
            // Case # 03650782 - End

        }
        // 04079900 - End

        // Case # 04387410 - Franchise Accounts Tagging on SalesForce - Start
        // Add RC_Attribution_L2__c,  VAR_Territory__c in the query

        // Case: 04668955 BRD QuickWin P0: Critical Account Indicator for CSM - START
        // Change Status condition to !='Resolved' and !='Yellow' TO !='Resolved - Saved' and !='Resolved - Lost'
        for (Account acc: [SELECT Account.RC_Attribution_Channel__c, Partner_Type__c,ELA_Account_Type__c,
                                 RecordType.Name, RC_SignUp_date__c, Partner_ID__c, MRR__c, RC_Account_Status__c,
                                 RC_Attribution_L2__c, VAR_Territory__c, Type, Billing_ID__c,
                                 (SELECT id,Name,Status__c FROM Escalations__r
                                 WHERE Status__c != 'Resolved - Saved' AND Status__c != 'Resolved - Lost' AND Status__c != 'Resolved – Downgraded' AND Status__c != 'C360 created'
                                 ORDER BY LastModifiedDate DESC LIMIT 1)
                          FROM Account WHERE Id =:acct.id LIMIT 1]) {
            try {
                if (acc.Escalations__r.size() > 0) {
                    bRedAccount = true;
                    strRedAccountId = acc.Escalations__r.get(0).id;
                    strRedAccount = acc.Escalations__r.get(0).Name;
                }
            } catch (Exception e) {}

            /*************************** Case 05029010 - SFDC Account Highlights Error *************************************/

            // For Franchise Account
            if (acc.RecordType.Name == 'Partner Account' && acc.Partner_Type__c == 'Franchisor') {
                warn2 = true;
            }

            if (acc.RecordType.Name == 'Customer Account' && acc.Partner_ID__c != null &&
                    acc.VAR_Territory__c != null && acc.VAR_Territory__c.equalsIgnoreCase('Franchise') &&
                    acc.RC_Attribution_L2__c != null && acc.RC_Attribution_L2__c.equalsIgnoreCase('Franchise & Assoc.')) {
                warn2 = true;
            }

            // For Reseller Account
            if (acc.RecordType.Name == 'Partner Account' && acc.Partner_Type__c != 'Franchisor') {
                warn3 = true;
            }

            if (acc.RecordType.Name == 'Customer Account' && acc.Partner_ID__c != null &&
                    (acc.VAR_Territory__c == null || !acc.VAR_Territory__c.equalsIgnoreCase('Franchise')) &&
                    (acc.RC_Attribution_L2__c == null || !acc.RC_Attribution_L2__c.equalsIgnoreCase('Franchise & Assoc.'))) {
                warn3 = true;
            }

            if (acc.ELA_Account_Type__c != null ){
                warn10 = true;
            }

            /*************************** Case 05029010 - SFDC Account Highlights Error *************************************/

            if (acc.MRR__c != null && acc.RC_Account_Status__c != null && acc.MRR__c == 0
                    && acc.RC_Account_Status__c.equalsIgnoreCase('Paid') && acc.Billing_ID__c == null) {
                if (acc.RC_SignUp_date__c != null && String.valueOf(acc.RC_SignUp_date__c) != '') {
                    boolTrailAccountMsg = true;
                    Date paidDate = acc.RC_SignUp_date__c.date() + 30;
                    strPaidDate = paidDate.format();
                }
            }
        }

        if (lstAcc.size() > 0) {
            Account acc = lstAcc.get(0);

            //Case 07094046 (QW) O@H to RC Migration Account Highlight Updates https://rc.my.salesforce.com/50034000012julb
            if (IsBrandEqualsToRcOffAtHand(acc.RC_Brand__c) && IsServiceNameEqualsToAttOffAtHand(acc.RC_Service_name__c)) {
                this.IsInTransitionToRcDirect = true;
            }

            Package__c accountPackage = getBillingPackage(acc);
            if (IsAcquisitionTierContainsAtt(accountPackage?.Acquisition_Tier__c) && IsBrandContainsRc(acc.RC_Brand__c)) {
                this.IsInMigrationToAcquistionTier = true;
            }

            isDuplicatePartnerAccountsWereFound(lstAcc[0]);
        }
    }

    public void getDocument() {
        String docName = 'Account_Highlighter';
        List<Document> doc = [SELECT body, Name, bodyLength, ContentType, Url FROM Document WHERE Name = :docName];
        if (doc != null && doc.size() > 0) {
            Blob b = doc[0].body;
            String content = b.toString();
            List<List<String>> parsedCSV = new List<List<String>>();

            // Parse the CSV File
            parsedCSV = parseCSV(content);
            if (parsedCSV != null && !Test.isRunningTest()) {
                parsedCSV.remove(0);
            }
            if (parsedCSV != null) {
                for (List<String> line : parsedCSV) {
                    if (line != null) {
                        String accName = line.get(0);
                        String custContactName = line.get(1);
                        String rcExecContactName = line.get(2);
                        String userId = line.get(3);
                        mapAccHighlighter.put(userId,
                                new AccHighlighterWrapper(accName, custContactName, rcExecContactName, userId));
                    }
                }
            }
        }
    }

    public class AccHighlighterWrapper {
        public String accName;
        public String custContactName;
        public String rcExecContactName;
        public String userId;

        public AccHighlighterWrapper(String accName, String custContactName, String rcExecContactName, String userId) {
            this.accName = accName;
            this.custContactName = custContactName;
            this.rcExecContactName = rcExecContactName;
            this.userId = userId;
        }
    }

    public class EngageLegalWrapper {
        public String elasticity {get; set;}
        public String elasticityDetails {get; set;}
        public String sla {get; set;}
        public String slaContactCenter {get; set;}
        public String slaMeetingsOnly {get; set;}
        public String slaGss {get; set;}
        public String slaIncidentManagement {get; set;}

        public EngageLegalWrapper (Approval__c approval) {
            this.elasticity = approval.Elasticity__c;
            this.elasticityDetails = approval.Elasticity_Details__c;
            this.sla = approval.SLA__c;
            this.slaContactCenter = approval.SLA_Contact_Center__c;
            this.slaMeetingsOnly = approval.SLA_Meetings_Only__c;
            this.slaGss = approval.SLA_GSS__c;
            this.slaIncidentManagement = approval.SLA_Incident_Management__c;
        }
    }

    public class StepUpWrapper {
        public String stepUpName {get; set;}
        public Decimal stepUpDLs {get; set;}
        public Date stepUpDate {get; set;}

        public StepUpWrapper (String stepUpName, Decimal stepUpDLs, Date stepUpDate) {
            this.stepUpName = stepUpName;
            this.stepUpDLs = stepUpDLs;
            this.stepUpDate = stepUpDate;
        }
    }

    private List<List<String>> parseCSV(string contents) {
        List<List<String>> allFields = new List<List<String>>();
        try {
            contents = contents.replaceAll(',"""', ',"DBLQT').replaceAll('""",', 'DBLQT",');
            contents = contents.replaceAll('""', 'DBLQT');
            List<String> lines = new List<String>();
            lines = contents.split('\n');
            for (String line : lines) {
                if (line.replaceAll(',', '').trim().length() == 0) { break; }
                List<String> fields = line.split(',');
                List<String> cleanFields = new List<String>();
                String compositeField;
                Boolean makeCompositeField = false;
                for(String field : fields) {
                    if (field.startsWith('"') && field.endsWith('"')) {
                        cleanFields.add(field.replaceAll('DBLQT', '"').trim());
                    } else if (field.startsWith('"')) {
                        makeCompositeField = true;
                        compositeField = field.trim();
                    } else if (field.endsWith('"')) {
                        compositeField += ',' + field.trim();
                        cleanFields.add(compositeField.replaceAll('DBLQT', '"').trim());
                        makeCompositeField = false;
                    } else if (makeCompositeField) {
                        compositeField += ',' + field.trim();
                    } else {
                        cleanFields.add(field.replaceAll('DBLQT', '"').trim());
                    }
                }
                allFields.add(cleanFields);
            }
        } catch (Exception ex) {}
        return allFields;
    }

    /*********************************************************************************************
    * @Description............: Update the Technical Account Manager field on Account,
    * with the most recently modified Technical Account Manager-Primary
    * Param...................: none
    * @Return.................: pageReference
    * ********************************************************************************************/
    public PageReference PopulateATM() {
        try {
            System.debug('### ' + acct);
            System.debug('======== TAM =========== ' + acct.Technical_Account_Manager__c +
                    ', CONTACT= ' + acct.Most_Recent_Implementation_Contact__c);
            Id tAMOldValue = acct.Technical_Account_Manager__c;
            Id tAMNewValue = null;
            Id oldContactId = null;
            Id newContactId = null;
            Boolean isContactRoleUpdated = false;
            List<AccountContactRole> accConRoleList = new List<AccountContactRole>();
            try {
                accConRoleList = [SELECT Id, ContactId, Contact.Preferred_Language__c FROM AccountContactRole
                                  WHERE AccountId = :acct.Id AND IsPrimary = TRUE
                                  AND Contact.Contact_Status__c NOT IN :ContactHelper.INVALID_CONTACT_STATUSES];
            } catch (Exception ex) {}

            if (accConRoleList.size() > 0) {
                AccountContactRole accConRoleObj = accConRoleList[0];
                if (accConRoleObj != null) {
                    oldContactId = acct.Most_Recent_Implementation_Contact__c;
                    newContactId = accConRoleObj.ContactId;
                    System.debug('### NEW Contact = ' + newContactId);
                    System.debug('### OLD Contact = ' + oldContactId);
                    if (acct.Most_Recent_Implementation_Contact__c != accConRoleObj.ContactId) {
                        isContactRoleUpdated = true;
                        acct.Most_Recent_Implementation_Contact__c = accConRoleObj.ContactId;

                        if (isNewBusinessAcc) {
                            acct.Preferred_Language__c = accConRoleObj.Contact.Preferred_Language__c;
                        }
                    }
                }
            }

            // 03650782 - Start
            warn7 = false;
            if (isATT && isFirstGroupAcc) {
                warn7 = true;
            }
            // 03650782 - End

            // 03531598 - Start
            List<Contact> conList = [SELECT Id, Preferred_Language__c, Email FROM Contact
                                     WHERE AccountId = :acct.Id
                                     AND Contact.Contact_Status__c NOT IN :ContactHelper.INVALID_CONTACT_STATUSES
                                     ORDER BY LastModifiedDate DESC];

            if (isATT && !warn7) {
                for (Contact conObj : conList) {
                    Boolean containsDomain = conObj.email.contains(Emails__c.getAll().get('greyhounddomen').Email_Address__c.replace('_', ''))
                            || conObj.email.contains(Emails__c.getAll().get('firstgroupdomen').Email_Address__c.replace('_', ''));
                    if (conObj.email != null && containsDomain) {
                        warn7 = true;
                    }
                }
            }

            if (accConRoleList.size() <= 0) {
                System.debug('conList--->' + conList);
                boolean isLastModied = true;

                if (conList != null && conList.size() > 0) {
                    if (acct.Most_Recent_Implementation_Contact__c != conList[0].Id) {
                        isContactRoleUpdated = true;
                        acct.Most_Recent_Implementation_Contact__c = conList[0].Id;
                        isLastModied = false;

                        if (isNewBusinessAcc) {
                            acct.Preferred_Language__c = conList[0].Preferred_Language__c;
                        }
                    }
                }
            }
            // 03531598 - End

            if (String.isBlank(String.valueOf(acct.Preferred_Language__c)) && isNewBusinessAcc) {
                acct.Preferred_Language__c = 'en_US';
            }

            //Case # 03523403 - START
            List<String> sTeamRole = new List<String>();
            sTeamRole.add('Customer Success Manager (CSM)');
            sTeamRole.add('Technical Account Manager - Primary');

            System.debug('acct.Most_Recent_Implementation_Contact__c--->' + acct.Most_Recent_Implementation_Contact__c);
            boolean isTamUpdated = false;
            List<AccountTeamMember> latm = new List<AccountTeamMember>();
            latm = [SELECT TeamMemberRole, User.Name, UserId, LastModifiedDate FROM AccountTeamMember
                    WHERE AccountId = :acct.Id
                    AND TeamMemberRole IN :sTeamRole
                    ORDER BY CreatedDate ASC];

            for (AccountTeamMember atm : latm) {
                if (warn5 == false || warn5 == null) {
                    if (atm.TeamMemberRole != null && (atm.TeamMemberRole.containsIgnoreCase(sTeamRole[1]))) {
                        warn5 = true;
                        strTAM = atm.User.Name;
                        strTAMId = atm.UserId;
                        if (acct != null) {
                            tAMNewValue = atm.UserId;
                        }
                    }
                }
                if (warn6 == false || warn6 == null) {
                    if (atm.TeamMemberRole != null && (atm.TeamMemberRole.containsIgnoreCase(sTeamRole[0]))) {
                        warn6 = true;
                        strCSM = atm.User.Name;
                        strCSMId = atm.UserId;
                    }
                }
            }

            //Case # 03523403 - END
            if (tAMNewValue != null && tAMNewValue != tAMOldValue && acct.Id != null) {
                acct.Technical_Account_Manager__c = tAMNewValue;
                refreshBool = true;
                System.debug('####  New TAM = ' + acct.Technical_Account_Manager__c);
                TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT();
                TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE();
                isTamUpdated = true;
                update acct;
            }
            if (!isTamUpdated && isContactRoleUpdated) {
                refreshBool = true;
                System.debug('####  New TAM = ' + acct.Most_Recent_Implementation_Contact__c);
                TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT();
                TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE();
                update acct;
            }
        } catch (Exception ex) {
                System.debug('#### Exception at line = ' + ex.getLineNumber() + ' Message = ' + ex.getMessage());
        }
        return null;
    }

    private Boolean IsBrandEqualsToRcOffAtHand(String value) {
        return IsStringMatchToPattern('(?i)^RingCentral Office\\@*Hand from AT\\&*T$', value);
    }

    private Boolean IsServiceNameEqualsToAttOffAtHand(String value) {
        return IsStringMatchToPattern('(?i)^AT\\&*T Office\\@*Hand$', value);
    }

    private Boolean IsAcquisitionTierContainsAtt(String value) {
        return IsStringMatchToPattern('(?i)^.*(AT\\&*T)+.*$', value);
    }

    private Boolean IsBrandContainsRc(String value) {
        return value.containsIgnoreCase(BRAND_RINGCENTRAL);
    }

    private Boolean IsStringMatchToPattern(String regExPattern, String value) {
        if (String.IsNotBlank(regExPattern) && String.IsNotBlank(value)) {
            return Pattern.matches(regExPattern, value);
        }
        return false;
    }

    private void isDuplicatePartnerAccountsWereFound(Account acc) {
        this.IsDuplicatedPartnerAccountFound = (acc.RecordType.Name == RT_NAME_PARTNER_ACCOUNT
            && String.IsNotBlank(acc.FoundDuplicateAccountIds__c));

        if (this.IsDuplicatedPartnerAccountFound == false) {
            return;
        }

        List<String> ids = acc.FoundDuplicateAccountIds__c.split(',');

        Map<Id, Account> queryResult = new Map<Id, Account>([
            SELECT RC_User_ID__c, Name, Ultimate_Parent_Account_Name__c
            FROM Account
            WHERE Id IN :ids]);

        //we need to arrange records: order of ID in the FoundDuplicateAccountIds__c is matter
        this.DuplicatePartnerAccounts = new List<Account>();
        for (String sid : ids) {
            this.DuplicatePartnerAccounts.add( queryResult.get(Id.valueOf(sid)));
        }
    }

    private Package__c getBillingPackage(Account acc) {
        List<Package__c> accPackages = (List<Package__c>) new PackageSelector()
            .selectPackagesByAccountId(acc.Id)
            .selectFields(new Set<SObjectField> {
                Package__c.Acquisition_Tier__c,
                Package__c.Service_Type__c
            })
            .executeQuery();
        return PackageHelper.filterPackagesByService(accPackages).get(acc.Id);
    }
}