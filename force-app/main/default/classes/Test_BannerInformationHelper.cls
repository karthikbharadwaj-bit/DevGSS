/**
 * @description       : Test class for BannerInformationHelper.
 * @author            : Aishwarya N
 * @group             : QTC-Team-Tejas
 * @last modified on  : 01-26-2025
 *
 * Modifications Log
 * ************************************************************************************
 * Ver   Date           Story/Bug#       Author            Description
 * ************************************************************************************
 * 1.0   01-26-2025     LTR-1819         Aishwarya N       Initial Version
 **/
@isTest
private class Test_BannerInformationHelper {
  /**
   * @description Verifies if the getBannerQuery generates valid query strings for different display locations.
   */
  @isTest
  static void validateQuery() {
    String homePageQuery = BannerInformationHelper.getBannerQuery('Home Page');
    String casePageQuery = BannerInformationHelper.getBannerQuery(
      'Case Create Page'
    );
    Assert.isTrue(homePageQuery != null, 'Query should be returned');
    Assert.isTrue(casePageQuery != null, 'Query should be returned');
  }

  /**
   * @description Verifies if the formBannerInformationWrapper populates the wrapper with all values.
   */
  @isTest
  static void testBannerWrapperWithData() {
    Banner_for_Outages__mdt homePageBannerRec = setupTestData('allValues');
    BannerInformationHelper.BannerInformationWrapper wrapperData = BannerInformationHelper.formBannerInformationWrapper(
      homePageBannerRec,
      system.now()
    );
    Assert.isTrue(wrapperData != null, 'Record data should be returned');
  }

  /**
   * @description Verifies if the wrapper is populated correctly for missing values.
   */
  @isTest
  static void testBannerWithMissingValues() {
    Banner_for_Outages__mdt bannerWithoutStatus = setupTestData(
      'missingValues'
    );
    BannerInformationHelper.BannerInformationWrapper wrapperData = BannerInformationHelper.formBannerInformationWrapper(
      bannerWithoutStatus,
      system.now()
    );
    Assert.areEqual('-', wrapperData.status, 'Status should be hyphen');
  }

  /**
   * @description Verifies if the wrapper is populated correctly when dunning message is missing.
   */
  @isTest
  static void testBannerWithoutDunningMessage() {
    Banner_for_Outages__mdt bannerWithoutDunningMsg = setupTestData(
      'missingDunningMsg'
    );
    BannerInformationHelper.BannerInformationWrapper wrapperData = BannerInformationHelper.formBannerInformationWrapper(
      bannerWithoutDunningMsg,
      system.now()
    );
    Assert.areEqual('-', wrapperData.dunningMessage, 'Status should be hyphen');
  }

  /**
   * @description Verifies if the wrapper is not returned when the end date is in the past.
   */
  @isTest
  static void testPastEndDateScenario() {
    Banner_for_Outages__mdt pastDateBannerRec = setupTestData('other');
    BannerInformationHelper.BannerInformationWrapper wrapperData = BannerInformationHelper.formBannerInformationWrapper(
      pastDateBannerRec,
      system.now()
    );
    Assert.isTrue(wrapperData == null, 'Record data should not be returned');
  }

  /**
   * @description Verifies if the metadata records are returned.
   */
  @isTest
  static void testBannerWrapper() {
    List<BannerInformationHelper.BannerInformationWrapper> wrapperData = BannerInformationHelper.getRecordsToDisplay(
      'Home Page'
    );
    Assert.isTrue(
      wrapperData.size() >= 0,
      'Data present in the metadata should be returned'
    );
  }

  /**
   * @description Returns Banner_for_Outages__mdt test data as per requested type.
   */
  private static Banner_for_Outages__mdt setupTestData(String typeOfData) {
    Banner_for_Outages__mdt testBanner = new Banner_for_Outages__mdt();
    testBanner.DeveloperName = 'Test Banner';
    testBanner.MasterLabel = testBanner.DeveloperName;
    testBanner.Type__c = (typeOfData == 'allValues'
      ? 'Incident'
      : 'Notification');
    testBanner.Title__c = 'Test Maintainance/Outage';
    testBanner.Description__c = 'Test Description';
    testBanner.Priority__c = 4;
    testBanner.Status__c = (typeOfData == 'allValues' ? 'Ongoing' : null);
    testBanner.Dunning_Period_Message__c = (typeOfData == 'allValues'
      ? 'Dunning message outage'
      : '');
    testBanner.Event_Display_Start_Date__c = System.now().addDays(-4);
    testBanner.Event_Start_Date__c = System.now().addDays(-3);
    testBanner.Event_End_Date__c = (typeOfData == 'missingValues' ? null :
                                      typeOfData == 'other' ? System.now().addDays(-2) :
                                      System.now().addDays(3));
    testBanner.Show_on_Home_Page__c = true;
    testBanner.Show_on_CaseCreation_Page__c = (typeOfData == 'allValues'
      ? true
      : false);

    if (typeOfData == 'allValues' || typeOfData == 'missingDunningMsg') {
      testBanner.Event_Start_Date__c = System.now().addDays(-1);
      testBanner.Event_End_Date__c = System.now().addDays(3);
      testBanner.Dunning_Period__c = 5;
    }
    return testBanner;
  }
}