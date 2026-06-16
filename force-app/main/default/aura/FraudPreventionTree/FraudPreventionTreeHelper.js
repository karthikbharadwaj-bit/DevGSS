({
	getGroup: function(group, name) {
        return {
            name: name || null,
            label: name || null,
            items: Array.isArray(group) ? group : [group],
        }
	},

    sortByOrder: function(field) {
        if(field.items) {
            field.items = _.sortBy(field.items, 'sortOrder').reverse();

            field.items.map(this.sortByOrder.bind(this));
        }

        if(field.children) {
            field.children = _.sortBy(field.children, 'sortOrder').reverse();
            field.children.map(this.sortByOrder.bind(this));
        }

        return field;
    }
})