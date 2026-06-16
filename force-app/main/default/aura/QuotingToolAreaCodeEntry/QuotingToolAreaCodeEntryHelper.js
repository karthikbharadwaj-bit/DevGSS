({
    deleteAreaCodeItem: function(component){

        component.getEvent('QuotingToolAreaCodeListEntryEvent').setParams({
            action: 'delete',
            params: {
                areaCodeItem:   component.get("v.areaCodeItem")
            }
        }).fire();

    },
    /**
     * Disable enable inputs
     */
    checkDisabling: function(component) {
        var Wizard = component.get('v.Wizard');
        var busy = component.get("v.busy");
        var state = component.get('v.state');
        var deleteButton = component.find('deleteButton');
        var deleteSpinner = component.find('deleteSpinner');
        var isItemDeleting = component.get('v.deletingAreaCodeItems').has(component.get("v.areaCodeItem.guid"));

        var quantityInputDisabled = false;
        var areaCodeInputDisabled = false;
        var deleteButtonHidden = false;

        var deleteSpinnerHidden = !isItemDeleting;

        if (!state ||
            Wizard.opportunity.isClosed ||
            state.isAgreement ||
            state.isQuoteOnApproval ||
            // Pro Serv User look at Sales quote
            (!state.isProServQuote && state.isUserProServ) ||
            // CC Pro Serv User look at Sales quote
            (!state.isCCProServQuote && state.isUserCCProServ) ||
            // Cart or item is busy
            busy ||
            isItemDeleting) {
            quantityInputDisabled = true;
            areaCodeInputDisabled = true;
            deleteButtonHidden = true;
        }
        component.find('quantity').set('v.disabled',quantityInputDisabled);
        component.find('areaCode').set('v.disabled',areaCodeInputDisabled);


        if (deleteButtonHidden){
            $A.util.addClass(deleteButton, "slds-hide");
        } else {
            $A.util.removeClass(deleteButton, "slds-hide");
        }

        if (deleteSpinnerHidden){
            $A.util.addClass(deleteSpinner, "slds-hide");
        } else {
            $A.util.removeClass(deleteSpinner, "slds-hide");
        }
    },
    /**
     * Validate Area Code field
     * 1) Area Code is required
     */
    validateAreaCode: function(component, suppressIfEmpty){
        var areaCode = component.get('v.areaCodeItem.Area_Code__c');
        var areaCodeCol = component.find('areaCodeCol');

        if (!areaCode && !suppressIfEmpty){
            $A.util.addClass(areaCodeCol, "slds-has-error");
        } else {
            $A.util.removeClass(areaCodeCol, "slds-has-error");
        }
    },
    /**
     * Validate Quantity field
     * 1) Quantity should be at least 1
     */
    normaliseQuantity: function(component){
        var areaCodeItem = component.get('v.areaCodeItem');
        if (areaCodeItem){
            var qty = Number(areaCodeItem.Quantity__c);
            if (!qty || qty < 1){
                component.set('v.areaCodeItem.Quantity__c',1);
            }
        }
    },
    calcColumns: function(component){
      var columns = component.get('v.columns');
      var group = component.get('v.group');
      var offset = 0;

      var areaCodeCol = component.find('areaCodeCol').getElement();

      if(group.name) offset = -32;

      var areaCodeSize = columns.nameCol + offset + columns.planCol + columns.iconsCol;

      if(areaCodeCol) {
        areaCodeCol.style.width = areaCodeSize + 'px';
        // areaCodeCol.style.minWidth = areaCodeSize + 'px';
        // areaCodeCol.style.maxWidth = areaCodeSize + 'px';
      }
    },
    /**
     * Pass additional parameters to lookup to implement filtering B-2189
     */
    setLookupParams: function(component){
        var qli = component.get('v.qli');
        var activePriceBookEntry = component.get('v.activePriceBookEntry');
        var params = {
            family: qli.Product2.Family,
            feature: qli.Product2.Feature__c ? String(qli.Product2.Feature__c) : null,
            brand: activePriceBookEntry.Pricebook2.Brand__r.Name
        };
        component.find('areaCode').set('v.params',params);
    }
})