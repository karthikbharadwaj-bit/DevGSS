({
    init: function(component, event, helper) {
        try {

            var items = component.get('v.items');

            var groupedItems = _.filter(items, function(item) {
                    return item.isGroup;
                })
                groupedItems = _.groupBy(groupedItems, function(item){
                    return item.groupLabel ? item.groupLabel.toLowerCase() : '__null__';
                });
                groupedItems = _.map(groupedItems, function(group, name){
                    return helper.getGroup(group, name);
                });

            var loneItems = _.filter(items, function(item) {
                    return !item.isGroup;
                });
                // loneItems = _.map(loneItems, function(group) {
                //     return helper.getGroup(group);
                // });

            groupedItems = groupedItems.concat(loneItems);
            groupedItems = _.sortBy(groupedItems, 'sortOrder').reverse();

            component.set('v.groupedItems', groupedItems);
        } catch (e) {
            console.log(e);
        }
    },
})