({
    doInit: function(component, event, helper) {
        /**
         * All possible notifications described here
         * Checker function automatically called from helper with name checkNotification_%notification name%
         * Priority described for each tab - lower are higher
         * [Service Plans, Products, Cart, Phase, Quote Summary ]
         *
         * @see https://docs.google.com/spreadsheets/d/1XGqkXsAle-cXoSYPpd0MqH7KqSVN2GiPkYysTJXNh6k Documentation
         */
        var allNotifications = [
            {
                name: 'tiersUnavailable',
                text: $A.get("$Label.c.QW_Notification_tiersUnavailable_text"),
                type: 'warning',
                priority: [1, 1, 1, 1, 1]
            }, {
                name: 'engagementCancelled',
                text: $A.get("$Label.c.QW_Notification_engagementCancelled_text"),
                type: 'info',
                priority: [2, 2, 2, 2, 2]
            }, {
                name: 'changesAreNotAllowedInAgreementStage',
                text: $A.get("$Label.c.QW_Notification_changesAreNotAllowedInAgreementStage_text"),
                type: 'warning',
                actionLink: 'Get help',
                helpText: $A.get("$Label.c.QW_Notification_changesAreNotAllowedInAgreementStage_helpText"),
                priority: [3, 3, 3, 3, 3]
            }, {
                name: 'invalidDiscountedPhonesQuantity',
                text: $A.get("$Label.c.QW_Notification_invalidDiscountedPhonesQuantity_text"),
                type: 'warning',
                actionLink: 'Get help',
                helpText: $A.get("$Label.c.QW_Notification_invalidDiscountedPhonesQuantity_helpText"),
                priority: [4, 4, 4, 6, 5]
            }, {
                name: 'invalidDiscountedPhonesQuantityForUpsell',
                text: $A.get("$Label.c.QW_Notification_invalidDiscountedPhonesQuantityForUpsell_text"),
                type: 'warning',
                actionLink: 'Get help',
                helpText: $A.get("$Label.c.QW_Notification_invalidDiscountedPhonesQuantityForUpsell_helpText"),
                priority: [5, 5, 5, 7, 6]
            }, {
                name: 'invalidGlobalOfficePhonesQuantity',
                text: $A.get("$Label.c.QW_Notification_invalidGlobalOfficePhonesQuantity_text"),
                type: 'warning',
                actionLink: 'Get help',
                helpText: $A.get("$Label.c.QW_Notification_invalidGlobalOfficePhonesQuantity_helpText"),
                priority: [6, 6, 6, 8, 7]
            }, {
                name: 'invalidLimitedExtensionPhonesQuantity',
                text: $A.get("$Label.c.QW_Notification_invalidLimitedExtensionPhonesQuantity_text"),
                type: 'warning',
                actionLink: 'Get help',
                helpText: $A.get("$Label.c.QW_Notification_invalidLimitedExtensionPhonesQuantity_helpText"),
                priority: [7, 7, 7, 9, 8]
            }, {
                name: 'invalidGlobalOfficeLimiteExtensionPhonesQuantity',
                text: $A.get("$Label.c.QW_Notification_invalidGlobalOfficeLimiteExtensionPhonesQuantity_text"),
                type: 'warning',
                actionLink: 'Get help',
                helpText: $A.get("$Label.c.QW_Notification_invalidGlobalOfficeLimiteExtensionPhonesQuantity_helptext"),
                priority: [8, 8, 8, 10, 9]
            }, {
                name: 'vanityPhonesQuantity',
                text: $A.get("$Label.c.QW_Notification_vanityPhonesQuantity_text"),
                type: 'warning',
                actionLink: 'Get help',
                helpText: $A.get("$Label.c.QW_Notification_vanityPhonesQuantity_helpText"),
                priority: [9, 9, 9, 11, 10]
            }, {
                name: '800TollFreePhonesQuantity',
                text: $A.get("$Label.c.QW_Notification_800TollFreePhonesQuantity_text"),
                type: 'warning',
                actionLink: 'Get help',
                helpText: $A.get("$Label.c.QW_Notification_800TollFreePhonesQuantity_helpText"),
                priority: [10, 10, 10, 12, 11]
            }, {
                name: 'internationalTollFreePhonesQuantity',
                text: $A.get("$Label.c.QW_Notification_internationalTollFreePhonesQuantity_text"),
                type: 'warning',
                actionLink: 'Get help',
                helpText: $A.get("$Label.c.QW_Notification_internationalTollFreePhonesQuantity_helpText"),
                priority: [11, 11, 11, 13, 12]
            }, {
                name: 'fixErrors',
                text: $A.get("$Label.c.QW_Notification_fixErrors_text"),
                type: 'warning',
                actionLink: 'Get help',
                helpText: $A.get("$Label.c.QW_Notification_fixErrors_helpText"),
                priority: [12, 12, 17, 19, 4]
            }, {
                name: 'rentalPhonesAvailability',
                text: $A.get("$Label.c.QW_Notification_rentalPhonesAvailability_text"),
                type: 'warning',
                actionLink: 'Go to Summary',
                priority: [13, 13, 12, 14, 17]
            }, {
                name: 'ccSeatsAdvanced',
                text: $A.get("$Label.c.QW_Notification_ccSeatsAdvanced_text"),
                type: 'info',
                priority: [15, 15, 14, 16, 16]
            }, {
                name: 'ccSeatsUltimate',
                text: $A.get("$Label.c.QW_Notification_ccSeatsUltimate_text"),
                type: 'info',
                priority: [16, 16, 15, 17, 17]
            }, {
                name: 'upsellDigitalLines',
                text: $A.get("$Label.c.QW_Notification_upsellDigitalLines_text"),
                type: 'info',
                priority: [18, 14, 13, 15, 14]
            }, {
                name: 'specialTerms',
                text: $A.get("$Label.c.QW_Notification_specialTerms_text"),
                type: 'info',
                actionLink: 'Go to Summary',
                priority: [19, 19, 19, 21, 13]
            }, {
                name: 'pendingForApproval',
                text: $A.get("$Label.c.QW_Notification_pendingForApproval_text"),
                type: 'info',
                priority: [20, 20, 20, 22, 20]
            }, {
                name: 'activeAgreementSpecialTerms',
                text: $A.get("$Label.c.QW_Notification_activeAgreementSpecialTerms_text"),
                type: 'info',
                priority: [21, 21, 21, 23, 21]
            }, {
                name: 'areaCodesNull',
                text: $A.get("$Label.c.QW_Notification_areaCodesNull_text"),
                type: 'warning',
                actionLink: 'Get help',
                helpText: $A.get("$Label.c.QW_Notification_areaCodesNull_helpText"),
                priority: [22, 22, 22, 24, 22]
            }, {
                name: 'mainAreaCodeIsNull',
                text: $A.get("$Label.c.QW_Notification_mainAreaCodeIsNull_text"),
                type: 'warning',
                actionLink: 'Get help',
                helpText: $A.get("$Label.c.QW_Notification_mainAreaCodeIsNull_helpText"),
                priority: [23, 23, 23, 25, 23]
            }, {
                name: 'wrongBillingAddress',
                text: $A.get("$Label.c.QW_Notification_WrongBillingAddress"),
                type: 'warning',
                priority: [24, 24, 10, 26, 10]
            },
            // Professional Services
            {
                name: 'proServDifferentPB',
                text: $A.get("$Label.c.QW_Notification_proServDifferentPB_text"),
                type: 'warning',
                actionLink: 'Get help',
                helpText: $A.get("$Label.c.QW_Notification_proServDifferentPB_helpText"),
                priority: [24, 24, 24, 26, 24]
            },
            // Phase Management
            {
                name: 'assignAllPhaseLineItems',
                text: $A.get("$Label.c.QW_Notification_assignAllPhaseLineItems_text"),
                type: 'warning',
                actionLink: 'Go to Phases',
                priority: [25, 25, 25, 4, 26]
            }, {
                name: 'emptyPhases',
                text: $A.get("$Label.c.QW_Notification_emptyPhases_text"),
                type: 'warning',
                actionLink: 'Go to Phases',
                priority: [26, 26, 26, 25, 27]
            }, {
                name: 'proServInProgress',
                text: $A.get("$Label.c.QW_Notification_proServInProgress_text"),
                type: 'info',
                priority: [27, 27, 27, 27, 25]
            }, {
                name: 'proservSoldRequired',
                text: $A.get("$Label.c.QW_Notification_proservSoldRequired_text"),
                type: 'warning',
                priority: [28, 28, 28, 28, 28]
            }, {
                name: 'proServDetails',
                text: $A.get("$Label.c.QW_Notification_proServDetails_text"),
                type: 'info',
                priority: [29, 29, 29, 29, 29]
            },
            // Contact Center: weak product dependencies
            {
                name: 'ccAmeliaVoiceNoTTS',
                text: $A.get("$Label.c.QW_Notification_ccAmeliaVoiceNoTTS"),
                type: 'info',
                priority: [30, 30, 30, 30, 30]
            }, {
                name: 'ccAmeliaTTSNoVoice',
                text: $A.get("$Label.c.QW_Notification_ccAmeliaTTSNoVoice"),
                type: 'info',
                priority: [31, 31, 31, 31, 31]
            }, {
                name: 'ccTextelShortCodeNoMonthly',
                text: $A.get("$Label.c.QW_Notification_ccTextelShortCodeNoMonthly"),
                type: 'info',
                priority: [32, 32, 32, 32, 32]
            }, {
                name: 'ccTextelLongCodeNoTierInternational',
                text: $A.get("$Label.c.QW_Notification_ccTextelLongCodeNoTierInternational"),
                type: 'info',
                priority: [33, 33, 33, 33, 33]
            }];
        component.set("v.allNotifications", allNotifications);

        helper.addEventListeners(component);
    },

    quoteChanged: function(component, event, helper) {
        helper.closeNotifications(component);
        helper.checkNotifications(component);
    },

    stateChanged: function(component, event, helper) {
        helper.checkNotifications(component);
    },

    cartItemsChanged: function(component, event, helper) {
        helper.checkNotifications(component);
    },

    specialTerms: function(component, event, helper) {
        var action = event.getParam("action");
        component.set("v.showSpecialTerms", action === "show");
        helper.checkNotifications(component);
    },

    upgrade: function(component, event, helper) {
        component.set('v.isUpgrade', event.getParam("upgrade"));
        helper.checkNotifications(component);
    },

    helperAction: function(component, event, helper) {
        var action = event.target.dataset.action;
        var getHelpActions = [
            'changesAreNotAllowedInAgreementStage',
            'invalidDiscountedPhonesQuantity',
            'invalidGlobalOfficePhonesQuantity',
            'invalidLimitedExtensionPhonesQuantity',
            'invalidCommonPhonesQuantity',
            'fixErrors',
            'vanityPhonesQuantity',
            '800TollFreePhonesQuantity',
            'internationalTollFreePhonesQuantity',
            'proServDifferentPB',
            'areaCodesNull',
            'mainAreaCodeIsNull',
            'invalidGlobalOfficeLimiteExtensionPhonesQuantity'
        ];
        if (getHelpActions.indexOf(action) > -1) {
            event.stopPropagation();
            if (!$A.util.hasClass(component.find('notificationsContainer'), 'notifications--open'))
                helper.openNotifications(component);

            var activeNotifications = component.get('v.activeNotifications');
            var notification = helper.findNotification(activeNotifications, action);

            notification.isHelpTextShown = true;

            component.set('v.activeNotifications', activeNotifications);
        } else if (action) {
            $A.get("e.c:QuotingToolNotificationActionEvent").setParams({
                name: action
            }).fire();
        }
    },

    toggleNotifications: function(component, event, helper) {
        var notificationsContainer = component.find('notificationsContainer');
        if ($A.util.hasClass(notificationsContainer, 'notifications--open')) {
            helper.closeNotifications(component);
        } else {
            component.set('v.preventNotificationsClose', true);
            helper.openNotifications(component);
        }
    },

    deleteQuote: function(component) {
        component.set("v.showSpecialTerms", false);
    },

    newQuote: function(component) {
        component.set("v.showSpecialTerms", false);
    },

    wizardChanged: function(component, event, helper){
        helper.checkNotifications(component);
    },

    tabsChanged: function(component, event, helper){
        helper.checkNotifications(component);
    }
});