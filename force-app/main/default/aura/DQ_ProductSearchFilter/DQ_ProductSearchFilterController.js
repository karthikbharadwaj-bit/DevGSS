({
	closeModel : function(component, event, helper) {
		component.set("v.serarchCmpOpen",false);
	},
    searchProd : function(component, event, helper) {
        component.set("v.Spinner",true);
        var serverAction = component.get("c.getProducts");
        serverAction.setParams({
            prodCatagoryName : component.get("v.ProductCategoryName"),
            ProdSubCatName : component.get("v.ProdSubCategoryName")
        });
        
        serverAction.setCallback(this, function(response){
            console.log(response.getState());
            if(response.getState() == "SUCCESS"){
                component.set("v.ProductList",response.getReturnValue());
                console.log("testing>>",response.getReturnValue());
                component.set("v.Spinner",false);
            }
        });
        $A.enqueueAction(serverAction);
        
    }
})