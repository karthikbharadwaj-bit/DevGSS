/**
 * Created on 11.04.2019
 */

import { LightningElement } from "lwc";

export default class ScLogin extends LightningElement {
    initTimeout;
    login_window;
    startURL;
    get isRedirect() {
        return !!(this.startURL);
    }
    getUrlParams (url) {
        if (typeof url == 'undefined') {
            url = window.location.search
        }
        url = url.split('#')[0];
        var urlParams = {};
        var queryString = url.split('?')[1];
        if (!queryString) {
            if (url.search('=') !== false) {
                queryString = url
            }
        }
        if (queryString) {
            var keyValuePairs = queryString.split('&')
            for (var i = 0; i < keyValuePairs.length; i++) {
                var keyValuePair = keyValuePairs[i].split('=');
                var paramName = keyValuePair[0];
                var paramValue = keyValuePair[1] || '';
                urlParams[paramName] = decodeURIComponent(paramValue.replace(/\+/g, ' '));
            }
        }
        return urlParams
    }
    PopupCenter(url, w, h) {
        // Fixes dual-screen position                         Most browsers      Firefox
        var dualScreenLeft = window.screenLeft != undefined ? window.screenLeft : window.screenX;
        var dualScreenTop = window.screenTop != undefined ? window.screenTop : window.screenY;

        var width = window.innerWidth ? window.innerWidth : document.documentElement.clientWidth ? document.documentElement.clientWidth : screen.width;
        var height = window.innerHeight ? window.innerHeight : document.documentElement.clientHeight ? document.documentElement.clientHeight : screen.height;

        var systemZoom = width / window.screen.availWidth;
        var left = (width - w) / 2 / systemZoom + dualScreenLeft
        var top = (height - h) / 2 / systemZoom + dualScreenTop
        var newWindow = window.open(url, "_blank", 'scrollbars=no,location=no,resizable=no, width=' + w / systemZoom + ', height=' + h / systemZoom + ', top=' + top + ', left=' + left);
        if (window.focus) newWindow.focus();
        return newWindow;
    }
    openLogin() {
        if(typeof (this.login_window) == 'undefined' || this.login_window.closed) {
            const loginUrl = '/support/services/auth/sso/RC_IdentityConnect';
            const mainPath = document.location.pathname.split('/s/')[0];
            this.login_window = this.PopupCenter(loginUrl + "?startURL=" + encodeURIComponent(mainPath + "/SupportCommunityLogin"), 500, 600);
            var this_ = this;
            this.initTimeout = setInterval(function() {
                this_.login_window.postMessage("sc_login__init", document.location.origin);
            }, 500);
        } else {
            this.login_window.focus();
        }
    }
    goHome() {
        document.location.href = '../';
    }
    connectedCallback() {
        this.startURL = this.getUrlParams().startURL || null;
        var this_ = this;
        window.addEventListener("message", function(event) {
            if (event.origin !== document.location.origin) return;
            if (event.data === "sc_login__init") clearInterval(this_.initTimeout);
            else if (event.data === "sc_login_final__good" || 'sc_login_final__partial') {
                this_.login_window.close();
                if(this_.startURL)
                    document.location.href = this_.startURL;
                else
                    document.location.href = '../';
            } else if (event.data === "sc_login_final__bad") {
                this_.login_window.close();
            }
        });
    }

}