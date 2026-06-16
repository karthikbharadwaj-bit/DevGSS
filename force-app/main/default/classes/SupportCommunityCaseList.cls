public with sharing class SupportCommunityCaseList {
    public static final String LABEL_CASES = 'caseManagement';
    public static final String LABEL_CSV = 'csv';
    public static final String LABEL_ISADMIN = 'isAdmin';
    public static final List<String> FIELDS_TO_CONVERT = new List<String> {
        'CaseNumber', 'Subject', 'CreatedDate', 'Status', 'Contact.Name'
    };

    @AuraEnabled(Cacheable=true)
    public static Response getCases(String request) {
        Response res = new Response();

        try {
            SCWrappers.CaseSearchRequest searchRequest =
                (SCWrappers.CaseSearchRequest) JSON.deserialize(request, SCWrappers.CaseSearchRequest.class);

            SCWrappers.CaseListView cases = SCCaseService.getCasesForCaseListView(searchRequest);
            res.setData(LABEL_CASES, cases);
        } catch (Exception e) {
            res.error(e.getMessage());
        }

        return res;
    }

    @AuraEnabled(Cacheable=true)
    public static Response downloadAsCSV(String request) {
        Response res = new Response();

        try {
            SCWrappers.CaseSearchRequest searchRequest =
                (SCWrappers.CaseSearchRequest) JSON.deserialize(request, SCWrappers.CaseSearchRequest.class);
            res.setData(
                LABEL_CSV,
                new CsvBuilder().createCSV(
                    SCCaseService.getCasesForCSV(searchRequest),
                    FIELDS_TO_CONVERT
                )
            );
        } catch (Exception e) {
            res.error(e.getMessage());
        }

        return res;
    }

    @AuraEnabled(Cacheable=true)
    public static Response isCurrentUserSCAdmin() {
        Response res = new Response();

        try {
            res.setData(LABEL_ISADMIN, SCUserService.isCurrentUserSCAdmin);
            return res;
        } catch (Exception e) {
            res.error(e.getMessage());
        }

        return res;
    }
}