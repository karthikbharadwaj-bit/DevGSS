({
    afterScriptsLoaded: function (component, event, helper) {
        helper.createApp(component);

        if (!component.get('v.app.approval.id')) return;

        helper.getApprovalFromController(component)
            .catch($A.getCallback(error => {
                if(!component.get('v.app').approval.record.Account__r.RC_User_ID__c) {
                    RC.salesforce.displayError('The Enterprise Account ID field on the Related Account should be populated to process refunds');
                } else {
                    RC.salesforce.displayError('Failed to Get Refunds', error);
                }
            }));
    },

    requestRefunds: function (component, event, helper) {
        helper.getRefunds(component);
    },

    sendRefunds: function (component, event, helper) {
        let app = component.get('v.app');
        app.setRefundsInProgress(true);
        helper.setApp(component);

        helper.sendRefundsToController(component)
            .then($A.getCallback( res => {
                return helper.sendNGBSRefundsToCtrl(component);
            }))
            .then($A.getCallback( res => {
                return helper.loadTransactionHistoryCtrl(component);
            }))
            .catch($A.getCallback(error => {
                RC.salesforce.displayError('Failed to Get Transaction History', error)
            }))
            .then($A.getCallback(res => {
                app.isSendRefundsInProgress = false;
                helper.updateApp(component);
            }));

    },

    onsubmit: function (component, event) {
        event.preventDefault();
        component.find('sendRefundsButton').focus();
    },

    onRefundManagementEvent: function (component, event, helper) {
        helper.updateApp(component, event.getParam('params').bypassAllTransactionsRerendering);
    },

    toggleRefundPopup: function(component, event, helper) {
        helper.preventRefundPopupClose = true;
        let refundPopupIcon = component.find('refundPopupIcon');
        let isShown = refundPopupIcon.get('v.iconName') === 'utility:up';

        refundPopupIcon.set('v.iconName', isShown ? 'utility:down' : 'utility:up');
        RC.cssUtils.toggleShow(component, 'refundPopup', !isShown);
    },

    onRefundAmountClick: function(component, event, helper){
        helper.preventRefundPopupClose = true;
    },

    loadMore: function(component, event, helper) {
        const app = component.get('v.app');
        const selectedTab = app.SelectedTab.id;

        if (app.IsLastPage || app.IsTransactionsInProgress) {
            return;
        }

        app.position(selectedTab, app.position() + app.transactionsPerPage());

        helper.loadTransactionInfo(component, selectedTab)
            .then($A.getCallback(() => {
                helper.setState(component);
                helper.loading(component, false, selectedTab);
            }));
    },

    rerender: function(component, event, helper) {
        helper.setApp(component, true);
    },

    handleProductTab: function(component, event, helper) {
        const app = component.get('v.app');

        helper.selectTab(component);

        if (component.get('v.app.isNotEmptyRefundedAmount')) {
            component.find("productSection")
                    .set("v.selectedTabId", app.SelectedTab.id);
            $A.get("e.c:ModalRequestEvent").setParams({
                header: $A.get("$Label.c.RM_Title_DiscardChangesConfirmation"),
                content: $A.get("$Label.c.RM_Message_DiscardChangesConfirmation"),
                buttons: [{
                    label: 'Ok',
                    variant: 'brand',
                    callback: () => helper.prepareTableView(component, app.SelectedTab.id, true)
                }]
            }).fire();
        } else {
            helper.prepareTableView(component, app.SelectedTab.id, false);
        }
    },

});