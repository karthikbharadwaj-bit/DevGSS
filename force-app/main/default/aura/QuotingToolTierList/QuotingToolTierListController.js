({
    doInit: function(component, event, helper) {
        helper.checkInputsDisabling(component);
    },
    newQuote: function(component, event, helper) {
        helper.scrollToTop(component);
    },
    /**
     * Find Service Plan to change to when user selects number of lines out of range of current service plan
     * @param component
     * @param event
     * @param helper
     */
    findSimilarTier: function(component, event, helper){
        var requestTier = event.getParam('requestTier');
        var type = event.getParam('type');
        var lines = event.getParam('lines');
        if (requestTier && type) {
              helper.findSimilarTier(component,requestTier,type,lines);
        }
    },
    /**
     * Current quote object changed
     */
    quoteChanged: function(component, event, helper){
        helper.setActivePriceBookEntry(component);
    },
    /**
     * State changed
     */
    stateChanged: function(component, event, helper){
        helper.filterTiers(component);
        if (component.get('v.isFilterInit')) {
            component.set('v.isFilterInit',true);
            helper.dropFilters(component);
            helper.setDefaultFilters(component);
            component.set('v.isFilterInit',false);
        }
        helper.checkDisplaying(component);
    },
    activePriceBookEntryChanged: function(component, event, helper){
        helper.getMCPriceDiff(component);
        component.set('v.isFilterInit',true);
    },
    /**
     *  Service Filter Changed
     */
    serviceFilterChanged: function(component, event, helper){
        helper.setFilterLevel(component);
        helper.filterTiers(component);
        helper.scrollToTop(component);
    },
    /**
     *  Edition Filter Changed
     */
    editionFilterChanged: function(component, event, helper){
        helper.setFilterLevel(component);
        helper.filterTiers(component);
        helper.scrollToTop(component);
    },
    /**
     *  Plan Filter Changed
     */
    planFilterChanged: function(component, event, helper){
        helper.setFilterLevel(component);
        helper.filterTiers(component);
        helper.scrollToTop(component);
    },
    /**
     *  Number of Lines Filter Changed
     */
    linesFilterChanged: function(component, event, helper){
        helper.filterTiers(component);
        helper.scrollToTop(component);
    },
    filterLevelChanged: function(component, event, helper){
        helper.scrollToTop(component);
        helper.checkInputsDisabling(component);
    },
    /**
     * User changed Service filter on UI
     */
    uiServiceFilterChanged: function(component, event, helper){
        component.set('v.planFilter',"");
        component.set('v.editionFilter',"");
    },
    /**
     * User changed Edition filter on UI
     */
    uiEditionFilterChanged: function(component, event, helper){
        component.set('v.planFilter',"");
    },
    /**
     * Upsell Status Changed
     */
    upsellStatusChanged: function(component, event, helper){
        helper.filterTiers(component);
        helper.checkDisplaying(component);
    },
    onButtonEvent: function(component, event, helper){
        switch (event.getParam('name')){
            case 'saveServicePlanButton':
                if(!helper.warnUserAboutServicePlanChange(component)){
                    helper.saveServicePlanOnQuote(component, component.get('v.selectedPriceBookEntry'));
                }
                break;
            case 'discardServicePlanButton':
                component.set('v.selectedPriceBookEntry',null);
                break;
        }
    },

    /**
     * Change Service Plan On Quote
     *
     * Arguments:
     * pricebook2Id
     *
     * @public
     * @param component
     * @param event
     * @param helper
     * @return {Promise|undefined}
     */
    switchServicePlan: function(component, event, helper){
        var args = event.getParam('arguments');
        return helper.switchServicePlan(component, args.pricebook2Id);
    },

    saveServicePlanOnQuote: function(component, event, helper) {
        var args = event.getParam('arguments');
        return helper.saveServicePlanOnQuote(component, args.priceBookEntry, args.lines);
    },
    
    accountServicePlanPbeChanged: function(component, event, helper){
        helper.filterTiers(component);
    },

    onTableScroll: function (component, event, helper) {
        helper.renderTiers(component);
    },

    tabIsActive: function (component, event, helper) {
        setTimeout($A.getCallback(() => {
            helper.renderTiers(component);
            setTimeout($A.getCallback(() => helper.scrollToSelectedTier(component)));
        }));
    },

    filteredTiersChanged: function (component, event, helper) {
        helper.setListBufferData(component);
    },

    onTableWheel: function (component, event) {
        RC.htmlUtils.trapScroll(event);
    }
});