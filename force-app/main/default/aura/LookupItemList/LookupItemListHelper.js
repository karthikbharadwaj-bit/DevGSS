({
    setParams: function(component, params){
        component.set('v.iconCollection',   params.iconCollection);
        component.set('v.icon',             params.icon);
        component.set('v.iconSize',         params.iconSize);
        component.set('v.searchResult',     params.searchResult);
        component.set('v.currentLimit',     params.currentLimit);
        component.set('v.targetRect',       params.targetRect);
        component.set('v.isLoading',        params.isLoading);
        component.set('v.listBoxHeight',    params.listBoxHeight);
        component.set('v.newRecordLabel',   params.newRecordLabel);
        component.set('v.newRecordLink',    params.newRecordLink);

    },
    showLookupList: function(component) {
        $A.util.removeClass(component.find('lookupItemList'), "listbox--hidden");
    },
    hideLookupList: function(component){
        $A.util.addClass(component.find('lookupItemList'), "listbox--hidden");
    },
    /**
     * Set position of the list box
     */
    setPosition: function(component){
        var targetRect = component.get('v.targetRect');
        var lookupItemList = component.find('lookupItemList').getElement();
        var listBoxHeight = component.get('v.listBoxHeight');

        var top,
            left,
            width;

        var containerRect = lookupItemList.parentNode.getBoundingClientRect();

        // Enough space on the bottom
        var isBottomOk = (containerRect.bottom - targetRect.bottom) > listBoxHeight;

        // Enough space on the top
        var isTopOk = (targetRect.top - containerRect.top) > listBoxHeight;


        if (isBottomOk || !isTopOk){
            // Place List on the bottom
            top = targetRect.bottom;

        } else {
            // Place List on the top
            top = targetRect.top - listBoxHeight - 5;
        }

        left = targetRect.left;
        width = targetRect.width;

        var styles = 'top:' + top + 'px;left:' + left + 'px;width:' + width + 'px';
        component.set('v.styles', styles);
    }

})