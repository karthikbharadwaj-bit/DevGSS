({
    toggleResultDetails: function (component, event, helper) {
        event.stopPropagation();
        helper.togglePostRefundMessage(component);
    },

    toggleExpand: function (component, event, helper) {
        if (RC.htmlUtils.isTextSelection()) {
            return;
        }

        if (component.get('v.transaction.isExpanded')) {
            return helper.toggleExpand(component);
        }

        helper.loadTransaction(component)
            .then($A.getCallback(() => helper.toggleExpand(component)));
    },

    onFullRefundClicked: function (component, event, helper) {
        event.stopPropagation();

        helper.loadTransaction(component)
            .then(transaction => {
                if(!transaction.isExpanded) {
                    transaction.isExpanded = true;
                }

                const app = component.get('v.app');
                app.doFullRefundOnTransaction(transaction);

                component.set('v.transaction', transaction);

                component.getEvent("RefundManagementEvent")
                    .setParams({params: {bypassAllTransactionsRerendering: true}})
                    .fire();
            });
    }
});