({
    quoteType: function(component) {
        var upsellStatus = component.get('v.upsellStatus');
        var text = {
            "New": "New Customer",
            "Upsell": "Upsell",
            "Upgrade": "Upgrade"
        };
        var quoteType = text.hasOwnProperty(upsellStatus) ? text[upsellStatus] : upsellStatus;
        component.set('v.quoteType', quoteType);
        if (quoteType) {
            $A.util.removeClass(component.find('quoteType'), 'slds-hide');
        } else {
            $A.util.addClass(component.find('quoteType'), 'slds-hide');
        }
    },
    /**
     * Approval Status
     */
    approvalStatus: function(component) {
        var quote = component.get('v.quote');
        var state = component.get('v.state');
        var approvalStatus = null;

        if (quote){
            approvalStatus = (state.isUserRelayware && state.isQuoteOnApproval) ?
                'Pending Approval' :
                quote.Approved_Status__c;
        }

        component.set('v.approvalStatus', approvalStatus);
        if (quote && approvalStatus) {
            $A.util.removeClass(component.find('approvalStatus'), 'slds-hide');
        } else {
            $A.util.addClass(component.find('approvalStatus'), 'slds-hide');
        }
    },
    /**
     * Approvers Dropdown
     */
    currentApprover: function(component) {
        var quote = component.get('v.quote');
        var settings = component.get('v.settings');
        var currentApprover = null;
        var approversToDisplay = [];
        var showDropdown = false;
        var nextApproverLabel = 'Next Approver';
        if (quote) {

            // Max Approval
            var maxApprovalLevel = settings.PENDING_APPROVAL_STATUSES.length;

            // Approval Stage
            var pendingIndex = settings.PENDING_APPROVAL_STATUSES.indexOf(quote.Approved_Status__c);
            var preApproval  = settings.PRE_APPROVAL_STATUSES.indexOf(quote.Approved_Status__c) > -1;
            var approval     = pendingIndex > -1;
            var postApproval = settings.POST_APPROVAL_STATUSES.indexOf(quote.Approved_Status__c) > -1;
            var approvalTypes = ['Sales Manager', 'Sales Manager Manager', 'Sales VP', 'Finance'];

            showDropdown = preApproval || approval || postApproval;

            if (showDropdown) {
                // Label
                if (preApproval) {
                    nextApproverLabel = 'Required Approver';
                } else if (postApproval){
                    nextApproverLabel = 'Last Approver';
                }

                // Get Approvers from Quote
                var approversList = [];
                for (var i = 1; i <= maxApprovalLevel; i++) {
                    approversList.push(quote['Level_' + i + '_Approver__r']);
                }

                // Create Approvers List
                approversList.forEach(function(approver, index){
                    var Lindex = index + 1;
                    var levelApprover = {};
                    levelApprover.name = approver ? approver.Name : 'Unknown';
                    levelApprover.link = approver ? '/' + approver.Id : null;

                    // Title
                    var hierarchyRole = approver ? approver.Hierarchy_Role__c : '';
                    var title = settings.isNewGOAFeatureEnabled ? hierarchyRole : approvalTypes[index];
                    levelApprover.title = 'L' + Lindex + ': ' + (title || 'Unknown');

                    // Icon
                    if (postApproval || index < pendingIndex) {
                        levelApprover.status = 'Approved';
                        levelApprover.icon = 'approval';
                        levelApprover.theme = 'success';
                    } else if (approval && ((pendingIndex) === index )) {
                        levelApprover.status = 'Pending Approval';
                        levelApprover.icon = 'clock';
                        levelApprover.theme = 'info';
                    } else {
                        levelApprover.status = 'Required';
                        levelApprover.icon = 'info';
                        levelApprover.theme = 'info';
                    }
                    approversToDisplay.push(levelApprover);
                });

                // Clean Approvers list
                for (var j = approversList.length-1; j >= 0 ; j--) {
                    if (!approversList[j] && pendingIndex < j){
                        approversToDisplay.splice(-1,1);
                    } else {
                        break;
                    }

                }

                // Current Approver
                if(approval){
                    currentApprover = approversToDisplay[pendingIndex];
                } else if (postApproval){
                    currentApprover = approversToDisplay[approversToDisplay.length-1];
                } else {
                    currentApprover = approversToDisplay[0];
                }


            }
        }

        component.set('v.approvers', approversToDisplay);
        var approversDropdown = component.find('currentApprover');
        if (showDropdown && currentApprover) {
            $A.util.removeClass(approversDropdown, 'slds-hide');
            component.set('v.currentApprover', currentApprover);
            component.set('v.nextApproverLabel',nextApproverLabel);
        } else {
            $A.util.addClass(approversDropdown, 'slds-hide');
        }
    },
    numberOfLines: function(component) {
        this.setNumberDls(component);
        var numberDLs = component.get('v.numberDLs');
        var quote = component.get('v.quote');
        var upsellStatus = component.get('v.upsellStatus');

        // Show number of lines only on Upsell/Upgrade
        if (numberDLs && (upsellStatus === 'Upsell' || upsellStatus === 'Upgrade')) {
            $A.util.removeClass(component.find('numberDLs'), 'slds-hide');
        } else {
            $A.util.addClass(component.find('numberDLs'), 'slds-hide');
        }
    },
    setNumberDls: function(component) {
        var quote = component.get('v.quote');
        if(quote && quote.QuoteLineItems) {
            quote.QuoteLineItems.forEach(function(quoteLineItem){
                if(quoteLineItem.Product2.Family == 'Service' && quoteLineItem.Entitlement__r) {
                    component.set('v.numberDLs', quoteLineItem.Entitlement__r.Quantity__c);
                }
            });
        }
    },
    closeApprovers: function(component) {
        $A.util.removeClass(component.find('allApprovers'), 'approver-dropdown--open');
        $A.util.removeClass(component.find('allApproversOverlay'), 'approver-overlay--open');
    },
    /**
     * Show/hide elements depending on user
     * @see B-897 Quote Wizard Changes for Relayware
     */
    checkUserAccess: function(component) {
        var currentApprover = component.find('currentApprover');

        if (component.get('v.state.isUserRelayware')) {
            $A.util.addClass(currentApprover, 'relayware--disable');
        } else {
            $A.util.removeClass(currentApprover, 'relayware--disable');
        }
    },
    billingSystem: function(component) {
        var wizard = component.get('v.wizard');
        if (wizard && wizard.opportunity && wizard.opportunity.record) {
            const billingSystem = wizard.opportunity.record.Is_Billing_Opportunity__c 
                ? RC.CONSTANTS.BILLING_SYSTEM.NGBS
                : RC.CONSTANTS.BILLING_SYSTEM.LEGACY
            component.set('v.billingSystem', billingSystem);
        }
    }
})