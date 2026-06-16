public abstract with sharing class QueueableBase implements Queueable, Database.AllowsCallouts {

    @TestVisible
    protected List<Object> scope;

    public QueueableBase () {}
    public abstract void execute(QueueableContext context);

    public void setScope (List<Object> listToProcess) {
        this.scope = listToProcess;
    }

    protected List<Object> getLocalScope (Integer scopeSize) {
        List<Object> localScope = new List<Object>();

        if (scopeSize == null || this.scope.size() <= scopeSize) {
            localScope.addAll(this.scope);
            this.scope = new List<Object>();
        } else {
            for (Integer i = 0; i < scopeSize; i++) {
                localScope.add(this.scope.remove(0));
            }
        }

        return localScope;
    }

    public static QueueableBase newInstance(String queueableClassName, List<Object> objectsToProcess) {
        if (String.isBlank(queueableClassName)) {
            AquivaHelper.throwAquivaException(
                'Required attribute missed: queueableClassName'
            );
        }
        Type queueableImplementationType = Type.forName(queueableClassName);
        if(queueableImplementationType == null) {
            AquivaHelper.throwAquivaException(
                'Queueable interface implementation with following name not found: ' + queueableClassName
            );
        }
        QueueableBase queueableImplementation = (QueueableBase)queueableImplementationType.newInstance();
        queueableImplementation.setScope(objectsToProcess);

        return queueableImplementation;
    }

    public static Id enqueJob(String queueableClassName, List<Object> objectsToProcess) {
        QueueableBase queueableImplementation = newInstance(queueableClassName, objectsToProcess);

        return enqueJob(queueableImplementation);
    }

    public static Id enqueJob(QueueableBase jobToEnque) {
        if (jobToEnque == null) {
            AquivaHelper.throwAquivaException('Unexpected parameter for jobToEnque');
        }
        if (Limits.getLimitQueueableJobs() == Limits.getQueueableJobs()) {
            AquivaHelper.throwAquivaException(
                'Too many queueable jobs added to the queue: ' + String.valueOf(Limits.getQueueableJobs())
            );
        }
        return System.enqueueJob(jobToEnque);
    }
}