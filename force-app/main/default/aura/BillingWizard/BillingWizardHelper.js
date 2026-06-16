({
    initAngular: function(component) {
        const config = component.get('v.config');
        const herokuEndpoint = config.heroku.endpoint;
        const sessionId = config.salesforce.sessionId;
        const origin = config.salesforce.origin;
        const oppId = config.salesforce.opportunityId;
        const visualforceOrigin = window.location.origin;
        const accountSFDCId = config.salesforce.accountSFDCId;
        const url = new URL(window.location.href);
        const quoteId = url.searchParams.get('quoteId');
        const newQuoteType = url.searchParams.get('newQuoteType');
        const isFedRamp = config.salesforce.isFedRamp;
        const featureToggle = config.old.settings.featureToggle;
        const userId = config.old.user.Id;
        const rcUserId = config.old.rcUserId;
        const opportunity = config.old.currentOpportunity;

        const angular = document.createElement('app-root');
        angular.routeParams = {
            name: 'uqt',
            data: {
                opportunity,
                userId,
                rcUserId,
                billingParams: {
                    herokuEndpoint,
                    sessionId,
                    origin,
                },
                visualforceOrigin,
                oppId,
                accountSFDCId,
                quoteId,
                newQuoteType,
                isFedRamp,
                featureToggle,
            }
        }
        document.getElementById('angular').appendChild(angular);
    }
})