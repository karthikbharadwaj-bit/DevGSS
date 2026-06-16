public class Pricebook2Helper {

    // Service__c
    public final static String SERVICE_OFFICE = 'Office';
    public final static String SERVICE_CONTACT_CENTER = 'Contact Center';
    public final static String SERVICE_PRO = 'professional';
    public final static String SERVICE_PROSERV = 'ProServ';
    public final static String SERVICE_FAX = 'fax';

    // Plan__c
    public final static String PLAN_MONTHLY = 'Monthly';
    public final static String PLAN_MONTHLY_CONTRACT = 'Monthly - Contract';
    public final static String PLAN_ANNUAL = 'Annual';

    //AllowedRecordType__c
    public final static String ALLOWED_RECORD_TYPE_SERVICE_BILLING_PROSERV = 'Service Billing ProServ';
    // Edition__C
    public final static String EDITION_GOOGLE_APPS_EDITION = 'google apps';
    public final static String EDITION_STANDARD = 'Standard';

    // PriceBook.Brand.Name
    public final static String BRAND_RINGCENTRAL = 'ringcentral';
    public final static String BRAND_RINGCENTRAL_CANADA = 'ringcentral canada';

    public static Pricebook2 standardPricebook {
        get {
            if (standardPricebook == null) {
                standardPricebook = (Pricebook2) new Pricebook2Selector()
                    .getStandardPricebook()
                    .executeQuery()
                    .get(0);
            }
            return standardPricebook;
        }
    }
    public static Id getStandardPricebookId() {
        if (Test.isRunningTest()) {
            return Test.getStandardPricebookId();
        }
        return standardPricebook.Id;
    }

    public static Boolean isFaxService(String service) {
        return service != null && service.toLowerCase() == SERVICE_FAX;
    }

    public static Boolean isProfessionalService(String service) {
        return service != null && service.toLowerCase() == SERVICE_PRO;
    }

    public static Boolean isGoogleAppsEdition(String edition) {
        return edition != null && edition.toLowerCase() == EDITION_GOOGLE_APPS_EDITION;
    }

    public static Boolean isRingCentralBrandName(String brand) {
        return brand != null && brand.toLowerCase() == BRAND_RINGCENTRAL;
    }

    public static Boolean isRingCentralCanadaBrand(String brand) {
        return brand != null && brand.toLowerCase() == BRAND_RINGCENTRAL_CANADA;
    }

    public enum PROSERV_TYPE {
        CC_PROSERV,
        PROSERV
    }

    public static Id findUniversalPricebookId(String brand, String subBrand, String isoCode, PROSERV_TYPE proServType) {

        List<Pricebook2> result = new List<Pricebook2>();

        Map<String, String> brandsToPricebookIdMap = new Map<String, String>();

        for (PriceBookAssignments__c assignmentsSetting : PriceBookAssignments__c.getAll().values()) {
            if (assignmentsSetting.Active__c == false) {
                continue;
            }
            String brandSubBrandKey = assignmentsSetting.BrandName__c + assignmentsSetting.SubBrandName__c;
            String priceBookExtId = proServType == PROSERV_TYPE.CC_PROSERV
                ? assignmentsSetting.CCPSPriceBookExtID__c
                : assignmentsSetting.PSPriceBookExtID__c;

            if (!String.isBlank(priceBookExtId)) {
                brandsToPricebookIdMap.put(brandSubBrandkey, priceBookExtId);
            }
        }

        String oppBrandSubBrand = brand + subBrand;
        String oppBrandEmptySubBrand = brand + null;

        String pricebook2ExtId;
        if (brandsToPricebookIdMap.containsKey(oppBrandSubBrand)) {
            pricebook2ExtId = brandsToPricebookIdMap.get(oppBrandSubBrand);
        } else if (brandsToPricebookIdMap.containsKey(oppBrandEmptySubBrand)) {
            pricebook2ExtId = brandsToPricebookIdMap.get(oppBrandEmptySubBrand);
        }

        if (!String.isBlank(pricebook2ExtId)) {
            PriceBook2 priceBook = (PriceBook2) new Pricebook2Selector().selectPricebooks()
                .setCondition('ExtID__c = :bind0')
                .setQueryBindings(new List<Object>{pricebook2ExtId})
                .executeQuery()
                .get(0);

            result.add(priceBook);
        } else {
            Pricebook2Selector pbSelector = new Pricebook2Selector();
            List<Pricebook2> defaultPriceBooks = proServType == PROSERV_TYPE.CC_PROSERV
                ? (List<Pricebook2>) pbSelector.selectUniversalCCProservPricebook(isoCode).executeQuery()
                : (List<Pricebook2>) pbSelector.selectUniversalProservPricebook(isoCode).executeQuery();
            result = defaultPriceBooks;
        }

        if (result.size() == 0) {
            String errorMessage = proServType == PROSERV_TYPE.CC_PROSERV
                ? 'Not found: Service Billing CC ProServ Pricebook'
                : 'Not found: Service Billing ProServ Pricebook';
            throw new AquivaHelper.AquivaException(errorMessage);
        } else if (result.size() > 1) {
            String errorMessage = proServType == PROSERV_TYPE.CC_PROSERV
                ? 'Incorrect CC ProServ Pricebook configuration. Please, contact system administrator.'
                : 'Incorrect ProServ Pricebook configuration. Please, contact system administrator.';
            throw new AquivaHelper.AquivaException(errorMessage);
        }

        return result.get(0).Id;
    }
}