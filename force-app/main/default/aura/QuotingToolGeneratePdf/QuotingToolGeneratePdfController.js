({
    doInit: function(component, event, helper) {
        helper.checkButtons(component);
    },
    initDialog: function(component, event, helper) {
        var modal = component.find('pdfModal');
        var pdfModalBg = component.find('pdfModalBg');
        $A.util.addClass(pdfModalBg, 'slds-backdrop--open');
        $A.util.addClass(modal, 'slds-fade-in-open');
        $A.util.removeClass(modal, 'slds-hide');
        component.set('v.isModalMinimized', false);

        if (!component.get('v.isAttachmentBusy')) {
            helper.changeTitle(component, 'Generate PDF');
            helper.getPdfTemplates(component);
        }
    },
    endDialog: function(component, event, helper) {
        helper.closeDialog(component);
    },
    closeAttachmentComponent: function(component, event, helper) {
        if (component.get('v.currentAttachment')) {
            helper.minimizeDialog(component);
        } else {
            helper.closeDialog(component);
        }
    },
    generateAndPreview: function(component, event, helper) {
        helper.filterSelectedTemplates(component);
        helper.disableAllSpinners(component);
        helper.previewPDF(component);
    },
    backToSelectTemplate: function(component, event, helper) {
        var modal = component.find('pdfModal');
        var selectTemplateContainer = component.find('selectTemplateContainer');
        var generateAndPreviewContainer = component.find('generateAndPreviewContainer');
        $A.util.addClass(modal, 'slds-modal--medium');
        $A.util.removeClass(modal, 'pdf-modal_fullscreen');
        $A.util.removeClass(selectTemplateContainer, 'slds-hide');
        $A.util.addClass(generateAndPreviewContainer, 'slds-hide');
        helper.changeTitle(component, 'Generate PDF');
    },
    selectTemplate: function(component, event, helper) {
        helper.selectTemplate(component, event.target.getAttribute('id'));
        const amountSelected = component.get('v.templateList').filter( template => { return template.checked }).length;
        component.set('v.generatePdf', amountSelected > 0);
    },
    disableSpinner: function(component, event, helper) {
        document.getElementById('spinner' + event.target.getAttribute('id')).style.display='none';
    },
    /**
     * Attach pdf to Opportunity
     */
    attachToOpportunity: function(component, event, helper) {
        var modal = component.find('pdfModal');
        var attachmentsContainer = component.find('attachments');
        var generateAndPreviewContainer = component.find('generateAndPreviewContainer');

        $A.util.addClass(generateAndPreviewContainer, 'slds-hide');
        $A.util.removeClass(modal, 'pdf-modal_fullscreen');
        $A.util.removeClass(attachmentsContainer, 'slds-hide');

        component.set('v.messages', []);
        component.set('v.attachmentResult', helper.constants.ATTACHMENT_IN_PROGRESS);
        component.set('v.isAttachmentBusy', true);
        helper.changeTitle(component, 'Attaching files...');
        helper.attachAllPdfsToOpportunity(component, component.get('v.filteredTemplates'));
    },
    /**
     * Show tooltip when user hover Generate PDF Button
     */
    mouseOverButton: function(component, event) {
        var generatePDFTooltipDisabled = component.get('v.generatePDFTooltipDisabled');
        if (!generatePDFTooltipDisabled) {
            var generatePDFTooltipText = component.get('v.generatePDFTooltipText');
            $A.get("e.c:PopoverEvent").setParams({
                target: event.target,
                showIcon: true,
                iconTheme: 'info',
                show: true,
                preferredPosition: 'top',
                text: generatePDFTooltipText
            }).fire();
        }
    },
    /**
     * Hide tooltip
     */
    mouseOutButton: function(component, event, helper) {
        $A.get("e.c:PopoverEvent").setParams({
            show: false
        }).fire();
    },
    quoteChanged: function(component, event, helper) {
        helper.checkButtons(component);
    },
    stateChanged: function(component, event, helper) {
        helper.checkButtons(component);
    },
    checkGeneratePDFButton: function(component, event, helper) {
        helper.checkButtons(component);
    },
    showButtonChanged: function(component, event, helper) {
        helper.checkDisplaying(component);
    },
    mouseOverWarningIcon: function(component, event) {
        QW.popover.show(event.currentTarget, JSON.parse(event.currentTarget.dataset.popover));
    },
    hidePopover: function(component, event, helper) {
        helper.hidePopover();
    },
    previousPDF: function(component, event, helper) {
        if (component.get('v.currentTemplateIndex') > 0) {
            helper.swapPdf(component, - 1);
        }
    },
    nextPDF: function(component, event, helper) {
        if (component.get('v.currentTemplateIndex') < component.get('v.filteredTemplates').length - 1) {
            helper.swapPdf(component, + 1);
        }
    }
});