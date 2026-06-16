@RestResource(urlMapping='/rccc/nic/case/create')
global class CaseCreateServiceICB {

    public static final String BAD_REQUEST_MESSAGE = 'HTTP error - Bad request';
    public static final String BAD_REQUEST_PARAMS = 'opportunityId parameter is required';
    public static final String BAD_REQUEST_OPP_ID = 'Opportunity with this Id does not exist';
    public static final String BAD_REQUEST_CASE_NOT_FOUND = 'Opportunity with this Id does not exist';

    class CaseCreateValidationException extends Exception {
        List<IcbHelper.IcbMessage> messages;

        public CaseCreateValidationException(List<IcbHelper.IcbMessage> icbMessages) {
            messages = icbMessages;
        }
    }

    class CaseCreateState {
        List<IcbHelper.IcbMessage> validationFailsMessages;
        Case icbCase;

        public CaseCreateState(List<IcbHelper.IcbMessage> errorMessages) {
            this.validationFailsMessages = errorMessages;
        }

        public CaseCreateState(Case cs) {
            this.icbCase = cs;
        }
    }

    @HttpPost
    global static void createCase() {
        String body = RestContext.request.requestBody.toString();
        if (RestContext.response == null) {
            RestContext.response = new RestResponse();
        }

        try {
            CaseCreateState state = processRequestBody(body);
            if (state.validationFailsMessages != null) {
                throw new CaseCreateValidationException(state.validationFailsMessages);
            }

            IcbHelper.setResponse(
                state.icbCase,
                PartnerNetworkConnectionHelper.selectPnrcByLocalRecordId(state.icbCase.Id)
            );

        } catch (CaseCreateValidationException e) {
            IcbHelper.handleError(e.messages);
        } catch (JSONException e) {
            IcbHelper.handleError(e);
        } catch (Exception e) {
            IcbHelper.handleError(e);
        }
    }

    private static CaseCreateState processRequestBody(String body) {
        IcbHelper.ICBCaseRequest params = (IcbHelper.ICBCaseRequest) JSON.deserialize(body, IcbHelper.ICBCaseRequest.class);

        List<IcbHelper.IcbMessage> errorMessages = validateRequest(params);
        if (errorMessages != null) {
            return new CaseCreateState(errorMessages);
        }

        Opportunity opp = IcbHelper.selectOpportunityForInContactCaseSharing(params.opportunityId);
            
        errorMessages = validateSObject(opp, BAD_REQUEST_OPP_ID);
        if (errorMessages != null) {
            return new CaseCreateState(errorMessages);
        }

        Case icbCase = IcbHelper.selectICBCase(opp);

        errorMessages = validateSObject(icbCase, BAD_REQUEST_CASE_NOT_FOUND);
        return errorMessages != null
            ? new CaseCreateState(errorMessages)
            : new CaseCreateState(icbCase);
    }

    private static List<IcbHelper.IcbMessage> validateRequest(IcbHelper.ICBCaseRequest params) {
        return validate(String.isBlank(params.opportunityId), BAD_REQUEST_PARAMS);
    }

    private static List<IcbHelper.IcbMessage> validateSObject(SObject sObj, String errorMessage) {
        return validate(sObj == null, errorMessage);
    }

    private static List<IcbHelper.IcbMessage> validate(Boolean condition, String messageIfFailed) {
        return condition ? getErrorState(messageIfFailed) : null;
    }

    private static List<IcbHelper.IcbMessage> getErrorState(String message) {
        return IcbHelper.createErrorList(BAD_REQUEST_MESSAGE, message);
    }
}