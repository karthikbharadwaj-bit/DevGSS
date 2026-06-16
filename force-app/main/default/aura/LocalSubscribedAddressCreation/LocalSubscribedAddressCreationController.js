({
    initComponent : function(component, event, helper){
        var pageRef = component.get("v.pageReference");
        var base64Context = pageRef.state.inContextOfRef;

        // Remove 1.
        if (base64Context.startsWith("1\.")) {
            base64Context = base64Context.substring(2);
        }
        var addressableContext = JSON.parse(window.atob(base64Context));
        component.set("v.approvalRecordId", addressableContext.attributes.recordId);
    }
});