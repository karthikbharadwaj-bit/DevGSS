/* globals CL */
import getDataWave1Apex from '@salesforce/apex/ConvertLeadController.getDataWave1';
import getDataWave2Apex from '@salesforce/apex/ConvertLeadController.getDataWave2';
import convertLeadApex from '@salesforce/apex/ConvertLeadController.convertLeadWrapper';
import getAccountsPage from '@salesforce/apex/ConvertLeadController.getAccountsPage';
import checkAvailableVATNumberSF from '@salesforce/apex/ConvertLeadController.checkAvailableVATNumberSF';
import getLeadQualificationsPage from '@salesforce/apex/ConvertLeadController.getLeadQualificationsPage';
import getServiceEntitlementApex from '@salesforce/apex/ConvertLeadController.getServiceEntitlement';
import getCountriesForSalesLeadApex from '@salesforce/apex/ConvertLeadController.getCountriesForSalesLead';
import getDataForSalesLeadApex from '@salesforce/apex/ConvertLeadController.getDataForSalesLead';
import hasTaxExemptionApprovals from '@salesforce/apex/ConvertLeadController.hasTaxExemptionApprovals';
import rejectTaxExemptionApprovals from '@salesforce/apex/ConvertLeadController.rejectTaxExemptionApprovals';
import getContactsApex from '@salesforce/apex/ConvertLeadController.getContacts';
import getOpportunitiesApex from '@salesforce/apex/ConvertLeadController.getOpportunities';
import getOppContactRoleInfoApex from '@salesforce/apex/ConvertLeadController.getOppContactRoleInfo';
import publishLimitsError from "@salesforce/apex/ConvertLeadController.publishLimitsError";
import getDataForSelectedAccountApex from "@salesforce/apex/ConvertLeadController.getDataForSelectedAccount";
import CreatingAccount from '@salesforce/label/c.clServiceCreatingAccount';
import andOpportunity from '@salesforce/label/c.clServiceandOpportunity';
import CreatingQuote from '@salesforce/label/c.clServiceCreatingQuote';
import NGBSPreparing from '@salesforce/label/c.clServiceNGBSPreparing';
import NGBSWorking from '@salesforce/label/c.clServiceNGBSWorking';
import UnhandledErrorAppeared from '@salesforce/label/c.clServiceUnhandledErrorAppeared';
import ConvertLeadunexpectedError from '@salesforce/label/c.clServiceConvertLeadunexpectedError';
import ConvertLeadErrormsg from '@salesforce/label/c.clServiceConvertLeadError';
import ConvertingLead from '@salesforce/label/c.clServiceConvertingLead';

export function getContacts(leadId, accId, offset) {
    return getContactsApex({leadId, accId, offset});
}

export function getOpportunities(accId, offset) {
    return getOpportunitiesApex({accId, offset});
}

export function getDataWave1(leadId) {
    return getDataWave1Apex({leadId});
}

export function getDataWave2(leadId) {
    return getDataWave2Apex({leadId});
}

export function getAccounts(leadId, offset) {
    return getAccountsPage({leadId, offset});
}

export function getServiceEntitlement(accountId) {
    return getServiceEntitlementApex({accountId});
}

export function getLeadQualifications(leadId, offset) {
    return getLeadQualificationsPage({leadId, offset});
}

export function getOppContactRoleInfo(oppId, conId) {
    return getOppContactRoleInfoApex({oppId, conId});
}

export function getCountriesForSalesLead(leadCountry) {
    return getCountriesForSalesLeadApex({leadCountry});
}

export function getDataForSalesLead(leadId, leadCountry, leadBrand) {
    return getDataForSalesLeadApex({leadId, leadCountry, leadBrand});
}

export function getDataForSelectedAccount(leadId, accountId) {
    return getDataForSelectedAccountApex({leadId, accountId});
}

