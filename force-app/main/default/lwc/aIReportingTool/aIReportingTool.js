import { LightningElement, track, wire } from 'lwc';
import getAIReport from '@salesforce/apex/AIReportingController.getAIReport';
import getPromptSuggestions from '@salesforce/apex/AIReportingController.getPromptSuggestions';
import getAISummary from '@salesforce/apex/AIReportingController.getAISummary';
import chatbotIcon from '@salesforce/resourceUrl/ChatBot';
import sendEmailWithSummary from '@salesforce/apex/AIReportingController.sendEmailWithSummary';
import { NavigationMixin } from 'lightning/navigation';
import getLargeDataMessage from '@salesforce/apex/AIReportingController.getLargeDataMessage';
import aggregateFeaturesDisablementMsg from '@salesforce/label/c.AIReporting_Aggregate_Features_Disablement_Msg';
import chatGreetingMsg from '@salesforce/label/c.AIReporting_Greeting_Msg';
import resetBtnMsg from '@salesforce/label/c.AIReporting_Reset_Button_Msg'
import noResultsMsg from '@salesforce/label/c.AIReporting_No_Results_Msg';
import promptPlaceholdermsg from '@salesforce/label/c.AIReporting_Prompt_Placeholder_Msg';
import promptLabelmsg from '@salesforce/label/c.AIReporting_Prompt_Label';
import canUserExportReports from '@salesforce/apex/AIReportingController.canUserExportReports';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import logFeedback from '@salesforce/apex/AIReportingController.logFeedback';
import getObjectKeywordMap from '@salesforce/apex/AIReportingController.getObjectKeywordMap';

export default class AIReportingTool extends NavigationMixin(LightningElement) {
    @track userQuery = '';
    @track messages = [];
    loading = false;
    messageId = 0;
    @track showSuggestions = false;
    @track promptOptions = [];
    chatbotIconUrl = chatbotIcon;
    @track largeDataNote = '';
    @track pageSize = 10;
    // @track currentPage = 1;
    // @track totalPages = 1;
    @track searchKeyword = '';
    debounceTimeout;
    @track filteredPagedData = [];
    aggregate_feature_disable_msg = aggregateFeaturesDisablementMsg;
    greeting_msg = chatGreetingMsg;
    reset_btn_msg = resetBtnMsg;
    no_results_msg = noResultsMsg;
    prompt_placeholder_msg = promptPlaceholdermsg;
    prompt_label_msg = promptLabelmsg;
    @track canExport = false;
    @track likedMessages = new Set();
    @track dislikedMessages = new Set();
    @track objectKeywordMap = [];

    connectedCallback() {
        getLargeDataMessage()
            .then(result => {
                this.largeDataNote = result;
            })
            .catch(() => {
                this.largeDataNote = 'Note: Features disabled for more than 500 rows.';
            });

        // 🔍 Check export permission
        canUserExportReports()
            .then(result => {
                this.canExport = result;
            })
            .catch(error => {
                this.canExport = false;
            });

        // 🚀 Load objectKeywordMap
        getObjectKeywordMap()
            .then(result => {
                this.objectKeywordMap = result;
            })
            .catch(error => {
                this.objectKeywordMap = [];
            });
    }

    handleSearch(event) {
        const msgId = parseInt(event.target.dataset.id, 10);
        const msg = this.messages.find(m => m.id === msgId);
        if (!msg) return;

        const keyword = event.target.value.toLowerCase();
        msg.searchKeyword = keyword;

        clearTimeout(this.debounceTimeout);
        this.debounceTimeout = setTimeout(() => {
            msg.currentPage = 1;
            this.updatePagedDataByMessage(msgId);
        }, 300);
    }


    handleInputChange(event) {
        this.userQuery = event.target.value;
        if (this.userQuery.length > 2) {
            this.fetchPromptSuggestions(this.userQuery);
        } else {
            this.showSuggestions = false;
        }
    }

    async fetchPromptSuggestions(searchText) {
        try {
            const prompts = await getPromptSuggestions({ searchText });
            this.promptOptions = prompts.map(prompt => ({ label: prompt, value: prompt }));
            this.showSuggestions = this.promptOptions.length > 0;
        } catch (error) {
            this.showSuggestions = false;
        }
    }

