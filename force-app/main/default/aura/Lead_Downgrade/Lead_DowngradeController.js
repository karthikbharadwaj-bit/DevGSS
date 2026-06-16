({
	doInit : function(component, event, helper) {
		var recId = component.get("v.recordId");
         var win = window.open("/apex/DowngradePopUp?id=" + recId, 'Popup','height=600,width=600,left=100,top=100,toolbar=0,location=0,directories=0, status=0,menubar=0,centerscreen=1,scrollbars=0');
                    	var timer = setInterval(function () {
                            if (win.closed) {
                            	clearInterval(timer);
                            	window.location.reload(); // Refresh the parent page
                            }
                        }, 1000);
	}
})