public class SObjectCache {

    private static final String ERROR_PARAMETER_INVALID_MISSING = 'Invalid or missing value for parameter \'{0}\': {1}';
    private static final String ERROR_PARAMETER_DEPENDENT_INVALID_MISSING = 'Invalid or missing value for parameter \'{0}\' depending on \'{1}\': {2}';
    private static final String ERROR_FIELD_NOT_EXIST = 'Field \'{0}\' does not exist on SObject \'{1}\'';
    private static final String ERROR_PARENT_FIELD_NOT_EXIST = 'Field \'{0}\' does not exist on \'{2}\'\'s (grand-)parent SObject \'{1}\'';
    private static final String ERROR_INVALID_SELECTOR_TYPE_MISMATCH = 'Invalid QueryFactory - SObjectType mismatch: \'{0}\' != \'{1}\'';
    private static final String ERROR_CACHE_STORAGE_EXISTS = 'CacheStorage already defined for {0} sObjectType';
    public abstract class ESObjectCacheException extends Exception {
    }

    public class EInvalidParameterException extends ESObjectCacheException {
        public EInvalidParameterException(String p, Object v) {
            this(String.format(ERROR_PARAMETER_INVALID_MISSING, new List<Object>{
                p, v?.toString()
            }));
        }
    }
    public class EInvalidDependingParameterException extends ESObjectCacheException {
        public EInvalidDependingParameterException(String d, String p, Object v) {
            this(String.format(ERROR_PARAMETER_DEPENDENT_INVALID_MISSING, new List<Object>{
                d, p, v?.toString()
            }));
        }
    }
    public class EFieldNotExistException extends ESObjectCacheException {
        public EFieldNotExistException(String sObjectName, Object fieldFQName) {
            this(String.format(ERROR_FIELD_NOT_EXIST, new List<Object>{
                fieldFQName, sObjectName
            }));
        }
    }
    public class EFieldNotExistOnParentException extends ESObjectCacheException {
        public EFieldNotExistOnParentException(String baseSObject, String relatedSObject, String fieldFQName) {
            this(String.format(ERROR_PARENT_FIELD_NOT_EXIST, new List<Object>{
                fieldFQName, relatedSObject, baseSObject
            }));
        }
    }

    public class EInvalidSelectorTypeMismatchException extends ESObjectCacheException {
        public EInvalidSelectorTypeMismatchException(String sObjectName, ICacheSelector selector) {
            this(String.format(ERROR_INVALID_SELECTOR_TYPE_MISMATCH, new List<Object>{
                sObjectName, selector.getSObjectType()
            }));
        }
    }

    public class EStorageAlreadyDefinedForObjectException extends ESObjectCacheException {
        public EStorageAlreadyDefinedForObjectException(ICacheStorage storage) {
            this(String.format(ERROR_CACHE_STORAGE_EXISTS, new List<Object>{
                storage.getSObjectType().getDescribe().getName()
            }));
        }
    }

    private final Map<SObjectType, ICacheStorage> STORAGES = new Map<SObjectType, ICacheStorage>();
    public SObjectCache addStorage(ICacheStorage csd) {
        if (csd == null) {
            throw new EInvalidParameterException('csd', csd);
        }

        SObjectType sObjectType = csd.getSObjectType();
        if (this.isStorageExists(sObjectType)) {
            throw new EStorageAlreadyDefinedForObjectException(csd);
        }

        this.STORAGES.put(sObjectType, csd);

        return this;
    }

    public ICacheStorage getStorage(SObjectType forType) {
        if (!this.STORAGES.containsKey(forType)) {
            throw new SObjectException();
        }

        return this.STORAGES.get(forType);
    }

    public Boolean isStorageExists(SObjectType sObjectType) {
        return this.STORAGES.containsKey(sObjectType);
    }

    public SObjectCache initStorage() {
        for (ICacheStorage cs : this.STORAGES.values()) {
            cs.initialize(this);
        }

        return this;
    }

    public interface ICacheStorage {
        void initialize(SObjectCache cacheInstance);
        void load(Set<Id> records);
        void load(List<Id> records);
        Set<SObject> retrieve(Set<Id> recordIds);
        List<SObject> retrieveList(Set<Id> recordIds);
        SObject retrieveSingle(Id recordId);
        SObjectType getSObjectType();
        Boolean isInitialized();
    }

