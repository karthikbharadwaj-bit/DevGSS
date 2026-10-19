/* Covers the OpportunityLineItem selector methods used by Opportunity Summary. */
@IsTest
private class Test_OpportunityLineItemSelector {
  private static final String ID_SUFFIX = '0'.repeat(12);
  private static final Integer ROW_LIMIT = 7;

  private static Id opportunityId() {
    return Id.valueOf(
      Opportunity.SObjectType.getDescribe().getKeyPrefix() + ID_SUFFIX
    );
  }

  // ── selectLineItemsByOpportunityIdForSummary ───
  @IsTest
  static void shouldFilterOnOpportunityWhenSelectingLineItems() {
    Test.startTest();
    QueryFactory factory = new OpportunityLineItemSelector()
      .selectLineItemsByOpportunityIdForSummary(opportunityId())
      .setQuery();
    Test.stopTest();

    String message = 'Line items must be filtered on the opportunity and carry the product name.';
    Assert.areEqual('OpportunityId = :bind0', factory.getCondition(), message);
    Assert.isTrue(factory.getQuery().contains('Product2.Name'), message);
  }

  // ── selectLineItemsWithProductContextForSummary ───
  @IsTest
  static void shouldAddProductCatalogAndRowCapWhenSelectingProductContext() {
    Test.startTest();
    QueryFactory factory = new OpportunityLineItemSelector()
      .selectLineItemsWithProductContextForSummary(opportunityId(), ROW_LIMIT)
      .setQuery();
    Test.stopTest();

    String query = factory.getQuery();
    String message = 'Product context must add the catalog fields and the caller row cap.';
    Assert.areEqual('OpportunityId = :bind0', factory.getCondition(), message);
    Assert.isTrue(query.contains('Product2.Family'), message);
    Assert.isTrue(query.contains('Product2.ServiceCategory__c'), message);
    Assert.isTrue(query.contains('LIMIT ' + ROW_LIMIT), message);
  }

  @IsTest
  static void shouldReturnDefaultFieldsWhenDefaultListRequested() {
    Test.startTest();
    List<Schema.SObjectField> fields = new OpportunityLineItemSelector()
      .getDefaultFieldList();
    Test.stopTest();

    String message = 'The default field list must include the line item Id and opportunity.';
    Assert.isTrue(fields.contains(OpportunityLineItem.Id), message);
    Assert.isTrue(fields.contains(OpportunityLineItem.OpportunityId), message);
  }

  @IsTest
  static void shouldCreateSelectorWhenUsingSecurityConstructor() {
    Test.startTest();
    OpportunityLineItemSelector securitySelector = new OpportunityLineItemSelector(
      true,
      true
    );
    Test.stopTest();

    Assert.isNotNull(
      securitySelector,
      'The security constructor must create a selector.'
    );
  }
}
