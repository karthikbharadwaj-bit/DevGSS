@isTest
private class Test_QueueableBase
{
    public class TestQueueable extends QueueableBase {
        public override void execute (QueueableContext context) {

        }

        public List<sObject> localGetLocalScope (Integer scopeSize) {
            List<sObject> tmp = new List<sObject>();
            for (Object item : getLocalScope(scopeSize)) {
                tmp.add((sObject) item);
            }
            return tmp;
        }
    }

    private static List<sObject> getObjList(Integer size) {
        List<sObject> objList = new List<sObject>();
        for (Integer i = 0; i < size; i++) {
            objList.add(new Account(Name = 'Test:' + i));
        }

        return objList;
    }

    @isTest
    static void testQueueableBase()
    {

        TestQueueable queueableCls = new TestQueueable();
        queueableCls.setScope(getObjList(30));
        System.assertEquals(30, queueableCls.scope.size());
        System.assertEquals(30, queueableCls.localGetLocalScope(30).size());
        System.assertEquals(0, queueableCls.scope.size());

        queueableCls.setScope(getObjList(30));
        System.assertEquals(30, queueableCls.scope.size());
        System.assertEquals(10, queueableCls.localGetLocalScope(10).size());
        System.assertEquals(20, queueableCls.scope.size());

        queueableCls.setScope(getObjList(30));
        System.assertEquals(30, queueableCls.scope.size());
        System.assertEquals(30, queueableCls.localGetLocalScope(null).size());
        System.assertEquals(0, queueableCls.scope.size());

        Test.startTest();
            try {
                QueueableBase.enqueJob(null, getObjList(30));
                System.assert(false, 'Should throw an exeption as queueable class name is not set');
            } catch (Exception e) {
                System.assert(
                    e.getMessage().containsIgnoreCase('Required attribute missed: queueableClassName'),
                    e.getMessage()
                );
            }

            try {
                QueueableBase.enqueJob('NoSuchClass', getObjList(30));
                System.assert(false, 'Should throw an exeption as queueable class does not exist');
            } catch (Exception e) {
                System.assert(
                    e.getMessage().containsIgnoreCase('Queueable interface implementation with following name not found:'),
                    e.getMessage()
                );
            }

            for (Integer i = 0; i < 50; i++) {
                QueueableBase.enqueJob('Test_QueueableBase.TestQueueable', getObjList(30));
            }

            try {
                QueueableBase.enqueJob('Test_QueueableBase.TestQueueable', getObjList(30));
                System.assert(false, 'Should throw an exeption as queueable class already scheduled 50 times');
            } catch (Exception e) {
                System.assert(
                    e.getMessage().containsIgnoreCase('Too many queueable jobs added to the queue:'),
                    e.getMessage()
                );
            }

        Test.stopTest();
    }
}