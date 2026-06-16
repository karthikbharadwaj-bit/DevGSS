({
    doInit: function(component, event, helper){
        var classes = helper.getClasses();
        component.set('v.Modals', new classes.Modals() );
    },

    onModalRequestEvent: function(component, event, helper){
        var params = event.getParams();
        var Modals = component.get('v.Modals');

        Modals.add( params );

        component.set('v.Modals', Modals);
    }

});