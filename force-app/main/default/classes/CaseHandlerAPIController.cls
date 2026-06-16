public with sharing class CaseHandlerAPIController {
    public static Map<String, Object> caseHandler(String request) {
        Map<String, Object> res = new Map<String, Object>();

        try {
            Map<String, Object> req = CaseAPIUtil.deserializeRequest(request);

            String action = StringHelper.safeString(req.get('action'));

            CaseHandlerStrategy.ICaseHandler handler = CaseHandlerStrategy.getStrategy(action);

            handler.validate(req);

            res = handler.execute(req);
        } catch (Exception e) {
            CaseAPIUtil.addErrorMessage(res, e.getMessage());
        }
        return res;
    }
}