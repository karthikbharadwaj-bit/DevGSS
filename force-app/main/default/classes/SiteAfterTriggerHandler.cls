public with sharing class SiteAfterTriggerHandler {

  public static final String ORDER_PRO_SERV_RT_DEV_NAME = 'Professional_Services';
  public static final String ORDER_CC_PRO_SERV_RT_DEV_NAME = 'CC_Professional_Services';

  // B-802 Updated Order and Site Object for CloudConnect
  public static void updateOrders( Map<Id, Site__c> sitesMap ) {
    Set<Id> orderIds = new Set<Id>();
    List<Order> orders;
    List<AggregateResult> sitesAR;
    Map<Id, Decimal> orderToTotalBandwidthOnOrderMap = new Map<Id, Decimal>();

    for( Site__c site : sitesMap.values() ) {
      orderIds.add( site.Order__c );
    }
    if( !orderIds.isEmpty() ) {
      orders = [SELECT Id, TotalBandwidthOnOrder__c FROM Order WHERE Id IN :orderIds];
      sitesAR = new List<AggregateResult>([SELECT SUM(ConnectionBandwidth__c)SUM, Order__c FROM Site__c WHERE Order__c IN :orders GROUP BY Order__c]);
    }
    for( AggregateResult siteAR : sitesAR ) {
      orderToTotalBandwidthOnOrderMap.put( (Id)siteAR.get('Order__c'), (Decimal)siteAR.get('SUM') );
    }
    for( Order o : orders ) {
      o.TotalBandwidthOnOrder__c = orderToTotalBandwidthOnOrderMap.get( o.Id )/1000;
    }

    if( !orders.isEmpty() ) {
      update orders;
    }
  }

  /**
  * @description  This method is used for auto locking Order records with 'Professional_Services' Developer Name when Site or Phase records were changed by user. It's used in Site_After.trigger and PhaseTrigger.trigger (in PhaseAfter.class) on after insert and after update
  * @param  Map<Id, SObject>  It's map of SObject records (either Site or Phase record)
  * @return void
   */
  public static void autoLockOrder(Map<Id, SObject> objMap) {
    Boolean isNeedToLock = false;
    Set<Id> orderId = new Set<Id>();

    for(SObject sobj : objMap.values()) {
      if (sobj.getSObjectType() == Site__c.SObjectType) {
        orderId.add(((Site__c)sobj).Order__c);
      } else if (sobj.getSObjectType() == Phase__c.SObjectType) {
        orderId.add(((Phase__c)sobj).Order__c);
      }
    }

    if(orderId.size() > 0) {

      Map<Id, Order> orders = new Map<Id, Order>([SELECT Id, TotalBandwidthOnQuote__c,
                                                  TotalBandwidthOnOrder__c, Estimated_ProServ_OTP__c,
                                                  Booked_ProServ_OTP__c, RecordType.DeveloperName,
                                                  (SELECT Id, Completed_Date__c, BillingStatus__c FROM Phases__r)
                                                FROM Order
                                                WHERE Id IN :orderId AND
                                                (RecordType.DeveloperName = :ORDER_PRO_SERV_RT_DEV_NAME OR
                                                RecordType.DeveloperName = :ORDER_CC_PRO_SERV_RT_DEV_NAME)]);

      processOrdersLocking(orders.values());
    }
  }

  private static void processOrdersLocking(List<Order> ordersList) {

    for(Order o : ordersList) {
      Boolean isAllPhasesAccepted = true;
      Boolean isAllPhasesCompleted = true;

      Boolean isProServRT = (o.RecordType.DeveloperName == ORDER_PRO_SERV_RT_DEV_NAME);
      Boolean isCCProServRT = (o.RecordType.DeveloperName == ORDER_CC_PRO_SERV_RT_DEV_NAME);
      Boolean isTotalBandwithEqual = (o.TotalBandwidthOnQuote__c == o.TotalBandwidthOnOrder__c);
      Boolean estimatedProServEqualBookedProServ = (o.Estimated_ProServ_OTP__c == o.Booked_ProServ_OTP__c);

      Boolean isNeedLock = (isProServRT && (isTotalBandwithEqual && estimatedProServEqualBookedProServ)) ||
        (isCCProServRT && estimatedProServEqualBookedProServ);

      if(isNeedLock) {

        for(Phase__c ph : o.Phases__r) {
          if (ph.Completed_Date__c == null) {
            isAllPhasesCompleted = false;
            break;
          }
          if(ph.BillingStatus__c != 'Accepted') {
            isAllPhasesAccepted = false;
            break;
          }
        }

        if (isAllPhasesCompleted && isAllPhasesAccepted) {
          ApexWebServices.activateOrderWithChildren(o.Id, true);
        }
      }
    }
  }

}