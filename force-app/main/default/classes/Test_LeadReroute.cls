/*       
* Created By    : Ishwarya
* Created Date  : 24-03-2020
* Description   : Test class for Lead_RerouteLead class

Change History
********************************************************************************************************************
SCRUM/Jira          ModifiedBy      Date     Description                             Tag

********************************************************************************************************************

*/
@isTest
public class Test_LeadReroute {
    @isTest
    public static void leadReroute(){
        LeadRoutingSettings__c LeadRouting = LeadRoutingSettings__c.getInstance();
        Lead l=new Lead(LastName='Test LName',Company='Test Cmpy',email='abct@test.com',
                        LeadSource='ISV Generated',Industry='Insurance',Status='2. Contacted',
                        Routing_Reason__c='testing',Assignment_Source_hidden__c='testii');
        
        LeadRouting.RoutingSystemUserId__c=UserInfo.getUserId();
        LeadRouting.RoutingSystemReason__c='test';
        LeadRouting.LeanDataFutureMethodToggle__c=TRUE;
        LeadRouting.LeanDataCreateCCIOToggle__c=TRUE;
        insert LeadRouting;
        insert l;
        
        Test.startTest();
        Lead_RerouteLead.rerouteRecord(l.Id);
        Test.stopTest();
        
        l=  [SELECT Id,Status, FirstName,LastName,Company,LeadSource,Routing_Reason__c,Assignment_Source_hidden__c FROM Lead WHERE Id = :l.Id];
        system.assertEquals(l.Routing_Reason__c,'[PreRouting] Lead Queued for LeanData via Re-Route Button');
        system.assertEquals(l.Assignment_Source_hidden__c,LeadRouting.RoutingSystemReason__c);
    }

    @isTest
    public static void leadReroutetoTestLeadUser(){
        
        LeadRoutingSettings__c LeadRouting = LeadRoutingSettings__c.getInstance();
        Lead l=new Lead(LastName='Test LName',Company='Test Cmpy',email='abct@test.com',
                        LeadSource='ISV Generated',Industry='Insurance',Status='2. Contacted',
                        Routing_Reason__c='testing',Assignment_Source_hidden__c='testii');
        
        LeadRouting.TestLeadUserId__c =UserInfo.getUserId();
        insert LeadRouting;
        insert l;
        
        Test.startTest();
        Lead_RerouteLead.reroutetoTestLead(l.Id);
        Test.stopTest();
        
        l=  [SELECT Id,Status, FirstName,LastName,Company,LeadSource,Routing_Reason__c,Assignment_Source_hidden__c, Auto_Delete__c, Owner.Name FROM Lead WHERE Id = :l.Id];
        system.assertEquals(l.Auto_Delete__c, 1);
    }
}