trigger KnowledgeTrigger on Knowledge__kav (before insert, before update, before delete, after insert, after update, after delete, after undelete) {

        KCSSettings__c featureToggle = KCSSettings__c.getInstance();
        Boolean isDisableKnowledgeArticleTrigger =
            featureToggle != null && featureToggle.DisableKnowledgeArticleTrigger__c;
        
        if (!Test.isRunningTest() && isDisableKnowledgeArticleTrigger) {
            return;
        }

    new Triggers()
        .bind(Triggers.Evt.beforeInsert, new KnowledgeArticleTriggerHelper.KCSBeforeCreateHandler())
        .bind(Triggers.Evt.afterInsert, new KnowledgeArticleTriggerHelper.KCSAfterCreateHandler())
        .bind(Triggers.Evt.afterUpdate, new KnowledgeArticleTriggerHelper.HandleContentDeletion())
        .bind(Triggers.Evt.beforeUpdate, new KnowledgeArticleTriggerHelper.KCSBeforeUpdateHandler())
        .manage();
}