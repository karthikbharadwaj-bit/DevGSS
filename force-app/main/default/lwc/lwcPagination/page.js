export class Page {
    get pageCls() {
        return `pagination__item${this.isCurrent ? " active" : ""}${this.isDots ? "" : " number"}`;
    }
    constructor(pageNumber, isCurrent, isDots) {
        this.id = pageNumber;
        this.isCurrent = isCurrent;
        this.isDots = isDots;
    }
}