const BUTTON_ID_SALES = "5734F000000CaXV";
const BUTTON_ID_SUPPORT = "5734F000000CaXa";
const DEPLOYMENT_ID = '5724F000000CaTX';
const BUTTON_ID = '5734F000000CaXf';

const BASE_LIVE_AGENT_CONTENT_URL = 'https://c.la2-c1cs-ord.salesforceliveagent.com/content';
const BASE_LIVE_AGENT_URL = 'https://d.la2-c1cs-ord.salesforceliveagent.com/chat';
const BASE_CORE_URL = 'https://rc--Box8.cs93.my.salesforce.com';
const COMMUNITY_ENDPOINT_URL = 'https://box8-ringcentral.cs93.force.com/rcsupport2013';
const ORG_ID = '00D4F0000008awg';
const ESW_CONFIG_DEV_NAME = 'Snap_in_product_chat';
const ESW_LIVE_AGENT_DEV_NAME = 'EmbeddedServiceLiveAgent_Parent04I4F000000CaRlUAK_1651985b4cf';
applyStyles();

function initSnapInsChat(config = {}) {
    var initESW = function (gslbBaseURL) {
        embedded_svc.settings.displayHelpButton = true;
        embedded_svc.settings.widgetWidth = 320;
        embedded_svc.settings.widgetHeight = 480;
        embedded_svc.settings.defaultMinimizedText = 'Chat with RC';
        embedded_svc.settings.disabledMinimizedText = 'Agent is offline';
        embedded_svc.settings.onlineLoadingText = 'Connecting…';
        embedded_svc.settings.offlineSupportMinimizedText = 'Contact RC';

        embedded_svc.settings.devMode = true;
        embedded_svc.settings.language = '';
        embedded_svc.settings.enabledFeatures = ['LiveAgent'];
        embedded_svc.settings.entryFeature = 'LiveAgent';

        embedded_svc.settings.directToButtonRouting = function (prechatFormData) {
            var chatType = prechatFormData.find(d => d.name === 'Phone').value;

            var buttonId;
            switch (chatType) {
                case 'sales':
                    buttonId = BUTTON_ID_SALES;
                    break;

                case 'support':
                    buttonId = BUTTON_ID_SUPPORT;
                    break;

                default:
                    buttonId = BUTTON_ID;
                    break;
            }
            return buttonId;
        };

        if (config.params) {
            embedded_svc.settings.prepopulatedPrechatFields = {
                FirstName: config.params.FIRSTNAME,
                LastName: config.params.LASTNAME,
                Company__c: config.params.COMPANY
            };
        }

        embedded_svc.init(BASE_CORE_URL, COMMUNITY_ENDPOINT_URL, gslbBaseURL, ORG_ID, ESW_CONFIG_DEV_NAME, {
            baseLiveAgentContentURL: BASE_LIVE_AGENT_CONTENT_URL,
            deploymentId: DEPLOYMENT_ID,
            buttonId: BUTTON_ID,
            baseLiveAgentURL: BASE_LIVE_AGENT_URL,
            eswLiveAgentDevName: ESW_LIVE_AGENT_DEV_NAME,
            isOfflineSupportEnabled: false
        });
    };

    var s1 = document.createElement('script');
    s1.setAttribute('src', 'https://service.force.com/embeddedservice/5.0/esw.min.js');
    s1.onload = function () {
        if (!window.embedded_svc) {
            var s = document.createElement('script');
            s.setAttribute('src', BASE_CORE_URL + '/embeddedservice/5.0/esw.min.js');
            s.onload = function () {
                initESW(null);
            };
            document.body.appendChild(s);
        } else {
            initESW('https://service.force.com');
        }
    };
    document.body.appendChild(s1);
}

function applyStyles(){
    var css = `.embeddedServiceHelpButton .helpButton .uiButton { background-color: #1884bc !important; font-family: "Helvetica", sans-serif; }
               .embeddedServiceHelpButton .helpButton .uiButton:focus { outline: 1px solid #1884bc; }`;
    var style = document.createElement('style');
    style.type = 'text/css';
    style.appendChild(document.createTextNode(css));
    document.head.appendChild(style);
}