({
    doInit: function(component, event, helper){
        var layoutItem = component.get('v.layoutItem');
        helper.getUserProfile(component)
            .then($A.getCallback(function (profileName) {
                component.set('v.profileName', profileName);
            }))
            .then($A.getCallback(function () {
                var profileName = component.get('v.profileName');
                if (layoutItem.field &&
                    (layoutItem.behavior != 'Readonly' || profileName === 'System Administrator')){
                    helper.createField(component);
                } else if (layoutItem.page_x
                    && helper.isPageEnabled(component.get('v.enabledPages'), layoutItem.page_x)){
                    helper.createPage(component);

                } else {
                    component.find('LoadingPlaceholder').set('v.isShown', false);
                }
            }));
    },
    onchange: function (component, event) {
        var record = component.get('v.record');
        // record[component.get('v.layoutItem.field')] = event.getSource().get('v.value');
        record[component.get('v.layoutItem.field')] = component.find('inputField').get('v.value');
        component.set('v.record', record);
    }
});