    public abstract class AbstractCacheStorage {
        protected SObjectType sObjectType {
            get;
            set {
                if (value == null) {
                    throw new EInvalidParameterException('sObjectType', value);
                }

                this.sObjectType = value;
            }
        }

        protected SObjectCache cacheInstance {
            get;
            set {
                if (value == null) {
                    throw new EInvalidParameterException('cacheInstance', value);
                }

                this.cacheInstance = value;
            }
        }

        protected ICacheSelector cacheSelector {
            get;
            protected set {
                if (value == null) {
                    throw new EInvalidParameterException('cacheSelector', value);
                }

                if (this.sObjectType != null) {
                    if (this.sObjectType != value.getSObjectType()) {
                        throw new EInvalidSelectorTypeMismatchException(
                            this.sObjectType.getDescribe().getName(),
                            value
                        );
                    }
                } else {
                    this.sObjectType = value.getSObjectType();
                }

                this.cacheSelector = value;
            }
        }


        public Set<String> indexFields {
            get;
            set {
                this.indexFields = value != null ? value : new Set<String>();
            }
        }

        public Boolean isInitialized {
            get {
                return this.sObjectType != null
                    && this.cacheInstance != null
                    && this.cacheSelector != null;
            }
        }

        public Set<Id> lastLoadedIds {
            get;
            protected set {
                this.lastLoadedIds = value != null ? value : new Set<Id>();
            }
        }

        private final Map<Id, SObject> OBJECT_CACHE = new Map<Id, SObject>();
        public virtual void initialize(
            SObjectCache cacheObj,
            ICacheSelector selector,
            Set<String> indexFieldSet
        ) {
            cacheInstance = cacheObj;
            cacheSelector = selector;
            indexFields = indexFieldSet;

            this.OBJECT_CACHE.clear();
        }

        protected Map<Id, SObject> getCache() {
            return new Map<Id, SObject>(OBJECT_CACHE);
        }

        protected Integer getCacheSize() {
            return this.OBJECT_CACHE.size();
        }

        private Set<Id> getRecordIdsToLoad(Set<Id> recordIds) {
            Set<Id> idsToFilter = new Set<Id>(recordIds);
            Set<Id> result = new Set<Id>();

            if (this.OBJECT_CACHE.isEmpty()) {
                return idsToFilter;
            }

            for (Id objectId : idsToFilter) {
                if (!this.OBJECT_CACHE.containsKey(objectId)) {
                    result.add((objectId));
                }
            }

            return result;
        }

        public ICacheSelector getCacheSelector() {
            return this.cacheSelector;
        }

        public SObjectCache getCacheInstance() {
            return this.cacheInstance;
        }

        public Set<Id> getLastLoadedIds() {
            return this.lastLoadedIds;
        }

        public Boolean isInitialized() {
            return this.isInitialized;
        }

        public Boolean isCacheContains(Id recordId) {
            return this.getCache().containsKey(recordId);
        }

        public void load(Id recordId) {
            this.load(new Set<Id>{
                recordId
            }, false);
        }

        public void load(List<Id> recordIds) {
            this.load(new Set<Id>(recordIds), false);
        }

        public void load(Set<Id> recordIds) {
            this.load(recordIds, false);
        }

        public void load(Set<Id> recordIds, Boolean skipCacheCheck) {
            Set<Id> objectIdsToLoad = skipCacheCheck ? new Set<Id>(recordIds) : this.getRecordIdsToLoad(recordIds);

            if (objectIdsToLoad.isEmpty()) {
                return;
            }

            QueryFactory f = this.getCacheSelector().selectRecords();

            f.altCondition('Id IN ' + f.nextBindingPlaceholder())
                .addQueryBindings(new List<Object>{
                    objectIdsToLoad
                });

            this.store(f.executeQuery());
        }

        public void store(List<SObject> records) {
            Map<Id, SObject> loadedRecords = new Map<Id, SObject>(records);

            this.OBJECT_CACHE.putAll(loadedRecords);
            this.lastLoadedIds = loadedRecords.keySet();
        }

        public SObject retrieveSingle(Id recordId) {
            List<SObject> result = this.retrieveList(
                recordId != null ? new Set<Id>{
                    recordId
                } : new Set<Id>()
            );
            return !result.isEmpty() ? result.get(0) : null;
        }

