import { track } from "lwc";
import BaseService from "c/lwcBaseService";

const DEFAULT_COUNT_PER_ROW = 4;
export default class ScTrustIncidents extends BaseService {
    perRow = DEFAULT_COUNT_PER_ROW;
    @track incidents = [];
    eventsName = {
        incidents: "SCTrustIncidents",
    };
    getRow(id) {
        return Math.floor(id / this.perRow) + 1;
    }
    sortList(list) {
        return list.sort(function(a, b) {
            const timeDiff = b.incidents[0].date.getTime() - a.incidents[0].date.getTime();
            return timeDiff !== 0 ? timeDiff : b.incidents[0].levelNumber - a.incidents[0].levelNumber;
        });
    }
    onIncidentsLoaded({ detail }) {
        const buf = [];
        for (let key in detail) {
            buf.push({ incidents: detail[key], isOpen: false });
        }
        this.sortList(buf);
        buf.forEach((item, inx) => {
            item.inx = inx;
            item.rowCls = `warn-row-${this.getRow(inx)}`;
        });
        this.incidents = buf;
    }
    handleIncidentClick(evt) {
        const id = evt.currentTarget.getAttribute("data-id") * 1;
        if (this.incidents[id].isOpen === true) {
            this.incidents[id].isOpen = false;
        } else {
            this.incidents.forEach(item => {
                item.isOpen = item.inx === id;
            });
        }
    }
    constructor() {
        super();
        window.addEventListener(this.eventsName.incidents, this.onIncidentsLoaded.bind(this));
    }
}