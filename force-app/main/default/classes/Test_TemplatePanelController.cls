@IsTest
private class Test_TemplatePanelController {

    @IsTest
    static void testGetTemplates() {
        RC_Quote_Template__c rcQuoteTemplate = (RC_Quote_Template__c) new SObjectBuilder(RC_Quote_Template__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    RC_Quote_Template__c.Name => 'Test RCQTemplate',
                    RC_Quote_Template__c.Active__c => true
                }
            )
            .create()
            .getRecord();

        System.assert(rcQuoteTemplate.Id != null);

        Test.startTest();
        List <RC_Quote_Template__c> templates = TemplatePanelController.getTemplates(null);
        System.assert(!templates.isEmpty());
        Test.stopTest();
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @IsTest
    static void testGetSections() {
        Test.startTest();
        TemplatePanelController.getSections();
        Test.stopTest();
    }

    @IsTest
    static void testSaveSection() {
        TemplateSections__c section  = (TemplateSections__c) new SObjectBuilder(TemplateSections__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    TemplateSections__c.Name => 'Test Section Name'
                }
            )
            .create()
            .getRecord();
        System.assert(section.Id != null);

        String content = 'TEST';
        String styles = 'body{font-size: 12pt;}';

        Test.startTest();
        TemplatePanelController.saveSection(section.Id, content, styles);
        Test.stopTest();
    }

    @IsTest
    private static void testIsTemplate() {
        RC_Quote_Template__c rcQuoteTemplate = (RC_Quote_Template__c) new SObjectBuilder(RC_Quote_Template__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    RC_Quote_Template__c.Name => 'Test RC QTemplate',
                    RC_Quote_Template__c.Active__c => true
                }
            )
            .create()
            .getRecord();

        System.assert(rcQuoteTemplate.Id != null);
        Boolean isTemplate = TemplatePanelController.isTemplate(rcQuoteTemplate.Id);
        System.assert(isTemplate);

        TemplateSections__c templateSection = (TemplateSections__c) new SObjectBuilder(TemplateSections__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    TemplateSections__c.Name => 'Test TS'
                }
            )
            .create()
            .getRecord();

        System.assert(templateSection.Id != null);

        Boolean isNotTemplate = !TemplatePanelController.isTemplate(templateSection.Id);
        System.assert(isNotTemplate);
    }
}