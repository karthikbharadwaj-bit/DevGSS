/*       
* Created By    : Ishwarya
* Created Date  : 24-03-2020
* Description   : Test class for Lead_UpgradeAction class

Change History
********************************************************************************************************************
SCRUM/Jira          ModifiedBy      Date     Description                             Tag

********************************************************************************************************************

*/
@isTest
public class Test_LeadUpgradeAction {
    
    @isTest
    public static void leadUpgrade(){
        Lead l=new Lead(LastName='Test LName',Company='Test Cmpy',email='abct@test.com',
                        LeadSource='ISV Generated',Industry='Insurance',Status='0. Downgraded',Downgrade_Reason__c='Price');
        insert l;
        Lead_UpgradeAction.upgradeLead(l.Id);
        Test.startTest();
        l.Status='.5 Re-New';
        update l;
        Test.stopTest();
        
        System.assertEquals(l.Status, '.5 Re-New');
    }
    @isTest
    public static void leadUpgradeMethod1(){
        Lead l=new Lead(LastName='Test LName',Company='Test Cmpy',email='abct@test.com',
                        LeadSource='ISV Generated',Industry='Insurance',Status='.5 Re-New');
        
        Test.startTest();
        insert l;
        Lead_UpgradeAction.upgradeLead(l.Id);
        Test.stopTest();
        
        System.assertEquals(l.Status, '.5 Re-New');
    }
}