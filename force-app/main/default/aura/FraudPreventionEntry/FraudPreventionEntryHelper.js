({
    updateGroupDisplaying: function(component) {
        var helper = this;
        var formObject = component.get('v.formObject');
        var fieldConfig = component.get('v.fieldConfig');

        if(!formObject) {
            // console.error(fieldConfig.name + ' has not formObject');
            return;
        }

        fieldConfig.display = false;

        if(fieldConfig.groupList) {
            var atLeastOneShown = false;
            _.forEach(fieldConfig.items, function(subItem) {
                var params = helper.getItemParams(subItem, formObject);
                if(helper.isDefault(params) || helper.isAny(params) || helper.isEqual(params)) {
                    fieldConfig.display = true;
                    atLeastOneShown = true;
                }
            });
            fieldConfig.display = atLeastOneShown;
        } else {
            var params = helper.getItemParams(fieldConfig, formObject);
            if(helper.isDefault(params) || helper.isAny(params) || helper.isEqual(params)) {
                fieldConfig.display = true;
            }
        }

        component.set('v.fieldConfig', fieldConfig);
    },

    getItemParams: function(item, formObject) {
        return {
            fieldValue: formObject[this.getParent(item).field],
            parentValue: this.getParent(item).value,
        }
    },

    getParent: function(fieldConfig) {
        return {
            field: fieldConfig.parentValue && fieldConfig.parentValue.split('%%')[0],
            value: fieldConfig.parentValue && fieldConfig.parentValue.split('%%')[1],
        }
    },

    isDefault: function(params) {
        return params.parentValue === 'default';
    },

    isAny: function(params) {
        return (params.fieldValue && params.parentValue == 'any');
    },

    isEqual: function(params) {
        return (this.getValue(params.parentValue) === this.getValue(params.fieldValue));
    },

    getValue: function(value) {
        var result = value;

        if(_.isString(value)) {
            result = value.toLowerCase();

            if(result === 'true')
                result = true;
            else if(result === 'false')
                result = false;
        }

        return result;
    },

    getKey: function(formObject, fieldName) {
        var result = _.findKey(formObject, function(value, key) {
            return key.toLowerCase() === fieldName.toLowerCase();
        });

        return result ? result : fieldName;
    },
})