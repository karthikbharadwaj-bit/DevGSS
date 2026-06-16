@isTest
public class Test_LastCommentByBatch {
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testMethod1(){
        /*List<Deal_Support__c> listDealSupp=new List<Deal_Support__c>();
        Deal_Support__c dealsupport=new Deal_Support__c();
        PartnerRecordsUtil objutil=new PartnerRecordsUtil();
        dealsupport.Partner_Account__c=PartnerRecordsUtil.partnerAccount.Id;
        dealsupport.Partner_Contact__c=PartnerRecordsUtil.partnerContact.Id;
        dealsupport.Name='New Contract Request - Ab-soft';
        dealsupport.Type__c='New Contract Request';
        dealsupport.Status__c='Ready for Signature';
        dealsupport.Discount__c=30;
        //insert dealsupport;
        //  Deal_Support_Comments__c dscom = dealsupport.dealComnts;
        listDealSupp.add(dealsupport);
         PartnerRecordsUtil objutil=new PartnerRecordsUtil();
         Deal_Support__c dealsupport=new Deal_Support__c();
        List<Deal_Support__c> listDealSupp=new List<Deal_Support__c>();
        dealsupport.Partner_Account__c=PartnerRecordsUtil.partnerAccount.Id;
        dealsupport.Partner_Contact__c=PartnerRecordsUtil.partnerContact.Id;
        dealsupport.Name='New Contract Request - Ab-soft';
        dealsupport.Type__c='New Contract Request';
        dealsupport.Status__c='Ready for Signature';
        dealsupport.Discount__c=30;
        //Deal_Support__c  dealsupport = dealCommWrpr.dealSprtObj;
         Deal_Support_Comments__c dscom=new Deal_Support_Comments__c();
        dscom.Deal_Support__c=dealsupport.id;
        listDealSupp.add(dealsupport);*/
        PartnerRecordsUtil util = new PartnerRecordsUtil();
        System.runAs(PartnerRecordsUtil.runAsSysAdmin)
        {
            Deal_Support__c dealsupport1 = PartnerRecordsUtil.createDealSupport();  
            Deal_Support_Comments__c dealsupcomments = new Deal_Support_Comments__c(Comments__c='test',Deal_Support__c=dealsupport1.Id);
            insert dealsupcomments;
            Test.startTest();
            LastCommentByBatch lastCommentBatch=new LastCommentByBatch();
            Id jobid= Database.executeBatch(lastCommentBatch,1);
            Test.stopTest();
            //System.assertEquals( dealsupport1.Last_Comment_By__c, dealsupport1.Deal_Support_Comments__r[0].CreatedById);
        }
    }
}