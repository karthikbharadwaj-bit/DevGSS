({
    updateUI: function(component, app){
        // Update UI
        app = app || component.get('v.app');
        app.update();
        component.set('v.isPhasesChanged', app.hasUnsavedChanges);
        component.set('v.app', app);
    },

    /**
     * Removes highlight from drop containers
     */
    visualiseStopDrag: function(component){
        var data = component.get('v.app');

        data.phases.map(function(phase){
            phase.readyToDrop = false;
            return phase;
        });
        data.readyToDrop = false;

        component.set('v.app', data);
    },

    /**
     * Move all items from unassigned to phase
     */
    moveUnassignedToPhase: function(component){
        var app = component.get('v.app');

        app.deselectAll();
        app.dragItems.forEach(dragItem => {
            dragItem.select(true);
        });
        app.moveItems(app.getSelectedItemsInfo(), component.get('v.phase.guid'));

        component.set('v.app', app);
    },

    /**
     * Delete phase from UI and salesforce
     */
    deletePhase: function(component, phaseGUID){
        var app = component.get('v.app');
        var phase = app.getPhase(phaseGUID);
        // Move all items to unassigned
        phase.dragItems.forEach(function(dragItem){
            dragItem.quantity = dragItem.quantityMax;
            phase.move(dragItem).to(app);
        });

        var sowExistingSn = [];
        app.phases.forEach(function(phase){
            sowExistingSn.push(phase.phaseNumber);
        }, this);

        sowExistingSn.sort(function(a,b){
            return a - b;
        });

        if (phase.sfid) {
            app.markPhaseAsDeleted(phase.guid);

        } else {
            app.deletePhase(phase.guid);
        }

        component.set('v.app', app);
    },

    /**
     * Perform Complete phase request to Salesforce
     * PhaseManagementController.completePhase(phaseId)
     */
    completePhase: function(component, completeOption, completionDate){
        var app = component.get('v.app');
        var phase = component.get('v.phase');
        var completionDate = component.get('v.completionDate');

        if (!phase.sfid) return;

        phase.isCompleteInProgress = true;
        component.set('v.app', app);

        var helper = this;
        PM.salesforce.request(component, 'c.completePhase', {
                phaseId: phase.sfid,
                completeOption: completeOption,
                completionDate: completionDate
            })
            .catch($A.getCallback(error => RC.salesforce.displayError('Failed to complete phase', error)))
            .then($A.getCallback(() => helper.getPhases(component)))
            .then($A.getCallback(() => helper.refreshApp(component, component.get('v.phases'))));
    },

    editPhaseEstCompDate: function(component, phaseGUID){
        var app = component.get('v.app');
        var phase = app.getPhase(phaseGUID);
        phase.isEditEstComplDate = !phase.isEditEstComplDate;

        component.set('v.app', app);
    },

    refreshApp: function (component, phases) {
        var app = component.get('v.app');

        app.init({phaseSObjects: phases});

        this.updateUI(component, app);
    },

    getErrors: function(component, onSave){
        var app = component.get('v.app');

        var hasErrors = false;
        app.phases.forEach(function(phase){
            // bypass checks on completed and deleted phases
            if (phase.isComplete || phase.isDeleted || (phase.isAtDeleteStatus && app.isNewChangeOrder))
                return;

            // Estimated date is empty
            //Commented out for B-4062, should be enabled later
            //phase.hasEstDateError = !phase.estimatedCompletionDate && onSave;
            phase.isEmptyError = false;

            // Estimated date is in the past
            if (phase.estimatedCompletionDate) {
                var now = new Date();
                now.setHours(0,0,0,0);

                var estDate = new Date(phase.estimatedCompletionDate);
                estDate.setHours(0,0,0,0);

                phase.hasEstDateError = now > estDate;
            }

            if (onSave){

                // Show edit Estimation Date
                //Commented out for B-4062, should be enabled later
                /**if (phase.hasEstDateError){
                    hasErrors = true;
                    phase.isEditEstComplDate = true;
                }*/

                // Phase is empty. Expand phase
                if (phase.dragItems.length === 0){
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
     * Init phase management data.
     * Loads Phases from salesforce and loads them to app
     * Depending on where app is open (Quoting Wizard or Order layout) Quote Id or Order Id are accessible.
     */
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

    getItemsByInfo: function(component, itemsInfo){
        var items = [];
        var app = component.get('v.app');

        itemsInfo.forEach(function(itemInfo){
            var source = itemInfo.phaseGUID ? app.getPhase(itemInfo.phaseGUID) : app;
            items.push(source.getDragItem(itemInfo.prod_sfid));
        });

        return items;
    },

    isItemsValid: function(items){
        var valid = true;
        items.forEach(function(item){
            if ((1 > item.quantity) || (item.quantity > item.quantityMax))
                valid = false;
        });
        return valid;
    },

    validateBeforeDelete: function(component){
        var isProductsDeletedOnOrder = !component.get('v.order') || component.get('v.phase.dragItems.length') === 0;
        RC.cssUtils.toggleShow(component, 'deleteProductsMessage', !isProductsDeletedOnOrder);

        if (!isProductsDeletedOnOrder){
            var phase = component.get('v.phase');
            phase.isCollapsed = false;
            component.set('v.phase', phase);
        }

        return isProductsDeletedOnOrder;
    },

    validateAddresses: function(component){
        var helper = this;
        var phase = component.get('v.phase');
        var app = component.get('v.app');

        var adresses = phase.getAdressesToValidate();
        phase.setValidationInProgress(app.getSequenceIdSet(adresses));
        component.set('v.phase', phase);

        RC.salesforce.request(component, 'c.validateAdressesWrapper', {
                addressItemList: JSON.stringify(adresses)
            })
            .then($A.getCallback(result => {
                phase.setValidatedAddressesResult(result);
            }))
            .catch($A.getCallback(error => RC.salesforce.displayError('Failed to validate addresses', error)))
            .then($A.getCallback(() => {
                phase.setValidationInProgress();
                component.set('v.phase', phase);
                helper.updateUI(component);
            }));
    },

    setApprovalAction: function(component, action){
        var helper = this;
        var phase = component.get('v.phase');
        phase.isCompleteInProgress = true;
        component.set('v.phase', phase);

        RC.salesforce.request(component, 'c.setApprovalAction', {
                phaseId: phase.record.Id,
                action: action,
                comment: component.find('approvalActionComment').get('v.value')
            })
            .catch($A.getCallback(error => RC.salesforce.displayError(`Failed to ${action} Phase`, error)))
            .then($A.getCallback(() => helper.getPhases(component)))
            .then($A.getCallback(() => helper.refreshApp(component, component.get('v.phases'))));
    },

    setApprovalPermissions: function(component) {
        var userAccessInfo = component.get('v.userAccessInfo');
        var phaseRecord = component.get('v.phase.record');
        var userId = $A.get("$SObjectType.CurrentUser.Id");
        var isUserOwnsPhase = phaseRecord &&
            [
                RC.stringHelper.getShortId(phaseRecord.OwnerId),
                RC.stringHelper.getShortId(phaseRecord.CreatedById),
                RC.stringHelper.getShortId(phaseRecord.LastModifiedById)
            ].includes(RC.stringHelper.getShortId(userId));

        component.set('v.isUserCanRecall', userAccessInfo.isSystemAdmin
                                        || isUserOwnsPhase);
        component.set('v.isUserCanApproveReject', userAccessInfo.isSystemAdmin
                                               || userAccessInfo.isUserInApprovalQueue);
    },

    validateCompletionDate:function(component) {
        var isValid = true;
        var helper = this;
        var completionDateWrapper = component.find("completionDateWrapper");
        var helperMessage = component.find("helperMessage");
        var completionDate = component.get("v.completionDate");
        var completionOption = component.find('completionOption').get('v.value');
        var bonusDays = component.get('v.rcVariousSettings').Automated_Phase_Completion_Days_Limit__c;
        var today = component.get('v.app.today');

        var min = PM.moment(today,"YYYY-MM-DD").add(-bonusDays, 'days').format('YYYY-MM-DD');
        var max = PM.moment(today,"YYYY-MM-DD").format('YYYY-MM-DD');

        if( !completionOption
            || completionOption === 'Manual' && (!completionDate || completionDate > max)
            || completionOption === 'Automated' && (!completionDate || completionDate < min || completionDate > max)
            ) {

            component.set('v.isNotValidCompletionDate', true);
            $A.util.addClass(completionDateWrapper, "slds-has-error");
            $A.util.addClass(helperMessage, "slds-text-color_error");
            $A.util.addClass(component.find('completionOption'), "slds-has-error");
            $A.util.addClass(component.find('completionDateInput'), "slds-has-error");
            isValid = false;

        } else {
            helper.clearErrors(component);
        }

        return isValid;
    },

    clearErrors: function(component) {
        var completionDateWrapper = component.find('completionDateWrapper');
        var completionOptionSelector = component.find('completionOption');
        var helperMessage = component.find('helperMessage');

        $A.util.removeClass(completionDateWrapper, "slds-has-error");
        $A.util.removeClass(helperMessage, "slds-text-color_error");
        $A.util.removeClass(completionOptionSelector, "slds-has-error");

        component.set('v.isNotValidCompletionDate', false);
        component.set('v.refreshInput', false);
        component.set('v.refreshInput', true);
    },

    restrictChangeCompletionDateOutOfRange:function(component) {
        var bonusDays = component.get('v.rcVariousSettings').Automated_Phase_Completion_Days_Limit__c;
        var completionOption = component.find('completionOption').get('v.value');
        if(completionOption === 'Automated' && !bonusDays) {
            component.set('v.isRestrictedChangeCompletionDate', true);
        } else {
            component.set('v.isRestrictedChangeCompletionDate', false);
        }
    },

    readCsvPromise: function(inputFile) {
        const temporaryFileReader = new FileReader();

        return new Promise((resolve, reject) => {
            temporaryFileReader.onerror = () => {
                temporaryFileReader.abort();
                reject(new DOMException('Problem parsing input file.'));
            };

            temporaryFileReader.onload = () => {
                const res = this.replaceSpacesInCsvHeaders(temporaryFileReader.result);
                resolve(res);
            };
            temporaryFileReader.readAsText(inputFile);
        });
    },

    replaceSpacesInCsvHeaders: function(fileRes) {
        let tempArr = fileRes.split(/\r\n|\n/);
        tempArr[0] = RC.stringHelper.removeSpacesFromString(tempArr[0]);
        return tempArr.join('\n');
    },

    validateCsvStructure: function(component) {
        const missingColumns = new Array();
        let errors = '';
        const locationsJson = component.get('v.locationsJsonList');
        const requiredVals = new Set([
            'LocationName',
            'StreetAddress',
            'City',
            'State',
            'Country',
            'PostalCode',
            'Quantity',
            'ProductName'
        ]);

        const allCsvColumns = [...requiredVals, 'CostCode', 'Site'];

        locationsJson
        && locationsJson[0]
        && Object.keys(locationsJson[0])
        && allCsvColumns.forEach(v => {
            if (!Object.keys(locationsJson[0]).includes(v)) {
                missingColumns.push(RC.stringHelper.addSpacesBetweenCapitalizedWords(v));
            }
        })

        if (missingColumns.length > 0) {
            errors = 'Required columns missing: ' + missingColumns.join(', ');
            this.clearLocationsFileInput(component);
        }

        return errors;
    },

    validateLocations: function(component) {
        let isValid = true;
        const locationsJson = component.get('v.locationsJsonList');
        const requiredVals = new Set([
            'LocationName',
            'StreetAddress',
            'City',
            'State',
            'Country',
            'PostalCode',
            'Quantity',
            'ProductName'
        ]);

        // Prod Name to quantities list. [0] is PLI max qty, [1] is Locations total qty from CSV for Prod.
        const prodNameToQtyMap = this.getPhaseLineItemsQuanitiesMap(component);
        const uniqueValSet = new Set();
        const prodNamesFromCsv = new Set();
        const phase = component.get('v.phase');

        locationsJson.forEach(el => {
            el['Status'] = '';

            const addressConcat = ''.concat(
                el.ProductName,
                el.StreetAddress,
                el.City,
                el.State,
                el.Country,
                el.PostalCode
            ).toLowerCase();

            // Find duplicates
            if (uniqueValSet.has(addressConcat)) {
                el['Status'] += 'Duplicate entry.\n';
                isValid = false;
            } else {
                uniqueValSet.add(addressConcat);
            }

            // Check required fields
            const reqValsMissing = [];
            requiredVals.forEach(reqVal => {
                if (!el[reqVal]) {
                    reqValsMissing.push(RC.stringHelper.addSpacesBetweenCapitalizedWords(reqVal));
                }
            });

            if (reqValsMissing.length > 0) {
                el['Status'] += 'Missing: ' + reqValsMissing.join(', ') + '\n';
                isValid = false;
            }

            // Populate prod name to quantity map using values from CSV
            prodNameToQtyMap.has(el['ProductName'])
                ? prodNameToQtyMap.get(el['ProductName'])[1] += Number(el['Quantity'])
                : prodNameToQtyMap.set(el['ProductName'], [0, Number(el['Quantity'])]);

            // Validate prod qty is > 0
            if (el['Quantity'] <= 0 || !isFinite(el['Quantity']) || isFinite(el['Quantity']) && el['Quantity'] % 1 !== 0) {
                isValid = false;
                el['Status'] += 'Site quantity should be positive integer\n';
            }

            // Validate Location ID format
            if (!!el['Site'] && !/^[A-Za-z0-9\s]*$/.test(el['Site'])) {
                isValid = false;
                el['Status'] += 'Site (Location ID) must contain only digits and letters\n';
            }

            // Validate Postal Codes
            if (!/^([0-9A-Za-z -].*)$/.test(el['PostalCode'])) {
                isValid = false;
                el['Status'] += 'Invalid postal code format\n';
            }

            prodNamesFromCsv.add(el['ProductName']);
        });

        phase.prodNamesFromCsv = prodNamesFromCsv;
        component.set('v.phase', phase);

        const uniqueLocationIdNamePairs = this.prepopulateLocationIdNamePairs(component.get('v.phases'), phase);

        locationsJson.forEach(el => {
            // Validate quantities and add errors.
            if (el['ProductName'] && prodNameToQtyMap.get(el['ProductName'])[0] === 0) {
                el['Status'] += el['ProductName'] + ' is not found on the phase \n';
                isValid = false;
            } else if((prodNameToQtyMap.get(el['ProductName'])[0] - prodNameToQtyMap.get(el['ProductName'])[1]) < 0) {
                isValid = false;
                el['Status'] += 'Product max quantity exceeded\n';
            } else if((prodNameToQtyMap.get(el['ProductName'])[0] - prodNameToQtyMap.get(el['ProductName'])[1]) > 0) {
                isValid = false;
                el['Status'] += 'Total product quantity should match PLI quantity\n';
            }

            // Find duplicate combination of Location Id and Location Name
            if (
                (!!el['Site'] || !!el['LocationName'])
                && uniqueLocationIdNamePairs.has(
                    PM.stringHelper.nullSafeString(el['Site'])
                    + PM.stringHelper.nullSafeString(el['LocationName'])
                )
            ) {
                el['Status'] += 'Such combination of Site (Location Id) and Location Name already exists on current Order.\n';
                isValid = false;
            } else {
                uniqueLocationIdNamePairs.add(
                    PM.stringHelper.nullSafeString(el['Site'])
                    + PM.stringHelper.nullSafeString(el['LocationName'])
                );
            }
        });

        phase.locationsJsonListValidated = locationsJson;
        phase.isLocationsJsonHasErrors = !isValid;

        component.set('v.phase', phase);
        return isValid;
    },

    validateCsvSitesAddresses: function(component) {
        const addresses = new Array();
        const phase = component.get('v.phase');
        const locations = component.get('v.phase.locationsJsonListValidated');

        locations.forEach(l => {
            l['seqId'] = PM.uuidv4();
            addresses.push({
                'itemToValidate': {
                    'seqId': l['seqId'],
                    'addressLine1': l['StreetAddress'],
                    'city': l['City'],
                    'state': l['State'],
                    'zip': l['PostalCode'],
                    'country': l['Country']
                },
                'pliId': null
            });
        });

        RC.salesforce.request(component, 'c.validateAdressesWrapper', {
            addressItemList: JSON.stringify(addresses)
        })
        .then($A.getCallback(result => {
            locations.forEach(l => {
                l['isLocationValid'] = result[l['seqId']].isResponseValid;
                if (!l['isLocationValid']) {
                    phase.isLocationsJsonHasErrors = true;
                }
                l['Status'] = l['isLocationValid'] ? 'OK' : 'Avalara validation failed!';
            });
            component.set('v.phase.locationsJsonListValidated', locations);
        }))
        .catch($A.getCallback(error => RC.salesforce.displayError('Failed to validate addresses', error)));

        if (phase.isLocationsJsonHasErrors) {
            component.set('v.phase', phase);
        }
    },

    /**
     * Gets "Location ID" + "Location Name" for all Phase Line Items existing on all order phases.
     * The products from current phase that are listed in CSV aren't taken into account as far as they will be replaced
     * with new records from the file.
     */
    prepopulateLocationIdNamePairs: function(allPhases, currPhase) {
        const res = new Set();

        allPhases.forEach(
            p => {
                p.Hardware_Line_Items__r
                && p.Hardware_Line_Items__r.forEach(
                    hli => (!!hli.Location_ID__c || !!hli.Location_Name__c)
                            && !(
                                p.Id == currPhase.record.Id
                                && currPhase.prodNamesFromCsv.has(hli.Quote_Line_Item__r.Product2.Name)
                            )
                            && res.add(
                                PM.stringHelper.nullSafeString(hli.Location_ID__c)
                                + PM.stringHelper.nullSafeString(hli.Location_Name__c)
                            )
                )
            }
        );

        return res;
    },

    getPhaseLineItemsQuanitiesMap: function(component) {
        const res = new Map();
        const items = component.get('v.phase.dragItems');

        items.forEach(i => {
            res.set(i.name, [i.quantityMax, 0]);
        });

        return res;
    },

    renderLocationsTable: function(component) {
        const colNames = [
            'Location Name',
            'Site',
            'Cost Code',
            'Street Address',
            'City',
            'State',
            'Postal Code',
            'Country',
            'Product Name',
            'Quantity',
            'Status'
        ];

        const phase = component.get('v.phase');
        const cols = new Array();

        colNames.forEach(cn => {
            cols.push({
                label: cn,
                fieldName: RC.stringHelper.removeSpacesFromString(cn),
                type: 'text',
                cellAttributes:{
                    class: {fieldName: (RC.stringHelper.removeSpacesFromString(cn) + 'CSSClass')},
                    alignment: 'left'
                }
            })
        });

        phase.locationsJsonListValidated.forEach(val => {
            if(!val['Status']) {
                val['Status'] = 'OK';
                val['StatusCSSClass'] = 'status-ok';
            } else {
                val['StatusCSSClass'] = 'status-error';
            }
        });

        component.set('v.locationsCsvTableColumns', cols);

        this.hideLocationsUploadModal(component);
        this.showLocationsTableModal(component);
    },

    clearLocationsFileInput: function(component) {
        const locationsCsvInput = component.find('locationsCsvInput').getElement();
        locationsCsvInput.value = '';
        if(locationsCsvInput.value){
            // these assignments are needed for some browsers
            locationsCsvInput.type = 'text';
            locationsCsvInput.type = 'file';
        }
    },

    showLocationsUploadModal: function(component) {
        component.find('uploadLocationsCsvModal').set('v.Modal', new RC.modalHelper.Modal({
            header: 'Sites upload'
        }));
        component.find('uploadLocationsCsvModal').show();
    },

    hideLocationsUploadModal: function(component) {
        component.find('uploadLocationsCsvModal').hide();
    },


    showLocationsTableModal: function(component) {
        const phase = component.get('v.phase');
        component.find('locationsTableModal').set('v.Modal', new RC.modalHelper.Modal({
            header: 'Sites upload',
            layout: 'large',
            buttons: [
                {
                    label: 'Discard',
                    variant: 'destructive',
                    callback: () => {
                        this.hideLocationsTableModal(component);
                        this.showLocationsUploadModal(component);

                        component.set('v.locationsJsonList', null);
                        component.set('v.phase.locationsJsonListValidated', null);

                        // unselect file
                        this.clearLocationsFileInput(component);
                    },
                    closeOnClick: false
                },
                {
                    label: 'Upload sites',
                    variant: 'brand',
                    callback: () => {
                        // TODO SITES UPLOAD TO DB
                        if (phase.locationsJsonListValidated) {
                            if (phase.isLocationsJsonHasErrors) {
                                $A.get('e.c:ToastEvent').setParams({
                                    theme: 'error',
                                    header: 'Sites upload refused',
                                    details: 'Please review all validation errors before uploading sites'
                                }).fire();
                            } else {
                                PM.spinner.show('Uploading sites');
                                this.uploadSites(component);
                            }
                        }
                    },
                    closeOnClick: false
                }
            ]
        }));
        component.find('locationsTableModal').show();
    },

    hideLocationsTableModal: function(component) {
        component.find('locationsTableModal').hide();
    },

    uploadSites: function(component) {
        const sitesSFIDsToDelete = this.getSitesSFIDsToDelete(component);
        const sitesJsonToUpsert = this.getSitesJsonToUpsert(component);

        let uploadSitesProcess = Promise.resolve();

        uploadSitesProcess.then($A.getCallback(() => {
            return PM.salesforce.request(component, 'c.processLocationsFromCSV', {
                phaseLineItemIdsToDelete: sitesSFIDsToDelete,
                phaseLineItemsToUpsert: sitesJsonToUpsert
            });
        }))
        .then($A.getCallback(() => {
            this.reloadPhaseManagement(component);
        }))
        .then($A.getCallback(() => {
            $A.get("e.c:ToastEvent").setParams({
                theme: 'success',
                header: 'Sites uploaded successfully',
                defaultTimeout: true
            }).fire();
        }))
        .catch($A.getCallback(e => {
            PM.salesforce.displayError('Sites upload failed', e);
        }))
        .finally($A.getCallback(() => {
            PM.spinner.hide();
        }))
    },

    reloadPhaseManagement: function(component) {
        Promise.resolve()
        .then($A.getCallback(() => {
            return component.get('v.parent').reloadPhases();
        }))
        .then($A.getCallback(() => {
            component.get('v.parent').discard();
        }));
    },

    getSitesSFIDsToDelete: function(component) {
        const res = new Set();
        const currPhase = component.get('v.phase');
        // 'v.phases' list contains initial values from DB, when 'v.phase' is phase's current UI state
        const initialPhase = this.findCurrentPhaseFromPhaseList(component.get('v.phases'), currPhase);
        if (!initialPhase || initialPhase.length == 0) {
            return res;
        }
        const prodNameToQliMap = new Map();

        initialPhase.Hardware_Line_Items__r && initialPhase.Hardware_Line_Items__r.forEach(hli => {
            const prodName = hli.Quote_Line_Item__r && hli.Quote_Line_Item__r.Product2.Name;
            // PLIs for products that are not in uploaded CSV should not be deleted
            if(currPhase.prodNamesFromCsv.has(prodName)) {
                prodNameToQliMap.set(prodName, hli.Quote_Line_Item__r);
                res.add(hli.Id)
            }
        });

        component.set('v.phase.prodNameToQliMap', prodNameToQliMap);
        return res;
    },

    findCurrentPhaseFromPhaseList: function(phases, currPhase) {
        return phases.filter(ip => ip.Id == currPhase.record.Id)[0];
    },

    getSitesJsonToUpsert: function(component) {
        const res = new Array();
        const phase = component.get('v.phase');

        component.get('v.phase.locationsJsonListValidated').forEach(l => {
            res.push({
                'sobjectType': 'Hardware_Line_Item__c',
                'Id': null,
                'Quantity__c': l['Quantity'],
                'Location_ID__c': l['Site'],
                'Location_Name__c': l['LocationName'],
                'Country__c':l['Country'],
                'City__c': l['City'],
                'Postal_Code__c': l['PostalCode'],
                'State__c': l['State'],
                'Address_Line__c': l['StreetAddress'],
                'Address_Validated__c': true,
                'Quote_Line_Item__c': phase.prodNameToQliMap.get(l['ProductName']).Id,
                'RingCentral_Hardware_Phase__c': phase.sfid,
                'Name': l['ProductName'],
                'Cost_Code__c': l['CostCode'],
                'Order__c': component.get('v.order.Id'),
                'Order_Line_Item__c': this.getOrderItemIdByProductId(
                    component,
                    phase.prodNameToQliMap.get(l['ProductName']).Product2Id
                )
            });
        });

        return res;
    },

    getOrderItemIdByProductId: function(component, productId) {
        const oiFound = component.get('v.order.OrderItems').find(oi => oi.Product2Id === productId);
        let res = null;
        if (oiFound) {
            res = oiFound.Id
        }
        return res;
    }
});