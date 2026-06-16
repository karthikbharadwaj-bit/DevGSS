@IsTest
public class Test_PreviewPDFController {

    @isTest
    static void testContentAsParams() {
        String templateStyles = 'body{font-size: 12pt}';
        String templateBody = '[{! $params.foo }][{! Name }]';
        Map <String, String> templateParametersMap = new Map <String, String>{
                'foo' => 'bar'
        };

        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        PageReference pageRef = Page.PreviewPDF;
        Test.setCurrentPageReference(pageRef);
        pageRef.getParameters().put('objectId', testAccount.Id);
        pageRef.getParameters().put('templateBody', templateBody);
        pageRef.getParameters().put('templateStyles', templateStyles);
        pageRef.getParameters().put('templateParameters', JSON.serialize(templateParametersMap));
        PreviewPDFController cs = new PreviewPDFController();

        System.assertEquals('[bar][Test Account]' , PreviewPDFController.content);
        System.assertEquals(templateStyles , PreviewPDFController.styles);
    }

    @isTest
    static void testContentFromTemplate() {
        String templateStyles = 'body{font-size: 12pt}';
        String templateBody = '{! $params.foo },{! Name },{! $params.foo2 }';
        Map <String, String> templateParametersMap = new Map <String, String>{
                'foo' => 'bar'
        };
        String templateParameters = JSON.serialize(templateParametersMap);

        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        RC_Quote_Template__c testTemplate = new RC_Quote_Template__c(
                Name = 'test',
                Brand__c = 'RingCentral',
                Description__c = 'test123',
                Type__c = 'test',
                Language__c = 'English',
                Parameters__c = templateParameters,
                CSS_Styles_1__c = templateStyles
        );

        insert testTemplate;

        TemplateSections__c section = new TemplateSections__c(
                Name='Section Name',
                Content_1__c = 'Hello',
                Content_2__c = templateBody,
                CSS_Styles_1__c = 'html{ color: red;}'
        );
        insert section;

        TemplateSectionJunction__c junction = new TemplateSectionJunction__c(
                Position__c = 1,
                RC_Quote_Template__c = testTemplate.id,
                Template_Section__c = section.id
        );
        insert junction;


        PageReference pageRef = Page.PreviewPDF;
        Test.setCurrentPageReference(pageRef);
        
        pageRef.getParameters().put('templateId', testTemplate.Id);
        PreviewPDFController cs = new PreviewPDFController();

        System.assertEquals(section.Content_1__c + section.Content_2__c, PreviewPDFController.content);
        System.assertEquals(testTemplate.CSS_Styles_1__c + section.CSS_Styles_1__c, PreviewPDFController.styles);

        pageRef.getParameters().put('objectId', testAccount.Id);
        pageRef.getParameters().put('templateParameters', JSON.serialize(new Map <String, String>{'foo2' => 'bar2'}));
        cs = new PreviewPDFController();

        List<String> contentParts = PreviewPDFController.content.split(',');
        System.assertEquals(section.Content_1__c + 'bar', contentParts[0], 'Wrong merge of template parameters.');
        System.assertEquals(testAccount.Name, contentParts[1], 'Wrong merge of object data.');
        System.assertEquals('bar2', contentParts[2], 'Wrong merge of passed parameters.');
        System.assertEquals(testTemplate.CSS_Styles_1__c + section.CSS_Styles_1__c, PreviewPDFController.styles);
    }

    @isTest
    private static void testGetPageContentViaPost() {
        PreviewPdfPageMock mock = new PreviewPdfPageMock();
        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();

            String pageContent = PreviewPDFController.getPageContentViaPost(mock.OBJ_ID, mock.TEMPLATE_ID, mock.PARAMETERS,mock.Template_Name).toString();

        Test.stopTest();

        // pageContent contains error if test failed
        System.assertEquals(mock.PREVIEW_PDF_PAGE_CONTENT, pageContent, pageContent);
    }

    public class PreviewPdfPageMock implements HttpCalloutMock {

        public final String PREVIEW_PDF_PAGE_CONTENT = 'TEST_PREVIEW_PDF_PAGE_CONTENT';
        public final String OBJ_ID = 'fakeObjId';
        public final String TEMPLATE_ID = 'fakeTemplateId';
        public final Map<String,Object> PARAMETERS = new Map<String,String>{'fakeParameter' => 'fakeValue'};
        public final String Template_Name = 'fakeTemplateName';

        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse resp = new HTTPResponse();

            String validationResult = validateRequest(req);

            if (validationResult == null) {
                resp.setBody(PREVIEW_PDF_PAGE_CONTENT);
            } else {
                resp.setBody(validationResult);
            }
            return resp;
        }

        private String validateRequest(HttpRequest req) {
            String url = req.getEndpoint();

            if (!url.containsIgnoreCase(Page.PreviewPDF.getUrl())
                || !url.startsWithIgnoreCase(TestVfContextVariables.fakeUrl)
            ) {
                return 'Wrong page URL.';
            }

            if (req.getMethod() != 'POST') {
                return 'Wrong request method.';
            }

            if (req.getHeader('Authorization') != 'Bearer ' + TestVfContextVariables.fakeSid) {
                return 'Wrong Authorization header.';
            }

            if (req.getHeader('Content-Type') != 'application/x-www-form-urlencoded') {
                return 'Wrong Content-Type header.';
            }

            return null;
        }

    }
    
}