@isTest
private class Test_OveragesQLIHelper {
    @TestSetup
    private static void prepareData(){
        Account newBusinessAcc = (Account) new SObjectBuilder(Account.sObjectType)
            .setField(Account.Name, 'New Business Account')
            .create()
            .getRecord();

        Account existingBusinessAcc = (Account) new SObjectBuilder(Account.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => 'Existing Business Account',
                Account.RC_User_ID__c => ValueProviderBuilder.provideUniqueString()
            })
            .create()
            .getRecord();

        Product2 seatBasic = (Product2) new SObjectBuilder(Product2.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Product2.Name => 'CC Basic Seat',
                Product2.Family => Product2Helper.FAMILY_CCSERVICE,
                Product2.IsActive => true,
                Product2.Charge_Term__c => Product2Helper.CHARGE_TERM_ANNUAL,
                Product2.Sub_Category__c => Product2Helper.SUBCATEGORY_CONTACT_CENTER,
                Product2.ExtID__c => 'null_CC Service: Basic Edition Seat - Annual Prepay_null_Annual_null_null_null_false',
                Product2.Edition__c => 'Basic',
                Product2.Product_Type__c => Product2Helper.PRODUCT_TYPE_SEAT
            })
            .create()
            .getRecord();

        List<Product2> products = (List<Product2>) new SObjectBuilder(Product2.sObjectType)
            .quantity(6)
            .setField(Product2.Name,
                ValueProviderBuilder.provideList(new List<String>{
                    'Seat Overage',
                    'Domestic Minutes Overage',
                    'Port Overage',
                    'CC Additional Port',
                    'CC 100K Minutes Bundle',
                    'Audio Recording Pro Overage'
                    }
                )
            )
            .setField(Product2.Family,
                ValueProviderBuilder.provideList(new List<String>{
                    Product2Helper.FAMILY_OVERAGE,
                    Product2Helper.FAMILY_OVERAGE,
                    Product2Helper.FAMILY_OVERAGE,
                    Product2Helper.FAMILY_ADDONS,
                    Product2Helper.FAMILY_MINUTES_BUNDLE,
                    Product2Helper.FAMILY_OVERAGE
                    }
                )
            )
            .setField(Product2.IsActive, true)
            .setField(Product2.Charge_Term__c,
                ValueProviderBuilder.provideList(new List<String>{
                    Product2Helper.CHARGE_TERM_MONTHLY_CONTRACT,
                    Product2Helper.CHARGE_TERM_MONTHLY_CONTRACT,
                    Product2Helper.CHARGE_TERM_MONTHLY_CONTRACT,
                    Product2Helper.CHARGE_TERM_ANNUAL,
                    Product2Helper.CHARGE_TERM_ANNUAL,
                    Product2Helper.CHARGE_TERM_MONTHLY_CONTRACT
                    }
                )
            )
            .setField(Product2.Sub_Category__c, 'Contact Center')
            .setField(Product2.ExtID__c,
                ValueProviderBuilder.provideList(new List<String>{
                    'Seat_CC Basic Edition Seat_null_Annual_null_null_null_false',
                    'Domestic_CC Basic Edition Seat_null_Annual_null_null_null_false',
                    'Port_CC Basic Edition Seat_null_Annual_null_null_null_false',
                    'null_CC Additional Port_null_Annual_null_null_null_false',
                    'null_CC 100K Minutes Bundle_null_Annual_null_null_null_false',
                    'Overage_Contact Center: Audio Recording Pro (per configured user)_null_Annual_null_null_null_false'
                    }
                )
            )
            .setField(Product2.Edition__c, '')
            .setField(Product2.Product_Type__c,
                ValueProviderBuilder.provideList(new List<String>{
                    Product2Helper.PRODUCT_TYPE_SEAT,
                    Product2Helper.PRODUCT_TYPE_TRANSPORT,
                    Product2Helper.PRODUCT_TYPE_PORT,
                    Product2Helper.PRODUCT_TYPE_PORT,
                    Product2Helper.PRODUCT_TYPE_TRANSPORT,
                    null
                    }
                )
            )
            .setField(Product2.Parent__c,
                ValueProviderBuilder.provideList(new List<Id>{
                    seatBasic.Id, seatBasic.Id, seatBasic.Id, null, null, null
                    }
                )
            )
            .create()
            .getRecords();

        products.add(seatBasic);

        new SObjectBuilder(PricebookEntry.sObjectType)
            .quantity(7)
            .setField(PricebookEntry.Pricebook2Id, Test.getStandardPricebookId())
            .setField(PricebookEntry.Product2Id, ValueProviderBuilder.provideParents(products))
            .setField(PricebookEntry.UnitPrice, ValueProviderBuilder.provideUniqueNumber(1))
            .setField(PricebookEntry.IsActive, true)
            .setField(PricebookEntry.UseStandardPrice, false)
            .create();
    }

    @isTest()
    private static void testAddingSeatOnNewBusiness() {
        Test.startTest();

            Account newBusinessAccount = (Account) new AccountSelector()
                .selectAccountDefault('RC_User_ID__c = NULL')
                .executeQuery()
                .get(0);

            Opportunity newBusinessOppty = (Opportunity) new SOBjectBuilder(Opportunity.sObjectType)
                .setFields(new Map<SObjectField, Object>{
                    Opportunity.AccountId => newBusinessAccount.Id,
                    Opportunity.Name => 'New Business Oppty',
                    Opportunity.Type => 'New Business',
                    Opportunity.CloseDate => ValueProviderBuilder.provideUniqueDate(),
                    Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY
                })
                .create()
                .getRecord();

            Map<Id,PricebookEntry> pricebookEntries = new Map<Id,PricebookEntry>(
                (List<PricebookEntry>) new PricebookEntrySelector()
                    .getContactCenterPBEs('Pricebook2Id = \'' + Test.getStandardPricebookId() + '\'')
                    .executeQuery()
            );

            PricebookEntry seatPBE;

            for (PricebookEntry pbe : pricebookEntries.values()) {
                if (Product2Helper.FAMILY_CCSERVICE.equalsIgnoreCase(pbe.Product2.Family)) {
                    seatPBE = pbe;
                }
            }

            Quote newBusinessQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
                .setFields(new Map<SObjectField, Object>{
                    Quote.Name => 'New Business Quote',
                    Quote.OpportunityId =>  newBusinessOppty.Id,
                    Quote.Start_Date__c =>  ValueProviderBuilder.provideUniqueDate(),
                    Quote.End_Date__c =>  ValueProviderBuilder.provideUniqueDate(),
                    Quote.IsPrimary__c =>  true,
                    Quote.QuoteType__c =>  QuoteHelper.QUOTE_TYPE_QUOTE,
                    Quote.PriceBook2Id =>  Test.getStandardPricebookId()
                })
                .create()
                .getRecord();

            QuoteLineItem seat = QuoteLineItemHelper.createFromPBE(seatPBE);
            seat.QuoteId = newBusinessQuote.Id;
            QuoteLineItemHelper.setQuantity(seat, 1);

            List<QuoteLineItem> overagesQlis = QuoteLineItemHelper.getOveragesOnInsert(
                new List<QuoteLineItem>{ seat },
                pricebookEntries,
                new List<Entitlement__c>{},
                new List<QuoteLineItem>{},
                new List<Quote>{ newBusinessQuote }
            );

        Test.stopTest();

        System.assertEquals(4, overagesQlis.size(), 'List size should be 4');
        System.assertEquals(1, getSeatOverages(overagesQlis)[0].Threshold__c, 'Threshold__c should be 0');
        System.assertEquals(0, getUSATransportOverages(overagesQlis)[0].Threshold__c, 'Threshold__c should be 0');
        System.assertEquals(0, getPortOverages(overagesQlis)[0].Threshold__c, 'Threshold__c should be 0');
    }

    private static List<QuoteLineItem> getUSATransportOverages(List<QuoteLineItem> overagesQlis) {
        List<QuoteLineItem> result = new List<QuoteLineItem>{};
        for (QuoteLineItem qli : overagesQlis) {
            if (QuoteLineItemHelper.isUSAorUKTransportType(qli.Product2.Product_Type__c)) {
                result.add(qli);
            }
        }
        return result;
    }
    private static List<QuoteLineItem> getSeatOverages(List<QuoteLineItem> overagesQlis) {
        List<QuoteLineItem> result = new List<QuoteLineItem>{};
        for (QuoteLineItem qli : overagesQlis) {
            if (Product2Helper.isSeatProduct(qli.Product2)) {
                result.add(qli);
            }
        }
        return result;
    }
    private static List<QuoteLineItem> getPortOverages(List<QuoteLineItem> overagesQlis) {
        List<QuoteLineItem> result = new List<QuoteLineItem>{};
        for (QuoteLineItem qli : overagesQlis) {
            if (Product2Helper.isPortProduct(qli.Product2)) {
                result.add(qli);
            }
        }
        return result;
    }
}