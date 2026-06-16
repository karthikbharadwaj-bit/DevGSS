import { track, api } from "lwc";
import BaseService from "c/lwcBaseService";

export default class ScKnowledgeDetails extends BaseService {
    @api detailsTitle = "Details";
    @api issueTitle = "Issue";
    @api questionTitle = "Question";
    @api STRTitle = "Steps to reproduce";
    @api causeTitle = "Cause";
    @api symptomTitle = "Symptom";
    @api affectedEnvTitle = "Affected Environments";
    @api statusTitle = "Status";
    @api resolutionTitle = "Resolution";
    @api detailsDisplay = false;
    @api displayDetailsTitle = false;
    @api issueDisplay = false;
    @api questionDisplay = false;
    @api STRDisplay = false;
    @api causeDisplay = false;
    @api symptomDisplay = false;
    @api affectedEnvDisplay = false;
    @api statusDisplay = false;
    @api resolutionDisplay = false;
    @api hideEmptyAdditionalBlocks = false;

    @track content = null;
    @track details = null;
    @track issue = null;
    @track question = null;
    @track STR = null;
    @track cause = null;
    @track symptom = null;
    @track affectedEnv = null;
    @track status = null;
    @track resolution = null;

    get showDetails() {
        return this.detailsDisplay && (this.details || !this.hideEmptyAdditionalBlocks);
    }
    get showDetailsHeader() {
        return this.displayDetailsTitle && this.showDetails;
    }
    get showIssue() {
        return this.issueDisplay && (this.issue || !this.hideEmptyAdditionalBlocks);
    }
    get showQuestion() {
        return this.questionDisplay && (this.question || !this.hideEmptyAdditionalBlocks);
    }
    get showSTR() {
        return this.STRDisplay && (this.STR || !this.hideEmptyAdditionalBlocks);
    }
    get showCause() {
        return this.causeDisplay && (this.cause || !this.hideEmptyAdditionalBlocks);
    }
    get showSymptom() {
        return this.symptomDisplay && (this.symptom || !this.hideEmptyAdditionalBlocks);
    }
    get showAffectedEnv() {
        return this.affectedEnvDisplay && (this.affectedEnv || !this.hideEmptyAdditionalBlocks);
    }
    get showStatus() {
        return this.statusDisplay && (this.status || !this.hideEmptyAdditionalBlocks);
    }
    get showResolution() {
        return this.resolutionDisplay && (this.resolution || !this.hideEmptyAdditionalBlocks);
    }

    doRender() {
        const summaryElement = this.template.querySelector(".scKnowledgeDetails__summary");
        if (summaryElement) {
            summaryElement.innerHTML = this.content || "";
        }
        if (this.showDetails) {
            const detailsElement = this.template.querySelector(".scKnowledgeDetails__details");
            if (detailsElement) {
                detailsElement.innerHTML = this.details || "";
            }
        }
        if (this.showIssue) {
            const issueElement = this.template.querySelector(".scKnowledgeDetails__issue");
            if (issueElement) {
                issueElement.innerHTML = this.issue || "";
            }
        }
        if (this.showQuestion) {
            const questionElement = this.template.querySelector(".scKnowledgeDetails__question");
            if (questionElement) {
                questionElement.innerHTML = this.question || "";
            }
        }
        if (this.showSTR) {
            const strElement = this.template.querySelector(".scKnowledgeDetails__str");
            if (strElement) {
                strElement.innerHTML = this.STR || "";
            }
        }
        if (this.showCause) {
            const causeElement = this.template.querySelector(".scKnowledgeDetails__cause");
            if (causeElement) {
                causeElement.innerHTML = this.cause || "";
            }
        }
        if (this.showSymptom) {
            const symptomElement = this.template.querySelector(".scKnowledgeDetails__symptom");
            if (symptomElement) {
                symptomElement.innerHTML = this.symptom || "";
            }
        }
        if (this.showAffectedEnv) {
            const affectedEnvElement = this.template.querySelector(".scKnowledgeDetails__affectedEnv");
            if (affectedEnvElement) {
                affectedEnvElement.innerHTML = this.affectedEnv || "";
            }
        }
        if (this.showStatus) {
            const statusElement = this.template.querySelector(".scKnowledgeDetails__status");
            if (statusElement) {
                statusElement.innerHTML = this.status || "";
            }
        }
        if (this.showResolution) {
            const resolutionElement = this.template.querySelector(".scKnowledgeDetails__resolution");
            if (resolutionElement) {
                resolutionElement.innerHTML = this.resolution || "";
            }
        }
    }

    renewContent() {
        this.content = window.app.Article.Summary;
        this.details = window.app.Article.Info;
        this.issue = window.app.Article.Issue;
        this.question = window.app.Article.Question;
        this.STR = window.app.Article.STR;
        this.cause = window.app.Article.Cause;
        this.symptom = window.app.Article.Symptom;
        this.affectedEnv = window.app.Article.AffectedEnv;
        this.status = window.app.Article.Status;
        this.resolution = window.app.Article.Resolution;
        BaseService.pushEvent("scBreadcrumbs", { title: window.app.Article.Title }, window);
        this.doRender();
    }

    connectedCallback() {
        if (window.app && window.app.Article.Info !== "") {
            this.renewContent();
        }
        document.addEventListener("sc-app_article", this.renewContent.bind(this));
    }
    renderedCallback() {
        this.doRender();
    }
}