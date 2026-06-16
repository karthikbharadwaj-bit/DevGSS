/**
 * This class contains unit tests for validating the behavior of Apex class TelusExternalSharingHelperCls
 * and triggers.
 */
@isTest
private class TestTelusExternalSharingHelperCls {
    static Account returnAccount() {
        Account acc = new Account(Partner_BAN_ID__c = '12345', Name = 'TELUS House Account');
        Test_Utils tutils = new Test_Utils();
        tutils.initialiseTriggerBypass();
        insert acc;
        return acc;
    }
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void myUnitTest() {
        User testUser = [select Id,Name FROM User Where Name= 'RCESB'];
        System.runAs(testUser){
            Account acc = returnAccount();
            Set<Id> accIdSet;
            if(acc.Id != NULL){
                accIdSet = new Set<Id>{acc.Id};
            }
            TelusExternalSharingHelperCls.returnAccountMapFromAccID(accIdSet);
            
            List<CaseComment> lstCaseComment = new List<CaseComment>();
            TelusExternalSharingHelperCls telusExtHelper = new TelusExternalSharingHelperCls();
            Test_Utils tutils = new Test_Utils();
            Set < Id > caseIdSet = new Set < Id > ();
    
            Contact con1 = new Contact(FirstName = 'Rajesh', LastName = 'Nehra', email = 'rajesh.kumar@simplion.com');
            List < Contact > contactList = new List < Contact > {
                con1
            };
            List < Contact > contactNewList = tutils.createContactRecord(contactList);
    
            Case case1 = new Case(recordTypeId = TelusExternalSharingHelperCls.rtMapById.get('Support - Telus').getRecordTypeId(), Type = 'VoIP Assure',
            Partner_BAN_ID__c = '12345', Case_Contact_Email__c = 'rajesh.kumar@simplion.com', contact = contactNewList[0], Account = acc);
            Case case2 = new Case(recordTypeId = TelusExternalSharingHelperCls.rtMapById.get('Support - T1 (Shipping)').getRecordTypeId(), Type = 'VoIP Device Back Order',
            Partner_BAN_ID__c = '1345');
            Case case3 = new Case(Partner_BAN_ID__c = '',recordTypeId = TelusExternalSharingHelperCls.rtMapById.get('Porting - In (TELUS)').getRecordTypeId(), Type = 'VoIP Device Back Order');
            Case case4 = new Case(recordTypeId = TelusExternalSharingHelperCls.rtMapById.get('Porting - Out').getRecordTypeId(), Type = 'VoIP Device Back Order');
            List < Case > caseList = new List < Case > {
                case1, case2, case3, case4
            };
            tutils.initialiseTriggerBypass();
            insert caseList;
            CaseComment objCaseComment = new CaseComment(ParentId = case1.Id,CommentBody = 'testing');
            lstCaseComment.add(objCaseComment);
            insert objCaseComment;
            for (Case cas: caseList) {
                caseIdSet.add(cas.Id);
            }
    
            TelusExternalSharingHelperCls.shareRecords(caseList);
        }
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void myUnitTest1() {
        User testUser = [select Id,Name FROM User Where Name= 'RCESB'];
        System.runAs(testUser){
            Account acc = returnAccount();
            TelusExternalSharingHelperCls telusExtHelperr = new TelusExternalSharingHelperCls();
            Test_Utils tutilss = new Test_Utils();
            Set < Id > caseIdSett = new Set < Id > ();
    
            Contact con11 = new Contact(FirstName = 'Rajesh', LastName = 'Nehra', email = 'rajesh.kumar@simplion.com');
            List < Contact > contactListt = new List < Contact > {
                con11
            };
            List < Contact > contactNewListt = tutilss.createContactRecord(contactListt);
    
            Case case11 = new Case(recordTypeId = TelusExternalSharingHelperCls.rtMapById.get('Support - Telus').getRecordTypeId(), Type = 'VoIP Assure',
            Partner_BAN_ID__c = '12345', Case_Contact_Email__c = 'rajesh.kumar@simplion.com', contact = contactNewListt[0], Account = acc);
            Case case21 = new Case(recordTypeId = TelusExternalSharingHelperCls.rtMapById.get('Support - T1 (Shipping)').getRecordTypeId(), Type = 'VoIP Device Back Order',
            Partner_BAN_ID__c = '1345');
            Case case31 = new Case(Partner_BAN_ID__c = '',recordTypeId = TelusExternalSharingHelperCls.rtMapById.get('Porting - In (TELUS)').getRecordTypeId(), Type = 'VoIP Device Back Order');
            Case case41 = new Case(recordTypeId = TelusExternalSharingHelperCls.rtMapById.get('Porting - Out').getRecordTypeId(), Type = 'VoIP Device Back Order');
            List < Case > caseListt = new List < Case > {
                case11, case21, case31, case41
            };
            tutilss.initialiseTriggerBypass();
            insert caseListt;
            for (Case cass: caseListt) {
                caseIdSett.add(cass.Id);
            }
            TelusExternalSharingHelperCls.mapAccountOnTelusSharedCases(caseListt);
            TelusExternalSharingHelperCls.mapTelusRecordTypesToRCRecType(caseListt);
        }

    }

    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void myUnitshareCasesWithTelus() {
        User testUser = [select Id,Name FROM User Where Name= 'RCESB'];
        System.runAs(testUser){
            Account acc = returnAccount();
            TelusExternalSharingHelperCls telusExtHelperrrrr = new TelusExternalSharingHelperCls();
            Test_Utils tutilsssss = new Test_Utils();
            Set < Id > caseIdSettttt = new Set < Id > ();
    
            Contact contact1 = new Contact(FirstName = 'Rajesh', LastName = 'Nehra', email = 'rajesh.kumar@simplion.com');
            List < Contact > contactList1 = new List < Contact > {
                contact1
            };
            List < Contact > contactNewList1 = tutilsssss.createContactRecord(contactList1);
    
            Case newCas1 = new Case(recordTypeId = TelusExternalSharingHelperCls.rtMapById.get('Support - Telus').getRecordTypeId(), Type = 'VoIP Assure',
            Partner_BAN_ID__c = '12345', Case_Contact_Email__c = 'rajesh.kumar@simplion.com', contact = contactNewList1[0], Account = acc);
            Case newCas2 = new Case(recordTypeId = TelusExternalSharingHelperCls.rtMapById.get('Support - T1 (Shipping)').getRecordTypeId(), Type = 'VoIP Device Back Order',
            Partner_BAN_ID__c = '1345');
            Case newCas3 = new Case(recordTypeId = TelusExternalSharingHelperCls.rtMapById.get('Porting - In (TELUS)').getRecordTypeId(), Type = 'VoIP Device Back Order');
            Case newCas4 = new Case(recordTypeId = TelusExternalSharingHelperCls.rtMapById.get('Porting - Out').getRecordTypeId(), Type = 'VoIP Device Back Order');
            List < Case > caseListtttt = new List < Case > {
                newCas1, newCas2, newCas3, newCas4
            };
            tutilsssss.initialiseTriggerBypass();
            insert caseListtttt;
            List < Device__c > lstDvc1 = new List < Device__c > ();
            Device__c dvcc = new Device__c(Serial_Number__c = '123', Device_Type__c = 'IP', Case__c = caseListtttt.get(0).Id, Instance_ID__c = '1234gh456');
            lstDvc1.add(dvcc);
            insert lstDvc1;
            dvcc.Returned_Date__c = system.today();
            update dvcc;
            for (Case casssss: caseListtttt) {
                caseIdSettttt.add(casssss.Id);
            }
            TelusExternalSharingHelperCls.shareCasesWithTelus(caseListtttt);
        }   
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void myUnitreParentToCaseOnRC() {
        User testUser = [select Id,Name FROM User Where Name= 'RCESB'];
        System.runAs(testUser){
            Account acc = returnAccount();
            Test_Utils tutilss = new Test_Utils();
            TelusExternalSharingHelperCls telusExtHelpper = new TelusExternalSharingHelperCls();
    
            Case newCas11 = new Case(recordTypeId = TelusExternalSharingHelperCls.rtMapById.get('Support - Telus').getRecordTypeId(), Type = 'VoIP Assure',
            Partner_BAN_ID__c = '12345', Case_Contact_Email__c = 'rajesh.kumar@simplion.com', Account= acc);
            Case newCas21 = new Case(recordTypeId = TelusExternalSharingHelperCls.rtMapById.get('Support - T1 (Shipping)').getRecordTypeId(), Type = 'VoIP Device Back Order',
            Partner_BAN_ID__c = '1345');
            Case newCas31 = new Case(recordTypeId = TelusExternalSharingHelperCls.rtMapById.get('Porting - In (TELUS)').getRecordTypeId(), Type = 'VoIP Device Back Order');
            Case newCas41 = new Case(recordTypeId = TelusExternalSharingHelperCls.rtMapById.get('Porting - Out').getRecordTypeId(), Type = 'VoIP Device Back Order');
            List < Case > caseList23 = new List < Case > {
                newCas11, newCas21, newCas31, newCas41
            };
            tutilss.initialiseTriggerBypass();
            insert caseList23;
            List < Device__c > lstDvc131 = new List < Device__c > ();
            Device__c dvc23 = new Device__c(Serial_Number__c = '123', Device_Type__c = 'IP', Case__c = caseList23.get(0).Id, Instance_ID__c = '1234gh456');
            Device__c dvc23q = new Device__c(Local_Parent_Id__c=(String)newCas41.Id,Serial_Number__c = '123', Device_Type__c = 'IP', Case__c = caseList23.get(0).Id, Instance_ID__c = '1234gh456');
            lstDvc131.add(dvc23);
            lstDvc131.add(dvc23q);
            insert lstDvc131;
            TelusExternalSharingHelperCls.reParentToCaseOnRC(lstDvc131);
        }   
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void myUnitshareDeviceWithTelus() {
        User testUser = [select Id,Name FROM User Where Name= 'RCESB'];
        System.runAs(testUser){
            Account acc = returnAccount();
            TelusExternalSharingHelperCls telusExtHelpper = new TelusExternalSharingHelperCls();
            Test_Utils tutilss = new Test_Utils();
    
            Case newCaseeshare1 = new Case(recordTypeId = TelusExternalSharingHelperCls.rtMapById.get('Support - Telus').getRecordTypeId(), Type = 'VoIP Assure',
            Partner_BAN_ID__c = '12345', Case_Contact_Email__c = 'rajesh.kumar@simplion.com',Account =acc);
            Case newCaseeshare2 = new Case(recordTypeId = TelusExternalSharingHelperCls.rtMapById.get('Support - T1 (Shipping)').getRecordTypeId(), Type = 'VoIP Device Back Order',
            Partner_BAN_ID__c = '1345');
            Case newCaseeshare3 = new Case(recordTypeId = TelusExternalSharingHelperCls.rtMapById.get('Porting - In (TELUS)').getRecordTypeId(), Type = 'VoIP Device Back Order');
            Case newCaseeshare4 = new Case(recordTypeId = TelusExternalSharingHelperCls.rtMapById.get('Porting - Out').getRecordTypeId(), Type = 'VoIP Device Back Order');
            List < Case > caseListshare = new List < Case > {
                newCaseeshare1, newCaseeshare2, newCaseeshare3, newCaseeshare4
            };
            tutilss.initialiseTriggerBypass();
            insert caseListshare;
            List < Device__c > lstDvc1share = new List < Device__c > ();
            Device__c dvcShDevice = new Device__c(Serial_Number__c = '123', Device_Type__c = 'IP', Case__c = caseListshare.get(0).Id, Instance_ID__c = '1234gh456');
            lstDvc1share.add(dvcShDevice);
            insert lstDvc1share;
            TelusExternalSharingHelperCls.shareWithTelus((List<sObject>) lstDvc1share);
        }   
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void myUnitpopulatePartnerCaseIdOnDevice() {
        User testUser = [select Id,Name FROM User Where Name= 'RCESB'];
        System.runAs(testUser){
            Account acc = returnAccount();
            TelusExternalSharingHelperCls telusExtHelpper = new TelusExternalSharingHelperCls();
            Test_Utils tutilss = new Test_Utils();
            Case newCaseeshare11 = new Case(recordTypeId = TelusExternalSharingHelperCls.rtMapById.get('Support - Telus').getRecordTypeId(), Type = 'VoIP Assure',
            Partner_BAN_ID__c = '12345', Case_Contact_Email__c = 'rajesh.kumar@simplion.com', Account= acc);
            Case newCaseeshare21 = new Case(recordTypeId = TelusExternalSharingHelperCls.rtMapById.get('Support - T1 (Shipping)').getRecordTypeId(), Type = 'VoIP Device Back Order',
            Partner_BAN_ID__c = '1345');
            Case newCaseeshare31 = new Case(recordTypeId = TelusExternalSharingHelperCls.rtMapById.get('Porting - In (TELUS)').getRecordTypeId(), Type = 'VoIP Device Back Order');
            Case newCaseeshare41 = new Case(recordTypeId = TelusExternalSharingHelperCls.rtMapById.get('Porting - Out').getRecordTypeId(), Type = 'VoIP Device Back Order');
            List < Case > caseListPopPartner = new List < Case > {
                newCaseeshare11, newCaseeshare21, newCaseeshare31, newCaseeshare41
            };
            tutilss.initialiseTriggerBypass();
            insert caseListPopPartner;
            List < Device__c > lstDvc1Pop = new List <Device__c> ();
            Device__c dvcShDevicePop = new Device__c(Serial_Number__c = '123', Device_Type__c = 'IP', Case__c = caseListPopPartner.get(0).Id, Instance_ID__c = '1234gh456');
            lstDvc1Pop.add(dvcShDevicePop);
            insert lstDvc1Pop;
            TelusExternalSharingHelperCls.populatePartnerCaseIdOnDevice(lstDvc1Pop);
        }   
    }
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void myUnitpopulateVendorContactFieds(){
        User testUser = [select Id,Name FROM User Where Name= 'RCESB'];
        System.runAs(testUser){
            Account acc = returnAccount();
            Test_Utils tutilss = new Test_Utils();
            TelusExternalSharingHelperCls telusExtHelpper = new TelusExternalSharingHelperCls();
            
    
            Case newCaseeshare111 = new Case(recordTypeId = TelusExternalSharingHelperCls.rtMapById.get('Support - Telus').getRecordTypeId(), Type = 'VoIP Assure',
            Partner_BAN_ID__c = '12345', Case_Contact_Email__c = 'rajesh.kumar@simplion.com', Account= acc );
            Case newCaseeshare211 = new Case(recordTypeId = TelusExternalSharingHelperCls.rtMapById.get('Support - T1 (Shipping)').getRecordTypeId(), Type = 'VoIP Device Back Order',
            Partner_BAN_ID__c = '1345');
            Case newCaseeshare311 = new Case(recordTypeId = TelusExternalSharingHelperCls.rtMapById.get('Porting - In (TELUS)').getRecordTypeId(), Type = 'VoIP Device Back Order');
            Case newCaseeshare411 = new Case(recordTypeId = TelusExternalSharingHelperCls.rtMapById.get('Porting - Out').getRecordTypeId(), Type = 'VoIP Device Back Order');
            List < Case > caseListPopPartnerVender = new List < Case > {
                newCaseeshare111, newCaseeshare211, newCaseeshare311, newCaseeshare411
            };
            tutilss.initialiseTriggerBypass();
            insert caseListPopPartnerVender;
            List < Device__c > lstDvc1PopVendor = new List < Device__c > ();
            Device__c dvcShDevicePopven = new Device__c(Serial_Number__c = '123', Device_Type__c = 'IP', Case__c = caseListPopPartnerVender.get(0).Id, Instance_ID__c = '1234gh456');
            lstDvc1PopVendor.add(dvcShDevicePopven);
            insert lstDvc1PopVendor;
            
            TelusExternalSharingHelperCls.populateVendorContactFieds(caseListPopPartnerVender);
        }
    }
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
     @isTest
    static void myUnittouchCases(){
        User testUser = [select Id,Name FROM User Where Name= 'RCESB'];
        System.runAs(testUser){
            Account acc = returnAccount();
            Test_Utils tutilss = new Test_Utils();
            TelusExternalSharingHelperCls telusExtHelpper = new TelusExternalSharingHelperCls();        
            Set < Id > caseIdTouchCasesetId = new Set < Id > ();
            Case newCaseUpdatetouchCases = new Case(recordTypeId = TelusExternalSharingHelperCls.rtMapById.get('Support - Telus').getRecordTypeId(), Type = 'VoIP Assure',
            Partner_BAN_ID__c = '12345', Case_Contact_Email__c = 'rajesh.kumar@simplion.com', Account= acc );
            
            List < Case > touchCasesList= new List < Case > { newCaseUpdatetouchCases};
            tutilss.initialiseTriggerBypass();      
            insert touchCasesList;
            for (Case casttt: touchCasesList) {
                caseIdTouchCasesetId.add(casttt.Id);
            }
            TelusExternalSharingHelperCls.touchCases(caseIdTouchCasesetId);
         }  
     }
     @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
     @isTest
    static void onLocalCaseCommentInsert(){
        User testUser = [select Id,Name FROM User Where Name= 'RCESB'];
        System.runAs(testUser){
            Account acc = returnAccount();
            Test_Utils tutilss = new Test_Utils();
            Case newCaseUpdatetouchCases = new Case(recordTypeId = TelusExternalSharingHelperCls.rtMapById.get('Support - Telus').getRecordTypeId(), Type = 'VoIP Assure',
            Partner_BAN_ID__c = '12345', Case_Contact_Email__c = 'rajesh.kumar@simplion.com', Account= acc,Return_Shipping_Address__c = 'add|city|state|123|USA' );
            
            List < Case > touchCasesList= new List < Case > { newCaseUpdatetouchCases};
            tutilss.initialiseTriggerBypass();      
            insert touchCasesList;
                    
            TelusExternalSharingHelperCls.mapTelusAddressToRCAddress(touchCasesList);
            CaseComment cmt = new CaseComment(ParentId = newCaseUpdatetouchCases.Id,CommentBody = '1234');
            CaseComment cmt2 = new CaseComment(ParentId = newCaseUpdatetouchCases.Id,CommentBody = '1234');
            
            List<CaseComment> caseComtList = new List<CaseComment>{cmt,cmt2}; 
            insert caseComtList;
            TelusExternalSharingHelperCls.onLocalCaseCommentInsert(caseComtList);
            TelusExternalSharingHelperCls.onLocalCaseCommentUpdate(caseComtList);
        }   
     }
     @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
     @isTest
    static void mapShippingAddress(){
        User testUser = [select Id,Name FROM User Where Name= 'RCESB'];
        System.runAs(testUser){
            Account acc = returnAccount();
            Test_Utils tutilss = new Test_Utils();
            Case newCaseUpdatetouchCases = new Case(recordTypeId = TelusExternalSharingHelperCls.rtMapById.get('Support - Telus').getRecordTypeId(), Type = 'VoIP Assure',
            Partner_BAN_ID__c = '12345', Case_Contact_Email__c = 'rajesh.kumar@simplion.com', Account= acc,Return_Shipping_Address__c = 'add|city|state|123|USA' );
            
            List < Case > touchCasesList= new List < Case > { newCaseUpdatetouchCases};
            tutilss.initialiseTriggerBypass();      
            insert touchCasesList;
                    
            TelusExternalSharingHelperCls.mapTelusAddressToRCAddress(touchCasesList);
        }   
     }
     @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
     @isTest
    static void mapfieldsForTelusCases(){
        User testUser = [select Id,Name FROM User Where Name= 'RCESB'];
        System.runAs(testUser){
            Account acc = returnAccount();
            Test_Utils tutilss = new Test_Utils();
            TelusExternalSharingHelperCls telusExtHelpper = new TelusExternalSharingHelperCls();
            
    
            Case newCaseeshare111 = new Case(recordTypeId = TelusExternalSharingHelperCls.rtMapById.get('Support - Telus').getRecordTypeId(), Type = 'VoIP Assure',
            Partner_BAN_ID__c = '12345', Case_Contact_Email__c = 'rajesh.kumar@simplion.com', case_Contact_Last_Name__c = 'lal',case_Contact_FIRST_Name__c='KK',Account= acc );
            Case newCaseeshare211 = new Case(recordTypeId = TelusExternalSharingHelperCls.rtMapById.get('Support - T1 (Shipping)').getRecordTypeId(), Type = 'VoIP Device Back Order',
            Partner_BAN_ID__c = '1345',case_Contact_Last_Name__c = 'lal',case_Contact_FIRST_Name__c='KK');
            Case newCaseeshare311 = new Case(recordTypeId = TelusExternalSharingHelperCls.rtMapById.get('Porting - In (TELUS)').getRecordTypeId(), Type = 'VoIP Device Back Order'
            ,case_Contact_Last_Name__c = 'lal',case_Contact_FIRST_Name__c='KK');
            Case newCaseeshare411 = new Case(case_Contact_Last_Name__c = 'lal',case_Contact_FIRST_Name__c='KK',recordTypeId = TelusExternalSharingHelperCls.rtMapById.get('Porting - Out').getRecordTypeId(), Type = 'VoIP Device Back Order');
            List < Case > caseList = new List < Case > {
                newCaseeshare111, newCaseeshare211, newCaseeshare311, newCaseeshare411
            };
            tutilss.initialiseTriggerBypass();
            insert caseList;
                    
            TelusExternalSharingHelperCls.mapFieldsForTelusCases(caseList);
            TelusExternalSharingHelperCls.updateBackToPartner(caseList);
        }   
     }
     @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
      @isTest
    static void myUnitupdateProdAssistacForBackOrderCase() {
        User testUser = [select Id,Name FROM User Where Name= 'RCESB'];
        System.runAs(testUser){
            Account acc = returnAccount();
            TelusExternalSharingHelperCls telusExtHelperrr = new TelusExternalSharingHelperCls();
            Test_Utils tutilsss = new Test_Utils();
            Set < Id > caseIdSettt = new Set < Id > ();
    
            Contact con11 = new Contact(FirstName = 'Rajesh', LastName = 'Nehra', email = 'rajesh.kumar@simplion.com',AccountId= Acc.id);
    
            List < Contact > contactList = new List < Contact > {
                con11
            };
            tutilsss.initialiseTriggerBypass();
            insert contactList;
    
            Case newCase1 = new Case(recordTypeId = TelusExternalSharingHelperCls.rtMapById.get('Support - Telus').getRecordTypeId(), Type = 'VoIP Assure',
            Partner_BAN_ID__c = '12345', Product_Assistance__c = 'Company Settings', Support_Disposition_Level_2__c = 'Device on Back Order', Support_Disposition_Level_1__c = 'Billing/Warranty/Shipping',
            Case_Contact_Email__c = 'rajesh.kumar@simplion.com', contact = contactList[0] , Account= acc);
            Case newCase2 = new Case(recordTypeId = TelusExternalSharingHelperCls.rtMapById.get('Support - T1 (Shipping)').getRecordTypeId(), Type = 'VoIP Device Back Order',
            Partner_BAN_ID__c = '1345');
            Case newCase3 = new Case(recordTypeId = TelusExternalSharingHelperCls.rtMapById.get('Porting - In (TELUS)').getRecordTypeId(), Type = 'VoIP Device Back Order');
            Case newCase4 = new Case(recordTypeId = TelusExternalSharingHelperCls.rtMapById.get('Porting - Out').getRecordTypeId(), Type = 'VoIP Device Back Order');
            Case newCase5 = new Case(recordTypeId = TelusExternalSharingHelperCls.rtMapById.get('Support - T1 (Shipping)').getRecordTypeId(), 
                            Type = 'VoIP Device Back Order',Partner_BAN_ID__c = '1345',Support_Disposition_Level_1__c = 'Billing/Warranty/Shipping',
                            Support_Disposition_Level_2__c = 'Device on Back Order');
            List < Case > caseListtt = new List < Case > {
                newCase1, newCase2, newCase3, newCase4, newCase5
            };
            
            insert caseListtt;
            List < Device__c > lstDvc = new List < Device__c > ();
            Device__c dvc = new Device__c(Serial_Number__c = '123', Device_Type__c = 'IP', Case__c = caseListtt.get(0).Id, Instance_ID__c = '1234456');
            lstDvc.add(dvc);
            insert lstDvc;
            for (Case casss: caseListtt) {
                caseIdSettt.add(casss.Id);
            }
    
            TelusExternalSharingHelperCls.updateProdAssistacForBackOrderCase(caseListtt);
            //TelusExternalSharingHelperCls.mapContactOnTelusSharedCases(caseIdSettt);
            TelusExternalSharingHelperCls.mapContactOnTelusSharedCases(caseListtt);
        }
    }
}