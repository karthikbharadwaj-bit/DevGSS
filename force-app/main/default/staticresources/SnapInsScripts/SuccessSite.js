'use strict';
/**
 Script for success site contains GW appearance and SW logic
 GW - all ID (except BUTTON_ID), applyStyles
 SW - other part: logic and BUTTON_ID
 */
/* Individual setup for environment - check values! */
/* GW data */
var DEPLOYMENT_ID = 'DEPLOYMENT_ID__c';
var BUTTON_ID = 'BUTTON_ID__c';
var BUTTON_ID_US_Team_All = 'BUTTON_ID_US_Team_All__c';
var BASE_LIVE_AGENT_CONTENT_URL = 'BASE_LIVE_AGENT_CONTENT_URL__c';
var BASE_LIVE_AGENT_URL = 'BASE_LIVE_AGENT_URL__c';
var BASE_CORE_URL = 'BASE_CORE_URL__c';
var COMMUNITY_ENDPOINT_URL = 'COMMUNITY_ENDPOINT_URL__c';
var ORG_ID = 'ORG_ID__c';
var ESW_CONFIG_DEV_NAME = 'ESW_CONFIG_DEV_NAME__c';
var ESW_LIVE_AGENT_DEV_NAME = 'ESW_LIVE_AGENT_DEV_NAME__c';

/* General setup - same for every environment */
var IS_FIRST_CALL = 'true'; // go to sales bucket for not first call
var USERNAME = "PLACEHOLDER_FIRSTNAME"; // user name for pop-up
var LANGUAGE = "en"; // language setting

applyStyles();

