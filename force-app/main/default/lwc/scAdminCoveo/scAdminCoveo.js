import { LightningElement, api } from "lwc";
import { ScAdminTopic as Topic } from "c/scAdminTopic";

export default class ScAdminCoveo extends LightningElement {
    @api coveo = [];
    @api highlight;

    get items() {
        return this.coveo.map(item => {
            item.highlight = this.highlight;
            item.cName = { defaultClass: "slds-item" };
            return item;
        });
    }

    highlightStart(evt) {
        const id = evt.currentTarget.getAttribute("data-id");
        const highlightEvent = new CustomEvent("highlightstart", {
            detail: id
        });
        this.dispatchEvent(highlightEvent);
    }
    highlightEnd() {
        this.dispatchEvent(new CustomEvent("highlightend"));
    }
    searchIt(evt) {
        // Send event with item name to search component
        evt.preventDefault();
        const id = evt.currentTarget.getAttribute("data-id");
        const item = this.coveo.find(item => item.id === id);
        if (item) {
            const name = item.name;
            const searchEvent = new CustomEvent("sc-search-it", {
                detail: name
            });
            window.dispatchEvent(searchEvent);
        }
    }
}