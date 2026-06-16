({
    getGroup: function(group, name) {
        var items = Array.isArray(group) ? group : [group];

        return {
            name: name || null,
            label: (name && name !== '__null__') ? name : null,
            sortOrder: _.max(items, function(item){ return item.sortOrder; }).sortOrder,
            items: items,
            groupList: true,
        }
    },
})