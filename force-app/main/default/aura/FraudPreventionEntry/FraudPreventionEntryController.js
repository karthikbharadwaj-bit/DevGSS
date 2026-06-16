({
    init: function (component, event, helper) {
        helper.updateGroupDisplaying(component);
    },

    eventHandler: function(component, event, helper) {
        var eData = event.getParams();

        if(eData.action === 'changeValue') {

            var fieldConfig = component.get('v.fieldConfig');

            var parentFields = [];
            if(fieldConfig.groupList) {
                parentFields = _.map(fieldConfig.items, function(item) {
                    return helper.getParent(item).field;
                });
                parentFields = _.uniq(parentFields);
            } else {
                parentFields.push(helper.getParent(fieldConfig).field);
            }

            if( _.indexOf(parentFields, eData.data.fieldName) > -1 ) {
                helper.updateGroupDisplaying(component);
            }
        }
        else if(eData.action === 'cancel') {
            helper.updateGroupDisplaying(component);
        }
    },
})