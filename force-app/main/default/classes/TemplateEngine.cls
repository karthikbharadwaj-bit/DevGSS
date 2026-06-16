/*
Change History
********************************************************************************************************************
SCRUM/Jira  		ModifiedBy      Date           Description                                           Tag
                    Rajalakshmi.R   05-Jan-2020    Added changes for Parsing If in var assignments
					                               for CC Automation.
********************************************************************************************************************

*/
public class TemplateEngine {

    public static final String PDF_ENGINE_1_0 = 'PDF Engine 1.0';
    public static final String PDF_ENGINE_2_0 = 'PDF Engine 2.0';
    public static final String AIR_PACKAGE_NAME = 'RingCentral AIR';
    private static Map<String,String> objectIdPrefixToObjectName = new Map<String,String>();
    public static String TemplateName;
    /* :Variable to hold object prefix for if loops */
    public static String objPref;
    // Proceed Document using template
    public static String createDoc(String objId, String templateIdOrExtId) {

        // Get pdf template body
        Map <String, Map<String, String>> templateBody = getTemplateBody(templateIdOrExtId);

        // procced template and get prepared html
        TemplateHandler th = new TemplateHandler();
        String result = th.proceedTemplate(objId, templateBody.get('template').get('content'), templateBody.get('parameters'));

        return result;
    }

    // Proceed Document using String
    public static String createFromString(String objId, String templateBody) {
        return createFromString(objId, templateBody, new Map <String, String>());
    }
    public static String createFromString(String objId, String templateBody, Map<String, String> parameters) {

        TemplateHandler th = new TemplateHandler();
        String result = th.proceedTemplate(objId, templateBody, parameters);
        return result;
    }


    /*
     * Helper Functions
     * ---------------- */

    /**
     * Returns styled debug message string
     * @param ex
     *
     * @return
     */
    public static String outputDebug(Exception ex) {
        return outputDebug(ex, null);
    }
    /**
     * Returns styled debug message string
     * @param ex
     * @param failedItem
     *
     * @return
     */
    public static String outputDebug(Exception ex, String failedItem) {
        String placeholder = '<span class="system-error">{0}<span>';
        List<String> values = new List<String>{
            String.valueOf(ex)
        };
        if (String.isNotBlank(failedItem)) {
            values.add(0, failedItem);
            placeholder = '<span class="system-error">{0}<br>{1}<span>';
        }
        return String.format(placeholder, values);
    }


    /**
     *
     * @param fieldSet
     * @param itemsToAdd
     *
     * @return
     */
    public static Set<String> addToFieldSet(Set<String> fieldSet, Set<String> itemsToAdd) {
        return addToFieldSet(fieldSet, new List<String>(itemsToAdd));
    }
    /*Set Selected template Name*/
    public static void SetSelectedTemplate(String Name){
        TemplateEngine.TemplateName = Name;
        System.debug('$$templateEngine Name' + TemplateName);
    }
    /**
     *
     * @param fieldSet
     * @param itemsToAdd
     *
     * @return
     */
    public static Set<String> addToFieldSet(Set<String> fieldSet, List<String> itemsToAdd) {
        if (itemsToAdd != null) {
            for (String itemToAdd : itemsToAdd) {
                fieldSet = addToFieldSet(fieldSet, itemToAdd);
            }
        }
        return fieldSet;
    }

    /**
     *
     * @param fieldSet
     * @param itemToAdd
     *
     * @return
     */
    public static Set<String> addToFieldSet(Set<String> fieldSet, String itemToAdd) {
        if (String.isNotBlank(itemToAdd)) {
            itemToAdd = itemToAdd.trim().toLowerCase();
            fieldSet.add(itemToAdd);
        }
        return fieldSet;
    }
    /**
     *  Get pdf unprepared template content string
     *  @param templateId
     *  @return
     *      template.content html markup
     *      template.styles  css styles
     *      parameters       template parameters
     */
    public static Map <String, Map <String, String>> getTemplateBody(String templateIdOrExtId) {
        String templateBody = '';
        String templateStyles = '';
        Map <String, String> parameters = new Map<String, String>();
        System.debug('get Template body');
        List<TemplateSectionJunction__c> templSectJunctions = (new TemplateSectionJunctionSelector())
            .selectByTemplateIdOrExternalId(templateIdOrExtId)
            .selectFields(new List<String>{
                'RC_Quote_Template__r.CSS_Styles_1__c',
                'RC_Quote_Template__r.CSS_Styles_1__c',
                'RC_Quote_Template__r.Parameters__c',
                'RC_Quote_Template__r.External_ID__c',
                'RC_Quote_Template__r.Language__c',
                'RC_Quote_Template__r.Name',
                'Template_Section__r.Content_1__c',
                'Template_Section__r.Content_2__c',
                'Template_Section__r.Content_3__c',
                'Template_Section__r.Content_4__c',
                'Template_Section__r.Content_5__c',
                'Template_Section__r.CSS_Styles_1__c'
            })
            .withoutSelectorOrderByIncluded()
            .addOrdering(TemplateSectionJunction__c.Position__c, QueryFactory.SortOrder.ASCENDING)
            .addOrdering(TemplateSectionJunction__c.LastModifiedDate, QueryFactory.SortOrder.DESCENDING)
            .executeQuery();

        Map<Id, RC_Quote_Template__c> templates = new Map<Id, RC_Quote_Template__c>();
        for (TemplateSectionJunction__c templSectJunction : templSectJunctions) {
            if (!templates.containsKey(templSectJunction.RC_Quote_Template__c)) {
                templates.put(templSectJunction.RC_Quote_Template__c, templSectJunction.RC_Quote_Template__r);
            }
        }

        if (templates.size() > 0) {
            RC_Quote_Template__c template;
            if (templates.size() > 1) {
                // This is possible cause of 'OR' in WHERE clause. Use 'templates.Id == templateIdOrExtId' in this case.
                template = templates.get(templateIdOrExtId);
            } else {
                template = templates.values()[0];
            }
            TemplateName = template.Name;
            if (String.isNotBlank(template.Parameters__c)) {
                parameters = (Map<String, String>) JSON.deserialize(template.Parameters__c, Map<String, String>.class);
            }
            parameters.put('Language__c', StringHelper.safeString(template.Language__c));
            templateStyles += StringHelper.safeString(template.CSS_Styles_1__c);

            // Create Template Body String
            for (TemplateSectionJunction__c tsj : templSectJunctions) {
                // use sections from selected template only.
                if (tsj.RC_Quote_Template__c == template.Id) {
                    templateBody += StringHelper.safeString(tsj.Template_Section__r.Content_1__c);
                    templateBody += StringHelper.safeString(tsj.Template_Section__r.Content_2__c);
                    templateBody += StringHelper.safeString(tsj.Template_Section__r.Content_3__c);
                    templateBody += StringHelper.safeString(tsj.Template_Section__r.Content_4__c);
                    templateBody += StringHelper.safeString(tsj.Template_Section__r.Content_5__c);
                    templateStyles += StringHelper.safeString(tsj.Template_Section__r.CSS_Styles_1__c);
                }
            }

        }
        return new Map <String, Map <String, String>>{
            'template' => new Map <String, String>{
                'content' => templateBody,
                'styles' => templateStyles
            },
            'parameters' => parameters
        };
    }

    public static String getRefFromTo(String fromSObjectName, String toSObjectName) {

        SObjectDescribeHelper sfdh = SObjectDescribeHelper.getDescribe(fromSObjectName);
        Map<String, Schema.SObjectField> sobjDescr = sfdh.getFieldsMap();

        Map<String, String> resultMap = new Map<String, String>();
        for (String fName : sobjDescr.keySet()) {
            Schema.DescribeFieldResult dfr = sobjDescr.get(fName).getDescribe();
            if (!dfr.isNamePointing() && !dfr.getReferenceTo().isEmpty()) {
                String relationshipName = dfr.getRelationshipName();
                if (relationshipName.contains('__r')) {
                    relationshipName = relationshipName.replace('__r', '__c');
                } else if (relationshipName.containsNone('__c')) {
                    relationshipName += 'Id';
                }
                resultMap.put(dfr.getReferenceTo().get(0).getDescribe().getName(), relationshipName);
            }
        }

        return resultMap.get(toSObjectName);
    }

    /**
     *  Get Object Name by Id
     */
    public static String determinedObjectById(string objId) {
        if (objId == null) {
            return objId;
        }

        String thePrefix = objId.substring(0, 3);
        if (objectIdPrefixToObjectName.get(thePrefix) == null) {
            Id  realObjId = Id.valueOf(objId);
            String name = realObjId.getSObjectType().getDescribe().getName();
            objectIdPrefixToObjectName.put(thePrefix, name);
        }
        return objectIdPrefixToObjectName.get(thePrefix);
    }

    public class ChangeOrderItem {
        public QuoteLineItem quoteLineItem { get; set; }
        public Entitlement__c entitlement { get; set; }
    }
    /* Added if clause to data item to store if condition details in variable assignments($var) */
    public class ifClause{
        public String VariableName    { get; set; }
        public String ComparisonOp 	  { get; set; }
        public String ComparisonField { get; set; }
        public String ComparisonValue { get; set; }
        public String returnField     { get; set; }
    }
    public class DataItem {

        public String objectName      { get; set; }
        public String id              { get; set; }
        public Set<String> fields     { get; set; }
        public sObject data           { get; set; }
        public List<Object> dataList  { get; set; }
        public String whereFilter     { get; set; }
        public String apexFilter      { get; set; }
        public String orderBy         { get; set; }
        public String limitOption     { get; set; }
        public String linkField       { get; set; }
        public String query           { get; set; }
        public String type            { get; set; }
        public String parentKey       { get; set; }
        public String linkBy          { get; set; }
        public String brand           { get; set; }
        public Map<String,ifClause> ifClauses {get; set; }


        // multiple query type
        public Map<String, String> queries            { get; set; }
        public Map<String, Set<String>> fieldsSets    { get; set; }
        public Map<String, List<sObject>> dataListMap { get; set; }
        public Map<String, sObject> dataMap           { get; set; }
        public Map<String, String> whereFilterMap     { get; set; }

        public DataItem() {
            this.fields = new Set<String>{
                'id'
            };
            this.whereFilterMap = new Map<String, String>();
            this.dataListMap = new Map<String, List<sObject>>();
            this.dataMap = new Map<String, sObject>();
            this.ifClauses = new Map<String,ifClause>();
        }
    }

    public class LoopItem {
        public String loopRowTemplate { get; set; }
        public Integer loopRowStartAt { get; set; }
        public Integer loopBlockStartAt { get; set; }
        public Integer loopRowEndAt { get; set; }
        public Integer loopBlockEndAt { get; set; }
        public String loopAlias { get; set; }
        public Map<String, Integer> loopIndexMap { get; set; }

        public LoopItem() {
            this.loopRowTemplate = null;
            this.loopRowStartAt = null;
            this.loopBlockStartAt = null;
            this.loopRowEndAt = null;
            this.loopBlockEndAt = null;
            this.loopAlias = '';
            this.loopIndexMap = new Map<String, Integer>();
        }
    }

    public enum SmsFee {INBOUND, OUTBOUND}

    public static final String VARIABLE_KEYWORD = 'var';
    public static String LOOP_START_KEYWORD = 'for';
    public static String LOOP_END_KEYWORD = '/for';
    public static String LOOP_INIT_ALIAS_SEPARATOR = ':';
    public static String RESERVED_WORD_CHAR = '$';

    // #{! ... }#
    public static String BASE_PATTERN = '\\{!(?:\\s*)?(.+?)(\\|[^{}]+?)?(?:\\s*)?\\}';
    // #<! ... >#
    // !!! ATTENTION !!!
    // in ( [^>]+) group SPACE SYMBOL after the bracket is REQUIRED (for some yet unknown reason)
    public static String BASE_PATTERN_2 = '<!( [^>]+)>';
    // ... #foo# ... bar ...
    public static String WORD_PATTERN = '([^\\s:]+)';
    // #Opportunity#.Name#
    public static String DOT_NOTATION_PATTERN = '(\\w+)';
    // #qli#.#Quantity.Name#
    public static String PREFIX_DOT_NOTATION_PATTERN = '(\\$?\\w+)(?:\\.([\\$\\w.]+))?';
    // #Opportunity.AccountId#.#Entitlement__c#
    public static String POSTFIX_DOT_NOTATION_PATTERN = '(?:([\\$?\\w.]+)\\.)?(\\$?\\w+)';
    // #filtername#(#Arg#)
    public static String FILTER_PATTERN = '\\|(?:\\s*)(.+?)\\(([^\\|]*)\\)';
    // #'#AND Name = \'XXXX\' #'#
    public static String QUOTES_PATTERN = '(?<!\\\\)\'';
    // 'AND Name = #\'#XXXX#\'# '
    public static String ESCAPED_QUOTE_PATTERN = '\\\\\'';
    // "(XXX"X)"
    public static String ESCAPED_QUOTES_PATTERN = '(\\w+)(")(\\w+)';
    public static String EXTRA_SPACE_PATTERN = '(>)(\\s*)([^<>\\s]*)(\\s*)(<)';

    public static String BASE_OBJECT_KEYWORD = 'baseObj';
    public static String LOOP_OBJ_KEYWORD = 'loopObj';
    public static String COSTCENTER_OBJECT_KEYWORD = 'Cost_Center__c';

    public static String CHANGE_ORDER_QUOTELINEITEM_KEYWORD = 'QuoteLineItem';
    public static String CHANGE_ORDER_ENTITLEMENT_KEYWORD = 'Entitlement__c';
    public static String DEFAULT_OBJ_KEYWORD = 'Current_Object';

    public static String CHANGE_ORDER_ENTITLEMENT_NGBS_KEYWORD = 'Entitlement__c(NGBS)';
    public static String CHANGE_ORDER_ENTITLEMENT_OLD_BILLING_KEYWORD = 'Entitlement__c(OLD BILLING)';

    /**
     *  Query Types
     */
    public static String CUSTOM_QUERY_TYPE = 'customQuery';
    public static String NO_QUERY_TYPE = 'noQuery';
    public static String CHANGE_ORDER_TYPE = 'changeOrderType';
    public static String HIERARCHY_TABLE_TYPE = 'hierarchyTable';
    public static String HIERARCHY_TABLE_NEW = 'hierarchyTableNew';
    public static String HIERARCHY_TABLE_EXISTING = 'hierarchyTableExisting';
    public static String HIERARCHY_TABLE_EXISTING_AND_NEW = 'hierarchyTableExistingAndNew';
    public static String HIERARCHY_TABLE_CHANGE_ORDER = 'hierarchyTableChangeOrder';
    public static String SIGNATURE_TAG_TYPE = 'signatureTagType';
    public static String TAXES_AND_FEES_TABLE_TYPE = 'taxesAndFeesTableType';

    private static Map<String, Set<String>> FORMATTER_FIELDS_AS_CURRENCY = new Map<String, Set<String>>{
        BASE_OBJECT_KEYWORD => new Set<String>{ 'CurrencyIsoCode' },
        LOOP_OBJ_KEYWORD => new Set<String>{ 'CurrencyIsoCode' },
        CHANGE_ORDER_QUOTELINEITEM_KEYWORD => new Set<String>{ 'CurrencyIsoCode' },
        CHANGE_ORDER_ENTITLEMENT_KEYWORD => new Set<String>{ 'CurrencyIsoCode' },
        DEFAULT_OBJ_KEYWORD => new Set<String>{ 'CurrencyIsoCode' }
    };
    public static Map<String, Map<String, Set<String>>> formatterNameToQueriedFields =
        new Map<String, Map<String, Set<String>>>{
            'asCurrency' => FORMATTER_FIELDS_AS_CURRENCY,
            'asCurrencyOrPercentageString' => FORMATTER_FIELDS_AS_CURRENCY
        };

    private static List<PdfHierarchySettings__mdt> hierarchySettings = new List<PdfHierarchySettings__mdt>();
    private static Map<Id, Integer> qliIdToHierarchyLevel = new Map<Id, Integer>();
    private static Map<Id, Integer> qliIdToHierarchyLevelChangeOrder = new Map<Id, Integer>();
    private static Map<Id, Integer> entIdToHierarchyLevelChangeOrder = new Map<Id, Integer>();
    /**
     * Check if string contains virtual identifier
     *
     * @example
     * isVirtual('$virtualfieldName') // true
     * isVirtual('fieldName') // false
     *
     * @param str
     *
     * @return true || false
     */
    public static Boolean isVirtual(String str) {
        return String.isNotBlank(str) && str.substring(0, 1) == RESERVED_WORD_CHAR;
    }

    /**
     * Get string vithout virtual identifier
     *
     * @example
     * cleanVirtualString('$virtualfieldName') // virtualfieldName
     * cleanVirtualString('fieldName') // fieldName
     *
     * @param str
     *
     * @return
     */
    public static String cleanVirtualString(String str) {
        return isVirtual(str) ? str.substring(1, str.length()) : str;
    }

    /**
     * Debug mode
     * if true output errors in the template
     */
    public static Boolean IS_DEBUG_MODE = true;

    // Change Order default field sets
    public static Set<String> CHANGE_ORDER_QUOTELINEITEM_DEFAULT_KEYWORDS = new Set<String> {
        'id', 'entitlement__c', 'discount_number__c', 'discount_type__c', 'unitprice', 'ChargeTerm__c',
        'zero_quantity__c', 'quantity', 'effectivepricenew__c', 'entitlement__r.product__r.charge_term__c',
        'entitlement__r.chargeterm__c', 'ishiddenlicense__c', 'entitlement__r.packagecatalogid__c',
        'entitlement__r.packageversion__c', 'packagecatalogid__c', 'packageversion__c',
        'entitlement__r.price__c', 'entitlement__r.effectiveprice__c', 'product2.charge_term__c',
        'quoterecordtype__c', 'Product2.Family', 'Package_Info__c', 'PackageInfo__c', 'Package_Info_QLI__c', 'Discount', 'NewQuantity__c',
        'Product2.ExtID__c', 'Product2.Name', 'Product2.Dependent_on_Feature__c', 'Sort_Order__c', 'Product2.Feature__c', 'Quote.PackageNameNew__c'
    };

    public static Set<String> CHANGE_ORDER_ENTITLEMENT_DEFAULT_KEYWORDS = new Set<String> {
        'id','discount__c', 'discount_type__c', 'packagecatalogid__c', 'quote__r.Payment_Plan__c', 'ChargeTerm__c',
        'Product__r.Charge_Term__c', 'price__c', 'packageversion__c', 'quantity__c', 'Price__c', 'Quantity__c', 'EffectivePrice__c',
        'Product__r.ExtID__c', 'Sort_Order__c', 'Product__r.Name', 'Product__r.Dependent_on_Feature__c', 'Product__r.Family', 'Product__r.Feature__c', 'PartnerConfig__c',
        'Quote__r.PackageNameNew__c'
    };

    public class TemplateHandler {

        private Map<String, Object> variablesMap;
        public TemplateHandler () {
            this.variablesMap = new Map<String, Object>();
        }

        /**
         *  Helper methods
         */
        public Set<String> RESERVED_WORDS = new Set<String>{
            'today', 'Params', 'resource', 'baseUrl'
        };

        /**
         *  Sort Methods
         */
        public String PRODUCTS_STANDARD_SORT = 'PRODUCTS_STANDARD_SORT';
        public Set<String> SORT_METHOD_NAMES = new Set<String>{
            PRODUCTS_STANDARD_SORT
        };

        /**
         *  Custom where clause
         */
        public String CUSTOM_OVERAGES_FILTRATION = 'OVERAGE_CUSTOM_WHERE_CLAUSE';
        public Map<String,String> CUSTOM_WHERE_CLAUSE = new Map<String,String>{
            CUSTOM_OVERAGES_FILTRATION => 'isHiddenLicense__c != true AND ((Product2.Family = \'Overage\' AND (Last_Approved_Discount__c != null OR Discount_Number__c != null)) OR (Product2.Family != \'Overage\'))'
        };

        /**
         *  Fields required for apex filters
         */
        public String APEX_FILTER_OVERAGES_BY_DISCOUNT = 'OVERAGES_BY_DISCOUNT';
        public Set<String> APEX_FILTER_OVERAGES_BY_DISCOUNT_FIELDS = new Set<String>{
            'Discount_number__c',
            'Discount_type__c',
            'Entitlement__r.Discount__c',
            'Entitlement__r.Discount_Type__c',
            'Product2.ExtId__c',
            'Product2.Family',
            'Product2.Name',
            'Product2.Parent__c',
            'Product2.Product_Type__c',
            'UnitPrice'
        };

        public String APEX_FILTER_REMOVE_NOT_CHANGED_QLIS = 'REMOVE_NOT_CHANGED_QLIS';
        // this filter`s required fields should include required fields for virtual functions used in this filter
        public Set<String> APEX_FILTER_REMOVE_NOT_CHANGED_QLIS_FIELDS{
            get{
                if (APEX_FILTER_REMOVE_NOT_CHANGED_QLIS_FIELDS == null) {
                    // some temporary variable is required to avoid interactions between class loading
                    // (e.g. if VirtualField class will try to use APEX_FILTER_REMOVE_NOT_CHANGED_QLIS_FIELDS value)
                    Set<String> reqFields = new Set<String>{
                        'Discount_number__c',
                        'Discount_type__c',
                        'EffectivePrice__c',
                        'EffectivePriceNew__c',
                        'Last_Approved_Discount__c',
                        'Last_Approved_Discount_Type__c',
                        'Last_Approved_Quantity__c',
                        'NewQuantity__c',
                        'UnitPrice'
                    };
                    VirtualField vf = new VirtualField();
                    // this apex filter uses currentItemSubtotal virtual field
                    for (String qliField : vf.getRequiredFields('currentItemSubtotal', LOOP_OBJ_KEYWORD)) {
                        reqFields.add(qliField);
                    }
                    // this apex filter uses subtotalConsideringChargeTerm virtual field
                    for (String qliField : vf.getRequiredFields('subtotalConsideringChargeTerm', LOOP_OBJ_KEYWORD)) {
                        reqFields.add(qliField);
                    }
                    for (String quoteField : vf.getRequiredFields('subtotalConsideringChargeTerm', BASE_OBJECT_KEYWORD)) {
                        reqFields.add('Quote.' + quoteField);
                    }
                    APEX_FILTER_REMOVE_NOT_CHANGED_QLIS_FIELDS = reqFields;
                }
                return APEX_FILTER_REMOVE_NOT_CHANGED_QLIS_FIELDS;
            }
            private set;
        }

        /*
         * Child subquery map
         */

        public Map<String,String> CHILDOBJECT_SUBQUERY = new Map<String,String>{
            COSTCENTER_OBJECT_KEYWORD =>
                ', (SELECT Id, Quantity__c, Quote_Line_Item__r.Product2.Charge_Term__c, ' +
                    'Quote_Line_Item__r.Discount, ' +
                    'Quote_Line_Item__r.UnitPrice, Quote_Line_Item__r.NewQuantity__c, Quote_Line_Item__r.Package_Info_QLI__c,' +
                    'Quote_Line_Item__r.TotalPrice, Quote_Line_Item__r.PackageInfo__c, ' +
                    'Quote_Line_Item__r.Quote.RecordTypeId, Quote_Line_Item__r.QuoteRecordType__c ' +
                    'FROM Cost_Center_Products__r) '
        };


        public List<PdfPreservedItems__c> preservedItems = PdfPreservedItems__c.getAll().values();

        // Names of overages used in OVERAGES_BY_DISCOUNT filtration. These overages should always be kept.
        public Set<String> PRESERVE_OVERAGES {
            get{
                if (PRESERVE_OVERAGES == null) {
                    PRESERVE_OVERAGES = new Set<String>();
                    for (PdfPreservedItems__c preservedItem : preservedItems) {
                        if (preservedItem.Preserved_Overage__c) {
                            PRESERVE_OVERAGES.add(preservedItem.Product_Name__c);
                        }
                    }
                }
                return PRESERVE_OVERAGES;
            }
            private set;
        }

        //ExtID__c of Products which should be always shown in hierarchy tables despite other filters
        public Set<String> PRESERVE_PRODUCT_EXT_ID {
            get{
                if (PRESERVE_PRODUCT_EXT_ID == null) {
                    PRESERVE_PRODUCT_EXT_ID = new Set<String>();
                    for (PdfPreservedItems__c preservedItem : preservedItems) {
                        if (preservedItem.Preserved_In_Hierarchy_Tables__c) {
                            PRESERVE_PRODUCT_EXT_ID.add(preservedItem.Product_External_Id__c);
                        }
                    }
                }
                return PRESERVE_PRODUCT_EXT_ID;
            }
            private set;
        }

        public final Set<String> INBOUND_FEE_TYPES = new Set<String>{
            Product2Helper.PRODUCT_TYPE_INCOMING_SMS,
            Product2Helper.PRODUCT_TYPE_SMS_TF_LONG_RATE,
            Product2Helper.PRODUCT_TYPE_OUTGOING_SMS
        };
        public final Set<String> OUTBOUND_FEE_TYPES = new Set<String>{
            Product2Helper.PRODUCT_TYPE_INCOMING_SMS,
            Product2Helper.PRODUCT_TYPE_SMS_TF_LONG_RATE,
            Product2Helper.PRODUCT_TYPE_OUTGOING_SMS_RATE
        };

        /**
         * procced template and get prepared html
         */
        public String proceedTemplate(String objId, String templateBody, Map<String, String> parameters) {
            String result = '';

            // Detect what records needs to be retrieved
            Map<String, DataItem> dataToGet = scanTemplate(objId, templateBody);

            // Retrieve records
            Map<String, DataItem> retrievedData = getData(dataToGet);

            // Preprocess data
            Map<String, DataItem> preprocessedData = preprocessData(retrievedData);
            // Replace placeholders with actual data
            result = replacePlaceholders(templateBody, preprocessedData, null, parameters, null).normalizeSpace().replaceAll(EXTRA_SPACE_PATTERN, '$1$3$5');
            return result;
        }

        /**
         * Scans Template and fulfill DataItem with required fields for each sobject
         * @param objId        Base Object Id
         * @param templateBody raw template string
         *
         * @return DataItems with info about required fields/queries/objectNames to retrieve
         */
        public Map<String, DataItem> scanTemplate(String objId, String templateBody) {
            TemplateEngine.VirtualField vf = new TemplateEngine.VirtualField();
            TemplateEngine.ChangeOrderVirtualField covf = new TemplateEngine.ChangeOrderVirtualField();

            Map<String, DataItem> data = new Map<String, DataItem>();
            DataItem baseObj = new DataItem();
            data.put(BASE_OBJECT_KEYWORD, baseObj);
            baseObj.id = objId;
            baseObj.objectName = determinedObjectById(objId);

            Matcher baseMatcher = Pattern.compile(BASE_PATTERN).matcher(templateBody);

            Boolean isLoopInit = false;
            Boolean isLoopBody = false;

            // #{! ... }#
            while (baseMatcher.find()) {
                String valuePart = baseMatcher.group(1);
                String filtersPart = baseMatcher.group(2);
                Integer loopInitVarIndex = null;
                String loopInitName = null;
                Boolean isPotentiallyVariableInitStep = true;

                Matcher wordMatcher = Pattern.compile(WORD_PATTERN).matcher(valuePart);
                // {! ... #foo# ... bar ... }
                while (wordMatcher.find()) {
                    String word = wordMatcher.group(1);
                    // if first word in {! ... } construction is 'var' - this is a variable initialization
                    if (isPotentiallyVariableInitStep) {
                        if (word == VARIABLE_KEYWORD) {
                            // finds variable name
                            wordMatcher.find();
                            String VariableName = wordMatcher.group(1);
                            // finds variable value string
                            wordMatcher.find();
                            String VariableValue = valuePart.substringAfter('=');
                            // we will need to enrich data items with fields mentioned in value string
                            String variableValuePartString = wordMatcher.group(1);
                            // direct assignment doesn't require any fields (e.g. {! var varName = 0.00 })
                            if (variableValuePartString != '=') {
                                enrichDataItemsWithFields(data, variableValuePartString, filtersPart,null);

                            }
                            //adding to data items for var assignments involving fields and conditions
                            if(variableValuePartString == '='){
                                List<String> VariableDetails = new List<String>();
                                VariableDetails.add(VariableName);
                                VariableDetails.add(VariableValue);
                                enrichDataItemsWithFields(data, variableValuePartString, filtersPart,VariableDetails);
                            }
                            break;
                        }
                        isPotentiallyVariableInitStep = false;
                    }

                    //
                    // Loop Logic
                    // ----------

                    //{! #/for# }
                    if (word == LOOP_END_KEYWORD) {
                        isLoopBody = false;
                        break;
                    }

                    //{!#for# qli : QuoteLineItem | filter }
                    if (word == LOOP_START_KEYWORD) {
                        isLoopInit = true;
                        loopInitVarIndex = 0;
                        continue;
                    }

                    if (isLoopInit || isLoopBody) {

                        DataItem loopData = null;

                        if (isLoopInit) {
                            loopInitVarIndex++;
                            //{!for #qli# : QuoteLineItem | filter }
                            if (loopInitVarIndex == 1) {
                                loopInitName = word;
                                if (!data.containsKey(loopInitName)) {
                                    data.put(loopInitName, new DataItem());
                                }
                                continue;
                            }
                            objPref =  loopInitName.equals('qli')?loopInitName:'';
                            loopData = data.get(loopInitName);
                            if (String.isNotBlank(filtersPart)) {
                                Matcher filterMatcher = Pattern.compile(FILTER_PATTERN).matcher(filtersPart);
                                while (filterMatcher.find()) {
                                    String filterName = filterMatcher.group(1);
                                    String filterArg = filterMatcher.group(2);

                                    if ('where'.equalsIgnoreCase(filterName)) {
                                        loopData.whereFilter = (String) parseArgs(filterArg).get(0);
                                    }
                                    if ('apexFilter'.equalsIgnoreCase(filterName)) {
                                        loopData.apexFilter = (String) parseArgs(filterArg).get(0);
                                        addToFieldSet(loopData.fields, getApexFilterRequiredFields(loopData.apexFilter));
                                    }

                                    if ('linkBy'.equalsIgnoreCase(filterName)) {
                                        loopData.linkBy = (String) parseArgs(filterArg).get(0);
                                    }

                                    if ('orderBy'.equalsIgnoreCase(filterName)) {
                                        loopData.orderBy = (String) parseArgs(filterArg).get(0);
                                    }

                                    if ('limit'.equalsIgnoreCase(filterName)) {
                                        loopData.limitOption = (String) parseArgs(filterArg).get(0);
                                    }

                                    if ('whereQli'.equalsIgnoreCase(filterName)) {
                                        String whereVal = (String) parseArgs(filterArg).get(0);
                                        loopData.whereFilterMap.put(CHANGE_ORDER_QUOTELINEITEM_KEYWORD, whereVal);
                                    }

                                    if ('whereEnt'.equalsIgnoreCase(filterName)) {
                                        String whereVal = (String) parseArgs(filterArg).get(0);
                                        loopData.whereFilterMap.put(CHANGE_ORDER_ENTITLEMENT_KEYWORD, whereVal);
                                    }
                                }
                            }

                            //{!for qli : #QuoteLineItem# | where('Feature != 7')}
                            if (loopInitVarIndex == 2) {
                                // #Opportunity.AccountId#.#Entitlement__c#
                                Matcher prefixDotNotationMatcher = Pattern.compile(POSTFIX_DOT_NOTATION_PATTERN).matcher(word);
                                String baseObjLinkField = null;
                                String loopObjectName = null;
                                while (prefixDotNotationMatcher.find()) {
                                    baseObjLinkField = prefixDotNotationMatcher.group(1);
                                    loopObjectName = prefixDotNotationMatcher.group(2);
                                }


                                if (isVirtual(loopObjectName)) {
                                    String cleanLoopObjectName = cleanVirtualString(loopObjectName);
                                    DataItem vObjInfo = vf.getVirtualObjectInfo(cleanLoopObjectName, data);
                                    loopData.type = vObjInfo.type;
                                    loopData.query = vObjInfo.query;
                                    loopData.queries = vObjInfo.queries;
                                    loopData.fieldsSets = vObjInfo.fieldsSets;
                                    loopData.whereFilterMap.putAll(vObjInfo.whereFilterMap);
                                    baseObj.fields = addToFieldSet(baseObj.fields, vf.getRequiredFields(cleanLoopObjectName, BASE_OBJECT_KEYWORD));

                                } else {
                                    loopData.objectName = loopObjectName;
                                    loopData.linkField = baseObjLinkField;

                                }

                                if (data.keySet().contains(baseObjLinkField)) {
                                    // if we detect that variable(baseObjLinkField) contains in data.keySet()(it is mean that variable from parent loop)
                                    // clear loopData.linkField and save that variable in loopData.parentKey

                                    loopData.linkField = null;
                                    loopData.parentKey = baseObjLinkField;
                                }

                                if (String.isNotBlank(loopData.linkField)) {
                                    addToFieldSet(baseObj.fields, loopData.linkField);
                                }

                                continue;
                            }
                        }
                    }
                    enrichDataItemsWithFields(data, word, filtersPart,null);
                }

                if (isLoopInit) {
                    isLoopInit = false;
                    isLoopBody = true;
                }


                // If filter condition mentions field - enrich Data Items with this field
                if (String.isNotBlank(filtersPart)) {
                    Matcher baseMatcher2 = Pattern.compile(BASE_PATTERN_2).matcher(filtersPart);
                    Set<String> escapedFieldsInFilter = new Set<String>();
                    while (baseMatcher2.find()) {
                        escapedFieldsInFilter.add(baseMatcher2.group(1));
                    }
                    for (String escapedFieldInFilter : escapedFieldsInFilter) {
                        enrichDataItemsWithFields(data, escapedFieldInFilter, '',null);
                    }
                }
            }

            data.put(BASE_OBJECT_KEYWORD, baseObj);
            return data;
        }

        private DataItem addFieldsRequiredForFilterMethods(
            DataItem sourceDataItem,
            String templateStr,
            String itemTypeKeyword
        ) {
            if (String.isBlank(templateStr) || String.isBlank(itemTypeKeyword)) {
                return sourceDataItem;
            }

            Matcher baseMatcher2 = Pattern.compile(FILTER_PATTERN).matcher(templateStr);

            while (baseMatcher2.find()) {
                for (String methodName : formatterNameToQueriedFields.keySet()) {
                    if (baseMatcher2.group(1).equalsIgnoreCase(methodName)) {

                        if (sourceDataItem.type == CHANGE_ORDER_TYPE
                            || sourceDataItem.type == HIERARCHY_TABLE_NEW
                            || sourceDataItem.type == HIERARCHY_TABLE_EXISTING
                            || sourceDataItem.type == HIERARCHY_TABLE_EXISTING_AND_NEW
                            || sourceDataItem.type == HIERARCHY_TABLE_CHANGE_ORDER) {
                            addToFieldSet(
                                sourceDataItem.fieldsSets.get(itemTypeKeyword),
                                formatterNameToQueriedFields.get(methodName).get(itemTypeKeyword)
                            );
                        } else {
                            addToFieldSet(
                                sourceDataItem.fields,
                                formatterNameToQueriedFields.get(methodName).get(itemTypeKeyword)
                            );
                        }
                    }
                }
            }

            return sourceDataItem;
        }

        // Map "apexFilterName -> requredFieldsSet" is not used, to support lazy initialisation
        // and avoid potential 'Maximum stack depth reached' exception during load of TemplateHandler class.
        public Set<String> getApexFilterRequiredFields(String apexFilterName) {
            if (apexFilterName == APEX_FILTER_OVERAGES_BY_DISCOUNT) {
                return APEX_FILTER_OVERAGES_BY_DISCOUNT_FIELDS;

            } else if (apexFilterName == APEX_FILTER_REMOVE_NOT_CHANGED_QLIS) {
                return APEX_FILTER_REMOVE_NOT_CHANGED_QLIS_FIELDS;

            } else {
                return new Set<String>();
            }
        }

