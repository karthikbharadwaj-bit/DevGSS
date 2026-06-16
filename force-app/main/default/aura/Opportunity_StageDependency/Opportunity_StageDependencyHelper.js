({
    getdowngradereason: function (component, event, helper, stagename) {
        console.log('Inside helper');
        var stageValue = component.find("StageField").get("v.value");
        console.log('stageValue' + stageValue);
        console.log('stagename' + stagename);
        if (stageValue == 'undefined' || stageValue == '') {
            console.log('inside if in downgrade');
            this.getSubDowngradeReason(component, event, helper, stagename);

            if (stagename == 'Lost' || stagename == 'Lost to Competition') {
                //this.getLosttoCompetition(component, event, helper,stagename);
                //this.getReasonforLoss(component, event, helper,stagename);
                //this.getServiceLost(component, event, helper,stagename);
            }
        }
        var action = component.get("c.getDependentPicklistValuesWithOptions");
        action.setParams({
            'sObjectName': 'Opportunity',
            'fieldName': 'Downgrade_Reason_Opp__c'

        });
        action.setCallback(this, function (response) {
            var stateofpick = response.getState();
            console.log(stateofpick);
            if (stateofpick == 'SUCCESS') {
                var map = response.getReturnValue();
                console.log('Downgrademap' + JSON.stringify(map));
                console.log('Downgrademap' + JSON.stringify(map));
                var li = map['0. Downgraded'];
                console.log('li-Downgradersn' + li);
                if (li != undefined || li != '') {
                    var newItems = [];
                    for (var i = 0; i < li.length; i++) {
                        var record = li[i];
                        var Item = {
                            Name: record
                        };
                        console.log('Item-> ' + JSON.stringify(Item));
                        newItems.push(Item);
                        console.log('newItems-> ' + JSON.stringify(newItems));
                    }
                    component.set("v.Dwngradereasons", newItems);

                }

            }
        });
        $A.enqueueAction(action);

    },
    getLosttoCompetition: function (component, event, helper, stagename) {
        console.log('inside getLosttoCompetition');
        var stageValue = component.find("DowngradeReason").get("v.value");

        console.log('stageValue in Losttocomp' + stageValue);
        var action = component.get("c.getDependentPicklistValuesWithOptions");
        action.setParams({
            'sObjectName': 'Opportunity',
            'fieldName': 'Primary_Competitor__c'

        });
        action.setCallback(this, function (response) {
            var stateofpick = response.getState();
            console.log(stateofpick);
            if (stateofpick == 'SUCCESS') {
                var map = response.getReturnValue();
                console.log('getLosttoCompetitionmap' + JSON.stringify(map));
                var li;
                if (stageValue != 'undefined') {
                    li = map['Lost'];
                } else {
                    li = map['Lost'];
                }
                if (li != 'undefined') {
                    var newItems = [];
                    for (var i = 0; i < li.length; i++) {
                        var record = li[i];
                        var Item = {
                            Name: record
                        };
                        console.log('Item-> ' + JSON.stringify(Item));
                        newItems.push(Item);
                        console.log('newItems-> ' + JSON.stringify(newItems));
                    }
                    console.log('li-Downgradersn' + li);
                    component.set("v.LosttoCompetition", newItems);
                }

            }
        });
        $A.enqueueAction(action);
    },
    getReasonforLoss: function (component, event, helper, stagename) {
        var stageValue = component.find("DowngradeReason").get("v.value");
        console.log(stageValue);
        var action = component.get("c.getDependentPicklistValuesWithOptions");
        action.setParams({
            'sObjectName': 'Opportunity',
            'fieldName': 'Primary_Loss_Reason__c'

        });
        action.setCallback(this, function (response) {
            var stateofpick = response.getState();
            console.log(stateofpick);
            if (stateofpick == 'SUCCESS') {
                var map = response.getReturnValue();
                console.log('getReasonforLossmap' + JSON.stringify(map));

                if (stageValue != undefined) {
                    var li = map['Lost'];
                } else {
                    var li = map['Lost'];
                }
                if (li != undefined || li != '') {
                    var newItems = [];
                    for (var i = 0; i < li.length; i++) {
                        var record = li[i];
                        var Item = {
                            Name: record
                        };
                        console.log('Item-> ' + JSON.stringify(Item));
                        newItems.push(Item);
                        console.log('newItems-> ' + JSON.stringify(newItems));
                    }
                    component.set("v.ReasonforLoss", newItems);
                }
            }
        });
        $A.enqueueAction(action);

    },
    getCustomerLimitations: function (component, event, helper, stagename) {
        var stageValue = component.find("ReasonforLoss").get("v.value");
        console.log(stageValue);
        var action = component.get("c.getDependentPicklistValuesWithOptions");
        action.setParams({
            'sObjectName': 'Opportunity',
            'fieldName': 'Customer_Limitations__c'

        });
        action.setCallback(this, function (response) {
            var stateofpick = response.getState();
            console.log(stateofpick);
            if (stateofpick == 'SUCCESS') {
                var map = response.getReturnValue();
                console.log('getCustomerLimitationsmap' + JSON.stringify(map));
                if (stageValue != 'undefined') {
                    var li = map[stageValue];
                } else {
                    var li = map[stagename];
                }
                if (li != 'undefined' || li != '') {
                    var newItems = [];
                    for (var i = 0; i < li.length; i++) {
                        var record = li[i];
                        var Item = {
                            Name: record
                        };
                        console.log('Item-> ' + JSON.stringify(Item));
                        newItems.push(Item);
                        console.log('newItems-> ' + JSON.stringify(newItems));
                    }
                    console.log('li-Downgradersn' + li);
                    component.set("v.CustomerLimitations", newItems);
                }
            }
        });
        $A.enqueueAction(action);
    },
    getRCProductGaps: function (component, event, helper, stagename) {
        var stageValue = component.find("ReasonforLoss").get("v.value");
        console.log(stageValue);
        var action = component.get("c.getDependentPicklistValuesWithOptions");
        action.setParams({
            'sObjectName': 'Opportunity',
            'fieldName': 'RC_Product_Gaps_Features__c'

        });
        action.setCallback(this, function (response) {
            var stateofpick = response.getState();
            console.log(stateofpick);
            if (stateofpick == 'SUCCESS') {
                var map = response.getReturnValue();
                console.log('getRCProductGapsmap' + JSON.stringify(map));
                if (stageValue != undefined) {
                    var li = map[stageValue];
                } else {
                    var li = map[stagename];
                }
                if (li != 'undefined' || li != '') {
                    var newItems = [];
                    for (var i = 0; i < li.length; i++) {
                        var record = li[i];
                        var Item = {
                            Name: record
                        };
                        console.log('Item-> ' + JSON.stringify(Item));
                        newItems.push(Item);
                        console.log('newItems-> ' + JSON.stringify(newItems));
                    }
                    console.log('li-Downgradersn' + li);
                    component.set("v.RCProductGaps", newItems);
                }
            }
        });
        $A.enqueueAction(action);
    },
    getServiceLost: function (component, event, helper, stagename) {
        var stageValue = component.find("DowngradeReason").get("v.value");
        console.log(stageValue);
        var action = component.get("c.getDependentPicklistValuesWithOptions");
        action.setParams({
            'sObjectName': 'Opportunity',
            'fieldName': 'Service_Lost__c'

        });
        action.setCallback(this, function (response) {
            var stateofpick = response.getState();
            console.log(stateofpick);
            if (stateofpick == 'SUCCESS') {
                var map = response.getReturnValue();
                console.log('getServiceLostmap' + JSON.stringify(map));
                if (stageValue == 'Lost to Competition') {
                    var li = map[stageValue];
                    console.log('li-Downgradersn' + li);
                    component.set("v.ServiceLost", li);

                }

            }
        });
        $A.enqueueAction(action);
    },
    getSubDowngradeReason: function (component, event, helper, stagename) {
        var stageValue = component.find("DowngradeReason").get("v.value");
        console.log(stageValue);
        var action = component.get("c.getDependentPicklistValuesWithOptions");
        action.setParams({
            'sObjectName': 'Opportunity',
            'fieldName': 'Sub_Downgrade_Reason__c'
        });
        action.setCallback(this, function (response) {
            var stateofpick = response.getState();
            console.log(stateofpick);
            if (stateofpick == 'SUCCESS') {
                var map = response.getReturnValue();
                console.log('getSubDowngradeReasonmap' + JSON.stringify(map));
                var li;
                if (stageValue != 'undefined') {
                    li = map[stageValue];
                } else {
                    li = map[stagename];
                }

                component.set("v.SubDowngradeReason", li);

            }
        });
        $A.enqueueAction(action);
    },

    getIncentive: function (component, event, helper) {
        var stageValue = component.find("StageField").get("v.value");
        console.log(stageValue);
        var action = component.get("c.getDependentPicklistValuesWithOptions");
        action.setParams({
            'sObjectName': 'Opportunity',
            'fieldName': 'Incentive__c'
        });
        action.setCallback(this, function (response) {
            var stateofpick = response.getState();
            console.log(stateofpick);
            if (stateofpick == 'SUCCESS') {
                var map = response.getReturnValue();
                console.log('getIncentivemap' + JSON.stringify(map));
                var li = map['RC product gaps/features'];
                console.log('li-Downgradersn' + li);
                component.set("v.Incentive", li);
            }
        });
        $A.enqueueAction(action);
    },

})