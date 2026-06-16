public class VfContextVariables {

    public static final String JSON_START_MARKER {get{return 'JSON_START_MARKER';}}
    public static final String JSON_END_MARKER {get{return 'JSON_END_MARKER';}}

    public String url;
    public String sid;

    public static VfContextVariables getVfContextVariables() {

        VfContextVariables vfContext = new VfContextVariables();

        String pageContent;
        if (Test.isRunningTest()) {
            pageContent = JSON_START_MARKER + '{"sid": "' + TestVfContextVariables.fakeSid +
                '", "url": "' +TestVfContextVariables.fakeUrl + '/apex/vfcontextvariables"}' + JSON_END_MARKER;
        } else {
            pageContent = Page.VfContextVariables.getContent().toString();
        }

        String vfContextJson = pageContent.substringBetween(JSON_START_MARKER, JSON_END_MARKER);
        vfContext = (VfContextVariables) JSON.deserialize(vfContextJson, VfContextVariables.class);
        vfContext.url = vfContext.url.substringBefore(Page.VfContextVariables.getUrl());

        return vfContext;
    }

}