public with sharing class PhaseTriggerHandler {

    private static final String VALIDATE_PHASE_LINE_ITEMS = 'Please validate all phase line items before complete phase';
    public static final String SUCCESS_CREATE = 'Mavenlink Integrator record was created on ' + System.now().format();
    public static final String SUCCESS_UPDATE = 'Mavenlink Integrator record was updated on ' + System.now().format();
    private static final String ORDER_STATUS = 'Change Order Opportunities aren\'t set up to sync up with Mavenlink.';
    private static final String OPP_STATUS = 'Phase should have related Opportunity for the sync with Mavenlink.';
    public static Map<Id, Asset> assetMapStatic = new Map<Id, Asset>();
    public static Boolean updateFromMavenlink = false;
    public static Map<Id, Account> accountsByPhaseId = new Map<Id, Account>();
    public static Map<Id, User> usersByPhaseId = new Map<Id, User>();
    public static Map<Id, Opportunity> opportunitiesByPhaseId = new Map<Id, Opportunity>();
    public static Map<Id, Quote> quotesByPhaseId = new Map<Id, Quote>();
    public static Map<Id, Quote> originalQuotesByPhaseId = new Map<Id, Quote>();
    public static Map<Id, Order> ordersByPhaseId = new Map<Id, Order>();
    public static String errorFields = '';
    public static Set<String> phaseIds = new Set<String>();
    public static List<Mavenlink_Integrator__c> mavenlinkRecords = new List<Mavenlink_Integrator__c>();
    public static Map<Id, Mavenlink_Integrator__c> mlRecordsByPhaseId = new Map<Id, Mavenlink_Integrator__c>();
    public static Set<String> orderRecordTypeNames = new Set<String>{'Professional Services',
                                                                    'CC Professional Services'};
    public static Map<String, Decimal> isoWithRateMap = new Map<String, Decimal>();

    public static Boolean syncChangeOrders = Feature_Toggle__c.getInstance().IsSynchronizeChangeOrders__c;
    public static Boolean changeOrderFlow = false;
    public static Boolean isMLRecordAlreadyInserted = false;

    public class PrepopulateFields extends Triggers.TriggerHandlerBase {
        override public void handle () {
            List<Phase__c> phaseList = (List<Phase__c>)Trigger.new;

            Set<Id> orderIdSet = new Set<Id>();
            for (Phase__c item : phaseList) {
                if (item.Order__c == null) {
                    continue;
                }
                orderIdSet.add(item.Order__c);
            }

            Map<Id,Order> orderMap = new Map<Id, Order>();
            if (!orderIdSet.isEmpty()) {
                orderMap = buildOrderMap(orderIdSet);
            }

            for (Phase__c item : phaseList) {
                item.Status__c = PhaseHelper.STATUS_NEW;

                if (item.Order__c == null) {
                    continue;
                }

                if (item.Initial_Payment__c != null && orderMap.get(item.Order__c).Booked_ProServ_OTP__c != null){
                    item.Percentage__c = item.Initial_Payment__c / orderMap.get(item.Order__c).Booked_ProServ_OTP__c * 100;
                }
            }
        }
    }

	public class ValidateCompletedOrder extends Triggers.TriggerHandlerBase {
		override public void handle() {
			Map<Id, Phase__c> phasesToProcessMap = (Map<Id,Phase__c>) (Trigger.isDelete
																		? Trigger.oldMap
																		: Trigger.newMap);
			//Get orders for triggered phases (orders already exist, map can't be empty)
			Map<Id, Order> orderMap = getOrdersForPhases(phasesToProcessMap.values());
            
			// B-3043 Assign ProServ SOW Phases into Quote https://rc.my.salesforce.com/a2034000003qk7h
			if (!orderMap.isEmpty()) {
				// You cannot make any changes under completed order
                // Check bypass setting for Salesforce Archive user 
				Boolean bypassCompletedOrderValidation = false;
				try {
					ByPassTrigger__c bypassSettings = ByPassTrigger__c.getInstance();
					if (bypassSettings != null && bypassSettings.Bypass_HLI_Completed_Order_Validation__c != null) {
						bypassCompletedOrderValidation = bypassSettings.Bypass_HLI_Completed_Order_Validation__c;
					}
				} catch (Exception e) {
					// If custom setting access fails, default to no bypass
					bypassCompletedOrderValidation = false;
				}
				for (Phase__c item : phasesToProcessMap.values()) {
					Order currentOrder = orderMap.get(item.Order__c);
					if ((trigger.isInsert || trigger.isDelete || trigger.isUpdate
							&& isChangedAnyField(item, new Set<SObjectField>{
							Phase__c.Completed_Date__c,
							Phase__c.Completion_Date__c,
							Phase__c.Initial_Payment__c}))
							&& (currentOrder != null && currentOrder.Status == 'Completed' ) 
                            && !bypassCompletedOrderValidation) {
						item.addError(HardwareLineItemTriggerHandler.CANNOT_MAKE_CHAGES_UNDER_COMPLETED_ORDER_ERROR);
					}
				}
			}

			CustomPermissionHelper customPermissions = new CustomPermissionHelper();
			if (customPermissions.hasPermission(CustomPermissionHelper.PERMISSION_EDIT_LOCATIONS)) {
				Set<Id> phaseIdWithCompletionDateChanged = new Set<Id>();
				for (Phase__c item : phasesToProcessMap.values()) {
					if (isChangedAnyField(item, new Set<SObjectField>{
													Phase__c.Completed_Date__c,
													Phase__c.Completion_Date__c} )) {
						phaseIdWithCompletionDateChanged.add(item.Id);
					}
				}
				if (!phaseIdWithCompletionDateChanged.isEmpty()) {

					HardwareLineItemSelector selector = new HardwareLineItemSelector();
					List<Object> bindings = new List<Object>();
					bindings.add(phaseIdWithCompletionDateChanged);
					List<Hardware_Line_Item__c> pliList = selector.selectPhaseLineItemsByPhaseIds(bindings).executeQuery();

					if (!pliList.isEmpty()) {
						for (Hardware_Line_Item__c pli : pliList) {
							if (!pli.Address_Validated__c) {
								phasesToProcessMap.get(pli.RingCentral_Hardware_Phase__c).addError(VALIDATE_PHASE_LINE_ITEMS);
							}
						}
					}
				}
			}
		}

		public Map <Id, Order> getOrdersForPhases (List <Phase__c> triggeredPhases) {
			Set<Id> orderIdSet = new Set<Id>();
			for (Phase__c item : triggeredPhases) {
				if (item.Order__c != null) {
					orderIdSet.add(item.Order__c);
				}
			}
			List <Order> orderList = new List<Order>();
			if (!orderIdSet.isEmpty()) {

				OrderSelector selector = new OrderSelector();
				List<Object> bindings = new List<Object>();
				bindings.add(orderIdSet);

				orderList = selector.selectOrdersByIds(bindings).executeQuery();
			}
			Map<Id, Order> orderMap = new Map<Id, Order>();
			for (Order orderRecord : orderList) {
				orderMap.put(orderRecord.Id, orderRecord);
			}
			return orderMap;
		}
	}

	public class PopulatePhaseAndOrderFields extends Triggers.TriggerHandlerBase {
		override public void handle() {

			Feature_Toggle__c featureToggleSetting = Feature_Toggle__c.getInstance();
			List<Phase__c> phasesWithOrder = new List<Phase__c>();
			for (Phase__c item : (List<Phase__c>)Trigger.new) {
				if (item.Order__c != null){
                    phasesWithOrder.add(item);
                }
			}
			if (phasesWithOrder.isEmpty()) {
                return;
            }
			Map<Id, List<Phase__c>> orderIdToPhaseListMap = new Map<Id, List<Phase__c>>();
			Set<Id> phaseIdSet = new Set<Id>();
			for (Phase__c item : phasesWithOrder) {
				if (!orderIdToPhaseListMap.containsKey(item.Order__c)) {
					orderIdToPhaseListMap.put(item.Order__c, new List<Phase__c>());
				}
				orderIdToPhaseListMap.get(item.Order__c).add(item);
				phaseIdSet.add( item.Id );
			}

			PhaseSelector phaseSelector = new PhaseSelector();
			List<Object> phaseBindings = new List<Object>();
			phaseBindings.add(orderIdToPhaseListMap.keySet());
			phaseBindings.add(phaseIdSet);

			List<Phase__c> proServPhasesList = phaseSelector.selectPhasesByOrdersIdsExcludePhaseIds(phaseBindings).executeQuery();

			for (Phase__c item : proServPhasesList) {

				if (!orderIdToPhaseListMap.containsKey(item.Order__c)) {
					orderIdToPhaseListMap.put(item.Order__c, new List<Phase__c>());
				}
				orderIdToPhaseListMap.get(item.Order__c).add(item);
			}

			//TODO Commented selector because it was getting outdated information. should be refactored in the right way
			Map<Id, Order> orderIdToOrderMap = new Map<Id, Order>([SELECT Id, Booked_ProServ_OTP__c,
                                                                        Estimated_ProServ_OTP__c,
																	    hasProServ__c, RecordTypeId, CurrencyIsoCode,
																	    AccountId, OpportunityId
															        FROM Order
															        WHERE Id IN : orderIdToPhaseListMap.keySet()]);

			OrderSelector orderSelector = new OrderSelector();
			List<Object> orderBindings = new List<Object>();
			orderBindings.add(orderIdToPhaseListMap.keySet());

			Map<Id, Order> orderToUpdateMap = new Map<Id, Order>();
			Double paymentAmountSumm = 0;
			Double completedOTPSumm = 0;

			for (Phase__c item : phasesWithOrder) {

				if (!orderToUpdateMap.keySet().contains(item.Order__c)) {

					List<Phase__c> phaseForCurrentOrder = orderIdToPhaseListMap.get( item.Order__c );

					Order order = orderIdToOrderMap.get(item.Order__c);

					paymentAmountSumm = 0;
					completedOTPSumm = 0;

					for (Phase__c phase : phaseForCurrentOrder) {
						if (phase.RecordTypeId == PhaseHelper.RT_ID_PROSERV_PHASE) {
							paymentAmountSumm += phase.Initial_Payment__c == null ? 0 : phase.Initial_Payment__c;
						}
						if (featureToggleSetting.NewChangeOrderFlow__c) {
							if ((phase.RecordTypeId == PhaseHelper.RT_ID_PROSERV_PHASE)
								&& (phase.Completed_Date__c != null)) {
								completedOTPSumm += phase.Initial_Payment__c == null ? 0 : phase.Initial_Payment__c;
							}
						}

					}

					if (paymentAmountSumm <= order.Estimated_ProServ_OTP__c) {
						order.Booked_ProServ_OTP__c = paymentAmountSumm;
						orderToUpdateMap.put(item.Order__c, order);
					}

					if (featureToggleSetting.NewChangeOrderFlow__c && completedOTPSumm > 0) {
						order.Completed_Phases_OTP_Summary__c = completedOTPSumm;
						if (!orderToUpdateMap.keySet().contains(item.Order__c)) {
							orderToUpdateMap.put(item.Order__c, order);
						}
					}
				}
			}

			if (orderToUpdateMap.size() > 0) {
                update orderToUpdateMap.values();
            }

			// Populate phase fields
			for (Phase__c item : phasesWithOrder) {
				item.Account__c = orderIdToOrderMap.get(item.Order__c).AccountId;
				item.Opportunity__c = orderIdToOrderMap.get(item.Order__c).OpportunityId;
				item.CurrencyIsoCode = orderIdToOrderMap.get(item.Order__c).CurrencyIsoCode;

				if ((isChangedField(item, Phase__c.Initial_Payment__c) || isChangedField(item, Phase__c.Order__c))
					&& item.Initial_Payment__c != null
					&& orderIdToOrderMap.get(item.Order__c).Booked_ProServ_OTP__c != null) {
                        item.Percentage__c = orderIdToOrderMap.get(item.Order__c).Booked_ProServ_OTP__c == 0
                        ? 0
                        : item.Initial_Payment__c / orderIdToOrderMap.get(item.Order__c).Booked_ProServ_OTP__c * 100;
                    }
			}
			// validate phase
			for (Phase__c item : phasesWithOrder) {
				validatePhase(item, orderIdToOrderMap);
			}
		}

		private void validatePhase(Phase__c phaseToValidate, Map<Id, Order> orderIdToOrderMap) {

			Order order = orderIdToOrderMap.get(phaseToValidate.Order__c);

			if (phaseToValidate.RecordTypeId == PhaseHelper.RT_ID_PROSERV_PHASE) {

				/*
                "If Phase with Record Type "ProServ Phase" is linked to Order with Record Type != "Professional Services",
                we need to show an error: "ProServ Phases can be linked only to Professional Service Orders"
                Should be checked when Phases are created or updated"
                */

				if (order.RecordTypeId != OrderHelper.RT_ID_PROSERV && order.RecordTypeId != OrderHelper.RT_ID_CC_PROSERV) {
					phaseToValidate.Order__c.addError('ProServ Phases can be linked only to Professional Services and CC Professional Services Orders');
				}

			} else if (phaseToValidate.RecordTypeId == PhaseHelper.RT_ID_RINGCENTRAL_HARDWARE_PHASE) {

				/*
                "If Phase with Record Type "RingCentral Hardware Phase" is linked to Order with Record Type != "RingCentral" or
                with "Has Pro Serv" field != true, we need to show an error:
                "RingCentral Hardware Phases can be linked only to RingCentral Orders if ProServ SOW was in the Primary Quote"
                Should be checked when Phases are created or updated"
                */

				if ((order.RecordTypeId != OrderHelper.RT_ID_RC)
                    || ( (order.RecordTypeId == OrderHelper.RT_ID_RC) && (order.hasProServ__c == false) )) {
					phaseToValidate.Order__c.addError('RingCentral Hardware Phases can be linked only to RingCentral Orders if ProServ SOW was in the Primary Quote');
				}
			}

		}
	}

    public class BrandPartnerPopulationHandler extends BrandPartnerFieldPopulationHandler {
        public BrandPartnerPopulationHandler() {
            super(Phase__c.sObjectType);
        }
    }

	public class ValidatePermissionToDeletePhase extends Triggers.TriggerHandlerBase {
		override public void handle() {
            Feature_Toggle__c featureToggleSetting = Feature_Toggle__c.getInstance();
			ProfileSelector profileSelector = new ProfileSelector();
			Map<Id, Profile> profileMapNames = new Map<Id, Profile>(
				(List<Profile>) profileSelector.selectAllProfiles().executeQuery()
			);

			List<Phase__c> phasesWithOrder = new List<Phase__c>();
			for (Phase__c item : (List<Phase__c>)Trigger.old) {
				if (item.Order__c != null) {
                    phasesWithOrder.add(item);
                }

			}

            for (Phase__c item : phasesWithOrder) {
                if (featureToggleSetting.NewChangeOrderFlow__c) {
                    if (item.Last_Phase__c == null) {
                        validatePhaseRecordType(item, profileMapNames);
                    }
                } else {
                    validatePhaseRecordType(item, profileMapNames);
                }
            }
        }

		private boolean validatePhaseRecordType(Phase__c phaseToValidate, Map<Id, Profile> profileMapNames) {

			//Only users with profiles "System Administrator" or "Sales Manager - BusinessProcessing"
			//should be able to delete Phases with "ProServ Phase" record type.

            //EU Privacy Phase 3 changes - START
            List<String> ProfList=new List<String>();//------created to store Sys Admin and sales Mgr profile plus its EU restricted one
			List<EU_Component_Reference__mdt> euComp = [Select Values__c from EU_Component_Reference__mdt where Apex_Classes__c like '%PhaseTriggerHandler%' and DeveloperName = 'Sys_Admin_Sales_Manager' ]; 
            for(EU_Component_Reference__mdt e:euComp){
                if(String.isNotBlank(e.Values__c)){
                    ProfList.addAll(e.Values__c.split(','));   }
                }
    		String profileName = profileMapNames.get(userinfo.getProfileId()).Name;
			if (phaseToValidate.RecordTypeId == PhaseHelper.RT_ID_PROSERV_PHASE
                && !ProfList.contains(profileName)) // EU Privacy Phase 3 changes - END
               {
				phaseToValidate.addError('Only System Administrators are allowed to create or delete ProServ Phases');
				return false;
			}
			return true;
		}
	}

	public class DeleteRelatedPLI extends Triggers.TriggerHandlerBase {
		override public void handle() {
			//When phase is deleted - remove all related pli
			Map<Id, Hardware_Line_Item__c> hlis = new Map<Id, Hardware_Line_Item__c>(
                [SELECT Id, RingCentral_Hardware_Phase__c
                FROM Hardware_Line_Item__c
                WHERE RingCentral_Hardware_Phase__c
                    IN :Trigger.oldMap.keySet()]);

            try {
                delete(hlis.values());
            } catch(DmlException e) {
                Trigger.oldMap.get(hlis.get(e.getDmlId(0)).RingCentral_Hardware_Phase__c)
                    .addError(PhaseHelper.CANNOT_DELETE_COMPLETED_PHASE);
            }
		}
	}

	public class LockOrder extends Triggers.TriggerHandlerBase {
		override public void handle() {
			SiteAfterTriggerHandler.autoLockOrder(Trigger.newMap);
		}
	}

	public class PopulateAssetDeliveredQuantity extends Triggers.TriggerHandlerBase {
		override public void handle () {
			Set <Id> phaseId = new Set <Id>();
			//Get ids of phases which were completed
			for (Phase__c p : (List <Phase__c>)Trigger.new) {
				Boolean isCompletedPhase =
					isChangedFieldTo(p, Phase__c.BillingStatus__c, PhaseHelper.BILLING_STATUS_SUBMITTED)
					|| isChangedFieldFrom(p, Phase__c.Completed_Date__c, null)
					&& isChangedFieldTo(p, Phase__c.BillingStatus__c, PhaseHelper.BILLING_STATUS_MANUAL);
				if (isCompletedPhase) {
					phaseId.add(p.Id);
				}
			}
			//If phases where completed
			if (!phaseId.isEmpty()) {
				//Get all phase line items under updated phases
				List <Hardware_Line_Item__c> hliList = [
						SELECT id, Quote_Line_Item__r.Product2Id, Order_Line_Item__c,
								Order_Line_Item__r.Asset__c,
								RingCentral_Hardware_Phase__r.Completed_Date__c, Quantity__c
						FROM Hardware_Line_Item__c
						WHERE RingCentral_Hardware_Phase__c IN:phaseId
				];

				//Build asset id to phase line items map
				Map <Id, List<Hardware_Line_Item__c>> assetIdToPliListMap = new Map <Id, List<Hardware_Line_Item__c>>();
				for (Hardware_Line_Item__c pli : hliList) {
					if (pli.Order_Line_Item__c != null && pli.Order_Line_Item__r.Asset__c != null) {
						if (!assetIdToPliListMap.containsKey(pli.Order_Line_Item__r.Asset__c)) {
							assetIdToPliListMap.put(pli.Order_Line_Item__r.Asset__c, new List<Hardware_Line_Item__c>());
						}
						assetIdToPliListMap.get(pli.Order_Line_Item__r.Asset__c).add(pli);
					}
				}

				AssetSelector selector = new AssetSelector();
				List<Object> bindings = new List<Object>();
				bindings.add(assetIdToPliListMap.keyset());
				List<Asset> assetList = selector.selectAssetsByIds(bindings).executeQuery();

				for (Asset assetRecord : assetList) {
					if (assetRecord.Delivered_Quantity__c == null) {
                        assetRecord.Delivered_Quantity__c = 0;
                    }
					for (Hardware_Line_Item__c pli : assetIdToPliListMap.get(assetRecord.Id)) {
						if (pli.RingCentral_Hardware_Phase__r.Completed_Date__c != null) {
							assetRecord.Delivered_Quantity__c += pli.Quantity__c;
						}
					}
					assetMapStatic.put(assetRecord.Id, assetRecord);
				}
				if (!assetMapStatic.isEmpty()) {
                    update assetMapStatic.values();
                }
			}
		}
	}

	private static Map<Id, Order> buildOrderMap(Set<Id> orderIdSet) {

		OrderSelector selector = new OrderSelector();
		List<Object> bindings = new List<Object>();
		bindings.add(orderIdSet);

		return new Map<Id, Order>(
			(List<Order>) selector.selectOrdersByIds(bindings).executeQuery()
		);
	}


	public class PopulateMaxPhaseNumberOnOrder extends Triggers.TriggerHandlerBase {

		override public void handle() {

			Set<Id> orderIdSet = new Set<Id>();
			Set<Id> phasesToDeleteIdSet = new Set<Id>();

			for (Phase__c phase : (List<Phase__c>) (Trigger.isDelete ? Trigger.old : Trigger.new)) {

				if (phase.Order__c == null) {
					continue;
				}

				if (Trigger.isInsert) {

					orderIdSet.add(phase.Order__c);

				}else if (Trigger.isUpdate &&
					(isChangedField(phase, Phase__c.Order__c) || isChangedField(phase, Phase__c.Phase_Number__c))) {

					orderIdSet.add(phase.Order__c);
				}else if (Trigger.isDelete) {
					orderIdSet.add(phase.Order__c);
					phasesToDeleteIdSet.add(phase.Id);
				}
			}

			if (orderIdSet.isEmpty()) {
				return;
			}

			List<Order> ordersToUpdate = new List<Order>();

			OrderSelector selector = new OrderSelector();
			List<Object> bindings = new List<Object>();
			bindings.add(orderIdSet);
			bindings.add(phasesToDeleteIdSet);
			List<Order> orderList = selector.selectOrderWithPhases(bindings).executeQuery();

			for (Order ord : orderList) {

				Integer maxPhaseNum = findMaxPhaseNumber(ord.Phases__r);

				if (ord.MaxPhaseNumber__c == null || maxPhaseNum > ord.MaxPhaseNumber__c) {
					ord.MaxPhaseNumber__c = maxPhaseNum;
					ordersToUpdate.add(ord);
				}
			}

			if (!ordersToUpdate.isEmpty()) {
				update ordersToUpdate;
			}
		}

		private Integer findMaxPhaseNumber(List<Phase__c> phases) {

			Integer result = 0;

			if (phases == null || phases.isEmpty()) {
				return result;
			}

			for (Phase__c ph : phases) {
				Integer phaseNum = ph.Phase_Number__c == null ? 0 : (Integer) ph.Phase_Number__c;
				if (result != Math.max(result, phaseNum)) {
					result = phaseNum;
				}
			}

			return result;
		}
	}

    public class PhaseBefore extends Triggers.TriggerHandlerBase {
    /** Logic for Mavenlink integration */
        override public void handle() {
            // Mavenlink integration shouldn't be triggered on Change Order
            if (!syncChangeOrders && changeOrderFlow) {
                return;
            }
            //Checking Feature Toggle Integration checkbox
            if (!Feature_Toggle__c.getInstance().Mavenlink_Integration__c || updateFromMavenlink) {
                return;
            }

            //Avoid double Phase Trigger firing
            MavenlinkIntegratorTriggerHandler.updateFromPhaseTrigger = true;
            //Adding related object's ids for checking required fields
            for (Phase__c phase : (List<Phase__c>)Trigger.new) {
                if (PhaseTriggerHandler.isValidPhase(phase)) {
                    if (phase.Id != null) {
                        phaseIds.add(phase.Id);
                    }
                    accountsByPhaseId.put(phase.Account__c, null);
                    usersByPhaseId.put(phase.Quote__r.ProServProjectManager__r.ManagerId, null);
                    opportunitiesByPhaseId.put(phase.Opportunity__c, null);
                    quotesByPhaseId.put(phase.Quote__c, null);
                    originalQuotesByPhaseId.put(phase.OriginalQuoteNumber__c, null);
                    ordersByPhaseId.put(phase.Order__c, null);
                }
            }
            //Fetching related objects
            if (!accountsByPhaseId.keySet().isEmpty()
                && !(accountsByPhaseId.keySet().size() == 1 && accountsByPhaseId.keySet().contains(null))) {
                accountsByPhaseId = new Map<Id, Account>([
                    SELECT Contact_Center_Start_Date__c, Current_Owner_Name__c, Current_Owner_Manager_Name__c,
                        Segment__c, CSM_Name__c, RC_User_ID__c, Name
                    FROM Account
                    WHERE Id IN :accountsByPhaseId.keySet()
                ]);
            }
            if (!usersByPhaseId.keySet().isEmpty()
                && !(usersByPhaseId.keySet().size() == 1 && usersByPhaseId.keySet().contains(null))) {
                usersByPhaseId = new Map<Id, User>([
                    SELECT Id
                    FROM User
                    WHERE Id IN :usersByPhaseId.keySet()
                ]);
            }
            if (!opportunitiesByPhaseId.keySet().isEmpty()
                && !(opportunitiesByPhaseId.keySet().size() == 1 && opportunitiesByPhaseId.keySet().contains(null))) {
                opportunitiesByPhaseId = new Map<Id, Opportunity>([
                    SELECT CloseDate, CurrencyIsoCode, Parent_Order__c, EstimatedProfessionalServices12Month__c, Name,
                        Owner.Name, Opportunity_Owner_Segment__c, Owner_Manager_Name__c
                    FROM Opportunity
                    WHERE Id IN :opportunitiesByPhaseId.keySet()
                ]);
            }
            if (!quotesByPhaseId.keySet().isEmpty()
                && !(quotesByPhaseId.keySet().size() == 1 && quotesByPhaseId.keySet().contains(null))) {
                quotesByPhaseId = new Map<Id, Quote>([
                    SELECT ProServProjectManager__r.Name, ProServSalesRep__r.Name, ProServ_Sold_Date__c, QuoteNumber,
                        ProServProjectManager__r.ManagerId, ProServProjectManager__r.Manager.Name, RecordType.Name,
                        TotalProjectHoursQuoted__c, T_E__c, OriginalQuoteNumber__c, RecordTypeId
                    FROM Quote
                    WHERE Id IN :quotesByPhaseId.keySet()
                ]);
            }
            if (!originalQuotesByPhaseId.keySet().isEmpty()
                && !(originalQuotesByPhaseId.keySet().size() == 1 && originalQuotesByPhaseId.keySet().contains(null))) {
                originalQuotesByPhaseId = new Map<Id, Quote>([
                    SELECT QuoteNumber
                    FROM Quote
                    WHERE Id IN :originalQuotesByPhaseId.keySet()
                ]);
            }
            if (!ordersByPhaseId.keySet().isEmpty()
                && !(ordersByPhaseId.keySet().size() == 1 && ordersByPhaseId.keySet().contains(null))) {
                ordersByPhaseId = new Map<Id, Order>([
                    SELECT Account_UID__c, AccountId, OrderNumber, RecordType.Name, SOW_Type__c, Signed_SOW__c,
                        Account.Name, CreatedDate, Estimated_ProServ_OTP__c
                    FROM Order
                    WHERE Id IN :ordersByPhaseId.keySet()
                ]);
            }
            mavenlinkRecords.clear();

            List<CurrencyType> currencyTypes = (List<CurrencyType>) new CurrencyTypeSelector()
                .selectActiveCurrencyTypes()
                .executeQuery();

            for (CurrencyType c : currencyTypes) {
                isoWithRateMap.put(c.IsoCode, c.ConversionRate);
            }
            for (Phase__c phase : (List<Phase__c>)Trigger.new) {
                //B-8848 Mavenlink Phase 2: Add 'OriginalQuoteNumber' field in quote and phase
                if (Trigger.isInsert && Trigger.isBefore) {
                    Quote quote = quotesByPhaseId.get(phase.Quote__c);
                    if (!quotesByPhaseId.keySet().isEmpty()) {
                        if (QuoteHelper.PROSERV_QUOTE_DEVELOPER_ID_SET.contains(quote.RecordTypeId)) {
                            phase.OriginalQuoteNumber__c = quote.OriginalQuoteNumber__c == null
                            ? quote.Id
                            : quote.OriginalQuoteNumber__c;
                        }
                    }
                }

                if (isValidRelatedRecords(phase)) {
                    if (Trigger.isUpdate) {
                        PhaseTriggerHandler.checkAllPhases(phase);
                    }
                    if (Trigger.isInsert && Trigger.isBefore) {
                        phase.MavenlinkIntegrationStatus__c = SUCCESS_CREATE;
                    }
                } else if (opportunitiesByPhaseId.get(phase.Opportunity__c) != null) {
                    if (!syncChangeOrders && String.isNotBlank(opportunitiesByPhaseId.get(phase.Opportunity__c).Parent_Order__c)) {
                        phase.MavenlinkIntegrationStatus__c = ORDER_STATUS;
                    }
                } else {
                    phase.MavenlinkIntegrationStatus__c = OPP_STATUS;
                }
            }
            if (isMLRecordAlreadyInserted == false) {
                insertMlRecords();
            }
        }
    }

    //Create ML records for Phases and assign Phase Id after Phase's insert
    public class PhaseAfter extends Triggers.TriggerHandlerBase {
        override public void handle() {
            if (Trigger.isInsert) {
                if (!Feature_Toggle__c.getInstance().Mavenlink_Integration__c || updateFromMavenlink) {
                    return;
                }
                for (Phase__c phase : (List<Phase__c>)Trigger.new) {
                    if (isValidRelatedRecords(phase)) {
                        PhaseTriggerHandler.checkAllPhases(phase);
                    }
                }
                insertMlRecords();
            }
        }
    }

    //Assigning ML integration status for Phase, depend on required fields
    private static void checkAllPhases(Phase__c phase) {
        if (isValidPhase(phase)) {
            if (hasRequiredFields(phase)) {
                if (Trigger.isUpdate || Trigger.isAfter) {
                    Mavenlink_Integrator__c mlRecord = new Mavenlink_Integrator__c();
                    assignFields(phase, mlRecord);
                    mavenlinkRecords.add(mlRecord);
                }
                if (!Trigger.isAfter) {
                    phase.MavenlinkIntegrationStatus__c = SUCCESS_UPDATE;
                }
            } else {
                if (!Trigger.isAfter) {
                    phase.MavenlinkIntegrationStatus__c = errorFields;
                }
            }
        }
    }

    //Checking required fields on the related objects and populating error string if not
    private static Boolean hasRequiredFields(Phase__c phase) {
        errorFields = '';
        Boolean isFormulaField = false;
        if (phase.Initial_Payment__c == null && phase.Status__c != PhaseHelper.STATUS_DELETED) {
            errorFields += 'Phase OTP on Phase, ';
        }
        if (accountsByPhaseId.get(phase.Account__c) != null) {
            if (String.isBlank(accountsByPhaseId.get(phase.Account__c).RC_User_ID__c)) {
                isFormulaField = true;
            }
        } else {
            errorFields += 'Current Owner Name, Current Owner Manager Name, Sales Segment on related Account, ';
        }
        if (opportunitiesByPhaseId.get(phase.Opportunity__c) != null) {
            Boolean isOpportunityField = false;
            if (opportunitiesByPhaseId.get(phase.Opportunity__c).CloseDate == null) {
                isOpportunityField = true;
                errorFields += 'Close Date, ';
            }
            if (opportunitiesByPhaseId.get(phase.Opportunity__c).EstimatedProfessionalServices12Month__c == null) {
                isOpportunityField = true;
                errorFields += 'Estimated Pro Services SOW, ';
            }
            if (isOpportunityField) {
                errorFields = errorFields.left(errorFields.length() - 2);
                errorFields += ' on related Opportunity, ';
            }
        } else {
            errorFields += 'Close Date, Estimated Pro Services SOW on related Opportunity, ';
        }
        if (quotesByPhaseId.get(phase.Quote__c) != null) {
            Boolean isQuoteField = false;
            if (quotesByPhaseId.get(phase.Quote__c).ProServ_Sold_Date__c == null) {
                isQuoteField = true;
                errorFields += 'ProServ Sold Date, ';
            }
            if (quotesByPhaseId.get(phase.Quote__c).ProServSalesRep__c == null
                || (quotesByPhaseId.get(phase.Quote__c).ProServSalesRep__c != null
                && quotesByPhaseId.get(phase.Quote__c).ProServSalesRep__r.Name == null)) {
                isQuoteField = true;
                errorFields += 'ProServ Architect, ';
            }
            if (quotesByPhaseId.get(phase.Quote__c).QuoteNumber == null) {
                isQuoteField = true;
                errorFields += 'Quote Number, ';
            }
            if (isQuoteField) {
                errorFields = errorFields.left(errorFields.length() - 2);
                errorFields += ' on related Quote, ';
            }
        } else {
            errorFields += 'ProServ Sold Date, ProServ Architect, Quote Number on related Quote, ';
        }
        if (ordersByPhaseId.get(phase.Order__c) != null) {
            Boolean isOrderField = false;
            if (String.isBlank(ordersByPhaseId.get(phase.Order__c).OrderNumber)) {
                isOrderField = true;
                errorFields += 'Order Number, ';
            }
            if (ordersByPhaseId.get(phase.Order__c).RecordType == null) {
                isOrderField = true;
                errorFields += 'Record Type, ';
            }
            if (String.isBlank(ordersByPhaseId.get(phase.Order__c).SOW_Type__c)) {
                isOrderField = true;
                errorFields += 'SOW Type, ';
            }
            if (String.isBlank(ordersByPhaseId.get(phase.Order__c).Signed_SOW__c)) {
                isOrderField = true;
                errorFields += 'Signed SOW, ';
            }
            if (isFormulaField) {
                isOrderField = true;
                errorFields += 'Account UID, ';
            }
            if (isOrderField) {
                errorFields = errorFields.left(errorFields.length() - 2);
                errorFields += ' on related Order, ';
            }
        } else {
            errorFields += 'Order Number, Record Type, SOW Type, Signed SOW, Account UID on related Order, ';
        }
        if (!String.isEmpty(errorFields)) {
            errorFields = errorFields.left(errorFields.length() - 2);
            errorFields += ' must be populated for the Integration.';
        }
        return String.isEmpty(errorFields);
    }

    //Checking that Phase has required Record type and Phase is not on Changed Order
    private static Boolean isValidPhase(Phase__c phase) {
        Map<String, Schema.RecordTypeInfo> phaseRecordTypesInfo =
                                            Schema.SObjectType.Phase__c.getRecordTypeInfosByName();
        Set<String> phaseRecordTypes = new Set<String>{
                                            phaseRecordTypesInfo.get('ProServ Phase').getRecordTypeId(),
                                            phaseRecordTypesInfo.get('RingCentral Hardware Phase').getRecordTypeId()
                                                        };
        return phaseRecordTypes.contains(phase.RecordTypeId) && phase.IsCloned__c == false;
    }

    private static void insertMlRecords() {
        if (!mavenlinkRecords.isEmpty()) {
            for (Mavenlink_Integrator__c mlRecord : mavenlinkRecords) {
                mlRecord.ProcessStatus__c = 'N';
            }
            insert mavenlinkRecords;
            isMLRecordAlreadyInserted = true;
        }
    }

    //Assingning values from Phase to ML integrator
    private static void assignFields(Phase__c phase, Mavenlink_Integrator__c mlRecord) {
        if (phase.Id != null) {
            mlRecord.PhaseId__c = phase.Id;
        }
        if (ordersByPhaseId.get(phase.Order__c).Account != null) {
            mlRecord.AccountId__c = ordersByPhaseId.get(phase.Order__c).Account.Name;
        } else {
            mlRecord.AccountId__c = null;
        }
        mlRecord.Account__c = ordersByPhaseId.get(phase.Order__c).AccountId;
        mlRecord.Account_UID__c = ordersByPhaseId.get(phase.Order__c).Account_UID__c;
        mlRecord.Contact_Center_Start_Date__c = accountsByPhaseId.get(phase.Account__c)
                                                                    .Contact_Center_Start_Date__c;
        mlRecord.CSM_Name__c = accountsByPhaseId.get(phase.Account__c).CSM_Name__c;
        mlRecord.Current_Owner_Manager_Name__c = accountsByPhaseId.get(phase.Account__c)
                                                                    .Current_Owner_Manager_Name__c;
        mlRecord.Current_Owner_Name__c = accountsByPhaseId.get(phase.Account__c).Current_Owner_Name__c;
        mlRecord.Direction__c = 'Outbound';
        mlRecord.EstimatedProfessionalServices12Month__c =
                                            opportunitiesByPhaseId.get(phase.Opportunity__c).CurrencyIsoCode;
        if (quotesByPhaseId.get(phase.Quote__c).ProServProjectManager__c != null
            && quotesByPhaseId.get(phase.Quote__c).ProServProjectManager__r.Manager != null) {
            mlRecord.ManagerOfProServProjectManager__c =
                                            quotesByPhaseId.get(phase.Quote__c).ProServProjectManager__r.Manager.Name;
        } else {
            mlRecord.ManagerOfProServProjectManager__c = null;
        }
        mlRecord.ObjectId__c = phase.Id;
        mlRecord.OpportunityCloseDate__c = opportunitiesByPhaseId.get(phase.Opportunity__c).CloseDate;
        mlRecord.OrderNumber__c = ordersByPhaseId.get(phase.Order__c).OrderNumber;
        mlRecord.OrderRecordType__c = ordersByPhaseId.get(phase.Order__c).RecordType.Name;
        mlRecord.PhaseName__c = phase.Name;
        mlRecord.Initial_Payment__c = convertCurrency(phase.CurrencyIsoCode, phase.Initial_Payment__c);
        mlRecord.ProServSalesRep__c = quotesByPhaseId.get(phase.Quote__c).ProServSalesRep__r.Name;
        if (quotesByPhaseId.get(phase.Quote__c).ProServProjectManager__c != null) {
            mlRecord.ProServProjectManager__c = quotesByPhaseId.get(phase.Quote__c).ProServProjectManager__r.Name;
        } else {
            mlRecord.ProServProjectManager__c = null;
        }
        mlRecord.ProServ_Sold_Date__c = quotesByPhaseId.get(phase.Quote__c).ProServ_Sold_Date__c;
        if (phase.OriginalQuoteNumber__c == null) {
            mlRecord.QuoteNumber__c = quotesByPhaseId.get(phase.Quote__c).QuoteNumber;
        } else {
            mlRecord.QuoteNumber__c = originalQuotesByPhaseId.get(phase.OriginalQuoteNumber__c).QuoteNumber;
        }
        mlRecord.Sales_Segment__c = accountsByPhaseId.get(phase.Account__c).Segment__c;
        mlRecord.Signed_SOW__c = ordersByPhaseId.get(phase.Order__c).Signed_SOW__c;
        mlRecord.SOW_Type__c = ordersByPhaseId.get(phase.Order__c).SOW_Type__c;
        mlRecord.Name = accountsByPhaseId.get(phase.Account__c).Name;
        mlRecord.PhaseStatus__c = phase.Completed_Date__c != null ? PhaseHelper.STATUS_COMPLETED : phase.Status__c;
        mlRecord.Estimated_Completion_Date__c = phase.Estimated_Completion_Date__c;
        mlRecord.Total_Project_Hours_Quoted__c = quotesByPhaseId.get(phase.Quote__c).TotalProjectHoursQuoted__c;
        mlRecord.TE__c = quotesByPhaseId.get(phase.Quote__c).T_E__c;
        mlRecord.ProjectCreatedDate__c = (ordersByPhaseId.get(phase.Order__c).CreatedDate).date();
        mlRecord.PSSOWValue__c = ordersByPhaseId.get(phase.Order__c).Estimated_ProServ_OTP__c;
        mlRecord.QuoteType__c = quotesByPhaseId.get(phase.Quote__c).RecordType.Name;
        mlRecord.ProjectName__c = opportunitiesByPhaseId.get(phase.Opportunity__c).Name;
        mlRecord.OpportunitySegment__c = opportunitiesByPhaseId.get(phase.Opportunity__c).Opportunity_Owner_Segment__c;
        mlRecord.OpportunityManager__c = opportunitiesByPhaseId.get(phase.Opportunity__c).Owner_Manager_Name__c;
        mlRecord.OpportunityAE__c = opportunitiesByPhaseId.get(phase.Opportunity__c).Owner.Name;
    }

    //Updating Phases, after required fields on related objects was updated
    public static void updateRelatedPhases(String objectName, Set<Id> relatedObjectIds) {

        if (!syncChangeOrders && changeOrderFlow) {
            return;
        }

        String query = 'SELECT MavenlinkIntegrationStatus__c ' +
                        'FROM Phase__c ' +
                        'WHERE ' + String.escapeSingleQuotes(objectName) + '__c' + ' IN :relatedObjectIds';
        List<Phase__c> phases = Database.query(query);
        if (!phases.isEmpty()) {
            List<Phase__c> phasesToUpdate = new List<Phase__c>();
            for (Phase__c phase : phases) {
                if (String.isNotBlank(phase.MavenlinkIntegrationStatus__c)
                    && phase.MavenlinkIntegrationStatus__c.containsIgnoreCase('related ' + objectName)) {
                    phasesToUpdate.add(phase);
                } else if ((objectName.equalsIgnoreCase('Account')
                    && String.isNotBlank(phase.MavenlinkIntegrationStatus__c)
                    && phase.MavenlinkIntegrationStatus__c.containsIgnoreCase('Account UID'))
                    || (objectName.equalsIgnoreCase('Quote'))) {
                    phasesToUpdate.add(phase);
                }
            }
            if (!phasesToUpdate.isEmpty()) {
                update phasesToUpdate;
            }
        }
    }

    public static Decimal convertCurrency(String currencyCode, Decimal amount) {
        Decimal convertedAmount;
        if (isoWithRateMap.containsKey(currencyCode)) {
            convertedAmount = (amount == null
                                ? 0
                                : amount)
                                / isoWithRateMap.get(currencyCode);
        }
        return convertedAmount;
    }

    public static Boolean isValidRelatedRecords(Phase__c phase) {
        return (ordersByPhaseId.get(phase.Order__c) != null
                && orderRecordTypeNames.contains(ordersByPhaseId.get(phase.Order__c).RecordType.Name)
                && opportunitiesByPhaseId.get(phase.Opportunity__c) != null
                && ( (!syncChangeOrders
                      && String.isBlank(opportunitiesByPhaseId.get(phase.Opportunity__c).Parent_Order__c))
                    || syncChangeOrders));
    }
    /** End of Mavenlink logic */
}