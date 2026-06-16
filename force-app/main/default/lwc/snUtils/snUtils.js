const READY = 'ready';
const ACTIVE = 'active';
const COMPLETED = 'completed';
const OFF = 'off';
const CHOOSE_PRIMARY_QUOTE = 'Choose Primary Quote';
const ORDERS_CREATION = 'Creating orders...';
const QUERYING_DATA = 'Querying data...';
const VALIDATION = 'Data validation...';
const PREPARING_CASES = 'Preparing Cases...';
const PREPARING = 'Preparing Account and Opportunity...';
const READY_TO_FUNNEL = 'Ready to request Funnel';
const READY_TO_CREATE_MAIN_COST_CENTER = 'Ready to create Main Cost Center';
const COST_CENTER_CREATED = 'Cost Center Created';
const PROSERV_SIGNUP_REQUEST_SEND = 'ProServ SignUp Request Send';
const FUNNEL_REQUEST = 'Funnel request...';
const SYNCED = 'Synced';
const PROCESSING = 'processing';
const CONTACT_CENTER = 'Contact Center';
const ENGAGE_DIGITAL = 'Engage Digital';
const ENGAGE_VOICE = 'Engage Voice';
const MVP = 'MVP';
const SIGN_UP_IN_PROCESS = (serviceNames) => `Your account is being processed. This window can be closed now. You will receive notification in the chatter after completion or use "Check ${serviceNames} Status" button`;
const SIGNED_UP = (serviceNames) => `${serviceNames} account has been created. Please, contact customer to activate account`;
const CONTACT_ORDER_MANAGEMENT = (serviceNames) => `Please contact Order Management team to process ${serviceNames} service`;
const OFFICE = 'Office';
const ENGAGE_DIGITAL_STANDALONE = 'Engage Digital Standalone';
const ENGAGE_VOICE_STANDALONE = 'Engage Voice Standalone';
const ENGAGE_DIGITAL_LEGACY = 'Engage Digital Legacy';
const ENGAGE_VOICE_LEGACY = 'Engage Voice Legacy';
const RING_CENTRAL_CONTACT_CENTER = 'RingCentral Contact Center';
const TIER_FAX = 'Fax';
const TIER_PROFESSIONAL_SERVICES = 'Professional Services';
const BRAND_RINGCENTRAL = 'RingCentral';
const BRAND_RINGCENTRAL_CA = 'RingCentral Canada';
const BRAND_RINGCENTRAL_UK = 'RingCentral UK';
const BRAND_RINGCENTRAL_EU = 'RingCentral EU';
const BRAND_RINGCENTRAL_AU = 'RingCentral AU';
const INR = 'INR';
const EMPTY_FAX_URL = 'The Sign Up request is currently unavailable';
const ERROR = 'error';
const INFO = 'info';
const MEETINGS = 'Meetings';
const INITIAL_NGBS_ACCOUNT_STATUS = 'Initial';
const ACTIVE_NGBS_ACCOUNT_STATUS = 'Active';
const POC = 'POC Quote';
const SALES = 'Sales Quote';
const PROSERV = 'ProServ Quote';
const CC_PROSERV = 'CC ProServ Quote';
const MIGRATION_IN_PROGRESS_TITLE = "This Contact Center account is being migrated to NGBS."
const MIGRATION_IN_PROGRESS = "If an urgent change order is needed, please fill out the Request to Unblock an Account form.";
const SUSPENDED_ACCOUNT_ERROR_MSG = "You are working with Suspended Account. You might need to check validity of the Payment Method of the Account.";
const WRONG_COUNTRY_BRAND = 'No matching Business Identity was found for the specified Country and Brand. ' +
    'If you are certain that the lead\'s Country and Brand information is accurate, kindly create a case for further assistance.';
