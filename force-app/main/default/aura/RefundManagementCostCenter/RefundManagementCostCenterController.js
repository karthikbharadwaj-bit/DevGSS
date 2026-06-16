({
    toggleExpand: function (component, event, helper) {
        if(component.get('v.entity.state.isExpandable')) {
            helper.toggleExpand(component);
        }
    },
});