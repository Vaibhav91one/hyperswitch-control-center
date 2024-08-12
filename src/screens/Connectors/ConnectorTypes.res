type steps = IntegFields | PaymentMethods | SummaryAndTest | Preview | AutomaticFlow
type connectorIntegrationField = {
  placeholder?: string,
  label?: string,
  name: string,
  isRequired?: bool,
  encodeToBase64?: bool,
  liveValidationRegex?: string,
  testValidationRegex?: string,
  liveExpectedFormat?: string,
  testExpectedFormat?: string,
  description?: string,
}

type metadataFields = {
  google_pay?: array<connectorIntegrationField>,
  apple_pay?: array<connectorIntegrationField>,
}
type integrationFields = {
  description: string,
  validate?: array<connectorIntegrationField>,
  inputFieldDescription?: string,
}

type verifyResponse = Success | Failure | NoAttempt | Loading
type authType = [#HeaderKey | #BodyKey | #SignatureKey | #MultiAuthKey | #CurrencyAuthKey | #Nokey]
type cashToCodeMthd = [#Classic | #Evoucher]

type processorTypes =
  | ADYEN
  | ADYENPLATFORM
  | CHECKOUT
  | BRAINTREE
  | BANKOFAMERICA
  | BILLWERK
  | AUTHORIZEDOTNET
  | STRIPE
  | KLARNA
  | GLOBALPAY
  | BLUESNAP
  | AIRWALLEX
  | WORLDPAY
  | CYBERSOURCE
  | EBANX
  | ACI
  | WORLDLINE
  | FISERV
  | SHIFT4
  | RAPYD
  | PAYU
  | NUVEI
  | DLOCAL
  | MULTISAFEPAY
  | BAMBORA
  | MOLLIE
  | TRUSTPAY
  | ZEN
  | PAYPAL
  | COINBASE
  | OPENNODE
  | PHONYPAY
  | FAUXPAY
  | PRETENDPAY
  | NMI
  | FORTE
  | NEXINETS
  | IATAPAY
  | BITPAY
  | CRYPTOPAY
  | CASHTOCODE
  | PAYME
  | GLOBEPAY
  | POWERTRANZ
  | TSYS
  | NOON
  | STRIPE_TEST
  | PAYPAL_TEST
  | STAX
  | WISE
  | GOCARDLESS
  | VOLT
  | PROPHETPAY
  | HELCIM
  | PLACETOPAY
  | ZSL
  | MIFINITY
  | RAZORPAY
  | BAMBORA_APAC
  | ITAUBANK
  | DATATRANS
  | PLAID

type threeDsAuthenticatorTypes = THREEDSECUREIO | NETCETERA

type frmTypes =
  | Signifyd
  | Riskifyed

type pmAuthenticationProcessorTypes = PLAID

type connectorTypes =
  | Processors(processorTypes)
  | ThreeDsAuthenticator(threeDsAuthenticatorTypes)
  | FRM(frmTypes)
  | PMAuthenticationProcessor(pmAuthenticationProcessorTypes)
  | UnknownConnector(string)

type paymentMethod =
  | Card
  | PayLater
  | Wallet
  | BankRedirect
  | BankTransfer
  | Crypto
  | BankDebit
  | UnknownPaymentMethod(string)

type paymentMethodTypes =
  | Credit
  | Debit
  | GooglePay
  | ApplePay
  | PayPal
  | BankDebit
  | UnknownPaymentMethodType(string)

type advancedConfigurationList = {
  @as("type") type_: string,
  list: array<string>,
}

type advancedConfiguration = {options: advancedConfigurationList}

type paymentMethodConfigType = {
  payment_method_type: string,
  card_networks: array<string>,
  accepted_currencies: option<advancedConfigurationList>,
  accepted_countries: option<advancedConfigurationList>,
  minimum_amount: option<int>,
  maximum_amount: option<int>,
  recurring_enabled: option<bool>,
  installment_payment_enabled: option<bool>,
  payment_experience: option<string>,
}

type paymentMethodEnabled = {
  payment_method: string,
  payment_method_type: string,
  provider?: array<paymentMethodConfigType>,
  card_provider?: array<paymentMethodConfigType>,
}

type applePay = {
  merchant_identifier: string,
  certificate: string,
  display_name: string,
  initiative_context: string,
  certificate_keys: string,
}
type googlePay = {
  merchant_name: string,
  publishable_key?: string,
  merchant_id: string,
}

type metaData = {
  apple_pay?: applePay,
  goole_pay?: googlePay,
}
type pmAuthPaymentMethods = {
  payment_method: string,
  payment_method_type: string,
  connector_name: string,
  mca_id: string,
}

type pmAuthDict = {enabled_payment_methods: array<pmAuthPaymentMethods>}

type paymentMethodConfig = {
  bank_redirect?: option<array<string>>,
  bank_transfer?: option<array<string>>,
  credit_card?: option<array<string>>,
  debit_card?: option<array<string>>,
  pay_later?: option<array<string>>,
  wallets?: option<array<string>>,
}

type wasmRequest = {
  payment_methods_enabled: array<paymentMethodEnabled>,
  connector: string,
  metadata: JSON.t,
}

type wasmExtraPayload = {
  profile_id: string,
  connector_type: string,
  connector_name: string,
  connector_account_details: JSON.t,
  disabled: bool,
  test_mode: bool,
  connector_webhook_details: option<JSON.t>,
}

// This type are used for FRM configuration which need to moved to wasm

type connectorAccountDetails = {
  auth_type: string,
  api_secret?: string,
  api_key?: string,
  key1?: string,
  key2?: string,
}

type paymentMethodEnabledType = {
  payment_method: string,
  payment_method_types: array<paymentMethodConfigType>,
}

type payment_methods_enabled = array<paymentMethodEnabledType>

type frm_payment_method_type = {
  payment_method_type: string,
  mutable flow: string,
  mutable action: string,
}

type frm_payment_method = {
  payment_method: string,
  payment_method_types: array<frm_payment_method_type>,
}

type frm_config = {
  gateway: string,
  mutable payment_methods: array<frm_payment_method>,
}

type connectorPayload = {
  connector_type: string,
  connector_name: string,
  connector_label: string,
  connector_account_details: connectorAccountDetails,
  test_mode: bool,
  disabled: bool,
  payment_methods_enabled: payment_methods_enabled,
  profile_id: string,
  metadata?: JSON.t,
  merchant_connector_id: string,
  frm_configs?: array<frm_config>,
  status: string,
}

type connector =
  FRMPlayer | Processor | PayoutConnector | ThreeDsAuthenticator | PMAuthenticationProcessor

type connectorTypeVariants =
  PaymentProcessor | PaymentVas | PayoutProcessor | AuthenticationProcessor | PMAuthProcessor
