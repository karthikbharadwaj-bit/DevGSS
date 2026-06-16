@isTest
private class Test_EmailTemplateSelector {
	
    //Email template fields defined
    private static final String EMAIL_TEMPLATE_DEVELOPER_NAME = 'TestDevName';
    private static final String EMAIL_TEMPLATE_BODY = 'Email body';
    private static final String EMAIL_TEMPLATE_TYPE = 'text';
    private static final String EMAIL_TEMPLATE_NAME = 'Test Query';
    private static final String EMAIL_TEMPLATE_SUBJECT = 'Just testing';

    //Assert message defined
    private static final String ASSERT_MESSAGE = 'Email templates should be selected';
    private static final String ASSERT_EQUALS_MESSAGE = 'Wrong email template selected';

    @testSetup 
    private static void testData() {
        EmailTemplate e = (EmailTemplate) new SObjectBuilder(EmailTemplate.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    EmailTemplate.DeveloperName => EMAIL_TEMPLATE_DEVELOPER_NAME,
                    EmailTemplate.Body => EMAIL_TEMPLATE_BODY,
                    EmailTemplate.FolderId => UserInfo.getUserId(),
                    EmailTemplate.TemplateType => EMAIL_TEMPLATE_TYPE,
                    EmailTemplate.Name => EMAIL_TEMPLATE_NAME,
                    EmailTemplate.Subject => EMAIL_TEMPLATE_SUBJECT
                }
            )
            .create()
            .getRecord();
    }
    
    @isTest
    private static void testSelectEmailTemplates(){
        List<EmailTemplate> emailTemplates = (List<EmailTemplate>) new EmailTemplateSelector(true, true)
            .selectEmailTemplates()
            .executeQuery();  
        
        System.assert(emailTemplates.size() == 1, ASSERT_MESSAGE);
    }
    
    @isTest
    private static void testSelectEmailTemplateByDeveloperName(){
        List<EmailTemplate> emailTemplateByDeveloperName = (List<EmailTemplate>) new EmailTemplateSelector()
            .selectEmailTemplateByDeveloperName(new List<Object>{new Set<String>{EMAIL_TEMPLATE_DEVELOPER_NAME}})
            .executeQuery();  
        
        System.assert(emailTemplateByDeveloperName.size() == 1, ASSERT_MESSAGE);
    }
        
    @isTest
    private static void testSelectEmailTemplatesByDeveloperNames(){
        List<EmailTemplate> emailTemplatesByDeveloperNames = (List<EmailTemplate>) new EmailTemplateSelector()
            .selectEmailTemplatesByDeveloperNames(new List<String>{EMAIL_TEMPLATE_DEVELOPER_NAME}, true)
            .executeQuery();  
        
        System.assert(emailTemplatesByDeveloperNames.size() == 1, ASSERT_MESSAGE);
    }
        
    
    @isTest
    private static void testSelectEmailTemplateById(){
        List<EmailTemplate> emailTemplates = (List<EmailTemplate>) new EmailTemplateSelector()
            .selectEmailTemplates()
            .executeQuery();  

        List<EmailTemplate> emailTemplateById = (List<EmailTemplate>) new EmailTemplateSelector()
            .selectEmailTemplateById(new List<String>{emailTemplates[0].Id})
            .executeQuery();  
        
        System.assert(emailTemplateById.size() == 1, ASSERT_MESSAGE);
        System.assertEquals(emailTemplates[0].Id, emailTemplateById[0].Id, ASSERT_EQUALS_MESSAGE);
    }
    
    @isTest
    private static void testSelectEmailTemplatesByIds(){
        List<EmailTemplate> emailTemplates = (List<EmailTemplate>) new EmailTemplateSelector()
            .selectEmailTemplates()
            .executeQuery();  
            
        List<EmailTemplate> emailTemplatesByIds = (List<EmailTemplate>) new EmailTemplateSelector()
            .selectEmailTemplatesByIds(new List<Object>{new Set<Id>{emailTemplates[0].Id}})
            .executeQuery();  
        
        System.assert(emailTemplatesByIds.size() == 1, ASSERT_MESSAGE);
        System.assertEquals(emailTemplates[0].Id, emailTemplatesByIds[0].Id, ASSERT_EQUALS_MESSAGE);
    }
}