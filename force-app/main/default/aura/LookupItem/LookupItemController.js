({
    select: function (component) {
        $A.get("e.c:LookupEvent").setParams({
            action: 'itemSelected',
            guid:   component.get('v.guid'),
            params: {
                item: component.get('v.item')
            }
        }).fire();
    }
})