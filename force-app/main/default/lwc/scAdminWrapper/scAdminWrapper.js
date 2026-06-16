import { LightningElement, track } from "lwc";
import { ScAdminTopic as Topic } from "c/scAdminTopic";
import getTopicData from "@salesforce/apex/TopicRatingController.getTopicData";
import saveTopicData from "@salesforce/apex/TopicRatingController.saveTopicData";

export default class ScAdminWrapper extends LightningElement {
    @track rowCount = 5; // Rows count
    @track changed = false; // Change marker for Save / Cancel buttons
    @track coveo = []; // List of topics from Coveo
    @track custom = []; // List of handmade topics
    @track highlight = null; // Highlight marker (finder topic in all cols)
    @track drag = false; // Drag marker for highlight slots position
    @track lang = "en_US"; // Language of trending
    @track loading = true; // Load marker
    @track tmp = {}; // Temp variable for refresh cache of Apex
    @track domain = ""; // Link to support community of current language

    errorMessage = "Something goes wrong!";
    toastEventName = "ShowToastEvent";

    get curTmp() {
        return this.tmp[this.lang] || 0;
    }

    pushEvent(name, detail, target) {
        target = target || this;
        const cEvent = new CustomEvent(name, {
            detail
        });
        target.dispatchEvent(cEvent);
    }
    addTmp() {
        this.tmp[this.lang] = this.curTmp + 1;
    }
    getTopics() {
        this.loading = true;
        getTopicData({ langCode: this.lang, tmp: this.curTmp })
            .then(result => {
                if (result.data && result.status === "success") {
                    this.loading = false;
                    if (result.data.listSize) {
                        this.rowCount = result.data.listSize;
                        this.originRowCount = this.rowCount;
                    }
                    this.domain = result.data.domain || "";
                    if (result.data.coveoTopics) {
                        this.coveo = result.data.coveoTopics.map(item => new Topic(item, false, this.domain));
                    }
                    if (result.data.fixedTopics) {
                        this.custom = result.data.fixedTopics.map(item => new Topic(item, true, this.domain));
                        this.originCustom = this.custom;
                    }
                } else {
                    throw new Error(result.messages.map(item => item.message).join("\n"));
                }
            })
            .catch(error => {
                console.error(error);
                this.pushEvent(
                    this.toastEventName,
                    {
                        type: "error",
                        title: this.errorMessage,
                        message: error.message
                    },
                    window
                );
            });
    }
    saveTopics() {
        this.loading = true;
        saveTopicData({
            request: JSON.stringify({
                langCode: this.lang,
                listSize: this.rowCount,
                topics: this.custom.map(item => item.toApex())
            })
        })
            .then(result => {
                this.loading = false;
                if (result.status === "success") {
                    this.originRowCount = this.rowCount;
                    this.originCustom = this.custom;
                    this.changed = false;
                    this.addTmp();
                    this.pushEvent(this.toastEventName, { type: "success", title: "Saved successfully!" }, window);
                } else {
                    throw new Error(result.messages.map(item => item.message).join("\n"));
                }
            })
            .catch(error => {
                console.error(error);
                this.pushEvent(
                    this.toastEventName,
                    {
                        type: "error",
                        title: this.errorMessage,
                        message: error.message
                    },
                    window
                );
                this.loading = false;
            });
    }
    changeLang(event) {
        this.lang = event.detail;
        this.getTopics();
        this.pushEvent("sc-search-it", name, window);;
    }
    onCancel() {
        this.custom = this.originCustom.slice(0);
        this.rowCount = this.originRowCount;
        this.changed = false;
    }
    onReset() {
        this.changed = true;
        this.custom = [];
    }
    changeOut(event) {
        this.changed = true;
        const buf = JSON.parse(event.detail);
        this.custom = buf.map(item => new Topic(JSON.parse(item), true, this.domain));
    }
    changeRow(event) {
        this.changed = true;
        this.rowCount = event.detail;
        this.custom = this.custom.filter(item => item.position <= this.rowCount);
    }

    connectedCallback() {
        this.getTopics();
    }
    /*---------- Highlight logic ----------*/
    highlightStart(evt) {
        this.highlight = evt.detail;
    }
    highlightEnd() {
        this.highlight = null;
    }
    /*------- Drag and Drop logic ---------*/
    dragStart() {
        this.drag = true;
    }
    dragEnd() {
        this.drag = false;
    }
}