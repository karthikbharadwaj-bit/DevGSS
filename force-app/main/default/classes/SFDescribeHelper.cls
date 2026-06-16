/**
 * This class helps get fields data from salesforce
 */
public class SFDescribeHelper {

    public static final String SOBJECT_NAME_USER = 'User';

    //----------------------------------- GETTING DEPENDANT PICKLISTS -----------------------------------//
    //copy-pasted from http://titancronus.com/blog/2014/07/03/acquiring-dependent-picklists-in-apex-contd/ from Paul N's comment.
    // **********************************************************************************************************************************
    // ********** GetDependentOptions ***************************************************************************************************
    // **********************************************************************************************************************************
    // Map<String,List<String>> GetDependentOptions (String pObjName, String pControllingFieldName, String pDependentFieldName)
    // Returns: Map of "pControllingFieldName" picklist values and their corresponding "pDependentFieldName" dependent option values.
    // **********************************************************************************************************************************

    /*
     * @Summary: Entity to represent a json version of a picklist entry
     * so that the validFor property becomes exposed
     */
    public class TPicklistEntry {
        public String active { get; set; }
        public String defaultValue { get; set; }
        public String label { get; set; }
        public String value { get; set; }
        public String validFor { get; set; }
        public TPicklistEntry() {}
        public TPicklistEntry(String value) {
            this.label = value;
            this.value = value;
        }
    }


    // Converts a base64 string into a list of integers representing the encoded bytes
    public static List<Integer> B64ToBytes (String sIn) {
        Map<Integer,Integer> base64 = new Map<Integer,Integer>{65=>0,66=>1,67=>2,68=>3,69=>4,70=>5,71=>6,72=>7,73=>8,74=>9,75=>10,76=>11,77=>12,78=>13,79=>14,80=>15,81=>16,82=>17,83=>18,84=>19,85=>20,86=>21,87=>22,88=>23,89=>24,90=>25
                                                               ,97=>26,98=>27,99=>28,100=>29,101=>30,102=>31,103=>32,104=>33,105=>34,106=>35,107=>36,108=>37,109=>38,110=>39,111=>40,112=>41,113=>42,114=>43,115=>44,116=>45,117=>46,118=>47,119=>48,120=>49,121=>50,122=>51
                                                               ,48=>52,49=>53,50=>54,51=>55,52=>56,53=>57,54=>58,55=>59,56=>60,57=>61,43=>62,47=>63};

        List<Integer> lstOut = new List<Integer>();
        if ( sIn == null || sIn == '' ){
            return lstOut;
        }
        sIn += '='.repeat( 4 - Math.mod( sIn.length(), 4) );

        for ( Integer idx=0; idx < sIn.length(); idx += 4 ) {
            if ( base64.get(sIn.charAt(idx+1)) != null ){
                lstOut.add( (base64.get(sIn.charAt(idx)) << 2) | (base64.get(sIn.charAt(idx+1)) >>> 4) );
            }
            if ( base64.get(sIn.charAt(idx+2)) != null ){
                lstOut.add( ((base64.get(sIn.charAt(idx+1)) & 15)<<4) | (base64.get(sIn.charAt(idx+2)) >>> 2) );
            }
            if ( base64.get(sIn.charAt(idx+3)) != null ){
                lstOut.add( ((base64.get(sIn.charAt(idx+2)) & 3)<<6) | base64.get(sIn.charAt(idx+3)) );
            }
        }

        return lstOut;
    }//B64ToBytes

    // Converts a base64 string into a list of integers indicating at which position the bits are on
    public static List<Integer> cnvBits (String b64Str) {
        List<Integer> lstOut = new List<Integer>();
        if ( b64Str == null || b64Str == '' ){
            return lstOut;
        }
        List<Integer> lstBytes = B64ToBytes(b64Str);

        Integer i;
        Integer b;
        Integer v;
        for ( i = 0; i < lstBytes.size(); i++ ) {
            v = lstBytes[i];
            for ( b = 1; b <= 8; b++ ) {
                if ( ( v & 128 ) == 128 ){
                    lstOut.add( (i*8) + b );
                }
                v <<= 1;
            }
        }
        return lstOut;
    }//cnvBits

