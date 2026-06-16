public with sharing class QueueableDMLExecuter extends QueueableBase {
    // Upsert operation is not supported due to
    // System.TypeException: DML on generic List<SObject> only allowed for insert, update or delete
    public Enum DMLType { DML_INSERT, DML_UPDATE, DML_DELETE }
    private DMLType operation;
    private Integer scopeLimit;
    private List<String> bypassTriggerVarNames;

    public QueueableDMLExecuter() {}
    public QueueableDMLExecuter(List<Object> sObjList, DMLType dmlType) {
        this.setScope(sObjList);
        this.operation = dmlType;

        if (this.operation == null) {
            AquivaHelper.throwAquivaException('DML type required');
        }
    }

    public QueueableDMLExecuter withScopeLimit(Integer maxScopeSize) {
        if (maxScopeSize < 1) {
            AquivaHelper.throwAquivaException('Scope limit cannot be less than 1');
        }
        this.scopeLimit = maxScopeSize;
        return this;
    }

    public QueueableDMLExecuter bypassTriggers(List<String> bypassVarNames) {
        this.bypassTriggerVarNames = bypassVarNames;
        return this;
    }

    public override void execute(QueueableContext context) {
        if (!(this.scope instanceof List<SObject>)) {
            return;
        }
        List<SObject> listToProcesInCurrScope = new List<SObject>();
        if (this.scopeLimit == null || this.scope.size() <= this.scopeLimit) {
            listToProcesInCurrScope.addAll((List<SObject>) this.scope);
            this.scope.clear();
        } else {
            for (Integer i = 0; i < this.scopeLimit; i++) {
                listToProcesInCurrScope.add((SObject) this.scope.remove(0));
            }
        }

        if (this.bypassTriggerVarNames != null) {
            TriggerHandler.bypassTrigger(this.bypassTriggerVarNames, true);
        }

        try {
            switch on operation {
                when DML_INSERT {
                    insert listToProcesInCurrScope;
                }
                when DML_UPDATE {
                    update listToProcesInCurrScope;
                }
                when DML_DELETE {
                    delete listToProcesInCurrScope;
                }
            }
        } catch (Exception e) {
            PlatformLog.logException('QueueableDMLExecuter.execute', e);
        }

        if (this.scope.size() > 0) {
            enqueueJob(this.scope, this.operation, this.scopeLimit, this.bypassTriggerVarNames);
        }
    }

    public static Id enqueueJob(List<Object> sObjList, DMLType dmlType) {
        return enqueueJob(sObjList, dmlType, null, null);
    }

    public static Id enqueJob(List<Object> sObjList, DMLType dmlType, Integer scopeLimit) {
        return enqueueJob(sObjList, dmlType, scopeLimit, null);
    }

    public static Id enqueueJob(
        List<Object> sObjList, DMLType dmlType, Integer scopeLimit, List<String> bypassTriggerVarNames
    ) {
        QueueableDMLExecuter nextJob = new QueueableDMLExecuter(sObjList, dmlType)
            .withScopeLimit(scopeLimit)
            .bypassTriggers(bypassTriggerVarNames);

        return QueueableBase.enqueJob(nextJob);
    }

}