/**
 * This is helper class for QuoteLineItem standard object
 * Keep all static variables and helper methods related to it here
 *
 * It's might be better to keep here helper methods that do not do any SOQL
 * so they could be reused in triggers or controllers
 */
public class QuoteLineItemHelper {

    // Action names
    public static final String ACTION_DELETE = 'delete';
    public static final String ACTION_INSERT = 'insert';
    public static final String ACTION_UPDATE = 'update';
    public static final String ACTION_UPSERT = 'upsert';

    //Discount_type__c
    public final static String DISCOUNT_TYPE_CURRENCY = 'Currency';
    public final static String DISCOUNT_TYPE_PERCENTAGE = 'Percentage';

    //Sub_Category__c
    public static final String SUBCATEGORY_PROSERV = 'Professional Services';
    public static final String SUBCATEGORY_CC_PROSERV = 'CC Professional Services';
    public static final String SUBCATEGORY_EVENTS = 'Events';

    public static final String ITEM_TYPE_PROSERV = 'Proserv';
    //Package Info Properties
    public static final String CHARGE_TERM_PROP = 'Charge Term';
    //Product_Type__c
    public static final String PRODUCT_TYPE_AI = 'AI';

    /* Billing cycle duration */
    public static final String BILLING_CYCLE_DURATION_MONTHLY = '1';
    public static final String BILLING_CYCLE_DURATION_ANNUAL = '12';

    public static final Map<String, String> CC_CATEGORIES = new Map<String,String>{
        Product2Helper.SUBCATEGORY_CONTACT_CENTER => 'Contact Center',
        Product2Helper.SUBCATEGORY_RC_CONTACT_CENTER => 'RC Contact Center'
    };

    public static final String CATEGORY_DL = 'DL';


    public static List<String> currencyList = new List<String>{'USD', 'EUR', 'CAD', 'GBP', 'AUD', 'SGD', 'INR', 'CHF', 'TWD'};
    public static final String DUPLICATED_QLI_MESSAGE = 'There are duplicated items on the quote';

    public static final List<String> CC_LEGACY_PACKAGE_IDS = new List<String> {'880', '881'};

    //EES Licenses
    public static final String EES_BRONZE = 'LC_EES_486';
    public static final String EES_SILVER = 'LC_EES_487';
    public static final String EES_SILVER_PLUS = 'LC_EES_937';
    public static final String EES_GOLD = 'LC_EES_488';
    public static final String EES_GOLD_PLUS = 'LC_EES_938';
    public static final String EES_PLATINUM = 'LC_EES_489';

    public static final Set<String> EES_LICENSES = new Set<String> {
        EES_BRONZE,
        EES_SILVER,
        EES_SILVER_PLUS,
        EES_GOLD,
        EES_GOLD_PLUS,
        EES_PLATINUM
    };

    //CC EES Licenses
    public static final String CC_EES_BRONZE = 'LC_CCES_481';
    public static final String CC_EES_SILVER = 'LC_CCES_482';
    public static final String CC_EES_SILVER_PLUS = 'LC_CCES_935';
    public static final String CC_EES_GOLD = 'LC_CCES_483';
    public static final String CC_EES_GOLD_PLUS = 'LC_CCES_936';
    public static final String CC_EES_PLATINUM = 'LC_CCES_484';

    public static final Set<String> EES_CC_LICENSES = new Set<String> {
        CC_EES_BRONZE,
        CC_EES_SILVER,
        CC_EES_SILVER_PLUS,
        CC_EES_GOLD,
        CC_EES_GOLD_PLUS,
        CC_EES_PLATINUM
    };

    //RCCC EES Licenses
    public static final String RCCC_EES_BRONZE = 'CC_EXENTSUPP_484';
    public static final String RCCC_EES_SILVER = 'CC_EXENTSUPP_485';
    public static final String RCCC_EES_SILVER_PLUS = 'CC_EXENTSUPP_486';
    public static final String RCCC_EES_GOLD = 'CC_EXENTSUPP_487';
    public static final String RCCC_EES_GOLD_PLUS = 'CC_EXENTSUPP_488';
    public static final String RCCC_EES_PLATINUM = 'CC_EXENTSUPP_489';

    public static final Set<String> RCCC_EES_PRODUCT_CATALOG_ID = new Set<String> {
        RCCC_EES_BRONZE,
        RCCC_EES_SILVER,
        RCCC_EES_SILVER_PLUS,
        RCCC_EES_GOLD,
        RCCC_EES_GOLD_PLUS,
        RCCC_EES_PLATINUM
   };

    public static final Map<String, String> CATALOG_ID_TO_EES_SERVISE_LEVEL = new Map<String, String> {
        EES_BRONZE => 'Bronze',
        EES_SILVER => 'Silver',
        EES_SILVER_PLUS => 'Silver+',
        EES_GOLD => 'Gold',
        EES_GOLD_PLUS => 'Gold+',
        EES_PLATINUM => 'Platinum',
        CC_EES_BRONZE => 'Bronze',
        CC_EES_SILVER => 'Silver',
        CC_EES_SILVER_PLUS => 'Silver+',
        CC_EES_GOLD => 'Gold',
        CC_EES_GOLD_PLUS => 'Gold+',
        CC_EES_PLATINUM => 'Platinum',
        RCCC_EES_BRONZE => 'Bronze',
        RCCC_EES_SILVER => 'Silver',
        RCCC_EES_SILVER_PLUS => 'Silver+',
        RCCC_EES_GOLD => 'Gold',
        RCCC_EES_GOLD_PLUS => 'Gold+',
        RCCC_EES_PLATINUM => 'Platinum'
    };

    public static final String CHARGE_TERM_MONTHLY = 'Monthly';
    public static final String CHARGE_TERM_MONTHLY_CONTRACT = 'Monthly - Contract';
    public static final String CHARGE_TERM_ANNUAL = 'Annual';

    public static final Set<String> RECURRING_CHARGE_TERM_VALUES = new Set<String>{CHARGE_TERM_MONTHLY, CHARGE_TERM_MONTHLY_CONTRACT, CHARGE_TERM_ANNUAL};

    public static List<PdfHierarchySettings__mdt> hierarchySettings {
        get {
            if (hierarchySettings == null) {
                hierarchySettings = PdfHierarchySettings__mdt.getAll().values();
            }
            return hierarchySettings;
        }
        private set;
    }

    public static Set<String> mainLicenseIds {
        get {
            Set<String> result = new Set<String>();

            if (mainLicenseIds == null) {
                for (Package_Main_Licenses__c pmc : Package_Main_Licenses__c.getAll().values()) {
                    result.add(pmc.Main_License__c);
                }
            }
            return result;
        }
        private set;
    }

    /**
     * Set Quantity for Quote Line Item with regards of Zero Quantity flag
     */
    public static QuoteLineItem setQuantity(QuoteLineItem qli, Decimal quantity) {

        Boolean zeroQuantity = false;
        if (quantity == 0) {
            zeroQuantity = true;
            quantity = 1;
        }
        qli.Quantity = quantity;
        qli.Zero_Quantity__c = zeroQuantity;

        return qli;
    }

    /**
     * Get Quantity with regards of Zero Quantity flag
     */
    public static Decimal getQuantity(QuoteLineItem qli) {
        return qli.Zero_Quantity__c ? 0 : qli.Quantity;
    }

