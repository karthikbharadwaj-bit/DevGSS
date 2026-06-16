import { LightningElement, api, track } from "lwc";
export default class ScLoginButton extends LightningElement {
    @api hasUser = false;
    @api loginUrl;
    @track loginWindow;
    @track initTimeout;
    @track
    labels = {
        login: "Login",
        logout: "Log out",
    };
    loginParam = "login";
    logoutParam = "logout";
    eventsName = {
        message: "message",
        doLogin: "scLogin",
        popup: {
            init: "sc_login__init",
            good: "sc_login__good",
            bad: "sc_login__bad",
            partial: "sc_login_final__partial",
        },
    };
    get loginOrigin() {
        return this.loginUrl.substr(0, this.loginUrl.replace("://", ":||").indexOf("/")) || document.location.origin;
    }
    get isIE() {
        return window.navigator.userAgent.indexOf("MSIE ") > 0 || !!navigator.userAgent.match(/Trident.*rv\:11\./);
    }
    get icon() {
        return this.hasUser ? "utility:logout" : "utility:lock";
    }
    get label() {
        return this.hasUser ? this.labels.logout : this.labels.login;
    }
    get mainPath() {
        return window.location.pathname.split("/s/")[0];
    }
    removeFromHash(param) {
        return window.location.hash.replace(param + "&", "").replace(param, "");
    }
    handleClick() {
        if (this.hasUser) {
            this.doLogout();
        }
        else {
            this.doLogin();
        }
    }
    popupCenter(url, w, h) {
        const dualScreenLeft = window.screenLeft || window.screenX;
        const dualScreenTop = window.screenTop || window.screenY;

        var width = window.innerWidth
            ? window.innerWidth
            : document.documentElement.clientWidth
            ? document.documentElement.clientWidth
            : screen.width;
        var height = window.innerHeight
            ? window.innerHeight
            : document.documentElement.clientHeight
            ? document.documentElement.clientHeight
            : screen.height;

        var systemZoom = width / window.screen.availWidth;
        var left = (width - w) / 2 / systemZoom + dualScreenLeft;
        var top = (height - h) / 2 / systemZoom + dualScreenTop;
        var newWindow = window.open(
            url,
            "_blank",
            "scrollbars=no,location=no,resizable=no, width=" +
                w / systemZoom +
                ", height=" +
                h / systemZoom +
                ", top=" +
                top +
                ", left=" +
                left
        );
        if (window.focus) newWindow.focus();
        return newWindow;
    }
    doLogout() {
        const curLoc = document.location.href;

        const currentHash = this.removeFromHash(this.logoutParam);
        const logoutHash = this.logoutParam + (currentHash.length > 1 ? "&" + currentHash.substring(1) : "");
        const url = this.mainPath + "/secur/logout.jsp?retUrl=" + encodeURIComponent(curLoc);
        if(this.isIE) {
            document.location.href = url + "#" + logoutHash;
        } else {
            jQuery.get(url, () => {

                document.location.hash = logoutHash;
                document.location.reload();
            });
        }
    }
    doLogin() {
        if(!this.isIE) {
            window.location.hash = this.removeFromHash(this.loginParam);
            if (!this.loginWindow || this.loginWindow.closed) {
                this.loginWindow = this.popupCenter(
                    this.loginUrl + "?startURL=" + encodeURIComponent(this.mainPath + "/SupportCommunityLogin"),
                    500,
                    600
                );
                this.initTimeout = setInterval(() => {
                    this.loginWindow.postMessage(this.eventsName.popup.init, this.loginOrigin);
                }, 500);
            }
            this.loginWindow.focus();
        } else {
            this.redirectToLogin();
        }
    }
    onMessageReceived({ origin, data }) {
        if (origin !== this.loginOrigin) {
            return;
        }
        if (data === this.eventsName.popup.good || data === this.eventsName.popup.partial) {
            this.loginWindow.close();
            document.location.reload();
        } else if (data === this.eventsName.popup.bad) {
            this.loginWindow.close();
            clearInterval(this.initTimeout);
        }
    }
    redirectToLogin() {
        window.location.href =
            this.loginUrl +
            "?startURL=" +
            encodeURIComponent(this.mainPath + "/SupportCommunityLogin?url=" +
                encodeURIComponent(window.location.href));
    }
    renderedCallback() {
        const hash = window.location.hash.substring(1);
        const hashLogin = hash === this.loginParam || hash.indexOf(this.loginParam + "&") === 0;
        if (hashLogin) {
            window.location.hash = this.removeFromHash(this.loginParam);
            if (!this.hasUser) {
               this.redirectToLogin();
            }
        }
    }
    constructor() {
        super();
        window.addEventListener(this.eventsName.message, this.onMessageReceived.bind(this));
        window.addEventListener(this.eventsName.doLogin, this.handleClick.bind(this));
    }
}