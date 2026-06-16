public without sharing class PrmCaseCreateHelper {

    @AuraEnabled
    public static Response getLayout() {
        Response resp = new Response();

        List<LayoutHelper.Section> sections = LayoutHelper.getSections('Case', CaseHelper.LAYOUT_NAME_DEAL_AND_ORDER_SUPPORT);
        resp.setData('layout', JSON.serialize(sections));

        return resp;
    }

    @AuraEnabled
    public static Response createCases(String caseListJSON) {
        Response resp = new Response();
        try {
            AssignmentRule caseAssignmentRule = (AssignmentRule) new ListOptional(new AssignmentRuleSelector()
                .selectAssignmentRuleBySObject('Case')
                .executeQuery()
            ).getFirst();
            Database.DMLOptions dmlOptions = new Database.DMLOptions();
            dmlOptions.assignmentRuleHeader.assignmentRuleId = caseAssignmentRule.Id;
            List<Case> caseList = (List<Case>) JSON.deserialize(caseListJSON, List<Case>.class);
            Database.insert(caseList,dmlOptions);
        } catch(Exception ex) {
            resp.error(ex);
        }
        return resp;
    }
}