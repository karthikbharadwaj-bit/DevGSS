import { LightningElement, api, track } from 'lwc';
import email from '@salesforce/resourceUrl/emailIcon';
import comment from '@salesforce/resourceUrl/commentIcon';
import jiraIcon from '@salesforce/resourceUrl/jiraIcon';
import chatIcon from '@salesforce/resourceUrl/chatIcon';
import feedSummaryIcon from '@salesforce/resourceUrl/feedSummaryIcon';
import getBasics from '@salesforce/apex/CaseAIInsightsProcessor.getBasics';
import getCaseBrand from '@salesforce/apex/CaseAIInsightsProcessor.getCaseBrand';
import getHighRiskConfig from '@salesforce/apex/CaseAIInsightsProcessor.getHighRiskConfig';
import hasChatTranscriptPermissionSet from '@salesforce/apex/CaseAIInsightsProcessor.hasChatTranscriptPermissionSet';
import getFeatureToggle from '@salesforce/apex/CaseAIInsightsProcessor.getFeatureToggle';
import hasRingCentralMobileIntervention from '@salesforce/apex/CaseAIInsightsProcessor.hasRingCentralMobileIntervention';
import getCaseRecordTypeDeveloperName from '@salesforce/apex/CaseAIInsightsProcessor.getCaseRecordTypeDeveloperName';
import isDimeloSyncEnabled from '@salesforce/apex/CaseAIInsightsProcessor.isDimeloSyncEnabled';
import hasSupportAgent from '@salesforce/customPermission/Support_Agent_AI_GCP';
import getJiraAccessContext from '@salesforce/apex/CreateJiraController.getJiraAccessContext';

/** Must match Case record type API Developer Names in the org */
const RT_SUPPORT_CHAT = 'Support_Chat';

export default class CaseSummaryTabOnly extends LightningElement {
    @api recordId;
    
    hasSupportAgent = hasSupportAgent;

    jiraAccessEvaluated = false;

    @track emailsLoading = false;
    @track commentsLoading = false;
    @track jiraCommentLoading = false;
    @track chatTranscriptLoading = false;
    @track feedSummaryLoading = false;

    emailLoaded = false;
    commentLoaded = false;
    jiraCommentLoaded = false;
    chatTranscriptLoaded = false;
    feedSummaryLoaded = false;
    
    // Dynamic permission set check for Chat Transcript
    @track hasChatTranscriptPermission = false;
    
    // Feature toggle for Chat Transcript Summary
    @track chatTranscriptSummaryEnabled = false;
    
    // User dimelo_sync checkbox
    @track userDimeloSyncEnabled = false;
    
    // RingCentral Mobile source check
    @track hasRingCentralMobile = false;

    // Feed Summary controlled-rollout flags (from GCP_Feature_Toggle__c hierarchy CS)
    @track feedSummaryEnabled = false;
    @track feedSummaryRecordType = '';
    
    /** Case RecordType.DeveloperName from Apex — drives record-type getters below */
    @track caseRecordTypeDeveloperName = '';

    // header fields
    caseNumber = '';
    status = '';
    subject = '';
    @track jiraCase = '';
    // High Risk brand config (mirrors caseAISummary logic)
    caseBrand = '';
    highRiskBrands = [];
    escalationEnabled = false;
    _configLoaded = false;
    @track _canViewJiraComments = false;

    async loadHeaderViaApex() {
        try {
            const rec = await getBasics({ caseId: this.recordId });
            this.applyRecord({
                number: rec?.CaseNumber,
                status: rec?.Status,
                subject: rec?.Subject,
                jiraCase: rec?.Jira_Case__c
            });
        } catch (e) {
            // minimal safe defaults (keeps UI visible)
            this.caseNumber = '';
            this.status = '';
            this.subject = '';
            this.caseRecordTypeDeveloperName = '';
            this.jiraCase = '';
        }
    }

    applyRecord(v) {
        this.caseNumber = v.number || '';
        this.status = v.status || '';
        this.subject = v.subject || 'Case';
        this.jiraCase = v.jiraCase || '';
    }

