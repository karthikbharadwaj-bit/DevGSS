public class ObjectCache {
    /**
    * An partition name to store varaious things in the cache 
    */
    public enum Partition {QUERIES, FACTORIES, MISC}

    /**
    * A static map represents the cache, exists for the execution context  
    */
    public static Map<ObjectCache.Partition, Map<String, Object>> objectCacheMap {
        get {
            if (objectCacheMap == null) {
                objectCacheMap = new Map<ObjectCache.Partition, Map<String, Object>>();
            }
            return objectCacheMap;
        }
        private set;
    }

    /**
    * Check if the cache contains specified partition specified in {@link #Partition}
    * @param part a ObjectCache.Partition used to split the cache by the physical meaning
    */
    public static Boolean containsPartition(ObjectCache.Partition part) {
        return objectCacheMap.containsKey(part);
    }

    /**
    * Check if the cache partition contains specified key, like the name of SOQL query
    * @param part a ObjectCache.Partition used to split the cache by the physical meaning
    * @param key a String used to identify the name of the object in the concrete partition
    */
    public static Boolean containsKey(ObjectCache.Partition part, String key) {
        return containsPartition(part) && objectCacheMap.get(part).containsKey(key);
    }

    /**
    * Sets the value to concrete key in the specified partition
    * @param part a ObjectCache.Partition used to split the cache by the physical meaning
    * @param key a String used to identify the name of the object in the concrete partition
    * @param value a Object represents the value to set up
    */
    public static void set(ObjectCache.Partition part, String key, Object value) {
        if (!objectCacheMap.containsKey(part)) {
            objectCacheMap.put(part, new Map<String, Object>());
        }
        objectCacheMap.get(part).put(key, value);
    }

    /**
    * Get the value from the concrete key in the specified partition
    * @param part a ObjectCache.Partition used to split the cache by the physical meaning
    * @param key a String used to identify the name of the object in the concrete partition
    */
    public static Object get(ObjectCache.Partition part, String key) {
        if (!containsKey(part, key)) {
            return null;
        }
        return objectCacheMap.get(part).get(key);
    }

    /**
    * Clears the specified the key from the cahce partition 
    * @param part a ObjectCache.Partition used to split the cache by the physical meaning
    * @param key a String used to identify the name of the object in the concrete partition
    */
    public static void removeKey(ObjectCache.Partition part, String key) {
        if (containsKey(part, key)) {
            objectCacheMap.get(part).remove(key);
        }
    }
}