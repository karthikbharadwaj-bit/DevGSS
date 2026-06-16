export class Col {
    title;
    value;
    sort;
    ariasSort = {
        none: { id: 0, val: "none" },
        desc: { id: 1, val: "descending" },
        asc: { id: 2, val: "ascending" },
    };

    get sortedText() {
        return `Sorted ${this.ariasSort[this.sort].val}`;
    }
    get colCls() {
        let cls = "slds-is-sortable";
        if (this.sort && this.sort !== "none") {
            cls += ` slds-is-sorted  slds-is-sorted_${this.sort}`;
        }
        return cls;
    }
    changeSort() {
        this.sort = this.sort === "desc" ? "asc" : "desc";
    }
    get ariaSort() {
        return this.sort ? this.ariasSort[this.sort].val : this.ariasSort.none.val;
    }
    constructor(title, value, sort, changeSort) {
        this.title = title;
        this.value = value;
        this.sort = sort;
        if (changeSort) {
            this.changeSort();
        }
    }
}