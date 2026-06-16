({
    // ================================================================================
    //  Common Helpers
    // ================================================================================

    setWindowTitle: function (component) {
        document.title = component.get('v.app.approval.record.Account__r.Name') + ' - ' + document.title;
    },

    getApprovalId: function () {
        return new URL(window.location.href).searchParams.get("id");
    },

    // ================================================================================
    //  Salesforce Requests
    // ================================================================================

    getApprovalFromController: function (component) {
        const helper = this;
        let app = component.get('v.app');

        app.isGetDataInProgress(app.SelectedTab.id, true);

        this.setApp(component);

        return RC.salesforce.request(component, 'c.getApprovalInfo', {
            approvalId: app.approval.id
        })
            .then($A.getCallback(function (response) {
                app.featureToggle(response.data.featureToggle);
                app.setApproval(response.data.approvalRecord);
                app.migratedTechnicalAccounts = response.data.migratedTechnicalAccounts;
                app.setIsReadOnly(response.data.isReadOnly);

                if (app.FeatureToggle.ContactCenterRefunds__c) {
                    app.addTab(app.TAB_ID_CONTACTCENTER, {label: app.TAB_LABEL_CONTACTCENTER, transactionType: app.TX_TYPE_CC});
                }

                if (app.FeatureToggle.ProServ_Refunds__c) {
                    app.addTab(app.TAB_ID_PROSERV, {label: app.TAB_LABEL_PROSERV, transactionType: app.TX_TYPE_PS});
                }

                app.update();

                helper.createTabComponents(component);
                helper.setWindowTitle(component);

                return helper.loadTransactionHistoryCtrl(component);
            }))
            .catch($A.getCallback(err => {
                RC.salesforce.displayError('Failed to Get Approval And Account Records', err);
            }))
            .then($A.getCallback(function () {
                app = component.get('v.app');

                app.isGetDataInProgress(app.SelectedTab.id, false);

                helper.setApp(component);
            }));
    },

    sendRefundsToController: function (component) {
        const app = component.get('v.app');
        const items = app.getTalendToSend();

        if (!items.length) return Promise.resolve();

        let itemsToTrim = JSON.parse(JSON.stringify(items));

        for (let item of itemsToTrim) {
            for (let ref of item.refundedItem) {
                let amount = ref.refundAmount + "";
                if (amount.indexOf(".") !== -1) {
                    ref.refundAmount = Number.parseFloat(amount.slice(0, (amount.indexOf(".")) + 3));
                }
            }
            item.transactionType = app.getTransactionType();
        }

        const params = {
            postRefundData: JSON.stringify(itemsToTrim),
            approvalId: app.approval.record.Id,
            accUserId: app.approval.record.Account__r.RC_User_ID__c,
            transactionType: app.getTransactionType()
        };

        return RC.salesforce.request(component, 'c.postRefundsWrapper', params)
            .then($A.getCallback(postRefundsResult => {
                app.setPostRefundsResult(postRefundsResult);
            }))
            .catch($A.getCallback(error => RC.salesforce.displayError('Failed to Post Refunds', error)));
    },

    sendNGBSRefundsToCtrl: function (component) {
        const helper = this;

        let promiseSequence = Promise.resolve();

        try {
            const promiseList = [
                ...helper.getNGBSRefundPromiseList(component),
                ...helper.getNGBSInvoicePromiseList(component),
            ];

            promiseSequence = _.reduce(
                promiseList,
                (sequence, promise) => sequence.then($A.getCallback(res => promise())),
                Promise.resolve()
            );
        } catch (e) {
            RC.salesforce.displayError('Failed to Send NGBS Refunds', e);
        }

        return promiseSequence;
    },

    /* Get Promise List */
    getNGBSRefundPromiseList: function (component) {
        const app = component.get('v.app');
        const list = app.getBillToSend();

        return list.map(item => this.applyNGBSWrapper(component, item, 'c.applyBillingRefund'));
    },
    getNGBSInvoicePromiseList: function (component) {
        const app = component.get('v.app');
        const list = app.getInvoiceToSend();

        return list.map(item => this.applyNGBSWrapper(component, item, 'c.applyInvoiceAdjustment'));
    },

    applyNGBSWrapper: function (component, item, ctrl) {
        return () => this.applyNGBSRefunds(component, item, ctrl);
    },

    applyNGBSRefunds: function (component, item, ctrl) {
        const app = component.get('v.app');

        const params = {
            approvalId: app.approval.record.Id,
            billingAccountId: app.approval.record.Account__r.Billing_ID__c,
            transactionJson: JSON.stringify(item)
        };

        return RC.salesforce.request(component, ctrl, params)
            .then($A.getCallback(res => {

                if (!res.data || !res.data.transactionHistory) {
                    return;
                }

                const trId = res.data.transactionHistory.TransactionId__c;
                const status = res.status;
                const message = _.reduce(res.messages, (full, item) => {
                    full += full.length ? '; ' + item.message : item.message;
                    return full;
                }, '');


                app.setTransactionResult(trId, status, message);
                this.setApp(component);

                return res;
            }))
            .catch($A.getCallback(error => RC.salesforce.displayError('Failed to apply Refunds', error)));
    },

    // ================================================================================
    //  App helpers
    // ================================================================================

    createApp: function (component) {
        const app = new RM.classes.App();

        app.defaultDateRange({
            start: moment({ h : 0, m : 0, s : 0, ms : 0}).subtract(1, 'month'),
            end: moment({ h : 0, m : 0, s : 0, ms : 0})
        });

        app.addTab(app.TAB_ID_RINGCENTRAL, {label: app.TAB_LABEL_RINGCENTRAL, transactionType: app.TX_TYPE_RC});

        app.approval.id = this.getApprovalId();

        component.set('v.app', app);

        this.setApp(component);
    },

    updateApp: function (component, bypassAllTransactionsRerendering) {
        const app = component.get('v.app');

        app.update();

        this.updateNotifications(component);

        this.setApp(component, bypassAllTransactionsRerendering);
    },

    updateNotifications: function (component) {
        component.find('NotificationsBar').update();
    },

    // ================================================================================
    //  UI (fixed header, etc...)
    // ================================================================================

    addEventListeners: function (component) {
        const helper = this;

        window.addEventListener('click', $A.getCallback(function () {
            if (helper.preventRefundPopupClose) {
                helper.preventRefundPopupClose = false;
                return;
            }
            helper.closeRefundPopup(component);
        }));
    },

    closeRefundPopup: function (component) {
        let refundPopupIcon = component.find('refundPopupIcon');
        let isShown = refundPopupIcon.get('v.iconName') === 'utility:up';

        if (isShown) {
            refundPopupIcon.set('v.iconName', 'utility:down');
            RC.cssUtils.toggleShow(component, 'refundPopup', false);
        }
    },

    setApp: function (component, bypassAllTransactionsRerendering) {
        const app = component.get('v.app');
        component.set('v.app', app);

        if (!bypassAllTransactionsRerendering) {
            this.setState(component);
        }
    },

    // New process
    getTransactions: function (component, currentTab) {
        let helper = this;
        let app = component.get('v.app');
        let account = app.approval.record.Account__r;

        if (!account.Billing_ID__c && !account.RC_User_ID__c) {
            return;
        }

        app.transactionsPerPage(10);
        app.transactions(currentTab, []);

        helper.loading(component, true, currentTab);

        return Promise.all([
            helper.getTalendTransactionsCtrl(component, account.RC_User_ID__c, app.approval.id, app.StartDate, app.EndDate),
            currentTab === app.TAB_ID_RINGCENTRAL ? helper.getNGBSTransactionsCtrl(component, account.Billing_ID__c, app.StartDate, app.EndDate) : []
        ])
            .then($A.getCallback(([talend, ngbs]) => [...talend || [], ...ngbs || []]))
            .then($A.getCallback(items => helper.sortByDate(items)))
            .then($A.getCallback((items) => app.transactions(currentTab, items)))
            .then($A.getCallback(() => helper.loadTransactionInfo(component, currentTab)))
            .catch($A.getCallback(err => RC.salesforce.displayError('Failed to Get All Transactions', err)));
    },

    sortByDate: function (transactions) {
        return _.sortBy(transactions, tr => -new Date(tr.transactionDate).getTime());
    },

    getTalendTransactionsCtrl: function (component, accUserId, approvalId, startDate, endDate) {
        const app = component.get('v.app');
        if (!accUserId) {
            return Promise.resolve({transactions: []});
        }

        const params = {
            accUserId: accUserId,
            approvalId: approvalId,
            transactionType: app.getTransactionType(),
            startDate: startDate.toJSON(),
            endDate: endDate.toJSON()
        };

        return RC.salesforce.request(component, 'c.getTalendTransactions', params, null, false, true)
            .then($A.getCallback(res => {
                return res.transactions;
            }))
            .catch($A.getCallback(err => {
                RC.salesforce.displayError('Failed to Get Talend Transactions', err);
            }));
    },

    getNGBSTransactionsCtrl: function (component, billingAccId, startDate, endDate) {
        if (!billingAccId || !startDate || !endDate) {
            return Promise.resolve([]);
        }

        const params = {
            accountBillingId: billingAccId,
            startDate: startDate.format('YYYY-MM-DD'),
            endDate: endDate.format('YYYY-MM-DD')
        };

        return RC.salesforce.request(component, 'c.getNGBSTransactions', params)
            .catch($A.getCallback(err => {
                RC.salesforce.displayError('Failed to Get NGBS Transactions', err);
            }));
    },

    getNGBSTransactionDetailsCtrl: function (component, transactions, billingAccId) {
        return transactions.map(tr => {
            const params = {
                billingAccId: billingAccId,
                transactionId: tr.record.transactionId,
                ngbsType: tr.ngbsType
            };

            return RC.salesforce.request(component, 'c.getNGBSProductItems', params)
                .then($A.getCallback(res => {
                    res.transactionId = params.transactionId;
                    return res;
                }))
                .catch($A.getCallback(err => {
                    RC.salesforce.displayError('Failed to Get Transaction Details', err);
                }));
        });
    },

    loadTransactionDetailsPromise: function (component, currentTab) {
        let helper = this;
        let app = component.get('v.app');
        let account = app.approval.record.Account__r;

        if (!app.transactions(currentTab).find(tr => !tr.products.length)) {
            helper.setApp(component);
            return Promise.resolve();
        }

        let ngbsRange = app.transactions(currentTab).filter(tr => tr.ngbsType);
        const promises = helper.getNGBSTransactionDetailsCtrl(component, ngbsRange, account.Billing_ID__c);

        helper.loading(component, true, currentTab);
        return Promise.all([...promises])
            .then($A.getCallback(details => {
                app.updateProducts(details);
            }))
            .catch($A.getCallback(err => {
                RC.salesforce.displayError('Failed to Get Details Transactions', err);
            }));
    },

    loadTransactionInfo: function (component, currentTab) {
        const helper = this;
        return helper.loadTransactionDetailsPromise(component, currentTab)
            .then($A.getCallback(() => {
                helper.loadTransactionHistoryCtrl(component);
            }))
            .catch($A.getCallback(err => {
                RC.salesforce.displayError('Failed to get transactions info', err);
            }));
    },

    loadTransactionHistoryCtrl: function (component) {
        const helper = this;
        const app = component.get('v.app');
        const params = {approvalId: app.approval.id};

        return RC.salesforce.request(component, 'c.getTalendTransactionHistory', params, null, false, true)
            .then($A.getCallback(transactionHistory => {
                app.transactionHistory = transactionHistory;
                helper.updateApp(component);
                return transactionHistory;
            }))
            .catch($A.getCallback(err => {
                RC.salesforce.displayError('Failed to load transaction history', err);
            }));
    },

    loading: function (component, val, tabName) {
        const app = component.get('v.app');

        app.isTransactionsInProgress(tabName, val);

        this.setApp(component);
    },

    prepareTableView: function (component, currentTab, isTabChanged) {
        const app = component.get('v.app');
        const currentTransactions = app.transactions(currentTab);
        const productSection = component.find("productSection");

        if (currentTransactions && currentTransactions.length) {
            this.setState(component, currentTransactions);
        }

        if (isTabChanged && productSection) {
            productSection.set("v.selectedTabId", app.SelectedTab.id);
            app.discard();
        }

        this.updateApp(component);
    },

    setState: function (component) {
        const app = component.get('v.app');

        component.set('v.transactions', app.getTransactionPage(app.SelectedTab.id, app.CurrentPage));
    },

    getRefunds: function (component) {
        const app = component.get('v.app');
        const currentTab = app.SelectedTab.id;

        app.position(currentTab, 0);

        if (!app.isProceedTransaction(currentTab)) {
            app.isProceedTransaction(currentTab, true);

            this.getTransactions(component, currentTab)
                .then($A.getCallback(() => {
                    this.setState(component);

                    app.isProceedTransaction(currentTab, false);

                    //Stop to show loading placeholder only after all transactions was finished
                    if (!app.isProceedTransaction(currentTab)) {
                        this.loading(component, false, currentTab);
                        app.incrementTabRequestCounter(currentTab);
                        app.updateMessage();
                    }

                }));
        } else {
            const transactions = [];

            app.transactions(currentTab, transactions);

            component.set('v.transactions', transactions);
        }

    },

    getSelectedTab: function (component) {
        const app = component.get('v.app');
        const productSection = component.find('productSection');

        if (app.FeatureToggle.ContactCenterRefunds__c) {
            return productSection.get('v.selectedTabId');
        } else {
            return app.TAB_ID_RINGCENTRAL;
        }
    },

    selectTab: function (component) {
        const app = component.get('v.app');
        const currentTab = this.getSelectedTab(component);

        app.SelectedTab = currentTab;

        component.set('v.app', app);

        return app.SelectedTab.id;
    },

    createTabComponents: function (component) {
        const app = component.get('v.app');

        RC.components.createMany(_.map(app.TABS, (tab) => [ 'lightning:tab', { id: tab.id, label: tab.label } ]))
            .then($A.getCallback((components) => {
                component.set('v.tabs', components);
            }))
            .catch($A.getCallback((error) => {
                console.error(error);
            }));
    },
});