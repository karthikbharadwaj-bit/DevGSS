import { api, track, wire } from "lwc";
import getAreaPicklistOptions from "@salesforce/apex/SupportCommunityNewCase.getAreaPicklistOptions";
import createCase from "@salesforce/apex/SupportCommunityNewCase.createCase";
import getContactId from "@salesforce/apex/SupportCommunityNewCase.getContactId";
import modalMessage from "./modalMessage";
import getUrl from "@salesforce/apex/SupportCommunityNewCase.getUrl";
import { labels } from "c/scCaseCreateLabels";
import BaseService from "c/lwcBaseService";

export default class ScCaseCreateInfo extends BaseService {
    @api title = "Case info";
    @api callPath = "/RCCallSupport";
    @api detailsPath = "case-detail?Id=";
    @track subject = "";
    @track description = "";
    @track severityLevel = null;
    @track isLoading = { self: false, info: true };
    @track options = [];
    @track selectedOptions = { l1: null, l2: null, l3: null };
    @track describeValue = [];
    @track describeAdlValue = [];
    @track GDPRInfo = {};
    @track paFirstName;
    @track paLastName;
    @track paEmail;
    @track paPhone;
    @track paCitizen;
    @track comments;
    @wire(getUrl, {})
    siteUrl;
    severities = [{ label: "Level 2 - Urgent" }, { label: "Level 3 - High" }, { label: "Level 4 - Medium" }];
    searchTimeout;
    searchTime = 500;
    searchValue = "";
    lang;
    contactData;
    gdprPicklistValue = "GDPR Request";
    messages = {
        "Sales Inquiry or Upgrade": "sales",
        "Service Downgrade or Cancellation": "downgrade",
    };
    eventsName = {
        contact: "SCCaseCreateValidateContact",
        articles: "SCCaseCreateValidateArticles",
        subject: "SCCaseCreateSubject",
        info: "SCCaseCreateInfo",
        language: "sc-app_language",
    };
    @track labels = labels;
    describeOptionList = ["view", "download", "change", "delete"];
    describeAdlOptionList = ["analytics", "glip"];
    get callUrl() {
        return this.siteUrl.data + this.callPath;
    }
    get l1Options() {
        return this.convertToComboboxValues(this.options);
    }
    get l2Options() {
        return this.convertToComboboxValues(this.getSubOption(this.options, 1));
    }
    get l3Options() {
        return this.convertToComboboxValues(this.getSubOption(this.getSubOption(this.options, 1), 2));
    }
    get hasLevel1() {
        return !!this.selectedOptions.l1;
    }
    get showLevel2() {
        return this.hasLevel1 && this.l2Options.length > 0;
    }
    get hasLevel2() {
        return !!this.selectedOptions.l2;
    }
    get showLevel3() {
        return this.hasLevel2 && this.l3Options.length > 0;
    }

    get severitiesOptions() {
        return this.convertToComboboxValues(this.severities);
    }
    get isGDPR() {
        const selectGDPR = this.selectedOptions.l1 === this.gdprPicklistValue;
        if (selectGDPR) {
            this.searchArticles("");
        }
        return selectGDPR;
    }
    get describeOptions() {
        return this.describeOptionList.map(item => {
            return { label: this.labels[item], value: item };
        });
    }
    get describeDeleteSelected() {
        return this.describeValue.filter(item => item === "delete").length > 0;
    }
    get describeAdlOptions() {
        return this.describeAdlOptionList.map(item => {
            return { label: this.labels[item], value: item };
        });
    }
    get emailPattern() {
        return BaseService.regexp.email;
    }
    get messageId() {
        return this.selectedOptions.l1 ? this.messages[this.selectedOptions.l1] : null;
    }
    get hasMessage() {
        const id = this.messageId;
        return !!id && !!modalMessage[id];
    }
    get getMessage() {
        const hasMessage = this.hasMessage;
        if (hasMessage) {
            this.template.querySelector(".sc-case-info__message").innerHTML = modalMessage[this.messageId];
        }
        return hasMessage;
    }

