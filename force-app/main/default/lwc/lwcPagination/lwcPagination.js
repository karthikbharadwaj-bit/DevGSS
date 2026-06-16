import BaseService from "c/lwcBaseService";
import { api } from "lwc";
import { Page } from "./page";
/**
 * @param {Integer} size Count of pages
 * @param {Integer} page Current page
 * @param {Boolean} disabled Disable pagination (for loading)
 * @param {Integer} step Count of page, display near current page
 */
export default class LwcPagination extends BaseService {
    @api size = 10;
    @api page = 1;
    @api disabled = false;
    @api step = 3;
    get paginationCls() {
        return `pagination${this.disabled? " disabled" : ""}`;
    }
    get arrowLeftCls() {
        return `pagination__arrow${this.disabled || this.page === 1 ? " disabled" : ""}`;
    }
    get arrowRightCls() {
        return `pagination__arrow${this.disabled || this.page === this.size ? " disabled" : ""}`;
    }
    add(from, to) {
        const bPages = [];
        to = to || from + 1;
        for (let i = from; i < to; i++) {
            bPages.push(new Page(i, i === this.page));
        }
        return bPages;
    }
    last() {
        return [new Page("...", false, true)].concat(this.add(this.size));
    }
    first() {
        return this.add(1).concat([new Page("...", false, true)]);
    }
    get pages() {
        let bPages = [];
        if (this.size < this.step * 2 + 6) {
            bPages = this.add(1, this.size + 1);
        } else if (this.page < this.step * 2 + 1) {
            bPages = this.add(1, this.step * 2 + 4).concat(this.last());
        } else if (this.page > this.size - this.step * 2) {
            bPages = this.first().concat(this.add(this.size - this.step * 2 - 2, this.size + 1));
        } else {
            bPages = this.first().concat(this.add(this.page - this.step, this.page + this.step + 1), this.last());
        }
        return bPages;
    }
    handleChangePage(evt) {
        if (!evt.currentTarget.classList.contains("disabled") && !evt.currentTarget.classList.contains("active")) {
            const data = evt.currentTarget.getAttribute("data-id");
            if (data === "next") {
                if (this.page < this.size) {
                    this.page++;
                }
            } else if (data === "prev") {
                if (this.page > 1) {
                    this.page--;
                }
            } else if (data !== "...") {
                this.page = data * 1;
            }
            BaseService.pushEvent("changepage", { page: this.page }, this);
        }
    }
}