        // Enrich Data Items with fields
        // Here we need to understand what type of syntax we deal with and prepare field names and queries
        // we will need to select(soql) from Salesforce
        // Added VariableDetails Parameter to add ifClause details to data item
        private void enrichDataItemsWithFields(Map<String, DataItem> data, String word, String filtersPart,List<String> VariableDetails) {
            TemplateEngine.VirtualField vf = new TemplateEngine.VirtualField();
            TemplateEngine.ChangeOrderVirtualField covf = new TemplateEngine.ChangeOrderVirtualField();
            DataItem baseObj = data.get(BASE_OBJECT_KEYWORD);
            baseObj.brand = getBrand(baseObj);

            Matcher prefixDotNotationMatcher = Pattern.compile(PREFIX_DOT_NOTATION_PATTERN).matcher(word);
            while (prefixDotNotationMatcher.find()) {
                // #qli#.#Quantity.Name#
                String prefix = prefixDotNotationMatcher.group(1);
                String field = StringHelper.safeString(prefixDotNotationMatcher.group(2));

                String cleanPrefix = cleanVirtualString(prefix);
                String cleanField = cleanVirtualString(field);

                if (prefix == RESERVED_WORD_CHAR + VARIABLE_KEYWORD) {
                    // if this is a variable (it has prefix $var) - we could not determine what object currently stored in it
                    // and therefore we unable to add any relevant info about required fields to DataItems (i.e. - Map<String, DataItem> data).
                    continue;
                }

                if (isVirtual(prefix)) {
                    // It is virtual Object or Helper function
                    // $virtualObject
                    // $virtualObject.FieldName__c
                    // NOTE: $VirtualObject.$virtualField constructions are not supported!
                    if (!data.containsKey(cleanPrefix)) {
                        data.put(cleanPrefix, vf.getVirtualObjectInfo(cleanPrefix, data));
                        DataItem dataItem = data.get(cleanPrefix);

                        dataItem.fields = addToFieldSet(dataItem.fields, vf.getRequiredFields(cleanPrefix, LOOP_OBJ_KEYWORD));
                        addFieldsRequiredForFilterMethods(dataItem, filtersPart, LOOP_OBJ_KEYWORD);

                        baseObj.fields = addToFieldSet(baseObj.fields, vf.getRequiredFields(cleanPrefix, BASE_OBJECT_KEYWORD));
                        addFieldsRequiredForFilterMethods(baseObj, filtersPart, BASE_OBJECT_KEYWORD);
                    }

                    DataItem dataItem = data.get(cleanPrefix);

                    if (dataItem.type != NO_QUERY_TYPE && !isVirtual(field)) {
                        dataItem.fields = addToFieldSet(dataItem.fields, cleanField);
                        addFieldsRequiredForFilterMethods(dataItem, filtersPart, DEFAULT_OBJ_KEYWORD);
                    }

                } else if (isVirtual(field)) {
                    // it is loop virtual field.
                    // This might be loop row virtual field if placed inside loop body or summary field
                    // if placed before or after loop declaration
                    // qli.$virtualfield

                    // field is before loop declaration, lets create DataItem for it and hope that loop will be
                    // initialized later.
                    if (!data.containsKey(cleanPrefix)) {
                        data.put(cleanPrefix, new DataItem());
                    }

                    DataItem dataItem = data.get(cleanPrefix);

                    if (dataItem.type == CHANGE_ORDER_TYPE
                        || dataItem.type == HIERARCHY_TABLE_NEW
                        || dataItem.type == HIERARCHY_TABLE_EXISTING
                        || dataItem.type == HIERARCHY_TABLE_EXISTING_AND_NEW
                        || dataItem.type == HIERARCHY_TABLE_CHANGE_ORDER){
                        covf.enrichChangeOrderRequiredFields(dataItem.fieldsSets, cleanField);
                        addFieldsRequiredForFilterMethods(dataItem, filtersPart, CHANGE_ORDER_QUOTELINEITEM_KEYWORD);
                        addFieldsRequiredForFilterMethods(dataItem, filtersPart, CHANGE_ORDER_ENTITLEMENT_KEYWORD);

                    } else {
                        dataItem.fields = addToFieldSet(dataItem.fields, vf.getRequiredFields(cleanField, LOOP_OBJ_KEYWORD));
                        addFieldsRequiredForFilterMethods(dataItem, filtersPart, LOOP_OBJ_KEYWORD);

                        baseObj.fields = addToFieldSet(baseObj.fields, vf.getRequiredFields(cleanField, BASE_OBJECT_KEYWORD));
                        addFieldsRequiredForFilterMethods(baseObj, filtersPart, BASE_OBJECT_KEYWORD);
                    }

                } else if (data.containsKey(cleanPrefix)) {
                    // it is Simple field from loop
                    // qli.FieldName__c

                    DataItem dataItem = data.get(cleanPrefix);

                    if (dataItem.type == CHANGE_ORDER_TYPE
                        || dataItem.type == HIERARCHY_TABLE_NEW
                        || dataItem.type == HIERARCHY_TABLE_EXISTING
                        || dataItem.type == HIERARCHY_TABLE_EXISTING_AND_NEW
                        || dataItem.type == HIERARCHY_TABLE_CHANGE_ORDER) {

                        covf.enrichChangeOrderRequiredFields(dataItem.fieldsSets, cleanField);
                        addFieldsRequiredForFilterMethods(dataItem, filtersPart, CHANGE_ORDER_QUOTELINEITEM_KEYWORD);
                        addFieldsRequiredForFilterMethods(dataItem, filtersPart, CHANGE_ORDER_ENTITLEMENT_KEYWORD);
                    } else {
                        dataItem.fields = addToFieldSet(dataItem.fields, field);
                        addFieldsRequiredForFilterMethods(dataItem, filtersPart, DEFAULT_OBJ_KEYWORD);
                    }
                } else {
                    // It is simple field from base object
                    // Lookup__r.FieldName__c

                    baseObj.fields = addToFieldSet(baseObj.fields, word);
                    addFieldsRequiredForFilterMethods(baseObj, filtersPart, DEFAULT_OBJ_KEYWORD);
                }
            }
            //if variableValue param != null it means variable assignment has if conditions
            if(VariableDetails != null && filtersPart != null){
                String objPrefix = VariableDetails[1].substringBefore('.');
                if(data != null && data.get(objPref) != null){
                    String compareFieldName = VariableDetails[1];
                    String[] args = String.valueOf(filtersPart).SubString(String.valueof(filtersPart).IndexOf('i') + 3,String.valueof(filtersPart).Length() - 1).split(',');
                    String rtnFldName = args[2];
                    if(objPrefix.trim().equals('qli')){
                        Map<String,Schema.SObjectField> mfields = ((SObject)Type.forName('QuoteLineItem').newInstance()).getSObjectType().getDescribe().fields.getMap();
                        SObjectField cmp_Field = mfields.get(compareFieldName);
                        SObjectField rtn_field = mfields.get(rtnFldName);

                        IfClause ifcl = new IfClause();
                        ifcl.VariableName = VariableDetails[0];
                        ifcl.ComparisonOp = word;
                        ifcl.ComparisonField = compareFieldName.substringAfter('.');
                        ifcl.ComparisonValue = args[1];
                        ifcl.returnField = rtnFldName.substringAfter('.');
                        data.get(objPref).ifClauses.put(VariableDetails[0],ifcl);
                        data.get(objPref).fields.add(compareFieldName.substringAfter('.'));
                        data.get(objPref).fields.add(rtnFldName.substringAfter('.'));
                        data.get(objPref).fields.add('CurrencyIsoCode');
                    }

                }
            }
        }

        private String getBrand(DataItem baseObj) {
            String brand = baseObj.brand;

            if (determinedObjectById(baseObj.Id) == 'Quote'
                && String.isEmpty(baseObj.brand)) {
                brand = ((List<Quote>) new QuoteSelector()
                    .selectQuoteById(new List<Object>{baseObj.Id})
                    .selectFields(new List<String> {'Brand__c'})
                    .executeQuery())
                    .get(0)
                    .Brand__c;
            }

            return brand;
        }

        private List<Approval__c> getLastApprovedWholesaleApproval(String accountId){
            return new ApprovalSelector()
                .selectApprovalsForPartnerOperations(
                    new List<Object>{
                        new Set<Id>{
                            ApprovalHelper.RT_ID_INVOICE_WHOLESALE_REQUEST
                        },
                        new Set<Id>{ accountId },
                        new List<String>{ ApprovalHelper.STATUS_APPROVED }
                    },
                    new List<String>{
                        'PartnerAccountPayableContact__c'
                    }
                )
                .executeQuery();
        }

        /**
         *  Do Soql queries to retrieve all required objects
         */
        public Map<String, DataItem> getData(Map<String, DataItem> data) {
            DataItem baseObj = data.get(BASE_OBJECT_KEYWORD);
            String baseObjName = baseObj.objectName;
            if (Quote.class.getName().equalsIgnoreCase(baseObjName)) {
                baseObj.fields = addToFieldSet(baseObj.fields, new Set<String>{
                    'accountid', 'opportunityid'//, 'Account.Billing_Id__c'
                });
            }
            String baseObjFields = String.join(new List<String>(baseObj.fields), ', ');
            String baseObjId = baseObj.id;
            String baseObjQuery = 'SELECT ' + baseObjFields + ' FROM ' + baseObjName + ' WHERE Id = :baseObjId';

            baseObj.data = Database.query(baseObjQuery);

            // Declare variables for use by custom queries
            // @see TemplateEngine.VirtualField.getVirtualObjectInfo()
            String opportunityId = '';
            String accountId = '';
            if (Quote.class.getName().equalsIgnoreCase(baseObjName)) {
                opportunityId = StringHelper.safeString(SFDescribeHelper.getSObjectField(baseObj.data, 'OpportunityId'));
                accountId = StringHelper.safeString(SFDescribeHelper.getSObjectField(baseObj.data, 'AccountId'));
            }


            for (String key : data.keySet()) {
                if (key != BASE_OBJECT_KEYWORD) {
                    DataItem d = data.get(key);
                    String query = '';
                    if (d.type == NO_QUERY_TYPE) {
                        continue;

                    } else if (d.type == CUSTOM_QUERY_TYPE || d.type == HIERARCHY_TABLE_TYPE) {
                        // Virtual Objects queries

                        query = d.query;
                        String objFields = String.join(new List<String>(d.fields), ', ');
                        query = query.replace('{!fields}', objFields);

                        if (d.type == HIERARCHY_TABLE_TYPE && String.isNotBlank(d.whereFilter)) {
                            query += 'AND ' + d.whereFilter;
                        }

                        if (d.type == CUSTOM_QUERY_TYPE && d.query.contains('partnerAPCId')) {
                            String partnerAPCId = '';
                            List<Approval__c> lastApprovedWholesaleApprovals = getLastApprovedWholesaleApproval(accountId);
                            if(!lastApprovedWholesaleApprovals.isEmpty()){
                                partnerAPCId = lastApprovedWholesaleApprovals[0].PartnerAccountPayableContact__c;
                            }
                            query = query.replace('partnerAPCId', partnerAPCId);
                        }

                        if (d.type == CUSTOM_QUERY_TYPE && d.query.contains('latestApprovedApprovalId')) {
                            String latestApprovedApprovalId = '';
                            List<Approval__c> accountKYCApprovals = (List<Approval__c>) new ApprovalSelector()
                                .selectKYCRequestApprovalsForAccount(new List<Object>{new Set<Id>{accountId}})
                                .setLimit(1)
                                .executeQuery();
                            Approval__c latestKYCApproval = !accountKYCApprovals.isEmpty()
                                ? accountKYCApprovals[0]
                                : null;
                            if (latestKYCApproval?.Status__c == ApprovalHelper.STATUS_APPROVED
                                || latestKYCApproval?.Status__c == ApprovalHelper.STATUS_PENDING
                                ) {
                                latestApprovedApprovalId = latestKYCApproval.Id;
                            }
                            query = query.replace('latestApprovedApprovalId', latestApprovedApprovalId);
                        }

                        if (d.type == CUSTOM_QUERY_TYPE && d.query.contains('masterQuoteId')) {
                            query = query.replace('masterQuoteId', baseObjId);
                        }

                        List<SObject> oneCustomObject = Database.query(query);
                        if (oneCustomObject.size() > 0) {
                            d.data = oneCustomObject[0];
                        }
                        d.dataList = oneCustomObject;
                    } else if (d.type == SIGNATURE_TAG_TYPE) {
                        query = d.query;

                        Opportunity opp = (Opportunity) new OpportunitySelector().selectOpportunitiesByIds(new Set<Id>{opportunityId}).executeQuery()[0];
                        Map<List<String>, Signature_Tags__mdt> segmentToSignatureTags = new Map<List<String>, Signature_Tags__mdt>();
                        Signature_Tags__mdt signatureTag = new Signature_Tags__mdt(
                            Signature__c = '',
                            StaticResourceName__c = '',
                            Title__c = ''
                        );

                        List<Signature_Tags__mdt> signatureTags = Database.query(query);
                        String opportunityBi = OpportunityHelper.getOpportunityBi(opp.BusinessIdentity__c);
                        if (signatureTags.size() > 0 && opp != null) {
                            for (Signature_Tags__mdt st : signatureTags) {
                                Boolean isRegionAndSubRegionContains = !String.isBlank(st.Region__c)
                                    && !String.isBlank(st.SubRegion__c)
                                    && !String.isBlank(opp.Owner.Region__c)
                                    && !String.isBlank(opp.Owner.Sub_Region__c)
                                    && st.Region__c.contains(opp.Owner.Region__c)
                                    && st.SubRegion__c.contains(opp.Owner.Sub_Region__c);
                                if (!String.isBlank(st.BusinessIdentity__c) && st.BusinessIdentity__c.split(';').contains(opportunityBi)) {
                                    if (String.isBlank(st.Segment__c)) {
                                        signatureTag = st;
                                    } else {
                                        if(st.Segment__c.split(';').contains(opp.Owner.SegmentPicklist__c)) {
                                            signatureTag = st;
                                            break;
                                        }
                                    }
                                } else if (isRegionAndSubRegionContains) {
                                    signatureTag = st;
                                }
                            }
                        }
                        d.data = signatureTag;
                    } else if (d.type == TAXES_AND_FEES_TABLE_TYPE) { // Taxes and Fees Table
                        List<QuoteLineItem> taxesAndFeesTable = new List<QuoteLineItem>();
                        query = d.query;

                        String objFields = String.join(new List<String>(d.fields), ', ');
                        query = query.replace('{!fields}', objFields);

                        if (String.isNotBlank(d.whereFilter)) {
                            query += 'AND ' + d.whereFilter;
                        }

                        List<QuoteLIneItem> qliList = Database.query(query);

                        if (qliList.size() > 0) {
                            taxesAndFeesTable = QuoteLineItemHelper.getTaxesAndFeesTable(qliList);
                        }

                        if (taxesAndFeesTable.size() > 0) {
                            d.data = taxesAndFeesTable[0];
                        }
                        d.dataList = taxesAndFeesTable;

                    } else if (d.type == CHANGE_ORDER_TYPE
                        || d.type == HIERARCHY_TABLE_NEW
                        || d.type == HIERARCHY_TABLE_EXISTING
                        || d.type == HIERARCHY_TABLE_EXISTING_AND_NEW
                        || d.type == HIERARCHY_TABLE_CHANGE_ORDER) {

                        Boolean isCustomSort = SORT_METHOD_NAMES.contains(d.orderBy);

                        for (String coKey : d.queries.keySet()) {
                            Quote qt = (Quote) baseObj.data;
                            Boolean isEntitlement = coKey == CHANGE_ORDER_ENTITLEMENT_KEYWORD;
                            Boolean isNGBS = qt.Opportunity.Is_Billing_Opportunity__c &&
                                QuoteHelper.isNewBillingQuote(qt);
                            String coQuery = d.queries.get(coKey);
                            if (isEntitlement) {
                                coQuery += isNGBS ?
                                    d.whereFilterMap.get(CHANGE_ORDER_ENTITLEMENT_NGBS_KEYWORD) :
                                    d.whereFilterMap.get(CHANGE_ORDER_ENTITLEMENT_OLD_BILLING_KEYWORD);
                            }

                            List<SObject> loopObjects = new List<SObject>();

                            // Prepare fields to query
                            if (isCustomSort) {
                                if (d.orderBy == PRODUCTS_STANDARD_SORT) {
                                    d.fields = addToFieldSet(d.fieldsSets.get(coKey), PRODUCTS_STANDARD_SORT_FIELDS.get(coKey));
                                }
                            }

                            String objFields = String.join(new List<String>(d.fieldsSets.get(coKey)), ', ');
                            coQuery = coQuery.replace('{!fields}', objFields);

                            // Add Where Clause
                            String whereFilter = d.whereFilterMap.get(coKey);
                            if (String.isNotBlank(whereFilter)) {
                                coQuery += ' AND (' + whereFilter + ')';
                            }

                            // Perform query
                            loopObjects = Database.query(coQuery);

                            if (loopObjects.size() > 0) {
                                d.dataMap.put(coKey, loopObjects[0]);
                            }
                            d.dataListMap.put(coKey, loopObjects);
                        }

                    } else {
                        // For Loops Queries

                        String objName = d.objectName;
                        Boolean isCustomSort = SORT_METHOD_NAMES.contains(d.orderBy);
                        // Prepare fields to query
                        if (isCustomSort) {
                            if (d.orderBy == PRODUCTS_STANDARD_SORT) {
                                d.fields = addToFieldSet(d.fields, PRODUCTS_STANDARD_SORT_FIELDS.get(objName));
                            }
                        }
                        String objFields = String.join(new List<String>(d.fields), ', ');


                        String linkBy = '';

                        if (String.isNotBlank(d.linkBy)) {
                            // Get Value of relationship field
                            String linkFieldValue = baseObj.Id;
                            if (String.isNotBlank(d.linkField)) {
                                linkFieldValue = StringHelper.safeString(SFDescribeHelper.getSObjectField(baseObj.data, d.linkField));
                            }

                            linkBy = d.linkBy + ' = \'' + linkFieldValue + '\'';

                        } else if (String.isBlank(d.parentKey)) {
                            // Get Value of relationship field
                            String linkFieldValue = baseObj.Id;
                            if (String.isNotBlank(d.linkField)) {
                                linkFieldValue = StringHelper.safeString(SFDescribeHelper.getSObjectField(baseObj.data, d.linkField));
                            }

                            // Get relationship field Object Name
                            String linkFieldObjectName = determinedObjectById(linkFieldValue);

                            // Get child relationship field Name
                            String relationshipFeild = null;
                            SObjectDescribeHelper sfdh = SObjectDescribeHelper.getDescribe(linkFieldObjectName);
                            Schema.DescribeSObjectResult sobjDescr = sfdh.getDescribe();

                            for (Schema.ChildRelationship child : sobjDescr.getChildRelationships()) {
                                if (child.getChildSObject().getDescribe().getName() == objName && child.getRelationshipName() != null) {
                                    relationshipFeild = String.valueOf(child.getField());
                                    break;
                                }
                            }

                            linkBy = relationshipFeild + ' = \'' + linkFieldValue + '\'';
                        } else {

                            String relationshipField = getRefFromTo(objName, data.get(d.parentKey).objectName);
                            String idList = '';
                            // get IdList from ParentObj
                            if (!data.get(d.parentKey).dataList.isEmpty()) {
                                List<String> ids = new List<String>();
                                for (SObject parentObj : (List<sObject>) data.get(d.parentKey).dataList) {
                                    String idVal = (String) parentObj.get('Id');
                                    ids.add('\'' + idVal + '\'');
                                }
                                idList += String.join(ids, ', ');
                            } else if (data.get(d.parentKey).data != null) {
                                idList += '\'' + data.get(d.parentKey).data.get('Id') + '\'' ;
                            } else {
                                continue;
                            }

                            linkBy = relationshipField + ' IN ' + '(' + idList + ')';

                            // add relationshipField to fields list
                            d.fields.add(relationshipField);
                            objFields += ', ' + relationshipField;
                        }

                        // Add Where Clause
                        String w = '';
                        if (String.isNotBlank(d.whereFilter)) {
                            String customWhereClause = CUSTOM_WHERE_CLAUSE.get(d.whereFilter);
                            w = customWhereClause != null
                                ? ' AND (' + customWhereClause + ')'
                                : ' AND (' + d.whereFilter + ')';
                        }

                        // Add fields dependent on where clause statement
                        if (d.whereFilter == CUSTOM_OVERAGES_FILTRATION) {
                            if (!objFields.contains('product2.family')) {
                                objFields += ' ,product2.family';
                            }
                            if (!objFields.contains('last_approved_discount__c')) {
                                objFields += ' ,last_approved_discount__c';
                            }
                            if (!objFields.contains('discount_number__c')) {
                                objFields += ' ,discount_number__c';
                            }
                        }

                        String orderBy = '';
                        if (String.isNotBlank(d.orderBy) && !isCustomSort) {
                            orderBy = ' ORDER BY ' + d.orderBy;
                        }

                        String limitOption = '';
                        if (String.isNotBlank(d.limitOption) && !isCustomSort) {
                            limitOption = ' LIMIT ' + d.limitOption;
                        }

                        String childObjectSubQuery = CHILDOBJECT_SUBQUERY.get(objName) != null
                            ? CHILDOBJECT_SUBQUERY.get(objName)
                            : '';

                        query = 'SELECT ' + objFields + childObjectSubQuery + ' FROM ' + objName + ' WHERE ' + linkBy + w + orderBy + limitOption;
                        List<sObject> loopObjects = Database.query(query);
                        List<sObject> filteredLoopObjects = implementCustomFiltration(loopObjects, d.whereFilter);
                        filteredLoopObjects = implementCustomFiltration(filteredLoopObjects, d.apexFilter);
                        if (isCustomSort) {
                            filteredLoopObjects = customSort(filteredLoopObjects, objName, d.OrderBy);
                        }
                        if (filteredLoopObjects.size() > 0) {
                            d.data = filteredLoopObjects[0];
                        }
                        d.dataList = filteredLoopObjects;

                    }
                }
            }
            return data;
        }

        private List<sObject> implementCustomFiltration(List<sObject> dataList, String filterName) {

            if (filterName == CUSTOM_OVERAGES_FILTRATION) {
                List<sObject> filteredList = new List<sObject>();
                for (sObject obj : dataList) {
                    QuoteLineItem qli = (QuoteLineItem) obj;
                    Decimal approvedDiscount = NumberHelper.toNumber(qli.Last_Approved_Discount__c);
                    Decimal discountNumber = NumberHelper.toNumber(qli.Discount_Number__c);
                    if (qli.Product2.Family != Product2Helper.FAMILY_OVERAGE ||
                        qli.Product2.Family == Product2Helper.FAMILY_OVERAGE &&
                        approvedDiscount != discountNumber
                        ) {
                        filteredList.add(qli);
                    }
                }
                return filteredList;

            } else if (filterName == APEX_FILTER_OVERAGES_BY_DISCOUNT && dataList instanceof List<QuoteLineItem>) {
                return filterOveragesByDiscount((List<QuoteLineItem>) dataList);

            } else if (filterName == APEX_FILTER_REMOVE_NOT_CHANGED_QLIS && dataList instanceof List<QuoteLineItem>) {
                return getQlisWithNonApprovedChanges((List<QuoteLineItem>) dataList);

            } else {
                return dataList;
            }
        }

        // Filters overages based on presence of parent product and comparison of discounts.
        public List<QuoteLineItem> filterOveragesByDiscount(List<QuoteLineItem> dataList) {
            List<sObject> filteredList = new List<sObject>();
            // For parent products search, dataList is used as a scope. (see getSmsFeesPresented() and OveragesParentsMatcher.
            // Cause if parent product is not present in dataList - then it's overage also shouldn't.

            // used to avoid multiple searches of sms parent product in SMS overages filtration.
            // Contains INBOUND and/or OUTBOUND (if corresponding parent product presented).
            Set<SmsFee> smsFees = null;

            QuoteLineItemHelper.OveragesParentsMatcher parentsMatcher;

            for (QuoteLineItem qli : dataList) {
                if (qli.Product2.Family != Product2Helper.FAMILY_OVERAGE) {
                    continue;

                } else if (PRESERVE_OVERAGES.contains(qli.Product2.Name)) {
                    // preserve some 'special' Overages.
                    System.debug('qli.Product2.Name' + qli.Product2.Name +'/' + TemplateName);
                    if(qli.Product2.Name == 'Seat Overage' && TemplateName.contains('Contact Center')){
                        filteredList.add(qli);
                    }
                    else if(qli.Product2.Name != 'Seat Overage'){
                        filteredList.add(qli);
                    }

                } else if (Product2Helper.SMS_OVERAGE_TYPES.contains(qli.Product2.Product_Type__c)) {
                    // preserve sms overage if parent product presented
                    if (smsFees == null) {
                        smsFees = getSmsFeesPresented(dataList);
                    }
                    if (isSmsParentPresent(qli, smsFees)) {
                        filteredList.add(qli);
                    }

                } else if (0 == NumberHelper.toNumber(qli.UnitPrice)) {
                    // CRM-1375: Hide $0 overages from Attachment A
                    continue;

                } else if (qli.Entitlement__c != null) {
                    Decimal previousDiscount = NumberHelper.toNumber(qli.Entitlement__r.Discount__c);
                    Decimal currentDiscount = NumberHelper.toNumber(qli.Discount_number__c);
                    // if entitlement exists - check previous discount
                    if (currentDiscount != previousDiscount
                        || ((qli.Discount_type__c != qli.Entitlement__r.Discount_type__c) && (currentDiscount != 0))
                        ) {
                        filteredList.add(qli);
                    }

                } else {
                    // preserve qli if this overage discount differs from parent product discount.
                    if (parentsMatcher == null) {
                        parentsMatcher = new QuoteLineItemHelper.OveragesParentsMatcher((List<QuoteLineItem>) dataList);
                    }

                    QuoteLineItem parentQli = parentsMatcher.getParent(qli);
                    if (parentQli == null) {
                        continue;
                    }
                    Decimal parentDiscount = NumberHelper.toNumber(parentQli.Discount_number__c);
                    Decimal overageDiscount = NumberHelper.toNumber(qli.Discount_number__c);
                    if (overageDiscount != parentDiscount
                        || (qli.Discount_type__c != parentQli.Discount_type__c && (overageDiscount != 0))
                        ) {
                        filteredList.add(qli);
                    }
                }
            }

            return filteredList;
        }

        // Returns set with INBOUND and/or OUTBOUND values if corresponding SMS Fee product presented in allQlis.
        // startsWithIgnoreCase is required to handle different countries, e.g. "... SMS Application Fee - Canada"
        private Set<SmsFee> getSmsFeesPresented(List<QuoteLineItem> allQlis) {
            Set<SmsFee> smsFees = new Set<SmsFee>();

            for (QuoteLineItem qli : allQlis) {
                if (qli.Product2.Name.startsWithIgnoreCase(Product2Helper.NAME_CC_INBOUND_SMS_APPLICATION_FEE)) {
                    smsFees.add(SmsFee.INBOUND);
                } else if (qli.Product2.Name.startsWithIgnoreCase(Product2Helper.NAME_CC_OUTBOUND_SMS_APPLICATION_FEE)) {
                    smsFees.add(SmsFee.OUTBOUND);
                }
            }
            return smsFees;
        }

        private Boolean isSmsParentPresent(QuoteLineItem qli, Set<SmsFee> smsFees) {

            Boolean isInboundFeeChild = INBOUND_FEE_TYPES.contains(qli.Product2.Product_Type__c);
            Boolean isOutboundFeeChild = OUTBOUND_FEE_TYPES.contains(qli.Product2.Product_Type__c);

            return (isInboundFeeChild && smsFees.contains(SmsFee.INBOUND)) ||
                (isOutboundFeeChild && smsFees.contains(SmsFee.OUTBOUND));
        }

        // Removes qlis without changes in EffectivePrice, Discount, Quantity or Subtotal
        public List<QuoteLineItem> getQlisWithNonApprovedChanges(List<QuoteLineItem> qlis) {
            List<QuoteLineItem> qliWithChanges = new List<QuoteLineItem>();
            for (QuoteLineItem qli : qlis) {
                if (isQliHasNonApprovedChanges(qli)) {
                    qliWithCHanges.add(qli);
                }
            }
            return qliWithChanges;
        }

        // Checks qli for non approved changes in EffectivePrice, Discount, Quantity or Subtotal
        public Boolean isQliHasNonApprovedChanges(QuoteLineItem qli) {

            VirtualField vf = new VirtualField();

            // if DiscountType is empty - the default type 'Currency' should be used.
            String currentDiscountType = String.isEmpty(qli.Discount_type__c) ?
                QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY : qli.Discount_type__c;
            String lastApprovedDiscountType = String.isEmpty(qli.Last_Approved_Discount_Type__c) ?
                QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY : qli.Last_Approved_Discount_Type__c;

            Decimal currentPrice = (qli.Last_Approved_Discount__c == null) ? qli.UnitPrice : qli.EffectivePrice__c;
            return
                // check Discount change
                currentDiscountType != lastApprovedDiscountType
                    || NumberHelper.toNumber(qli.Discount_number__c) != NumberHelper.toNumber(qli.Last_Approved_Discount__c)
                    // check Quantity change
                    || (qli.Last_Approved_Quantity__c != null
                    && NumberHelper.toNumber(qli.NewQuantity__c) != NumberHelper.toNumber(qli.Last_Approved_Quantity__c))
                    // check EffectivePrice change
                    || NumberHelper.toNumber(qli.EffectivePriceNew__c).setScale(3, RoundingMode.HALF_UP) !=
                    NumberHelper.toNumber(currentPrice).setScale(3, RoundingMode.HALF_UP)
                    // check Subtotal change
                    || vf.currentItemSubtotal(qli) != vf.subtotalConsideringChargeTerm(qli, qli.Quote);

        }

        /**
         *  Implement custom sorting for queried list
         *  @see {@link https://rc.my.salesforce.com/a2034000003puK6} B-2921 PDF Products Sorting
         */
        public List<sObject> customSort(List<sObject> objectList, String sobjectName, String sortMethod) {
            List<sObject> sortedObjectList = objectList;
            if (PRODUCTS_STANDARD_SORT.equalsIgnoreCase(sortMethod)) {
                sortedObjectList = new List<sObject>();
                List<ProductTableItem> productTableItems = new List<ProductTableItem>();
                for (sObject obj : objectList) {
                    if ('QuoteLineItem'.equalsIgnoreCase(sobjectName)) {
                        QuoteLineItem qli = (QuoteLineItem) obj;
                        ProductTableItem prod = new ProductTableItem(
                            qli.Product2.Family,
                            qli.Product2.Name,
                            qli.Product2.Dependent_On_Feature__c,
                            obj
                        );
                        productTableItems.add(prod);
                    }
                    if ('Entitlement__c'.equalsIgnoreCase(sobjectName)) {
                        Entitlement__c ent = (Entitlement__c) obj;
                        ProductTableItem prod = new ProductTableItem(
                            ent.Product__r.Family,
                            ent.Product__r.Name,
                            ent.Product__r.Dependent_On_Feature__c,
                            obj
                        );
                        productTableItems.add(prod);
                    }
                }
                productTableItems.sort();
                for (Integer i = productTableItems.size() - 1; i >= 0; i--) {
                    sortedObjectList.add((sObject) productTableItems[i].obj);
                }
            }
            return sortedObjectList;
        }

        public List<ChangeOrderItem> customSortChangeOrder(List<ChangeOrderItem> objectList, String sortMethod) {
            List<ChangeOrderItem> sortedObjectList = objectList;
            if (PRODUCTS_STANDARD_SORT.equalsIgnoreCase(sortMethod)) {
                sortedObjectList = new List<ChangeOrderItem>();
                List<ProductTableItem> productTableItems = new List<ProductTableItem>();
                for (ChangeOrderItem coi : objectList) {
                    if (coi.QuoteLineItem != null) {
                        QuoteLineItem qli = coi.QuoteLineItem;
                        ProductTableItem prod = new ProductTableItem(
                            qli.Product2.Family,
                            qli.Product2.Name,
                            qli.Product2.Dependent_On_Feature__c,
                            coi
                        );
                        productTableItems.add(prod);
                    } else if (coi.Entitlement != null) {
                        Entitlement__c ent = coi.Entitlement;
                        ProductTableItem prod = new ProductTableItem(
                            ent.Product__r.Family,
                            ent.Product__r.Name,
                            ent.Product__r.Dependent_On_Feature__c,
                            coi
                        );
                        productTableItems.add(prod);
                    }
                }
                productTableItems.sort();
                for (Integer i = productTableItems.size() - 1; i >= 0; i--) {
                    sortedObjectList.add((ChangeOrderItem) productTableItems[i].obj);
                }
            }
            return sortedObjectList;
        }

        private void processVariableAssignment(String valuePart, String filtersPart, Map<String, DataItem> data,
            Map<String, String> parameters, Map<String, Integer> loopIndexMap, sObject prevObj) {
            Matcher wordMatcher = Pattern.compile(WORD_PATTERN).matcher(valuePart);
            // finds VARIABLE_KEYWORD
            wordMatcher.find();
            // finds variable name
            wordMatcher.find();
            String variableName = wordMatcher.group(1);
            // finds variable value or '=' (if literal value provided, e.g. 0.00 or "SomeStringVlaue")
            wordMatcher.find();
            String variableValuePartString = wordMatcher.group(1);
            Object variableValue;
            if (variableValuePartString != '=') {
                variableValue = replaceField(variableValuePartString, filtersPart, data, parameters, loopIndexMap, prevObj);
            } else {
                wordMatcher.find();
                variableValuePartString = wordMatcher.group(1);
                /* Logic to process variable assignments that have if conditions */
                if(filtersPart != null){
                    System.debug('filtersPart not null' + filtersPart);
                    String objPrefix = variableValuePartString.substringBefore('.');
                    System.debug('objPrefix' + objPrefix + '/' + variableValuePartString);
                    System.debug('data.get' + data.get(objPref).ifClauses.get(variableName) + '/' + variablename);
                    /* if 'ifClause' DataItem is present for the current variable */
                    if(objPrefix == 'qli' && data.get(objPref).ifClauses.get(variableName) != null){
                        String Comp_Field = data.get(objPref).ifClauses.get(variableName).comparisonField;
                        String op = data.get(objPref).ifClauses.get(variableName).ComparisonOp;
                        String compValue = data.get(objPref).ifClauses.get(variableName).ComparisonValue;
                        System.debug('Data list' + data.get(objPref));
                        for(Object qt: data.get(objPref).dataList){
                            SObject qli = (SObject)qt;
                            Id ProdId;
                            String FieldValue;
                            //if the field to be compared has a parent relationShip
                            if(Comp_Field.contains('.')){
                                SObject Prodc = qli.getSObject(Comp_Field.substringBefore('.'));
                                FieldValue = (String) Prodc.get(Comp_Field.substringAfter('.').trim());
                            }
                            else{
                                FieldValue = (String)qli.get(Comp_Field.trim());
                            }
                            System.debug('Field Value' + FieldValue);
                            System.debug('is if running' + FieldValue.length() + '/' + compValue.length());
                            //compare the field value and the comparision value we have stored in ifClause data item
                            if(op.equals('=') && FieldValue.equals(compValue.trim())){
                                variableValue = (String)qli.get('CurrencyIsoCode') + ' ' + String.valueOf(qli.get(data.get(objPref).ifClauses.get(variableName).returnField));
                            }
                            System.debug('variablevalue' + variableValue);
                        }

                    }
                }
                else{
                    variableValue = parseArgs(variableValuePartString).get(0);
                }
            }
            variablesMap.put(variableName.toLowerCase(), variableValue);

        }

