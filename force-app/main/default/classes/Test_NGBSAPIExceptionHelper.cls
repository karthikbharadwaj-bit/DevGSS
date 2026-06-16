@IsTest
private class Test_NGBSAPIExceptionHelper {
    @IsTest
    private static void testHandleNGBSAPIExceptionSingle() {
        String errorBodySingleMessage = 'Object [account] not found for [id = 22045860021]';
        String errorMessage = JSON.serialize(new NGBSAPIExceptionHelper.ExceptionMessage(
            null,
            null,
            '{"code":404,"message":"' + errorBodySingleMessage + '"}'
        ));

        List<Response.ResponseMessage> responseMessages = NGBSAPIExceptionHelper.handleNGBSAPIException(
            new NGBSAPI.NGBSAPIException(errorMessage),
            Label.Opportunity_SignUp_Validation_SignUp_failed
        );
        System.assertEquals(
            errorBodySingleMessage,
            responseMessages[0].messageDetails,
            'message details should be here'
        );
    }

    @IsTest
    private static void testHandleNGBSAPIExceptionMulti() {
        String errorBodyMultiMessage = 'error details';
        String errorMessageList = JSON.serialize(new NGBSAPIExceptionHelper.ExceptionMessage(
            null,
            null,
            '{"status":"error","messages":[{"severity":"error","message":"' + errorBodyMultiMessage + '"}]}'
        ));

        List<Response.ResponseMessage> responseMessagesList = NGBSAPIExceptionHelper.handleNGBSAPIException(
            new NGBSAPI.NGBSAPIException(errorMessageList),
            Label.Opportunity_SignUp_Validation_SignUp_failed
        );
        System.assertEquals(
            errorBodyMultiMessage,
            responseMessagesList[0].messageDetails,
            'message details should be here'
        );
    }

    @IsTest
    private static void testHandleNGBSAPIExceptionNotValid() {
        List<Response.ResponseMessage> responseMessages = NGBSAPIExceptionHelper.handleNGBSAPIException(
            new NGBSAPI.NGBSAPIException('some not valid JSON'),
            Label.Opportunity_SignUp_Validation_SignUp_failed
        );
        System.assert(!responseMessages.isEmpty(), 'Not valid JSON should case an error');

        String errorMessageList = JSON.serialize(new NGBSAPIExceptionHelper.ExceptionMessage(
            null,
            null,
            'not valid body'
        ));

        responseMessages = NGBSAPIExceptionHelper.handleNGBSAPIException(
            new NGBSAPI.NGBSAPIException(errorMessageList),
            Label.Opportunity_SignUp_Validation_SignUp_failed
        );

        System.assert(!responseMessages.isEmpty(), 'Not valid body should case an error');
    }
}