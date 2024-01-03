type filterBody = {
  start_time: string,
  end_time: string,
}

let isStringNonEmpty = str => str->Js.String2.length > 0

let getDateValue = (key, ~getModuleFilters) => {
  getModuleFilters->Js.Dict.get(key)->Belt.Option.getWithDefault("")
}

let formateDateString = date => {
  date->Js.Date.toISOString->TimeZoneHook.formattedISOString("YYYY-MM-DDTHH:mm:[00][Z]")
}

let getDateFilteredObject = () => {
  let currentDate = Js.Date.make()

  let end_time = currentDate->formateDateString

  let start_time =
    Js.Date.makeWithYMD(
      ~year=currentDate->Js.Date.getFullYear,
      ~month=currentDate->Js.Date.getMonth,
      ~date=currentDate->Js.Date.getDate,
      (),
    )
    ->Js.Date.setDate((currentDate->Js.Date.getDate->Belt.Float.toInt - 7)->Belt.Int.toFloat)
    ->Js.Date.fromFloat
    ->formateDateString

  {
    start_time,
    end_time,
  }
}

let getFilterFields: Js.Json.t => array<EntityType.optionType<'t>> = json => {
  open LogicUtils
  let filterDict = json->getDictFromJsonObject

  filterDict
  ->Js.Dict.keys
  ->Array.reduce([], (acc, key) => {
    let title = `Select ${key->snakeToTitle}`
    let values = filterDict->getArrayFromDict(key, [])->getStrArrayFromJsonArray

    let dropdownOptions: EntityType.optionType<'t> = {
      urlKey: key,
      field: {
        FormRenderer.makeFieldInfo(
          ~label="",
          ~name=key,
          ~customInput=InputFields.multiSelectInput(
            ~options={
              values
              ->SelectBox.makeOptions
              ->Js.Array2.map(item => {
                let value = {...item, label: item.value}
                value
              })
            },
            ~buttonText=title,
            ~showSelectionAsChips=false,
            ~searchable=true,
            ~showToolTip=true,
            ~showNameAsToolTip=true,
            ~customButtonStyle="bg-none",
            (),
          ),
          (),
        )
      },
      parser: val => val,
      localFilter: None,
    }

    if values->Js.Array2.length > 0 {
      acc->Array.push(dropdownOptions)
    }
    acc
  })
}

let useSetInitialFilters = (~updateExistingKeys, ~startTimeFilterKey, ~endTimeFilterKey) => {
  let {filterValueJson} = FilterContext.filterContext->React.useContext

  () => {
    let inititalSearchParam = Js.Dict.empty()

    let defaultDate = getDateFilteredObject()

    if filterValueJson->Js.Dict.keys->Js.Array2.length < 1 {
      [
        (startTimeFilterKey, defaultDate.start_time),
        (endTimeFilterKey, defaultDate.end_time),
      ]->Belt.Array.forEach(item => {
        let (key, defaultValue) = item
        switch inititalSearchParam->Js.Dict.get(key) {
        | Some(_) => ()
        | None => inititalSearchParam->Js.Dict.set(key, defaultValue)
        }
      })

      inititalSearchParam->updateExistingKeys
    }
  }
}

let useGetFiltersData = () => {
  open APIUtils
  open Promise
  open LogicUtils
  let (filterData, setFilterData) = React.useState(_ => None)
  let updateDetails = useUpdateMethod()
  let {filterValueJson} = FilterContext.filterContext->React.useContext
  let startTimeVal = filterValueJson->getString("start_time", "")
  let endTimeVal = filterValueJson->getString("end_time", "")

  (url, body) => {
    React.useEffect3(() => {
      setFilterData(_ => None)
      if startTimeVal->isStringNonEmpty && endTimeVal->isStringNonEmpty {
        try {
          updateDetails(url, body->Js.Json.object_, Post)
          ->thenResolve(json => setFilterData(_ => json->Some))
          ->catch(_ => resolve())
          ->ignore
        } catch {
        | _ => ()
        }
      }
      None
    }, (startTimeVal, endTimeVal, body->Js.Json.object_->Js.Json.stringify))
    filterData
  }
}

