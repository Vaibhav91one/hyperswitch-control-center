let headerTextStyle = "text-xl font-semibold text-grey-700"
let subTextStyle = "text-base font-normal text-grey-700 opacity-50"
let dividerColor = "bg-grey-700 bg-opacity-20 h-px w-full"
let highlightedText = "text-base font-normal text-blue-700 underline"

@react.component
let make = (
  ~amount=100,
  ~returnUrl,
  ~currency="USD",
  ~onProceed: (~paymentId: string) => promise<unit>,
  ~profileId=?,
  ~sdkWidth="w-[60%]",
  ~isTestCredsNeeded=true,
  ~customWidth="w-full md:w-1/2",
  ~paymentStatusStyles="p-11",
  ~successButtonText="Proceed",
  ~keyValue,
) => {
  open APIUtils
  open LogicUtils
  open HyperSwitchTypes

  let updateDetails = useUpdateMethod(~showErrorToast=false, ())
  let (clientSecret, setClientSecret) = React.useState(_ => None)
  let (paymentStatus, setPaymentStatus) = React.useState(_ => INCOMPLETE)
  let (paymentId, setPaymentId) = React.useState(_ => "")
  let merchantDetailsValue = HSwitchUtils.useMerchantDetailsValue()
  let publishableKey = merchantDetailsValue->getDictFromJsonObject->getString("publishable_key", "")
  let paymentElementOptions = CheckoutHelper.getOptionReturnUrl(returnUrl)
  let elementOptions = CheckoutHelper.getOption(clientSecret)
  let url = RescriptReactRouter.useUrl()
  let searchParams = url.search
  let filtersFromUrl = getDictFromUrlSearchParams(searchParams)
  let businessProfiles = Recoil.useRecoilValueFromAtom(HyperswitchAtom.businessProfilesAtom)
  let defaultBusinessProfile =
    businessProfiles->HSwitchMerchantAccountUtils.getValueFromBusinessProfile

  let getClientSecret = async () => {
    try {
      let url = `${HSwitchGlobalVars.hyperSwitchApiPrefix}/payments`
      let body =
        Js.Dict.fromArray([
          ("currency", currency->Js.Json.string),
          ("amount", amount->Belt.Int.toFloat->Js.Json.number),
          (
            "profile_id",
            profileId
            ->Belt.Option.getWithDefault(defaultBusinessProfile.profile_id)
            ->Js.Json.string,
          ),
        ])->Js.Json.object_
      let response = await updateDetails(url, body, Post)
      let clientSecret = response->getDictFromJsonObject->getOptionString("client_secret")
      setPaymentId(_ => response->getDictFromJsonObject->getString("payment_id", ""))
      setClientSecret(_ => clientSecret)
      setPaymentStatus(_ => INCOMPLETE)
    } catch {
    | _ => setPaymentStatus(_ => FAILED(""))
    }
  }

  React.useEffect1(() => {
    let status =
      filtersFromUrl->Js.Dict.get("status")->Belt.Option.getWithDefault("")->Js.String2.toLowerCase
    if status === "succeeded" {
      setPaymentStatus(_ => SUCCESS)
    } else if status === "failed" {
      setPaymentStatus(_ => FAILED(""))
    } else if status === "processing" {
      setPaymentStatus(_ => PROCESSING)
    } else {
      setPaymentStatus(_ => INCOMPLETE)
    }
    if status->Js.String2.length <= 0 && keyValue->Js.String2.length > 0 {
      getClientSecret()->ignore
    }
    None
  }, [keyValue])

  <div className={`flex flex-col gap-12 h-full ${paymentStatusStyles}`}>
    {switch paymentStatus {
    | SUCCESS =>
      <ProdOnboardingUIUtils.BasicAccountSetupSuccessfulPage
        iconName="account-setup-completed"
        statusText="Payment Successful"
        buttonText=successButtonText
        buttonOnClick={_ => onProceed(~paymentId)->ignore}
        customWidth
        bgColor="bg-green-success_page_bg"
      />

    | FAILED(_err) =>
      <ProdOnboardingUIUtils.BasicAccountSetupSuccessfulPage
        iconName="account-setup-failed"
        statusText="Payment Failed"
        buttonText=successButtonText
        buttonOnClick={_ => onProceed(~paymentId)->ignore}
        customWidth
        bgColor="bg-red-failed_page_bg"
      />
    | CHECKCONFIGURATION =>
      <ProdOnboardingUIUtils.BasicAccountSetupSuccessfulPage
        iconName="processing"
        statusText="Check your Configurations"
        buttonText=successButtonText
        buttonOnClick={_ => onProceed(~paymentId)->ignore}
        customWidth
        bgColor="bg-yellow-pending_page_bg"
      />

    | PROCESSING =>
      <ProdOnboardingUIUtils.BasicAccountSetupSuccessfulPage
        iconName="processing"
        statusText="Payment Pending"
        buttonText=successButtonText
        buttonOnClick={_ => onProceed(~paymentId)->ignore}
        customWidth
        bgColor="bg-yellow-pending_page_bg"
      />
    | _ => React.null
    }}
    {switch clientSecret {
    | Some(val) =>
      if isTestCredsNeeded {
        <div className="flex gap-8">
          <div className=sdkWidth>
            <WebSDK
              clientSecret=val
              publishableKey
              sdkType=ELEMENT
              paymentStatus
              currency
              setPaymentStatus
              elementOptions
              paymentElementOptions
              returnUrl
              amount
              setClientSecret
            />
          </div>
          <TestCredentials />
        </div>
      } else {
        <WebSDK
          clientSecret=val
          publishableKey
          sdkType=ELEMENT
          paymentStatus
          currency
          setPaymentStatus
          elementOptions
          paymentElementOptions
          returnUrl
          amount
          setClientSecret
        />
      }
    | None => React.null
    }}
  </div>
}
