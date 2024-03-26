type featureFlag = {
  default: bool,
  productionAccess: bool,
  testLiveToggle: bool,
  magicLink: bool,
  quickStart: bool,
  switchMerchant: bool,
  isLiveMode: bool,
  auditTrail: bool,
  systemMetrics: bool,
  sampleData: bool,
  frm: bool,
  payOut: bool,
  recon: bool,
  testProcessors: bool,
  feedback: bool,
  generateReport: bool,
  businessProfile: bool,
  mixpanel: bool,
  mixpanelSdk: bool,
  verifyConnector: bool,
  forgetPassword: bool,
  userJourneyAnalytics: bool,
  surcharge: bool,
  disputeEvidenceUpload: bool,
  paypalAutomaticFlow: bool,
  acceptInvite: bool,
  threedsAuthenticator: bool,
}

let featureFlagType = (featureFlags: JSON.t) => {
  open LogicUtils
  let dict = featureFlags->getDictFromJsonObject
  let typedFeatureFlag: featureFlag = {
    default: dict->getBool("default", true),
    productionAccess: dict->getBool("production_access", false),
    testLiveToggle: dict->getBool("test_live_toggle", false),
    magicLink: dict->getBool("magic_link", false),
    quickStart: dict->getBool("quick_start", false),
    switchMerchant: dict->getBool("switch_merchant", false),
    isLiveMode: dict->getBool("is_live_mode", false),
    auditTrail: dict->getBool("audit_trail", false),
    systemMetrics: dict->getBool("system_metrics", false),
    sampleData: dict->getBool("sample_data", false),
    frm: dict->getBool("frm", false),
    payOut: dict->getBool("payout", false),
    recon: dict->getBool("recon", false),
    testProcessors: dict->getBool("test_processors", false),
    feedback: dict->getBool("feedback", false),
    generateReport: dict->getBool("generate_report", false),
    businessProfile: dict->getBool("business_profile", false),
    mixpanel: dict->getBool("mixpanel", false),
    mixpanelSdk: dict->getBool("mixpanel_sdk", false),
    verifyConnector: dict->getBool("verify_connector", false),
    forgetPassword: dict->getBool("forgot_password", false),
    userJourneyAnalytics: dict->getBool("user_journey_analytics", false),
    surcharge: dict->getBool("surcharge", false),
    disputeEvidenceUpload: dict->getBool("dispute_evidence_upload", false),
    paypalAutomaticFlow: dict->getBool("paypal_automatic_flow", false),
    acceptInvite: dict->getBool("accept-invite", false),
    threedsAuthenticator: dict->getBool("threeds-authenticator", false),
  }
  typedFeatureFlag
}