    handleShowSuggestions() {
        if (this.promptOptions.length > 0) {
            this.showSuggestions = true;
        }
    }

    handleSuggestionClick(event) {
        this.userQuery = event.target.dataset.value;
        this.showSuggestions = false;
    }

    async handleAsk() {
        if (!this.userQuery.trim()) return;

        //this.addMessage(this.userQuery, 'user-message');
        const currentQuery = this.userQuery;
        this.userQuery = '';
        this.loading = true;

        this.messages.push({
            id: ++this.messageId,
            text: currentQuery,
            class: 'user-message',
            isTable: false,
            liked: false,
            disliked: false,
            showFeedback: false // 🚫 No feedback icons for prompt input
        });


        try {
            const result = await getAIReport({ queryInput: currentQuery });

            // ✅ Safely replace 'expr0' with 'Result' only if present
            let result2 = result.includes('"expr0"') ? result.replace(/"expr0"/g, '"Result"') : result;
            let responseData = JSON.parse(result2);

            // ✅ Only assign 0 if it's actually null in aggregate result
            if (
                responseData != null &&
                responseData.records?.length &&
                responseData.records[0]?.attributes?.type === 'AggregateResult'
            ) {
                const keys = Object.keys(responseData.records[0]).filter(k => k !== 'attributes');
                if (keys.length > 0) {
                    const firstKey = keys[0];
                    if (responseData.records[0][firstKey] == null) {
                        responseData.records[0][firstKey] = 0; // 👈 Set to 0 if null
                    }
                }
            }

            if (responseData.error) {
                if (responseData.error.includes('do not have access')) {
                    this.addMessage(responseData.error, 'bot-error-message', 'report_like', 'Unknown');
                } else {
                    this.addMessage('Kindly specify/rephrase your requirements clearly to obtain the desired results', 'bot-error-message', 'report_like', 'Unknown')
                }
            } else if (responseData.message) {
                this.addMessage(responseData.message, 'bot-message', 'report_like', 'Unknown');
            } else if (responseData.records && Array.isArray(responseData.records)) {
                if (responseData.records.length > 0) {
                    const isAggregate = responseData.records[0]?.attributes?.type === 'AggregateResult';
                    const isEmptyAggregate = isAggregate &&
                        Object.keys(responseData.records[0])
                            .filter(key => key !== 'attributes')
                            .length === 0;
                    // ✅ CASE: Aggregate query returned no usable data
                    if (responseData.records.length === 0 || isEmptyAggregate) {
                        this.addMessage('No results to display — your query returned no data.', 'bot-message', 'report_like', 'Unknown');
                        return;
                    }

                    // ✅ CASE: Valid records to display
                    const fieldLabels = responseData.fieldLabels || {};
                    const columns = Object.keys(responseData.records[0])
                        .filter(key => key !== 'attributes' && key.toLowerCase() !== 'id')
                        .map(field => ({
                            label: fieldLabels[field] || field,
                            fieldName: field,
                            type: 'text',
                            sortable: true
                        }));
                    if (!isAggregate) {
                        const objectType = responseData.records[0]?.attributes?.type;

                        columns.forEach((column, index) => {
                            const fieldNameLower = column.fieldName.toLowerCase();

                            // ✅ For Account, Opportunity, Contact, Lead → make Name clickable
                            if (fieldNameLower === 'name' && objectType !== 'Case') {
                                columns[index] = {
                                    label: column.label,
                                    fieldName: 'recordUrl',
                                    type: 'url',
                                    typeAttributes: {
                                        label: { fieldName: 'Name' },
                                        target: '_blank'
                                    }
                                };
                            }

                            // ✅ For Case object → make CaseNumber clickable
                            if (fieldNameLower === 'casenumber' && objectType === 'Case') {
                                columns[index] = {
                                    label: column.label,
                                    fieldName: 'recordUrl',
                                    type: 'url',
                                    typeAttributes: {
                                        label: { fieldName: 'CaseNumber' },
                                        target: '_blank'
                                    }
                                };
                            }

                            if (fieldNameLower === 'linenumber' && objectType === 'QuoteLineItem') {
                                columns[index] = {
                                    label: column.label,
                                    fieldName: 'recordUrl',
                                    type: 'url',
                                    typeAttributes: {
                                        label: { fieldName: 'LineNumber' },
                                        target: '_blank'
                                    }
                                };
                            }
                        });
                    }

                    const cleanData = responseData.records.map((record) => {

                        const rest = { ...record }; // keep attributes intact
                        if (record.Id) {
                            rest.recordUrl = '/' + record.Id;
                        }
                        return rest;
                    });

                    this.addTableMessage(cleanData, columns, fieldLabels);

                } else {
                    this.addMessage('No records found.', 'bot-message', 'report_like', 'Unknown');
                }
            }
            else {
                this.addMessage('Kindly specify/rephrase your requirements clearly to obtain the desired results', 'bot-message', 'report_like', 'Unknown');
            }
        } catch (error) {
            this.addMessage('Kindly specify/rephrase your requirements clearly to obtain the desired results', 'bot-error-message', 'report_like');
        } finally {
            this.loading = false;
            this.scrollToBottom();
        }
    }

