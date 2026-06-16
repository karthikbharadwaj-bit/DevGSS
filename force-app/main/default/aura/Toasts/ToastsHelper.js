({
    /**
     * Create Toast and add it to markup
     */
    createToast: function(component, toastParams) {
        $A.createComponent(
            "c:Toast", {
                theme: toastParams.theme,
                header: toastParams.header,
                details: this.getDetails(toastParams.details),
                timeout: toastParams.timeout,
                defaultTimeout: toastParams.defaultTimeout
            },
            function(newToast, status, errorMessage) {
                if (status === "SUCCESS") {
                    var body = component.get("v.body");
                    body.push(newToast);
                    component.set("v.body", body);
                } else {
                    console.error("Error: " + errorMessage);
                    // Show error message
                }
            }
        );
    },

    /**
      * @param details {(string|string[])}
      * @returns result {string[]}
      */
    getDetails: function(details) {
      var result = [details];
      if( Array.isArray(details) ) result = details;
      return result;
    }
})