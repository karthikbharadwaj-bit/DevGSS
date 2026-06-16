public with sharing class PicklistSiteopsController {

    public Sobject targetSobject { get; set; }
    public List<String> targetSobjectFields { get; set; }
    public String selectedLanguage { get; set; }

    public static final String SOBJECTTYPE_PARAM = 'SObjectType';
    public static final String RECORDTYPENAME_PARAM = 'RecordTypeName';
    public static final String FIELDS_PARAM = 'fields';
    public static final String LANG_PARAM = 'lang';

    public static final String DEFAULT_LANG_PARAM = 'en_US';

    public PicklistSiteopsController() {

        Map<String, String> pageParams = ApexPages.currentPage().getParameters();

        selectedLanguage = (pageParams != null && pageParams.containsKey(LANG_PARAM)) ?
            pageParams.get(LANG_PARAM) :
            DEFAULT_LANG_PARAM;

        initSpecificSobject(pageParams);
    }

    private void initSpecificSobject(Map<String, String> pageParams) {

        system.debug('Nico -- pageParams: ' + pageParams);

        String sobjType = pageParams.get(SOBJECTTYPE_PARAM);
        String rtName = pageParams.get(RECORDTYPENAME_PARAM);

        Schema.SObjectType mySobjType = ((SObject)Type.forName(sobjType).newInstance()).getSObjectType();

        Map<String, Schema.RecordTypeInfo> rtInfoByName = mySobjType.getDescribe().getRecordTypeInfosByName();

        targetSobject = mySobjType.newSObject();
        targetSobject.put('RecordTypeId', rtInfoByName.get(rtName).getRecordTypeId());

        Set<String> requiredFields = new Set<String>();
        // if FIELDS_PARAM is presented - add these fields in requiredFields set
        if(!String.isBlank(pageParams.get(FIELDS_PARAM))) {
            String fieldsParam = pageParams.get(FIELDS_PARAM);
            fieldsParam = fieldsParam.toLowerCase();

            if(fieldsParam.contains(',')) {
                requiredFields.addAll(fieldsParam.split(','));
            }else{
                requiredFields.add(fieldsParam);
            }
        }

        List<String> targetSobjPickLists = new List<String>();
        Map<String, Schema.SObjectField> sobjDescr = mySobjType.getDescribe().fields.getMap();

        for(String fName : sobjDescr.keySet()) {
            if(sobjDescr.get(fName).getDescribe().getType() == Schema.DisplayType.PICKLIST ||
                sobjDescr.get(fName).getDescribe().getType() == Schema.DisplayType.MULTIPICKLIST) {

                if(requiredFields.isEmpty()) {
                    targetSobjPickLists.add(fName);
                }else if(requiredFields.contains(fName)){
                    targetSobjPickLists.add(fName);
                }
            }
        }
        targetSobjectFields = targetSobjPickLists;
    }

    static public List<Picklist> parse(String html, String parentTag, String childTag) {
        return parse(html, parentTag, childTag, false);
    }

    static public List<Picklist> parse(String html, String parentTag, String childTag, Boolean hasDependentField) {

        List<Picklist> result = new List<Picklist>();

        Integer idx = 0;
        Integer furthestIdx = 0;
        String parentTagFragment = PicklistController.getFragment(parentTag);
        String parentTagClose = PicklistController.getTagClose(parentTagFragment);
        Integer parentTagCloseLen = parentTagClose.length();

        while (idx <= html.length()) {
            
            idx = html.indexOf(parentTag, idx);
            if (idx == -1) {
                break;
            }  
            Integer nextCloseTag = html.indexOf(parentTagClose, idx + 1);
            Integer objectEndIdx = (nextCloseTag + parentTagCloseLen);
            String parentTagEnclosure = html.substring(idx, objectEndIdx);

            String name = PicklistController.getAttributeValue(parentTagEnclosure, 'data-id');
            String myId = PicklistController.getAttributeValue(parentTagEnclosure, 'id');

            if( !myId.contains('_unselected') && !myId.contains('_selected')) {

                Picklist picklist = new Picklist(name);
                Integer sIdx = 0;
                String childTagFragment = PicklistController.getFragment(childTag);
                String childTagClose = PicklistController.getTagClose(childTagFragment);
                Integer childTagCloseLen = parentTagClose.length();

                while (sIdx <= parentTagEnclosure.length()) {
                    sIdx = parentTagEnclosure.indexOf(childTag, sIdx);
                    if (sIdx == -1) {
                        break;
                    }
                    Integer nextChildCloseTag = parentTagEnclosure.indexOf(childTagClose, sIdx + 1);
                    Integer childObjectEndIdx = (nextChildCloseTag + childTagCloseLen);
                    String childTagEnclosure = parentTagEnclosure.substring(sIdx, childObjectEndIdx);
                    Integer childTagEnd = parentTagEnclosure.indexOf('">', sIdx);

                    String value = PicklistController.getAttributeValue(childTagEnclosure, 'value');
                    String label = PicklistController.getText(parentTagEnclosure, childTagEnd, childObjectEndIdx - childTagCloseLen);

                    SCWrappers.BaseOption option = new SCWrappers.BaseOption(value, label);
                    picklist.Options.add(option);

                    sIdx = childObjectEndIdx;
                }

                result.add(picklist);
            }

            if (objectEndIdx != -1) {
                furthestIdx = objectEndIdx;
            }
            idx = objectEndIdx;
        }

        //Only works for ONE dependent field. If there is more than 1 dependent field in the HTML, it will return the first one it finds.
        if (hasDependentField && furthestIdx != -1) {
            //Example of value: pl.vals_00N80000005HvdP_01280000000UIfJ=['value1','label1','value2','label2'];
            Integer indexStartVals = html.indexOf('vals_', furthestIdx);
            if(indexStartVals != -1) {
                Integer indexEndVals = html.indexOf('\'];', indexStartVals);
    
                String values = html.substring(indexStartVals, indexEndVals);

    
                List<String> valuesList = values.replaceAll('\',\'', '____')
                    .substring(values.indexOf('[') + 2)
                    .split('____');

                Picklist picklist = new Picklist('Dependent field');
                for (Integer i=0 ; i< valuesList.size() - 1; i+=2) {
                    picklist.Options.add(new SCWrappers.BaseOption(valuesList[i], valuesList[i + 1]));
                }
                result.add(picklist);
            }
        }

        return result;
    }

    public class Picklist {
        public String Name;
        public List<SCWrappers.BaseOption> Options;
        
        public Picklist(String name) {
            this.Name = name;
            this.Options = new List<SCWrappers.BaseOption>();
        }
    }
}