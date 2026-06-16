({
    doInit: function doInit(cmp, event, helper) {
        cmp.set("v.columns", [
            {
                label: $A.get("$Label.c.SC_number"),
                fieldName: "caseLink",
                type: "url",
                initialWidth: 100,
                typeAttributes: { label: { fieldName: "caseNumber" } }
            },
            { label: $A.get("$Label.c.SC_subject"), fieldName: "subject", type: "text" },
            { label: $A.get("$Label.c.SC_status"), fieldName: "status", type: "text", initialWidth: 110 }
        ]);
    },
});