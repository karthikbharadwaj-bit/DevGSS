@isTest
private class Test_AgentCreditSelector {
	//Account fields defined
    private static final String ACCOUNT_NAME = 'Test';
    private static final String ACCOUNT_BILLING_ID = '12345';
    
    //Agent credit fields defined
    private static final String AGENT_CREDIT_NAME = 'TestNameForAC';
    private static final String AGENT_CREDIT_FIRST_NAME = 'Test AC';
        
    //Assert messages defined
    private static final String ASSERT_MESSAGE = 'Agent credit should be selected';
    private static final String ASSERT_EQUALS_MESSAGE = 'Wrong agent credit selected';
    
    @testsetup
    private static void testData(){
        Account testAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => ACCOUNT_NAME,
                    Account.Billing_ID__c => ACCOUNT_BILLING_ID
                }
            )
            .create()
            .getRecord();
        
        Agent_Credit__c testAC = (Agent_Credit__c) new SObjectBuilder(Agent_Credit__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Agent_Credit__c.Account__c => testAcc.Id,
                    Agent_Credit__c.Name => AGENT_CREDIT_NAME,
                    Agent_Credit__c.Agent_First_Name__c => AGENT_CREDIT_FIRST_NAME
                }
            )
            .create()
            .getRecord();
    }
    
    @isTest
    private static void testSelectAgentCredits(){
        List<Agent_Credit__c> agentCredits = (List<Agent_Credit__c>) new AgentCreditSelector(true, true)
            .selectAgentCredits()
        	.executeQuery();
       	
        System.assert(agentCredits.size() == 1 ,ASSERT_MESSAGE);
    }
    
    @isTest
    private static void testSelectAgentCreditsForApproval(){
        List<Agent_Credit__c> agentCredits = (List<Agent_Credit__c>) new AgentCreditSelector()
            .selectAgentCredits()
        	.executeQuery();
        
        List<Agent_Credit__c> agentCreditsForApproval = (List<Agent_Credit__c>) new AgentCreditSelector()
            .selectAgentCreditsForApproval(new List<Object>{new Set<Id>{agentCredits[0].Id}})
        	.executeQuery();
        
        System.assert(agentCreditsForApproval.size() == 1 ,ASSERT_MESSAGE);
        System.assertEquals(agentCreditsForApproval[0].Id, agentCredits[0].Id, ASSERT_EQUALS_MESSAGE);
    }
}