    @track cards = [
        {
            id: 'email',
            icon: email,
            title: 'Summary of Email Messages',
            expanded: false,
            iconName: 'utility:chevronright',
            contentClass: 'summary-content slds-hide',
            isEmail: true,
            isComment: false,
            isJiraComment: false,
            isChatTranscript: false
        },
        {
            id: 'comment',
            icon: comment,
            title: 'Summary of Case Comments',
            expanded: false,
            iconName: 'utility:chevronright',
            contentClass: 'summary-content slds-hide',
            isEmail: false,
            isComment: true,
            isJiraComment: false,
            isChatTranscript: false
        },
        {
            id: 'jiraComment',
            icon: jiraIcon,
            title: 'Summary of Jira',
            expanded: false,
            iconName: 'utility:chevronright',
            contentClass: 'summary-content slds-hide',
            isEmail: false,
            isComment: false,
            isJiraComment: true,
            isChatTranscript: false
        },
        {
            id: 'chatTranscript',
            icon: chatIcon,
            title: 'Summary of Support Chat Transcripts',
            expanded: false,
            iconName: 'utility:chevronright',
            contentClass: 'summary-content slds-hide',
            isEmail: false,
            isComment: false,
            isJiraComment: false,
            isChatTranscript: true,
            isFeedSummary: false
        },
        {
            id: 'feedSummary',
            icon: feedSummaryIcon,
            title: 'Summary of Case Feed',
            expanded: false,
            iconName: 'utility:chevronright',
            contentClass: 'summary-content slds-hide',
            isEmail: false,
            isComment: false,
            isJiraComment: false,
            isChatTranscript: false,
            isFeedSummary: true
        }
    ];
    
    connectedCallback() {
        this.loadHeaderViaApex();
        this.checkChatTranscriptPermission();
        this.checkChatTranscriptFeatureToggle();
        this.checkDimeloSyncEnabled();
        this.checkRingCentralMobileSource();
        this.loadCaseRecordTypeDeveloperName();
        this.loadHighRiskConfig();
        this.loadCaseBrand();
        this.loadJiraAccessContext();
    }

    /**
     * Fetch Case brand imperatively — @wire(getRecord) cannot resolve
     * cross-object fields (Case.Account.RC_Brand__c) in VF page / Lightning Out context.
     */
    async loadCaseBrand() {
        try {
            this.caseBrand = await getCaseBrand({ caseId: this.recordId }) || '';
        } catch (e) {
            console.error('[CaseSummaryTabOnly] Error loading case brand:', e);
            this.caseBrand = '';
        }
    }

    async loadJiraAccessContext() {
        if (!this.recordId) return;

        // FIX: reset the loaded guard so load() fires again if card re-mounts
        this.jiraCommentLoaded = false;

        try {
            const ctx = await getJiraAccessContext({ caseId: this.recordId });
            this._canViewJiraComments = ctx?.canViewComments === true;
        } catch (e) {
            this._canViewJiraComments = false;
        } finally {
            this.jiraAccessEvaluated = true;
        }
    }

    async checkDimeloSyncEnabled() {
        try {
            this.userDimeloSyncEnabled = await isDimeloSyncEnabled();
        } catch (e) {
            console.warn('Failed to check Dimelo sync enabled:', e);
            this.userDimeloSyncEnabled = false;
        }
    }
    
    /**
     * Check if case brand matches any configured High Risk brands
     * AND the escalation feature is enabled for the running user.
     * Both conditions must be true to show the caseBannerAtt component.
     * Brands are configurable via GCP_Feature_Toggle__c.High_Risk_Brands__c
     * Access is controlled via GCP_Feature_Toggle__c.High_Risk_Escalation_Switch__c
     */
    get isHighRiskBrandCase() {
        if (!this.escalationEnabled) {
            return false;
        }
        const currentBrand = (this.caseBrand || '').toLowerCase();
        return this.highRiskBrands.some(configuredBrand =>
            currentBrand.includes(configuredBrand)
        );
    }

    /**
     * Load High Risk brands from GCP_Feature_Toggle__c Custom Setting
     */
    async loadHighRiskConfig() {
        try {
            const config = await getHighRiskConfig();
            this.escalationEnabled = config?.escalationEnabled === true;
            const brandsStr = config?.brands || '';
            this.highRiskBrands = brandsStr
                .split(',')
                .map(b => b.trim().toLowerCase())
                .filter(b => b.length > 0);
        } catch (e) {
            console.error('[CaseSummaryTabOnly] Error loading High Risk config:', e);
            this.escalationEnabled = false;
            this.highRiskBrands = [];
        } finally {
            this._configLoaded = true;
        }
    }
    