        /**
         * Replace placeholders in templateBody with actual data
         *
         * For loops we first get the sub template string inside {! for ... } {! /for } tags
         * and call this method recursively
         *
         * @param templateBody
         * @param data
         * @param loopIndexMap
         * @param parameters
         * @param previousRenderedObj
         *
         * @return
         */
        public String replacePlaceholders(String templateBody,
            Map<String, DataItem> data,
            Map<String, Integer> loopIndexMap,
            Map<String, String> parameters,
            Object previousRenderedObj) {

            FormatterHelper format = new FormatterHelper();
            String resultBody = templateBody;
            Boolean isLoopInit = false;
            Boolean isLoopBody = false;
            String loopAlias = '';
            loopIndexMap = (loopIndexMap == null) ? new Map<String, Integer>() : loopIndexMap;

            Integer loopCounter = 0;

            Map<Integer, LoopItem> loopCounterToLoopItemMap = new Map<Integer, LoopItem>();

            // #{! ... }#
            Matcher baseMatcher = Pattern.compile(BASE_PATTERN).matcher(templateBody);
            while (baseMatcher.find()) {
                String placeholder = format.escapeRegexpString(baseMatcher.group(0));
                String valuePart = baseMatcher.group(1);
                String filtersPart = baseMatcher.group(2);
                String realData = '';

                // {! ... #foo# ... bar ... }
                Matcher wordMatcher = Pattern.compile(WORD_PATTERN).matcher(valuePart);
                while (wordMatcher.find()) {
                    String word = wordMatcher.group(1);
                    if (word == LOOP_START_KEYWORD) {
                        isLoopInit = true;
                        isLoopBody = true;

                        loopCounter++;
                        continue;
                    }
                    if (isLoopInit) {
                        loopAlias = word;
                        loopIndexMap.put(loopAlias, 0);
                        isLoopInit = false;

                        LoopItem l = new LoopItem();
                        l.loopRowStartAt = baseMatcher.end();
                        l.loopBlockStartAt = baseMatcher.start();
                        l.loopAlias = loopAlias;
                        l.loopIndexMap.put(loopAlias, 0);
                        loopCounterToLoopItemMap.put(loopCounter, l);

                        break;
                    }
                    if (word == LOOP_END_KEYWORD) {
                        isLoopBody = false;

                        LoopItem l = loopCounterToLoopItemMap.get(loopCounter);
                        l.loopRowEndAt = baseMatcher.start();
                        l.loopBlockEndAt = baseMatcher.end();

                        loopCounter--;
                        break;
                    }
                    if (loopCounter == 0) {
                        Sobject prevObj = previousRenderedObj instanceof ChangeOrderItem
                            ? null
                            : (sObject) previousRenderedObj;
                        if (word == VARIABLE_KEYWORD) {
                            processVariableAssignment(valuePart, filtersPart, data, parameters, loopIndexMap, prevObj);
                            break;
                        } else {
                            realData = StringHelper.safeString(
                                replaceField(valuePart, filtersPart, data, parameters, loopIndexMap, prevObj));
                        }
                    }
                }
                if (loopCounter == 0) {

                    LoopItem outerLoop = loopCounterToLoopItemMap.get(1);

                    if (outerLoop != null && !valuePart.contains('$')) {

                        String loopRow = templateBody.substring(outerLoop.loopRowStartAt, outerLoop.loopRowEndAt);
                        String loopBlock = templateBody.substring(outerLoop.loopBlockStartAt, outerLoop.loopBlockEndAt);

                        for (String alias : outerLoop.loopIndexMap.keySet()) {
                            for (Object loopObj : data.get(alias).dataList) {

                                if (previousRenderedObj != null) {
                                    Id prevRenderedObjId = (Id) ((sObject) previousRenderedObj).get('Id');
                                    String refFrom = data.get(alias).objectName;
                                    String refTo = determinedObjectById(prevRenderedObjId);

                                    String relationshipField = getRefFromTo(refFrom, refTo);

                                    Id parentObjId = (Id) ((sObject) loopObj).get(relationshipField);

                                    if (parentObjId == prevRenderedObjId) {
                                        Integer currentLoopObjIndex = data.get(alias).dataList.indexOf(loopObj);
                                        outerLoop.loopIndexMap.put(alias, currentLoopObjIndex);
                                        realData += replacePlaceholders(loopRow, data, outerLoop.loopIndexMap, parameters, loopObj);
                                    }

                                } else {
                                    Integer currentLoopObjIndex = data.get(alias).dataList.indexOf(loopObj);

                                    outerLoop.loopIndexMap.put(alias, currentLoopObjIndex);
                                    realData += replacePlaceholders(loopRow, data, outerLoop.loopIndexMap, parameters, loopObj);
                                }
                            }
                        }
                        outerLoop.loopIndexMap.clear();

                        String trimmedValuePart = valuePart.trim();

                        Boolean itIsBaseObjField = (trimmedValuePart != LOOP_END_KEYWORD
                            && trimmedValuePart != LOOP_START_KEYWORD
                            && !trimmedValuePart.contains('$'))
                            && data.get(BASE_OBJECT_KEYWORD).fields.contains(trimmedValuePart.toLowerCase());

                        if (!itIsBaseObjField) {
                            placeholder = format.escapeRegexpString(loopBlock);
                        }
                    }
                    loopCounterToLoopItemMap.clear();
                }
                realData = Matcher.quoteReplacement(realData);
                if (!isLoopBody && loopCounter == 0) {
                    resultBody = resultBody.replaceFirst(placeholder, realData);
                }
            }
            return resultBody;
        }


        /**
         * Replace fields placeholder with data and apply formatters
         *
         * @param valuePart
         * @param filtersPart
         * @param data
         * @param parameters    parameters for use by $params helper
         * @param loopIndexMap
         *
         * @return
         */
        public Object replaceField(String valuePart,
            String filtersPart,
            Map<String, DataItem> data,
            Map<String, String> parameters,
            Map<String, Integer> loopIndexMap,
            sObject parentObject) {

            Object realData = '';
            Id parentObjId = parentObject != null ? (Id) parentObject.get('Id') : null;

            try {
                FormatterHelper format = new FormatterHelper();
                ChangeOrderVirtualField covf = new ChangeOrderVirtualField();
                VirtualField vf = new VirtualField();
                DataItem dataItem = null;
                Object dataObj = null;

                // {! ... #foo# ... bar ... }
                Matcher wordMatcher = Pattern.compile(WORD_PATTERN).matcher(valuePart);
                while (wordMatcher.find()) {
                    String word = wordMatcher.group(1);

                    // #qli#.#Quantity.Name#
                    Matcher prefixDotNotationMatcher = Pattern.compile(PREFIX_DOT_NOTATION_PATTERN).matcher(word);
                    while (prefixDotNotationMatcher.find()) {
                        String prefix = prefixDotNotationMatcher.group(1);
                        String field = prefixDotNotationMatcher.group(2);
                        field = String.isNotBlank(field) ? field.trim() : '';

                        String cleanPrefix = cleanVirtualString(prefix);
                        String cleanField = cleanVirtualString(field);
                        // Get data item
                        dataItem = data.containsKey(cleanPrefix) ? data.get(cleanPrefix) : data.get(BASE_OBJECT_KEYWORD);

                        // Get data from loop row
                        Integer loopItemIndex = loopIndexMap.get(cleanPrefix);
                        Boolean isLoopItem = loopItemIndex != null;

                        if (isLoopItem && dataItem.dataList.isEmpty()) {
                            continue;
                        }

                        dataObj = (isLoopItem ? dataItem.dataList.get(loopItemIndex) : dataItem.data);

                        if (dataItem.type == CHANGE_ORDER_TYPE
                            || dataItem.type == HIERARCHY_TABLE_NEW
                            || dataItem.type == HIERARCHY_TABLE_EXISTING
                            || dataItem.type == HIERARCHY_TABLE_EXISTING_AND_NEW
                            || dataItem.type == HIERARCHY_TABLE_CHANGE_ORDER) {
                            realData = covf.getRealData(cleanField, data, dataItem, loopItemIndex);

                        } else if (prefix == RESERVED_WORD_CHAR + VARIABLE_KEYWORD) {
                            realData = this.variablesMap.get(field.toLowerCase());

                        } else if (isVirtual(prefix) || isVirtual(field)) {
                            // It is virtual Object, field or Helper function
                            realData = vf.replaceVirtualField(cleanPrefix, cleanField, data, dataItem, loopItemIndex, parameters, parentObjId);

                        } else if (data.containsKey(cleanPrefix)) {
                            // it is Simple field from loop
                            // qli.FieldName__c
                            realData = SFDescribeHelper.getSObjectField((sObject) dataObj, cleanField);

                        } else {
                            // It is simple field from base object
                            // Lookup__r.FieldName__c
                            realData = SFDescribeHelper.getSObjectField((sObject) dataObj, word);
                        }

                    }
                }

                // If filters part mentiones field - replace field placeholder with real data (also supports virtual fields)
                if (String.isNotBlank(filtersPart)) {
                    Matcher baseMatcher2 = Pattern.compile(BASE_PATTERN_2).matcher(filtersPart);
                    // search for '<! xxx >' constructions. Escaping characters are omitted.
                    Set<String> escapedFieldsInFilter = new Set<String>();
                    while (baseMatcher2.find()) {
                        escapedFieldsInFilter.add(baseMatcher2.group(1));
                    }
                    // proceed each found '<! xxx >' construction (for a case when the same entry used multiple times)
                    for (String escapedFieldInFilter : escapedFieldsInFilter) {
                        Object fieldValue = replaceField(escapedFieldInFilter, '', data, parameters, loopIndexMap, parentObject);
                        filtersPart = filtersPart.replace('<!' + escapedFieldInFilter + '>', JSON.serialize(fieldValue));
                    }
                }

                if (String.isNotBlank(filtersPart)) {
                    Matcher filterMatcher = Pattern.compile(FILTER_PATTERN).matcher(filtersPart);
                    while (filterMatcher.find()) {
                        String filterName = StringHelper.safeString(filterMatcher.group(1));
                        String filterArg = StringHelper.safeString(filterMatcher.group(2));

                        List<Object> filterArgsList = parseArgs(filterArg);

                        realData = (realData == null) ? '' : realData;

                        if (filterName.equalsIgnoreCase('addAfter')) {
                            realData = format.addAfter(realData, filterArgsList);

                        } else if (filterName.equalsIgnoreCase('setScale')) {
                            realData = format.setScale(realData, filterArgsList);

                        } else if (filterName.equalsIgnoreCase('asCurrency')) {
                            realData = format.asCurrency(realData, getObjToGetCurrency(dataItem), filterArgsList);

                        } else if (filterName.equalsIgnoreCase('asCurrencyOrPercentageString')) {
                            realData = format.asCurrencyOrPercentageString(
                                realData, getObjToGetCurrency(dataItem), filterArgsList);

                        } else if (filterName.equalsIgnoreCase('asNumber')) {
                            realData = format.asNumber(realData, filterArgsList);

                        } else if (filterName.equalsIgnoreCase('if')) {
                            realData = format.ifCondition(realData, filterArgsList);

                        } else if (filterName.equalsIgnoreCase('add')) {
                            realData = format.addDecimal(realData, filterArgsList);

                        } else if (filterName.equalsIgnoreCase('subtract')) {
                            realData = format.subtractDecimal(realData, filterArgsList);

                        } else if (filterName.equalsIgnoreCase('multiply')) {
                            realData = format.multiplyDecimal(realData, filterArgsList);

                        } else if (filterName.equalsIgnoreCase('divide')) {
                            realData = format.divideDecimal(realData, filterArgsList);

                        } else if (filterName.equalsIgnoreCase('asDate')) {
                            realData = format.asDate(realData, filterArgsList);

                        } else if (filterName.equalsIgnoreCase('pluralize')) {
                            realData = format.pluralize(realData, filterArgsList);

                        } else if (filterName.equalsIgnoreCase('rename')) {
                            realData = format.rename(realData, filterArgsList);

                        } else if (filterName.equalsIgnoreCase('translate')) {
                            realData = format.translate(realData, filterArgsList);

                        } else if (filterName.equalsIgnoreCase('default')) {
                            realData = format.default(realData, filterArgsList);

                        } else if (filterName.equalsIgnoreCase('wrap')) {
                            realData = format.wrap(realData, filterArgsList);

                        } else if (IS_DEBUG_MODE) {
                            realData = String.format('<span class="system-error">{0} not found </span>', new List<String>{
                                filterName
                            });
                            break;
                        }
                    }
                }
            } catch (Exception e) {

                System.debug(e);
                System.debug(e.getStackTraceString());
                realData = outputDebug(e, valuePart + ' ' + filtersPart);
            }
            return realData;
        }

        public List<Object> parseArgs(String args) {
            String argsJSON = '[' + args.replaceAll(QUOTES_PATTERN, '"').replaceAll(ESCAPED_QUOTE_PATTERN, '\'').replaceAll(ESCAPED_QUOTES_PATTERN, '$1\'$3') + ']';
            List<Object> argsList = (List<Object>) JSON.deserializeUntyped(argsJSON);
            return argsList;
        }

        public Map<String, DataItem> preprocessData(Map<String, DataItem> data){
            for (String key : data.keySet()) {
                DataItem d = data.get(key);

                if (d.type == CHANGE_ORDER_TYPE
                    || d.type == HIERARCHY_TABLE_NEW
                    || d.type == HIERARCHY_TABLE_EXISTING
                    || d.type == HIERARCHY_TABLE_EXISTING_AND_NEW
                    || d.type == HIERARCHY_TABLE_CHANGE_ORDER) {
                    d = preprocessChangeOrder(d);
                }

                if (d.type == HIERARCHY_TABLE_TYPE
                    || d.type == HIERARCHY_TABLE_NEW
                    || d.type == HIERARCHY_TABLE_EXISTING
                    || d.type == HIERARCHY_TABLE_EXISTING_AND_NEW
                    || d.type == HIERARCHY_TABLE_CHANGE_ORDER) {
                    d = preprocessHierarchyTable(d);
                }
            }

            return data;
        }

        private DataItem preprocessHierarchyTable(DataItem d) {
            hierarchySettings = getHierarchySettings();

            if (d.type == HIERARCHY_TABLE_TYPE) {
                List<QuoteLineItem> rootElements = new List<QuoteLineItem>();
                List<QuoteLineItem> childElements = new List<QuoteLineItem>();
                List<QuoteLineItem> flatElements = new List<QuoteLineItem>();

                List<QuoteLineItem> qlis = (List<QuoteLineItem>) d.dataList;
                for (QuoteLineItem qli : qlis) {
                    if (showQliInPdf(qli)) {
                        if (isRootElement(qli)) {
                            QuoteLineItem clone = qli.clone(true, true, false, false);
                            clone.Product2 = qli.Product2;
                            rootElements.add(clone);
                        }
                        if (isChildElement(qli)) {
                            childElements.add(qli);
                        }
                        if (isNotInHierarchy(qli)) {
                            flatElements.add(qli);
                        }
                    }
                }
                d.dataList = createItemsHierarchy(rootElements, childElements, flatElements);
            } else if (d.type == HIERARCHY_TABLE_NEW
                || d.type == HIERARCHY_TABLE_EXISTING
                || d.type == HIERARCHY_TABLE_EXISTING_AND_NEW) {
                List<ChangeOrderItem> items = new List<ChangeOrderItem>();

                for (QuoteLineItem qli : (List<QuoteLineItem>) d.dataListMap.get(CHANGE_ORDER_QUOTELINEITEM_KEYWORD)) {
                    ChangeOrderItem coi = new ChangeOrderItem();
                    coi.quoteLineItem = qli;
                    items.add(coi);
                }
                for (Entitlement__c ent : (List<Entitlement__c>) d.dataListMap.get(CHANGE_ORDER_ENTITLEMENT_KEYWORD)) {
                    ChangeOrderItem coi = new ChangeOrderItem();
                    coi.entitlement = ent;
                    items.add(coi);
                }

                List<ChangeOrderItem> matchedItems = matchEntitlementsAndQlis(items);
                List<ChangeOrderItem> filteredItems = filterItemsByTableType(matchedItems, d.type);

                List<ChangeOrderItem> rootElements = new List<ChangeOrderItem>();
                List<ChangeOrderItem> childElements = new List<ChangeOrderItem>();
                List<ChangeOrderItem> flatElements = new List<ChangeOrderItem>();

                for (ChangeOrderItem coi : filteredItems) {
                    if (showQliInPdf(coi.quoteLineItem)) {
                        if (isRootElement(coi.quoteLineItem)) {
                            rootElements.add(coi);
                        }
                        if (isChildElement(coi.quoteLineItem)) {
                            childElements.add(coi);
                        }
                        if (isNotInHierarchy(coi.quoteLineItem)) {
                            flatElements.add(coi);
                        }
                    }
                }

                d.dataList = createItemsHierarchyForExistingBusiness(rootElements, childElements, flatElements);
            } else if (d.type == HIERARCHY_TABLE_CHANGE_ORDER) {
                List<ChangeOrderItem> rootElementsMerged = new List<ChangeOrderItem>();

                List<ChangeOrderItem> rootElementsQli = new List<ChangeOrderItem>();
                List<ChangeOrderItem> childElementsQli = new List<ChangeOrderItem>();
                List<ChangeOrderItem> flatElementsQli = new List<ChangeOrderItem>();

                List<ChangeOrderItem> rootElementsEnt = new List<ChangeOrderItem>();
                List<ChangeOrderItem> childElementsEnt = new List<ChangeOrderItem>();
                List<ChangeOrderItem> flatElementsEnt = new List<ChangeOrderItem>();

                for (ChangeOrderItem coi : (List<ChangeOrderItem>) d.dataList) {
                    if (coi.quoteLineItem != null && coi.entitlement != null
                        && isRootElement(coi.quoteLineItem)) {
                        rootElementsMerged.add(coi);
                    }
                    if (coi.quoteLineItem != null) {
                        if (isRootElement(coi.quoteLineItem)
                            && !rootElementsMerged.contains(coi)) {
                            rootElementsQli.add(coi);
                        }
                        if (isChildElement(coi.quoteLineItem)) {
                            childElementsQli.add(coi);
                        }
                        if (isNotInHierarchy(coi.quoteLineItem)) {
                            flatElementsQli.add(coi);
                        }
                    }
                    if (coi.entitlement != null) {
                        if (isRootElement(coi.entitlement, (List<ChangeOrderItem>) d.dataList)
                            && !rootElementsMerged.contains(coi)) {
                            rootElementsEnt.add(coi);
                        }
                        if (isChildElement(coi.entitlement, (List<ChangeOrderItem>) d.dataList)) {
                            childElementsEnt.add(coi);
                        }
                        if (isNotInHierarchy(coi.entitlement, (List<ChangeOrderItem>) d.dataList)
                            && !flatElementsQli.contains(coi)) {
                            flatElementsEnt.add(coi);
                        }
                    }
                }

                d.dataList = createItemsHierarchyChangeOrder(
                    rootElementsMerged, rootElementsQli, childElementsQli, flatElementsQli, rootElementsEnt, childElementsEnt, flatElementsEnt);
            }
            return d;
        }

        private Boolean isRootElement(QuoteLineItem qli) {
            for (PdfHierarchySettings__mdt setting : hierarchySettings) {
                if(qli.Quote.PackageNameNew__c != AIR_PACKAGE_NAME && setting.Parent__c.equalsIgnoreCase('AIR')){
                    continue;
                }
                if (setting.Parent__c.equalsIgnoreCase(getCategoryPath(qli))) {
                    return true;
                }
            }

            return false;
        }

        private Boolean isRootElement(Entitlement__c ent, List<ChangeOrderItem> dataList) {
            for (PdfHierarchySettings__mdt setting : hierarchySettings) {
                if(ent.Quote__r.PackageNameNew__c != AIR_PACKAGE_NAME && setting.Parent__c.equalsIgnoreCase('AIR')){
                    continue;
                }
                if (setting.Parent__c.contains(getCategoryPath(ent, dataList))) {
                    return true;
                }
            }

            return false;
        }

        private Boolean isChildElement(QuoteLineItem qli) {
            for (PdfHierarchySettings__mdt setting : hierarchySettings) {
                if(qli.Quote.PackageNameNew__c != AIR_PACKAGE_NAME && setting.Parent__c.equalsIgnoreCase('AIR')){
                    continue;
                }
                if (setting.Childs__c.split(',').contains(getCategoryPath(qli))) {
                    return true;
                }
            }

            return false;
        }

        private Boolean isChildElement(Entitlement__c ent, List<ChangeOrderItem> dataList) {
            for (PdfHierarchySettings__mdt setting : hierarchySettings) {
                if(ent.Quote__r.PackageNameNew__c != AIR_PACKAGE_NAME && setting.Parent__c.equalsIgnoreCase('AIR')){
                    continue;
                }
                if (setting.Childs__c.split(',').contains(getCategoryPath(ent, dataList))) {
                    return true;
                }
            }

            return false;
        }

        private Boolean isNotInHierarchy(QuoteLineItem qli) {
            return !isRootElement(qli) && !isChildElement(qli);
        }

        private Boolean isNotInHierarchy(Entitlement__c ent, List<ChangeOrderItem> dataList) {
            return !isRootElement(ent, dataList) && !isChildElement(ent, dataList);
        }

        private Boolean showQliInPdf(QuoteLineItem qli) {
            return qli.EffectivePriceNew__c != 0
                || PRESERVE_PRODUCT_EXT_ID.contains(qli.Product2.ExtID__c)
                || (qli.EffectivePriceNew__c == 0 && qli.Discount == 100);
            //handle 100% discount
        }

        private List<QuoteLineItem> createItemsHierarchy(
            List<QuoteLineItem> rootElements,
            List<QuoteLineItem> childElements,
            List<QuoteLineItem> flatElements
        ) {
            List<QuoteLineItem> result = new List<QuoteLineItem>();

            rootElements.addAll(flatElements);
            rootElements = customSort(rootElements, 'QuoteLineItem', this.PRODUCTS_STANDARD_SORT);

            for (QuoteLineItem parent : rootElements) {
                //copy qli because the same qli can be parent and child
                QuoteLineItem newParent = parent.clone(false, true, false, true);
                Decimal parentOverallPrice = 0;
                qliIdToHierarchyLevel.put(newParent.Id, 0);
                List<String> childCategoryPaths = getChildCategoryPathsByParent(newParent);
                List<QuoteLineItem> childs = new List<QuoteLineItem>();

                for (QuoteLineItem child : childElements) {
                    if (childCategoryPaths.contains(getCategoryPath(child))) {
                        qliIdToHierarchyLevel.put(child.Id, 1);
                        child.Quantity = newParent.Quantity;
                        childs.add(child);

                        parentOverallPrice += child.EffectivePriceNew__c;
                    }
                }

                newParent.EffectivePriceNew__c = parentOverallPrice == 0 ? newParent.EffectivePriceNew__c : parentOverallPrice;
                result.add(newParent);
                result.addAll(sortChilds(childCategoryPaths, childs));
            }

            return result;
        }

        private List<String> getChildCategoryPathsByParent(QuoteLineItem qli) {
            for (PdfHierarchySettings__mdt setting : hierarchySettings) {
                if(qli.Quote.PackageNameNew__c != AIR_PACKAGE_NAME && setting.Parent__c.equalsIgnoreCase('AIR')){
                    continue;
                }
                if (setting.Parent__c.equalsIgnoreCase(getCategoryPath(qli))) {
                    return setting.Childs__c.split(',');
                }
            }

            return new List<String>();
        }

        private List<String> getChildCategoryPathsByParent(Entitlement__c ent, List<ChangeOrderItem> items) {
            for (PdfHierarchySettings__mdt setting : hierarchySettings) {
                if(ent.Quote__r.PackageNameNew__c != AIR_PACKAGE_NAME && setting.Parent__c.equalsIgnoreCase('AIR')){
                    continue;
            	}
                if (setting.Parent__c.equalsIgnoreCase(getCategoryPath(ent, items))) {
                    return setting.Childs__c.split(',');
                }
            }

            return new List<String>();
        }

        private String getCategoryPath(QuoteLineItem qli) {
            BillingWrappers.QLIPackageInfo qliPackageInfo = new BillingWrappers.QLIPackageInfo(qli.PackageInfo__c);
            return qliPackageInfo.categoryPath;
        }

        private String getCategoryPath(Entitlement__c ent, List<ChangeOrderItem> items) {
            QuoteLineItem matchedQli;

            for (ChangeOrderItem coi : items) {
                if (coi.quoteLineItem != null && ent.Id == coi.quoteLineItem.Entitlement__c) {
                    matchedQli = coi.quoteLineItem;
                    break;
                }
            }

            if (matchedQli == null) {
                return '';
            }

            BillingWrappers.QLIPackageInfo qliPackageInfo = new BillingWrappers.QLIPackageInfo(matchedQli.PackageInfo__c);
            return qliPackageInfo.categoryPath;
        }

        private List<PdfHierarchySettings__mdt> getHierarchySettings() {
            return (List<PdfHierarchySettings__mdt>) new PdfHierarchySettingsSelector()
                .selectPdfHierarchySettings()
                .executeQuery();
        }

        private List<QuoteLineItem> sortChilds(List<String> childCategoryPaths, List<QuoteLineItem> childs) {
            List<QuoteLineItem> sortedChilds = new List<QuoteLineItem>();

            for (String categoryPath : childCategoryPaths) {
                for (QuoteLineItem child : childs) {
                    if (categoryPath.equalsIgnoreCase(getCategoryPath(child))) {
                        sortedChilds.add(child);
                        break;
                    }
                }
            }

            return sortedChilds;
        }

        private List<ChangeOrderItem> matchEntitlementsAndQlis(List<ChangeOrderItem> items) {
            List<ChangeOrderItem> matchedItems = new List<ChangeOrderItem>();
            List<ChangeOrderItem> entitlementsToMatch = new List<ChangeOrderItem>();
            List<ChangeOrderItem> itemsWithoutEntitlements = new List<ChangeOrderItem>();

            for (ChangeOrderItem item : items) {

                if (item.quoteLineItem == null && item.entitlement != null) {
                    entitlementsToMatch.add(item);
                }
                if (item.quoteLineItem != null && item.entitlement != null) {
                    matchedItems.add(item);
                }
                if (item.quoteLineItem != null && item.entitlement == null) {
                    itemsWithoutEntitlements.add(item);
                }
            }

            for (ChangeOrderItem itemWithoutEnt : itemsWithoutEntitlements) {
                for (ChangeOrderItem itemWithoutQli : entitlementsToMatch) {
                    if (itemWithoutEnt.quoteLineItem.Entitlement__c == itemWithoutQli.entitlement.Id) {
                        itemWithoutEnt.entitlement = itemWithoutQli.entitlement;
                        break;
                    }
                }

                matchedItems.add(itemWithoutEnt);
            }

            return matchedItems;
        }

        private boolean isValidQli(ChangeOrderItem coi) {
            if (coi.quoteLineItem.Zero_Quantity__c && coi.quoteLineItem.NewQuantity__c == 0) {
                return false;
            }

            return true;
        }

        private List<ChangeOrderItem> filterItemsByTableType(List<ChangeOrderItem> items, String type) {
            List<ChangeOrderItem> filteredItems = new List<ChangeOrderItem>();

            if (type == HIERARCHY_TABLE_NEW) {
                for (ChangeOrderItem coi : items) {
                    if ((coi.quoteLineItem.Display_Name__c != null
                        && isValidQli(coi))
                        || (isChildElement(coi.quoteLineItem) && !isRootElement(coi.quoteLineItem))
                        ) {
                        filteredItems.add(coi);
                    }
                }
            }

            if (type == HIERARCHY_TABLE_EXISTING) {
                for (ChangeOrderItem coi : items) {
                    if (coi.entitlement != null
                        && ((coi.entitlement.Price__c > 0
                        && coi.entitlement.Quantity__c > 0)
                        || PRESERVE_PRODUCT_EXT_ID.contains(coi.entitlement.Product__r.ExtID__c))) {
                        filteredItems.add(coi);
                    }
                }
            }

            if (type == HIERARCHY_TABLE_EXISTING_AND_NEW) {
                for (ChangeOrderItem coi : items) {
                    if (isValidQli(coi)
                        && (!coi.quoteLineItem.Zero_Quantity__c
                        || (coi.quoteLineItem.Display_Name__c != null && (isChildElement(coi.quoteLineItem)))
                        || coi.quoteLineItem.NewQuantity__c > 0)) {
                        filteredItems.add(coi);
                    }
                }
            }

            return filteredItems;
        }

        private List<ChangeOrderItem> createItemsHierarchyForExistingBusiness(
            List<ChangeOrderItem> rootElements,
            List<ChangeOrderItem> childElements,
            List<ChangeOrderItem> flatElements
        ) {
            List<ChangeOrderItem> result = new List<ChangeOrderItem>();

            rootElements.addAll(flatElements);
            rootElements = customSortChangeOrder(rootElements, this.PRODUCTS_STANDARD_SORT);

            for (ChangeOrderItem parent : rootElements) {
                ChangeOrderItem newParent = new ChangeOrderItem();
                newParent.quoteLineItem = parent.quoteLineItem.clone(false, true, false, true);
                newParent.quoteLineItem.Id = null;
                overrideEntPrice(parent);

                Decimal qliParentOverallPrice = 0;
                Decimal entParentOverallPrice = 0;
                Boolean isNewItem = false;

                qliIdToHierarchyLevelChangeOrder.put(newParent.quoteLineItem.Id, 0);
                if (parent.entitlement != null) {
                    newParent.entitlement = parent.entitlement.clone(false, true, false, true);
                    newParent.entitlement.Id = null;

                    //handle discount only case
                    if (newParent.quoteLineItem.Zero_Quantity__c && newParent.entitlement != null) {
                        newParent.quoteLineItem.Quantity = newParent.entitlement.Quantity__c;
                    }

                    entIdToHierarchyLevelChangeOrder.put(newParent.entitlement.Id, 0);
                } else {
                    isNewItem = true;
                }
                List<String> childCategoryPaths = getChildCategoryPathsByParent(newParent.quoteLineItem);
                List<ChangeOrderItem> childs = new List<ChangeOrderItem>();

                for (ChangeOrderItem child : childElements) {
                    overrideEntPrice(child);
                    if (childCategoryPaths.contains(getCategoryPath(child.quoteLineItem))) {
                        if (child.quoteLineItem.Id != null) {
                            qliIdToHierarchyLevelChangeOrder.put(child.quoteLineItem.Id, 1);
                        }
                        child.quoteLineItem.Quantity = newParent.quoteLineItem.Quantity;
                        if(isNewItem) {
                            ChangeOrderItem newChild = new ChangeOrderItem();
                            newChild.quoteLineItem = child.quoteLineItem.clone(true, true, false, true);
                            newChild.entitlement = null;
                            childs.add(newChild);
                        } else if (child.entitlement != null) {
                            child.entitlement.Quantity__c = newParent.entitlement.Quantity__c;
                            entIdToHierarchyLevelChangeOrder.put(child.entitlement.Id, 1);
                            childs.add(child);
                        }

                        qliParentOverallPrice += child.quoteLineItem.EffectivePriceNew__c;
                        if (child.entitlement != null) {
                            entParentOverallPrice += child.entitlement.Price__c;
                        }
                    }
                }

                newParent.quoteLineItem.EffectivePriceNew__c = qliParentOverallPrice == 0 ? newParent.quoteLineItem.EffectivePriceNew__c : qliParentOverallPrice;
                if (newParent.entitlement != null) {
                    newParent.entitlement.Price__c = entParentOverallPrice == 0 ? newParent.entitlement.Price__c : entParentOverallPrice;
                }

                result.add(newParent);
                result.addAll(sortChangeOrderChildsQli(childCategoryPaths, childs));
            }

            return result;
        }

        /* copy EffectivePrice__c to Price__c because EffectivePrice__c can't accumulate child prices,
           since EffectivePrice__c is not writable
        */
        private void overrideEntPrice(ChangeOrderItem coi) {
            if (coi.entitlement != null) {
                coi.entitlement.Price__c = (coi.entitlement.EffectivePrice__c).setScale(2, RoundingMode.HALF_UP);
            }
        }

        private List<ChangeOrderItem> sortChangeOrderChildsQli(List<String> childCategoryPaths, List<ChangeOrderItem> childs) {
            List<ChangeOrderItem> sortedChilds = new List<ChangeOrderItem>();

            for (String categoryPath : childCategoryPaths) {
                for (ChangeOrderItem child : childs) {
                    if (categoryPath.equalsIgnoreCase(getCategoryPath(child.quoteLineItem))) {
                        sortedChilds.add(child);
                        break;
                    }
                }
            }

            return sortedChilds;
        }

        private List<ChangeOrderItem> sortChangeOrderChildsEnt(List<String> childCategoryPaths, List<ChangeOrderItem> childs, List<ChangeOrderItem> correspondingQlis) {
            List<ChangeOrderItem> sortedChilds = new List<ChangeOrderItem>();

            for (String categoryPath : childCategoryPaths) {
                for (ChangeOrderItem child : childs) {
                    if (categoryPath.equalsIgnoreCase(getCategoryPath(child.entitlement, correspondingQlis))) {
                        sortedChilds.add(child);
                        break;
                    }
                }
            }

            return sortedChilds;
        }

        private List<ChangeOrderItem> createItemsHierarchyChangeOrder(
            List<ChangeOrderItem> rootElementsMerged,
            List<ChangeOrderItem> rootElementsQli,
            List<ChangeOrderItem> childElementsQli,
            List<ChangeOrderItem> flatElementsQli,
            List<ChangeOrderItem> rootElementsEnt,
            List<ChangeOrderItem> childElementsEnt,
            List<ChangeOrderItem> flatElementsEnt
        ) {
            List<ChangeOrderItem> result = new List<ChangeOrderItem>();

            rootElementsQli.addAll(flatElementsQli);
            rootElementsQli = customSortChangeOrder(rootElementsQli, this.PRODUCTS_STANDARD_SORT);


            rootElementsEnt.addAll(flatElementsEnt);
            rootElementsEnt = customSortChangeOrder(rootElementsEnt, this.PRODUCTS_STANDARD_SORT);

            for (ChangeOrderItem parent : rootElementsMerged) {
                List<String> childCategoryPaths = getChildCategoryPathsByParent(parent.quoteLineItem);
                Boolean isParentSplitted = false;

                for (ChangeOrderItem child : childElementsQli) {
                    if (childCategoryPaths.contains(getCategoryPath(child.quoteLineItem))
                        && child.entitlement == null
                        && parent.QuoteLineItem.NewQuantity__c != 0
                        ) {
                        isParentSplitted = true;
                        ChangeOrderItem rootElementQli = new ChangeOrderItem();
                        rootElementQli.quoteLineItem = parent.quoteLineItem;
                        rootElementQli.entitlement = null;
                        rootElementsQli.add(rootElementQli);
                        break;
                    }
                }
                for (ChangeOrderItem child : childElementsEnt) {
                    if (childCategoryPaths.contains(getCategoryPath(child.entitlement, childElementsQli))
                        && child.quoteLineItem == null
                        ) {
                        isParentSplitted = true;
                        ChangeOrderItem rootElementEnt = new ChangeOrderItem();
                        rootElementEnt.quoteLineItem = null;
                        rootElementEnt.entitlement = parent.entitlement;
                        rootElementsEnt.add(rootElementEnt);
                        break;
                    }
                }
                if (!isParentSplitted) {
                    rootElementsQli.add(parent);
                }
            }

            //qli part
            for (ChangeOrderItem parent : rootElementsQli) {
                Decimal qliParentOverallPrice = 0;
                ChangeOrderItem newParent = new ChangeOrderItem();
                newParent.quoteLineItem = parent.quoteLineItem.clone(false, true, false, true);
                newParent.entitlement = parent.entitlement?.clone(false, true, false, true);

                List<String> childCategoryPaths = getChildCategoryPathsByParent(newParent.quoteLineItem);
                List<ChangeOrderItem> childs = new List<ChangeOrderItem>();

                for (ChangeOrderItem child : childElementsQli) {
                    if (childCategoryPaths.contains(getCategoryPath(child.quoteLineItem))) {
                        qliIdToHierarchyLevelChangeOrder.put(child.quoteLineItem.Id, 1);
                        child.quoteLineItem.Quantity = newParent.quoteLineItem.Quantity;
                        qliParentOverallPrice += child.quoteLineItem.EffectivePriceNew__c;
                        childs.add(child);
                    }
                }

                newParent.quoteLineItem.EffectivePriceNew__c = qliParentOverallPrice == 0 ? newParent.quoteLineItem.EffectivePriceNew__c : qliParentOverallPrice;
                result.add(newParent);
                result.addAll(sortChangeOrderChildsQli(childCategoryPaths, childs));
            }

            //entitlement part
            for (ChangeOrderItem parent : rootElementsEnt) {
                Decimal entParentOverallPrice = 0;
                ChangeOrderItem newParent = new ChangeOrderItem();
                newParent.quoteLineItem = parent.quoteLineItem?.clone(false, true, false, true);
                newParent.entitlement = parent.entitlement.clone(false, true, false, true);
                overrideEntPrice(newParent);

                List<ChangeOrderItem> childs = new List<ChangeOrderItem>();
                entIdToHierarchyLevelChangeOrder.put(newParent.entitlement.Id, 0);
                List<String> childCategoryPaths = getChildCategoryPathsByParent(parent.entitlement, rootElementsQli);

                for (ChangeOrderItem child : childElementsEnt) {
                    if (childCategoryPaths.contains(getCategoryPath(child.entitlement, childElementsQli))) {
                        entIdToHierarchyLevelChangeOrder.put(child.entitlement.Id, 1);
                        child.entitlement.Quantity__c = newParent.entitlement.Quantity__c;
                        overrideEntPrice(child);
                        entParentOverallPrice += child.entitlement.Price__c;
                        childs.add(child);
                    }
                }

                newParent.entitlement.Price__c = entParentOverallPrice == 0 ? newParent.entitlement.Price__c : entParentOverallPrice;

                result.add(newParent);
                result.addAll(sortChangeOrderChildsEnt(childCategoryPaths, childs, childElementsQli));
            }

            return result;
        }

