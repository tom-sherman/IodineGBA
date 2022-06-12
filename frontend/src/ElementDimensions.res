type dimensions = {width: float}

let measureElement = el => {
  let boundingClient = el->Webapi.Dom.Element.getBoundingClientRect
  {
    width: boundingClient->Webapi.Dom.DomRect.width,
  }
}

let defaultDimensions = {width: 0.}

let useDimensions = () => {
  let ref = React.useRef(Js.Nullable.null)
  let (dimensions, setDimensions) = React.useState(() => defaultDimensions)
  let resizeObserver = LazyRef.use(() =>
    Webapi.ResizeObserver.make(entries =>
      entries->Js.Array2.forEach(entry => {
        let target = entry->Webapi.ResizeObserver.ResizeObserverEntry.target
        setDimensions(_ => target->measureElement)
      })
    )
  )

  React.useLayoutEffect1(() =>
    ref.current
    ->Js.Nullable.toOption
    ->Belt.Option.map(el => {
      setDimensions(_ => el->measureElement)
      resizeObserver->Webapi.ResizeObserver.observe(el)

      () => resizeObserver->Webapi.ResizeObserver.unobserve(el)
    })
  , [resizeObserver])

  (dimensions, ref)
}