    async checkChatTranscriptPermission() {
        try {
            this.hasChatTranscriptPermission = await hasChatTranscriptPermissionSet();
        } catch (e) {
            console.warn('Failed to check Chat Transcript permission sets:', e);
            this.hasChatTranscriptPermission = false;
        }
    }
    
    async checkChatTranscriptFeatureToggle() {
        try {
            const result = await getFeatureToggle();
            this.chatTranscriptSummaryEnabled = result?.Chat_Transcript_Summary_Switch__c || false;
            // Feed Summary flags — read from same hierarchy CS call to avoid extra Apex round-trip
            this.feedSummaryEnabled    = result?.Feed_Summary_Switch__c         || false;
            this.feedSummaryRecordType = result?.Feed_Summary_Record_Type__c    || '';
        } catch (e) {
            console.warn('Failed to check feature toggles:', e);
            this.chatTranscriptSummaryEnabled = false;
            this.feedSummaryEnabled    = false;
            this.feedSummaryRecordType = '';
        }
    }
    
    async checkRingCentralMobileSource() {
        try {
            this.hasRingCentralMobile = await hasRingCentralMobileIntervention({ caseId: this.recordId });
        } catch (e) {
            console.warn('Failed to check RingCentral Mobile intervention:', e);
            this.hasRingCentralMobile = false;
        }
    }
    
    async loadCaseRecordTypeDeveloperName() {
        if (!this.recordId) {
            this.caseRecordTypeDeveloperName = '';
            return;
        }
        try {
            const name = await getCaseRecordTypeDeveloperName({ caseId: this.recordId });
            this.caseRecordTypeDeveloperName = name || '';
        } catch (e) {
            console.warn('[CaseSummaryTabOnly] Failed to load Case RecordType.DeveloperName:', e);
            this.caseRecordTypeDeveloperName = '';
        }
    }

   get showJiraCommentCard() {
        return this._canViewJiraComments;
    }

    get isSupportChat() {
        return this.caseRecordTypeDeveloperName === RT_SUPPORT_CHAT;
    }
    
    get filteredCards() {
        return this.cards.filter(card => {
            if (card.id === 'jiraComment') {
                return this.showJiraCommentCard;
            }
            if (card.id === 'chatTranscript') {
                return this.showChatTranscript;
            }
            if (card.id === 'feedSummary') {
                return this.showFeedSummary;
            }
            return true;
        });
    }

    toggleCard(event) {
        const id = event.currentTarget.dataset.id;

        this.cards = this.cards.map(c => {
            if (c.id === id) {
                const expanded = !c.expanded;
                return {
                    ...c,
                    expanded,
                    iconName: expanded ? 'utility:chevrondown' : 'utility:chevronright',
                    contentClass: expanded ? 'summary-content' : 'summary-content slds-hide'
                };
            }
            return c;
        });

        if (id === 'email') {
            if (this.cards.find(c => c.id === 'email')?.expanded && !this.emailLoaded) {
                const cmp = this.template.querySelector('c-email-summary');
                if (cmp && typeof cmp.load === 'function') cmp.load();
                this.emailLoaded = true;
            }
            if (!this.cards.find(c => c.id === 'email')?.expanded) this.emailsLoading = false;
        }

        if (id === 'comment') {
            if (this.cards.find(c => c.id === 'comment')?.expanded && !this.commentLoaded) {
                const cmp = this.template.querySelector('c-case-comment-summary');
                if (cmp && typeof cmp.load === 'function') cmp.load();
                this.commentLoaded = true;
            }
            if (!this.cards.find(c => c.id === 'comment')?.expanded) this.commentsLoading = false;
        }

        if (id === 'jiraComment') {
            const card = this.cards.find(c => c.id === 'jiraComment');
            if (card?.expanded && !this.jiraCommentLoaded) {
                setTimeout(() => {
                    const cmp = this.template.querySelector('c-jira-comment-summary');
                    if (cmp?.load) cmp.load();
                }, 0);
                this.jiraCommentLoaded = true;
            }
            if (!card?.expanded) this.jiraCommentLoading = false;
        }

        if (id === 'chatTranscript') {
            if (this.cards.find(c => c.id === 'chatTranscript')?.expanded && !this.chatTranscriptLoaded) {
                // Use setTimeout to ensure DOM is updated before querying
                setTimeout(() => {
                    const cmp = this.template.querySelector('c-chat-transcript-summary');
                    console.log('Parent: Looking for chat-transcript-summary component:', cmp);
                    if (cmp && typeof cmp.load === 'function') {
                        console.log('Parent: Calling load() on chat-transcript-summary');
                        cmp.load();
                    } else {
                        console.warn('Parent: chat-transcript-summary component not found or load method missing');
                    }
                }, 0);
                this.chatTranscriptLoaded = true;
            }
            if (!this.cards.find(c => c.id === 'chatTranscript')?.expanded) this.chatTranscriptLoading = false;
        }

        if (id === 'feedSummary') {
            if (this.cards.find(c => c.id === 'feedSummary')?.expanded && !this.feedSummaryLoaded) {
                setTimeout(() => {
                    const cmp = this.template.querySelector('c-case-feed-summary');
                    if (cmp && typeof cmp.load === 'function') {
                        cmp.load();
                    } else {
                        console.warn('Parent: case-feed-summary component not found or load method missing');
                    }
                }, 0);
                this.feedSummaryLoaded = true;
            }
            if (!this.cards.find(c => c.id === 'feedSummary')?.expanded) this.feedSummaryLoading = false;
        }
    }

