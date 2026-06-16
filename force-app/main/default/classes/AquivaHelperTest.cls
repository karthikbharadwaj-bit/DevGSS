@isTest
public with sharing class AquivaHelperTest {
    public static final String TEST_SAFID = '12345';
    public static final String TEST_SAFID_WITH_PARTNER = '54321';
    public static final String TEST_TIME_ZONE_NAME = '(GMT-12:00) International Date Line West';
    public static final Integer TEST_TIME_ZONE_ID = 62;

    @TestSetup
    static void createTestData() {
        /* Settings */
        new SObjectBuilder(NGBS_Settings__c.SObjectType)
            .create();

        new SObjectBuilder(Category_Codes__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
            Category_Codes__c.Name => 'REQUIRED_AREA_CODES',
            Category_Codes__c.Codes__c => 'HDRF,HDR,HD,MLN,MTN,MLFN,MTFN,ALN,ATN,SP,EP'
        })
            .create();

        new SObjectBuilder(NGBS_Time_Zone_Mapping__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
            NGBS_Time_Zone_Mapping__c.Name => '1',
            NGBS_Time_Zone_Mapping__c.TimeZoneName__c => TEST_TIME_ZONE_NAME,
            NGBS_Time_Zone_Mapping__c.TimeZoneId__c => TEST_TIME_ZONE_ID
        })
            .create();

        /* Area Codes */
        Area_Codes__c ac1 = (Area_Codes__c) new SObjectBuilder(Area_Codes__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Area_Codes__c.Name => 'Test Area Code 1',
                Area_Codes__c.State__c => 'NY',
                Area_Codes__c.Country__c => 'United States'
            })
            .create()
            .getRecord();

        /* User */
        new SObjectBuilder(User.SObjectType)
            .setFields(new Map<SObjectField, Object>{
            User.FirstName => 'John',
            User.LastName => 'Good',
            User.PID__c => 'JohnGoodTestPID',
            User.Country__c => 'United States',
            User.ProfileId => ProfileHelper.PROFILE_ID_SYSADMIN
        })
            .create();

        Triggers.switchOff();
        /* Account  */
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => 'Test acc',
                Account.Payment_Method__c => 'Invoice',
                Account.Tax_Exempt__c => false,
                Account.SignupType__c => 'Free',
                Account.Monthly_Credit_Limit__c => 0,
                Account.Sign_up_Purchase_Limit__c => 0,
                Account.Payment_Terms__c => '12',
                Account.Invoice_Terms__c => '12',
                Account.PID__c => 'test_p_id',
                Account.Timezone__c => TEST_TIME_ZONE_NAME,
                Account.BillingCity => 'TestCity',
                Account.BillingStreet => 'TestStreet',
                Account.BillingState => 'NY',
                Account.BillingPostalCode => '123890',
                Account.BillingCountry => 'US'
            })
            .create()
            .getRecord();

        /* Contact */
        Contact cont = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Contact.AccountId => acc.Id,
                Contact.LastName => 'John',
                Contact.FirstName => 'Good',
                Contact.Email => 'jg@rc.test'
            })
            .create()
            .getRecord();

        Triggers.switchOn();
        /* Opportunity */
        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.AccountId => acc.Id,
                Opportunity.BMID__c => 'test_bm_id',
                Opportunity.OID__c => 'test_o_id',
                Opportunity.Partner_ID__c => 'test_partner_id',
                Opportunity.Enable_Cost_Center_Management__c => false,
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_CLOSED_WON
            })
            .create()
            .getRecord();

        new SObjectBuilder(OpportunityContactRole.SObjectType)
            .setFields(new Map<SObjectField, Object>{
            OpportunityContactRole.isPrimary => true,
            OpportunityContactRole.Role => 'Signatory',
            OpportunityContactRole.ContactId => cont.Id,
            OpportunityContactRole.OpportunityId => opp.Id
        })
            .create();

        Test.startTest();
        /* quote regular */
        Quote qtRegular = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Quote.Pricebook2Id => Test.getStandardPricebookId(),
                Quote.Name => 'Test Regular quote',
                Quote.OpportunityId => opp.Id,
                Quote.CurrencyIsoCode => 'USD',
                Quote.Approved_Status__c => 'Approved',
                Quote.Status => 'Draft',
                Quote.isPrimary__c => true,
                Quote.Initial_Term_months__c => '12',
                Quote.Package_Info__c => NGBSTestDataGenerator.generateQuotePackageInfo(),
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.QuoteType__c => 'Quote',
                Quote.AreaCode__c => ac1.Id,
                Quote.FaxAreaCode__c => ac1.Id,
                Quote.Payment_Plan__c => 'Monthly'
            })
            .create()
            .getRecord();

        /* qlis */
        QuoteLineItem qli = NGBSTestDataGenerator.createQLI('Test product 1', 'LC_TEST_1', 'USD', acc, qtRegular);

        /* acli */
        new SObjectBuilder(Area_Code_Line_Item__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
            Area_Code_Line_Item__c.Quote_Line_Item__c => qli.Id,
            Area_Code_Line_Item__c.Area_Code__c => ac1.Id,
            Area_Code_Line_Item__c.Quantity__c => 1
        })
            .create();
        Test.stopTest();

        // ali

        // contract?
        new SObjectBuilder(GOA_V2__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
            GOA_V2__c.Group__c => 'test',
            GOA_V2__c.Contract_Initial_Term_Range__c => '12-60',
            GOA_V2__c.Sales_Rep__c => '0-10',
            GOA_V2__c.Name => 'test',
            GOA_V2__c.Currency__c => 'USD',
            GOA_V2__c.Direct_Manager__c => '10.01-20',
            GOA_V2__c.Quantity_Range__c => '1-9999999',
            GOA_V2__c.SVP_WWS__c => '20.01-30',
            GOA_V2__c.SVP_WWS_Directs__c => '30.01-40'
        })
            .create();

        RetentionOptionVisibility__c retentionSetting = new RetentionOptionVisibility__c();
        retentionSetting.RoleName__c = 'Retention - Michael';
        insert retentionSetting;
    }


    @isTest
    static void testSignMeUpMethod() {

        User testUser = (User) new SObjectBuilder(User.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    User.LastName => 'DTestTest2d',
                    User.Username => 'Test!user2d@gmail.com',
                    User.Email => 'Test_user2d@gmail.com',
                    User.Alias => 'Test2ds',
                    User.CommunityNickname => 'Test2D',
                    User.TimeZoneSidKey => 'America/Los_Angeles',
                    User.ManagerId => UserInfo.getUserId(),
                    User.LocaleSidKey => 'en_US',
                    User.EmailEncodingKey => 'UTF-8',
                    User.ProfileId => [SELECT Id, Name FROM Profile WHERE Name = 'System Administrator'].Id,
                    User.LanguageLocaleKey => 'en_US',
                    User.Hierarchy_Role__c => 'Sales Rep'
                }
            )
            .create()
            .getRecord();

        List<Group> groupList = new GroupSelector()
            .selectGroupBasedOnDeveloperNames(
                new List<Object>{
                    new Set<String>{
                        'Sales_Desk_Legal'
                    }
                }
            )
            .executeQuery();

        Group salesDeskLegalQueue = groupList.get(0);

        Approval__c testApproval = (Approval__c) new SObjectBuilder(Approval__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Approval__c.OwnerId => salesDeskLegalQueue.Id,
                    Approval__c.Status__c => ApprovalHelper.STATUS_NEW
                }
            )
            .create()
            .getRecord();

        Test.startTest();

            System.runAs(testUser) {
                String result = ApprovalHelperCls.signMeUp(testApproval.Id);
                System.assert(result == null, 'ApprovalHelperCls.signMeUp() should return null if no errors occured');
            }

        Test.stopTest();

        List<Approval__c> approvalList = new ApprovalSelector()
            .selectApprovals()
            .selectFields(
                new Set<SObjectField>{
                    Approval__c.OwnerId,
                    Approval__c.Status__c
                }
            )
            .setCondition('Id = :bind0')
            .setQueryBindings(new List<Object>{ testApproval.Id })
            .executeQuery();

        Approval__c reselectedApproval = approvalList.get(0);

        System.assertEquals(
            'In Progress',
            reselectedApproval.Status__c,
            'Approval.Status__c should be "In Progress"'
        );
        System.assertEquals(
            testUser.Id,
            reselectedApproval.OwnerId,
            'Approval.Owner should be user who run ApprovalHelperCls.signMeUp() method'
        );
    }

    @isTest
    static void testRecallMethod() {

        Approval__c testApproval = (Approval__c) new SObjectBuilder(Approval__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Approval__c.OwnerId => UserInfo.getUserId(),
                    Approval__c.Status__c => ApprovalHelper.STATUS_NEW
                }
            )
            .create()
            .getRecord();

        Test.startTest();

            String result = ApprovalHelperCls.recall(testApproval.Id);
            System.assertEquals(null, result, 'recall() method should return null in case if no errors occurred');

        Test.stopTest();

        List<Approval__c> approvalList = new ApprovalSelector()
            .selectApprovals()
            .selectFields(
                new Set<SObjectField>{
                    Approval__c.Status__c
                }
            )
            .setCondition('Id = :bind0')
            .setQueryBindings(new List<Object>{ testApproval.Id })
            .executeQuery();

        Approval__c reselectedApproval = approvalList.get(0);
        System.assertEquals(
            ApprovalHelper.STATUS_RECALLED,
            reselectedApproval.Status__c,
            'Approval__c.Status__c should be "Recalled"'
        );
    }

  @isTest static void testIsAllowToShowOptions() {
    id currentUserRoleId = UserInfo.getUserRoleId();

    Test.startTest();
    Boolean result = CancelDownsellWizardController.isAllowToShowOptions(currentUserRoleId);
    Test.stopTest();

    System.assertEquals(result, false);
  }

}