    handleSort(event) {
        const { fieldName, sortDirection } = event.detail;
        const lastMsg = this.messages.slice().reverse().find(m => m.isTable);
        if (lastMsg) {
            let sortedData = [...lastMsg.pagedData];

            sortedData.sort((a, b) => {
                const aValue = a[fieldName] ? a[fieldName].toString().toLowerCase() : '';
                const bValue = b[fieldName] ? b[fieldName].toString().toLowerCase() : '';
                return aValue.localeCompare(bValue);
            });

            if (sortDirection === 'desc') {
                sortedData.reverse();
            }

            lastMsg.pagedData = sortedData;
        }
    }

    async handleSummarize(event) {
        const msgId = event.target.dataset.id;
        const msg = this.messages.find(m => m.id == msgId);
        if (!msg || !msg.tableData.length) {
            return;
        }

        // NEW: Detect object type from the table being summarized
        let objectType = 'Unknown';
        if (msg && msg.tableData && msg.tableData.length > 0) {
            objectType = msg.tableData[0]?.attributes?.type || 'Unknown';
        }

        const loadingMsgId = ++this.messageId;
        this.messages.push({
            id: loadingMsgId,
            text: 'Summarizing data...',
            class: 'bot-message',
            isTable: false,
            showFeedback: false
        });
        this.scrollToBottom();
        this.loading = true;

        try {
            const result = await getAISummary({ tableData: JSON.stringify(msg.tableData) });
            let responseData = JSON.parse(result);

            this.messages = this.messages.filter(m => m.id !== loadingMsgId);

            if (responseData.error) {
                this.addMessage(responseData.error, 'bot-error-message', 'summary_like', 'Unknown');
            } else {
                const formattedSummary = responseData.message
                    .split('\n')
                    .map(line => {
                        const match = line.match(/^(\-?\s?\*\*(.*?)\*\*):(.*)/);
                        if (match) {
                            const label = match[2].trim();
                            const rest = match[3].trim();
                            return `- <strong>${label}</strong>: ${rest}`;
                        }
                        return line;
                    })
                    .join('<br/>');

                this.addMessage(formattedSummary, 'bot-message', 'summary_like', objectType);
            }
        } catch (error) {
            this.messages = this.messages.filter(m => m.id !== loadingMsgId);
            this.addMessage('Oops! Something went wrong.', 'bot-error-message', 'summary_like', 'Unknown');
        } finally {
            this.loading = false;
            this.scrollToBottom();
        }
    }

    handleReset() {
        this.messages = [];
        this.userQuery = '';
        this.searchKeyword = '';
    }

    addMessage(text, className, feedbackType = 'report_like', objectType = 'Unknown') {
        this.messages.push({
            id: ++this.messageId,
            text,
            class: className,
            isTable: false,
            liked: false,
            disliked: false,
            showFeedback: true,
            likeIconName: 'utility:like',
            dislikeIconName: 'utility:dislike',
            feedbackType,
            objectType
        });
        this.scrollToBottom();
    }

