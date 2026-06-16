({
    mouseOverInfoIcon: function(component, event, helper){
        helper.showPopover(event.currentTarget, 'info' , component.get('v.infoText'));
    },
    hidePopover: function(component, event, helper){
        helper.hidePopover();
    }
})