const ADMIN_PREVIEW = 'Admin Preview';
const REQUEST_PREVIEW_PLACEHOLDER = 'Generating Request Preview...'
const COPY_JSON = 'Copy JSON';
const SIGN_UP = 'Sign Up';
const CC_SYNC_STATUS_STARTED = 'Started';
const DEFAULT_SYNC_ERROR = 'Error - Sync to NGBS';
const RC_EVENT = 'RC Events';
const TIER_RC_EVENT = 'Events';

const REQUIRES_MVP_SERVICE_COMPLETED = (serviceDisplayName) => `${serviceDisplayName} requires MVP service to be completed or synced first`;
const REQUIRES_PAID_OFFICE_COMPLETION = (serviceDisplayName) => `Paid ${serviceDisplayName} requires completion of Paid Office service`;
const REQUIRES_POC_OFFICE_COMPLETION = (serviceDisplayName) => `POC ${serviceDisplayName} requires completion of POC Office service`;
const SIGNUP_BLOCKED_MESSAGE = (isExistingBusiness, errorMessage) => `${isExistingBusiness ? "Sync" : "Sign-up"} blocked: ${errorMessage}`;
const POC_DEALS_RESTRICTED_FOR_STANDALONE = (serviceDisplayName) => `Sign up of POC deals is restricted for ${serviceDisplayName} Standalone accounts`;

const TIER_MAP = new Map([
    [OFFICE, {tier: MVP, order: 1}],
    [RING_CENTRAL_CONTACT_CENTER, {tier: CONTACT_CENTER, order: 2}],
    [ENGAGE_VOICE_STANDALONE, {tier: ENGAGE_VOICE, order: 3}],
    [ENGAGE_DIGITAL_STANDALONE, {tier: ENGAGE_DIGITAL, order: 4}],
    [ENGAGE_VOICE_LEGACY, {tier: ENGAGE_VOICE, order: 5}],
    [ENGAGE_DIGITAL_LEGACY, {tier: ENGAGE_DIGITAL, order: 6}],
    [MEETINGS, {tier: MEETINGS, order: 7}],
    [TIER_FAX, {tier: TIER_FAX, order: 8}],
    [TIER_PROFESSIONAL_SERVICES, {tier: TIER_PROFESSIONAL_SERVICES, order: 9}],
    [TIER_RC_EVENT, {tier: RC_EVENT, order: 10}],
]);

