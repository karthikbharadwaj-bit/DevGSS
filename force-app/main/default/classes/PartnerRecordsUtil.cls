/*
* Created By    : Saradha
* Created Date  : 18-02-2020
* Description   : Util class to create records for Avaya partner community related test classes

Change History
********************************************************************************************************************
SCRUM/Jira          ModifiedBy      Date     Description                             Tag

********************************************************************************************************************

*/
public class PartnerRecordsUtil{

    public static Account partnerAccount{get;set;}
    public static Contact partnerContact{get;set;}
    public static Partner_Request__c avayaPartner{get;set;}
    public static User runAsSysAdmin{get;set;}
    public static User runAsAvayaAdmin{get;set;}
    //public static User runAsAtosAdmin{get;set;}
    //public static User runAsAleAdmin{get;set;}
    public static User runAsAvayaMasterRole{get;set;}
    public static User runAsAvayaMain{get;set;}
    public static Lead leadObj{get;set;}
    public static Deal_Registration__c dealObj{get;set;}
    public static Opportunity oppObj{get;set;}
    public static Partner_Quote__c partnerQuoteObj{get;set;}
    public static Deal_Support__c dealSupportObj{get;set;}
    public static Deal_Support__c dealSuprtObjForComm{get;set;}
    public static Id accountForLead{get;set;}
    public static Id contactForLead{get;set;}
    public static DealSuprtAndCommentWrapper dealCommWrapper{get;set;}
    public static Account avayaMasterAccount;
    static {
        String randomString = String.valueOf(Datetime.now().getTime());
        if (runAsSysAdmin == null) {
            UserRole portalRole;
            List<UserRole> portalRoles = [SELECT Id, Name,DeveloperName, PortalType FROM UserRole WHERE DeveloperName = 'TestPartnerManager'];

            if (portalRoles.isEmpty()) {
                portalRole = (UserRole) new SObjectBuilder(UserRole.SObjectType)
                .setFields(new Map<SObjectField, Object> {
                    UserRole.Name => 'Test Partner Manager',
                    UserRole.DeveloperName => 'TestPartnerManager',
                    UserRole.PortalType => 'None'
                })
                .create()
                .getRecord();
            } else {
                portalRole = portalRoles.get(0);
            }
            runAsSysAdmin = (User) new SObjectBuilder(User.SObjectType)
                .setFields(
                    new Map<SObjectField, Object> {
                        User.UserRoleId => portalRole.Id,
                        User.ProfileId => ProfileHelper.PROFILE_ID_SYSADMIN,
                        User.Email => new ValueProvider.UniqueStringProvider('bruce.wayne@wayneenterprises2f234.com'),
                        User.EmailEncodingKey => 'UTF-8',
                        User.FirstName => new ValueProvider.UniqueStringProvider('Bruce'),
                        User.LastName => new ValueProvider.UniqueStringProvider('Wayne'),
                        User.LanguageLocaleKey => 'en_US',
                        User.LocaleSidKey => 'en_US',
                        User.TimeZoneSidKey => 'America/Chicago',
                        User.Username => new ValueProvider.UniqueStringProvider(randomString + 'bw@wayne.com'),
                        User.Alias => 'batndfw',
                        User.CommunityNickname => randomString
                    }
                )
                .create()
                .getRecord();
        }

        if (avayaMasterAccount == null) {
            avayaMasterAccount = (Account) new SObjectBuilder(Account.SObjectType)
                .setFields(
                    new Map<SObjectField, Object> {
                        Account.Name => 'Avaya Inc.',
                        Account.BillingStreet => '290 Davidson Avenue',
                        Account.BillingCity => 'Somerset',
                        Account.BillingState => 'NEW JERSEY',
                        Account.BillingPostalCode => '8873',
                        Account.Billingcountry => 'United States',
                        Account.RC_User_ID__c => randomString,
                        Account.Billing_ID__c => '',
                        Account.RC_Account_Status__c => '',
                        Account.RC_brand__c => OpportunityHelper.BRAND_AVAYA,
                        Account.CurrencyIsoCode => 'USD',
                        Account.Service_Type__c => '',
                        Account.Type => AccountHelper.TYPE_PARTNER
                    }
                )
                .createAsUser(runAsSysAdmin)
                .getRecord();
        }
    }
    public PartnerRecordsUtil(){
        PartnerRecordsUtil.createAvayaPartnerAccount();
        PartnerRecordsUtil.createAvayaPartnerRequest();
        System.debug('$$$$ QUERIES AFTER PartnerRecordsUtil: ' + Limits.getQueries());
    }
    public static void createAvayaPartnerAccount(){
        if(PartnerRecordsUtil.partnerAccount == null){
            //List<Group> grp = [Select Id from Group where relatedId = :portalRole.Id];
            List<User> userLst = new List<User>();
            List<Account> accLst = new List<Account>();
            List<Contact> contactLst = new List<Contact>();
            User userSysAdmin = runAsSysAdmin;
            System.runAs ( userSysAdmin ) {
                ByPassTrigger__c bpt = new ByPassTrigger__c(SetupOwnerId= Userinfo.getUserId(), Bypass_Account_Trigger__c = true, Bypass_Contact_Trigger__c = true);
        		insert bpt;
                Account portalAccount1 = new Account(
                    Name = 'TestAccount',
                    OwnerId = userSysAdmin.Id,
                    RC_Brand__c ='Avaya Cloud Office'
                );
                accLst.add(portalAccount1);

                Account AtosAccount = new Account(
                    Name = 'TestAtos',
                    OwnerId = userSysAdmin.Id,
                    RC_Brand__c ='Unify Office'
                );
                accLst.add(AtosAccount);

                Account ALEAccount = new Account(
                    Name = 'TestALE',
                    OwnerId = userSysAdmin.Id,
                    RC_Brand__c ='Rainbow Office'
                );

                accLst.add(ALEAccount);

                Account portalAccount3 = new Account(
                    Name = 'TestAccount 3',
                    OwnerId = userSysAdmin.Id
                );
                accLst.add(portalAccount3);

                Account portalAccount4 = new Account(
                    Name = 'TestAccount4',
                    RC_Brand__c ='Avaya Cloud Office',
                    OwnerId = userSysAdmin.Id);

                accLst.add(portalAccount4);

                Database.insert(accLst);
                accLst = new List<Account>();

                portalAccount1.IsPartner = true;
                portalAccount1.type = 'Partner';
                portalAccount1.Avaya_partnership_account__c = true;
                portalAccount1.Parent_Partner_Account__c = avayaMasterAccount.Id;
                portalAccount1.Partner_Account__c =portalAccount4.Id;
                portalAccount1.Permitted_Brands__c = 'Avaya Cloud Office';

                AtosAccount.IsPartner = true;
                AtosAccount.type = 'Partner';
                AtosAccount.Avaya_partnership_account__c = true;

                ALEAccount.IsPartner = true;
                ALEAccount.type = 'Partner';
                ALEAccount.Avaya_partnership_account__c = true;

                portalAccount3.IsPartner = true;
                portalAccount3.type = 'Partner';
                portalAccount3.Partner_Role__c ='Master Agent';
                portalAccount3.Avaya_partnership_account__c = true;
                portalAccount3.Parent_Partner_Account__c = avayaMasterAccount.Id;
                portalAccount3.RC_Brand__c = 'Avaya Cloud Office';

                portalAccount4.IsPartner = true;
                portalAccount4.type = 'Partner';
                portalAccount4.Avaya_partnership_account__c = true;
                portalAccount4.Partner_Account__c = portalAccount1.Id;
                portalAccount4.Parent_Partner_Account__c = portalAccount1.Id;

                accLst.add(portalAccount1);
                accLst.add(portalAccount3);
                accLst.add(portalAccount4);
                accLst.add(AtosAccount);
                accLst.add(ALEAccount);

                update accLst;

                Contact contact1 = new Contact(
                    FirstName = 'Test',
                    Lastname = 'McTesty',
                    AccountId = portalAccount1.Id,
                    Partner_Portal_View__c='Full',
                    Email = System.now().millisecond() + 'test@1test.com'
                );
                contactLst.add(contact1);

                Contact AtosContact = new Contact(
                    FirstName = 'Test',
                    Lastname = 'Atos',
                    AccountId = AtosAccount.Id,
                    Partner_Portal_View__c='Full',
                    Email = System.now().millisecond() + 'testatos@1test.com'
                );
                contactLst.add(AtosContact);

                Contact ALEContact = new Contact(
                      FirstName = 'Test',
                      Lastname = 'ALE',
                      AccountId = ALEAccount.Id,
                      Partner_Portal_View__c='Full',
                      Email = System.now().millisecond() + 'testatos@1test.com',
                      Avaya_Partnership_Contact__c = true
                  );
                  contactLst.add(ALEContact);

                Contact contact2 = new Contact(
                    FirstName = 'Test 2',
                    Lastname = 'McTestysdf',
                    AccountId = avayaMasterAccount.id,
                    Partner_Portal_View__c='Full',
                    Email = System.now().millisecond() + 'test@2test.com'
                );
                contactLst.add(contact2);
                Contact contact3 = new Contact(
                    FirstName = 'Test 3',
                    Lastname = 'McTestysdf',
                    AccountId = portalAccount3.Id,
                    Partner_Portal_View__c='Full',
                    Email = System.now().millisecond() + 'test@2test.com'
                );
                contactLst.add(contact3);

               Contact contact4 = new Contact(
                    FirstName = 'Test 4',
                    Lastname = 'McTest4',
                    AccountId = portalAccount4.Id,
                    Partner_Portal_View__c='Full',
                    Email = System.now().millisecond() + 'test@4test.com'
                );
                contactLst.add(contact4);

                Database.insert(contactLst);

                // Creating User with Portal Role -> Manager & Profile as -> Partner Community - Partner Admin
                // And with account Partner_Role__c ='Master Agent';
                Profile portalProfile = [SELECT Id FROM Profile where name='Partner Community - Partner Admin' Limit 1];

                User user = new User(alias = 'test123',
                                     email='test123@noemail.com',
                                     emailencodingkey='UTF-8',
                                     lastname='Testing',
                                     languagelocalekey='en_US',
                                     localesidkey='en_US',
                                     PortalRole = 'Manager',
                                     profileid = portalProfile.Id,
                                     country='United States',IsActive =true,
                                     ContactId = contact1.Id,
                                     timezonesidkey='America/Los_Angeles',
                                     username='testerrandomw@noemail.com'+getRandomUsername());
                userLst.add(user);
                // Creating User with Portal Role -> Manager & Profile as -> Partner Community - Partner Admin
                // And without account Partner_Role__c ='Master Agent'; and Account as Avaya(master)
                //Profile partnerAdmin = [SELECT Id FROM Profile where name='Partner Community - Partner Admin' Limit 1];
                User user1 = new User(alias = 'test123',
                                      email='test123@noemail.com',
                                      emailencodingkey='UTF-8',
                                      lastname='Testing',
                                      languagelocalekey='en_US',
                                      localesidkey='en_US',
                                      profileid = portalProfile.Id,
                                      country='United States',IsActive =true,
                                      ContactId = contact2.Id,
                                      timezonesidkey='America/Los_Angeles',
                                      PortalRole = 'Manager',
                                      username='testerrandomwuser@noemail.com'+getRandomUsername());
                userLst.add(user1);

                User user3 = new User(alias = 'test123',
                                      email='test123@noemail.com',
                                      emailencodingkey='UTF-8',
                                      lastname='Testing',
                                      languagelocalekey='en_US',
                                      localesidkey='en_US',
                                      PortalRole = 'Manager',
                                      profileid = portalProfile.Id,
                                      country='United States',IsActive =true,
                                      ContactId = contact3.Id,
                                      timezonesidkey='America/Los_Angeles',
                                      username='testerrandomw1@noemail.com'+getRandomUsername());
                userLst.add(user3);

                //Database.insert(userLst);
                insert userLst;

                runAsAvayaAdmin = user;
                //runAsAtosAdmin = AtosUser;
                //runAsAleAdmin = ALEUser;
                runAsAvayaMasterRole = user3;
                runAsAvayaMain = user1;
                accountForLead = portalAccount3.id;
                contactForLead = contact3.id;
                //Included for PCM
                portalAccount1.Partner_Channel_Manager__c = contact3.Id;
                update portalAccount1;

                //This is the Partner Account
                partnerAccount = portalAccount1;
                //This is the Partner Contact
                partnerContact = contact1;
            }
        }

    }
    public static void createAvayaPartnerRequest(){
        if(PartnerRecordsUtil.avayaPartner == null){
            Partner_Request__c partnerObj = new Partner_Request__c();
            partnerObj.Partner_First_Name__c = 'Test Avaya';
            partnerObj.Partner_Last_Name__c ='Partner';
            partnerObj.Partner_Company_Name__c = 'Test Avaya Company';
            partnerObj.Partner_Address1__c = 'Test Address';
            partnerObj.Partner_City__c = 'Test City';
            partnerObj.Partner_State__c ='ALASKA';
            partnerObj.Partner_Zip__c='123456';
            partnerObj.Partner_Country__c='United States';
            partnerObj.Partner_Phone__c='7895412630';
            partnerObj.Partner_Email_Address__c='testavaya@lister.com';
            partnerObj.Partner_Portal_View__c='Full';
            partnerObj.Avaya_Partnership_Reg__c = true;
            partnerObj.Partner_Role__c = 'General Partner';
            partnerObj.Partner_Type__c ='Avaya';
            partnerObj.AD__c = 'No';
            try{
                system.runAs(runAsSysAdmin){
                    Database.insert(partnerObj);
                }

            }catch(Exception e){

            }
            avayaPartner = partnerObj;
        }


    }
    public static Lead createAvayaLead(Deal_Registration__c dealObj){
        if(leadObj == null){
            Lead leadTmpObj=new Lead(
                LastName='TestLast',
                FirstName='TestFirst',
                Company='Test',
                email='test@lister.com',
                Status='1. New',
                Deal_Registration__c = dealObj.Id,
                Avaya_Partnership_Lead__c = true,
                Lead_Brand_Name__c='Avaya Cloud Office',
                Estimated_Close_Date__c = dealObj.Estimated_Close_Date__c,
                Partner_Account__c = avayaMasterAccount.Id,
                Partner_Contact__c = PartnerRecordsUtil.partnerContact.Id
            );
            system.runAs(runAsSysAdmin){
                Database.insert(leadTmpObj);
                System.debug('** lead '+leadTmpObj);
            }

            leadObj= leadTmpObj;
        }
        return leadObj;
    }
    public static Deal_Registration__c createAvayaDeal(){
        if(dealObj == null){
            Deal_Registration__c dealRegObj = new Deal_Registration__c();
            dealRegObj.First_Name__c = 'Test';
            dealRegObj.Last_Name__c = 'DealReg';
            dealRegObj.Business_Title__c = 'Consultant';
            dealRegObj.Company_Name__c = 'Test Company';
            dealRegObj.Email_Address__c = 'testdealreg@mail.com';
            dealRegObj.Phone_Number__c = '123456789';
            dealRegObj.Address__c = 'ABC street';
            dealRegObj.City__c = 'abc city';
            dealRegObj.State__c = 'ALASKA';
            dealRegObj.Postal_Code__c = '123456';
            dealRegObj.Country__c = 'United States';
            dealRegObj.Forecasted_Users__c = 5;
            dealRegObj.Brand_Name__c = 'Avaya Cloud Office';
            dealRegObj.Tier_Name__c = 'Office';
            dealRegObj.Edition__c = 'Standard';
            dealRegObj.Term__c = 'Annual';
            dealRegObj.Number_of_Employees__c = '50-249';
            dealRegObj.Number_of_Locations__c = '5-9';
            dealRegObj.Industry__c = 'Banking';
            dealRegObj.Estimated_Close_Date__c = System.today()+90;
            dealRegObj.Website__c = 'www.testsite.com';
            dealRegObj.How_did_you_acquire_this_Lead__c = 'Testing Acquisition';
            dealRegObj.Description__c = 'Test Deal Reg description';
            dealRegObj.Budget_available_for_project__c = 'Yes';
            dealRegObj.Existing_Solution_Provider__c = 'Avaya';
            dealRegObj.Competitor_s__c = 'Avaya';
            dealRegObj.What_s_prompting_change__c = 'Other';
            dealRegObj.Whats_prompting_change__c = 'Other';
            dealRegObj.Decision_Maker__c = 'Other';
            dealRegObj.Currently_in_a_contract__c = 'Yes';
            dealRegObj.Sales_Notes__c = 'Test Sales notes';
            dealRegObj.Avaya_Partnership_Deal__c = true;
            dealRegObj.Status__c = 'Approved';
            dealRegObj.Avaya_Cloud_Specialist__c = PartnerRecordsUtil.partnerContact.Id;
            dealRegObj.RC_Overlay__c = 'test';
            dealRegObj.Portal_Cloud_Specialist__c=PartnerRecordsUtil.partnerContact.Id;
            dealRegObj.Partner_Contact__c = PartnerRecordsUtil.partnerContact.Id;
            dealRegObj.Partner_Account__c = PartnerRecordsUtil.partnerAccount.Id;
            system.runAs(runAsSysAdmin){
                Database.insert(dealRegObj);
                System.debug('** Deal '+dealRegObj);
            }
            dealObj = dealRegObj;
        }
        return dealObj;
    }
    public static Opportunity createAvayaOpportunity(){
        if(oppObj == null){
            Opportunity oppTmpObj = new Opportunity(
                Name = 'Test a Opportunity',
                StageName = '1. Qualify',
                AccountId = avayaMasterAccount.Id,
                Strategic_Partner_RC_Owner__c = userinfo.getuserid(),
                /* Close date is setup or test fix purposes
                 * There are no Opportuinty.Name = "Test a Opportunity" on production env
                **/
                CloseDate = System.today(),
                Partner_Account__c = avayaMasterAccount.Id,
                Portal_Cloud_Specialist__c=PartnerRecordsUtil.partnerContact.Id
            );
            system.runAs(runAsSysAdmin){
                Database.insert(oppTmpObj);
            }
            oppObj = oppTmpObj;
        }
        return oppObj;
    }

