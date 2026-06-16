import { LightningElement, api, track } from "lwc";
import getTopicData from "@salesforce/apex/TopicRatingController.getTopicData";
import { ScAdminTopic as Topic } from "c/scAdminTopic";
import SC_viewAllTopics from "@salesforce/label/c.SC_viewAllTopics";
export default class ScTrendingTopics extends LightningElement {
    @api title;
    @api newTab;
    @api viewAll;

    @track lang = "en_US";
    @track rowCount = 5;
    @track coveo = [];
    @track custom = [];
    @track hasRealLanguage = false;

    domain = "";
    label = {
        SC_viewAllTopics
    };

    get target() {
        return this.newTab ? "_blank" : "_self";
    }
    get coveoFiltered() {
        // Remove from Coveo list all custom topics
        const ids = this.custom.map(item => item.id);
        return this.coveo.filter(item => ids.indexOf(item.id) < 0);
    }

    getTopics() {
        getTopicData({ langCode: this.lang, tmp: 0 })
            .then(result => {
                if (result) {
                    const res = JSON.parse(JSON.stringify(result));
                    if (res.data) {
                        this.loading = false;
                        if (res.data.listSize) {
                            this.rowCount = res.data.listSize;
                        }
                        if (res.data.coveoTopics) {
                            this.coveo = res.data.coveoTopics.map(item => new Topic(item, false));
                        }
                        if (res.data.fixedTopics) {
                            this.custom = res.data.fixedTopics.map(item => new Topic(item, true));
                        }
                    }
                }
                this.error = undefined;
            })
            .catch(error => {
                console.warn(error);
                this.error = error;
            });
    }
    get outList() {
        // Main func for forming a list of topics
        let out = [];
        let j = 0;
        for (let i = 1; i <= this.rowCount; i++) {
            const slotItem = this.custom.filter(item => item.position === i);
            if (slotItem.length > 0) {
                out.push(slotItem[0]);
            } else {
                if (this.coveoFiltered.length > j) {
                    out.push(this.coveoFiltered[j]);
                    j++;
                }
            }
        }
        out = out.map((item, index) => {
            try {
            } catch (e) {
                console.warn(out, index, e);
                return item;
            }
            item.position = item.isCustom ? item.position : index + 1;
            item.cName = { defaultClass: "slds-item" };
            return item;
        });
        return out;
    }
    onLanguageChanged() {
        if (window.app && window.app.language) {
            this.lang = window.app.language;
            this.hasRealLanguage = true;
            this.getTopics();
        }
    }
    constructor() {
        super();
        if (window.app && window.app.language) {
            this.lang = window.app.language;
            this.hasRealLanguage = true;
        } else {
            window.addEventListener("sc-app_language", this.onLanguageChanged.bind(this));
        }
    }
    connectedCallback() {
        if (this.hasRealLanguage) {
            this.getTopics();
        }
    }
}