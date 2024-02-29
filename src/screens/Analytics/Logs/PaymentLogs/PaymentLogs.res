@react.component
let make = (~paymentId, ~createdAt) => {
  open APIUtils
  open LogicUtils
  open PaymentLogsUtils
  open LogTypes
  let fetchDetails = useGetMethod(~showErrorToast=false, ())
  let fetchPostDetils = useUpdateMethod()
  let (data, setData) = React.useState(_ => [])
  let isError = React.useMemo0(() => {ref(false)})
  let (logDetails, setLogDetails) = React.useState(_ => {
    response: "",
    request: "",
  })
  let (selectedOption, setSelectedOption) = React.useState(_ => {
    value: 0,
    optionType: API_EVENTS,
  })
  let (screenState, setScreenState) = React.useState(_ => PageLoaderWrapper.Loading)

  let apiLogsUrl = getURL(~entityName=PAYMENT_LOGS, ~methodType=Get, ~id=Some(paymentId), ())
  let sdkLogsUrl = getURL(~entityName=SDK_EVENT_LOGS, ~methodType=Post, ~id=Some(paymentId), ())
  let startTime = createdAt->Date.fromString->Date.getTime -. 1000. *. 60. *. 5.
  let startTime = startTime->Js.Date.fromFloat->Date.toISOString
  let endTime = createdAt->Date.fromString->Date.getTime +. 1000. *. 60. *. 60. *. 3.
  let endTime = endTime->Js.Date.fromFloat->Date.toISOString
  let sdkPostBody =
    [
      ("paymentId", paymentId->JSON.Encode.string),
      (
        "timeRange",
        [("startTime", startTime->JSON.Encode.string), ("endTime", endTime->JSON.Encode.string)]
        ->Dict.fromArray
        ->JSON.Encode.object,
      ),
    ]->getJsonFromArrayOfJson
  let webhookLogsUrl = getURL(
    ~entityName=WEBHOOKS_EVENT_LOGS,
    ~methodType=Get,
    ~id=Some(paymentId),
    (),
  )
  let connectorLogsUrl = getURL(
    ~entityName=CONNECTOR_EVENT_LOGS,
    ~methodType=Get,
    ~id=Some(paymentId),
    (),
  )

  let getDetails = async () => {
    let logs = []
    if !(paymentId->HSwitchOrderUtils.isTestData) {
      let resArr = await PromiseUtils.allSettledPolyfill([
        fetchDetails(apiLogsUrl),
        fetchPostDetils(sdkLogsUrl, sdkPostBody, Post, ()),
        fetchDetails(webhookLogsUrl),
        fetchDetails(connectorLogsUrl),
      ])

      resArr->Array.forEach(json => {
        // clasify btw json value and error response
        switch JSON.Classify.classify(json) {
        | Array(arr) =>
          // add to the logs only if array is non empty
          switch arr->Array.get(0) {
          | Some(dict) =>
            switch dict->getDictFromJsonObject->getLogType {
            | SDK => logs->Array.pushMany(arr->parseSdkResponse)->ignore
            | CONNECTOR | API_EVENTS => logs->Array.pushMany(arr)->ignore
            | WEBHOOKS => logs->Array.pushMany([dict])->ignore
            }
          | _ => ()
          }
        | String(_) => isError.contents = true
        | _ => ()
        }
      })

      if logs->Array.length === 0 && isError.contents {
        setScreenState(_ => PageLoaderWrapper.Error("Failed to Fetch!"))
      } else {
        setScreenState(_ => PageLoaderWrapper.Success)
        let newLogs = logs->Js.Array2.sortInPlaceWith(LogUtils.sortByCreatedAt)
        setData(_ => newLogs)
        switch logs->Array.get(0) {
        | Some(value) => {
            let initialData = value->getDictFromJsonObject
            initialData->setDefaultValue(setLogDetails, setSelectedOption)
          }
        | _ => ()
        }
      }
    } else {
      setScreenState(_ => PageLoaderWrapper.Custom)
    }
  }

  React.useEffect0(() => {
    getDetails()->ignore
    None
  })

  let headerText = switch selectedOption.optionType {
  | API_EVENTS | CONNECTOR => "Response body"
  | WEBHOOKS => "Request body"
  | SDK => "Metadata"
  }->Some

  let timeLine =
    <div className="flex flex-col w-2/5 overflow-y-scroll pt-7 pl-5">
      <div className="flex flex-col">
        {data
        ->Array.mapWithIndex((paymentDetailsValue, index) => {
          <ApiDetailsComponent
            key={index->Int.toString}
            dataDict={paymentDetailsValue->getDictFromJsonObject}
            setLogDetails
            setSelectedOption
            currentSelected=selectedOption.value
            index
            logsDataLength={data->Array.length - 1}
            getLogType
            nameToURLMapper={nameToURLMapper(~id={paymentId})}
            filteredKeys
          />
        })
        ->React.array}
      </div>
    </div>

  let requestHeader = switch selectedOption.optionType {
  | API_EVENTS | CONNECTOR => "Request body"
  | SDK => "Event"
  | WEBHOOKS => ""
  }

  let codeBlock =
    <UIUtils.RenderIf
      condition={logDetails.response->isNonEmptyString || logDetails.request->isNonEmptyString}>
      <div
        className="flex flex-col gap-4 border-l-1 border-border-light-grey show-scrollbar scroll-smooth overflow-scroll px-5 py-3 w-3/5">
        <UIUtils.RenderIf
          condition={logDetails.request->isNonEmptyString &&
            selectedOption.optionType !== WEBHOOKS}>
          <PrettyPrintJson
            jsonToDisplay=logDetails.request
            headerText={requestHeader->Some}
            maxHeightClass={logDetails.response->String.length > 0 ? "max-h-25-rem" : ""}
          />
        </UIUtils.RenderIf>
        <UIUtils.RenderIf condition={logDetails.response->isNonEmptyString}>
          <PrettyPrintJson jsonToDisplay={logDetails.response} headerText />
        </UIUtils.RenderIf>
      </div>
    </UIUtils.RenderIf>

  open OrderUtils
  <PageLoaderWrapper
    screenState customUI={<NoDataFound message="No logs available for this payment" />}>
    {if paymentId->HSwitchOrderUtils.isTestData || data->Array.length === 0 {
      <div
        className="flex items-center gap-2 bg-white w-full border-2 p-3 !opacity-100 rounded-lg text-md font-medium">
        <Icon name="info-circle-unfilled" size=16 />
        <div className={`text-lg font-medium opacity-50`}>
          {"No logs available for this payment"->React.string}
        </div>
      </div>
    } else {
      <Section
        customCssClass={`bg-white dark:bg-jp-gray-lightgray_background rounded-md pt-2 pb-4 flex gap-7 justify-between h-48-rem !max-h-50-rem !min-w-[55rem] max-w-[72rem] overflow-scroll`}>
        {timeLine}
        {codeBlock}
      </Section>
    }}
  </PageLoaderWrapper>
}