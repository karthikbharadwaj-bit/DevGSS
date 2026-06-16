({
    toggleExpand: function(component){
        let entity = component.get('v.entity')
            entity.state.isExpanded = !entity.state.isExpanded;
        component.set('v.entity', entity);
    },
})