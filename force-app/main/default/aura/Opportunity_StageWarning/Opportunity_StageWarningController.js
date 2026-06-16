({
    doInit: function(component, event, helper){
        component.set('v.showComponent', false);
        helper.checkVisibility(component);
    },
})