export function convertLead(convertParams) {
    let label = {
        CreatingAccount,
        andOpportunity,
        CreatingQuote,
        NGBSPreparing,
        NGBSWorking,
        UnhandledErrorAppeared,
        ConvertLeadunexpectedError,
        ConvertLeadErrormsg,
        ConvertingLead
    };

    showSpinner((convertParams.isCreateAccount ? label.CreatingAccount : label.ConvertingLead) + ' ' + (convertParams.isCreateOpportunity ? label.andOpportunity : ''));
    return convertLeadApex(createConvertParams(convertParams, 0))
        .then(r => {
            checkForErrors(r);
            return convertLeadApex(createConvertParams(convertParams, 1));
        })
        .then(r => {
            checkForErrors(r);
            return convertLeadApex(createConvertParams(createConvertData(r), 2));
        })
        .then(r => {
            checkForErrors(r);
            if (r.data.ConvertData && r.data.ConvertData.isCreateOpportunity
                && CL.app.serviceSelector.filters.brand.value !== 'TELUS Business Connect') {
                !r.data.ConvertData.isBilling && showSpinner(label.CreatingQuote);
                return convertLeadApex(createConvertParams(r.data.ConvertData, 3));
            }
            return r;
        })
        .then(r => convertParams.isElaAccount ? Array(5).fill(20).reduce((result, chunkSize) =>
                result.then(resp => createElaChunk(resp, chunkSize)), Promise.resolve(r)) : r
        )
        .then(r => {
            checkForElaErrors(r);
            return r;
        })
        .then(r => r.data.ConvertData.elaServiceOpportunityIds ?
            new Promise(resolve => {
                const elaServiceOpportunityIds = r.data.ConvertData.elaServiceOpportunityIds;
                const elaServiceOpportunityIdsLength = r.data.ConvertData.elaServiceOpportunityIds.length;
                const ELA_SERVICE_TYPE = 'ELA Service';
                showSpinner('Creating Quotes for ELA Service Opportunities...');
                let responseCounter = 0;
                const handleResponse = (response) => {
                    if (responseCounter === elaServiceOpportunityIdsLength) {
                        resolve(getTargetId(r));
                        return;
                    }
                    if (response.stage === 'error') {
                        responseCounter++;
                        showSpinner('The following error has occurred while processing quote: ' + response.error);
                        createQuote(elaServiceOpportunityIds.pop(), convertParams, ELA_SERVICE_TYPE, r.data.AccountId)
                        .subscribe(handleResponse);
                    }
                    if(response.stage === 'complete') {
                        responseCounter++;
                        showSpinner(
                            `${responseCounter} of ${elaServiceOpportunityIdsLength} ELA Service Quote ${responseCounter > 1 ? 'are' : 'is'} processed`
                        );
                        createQuote(elaServiceOpportunityIds.pop(), convertParams, ELA_SERVICE_TYPE, r.data.AccountId)
                        .subscribe(handleResponse);
                    }
                };
                createQuote(elaServiceOpportunityIds.pop(), convertParams, ELA_SERVICE_TYPE, r.data.AccountId)
                .subscribe(handleResponse);
            }) : getTargetId(r)
        );
}

export function createQuote(opportunityId, convertParams, elaAccountType, accountId) {
    return CL.ngbs.createQuote({
        opportunityId,
        forecastedUsers: convertParams.forecastedUsers
            || convertParams.forecastedDigitalUsers
            || convertParams.forecastedVoiceUsers
            || convertParams.ccForecastedUsers,
        forecastedRCVideoUsers: convertParams.forecastedRCVideoUsers,
        elaAccountType,
        accountId
    });
}

export function clAppReady(callback) {
    CL && CL.app
        ? callback()
        : window.addEventListener('clAppInit', callback);
}

export function handleError(error, title, lead) {
    console.log(error);
    console.log(title);
    let label = {
        CreatingAccount,
        andOpportunity,
        CreatingQuote,
        NGBSPreparing,
        NGBSWorking,
        UnhandledErrorAppeared,
        ConvertLeadunexpectedError,
        ConvertLeadErrormsg
    };
    let message = label.UnhandledErrorAppeared;
    if (error) {
        if (error instanceof ConvertLeadError) {
            title = label.ConvertLeadunexpectedError;
            message = error.message;
        } else if (Array.isArray(error.body)) {
            message = error.body.map(e => e.message).join(', ');
        } else if (error.body && typeof error.body.message === 'string') {
            message = error.body.message;
        } else if (typeof error.message === 'string') {
            message = error.message;
        }
        if (error.body.exceptionType === "System.LimitException") {
            publishLimitsError({
                leadId: lead.record.Id,
                error: message,
                errorType: error.body.exceptionType,
                stacktrace: error.body.stackTrace,
            });
        }
    }
    showToast({title, message, type: 'error', duration: 0});
}

