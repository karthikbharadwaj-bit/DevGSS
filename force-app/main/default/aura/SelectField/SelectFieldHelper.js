({
    loadField: function (component) {
        let helper = this;
        RC.salesforce.request(component, 'c.getSelectField', {
                sObjectName:    component.get('v.sObjectName'),
                recordTypeName: component.get('v.recordTypeName'),
                fieldName:      component.get('v.fieldName'),
            })
            .then($A.getCallback(r => {
                const options = JSON.parse(r.data.optionsSerialized);
                const describe = JSON.parse(r.data.describeSerialized);

                helper.setPicklist(component, options, describe);
                helper.fireOnReady(component);
            }))
            .catch($A.getCallback(error =>
                RC.salesforce.displayError(`Failed To Load Picklist ${component.get('v.fieldName')}`, error)))
    },

    setPicklist: function(component, options, describe){
        if (!component.get('v.label')){
            component.set('v.label', describe.label);
        }

        if (!component.get('v.options') || component.get('v.options').length === 0){
            component.set('v.options', this.convertOpts(options));
        }

        component.set('v.value', describe.defaultValue);
        component.set('v.value2', describe.defaultValue);
    },

    convertOpts: function(options){
        return options.map(o => {
            return {
                value: o.Value,
                label: o.Label
            }
        })
    },

    fireOnReady: function (component) {
        var onready = component.get('v.onready');
        if (onready) {
            $A.enqueueAction(onready);
        }
    },
});