({
    init: function (component, event, helper) {
        let originalPosition = window.scrollY;

        window.addEventListener('scroll', event => {
            if (window.scrollY != originalPosition) {
                helper.hideLookupList(component);
            }
        })
    },
    lookupEventHandler: function (component, event, helper) {
        var action = event.getParam('action');
        var params = event.getParam('params');
        var guid = event.getParam('guid');
        var isSynced = component.get('v.guid') === guid;

        switch (action) {

            // Show (init) Lookup Init
            case 'showLookupList':
                component.set('v.guid', guid);
                helper.setParams(component, params);
                helper.showLookupList(component);
                helper.setPosition(component);
                break;

            // Update Lookup data
            case 'updateLookupList':
                if (isSynced) {
                    helper.setParams(component, params);
                    helper.setPosition(component);
                }
                break;

            // Hide Lookup List
            case 'hideLookupList':
                if (isSynced) {
                    helper.hideLookupList(component);
                    component.set('v.guid', null);
                }
                break;

        }

    },

    loadMore: function (component) {
        $A.get("e.c:LookupEvent").setParams({
            action: 'loadMore',
            guid: component.get('v.guid')
        }).fire();
    },

    onNewRecordClick: function (component) {
        window.open(component.get('v.newRecordLink'), '_blank');
    }
})