        public DataItem preprocessChangeOrder(DataItem d){
            d.dataList = new List<ChangeOrderItem>();

            ChangeOrderVirtualField covf = new ChangeOrderVirtualField();
            List<QuoteLineItem> qlis = d.dataListMap.get(CHANGE_ORDER_QUOTELINEITEM_KEYWORD);
            Map<Id, Entitlement__c> ents = new Map<Id, Entitlement__c>((List<Entitlement__c>) d.dataListMap.get(CHANGE_ORDER_ENTITLEMENT_KEYWORD));
            Set<Id> entIDs = new Set<Id>();

            for (QuoteLineItem qli : qlis) {
                if (qli.IsHiddenLicense__c && !preserveProductsForHierarchyTables(qli, d.type)) {
                    entIDs.add(qli.Entitlement__c);
                    continue;
                }

                ChangeOrderItem coi = new ChangeOrderItem();
                coi.QuoteLineItem = qli;
                if (isChangeOrderQliShouldBeMergedWithEntitlement(qli)) {
                    coi.Entitlement = ents.get(qli.Entitlement__c);
                    entIDs.add(qli.Entitlement__c);
                }
                d.dataList.add(coi);
            }

            for (Entitlement__c ent : ents.values()) {
                if (!entIDs.contains(ent.Id)) {
                    ChangeOrderItem coi = new ChangeOrderItem();
                    coi.Entitlement = ent;
                    d.dataList.add(coi);
                }
            }

            d.dataList = (List<Object>) covf.filterOutNotChanged((List<ChangeOrderItem>) d.dataList);
            Boolean isCustomSort = SORT_METHOD_NAMES.contains(d.orderBy);
            if (isCustomSort) {
                d.dataList = customSortChangeOrder((List<ChangeOrderItem>) d.dataList, d.orderBy);
            }

            return d;
        }

        public Boolean isChangeOrderQliShouldBeMergedWithEntitlement(QuoteLineItem qli) {
            Decimal qliUnitPrice = ((Decimal) NumberHelper.getNumberNullSafe(qli.UnitPrice)).setScale(2, RoundingMode.HALF_UP);
            Decimal qliEffectivePriceNew = ((Decimal) NumberHelper.getNumberNullSafe(qli.EffectivePriceNew__c)).setScale(2, RoundingMode.HALF_UP);
            Decimal entPrice = ((Decimal) NumberHelper.getNumberNullSafe(qli.Entitlement__r.Price__c)).setScale(2, RoundingMode.HALF_UP);
            Decimal entEffectivePrice = ((Decimal) NumberHelper.getNumberNullSafe(qli.Entitlement__r.EffectivePrice__c)).setScale(2, RoundingMode.HALF_UP);
            return String.isNotBlank(qli.Entitlement__c) &&
                QuoteLineItemHelper.getChargeTerm(qli) == EntitlementHelper.getChargeTerm(qli.Entitlement__r) &&
                qli.PackageCatalogId__c == qli.Entitlement__r.PackageCatalogId__c &&
                qli.PackageVersion__c == qli.Entitlement__r.PackageVersion__c &&
                (!QuoteHelper.isNewBillingQuote(qli) ||
                    (qliUnitPrice == entPrice && qliEffectivePriceNew == entEffectivePrice));
        }

        public Boolean preserveProductsForHierarchyTables(QuoteLineItem qli, String type) {
            return (type == HIERARCHY_TABLE_CHANGE_ORDER
                ||  type == HIERARCHY_TABLE_TYPE
                ||  type == HIERARCHY_TABLE_NEW
                ||  type == HIERARCHY_TABLE_EXISTING
                ||  type == HIERARCHY_TABLE_EXISTING_AND_NEW)
                && PRESERVE_PRODUCT_EXT_ID.contains(qli.Product2.ExtID__c);
        }

        // returns sObject which should be used in 'asCurrency' formatter to determine CurrencyIsoCode.
        public sObject getObjToGetCurrency(DataItem dataItem) {
            sObject objToGetCurrency = null;
            if (dataItem.type == CHANGE_ORDER_TYPE
                || dataItem.type == HIERARCHY_TABLE_NEW
                || dataItem.type == HIERARCHY_TABLE_EXISTING
                || dataItem.type == HIERARCHY_TABLE_EXISTING_AND_NEW
                || dataItem.type == HIERARCHY_TABLE_CHANGE_ORDER) {
                ChangeOrderItem coi = null;
                if (!dataItem.dataList.isEmpty()) {
                    coi = (ChangeOrderItem) dataItem.dataList.get(0);
                }
                if (coi != null && coi.QuoteLineItem != null) {
                    objToGetCurrency = coi.QuoteLineItem;
                } else if (coi != null && coi.Entitlement != null) {
                    objToGetCurrency = coi.Entitlement;
                }
            } else {
                objToGetCurrency = dataItem.data;
            }
            return objToGetCurrency;
        }
    }

    public class ChangeOrderVirtualField {

        public void enrichChangeOrderRequiredFields(Map<String, Set<String>> fieldSets, String virtualFieldName) {
            VirtualField vf = new VirtualField();
            virtualFieldName = virtualFieldName.trim();
            Matcher prefixDotNotationMatcher = Pattern.compile(PREFIX_DOT_NOTATION_PATTERN).matcher(virtualFieldName);
            Boolean isSObjectReference = false;
            String prefix = null;
            String field = null;
            String cleanField = null;
            while (prefixDotNotationMatcher.find()) {
                // #qli#.#Quantity.Name#
                prefix = prefixDotNotationMatcher.group(1);
                field = prefixDotNotationMatcher.group(2);
                cleanField = cleanVirtualString(field);
                isSObjectReference = fieldSets.keySet().contains(prefix);
            }

            if ('dependentOnFeature'.equalsIgnoreCase(prefix)) {
                virtualFieldName = cleanField;
                addToFieldSet(fieldSets.get(CHANGE_ORDER_ENTITLEMENT_KEYWORD), DEPENDENT_ON_FEATURE_FIELDS.get(CHANGE_ORDER_ENTITLEMENT_KEYWORD));
                addToFieldSet(fieldSets.get(CHANGE_ORDER_QUOTELINEITEM_KEYWORD), DEPENDENT_ON_FEATURE_FIELDS.get(CHANGE_ORDER_QUOTELINEITEM_KEYWORD));
            }

            if (isSObjectReference) {
                if(isVirtual(field)){
                    if ('quantity'.equalsIgnoreCase(cleanField)) {
                        addToFieldSet(fieldSets.get(CHANGE_ORDER_QUOTELINEITEM_KEYWORD), vf.QUANTITY_FIELDS.get(LOOP_OBJ_KEYWORD));

                    } else if ('currentSubtotal'.equalsIgnoreCase(cleanField)) {
                        addToFieldSet(fieldSets.get(CHANGE_ORDER_ENTITLEMENT_KEYWORD), vf.CURRENT_SUBTOTAL_FIELDS.get(LOOP_OBJ_KEYWORD));

                    } else if ('newSubtotal'.equalsIgnoreCase(cleanField)) {
                        addToFieldSet(fieldSets.get(CHANGE_ORDER_QUOTELINEITEM_KEYWORD), vf.NEW_SUBTOTAL_FIELDS.get(LOOP_OBJ_KEYWORD));

                    } else if ('newRate'.equalsIgnoreCase(cleanField)) {
                        addToFieldSet(fieldSets.get(CHANGE_ORDER_QUOTELINEITEM_KEYWORD), vf.NEW_RATE_FIELDS.get(LOOP_OBJ_KEYWORD));

                    }

                } else {
                    addToFieldSet(fieldSets.get(prefix), field);
                }

            } else if ('name'.equalsIgnoreCase(virtualFieldName)) {
                addToFieldSet(fieldSets.get(CHANGE_ORDER_ENTITLEMENT_KEYWORD), NAME_FIELDS.get(CHANGE_ORDER_ENTITLEMENT_KEYWORD));
                addToFieldSet(fieldSets.get(CHANGE_ORDER_QUOTELINEITEM_KEYWORD), NAME_FIELDS.get(CHANGE_ORDER_QUOTELINEITEM_KEYWORD));

            } else if ('chargeTerm'.equalsIgnoreCase(virtualFieldName)) {
                addToFieldSet(fieldSets.get(CHANGE_ORDER_ENTITLEMENT_KEYWORD), CHARGE_TERM_FIELDS.get(CHANGE_ORDER_ENTITLEMENT_KEYWORD));
                addToFieldSet(fieldSets.get(CHANGE_ORDER_QUOTELINEITEM_KEYWORD), CHARGE_TERM_FIELDS.get(CHANGE_ORDER_QUOTELINEITEM_KEYWORD));

            } else if ('quantity'.equalsIgnoreCase(virtualFieldName)) {
                addToFieldSet(fieldSets.get(CHANGE_ORDER_ENTITLEMENT_KEYWORD), CHANGE_QUANTITY_FIELDS.get(CHANGE_ORDER_ENTITLEMENT_KEYWORD));
                addToFieldSet(fieldSets.get(CHANGE_ORDER_QUOTELINEITEM_KEYWORD), CHANGE_QUANTITY_FIELDS.get(CHANGE_ORDER_QUOTELINEITEM_KEYWORD));

            } else if ('changeMonthlySubtotal'.equalsIgnoreCase(prefix)) {
                addToFieldSet(fieldSets.get(CHANGE_ORDER_ENTITLEMENT_KEYWORD), CHANGE_MONTHLY_SUBTOTAL_FIELDS.get(CHANGE_ORDER_ENTITLEMENT_KEYWORD));
                addToFieldSet(fieldSets.get(CHANGE_ORDER_QUOTELINEITEM_KEYWORD), CHANGE_MONTHLY_SUBTOTAL_FIELDS.get(CHANGE_ORDER_QUOTELINEITEM_KEYWORD));

            } else if ('changeAnnualSubtotal'.equalsIgnoreCase(prefix)) {
                addToFieldSet(fieldSets.get(CHANGE_ORDER_ENTITLEMENT_KEYWORD), CHANGE_ANNUAL_SUBTOTAL_FIELDS.get(CHANGE_ORDER_ENTITLEMENT_KEYWORD));
                addToFieldSet(fieldSets.get(CHANGE_ORDER_QUOTELINEITEM_KEYWORD), CHANGE_ANNUAL_SUBTOTAL_FIELDS.get(CHANGE_ORDER_QUOTELINEITEM_KEYWORD));

            } else if ('changeOneTimeSubtotal'.equalsIgnoreCase(prefix)) {
                addToFieldSet(fieldSets.get(CHANGE_ORDER_ENTITLEMENT_KEYWORD), CHANGE_ONE_TIME_SUBTOTAL_FIELDS.get(CHANGE_ORDER_ENTITLEMENT_KEYWORD));
                addToFieldSet(fieldSets.get(CHANGE_ORDER_QUOTELINEITEM_KEYWORD), CHANGE_ONE_TIME_SUBTOTAL_FIELDS.get(CHANGE_ORDER_QUOTELINEITEM_KEYWORD));

            } else if ('summChangeMonthlySubtotal'.equalsIgnoreCase(prefix)) {
                addToFieldSet(fieldSets.get(CHANGE_ORDER_ENTITLEMENT_KEYWORD), SUMM_CHANGE_MONTHLY_SUBTOTAL_FIELDS.get(CHANGE_ORDER_ENTITLEMENT_KEYWORD));
                addToFieldSet(fieldSets.get(CHANGE_ORDER_QUOTELINEITEM_KEYWORD), SUMM_CHANGE_MONTHLY_SUBTOTAL_FIELDS.get(CHANGE_ORDER_QUOTELINEITEM_KEYWORD));

            } else if ('summChangeAnnualSubtotal'.equalsIgnoreCase(prefix)) {
                addToFieldSet(fieldSets.get(CHANGE_ORDER_ENTITLEMENT_KEYWORD), SUMM_CHANGE_ANNUAL_SUBTOTAL_FIELDS.get(CHANGE_ORDER_ENTITLEMENT_KEYWORD));
                addToFieldSet(fieldSets.get(CHANGE_ORDER_QUOTELINEITEM_KEYWORD), SUMM_CHANGE_ANNUAL_SUBTOTAL_FIELDS.get(CHANGE_ORDER_QUOTELINEITEM_KEYWORD));

            } else if ('summChangeOneTimeSubtotal'.equalsIgnoreCase(prefix)) {
                addToFieldSet(fieldSets.get(CHANGE_ORDER_ENTITLEMENT_KEYWORD), SUMM_CHANGE_ONE_TIME_SUBTOTAL_FIELDS.get(CHANGE_ORDER_ENTITLEMENT_KEYWORD));
                addToFieldSet(fieldSets.get(CHANGE_ORDER_QUOTELINEITEM_KEYWORD), SUMM_CHANGE_ONE_TIME_SUBTOTAL_FIELDS.get(CHANGE_ORDER_QUOTELINEITEM_KEYWORD));

            }
        }

        public Object getRealData(String changeOrderfield, Map<String, DataItem> dataItemsMap, DataItem dataItemObj, Integer loopItemIndex) {
            Object realData = '';
            Matcher prefixDotNotationMatcher = Pattern.compile(PREFIX_DOT_NOTATION_PATTERN).matcher(changeOrderfield);
            Boolean isSObjectReference = false;
            String prefix = null;
            String field = null;
            VirtualField vf = new VirtualField();
            Map<String,Set<String>> fieldsSetsCaseInsensitive = new Map<String,Set<String>>();
            if (dataItemObj.fieldsSets != null) {
                for (String key: dataItemObj.fieldsSets.keySet()) {
                    fieldsSetsCaseInsensitive.put(key.toLowerCase(), dataItemObj.fieldsSets.get(key));
                }
            }
            while (prefixDotNotationMatcher.find()) {
                // #qli#.#Quantity.Name#
                prefix = prefixDotNotationMatcher.group(1);
                field = prefixDotNotationMatcher.group(2);

                isSObjectReference = fieldsSetsCaseInsensitive.keySet().contains(prefix.toLowerCase());
            }

            ChangeOrderItem coi = (dataItemObj != null && dataItemObj.dataList != null && loopItemIndex != null)
                ? (ChangeOrderItem) dataItemObj.dataList.get(loopItemIndex)
                : new ChangeOrderItem();

            if (isSObjectReference) {
                if (prefix == CHANGE_ORDER_QUOTELINEITEM_KEYWORD) {

                    if (coi.QuoteLineItem != null) {
                        if (isVirtual(field)) {

                            if ('quantity'.equalsIgnoreCase(cleanVirtualString(field))) {
                                realData = vf.quantity(coi.QuoteLineItem);

                            } else if ('newSubtotal'.equalsIgnoreCase(cleanVirtualString(field))) {
                                realData = vf.newSubtotal(coi.QuoteLineItem);

                            } else if ('newRate'.equalsIgnoreCase(cleanVirtualString(field))) {
                                realData = vf.newRate(coi.QuoteLineItem);

                            }

                        } else {
                            realData = SFDescribeHelper.getSObjectField(coi.QuoteLineItem, field);
                        }
                    }

                } else if (prefix == CHANGE_ORDER_ENTITLEMENT_KEYWORD) {
                    if (coi.Entitlement != null) {
                        if (isVirtual(field)) {
                            if ('currentSubtotal'.equalsIgnoreCase(cleanVirtualString(field))) {
                                realData = vf.currentSubtotal(coi.Entitlement);

                            }

                        } else {
                            realData = SFDescribeHelper.getSObjectField(coi.Entitlement, field);
                        }
                    }
                }

            } else if ('name'.equalsIgnoreCase(prefix)) {
                realData = name(coi);

            } else if ('chargeTerm'.equalsIgnoreCase(prefix)) {
                realData = chargeTerm(coi);

            } else if ('changeQuantity'.equalsIgnoreCase(prefix)) {
                realData = changeQuantity(coi);

            } else if ('changeMonthlySubtotal'.equalsIgnoreCase(prefix)) {
                realData = changeMonthlySubtotal(coi);

            } else if ('changeAnnualSubtotal'.equalsIgnoreCase(prefix)) {
                realData = changeAnnualSubtotal(coi);

            } else if ('changeOneTimeSubtotal'.equalsIgnoreCase(prefix)) {
                realData = changeOneTimeSubtotal(coi, false);

            } else if ('summChangeMonthlySubtotal'.equalsIgnoreCase(prefix)) {
                realData = summChangeMonthlySubtotal(dataItemObj);

            } else if ('summChangeAnnualSubtotal'.equalsIgnoreCase(prefix)) {
                realData = summChangeAnnualSubtotal(dataItemObj);

            } else if ('summChangeOneTimeSubtotal'.equalsIgnoreCase(prefix)) {
                realData = summChangeOneTimeSubtotal(dataItemObj, false);

            } else if ('dependentOnFeature'.equalsIgnoreCase(prefix)) {
                realData = changeOrderDependentOnFeature(coi, field, dataItemsMap, dataItemObj, loopItemIndex);

            } else if ('size'.equalsIgnoreCase(prefix)) {
                realData = dataItemObj.dataList.size();

            } else if ('hierarchyLevel'.equalsIgnoreCase(prefix)) {
                realData = hierarchyLevelChangeOrder(coi);

            } else if ('existingServicesTotal'.equalsIgnoreCase(prefix)) {
                realData = existingServicesTotal(dataItemObj);

            } else if ('newServicesTotal'.equalsIgnoreCase(prefix)) {
                realData = newServicesTotal(dataItemObj);

            } else if ('newAndExistingServicesTotal'.equalsIgnoreCase(prefix)) {
                realData = newAndExistingServicesTotal(dataItemObj);

            } else if ('changeOrderHierarchyTotal'.equalsIgnoreCase(prefix)) {
                realData = changeOrderHierarchyTotal(dataItemObj);

            } else if ('changeOrderHierarchySubtotal'.equalsIgnoreCase(prefix)) {
                realData = changeOrderHierarchySubtotal(coi);

            }

            return realData;
        }

        public List<ChangeOrderItem> filterOutNotChanged(List<ChangeOrderItem> dataList) {

            List<ChangeOrderItem> filteredList = new List<ChangeOrderItem>();
            for(ChangeOrderItem coi : dataList) {
                Boolean isChanged = coi.QuoteLineItem == null || coi.Entitlement == null ||
                    (Decimal.valueOf(String.valueOf(changeQuantity(coi))) != 0
                        || (QuoteLineItemHelper.getDiscountValue(coi.QuoteLineItem) != EntitlementHelper.getDiscountValue(coi.Entitlement))
                    );

                if (isChanged){
                    filteredList.add(coi);
                }
            }

            return filteredList;
        }

        public Map<String, Set<String>> NAME_FIELDS = new Map<String, Set<String>>{
            BASE_OBJECT_KEYWORD => new Set<String>{
                ''
            },
            CHANGE_ORDER_QUOTELINEITEM_KEYWORD => new Set<String>{
                'Product2.Name'
            },
            CHANGE_ORDER_ENTITLEMENT_KEYWORD => new Set<String>{
                'Product__r.Name'
            }
        };
        public Object name(ChangeOrderItem coi) {
            Object result = '';

            if (coi.QuoteLineItem != null){
                result = SFDescribeHelper.getSObjectField(coi.QuoteLineItem, 'Product2.Name');

            } else if (coi.Entitlement != null){
                result = SFDescribeHelper.getSObjectField(coi.Entitlement, 'Product__r.Name');

            }

            return result;
        }

        public Map<String, Set<String>> CHARGE_TERM_FIELDS = new Map<String, Set<String>>{
            BASE_OBJECT_KEYWORD => new Set<String>{
                ''
            },
            CHANGE_ORDER_QUOTELINEITEM_KEYWORD => new Set<String>{
                'Product2.Charge_Term__c', 'QuoteRecordType__c', 'Quote.RecordTypeId', 'PackageInfo__c', 'Package_Info_QLI__c', 'Package_Info__c'
            },
            CHANGE_ORDER_ENTITLEMENT_KEYWORD => new Set<String>{
                'Product__r.Charge_Term__c', 'ChargeTerm__c'
            }
        };
        public String chargeTerm(ChangeOrderItem coi) {
            String result = '';

            if (coi.QuoteLineItem != null) {
                result = QuoteLineItemHelper.getChargeTerm(coi.QuoteLineItem);

            } else if (coi.Entitlement != null) {
                result = EntitlementHelper.getChargeTerm(coi.Entitlement);
            }

            return result;
        }

        public Map<String, Set<String>> SUBTOTAL_FIELDS = new Map<String, Set<String>>{
            BASE_OBJECT_KEYWORD => new Set<String>{
                ''
            },
            CHANGE_ORDER_QUOTELINEITEM_KEYWORD => new Set<String>{
                'Product2.Charge_Term__c', 'NewQuantity__c', 'EffectivePrice__c', 'QuoteRecordType__c', 'Package_Info__c',
                'Quote.RecordTypeId', 'PackageInfo__c', 'EffectivePriceNew__c', 'Product2.Family', 'Package_Info_QLI__c'
            },
            CHANGE_ORDER_ENTITLEMENT_KEYWORD => new Set<String>{
                'Product__r.Charge_Term__c', 'DisplayQuantity__c', 'EffectivePrice__c', 'EffectivePricePrecise__c'
            }
        };
        public Object subtotal(ChangeOrderItem coi) {
            VirtualField vf = new VirtualField();

            Decimal newSubtotal = 0;
            if (coi.QuoteLineItem != null) {
                newSubtotal = Decimal.valueOf(String.valueOf(vf.newSubtotal(coi.QuoteLineItem)));
            }

            Decimal currentSubtotal = 0;
            if (coi.Entitlement != null) {
                currentSubtotal = Decimal.valueOf(String.valueOf(vf.currentSubtotal(coi.Entitlement)));
            }

            Decimal result = newSubtotal - currentSubtotal;

            return String.valueOf(result);
        }

        public Map<String, Set<String>> CHANGE_MONTHLY_SUBTOTAL_FIELDS = new Map<String, Set<String>>{
            BASE_OBJECT_KEYWORD => new Set<String>{
                ''
            },
            CHANGE_ORDER_QUOTELINEITEM_KEYWORD => new Set<String> {
                'Product2.Charge_Term__c', 'NewQuantity__c', 'EffectivePrice__c',  'QuoteRecordType__c',
                'Quote.RecordTypeId', 'PackageInfo__c', 'EffectivePriceNew__c', 'Package_Info_QLI__c', 'Package_Info__c'
            },
            CHANGE_ORDER_ENTITLEMENT_KEYWORD => new Set<String> {
                'Product__r.Charge_Term__c', 'DisplayQuantity__c', 'EffectivePrice__c', 'EffectivePricePrecise__c', 'ChargeTerm__c'
            }
        };
        public Object changeMonthlySubtotal(ChangeOrderItem coi) {

            Decimal result = 0;
            String chargeTerm = chargeTerm(coi);
            if (chargeTerm == Product2Helper.CHARGE_TERM_ANNUAL) {
                Decimal subtotal = Decimal.valueOf(String.valueOf(subtotal(coi)));
                result = subtotal / 12;
            }

            if (chargeTerm == Product2Helper.CHARGE_TERM_MONTHLY
                || chargeTerm == Product2Helper.CHARGE_TERM_MONTHLY_CONTRACT) {
                Decimal subtotal = Decimal.valueOf(String.valueOf(subtotal(coi)));
                result = subtotal;
            }

            return String.valueOf(result);
        }

        public Map<String, Set<String>> CHANGE_ANNUAL_SUBTOTAL_FIELDS = new Map<String, Set<String>>{
            BASE_OBJECT_KEYWORD => new Set<String>{
                ''
            },
            CHANGE_ORDER_QUOTELINEITEM_KEYWORD => new Set<String>{
                'Product2.Charge_Term__c', 'NewQuantity__c', 'EffectivePrice__c', 'QuoteRecordType__c',
                'Quote.RecordTypeId', 'PackageInfo__c', 'EffectivePriceNew__c', 'Package_Info_QLI__c', 'PAckage_Info__c'
            },
            CHANGE_ORDER_ENTITLEMENT_KEYWORD => new Set<String>{
                'Product__r.Charge_Term__c', 'Quantity__c', 'Price__c', 'DisplayQuantity__c', 'EffectivePricePrecise__c'
            }
        };
        public Object changeAnnualSubtotal(ChangeOrderItem coi) {
            // if qli.product.charge term = monthly || monthly - contract: (new subtotal - current subtotal) * 12,
            // if qli.product.charge term = annual: new subtotal - current subtotal
            Decimal result = 0;
            String chargeTerm = chargeTerm(coi);
            if (chargeTerm == Product2Helper.CHARGE_TERM_ANNUAL) {
                Decimal subtotal = Decimal.valueOf(String.valueOf(subtotal(coi)));
                result = subtotal;
            }

            if (chargeTerm == Product2Helper.CHARGE_TERM_MONTHLY
                || chargeTerm == Product2Helper.CHARGE_TERM_MONTHLY_CONTRACT) {
                Decimal subtotal = Decimal.valueOf(String.valueOf(subtotal(coi)));
                result = subtotal * 12;
            }

            return String.valueOf(result);
        }

        public Map<String, Set<String>> CHANGE_ONE_TIME_SUBTOTAL_FIELDS = new Map<String, Set<String>>{
            BASE_OBJECT_KEYWORD => new Set<String>{
                ''
            },
            CHANGE_ORDER_QUOTELINEITEM_KEYWORD => new Set<String>{
                'Product2.Charge_Term__c', 'NewQuantity__c', 'EffectivePrice__c',  'QuoteRecordType__c',
                'Quote.RecordTypeId', 'PackageInfo__c', 'EffectivePriceNew__c', 'Package_Info_QLI__c', 'Package_Info__c'
            },
            CHANGE_ORDER_ENTITLEMENT_KEYWORD => new Set<String>{
                'Product__r.Charge_Term__c', 'Quantity__c', 'Price__c'
            }
        };
        public Object changeOneTimeSubtotal(ChangeOrderItem coi, Boolean isResellerPrice) {
            VirtualField vf = new VirtualField();
            Decimal result = 0;
            String chargeTerm = chargeTerm(coi);
            if (chargeTerm == Product2Helper.CHARGE_TERM_ONE_TIME && coi.QuoteLineItem != null) {
                result = Decimal.valueOf(String.valueOf(vf.newSubtotal(coi.QuoteLineItem)));
            }

            return String.valueOf(result);
        }

        public Map<String, Set<String>> SUMM_CHANGE_MONTHLY_SUBTOTAL_FIELDS = new Map<String, Set<String>>{
            BASE_OBJECT_KEYWORD => new Set<String>{
                ''
            },
            CHANGE_ORDER_QUOTELINEITEM_KEYWORD => new Set<String> (
                CHANGE_MONTHLY_SUBTOTAL_FIELDS.get(CHANGE_ORDER_QUOTELINEITEM_KEYWORD)
            ),
            CHANGE_ORDER_ENTITLEMENT_KEYWORD => new Set<String> (
                CHANGE_MONTHLY_SUBTOTAL_FIELDS.get(CHANGE_ORDER_ENTITLEMENT_KEYWORD)
            )
        };
        public Object summChangeMonthlySubtotal(DataItem d) {
            Decimal result = 0;

            for (Object coi : d.dataList){
                result += Decimal.valueOf(String.valueOf(changeMonthlySubtotal((ChangeOrderItem) coi)));
            }

            return String.valueOf(result);
        }

        public Map<String, Set<String>> SUMM_CHANGE_ANNUAL_SUBTOTAL_FIELDS = new Map<String, Set<String>>{
            BASE_OBJECT_KEYWORD => new Set<String>{
                ''
            },
            CHANGE_ORDER_QUOTELINEITEM_KEYWORD => new Set<String> (
                CHANGE_ANNUAL_SUBTOTAL_FIELDS.get(CHANGE_ORDER_QUOTELINEITEM_KEYWORD)
            ),
            CHANGE_ORDER_ENTITLEMENT_KEYWORD => new Set<String> (
                CHANGE_ANNUAL_SUBTOTAL_FIELDS.get(CHANGE_ORDER_ENTITLEMENT_KEYWORD)
            )
        };
        public Object summChangeAnnualSubtotal(DataItem d) {
            Decimal result = 0;

            for (Object coi : d.dataList) {
                result += Decimal.valueOf(String.valueOf(changeAnnualSubtotal((ChangeOrderItem) coi)));
            }

            return String.valueOf(result);
        }

        public Map<String, Set<String>> SUMM_CHANGE_ONE_TIME_SUBTOTAL_FIELDS = new Map<String, Set<String>>{
            BASE_OBJECT_KEYWORD => new Set<String>{
                ''
            },
            CHANGE_ORDER_QUOTELINEITEM_KEYWORD => new Set<String> (
                CHANGE_ONE_TIME_SUBTOTAL_FIELDS.get(CHANGE_ORDER_QUOTELINEITEM_KEYWORD)
            ),
            CHANGE_ORDER_ENTITLEMENT_KEYWORD => new Set<String> (
                CHANGE_ONE_TIME_SUBTOTAL_FIELDS.get(CHANGE_ORDER_ENTITLEMENT_KEYWORD)
            )
        };
        public Object summChangeOneTimeSubtotal(DataItem d, Boolean isResellerPrice) {
            Decimal result = 0;

            for (Object coi : d.dataList) {
                result += Decimal.valueOf(String.valueOf(changeOneTimeSubtotal((ChangeOrderItem) coi, isResellerPrice)));
            }

            return String.valueOf(result);
        }


        public Map<String, Set<String>> CHANGE_QUANTITY_FIELDS = new Map<String, Set<String>>{
            BASE_OBJECT_KEYWORD => new Set<String>{
                ''
            },
            CHANGE_ORDER_QUOTELINEITEM_KEYWORD => new Set<String> {
                'Quantity', 'Zero_Quantity__c'
            },
            CHANGE_ORDER_ENTITLEMENT_KEYWORD => new Set<String> {
                'Quantity__c'
            }
        };
        public Object changeQuantity(ChangeOrderItem coi) {
            VirtualField vf = new VirtualField();

            Decimal result = 0;
            if (coi.QuoteLineItem != null) {
                result = coi.Entitlement != null ?
                    QuoteLineItemHelper.getQuantity(coi.QuoteLineItem) :
                    coi.QuoteLineItem.NewQuantity__c;

            } else if (coi.Entitlement != null) {
                result = -coi.Entitlement.Quantity__c;

            }

            return String.valueOf(result);
        }

        public Map<String, Set<String>> DEPENDENT_ON_FEATURE_FIELDS = new Map<String, Set<String>>{
            BASE_OBJECT_KEYWORD => new Set<String>{
                ''
            },
            CHANGE_ORDER_QUOTELINEITEM_KEYWORD => new Set<String> {
                'Product2.Dependent_on_Feature__c', 'Product2.Feature__c'
            },
            CHANGE_ORDER_ENTITLEMENT_KEYWORD => new Set<String> {
                'Product__r.Dependent_on_Feature__c', 'Product__r.Feature__c'
            }
        };
        public Object changeOrderDependentOnFeature(
            ChangeOrderItem coi,
            String changeOrderfield,
            Map<String, DataItem> dataItemsMap,
            DataItem dataItemObj,
            Integer loopItemIndex) {

            Decimal feature = coi.QuoteLineItem != null ?
                coi.QuoteLineItem.Product2.Dependent_on_Feature__c :
                coi.Entitlement.Product__r.Dependent_on_Feature__c;
            if (feature == null) {
                return '';
            }
            Integer targetIndex = null;
            Integer i = 0;
            for (ChangeOrderItem c : (List<ChangeOrderItem>) dataItemObj.dataList) {
                Decimal dFeature = c.QuoteLineItem != null ?
                    c.QuoteLineItem.Product2.Feature__c :
                    c.Entitlement.Product__r.Feature__c;
                if (feature == dFeature) {
                    targetIndex = i;
                    break;
                }
                i++;
            }
            Object result = '';
            if (targetIndex != null) {
                result = getRealData(cleanVirtualString(changeOrderfield), dataItemsMap, dataItemObj, targetIndex);
            }
            return result;
        }

        public String hierarchyLevelChangeOrder(ChangeOrderItem coi) {
            Integer level = 0;
            if (coi.quoteLineItem != null) {
                level = qliIdToHierarchyLevelChangeOrder.get(coi.quoteLineItem.Id);
            } else if (coi.entitlement != null) {
                level = entIdToHierarchyLevelChangeOrder.get(coi.entitlement.Id);
            }

            return String.valueOf(level == null ? 0 : level);
        }

        public String existingServicesTotal(DataItem dataItemObj) {
            Decimal total = 0;
            for (ChangeOrderItem coi : (List<ChangeOrderItem>) dataItemObj.dataList) {
                if (coi.entitlement != null && (entIdToHierarchyLevelChangeOrder.get(coi.entitlement.Id) == 0 || coi.entitlement.Id == null)) {
                    total += coi.entitlement.Price__c * coi.entitlement.Quantity__c;
                }
            }

            return String.valueOf(total);
        }

        public String newServicesTotal(DataItem dataItemObj) {

            Decimal total = 0;
            for (ChangeOrderItem coi : (List<ChangeOrderItem>) dataItemObj.dataList) {
                if (coi.quoteLineItem != null && (qliIdToHierarchyLevelChangeOrder.get(coi.quoteLineItem.Id) == 0 || coi.quoteLineItem.Id == null)) {
                    total += coi.quoteLineItem.EffectivePriceNew__c * coi.quoteLineItem.NewQuantity__c;
                }
            }

            return String.valueOf(total);
        }

