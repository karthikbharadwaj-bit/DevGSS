public with sharing class DQ_DealQualificationController {
    @AuraEnabled
    public static DealQualificationWrapper checkDQExistFOROpp(String OppId) {
        String brandName = 'Avaya Cloud Office';
        Id dqDiscountSalesRecordTypeId = Schema.SObjectType.DQ_Deal_Qualification_Discounts__c.getRecordTypeInfosByName().get('Sales Quote').getRecordTypeId();
    Id dqDiscountContactRecordTypeId = Schema.SObjectType.DQ_Deal_Qualification_Discounts__c.getRecordTypeInfosByName().get('Contact Center').getRecordTypeId();
    Map<String,String> mapOfPackageNameToId = new Map<String,String>();
        DealQualificationWrapper obj = new DealQualificationWrapper();
        obj.ProductCategoriesMap = DQ_DealQualificationUtil.getPickListValue('DQ_Deal_Qualification_Discounts__c','Product_Category__c');
        obj.ProductFamilyMap = DQ_DealQualificationUtil.getPickListValue('DQ_Deal_Qualification_Discounts__c','Product_Family__c');
        obj.ProductSubCategoriesMap = DQ_DealQualificationUtil.getPickListValue('DQ_Deal_Qualification_Discounts__c','Product_Sub_Categories__c');
        obj.dependentPicklist = getDependentMap('DQ_Deal_Qualification_Discounts__c','Product_Category__c','Product_Sub_Categories__c');
        obj.specialTermsPicklistValueMap = DQ_DealQualificationUtil.getPickListValue('DQ_Deal_Qualification__c','Special_Terms__c');
        obj.freeShippingTermsPicklistValueMap = DQ_DealQualificationUtil.getPickListValue('DQ_Deal_Qualification__c','Free_Shipping_Terms_Options__c');
        obj.ProductCategoriesContactMap =  DQ_DealQualificationUtil.getPickListValuesBasedOnRecordType('DQ_Deal_Qualification_Discounts__c',dqDiscountContactRecordTypeId,'Product_Category__c');
        obj.ProductCategoriesSalesMap =  DQ_DealQualificationUtil.getPickListValuesBasedOnRecordType('DQ_Deal_Qualification_Discounts__c',dqDiscountSalesRecordTypeId,'Product_Category__c');
        obj.quoteList = DQ_DealQualificationUtil.getQuotes(OppId);
        obj.isDQExist = false;
        DQ_Deal_Qualification__c objDQ = DQ_DealQualificationUtil.getDealQualification(OppId);
            Opportunity oppRec = DQ_DealQualificationUtil.getOppurtunityById(OppId);
            if(oppRec != null && oppRec.Brand_Name__c != null) {
                brandName = oppRec.Brand_Name__c;
            }
        //Adding Package Dynamic
            For(Product_Package__c objPackage : [SELECT Id,name,(SELECT Id,Description__c,Contract_Discount__c, Monthly_Price__c, Yearly_Price__c, No_of_Licenses__c
                                               FROM Product_Tier_Prices__r) FROM Product_Package__c
                                               WHERE Brand_Name__c = :brandName
                                               AND Active__c = true]) {
            if(objPackage.Product_Tier_Prices__r.isEmpty()){
                continue;
             }

             mapOfPackageNameToId.put(objPackage.name,objPackage.Id);
          }

          obj.mapOfPackageNameToId =   mapOfPackageNameToId;

         if(objDQ != null) {
            obj.isDQExist = true;
            obj.DQRec = objDQ;
            List<DQ_Deal_Qualification_Discounts__c> DQList = DQ_DealQualificationUtil.getDealQualificationDiscount(objDQ.Id);
            if(DQList != null && DQList.size() > 0) {
              obj.DQDiscountList = DQList;
            }
            else {
                obj.DQDiscountList = new List<DQ_Deal_Qualification_Discounts__c>{new DQ_Deal_Qualification_Discounts__c()};
            }
            //Contact Center
            List<DQ_Deal_Qualification_Discounts__c> DQContactCenterList = DQ_DealQualificationUtil.getDealQualificationDiscount(objDQ.Id,'Contact Center');
            if(DQContactCenterList != null && DQContactCenterList.size() > 0) {
              obj.DQDiscountContactCenterList = DQContactCenterList;
            }
            else {
                obj.DQDiscountContactCenterList = new List<DQ_Deal_Qualification_Discounts__c>{new DQ_Deal_Qualification_Discounts__c(RecordTypeId = dqDiscountContactRecordTypeId)};
            }
            //Sales Quote
            List<DQ_Deal_Qualification_Discounts__c> DQSalesQuoteList = DQ_DealQualificationUtil.getDealQualificationDiscount(objDQ.Id,'Sales Quote');
            if(DQSalesQuoteList != null && DQSalesQuoteList.size() > 0) {
              obj.DQDiscountSalesQuoteList = DQSalesQuoteList;
            }
            else {
                obj.DQDiscountSalesQuoteList = new List<DQ_Deal_Qualification_Discounts__c>{new DQ_Deal_Qualification_Discounts__c(RecordTypeId = dqDiscountSalesRecordTypeId)};
            }
            obj.approverList = DQ_ApprovalEngine1.getApproversForDQ(objDQ.Id);
            obj.highestStepNumber = getHighestStepOrderFromApprovalList(obj.approverList);
            Map<String,List<DQ_Deal_Qualification_Approver__c>> mapOfStepToApprover = new Map<String,List<DQ_Deal_Qualification_Approver__c>>();
            Map<String,List<DQSLAWrapper>> mapOfStepToSLAWrap = new Map<String,List<DQSLAWrapper>>();
          List<ApprovalStatusWrapper> listofApprovalStatusWrap = new List<ApprovalStatusWrapper>();
            System.debug('DQ_DealQualificationUtil.getDQApproverList>>>'+ DQ_DealQualificationUtil.getDQApproverList(objDQ.Id));

            Map<Integer, Integer> mapOfSubmitOrderVsSmallStep = new Map<Integer, Integer>();
            for(DQ_Deal_Qualification_Approver__c approverRec : DQ_DealQualificationUtil.getDQApproverList(objDQ.Id)) {
                Decimal NoOfSLADays = 0;
                DQSLAWrapper objSLARec = new DQSLAWrapper();
                if(approverRec.Status__c != 'Cancelled'){
                    if(approverRec.Approve_Reject_Date__c != null && approverRec.Submitted_Date__c != null) {
                        Date responseDate = Date.valueOf(approverRec.Approve_Reject_Date__c);
                        Date submittedDate = Date.valueOf(approverRec.Submitted_Date__c);
                        NoOfSLADays = getSLAInHours(approverRec.Approve_Reject_Date__c, approverRec.Submitted_Date__c);
                        if(NoOfSLADays > 0) {
                            objSLARec.noofDays = NoOfSLADays;
                        } else {
                            objSLARec.noofDays = 0;
                        }
                    } else if(approverRec.Approve_Reject_Date__c == null && approverRec.Submitted_Date__c != null) {
                        Date submittedDate = Date.valueOf(approverRec.Submitted_Date__c);
                        NoOfSLADays = getSLAInHours(DateTime.now(), approverRec.Submitted_Date__c);
                        if(NoOfSLADays > 0) {
                            objSLARec.noofDays = NoOfSLADays;
                        } else {
                            objSLARec.noofDays = 0;
                        }
                    }
                }

                Integer stepOrder = mapOfSubmitOrderVsSmallStep.get(Integer.valueOf(approverRec.Submitted_Order__c));
                if (stepOrder == null) {
                    stepOrder = Integer.valueOf(approverRec.Step_Order__c);
                }

                if (stepOrder > approverRec.Step_Order__c) {
                    stepOrder = Integer.valueOf(approverRec.Step_Order__c);
                }

                mapOfSubmitOrderVsSmallStep.put(Integer.valueOf(approverRec.Submitted_Order__c), stepOrder);

                if(mapOfStepToApprover.containsKey(String.valueOf(approverRec.Step_Order__c)+String.valueOf(approverRec.Submitted_Order__c))) {
                    mapOfStepToApprover.get(String.valueOf(approverRec.Step_Order__c)+String.valueOf(approverRec.Submitted_Order__c)).add(approverRec);
                } else {
                    mapOfStepToApprover.put(String.valueOf(approverRec.Step_Order__c)+String.valueOf(approverRec.Submitted_Order__c),new List<DQ_Deal_Qualification_Approver__c>{approverRec});
                }

                if(mapOfStepToSLAWrap.containsKey(String.valueOf(approverRec.Step_Order__c)+String.valueOf(approverRec.Submitted_Order__c))) {
                    objSLARec.approverRec = approverRec;
                    mapOfStepToSLAWrap.get(String.valueOf(approverRec.Step_Order__c)+String.valueOf(approverRec.Submitted_Order__c)).add(objSLARec);
                } else {
                    objSLARec.approverRec = approverRec;
                    mapOfStepToSLAWrap.put(String.valueOf(approverRec.Step_Order__c)+String.valueOf(approverRec.Submitted_Order__c),new List<DQSLAWrapper>{objSLARec});
                }
            }

            for(String stepNumber : mapOfStepToApprover.KeySet()) {
                ApprovalStatusWrapper objApproval = new ApprovalStatusWrapper();
                Integer stepNumberVal = Integer.valueOf(stepNumber.substring(0,1));
                Integer submitOrder = Integer.valueOf(stepNumber.substring(1,2));
                Integer smallStepFromMap = mapOfSubmitOrderVsSmallStep.get(submitOrder);

                if (smallStepFromMap != null && String.valueOf(smallStepFromMap + '' + submitOrder) == stepNumber) {
                    objApproval.showSubmittedDetail = true;
                }
                objApproval.stepNumber = String.valueof(mapOfStepToApprover.get(stepNumber)[0].Step_Order__c);
            objApproval.approverList = mapOfStepToApprover.get(stepNumber);
          objApproval.submittedDetails = mapOfStepToApprover.get(stepNumber)[0];
                objApproval.SLAWrapperList = mapOfStepToSLAWrap.get(stepNumber);
                listofApprovalStatusWrap.add(objApproval);
            }
            obj.ApproverDetailList = listofApprovalStatusWrap;



        } else {
            obj.DQRec = new DQ_Deal_Qualification__c(Status__c = 'New',
                                                     Renewal_Term__c = '12',
                                                     Charge_Term__c = 'Monthly',
                                                     Initial_Term__c = '12',
                                                     Minimum_Package_s__c = 'Standard');
            Map<Id, Opportunity> mapOfIdVsOpportunity = DQ_DealQualificationUtil.getOppurtunityById(new Set<Id> {OppId});

            if (mapOfIdVsOpportunity.containsKey(OppId)) {
                Opportunity oppRecord = mapOfIdVsOpportunity.get(OppId);
            }
        }
        obj.isEnableChangeApprover = isUserHaveChangeApprovalPermission();
        return obj;
    }

    @AuraEnabled
    public static List<QuoteLineItem> getPrimayQuoteLineDetails(String OppId){
        List<QuoteLineItem> QtLine =[select id, Product2.Name,UnitPrice,
                                     Discount_number__c, EffectivePrice__c,
                                     Quote.Opportunity.Total_Contract_Value__c,
                                     CurrencyIsoCode,
                                     Quote.Opportunity.CurrencyISOCode,
                                     Quantity,TotalPrice,Total12MonthPrice__c,
                                     Discount_type__c,LineNumber, Quote.OpportunityId, Quote.isPrimary__c, Quote.RecordType.Name
                        FROM QuoteLineItem
                        where Quote.OpportunityId =:OppId and Quote.isPrimary__c = true and Quote.RecordType.Name like 'Sales Quote%'
                               and UnitPrice != 0];

        return QtLine;
   }
    private static boolean isUserHaveChangeApprovalPermission () {
        return FeatureManagement.checkPermission('Enable_Change_Approvals');
    }

    public static List<ApprovalStatusWrapper> getApproverDetailListByDQId(Id dqId) {
        Map<String,List<DQ_Deal_Qualification_Approver__c>> mapOfStepToApprover = new Map<String,List<DQ_Deal_Qualification_Approver__c>>();
        Map<String,List<DQSLAWrapper>> mapOfStepToSLAWrap = new Map<String,List<DQSLAWrapper>>();
        List<ApprovalStatusWrapper> listofApprovalStatusWrap = new List<ApprovalStatusWrapper>();

        for(DQ_Deal_Qualification_Approver__c approverRec : DQ_DealQualificationUtil.getDQApproverList(dqId)) {
            Decimal NoOfSLADays = 0;
            DQSLAWrapper objSLARec = new DQSLAWrapper();
            if(approverRec.Status__c != 'Cancelled'){
                if(approverRec.Approve_Reject_Date__c != null && approverRec.Submitted_Date__c != null) {
                    Date responseDate = Date.valueOf(approverRec.Approve_Reject_Date__c);
                    Date submittedDate = Date.valueOf(approverRec.Submitted_Date__c);
                    NoOfSLADays = getSLAInHours(approverRec.Approve_Reject_Date__c, approverRec.Submitted_Date__c);
                    if(NoOfSLADays > 0) {
                        objSLARec.noofDays = NoOfSLADays;
                    } else {
                        objSLARec.noofDays = 0;
                    }
                } else if(approverRec.Approve_Reject_Date__c == null && approverRec.Submitted_Date__c != null) {
                    Date submittedDate = Date.valueOf(approverRec.Submitted_Date__c);
                    NoOfSLADays = submittedDate.daysBetween(system.today());
                    NoOfSLADays = getSLAInHours(DateTime.now(), approverRec.Submitted_Date__c);
                    if(NoOfSLADays > 0) {
                        objSLARec.noofDays = NoOfSLADays;
                    } else {
                        objSLARec.noofDays = 0;
                    }
                }
            }
            if(mapOfStepToApprover.containsKey(String.valueOf(approverRec.Step_Order__c)+String.valueOf(approverRec.Submitted_Order__c))) {
                mapOfStepToApprover.get(String.valueOf(approverRec.Step_Order__c)+String.valueOf(approverRec.Submitted_Order__c)).add(approverRec);
            } else {
                mapOfStepToApprover.put(String.valueOf(approverRec.Step_Order__c)+String.valueOf(approverRec.Submitted_Order__c),new List<DQ_Deal_Qualification_Approver__c>{approverRec});
            }

            if(mapOfStepToSLAWrap.containsKey(String.valueOf(approverRec.Step_Order__c)+String.valueOf(approverRec.Submitted_Order__c))) {
                objSLARec.approverRec = approverRec;
                mapOfStepToSLAWrap.get(String.valueOf(approverRec.Step_Order__c)+String.valueOf(approverRec.Submitted_Order__c)).add(objSLARec);
            } else {
                objSLARec.approverRec = approverRec;
                mapOfStepToSLAWrap.put(String.valueOf(approverRec.Step_Order__c)+String.valueOf(approverRec.Submitted_Order__c),new List<DQSLAWrapper>{objSLARec});
            }
        }

        for(String stepNumber : mapOfStepToApprover.KeySet()) {
            ApprovalStatusWrapper objApproval = new ApprovalStatusWrapper();
            objApproval.stepNumber = String.valueof(mapOfStepToApprover.get(stepNumber)[0].Step_Order__c);
            objApproval.approverList = mapOfStepToApprover.get(stepNumber);
            objApproval.submittedDetails = mapOfStepToApprover.get(stepNumber)[0];
            objApproval.SLAWrapperList = mapOfStepToSLAWrap.get(stepNumber);
            listofApprovalStatusWrap.add(objApproval);
        }
        return listofApprovalStatusWrap;
    }

    @AuraEnabled
    public static List<Product_Catalogue__c> getProducts(String prodCatagoryName , String ProdSubCatName) {
       String query = 'Select Id,Name,Product_Name__c,Sub_Category_Name__c,Category_Name__c From Product_Catalogue__c';
        if(prodCatagoryName != '' && ProdSubCatName != '') {
          query += ' where Sub_Category_Name__c =\''+ProdSubCatName+'\'' +'and'+' '+'Category_Name__c =\''+prodCatagoryName+'\'';
        } else if(prodCatagoryName != '') {
            query += ' where Category_Name__c =\''+prodCatagoryName+'\'';
        } else if(ProdSubCatName != '') {
            query += ' where Sub_Category_Name__c =\''+ProdSubCatName+'\'';
        }
        return Database.query(query);
    }

    @AuraEnabled
    public static void saveDealQualification(DQ_Deal_Qualification__c objDQ, List<DQ_Deal_Qualification_Discounts__c> DQDiscountList, Boolean isDQExist) {
        List<DQ_Deal_Qualification_Discounts__c> dqDiscountListToInsert = new List<DQ_Deal_Qualification_Discounts__c>();
        Id dqDiscountSalesRecordTypeId = Schema.SObjectType.DQ_Deal_Qualification_Discounts__c.getRecordTypeInfosByName().get('Sales Quote').getRecordTypeId();
        if(objDQ != null) {
            upsert objDQ;

            if(isDQExist && DQDiscountList.size() > 0) {
                for(DQ_Deal_Qualification_Discounts__c DQDiscount : DQDiscountList) {
                    if(String.isBlank(DQDiscount.Product_Category__c) &&
                       String.isBlank(DQDiscount.Product_Package__c)) {
                        continue;
                    }
                    if(DQDiscount.Deal_Qualification__c == null && DQDiscount.Id == null) {
                        DQDiscount.Deal_Qualification__c = objDQ.Id;
                        DQDiscount.RecordTypeId =dqDiscountSalesRecordTypeId ;
                    }
                    if(String.isBlank(DQDiscount.CPQ_Configured_Product__c))
                    {
                        List<Product_Package__c> prodPackage = [Select Id,Ext_Element_Id__c from Product_Package__c where Id = :DQDiscount.Product_Package__c];
                        if(prodPackage != null && prodPackage.size() > 0)
                        {
                            String productPackageId = prodPackage[0].Ext_Element_Id__c;
                            List<Product2> lstProducts = [Select Id from Product2 where ProductCode = :productPackageId];
                            if(lstProducts != null && lstProducts.size() > 0)
                            {
                                DQDiscount.CPQ_Configured_Product__c = lstProducts[0].Id;
                            }
                        }
                    }
                    dqDiscountListToInsert.add(DQDiscount);
                }
                upsert dqDiscountListToInsert;
            }
        }
    }

    @AuraEnabled
    public static void revisedDealQualification(DQ_Deal_Qualification__c objDQ) {

        if(objDQ != null) {
            List<DQ_Deal_Qualification_Approver__c> listOfDQApprover = getCurrentApproverRecordForDQ(objDQ.Id);
            for (DQ_Deal_Qualification_Approver__c eachRecord: listOfDQApprover) {
                eachRecord.Status__c = 'Cancelled';
                eachRecord.Comments__c = 'Deal Qualification revised.';
                eachRecord.Submitted_Date__c = Datetime.now();
            }
            update listOfDQApprover;

            objDQ.Status__c = 'Revision Pending';
            update objDQ;
        }
    }

    private static List<DQ_Deal_Qualification_Approver__c> getCurrentApproverRecordForDQ(Id dqId) {
        Integer submitOrder = getDealQualficationApproverSubmitOrder(dqId) - 1;
        return [SELECT Id, Status__c, Submitted_Date__c, Comments__c
            FROM DQ_Deal_Qualification_Approver__c
            WHERE Deal_Qualification__c = :dqId AND Submitted_Order__c = :submitOrder AND Status__c NOT IN ('Approved', 'Notification')];
    }

    @AuraEnabled
    public static void deleteDQDiscountRecord(DQ_Deal_Qualification_Discounts__c DQDiscoutRec) {
        delete DQDiscoutRec;
    }

     @AuraEnabled
    public static void submitForApprovalForDealQualification(Id dqId, Id oppId, DQ_Deal_Qualification__c dqRecord) {
         List<DQ_ApprovalEngine1.ApproverWrapper> approverList = DQ_ApprovalEngine1.getApproversForDQ(dqId);
        if (dqRecord != null) {
            update dqRecord;
        }

        List<DQ_Deal_Qualification_Approver__c> listOfDealQualificationRecord = new List<DQ_Deal_Qualification_Approver__c>();
        Integer submitOrder = getDealQualficationApproverSubmitOrder(dqId);
        if (!approverList.isEmpty()) {
            Integer stepOrderForPending = getSmallestStepOrderFromApprovalList(approverList);
            Integer highestOrderNumber = getHighestStepOrderFromApprovalList(approverList);
            System.debug('>> stepOrderForPending>>> ' + stepOrderForPending);
            for (DQ_ApprovalEngine1.ApproverWrapper eachRecord : approverList) {
                for (DQ_Approval_Step_Approver__c eachApproverRecord : eachRecord.listOfStepApprover) {
                    if (eachApproverRecord == null) {
                        continue;
                    }
                    DQ_Deal_Qualification_Approver__c dealQualificationRecord = new DQ_Deal_Qualification_Approver__c();
                    dealQualificationRecord.Deal_Qualification__c = dqId;
                    dealQualificationRecord.Approval_Step__c = eachRecord.approvalStepRecord.Id;
                    dealQualificationRecord.Approval_Step_Approver__c = eachApproverRecord.Id;
                    dealQualificationRecord.Approval_Reason__c = eachRecord.approvalReason;
                    dealQualificationRecord.Step_Order__c = eachRecord.approvalStepRecord.Step_Order__c;
                    dealQualificationRecord.Submitted_Order__c = submitOrder;
                    dealQualificationRecord.OwnerId = eachApproverRecord.OwnerId;
                    if(!dqRecord.IsDQCreatedFromCPQOpp__c)
                    {
                        if (eachRecord.approvalStepRecord.Step_Order__c == stepOrderForPending) {
                            if (eachApproverRecord.Approval_Type__c == 'Approval') {
                                dealQualificationRecord.Status__c = 'Pending';
                            } else {
                                dealQualificationRecord.Status__c = 'Notification';
                            }

                            dealQualificationRecord.Submitted_Date__c = DateTime.now();
                        }
                    }
                    else
                    {
                        if (eachRecord.approvalStepRecord.Step_Order__c == highestOrderNumber) {
                            if (eachApproverRecord.Approval_Type__c == 'Approval') {
                                dealQualificationRecord.Status__c = 'Pending';
                            } else {
                                dealQualificationRecord.Status__c = 'Notification';
                            }

                            dealQualificationRecord.Submitted_Date__c = DateTime.now();
                        }
                        else
                        {
                            dealQualificationRecord.Status__c = 'Notification';
                        }
                    }

                    listOfDealQualificationRecord.add(dealQualificationRecord);
                }
            }
            insert listOfDealQualificationRecord;
            if(listOfDealQualificationRecord.size() > 0) {
                updateDealQualificationStatus(dqId);
            }
        } else {
                updateDealQualificationStatus(dqId, 'Approved');

        }
    }

    public static Integer getSmallestStepOrderFromApprovalList(List<DQ_ApprovalEngine1.ApproverWrapper> approverList) {
        Integer smallestStepNumber = 999;
        for (DQ_ApprovalEngine1.ApproverWrapper eachRecord : approverList) {

            if (eachRecord.listOfStepApprover != null && !eachRecord.listOfStepApprover.isEmpty()) {
                System.debug('eachRecord.approvalStepRecord.Step_Order__c>>>>> ' + eachRecord.listOfStepApprover);
                if (eachRecord.listOfStepApprover.size() == 1 && eachRecord.listOfStepApprover.get(0) == null) {
                    continue;
                }
                if (smallestStepNumber > eachRecord.approvalStepRecord.Step_Order__c) {
                    smallestStepNumber = Integer.valueOf(eachRecord.approvalStepRecord.Step_Order__c);
                }
          }
        }
        return smallestStepNumber;
    }
    public static Integer getHighestStepOrderFromApprovalList(List<DQ_ApprovalEngine1.ApproverWrapper> approverList) {
        Integer highestStepNumber = 0;
        for (DQ_ApprovalEngine1.ApproverWrapper eachRecord : approverList) {

            if (eachRecord.listOfStepApprover != null && !eachRecord.listOfStepApprover.isEmpty()) {
                System.debug('eachRecord.approvalStepRecord.Step_Order__c>>>>> ' + eachRecord.listOfStepApprover);
                if (eachRecord.listOfStepApprover.size() == 1 && eachRecord.listOfStepApprover.get(0) == null) {
                    continue;
                }
                if (highestStepNumber < eachRecord.approvalStepRecord.Step_Order__c) {
                    highestStepNumber = Integer.valueOf(eachRecord.approvalStepRecord.Step_Order__c);
                }
          }
        }
        return highestStepNumber;
    }

    private static Integer getDealQualficationApproverSubmitOrder (Id dqId) {
        List<DQ_Deal_Qualification_Approver__c> listOfDealQualificationApprover = [SELECT Id, Submitted_Order__c
                                                                                   FROM DQ_Deal_Qualification_Approver__c
                                                                                   WHERE Deal_Qualification__c =:dqId
                                                                                   ORDER BY Submitted_Order__c DESC];
        if (!listOfDealQualificationApprover.isEmpty()) {
            return Integer.valueOf(listOfDealQualificationApprover.get(0).Submitted_Order__c) + 1;
        }

        return 1;

    }

    private static void updateDealQualificationStatus(Id dqId) {
        updateDealQualificationStatus(dqId, 'Pending Approval');
    }

    private static void updateDealQualificationStatus(Id dqId, String status) {
        DQ_Deal_Qualification__c dealQualificationRecord = [SELECT Id, Status__c,Opportunity__c,IsDQCreatedFromCPQOpp__c
                                                                FROM DQ_Deal_Qualification__c WHERE Id =: dqId];
        dealQualificationRecord.Status__c = status;
        update dealQualificationRecord;
    }

    public static Map<String, List<String>> getDependentMap(String objDetail, string contrfieldApiName,string depfieldApiName) {
        String controllingField = contrfieldApiName.toLowerCase();
        String dependentField = depfieldApiName.toLowerCase();

        Map<String,List<String>> objResults = new Map<String,List<String>>();
        Schema.sObjectType objType = ((SObject)Type.forName(objDetail).newInstance()).getSObjectType();
        if (objType==null){
            return objResults;
        }

        Map<String, Schema.SObjectField> objFieldMap = objType.getDescribe().fields.getMap();

        if (!objFieldMap.containsKey(controllingField) || !objFieldMap.containsKey(dependentField)){
            return objResults;
        }

        Schema.SObjectField theField = objFieldMap.get(dependentField);
        Schema.SObjectField ctrlField = objFieldMap.get(controllingField);

        List<Schema.PicklistEntry> contrEntries = ctrlField.getDescribe().getPicklistValues();
        List<PicklistEntryWrapper> depEntries = wrapPicklistEntries(theField.getDescribe().getPicklistValues());
        List<String> controllingValues = new List<String>();

        for (Schema.PicklistEntry ple : contrEntries) {
            String label = ple.getLabel();
            objResults.put(label, new List<String>());
            controllingValues.add(label);
        }

        for (PicklistEntryWrapper plew : depEntries) {
            String label = plew.label;
            String validForBits = base64ToBits(plew.validFor);
            for (Integer i = 0; i < validForBits.length(); i++) {
                String bit = validForBits.mid(i, 1);
                if (bit == '1') {
                    objResults.get(controllingValues.get(i)).add(label);
                }
            }
        }
        return objResults;
    }

    public static String decimalToBinary(Integer val) {
        String bits = '';
        while (val > 0) {
            Integer remainder = Math.mod(val, 2);
            val = Integer.valueOf(Math.floor(val / 2));
            bits = String.valueOf(remainder) + bits;
        }
        return bits;
    }

    public static String base64ToBits(String validFor) {
        if (String.isEmpty(validFor)) {
            return '';
        }

        String validForBits = '';

        for (Integer i = 0; i < validFor.length(); i++) {
            String thisChar = validFor.mid(i, 1);
            Integer val = base64Chars.indexOf(thisChar);
            String bits = decimalToBinary(val).leftPad(6, '0');
            validForBits += bits;
        }

        return validForBits;
    }

    private static final String base64Chars = '' +
        'ABCDEFGHIJKLMNOPQRSTUVWXYZ' +
        'abcdefghijklmnopqrstuvwxyz' +
        '0123456789+/';


    private static List<PicklistEntryWrapper> wrapPicklistEntries(List<Schema.PicklistEntry> PLEs) {
        return (List<PicklistEntryWrapper>)
            JSON.deserialize(JSON.serialize(PLEs), List<PicklistEntryWrapper>.class);
    }

    @AuraEnabled
    public static List<ApprovalStatusWrapper> saveApprovalDetails(String approvalRecordId, String reason, String status, String DQId) {
        DQ_Deal_Qualification_Approver__c objDQApprover = new DQ_Deal_Qualification_Approver__c(Id = approvalRecordId);
        objDQApprover.Comments__c = reason;
        objDQApprover.Status__c = status;
        objDQApprover.Approve_Reject_Date__c = Datetime.now();
        objDQApprover.Approved_By__c = UserInfo.getUserId();
        update objDQApprover;

        DQ_Deal_Qualification__c objDQRec =  [SELECT Id,Status__c FROM DQ_Deal_Qualification__c WHERE Id = :DQId];

        Map<String,List<DQ_Deal_Qualification_Approver__c>> mapOfStepToApprover = new Map<String,List<DQ_Deal_Qualification_Approver__c>>();
        Map<String,List<DQSLAWrapper>> mapOfStepToSLAWrap = new Map<String,List<DQSLAWrapper>>();
        List<ApprovalStatusWrapper> listofApprovalStatusWrap = new List<ApprovalStatusWrapper>();
        for(DQ_Deal_Qualification_Approver__c approverRec : DQ_DealQualificationUtil.getDQApproverList(DQId)) {
            Decimal NoOfSLADays = 0;
            DQSLAWrapper objSLARec = new DQSLAWrapper();
            if(approverRec.Status__c != 'Cancelled'){
                if(approverRec.Approve_Reject_Date__c != null && approverRec.Submitted_Date__c != null) {
                    Date responseDate = Date.valueOf(approverRec.Approve_Reject_Date__c);
                    Date submittedDate = Date.valueOf(approverRec.Submitted_Date__c);

                    NoOfSLADays = getSLAInHours(approverRec.Approve_Reject_Date__c, approverRec.Submitted_Date__c);
                    if(NoOfSLADays > 0) {
                        objSLARec.noofDays = NoOfSLADays;
                    } else {
                        objSLARec.noofDays = 0;
                    }
                } else if(approverRec.Approve_Reject_Date__c == null && approverRec.Submitted_Date__c != null) {
                    Date submittedDate = Date.valueOf(approverRec.Submitted_Date__c);
                    NoOfSLADays = getSLAInHours(DateTime.now(), approverRec.Submitted_Date__c);
                    if(NoOfSLADays > 0) {
                        objSLARec.noofDays = NoOfSLADays;
                    } else {
                        objSLARec.noofDays = 0;
                    }
                }
            }
            if(mapOfStepToApprover.containsKey(String.valueOf(approverRec.Step_Order__c)+String.valueOf(approverRec.Submitted_Order__c))) {
                mapOfStepToApprover.get(String.valueOf(approverRec.Step_Order__c)+String.valueOf(approverRec.Submitted_Order__c)).add(approverRec);
            } else {
                mapOfStepToApprover.put(String.valueOf(approverRec.Step_Order__c)+String.valueOf(approverRec.Submitted_Order__c),new List<DQ_Deal_Qualification_Approver__c>{approverRec});
            }

            if(mapOfStepToSLAWrap.containsKey(String.valueOf(approverRec.Step_Order__c)+String.valueOf(approverRec.Submitted_Order__c))) {
                objSLARec.approverRec = approverRec;
                mapOfStepToSLAWrap.get(String.valueOf(approverRec.Step_Order__c)+String.valueOf(approverRec.Submitted_Order__c)).add(objSLARec);
            } else {
                objSLARec.approverRec = approverRec;
                mapOfStepToSLAWrap.put(String.valueOf(approverRec.Step_Order__c)+String.valueOf(approverRec.Submitted_Order__c),new List<DQSLAWrapper>{objSLARec});
            }
        }

        for(String stepNumber : mapOfStepToApprover.KeySet()) {
            ApprovalStatusWrapper objApproval = new ApprovalStatusWrapper();
            objApproval.stepNumber = String.valueof(mapOfStepToApprover.get(stepNumber)[0].Step_Order__c);
          objApproval.approverList = mapOfStepToApprover.get(stepNumber);
            objApproval.submittedDetails = mapOfStepToApprover.get(stepNumber)[0];
            objApproval.SLAWrapperList = mapOfStepToSLAWrap.get(stepNumber);
            objApproval.isDQStatusApprovedORReject = false;
            if(objDQRec != null && objDQRec.Status__c != 'Pending Approval') {
                objApproval.isDQStatusApprovedORReject = true;
            }
            listofApprovalStatusWrap.add(objApproval);
        }

        return listofApprovalStatusWrap;
    }

    public static Decimal getSLAInHours (DateTime startDate, DateTime endDate) {
        if(startDate == null || endDate == null){
            return null;
        }
        Decimal startTimeLong = startDate.getTime();
        Decimal endTimeLong = endDate.getTime();
        Decimal milliseconds = startTimeLong - endTimeLong;
        Decimal seconds = milliseconds / 1000;
        Decimal minutes = seconds / 60;
        Decimal hours = minutes / 60;
        return hours.setScale(2, RoundingMode.HALF_UP);
    }

    @AuraEnabled
    public static Boolean checkApprovePermission(String approvalRecordId) {
        String currentUserId = UserInfo.getUserId();
        Set<String> userIdSet = new Set<String>();
        DQ_Deal_Qualification_Approver__c objDQApprover = [SELECT Id,OwnerId,Approval_Step_Approver__r.OwnerId, Comments__c, Approval_Reason__c, Name, Approval_Step_Approver__r.Owner.Name, Approval_Step_Approver__c,
                                      Approve_Reject_Date__c, CreatedDate, Approved_By__c, Status__c, Step_Order__c
                                                             FROM DQ_Deal_Qualification_Approver__c WHERE Id = :approvalRecordId];
        String ownerID = objDQApprover.OwnerId;
        //Super User..
        if(FeatureManagement.checkPermission('DQ_Super_User')) {
            return true;
        }
        // For manager handling
        if(ownerId == null) {
            ownerId = objDQApprover.OwnerId;
        }
        if(ownerID != null && ownerID.startsWith('005')) {
            User objUser = [SELECT Id,DelegatedApproverId  FROM User WHERE Id = :ownerID];
            if(ownerID == currentUserId || (objUser.DelegatedApproverId != null && objUser.DelegatedApproverId == currentUserId)) {
              return true;
            }
        } else if(ownerID != null && ownerID.startsWith('00G')) {
           List<GroupMember> memberRecord  =  [SELECT Group.Name, UserOrGroupId FROM GroupMember WHERE
                                                Group.Type = 'Queue'
                                                AND Group.Name = :objDQApprover.Approval_Step_Approver__r.Owner.Name];
            for(GroupMember objMember : memberRecord) {
                userIdSet.add(objMember.UserOrGroupId);
            }
            for(User objUser : [SELECT Id,DelegatedApproverId  FROM User WHERE Id IN :userIdSet]) {
                userIdSet.add(objUser.DelegatedApproverId);
            }
            if(!userIdSet.isEmpty() && userIdSet != null && userIdSet.contains(currentUserId)) {
                return true;
            }

            return false;
        }

        return false;
    }

    @auraEnabled
    public static ApproverDetailByOppWrapper getApproverByOppId(String oppId, String quoteId) {
        ApproverDetailByOppWrapper wrapper = new ApproverDetailByOppWrapper();
        wrapper.dqApprover = DQ_SubmitQuoteForApproval1.getApproverByOppId(oppId, quoteId, true);
        DQ_Deal_Qualification__c dqRecord = DQ_DealQualificationUtil.getDealQualification(oppId);
        if (dqRecord != null) {
            Integer defaultInitialTerm = 12;
            wrapper.dqId = dqRecord.Id;
            if((dqRecord.Quote__r.Initial_Term_months__c != null &&
            (dqRecord.Initial_Term__c != null && dqRecord.Quote__r.Initial_Term_months__c != null &&
            Integer.valueof(dqRecord.Initial_Term__c) != Integer.valueof(dqRecord.Quote__r.Initial_Term_months__c))
            || (dqRecord.Quote__r.Payment_Plan__c == 'Monthly' && dqRecord.Quote__r.Initial_Term_months__c == null
            && (dqRecord.Initial_Term__c != null && defaultInitialTerm != Integer.valueof(dqRecord.Initial_Term__c)))))
            {
              wrapper.isInitialTermMatch = false;
            }
            else {
                wrapper.isInitialTermMatch = true;
            }
        } else {
            wrapper.isInitialTermMatch = true;
        }
        return wrapper;
    }

    @AuraEnabled
    public static String checkIfDQApprovalAcceptorReject( String dqApprovalRecId) {
        if(dqApprovalRecId != null) {
            List<DQ_Deal_Qualification_Approver__c> DQDealQualificationApproveList = [SELECT Id,Status__c FROM DQ_Deal_Qualification_Approver__c where Id = :dqApprovalRecId
                                                                                      and (status__c = 'Approved' OR status__c = 'Rejected' OR status__c = 'Cancelled')];
            if(DQDealQualificationApproveList != null && DQDealQualificationApproveList.size() > 0) {
                return DQDealQualificationApproveList[0].status__c;
            }
        }
        return '';
    }

    public static string getPackageIdFromQuote(String quoteId) {
        try{
            if(quoteId != null && quoteId != '') {
                List<Quote> quoteList = [SELECT Id,Opportunity.Brand_Name__c,Package_Info__c FROM Quote WHERE Id = :quoteId];
                if(quoteList != null && quoteList.size() > 0 && quoteList[0].Package_Info__c != null) {
                    List<Quote_QuoteJSONParent> objWrappList = (List<Quote_QuoteJSONParent>)System.JSON.deserialize(quoteList[0].Package_Info__c, List<Quote_QuoteJSONParent>.class);
                    if(objWrappList != null ) {
                        //System.assert(false,objWrappList);
                        String elementId = objWrappList[0].id;
                        List<Product_package__c> packageList = [SELECT ID FROM Product_package__c
                                                                WHERE Brand_Name__c = :quoteList[0].Opportunity.Brand_Name__c and Element_Ids__c INCLUDES (:elementId)];
                        if(packageList != null && packageList.size() > 0) {
                            return packageList[0].Id;
                        }
                    }
                }
            }
        } catch(Exception e) {
            System.debug(e.getMessage());
        }
        return null;
    }

    @AuraEnabled
    public static DealQualAndDiscountHistory getDQDealApprovalHistory(String dQId) {
        DealQualAndDiscountHistory dqHistoryRecords = new DealQualAndDiscountHistory();
        List<DQ_Deal_Qualification_History__c> listOFDQHistory =
             [SELECT ID, Initial_Term__c, Overall_Discount__c, (SELECT Id, toLabel(Product_Category__c), Discount__c, Quantity__c, Product__r.Name,
                Product_Package__c,Product_Package__r.Name
                FROM DQ_Deal_Qualification_Discounts_History__r)
                FROM DQ_Deal_Qualification_History__c
                WHERE Deal_Qualification__c = :dQId AND Status__c = 'Approved'];

        if(!listOFDQHistory.isEmpty()) {
            dqHistoryRecords.dealQualificationHistory = listOFDQHistory.get(0);
            dqHistoryRecords.dealQualDiscountHistory = listOFDQHistory[0].DQ_Deal_Qualification_Discounts_History__r;
        }

        return dqHistoryRecords;
    }

    @AuraEnabled
    public static void updateApproverUserAssignment(String approverId, String userOrQueueIdParam) {
        if (String.isBlank(approverId) || String.isBlank(userOrQueueIdParam)) {
            throw new AuraHandledException('Approver Id or User/Queue Id can not be blank');
        }
        if (String.isNotBlank(approverId) && String.isNotBlank(userOrQueueIdParam)) {
            DQ_Deal_Qualification_Approver__c dqApproverObj = new DQ_Deal_Qualification_Approver__c(Id = approverId, OwnerId = userOrQueueIdParam);
            try {
                update dqApproverObj;
            } catch(Exception ex) {
                throw new AuraHandledException(ex.getMessage());
            }
        }

    }

    @AuraEnabled
    public static List<String> getPendingDealQualificationApproverDetailsByDQId (String dqId) {
        String pendingMessage = '{0} is pending for {1}';
        List<String> pendingApproverList = new List<String>();
        List<DQ_Deal_Qualification_Approver__c> listOfDQApprover = DQ_DealQualificationUtil.getDQApproverList(dqId);
        if(!listOfDQApprover.isEmpty()) {
            for (DQ_Deal_Qualification_Approver__c eachApprover : listOfDQApprover) {
                if (eachApprover.Status__c == 'Pending' && eachApprover.Approval_Step_Approver__r.Approval_Type__c != 'Notification') {
                    pendingApproverList.add(String.format(pendingMessage, new List<Object> {eachApprover.Approval_Step__r.Name, eachApprover.Owner.Name}));
                }
            }
        }
        if (pendingApproverList.isEmpty()) {
            pendingApproverList.add('No approval required!');
        }
       return pendingApproverList;
    }

    @AuraEnabled
    public static List<Attachment> getFiles(string recordId){
        List<Attachment> DocumentList = new List<Attachment>();
        DocumentList = [SELECT Id, ContentType, ParentId, Name FROM Attachment WHERE ParentId =: recordId];
        return DocumentList;
    }
    @AuraEnabled
    public static Id saveChunk(Id parentId, String fileName, String base64Data, String contentType, String fileId) {
        // check if fileId id ''(Always blank in first chunk), then call the saveTheFile method,
        //  which is save the check data and return the attachemnt Id after insert,
        //  next time (in else) we are call the appentTOFile() method
        //   for update the attachment with reamins chunks
        if (fileId == '') {
            fileId = saveTheFile(parentId, fileName, base64Data, contentType);
        } else {
            appendToFile(fileId, base64Data);
        }

        return Id.valueOf(fileId);
    }

    public static Id saveTheFile(Id parentId, String fileName, String base64Data, String contentType) {
        base64Data = EncodingUtil.urlDecode(base64Data, 'UTF-8');

        Attachment oAttachment = new Attachment();
        oAttachment.parentId = parentId;

        oAttachment.Body = EncodingUtil.base64Decode(base64Data);
        oAttachment.Name = fileName;
        oAttachment.ContentType = contentType;

        insert oAttachment;

        return oAttachment.Id;
    }

    private static void appendToFile(Id fileId, String base64Data) {
        base64Data = EncodingUtil.urlDecode(base64Data, 'UTF-8');

        Attachment a = [
            SELECT Id, Body
            FROM Attachment
            WHERE Id =: fileId
        ];

        String existingBody = EncodingUtil.base64Encode(a.Body);

        a.Body = EncodingUtil.base64Decode(existingBody + base64Data);

        update a;
    }


    public class PicklistEntryWrapper{
        public String active {get;set;}
        public String defaultValue {get;set;}
        public String label {get;set;}
        public String value {get;set;}
        public String validFor {get;set;}
        public PicklistEntryWrapper(){
        }

    }

    public class ApprovalStatusWrapper {
        @AuraEnabled public String stepNumber {get;set;}
        @AuraEnabled public Boolean isDQStatusApprovedORReject {get;set;}
        @AuraEnabled public List<DQ_Deal_Qualification_Approver__c> approverList {get;set;}
        @AuraEnabled public DQ_Deal_Qualification_Approver__c submittedDetails {get;set;}
        @AuraEnabled public List<DQSLAWrapper> SLAWrapperList {get;set;}
        @AuraEnabled public Boolean showSubmittedDetail {get; set;}

        public ApprovalStatusWrapper () {
            this.showSubmittedDetail = false;
        }
    }
    public class DQSLAWrapper {
        @AuraEnabled public DQ_Deal_Qualification_Approver__c approverRec {get;set;}
        @AuraEnabled public Decimal noofDays {get;set;}
    }

    public class DealQualificationWrapper {
        @AuraEnabled public Boolean isEnableChangeApprover{get;set;}
        @AuraEnabled public Boolean isDQExist;
        @AuraEnabled public DQ_Deal_Qualification__c DQRec;
        @AuraEnabled public List<DQ_Deal_Qualification_Discounts__c> DQDiscountList;
        @AuraEnabled public List<DQ_Deal_Qualification_Discounts__c> DQDiscountSalesQuoteList;
        @AuraEnabled public List<DQ_Deal_Qualification_Discounts__c> DQDiscountContactCenterList;
        @AuraEnabled public Map<String,String> ProductCategoriesMap;
        @AuraEnabled public Map<String,String> ProductFamilyMap;
        @AuraEnabled public Map<String,String> ProductSubCategoriesMap;
        @AuraEnabled public Map<String,String> ProductCategoriesContactMap;
        @AuraEnabled public Map<String,String> ProductCategoriesSalesMap;
        @AuraEnabled public List<DQ_ApprovalEngine1.ApproverWrapper> approverList;
        @AuraEnabled public Integer highestStepNumber;
        @AuraEnabled public Map<String,String> RegionPicklistValueMap;
        @AuraEnabled public Map<String,String> SegmentPicklistValueMap;
        @AuraEnabled public Map<String,String> dealTypePicklistValueMap;
        @AuraEnabled public Map<String,String> brandPicklistValueMap;
        @AuraEnabled public Map<String,String> specialTermsPicklistValueMap;
        @AuraEnabled public Map<String,String> freeShippingTermsPicklistValueMap;
        @AuraEnabled public Map<String, List<String>> dependentPicklist;
        @AuraEnabled public List<Partner_Quote__c> quoteList;
        @AuraEnabled public List<ApprovalStatusWrapper> ApproverDetailList;
        @AuraEnabled public Map<String,String> mapOfPackageNameToId;
    }

    public class DealQualAndDiscountHistory {
        @AuraEnabled public DQ_Deal_Qualification_History__c dealQualificationHistory {get; set;}
        @AuraEnabled public List<DQ_Deal_Qualification_Discount_History__c> dealQualDiscountHistory {get; set;}
    }

    public class ApproverDetailByOppWrapper {
        @AuraEnabled public String dqId {get; set;}
        @AuraEnabled public List<DQ_ApprovalEngine1.ApproverWrapper> dqApprover {get; set;}
        @AuraEnabled public Boolean isInitialTermMatch {get; set;}
    }
}