export class Crumb {
    constructor(inx, label, url) {
        this.id = "bc_" + label.toLowerCase();
        this.label = label;
        this.url = url || null;
        this.css = `sc-breadcrumb ${!url || url === "" ? "inactive": ""}`;
        this.inx = inx - 1;
    }
}