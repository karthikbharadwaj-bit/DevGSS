public with sharing class EntitlementsViewHelper {
    public static final String FAIL_MESSAGE = 'Failed to get billing info: ';

    public class AccountSummaryResponse {
        @AuraEnabled public List<PackageInfo> packages { get; set; }
    }

    public class PackageInfo {
        @AuraEnabled public String id { get; set; }
        @AuraEnabled public String description { get; set; }
        @AuraEnabled public String name { get; set; }
        @AuraEnabled public String billingId { get; set; }
        @AuraEnabled public String currencyCode { get; set; }
    }

    public class BillingInfoSummaryLicenseResponse {
        public String catalogId;
        public String billingCycleDuration;
        public Double price;
        public Double discountAmount;
        public DiscountValue discountValue;
        public Integer qty;
        public String dateRangeStart;
        public String dateRangeEnd;
        public String description;
        public Boolean scheduledForRemoval;
    }

    public class GroupedLicense {
        public String catalogId;
        public String billingCycleDuration;
        public Double price;
        public Double discountAmount;
        public DiscountValue discountValue;
        public Integer qty;
        public String dateRangeStart;
        public String dateRangeEnd;
        public String description;
        public Boolean scheduledForRemoval;
        public Boolean isGrouped;
        public List<GroupedLicense> childLicenses;
        public String packageId;

        public GroupedLicense() {
            this.childLicenses = new List<GroupedLicense>();
            this.isGrouped = false;
        }
    }

    public class BillingInfoRequestBody {
        public Fields fields;

        public BillingInfoRequestBody() {
            this.fields = new Fields();
        }
    }

    public class Fields {
        public Boolean scheduledForRemoval = true;
        public Boolean price = true;
        public Boolean dateRange = true;
        public List<String> discountValue = new List<String>{'Unit', 'Value'};
    }

    public class DiscountValue {
        public String unit;
        public String value;

        public DiscountValue(String unit, String value) {
            this.unit = unit;
            this.value = value;
        }
    }

    public static List<BillingInfoSummaryLicenseResponse> getBillingInfoSummaryLicenses(String billingId, String packageId) {
        String endpoint = String.format(
            NGBSAPI.NGBS_BILLING_INFO_SUMMARY_LICENSE,
            new List<String>{billingId, packageId}
        );

        BillingInfoRequestBody requestBody = new BillingInfoRequestBody();
        String requestBodyJson = JSON.serialize(requestBody);
        HttpResponse response = NGBSAPI.requestNGBS(endpoint,  HttpHelper.METHOD_POST, requestBodyJson);

        if (response.getStatusCode() != 200) {
            throw new NGBSAPI.NGBSAPIException(FAIL_MESSAGE + response.getStatus());
        }

        return (List<BillingInfoSummaryLicenseResponse>) JSON.deserialize(
            response.getBody(),
            List<BillingInfoSummaryLicenseResponse>.class
        );
    }

    // when packageLicenses.size() == 1
    private static GroupedLicense convertToGroupedLicense(BillingInfoSummaryLicenseResponse license) {
        GroupedLicense groupedLicense = new GroupedLicense();
        groupedLicense.billingCycleDuration = license.billingCycleDuration;
        groupedLicense.price = license.price;
        groupedLicense.discountAmount = license.discountAmount;
        groupedLicense.discountValue = license.discountValue;
        groupedLicense.qty = license.qty;
        groupedLicense.dateRangeStart = license.dateRangeStart;
        groupedLicense.dateRangeEnd = license.dateRangeEnd;
        groupedLicense.description = license.description;
        groupedLicense.isGrouped = false;

        return groupedLicense;
    }

    // when packageLicenses.size() > 1
    private static GroupedLicense createGroupedLicense(List<BillingInfoSummaryLicenseResponse> licenses) {
        GroupedLicense groupedLicense = new GroupedLicense();
        BillingInfoSummaryLicenseResponse firstLicense = licenses[0];

        // Set common fields
        groupedLicense.catalogId = firstLicense.catalogId;
        groupedLicense.description = firstLicense.description;
        groupedLicense.isGrouped = true;

        // Check if all values are the same for each field
        groupedLicense.billingCycleDuration = getCommonValue(licenses, 'billingCycleDuration');
        groupedLicense.price = getCommonDoubleValue(licenses, 'price');
        groupedLicense.discountAmount = getCommonDoubleValue(licenses, 'discountAmount');
        groupedLicense.discountValue = getCommonDiscountValue(licenses, groupedLicense.discountAmount);
        groupedLicense.qty = getCommonIntegerValue(licenses, 'qty');
        groupedLicense.dateRangeStart = getCommonValue(licenses, 'dateRangeStart');
        groupedLicense.dateRangeEnd = getCommonValue(licenses, 'dateRangeEnd');
        groupedLicense.scheduledForRemoval = getCommonBooleanValue(licenses, 'scheduledForRemoval');

        // Add all child licenses
        List <GroupedLicense> childLicensesList = new List<GroupedLicense>();
        for (BillingInfoSummaryLicenseResponse license : licenses) {
            childLicensesList.add(convertToGroupedLicense(license));
        }
        groupedLicense.childLicenses.addAll(childLicensesList);

        return groupedLicense;
    }

    private static DiscountValue getCommonDiscountValue(List<BillingInfoSummaryLicenseResponse> licenses, Double discountAmount) {
        if (discountAmount == 0) {
            return new DiscountValue(null, '0');
        }

        String commonUnit;
        String commonValue;

        for (BillingInfoSummaryLicenseResponse license : licenses) {
            if (license.discountValue == null) {
               continue;
            }

            if (commonUnit == null && commonValue == null) {
                commonUnit = getFieldValue(license, 'unit');
                commonValue = getFieldValue(license, 'value');
            } else if (getFieldValue(license, 'unit') != commonUnit
                || getFieldValue(license, 'value') != commonValue) {
                return null;
            }
        }

        return (commonUnit == null && commonValue == null)
            ? new DiscountValue(null, '0')
            : new DiscountValue(commonUnit, commonValue);
    }

    private static String getCommonValue(List<BillingInfoSummaryLicenseResponse> licenses, String fieldName) {
        String firstValue = getFieldValue(licenses[0], fieldName);
        for (BillingInfoSummaryLicenseResponse license : licenses) {
            if (getFieldValue(license, fieldName) != firstValue) {
                return null;
            }
        }
        return firstValue;
    }

    private static Double getCommonDoubleValue(List<BillingInfoSummaryLicenseResponse> licenses, String fieldName) {
        Double firstValue = getDoubleFieldValue(licenses[0], fieldName);
        for (BillingInfoSummaryLicenseResponse license : licenses) {
            if (getDoubleFieldValue(license, fieldName) != firstValue) {
                return null;
            }
        }
        return firstValue;
    }

    private static Integer getCommonIntegerValue(List<BillingInfoSummaryLicenseResponse> licenses, String fieldName) {
        Integer firstValue = getIntegerFieldValue(licenses[0], fieldName);
        for (BillingInfoSummaryLicenseResponse license : licenses) {
            if (getIntegerFieldValue(license, fieldName) != firstValue) {
                return null;
            }
        }
        return firstValue;
    }

    private static Boolean getCommonBooleanValue(List<BillingInfoSummaryLicenseResponse> licenses, String fieldName) {
        Boolean firstValue = getBooleanFieldValue(licenses[0], fieldName);
        for (BillingInfoSummaryLicenseResponse license : licenses) {
            if (getBooleanFieldValue(license, fieldName) != firstValue) {
                return null;
            }
        }
        return firstValue;
    }

    private static String getFieldValue(BillingInfoSummaryLicenseResponse license, String fieldName) {
        switch on fieldName {
            when 'billingCycleDuration' { return license.billingCycleDuration; }
            when 'dateRangeStart' { return license.dateRangeStart; }
            when 'dateRangeEnd' { return license.dateRangeEnd; }
            when 'unit' { return license.discountValue?.unit; }
            when 'value' { return license.discountValue?.value; }
            when else { return null; }
        }
    }

    private static Double getDoubleFieldValue(BillingInfoSummaryLicenseResponse license, String fieldName) {
        switch on fieldName {
            when 'price' { return license.price; }
            when 'discountAmount' { return license.discountAmount; }
            when else { return null; }
        }
    }

    private static Integer getIntegerFieldValue(BillingInfoSummaryLicenseResponse license, String fieldName) {
        switch on fieldName {
            when 'qty' { return license.qty; }
            when else { return null; }
        }
    }

    private static Boolean getBooleanFieldValue(BillingInfoSummaryLicenseResponse license, String fieldName) {
        switch on fieldName {
            when 'scheduledForRemoval' { return license.scheduledForRemoval; }
            when else { return null; }
        }
    }

    public static List<GroupedLicense> getBillingInfoForPackage(String billingId, String packageId) {
        List<GroupedLicense> result = new List<GroupedLicense>();

        try {
            List<BillingInfoSummaryLicenseResponse> licenses = getBillingInfoSummaryLicenses(billingId, packageId);
            Map<String, List<BillingInfoSummaryLicenseResponse>> licenseMap = new Map<String, List<BillingInfoSummaryLicenseResponse>>();

            for (BillingInfoSummaryLicenseResponse license : licenses) {
                if (BooleanHelper.toBoolean(license.scheduledForRemoval)) {
                    continue;
                }
                if (!licenseMap.containsKey(license.catalogId)) {
                    licenseMap.put(license.catalogId, new List<BillingInfoSummaryLicenseResponse>());
                }
                licenseMap.get(license.catalogId).add(license);
            }

            for (String catalogId : licenseMap.keySet()) {
                List<BillingInfoSummaryLicenseResponse> packageLicenses = licenseMap.get(catalogId);

                if (packageLicenses.size() == 1) {
                    GroupedLicense groupedLicense = convertToGroupedLicense(packageLicenses[0]);
                    groupedLicense.packageId = packageId;
                    result.add(groupedLicense);
                } else {
                    GroupedLicense groupedLicense = createGroupedLicense(packageLicenses);
                    groupedLicense.packageId = packageId;
                    result.add(groupedLicense);
                }
            }

        } catch (Exception e) {
            AquivaHelper.throwAuraException('Error retrieving billing information for package: ' + e.getMessage());
        }

        return result;
    }
}