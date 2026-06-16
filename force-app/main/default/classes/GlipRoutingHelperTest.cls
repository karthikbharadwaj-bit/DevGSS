@isTest
private class GlipRoutingHelperTest {

  @isTest static void testGlipRouting(){
    Glip_Routing_Settings__c glipSettings = new Glip_Routing_Settings__c();
    glipSettings.RC_ClientId__c = 'X';
    glipSettings.RC_ClientSecret__c = 'X';
    glipSettings.RC_Server__c = 'X';
    glipSettings.RC_BotId__c = 'X';
    glipSettings.RC_BotEmail__c = 'X';
    insert glipSettings;
    LeadSelector leadSelector = new LeadSelector();
    Lead newLead = (Lead) new SObjectBuilder(Lead.SObjectType)
                                            .setField(Lead.LastName, 'Testerson')
                                            .setField(Lead.Company, 'Testly test')
                                            .setField(Lead.Email, 'fake@email.com')
                                            .setField(Lead.LeadSource, 'Lead Generation')
                                            .create()
                                            .getRecord();
    newLead = (Lead) leadSelector.selectLeadById(new List<Object>{newLead.Id}).selectField('OwnerId').executeQuery()[0];

    Test.setMock(HttpCalloutMock.class, new GlipRoutingHelper.MockGlipResponder());
    String nodeEdge;

    Test.startTest();
    nodeEdge = GlipRoutingHelper.sendGlipNotification(newLead, newLead.OwnerId, (Id) new ValueProvider.DummyIdProvider(EmailTemplate.sObjectType).getValue());
    Test.stopTest();

    System.assertEquals(nodeEdge, 'Next Node');
  }

}