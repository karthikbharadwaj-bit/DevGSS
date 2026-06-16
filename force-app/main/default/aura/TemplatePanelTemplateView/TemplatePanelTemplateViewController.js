({
    openTemplateList: function (component, event, helper) {
        $A.get("e.c:TemplatePanelEvent").setParams({
            target: 'templateList'
        }).fire();
    }
})