public class RCSupportPortalCasePagingHelper {
    
    @TestVisible
    List<Object> listObj1;
    public List<Object> rtnListObj1 {get;set;}
    @TestVisible
    Integer index = 0;
    
    
    public RCSupportPortalCasePagingHelper(List<Object> listObj) {
        rtnListObj1 = new List<Object>();
        listObj1 = new List<Object>();
        listObj1 = listObj;
        getRecords();
        getTotalPageNumber(); 
    }
    
    public List<Object> getRecords() {
        rtnListObj1 = new List<Object>();
        pageNumber = 0;
        totalPageNumber = 0;
        pageSize = 10;
        pageNumberParam = 1; 
        BindData(1);
        return rtnListObj1;
    }
    
    public void bindData(Integer newPageIndex) {
        try {
            rtnListObj1 = new List<Object>();
            Transient Integer counter = 0;
            Transient Integer min = 0;
            Transient Integer max = 0;
            if(newPageIndex == totalPageNumber) {
                pageNumberParam = totalPageNumber;
            }
            if (newPageIndex > pageNumberParam) {
                min = pageNumberParam * pageSize;
                max = newPageIndex * pageSize;
                //min = max - ;
            }
            else {
                max = newPageIndex * pageSize;
                min = max - pageSize;
            }
            for(Object obj : listObj1) {
                counter++;
                if (counter > min && counter <= max) {
                    rtnListObj1.add(obj);
                } 
            }
            pageNumberParam = newPageIndex;
        }
        catch(Exception ex) {
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.FATAL,ex.getMessage()));
        }
    }

    @TestVisible
    private Integer pageNumber;

    @TestVisible
    private Integer pageSize;
    private Integer totalPageNumber;
    
    public Integer getPageNumber() {
        return pageNumber;
    }
    
    public Integer getPageSize() {
        return pageSize;
    }
    
    public Boolean getPreviousButtonEnabled {
        get {
            return (pageNumber > 1); 
        }
        set;
    }
    
    public Boolean getNextButtonDisabled {
        get {
            if (listObj1 == null) {
                return true;
            } else {
                return ((pageNumber * pageSize) >= listObj1.size());
            }
        }
        set;
    }
    
    public Integer getTotalPageNumber() {
        totalPageNumber = 0;
        if (totalPageNumber == 0 && listObj1 != null) {
            totalPageNumber = listObj1.size() / pageSize;
            Integer mod = listObj1.size() - (totalPageNumber * pageSize);
            if (mod > 0) {
                totalPageNumber++;
            }
        }
        return totalPageNumber;
    }
    
    public PageReference nextBtnClick() {
        BindData(pageNumber + 1);
        return null;
    }
    
    public PageReference previousBtnClick() {
        BindData(pageNumber - 1);
        return null;
    }
    
    public void first() {
        BindData(1);
    }
    
    public PageReference last() {
        BindData(totalPageNumber); 
        return null;
    }
    
       // indicates whether there are more records after the current page set.
    public Boolean hasNext {
        get {
            if(index >= listObj1.size()) {
                   return false; 
               } else {
                   return   true; 
               }
        }
        set;
    }
    
    public Integer pageNumberParam {get;set;}
    public void getRecordsByPN() {
        if(pageNumberParam != null) {
            BindData(pageNumberParam);
        }
    }
    
}