import { LightningElement, track } from 'lwc';
import sendMessageToDialogflow from '@salesforce/apex/DialogflowService1.sendMessage';
import BOT_IMG from '@salesforce/resourceUrl/botIcon';
import getCaseIdByCaseNumber from '@salesforce/apex/DialogflowService1.getCaseIdByCaseNumber';
import getKnowledgeIdByArticleNumber from '@salesforce/apex/DialogflowService1.getKnowledgeIdByArticleNumber';

export default class DialogflowChatbot extends LightningElement {
    @track conversation = [];
    @track messageInput = '';
    @track isLoading = false;

    botImage = BOT_IMG;

    handleChange(event) {
        this.messageInput = event.target.value;
    }

    handleKeyUp(event) {
        if (event.keyCode === 13) {
            this.handleSendMessage();
        }
    }

    async handleSendMessage() {
        if (!this.messageInput.trim()) return;

        const userMessageText = this.messageInput;
        const userMessage = {
            id: 'user-' + this.conversation.length,
            role: 'user',
            text: userMessageText,
            containerClass: 'slds-chat-message slds-chat-message__text_outbound user-message',
            textClass: 'slds-chat-message__text slds-chat-message__text_outbound',
            isBot: false
        };
        this.conversation = [...this.conversation, userMessage];

        // Clear the input
        this.messageInput = '';
        this.isLoading = true;

        // Add "Typing..." placeholder
        const tempBotMessageId = 'typing-' + this.conversation.length;
        const tempBotMessage = {
            id: tempBotMessageId,
            role: 'assistant',
            text: 'Typing...',
            containerClass: 'slds-chat-message slds-chat-message__text_inbound',
            textClass: 'slds-chat-message__text slds-chat-message__text_inbound',
            isBot: true,
            messageText: 'Typing...'
        };
        this.conversation = [...this.conversation, tempBotMessage];

        try {
            const response = await sendMessageToDialogflow({ userMessage: userMessageText });

            let assistantMessageText = response || 'Some error occurred: please retry';

            // Remove trailing comma
            assistantMessageText = assistantMessageText.replace(/,\s*$/gm, '');

            // Convert line breaks to <br/>
            assistantMessageText = assistantMessageText.replace(/\n/g, '<br/>');

            // Replace case numbers with links
            const caseRegex = /(case(?: number| id)?[^\d]*)(\d{6,})/gi;
            const matches = [...assistantMessageText.matchAll(caseRegex)];

            for (let match of matches) {
                const fullMatch = match[0];
                const prefix = match[1];
                const caseNumber = match[2];

                try {
                    const caseId = await getCaseIdByCaseNumber({ caseNumber });
                    const caseLink = `/lightning/r/Case/${caseId}/view`;
                    const replacement = `${prefix}<a href="${caseLink}" target="_blank">${caseNumber}</a>`;
                    assistantMessageText = assistantMessageText.replace(fullMatch, replacement);
                } catch (lookupError) {
                    console.warn(`Case lookup failed for ${caseNumber}:`, lookupError);
                }
            }

            // Replace article numbers with links (Title Case "Article Number")
            const articleNumberRegex = /article number[^0-9]*([0-9]{6,})/gi;
            const articleMatches = [...assistantMessageText.matchAll(articleNumberRegex)];

            for (let match of articleMatches) {
                const fullMatch = match[0];
                const articleNumber = match[1];
                console.log("Matched article number:", articleNumber);

                try {
                    const articleId = await getKnowledgeIdByArticleNumber({ articleNumber });
                    const articleLink = `/lightning/r/Knowledge__kav/${articleId}/view`;
                    const replacement = `Article Number <a href="${articleLink}" target="_blank">${articleNumber}</a>`;
                    assistantMessageText = assistantMessageText.replace(fullMatch, replacement);
                } catch (lookupError) {
                    console.warn(`Article lookup failed for ${articleNumber}:`, lookupError);
                }
            }

            // Replace "Typing..." message with actual response
            this.conversation = this.conversation.map(msg => {
                if (msg.id === tempBotMessageId) {
                    return {
                        ...msg,
                        id: 'assistant-' + this.conversation.length,
                        text: assistantMessageText,
                        messageText: assistantMessageText
                    };
                }
                return msg;
            });

        } catch (error) {
            console.error('Error:', error);
        } finally {
            this.isLoading = false;
            this.scrollChatToBottom();
        }
    }

    handleResetChat() {
        this.conversation = [];
    }

    renderedCallback() {
        this.scrollChatToBottom();
        this.conversation.forEach(msg => {
            if (msg.isBot) {
                const el = this.template.querySelector(`div[data-id="${msg.id}"]`);
                if (el) {
                    el.innerHTML = msg.messageText;
                }
            }
        });
    }

    scrollChatToBottom() {
        const chatEl = this.template.querySelector('.slds-chat.chat');
        if (chatEl) {
            chatEl.scrollTop = chatEl.scrollHeight;
        }
    }
}