        public List<SObject> retrieveList(List<Id> recordIds) {
            return this.retrieveList(new Set<Id>(recordIds != null ? recordIds : new List<Id>()));
        }

        public List<SObject> retrieveList(Set<Id> recordIds) {
            return new List<SObject>(this.retrieve(recordIds));
        }

        public Set<SObject> retrieve(List<Id> recordIds) {
            return this.retrieve(recordIds != null ? new Set<Id>(recordIds) : new Set<Id>());
        }

        public Set<SObject> retrieve(Set<Id> recordIds) {
            Set<SObject> result = new Set<SObject>();

            if (recordIds == null || recordIds.isEmpty()) {
                return result;
            }

            this.load(recordIds);

            for (Id objectId : recordIds) {
                if (this.OBJECT_CACHE.containsKey(objectId)) {
                    result.add(this.OBJECT_CACHE.get(objectId));
                }
            }

            return result;
        }
    }

    public abstract class CacheStorage extends AbstractCacheStorage implements ICacheStorage {
        public virtual void initialize(SObjectCache cacheInstance) {
            super.initialize(cacheInstance, this.cacheSelector, new Set<String>());
        }

        public SObjectType getSObjectType() {
            return this.sObjectType;
        }
    }

    public interface ICacheSelector {
        QueryFactory prefetchRecords();
        QueryFactory selectRecords();
        SObjectType getSObjectType();
    }

    public class UserCacheSelector extends SObjectSelector implements ICacheSelector {
        private final Set<String> STANDARD_FIELDS = new Set<String>{
            'Id', 'IsActive', 'UserType', 'Username', 'Name', 'FirstName',
            'LastName', 'Title', 'Division', 'Email', 'Phone', 'EmployeeNumber',
            'DefaultCurrencyIsoCode', 'Department'
        };

        private final Set<String> CUSTOM_FIELDS = new Set<String>{
            'PID__c', 'Team__c', 'UserRoleName__c', 'Systems_Integration_Users__c',
            'SegmentPicklist__c', 'Upmarket_Territory__c', 'IsTmtTriggersDisabled__c',
            'Mkto_Reply_Email__c', 'Hold_Out_List__c', 'Implementation_Dispatcher__c',
            'Channel__c', 'Manager_Id__c', 'Manager_Manager_ID__c', 'Hierarchy_Role__c'
        };

        private final Set<String> CONTACT_FIELDS = new Set<String>{
            'Contact.Id', 'Contact.Name', 'Contact.RecordTypeId'
        };

        private final Set<String> CONTACT_ACCOUNT_FIELDS = new Set<String>{
            'Contact.Account.Id', 'Contact.Account.Name',
            'Contact.Account.RecordTypeId', 'Contact.Account.IsPartner',
            'Contact.Account.Partner_ID__c', 'Contact.Account.Permitted_Brands__c'
        };

        private final Set<String> PROFILE_FIELDS = new Set<String>{
            'Profile.Id', 'Profile.Name'
        };

        private final Set<String> USER_ROLE_FIELDS = new Set<String>{
            'UserRole.Id', 'UserRole.Name', 'UserRole.PortalRole'
        };

        private final List<Set<String>> MANAGER_FIELD_SETS = new List<Set<String>>{
            STANDARD_FIELDS,
            CUSTOM_FIELDS
        };

        private final Set<String> MANAGER_FIELDS {
            get {
                if (this.MANAGER_FIELDS == null) {
                    Set<String> managerFields = new Set<String>();
                    String relName = 'Manager';

                    for (Set<String> fieldSet : MANAGER_FIELD_SETS) {
                        for (String fsField : fieldSet) {
                            managerFields.add(
                                String.format('{0}.{1}', new List<Object>{
                                    relName, fsField
                                })
                            );
                        }
                    }

                    this.MANAGER_FIELDS = managerFields;
                }

                return this.MANAGER_FIELDS;
            }
            set {
                this.MANAGER_FIELDS = value;
            }
        }

        private final Integer MANAGER_HIERARCHY_DEPTH = 3;

