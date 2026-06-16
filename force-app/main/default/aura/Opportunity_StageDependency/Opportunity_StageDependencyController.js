({
    doInit: function (component, event, helper) {
        var IsClosed;
        var recId = component.get("v.recordId");
        console.log(recId);
        component.set("v.OppId", recId);

        var options = ["0.Downgraded", "7.Closed Won"];
        //console.log(component.find("StageField").get("v.value"));
        var action = component.get("c.getOppDetails");
        action.setParams({
            'OppId': recId
        });
        action.setCallback(this, function (response) {
            var state = response.getState();
            if (state === 'SUCCESS') {
                var oppObj = response.getReturnValue();
                console.log('opp-stagename' + oppObj.StageName);
                    
                    if (oppObj.StageName == '7. Closed Won')
                {
                      component.set("v.Closedwon",false);
                    
                }
                
                
                if (oppObj.StageName == '7. Closed Won' || oppObj.StageName == '0. Downgraded') {
                    component.find("StageField").set("v.value", oppObj.StageName);
                    var a = component.get('c.pickChange');
                    $A.enqueueAction(a);
                 if(oppObj.StageName == '0. Downgraded')
                 {
                       component.set("v.Downgrade",false); 
                 }
                                 
                   
                }
                if (oppObj.IsClosed == true) {
                    IsClosed = true;
                    component.set("v.IsClosed", oppObj.IsClosed);
                }

                console.log('opp-substagename' + oppObj.Sub_Stage__c);
                component.set("v.Opt", oppObj.StageName);
                component.set("v.SubOpt", oppObj.Sub_Stage__c);
                component.set("v.Dwnreasons", oppObj.Downgrade_Reason_Opp__c);
                component.set("v.LsttoCompetition", oppObj.Primary_Competitor__c);
                component.set("v.RsonforLoss", oppObj.Primary_Loss_Reason__c);
                component.set("v.CustomerLimit", oppObj.Customer_Limitations__c);
                component.set("v.RCProdGaps", oppObj.RC_Product_Gaps_Features__c);
                component.set("v.ServiceLst", oppObj.Service_Lost__c);
                component.set("v.SubDwngradeRsn", oppObj.Sub_Downgrade_Reason__c);
                component.set("v.Incntive", oppObj.Incentive__c);
                console.log('opt' + component.get("v.Opt"));
                console.log('Opt' + component.get("v.Opt"));
                console.log('Dwnreasons' + component.get("v.Dwngradereasons"));
                console.log('Dwnreasons-comp' + component.get("v.Dwnreasons"));
                console.log('isclosed' + oppObj.IsClosed);
                var action1 = component.get("c.getOptions");
                console.log('Rectype id' + oppObj.RecordTypeId);
                action1.setParams({
                    'RectypeId': oppObj.RecordTypeId,
                    'isClosed': false
                });
                action1.setCallback(this, function (response) {

                    var state1 = response.getState();
                    var records = response.getReturnValue();

                    console.log('recordsss' + JSON.stringify(response.getReturnValue()) + records.length + state1);

                    if (state1 == 'SUCCESS') {
                        console.log('inside success');
                        var newItems = [];

                        for (var i = 0; i < records.length; i++) {
                            var record = records[i];
                            var Item = {
                                Name: record
                            };
                            console.log('Item-> ' + JSON.stringify(Item));
                            newItems.push(Item);
                            console.log('newItems-> ' + JSON.stringify(newItems));
                        }
                        console.log('oppObj.isClosed??' + component.get("v.IsClosed"));
                        if (component.get("v.IsClosed") == true) {
                            var Item1 = {
                                Name: '0. Downgraded'
                            };
                            var Item2 = {
                                Name: '7. Closed Won'
                            };
                            var Item3 = {
                                Name: '7.1. Closed Won for ProServ'
                            };

                            component.set("v.recTypeId", oppObj.RecordTypeId);
                            newItems.push(Item1);
                            if (oppObj.StageName === '7.1. Closed Won for ProServ') {
                                newItems.push(Item3);
                            } else {
                                newItems.push(Item2);
                            }
                            component.set("v.Options", newItems);
                            console.log('newItems in closed-> ' + JSON.stringify(newItems));
                        } else {
                            component.set("v.Options", newItems);

                        }

                    }
                });
                $A.enqueueAction(action1);

            }
        });
        $A.enqueueAction(action);

    },
    //start doing substage picklist values work from here
    pickChange: function (component, event, helper, Stagename) {
        console.log('inside pickchange');
        var stageValue = component.find("StageField").get("v.value");
        console.log('Stagevalue inside pickchange' + stageValue);

        if (stageValue != '0. Downgraded') {

            component.set("v.Dwngradereasons", undefined);
            component.set("v.SubDowngradeReason", undefined);
            component.set("v.Downgrade",true);
            component.set("v.Closedwon",true);
            console.log('Before if'+stageValue);
            if (stageValue == '7. Closed Won')
                {
                      component.set("v.Closedwon",false);
                      console.log('inside pickchange'+component.get("v.Closedwon"));
                }

        } 
       
        else {
            component.find("StageField").set("v.value", '0. Downgraded');
            component.set("v.Downgrade",false);
            helper.getdowngradereason(component, event, helper);
        }
             
  
        var action = component.get("c.getDependentPicklistValuesWithOptions");
        var Dependentfieldsforstage = ['Sub_Stage__c', 'Downgrade_Reason_Opp__c']
        action.setParams({
            'sObjectName': 'Opportunity',
            'fieldName': 'Sub_Stage__c'

        });
        action.setCallback(this, function (response) {
            var stateofpick = response.getState();
            console.log(stateofpick);
            var li
            if (stateofpick == 'SUCCESS') {
                var map = response.getReturnValue();
                li = map[stageValue];
                console.log(map);

                component.set("v.SubOptions", li);

            }
        });
        $A.enqueueAction(action);

    },
    doUpdate: function (component, event, helper) {
        var stageValue;
        var substageValue;
        var Dwngradereasons;
        var SubDowngradeReason;
        component.set("v.loaded", true);
        if (component.find("StageField").get("v.value") != 'undefined' && component.find("StageField").get("v.value") != '') {
            stageValue = component.find("StageField").get("v.value");
            console.log('stageValue' + stageValue);

        }
        if (component.find("Sub-StageField").get("v.value") != 'undefined' && component.find("Sub-StageField").get("v.value") != '') {
            substageValue = component.find("Sub-StageField").get("v.value");
            console.log('substageValue' + substageValue);

        }
        if (component.find("DowngradeReason").get("v.value") != 'undefined' && component.find("DowngradeReason").get("v.value") != '') {
            Dwngradereasons = component.find("DowngradeReason").get("v.value");
            console.log(Dwngradereasons);
        }
        if (component.find("SubDowngradeReason").get("v.value") != 'undefined' && component.find("SubDowngradeReason").get("v.value") != '') {
            SubDowngradeReason = component.find("SubDowngradeReason").get("v.value");
            console.log(SubDowngradeReason);
        }
        /* var LosttoCompetition = component.find("LosttoCompetition").get("v.value");
        console.log(LosttoCompetition);
        var ReasonforLoss = component.find("ReasonforLoss").get("v.value");
        console.log(ReasonforLoss);
        var CustomerLimitations = component.find("CustomerLimitations").get("v.value");
        console.log(CustomerLimitations);
        var RCProductGaps = component.find("RCProductGaps").get("v.value");
        console.log(RCProductGaps);
        var ServiceLost = component.find("ServiceLost").get("v.value");
        console.log(ServiceLost);

        var Incentive = component.find("Incentive").get("v.value");
        console.log(Incentive);*/
        var recId = component.get("v.recordId");
        console.log(recId);
        var action = component.get("c.updateOpp");
        action.setParams({
            'recId': recId,
            'Stage': stageValue,
            'SubStage': substageValue,
            'Dwngradereasons': Dwngradereasons,
            'LosttoCompetition': '',
            'ReasonforLoss': '',
            'CustomerLimitations': '',
            'RCProductGaps': '',
            'ServiceLost': '',
            'SubDowngradeReason': SubDowngradeReason,
            'Incentive': ''

        });
        action.setCallback(this, function (response) {
            var stateofupdate = response.getState();

            if (stateofupdate == 'SUCCESS') {

                var Resp = response.getReturnValue();
                console.log('update resp' + Resp);
                if (Resp == 'Success') {
                    component.set("v.loaded", false);
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": "Success!",
                        "message": "The record has been updated successfully.",
                        "type":"success"
                    });
                    toastEvent.fire();
                } else {
					component.set("v.loaded", false);
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": "Error!",
                        "message": Resp,
                        "type":"error"
                    });
                    toastEvent.fire();
                   
                }

            }

        });
        $A.enqueueAction(action);

    },
    pickDowngradeChanges: function (component, event, helper) {
        //component.set("v.Downgrade",false);
        var stageValue = component.find("DowngradeReason").get("v.value");
        console.log('Stagevalue inside pickDowngradeChanges' + stageValue);
        helper.getSubDowngradeReason(component, event, helper);
        //helper.getIncentive(component, event, helper);
        if (stageValue == 'Lost' || stageValue == 'Lost to Competition') {
            //helper.getLosttoCompetition(component, event, helper);
            //helper.getReasonforLoss(component, event, helper);
            //helper.getServiceLost(component, event, helper);
        }

    },
    pickReasonforLoss: function (component, event, helper) {
        var ReasonforLoss = component.find("ReasonforLoss").get("v.value");
        if (ReasonforLoss == 'Customer limitations') {
            helper.getCustomerLimitations(component, event, helper);

        } else if (ReasonforLoss == 'RC product gaps/features') {
            helper.getRCProductGaps(component, event, helper);
        }
    },
    docancel: function (component, event, helper) {
        var recId = component.get("v.recordId");
        var navEvt = $A.get("e.force:navigateToSObject");
        navEvt.setParams({
            "recordId": recId,
            "slideDevName": "detail"
        });
        navEvt.fire();

    }

})