function initSnapInsChat() {
    var config = arguments.length <= 0 || arguments[0] === undefined ? {} : arguments[0];
    var initESW = function initESW(gslbBaseURL) {
        embedded_svc.settings.displayHelpButton = true;
        embedded_svc.settings.widgetWidth = '320px';
        embedded_svc.settings.widgetHeight = '498px';
        embedded_svc.settings.defaultMinimizedText = 'Ask RingCentral';
        embedded_svc.settings.disabledMinimizedText = 'Agent is offline';
        embedded_svc.settings.loadingText = 'Connecting…';
        embedded_svc.settings.onlineLoadingText = 'Connecting…';
        embedded_svc.settings.offlineSupportMinimizedText = 'Contact RC';
        embedded_svc.settings.enabledFeatures = ['LiveAgent'];
        embedded_svc.settings.entryFeature = 'LiveAgent';

        embedded_svc.addEventHandler("onHelpButtonClick", function(data) {
            IS_FIRST_CALL = 'true';	// reset to first call
        });

        embedded_svc.settings.directToButtonRouting = function (prechatFormData) {
            var chatType = prechatFormData.find(function (d) {
                return d.name === 'Original_SFDC_Source__c';
            }).value;
            var partsArray = chatType.split('-');
            if(IS_FIRST_CALL == 'false' && partsArray[0] == 'sales') { // if not a first sales call - go to sales bucket
                console.log('not a first call');
                return BUTTON_ID_US_Team_All;
            }
            console.log('first call');
            console.log( 'chatType ' + chatType);
            IS_FIRST_CALL = 'false';
            return partsArray[1];
        };

        var COMMUNITY_FIRST_NAME = "PLACEHOLDER_FIRSTNAME";	/* get FirstName or Guest*/
        if(COMMUNITY_FIRST_NAME !== "Guest"){
            USERNAME = COMMUNITY_FIRST_NAME;
        }else{
            USERNAME = (config.params.FIRSTNAME) ? config.params.FIRSTNAME : "Guest";
        }

        embedded_svc.settings.extraPrechatFormDetails = [];

        if (config.params) {
            LANGUAGE = (config.params.RCUSERLANG) ? setLangCodeTranslation(config.params.RCUSERLANG.toLowerCase()) : "en"; // setup language
            translate(embedded_svc, LANGUAGE);
            document.documentElement.setAttribute('lang', LANGUAGE);

            embedded_svc.settings.prepopulatedPrechatFields = {
                FirstName: config.params.FIRSTNAME,
                LastName: config.params.LASTNAME,
                Email: config.params.EMAIL,
                Phone: config.params.CONTACTPHONE,
                Company__c: config.params.COMPANY
            };

            /* Pass marketing params if exists */
            embedded_svc.settings.extraPrechatFormDetails.push.apply(embedded_svc.settings.extraPrechatFormDetails, [{
                "label": "BMID",
                "value": config.params.BMID,
                "transcriptFields": ["BMID__c"],
                "displayToAgent": true
            }, {
                "label": "AID",
                "value": config.params.AID,
                "transcriptFields": ["AID__c"],
                "displayToAgent": true
            }, {
                "label": "SID",
                "value": config.params.SID,
                "transcriptFields": ["SID__c"],
                "displayToAgent": true
            }, {
                "label": "PID",
                "value": config.params.PID,
                "transcriptFields": ["PID__c"],
                "displayToAgent": true
            }, {
                "label": "RCMT",
                "value": config.params.RCMT,
                "transcriptFields": ["RCMT__c"],
                "displayToAgent": true
            }, {
                "label": "RCKW",
                "value": config.params.RCKW,
                "transcriptFields": ["RCKW__c"],
                "displayToAgent": true
            }, {
                "label": "OriginalReferrer",
                "value": config.params.OriginalReferrer,
                "transcriptFields": ["Original_Referrer__c"],
                "displayToAgent": true
            }, {
                "label": "user_log",
                "value": config.params.user_log,
                "displayToAgent": true
            }, {
                "label": "gw_referer",
                "value": config.params.gw_referer,
                "transcriptFields": ["GW_Referer__c"],
                "displayToAgent": true
            }, {
                "label": "Adobe_Target_Id__c",
                "value": config.params.Adobe_Target_Id__c,
                "transcriptFields": ["Adobe_Target_Id__c"],
                "displayToAgent": true
            }, {
                "label": "Transaction_Id__c",
                "value": config.params.Transaction_Id__c,
                "transcriptFields": ["Transaction_Id__c"],
                "displayToAgent": true
            }, {
                "label": "Adobe_Target_Id_History__c",
                "value": config.params.Adobe_Target_Id_History__c,
                "transcriptFields": ["Adobe_Target_Id_History__c"],
                "displayToAgent": true
            }]);
        }

        /* General mappings for the contact */
        embedded_svc.settings.extraPrechatInfo = [{
            "entityFieldMaps": [{
                "doCreate": true,
                "doFind": false,
                "fieldName": "LastName",
                "label": "Last Name"
            }, {
                "doCreate": true,
                "doFind": false,
                "fieldName": "FirstName",
                "label": "First Name"
            }, {
                "doCreate": true,
                "doFind": false,
                "fieldName": "Phone",
                "label": "Phone"
            }, {
                "doCreate": true,
                "doFind": false,
                "fieldName": "Company__c",
                "label": "Company"
            }, {
                "doCreate": true,
                "doFind": true,
                "fieldName": "Email",
                "isExactMatch": false,
                "label": "Email"
            }],
            "entityName": "Contact",
            "showOnCreate": true,
            "saveToTranscript": "ContactId"
        }];

        /* General mappings for the contact fields */
        embedded_svc.settings.extraPrechatFormDetails.push.apply(embedded_svc.settings.extraPrechatFormDetails, [{
            "label": "First Name",
            "transcriptFields": ["PreChat_Firstname__c"]
        }, {
            "label": "Last Name",
            "transcriptFields": ["PreChat_Lastname__c"]
        }, {
            "label": "Email",
            "transcriptFields": ["PreChat_Email__c"]
        }, {
            "label": "Phone",
            "transcriptFields": ["PreChat_Phone__c"]
        }, {
            "label": "Company",
            "transcriptFields": ["PreChat_Company__c"]
        }, {
            "label": "No. of Employees (Range)",
            "transcriptFields": ["PreChat_Number_of_Employees__c"]
        }]);

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

    document.addEventListener('SalesAgentsOffline', function(event) { // test Sales Agent Offline event
        console.log('SalesAgentsOffline'
            + '; firstname:' + event.detail.firstName
            + '; lastName:' + event.detail.lastName
            + '; email:' + event.detail.email
            + '; phone:' + event.detail.phone
            + '; company:' + event.detail.company
            + '; NumberOfEmployees__c:' + event.detail.NumberOfEmployees__c
        );
    }, false);

}

function translate(console, lang) {
    if (lang) {
        console.settings.language = setLangCodeTranslation(lang.toLowerCase());;
        console.settings.defaultMinimizedText = setTextTranslation(console.settings.defaultMinimizedText, console.settings.language);
        console.settings.disabledMinimizedText = setTextTranslation(console.settings.disabledMinimizedText, console.settings.language);
        console.settings.onlineLoadingText = setTextTranslation(console.settings.onlineLoadingText, console.settings.language);
        console.settings.loadingText = setTextTranslation(console.settings.loadingText, console.settings.language);
        console.settings.offlineSupportMinimizedText = setTextTranslation(console.settings.offlineSupportMinimizedText, console.settings.language);
    }
}

function setLangCodeTranslation(lang) {
    switch (lang) {
        case "de-de":
        case "de":
            return "de";
        case "en-gb":
        case "en-us":
        case "en":
            return "en";
        case "es-es":
        case "es":
            return "es";
        case "es-419":
        case "es-mx":
            return "es-mx";
        case "fr-fr":
        case "fr-ca":
        case "fr":
            return "fr";
        case "it-it":
        case "it":
            return "it";
        case "ja-jp":
        case "ja":
            return "ja";
        case "zh-hk":
        case "zh-tw":
            return "zh-tw";
        case "zh-cn":
            return "zh-cn";
        case "pt-br":
            return "pt-br";
        default:
            return "en";
    }
}

function setTextTranslation(text, lang) {
    var dict = {
        'Ask RingCentral': {
            "en":	"Ask RingCentral",
            "zh-cn": "问RingCentral",
            "zh-tw": "問RingCentral",
            "pt-br": "Pergunte ao RingCentral",
            "de": "Fragen Sie RingCentral",
            "fr": "Demandez à RingCentral",
            "es": "Pregunta a RingCentral",
            "es-mx": "Pregunta a RingCentral",
            "it": "Chiedi a RingCentral",
            "ja": "RingCentralに聞く"
        },
        'Agent is offline': {
            "en":	"Agent is offline",
            "zh-cn": "代理离线",
            "zh-tw": "代理離線",
            "pt-br": "Agente está offline",
            "de": "Der Agent ist offline",
            "fr": "Agent est déconnecté",
            "es": "El agente está fuera de línea",
            "es-mx": "El agente está fuera de línea",
            "it": "L'agente è offline",
            "ja": "エージェントはオフラインです"
        },
        'Connecting…': {
            "en":	"Connecting…",
            "zh-cn": "连接...",
            "zh-tw": "連接...",
            "pt-br": "Conectando...",
            "de": "Verbindung...",
            "fr": "De liaison...",
            "es": "Conectando...",
            "es-mx": "Conectando...",
            "it": "Connessione in corso...",
            "ja": "接続中..."
        },
        'Contact RC': {
            "en":	"Contact RC",
            "zh-cn": "联系RC",
            "zh-tw": "聯繫RC",
            "pt-br": "Contato RC",
            "de": "Kontaktieren Sie RC",
            "fr": "Contacter RC",
            "es": "Contacto RC",
            "es-mx": "Contacto RC",
            "it": "Contatta RC",
            "ja": "RCに連絡する"
        },
        'Hello': {
            "en":	"Hello",
            "zh-cn": "你好",
            "zh-tw": "你好",
            "pt-br": "Olá",
            "de": "Hallo",
            "fr": "Bonjour",
            "es": "Hola",
            "es-mx": "Hola",
            "it": "Ciao",
            "ja": "こんにちは"
        },
        'Stuck or can\'t find what your looking for?': {
            "en":	"Stuck or can\'t find what your looking for?",
            "zh-cn": "被困或无法找到你想要的东西？",
            "zh-tw": "被困或無法找到你想要的東西？",
            "pt-br": "Preso ou não consegue encontrar o que você está procurando?",
            "de": "Stuck oder kann nicht finden was Sie suchen?",
            "fr": "Coincé ou ne trouve pas ce que vous cherchez?",
            "es": "¿Atascado o no encuentras lo que buscas?",
            "es-mx": "¿Atascado o no encuentras lo que buscas?",
            "it": "Bloccato o non riesci a trovare quello che stai cercando?",
            "ja": "あなたが探しているものが見つからない？"
        },
        'We\'re happy to help.': {
            "en":	"We\'re happy to help.",
            "zh-cn": "我们很乐意帮助。",
            "zh-tw": "我们很乐意帮助。",
            "pt-br": "Estamos felizes em ajudar.",
            "de": "Wir helfen gerne.",
            "fr": "Nous sommes heureux de vous aider.",
            "es": "Estamos felices de ayudar.",
            "es-mx": "Estamos felices de ayudar.",
            "it": "Siamo felici di aiutare.",
            "ja": "私たちは喜んでお手伝いします。"
        },
        'Chat with us': {
            "en":	"Chat with us",
            "zh-cn": "和我们聊天",
            "zh-tw": "和我们聊天",
            "pt-br": "Conversar com nós",
            "de": "Chatte mit uns",
            "fr": "Discute avec nous",
            "es": "Habla con nosotros",
            "es-mx": "Habla con nosotros",
            "it": "Chatta con noi",
            "ja": "私たちとしゃべる"
        }
    };

    if (dict[text]) {
        if (dict[text][lang]) {
            text = dict[text][lang];
        }
    }

    return text;
}

window.onload = function () {
    var Label_SnapInGreeting = setTextTranslation('Hello', setLangCodeTranslation(LANGUAGE.toLowerCase()));
    var Label_SnapInStuck =	setTextTranslation('Stuck or can\'t find what your looking for?', setLangCodeTranslation(LANGUAGE.toLowerCase()));
    var Label_SnapInWerehappytohelp = setTextTranslation('We\'re happy to help.', setLangCodeTranslation(LANGUAGE.toLowerCase()));
    var Label_SnapInChatWithUs = setTextTranslation('Chat with us', setLangCodeTranslation(LANGUAGE.toLowerCase()));

    var snapins_invite = document.createElement('div');
    snapins_invite.className = 'invitation-chat-popup IId-proactive-popup CId-proactive-popup ';
    snapins_invite.setAttribute('id', 'snapins_invite');

    var txt = "<div class=\"invitation-chat-popup-content\"><div class=\"inv-cht-close-btn proactive-popup-closeButton butt-popup-proactive-no\" id=\"invitation-chat-ButtonClose1\" role=\"button\" element=\"button\" name=\"No, don't start\"></div><p class=\"inv-cht-popup-title\">"+Label_SnapInGreeting+" "+USERNAME+".<br/> "+Label_SnapInStuck+"</p><p class=\"inv-cht-reg-text\">"+Label_SnapInWerehappytohelp+"</p><div class=\"inv-cht-button proactive-popup-startButton\" id=\"invitation-chat-ButtonStart1\" title=\"Chat with us\" role=\"button\" element=\"button\" name=\"Yes, start chat\"><span class=\"inv-cht-button-text\">"+Label_SnapInChatWithUs+"</span></div><br/></div>";
    snapins_invite.innerHTML = txt;
    document.body.appendChild(snapins_invite);

    document.getElementById('invitation-chat-ButtonClose1').onclick = function () {
        embedded_svc.inviteAPI.inviteButton.rejectInvite(); // use this API call to reject invitations
    };
    document.getElementById('invitation-chat-ButtonStart1').onclick = function () {
        embedded_svc.inviteAPI.inviteButton.acceptInvite(); // use this API call to start chat from invitations
    };
    document.addEventListener('keyup', function (event) {
        if (event.keyCode == 27) {
            embedded_svc.inviteAPI.inviteButton.rejectInvite();
        }
    });
};

/* GW data */
function applyStyles() {
    var pathToCloseButton = COMMUNITY_ENDPOINT_URL + "/resource/ChatAgentImages/CloseButton.png";
    var css = "@-webkit-keyframes invit-popup-up{from,60%,75%,90%,to{-webkit-animation-timing-function:cubic-bezier(0.215, 0.61, 0.355, 1);animation-timing-function:cubic-bezier(0.215, 0.61, 0.355, 1)}from{opacity:0;-webkit-transform:translate3d(0, 3000px, 0);transform:translate3d(0, 3000px, 0)}60%{opacity:1;-webkit-transform:translate3d(0, -20px, 0);transform:translate3d(0, -20px, 0)}75%{-webkit-transform:translate3d(0, 10px, 0);transform:translate3d(0, 10px, 0)}90%{-webkit-transform:translate3d(0, -5px, 0);transform:translate3d(0, -5px, 0)}to{-webkit-transform:translate3d(0, 0, 0);transform:translate3d(0, 0, 0)}}@keyframes invit-popup-up{from,60%,75%,90%,to{-webkit-animation-timing-function:cubic-bezier(0.215, 0.61, 0.355, 1);animation-timing-function:cubic-bezier(0.215, 0.61, 0.355, 1)}from{opacity:0;-webkit-transform:translate3d(0, 3000px, 0);transform:translate3d(0, 3000px, 0)}60%{opacity:1;-webkit-transform:translate3d(0, -20px, 0);transform:translate3d(0, -20px, 0)}75%{-webkit-transform:translate3d(0, 10px, 0);transform:translate3d(0, 10px, 0)}90%{-webkit-transform:translate3d(0, -5px, 0);transform:translate3d(0, -5px, 0)}to{-webkit-transform:translate3d(0, 0, 0);transform:translate3d(0, 0, 0)}}@-webkit-keyframes invit-popup-out{20%{-webkit-transform:translate3d(0, 10px, 0);transform:translate3d(0, 10px, 0)}40%,45%{opacity:1;-webkit-transform:translate3d(0, -20px, 0);transform:translate3d(0, -20px, 0)}to{opacity:0;-webkit-transform:translate3d(0, 2000px, 0);transform:translate3d(0, 2000px, 0)}}@keyframes invit-popup-out{20%{-webkit-transform:translate3d(0, 10px, 0);transform:translate3d(0, 10px, 0)}40%,45%{opacity:1;-webkit-transform:translate3d(0, -20px, 0);transform:translate3d(0, -20px, 0)}to{opacity:0;-webkit-transform:translate3d(0, 2000px, 0);transform:translate3d(0, 2000px, 0)}}.pre-chat__buttons>.pre-chat__question{display:-webkit-box;display:-webkit-flex;display:-ms-flexbox;display:flex;-webkit-box-orient:vertical;-webkit-box-direction:normal;-webkit-flex-direction:column;-ms-flex-direction:column;flex-direction:column}.pre-chat__question p:first-child{-webkit-box-ordinal-group:4;-webkit-order:3;-ms-flex-order:3;order:3}.pre-chat__question p:nth-child(3){-webkit-box-ordinal-group:2;-webkit-order:1;-ms-flex-order:1;order:1}button.slds-button.slds-button_neutral.pre-chat__button:nth-child(4){-webkit-box-ordinal-group:3;-webkit-order:2;-ms-flex-order:2;order:2;background:#f80 !important;color:#fff !important;border:none !important}button.slds-button.slds-button_neutral.pre-chat__button:nth-child(2){-webkit-box-ordinal-group:5;-webkit-order:4;-ms-flex-order:4;order:4;background:#fff !important;color:#0684bd !important;border:0.1rem solid #0684bd !important}.pre-chat__hello-text{word-break:break-word}.embeddedServiceHelpButton .uiButton .helpButtonLabel .message{white-space:normal !important}.embeddedServiceHelpButton .helpButton .helpButtonEnabled:hover::before{border-radius:8px 8px 0 0 !important}.embeddedServiceHelpButton .helpButton .helpButtonEnabled:focus::before{border-radius:8px 8px 0 0 !important}.embeddedServiceHelpButton .helpButton .uiButton{border-radius:8px 8px 0 0 !important;background-color:#0684bd !important;font-family:\"Proxima Nova\", sans-serif}.embeddedServiceHelpButton .helpButton .uiButton:focus{outline:1px solid #0684bd}.embeddedServiceLiveAgentStateChatHeaderOption .optionName{white-space:normal !important}.embeddedServiceLiveAgentStateChatHeader:not(.alert) .message{white-space:normal !important}button.uiButton.helpButtonEnabled{border-radius:8px 8px 0 0 !important}.helpButton{position:fixed !important;bottom:0 !important}button.uiButton.helpButtonDisabled{border-radius:8px 8px 0 0 !important}button.sidebarHeader.minimizedContainer.helpButton.embeddedServiceSidebarMinimizedDefaultUI{border-style:none}.dockableContainer .sidebarHeader .waitingGreeting{word-wrap:break-word}.pre-chat__button__dark{background:#f80 !important}.pre-chat__button__light{background:#fff !important;color:#0684bd !important;border:0.1rem solid #0684bd !important}button.embeddedServiceSidebarButton:not(.uiButton--inverse):focus{background:#0684bd !important}button.embeddedServiceSidebarButton:not(.uiButton--inverse):hover{background:#0684bd !important}#snapins_invite{position:fixed !important;visibility:hidden;top:0%;left:0%;max-width:302px}.invitation-chat-popup{width:302px;z-index:10000;font-family:\"Lato\",Helvetica,Arial,sans-serif;font-weight:300;text-align:left}.invitation-chat-popup *{box-sizing:border-box;margin:0;padding:0;line-height:1;-webkit-font-smoothing:antialiased}.invitation-chat-popup .invitation-chat-popup-content{display:block;position:relative;width:100%;height:100%;background-color:#fafafa;border:1px solid #b6b6b6;border-top-left-radius:8px;border-top-right-radius:8px}.invitation-chat-popup .invitation-chat-popup-content .inv-cht-close-btn{position:absolute;right:5px;top:6px;cursor:pointer;width:20px;height:20px;z-index:10100}.invitation-chat-popup .invitation-chat-popup-content .inv-cht-close-btn:before,.invitation-chat-popup .invitation-chat-popup-content .inv-cht-close-btn:after{position:absolute;left:9px;top:2px;content:' ';height:17px;width:1px;background-color:#afafaf}.invitation-chat-popup .invitation-chat-popup-content .inv-cht-close-btn:before{-webkit-transform:rotate(45deg);-ms-transform:rotate(45deg);transform:rotate(45deg)}.invitation-chat-popup .invitation-chat-popup-content .inv-cht-close-btn:after{-webkit-transform:rotate(-45deg);-ms-transform:rotate(-45deg);transform:rotate(-45deg)}.invitation-chat-popup .invitation-chat-popup-content .inv-cht-image-rounded-container{height:44px;outline:none}.invitation-chat-popup .invitation-chat-popup-content .inv-cht-image-rounded-container .inv-cht-image-img{margin:0 auto;position:relative;top:-41px;height:76px;display:block;outline:none}.invitation-chat-popup .invitation-chat-popup-content .inv-cht-popup-title{font-size:22px;font-weight:400;padding-bottom:9px;letter-spacing:.2px;color:#333}.invitation-chat-popup .invitation-chat-popup-content .inv-cht-reg-text{font-size:16px;line-height:18px;padding-bottom:13px;padding-right:25px;letter-spacing:.1px;color:#333}.invitation-chat-popup .invitation-chat-popup-content .inv-cht-phone-num{font-size:34px;color:#0e72d2;padding-bottom:16px;cursor:text}.invitation-chat-popup .invitation-chat-popup-content .inv-cht-phone-num .dynamicNumber{color:inherit;display:block;font-weight:bold;text-align:center;cursor:text;text-decoration:none}.invitation-chat-popup .invitation-chat-popup-content .inv-cht-phone-num .dynamicNumber code{text-decoration:none;outline:0;display:inline-block;font-weight:bold}.invitation-chat-popup .invitation-chat-popup-content .inv-cht-divider{width:71%;border-top:2px solid #dcdcdc;text-align:center;padding-bottom:3px;margin:0 auto}.invitation-chat-popup .invitation-chat-popup-content .inv-cht-divider .inv-cht-divider-text{position:relative;top:-10px;color:#767676;font-size:15px;background:#fafafa;display:inline-block;text-align:center;padding-left:4px;padding-right:4px}.invitation-chat-popup .invitation-chat-popup-content .inv-cht-button{width:80%;cursor:pointer;background:#ff8900;border-radius:6px;height:47px;text-align:center;margin:0 auto}.invitation-chat-popup .invitation-chat-popup-content .inv-cht-button:hover{background:#ff9d2a}.invitation-chat-popup .invitation-chat-popup-content .inv-cht-button:active{background:#eb6321}.invitation-chat-popup .invitation-chat-popup-content .inv-cht-button .inv-cht-button-text{position:relative;top:15px;color:#fff;font-size:16px;font-weight:400;letter-spacing:.2px;margin:0 auto}.invitation-chat-popup .invitation-chat-popup-content .inv-cht-text-bottom{font-size:13px;font-weight:400;padding-bottom:20px;text-align:center;margin-top:18px;color:#222}.invitation-chat-popup .invitation-chat-popup-content .inv-cht-text-bottom a{font-size:13px;color:#0073ae;text-decoration:underline}#invitation-chat-ButtonStart2{background:#fff !important;border:0.1rem solid #0684bd !important}#invitation-chat-ButtonStart2:hover{background:#f2f2f2 !important}#inv-cht-button-text2{color:#0684bd !important}.invitation-chat-popup.isonline{left:unset !important;left:inherit !important;top:unset !important;top:inherit !important;bottom:0 !important;margin:0 !important;right:4%;-webkit-animation-name:invit-popup-up;animation-name:invit-popup-up;-webkit-animation-duration:1.2s;animation-duration:1.2s;-webkit-animation-fill-mode:both;animation-fill-mode:both}.invitation-chat-popup.isoffline{left:-1000px !important;top:-1000px !important}.inv-cht-popup-title{padding-left:9%}.inv-cht-reg-text{padding-left:9%}.invitation-chat-popup.button-action-hide{display:none}.inv-pop-up-B .popup-content-wrap{display:none}.inv-pop-up-B .popup-proactive-bottom-content{display:none}.inv-pop-up-B .invitation-chat-popup-content{display:block}.invitation-chat-popup-content{display:none}.invit-popup-animated{-webkit-animation-duration:1.2s;animation-duration:1.2s;-webkit-animation-fill-mode:both;animation-fill-mode:both}.invit-popup-up{-webkit-animation-name:invit-popup-up;animation-name:invit-popup-up}.invitation-chat-popup.isrejected{-webkit-animation-name:invit-popup-out;animation-name:invit-popup-out;-webkit-animation-duration:1.2s;animation-duration:1.2s;-webkit-animation-fill-mode:both;animation-fill-mode:both}.invitation-chat-popup.isstarted{-webkit-animation-name:invit-popup-out;animation-name:invit-popup-out;-webkit-animation-duration:1.2s;animation-duration:1.2s;-webkit-animation-fill-mode:both;animation-fill-mode:both}@media only screen and (max-width: 719px){.invitation-chat-popup{display:none}}\n";
    var style = document.createElement('style');
    style.type = 'text/css';
    style.appendChild(document.createTextNode(css));
    document.head.appendChild(style);
}
