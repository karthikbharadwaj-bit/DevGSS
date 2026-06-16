public class Triggers {
    private static final SObjectCache CACHE = new SObjectCache();
    private static Map<Type, Set<Triggers.Evt>> excludedHandlers = new Map<Type, Set<Triggers.Evt>>();

    private class ECacheUnavailableTriggerNotExecutingException extends Exception {}

    static {
        Triggers.CACHE.addStorage(new SObjectCache.UserCacheStorage());
    }

    public static SObjectCache.ICacheStorage getCacheStorage(SObjectType sObjectType) {
        if (!Trigger.isExecuting) {
            throw new ECacheUnavailableTriggerNotExecutingException();
        }

        return CACHE.getStorage(sObjectType);
    }

    /**
    *	Ability to shut down all handlers
    */
    private static Boolean isExecute = true;
    public static void switchOff() {
        System.debug('Trigger handler execution globally disabled');
        excludedHandlers.clear();
        isExecute = false;
    }
    public static void switchOn() {
        System.debug('Trigger handler execution globally enabled');
        excludedHandlers.clear();
        isExecute = true;
    }

    /**
    *	Enum representing each of before/after CRUD events on Sobjects
    */
    public enum Evt {
        afterdelete, afterinsert, afterundelete,
        afterupdate, beforedelete, beforeinsert, beforeupdate
    }

    /**
    *	Simplistic handler to implement on any of the event. It doesn't requires or enforces any patter except the
    *	method name to be "handle()", a developer is free to use any Trigger context variable or reuse any other
    *	apex class here.
    */
    public interface Handler {
        void handle();
        Boolean bypass();
    }

    // Internal mapping of handlers
    private Map<String, List<Handler>> eventHandlerMapping = new Map<String, List<Handler>>();

    public static void except(Map<String, Set<Evt>> excludedEventsByHandlers) {
        for(String handlerTypeName : excludedEventsByHandlers.keySet()) {
            Type handlerType = Type.forName(handlerTypeName);
            Set<Evt> eventsToExclude = excludedEventsByHandlers.get(handlerTypeName);
            if(eventsToExclude == null || eventsToExclude.isEmpty()) {
                eventsToExclude = new Set<Triggers.Evt>{
                    Evt.beforeinsert, Evt.beforeupdate, Evt.beforedelete,
                    Evt.afterinsert, Evt.afterupdate, Evt.afterupdate, Evt.afterundelete
                    };
            }
            excludedHandlers.put(handlerType, eventsToExclude);
        }
    }

    public static void except(String handlerType, Set<Evt> eventsSet) {
        except(new Map<String, Set<Evt>> { handlerType => eventsSet });
    }

    public static void except(String handlerType) {
        except(new Map<String, Set<Evt>> { handlerType => new Set<Evt>() });
    }

    /**
    *	Core API to bind handlers with events
    */
    public Triggers bind(Evt event, Handler eh) {
        List<Handler> handlers = eventHandlerMapping.get(event.name());
        if (handlers == null) {
            handlers = new List<Handler>();
            eventHandlerMapping.put(event.name(), handlers);
        }
        handlers.add(eh);
        return this;
    }

    /**
    *	Invokes correct handlers as per the context of trigger and available registered handlers
    */
    public void manage() {
        Evt ev = null;
        if(Trigger.isInsert && Trigger.isBefore){
            ev = Evt.beforeinsert;
        } else if(Trigger.isInsert && Trigger.isAfter){
            ev = Evt.afterinsert;
        } else if(Trigger.isUpdate && Trigger.isBefore){
            ev = Evt.beforeupdate;
        } else if(Trigger.isUpdate && Trigger.isAfter){
            ev = Evt.afterupdate;
        } else if(Trigger.isDelete && Trigger.isBefore){
            ev = Evt.beforedelete;
        } else if(Trigger.isDelete && Trigger.isAfter){
            ev = Evt.afterdelete;
        } else if(Trigger.isUndelete){
            ev = Evt.afterundelete;
        }

        List<Handler> handlers = eventHandlerMapping.get(ev.name());

        if (!isExecute) {
            if(excludedHandlers.isEmpty()) {
                return;
            }
        }

        if(handlers == null || handlers.isEmpty()) {
            System.debug('No trigger handlers to execute for event ' + ev.name());
            return;
        }

        for (Handler h : handlers) {
            Type handlerType = ObjectHelper.getObjectType(h);
            Set<Triggers.Evt> excludedEvents = excludedHandlers.get(handlerType);

            if (isExecute) {
                if (excludedEvents != null && excludedEvents.contains(ev)) {
                    System.debug('Bypass trigger handler ' + handlerType + ' for event ' + ev.name() + ': disabled manually');
                    continue;
                }
            } else {
                if (excludedEvents != null && excludedEvents.contains(ev)) {
                    System.debug('Execute trigger handler ' + handlerType + ' for event ' + ev.name() + ': enabled manually');
                } else {
                    System.debug('Bypass trigger handler ' + handlerType + ' for event ' + ev.name() + ': disabled globally');
                    continue;
                }
            }

            if(h.bypass()) {
                System.debug('Bypass trigger handler ' + handlerType + ' for event ' + ev.name() + ': bypass method returns true');
                continue;
            }

            h.handle();
        }
    }

    // Following methods are used to circumnavigate the Java rule that this() or super() must be the first statement in a constructor
    @TestVisible
    private static Map<Id, SObject> getOldMap() {
        if (Trigger.isExecuting && (Trigger.isUpdate || Trigger.isDelete)) {
            return Trigger.oldMap;
        }

        return new Map<Id, SObject>();
    }

    @TestVisible
    private static List<SObject> getOldRecords() {
        if (Trigger.isExecuting && (Trigger.isUpdate || Trigger.isDelete)) {
            return Trigger.old;
        }

        return new List<SObject>();
    }

    @TestVisible
    private static Map<Id, SObject> getNewMap() {
        if (!Trigger.isExecuting) {
            return new Map<Id, SObject>();
        }

        switch on Trigger.operationType {
            when BEFORE_UPDATE, AFTER_INSERT, AFTER_UPDATE, AFTER_UNDELETE {
                return Trigger.newMap;
            }
            when else {
                // not returning null to avoid NPE inside the TriggerHelper
                return new Map<Id, SObject>();
            }
        }
    }

    public abstract class TriggerHelper {
        @TestVisible
        private final TriggerOperation OPERATION_TYPE;
        private final Map<Id, SObject> newMap;
        @TestVisible
        private final Map<Id, SObject> oldMap;
        private final List<SObject> oldRecords;
        protected final Boolean isExecuting;
        protected List<SObject> triggerRecords;

        @TestVisible
        protected Boolean isInsert() {
            return this.OPERATION_TYPE == TriggerOperation.BEFORE_INSERT
                || this.OPERATION_TYPE == TriggerOperation.AFTER_INSERT;
        }

        @TestVisible
        protected Boolean isUpdate() {
            return this.OPERATION_TYPE == TriggerOperation.BEFORE_UPDATE
                || this.OPERATION_TYPE == TriggerOperation.AFTER_UPDATE;
        }

        @TestVisible
        protected Boolean isDelete() {
            return this.OPERATION_TYPE == TriggerOperation.BEFORE_DELETE
                || this.OPERATION_TYPE == TriggerOperation.AFTER_DELETE;
        }

        @TestVisible
        protected Boolean isUndelete() {
            return this.OPERATION_TYPE == TriggerOperation.AFTER_UNDELETE;
        }

        @TestVisible
        protected Boolean isBefore() {
            return this.OPERATION_TYPE == TriggerOperation.BEFORE_INSERT
                || this.OPERATION_TYPE == TriggerOperation.BEFORE_UPDATE
                || this.OPERATION_TYPE == TriggerOperation.BEFORE_DELETE;
        }

        @TestVisible
        protected Boolean isAfter() {
            return this.OPERATION_TYPE == TriggerOperation.AFTER_INSERT
                || this.OPERATION_TYPE == TriggerOperation.AFTER_UPDATE
                || this.OPERATION_TYPE == TriggerOperation.AFTER_DELETE
                || this.OPERATION_TYPE == TriggerOperation.AFTER_UNDELETE;
        }

        //Returns true if field is changed in this trigger context
        @TestVisible
        protected Boolean isChangedField(SObject record, SObjectField field) {
            switch on this.OPERATION_TYPE {
                when BEFORE_INSERT, AFTER_INSERT, AFTER_UNDELETE {
                    return record.get(field) != null;
                }
                when BEFORE_DELETE, AFTER_DELETE {
                    return this.oldValue(record, field) != null;
                }
                when BEFORE_UPDATE, AFTER_UPDATE {
                    return record.get(field) != this.oldValue(record, field);
                }
                when else {
                    return false;
                }
            }
        }

        //Returns true if any specified field is changed in this trigger context
        @TestVisible
        protected Boolean isChangedAnyField(SObject record, Set<SObjectField> fields) {
            for (SObjectField field : fields) {
                if (isChangedField(record, field)) {
                    return true;
                }
            }
            return false;
        }

        //Returns true if field changed from specified value to some other value
        @TestVisible
        protected Boolean isChangedFieldFrom(SObject record, SObjectField field, Object fromValue) {
            return oldValue(record, field) == fromValue && isChangedField(record, field);
        }

        //Returns true if field changed to specified value
        @TestVisible
        protected Boolean isChangedFieldTo(SObject record, SObjectField field, Object toValue) {
            return isChangedField(record, field) && record.get(field) == toValue;
        }

        //Returns true if field changed to any value from the specified set
        @TestVisible
        protected Boolean isChangedFieldToAnyString(SObject record, SObjectField field, Set<String> toValueSet) {
            return isChangedField(record, field) && toValueSet.contains(String.valueOf(record.get(field)));
        }

        //Returns true if case insensitive field changed to any value from the specified set
        @TestVisible
        protected Boolean isChangedToAnyStringCaseInsensitive(SObject record, SObjectField field, Set<String> toValueSet) {
            return isChangedField(record, field)
                && StringHelper.convertSetToLowerCase(toValueSet).contains(String.valueOf(record.get(field))?.toLowerCase());
        }

        //Returns true if field changed and to a non-null value
        @TestVisible
        protected Boolean isChangedFieldToNonNull(SObject record, SObjectField field) {
            return isChangedField(record, field) && record.get(field) != null;
        }

        //Return old field value
        @TestVisible
        protected Object oldValue(SObject record, SObjectField field) {
            return oldRecord(record)?.get(field);
        }

        //Return old records
        @TestVisible
        protected List<SObject> oldRecords() {
            switch on this.OPERATION_TYPE {
                when BEFORE_UPDATE, AFTER_UPDATE, BEFORE_DELETE, AFTER_DELETE {
                    return this.oldRecords;
                }
                when else {
                    return null;
                }
            }
        }

        //Return old record
        @TestVisible
        protected SObject oldRecord(SObject record) {
            return this.oldMap.get(record.Id);
        }

        @TestVisible
        protected Map<Id, SObject> newMap() {
            switch on this.OPERATION_TYPE {
                when BEFORE_UPDATE, AFTER_INSERT, AFTER_UPDATE, AFTER_UNDELETE {
                    return this.newMap;
                }
                when else {
                    return null;
                }
            }
        }

        @TestVisible
        protected Map<Id, SObject> oldMap() {
            switch on this.OPERATION_TYPE {
                when BEFORE_UPDATE, AFTER_UPDATE, BEFORE_DELETE, AFTER_DELETE {
                    return this.oldMap;
                }
                when else {
                    return null;
                }
            }
        }

        public TriggerHelper() {
            this(Trigger.isExecuting ? (Trigger.isDelete ? Trigger.old : Trigger.new) : new List<SObject>());
        }

        public TriggerHelper(List<SObject> triggerRecords) {
            this(Trigger.isExecuting, Trigger.operationType, triggerRecords);
        }

        public TriggerHelper(Boolean isExecuting, TriggerOperation operationType, List<SObject> triggerRecords) {
            this(isExecuting, operationType, triggerRecords, Triggers.getOldRecords(), Triggers.getNewMap(), Triggers.getOldMap());
        }

        public TriggerHelper(Boolean isExecuting, TriggerOperation operationType, List<SObject> triggerRecords, List<SObject> oldRecords, Map<Id, SObject> newMap, Map<Id, SObject> oldMap) {
            this.isExecuting = isExecuting;
            this.OPERATION_TYPE = operationType;
            this.triggerRecords = triggerRecords;
            this.oldRecords = oldRecords;
            this.newMap = newMap;
            this.oldMap = oldMap;
        }
    }

    public abstract class TriggerHandlerBase extends TriggerHelper implements Handler {
        public abstract void handle();
        public virtual Boolean bypass() {
            return false;
        }

        public TriggerHandlerBase() {
            super();
        }

        public TriggerHandlerBase(List<SObject> triggerRecords) {
            super(triggerRecords);
        }

        public TriggerHandlerBase(Boolean isExecuting, TriggerOperation operationType, List<SObject> triggerRecords) {
            super(isExecuting, operationType, triggerRecords);
        }

        public TriggerHandlerBase(Boolean isExecuting, TriggerOperation operationType, List<SObject> triggerRecords, List<SObject> oldRecords, Map<Id, SObject> newMap, Map<Id, SObject> oldMap) {
            super(isExecuting, operationType, triggerRecords, oldRecords, newMap, oldMap);
        }
    }
}