    addTableMessage(tableData, columns, fieldLabels, soqlExplanation) {

        const recordCount = tableData.length;
        const label = recordCount === 1 ? 'record' : 'records';
        const isAggregate = tableData[0]?.attributes?.type === 'AggregateResult';
        //const showSummaryButtons = recordCount <= 500;
        const showSummaryButtons = recordCount > 9 && recordCount <= 500;


        let finalColumns = [...columns];

        const objectType = tableData[0]?.attributes?.type;
        const clickableField = objectType === 'Case' ? 'CaseNumber' : 'Name';

        const clickableIndex = finalColumns.findIndex(col => col.fieldName === 'recordUrl');
        // Inside addTableMessage, after you define msg object:
        const currentPage = 1;
        const totalPages = Math.max(1, Math.ceil(tableData.length / this.pageSize));
        const start = 0;
        const end = this.pageSize;
        const pageRecordInfo = `Displaying records ${start + 1} to ${Math.min(end, tableData.length)} of ${tableData.length}`;

        if (clickableIndex > 0) {
            const [clickableColumn] = finalColumns.splice(clickableIndex, 1);
            finalColumns.unshift(clickableColumn);
        }

        const correctedColumns = finalColumns.map(col => {
            const lowerFieldName = col.fieldName.toLowerCase();
            if (fieldLabels && fieldLabels[lowerFieldName]) {
                return { ...col, label: fieldLabels[lowerFieldName] };
            }
            return col;
        });

        this.messages.push({
            id: ++this.messageId,
            tableData,
            pagedData: this.getPagedData(tableData, currentPage),
            columns: correctedColumns,
            isFirstPage: currentPage === 1,
            isLastPage: currentPage === totalPages,
            searchKeyword: '',
            pageRecordInfo,
            currentPage,
            totalPages,
            pageRecordInfo,
            recordCount,
            recordLabel: label,
            isAggregateResult: isAggregate,
            soqlExplanation,
            class: 'bot-message',
            isTable: true,
            showSummaryButtons,
            largeDataNote: (!showSummaryButtons && recordCount > 500 && !isAggregate) ? this.largeDataNote : '',
            liked: false,
            disliked: false,
            showFeedback: true,
            likeIconName: 'utility:like',
            dislikeIconName: 'utility:dislike'
        });

        this.scrollToBottom();
        this.totalPages = Math.ceil(recordCount / this.pageSize);
        this.currentPage = 1;

    }

    getPagedData(tableData, pageNumber) {
        const start = (pageNumber - 1) * this.pageSize;
        const end = start + this.pageSize;
        return tableData.slice(start, end);
    }

    get isFirstPage() {
        return this.currentPage === 1;
    }

    get isLastPage() {
        return this.currentPage === this.totalPages;
    }

    handleNextPage(event) {
        const msgId = event.target.dataset.id;
        const msg = this.messages.find(m => m.id === parseInt(msgId, 10));
        if (msg && msg.currentPage < msg.totalPages) {
            msg.currentPage++;
            this.updatePagedDataByMessage(msgId);
        }
    }

    handlePreviousPage(event) {
        const msgId = event.target.dataset.id;
        const msg = this.messages.find(m => m.id === parseInt(msgId, 10));
        if (msg && msg.currentPage > 1) {
            msg.currentPage--;
            this.updatePagedDataByMessage(msgId);
        }
    }

    handleFirstPage(event) {
        const msgId = event.target.dataset.id;
        const msg = this.messages.find(m => m.id === parseInt(msgId, 10));
        if (msg && msg.currentPage !== 1) {
            msg.currentPage = 1;
            this.updatePagedDataByMessage(msgId);
        }
    }

    handleLastPage(event) {
        const msgId = event.target.dataset.id;
        const msg = this.messages.find(m => m.id === parseInt(msgId, 10));
        if (msg && msg.currentPage !== msg.totalPages) {
            msg.currentPage = msg.totalPages;
            this.updatePagedDataByMessage(msgId);
        }
    }

    getSoqlExplanationLabel(msgId) {
        const msg = this.messages.find(m => m.id == msgId);
        return msg && msg.showSoqlExplanation ? 'Hide Explanation' : 'Show Explanation';
    }

