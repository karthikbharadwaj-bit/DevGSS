({
    /*
     *   Find suggestions
     */
    overallSearch: function(component, bypassSearchResultsRerender) {
        var searchQuery = component.get('v.searchQuery').toLowerCase();
        var picklistsData = component.get('v.picklistsData');
        var values = component.get('v.values');

        if (this.getSuggestionsHash(searchQuery, values) === component.get('v.suggestionsForHash'))
            return;

        function copy(o) {
            return Object.assign({}, o);
        }

        function searchForText(item, searchQuery) {
            return item.text.toLowerCase().indexOf(searchQuery) > -1;
        }

        // TODO make recoursive
        // Filter picklists
        var searchResults = picklistsData.map(copy).filter(function(l1) {

            if (Array.isArray(l1.childs)) {
                l1.childs = l1.childs.map(copy).filter(function(l2) {

                    if (Array.isArray(l2.childs)) {
                        l2.childs = l2.childs.map(copy).filter(function(l3) {

                            return searchForText(l3, searchQuery);

                        });
                    }
                    if (values[1]) {
                        return l2.text === values[1];
                    } else {
                        return l2.childs.length > 0 || searchForText(l2, searchQuery);
                    }

                });
            }
            if (values[0]) {
                return l1.text === values[0];
            } else {
                return l1.childs.length > 0 || searchForText(l1, searchQuery);
            }

        });

        if (!searchQuery) {
            var currentDepth = this.getDepth(searchResults);
            component.set('v.currentDepth', currentDepth);
        }

        if(!bypassSearchResultsRerender) {
            component.set('v.suggestionsForHash', this.getSuggestionsHash(searchQuery, values));
            component.set('v.searchResults', searchResults);
        }
    },
    /*
     *  Show/Hide suggestions for columns which not currently selected
     */
    showhide: function(component) {
        var searchLookupEl = component.find('searchLookupWrapper');
        var searchQuery = component.get('v.searchQuery');
        var values = component.get('v.values');
        if (searchQuery) {
            $A.util.removeClass(searchLookupEl, "lookup--init-1");
            $A.util.removeClass(searchLookupEl, "lookup--init-2");
        } else {
            if (values.length === 0) {
                $A.util.addClass(searchLookupEl, "lookup--init-1");
            }
            if (values.length === 1) {
                $A.util.removeClass(searchLookupEl, "lookup--init-1");
                $A.util.addClass(searchLookupEl, "lookup--init-2");
            }
            if (values.length === 2) {
                $A.util.removeClass(searchLookupEl, "lookup--init-1");
                $A.util.removeClass(searchLookupEl, "lookup--init-2");
            }
        }
    },
    /*
     *   Check if all possible values/picklists are populated 
     */
    checkValid: function(component) {
        var values = component.get('v.values');
        var currentDepth = component.get('v.currentDepth');
        var isValid = values.length === currentDepth;
        if (isValid) {
            this.endSearch(component);
        }
        component.set('v.isValid', isValid);
    },
    /*
     *  Open suggestions box
     */
    startSearch: function(component) {
        var searchLookupEl = component.find('searchLookupWrapper');
        $A.util.addClass(searchLookupEl, "slds-is-open");
        component.set('v.isFocused', true);

        component.set('v.expandIndexP1', '');
        component.set('v.expandIndexP2', '');
        this.focus(component);
    },
    /*
     *  Close suggestions box
     */
    endSearch: function(component) {
        var searchLookupEl = component.find('searchLookupWrapper');
        $A.util.removeClass(searchLookupEl, "slds-is-open");
        component.set('v.isFocused', false);

        component.set('v.expandIndexP1', '');
        component.set('v.expandIndexP2', '');
    },
    /*
     *  Focus Search input
     */
    focus: function(component) {
        // TODO will not work with locker service
        var searchLookupInput = component.find('searchLookupInput').getElement();
        if (searchLookupInput) {
            searchLookupInput.getElementsByTagName('input')[0].focus();
        }
    },
    blur: function(component){
        // TODO will not work with locker service
        var searchLookupInput = component.find('searchLookupInput').getElement();
        if (searchLookupInput) {
            searchLookupInput.getElementsByTagName('input')[0].blur();
        }
    },
    displayValues: function(component) {
        var searchLookupEl = component.find('searchLookupWrapper');
        var values = component.get('v.values');
        var isValid = component.get('v.isValid');

        $A.util.removeClass(searchLookupEl, "slds-size--1-of-3");
        $A.util.removeClass(searchLookupEl, "slds-size--2-of-3");
        $A.util.removeClass(searchLookupEl, "slds-size--3-of-3");

        var newclass = "populated-" + values.length;
        $A.util.addClass(searchLookupEl, newclass);
    },
    /*
     *  Get maximum depth of nested picklists
     */
    getMaxDepth: function(component) {
        var picklistsData = component.get('v.picklistsData');
        var maxDepth = this.getDepth(picklistsData);
        component.set('v.maxDepth', maxDepth);
    },
    /*
     *  Helper function to get maximum depth of nested array
     */
    getDepth: function(arr) {
        var depth = 0;
        arr.forEach(function(item) {
            if (Array.isArray(item.childs) && item.childs.length > 0) {
                var tmpDepth = this.getDepth(item.childs);
                if (tmpDepth > depth) {
                    depth = tmpDepth;
                }
            }
        },this);
        return 1 + depth;
    },
    /*
     *  Remove last picklist value
     */
    removeOneValue: function(component){
        var values = component.get('v.values');
        if (values.length > 0) {
            values.splice(values.length - 1,1);
            component.set('v.values', values);
        }
    },
    styleSearch: function(component){
        var values = component.get('v.values');
        var currentDepth = component.get('v.currentDepth');
        var filledBy = values.length / currentDepth * 100;
        var valuePillsStyle = 'width: calc( ' + filledBy + '% - 2.3rem );';
        var valueInputStyle = '';
        if (filledBy !== 0) {
            valueInputStyle = 'padding-left: calc( ' + filledBy + '% - 2.3rem);';
        }

        component.set('v.valuePillsStyle',valuePillsStyle);
        component.set('v.valueInputStyle',valueInputStyle);
    },
    setNextValue: function(component){
        var values = component.get('v.values');
        var currentDepth = component.get('v.currentDepth');
        var searchResults = component.get('v.searchResults');
        if (values.length < currentDepth) {
            var positionArray = Array(values.length + 1).fill(0);
            var item = this.getValueByIndexes(searchResults, positionArray);
            var nextValue = item && item.text;

            if (nextValue) {
                values.push(nextValue);
                component.set('v.values',values);
                component.set('v.searchQuery', '');
                if (component.get('v.isValid'))
                    this.blur(component);
            }
        }
    },
    
    changeActionfire: function(component) {
        $A.get("e.c:CaseTaggingToolPickListChangeEvent").setParams({
          tab: component.get('v.tabName')
        }).fire();
    },

    getSuggestionsHash: function(searchQuery, values){
        return searchQuery + values;
    },

    getValueByIndexes: function (arr, indexes) {
        var entity = arr;
        indexes.forEach(function(val, index){
            entity = index === 0
                ? arr && arr[val]
                : entity && entity.childs && entity.childs[val];
        });

        return entity;
    }
})