public class CaseCreationPageController {
    public CaseCreationPageController(ApexPages.StandardController stdController) {}

    public static PageReference checkAccess() {
        // get Record Type name
        System.PageReference currentPage = ApexPages.currentPage();
        String recordTypeId = currentPage.getParameters().get('RecordType');
        CustomPermissionHelper cp = new CustomPermissionHelper();

        // check record Type Name
        if (recordTypeId != CaseHelper.RT_ID_SUPPORT_T1
                || !cp.hasPermission(CustomPermissionHelper.PERMISSION_ALTERNATIVE_CASE_CREATION)) {
            Map <String, String> urlParams = currentPage.getParameters();
            urlParams.remove('save_new');
            urlParams.remove('sfdc.override');
            PageReference standardCaseCreation = new PageReference('/500/e');
            standardCaseCreation.getParameters().putAll(urlParams);
            standardCaseCreation.getParameters().put('nooverride', '1');

            standardCaseCreation.setRedirect(true);
            return standardCaseCreation;
        }
        return null;

    }

}