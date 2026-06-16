import { track, api } from "lwc";
import BaseService from "c/lwcBaseService";
import getUserFullInfo from "@salesforce/apex/SupportCommunityUsers.getUserFullInfo";
import getCasesInfo from "@salesforce/apex/SupportCommunityUsers.getCasesInfo";
import { mockData } from "./mockData";

export default class ScTabsData extends BaseService {
    @api caseLink;
    @track firstInit = true;
    getUserInfo() {
        return new Promise(resolve => {
            BaseService.invokeServiceMethodWithoutParameters(getUserFullInfo)
                .then(res => res.userFullInfo)
                .then(res => resolve(res))
                .catch(error => console.error(error));
        });
    }
    getCases() {
        return new Promise(resolve => {
            BaseService.invokeServiceMethodWithoutParameters(getCasesInfo)
                .then(res => res.casesInfo)
                .then(res => resolve(res))
                .catch(error => console.error(error));
        });
    }
    async init() {
        if (window.app) {
            if (this.firstInit) {
                this.firstInit = false;
                const user = await this.getUserInfo();
                window.app.User = { user };
                if (window.app.hasUser() && window.app.hasContact()) {
                    window.app.Cases = await this.getCases();
                    window.app.setCasesLink(this.caseLink);
                    BaseService.pushEvent("changecases", { cases: window.app.Cases, isMock: false }, this);
                } else {
                    BaseService.pushEvent("changecases", { cases: mockData, isMock: true }, this);
                }
            }

            BaseService.pushEvent("changeuser", { user: window.app.User }, this);
        }
    }
    connectedCallback() {
        this.init();
    }

    constructor() {
        super();
        document.addEventListener("sc-app_contact", this.init.bind(this));
    }
}