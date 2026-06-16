({
	handleEditionSelection : function(component, event, helper) {
        var objSelectedEdition = event.getParam("evtParam_ProductEdition");
        component.set("v.selectedEdition", objSelectedEdition);
	},
    
    loadEditionComponent : function(component, event, helper){
    	try{
        	var url = new URL(location.href);
            var id = url.searchParams.get('id');
    		var step = url.searchParams.get('step');
            console.log('id==' + id);
            if(step){
            	component.set("v.Step", step);    
                if(step == '3')
                    component.set("v.selectedCategory", "Service");
            }
            else if(id){
                component.set("v.Step", "2");
            }
        }
    	catch(e){
        	console.log('Error = ', e);        
        }
	},
    
    
})