public class SaveResultWrapper{
        public SaveResultWrapper(Boolean isSuccess, String recordId, Database.Error[] databaseErrorResults){
            this.isSuccess = isSuccess;
            this.recordId = recordId;
            errorResults = new List<ErrorWrapper>();
            for(Database.Error dbError : databaseErrorResults) {
                ErrorWrapper newError = new ErrorWrapper(dbError.getFields(), dbError.getMessage(), dbError.getStatusCode());
                errorResults.add(newError);
            }
        }
        public Boolean isSuccess;
        public String recordId {
            set;
            get { return this.recordId == null ? 'null'
                             : this.recordId;
            }
        }
        public List<ErrorWrapper> errorResults;
        public class ErrorWrapper{
            public ErrorWrapper(List<String> fields, String message, System.StatusCode statusCode){
                this.fields = fields;
                this.message = message;
                this.statusCode = statusCode;
            }
            public List<String> fields;
            public String message;
            public System.StatusCode statusCode;
        }
    }