import { LightningElement, api, track } from "lwc";
import { ScAdminTopic as Topic } from "c/scAdminTopic";

export default class ScAdminOut extends LightningElement {
    @api rows; // Rows count
    @api coveo = []; // List of topics from Coveo
    @api custom = []; // List of handmade topics
    @api drag = false; // Drag and drop marker
    @api highlight; // Highlight marker (finder topic in all cols)
    @api domain; // Link to support community of current language

    @track overIndex = 0; // Drop marker for highlight drop zone

    get coveoFiltered() {
        // Remove from Coveo list all custom topics
        const ids = this.custom.map(item => item.id);
        return this.coveo.filter(item => ids.indexOf(item.id) < 0);
    }
    get outList() {
        // Main func for forming a list of topics
        let out = [];
        let j = 0;
        for (let i = 1; i <= this.rows; i++) {
            const slotItem = this.custom.filter(item => item.position === i);
            if (slotItem.length > 0) {
                out.push(slotItem[0]);
            } else {
                if (this.coveoFiltered.length > j) {
                    out.push(this.coveoFiltered[j]);
                    j++;
                } else {
                    // Empty slots for drag and drop if Coveo results less rows count
                    out.push(new Topic({ name: `Empty slot #${i}`, id: i, isEmpty: true }));
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
            item.highlight = this.highlight;
            item.cName = { defaultClass: "slds-item", overIndex: this.overIndex };
            return item;
        });
        return out;
    }
    get listStyle() {
        return "slds-has-dividers_around-space slot-list" + (this.drag ? " drop" : "");
    }

    pushEvent(name, detail, target) {
        target = target || this;
        const cEvent = new CustomEvent(name, {
            detail
        });
        target.dispatchEvent(cEvent);
    }
    addCustom(data, pos) {
        // Add new handmade topic to out list
        let cBuf = this.custom.filter(item => item.position !== pos && item.id !== data.id);
        const newItem = new Topic(data, true, this.domain, pos);
        cBuf.push(newItem);
        this.custom = cBuf;
        this.handleChange();
    }
    handleChange() {
        // Transfer changes to wrapper
        this.pushEvent("outchange", JSON.stringify(this.custom.map(item => item.toJSON())));
    }
    clearSlot(ev) {
        const id = ev.target.getAttribute("data-id");
        this.custom = this.custom.filter(item => item.id !== id);
        this.handleChange();
    }
    /*------- Drag and Drop logic ---------*/
    dragEnter(ev) {
        ev.preventDefault();
        return true;
    }
    dragOver(ev) {
        ev.preventDefault();
        ev.stopPropagation();
        this.overIndex = ev.target.getAttribute("data-pos") * 1;
    }
    dragLeave(ev) {
        ev.preventDefault();
        ev.stopPropagation();
        this.overIndex = 0;
    }
    dragDrop(ev) {
        const data = JSON.parse(ev.dataTransfer.getData("Text"));
        this.overIndex = 0;
        this.addCustom(data, ev.target.getAttribute("data-pos") * 1);
        ev.preventDefault();
        ev.stopPropagation();
        return false;
    }
    /*---------- Highlight logic ----------*/
    highlightStart(evt) {
        const id = evt.currentTarget.getAttribute("data-id");
        this.pushEvent("highlightstart", id);
    }
    highlightEnd() {
        this.dispatchEvent(new CustomEvent("highlightend"));
    }
    searchIt(evt) {
        // Send event with item name to search component
        evt.preventDefault();
        const id = evt.currentTarget.getAttribute("data-id");
        const classes = evt.currentTarget.classList;
        if (!classes.contains("empty")) {
            const item = classes.contains("custom")
                ? this.custom.find(item => item.id === id)
                : this.coveo.find(item => item.id === id);
            if (item) {
                const name = item.name;
                this.pushEvent("sc-search-it", name, window);
            }
        }
    }
}