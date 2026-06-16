@IsTest
private class Test_SObjectCache {
    private static final SObjectCache.UserCacheSelector CACHE_SELECTOR = new SObjectCache.UserCacheSelector();
    private static final QueryFactory CACHE_FACTORY = CACHE_SELECTOR.selectRecords();
    private static final String CACHE_FACTORY_NAME = CACHE_FACTORY.getFactoryName();

    private class Mock_CacheStorage extends SObjectCache.CacheStorage {
        public Mock_CacheStorage() {
            this.sObjectType = User.getSObjectType();
            this.cacheSelector = CACHE_SELECTOR;
        }
    }

    @IsTest
    private static void test_CacheStorage() {
        Test.startTest();
        SObjectCache.CacheStorage cs = new Mock_CacheStorage();
        Test.stopTest();

        System.assert(
            cs.getSObjectType() == User.getSObjectType(),
            String.format(
                'initialized with correct type: {0} == {1}',
                new List<Object>{
                    cs.getSObjectType(), User.getSObjectType()
                }
            )
        );

        System.assert(
            cs.getCacheSelector().selectRecords().getFactoryName() == CACHE_FACTORY_NAME,
            String.format(
                'initialized with correct query factory: {0} == {1}',
                new List<Object>{
                    cs.getCacheSelector().selectRecords().getFactoryName(), CACHE_FACTORY_NAME
                }
            )
        );
        System.assert(
            cs.getCacheSelector().selectRecords().sObjType == cs.getSObjectType(),
            String.format(
                'initialized with match SObjectTypes on QueryFactory and CacheStorage: {0} == {1}',
                new List<Object>{
                    cs.getCacheSelector().selectRecords().sObjType, cs.getSObjectType()
                }
            )
        );
    }

    @IsTest
    private static void test_CacheStorage_initialize() {
        Test.startTest();

        SObjectCache c = new SObjectCache();
        SObjectCache.CacheStorage cs = new Mock_CacheStorage();
        cs.initialize(c);

        Test.stopTest();

        System.assert(
            cs.getCacheInstance() == c,
            String.format(
                'correct SObjectCache instance is set: {0} == {1}',
                new List<Object>{
                    cs.getCacheInstance(), c
                }
            )
        );
        System.assert(
            cs.isInitialized == true,
            String.format(
                'isInitialized flag is set to true: {0}',
                new List<Object>{
                    cs.isInitialized()
                }
            )
        );
    }

    @IsTest
    private static void test_CacheStorage_retrieveSingle() {

        Test.startTest();

        SObjectCache c = new SObjectCache();
        SObjectCache.CacheStorage cs = new Mock_CacheStorage();

        cs.initialize(c);

        User u = (User) cs.retrieveSingle(UserInfo.getUserId());
        User u2 = (User) cs.retrieveSingle((Id) ValueProviderBuilder.provideDummyId(User.getSObjectType()).getValue());

        Test.stopTest();

        System.assert(
            u.Id == UserInfo.getUserId(),
            'Retrieved user with correct id from cache'
        );

        System.assert(
            u2 == null,
            'Did not retrieved user with random id'
        );
    }
    @IsTest
    private static void test_CacheStorage_retrieve() {

        User user1 = TestDataFactory.createUser('User1');
        User user2 = TestDataFactory.createUser('User2');

        Test.startTest();

        SObjectCache c = new SObjectCache();
        SObjectCache.CacheStorage cs = new Mock_CacheStorage();

        cs.initialize(c);

        Set<Id> userIdsToRetrieve = new Set<Id>{
            UserInfo.getUserId(), user2.Id
        };
        Map<Id, SObject> cacheUsers = new Map<Id, SObject>(
            new List<SObject>(cs.retrieve(userIdsToRetrieve))
        );

        Test.stopTest();

        System.assert(
            !cacheUsers.isEmpty(),
            String.format(
                'cached user list is not empty: {0}',
                new List<Object>{
                    cacheUsers.size()
                }
            )
        );

        User cacheCurrentUser = (User) cacheUsers.get(UserInfo.getUserId());

        System.assert(
            cacheCurrentUser.Username == UserInfo.getUserName(),
            String.format(
                'match Username field on retrieved User and current User: {0} == {1}',
                new List<Object>{
                    cacheCurrentUser.Username, UserInfo.getName()
                }
            )
        );

        System.assert(
            cs.isCacheContains(UserInfo.getUserId()),
            String.format(
                'lastLoadedIds contains Id of user {0} ({1}): {2}',
                new List<Object>{
                    UserInfo.getUserName(), UserInfo.getUserId(), cs.getLastLoadedIds()
                }
            )
        );

        System.assert(
            cs.isCacheContains(user2.Id),
            String.format(
                'lastLoadedIds contains Id of user {0} ({1}): {2}',
                new List<Object>{
                    user2.Username, user2.Id, cs.getLastLoadedIds()
                }
            )
        );

        System.assert(
            !cs.getLastLoadedIds().contains(user1.Id),
            String.format(
                'lastLoadedIds does not contain Id of user {0} ({1}): {2}',
                new List<Object>{
                    user1.Username, user1.Id, cs.getLastLoadedIds()
                }
            )
        );

        cs.retrieve(new List<Id> { user1.Id, user2.Id });
        cs.retrieve(new Set<Id> { user1.Id, user2.Id });
        cs.retrieveList(new List<Id> { user1.Id, user2.Id });
        cs.retrieveList(new Set<Id> { user1.Id, user2.Id });
    }

    @IsTest
    private static void test_SObjectCache_addStorage_getStorage_isStorageExists() {
        Test.startTest();
        SObjectCache c = new SObjectCache().addStorage(new Mock_CacheStorage());
        Test.stopTest();

        Boolean exists = c.isStorageExists(User.getSObjectType());
        System.assert(exists, String.format('cache storage exists in cache: {0}', new List<Object>{
            exists
        }));

        SObjectCache.ICacheStorage storage = c.getStorage(User.getSObjectType());
        System.assert(storage != null, String.format('valid cache storage retrieved: {0}', new List<Object>{
            storage
        }));
        System.assert(!storage.isInitialized(), String.format('storage is not initialized: {0}', new List<Object>{
            storage.isInitialized()
        }));
    }

    @IsTest
    private static void test_SObjectCache_initStorages() {
        Test.startTest();
        SObjectCache c = new SObjectCache().addStorage(new Mock_CacheStorage())
            .initStorage();
        Test.stopTest();

        System.assert(
            c.getStorage(User.getSObjectType()).isInitialized(),
            String.format('storage was initialized: {0}', new List<Object> { c.getStorage(User.getSObjectType()).getSObjectType()} )
        );
    }
}