import { createElement } from 'lwc';
import CompanyIntelligence from 'c/companyIntelligence';
import requestCompanyIntelligence from '@salesforce/apex/CompanyIntelligenceController.requestCompanyIntelligence';

jest.mock(
    '@salesforce/apex/CompanyIntelligenceController.requestCompanyIntelligence',
    () => ({ default: jest.fn() }),
    { virtual: true }
);

const RECORD_ID = '006000000000001AAA';
const GOOGLE_REDIRECT_URL =
    'https://vertexaisearch.cloud.google.com/grounding-api-redirect/private-token';

function successfulResponse(overrides = {}) {
    return {
        success: true,
        statusCode: 200,
        intelligence: {
            sources: [
                {
                    index: 9,
                    displayLabel: 'nine.example',
                    title: 'Nine',
                    url: `${GOOGLE_REDIRECT_URL}-nine`,
                    domain: 'nine.example'
                },
                {
                    index: 0,
                    displayLabel: 'zero.example',
                    title: 'Zero',
                    url: `${GOOGLE_REDIRECT_URL}-zero`,
                    domain: 'zero.example'
                }
            ],
            derivedInformation: [
                { text: 'A claim supported by source nine', sourceIndices: [9] }
            ],
            webSearchQueries: ['Example latest company announcements'],
            summary: {
                companySnapshot: ['Public software company'],
                latestCompanyAnnouncements: ['Launched a new service'],
                executiveLeadershipAnnouncements: ['Named a new executive'],
                businessAndFinancialSignals: ['Reported revenue growth'],
                competitiveAndMarketContext: ['Competes in a growing market'],
                opportunityRelevance: ['Renewal aligns with public strategy'],
                informationGaps: ['No reliable regional breakdown found']
            },
            searchEntryPoint: {
                renderedContent:
                    '<style>.suggestion{color:blue}</style><svg></svg><a href="https://google.com">Search</a>'
            },
            ...overrides
        }
    };
}

function deferred() {
    let resolve;
    let reject;
    const promise = new Promise((promiseResolve, promiseReject) => {
        resolve = promiseResolve;
        reject = promiseReject;
    });
    return { promise, resolve, reject };
}

async function flushPromises() {
    await Promise.resolve();
    await Promise.resolve();
    await Promise.resolve();
}

async function createComponent(recordId = RECORD_ID) {
    const element = createElement('c-company-intelligence', {
        is: CompanyIntelligence
    });
    element.recordId = recordId;
    document.body.appendChild(element);
    await flushPromises();
    return element;
}

