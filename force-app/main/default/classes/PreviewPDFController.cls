public class PreviewPDFController {

    public static String content {get;set;}
    public static String styles {get;set;}

    public PreviewPDFController() {
        String objId = ApexPages.currentPage().getParameters().get('objectId');
        String templateId = ApexPages.currentPage().getParameters().get('templateId');
        String templateName = ApexPages.currentPage().getParameters().get('templateName');
	if(templateName != null){
		templateName = EncodingUtil.urlDecode(templateName,'UTF-8');
	}
        
        System.debug('Template name in URL '+ ApexPages.currentPage().getParameters().get('templateName'));
        String templateBody = '';
        String templateStyles = '';
        //TemplateEngine.TemplateName = templateName;
        TemplateEngine.SetSelectedTemplate(templateName);
        Map <String, String> templateParameters = new Map <String, String>();
        String parameters = ApexPages.currentPage().getParameters().get('templateParameters');
        if (String.isNotBlank(parameters)){
            templateParameters = (Map<String, String>) JSON.deserialize(parameters, Map<String, String>.class);
        }

        if (String.isBlank(templateId)){
            templateStyles = ApexPages.currentPage().getParameters().get('templateStyles');
            templateBody = ApexPages.currentPage().getParameters().get('templateBody');

            if (String.isNotBlank(objId)){
                templateBody = TemplateEngine.createFromString(objId, templateBody, templateParameters);
            }
        } else {
            Map<String, Map<String, String>> templateMap = TemplateEngine.getTemplateBody(templateId);
            templateStyles = templateMap.get('template').get('styles');
            if (String.isEmpty(objId)){
                templateBody = templateMap.get('template').get('content');
            } else {
                templateMap.get('parameters').putAll(templateParameters);
                templateBody = TemplateEngine.createFromString(objId, templateMap.get('template').get('content'), templateMap.get('parameters'));
            }
        }

        content = templateBody;
        styles = templateStyles;
    }

    public static Blob getPageContentViaPost(String objectId, String templateId, Map<String, Object> parameters,String TemplateName) {
        VfContextVariables vfContext = VfContextVariables.getVfContextVariables();
        String targetString = EncodingUtil.URLENCODE(TemplateName,'UTF-8');
        HttpRequest req = HttpHelper.prepareHttpRequest(
            vfContext.url + Page.PreviewPDF.getUrl() + '?templateId=' + templateId + '&objectId=' + objectId + '&templateName=' + targetString,
            'POST',
            'templateParameters=' + EncodingUtil.urlEncode(JSON.serialize(parameters), 'UTF-8'),
            'application/x-www-form-urlencoded'
        );
        req.setHeader('Authorization', 'Bearer ' + vfContext.sid);

        HttpResponse resp = (new Http()).send(req);

        return resp.getBodyAsBlob();
    }
}