    /**
     * Returns List of Quote Line Items (Overages) that should be added or updated along with itemsToInsert
     *
     *
     * @param itemsToInsert         Quote Line Items that are being inserted in this transaction
     * @param priceBookEntries      List of PriceBookEntries. It should contains entries with Overages family
     *                              And should contain products for items that are going to be inserted
     *                              Product2.Add_Overages__c, Product2.Product_Type__c, Product2.Number_of_Minutes__c
     * @param entitlements          List of Entitlements for accounts
     * @param existingQlis          Existing QuoteLineItems on Quote
     * @param quoteList             AccountId, CurrencyIsoCode
     *
     * @return List of Quote Line Items (Overages) that should be added or updated along with itemsToInsert
     *
     * @see https://aquiva.atlassian.net/wiki/spaces/RC/pages/119504898/Overages Overages Documentation
     */
    public static List<QuoteLineItem> getOveragesOnInsert(
        List<QuoteLineItem> itemsToInsert,
        Map<Id, PricebookEntry> priceBookEntries,
        List<Entitlement__c> accEntitlements,
        List<QuoteLineItem> existingQlis,
        List<Quote> quoteList) {
        List<QuoteLineItem> qliToInsert = new List<QuoteLineItem>();
        List<PricebookEntry> overagesPBEs = new List<PricebookEntry>();

        Map<Id, Map<Id, Entitlement__c>> entlProdsByAccId = new Map<Id, Map<Id, Entitlement__c>>();
        Map<Id, Id> entlSeatIdByAccountId = new Map<Id, Id>();
        Entitlement__c seatEntitlement = new Entitlement__c();
        List<QuoteLineItem> existingOverages = new List<QuoteLineItem>();
        Map<String, QuoteLineItem> notEntlTransportQlis = new Map<String, QuoteLineItem>();
        Map<String, QuoteLineItem> entlTransportQlis = new Map<String, QuoteLineItem>();
        Map<Id, Id> alreadyHasSeat = new Map<Id, Id>();
        Map<Id, Set<Id>> existingProductIds = new Map<Id, Set<Id>>();
        Map<Id, Quote> quotesMapStatic = new Map<Id, Quote>();
        Map<Id, Product2> relatedProductsMap = new Map<Id, Product2>();

        List<Entitlement__c> entitlements = getContactCenterEntitlements(accEntitlements);

        List<String> euTransportSettings = getEuropeTransportTypes();

        RecordsMatcher.cacheResults = true;
        boolean accountOveragePremiumChargeToggle = Feature_Toggle__c.getInstance().AccountPremiumOverageCharge__c;

        // Prepare Quote Map
        for (Quote quote : quoteList) {
            if (!quotesMapStatic.containsKey(quote.Id)) {
                quotesMapStatic.put(quote.Id, quote);
            }
        }

        // Prepare Products Map
        for (PricebookEntry pbe : priceBookEntries.values()) {
            relatedProductsMap.put(pbe.Product2Id, pbe.Product2);
        }

        // Prepare overage PriceBook Entries
        for (PricebookEntry pbe : priceBookEntries.values()) {
            if (Product2Helper.FAMILY_OVERAGE.equalsIgnoreCase(pbe.Product2.Family)
                && pbe.Pricebook2.isStandard == false
                && pbe.Product2.isActive == true
                && pbe.isActive == true) {
                overagesPBEs.add(pbe);
            }
        }

        for (QuoteLineItem qli : existingQlis) {
            if (!existingProductIds.containsKey(qli.QuoteId)) {
                existingProductIds.put(qli.QuoteId, new Set<Id>());
            }
            existingProductIds.get(qli.QuoteId).add(qli.Product2Id);

            if (qli.Product2.Add_Overages__c
                && Product2Helper.isSeatProduct(qli.Product2)
                && qli.Entitlement__r.Id == null
                && qli.Deactivated__c == false) {
                alreadyHasSeat.put(qli.QuoteId, qli.Product2Id);
            }

            if (qli.Product2.Add_Overages__c && String.isNotBlank(qli.Product_Type__c)
                && isMinutesBundleProduct(qli.Product_Type__c, euTransportSettings)) {
                if (qli.Entitlement__r.Id == null) {
                    notEntlTransportQlis.put(qli.Product_Type__c, qli);
                } else {
                    entlTransportQlis.put(qli.Product_Type__c, qli);
                }
            }
            if (isOverage(qli)) {
                existingOverages.add(qli);
            }
        }

        for (Entitlement__c ent : entitlements) {
            if (!entlProdsByAccId.containsKey(ent.Account__c)) {
                entlProdsByAccId.put(ent.Account__c, new Map<Id, Entitlement__c>());
            }
            entlProdsByAccId.get(ent.Account__c).put(ent.Product__c, ent);
            //We need Seat Product because it's parent for all overages
            if (ent.Product__r.Family != Product2Helper.FAMILY_OVERAGE && Product2Helper.isSeatProduct(ent.Product__r)) {
                entlSeatIdByAccountId.put(ent.Account__c, ent.Product__c);
                seatEntitlement = ent;
            }
        }

        for (QuoteLineItem qli : itemsToInsert) {
            Product2 qliProduct2 = relatedProductsMap.get(qli.Product2Id);
            if (qliProduct2.Add_Overages__c) {
                Id accId = quotesMapStatic.get(qli.QuoteId).AccountId;
                boolean accountOveragePremiumCharge = quotesMapStatic.get(qli.QuoteId).Account.CCOveragePremiumDiscount__c;
                Id seatId = null;
                //Looking for Seat product Id.
                //Additional ports and minutes bundle cannot be added without seat
                //that is in the cart or entitlements
                if (Product2Helper.isSeatProduct(qliProduct2)) {
                    if (alreadyHasSeat.containsKey(qli.QuoteId)) {
                        AquivaHelper.throwAuraException('There can be only one active seat on Quote');
                    } else {
                        seatId = qli.Product2Id;
                    }
                } else {
                    if (alreadyHasSeat.containsKey(qli.QuoteId)) {
                        seatId = alreadyHasSeat.get(qli.QuoteId);
                    } else if (entlSeatIdByAccountId.containsKey(accId)) {
                        if(!CC_CATEGORIES.keySet().contains(qliProduct2.Sub_Category__c) || qliProduct2.Sub_Category__c == seatEntitlement.Product__r.Sub_Category__c) {
                            seatId = entlSeatIdByAccountId.get(accId);
                        } else {
                            AquivaHelper.throwAuraException(CC_CATEGORIES.get(qliProduct2.Sub_Category__c) + ' Seat should be added to Quote in order to add this product');
                        }
                    } else {
                        AquivaHelper.throwAuraException(CC_CATEGORIES.get(qliProduct2.Sub_Category__c) + ' Seat should be added to Quote in order to add this product');
                    }
                }

                Map<Id, Entitlement__c> pbeToEntitlementMatchedByProductId = new Map<Id, Entitlement__c>();
                List<Entitlement__c> entsNotMatchedByProductId = new List<Entitlement__c>();
                for (Entitlement__c ent : entitlements) {
                    Boolean matchedById = false;
                    for (PriceBookEntry pbe : overagesPBEs) {
                        if (pbe.Product2Id == ent.Product__c) {
                            pbeToEntitlementMatchedByProductId.put(pbe.Id, ent);
                            matchedById = true;
                        }
                    }
                    if (!matchedById) {
                        entsNotMatchedByProductId.add(ent);
                    }
                }

                Map<Id, List<PricebookEntry>> pbeToAddByQuote = new Map<Id, List<PricebookEntry>>();
                for (PricebookEntry pbe : overagesPBEs) {
                    if (priceBookEntries.get(qli.PricebookEntryId).Product2.Sub_Category__c != pbe.Product2.Sub_Category__c) {
                        continue;
                    }
                    Entitlement__c matchingEntitlement = pbeToEntitlementMatchedByProductId.get(pbe.Id);
                    Boolean isNotMatching = matchingEntitlement == null;

                    if (isNotMatching && Product2Helper.PRODUCT_TYPE_SEAT.equalsIgnoreCase(pbe.Product2.Product_Type__c)) {
                        List<Entitlement__c> matcherResult = (Entitlement__c[]) RecordsMatcher.match(entsNotMatchedByProductId, pbe.Product2, 'Matcher_Formula__c');
                        matchingEntitlement = (matcherResult.size() > 0 ? matcherResult[0] : null);

                        matcherResult = (Entitlement__c[]) RecordsMatcher.match(entsNotMatchedByProductId, pbe.Product2, 'Advanced_Matcher_Formula__c');
                        Entitlement__c advMatchingEntitlement = (matcherResult.size() > 0 ? matcherResult[0] : null);

                        isNotMatching = matchingEntitlement == null || advMatchingEntitlement == null;
                    }


                    String qliExtId = qliProduct2.ExtID__c.replaceFirst('null', 'Overage');
                    Boolean isParentEmpty = pbe.Product2.Parent__c == null;
                    Boolean isParentSeat = pbe.Product2.Parent__c == seatId;
                    Boolean isSameProductType = pbe.Product2.Product_Type__c != null && pbe.Product2.Product_Type__c == qliProduct2.Product_Type__c;
                    Boolean isSeat = Product2Helper.PRODUCT_TYPE_SEAT.equalsIgnoreCase(qliProduct2.Product_Type__c);
                    //Insert new item for Overage if Product type equals to QLI Product Type
                    //and it is a child for seat product beign inserted or the one from entitlements
                    //If there is no Seat product, we prohibit to insert line item
                    //Skip overage if it is in the cart already
                    if (quotesMapStatic.get(qli.QuoteId).Pricebook2Id == pbe.Pricebook2Id
                        &&
                        seatId != null
                        &&
                        (
                            (
                                isSameProductType &&
                                (
                                    isParentSeat ||
                                    // logic for EU overages, where Parent__c field is absent
                                    isEuropeTransportType(pbe.Product2.Product_Type__c, euTransportSettings)
                                )
                            )
                            ||
                            (
                                isSeat &&
                                (isParentEmpty || isParentSeat) &&
                                isNotMatching
                            )
                            ||
                            qliExtId == pbe.Product2.ExtID__c
                        )
                    ) {
                        //Add Overage QLI if it doesn't exist
                        if (existingProductIds.get(qli.QuoteId) == null
                            || !existingProductIds.get(qli.QuoteId).contains(pbe.Product2Id)) {
                            Decimal dsc = 0;
                            String dtype = DISCOUNT_TYPE_CURRENCY;
                            Decimal qty = 0;

                            //B-4627 Seat Overage logic on adding new Seat Product
                            // Seat Overage logic on adding new Seat Product
                            if (Product2Helper.isSeatProduct(pbe.Product2)) {
                                qty = qli.Quantity;
                                if (accountOveragePremiumChargeToggle && accountOveragePremiumCharge) {
                                    Decimal priceDiff = pbe.UnitPrice - qli.UnitPrice;
                                    if (priceDiff >= 0) {
                                        dsc += priceDiff;
                                    }
                                }
                                for (QuoteLineItem overageQli : existingOverages) {
                                    if (overageQli.Product_Type__c == pbe.Product2.Product_Type__c) {
                                        if (overageQli.Entitlement__r != null) {
                                            overageQli.Threshold__c = -seatEntitlement.Quantity__c;
                                            qliToInsert.add(overageQli);
                                        }
                                    }
                                }
                            }

                            //B-1497 Port Overage specific logic
                            // Port Overage specific logic
                            if (Product2Helper.isPortProduct(qliProduct2)) {
                                dsc = qli.Discount_number__c;
                                dtype = qli.Discount_Type__c;
                                qty = qli.Quantity;
                            } else if (Product2Helper.isPortProduct(pbe.Product2)) {
                                qty = 0;
                                if (matchingEntitlement != null) {
                                    qty = matchingEntitlement.Quantity__c;
                                }
                            }
                            // B-1497

                            //B-1498 Transport Overage specific logic
                            //B-4627 Transport Overage logic on adding new Seat Product
                            if (isMinutesBundleProduct(pbe.Product2.Product_Type__c, euTransportSettings)) {
                                if (entlTransportQlis.containsKey(pbe.Product2.Product_Type__c)) {
                                    Decimal oldNumberOfMinutes = entlTransportQlis.get(pbe.Product2.Product_Type__c).Product2.Number_of_Minutes__c;
                                    Decimal newNumberOfMinutes = notEntlTransportQlis.containsKey(pbe.Product2.Product_Type__c)
                                        ? notEntlTransportQlis.get(pbe.Product2.Product_Type__c).Product2.Number_of_Minutes__c
                                        : null;
                                    qty = newNumberOfMinutes != null ? newNumberOfMinutes : oldNumberOfMinutes;
                                    // setting overage with entitlement to negative value
                                    for (QuoteLineItem overageQli : existingOverages) {
                                        if (overageQli.Product_Type__c == pbe.Product2.Product_Type__c) {
                                            if (overageQli.Entitlement__r != null) {
                                                overageQli.Threshold__c = - oldNumberOfMinutes;
                                                qliToInsert.add(overageQli);
                                            }
                                        }
                                    }
                                } else {
                                    Decimal newNumberOfMinutes = notEntlTransportQlis.containsKey(pbe.Product2.Product_Type__c)
                                        ? notEntlTransportQlis.get(pbe.Product2.Product_Type__c).Product2.Number_of_Minutes__c
                                        : null;
                                    qty =  NumberHelper.toNumber(newNumberOfMinutes);
                                    for (QuoteLineItem overageQli : existingOverages) {
                                        if (overageQli.Product_Type__c == pbe.Product2.Product_Type__c) {
                                                overageQli.Threshold__c = 0;
                                                qliToInsert.add(overageQli);
                                        }
                                    }
                                }
                            }
                            //B-1498

                            // B-1519 Additional Overages specific logic
                            if (Product2Helper.COMMON_OVERAGE_TYPES.contains(pbe.Product2.Product_Type__c)) {
                                qty = 0;
                            }

                            // Bundles specific logic
                            if (pbe.Product2.Product_Type__c == Product2Helper.PRODUCT_TYPE_AI) {
                                final Decimal bundleVolume = Product2Helper.VOLUME_BY_STRING.get(
                                    relatedProductsMap.get(qli.Product2Id).Name
                                    .substringBefore(' Session Bundle').substringAfterLast(' ')
                                );
                                if (bundleVolume != null) {
                                    qty = bundleVolume;
                                }
                            }
                            if (Product2Helper.PRODUCT_TYPES_BUNDLES.contains(relatedProductsMap.get(qli.Product2Id)?.Product_Type__c)) {
                                qty = 0;
                            }

                            // PBC-10782 Prevent an old Active Storage overage being added for global bundles
                            if (Product2Helper.isGlobalSeat(qliProduct2)) {
                                if (Product2Helper.CATID_ADDITIONAL_STORAGE_OLD == pbe.Product2.CatID__c) {
                                    continue;
                                }
                            } else if (Product2Helper.CATID_ADDITIONAL_STORAGE == pbe.Product2.CatID__c) {
                                continue;
                            }

                            // PBC-15315 Prevent default Storage Retrieval being added for global bundles
                            if (Product2Helper.isGlobalSeat(qliProduct2)
                                    && pbe.Product2.CatID__c == Product2Helper.CATID_STORAGE_RETRIEVAL
                                    && pbe.Product2.Parent__c == null) {
                                continue;
                            }

                            if (
                                pbe.Product2.Product_Type__c == null
                                && (
                                    Product2Helper.FAMILY_ADDONS.equalsIgnoreCase(qliProduct2.Family)
                                    || Product2Helper.FAMILY_SMS.equalsIgnoreCase(qliProduct2.Family)
                                )
                                && !Product2Helper.isPortProduct(pbe.Product2)
                                && !isMinutesBundleProduct(pbe.Product2.Product_Type__c, euTransportSettings)
                                && qliExtId == pbe.Product2.ExtID__c
                            ) {
                                qty = getQuantity(qli);
                            }

                            QuoteLineItem newqli = new QuoteLineItem(
                                QuoteId = qli.QuoteId,
                                PricebookEntryId = pbe.Id,
                                Product2 = pbe.Product2,
                                Quantity = 1,
                                UnitPrice = pbe.UnitPrice,
                                Discount_number__c = dsc,
                                Discount_Type__c = dtype,
                                Zero_Quantity__c = true,
                                Threshold__c = qty,
                                Overage_parent__c = qli.Id
                            );
                            qliToInsert.add(newqli);
                        } else {
                            //if there is existing QLI for overage
                            // B-1497 Update Overage QLI for port type
                            if (Product2Helper.isPortProduct(pbe.Product2)) {
                                for (QuoteLineItem overageQli : existingOverages) {
                                    if (overageQli.Product2Id == pbe.Product2Id) {
                                        overageQli.Threshold__c = qli.Quantity;
                                        overageQli.Discount_Type__c = qli.Discount_Type__c != null
                                            ? qli.Discount_Type__c
                                            : DISCOUNT_TYPE_CURRENCY;
                                        overageQli.Discount_number__c = qli.Discount_number__c != null
                                            ? qli.Discount_number__c
                                            : 0;
                                        qliToInsert.add(overageQli);
                                        break;
                                    }
                                }
                            }
                            //B-1498 Update Overage QLI for transport type
                            //Need to add threshold for overage.
                            //B-4627 Trasnport Overage logic on adding new Transport Product
                            if (isMinutesBundleProduct(pbe.Product2.Product_Type__c, euTransportSettings)) {
                                for (QuoteLineItem overageQli : existingOverages) {
                                    if (overageQli.Product_Type__c == qliProduct2.Product_Type__c) {

                                        Boolean isTransportWithEntl = entlTransportQlis.containsKey(overageQli.Product_Type__c);

                                        Decimal existingNumberOfMinutes = isTransportWithEntl
                                            ? - entlTransportQlis.get(overageQli.Product_Type__c).Product2.Number_of_Minutes__c : 0;

                                        if (!overageQli.Deactivated__c) {
                                            overageQli.Threshold__c = qliProduct2.Number_of_Minutes__c +
                                            (overageQli.Entitlement__r.Id != null ? existingNumberOfMinutes : 0);
                                        } else {
                                            overageQli.Threshold__c = existingNumberOfMinutes;
                                        }
                                        qliToInsert.add(overageQli);
                                    }
                                }
                            }

                            //B-4677 overage's parent determined based on ExtID
                            if (pbe.Product2.Product_Type__c == null || (!Product2Helper.isPortProduct(pbe.Product2) &&
                                !isMinutesBundleProduct(pbe.Product2.Product_Type__c, euTransportSettings) &&
                                qliExtId == pbe.Product2.ExtID__c)
                            ) {
                                for (QuoteLineItem overageQli : existingOverages) {
                                    if (overageQli.Product2Id == pbe.Product2Id) {
                                        overageQli.Threshold__c = getQuantity(qli);

                                        if (overageQli.Product_Type__c == Product2Helper.PRODUCT_TYPE_AI
                                                && relatedProductsMap.get(qli.Product2Id).Name.contains(' Session Bundle')) {
                                            final Decimal bundleVolume = Product2Helper.VOLUME_BY_STRING.get(
                                                relatedProductsMap.get(qli.Product2Id).Name
                                                .substringBefore(' Session Bundle').substringAfterLast(' ')
                                            );
                                            if (bundleVolume != null) {
                                                overageQli.Threshold__c = bundleVolume;
                                            }
                                        }

                                        if (Product2Helper.PRODUCT_TYPES_BUNDLES.contains(relatedProductsMap.get(qli.Product2Id)?.Product_Type__c)) {
                                            overageQli.Threshold__c = 0;
                                        }

                                        if (matchingEntitlement != null) {
                                            overageQli.Threshold__c -= matchingEntitlement.Quantity__c;
                                        }
                                        qliToInsert.add(overageQli);
                                        break;
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        return qliToInsert;
    }

    public static Boolean isMinutesBundleProduct(String productType, List<String> settings) {
        return isUSAorUKTransportType(productType) || isEuropeTransportType(productType, settings);
    }

    public static Boolean isUSAorUKTransportType(String productType) {
        return String.isNotBlank(productType)
            &&
            (
                productType.equalsIgnoreCase(Product2Helper.PRODUCT_TYPE_TRANSPORT)
                ||
                productType.equalsIgnoreCase(Product2Helper.PRODUCT_TYPE_INBOUND_CALLS)
                ||
                productType.equalsIgnoreCase(Product2Helper.PRODUCT_TYPE_OUTBOUND_CALLS)
            );
    }

    public static Boolean isEuropeTransportType(String productType, List<String> settings) {
        if (String.isBlank(productType)) {
            return false;
        }
        for (String s : settings) {
            if (productType.toLowerCase().contains(s.toLowerCase())) {
                return true;
            }
        }
        return false;
    }

    public static List<String> getEuropeTransportTypes() {
        List<String> settings = new List<String>();
        for (ContactCenterEUMinuteBundlesTypes__c s : ContactCenterEUMinuteBundlesTypes__c.getAll().values()) {
            settings.add(s.Product_Type__c);
        }
        return settings;
    }

    public static Boolean isFamilyWithOverage(String productFamily) {
        return String.isNotBlank(productFamily)
            &&
            (
                productFamily.equalsIgnoreCase(Product2Helper.FAMILY_ADDONS)
                ||
                productFamily.equalsIgnoreCase(Product2Helper.FAMILY_SMS)
                ||
                productFamily.equalsIgnoreCase(Product2Helper.FAMILY_WFO)
            );
    }

    private static List<Entitlement__c> getContactCenterEntitlements(List<Entitlement__c> entsToFilter) {
        List<Entitlement__c> res = new List<Entitlement__c>();

        for(Entitlement__c e : entsToFilter) {
            if(Product2Helper.isCCProduct(e.Product__r)) {
                res.add(e);
            }
        }

        return res;
    }

    /**
     * Get Dependent items Changes that should be made when some items are being inserted
     * @param itemsToInsert     QuoteLineItems that are going to be inserted
     * @param priceBookEntries  Product2.Dependent_on_Feature__c, Product2.Feature__c, Product2.Description,
     *                          CurrencyIsoCode, UnitPrice, Pricebook2Id
     * @param entitlements      All Entitlements for an Account
     * @param existingQlis      QuoteLineItems that are currently on Quotes
     * @param quotesList        Pricebook2Id, AccountId
     *
     * @return
     */
    public static List<QuoteLineItem> getDependentOnFeatureItemsOnInsert(
        List<QuoteLineItem> itemsToInsert,
        List<PricebookEntry> priceBookEntries,
        List<Entitlement__c> entitlements,
        List<QuoteLineItem> existingQlis,
        List<Quote> quotesList
    ) {
        List<QuoteLineItem> featureDependentLineItemsToUpsert = new List<QuoteLineItem>();

        Map<Id, Quote> quoteIdToQuoteMap = new Map<Id, Quote>();
        Map<Id, List<Entitlement__c>> accountIdToEntitlements = new Map<Id, List<Entitlement__c>>();
        Map<Id, List<QuoteLineItem>> quoteIdToLineItems = new Map<Id, List<QuoteLineItem>>();
        Map<String, List<QuoteLineItem>> featureDependentLineItems = new Map<String, List<QuoteLineItem>>();
        Map<String, List<QuoteLineItem>> lineItemsWithFeature = new Map<String, List<QuoteLineItem>>();
        Map<String, List<PriceBookEntry>> priceBookEntriesMap = new Map<String, List<PriceBookEntry>>();
        Map<Id, QuoteLineItem> featureDependentLineItemsToUpdate = new Map<Id, QuoteLineItem>();
        Map<Id, QuoteLineItem> featureDependentLineItemsToInsert = new Map<Id, QuoteLineItem>();
        Map<Id, Product2> productsMap = new Map<Id, Product2>();

        // Line Items List after insert
        List<QuoteLineItem> lineItemsAfterInsert = new List<QuoteLineItem>(existingQlis);
        lineItemsAfterInsert.addAll(itemsToInsert);

        // Prepare Quote Map
        for (Quote quote : quotesList) {
            if (!quoteIdToQuoteMap.containsKey(quote.Id)) {
                quoteIdToQuoteMap.put(quote.Id, quote);
            }
        }

        // Prepare Entitlements Map
        for (Entitlement__c ent : entitlements) {
            if (!accountIdToEntitlements.containsKey(ent.Account__c)) {
                accountIdToEntitlements.put(ent.Account__c, new List<Entitlement__c>());
            }
            accountIdToEntitlements.get(ent.Account__c).add(ent);
        }

        // Prepare dependent on Feature Pricebook Entries Map
        for (PriceBookEntry pBookEntry : priceBookEntries) {
            if (pBookEntry.Product2.Dependent_on_Feature__c != null) {
                String key = pBookEntry.Pricebook2Id + String.ValueOf(pBookEntry.Product2.Dependent_on_Feature__c);
                if (!priceBookEntriesMap.containsKey(key)) {
                    priceBookEntriesMap.put(key, new List<PriceBookEntry>());
                }
                priceBookEntriesMap.get(key).add(pBookEntry);
            }

            productsMap.put(pBookEntry.Product2Id, pBookEntry.Product2);
        }


        // Prepare Dependent on Feature Quote Line Items Map
        for (QuoteLineItem qli : lineItemsAfterInsert) {

            if (productsMap.get(qli.Product2Id).Dependent_on_Feature__c != null) {
                String key = qli.QuoteId + String.ValueOf(productsMap.get(qli.Product2Id).Dependent_on_Feature__c);
                if (!featureDependentLineItems.containsKey(key)) {
                    featureDependentLineItems.put(key, new List<QuoteLineItem>());
                }
                featureDependentLineItems.get(key).add(qli);
            }

            if (productsMap.get(qli.Product2Id).Feature__c != null) {
                String key = qli.QuoteId + String.ValueOf(productsMap.get(qli.Product2Id).Feature__c);
                if (!lineItemsWithFeature.containsKey(key)) {
                    lineItemsWithFeature.put(key, new List<QuoteLineItem>());
                }
                lineItemsWithFeature.get(key).add(qli);
            }

        }

        for (String key : lineItemsWithFeature.keySet()) {
            for (QuoteLineItem qli : lineItemsWithFeature.get(key)) {
                String pricebookKey = quoteIdToQuoteMap.get(qli.QuoteId).Pricebook2Id + String.ValueOf(productsMap.get(qli.Product2Id).Feature__c);

                // add Dependent Qli to Update
                if (featureDependentLineItems.containsKey(key)) {
                    for (QuoteLineItem qliToUpdate : featureDependentLineItems.get(key)) {

                        // Get summ of quantity of items with feature. Existing and being inserted
                        Decimal qlisWithFeatureQuantitySumm = 0;
                        for (QuoteLineItem qliWithFeatureOnQuote : lineItemsWithFeature.get(key)) {
                            qlisWithFeatureQuantitySumm += getQuantity(qliWithFeatureOnQuote);
                        }

                        if (qlisWithFeatureQuantitySumm != getQuantity(qliToUpdate)) {

                            qliToUpdate = setQuantity(qliToUpdate, qlisWithFeatureQuantitySumm);

                            featureDependentLineItemsToUpsert.add(qliToUpdate);

                        }

                    }

                } else if (priceBookEntriesMap.containsKey(pricebookKey)) {

                    // add Dependent Qli to insert
                    for (PriceBookEntry pBookEntry : priceBookEntriesMap.get(pricebookKey)) {

                        if (quoteIdToQuoteMap.get(qli.QuoteId).CurrencyIsoCode == pBookEntry.CurrencyIsoCode) {

                            QuoteLineItem newQ = new QuoteLineItem(
                                ServiceDate = Date.today(),
                                Description = pBookEntry.Product2.Description,
                                UnitPrice = pBookEntry.UnitPrice,
                                PriceBookEntryId = pBookEntry.Id,
                                Product2Id = pBookEntry.Product2Id,
                                Quantity = qli.Quantity,
                                Zero_Quantity__c = qli.Zero_Quantity__c,
                                QuoteId = qli.QuoteId
                            );

                            List<Entitlement__c> entlList = accountIdToEntitlements.get(quoteIdToQuoteMap.get(qli.QuoteId).AccountId);

                            // Match Entitlement
                            if (entlList != null) {

                                List<Entitlement__c> matcherResult = (Entitlement__c[]) RecordsMatcher.match(entlList, pBookEntry.Product2, 'Matcher_Formula__c');
                                Entitlement__c matchedEntitlement = (matcherResult.size() > 0 ? matcherResult[0] : null);

                                if (matchedEntitlement != null) {
                                    newQ.Entitlement__c = matchedEntitlement.Id;
                                }

                            }

                            featureDependentLineItemsToUpsert.add(newQ);
                        }
                    }

                }

            }

        }

        return featureDependentLineItemsToUpsert;
    }

    /**
     * Get dependent on feature items changes that should be made when some items are deleting
     * @param itemsToDelete Product2.Feature__c
     * @param existingQlis
     *
     * @return {
     *      'delete' => Items that should be deleted
     *      'update' => Items that should be updated
     * }
     */
    public static Map<String, List<QuoteLineItem>> getDependentOnFeatureItemsOnDelete(
        List<QuoteLineItem> itemsToDelete,
        List<QuoteLineItem> existingQlis) {

        Set<QuoteLineItem> dependentOnFeatureItemsToDelete = new Set<QuoteLineItem>();
        Set<QuoteLineItem> dependentOnFeatureItemsToUpdate = new Set<QuoteLineItem>();

        Map<String, Map<String, QuoteLineItem>> quoteIdToQLIidToDeletingQLIMap = new Map<String, Map<String, QuoteLineItem>>();
        Map<String, List<QuoteLineItem>> featureToExistingQLIsMap = new Map<String, List<QuoteLineItem>>();
        Map<String, List<QuoteLineItem>> dependentOnFeatureToExistingQLIsMap = new Map<String, List<QuoteLineItem>>();

        // Prepare Items To delete map
        for (QuoteLineItem qli : itemsToDelete) {
            if (qli.Product2.Feature__c != null) {
                String key = qli.QuoteId + String.ValueOf(qli.Product2.Feature__c);
                if (!quoteIdToQLIidToDeletingQLIMap.containsKey(key)) {
                    quoteIdToQLIidToDeletingQLIMap.put(key, new Map<String, QuoteLineItem>());
                }
                quoteIdToQLIidToDeletingQLIMap.get(key).put(qli.Id, qli);
            }
        }

        // Prepare items after deletion on quotes map
        for (QuoteLineItem qli : existingQlis) {

            // Feature Map
            if (qli.Product2.Feature__c != null) {
                Map<String, QuoteLineItem> QLIs = quoteIdToQLIidToDeletingQLIMap.get(qli.QuoteId + String.ValueOf(qli.Product2.Feature__c));
                if (QLIs != null && !QLIs.keySet().contains(qli.Id)) {
                    String featureKey = qli.QuoteId + String.ValueOf(qli.Product2.Feature__c);
                    if (!featureToExistingQLIsMap.containsKey(featureKey)) {
                        featureToExistingQLIsMap.put(featureKey, new List<QuoteLineItem>());
                    }
                    featureToExistingQLIsMap.get(featureKey).add(qli);
                }
            }

            // Dependent on feature Map
            if (qli.Product2.Dependent_on_Feature__c != null) {
                Map<String, QuoteLineItem> QLIs = quoteIdToQLIidToDeletingQLIMap.get(qli.QuoteId + String.ValueOf(qli.Product2.Dependent_on_Feature__c));
                if (QLIs != null && !QLIs.keySet().contains(qli.Id)) {
                    String dependentOnFeatureKey = qli.QuoteId + String.ValueOf(qli.Product2.Dependent_on_Feature__c);
                    if (!dependentOnFeatureToExistingQLIsMap.containsKey(dependentOnFeatureKey)) {
                        dependentOnFeatureToExistingQLIsMap.put(dependentOnFeatureKey, new List<QuoteLineItem>());
                    }
                    dependentOnFeatureToExistingQLIsMap.get(dependentOnFeatureKey).add(qli);
                }
            }
        }

        for (Map<String, QuoteLineItem> qliIdToQliMap : quoteIdToQLIidToDeletingQLIMap.values()) {
            for (QuoteLineItem qli : qliIdToQliMap.values()) {
                String key = qli.QuoteId + String.ValueOf(qli.Product2.Feature__c);

                // Dependent on feature items on quote
                List <QuoteLineItem> dependentOnFeatureLineItems = dependentOnFeatureToExistingQLIsMap.get(key);

                // Feature items on quote
                List <QuoteLineItem> featureLineItems = featureToExistingQLIsMap.get(key);

                // Delete Dependent items
                if (featureLineItems == null && dependentOnFeatureLineItems != null) {
                    dependentOnFeatureItemsToDelete.addAll(dependentOnFeatureLineItems);
                } else if (featureLineItems != null && dependentOnFeatureLineItems != null) {

                    Decimal featureQuantity = 0;
                    for (QuoteLineItem featureQLI : featureLineItems) {
                        featureQuantity += getQuantity(featureQLI);
                    }

                    for (QuoteLineItem dependentQli : dependentOnFeatureLineItems) {
                        if (featureQuantity != getQuantity(dependentQli)) {
                            dependentOnFeatureItemsToUpdate.add(setQuantity(dependentQli, featureQuantity));
                        }
                    }
                }

            }
        }

        return new Map<String, List<QuoteLineItem>>{
            'delete' => new List<QuoteLineItem>(dependentOnFeatureItemsToDelete),
            'update' => new List<QuoteLineItem>(dependentOnFeatureItemsToUpdate)
        };
    }

    /**
     * Return quote line items that need to be deleted with CCSeat product
     * @param itemsToDelete Product2.Feature__c
     * @param existingQlis QuoteLineItems that are currently on Quote
     *
     * @return
     */
    public static List<QuoteLineItem> getEESProducts(List<QuoteLineItem> qliList) {

        List<QuoteLineItem> resultList = new List<QuoteLineItem>();

        if (qliList == null || qliList.isEmpty()) {
            return resultList;
        }

        for (QuoteLineItem qli : qliList) {
            if (qli.Product2.Feature__c == Product2Helper.FEATURE_CONTACT_CENTER_EXTENDED_ENTERPRISE) {
                resultList.add(qli);
            }
        }

        return resultList;
    }

    /**
     * Check if QuoteLineItems list contains CCSeat product
     * @param qlisToCheck Product2.Family, Product2.Name
     *
     * @return
     */
    public static Boolean isContainsCCSeat(List<QuoteLineItem> qlisToCheck) {

        Boolean result = false;

        if (qlisToCheck == null || qlisToCheck.isEmpty()) {
            return result;
        }

        for (QuoteLineItem qli : qlisToCheck) {
            if (Product2Helper.isCCSeat(qli.Product2)) {
                result = true;
                break;
            }
        }

        return result;
    }

    /**
     * Get dependent on feature items changes that should be made when some items are updated
     * @param itemsToDelete QuoteId, Product2.Feature__c, Product2.Dependent_on_Feature__c
     * @param existingQlis  QuoteLineItems that are currently on Quote
     *
     * @return
     */
    public static List<QuoteLineItem> getDependentOnFeatureItemsOnUpdate(
        List<QuoteLineItem> itemsToUpdate,
        List<QuoteLineItem> existingQlis) {

        List<QuoteLineItem> dependentOnFeatureItemsToUpdate = new List<QuoteLineItem>();
        Map<String, Map<String, QuoteLineItem>> quoteIdToQLIidToUpdateQLIMap = new Map<String, Map<String, QuoteLineItem>>();
        Map<String, List<QuoteLineItem>> featureToExistingAfterUpdateQLIsMap = new Map<String, List<QuoteLineItem>>();
        Map<String, List<QuoteLineItem>> dependentOnFeatureToExistingQLIsMap = new Map<String, List<QuoteLineItem>>();

        // Prepare Items To Update map
        for (QuoteLineItem qli : itemsToUpdate) {
            if (qli.Product2.Feature__c != null) {
                String key = qli.QuoteId + String.ValueOf(qli.Product2.Feature__c);
                if (!quoteIdToQLIidToUpdateQLIMap.containsKey(key)) {
                    quoteIdToQLIidToUpdateQLIMap.put(key, new Map<String, QuoteLineItem>());
                }
                quoteIdToQLIidToUpdateQLIMap.get(key).put(qli.Id, qli);
            }
        }


        // Prepare Existing Qli Map
        for (QuoteLineItem qli : existingQlis) {

            // Prepare Dependent on Feature Map
            if (qli.Product2.Dependent_on_Feature__c != null) {
                String key = qli.QuoteId + String.ValueOf(qli.Product2.Dependent_on_Feature__c);
                if (!dependentOnFeatureToExistingQLIsMap.containsKey(key)) {
                    dependentOnFeatureToExistingQLIsMap.put(key, new List<QuoteLineItem>());
                }
                dependentOnFeatureToExistingQLIsMap.get(key).add(qli);
            }

            //Prepare Feature Map after update
            if (qli.Product2.Feature__c != null) {
                String key = qli.QuoteId + String.ValueOf(qli.Product2.Feature__c);
                if (!featureToExistingAfterUpdateQLIsMap.containsKey(key)) {
                    featureToExistingAfterUpdateQLIsMap.put(key, new List<QuoteLineItem>());
                }
                Map<String, QuoteLineItem> qliMap = quoteIdToQLIidToUpdateQLIMap.get(key);
                featureToExistingAfterUpdateQLIsMap.get(key)
                    .add(qliMap != null && qliMap.containsKey(qli.Id) ? qliMap.get(qli.Id) : qli);
            }
        }


        for (String key : quoteIdToQLIidToUpdateQLIMap.keySet()) {

            // Get Quantity of all elements with this feature
            Decimal featureQuantity = 0;
            for (QuoteLineItem qli : featureToExistingAfterUpdateQLIsMap.get(key)) {
                featureQuantity += getQuantity(qli);
            }

            if (dependentOnFeatureToExistingQLIsMap.containsKey(key)) {
                // Update Quantity on items
                for (QuoteLineItem qli : dependentOnFeatureToExistingQLIsMap.get(key)) {
                    if (getQuantity(qli) != featureQuantity) {
                        dependentOnFeatureItemsToUpdate.add(setQuantity(qli, featureQuantity));
                    }
                }
            }

        }

        return dependentOnFeatureItemsToUpdate;
    }

    public static void handleDigitalOveragesOnUpdate(List<QuoteLineItem> itemsToUpdate, List<QuoteLineItem> currentQLIs) {

        final Map<Id, QuoteLineItem> itemsToUpdateMap = new Map<Id, QuoteLineItem>(itemsToUpdate);
        List<QuoteLineItem> allQLIs = itemsToUpdate.clone();
        allQLIs.addAll(currentQLIs);
        QuoteLineItem storageOverage;
        Decimal storageQty;
        for (QuoteLineItem qli : allQLIs) {
            if (Product2Helper.isActiveStorage(qli.Product2)) {
                if (isOverage(qli)) {
                    storageOverage = qli;
                } else {
                    storageQty = itemsToUpdateMap.containsKey(qli.Id)
                    ? itemsToUpdateMap.get(qli.Id).Quantity
                    : qli.NewQuantity__c;
                }
            }
        }
        if (storageOverage != null) {
            Decimal newOverageThreshold = NumberHelper.toNumber(storageQty);
            if (storageOverage.Threshold__c == newOverageThreshold) {
                return;
            }
            Boolean isInItemsToUpdate = false;
            for (QuoteLineItem item : itemsToUpdate) {
                if (item.Id == storageOverage.Id) {
                    item.Threshold__c = newOverageThreshold;
                    isInItemsToUpdate = true;
                    break;
                }
            }
            if (!isInItemsToUpdate) {
                storageOverage.Threshold__c = newOverageThreshold;
                itemsToUpdate.add(storageOverage);
            }
        }
    }

    public static void handleDigitalOveragesOnCreate(List<QuoteLineItem> qliToInsert, List<QuoteLineItem> existingQLIs, List<PriceBookEntry> priceBookEntries) {

        Map<Id, Product2> productsMap = new Map<Id, Product2>();
        for (PriceBookEntry pBookEntry : priceBookEntries) {
            productsMap.put(pBookEntry.Product2Id, pBookEntry.Product2);
        }
        QuoteLineItem storageOverage;
        Boolean isOverageInUpsertList = false;
        Boolean isGlobalSeat = false;
        Decimal storageQty;
        for (QuoteLineItem qli : existingQLIs) {
            final Product2 product = productsMap.get(qli.Product2Id);
            if (Product2Helper.isCcService(product)) {
                isGlobalSeat = Product2Helper.isGlobalSeat(product);
            }
            if (Product2Helper.isActiveStorage(product)) {
                if (Product2Helper.isOverage(product)) {
                    storageOverage = qli;
                } else {
                    storageQty = getQuantity(qli);
                }
            }
        }
        for (QuoteLineItem qli : qliToInsert) {
            final Product2 product = qli.Product2 != null ? qli.Product2 : productsMap.get(qli.Product2Id);
            if (Product2Helper.isCcService(product)) {
                isGlobalSeat = Product2Helper.isGlobalSeat(product);
            }
            if (Product2Helper.isActiveStorage(product)) {
                if (Product2Helper.isOverage(product)) {
                    storageOverage = qli;
                    isOverageInUpsertList = true;
                } else {

                    // PBC-10782 Prevent an old Active Storage add-on being added for global bundles and vise versa
                    if (isGlobalSeat) {
                        if (Product2Helper.CATID_ADDITIONAL_STORAGE_OLD == product.CatID__c) {
                            AquivaHelper.throwAuraException('Selected seat supports only the Additional Active Storage (per GB)');
                        }
                    } else if (Product2Helper.CATID_ADDITIONAL_STORAGE == product.CatID__c) {
                        AquivaHelper.throwAuraException('Selected seat supports only the Active Storage (per GB for Concurrent User)');
                    }
                    storageQty = getQuantity(qli);
                }
            }
        }
        if (storageOverage != null) {
            Decimal newThreshold = NumberHelper.toNumber(storageQty);
            if (storageOverage.Threshold__c == null || storageOverage.Threshold__c != newThreshold) {
                storageOverage.Threshold__c = newThreshold;
                if (!isOverageInUpsertList) {
                    qliToInsert.add(storageOverage);
                }
            }
        }
    }

    public static void handleDigitalOveragesOnDelete(QuoteLineItem deletedQli, List<QuoteLineItem> existingQLIs, Map<Id, QuoteLineItem> itemsToUpdate) {
        if (!(Product2Helper.isActiveStorage(deletedQli.Product2) && !Product2Helper.isOverage(deletedQli.Product2))) {
            return;
        }
        QuoteLineItem storageOverage;
        for (QuoteLineItem qli : existingQLIs) {
            if (Product2Helper.isActiveStorage(qli.Product2) && Product2Helper.isOverage(qli.Product2)) {
                storageOverage = qli;
            }
        }
        if (storageOverage != null) {
            if (itemsToUpdate.containsKey(storageOverage.Id)) {
                itemsToUpdate.get(storageOverage.Id).Threshold__c = 0;
            } else {
                storageOverage.Threshold__c = 0;
                itemsToUpdate.put(storageOverage.Id, storageOverage);
            }
        }
    }

    public static void handleBundleServicesOnUpdate(List<QuoteLineItem> itemsToUpdate, List<QuoteLineItem> currentQLIs) {

        final Map<Id, QuoteLineItem> itemsToUpdateMap = new Map<Id, QuoteLineItem>(itemsToUpdate);
        Map<Id, QuoteLineItem> allQLIs = new Map<Id, QuoteLineItem>(itemsToUpdate);
        for (QuoteLineItem currentQli : currentQLIs) {
            if (!allQLIs.containsKey(currentQli.Id)) {
                allQLIs.put(currentQli.Id, currentQli);
            }
        }
        QuoteLineItem ameliaTTS;
        QuoteLineItem ameliaTTSOverage;
        Decimal ameliaNumberOfCalls = 0;
        Set<Id> ameliaBundleQliIds = new Set<Id>();
        for (QuoteLineItem qli : allQLIs.values()) {
            if (qli.Product2.CatID__c == Product2Helper.CATID_AMELIA_TTS) {
                if (Product2Helper.isOverage(qli.Product2)) {
                    ameliaTTSOverage = qli;
                } else {
                    ameliaTTS = qli;
                }
            }
            if (qli.Product2.Product_Type__c == Product2Helper.PRODUCT_TYPE_CALLS && !Product2Helper.isOverage(qli.Product2)) {
                ameliaNumberOfCalls += getQuantity(qli) * Product2Helper.getCCBundleVolume(qli.Product2);
            }
        }
        if (ameliaTTS != null) {
            if (getQuantity(ameliaTTS) == ameliaNumberOfCalls) {
                return;
            }
            Boolean isTTSInItemsToUpdate = false;
            Boolean isTTSOverageInItemsToUpdate = false;
            for (QuoteLineItem item : itemsToUpdate) {
                if (item.Id == ameliaTTS.Id) {
                    setQuantity(item, ameliaNumberOfCalls);
                    isTTSInItemsToUpdate = true;
                } else if (item.Id == ameliaTTSOverage.Id) {
                    item.Threshold__c = ameliaNumberOfCalls;
                    isTTSOverageInItemsToUpdate = true;
                }
            }
            if (!isTTSInItemsToUpdate) {
                setQuantity(ameliaTTS, ameliaNumberOfCalls);
                itemsToUpdate.add(ameliaTTS);
            }
            if (!isTTSOverageInItemsToUpdate) {
                ameliaTTSOverage.Threshold__c = ameliaNumberOfCalls;
                itemsToUpdate.add(ameliaTTSOverage);
            }
        }
    }

    public static void handleBundleServicesOnCreate(List<QuoteLineItem> qliToInsert, List<QuoteLineItem> existingQLIs, List<PriceBookEntry> priceBookEntries) {

        Map<Id, Product2> productsMap = new Map<Id, Product2>();
        for (PriceBookEntry pBookEntry : priceBookEntries) {
            productsMap.put(pBookEntry.Product2Id, pBookEntry.Product2);
        }
        QuoteLineItem ameliaTTS;
        QuoteLineItem ameliaTTSOverage;
        Set<Id> ameliaBundleQliIds = new Set<Id>();
        Decimal ameliaNumberOfCalls = 0;
        Boolean isAmeliaTTSInUpsertList = false;
        Boolean isAmeliaTTSOverageInUpsertList = false;
        for (QuoteLineItem qli : existingQLIs) {
            final Product2 product = productsMap.get(qli.Product2Id);
            if (product.CatID__c == Product2Helper.CATID_AMELIA_TTS) {
                if (Product2Helper.isOverage(product)) {
                    ameliaTTSOverage = qli;
                } else {
                    ameliaTTS = qli;
                }
            }
            if (product.Product_Type__c == Product2Helper.PRODUCT_TYPE_CALLS
                    && !Product2Helper.isOverage(product)
                    && !ameliaBundleQliIds.contains(qli.Id)) {
                ameliaNumberOfCalls += getQuantity(qli) * Product2Helper.getCCBundleVolume(product);
                ameliaBundleQliIds.add(qli.Id);
            }
        }
        for (QuoteLineItem qli : qliToInsert) {
            final Product2 product = qli.Product2 != null ? qli.Product2 : productsMap.get(qli.Product2Id);
            if (product.CatID__c == Product2Helper.CATID_AMELIA_TTS) {
                if (Product2Helper.isOverage(product)) {
                    ameliaTTSOverage = qli;
                    isAmeliaTTSOverageInUpsertList = true;
                } else {
                    ameliaTTS = qli;
                    isAmeliaTTSInUpsertList = true;
                }
            }
            if (product.Product_Type__c == Product2Helper.PRODUCT_TYPE_CALLS
                    && !Product2Helper.isOverage(product)
                    && !ameliaBundleQliIds.contains(qli.Id)) {
                ameliaNumberOfCalls += getQuantity(qli) * Product2Helper.getCCBundleVolume(product);
                ameliaBundleQliIds.add(qli.Id);
            }
        }
        if (ameliaTTS != null) {
            if (ameliaTTS.Quantity == null || getQuantity(ameliaTTS) != ameliaNumberOfCalls) {
                setQuantity(ameliaTTS, ameliaNumberOfCalls);
                ameliaTTSOverage.Threshold__c = ameliaNumberOfCalls;
                if (!isAmeliaTTSInUpsertList) {
                    qliToInsert.add(ameliaTTS);
                }
                if (!isAmeliaTTSOverageInUpsertList) {
                    qliToInsert.add(ameliaTTSOverage);
                }
            }
        }
    }

    public static void handleBundleServicesOnDelete(QuoteLineItem deletedQli, List<QuoteLineItem> existingQLIs, Map<Id, QuoteLineItem> itemsToUpdate) {

        if (!(deletedQli.Product2.Product_Type__c == Product2Helper.PRODUCT_TYPE_CALLS && !Product2Helper.isOverage(deletedQli.Product2))) {
            return;
        }
        QuoteLineItem ameliaTTS;
        QuoteLineItem ameliaTTSOverage;
        Decimal remainingAmeliaNumberOfCalls = 0;
        for (QuoteLineItem qli : existingQLIs) {
            if (deletedQli.Id != qli.Id && qli.Product2.Product_Type__c == Product2Helper.PRODUCT_TYPE_CALLS && !Product2Helper.isOverage(qli.Product2)) {
                remainingAmeliaNumberOfCalls += getQuantity(qli) * Product2Helper.getCCBundleVolume(qli.Product2);
            } else if (qli.Product2.CatID__c == Product2Helper.CATID_AMELIA_TTS) {
                if (Product2Helper.isOverage(qli.Product2)) {
                    ameliaTTSOverage = qli;
                } else {
                    ameliaTTS = qli;
                }
            }
        }
        if (ameliaTTS != null) {
            if (!itemsToUpdate.containsKey(ameliaTTS.Id)) {
                itemsToUpdate.put(ameliaTTS.Id, ameliaTTS);
            }
            if (!itemsToUpdate.containsKey(ameliaTTSOverage.Id)) {
                itemsToUpdate.put(ameliaTTSOverage.Id, ameliaTTSOverage);
            }
            setQuantity(itemsToUpdate.get(ameliaTTS.Id), remainingAmeliaNumberOfCalls);
            itemsToUpdate.get(ameliaTTSOverage.Id).Threshold__c = remainingAmeliaNumberOfCalls;
        }
    }

    public static Map<String, List<QuoteLineItem>> getProServItemsToRemove(List<QuoteLineItem> quoteLineItems) {
        return getProServItemsToRemove(quoteLineItems, QuoteLineItemHelper.SUBCATEGORY_PROSERV);
    }
    public static Map<String, List<QuoteLineItem>> getCCProServItemsToRemove(List<QuoteLineItem> quoteLineItems) {
        return getProServItemsToRemove(quoteLineItems, QuoteLineItemHelper.SUBCATEGORY_CC_PROSERV);
    }

    /**
     * Returns Quote Line Items that needs to be deleted or updated in order to remove ProServ.
     * Products without Entitlements should be deleted
     * Products with Entitlements should be updated with Quantity 0 and new Quantity = Entitlement Quantity
     *
     * @param quoteLineItems List of Quote Line Items to proceed. Should have fields:
     *                       Sub_Category__c, Entitlement__c, Entitlement__r.Quantity__c, NewQuantity__c,
     *                       Zero_Quantity__c, Quantity, QuoteId, Quote.RecordTypeId, Discount_type__c, Discount_number__c
     * @param subcategory    Professional Services || CC Professional Services
     *
     * @return delete Products to delete
     *         update Products to update
     *
     * @see https://aquiva.atlassian.net/wiki/spaces/RC/pages/113999918/Professional+Services Professional Services Documentation
     */
    private static Map<String, List<QuoteLineItem>> getProServItemsToRemove(List<QuoteLineItem> quoteLineItems, String subcategory) {

        Map<Id, Quote> quoteIdToQuoteMap = new Map<Id, Quote>();
        List<QuoteLineItem> qliToDelete = new List<QuoteLineItem>();
        List<QuoteLineItem> qliToUpdate = new List<QuoteLineItem>();

        // Prepare Quotes Map
        for (QuoteLineItem qli : quoteLineItems) {
            if (!quoteIdToQuoteMap.containsKey(qli.quoteId)) {
                quoteIdToQuoteMap.put(qli.quoteId, qli.quote);
            }
        }

        for (QuoteLineItem qli : quoteLineItems) {
            if ((QuoteHelper.isSalesQuote(quoteIdToQuoteMap.get(qli.quoteId)) || QuoteHelper.isCCQuote(quoteIdToQuoteMap.get(qli.quoteId))
                || QuoteHelper.isNewBillingQuote(qli.quote))
                && (subcategory.equalsIgnoreCase(qli.Sub_Category__c) || ITEM_TYPE_PROSERV.equalsIgnoreCase(qli.Item_type__c))) {
                if (qli.Entitlement__c == null) {
                    // Delete (CC) ProServ QLIs
                    qliToDelete.add(qli);
                } else {
                    // Update (CC) ProServ QLIs
                    if (isQliDifferentFromEntitlement(qli)) {
                        qli.NewQuantity__c = qli.Entitlement__r.DisplayQuantity__c;
                        qliToUpdate.add(qli);
                    }
                }
            }
        }

        qliToUpdate = restoreQLIFromEntitlement(qliToUpdate);

        return new Map<String, List<QuoteLineItem>>{
            'delete' => qliToDelete,
            'update' => qliToUpdate
        };
    }

    public static Boolean isDiscountDifferentFromEntitlement(QuoteLineItem qli) {
        return qli.Entitlement__c != null
                ? qli.Discount_type__c != qli.Entitlement__r.Discount_Type__c
                  || qli.Discount_number__c != qli.Entitlement__r.Discount__c
                : true;
    }

    public static Boolean isQliDifferentFromEntitlement(QuoteLineItem qli) {
        return getQuantity(qli) != 0
                || qli.NewQuantity__c != qli.Entitlement__r.DisplayQuantity__c
                || isDiscountDifferentFromEntitlement(qli);
    }

    public static Boolean isPaymentPlanChange(QuoteLineItem qli) {
        Boolean result = false;

        if (!Product2Helper.isUsageLicense(qli.Product2)
                && String.isNotBlank(qli.ChargeTerm__c)
                && String.isNotBlank(qli.Entitlement__r?.ChargeTerm__c)
                ) {
            result = qli.ChargeTerm__c != qli.Entitlement__r.ChargeTerm__c;
        }

        return result;
    }

    public static Boolean isPackageChange(QuoteLineItem qli) {
        Boolean result = false;

        if (String.isNotBlank(qli.PackageCatalogId__c)
                && String.isNotBlank(qli.PackageVersion__c)
                && String.isNotBlank(qli.Entitlement__r?.PackageCatalogId__c)
                && String.isNotBlank(qli.Entitlement__r?.PackageVersion__c)
                ) {
            result = qli.PackageCatalogId__c != qli.Entitlement__r.PackageCatalogId__c
                    || qli.PackageVersion__c != qli.Entitlement__r.PackageVersion__c;
        }

        return result;
    }

    public static Boolean isDiscountChange(QuoteLineItem qli) {
        Boolean result = false;

        if (!Product2Helper.isMobileUser(qli)
                && qli.Discount_Number__c != null
                && qli.Entitlement__r?.Discount__c != null
                && String.isNotBlank(qli.Discount_type__c)
                && String.isNotBlank(qli.Entitlement__r?.Discount_Type__c)
                ) {
            result = qli.Discount_Number__c != qli.Entitlement__r.Discount__c
                    || (qli.Discount_type__c != qli.Entitlement__r.Discount_Type__c && qli.Discount_Number__c != 0);
        }

        return result;
    }

    public static Boolean isDownsell(QuoteLineItem qli) {
        Boolean result = false;

        if (qli.Quantity != null) {
            result = qli.Quantity < 0;
        }

        return result;
    }

    public static Boolean isUpsell(QuoteLineItem qli) {
        if (qli == null) {
            return false;
        }
        return qli.Zero_Quantity__c == false && qli.Quantity > 0;
    }

    public static Boolean isPriceChange(QuoteLineItem qli) {
        Boolean result = false;

        if (qli.UnitPrice != null && qli.Entitlement__r?.Price__c != null) {
            Decimal qliUnitPrice = NumberHelper.roundCurrency(qli.UnitPrice, 2, RoundingMode.HALF_UP);
            Decimal entUnitPrice = NumberHelper.roundCurrency(qli.Entitlement__r.Price__c, 2, RoundingMode.HALF_UP);
            result = qliUnitPrice != entUnitPrice;
        }

        return result;
    }

    /**
     * Returns Quote Line Items that needs to be deleted or updated in order to remove ProServ.
     * Products without Entitlements should be deleted
     * Products with Entitlements should be updated with Quantity 0 and new Quantity = Entitlement Quantity
     *
     * @param quoteLineItems List of Quote Line Items to proceed. Should have fields:
     *                       Zero_Quantity__c, Discount_type__c, Discount_number__c,
     *                       Quantity, Entitlement__c, Entitlement__r.Quantity__c,
     *                       Entitlement__r.Discount_Type__c, Entitlement__r.Discount__c,
     *
     * @return QuoteLineItems to update
     */
    public static List<QuoteLineItem> restoreQLIFromEntitlement(List<QuoteLineItem> quoteLineItems) {

        if (quoteLineItems == null || quoteLineItems.size() < 1) {
            return quoteLineItems;
        }

        List<QuoteLineItem> updatedQLIs = new List<QuoteLineItem>();

        for (QuoteLineItem item : quoteLineItems) {

            Boolean qliIsUpdated = false;

            // copy Quantity__c from Entitlement
            if (item.Quantity != item.Entitlement__r.Quantity__c) {
                item.Quantity = item.Entitlement__r.Quantity__c;

                // fill Zero_Quantity__c with 'true' becouse we have Quantity = item.Entitlement__r.Quantity__c
                item.Zero_Quantity__c = true;

                qliIsUpdated = true;
            }

            // copy Discount_Type__c from Entitlement
            if (item.Discount_type__c != item.Entitlement__r.Discount_Type__c) {
                item.Discount_type__c = item.Entitlement__r.Discount_Type__c;
                qliIsUpdated = true;
            }

            // copy Discount__c from Entitlement
            if (item.Discount_number__c != item.Entitlement__r.Discount__c) {
                item.Discount_number__c = item.Entitlement__r.Discount__c;
                qliIsUpdated = true;
            }

            if (qliIsUpdated) {

                // if qli is restored - need to set 'false' value in Deactivated__c field
                item.Deactivated__c = false;

                updatedQLIs.add(item);
            }
        }

        return updatedQLIs;
    }


    public static QuoteLineItem findExtendedEnterpriseQLIWithEntitlement(List<QuoteLineItem> qliList) {
        QuoteLineItem result = null;

        for (QuoteLineItem qli : qliList) {
            if (Product2Helper.isExtendedEnterprise(qli.Product2) && isHasEntitlement(qli)) {
                result = qli;
                break;
            }
        }
        return result;
    }


    public static QuoteLineItem findExtendedEnterpriseQLIWithoutEntitlement(List<QuoteLineItem> qliList) {
        QuoteLineItem result = null;

        for (QuoteLineItem qli : qliList) {
            if (Product2Helper.isExtendedEnterprise(qli.Product2) && !isHasEntitlement(qli)) {
                result = qli;
                break;
            }
        }
        return result;
    }

    public static Boolean isHasEntitlement(QuoteLineItem qli) {
        return qli != null && qli.Entitlement__c != null;
    }

    /**
     * Get resulting Quantity on product that client will have
     * For Existing customers QuoteLineItem.NewQuantity__c field contains resulting quantity and
     * QuoteLineItem.Quantity contains the delta between Quantity on entitlement and resulting.
     *
     * For New Customers QuoteLineItem.Quantity field should be used. QuoteLineItem.NewQuantity__c is not in use
     * @deprecated Just use NewQuantity__c in that case
     */
    public static Decimal getResultingQuantity(QuoteLineItem qli) {
        return isHasEntitlement(qli) ? qli.NewQuantity__c : qli.Quantity;
    }

    public static Decimal getResultingQuantity(QuoteLineItem qli, Entitlement__c qliEntitlement) {
        return qliEntitlement != null ? qli.NewQuantity__c : qli.Quantity;
    }


    public static QuoteLineItem setResultingQuantity(QuoteLineItem qli, Decimal resultingQuantity, Entitlement__c qliEntitlement) {
        qliEntitlement = qliEntitlement == null ? qli.Entitlement__r : qliEntitlement;

        if (isHasEntitlement(qli)) {
            qli.NewQuantity__c = resultingQuantity;
            Decimal existingQuantity = qliEntitlement.DisplayQuantity__c;
            Decimal diffQuantity = resultingQuantity - existingQuantity;
            qli = setQuantity(qli, diffQuantity);

        } else {
            qli = setQuantity(qli, resultingQuantity);

        }
        return qli;
    }


    public static QuoteLineItem setResultingQuantity(QuoteLineItem qli, Decimal resultingQuantity) {
        return setResultingQuantity(qli, resultingQuantity, null);
    }


    /**
     * Get Quote Line Item Discount final value
     *
     * Percentage discounts will be converted to money
     */
    public static Decimal getDiscountValue(QuoteLineItem qli) {
        Decimal discountValue = 0;
        Decimal discountNumber = qli.Discount_number__c == null ? 0 : qli.Discount_number__c;

        if (DISCOUNT_TYPE_CURRENCY.equalsIgnoreCase(qli.Discount_type__c)) {
            discountValue = discountNumber;

        } else if (DISCOUNT_TYPE_PERCENTAGE.equalsIgnoreCase(qli.Discount_type__c)) {
            discountValue = (qli.UnitPrice / 100) * discountNumber;

        }

        return discountValue;
    }

    /**
     * Get Quote Line Item Approved Discount final value
     *
     * Percentage discounts will be converted to money
     */
    public static Decimal getApprovedDiscountValue(QuoteLineItem qli) {
        Decimal approvedDiscountValue = 0;
        Decimal approvedDiscount = qli.Last_Approved_Discount__c == null ? 0 : qli.Last_Approved_Discount__c;

        if (DISCOUNT_TYPE_CURRENCY.equalsIgnoreCase(qli.Last_Approved_Discount_Type__c)) {
            approvedDiscountValue = approvedDiscount;

        } else if (DISCOUNT_TYPE_PERCENTAGE.equalsIgnoreCase(qli.Last_Approved_Discount_Type__c)) {
            approvedDiscountValue = (qli.UnitPrice / 100) * approvedDiscount;

        }

        return approvedDiscountValue;
    }

    /**
     * Builds QuoteId => QuoteLineItem[] Map
     */
    public static Map<Id, List<QuoteLineItem>> buildQuoteIdToQliMap(List<QuoteLineItem> qliList) {
        Map<Id, List<QuoteLineItem>> quoteToQLIListMap = new Map<Id, List<QuoteLineItem>>();

        for (QuoteLineItem qli : qliList) {
            if (!quoteToQLIListMap.containsKey(qli.QuoteId)) {
                quoteToQLIListMap.put(qli.QuoteId, new List<QuoteLineItem>());
            }
            quoteToQLIListMap.get(qli.QuoteId).add(qli);
        }

        return quoteToQLIListMap;
    }

    /**
     * Check if product will be deactivated
     */
    public static Boolean isDeactivated(QuoteLineItem qli) {
        return qli != null && qli.Deactivated__c;
    }

    /**
     * Deactivate Product for client
     * resulting quantity 0
     */
    public static QuoteLineItem deactivate(QuoteLineItem qli) {
        qli.Deactivated__c = true;
        qli.Quantity = -qli.Entitlement__r.Quantity__c;
        qli.Zero_Quantity__c = false;
        qli.NewQuantity__c = 0;
        return qli;
    }

    /**
     * Makes quote line item active and restore its quantity
     */
    public static QuoteLineItem activate(QuoteLineItem qli) {
        qli.Deactivated__c = false;
        qli.Quantity = 1;
        qli.Zero_Quantity__c = true;
        qli.NewQuantity__c = qli.Entitlement__r.DisplayQuantity__c;
        return qli;
    }

    /**
     * Populates QuoteLineItem fields from PriceBookEntry
     * Can be used to prepare QuoteLineItem before it will be inserted
     */
    public static QuoteLineItem createFromPBE(PricebookEntry pbe, QuoteLineItem sourceQLI) {
        QuoteLineItem result = sourceQLI == null ? new QuoteLineItem() : sourceQLI;

        result.Product2Id = pbe.Product2Id;
        result.UnitPrice = pbe.UnitPrice;
        result.Description = pbe.Product2.Description;
        result.PricebookEntryId = pbe.Id;

        return result;
    }

    public static QuoteLineItem createFromPBE(PricebookEntry pbe) {
        return createFromPBE(pbe, null);
    }

    public static QuoteLineItem getAnyQuoteLineItemWithEntitlement(QuoteLineItem[] qlis) {
        QuoteLineItem result;

        for(QuoteLineItem qli : qlis) {
            if (qli.Entitlement__r != null) {
                result = qli;
                break;
            }
        }

        return result;
    }

    public static QuoteLineItem getAnyQuoteLineItemWithPartnerEntitlement(QuoteLineItem[] qlis) {
        QuoteLineItem result;

        for(QuoteLineItem qli : qlis) {
            if (qli.Entitlement__r != null && qli.Entitlement__r.PartnerConfig__c != null) {
                result = qli;
                break;
            }
        }

        return result;
    }

    /**
     * Searches for Active Service Plan Quote Line Item in List
     */
    public static QuoteLineItem findActiveServicePlan(List<QuoteLineItem> qliList) {
        QuoteLineItem servicePlanQLI = null;
        for (QuoteLineItem qli : qliList) {

            if (Product2Helper.isServicePlan(qli.Product2) && !isDeactivated(qli)) {
                servicePlanQLI = qli;
                break;
            }
            if (qli.Entitlement__c != null && QuoteHelper.isPhoenix(new Quote(Id = qli.QuoteId, Package_Info__c = qli.Quote.Package_Info__c))) {
                servicePlanQLI = qli;
                break;
            }
        }
        return servicePlanQLI;
    }

    /**
     * Check Quantity of QLI for Extended Enterprise Support Products to match Quantity of QLI for Service Product.
     * Add/Remove/Activate/Deactivate EES products if out of range.
     *
     * Call method after all changes has been saved on Quote/QuoteLineItems
     *
     * Documentation:
     * https://aquiva.atlassian.net/wiki/spaces/RC/pages/192610356/Extended+Enterprise+Support
     *
     * B-3578 Extended enterprise support to match # of DLs
     * https://rc.my.salesforce.com/a203400000464Gi
     *
     * @see Test_ExtendedEnterpriseSupport Test Class
     *
     * @param quoteLineItemsOnQuote Existing Quote Line Items on quote. Should contain Service Plan and EES products
     *                              Required Fields:
     *                              Id, Product2Id, Product2.Feature__c, Product2.Family, Quantity, Zero_Quantity__c,
     *                              NewQuantity__c, Product2.Seat_Range_Min__c, Product2.Seat_Range_Max__c,
     *                              Deactivated__c, Entitlement__c, Entitlement__r.Quantity__c, Product2.Name, QuoteId
     *
     * @param pricebookEntries      PriceBookEntries supported on Quote. Should contain EES products.
     *                              Required Fields:
     *                              Id, Product2Id, Product2.Name, Product2.Feature__c, Product2.Family,
     *                              Product2.Description, Product2.Seat_Range_Min__c, Product2.Seat_Range_Max__c
     *
     *
     * @return <code>result.get(ACTION_DELETE)</code> List of Quote Line Items that should be deleted
     *         <code>result.get(ACTION_UPSERT)</code> List of Quote Line Items that should be upsert
     */
    public static Map<String, List<QuoteLineItem>> handleExtendedEnterpriseSupport(
        List<QuoteLineItem> quoteLineItemsOnQuote,
        List<PricebookEntry> pricebookEntries) {

        List<QuoteLineItem> qlisToDelete = new List<QuoteLineItem>();
        List<QuoteLineItem> qlisToUpsert = new List<QuoteLineItem>();
        Map<String, List<QuoteLineItem>> result = new Map<String, List<QuoteLineItem>>{
            ACTION_DELETE => qlisToDelete,
            ACTION_UPSERT => qlisToUpsert
        };

        // Find Service Product
        QuoteLineItem serviceQLI = findActiveServicePlan(quoteLineItemsOnQuote);

        // Find EES Without Entitlement
        QuoteLineItem EESqliWithoutEnt =
            QuoteLineItemHelper.findExtendedEnterpriseQLIWithoutEntitlement(quoteLineItemsOnQuote);

        // Find EES With Entitlement
        QuoteLineItem EESqliWithEnt = findExtendedEnterpriseQLIWithEntitlement(quoteLineItemsOnQuote);

        // Skip if there is no Service Product
        if (serviceQLI == null || (EESqliWithoutEnt == null && EESqliWithEnt == null)) {
            return result;
        }
        Decimal serviceQLIResultingQuantity = getResultingQuantity(serviceQLI);

        // Check if extended Enterprise Support products are in supported range
        Boolean isEESWithoutEntInRange = EESqliWithoutEnt != null
            && Product2Helper.isExtendedEnterpriseSupportInRange(EESqliWithoutEnt.Product2, serviceQLI);

        Boolean isEESWithEntInRange = EESqliWithEnt != null
            && Product2Helper.isExtendedEnterpriseSupportInRange(EESqliWithEnt.Product2, serviceQLI);

        Boolean isEESqliWithEntDeactivated = isDeactivated(EESqliWithEnt);

        // Update Quantity on qli without entitlement if it is in range
        // but quantity not the same with Service Plan
        if (EESqliWithoutEnt != null
            && isEESWithoutEntInRange
            && serviceQLIResultingQuantity != getResultingQuantity(EESqliWithoutEnt)) {

            Boolean isEESBronze = Product2Helper.isExtendedEnterpriseBronze(EESqliWithoutEnt.Product2);
            if (isEESBronze) {
                setResultingQuantity(EESqliWithoutEnt, 1);
            } else {
                setResultingQuantity(EESqliWithoutEnt, serviceQLIResultingQuantity);
            }

            qlisToUpsert.add(EESqliWithoutEnt);
        }

        // Delete item without entitlement if it is not in range
        Boolean isEESqliWithoutEntToBeDeleted = false;
        if (EESqliWithoutEnt != null && !isEESWithoutEntInRange) {
            qlisToDelete.add(EESqliWithoutEnt);
            isEESqliWithoutEntToBeDeleted = true;
        }

        // Deactivate item with entitlement if it is not in range
        Boolean isEESqliWithEntToBeDeactivated = false;
        if (EESqliWithEnt != null && !isEESWithEntInRange) {
            qlisToUpsert.add(deactivate(EESqliWithEnt));
            isEESqliWithEntToBeDeactivated = true;
        }

        // Activate item with Entitlement if it is in range and deactivated
        Boolean isEESqliWithEntToBeActivated = false;
        if (EESqliWithEnt != null && isEESWithEntInRange && isEESqliWithEntDeactivated) {
            activate(EESqliWithEnt);

            Boolean isEESBronze = Product2Helper.isExtendedEnterpriseBronze(EESqliWithEnt.Product2);
            if (isEESBronze) {
                setResultingQuantity(EESqliWithEnt, 1);
            } else {
                setResultingQuantity(EESqliWithEnt, serviceQLIResultingQuantity);
            }

            qlisToUpsert.add(EESqliWithEnt);
            isEESqliWithEntToBeActivated = true;
        }

        // Update Quantity on qli with entitlement if it is in range
        // but quantity not the same with Service Plan
        if (EESqliWithEnt != null
            && isEESWithEntInRange
            && serviceQLIResultingQuantity != getResultingQuantity(EESqliWithEnt)
            && !isEESqliWithEntToBeActivated) {

            Boolean isEESBronze = Product2Helper.isExtendedEnterpriseBronze(EESqliWithEnt.Product2);
            if (isEESBronze) {
                setResultingQuantity(EESqliWithEnt, 1);
            } else {
                setResultingQuantity(EESqliWithEnt, serviceQLIResultingQuantity);
            }
            qlisToUpsert.add(EESqliWithEnt);
        }

        // Add Extended Enterprise Support product with supported level
        Boolean check1 = isEESqliWithoutEntToBeDeleted
            && (EESqliWithEnt == null || (isEESqliWithEntDeactivated && !isEESqliWithEntToBeActivated));
        Boolean check2 = isEESqliWithEntToBeDeactivated && EESqliWithoutEnt == null;
        if (check1 || check2) {
            PricebookEntry priceBookEntryToAdd = null;

            // Find Extended Enterprise Support PricebookEntry to add
            for (PricebookEntry pbe : pricebookEntries) {

                if (Product2Helper.isExtendedEnterprise(pbe.Product2)
                    && Product2Helper.isExtendedEnterpriseSupportInRange(pbe.Product2, serviceQLI)) {
                    priceBookEntryToAdd = pbe;
                    break;
                }
            }

            // if found add it as qli
            if (priceBookEntryToAdd != null) {

                QuoteLineItem newEESQLI = createFromPBE(priceBookEntryToAdd);

                Boolean isEESBronze = Product2Helper.isExtendedEnterpriseBronze(
                    priceBookEntryToAdd.Product2.Feature__c,
                    priceBookEntryToAdd.Product2.Name
                );

                if (isEESBronze) {
                    setResultingQuantity(newEESQLI, 1);
                } else {
                    setResultingQuantity(newEESQLI, serviceQLIResultingQuantity);
                }
                newEESQLI.QuoteId = serviceQLI.QuoteId;
                qlisToUpsert.add(newEESQLI);
            }
        }

        return result;
    }

    /**
     * Products used by new billing system do not have Charge Term
     *
     * Qli shoud have next fields:
     * Product2.Charge_Term__c, QuoteRecordType__c or Quote.RecordTypeId
     */
    public static String getChargeTerm(QuoteLineItem qli) {
        Boolean isNewBilling = false;
        if (qli?.QuoteRecordType__c != null) {
            isNewBilling = QuoteHelper.isNewBillingQuote(qli) && String.isNotBlank(qli?.PackageInfo__c);
        } else if (qli?.Quote?.RecordTypeId != null) {
            isNewBilling = QuoteHelper.isNewBillingQuote(qli?.Quote) && String.isNotBlank(qli?.PackageInfo__c);
        }

        return isNewBilling ? new BillingWrappers.QLIPackageInfo(qli?.PackageInfo__c).duration
            : qli?.Product2?.Charge_Term__c;
    }

    public static Decimal getEffectivePrice(QuoteLineItem qli) {

        Decimal result = 0;

        if(qli == null) {
            return result;
        }

        Decimal qliEffectivePriceValue = qli.EffectivePriceNew__c == null ? 0 : qli.EffectivePriceNew__c;
        result = qliEffectivePriceValue;

        return result;
    }

    /*
     * For calculate TotalAnnualPriceWithEntitlement__c
     * Qli should have next fields:
     *
     *      Discount, UnitPrice, NewQuantity__c,
     *      Product2.Charge_Term__c, Quote.RecordTypeId, PackageInfo__c
     *
     */
    public static Decimal getTotalAnnualPriceWithEntitlement(QuoteLineItem qli) {
        Decimal result;
        Decimal totalPrice = getTotalPrice(qli); // qty = (Zero_Quantity__c || 'Overage') ? 0 : Quantity;

        if (isMonthly(qli) || isMonthlyContract(qli)) {
            result = totalPrice * 12;
        } else {
            result = isAnnual(qli) ? totalPrice : 0;
        }

        return result.setScale(6);
    }

    /*
     * For calculate TotalMonthlyPriceWithEntitlement__c
     * Qli should have next fields:
     *
     *      Discount, UnitPrice, NewQuantity__c,
     *      Product2.Charge_Term__c, Quote.RecordTypeId, PackageInfo__c
     *
     */
    public static Decimal getTotalMonthlyPriceWithEntitlement(QuoteLineItem qli) {
        Decimal result;
        Decimal totalPrice = getTotalPrice(qli);

        if (isMonthly(qli) || isMonthlyContract(qli)) {
            result = totalPrice;
        } else {
            result = isAnnual(qli) ? totalPrice / 12 : 0;
        }

        return result.setScale(6);
    }

    /* check charge term */
    public static Boolean isMonthly(QuoteLineItem qli) {
        return getChargeTerm(qli) == Product2Helper.CHARGE_TERM_MONTHLY;
    }
    public static Boolean isMonthlyContract(QuoteLineItem qli) {
        return getChargeTerm(qli) == Product2Helper.CHARGE_TERM_MONTHLY_CONTRACT;
    }
    public static Boolean isAnnual(QuoteLineItem qli) {
        return getChargeTerm(qli) == Product2Helper.CHARGE_TERM_ANNUAL;
    }
    public static Boolean isOneTime(QuoteLineItem qli) {
        return getChargeTerm(qli) == Product2Helper.CHARGE_TERM_ONE_TIME;
    }

    /* check family */
    public static Boolean isOverage(QuoteLineItem qli) {
        return Product2Helper.FAMILY_OVERAGE.equalsIgnoreCase(qli.Product2.Family);
    }

    public static Decimal getYourPrice(QuoteLineItem qli) {
        Decimal result = 0;
        Decimal discount = NumberHelper.toNumber(qli?.Discount);
        result = ((1 - discount / 100) * NumberHelper.toNumber(qli?.UnitPrice)).setScale(2);
        return result;
    }

    public static Decimal getTotalPrice(QuoteLineItem qli) {
        return NumberHelper.toNumber(qli?.NewQuantity__c) * getYourPrice(qli);
    }

    public static Decimal getYourPrice(Cost_Center_Line_Item__c ccli) {
        Decimal result = 0;
        if (ccli == null) {
            return result;
        }

        Decimal discount = (ccli.Quote_Line_Item__r != null && ccli.Quote_Line_Item__r.Discount != null)
            ? ccli.Quote_Line_Item__r.Discount
            : 0;
        Decimal unitPrice = (ccli.Quote_Line_Item__r != null && ccli.Quote_Line_Item__r.UnitPrice != null)
            ? ccli.Quote_Line_Item__r.UnitPrice
            : 0;

        result = (1 - discount / 100) * unitPrice;
        return result;
    }

    public static Decimal getTotalPrice(Cost_Center_Line_Item__c ccli) {
        Decimal result = 0;
        if (ccli == null) {
            return result;
        }
        Decimal quantity = ccli.Quantity__c != null ? ccli.Quantity__c : 0;
        return quantity * getYourPrice(ccli);
    }


    /**
     * Calculate and set total values on Quote
     *
     * Documentation:
     * https://aquiva.atlassian.net/wiki/spaces/RC/pages/192446527/Quote+Totals
     *
     * @param quotesToUpdate
     * @param qliList
     *
     * @return
     */
    public static List<Quote> setTotals(List<Quote> quotesToUpdate, List<QuoteLineItem> qliList) {

        Map<Id, List<QuoteLineItem>> quoteToQLIListMap = QuoteLineItemHelper.buildQuoteIdToQliMap(qliList);

        Map<Id, SetApprovalTypeHelper.QuoteTabValues> quoteId_Values = SetApprovalTypeHelper.getTabValues(qliList);

        Map<Id, Decimal> quoteSumProServOneTime = SetApprovalTypeHelper.getMapProServOneTime(qliList);

        Map<Id, Decimal> initialDiscountWithoutProServMap = SetApprovalTypeHelper.getInitialDiscountWithoutProServ(qliList);

        for (Quote qt : quotesToUpdate) {

            if (quoteId_Values.containsKey(qt.Id)) {
                List<QuoteLineItem> quoteQLIs = quoteToQLIListMap.get(qt.Id);

                qt.ProServSOWDiscount__c = QuoteHelper.calcTotalProServSOWDiscount(quoteQLIs);
                qt.sumProServOneTime__c = quoteSumProServOneTime.containsKey(qt.Id) ? quoteSumProServOneTime.get(qt.Id) : 0;
                qt.First_Year_Cost_of_Service__c = quoteId_Values.get(qt.Id).FYCS - qt.sumProServOneTime__c;
                qt.First_Year_Discount__c = quoteId_Values.get(qt.Id).FYD;
                qt.Monthly_Recurring_Revenue__c = quoteId_Values.get(qt.Id).MRV;
                qt.Initial_Discount_without_ProServ__c = initialDiscountWithoutProServMap.get(qt.Id);
                qt.First_Year_Total_Cost_excluding_Taxes__c = quoteId_Values.get(qt.Id).FYTCET - qt.sumProServOneTime__c;
            }
        }

        return quotesToUpdate;
    }

    // 2. Automatically add Setup Fees for selected Area Codes on Quote and on Additional Number Products.
    // 2.1. Automatically add True 800 Number Setup Product (Feature == 4) with Quantity that is equal to Quantity of ACLI with Area Code Name == 800 that will be added.
    // 2.2. Automatically add Vanity Toll Free Number Setup Product (Feature == 5) with Quantity that is equal to Number of checked 'Is Vanity' checkboxes.
    public static List<QuoteLineItem> getQuoteLineItemsByFeature(
        List<PricebookEntry> priceBookEntries,
        Map<Decimal, Decimal> featureToQuantityMap,
        Id quoteId
    ) {
        List<QuoteLineItem> qlisToInsert = new List<QuoteLineItem>();
        if (featureToQuantityMap == null || featureToQuantityMap.values().size() == 0) {
            return qlisToInsert;
        }

        Map<Id, List<Entitlement__c>> accountIdToEntitlements = new Map<Id, List<Entitlement__c>>();
        Map<Decimal, List<PriceBookEntry>> featureToPricebookEntriesMap = new Map<Decimal, List<PriceBookEntry>>();
        Map<Id, Product2> productsMap = new Map<Id, Product2>();

        // Prepare Feature to Pricebook Entries Map
        for (PriceBookEntry pBookEntry : priceBookEntries) {
            if (!featureToPricebookEntriesMap.containsKey(pBookEntry.Product2.Feature__c)) {
                featureToPricebookEntriesMap.put(pBookEntry.Product2.Feature__c, new List<PriceBookEntry>());
            }
            featureToPricebookEntriesMap.get(pBookEntry.Product2.Feature__c).add(pBookEntry);
        }

        for (Decimal feature : featureToQuantityMap.keySet()) {
            List<PricebookEntry> pbes = featureToPricebookEntriesMap.get(feature);
            Decimal quantity = featureToQuantityMap.get(feature);

            for (PricebookEntry pbe : pbes) {
                QuoteLineItem newQli = createFromPBE(pbe);
                setResultingQuantity(newQli, quantity);
                newQli.QuoteId = quoteId;

                qlisToInsert.add(newQli);
            }
        }

        return qlisToInsert;
    }

    public static List<PricebookEntry> filterProductsByPermissions(List<PricebookEntry> products, Map<String, Boolean> userPermissions) {

        List<PricebookEntry> filteredProducts = new List<PricebookEntry>();

        for (PricebookEntry pb : products) {
            Boolean pbContainsPermissions = true;
            if (String.isNotBlank(pb.Product2.Custom_Permission_Set__c)) {
                for (String permission : pb.Product2.Custom_Permission_Set__c.split(';')) {
                    if (!userPermissions.keySet().contains(permission)) {
                        pbContainsPermissions = false;
                        break;
                    }
                }
            }
            if (pbContainsPermissions) {
                filteredProducts.add(pb);
            }
        }
        return filteredProducts;
    }

    public static List<PricebookEntry> filterProductsByChargeTerm(List<PricebookEntry> products, String chargeTerm) {
        List<PricebookEntry> result = new List<PricebookEntry>();
        for (PricebookEntry pe : products) {
            if (pe.Product2.Charge_Term__c != Product2Helper.CHARGE_TERM_ONE_TIME
                && pe.Product2.Charge_Term__c != chargeTerm) {
                continue;
            }
            result.add(pe);
        }

        return result;
    }
    // B-5902
    // This method is used to bypass approval recalculation if a dependent product is added to cart.
    // Dependent product is product quantity of which is changed after adding it to cart or
    // after changing another product's quantity (e.g. DigitalLine Hot Desking or Extended Enterprise Support).
    public static Boolean isSkipUpdate(List<QuoteLineItem> qlis) {
        Set<Decimal> featuresToSkipSet = new Set<Decimal>{
            Product2Helper.FEATURE_EXTENDED_ENTERPRISE_SUPPORT,
            Product2Helper.FEATURE_DIGITAL_LINE_HOT_DESKING
        };

        Boolean isSkip = false;
        if (
            (qlis != null && QuoteLineItemTriggerHelper.productsMapStatic.size() > 0)
                && (qlis.size() == 1)
                && featuresToSkipSet.contains(
                QuoteLineItemTriggerHelper.productsMapStatic.get(qlis[0].Product2Id).Feature__c
            )
            ) {

            isSkip = true;
        }

        return isSkip;
    }

    public static QuoteLineItem getServicePlanQLI(List<QuoteLineItem> qlis) {
        QuoteLineItem res = null;

        for(QuoteLineItem qli : qlis) {
            if(Product2Helper.isServicePlan(qli.Product2)) {
                res = qli;
                break;
            }
        }

        return res;
    }

    //depricated method
    //it's better to use QuoteHelper.isNGBSQuote(qli)
    public static Boolean isNGBSQuoteLineItem(QuoteLineItem qli) {
        if (qli == null || qli.QuoteRecordType__c == null) {
            return false;
        }
        return qli.QuoteRecordType__c == QuoteHelper.RT_NAME_BILLING;
    }

    public static Decimal getCurrentTotal(QuoteLineItem qli) {
        Decimal result = 0;
        if (qli == null) {
            return result;
        }

        Decimal existingQuantity;
        Decimal existingEffectivePrice;
        if (String.isBlank(qli.PackageInfo__c)) {
            existingQuantity = qli.Last_Approved_Quantity__c != null
                ? qli.Last_Approved_Quantity__c
                : getQuantity(qli);
            existingEffectivePrice = qli.Last_Approved_Discount__c != null
                ? (qli.UnitPrice - getApprovedDiscountValue(qli))
                : qli.EffectivePriceNew__c;
        } else {
            // When billing quote line items
            existingQuantity = qli.Entitlement__r.Quantity__c != null ? qli.Entitlement__r.Quantity__c : 0;
            existingEffectivePrice = qli.Entitlement__r.EffectivePrice__c != null ? qli.Entitlement__r.EffectivePrice__c : 0;
        }

        result = existingQuantity * existingEffectivePrice;
        return result;
    }

    public static Boolean isAnnualBillingCycle(QuoteLineItem qli) {
        return (qli != null && qli.Billing_Cycle_Duration__c == BILLING_CYCLE_DURATION_ANNUAL);
    }

    public static Boolean isMonthlyBillingCycle(QuoteLineItem qli) {
        return (qli != null && qli.Billing_Cycle_Duration__c == BILLING_CYCLE_DURATION_MONTHLY);
    }

    public class OveragesParentsMatcher{

        // Special product types for overage parent product search logic.
        // Full product type name includes counrty name at the end, e.g. 'Landline outbound minutes FR'.
        public final Set<String> MINUTE_BUNDLE_PRODUCT_TYPES  = new Set<String>{
            'Landline outbound minutes',
            'Mobile outbound minutes',
            'Toll Free Inbound from landline minutes',
            'Toll Free Inbound from Mobile minutes'
        };

        public final Set<String> SEAT_OVERAGES = new Set<String>{
            'International Minutes Overage',
            'IVN Minutes Overage',
            'Contact Center: Automated Speech Recognition (per minute)',
            'Contact Center: Data Storage beyond 1 GB per Seat',
            'Contact Center: Monthly Long-term Storage Retrieval (per GB)',
            'Contact Center: Monthly Overage for Long-term Storage (per GB)',
            'Professional Services On-Demand (per 15-minute block)',
            'Professional Services OnDemand (per 15-minute block)'
        };

        // qlisByExtId map - keys transformed to lower case.
        private Map<String, QuoteLineItem> qlisByExtId = new Map<String, QuoteLineItem>();
        private Map<Id, QuoteLineItem> qlisByProductId = new Map<Id, QuoteLineItem>();
        private Map<String, QuoteLineItem> qlisByProductType = new Map<String, QuoteLineItem>();
        private QuoteLineItem seatQli;

        public OveragesParentsMatcher() {
        }

        public OveragesParentsMatcher(List<QuoteLineItem> qlis) {
            addToSearchScope(qlis);
        }

        public void addToSearchScope(List<QuoteLineItem> qlis) {
            for (QuoteLineItem qli : qlis) {
                addToSearchScope(qli);
            }
        }

        public void addToSearchScope(QuoteLineItem qli) {
            if (qli.Product2.Family != Product2Helper.FAMILY_OVERAGE) {

                qlisByProductId.put(qli.Product2.Id, qli);

                if (isMinuteBundleProduct(qli)) {
                    qlisByProductType.put(qli.Product2.Product_Type__c, qli);
                }

                if (Product2Helper.isCCSeat(qli.Product2)) {
                    seatQli = qli;
                }

                if (qli.Product2.ExtId__c != null) {
                    qlisByExtId.put(qli.Product2.ExtId__c.toLowerCase(), qli);
                }
            }
        }

        public QuoteLineItem getParent(QuoteLineItem qli) {
            if (qli.Product2.Parent__c != null) {
                return qlisByProductId.get(qli.Product2.Parent__c);

            } else if (SEAT_OVERAGES.contains(qli.Product2.Name)) {
                return seatQli;

            } else if (isMinuteBundleProduct(qli)) {
                // Special Minute Bundle overages (see MINUTE_BUNDLE_PRODUCT_TYPES). Matching by Product_Type__c.
                return qlisByProductType.get(qli.Product2.Product_Type__c);

            } else if (qli.Product2.ExtId__c != null) {
                String parentExtId = 'null_' + qli.Product2.ExtId__c.substringAfter('_').toLowerCase();
                return qlisByExtId.get(parentExtId);
            }

            return null;
        }

        private Boolean isMinuteBundleProduct(QuoteLineItem qli) {
            return qli.Product2.Product_Type__c != null
                && MINUTE_BUNDLE_PRODUCT_TYPES.contains(
                    qli.Product2.Product_Type__c.left(qli.Product2.Product_Type__c.length() - 3)
                );
        }
    }

    public static String parseOldFormatGOA(QuoteLineItem item, BillingWrappers.QuotePackageInfo pInfo) {
        String goaGroup = '';
        Map<String, Map<String, Map<String, String>>> gInfo =
            (Map<String, Map<String, Map<String, String>>>)
                JSON.deserialize(
                    item.Product2.GOA_Group_V3__c,
                    Map<String, Map<String, Map<String, String>>>.class
                );
        String contractInfo = pInfo.contract != null ? 'contracted' : 'regular';
        if (gInfo.containsKey(contractInfo)) {
            if (gInfo.get(contractInfo).containsKey(pInfo.duration)) {
                String gCurrency = item.Discount_type__c == QuoteLineItemHelper.DISCOUNT_TYPE_PERCENTAGE
                    ? QuoteLineItemHelper.DISCOUNT_TYPE_PERCENTAGE
                    : item.CurrencyIsoCode;
                goaGroup = gInfo.get(contractInfo).get(pInfo.duration).get(gCurrency);
            }
        }
        return goaGroup;
    }

    public static String parseNewFormatGOA(QuoteLineItem item, BillingWrappers.QuotePackageInfo pInfo) {
        String goaGroup = '';

        Map<String, String> gInfo =
            (Map<String, String>)
                JSON.deserialize(
                    item.Product2.GOA_Group_V3__c,
                    Map<String, String>.class
                );
        String contractInfo = pInfo.contract != null ? 'contracted' : 'regular';
        if (gInfo.containsKey(contractInfo)) {
            goaGroup = gInfo.get(contractInfo);
        }
        return goaGroup;
    }

    public static Map<String, QuoteLineItem> buildElementIdToQliMap(List<QuoteLineItem> qlis) {
        Map<String, QuoteLineItem> result = new Map<String, QuoteLineItem>();

        for (QuoteLineItem qli: qlis) {
            result.put(qli.Product2.ExtID__c, qli);
        }

        return result;
    }

    public static Decimal getDLAmount(List<QuoteLineItem> qlis) {
        Decimal result = 0;

        for (QuoteLineItem qli: qlis) {
            if (String.isNotBlank(qli.PackageInfo__c)) {
                BillingWrappers.QLIPackageInfo packageInfoWrapper = (BillingWrappers.QLIPackageInfo)
                    JSON.deserialize(qli.PackageInfo__c, BillingWrappers.QLIPackageInfo.class);
                if (packageInfoWrapper.categoryPath == CATEGORY_DL) {
                    result += qli.NewQuantity__c;
                }
            }
        }

        return result;
    }

    public static Boolean isQLIApplicableForSyncWithNGBS(QuoteLineItem qli) {
        return qli != null
            && qli.Product2 != null
            && !qli.Deactivated__c
            && !qli.IsHiddenLicense__c
            && Product2Helper.isProductApplicableForSyncWithNGBS(qli.Product2)
            && !(qli.ChargeTerm__c == Product2Helper.CHARGE_TERM_ONE_TIME
                && qli.Zero_Quantity__c
                && qli.EffectivePriceNew__c == 0);
    }

    public static Boolean isUsageLicense(QuoteLineItem qli) {
        return qli != null && Product2Helper.isUsageLicense(qli.Product2);
    }

    public static Boolean isOnlyOneTime(List<QuoteLineItem> qlis) {
        Boolean result = true;
        for (QuoteLineItem qli : qlis) {
            if (!isOneTime(qli)) {
                result = false;
                break;
            }
        }
        return result;
    }

    public static String getCategoryPath(QuoteLineItem qli) {
        if (String.isBlank(qli.PackageInfo__c)) {
            return null;
        }

        BillingWrappers.QLIPackageInfo qliPackageInfo = new BillingWrappers.QLIPackageInfo(qli.PackageInfo__c);
        return qliPackageInfo?.categoryPath;
    }

    public static QuoteLineItem getPrimaryQuoteLineItem(Quote targetQuote) {
        if(targetQuote != null) {
            for (QuoteLineItem qli : targetQuote.QuoteLineItems) {
                if(Boolean.valueOf('' + BillingWrappers.parseQLIPackageInfo(qli.Package_Info__c).isCore)) {
                    return qli;
                }
            }
        }
        return new QuoteLineItem();
    }

    public static Decimal getOverallDiscount(List<QuoteLineItem> qliList) {
        Decimal summUnitPrice = 0;
        Decimal summEffectivePrice = 0;
        if (qliList == null || qliList.isEmpty()) {
            return 0;
        }
        for (QuoteLineItem qli : qliList) {
            if (qli.Promotion__c != null) {
                continue;
            }

            Decimal qliUnitPrice = qli.UnitPrice != null ? qli.UnitPrice : 0;
            summUnitPrice = summUnitPrice + qliUnitPrice;

            Decimal qliDiscount = qli.Discount == null ? 0 : qli.Discount;
            qliDiscount = qliDiscount / 100;

            Decimal effectivePrice = (qliUnitPrice * (1 - qliDiscount)); // (Subtotal - QLI.Discount)
            summEffectivePrice = summEffectivePrice + effectivePrice;
        }
        return summUnitPrice == 0 ? 0 : ((summUnitPrice - summEffectivePrice) / summUnitPrice) * 100;
    }

    public static List<QuoteLineItem> getQuoteLineItemsByQuoteId(
        Id quoteId
    ) {
        if (String.isEmpty(quoteId)) {
            return new List<QuoteLineItem>();
        }

        return new QuoteLineItemSelector()
            .selectQuoteLineItemsByQuoteIds(quoteId)
            .executeQuery();
    }

    public static List<QuoteLineItem> getQuoteLineItems(
        List<Id> qliIds
    ) {
        if (qliIds == null || qliIds.isEmpty()) {
            return new List<QuoteLineItem>();
        }

        return new QuoteLineItemSelector()
            .selectQuoteLineItemsByIds(qliIds)
            .executeQuery();
    }

    public static List<QuoteLineItem> getQuoteLineItems(
        Id quoteId,
        List<Id> qliIds
    ) {
        return new QuoteLineItemSelector()
            .selectQuoteLineItems(quoteId, qliIds)
            .executeQuery();
    }

    private static Set<String> QLI_UNIQUE_FIELDS = SObjectDescribeHelper.getDescribe(QuoteLineItem.getSObjectType()).getUniqueFieldNames();
    /**
     * Process cart items and return organized Map structure
     * Returns Map<CatalogId, QuoteLineItem>
     */
    public static Map<String, QuoteLineItem> processUpsertQuoteLineItemsAsMap(
        Id quoteId,
        BillingWrappers.CartItem[] cartItems,
        Map<String, BillingWrappers.CartItem> catalogIdToCartItem,
        List<PricebookEntry> pricebookEntries,
        List<QuoteLineItem> existingQuoteLineItems,
        List<Entitlement__c> entitlements,
        QuoteLineItem baseQuoteLineItem,
        Map<String, Product2> productMap
    ) {
        Map<String, PricebookEntry> catalogIdToPBE = new Map<String, PricebookEntry>();
        for(PricebookEntry pbe : pricebookEntries) {
            BillingWrappers.CartItem item = catalogIdToCartItem.get(pbe.Product2.ExtID__c);
            if( item.currencyIsoCode == pbe.CurrencyIsoCode ) {
                catalogIdToPBE.put(pbe.Product2.ExtID__c, pbe);
            }
        }

        Map<Id, Entitlement__c> productIdToEntitlement = new Map<Id, Entitlement__c>();
        for (Entitlement__c ent : entitlements) {
            productIdToEntitlement.put(ent.Product__c, ent);
        }

        Map<String, QuoteLineItem> catalogIdToExistingQli = new Map<String, QuoteLineItem>();
        for(QuoteLineItem existingQli : existingQuoteLineItems) {
            // Only include QLIs for the specific quote we're processing
            if (existingQli.QuoteId == quoteId) {
                String catalogId = existingQli.Product2.ExtID__c;
                catalogIdToExistingQli.put(catalogId, existingQli);
            }
        }

        BillingWrappers.CartItem dlUnlimited = getCartItemByCatalogId(cartItems, Product2Helper.DL_UNL_ELEMENT_ID);

        /* qli logic */
        Map<String, QuoteLineItem> catalogIdToQLI = new Map<String, QuoteLineItem>();

        for(BillingWrappers.CartItem cartItem : cartItems) {
            if(cartItem.isDeleted != null && cartItem.isDeleted) {
                continue;
            }

            PricebookEntry pricebookEntry = catalogIdToPBE.get(cartItem.catalogId);
            Entitlement__c entitlement = null;
            if(pricebookEntry != null) {
                entitlement = productIdToEntitlement.get(pricebookEntry.Product2Id);
            }
            QuoteLineItem existingQuoteLineItem = catalogIdToExistingQli.get(cartItem.catalogId);

            // Seldom case:
            // When Account in NGBS is POC/Trial and has OneTime items
            BillingWrappers.QLIPackageInfo packageInfo =  BillingWrappers.parseQLIPackageInfo(cartItem.packageInfo);
            String duration = packageInfo.duration == BillingWrappers.BILLING_CHARGE_TERM_ONE_TIME
                ? Product2Helper.CHARGE_TERM_ONE_TIME
                : packageInfo.duration;

            packageInfo.duration = duration;
            String packageInfoJson = JSON.serialize(packageInfo);

            String shortPackageInfo = BillingWrappers.getShortQLIPackageInfo(packageInfoJson);

            QuoteLineItem qli = existingQuoteLineItem != null
                ? new QuoteLineItem(Id = existingQuoteLineItem.Id)
                : baseQuoteLineItem.clone(false, false, false, false);

            Product2 prod = new Product2();

            if (pricebookEntry != null) {
                prod.Id = pricebookEntry.Product2Id;
                prod.ExtID__c = cartItem.catalogId;
            }

            if (qli.Id == null) {
                for (String field : QLI_UNIQUE_FIELDS) {
                    qli.put(field, null);
                }

                qli.QuoteId = quoteId;
                qli.Description = cartItem.name;
                qli.Item_type__c = cartItem.itemType;

                if (pricebookEntry != null) {
                    qli.PricebookEntryId = pricebookEntry.Id;
                    qli.Product2Id = pricebookEntry.Product2Id;
                    qli.putSObject('Product2', prod);
                }
            } else {
                setProductToMap(productMap, qli.Id, prod);
            }

            String discountType = existingQuoteLineItem != null && Product2Helper.isMobileUser(existingQuoteLineItem) && dlUnlimited != null
                ? dlUnlimited.discountType
                : cartItem.discountType;

            Decimal discountNumber = existingQuoteLineItem != null && Product2Helper.isMobileUser(existingQuoteLineItem) && dlUnlimited != null
                ? getMobileUserDiscountNumber(dlUnlimited, cartItem, discountType)
                : cartItem.discount;

            qli.Discount_number__c = discountNumber;
            qli.Discount_type__c = discountType;
            qli.Entitlement__c = entitlement != null ? entitlement.Id : null;
            qli.Quantity = cartItem.quantity == 0 ? 1 : cartItem.quantity;
            qli.Zero_Quantity__c = cartItem.quantity == 0;
            qli.UnitPrice = cartItem.unitPrice;
            qli.PackageInfo__c = packageInfoJson;
            qli.Package_Info_QLI__c = packageInfoJson;
            qli.Package_Info__c = shortPackageInfo;
            qli.PackageCatalogId__c = cartItem.billingPackage != null
                ? String.valueOf(cartItem.billingPackage.catalogId)
                : packageInfo != null
                    ? packageInfo.Id
                    : null;
            qli.PackageVersion__c = cartItem.billingPackage != null
                ? String.valueOf(cartItem.billingPackage.version)
                : packageInfo != null
                    ? packageInfo.Version
                    : null;
            qli.Display_Name__c = cartItem.displayName;
            qli.Sort_Order__c = cartItem.sortOrder;
            qli.Billing_Cycle_Duration__c = cartItem.billingCycleDuration;
            qli.SalesEndDate__c = cartItem.salesEndDate;
            qli.Promotion__c = cartItem.sfPromoCodeId;
            qli.ServiceName__c = cartItem.productName;

            // Add to Map structure - this preserves the catalog ID relationship
            catalogIdToQLI.put(cartItem.catalogId, qli);
        }

        appendParentQuoteLineItems(catalogIdToQLI.values(), existingQuoteLineItems);

        return catalogIdToQLI;
    }

    /**
     * Existing method - maintains backward compatibility by converting Map to List
     */
    public static List<QuoteLineItem> processUpsertQuoteLineItems(
        Id quoteId,
        BillingWrappers.CartItem[] cartItems,
        Map<String, BillingWrappers.CartItem> catalogIdToCartItem,
        List<PricebookEntry> pricebookEntries,
        List<QuoteLineItem> existingQuoteLineItems,
        List<Entitlement__c> entitlements,
        QuoteLineItem baseQuoteLineItem,
        Map<String, Product2> productMap
    ) {
        Map<String, QuoteLineItem> catalogIdToQLI = processUpsertQuoteLineItemsAsMap(
            quoteId,
            cartItems,
            catalogIdToCartItem,
            pricebookEntries,
            existingQuoteLineItems,
            entitlements,
            baseQuoteLineItem,
            productMap
        );

        return catalogIdToQLI.values();
    }

    public static List<QuoteLineItem> upsertQuoteLineItems(
        Id quoteId,
        BillingWrappers.CartItem[] items
    ) {
        List<QuoteLineItem> result = new List<QuoteLineItem>();
        Map<String,BillingWrappers.CartItem> catalogIdToCartItem = new Map<String,BillingWrappers.CartItem>();
        for(BillingWrappers.CartItem item : items) {
            catalogIdToCartItem.put(item.catalogId, item);
        }
        List<QuoteLineItem> qlis = new QuoteLineItemSelector()
            .selectQuoteLineItemsByQuoteIds(quoteId)
            .executeQuery();

        /* get entitlements for quote & create ents map */
        List<Entitlement__c> entls = new EntitlementSelector()
            .selectEntitlementForSyncQuoteLineItemsByQuoteId(quoteId)
            .executeQuery();

        List<PricebookEntry> pbeList = getPbeBasedOnCartItems(quoteId, catalogIdToCartItem);
        List<QuoteLineItem> qliToUpsert = processUpsertQuoteLineItems(
            quoteId,
            items,
            catalogIdToCartItem,
            pbeList,
            qlis,
            entls,
            new QuoteLineItem(),
            new Map<String, Product2>()
        );
        if (qliToUpsert.size() > 0) {
            upsert qliToUpsert;

            Set<Id> qliIds = new Set<Id>();
            for (QuoteLineItem qli : qliToUpsert) {
                qliIds.add(qli.Id);
            }

            result = getQuoteLineItems(new List<Id>(qliIds));
        }

        return result;
    }

    public static Map<String, List<QuoteLineItem>> upsertTechnicalQuoteLineItems(
        Id masterQuoteId,
        Map<String, BillingWrappers.CartItem[]> items
    ) {
        Quote masterQuote = (Quote) new QuoteSelector()
            .selectQuoteForCloning(new List<Object> { masterQuoteId })
            .executeQuery()
            .get(0);
        List<String> serviceNames = new List<String>(items.keySet());
        Map<String, Account> technicalAccounts = AccountHelper.getTechnicalAccountsByMasterId(masterQuote.AccountId);
        Map<String, Opportunity> technicalOpportunities = OpportunityHelper.getTechnicalOpportunitiesByMasterId(masterQuote.OpportunityId, technicalAccounts);
        Map<String, Quote> quotesByServicesMap = QuoteHelper.getTechnicalQuotesByMasterId(masterQuote.Id, serviceNames, technicalOpportunities);

        return upsertTechnicalQuoteLineItems(masterQuote, items, quotesByServicesMap);
    }

    public static Map<String, List<QuoteLineItem>> upsertTechnicalQuoteLineItemsUB(
        Id masterQuoteId,
        Map<String, BillingWrappers.CartItem[]> items
    ) {
        Quote masterQuote = (Quote) new QuoteSelector()
            .selectQuoteForCloning(new List<Object> { masterQuoteId })
            .executeQuery()
            .get(0);
        List<String> serviceNames = new List<String>(items.keySet());
        Map<String, Quote> quotesByServicesMap = QuoteHelper.getTechnicalQuotesByMasterIdUB(masterQuote.Id, serviceNames);

        return upsertTechnicalQuoteLineItems(masterQuote, items, quotesByServicesMap);
    }

    public static Map<String, List<QuoteLineItem>> upsertTechnicalQuoteLineItems(
        Quote masterQuote,
        Map<String, BillingWrappers.CartItem[]> cartItemsByServicesMap,
        Map<String, Quote> quotesByServicesMap
    ) {
        Map<String, List<QuoteLineItem>> result = new Map<String, List<QuoteLineItem>>();
        Map<String, Id> quoteIdsByServices = new Map<String, Id>();

        List<Id> quoteIds = (List<Id>) AquivaHelper.collectFieldValues(
            List<Id>.class,
            quotesByServicesMap.values(),
            'Id',
            true
        );

        List<Entitlement__c> entitlements = new EntitlementSelector()
            .selectEntitlementForSyncQuoteLineItemsByQuoteId(quoteIds)
            .executeQuery();

        List<QuoteLineItem> masterQlis = new QuoteLineItemSelector()
            .selectQuoteLineItemsByQuoteIds(masterQuote.Id)
            .executeQuery();
        Map<String, QuoteLineItem> masterQuoteLineItemsMap = getQuoteLineItemsByProductNames(masterQlis);

        entitlements = copyTechnicalEntitlementsFromMasterQli(quotesByServicesMap, masterQlis, entitlements);

        Map<Id, List<Entitlement__c>> entitlementsByQuoteIds = new Map<Id, List<Entitlement__c>>();
        for (Id id: quoteIds) {
            entitlementsByQuoteIds.put(id, new List<Entitlement__c>());
        }
        for (Entitlement__c entitlement : entitlements) {
            if (!entitlementsByQuoteIds.containsKey(entitlement.Quote__c)) {
                List<Entitlement__c> quoteEntitlements = entitlementsByQuoteIds.get(entitlement.Quote__c);

                quoteEntitlements.add(entitlement);

                entitlementsByQuoteIds.put(entitlement.Quote__c, quoteEntitlements);
            } else {
                entitlementsByQuoteIds.get(entitlement.Quote__c).add(entitlement);
            }
        }

        Map<String, BillingWrappers.CartItem> catalogIdToCartItem = new Map<String,BillingWrappers.CartItem>();
        for (String service: cartItemsByServicesMap.keySet()) {
            for (BillingWrappers.CartItem item: cartItemsByServicesMap.get(service)) {
                catalogIdToCartItem.put(item.catalogId, item);
            }
        }

        Map<Id, List<PricebookEntry>> pricebookEntriesByQuoteId = getPbeBasedOnCartItems(quoteIds, catalogIdToCartItem);
        List<QuoteLineItem> quoteLineItems = new QuoteLineItemSelector()
            .selectQuoteLineItemsByQuoteIdsForBilling(quoteIds)
            .executeQuery();
        Map<Id, List<QuoteLineItem>> existingQLIsByQuoteIds = new Map<Id, List<QuoteLineItem>>();
        for(QuoteLineItem qli: quoteLineItems) {
            if(!existingQLIsByQuoteIds.containsKey(qli.QuoteId)) {
                existingQLIsByQuoteIds.put(qli.QuoteId, new List<QuoteLineItem>{qli});
            } else {
                existingQLIsByQuoteIds.get(qli.QuoteId).add(qli);
            }
        }

        List<QuoteLineItem> itemsToUpsert = new List<QuoteLineItem>();
        QuoteLineItem technicalQli = new QuoteLineItem(IsMultiProductTechnicalQLI__c = true);
        for (String service: cartItemsByServicesMap.keySet()) {
            if (cartItemsByServicesMap.get(service) == null) {
                continue;
            }

            if (cartItemsByServicesMap.get(service).isEmpty()) {
                continue;
            }

            BillingWrappers.CartItem[] items = cartItemsByServicesMap.get(service);
            Quote quote = quotesByServicesMap.get(service);
            List<QuoteLineItem> currentQuoteItems = new List<QuoteLineItem>();

            if(existingQLIsByQuoteIds.containsKey(quote.Id)) {
                currentQuoteItems = existingQLIsByQuoteIds.get(quote.Id);
            }

            Map<String, Product2> productMap = new Map<String, Product2>();

            List<QuoteLineItem> technicalQuoteLineItems = processUpsertQuoteLineItems(
                quote.Id,
                items,
                catalogIdToCartItem,
                pricebookEntriesByQuoteId.get(quote.Id),
                currentQuoteItems,
                entitlementsByQuoteIds.get(quote.Id),
                technicalQli,
                productMap
            );

            for (QuoteLineItem techQli: technicalQuoteLineItems) {
                Product2 product = productMap.get(techQli.id);
                if (masterQuoteLineItemsMap.containsKey(techQli.Product2.ExtID__c)) {
                    techQli.MasterQLI__c = masterQuoteLineItemsMap.get(techQli.Product2.ExtID__c).Id;
                } else if  (product != null && masterQuoteLineItemsMap.containsKey(product.ExtID__c)) {
                    techQli.MasterQLI__c = masterQuoteLineItemsMap.get(product.ExtID__c).Id;
                }
            }

            itemsToUpsert.addAll(technicalQuoteLineItems);
            quoteIdsByServices.put(service, quote.Id);
        }

        if (itemsToUpsert.size() > 0) {
            upsert itemsToUpsert;

            Set<Id> quoteLineItemIds = new Set<Id>();
            for (QuoteLineItem qli: itemsToUpsert) {
                quoteLineItemIds.add(qli.Id);
            }

            List<QuoteLineItem> insertedQuoteLineItems = getQuoteLineItems(new List<Id>(quoteLineItemIds));

            for (String service: quotesByServicesMap.keySet()) {
                Quote quote = quotesByServicesMap.get(service);

                List<QuoteLineItem> technicalQuoteLineItems = new List<QuoteLineItem>();
                for (QuoteLineItem qli: insertedQuoteLineItems) {
                    if (quote.Id == qli.QuoteId) {
                        technicalQuoteLineItems.add(qli);
                    }
                }

                result.put(service, technicalQuoteLineItems);
            }
        }
        return result;
    }

    public static List<Entitlement__c> copyTechnicalEntitlementsFromMasterQli(Map<String, Quote> quotesByServicesMap , List<QuoteLineItem> masterQlis,  List<Entitlement__c> entitlements) {
        Map<String, Entitlement__c> technicalEntitlementsMap = getEntitlemetByProductNames(entitlements);
        List<Entitlement__c> entToInsert = new List<Entitlement__c>();
        for (Quote techQuote : quotesByServicesMap.values()) {
            for (QuoteLineItem masterQli: masterQlis) {
                if (masterQli.ServiceName__c == techQuote.ServiceName__c && !String.isBlank(masterQli.Entitlement__c) && !technicalEntitlementsMap.containsKey(masterQli.Product2.ExtID__c)) {
                    Entitlement__c techEntitlement = masterQli.Entitlement__r.clone(false, true, false, false);
                    techEntitlement.Quote__c = techQuote.Id;
                    techEntitlement.Account__c = techQuote.AccountId;
                    entitlements.add(techEntitlement);
                    entToInsert.add(techEntitlement);
                }
            }
        }
        if (entToInsert.size() > 0) {
            insert entToInsert;
        }

        return entitlements;
    }

    public static Map<String, Entitlement__c> getEntitlemetByProductNames(
        List<Entitlement__c> entitlements
    ) {
        Map<String, Entitlement__c> result = new Map<String, Entitlement__c>();

        if (entitlements == null || entitlements.isEmpty()) {
            return result;
        }

        for (Entitlement__c ent: entitlements) {
            result.put(ent.Product__r.ExtID__c, ent);
        }

        return result;
    }

    public static List<QuoteLineItem> deleteQuoteLineItems(
        Id quoteId,
        BillingWrappers.CartItem[] items
    ) {
        List<QuoteLineItem> existingQlis = new List<QuoteLineItem>();
        try {
            List<String> extIds = new List<String>();
            for(BillingWrappers.CartItem cartItem : items) {
                extIds.add(cartItem.catalogId);
            }

            // This line has to be deleted after E2E/UAT refresh
            fixArchiveProductForDeleteQLI(extIds);

            existingQlis = [
                SELECT Id, Quantity, Discount_number__c, Discount_type__c, Product2.ExtID__c
                FROM QuoteLineItem
                WHERE QuoteId =: quoteId
                AND Product2.ExtID__c IN :extIds
            ];

            if (existingQlis.size() > 0) {
                delete existingQlis;
            }
        } catch (Exception e) {
            AquivaHelper.throwAquivaException('Delete QLI: ' + e.getMessage(), e);
        }

        return existingQlis;
    }

    public static List<PricebookEntry> getPbeBasedOnCartItems(
        Id quoteId,
        Map<String,BillingWrappers.CartItem> catalogIdToCartItem
    ) {
        Quote currentQuote = (
            (List<Quote>) new QuoteSelector()
                .selectQuoteForQuotingToolItemsSync(quoteId)
                .executeQuery()
        ).get(0);

        return new PricebookEntrySelector()
            .getQuotingToolSyncPBEs(new List<Object>{
                new Set<Id> { currentQuote.Pricebook2Id },
                catalogIdToCartItem.keySet(),
                currencyList
            })
            .executeQuery();
    }

    public static Map<Id, List<PricebookEntry>> getPbeBasedOnCartItems(
        List<Id> quoteIds,
        Map<String, BillingWrappers.CartItem> catalogIdToCartItem
    ) {
        List<Quote> quotes = new QuoteSelector()
            .selectQuotesByIds(new List<Object> { quoteIds })
            .executeQuery();
        Set<Id> pricebookIds = new Set<Id>();

        for (Quote q: quotes) {
            pricebookIds.add(q.Pricebook2Id);
        }

        List<PricebookEntry> pbeList = new PricebookEntrySelector()
            .getQuotingToolSyncPBEs(new List<Object> {
                pricebookIds,
                catalogIdToCartItem.keySet(),
                currencyList
            })
            .executeQuery();

        Map<Id, List<PricebookEntry>> result = new Map<Id, List<PricebookEntry>>();
        for (Quote quote: quotes) {
            List<PricebookEntry> quotePbeList = new List<PricebookEntry>();
            for (PricebookEntry pbe: pbeList) {
                if (quote.Pricebook2Id == pbe.Pricebook2Id) {
                    quotePbeList.add(pbe);
                }
            }
            result.put(quote.Id, quotePbeList);
        }

        return result;
    }

    private static Decimal getMobileUserDiscountNumber(
        BillingWrappers.CartItem dlUnlimited,
        BillingWrappers.CartItem mobileUser,
        String discountType
    ) {
        if (discountType == QuoteLineItemHelper.DISCOUNT_TYPE_PERCENTAGE) {
            return dlUnlimited.discount;
        } else {
            BillingWrappers.QLIPackageInfo pInfo = BillingWrappers.parseQLIPackageInfo(dlUnlimited.packageInfo);
            return pInfo.duration == Product2Helper.CHARGE_TERM_MONTHLY
                ? dlUnlimited.discount
                : dlUnlimited.discount / 12;
        }
    }

    private static BillingWrappers.CartItem getCartItemByCatalogId(
        List<BillingWrappers.CartItem> cartItems,
        String catalogId
    ) {
        BillingWrappers.CartItem result;
        for (BillingWrappers.CartItem cartItem: cartItems) {
            if (cartItem.catalogId == catalogId) {
                result = cartItem;
            }
        }
        return result;
    }

    private static void fixArchiveProductForDeleteQLI(
        List<String> extIds
    ) {
        for (String extId : extIds) {
            if (extId == 'LC_SH_86') {
                extIds.add('LC_SH_86_temp');
                extIds.remove(extIds.indexOf(extId));
            }
        }
    }

    private static void setProductToMap(Map<String, Product2> productMap, String qliId, Product2 prod) {
        productMap.put(qliId, prod);
    }

    public static Map<String, QuoteLineItem> getQuoteLineItemsByProductNames(
        List<QuoteLineItem> items
    ) {
        Map<String, QuoteLineItem> result = new Map<String, QuoteLineItem>();

        if (items == null || items.isEmpty()) {
            return result;
        }

        for (QuoteLineItem qli: items) {
            result.put(qli.Product2.ExtID__c, qli);
        }

        return result;
    }

    public static List<QuoteLineItem> copyQuoteLineItemsToMasterQuote(
        Id masterQuoteId
    ) {
        return copyQuoteLineItemsToMasterQuote(masterQuoteId, new List<String>());
    }

    public static List<QuoteLineItem> copyQuoteLineItemsToMasterQuote(
        Id masterQuoteId, List<String> services
    ) {
        List<Quote> technicalQuotes = new QuoteSelector()
            .selectServiceQuotesForMasterQuote(masterQuoteId, services)
            .executeQuery();

        List<Id> technicalQuoteIds = (List<Id>) AquivaHelper.collectFieldValues(List<Id>.class, technicalQuotes, 'Id', true);

        List<QuoteLineItem> technicalQuoteLineItems = new QuoteLineItemSelector()
            .selectQuoteLineItemsByQuoteIdsForCloning(technicalQuoteIds)
            .executeQuery();
        Map<String, QuoteLineItem> technicalQuoteLineItemsMap = getQuoteLineItemsByProductNames(technicalQuoteLineItems);

        List<QuoteLineItem> masterQuoteLineItems = new QuoteLineItemSelector()
            .selectQuoteLineItemsByQuoteIdsForCloning(masterQuoteId)
            .executeQuery();
        Map<String, QuoteLineItem> masterQuoteLineItemsMap = getQuoteLineItemsByProductNames(masterQuoteLineItems);

        List<QuoteLineItem> itemsToCreate = new List<QuoteLineItem>();
        for (QuoteLineItem qli: technicalQuoteLineItems) {
            if (!masterQuoteLineItemsMap.containsKey(qli.Product2.ExtID__c)) {
                QuoteLineItem clonedItem = qli.clone(false, true, false, false);

                clonedItem.QuoteId = masterQuoteId;
                clonedItem.IsMultiProductTechnicalQLI__c = false;
                clonedItem.MasterQLI__c = null;

                itemsToCreate.add(clonedItem);
            }
        }

        if (!itemsToCreate.isEmpty()) {
            System.debug(itemsToCreate.size());
            System.debug(itemsToCreate);
            insert itemsToCreate;
        }

        List<QuoteLineItem> itemsToUpdate = new List<QuoteLineItem>();
        List<QuoteLineItem> itemsToDelete = new List<QuoteLineItem>();

        masterQuoteLineItems = new QuoteLineItemSelector()
            .selectQuoteLineItemsByQuoteIdsForCloning(masterQuoteId)
            .executeQuery();

        for (QuoteLineItem qli: masterQuoteLineItems) {
            if (technicalQuoteLineItemsMap.containsKey(qli.Product2.ExtID__c)) {
                QuoteLineItem serviceItem = technicalQuoteLineItemsMap.get(qli.Product2.ExtID__c);
                QuoteLineItem clonedItem = serviceItem
                    .clone(false, true, false, false);

                clonedItem.Id = qli.Id;
                clonedItem.Quote = qli.Quote;
                clonedItem.IsMultiProductTechnicalQLI__c = false;
                clonedItem.MasterQLI__c = null;

                itemsToUpdate.add(clonedItem);

                serviceItem.MasterQLI__c = qli.Id;
                serviceItem.IsMultiProductTechnicalQLI__c = true;

                itemsToUpdate.add(serviceItem);
            } else {
                itemsToDelete.add(qli);
            }
        }

        if (!itemsToUpdate.isEmpty()) {
            System.debug(itemsToUpdate.size());
            System.debug(itemsToUpdate);
            update itemsToUpdate;
        }

        if (!itemsToDelete.isEmpty()) {
            System.debug(itemsToDelete.size());
            System.debug(itemsToDelete);
            delete itemsToDelete;
        }

        return new QuoteLineItemSelector()
            .selectQuoteLineItemsByQuoteIdsForBilling(masterQuoteId)
            .executeQuery();
    }

    public static Decimal getDeltaRecurringRevenue(QuoteLineItem qli) {
        return getChargeTerm(qli) == Product2Helper.CHARGE_TERM_ANNUAL
            ? qli?.Delta_ARR__c
            : qli?.Delta_MRR__c;
    }

    private static Set<String> getParentCategoryPaths(QuoteLineItem qli) {
        Set<String> result = new Set<String>();
        for (PdfHierarchySettings__mdt setting : hierarchySettings) {
            if (setting.Childs__c.split(',').contains(QuoteLineItemHelper.getCategoryPath(qli))
                    && setting.Parent__c != getCategoryPath(qli)) { // qli itself should not be parent
                result.add(setting.Parent__c);
            }
        }
        return result;
    }

    public static void appendParentQuoteLineItems(List<QuoteLineItem> inputQlis, List<QuoteLineItem> qlisToSearch) {

        Set<String> parentCategoryPaths = new Set<String>();
        List<Id> qliIds = new List<Id>();
        for (QuoteLineItem qli : inputQlis) {
            if (qli.Id != null) {
                qliIds.add(qli.Id);
            }
            parentCategoryPaths.addAll(getParentCategoryPaths(qli));
        }

        for (QuoteLineItem qli : qlisToSearch) {
            if (parentCategoryPaths.contains(getCategoryPath(qli)) && !qliIds.contains(qli.Id)) {
                inputQlis.add(qli);
            }
        }
    }

    public static Boolean isSeatQli(QuoteLineItem qli) {
        return mainLicenseIds.contains(qli.Product_Lic_Id__c);
    }

    public static Boolean isChangePackageFromCCLegacyToStandalone(List<QuoteLineItem> qlis) {
        Quote quote = qlis.get(0).Quote;
        if (String.isBlank(quote.Package_Info__c)) {
            return false;
        }

        List<BillingWrappers.QuotePackageInfo> pInfos = new BillingWrappers.QuotePackageInfoWrapper().parseQuotePackageInfo(quote.Package_Info__c);
        for (BillingWrappers.QuotePackageInfo pInfo : pInfos) {
            if (QuoteHelper.NGBS_RCCC_PRODUCT.equalsIgnoreCase(pInfo.productName)
                && pInfo.existingPackageInfo != null
                && QuoteLineItemHelper.CC_LEGACY_PACKAGE_IDS.contains(pInfo.existingPackageInfo.id)
                && pInfo.packageInfo.displayName != pInfo.packageInfo.oldPackageName
            ) {
                return true;
            }
        }
        return false;
    }

    public static Boolean isProductReachedSalesEndDate(QuoteLineItem qli) {
        return qli.SalesEndDate__c != null && qli.SalesEndDate__c <= System.now();
    }

    public static void cropQuoteLineItems(Id masterQuoteId, Set<String> catalogIds, Boolean isProServChangeOrderOpp) {
        if (masterQuoteId == null) {
            return;
        }

        List<QuoteLineItem> qlisToDelete = new List<QuoteLineItem>();
        List<Quote> quotes = (List<Quote>) new QuoteSelector()
            .selectQuotesByMasterQuoteIdToCropQLIs(new Set<Id>{ masterQuoteId })
            .executeQuery();
        for (Quote qt : quotes) {
            for (QuoteLineItem qli : qt.QuoteLineItems) {
                if (!catalogIds.contains(qli.Product_Lic_Id__c)) {
                    qlisToDelete.add(qli);
                }
            }
        }

        if (qlisToDelete.size() > 0) {
            if (isProServChangeOrderOpp) {
                EntitlementHelper.deleteEntitlementsByQuoteLineItems(masterQuoteId, qlisToDelete);
            }
            delete qlisToDelete;
        }
    }

    // Iterate overall QuoteLineItems and map it to appropriate Provisioning By Product2.UpsellType__c or Product2.InitialOrderType__c
    public static Map<String, List<QuoteLineItem>> getProvisioningToQLIListMap(List<QuoteLineItem> qliList, Boolean isNewService) {
        Map<String, List<QuoteLineItem>> provisioningToQLIListMap = new Map<String, List<QuoteLineItem>>();

        if (qliList == null) {
            return provisioningToQLIListMap;
        }

        Map<String, Set<String>> provisioningToProductOrderTypes = isNewService
            ? OrderHelper.PROVISIONING_TO_PRODUCT2_INITIAL_ORDER_TYPES
            : OrderHelper.PROVISIONING_TO_PRODUCT2_UPSELL_TYPES;

        Set<String> allMappedOrderTypes = new Set<String>();
        for (Set<String> mappedOrderTypes : provisioningToProductOrderTypes.values()) {
            allMappedOrderTypes.addAll(mappedOrderTypes);
        }

        for (String provisioning :  provisioningToProductOrderTypes.keySet()) {
            provisioningToQLIListMap.put(provisioning, new List<QuoteLineItem>());

            for (QuoteLineItem qli : qliList) {
                String productOrderType = isNewService
                    ? qli.Product2.InitialOrderType__c
                    : qli.Product2.UpsellType__c;

                if (provisioningToProductOrderTypes.get(provisioning).contains(productOrderType)) {
                    provisioningToQLIListMap.get(provisioning).add(qli);

                    // for the case if current productOrderType is not included to the provisioningToProductOrderTypes map
                } else if (!allMappedOrderTypes.contains(productOrderType) && provisioning == OrderHelper.PROVISIONING_MANUAL) {
                    provisioningToQLIListMap.get(provisioning).add(qli);
                }
            }
        }

        return provisioningToQLIListMap;
    }

    public static List<String> getLicensesForPurchaseBypass(String oppBi) {
        List<String> result = new List<String>();

        String biId = String.isNotBlank(oppBi)
            ? ((BillingWrappers.QuoteBusinessIdentity) JSON.deserialize(oppBi, BillingWrappers.QuoteBusinessIdentity.class))?.biId
            : null;

        for(NGBSPurchaseSettingsByBI__c config : NGBSPurchaseSettingsByBI__c.getAll().values()) {
            if (biId == config?.biId__c && String.isNotBlank(config?.LicensesForPurchase__c)) {
                result.addAll(config?.LicensesForPurchase__c.split(';'));
            }
        }
        return result;
    }

    public static Boolean isProfessionalServiceQli(QuoteLineItem qli) {
        return qli.ServiceName__c == SUBCATEGORY_PROSERV ||
        (
            qli.Product2 != null &&
            qli.Product2.GOA_Group_V3__c != null &&
            qli.Product2.GOA_Group_V3__c.containsIgnoreCase('ProServ_Directs') &&
            qli.Product2.group__c != null &&
            qli.Product2.group__c.containsIgnoreCase('Professional Services')
        );
    }

    public static Boolean isEventsQli(QuoteLineItem qli) {
        return qli.ServiceName__c == SUBCATEGORY_EVENTS;
    }

    public static Boolean isOfficeQli(QuoteLineItem qli) {
        return qli.ServiceName__c == Product2Helper.PRODUCT_OFFICE;
    }

    public static Map<String, QuoteLineItem> getProductLicIdToQliMap(Id quoteId) {
        Map<String, QuoteLineItem> productLicIdToQliMap = new Map<String, QuoteLineItem>();
        List<QuoteLineItem> qlis = (List<QuoteLineItem>) new QuoteLineItemSelector()
            .selectQuoteLineItemsByQuoteIds(quoteId)
            .executeQuery();

        for (QuoteLineItem qli : qlis) {
            productLicIdToQliMap.put(qli.Product_Lic_Id__c, qli);
        }

        return productLicIdToQliMap;
    }

    public static List<QuoteLineItem> getTaxesAndFeesTable(List<QuoteLineItem> dataList) {
        List<QuoteLineItem> result = new List<QuoteLineItem>();
        List<QuoteLineItem> serviceFees = new List<QuoteLineItem>();
        List<QuoteLineItem> complianceFees = new List<QuoteLineItem>();

        for (QuoteLineItem qli : dataList) {
            if (qli.Product2.ExtID__c.containsIgnoreCase('LC_E911')) {
                serviceFees.add(qli);
            } else if (qli.Product2.ExtID__c.containsIgnoreCase('LC_CRF')) {
                complianceFees.add(qli);
            } else {
                result.add(qli);
            }
        }

        result.addAll(combineQuoteLineItemsByPrice(serviceFees));
        result.addAll(combineQuoteLineItemsByPrice(complianceFees));

        return result;
    }

    public static List<QuoteLineItem> combineQuoteLineItemsByPrice(List<QuoteLineItem> quoteLineItems) {
        if (quoteLineItems == null || quoteLineItems.isEmpty()) {
            return new List<QuoteLineItem>();
        }
        Map<Decimal, QuoteLineItem> priceToQuoteLineItemMap = new Map<Decimal, QuoteLineItem>();

        for (QuoteLineItem qli : quoteLineItems) {
            if (priceToQuoteLineItemMap.containsKey(qli.EffectivePriceNew__c)) {
                QuoteLineItem existingQli = priceToQuoteLineItemMap.get(qli.EffectivePriceNew__c);
                existingQli.NewQuantity__c += qli.NewQuantity__c;
                existingQli.Display_Name__c = qli.Display_Name__c.replace('*', '');
            } else {
                priceToQuoteLineItemMap.put(qli.EffectivePriceNew__c, qli.clone(false, true, true, true));
            }
        }

        return new List<QuoteLineItem>(priceToQuoteLineItemMap.values());
    }
}