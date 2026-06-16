public virtual class BatchJobQueueException extends Exception {

    //Return serializable detail specific to the exception type.
    public virtual ExceptionDetail getDetail() {
        return new ExceptionDetail(this);
    }

    //Return serializable detail for any exception.
    public static ExceptionDetail getExceptionDetail(Exception e) {
        if (e instanceof BatchJobQueueException) {
            return ((BatchJobQueueException) e).getDetail();
        } else {
            return new ExceptionDetail(e);
        }
    }

    //Serializable class holding exception detail beyond the message.
    public virtual class ExceptionDetail {

        public Integer LineNumber { get; set; }
        public String StackTrace { get; set; }

        public ExceptionDetail(Exception e) {
            this.LineNumber = e.getLineNumber();
            this.StackTrace = e.getStackTraceString();
        }

    }

    //Serializable exception information for one DML row
    public class DmlRowDetail {

        public Integer RowIndex { get; set; }
        public List<String> FieldNames { get; set; }
        public String RecordId { get; set; }
        public String Message { get; set; }
        public String Type { get; set; }

        //Construct from DmlException row
        public DmlRowDetail(System.DmlException e, Integer rowDetailNum) {
            this.RowIndex = e.getDmlIndex(rowDetailNum);
            this.FieldNames = e.getDmlFieldNames(rowDetailNum);
            this.RecordId = e.getDmlId(rowDetailNum);
            this.Message = e.getDmlMessage(rowDetailNum);
            this.Type = String.valueOf(e.getDmlType(rowDetailNum));
        }

        //Construct from EmailException row
        public DmlRowDetail(System.EmailException e, Integer rowDetailNum) {
            this.RowIndex = e.getDmlIndex(rowDetailNum);
            this.FieldNames = e.getDmlFieldNames(rowDetailNum);
            this.RecordId = e.getDmlId(rowDetailNum);
            this.Message = e.getDmlMessage(rowDetailNum);
            this.Type = String.valueOf(e.getDmlType(rowDetailNum));
        }
    }
}