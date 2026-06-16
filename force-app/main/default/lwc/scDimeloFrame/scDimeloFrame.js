import { LightningElement, api, track } from "lwc";
import dimelo from "@salesforce/resourceUrl/scDimeloIframe";
export default class ScDimeloFrame extends LightningElement {
    @api modals = false;
    @api scripts = false;
    @api forms = false;
    @api sameOrigin = false;
    @api popups = false;
    @api geolocation = false;
    @api microphone = false;
    @api camera = false;
    @api showOnMobile = false;
    @api showOnTablet = false;
    @track isLoaded = false;
    @track options = {};
    @track permissions = {};

    get dimeloCls() {
        return (this.showOnMobile ? "": "mobile-hide") +
            (this.showOnTablet ? "": " tablet-hide");
    }
    get browserPermissions() {
        let perm = [];
        for (let key in this.permissions) {
            if (this.permissions[key]) {
                perm.push(key);
            }
        }
        return perm.join("; ");
    }
    get sandboxOptions() {
        let opt = [];
        for (let key in this.options) {
            if (this.options[key]) {
                opt.push(key);
            }
        }
        return opt.join(" ");
    }
    get url() {
        return `${dimelo}/index.html`;
    }
    connectedCallback() {
        this.options = {
            "allow-modals": this.modals,
            "allow-scripts": this.scripts,
            "allow-forms": this.forms,
            "allow-same-origin": this.sameOrigin,
            "allow-popups": this.popups,
        };
        this.permissions = {
            geolocation: this.geolocation,
            microphone: this.microphone,
            camera: this.camera,
        };
        this.isLoaded = true;
    }
}