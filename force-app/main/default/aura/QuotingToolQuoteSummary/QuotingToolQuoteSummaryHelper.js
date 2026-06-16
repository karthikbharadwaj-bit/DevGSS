/* globals QW */
({
    /**
     * Hide Quote Name Edit input field
     */
    hideQuoteNameEditInput: function(component) {
        $A.util.removeClass(component.find("quoteNameDisplay"), "hidden");
        $A.util.addClass(component.find("quoteNameInput"), "hidden");
    },
    /**
     * Save summary tab values
     * Actual server call performed in QuotingToolSelectedTierInfo
     */
    saveSummary: function(component) {
        var helper = this;
        var Wizard = component.get('v.Wizard');

        // Prepare Quote with updated values
        var updatedQuote = {
            Id:                                     Wizard.currentQuote.record.Id,
            Name:                                   component.get("v.nameQuote"),
            QuoteType__c:                           component.get("v.quoteType"),
            Special_Terms__c:                       component.get("v.specialTerms"),
            Start_Date__c:                          component.get("v.startDate"),
            Term_months__c:                         helper.getTermValue(component.get("v.rTerm")),
            Initial_Term_months__c:                 helper.getTermValue(component.get("v.iTerm")),
            Status:                                 component.get("v.status"),
            Auto_Renewal__c:                        component.get("v.autoRenewal"),
            JustificationandDescription__c:         component.get("v.justification"),
            ExpirationDate:                         component.get("v.expirationDate"),
            End_Date__c:                            component.get('v.endDate'),
            AreaCode__c:                            component.get('v.mainAreaCode'),
            FaxAreaCode__c:                         component.get('v.faxAreaCode'),
            Main_Vanity_Number__c:                  component.get('v.isMainPhoneVanity'),
            Fax_Vanity_Number__c:                   component.get('v.isFaxPhoneVanity'),
            UID_from_biz__c:                        component.get('v.UIDfrombiz')
        };
        if (Wizard.currentQuote.isCCorProServ) {
            updatedQuote.Quote_Description__c                  = component.get('v.quoteDescription');
            updatedQuote.Number_of_ProServ_Phases__c           = component.get('v.numberOfProServPhases');
            updatedQuote.Number_of_Hardware_Shipment_Phases__c = component.get('v.numberOfHardwareShipmentPhases');
            updatedQuote.ProServ_Forecasted_Close_Date__c      = component.get('v.proServForecastedCloseDate');
            updatedQuote.ProServ_Forecast_Category__c          = component.get('v.proServForecastCategory');
            updatedQuote.PSOfferType__c                        = component.get('v.proServOfferType');
            updatedQuote.PSProjectComplexity__c                = component.get('v.proServProjectComplexity');
            updatedQuote.T_E__c                                = component.get('v.proServTE');
            updatedQuote.ProServProjectManager__c              = component.get('v.proServProjectManager');
            updatedQuote.SOW_Type__c                           = component.get('v.proServSOWType');
            updatedQuote.Original_SOW_Quote_Number__c          = component.get('v.originalSOWQuoteNumber');
            updatedQuote.ASA_Owner__c                          = component.get('v.ASAOwner');
            updatedQuote.ProServUsers__c                       = component.get('v.numberOfProServUsers');
            updatedQuote.PS_Segment__c                         = component.get('v.PSSegment');
            updatedQuote.PSMonthlyRecurringServicesValueARR__c = component.get('v.psMonthlyRecurringServicesValueARR');
            updatedQuote.Signed_SOW__c                         = component.get('v.signedSOW')
                                                                        ? QW.prependHttp(component.get('v.signedSOW'))
                                                                        : '';
            updatedQuote.Signed_COD__c                         = component.get('v.signedCOD')
                                                                        ? QW.prependHttp(component.get('v.signedCOD'))
                                                                        : '';
        } else {
            if (Wizard.currentQuote.isProServ) {
                updatedQuote.Original_SOW_Quote_Number__c      = component.get('v.originalSOWQuoteNumber');
                updatedQuote.ProServ_Forecasted_Close_Date__c      = component.get('v.proServForecastedCloseDate');
                updatedQuote.Signed_COD__c                         = component.get('v.signedCOD')
                    ? QW.prependHttp(component.get('v.signedCOD'))
                    : '';
            }
            updatedQuote.Shipping_Country__c      = component.get('v.shippingLocation.country');
            updatedQuote.Shipping_City__c         = component.get('v.shippingLocation.city');
            updatedQuote.Shipping_State__c        = component.get('v.shippingLocation.state');
            updatedQuote.Shipping_Address_Line__c = component.get('v.shippingLocation.addressLine');
            updatedQuote.Shipping_Postal_Code__c  = component.get('v.shippingLocation.postalCode');
            updatedQuote.Shipping_Option__c       = component.get('v.shippingLocation.shippingOption');
            updatedQuote.Ship_Attention_To__c     = component.get('v.shippingLocation.shipAttentionTo');
            updatedQuote.Shipping_Additional_Address_Line__c = component.get('v.shippingLocation.additionalAddressLine');
            updatedQuote.Shipping_Customer_Name__c = component.get('v.shippingLocation.customerName');
            updatedQuote.MultipleShippingLocations__c = component.get('v.shippingLocation.multipleLocations');
        }

        updatedQuote.ProServSalesRep__c = component.get('v.proServSalesRep');
        updatedQuote.Opportunity = Wizard.currentQuote.record.Opportunity;
        updatedQuote.Opportunity.ProvisioningDetails__c = component.get('v.provisioningDetails');
        updatedQuote.Opportunity.SelfProvisioned__c = component.get('v.selfProvisioned');

        QW.spinner.show('Saving Quote');
        return QW.salesforce.request(component, 'c.updateQuote', { updatedQuote: updatedQuote })
            .then($A.getCallback(function() {

                if(Wizard.opportunity.isProvDetailsFieldChanged ||
                    Wizard.opportunity.isSelfProvisionedFieldChanged) {
                    return QW.salesforce.request(component, 'c.updateOpp', { updatedOpp: updatedQuote.Opportunity })
                }
            }))
            .then($A.getCallback(function () {
                helper.hideQuoteNameEditInput(component);
            }))
            .catch($A.getCallback(function (error) {
                console.error(error);
                $A.get("e.c:ToastEvent").setParams({
                    theme: 'error',
                    header: 'Failed to save Quote',
                    details: QW.salesforce.getResponseError(error),
                    defaultTimeout: false
                }).fire();
            }))
            .then($A.getCallback(function(){
                QW.spinner.show('Refreshing Quote');
                return QW.salesforce.request(component, 'c.getQuotes', {
                    opportunityId: Wizard.opportunity.record.Id
                })
            }))
            .then($A.getCallback(function(quotes) {

                /*
                    temporary fix, because some places using `v.quote`,
                    but here after getting of quotes we don't set them in v.quote
                */
               Wizard.setQuotes(quotes);
               Wizard.update();
               component.set('v.Wizard', Wizard);

                var quote = component.get('v.quote');
                var currentQuote = _.find(quotes, function(q) { return q.Id === quote.Id});
                    currentQuote && component.set('v.quote', currentQuote);

                QW.spinner.hide();
            }));
    },

    getTermValue: function(value) {
        return value ? String(value) : null;
    },

    validateInputs: function(component) {
        var Wizard = component.get('v.Wizard');
        var validated = true;

        if (Wizard.currentQuote.isCCorProServ){
            /* validate Number of ProServ Phases */
            if (!this.numberOfProServPhases(component)) {
                validated = false;
            }
            /* validate Number of Hardware Shipment Phases */
            if (!this.validateNumberOfHardwareShipmentPhases(component)) {
                validated = false;
            }
            if (!this.validateNumberOfProServUsers(component)) {
                validated = false;
            }
            if (!this.validateProservSalesRepPopulation(component)) {
                validated = false;
            }
            if (!this.validateProservForecastCategoryPopulation(component)) {
                validated = false;
            }
            if (Wizard.currentQuote.isProServ && !this.validateProServForecastedCloseDatePopulation(component)) {
                validated = false;
            }
            if (Wizard.currentQuote.isCCProServ && !component.find("proServForecastedCloseDate2").reportValidity()) {
                validated = false;
            }
            if (!component.find("signedSOW").isValid()) {
                validated = false;
            }
            if (Wizard.currentQuote.record.Opportunity.Parent_Order__c != null && !component.find("signedCOD").isValid()) {
                validated = false;
            }
            if (!component.find("originalSOWQuoteNumber").reportValidity()) {
                validated = false;
            }
            if (!component.find("proServProjectComplexity").reportValidity()) {
                validated = false;
            }
            if (!component.find("psMonthlyRecurringServicesValueARR").reportValidity()) {
                validated = false;
            }

        } else {
            /* validate start date */
            if (!this.validateStartDate(component)) {
                validated = false;
            }
            /* validate initial term */
            if (!this.validateITerm(component)) {
                validated = false;
            }
            /* validate expiration date */
            if (!this.validateExpirationDate(component)) {
                validated = false;
            }
            /* validate renewal term */
            if (!this.validateRenewalTerm(component)) {
                validated = false;
            }

            if(!this.validateProvDetailsPopulation(component)) {
                validated = false;
            }
            if (Wizard.currentQuote.isProServ && !component.find("originalSOWQuoteNumber").reportValidity()) {
                validated = false;
            }
        }
        return validated;
    },
    /**
     * Remove validation errors from fields
     */
    clearErrors: function(component) {
        component.find("startDate").set("v.errors", null);
        $A.util.removeClass(component.find("startDateBlock"), "slds-has-error");

        component.find("renewalTerm").set("v.errors", null);
        $A.util.removeClass(component.find("renewalTermBlock"), "slds-has-error");
        $A.util.removeClass(component.find("renewalTermDiv"), "slds-has-warning");

        component.find("initialTerm").set("v.errors", null);
        $A.util.removeClass(component.find("initialTermBlock"), "slds-has-error");

        component.find("expirationDate").set("v.errors", null);
        $A.util.removeClass(component.find("expirationDateBlock"), "slds-has-error");

        $A.util.removeClass(component.find("specialTermsDiv"), "slds-has-warning");

        $A.util.removeClass(component.find("provisioningBlock"), "slds-has-error");

        $A.util.removeClass(component.find("numberOfProServUsersBlock"), "slds-has-error");
        $A.util.removeClass(component.find("numberOfProServUsersBlock2"), "slds-has-error");

        component.find("proServForecastedCloseDate").set("v.errors", null);
        $A.util.removeClass(component.find("proServForecastedCloseDateBlock"), "slds-has-error");

        component.find("proServForecastCategory").set("v.errors", null);
        $A.util.removeClass(component.find("proServForecastCategoryBlock"), "slds-has-error");
    },
    /**
     * Validate Number of ProServ Users field
     * @returns {boolean}
     */
    validateNumberOfProServUsers: function(component){
        var numberOfProServUsers = component.get('v.numberOfProServUsers');
        var isValidNumber = this.isIntegerValue(numberOfProServUsers) && parseInt(numberOfProServUsers) >= 0 && parseInt(numberOfProServUsers) <= 999999;
        if(!isValidNumber) {
            var numberOfProServUsersBlock = component.find('numberOfProServUsersBlock');
            var numberOfProServUsersBlock2 = component.find('numberOfProServUsersBlock2');
            $A.util.addClass(numberOfProServUsersBlock, "slds-has-error");
            $A.util.addClass(numberOfProServUsersBlock2, "slds-has-error");
        }
        return isValidNumber;
    },
    /**
     * Validate Number of ProServ Phases field
     * @returns {boolean}
     */
    numberOfProServPhases: function(component){
        var numberOfProServPhases = component.get('v.numberOfProServPhases');
        var numberOfProServPhasesInt = parseInt(numberOfProServPhases);
        return !numberOfProServPhases || (this.isIntegerValue(numberOfProServPhases) && numberOfProServPhasesInt >= 0 && numberOfProServPhasesInt <= 30);
    },
    /**
     * Validate Number Of Hardware Shipment Phases field
     * @returns {boolean}
     */
    validateNumberOfHardwareShipmentPhases: function(component){
        var numberOfHardwareShipmentPhases = component.get('v.numberOfHardwareShipmentPhases');
        var numberOfHardwareShipmentPhasesInt = parseInt(numberOfHardwareShipmentPhases);
        return !numberOfHardwareShipmentPhases ||
               (this.isIntegerValue(numberOfHardwareShipmentPhases) && numberOfHardwareShipmentPhasesInt >= 0 && numberOfHardwareShipmentPhasesInt <= 30);
    },

    isIntegerValue: function(value) {
        return Number(value) === parseInt(value);
    },

    /**
     * Check if ProServ Sales Rep field is populated
     * @returns {boolean}
     */
    validateProservSalesRepPopulation: function(component) {
        var proServSalesRep = component.get('v.proServSalesRep');
        if(!proServSalesRep) {
            var proServSalesRepBlock = component.find('proServSalesRepBlock');
            $A.util.addClass(proServSalesRepBlock, "slds-has-error");
        }
        return proServSalesRep;
    },
    /**
     * Check if ProServ Forecast Category field is populated
     * @returns {boolean}
     */
    validateProservForecastCategoryPopulation: function(component) {
        var proServForecastCategoryBlock = component.find('proServForecastCategoryBlock');
        $A.util.removeClass(proServForecastCategoryBlock, "slds-has-error");

        var proServForecastCategory = component.get('v.proServForecastCategory');
            if(!proServForecastCategory) {
            $A.util.addClass(proServForecastCategoryBlock, "slds-has-error");
        }

        return proServForecastCategory;
    },
    /**
     * Check if ProServ Forecasted Close Date field is populated
     * @returns {boolean}
     */
    validateProServForecastedCloseDatePopulation: function(component) {
        var proServForecastedBlock = component.find('proServForecastedCloseDateBlock');
        $A.util.removeClass(proServForecastedBlock, "slds-has-error");

        var proServForecastedCloseDate = component.get('v.proServForecastedCloseDate');
        if(!proServForecastedCloseDate) {
            $A.util.addClass(proServForecastedBlock, "slds-has-error");
        }

        return proServForecastedCloseDate;
    },

    /**
     * Validate Start Date field and show error
     * 1) field is required
     * 2) Start Date should be in range of +-30 days from current date.
     * @param component                 {object}    Aura Component
     * @param params                    [{object}]
     * @param params.suppressIfEmpty    [{boolean}] do not show error if value is empty
     * @returns {boolean}
     */
    validateStartDate: function(component, params) {
        var stDateDiv = component.find("startDateBlock");
        var stDateInput = component.find("startDate");
        var startDateValue = component.get("v.startDate");
        var quoteType = component.get("v.quoteType");
        var isValid = true;
        var suppressIfEmpty = params ? params.suppressIfEmpty : false;
        var messages = [];
        /* clear previous errors */
        stDateInput.set("v.errors", null);
        $A.util.removeClass(stDateDiv, "slds-has-error");

        /* validate */
        if (quoteType === "Agreement") {
            /* 1) field is required */
            $A.util.addClass(stDateDiv, "is-required");
            var isEmpty = false;
            if (!startDateValue || !startDateValue.trim()) {
                isEmpty = true;
                isValid = false;
                messages.push({ message: "This field is required" });
            }
            /* suppress errors if user expected to fill input */
            if (suppressIfEmpty && isEmpty) {
                isValid = true;
                messages = [];
            } else { // continue validation
                /* 2) Start Date should be in range of +-30 days from current date. */
                var nowDate = QW.moment();
                var startDate = QW.moment(startDateValue);
                var daysFromNow = Math.abs(nowDate.diff(startDate, "days"));
                if (daysFromNow > 30) {
                    isValid = false;
                    messages.push({ message: "Start Date should be in range of +-30 days from current date." });
                }
            }
        } else {
            $A.util.removeClass(stDateDiv, "is-required");
        }
        /* show errors */
        if (!isValid) {
            stDateInput.set("v.errors", messages);
            $A.util.addClass(stDateDiv, 'slds-has-error');
        }
        return isValid;
    },

    validateITerm: function(component, params) {
        var iTermDiv = component.find("initialTermBlock");
        var iTermInput = component.find("initialTerm");
        var iTermValue = component.get("v.iTerm");
        var specialTermsValue = component.get("v.specialTerms");
        var quoteType = component.get("v.quoteType");
        var isValid = true;
        var suppressIfEmpty = params ? params.suppressIfEmpty : false;
        var messages = [];
        /* clear previous errors */
        iTermInput.set("v.errors", null);
        $A.util.removeClass(iTermDiv, "slds-has-error");
        /* validate */
        if (quoteType === "Agreement" || specialTermsValue) {
            /* 1) field is required */
            $A.util.addClass(iTermDiv, "is-required");
            var isEmpty = false;
            if (!iTermValue || iTermValue === "--None--") {
                isEmpty = true;
                isValid = false;
                if (quoteType !== "Agreement" && specialTermsValue) {
                    var message = "Initial Term should be selected in order to pick one of Special Terms";
                } else {
                    var message = "This field is required";
                }
                messages.push({ message: message });
            }
            /* suppress errors if user expected to fill input */
            if (suppressIfEmpty && isEmpty) {
                isValid = true;
                messages = [];
            }
        } else {
            $A.util.removeClass(iTermDiv, "is-required");
        }
        /* show errors */
        if (!isValid) {
            iTermInput.set("v.errors", messages);
            $A.util.addClass(iTermDiv, 'slds-has-error');
        }
        return isValid;
    },
    validateExpirationDate: function(component, params) {
        var exDateDiv = component.find("expirationDateBlock");
        var exDateInput = component.find("expirationDate");
        var exDateValue = component.get("v.expirationDate");
        var currentQuote = component.get("v.Wizard.currentQuote");
        var isValid = true;
        var suppressIfEmpty = params ? params.suppressIfEmpty : false;
        var messages = [];
        /* clear previous errors */
        exDateInput.set("v.errors", null);
        $A.util.removeClass(exDateDiv, "slds-has-error");
        /* validate */
        /* 1) field is required */
        $A.util.addClass(exDateDiv, "is-required");
        var isEmpty = false;
        if (!exDateValue || !exDateValue.trim()) {
            isEmpty = true;
            isValid = false;
            messages.push({ message: "This field is required" });
        }
        /* suppress errors if user expected to fill input */
        if (suppressIfEmpty && !isEmpty) {
            isValid = true;
            messages = [];
        } else {
            /* 2) B-1861 User shouldn't be able to enter  date less than current date or more than +30 days from current date  */
            if (currentQuote.record.ExpirationDate !== exDateValue) {
                var nowDate = QW.moment();
                var exDate = QW.moment(exDateValue);
                var daysFromNow = exDate.diff(nowDate, "days");

                if (daysFromNow < 0 || daysFromNow > 30) {
                    isValid = false;
                    messages.push({ message: "Expiration Date should be in the range from the current date to 30 days from the current date" });
                }
            }
        }
        component.set('v.isExpDateValid', isValid);
        /* show errors */
        if (!isValid) {
            exDateInput.set("v.errors", messages);
            $A.util.addClass(exDateDiv, 'slds-has-error');
        }
        return isValid;
    },
    validateRenewalTerm: function(component, params) {
        var rTermDiv = component.find("renewalTermBlock");
        var rTermInput = component.find("renewalTerm");
        var rTermValue = component.get("v.rTerm");
        var quoteType = component.get("v.quoteType");
        var isValid = true;
        var suppressIfEmpty = params ? params.suppressIfEmpty : false;
        var messages = [];
        /* clear previous errors */
        rTermInput.set("v.errors", null);
        $A.util.removeClass(rTermDiv, "slds-has-error");
        /* validate */
        if (quoteType === "Agreement") {
            /* 1) field is required */
            $A.util.addClass(rTermDiv, "is-required");
            var isEmpty = false;
            if (!rTermValue || rTermValue === "--None--") {
                isEmpty = true;
                isValid = false;
                messages.push({ message: "This field is required" });
            }
            /* suppress errors if user expected to fill input */
            if (suppressIfEmpty && isEmpty) {
                isValid = true;
                messages = [];
            }
        } else {
            $A.util.removeClass(rTermDiv, "is-required");
        }
        /* show errors */
        if (!isValid) {
            rTermInput.set("v.errors", messages);
            $A.util.addClass(rTermDiv, 'slds-has-error');
        }
        return isValid;
    },
    /**
     * Check difference between Initial Term and Renewal Term
     * Renewal Term should be greater or equal to Initial Term
     * B-2408 https://rc.my.salesforce.com/a2034000003naPT
     */
    isRenewalTermInitialTermNotRecommended: function(component){
        var rTermValue = component.get("v.rTerm");
        var iTermValue = component.get("v.iTerm");
        var currentQuote = component.get('v.Wizard.currentQuote');

        return Number(rTermValue) < Number(iTermValue)
            && (rTermValue !== currentQuote.record.Term_months__c || iTermValue !== currentQuote.record.Initial_Term_months__c);
    },
    /**
     * Add warning class for Renewal Term Field
     * B-2408 https://rc.my.salesforce.com/a2034000003naPT
     */
    warnRenewalTerm: function(component) {
        var showWarning = this.isRenewalTermInitialTermNotRecommended(component);
        QW.cssUtils.toggleClass(component, 'renewalTermDiv', showWarning, 'slds-has-warning');

        if (showWarning) {
            component.set('v.popoverFreeze', true);
            QW.popover.show(component.find("renewalTermDiv").getElement(), QW.popover.MESSAGES.renewalTermLessThanInitialTerm);

            window.setTimeout(
                $A.getCallback(function () {
                    component.set('v.popoverFreeze', false);
                }), 5000
            );
        } else {
            component.set('v.popoverFreeze', false);
        }
    },

    validateProvDetailsPopulation: function(component) {
        if (component.get('v.Wizard.settings.featureToggle.ProvisioningDetailsField__c')) {
            var provisioningDetails = component.get('v.provisioningDetails');
            var primaryQuote = component.get('v.Wizard.primaryQuote');
            if ((!provisioningDetails || !provisioningDetails.trim()) && primaryQuote.isDownsell) {
                QW.cssUtils.toggleClass(component,
                    'provisioningBlock',
                    true,
                    'slds-has-error'
                );
                return false;
            }
        }
        return true;
    },

    /**
     * Check difference between Initial Term and Special Terms (free weeks of service)
     * B-2408 https://rc.my.salesforce.com/a2034000003naPT
     */
    isInitialTermAndSpecialTermWeeksNotRecommended: function(component) {
        var sTermValue = component.get("v.specialTerms");
        var iTermValue = component.get("v.iTerm");
        var currentQuote = component.get('v.Wizard.currentQuote');
        var result = false;

        if (sTermValue !== currentQuote.record.Special_Terms__c || iTermValue !== currentQuote.record.Initial_Term_months__c){
            if (sTermValue && (typeof sTermValue === 'string')) {
                if (sTermValue.toLowerCase().indexOf('free week') !== -1) {
                    var weeks = parseInt(sTermValue);
                    if ((iTermValue == '12' && weeks > 4) || (iTermValue == '24' && weeks > 8) || (iTermValue == '36' && weeks > 12)) {
                        result = true;
                    }
                }
            }
        }

        return result;
    },
    /**
     * Check difference between Initial Term and Special Terms (free months of service)
     * B-2408 https://rc.my.salesforce.com/a2034000003naPT
     */
    isInitialTermAndSpecialTermMonthsNotRecommended: function(component) {
        var sTermValue = component.get("v.specialTerms");
        var iTermValue = component.get("v.iTerm");
        var currentQuote = component.get('v.Wizard.currentQuote');
        var result = false;

        if (sTermValue !== currentQuote.record.Special_Terms__c || iTermValue !== currentQuote.record.Initial_Term_months__c){
            if (sTermValue && (typeof sTermValue === 'string')) {
                if (sTermValue.toLowerCase().indexOf('free month') !== -1) {
                    var months = parseInt(sTermValue);
                    if (
                        (months == 1 && iTermValue < 12) ||
                        (months == 2 && iTermValue < 24) ||
                        (months == 3 && iTermValue < 36) ||
                        (months == 4 && iTermValue < 48) ||
                        (months == 5 && iTermValue < 60) ||
                        (months == 6 && iTermValue < 72)
                       ) {
                        result = true;
                    }
                }
            }
        }

        return result;
    },
    requiresSpecialTermsApproval: function(component) {
        var sTermValue = component.get("v.specialTerms");
        var iTermValue = component.get("v.iTerm");
        var currentQuote = component.get('v.Wizard.currentQuote');
        var result = false;

        if (sTermValue !== currentQuote.record.Special_Terms__c || iTermValue !== currentQuote.record.Initial_Term_months__c){
            if (sTermValue && (typeof sTermValue === 'string')) {
                if (sTermValue.toLowerCase().indexOf('free month') !== -1) {
                    var months = parseInt(sTermValue);
                    if(months == 4 || months == 5 || months == 6){
                        result = true;
                    }
                }
            }
        }

        return result;
    },
    /**
     * Add warning class for Special Terms Field
     * B-2408 https://rc.my.salesforce.com/a2034000003naPT
     */
    warnSpecialTerm: function(component) {
        var showWeekWarning = this.isInitialTermAndSpecialTermWeeksNotRecommended(component);
        var showMonthWarning = this.isInitialTermAndSpecialTermMonthsNotRecommended(component);
        var showSpecialTermWarning = this.requiresSpecialTermsApproval(component);

        QW.cssUtils.toggleClass(component, 'specialTermsDiv', showWeekWarning, 'slds-has-warning');
        if (showWeekWarning) {
            component.set('v.popoverFreeze', true);
            QW.popover.show(component.find("specialTermsDiv").getElement(), QW.popover.MESSAGES.specialTermsFreeWeeks);

            window.setTimeout(
                $A.getCallback(function () {
                    component.set('v.popoverFreeze', false);
                }), 5000
            );
        } else if(showMonthWarning || showSpecialTermWarning) {
            var messages = [];

            if(showMonthWarning){
                messages.push(QW.popover.MESSAGES.specialTermsFreeMonths);
            }
            if(showSpecialTermWarning){
                messages.push(QW.popover.MESSAGES.specialTermsRequiresApproval);
            }
            QW.cssUtils.toggleClass(component, 'specialTermsDiv', showMonthWarning, 'slds-has-warning');
            component.set('v.popoverFreeze', true);

            QW.popover.show(component.find("specialTermsDiv").getElement(), messages);

            window.setTimeout(
                $A.getCallback(function () {
                    component.set('v.popoverFreeze', false);
                }), 5000
            );
        }else {
            component.set('v.popoverFreeze', false);
        }
    },
    /**
     * Set actual values to field from Quote
     */
    refreshFieldsValues: function(component) {
        var currentQuote = component.get('v.Wizard.currentQuote');

        this.addMissedOptionValues(component);
        var creditAmount = currentQuote.record.Credit_Amount__c ? parseFloat(currentQuote.record.Credit_Amount__c) : 0;
        var freeServiceTaxes = currentQuote.record.Free_Service_Taxes__c
            ? parseFloat(currentQuote.record.Free_Service_Taxes__c)
            : 0;

        component.set("v.rTerm",                      currentQuote.record.Term_months__c);
        component.set("v.iTerm",                      currentQuote.record.Initial_Term_months__c);
        component.set("v.status",                     currentQuote.record.Status);
        component.set("v.specialTerms",               currentQuote.record.Special_Terms__c);
        component.set("v.justification",              currentQuote.record.JustificationandDescription__c || '');
        component.set("v.autoRenewal",                currentQuote.record.Auto_Renewal__c);
        component.set("v.quoteType",                  currentQuote.record.QuoteType__c);
        component.set("v.expirationDate",             currentQuote.record.ExpirationDate);
        component.set("v.startDate",                  currentQuote.record.Start_Date__c);
        component.set("v.endDate",                    currentQuote.record.End_Date__c);
        component.set("v.nameQuote",                  currentQuote.record.Name);
        component.set("v.quoteDescription",           currentQuote.record.Quote_Description__c || '');
        component.set("v.proServStatus",              currentQuote.record.ProServ_Status__c);
        component.set("v.mainAreaCode",               currentQuote.record.AreaCode__c);
        component.set("v.faxAreaCode",                currentQuote.record.FaxAreaCode__c);
        component.set("v.isMainPhoneVanity",          currentQuote.record.Main_Vanity_Number__c);
        component.set("v.isFaxPhoneVanity",           currentQuote.record.Fax_Vanity_Number__c);
        component.set("v.numberOfProServUsers",       currentQuote.record.ProServUsers__c);
        component.set("v.proServProjectManager",      currentQuote.record.ProServProjectManager__c);
        component.set("v.proServSalesRep",            currentQuote.record.ProServSalesRep__c);
        component.set("v.proServForecastedCloseDate", currentQuote.record.ProServ_Forecasted_Close_Date__c);
        component.set("v.proServForecastCategory",    currentQuote.record.ProServ_Forecast_Category__c);
        component.set("v.proServProjectComplexity",   currentQuote.record.PSProjectComplexity__c);
        component.set("v.proServTE",                  currentQuote.record.T_E__c);
        component.set("v.totalProjectHoursQuoted",    currentQuote.record.TotalProjectHoursQuoted__c);
        component.set("v.proServSOWType",             currentQuote.record.SOW_Type__c);
        component.set("v.freeMonthDiscount",          creditAmount + freeServiceTaxes);
        component.set("v.signedCOD",                  currentQuote.record.Signed_COD__c);
        this.fetchOriginalSOW(component, currentQuote);
        component.set("v.originalSOWQuoteNumber",     currentQuote.record.Original_SOW_Quote_Number__c);
        component.set("v.provisioningDetails",        currentQuote.record.Opportunity.ProvisioningDetails__c);
        component.set("v.selfProvisioned",            currentQuote.record.Opportunity.SelfProvisioned__c);
        component.set("v.proServOfferType",           currentQuote.record.PSOfferType__c);
        component.set("v.ASAOwner",                   currentQuote.record.ASA_Owner__c);
        component.set("v.PSSegment",                   currentQuote.record.PS_Segment__c);
        component.set("v.psMonthlyRecurringServicesValueARR",currentQuote.record.PSMonthlyRecurringServicesValueARR__c);
        component.set('v.shippingLocation', {
            country:                currentQuote.record.Shipping_Country__c,
            city:                   currentQuote.record.Shipping_City__c,
            state:                  currentQuote.record.Shipping_State__c,
            addressLine:            currentQuote.record.Shipping_Address_Line__c,
            postalCode:             currentQuote.record.Shipping_Postal_Code__c,

            shippingOption:         currentQuote.record.Shipping_Option__c,
            shipAttentionTo:        currentQuote.record.Ship_Attention_To__c,
            additionalAddressLine:  currentQuote.record.Shipping_Additional_Address_Line__c,
            customerName:           currentQuote.record.Shipping_Customer_Name__c,
            multipleLocations:      currentQuote.record.MultipleShippingLocations__c,
        });

        if(component.get("v.signedSOW")) {
            component.find("signedSOW").hideInput();
        }
        if(component.get("v.signedCOD")) {
            component.find("signedCOD").hideInput();
        }
        // Number fields in lightning can't properly clear themselves if value empty, so we rerender them
        if (!currentQuote.record.Number_of_ProServ_Phases__c){
            component.set("v.renderNumberOfProServPhases", false);
            component.set("v.renderNumberOfProServPhases", true);
        }
        if (!currentQuote.record.Number_of_Hardware_Shipment_Phases__c){
            component.set("v.renderNumberOfHardwareShipmentPhases", false);
            component.set("v.renderNumberOfHardwareShipmentPhases", true);
        }
        component.set("v.numberOfProServPhases",            currentQuote.record.Number_of_ProServ_Phases__c);
        component.set("v.numberOfHardwareShipmentPhases",   currentQuote.record.Number_of_Hardware_Shipment_Phases__c);

        // Search fields should be resetted to avoid leaving old values when changing quotes (CRM-312)
        component.find("proServProjectManager") && component.find("proServProjectManager").set("v.searchText", "");
        component.find("proServSalesRep") && component.find("proServSalesRep").set("v.searchText", "");
        component.set("v.UIDfrombiz", currentQuote.record.UID_from_biz__c);
    },

    fetchOriginalSOW: function(component, currentQuote) {

        component.set("v.signedSOW", currentQuote.record.Signed_SOW__c);
        component.set("v.Wizard.user.isMayEditSignedSOW", true);
        component.set("v.Wizard.isSOWAutoPopulated", false);
        if (!currentQuote.isCCorProServ && currentQuote.record.Upsell_Status__c !== 'New' && currentQuote.record.Opportunity.Parent_Order__c != null) {
            var action = component.get("c.fetchOriginalSOW");
            action.setParams({ accountId : currentQuote.record.AccountId });
            action.setCallback(this, function(response) {
                var state = response.getState();
                if (state === "SUCCESS") {
                    var value = response.getReturnValue();
                    if (value != null) {
                        component.set("v.signedSOW", value);
                        component.set("v.Wizard.user.isMayEditSignedSOW", false);
                        component.set("v.Wizard.isSOWAutoPopulated", true);
                    }
                } else {
                    console.log("fetchOriginalSOW method failed with status: " + state);
                    component.set("v.signedSOW", currentQuote.record.Signed_SOW__c);
                }
            });
            $A.enqueueAction(action);
        }
    },

    setInputsDisabling: function(component) {
        var state = component.get('v.state');
        var Wizard = component.get('v.Wizard');
        var mainACType = component.get('v.mainAreaCodeObj.RecordObj.Type__c');
        var faxACType = component.get('v.faxAreaCodeObj.RecordObj.Type__c');
        var isAreaCodeLineItemsMissed = component.get('v.isAreaCodeLineItemsMissed');
        var selfProvisionedCheckbox = component.find('self-provisioned');

        if(!Wizard.currentQuote) return;

        var quoteNameInput = false;
        var expirationDateInput = false;
        var startDateInput = false;
        var specialTermsInput = false;
        var initialTermInput = false;
        var renewalTermInput = false;
        var autoRenewalInput = false;
        var justificationInput = false;
        var isQuoteTypeInputDisabled = false;
        var quoteDescriptionInput = true;
        var numberOfHardwareShipmentPhasesInput = true;
        var proServForecastedCloseDateInput = true;
        var proServForecastCategoryInput = true;
        var proServOfferTypeInput = true;
        var proServProjectComplexityInput = true;
        var proServTEInput = true;
        var proServSowTypeInput = true;
        var numberOfProServPhasesInput = true;
        var isShippingLocationDisabled = true;

        var isMainPhoneVanityDisabled = true;
        var isFaxPhoneVanityDisabled = true;

        var isMainAreaCodeDisabled = false;
        var isFaxAreaCodeDisabled = false;
        var isProvDetailsDisabled = false;
        var isSelfProvisionedDisabled = false;
        var signedCODDisabled = false;


        var showQuoteTypeDisabledTooltip = false;

        var originalSOWInput = false;
        var numberOfProServUsersInput = false;
        var ASAOwnerInput = false;
        var PSSegmentInput = false;
        var ProServArchitectInput = false;
        var ProServPMInput = false;
        var proServForecastedCloseDate2Input = false;
        var psMonthlyRecurringServicesValueARRInput = false;

        var isProServSalesRepDisabled = !Wizard.settings.userPermissions.EditProServSalesRepField
            || Wizard.currentQuote.isOnApproval;
        var isProServProjectManagerDisabled = !Wizard.settings.userPermissions.EditProServProjectManagerField
            || Wizard.currentQuote.isOnApproval;

        if (Wizard.opportunity.isClosed
            || Wizard.currentQuote.isOnApproval
            || !Wizard.currentQuote.isUserHasPermissionToEditQuote
            || Wizard.currentQuote.isActiveAgreement
            || Wizard.currentQuote.isCancelled
            || Wizard.currentQuote.isSold
            || Wizard.currentQuote.isInvalid) {

            quoteNameInput = true;
            expirationDateInput = true;
            startDateInput = true;
            specialTermsInput = true;
            initialTermInput = true;
            renewalTermInput = true;
            autoRenewalInput = true;
            justificationInput = true;
            isMainAreaCodeDisabled = true;
            isFaxAreaCodeDisabled = true;
            isQuoteTypeInputDisabled = true;
            isProvDetailsDisabled = true;
            isSelfProvisionedDisabled = true;
            originalSOWInput = true;
            numberOfProServUsersInput = true;
            ASAOwnerInput = true;
            PSSegmentInput = true;
            ProServArchitectInput = true;
            ProServPMInput = true;
            proServForecastedCloseDate2Input = true;
            signedCODDisabled = true;
            psMonthlyRecurringServicesValueARRInput = true;
        } else if (Wizard.currentQuote.isAgreement){

            // On Agreement all fields disabled except Quote Type (Stage)
            quoteNameInput = true;
            expirationDateInput = true;
            startDateInput = true;
            specialTermsInput = true;
            initialTermInput = true;
            renewalTermInput = true;
            autoRenewalInput = true;
            justificationInput = true;
            isMainAreaCodeDisabled = true;
            isFaxAreaCodeDisabled = true;
            psMonthlyRecurringServicesValueARRInput = true;
        } else if (Wizard.currentQuote.isCCorProServ) {

            // B-1623 All fields should be read-only on Pro Serv Quote except Expiration Date
            quoteNameInput = true;
            isQuoteTypeInputDisabled = true;
            startDateInput = true;
            specialTermsInput = true;
            initialTermInput = true;
            renewalTermInput = true;
            autoRenewalInput = true;
            quoteDescriptionInput = false;
            numberOfHardwareShipmentPhasesInput = false;
            proServForecastedCloseDateInput = false;
            proServForecastCategoryInput = false;
            proServProjectComplexityInput = false;
            proServTEInput = false;
            proServSowTypeInput = false;
            numberOfProServPhasesInput = false;
            proServOfferTypeInput = false;
            psMonthlyRecurringServicesValueARRInput = false;
        } else {
            isShippingLocationDisabled = false;

            // A Sales Rep shouldn't have ability to change Stage or Agreement status of the Quote
            // if there are errors
            if (Wizard.currentQuote.isHasErrors
                || Wizard.currentQuote.isApprovalRequired
                    // Fax an Main area codes are required on new customer quotes
                || (Wizard.currentQuote.isNewCustomer &&
                    (!Wizard.currentQuote.record.AreaCode__c
                        // But Fax area code is not in use with Google service plans
                        || (!Wizard.currentQuote.record.FaxAreaCode__c && (!state.isQuoteHasGoogleServicePlan ||
                            (state.isQuoteHasGoogleServicePlan && !state.isQuoteHasRingCentralOrCanadaServicePlan)) ) ))
                //If there are no qlis with product2.Family = "Taxes" and if Estimated_Taxes_Request_Failed__c == false
                || !Wizard.currentQuote.record.Estimated_Taxes_Request_Failed__c && !state.isQuoteHasTaxes
                || Wizard.currentQuote.isWrongBillingAddress
                || isAreaCodeLineItemsMissed) {

                isQuoteTypeInputDisabled = true;
                showQuoteTypeDisabledTooltip = true;
            }

            if (Wizard.isCCProServEngagementRequired
                || Wizard.isProServSyncRequired
                || Wizard.isCCProServSyncRequired
                || Wizard.currentQuote.isSales
                    && Wizard.currentQuote.isMonthlyPlan
                || Wizard.ccProServQuote
                    && !Wizard.ccProServQuote.isSold
                    && !Wizard.ccProServQuote.isOutForSignature
                    && !Wizard.ccProServQuote.isCancelled
                || Wizard.proServQuote
                    && !Wizard.proServQuote.isSold
                    && !Wizard.proServQuote.isOutForSignature
                    && !Wizard.proServQuote.isCancelled){
                isQuoteTypeInputDisabled = true;
            }

            if(state.isVanityNumbersAllowed){

                if(mainACType  === 'Toll-Free'){
                    isMainPhoneVanityDisabled = false;
                }

                if(faxACType  === 'Toll-Free'){
                    isFaxPhoneVanityDisabled = false;
                }

            }

        }

        if (quoteNameInput) {
            $A.util.addClass(component.find("quoteNameEditLink"), "slds-hide");
        } else {
            $A.util.removeClass(component.find("quoteNameEditLink"), "slds-hide");
        }

        //Make credit amount field grey when opportunity is in closed won stage
        if(Wizard.opportunity.isClosed || Wizard.opportunity.isPendingConfirmAndClose) {
            $A.util.addClass(component.find("creditAmount"), "testdisabled");
        } else {
            $A.util.removeClass(component.find("creditAmount"), "testdisabled");
        }
        component.find("quoteName")                 .set("v.disabled", quoteNameInput);
        component.find("quote-type")                .set("v.disabled", isQuoteTypeInputDisabled);
        component.find("expirationDate")            .set("v.disabled", expirationDateInput);
        component.find("agreementStatus")           .set("v.disabled", true);
        component.find("startDate")                 .set("v.disabled", startDateInput);
        component.find("specialTerms")              .set("v.disabled", specialTermsInput);
        component.find("initialTerm")               .set("v.disabled", initialTermInput);
        component.find("renewalTerm")               .set("v.disabled", renewalTermInput);
        component.find("auto-renewal")              .set("v.disabled", autoRenewalInput);
        component.find("justification")             .set("v.disabled", justificationInput);
        component.find("quoteDescription")          .set("v.disabled", quoteDescriptionInput);
        component.find("isMainPhoneVanity")         .set("v.disabled", isMainPhoneVanityDisabled);
        component.find("isFaxPhoneVanity")          .set("v.disabled", isFaxPhoneVanityDisabled);
        component.find("mainAreaCode")              .set("v.disabled", isMainAreaCodeDisabled);
        component.find("faxAreaCode")               .set("v.disabled", isFaxAreaCodeDisabled);
        component.find("proServSalesRep")           .set("v.disabled", isProServSalesRepDisabled);
        component.find("proServProjectManager")     .set("v.disabled", isProServProjectManagerDisabled);
        component.find("proServForecastedCloseDate").set("v.disabled", proServForecastedCloseDateInput);
        component.find("proServForecastCategory")   .set("v.disabled", proServForecastCategoryInput);
        component.find("proServProjectComplexity")  .set("v.disabled", proServProjectComplexityInput);
        component.find("proServTE")                 .set("v.disabled", proServTEInput);
        component.find("proServSOWType")            .set("v.disabled", proServSowTypeInput);
        component.find("shippingLocation")          .set("v.disabled", isShippingLocationDisabled);
        component.find("provisioning")              .set("v.disabled", isProvDetailsDisabled);
        component.find("proServOfferType")          .set("v.disabled", proServOfferTypeInput);

        component.find("originalSOWQuoteNumber")    .set("v.disabled", originalSOWInput);
        component.find("numberOfProServUsers")      .set("v.disabled", numberOfProServUsersInput);
        component.find("numberOfProServUsers2")     .set("v.disabled", numberOfProServUsersInput);
        component.find("proServASAOwner")           .set("v.disabled", ASAOwnerInput);
        component.find("PSSegment")                 .set("v.disabled", PSSegmentInput);
        component.find("proServSalesRep")           .set("v.disabled", ProServArchitectInput);
        component.find("proServProjectManager")     .set("v.disabled", ProServPMInput);
        component.find("proServForecastedCloseDate2").set("v.disabled", proServForecastedCloseDate2Input);
        component.find("psMonthlyRecurringServicesValueARR").set("v.disabled", psMonthlyRecurringServicesValueARRInput);

        component.set('v.numberOfHardwareShipmentPhasesDisabled', numberOfHardwareShipmentPhasesInput);
        component.set('v.numberOfProServPhasesDisabled', numberOfProServPhasesInput);
        component.set("v.showQuoteTypeDisabledTooltip", showQuoteTypeDisabledTooltip);
        component.set("v.signedCODDisabled", signedCODDisabled);

        if (selfProvisionedCheckbox) {
            selfProvisionedCheckbox.set("v.disabled", isSelfProvisionedDisabled);
        }
    },
    /**
     * Calculate and set End Date
     * End Date = Start Date + Initial Term
     * @param component
     */
    setEndDate: function(component) {
        var startDateValue = component.get('v.startDate');
        var iTermValue = component.get('v.iTerm');
        var currentQuote = component.get('v.Wizard.currentQuote');
        var startDateErrors = component.find("startDate").get('v.errors');
        var initialTermErrors = component.find("initialTerm").get('v.errors');
        var endDateValue = '';

        if ((startDateErrors && startDateErrors.length > 0) ||
            (initialTermErrors && initialTermErrors.length > 0)) {
            endDateValue = 'Validation error';

        } else {
            if (startDateValue && iTermValue) {
                if ((startDateValue !== currentQuote.record.Start_Date__c)
                    || (iTermValue !== currentQuote.record.Initial_Term_months__c)) {
                    endDateValue = QW.moment(startDateValue).add(iTermValue, "months").format('YYYY-MM-DD');

                } else {
                    endDateValue = currentQuote.record.End_Date__c;

                }

            }

        }
        component.set('v.endDate', endDateValue);
    },
    /**
     * Rearrange layout, show or hide fields for ProServ, Relayware, and Sales quotes
     * - B-897, B-1462 Quote Wizard Changes for Relayware
     */
    rearrangeLayout: function(component) {
        var state = component.get('v.state');
        var Wizard = component.get('v.Wizard');
        if (!Wizard.currentQuote)
            return;


        var isFaxAreaCodeUnavailable = state.isQuoteHasGoogleServicePlan && state.isQuoteHasRingCentralOrCanadaServicePlan;

        QW.cssUtils.toggleShow(component, 'autoRenewalBlock', !state.isUserRelayware && !state.isQuoteHasMonthlyServicePlan);
        component.find('expirationDateBlock').set('v.size',   Wizard.currentQuote.isCCorProServ || Wizard.user.isRelayware ? 6 : 4);

        QW.cssUtils.toggleShow(component, 'proServPhasesBlock',                   Wizard.currentQuote.isCCorProServ);
        QW.cssUtils.toggleShow(component, 'proServOfferTypeBlock',                Wizard.currentQuote.isCCorProServ);
        QW.cssUtils.toggleShow(component, 'numberOfHardwareShipmentPhasesBlock',  Wizard.currentQuote.isProServ);
        QW.cssUtils.toggleShow(component, 'proServForecastedCloseDateBlock',      Wizard.currentQuote.isProServ);
        QW.cssUtils.toggleShow(component, 'proServForecastedCloseDateBlock2',     Wizard.currentQuote.isCCorProServ && !Wizard.currentQuote.isProServ);
        QW.cssUtils.toggleShow(component, 'numberOfProServUsersBlock',            Wizard.currentQuote.isProServ);
        QW.cssUtils.toggleShow(component, 'numberOfProServUsersBlock2',           Wizard.currentQuote.isCCorProServ && !Wizard.currentQuote.isProServ);
        QW.cssUtils.toggleShow(component, 'signedSOWBlock',                       Wizard.currentQuote.isCCorProServ);
        QW.cssUtils.toggleShow(component, 'signedCODBlock',                       (Wizard.currentQuote.isCCorProServ || Wizard.currentQuote.isProServ) && !state.isNewCustomer);
        QW.cssUtils.toggleShow(component, 'originalSOWQuoteNumberBlock',          Wizard.currentQuote.isCCorProServ || Wizard.currentQuote.isProServ);
        QW.cssUtils.toggleShow(component, 'provisioningBlock',                    !Wizard.currentQuote.isCCorProServ
                                                                               && Wizard.settings.featureToggle.ProvisioningDetailsField__c);
        QW.cssUtils.toggleShow(component, 'psMonthlyRecurringServicesValueARRBlock',Wizard.currentQuote.isCCorProServ);

        // Number Of ProServ Phases
        QW.cssUtils.toggleShow(component, 'numberOfProServPhasesBlock',  false);
        component.find('numberOfHardwareShipmentPhasesBlock').set('v.size', 6);
        QW.cssUtils.toggleClass(component, 'numberOfHardwareShipmentPhasesBlock', false, 'slds-p-left--small');
        QW.cssUtils.toggleShow(component, 'proServPhasesBlock', Wizard.currentQuote.isProServ);

        QW.cssUtils.toggleShow(component, 'quoteDescriptionBlock',        Wizard.currentQuote.isCCorProServ);
        QW.cssUtils.toggleShow(component, 'proServStatusBlock',           Wizard.currentQuote.isCCorProServ);
        QW.cssUtils.toggleShow(component, 'proServUsersBlock',            Wizard.currentQuote.isCCorProServ || Wizard.currentQuote.isExtendedEnterpriseProdInCart);
        QW.cssUtils.toggleShow(component, 'proServManagerField',          Wizard.currentQuote.isCCorProServ);
        QW.cssUtils.toggleShow(component, 'proServASAOwnerField',         Wizard.currentQuote.isCCorProServ);
        QW.cssUtils.toggleShow(component, 'PSSegmentField',         Wizard.currentQuote.isCCorProServ || Wizard.currentQuote.isProServ);
        QW.cssUtils.toggleShow(component, 'proServForecastedBlock',       Wizard.currentQuote.isProServ);
        QW.cssUtils.toggleShow(component, 'proServSowTypeBlock',          Wizard.currentQuote.isCCorProServ);
        QW.cssUtils.toggleShow(component, 'proServProjectComplexityBlock',Wizard.currentQuote.isCCorProServ);
        QW.cssUtils.toggleShow(component, 'proServTEBlock',               Wizard.currentQuote.isCCorProServ);
        QW.cssUtils.toggleShow(component, 'totalProjectHoursQuotedBlock', Wizard.currentQuote.isCCorProServ);

        var proServSalesRepComponent = component.find('proServSalesRep');
        component.find('proServSalesRep').set('v.disabled',        !(Wizard.user.isMayEditProServArchOnSalesQuote));
        component.find('PSSegmentField').set('v.disabled',        !(Wizard.user.isMayEditPSSegment));
        component.find('proServSalesRep').set('v.tooltipText',
            proServSalesRepComponent.get('v.disabled') && (proServSalesRepComponent.get('v.value') == null)
                                                       && !Wizard.currentQuote.isCCorProServ
                //The ProServ team must populate this field if Extended Enterprise Support has been quoted
                ? QW.popover.MESSAGES.SalesQuoteSalesRepPopover.text
                : "");
        QW.cssUtils.toggleClass(component, 'proServArchitectField',  Wizard.currentQuote.isCCorProServ, 'is-required');

        component.find('quoteNumberBlock').set('v.size',             Wizard.currentQuote.isCCorProServ ? 6 : 4);
        component.find('proServArchitectField').set('v.size',        Wizard.currentQuote.isCCorProServ ? 6 : 12);
        QW.cssUtils.toggleClass(component, 'quoteNumberBlock',      !Wizard.currentQuote.isCCorProServ, 'slds-p-right--x-small');
        QW.cssUtils.toggleShow(component, 'quoteNameBlock',         !Wizard.currentQuote.isCCorProServ);


        QW.cssUtils.toggleShow(component, 'blockC',                 !Wizard.currentQuote.isCCorProServ);
        QW.cssUtils.toggleShow(component, 'blockD',                 !Wizard.currentQuote.isCCorProServ);
        QW.cssUtils.toggleShow(component, 'agreementStatusBlock',   !Wizard.currentQuote.isCCorProServ && !Wizard.user.isRelayware);
        QW.cssUtils.toggleShow(component, 'specialTermsBlock',      !Wizard.currentQuote.isCCorProServ && !Wizard.user.isRelayware);
        QW.cssUtils.toggleShow(component, 'mainAreaCodeComboBlock', !Wizard.currentQuote.isCCorProServ && Wizard.currentQuote.isAreaCodesAllowed);
        QW.cssUtils.toggleShow(component, 'faxAreaCodeComboBlock',  !Wizard.currentQuote.isCCorProServ && Wizard.currentQuote.isAreaCodesAllowed && !isFaxAreaCodeUnavailable);
        QW.cssUtils.toggleShow(component, 'creditAmountBlock',      !Wizard.currentQuote.isCCorProServ);
        QW.cssUtils.toggleShow(component, 'shippingLocationBlock',  !Wizard.currentQuote.isCCorProServ && Wizard.settings.featureToggle.ShippingDetailsField__c);

        // Justification Vertical Size change
        var justificationCSSclass = 'textarea-vsize--';
        var justificationVsize = (!Wizard.currentQuote.isAreaCodesAllowed && Wizard.currentQuote.isSales) ? 5 :
            ( Wizard.currentQuote.isProServ || Wizard.currentQuote.isExtendedEnterpriseProdInCart ? 4 :
                ( Wizard.currentQuote.isCCProServ || Wizard.currentQuote.isExtendedEnterpriseProdInCart ? 6 :
                    ( isFaxAreaCodeUnavailable ? 3 : 2 ) ) );

        // Remove previous v-size classes
        var vSizeRows = [2, 3, 4, 5];
        vSizeRows.filter(function(i) { return i !== justificationVsize; }).forEach(function(i){
            $A.util.removeClass(component.find('justification'), justificationCSSclass + i );
        });
        // Add new v-size class
        $A.util.addClass(component.find('justification'), justificationCSSclass + justificationVsize );

        // Quote Type
        QW.cssUtils.toggleShow(component, 'quoteTypeBlock',  !Wizard.currentQuote.isCCorProServ);
        component.find('quoteTypeBlock').set('v.size',        Wizard.user.isRelayware ? 6 : 4);
        QW.cssUtils.toggleClass(component, 'quoteTypeBlock', !Wizard.user.isRelayware, 'slds-p-horizontal--x-small');
        QW.cssUtils.toggleClass(component, 'quoteTypeBlock',  Wizard.user.isRelayware, 'slds-p-left--x-small');

        // Is Main Vanity
        QW.cssUtils.toggleShow(component, 'isMainPhoneVanityBlock', state.isVanityNumbersAllowed);
        component.find('mainAreaCodeBlock').set('v.size',           state.isVanityNumbersAllowed ? 10 : 12);

        // Is Fax Vanity
        QW.cssUtils.toggleShow(component, 'isFaxPhoneVanityBlock', state.isVanityNumbersAllowed);
        component.find('faxAreaCodeBlock').set('v.size',           state.isVanityNumbersAllowed ? 10 : 12);

        // Initial term
        component.find('initialTermBlock').set('v.size',       !Wizard.user.isRelayware ? 4 : 6);

        // Renewal Term
        component.find('renewalTermBlock').set('v.size',       !Wizard.user.isRelayware ? 4 : 6);
        QW.cssUtils.toggleClass(component, 'renewalTermBlock', !Wizard.user.isRelayware, 'slds-p-horizontal--x-small');
        QW.cssUtils.toggleClass(component, 'renewalTermBlock',  Wizard.user.isRelayware, 'slds-p-left--x-small');

        QW.cssUtils.toggleClass(component, 'provisioningBlock', !Wizard.currentQuote.isCCorProServ && Wizard.currentQuote.isDownsell, 'is-required');
    },
    /**
     * Check if there is any changes in quote summary
     * @param component
     */
    checkUnsavedChanges: function(component){
        var currentQuote = component.get('v.Wizard.currentQuote');
        var opp = component.get('v.Wizard.opportunity');

        var isSummaryChanged = false;
        var fields = [
            { attr:'rTerm',                            field: 'Term_months__c',                          auraId: 'renewalTerm' },
            { attr:'iTerm',                            field: 'Initial_Term_months__c',                  auraId: 'initialTerm' },
            { attr:'status',                           field: 'Status',                                  auraId: 'agreementStatus' },
            { attr:'specialTerms',                     field: 'Special_Terms__c',                        auraId: 'specialTerms' },
            { attr:'justification',                    field: 'JustificationandDescription__c',          auraId: 'justification' },
            { attr:'autoRenewal',                      field: 'Auto_Renewal__c',                         auraId: 'auto-renewal' },
            { attr:'quoteType',                        field: 'QuoteType__c',                            auraId: 'quote-type' },
            { attr:'expirationDate',                   field: 'ExpirationDate',                          auraId: 'expirationDate' },
            { attr:'startDate',                        field: 'Start_Date__c',                           auraId: 'startDate' },
            { attr:'endDate',                          field: 'End_Date__c',                             auraId: 'endDate' },
            { attr:'nameQuote',                        field: 'Name',                                    auraId: 'quoteName' },
            { attr:'quoteDescription',                 field: 'Quote_Description__c',                    auraId: 'quoteDescription' },
            { attr:'mainAreaCode',                     field: 'AreaCode__c',                             auraId: 'mainAreaCode' },
            { attr:'faxAreaCode',                      field: 'FaxAreaCode__c',                          auraId: 'faxAreaCode' },
            { attr:'isMainPhoneVanity',                field: 'Main_Vanity_Number__c',                   auraId: 'isMainPhoneVanity' },
            { attr:'isFaxPhoneVanity',                 field: 'Fax_Vanity_Number__c',                    auraId: 'isFaxPhoneVanity' },
            { attr:'numberOfProServPhases',            field: 'Number_of_ProServ_Phases__c',             auraId: 'numberOfProServPhases' },
            { attr:'numberOfHardwareShipmentPhases',   field: 'Number_of_Hardware_Shipment_Phases__c',   auraId: 'numberOfHardwareShipmentPhases' },
            { attr:'proServForecastedCloseDate',       field: 'ProServ_Forecasted_Close_Date__c',        auraId: 'proServForecastedCloseDate' },
            { attr:'proServForecastedCloseDate',       field: 'ProServ_Forecasted_Close_Date__c',        auraId: 'proServForecastedCloseDate2' },
            { attr:'numberOfProServUsers',             field: 'ProServUsers__c',                         auraId: 'numberOfProServUsers' },
            { attr:'proServOfferType',                 field: 'PSOfferType__c',                          auraId: 'proServOfferType' },
            { attr:'proServProjectComplexity',         field: 'PSProjectComplexity__c',                  auraId: 'proServProjectComplexity' },
            { attr:'proServForecastCategory',          field: 'ProServ_Forecast_Category__c',            auraId: 'proServForecastCategory' },
            { attr:'proServTE',                        field: 'T_E__c',                                  auraId: 'proServTE' },
            { attr:'proServProjectManager',            field: 'ProServProjectManager__c',                auraId: 'proServProjectManager' },
            { attr:'proServSOWType',                   field: 'SOW_Type__c',                             auraId: 'proServSOWType' },
            { attr:'signedSOW',                        field: 'Signed_SOW__c',                           auraId: 'signedSOW' },
            { attr:'signedCOD',                        field: 'Signed_COD__c',                           auraId: 'signedCOD' },
            { attr:'ASAOwner',                         field: 'ASA_Owner__c',                           auraId: 'proServASAOwner' },
            { attr:'PSSegment',                        field: 'PS_Segment__c',                           auraId: 'PSSegment' },
            { attr:'originalSOWQuoteNumber',           field: 'Original_SOW_Quote_Number__c',            auraId: 'originalSOWQuoteNumber' },
            { attr:'proServSalesRep',                  field: 'ProServSalesRep__c',                      auraId: 'proServSalesRep' },
            { attr:'psMonthlyRecurringServicesValueARR', field: 'PSMonthlyRecurringServicesValueARR__c', auraId: 'psMonthlyRecurringServicesValueARR' },
            { attr:'provisioningDetails',              field: 'Opportunity.ProvisioningDetails__c',      auraId: 'provisioning' },
            { attr:'selfProvisioned',                  field: 'Opportunity.SelfProvisioned__c',          auraId: 'self-provisioned' },
            { attr:'shippingLocation',                 fields: [
                    { prop: 'country',          field: 'Shipping_Country__c' },
                    { prop: 'city',             field: 'Shipping_City__c' },
                    { prop: 'state',            field: 'Shipping_State__c' },
                    { prop: 'addressLine',      field: 'Shipping_Address_Line__c' },
                    { prop: 'postalCode',       field: 'Shipping_Postal_Code__c' },
                    { prop: 'shippingOption',   field: 'Shipping_Option__c' },
                    { prop: 'shipAttentionTo',  field: 'Ship_Attention_To__c' },
                    { prop: 'additionalAddressLine', field: 'Shipping_Additional_Address_Line__c' },
                    { prop: 'customerName',     field: 'Shipping_Customer_Name__c' },
                    { prop: 'multipleLocations',field: 'MultipleShippingLocations__c' }
            ], auraId: 'shippingLocationBlock' },
            { attr:'UIDfrombiz',                        field: 'UID_from_biz__c',                           auraId: 'UIDfrombiz' },
        ];
        fields.forEach(function(f){
            var attrValue = component.get('v.' + f.attr);

            let fieldValue;
            let isFieldChanged;
            if (f.field) {
                if(f.attr === 'provisioningDetails') {
                    fieldValue = currentQuote.record.Opportunity.ProvisioningDetails__c;
                } else if (f.attr === 'selfProvisioned') {
                    fieldValue = currentQuote.record.Opportunity.SelfProvisioned__c;
                } else {
                    fieldValue = currentQuote.record[f.field];
                }
                isFieldChanged = RC.stringHelper.areNotEqual(attrValue, fieldValue);
                if(f.attr === 'provisioningDetails') opp.isProvDetailsFieldChanged = isFieldChanged;
                if(f.attr === 'selfProvisioned') opp.isSelfProvisionedFieldChanged = isFieldChanged;
            } else if (f.fields) {
                isFieldChanged = f.fields.some(p => {
                    fieldValue = currentQuote.record[p.field];
                    let propertyValue = component.get(`v.${f.attr}.${p.prop}`);
                    return RC.stringHelper.areNotEqual(propertyValue, fieldValue);
                })

            }

            isSummaryChanged = isFieldChanged || isSummaryChanged;

            // Highlight that field have unsaved changes
            if (f.auraId){
                QW.cssUtils.toggleClass(component, f.auraId, isFieldChanged, 'field-changed');
            }
        });

        if (!isSummaryChanged){
            QW.popover.hide();
        }

        component.set('v.isSummaryChanged', isSummaryChanged);
    },
    /**
     *  Initialize lookup filtering
     */
    setLookupParams: function(component){
        var brandName = component.get('v.Wizard.currentQuote.record.Pricebook2.Brand__r.Name');
        component.set('v.areaCodeMainLookUpParams', {
            brand: brandName,
            type: 'main'
        });
        component.set('v.areaCodeFaxLookUpParams', {
            brand: brandName,
            type: 'fax'
        });
    },
    /**
     * Show Popover for specified element
     * @param component
     * @param auraId
     */
    showPopover: function(component, auraId){
        var messages = [];
        var Wizard = component.get('v.Wizard');
        var state = component.get('v.state');
        var currentQuote = component.get('v.Wizard.currentQuote');

        // Do not show any popovers during freeze
        if (component.get('v.popoverFreeze')) return;

        switch (auraId){

            // Special Terms
            case 'specialTermsDiv':
                if (this.isInitialTermAndSpecialTermWeeksNotRecommended(component)){
                    messages.push(QW.popover.MESSAGES.specialTermsFreeWeeks);
                }
                break;

            // Renewal Term
            case 'renewalTermDiv':
                if (this.isRenewalTermInitialTermNotRecommended(component)){
                    messages.push(QW.popover.MESSAGES.renewalTermLessThanInitialTerm);
                }
                break;

            // Vanity Checkboxes
            case 'isMainPhoneVanityTooltip':
            case 'isFaxPhoneVanityTooltip':
                messages.push(QW.popover.MESSAGES.vanityTollFree);
                break;

            // Quote Stage
            case 'quoteTypeDiv':
                //You do not need an agreement for Monthly Service Plan
                if (Wizard.currentQuote.isMonthlyPlan) {
                    messages.push(QW.popover.MESSAGES.activeAgreementNotRequiredOnMonthlyPlan);
                } else {
                    // There are errors on the quote
                    if (component.get('v.showQuoteTypeDisabledTooltip')) {
                        messages.push(QW.popover.MESSAGES.quoteTypeErrors);
                    }
                    // Taxes are not added or estimated taxes request failed
                    if (!Wizard.currentQuote.record.Estimated_Taxes_Request_Failed__c && !state.isQuoteHasTaxes) {
                        messages.push(QW.popover.MESSAGES.quoteTypeHasNoTaxes);
                    }
                }
                // Billing address on the quote must match to the address on the Account
                if(Wizard.currentQuote.isWrongBillingAddress && !Wizard.currentQuote.isAgreement) {
                   messages.push(QW.popover.MESSAGES.quoteTypeWrongBillingAddress);
                }
                // Professional Services Sync is Required
                if (Wizard.isProServSyncRequired){
                    messages.push(QW.popover.MESSAGES.quoteTypeProServNotSynced);
                }
                // Contact Center Professional Services Sync is Required
                if (Wizard.isCCProServSyncRequired){
                    messages.push(QW.popover.MESSAGES.quoteTypeCCProServNotSynced);
                }
                // Contact Center Professional Services Engagement is Required
                if (Wizard.isCCProServEngagementRequired){
                    messages.push(QW.popover.MESSAGES.quoteTypeCCProServNotEngaged);
                }
                // Quote is not approved
                if (Wizard.currentQuote.isOnApproval || Wizard.currentQuote.isApprovalRequired){
                    messages.push(QW.popover.MESSAGES.quoteIsNotApproved);
                }
                if (Wizard.ccProServQuote && (!Wizard.ccProServQuote.isSoldOrOutForSignature && !Wizard.ccProServQuote.isCancelled)
                    || Wizard.proServQuote && (!Wizard.proServQuote.isSoldOrOutForSignature && !Wizard.proServQuote.isCancelled)) {
                    messages.push(QW.popover.MESSAGES.quoteIsNotSoldOrCancelled);
                }
                // AreaCode items are missed
                if (component.get('v.isAreaCodeLineItemsMissed')) {
                    messages.push(QW.popover.MESSAGES.areaCodesAreMissed);
                }

                //You do not need an agreement for Professional Service Change Order Quote
                if (this.currentQuote.opportunity.record.Tier_Name__c == 'Professional Services' && this.currentQuote.opportunity.record.Parent_Order__c  !== null) {
                    messages.push(QW.popover.MESSAGES.activeAgreementNotRequiredForProServChangeOrder);
                }
                break;

            //Free Months Discount
            case 'freeMonthsDiscountToolTip':
                if(currentQuote.record.Estimated_Taxes_Request_Failed__c || !currentQuote.record.Free_Service_Taxes__c) {
                    messages.push(QW.popover.MESSAGES.freeMonthsDiscountWithoutTaxes);
                } else {
                    messages.push(QW.popover.MESSAGES.freeMonthsDiscountIncludesTaxes);
                }
                break;
        }

        // Get target
        var targetCmp = component.find(auraId);
        var target = targetCmp ? targetCmp.getElement() : null;

        if (target && messages.length > 0){
            QW.popover.show(target, messages);
        }
    },

    /*
     * value - value to test
     * range - array of 2 value [min, max]
     *          min or max can be omitted
     */
    checkRange: function(value, range) {
        var result = Number(value);

        if(range[0] && result < range[0]) result = range[0];
        else if(range[1] && result > range[1]) result = range[1];

        return result;
    },

    checkInteger: function(value) {
        return parseInt(value);
    },

    checkUserPermissions: function(component) {
        var settings = component.get('v.settings');

        if(!settings || !settings.userPermissions) return;

        if(settings.userPermissions.SeeExtendedInputInitialRenewalTerm) {
            component.set('v.extendedInputTerms', true);
        }
    },

    getPicklistOption: function(value) {
        return {
            label: value,
            value: value,
        }
    },

    getMissedOptionValues: function(picklistOptions, values) {
        var result = [];

        _.each(_.uniq(values), function(val) {
            (_.where(picklistOptions, {value: val}).length === 0) && result.push(val);
        });

        return result;
    },

    // Sometimes field value in database doesn't exist in viewed picklist values.
    // To show correct current value in picklist this method is used.
    // It takes the value from record and adds it to the possible picklist values.
    addMissedOptionValues: function(component) {
        var currentQuote = component.get('v.Wizard.currentQuote');

        var initialTermMonthsValues = component.get('v.initialTermMonthsValues');
        var termMonthsValues = component.get('v.termMonthsValues');
        var specialTermsValues = component.get('v.specialTermsValues');
        var quoteTypes = component.get('v.quoteTypeValues');

        var rTerm = currentQuote.record.Term_months__c;
        var iTerm = currentQuote.record.Initial_Term_months__c;
        var sTerm = currentQuote.record.Special_Terms__c;
        var currQuoteType = currentQuote.record.QuoteType__c;

        _.each(this.getMissedOptionValues(termMonthsValues, [rTerm, iTerm]), function(o) {
            termMonthsValues.push(this.getPicklistOption(o));
            initialTermMonthsValues.push(this.getPicklistOption(o));
        }, this);

        _.each(this.getMissedOptionValues(specialTermsValues, [sTerm]), function(o) {
            if(this.getPicklistOption(o).value) {
                specialTermsValues.push(this.getPicklistOption(o));
            }
        }, this);

        _.each(this.getMissedOptionValues(quoteTypes, [currQuoteType]), function(o) {
            quoteTypes.push(this.getPicklistOption(o));
        }, this);

        component.set('v.specialTermsValues', _.sortBy(specialTermsValues, 'value'));
        component.set('v.termMonthsValues', _.sortBy(termMonthsValues, 'value'));
        component.set('v.initialTermMonthsValues', _.sortBy(initialTermMonthsValues, 'value'));
        component.set('v.quoteTypeValues', quoteTypes);
    },

    creditAmountLabelChange: function(component) {

        var sTermValue = component.get("v.specialTerms");
        var currentQuote = component.get('v.Wizard.currentQuote');

        if ((sTermValue !== currentQuote.record.Special_Terms__c)) {
            if (sTermValue && (typeof sTermValue === 'string')) {
                if (sTermValue.toLowerCase().indexOf('free week') !== -1) {
                    component.set('v.creditAmountLabel', 'Free weeks discount');
                }
                if (sTermValue.toLowerCase().indexOf('free month') !== -1) {
                    component.set('v.creditAmountLabel', 'Free months discount');
                }
            }
        }

    },
    /**
     * Hide Quote Name Edit Input
     */
    hideQuoteNameInput: function(component) {
        $A.util.removeClass(component.find("quoteNameDisplay"), "hidden");
        $A.util.addClass(component.find("quoteNameInput"), "hidden");
    },

    validateAreaCodeLineItems: function(component) {
        component.set('v.isAreaCodeLineItemsMissed', false);
        var areaCodeLineItems = component.get('v.areaCodeItems');
        var cartItems = component.get('v.Wizard.currentQuote.cartItems');

        let quoteLineItemsidSet = [];
        areaCodeLineItems.forEach((acli) => {
            quoteLineItemsidSet.push(acli.Quote_Line_Item__c);
        });

        cartItems.forEach((qli) =>{

            var byPassItem = RC.Product2Helper.isGlobalOfficeLimitedExtensionProduct(qli.record.Product2);
            var isAreaCodeMissed = !quoteLineItemsidSet.includes(qli.record.Id);
            var isItemToCheck = RC.Product2Helper.isDiscountedPhone(qli.record.Product2)
                || RC.Product2Helper.isRentalPhone(qli.record.Product2)
                || RC.Product2Helper.isRefurbishedPhone(qli.record.Product2)
                || RC.Product2Helper.isAdditionaLocalNumber(qli.record.Product2);

            if (!byPassItem && isAreaCodeMissed && isItemToCheck && !qli.record.Zero_Quantity__c) {
                component.set('v.isAreaCodeLineItemsMissed', true);
            }
        });
    }
});