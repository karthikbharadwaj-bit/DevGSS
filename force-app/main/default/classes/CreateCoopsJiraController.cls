public class CreateCoopsJiraController {
    @AuraEnabled
    public static String createJira(Id CaseId)
        
    {
        Case cs = [Select Id,Jira__c,CaseNumber,AccountId,Subject,Description,CreatedDate,Brand_Account__c,Case_Severity__c,Account.Name,CaseUID__c,(select id from Contentdocumentlinks) From Case Where Id=:CaseId];
        List<Contentdocumentlink> cd =  new List<Contentdocumentlink>();
        cd = [Select Id FROM ContentDocumentLink Where LinkedEntityId =:CaseId] ;
        
        If(cs.Jira__c==null || cs.Jira__c==''){
            JSONGenerator jsonGen = JSON.createGenerator(true);
            jsonGen.writeStartObject();
            jsonGen.writeFieldName('Case');
            
            jsonGen.writeStartObject();
            jsonGen.writeStringField('Id',cs.Id);
            jsonGen.writeStringField('CaseNumber',cs.CaseNumber);
            if(cs.AccountId == null){
                jsonGen.writeStringField('AccountId','');
            }
            else{
                jsonGen.writeStringField('AccountId',cs.AccountId);
            }
            if(cs.Subject == null){
                jsonGen.writeStringField('Subject','');
            }
            else{
                jsonGen.writeStringField('Subject',cs.Subject);
            }
            if(cs.Description == null){
                jsonGen.writeStringField('Description','');
            }
            else{
                jsonGen.writeStringField('Description',cs.Description);
            }
            jsonGen.writeDateTimeField('CreatedDate',cs.CreatedDate);
            if(cs.Brand_Account__c == null){
                jsonGen.writeStringField('Brand_Account__c','');
            }
            else{
                jsonGen.writeStringField('Brand_Account__c',cs.Brand_Account__c);
            }
            if(cs.Case_Severity__c == null){
                jsonGen.writeStringField('Case_Severity__c','');
            }
            else{
                jsonGen.writeStringField('Case_Severity__c',cs.Case_Severity__c);
            }
            if(cs.Account.Name == null){
                jsonGen.writeStringField('Account_Name__c','');
            }
            else{
                jsonGen.writeStringField('Account_Name__c',cs.Account.Name);
            }
            if(cs.CaseUID__c == null){
                jsonGen.writeStringField('CaseUID__c','');
            }
            else{
                jsonGen.writeStringField('CaseUID__c',cs.CaseUID__c);
            }
            if(cd.size() == 0){
                jsonGen.writeStringField('Attachment','No');
                jsonGen.writeStringField('AttachmentSize','0');
            }
            else{
                jsonGen.writeStringField('Attachment','Yes');
                String cdl = String.valueOf(cd.size()) ;
                jsonGen.writeStringField('AttachmentSize',cdl);
            }
       
            jsonGen.writeEndObject();
            jsonGen.writeEndObject();
            String jsonData = jsonGen.getAsString();
            
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setEndpoint(System.Label.Coops_Jira_Endpoint_URL);
            request.setMethod('POST');
            request.setBody(jsonData);
            request.setTimeout(120000);
            
            String username = System.Label.Coops_Jira_Username;
            String password = System.Label.Coops_Jira_Password;
            
            Blob headerValue = Blob.valueOf(username+':'+password);
            String authorizationHeader = 'BASIC ' +
                EncodingUtil.base64Encode(headerValue);
            request.setHeader('Authorization', authorizationHeader);
            HttpResponse response = new HttpResponse();
            try{
                response = http.send(request); 
            }
            catch(Exception e){
                System.debug('Exception'+e.getMessage());
            }
            if (response.getStatusCode() == 200) {
                Map<String, Object> results = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                String CoopsNumber = String.valueof(results.get('key'));
                String Notice = String.valueof(results.get('Notice'));
                If(Notice == 'Error Occured'){
                    return Notice+' Message' +String.valueof(results.get('Message'));
                }
                else If(Notice != null){
                    return Notice+' Key' +String.valueof(results.get('Jira Key'));
                }
                cs.Jira__c = CoopsNumber;
                update cs;                
                return 'Ticket created key'+ CoopsNumber; 
            }              
        }
        return null;
    }  
}