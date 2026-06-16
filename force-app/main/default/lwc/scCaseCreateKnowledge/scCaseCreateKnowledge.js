import { api, track } from "lwc";
import BaseService from "c/lwcBaseService";
import searchArticles from "@salesforce/apex/SupportCommunityNewCase.searchArticles";
import { labels } from "c/scCaseCreateLabels";
export default class ScCaseCreateKnowledge extends BaseService {
    @api title = "Related articles";
    @track queryValue = "";
    @track results = [];
    lang;
    labels = labels;
    searchMinSize = 3;
    eventsName = {
        subject: "SCCaseCreateSubject",
        articles: "SCCaseCreateValidateArticles",
    };
    get isEmptyQuery() {
        return this.queryValue === "";
    }
    get isEmptyResults() {
        return this.results.length === 0;
    }
    get isEmpty() {
        return this.isEmptyResults || this.isEmptyQuery;
    }
    get emptyMessage() {
        return this.isEmptyQuery ? this.labels.emptyQuery : this.labels.emptyResults;
    }
    doSearch() {
        this.loading = true;
        BaseService.invokeServiceMethod(searchArticles, { titlePart: this.queryValue, langCode: this.lang })
            .then(result => {
                this.loading = false;
                if (result.articles) {
                    this.results = result.articles.map(({ id, title, url, summary, LastPublishedDate }) => {
                        return { id, title, summary, LastPublishedDate, url: `article/${url}` };
                    });
                } else {
                    throw new Error("Empty options");
                }
            })
            .catch(error => {
                console.error(error);
                BaseService.errorToast(this.labels.errorMessage, error);
            });
    }
    onHandleSearch({ detail = { value, lang } }) {
        this.queryValue = detail.value.trim();
        this.lang = detail.lang;
        if (this.queryValue.length >= this.searchMinSize) {
            this.doSearch();
        } else {
            this.results = [];
        }
    }
    async doValidate({ detail }) {
        try {
            detail(this.results.length === 0);
        } catch (e) {
            console.warn(e);
        }
    }
    constructor() {
        super();
        window.addEventListener(this.eventsName.subject, this.onHandleSearch.bind(this));
        window.addEventListener(this.eventsName.articles, this.doValidate.bind(this));
    }
}