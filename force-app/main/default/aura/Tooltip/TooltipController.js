({
  onMouseOver: function(component, event, helper){
    helper.showPopover(event.currentTarget, component.get('v.text'), component.get('v.theme'), component.get('v.iconCollection'));
  },
  onMouseOut: function(component, event, helper){
    $A.get("e.c:PopoverEvent").setParams({ show: false }).fire();
  },
})