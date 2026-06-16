@IsTest
private class Test_BatchJobQueueExceptionTest {
    @IsTest
    private static void testBatchJobQueueException() {
        //Constructor
        BatchJobQueueException bjqe = new BatchJobQueueException();
        BatchJobQueueException.ExceptionDetail detail = bjqe.getDetail();
        detail = BatchJobQueueException.getExceptionDetail(bjqe);

        //Cause DML exception
        try {
            insert new Account();
            System.assert(false, 'Expected DmlException.');
        }
        catch (DmlException e) {
            detail = BatchJobQueueException.getExceptionDetail(e);
            BatchJobQueueException.DmlRowDetail dmlDetail = new BatchJobQueueException.DmlRowDetail(e, 0);
            System.assert(dmlDetail != null);
        }

        //Cause email exception
        try {
            Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{new Messaging.SingleEmailMessage()}, true);
            System.assert(false, 'Expected EmailException.');
        }
        catch (System.EmailException e) {

            detail = BatchJobQueueException.getExceptionDetail(e);
            BatchJobQueueException.DmlRowDetail emailDetail = new BatchJobQueueException.DmlRowDetail(e, 0);
            System.assert(emailDetail != null);
        }
    }
}