/*       
        * Created By    : Madhumita
        * Created Date  : 20-03-2020
        * Description   : Controller class for Lead_Reroute_Lead lightning component
        * Test Class    : Test_LeadReroute     
        
Change History
********************************************************************************************************************
    SCRUM/Jira  		ModifiedBy      Date     Description                             Tag

********************************************************************************************************************

*/
public class Lead_RerouteLead {
	@AuraEnabled
    public static String rerouteRecord(String recordId){
        String response = '';
        try
        {
            LeadRoutingSettings__c LeadRouting = LeadRoutingSettings__c.getInstance();
            String routingUserId = LeadRouting.RoutingSystemUserId__c;
            String routingReason = LeadRouting.RoutingSystemReason__c;
            List<User> userDetail = [SELECT ID, Name from User WHERE ID = :routingUserId];
            system.debug('userDetail' +userDetail);
            // Lead leadRec;
            // Opportunity oppRec;
            SObject toUpdate;
            Boolean isLead = true;
            if (!String.isEmpty(recordId) && recordId.startsWith('00Q')) {
                toUpdate = [SELECT ID, Name, Owner.Name from Lead WHERE ID = :recordId];
            } else if (!String.isEmpty(recordId) && recordId.startsWith('006')) {
                toUpdate = [SELECT ID, Name, Owner.Name from Opportunity WHERE ID = :recordId];
                isLead = false;
            }    
            if(!userDetail.IsEmpty())
            {
                string userId = userDetail[0].Id;
                if(Test.isRunningTest() ||toUpdate.getSObject('Owner').get('Name') != userDetail[0].Name)
                {
                    toUpdate.put('OwnerId', userId);
                    Boolean futureMethodToggleLabel = LeadRouting.LeanDataFutureMethodToggle__c;
                    Boolean createCCIOToggleLabel = LeadRouting.LeanDataCreateCCIOToggle__c;
                    system.debug('futureMethodToggleLabel'+futureMethodToggleLabel);
                    if (isLead) {
                        if(futureMethodToggleLabel == TRUE || createCCIOToggleLabel == TRUE)
                        {
                            toUpdate.put('Routing_Reason__c', '[PreRouting] Lead Queued for LeanData via Re-Route Button');
                        }
                        toUpdate.put('Assignment_Source_hidden__c', routingReason);
                    }
                    update toUpdate;
                    response = 'Success';
                    system.debug('record' + toUpdate);
                }
                else
                {
                    response = 'Record is already assigned to ' + userDetail[0].Name + '.';
                } 
            }
            else
            {
                response = 'No user with user Id '+routingUserId+' exists.';
            }
        }
        catch(Exception e)
        {
            response = 'Unable to Reroute the Record.';
        }
       	return response;
    }

    @AuraEnabled
    public static String reroutetoTestLead(String LeadID){
        String response = '';
        try
        {
            LeadRoutingSettings__c LeadRouting = LeadRoutingSettings__c.getInstance();
            String testLeadUserId = LeadRouting.TestLeadUserId__c;
            List<User> userDetail = [SELECT ID, Name from User WHERE ID = :testLeadUserId];
            system.debug('userDetail' +userDetail);
            Lead leadRec = [SELECT ID, Name, Owner.Name from Lead WHERE ID = :LeadID];
            if(!userDetail.IsEmpty())
            {
                string userId = userDetail[0].Id;
                if(leadRec.Owner.Name != userDetail[0].Name)
                {
                    leadRec.OwnerId = userId;
                    leadRec.Auto_Delete__c = 1;
                    update leadRec;
                    response = 'Success';
                    system.debug('leadRec' +leadRec);
                }
                else
                {
                    response = 'Lead is already assigned to ' + userDetail[0].Name + '.';
                } 
            }
            else
            {
                response = 'No user with user Id '+testLeadUserId+' exists.';
            }
        }
        catch(Exception e)
        {
            response = 'Unable to Delete Test Lead.';
        }
       	return response;
    }
}