        public String newAndExistingServicesTotal(DataItem dataItemObj) {

            Decimal total = 0;
            for (ChangeOrderItem coi : (List<ChangeOrderItem>) dataItemObj.dataList) {
                if (coi.quoteLineItem != null && (qliIdToHierarchyLevelChangeOrder.get(coi.quoteLineItem.Id) == 0 || coi.quoteLineItem.Id == null)) {
                    total += coi.quoteLineItem.EffectivePriceNew__c * coi.quoteLineItem.NewQuantity__c;
                }
            }

            return String.valueOf(total);
        }

        public String changeOrderHierarchyTotal(DataItem dataItemObj) {
            Decimal total = 0;

            for (ChangeOrderItem coi : (List<ChangeOrderItem>) dataItemObj.dataList) {
                if (coi.quoteLineItem != null && (qliIdToHierarchyLevelChangeOrder.get(coi.quoteLineItem.Id) == 0 || coi.quoteLineItem.Id == null)) {
                    total += coi.quoteLineItem.EffectivePriceNew__c * Integer.valueOf(changeQuantity(coi));
                } else if (coi.entitlement != null && (entIdToHierarchyLevelChangeOrder.get(coi.entitlement.Id) != null && entIdToHierarchyLevelChangeOrder.get(coi.entitlement.Id) == 0 || coi.entitlement.Id == null)) {
                    total += Decimal.valueOf(changeOrderHierarchySubtotal(coi));
                }
            }

            return String.valueOf(total);
        }

        public String changeOrderHierarchySubtotal(ChangeOrderItem coi) {
            Decimal subtotal = 0;

            if (coi.entitlement != null) {
                String entitlementChargeTerm = EntitlementHelper.getChargeTerm(coi.entitlement);
                subtotal = coi.entitlement.Price__c * Integer.valueOf(changeQuantity(coi));

                if (entitlementChargeTerm != coi.entitlement.Quote__r.Payment_Plan__c) {
                    if (entitlementChargeTerm == Product2Helper.CHARGE_TERM_ANNUAL) {
                        subtotal /= 12;
                    } else {
                        subtotal *= 12;
                    }
                }
            }

            return String.valueOf(subtotal);
        }
    }

    public class VirtualField {
        /**
         *
         *
         * @param virtualFieldPrefix
         * @param virtualFieldName
         * @param data
         * @param dataItem
         * @param loopIndex
         * @param parameters
         *
         * @return
         */
        public Object replaceVirtualField(String virtualFieldPrefix,
            String virtualFieldName,
            Map<String, DataItem> data,
            DataItem dataItem,
            Integer loopIndex,
            Map<String, String> parameters,
            Id parentObjId) {
            Object realData = null;
            VirtualField vf = new VirtualField();

            sObject dataObj = (sObject) (loopIndex != null ? dataItem.dataList.get(loopIndex) : dataItem.data);
            sObject baseObj = data.get(BASE_OBJECT_KEYWORD).data;
            List<sObject> dataList = (List<sObject>) dataItem.dataList;

            String refFrom = dataItem.objectName;
            String refTo = determinedObjectById(parentObjId);
            String relationShipField = refTo != null && refFrom != null ? getRefFromTo(refFrom, refTo) : null;

            Matcher prefixDotNotationMatcher = Pattern.compile(PREFIX_DOT_NOTATION_PATTERN).matcher(virtualFieldName);
            String prefix = '';
            String field = '';
            while (prefixDotNotationMatcher.find()) {
                // #qli#.#Quantity.Name#
                prefix = prefixDotNotationMatcher.group(1);
                field = prefixDotNotationMatcher.group(2);
            }
            // $#prefix#
            if ('BillingContact'.equalsIgnoreCase(virtualFieldPrefix)
                || 'SignatoryContact'.equalsIgnoreCase(virtualFieldPrefix)
                || 'EngageLegalApproval'.equalsIgnoreCase(virtualFieldPrefix)
                || 'PartnerAccountsPayableContact'.equalsIgnoreCase(virtualFieldPrefix)
                || 'Signature'.equalsIgnoreCase(virtualFieldPrefix)
                || 'KYCApproval'.equalsIgnoreCase(virtualFieldPrefix)
                || 'TechnicalQuoteEV'.equalsIgnoreCase(virtualFieldPrefix)
                ) {
                realData = (dataObj != null) ? SFDescribeHelper.getSObjectField(dataObj, virtualFieldName) : '';

            } else  if ('LocalSubscribedAddress'.equalsIgnoreCase(virtualFieldPrefix)) {
                realData = (dataObj != null) ? SFDescribeHelper.getSObjectField(dataObj, virtualFieldName) : '';

            } else if ('Params'.equalsIgnoreCase(virtualFieldPrefix)) {
                realData = vf.getTemplateParameter(virtualFieldName, parameters);

            } else if ('resource'.equalsIgnoreCase(virtualFieldPrefix)) {
                realData = vf.resource(virtualFieldName);

            } else if ('baseUrl'.equalsIgnoreCase(virtualFieldPrefix)) {
                realData = vf.baseUrl();

            } else if ('today'.equalsIgnoreCase(virtualFieldPrefix)) {
                realData = vf.today();

            } else if ('isProServEngaged'.equalsIgnoreCase(virtualFieldPrefix)) {
                realData = vf.isProServEngaged(baseObj);

            } else if ('approvedBICountry'.equalsIgnoreCase(virtualFieldPrefix)) {
                realData = vf.getApprovedBICountry(baseObj);

            } else if ('oldPackageName'.equalsIgnoreCase(virtualFieldPrefix)) {
                realData = vf.getOldPackageName(baseObj);

            } else if ('newPackageName'.equalsIgnoreCase(virtualFieldPrefix)) {
                realData = vf.getNewPackageName(baseObj);

            } else if ('selectedPackageId'.equalsIgnoreCase(virtualFieldPrefix)) {
                realData = vf.getSelectedPackageId(baseObj);

            } else if ('engageVoicePackageIds'.equalsIgnoreCase(virtualFieldPrefix)) {
                realData = vf.getEngageVoicePackageIds(baseObj);

            } else if ('isTargetPriceAvailable'.equalsIgnoreCase(virtualFieldPrefix)) {
                realData = vf.isTargetPriceAvailable();

            } else if ('isCCTerminated'.equalsIgnoreCase(virtualFieldPrefix)) {
                realData = vf.isCCTerminated(baseObj);

            } else if ('isEngDTerminated'.equalsIgnoreCase(virtualFieldPrefix)) {
                realData = vf.isEngDTerminated(baseObj);

            } else if ('isEngVTerminated'.equalsIgnoreCase(virtualFieldPrefix)) {
                realData = vf.isEngVTerminated(baseObj);

            } else if ('isWholesaleEntitlement'.equalsIgnoreCase(virtualFieldPrefix)) {
                realData = vf.isWholesaleEntitlement(baseObj);

            } else if ('isInitialTermNotChanged'.equalsIgnoreCase(virtualFieldPrefix)) {
                realData = vf.isTermNotChanged(baseObj, 'Initial');

            } else if ('isRenewalTermNotChanged'.equalsIgnoreCase(virtualFieldPrefix)) {
                realData = vf.isTermNotChanged(baseObj, 'Renewal');

            } else if ('isInitialAndRenewalTermsNotChanged'.equalsIgnoreCase(virtualFieldPrefix)) {
                Object isInitialTermNotChanged = vf.isTermNotChanged(baseObj, 'Initial');
                Object isRenewalTermNotChanged = vf.isTermNotChanged(baseObj, 'Renewal');
                realData = vf.isInitialAndRenewalTermsNotChanged(isInitialTermNotChanged, isRenewalTermNotChanged);

            } else {

                // $prefix.#FieldName#
                if ('RatePerMonth'.equalsIgnoreCase(prefix)) {
                    realData = vf.ratePerMonth(dataObj);

                } else if ('RatePerYear'.equalsIgnoreCase(prefix)) {
                    realData = vf.ratePerYear(dataObj);

                } else if ('Subtotal'.equalsIgnoreCase(prefix)) {
                    realData = vf.subtotal(dataObj, baseObj);

                } else if ('resellerPrice'.equalsIgnoreCase(prefix)) {
                    realData = vf.resellerPrice(dataObj);

                } else if ('entResellerPrice'.equalsIgnoreCase(prefix)) {
                    realData = vf.entResellerPrice(dataObj);

                } else if ('initialCostCenterLineItemSubTotal'.equalsIgnoreCase(prefix)) {
                    realData = vf.initialCostCenterLineItemSubTotal(dataObj);

                } else if ('initialSubTotal'.equalsIgnoreCase(prefix)) {
                    realData = vf.initialSubTotal(dataObj);

                } else if ('totalinitialCostCenterLineItemSubTotal'.equalsIgnoreCase(prefix)) {
                    realData = vf.totalinitialCostCenterLineItemSubTotal(dataList, relationShipField, parentObjId);

                } else if ('totalInitialSubTotal'.equalsIgnoreCase(prefix)) {
                    realData = vf.totalInitialSubTotal(dataList, relationShipField, parentObjId);

                } else if ('costCenterTotal'.equalsIgnoreCase(prefix)) {
                    realData = vf.costCenterTotal(dataObj);

                } else if ('totalByCostCenters'.equalsIgnoreCase(prefix)) {
                    realData = vf.totalByCostCenters(dataList, relationShipField, parentObjId);

                } else if ('SubtotalConsideringChargeTerm'.equalsIgnoreCase(prefix)) {
                    realData = vf.subtotalConsideringChargeTerm(dataObj, baseObj);

                } else if ('TotalMonthlyAmount'.equalsIgnoreCase(prefix)) {
                    realData = vf.totalMonthlyAmount(dataList);

                } else if ('TotalInitialAmount'.equalsIgnoreCase(prefix)) {
                    realData = vf.totalInitialAmount(dataList, baseObj);

                } else if ('TotalFirstYearAmount'.equalsIgnoreCase(prefix)) {
                    realData = vf.totalFirstYearAmount(dataList);

                } else if ('ServicePlanRatePerMonth'.equalsIgnoreCase(prefix)) {
                    realData = vf.servicePlanRatePerMonth(dataObj, baseObj);

                } else if ('ServicePlanRatePerYear'.equalsIgnoreCase(prefix)) {
                    realData = vf.servicePlanRatePerYear(dataObj, baseObj);

                } else if ('entitlementTotal'.equalsIgnoreCase(prefix)) {
                    realData = vf.entitlementTotal(dataObj, baseObj, vf.entitlementChargeTerm(dataList, baseObj));

                } else if ('summEntitlementTotal'.equalsIgnoreCase(prefix)) {
                    realData = vf.summEntitlementTotal(dataList, baseObj);

                } else if ('summEntitlementAnnualTotal'.equalsIgnoreCase(prefix)) {
                    realData = vf.summEntitlementAnnualTotal(dataList, baseObj);

                } else if ('summEntitlementMonthlyTotal'.equalsIgnoreCase(prefix)) {
                    realData = vf.summEntitlementMonthlyTotal(dataList, baseObj);

                } else if ('entitlementChargeTerm'.equalsIgnoreCase(prefix)) {
                    realData = vf.entitlementChargeTerm(dataList, baseObj);

                } else if ('isTaxesInCart'.equalsIgnoreCase(prefix)) {
                    realData = vf.isTaxesInCart(dataList);

                } else if ('newProposalTotal'.equalsIgnoreCase(prefix)) {
                    realData = vf.newProposalTotal(dataObj, baseObj);

                } else if ('overallOneTimePayment'.equalsIgnoreCase(prefix)) {
                    realData = vf.overallOneTimePayment(dataList, baseObj);

                }  else if ('overallOneTimeResellerPrice'.equalsIgnoreCase(prefix)) {
                    realData = vf.overallOneTimeResellerPrice(dataList);

                } else if ('overallOneTimePaymentWithTaxes'.equalsIgnoreCase(prefix)) {
                    realData = vf.overallOneTimePaymentWithTaxes(dataList, baseObj);

                } else if ('overallTaxesPayment'.equalsIgnoreCase(prefix)) {
                    realData = vf.overallTaxesPayment(dataList, baseObj);

                } else if ('totalAnnualAmount'.equalsIgnoreCase(prefix)) {
                    realData = vf.totalAnnualAmount(dataList, baseObj);

                } else if ('overallNewProposalTotalPrice'.equalsIgnoreCase(prefix)) {
                    realData = vf.overallNewProposalTotalPrice(dataList, baseObj);

                } else if ('overallNewProposalTotalPriceWithTaxes'.equalsIgnoreCase(prefix)) {
                    realData = vf.overallNewProposalTotalPriceWithTaxes(dataList, baseObj);

                } else if ('overallNewProposalTotalAnnualPrice'.equalsIgnoreCase(prefix)) {
                    realData = vf.overallNewProposalTotalAnnualPrice(dataList, baseObj);

                } else if ('overallNewProposalTotalMonthlyPrice'.equalsIgnoreCase(prefix)) {
                    realData = vf.overallNewProposalTotalMonthlyPrice(dataList, baseObj);

                } else if ('overallTotal12MonthAmount'.equalsIgnoreCase(prefix)) {
                    realData = vf.overallTotal12MonthAmount(dataList, baseObj);

                } else if ('DLsInitiallyPurchased'.equalsIgnoreCase(prefix)) {
                    realData = vf.dlsInitiallyPurchased(dataList);

                } else if ('summNewQuantity'.equalsIgnoreCase(prefix)) {
                    realData = vf.summNewQuantity(dataList);

                } else if ('newProposalChargeTerm'.equalsIgnoreCase(prefix)) {
                    realData = vf.newProposalChargeTerm(dataObj);

                } else if ('currentItemSubtotal'.equalsIgnoreCase(prefix)) {
                    realData = vf.currentItemSubtotal(dataObj);

                } else if ('dependentOnFeature'.equalsIgnoreCase(prefix)) {
                    realData = vf.dependentOnFeature(dataObj, field, dataItem);

                } else if ('size'.equalsIgnoreCase(virtualFieldName)) {
                    realData = dataList.size();

                } else if ('newRaterAnnualSubtotal'.equalsIgnoreCase(virtualFieldName)) {
                    realData = vf.newRaterSubtotal(dataObj, true, false);

                } else if ('newRaterMonthlySubtotal'.equalsIgnoreCase(virtualFieldName)) {
                    realData = vf.newRaterSubtotal(dataObj, false, false);

                } else if ('summNewRaterAnnualSubtotal'.equalsIgnoreCase(virtualFieldName)) {
                    realData = vf.summNewRaterSubtotal(dataList, true, false);

                } else if ('summNewRaterMonthlySubtotal'.equalsIgnoreCase(virtualFieldName)) {
                    realData = vf.summNewRaterSubtotal(dataList, false, false);

                } else if ('entMonthlySubtotal'.equalsIgnoreCase(virtualFieldName)) {
                    realData = vf.entMonthlySubtotal(dataObj, false);

                } else if ('sumEntMonthlySubtotal'.equalsIgnoreCase(virtualFieldName)) {
                    realData = vf.sumEntMonthlySubtotal(dataList, false);

                } else if ('entAnnualSubtotal'.equalsIgnoreCase(virtualFieldName)) {
                    realData = vf.entAnnualSubtotal(dataObj, false);

                } else if ('sumEntAnnualSubtotal'.equalsIgnoreCase(virtualFieldName)) {
                    realData = vf.sumEntAnnualSubtotal(dataList, false);

                }else if ('entResellerPriceMonthlySubtotal'.equalsIgnoreCase(virtualFieldName)) {
                    realData = vf.entMonthlySubtotal(dataObj, true);

                } else if ('sumEntResellerPriceMonthlySubtotal'.equalsIgnoreCase(virtualFieldName)) {
                    realData = vf.sumEntMonthlySubtotal(dataList, true);

                } else if ('entResellerPriceAnnualSubtotal'.equalsIgnoreCase(virtualFieldName)) {
                    realData = vf.entAnnualSubtotal(dataObj, true);

                } else if ('sumEntResellerPriceAnnualSubtotal'.equalsIgnoreCase(virtualFieldName)) {
                    realData = vf.sumEntAnnualSubtotal(dataList, true);

                } else if ('entOneTimeSubtotal'.equalsIgnoreCase(virtualFieldName)) {
                    realData = vf.entOneTimeSubtotal(dataObj, false);

                } else if ('entResellerPriceOneTimeSubtotal'.equalsIgnoreCase(virtualFieldName)) {
                    realData = vf.entOneTimeSubtotal(dataObj, true);

                } else if ('sumEntOneTimeSubtotal'.equalsIgnoreCase(virtualFieldName)) {
                    realData = vf.sumEntOneTimeSubtotal(dataList, false);

                } else if ('sumResellerPriceEntOneTimeSubtotal'.equalsIgnoreCase(virtualFieldName)) {
                    realData = vf.sumEntOneTimeSubtotal(dataList, true);

                } else if ('goaStatus'.equalsIgnoreCase(virtualFieldName)) {
                    realData = vf.goaStatus(dataObj);

                } else if ('hierarchyLevel'.equalsIgnoreCase(virtualFieldName)) {
                    realData = vf.hierarchyLevel(dataObj);

                } else if ('hierarchyTotals'.equalsIgnoreCase(virtualFieldName)) {
                    realData = vf.hierarchyTotals(dataList);

                } else if ('resellerPriceTotals'.equalsIgnoreCase(virtualFieldName)) {
                    realData = vf.resellerPriceTotals(dataList);

                } else if ('newResellerPriceAnnualSubtotal'.equalsIgnoreCase(virtualFieldName)) {
                    realData = vf.newRaterSubtotal(dataObj, true, true);

                } else if ('newResellerPriceMonthlySubtotal'.equalsIgnoreCase(virtualFieldName)) {
                    realData = vf.newRaterSubtotal(dataObj, false, true);

                } else if ('summNewResellerPriceAnnualSubtotal'.equalsIgnoreCase(virtualFieldName)) {
                    realData = vf.summNewRaterSubtotal(dataList, true, true);

                } else if ('summNewResellerPriceMonthlySubtotal'.equalsIgnoreCase(virtualFieldName)) {
                    realData = vf.summNewRaterSubtotal(dataList, false, true);

                } else if ('phaseTotal'.equalsIgnoreCase(virtualFieldName)) {
                    realData = vf.calculatePhaseTotal(dataObj);
                } else if ('phasesGrandTotal'.equalsIgnoreCase(virtualFieldName)) {
                    realData = vf.calculatePhasesGrandTotal(datalist);
                } else if ('phasesUCSubTotal'.equalsIgnoreCase(virtualFieldName)) {
                    realData = vf.calculateUCPhasesSubTotal(datalist);
                } else if ('phasesCCSubTotal'.equalsIgnoreCase(virtualFieldName)) {
                    realData = vf.calculateCCPhasesSubTotal(datalist);
                } else if ('phasesTypes'.equalsIgnoreCase(virtualFieldName)) {
                    realData = vf.getPhasesTypes(datalist);
                }  else if (IS_DEBUG_MODE) {
                    realData = String.format('<span class="system-error">{0} not found </span>', new List<String>{
                        virtualFieldName
                    });
                }
            }

            return realData;
        }

        public Map<String, Set<String>> BILLINGCONTACT_FIELDS = new Map<String, Set<String>>{
            BASE_OBJECT_KEYWORD => new Set<String>{
                'OpportunityId'
            }
        };

        public Map<String, Set<String>> SIGNATORYCONTACT_FIELDS = new Map<String, Set<String>>{
            BASE_OBJECT_KEYWORD => new Set<String>{
                'OpportunityId'
            }
        };

        public Map<String, Set<String>> RESELLERPRICE_FIELDS = new Map<String, Set<String>>{
            LOOP_OBJ_KEYWORD => new Set<String>{
                'ChargeTerm__c', 'Product2.Feature__c', 'Product2.ExtID__c', 'UnitPrice', 'PackageInfo__c', 'NewQuantity__c'
            }
        };

        public Map<String, Set<String>> ENTRESELLERPRICE_FIELDS = new Map<String, Set<String>>{
            LOOP_OBJ_KEYWORD => new Set<String>{
                'Product__r.ExtID__c', 'Price__c'
            }
        };

        public Map<String, Set<String>> ENGAGELEGALAPPROVAL_FIELDS = new Map<String, Set<String>>{
            BASE_OBJECT_KEYWORD => new Set<String>{
                'OpportunityId'
            }
        };

        public Map<String, Set<String>> HIERARCHYTABLE_FIELDS = new Map<String, Set<String>>{
            BASE_OBJECT_KEYWORD => new Set<String>{
                'OpportunityId'
            }
        };

        public Set<String> COSTCENTERLINEITEM_REQUIRED_FIELDS = new Set<String>{'Quantity__c'};

        public Map<String, Set<String>> CHANGE_ORDER_TABLE_FIELDS = new Map<String, Set<String>>{
            BASE_OBJECT_KEYWORD => new Set<String>{
                'opportunity.is_billing_opportunity__c', 'recordtypeid'
            }
        };

        public DataItem getVirtualObjectInfo(String virtualObjectName, Map<String,TemplateEngine.DataItem> data) {
            DataItem dataItem = new DataItem();

            if ('BillingContact'.equalsIgnoreCase(virtualObjectName)) {

                String query = 'SELECT {!fields} FROM Contact WHERE Id IN ' +
                    '(SELECT ContactId ' +
                    'FROM OpportunityContactRole ' +
                    'WHERE OpportunityId = :opportunityId AND Role = \'Billing Contact\') ' +
                    'LIMIT 1';

                dataItem.type = CUSTOM_QUERY_TYPE;
                dataItem.query = query;

            } else if ('SignatoryContact'.equalsIgnoreCase(virtualObjectName)) {

                String query = 'SELECT {!fields} FROM Contact WHERE Id IN ' +
                    '(SELECT ContactId ' +
                    'FROM OpportunityContactRole ' +
                    'WHERE OpportunityId = :opportunityId AND Role = \'' + OpportunityHelper.CONTACT_ROLE_SIGNATORY + '\' ' +
                    'AND IsPrimary = true) ' +
                    'LIMIT 1';

                dataItem.type = CUSTOM_QUERY_TYPE;
                dataItem.query = query;

            }  else if ('LocalSubscribedAddress'.equalsIgnoreCase(virtualObjectName)) {
                String query = 'SELECT {!fields} FROM LocalSubscribedAddress__c WHERE ' +
                    'RecordType.Name = \'Registered Address of Company\' ' +
                    'AND Approval__c = \'latestApprovedApprovalId\' ' +
                    'LIMIT 1';

                dataItem.type = CUSTOM_QUERY_TYPE;
                dataItem.query = query;

            } else if ('SignatoryContact'.equalsIgnoreCase(virtualObjectName)) {

                String query = 'SELECT {!fields} FROM Contact WHERE Id IN ' +
                    '(SELECT ContactId ' +
                    'FROM OpportunityContactRole ' +
                    'WHERE OpportunityId = :opportunityId AND Role = \'' + OpportunityHelper.CONTACT_ROLE_SIGNATORY + '\' ' +
                    'AND IsPrimary = true) ' +
                    'LIMIT 1';

                dataItem.type = CUSTOM_QUERY_TYPE;
                dataItem.query = query;
            } else if ('PartnerAccountsPayableContact'.equalsIgnoreCase(virtualObjectName)) {

                String query = 'SELECT {!fields} FROM Contact WHERE Id IN ' +
                    '(SELECT ContactId ' +
                    'FROM AccountContactRole ' +
                    'WHERE ContactId = \'partnerAPCId\' AND Role = \'' + AccountContactRoleHelper.CONTACT_ROLE_ACCOUNT_PAYABLE + '\') ' +
                    'LIMIT 1';

                dataItem.type = CUSTOM_QUERY_TYPE;
                dataItem.query = query;

            } else if ('Signature'.equalsIgnoreCase(virtualObjectName)) {
                String query = 'SELECT Segment__c, Brand__c, Signature__c, StaticResourceName__c, Title__c, ' +
                    'Email__c, BusinessIdentity__c, Region__c, SubRegion__c FROM Signature_Tags__mdt ' +
                    'ORDER BY Segment__c ASC NULLS LAST';
                dataItem.type = SIGNATURE_TAG_TYPE;
                dataItem.query = query;

            } else if ('EngageLegalApproval'.equalsIgnoreCase(virtualObjectName)) {
                String quoteBrand = data.get(BASE_OBJECT_KEYWORD).brand;
                String query = 'SELECT {!fields} ' +
                    'FROM Approval__c ' +
                    'WHERE Opportunity__c = :opportunityId ' +
                    'AND RecordType.Name = \'' + ApprovalHelper.RT_NAME_ENGAGE_LEGAL + '\' ' +
                    'AND Status__c != \'Rejected\' AND Status__c != \'Recalled\' ' +
                    'AND Status__c != \'Completed Audit\'';

                if (LeadConversionConfiguration__c.getInstance(quoteBrand).Multiple_Engage_Legal_Management_Flow__c) {
                    query += ' AND Send_Special_Terms_To_PDF__c = true';
                } else {
                    query += ' LIMIT 1';
                }

                dataItem.type = CUSTOM_QUERY_TYPE;
                dataItem.query = query;

            } else if ('KYCApproval'.equalsIgnoreCase(virtualObjectName)) {
                String query = 'SELECT {!fields} FROM Approval__c WHERE ' +
                    'Id = \'latestApprovedApprovalId\' ';

                dataItem.type = CUSTOM_QUERY_TYPE;
                dataItem.query = query;

            } else if ('TechnicalQuoteEV'.equalsIgnoreCase(virtualObjectName)) {
                String query = 'SELECT {!fields} FROM Quote WHERE ' +
                    'MasterQuote__c = \'masterQuoteId\' AND ServiceName__c = \'' + QuoteHelper.NGBS_ENGAGE_VOICE_PRODUCT + '\' ';

                dataItem.type = CUSTOM_QUERY_TYPE;
                dataItem.query = query;

            } else if ('Phases'.equalsIgnoreCase(virtualObjectName)) {
                String query = 'SELECT Id, Name, AutoNumberName__c, CurrencyIsoCode, Phase_Number__c, PhaseDescription__c, Phase_Type__c,' +
                    '(SELECT Id, CurrencyIsoCode, Quote_Line_Item__r.EffectivePrice__c, Quantity__c, Total_Price__c, AdditionalQuantity__c, ExistingQuantity__c FROM Hardware_Line_Items__r) ' +
                    'FROM Phase__c WHERE Quote__c = \'masterQuoteId\' ORDER BY Phase_Type__c ASC';

                dataItem.type = CUSTOM_QUERY_TYPE;
                dataItem.query = query;

            } else if ('Params'.equalsIgnoreCase(virtualObjectName)) {

                dataItem.type = NO_QUERY_TYPE;

            } else if ('today'.equalsIgnoreCase(virtualObjectName)) {

                dataItem.type = NO_QUERY_TYPE;

            } else if ('resource'.equalsIgnoreCase(virtualObjectName)) {

                dataItem.type = NO_QUERY_TYPE;

            } else if ('baseUrl'.equalsIgnoreCase(virtualObjectName)) {

                dataItem.type = NO_QUERY_TYPE;

            } else if ('isWholesaleEntitlement'.equalsIgnoreCase(virtualObjectName)) {

                dataItem.type = NO_QUERY_TYPE;

            } else if ('isInitialTermNotChanged'.equalsIgnoreCase(virtualObjectName)) {

                dataItem.type = NO_QUERY_TYPE;

            } else if ('isRenewalTermNotChanged'.equalsIgnoreCase(virtualObjectName)) {

                dataItem.type = NO_QUERY_TYPE;

            } else if ('isInitialAndRenewalTermsNotChanged'.equalsIgnoreCase(virtualObjectName)) {

                dataItem.type = NO_QUERY_TYPE;

            } else if ('taxesAndFeesTable'.equalsIgnoreCase(virtualObjectName)) {
                String query = 'SELECT {!fields}, Product2.ExtID__c ' +
                    ' FROM QuoteLineItem ' +
                    ' WHERE Quote.OpportunityId = :opportunityId AND QuoteId = :baseObjId ';

                dataItem.type = TAXES_AND_FEES_TABLE_TYPE;
                dataItem.queries = new Map<String, String> {CHANGE_ORDER_QUOTELINEITEM_KEYWORD => query};
                dataItem.query = query;
                dataItem.objectName = 'QuoteLineItem';
                dataItem.fields = CHANGE_ORDER_QUOTELINEITEM_DEFAULT_KEYWORDS;

            } else if (
                'changeOrderTable'.equalsIgnoreCase(virtualObjectName)
                    || 'changeOrderTableCC'.equalsIgnoreCase(virtualObjectName)
                ) {

                String qliQueryString = 'SELECT {!fields} FROM QuoteLineItem WHERE QuoteId = :baseObjId';

                if('changeOrderTableCC'.equalsIgnoreCase(virtualObjectName)) {
                    qliQueryString = 'SELECT {!fields} ' +
                        ' FROM QuoteLineItem ' +
                        ' WHERE Quote.OpportunityId = :opportunityId ' +
                        ' AND Quote.RecordTypeId = \'' + QuoteHelper.RT_ID_CC + '\'';
                }

                dataItem.type = CHANGE_ORDER_TYPE;
                dataItem.queries = new Map<String, String> {
                    CHANGE_ORDER_QUOTELINEITEM_KEYWORD => qliQueryString,
                    CHANGE_ORDER_ENTITLEMENT_KEYWORD => 'SELECT {!fields} FROM Entitlement__c WHERE'
                };
                dataItem.fieldsSets = new Map<String, Set<String>>{
                    CHANGE_ORDER_QUOTELINEITEM_KEYWORD => new Set<String>(),
                    CHANGE_ORDER_ENTITLEMENT_KEYWORD => new Set<String>()
                };

                addToFieldSet(
                    dataItem.fieldsSets.get(CHANGE_ORDER_QUOTELINEITEM_KEYWORD),
                    CHANGE_ORDER_QUOTELINEITEM_DEFAULT_KEYWORDS
                );
                addToFieldSet(
                    dataItem.fieldsSets.get(CHANGE_ORDER_ENTITLEMENT_KEYWORD),
                    CHANGE_ORDER_ENTITLEMENT_DEFAULT_KEYWORDS
                );

                String entNgbsQueryStr = ' Quote__c = :baseObjId';

                if('changeOrderTableCC'.equalsIgnoreCase(virtualObjectName)) {
                    entNgbsQueryStr = ' Account__c = :accountId AND Quote__c = null AND Product__r.Sub_Category__c = \'' + Product2Helper.SUBCATEGORY_CONTACT_CENTER + '\'';
                }

                dataItem.whereFilterMap = new Map<String, String>{
                    CHANGE_ORDER_ENTITLEMENT_NGBS_KEYWORD => entNgbsQueryStr,
                    CHANGE_ORDER_ENTITLEMENT_OLD_BILLING_KEYWORD => ' Account__c = :accountId AND Quote__c = null'
                };

            } else if ('hierarchyTable'.equalsIgnoreCase(virtualObjectName)) {
                String query = 'SELECT {!fields}, Package_Info__c, PackageInfo__c, Charge_Term__c, ChargeTerm__c, Discount, Product2.ExtID__c, Product2.Feature__c, Product2.Family, Product2.Dependent_On_Feature__c, Product2.Name, Sort_Order__c, Package_Info_QLI__c ,Quote.PackageNameNew__c ' +
                    ' FROM QuoteLineItem ' +
                    ' WHERE Quote.OpportunityId = :opportunityId AND QuoteId = :baseObjId ' +
                    ' AND ChargeTerm__c != \'' + Product2Helper.CHARGE_TERM_ONE_TIME + '\'';

                dataItem.type = HIERARCHY_TABLE_TYPE;
                dataItem.queries = new Map<String, String> {CHANGE_ORDER_QUOTELINEITEM_KEYWORD => query};
                dataItem.query = query;
                dataItem.objectName = 'QuoteLineItem';
                dataItem.fields = CHANGE_ORDER_QUOTELINEITEM_DEFAULT_KEYWORDS;

            } else if ('hierarchyTableNew'.equalsIgnoreCase(virtualObjectName)) {
                String qliQueryString = 'SELECT {!fields} FROM QuoteLineItem WHERE QuoteId = :baseObjId';

                dataItem.type = HIERARCHY_TABLE_NEW;
                dataItem.queries = new Map<String, String> {
                    CHANGE_ORDER_QUOTELINEITEM_KEYWORD => qliQueryString,
                    CHANGE_ORDER_ENTITLEMENT_KEYWORD => 'SELECT {!fields} FROM Entitlement__c WHERE'
                };
                dataItem.fieldsSets = new Map<String, Set<String>>{
                    CHANGE_ORDER_QUOTELINEITEM_KEYWORD => new Set<String>(),
                    CHANGE_ORDER_ENTITLEMENT_KEYWORD => new Set<String>()
                };

                addToFieldSet(
                    dataItem.fieldsSets.get(CHANGE_ORDER_QUOTELINEITEM_KEYWORD),
                    CHANGE_ORDER_QUOTELINEITEM_DEFAULT_KEYWORDS
                );
                addToFieldSet(
                    dataItem.fieldsSets.get(CHANGE_ORDER_ENTITLEMENT_KEYWORD),
                    CHANGE_ORDER_ENTITLEMENT_DEFAULT_KEYWORDS
                );

                String entNgbsQueryStr = ' Quote__c = :baseObjId';

                dataItem.whereFilterMap = new Map<String, String>{
                    CHANGE_ORDER_ENTITLEMENT_NGBS_KEYWORD => entNgbsQueryStr,
                    CHANGE_ORDER_ENTITLEMENT_OLD_BILLING_KEYWORD => ' Account__c = :accountId AND Quote__c = null'
                };

            } else if ('hierarchyTableExisting'.equalsIgnoreCase(virtualObjectName)) {
                String qliQueryString = 'SELECT {!fields} FROM QuoteLineItem WHERE QuoteId = :baseObjId';

                dataItem.type = HIERARCHY_TABLE_EXISTING;
                dataItem.queries = new Map<String, String> {
                    CHANGE_ORDER_QUOTELINEITEM_KEYWORD => qliQueryString,
                    CHANGE_ORDER_ENTITLEMENT_KEYWORD => 'SELECT {!fields} FROM Entitlement__c WHERE'
                };
                dataItem.fieldsSets = new Map<String, Set<String>>{
                    CHANGE_ORDER_QUOTELINEITEM_KEYWORD => new Set<String>(),
                    CHANGE_ORDER_ENTITLEMENT_KEYWORD => new Set<String>()
                };

                addToFieldSet(
                    dataItem.fieldsSets.get(CHANGE_ORDER_QUOTELINEITEM_KEYWORD),
                    CHANGE_ORDER_QUOTELINEITEM_DEFAULT_KEYWORDS
                );
                addToFieldSet(
                    dataItem.fieldsSets.get(CHANGE_ORDER_ENTITLEMENT_KEYWORD),
                    CHANGE_ORDER_ENTITLEMENT_DEFAULT_KEYWORDS
                );

                String entNgbsQueryStr = ' Quote__c = :baseObjId';

                dataItem.whereFilterMap = new Map<String, String>{
                    CHANGE_ORDER_ENTITLEMENT_NGBS_KEYWORD => entNgbsQueryStr,
                    CHANGE_ORDER_ENTITLEMENT_OLD_BILLING_KEYWORD => ' Account__c = :accountId AND Quote__c = null'
                };

            } else if ('hierarchyTableExistingAndNew'.equalsIgnoreCase(virtualObjectName)) {
                String qliQueryString = 'SELECT {!fields} FROM QuoteLineItem WHERE QuoteId = :baseObjId';

                dataItem.type = HIERARCHY_TABLE_EXISTING_AND_NEW;
                dataItem.queries = new Map<String, String> {
                    CHANGE_ORDER_QUOTELINEITEM_KEYWORD => qliQueryString,
                    CHANGE_ORDER_ENTITLEMENT_KEYWORD => 'SELECT {!fields} FROM Entitlement__c WHERE'
                };
                dataItem.fieldsSets = new Map<String, Set<String>>{
                    CHANGE_ORDER_QUOTELINEITEM_KEYWORD => new Set<String>(),
                    CHANGE_ORDER_ENTITLEMENT_KEYWORD => new Set<String>()
                };

                addToFieldSet(
                    dataItem.fieldsSets.get(CHANGE_ORDER_QUOTELINEITEM_KEYWORD),
                    CHANGE_ORDER_QUOTELINEITEM_DEFAULT_KEYWORDS
                );
                addToFieldSet(
                    dataItem.fieldsSets.get(CHANGE_ORDER_ENTITLEMENT_KEYWORD),
                    CHANGE_ORDER_ENTITLEMENT_DEFAULT_KEYWORDS
                );

                String entNgbsQueryStr = ' Quote__c = :baseObjId';

                dataItem.whereFilterMap = new Map<String, String>{
                    CHANGE_ORDER_ENTITLEMENT_NGBS_KEYWORD => entNgbsQueryStr,
                    CHANGE_ORDER_ENTITLEMENT_OLD_BILLING_KEYWORD => ' Account__c = :accountId AND Quote__c = null'
                };

            } else if ('hierarchyTableChangeOrder'.equalsIgnoreCase(virtualObjectName)) {
                dataItem.type = HIERARCHY_TABLE_CHANGE_ORDER;
                dataItem.queries = new Map<String, String> {
                    CHANGE_ORDER_QUOTELINEITEM_KEYWORD => 'SELECT {!fields} FROM QuoteLineItem WHERE QuoteId = :baseObjId',
                    CHANGE_ORDER_ENTITLEMENT_KEYWORD => 'SELECT {!fields} FROM Entitlement__c WHERE'
                };
                dataItem.fieldsSets = new Map<String, Set<String>>{
                    CHANGE_ORDER_QUOTELINEITEM_KEYWORD => new Set<String>(),
                    CHANGE_ORDER_ENTITLEMENT_KEYWORD => new Set<String>()
                };

                addToFieldSet(
                    dataItem.fieldsSets.get(CHANGE_ORDER_QUOTELINEITEM_KEYWORD),
                    CHANGE_ORDER_QUOTELINEITEM_DEFAULT_KEYWORDS
                );
                addToFieldSet(
                    dataItem.fieldsSets.get(CHANGE_ORDER_ENTITLEMENT_KEYWORD),
                    CHANGE_ORDER_ENTITLEMENT_DEFAULT_KEYWORDS
                );

                dataItem.whereFilterMap = new Map<String, String>{
                    CHANGE_ORDER_ENTITLEMENT_NGBS_KEYWORD => ' Quote__c = :baseObjId',
                    CHANGE_ORDER_ENTITLEMENT_OLD_BILLING_KEYWORD => ' Account__c = :accountId AND Quote__c = null'
                };

            } else if ('isProServEngaged'.equalsIgnoreCase(virtualObjectName)) {
                dataItem.type = NO_QUERY_TYPE;

            } else if ('approvedBICountry'.equalsIgnoreCase(virtualObjectName)) {
                dataItem.type = NO_QUERY_TYPE;

            } else if ('oldPackageName'.equalsIgnoreCase(virtualObjectName)) {
                dataItem.type = NO_QUERY_TYPE;

            } else if ('newPackageName'.equalsIgnoreCase(virtualObjectName)) {
                dataItem.type = NO_QUERY_TYPE;

            } else if ('selectedPackageId'.equalsIgnoreCase(virtualObjectName)) {
                dataItem.type = NO_QUERY_TYPE;

            } else if ('engageVoicePackageIds'.equalsIgnoreCase(virtualObjectName)) {
                dataItem.type = NO_QUERY_TYPE;

            } else if ('isTargetPriceAvailable'.equalsIgnoreCase(virtualObjectName)) {
                dataItem.type = NO_QUERY_TYPE;

            } else if ('isCCTerminated'.equalsIgnoreCase(virtualObjectName)) {
                dataItem.type = NO_QUERY_TYPE;

            } else if ('isEngDTerminated'.equalsIgnoreCase(virtualObjectName)) {
                dataItem.type = NO_QUERY_TYPE;

            } else if ('isEngVTerminated'.equalsIgnoreCase(virtualObjectName)) {
                dataItem.type = NO_QUERY_TYPE;

            } else if (VARIABLE_KEYWORD.equalsIgnoreCase(virtualObjectName)) {
                dataItem.type = NO_QUERY_TYPE;

            }

            return dataItem;
        }