    updatePagedDataByMessage(msgId) {
        const msg = this.messages.find(m => m.id === parseInt(msgId, 10));
        if (!msg) return;

        let filteredData = msg.tableData;

        if (msg.searchKeyword) {
            filteredData = msg.tableData.filter(record => {
                return Object.values(record).some(value =>
                    value && value.toString().toLowerCase().includes(msg.searchKeyword)
                );
            });
        }

        msg.totalPages = Math.max(1, Math.ceil(filteredData.length / this.pageSize));

        if (msg.currentPage > msg.totalPages) {
            msg.currentPage = msg.totalPages;
        }

        const start = (msg.currentPage - 1) * this.pageSize;
        const end = start + this.pageSize;
        msg.pagedData = filteredData.slice(start, end);
        msg.noResultsFound = filteredData.length === 0 && this.searchKeyword;



        // ✅ Compute derived values
        msg.isFirstPage = msg.currentPage === 1;
        msg.isLastPage = msg.currentPage === msg.totalPages;

        // ✅ Calculate display text for "Displaying records x to y of z"
        const startRecord = start + 1;
        let endRecord = msg.currentPage * this.pageSize;
        if (endRecord > filteredData.length) {
            endRecord = filteredData.length;
        }
        msg.pageRecordInfo = `Displaying records ${startRecord} to ${endRecord} of ${filteredData.length}`;
    }



    get currentPagedData() {
        const start = (this.currentPage - 1) * this.pageSize;
        const end = start + this.pageSize;
        return this.filteredPagedData.slice(start, end);
    }

    get noResultsFound() {
        return this.filteredPagedData.length === 0 && this.searchKeyword;
    }

    handleClearSearch(event) {
        const msgId = parseInt(event.target.dataset.id, 10);
        const msg = this.messages.find(m => m.id === msgId);
        if (!msg) return;

        msg.searchKeyword = '';
        msg.currentPage = 1;
        this.updatePagedDataByMessage(msgId);
    }


    getPagedData(tableData, pageNumber) {
        const start = (pageNumber - 1) * this.pageSize;
        const end = start + this.pageSize;
        return tableData.slice(start, end);
    }

    getPageData(msgId) {
        const msg = this.messages.find(m => m.id === parseInt(msgId, 10));
        if (!msg) return [];

        const start = (this.currentPage - 1) * this.pageSize;
        const end = start + this.pageSize;
        return msg.tableData.slice(start, end);
    }

    getPageRecordInfo(msg) {
        const startRecord = ((msg.currentPage - 1) * this.pageSize) + 1;
        let endRecord = msg.currentPage * this.pageSize;
        const totalRecords = msg.recordCount;

        if (endRecord > totalRecords) {
            endRecord = totalRecords;
        }

        return `Displaying records ${startRecord} to ${endRecord} of ${totalRecords}`;
    }


    get hasMultiplePages() {
        return this.totalPages > 1;
    }

    scrollToBottom() {
        setTimeout(() => {
            const container = this.template.querySelector('.chat-messages');
            container.scrollTop = container.scrollHeight;
        }, 100);
    }

    downloadExcel(event) {
        const msgId = event.target.dataset.id;
        const msg = this.messages.find(m => m.id == msgId);
        if (!msg || !msg.tableData.length) {
            return;
        }

        let excelContent = '\uFEFF';
        const headers = msg.columns.map(col => col.label).join('\t');
        excelContent += headers + '\n';

        msg.tableData.forEach(row => {
            excelContent += msg.columns.map(col => row[col.fieldName]).join('\t') + '\n';
        });

        this.downloadFile(excelContent, 'AI_Report.xls');
    }

    toggleSoqlExplanation(event) {
        const msgId = event.target.dataset.id;
        const msg = this.messages.find(m => m.id == msgId);
        if (msg) {
            msg.showSoqlExplanation = !msg.showSoqlExplanation;
            msg.soqlExplanationLabel = msg.showSoqlExplanation ? 'Hide Explanation' : 'Show Explanation';
        }
    }