module SearchBarFilter = {
  @react.component
  let make = (~placeholder, ~setSearchVal, ~searchVal) => {
    let (searchValBase, setSearchValBase) = React.useState(_ => "")
    let onChange = ev => {
      let value = ReactEvent.Form.target(ev)["value"]
      setSearchValBase(_ => value)
    }

    React.useEffect1(() => {
      let onKeyPress = event => {
        let keyPressed = event->ReactEvent.Keyboard.key

        if keyPressed == "Enter" {
          setSearchVal(_ => searchValBase)
        }
      }
      Window.addEventListener("keydown", onKeyPress)
      Some(() => Window.removeEventListener("keydown", onKeyPress))
    }, [searchValBase])

    React.useEffect1(() => {
      if searchValBase->Js.String2.length < 1 && searchVal->Js.String2.length > 0 {
        setSearchVal(_ => searchValBase)
      }
      None
    }, [searchValBase])

    let inputSearch: ReactFinalForm.fieldRenderPropsInput = {
      name: "name",
      onBlur: _ev => (),
      onChange,
      onFocus: _ev => (),
      value: searchValBase->Js.Json.string,
      checked: true,
    }

    <div className="w-1/4 flex">
      {InputFields.textInput(~input=inputSearch, ~placeholder, ~customStyle=`!h-10 w-full`, ())}
      <Button
        leftIcon={FontAwesome("search")}
        buttonType={Secondary}
        customButtonStyle="px-2 py-3 mt-2"
        customIconSize=13
        onClick={_ => {
          setSearchVal(_ => searchValBase)
        }}
      />
    </div>
  }
}

module RemoteTableFilters = {
  open LogicUtils
  @react.component
  let make = (
    ~filterUrl,
    ~setFilters,
    ~endTimeFilterKey,
    ~startTimeFilterKey,
    ~initialFilters,
    ~initialFixedFilter,
    ~placeholder,
    ~setSearchVal,
    ~searchVal,
    ~setOffset,
    (),
  ) => {
    let {filterValue, updateExistingKeys, filterValueJson, removeKeys} =
      FilterContext.filterContext->React.useContext
    let defaultFilters = {""->Js.Json.string}

    let getFilterData = useGetFiltersData()
    let setInitialFilters = useSetInitialFilters(
      ~updateExistingKeys,
      ~startTimeFilterKey,
      ~endTimeFilterKey,
    )

    let customViewTop = <SearchBarFilter placeholder setSearchVal searchVal />

    React.useEffect0(() => {
      setInitialFilters()
      None
    })

    let endTimeVal = filterValueJson->getString(endTimeFilterKey, "")
    let startTimeVal = filterValueJson->getString(startTimeFilterKey, "")

    let filterBody = React.useMemo3(() => {
      [
        (startTimeFilterKey, startTimeVal->Js.Json.string),
        (endTimeFilterKey, endTimeVal->Js.Json.string),
      ]->Js.Dict.fromArray
    }, (startTimeVal, endTimeVal, filterValue))

    let filterDataJson = filterUrl->getFilterData(filterBody)
    let filterData = filterDataJson->Belt.Option.getWithDefault(Js.Dict.empty()->Js.Json.object_)

    React.useEffect1(() => {
      if filterValueJson->Js.Dict.keys->Js.Array2.length > 0 {
        setFilters(_ => filterValueJson->Some)
        setOffset(_ => 0)
      }
      None
    }, [filterValue])

    let remoteFilters = filterData->initialFilters
    let initialDisplayFilters =
      remoteFilters->Js.Array2.filter((item: EntityType.initialFilters<'t>) =>
        item.localFilter->Js.Option.isSome
      )
    let remoteOptions =
      filterData
      ->getFilterFields
      ->Js.Array2.filter(item => item.localFilter->Js.Option.isNone)
      ->Array.filterWithIndex((_item, index) => index > 3)

    let clearFilters = () => {
      filterData->getDictFromJsonObject->Js.Dict.keys->removeKeys
    }

    let hideFiltersDefaultValue = !(
      filterValue
      ->Js.Dict.keys
      ->Js.Array2.filter(item =>
        [startTimeFilterKey, endTimeFilterKey]
        ->Js.Array2.find(key => key == item)
        ->Belt.Option.isNone
      )
      ->Js.Array2.length > 0
    )

    switch filterDataJson {
    | Some(_) =>
      <RemoteFilter
        key="0"
        customViewTop
        defaultFilters
        fixedFilters={initialFixedFilter()}
        requiredSearchFieldsList=[]
        localFilters={initialDisplayFilters}
        localOptions=[]
        remoteOptions
        remoteFilters
        autoApply=false
        showExtraFiltersInline=true
        showClearFilterButton=true
        defaultFilterKeys=[startTimeFilterKey, endTimeFilterKey]
        updateUrlWith={updateExistingKeys}
        clearFilters
        filterFieldsPortalName=""
        showFiltersBtn={filterData->getFilterFields->Js.Array2.length > 0}
        hideFiltersDefaultValue
      />
    | _ =>
      <RemoteFilter
        key="1"
        customViewTop
        defaultFilters
        fixedFilters={initialFixedFilter()}
        requiredSearchFieldsList=[]
        localFilters=[]
        localOptions=[]
        remoteOptions=[]
        remoteFilters=[]
        autoApply=false
        showExtraFiltersInline=true
        showClearFilterButton=true
        defaultFilterKeys=[startTimeFilterKey, endTimeFilterKey]
        updateUrlWith={updateExistingKeys}
        clearFilters
        filterFieldsPortalName=""
        showFiltersBtn=false
        hideFiltersDefaultValue
      />
    }
  }
}
