({
    csv2Array: function (strData) {
        const objPattern = new RegExp(("(\\,|\\r?\\n|\\r|^)(?:\"([^\"]*(?:\"\"[^\"]*)*)\"|([^\\,\\r\\n]*))"), "gi");
        let arrMatches = null, arrData = [[]];
        while (arrMatches = objPattern.exec(strData)) {
            if (arrMatches[1].length && arrMatches[1] !== ",") {
                arrData.push([]);
            }
            arrData[arrData.length - 1].push(arrMatches[2] ? arrMatches[2].replace(new RegExp("\"\"", "g"), "\"") : arrMatches[3]);
        }
        arrData = arrData.map(x => x[0].split(/,|;/)).slice(0, -1);
        return (arrData.length > 0) ? arrData.filter(x => x.length == arrData[0].length) : [];
    },
    array2csv: function (arrayData) {
        if (arrayData && arrayData.length > 0) {
            //Extract column headers
            let headers = Object.keys(arrayData[0]);
            //Generate CSV header
            let csv = headers.reduce(((acc, elem, index) => acc + elem + (index === (headers.length - 1) ? '\n' : ',')), '');
            //Generate CSV rows
            csv = arrayData.reduce((acc, elem) => acc + headers.map((x) => elem[x] ? elem[x] : '').reduce(((acc, elem, index) => acc + elem + (index === (headers.length - 1) ? '\n' : ',')), ''), csv);
            return csv.slice(0, -1); //Remove trailing new line and return
        }
        else {
            return '';
        }
    },
    extractPhoneNumbersFromCsv: function (csvData) {
        if (csvData && csvData.length > 0 && csvData[0].length > 0) {
            //Extract the position of phone number column in first row
            let position = csvData[0].indexOf("Phone");
            if (position === -1) {
                return {
                    status: 'error',
                    errorMessage: 'The uploaded csv doesn\'t have a column header named \'Phone\''
                }
            }
            //Extract all numbers now
            let numbers = csvData.map(x => x[position]);
            numbers.shift(); //Remove the header row
            return numbers.length === 0 ? { status: 'error', errorMessage: 'No phone numbers found in csv' } : { status: 'success', numbers }
        }
        else {
            return { status: 'error', errorMessage: 'No phone numbers found in csv' };
        }
    },
    extractPhoneNumbersFromText: function (textAreaText) {
        return textAreaText ? textAreaText.split('\n') : [];
    },
    transformPhoneNumbersToText: function (phoneNumbers) {
        return phoneNumbers ? phoneNumbers.reduce(((acc, curr) => acc + curr + "\n"), '').trim() : '';
    },
    validateNumbers: function (phoneNumbers, countryCode, bulkLimit) {
        if (phoneNumbers) {
            //Pre validation - Remove all spaces from numbers
            phoneNumbers = phoneNumbers.map(x => x.replace(/ /g,''));

            //Stage 1 - E.164 Regex Validation
            let acceptedNumbers = phoneNumbers.filter(x => x.match(/^\+?[1-9]\d{1,14}$/) ? true : false);
            let rejectedNumbers = phoneNumbers.filter(x => x.match(/^\+?[1-9]\d{1,14}$/) ? false : true).map(x => { return { number: x, rejectionReason: 'Invalid Format' } });

            //Stage 2 - Country code validation
            countryCode = countryCode.replace('+', '');
            let rejectedNumbers1 = acceptedNumbers.filter(x => !(x.replace('+', '').indexOf(countryCode) == 0)).map(x => { return { number: x, rejectionReason: 'Invalid Country Code' } });
            acceptedNumbers = acceptedNumbers.filter(x => (x.replace('+', '').indexOf(countryCode) == 0));
            rejectedNumbers = rejectedNumbers.concat(rejectedNumbers1);

            //Stage2.5 - US and Canada
            if(countryCode === '1') {
                let rejectednumber2 = acceptedNumbers.filter(x => x.replace('+', '').length !== 11).map(x => { return { number: x, rejectionReason: 'Number length incorrect' } });
                acceptedNumbers = acceptedNumbers.filter(x => x.replace('+', '').length === 11);
                rejectedNumbers = rejectedNumbers.concat(rejectednumber2);
            }

            //Stage 3 - Bulk Limit
            if (acceptedNumbers.length > bulkLimit) {
                rejectedNumbers = rejectedNumbers.concat(acceptedNumbers.splice(bulkLimit, acceptedNumbers.length).map(x => { return { number: x, rejectionReason: 'Request Limit of ' + bulkLimit + ' Numbers Exceeded' } }));
                acceptedNumbers = acceptedNumbers.splice(0, bulkLimit);
            }

            return {
                acceptedNumbers,
                rejectedNumbers
            }
        }
        else {
            return {
                acceptedNumbers: [],
                rejectedNumbers: []
            };
        }
    },
    
     //Translation Start
    getTranslations : function (component, event, helper) 
    {
        try
        {
            var action = component.get("c.getTranslations");
            action.setParams({
                "objNames": 'Number_Portability_Request__c'
            });
            action.setCallback(this, function (result) {
                var state = result.getState();
                if (component.isValid() && state === "SUCCESS") {
                    console.log('AllObjFields - ' + JSON.stringify(result.getReturnValue()));
                    var resultData = result.getReturnValue();
                    if(resultData != undefined && resultData != null && resultData != '')
                    {
                        if(resultData.allObjFieldsMap != undefined && resultData.allObjFieldsMap != null && 
                           resultData.allObjFieldsMap != '')
                        {
                            component.set("v.portFieldsMap", resultData.allObjFieldsMap.Number_Portability_Request__c);
                        }
                        component.set("v.translationsMap", resultData.prmLabelsMap);
                        component.set("v.PRMSpecificTranslationsMap", resultData.prmSpecificLabelsMap);
                    }
                }
            });
            $A.enqueueAction(action);
        }
        catch(e)
        {
            console.log('err - ' + e);
        } 
    },
     //Translation End
    copyTextHelper: function (text) {
        const hiddenTextArea = document.createElement("textarea");
        hiddenTextArea.value = text;
        document.body.appendChild(hiddenTextArea);
        hiddenTextArea.select();
        document.execCommand("copy");
        document.body.removeChild(hiddenTextArea);
    },
    downloadCsvHelper: function (data, mimeType, fileName) {
        data = data ? data : '';
        mimeType = mimeType ? mimeType : 'text/plain';
        fileName = fileName ? fileName : 'ExportData.txt';

        const hiddenElement = document.createElement('a');
        hiddenElement.href = 'data:' + mimeType + ';charset=utf-8,' + encodeURI(data);
        //hiddenElement.href = 'data:text/csv;charset=utf-8,' + encodeURI(csv);
        hiddenElement.target = '_self';
        hiddenElement.download = fileName;
        document.body.appendChild(hiddenElement);
        hiddenElement.click();
        document.body.removeChild(hiddenElement);
    },
    getPortingResults: function (component, helper, selectedCountry, brandCode, isBulk, uploadCSV, csvFileName, numberList) {
        try {
            let action = component.get("c.generateNumberPortingRequest"); //Call stage 1 process
            action.setParams({
                countryName: selectedCountry.countryName,
                countryIsoCode: selectedCountry.countryISOCode,
                brandCode: brandCode,
                requestSize: numberList.length,
                isBulk,
                uploadCSV,
                csvFileName,
                numberList
            });
            action.setCallback(this, function (result) {
                let state = result.getState();
                if (component.isValid() && state === "SUCCESS") {
                    let stage1Result = result.getReturnValue();
                    console.log('Stage 1 completed, portingRequestId = ' + stage1Result.portingRequestId);
                    component.set('v.portingResult', stage1Result);
                    if (stage1Result.responseCode === -1) { //Success, Proceed to Stage 2
                        let stage2action = component.get("c.checkPortability"); //Call stage 2 process
                        stage2action.setParams({
                            brandCode: stage1Result.brandCode,
                            brandName: stage1Result.brandName,
                            apiIdentifier: stage1Result.apiIdentifier,
                            portingRequestId: stage1Result.portingRequestId,
                        });
                        stage2action.setCallback(this, function (result) {
                            console.log('Stage 2 completed');
                            if (component.isValid() && state === "SUCCESS") {
                                let stage2Result = result.getReturnValue();
                                component.set('v.portingResult', stage2Result);

                                if (stage2Result.responseCode === -1) { //Success, Proceed to Stage 3
                                    let testAction = component.get('c.getContentDocumentCount');
                                    let processExecutionStatusAction = component.get('c.getProcessExecutionStatus');
                                    testAction.setParams({
                                        portingRequestId: stage1Result.portingRequestId
                                    });
                                    processExecutionStatusAction.setParams({
                                        portingRequestId: stage1Result.portingRequestId
                                    });
                                    let retryCount = 0;
                                    processExecutionStatusAction.setCallback(this, (result) => {
                                        let res = result.getReturnValue();
                                        if(res === null) {
                                            $A.enqueueAction(processExecutionStatusAction);
                                        }
                                        else {
                                            let execStatus = JSON.parse(res);
                                            if((execStatus.result.length > 0 && (execStatus.result[0].status === 'INPROCESS' || execStatus.result[0].status === 'STARTED')) || (execStatus.result.length === 0)) {
                                                $A.enqueueAction(processExecutionStatusAction);
                                            }
                                            else if(execStatus.result.length > 0 && execStatus.result[0].status === 'COMPLETE') {
                                                $A.enqueueAction(testAction);
                                            }
                                            else if((execStatus.result.length > 0 && (execStatus.result[0].status !== 'COMPLETE' || execStatus.result[0].status !== 'INPROCESS'))) {
                                                console.log(execStatus.result[0].status);
                                                component.set('v.portingResult', { responseCode: 500, responseMessage: 'Background process failed to complete. Please try again.' });
                                            }
                                        }
                                    });
                                    testAction.setCallback(this, (result) => {
                                        let res = result.getReturnValue();
                                        let expectedCount = (isBulk ? 2 : 1) + stage1Result.expectedResponseFileCount;
                                        if (res === expectedCount) { //File upload complete from Boomi, Proceed with third stage
                                            let stage3action = component.get("c.getPortabilityCheckResults"); //Call stage 3 process
                                            stage3action.setParams({
                                                apiIdentifier: stage1Result.apiIdentifier,
                                                brandName: stage1Result.brandName,
                                                countryName: selectedCountry.countryName,
                                                portingRequestId: stage1Result.portingRequestId,
                                                isBulk
                                            });
                                            stage3action.setCallback(this, function (result) {
                                                console.log('Stage 3 completed');
                                                if (component.isValid() && state === "SUCCESS") {
                                                    let portingResult = result.getReturnValue();
                                                    component.set('v.portingResult', portingResult);
                                                    component.set('v.totalRecords', portingResult.responseList.length);
                                                    component.set('v.totalPages', Math.ceil(portingResult.responseList.length / component.get('v.recordsPerPage')));
                                                    helper.setCurrentPage(component, 1, component.get('v.recordsPerPage'), component.get('v.portingResult').responseList);
                                                }
                                                else {
                                                    let error = result.getError();
                                                    component.set('v.portingResult', { responseCode: 500, responseMessage: error[0].message });
                                                }
                                            });
                                            $A.enqueueAction(stage3action);
                                            console.log('Stage 3 started');
                                        }
                                        else {
                                            retryCount++;
                                            if(retryCount <= 100) {
                                                $A.enqueueAction(testAction);
                                                console.log('Stage 3 Deferred: Waiting for file upload to complete on server');
                                            }
                                            else {
                                                console.log('Stage 3 Cancelled: Timed out while waiting for results to upload on server.');
                                                component.set('v.portingResult', { responseCode: 500, responseMessage: 'Timed out while waiting for results to upload on server.' });
                                            }
                                        }
                                    });
                                    $A.enqueueAction(processExecutionStatusAction);
                                }
                            }
                            else {
                                let error = result.getError();
                                component.set('v.portingResult', { responseCode: 500, responseMessage: error[0].message });
                            }
                        });
                        $A.enqueueAction(stage2action);
                        console.log('Stage 2 started');
                    }
                }
                else {
                    let error = result.getError();
                    component.set('v.portingResult', { responseCode: 500, responseMessage: error[0].message });
                }
            });
            $A.enqueueAction(action);
            console.log('Stage 1 started');
        }
        catch (error) {
            console.log('ERRRRORRRRR->', error);
        }
    },
    getPortabilityHistory: function (component, helper, pageNumber, pageSize) {
        try {
            let action = component.get("c.getPortabilityHistory");
            action.setParams({
                pageNumber,
                pageSize
            });
            action.setCallback(this, function (result) {
                let state = result.getState();
                if (component.isValid() && state === "SUCCESS") {
                    let portingHistoryResult = result.getReturnValue();
                    if (!portingHistoryResult.isError) {
                        component.set('v.currentPortingHistoryPage',  portingHistoryResult.portingHistoryList);
                        component.set('v.isMaster', portingHistoryResult.isMaster);
                        component.set('v.showRequestingUser', portingHistoryResult.showRequestingUser);
                    } else {
                        console.log('getPortabilityHistory Error ->' + portingHistoryResult.errorMessage);
                    }
                    if(portingHistoryResult.portingHistoryList.length < pageSize) {
                        component.set('v.historyNextButtonDisabled', true);
                    }
                    component.set('v.showHistoryLoading', false);
                }
            });
            $A.enqueueAction(action);
            component.set('v.showHistoryLoading', true);
        }
        catch (error) {
            console.log('ERRRRORRRRR->', error);
        }
    },
    setCurrentPage: function (component, pageNumber, recordsPerPage, data) {
        component.set('v.recordStart', ((pageNumber - 1) * recordsPerPage) + 1);
        component.set('v.recordEnd', (data.length > (pageNumber * recordsPerPage) ? (pageNumber * recordsPerPage) : data.length));
        component.set('v.pageNumber', pageNumber);

        let start = (pageNumber - 1) * recordsPerPage;
        let end = pageNumber * recordsPerPage;
        component.set('v.currentPortingResultPage', data.slice(start, end));
    }
})