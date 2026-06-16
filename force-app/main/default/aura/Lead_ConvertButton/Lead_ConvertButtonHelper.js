({
    convert : function(component,event,helper,cs,s,LeadId,OwnerId,rcnotify){
        console.log('Test return in convert ' + cs +'Owner Id is :'  + OwnerId);
        console.log('test 123' + !cs.includes(OwnerId));
		if(!cs.includes(OwnerId))
       {
      		console.log(OwnerId);
            var action = component.get("c.convert");
        	var recId  = component.get("v.recordId");
            action.setParams({
              "recordId":recId
           });

            action.setCallback(this, function(response){
                     var state = response.getState(); 
                	 console.log(response);
                	 console.log(state);
                     if(state= 'SUCCESS'){
                         const msg = response.getReturnValue();
                         if (!msg || 0 === msg.length) {
                            // var x =response.getReturnValue();
                            console.log(s);
                         	if(s == 'True'){
                		 		var device = $A.get("$Browser.formFactor");
                         		if(device=='DESKTOP'){
                                    
                                    window.open('/apex/convertLead?id='+ LeadId); 
                         		    
                             }else{
                              		var urlEvent = $A.get("e.force:navigateToURL");   
                         			urlEvent.setParams({
                                    'url': '/apex/convertLead?id='+ LeadId
                   	                 });
                        			urlEvent.fire();
                             	  }
            
                	          }  
								  window.open("/apex/convertLeadVFPage?id=".concat(LeadId, "&newmodel=1"));
        					  
                           } else {
                                 rcnotify.addToast({
          						 theme: 'error',
          						 header: 'Unable to Convert record',
          						 details: msg
                               });
                            }  
    				    }else{ 
             		 			rcnotify.hideSpinner();
        			 			rcnotify.addToast({
          			 			theme: 'error',
          			 			header: 'Unable to convert record',
         			 			details: err.faultstring
        					  });
        	         			return;   
                          }            
                    });
                    $A.enqueueAction(action);
			    
		     }
          	
		     else {
    				if (cs.includes(OwnerId)) {
      				    rcnotify.hideSpinner();
      				    rcnotify.addToast({
        			    theme: 'error',
        			    header: 'Unable to convert record',
        			    details: 'Please change ownership before converting'
      				 });
    			  }
             }
       }
})