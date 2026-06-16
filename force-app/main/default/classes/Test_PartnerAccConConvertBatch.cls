@isTest
public class Test_PartnerAccConConvertBatch{

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testMethod1() {
        // this is used to create needed test data
        new PartnerRecordsUtil();
        List<Partner_Request__c> partnerRequestList = new List<Partner_Request__c>();
            Partner_Request__c partnerObj = new Partner_Request__c();
            partnerObj.Partner_First_Name__c = 'Test Avaya';
            partnerObj.Partner_Last_Name__c ='Partner';
            partnerObj.Partner_Company_Name__c = 'Test Avaya Company';
            partnerObj.Partner_Address1__c = 'Test Address';
            partnerObj.Partner_City__c = 'Test City';
            partnerObj.Partner_State__c ='ALASKA';
            partnerObj.Partner_Zip__c='123456';
            partnerObj.Partner_Country__c='Germany';
            partnerObj.Partner_Phone__c='7895412630';
            partnerObj.Partner_Email_Address__c='testrc@lister.com';
            partnerObj.Partner_Portal_View__c='Full';
            partnerObj.Avaya_Partnership_Reg__c = true;
            partnerObj.Partner_Role__c = 'General Partner';
            partnerObj.Partner_Type__c ='RingCentral';
            partnerObj.Brand_Name__c='RingCentral';
            partnerObj.AD__c = 'No';
            partnerObj.Ready_For_Processing__c=True;
            partnerObj.PR_Processed__c=false;
            try{
                    Test.startTest();
                    Database.insert(partnerObj);
                    partnerRequestList.add(partnerObj);

            }catch(Exception e){

            }
           PartnerAccountContactConvertBatch partnerBacth = new PartnerAccountContactConvertBatch();
            PartnerAccConConvertBatchScheduler sch = new PartnerAccConConvertBatchScheduler();
            String jobID1 = system.schedule('Partner Account Contact convert for RC'+system.now(), '0 0 * * * ?', sch);                    Test.stopTest();

        }
}