    public static Partner_Quote__c createPartnerQuote(Opportunity oppObjParam){
        if(partnerQuoteObj == null){
            Partner_Quote__c partnerQuoteTmpObj = new Partner_Quote__c();
            partnerQuoteTmpObj.Name__c = 'Test Partner Quote';
            partnerQuoteTmpObj.Opportunity__c = oppObjParam.id;
            system.runAs(runAsSysAdmin){
                Database.insert(partnerQuoteTmpObj);
            }
            partnerQuoteObj = partnerQuoteTmpObj;
        }
        return partnerQuoteObj;
    }

    public static Deal_Support__c createDealSupport(){
        if(dealSupportObj == null){
            Group testGroup = new Group(Name='Avaya Queue', Type='Queue');
            insert testGroup;

            Deal_Support__c dealSupTmp = new Deal_Support__c();
            dealSupTmp.Partner_Account__c=PartnerDealRegistrationUtil.getSelectedPartnerId();
            dealSupTmp.Type__c='Initial Order';
            System.RunAs(new User(Id=UserInfo.getUserId())){
            QueuesObject testQueue = new QueueSObject(QueueID = testGroup.id, SObjectType = 'Deal_Support__c');
            insert testQueue;
            }
            dealSupTmp.OwnerId = testGroup.Id;
            dealSupTmp.Partner_Contact__c = partnerContact.id;
            Opportunity opp = PartnerRecordsUtil.createAvayaOpportunity();
            dealSupTmp.Opportunity__c=opp.id;
            dealSupTmp.Name='Initial Order'+' - '+opp.Name;
            dealSupTmp.Customer_Account__c = opp.Partner_Account__c;
            system.runAs(runAsSysAdmin){
                Database.Insert(dealSupTmp);
            }
            dealSupportObj = dealSupTmp;
        }
        return dealSupportObj;
    }

    public static String getRandomUsername(){
        String randomUserName = '';
        Integer i = 5;
        while(i > 0){
            randomUserName += string.valueOf((Integer)Math.ceil(Math.random()*10));
            i--;
        }
        return randomUserName;
    }
    public class DealSuprtAndCommentWrapper{
        public Deal_Support__c dealSprtObj{get;set;}
        public Deal_Support_Comments__c dealComnts{get;set;}
        public Partner_Quote__c pQuoteObj{get;set;}
    }
}