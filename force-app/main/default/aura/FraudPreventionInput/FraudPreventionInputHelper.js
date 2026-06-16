({
    setValue: function(component) {
        try {

            var formObject = component.get("v.formObject");
            var fieldConfig = component.get("v.fieldConfig");
            var fieldName = component.get("v.fieldName");
            var value = null;

            if (formObject) value = formObject[fieldName];

            if(value && fieldConfig.type === 'checkbox') {
                value  = JSON.parse(value);
            }

            // for select
            if( fieldConfig.type === 'select' ) {
                value = value ? String(value).toLowerCase() : value;

                var options = component.get('v.options')
                if(!options.length) {
                    options = _.map(fieldConfig.values, function(o) {
                        return {
                            value: o && o.toLowerCase(),
                            label: o,
                        }
                    });
                }
                component.set('v.options', options);
            }

            component.set("v.value", value);
        } catch (e) {
            console.log(e);
        }
    },

    setError: function(component, message) {
        component.set('v.errorMessage', message);
    },

    validate: function(component) {
        var fieldConfig = component.get("v.fieldConfig");
        var value = component.get("v.value");
        var result = null;

        // if date is required
        if(fieldConfig.type == 'date' && fieldConfig.required && this.isEmpty(value)) {
            result = 'Complete this field';
        }

        var name = component.get("v.fieldName");
        var settings = component.get('v.settings');
            settings.errors[name] = result;

        component.set('v.settings', settings);
        this.setError(component, settings.errors[name]);
    },

    isEmpty: function(value) {
        return $A.util.isEmpty(value);
    },

    getKey: function(formObject, fieldName) {
        var result = _.findKey(formObject, function(value, key) {
            return key.toLowerCase() === fieldName.toLowerCase();
        });

        return result ? result : fieldName;
    },
});