const TIME_ZONE_OPTIONS_ENGAGE = [
    { value: "America/Sao_Paulo", label: "Brasilia" },
    { value: "Asia/Vladivostok", label: "Vladivostok" },
    { value: "Africa/Nairobi", label: "Nairobi" },
    { value: "America/Fortaleza", label: "Georgetown" },
    { value: "Europe/Berlin", label: "Berlin" },
    { value: "Pacific/Pago_Pago", label: "American Samoa" },
    { value: "Europe/Moscow", label: "Moscow" },
    { value: "Pacific/Honolulu", label: "Hawaii" },
    { value: "Australia/Hobart", label: "Hobart" },
    { value: "Asia/Ulaanbaatar", label: "Ulaanbaatar" },
    { value: "Asia/Baghdad", label: "Baghdad" },
    { value: "Asia/Shanghai", label: "Beijing" },
    { value: "America/Tijuana", label: "Tijuana" },
    { value: "Asia/Yerevan", label: "Yerevan" },
    { value: "Asia/Kamchatka", label: "Kamchatka" },
    { value: "Etc/GMT+12", label: "International Date Line West" },
    { value: "Africa/Tripoli", label: "Harare" },
    { value: "America/Chihuahua", label: "Chihuahua" },
    { value: "Europe/Warsaw", label: "Warsaw" },
    { value: "US/Central", label: "Central Time (US & Canada)" },
    { value: "Asia/Yakutsk", label: "Yakutsk" },
    { value: "America/Indianapolis", label: "Indianapolis" },
    { value: "Pacific/Fiji", label: "Fiji" },
    { value: "Europe/Belgrade", label: "Belgrade" },
    { value: "America/Santiago", label: "Santiago" },
    { value: "Asia/Baku", label: "Baku" },
    { value: "Asia/Tehran", label: "Tehran" },
    { value: "America/Anchorage", label: "Anchorage" },
    { value: "America/La_Paz", label: "La Paz" },
    { value: "Asia/Taipei", label: "Taipei" },
    { value: "Asia/Tashkent", label: "Tashkent" },
    { value: "Asia/Bangkok", label: "Bangkok" },
    { value: "Australia/Adelaide", label: "Adelaide" },
    { value: "America/Phoenix", label: "Phoenix" },
    { value: "Europe/Sofia", label: "Sofia" },
    { value: "Asia/Dubai", label: "Abu Dhabi" },
    { value: "America/Mexico_City", label: "Mexico City" },
    { value: "Pacific/Noumea", label: "New Caledonia" },
    { value: "Asia/Tbilisi", label: "Tbilisi" },
    { value: "Asia/Jerusalem", label: "Jerusalem" },
    { value: "America/Montevideo", label: "Montevideo" },
    { value: "America/Noronha", label: "Noronha" },
    { value: "Europe/Lisbon", label: "Lisbon" },
    { value: "Asia/Gaza", label: "Gaza" },
    { value: "Australia/Perth", label: "Perth" },
    { value: "Australia/Darwin", label: "Darwin" },
    { value: "Asia/Rangoon", label: "Rangoon" },
    { value: "Asia/Kuwait", label: "Kuwait" },
    { value: "America/Bogota", label: "Bogota" },
    { value: "Asia/Kabul", label: "Kabul" },
    { value: "Pacific/Tongatapu", label: "Nuku\'alofa" },
    { value: "US/Eastern", label: "Eastern Time (US & Canada)" },
    { value: "Atlantic/Azores", label: "Azores" },
    { value: "Asia/Krasnoyarsk", label: "Krasnoyarsk" },
    { value: "America/Godthab", label: "Godthab" },
    { value: "Asia/Calcutta", label: "Kolkata" },
    { value: "Europe/Minsk", label: "Minsk" },
    { value: "Pacific/Auckland", label: "Magadan" },
    { value: "GMT", label: "Casablanca" },
    { value: "America/Caracas", label: "Caracas" },
    { value: "Asia/Magadan", label: "Magadan" },
    { value: "Pacific/Guam", label: "Guam" },
    { value: "Africa/Algiers", label: "Algiers" },
    { value: "Asia/Irkutsk", label: "Irkutsk" },
    { value: "America/St_Johns", label: "Newfoundland" },
    { value: "US/Mountain", label: "Mountain Time (US & Canada)" },
    { value: "Asia/Kathmandu", label: "Kathmandu" },
    { value: "Australia/Sydney", label: "Sydney" },
    { value: "Asia/Tokyo", label: "Tokyo" },
    { value: "Asia/Colombo", label: "Colombo" },
    { value: "Asia/Singapore", label: "Singapore" },
    { value: "Canada/Saskatchewan", label: "Saskatchewan" },
    { value: "America/Regina", label: "Regina" },
    { value: "Asia/Seoul", label: "Seoul" },
    { value: "Asia/Pyongyang", label: "Pyongyang" },
    { value: "US/Pacific", label: "Pacific Time (US & Canada)" },
    { value: "Canada/Atlantic", label: "Atlantic Time (Canada)" },
    { value: "America/Cuiaba", label: "Cuiaba" },
    { value: "Asia/Bishkek", label: "Bishkek" },
    { value: "Asia/Omsk", label: "Omsk" },
    { value: "Europe/Paris", label: "Paris" },
    { value: "Africa/Windhoek", label: "Windhoek" },
    { value: "Africa/Cairo", label: "Cairo" },
    { value: "Asia/Damascus", label: "Damascus" },
    { value: "Asia/Beirut", label: "Beirut" },
    { value: "Asia/Amman", label: "Amman" },
    { value: "Australia/Brisbane", label: "Brisbane" },
    { value: "America/Argentina/Buenos_Aires", label: "Buenos Aires" },
    { value: "Atlantic/Cape_Verde", label: "Cape Verde Is." },
    { value: "Asia/Yekaterinburg", label: "Yekaterinburg" },
    { value: "Europe/Athens", label: "Athens" }
];

