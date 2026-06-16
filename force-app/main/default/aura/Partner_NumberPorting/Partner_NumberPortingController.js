({
    init: function (component, event, helper) {
        try {
            let action = component.get("c.getNumberPortingMappingDetails");
            action.setCallback(this, function (result) {
                let state = result.getState();
                if (component.isValid() && state === "SUCCESS") {
                    let resultData = result.getReturnValue();

                    if (resultData !== undefined && resultData !== null) {
                        resultData = resultData.map(x => x.countryISOCode === 'US' ? Object.assign(x, { selected: true }) : x);
                        let selectedCountry = resultData.filter(x => x.countryISOCode === 'US')[0];
                        component.set('v.countries', resultData);
                        component.set('v.selectedCountry', selectedCountry.countryISOCode);
                    }
                }
            });
            $A.enqueueAction(action);
            component.set('v.disclaimer', $A.get('$Label.c.Number_Porting_Disclaimer'));
            console.log(component.get('v.disclaimer'));
            helper.getTranslations(component, event, helper);
        }
        catch (error) {
            console.error(error);
        }
    },
    countryChangeHandler: function (component, event, helper) {
        let countries = component.get('v.countries');
        let selectedValue = event.getParam('value');
        let selectedCountry = countries.filter(x => x.countryISOCode === selectedValue);
        if (selectedCountry.length > 0) {
            let text1 = 'Enter/paste upto ' + selectedCountry[0].apiRequestLimit + ' numbers. Each number should be added in a new line and follow E.164 format. E.g. \n'
            let text2 = ((selectedCountry[0].exampleNumbers) ? selectedCountry[0].exampleNumbers.replace(/,/g, '\n') :
                (selectedCountry[0].countryCode + '1234\n' +
                    selectedCountry[0].countryCode + '5678\n' +
                    selectedCountry[0].countryCode + '1357'));
            component.set('v.textAreaPlaceholderText', text1 + text2);
            component.set('v.textAreaValue', '');
        }
    },
    fileChangeHandler: function (component, event, helper) {
        let files = event.getSource().get("v.files");
        if (files.length > 0 && files[0].name.split(/\./g).slice(-1)[0].toLowerCase() !== 'csv') {
            component.set('v.showResults', true);
            component.set('v.portingResult', { responseCode: 500, responseMessage: 'Uploaded filetype is not csv' });
            return;
        }

        let filereader = new FileReader();

        let selectedCountryCode = component.get('v.selectedCountry');
        let countries = component.get('v.countries');
        let selectedCountry = countries.filter(x => x.countryISOCode === selectedCountryCode);

        if (files.length > 0 && selectedCountry && selectedCountry.length > 0) {
            filereader.readAsText(files[0]);
            filereader.onload = function () {
                let phoneNumberExtractionRes = helper.extractPhoneNumbersFromCsv(helper.csv2Array(filereader.result));
                if (phoneNumberExtractionRes.status === 'error') {
                    component.set('v.showResults', true);
                    component.set('v.portingResult', { responseCode: 500, responseMessage: phoneNumberExtractionRes.errorMessage });
                    return;
                }
                component.set('v.showResults', false);
                let validationResult = helper.validateNumbers(phoneNumberExtractionRes.numbers, selectedCountry[0].countryCode, selectedCountry[0].apiRequestLimit);
                component.set('v.textAreaValue', helper.transformPhoneNumbersToText(validationResult.acceptedNumbers));
                if (validationResult.rejectedNumbers.length > 0) {
                    component.set('v.rejectedNumbers', validationResult.rejectedNumbers);
                    component.set("v.isModalOpen", true);
                }
                if (validationResult.acceptedNumbers.length > 0) {
                    let phoneInputTextArea = component.find("phoneInputTextArea");
                    phoneInputTextArea.reportValidity();
                    component.set('v.showResults', true);
                    helper.getPortingResults(component, helper, selectedCountry[0], selectedCountry[0].brandCode, true, filereader.result, files[0].name, validationResult.acceptedNumbers);
                    component.set('v.portingResult', { responseCode: -1, responseMessage: 'Uploading numbers....' });
                }
            }
        }
    },
    checkPortabilityClickHandler: function (component, event, helper) {
        let phoneInputTextArea = component.find("phoneInputTextArea");
        if (phoneInputTextArea.checkValidity()) {
            component.set('v.showResults', false);
            let selectedCountryCode = component.get('v.selectedCountry');
            let countries = component.get('v.countries');
            let selectedCountry = countries.filter(x => x.countryISOCode == selectedCountryCode);

            if (selectedCountry.length > 0) {
                let validationResult = helper.validateNumbers(helper.extractPhoneNumbersFromText(component.get("v.textAreaValue")), selectedCountry[0].countryCode, selectedCountry[0].apiRequestLimit);
                component.set('v.textAreaValue', helper.transformPhoneNumbersToText(validationResult.acceptedNumbers));
                if (validationResult.rejectedNumbers.length > 0) {
                    component.set('v.rejectedNumbers', validationResult.rejectedNumbers);
                    component.set("v.isModalOpen", true);
                }
                if (validationResult.acceptedNumbers.length > 0) {
                    component.set('v.showResults', true);
                    helper.getPortingResults(component, helper, selectedCountry[0], selectedCountry[0].brandCode, false, '', '', validationResult.acceptedNumbers);
                    component.set('v.portingResult', { responseCode: -1, responseMessage: 'Uploading numbers....' });
                }
            }
        }
        else {
            phoneInputTextArea.reportValidity();
        }
    },
    getPortabilityHistoryHandler: function (component, event, helper) {
        let recordsPerPage = component.get('v.historyRecordsPerPage');
        component.set('v.historyNextButtonDisabled', false);
        component.set('v.historyPageNumber', 0);
        helper.getPortabilityHistory(component, helper, 0, recordsPerPage);
    },
    exampleLinkClickHandler: function (component, event, helper) {
        let selectedCountryCode = component.get('v.selectedCountry');
        let countries = component.get('v.countries');
        let selectedCountry = countries.filter(x => x.countryISOCode === selectedCountryCode);

        if (selectedCountry.length > 0) {
            let text = 'Phone\n' + ((selectedCountry[0].exampleNumbers) ? selectedCountry[0].exampleNumbers.replace(/,/g, '\n') :
                (selectedCountry[0].countryCode + '1234\n' +
                    selectedCountry[0].countryCode + '5678\n' +
                    selectedCountry[0].countryCode + '1357'));
            helper.downloadCsvHelper(text, 'text/csv', 'Example.csv');
        }
    },
    closeModalClickHandler: function (component, event, helper) {
        component.set("v.isModalOpen", false);
    },
    copyToClipBoardHandler: function (component, event, helper) {
        let rejectedNumbers = component.get("v.rejectedNumbers");
        let rejectedText = rejectedNumbers.map(x => x.number).reduce((acc, elem) => acc + elem + '\n', '').slice(0, -1);
        helper.copyTextHelper(rejectedText);
        component.set("v.copyButtonText", "Copied!");
        setTimeout(() => {
            component.set("v.copyButtonText", "Copy to clipboard");
        }, 700);
    },
    exportRejectedToCsvHandler: function (component, event, helper) {
        let csv = helper.array2csv(component.get('v.rejectedNumbers'));
        helper.downloadCsvHelper(csv, 'text/csv', 'Rejected.csv');
    },
    exportResultsToCsvHandler: function (component, event, helper) {
        let csv = component.get('v.portingResult').responseCsv;
        helper.downloadCsvHelper(csv, 'text/csv', 'Results.csv');
    },
    downloadHistoryFilesHandler: function (component, event, helper) {
        let index_fileName = event.getSource().get("v.name").split('_');
        let index = parseInt(index_fileName[0]);
        let fileName = index_fileName[1];
        let selectedPortingHistory = component.get('v.currentPortingHistoryPage')[index];
        let data = selectedPortingHistory[index_fileName[2]];
        let mimeType = selectedPortingHistory[index_fileName[3]];
        helper.downloadCsvHelper(data, mimeType, fileName);
    },
    resultsPreviousClickHandler: function (component, event, helper) {
        let currentPageNumber = component.get('v.pageNumber');
        currentPageNumber--;
        if (currentPageNumber > 0) {
            helper.setCurrentPage(component, currentPageNumber, component.get('v.recordsPerPage'), component.get('v.portingResult').responseList);
            component.set('v.pageNumber', currentPageNumber);
        }
    },
    resultsNextClickHandler: function (component, event, helper) {
        let currentPageNumber = component.get('v.pageNumber');
        currentPageNumber++;
        if (currentPageNumber <= component.get('v.totalPages')) {
            helper.setCurrentPage(component, currentPageNumber, component.get('v.recordsPerPage'), component.get('v.portingResult').responseList);
            component.set('v.pageNumber', currentPageNumber);
        }
    },
    historyPreviousClickHandler: function (component, event, helper) {
        component.set('v.historyNextButtonDisabled', false);
        let currentPageNumber = component.get('v.historyPageNumber');
        let recordsPerPage = component.get('v.historyRecordsPerPage');
        currentPageNumber--;
        if (currentPageNumber > -1) {
            helper.getPortabilityHistory(component, helper, currentPageNumber, recordsPerPage);
        }
        component.set('v.historyPageNumber', currentPageNumber);
    },
    historyNextClickHandler: function (component, event, helper) {
        let currentPageNumber = component.get('v.historyPageNumber');
        let recordsPerPage = component.get('v.historyRecordsPerPage');
        currentPageNumber++;
        helper.getPortabilityHistory(component, helper, currentPageNumber, recordsPerPage);
        component.set('v.historyPageNumber', currentPageNumber);
    }
})