    public static Map<String,List<String>> GetDependentOptions(String pObjName, String pControllingFieldName, String pDependentFieldName) {
        Map<String,List<String>> mapResults = new Map<String,List<String>>();

        //verify/get object schema
        Schema.SObjectType pType = ((SObject)Type.forName(pObjName).newInstance()).getSObjectType();
        if ( pType == null ){ 
            return mapResults;
        }
        Map<String, Schema.SObjectField> objFieldMap = pType.getDescribe().fields.getMap();

        //verify field names
        if (!objFieldMap.containsKey(pControllingFieldName) || !objFieldMap.containsKey(pDependentFieldName)){
             return mapResults;
        }
        //get the control & dependent values
        List<Schema.PicklistEntry> ctrl_ple = objFieldMap.get(pControllingFieldName).getDescribe().getPicklistValues();
        List<Schema.PicklistEntry> dep_ple = objFieldMap.get(pDependentFieldName).getDescribe().getPicklistValues();

        //clear heap
        objFieldMap = null;

        //initialize results mapping
        for(Integer pControllingIndex=0; pControllingIndex<ctrl_ple.size(); pControllingIndex++){
            mapResults.put( ctrl_ple[pControllingIndex].getLabel(), new List<String>());
        }

        //serialize dep entries
        List<SFDescribeHelper.TPicklistEntry> objDS_Entries = new List<SFDescribeHelper.TPicklistEntry>();
        objDS_Entries = (List<SFDescribeHelper.TPicklistEntry>)JSON.deserialize(JSON.serialize(dep_ple), List<SFDescribeHelper.TPicklistEntry>.class);

        List<Integer> validIndexes;
        for (SFDescribeHelper.TPicklistEntry objDepPLE : objDS_Entries){

            validIndexes = cnvBits(objDepPLE.validFor);

            for (Integer validIndex : validIndexes){
                mapResults.get( ctrl_ple[validIndex-1].getLabel() ).add( objDepPLE.label );
            }
        }

        //clear heap
        objDS_Entries = null;

        return mapResults;
    }

    //----------------------------------- OVER GETTING DEPENDANT PICKLISTS -----------------------------------//

    /*
     *  Get picklist options
     */
    public static List<Schema.PicklistEntry> getOptions(String objName, String fieldName) {
        return getOptions(objName, fieldName, false);
    }
    public static List<Schema.PicklistEntry> getOptions(String objName, String fieldName, Boolean addEmptyValue) {
        List<Schema.PicklistEntry> picklistValues = new List<Schema.PicklistEntry>();
        String[] types = new String[]{objName};
        Schema.DescribeSobjectResult[] results = Schema.describeSObjects(types);
        Schema.DescribeSobjectResult res = results[0];
        picklistValues =   res.fields.getMap().get(FieldName).getDescribe().getPicklistValues();
        if(addEmptyValue == true) {
            picklistValues.add(0, (PicklistEntry) JSON.deserialize('{"value": "", "label": "--None--", "defaultValue": false, "active": true }', PicklistEntry.class));
        }
        return picklistValues;
    }

    /*
     *  Get picklist options mapped by labels
     */
    public static Map<String, Schema.PicklistEntry> getOptionsMap(String objName, String fieldName) {
        Map<String, Schema.PicklistEntry> result = new Map<String, Schema.PicklistEntry>();
        String[] types = new String[]{objName};
        Schema.DescribeSobjectResult[] describes = Schema.describeSObjects(types);
        Schema.DescribeSobjectResult res = describes[0];
        for (Schema.PicklistEntry pe : res.fields.getMap().get(fieldName).getDescribe().getPicklistValues()) {
            result.put(pe.getLabel(), pe);
        }

        return result;
    }

    public static String DOT_NOTATION_PATTERN = '(\\w+)';
    public static Object getSObjectField(SObject obj, String fieldName) {
        Object fieldValue = null;
        Matcher dotNotationMatcher = Pattern.compile(DOT_NOTATION_PATTERN).matcher(fieldName);
        List<String> fieldParts = new List<String>();

        while (dotNotationMatcher.find()) {
            fieldParts.add(dotNotationMatcher.group(1));
        }

        Integer fieldPartsSize = fieldParts.size();
        Integer i = 1;
        for (String part : fieldParts) {
            if (obj == null) {
                break;
            } else if (fieldPartsSize == i) {
                fieldValue = obj.get(part);
            } else {
                obj = obj.getSObject(part);
            }
            i++;
        }

        return fieldValue;
    }

