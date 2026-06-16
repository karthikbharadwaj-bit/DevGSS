({
    /**
     * Show List Box
     */
    showListbox: function (component) {
        if (component.get('v.listIsRelative')) {
            var combobox = component.find('combobox');
            $A.util.addClass(combobox, 'slds-is-open');

        } else {
            $A.get("e.c:LookupEvent")
                .setParams({
                    action: 'showLookupList',
                    guid: component.get('v.guid'),
                    params: this.lookupItemListParams(component)
                })
                .fire();

        }
    },
    /**
     * Hide List Box
     */
    hideListbox: function (component) {

        if (component.get('v.listIsRelative')) {
            var combobox = component.find('combobox');
            $A.util.removeClass(combobox, 'slds-is-open');

        } else {
            $A.get("e.c:LookupEvent")
                .setParams({
                    action: 'hideLookupList',
                    guid: component.get('v.guid')
                })
                .fire();
        }
    },
    /**
     * Remove selected value
     */
    removeValues: function (component) {
        component.set('v.selectedValue', null);
        component.set('v.value', null);
    },
    /**
     * Apply styles when input is in focus
     */
    inputFocus: function (component) {
        var comboboxContainer = component.find('comboboxInput');
        $A.util.addClass(comboboxContainer, 'slds-has-input-focus');
    },
    /**
     * Remove focused input styles
     */
    inputBlur: function (component) {
        var comboboxContainer = component.find('comboboxInput');
        $A.util.removeClass(comboboxContainer, 'slds-has-input-focus');
    },

    /**
     * Get suggestions based on User Input
     */
    getItems: function (component, keepResults) {
        var helper = this;
        var method = component.get('v.method');

        var controller = 'c.' + method;
        var params = component.get('v.options');
        params.searchText = component.get('v.searchText');
        params.recordId = null;
        params.queryLimit = component.get('v.currentLimit');
        params.params = component.get('v.params');

        if (method === 'getRecords') {
            params.sObjectName = component.get('v.sObjectName');
        }

        if (!keepResults) {
            component.set('v.searchResult', []);
        }

        component.set('v.isLoading', true);
        return this.request(component, helper, controller, params)
            .then($A.getCallback(function (res) {
                component.set('v.isLoading', false);
                component.set('v.searchResult', res);

                helper.setListboxHeight(component);
            }))
            .catch($A.getCallback(function (res) {
                console.log(res.getError()[0]);
                component.set('v.isLoading', false);
            }));
    },
    /**
     * Wrapper for standard logic of requests
     */
    request: function (component, helper, controller, params) {
        var p = new Promise(function (resolve, reject) {
            var action = component.get(controller);
            if (params) {
                action.setParams(params);
            }
            action.setCallback(helper, function (response) {
                if (response.getState() === 'SUCCESS') {
                    var res = response.getReturnValue();
                    if (res) {
                        resolve(res);
                    } else {
                        reject(res);
                    }
                } else {
                    reject(response);
                }
            });
            $A.enqueueAction(action);
        });
        return p;
    },

    /**
     * Prepopulate lookup by record id
     * @param component
     * @param id {string}
     */
    setValue: function (component, id) {
        var helper = this;
        var method = component.get('v.method');
        var controller = 'c.' + method;
        var params = component.get('v.options');
        params.searchText = null;
        params.recordId = id;
        params.params = {};
        if (method === 'getRecords') {
            params.sObjectName = component.get('v.sObjectName');
        }
        component.set('v.searchResult', []);
        this.request(component, helper, controller, params)
            .then(function (searchResult) {
                var selectedValue = {
                    Id: id,
                    Text: id,
                    Meta: '',
                    RecordObj: {}
                };
                if (searchResult.length > 0) {
                    selectedValue = searchResult[0];
                }
                component.set('v.selectedValue', selectedValue);
            })
            .catch($A.getCallback(function (error) {
                console.error(error.getError());
            }));
    },
    /**
     * Set default limit
     */
    resetLimit: function (component) {
        component.set('v.currentLimit', component.get('v.limit'));
    },

    setListboxHeight: function (component) {
        var searchResult = component.get('v.searchResult');
        var itemHeight = 44;
        var boxMargin = 8;
        var maxHeight = 316;

        var loadMoreHeight = searchResult.length === component.get('v.currentLimit') ? itemHeight : 0;
        var newRecordHeight = component.get('v.newRecordLink') ? itemHeight : 0;
        var listBoxHeight = (searchResult.length ? searchResult.length : 1) * itemHeight + boxMargin + loadMoreHeight + newRecordHeight;
        listBoxHeight = listBoxHeight > maxHeight ? maxHeight : listBoxHeight;
        component.set('v.listBoxHeight', listBoxHeight);
    },

    /**
     * Fire an event that user has selected new value
     */
    fireOnChange: function (component) {
        var onchange = component.get('v.onchange');
        $A.enqueueAction(onchange);
    },
    /**
     *  Apply new selected record
     */
    itemSelectedHandler: function (component, item) {
        component.set('v.selectedValue', item);
        component.set('v.value', item.Id);
        this.fireOnChange(component);
    },
    /**
     * Send updated params to remote Lookup Item List
     */
    updateListbox: function (component) {
        $A.get("e.c:LookupEvent")
            .setParams({
                action: 'updateLookupList',
                guid: component.get('v.guid'),
                params: this.lookupItemListParams(component)
            })
            .fire();
    },

    /**
     * Generate Lookup unique identifier
     * sets the v.guid attribute
     */
    generateUniqueId: function (component) {

        /**
         * RFC4122 version 4 compliant GUID generator
         * @returns {string} GUID
         */
        function uuidv4() {
            return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function (c) {
                var r = Math.random() * 16 | 0, v = c == 'x' ? r : (r & 0x3 | 0x8);
                return v.toString(16);
            });
        }

        component.set('v.guid', uuidv4());

    },
    /**
     * List of params to send to remote Lookup Item List
     */
    lookupItemListParams: function (component) {
        return {
            iconCollection: component.get('v.iconCollection'),
            icon: component.get('v.icon'),
            iconSize: component.get('v.iconSize'),
            searchResult: component.get('v.searchResult'),
            currentLimit: component.get('v.currentLimit'),
            isLoading: component.get('v.isLoading'),
            targetRect: component.find('combobox').getElement().getBoundingClientRect(),
            listBoxHeight: component.get('v.listBoxHeight'),
            newRecordLabel: component.get('v.newRecordLabel'),
            newRecordLink: component.get('v.newRecordLink')
        }
    },
    /**
     * Increase limit of returned results
     */
    loadMore: function (component) {
        component.set('v.currentLimit', component.get('v.currentLimit') * 2);
        component.set('v.loadMore', true);
    }
})