public with sharing class PicklistController {

    public Sobject targetSobject { get; set; }
    public List<String> targetSobjectFields { get; set; }

    private static final String SOBJECTTYPE_PARAM = 'SObjectType';
    private static final String RECORDTYPENAME_PARAM = 'RecordTypeName';
    private static final String FIELDS_PARAM = 'fields';

    public PicklistController() {

        Map<String, String> pageParams = ApexPages.currentPage().getParameters();

        if(pageParams != null &&
            pageParams.keySet().contains(SOBJECTTYPE_PARAM) && pageParams.keySet().contains(RECORDTYPENAME_PARAM)) {
            initSpecificSobject(pageParams);
        }else {
            initDefaultSobject(pageParams);
        }
    }

    private void initDefaultSobject(Map<String, String> pageParams) {

        Set<String> requiredFields = new Set<String>{
            'type__c',
            'add_ons__c',
            'accomodations__c',
            'feature_add_ons__c',
            'change_order_types__c'
        };

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

        Schema.SObjectType mySobjType = ((SObject)Type.forName('Approval__c').newInstance()).getSObjectType();

        Map<String, Schema.RecordTypeInfo> rtInfoByName = mySobjType.getDescribe().getRecordTypeInfosByName();

        targetSobject = mySobjType.newSObject();
        targetSobject.put('RecordTypeId', rtInfoByName.get('Engage Legal').getRecordTypeId());

        List<String> targetSobjPickLists = new List<String>();
        Map<String, Schema.SObjectField> sobjDescr = mySobjType.getDescribe().fields.getMap();
        for(String fName : sobjDescr.keySet()) {
            if((sobjDescr.get(fName).getDescribe().getType() == Schema.DisplayType.PICKLIST ||
                sobjDescr.get(fName).getDescribe().getType() == Schema.DisplayType.MULTIPICKLIST) && requiredFields.contains(fName)) {
                targetSobjPickLists.add(fName);
            }
        }
        targetSobjectFields = targetSobjPickLists;
    }

    private void initSpecificSobject(Map<String, String> pageParams) {

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

    static public String getFragment(String tag) {
        Integer parentTagFragmentEnd = tag.indexOf(' ');

        if (parentTagFragmentEnd < 0) {
            parentTagFragmentEnd = tag.indexOf('>');
            if (parentTagFragmentEnd < 0) {
                parentTagFragmentEnd = tag.length();
            }
        }

        return tag.left(parentTagFragmentEnd);
    }
    
    static public String getTagClose(String parentTagFragment) {
        return parentTagFragment.replace('<','</') + '>';
    }
    
    public class Option {
        public String Value;
        public String Label;
        
        public Option(String value, String label) {
            this.Value = value;
            this.Label = label;
        }
    }
    public class Picklist {
        public String Name;
        public List<Option> Options;
        
        public Picklist(String name) {
            this.Name = name;
            this.Options = new List<Option>();
        }
    }

    static public List<Picklist> parse(String html, String parentTag, String childTag) {

        List<Picklist> result = new List<Picklist>();

        Integer idx = 0;
        String parentTagFragment = getFragment(parentTag);
        String parentTagClose = getTagClose(parentTagFragment);
        Integer parentTagCloseLen = parentTagClose.length();

        while (idx <= html.length()) {
            
            idx = html.indexOf(parentTag, idx);
            if (idx == -1) {
                break;
            }
            Integer nextCloseTag = html.indexOf(parentTagClose, idx + 1);
            Integer objectEndIdx = (nextCloseTag + parentTagCloseLen);
            String parentTagEnclosure = html.substring(idx, objectEndIdx);

            String name = getAttributeValue(parentTagEnclosure, 'data-id');
            String myId = getAttributeValue(parentTagEnclosure, 'id');

            if( !myId.contains('_unselected') && !myId.contains('_selected')) {

                Picklist picklist = new Picklist(name);
                Integer sIdx = 0;
                String childTagFragment = getFragment(childTag);
                String childTagClose = getTagClose(childTagFragment);
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

                    String value = getAttributeValue(childTagEnclosure, 'value');
                    String label = getText(parentTagEnclosure, childTagEnd, childObjectEndIdx - childTagCloseLen);

                    Option option = new Option(value, label);
                    picklist.Options.add(option);

                    sIdx = childObjectEndIdx;
                }

                result.add(picklist);
            }

            idx = objectEndIdx;
        }

        return result;
    }

    public static String getText(String parentTagEnclosure, Integer childTagEnd, Integer childObjectEndIdx) {
        Integer valueReadStart = (childTagEnd + 2);
        Integer valueReadEnd = childObjectEndIdx;

        return parentTagEnclosure.substring(valueReadStart, valueReadEnd);
    }

    public static String getAttributeValue(String tagValue, String attributeName) {
        String valueToReturn = '';

        if (!String.isBlank(tagValue) && !String.isBlank(attributeName)) {
            Integer attributeIdx = tagValue.indexOf(' '+attributeName+'=');
            if (attributeIdx >= 0) {
                Integer valueStart = tagValue.indexOf('"', attributeIdx) + 1;
                Integer valueEnd = tagValue.indexOf('"', valueStart + 1);
                if (valueStart >= 0 && valueEnd >= 0) {
                    valueToReturn = tagValue.substring(valueStart, valueEnd);
                }
            }
        }

        return valueToReturn;
    }
}