        /**
         *  Get Set of fields required for virtual field
         *  @param virtualFieldName
         *  @param type             get fields for which type of objects (base object or loop object)
         */
        public Set<String> getRequiredFields(String virtualFieldName, String type) {
            virtualFieldName = virtualFieldName.trim();
            Matcher prefixDotNotationMatcher = Pattern.compile(PREFIX_DOT_NOTATION_PATTERN).matcher(virtualFieldName);
            String virtualFieldNamePrefix = null;
            String virtualFieldNameField = null;
            while (prefixDotNotationMatcher.find()) {
                virtualFieldNamePrefix = prefixDotNotationMatcher.group(1);
                virtualFieldNameField = prefixDotNotationMatcher.group(2);
            }

            Map <String, Set<String>> requiredFields = new Map <String, Set<String>>();
            if ('RatePerMonth'.equalsIgnoreCase(virtualFieldNamePrefix)) {
                requiredFields = RATEPERMONTH_FIELDS;

            } else if ('RatePerYear'.equalsIgnoreCase(virtualFieldNamePrefix)) {
                requiredFields = RATEPERYEAR_FIELDS;

            } else if ('Subtotal'.equalsIgnoreCase(virtualFieldNamePrefix) ||
                'initialSubTotal'.equalsIgnoreCase(virtualFieldNamePrefix) ||
                'totalInitialSubTotal'.equalsIgnoreCase(virtualFieldNamePrefix)) {
                requiredFields = SUBTOTAL_FIELDS;

            }  else if ('initialCostCenterLineItemSubTotal'.equalsIgnoreCase(virtualFieldNamePrefix) ||
                'totalinitialCostCenterLineItemSubTotal'.equalsIgnoreCase(virtualFieldNamePrefix)) {
                requiredFields = COSTCENTERLINEITEM_SUBTOTAL_FIELDS;

            } else if ('SubtotalConsideringChargeTerm'.equalsIgnoreCase(virtualFieldNamePrefix)) {
                requiredFields = SUBTOTALCONSIDERINGCHARGETERM_FIELDS;

            } else if ('TotalMonthlyAmount'.equalsIgnoreCase(virtualFieldNamePrefix)) {
                requiredFields = TOTALMONTHLYAMOUNT_FIELDS;

            } else if ('TotalInitialAmount'.equalsIgnoreCase(virtualFieldNamePrefix)) {
                requiredFields = TOTALINITIALAMOUNT_FIELDS;

            } else if ('TotalFirstYearAmount'.equalsIgnoreCase(virtualFieldNamePrefix)) {
                requiredFields = TOTALFIRSTYEARAMOUNT_FIELDS;

            } else if ('ServicePlanRatePerMonth'.equalsIgnoreCase(virtualFieldNamePrefix)) {
                requiredFields = SERVICEPLANRATEPERMONTH_FIELDS;

            } else if ('ServicePlanRatePerYear'.equalsIgnoreCase(virtualFieldNamePrefix)) {
                requiredFields = SERVICEPLANRATEPERYEAR_FIELDS;

            } else if ('entitlementTotal'.equalsIgnoreCase(virtualFieldNamePrefix)) {
                requiredFields = ENTITLEMENTTOTAL_FIELDS;

            } else if ('summEntitlementTotal'.equalsIgnoreCase(virtualFieldNamePrefix)) {
                requiredFields = SUMMENTITLEMENTTOTAL_FIELDS;

            } else if ('summEntitlementAnnualTotal'.equalsIgnoreCase(virtualFieldNamePrefix)) {
                requiredFields = SUMMENTITLEMENTTOTAL_FIELDS;

            } else if ('summEntitlementMonthlyTotal'.equalsIgnoreCase(virtualFieldNamePrefix)) {
                requiredFields = SUMMENTITLEMENTTOTAL_FIELDS;

            } else if ('entitlementChargeTerm'.equalsIgnoreCase(virtualFieldNamePrefix)) {
                requiredFields = SUMMENTITLEMENTTOTAL_FIELDS;

            } else if ('isTaxesInCart'.equalsIgnoreCase(virtualFieldNamePrefix)) {
                requiredFields = ISTAXESINCART_FIELDS;

            } else if (
                'newProposalTotal'.equalsIgnoreCase(virtualFieldNamePrefix)
                    || 'overallOneTimePayment'.equalsIgnoreCase(virtualFieldNamePrefix)
                    || 'overallOneTimePaymentWithTaxes'.equalsIgnoreCase(virtualFieldNamePrefix)
                    || 'overallTaxesPayment'.equalsIgnoreCase(virtualFieldNamePrefix)
                    || 'overallOneTimeResellerPrice'.equalsIgnoreCase(virtualFieldNamePrefix)
                ) {
                requiredFields = NEWPROPOSALTOTAL_FIELDS;

            } else if('totalAnnualAmount'.equalsIgnoreCase(virtualFieldNamePrefix)) {
                requiredFields = TOTALANNUALAMOUNT_FIELDS;

            } else if ('overallNewProposalTotalPrice'.equalsIgnoreCase(virtualFieldNamePrefix)) {
                requiredFields = OVERALLNEWPROPOSALTOTALPRICE_FIELDS;

            } else if ('overallNewProposalTotalPriceWithTaxes'.equalsIgnoreCase(virtualFieldNamePrefix)) {
                requiredFields = OVERALLNEWPROPOSALTOTALPRICE_FIELDS;

            } else if ('overallNewProposalTotalAnnualPrice'.equalsIgnoreCase(virtualFieldNamePrefix)) {
                requiredFields = OVERALLNEWPROPOSALTOTALPRICE_FIELDS;

            } else if ('overallNewProposalTotalMonthlyPrice'.equalsIgnoreCase(virtualFieldNamePrefix)) {
                requiredFields = OVERALLNEWPROPOSALTOTALPRICE_FIELDS;

            } else if ('overallTotal12MonthAmount'.equalsIgnoreCase(virtualFieldNamePrefix)) {
                requiredFields = OVERALLTOTAL12MONTHAMOUNT_FIELDS;

            } else if ('BillingContact'.equalsIgnoreCase(virtualFieldNamePrefix)) {
                requiredFields = BILLINGCONTACT_FIELDS;

            } else if ('SignatoryContact'.equalsIgnoreCase(virtualFieldNamePrefix)) {
                requiredFields = SIGNATORYCONTACT_FIELDS;

            } else if ('EngageLegalApproval'.equalsIgnoreCase(virtualFieldNamePrefix)) {
                requiredFields = ENGAGELEGALAPPROVAL_FIELDS;

            } else if (
                'hierarchyTable'.equalsIgnoreCase(virtualFieldNamePrefix)
                    || 'taxesAndFeesTable'.equalsIgnoreCase(virtualFieldNamePrefix)
                ) {
                requiredFields = HIERARCHYTABLE_FIELDS;

            } else if ('DLsInitiallyPurchased'.equalsIgnoreCase(virtualFieldNamePrefix)) {
                requiredFields = DLSINITIALLYPURCHASED_FIELDS;

            } else if ('summNewQuantity'.equalsIgnoreCase(virtualFieldNamePrefix)) {
                requiredFields = SUMMNEWQUANTITY_FIELDS;

            }  else if ('resellerPrice'.equalsIgnoreCase(virtualFieldName)
                || 'resellerPriceTotals'.equalsIgnoreCase(virtualFieldName)) {
                requiredFields = RESELLERPRICE_FIELDS;

            } else if ('entResellerPrice'.equalsIgnoreCase(virtualFieldName)) {
                requiredFields = ENTRESELLERPRICE_FIELDS;

            } else if ('isProServEngaged'.equalsIgnoreCase(virtualFieldNamePrefix)) {
                requiredFields = IS_PROSERV_ENGAGED_FIELDS;

            } else if ('currentItemSubtotal'.equalsIgnoreCase(virtualFieldNamePrefix)) {
                requiredFields = CURRENT_ITEM_SUBTOTAL_FIELDS;

            } else if (
                'changeOrderTable'.equalsIgnoreCase(virtualFieldNamePrefix)
                    || 'changeOrderTableCC'.equalsIgnoreCase(virtualFieldNamePrefix)
                ) {
                requiredFields = CHANGE_ORDER_TABLE_FIELDS;

            } else if (
                'hierarchyTableNew'.equalsIgnoreCase(virtualFieldNamePrefix)
                    || 'hierarchyTableExisting'.equalsIgnoreCase(virtualFieldNamePrefix)
                    || 'hierarchyTableExistingAndNew'.equalsIgnoreCase(virtualFieldNamePrefix)
                    || 'hierarchyTableChangeOrder'.equalsIgnoreCase(virtualFieldNamePrefix)
                ) {
                requiredFields = CHANGE_ORDER_TABLE_FIELDS;

            } else if ('dependentOnFeature'.equalsIgnoreCase(virtualFieldNamePrefix)) {
                DEPENDENT_ON_FEATURE_FIELDS.get(LOOP_OBJ_KEYWORD).add(virtualFieldNameField);
                requiredFields = DEPENDENT_ON_FEATURE_FIELDS;

            } else if ('newRaterAnnualSubtotal'.equalsIgnoreCase(virtualFieldName) ||
                'newRaterMonthlySubtotal'.equalsIgnoreCase(virtualFieldName) ||
                'newResellerPriceAnnualSubtotal'.equalsIgnoreCase(virtualFieldName) ||
                'newResellerPriceMonthlySubtotal'.equalsIgnoreCase(virtualFieldName) ||
                'summNewRaterAnnualSubtotal'.equalsIgnoreCase(virtualFieldName) ||
                'summNewRaterMonthlySubtotal'.equalsIgnoreCase(virtualFieldName) ||
                'summNewResellerPriceAnnualSubtotal'.equalsIgnoreCase(virtualFieldName) ||
                'summNewResellerPriceMonthlySubtotal'.equalsIgnoreCase(virtualFieldName)) {
                requiredFields = NEW_SUBTOTAL_FIELDS;

            } else if ('entMonthlySubtotal'.equalsIgnoreCase(virtualFieldName) ||
                'entResellerPriceMonthlySubtotal'.equalsIgnoreCase(virtualFieldName)) {
                requiredFields = MONTHLY_SUBTOTAL_FIELDS;

            } else if ('sumEntMonthlySubtotal'.equalsIgnoreCase(virtualFieldName) ||
                'sumEntResellerPriceMonthlySubtotal'.equalsIgnoreCase(virtualFieldName)) {
                requiredFields = SUM_MONTHLY_SUBTOTAL_FIELDS;

            } else if ('entAnnualSubtotal'.equalsIgnoreCase(virtualFieldName) ||
                'entResellerPrice'.equalsIgnoreCase(virtualFieldName) ||
                'entResellerPriceAnnualSubtotal'.equalsIgnoreCase(virtualFieldName)) {
                requiredFields = ANNUAL_SUBTOTAL_FIELDS;

            } else if ('sumEntAnnualSubtotal'.equalsIgnoreCase(virtualFieldName) ||
                'sumEntResellerPriceAnnualSubtotal'.equalsIgnoreCase(virtualFieldName)) {
                requiredFields = SUM_ANNUAL_SUBTOTAL_FIELDS;

            } else if ('entOneTimeSubtotal'.equalsIgnoreCase(virtualFieldName) ||
                'entResellerPriceOneTimeSubtotal'.equalsIgnoreCase(virtualFieldName)) {
                requiredFields = ONE_TIME_SUBTOTAL_FIELDS;

            } else if ('sumEntOneTimeSubtotal'.equalsIgnoreCase(virtualFieldName) ||
                'sumResellerPriceEntOneTimeSubtotal'.equalsIgnoreCase(virtualFieldName)) {
                requiredFields = SUM_ONE_TIME_SUBTOTAL_FIELDS;

            } else if ('goaStatus'.equalsIgnoreCase(virtualFieldName)) {
                requiredFields = GOA_STATUS_FIELDS;
            } else if ('approvedBICountry'.equalsIgnoreCase(virtualFieldName)) {
                requiredFields = BUSINESS_IDENTITY_COUNTRY_FIELDS;
            } else if ('oldPackageName'.equalsIgnoreCase(virtualFieldName)) {
                requiredFields = PACKAGE_NAME_FIELDS_COUNTRY_FIELDS;
            } else if ('newPackageName'.equalsIgnoreCase(virtualFieldName)) {
                requiredFields = PACKAGE_NAME_FIELDS_COUNTRY_FIELDS;
            } else if ('selectedPackageId'.equalsIgnoreCase(virtualFieldName)) {
                requiredFields = SELECTED_PACKAGE_ID_FIELDS;
            } else if ('isTargetPriceAvailable'.equalsIgnoreCase(virtualFieldName)) {
                requiredFields = TARGET_PRICE_FIELDS;
            } else if ('isCCTerminated'.equalsIgnoreCase(virtualFieldName)) {
                requiredFields = IS_TERMINATED_FIELDS;
            } else if ('isEngDTerminated'.equalsIgnoreCase(virtualFieldName)) {
                requiredFields = IS_TERMINATED_FIELDS;
            } else if ('isEngVTerminated'.equalsIgnoreCase(virtualFieldName)) {
                requiredFields = IS_TERMINATED_FIELDS;
            } else if ('engageVoicePackageIds'.equalsIgnoreCase(virtualFieldName)) {
                requiredFields = ENGAGE_VOICE_PACKAGE_FIELDS;
            } else if ('isInitialTermNotChanged'.equalsIgnoreCase(virtualFieldName)
                || 'isRenewalTermNotChanged'.equalsIgnoreCase(virtualFieldName)
                || 'isInitialAndRenewalTermsNotChanged'.equalsIgnoreCase(virtualFieldName)) {
                requiredFields = CHANGE_TERM_FIELDS;
            }

            return requiredFields.containsKey(type) ? requiredFields.get(type) : new Set<String>();
        }

        /**
         *  @see {@link https://rc.my.salesforce.com/a2034000003Lub5} B-2140 5.1 Enterprise Deal PDF Template
         */
        public Map<String, Set<String>> SERVICEPLANRATEPERMONTH_FIELDS = new Map<String, Set<String>>{
            BASE_OBJECT_KEYWORD => new Set<String>{
                'RecordTypeId', 'Package_Info__c', 'Pricebook2.Plan__c', 'Payment_Plan__c'
            },
            LOOP_OBJ_KEYWORD => new Set<String>{
                'EffectivePrice__c', 'EffectivePriceNew__c', 'Zero_Quantity__c'
            }
        };
        public Object servicePlanRatePerMonth(sObject qliSObj, sObject baseObj) {
            QuoteLineItem qli = (QuoteLineItem) qliSObj;
            Quote quote = (Quote) baseObj;
            String plan = QuoteHelper.getPlan(quote);
            Decimal effPrice = QuoteLineItemHelper.getEffectivePrice(qli);

            Decimal ratePerMonth = plan.equalsIgnoreCase('Annual') ?
                effPrice / 12 :
                effPrice;

            return (Object) ratePerMonth;
        }
        /**
         *  @see {@link https://rc.my.salesforce.com/a2034000003Lub5} B-2140 5.1 Enterprise Deal PDF Template
         */
        public Map<String, Set<String>> SERVICEPLANRATEPERYEAR_FIELDS = new Map<String, Set<String>>{
            BASE_OBJECT_KEYWORD => new Set<String>{
                'RecordTypeId', 'Package_Info__c', 'Pricebook2.Plan__c', 'Payment_Plan__c'
            },
            LOOP_OBJ_KEYWORD => new Set<String>{
                'EffectivePrice__c', 'EffectivePriceNew__c', 'Zero_Quantity__c'
            }
        };
        public Object servicePlanRatePerYear(sObject qliSObj, sObject baseObj) {
            QuoteLineItem qli = (QuoteLineItem) qliSObj;
            Quote quote = (Quote) baseObj;
            String plan = QuoteHelper.getPlan(quote);
            Decimal effPrice = QuoteLineItemHelper.getEffectivePrice(qli);

            Decimal ratePerMonth = plan.equalsIgnoreCase('Annual') ?
                effPrice :
                effPrice * 12;

            return (Object) ratePerMonth;

        }

        /**
         *  @see {@link https://rc.my.salesforce.com/a2034000003Lub5} B-2140 5.2 Enterprise Deal PDF Template
         */
        public Map<String, Set<String>> RATEPERMONTH_FIELDS = new Map<String, Set<String>>{
            LOOP_OBJ_KEYWORD => new Set<String>{
                'Product2.Charge_Term__c', 'EffectivePrice__c', 'EffectivePriceNew__c',
                'Zero_Quantity__c', 'NewQuantity__c', 'PackageInfo__c', 'Package_Info_QLI__c', 'Package_Info__c',
                'Quote.RecordTypeId', 'QuoteRecordType__c', 'Entitlement__r.ChargeTerm__c', 'PriceFromEntitlement__c'
            }
        };
        public Object ratePerMonth(sObject qliSObj) {
            QuoteLineItem qli = (QuoteLineItem) qliSObj;
            Decimal effPrice = QuoteLineItemHelper.getEffectivePrice(qli);
            String chargeTerm = QuoteLineItemHelper.getChargeTerm(qli);
            Decimal ratePerMonth = null;
            if (chargeTerm.equalsIgnoreCase('Annual')) {
                if (qli.Entitlement__r.ChargeTerm__c != chargeTerm && qli.PriceFromEntitlement__c != null) {
                    ratePerMonth = (effPrice - qli.PriceFromEntitlement__c) / 12;
                } else {
                    ratePerMonth = effPrice / 12;
                }
            } else {
                ratePerMonth = effPrice;
            }

            return (Object) ratePerMonth;
        }

        /**
         *  @see {@link https://rc.my.salesforce.com/a2034000003Lub5} B-2140 5.2 Enterprise Deal PDF Template
         */
        public Map<String, Set<String>> RATEPERYEAR_FIELDS = new Map<String, Set<String>>{
            LOOP_OBJ_KEYWORD => new Set<String>{
                'Product2.Charge_Term__c', 'EffectivePriceNew__c', 'EffectivePrice__c',
                'Zero_Quantity__c', 'Quantity', 'NewQuantity__c', 'PackageInfo__c', 'Package_Info__c',
                'Quote.RecordTypeId', 'QuoteRecordType__c', 'Package_Info_QLI__c'
            }
        };
        public Object ratePerYear(sObject qliSObj) {
            QuoteLineItem qli = (QuoteLineItem) qliSObj;
            Decimal effPrice = QuoteLineItemHelper.getEffectivePrice(qli);
            String chargeTerm = QuoteLineItemHelper.getChargeTerm(qli);

            Decimal ratePerYear = null;
            if (chargeTerm.equalsIgnoreCase('Annual')) {
                ratePerYear = effPrice;
            } else if (chargeTerm.equalsIgnoreCase('One - Time')) {
                ratePerYear = effPrice;
            } else {
                ratePerYear = effPrice * 12;
            }

            return (Object) ratePerYear;
        }

        /**
         *  @see {@link https://rc.my.salesforce.com/a2034000003Lub5} B-2140 5.2 Enterprise Deal PDF Template
         *  @see {@link https://rc.my.salesforce.com/a2034000003qSHA} B-3032 2 Support Enterprise Order Forms for Change Orders
         */
        public Map<String, Set<String>> SUBTOTAL_FIELDS = new Map<String, Set<String>>{
            BASE_OBJECT_KEYWORD => new Set<String>{
                'RecordTypeId', 'Package_Info__c', 'Pricebook2.Plan__c', 'Payment_Plan__c'
            },
            LOOP_OBJ_KEYWORD => new Set<String>{
                'Product2.Charge_Term__c', 'Discount', 'UnitPrice', 'NewQuantity__c', 'TotalPrice', 'Package_Info__c',
                'PackageInfo__c', 'Quote.RecordTypeId', 'QuoteRecordType__c', 'Product2.Family', 'Package_Info_QLI__c'
            }
        };
        public Object subtotal(sObject qliSObj, sObject baseObj) {
            return (Object) calcSubTotal(qliSObj, baseObj, false);
        }

        public Map<String, Set<String>> COSTCENTERLINEITEM_SUBTOTAL_FIELDS = new Map<String, Set<String>>{
            LOOP_OBJ_KEYWORD => new Set<String>{
                'Quote_Line_Item__r.Product2.Charge_Term__c', 'Quote_Line_Item__r.Discount',
                'Quote_Line_Item__r.UnitPrice', 'Quote_Line_Item__r.NewQuantity__c',
                'Quote_Line_Item__r.TotalPrice', 'Quote_Line_Item__r.Package_Info_QLI__c',
                'Quote_Line_Item__r.PackageInfo__c', 'Quote_Line_Item__r.Quote.RecordTypeId',
                'Quote_Line_Item__r.Package_Info__c',
                'Quote_Line_Item__r.QuoteRecordType__c', 'Quantity__c'
            }
        };

        /**
         *  @see {@link https://rc.my.salesforce.com/a2034000003qSHA} B-3032 2 Support Enterprise Order Forms for Change Orders
         */
        public Map<String, Set<String>> SUBTOTALCONSIDERINGCHARGETERM_FIELDS = new Map<String, Set<String>>{
            BASE_OBJECT_KEYWORD => new Set<String>{
                'RecordTypeId', 'Package_Info__c', 'Pricebook2.Plan__c', 'Payment_Plan__c'
            },
            LOOP_OBJ_KEYWORD => new Set<String>{
                'Product2.Charge_Term__c', 'Discount', 'UnitPrice', 'NewQuantity__c', 'TotalPrice', 'Package_Info__c',
                'PackageInfo__c', 'Quote.RecordTypeId', 'QuoteRecordType__c', 'Product2.Family', 'Package_Info_QLI__c'
            }
        };
        public Object subtotalConsideringChargeTerm(sObject qliSObj, sObject baseObj) {
            return (Object) calcSubTotal(qliSObj, baseObj, true);
        }

        private Object calcSubTotal(sObject qliSObj, sObject baseObj, Boolean useChargeTerm) {
            QuoteLineItem qli = (QuoteLineItem) qliSObj;
            Quote quote = (Quote) baseObj;

            String chargeTerm = QuoteLineItemHelper.getChargeTerm(qli);
            String plan = QuoteHelper.getPlan(quote);

            // qli.TotalAnnualPriceWithEntitlement__c && qli.TotalMonthlyPriceWithEntitlement__c;
            Decimal totalAnnualPrice = QuoteLineItemHelper.getTotalAnnualPriceWithEntitlement(qli);
            Decimal totalMonthlyPrice = QuoteLineItemHelper.getTotalMonthlyPriceWithEntitlement(qli);

            Decimal subtotal = null;

            if (useChargeTerm
                && !(chargeTerm.equalsIgnoreCase(Product2Helper.CHARGE_TERM_ANNUAL)
                || chargeTerm.contains(Product2Helper.CHARGE_TERM_MONTHLY))) {
                subtotal = qli.TotalPrice;
            } else {
                subtotal = Product2Helper.CHARGE_TERMS_SET_ANNUAL.contains(plan) ? totalAnnualPrice : totalMonthlyPrice;
            }

            return (Object) subtotal;
        }

        private Object initialCostCenterLineItemSubTotal(sObject ccliSObj) {
            Cost_Center_Line_item__c ccli = (Cost_Center_Line_Item__c) ccliSObj;
            Decimal initialCostCenterLineItemSubTotal = QuoteLineItemHelper.getTotalPrice(ccli);
            return (Object) initialCostCenterLineItemSubTotal;
        }

        private Object totalinitialCostCenterLineItemSubTotal(List<sObject> dataList, String relationshipFieldName, Id parentobjId) {
            Decimal totalinitialCostCenterLineItemSubTotal = 0;
            for (sObject ccliSobj : dataList) {
                Cost_Center_Line_Item__c ccli = (Cost_Center_Line_Item__c) ccliSobj;
                if (relationshipFieldName != null && parentobjId != null &&
                    ccli.get(relationshipFieldName) == parentobjId) {
                    Decimal initialCostCenterLineItemSubTotal = QuoteLineItemHelper.getTotalPrice(ccli);
                    totalinitialCostCenterLineItemSubTotal += initialCostCenterLineItemSubTotal;
                }
            }

            return (Object) totalinitialCostCenterLineItemSubTotal;
        }

        private Object initialSubTotal(sObject qliSobj) {
            QuoteLineItem qli = (QuoteLineItem) qliSobj;
            Decimal initialSubTotal = QuoteLineItemHelper.getTotalPrice(qli);
            return (Object) initialSubTotal;
        }

        private Object totalInitialSubTotal(List<sObject> dataList, String relationshipFieldName, Id parentobjId) {
            Decimal totalInitialSubTotal = 0;
            for (sObject qliSObj : dataList) {
                QuoteLineItem qli = (QuoteLineItem) qliSObj;
                if (relationshipFieldName != null && parentobjId != null &&
                    qli.get(relationshipFieldName) == parentobjId || parentobjId == null) {
                    Decimal initialSubTotal = QuoteLineItemHelper.getTotalPrice(qli);
                    totalInitialSubTotal += initialSubTotal;
                }
            }

            return (Object) totalInitialSubTotal;
        }

        private Object costCenterTotal(sObject ccObj) {
            Cost_Center__c cc = (Cost_Center__c) ccObj;
            Decimal costCenterTotal = 0;
            for (Cost_Center_Line_item__c ccli : cc.Cost_Center_Products__r) {
                costCenterTotal += (Decimal) initialCostCenterLineItemSubTotal(ccli);
            }
            return (Object) costCenterTotal;
        }

        private Object totalByCostCenters(List<sObject> dataList, String relationshipFieldName, Id parentobjId) {

            Decimal totalByCostCenters = 0;
            for (Cost_Center__c cc : (List<Cost_Center__c>) dataList) {
                if (relationshipFieldName != null && parentobjId != null &&
                    cc.get(relationshipFieldName) == parentobjId || parentobjId == null) {
                    for (Cost_Center_Line_item__c ccLi : cc.Cost_Center_Products__r) {

                        totalByCostCenters += (Decimal) initialCostCenterLineItemSubTotal(ccli);
                    }
                }
            }
            return (Object) totalByCostCenters;
        }

        /**
         *  @see {@link https://rc.my.salesforce.com/a2034000003Lub5} B-2140 5.2 Enterprise Deal PDF Template
         *  @see {@link https://rc.my.salesforce.com/a2034000003qSHA} B-3032 2 Support Enterprise Order Forms for Change Orders
         *  sum of Rate Per Month * Quantity for all rows where Product2.Charge_Term__c != "One - Time" (take into account table 5.1. too)
         */
        public Map<String, Set<String>> TOTALMONTHLYAMOUNT_FIELDS = RATEPERMONTH_FIELDS;
        public Object totalMonthlyAmount(List<sObject> dataList) {
            Decimal totalMonthlyAmount = 0;
            for (sObject qliSObj : dataList) {
                QuoteLineItem qli = (QuoteLineItem) qliSObj;
                String chargeTerm = QuoteLineItemHelper.getChargeTerm(qli);
                if (!chargeTerm.equalsIgnoreCase('One - Time')) {
                    Decimal ratePerMonth = (Decimal) ratePerMonth(qliSObj) * (qli.NewQuantity__c == null ? 0 : qli.NewQuantity__c);
                    totalMonthlyAmount += ratePerMonth;
                }
            }

            return (Object) totalMonthlyAmount;
        }

        /**
         *  @see {@link https://rc.my.salesforce.com/a2034000003Lub5} B-2140 5.2 Enterprise Deal PDF Template
         *  Total Initial Amount (includes One-Time Fees)*: sum of all SubTotals (take into account table 5.1. too)
         */
        public Map<String, Set<String>> TOTALINITIALAMOUNT_FIELDS = SUBTOTALCONSIDERINGCHARGETERM_FIELDS;
        public Object totalInitialAmount(List<sObject> dataList, sObject baseObj) {
            Decimal totalInitialAmount = 0;
            for (sObject qli : dataList) {
                Decimal subtotal = (Decimal) calcSubTotal(qli, baseObj, true);
                totalInitialAmount += subtotal;
            }
            return (Object) totalInitialAmount;
        }

        /**
         *  @see {@link https://rc.my.salesforce.com/a2034000003Lub5} B-2140 5.2 Enterprise Deal PDF Template
         *  @see {@link https://rc.my.salesforce.com/a2034000003qSHA} B-3032 2 Support Enterprise Order Forms for Change Orders
         */
        public Map<String, Set<String>> TOTALFIRSTYEARAMOUNT_FIELDS = RATEPERYEAR_FIELDS;
        public Object totalFirstYearAmount(List<sObject> dataList) {
            Decimal totalFirstYearAmount = 0;
            for (sObject qliSObj : dataList) {
                QuoteLineItem qli = (QuoteLineItem) qliSObj;
                String chargeTerm = QuoteLineItemHelper.getChargeTerm(qli);
                if (!chargeTerm.equalsIgnoreCase('One - Time')) {
                    totalFirstYearAmount += (Decimal) ratePerYear(qliSObj) * (qli.NewQuantity__c == null ? 0 : qli.NewQuantity__c);
                }
            }

            return (Object) totalFirstYearAmount;
        }

        /**
         *  @see {@link https://rc.my.salesforce.com/a2034000005HO33} B-7092 New Template Engine field - TotalAnnualAmount (does not include One - Time)
         *  @return summ of 'Rate Per Year' for Products with Charge_Term__c not equals 'One - Time'
         */
        public Map<String, Set<String>> TOTALANNUALAMOUNT_FIELDS = RATEPERYEAR_FIELDS;

        public Object totalAnnualAmount(List<sObject> dataList, sObject baseObj) {
            Decimal totalAnnualAmount = 0;
            Quote quote = (Quote) baseObj;
            for (sObject qliSObj : dataList) {
                QuoteLineItem qli = (QuoteLineItem) qliSObj;
                String chargeTerm = QuoteLineItemHelper.getChargeTerm(qli);

                if(Product2Helper.CHARGE_TERM_ONE_TIME.equalsIgnoreCase(chargeTerm)) {
                    continue;
                }

                Decimal quantity = QuoteLineItemHelper.getQuantity(qli);
                Decimal ratePerYearValue = (Decimal) ratePerYear(qli);

                totalAnnualAmount += (ratePerYearValue * quantity);
            }

            return (Object) totalAnnualAmount;
        }

        /**
         *  @see {@link https://rc.my.salesforce.com/a2034000003fwI2} B-1529 PDF Changes for existing quantity
         *  @return if Pricebook plan is 'Annual' then 'Total Annual Price' otherwise 'Total Monthly Price'
         */
        public Map<String, Set<String>> ENTITLEMENTTOTAL_FIELDS = new Map<String, Set<String>>{
            BASE_OBJECT_KEYWORD => new Set<String>{
                'RecordTypeId', 'Package_Info__c', 'Pricebook2.Plan__c', 'Payment_Plan__c',
                'CurrentService__c', 'Opportunity.Tier_Name__c', 'CurrentService__r.ChargeTerm__c',
                'CurrentService__r.Product__r.Charge_Term__c'
            },
            LOOP_OBJ_KEYWORD => new Set<String>{
                'Total_Annual_Price__c', 'Total_Monthly_Price__c', 'Account__c', 'Product__r.Family',
                'Product__r.Charge_Term__c', 'ChargeTerm__c'
            }
        };
        public Object entitlementTotal(sObject entSObj, sObject baseObj, Object chargeTerm) {
            Entitlement__c ent = (Entitlement__c) entSObj;
            Quote quote = (Quote) baseObj;
            Decimal entitlementTotal = 0;

            if(quote.Opportunity.Tier_Name__c != 'Fax'){
                entitlementTotal = ('Annual').equalsIgnoreCase((String) chargeTerm) ?
                    ent.Total_Annual_Price__c :
                    ent.Total_Monthly_Price__c;
            } else {
                entitlementTotal = ('Annual').equalsIgnoreCase(ent.ChargeTerm__c) ?
                    ent.Total_Annual_Price__c :
                    ent.Total_Monthly_Price__c;
            }

            return (Object) entitlementTotal;
        }