describe('companyIntelligence', () => {
    beforeEach(() => {
        requestCompanyIntelligence.mockResolvedValue(successfulResponse());
    });

    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        jest.clearAllMocks();
    });

    it('loads independently when placed on an Opportunity record page', async () => {
        const element = await createComponent();

        expect(requestCompanyIntelligence).toHaveBeenCalledTimes(1);
        expect(requestCompanyIntelligence).toHaveBeenCalledWith({ recordId: RECORD_ID });
        expect(element.shadowRoot.textContent).toContain('Public software company');
    });

    it('prevents duplicate lifecycle requests while loading', async () => {
        const response = deferred();
        requestCompanyIntelligence.mockReturnValue(response.promise);
        const element = await createComponent();

        element.recordId = RECORD_ID;
        await flushPromises();

        expect(requestCompanyIntelligence).toHaveBeenCalledTimes(1);
        expect(element.shadowRoot.querySelector('[data-testid="loading"]')).not.toBeNull();

        response.resolve(successfulResponse());
        await flushPromises();
    });

    it('renders a safe service error', async () => {
        requestCompanyIntelligence.mockResolvedValue({
            success: false,
            statusCode: 429,
            message: 'Company Intelligence is temporarily busy. Try again in a few minutes.'
        });
        const element = await createComponent();

        expect(element.shadowRoot.querySelector('[data-testid="error"]')).not.toBeNull();
        expect(element.shadowRoot.textContent).toContain('temporarily busy');
    });

    it('renders summary sections in the required order', async () => {
        const element = await createComponent();

        const sectionElements = [
            ...element.shadowRoot.querySelectorAll('[data-section-key]')
        ];
        const titles = sectionElements.map((section) => section.label);
        expect(titles).toEqual([
            'Company Snapshot',
            'Latest Company Announcements',
            'Executive Leadership Announcements',
            'Business and Financial Signals',
            'Competitive and Market Context',
            'Opportunity Relevance',
            'Information Gaps'
        ]);
        expect(
            element.shadowRoot.querySelector('lightning-accordion').activeSectionName
        ).toBe('companySnapshot');
    });

    it('hides empty sections and shows the concise empty state', async () => {
        requestCompanyIntelligence.mockResolvedValue(
            successfulResponse({
                sources: [],
                derivedInformation: [],
                webSearchQueries: [],
                summary: {},
                searchEntryPoint: { renderedContent: '' }
            })
        );
        const element = await createComponent();

        expect(element.shadowRoot.querySelectorAll('[data-section-key]')).toHaveLength(0);
        expect(element.shadowRoot.querySelector('[data-testid="empty"]')).not.toBeNull();
        expect(element.shadowRoot.textContent).toContain('No reliable public information found.');
    });

    it('maps claims by explicit source index and hides raw URLs from text', async () => {
        const element = await createComponent();

        const claimSource = element.shadowRoot.querySelector(
            '.claims [data-source-index="9"]'
        );
        expect(claimSource.textContent).toBe('nine.example');
        expect(claimSource.href).toBe(`${GOOGLE_REDIRECT_URL}-nine`);
        expect(claimSource.target).toBe('_blank');
        expect(claimSource.rel).toBe('noopener noreferrer');
        expect(element.shadowRoot.querySelector('.claims [data-source-index="0"]')).toBeNull();
        expect(element.shadowRoot.textContent).not.toContain(GOOGLE_REDIRECT_URL);
    });

    it('keeps searches collapsed and reports the Search Suggestions blocker', async () => {
        const element = await createComponent();

        const searches = element.shadowRoot.querySelector('.searches');
        expect(searches.open).toBe(false);
        expect(searches.textContent).toContain('Example latest company announcements');
        expect(
            element.shadowRoot.querySelector('[data-testid="search-suggestions-blocker"]')
        ).not.toBeNull();
        expect(element.shadowRoot.querySelector('style')).toBeNull();
        expect(element.shadowRoot.querySelector('a[href="https://google.com"]')).toBeNull();
    });

    it('reports the Search Suggestions blocker when it is the only returned content', async () => {
        requestCompanyIntelligence.mockResolvedValue(
            successfulResponse({
                sources: [],
                derivedInformation: [],
                webSearchQueries: [],
                summary: {},
                searchEntryPoint: { renderedContent: '<style></style><svg></svg>' }
            })
        );
        const element = await createComponent();

        expect(
            element.shadowRoot.querySelector('[data-testid="search-suggestions-blocker"]')
        ).not.toBeNull();
        expect(element.shadowRoot.querySelector('[data-testid="empty"]')).toBeNull();
        expect(element.shadowRoot.querySelector('style')).toBeNull();
        expect(element.shadowRoot.querySelector('svg')).toBeNull();
    });

    it('refreshes independently and coalesces duplicate refresh clicks', async () => {
        const element = await createComponent();
        const refreshResponse = deferred();
        requestCompanyIntelligence.mockReturnValue(refreshResponse.promise);

        const refreshButton = element.shadowRoot.querySelector('[data-testid="refresh"]');
        refreshButton.click();
        refreshButton.click();
        await flushPromises();

        expect(requestCompanyIntelligence).toHaveBeenCalledTimes(2);
        expect(element.shadowRoot.querySelector('[data-testid="loading"]')).not.toBeNull();

        refreshResponse.resolve(successfulResponse());
        await flushPromises();
    });
});
