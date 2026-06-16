public class JiraJsonBuilder {
    public static String build(Case cs, String jiraProjectKey) {
        
        
        JSONGenerator jsonGen = JSON.createGenerator(true);
        jsonGen.writeStartObject();
        jsonGen.writeFieldName('Case');
        jsonGen.writeStartObject();

        jsonGen.writeStringField('Id', cs.Id);
        jsonGen.writeStringField('CaseNumber', cs.CaseNumber);
        jsonGen.writeStringField('AccountId', cs.CaseUID__c == null ? '' : cs.CaseUID__c);
        jsonGen.writeStringField('Subject', cs.Subject == null ? '' : cs.Subject);
        jsonGen.writeStringField('Description', cs.Description == null ? '' : cs.Description);
        jsonGen.writeDateTimeField('CreatedDate', cs.CreatedDate);
        jsonGen.writeStringField('Brand_Account__c', cs.Brand_Account__c == null ? '' : cs.Brand_Account__c);
        jsonGen.writeStringField('Case_Severity__c', cs.Case_Severity__c == null ? '' : cs.Case_Severity__c);
        jsonGen.writeStringField('Account_Name__c', cs.Account.Name == null ? '' : cs.Account.Name);
        jsonGen.writeStringField('CaseUID__c', cs.CaseUID__c == null ? '' : cs.CaseUID__c);
        jsonGen.writeStringField('Number_of_DLs_Account__c', cs.Number_of_DLs_Account__c == null ? '' : String.valueOf(cs.Number_of_DLs_Account__c));
        jsonGen.writeStringField('Tier_Account__c', cs.Tier_Account__c == null ? '' : cs.Tier_Account__c);

        List<ContentDocumentLink> cdLinks = cs.ContentDocumentLinks;
        jsonGen.writeStringField('Attachment', cdLinks.isEmpty() ? 'No' : 'Yes');
        jsonGen.writeStringField('AttachmentSize', String.valueOf(cdLinks.size()));

        List<CaseComment> comments = cs.CaseComments;
        jsonGen.writeStringField('Comments', comments.isEmpty() ? 'No' : 'Yes');
        jsonGen.writeStringField('CommentsCount', String.valueOf(comments.size()));

        jsonGen.writeStringField('Jira_Project', jiraProjectKey);

        jsonGen.writeEndObject(); // end Case
        jsonGen.writeEndObject(); // end root

        return jsonGen.getAsString();
    }
    
    public static String buildForLinking(Id caseId, String jiraNumber) {
        JSONGenerator jsonGen = JSON.createGenerator(true);
        jsonGen.writeStartObject();
        jsonGen.writeFieldName('Case');
        jsonGen.writeStartObject();
        
        jsonGen.writeStringField('Id', caseId);
        jsonGen.writeStringField('Jira__c', jiraNumber);
        
        jsonGen.writeEndObject(); // end Case
        jsonGen.writeEndObject(); // end root
        
        return jsonGen.getAsString();
    }
}