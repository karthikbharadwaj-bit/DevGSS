({
    onTemplatePanelEvent: function(component, event, helper){
        var params = event.getParams();
        console.log('navigate',params);
        if(params.target === 'sectionBuilder'){
            helper.openSectionBuilder(component, params.templateId, params.sectionId);
        } else if (params.target === 'templateList'){
            helper.getTemplates(component);
            helper.openTemplateList(component);
        } else if (params.target === 'templateView'){
            helper.openTemplateView(component);
        } else if (params.target === 'refreshTemplates'){
            helper.getTemplates(component);
        }
    },
    templatePanelHelperLoaded: function(component, event, helper){
        helper.getTemplates(component);
    }
});