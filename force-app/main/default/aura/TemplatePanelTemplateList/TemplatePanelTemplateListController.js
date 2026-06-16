({
    openSectionBuilder: function(component, event, helper){
        var sections = component.get('v.sections');
        var templates = component.get('v.templates');
        var params = event.currentTarget.dataset;
        var selectedSection = sections.filter(function(section){
            return section.Id === params.sectionid})[0];
        component.set('v.selectedSection',selectedSection);

        var selectedTemplate = templates.filter(function(template){
            return template.Id === params.templateid})[0];
        component.set('v.selectedTemplate',selectedTemplate);

        $A.get("e.c:TemplatePanelEvent").setParams({
            target: 'sectionBuilder'
        }).fire();
    },
    openTemplateView: function(component, event, helper){
        var templates = component.get('v.templates');
        var params = event.currentTarget.dataset;

        component.set('v.selectedSection',null);

        var selectedTemplate = templates.filter(function(template){
            return template.Id === params.templateid})[0];
        component.set('v.selectedTemplate',selectedTemplate);

        $A.get("e.c:TemplatePanelEvent").setParams({
            target: 'templateView'
        }).fire();

    }
})