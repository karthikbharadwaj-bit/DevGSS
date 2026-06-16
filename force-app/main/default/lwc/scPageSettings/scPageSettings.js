import { api } from "lwc";
import { loadScript, loadStyle } from "lightning/platformResourceLoader";
import userFiles from "@salesforce/resourceUrl/scUserFiles";
import BaseService from "c/lwcBaseService";
export default class ScPageSettings extends BaseService {
    @api styleName;
    @api scriptName;
    @api unloadScriptName;
    @api showSnapIns;
    pushSettings() {
        const showSnapIns = this.showSnapIns;
        BaseService.pushEvent("scPageSettings", { showSnapIns }, window);
    }
    connectedCallback() {
        this.pushSettings();
    }
    disconnectedCallback() {
        if (this.styleName)
            try {
                document.head.querySelector('link[href="' + userFiles + "/" + this.styleName + ".css" + '"]').remove();
            } catch (e) {
                console.error(e);
            }
        if (this.scriptName)
            try {
                document.head
                    .querySelector('script[data-locker-src="' + userFiles + "/" + this.scriptName + ".js" + '"]')
                    .remove();
            } catch (e) {
                console.error(e);
            }
        if (this.unloadScriptName) {
            loadScript(this, userFiles + "/" + this.unloadScriptName + ".js")
                .then(() => {})
                .catch(error => {
                    console.error(error);
                });
        }
    }
    renderedCallback() {
        if (this.hasRendered) return;
        this.hasRendered = true;
        Promise.all([
            this.scriptName ? loadScript(this, userFiles + "/" + this.scriptName + ".js") : null,
            this.styleName ? loadStyle(this, userFiles + "/" + this.styleName + ".css") : null,
        ])
            .then(() => {})
            .catch(error => {
                console.error(error);
            });
    }
    constructor() {
        super();
        window.addEventListener("sc-app_init", this.pushSettings.bind(this) )
    }
}