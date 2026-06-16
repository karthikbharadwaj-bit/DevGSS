public class DQApprovalTestDataFactory {
    private static Id newSalesRecordTypeId =  Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('New Sales Opportunity').getRecordTypeId();

    public static List<DQ_Approval_Step__c> generateDQApprovalStep(Integer noOfRecords) {
        List<DQ_Approval_Step__c> DQApporvalStepList = new List<DQ_Approval_Step__c>();
        for(Integer i=0;i < noOfRecords; i++) {
            DQ_Approval_Step__c objApproval = new DQ_Approval_Step__c();
            objApproval.Name = 'Level '+ i;
            objApproval.Step_Order__c = i;
            objApproval.Deal_Size__c = 12;
            objApproval.Overall_Discount__c = 20;
            DQApporvalStepList.add(objApproval);
        }
        return DQApporvalStepList;
    }

    public static List<DQ_Approval_Type__c> generateDQApprovalType(
        Integer noOfRecords,Boolean IsActive,String ProductCatagory,String approvalType, Integer threshold ) {
            List<DQ_Approval_Type__c> DQApporvalTypeList = new List<DQ_Approval_Type__c>();
            for(Integer i=0;i < noOfRecords; i++) {
                DQ_Approval_Type__c objApprovalType = new DQ_Approval_Type__c();
                objApprovalType.Product_Category__c = ProductCatagory;
                objApprovalType.Approval_Type__c = approvalType;
                objApprovalType.Threshold__c = threshold;
                objApprovalType.IsActive__c = IsActive;
                DQApporvalTypeList.add(objApprovalType);
            }
        return DQApporvalTypeList;
    }


    public static List<DQ_Approval_Type_Step__c> generateDQApprovalTypeAndStep(
        Integer noOfRecords,String approvalTypeId,String approvalStepId,
        String brand, Integer quantiythreshold,String dealType,String region,
        String segment,Integer discountThreshold ) {
            List<DQ_Approval_Type_Step__c> DQApporvalTypeANDStepList = new List<DQ_Approval_Type_Step__c>();
            for(Integer i=0;i < noOfRecords; i++) {
                DQ_Approval_Type_Step__c objApprovalTypeAndStep = new DQ_Approval_Type_Step__c();
                objApprovalTypeAndStep.Brand__c = brand;
                objApprovalTypeAndStep.Deal_Type__c = dealType;
                objApprovalTypeAndStep.Discount_Threshold__c = discountThreshold;
                objApprovalTypeAndStep.DQ_Approval_Step__c = approvalStepId;
                objApprovalTypeAndStep.DQ_Approval_Type__c = approvalTypeId;
                objApprovalTypeAndStep.Quantity_Threshold__c = quantiythreshold;
                objApprovalTypeAndStep.Region__c = region;
                objApprovalTypeAndStep.Segment__c = segment;
                DQApporvalTypeANDStepList.add(objApprovalTypeAndStep);
            }
        return DQApporvalTypeANDStepList;
    }

    public static List<DQ_Approval_Step_Approver__c> generateDQApprovalStepApprover(
        Integer noOfRecords,String approvalStepId, String brand, String approvalType,String dealType, String region,String segment) {
            List<DQ_Approval_Step_Approver__c> DQApporvalStepApproverList = new List<DQ_Approval_Step_Approver__c>();
            for(Integer i=0;i < noOfRecords; i++) {
                DQ_Approval_Step_Approver__c objApprovalStepApprover = new DQ_Approval_Step_Approver__c();
                objApprovalStepApprover.Approval_Type__c = approvalType;
                objApprovalStepApprover.Brand__c = brand;
                objApprovalStepApprover.Deal_Type__c = dealType;
                objApprovalStepApprover.DQ_Approval_Step__c = approvalStepId;
                objApprovalStepApprover.Region__c = region;
                objApprovalStepApprover.Segment__c = segment;
                DQApporvalStepApproverList.add(objApprovalStepApprover);
            }
        return DQApporvalStepApproverList;
    }

    public static List<DQ_Deal_Qualification__c> generateDQ(
        Integer noOfRecords,String brand, String dealType, String region,String segment, String oppId) {
            List<DQ_Deal_Qualification__c> DQListToInsert = new List<DQ_Deal_Qualification__c>();
            for(Integer i=0;i < noOfRecords; i++) {
                DQ_Deal_Qualification__c objDQ = new DQ_Deal_Qualification__c();
                objDQ.Opportunity__c = oppId;
                objDQ.Charge_Term__c = 'Monthly';
                objDQ.Initial_Term__c = '12';
                objDQ.Renewal_Term__c = '12';
                objDQ.Type__c = 'Original';
                objDQ.Status__c = 'Pending Approval';
                objDQ.Minimum_Package_s__c = 'Standard';
                objDQ.Number_of_DLs__c =  25;
                // objDQ.Max_Discount__c = 15;
                objDQ.Justification_Description__c = 'TEst';
                objDQ.Deal_Size__c = 45;
                objDQ.Overall_Discount__c = 25;
                objDQ.Special_Terms__c = '5 Free Months of Service';
                objDQ.Is_ELA__c = 'Yes';
                objDQ.Minimum_Baseline__c = 2000;
                objDQ.Maximum_Potential__c = 3000;
                objDQ.ELA_Initial_Terms__c = '36';
                objDQ.Start_Date__c = Date.today();
                objDQ.Roll_Out_Plan__c = null;
                objDQ.Additional_Info__c = 'TEST';
                objDQ.Global_Office_Location__c = null;
                objDQ.Cost_of_One_Time_items__c = 12.5;
                objDQ.New_Annual_Recurring_Charges__c = 150;
                objDQ.True_Up_Terms__c = null;
                DQListToInsert.add(objDQ);
            }
        return DQListToInsert;
    }


    public static List<DQ_Deal_Qualification_History__c> generateDQHistory(
        Integer noOfRecords,String brand, String dealType, String region,String segment, String dqId) {
            List<DQ_Deal_Qualification_History__c> DQListToInsert = new List<DQ_Deal_Qualification_History__c>();
            for(Integer i=0;i < noOfRecords; i++) {
                DQ_Deal_Qualification_History__c objDQ = new DQ_Deal_Qualification_History__c();
                objDQ.Deal_Size__c  = 2;
                objDQ.Brand__c  = brand;
                objDQ.Deal_Type__c  = dealType;
                objDQ.Initial_Term__c  = '36';
                objDQ.Minimum_Package_s__c  = null;
                objDQ.Number_of_DLs__c  = null;
                objDQ.Overall_Discount__c  = 20;
                objDQ.Region__c  = region;
                objDQ.Renewal_Term__c  = '12';
                objDQ.Segment__c  = segment;
                objDQ.Deal_Qualification__c  = dqId;
                objDQ.Special_Terms__c  = null;
                objDQ.Is_ELA__c  = 'Yes';
                objDQ.Sub_Region__c  = 'Central';
                objDQ.ELA_Initial_Terms__c  = '36';
                objDQ.Maximum_Potential__c  = 4000;
                objDQ.Roll_Out_Plan__c  = null;
                objDQ.Start_Date__c  = Date.Today();
                objDQ.True_Up_Terms__c  = null;
                objDQ.Additional_Info__c  = 'test';
                objDQ.Status__c = 'Approved';
                DQListToInsert.add(objDQ);
            }
        return DQListToInsert;
    }

    public static List<DQ_Deal_Qualification_Discounts__c> generateDQDiscount(
        Integer noOfRecords,String dqId,integer discount, String prodCat, String productId, Integer quantity, Boolean withPackage) {
            List<DQ_Deal_Qualification_Discounts__c> DQDiscountListToInsert = new List<DQ_Deal_Qualification_Discounts__c>();
            Id RecordTypeIdDQDiscountQuote = Schema.SObjectType.DQ_Deal_Qualification_Discounts__c.getRecordTypeInfosByName().get('Sales Quote').getRecordTypeId();
            for(Integer i=0;i < noOfRecords; i++) {
                DQ_Deal_Qualification_Discounts__c objDQ = new DQ_Deal_Qualification_Discounts__c();
                objDQ.Deal_Qualification__c = dqId;
                objDQ.Discount__c = discount;
				objDQ.RecordTypeId = RecordTypeIdDQDiscountQuote;
                // objDQ.Product_Family__c = productFamily;
                objDQ.Product_Category__c = prodCat;
                objDQ.Product__c = productId;
                //objDQ.Product_Sub_Categories__c = prodSubCat;
                objDQ.Quantity__c = quantity;
                if(withPackage){
                    objDQ.PackageName__c = 'Test package';
                    objDQ.OriginalPackageId__c = '0001';
                    objDQ.OriginalPackageVersion__c = 'v1';
                }
                DQDiscountListToInsert.add(objDQ);
            }
        return DQDiscountListToInsert;
    }

    public static List<DQ_Deal_Qualification_Discount_History__c> generateDQDiscountHistory(
        Integer noOfRecords,String dqId,integer discount, String prodCat, String productId, Integer quantity) {
            List<DQ_Deal_Qualification_Discount_History__c> DQDiscountListToInsert = new List<DQ_Deal_Qualification_Discount_History__c>();
            for(Integer i=0; i < noOfRecords; i++) {
                DQ_Deal_Qualification_Discount_History__c objDQ = new DQ_Deal_Qualification_Discount_History__c();
                objDQ.DQ_Deal_Qualification_History__c = dqId;
                objDQ.Discount__c = discount;
                // objDQ.Product_Family__c = productFamily;
                objDQ.Product_Category__c = prodCat;
                objDQ.Product__c = productId;
                //objDQ.Product_Sub_Categories__c = prodSubCat;
                objDQ.Quantity__c = quantity;
                DQDiscountListToInsert.add(objDQ);
            }
        return DQDiscountListToInsert;
    }

    public static List<DQ_Deal_Qualification__c> generateDealQualificationWithConfig () {
        Triggers.switchOff();
        List<User> listOfUser = [SELECT Id FROM User WHERE Profile.Name LIKE '%Administrator%' AND Id != :UserInfo.getUserId() LIMIT 3 ];
        User userRec = new User(Id = UserInfo.getUserId());
        userRec.SegmentPicklist__c = 'SOHO';
        userRec.Region__c = 'EU';
        userRec.Sub_Region__c = 'Central';
        userRec.ManagerId = listOfUser.get(0).Id;
        update userRec;
        Triggers.switchOn();

        Segment_Master__c sg = new Segment_Master__c();
        sg.Name = 'SOHO';
        sg.Country__c = 'United States';
        sg.Max__c = 1;
        sg.Min__c = 10000;
        sg.Start_Date__c = Date.today();
        sg.CurrencyIsoCode = 'USD';
        insert sg;

        Account ObjAcc = new Account();
        ObjAcc.Name = 'Test 1';
        ObjAcc.OwnerId = userRec.Id;
        ObjAcc.Segment_Name__c = sg.Id;
        insert ObjAcc;

        // insert Opp
        Opportunity objOpp = new Opportunity();
        objOpp.Name = 'Test 1';
        objOpp.StageName = '7. Closed Won';
        objOpp.AccountId = objAcc.Id;
        objOpp.RecordTypeId = newSalesRecordTypeId;
        objOpp.Brand_Name__c =  'Avaya Cloud Office';
        objOpp.CloseDate = System.today();
        insert objOpp;


        // generate step..
        List<DQ_Approval_Step__c> objDQApprovalStepList = DQApprovalTestDataFactory.generateDQApprovalStep(2);
        objDQApprovalStepList[0].Name = 'Level 1';
        objDQApprovalStepList.get(1).Name = 'Level 2';
		objDQApprovalStepList.get(1).Overall_Discount__c = null;
        objDQApprovalStepList.get(1).Deal_Size__c = null;

        insert objDQApprovalStepList;

        //Generate generateDQApprovalType
        //Integer noOfRecords,Boolean IsActive,String ProductCatagory,String approvalType, Integer threshold
        List<DQ_Approval_Type__c> objDQApprovalTypeList = DQApprovalTestDataFactory.generateDQApprovalType(8,true,'GOA_Devices','Discount',40);
        objDQApprovalTypeList[0].isActive__c = true;
        objDQApprovalTypeList[0].Initial_Term_To_Discount__c = null;
        objDQApprovalTypeList[0].Initial_Term_Discount__c = null;

        objDQApprovalTypeList[1].isActive__c = true;
        objDQApprovalTypeList[1].Initial_Term_To_Discount__c = 0.1;
        objDQApprovalTypeList[1].Initial_Term_Discount__c = 9999;
        objDQApprovalTypeList[1].Approval_Type__c = 'Special Term';
        objDQApprovalTypeList[1].Special_Terms__c = '1 Free Month of Service; 2 Free Months of Service;3 Free Months of Service;4 Free Months of Service;5 Free Months of Service;';

        objDQApprovalTypeList[2].isActive__c = true;
        objDQApprovalTypeList[2].Initial_Term_To_Discount__c = 0.1;
        objDQApprovalTypeList[2].Initial_Term_Discount__c = 9999;
        objDQApprovalTypeList[2].Approval_Type__c = 'Total Discount';
        objDQApprovalTypeList[2].Threshold__c = 2;

        objDQApprovalTypeList[3].isActive__c = true;
        objDQApprovalTypeList[3].Initial_Term_To_Discount__c = 0.1;
        objDQApprovalTypeList[3].Initial_Term_Discount__c = 9999;
        objDQApprovalTypeList[3].Approval_Type__c = 'ELA Standard';

        objDQApprovalTypeList[4].isActive__c = true;
        objDQApprovalTypeList[4].Initial_Term_To_Discount__c = 0.1;
        objDQApprovalTypeList[4].Initial_Term_Discount__c = 9999;
        objDQApprovalTypeList[4].Approval_Type__c = 'ELA Non-Standard';

        objDQApprovalTypeList[5].isActive__c = true;
        objDQApprovalTypeList[5].Initial_Term_To_Discount__c = 0.1;
        objDQApprovalTypeList[5].Initial_Term_Discount__c = 9999;
        objDQApprovalTypeList[5].Approval_Type__c = 'Renewal Term';
         objDQApprovalTypeList[5].Threshold__c = 12;

        objDQApprovalTypeList[6].isActive__c = true;
        objDQApprovalTypeList[6].Initial_Term_To_Discount__c = 0.1;
        objDQApprovalTypeList[6].Initial_Term_Discount__c = 9999;
        objDQApprovalTypeList[6].Approval_Type__c = 'Initial Term';
         objDQApprovalTypeList[6].Threshold__c = 12;

        objDQApprovalTypeList[7].isActive__c = true;
        objDQApprovalTypeList[7].Initial_Term_To_Discount__c = null;
        objDQApprovalTypeList[7].Initial_Term_Discount__c = null;
        objDQApprovalTypeList[7].Approval_Type__c = 'Special Term';
        objDQApprovalTypeList[7].Special_Terms__c = '1 Free Month of Service; 2 Free Months of Service;3 Free Months of Service;4 Free Months of Service;5 Free Months of Service;';

        List<DQ_Approval_Type__c> objDQApprovalTypeEESList = DQApprovalTestDataFactory.generateDQApprovalType(2,true,'EES','Product Removal',null);

        objDQApprovalTypeEESList[1].Product_Category__c = 'EES-CC';

        objDQApprovalTypeList.addAll(objDQApprovalTypeEESList);
        insert objDQApprovalTypeList;

        //generateDQApprovalTypeAndStep
        //Integer noOfRecords,String approvalTypeId,String approvalStepId,String brand, Integer quantiythreshold,
        //String dealType,String region,String segment,Integer discountThreshold
        List<DQ_Approval_Type_Step__c> objApprovalTypeStepList = DQApprovalTestDataFactory.generateDQApprovalTypeAndStep(
            7, objDQApprovalTypeList[0].Id,objDQApprovalStepList[0].Id,'Avaya Cloud Office', 40,'Direct','EU','SOHO',40);

        objApprovalTypeStepList.get(0).Sub_Region__c = 'Central';

        objApprovalTypeStepList.get(1).Sub_Region__c = 'Central';
        objApprovalTypeStepList.get(1).DQ_Approval_Type__c = objDQApprovalTypeList.get(1).Id;


		objApprovalTypeStepList.get(2).Sub_Region__c = 'Central';
        objApprovalTypeStepList.get(2).DQ_Approval_Type__c = objDQApprovalTypeList.get(2).Id;

        objApprovalTypeStepList.get(3).Sub_Region__c = 'Central';
        objApprovalTypeStepList.get(3).DQ_Approval_Type__c = objDQApprovalTypeList.get(3).Id;


        objApprovalTypeStepList.get(4).Sub_Region__c = 'Central';
        objApprovalTypeStepList.get(4).DQ_Approval_Type__c = objDQApprovalTypeList.get(4).Id;

        objApprovalTypeStepList.get(5).Sub_Region__c = 'Central';
        objApprovalTypeStepList.get(5).DQ_Approval_Type__c = objDQApprovalTypeEESList.get(0).Id;

        objApprovalTypeStepList.get(6).Sub_Region__c = 'Central';
        objApprovalTypeStepList.get(6).DQ_Approval_Type__c = objDQApprovalTypeEESList.get(1).Id;

        insert objApprovalTypeStepList;

        //List<DQ_Approval_Step_Approver__c> generateDQApprovalStepApprover
        //Integer noOfRecords,String approvalStepId,String brand, String approvalType,String dealType,String region,String segment
        List<DQ_Approval_Step_Approver__c> objDQApprovalStepApproverList = DQApprovalTestDataFactory.generateDQApprovalStepApprover(
            1, objDQApprovalStepList[0].Id,'Avaya Cloud Office','Approval','Direct','EU','SOHO');

        objDQApprovalStepApproverList.get(0).Sub_Region__c = 'Central';
        insert objDQApprovalStepApproverList;

        List<DQ_Deal_Qualification__c> objDQ = DQApprovalTestDataFactory.generateDQ(1,'Avaya Cloud Office','Direct','EU','Small Business',objOpp.Id);
        insert objDQ;

        Quote testQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Quote.OpportunityId => objOpp.Id,
                Quote.Name => ValueProviderBuilder.provideUniqueString('test quote'),
                Quote.Payment_Plan__c => 'Monthly',
                Quote.Term_months__c => '12',
                Quote.Initial_Term_months__c => '12',
                Quote.Special_Terms__c => '6 Free Months of Service',
                Quote.Total_First_Year_Cost__c => 720,
                Quote.Monthly_Recurring_Revenue__c => 47,
                Quote.Shipping_Option__c => 'Overnight',
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.Package_Info__c => NGBSTestDataGenerator.generateQuotePackageInfo(),
                Quote.Pricebook2Id => Test.getStandardPricebookId()
            })
            .create()
            .getRecord();

        String testElementId1 = 'LC_EES_486';
        String testElementId2 = 'productElementId_2';

        List<Product2> testProductList = (List<Product2>) new SObjectBuilder(Product2.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Product2.Name => ValueProviderBuilder.provideList(new List<String> {'Test Product 1', 'Test Product 2'}),
                    Product2.IsActive => true,
                    Product2.ExtID__c => ValueProviderBuilder.provideList(new List<String> {testElementId1, testElementId2})
                }
            )
            .quantity(2)
            .create()
            .getRecords();

        List<PriceBookEntry> priceEntryList = (List<PriceBookEntry>) new SObjectBuilder(PriceBookEntry.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    PriceBookEntry.Product2Id => ValueProviderBuilder.provideList(new List<Id> {testProductList[0].Id, testProductList[1].Id}),
                    PriceBookEntry.UnitPrice => 10000,
                    PriceBookEntry.IsActive => true,
                    PriceBookEntry.UseStandardPrice => false,
                    PriceBookEntry.Pricebook2Id => Test.getStandardPricebookId()
                }
            )
            .quantity(2)
            .create()
            .getRecords();

        Triggers.switchOff();
        List<QuoteLineItem> quoteLineItemList = (List<QuoteLineItem>) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    QuoteLineItem.ServiceDate => date.today(),
                    QuoteLineItem.Description => 'TestLineItem',
                    QuoteLineItem.UnitPrice => ValueProviderBuilder.provideList(new List<Decimal> {priceEntryList[0].UnitPrice, priceEntryList[1].UnitPrice}),
                    QuoteLineItem.Quantity => 5,
                    QuoteLineItem.QuoteId => testQuote.Id,
                    QuoteLineItem.PriceBookEntryId => ValueProviderBuilder.provideList(new List<Id> {priceEntryList[0].Id, priceEntryList[1].Id}),
                    QuoteLineItem.Product2Id => ValueProviderBuilder.provideList(new List<Id> {testProductList[0].Id, testProductList[1].Id}),
                    QuoteLineItem.Discount_type__c => QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY,
                    QuoteLineItem.Discount_number__c => 0,
                    QuoteLineItem.NewQuantity__c => 5
                }
            )
            .quantity(2)
            .create()
            .getRecords();
        Triggers.switchOn();

        List<DQ_Deal_Qualification_Discounts__c> objDiscount = DQApprovalTestDataFactory.generateDQDiscount(1, objDQ[0].Id, 70, 'GOA_Devices', testProductList[0].Id, 80, false);
        insert objDiscount;

        List<DQ_Deal_Qualification_Discounts__c> objDiscountWithPackage = DQApprovalTestDataFactory.generateDQDiscount(1, objDQ[0].Id, 70, 'GOA_Devices', testProductList[0].Id, 80, true);
        insert objDiscountWithPackage;

        List<DQ_Deal_Qualification_History__c> objDQH = DQApprovalTestDataFactory.generateDQHistory(2,'Avaya Cloud Office','Direct','EU','Small Business',objDQ[0].Id);
        objDQH.get(1).Status__c = 'Pending Approval';
        objDQH.get(0).Initial_Term__c = '12';
        objDQH.get(1).Initial_Term__c = '12';
        insert objDQH;

        List<DQ_Deal_Qualification_Discount_History__c> objDiscountH = DQApprovalTestDataFactory.generateDQDiscountHistory(2, objDQH[0].Id, 20, 'GOA_Devices', testProductList[0].Id, 80);
        objDiscountH.get(1).Discount__c = 70;
        objDiscountH.get(1).Quantity__c = 80;
        objDiscountH.get(1).DQ_Deal_Qualification_History__c = objDQH.get(1).Id;
        insert objDiscountH;

        return objDQ;
    }

}