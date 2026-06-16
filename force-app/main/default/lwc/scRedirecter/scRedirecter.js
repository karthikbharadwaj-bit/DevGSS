import { track, api } from "lwc";
import BaseService from "c/lwcBaseService";
import { NavigationMixin } from "lightning/navigation";
import signIn from "@salesforce/label/c.SC_SignIn";

export default class ScRedirecter extends NavigationMixin(BaseService) {
    @track isLogout = false;
    @api label;
    @api loginButton = false;
    @api isHTML = false;
    logoutParam = "logout";
    labels = {
        signIn: signIn || "Login",
    };
    eventsName = {
        doLogin: "scLogin",
    };
    clickLogin() {
        BaseService.pushEvent(this.eventsName.doLogin, null, window);
    }
    renderedCallback() {
        const contentElement = this.template.querySelector(".sc-redirecter__html");
        if (contentElement) {
            contentElement.innerHTML = this.label;
        }
    }
    get emptyLabel() {
        return !(!this.isHTML && this.label && this.label.length > 0);
    }
    navigateHome() {
        this[NavigationMixin.Navigate]({
            type: "standard__namedPage",
            attributes: {
                pageName: "home",
            },
        });
    }
    connectedCallback() {
        const hash = window.location.hash.substring(1);
        this.isLogout = hash === this.logoutParam || hash.indexOf(this.logoutParam + "&") === 0;
        if (this.isLogout) {
            this.navigateHome();
        }
    }
}