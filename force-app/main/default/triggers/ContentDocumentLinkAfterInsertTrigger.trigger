//Developer: ratul.saha@ringcentral.com, 
//JIRA: PRM-58
//Test class: Test_ContentDocumentLinkTrigger
trigger ContentDocumentLinkAfterInsertTrigger on ContentDocumentLink (after insert) {
  if(trigger.isafter && trigger.isinsert) {
    ContentDocumentLinkTriggerHandler.handleCaseContentDocumentLinks(trigger.new);
  }
}