    /**
     *  Get Object Name by Id
     */
    public static String getObjectNameById(Id objId) {
        return objId.getSObjectType().getDescribe().getName();
    }

    public static Metadata.Layout getLayoutInfo(String objectName, String layoutName){
        String componentName = String.format('{0}-{1}', new List<String>{
                objectName,
                layoutName
        });
        List<Metadata.Metadata> components = Metadata.Operations.retrieve(
                Metadata.MetadataType.Layout,
                new List<String>{
                        componentName
                }
        );
        Metadata.Layout opptyLayout = (Metadata.Layout) components.get(0);

        return opptyLayout;
    }

    public static Schema.DescribeFieldResult getNameField(String sObjectName){
        for(Schema.SObjectField fld: ((SObject) Type.forName(sObjectName).newInstance()).getSObjectType().getDescribe().fields.getMap().values()) {
            if (fld.getDescribe().isNameField()) {
                return fld.getDescribe();
            }
        }
        return null;
    }

    public static Boolean isValidSalesforceId(String stringValueId, Schema.SObjectType sObjectType) {

        Boolean isValid = false;

        if (stringValueId InstanceOf Id) {
            Id sObjectId = (Id)stringValueId;
            if (sObjectId.getSObjectType() == sObjectType) {
                isValid = true;
            }
        }
        return isValid;
    }

    public static List<PicklistController.Picklist> getPicklistOptions(String sObjectName, String recordTypeName, String fieldName) {

        String picklistPageUrlParams = '?' + 'SObjectType=' + sObjectName +
            '&RecordTypeName=' + recordTypeName +
            '&fields=' + fieldName;

        System.debug(picklistPageUrlParams);

        PageReference pr = new PageReference('/apex/Picklist' + picklistPageUrlParams);
        String htmlContent = pr.getContent().toString().unescapeHtml4();
        List<PicklistController.Picklist> picklists = PicklistController.parse(htmlContent, '<select ', '<option ');

        return picklists;
    }

    public static List<PicklistSiteopsController.Picklist> getPicklistOptions(
        String sObjectName,
        String recordTypeName,
        String fieldNames,
        String language,
        Boolean containsDependentPicklist
    ) {

        String picklistPageUrlParams = '?' + PicklistSiteopsController.SOBJECTTYPE_PARAM + '=' + sObjectName +
            '&' + PicklistSiteopsController.RECORDTYPENAME_PARAM + '=' + recordTypeName +
            '&' + PicklistSiteopsController.FIELDS_PARAM + '=' + fieldNames +
            '&' + PicklistSiteopsController.LANG_PARAM + '=' + language;

        List<PicklistSiteopsController.Picklist> picklists = new List<PicklistSiteopsController.Picklist>();

        try{
            PageReference pr = new PageReference('/apex/PicklistSiteops' + picklistPageUrlParams);

            String htmlContent = Test.isRunningTest() ?
                '' :
                pr.getContent().toString().unescapeHtml4();

            picklists = PicklistSiteopsController.parse(htmlContent, '<select ', '<option ', containsDependentPicklist);
        } catch(Exception e) {
            System.debug('SFDescribeHelper.getPicklistOptions exception: ' + e.getMessage());
        }

        return picklists;
    }

    public static List<Schema.PicklistEntry> getFilteredPicklist(List<String> filteredValues, List<Schema.PicklistEntry> picklistValues) {
        List<Schema.PicklistEntry> filteredPicklist = new List<Schema.PicklistEntry>();
        for (Schema.PicklistEntry val : picklistValues) {
            if (filteredValues.contains(val.getValue())) {
                filteredPicklist.add(val);
            }
        }
        return filteredPicklist;
    }

    public static List<TPicklistEntry> convertToTPicklistEntry(List<Schema.PicklistEntry> entries) {
        return (List<TPicklistEntry>)  JSON.deserialize(JSON.serialize(entries), List<TPicklistEntry>.class);
    }

    public static Schema.ChildRelationship getChildRelationship(Schema.DescribeSObjectResult sObjectDescribe, String relationName) {
        for (Schema.ChildRelationship accountChildRelation : sObjectDescribe.getChildRelationships()) {
            if (relationName == accountChildRelation.relationshipName) {
                return accountChildRelation;
            }
        }
        return null;
    }
}