    get messageCls() {
        return `sc-case-info__message ${this.getMessage ? " sc-case-info__message_show" : ""}`;
    }
    set loading({ value, source = "self" }) {
        this.isLoading[source] = value;
    }
    get loading() {
        return this.isLoading["self"];
    }
    parseDuplicate() {
        const hash = window.location.hash.substring(1);
        let params;
        if (hash.length > 0) {
            try {
                params = JSON.parse(decodeURIComponent(window.atob(decodeURIComponent(hash))));
            } catch (e) {
                console.warn(e);
            }
            if (params) {
                if (params.isGDPR) {
                    this.selectedOptions.l1 = this.gdprPicklistValue;
                    this.GDPRInfo.firstName = params.firstName;
                    this.GDPRInfo.lastName = params.lastName;
                    this.GDPRInfo.email = params.email;
                    this.GDPRInfo.rcPhone = params.phone;
                    this.GDPRInfo.euCitizen = params.citizen;
                    this.GDPRInfo.comments = params.description;
                    let describeVal = [];
                    let describeAdlVal = [];
                    for (let val of this.describeOptionList) {
                        if (params[val]) {
                            describeVal.push(val);
                        }
                    }
                    for (let val of this.describeAdlOptionList) {
                        if (params[val]) {
                            describeAdlVal.push(val);
                        }
                    }
                    this.describeValue = describeVal;
                    this.describeAdlValue = describeAdlVal;
                } else {
                    this.selectedOptions = params.selectedOptions;
                    this.description = params.description;
                    this.severityLevel = params.severityLevel;
                    this.subject = params.subject;
                    this.searchArticles(params.subject);
                }
            }
        }
    }
    getSubOption(opt, level) {
        const curLevel = opt.filter(item => item.label === this.selectedOptions[`l${level}`]);
        return curLevel.length > 0 && curLevel[0].subLevelOptions ? curLevel[0].subLevelOptions : [];
    }
    handleGDPRChange(evt) {
        const name = evt.target.name;
        if (evt.target.checkValidity()) {
            this.GDPRInfo[name] = name === "euCitizen" ? evt.target.checked : evt.detail.value;
        }
    }
    convertToComboboxValues(items) {
        return items.map(item => {
            return { label: item.label, value: item.label };
        });
    }
    optionsHandleChange(evt) {
        const name = evt.target.name;
        let level = 1;
        try {
            level = name.split("-")[2] * 1;
        } catch (e) {
            console.error("Wrong combobox name", e);
        }
        this.selectedOptions[`l${level}`] = evt.detail.value;
        const size = Object.keys(this.selectedOptions).length;
        for (let i = level + 1; i <= size; i++) {
            this.selectedOptions[`l${i}`] = null;
        }
    }
    searchArticles(text) {
        clearTimeout(this.searchTimeout);
        if (text !== this.searchValue) {
            this.searchValue = text;
            BaseService.pushEvent(
                this.eventsName.subject,
                {
                    value: this.searchValue,
                    lang: this.lang || "en_US",
                },
                window
            );
        }
    }
    severityHandleChange(evt) {
        this.severityLevel = evt.detail.value;
    }
    subjectHandleChange(evt) {
        clearTimeout(this.searchTimeout);
        this.subject = evt.detail.value;

        this.searchTimeout = setTimeout(() => {
            this.searchArticles(evt.detail.value);
        }, this.searchTime);
    }
    subjectBlur(evt) {
        this.searchArticles(evt.target.value);
    }
    descriptionHandleChange(evt) {
        this.description = evt.detail.value;
    }
    checkInfo() {
        return BaseService.lightningValidate(
            this.template.querySelectorAll("lightning-input, lightning-combobox, lightning-textarea")
        );
    }
    checkKnowledge() {
        return new Promise(resolve => {
            BaseService.pushEvent(
                this.eventsName.articles,
                val => {
                    resolve(val);
                },
                window
            );
        });
    }
    checkContact() {
        return new Promise(resolve => {
            BaseService.pushEvent(
                this.eventsName.contact,
                ({ valid, data }) => {
                    this.contactData = data;
                    resolve(valid);
                },
                window
            );
        });
    }
    checkAll() {
        return Promise.all([this.checkContact(), this.checkKnowledge()]);
    }
    async confirmKnowledge() {
        return await new Promise(resolve =>
            BaseService.showModal(
                null,
                `<h2 class="slds-text-heading_small">You might find a faster answer in our knowledge base.</h2>`,
                [
                    {
                        label: "Great! Show me related articles",
                        variant: "brand",
                        callback: () => {
                            resolve(false);
                        },
                    },
                    {
                        variant: "success",
                        label: "Create a Case",
                        callback: () => {
                            resolve(true);
                        },
                    },
                ],
                () => {
                    resolve(false);
                }
            )
        );
    }
    async getSecondEmail() {
        return await new Promise(resolve => {
            BaseService.showModal(
                null,
                `
                    ${this.labels.updateInfo}
                    <input type="email" name="email" readonly value="${this.contactData.email}" class="slds-input"/>
                    ${this.labels.secondEmail}
                    <input type="email" name="secEmail" class="slds-input"/>`,
                [
                    {
                        label: "Next",
                        variant: "brand",
                        name: "next",
                        callback: ({ values }) => {
                            try {
                                const secEmail = values.filter(item => {
                                    return item.name === "secEmail";
                                });
                                if (secEmail.length > 0) {
                                    const email = secEmail[0].value;
                                    resolve(email);
                                } else {
                                    throw new Error("No have secEmail");
                                }
                            } catch (e) {
                                console.error(e);
                                resolve(false);
                            }
                        },
                    },
                ],
                () => {
                    resolve(false);
                }
            );
        });
    }
    openCaseDetails(id) {
        try {
            location.assign(this.detailsPath + id);
        } catch (e) {
            location.href = this.detailsPath + id;
        }
    }
   submitException(error) {
       console.error(error);
       BaseService.errorToast(this.labels.errorMessage, error);
       BaseService.showSpinner(false);
   }
    submit(contact, caseInfo) {
        BaseService.showSpinner(true, this.labels.submittingCase);
        BaseService.invokeServiceMethod(getContactId, contact).then(({ contactId }) => {
            BaseService.invokeServiceMethod(createCase, Object.assign(caseInfo, { contactId }))
                .then(result => {
                    if (result.createdCaseId) {
                        BaseService.showSpinner(false);
                        this.openCaseDetails(result.createdCaseId);
                    } else {
                        throw new Error("Case is not created!");
                    }
                })
                .catch(error => this.submitException(error));
        }).catch(error => this.submitException(error));
    }
    checkDescribeValue(val, adv = false) {
        const source = adv ? this.describeAdlValue : this.describeValue;
        return source.filter(item => item === val).length !== 0;
    }
    async validateSubmit() {
        const results = [this.checkInfo()].concat(await this.checkAll());
        const invalidResults = results.filter(item => item === false).length;
        if (invalidResults === 0 || (invalidResults === 1 && results[2] === false && (await this.confirmKnowledge()))) {
            const altEmail = await this.getSecondEmail();

            if (altEmail !== false) {
                const isEmailValid =
                    altEmail.length === 0 || new RegExp(BaseService.regexp.email).test(String(altEmail).toLowerCase());

                if (isEmailValid) {
                    let caseInfo = {
                        subject: this.subject,
                        description: this.description,
                        severityLevel: this.severityLevel,
                        selectedProduct: this.selectedOptions.l1,
                        selectedProduct2: this.selectedOptions.l2,
                        selectedProduct3: this.selectedOptions.l3,
                        alternateEmail: altEmail,
                        callbackPhone: this.contactData.callbackPhone,
                        timezone: this.contactData.timezone,
                    };
                    if (this.isGDPR) {
                        const gdprInfo = Object.assign(
                            {
                                viewRequest: this.checkDescribeValue("view"),
                                changeRequest: this.checkDescribeValue("change"),
                                downloadRequest: this.checkDescribeValue("download"),
                                deleteRequest: this.checkDescribeValue("delete"),
                                retainAnalytics: this.checkDescribeValue("analytics", true),
                                retainGlip: this.checkDescribeValue("glip", true),
                            },
                            this.GDPRInfo
                        );
                        caseInfo = Object.assign({}, caseInfo, gdprInfo);
                    }
                    delete this.contactData.callbackPhone;
                    this.submit(this.contactData, {
                        caseInfo: JSON.stringify(caseInfo),
                        isGdpr: this.isGDPR,
                    });
                } else {
                    BaseService.errorToast(this.labels.missing.secEmailTitle, this.labels.missing.secEmail);
                    this.loading = { value: false };
                }
            }
        } else if (results[2] !== false || invalidResults > 1) {
            BaseService.errorToast(this.labels.submitNotValid, this.labels.submitNotValidMessage);
            this.loading = { value: false };
        }
    }
    async showSeverity(evt) {
        evt.preventDefault();
        BaseService.showModal("Severity Definitions", modalMessage.levelDefinitions);
    }
    getCaseInfo() {
        this.loading = { value: true };
        BaseService.invokeServiceMethodWithoutParameters(getAreaPicklistOptions)
            .then(result => {
                this.loading = { value: false };
                if (result.areaOptions) {
                    this.options = result.areaOptions;
                    this.parseDuplicate();
                } else {
                    throw new Error("Empty options");
                }
            })
            .catch(error => {
                console.error(error);
                BaseService.errorToast(this.labels.errorMessage, error);
            });
    }
    onLanguageChanged() {
        if (window.app && window.app.language) {
            this.lang = window.app.language;
        }
    }
    handleChangeDescribe(evt) {
        this.describeValue = evt.detail.value;
    }
    handleChangeAdlDescribe(evt) {
        this.describeAdlValue = evt.detail.value;
    }
    onInfoLoaded({ detail }) {
        if (detail === "loaded") {
            this.loading = { value: false, source: "info" };
        }
    }
    connectedCallback() {
        this.getCaseInfo();
    }
    constructor() {
        super();
        BaseService.pushEvent(this.eventsName.info, "init", window);
        window.addEventListener(this.eventsName.info, this.onInfoLoaded.bind(this));
        if (window.app && window.app.language) {
            this.lang = window.app.language;
        } else {
            window.addEventListener(this.eventsName.language, this.onLanguageChanged.bind(this));
        }
    }
}