        public Object entitlementChargeTerm(List<sObject> dataList, sObject baseObj) {
            Quote quote = (Quote) baseObj;
            Entitlement__c serviceEnt = null;
            String chargeTerm;

            for (Entitlement__c e : (List<Entitlement__c>) dataList) {
                if(e.Id == quote.CurrentService__c) {
                    serviceEnt = e;
                    break;
                }
            }

            serviceEnt = serviceEnt != null
                ? serviceEnt
                : quote.CurrentService__r != null
                    ? quote.CurrentService__r
                    : null;

            chargeTerm = serviceEnt != null
                ? EntitlementHelper.getChargeTerm(serviceEnt)
                : 'COULDN\'T FIND SERVICE ENTITLEMENT FOR QUOTE!';

            return (Object) chargeTerm;
        }

        /**
         *  @see {@link https://rc.my.salesforce.com/a2034000003fwI2} B-1529 PDF Changes for existing quantity
         *  Summ of entitlementTotal
         */
        public Map<String, Set<String>> SUMMENTITLEMENTTOTAL_FIELDS = ENTITLEMENTTOTAL_FIELDS;
        public Object summEntitlementTotal(List<sObject> dataList, sObject baseObj) {
            Decimal entitlementTotalSummary = 0;
            String serviceEntChargeTerm = (String) entitlementChargeTerm(dataList, baseObj);
            for (sObject entSObj : dataList) {
                Object entitlementTotal = entitlementTotal(entSObj, baseObj, serviceEntChargeTerm);
                if (String.isNotBlank(String.valueOf(entitlementTotal))) {
                    entitlementTotalSummary += (Decimal) entitlementTotal;
                }
            }
            return (Object) entitlementTotalSummary;
        }

        /**
         *  @see {@link https://jira.ringcentral.com/browse/CRM-974} CRM-974 PDF Changes for existing quantity
         *  Summ of entitlementAnnualTotal exclude monthly charges
         */
        public Object summEntitlementAnnualTotal(List<sObject> dataList, sObject baseObj) {
            Decimal summEntitlementAnnualTotal = 0;
            for (sObject entSObj : dataList) {
                Entitlement__c ent = (Entitlement__c) entSObj;
                if(Product2Helper.CHARGE_TERM_ANNUAL.equalsIgnoreCase(ent.ChargeTerm__c)){
                    summEntitlementAnnualTotal += (Decimal) ent.Total_Annual_Price__c;
                }
            }
            return (Object) summEntitlementAnnualTotal;
        }

        /**
         *  @see {@link https://jira.ringcentral.com/browse/CRM-974} CRM-974 PDF Changes for existing quantity
         *  Summ of entitlementMonthlyTotal exclude annual charges
         */
        public Object summEntitlementMonthlyTotal(List<sObject> dataList, sObject baseObj) {
            Decimal summEntitlementMonthlyTotal = 0;
            for (sObject entSObj : dataList) {
                Entitlement__c ent = (Entitlement__c) entSObj;
                if(Product2Helper.CHARGE_TERM_MONTHLY.equalsIgnoreCase(ent.ChargeTerm__c)){
                    summEntitlementMonthlyTotal += (Decimal) ent.Total_Monthly_Price__c;
                }
            }
            return (Object) summEntitlementMonthlyTotal;
        }

        /**
         *  @see {@link https://rc.my.salesforce.com/a2034000003fwI2} B-1529 PDF Changes for existing quantity
         *  @return Product2.Charge_Term__c == "One-Time" ? (Product2.Family == "Overage" ? 0 : QLI[].TotalPrice) : (PriceBook2.Plan__c != "Annual" ? TotalMonthlyPriceWithEntitlement__c : TotalAnnualPriceWithEntitlement__c)
         */
        public Map<String, Set<String>> NEWPROPOSALTOTAL_FIELDS = new Map<String, Set<String>>{
            BASE_OBJECT_KEYWORD => new Set<String>{
                'RecordTypeId', 'Package_Info__c', 'Pricebook2.Plan__c', 'Payment_Plan__c'
            },
            LOOP_OBJ_KEYWORD => new Set<String>{
                'Discount', 'UnitPrice', 'NewQuantity__c', 'TotalPrice', 'Zero_Quantity__c',
                'Product2.Charge_Term__c', 'Product2.Family', 'Quantity', 'Package_Info__c',
                'PackageInfo__c', 'Quote.RecordTypeId', 'QuoteRecordType__c', 'EffectivePrice__c',
                'Total_One_Time__c', 'Entitlement__r.ChargeTerm__c', 'Package_Info_QLI__c', 'ChargeTerm__c'
            }
        };
        public Object newProposalTotal(sObject qliSObj, sObject baseObj) {
            QuoteLineItem qli = (QuoteLineItem) qliSObj;
            Quote quote = (Quote) baseObj;

            String chargeTerm = QuoteLineItemHelper.getChargeTerm(qli);
            String plan = QuoteHelper.getPlan(quote);

            Decimal totalAnnualPriceWithEntitlement = QuoteLineItemHelper.getTotalAnnualPriceWithEntitlement(qli);
            Decimal totalMonthlyPriceWithEntitlement = QuoteLineItemHelper.getTotalMonthlyPriceWithEntitlement(qli);

            Decimal newProposalTotal = null;

            if (Product2Helper.FAMILY_TAXES.equalsIgnoreCase(qli.Product2.Family)) {
                return qli.TotalPrice;
            } else if (Product2Helper.CHARGE_TERM_ONE_TIME.equalsIgnoreCase(chargeTerm)) {
                if (Product2Helper.FAMILY_OVERAGE.equalsIgnoreCase(qli.Product2.Family)) {
                    newProposalTotal = 0;
                } else {
                    newProposalTotal = qli.Total_One_Time__c;
                }
            } else {
                if (
                    Product2Helper.CHARGE_TERM_ANNUAL.equalsIgnoreCase(chargeTerm)
                        || Product2Helper.CHARGE_TERM_ANNUAL_CONTRACT.equalsIgnoreCase(chargeTerm)
                    ) {
                    newProposalTotal = totalAnnualPriceWithEntitlement;
                } else {
                    newProposalTotal = totalMonthlyPriceWithEntitlement;
                }
            }

            return newProposalTotal;
        }

        /**
         *  @see {@link https://rc.my.salesforce.com/a2034000003fwI2} B-1529 PDF Changes for existing quantity
         *  @return summ of 'Total Price' of 'One - Time' Products
         */

        public String overallOneTimeResellerPrice(List<sObject> dataList) {
            VirtualField vf = new VirtualField();
            Decimal totalOneTimeResellerPrice = 0;
            for (sObject qliSObj : dataList) {
                QuoteLineItem qli = (QuoteLineItem) qliSObj;
                String chargeTerm = QuoteLineItemHelper.getChargeTerm(qli);

                if (Product2Helper.CHARGE_TERM_ONE_TIME.equalsIgnoreCase(chargeTerm)) {
                    if (!Product2Helper.FAMILY_TAXES.equalsIgnoreCase(qli.Product2.Family)) {
                        totalOneTimeResellerPrice += Decimal.ValueOf(getOneTimeResellerPrice(qliSObj));
                    }
                }
            }

            return String.valueOf(totalOneTimeResellerPrice.setScale(2));
        }

        private String getOneTimeResellerPrice(sObject qliSObj) {
            QuoteLineItem qli = (QuoteLineItem) qliSObj;
            Decimal oneTimePrice = null;

            if (Product2Helper.FAMILY_OVERAGE.equalsIgnoreCase(qli.Product2.Family)) {
                oneTimePrice = 0;
            } else {
                oneTimePrice = Decimal.ValueOf(resellerPrice(qli)) * qli.NewQuantity__c;
            }

            return String.valueOf(oneTimePrice);
        }

        public Object overallOneTimePayment(List<sObject> dataList, sObject baseObj, Boolean isWithTaxes) {
            VirtualField vf = new VirtualField();
            Decimal totalOneTimePayment = 0;
            Quote quote = (Quote) baseObj;
            for (sObject qliSObj : dataList) {
                QuoteLineItem qli = (QuoteLineItem) qliSObj;
                String chargeTerm = QuoteLineItemHelper.getChargeTerm(qli);

                if (Product2Helper.CHARGE_TERM_ONE_TIME.equalsIgnoreCase(chargeTerm)) {
                    if (isWithTaxes || !Product2Helper.FAMILY_TAXES.equalsIgnoreCase(qli.Product2.Family)) {
                        totalOneTimePayment += (Decimal) vf.newProposalTotal(qliSObj, baseObj);
                    }
                }
            }

            return (Object) totalOneTimePayment;
        }

        public Object overallOneTimePayment(List<sObject> dataList, sObject baseObj) {
            return overallOneTimePayment(dataList, baseObj, false);
        }

        public Object overallOneTimePaymentWithTaxes(List<sObject> dataList, sObject baseObj) {
            return overallOneTimePayment(dataList, baseObj, true);
        }

        public Object overallTaxesPayment(List<sObject> dataList, sObject baseObj) {
            VirtualField vf = new VirtualField();
            Decimal totalTaxesPayment = 0;

            for (sObject qliSObj : dataList) {
                QuoteLineItem qli = (QuoteLineItem) qliSObj;
                if (Product2Helper.FAMILY_TAXES.equalsIgnoreCase(qli.Product2.Family)) {
                    totalTaxesPayment += (Decimal) vf.newProposalTotal(qliSObj, baseObj);
                }
            }

            return totalTaxesPayment;
        }

        /**
         *  @see {@link https://rc.my.salesforce.com/a2034000003fwI2} B-1529 PDF Changes for existing quantity
         *  @return summ of 'Total Annual (Monthly) Price With Entitlement' of not 'One - Time' Products
         */
        public Map<String, Set<String>> OVERALLNEWPROPOSALTOTALPRICE_FIELDS = new Map<String, Set<String>>{
            BASE_OBJECT_KEYWORD => new Set<String>{
                'RecordTypeId', 'Package_Info__c', 'Pricebook2.Plan__c', 'Payment_Plan__c'
            },
            LOOP_OBJ_KEYWORD => new Set<String>{
                'Product2.Charge_Term__c', 'Zero_Quantity__c', 'Quantity', 'Total_One_Time__c', 'ChargeTerm__c',
                'Discount', 'UnitPrice', 'NewQuantity__c', 'TotalPrice', 'EffectivePrice__c', 'Charge_Term__c',
                'PackageInfo__c', 'Quote.RecordTypeId', 'QuoteRecordType__c', 'Product2.Family', 'Package_Info__c',
                'PriceFromEntitlement__c', 'Entitlement__r.ChargeTerm__c'
            }
        };

        public Object overallNewProposalTotalPrice(List<sObject> dataList, sObject baseObj, Boolean isWithTaxes) {
            Decimal overallNewProposalTotalPrice = 0;
            Quote quote = (Quote) baseObj;
            Boolean isNewBilling = QuoteHelper.isNewBillingQuote(quote);
            String plan = QuoteHelper.getPlan(quote);

            for (sObject qliSObj : dataList) {
                QuoteLineItem qli = (QuoteLineItem) qliSObj;
                String chargeTerm = QuoteLineItemHelper.getChargeTerm(qli);

                Decimal totalAnnualPriceWithEntitlement = QuoteLineItemHelper.getTotalAnnualPriceWithEntitlement(qli);
                Decimal totalMonthlyPriceWithEntitlement = QuoteLineItemHelper.getTotalMonthlyPriceWithEntitlement(qli);

                if (!Product2Helper.CHARGE_TERM_ONE_TIME.equalsIgnoreCase(chargeTerm)) {
                    if (isWithTaxes || !Product2Helper.FAMILY_TAXES.equalsIgnoreCase(qli.Product2.Family)) {
                        overallNewProposalTotalPrice +=
                            ( Product2Helper.CHARGE_TERM_ANNUAL.equalsIgnoreCase(plan)
                                || Product2Helper.CHARGE_TERM_ANNUAL_CONTRACT.equalsIgnoreCase(plan))
                                ? totalAnnualPriceWithEntitlement
                                : totalMonthlyPriceWithEntitlement;
                    }
                }
            }

            return (Object) overallNewProposalTotalPrice;
        }


        public Object overallNewProposalTotalPrice(List<sObject> dataList, sObject baseObj) {
            return overallNewProposalTotalPrice(dataList, baseObj, false);
        }

        public Object overallNewProposalTotalPriceWithTaxes(List<sObject> dataList, sObject baseObj) {
            return overallNewProposalTotalPrice(dataList, baseObj, true);
        }

        /**
         *  @see {@link https://jira.ringcentral.com/browse/CRM-974} CRM-974 PDF Changes for existing quantity
         *  return total annual price by QuoteLineItem
         */
        public Object overallNewProposalTotalAnnualPrice(List<sObject> dataList, sObject baseObj) {
            Decimal overallNewProposalTotalAnnualPrice = 0;

            for (sObject qliSObj : dataList) {
                QuoteLineItem qli = (QuoteLineItem) qliSObj;
                String chargeTerm = QuoteLineItemHelper.getChargeTerm(qli);
                if (!Product2Helper.CHARGE_TERM_ONE_TIME.equalsIgnoreCase(chargeTerm)) {
                    if( Product2Helper.CHARGE_TERM_ANNUAL.equalsIgnoreCase(chargeTerm)
                        || Product2Helper.CHARGE_TERM_ANNUAL_CONTRACT.equalsIgnoreCase(chargeTerm)){
                        Decimal totalAnnualPriceWithEntitlement = QuoteLineItemHelper.getTotalAnnualPriceWithEntitlement(qli);
                        overallNewProposalTotalAnnualPrice += totalAnnualPriceWithEntitlement;
                    }
                }
            }

            return (Object) overallNewProposalTotalAnnualPrice;
        }

        /**
         *  @see {@link https://jira.ringcentral.com/browse/CRM-974} CRM-974 PDF Changes for existing quantity
         *  return total monthly price by QuoteLineItem
         */
        public Object overallNewProposalTotalMonthlyPrice(List<sObject> dataList, sObject baseObj) {
            Decimal overallNewProposalTotalMonthlyPrice = 0;

            for (sObject qliSObj : dataList) {
                QuoteLineItem qli = (QuoteLineItem) qliSObj;
                String chargeTerm = QuoteLineItemHelper.getChargeTerm(qli);

                if (!Product2Helper.CHARGE_TERM_ONE_TIME.equalsIgnoreCase(chargeTerm)) {
                    if( Product2Helper.CHARGE_TERM_MONTHLY.equalsIgnoreCase(chargeTerm) ) {
                        Decimal totalMonthlyPriceWithEntitlement = QuoteLineItemHelper.getTotalMonthlyPriceWithEntitlement(qli);
                        overallNewProposalTotalMonthlyPrice += totalMonthlyPriceWithEntitlement;
                    }
                }
            }

            return (Object) overallNewProposalTotalMonthlyPrice;
        }

        public Object overallNewProposalTotal12Price(List<sObject> dataList, sObject baseObj) {
            Decimal overallNewProposalTotalPrice = 0;
            Quote quote = (Quote) baseObj;
            String plan = QuoteHelper.getPlan(quote);

            for (sObject qliSObj : dataList) {
                QuoteLineItem qli = (QuoteLineItem) qliSObj;
                String chargeTerm = QuoteLineItemHelper.getChargeTerm(qli);

                Decimal totalAnnualPriceWithEntitlement = QuoteLineItemHelper.getTotalAnnualPriceWithEntitlement(qli);

                if (!'One - Time'.equalsIgnoreCase(chargeTerm)) {
                    overallNewProposalTotalPrice += totalAnnualPriceWithEntitlement;
                }
            }

            return (Object) overallNewProposalTotalPrice;
        }

        /**
         *  @see {@link https://rc.my.salesforce.com/a2034000003pjrg} B-2842 Canadian and US Agreement templates migration to PDF GE 2.0
         *  @return summ of 'Total Price' + summ of 'Total Annual (Monthly) Price With Entitlement' (all of not 'One - Time' Products)
         */
        public Map<String, Set<String>> OVERALLTOTAL12MONTHAMOUNT_FIELDS = OVERALLNEWPROPOSALTOTALPRICE_FIELDS;
        public Object overallTotal12MonthAmount(List<sObject> dataList, sObject baseObj) {
            Decimal overallTotal12MonthAmount = 0;
            /* One-Time */
            overallTotal12MonthAmount += (Decimal) overallOneTimePayment(dataList, baseObj);
            /* Other */
            overallTotal12MonthAmount += (Decimal) overallNewProposalTotal12Price(dataList, baseObj);

            return (Object) overallTotal12MonthAmount;
        }

        /**
         *  is Taxes In Cart
         */
        public Map<String, Set<String>> ISTAXESINCART_FIELDS = new Map<String, Set<String>>{
            LOOP_OBJ_KEYWORD => new Set<String>{
                'Product2.Family'
            }
        };
        public Object isTaxesInCart(List<sObject> dataList) {
            Boolean isTaxesInCart = false;
            for (sObject qliSobj : dataList) {
                QuoteLineItem qli = (QuoteLineItem) qliSobj;
                if (Product2Helper.FAMILY_TAXES.equalsIgnoreCase(qli.Product2.Family)) {
                    isTaxesInCart = true;
                    break;
                }
            }
            return (Object) isTaxesInCart;
        }

        /**
         *  https://rc.my.salesforce.com/a2034000003pkBY B-2843 (4) Enterprise CC Order Form PDF templates
         *  @return summary of QLI.NewQuantity__c where QLI.Product2.Feature__c == 17,12,63 or 47
         */
        public Map<String, Set<String>> DLSINITIALLYPURCHASED_FIELDS = new Map<String, Set<String>>{
            LOOP_OBJ_KEYWORD => new Set<String>{
                'NewQuantity__c', 'Product2.Feature__c'
            }
        };
        public Object dlsInitiallyPurchased(List<sObject> dataList) {
            Decimal numberOfDigitalLinesInitiallyPurchased = 0;
            for (sObject qliSObj : dataList) {
                QuoteLineItem qli = (QuoteLineItem) qliSObj;

                if (new Set<Decimal>{
                    Product2Helper.FEATURE_SERVICE_PLAN,
                    Product2Helper.FEATURE_LIMITED_EXTENSION,
                    Product2Helper.FEATURE_GLOBAL_OFFICE,
                    Product2Helper.FEATURE_GLOBAL_OFFICE_LIMITED_EXTENSION
                }.contains(qli.Product2.Feature__c)) {

                    numberOfDigitalLinesInitiallyPurchased += qli.NewQuantity__c;

                }
            }

            return (Object) numberOfDigitalLinesInitiallyPurchased;
        }

        /**
         *  https://rc.my.salesforce.com/a2034000003pkBY B-2843 (7.1) Enterprise CC Order Form PDF templates
         *  @return Summary of QLI.NewQuantity__c
         */
        public Map<String, Set<String>> SUMMNEWQUANTITY_FIELDS = new Map<String, Set<String>>{
            LOOP_OBJ_KEYWORD => new Set<String>{
                'NewQuantity__c'
            }
        };
        public Object summNewQuantity(List<sObject> dataList) {
            Decimal summNewQuantity = 0;
            for (sObject qliSObj : dataList) {
                QuoteLineItem qli = (QuoteLineItem) qliSObj;

                summNewQuantity += qli.NewQuantity__c;

            }

            return (Object) summNewQuantity;
        }
        /**
         * https://rc.my.salesforce.com/a2034000003zOt6  B-4938 ChargeTerm in new Proposal
         * @return ChargeTerm of QLI
         */
        public Object newProposalChargeTerm(SObject dataObj){
            QuoteLineItem qli = (QuoteLineItem) dataObj;
            String chargeTerm = QuoteLineItemHelper.getChargeTerm(qli);
            return chargeTerm;
        }
        /**
         * Today's date
         */
        public Object today() {
            DateTime today = System.today();
            return (Object) today;
        }

        public Object getTemplateParameter(Object paramName, Map<String, String> templateParameters) {
            String result = templateParameters.get((String) paramName);
            if (String.isEmpty(result)) {
                result = '';
            }
            return result;
        }

        /**
         *  Get link to static resource
         *  @example
         *  {! $resource.my_static } -> https://mydomain.visual.force.tld/resource/1501065430000/my_static
         */
        public Object resource(Object paramName) {
            String link = PageReference.forResource(String.valueOf(paramName)).getUrl();
            Integer getParamStartIndex = link.indexOf('?');
            if (getParamStartIndex > -1) {
                link = link.subString(0, getParamStartIndex);
            }
            return URL.getOrgDomainUrl().toExternalForm() + link;
        }

        /**
         * Returns the URL of the Salesforce instance.
         * e.g. https://yourInstance.salesforce.com/
         */
        public Object baseUrl() {
            return (Object) URL.getOrgDomainUrl().toExternalForm();
        }


        public Map<String, Set<String>> QUANTITY_FIELDS = new Map<String, Set<String>>{
            LOOP_OBJ_KEYWORD => new Set<String>{
                'Quantity', 'Zero_Quantity__c'
            }
        };
        public Object quantity(sObject dataObj) {
            return (Object) QuoteLineItemHelper.getQuantity((QuoteLineItem) dataObj);
        }

        public Map<String, Set<String>> CURRENT_SUBTOTAL_FIELDS = new Map<String, Set<String>>{
            // Entitlement__c
            LOOP_OBJ_KEYWORD => new Set<String>{
                'DisplayQuantity__c', 'EffectivePrice__c', 'EffectivePricePrecise__c'
            }
        };
        public Object currentSubtotal(sObject dataObj) {
            Entitlement__c ent = (Entitlement__c) dataObj;
            return ent.DisplayQuantity__c * ent.EffectivePricePrecise__c;
        }

        public Map<String, Set<String>> NEW_SUBTOTAL_FIELDS = new Map<String, Set<String>>{
            // QuoteLineItem
            LOOP_OBJ_KEYWORD => new Set<String>{
                'NewQuantity__c', 'EffectivePrice__c', 'EffectivePriceNew__c', 'Package_Info__c',
                'QuoteRecordType__c', 'PackageInfo__c', 'Zero_Quantity__c', 'Package_Info_QLI__c',
                'Quantity', 'NewQuantity__c', 'Quote.RecordTypeId', 'Product2.Charge_Term__c', 'Product2.Family', 'Product2.Feature__c', 'ChargeTerm__c'
            }
        };
        public Object newSubtotal(sObject dataObj) {
            QuoteLineItem qli = (QuoteLineItem) dataObj;
            return qli.NewQuantity__c * Decimal.valueOf(String.valueOf(newRate(qli)));
        }

        public String newRaterSubtotal(sObject dataObj, Boolean isAnnualChargeTerm, Boolean isResellerPrice) {
            QuoteLineItem qli = (QuoteLineItem) dataObj;
            String chargeTerm = QuoteLineItemHelper.getChargeTerm(qli);

            Decimal multiplier = isAnnualChargeTerm ? 1 : (Decimal) 1 / 12;
            DEcimal rate = isResellerPrice ? Decimal.ValueOf(resellerPrice(dataObj)) : ((Decimal) NumberHelper.getNumberNullSafe(newRate(dataObj)));
            Decimal subtotal = 0;

            if (chargeTerm == Product2Helper.CHARGE_TERM_MONTHLY || chargeTerm == Product2Helper.CHARGE_TERM_MONTHLY_CONTRACT) {
                subtotal = NumberHelper.toNumber(qli?.NewQuantity__c) * rate * 12 * multiplier;
            } else if (chargeTerm == Product2Helper.CHARGE_TERM_ANNUAL) {
                subtotal = NumberHelper.toNumber(qli?.NewQuantity__c) * rate * multiplier;
            }

            return String.ValueOf(subtotal);
        }

        public String summNewRaterSubtotal(List<sObject> dataList, Boolean isAnnualChargeTerm, Boolean isResellerPrice) {
            Decimal total = 0;
            for (sObject qliSObj : dataList) {
                total += Decimal.ValueOF(newRaterSubtotal(qliSObj, isAnnualChargeTerm, isResellerPrice));
            }

            return  String.ValueOf(total);
        }

        public Decimal calculatePhaseTotal(sObject dataObj) {
            VirtualField vf = new VirtualField();
            Decimal total = 0;
            Phase__c phase = (Phase__c) dataObj;

            for (Hardware_Line_Item__c pli : phase.Hardware_Line_Items__r) {
                total += pli.Total_Price__c;
            }

            return total;
        }

        public Decimal calculatePhasesGrandTotal(List<sObject> dataList) {
            VirtualField vf = new VirtualField();
            Decimal total = 0;

            for (sObject dataObj : dataList) {
                Phase__c phase = (Phase__c) dataObj;
                for (Hardware_Line_Item__c pli : phase.Hardware_Line_Items__r) {
                    total += pli.Total_Price__c;
                }
            }

            return  total;
        }

        public Decimal calculateUCPhasesSubTotal(List<sObject> dataList) {
            VirtualField vf = new VirtualField();
            Decimal total = 0;

            for (sObject dataObj : dataList) {
                Phase__c phase = (Phase__c) dataObj;
                if (phase.Phase_Type__c == 'UC') {
                    for (Hardware_Line_Item__c pli : phase.Hardware_Line_Items__r) {
                        total += pli.Total_Price__c;
                    }
                }
            }

            return total;
        }

        public Decimal calculateCCPhasesSubTotal(List<sObject> dataList) {
            VirtualField vf = new VirtualField();
            Decimal total = 0;

            for (sObject dataObj : dataList) {
                Phase__c phase = (Phase__c) dataObj;
                if (phase.Phase_Type__c == 'CC') {
                    for (Hardware_Line_Item__c pli : phase.Hardware_Line_Items__r) {
                        total += pli.Total_Price__c;
                    }
                }
            }

            return total;
        }

        public Set<String> getPhasesTypes(List<sObject> dataList) {
            VirtualField vf = new VirtualField();
            Set<String> phasesTypes = new Set<String>();

            for (sObject dataObj : dataList) {
                Phase__c phase = (Phase__c) dataObj;
                phasesTypes.add(phase.Phase_Type__c);
            }

            return phasesTypes;
        }

        public Map<String, Set<String>> NEW_RATE_FIELDS = new Map<String, Set<String>>{
            // QuoteLineItem
            LOOP_OBJ_KEYWORD => new Set<String>{
                'EffectivePrice__c', 'EffectivePriceNew__c'
            }
        };
        public Object newRate(sObject dataObj) {
            QuoteLineItem qli = (QuoteLineItem) dataObj;
            return qli.EffectivePriceNew__c != null
                ? qli.EffectivePriceNew__c
                : qli.EffectivePrice__c;
        }

        public String entResellerPrice(sObject entSObj){
            Decimal wholesaleRate;
            Decimal result;
            Entitlement__c ent = (Entitlement__c) entSObj;

            Decimal itemPrice = ent.Price__c;

            List<BillingWrappers.PartnerPackageLicenseBillingPlan> partnerConfig = getPartnerConfig(ent);

            Boolean isCommissionable = !partnerConfig.isEmpty();

            if (isCommissionable) {
                for (BillingWrappers.PartnerPackageLicenseBillingPlan pc: partnerConfig){
                    if (pc.duration == NGBS_Discount.durationMapping.get(ent.ChargeTerm__c) && Date.valueOf(pc.startDate) <= Date.TODAY()){
                        wholesaleRate = setWholesaleRateEnt(ent, pc?.wholesaleRater);
                    }
                }
                result = itemPrice * (1 - wholesaleRate/100);
            }

            return isCommissionable
                ?  String.valueOf(result)
                :  String.valueOf(itemPrice);
        }

        private Decimal setWholesaleRateEnt(Entitlement__c ent, BillingWrappers.PartnerPackageLicenseBillingPlanRater wholesaleRater) {
            Decimal wholesaleRate;
            if(wholesaleRater?.type == 'Fixed') {
                wholesaleRate = Decimal.ValueOf(wholesaleRater?.config);
            } else {
                String config = wholesaleRater?.config.replace('from', 'fromQuantity').replace('to', 'toQuantity');
                List<BillingWrappers.PartnerPackageLicenseBillingPlanRaterConfig> configs = ( List<BillingWrappers.PartnerPackageLicenseBillingPlanRaterConfig>)
                    JSON.deserialize(config, List<BillingWrappers.PartnerPackageLicenseBillingPlanRaterConfig>.class);
                for (BillingWrappers.PartnerPackageLicenseBillingPlanRaterConfig conf: configs) {
                    if (conf.fromQuantity <= ent.DisplayQuantity__c && conf.toQuantity >= ent.DisplayQuantity__c) {
                        wholesaleRate = Decimal.ValueOf(conf.value);
                    }
                }
            }
            return wholesaleRate;
        }

        private List<BillingWrappers.PartnerPackageLicenseBillingPlan> getPartnerConfig(Entitlement__c ent) {
            if (String.isEmpty(ent.PartnerConfig__c)) {
                return new List<BillingWrappers.PartnerPackageLicenseBillingPlan>();
            }

            BillingWrappers.PartnerPackageConfig config = (BillingWrappers.PartnerPackageConfig)
                JSON.deserialize(ent.PartnerConfig__c, BillingWrappers.PartnerPackageConfig.class);

            return config.billingPlan;
        }

        public String resellerPrice(sObject dataObj){
            Decimal wholesaleRate;
            Decimal result;

            QuoteLineItem qli = (QuoteLineItem) dataObj;
            Decimal itemPrice = qli.UnitPrice;
            BillingWrappers.QLIPartnerInfo partnerInfo = getPartnerInfo(qli);

            Boolean isCommissionable = partnerInfo != null;

            if (isCommissionable) {
                for (BillingWrappers.PartnerPackageLicenseBillingPlan pi: partnerInfo.billingPlan){
                    if (pi.duration == NGBS_Discount.durationMapping.get(qli.ChargeTerm__c) && Date.valueOf(pi.startDate) <= Date.TODAY()){
                        wholesaleRate = setWholesaleRateQli(qli, pi?.wholesaleRater);
                    }
                }
                result = itemPrice * (1 - wholesaleRate/100);
            }

            return isCommissionable
                ?  String.valueOf(result)
                :  String.valueOf(itemPrice);
        }

        private Decimal setWholesaleRateQli(QuoteLineItem qli, BillingWrappers.PartnerPackageLicenseBillingPlanRater wholesaleRater) {
            Decimal wholesaleRate;
            if(wholesaleRater?.type == 'Fixed') {
                wholesaleRate = Decimal.ValueOf(wholesaleRater?.config);
            } else {
                String config = wholesaleRater?.config.replace('from', 'fromQuantity').replace('to', 'toQuantity');
                List<BillingWrappers.PartnerPackageLicenseBillingPlanRaterConfig> configs = ( List<BillingWrappers.PartnerPackageLicenseBillingPlanRaterConfig>)
                    JSON.deserialize(config, List<BillingWrappers.PartnerPackageLicenseBillingPlanRaterConfig>.class);
                for (BillingWrappers.PartnerPackageLicenseBillingPlanRaterConfig conf: configs) {
                    if (conf.fromQuantity <= qli.newQuantity__c && conf.toQuantity >= qli.newQuantity__c) {
                        wholesaleRate = Decimal.ValueOf(conf.value);
                    }
                }
            }
            return wholesaleRate;
        }

        private BillingWrappers.QLIPartnerInfo getPartnerInfo(QuoteLineItem qli) {
            BillingWrappers.QLIPackageInfo qliPackageInfo = (BillingWrappers.QLIPackageInfo)
                JSON.deserialize(qli.PackageInfo__c, BillingWrappers.QLIPackageInfo.class);
            return qliPackageInfo?.partnerInfo;
        }

        public String resellerPriceTotals(List<sObject> dataList) {
            Decimal total = 0;
            for (sObject obj : dataList) {
                QuoteLineItem qli = (QuoteLineItem) obj;
                total += Decimal.ValueOf(resellerPrice(obj)) * qli.NewQuantity__c;
            }

            return String.valueOf(total);
        }

        public Object isWholesaleEntitlement(sObject baseObj) {
            Quote quote = (Quote) baseObj;
            List<QuoteLineItem> qlis = (List<QuoteLineItem>) new QuoteLineItemSelector()
                .selectQuoteLineItemsByQuoteIds(quote.Id)
                .executeQuery();

            Boolean isWholesaleEntitlement = true;
            for (QuoteLineItem qli: qlis) {
                BillingWrappers.QLIPartnerInfo partnerInfo = getPartnerInfo(qli);
                if (qli.Entitlement__c != null) {
                    List<BillingWrappers.PartnerPackageLicenseBillingPlan> partnerConfig = getPartnerConfig(qli.Entitlement__r);
                    if (partnerInfo != null && partnerConfig.isEmpty()) {
                        isWholesaleEntitlement = false;
                    }
                }
            }
            return String.valueOf(isWholesaleEntitlement);
        }

        public Object isTermNotChanged(sObject baseObj, String typeTerm) {
            Quote quote = (Quote) baseObj;
            String packageId = QuoteHelper.getPackageIdFromQuote(quote);
            Boolean isNotChanged = false;

            List<BillingWrappers.BillingContract> contracts =
                NGBSAPI.requestContractsFromBilling(quote.Account.Billing_Id__c, packageId);

            if (contracts.isEmpty()) {
                return String.valueOf(isNotChanged);
            }

            for (BillingWrappers.BillingContract contract : contracts) {
                if (contract.isActiveContract()) {
                    isNotChanged = typeTerm == 'Initial' ? contract.term == Integer.valueOf(quote.Initial_Term_months__c) : contract.renewalTerm == Integer.valueOf(quote.Term_months__c);
                }
            }

            return String.valueOf(isNotChanged);
        }

        public Object isInitialAndRenewalTermsNotChanged(Object isInitialTermNotChanged, Object isRenewalTermNotChanged) {
            Boolean isNotChanged = true;
            if (Boolean.valueOf(isInitialTermNotChanged) == false || Boolean.valueOf(isRenewalTermNotChanged) == false) {
                isNotChanged = false;
            }
            return String.valueOf(isNotChanged);
        }

        public Map<String, Set<String>> IS_PROSERV_ENGAGED_FIELDS = new Map<String, Set<String>>{
            BASE_OBJECT_KEYWORD => new Set<String> {
                'Opportunity.EstimatedProfessionalServices12Month__c'
            }
        };
        public Object isProServEngaged(sObject baseObj) {
            Quote quote = (Quote) baseObj;

            return String.valueOf(OpportunityHelper.isProServEngaged(quote.Opportunity));
        }

        public Map<String, Set<String>> CURRENT_ITEM_SUBTOTAL_FIELDS = new Map<String, Set<String>>{
            LOOP_OBJ_KEYWORD => new Set<String>{
                'Last_Approved_Discount__c', 'Last_Approved_Quantity__c', 'Last_Approved_Discount_Type__c',
                'Approved_Discount__c', 'Approved_Quantity__c', 'Approved_Discount_Type__c',
                'UnitPrice', 'PackageInfo__c', 'Zero_Quantity__c', 'Quantity', 'EffectivePriceNew__c',
                'Entitlement__r.Quantity__c', 'Entitlement__r.EffectivePrice__c', 'Package_Info_QLI__c',
                'Package_Info__c'
            }
        };
        public Decimal currentItemSubtotal(sObject dataObj) {
            QuoteLineItem qli = (QuoteLineItem) dataObj;
            return QuoteLIneItemHelper.getCurrentTotal(qli);
        }