const LANGUAGE_OPTIONS_ENGAGE = [
    { label: "English", value: "en-US" },
    { label: "German", value: "de-DE" },
    { label: "French", value: "fr-CA" },
    { label: "Spanish", value: "es-ES" }
];

const ACCOUNT_MIGRATION_STATUSES = {
    BLOCKING_ACCOUNT_MIGRATION_STATUSES: [
        'ScheduledBlocked',
        'InProgressBlocked',
    ],

    IN_PROGRESS_ACCOUNT_MIGRATION_STATUSES: [
        'Scheduled',
        'InProgress',
    ]
}

const ACCOUNT_INACTIVE_STATUSES = [
    'Canceled', 'Cancelled', 'Deleted', 'Disabled', 'Terminated'
];

const BRAND_NAMES = new Map([
    [BRAND_RINGCENTRAL, 'US'],
    [BRAND_RINGCENTRAL_CA, 'CA'],
    [BRAND_RINGCENTRAL_UK, 'UK'],
    [BRAND_RINGCENTRAL_EU, 'EU'],
    [BRAND_RINGCENTRAL_AU, 'AU'],
]);

export {
    ACTIVE,
    COMPLETED,
    OFF,
    READY,
    TIME_ZONE_OPTIONS_ENGAGE,
    LANGUAGE_OPTIONS_ENGAGE,
    CHOOSE_PRIMARY_QUOTE,
    ORDERS_CREATION,
    QUERYING_DATA,
    VALIDATION,
    PREPARING_CASES,
    PREPARING,
    FUNNEL_REQUEST,
    PROCESSING,
    SYNCED,
    MVP,
    ENGAGE_DIGITAL,
    ENGAGE_VOICE,
    CONTACT_CENTER,
    READY_TO_FUNNEL,
    SIGN_UP_IN_PROCESS,
    SIGNED_UP,
    CONTACT_ORDER_MANAGEMENT,
    TIER_MAP,
    OFFICE,
    ENGAGE_DIGITAL_STANDALONE,
    ENGAGE_VOICE_STANDALONE,
    RING_CENTRAL_CONTACT_CENTER,
    TIER_FAX,
    BRAND_RINGCENTRAL,
    BRAND_RINGCENTRAL_CA,
    EMPTY_FAX_URL,
    ERROR,
    INFO,
    MEETINGS,
    INITIAL_NGBS_ACCOUNT_STATUS,
    ACTIVE_NGBS_ACCOUNT_STATUS,
    ACCOUNT_INACTIVE_STATUSES,
    POC,
    SALES,
    MIGRATION_IN_PROGRESS_TITLE,
    MIGRATION_IN_PROGRESS,
    ACCOUNT_MIGRATION_STATUSES,
    SUSPENDED_ACCOUNT_ERROR_MSG,
    BRAND_NAMES,
    WRONG_COUNTRY_BRAND,
    TIER_PROFESSIONAL_SERVICES,
    ADMIN_PREVIEW,
    SIGN_UP,
    COPY_JSON,
    REQUEST_PREVIEW_PLACEHOLDER,
    PROSERV,
    CC_PROSERV,
    READY_TO_CREATE_MAIN_COST_CENTER,
    COST_CENTER_CREATED,
    PROSERV_SIGNUP_REQUEST_SEND,
    CC_SYNC_STATUS_STARTED,
    DEFAULT_SYNC_ERROR,
    RC_EVENT,
    TIER_RC_EVENT,
    REQUIRES_MVP_SERVICE_COMPLETED,
    REQUIRES_PAID_OFFICE_COMPLETION,
    REQUIRES_POC_OFFICE_COMPLETION,
    SIGNUP_BLOCKED_MESSAGE,
    POC_DEALS_RESTRICTED_FOR_STANDALONE,
};