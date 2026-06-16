@isTest
private class Test_RCSupportPortalCasePagingHelper {

    @isTest
    static void testGetRecords() {

        List<Object> testList = new List<Object>{ 1 };

        RCSupportPortalCasePagingHelper helper = new RCSupportPortalCasePagingHelper(testList);
        List<Object> records = helper.getRecords();

        Assert.isTrue(helper.pageSize == 10);

    }

    @isTest
    static void testBindData() {
        List<Object> testList = new List<Object>{ 1 };

        RCSupportPortalCasePagingHelper helper = new RCSupportPortalCasePagingHelper(testList);
        helper.BindData(1);

        Assert.isTrue(helper.rtnListObj1.size() == 1);
    }

    @isTest
    static void testGetTotalPageNumber() {
        List<Object> testList = new List<Object>{ 1,2,3 };

        RCSupportPortalCasePagingHelper helper = new RCSupportPortalCasePagingHelper(testList);
        Integer totalPageNumber = helper.getTotalPageNumber();

        Assert.isTrue(helper.rtnListObj1.size() == 3);
    }

    @isTest
    static void testNavigation() {
        List<Object> testList = new List<Object>{ 1,2,3,4,5 };

        RCSupportPortalCasePagingHelper helper = new RCSupportPortalCasePagingHelper(testList);
        PageReference nextPage = helper.nextBtnClick();
        PageReference previousPage = helper.previousBtnClick();
        helper.first();
        helper.getRecordsByPN();
        PageReference lastPage = helper.last();

        Integer pageNumber = helper.PageNumber;
        Integer pageSize = helper.PageSize;

        Boolean previousButtonEnabled = helper.getPreviousButtonEnabled;
        Boolean previousButtonDisabled = helper.getNextButtonDisabled;
        Boolean hasNext = helper.hasNext;

        Assert.isNotNull(pageNumber);
        Assert.isNotNull(pageSize);
        Assert.isFalse(previousButtonEnabled);
        Assert.isFalse(previousButtonDisabled);
        Assert.isTrue(hasNext);
        Assert.isNull(nextPage);
        Assert.isNull(previousPage);
        Assert.isNull(lastPage);
    }

}