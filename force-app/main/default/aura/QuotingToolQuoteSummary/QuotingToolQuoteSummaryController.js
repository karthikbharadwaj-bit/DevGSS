({
    doInit: function(component, event, helper) {
        helper.checkUserPermissions(component);
        helper.refreshFieldsValues(component);
        helper.checkUnsavedChanges(component);
        helper.validateExpirationDate(component, { suppressIfEmpty: true });
        helper.setLookupParams(component);
        helper.validateAreaCodeLineItems(component);
    },
    /**
     * On User change field value
     * Check for unsaved changes and activate save button
     */
    activateSave: function(component, event, helper) {
        helper.checkUnsavedChanges(component);
    },
    querySaveQuote: function(component, event, helper) {
        var currentQuote = component.get("v.Wizard.currentQuote");

        var showReapprovalNotification = currentQuote.isApprovalStatusNotRequired
            && component.get("v.specialTerms") !== currentQuote.record.Special_Terms__c;

        helper.clearErrors(component);
        var validated = helper.validateInputs(component);
        helper.setEndDate(component);
        helper.hideQuoteNameInput(component);

        if (validated) {
            if (showReapprovalNotification) {
                $A.get("e.c:QuotingToolModalRequestEvent").setParams({
                    sourceId: currentQuote.record.Id,
                    action: "ApprovedQuoteUpdate"
                }).fire();
            } else {
                return helper.saveSummary(component);
            }
        }
    },
    discardQuoteChanges: function(component, event, helper) {
        helper.refreshFieldsValues(component);

        var currentQuote = component.get("v.Wizard.currentQuote");
        var specialTerms = currentQuote.record.Special_Terms__c;
        if (specialTerms
            && (typeof specialTerms === 'string')
            && (specialTerms.toLowerCase().indexOf('shipping') !== -1)) {
            $A.get("e.c:QuotingToolTermsChangeEvent").setParams({
                action: "show"
            }).fire();
        } else {
            $A.get("e.c:QuotingToolTermsChangeEvent").setParams({
                action: "hide"
            }).fire();
        }

        helper.hideQuoteNameInput(component);
        helper.validateStartDate(component, { suppressIfEmpty: true });
        helper.validateITerm(component, { suppressIfEmpty: true });
        helper.validateExpirationDate(component, { suppressIfEmpty: true });
        helper.validateRenewalTerm(component, { suppressIfEmpty: true });

        helper.clearErrors(component);
        helper.setInputsDisabling(component);
        helper.setEndDate(component);
        helper.checkUnsavedChanges(component);
    },
    /**
     * Modal Response
     */
    confirmSaveQuote: function(component, event, helper) {
        var result = event.getParam("modalResult");
        var action = event.getParam("action");
        if (action === "ApprovedQuoteUpdate" && result) {
            helper.saveSummary(component);
            helper.hideQuoteNameEditInput(component);
        }

    },
    /**
     * Show Quote Name Edit Input
     */
    showQuoteNameInput: function(component) {
        $A.util.addClass(component.find("quoteNameDisplay"), "hidden");
        $A.util.removeClass(component.find("quoteNameInput"), "hidden");
    },
    /**
     * User changed Special Terms Field
     */
    changeSpecialTerms: function(component, event, helper) {
        var st = component.get("v.specialTerms");
        if (st && (typeof st === 'string') && (st.toLowerCase().indexOf('shipping') !== -1)) {
            $A.get("e.c:QuotingToolTermsChangeEvent").setParams({
                action: "show"
            }).fire();
        } else {
            $A.get("e.c:QuotingToolTermsChangeEvent").setParams({
                action: "hide"
            }).fire();
        }
        helper.validateITerm(component, { suppressIfEmpty: true });
        helper.checkUnsavedChanges(component);
        helper.warnSpecialTerm(component);
        helper.creditAmountLabelChange(component);
    },
    /**
     * User changed Quote Type field
     */
    changeQuoteType: function(component, event, helper) {
        if (component.get('v.quoteType') === 'Quote') {
            component.set('v.status', 'Draft');
        }
        helper.validateStartDate(component, { suppressIfEmpty: true });
        helper.validateITerm(component, { suppressIfEmpty: true });
        helper.validateExpirationDate(component, { suppressIfEmpty: true });
        helper.validateRenewalTerm(component, { suppressIfEmpty: true });
        helper.setEndDate(component);
        helper.setInputsDisabling(component);
        helper.checkUnsavedChanges(component);
    },
    /**
     * v.startDate attribute changed
     */
    startDateChanged: function(component, event, helper) {
        helper.setEndDate(component);
    },
    /**
     * User changed Start date field
     */
    onUserChangeStartDate: function(component, event, helper) {
        helper.validateStartDate(component);
        helper.setEndDate(component);
    },
    /**
     * User Changed Initial Term
     */
    userChangedInitialTerm: function(component, event, helper) {
        var iTerm = component.get("v.iTerm");
            iTerm = helper.checkRange(iTerm, [2, 120]);
            iTerm = helper.checkInteger(iTerm);
            iTerm = String(iTerm);

        component.set("v.iTerm",  iTerm);
        component.set("v.rTerm",  iTerm);

        helper.checkUnsavedChanges(component);
        helper.warnSpecialTerm(component);
        helper.warnRenewalTerm(component);
    },
    /**
     * v.iTerm attribute changed
     */
    iTermChanged: function(component, event, helper) {
        helper.validateITerm(component);
        helper.setEndDate(component);
        helper.setInputsDisabling(component);
    },
    refreshQuoteSummaryTabInputValues: function(component, event, helper) {
        helper.refreshFieldsValues(component);
    },
    /**
     * User changed Expiration Date
     */
    onUserChangeExpirationDate: function(component, event, helper) {
        helper.validateExpirationDate(component);
    },
    /**
     * User changed Expiration Date
     */
    onPsForecastedCloseDateChange: function(component, event, helper) {
        helper.validateProServForecastedCloseDatePopulation(component);
    },
    /**
     * User changed Expiration Date
     */
    onPsForecastCategoryChange: function(component, event, helper) {
        helper.validateProservForecastCategoryPopulation(component);
        helper.checkUnsavedChanges(component);
    },
    /**
     * v.rTerm attribute changed
     */
    changeRenewalTerm: function(component, event, helper) {
        helper.validateRenewalTerm(component);
    },
    /**
     * User Changed Renewal Term
     */
    userChangedRenewalTerm: function(component, event, helper){
        var rTerm = component.get("v.rTerm");
            rTerm = helper.checkRange(rTerm, [2, 120]);
            rTerm = helper.checkInteger(rTerm);
            rTerm = String(rTerm);
        component.set("v.rTerm",  rTerm);

        helper.checkUnsavedChanges(component);
        helper.warnRenewalTerm(component);
    },
    modifyDatepicker: function(component, event) {
        // make datepicker years filter behave like salesforse native one
        var id = event.getSource().getLocalId();
        var dateValue = component.get('v.' + id);
        var currentYear = QW.moment().format('YYYY');
        var selectedYear = QW.moment(dateValue).format('YYYY');
        var startDate = Number(currentYear) - 1;
        var endDate = Number(currentYear) + 5;
        QW.jquery(document).ready(function() {
            var elements = QW.jquery('.datepicker__filter--year .picklist__label option');
            elements.each(function(index) {
                var elementYear = QW.jquery(this).val();
                if ((elementYear < startDate || elementYear > endDate) && elementYear !== selectedYear) {
                    QW.jquery(this).hide();
                } else {
                    QW.jquery(this).show();
                }
            });
        });
    },
    notificationAction: function(component, event) {
        switch (event.getParam("name")){
            case "specialTerms":
            case "rentalPhonesAvailability":
                let Tabs = component.get('v.Tabs');

                Tabs.open(Tabs.summary);

                component.set('v.Tabs', Tabs);
                break;
        }
    },
    /**
     * v.state attribute changed
     */
    stateChanged: function(component, event, helper){
        helper.setInputsDisabling(component);
        helper.rearrangeLayout(component);
    },
    /**
     * v.Wizard attribute Changed
     */
    wizardChanged: function(component, event, helper) {
        if (!component.get('v.Wizard.currentQuote'))
            return;

        helper.refreshFieldsValues(component);
        helper.setInputsDisabling(component);
        helper.rearrangeLayout(component);
        helper.checkUnsavedChanges(component);
        helper.setLookupParams(component);
    },
    /**
     * Selected Main Area Code object changed
     */
    mainAreaCodeObjChanged: function(component, event, helper){
        helper.setInputsDisabling(component);
    },
    /**
     * Selected Fax Area Code object changed
     */
    faxAreaCodeObjChanged: function(component, event, helper){
        helper.setInputsDisabling(component);
    },
    /**
     * Show popover
     */
    showPopover: function(component, event, helper){
        helper.showPopover(component, event.currentTarget.dataset.name);
    },
    /**
     *  Hide Renewal Term info
     */
    hidePopover: function(component){
        if (!component.get('v.popoverFreeze')) {
            QW.popover.hide();
        }
    },
    /**
     * User made changes on Main area code lookup
     */
    userChangedMainAreaCode: function(component, event, helper){
        var state = component.get('v.state');
        var faxAreaCode = component.get('v.faxAreaCode');
        var mainAreaCode = component.get('v.mainAreaCode');
        var mainAreaCodeObj = component.get('v.mainAreaCodeObj');

        if( state.isVanityNumbersAllowed && component.get('v.mainAreaCodeObj.RecordObj.Type__c') !== 'Toll-free'){
            component.set('v.isMainPhoneVanity',false);
        }

        // B-2342 prepopulate fax area code if it is emptyactivateSave
        if ( mainAreaCode && !faxAreaCode
             && mainAreaCodeObj.RecordObj.Name !== '800'
             && mainAreaCodeObj.RecordObj.Area_Code__c !== 800
             && !(state.isQuoteHasGoogleServicePlan && state.isQuoteHasRingCentralOrCanadaServicePlan)){
            component.set('v.faxAreaCode', mainAreaCode);
        }

        helper.checkUnsavedChanges(component);
    },
    /**
     * User made changes on Fax area code lookup
     */
    userChangedFaxAreaCode: function(component, event, helper){
        var state = component.get('v.state');
        if( state.isVanityNumbersAllowed && component.get('v.faxAreaCodeObj.RecordObj.Type__c') !== 'Toll-free'){
            component.set('v.isFaxPhoneVanity',false);
        }

        helper.checkUnsavedChanges(component);
    },
    proServSalesRepChanged: function(component) {
        var proServSalesRep = component.get('v.proServSalesRep');
        var proServSalesRepBlock = component.find('proServSalesRepBlock');
        if (proServSalesRep) {
            $A.util.removeClass(proServSalesRepBlock, "slds-has-error");
        }
    },

    areaCodeItemsChanged:function(component, event, helper){
        helper.validateAreaCodeLineItems(component);
        helper.setInputsDisabling(component);
    }
});