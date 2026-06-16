public class TemplatePanelController {

    @AuraEnabled
    public static List <RC_Quote_Template__c> getTemplates(String templateId) {
        String condition = (!String.isEmpty(templateId) && isTemplate(templateId)) ? 'Id = :bind0' : 'Id != null';

        List<RC_Quote_Template__c> rcQuoteTemplates = new RCQuoteTemplateSelector()
            .selectRCQuoteTemplates().withoutSelectorFieldsIncluded()
            .selectFields(new Set<String>{'Id', 'CSS_Styles_1__c', 'Template_Engine__c', 'Active__c', 'Parameters__c'})
            .setQueryBindings(new List<Object>{templateId})
            .subselect(new TemplateSectionJunctionSelector().selectSectionJunctions().withoutSelectorFieldsIncluded()
                .withoutSelectorOrderByIncluded()
                .selectFields(new Set<String> {'Template_Section__c', 'Position__c', 'Template_Section__r.Name'})
                .addOrdering('Position__c', QueryFactory.SortOrder.ASCENDING)
                .addOrdering('LastModifiedDate', QueryFactory.SortOrder.DESCENDING))
            .setCondition(condition)
            .executeQuery();

        return rcQuoteTemplates;
    }

    @TestVisible
    private static Boolean isTemplate(String Id) {
        String objectAPIName = '';
        String keyPrefix = Id.substring(0, 3);
        SObjectDescribeHelper templateDescribe = SObjectDescribeHelper.getDescribe(RC_Quote_Template__c.class.getName());

        String prefix = templateDescribe.getSObjectType().getDescribe().getKeyPrefix();

        if (keyPrefix.equals(prefix)) {
            objectAPIName = templateDescribe.getDescribe().getName();
        }
        return RC_Quote_Template__c.class.getName().equalsIgnoreCase(objectAPIName);
    }

    @AuraEnabled
    public static List <TemplateSections__c> getSections() {
        return [
                SELECT Id, Name, CSS_Styles_1__c,
                        Content_1__c, Content_2__c, Content_3__c, Content_4__c, Content_5__c
                FROM TemplateSections__c
        ];
    }

    @AuraEnabled
    public static void saveSection(String sectionId, String content, String styles ) {

        TemplateSections__c section = new TemplateSections__c(
                Id = sectionId,
                Content_1__c = content,
                CSS_Styles_1__c = styles
        );

        update section;

    }

}