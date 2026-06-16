/*--------------------------------------General Description-------------------------------------
 * Purpose - This Apex class is exposed as a REST service to RC Incident Management Portal System.
 * Functionality - When an IMP incident gets close, all the associated cases with the Incident case number should be closed.
 * Created By - India Team
 * Created: Feb 2022
 * -------------------------------------End-----------------------------------------------------*/

@RestResource(urlMapping = '/sf-imp-case-close/*')
global with sharing class SF_IMP_Integration {
    
    global static List<String> incidentNos = new List<String>();
    global static List<Case> caseList = new List<Case>();
    global static Map<String,List<Case>> caseMap = new Map<String,List<Case>>();
    global static Map<Id,Case> caseEmailMap = new Map<Id,Case>();
    global static List<Id> successCases = new List<Id>();
    global static List<Id> failureCases = new List<Id>();
    global static List<String> incidentsNoCase = new List<String>();
    global static String responseBody = '';
    global static RestResponse res = RestContext.response;
    global static List<Messaging.SingleEmailMessage> emailMessages = new List<Messaging.SingleEmailMessage>();

    @HttpPut
    global static void getIncidentNumbers(List<IMPIncidentNumber> incidentList){
        
        try{
            if(incidentList.size() <= 0){
                res.statusCode = 500;
                responseBody = '{'+
                    '"statusCode":500,\n'+
                    '"message":"Incident List is empty"}';
                res.addHeader('Content-Type', 'application/json');
                res.responseBody = Blob.valueOf(responseBody);
            }
            else{
        		for(IMPIncidentNumber inc: incidentList){
            	if(String.isNotBlank(inc.incidentNo)){
                	incidentNos.add(inc.incidentNo);
            	}
        	}
        		system.debug('Incident List: '+incidentNos);
                if(incidentNos.size() <= 0){
                    res.statusCode = 500;
                	responseBody = '{'+
                    '"statusCode":500,\n'+
                    '"message":"Incident Number is empty"}';
                	res.addHeader('Content-Type', 'application/json');
                	res.responseBody = Blob.valueOf(responseBody);
                }
        		else if(incidentNos.size() > 0){
            	system.debug(incidentNos);
            	caseList = [SELECT Id, status, ContactId, Support_Jira__c, contact.email FROM Case WHERE Support_Jira__c = :incidentNos AND Status != 'Closed' AND Type = 'Platform Incident'];
        		caseEmailMap.putAll(caseList);
                for(Case c: caseList){
                    if(!caseMap.containsKey(c.Support_Jira__c)){
                        List<Case> newCaseList = new List<Case>();
                        newCaseList.add(c);
                        caseMap.put(c.Support_Jira__c,newCaseList);
                    }
                    else if(caseMap.containsKey(c.Support_Jira__c)){
                        List<Case> existingCaseList = caseMap.get(c.Support_Jira__c);
                        existingCaseList.add(c);
                        caseMap.put(c.Support_Jira__c,existingCaseList);
                    }
        		}
                
                system.debug('Case Map: '+caseMap);
                
                for(String s: incidentNos){
                    if(!caseMap.containsKey(s)){
                        incidentsNoCase.add(s);
                    }
                }

                for(Case c: caseList){
                    c.status = 'Closed';
                }
        		Database.SaveResult[] srList = Database.update(caseList, false);
                EmailTemplate template = [SELECT Id FROM EmailTemplate WHERE DeveloperName = 'SFDC_IMP_case_closure_email_template' LIMIT 1];
                for(Database.SaveResult sr: srList){
                    if(!sr.isSuccess()){
                        for(Database.Error err: sr.getErrors()){
                            failureCases.add(sr.getId());
                        }
                    }

                    
                   else if(sr.isSuccess()){
                       successCases.add(sr.getId());
                       if(caseEmailMap.get(sr.getId()).ContactId != null){
                        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                        email.setTargetObjectId(caseEmailMap.get(sr.getId()).ContactId);
                        email.setUseSignature(false);
                        email.setBccSender(false);
   						email.setSaveAsActivity(false);
                        email.setTemplateID(template.Id);
   						email.setWhatId(caseEmailMap.get(sr.getId()).Id);
   						email.toAddresses = new String[] {caseEmailMap.get(sr.getId()).contact.email};
                        emailMessages.add(email);
                       }
                    }
                }
                if(emailMessages.size() > 0){
                    Messaging.SendEmailResult[] results = Messaging.sendEmail(emailMessages);
                }
                res.statusCode = 200;
                responseBody = '{'+
                    '"statusCode": 200,\n'+
                    '"SuccessfullyClosedSFCaseNumbers": ['+String.join(successCases, ',')+'],\n'+
                    '"UnsuccessfulClosedSFCaseNumber": ['+String.join(failureCases,',')+'],\n'+
                    '"incidentWithNoSFCases": ['+String.join(incidentsNoCase,',')+']\n'+
                    '}';
                res.addHeader('Content-Type', 'application/json');
                res.responseBody = Blob.valueOf(responseBody);
        }
            }
    }
        catch(Exception e){
            Id recordTypeId = Schema.SObjectType.Exception_And_Notification_History__c.getRecordTypeInfosByName().get('Exception History').getRecordTypeId();
            Exception_And_Notification_History__c exc = new Exception_And_Notification_History__c(
            											Exception__c = 'SF-IMP Error',
                										Exception_Desc__c = e.getStackTraceString()+ '\n'+e.getMessage(),
            											RecordTypeId = recordTypeId);
            insert exc;
            responseBody = '{'+'"statusCode":500,\n'+'"message": "Platform Error, Please Contact RC SF Team. Exception Id: '+String.valueOf(exc.Id)+'"}';
            res.statusCode = 500;
            res.addHeader('Content-Type', 'application/json');
            res.responseBody = Blob.valueOf(responseBody);
        }
    }
    
    global class IMPIncidentNumber{
        global String incidentNo{get;set;}
    }
}