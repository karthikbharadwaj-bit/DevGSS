({
    setParams: function (component) {
        const params = {};
        params.name = component.get('v.data').name;
        params.values = this.getParams(component);

        component.set('v.params', params);
        
        return params;
    },
    
    getParams: function (component) {
        const data = component.get('v.data');
        const selectedOptions = this.getSelectedOptions(data.options);
        const selectedAdditionalOptions = this.getSelectedAdditionalOptions(data.options);

        const params = {};

        if (data.plFieldName) {
            params[data.plFieldName] = this.getReasons(selectedOptions).join(';');
        }

        if (data.plFieldNameDependent) {
            params[data.plFieldNameDependent] = this.getSubReasons(selectedOptions).join(';');
        }

        _.forEach(selectedAdditionalOptions, (saOption) => {
            params[saOption.name] = saOption.value;
        });

        return params;
    },

    getSelectedOptions: function (options, _result) {
        const result = _result || [];

        for (let i = 0; i < options.length; i++) {
            if (options[i].options && options[i].options.length) {
                this.getSelectedOptions(options[i].options, result);
            } else {
                if (options[i].checked) {
                    result.push(options[i]);
                }
            }
        }

        return result;
    },
    
    getSelectedAdditionalOptions: function (options, _result) {
        const result = _result || [];

        _.forEach(options, (option) => {
            _.forEach(option.additionalOptions, (aOption) => {
                aOption.value && result.push(aOption);
            });

            if (option.options && option.options.length) {
                this.getSelectedAdditionalOptions(option.options, result);
            }
        }, this);

        return result;
    },

    getReason: function (item) {
        return item ? (item.parent ? item.parent : item.value) : null;
    },

    getReasons: function (items) {
        const result = [];
        let val;
        
        for (let i = 0; i < items.length; i++) {
            val = items[i] ? (items[i].parent ? items[i].parent : items[i].name) : null;
            val && (result.indexOf(val) === -1) && result.push(val);
        }
        
        return result;
    },

    getSubReason: function (item) {
        return item ? (item.parent ? item.value : null) : null;
    },

    getSubReasons: function (items) {
        const result = [];
        let val;
        
        for (let i = 0; i < items.length; i++) {
            val = items[i] ? (items[i].parent ? items[i].name : null) : null;
            val && result.push(val);
        }
        return result;
    },

    getDetail: function (item) {
        return item ? (item.inputText || null) : null;
    },

    getDetails: function (items, type) {
        const result = [];
        let val;

        for (let i = 0; i < items.length; i++) {
            if (items[i].type === type) {
                val = items[i] ? (items[i].inputText || null) : null;
                val && result.push({
                    option: items[i].parent,
                    suboption: items[i].value,
                    inputText: items[i].inputText,
                });
            }
        }

        return result || null;
    },

    isComplete: function (component, override) {
        const required = !!component.get('v.data.required');
        const isValueSelected = false;
        let isComplete = false;

        if (override) {
            isComplete = override;
        } else if (!required) {
            isComplete = true;
        } else {
            isComplete = true;

            const options = component.get("v.data.options");
            const result = this.checkOptions(options, {isComplete: isComplete, isValueSelected: isValueSelected});

            isComplete = result.isComplete;

            if (required && !result.isValueSelected) {
                isComplete = false;
            }
        }

        component.set("v.isComplete", isComplete);
    },

    checkOptions: function (options, result) {
        _.forEach(options, (option) => {
            if (option.checked) {
                result.isValueSelected = true;

                if (option.error) {
                    result.isComplete = false;
                }

                _.forEach(option.additionalOptions, (aOption) => {
                    if (aOption.error) result.isComplete = false;
                });
            }

            if (option.options) {
                result = this.checkOptions(option.options, result);
            }
        }, this);

        return result;
    },
});