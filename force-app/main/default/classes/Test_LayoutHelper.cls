@isTest
public class Test_LayoutHelper {
    public final static String LAYOUT_NAME = 'Test Layout';
    @IsTest
    static void testGetLayoutName() {
        Test.setMock(HttpCalloutMock.class, new Mock());
        Test.startTest();
            String name = LayoutHelper.getLayoutName(ApprovalHelper.RT_ID_INVOICING_REQUEST);
        Test.stopTest();
        System.assert(LAYOUT_NAME == name, 'Wrong layout name was retrieved');
    }

    public class Mock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            res.setStatus('OK');
            res.setStatusCode(200);
            res.setBody('"Name":"' + LAYOUT_NAME + '"');
            return res;
        }
    }

    @IsTest
    static void testGetSection() {
        Test.startTest();
            List<LayoutHelper.Section> sections = LayoutHelper.getSections('Case', CaseHelper.LAYOUT_NAME_DEAL_AND_ORDER_SUPPORT);
        Test.stopTest();
        System.assert(sections != null, 'List of sections wrapper was returned for DOS layout on object case');
        System.assertEquals(5, sections.size(), 'For DOS layout must returned 5 sections');
    }
}