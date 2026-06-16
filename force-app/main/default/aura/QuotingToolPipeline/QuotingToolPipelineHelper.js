({
    getCartItemsLabel: function(component){
        let list = component.get('v.currentCartItems');
        let _list = [];

        list.forEach(function(listItem) {
            _list = _list.concat(listItem.items);
        });

        return `Cart (${_list.length})`;
    }
});