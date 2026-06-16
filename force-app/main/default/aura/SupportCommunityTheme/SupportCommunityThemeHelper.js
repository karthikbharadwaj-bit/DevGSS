({
    getPageSettings: function(cmp) {
        window.addEventListener("scPageSettings",({detail})=>{
            const showSnapIns = detail.showSnapIns;
            cmp.set("v.showSnapIns",showSnapIns);
            if(showSnapIns) {
                cmp.set("v.snapInsInit", true)
            }
        });
    },
    getInfo: function getInfo(cmp) {
        var _this = this;
        _this.send_event("jquery");
        RC.salesforce
            .request(cmp, "c.getUserInfo", {})
            .then(
                $A.getCallback(function(res) {
                    window.app.User = res;
                    cmp.set("v.hasUser", !!res.user);
                })
            )
            .catch(
                $A.getCallback(function(error) {
                    window.app.User = null;
                    cmp.set("v.hasUser", false);
                })
            ).finally( $A.getCallback(function(){
            _this.send_event("init");
            cmp.set("v.preloader", false);
        }));
    },
    pushEvent: function pushEvent(name) {
        window.dispatchEvent(new CustomEvent(name));
    },
    getLanguage: function() {
        const html = document.getElementsByTagName("html");
        return html.length > 0 ? html[0].getAttribute("lang") : "en-US";
    },
    send_event: function send_event(param) {
        var updateEvent = $A.get("e.c:SupportCommunityUserEvent");
        updateEvent.setParams({ param: param });
        updateEvent.fire();
    },
    hamburgerClick: function hamburgerClick() {
        var nav = jQuery(".cSupportCommunityTheme");
        if (nav.hasClass("opened-menu")) {
            nav.addClass("closed-menu");
        } else {
            nav.removeClass("closed-menu");
        }
        nav.toggleClass("opened-menu");
    },
    touchstartCoordX: null,
    touchendCoordX: null,
    touchstartCoordY: null,
    touchendCoordY: null,
    bodyTouchstart: function bodyTouchstart(event) {
        var touchstartCoordX = event.changedTouches[0].clientX;
        var touchstartCoordY = event.changedTouches[0].clientY;
        if (
            window.matchMedia(
                "only screen and (min-width: 320px) and (max-width: 480px) and (orientation: portrait),\n" +
                    "only screen and (max-width: 820px) and (orientation: landscape)"
            ).matches
        ) {
            this.touchstartCoordX = touchstartCoordX;
            this.touchstartCoordY = touchstartCoordY;
        } else this.touchstartCoordX = null;
    },
    bodyTouchmove: function bodyTouchmove(event) {
        if (!jQuery(".cSupportCommunityTheme").hasClass("opened-menu")) {
            if (this.touchstartCoordX < 40) event.preventDefault();
        }
    },
    bodyTouchend: function bodyTouchend(event) {
        if (this.touchstartCoordX) {
            this.touchendCoordX = event.changedTouches[0].clientX;
            this.touchendCoordY = event.changedTouches[0].clientY;
            var direction = this.touchendCoordX < this.touchstartCoordX ? "left" : "right";
            var changeX = Math.abs(this.touchendCoordX - this.touchstartCoordX);
            var changeY = Math.abs(this.touchendCoordY - this.touchstartCoordY);
            var nav = jQuery(".cSupportCommunityTheme");
            if (changeX > 30 && changeY < 50) {
                if (direction === "right" && this.touchstartCoordX < 40 && !nav.hasClass("opened-menu")) {
                    nav.removeClass("closed-menu");
                    nav.addClass("opened-menu");
                } else if (direction === "left" && nav.hasClass("opened-menu")) {
                    nav.addClass("closed-menu");
                    nav.removeClass("opened-menu");
                }
            }
        }
    },
    swipeMenu: function swipeMenu() {
        var elMain = document.querySelector(".cSupportCommunityTheme");
        elMain.addEventListener("touchstart", this.bodyTouchstart, false);
        elMain.addEventListener("touchend", this.bodyTouchend, false);
    },
    getParam: function(key) {
        var val = new RegExp(key + "(?:=(.*?))?(?:[&#]|$)").exec(window.location.search.slice(1));
        return val === null ? null : typeof val[1] === "string" ? decodeURIComponent(val[1].replace(/\+/g, " ")) : "";
    },
    loadIcons: function(cmp) {
        if (navigator.userAgent.indexOf("MSIE") !== -1 || navigator.appVersion.indexOf("Trident/") > 0) {
            var _this = this;
            window.app.ie = true;
            var iconsURL = cmp.get("v.icons");
            var request = new XMLHttpRequest();
            request.onreadystatechange = function() {
                if (request.readyState === 4) {
                    if (request.status === 200) {
                        try {
                            var data = request.responseText;
                            var icons = {};
                            data = data.replace("</svg>", "").split("<symbol");
                            data = data.splice(1);
                            for (var i = 0; i < data.length; i++) {
                                data[i] = "<svg" + data[i].replace("</symbol>", "<svg>");
                                data[i] = data[i]
                                    .replace(/\r\n/g, "")
                                    .replace(/\n/g, "")
                                    .replace(/\t/g, "");
                                var id_start = data[i].indexOf('id="') + 4;
                                var id = data[i].substr(id_start);
                                var id_end = id.indexOf('"');
                                id = id.substr(0, id_end);
                                icons[id] = data[i];
                            }
                            window.app.icons = icons;
                            _this.send_event("icon");
                        } catch (e) {}
                    } else {
                    }
                }
            };
            request.open("Get", iconsURL);
            request.send();
        } else window.app.ie = false;
    },
});