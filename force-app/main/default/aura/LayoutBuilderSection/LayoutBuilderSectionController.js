({
    doInit: function(component, event, helper){
        helper.createContent(component);
    },
    toggleSection: function(component){
        $A.util.toggleClass(component.find('section'),'slds-is-open');
    }
});