        public Map<String, Set<String>> DEPENDENT_ON_FEATURE_FIELDS = new Map<String, Set<String>>{
            LOOP_OBJ_KEYWORD => new Set<String>{
                'Product2.Feature__c', 'Product2.Dependent_on_Feature__c'
            }
        };
        public Object dependentOnFeature(
            sObject dataObj,
            String field,
            DataItem dataItem) {
            QuoteLineItem qli = (QuoteLineItem) dataObj;
            Decimal feature = qli.Product2.Dependent_on_Feature__c;
            if (feature == null) {
                return '';
            }
            QuoteLineItem target = null;
            for (QuoteLineItem q : (List<QuoteLineItem>) dataItem.dataList) {
                Decimal dFeature = q.Product2.Feature__c;
                if (feature == dFeature) {
                    target = q;
                    break;
                }
            }
            String result = '';
            if (target != null) {
                result = StringHelper.safeString(SFDescribeHelper.getSObjectField(target, field));
            }
            return result;
        }

        public Map<String, Set<String>> MONTHLY_SUBTOTAL_FIELDS = new Map<String, Set<String>>{
            BASE_OBJECT_KEYWORD => new Set<String>{
                'RecordTypeId', 'Pricebook2.Plan__c', 'Package_Info__c'
            },
            LOOP_OBJ_KEYWORD => new Set<String>{
                'Product__r.Family', 'Product__r.Charge_Term__c', 'ChargeTerm__c',
                'EffectivePrice__c', 'EffectivePricePrecise__c', 'DisplayQuantity__c', 'Account__c', 'PartnerConfig__c', 'Product__r.Feature__c', 'Price__c'
            }
        };
        public Object entMonthlySubtotal(sObject entSObj, Boolean isResellerPrice) {
            Entitlement__c ent = (Entitlement__c) entSObj;
            String terms = ((Entitlement__c) entSObj)?.ChargeTerm__c;
            Decimal effectivePricePrecise = isResellerPrice ? Decimal.ValueOf(entResellerPrice(entSObj)) : (Decimal) NumberHelper.getNumberNullSafe(ent?.EffectivePricePrecise__c);
            Decimal displayQuantity = (Decimal) NumberHelper.getNumberNullSafe(ent?.DisplayQuantity__c);

            switch on terms {
                when 'Annual' {
                    return (Object) ((effectivePricePrecise * displayQuantity) / 12);
                }
                when 'One - Time' {
                    return (Object) 0;
                }
                when else {
                    return (Object) (
                        (terms != null
                            && terms.containsIgnoreCase('Monthly'))
                            ? effectivePricePrecise * displayQuantity
                            : 0
                    );
                }
            }
        }

        public Map<String, Set<String>> SUM_MONTHLY_SUBTOTAL_FIELDS = MONTHLY_SUBTOTAL_FIELDS;
        public Object sumEntMonthlySubtotal(List<sObject> dataList, Boolean isResellerPrice) {
            Decimal sumMonthlySubtotal = 0;

            for (sObject entObj : dataList) {
                Object monthlySubtotalObj = entMonthlySubtotal(entObj, isResellerPrice);
                sumMonthlySubtotal += (Decimal) NumberHelper.getNumberNullSafe(monthlySubtotalObj);
            }
            return sumMonthlySubtotal;
        }

        public Map<String, Set<String>> ANNUAL_SUBTOTAL_FIELDS = new Map<String, Set<String>>{
            BASE_OBJECT_KEYWORD => new Set<String>{
                'RecordTypeId', 'Pricebook2.Plan__c', 'Package_Info__c'
            },
            LOOP_OBJ_KEYWORD => new Set<String>{
                'Product__r.Family', 'Product__r.Charge_Term__c', 'ChargeTerm__c',
                'EffectivePrice__c', 'EffectivePricePrecise__c', 'DisplayQuantity__c', 'Account__c', 'PartnerConfig__c', 'Product__r.Feature__c', 'Price__c'
            }
        };
        public Object entAnnualSubtotal(sObject entSObj, Boolean isResellerPrice) {
            Entitlement__c ent = (Entitlement__c) entSObj;
            String terms = ((Entitlement__c) entSObj)?.ChargeTerm__c;
            Decimal effectivePricePrecise = isResellerPrice ? Decimal.ValueOf(entResellerPrice(entSObj)) : (Decimal) NumberHelper.getNumberNullSafe(ent?.EffectivePricePrecise__c);
            Decimal displayQuantity = (Decimal) NumberHelper.getNumberNullSafe(ent?.DisplayQuantity__c);

            switch on terms {
                when 'Annual' {
                    return (Object) (effectivePricePrecise * displayQuantity);
                }
                when 'One - Time' {
                    return (Object) 0;
                }
                when else {
                    return (Object) (
                        (terms != null
                            && terms.containsIgnoreCase('Monthly'))
                            ? effectivePricePrecise * displayQuantity * 12
                            : 0
                    );
                }
            }
        }

        public Map<String, Set<String>> SUM_ANNUAL_SUBTOTAL_FIELDS = ANNUAL_SUBTOTAL_FIELDS;
        public Object sumEntAnnualSubtotal(List<sObject> dataList, Boolean isResellerPrice) {
            Decimal sumAnnualSubtotal = 0;

            for (sObject entObj : dataList) {
                Object annualSubtotalObj = entAnnualSubtotal(entObj, isResellerPrice);
                sumAnnualSubtotal += (Decimal) NumberHelper.getNumberNullSafe(annualSubtotalObj);
            }
            return sumAnnualSubtotal;
        }

        public Map<String, Set<String>> ONE_TIME_SUBTOTAL_FIELDS = new Map<String, Set<String>>{
            BASE_OBJECT_KEYWORD => new Set<String>{
                'RecordTypeId', 'Pricebook2.Plan__c', 'Package_Info__c'
            },
            LOOP_OBJ_KEYWORD => new Set<String>{
                'Product__r.Family', 'Product__r.Charge_Term__c', 'ChargeTerm__c',
                'EffectivePrice__c', 'EffectivePricePrecise__c', 'DisplayQuantity__c', 'Account__c'
            }
        };
        public Object entOneTimeSubtotal(sObject entSObj, Boolean isResellerPrice) {
            Entitlement__c ent = (Entitlement__c) entSObj;
            String terms = ((Entitlement__c) entSObj).ChargeTerm__c;
            Decimal effectivePricePrecise = isResellerPrice ? Decimal.ValueOf(entResellerPrice(entSObj)) : (Decimal) NumberHelper.getNumberNullSafe(ent.EffectivePricePrecise__c);
            Decimal displayQuantity = (Decimal) NumberHelper.getNumberNullSafe(ent.DisplayQuantity__c);

            return (Object) (
                (terms != null
                    && terms.equalsIgnoreCase('One - Time'))
                    ? effectivePricePrecise * displayQuantity
                    : 0
            );
        }

        public Map<String, Set<String>> SUM_ONE_TIME_SUBTOTAL_FIELDS = ONE_TIME_SUBTOTAL_FIELDS;
        public Object sumEntOneTimeSubtotal(List<sObject> dataList, Boolean isResellerPrice) {
            Decimal sumOneTimeSubtotal = 0;

            for (sObject entObj : dataList) {
                Object oneTimeSubtotalObj = entOneTimeSubtotal(entObj, isResellerPrice);
                sumOneTimeSubtotal += (Decimal) NumberHelper.getNumberNullSafe(oneTimeSubtotalObj);
            }
            return sumOneTimeSubtotal;
        }

        public Map<String, Set<String>> GOA_STATUS_FIELDS = new Map<String, Set<String>>{
            LOOP_OBJ_KEYWORD => new Set<String>{
                'Discount_number__c', 'Discount_type__c', 'EffectivePrice__c', 'EffectivePricenew__c',
                'Last_Approved_Discount__c', 'Last_Approved_Discount_Type__c', 'Last_Approved_Quantity__c',
                'ListPrice', 'NewQuantity__c', 'Quote.RecordType.Name', 'UnitPrice'
            }
        };

        public String goaStatus(sObject dataObj) {
            String goaStatus = '';
            if (dataObj instanceof QuoteLineItem) {
                QuoteLineItem qli = (QuoteLineItem) dataObj;

                Boolean isQuantityChanged = qli.Last_Approved_Quantity__c != null &&
                    NumberHelper.toNumber(qli.NewQuantity__c) != NumberHelper.toNumber(qli.Last_Approved_Quantity__c);

                // if DiscountType is empty - the default type 'Currency' should be used.
                String currentDiscountType = String.isEmpty(qli.Discount_type__c) ?
                    QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY : qli.Discount_type__c;
                String lastApprovedDiscountType = String.isEmpty(qli.Last_Approved_Discount_Type__c) ?
                    QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY : qli.Last_Approved_Discount_Type__c;

                Boolean isDiscountChanged = currentDiscountType != lastApprovedDiscountType
                    || NumberHelper.toNumber(qli.Discount_number__c) != NumberHelper.toNumber(qli.Last_Approved_Discount__c);

                if (isDiscountChanged && isQuantityChanged) {
                    goaStatus = 'Discount & Quantity Change';
                } else if (isDiscountChanged) {
                    goaStatus = 'Discount Change';
                } else if (isQuantityChanged) {
                    goaStatus = 'Quantity Change';
                } else {
                    Decimal currentEffectivePrice = (qli.Last_Approved_Discount__c == null) ? qli.UnitPrice : qli.EffectivePrice__c;
                    Decimal listPrice = (qli.Quote.RecordType.Name == QuoteHelper.RT_NAME_BILLING) ? qli.UnitPrice : qli.ListPrice;
                    if (NumberHelper.toNumber(currentEffectivePrice) == NumberHelper.toNumber(listPrice)) {
                        goaStatus = 'No Discount';
                    } else if (NumberHelper.toNumber(currentEffectivePrice).setScale(3, RoundingMode.HALF_UP)
                        == NumberHelper.toNumber(qli.EffectivePricenew__c).setScale(3, RoundingMode.HALF_UP))
                    {
                        goaStatus =  'Discount Approved';
                    }
                }
            }
            return goaStatus;
        }

        public String hierarchyLevel(SObject dataObj) {
            Integer level = qliIdToHierarchyLevel.get(dataObj.Id);
            return String.valueOf(level == null ? 0 : level);
        }

        public String hierarchyTotals(List<sObject> dataList) {
            Decimal total = 0;

            for (sObject obj : dataList) {
                if (qliIdToHierarchyLevel.get(obj.Id) == 0) {
                    QuoteLineItem qli = (QuoteLineItem) obj;
                    total += qli.EffectivePriceNew__c * qli.NewQuantity__c;
                }
            }

            return String.valueOf(total);
        }

        public Map<String, Set<String>> BUSINESS_IDENTITY_COUNTRY_FIELDS = new Map<String, Set<String>>{
            BASE_OBJECT_KEYWORD => new Set<String>{
                'Package_Info__c'
            }
        };

        public Map<String, Set<String>> PACKAGE_NAME_FIELDS_COUNTRY_FIELDS = new Map<String, Set<String>>{
            BASE_OBJECT_KEYWORD => new Set<String>{
                'Package_Info__c'
            }
        };

        public Map<String, Set<String>> SELECTED_PACKAGE_ID_FIELDS = new Map<String, Set<String>>{
            BASE_OBJECT_KEYWORD => new Set<String>{
                'Package_Info__c'
            }
        };

        public Map<String, Set<String>> ENGAGE_VOICE_PACKAGE_FIELDS = new Map<String, Set<String>>{
            BASE_OBJECT_KEYWORD => new Set<String>{
                'Account.BillingCountry'
            }
        };

        public Map<String, Set<String>> TARGET_PRICE_FIELDS = new Map<String, Set<String>>{
            BASE_OBJECT_KEYWORD => new Set<String>{
                'Account.Billing_ID__c', 'Account.RC_User_ID__c', 'RecordTypeId', 'Package_Info__c'
            }
        };

        public Map<String, Set<String>> IS_TERMINATED_FIELDS = new Map<String, Set<String>>{
            BASE_OBJECT_KEYWORD => new Set<String>{
                'IsTermination__c'
            }
        };

        public Map<String, Set<String>> CHANGE_TERM_FIELDS = new Map<String, Set<String>>{
            BASE_OBJECT_KEYWORD => new Set<String>{
                'Account.Billing_ID__c', 'Package_Info__c'
            }
        };
        // Country from approved business identity (approvedBi) on Package_Info__c
        public Object getApprovedBICountry(sObject baseObj) {
            Quote q = (Quote) baseObj;
            return QuoteHelper.getApprovedBICountryFromQuote(q);
        }

        public Object getOldPackageName(sObject baseObj) {
            Quote q = (Quote) baseObj;
            return QuoteHelper.getOldPackageNameFromQuote(q);
        }

        public Object getSelectedPackageId(sObject baseObj) {
            Quote q = (Quote) baseObj;
            return QuoteHelper.getPackageIdFromQuote(q);
        }

        public Object getNewPackageName(sObject baseObj) {
            Quote q = (Quote) baseObj;
            return QuoteHelper.getNewPackageNameFromQuote(q);
        }

        public List<String> getEngageVoicePackageIds(sObject baseObj) {
            Quote q = (Quote) baseObj;
            return getEngageVoicePackageIdsByCountry(q);
        }

        public Boolean isTargetPriceAvailable() {
            return QuoteHelper.isDQAndTPAvailable();
        }

        public Boolean isCCTerminated(sObject baseObj) {
            Quote q = (Quote) baseObj;
            return QuoteHelper.isServiceTerminated(q.Id, QuoteHelper.NGBS_RCCC_PRODUCT);
        }

        public Boolean isEngDTerminated(sObject baseObj) {
            Quote q = (Quote) baseObj;
            return QuoteHelper.isServiceTerminated(q.Id, QuoteHelper.NGBS_ENGAGE_DIGITAL_PRODUCT);
        }

        public Boolean isEngVTerminated(sObject baseObj) {
            Quote q = (Quote) baseObj;
            return QuoteHelper.isServiceTerminated(q.Id, QuoteHelper.NGBS_ENGAGE_VOICE_PRODUCT);
        }

        private List<String> getEngageVoicePackageIdsByCountry(sObject baseObj) {
            Quote q = (Quote) baseObj;
            List<String> engageVoicePackageIds = new List<String>();

            if (String.isBlank(q.Account.BillingCountry)) {
                return engageVoicePackageIds;
            }

            for (EngageVoiceListPackages__mdt pkgConfig: [SELECT Billing_Country__c, ListOfPackageIDs__c FROM EngageVoiceListPackages__mdt]) {
                if (pkgConfig.Billing_Country__c.contains(q.Account.BillingCountry)) {
                    engageVoicePackageIds = pkgConfig.ListOfPackageIDs__c.split(';');
                }
            }
            return engageVoicePackageIds;
        }
    }

    public class FormatterHelper {
        public Map<String, String> CURRENCY_MAP = new Map<String, String>{
            'USD' => '$', 'EUR' => '€', 'GBP' => '£', 'CAD' => 'CAD $', 'AUD' => 'AUD $'
        };

        /**
         *  Escape regexp reserved chars
         */
        public String escapeRegexpString(String text) {
            List <String> escapeStrings = new List<String>{
                '\\', '{', '}', '|', '(', ')', '?', '$', '[', ']', '+'
            };
            for (String c : escapeStrings) {
                text = text.replace(c, '\\' + c);
            }
            return text;
        }

        /**
         * Add string after value if it is not empty
         */
        public Object addAfter(Object textObj, List<Object> argsList) {
            String text = StringHelper.safeString(textObj);
            String addText = StringHelper.safeString(argsList.get(0));
            String result = String.isEmpty(text) ? '' : text + addText;
            return result;
        }

        /**
         * Add decimal value to current one. To subtract value - substractDecimal() should be used
         */
        public Object addDecimal(Object valObj, List<Object> argsList) {
            String curStr = String.valueOf(valObj);
            String addStr = (argsList != null && argsList.size() > 0 ? String.valueOf(argsList.get(0)) : null);
            Decimal curVal = String.isNotBlank(curStr) ? Decimal.valueOf(curStr) : 0;
            Decimal addVal = String.isNotBlank(addStr) ? Decimal.valueOf(addStr) : 0;
            return curVal + addVal;
        }

        /**
         * Multiply decimal value by current one
         */
        public Object multiplyDecimal(Object valObj, List<Object> argsList) {
            String curStr = String.valueOf(valObj);
            String mlpStr = (argsList != null && argsList.size() > 0 ? String.valueOf(argsList.get(0)) : null);
            Decimal curVal = String.isNotBlank(curStr) ? Decimal.valueOf(curStr) : 0;
            Decimal mlpVal = String.isNotBlank(mlpStr) ? Decimal.valueOf(mlpStr) : 0;
            return curVal * mlpVal;
        }

        /**
         * Divide decimal value by current one
         */
        public Object divideDecimal(Object valObj, List<Object> argsList) {
            String curStr = String.valueOf(valObj);
            String dvdStr = (argsList != null && argsList.size() > 0 ? String.valueOf(argsList.get(0)) : null);
            Decimal numerator = String.isNotBlank(curStr) ? Decimal.valueOf(curStr) : 0;
            Decimal denomerator = String.isNotBlank(dvdStr) ? Decimal.valueOf(dvdStr) : 0;
            return denomerator == 0 ? null : numerator / denomerator;
        }

        /**
         * Subtract decimal value to current one
         */
        public Object subtractDecimal(Object valObj, List<Object> argsList) {
            String curStr = String.valueOf(valObj);
            String addStr = (argsList != null && argsList.size() > 0 ? String.valueOf(argsList.get(0)) : null);
            Decimal curVal = String.isNotBlank(curStr) ? Decimal.valueOf(curStr) : 0;
            Decimal addVal = String.isNotBlank(addStr) ? Decimal.valueOf(addStr) : 0;
            return curVal - addVal;
        }

        /**
         *  Set scale for Decimal
         *  25.123 -> 25.1
         */
        public Object setScale(Object valObj, List<Object> argsList) {
            Object result = valObj;
            String valStr = String.valueOf(valObj);
            if (String.isNotBlank(valStr) && argsList.size() >= 1) {
                Decimal valToScale = Decimal.valueOf(valStr);
                Integer scale = Integer.valueOf(argsList.get(0));
                result = (Object) valToScale.setScale(scale).toPlainString();
            }
            return result;
        }

        /**
         *  Convert Number to Currency format
         *  1000000.00 -> $1,000,000.00
         */
        public Object asCurrency(Object valObj, sObject objToGetCurrency, List<Object> argsList) {
            String valStr = String.valueOf(valObj);
            if (String.isBlank(valStr)) {
                return valObj;
            }

            String minus = '';
            Decimal valDec = Decimal.valueOf(valStr);
            if(valDec < 0) {
                valObj = Math.abs(valDec);
                minus = '-';
            }

            String price = (String) asNumber(valObj, argsList);
            String sign = '';
            if (objToGetCurrency != null) {
                String currencyIsoCode = (String) objToGetCurrency.get('CurrencyIsoCode');
                sign = CURRENCY_MAP.get(currencyIsoCode);
                if (String.isBlank(sign)) {
                    sign = currencyIsoCode;
                }
            }

            String priceStr = minus + sign + price;
            return (Object) priceStr;
        }

        /**
         *  Convert Decimal to Number format
         *  1000000.00 -> 1,000,000.00
         *  1000000.000 -> 1,000,000.000
         *  asNumber() -> 1,000,000.00
         *  asNumber(-1) -> 1,000,000
         */
        public Object asNumber(Object valObj, List<Object> argsList) {
            Integer precision = 0;

            if(argsList.isEmpty()) {
                precision = 2;

            } else if (argsList.size() == 1) {
                precision = Integer.valueOf(argsList.get(0));
                if (precision < 0) {
                    precision = 0;
                }

            } else if (argsList.size() > 1) {
                return StringHelper.asNumber(valObj, Integer.valueOf(argsList[0]), Integer.valueOf(argsList[1]));
            }

            return StringHelper.asNumber(valObj, precision);
        }

        /**
         * @param argsList
         *              1. Type (equals, =, notEquals, !=, contains)
         *              2. Value to compare
         *              3. return value if true
         *              4. return value if false
         */
        public Object ifCondition(Object valObj, List<Object> argsList) {
            String val = StringHelper.safeString(valObj).toLowerCase();
            String compareWithString = '';
            Object compareWithObj = argsList.get(1);
            Set<String> compareWithSet = new Set<String>();
            Object trueValue;
            Object falseValue;
            Object returnValue = '';

            String type = String.valueOf(argsList.get(0));
            Boolean isCompareWithSet = compareWithObj instanceof List<Object>;

            if (isCompareWithSet) {
                List<Object> compareWithListObj = (List<Object>) argsList.get(1);
                for (Object strObj : compareWithListObj) {
                    String str = String.valueOf(strObj);
                    compareWithSet.add(str.toLowerCase());
                }
            } else if (compareWithObj != null) {
                compareWithString = String.valueOf(compareWithObj).toLowerCase();

            }

            trueValue = argsList.get(2);
            falseValue = (argsList.size() >= 4) ? argsList.get(3) : '';
            if (type.equalsIgnoreCase('equals') || type.equalsIgnoreCase('=')) {
                if (!(valObj instanceof String) && !(compareWithObj instanceof String)) {
                    returnValue = (valObj == compareWithObj) ? trueValue : falseValue;
                } else {
                    returnValue = val.equalsIgnoreCase(compareWithString.trim()) ? trueValue : falseValue;
                }
            } else if (type.equalsIgnoreCase('notEquals') || type.equalsIgnoreCase('!=')) {
                if (!(valObj instanceof String) && !(compareWithObj instanceof String)) {
                    returnValue = (valObj != compareWithObj) ? trueValue : falseValue;
                } else {
                    returnValue = !val.equalsIgnoreCase(compareWithString) ? trueValue : falseValue;
                }
            } else if (type.equalsIgnoreCase('contains')) {
                if (isCompareWithSet) {
                    returnValue = compareWithSet.contains(val) ? trueValue : falseValue;
                } else {
                    returnValue = val.containsIgnoreCase(compareWithString) ? trueValue : falseValue;
                }
            } else if (type.equalsIgnoreCase('notContains')) {
                if (isCompareWithSet) {
                    returnValue = !compareWithSet.contains(val) ? trueValue : falseValue;
                } else {
                    returnValue = !val.containsIgnoreCase(compareWithString) ? trueValue : falseValue;
                }
            } else if (type.equalsIgnoreCase('containsWordsExcept')) {
                String substring = val.replaceAll(compareWithString, '');
                Matcher matcher = Pattern.compile('[\\w]+').matcher(substring);
                String temp = '';
                while (matcher.find()) {
                    temp = StringHelper.safeString(matcher.group(0));
                    temp = temp.trim();
                }
                returnValue = temp.length() > 0 ? trueValue : falseValue;
            }
            return returnValue;
        }

        /**
         * Date formatting
         */
        public Object asDate(Object valObj, List<Object> argsList) {
            String formattedDate = StringHelper.safeString(valObj);
            if (String.isNotBlank(formattedDate)) {
                String formatStr = argsList.size() >= 1 ? String.valueOf(argsList.get(0)) : null;
                Boolean toFrench = false;
                String arg1 = argsList.size() >= 2 ? String.valueOf(argsList.get(1)) : null;
                if ('fr'.equalsIgnoreCase(arg1)) {
                    toFrench = true;
                }


                List<String> dateParts = formattedDate.substring(0, 10).split('-');
                Datetime dateInstance = Datetime.newInstance(
                    Integer.valueOf(dateParts[0]),
                    Integer.valueOf(dateParts[1]),
                    Integer.valueOf(dateParts[2]));

                if (String.isNotBlank(formatStr) && !'default'.equalsIgnoreCase(formatStr)) {
                    formattedDate = dateInstance.format(formatStr);
                } else {
                    if (toFrench) {
                        formattedDate = String.format('{0} {1} {2}', new List<String>{
                            dateInstance.format('d'),
                            dateInstance.format('MMMMM'),
                            dateInstance.format('yyyy')
                        });
                    } else {
                        formattedDate = String.format('{0} {1}<sup>{2}</sup>, {3}', new List<String>{
                            dateInstance.format('MMMMM'),
                            dateInstance.format('d'),
                            getDayOfMonthSuffix(dateInstance.day()),
                            dateInstance.format('yyyy')
                        });
                    }
                }

                if (toFrench) {
                    formattedDate = (String) translate(formattedDate, new List<Object>{
                        'months', 'fr'
                    });
                }
            }

            return formattedDate;
        }

        /**
         * Returns suffix for day of months
         * 1st, 2nd, 3rd, 4th...
         */
        private String getDayOfMonthSuffix(Integer n) {
            if (n == null) {
                return '';
            }

            if (n >= 11 && n <= 13) {
                return 'th';
            }

            Integer modResult = Math.mod(n, 10);
            if (modResult == 1) {
                return 'st';
            } else if (modResult == 2) {
                return 'nd';
            } else if (modResult == 3) {
                return 'rd';
            } else {
                return 'th';
            }
        }

        /**
         *  Returns singular or plural value depending on field Number
         *  @param argsList
         *              1. Singular Value
         *              1. Plural Value
         */
        public Object pluralize(Object valObj, List<Object> argsList) {
            String val = StringHelper.safeString(valObj);
            Boolean isPlural = true;

            if (val.length() > 0) {
                Decimal valDec = Decimal.valueOf(String.valueOf(valObj));
                Boolean isInteger = Integer.valueOf(valDec) == valDec;
                String lastDigit = val.substring(val.length() - 1, val.length());

                if (isInteger && lastDigit == '1') {
                    isPlural = false;
                }

            }

            Object singular = argsList.get(0);
            Object plural = argsList.get(1);

            return isPlural ? plural : singular;
        }

        /**
         * @param argsList
         *              1. Substring that will be replaced
         *              2. Replacing value
         */
        public Object rename(Object valObj, List<Object> argsList) {
            String prodName = StringHelper.safeString(valObj);
            String replaceWhat = (String) argsList.get(0);
            String replaceWith = (String) argsList.get(1);

            if (prodName.contains(replaceWhat)) {
                return Pattern.compile(replaceWhat).matcher(prodName).replaceAll(replaceWith);
            }

            return prodName;
        }

        public Object default(Object valObj, List<Object> argsList) {
            if (String.isEmpty(StringHelper.safeString(valObj))) {
                return argsList.get(0);
            } else {
                return valObj;
            }
        }

        /**
         *  Translate field to another language using
         *  predefined translation map
         */
        Map <String, Map <String, Map <String, String>>> FIELD_TRANSLATION = new Map <String, Map <String, Map <String, String>>>{
            'special_terms__c' => new Map <String, Map <String, String>>{
                'fr' => new Map <String, String>{
                    '2-day Shipping for Ground Pricing' => 'Livraison de 2 jours pour la tarification au sol',
                    'Free shipping' => 'Livraison gratuite',
                    '1 Free Week of Service' => '1 semaine gratuite de service',
                    'Free Weeks of Service' => 'semaines gratuites de service',
                    '1 Free Month of Service' => '1 mois gratuite de service',
                    'Free Months of Service' => 'mois gratuites de service',
                    '50% off service charge for the first 2 months of the contract' => '50% de frais de service pour les 2 premiers mois du contrat',
                    '50% off service charge for the first 3 months of the contract' => '50% de frais de service pour les 3 premiers mois du contrat'
                },
                'de' => new Map<String, String>{
                    '2-day Shipping for Ground Pricing' => '2-Tage-Versand für Ground Pricing',
                    'Free shipping' => 'Kostenloser Versand',
                    '1 Free Week of Service' => '1 semaine gratuite de service',
                    '1 Free Month of Service' => 'Monate von kostenlosen Leistungen',
                    'Free Weeks of Service' => 'Wochen von kostenlosen Leistungen',
                    '1 Free Month of Service' => '1 Monat von kostenlosen Leistungen',
                    'Free Months of Service' => 'Monate von kostenlosen Leistungen',
                    '50% off service charge for the first 2 months of the contract' => '50% Rabatt auf die Servicegebühr für die ersten 2 Monate der Vertragslaufzeit',
                    '50% off service charge for the first 3 months of the contract' => '50% Rabatt auf die Servicegebühr für die ersten 3 Monate der Vertragslaufzeit'

                }
            },
            'chargeterm__c' => new Map <String, Map <String, String>>{
                'fr' => new Map <String, String>{
                    'Monthly - Contract' => 'Mensuel - Contrat',
                    'Monthly' => 'Mensuel',
                    'Annual' => 'Annuel',
                    'One - Time' => 'Pré-payé'
                },
                'de' => new Map <String, String>{
                    'Monthly - Contract' => 'Monatlich - Vertrag',
                    'Monthly' => 'Monatlich',
                    'Annual' => 'Jährlich',
                    'One - Time' => 'Einmal'
                }
            },
            'payment_period__c' => new Map <String, Map <String, String>>{
                'fr' => new Map <String, String>{
                    'Monthly Payment Period' => 'Période de paiement mensuel',
                    'Annual Payment Period' => 'Période de paiement annuelle'
                },
                'de' => new Map <String, String>{
                    'Monthly Payment Period' => 'Monatlicher Zahlungszeitraum',
                    'Annual Payment Period' => 'Jährliche Zahlungsfrist'
                }
            },
            'months' => new Map <String, Map <String, String>>{
                'fr' => new Map <String, String>{
                    'January' => 'janvier',
                    'February' => 'février',
                    'March' => 'mars',
                    'April' => 'avril',
                    'May' => 'mai',
                    'June' => 'juin',
                    'July' => 'juillet',
                    'August' => 'août',
                    'September' => 'septembre',
                    'October' => 'octobre',
                    'November' => 'novembre',
                    'December' => 'décembre'
                },
                'de' => new Map <String, String>{
                    'January' => 'Januar',
                    'February' => 'Februar',
                    'March' => 'März',
                    'April' => 'April',
                    'May' => 'Kann',
                    'June' => 'Juni',
                    'July' => 'Juli',
                    'August' => 'August',
                    'September' => 'September',
                    'October' => 'Oktober',
                    'November' => 'November',
                    'December' => 'Dezember'
                }
            }
        };
        public Object translate(Object valObj, List<Object> argsList) {
            String fieldName = String.valueOf(argsList.get(0)).toLowerCase();
            String language = String.valueOf(argsList.get(1)).toLowerCase();
            String valStr = String.valueOf(valObj);
            Map <String, String> translationMap = FIELD_TRANSLATION.get(fieldName).get(language);
            for (String str : translationMap.keySet()) {
                valStr = valStr.replace(str, translationMap.get(str));
            }
            return valStr;
        }

        public Object wrap(Object valObj, List<Object> argsList) {
            String strToWrap = StringHelper.safeString(valObj);
            return String.isNotBlank(strToWrap)
                ?   StringHelper.safeString(argsList[0]) +
                    strToWrap +
                    StringHelper.safeString(argsList[argsList.size()-1])
                : strToWrap;
        }

        public Object asCurrencyOrPercentageString(Object valObj, sObject objToGetCurrency, List<Object> argsList) {
            if(argsList.isEmpty()) {
                // argsList MUST contains a [0] value to determine formatter to use.
                AquivaHelper.throwAquivaException('Type (currency/percentage) not specified.');
            }

            if(argsList.remove(0) == QuoteLineItemHelper.DISCOUNT_TYPE_PERCENTAGE) {
                return asNumber(valObj, argsList) + '%';
            } else {
                return asCurrency(valObj, objToGetCurrency, argsList);
            }
        }
    }


    // Fields required for PRODUCTS_STANDARD_SORT ordering
    public static Map<String, Set<String>> PRODUCTS_STANDARD_SORT_FIELDS = new Map<String, Set<String>>{
        'QuoteLineItem' => new Set<String>{
            'Product2.Family', 'Product2.Name', 'Product2.Dependent_On_Feature__c', 'Sort_Order__c'
        },
        'Entitlement__c' => new Set<String>{
            'Product__r.Family', 'Product__r.Name', 'Product__r.Dependent_On_Feature__c', 'Sort_Order__c'
        }
    };

    /**
     *  Custom sorting implementation
     *  @see {@link https://rc.my.salesforce.com/a2034000003puK6} B-2921 PDF Products Sorting
     */
    public class ProductTableItem implements Comparable {

        public String Family;
        public String Name;
        public Decimal DependentOnFeature;
        public object obj;

        private Decimal qliSortOrder;
        private Decimal entlSortOrder;

        // Constructor
        public ProductTableItem(String f, String n, Decimal d, object o) {
            this.Family = f;
            this.Name = n;
            this.DependentOnFeature = d;
            this.obj = o;

            QuoteLineItem thisQli = this.getQli(this);
            if(thisQli != null) {
                this.qliSortOrder = thisQli.Sort_Order__c;
            }

            Entitlement__c thisEntl = this.getEntl(this);
            if(thisEntl != null) {
                this.entlSortOrder = thisEntl.Sort_Order__c;
            }
        }

        // Implement the compareTo() method
        // 1. If QuoteLineItem/Entitlement__c has non empty Sort_Order__c - compare using this field
        // 2. Service
        // 3. Dependent on feature 17 Fees
        // 4. By Name ASC
        public Integer compareTo(Object compareTo) {

            ProductTableItem compareToProd = (ProductTableItem) compareTo;

            QuoteLineItem compareToQli = this.getQli(compareToProd);
            Entitlement__c compareToEntl = this.getEntl(compareToProd);

            Boolean isCompareToQliExist = (compareToQli != null && compareToQli.Sort_Order__c != null);
            Boolean isCompareToEntlExist = (compareToEntl != null && compareToEntl.Sort_Order__c != null);

            if(isCompareToQliExist && (this.entlSortOrder != null)) {
                return Integer.valueOf(compareToQli.Sort_Order__c - this.entlSortOrder);
            }else if(isCompareToEntlExist && (this.qliSortOrder != null)) {
                return Integer.valueOf(compareToEntl.Sort_Order__c - this.qliSortOrder);
            }

            if(isCompareToQliExist && (this.qliSortOrder != null)) {
                return Integer.valueOf(compareToQli.Sort_Order__c - this.qliSortOrder);
            }

            if(isCompareToEntlExist && (this.entlSortOrder != null)) {
                return Integer.valueOf(compareToEntl.Sort_Order__c - this.entlSortOrder);
            }

            Boolean isAService = Product2Helper.FAMILY_SERVICE.equalsIgnoreCase(this.Family);
            Boolean isAFee = this.DependentOnFeature == Product2Helper.FEATURE_SERVICE_PLAN;

            Boolean isBService = Product2Helper.FAMILY_SERVICE.equalsIgnoreCase(compareToProd.Family);
            Boolean isBFee = compareToProd.DependentOnFeature == Product2Helper.FEATURE_SERVICE_PLAN;

            if (isAService == isBService && isAFee == isBFee) {
                return compareToProd.Name.compareTo(this.Name);
            }
            if (isAService) {
                return 1;
            }
            if (isBService) {
                return -1;
            }
            if (isAFee) {
                return 1;
            }
            return -1;
        }

        private QuoteLineItem getQli(ProductTableItem item) {
            QuoteLineItem result = null;

            if(item == null || item.obj == null) {
                return result;
            }

            if(item.obj instanceof ChangeOrderItem) {
                ChangeOrderItem coi = (ChangeOrderItem) item.obj;
                if(coi.QuoteLineItem != null) {
                    result = (QuoteLineItem) coi.QuoteLineItem;
                }
            }else if(item.obj instanceof QuoteLineItem) {
                result = (QuoteLineItem) item.obj;
            }

            return result;
        }

        private Entitlement__c getEntl(ProductTableItem item) {
            Entitlement__c result = null;

            if(item == null || item.obj == null) {
                return result;
            }

            if(item.obj instanceof ChangeOrderItem) {
                ChangeOrderItem coi = (ChangeOrderItem) item.obj;
                if(coi.Entitlement != null) {
                    result = (Entitlement__c) coi.Entitlement;
                }
            }else if(item.obj instanceof Entitlement__c) {
                result = (Entitlement__c) item.obj;
            }

            return result;
        }
    }
}