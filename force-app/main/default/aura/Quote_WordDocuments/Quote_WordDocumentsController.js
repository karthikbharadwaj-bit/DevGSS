({
	openLink : function(component, event, helper) {
        var target = event.target;
        var attachmentId = target.getAttribute("data-row-index");
        window.open('/servlet/servlet.FileDownload?file='+attachmentId);
	}
})