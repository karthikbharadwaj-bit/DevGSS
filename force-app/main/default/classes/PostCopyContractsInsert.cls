public with sharing class PostCopyContractsInsert extends PostCopyWorker {
    public static final String NAME_MEETINGS_CONTRACT = 'Meetings Contract';
    public static final String NAME_OFFICE_CONTRACT = 'Office Contract';
    public static final String NAME_EV_STANDALONE_CONTRACT = 'EV Standalone Contract';
    public static final String NAME_EVENTS_CONTRACT = 'Events Contract'; 
    public static final String NAME_EV_LEGACY_CONTRACT = 'EV Legacy Contract';
    public static final String NAME_ED_STANDALONE_CONTRACT = 'ED Standalone Contract';
    public static final String NAME_ED_LEGACY_CONTRACT = 'ED Legacy Contract';
    public static final String NAME_EO_CONTRACT = 'EO Contract';
    public static final String NAME_FEDRAMP_CONTRACT = 'Office FedRamp Contract';
    public static final String NAME_OFFICE_CONTRACT_SINGAPORE = 'Office Contract Singapore';
    public static final String NAME_OFFICE_INDIA_CONTRACT = 'Office India Contract';
    public static final String NAME_RCCC_CONTRACT = 'RCCC Contract';
    public static final String NAME_UO_VIDEO_CONRACT = 'Unify Office Video Contract';
    public static final String NAME_OFFICE_EDUCATION_CONTRACT = 'Office Education Contract';
    public static final String NAME_OFFICE_TAIWAN_CONTRACT = 'Office Taiwan Contract';
    public static final String NAME_PROSERV_CONTRACT = 'ProServ Contract';

    public static final String PACKAGES_OFFICE_US = '5,18,19,20,21,22,23,24,25,26,27,28,29,30,1950,1952,1953,1955,1956,1957,1958';
    public static final String PACKAGES_OFFICE_CA = '40,41,42,35,38,39,43,44,45,48,49,50,1961,1962,1959,1964,1965,1966,1967';
    public static final String PACKAGES_OFFICE_AU = '70,71,72,73,74,78,211,214,217,1982,1983,1985,1987,1984,1986,1988';
    public static final String PACKAGES_OFFICE_EU = '57,58,59,61,62,63,65,68,75,195,196,197,1850,1851,1852,1975,1976,1977,1978,1979,1980,1981';
    public static final String PACKAGES_OFFICE_UK = '80,81,82,84,85,89,92,93,95,97,98,99,1968,1969,1970,1971,1972,1973,1974';
    public static final String PACKAGES_OFFICE_5_US = '1231005,1232005,1233005,1465005,1466005,1467005';
    public static final String PACKAGES_OFFICE_5_CA = '1300005,1301005,1302005';
    public static final String PACKAGES_OFFICE_AVAYA_5_US = '1423005,1427005,1428005';
    public static final String PACKAGES_OFFICE_AVAYA_5_CA = '1429005,1430005,1431005';
    public static final String PACKAGES_OFFICE_10_US = '1126005, 1127005, 1128005, 1129005';
    public static final String PACKAGES_OFFICE_US_OLD = '5,18,19,20,21,22,23,24,25,26,27,28,29,30,1127005';
    public static final String PACKAGES_OFFICE_CA_OLD = '35,38,39,40,41,42,43,44,45,48,49,50';
    public static final String PACKAGES_OFFICE_AU_OLD = '70,71,72,73,74,78';
    public static final String PACKAGES_OFFICE_AVAYA = '318,324,328,320';
    public static final String PACKAGES_OFFICE_AVAYA_CA = '340,338,344,348';
    public static final String PACKAGES_OFFICE_AVAYA_AU = '370,373,374,378,345,346,347';
    public static final String PACKAGES_OFFICE_AVAYA_UK = '380,385,393,398,313,314,315';
    public static final String PACKAGES_OFFICE_AVAYA_SG = '1862,1863,1864,1865';
    public static final String PACKAGES_OFFICE_UO = '524,503,518,501,530,505,536,918,924,930,1853,1854,1855';
    public static final String PACKAGES_OFFICE_AVAYA_EU_FR = '350,351,352,358,356,354,310,375,376,377,1856,1857,1858';
    public static final String PACKAGES_OFFICE_UO_UK = '520,526,532,538,517,523,529,535,903,904,905';
    public static final String PACKAGES_OFFICE_UO_US = '519,525,531,537,507,509,513,515';
    public static final String PACKAGES_OFFICE_UO_AU = '521,527,533,539,541,543,545,547,906,907,908';
    public static final String PACKAGES_OFFICE_RAINBOW = '1000,1002,1004,1006,1008,1009,1010,1859,1860,1861';
    public static final String PACKAGES_ALE_UK_PAID = '1026,1020,1022,1024,1028,1029,1030';
    public static final String PACKAGES_ALE_AU_PAID = '1046,1040,1042,1044,1048,1049,1050';
    public static final String PACKAGES_ALE_US_PAID = '1060,1062,1064,1066';
    public static final String PACKAGES_ALE_CA_PAID = '1080,1082,1084,1086';

    public static final String PACKAGES_MEETINGS_US = '6,7,8';
    public static final String PACKAGES_MEETINGS_CA = '11,12,13';

    public static final String PACKAGES_EV_STANDALONE_US = '640,642,643,650,652,653,660,670,680,690,672,673,676,677,682,683,750,751,752,753,686,687,692,1271005,1270005,1268005';
    public static final String PACKAGES_EV_STANDALONE_CA = '641,644,645,651,654,655,661,671,681,674,675,684,685,754,755,756,757,678,679,688,689,693,691,1273005,1272005,1269005';
    public static final String PACKAGES_EV_STANDALONE_UK = '1709005,1710005,1708005';
    public static final String PACKAGES_EV_STANDALONE_EU = '1902005,1903005,1904005';
    public static final String PACKAGES_EV_STANDALONE_AUS = '2025005, 2026005, 2027005';
    public static final String PACKAGES_EV_STANDALONE_INDIA = '6744005,7546005,7022005';
    public static final String PACKAGES_EV_LEGACY_US = '600,610,620,630';
    public static final String PACKAGES_EV_LEGACY_CA = '601,611,621,631';
    public static final String PACKAGES_ED_LEGACY_US = '550,571';
    public static final String PACKAGES_ED_LEGACY_EU = '560,570';
    public static final String PACKAGES_ED_LEGACY_CA = '551';
    public static final String PACKAGES_ED_STANALONE_EU = '580,590';
    public static final String PACKAGES_ED_STANALONE_US = '581,591';
    public static final String PACKAGES_ED_STANALONE_UK = '583,593';
    public static final String PACKAGES_ED_STANALONE_CA = '582,592';
    public static final String PACKAGES_EO_US = '700,701,702,703,704,705,706,707,708,709,710,711,712,713,714';
    public static final String PACKAGES_EO_CA = '715,716,717,718,719,720,721,722,723,724,725,726,727,728,729';
    public static final String PACKAGES_EO_UK = '730,731,732,733,734,735,736,737,738,739,740,741,742,743,744';
    public static final String PACKAGES_FEDRAMP_US = '974,980,968';
    public static final String PACKAGES_SINGAPORE = '270,273,276,279';
    public static final String PACKAGES_OFFICE_INDIA = '1450,1453,1456';

    public static final String PACKAGES_RCCC_US = '800,801,802,803,804,805,812,813,814,815,816,817,880';
    public static final String PACKAGES_RCCC_CANADA = '806,807,808,809,810,811,818,819,820,821,822,823,881';
    public static final String PACKAGES_RCCC_UK = '824,825,826,827,828,829,836,837,838,839,840,841,1522005,1523005,1524005,1525005,1526005,1527005,1528005,1529005,1530005,1531005,1532005,1533005,2542005';
    public static final String PACKAGES_RCCC_AU = '830,831,832,833,834,835,842,843,844,845,846,847,1534005,1535005,1536005,1537005,1538005,1539005,1540005,1541005,1542005,1543005,1544005,1545005,2483005';
    public static final String PACKAGES_RCCC_EU = '1934005,1935005,1936005,1937005,1938005,1939005,1940005,1941005,1942005,1943005,1944005,1945005,2565005';

    public static final String PACKAGES_MVP_CH = '290,291,293,295';
    public static final String PACKAGES_UO_CH = '910,911,913,915';
    public static final String PACKAGES_AVAYA_CH = '335,336,331,333';
    public static final String PACKAGES_MVP_MEETINGS_CH = '296';
    public static final String PACKAGES_UO_MEETINGS_CH = '916';

    public static final String PACKAGES_OFFICE_AVAYA_EDU_CANADA = '1892,1893';
    public static final String PACKAGES_OFFICE_AVAYA_EDU_US = '1886,1887';
    public static final String PACKAGES_OFFICE_EDU_CANADA = '1960,1963';
    public static final String PACKAGES_OFFICE_EDU = '1951,1954';
    public static final String PACKAGES_OFFICE_EDU_US = '1874,1875';
    public static final String PACKAGES_OFFICE_TAIWAN = '2000,2002,2004';
    public static final String PACKAGES_WEBINAR_CANADA = '1384005';
    public static final String PACKAGES_WEBINAR_US = '1382005';

    public static final String PACKAGES_EVENTS_US = '5102005,5103005,5104005,5105005';
    public static final String PACKAGES_EVENTS_EU = '5465005,5466005,5467005,5468005';
    public static final String PACKAGES_EVENTS_CA = '5452005,5453005,5454005,5455005';
    public static final String PACKAGES_EVENTS_CH = '5472005,5473005,5474005,5483005';
    public static final String PACKAGES_EVENTS_SG = '5469005,5470005,5471005,5488005';
    public static final String PACKAGES_EVENTS_UK = '5456005,5457005,5458005,5459005';
    public static final String PACKAGES_EVENTS_AU = '5460005,5461005,5463005,5464005';

    public static final String PACKAGES_PROSERV_US = '2982005';
    public static final String PACKAGES_PROSERV_CA = '2983005';
    public static final String PACKAGES_PROSERV_EU = '2984005';
    public static final String PACKAGES_PROSERV_UK = '2985005';
    public static final String PACKAGES_PROSERV_AU = '2986005';
    public static final String PACKAGES_PROSERV_SG = '2987005';
    public static final String PACKAGES_PROSERV_CH = '2988005';

    public static final String PACKAGES_NONE = '';

    public static final Map<String, String> DISCOUNTS_MAP = new Map<String, String>{
        'DigitalLine Unlimited' => 'LC_DL-UNL_50',
        'Global Office - EMEA' => 'LC_IBO_284',
        'Global Office - UK' => 'LC_IBO_286',
        'Global Office - APAC' => 'LC_IBO_288',
        'Global Office - LATAM' => 'LC_IBO_290',
        'Digital Line Unlimited*' => 'LC_DL-UNL-CC_737',
        'Global Office* - EMEA' => 'LC_IBO-CC_594',
        'Global Office* - UK' => 'LC_IBO-CC_596',
        'Global Office* - APAC' => 'LC_IBO-CC_598',
        'Global Office* - LATAM' => 'LC_IBO-CC_600',
        'Mobile User' => 'LC_MU_281'
    };

    public static final Map<String, String> DISCOUNTS_MAP_BYOC = new Map<String, String>{
            'DigitalLine Unlimited' => 'LC_DL-UNL_50',
            'DL BYOCD' => 'LC_DL-BYOCD_942',
            'DL BYOCI' => 'LC_DL-BYOCI_942',
            'Global Office - EMEA' => 'LC_IBO_284',
            'Global Office - UK' => 'LC_IBO_286',
            'Global Office - APAC' => 'LC_IBO_288',
            'Global Office - LATAM' => 'LC_IBO_290',
            'Digital Line Unlimited*' => 'LC_DL-UNL-CC_737',
            'Global Office* - EMEA' => 'LC_IBO-CC_594',
            'Global Office* - UK' => 'LC_IBO-CC_596',
            'Global Office* - APAC' => 'LC_IBO-CC_598',
            'Global Office* - LATAM' => 'LC_IBO-CC_600',
            'Mobile User' => 'LC_MU_281'
    };

    public static final Map<String, String> DISCOUNTS_MAP_MEETINGS = new Map<String, String>{'Video Pro' => 'LC_SM_405'};

    public static final Map<String, String> DISCOUNTS_MAP_WITH_US_C = new Map<String, String>{
        'DigitalLine Unlimited' => 'LC_DL-UNL_50',
        'Global Office - EMEA' => 'LC_IBO_284',
        'Global Office - UK' => 'LC_IBO_286',
        'Global Office - APAC' => 'LC_IBO_288',
        'Global Office - LATAM' => 'LC_IBO_290',
        'Global Office - Premium' => 'LC_IBO_292',
        'Global Office - US&C' => 'LC_IBO_696',
        'Digital Line Unlimited*' => 'LC_DL-UNL-CC_737',
        'Global Office* - EMEA' => 'LC_IBO-CC_594',
        'Global Office* - UK' => 'LC_IBO-CC_596',
        'Global Office* - APAC' => 'LC_IBO-CC_598',
        'Global Office* - LATAM' => 'LC_IBO-CC_600',
        'Global Office* - Premium' => 'LC_IBO-CC_602',
        'Global Office* - US&C' => 'LC_IBO-CC_706',
        'Mobile User' => 'LC_MU_281'
    };

    public static final Map<String, String> DISCOUNTS_MAP_WITH_US_C_BYOC = new Map<String, String>{
            'DigitalLine Unlimited' => 'LC_DL-UNL_50',
            'DL BYOCD' => 'LC_DL-BYOCD_942',
            'DL BYOCI' => 'LC_DL-BYOCI_942',
            'Global Office - EMEA' => 'LC_IBO_284',
            'Global Office - UK' => 'LC_IBO_286',
            'Global Office - APAC' => 'LC_IBO_288',
            'Global Office - LATAM' => 'LC_IBO_290',
            'Global Office - Premium' => 'LC_IBO_292',
            'Global Office - US&C' => 'LC_IBO_696',
            'Digital Line Unlimited*' => 'LC_DL-UNL-CC_737',
            'Global Office* - EMEA' => 'LC_IBO-CC_594',
            'Global Office* - UK' => 'LC_IBO-CC_596',
            'Global Office* - APAC' => 'LC_IBO-CC_598',
            'Global Office* - LATAM' => 'LC_IBO-CC_600',
            'Global Office* - Premium' => 'LC_IBO-CC_602',
            'Global Office* - US&C' => 'LC_IBO-CC_706',
            'Mobile User' => 'LC_MU_281'
    };

    public static final Map<String, String> DISCOUNTS_MAP_WITH_MS_TEAM = new Map<String, String>{
        'DigitalLine Unlimited' => 'LC_DL-UNL_50',
        'DL BYOCD' => 'LC_DL-BYOCD_942',
        'DL BYOCI' => 'LC_DL-BYOCI_942',
        'Global Office - EMEA' => 'LC_IBO_284',
        'Global Office - UK' => 'LC_IBO_286',
        'Global Office - APAC' => 'LC_IBO_288',
        'Global Office - LATAM' => 'LC_IBO_290',
        'Digital Line Unlimited*' => 'LC_DL-UNL-CC_737',
        'Global Office* - EMEA' => 'LC_IBO-CC_594',
        'Global Office* - UK' => 'LC_IBO-CC_596',
        'Global Office* - APAC' => 'LC_IBO-CC_598',
        'Global Office* - LATAM' => 'LC_IBO-CC_600',
        'Mobile User' => 'LC_MU_281',
        'MS Teams CloudPBX - Global MVP EMEA' => 'LC_IBO-MST_957',
        'MS Teams CloudPBX - Global MVP UK' => 'LC_IBO-MST_959',
        'MS Teams CloudPBX - Global MVP APAC' => 'LC_IBO-MST_961',
        'MS Teams CloudPBX - Global MVP LATAM' => 'LC_IBO-MST_963',
        'MS Teams CloudPBX - Global MVP Premium' => 'LC_IBO-MST_965',
        'MS Teams CloudPBX - Domestic' => 'LC_DL-MST_955'
};

    public static final Map<String, String> DISCOUNTS_MAP_OFFICE_CA = new Map<String, String>{
        'DigitalLine Unlimited' => 'LC_DL-UNL_50',
        'DL BYOCD' => 'LC_DL-BYOCD_942',
        'DL BYOCI' => 'LC_DL-BYOCI_942',
        'Global Office - EMEA' => 'LC_IBO_284',
        'Global Office - UK' => 'LC_IBO_286',
        'Global Office - APAC' => 'LC_IBO_288',
        'Global Office - LATAM' => 'LC_IBO_290',
        'Global Office - Premium' => 'LC_IBO_292',
        'Global Office - US&C' => 'LC_IBO_696',
        'Digital Line Unlimited*' => 'LC_DL-UNL-CC_737',
        'Global Office* - EMEA' => 'LC_IBO-CC_594',
        'Global Office* - UK' => 'LC_IBO-CC_596',
        'Global Office* - APAC' => 'LC_IBO-CC_598',
        'Global Office* - LATAM' => 'LC_IBO-CC_600',
        'Global Office* - Premium' => 'LC_IBO-CC_602',
        'Global Office* - US&C' => 'LC_IBO-CC_706',
        'Mobile User' => 'LC_MU_281',
        'MS Teams CloudPBX - Global MVP EMEA' => 'LC_IBO-MST_957',
        'MS Teams CloudPBX - Global MVP UK' => 'LC_IBO-MST_959',
        'MS Teams CloudPBX - Global MVP APAC' => 'LC_IBO-MST_961',
        'MS Teams CloudPBX - Global MVP LATAM' => 'LC_IBO-MST_963',
        'MS Teams CloudPBX - Global MVP Premium' => 'LC_IBO-MST_965',
        'MS Teams CloudPBX - Domestic' => 'LC_DL-MST_955',
        'MS Teams CloudPBX - Global MVP US&CA' => 'LC_IBO-MST_967'
    };

    public static final Map<String, String> DISCOUNTS_MAP_OFFICE_EDU = new Map<String, String>{
        'DL BYOCD' =>'LC_DL-BYOCD_942',
        'DL BYOCI' =>'LC_DL-BYOCI_942',
        'MS Teams CloudPBX - Domestic' =>'LC_DL-MST_955',
        'Digital Line Unlimited*' =>'LC_DL-UNL-CC_737',
        'DigitalLine Unlimited' =>'LC_DL-UNL_50',
        'Global Office* - EMEA' =>'LC_IBO-CC_594',
        'Global Office* - UK' =>'LC_IBO-CC_596',
        'Global Office* - APAC' =>'LC_IBO-CC_598',
        'Global Office* - LATAM' =>'LC_IBO-CC_600',
        'MS Teams CloudPBX - Global MVP EMEA' =>'LC_IBO-MST_957',
        'MS Teams CloudPBX - Global MVP UK' =>'LC_IBO-MST_959',
        'MS Teams CloudPBX - Global MVP APAC' =>'LC_IBO-MST_961',
        'MS Teams CloudPBX - Global MVP LATAM' =>'LC_IBO-MST_963',
        'MS Teams CloudPBX - Global MVP Premium' =>'LC_IBO-MST_965',
        'Global Office - EMEA' =>'LC_IBO_284',
        'Global Office - UK' =>'LC_IBO_286',
        'Global Office - APAC' =>'LC_IBO_288',
        'Global Office - LATAM' =>'LC_IBO_290',
        'Mobile User' =>'LC_MU_281'
    };

    public static final List<ContractWithDiscounts> CONTRACTS = new List<ContractWithDiscounts>{
        new ContractWithDiscounts(NAME_OFFICE_CONTRACT, PACKAGES_OFFICE_US, DISCOUNTS_MAP_BYOC, 7, 'Office', true, RingCentralHelper.USD),
        new ContractWithDiscounts(NAME_OFFICE_CONTRACT, PACKAGES_OFFICE_CA, DISCOUNTS_MAP_BYOC, 7, 'Office_Canada', true, RingCentralHelper.CAD),
        new ContractWithDiscounts(NAME_OFFICE_CONTRACT, PACKAGES_OFFICE_5_US, DISCOUNTS_MAP_OFFICE_CA, 5, 'Office_5_US', true, RingCentralHelper.USD),
        new ContractWithDiscounts(NAME_OFFICE_CONTRACT, PACKAGES_OFFICE_5_CA, DISCOUNTS_MAP_OFFICE_CA, 5, 'Office_5_CA', true, RingCentralHelper.CAD),
        new ContractWithDiscounts(NAME_OFFICE_CONTRACT, PACKAGES_OFFICE_AVAYA_5_US, DISCOUNTS_MAP_OFFICE_CA, 5, 'Office_Avaya_5_USA_20', true, RingCentralHelper.USD),
        new ContractWithDiscounts(NAME_OFFICE_CONTRACT, PACKAGES_OFFICE_AVAYA_5_CA, DISCOUNTS_MAP_OFFICE_CA, 5, 'Office_Avaya_5_CAN_23', true, RingCentralHelper.CAD),
        new ContractWithDiscounts(NAME_OFFICE_CONTRACT, PACKAGES_OFFICE_AU, DISCOUNTS_MAP_WITH_US_C_BYOC, 7, 'Office_Australia', true, RingCentralHelper.AUD),
        new ContractWithDiscounts(NAME_OFFICE_CONTRACT, PACKAGES_OFFICE_EU, DISCOUNTS_MAP_WITH_US_C_BYOC, 3, 'Office_Europe', true, RingCentralHelper.EUR),
        new ContractWithDiscounts(NAME_OFFICE_CONTRACT, PACKAGES_OFFICE_UK, DISCOUNTS_MAP_WITH_US_C, 2, 'Office_United_Kingdom', true, RingCentralHelper.GBP),
        new ContractWithDiscounts(NAME_OFFICE_CONTRACT, PACKAGES_OFFICE_AVAYA, DISCOUNTS_MAP, 7, 'Office_Avaya', true, RingCentralHelper.USD),

        new ContractWithDiscounts(NAME_OFFICE_CONTRACT, PACKAGES_OFFICE_AVAYA_CA, DISCOUNTS_MAP, 7, 'Office_Avaya_Canada', true, RingCentralHelper.CAD),
        new ContractWithDiscounts(NAME_OFFICE_CONTRACT, PACKAGES_OFFICE_AVAYA_AU, DISCOUNTS_MAP, 7, 'Office_Avaya_Australia', true, RingCentralHelper.AUD),
        new ContractWithDiscounts(NAME_OFFICE_CONTRACT, PACKAGES_OFFICE_AVAYA_UK, DISCOUNTS_MAP, 2, 'Office_Avaya_United_Kingdom', true, RingCentralHelper.GBP),
        new ContractWithDiscounts(NAME_OFFICE_CONTRACT, PACKAGES_OFFICE_AVAYA_SG, DISCOUNTS_MAP_WITH_US_C, 7, 'Office_Avaya_SG', true, RingCentralHelper.SGD),

        new ContractWithDiscounts('Office Contract US Old', PACKAGES_OFFICE_US_OLD, DISCOUNTS_MAP, 2, 'Office_US_Old', false, RingCentralHelper.USD),
        new ContractWithDiscounts('Office Contract Canada Old', PACKAGES_OFFICE_CA_OLD, DISCOUNTS_MAP, 2, 'Office_Canada_Old', false, RingCentralHelper.CAD),
        new ContractWithDiscounts('Office Contract Australia Old', PACKAGES_OFFICE_AU_OLD, DISCOUNTS_MAP, 2, 'Office_Australia_Old', false, RingCentralHelper.AUD),

        new ContractWithDiscounts(NAME_OFFICE_CONTRACT, PACKAGES_OFFICE_10_US, DISCOUNTS_MAP_WITH_MS_TEAM, 10, 'Office_10_US', true, RingCentralHelper.USD),

        new ContractWithDiscounts(NAME_OFFICE_CONTRACT, PACKAGES_OFFICE_UO, DISCOUNTS_MAP_WITH_US_C, 3, 'Office_UO_EU', true, RingCentralHelper.EUR,
            'Belgium;Denmark;Ireland;Italy;Netherlands;Norway;Portugal;Spain;Sweden;Finland', 'France'),
        new ContractWithDiscounts(NAME_OFFICE_CONTRACT, PACKAGES_OFFICE_UO, DISCOUNTS_MAP_WITH_US_C, 3, 'Office_UO_FR', true, RingCentralHelper.EUR,
            'France', 'France'),
        new ContractWithDiscounts(NAME_OFFICE_CONTRACT, PACKAGES_OFFICE_UO, DISCOUNTS_MAP_WITH_US_C, 3, 'Office_UO_DE', true, RingCentralHelper.EUR,
            'Austria;Germany', 'Germany'),
        new ContractWithDiscounts(NAME_OFFICE_CONTRACT, PACKAGES_OFFICE_UO_UK, DISCOUNTS_MAP_WITH_US_C, 2, 'Office_UO_UK', true, RingCentralHelper.GBP,
            'United Kingdom', 'United Kingdom'),
        new ContractWithDiscounts(NAME_OFFICE_CONTRACT, PACKAGES_OFFICE_UO_US, DISCOUNTS_MAP, 7, 'Office_UO_US', true, RingCentralHelper.USD,
            'United States', 'United States'),
        new ContractWithDiscounts(NAME_OFFICE_CONTRACT, PACKAGES_OFFICE_UO_AU, DISCOUNTS_MAP_WITH_US_C, 7, 'Office_UO_AU', true, RingCentralHelper.AUD,
            'Australia', 'Australia'),

        new ContractWithDiscounts('Phoenix Meetings US Contract', '210,666', 'Phoenix_Meetings', true, RingCentralHelper.USD),
        new ContractWithDiscounts('Phoenix Meetings CA Contract', '220', 'Phoenix_Meetings_Canada', true, RingCentralHelper.CAD),
        new ContractWithDiscounts('Phoenix Meetings UK Contract', '231', 'Phoenix_Meetings_United_Kingdom', true, RingCentralHelper.GBP),
        new ContractWithDiscounts('Phoenix Meetings EU Contract', '241', 'Phoenix_Meetings_Europe', true, RingCentralHelper.EUR),
        new ContractWithDiscounts('Phoenix Meetings AU Contract', '251', 'Phoenix_Meetings_Australia', true, RingCentralHelper.AUD),
        new ContractWithDiscounts('Unify Office Video US Contract', '900', DISCOUNTS_MAP_MEETINGS, 2, 'Video_UO_US', true, RingCentralHelper.USD),
        new ContractWithDiscounts('Unify Office Video UK Contract', '901', DISCOUNTS_MAP_MEETINGS, 1, 'Video_UO_UK', true, RingCentralHelper.GBP),
        new ContractWithDiscounts('Unify Office Video AU Contract', '902', DISCOUNTS_MAP_MEETINGS, 3, 'Video_UO_AU', true, RingCentralHelper.AUD),
        new ContractWithDiscounts('Unify Office Video EU Contract', '510', DISCOUNTS_MAP_MEETINGS, 1, 'UnifyOffice_Phoenix_Meetings_Europe', true, RingCentralHelper.EUR),
        new ContractWithDiscounts(NAME_OFFICE_CONTRACT, PACKAGES_OFFICE_AVAYA_EU_FR, DISCOUNTS_MAP_WITH_US_C, 3, 'Office_Avaya_EU', true, RingCentralHelper.EUR,
            'Ireland;Netherlands;Italy;Spain;Belgium;Portugal', 'France'),
        new ContractWithDiscounts(NAME_OFFICE_CONTRACT, PACKAGES_OFFICE_AVAYA_EU_FR, DISCOUNTS_MAP_WITH_US_C, 3, 'Office_Avaya_DE', true, RingCentralHelper.EUR,
            'Germany;Austria', 'Germany'),
        new ContractWithDiscounts(NAME_OFFICE_CONTRACT, PACKAGES_OFFICE_AVAYA_EU_FR, DISCOUNTS_MAP_WITH_US_C, 3, 'Office_Avaya_FR', true, RingCentralHelper.EUR,
            'France', 'France'),
        new ContractWithDiscounts(NAME_OFFICE_CONTRACT, PACKAGES_OFFICE_RAINBOW, DISCOUNTS_MAP_WITH_US_C, 3, 'Office_RO_EU', true, RingCentralHelper.EUR,
            'Belgium;Italy;Spain;Ireland;Netherlands', 'France'),
        new ContractWithDiscounts(NAME_OFFICE_CONTRACT, PACKAGES_OFFICE_RAINBOW, DISCOUNTS_MAP_WITH_US_C, 3, 'Office_RO_FR', true, RingCentralHelper.EUR,
            'France', 'France'),
        new ContractWithDiscounts(NAME_OFFICE_CONTRACT, PACKAGES_OFFICE_RAINBOW, DISCOUNTS_MAP_WITH_US_C, 3, 'Office_RO_DE', true, RingCentralHelper.EUR,
            'Germany;Austria', 'Germany'),
        new ContractWithDiscounts(NAME_OFFICE_CONTRACT, PACKAGES_ALE_UK_PAID, DISCOUNTS_MAP_WITH_US_C, 2, 'Office_RO_UK', true, RingCentralHelper.GBP,
            'United Kingdom', 'United Kingdom'),
        new ContractWithDiscounts(NAME_OFFICE_CONTRACT, PACKAGES_ALE_AU_PAID, DISCOUNTS_MAP_WITH_US_C, 7, 'Office_RO_AU', true, RingCentralHelper.AUD,
            'Australia', 'Australia'),

        new ContractWithDiscounts(NAME_MEETINGS_CONTRACT, PACKAGES_MEETINGS_US, 'Meetings', true, RingCentralHelper.USD),
        new ContractWithDiscounts(NAME_MEETINGS_CONTRACT, PACKAGES_MEETINGS_CA, 'Meetings_Canada', true, RingCentralHelper.CAD),

        new ContractWithDiscounts(NAME_EV_STANDALONE_CONTRACT, PACKAGES_EV_STANDALONE_US, 'EV_Standalone', true, RingCentralHelper.USD),
        new ContractWithDiscounts(NAME_EV_STANDALONE_CONTRACT, PACKAGES_EV_STANDALONE_CA, 'EV_Standalone_Canada', true, RingCentralHelper.CAD),
        new ContractWithDiscounts(NAME_EV_STANDALONE_CONTRACT, PACKAGES_EV_STANDALONE_UK, 'EV_Standalone_United_Kingdom', true, RingCentralHelper.GBP),
        new ContractWithDiscounts(NAME_EV_STANDALONE_CONTRACT, PACKAGES_EV_STANDALONE_EU, 'EV_Standalone_EU', true, RingCentralHelper.EUR),
        new ContractWithDiscounts(NAME_EV_STANDALONE_CONTRACT, PACKAGES_EV_STANDALONE_AUS, 'EV_Standalone_AUS', true, RingCentralHelper.AUD),
        new ContractWithDiscounts(NAME_EV_STANDALONE_CONTRACT, PACKAGES_EV_STANDALONE_INDIA, 'EV_Standalone_India', true, RingCentralHelper.INR),
        new ContractWithDiscounts(NAME_EV_LEGACY_CONTRACT, PACKAGES_EV_LEGACY_US, 'EV_Legacy', true, RingCentralHelper.USD),
        new ContractWithDiscounts(NAME_EV_LEGACY_CONTRACT, PACKAGES_EV_LEGACY_CA, 'EV_Legacy_Canada', true, RingCentralHelper.CAD),
        new ContractWithDiscounts(NAME_ED_STANDALONE_CONTRACT, PACKAGES_ED_STANALONE_EU, 'ED_Standalone_Europe', true, RingCentralHelper.EUR),
        new ContractWithDiscounts(NAME_ED_STANDALONE_CONTRACT, PACKAGES_ED_STANALONE_US, 'ED_Standalone', true, RingCentralHelper.USD),
        new ContractWithDiscounts(NAME_ED_STANDALONE_CONTRACT, PACKAGES_ED_STANALONE_UK, 'ED_Standalone_United_Kingdom', true, RingCentralHelper.GBP),
        new ContractWithDiscounts(NAME_ED_STANDALONE_CONTRACT, PACKAGES_ED_STANALONE_CA, 'ED_Standalone_Canada', true, RingCentralHelper.CAD),
        new ContractWithDiscounts(NAME_ED_LEGACY_CONTRACT, PACKAGES_ED_LEGACY_US, 'ED_Legacy', true, RingCentralHelper.USD),
        new ContractWithDiscounts(NAME_ED_LEGACY_CONTRACT, PACKAGES_ED_LEGACY_EU, 'ED_Legacy_Europe', true, RingCentralHelper.EUR),
        new ContractWithDiscounts(NAME_ED_LEGACY_CONTRACT, PACKAGES_ED_LEGACY_CA, 'ED_Legacy_Canada', true, RingCentralHelper.CAD),
        new ContractWithDiscounts(NAME_EO_CONTRACT, PACKAGES_EO_US, 'EO', true, RingCentralHelper.USD),
        new ContractWithDiscounts(NAME_EO_CONTRACT, PACKAGES_EO_CA, 'EO_Canada', true, RingCentralHelper.CAD),

        new ContractWithDiscounts(NAME_FEDRAMP_CONTRACT, PACKAGES_FEDRAMP_US, DISCOUNTS_MAP, 7, 'Office_FedRamp', true, RingCentralHelper.USD),
        new ContractWithDiscounts(NAME_EO_CONTRACT, PACKAGES_EO_UK, 'EO_United_Kingdom', true, RingCentralHelper.GBP),
        new ContractWithDiscounts(NAME_OFFICE_CONTRACT_SINGAPORE, PACKAGES_SINGAPORE, DISCOUNTS_MAP_WITH_US_C, 7, 'Office_Singapore', true, RingCentralHelper.SGD),
        new ContractWithDiscounts(NAME_OFFICE_INDIA_CONTRACT, PACKAGES_OFFICE_INDIA, 'Office_India', true, RingCentralHelper.INR),

        new ContractWithDiscounts(NAME_RCCC_CONTRACT, PACKAGES_RCCC_US, 'RCCC', true, RingCentralHelper.USD),
        new ContractWithDiscounts(NAME_RCCC_CONTRACT, PACKAGES_RCCC_CANADA, 'RCCC_Canada', true, RingCentralHelper.CAD),
        new ContractWithDiscounts(NAME_RCCC_CONTRACT, PACKAGES_RCCC_UK, 'RCCC_United_Kingdom', true, RingCentralHelper.GBP),
        new ContractWithDiscounts(NAME_RCCC_CONTRACT, PACKAGES_RCCC_AU, 'RCCC_Australia', true, RingCentralHelper.AUD),
        new ContractWithDiscounts(NAME_RCCC_CONTRACT, PACKAGES_RCCC_EU, 'RCCC_EU', true, RingCentralHelper.EUR),

        new ContractWithDiscounts(NAME_OFFICE_CONTRACT, PACKAGES_ALE_US_PAID, DISCOUNTS_MAP, 7, 'Office_ALE', true, RingCentralHelper.USD),
        new ContractWithDiscounts(NAME_OFFICE_CONTRACT, PACKAGES_ALE_CA_PAID, DISCOUNTS_MAP, 7, 'Office_ALE_Canada', true, RingCentralHelper.CAD),

        new ContractWithDiscounts(NAME_OFFICE_CONTRACT, PACKAGES_MVP_CH, DISCOUNTS_MAP_WITH_US_C_BYOC, 3, 'MVP_CH', true, RingCentralHelper.CHF, null, 'Switzerland'),
        new ContractWithDiscounts(NAME_OFFICE_CONTRACT, PACKAGES_UO_CH, DISCOUNTS_MAP_WITH_US_C, 3, 'UO_CH', true, RingCentralHelper.CHF, 'Switzerland', 'Switzerland'),
        new ContractWithDiscounts(NAME_OFFICE_CONTRACT, PACKAGES_AVAYA_CH, DISCOUNTS_MAP_WITH_US_C, 3, 'Avaya_CH', true, RingCentralHelper.CHF, 'Switzerland', 'Switzerland'),
        new ContractWithDiscounts(NAME_MEETINGS_CONTRACT, PACKAGES_MVP_MEETINGS_CH, 'MVP_Meetings_CH', true, RingCentralHelper.CHF, 'Switzerland', 'Switzerland'),
        new ContractWithDiscounts(NAME_UO_VIDEO_CONRACT, PACKAGES_UO_MEETINGS_CH, DISCOUNTS_MAP_MEETINGS, 1, 'UnifyOffice_Meetings_CH', true, RingCentralHelper.CHF, 'Switzerland', 'Switzerland'),

        new ContractWithDiscounts(NAME_OFFICE_EDUCATION_CONTRACT, PACKAGES_OFFICE_AVAYA_EDU_CANADA, DISCOUNTS_MAP_OFFICE_EDU, 4, 'Office_Avaya_Canada_EDU', true, RingCentralHelper.CAD ),
        new ContractWithDiscounts(NAME_OFFICE_EDUCATION_CONTRACT, PACKAGES_OFFICE_AVAYA_EDU_US, DISCOUNTS_MAP_OFFICE_EDU, 4, 'Office_Avaya_US_EDU', true, RingCentralHelper.USD),
        new ContractWithDiscounts(NAME_OFFICE_EDUCATION_CONTRACT, PACKAGES_OFFICE_EDU_US, DISCOUNTS_MAP_OFFICE_EDU, 4, 'Office_US_EDU', true, RingCentralHelper.USD),
        new ContractWithDiscounts(NAME_OFFICE_EDUCATION_CONTRACT, PACKAGES_OFFICE_EDU_CANADA, DISCOUNTS_MAP_OFFICE_EDU, 4, 'Office_Canada_EDU', true, RingCentralHelper.CAD),
        new ContractWithDiscounts(NAME_OFFICE_EDUCATION_CONTRACT, PACKAGES_OFFICE_EDU, DISCOUNTS_MAP_OFFICE_EDU, 4, 'Office_EDU', true, RingCentralHelper.USD),
        new ContractWithDiscounts(NAME_OFFICE_TAIWAN_CONTRACT, PACKAGES_OFFICE_TAIWAN, 'Office_Taiwan', true, RingCentralHelper.TWD),
        new ContractWithDiscounts(NAME_PROSERV_CONTRACT, PACKAGES_PROSERV_US, 'ProServ_US', true, RingCentralHelper.USD),
        new ContractWithDiscounts(NAME_PROSERV_CONTRACT, PACKAGES_PROSERV_CA, 'ProServ_CA', true, RingCentralHelper.CAD),
        new ContractWithDiscounts(NAME_PROSERV_CONTRACT, PACKAGES_PROSERV_EU, 'ProServ_EU', true, RingCentralHelper.EUR),
        new ContractWithDiscounts(NAME_PROSERV_CONTRACT, PACKAGES_PROSERV_UK, 'ProServ_UK', true, RingCentralHelper.GBP),
        new ContractWithDiscounts(NAME_PROSERV_CONTRACT, PACKAGES_PROSERV_AU, 'ProServ_AU', true, RingCentralHelper.AUD),
        new ContractWithDiscounts(NAME_PROSERV_CONTRACT, PACKAGES_PROSERV_SG, 'ProServ_SG', true, RingCentralHelper.SGD),
        new ContractWithDiscounts(NAME_PROSERV_CONTRACT, PACKAGES_PROSERV_CH, 'ProServ_CH', true, RingCentralHelper.CHF),

        new ContractWithDiscounts(NAME_EVENTS_CONTRACT, PACKAGES_EVENTS_US, 'RC_Events', true, RingCentralHelper.USD),
        new ContractWithDiscounts(NAME_EVENTS_CONTRACT, PACKAGES_EVENTS_EU, 'RC_Events_EU', true, RingCentralHelper.EUR),
        new ContractWithDiscounts(NAME_EVENTS_CONTRACT, PACKAGES_EVENTS_CA, 'RC_Events_CA', true, RingCentralHelper.CAD),
        new ContractWithDiscounts(NAME_EVENTS_CONTRACT, PACKAGES_EVENTS_UK, 'RC_Events_UK', true, RingCentralHelper.GBP),
        new ContractWithDiscounts(NAME_EVENTS_CONTRACT, PACKAGES_EVENTS_AU, 'RC_Events_AU', true, RingCentralHelper.AUD),
        new ContractWithDiscounts(NAME_EVENTS_CONTRACT, PACKAGES_EVENTS_CH, 'RC_Events_CH', true, RingCentralHelper.CHF),
        new ContractWithDiscounts(NAME_EVENTS_CONTRACT, PACKAGES_EVENTS_SG, 'RC_Events_SG', true, RingCentralHelper.SGD)
    };

    public override String getClassName() {
        return PostCopyContractsInsert.class.getName();
    }

    public override void run() {
        Response existingData = selectExisting();
        Response insertUpdateData = getNonExisting(existingData);
        insertUpdateRecords(insertUpdateData);
    }

    public static Response selectExisting() {
        Response res = new Response();
        Map<String, Contract__c> mapContractByExternalIds = new Map<String, Contract__c>();
        Map<String, Map<String, Contract_Discount__c>> mapContractDiscountByExternalIds = new Map<String, Map<String, Contract_Discount__c>>();
        for (Contract__c c : (List<Contract__c>) new BillingContractSelector().selectContractsWithDiscounts().executeQuery()) {
            mapContractByExternalIds.put(c.ExtID__c, c);
            mapContractDiscountByExternalIds.put(c.ExtID__c, new Map<String, Contract_Discount__c>());
            if (!c.Contract_Discounts__r.isEmpty()) {
                for (Contract_Discount__c discount : c.Contract_Discounts__r) {
                    if (!mapContractDiscountByExternalIds.get(c.ExtID__c).containsKey(discount.ApplicableTo__c)) {
                        mapContractDiscountByExternalIds.get(c.ExtID__c).put(discount.ApplicableTo__c, discount);
                    }
                }
            }
        }
        res.setData('existingContracts', mapContractByExternalIds);
        res.setData('existingContractDiscounts', mapContractDiscountByExternalIds);
        return res;
    }

    public Response getNonExisting(Response existingData) {
        Response updateInsertContractDiscount = new Response();
        List<ContractWithDiscounts> result = new List<ContractWithDiscounts>();
        Map<String, Contract__c> existingContracts = (Map<String, Contract__c>) existingData.data.get('existingContracts');
        Map<String, Map<String, Contract_Discount__c>> existingContractDiscounts = (Map<String, Map<String, Contract_Discount__c>>) existingData.data.get('existingContractDiscounts');
        Set<Contract__c> updateExistingContracts = new Set<Contract__c>();
        Set<Contract_Discount__c> updateExistingDiscounts = new Set<Contract_Discount__c>();
        Set<Contract_Discount__c> insertDiscountsForExistingContracts = new Set<Contract_Discount__c>();
        for (ContractWithDiscounts c : CONTRACTS) {
            if (!existingContracts.containsKey(c.extId)) {
                result.add(c);
            } else {
                Contract__c oldContract = existingContracts.get(c.extId);
                if (
                        oldContract.CurrencyIsoCode != c.contract.CurrencyIsoCode ||
                        oldContract.Active__c != c.contract.Active__c ||
                        oldContract.Name != c.contract.Name ||
                        oldContract.Available_in_packages__c != c.contract.Available_in_packages__c ||
                        oldContract.Business_Identities_Countries__c != c.contract.Business_Identities_Countries__c ||
                        oldContract.Billing_Countries__c != c.contract.Billing_Countries__c
                    ) {
                    updateExistingContracts.add(new Contract__c(
                            Id = oldContract.Id,
                            CurrencyIsoCode = c.contract.CurrencyIsoCode,
                            Active__c = c.contract.Active__c,
                            Name = c.contract.Name,
                            Available_in_packages__c = c.contract.Available_in_packages__c,
                            Billing_Countries__c = c.contract.Billing_Countries__c,
                            Business_Identities_Countries__c = c.contract.Business_Identities_Countries__c));
                }
                for (Contract_Discount__c discount : c.discounts) {
                    if (!existingContractDiscounts.get(c.extId).containsKey(discount.ApplicableTo__c)) {
                        discount.Contract__c = oldContract.Id;
                        discount.CurrencyIsoCode = oldContract.CurrencyIsoCode;
                        insertDiscountsForExistingContracts.add(discount);
                    } else if (
                            existingContractDiscounts.get(c.extId).get(discount.ApplicableTo__c).Discount__c != discount.Discount__c ||
                            existingContractDiscounts.get(c.extId).get(discount.ApplicableTo__c).Duration__c != discount.Duration__c ||
                            existingContractDiscounts.get(c.extId).get(discount.ApplicableTo__c).Name != discount.Name ||
                            existingContractDiscounts.get(c.extId).get(discount.ApplicableTo__c).CurrencyIsoCode != discount.CurrencyIsoCode) {

                        updateExistingDiscounts.add(new Contract_Discount__c(
                                Id = existingContractDiscounts.get(c.extId).get(discount.ApplicableTo__c).Id,
                                CurrencyIsoCode = discount.CurrencyIsoCode,
                                Discount__c = discount.Discount__c,
                                Duration__c = discount.Duration__c,
                                Name = discount.Name));
                    }
                }
            }
        }

        updateInsertContractDiscount.setData('insertNewContractsDiscounts', result);
        updateInsertContractDiscount.setData('updateExistingContracts', new List<Contract__c>(updateExistingContracts));
        updateInsertContractDiscount.setData('updateExistingDiscounts', new List<Contract_Discount__c>(updateExistingDiscounts));
        updateInsertContractDiscount.setData('insertDiscountsForExistingContracts', new List<Contract_Discount__c>(insertDiscountsForExistingContracts));

        return updateInsertContractDiscount;
    }

    public void insertUpdateRecords(Response insertUpdateData) {
        List<Contract__c> contractsToInsert = getContracts((List<ContractWithDiscounts>)insertUpdateData.data.get('insertNewContractsDiscounts'));
        if (!contractsToInsert.isEmpty()) {
            insert contractsToInsert;
        }

        List<Contract_Discount__c> contractDiscountsToInsert = getContractDiscounts((List<ContractWithDiscounts>)insertUpdateData.data.get('insertNewContractsDiscounts'));
        if (!contractDiscountsToInsert.isEmpty()) {
            insert contractDiscountsToInsert;
        }

        List<Contract__c> updateContracts = (List<Contract__c>)insertUpdateData.data.get('updateExistingContracts');
        if (!updateContracts.isEmpty()) {
            update updateContracts;
        }
        List<Contract_Discount__c> updateDiscounts = (List<Contract_Discount__c>)insertUpdateData.data.get('updateExistingDiscounts');
        if (!updateDiscounts.isEmpty()) {
            update updateDiscounts;
        }
        List<Contract_Discount__c> insertNewDiscountsForExistingContracts = (List<Contract_Discount__c>)insertUpdateData.data.get('insertDiscountsForExistingContracts');
        if (!insertNewDiscountsForExistingContracts.isEmpty()) {
            insert insertNewDiscountsForExistingContracts;
        }
    }

    public List<Contract__c> getContracts(List<ContractWithDiscounts> newContracts) {
        List<Contract__c> result = new List<Contract__c>();
        for (ContractWithDiscounts c : newContracts) {
            result.add(c.contract);
        }
        return result;
    }

    public List<Contract_Discount__c> getContractDiscounts(List<ContractWithDiscounts> newContracts) {
        List<Contract_Discount__c> result = new List<Contract_Discount__c>();
        for (ContractWithDiscounts c : newContracts) {
            result.addAll(c.discounts);
        }
        return result;
    }

    @TestVisible
    private class ContractWithDiscounts {
        public Contract__c contract;

        public List<Contract_Discount__c> discounts {
            get {
                if (this.discounts == null) {
                    this.discounts = new List<Contract_Discount__c>();
                }
                for (Contract_Discount__c cd: this.discounts) {
                    Id contractId = this.contract == null ? null : this.contract.Id;
                    String contractCurrency = this.contract == null ? null : this.contract.CurrencyIsoCode;
                    if (cd.Contract__c != contractId && contractId != null) {
                        cd.Contract__c = contractId;
                        if (contractCurrency != null) {
                            cd.CurrencyIsoCode = contractCurrency;
                        }
                    }
                }
                return this.discounts;
            }
            set {
                this.discounts = value == null ? new List<Contract_Discount__c>() : value;
            }
        }
        public String extId {
            get {
                return this.contract == null ? null : this.contract.ExtID__c;
            }
        }

        ContractWithDiscounts(
            String name,
            String availableInPackages,
            String extId,
            Boolean isActive,
            String currencyCode
        ) {
            this.createContract(name, extId, availableInPackages, isActive, currencyCode, '', '');
        }

        public ContractWithDiscounts(
            String name,
            String availableInPackages,
            Map<String, String> discountsMap,
            Decimal discount,
            String extId,
            Boolean isActive,
            String currencyCode
        ) {
            this.createContract(name, extId, availableInPackages, isActive, currencyCode, '', '');
            this.createDiscounts(discount, discountsMap);
        }

        public ContractWithDiscounts(
            String name,
            String availableInPackages,
            Map<String, String> discountsMap,
            Decimal discount,
            String extId,
            Boolean isActive,
            String currencyCode,
            String billingCountries,
            String biCountries
        ) {
            this.createContract(name, extId, availableInPackages, isActive, currencyCode, billingCountries, biCountries);
            this.createDiscounts(discount, discountsMap);
        }

        public ContractWithDiscounts(
            String name,
            String availableInPackages,
            String extId,
            Boolean isActive,
            String currencyCode,
            String billingCountries,
            String biCountries
        ) {
            this.createContract(name, extId, availableInPackages, isActive, currencyCode, billingCountries, biCountries);
        }

        public void createContract(
            String name,
            String extId,
            String Available_in_packages,
            Boolean isActive,
            String currencyCode,
            String billingCountries,
            String biCountries
        ) {
            this.contract = new Contract__c(
                Name = name,
                Available_in_packages__c = Available_in_packages,
                ExtID__c = extId,
                Active__c = isActive,
                CurrencyIsoCode = currencyCode,
                Billing_Countries__c = billingCountries,
                Business_Identities_Countries__c = biCountries
            );
        }

        public void createDiscounts(Decimal discount, Map<String, String> discountMapping) {
            List<Contract_Discount__c> result = new List<Contract_Discount__c>();

            for (String name : discountMapping.keySet()) {
                result.add(new Contract_Discount__c(
                    Name = name,
                    ApplicableTo__c = discountMapping.get(name),
                    Discount__c = NumberHelper.toNumber(discount),
                    Duration__c = Product2Helper.CHARGE_TERM_MONTHLY
                ));
            }

            this.discounts = result;
        }
    }
}