        protected final Set<String> MANAGER_HIERARCHY_FIELDS {
            get {
                if (this.MANAGER_HIERARCHY_FIELDS == null) {
                    Set<String> managerFields = new Set<String>();
                    switch on MANAGER_HIERARCHY_DEPTH {
                        when 0 {
                            managerFields = new Set<String>();
                        }
                        when 1 {
                            managerFields = new Set<String>(this.MANAGER_FIELDS);
                        }
                        when else {
                            managerFields = new Set<String>(this.MANAGER_FIELDS);
                            String prefix = 'Manager';
                            for (Integer i = 0; i < MANAGER_HIERARCHY_DEPTH - 1; i++) {
                                prefix = String.format('{0}.{1}', new List<Object> { prefix, 'Manager' });
                                for (String f: this.MANAGER_FIELDS) {
                                    managerFields.add(String.format('{0}.{1}', new List<Object> { prefix, f } ));
                                }
                            }
                        }
                    }

                    this.MANAGER_HIERARCHY_FIELDS = managerFields;
                }

                return this.MANAGER_HIERARCHY_FIELDS;
            }
            set {
                if (value == null) {
                    this.MANAGER_HIERARCHY_FIELDS = new Set<String>(this.MANAGER_FIELDS);
                } else {
                    this.MANAGER_HIERARCHY_FIELDS = value;
                }
            }
        }

        private final Set<Id> prefetchWithIds = new Set<Id> {
            UserInfo.getUserId()
        };

        private final Set<String> prefetchWithNames = new Set<String> {
            'LAR System User',
            'DO NOT CONTACT - VAR',
            'LeanData Queue',
            'User Marketo',
            'RCSF Sync',
            'RC Support Agent',
            'D&B Credit Check'
        };

        private final Set<String> prefetchWithProfileNames = new Set<String> {
            'System Administrator'
        };

        public UserCacheSelector() {
            super();
        }

        public UserCacheSelector(Boolean enforceCRUD, Boolean enforceFLS) {
            super(enforceCRUD, enforceFLS);
        }

        public override SObjectType getSObjectType() {
            return User.getSObjectType();
        }

        public override List<SObjectField> getDefaultFieldList() {
            return new List<SObjectField>{
                User.Id
            };
        }

        public List<String> getDemandFunnelRequestFields() {
            return new List<String>(FieldMappingEngine.collectSourceFieldsForObject(getSObjectType().getDescribe().getName()));
        }

        public QueryFactory prefetchRecords() {
            QueryFactory qf = this.selectRecords();

            if (!this.prefetchWithIds.isEmpty()) {
                qf.altCondition('Id IN ' + qf.nextBindingPlaceholder())
                    .addQueryBindings(new List<Object> { prefetchWithIds });
            }

            if (!this.prefetchWithNames.isEmpty()) {
                qf.altCondition('Name IN ' + qf.nextBindingPlaceholder())
                    .addQueryBindings(new List<Object> { prefetchWithNames });
            }

            if (!this.prefetchWithProfileNames.isEmpty()) {
                qf.altCondition('Profile.Name IN ' + qf.nextBindingPlaceholder())
                    .addQueryBindings(new List<Object> { prefetchWithProfileNames });
            }

            return qf;
        }

        public QueryFactory selectRecords() {
            QueryFactory qf = newQueryFactory()
                .setFactoryName('selectUsersForCaching')
                .selectFields(getDemandFunnelRequestFields())
                .selectFields(STANDARD_FIELDS)
                .selectFields(CUSTOM_FIELDS)
                .selectFields(CONTACT_FIELDS)
                .selectFields(CONTACT_ACCOUNT_FIELDS)
                .selectFields(USER_ROLE_FIELDS)
                .selectFields(PROFILE_FIELDS)
                .selectFields(MANAGER_HIERARCHY_FIELDS)
                .subselect(new EmployeeSelector().selectEmployeeForDFR())
                .addOrdering('CreatedDate', QueryFactory.SortOrder.DESCENDING)
                .addOrdering('Name', QueryFactory.SortOrder.ASCENDING)
                .withSelectFieldsSorted()
                .withoutSelectorOrderByIncluded();

            return qf;
        }
    }

    public class UserCacheStorage extends CacheStorage {
        public UserCacheStorage() {
            this.sObjectType = User.getSObjectType();
            this.cacheSelector = new UserCacheSelector();
        }

        public User getCurrentUser() {
            return (User) this.retrieveSingle(UserInfo.getUserId());
        }
    }
}