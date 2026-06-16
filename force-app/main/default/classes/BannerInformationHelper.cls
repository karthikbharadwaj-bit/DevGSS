/**
 * @description       : Helper class that retrieves, filters and formats records from
 *                      Banner_for_Outages__mdt for display in the bannerForOutage LWC.
 * @author            : Aishwarya N
 * @group             : QTC-Team-Tejas
 * @last modified on  : 01-10-2025
 *
 * Modifications Log
 * ************************************************************************************
 * Ver   Date           Story/Bug#       Author            Description
 * ************************************************************************************
 * 1.0   01-10-2025     LTR-1819         Aishwarya N       Initial Version
 **/

public with sharing class BannerInformationHelper {
  /**
   * @description : Gets a list of banner event records to display based on the provided location
   * @param : displayLocation - Location where the banner should be displayed
   * @return : List<BannerInformationWrapper> - List of banner information records to display
   **/
  @AuraEnabled
  public static List<BannerInformationWrapper> getRecordsToDisplay(
    String displayLocation
  ) {
    // Get the current datetime in UTC
    Datetime utcTimeNow = System.now();

    List<BannerInformationWrapper> eventRecordsList = new List<BannerInformationWrapper>();
    String bannerQuery = getBannerQuery(displayLocation);

    for (
      Banner_for_Outages__mdt eventRecord : Database.query(
        String.escapeSingleQuotes(bannerQuery)
      )
    ) {
      BannerInformationWrapper wrapperRecord = formBannerInformationWrapper(
        eventRecord,
        utcTimeNow
      );
      if (wrapperRecord != null) {
        eventRecordsList.add(wrapperRecord);
      }
    }
    return eventRecordsList;
  }

  /**
   * @description - Creates a wrapper object from a Banner_for_Outages__mdt record with event display information
   * @param - eventRecord : Banner_for_Outages__mdt record to convert to a wrapper
   * @param - utcTimeNow : Current UTC datetime used to determine if event should be displayed
   * @return - BannerInformationWrapper : Populated wrapper if event should be displayed, null otherwise
   **/
  public static BannerInformationWrapper formBannerInformationWrapper(
    Banner_for_Outages__mdt eventRecord,
    Datetime utcTimeNow
  ) {
    BannerInformationWrapper wrapperRecord = new BannerInformationWrapper();
    if (shouldDisplayEvent(utcTimeNow, eventRecord)) {
      wrapperRecord.type = eventRecord.Type__c;
      wrapperRecord.title = eventRecord.Title__c;
      wrapperRecord.details = eventRecord.Description__c;
      wrapperRecord.status = eventRecord.Status__c != null
        ? eventRecord.Status__c
        : '-';
      wrapperRecord.startTime = formatDateTime(eventRecord.Event_Start_Date__c);
      wrapperRecord.endTime = formatDateTime(eventRecord.Event_End_Date__c);
      wrapperRecord.duration = calculateDuration(
        eventRecord.Event_Start_Date__c,
        eventRecord.Event_End_Date__c
      );

      if (
        eventRecord.Dunning_Period__c != null &&
        eventRecord.Dunning_Period__c != 0 &&
        eventRecord.Event_End_Date__c != null
      ) {
        wrapperRecord.dunningMessage = String.isNotBlank(
            eventRecord.Dunning_Period_Message__c
          )
          ? String.valueOf(eventRecord.Dunning_Period_Message__c)
          : '-';
      }
      return wrapperRecord;
    }
    return null;
  }

  /**
   * @description : Calculates the duration between two datetime values and formats it as "X days, Y hours, Z minutes"
   * @param : startDate - The start datetime of the event
   * @param : endDate - The end datetime of the event
   * @return : String - Duration formatted as "X days, Y hours, Z minutes" or "-" if either date is null
   **/
  private static String calculateDuration(
    DateTime startDate,
    DateTime endDate
  ) {
    String duration = '-';
    if (startDate != null && endDate != null) {
      Long diffInMilliseconds = endDate.getTime() - startDate.getTime();
      Integer eventDurationInDays = Integer.valueOf(
        diffInMilliseconds / (1000 * 60 * 60 * 24)
      );
      Long remainingHoursMilliseconds = Math.mod(
        diffInMilliseconds,
        (1000 * 60 * 60 * 24)
      );
      Integer eventDurationInHours = Integer.valueOf(
        remainingHoursMilliseconds / (1000 * 60 * 60)
      );
      Long remainingMinsMilliseconds = Math.mod(
        diffInMilliseconds,
        (1000 * 60 * 60)
      );
      Integer eventDurationInMinutes = Integer.valueOf(
        remainingMinsMilliseconds / (1000 * 60)
      );

      duration =
        String.valueOf(eventDurationInDays) +
        ' days, ' +
        String.valueOf(eventDurationInHours) +
        ' hours, ' +
        String.valueOf(eventDurationInMinutes) +
        ' minutes';
    }
    return duration;
  }

  /**
   * @description : Forms the banner metadata query based on the display location.
   * @param : displayLocation - Location where the banner should be displayed
   * @return : String - Query string for Banner_for_Outages__mdt records
   **/
  public static String getBannerQuery(String displayLocation) {
    String bannerQuery =
      'SELECT ' +
      'Type__c, ' +
      'Priority__c, ' +
      'Title__c, ' +
      'Description__c, ' +
      'Event_Start_Date__c, ' +
      'Event_End_Date__c, ' +
      'Status__c, ' +
      'Dunning_Period__c, ' +
      'Dunning_Period_Message__c ' +
      'FROM Banner_for_Outages__mdt ' +
      'WHERE Event_Display_Start_Date__c <= :utcTimeNow ';
    if (
      String.isNotBlank(displayLocation) &&
      displayLocation == 'Case Create Page'
    ) {
      bannerQuery += 'AND Show_on_CaseCreation_Page__c = true ';
    } else if (
      String.isNotBlank(displayLocation) && displayLocation == 'Home Page'
    ) {
      bannerQuery += 'AND Show_on_Home_Page__c = true ';
    }
    bannerQuery += 'ORDER BY Priority__c ASC NULLS LAST, Event_Start_Date__c DESC';
    return bannerQuery;
  }

  /**
   * @description : Formats the datetime from UTC to current user's timezone.
   * @param : eventRecordDateTime - Datetime to format
   * @return : String - Formatted datetime in user's timezone or "-" if datetime is null
   **/
  private static String formatDateTime(DateTime eventRecordDateTime) {
    TimeZone userTimeZone = UserInfo.getTimeZone();
    String formattedDateTime = eventRecordDateTime != null
      ? eventRecordDateTime.format(
          'hh:mm a z\', \'MMM dd',
          String.valueOf(userTimeZone)
        )
      : '-';
    return formattedDateTime;
  }

  /**
   * @description : Determines if the event record should be displayed based on the current time and event record details.
   * @param : currentTime - Current datetime in UTC
   * @param : eventRecord - Banner_for_Outages__mdt record containing event information
   * @return : Boolean - True if the event should be displayed, false otherwise
   **/
  private static Boolean shouldDisplayEvent(
    DateTime currentTime,
    Banner_for_Outages__mdt eventRecord
  ) {
    return ((eventRecord.Dunning_Period__c != null &&
      eventRecord.Event_End_Date__c != null)
      ? (currentTime <=
        eventRecord.Event_End_Date__c.addHours(
          Integer.valueOf(eventRecord.Dunning_Period__c)
        ))
      : (eventRecord.Dunning_Period__c == null &&
          eventRecord.Event_End_Date__c != null)
          ? (currentTime <= eventRecord.Event_End_Date__c)
          : true);
  }

  /**
   * @description : Wrapper class to store the Event information.
   **/
  public class BannerInformationWrapper {
    @AuraEnabled
    public String type { get; set; }
    @AuraEnabled
    public String title { get; set; }
    @AuraEnabled
    public String details { get; set; }
    @AuraEnabled
    public String status { get; set; }
    @AuraEnabled
    public String startTime { get; set; }
    @AuraEnabled
    public String endTime { get; set; }
    @AuraEnabled
    public String duration { get; set; }
    @AuraEnabled
    public String dunningMessage { get; set; }
  }
}