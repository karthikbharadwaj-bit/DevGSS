({
    init : function(component) {
        const serverAction = component.get("c.checkDQExistFOROpp"),
            oppIdParam = component.get("v.oppId");
        serverAction.setParams({
            OppId: oppIdParam
        });
            
        serverAction.setCallback(this, function (response) {
            if (response.getState() == "SUCCESS") {
                var objDealQualificationWRAP = response.getReturnValue();
                if (objDealQualificationWRAP) {
                    component.set(  "v.objDealQualificationWrap",  objDealQualificationWRAP );
                    component.set( "v.DQApproverList", objDealQualificationWRAP.ApproverDetailList);
                }
            }
            if (response.getState()  === "ERROR") {
				alert(response.getError()[0].message);
			}

        });

        $A.enqueueAction(serverAction);
    }
})