({
	saveDetails : function(component, event, helper) {
        let dqApproverList;
        this.saveApprovalDetails(component)
            .then($A.getCallback(() => {
                const p = component.get('v.parent');

                if(dqApproverList[0].isDQStatusApprovedORReject || component.get('v.isFromMobileAction')) {
                    // Refresh Parent component
                    p.refreshApproverList();
                }

                component.set('v.refreshScreen', false);
                component.set('v.DQApproverList', dqApproverList);
                component.set('v.refreshScreen',true);
                component.set('v.showApprovalAction', false);
            }))
            .catch($A.getCallback((e) => {
                console.error(e);
            }))
            .then($A.getCallback(() => {
                component.set('v.Spinner',false);
            }));
    },

    saveApprovalDetails: function(component) {
        const params = {
            approvalRecordId: component.get('v.approvalRecordId'),
            reason: this.getReason(component),
            status: this.getStatus(component),
        };

        if (component.get('v.isFromMobileAction')) {
            params.DQId = component.get('v.dealQualId');
        } else {
            params.DQId = component.get('v.objDealQualificationWrap').DQRec.Id;
        }

        return this.request(component, 'saveApprovalDetails', params);
    },

    request: function(component, name, params) {
        console.log(`${name} :: request params`, params);
        return new Promise(function (resolve, reject) {
            const action = component.get(`c.${name}`);
            action.setParams(params);
            action.setCallback(this, function(response) {
                console.log(`${name} :: response value`, response.getReturnValue());
                console.log(`${name} :: response error`, response.getError());
                if (response.getState() == 'SUCCESS') {
                    resolve(response.getReturnValue());
                } else {
                    reject(response.getError());
                }
            });
            $A.enqueueAction(action);
        });
    },

    getStatus: function(component) {
        return component.get('v.enabledApprove') ? 'Approved' : 'Rejected';
    },

    getReason: function(component) {
        return component.get('v.enabledApprove') ? component.get('v.approvedReason') : component.get('v.rejectReason');
    },
})