({
  getDefaultSelectedRecord: function (component, event, getInputkeyWord) {
    var action = component.get("c.getSelectedRecord");
    var objectName = component.get("v.objectAPIName");
    action.setParams({
      'recordId': component.get("v.selectedRecordId"),
      'ObjectName': objectName,
        'isDQFromCPQ':component.get("v.isDQFromCPQ"),
'configuredProductId' : component.get("v.cpqConfiguredId")         
    });
    action.setCallback(this, function (response) {
      //$A.util.removeClass(component.find("mySpinner"), "slds-show");
      console.log('Success insrer>>>');
      var state = response.getState();
      console.log('state>>>', state);
        console.log('stateerrors>>>', response.getError());
      if (state === "SUCCESS") {
        console.log('Success insrer>>>', response.getReturnValue());
        component.set("v.selectedRecord", response.getReturnValue());
        var isProduct = false;
        if(response.getReturnValue()) {
            isProduct = response.getReturnValue().Id.startsWith('01t');
        } 
        component.set("v.isProduct",isProduct);
        var forclose = component.find("lookup-pill");
        $A.util.addClass(forclose, 'slds-show');
        $A.util.removeClass(forclose, 'slds-hide');

        var forclose = component.find("searchRes");
        $A.util.addClass(forclose, 'slds-is-close');
        $A.util.removeClass(forclose, 'slds-is-open');

        var lookUpTarget = component.find("lookupField");
        $A.util.addClass(lookUpTarget, 'slds-hide');
        $A.util.removeClass(lookUpTarget, 'slds-show');
      }
    });
    // enqueue the Action  
    $A.enqueueAction(action);


  },

  searchHelper: function (component, event, getInputkeyWord) {
      console.log('component.get("v.productFamily")>>',component.get("v.productFamily")); 
    // call the apex class method 
    var action = component.get("c.fetchLookUpValues");
    // set param to method  
    var objectName = component.get("v.objectAPIName");
    action.setParams({
      'searchKeyWord': getInputkeyWord,
      'ObjectName': objectName,
        'productFamily' : component.get("v.productFamily"),
        'packageId' : component.get("v.packageId"),
        'isDQFromCPQ' : component.get("v.isDQFromCPQ"),
        'configuredProductId' : component.get("v.cpqConfiguredId")
    });
    // set a callBack    
    action.setCallback(this, function (response) {
      $A.util.removeClass(component.find("mySpinner"), "slds-show");
      var state = response.getState();
      if (state === "SUCCESS") {
        var storeResponse = response.getReturnValue();
        // if storeResponse size is equal 0 ,display No Result Found... message on screen.                }
        if (storeResponse.length == 0) {
          component.set("v.Message", 'No Result Found...');
        } else {
          component.set("v.Message", '');
        }
        // set searchResult list with return value from server.
        component.set("v.listOfSearchRecords", storeResponse);
          console.log('storeResponse>>'+JSON.stringify(storeResponse));
      }

    });
    // enqueue the Action  
    $A.enqueueAction(action);

  },
})