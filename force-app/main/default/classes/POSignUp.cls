public with sharing class POSignUp {
    public interface IUISignUpRunner {
        Boolean isUiSignUp();
        Response proceedUISignUp();
        Response proceedUIlessSignUp();
    }

    public abstract class SignUpRunner {
        @TestVisible
        POWrappers.SignUpRequestBody body;
        @TestVisible
        Opportunity opportunity;
        @TestVisible
        Quote targetQuote;

        SignUpRunner(POWrappers.SignUpParams data) {
            this(data, new POSignUpBodyHelper.SignUpBodyBuilder());
        }
        SignUpRunner(POWrappers.SignUpParams data, POSignUpBodyHelper.ISignUpBodyBuilder builder) {
            opportunity = data.opportunity;
            targetQuote = data.targetQuote;
            body = builder.buildBody(data);
        }
        SignUpRunner() {}

        public abstract Response signUp();
        public abstract Object getRequestBody();
    }

    public class MVPSignUpRunner extends SignUpRunner {
        public MVPSignUpRunner(POWrappers.SignUpParams data) {
            super(data);
        }
        public MVPSignUpRunner() {}

        public override Object getRequestBody() {
            return body;
        }

        public override Response signUp() {
            Response resp = new Response();
            FunnelAPI.FunnelResponse res = FunnelAPI.multiProductMVPSignUp(opportunity, (POWrappers.SignUpRequestBody) getRequestBody());
            resp.setData('message', res.result.orderStatus);
            resp.setData('data', res);

            Account acc = new Account(
                Id = opportunity.Account.Id,
                Internal_Enterprise_Account_ID__c = res.FSG_SID
            );
            if (AccountHelper.isInactive(opportunity.Account)) {
                acc.RC_Account_Status__c = null;
            }
            update acc;

            return resp;
        }
    }

    public class FaxSignUpRunner extends SignUpRunner {
        public FaxSignUpRunner(POWrappers.SignUpParams data) {
            super(data);
        }
        public FaxSignUpRunner() {}

        public override Response signUp() {
            Response resp = new Response();
            resp.setData('status', Response.STATUS_SUCCESS);
            resp.setData('redirectUrl', getFaxRedirectUrl(opportunity.Brand_Name__c));
            return resp;
        }

        public override Object getRequestBody() {
            return null;
        }

        private String getFaxRedirectUrl(String brandName) {
            EndpointsSettings__c es = SettingsHelper.getEndpointsSettings();
            return new Map<String, String> {
                OpportunityHelper.BRAND_RINGCENTRAL => es.Fax_US_SignUp_Endpoint__c,
                OpportunityHelper.BRAND_RINGCENTRAL_CA => es.Fax_CA_SignUp_Endpoint__c
            }.get(brandName);
        }
    }

    public class EngageSignUpRunner extends SignUpRunner implements IUISignUpRunner {
        public EngageSignUpRunner(POWrappers.SignUpParams data) {
            super(data);
        }
        public EngageSignUpRunner() {}

        public override Response signUp() {
            return isUiSignUp() ? proceedUISignUp() : proceedUIlessSignUp();
        }
        public override Object getRequestBody() {
            String bodyString;
            if (isUiSignUp()) {
                bodyString = toStringURL(body.requestBodyMap);
            } else {
                bodyString = JSON.serialize(body.requestBodyMap, true)
                    .replaceAll('isOverride', 'override')
                    .replaceAll('limitType', 'type');
            }

            return bodyString;
        }
        public Boolean isUiSignUp() {
            return !POHelper.isEngageUILessSettingsOn;
        }
        public Response proceedUISignUp() {
            UISignUP uiSignUp = new UISignUP(targetQuote, (String) getRequestBody());

            return uiSignUp.proceedDefaultSignUp();
        }
        public Response proceedUIlessSignUp() {
            HttpResponse httpResponse = CCBAPI.requestCCB(
                CCBAPI.getSignUpUILessEndpoint(AccountHelper.isMPUBAccount(opportunity.Account)),
                HttpHelper.METHOD_POST,
                (String) getRequestBody()
            );

            return CCBAPI.handleResponse(httpResponse);
        }

        public String toStringURL(Map<String, Object> body) {
            List<String> listType = new List<String> {
                'OID', 'DefaultPackageLimits', 'ApprovedPackageLimits', 'LboxOverrides', 'TaxSettings'
            };
            String result = '';
            for (String key : body.keySet()) {
                String val = String.valueOf(
                    body.get(key)
                );
                if (String.isBlank(val)) {
                    continue;
                }
                if (String.isNotBlank(result) ) {
                    result += '&';
                }
                if (!listType.contains(key)) {
                    result += key + '=';
                }
                result += val;
            }

            return result;
        }
    }

    public class RCCCSignUpRunner extends SignUpRunner {
        public RCCCSignUpRunner(POWrappers.SignUpParams data) {
            super(data);
        }
        public RCCCSignUpRunner() {}

        public override Response signUp() {
            String path = ICBAPI.ICB_SETTINGS.SignUpPath__c;
            String endpoint = (AccountHelper.isMPUBAccount(opportunity.Account)
                ? ICBAPI.BASE_ENDPOINT_V2
                : ICBAPI.BASE_ENDPOINT_V1) + path;
            HttpResponse httpResponse = ICBAPI.requestICB(endpoint, HttpHelper.METHOD_POST, (String) getRequestBody());
            return ICBAPI.handleResponse(httpResponse);
        }

        public override Object getRequestBody() {
            return JSON.serialize(body.requestBodyMap)
                .replaceAll('isOverride', 'override')
                .replaceAll('limitType', 'type');
        }
    }

    // RCCC change order flow is almost the same as RCCC sign up flow,
    // but with different endpoints and more complex logic:
    // Current state should be sent to ICB for Case provisioning
    public class RCCCSyncRunner extends SignUpRunner {
        public RCCCSyncRunner(POWrappers.SignUpParams data) {
            super(data);
        }
        public RCCCSyncRunner() {}

        public override Response signUp() {
            String endpoint = ICBAPI.BASE_ENDPOINT_V1 + ICBAPI.ICB_SETTINGS.ChangePath__c;
            HttpResponse httpResponse = ICBAPI.requestICB(endpoint, HttpHelper.METHOD_POST, (String) getRequestBody());
            return ICBAPI.handleResponse(httpResponse);
        }

        public override Object getRequestBody() {
            return JSON.serialize(body.requestBodyMap)
                .replaceAll('isOverride', 'override')
                .replaceAll('limitType', 'type');
        }
    }

    public class UISignUP {
        Quote qt;
        String bodyStr;

        public UISignUP(Quote targetQuote, String bodyStr) {
            this.qt = targetQuote;
            this.bodyStr = bodyStr;
        }

        public Response proceedDefaultSignUp() {
            Response resp = new Response();
            try {
                POWrappers.SalesFunnelUIResponse result = new POWrappers.SalesFunnelUIResponse();
                POWrappers.SignUpFunnelUIRequestParams params = new POWrappers.SignUpFunnelUIRequestParams(qt);
                String res = getSignUpFunnelResponseBody(bodyStr, params);
                POWrappers.GWSignUpResponse gwres = (POWrappers.GWSignUpResponse) JSON.deserialize(res, POWrappers.GWSignUpResponse.class);
                result.Status = 'Ok';
                result.RedirectUrl = QuoteHelper.isRCCC(qt) ? gwres.fullRedirectUrl : gwres.generateUrl();

                resp.setData('status', 'success');
                resp.setData('header', 'SignUp succeeded');
                resp.setData('message', result.Message);
                resp.setData('redirectUrl', result.RedirectUrl);
            } catch (NGBSAPI.NGBSAPIException e) {
                resp.addMessages(
                    NGBSAPIExceptionHelper.handleNGBSAPIException(e, Label.Opportunity_SignUp_Validation_SignUp_failed)
                );
            } catch (Exception e) {
                resp.addMessage(
                    Label.Opportunity_SignUp_Validation_SignUp_failed,
                    getSignUpErrorMessage(e),
                    Response.SEVERITY_ERROR
                );
            }

            return resp;
        }

        @TestVisible
        private String getSignUpFunnelResponseBody(String bodyStr, POWrappers.SignUpFunnelUIRequestParams params) {
            if (Test.isRunningTest()) {
                return JSON.serialize(new POWrappers.GWSignUpResponse());
            }
            HttpResponse response = NGBSAPI.requestNGBS(
                params.endpoint,
                HttpHelper.METHOD_POST,
                bodyStr,
                params.contentTypeValue,
                params.headers
            );
            return response.getBody();
        }

        @TestVisible
        private String getSignUpErrorMessage(Exception e) {
            String errorMessage = e.getMessage();

            String st = e.getStackTraceString();
            if (String.isNotBlank(st) && st.trim() != '()') {
                errorMessage += '<br/>' + st;
            }
            return errorMessage;
        }
    }

    public class ProServSignUpRunner extends SignUpRunner {
        public ProServSignUpRunner(POWrappers.SignUpParams data) {
            super(data, new POSignUpBodyHelper.ProServSignUpBodyBuilder());
        }
        public ProServSignUpRunner() {}

        public override Object getRequestBody() {
            return body;
        }

        public override Response signUp() {
            Response resp = new Response();
            FunnelAPI.FunnelResponse res = FunnelAPI.multiProductProServSignUp(opportunity, (POWrappers.SignUpRequestBody) getRequestBody());
            if (res != null && res.result != null) {
                resp.setData('message', res.result);
                resp.setData('data', res);
            }

            return resp;
        }
    }

    public class EventsSignUpRunner extends SignUpRunner {
        public EventsSignUpRunner(POWrappers.SignUpParams data) {
            super(data, new POSignUpBodyHelper.EventsSignUpBodyBuilder());
        }
        public EventsSignUpRunner() {}

        public override Object getRequestBody() {
            return body;
        }

        public override Response signUp() {
            final String errorMessage = 'ERROR! SignUp Failed !!' + '\n';
            final String SUCCESS = 'success';
            Response resp = new Response();
            HttpResponse response = FunnelAPI.multiProductEventsSignUp(opportunity, (POWrappers.SignUpRequestBody) getRequestBody());
            if(response.getStatusCode() > 300){
                FunnelAPI.ErrorWrapper wrapper = (FunnelAPI.ErrorWrapper) JSON.deserialize(response.getBody(), FunnelAPI.ErrorWrapper.class);
                String result = errorMessage;
                if (wrapper != null && wrapper.errors != null) {
                    for (FunnelAPI.ErrorDetail err : wrapper.errors) {
                        result += 'Error Code: ' + err.errorCode + ' | Message: ' + err.message + '\n';
                        resp.error(result);
                    }
                }else {
                    resp.error(errorMessage);
                }  
            }else{
                resp.status = SUCCESS;
            }
            return resp;
        }
    }
}