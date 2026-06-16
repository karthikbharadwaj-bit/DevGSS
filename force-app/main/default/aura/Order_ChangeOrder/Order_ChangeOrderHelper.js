({
    initChangeOrder: function(component, event, helper) {
        var orderId = component.get("v.currentOrderId");
        if (!orderId) {
            var recordId = component.get("v.recordId");
            if (recordId) {
                component.set("v.currentOrderId", recordId);
                orderId = recordId;
            }
        }

        this.runValidations(component, event, orderId);
    },

    runValidations: function(component, event, orderId) {
        component.set("v.failedValidation", false);

        this.checkPrimaryAccountContactRole(component);
        this.checkPhasesIsPendingApproval(component, event, orderId);
        this.checkIsOrderCompleted(component, event, orderId);
    },

    checkPrimaryAccountContactRole: function(component) {
        var primaryAccContactRole = component.get("v.contactId");
        if ($A.util.isEmpty(primaryAccContactRole)) {
            component.set("v.failedValidation", true);
            this.showToast(
                'warning',
                'Missing primary Account Contact Role',
                'You can\'t proceed with Change Order if Account is missing primary Account Contact Role'
            );
            return;
        }
    },

    checkPhasesIsPendingApproval: function(component, event, orderId) {
        var action = component.get("c.checkPhasesIsPendingApproval");
        action.setParams({ "orderId": orderId });
        action.setCallback(this, function(response) {
            if (!this.handleResponse(response, 'Change Order process failed')) {
                component.set("v.failedValidation", true);
                return;
            }
            var isOrderHasPendingForApprovalPhase = response.getReturnValue();
            component.set("v.isOrderHasPendingForApprovalPhase", isOrderHasPendingForApprovalPhase);

            if (isOrderHasPendingForApprovalPhase === true) {
                component.set("v.failedValidation", true);
                this.showToast(
                    'warning',
                    'Phases Pending Approval',
                    'You can\'t proceed with Change Order if there are Phases in Approval Process'
                );
                return;
            }
        });
        $A.enqueueAction(action);
    },

    checkIsOrderCompleted: function(component, event, orderId) {
        var action = component.get("c.checkOrderIsCompleted");
        action.setParams({ "orderId": orderId });
        action.setCallback(this, function(response) {
            if (!this.handleResponse(response, 'Change Order process failed')) {
                component.set("v.failedValidation", true);
                return;
            }

            var orderIsCompleted = response.getReturnValue();
            component.set("v.orderIsCompleted", orderIsCompleted);

            if (orderIsCompleted) {
                component.set("v.failedValidation", true);
                this.showToast(
                    'error',
                    'Error',
                    'You can not change this Order because it was completed already.'
                );
                return;
            }

            if (!component.get("v.failedValidation")) {
                this.processChangeOrder(component, orderId);
            }
        });
        $A.enqueueAction(action);
    },

    processChangeOrder: function(component, orderId) {
        var action = component.get("c.changeOrder");
        action.setParams({ "orderId": orderId });
        action.setCallback(this, function(response) {
            if (!this.handleResponse(response, 'Change Order process failed.')) {
                return;
            }

            var output = JSON.parse(response.getReturnValue());
            this.handleChangeOrderResponse(component, output);
        });
        $A.enqueueAction(action);
    },

    handleChangeOrderResponse: function(component, output) {
        var changeOrderOppId = output.data ? output.data.newOppId : null;

        if (changeOrderOppId) {
            this.showRedirectToNewOpptyToast(changeOrderOppId);
            this.redirectToOpportunity(changeOrderOppId);
        } else if (!changeOrderOppId && output.messages && output.messages.length > 0) {
            this.showRedirectToExistingOpptyToast(output.data.relatedChangeOpportunity);
            this.redirectToOpportunity(output.data.relatedChangeOpportunity);
        } else {
            this.showToast(
                'error',
                'Error',
                'Change Order process failed.'
            );
        }
    },

    redirectToOpportunity: function(opportunityId) {
        window.setTimeout(
            $A.getCallback(function() {
                var targetPageUrl = '/' + opportunityId;
                window.location.href = targetPageUrl;
            }), 5000
        );
    },

    handleResponse: function(response, defaultErrorMessage) {
        var state = response.getState();
        if (state === "SUCCESS") {
            return true;
        }

        var errors = response.getError();
        var errorMessage = defaultErrorMessage;
        if (errors && errors[0] && errors[0].message) {
            errorMessage = errors[0].message;
        }
        this.showToast(
            'error',
            'Error',
            errorMessage
        );
        return false;
    },

    showRedirectToNewOpptyToast: function(changeOrderOppId) {
        var message = "You will be forwarded to the created Opportunity. <br>\n Please click this link If you weren't:\n <a href='/" + changeOrderOppId + "'>Link to new Opportunity</a>";
        this.showToast(
            'success',
            'Change Order succeeded',
            message
        );
    },

    showRedirectToExistingOpptyToast: function(relatedChangeOpportunity) {
        var message = "Change Order Opportunity for the last Order has already been generated. You will be forwarded to it.<br>Please click this link If you weren't: <a href='/" + relatedChangeOpportunity + "'>Link to new Opportunity</a>";
        this.showToast(
            'warning',
            'Warning',
            message);
    },

    showToast: function(type, title, message) {
        window._rcnotify.addToast(
            {
                theme: type,
                header: title,
                details: message
            });
    },
})