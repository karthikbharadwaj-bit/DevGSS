export default class Status {
    label;
    prefix;
    status;
    color;
    colors = {
        blue: [
            "new",
            "open",
            "reopened",
            "created",
        ],
        green: [
            "completed",
            "closed",
            "resolved",
        ],
        orange: [
            "work in progress",
            "wip",
            "in progress",
            "progress",
        ],
        red: [
            "duplicate",
            "invalid",
            "rejected",
            "cancelled",
        ],
    };
    get cls() {
        return `${this.prefix}__status ${this.prefix}__status_${this.color}`;
    }
    getColor() {
        Object.keys(this.colors).forEach(key => {
            if(this.colors[key].filter(item => item === this.status).length > 0) {
                this.color = key;
            }
        });
    }
    constructor(status, prefix) {
        this.status = status.toLowerCase();
        this.label = status;
        this.prefix = prefix;
        this.getColor();
    }
}