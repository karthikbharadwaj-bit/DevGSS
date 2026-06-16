import { LightningElement, track, api } from "lwc";
import searchTopicsByTitle from "@salesforce/apex/TopicRatingController.searchTopicsByTitle";
import { ScAdminTopic as Topic } from "c/scAdminTopic";

export default class ScAdminSearch extends LightningElement {
    @api highlight;
    @api custom;
    @api lang;
    @api domain;

    @track queryValue;
    @track queryTerm;
    @track searchResults = [];
    @track loading = false;
    @track hasError = false;

    minLength = 3;
    minLenMessage = `Please write more then ${this.minLength} characters`;
    toastEventName = "ShowToastEvent";
    errorMessage = "Something goes wrong!";

    get customIds() {
        return this.custom.map(item => item.id);
    }
    get results() {
        const ids = this.customIds;
        return this.searchResults.map(item => {
            item.highlight = this.highlight;
            item.isCustom = ids.indexOf(item.id) >= 0;
            item.cName = { defaultClass: "slds-item" };
            return item;
        });
    }
    get resultsLoaded() {
        return this.queryTerm && !this.loading;
    }
    get wrapperClass() {
        return `input-wrapper${this.hasError ? " error" : ""}`;
    }
    get inputClass() {
        return `${this.hasError ? "slds-has-error" : ""}`;
    }

    pushEvent(name, detail, target) {
        target = target || this;
        const cEvent = new CustomEvent(name, {
            detail
        });
        target.dispatchEvent(cEvent);
    }
    getSearchData(text) {
        this.hasError = false;
        this.loading = true;
        searchTopicsByTitle({ request: JSON.stringify({ titlePart: text, lang: this.lang }) })
            .then(result => {
                this.loading = false;
                if (result.data && result.status === "success") {
                    if (result.data.topics) {
                        this.searchResults = result.data.topics.map(item => new Topic(item, true, this.domain));
                    } else {
                        this.searchResults = [];
                    }
                } else {
                    throw new Error(result.messages.map(item => item.message).join("\n"));
                }
            })
            .catch(error => {
                this.loading = false;
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

    handleKeyUp(evt) {
        if (evt.keyCode === 13) {
            const el = evt.target;
            const query = el.value.trim();
            this.queryValue = query;
            if (query.length >= this.minLength) {
                this.queryTerm = query;
                this.getSearchData(query);
                this.hasError = false;
            } else {
                this.queryTerm = null;
                this.hasError = true;
            }
        }
    }
    handleClear(evt) {
        if (evt.target.value === "") {
            this.queryTerm = null;
        }
    }

    dragStart(evt) {
        const id = evt.target.getAttribute("data-id");
        const item = this.searchResults.find(item => item.isEqualId(id));
        evt.dataTransfer.setData("Text", item.toJSON());
        this.dispatchEvent(new CustomEvent("cdragstart"));
    }
    dragEnd() {
        this.dispatchEvent(new CustomEvent("cdragend"));
    }

    highlightStart(evt) {
        const id = evt.currentTarget.getAttribute("data-id");
        const searchEvent = new CustomEvent("highlightstart", {
            detail: id
        });
        this.dispatchEvent(searchEvent);
    }
    highlightEnd() {
        this.dispatchEvent(new CustomEvent("highlightend"));
    }
    onSearchHandled(evt) {
        this.queryValue = evt.detail;
        this.queryTerm = evt.detail;
        this.getSearchData(evt.detail);
    }

    constructor() {
        super();
        window.addEventListener("sc-search-it", this.onSearchHandled.bind(this));
    }
}