({
    sync: function(component,event,helper,opportunityId,isBillingOpportunity,rcnotify) {

        const errors = this.validate(isBillingOpportunity);
        if (errors.length > 0)
        {
            errors.forEach(error => rcnotify.addToast(error));
            return Promise.reject();
        }
        rcnotify.showSpinner();

        var action1=component.get("c.validateSyncWithNGBS");
        var recId = component.get("v.recordId");
        action1.setParams({
            "opportunityId":recId
        });

        action1.setCallback(this,function(response)
        {

            var state = response.getState();
            console.log('state'+state);

            if(state=='SUCCESS'){
                var result=response.getReturnValue();
                var resp= JSON.parse(result);
                console.log('res'+resp);
                console.log('reslen'+resp.length);
                console.log('reslen'+resp.size);
                if (resp.length > 0) {
                    rcnotify.hideSpinner();
                    this.handleResults(result,rcnotify);
                }
                else {
                    rcnotify.hideSpinner();
                    /*component.set("v.isSuccess",true);
                    component.set("v.url",'/apex/syncWithNGBS?id='+recId);
                    var cmpTarget = component.find('Modalbox');
        			var cmpBack = component.find('Modalbackdrop');
       				$A.util.addClass(cmpTarget, 'slds-fade-in-open');
        		    $A.util.addClass(cmpBack, 'slds-backdrop--open'); */
                    //this.SyncNGBSType(component,event,helper,opportunityId,isBillingOpportunity,rcnotify);
                    this.openModal(recId,rcnotify);
                    $A.get("e.force:closeQuickAction").fire();
                }
            }
        });
        $A.enqueueAction(action1);
    },

    //SyncNGBSType
    SyncNGBSType:function(component,event,helper,opportunityId,isBillingOpportunity,rcnotify) {

        var action2 = component.get("c.getSyncNGBSType");
        /*action2.setParams({
       });*/
        action2.setCallback(this, function(response){

            var state = response.getState();

            console.log('State-getSyncNGBSType'+state);
            if(state=='SUCCESS')
            {
                var val=response.getReturnValue();
                console.log('resp-getSyncNGBSType'+JSON.stringify(val));
                if (val === 'v1')
                {
                    this.syncWNGBS(component,event,helper,isBillingOpportunity,rcnotify);
                }
                else if (val === 'v2')
                {
                    console.log('inside v2');
                    rcnotify.hideSpinner();
                    this.openModal(opportunityId,rcnotify);
                }
                else {
                    rcnotify.hideSpinner();
                }
            }
        });
        $A.enqueueAction(action2);
    },
    //syncWNGBS
    syncWNGBS:function(component,event,helper,isBillingOpportunity) {
        var action3=component.get("c.syncWithNGBS");
        var recId = component.get("v.recordId");
        action3.setParams({
            "recordId":recId
        });
        action3.setCallback(this, function(response){
            var state = response.getState();
            if(state=='SUCCESS'){
                var val=response.getReturnValue();
                var res =JSON.parse(val);
                rcnotify.hideSpinner();
                this.handleResults(res,rcnotify);
                if (this.isShowPopUpWindow(res))
                {
                    const promptOptions = {
                        header: 'Sync with NGBS',
                        content: this.getMessage(),
                        trueButtonText: 'Continue'
                    };
                    rcnotify.openPrompt(promptOptions, () => {
                        this.repriceProcess(component,event,helper,rcnotify);
                    });
                }
                return val;
            }
        });
        $A.enqueueAction(action3);
    },
    //validate Func
    validate:function(isBillingOpportunity) {
        const errors = [];

        if (!isBillingOpportunity) {
            errors.push({
                theme: 'info',
                header: 'Not Billing Opportunity',
                details: 'You may execute sync with NGBS only for billing opportunities'
            });
        }

        return errors;
    },

    //handleResults
    handleResults:function(rawResults,rcnotify) {
        if (!rawResults) {
            return;
        }

        const results = JSON.parse(rawResults);

        if (!results.action) {
            for (let result of results) {
                console.log('Publishing error messages');
                const toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "type": result.status,
                    "title":result.header,
                    "message": result.message,
                    "mode":'dismissible'
                });
                toastEvent.fire();
            }
        }
    },
//isShowPopUpWindow
    isShowPopUpWindow:function(rawResults) {
        if (!rawResults) {
            return;
        }
        let isShowPopUp = rawResults.some(result => {
            return result.status == 'success' && result.action == 'reprice';
        });
        return isShowPopUp;
    },

    //repriceProcess
    repriceProcess:function(component,event,helper,rcnotify) {
        this.startSync();
        var action=component.get("c.priceChange");
        var recId = component.get("v.recordId");
        action.setParams({
            "recordId":recId
        });
        action.setCallback(this, function(response){
            var state = response.getState();
            console.log('State'+state);
            if(state=='SUCCESS'){
                var res= JSON.stringify(response.getReturnValue());
                console.log('result'+res);
                try{
                    this.handleResults(res,rcnotify);
                }
                catch(e)
                {
                    this.handleException(e);
                }
                finally
                {
                    this.handleFinally(rcnotify)
                }

            }
        });
        $A.enqueueAction(action);
    },
    //startSync
    startSync:function() {
        this.rcnotify.removeAllToasts();
        rcnotify.showSpinner();
    },
//openModal
    openModal:function(opportunityId,rcnotify) {
        console.log('opp'+opportunityId);
        rcnotify.openModal({
            type: 'iframe',
            size: 'large',
            height: '500px',
            header: '',
            url: '/apex/syncWithNGBS?id=' + opportunityId,
            taglines: 'description...'
        });
    },


    //handleException
    handleException:function(e) {
        if (!e) {
            return;
        }

        this.rcnotify.addToast({
            theme: 'error',
            header: 'Unexpected error occurred',
            details: 'Please contact Administrator'
        });
    },
    //handleFinally
    handleFinally:function(rcnotify) {
        rcnotify.hideSpinner();
    },
})