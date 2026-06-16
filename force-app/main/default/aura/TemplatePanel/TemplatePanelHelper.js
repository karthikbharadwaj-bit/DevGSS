/* global TP */
({

    getTemplates: function(component){
        $A.util.addClass(component.get('templateListContainer'), 'templates-loading');
        var templateId = component.get("v.templateId");
        TP.salesforce.request(component, 'c.getTemplates', {'templateId': templateId})
            .then($A.getCallback(function(templates) {
                console.log('templates',templates);
                component.set('v.templates', templates);
                $A.util.removeClass(component.get('templateListContainer'), 'templates-loading');
            }));

        TP.salesforce.request(component, 'c.getSections')
            .then($A.getCallback(function(sections) {
                console.log('sections',sections);
                component.set('v.sections', sections);
            }));
    },
    openSectionBuilder: function(component, templateId, sectionId){
        var sectionBuilderContainer = component.find('sectionBuilderContainer');
        var templateListContainer = component.find('templateListContainer');

        $A.util.removeClass(sectionBuilderContainer, 'slds-hide');
        $A.util.addClass(templateListContainer, 'slide-out--left');

        setTimeout($A.getCallback(function() {
            $A.util.addClass(templateListContainer, "slds-hide");
            $A.util.removeClass(sectionBuilderContainer, "slide-out--right");
        }), 300);

    },
    openTemplateList: function(component){
        var sectionBuilderContainer = component.find('sectionBuilderContainer');
        var templateListContainer = component.find('templateListContainer');
        var templateViewContainer = component.find('templateViewContainer');

        $A.util.removeClass(templateListContainer, 'slds-hide');
        $A.util.addClass(sectionBuilderContainer, 'slide-out--right');
        $A.util.addClass(templateViewContainer, 'slide-out--right');

        setTimeout($A.getCallback(function() {
            $A.util.addClass(sectionBuilderContainer, "slds-hide");
            $A.util.addClass(templateViewContainer, "slds-hide");
            $A.util.removeClass(templateListContainer, "slide-out--left");
        }), 300);
    },
    openTemplateView: function(component){
        var templateViewContainer = component.find('templateViewContainer');
        var templateListContainer = component.find('templateListContainer');

        $A.util.removeClass(templateViewContainer, 'slds-hide');
        $A.util.addClass(templateListContainer, 'slide-out--left');

        setTimeout($A.getCallback(function() {
            $A.util.addClass(templateListContainer, "slds-hide");
            $A.util.removeClass(templateViewContainer, "slide-out--right");
        }), 300);
    },
})