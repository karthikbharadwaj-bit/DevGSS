({
    toggleExpand: function (component) {
        var transaction = component.get('v.transaction');

        transaction.isExpanded = !transaction.isExpanded;

        component.set('v.transaction', transaction);
    },

    togglePostRefundMessage: function (component) {
        var transaction = component.get('v.transaction');

        transaction.postRefundResult.isMessageShown = !transaction.postRefundResult.isMessageShown;

        component.set('v.transaction', transaction);
    },

    loadTransaction: function (component) {
        const transaction = component.get('v.transaction');
        const app = component.get('v.app');
        if (app.FeatureToggle.Alternative_Refund_Transactions_Requests__c &&
            !transaction.isWithDetails &&
            !transaction.ngbsType) {
            component.set('v.isLoading', true);
            if (app.FeatureToggle.Large_Transactions_Processing__c) {
                return this.paginateTransaction(component);
            } else {
                return this.processFullTransaction(component);
            }
        }
        return Promise.resolve(transaction);
    },


    processFullTransaction: function(component) {
        const transaction = component.get('v.transaction');
        const app = component.get('v.app');
        const result = Promise.resolve(transaction);
        return result
                .then($A.getCallback(transaction => RC.salesforce.request(component, 'c.getTransactionDetails', {
                    userId: app.approval.record.Account__r.RC_User_ID__c,
                    approvalId: app.approval.id,
                    transactionId: transaction.id,
                    transactionType: app.getTransactionType()
                })))
                .then($A.getCallback(result => {
                    transaction.initTransaction(result.transactions[0]);
                    transaction.update();
                    transaction.setIsWithDetails(true);
                    component.get('v.app').updateTransactions();
                    return transaction;
                }))
                .catch($A.getCallback(error => RC.salesforce.displayError('Failed to get transaction details', error)))
                .then($A.getCallback(() => {
                    component.set('v.isLoading', false);
                    return transaction;
                }));
    },

    paginateTransaction: function(component) {
        const transaction = component.get('v.transaction');
        const app = component.get('v.app');
        const result = Promise.resolve(transaction);
        return result
                .then($A.getCallback(transaction => RC.salesforce.request(component, 'c.getTransactionPagesInfo', {
                    userId: app.approval.record.Account__r.RC_User_ID__c,
                    approvalId: app.approval.id,
                    transactionId: transaction.id,
                    transactionType: app.getTransactionType()
                })))
                .then($A.getCallback(transactionPages => {
                    let pageAmount = Array.from(new Array(parseInt(transactionPages.sessionPageCount)), (x,i) => i+1);
                    let promises = [];
                    pageAmount.forEach((page) => {
                        promises.push(this.getTransactionDetails(component, transactionPages, page))
                    })
                    return Promise.all(promises);
                }))
                .catch($A.getCallback(error => RC.salesforce.displayError('Failed to get transaction details', error)))
                .then($A.getCallback(pageList => {
                    if (pageList) {
                        /* Accumulate each page response */
                        let res = pageList;
                        for (let page = 0; page < pageList.length; page++) {
                            if (page == 0) {
                                continue;
                            }
                            pageList[0].transactions[0].productItems.push(...pageList[page].transactions[0].productItems);
                        }
                        transaction.initTransaction(res[0].transactions[0]);
                        transaction.update();
                        transaction.setIsWithDetails(true);
                        component.get('v.app').updateTransactions();
                    }
                    return transaction;
                }))
                .then($A.getCallback(() => {
                    component.set('v.isLoading', false);
                    return transaction;
                }));
    },

    getTransactionDetails: function (component, transactionPages, page) {
        var app = component.get('v.app');
        const transaction = component.get('v.transaction');
        /* The last "true" parameter required to split transactions into separate contexts*/
        return RC.salesforce.request(component, 'c.getTransactionDetails', {
            userId: app.approval.record.Account__r.RC_User_ID__c,
            approvalId: app.approval.id,
            transactionId: transaction.id,
            transactionType: app.getTransactionType(),
            sessionId: transactionPages.sessionId,
            sessionPageId: page
        }, null, null, true)
    }
});