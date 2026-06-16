({

    doInit: function(component, event, helper){
        helper.setApprovalPermissions(component);
    },

    onDragEnter: function(component, event){
        event.preventDefault();
    },

    /**
     * User drag over phase
     */
    onDragOver: function(component, event){
        event.preventDefault();
    },

    /**
     * User Drop into drag items container (Phase or Unassigned block)
     */
    onDropInto: function(component, event, helper){
        event.preventDefault();

        // return if user tries to drop something inappropriate
        try {
            var itemsInfo = JSON.parse(event.dataTransfer.getData("text"));
        } catch (error){
            console.error(error);
            return;
        }

        // Move item
        var app = component.get('v.app');
        itemsInfo.isNewChangeOrderFlow = app.isMoveProductsAllowed;

        app.moveItems(itemsInfo, component.get('v.phase.guid'));

        // Update UI
        helper.updateUI(component, app);

        // Remove drag styling
        helper.visualiseStopDrag(component);
    },

    moveSelectedToPhase: function(component, event, helper){
        var phaseGUID = event.currentTarget.dataset.guid;

        var items = helper.getItemsByInfo(component, component.get('v.app').selectedItemsInfo);
        if (!helper.isItemsValid(items)) {
            component.set('v.preventDeselection', true);
            return;
        }

        var app = component.get('v.app');
        app.moveItems(app.selectedItemsInfo, phaseGUID);

        // Update UI
        helper.updateUI(component, app);
    },
    /**
     * Move all items from unassigned to phase
     */
    moveUnassignedToPhase: function(component, event, helper){
        helper.moveUnassignedToPhase(component);

        // Update UI
        helper.updateUI(component);
    },
    /**
     * User clicked collapse button on phase
     */
    phaseCollapse: function(component, event){
        var phaseGUID = event.currentTarget.dataset.guid;

        var app = component.get('v.app');
        var phase = app.getPhase(phaseGUID);

        if (phase.isDeleted) return;

        phase.isCollapsed = !phase.isCollapsed ;

        component.set('v.app', app);
    },
    /**
     * User clicked delete phase button
     */
    onDeletePhaseClick: function(component, event, helper){
        var phaseGUID = event.currentTarget.dataset.guid;
        var app = component.get('v.app');
        app.deselectAll();
        component.set('v.app', app);

        if (!helper.validateBeforeDelete(component))
            return;

        helper.deletePhase(component, phaseGUID);

        helper.updateUI(component);
    },

    /**
     * User clicked Upload Locations CSV button
     */
    onUploadLocationsCsvClick: function(component, event, helper){
        component.set('v.modalGuid', PM.uuidv4());
        const phase = component.get('v.phase');
        if (phase.locationsJsonListValidated) {
            helper.showLocationsTableModal(component);
        } else {
            helper.showLocationsUploadModal(component);
        }
    },

    onLocationsUploadFinished: function(component, event, helper) {
        const fileInput = component.find('locationsCsvInput').getElement();
        const file = fileInput && fileInput.files && fileInput.files[0];

        if (file) {
            component.set('v.locationsJsonList', null);
            PM.spinner.show('Processing CSV');

            try{
                helper.readCsvPromise(file)
                .then(res => {
                    PM.csvtojson({ trim:true })
                        .fromString(res)
                        .then($A.getCallback(jsonObj => {
                            component.set('v.locationsJsonList', jsonObj);
                            return jsonObj;
                        }));
                })
            } catch (e) {
                $A.get('e.c:ToastEvent').setParams({
                    theme: 'error',
                    header: 'CSV parser failed',
                    details: e.message
                }).fire();
            }
        }
    },

    onLocationsJsonChanged: function(component, event, helper) {
        if (component.get('v.locationsJsonList')) {
            const locationsCsvProcess = new Promise((resolve, reject) => {
                const validationError = helper.validateCsvStructure(component);
                if (validationError !== '') {
                    reject({
                        header: 'Wrong CSV format',
                        message: validationError
                    });
                } else {
                    resolve();
                }
            });

            locationsCsvProcess.then($A.getCallback((() => {
                return helper.validateLocations(component);
            })))
            .then($A.getCallback(locationsValid => {
                if (locationsValid) {
                    helper.validateCsvSitesAddresses(component);
                }
                return;
            }))
            .then($A.getCallback(() => {
                if (component.get('v.phase.locationsJsonListValidated')) {
                    helper.renderLocationsTable(component);
                }
            }))
            .catch($A.getCallback(e => {
                $A.get('e.c:ToastEvent').setParams({
                    theme: 'error',
                    header: e.header,
                    details: e.message,
                }).fire();
            }))
            .finally($A.getCallback(() => {
                PM.spinner.hide();
            }));
        }
    },

    /**
     * User clicked complete phase button
     */
    onCompletePhaseClick: function(component, event, helper){
        component.set('v.modalGuid', PM.uuidv4());
        var app = component.get('v.app');
        var phase = app.getPhase(component.get('v.phase.guid'));
        var isValidOnComplete = phase.validateOnComplete();
        app.update();
        component.set('v.app', app);
        if (!isValidOnComplete)
            return;
        component.find('completeModal').set('v.Modal', new RC.modalHelper.Modal({
            header: 'Do you want to complete Phase?',
                content: 'After that Phase and all its Phase Line Items will be locked for editing.',
                buttons: [{
                    label: 'Complete and lock phase',
                    variant: 'brand',
                    callback: () => {
                        var allValid = helper.validateCompletionDate(component);

                        if(allValid) {
                            helper.completePhase(component, component.get('v.completionOption'));
                            component.find('completeModal').hide();
                        }
                    },
                    closeOnClick: false
                }]
        }));
        component.find('completeModal').show();
    },

    editPhaseEstCompDate: function(component, event, helper){
        var phaseGUID = event.getSource().get('v.value');
        helper.editPhaseEstCompDate(component, phaseGUID);

    },
    onEstimatedCompletionDateChange: function(component, event, helper){
        helper.updateUI(component);
        helper.getErrors(component);
    },
    onPhaseDescriptionChange: function(component, event, helper){
        let timer = component.get('v.timer');
        clearTimeout(timer);

        timer = setTimeout(function() {
            helper.updateUI(component);
            clearTimeout(timer);
            component.set('v.timer', null);
        }, 800);

        component.set('v.timer', timer);
    },

    mouseOverCompleteButton: function(component, event){
        var app = component.get('v.app');
        var phase = app.getPhase(component.get('v.phase.guid'));

        var messages = [];

        var headerText = 'You can\'t complete this Phase';

        if(component.get('v.isPhasesChanged'))
            messages.push({
                header: headerText,
                text: 'Please save your changes first',
                iconTheme: 'info'
            });

        if(!phase.isAllLocationAdressesValid) {
            messages.push({
                header: headerText,
                text: `This Phase contains Phase Line Items with invalid and/or not validated addresses.
                    Please validate all Phase Line Items Addresses before trying to complete this Phase.`,
                iconTheme: 'info'
            });
        }

        if(!phase.record.Executed_Signoff_Link__c) {
            messages.push({
                header: headerText,
                text: `Executed Signoff Link should be populated to complete this phase.`,
                iconTheme: 'info'
            });
        }

        if(!phase.record.Phase_Type__c) {
            messages.push({
                header: headerText,
                text: `Phase Type should be populated to complete this phase.`,
                iconTheme: 'info'
            });
        }

        if (messages.length > 0) {
            var severity = ['info'];
            RC.popover.show(severity, event.currentTarget, messages);
        }
    },

    mouseOverLockedButton: function(component, event){
        var app = component.get('v.app');
        var phase = app.getPhase(component.get('v.phase.guid'));

        var messages = [];

        var headerText = 'This order is Locked';

        var creatorName = component.get('v.phase.record.Order__r.Opportunity.CreatedBy.Name');

        var textLocked = 'This order is locked due a pending change order created by ' + creatorName + '.';

        messages.push({
            header: headerText,
            text: textLocked,
            iconTheme: 'info'
        });

        if (messages.length > 0) {
            var severity = ['info'];
            RC.popover.show(severity, event.currentTarget, messages);
        }
    },

    mouseOutCompleteButton: function(){
        $A.get('e.c:PopoverEvent').setParams({
            show: false,
        }).fire();
    },

    onValidateLocation: function(component, event, helper){
        helper.validateAddresses(component);
    },

    onRecallClick: function (component, event, helper) {
        component.find('approvalActionComment').set('v.value', '');
        component.find('approvalActionModal').set('v.Modal', new RC.modalHelper.Modal({
            header: 'Do you want to recall phase completion approval?',
            buttons: [{
                label: 'Recall',
                variant: 'brand',
                callback: () => helper.setApprovalAction(component, 'Removed')
            }]
        }));
        component.find('approvalActionModal').show()
            .then($A.getCallback(() => component.find('approvalActionComment').focus()));
    },

    onApproveClick: function (component, event, helper) {
        component.find('approvalActionComment').set('v.value', '');
        component.find('approvalActionModal').set('v.Modal', new RC.modalHelper.Modal({
            header: 'Do you want to approve phase completion approval?',
            buttons: [{
                label: 'Approve',
                variant: 'success',
                callback: () => helper.setApprovalAction(component, 'Approve')
            }]
        }));
        component.find('approvalActionModal').show()
            .then($A.getCallback(() => component.find('approvalActionComment').focus()));
    },

    onRejectClick: function (component, event, helper) {
        component.find('approvalActionComment').set('v.value', '');
        component.find('approvalActionModal').set('v.Modal', new RC.modalHelper.Modal({
            header: 'Do you want to reject phase completion approval?',
            buttons: [{
                label: 'Reject',
                variant: 'destructive',
                callback: () => helper.setApprovalAction(component, 'Reject')
            }]
        }));
        component.find('approvalActionModal').show()
            .then($A.getCallback(() => component.find('approvalActionComment').focus()));
    },

    onChangeCompletionOption:function (component, event, helper) {
        helper.clearErrors(component);
        var completionOption = component.find('completionOption').get('v.value');
        if(completionOption === 'Manual'){
            component.set('v.completionDate', null);
            component.set('v.completionOptionLabel', 'Manual Completion Date');
        } else {
            component.set('v.completionOptionLabel', 'Automated Completion Date');
            component.set('v.completionDate', component.get('v.app.today'));
        }
        helper.restrictChangeCompletionDateOutOfRange(component);
    },

    onUserChangeCompletionDate:function (component, event, helper) {
        helper.validateCompletionDate(component);
    },

    onExecutedSignoffChanged: function (component, event, helper) {
        if (component.get('v.phase.record.Executed_Signoff_Link__c') !== component.get('v.phase.executedSignoff')) {
            component.set('v.phase.isExecutedSignoffValid', component.find('executedSignoff').isValid());
        }
    },

    onPhaseTypeChange: function (component, event, helper) {
        component.set('v.phase.phaseType', component.find('phaseTypeSelect').get('v.value'));
        helper.updateUI(component);
    }
});