    downloadFile(content, fileName) {
        const encodedUri = encodeURI('data:text/csv;charset=utf-8,' + content);
        const link = document.createElement('a');
        link.setAttribute('href', encodedUri);
        link.setAttribute('download', fileName);
        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);
    }

    async handleSendEmail(event) {
        const msgId = event.target.dataset.id;
        const msg = this.messages.find(m => m.id == msgId);

        if (!msg || !msg.tableData || msg.tableData.length === 0) {
            this.addMessage('⚠️ Cannot send email: No data to send.', 'bot-error-message', 'report_like', 'Unknown');
            return;
        }

        this.loading = true;
        try {
            const jsonData = JSON.stringify(msg.tableData);
            const result = await sendEmailWithSummary({ tableDataJson: jsonData });

            if (result === 'Success') {
                this.addMessage('📧 Email sent successfully!', 'bot-message', 'report_like', 'Unknown');
            } else {
                this.addMessage('⚠️ Failed to send email: ' + result, 'bot-error-message', 'report_like', 'Unknown');
            }
        } catch (error) {
            this.addMessage('⚠️ An error occurred while sending the email.', 'bot-error-message', 'report_like', 'Unknown');
        } finally {
            this.loading = false;
            this.scrollToBottom();
        }
    }

    // Add toggle like method
    async toggleLike(event) {
        const msgId = parseInt(event.target.dataset.id, 10);
        const msg = this.messages.find(m => m.id === msgId);
        if (msg) {
            msg.liked = !msg.liked;
            msg.disliked = false;
            msg.showFeedback = false; // ✅ Hide buttons after click
            if (msg.liked) {
                this.likedMessages.add(msgId);
                this.dislikedMessages.delete(msgId);
                // 🚀 Log feedback to Apex
                try {
                    await logFeedback({
                        feedbackType: msg.feedbackType || 'report_like',
                        objectName: this.getFeedbackTopic(msg)
                    });
                } catch (e) {
                    console.error('Logging like feedback failed', e);
                }

                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Feedback Received',
                        message: 'You liked this message.',
                        variant: 'success'
                    })
                );
            } else {
                this.likedMessages.delete(msgId);
            }
        }
    }

    async toggleDislike(event) {
        const msgId = parseInt(event.target.dataset.id, 10);
        const msg = this.messages.find(m => m.id === msgId);
        if (msg) {
            msg.disliked = !msg.disliked;
            msg.liked = false;
            msg.showFeedback = false; // ✅ Hide buttons after click
            if (msg.disliked) {
                this.dislikedMessages.add(msgId);
                this.likedMessages.delete(msgId);

                let feedbackType = msg.feedbackType;
                if (feedbackType === 'summary_like') {
                    feedbackType = 'summary_dislike';
                } else if (feedbackType === 'report_like') {
                    feedbackType = 'report_dislike';
                } else if (!feedbackType) {
                    feedbackType = 'report_dislike'; // fallback
                }

                // 🚀 Log feedback to Apex
                try {
                    await logFeedback({
                        feedbackType: feedbackType,
                        objectName: this.getFeedbackTopic(msg)
                    });
                } catch (e) {
                    console.error('Logging dislike feedback failed', e);
                }

                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Feedback Received',
                        message: 'You disliked this message.',
                        variant: 'warning'
                    })
                );
            } else {
                this.dislikedMessages.delete(msgId);
            }
        }
    }


    getFeedbackTopic(msg) {
        if (msg.objectType && msg.objectType !== 'Unknown') {
            return msg.objectType;
        }
        if (msg.columns && msg.columns.length > 0) {
            const objectType = msg.tableData?.[0]?.attributes?.type;
            if (objectType) {
                return objectType;
            }
        }

        // Fallback: use objectKeywordMap (no more hardcoding!)
        if (msg.text && this.objectKeywordMap.length > 0) {
            const text = msg.text.toLowerCase();

            for (const entry of this.objectKeywordMap) {
                const objectName = entry.objectName;
                const keywords = entry.keywords.split(',').map(k => k.trim().toLowerCase());

                for (const keyword of keywords) {
                    if (text.includes(keyword)) {
                        return objectName;
                    }
                }
            }
        }

        return 'Unknown';
    }

}