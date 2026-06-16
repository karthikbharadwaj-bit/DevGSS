({
    approveRejectApprovalRequest: function (component, params) {
        var helper = this;
        RC.spinner.show(`${params.action} in progress`);

        RC.salesforce.request(component, 'c.setApprovalAction', {
                params: params
            })
            .then($A.getCallback(function () {
                component.find("approveRejectComment").set("v.value", '');
                helper.modalClose(component);
            }))
            .catch($A.getCallback(function (error) {
                $A.get("e.c:ToastEvent").setParams({
                    theme: "error",
                    header: `${params.action} failed`,
                    details: RC.salesforce.getResponseError(error),
                    defaultTimeout: false,
                }).fire();
            }))
            .then($A.getCallback(function () {
                // refresh quote
                $A.get("e.c:QuotingToolRefreshQuoteEvent").fire();
                RC.spinner.hide();
            }));
    },

    recallApprovalRequest: function (component, params) {
        var helper = this;
        RC.spinner.show('Recalling');

        RC.salesforce.request(component, 'c.setApprovalAction', {
                params: params
            })
            .then($A.getCallback(function () {
                component.find("recallComment").set("v.value", '');
                helper.modalClose(component);
            }))
            .catch($A.getCallback(function (error) {
                $A.get("e.c:ToastEvent").setParams({
                    theme: "error",
                    header: "Recall failed",
                    details: RC.salesforce.getResponseError(error),
                    defaultTimeout: false,
                }).fire();
            }))
            .then($A.getCallback(function () {
                // refresh quote
                $A.get("e.c:QuotingToolRefreshQuoteEvent").fire();
                RC.spinner.hide();
            }));
    },

    submitForApproval: function (component, params) {
        RC.spinner.show('Submitting for Approval');

        RC.salesforce.request(component, 'c.generateQuoteDetails', {
            params: params
        })
        .catch($A.getCallback(function (error) {
            $A.get("e.c:ToastEvent").setParams({
                theme: "error",
                header: "Quote details generation failed",
                details: RC.salesforce.getResponseError(error),
                defaultTimeout: false,
            }).fire();
        }));

        RC.salesforce.request(component, 'c.submitApprovalRequest', {
                params: params
            })
            .catch($A.getCallback(function (error) {
                $A.get("e.c:ToastEvent").setParams({
                    theme: "error",
                    header: "Submit for approval failed",
                    details: RC.salesforce.getResponseError(error),
                    defaultTimeout: false,
                }).fire();
            }))
            .then($A.getCallback(function () {
                // refresh quote
                $A.get("e.c:QuotingToolRefreshQuoteEvent").fire();
                RC.spinner.hide();
            }));
    },

    approvalVisibility: function (component) {
        var Wizard = component.get('v.Wizard');

        var isApprovalEnabled = Wizard.opportunity
            && Wizard.currentQuote
            && !Wizard.currentQuote.isAgreement
            && !Wizard.opportunity.isClosed
            && !Wizard.opportunity.isPendingConfirmAndClose;

        var isUserAllowed = isApprovalEnabled
            && (Wizard.user.isOpportunityOwner
                || Wizard.user.isQuoteCreator
                || Wizard.currentQuote.isCCorProServ
                || Wizard.settings.isUserRoleAllowed);

        var isSumbitForApprovalVisible = isApprovalEnabled
            && Wizard.currentQuote.isApprovalRequired
            && isUserAllowed;

        var isRecallApprovalModalButtonVisible = isApprovalEnabled
            && Wizard.currentQuote.isOnApproval
            && isUserAllowed;

        var isApproveRejectModalButtonVisible = isApprovalEnabled
            && Wizard.currentQuote.isOnApproval
            && (Wizard.user.isCurrentLevelApprover || Wizard.user.isSysAdmin);

        if (isSumbitForApprovalVisible && Wizard.currentQuote)
            component.find('submitForApprovalButton')
                .set('v.disabled', Wizard.currentQuote.isHasErrors
                               || (!Wizard.settings.isTelus && !Wizard.currentQuote.record.JustificationandDescription__c));

        RC.cssUtils.toggleShow(component, 'submitForApprovalButtonWrapper', isSumbitForApprovalVisible);
        RC.cssUtils.toggleShow(component, 'recallApprovalModalButton', isRecallApprovalModalButtonVisible);
        RC.cssUtils.toggleShow(component, 'approveRejectModalButton', isApproveRejectModalButtonVisible);
    },

    modalClose: function (component) {
        var modal = component.find('modal');
        var modalBg = component.find('modalBg');
        $A.util.removeClass(modalBg, 'slds-backdrop--open');
        $A.util.removeClass(modal, 'slds-fade-in-open');
        $A.util.addClass(modal, 'slds-hide');
    },

    showPopover: function (component, auraId, target) {
        var Wizard = component.get('v.Wizard');

        if (!Wizard.currentQuote)
            return;

        var messages = [];

        switch (auraId) {

            case 'submitForApprovalButton':

                if (!Wizard.settings.isTelus && !Wizard.currentQuote.record.JustificationandDescription__c)
                    messages.push(QW.popover.MESSAGES.descriptionRequiredForApproval);

                if (Wizard.currentQuote.isHasErrors)
                    messages.push(QW.popover.MESSAGES.approvalErrors);

                break;
        }

        // Show popover
        if (target && messages.length > 0) {
            QW.popover.show(target, messages);
        }
    },
});