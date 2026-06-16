({
    documentClickHandler: null,

    createApp: function (component) {
        var app = new PM.classes.App();
        app.quote = component.get('v.quote');
        app.setChangeOrderPhases(component.get('v.changeOrderPhases'));
        app.isOnOrder = !!component.get('v.order');
        this.setAppPermissions(component, app);
        app.isNewChangeOrder = component.get('v.isNewChangeOrder');
        $A.localizationService.getToday($A.get("$Locale.timezone"), today => {
            app.today = today
        });

        Promise.resolve().then($A.getCallback(() => {
            return this.findMaxPhaseNumber(component);
        })).then($A.getCallback((maxPhaseNumber) => {
            app.orderMaxPhaseNumber = maxPhaseNumber;
            return this.getParentOrder(component);
        })).then($A.getCallback((parentOrder) => {
            app.parentOrder = parentOrder;

            PM.spinner.hide();
        }));
    },

    getParentOrder: function (component) {

        var order = component.get('v.order');
        var quote = component.get('v.quote');

        var orderOrOppId = null;

        if(order && order.Id) {
            orderOrOppId = order.Id;
        }else if(quote && quote.OpportunityId) {
            orderOrOppId = quote.OpportunityId
        }

        return PM.salesforce.request(component, 'c.findParentOrder', {
            oppOrOrderId: orderOrOppId
        }, $A).catch($A.getCallback(function (error) {
            $A.get("e.c:ToastEvent").setParams({
                theme: 'error',
                header: 'Failed to find Parent Order',
                details: PM.salesforce.getResponseError(error),
                defaultTimeout: false
            }).fire();
        })).then($A.getCallback(function (parentOrder) {
            return parentOrder;
        }));
    },

    findMaxPhaseNumber: function(component) {
        var defaultMaxPhaseNumber = 0;

        var order = component.get('v.order');
        var quote = component.get('v.quote');

        var orderId = null;
        if(order) {
            orderId = order.Id;
        }else if(!order && quote) {
            orderId = quote.Opportunity.Parent_Order__c
        }

        if(!orderId) {
            return Promise.resolve(defaultMaxPhaseNumber);
        }

        return PM.salesforce.request(component, 'c.findMaxPhaseNumberOnOrder', {
            orderId: orderId
        }, $A).catch($A.getCallback(function (error) {
            $A.get("e.c:ToastEvent").setParams({
                theme: 'error',
                header: 'Failed to find Max Phase Number on Order',
                details: PM.salesforce.getResponseError(error),
                defaultTimeout: false
            }).fire();
        })).then($A.getCallback(function (maxPhaseNumber) {
            return maxPhaseNumber;
        }));
    },

    setAppPermissions: function (component, app) {

        app = app || component.get('v.app');
        if (!app)
            return;

        app.isEditAllowed = component.get('v.isEditAllowed');
        app.isUnassignedAllowed = !app.isEditAllowed ? app.isEditAllowed : component.get('v.isUnassignedAllowed');
        app.isAddPhasesAllowed = !app.isEditAllowed ? app.isEditAllowed : component.get('v.isAddPhasesAllowed');
        app.isCompletePhaseAllowed = !app.isEditAllowed ? app.isEditAllowed : component.get('v.isCompletePhaseAllowed');
        app.isMoveProductsAllowed = !app.isEditAllowed ? app.isEditAllowed : component.get('v.isMoveProductsAllowed');
        app.isMoveSitesAllowed = !app.isEditAllowed ? app.isEditAllowed : component.get('v.isMoveSitesAllowed');
        app.isCartItemsEditAllowed = !app.isEditAllowed ? app.isEditAllowed : component.get('v.isCartItemsEditAllowed');
        app.isLocationsEnabled = component.get('v.isLocationsEnabled');

        this.updateUI(component, app);
    },

    documentClickHandlerHelper: function (component) {
        if (component.get('v.preventDeselection'))
            component.set('v.preventDeselection', false);
        else if (component.get('v.hasSelectedCartItems')) {
            this.deselectAll(component);
            component.set('v.hasSelectedCartItems', false);
        }
    },

    addEventListeners: function (component) {
        this.documentClickHandler = this.documentClickHandlerHelper.bind(this, component);
        document.addEventListener('click', this.documentClickHandler, false);
    },

    removeEventListeners: function () {
        document.removeEventListener('click', this.documentClickHandler, false);
    },

    getPhases: function (component) {
        var quoteId = component.get('v.quote.Id');
        var orderId = component.get('v.order.Id');

        return PM.salesforce.request(component, 'c.getPhases', {
            sObjectId: quoteId || orderId
        }, $A)
            .catch($A.getCallback(function (error) {
                console.error(error);
                $A.get("e.c:ToastEvent").setParams({
                    theme: 'error',
                    header: 'Failed to get Phases',
                    details: PM.salesforce.getResponseError(error),
                    defaultTimeout: false
                }).fire();
            }))
            .then($A.getCallback(function (phases) {
                component.set('v.phases', phases);
            }));
    },

    refreshApp: function (component, phases) {
        var app = component.get('v.app');
        var QuoteLineItems = component.get('v.cartItems');

        if (!app) {
            this.createApp(component);
            app = component.get('v.app');
        }

        // Fix afterRender threw an error in 'lightning:input'
        app.phases.forEach(phase => {
            phase.dragItems.forEach(dragItem => {
                dragItem.locations = [];
            });
        });
        component.set('v.app', app);
        // Fix End

        app.init({phaseSObjects: phases, quoteLineItemSObjects: QuoteLineItems, quote: component.get('v.quote')});

        this.updateUI(component, app);
    },

    /**
     * Creates new empty phase
     * Creation is available only when open in Quoting Wizard on Quote
     */
    createPhase: function (component) {
        var app = component.get('v.app');
        var quote = component.get('v.quote');
        var order = component.get('v.order');

        var newPhase = new PM.classes.Phase();

        if(!quote && order) {
            newPhase.opportunityId = order.Opportunity__c;
            newPhase.quoteId = app.phases.find(p => p.record).record.Quote__c;
            newPhase.orderId = order.Id;

        } else {
            newPhase.quoteId = quote.Id;
            newPhase.opportunityId = quote.OpportunityId;

        }

        app.addPhase(newPhase);

        component.set('v.app', app);
    },

    reloadChangeOrderPhases: function (component) {
        var quote = component.get('v.quote');
        var optyId = quote.OpportunityId;
        return PM.salesforce.request(component, 'c.getPhasesBeforeChangeOrder', {
            optyId
        }, $A)
            .then($A.getCallback(function (changeOrderPhases) {
                component.set('v.changeOrderPhases', changeOrderPhases);
            }))
            .catch($A.getCallback(function (error) {
                console.error(error);
                $A.get("e.c:ToastEvent").setParams({
                    theme: 'error',
                    header: 'Failed to get change order Phases',
                    details: PM.salesforce.getResponseError(error),
                    defaultTimeout: false
                }).fire();
            }));
    },

    deselectAll: function (component) {
        var app = component.get('v.app');

        app.deselectAll();

        // Update UI
        this.updateUI(component, app);
    },

    getErrors: function (component, onSave) {
        var app = component.get('v.app');

        var hasErrors = false;
        app.phases.forEach(function (phase) {
            // bypass checks on completed and deleted phases
            if (phase.isComplete || phase.isDeleted || (phase.isAtDeleteStatus && app.isNewChangeOrder)) {
                return;
            }

            // Estimated date is empty
            //Commented out for B-4062, should be enabled later
            //phase.hasEstDateError = !phase.estimatedCompletionDate && onSave;
            phase.isEmptyError = false;

            // Estimated date is in the past
            if (phase.estimatedCompletionDate) {
                var now = new Date();
                now.setHours(0, 0, 0, 0);

                var estDate = new Date(phase.estimatedCompletionDate);
                estDate.setHours(0, 0, 0, 0);

                phase.hasEstDateError = now > estDate;
            }

            if (onSave) {

                // Show edit Estimation DateupdateUI
                //Commented out for B-4062, should be enabled later
                /**if (phase.hasEstDateError){
                    hasErrors = true;
                    phase.isEditEstComplDate = true;
                }*/

                // Phase is empty. Expand phase
                phase.dragItems.forEach(dragItem => {
                    dragItem.isUnassignedLocationsError = app.isLocationsEnabled
                        && dragItem.unassignedQuantity > 0;
                    if (dragItem.isUnassignedLocationsError) {
                        phase.isCollapsed = false;
                        dragItem.isDetailsShown = true;
                        hasErrors = true;

                    }
                });

                // Phase is empty. Expand phase
                if (phase.dragItems.length === 0) {
                    phase.isCollapsed = false;
                    phase.isEmptyError = true;
                    hasErrors = true;
                }

                if (phase.isExecutedSignoffValid === false) {
                    hasErrors = true;
                }
            }
        });

        return hasErrors
    },

    /**
     * Perform Save Request to Salesforce
     * 0) Check for errors
     * 1) Delete Phase Line Items
     *    PhaseManagementController.deletePhaseLineItems(phaseLineItemIdsToDelete)
     * 2) Delete Phases
     *    PhaseManagementController.deletePhases(phaseIdsToDelete)
     * 3) Upsert Phases
     *    PhaseManagementController.upsertPhases(phaseIdsToUpsert)
     * 4) Save Phase Line Items
     *    PhaseManagementController.upsertPhaseLineItems(phaseLineItemsToUpsert)
     * 5) Update Phase Status and Lock records for Deleted Cloned Phases
     *    PhaseManagementController.updatePhaseStatus(phasesToUpdateStatus)
     * And refreshes data
     */
    save: function (component) {
        var helper = this;
        var app = component.get('v.app');

        if (this.getErrors(component, true) || !app.hasUnsavedChanges) {
            component.set('v.app', app);
            return;
        }
        var unsavedChanges = app.unsavedChanges;

        var savePhasesProcess = Promise.resolve();

        // Delete Phase Line Items
        if (unsavedChanges.phaseLineItems.toDelete.length) {
            savePhasesProcess = savePhasesProcess.then($A.getCallback(function () {
                PM.spinner.show('Deleting Phase Line Items');
                return PM.salesforce.request(component, 'c.deletePhaseLineItems', {
                    phaseLineItemIdsToDelete: unsavedChanges.phaseLineItems.toDelete
                }, $A);
            }))
        }

        // Delete Phases
        if (unsavedChanges.phases.toDelete.length) {
            savePhasesProcess = savePhasesProcess.then($A.getCallback(function () {
                PM.spinner.show('Deleting Phases');
                return PM.salesforce.request(component, 'c.deletePhases', {
                    phaseIdsToDelete: unsavedChanges.phases.toDelete
                }, $A);
            }))
        }

        // Upsert Phases
        if (Object.keys(unsavedChanges.phases.toUpsert).length) {
            if (app.isNewChangeOrder) {
                Object.keys(unsavedChanges.phases.toUpsert).forEach(unsavedPhase => {
                    if (unsavedChanges.phases.toUpsert[unsavedPhase]) {
                        if (unsavedChanges.phases.toUpsert[unsavedPhase].newPhaseNumber) {
                            unsavedChanges.phases.toUpsert[unsavedPhase].Phase_Number__c = unsavedChanges.phases.toUpsert[unsavedPhase].newPhaseNumber;
                            delete unsavedChanges.phases.toUpsert[unsavedPhase].newPhaseNumber;
                        }
                    }
                });
            }
            savePhasesProcess = savePhasesProcess.then($A.getCallback(function () {
                PM.spinner.show('Saving Phases');
                return PM.salesforce.request(component, 'c.upsertPhases', {
                    phasesToUpsert: unsavedChanges.phases.toUpsert
                }, $A);
            }))
        }

        // Save Phase Line Items
        if (Object.keys(unsavedChanges.phaseLineItems.toUpsert).length) {
            savePhasesProcess = savePhasesProcess.then($A.getCallback(function (phases) {
                PM.spinner.show('Saving Phase Line Items');
                console.log(phases);
                var phaseLineItemsToUpsert = [];

                // Enrich Phase IDs
                for (var phaseGUID in unsavedChanges.phaseLineItems.toUpsert) {

                    unsavedChanges.phaseLineItems.toUpsert[phaseGUID] =
                        unsavedChanges.phaseLineItems.toUpsert[phaseGUID].map(function (pli) {
                            if (!pli.RingCentral_Hardware_Phase__c && phases && phases[phaseGUID])
                                pli.RingCentral_Hardware_Phase__c = phases[phaseGUID].Id;
                            phaseLineItemsToUpsert.push(pli);
                        });
                }

                return PM.salesforce.request(component, 'c.upsertPhaseLineItems', {
                    phaseLineItemsToUpsert: phaseLineItemsToUpsert
                }, $A);
            }));
        }

        // Update Phase Status and Lock records for Deleted Cloned Phases
        if (Object.keys(unsavedChanges.phases.toUpdateStatus).length) {
            savePhasesProcess = savePhasesProcess.then($A.getCallback(function () {
                PM.spinner.show('Updating Deleted Cloned Phases');
                return PM.salesforce.request(component, 'c.lockDeletedPhases', {
                    phasesToUpdate: unsavedChanges.phases.toUpdateStatus
                }, $A);
            }))
        }

        return savePhasesProcess
            .catch($A.getCallback(function (error) {
                console.error(error);
                $A.get("e.c:ToastEvent").setParams({
                    theme: 'error',
                    header: 'Failed to save Changes',
                    details: PM.salesforce.getResponseError(error),
                    defaultTimeout: false
                }).fire();
                PM.spinner.hide();
            }))
            .then($A.getCallback(function () {
                return helper.getPhases(component);
            }))
            .then($A.getCallback(function () {
                helper.refreshApp(component, component.get('v.phases'));
                PM.spinner.hide();

                var onChangesSaved = component.get('v.onChangesSaved');
                if (onChangesSaved) {
                    $A.enqueueAction(onChangesSaved);
                }
            }));
    },

    /**
     * Delete specified phase Line Items from Salesforce
     * @returns {Promise}
     */
    deletePhaseLineItems: function (component, phaseLineItemIdsToDelete) {
        console.log('deletePhaseLineItems', phaseLineItemIdsToDelete);

        PM.spinner.show('Deleting phase Line Items');
        var hasError = false;
        var helper = this;
        return PM.salesforce.request(component, 'c.deletePhaseLineItems', {
                phaseLineItemIdsToDelete: phaseLineItemIdsToDelete
            }, $A)
            .catch($A.getCallback(function (error) {
                console.error(error);
                hasError = true;
                $A.get("e.c:ToastEvent").setParams({
                    theme: 'error',
                    header: 'Failed to delete phase Line Items',
                    details: PM.salesforce.getResponseError(error),
                    defaultTimeout: false
                }).fire();
            }))
            .then($A.getCallback(function () {
                // Refresh data
                return helper.getPhases(component);
            }))
            .then($A.getCallback(function () {
                PM.spinner.hide();
                if (hasError) {
                    return Promise.reject();
                }
            }));

    },

    /**
     * Delete Specified Phases from Salesforce
     */
    deletePhases: function (component, phaseIdsToDelete) {
        if (phaseIdsToDelete.Id === 0) return;

        PM.spinner.show('Deleting Phases');
        var helper = this;
        var hasError = false;
        return PM.salesforce.request(component, 'c.deletePhases', {
            phaseIdsToDelete: phaseIdsToDelete
        }, $A)
            .then($A.getCallback(function (result) {
                console.log(result);

                // Refresh data
                return helper.getPhases(component);
            }))
            .catch($A.getCallback(function (error) {
                console.error(error);
                hasError = true;
                $A.get("e.c:ToastEvent").setParams({
                    theme: 'error',
                    header: 'Failed to delete Phases',
                    details: PM.salesforce.getResponseError(error),
                    defaultTimeout: false
                }).fire();
            }))
            .then($A.getCallback(function () {
                // Refresh data
                return helper.getPhases(component);
            }))
            .then($A.getCallback(function () {
                PM.spinner.hide();
                if (hasError) {
                    return Promise.reject();
                }
            }));
    },

    updateUI: function (component, app) {
        app = app || component.get('v.app');
        app.update();
        component.set('v.isPhasesChanged', app.hasUnsavedChanges);
        component.set('v.app', app);
    },

    visualiseStopDrag: function (component) {
        var data = component.get('v.app');

        data.phases.forEach(phase => {
            phase.readyToDrop = false;
        });
        data.readyToDrop = false;

        component.set('v.app', data);
    },

    openDefaultLocationForm: function(component){
        var app = component.get('v.app');
        $A.get("e.c:PhaseManagementEvent").setParams({
            action: 'openDefaultLocationForm',
            location: app.defaultLocation,
            app: app,
            target: component.find('editDefaultLocationButton').getElement()
        }).fire();
    },

    submitDefaultLocationForm: function(component) {
        var app = component.get('v.app');
        app.defaultLocation.isLoading = true;
        component.set('v.app', app);

        let process = Promise.resolve();

        // Validate Address
        if (!app.defaultLocation.isAddressValid)
            process = process.then($A.getCallback(() =>
                RC.salesforce.request(component, 'c.validateAdressesWrapper', {
                    addressItemList: JSON.stringify([app.defaultLocation.getAdressToValidate({isUserInput: true})])
                })))
            .catch($A.getCallback(error => RC.salesforce.displayError('Failed to validate address', error)))
            .then($A.getCallback(result => app.defaultLocation.setValidatedAddressesResult(result)));

        // Save on Quote
        process.then($A.getCallback(() =>
                RC.salesforce.request(component, 'c.updateQuote', {
                    updatedQuote: {
                        sobjectType: 'Quote',
                        Id: component.get('v.quote.Id'),
                        Address_Line__c: app.defaultLocation.adressLine,
                        City__c: app.defaultLocation.city,
                        State__c: app.defaultLocation.state,
                        Postal_Code__c: app.defaultLocation.postalCode,
                        Country__c: app.defaultLocation.country,
                        Address_Validated__c: app.defaultLocation.isAddressValid
                    }
                })
            ))
            .catch($A.getCallback(error => RC.salesforce.displayError('Failed to save default Location', error)))
            .then($A.getCallback(() => {
                app.defaultLocation.isLoading = false;
                component.set('v.app', app);
                $A.get("e.c:QuotingToolRefreshQuoteEvent").fire();
            }));
    },

    validateAddresses: function (component) {
        var helper = this;
        var app = component.get('v.app');

        var adresses = app.getAdressesToValidate();
        app.setValidationInProgress(app.getSequenceIdSet(adresses));
        component.set('v.app', app);

        RC.salesforce.request(component, 'c.validateAdressesWrapper', {
                addressItemList: JSON.stringify(adresses)
            })
            .then($A.getCallback(result => {
                app.setValidatedAddressesResult(result);
            }))
            .catch($A.getCallback(error => RC.salesforce.displayError('Failed to validate addresses', error)))
            .then($A.getCallback(() => {
                app.setValidationInProgress();
                helper.updateUI(component);
            }))
    },

    loadUserAccessInfo: function(component){
        return RC.salesforce.request(component, 'c.getUserAccessInfo')
            .then($A.getCallback(userAccessInfo => {
                component.set('v.userAccessInfo', userAccessInfo);
            }));
    },

    getPhaseTypesPicklistValues: function(component) {
        PM.salesforce.request(component, 'c.getPicklistValues', {
            sObjectApiName: PM.CONSTANTS.PHASE.API_NAME,
            fieldApiName: PM.CONSTANTS.PHASE.PHASE_TYPE.API_NAME
        })
        .catch($A.getCallback(error => {
            RC.salesforce.displayError(
                'Failed to get ' + PM.CONSTANTS.PHASE.PHASE_TYPE.API_NAME + ' picklist values',
                error
            )
        }))
        .then($A.getCallback(res => {
            let types = [{value: '', label: '-None-'}];
            res.forEach(item => {
                types.push({value: item, label: item});
            });
            component.set('v.phaseTypes', types);
        }));
    }
});