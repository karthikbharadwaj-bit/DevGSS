public with sharing class HardwareLineItemTriggerHandler {

	public HardwareLineItemTriggerHandler() {}

	//Record types for Phase objects.
	private static final String RC_HARDWARE_PHASE_RT_NAME = 'RingCentral Hardware Phase';
	private static final String RC_PROSERV_PHASE_RT_NAME = 'ProServ Phase';

	private static final Map<String, Schema.RecordTypeInfo> PHASE_RT_INFO_BY_NAME = Phase__c.SObjectType.getDescribe().getRecordTypeInfosByName();

	private static final Id RC_HARDWARE_PHASE_RT_ID = PHASE_RT_INFO_BY_NAME.get(RC_HARDWARE_PHASE_RT_NAME).getRecordTypeId();
	private static final Id RC_PROSERV_PHASE_RT_ID = PHASE_RT_INFO_BY_NAME.get(RC_PROSERV_PHASE_RT_NAME).getRecordTypeId();

	//Record types for Phase Line Item objects.
	private static final String HLI_PHASE_LINE_ITEM_RT_NAME = 'Hardware Line Item';
	private static final String PLI_PHASE_LINE_ITEM_RT_NAME = 'ProServ Line Item';

	private static final Map<String, Schema.RecordTypeInfo> PHASE_LINE_ITEM_RT_INFO_BY_NAME = Hardware_Line_Item__c.SObjectType.getDescribe().getRecordTypeInfosByName();

	private static final Id HLI_PHASE_LINE_ITEM_RT_ID = PHASE_LINE_ITEM_RT_INFO_BY_NAME.get(HLI_PHASE_LINE_ITEM_RT_NAME).getRecordTypeId();
	private static final Id PLI_PHASE_LINE_ITEM_RT_ID = PHASE_LINE_ITEM_RT_INFO_BY_NAME.get(PLI_PHASE_LINE_ITEM_RT_NAME).getRecordTypeId();


	private static final String ONE_TIME_CHARGE_TERM = 'One - Time';
	private static final String MONTHLY_CHARGE_TERM = 'Monthly';
	private static final String ANNUAL_CHARGE_TERM = 'Annual';
	private static final String MONTHLY_CONTRACT_CHARGE_TERM = 'Monthly - Contract';

	private static final String CANNOT_ASSIGN_TO_COMPLETED_PHASE_ERROR = 'You can\'t assign Phase Line Item to Completed Phase.';
	private static final String CANNOT_MOVE_FROM_COMPLETED_PHASE_ERROR = 'You can\'t move Phase Line Item from Completed Phase';
	private static final String CANNOT_DELETE_FROM_COMPLETED_PHASE_ERROR = 'You can not delete Phase Line Item from Completed Phase.';
	public static final String CANNOT_MAKE_CHAGES_UNDER_COMPLETED_ORDER_ERROR = 'You can\'t make any changes to Phases and/or Phase Line Items under completed Order';
	public static final String CANNOT_MAKE_CHANGES_PHASE_IN_APPROVAL_PROCESS = 'You can\'t make any changes when Phase is in approval process';

	// Bypass setting for Archive user to allow updates under Completed Orders (null-safe)
	private static Boolean bypassCompletedOrderValidation {
		get {
			if (bypassCompletedOrderValidation == null) {
				bypassCompletedOrderValidation = false;
				try {
					ByPassTrigger__c bypassSettings = ByPassTrigger__c.getInstance();
					if (bypassSettings != null && bypassSettings.Bypass_HLI_Completed_Order_Validation__c != null) {
						bypassCompletedOrderValidation = bypassSettings.Bypass_HLI_Completed_Order_Validation__c;
					}
				} catch (Exception e) {
					// If custom setting access fails, default to no bypass
					bypassCompletedOrderValidation = false;
				}
			}
			return bypassCompletedOrderValidation;
		}
		set;
	}
	public static Map<Id, Phase__c> phaseMapStatic = new Map<Id, Phase__c>();
	private static Map<Id, OrderItem> orderItemMapStatic = new Map<Id, OrderItem>();
	private static Map<Id, Order> orderMapStatic = new Map<Id, Order>();
	private static Map<Id, QuoteLineItem> quoteLineItemMapStatic = new Map<Id, QuoteLineItem>();

	public class HandleInsertUpdate extends Triggers.TriggerHandlerBase {

		override public void handle() {

			// B-3043 Assign ProServ SOW Phases into Quote https://rc.my.salesforce.com/a2034000003qk7h
			List<Hardware_Line_Item__c> hliToProcess = (List<Hardware_Line_Item__c>) Trigger.new;

			if(hliToProcess == null || hliToProcess.isEmpty()) {
				return;
			}

			Set<Id> orderIdSet = new Set<Id>();
			Set<Id> phaseIdSet = new Set<Id>();
			Set<Id> quoteLineItemIdSet = new Set<Id>();
			Set<Id> orderLineItemIdSet = new Set<Id>();

			for(Hardware_Line_Item__c hli : hliToProcess) {
				phaseIdSet.add(hli.RingCentral_Hardware_Phase__c);
				orderIdSet.add(hli.Order__c);
				quoteLineItemIdSet.add(hli.Quote_Line_Item__c);
				orderLineItemIdSet.add(hli.Order_Line_Item__c);
			}

			Map<Id, Phase__c> phaseMap = buildRcHardwarePhaseMap(phaseIdSet);
			for(Phase__c phase : phaseMap.values()) {
				orderIdSet.add(phase.Order__c);
			}
			Map<Id, List<Hardware_Line_Item__c>> phaseIdToHLIListMap = new Map<Id, List<Hardware_Line_Item__c>>();
			Map<Id, QuoteLineItem> quoteLineItemMap = buildQuoteLineItemMap(quoteLineItemIdSet);
			buildOrderLineItemAndOrderMap(orderLineItemIdSet);
			Map<Id, OrderItem> orderLineItemMap = new Map<Id, OrderItem>(orderItemMapStatic);

			Map<Id, Order> orderMap = new Map<Id, Order>(orderMapStatic);
			for(Hardware_Line_Item__c hli : hliToProcess) {

				Phase__c phase = phaseMap.get(hli.RingCentral_Hardware_Phase__c);

				Boolean phaseLookupChangedToNonNull = hli.RingCentral_Hardware_Phase__c != null &&
					CoreObjectBase.isFieldChanged(hli, Hardware_Line_Item__c.RingCentral_Hardware_Phase__c);

				if(phaseLookupChangedToNonNull && phase.Completed_Date__c != null) {

					hli.addError(CANNOT_ASSIGN_TO_COMPLETED_PHASE_ERROR);
				}


				Order currentOrder = orderMap.get(hli.Order__c);
				if(currentOrder == null && phase != null && phase.Order__c != null) {
					currentOrder = orderMap.get(phase.Order__c);
				}
				if(currentOrder != null) {
					Boolean isCompletedOrder = currentOrder.Status == 'Completed';

					// validation for any Phase and PLIs changes under completed Order.
					// Skip validation if bypass is enabled for Salesforce Archive user
					Boolean fieldValueUpdated = CoreObjectBase.isFieldChanged(hli, Hardware_Line_Item__c.Order__c) ||
						CoreObjectBase.isFieldChanged(hli, Hardware_Line_Item__c.Order_Line_Item__c) ||
						CoreObjectBase.isFieldChanged(hli, Hardware_Line_Item__c.Quantity__c) ||
						CoreObjectBase.isFieldChanged(hli, Hardware_Line_Item__c.Quote_Line_Item__c) ||
						CoreObjectBase.isFieldChanged(hli, Hardware_Line_Item__c.Total_Price__c);

					if(Trigger.isUpdate && fieldValueUpdated && isCompletedOrder && !bypassCompletedOrderValidation) {
						hli.addError(CANNOT_MAKE_CHAGES_UNDER_COMPLETED_ORDER_ERROR);
					}
				}
				//Populate total price field on phase line item object
				QuoteLineItem qli = quoteLineItemMap.get(hli.Quote_Line_Item__c);
				OrderItem oli = orderLineItemMap.get(hli.Order_Line_Item__c);
				hli.Total_Price__c = qli != null
									? calculateTotalPrice((Double) hli.Quantity__c, (Double) qli.EffectivePriceNew__c)
									: calculateTotalPrice((Double) hli.Quantity__c, (Double) (oli != null ? oli.UnitPrice : 0));

				//Phase line item can't be changed when phase in approval process
				if(Trigger.isUpdate && phase.Status__c == PhaseHelper.STATUS_PENDING_APPROVAL) {
					hli.addError(CANNOT_MAKE_CHANGES_PHASE_IN_APPROVAL_PROCESS);
				}
			}

			Map<Id, List<Hardware_Line_Item__c>> oldPhaseIdToNewHliListMap = new Map<Id, List<Hardware_Line_Item__c>>();

			for(Hardware_Line_Item__c hli : hliToProcess) {

				Boolean phaseLookupCleared = CoreObjectBase.isFieldChangedTo(
					hli, Hardware_Line_Item__c.RingCentral_Hardware_Phase__c, null
				);

				if(Trigger.isUpdate && phaseLookupCleared) {
					Hardware_Line_Item__c oldHli = (Hardware_Line_Item__c) Trigger.oldMap.get(hli.Id);

					if(oldPhaseIdToNewHliListMap.get(oldHli.RingCentral_Hardware_Phase__c) == null) {
						oldPhaseIdToNewHliListMap.put(oldHli.RingCentral_Hardware_Phase__c, new List<Hardware_Line_Item__c>());
					}
					oldPhaseIdToNewHliListMap.get(oldHli.RingCentral_Hardware_Phase__c).add(hli);
				}
			}

			if(oldPhaseIdToNewHliListMap.isEmpty()) {
				return;
			}

			Map<Id, Phase__c> oldPhaseMap = buildRcHardwarePhaseMap(oldPhaseIdToNewHliListMap.keySet());

			for(Id oldPhaseId : oldPhaseIdToNewHliListMap.keySet()) {
				Phase__c oldPhase = oldPhaseMap.get(oldPhaseId);
				if(oldPhase.Completed_Date__c != null) {
					for(Hardware_Line_Item__c hli : oldPhaseIdToNewHliListMap.get(oldPhaseId)) {
						hli.addError(CANNOT_MOVE_FROM_COMPLETED_PHASE_ERROR);
					}
				}
			}
		}


		private Double calculateTotalPrice(Double quantity, Double price) {

			quantity = quantity == null ? 0 : quantity;
			price = price == null ? 0 : price;

			return price * quantity;
		}
	}

	public class HandleDelete extends Triggers.TriggerHandlerBase {

		override public void handle() {

			// B-3043 Assign ProServ SOW Phases into Quote https://rc.my.salesforce.com/a2034000003qk7h
			Set<Id> phaseIdSet = new Set<Id>();
			Set<Id> orderIdSet = new Set<Id>();
			Set<Id> deletedHliIdSet = new Set<Id>();
			for(Hardware_Line_Item__c hli : (List <Hardware_Line_Item__c>)super.oldRecords()) {
				phaseIdSet.add(hli.RingCentral_Hardware_Phase__c);
				orderIdSet.add(hli.Order__c);
				deletedHliIdSet.add(hli.Id);
			}

			Map<Id, Phase__c> phaseMap = buildRcHardwarePhaseMap(phaseIdSet);

			for(Hardware_Line_Item__c hli : (List <Hardware_Line_Item__c>)super.oldRecords()) {

				Phase__c phase = phaseMap.get(hli.RingCentral_Hardware_Phase__c);

				if(hli.Order__c != null) {
					orderIdSet.add(hli.Order__c);
				}else if(phase != null && phase.Order__c != null) {
					orderIdSet.add(phase.Order__c);
				}
			}

			Map<Id, Order> orderMap = new Map<Id, Order>([select Id, Status from Order where Id in :orderIdSet]);

			Boolean hasErrors = false;
			for(Hardware_Line_Item__c hli : (List <Hardware_Line_Item__c>)super.oldRecords()) {

				Phase__c phase = phaseMap.get(hli.RingCentral_Hardware_Phase__c);

				if(phase != null && phase.Completed_Date__c != null) {
					hli.addError(CANNOT_DELETE_FROM_COMPLETED_PHASE_ERROR);
					hasErrors = true;
				}

				Order currentOrder = orderMap.get(hli.Order__c);
				if(currentOrder == null && phase != null) {
					currentOrder = orderMap.get(phase.Order__c);
				}
				if(currentOrder != null && currentOrder.Status == 'Completed') {
					hli.addError(CANNOT_MAKE_CHAGES_UNDER_COMPLETED_ORDER_ERROR);
					hasErrors = true;
				}

				if(phase != null && phase.Status__c == PhaseHelper.STATUS_PENDING_APPROVAL) {
					hli.addError(CANNOT_MAKE_CHANGES_PHASE_IN_APPROVAL_PROCESS);
					hasErrors = true;
				}
			}

			if(hasErrors == true) {
				return;
			}

			//Build phase Id to phase line item list map (contains all not deleted phase line items)
			Map <Id, List<Hardware_Line_Item__c>> phaseIdToHLIListMapOnDelete =
														buildPhaseIdToHLIListMap(phaseIdSet,deletedHliIdSet);
			//Process phases for which last phase line item was deleted
			if(!phaseIdToHLIListMapOnDelete.isEmpty()) {
				for (Id phId : phaseIdToHLIListMapOnDelete.keyset()) {
					if (phaseIdToHLIListMapOnDelete.get(phId).isEmpty()) {
						phaseMap.get(phId).Initial_Payment__c = null;
						phaseMapStatic.put(phId, phaseMap.get(phId));
					}
				}
			} else {
				for (Phase__c ph : phaseMap.values()) {
					ph.Initial_Payment__c = null;
					phaseMapStatic.put(ph.Id, ph);
				}
			}

			//Process other phases for which there are phase line items
			//Contains all phase line items except the deleted ones
			List<Hardware_Line_Item__c> hliToProcess = new List<Hardware_Line_Item__c>();
			//Contains quote line items ids for every phase line item except deleted ones
			Set<Id> quoteLineItemIdSet = new Set<Id>();
			for (List<Hardware_Line_Item__c> hliList : phaseIdToHLIListMapOnDelete.values()) {
				if (!hliList.isEmpty()) {
					for (Hardware_Line_Item__c hli : hliList) {
						quoteLineItemIdSet.add(hli.Quote_Line_Item__c);
						hliToProcess.add(hli);
					}
				}
			}
			if (!hliToProcess.isEmpty()) {
				//Build quote line item map
				Map <Id, QuoteLineItem> quoteLineItemMap = buildQuoteLineItemMap(quoteLineItemIdSet);
				for (Hardware_Line_Item__c hli :hliToProcess) {
					Phase__c phaseToProcess = phaseMap.get(hli.RingCentral_Hardware_Phase__c);
					//Populate initial payment field
					phaseToProcess = populateInitialPaymentField(phaseToProcess, hli, quoteLineItemMap, phaseIdToHLIListMapOnDelete);
					phaseMapStatic.put(phaseToProcess.Id, phaseToProcess);
				}
			}

			//Update phases
			if (!phaseMapStatic.isEmpty()) {
				update phaseMapStatic.values();
			}
		}

		private Map<Id, List<Hardware_Line_Item__c>> buildPhaseIdToHLIListMap(Set<Id> phaseIdSet, Set<Id> deleteHLIIdSet) {
			Map<Id, List<Hardware_Line_Item__c>> phaseIdToHLIListMap = new Map<Id, List<Hardware_Line_Item__c>>();
			for(Hardware_Line_Item__c item : [SELECT Id, RingCentral_Hardware_Phase__c, Order_Line_Item__c, Order__c,
												Total_Price__c, Quantity__c, Quote_Line_Item__c
											FROM Hardware_Line_Item__c
											WHERE RingCentral_Hardware_Phase__c in : phaseIdSet and Id not in : deleteHLIIdSet]) {

				if(phaseIdToHLIListMap.get(item.RingCentral_Hardware_Phase__c) == null) {
					phaseIdToHLIListMap.put(item.RingCentral_Hardware_Phase__c, new List<Hardware_Line_Item__c>());
				}

				phaseIdToHLIListMap.get(item.RingCentral_Hardware_Phase__c).add(item);
			}

			return phaseIdToHLIListMap;
		}
	}

	//This class should be used to update/populate fields on phase object
	public class PopulatePhaseFields extends Triggers.TriggerHandlerBase {
		override public void handle() {
			List<Hardware_Line_Item__c> hliToProcess = (List<Hardware_Line_Item__c>) Trigger.new;

			Set<Id> phaseIdSet = new Set<Id>();
			for(Hardware_Line_Item__c hli : hliToProcess) {
				phaseIdSet.add(hli.RingCentral_Hardware_Phase__c);
			}
			Map<Id, Phase__c> phaseMap = buildRcHardwarePhaseMap(phaseIdSet);
			//Build phase id to phase line item list map (get all phase line items under Phase)
			Map<Id, List<Hardware_Line_Item__c>> phaseIdToHLIListMap = buildPhaseIdToHLIListMap(phaseIdSet);
			//Get quote line items ids for every phase line item
			Set<Id> quoteLineItemIdSet = new Set<Id>();
			for (List<Hardware_Line_Item__c> hliList : phaseIdToHLIListMap.values()) {
				for (Hardware_Line_Item__c hli : hliList) {
					quoteLineItemIdSet.add(hli.Quote_Line_Item__c);
				}
			}
			//Build quote line item map
			Map <Id, QuoteLineItem> quoteLineItemMap = buildQuoteLineItemMap(quoteLineItemIdSet);
			for (Hardware_Line_Item__c hli : hliToProcess) {
				// Removed a previous condition that asked not to have changes in the order or order line item lookups to update the phase.Initial_Payment__c
				Phase__c phase = phaseMap.get(hli.RingCentral_Hardware_Phase__c);
				//Populate initial payment field
				phase = populateInitialPaymentField(phase, hli, quoteLineItemMap, phaseIdToHLIListMap);
				phaseMapStatic.put(phase.Id, phase);
			}
			if (!phaseMapStatic.isEmpty()) {
				update phaseMapStatic.values();
			}
		}

		private Map<Id, List<Hardware_Line_Item__c>> buildPhaseIdToHLIListMap(Set<Id> phaseIdSet) {
		Map<Id, List<Hardware_Line_Item__c>> phaseIdToHLIListMap = new Map<Id, List<Hardware_Line_Item__c>>();

			for(Hardware_Line_Item__c item : [SELECT Id, RingCentral_Hardware_Phase__c, Quote_Line_Item__c, Order__c,
												Total_Price__c, Quantity__c
											  FROM Hardware_Line_Item__c
											  WHERE RingCentral_Hardware_Phase__c in : phaseIdSet]) {

				if(!phaseIdToHLIListMap.keyset().contains(item.RingCentral_Hardware_Phase__c)) {
					phaseIdToHLIListMap.put(item.RingCentral_Hardware_Phase__c, new List<Hardware_Line_Item__c>());
				}
				phaseIdToHLIListMap.get(item.RingCentral_Hardware_Phase__c).add(item);
			}

			return phaseIdToHLIListMap;
		}
	}

	private static Phase__c populateInitialPaymentField(Phase__c phase, Hardware_Line_Item__c hli, Map<Id, QuoteLineItem> quoteLineItemMap, Map<Id, List<Hardware_Line_Item__c>> phaseIdToHLIListMap) {
		if( phase.RecordTypeId == RC_HARDWARE_PHASE_RT_ID || phase.RecordTypeId == RC_PROSERV_PHASE_RT_ID) {

			List<Hardware_Line_Item__c> hliListForCurrentPhase = phaseIdToHLIListMap.get(phase.Id);
			//Populate InitialPayment field on phase__c object
			Double initialPayment = calculateInitialPaymentViaQli(quoteLineItemMap, hliListForCurrentPhase);
			phase.Initial_Payment__c = initialPayment;
		}

		return phase;
	}

	private static Double calculateInitialPaymentViaQli(Map<Id, QuoteLineItem> quoteLineItemMap, List<Hardware_Line_Item__c> hliListForCurrentPhase) {

		Double initialPayment = 0;
		for(Hardware_Line_Item__c item : hliListForCurrentPhase) {
			if(item.Quote_Line_Item__c != null) {
				QuoteLineItem qli = quoteLineItemMap.get(item.Quote_Line_Item__c);

				if( qli.PricebookEntry.Product2.Charge_Term__c == ONE_TIME_CHARGE_TERM ) {
					if(item.Total_Price__c != null) {
						initialPayment += item.Total_Price__c;
					}
				}
			}
		}
		return initialPayment;
	}

	private static void buildOrderLineItemAndOrderMap(Set<Id> orderLineItemIdSet) {
		if(
			!orderItemMapStatic.keySet().containsAll(orderLineItemIdSet)
			|| !orderMapStatic.keySet().containsAll(orderLineItemIdSet)
		) {
			List<OrderItem> oiList = ([SELECT Id, PricebookEntry.Product2Id,
												PricebookEntry.Product2.Charge_Term__c,
												PricebookEntry.Product2.Feature__c,
												PricebookEntry.Product2.Sub_Category__c,
												Not_Shipped_Phones__c,
												UnitPrice, Quantity,
												Order.Id, Order.Status
											FROM OrderItem
											WHERE Id IN :orderLineItemIdSet]);

			for(OrderItem oi : oiList) {
				orderItemMapStatic.put(oi.Id, oi);
				orderMapStatic.put(oi.Order.Id, oi.Order);
			}
		}

	}

	private static Map<Id, Phase__c> buildRcHardwarePhaseMap(Set<Id> rcHardwarePhaseIdSet) {
		if(phaseMapStatic.keySet().containsAll(rcHardwarePhaseIdSet)) {
			return phaseMapStatic;
		} else {
			phaseMapStatic.putAll([SELECT Id, RecordTypeId,
											RecordType.DeveloperName,
											CurrencyIsoCode,
											Initial_Payment__c,
											Rental_Phones_MRR__c,
											Order__c, Order__r.AccountId,
											Order__r.OpportunityId,
											Completed_Date__c, Status__c
										FROM Phase__c
										WHERE Id IN :rcHardwarePhaseIdSet]);
			return phaseMapStatic;
		}
	}

	private static Map<Id, QuoteLineItem> buildQuoteLineItemMap(Set<Id> quoteLineItemIdSet) {
		if(quoteLineItemMapStatic.keySet().containsAll(quoteLineItemIdSet)) {
			return quoteLineItemMapStatic;
		} else {
			quoteLineItemMapStatic.putAll([SELECT Id, PricebookEntry.Product2Id,
											PricebookEntry.Product2.Charge_Term__c,
											PricebookEntry.Product2.Feature__c,
											PricebookEntry.Product2.Sub_Category__c,
											UnitPrice, Quantity, EffectivePrice__c, EffectivePriceNew__c
										FROM QuoteLineItem
										WHERE Id IN :quoteLineItemIdSet]);
			return quoteLineItemMapStatic;
		}
	}

	public class ValidateOrderItem extends Triggers.TriggerHandlerBase {

		override public void handle() {
			List<Hardware_Line_Item__c> hardwareLineItems = Trigger.new;
			Map<Id, Hardware_Line_Item__c> hardwareLineItemsByIds = (Map<Id, Hardware_Line_Item__c>) Trigger.newMap;

			Set<Id> phaseIds = new Set<Id>();
			for (Hardware_Line_Item__c hli: hardwareLineItems) {
				phaseIds.add(hli.RingCentral_Hardware_Phase__c);
			}

			Map<Id, Phase__c> phasesByIds = new Map<Id, Phase__c>([
					SELECT Id, Order__c
					FROM Phase__c
					WHERE Id IN :phaseIds
			]);

			Set<Id> orderItemIds = new Set<Id>();
			for (Hardware_Line_Item__c hli: hardwareLineItems) {
				orderItemIds.add(hli.Order_Line_Item__c);
			}

			Map<Id, OrderItem> orderItemsByIds = new Map<Id, OrderItem>([
					SELECT Id, OrderId
					FROM OrderItem
					WHERE Id IN :orderItemIds
			]);

			if (!orderItemsByIds.isEmpty()) {
				for (Hardware_Line_Item__c hli: hardwareLineItems) {
					if (hli.Order_Line_Item__c != null) {
						Phase__c hliPhase = phasesByIds.get(hli.RingCentral_Hardware_Phase__c);
						OrderItem orderItem = orderItemsByIds.get(hli.Order_Line_Item__c);
						if (hliPhase.Order__c != orderItem.OrderId) {
							hli.addError('Phase line Item can not be related to an order item from an order that differs ' +
									'from the one on the phase');
						} else {
							hli.Order__c = orderItem.OrderId;
						}
					}
				}
			}
		}
	}
}