    handleCommentsLoading() {
        this.commentsLoading = true; 
    }
    handleCommentsLoaded() {
        this.commentsLoading = false; 
    }
    handleEmailLoading() {
        this.emailsLoading = true; 
    }
    handleEmailLoaded() {
        this.emailsLoading = false; 
    }
    
    handleArticlesTabActive() {
        setTimeout(() => {
            this.tryAutoOpenArticles();
        }, 0);
    }

    tryAutoOpenArticles(retryCount = 0) {
        const cmp = this.template.querySelector('c-get-knowledge-articles-for-g-c-p');
        if (cmp && typeof cmp.autoOpenArticles === 'function') {
            cmp.autoOpenArticles();
        } else if (retryCount < 3) {
            setTimeout(() => {
                this.tryAutoOpenArticles(retryCount + 1);
            }, 50 * (retryCount + 1));
        }
    }
    handleJiraCommentLoading() {
        console.log('Parent: Received jcsloading event');
        this.jiraCommentLoading = true;
    }
    handleJiraCommentLoaded() {
        console.log('Parent: Received jcsloaded event');
        this.jiraCommentLoading = false;
    }
    handleChatTranscriptLoading() {
        console.log('Parent: Received ctsloading event');
        this.chatTranscriptLoading = true;
    }
    handleChatTranscriptLoaded() {
        console.log('Parent: Received ctsloaded event');
        this.chatTranscriptLoading = false;
    }
    handleFeedSummaryLoading() {
        this.feedSummaryLoading = true;
    }
    handleFeedSummaryLoaded() {
        this.feedSummaryLoading = false;
    }

    get statusPillClass() {
        const s = (this.status || '').toLowerCase();
        return `status-pill ${s}`;
    }


    get showChatTranscript() {
        // Show Chat Transcript card only if:
        // 1. User has one of the permission sets configured in Chat_Transcript_Summary_Permission_Sets__c field
        // 2. Case RecordType is  Support - Chat.
        // 3. Chat Transcript Summary switch is enabled for user in GCP_Feature_Toggle__c custom setting
        // 4. User has dimelo_sync__c checkbox enabled
        // 5. Case has an Intervention with Dimelo__source_name__c present in Feature toggle CS channel name field
        return this.hasChatTranscriptPermission && this.isSupportChat && this.chatTranscriptSummaryEnabled && this.userDimeloSyncEnabled && this.hasRingCentralMobile;
    }

    get showFeedSummary() {
        // Show Feed Summary card only if:
        // 1. Feed_Summary_Switch__c is true for the user (hierarchy CS — user-level record overrides org-level)
        // 2. Case RecordType DeveloperName is in the comma-separated Feed_Summary_Record_Type__c CS field
        const allowed = (this.feedSummaryRecordType || '')
            .split(',')
            .map(s => s.trim())
            .filter(Boolean);
        return this.feedSummaryEnabled && allowed.includes(this.caseRecordTypeDeveloperName);
    } 

}