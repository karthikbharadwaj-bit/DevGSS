import { LightningElement, api, track } from "lwc";
import { Crumb } from "./crumb";
const MAX_CRUMBS = 5;
export default class BreadcrumbsWithIteration extends LightningElement {
    @api bc_label_1 = "Home";
    @api bc_url_1 = "./";
    @api bc_label_2;
    @api bc_url_2;
    @api bc_label_3;
    @api bc_url_3;
    @api bc_label_4;
    @api bc_url_4;
    @api bc_label_5;
    @api bc_url_5;

    @track dynamic;

    get breadcrumbs() {
        const res = [];
        for (let i = 1; i <= MAX_CRUMBS; i++) {
            const label = this["bc_label_" + i];
            const url = this["bc_url_" + i];
            if(!!label) {
                res.push(new Crumb(i, label, url));
            } else {
                break;
            }
        }
        if(this.dynamic) {
            res.push(new Crumb(MAX_CRUMBS + 1, this.dynamic, null));
        }
        this.myBreadcrumbs = res;
        return res;
    }

    handleNavigateTo(event) {
        event.preventDefault();
        const name = event.target.name;
        if (this.myBreadcrumbs[name] && this.myBreadcrumbs[name].url) {
            window.location.assign(this.myBreadcrumbs[name].url);
        }
    }
    dynamicCrumbHandle({ detail }) {
        this.dynamic = detail.title;
    }
    constructor() {
        super();
        window.addEventListener("scBreadcrumbs", this.dynamicCrumbHandle.bind(this));
    }
}