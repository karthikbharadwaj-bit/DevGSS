({
	doInit : function(component, event, helper) {
		var qd = {};
        //Parse URI string
        if (location.href.split("#")[1]) {
            location.href.split("#")[1].split("&").forEach(function(item) {
                var s = item.split("="),
                    k = s[0],
                    v = s[1] && decodeURIComponent(s[1]);
                (k in qd) ? qd[k].push(v) : qd[k] = [v]
            });
            if (qd.launchURL) {
                window.history.pushState(
                    {},
                    "",
                    window.location.protocol + '//' + window.location.host + window.location.pathname
                );
                window.document.getElementById("learningCustomFrame").src = qd.launchURL[0];
            }
        }
	}
})