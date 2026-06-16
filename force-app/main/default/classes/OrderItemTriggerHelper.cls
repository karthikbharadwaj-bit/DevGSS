public with sharing class OrderItemTriggerHelper {

	public class HandleZeroQuantity extends Triggers.TriggerHandlerBase {
        override public void handle() {
			List<OrderItem> items = (List<OrderItem>) trigger.new;
			Map<Id, OrderItem> oldItemsMap = (Map<Id, OrderItem>) trigger.oldMap;
			for (OrderItem item : items) {
				if (item.Quantity == 0) {
					item.Quantity = 1;
					item.Zero_Quantity__c = true;
				} else {
					if (trigger.isUpdate &&
						item.Quantity != oldItemsMap.get(item.Id).Quantity) {
							item.Zero_Quantity__c = false;
					}
				}
			}
		}
	}

	private static final String ORDER_CC_PROF_SERVICE_RT_NAME = 'CC Professional Services';
	private static final String ORDER_PROF_SERVICE_RT_NAME = 'Professional Services';
	private static final String ORDER_RC_RT_NAME = 'RingCentral';
	private static final Map<String, Schema.RecordTypeInfo> ORDER_RT_INFO_BY_NAME = Order.SObjectType.getDescribe().getRecordTypeInfosByName();

	private static final Id ORDER_CC_PROF_SERVICE_RT_ID = ORDER_RT_INFO_BY_NAME.get(ORDER_CC_PROF_SERVICE_RT_NAME).getRecordTypeId();
	private static final Id ORDER_PROF_SERVICE_RT_ID = ORDER_RT_INFO_BY_NAME.get(ORDER_PROF_SERVICE_RT_NAME).getRecordTypeId();
	private static final Id ORDER_RC_RT_ID = ORDER_RT_INFO_BY_NAME.get(ORDER_RC_RT_NAME).getRecordTypeId();

    public static final String CCDESK_FEATURE_60_65_EMAIL_API_NAME = 'ccDesk_feature_60_65';

	public static Map<Id, Hardware_Line_Item__c> phaseLineItemMapStatic = new Map<Id, Hardware_Line_Item__c>();

    public static Boolean isRampUpChangeOrderItemInsert = false;

	public class PopulateOrderFields extends Triggers.TriggerHandlerBase {

		override public void handle() {
			List<OrderItem> items = (List<OrderItem>) Trigger.new;
			if(Trigger.isDelete) {
				items = (List<OrderItem>) Trigger.old;
			}

			Map<Id, List<OrderItem>> orderIdToOrderItemListMap = new Map<Id, List<OrderItem>>();

			Set<Id> deletedOrderItemIdSet = new Set<Id>();
			Set<Id> orderItemIdSet = new Set<Id>();
			Set<Id> priceBookEntriesIdSet = new Set<Id>();

			for(OrderItem item : items) {

				if( orderIdToOrderItemListMap.get(item.OrderId) == null ) {
					orderIdToOrderItemListMap.put(item.OrderId, new List<OrderItem>());
				}
				if( !Trigger.isDelete ) {
					orderIdToOrderItemListMap.get(item.OrderId).add(item);

					if( item.Id != null ) {
						orderItemIdSet.add( item.Id ); // in update case we should do not reselect updated Orderitems
					}

					priceBookEntriesIdSet.add(item.PricebookEntryId);
				}

				if( Trigger.isDelete ) {
					deletedOrderItemIdSet.add(item.Id);
				}

			}

			if( orderIdToOrderItemListMap.size() > 0 ) {

				List<OrderItem> oliList = [select Id,
											UnitPrice, Quantity,
											OrderId, Order.RecordTypeId,
											PricebookEntry.Product2.Charge_Term__c
										from OrderItem
										where OrderId in : orderIdToOrderItemListMap.keySet() AND
										Id not in : deletedOrderItemIdSet AND
										Id not in : orderItemIdSet];


				Map<Id, String> pbeIdToChargeTermMap = new Map<Id, String>();
				for(PriceBookEntry pbe : [select Id, Product2Id, Product2.Charge_Term__c from PricebookEntry where Id in : priceBookEntriesIdSet]) {
					pbeIdToChargeTermMap.put(pbe.Id, pbe.Product2.Charge_Term__c);
				}

				for(OrderItem item : oliList) {

					if(item.Order.RecordTypeId == ORDER_PROF_SERVICE_RT_ID || item.Order.RecordTypeId == ORDER_CC_PROF_SERVICE_RT_ID) {

						orderIdToOrderItemListMap.get(item.OrderId).add(item);

					}else{
						orderIdToOrderItemListMap.remove(item.OrderId);
					}

				}

				Map<Id, Order> orderToUpdate = new Map<Id, Order>();

				for(Id currentOrderId : orderIdToOrderItemListMap.keySet()) {
					List<OrderItem> orderItemsForCurrentOrder = orderIdToOrderItemListMap.get(currentOrderId);

					Double totalPricesOneTimeSumm = 0;
					Double totalPricesMonthlySumm = 0;
					Double totalPricesAnnualSumm = 0;

					Boolean updateCurrentOrder = false;

					for(OrderItem item : orderItemsForCurrentOrder) {

						String chargeTerm = item.PricebookEntry.Product2.Charge_Term__c;

						if(chargeTerm == null) {
							chargeTerm = pbeIdToChargeTermMap.get(item.PricebookEntryId);
						}

						Double totalPrice = ((item.UnitPrice == null) ? 0 : item.UnitPrice) * ((item.Quantity == null) ? 0 : item.Quantity);

						if( chargeTerm == 'One - Time' ) {
							totalPricesOneTimeSumm += totalPrice; // add totalPrice
							updateCurrentOrder = true;
						}else if( (chargeTerm == 'Monthly') || (chargeTerm == 'Monthly - Contract') ) {
							totalPricesMonthlySumm += totalPrice; // add totalPrice
							updateCurrentOrder = true;
						}else if( chargeTerm == 'Annual' ) {
							totalPricesAnnualSumm += totalPrice; // add totalPrice
							updateCurrentOrder = true;
						}
					}

					if(updateCurrentOrder) {

						orderToUpdate.put(
							currentOrderId,
							new Order(
								Id = currentOrderId,
								Estimated_ProServ_OTP__c = totalPricesOneTimeSumm/*,
								Estimated_ProServ_MRR__c = totalPricesMonthlySumm + (totalPricesAnnualSumm/12)*/
							)
						);

						updateCurrentOrder = false;
					}

				}

				if( orderToUpdate.size() > 0 ) {
					update orderToUpdate.values();
				}

			}

		}
	}
	//B-1942
	//List of
	private static final Set <String> extEntSupProduct = new Set<String>{Product2Helper.NAME_EXTENDED_ENTERPRISE_SUPPORT_GOLD,
																		Product2Helper.NAME_EXTENDED_ENTERPRISE_SUPPORT_PLATINUM,
																		Product2Helper.NAME_EXTENDED_ENTERPRISE_SUPPORT_SILVER};
	public class NotifyProserv extends Triggers.TriggerHandlerBase {
		override public void handle() {
			//Get product Id
			Set<Id> productsId = new Set<Id>();
			for(OrderItem oi : (List <OrderItem>)Trigger.new) {
				productsId.add(oi.Product2Id);
			}
			//Get product id to product record map
			Map<Id, Product2> idToProductMap = new Map<Id, Product2>([SELECT Id,
																			 Name,
																			 Feature__c
																	  FROM Product2
																	  WHERE Id IN : productsId]);

			//Build order id to order item list map
			Map<Id,List <OrderItem>> orderIdToOrderItemListMap = new Map<Id, List <OrderItem>>();
			for (OrderItem oi : (List <OrderItem>)Trigger.new) {
				if(!orderIdToOrderItemListMap.keyset().contains(oi.OrderId)) {
					orderIdToOrderItemListMap.put(oi.OrderId, new List <OrderItem>());
				}
				orderIdToOrderItemListMap.get(oi.OrderId).add(oi);
			}

			//Count amount of extended enterprise support products for every order
			Map<Id,decimal> orderIdProductQuantity = new Map<Id, decimal>();
			for (Id orderId : orderIdToOrderItemListMap.keyset()) {
				decimal amountOfextEntSupProduct = 0;
				for (OrderItem oi : orderIdToOrderItemListMap.get(orderId)) {
					Product2 oliProduct = idToProductMap.get(oi.product2Id);
					if (oliProduct.Feature__c == Product2Helper.FEATURE_EXTENDED_ENTERPRISE_SUPPORT
						&& (extEntSupProduct.contains(oliProduct.Name))) {
						amountOfextEntSupProduct += oi.Quantity;
					}
				}
				if (amountOfextEntSupProduct > 0) {
					orderIdProductQuantity.put(orderId,amountOfextEntSupProduct);
				}
			}

            if (!orderIdProductQuantity.isEmpty()) {
    			List <Order> ordersToProcess = [SELECT Id, Name, OrderNumber, Account.Name, Opportunity.Name FROM Order WHERE Id IN:orderIdProductQuantity.keyset()];
    			for(Order order : ordersToProcess) {
    				String accountName = order.Account.Name;
    				String accountId = order.Account.Id;
    				String opportunityName = order.Opportunity.Name;
    				String opportunityId = order.Opportunity.Id;
    				String orderNumber = order.OrderNumber;
    				String orderId = order.Id;
    				String numberOfSeats = String.valueOf(orderIdProductQuantity.get(order.Id).setScale(0));
    				sendMailViaTemplate(accountName, accountId, opportunityName, opportunityId, numberOfSeats, orderId, orderNumber, 'Notify_Proserv');
    			}
            }
		}

		public void sendMailViaTemplate(String accountName, String accountId, String opportunityName, String opportunityId, String numberOfSeats, String orderId, String orderNumber, String developerName) {
            EmailTemplate template = [SELECT Id, Name, DeveloperName, Body, HtmlValue, Subject
			                 		FROM EmailTemplate
			                 		WHERE IsActive = true
			                 		AND DeveloperName = :developerName];

            if(template != null) {
               	List<String> emailToAdresses = new List<String>();
				if (Emails__c.getall().get('proservleaders') == null
					|| !String.isNotBlank(Emails__c.getall().get('proservleaders').Email_Address__c) ){
					return;
				}
				emailToAdresses.add(Emails__c.getall().get('proservleaders').Email_Address__c);
				if(emailToAdresses.size() > 0) {
	                String emailSubject = template.Subject;
	                String emailTextBody = template.Body;
	                String emailHtmlBody = template.HtmlValue;

	                String baseUrl = URL.getOrgDomainUrl().toExternalForm();

	                //Find and replace place holders with corresponding values in the template
	                emailHtmlBody = emailHtmlBody.replaceAll('(?i)\\$\\{AccountName\\}', accountName);
	                emailHtmlBody = emailHtmlBody.replaceAll('(?i)\\$\\{AccountLink\\}', baseUrl + '/' +accountId);

	                emailHtmlBody = emailHtmlBody.replaceAll('(?i)\\$\\{OpportunityName\\}', opportunityName);
	                emailHtmlBody = emailHtmlBody.replaceAll('(?i)\\$\\{OpportunityLink\\}', baseUrl + '/' +opportunityId);

	                emailHtmlBody = emailHtmlBody.replaceAll('(?i)\\$\\{NumberOfSeats\\}', numberOfSeats);
	                emailHtmlBody = emailHtmlBody.replaceAll('(?i)\\$\\{NumberOfSeatsLink\\}', baseUrl + '/' +numberOfSeats);

	                emailHtmlBody = emailHtmlBody.replaceAll('(?i)\\$\\{OrderNumber\\}', orderNumber);
	                emailHtmlBody = emailHtmlBody.replaceAll('(?i)\\$\\{OrderNumberLink\\}', baseUrl + '/' +orderId);

	                emailSubject = emailSubject.replaceAll('(?i)\\$\\{AccountName\\}',  accountName);
	                emailSubject = emailSubject.replaceAll('(?i)\\$\\{AccountLink\\}', baseUrl + '/' +accountName);

                    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                    mail.setToAddresses(emailToAdresses);
                    mail.setSubject(emailSubject);
                    mail.setPlainTextBody(emailTextBody);
                    mail.setHtmlBody(emailHtmlBody);
                    // Send the email
                    Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
            	}
           	}
    	}
    }

    public class NotifyCcDesk extends Triggers.TriggerHandlerBase {
		override public void handle() {
			//Get product Id
			Set<Id> productsId = new Set<Id>();
			for(OrderItem oi : (List <OrderItem>)Trigger.new) {
				productsId.add(oi.Product2Id);
			}

			List<Product2> productList = new List<Product2>([SELECT Id, Name, Feature__c
																FROM Product2
																WHERE Id IN : productsId]);
			for(Product2 p : productList) {
				if(p.Feature__c == Product2Helper.FEATURE_LIVE_REPORTS || p.Feature__c == Product2Helper.FEATURE_INCONTACT_INTERCONNECT) {
					String templateApiName = CCDESK_FEATURE_60_65_EMAIL_API_NAME;

					OrderItem oi = (OrderItem)Trigger.new[0];
					sendMailViaTemplate(templateApiName, oi.OrderId);
					break;
				}
			}
		}

		public void sendMailViaTemplate(String templateApiName, Id orderId) {

			EmailTemplate template = [SELECT Name, DeveloperName, Body, HtmlValue, Subject
			                 		  FROM EmailTemplate
			                 		  WHERE IsActive = true
			                 		  AND DeveloperName = :templateApiName];

			String emailSubject = template.Subject;
            String emailTextBody = template.Body;
			String emailHtmlBody = template.HtmlValue;

			List<String> emailToAdresses = new List<String>();

			String ccDeskEmail = Emails__c.getAll().get('ccdesk').Email_Address__c;
			if(!String.isBlank(ccDeskEmail)) {
				emailToAdresses.add(ccDeskEmail);
			}

            emailSubject = TemplateEngine.createFromString(orderId, emailSubject);
            emailHtmlBody = TemplateEngine.createFromString(orderId, emailHtmlBody);
            emailTextBody = TemplateEngine.createFromString(orderId, emailTextBody);

            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(emailToAdresses);
            mail.setSubject(emailSubject);
            mail.setPlainTextBody(emailTextBody);
            mail.setHtmlBody(emailHtmlBody);

            // Send the email
            if(!emailToAdresses.isEmpty()) {
            	Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
            }
		}
    }

    //B-2940 Estimated ProServ MRR field calculation
    public class CalcEstimatedProServMRR extends Triggers.TriggerHandlerBase {
    	override public void handle(){
    		set<Id> orderIds = new set<Id>();
			map<Id,list<OrderItem>> ordersWithRCProducts = new map<Id,list<OrderItem>>();
    		list<OrderItem> items = (list<OrderItem>)(trigger.isDelete ? trigger.old : trigger.new);

			for(OrderItem item : items){
				if(item.OrderId != null) {
					orderIds.add(item.OrderId);
				}
			}

			for(OrderItem item : [
				SELECT Id, TotalPrice, OrderId, Order.RecordTypeId, Product2Id, Product2.Charge_Term__c, Product2.Sub_Category__c
				FROM OrderItem
				WHERE OrderId IN :orderIds]){

				if(item.Order.RecordTypeId == ORDER_RC_RT_ID){
					list<OrderItem> temp = (ordersWithRCProducts.containsKey(item.OrderId) ? ordersWithRCProducts.get(item.OrderId) : new list<OrderItem>());
					temp.add(item);
					ordersWithRCProducts.put(item.OrderId, temp);
				}
			}

			map<Id,Order> orderToUpdate = new map<Id,Order>();
			for(Id orderId : ordersWithRCProducts.keySet()) {
				Double totalPricesAnnualSumm = 0;
				Double totalPricesMonthlySumm = 0;

				for(OrderItem item : ordersWithRCProducts.get(orderId)){
					if(item.Product2.Sub_Category__c == 'Professional Services' || item.Product2.Sub_Category__c == 'CC Professional Services'){
						String chargeTerm = item.Product2.Charge_Term__c;
						if(chargeTerm == 'Annual') {
							totalPricesAnnualSumm += item.TotalPrice;
						}
						if(chargeTerm == 'Monthly' || chargeTerm == 'Monthly - Contract') {
							totalPricesMonthlySumm += item.TotalPrice;
						}
					}
				}

				orderToUpdate.put(orderId, new Order(
					Id = orderId,
					Estimated_ProServ_MRR__c = totalPricesMonthlySumm + totalPricesAnnualSumm / 12
				));
			}

			if(orderToUpdate.size() > 0) {
				update orderToUpdate.values();
			}
    	}
    }

    public class UpdatePhaseLineItem extends Triggers.TriggerHandlerBase {
    	override public void handle() {
    		//Build quote line item id to order item map
    		Map <Id, OrderItem> orderItemMap = new Map <Id, OrderItem>();
    		for (OrderItem oi : (list<OrderItem>) trigger.new) {
    			//There is one case when order item has QuoteLineItemId = null. When quote.Credit_Amount__c > 0 an order item
    			//for non existing quotelineitem is generated for 'Special Terms Credit' product
    			if (oi.QuoteLineItemId != null) {
    				orderItemMap.put(oi.QuoteLineItemId, oi);
    			}
    		}
    		//Get all phase line items related to quote line items
    		List <Hardware_Line_Item__c> phaseLineItems = [SELECT id, Quote_Line_Item__c, Order_Line_Item__c, RingCentral_Hardware_Phase__r.Order__c
    														FROM Hardware_Line_Item__c
    														WHERE Quote_Line_Item__c IN: orderItemMap.keyset()];
			//Build quote line item id to phase line item list map
    		Map <Id, List <Hardware_Line_Item__c>> quoteLineItemIdToPhaseLineItemListMap = new Map <Id, List <Hardware_Line_Item__c>>();
    		for (Hardware_Line_Item__c hli : phaseLineItems) {
    			if (!quoteLineItemIdToPhaseLineItemListMap.keyset().contains(hli.Quote_Line_Item__c)) {
    				quoteLineItemIdToPhaseLineItemListMap.put(hli.Quote_Line_Item__c, new List<Hardware_Line_Item__c>());
    			}
    			quoteLineItemIdToPhaseLineItemListMap.get(hli.Quote_Line_Item__c).add(hli);
    		}
    		//Populate order and order line item lookUp fields on phase line item object
    		for (Id qliId : quoteLineItemIdToPhaseLineItemListMap.keyset()) {
    			for (Hardware_Line_Item__c hli : quoteLineItemIdToPhaseLineItemListMap.get(qliId)) {
    				hli.Order__c = (hli.RingCentral_Hardware_Phase__c != null) ? hli.RingCentral_Hardware_Phase__r.Order__c : null;
					hli.Order_Line_Item__c = orderItemMap.get(qliId).Id;
    				phaseLineItemMapStatic.put(hli.Id, hli);
    			}
    		}

    		if(!phaseLineItemMapStatic.isEmpty()) {
				update phaseLineItemMapStatic.values();
			}
    	}
    }

    // Add a product detail for each order.
    public without sharing class AddProductDetail extends Triggers.TriggerHandlerBase {
        override public void handle() {
            if (isRampUpChangeOrderItemInsert) {
                return;
            }
            List<ProductDetail__c> listProductDetails     = new List<ProductDetail__c>();
            List<Id>               listOrderItemIds       = new List<Id>(trigger.newMap.keySet());
            OrderItemSelector      orderItemQuerySelector = new OrderItemSelector();

            List<OrderItem> listOrderItems = (List<OrderItem>)
                orderItemQuerySelector.selectOrderItemsById(listOrderItemIds).executeQuery();

            for (OrderItem oi :listOrderItems) {
                if(Product2Helper.isCCProduct(oi.Product2)) {
                    listProductDetails.add(new ProductDetail__c(
                        QuantityOrThreshold__c = oi.QuantityOrThreshold__c,
                        OrderItem__c           = oi.Id,
                        RampUpStartDate__c     = oi.Order.Submitted_Date__c == null
                                                     ? System.now()
                                                     : oi.Order.Submitted_Date__c,
                        RampUp__c              = '0'
                    ));
                }
            }

            try {
                insert listProductDetails;
            } catch(DmlException e) {
                listProductDetails[0].addError(e.getMessage());
                System.debug(e.getMessage());
            }
        }
    }

    public without sharing class CalculateTotalsOnOrder extends Triggers.TriggerHandlerBase {
        override public void handle() {
            Set<Id> orderIds = new Set<Id>();
            for (OrderItem ordItem : (List<OrderItem>) Trigger.new) {
                orderIds.add(ordItem.OrderId);
            }

            List<Order> ordersToUpdate = new List<Order>();
            List<Order> ordersWithItems = (List<Order>) new OrderSelector()
                .newQueryFactory()
                .selectFields(new Set<String>{
                    'Id',
                    'RecordTypeId',
                    'QuoteId',
                    'Recurring_total__c',
                    'SeatMRR__c',
                    'NumberOfMainLicenses__c',
                    'MinuteBundle__c',
                    'TransportMRR__c'
                })
                .subselect(
                    new OrderItemSelector()
                        .newQueryFactory()
                        .selectFields(new Set<String>{
                            'Id',
                            'OrderId',
                            'Quantity',
                            'TotalPrice',
                            'TotalSummary__c',
                            'NewQuantity__c',
                            'EffectivePrice__c',
                            'ChargeTerm__c',
                            'Product2.ExtID__c',
                            'Product2.Name',
                            'Product2.Billing_Type__c',
                            'QuoteLineItemId',
                            'QuoteLineItem.Id',
                            'QuoteLineItem.TotalPrice',
                            'QuoteLineItem.EffectivePrice__c',
                            'QuoteLineItem.TotalSummary__c',
                            'QuoteLineItem.NewQuantity__c',
                            'QuoteLineItem.ChargeTerm__c',
                            'QuoteLineItem.Product_Lic_Id__c'
                        })
                )
                .setCondition('Id IN :bind0')
                .setQueryBindings(new List<Object>{orderIds})
                .executeQuery();

            if (ordersWithItems.isEmpty()) {
                return;
            }

            for (Order ord : ordersWithItems) {
                Order orderToUpdate = new Order(Id = ord.Id);
                Map<String, Decimal> orderTotals = new Map<String, Decimal>();
                Boolean isUpdated = false;

                for (OrderItem ordItem : ord.OrderItems) {
                    Decimal currentRecurringTotal = (Decimal) NumberHelper.getNumberNullSafe(
                        orderTotals.get('Recurring_total__c')
                    );
                    Decimal currentSeatMRR = (Decimal) NumberHelper.getNumberNullSafe(
                        orderTotals.get('SeatMRR__c')
                    );
                    Decimal currentNumberOfMainLicenses = (Decimal) NumberHelper.getNumberNullSafe(
                        orderTotals.get('NumberOfMainLicenses__c')
                    );
                    Decimal currentMinuteBundleQuantity = (Decimal) NumberHelper.getNumberNullSafe(
                        orderTotals.get('MinuteBundle__c')
                    );
                    Decimal currentTransportMRR = (Decimal) NumberHelper.getNumberNullSafe(
                        orderTotals.get('TransportMRR__c')
                    );

                    if (ordItem.QuoteLineItem != null) {
                        if (QuoteLineItemHelper.RECURRING_CHARGE_TERM_VALUES.contains(ordItem.ChargeTerm__c)
                            && ordItem.Product2.Billing_Type__c != Product2Helper.BILLING_TYPE_USAGE) {
                            orderTotals.put('Recurring_total__c', currentRecurringTotal + ordItem.EffectivePrice__c * ordItem.NewQuantity__c);
                        }

                        if (QuoteLineItemHelper.isSeatQli(ordItem.QuoteLineItem)) {
                            orderTotals.put('SeatMRR__c', currentSeatMRR + ordItem.TotalSummary__c);
                            if (ord.RecordTypeId != OrderHelper.SERVICE_NAME_TO_RT_ID.get(QuoteHelper.NGBS_OFFICE_PRODUCT)) {
                                Decimal newQuantity = (Decimal) NumberHelper.getNumberNullSafe(ordItem.NewQuantity__c);
                                orderTotals.put('NumberOfMainLicenses__c', currentNumberOfMainLicenses + newQuantity);
                            }
                        }
                    }

                    if (ordItem.Product2.ExtID__c == Product2Helper.MINUTE_BUNDLE_EXT_ID) {
                        orderTotals.put('MinuteBundle__c', currentMinuteBundleQuantity + ordItem.Quantity * Product2Helper.MINUTE_BUNDLE_CC_QUANTITY);
                        orderTotals.put('TransportMRR__c', currentTransportMRR + ordItem.EffectivePrice__c * ordItem.NewQuantity__c);
                    }
                }

                for (String key : orderTotals.keySet()) {
                    Decimal val = orderTotals.get(key);
                    if (val != ord.get(key)) {
                        orderToUpdate.put(key, val);
                        isUpdated = true;
                    }
                }

                if (isUpdated) {
                    ordersToUpdate.add(orderToUpdate);
                }
            }

            if (!ordersToUpdate.isEmpty()) {
                update ordersToUpdate;
            }
        }
    }
}