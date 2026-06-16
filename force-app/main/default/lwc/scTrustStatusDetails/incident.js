/**
 * Created on 27.05.2019
 */
import { TimeZones } from "./timeZones";

export class Incident {
    constructor(serviceName, parentName, date, title, description, level) {
        this.serviceName = serviceName;
        this.parentName = parentName;
        this.incomingDate = date;
        this.title = title;
        this.description = description;
        this.level = level;
        this.time = new TimeZones();
    }
    getShort(maxSizeDesc) {
        maxSizeDesc = maxSizeDesc || 280;
        const description = this.description ? this.description.slice(0, maxSizeDesc) + "..." : "";
        return new Incident(
            this.serviceName,
            this.parentName,
            this.incomingDate,
            this.title,
            description,
            this.level
        );
    }
    get levelNumber() {
        return this.level.level;
    }
    get fullTitle() {
        return this.parentName ? `${this.parentName} - ${this.serviceName}` : this.serviceName;
    }
    get dateForIncident() {
        const d = this.date;
        return `${this.time.getMonthName(d.getMonth())} ${d.getDate()}, ${d.getFullYear()}`;
    }
    get timeForIncident() {
        const d = this.date;
        return `${this.time.plusZero(d.getHours())}:${this.time.plusZero(d.getMinutes())}:${this.time.plusZero(
            d.getSeconds()
        )} ${this.time.getTimeZoneGMT(d.getTimezoneOffset())}`;
    }
    get uid() {
        return `${this.groupByValue}_${this.title}_${this.incomingDate}`;
    }
    get groupByValue() {
        return `${this.fullTitle} (${this.level.label.toLowerCase()})`;
    }
    get date() {
        return new Date(this.incomingDate);
    }
    get formattedDate() {
        const d = this.date;
        return `${this.time.getMonthName(d.getMonth())} ${d.getDate()}, ${d.getFullYear()} ${this.time.plusZero(
            d.getHours()
        )}:${this.time.plusZero(d.getMinutes())}:${this.time.plusZero(d.getSeconds())} ${this.time.getTimeZone(
            d.getTimezoneOffset()
        )} - `;
    }
}