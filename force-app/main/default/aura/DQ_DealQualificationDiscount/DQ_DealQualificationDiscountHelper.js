({
	createObjectData: function(component, event) {
        // get the DQDicountList from component and add(push) New Object to List  
        var RowItemList = component.get("v.DQDiscountSalesQuoteList");
        RowItemList.push({
            'sobjectType': 'DQ_Deal_Qualification_Discounts__c',
            'Discount_Type__c': '',
            'Product_Category__c': '',
            'Product_Sub_Categories__c': ''
        });
        // set the updated list to attribute (DQDicountList) again    
        component.set("v.DQDiscountSalesQuoteList", RowItemList);
    },
    openSearchProd : function(component, event, helper) {
        component.set("v.serarchCmpOpen",true);
    },
    removeRow: function(component, event, helper,objDQDiscountRec,index) {
        var serverAction = component.get("c.deleteDQDiscountRecord");
        serverAction.setParams({
            DQDiscoutRec : objDQDiscountRec
        });
        
        serverAction.setCallback(this, function(response){
            console.log(response.getState());
            if(response.getState() == "SUCCESS"){
                var AllRowsList = component.get("v.DQDiscountList");
        		var DQDiscountRec = AllRowsList[index];
        		AllRowsList.splice(index, 1);
            	// set the DQDiscountList after remove selected row element  
            	component.set("v.DQDiscountList", AllRowsList);
                var p = component.get("v.parent");
    			p.refreshApproverList();
  			}
        });
        $A.enqueueAction(serverAction);
 
    },
    
    removeRowCheck: function(component, event, helper,isFromContactCenter) {
        // get the selected row Index for delete, from Lightning Event Attribute  
        var index = event.target.dataset.indexvardel;
        // get the all List (DQDiscountList attribute) and remove the Object Element Using splice method    
        var AllRowsList;
        if(isFromContactCenter) 
        	AllRowsList = component.get("v.DQDiscountContactCenterList");
        else {
            AllRowsList = component.get("v.DQDiscountSalesQuoteList");
        }
        var DQDiscountRec = AllRowsList[index];
        if(DQDiscountRec.Id) {
            helper.removeRow(component, event, helper,DQDiscountRec,index);
        }
        else{
            AllRowsList.splice(index, 1);
            // set the DQDiscountList after remove selected row element
            if(isFromContactCenter)  
            	component.set("v.DQDiscountContactCenterList", AllRowsList);
            else
                component.set("v.DQDiscountSalesQuoteList", AllRowsList);
        }
    },
})