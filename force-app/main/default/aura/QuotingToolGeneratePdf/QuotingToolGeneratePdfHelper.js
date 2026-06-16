({
    constants: {
        'ATTACHMENT_ERROR' : 'ERROR',
        'ATTACHMENT_SUCCESS' : 'SUCCESS',
        'ATTACHMENT_IN_PROGRESS' : 'ATTACHING'
    },
    getPdfTemplates: function(component) {
        var quote = component.get('v.quote');
        if (quote) {
            var selectTemplateSpinner = component.find("selectTemplateSpinner");
            var selectTemplateFieldset = component.find("selectTemplateFieldset");
            $A.util.removeClass(selectTemplateSpinner, 'slds-hide');
            $A.util.addClass(selectTemplateFieldset, 'slds-hide');
            var state = component.get('v.state');
            var action = component.get("c.getPdfTemplates");
            var prms = {
                opportunityId: quote.OpportunityId,
                quoteId: quote.Id
            };
            action.setParams({
                params: prms
            });
            action.setCallback(this, function(actionResult) {
                if (component.isValid() && actionResult.getState() === "SUCCESS") {
                    var templateList = actionResult.getReturnValue();
                    if (Array.isArray(templateList) && templateList.length > 0) {
                        this.setTemplateList(component, templateList);
                    } else {
                        component.set("v.templateList", []);
                    }
                    $A.util.addClass(selectTemplateSpinner, 'slds-hide');
                    $A.util.removeClass(selectTemplateFieldset, 'slds-hide');
                } else {
                    var errmsg = actionResult.getError()[0].message;
                    $A.get("e.c:ToastEvent").setParams({
                        theme: "error",
                        header: "PDF templates load failed",
                        details: errmsg,
                        defaultTimeout: false
                    }).fire();
                }
            });
            $A.enqueueAction(action);
        }
    },
    attachAllPdfsToOpportunity: function(component, pendingAttachments) {
        if (pendingAttachments.length == 0) {
            const successfulAttachment = component.get('v.attachmentResult') !== this.constants.ATTACHMENT_ERROR;
            const resultMessage = successfulAttachment ? 'The upload finished successfully' : 'The upload finished with errors';

            this.changeTitle(component, resultMessage);
            component.set('v.closeButtonLabel', 'Close');

            if (component.get('v.isModalMinimized') || !successfulAttachment) {
                component.set('v.awaitingForResults', true);
            } else {
                setTimeout(() => {
                    if (component.get('v.isAttachmentBusy')) {
                        this.closeDialog(component);
                    }
                }, 3000);
            }
            component.set('v.currentAttachment', null);
            component.set('v.attachmentResult', '');

            return;
        }

        const currentTemplateId = pendingAttachments[0].Id;
        const currentTemplateName = pendingAttachments[0].Name;
        const quote = component.get("v.quote");
        component.set('v.currentAttachment', pendingAttachments[0]);

        let msgWasSuccessful = false;
        let errorMsg = '';

        if (quote && currentTemplateId) {
            RC.salesforce.request(component, 'c.AttachPdfToOpportunity', {
                params: {
                    quoteId: quote.Id,
                    opportunityId: quote.OpportunityId,
                    templateId: currentTemplateId,
                    newModel: 'true'
                }}
            )
            .then($A.getCallback( result => {
                // Handle success
                msgWasSuccessful = component.isValid();
            }))
            .catch($A.getCallback( error => {
                // Handle error
                errorMsg = ' - Error, please try again later';
            }))
            .then($A.getCallback( () => {
                // Finally
                this.pushNewMessage(
                    component,
                    currentTemplateName + errorMsg,
                    msgWasSuccessful ? 'success' : 'error',
                    msgWasSuccessful ? 'aq-icon-text-success' : 'aq-icon-text-error'
                );
                component.set('v.attachmentResult', msgWasSuccessful ? this.constants.ATTACHMENT_IN_PROGRESS : this.constants.ATTACHMENT_ERROR);
                this.attachAllPdfsToOpportunity(component, pendingAttachments.slice(1, pendingAttachments.length));
            }));
        } else {
            errorMsg = ' - either the Quote or the Template ID were empty';
            this.pushNewMessage(component, currentTemplateName + errorMsg, 'error', 'aq-icon-text-error');
            this.attachAllPdfsToOpportunity(component, pendingAttachments.slice(1, pendingAttachments.length));
        }
    },
    pushNewMessage: function(component, text, icon, style) {
        let messages = component.get('v.messages');
        messages.push({
            'text': text,
            'icon': icon,
            'style': style
        });
        component.set('v.messages', messages);
    },
    previewPDF: function(component) {
        var modal = component.find('pdfModal');
        var selectTemplateContainer = component.find('selectTemplateContainer');
        var generateAndPreviewContainer = component.find('generateAndPreviewContainer');
        $A.util.removeClass(modal, 'slds-modal--medium');
        $A.util.addClass(modal, 'pdf-modal_fullscreen');
        $A.util.addClass(selectTemplateContainer, 'slds-hide');
        $A.util.removeClass(generateAndPreviewContainer, 'slds-hide');
        component.set('v.generatePdf', true);
    },
    /**
     * Close Modal
     */
    closeDialog: function(component){
        var modal = component.find('pdfModal');
        var pdfModalBg = component.find('pdfModalBg');
        var selectTemplateContainer = component.find('selectTemplateContainer');
        var generateAndPreviewContainer = component.find('generateAndPreviewContainer');
        var attachmentsContainer = component.find('attachments');

        $A.util.removeClass(pdfModalBg, 'slds-backdrop--open');
        $A.util.removeClass(modal, 'slds-fade-in-open');
        $A.util.addClass(modal, 'slds-hide');
        $A.util.addClass(modal, 'slds-modal--medium');
        $A.util.removeClass(modal, 'pdf-modal_fullscreen');
        $A.util.removeClass(selectTemplateContainer, 'slds-hide');
        $A.util.addClass(generateAndPreviewContainer, 'slds-hide')
        $A.util.addClass(attachmentsContainer, 'slds-hide');;

        component.set('v.isAttachmentBusy', false);
        component.set('v.generatePdf', false);
        component.set('v.awaitingForResults', false);
        component.set('v.isModalMinimized', false);
        component.set('v.closeButtonLabel', 'Minimize');
    },
    minimizeDialog: function(component){
        var modal = component.find('pdfModal');
        var pdfModalBg = component.find('pdfModalBg');

        $A.util.removeClass(pdfModalBg, 'slds-backdrop--open');
        $A.util.removeClass(modal, 'slds-fade-in-open');
        $A.util.addClass(modal, 'slds-hide');

        component.set('v.isModalMinimized', true);
    },
    /**
     * Disable/Enable Buttons
     * Show/Hide Tooltip
     */
    checkButtons: function(component){
        var quote = component.get('v.quote');
        var isSummaryChanged = component.get('v.isSummaryChanged');

        var generatePDFTooltipDisabled = true;
        var generatePDFTooltip = [];
        var generatePDFButtonDisabled = true;

        if (quote) {
            if (isSummaryChanged) {
                generatePDFTooltipDisabled = false;
                generatePDFTooltip.push('You need to save the Quote&nbsp;first');
            } else {
                var state = component.get('v.state');
                var expDateValid = component.get('v.isExpDateValid');

                generatePDFButtonDisabled = false;

                // Quote is on approval
                if (state.isQuoteRequiresApproval) {
                    generatePDFButtonDisabled = true;
                    generatePDFTooltipDisabled = false;
                    generatePDFTooltip.push('Quote requires an&nbsp;approval');
                }
                if (state.isQuoteOnApproval) {
                    generatePDFButtonDisabled = true;
                    generatePDFTooltipDisabled = false;
                    generatePDFTooltip.push('Quote pending for&nbsp;approval');
                }

                // Quantity Errors
                if (quote.InvalidDiscountedPhonesQuantity__c ||
                    quote.InvalidGlobalOfficePhonesQuantity__c |
                    quote.InvalidLimitedExtensionPhonesQuantity__c ||
                    quote.Invalid_Number_of_800_Setups__c ||
                    quote.Invalid_Number_of_Int_TF_Setups__c ||
                    quote.Invalid_Number_of_Vanity_Setups__c ||
                    quote.Invalid_GO_LE_Phones_Quantity__c) {
                    generatePDFButtonDisabled = true;
                    generatePDFTooltipDisabled = false;
                    generatePDFTooltip.push('There is a phones quantity error on the&nbsp;Quote');
                }

                if (quote.Required_Area_Codes_are_empty__c) {
                    generatePDFButtonDisabled = true;
                    generatePDFTooltipDisabled = false;
                    generatePDFTooltip.push('Area Codes are not selected for DLs and phone&nbsp;numbers');
                }

                if (quote.QuoteType__c === 'Agreement') {
                    // B-1462 Disable "Generate PDF" button if Stage == "Agreement" for Relayware
                    if (state.isUserRelayware) {
                        generatePDFButtonDisabled = true;
                        generatePDFTooltipDisabled = false;
                        generatePDFTooltip.push('Quote is in Agreement&nbsp;stage');
                    }
                    // B-4904 Disable "Generate PDF" button if Stage == "Agreement" and Initial Term is not filled
                    if (!quote.Initial_Term_months__c) {
                        generatePDFButtonDisabled = true;
                        generatePDFTooltipDisabled = false;
                        generatePDFTooltip.push('Initial Term is not specified for the&nbsp;Agreement');
                    }
                    // B-4904 Disable "Generate PDF" button if Stage == "Agreement" and Start Date is not filled
                    if (!quote.Start_Date__c) {
                        generatePDFButtonDisabled = true;
                        generatePDFTooltipDisabled = false;
                        generatePDFTooltip.push('Start Date is not specified for the&nbsp;Agreement');
                    }
                    // B-4904 Disable "Generate PDF" button if Stage == "Agreement" and End Date is not filled
                    if (!quote.End_Date__c) {
                        generatePDFButtonDisabled = true;
                        generatePDFTooltipDisabled = false;
                        generatePDFTooltip.push('End Date is not specified for the&nbsp;Agreement');
                    }
                }

                // B-1861 Expiration Date Limitation
                if (!expDateValid) { // if date is not valid
                    generatePDFButtonDisabled = true;
                    generatePDFTooltipDisabled = false;
                    generatePDFTooltip.push('Expiration Date should be in the range from the current date to 30 days from the current&nbsp;date');
                }
            }
        }

        component.set('v.generatePDFButtonDisabled',generatePDFButtonDisabled);
        component.set('v.generatePDFTooltipDisabled',generatePDFTooltipDisabled);

        var generatePDFTooltipText = '';
        if (generatePDFTooltip.length > 0) {
            generatePDFTooltipText += '<b>PDF generation is disabled because:</b>';
            generatePDFTooltipText += '<ul class="slds-list--dotted slds-m-top--xx-small">';
            generatePDFTooltip.forEach(function(message){
                generatePDFTooltipText += '<li>'+message+'</li>';
            });
            generatePDFTooltipText += '</ul>';
        }
        component.set('v.generatePDFTooltipText',generatePDFTooltipText);
    },
    /**
     * Show/Hide Generate Pdf button
     * Displaying logic stored in NavButtonGroup component
     */
    checkDisplaying: function(component){
        QW.cssUtils.toggleShow(component, 'generatePDFButtonContainer', component.get('v.showButton'));
    },
    selectTemplate: function(component, templateId){
        let templates = component.get('v.templateList');
        templates.forEach( elem => {
            if (elem.Id === templateId) {
                elem.checked = !elem.checked;
            }
        })
        component.set('v.templateList', templates);
    },
    showPopover: function(target, iconTheme, text){
        $A.get("e.c:PopoverEvent").setParams({
            target: target,
            show: true,
            showIcon: true,
            iconTheme: iconTheme,
            preferredPosition: 'right',
            text: text
        }).fire();
    },
    /**
     * Hide popover
     * @fires PopoverEvent
     */
    hidePopover: function(){
        $A.get("e.c:PopoverEvent").setParams({
            show: false
        }).fire();
    },
    /**
     * Prepare template List
     * Disable templates if necessary
     * @param component
     * @param templateList
     */
    setTemplateList: function(component, templateList){
        var settings = component.get('v.settings');
        var state = component.get('v.state');

        templateList.map(function(template){
            template.disabled = false;
            template.checked = false;
            if (template.Requirements__c){
                var popovers = [];

                // Contact Role record with ‘Billing Contact’ role is required
                if (template.Requirements__c.includes('Billing Contact Required') && !settings.isHasBillingContact){
                    template.disabled = true;
                    popovers.push(QW.popover.MESSAGES.billingContactRequiredForPDF);
                }

                // Contact Center Products required
                if (!state.isQuoteHaveContactCenter) {
                    if (template.Requirements__c.includes('Contact Center Products Required')) {
                        template.disabled = true;
                        popovers.push(QW.popover.MESSAGES.contactCenterProductsRequiredForPDF);
                    }
                    else if (template.Requirements__c.includes('RC contact Center Products Required')) {
                        template.disabled = true;
                        popovers.push(QW.popover.MESSAGES.rcContactCenterProductsRequiredForPDF);
                    }
                }

                if (popovers.length > 0)
                    template.popovers = JSON.stringify(popovers);

            }
            return template;
        });
        component.set("v.templateList", templateList);
    },
    /**
     * Gets all the selected (by checkboxes) templates to preview them all together
     * @param component
     */
    filterSelectedTemplates: function(component) {
        var filteredTemplates = [];
        component.get('v.templateList').forEach( template => {
            if (template.checked) {
                filteredTemplates.push(template);
            }
        });
        if (filteredTemplates.length > 0) {
            component.set('v.currentTemplateId', filteredTemplates[0].Id);
            component.set('v.selectedTemplate', filteredTemplates[0]);
            this.changeTitle(component, filteredTemplates[0].Name);
        }
        component.set('v.filteredTemplates', filteredTemplates);
        component.set('v.currentTemplateIndex', 0);
    },
    disableAllSpinners: function(component) {
        const currentTemplateIndex = component.get('v.currentTemplateIndex');
        component.get('v.filteredTemplates').forEach( (template, index) => {
            const currentElementSpinner = component.find('spinneriframe' + template.Id);
            $A.util.addClass(currentElementSpinner, 'disable-spinner');
        });
    },
    swapPdf: function(component, diff) {
        var currentElement = component.find('filtered' + component.get('v.currentTemplateId'));
        var currentElementSpinner = document.getElementById('spinneriframe' + component.get('v.currentTemplateId'));

        $A.util.addClass(currentElement, 'unfocusTemplate');
        $A.util.addClass(currentElementSpinner, 'disable-spinner');
        component.set('v.currentTemplateIndex', component.get('v.currentTemplateIndex') + diff);

        const currentTemplate = component.get('v.filteredTemplates')[component.get('v.currentTemplateIndex')];
        component.set('v.currentTemplateId', currentTemplate.Id);
        component.set('v.selectedTemplate', currentTemplate); // For attaching in CRM-580, until we develop CRM-581 (multi-attachment)
        currentElement = component.find('filtered' + component.get('v.currentTemplateId'));
        currentElementSpinner = document.getElementById('spinneriframe' + component.get('v.currentTemplateId'));

        $A.util.removeClass(currentElement, 'unfocusTemplate');
        $A.util.removeClass(currentElementSpinner, 'disable-spinner');
        this.changeTitle(component, currentTemplate.Name);
    },
    changeTitle: function(component, newTitle) {
        component.set('v.mainTitle', newTitle);
    }
});