export function showToast({title, message, type = 'info', duration, link}) {
    window.dispatchEvent(new CustomEvent('ShowToastEvent', {
        detail: {title, message, type, duration, link}
    }));
}

export function closeToast() {
    window.dispatchEvent(new CustomEvent('OnCloseToastEvent'));
}

export function showSpinner(text) {
    fireSpinnerEvent({text, isShown: true});
}

export function hideSpinner() {
    fireSpinnerEvent({isShown: false});
}

export function hasSomeApprovals(accountId, brand) {
    if (!accountId) {
        return Promise.resolve(false)
    }
    return hasTaxExemptionApprovals({accountId, brand});
}

export function rejectSomeTaxExemptionApprovals(accountId, brand) {
    return rejectTaxExemptionApprovals({accountId, brand});
}

export function checkAvailableVATNumber(accountId, leadId) {
    if (!accountId || !leadId) {
        return Promise.resolve(false)
    }
    return checkAvailableVATNumberSF({accountId, leadId});
}

function fireSpinnerEvent({text = '', isShown}) {
    window.dispatchEvent(new CustomEvent('ShowSpinnerEvent', {
        detail: {text, isShown}
    }));
}

function ConvertLeadError(messages, data) {
    let label = {
        ConvertLeadErrormsg
    };
    this.name = label.ConvertLeadErrormsg;
    this.data = data;
    if (Array.isArray(messages)) {
        this.message = messages.map(e => {
            if (e.messageDetails) {
                return `${e.message} \n ${e.messageDetails}`
            }
            return e.message;
        }).join(', ');
    } else {
        this.message = messages;
    }

    if (Error.captureStackTrace) {
        Error.captureStackTrace(this, this.constructor);
    } else {
        this.stack = (new Error()).stack;
    }
}

function createElaChunk(r, elaChunkSize) {
    const numberOfServices = r.data.ConvertData.numberOfELAServiceAccounts;

    if (!r.data.ConvertData.elaServiceOpportunityIds) {
        r.data.ConvertData.elaServiceOpportunityIds = [];
    }

    const numberOfCreatedServices = r.data.ConvertData.elaServiceOpportunityIds.length;

    if (numberOfCreatedServices >= numberOfServices) {
        return Promise.resolve(r);
    }

    showSpinner(
        'Creating ELA Accounts... Creating ELA Opportunities...\n' +
        numberOfCreatedServices + ' of ' + numberOfServices + ' were created'
    );

    r.data.ConvertData.elaChunkSize = numberOfServices - numberOfCreatedServices < elaChunkSize ?
        numberOfServices - numberOfCreatedServices : elaChunkSize;

    r.data.ConvertData.isElaLastChunk = numberOfCreatedServices + elaChunkSize >= numberOfServices;

    return convertLeadApex({
        convertParams: JSON.stringify({
            ConvertData: r.data.ConvertData,
            partIndex: 4
        })
    });
}

function createConvertParams(convertParams, partIndex) {
    return {
        convertParams: JSON.stringify({
            ConvertData: convertParams,
            partIndex: partIndex
        })
    };
}

function createConvertData(r) {
    return {
        accountId: r.data.AccountId,
        contactId: r.data.ContactId,
        ...r.data.ConvertData
    };
}

function checkForErrors(r) {
    if (r.status === 'error') {
        throw new ConvertLeadError(r.messages, r.data);
    }
}

function checkForElaErrors(r) {
    if (r.data.ConvertData.isElaAccount && r.status === 'error') {
        this.showToast({
            title: 'Create ELA Account unexpected Error',
            message: r.messages.map(error => JSON.stringify(error)).join(', \n'),
            type: 'error',
            duration: 0});
    }
}

function getTargetId(r) {
    return r.data.OpportunityId || r.data.ContactId;
}

ConvertLeadError.prototype = Object.create(Error.prototype);
ConvertLeadError.prototype.constructor = ConvertLeadError;