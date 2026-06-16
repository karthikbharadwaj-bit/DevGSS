({
    hidePopover: function(){
        $A.get("e.c:PopoverEvent").setParams({
            show: false
        }).fire();
    },
    mouseOverInfoIcon: function(component, event, helper){
        helper.showPopover(component, event.currentTarget, 'infoText', 'info');
    },
    mouseOverWarningIcon: function(component, event, helper){
        helper.showPopover(component, event.currentTarget, 'warningText', 'warning');
    },
    mouseOverCancelIcon: function(component, event, helper){
        helper.showPopover(component, event.currentTarget, 'cancelText', 'ban');
    },
    mouseOverAreaCodesIcon: function(component, event, helper){
        helper.showPopover(component, event.currentTarget, 'areaCodesText', 'info');
    }
})